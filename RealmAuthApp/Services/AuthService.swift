//
//  AuthService.swift
//  RealmAuthApp
//
//  Created by RealmAuthApp on 2024.
//

import Foundation
import RealmSwift
import CryptoKit

class AuthService {
    private let realm: Realm
    
    init() throws {
        realm = try Realm()
    }
       
    // MARK: - Registration
    func registerUser(username: String, email: String, password: String) throws -> User {
        // Validate input
        try validateEmail(email)
        try validatePassword(password)
        
        // Check if user already exists
        if getUserByEmail(email) != nil {
            throw AuthError.userAlreadyExists
        }
        
        // Hash password
        let hashedPassword = hashPassword(password)
        
        // Create user
        let user = User(username: username, email: email, password: hashedPassword)
        
        // Save to Realm
        do {
            try realm.write {
                realm.add(user)
            }
            return user
        } catch {
            throw AuthError.realmError
        }
    }
    
    // MARK: - Login
    func loginUser(email: String, password: String) throws -> User {
        guard let user = getUserByEmail(email) else {
            throw AuthError.userNotFound
        }
        
        let hashedPassword = hashPassword(password)
        
        if user.password == hashedPassword {
            return user
        } else {
            throw AuthError.invalidCredentials
        }
    }
    
    // MARK: - Helper Methods
    private func getUserByEmail(_ email: String) -> User? {
        return realm.objects(User.self).filter("email == %@", email).first
    }
    
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
    
    // MARK: - User Management
    func getAllUsers() -> [User] {
        return Array(realm.objects(User.self))
    }
    
    func deleteUser(_ user: User) throws {
        do {
            try realm.write {
                realm.delete(user)
            }
        } catch {
            throw AuthError.realmError
        }
    }
    
    enum AuthError: Error, LocalizedError {
        case userAlreadyExists
        case invalidCredentials
        case weakPassword
        case invalidEmail
        case userNotFound
        case realmError
        
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
            case .realmError:
                return "Database error occurred"
            }
        }
    }
}
