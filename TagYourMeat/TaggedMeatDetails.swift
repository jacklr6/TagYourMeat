//
//  TaggedMeatDetails.swift
//  TagYourMeat
//
//  Created by Jack Rogers on 6/18/25.
//

import SwiftUI
import Combine
import MapKit

struct TaggedMeatDetails: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State var tag: MeatTag
    @State private var showPricePicker: Bool = false
    @AppStorage("alertSuccessfullyUpdated") private var alertSuccessfullyUpdated: Bool = false
    @AppStorage("alertSuccessfullyUpdatedSF") private var alertSuccessfullyUpdatedSF: Bool = false
    
    @State private var cameraPosition = MapCameraPosition.region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18)))
    
    var coordinate: CLLocationCoordinate2D? {
        if tag.packagedLocation.hasPrefix("Lat: ") {
            let coords = parseCoordinates(from: tag.packagedLocation)
            return CLLocationCoordinate2D(latitude: coords.lat, longitude: coords.lon)
        } else {
            return nil
        }
    }
    
    var body: some View {
        ZStack {
            Form {
                Section(header: Text("Basic Info")) {
                    TextField("Item Name", text: $tag.itemName)
                    TextField("Location", text: $tag.packagedLocation)
                    if let coordinate = coordinate {
                        Map(position: $cameraPosition) { Marker("Packaged Location", coordinate: coordinate) }
                        .frame(height: 150)
                        .cornerRadius(10)
                        .onAppear {
                            cameraPosition = .region(
                                MKCoordinateRegion(center: coordinate,
                                                   span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
                            )
                        }
                        .disabled(true)
                    }
                    DatePicker("Packaged Date", selection: .constant(tag.datePackaged), displayedComponents: .date)
                        .disabled(true)
                }
                
                Section(header: Text("Details")) {
                    DatePicker("Expire Date", selection: Binding($tag.expireDate, replacingNilWith: tag.datePackaged + 182.5*24*60*60), displayedComponents: .date)
                    HStack {
                        Text("\(tag.price ?? 0.0, format: .currency(code: "USD"))")
                            .contentTransition(.numericText())
                        Spacer()
                        Text("/\(tag.unit ?? "unit")")
                            .contentTransition(.numericText())
                    }
                    .onTapGesture { showPricePicker = true }
                    HStack {
                        HStack {
                            Text("Quantity:")
                            Text("\(tag.quantity ?? 1)")
                                .contentTransition(.numericText())
                        }
                        Stepper("", value: Binding($tag.quantity, replacingNilWith: 1), in: 1...500)
                    }
                    .animation(.default, value: tag.quantity)
                    TextField("Notes", text: Binding($tag.notes, replacingNilWith: ""), axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }
                .animation(.default, value: tag.price)
                .animation(.default, value: tag.unit)
                
                Button(action: {
                    auth.updateMeatTag(tag) { success in
                        if success {
                            dismiss()
                            withAnimation {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    alertSuccessfullyUpdated = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                    alertSuccessfullyUpdatedSF = true
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                    alertSuccessfullyUpdated = false
                                    alertSuccessfullyUpdatedSF = false
                                }
                            }
                        }
                    }
                }) {
                    HStack {
                        Text("Save Changes")
                        Spacer()
                        if auth.isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark.circle")
                        }
                    }
                    .fontWeight(.semibold)
                    .animation(.default, value: auth.isLoading)
                }
            }
            .navigationTitle("Edit Meat Tag")
            .sheet(isPresented: $showPricePicker) {
                PricePickerView(price: Binding($tag.price, replacingNilWith: 0.0), unit: Binding($tag.unit, replacingNilWith: "unit"))
                    .presentationDetents([.height(500), .large])
            }
        }
    }
    
    func parseCoordinates(from string: String) -> (lat: Double, lon: Double) {
        var lat: Double = 0.0
        var lon: Double = 0.0
        
        let parts = string.components(separatedBy: ",")
        
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("Lat:") {
                let valueString = trimmed.replacingOccurrences(of: "Lat:", with: "")
                lat = Double(valueString.trimmingCharacters(in: .whitespaces)) ?? 0.0
            } else if trimmed.hasPrefix("Lon:") {
                let valueString = trimmed.replacingOccurrences(of: "Lon:", with: "")
                lon = Double(valueString.trimmingCharacters(in: .whitespaces)) ?? 0.0
            }
        }
        print("Lat: \(lat), Lon: \(lon)")
        
        return (lat, lon)
    }
}

