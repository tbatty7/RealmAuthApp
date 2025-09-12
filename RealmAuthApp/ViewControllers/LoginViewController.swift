//
//  LoginViewController.swift
//  RealmAuthApp
//
//  Created by RealmAuthApp on 2024.
//

import UIKit

class LoginViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var welcomeLabel: UILabel!
    
    // MARK: - Properties
    private var authService: RefactoredAuthService!
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAuthService()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Login"
        
        // Configure welcome label
        welcomeLabel.text = "Welcome Back!"
        welcomeLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        welcomeLabel.textAlignment = .center
        
        // Configure text fields
        emailTextField.borderStyle = .roundedRect
        emailTextField.placeholder = "Email"
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.delegate = self
        
        passwordTextField.borderStyle = .roundedRect
        passwordTextField.placeholder = "Password"
        passwordTextField.isSecureTextEntry = true
        passwordTextField.delegate = self
        
        // Configure buttons
        loginButton.backgroundColor = .systemBlue
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 8
        
        signupButton.setTitleColor(.systemBlue, for: .normal)
        signupButton.backgroundColor = .clear
    }
    
    private func setupAuthService() {
        do {
            let database = try DatabaseFactory.createDefaultUserDb()
            authService = RefactoredAuthService(database: database)
        } catch {
            showAlert(title: "Error", message: "Failed to initialize authentication service")
        }
    }
    
    // MARK: - IBActions
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter both email and password")
            return
        }
        
        // Attempt to login user
        do {
            let user = try authService.loginUser(email: email, password: password)
            showAlert(title: "Success", message: "Welcome back, \(user.username)!") { [weak self] in
                self?.navigateToMainApp()
            }
        } catch let error as RefactoredAuthService.AuthError {
            showAlert(title: "Login Failed", message: error.localizedDescription)
        } catch {
            showAlert(title: "Error", message: "An unexpected error occurred")
        }
    }
    
    @IBAction func signupButtonTapped(_ sender: UIButton) {
        navigateToSignup()
    }
    
    // MARK: - Navigation
    private func navigateToSignup() {
        if let signupVC = storyboard?.instantiateViewController(withIdentifier: "SignupViewController") as? SignupViewController {
            navigationController?.pushViewController(signupVC, animated: true)
        }
    }
    
    private func navigateToMainApp() {
        // In a real app, you would navigate to your main app interface
        // For this example, we'll just show a success message and stay on login
        print("User successfully logged in - navigate to main app")
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
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case emailTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            textField.resignFirstResponder()
            loginButtonTapped(loginButton)
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}
