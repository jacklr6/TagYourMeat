//
//  ContentView.swift
//  TagYourMeet
//
//  Created by Jack Rogers on 6/5/25.
//

import SwiftUI

struct TagYourMeetMain: View {
    @State private var moveToAuthView = false
    @StateObject private var auth = AuthViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                if !auth.isAuthenticated {
                    VStack {
                        Text("Please sign in to continue.")
                        Button("Sign In") {
                            moveToAuthView = true
                        }
                    }
                } else {
                    VStack {
                        Text("Hello, \(auth.user?.email ?? "User")")
                        Text("Role: \(auth.role ?? "unknown")")
                        .buttonStyle(.bordered)
                    }
                }
            }
            .navigationTitle(Text("TagYourMeet"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        moveToAuthView = true
                    } label: {
                        Image(systemName: "person.circle")
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
    TagYourMeetMain()
}
