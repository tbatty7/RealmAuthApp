//
//  GrdbUserDatabaseMigrationTests.swift
//  RealmAuthApp
//
//  Created by Timothy D Batty on 9/12/25.
//

import XCTest
import RealmSwift
import GRDB
@testable import RealmAuthApp

final class GrdbUserDatabaseMigrationTests: XCTestCase {

    var realmConfig: Realm.Configuration!
    
    override func setUp() {
        super.setUp()
        realmConfig = Realm.Configuration(inMemoryIdentifier: self.name)
    }
    
    func testMigrationCopiesRealmUsersToGRDB() throws {
        // 1️⃣ Create some users in in-memory Realm
        let realm = try Realm(configuration: realmConfig)
        let user1 = User(username: "alice", email: "alice@example.com", password: "pass123")
        let user2 = User(username: "bob", email: "bob@example.com", password: "secret")
        try realm.write {
            realm.add([user1, user2])
        }
        
        // 2️⃣ Create in-memory GRDB database
        let grdbDB = try GrdbUserDatabase(config: ":memory:")
        
        // 3️⃣ Run migration
        try grdbDB.runMigration(realmConfig: realmConfig)
        
        // 4️⃣ Fetch all users from GRDB
        let migratedUsers = try grdbDB.getAllUsers()
        
        // 5️⃣ Assert the users were migrated
        XCTAssertEqual(migratedUsers.count, 2)
        
        let emails = migratedUsers.map { $0.email }
        XCTAssertTrue(emails.contains("alice@example.com"))
        XCTAssertTrue(emails.contains("bob@example.com"))
        
        let usernames = migratedUsers.map { $0.username }
        XCTAssertTrue(usernames.contains("alice"))
        XCTAssertTrue(usernames.contains("bob"))
    }
}

