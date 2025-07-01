//
//  Settings.swift
//  TagYourMeat
//
//  Created by Jack Rogers on 6/30/25.
//

import SwiftUI
import StoreKit
import TipKit

struct TagYourMeatSettings: View {
    @State private var checkOSVersion: String = ""
    @State private var isTestFlight: Bool = false
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Settings")) {
                    Text("Coming soon!")
                }
                
                if !isTestFlight {
                    Section(header: Text("Developer"), footer: Text("Only available to beta testers in TestFlight.")) {
                        NavigationLink(destination: DeveloperView(), label: {
                            HStack {
                                Text("Developer Settings")
                                Spacer()
                                Image(systemName: "hammer.fill")
                            }
                        })
                    }
                }
                
                Section {
                    HStack {
                        Spacer()
                        VStack {
                            Text("TagYourMeat for \(checkOSVersion) | \(Text("\(appVersion) Beta").fontWeight(.bold).foregroundStyle(LinearGradient(gradient: Gradient(colors: [.green, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing)))")
                            Text("Jack Rogers | 2025")
                        }
                        .font(.footnote)
                        Spacer()
                    }
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
                    .ignoresSafeArea(.all)
                }
            }
            .navigationTitle(Text("Settings"))
            .onAppear {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    checkOSVersion = "iPadOS"
                } else if UIDevice.current.userInterfaceIdiom == .phone {
                    checkOSVersion = "iOS"
                } else if UIDevice.current.userInterfaceIdiom == .carPlay {
                    checkOSVersion = "CarPlay"
                }
            }
            .task {
                isTestFlight = await isTestFlightBuild()
            }
        }
    }
    
    func isTestFlightBuild() async -> Bool {
        do {
            let verificationResult = try await AppTransaction.shared
            switch verificationResult {
            case .verified(let appTransaction):
                return appTransaction.environment == .sandbox
            case .unverified(_, let verificationError):
                print("App transaction unverified: \(verificationError)")
                return false
            }
        } catch {
            print("Error getting AppTransaction: \(error)")
            return false
        }
    }
}

struct DeveloperView: View {
    @Environment(\.openURL) private var openURL
    @AppStorage("appOpenCount") private var appOpenCount: Int = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section(header: Text("Reset Variables")) {
                        Group {
                            Button(action: {
                                Task {
                                    try Tips.resetDatastore()
                                }
                            }) {
                                Text("Reset Tips")
                            }
                            
                            Button(action: {
                                Task {
                                    appOpenCount = 0
                                }
                            }) {
                                Text("Reset App Open Count")
                            }
                        }
                        .tint(.red)
                        .fontWeight(.semibold)
                    }
                    .listSectionSpacing(60)
                    
                    Section {
                        HStack {
                            Spacer()
                            VStack {
                                Image(systemName: "sensor.tag.radiowaves.forward")
                                    .font(.system(size: 48))
                                    .shadow(color: Color.black.opacity(0.4), radius: 6, x: 8, y: 8)
                                Text("Test With NFC Tags")
                                    .font(.system(size: 24, weight: .semibold))
                                Text("To test TagYourMeat, place an \(Text("NTAG215").fontWeight(.semibold)) tag on your iPhone to scan it into the app.")
                            }
                            Spacer()
                        }
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8)
                    }
                    .listSectionSpacing(10)
                    
                    Section {
                        Button {
                            if let url = URL(string: "https://www.amazon.com/ntag215/s?k=ntag215") {
                                openURL(url)
                            }
                        } label: {
                            Label("Purchase NTAG215 on Amazon", systemImage: "cart")
                        }
                    }
                    
                    Section {
                        HStack {
                            Spacer()
                            VStack {
                                Image(systemName: "bubble.and.pencil")
                                    .font(.system(size: 48))
                                    .padding(.top, -5)
                                    .shadow(color: Color.black.opacity(0.4), radius: 6, x: 8, y: 8)
                                Text("Submit Feedback")
                                    .font(.system(size: 24, weight: .semibold))
                                Text("Follow the link below to submit feedback to the TestFlight App or in my GitHub Repo!")
                            }
                            Spacer()
                        }
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8)
                    }
                    
                    Section {
                        Button {
                            if let url = URL(string: "itms-beta://") {
                                openURL(url)
                            }
                        } label: {
                            Label("Submit Feedback via TestFlight", systemImage: "arrow.turn.up.right")
                        }
                    }
                    .listSectionSpacing(10)
                    
                    Section {
                        Button {
                            if let url = URL(string: "https://github.com/jacklr6/") {
                                openURL(url)
                            }
                        } label: {
                            Label("Submit Feedback via GitHub", systemImage: "network")
                        }
                    }
                    .listSectionSpacing(10)
                }
            }
            .navigationTitle(Text("Developer"))
        }
    }
}

#Preview {
    TagYourMeatSettings()
}