struct PricePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var price: Double
    @Binding var unit: String
    @State private var priceString: String = ""
    @State private var unitPickerSelection: String = "unit"
    @State private var keyboardIsShowing: Bool = false
    
    var unitOptions: [String] = ["unit", "lb", "oz", "kg"]
    
    var body: some View {
        VStack {
            HStack {
                Text("$\(priceString.isEmpty ? "0.00" : priceString)")
                    .font(.system(size: 75, weight: .bold, design: .rounded))
                    .fixedSize()
                    .frame(width: UIScreen.main.bounds.width - 130, height: 100)
                    .mask (
                        HStack(spacing: 0) {
                            LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .leading, endPoint: .trailing)
                                .frame(width: 45)
                            
                            Rectangle()
                                .fill(Color.black)
                            
                            LinearGradient(gradient: Gradient(colors: [.black, .clear]), startPoint: .leading, endPoint: .trailing)
                                .frame(width: 45)
                        }
                    )
                
                Picker("", selection: $unitPickerSelection) {
                    ForEach(unitOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 100, height: 150)
                .onChange(of: unitPickerSelection) { _, newValue in
                    withAnimation {
                        unit = newValue
                    }
                }
                .onChange(of: priceString) { _, newValue in
                    if let newPrice = Double(newValue) {
                        price = newPrice
                    } else if newValue.isEmpty {
                        price = 0.00
                    }
                }
                .onAppear {
                    unitPickerSelection = unit
                    if price.truncatingRemainder(dividingBy: 1) == 0 {
                        priceString = String(format: "%.0f", price)
                    } else {
                        priceString = String(price)
                    }
                    if price == 0.00 && priceString == "0" {
                        priceString = ""
                    }
                }
            }
            
            NumpadView(value: $priceString) { buttonText in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            .padding(.horizontal)
            .padding(.top, -30)
            
            Button(action: {
                dismiss()
            }) {
                Text("Confirm Price")
                    .frame(maxWidth: .infinity, maxHeight: 60)
            }
            .buttonStyle(.borderedProminent)
            .cornerRadius(15)
            .padding(.horizontal, 32)
            .fontWeight(.medium)
        }
    }
}

struct NumpadView: View {
    @Binding var value: String
    
    var onButtonTap: ((String) -> Void)?
    
    let buttons: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"]
    ]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { buttonText in
                        Button(action: {
                            handleButtonTap(buttonText)
                            onButtonTap?(buttonText)
                        }) {
                            Text(buttonText)
                                .font(.largeTitle)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity, minHeight: 60)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(15)
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private func handleButtonTap(_ buttonText: String) {
        switch buttonText {
        case "⌫":
            if !value.isEmpty {
                value.removeLast()
            }
        case ".":
            if !value.contains(".") {
                if value.isEmpty {
                    value = "0."
                } else {
                    value += "."
                }
            }
        case "0":
            if value == "0" && !value.contains(".") {
            } else {
                value += buttonText
            }
        default:
            if value == "0" && !value.contains(".") {
                value = buttonText
            } else {
                value += buttonText
            }
        }
    }
}

extension Binding {
    init(_ source: Binding<Value?>, replacingNilWith defaultValue: Value) {
        self.init(
            get: { source.wrappedValue ?? defaultValue },
            set: { newValue in
                source.wrappedValue = newValue
            }
        )
    }
}

#Preview {
    TaggedMeatDetails(tag: MeatTag(id: "sample-tag-id", itemName: "Ribeye Steak", packagedLocation: "Lat: 37.3347302, Lon: -122.0089189", datePackaged: Date()))
        .environmentObject(AuthViewModel())
}
