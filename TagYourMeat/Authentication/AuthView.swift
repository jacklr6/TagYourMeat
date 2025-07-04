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
    @AppStorage("appGradients") private var appGradients: Bool = true
    
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isSignUp = false
    @State private var showAppRoleAlert: Bool = false
    
    var roleOptions: [String] = ["User", "Butcher"]

    var body: some View {
        NavigationStack {
            ZStack {
                if appGradients {
                    Rectangle()
                        .fill(LinearGradient(gradient: Gradient(colors: [isSignUp ? .orange : .yellow, isSignUp ? .teal : .blue]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .ignoresSafeArea(edges: .all)
                }
                
                VStack(spacing: 16) {
                    if auth.isAuthenticated {
                        VStack {
                            if auth.isLoading {
                                ProgressView()
                            } else {
                                VStack {
                                    Text("TagYourMeat")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .shadow(radius: 5, x: 0, y: 10)
                                }
                                
                                VStack {
                                    Text("Name:")
                                        .fontWeight(.semibold)
                                    TextField("", text: $auth.firstName, prompt: Text("First Name").foregroundColor(.gray))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.white)
                                        .foregroundStyle(Color.black)
                                        .cornerRadius(5)
                                        .onChange(of: auth.firstName) { _, name in
                                            auth.setFirstName(name)
                                        }
                                    TextField("", text: $auth.lastName, prompt: Text("Last Name").foregroundColor(.gray))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.white)
                                        .foregroundStyle(Color.black)
                                        .cornerRadius(5)
                                        .onChange(of: auth.lastName) { _, name in
                                            auth.setLastName(name)
                                        }
                                }
                                .frame(width: UIScreen.main.bounds.width * 0.55)
                                .padding(.bottom, 10)
                                
                                VStack {
                                    Text("Email:")
                                        .fontWeight(.semibold)
                                    Text("\(auth.email)")
                                }
                                .padding(.bottom, 10)
                                
                                VStack {
                                    HStack {
                                        Text("App Role:")
                                            .fontWeight(.semibold)
                                        Image(systemName: "info.circle")
                                            .onTapGesture {
                                                showAppRoleAlert = true
                                            }
                                    }
                                    .padding(.bottom, -12)
                                    Picker("Role", selection: $auth.role) {
                                        ForEach(roleOptions, id: \.self) { role in
                                            Text(role).tag(role)
                                        }
                                    }
                                    .tint(.primary)
                                    .onAppear {
                                        if auth.role == nil {
                                            auth.role = "User"
                                        }
                                    }
                                    .onChange(of: auth.role) { _, newRole in
                                        withAnimation {
                                            if let newRole = newRole {
                                                auth.setRole(newRole)
                                            }
                                        }
                                    }
                                    .tint(.black)
                                }
                            }
                        }
                        .animation(.easeInOut, value: auth.isLoading)
                        .padding(.vertical, 30)
                        .padding(.horizontal, 30)
                        .background(appGradients ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.gray.opacity(0.4)))
                        .cornerRadius(20)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Sign Out") {
                                    auth.signOut()
                                    dismiss()
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                }
                            }
                        }
                    } else {
                        ZStack {
                            VStack {
                                Group {
                                    if isSignUp {
                                        Group {
                                            TextField("First Name", text: $firstName, prompt: Text("First Name").foregroundColor(.gray))
                                            TextField("Last Name", text: $lastName, prompt: Text("Last Name").foregroundColor(.gray))
                                        }
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                    }
                                    
                                    TextField("", text: $email, prompt: Text("Email").foregroundColor(.gray))
                                        .autocapitalization(.none)
                                    
                                    SecureField("Password", text: $password, prompt: Text("Password").foregroundColor(.gray))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.white)
                                .foregroundStyle(Color.black)
                                .cornerRadius(5)
                                
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
                                                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
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
                                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
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
                                                auth.handleGoogleSignIn()
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
                                                auth.handleGoogleSignIn()
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
                                    .foregroundStyle(colorScheme == .light ? .black : .white)
                                    .frame(width: 230, height: 39)
                                    .background(colorScheme == .light ? .white : .black)
                                    .cornerRadius(6)
                                    .padding(.horizontal)
                                    .padding(.bottom, 5)
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                
                                Button(isSignUp ? "Already have an account? Sign In" : "No account? Sign Up") {
                                    withAnimation {
                                        isSignUp.toggle()
                                    }
                                }
                                .foregroundColor(colorScheme == .dark ? .white : .blue)
                            }
                            .frame(width: 230)
                            .animation(.easeInOut, value: isSignUp)
                        }
                        .padding(.vertical, 30)
                        .padding(.horizontal, 30)
                        .background(appGradients ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.gray.opacity(0.4)))
                        .cornerRadius(20)
                    }
                }
                .padding()
                .toolbar {
                    if !auth.isAuthenticated {
                        ToolbarItem(placement: .topBarLeading) {
                            Text(isSignUp ? "Create an Account" : "Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    
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
        .alert("TagYourMeat Role", isPresented: $showAppRoleAlert) {
            Button("OK", role: .cancel) { showAppRoleAlert = false }
        } message: {
            Text("Choose your app interface based on your needs. The USER interface allows you to scan in tags already scanned by your butcher. The BUTCHER interface allows you to write information to an NFC tag for the consumer.")
        }
    }
}

#Preview {
    TagYourMeatMain()
}
