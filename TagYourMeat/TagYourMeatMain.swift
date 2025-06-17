//
//  ContentView.swift
//  TagYourMeat
//
//  Created by Jack Rogers on 6/5/25.
//

import SwiftUI
import TipKit

struct TagYourMeatMain: View {
    @AppStorage("appHasBeenLoaded") private var appHasBeenLoaded: Bool = false
    @State private var moveToAuthView = false
    @StateObject private var auth = AuthViewModel()
    
    var createAccountTip = CreateAccountTip()
    @State private var showCreateAccountTip: Bool = false

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
                        
                        if showCreateAccountTip {
                            TipView(createAccountTip, arrowEdge: .top)
                                .frame(width: 300)
                                .transition(.opacity)
                        }
                    }
                } else {
                    List {
                        ForEach(auth.meatTags) { tag in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(tag.itemName)
                                    .font(.headline)
                                Text("Location: \(tag.packagedLocation)")
                                    .font(.subheadline)
                                Text("Date: \(tag.datePackaged.formatted(.dateTime.month().day().year().hour().minute()))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .onAppear {
                        auth.fetchMeatTags()
                    }
                    .refreshable {
                        auth.fetchMeatTags()
                    }
                }
            }
            .navigationTitle("TagYourMeat")
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
                    if auth.isAuthenticated {
                        NavigationLink(destination: ButcherNFCView()) {
                            Image(systemName: "plus")
                        }
                    } else {
                        Button {
                            showCreateAccountTip = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundColor(.blue)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .onAppear {
                auth.setup()
                appHasBeenLoaded = true
            }
            .task {
                do {
//                    Reset Tips
//                    try Tips.resetDatastore()
                    try Tips.configure()
                    print("TipKit Configured!")
                } catch {
                    print("TipKit Error: \(error.localizedDescription)")
                }
            }
        }
        .sheet(isPresented: $moveToAuthView) {
            AuthView()
                .environmentObject(auth)
        }
    }
}

struct CreateAccountTip: Tip {
    var title: Text { Text("Sign In/Create Account") }
    var message: Text? { Text("Please Sign In or Create an Account with TagYourMeat to access all features.") }
    var image: Image? { Image(systemName: "person.crop.circle.badge.questionmark") }
}

#Preview {
    TagYourMeatMain()
}
