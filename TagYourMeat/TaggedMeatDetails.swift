//
//  TaggedMeatDetails.swift
//  TagYourMeat
//
//  Created by Jack Rogers on 6/18/25.
//

import SwiftUI

struct TaggedMeatDetails: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State var tag: MeatTag
    @State private var showPricePicker: Bool = false
    
    var body: some View {
        ZStack {
            Form {
                Section(header: Text("Basic Info")) {
                    TextField("Item Name", text: $tag.itemName)
                    TextField("Location", text: $tag.packagedLocation)
                    DatePicker("Packaged Date", selection: .constant(tag.datePackaged), displayedComponents: .date)
                        .disabled(true)
                }
                
                Section(header: Text("Details")) {
                    DatePicker("Expire Date", selection: Binding($tag.expireDate, replacingNilWith: tag.datePackaged + 182.5*24*60*60), displayedComponents: .date)
                    Text("\(tag.price ?? 0.0, format: .currency(code: "USD"))")
                        .contentTransition(.numericText())
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
                
                Button("Save Changes") {
                    auth.updateMeatTag(tag) { success in
                        if success { dismiss() }
                    }
                }
            }
            .navigationTitle("Edit Meat Tag")
            .sheet(isPresented: $showPricePicker) {
                PricePickerView(price: Binding($tag.price, replacingNilWith: 0.0))
                    .presentationDetents([.medium, .large])
            }
            
            if auth.isLoading {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .ignoresSafeArea(edges: .all)
                    ProgressView()
                }
            }
        }
    }
}

struct PricePickerView: View {
    @Binding var price: Double
    @State private var unitPickerSelection: String = "unit"
    
    var unitOptions: [String] = ["unit", "lb", "oz", "kg"]
    
    var body: some View {
        VStack {
            HStack {
                TextField("Price", value: Binding($price), format: .currency(code: "USD"))
                    .font(.system(size: 75, weight: .bold, design: .rounded))
                    .padding(.top, 50)
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .mask(
                        HStack(spacing: 0) {
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .black]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 50)

                            Rectangle().fill(Color.black)

                            LinearGradient(
                                gradient: Gradient(colors: [.black, .clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 50)
                        }
                    )
                Text("/\(unitPickerSelection)")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .offset(y: 40)
                    .padding(.horizontal, 15)
            }
            Divider()
                .frame(width: UIScreen.main.bounds.width * 0.85)
            HStack {
                Spacer()
                Picker("", selection: $unitPickerSelection) {
                    ForEach(unitOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 120, height: 150)
                .padding(.horizontal, 15)
            }
            Spacer()
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
    TaggedMeatDetails(tag: MeatTag(id: "sample-tag-id", itemName: "Ribeye Steak", packagedLocation: "Freezer A", datePackaged: Date()))
        .environmentObject(AuthViewModel())
}
