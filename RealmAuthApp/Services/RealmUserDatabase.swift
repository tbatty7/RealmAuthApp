//
//  RealmUserDatabase.swift
//  RealmAuthApp
//
//  Created by RealmAuthApp on 2024.
//  Realm implementation of UserDatabaseProtocol
//

import Foundation
import RealmSwift

/// Realm implementation of the user database protocol
class RealmUserDatabase: UserDatabaseProtocol {
    private let realm: Realm
    
    required init() throws {
        do {
            realm = try Realm()
        } catch {
            throw DatabaseError.connectionFailed
        }
    }
    
    // MARK: - User Operations
    
    func saveUser(_ user: DomainUser) throws -> DomainUser {
        do {
            // Check if user already exists
            if try userExists(email: user.email) {
                throw DatabaseError.duplicateUser
            }
            
            // Convert DomainUser to Realm User
            let realmUser = User(username: user.username, email: user.email, password: user.password)
            realmUser.id = user.id
            realmUser.createdAt = user.createdAt
            
            try realm.write {
                realm.add(realmUser)
            }
            
            // Return the saved user
            return user
        } catch let error as DatabaseError {
            throw error
        } catch {
            throw DatabaseError.saveFailed
        }
    }
    
    func findUserByEmail(_ email: String) throws -> DomainUser? {
        
        let realmUser = realm.objects(User.self).filter("email == %@", email).first
        return realmUser?.toDomainUser()
        
    }
    
    func findUserById(_ id: String) throws -> DomainUser? {
        
        let realmUser = realm.objects(User.self).filter("id == %@", id).first
        return realmUser?.toDomainUser()
        
    }
    
    func getAllUsers() throws -> [DomainUser] {
        
        let realmUsers = realm.objects(User.self)
        return Array(realmUsers).map { $0.toDomainUser() }
        
    }
    
    func updateUser(_ user: DomainUser) throws -> DomainUser {
        do {
            guard let realmUser = realm.objects(User.self).filter("id == %@", user.id).first else {
                throw DatabaseError.userNotFound
            }
            
            try realm.write {
                realmUser.username = user.username
                realmUser.email = user.email
                realmUser.password = user.password
                // Note: We don't update createdAt as it should remain unchanged
            }
            
            return user
        } catch let error as DatabaseError {
            throw error
        } catch {
            throw DatabaseError.saveFailed
        }
    }
    
    func deleteUser(userId: String) throws -> Bool {
        do {
            guard let realmUser = realm.objects(User.self).filter("id == %@", userId).first else {
                return false // User not found, but not an error
            }
            
            try realm.write {
                realm.delete(realmUser)
            }
            
            return true
        } catch {
            throw DatabaseError.deleteFailed
        }
    }
    
    func userExists(email: String) throws -> Bool {
        
        let count = realm.objects(User.self).filter("email == %@", email).count
        return count > 0
        
    }
    
    // MARK: - Database Management
    
    func close() {
        // Realm automatically manages connections, no explicit close needed
    }
    
    func getStats() -> [String: Any] {
        let userCount = realm.objects(User.self).count
        let realmURL = realm.configuration.fileURL?.absoluteString ?? "Unknown"
        
        return [
            "userCount": userCount,
            "databasePath": realmURL,
            "databaseType": "Realm"
        ]
    }
}

// MARK: - Realm User Extensions

extension User {
    /// Convert Realm User to DomainUser
    func toDomainUser() -> DomainUser {
        return DomainUser(
            id: self.id,
            username: self.username,
            email: self.email,
            password: self.password,
            createdAt: self.createdAt
        )
    }
    
}
