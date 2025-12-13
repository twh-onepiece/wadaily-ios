//
//  CallPartnerRepositoryProtocol.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/11/30.
//

protocol CallerRepositoryProtocol {
    func fetchCallPartners() async throws -> [Caller]
}

// MARK: - Supabase Repository
class CallerRepository: CallerRepositoryProtocol {
    private let accountRepository = AccountRepository()
    
    func fetchCallPartners() async throws -> [Caller] {
        let accounts = try await accountRepository.fetchAll()
        return accounts.map { Caller.from($0) }
    }
}

// MARK: - Mock Repository for Testing/Preview
class MockCallerRepository: CallerRepositoryProtocol {
    func fetchCallPartners() async throws -> [Caller] {
        // ダミーデータを返す
        return DummyCallPartner.partners
    }
}
