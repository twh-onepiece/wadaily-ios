//
//  CallPartnerRepositoryProtocol.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/11/30.
//

protocol CallerRepositoryProtocol {
    func fetchCallPartners() async throws -> [Caller]
}

// MARK: - Mock Repository for Testing/Preview
class MockCallerRepository: CallerRepositoryProtocol {
    func fetchCallPartners() async throws -> [Caller] {
        // ダミーデータを返す
        return DummyCallPartner.partners
    }
}
