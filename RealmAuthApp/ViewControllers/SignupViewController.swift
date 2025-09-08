//
//  SignupViewController.swift
//  RealmAuthApp
//
//  Created by RealmAuthApp on 2024.
//

import UIKit

class SignupViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    
    // MARK: - Properties
    private var authService: AuthService!
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAuthService()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Sign Up"
        
        // Configure text fields
        usernameTextField.borderStyle = .roundedRect
        usernameTextField.placeholder = "Username"
        usernameTextField.autocapitalizationType = .none
        
        emailTextField.borderStyle = .roundedRect
        emailTextField.placeholder = "Email"
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        
        passwordTextField.borderStyle = .roundedRect
        passwordTextField.placeholder = "Password"
        passwordTextField.isSecureTextEntry = true
        
        confirmPasswordTextField.borderStyle = .roundedRect
        confirmPasswordTextField.placeholder = "Confirm Password"
        confirmPasswordTextField.isSecureTextEntry = true
        
        // Configure buttons
        signupButton.backgroundColor = .systemBlue
        signupButton.setTitleColor(.white, for: .normal)
        signupButton.layer.cornerRadius = 8
        
        loginButton.setTitleColor(.systemBlue, for: .normal)
        loginButton.backgroundColor = .clear
    }
    
    private func setupAuthService() {
        do {
            authService = try AuthService()
        } catch {
            showAlert(title: "Error", message: "Failed to initialize authentication service")
        }
    }
    
    // MARK: - IBActions
    @IBAction func signupButtonTapped(_ sender: UIButton) {
        guard let username = usernameTextField.text, !username.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
            showAlert(title: "Error", message: "Please fill in all fields")
            return
        }
        
        // Check if passwords match
        guard password == confirmPassword else {
            showAlert(title: "Error", message: "Passwords do not match")
            return
        }
        
        // Attempt to register user
        do {
            let user = try authService.registerUser(username: username, email: email, password: password)
            showAlert(title: "Success", message: "Account created successfully!") { [weak self] in
                self?.navigateToLogin()
            }
        } catch let error as AuthService.AuthError {
            showAlert(title: "Registration Failed", message: error.localizedDescription)
        } catch {
            showAlert(title: "Error", message: "An unexpected error occurred")
        }
    }
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        navigateToLogin()
    }
    
    // MARK: - Navigation
    private func navigateToLogin() {
        if let loginVC = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
            navigationController?.pushViewController(loginVC, animated: true)
        }
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension SignupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case usernameTextField:
            emailTextField.becomeFirstResponder()
        case emailTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            confirmPasswordTextField.becomeFirstResponder()
        case confirmPasswordTextField:
            textField.resignFirstResponder()
            signupButtonTapped(signupButton)
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}
