//
//  UserDatabaseProtocolTests.swift
//  RealmAuthAppTests
//
//  Created by RealmAuthApp on 2024.
//  Protocol compliance tests that work with ANY database implementation
//

import XCTest
@testable import RealmAuthApp

class UserDatabaseProtocolTests: XCTestCase {
    
    var database: UserDatabaseProtocol!
    
    override func setUpWithError() throws {
        database = try InMemoryUserDatabase()
    }
    
    override func tearDownWithError() throws {
        database.close()
        database = nil
    }
    
    func testSaveUser() throws {
        let user = DomainUser.create(username: "test", email: "test@example.com", password: "hashedPassword")
        
        let savedUser = try database.saveUser(user)
        
        XCTAssertEqual(savedUser.id, user.id)
        XCTAssertEqual(savedUser.username, user.username)
        XCTAssertEqual(savedUser.email, user.email)
        XCTAssertEqual(savedUser.password, user.password)
    }
    
    func testFindUserByEmail() throws {
        let user = DomainUser.create(username: "test", email: "test@example.com", password: "hashedPassword")
        _ = try database.saveUser(user)
        
        let foundUser = try database.findUserByEmail("test@example.com")
        
        XCTAssertNotNil(foundUser)
        XCTAssertEqual(foundUser?.id, user.id)
        XCTAssertEqual(foundUser?.username, user.username)
        XCTAssertEqual(foundUser?.email, user.email)
    }
    
    func testFindUserByEmailNonexistent() throws {
        let foundUser = try database.findUserByEmail("nonexistent@example.com")
        
        XCTAssertNil(foundUser)
    }
    
    func testFindUserById() throws {
        let user = DomainUser.create(username: "test", email: "test@example.com", password: "hashedPassword")
        _ = try database.saveUser(user)
        
        let foundUser = try database.findUserById(user.id)
        
        XCTAssertNotNil(foundUser)
        XCTAssertEqual(foundUser?.id, user.id)
        XCTAssertEqual(foundUser?.email, user.email)
    }
    
    func testGetAllUsers() throws {
        let user1 = DomainUser.create(username: "user1", email: "user1@example.com", password: "password1")
        let user2 = DomainUser.create(username: "user2", email: "user2@example.com", password: "password2")
        _ = try database.saveUser(user1)
        _ = try database.saveUser(user2)
        
        let allUsers = try database.getAllUsers()
        
        XCTAssertEqual(allUsers.count, 2)
        let userIds = allUsers.map { $0.id }
        XCTAssertTrue(userIds.contains(user1.id))
        XCTAssertTrue(userIds.contains(user2.id))
    }
    
    func testUpdateUser() throws {
        // Given
        let originalUser = DomainUser.create(username: "original", email: "original@example.com", password: "password")
        _ = try database.saveUser(originalUser)
        
        let updatedUser = DomainUser(
            id: originalUser.id,
            username: "updated",
            email: "updated@example.com",
            password: "newPassword",
            createdAt: originalUser.createdAt
        )
        
        // When
        let result = try database.updateUser(updatedUser)
        
        // Then
        XCTAssertEqual(result.username, "updated")
        XCTAssertEqual(result.email, "updated@example.com")
        XCTAssertEqual(result.password, "newPassword")
        
        // Verify in database
        let foundUser = try database.findUserById(originalUser.id)
        XCTAssertEqual(foundUser?.username, "updated")
        XCTAssertEqual(foundUser?.email, "updated@example.com")
    }
    
    func testDeleteUser() throws {
        // Given
        let user = DomainUser.create(username: "test", email: "test@example.com", password: "password")
        _ = try database.saveUser(user)
        
        // When
        let deleted = try database.deleteUser(userId: user.id)
        
        // Then
        XCTAssertTrue(deleted)
        let foundUser = try database.findUserById(user.id)
        XCTAssertNil(foundUser)
    }
    
    func testDeleteNonexistentUser() throws {
        // When
        let deleted = try database.deleteUser(userId: "nonexistent-id")
        
        // Then
        XCTAssertFalse(deleted)
    }
    
    func testUserExists() throws {
        // Given
        let user = DomainUser.create(username: "test", email: "test@example.com", password: "password")
        _ = try database.saveUser(user)
        
        // When/Then
        XCTAssertTrue(try database.userExists(email: "test@example.com"))
        XCTAssertFalse(try database.userExists(email: "nonexistent@example.com"))
    }
    
