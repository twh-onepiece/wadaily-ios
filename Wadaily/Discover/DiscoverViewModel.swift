//
//  DiscoverViewModel.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/12/09.
//

import Foundation
import Combine

class DiscoverViewModel: ObservableObject {
    @Published var partners: [Caller] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let repository: CallerRepositoryProtocol
    private let me: Caller
    
    init(me: Caller) {
        self.me = me
        self.repository = CallerRepository()
    }
    
    func fetchPartners() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let allPartners = try await repository.fetchCallPartners()
            // 自分以外をフィルタリング
            let filteredPartners = allPartners.filter { $0.userId != me.userId }
            
            await MainActor.run {
                partners = filteredPartners
            }
        } catch {
            await MainActor.run {
                errorMessage = "通話相手の取得に失敗しました: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
}
