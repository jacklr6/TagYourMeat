//
//  AuthViewModel.swift
//  TagYourMeet
//
//  Created by Jack Rogers on 6/5/25.
//

import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var user: User? = Auth.auth().currentUser
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var role: String?
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var isLoading = false

    private let db = Firestore.firestore()
    
    var needsRoleSelection: Bool {
        isAuthenticated && role == nil
    }

    init() {
        self.user = Auth.auth().currentUser
        self.isAuthenticated = user != nil

        if let user = user {
            fetchUserProfile(for: user.uid)
        }
    }

    func signUp(email: String, password: String, firstName: String, lastName: String, completion: @escaping () -> Void) {
        isLoading = true
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
                return
            }

            guard let user = result?.user else {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }

            let userData: [String: Any] = [
                "firstName": firstName,
                "lastName": lastName,
                "email": email
            ]

            self.db.collection("users").document(user.uid).setData(userData) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                        return
                    }

                    self.user = user
                    self.isAuthenticated = true
                    self.fetchUserProfile(for: user.uid)
                    self.isLoading = false
                    completion()
                }
            }
        }
    }

    func signIn(email: String, password: String, completion: @escaping () -> Void) {
        isLoading = true
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Sign In Failed: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }

                self.user = result?.user
                self.fetchUserProfile(for: result?.user.uid ?? "")
                self.isAuthenticated = true
                self.isLoading = false
                completion()
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.isAuthenticated = false
            self.role = nil
        } catch {
            self.errorMessage = "Sign Out Failed: \(error.localizedDescription)"
        }
    }

    func setRole(_ role: String) {
        guard let uid = user?.uid else { return }

        db.collection("users").document(uid).setData(["role": role], merge: true) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Role Save Failed: \(error.localizedDescription)"
                    return
                }
                self.role = role
            }
        }
    }
    
    func fetchUserProfile(for uid: String) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("⚠️ Error fetching user profile: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data() else {
                print("⚠️ No data found for user \(uid)")
                return
            }

            print("✅ Fetched user profile: \(data)")

            DispatchQueue.main.async {
                self.firstName = data["firstName"] as? String ?? ""
                self.lastName = data["lastName"] as? String ?? ""
                self.role = data["role"] as? String
            }
        }
    }
}
