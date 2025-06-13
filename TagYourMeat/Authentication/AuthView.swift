//
//  AuthView.swift
//  TagYourMeat
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
                                    if auth.role == nil {
                                        Text("(Select a Role)")
                                            .foregroundColor(.secondary)
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
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .frame(width: UIScreen.main.bounds.width * 0.75, height: isSignUp ? 325 : 225)
                            
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
                                
                                Button(action: {
                                    withAnimation {
                                        if isSignUp {
                                            if password.count < 6 {
                                                auth.errorMessage = "Password must be at least 6 characters long."
                                            } else if password.count > 48 {
                                                auth.errorMessage = "Password must be 48 characters or less."
                                            } else {
                                                auth.signUp(email: email, password: password, firstName: firstName, lastName: lastName) { }
                                            }
                                        } else {
                                            auth.signIn(email: email, password: password) {
                                                dismiss()
                                            }
                                        }
                                    }
                                }) {
                                    if auth.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .foregroundColor(.white)
                                    } else {
                                        Text(isSignUp ? "Create Account" : "Sign In")
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .transition(.move(edge: .top).combined(with: .opacity))
                                
                                Button(isSignUp ? "Already have an account? Sign In" : "No account? Sign Up") {
                                    withAnimation {
                                        isSignUp.toggle()
                                    }
                                }
                            }
                            .frame(width: 225)
                            .animation(.easeInOut, value: isSignUp)
                        }
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
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

#Preview {
    TagYourMeatMain()
}
