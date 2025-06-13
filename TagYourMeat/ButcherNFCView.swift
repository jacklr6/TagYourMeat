//
//  ButcherNFCView.swift
//  TagYourMeat
//
//  Created by Jack Rogers on 6/6/25.
//

import SwiftUI
import CoreNFC

struct ButcherNFCView: View {
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
    
    var body: some View {
        VStack(spacing: 20) {
            if !showTextTip.isEmpty {
                Text(showTextTip)
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
        .padding()
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

    private func startNFCWrite() {
        let payload = "Item:\(itemName);Location:\(packagedLocation);Date:\(Date().ISO8601Format())"
        nfcWriter = NFCWriter()
        nfcWriter?.beginWriting(payload: payload) { success, error in
            nfcStatus = success ? "Tag Written!" : "Write Failed: \(error?.localizedDescription ?? "Unknown error")"
            showingNFCAlert = true
            
            if nfcStatus.starts(with: "Write Failed:") {
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

#Preview {
    ButcherNFCView()
}
