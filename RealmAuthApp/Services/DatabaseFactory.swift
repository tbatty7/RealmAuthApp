//
//  DatabaseFactory.swift
//  RealmAuthApp
//
//  Created by RealmAuthApp on 2024.
//  Factory for creating database instances
//

import Foundation

/// Database type enumeration for factory
enum DatabaseType {
    case realm
    case grdb
    case inMemory  // For testing
}

/// Factory class for creating database instances
/// This keeps the AuthService completely database-agnostic
class DatabaseFactory {
    
    /// Create a database instance based on type
    /// - Parameter type: The type of database to create
    /// - Returns: Database instance conforming to UserDatabaseProtocol
    /// - Throws: DatabaseError if creation fails
    static func createDatabase(type: DatabaseType) throws -> UserDatabaseProtocol {
        switch type {
        case .realm:
            return try RealmUserDatabase()
        case .grdb:
            return try GrdbUserDatabase()
        case .inMemory:
            return try InMemoryUserDatabase()
        }
    }
    
    /// Create the default database (currently Realm)
    static func createDefaultDatabase() throws -> UserDatabaseProtocol {
        return try createDatabase(type: .grdb)
    }
}

/// In-memory database implementation for testing
class InMemoryUserDatabase: UserDatabaseProtocol {
    private var users: [String: DomainUser] = [:]
    
    required init() throws {
        // Nothing to initialize for in-memory database
        // throws required by protocol but never actually throws
    }
    
    func saveUser(_ user: DomainUser) throws -> DomainUser {
        // Check for duplicate email
        for existingUser in users.values {
            if existingUser.email == user.email {
                throw DatabaseError.duplicateUser
            }
        }
        
        users[user.id] = user
        return user
    }
    
    func findUserByEmail(_ email: String) throws -> DomainUser? {
        return users.values.first { $0.email == email }
    }
    
    func findUserById(_ id: String) throws -> DomainUser? {
        return users[id]
    }
    
    func getAllUsers() throws -> [DomainUser] {
        return Array(users.values)
    }
    
    func updateUser(_ user: DomainUser) throws -> DomainUser {
        guard users[user.id] != nil else {
            throw DatabaseError.userNotFound
        }
        users[user.id] = user
        return user
    }
    
    func deleteUser(userId: String) throws -> Bool {
        let existed = users[userId] != nil
        users.removeValue(forKey: userId)
        return existed
    }
    
    func userExists(email: String) throws -> Bool {
        return users.values.contains { $0.email == email }
    }
    
    func close() {
        users.removeAll()
    }
    
    func getStats() -> [String: Any] {
        return [
            "userCount": users.count,
            "databaseType": "InMemory",
            "users": users.keys.sorted()
        ]
    }
}
