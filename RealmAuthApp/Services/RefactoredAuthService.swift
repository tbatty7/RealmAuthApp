//
//  RefactoredAuthService.swift
//  RealmAuthApp
//
//  Created by RealmAuthApp on 2024.
//  Refactored AuthService that uses database facade pattern
//

import Foundation
import CryptoKit

/// Refactored authentication service that uses database abstraction
class RefactoredAuthService {
    private let database: UserDatabaseProtocol
    
    enum AuthError: Error, LocalizedError, Equatable {
        case userAlreadyExists
        case invalidCredentials
        case weakPassword
        case invalidEmail
        case userNotFound
        case databaseError(DatabaseError)
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .userAlreadyExists:
                return "User with this email already exists"
            case .invalidCredentials:
                return "Invalid email or password"
            case .weakPassword:
                return "Password must be at least 6 characters long"
            case .invalidEmail:
                return "Please enter a valid email address"
            case .userNotFound:
                return "User not found"
            case .databaseError(let dbError):
                return "Database error: \(dbError.localizedDescription)"
            case .unknown:
                return "An unexpected error occurred"
            }
        }
        
        // MARK: - Equatable Implementation
        
        static func == (lhs: AuthError, rhs: AuthError) -> Bool {
            switch (lhs, rhs) {
            case (.userAlreadyExists, .userAlreadyExists),
                 (.invalidCredentials, .invalidCredentials),
                 (.weakPassword, .weakPassword),
                 (.invalidEmail, .invalidEmail),
                 (.userNotFound, .userNotFound),
                 (.unknown, .unknown):
                return true
            case (.databaseError(let lhsError), .databaseError(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize with dependency injection for testability
    /// - Parameter database: Database implementation to use
    init(database: UserDatabaseProtocol) {
        self.database = database
    }
    
    /// Note: No default initializer - database implementation must be injected
    /// This ensures the service remains database-agnostic
    
    // MARK: - Authentication Methods
    
    /// Register a new user
    /// - Parameters:
    ///   - username: User's display name
    ///   - email: User's email address
    ///   - password: User's password (will be hashed)
    /// - Returns: The created user
    /// - Throws: AuthError if registration fails
    func registerUser(username: String, email: String, password: String) throws -> DomainUser {
        do {
            // Validate input
            try validateEmail(email)
            try validatePassword(password)
            
            // Hash password
            let hashedPassword = hashPassword(password)
            
            // Create domain user
            let user = DomainUser.create(username: username, email: email, password: hashedPassword)
            
            // Save to database
            return try database.saveUser(user)
            
        } catch let error as AuthError {
            throw error
        } catch let dbError as DatabaseError {
            if dbError == .duplicateUser {
                throw AuthError.userAlreadyExists
            }
            throw AuthError.databaseError(dbError)
        } catch {
            throw AuthError.unknown
        }
    }
    
    /// Login an existing user
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: The authenticated user
    /// - Throws: AuthError if login fails
    func loginUser(email: String, password: String) throws -> DomainUser {
        do {
            // Find user by email
            guard let user = try database.findUserByEmail(email) else {
                throw AuthError.userNotFound
            }
            
            // Verify password
            let hashedPassword = hashPassword(password)
            if user.password == hashedPassword {
                return user
            } else {
                throw AuthError.invalidCredentials
            }
            
        } catch let error as AuthError {
            throw error
        } catch let dbError as DatabaseError {
            throw AuthError.databaseError(dbError)
        } catch {
            throw AuthError.unknown
        }
    }
    
    // MARK: - User Management
    
    /// Get all users (for admin purposes)
    /// - Returns: Array of all users
    /// - Throws: AuthError if query fails
    func getAllUsers() throws -> [DomainUser] {
        do {
            return try database.getAllUsers()
        } catch let dbError as DatabaseError {
            throw AuthError.databaseError(dbError)
        } catch {
            throw AuthError.unknown
        }
    }
    
    /// Delete a user
    /// - Parameter userId: ID of user to delete
    /// - Returns: True if user was deleted
    /// - Throws: AuthError if deletion fails
    func deleteUser(userId: String) throws -> Bool {
        do {
            return try database.deleteUser(userId: userId)
        } catch let dbError as DatabaseError {
            throw AuthError.databaseError(dbError)
        } catch {
            throw AuthError.unknown
        }
    }
    
    /// Update user information
    /// - Parameter user: Updated user information
    /// - Returns: The updated user
    /// - Throws: AuthError if update fails
    func updateUser(_ user: DomainUser) throws -> DomainUser {
        do {
            return try database.updateUser(user)
        } catch let dbError as DatabaseError {
            throw AuthError.databaseError(dbError)
        } catch {
            throw AuthError.unknown
        }
    }
    
    /// Check if user exists
    /// - Parameter email: Email to check
    /// - Returns: True if user exists
    /// - Throws: AuthError if query fails
    func userExists(email: String) throws -> Bool {
        do {
            return try database.userExists(email: email)
        } catch let dbError as DatabaseError {
            throw AuthError.databaseError(dbError)
        } catch {
            throw AuthError.unknown
        }
    }
    
    // MARK: - Utility Methods
    
    /// Get database statistics
    /// - Returns: Dictionary with database information
    func getDatabaseStats() -> [String: Any] {
        return database.getStats()
    }
    
    /// Close database connection
    func close() {
        database.close()
    }
    
    // MARK: - Private Helper Methods
    
    private func validateEmail(_ email: String) throws {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: email) {
            throw AuthError.invalidEmail
        }
    }
    
    private func validatePassword(_ password: String) throws {
        if password.count < 6 {
            throw AuthError.weakPassword
        }
    }
    
    private func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
