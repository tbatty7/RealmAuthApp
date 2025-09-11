//
//  GrdbUserDatabse.swift
//  RealmAuthApp
//
//  Created by Timothy D Batty on 9/10/25.
//

import Foundation
import GRDB
import RealmSwift

final class GrdbUserDatabase: UserDatabaseProtocol {
    private var dbQueue: DatabaseQueue?
    
    // MARK: - Lifecycle
    
    required init() throws {
        do {
            let dbURL = try FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("users.sqlite")
            
            dbQueue = try DatabaseQueue(path: dbURL.path)
            try migrator.migrate(dbQueue!)
        } catch {
            throw DatabaseError.connectionFailed
        }
    }
    
    // MARK: - User Operations
    
    func saveUser(_ user: DomainUser) throws -> DomainUser {
        let grdbUser = GRDBUser(from: user)
        do {
            try dbQueue?.write { db in
                if try GRDBUser.filter(Column("email") == user.email).fetchOne(db) != nil {
                    throw DatabaseError.duplicateUser
                }
                try grdbUser.insert(db)
            }
            return grdbUser.toDomain()
        } catch let dbErr as DatabaseError {
            throw dbErr
        } catch {
            throw DatabaseError.saveFailed
        }
    }
    
    func findUserByEmail(_ email: String) throws -> DomainUser? {
        do {
            return try dbQueue?.read { db in
                try GRDBUser.filter(Column("email") == email).fetchOne(db)?.toDomain()
            }
        } catch {
            throw DatabaseError.queryFailed
        }
    }
    
    func findUserById(_ id: String) throws -> DomainUser? {
        do {
            return try dbQueue?.read { db in
                try GRDBUser.fetchOne(db, key: id)?.toDomain()
            }
        } catch {
            throw DatabaseError.queryFailed
        }
    }
    
    func getAllUsers() throws -> [DomainUser] {
        do {
            return try dbQueue?.read { db in
                try GRDBUser.fetchAll(db).map { $0.toDomain() }
            } ?? []
        } catch {
            throw DatabaseError.queryFailed
        }
    }
    
    func updateUser(_ user: DomainUser) throws -> DomainUser {
        let grdbUser = GRDBUser(from: user)
        do {
            let updated = try dbQueue?.write { db in
                guard try GRDBUser.fetchOne(db, key: user.id) != nil else {
                    throw DatabaseError.userNotFound
                }
                try grdbUser.update(db)
                return grdbUser.toDomain()
            }
            return updated!
        } catch let dbErr as DatabaseError {
            throw dbErr
        } catch {
            throw DatabaseError.saveFailed
        }
    }
    
    func deleteUser(userId: String) throws -> Bool {
        do {
            return try dbQueue?.write { db in
                guard let user = try GRDBUser.fetchOne(db, key: userId) else {
                    return false
                }
                try user.delete(db)
                return true
            } ?? false
        } catch {
            throw DatabaseError.deleteFailed
        }
    }
    
    func userExists(email: String) throws -> Bool {
        do {
            return try dbQueue?.read { db in
                try GRDBUser.filter(Column("email") == email).fetchCount(db) > 0
            } ?? false
        } catch {
            throw DatabaseError.queryFailed
        }
    }
    
    // MARK: - Database Management
    
    func close() {
        dbQueue = nil
    }
    
    func getStats() -> [String: Any] {
        var stats: [String: Any] = [:]
        if let count = try? dbQueue?.read({ db in try GRDBUser.fetchCount(db) }) {
            stats["userCount"] = count
        }
        return stats
    }
    
    // MARK: - Migration
    
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createUsers") { db in
            try db.create(table: "users") { t in
                t.column("id", .text).primaryKey()
                t.column("email", .text).unique(onConflict: .fail).notNull()
                t.column("username", .text).notNull()
                t.column("password", .text).notNull()
                t.column("createdAt", .datetime).notNull()
            }
            
            let realm = try Realm()
                let realmUsers = realm.objects(User.self)

                for rUser in realmUsers {
                    let grdbUser = GRDBUser(
                        id: rUser.id,
                        username: rUser.username,
                        email: rUser.email,
                        password: rUser.password,
                        createdAt: rUser.createdAt
                    )
                    try grdbUser.insert(db)
                }
        }
        return migrator
    }
}
