//
//  AccountRepository.swift
//  Wadaily
//
//  Created on 2025/12/08.
//

import Foundation
import Supabase

class AccountRepository: AccountRepositoryProtocol {
    private let client = SupabaseClient(
        supabaseURL: URL(string: "https://hugiiayzlgfftarxzqne.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh1Z2lpYXl6bGdmZnRhcnh6cW5lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxOTI3MTgsImV4cCI6MjA4MDc2ODcxOH0.QDoCA0KlWWO8rFudSMk0VxEmvxEwEhFU-5p-F1fHZl8",
        options: SupabaseClientOptions(
            auth: SupabaseClientOptions.AuthOptions(
                emitLocalSessionAsInitialSession: true
            )
        )
    )
    
    func register(account: Account) async throws -> Account {
        try await client
            .from("accounts")
            .insert(account)
            .select()
            .single()
            .execute()
            .value
    }
    
    func find(userId: String) async throws -> Account {
        try await client
            .from("accounts")
            .select()
            .eq("user_id", value: userId)
            .single()
            .execute()
            .value
    }
    
    func update(account: Account) async throws -> Account {
        try await client
            .from("accounts")
            .update(account)
            .eq("user_id", value: account.userId)
            .select()
            .single()
            .execute()
            .value
    }
    
    func fetchAll() async throws -> [Account] {
        try await client
            .from("accounts")
            .select()
            .execute()
            .value
    }
    
    func updateStatus(userId: String, status: String) async throws {
        try await client
            .from("accounts")
            .update(["status": status])
            .eq("user_id", value: userId)
            .execute()
    }
}

