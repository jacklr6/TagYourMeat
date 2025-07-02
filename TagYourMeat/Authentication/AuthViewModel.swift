//
//  AuthViewModel.swift
//  TagYourMeet
//
//  Created by Jack Rogers on 6/5/25.
//

import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import AuthenticationServices
import CryptoKit
import GoogleSignIn
import GoogleSignInSwift
import SwiftUI

private var currentNonce: String?

struct MeatTag: Codable, Identifiable {
    var id: String
    var itemName: String
    var packagedLocation: String
    var datePackaged: Date
    
    var notes: String?
    var price: Double?
    var unit: String?
    var expireDate: Date?
    var quantity: Int?
}

class AuthViewModel: NSObject, ObservableObject {
    @Published var user: User? = Auth.auth().currentUser
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var role: String? = "User"
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var isLoading = false
    @Published var isFetching = false
    @Published var MeatTags: [MeatTag] = []

    private let db = Firestore.firestore()
    
    var needsRoleSelection: Bool {
        isAuthenticated && role == nil
    }

    override init() {
        super.init()
    }
    
    func setup() {
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
                    self.role = "User"
                    self.setRole("User")
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
    
    func setFirstName(_ firstName: String) {
        guard let uid = user?.uid else { return }

        db.collection("users").document(uid).setData(["firstName": firstName], merge: true) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "First Name Save Failed: \(error.localizedDescription)"
                    return
                }
                self.firstName = firstName
            }
        }
    }
    
    func setLastName(_ lastName: String) {
        guard let uid = user?.uid else { return }

        db.collection("users").document(uid).setData(["lastName": lastName], merge: true) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Last Name Save Failed: \(error.localizedDescription)"
                    return
                }
                self.lastName = lastName
            }
        }
    }
    
    func fetchUserProfile(for uid: String) {
        withAnimation {
            isLoading = true
            db.collection("users").document(uid).getDocument { snapshot, error in
                if let error = error {
                    print("Error Fetching User Profile: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data() else {
                    print("No Data Found for User \(uid)")
                    return
                }
                
                print("Fetched User Profile: \(data)")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.firstName = data["firstName"] as? String ?? ""
                    self.lastName = data["lastName"] as? String ?? ""
                    self.role = data["role"] as? String
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Storing Meat Tags in Firestore
    func addMeatTag(itemName: String, packagedLocation: String, tagID: String? = nil, completion: @escaping (Bool) -> Void) {
        guard let user = user else {
            self.errorMessage = "No Authenticated User."
            completion(false)
            return
        }

        let tagID = tagID ?? UUID().uuidString
        let tagData: [String: Any] = [
            "id": tagID,
            "itemName": itemName,
            "packagedLocation": packagedLocation,
            "datePackaged": Timestamp(date: Date())
        ]

        db.collection("users")
            .document(user.uid)
            .collection("MeatTags")
            .document(tagID)
            .setData(tagData) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = "Failed to Save Meat Tag: \(error.localizedDescription)"
                        completion(false)
                        return
                    }
                    completion(true)
                }
            }
    }
    
    func deleteMeatTag(_ tag: MeatTag, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let user = user else { return }

        db.collection("users")
            .document(user.uid)
            .collection("MeatTags")
            .document(tag.id)
            .delete { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = "Failed to Delete Meat Tag: \(error.localizedDescription)"
                        completion(false)
                    } else {
                        self.MeatTags.removeAll { $0.id == tag.id }
                        completion(true)
                    }
                }
            }
    }
    
    func fetchMeatTags() {
        isFetching = true
        guard let user = user else { return }

        db.collection("users")
            .document(user.uid)
            .collection("MeatTags")
            .order(by: "datePackaged", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to load meat tags: \(error.localizedDescription)"
                        self.isFetching = false
                    }
                    return
                }

                guard let documents = snapshot?.documents else { return }

                let tags = documents.compactMap { doc -> MeatTag? in
                    let data = doc.data()
                    guard let itemName = data["itemName"] as? String,
                          let packagedLocation = data["packagedLocation"] as? String,
                          let timestamp = data["datePackaged"] as? Timestamp else { return nil }

                    return MeatTag(
                        id: data["id"] as? String ?? doc.documentID,
                        itemName: itemName,
                        packagedLocation: packagedLocation,
                        datePackaged: timestamp.dateValue(),
                        notes: data["notes"] as? String,
                        price: data["price"] as? Double,
                        unit: data["unit"] as? String,
                        expireDate: (data["expireDate"] as? Timestamp)?.dateValue(),
                        quantity: data["quantity"] as? Int
                    )
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.MeatTags = tags
                    withAnimation {
                        self.isFetching = false
                    }
                }
            }
    }
    
    func updateMeatTag(_ tag: MeatTag, completion: @escaping (Bool) -> Void = { _ in }) {
        withAnimation {
            isLoading = true
            guard let user = user else { return }
            
            var data: [String: Any] = [
                "itemName": tag.itemName,
                "packagedLocation": tag.packagedLocation,
                "datePackaged": Timestamp(date: tag.datePackaged),
                "id": tag.id
            ]
            
            if let notes = tag.notes { data["notes"] = notes }
            if let price = tag.price { data["price"] = price }
            if let unit = tag.unit { data["unit"] = unit }
            if let expireDate = tag.expireDate { data["expireDate"] = Timestamp(date: expireDate) }
            if let quantity = tag.quantity { data["quantity"] = quantity }
            
            db.collection("users")
                .document(user.uid)
                .collection("MeatTags")
                .document(tag.id)
                .setData(data, merge: true) { error in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if let error = error {
                            self.errorMessage = "Failed to Update Meat Tag: \(error.localizedDescription)"
                            completion(false)
                            return
                        }
                        self.isLoading = false
                        completion(true)
                    }
                }
        }
    }
    
    // MARK: - Sign In With Apple
    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let random = (0..<16).map { _ in UInt8.random(in: 0...255) }

            random.forEach { byte in
                if remainingLength == 0 { return }
                if byte < charset.count {
                    result.append(charset[Int(byte)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
    
    func startSignInWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

}

extension AuthViewModel: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first ?? UIWindow()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            self.errorMessage = "Apple Sign-In failed: Missing credentials."
            return
        }

        let credential = OAuthProvider.credential(
            providerID: .apple,
            idToken: idTokenString,
            rawNonce: nonce
        )

        isLoading = true
        Auth.auth().signIn(with: credential) { result, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
                    return
                }

                guard let user = result?.user else { return }
                self.user = user
                self.isAuthenticated = true
                self.fetchUserProfile(for: user.uid)
                
                if let fullName = appleIDCredential.fullName {
                    let first = fullName.givenName ?? ""
                    let last = fullName.familyName ?? ""

                    let userData: [String: Any] = [
                        "firstName": first,
                        "lastName": last,
                        "email": user.email ?? ""
                    ]
                    self.db.collection("users").document(user.uid).setData(userData, merge: true)
                    self.firstName = first
                    self.lastName = last
                }
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.errorMessage = "Apple Sign-In error: \(error.localizedDescription)"
    }
}

// MARK: - Sign In With Google
extension AuthViewModel {
    func signInWithGoogle(presentingViewController: UIViewController) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }

            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString
            else {
                self.errorMessage = "Google Sign-In failed to get token"
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    self.errorMessage = "Firebase Sign-In with Google failed: \(error.localizedDescription)"
                    return
                }

                self.user = authResult?.user
                self.isAuthenticated = true
                
                self.fetchUserProfile(for: authResult?.user.uid ?? "")
            }
        }
    }
}