    // MARK: - Constraint Tests
    
    func testDuplicateEmailPrevention() throws {
        // Given
        let user1 = DomainUser.create(username: "user1", email: "duplicate@example.com", password: "password1")
        let user2 = DomainUser.create(username: "user2", email: "duplicate@example.com", password: "password2")
        
        _ = try database.saveUser(user1)
        
        // When/Then
        XCTAssertThrowsError(try database.saveUser(user2)) { error in
            XCTAssertTrue(error is DatabaseError)
            if let dbError = error as? DatabaseError {
                XCTAssertEqual(dbError, .duplicateUser)
            }
        }
    }
    
    func testUpdateNonexistentUser() throws {
        // Given
        let nonexistentUser = DomainUser.create(username: "ghost", email: "ghost@example.com", password: "password")
        
        // When/Then
        XCTAssertThrowsError(try database.updateUser(nonexistentUser)) { error in
            XCTAssertTrue(error is DatabaseError)
            if let dbError = error as? DatabaseError {
                XCTAssertEqual(dbError, .userNotFound)
            }
        }
    }
    
    // MARK: - Data Integrity Tests
    
    func testUserDataIntegrity() throws {
        // Given
        let originalCreatedAt = Date()
        let user = DomainUser(
            id: "custom-id",
            username: "testuser",
            email: "test@example.com",
            password: "hashedPassword",
            createdAt: originalCreatedAt
        )
        
        // When
        _ = try database.saveUser(user)
        let retrievedUser = try database.findUserById("custom-id")
        
        // Then
        XCTAssertNotNil(retrievedUser)
        XCTAssertEqual(retrievedUser?.id, "custom-id")
        XCTAssertEqual(retrievedUser?.username, "testuser")
        XCTAssertEqual(retrievedUser?.email, "test@example.com")
        XCTAssertEqual(retrievedUser?.password, "hashedPassword")
        
        // Note: Some databases might have slight precision differences in dates
        // so we'll allow a small tolerance
        let timeDifference = abs(retrievedUser!.createdAt.timeIntervalSince(originalCreatedAt))
        XCTAssertLessThan(timeDifference, 1.0, "CreatedAt should be preserved within 1 second")
    }
    
    func testMultipleOperationsConsistency() throws {
        // This test ensures the database maintains consistency across multiple operations
        
        // Save multiple users
        let users = [
            DomainUser.create(username: "user1", email: "user1@example.com", password: "pass1"),
            DomainUser.create(username: "user2", email: "user2@example.com", password: "pass2"),
            DomainUser.create(username: "user3", email: "user3@example.com", password: "pass3")
        ]
        
        for user in users {
            _ = try database.saveUser(user)
        }
        
        // Verify count
        XCTAssertEqual(try database.getAllUsers().count, 3)
        
        // Update one user
        let updatedUser = DomainUser(
            id: users[1].id,
            username: "updated_user2",
            email: "updated_user2@example.com",
            password: "updated_pass2",
            createdAt: users[1].createdAt
        )
        _ = try database.updateUser(updatedUser)
        
        // Delete one user
        _ = try database.deleteUser(userId: users[2].id)
        
        // Final verification
        let finalUsers = try database.getAllUsers()
        XCTAssertEqual(finalUsers.count, 2)
        
        let updatedUserFromDB = try database.findUserById(users[1].id)
        XCTAssertEqual(updatedUserFromDB?.username, "updated_user2")
        XCTAssertEqual(updatedUserFromDB?.email, "updated_user2@example.com")
        
        let deletedUser = try database.findUserById(users[2].id)
        XCTAssertNil(deletedUser)
    }
    
    // MARK: - Statistics Tests
    
    func testGetStats() throws {
        // Given
        let user = DomainUser.create(username: "test", email: "test@example.com", password: "password")
        _ = try database.saveUser(user)
        
        // When
        let stats = database.getStats()
        
        // Then
        XCTAssertNotNil(stats["userCount"])
        XCTAssertNotNil(stats["databaseType"])
        
        // User count should be at least 1
        if let userCount = stats["userCount"] as? Int {
            XCTAssertGreaterThanOrEqual(userCount, 1)
        }
    }
}
