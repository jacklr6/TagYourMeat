//
//  ReaderNFCView.swift
//  TagYourMeat
//
//  Created by Jack Rogers on 7/3/25.
//

import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import Foundation
import SwiftUI
import CoreNFC

enum ReaderNFCFlowRoute: Hashable, Codable {
    case confirmation(itemName: String, packagedLocation: String, tagID: String)
}

struct ReaderNFCNavigationItem: Hashable, Codable {
    let route: ReaderNFCFlowRoute
}

struct ReaderNFCView: View {
    @Environment(\.dismiss) var dismissReaderNFCView
    @StateObject private var auth = AuthViewModel()
    
    @AppStorage("appGradients") private var appGradients: Bool = true
    @State private var path: NavigationPath = NavigationPath()
    @State private var nfcStatus: String = "Waiting to scan..."
    @State private var nfcReader: NFCReader? = nil
    @State private var nfcIsLoading: Bool = false
    @State private var showingNFCAlert = false
    @State private var saveFailedAlert: Bool = false
    
    @State private var tagID: String = ""
    @State private var itemName: String = ""
    @State private var packagedLocation: String = ""
    @State private var scanComplete: Bool = false
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                if appGradients {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.green.opacity(0.1)]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .ignoresSafeArea(edges: .all)
                }
                
                VStack {
                    Text("Scan a Tag to Begin")
                        .font(.system(size: 18, weight: .medium))
                    
                    Button(action: {
                        startNFCRead()
                    }) {
                        Group {
                            if nfcIsLoading {
                                HStack {
                                    ProgressView().tint(.white)
                                }
                            } else {
                                Text("Start Scanning")
                            }
                        }
                        .frame(width: 120)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(scanComplete)
                    .padding(.bottom, scanComplete ? 6 : 0)
                    
                    if nfcStatus != "Tag Read Successfully!" {
                        Text(nfcStatus)
                            .padding(.top, 4)
                            .multilineTextAlignment(.center)
                            .transition(.blurReplace)
                    }
                    
                    if scanComplete {
                        Group {
                            Divider()
                            
                            VStack(spacing: 6) {
                                VStack {
                                    Text("Item Name:")
                                        .fontWeight(.medium)
                                    Text(itemName)
                                }
                                VStack {
                                    Text("Packaged Location:")
                                        .fontWeight(.medium)
                                    Text(packagedLocation)
                                }
                                VStack {
                                    Text("Tag ID:")
                                        .fontWeight(.medium)
                                    Text(tagID)
                                        .padding(.bottom, 6)
                                }
                                
                                Button("Continue") {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        withAnimation {
                                            path.append(ReaderNFCNavigationItem(route: .confirmation(itemName: itemName, packagedLocation: packagedLocation, tagID: tagID)))
                                        }
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .multilineTextAlignment(.center)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
                .frame(width: 360)
                .background(appGradients ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.gray.opacity(0.4)))
                .cornerRadius(20)
                .animation(.default, value: scanComplete)
                .animation(.default, value: nfcStatus)
                .alert("NFC Reader", isPresented: $showingNFCAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(nfcStatus)
                }
                .alert("Save Failed", isPresented: $saveFailedAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Failed to save and sync with Firebase. Please try again later or when better connection is available.")
                }
            }
            .navigationTitle("Read NFC Tags")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(auth.role ?? "")
                }
            }
            .navigationDestination(for: ReaderNFCNavigationItem.self) { navItem in
                switch navItem.route {
                case .confirmation(let item, let location, let tagID):
                    ReaderNFCConfirmation(itemName: item, packagedLocation: location, tagID: tagID) {
                        withAnimation {
                            path.removeLast(path.count)
                            dismissReaderNFCView()
                        }
                    }
                }
            }
        }
    }
    
    private func startNFCRead() {
        nfcReader = NFCReader()
        nfcReader?.beginReading { result, error in
            nfcStatus = (result != nil)
                ? "Tag Read!"
                : "Read Failed: \(error?.localizedDescription ?? "Unknown error")"
            showingNFCAlert = true
            
            if let result = result {
                let parsed = parseNFCPayload(result)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showingNFCAlert = false
                    withAnimation(.easeInOut(duration: 0.8)) {
                        path.append(
                            ReaderNFCNavigationItem(route: .confirmation(
                                itemName: parsed.itemName,
                                packagedLocation: parsed.packagedLocation,
                                tagID: parsed.tagID
                            ))
                        )
                    }
                }
            }
        }
    }
    
    func parseNFCPayload(_ rawPayload: String) -> (itemName: String, packagedLocation: String, tagID: String) {
        guard let itemRange = rawPayload.range(of: "Item:") else {
            return ("", "", "")
        }
        
        let usefulPayload = rawPayload[itemRange.lowerBound...]
        let components = usefulPayload.components(separatedBy: ";")
        
        var itemName = ""
        var packagedLocation = ""
        var tagID = ""
        
        for component in components {
            let trimmed = component.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("Item:") {
                itemName = trimmed.replacingOccurrences(of: "Item:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmed.hasPrefix("Location:") {
                let locationString = trimmed.replacingOccurrences(of: "Location:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                packagedLocation = locationString
            } else if trimmed.hasPrefix("ID:") {
                tagID = trimmed.replacingOccurrences(of: "ID:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return (itemName, packagedLocation, tagID)
    }

}

struct ReaderNFCConfirmation: View {
    let itemName: String
    let packagedLocation: String
    let tagID: String
    let goToRoot: () -> Void
    
    @StateObject private var auth = AuthViewModel()
    @State private var dynamicColor: Color = .green
    @State private var saveFailedAlert: Bool = false
    @State private var infoAlert: Bool = false
    @AppStorage("appGradients") private var appGradients: Bool = true
    @State private var tagExists = false
    @State private var tagOwnerID: String? = nil
    
    var body: some View {
        ZStack {
            if appGradients {
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [dynamicColor, dynamicColor.opacity(0.1)]), startPoint: .bottom, endPoint: .top))
                    .ignoresSafeArea(edges: .all)
            }
            
            VStack {
                VStack {
                    Text("What would you like to do with this newly tagged meat?")
                        .font(.system(size: 18, weight: .medium))
                        .padding(.bottom, 3)
                    if tagExists && tagOwnerID != auth.user?.uid {
                        withAnimation(.easeInOut(duration: 1)) {
                            Text("Congradulations! You can transfer your meat to your TagYourMeat account.")
                                .font(.system(size: 14))
                        }
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.bottom, 5)
                
                Divider()
                    .frame(width: 280)
                
                Text("\(Text(itemName).fontWeight(.semibold)) was packaged in \(Text(packagedLocation).fontWeight(.semibold))")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                
                Divider()
                    .frame(width: 280)
                    .padding(.bottom, 10)
                
                HStack {
                    if tagExists && tagOwnerID != auth.user?.uid {
                        Button(action: {
                            withAnimation {
                                auth.transferMeatTag(tagID: tagID) { success in
                                    if success {
                                        print("Transfer complete!")
                                        goToRoot()
                                    } else {
                                        print("Transfer failed.")
                                        saveFailedAlert = true
                                    }
                                }
                            }
                        }) {
                            Text("Transfer This Tag to Your \(Text("TagYourMeat").fontWeight(.semibold)) Account")
                                .frame(width: 125, height: 100)
                        }
                        .buttonStyle(.borderedProminent)
                    } else if auth.isTransfering {
                        ProgressView()
                            .frame(width: 125, height: 100)
                    } else {
                        Button(action: {
                            withAnimation {
                                auth.addMeatTag(itemName: itemName, packagedLocation: packagedLocation, tagID: tagID) { success in
                                    if success {
                                        goToRoot()
                                        print("Write Successful")
                                    } else {
                                        saveFailedAlert = true
                                    }
                                }
                            }
                        }) {
                            Text("Add to your \(Text("TagYourMeat").fontWeight(.semibold)) Account")
                                .frame(width: 125, height: 100)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Button(action: {
                        goToRoot()
                    }) {
                        Text("Don't Add")
                            .frame(width: 125, height: 100)
                    }
                    .buttonStyle(.bordered)
                }
                
                Text(tagID)
                    .font(.caption)
                    .monospaced(true)
                    .foregroundColor(.gray)
                    .padding(.top, 5)
            }
            .padding(.vertical, 40)
            .padding(.horizontal, 20)
            .frame(width: 360)
            .background(appGradients ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.gray.opacity(0.4)))
            .cornerRadius(20)
        }
        .navigationTitle(Text("Next Steps"))
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("\(auth.role ?? "")")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    infoAlert = true
                }) {
                    Image(systemName: "info.circle")
                }
            }
        }
        .onAppear {
            auth.checkIfTagExistsInMaster(tagID: tagID) { exists, ownerID in
                DispatchQueue.main.async {
                    tagExists = exists
                    tagOwnerID = ownerID
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                withAnimation(.easeInOut(duration: 1.5)) {
                    dynamicColor = .blue
                }
            })
        }
        .alert("Save Failed", isPresented: $saveFailedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Failed to save and sync with the Cloud. Please try again later or when better connection is available.")
        }
        .alert("Info", isPresented: $infoAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You can choose to save this NFC Tag to your TagYourMeat account or not.")
        }
    }
}


#Preview {
    ReaderNFCView()
}
