//
//  RefactoredAuthServiceTests.swift
//  RealmAuthAppTests
//
//  Created by RealmAuthApp on 2024.
//  Database-agnostic tests for authentication service
//

import XCTest
@testable import RealmAuthApp

class RefactoredAuthServiceTests: XCTestCase {
    
    var authService: RefactoredAuthService!
    
    override func setUpWithError() throws {
        // Use InMemoryUserDatabase for testing - completely isolated from Realm
        let database = try InMemoryUserDatabase()
        authService = RefactoredAuthService(database: database)
    }
    
    override func tearDownWithError() throws {
        authService = nil
    }
    
    // MARK: - User Registration Tests
    
    func testSuccessfulUserRegistration() throws {
        // Given
        let username = "testuser"
        let email = "test@example.com"
        let password = "password123"
        
        // When
        let user = try authService.registerUser(username: username, email: email, password: password)
        
        // Then
        XCTAssertEqual(user.username, username)
        XCTAssertEqual(user.email, email)
        XCTAssertNotEqual(user.password, password) // Should be hashed
        XCTAssertFalse(user.id.isEmpty)
        XCTAssertNotNil(user.createdAt)
    }
    
    func testRegistrationWithDuplicateEmail() throws {
        // Given
        let email = "test@example.com"
        _ = try authService.registerUser(username: "user1", email: email, password: "password123")
        
        // When/Then
        XCTAssertThrowsError(try authService.registerUser(username: "user2", email: email, password: "password456")) { error in
            XCTAssertTrue(error is RefactoredAuthService.AuthError)
            if let authError = error as? RefactoredAuthService.AuthError {
                XCTAssertEqual(authError, .userAlreadyExists)
            }
        }
    }
    
    func testRegistrationWithInvalidEmail() throws {
        // Given
        let invalidEmails = ["invalid", "@example.com", "test@", "test.example.com", ""]
        
        // When/Then
        for email in invalidEmails {
            XCTAssertThrowsError(try authService.registerUser(username: "test", email: email, password: "password123")) { error in
                if let authError = error as? RefactoredAuthService.AuthError {
                    XCTAssertEqual(authError, .invalidEmail, "Email '\(email)' should be invalid")
                }
            }
        }
    }
    
    func testRegistrationWithWeakPassword() throws {
        // Given
        let weakPasswords = ["", "12345", "abc", "a1"]
        
        // When/Then
        for password in weakPasswords {
            XCTAssertThrowsError(try authService.registerUser(username: "test", email: "test@example.com", password: password)) { error in
                if let authError = error as? RefactoredAuthService.AuthError {
                    XCTAssertEqual(authError, .weakPassword, "Password '\(password)' should be too weak")
                }
            }
        }
    }
    
    func testRegistrationWithValidEmails() throws {
        // Given
        let validEmails = ["test@example.com", "user.name@domain.co.uk", "first+last@test-domain.org"]
        
        // When/Then
        for (index, email) in validEmails.enumerated() {
            XCTAssertNoThrow(try authService.registerUser(username: "user\(index)", email: email, password: "password123"))
        }
    }
    
    // MARK: - User Login Tests
    
    func testSuccessfulLogin() throws {
        // Given - Register a user first
        let email = "test@example.com"
        let password = "password123"
        let registeredUser = try authService.registerUser(username: "testuser", email: email, password: password)
        
        // When
        let loggedInUser = try authService.loginUser(email: email, password: password)
        
        // Then
        XCTAssertEqual(loggedInUser.id, registeredUser.id)
        XCTAssertEqual(loggedInUser.username, registeredUser.username)
        XCTAssertEqual(loggedInUser.email, registeredUser.email)
        XCTAssertEqual(loggedInUser.password, registeredUser.password) // Both should be hashed
    }
    
    func testLoginWithNonexistentEmail() throws {
        // When/Then
        XCTAssertThrowsError(try authService.loginUser(email: "nonexistent@example.com", password: "password123")) { error in
            if let authError = error as? RefactoredAuthService.AuthError {
                XCTAssertEqual(authError, .userNotFound)
            }
        }
    }
    
    func testLoginWithWrongPassword() throws {
        // Given - Register a user first
        let email = "test@example.com"
        _ = try authService.registerUser(username: "testuser", email: email, password: "correctpassword")
        
        // When/Then
        XCTAssertThrowsError(try authService.loginUser(email: email, password: "wrongpassword")) { error in
            if let authError = error as? RefactoredAuthService.AuthError {
                XCTAssertEqual(authError, .invalidCredentials)
            }
        }
    }
    
    // MARK: - Password Security Tests
    
    func testPasswordsAreHashed() throws {
        // Given
        let password = "plaintext123"
        
        // When
        let user = try authService.registerUser(username: "test", email: "test@example.com", password: password)
        
        // Then
        XCTAssertNotEqual(user.password, password, "Password should be hashed, not stored as plain text")
        XCTAssertGreaterThan(user.password.count, password.count, "Hashed password should be longer than original")
    }
    
