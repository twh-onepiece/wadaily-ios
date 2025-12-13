//
//  SpeechToTextService.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/12/13.
//

import Foundation

class SpeechToTextService: SpeechToTextServiceProtocol {
    private var webSocketTask: URLSessionWebSocketTask?
    private var callback: SpeechToTextCallback?
    private var isConnected = false
    
    private let WEBSOCKET_URL_STRING: String = "wss://app-253151b9-60c4-47f1-b33f-7c028738cde8.ingress.apprun.sakura.ne.jp/transcript/connect"
   
    func startSession(
        sampleRate: Int,
        channels: Int,
        callback: @escaping SpeechToTextCallback
    ) async throws {
        self.callback = callback
        
        guard let url = URL(string: WEBSOCKET_URL_STRING) else {
            throw NSError(domain: "SpeechToTextService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        // URLSessionの設定
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        configuration.waitsForConnectivity = true
        
        let session = URLSession(configuration: configuration)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()

        isConnected = true
        
        // メッセージ受信の開始（接続確立後すぐに）
        receiveMessage()
    }
    
    func sendAudioData(_ pcmData: Data) async throws {
        guard let webSocketTask = webSocketTask else {
            throw NSError(domain: "SpeechToTextService", code: 2, userInfo: [NSLocalizedDescriptionKey: "WebSocket not connected"])
        }
        
        guard isConnected else {
            throw NSError(domain: "SpeechToTextService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Connection not established"])
        }

        do {
            try await webSocketTask.send(.data(pcmData))
        } catch {
            isConnected = false
            print("error: can't send it")
            throw error
        }
    }
   
    func endSession() async {
        isConnected = false
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        callback = nil
    }
   
    private func receiveMessage() {
        guard isConnected else { return }
        guard let task = webSocketTask else { return }
                
        task.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.callback?(.success(text))
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.callback?(.success(text))
                    }
                @unknown default:
                    break
                }
                // 次のメッセージを受信
                self.receiveMessage()
            case .failure(let error):
                self.isConnected = false
                self.callback?(.failure(error))
            }
        }
    }
}
