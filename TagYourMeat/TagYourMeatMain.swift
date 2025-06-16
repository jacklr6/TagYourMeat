//
//  ContentView.swift
//  TagYourMeat
//
//  Created by Jack Rogers on 6/5/25.
//

import SwiftUI

struct TagYourMeatMain: View {
    @State private var moveToAuthView = false
    @StateObject private var auth = AuthViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                if !auth.isAuthenticated {
                    VStack {
                        Image(systemName: "person.slash.fill")
                            .font(.system(size: 72))
                            .symbolEffect(.wiggle, options: .nonRepeating)
                        Text("Please Sign In to Continue.")
                            .font(.system(size: 18, weight: .semibold))
                        Button("Sign In") {
                            moveToAuthView = true
                        }
                    }
                } else {
                    VStack {
                        Text("Welcome Back, \(auth.firstName) \(auth.lastName)")
                        Text("Email: \(auth.user?.email ?? "User")")
                        Text("Role: \(auth.role ?? "unknown")")
                        .buttonStyle(.bordered)
                    }
                    .frame(width: UIScreen.main.bounds.width * 0.75, height: 300)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .shadow(color: .blue, radius: 20, x: 0, y: 0)
                }
            }
            .navigationTitle(Text("TagYourMeat"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        moveToAuthView = true
                    } label: {
                        if auth.isAuthenticated {
                            HStack {
                                Image(systemName: "person.circle")
                                Text("\(auth.firstName.first?.uppercased() ?? "?")\(auth.lastName.first?.uppercased() ?? "?")")
                            }
                        } else {
                            Image(systemName: "person.circle")
                        }
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("\(auth.role ?? "")")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: ButcherNFCView()) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .sheet(isPresented: $moveToAuthView) {
            AuthView()
                .environmentObject(auth)
        }
    }
}

#Preview {
    TagYourMeatMain()
}
