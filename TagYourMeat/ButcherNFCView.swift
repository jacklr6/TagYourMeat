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
    @State private var saveFailedAlert: Bool = false
    @AppStorage("savedLocation") private var savedLocation: String = ""
    @AppStorage("appGradients") private var appGradients: Bool = true
    @AppStorage("alertSuccessfullyAdded") private var alertSuccessfullyAdded: Bool = false
    @AppStorage("alertSuccessfullyAddedSF") private var alertSuccessfullyAddedSF: Bool = false
    @FocusState private var isLocationFocused: Bool
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                if appGradients {
                    Rectangle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.red, Color.red.opacity(0.1)]), startPoint: .bottom, endPoint: .top))
                        .ignoresSafeArea(edges: .all)
                }
                
                VStack(spacing: 20) {
                    if !showTextTip.isEmpty {
                        Text(showTextTip)
                            .font(.system(size: 18, weight: .medium))
                            .transition(.blurReplace)
                    }
                    
                    TextField("", text: $itemName, prompt: Text("Item Name (e.g. Ribeye Steak)").foregroundColor(.gray))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white)
                        .foregroundStyle(Color.black)
                        .cornerRadius(5)
                        .disabled(reenableTextField == 1 ? false : showPackagingLocation == 1)
                    
                    if showPackagingLocation == 1 {
                        HStack {
                            TextField("", text: $packagedLocation, prompt: Text("Packaged at (e.g. Freezer A)").foregroundColor(.gray))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.white)
                                .foregroundStyle(Color.black)
                                .cornerRadius(5)
                                .focused($isLocationFocused)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .disabled(reenableTextField == 1 ? false : showStartWrite == 1)
                            
                            Button(action: {
                                locationManager.checkLocationAuthorization()
                                if locationManager.lastKnownLocation?.latitude != nil {
                                    checkedLocation = true
                                }
                                if let coordinate = locationManager.lastKnownLocation {
                                    packagedLocation = "Lat: \(coordinate.latitude), Lon: \(coordinate.longitude)"
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
                    
                    HStack {
                        if showPackagingLocation == 1 {
                            Button("Back") {
                                withAnimation {
                                    showPackagingLocation = 0
                                    packagedLocation = ""
                                    showTextTip = "Please Enter a Valid Item Name."
                                }
                            }
                            .buttonStyle(.bordered)
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
//                                    startNFCWrite()
                                    path.append(NFCNavigationItem(route: .confirmation(itemName: itemName, packagedLocation: packagedLocation, tagID: generatedTagID)))
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
                                if newValue.isEmpty {
                                    buttonText = "Next Step"
                                } else {
                                    buttonText = "Scan NFC Tag"
                                }
                            }
                        }
                        
                        if showPackagingLocation == 1 {
                            if !packagedLocation.isEmpty {
                                Button("Cloud Save") {
                                    withAnimation {
                                        auth.addMeatTag(itemName: itemName, packagedLocation: packagedLocation, tagID: generatedTagID) { success in
                                            if success {
                                                dismissButcherNFCView()
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    alertSuccessfullyAdded = true
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                                    alertSuccessfullyAddedSF = true
                                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                                    alertSuccessfullyAdded = false
                                                    alertSuccessfullyAddedSF = false
                                                }
                                            } else {
                                                saveFailedAlert = true
                                            }
                                        }
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
                .frame(width: 360)
                .background(appGradients ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.gray.opacity(0.4)))
                .cornerRadius(20)
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
                .alert("Save Failed", isPresented: $saveFailedAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Failed to save and sync with Firebase. Please try again later or when better connection is available.")
                }
            }
            .navigationTitle(Text("Write NFC Tags"))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(auth.role ?? "")
                }
                ToolbarItem(placement: .keyboard) {
                    if isLocationFocused {
                        Button(action: {
                            packagedLocation.append(contentsOf: savedLocation)
                        }) {
                            if !savedLocation.isEmpty {
                                Text(savedLocation)
                            }
                        }
                    }
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
    @AppStorage("appGradients") private var appGradients: Bool = true
    
    var body: some View {
        ZStack {
            if appGradients {
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [dynamicColor, dynamicColor.opacity(0.1)]), startPoint: .bottom, endPoint: .top))
                    .ignoresSafeArea(edges: .all)
            }
            
            VStack {
                Text("What would you like to do with this newly tagged meat?")
                    .font(.system(size: 18, weight: .medium))
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
                    Button(action: {
                        withAnimation {
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
                
                Text(tagID)
                    .font(.caption)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                withAnimation(.easeInOut(duration: 1.5)) {
                    dynamicColor = .orange
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
    ButcherNFCView()
//    ButcherNFCConfirmation(itemName: "Steak", packagedLocation: "Freezer C", tagID: "1234567890")
}
