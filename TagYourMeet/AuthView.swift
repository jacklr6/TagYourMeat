//
//  AuthView.swift
//  TagYourMeet
//
//  Created by Jack Rogers on 6/5/25.
//

import SwiftUI

struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isSignUp = false
    @State private var isAwaitingRoleSelection = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)

                if isSignUp {
                    TextField("First Name", text: $firstName)
                        .textFieldStyle(.roundedBorder)
                    TextField("Last Name", text: $lastName)
                        .textFieldStyle(.roundedBorder)
                }

                if let error = auth.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }

                Button(isSignUp ? "Create Account" : "Sign In") {
                    if isSignUp {
                        auth.signUp(email: email, password: password, firstName: firstName, lastName: lastName) {
                            isAwaitingRoleSelection = true
                        }
                    } else {
                        auth.signIn(email: email, password: password) {
                            dismiss()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                
                if auth.isAuthenticated {
                    if isSignUp == false {
                        Button("Sign Out") {
                            auth.signOut()
                            dismiss()
                        }
                    }
                }

                Button(isSignUp ? "Already have an account? Sign In" : "No account? Sign Up") {
                    isSignUp.toggle()
                }
                
                if isAwaitingRoleSelection == true && auth.role == nil {
                    VStack(spacing: 12) {
                        Text("Are you a...").bold()
                        Button("Butcher") {
                            auth.setRole("Butcher")
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Customer") {
                            auth.setRole("Customer")
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 24)
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}
