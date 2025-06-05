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

    private let db = Firestore.firestore()

    init() {
        self.user = Auth.auth().currentUser
        self.isAuthenticated = user != nil

        if let user = user {
            fetchRole(for: user.uid)
        }
    }

    func signUp(email: String, password: String, firstName: String, lastName: String, completion: @escaping () -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Sign Up Failed: \(error.localizedDescription)"
                    return
                }

                guard let user = result?.user else { return }
                self.user = user
                self.isAuthenticated = true

                let db = Firestore.firestore()
                db.collection("users").document(user.uid).setData([
                    "firstName": firstName,
                    "lastName": lastName
                ], merge: true)

                completion()
            }
        }
    }

    func signIn(email: String, password: String, completion: @escaping () -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Sign In Failed: \(error.localizedDescription)"
                    return
                }

                self.user = result?.user
                self.isAuthenticated = true

                if let uid = result?.user.uid {
                    self.fetchRole(for: uid)
                }

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

    func fetchRole(for uid: String) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            DispatchQueue.main.async {
                if let data = snapshot?.data(), let role = data["role"] as? String {
                    self.role = role
                }
            }
        }
    }
}
