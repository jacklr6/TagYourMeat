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
    @StateObject private var network = NetworkManager()
    
    var createAccountTip = CreateAccountTip()
    @State private var showCreateAccountTip: Bool = false
    @State private var searchText = ""
    @State private var wifiImageSwitcher: Bool = false
    
    var filteredTags: [MeatTag] {
        withAnimation {
            if searchText.isEmpty {
                return auth.MeatTags
            } else {
                return auth.MeatTags.filter {
                    $0.itemName.localizedCaseInsensitiveContains(searchText) ||
                    $0.packagedLocation.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
    }
    
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
                    if network.isConnected {
                        VStack {
                            if auth.isFetching {
                                List {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                        Spacer()
                                    }
                                }
                                .searchable(text: $searchText, prompt: "Search Meat or Location")
                            } else {
                                List {
                                    ForEach(filteredTags) { tag in
                                        NavigationLink(destination: TaggedMeatDetails(tag: tag).environmentObject(auth)) {
                                            VStack(alignment: .leading) {
                                                Text(tag.itemName)
                                                    .font(.system(size: 22, weight: .semibold))
                                                Text("Location: \(tag.packagedLocation)")
                                                    .font(.subheadline)
                                                Text("Date: \(tag.datePackaged.formatted(.dateTime.month().day().year().hour().minute()))")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .padding(.vertical, 5)
                                    }
                                    .onDelete { indexSet in
                                        indexSet.forEach { index in
                                            let tag = auth.MeatTags[index]
                                            auth.deleteMeatTag(tag)
                                        }
                                    }
                                }
                                .animation(.easeInOut(duration: 2), value: auth.MeatTags.count)
                                .animation(.easeInOut(duration: 2), value: filteredTags.count)
                                .refreshable {
                                    withAnimation {
                                        auth.fetchMeatTags()
                                    }
                                }
                                .searchable(text: $searchText, prompt: "Search Meat or Location")
                                .overlay {
                                    if !searchText.isEmpty && filteredTags.isEmpty {
                                        ContentUnavailableView.search(text: searchText)
                                    }
                                }
                            }
                        }
                        .animation(.easeInOut, value: auth.isFetching)
                    } else {
                        VStack {
                            Image(systemName: wifiImageSwitcher ? "wifi.exclamationmark" : "wifi")
                                .font(.system(size: 48))
                                .contentTransition(.symbolEffect(.replace))
                                .frame(width: 50, height: 50)
                            Text("Network Unavailable")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Please connect to the internet to use TagYourMeat and it's services.")
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                    }
                }
            }
            .onChange(of: auth.user?.email) { _, newValue in
                auth.fetchMeatTags()
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
                                Text("\(auth.firstName.first?.uppercased() ?? "")\(auth.lastName.first?.uppercased() ?? "")")
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
                    if auth.isAuthenticated && network.isConnected {
                        NavigationLink(destination: ButcherNFCView()) {
                            Image(systemName: "plus")
                        }
                    } else if auth.isAuthenticated == false || network.isConnected == false {
                        Button { showCreateAccountTip = true } label: {
                            Image(systemName: "plus")
                                .foregroundColor(network.isConnected ? .gray : .blue)
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    wifiImageSwitcher = true
                }
                if network.isConnected {
                    auth.fetchMeatTags()
                }
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

extension MeatTag {
    static let samples: [MeatTag] = [
        MeatTag(id: "1", itemName: "Ribeye Steak", packagedLocation: "Freezer A", datePackaged: Date()),
        MeatTag(id: "2", itemName: "Ground Beef", packagedLocation: "Freezer B", datePackaged: Date().addingTimeInterval(-86400)),
        MeatTag(id: "3", itemName: "Chicken Breast", packagedLocation: "Fridge C", datePackaged: Date().addingTimeInterval(-172800))
    ]
}
