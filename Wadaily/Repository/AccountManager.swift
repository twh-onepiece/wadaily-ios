//
//  AccountManager.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/12/09.
//

import Foundation
import Combine

/// ログイン中のアカウント情報を管理するシングルトンクラス
class AccountManager: ObservableObject {
    static let shared = AccountManager()
    
    @Published private(set) var currentAccount: Account?
    
    private let storage: LocalStorageProtocol
    private let storageKey = "current_account"
    
    private init(storage: LocalStorageProtocol = UserDefaultsStorage()) {
        self.storage = storage
        self.currentAccount = loadAccount()
    }
    
    /// ログイン済みかどうか
    var isLoggedIn: Bool {
        currentAccount != nil
    }
    
    /// アカウント情報を保存
    func saveAccount(_ account: Account) {
        do {
            try storage.save(account, forKey: storageKey)
            currentAccount = account
        } catch {
            print("Failed to save account: \(error)")
        }
    }
    
    /// アカウント情報を読み込み
    func loadAccount() -> Account? {
        do {
            return try storage.load(forKey: storageKey, as: Account.self)
        } catch {
            print("Failed to load account: \(error)")
            return nil
        }
    }
    
    /// ログアウト（アカウント情報を削除）
    func logout() {
        do {
            try storage.delete(forKey: storageKey)
            currentAccount = nil
        } catch {
            print("Failed to delete account: \(error)")
        }
    }
    
    /// アカウント情報を更新
    func updateAccount(_ account: Account) {
        saveAccount(account)
    }
}
