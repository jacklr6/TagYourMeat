//
//  AuthView.swift
//  TagYourMeat
//
//  Created by Jack Rogers on 6/5/25.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import GoogleSignInSwift
import FirebaseCore
import GoogleSignIn

struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var auth: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isSignUp = false
    
    var roleOptions: [String] = ["Customer", "Butcher"]

    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [isSignUp ? .orange : .yellow, isSignUp ? .teal : .blue]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .ignoresSafeArea(edges: .all)
                
                VStack(spacing: 16) {
                    if auth.isAuthenticated {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .frame(width: UIScreen.main.bounds.width * 0.75, height: 300)
                            
                            VStack {
                                VStack {
                                    Text("Name:")
                                        .fontWeight(.semibold)
                                    TextField("First Name", text: $auth.firstName)
                                        .frame(width: 225)
                                        .textFieldStyle(.roundedBorder)
                                    TextField("Last Name", text: $auth.lastName)
                                        .frame(width: 225)
                                        .textFieldStyle(.roundedBorder)
                                }
                                .padding(.bottom, 10)
                                
                                VStack {
                                    Text("Email:")
                                        .fontWeight(.semibold)
                                    Text("\(auth.user?.email ?? "User")")
                                }
                                .padding(.bottom, 10)
                                
                                VStack {
                                    Text("Role:")
                                        .fontWeight(.semibold)
                                        .padding(.bottom, -12)
                                    Picker("Role", selection: $auth.role) {
                                        ForEach(roleOptions, id: \.self) { role in
                                            Text(role).tag(role)
                                        }
                                    }
                                    .pickerStyle(.automatic)
                                    .onChange(of: auth.role) { _, newRole in
                                        if let newRole = newRole {
                                            auth.setRole(newRole)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .toolbar {
                                ToolbarItem(placement: .topBarLeading) {
                                    Button("Sign Out") {
                                        auth.signOut()
                                        dismiss()
                                    }
                                }
                            }
                        }
                    } else {
                        ZStack {
                            VStack {
                                if isSignUp {
                                    Group {
                                        TextField("First Name", text: $firstName)
                                        TextField("Last Name", text: $lastName)
                                    }
                                    .textFieldStyle(.roundedBorder)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                }
                                
                                TextField("Email", text: $email)
                                    .textFieldStyle(.roundedBorder)
                                    .autocapitalization(.none)
                                
                                SecureField("Password", text: $password)
                                    .textFieldStyle(.roundedBorder)
                                
                                if let error = auth.errorMessage {
                                    Text(error)
                                        .foregroundColor(.red)
                                        .font(.footnote)
                                        .multilineTextAlignment(.center)
                                }
                                
                                Group {
                                    if isSignUp {
                                        Button(action: {
                                            withAnimation {
                                                if password.count < 6 {
                                                    auth.errorMessage = "Password must be at least 6 characters long."
                                                } else if password.count > 48 {
                                                    auth.errorMessage = "Password must be 48 characters or less."
                                                } else {
                                                    auth.signUp(email: email, password: password, firstName: firstName, lastName: lastName) {
                                                        auth.errorMessage = nil
                                                    }
                                                }
                                            }
                                        }) {
                                            Group {
                                                if !auth.isLoading {
                                                    Text("Create Account")
                                                } else {
                                                    ProgressView()
                                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                }
                                            }
                                            .frame(width: 205, height: 27)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .disabled(email.isEmpty && password.isEmpty && firstName.isEmpty && lastName.isEmpty)
                                    } else {
                                        Button(action: {
                                            withAnimation {
                                                auth.signIn(email: email, password: password) {
                                                    auth.errorMessage = nil
                                                    dismiss()
                                                }
                                            }
                                        }) {
                                            Group {
                                                if !auth.isLoading {
                                                    Text("Sign In")
                                                } else {
                                                    ProgressView()
                                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                }
                                            }
                                            .frame(width: 205, height: 27)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .disabled(email.isEmpty && password.isEmpty)
                                    }
                                    
                                    if isSignUp {
                                        SignInWithAppleButton(.signUp, onRequest: { request in
                                            auth.startSignInWithApple()
                                        }, onCompletion: { _ in })
                                        .frame(height: 40)
                                    } else {
                                        SignInWithAppleButton(.signIn, onRequest: { request in
                                            auth.startSignInWithApple()
                                        }, onCompletion: { _ in })
                                        .frame(height: 40)
                                    }
                                    
                                    Group {
                                        if isSignUp {
                                            Button(action: {
                                                handleGoogleSignIn()
                                            }) {
                                                HStack {
                                                    Image("Google-Logo")
                                                        .resizable()
                                                        .frame(width: 15, height: 15)
                                                    Text("Sign up with Google")
                                                        .font(.system(size: 15, weight: .semibold))
                                                }
                                            }
                                        } else {
                                            Button(action: {
                                                handleGoogleSignIn()
                                            }) {
                                                HStack {
                                                    Image("Google-Logo")
                                                        .resizable()
                                                        .frame(width: 15, height: 15)
                                                    Text("Sign in with Google")
                                                        .font(.system(size: 15, weight: .medium))
                                                        
                                                }
                                            }
                                        }
                                    }
                                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                                    .frame(width: 230, height: 40)
                                    .background(colorScheme == .dark ? .white : .black)
                                    .cornerRadius(6)
                                    .padding(.horizontal)
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                
                                Button(isSignUp ? "Already have an account? Sign In" : "No account? Sign Up") {
                                    withAnimation {
                                        isSignUp.toggle()
                                    }
                                }
                            }
                            .frame(width: 230)
                            .animation(.easeInOut, value: isSignUp)
                        }
                        .padding(40)
                        .background(
                            Color.white.opacity(0.275)
                        )
                        .cornerRadius(20)
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
                .onAppear {
                    auth.setup()
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private func handleGoogleSignIn() {
        guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?
                .rootViewController else {
            print("❌ Failed to get root view controller.")
            return
        }

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("❌ Missing Firebase client ID.")
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                print("❌ Google Sign-In failed: \(error.localizedDescription)")
                return
            }

            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString,
                let accessToken = Optional(user.accessToken.tokenString)
            else {
                print("❌ Missing Google tokens.")
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("❌ Firebase Sign-In with Google failed: \(error.localizedDescription)")
                    return
                }

                print("✅ User signed in with Google: \(authResult?.user.uid ?? "")")
            }
        }
    }
}

#Preview {
    TagYourMeatMain()
}
