//
//  AccountRepositoryProtocol.swift
//  Wadaily
//
//  Created by 浦山秀斗 on 2025/11/30.
//

protocol AccountRepositoryProtocol {
    func register(account: Account) async throws -> Account
    func find(userId: String) async throws -> Account
    func update(account: Account) async throws -> Account
    func fetchAll() async throws -> [Account]
    func updateStatus(userId: String, status: String) async throws
}
