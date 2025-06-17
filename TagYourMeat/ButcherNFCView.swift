//
//  ButcherNFCView.swift
//  TagYourMeat
//
//  Created by Jack Rogers on 6/6/25.
//

import Foundation
import SwiftUI
import CoreNFC

enum NFCFlowRoute: Hashable, Codable {
    case confirmation(itemName: String, packagedLocation: String, tagID: String)
}

struct NFCNavigationItem: Hashable, Codable {
    let route: NFCFlowRoute
}

struct ButcherNFCView: View {
    @Environment(\.dismiss) var dismissButcherNFCView
    @StateObject private var locationManager = LocationManager()
    @StateObject private var auth = AuthViewModel()
    
    @State private var itemName: String = ""
    @State private var packagedLocation: String = ""
    @State private var nfcStatus: String = "Waiting to scan..."
    @State private var nfcWriter: NFCWriter? = nil
    @State private var nfcReader: NFCReader? = nil
    @State private var showingNFCAlert = false
    @State private var showingLocationAlert = false
    @State private var showPackagingLocation = 0
    @State private var showStartWrite = 0
    @State private var showTextTip: String = "Please Enter a Valid Item Name."
    @State private var reenableTextField = 0
    @State private var checkedLocation: Bool = false
    @State private var buttonText: String = "Next Step"
    @State private var navigateToConfirmView = false
    @State private var path: NavigationPath = NavigationPath()
    @State private var generatedTagID: String = UUID().uuidString
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.red, Color.red.opacity(0.1)]), startPoint: .bottom, endPoint: .top))
                    .ignoresSafeArea(edges: .all)
                
                VStack(spacing: 20) {
                    if !showTextTip.isEmpty {
                        Text(showTextTip)
                            .font(.system(size: 18, weight: .medium))
                            .transition(.blurReplace)
                    }
                    
                    TextField("Item Name (e.g. Ribeye Steak)", text: $itemName)
                        .textFieldStyle(.roundedBorder)
                        .disabled(reenableTextField == 1 ? false : showPackagingLocation == 1)
                    
                    if showPackagingLocation == 1 {
                        HStack {
                            TextField("Packaged at (e.g. Freezer A)", text: $packagedLocation)
                                .textFieldStyle(.roundedBorder)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .disabled(reenableTextField == 1 ? false : showStartWrite == 1)
                            
                            Button(action: {
                                locationManager.checkLocationAuthorization()
                                if locationManager.lastKnownLocation?.latitude != nil {
                                    checkedLocation = true
                                }
                                if let coordinate = locationManager.lastKnownLocation {
                                    packagedLocation = "Lat: \(coordinate.latitude.formatted(.number.precision(.fractionLength(4)))), Lon: \(coordinate.longitude.formatted(.number.precision(.fractionLength(4))))"
                                }
                                if locationManager.locationErrorMessage != nil {
                                    showingLocationAlert = true
                                }
                            }) {
                                if checkedLocation {
                                    Image(systemName: "location.fill")
                                } else {
                                    Image(systemName: "mappin")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    
                    Button(buttonText) {
                        if !itemName.isEmpty {
                            withAnimation {
                                showPackagingLocation = 1
                            }
                        } else {
                            withAnimation {
                                showTextTip = "Please Enter a Valid Item Name."
                            }
                        }
                        
                        if showPackagingLocation == 1 {
                            if !packagedLocation.isEmpty {
                                startNFCWrite()
                                withAnimation {
                                    showStartWrite = 1
                                }
                            } else {
                                withAnimation {
                                    showTextTip = "Please Enter a Valid Packaged Location."
                                }
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .onChange(of: packagedLocation) { _, newValue in
                        withAnimation {
                            buttonText = newValue.isEmpty ? "Next Step" : "Scan NFC Tag"
                        }
                    }
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
                .frame(width: 360)
                .background(Color.white.opacity(0.275))
                .cornerRadius(20)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("\(auth.role ?? "")")
                    }
                }
                .alert("NFC Write", isPresented: $showingNFCAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(nfcStatus)
                }
                .alert("Location Error", isPresented: $showingLocationAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    if let errorMessage = locationManager.locationErrorMessage {
                        Text(errorMessage)
                    }
                }
            }
            .navigationTitle(Text("Write NFC Tags"))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(auth.role ?? "")
                }
            }
            .navigationDestination(for: NFCNavigationItem.self) { navItem in
                switch navItem.route {
                case .confirmation(let item, let location, let tagID):
                    ButcherNFCConfirmation(itemName: item, packagedLocation: location, tagID: tagID) {
                        path.removeLast(path.count)
                        dismissButcherNFCView()
                    }
                }
            }
        }
    }

    private func startNFCWrite() {
        let payload = "Item:\(itemName);Location:\(packagedLocation);Date:\(Date().ISO8601Format());ID:\(generatedTagID)"
        nfcWriter = NFCWriter()
        nfcWriter?.beginWriting(payload: payload) { success, error in
            nfcStatus = success ? "Tag Written!" : "Write Failed: \(error?.localizedDescription ?? "Unknown error")"
            showingNFCAlert = true

            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    navigateToConfirmView = true
                    path.append(NFCNavigationItem(route: .confirmation(itemName: itemName, packagedLocation: packagedLocation, tagID: generatedTagID)))
                }
            } else {
                reenableTextField = 1
            }
        }
    }
    
    private func startNFCRead() {
        nfcReader = NFCReader()
        nfcReader?.beginReading { result, error in
            if let result = result {
                nfcStatus = "Read: \(result)"
            } else {
                nfcStatus = "Read Failed: \(error?.localizedDescription ?? "Unknown error")"
            }
            showingNFCAlert = true
        }
    }
}

