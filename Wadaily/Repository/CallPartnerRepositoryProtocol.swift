//
//  CallPartnerRepositoryProtocol.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/11/30.
//

protocol CallPartnerRepositoryProtocol {
    func fetchCallPartners() async throws -> [Caller]
}
