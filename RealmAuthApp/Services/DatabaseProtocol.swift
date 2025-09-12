//
//  DatabaseProtocol.swift
//  RealmAuthApp
//
//  Created by RealmAuthApp on 2024.
//  Database abstraction protocol for user management
//

import Foundation

/// Database errors that can occur during operations
enum DatabaseError: Error, LocalizedError, Equatable {
    case connectionFailed
    case saveFailed
    case deleteFailed
    case queryFailed
    case userNotFound
    case duplicateUser
    case migrationFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Failed to connect to database"
        case .saveFailed:
            return "Failed to save user to database"
        case .deleteFailed:
            return "Failed to delete user from database"
        case .queryFailed:
            return "Failed to query database"
        case .userNotFound:
            return "User not found in database"
        case .duplicateUser:
            return "User already exists in database"
        case .migrationFailed:
            return "Database migration failed"
        case .unknown:
            return "An unknown database error occurred"
        }
    }
}

/// Protocol that abstracts database operations for user management
protocol UserDatabaseProtocol {
    
    // MARK: - Lifecycle
    
    /// Initialize the database connection
    /// - Throws: DatabaseError if connection fails
    init(config: Any?) throws
    
    // MARK: - User Operations
    
    /// Save a user to the database
    /// - Parameter user: The user to save
    /// - Returns: The saved user (may include database-generated fields)
    /// - Throws: DatabaseError if save fails or user already exists
    func saveUser(_ user: DomainUser) throws -> DomainUser
    
    /// Find a user by email address
    /// - Parameter email: The email to search for
    /// - Returns: The user if found, nil otherwise
    /// - Throws: DatabaseError if query fails
    func findUserByEmail(_ email: String) throws -> DomainUser?
    
    /// Find a user by ID
    /// - Parameter id: The user ID to search for
    /// - Returns: The user if found, nil otherwise
    /// - Throws: DatabaseError if query fails
    func findUserById(_ id: String) throws -> DomainUser?
    
    /// Get all users from the database
    /// - Returns: Array of all users
    /// - Throws: DatabaseError if query fails
    func getAllUsers() throws -> [DomainUser]
    
    /// Update an existing user
    /// - Parameter user: The user with updated information
    /// - Returns: The updated user
    /// - Throws: DatabaseError if update fails or user not found
    func updateUser(_ user: DomainUser) throws -> DomainUser
    
    /// Delete a user from the database
    /// - Parameter userId: The ID of the user to delete
    /// - Returns: True if user was deleted, false if user wasn't found
    /// - Throws: DatabaseError if deletion fails
    func deleteUser(userId: String) throws -> Bool
    
    /// Check if a user with the given email exists
    /// - Parameter email: The email to check
    /// - Returns: True if user exists, false otherwise
    /// - Throws: DatabaseError if query fails
    func userExists(email: String) throws -> Bool
    
    // MARK: - Database Management
    
    /// Close the database connection
    func close()
    
    /// Get database statistics (optional)
    /// - Returns: Dictionary with database stats (e.g., user count, database size)
    func getStats() -> [String: Any]
}