    func testSamePasswordsProduceSameHash() throws {
        // Given
        let password = "samepassword123"
        
        // When
        let user1 = try authService.registerUser(username: "user1", email: "user1@example.com", password: password)
        let user2 = try authService.registerUser(username: "user2", email: "user2@example.com", password: password)
        
        // Then
        XCTAssertEqual(user1.password, user2.password, "Same passwords should produce same hash")
    }
    
    // MARK: - User Management Tests
    
    func testGetAllUsers() throws {
        // Given - Register multiple users
        _ = try authService.registerUser(username: "user1", email: "user1@example.com", password: "password123")
        _ = try authService.registerUser(username: "user2", email: "user2@example.com", password: "password123")
        _ = try authService.registerUser(username: "user3", email: "user3@example.com", password: "password123")
        
        // When
        let allUsers = try authService.getAllUsers()
        
        // Then
        XCTAssertEqual(allUsers.count, 3)
        let usernames = allUsers.map { $0.username }
        XCTAssertTrue(usernames.contains("user1"))
        XCTAssertTrue(usernames.contains("user2"))
        XCTAssertTrue(usernames.contains("user3"))
    }
    
    func testUserExists() throws {
        // Given
        let email = "test@example.com"
        _ = try authService.registerUser(username: "test", email: email, password: "password123")
        
        // When/Then
        XCTAssertTrue(try authService.userExists(email: email))
        XCTAssertFalse(try authService.userExists(email: "nonexistent@example.com"))
    }
    
    func testDeleteUser() throws {
        // Given
        let user = try authService.registerUser(username: "test", email: "test@example.com", password: "password123")
        
        // When
        let deleted = try authService.deleteUser(userId: user.id)
        
        // Then
        XCTAssertTrue(deleted)
        XCTAssertFalse(try authService.userExists(email: "test@example.com"))
        
        // Verify deletion by trying to login
        XCTAssertThrowsError(try authService.loginUser(email: "test@example.com", password: "password123"))
    }
    
    func testDeleteNonexistentUser() throws {
        // When
        let deleted = try authService.deleteUser(userId: "nonexistent-id")
        
        // Then
        XCTAssertFalse(deleted)
    }
    
    func testUpdateUser() throws {
        // Given
        let originalUser = try authService.registerUser(username: "original", email: "original@example.com", password: "password123")
        
        // When
        let updatedUser = DomainUser(
            id: originalUser.id,
            username: "updated",
            email: "updated@example.com",
            password: originalUser.password, // Keep same hashed password
            createdAt: originalUser.createdAt
        )
        let result = try authService.updateUser(updatedUser)
        
        // Then
        XCTAssertEqual(result.username, "updated")
        XCTAssertEqual(result.email, "updated@example.com")
        XCTAssertEqual(result.id, originalUser.id)
        XCTAssertEqual(result.createdAt, originalUser.createdAt)
    }
    
    // MARK: - Database Statistics Tests
    
    func testDatabaseStats() throws {
        // Given
        _ = try authService.registerUser(username: "user1", email: "user1@example.com", password: "password123")
        _ = try authService.registerUser(username: "user2", email: "user2@example.com", password: "password123")
        
        // When
        let stats = authService.getDatabaseStats()
        
        // Then
        XCTAssertEqual(stats["userCount"] as? Int, 2)
        XCTAssertEqual(stats["databaseType"] as? String, "InMemory")
        XCTAssertNotNil(stats["users"])
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testRegistrationWithEmptyFields() throws {
        
        // Test empty email
        XCTAssertThrowsError(try authService.registerUser(username: "test", email: "", password: "password123"))
        
        // Test empty password
        XCTAssertThrowsError(try authService.registerUser(username: "test", email: "test@example.com", password: ""))
    }
    
    func testCaseSensitiveEmails() throws {
        // Given
        _ = try authService.registerUser(username: "user1", email: "Test@Example.com", password: "password123")
        
        // When/Then - Different case should be treated as different email
        XCTAssertNoThrow(try authService.registerUser(username: "user2", email: "test@example.com", password: "password123"))
    }
    
    func testMultipleSuccessfulOperations() throws {
        // This test ensures the in-memory database maintains state across operations
        
        // Register users
        let user1 = try authService.registerUser(username: "user1", email: "user1@example.com", password: "password123")
        let user2 = try authService.registerUser(username: "user2", email: "user2@example.com", password: "password456")
        
        // Login with both
        let loggedUser1 = try authService.loginUser(email: "user1@example.com", password: "password123")
        let loggedUser2 = try authService.loginUser(email: "user2@example.com", password: "password456")
        
        // Verify
        XCTAssertEqual(loggedUser1.id, user1.id)
        XCTAssertEqual(loggedUser2.id, user2.id)
        
        // Check total users
        let allUsers = try authService.getAllUsers()
        XCTAssertEqual(allUsers.count, 2)
    }
}
