//
//  User.swift
//  RealmAuthApp
//
//  Created by RealmAuthApp on 2024.
//

import Foundation
import RealmSwift

class User: Object {
    @Persisted var id: String = UUID().uuidString
    @Persisted var username: String = ""
    @Persisted var email: String = ""
    @Persisted var password: String = ""
    @Persisted var createdAt: Date = Date()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(username: String, email: String, password: String) {
        self.init()
        self.username = username
        self.email = email
        self.password = password
    }
}
