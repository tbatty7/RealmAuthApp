//
//  DomainUser.swift
//  RealmAuthApp
//
//  Created by RealmAuthApp on 2024.
//  Database-agnostic User domain model
//

import Foundation

/// Domain model for User that doesn't depend on any specific database implementation
struct DomainUser {
    let id: String
    let username: String
    let email: String
    let password: String
    let createdAt: Date
    
    init(id: String = UUID().uuidString, username: String, email: String, password: String, createdAt: Date = Date()) {
        self.id = id
        self.username = username
        self.email = email
        self.password = password
        self.createdAt = createdAt
    }
}

// MARK: - Convenience Extensions

extension DomainUser {
    /// Create DomainUser with auto-generated ID and current timestamp
    static func create(username: String, email: String, password: String) -> DomainUser {
        return DomainUser(username: username, email: email, password: password)
    }
    
    /// Check if the user has valid data
    var isValid: Bool {
        return !username.isEmpty && !email.isEmpty && !password.isEmpty
    }
}

// MARK: - Equatable

extension DomainUser: Equatable {
    static func == (lhs: DomainUser, rhs: DomainUser) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension DomainUser: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
