//
//  GRDBUser.swift
//  RealmAuthApp
//
//  Created by Timothy D Batty on 9/10/25.
//

import Foundation
import GRDB

struct GRDBUser: Codable, FetchableRecord, PersistableRecord {
    
    let id: String
    let username: String
    let email: String
    let password: String
    let createdAt: Date
    
    static let databaseTableName = "users"
    
    enum Columns: String, ColumnExpression {
        case id, email, username, createdAt
    }
}

// MARK: - Mappers

extension GRDBUser {
    init(from domain: DomainUser) {
        self.id = domain.id
        self.email = domain.email
        self.username = domain.username
        self.createdAt = domain.createdAt
        self.password = domain.password
    }
    
    func toDomain() -> DomainUser {
        DomainUser(id: id, username: username,email: email,  password: password, createdAt: createdAt)
    }
}