struct ButcherNFCConfirmation: View {
    let itemName: String
    let packagedLocation: String
    let tagID: String
    let goToRoot: () -> Void
    
    @StateObject private var auth = AuthViewModel()
    @State private var dynamicColor: Color = .red
    @State private var saveFailedAlert: Bool = false
    @State private var infoAlert: Bool = false
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(gradient: Gradient(colors: [dynamicColor, dynamicColor.opacity(0.1)]), startPoint: .bottom, endPoint: .top))
                .ignoresSafeArea(edges: .all)
            
            VStack {
                Text("What would you like to do with this newly tagged meat?")
                    .font(.system(size: 18, weight: .medium))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 5)
                
                Divider()
                    .frame(width: 280)
                
                Text("\(Text(itemName).fontWeight(.semibold)) was packaged in \(Text(packagedLocation).fontWeight(.semibold))")
                    .font(.subheadline)
                
                Divider()
                    .frame(width: 280)
                    .padding(.bottom, 10)
                
                HStack {
                    Button(action: {
                        auth.addMeatTag(
                            itemName: itemName,
                            packagedLocation: packagedLocation,
                            tagID: tagID
                        ) { success in
                            if success {
                                goToRoot()
                                print("Write Successful")
                            } else {
                                saveFailedAlert = true
                            }
                        }
                    }) {
                        Text("Add to your \(Text("TagYourMeat").fontWeight(.semibold)) Account")
                            .frame(width: 125, height: 80)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: {
                        goToRoot()
                    }) {
                        Text("Don't Add")
                            .frame(width: 125, height: 80)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.vertical, 40)
            .padding(.horizontal, 20)
            .frame(width: 360)
            .background(Color.white.opacity(0.275))
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                withAnimation(.easeInOut(duration: 1.5)) {
                    dynamicColor = .orange
                }
            })
        }
        .alert("Save Failed", isPresented: $saveFailedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Failed to save and sync with Firebase. Please try again later or when better connection is available.")
        }
        .alert("Info", isPresented: $infoAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You can choose to save this NFC Tag to your TagYourMeat account or not.")
        }
    }
}

#Preview {
    ButcherNFCView()
//    ButcherNFCConfirmation(itemName: "Steak", packagedLocation: "Freezer C", tagID: "1234567890")
}
