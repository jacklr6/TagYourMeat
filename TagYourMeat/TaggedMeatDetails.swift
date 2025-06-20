//
//  TaggedMeatDetails.swift
//  TagYourMeat
//
//  Created by Jack Rogers on 6/18/25.
//

import SwiftUI

struct TaggedMeatDetails: View {
    let tag: MeatTag
    
    var body: some View {
        Text("TaggedMeatDetails")
        Text(tag.id)
        Text(tag.itemName)
        Text(tag.packagedLocation)
        Text("\(tag.datePackaged)")
    }
}

#Preview {
    TaggedMeatDetails(tag: MeatTag(id: "sample-tag-id", itemName: "Ribeye Steak", packagedLocation: "Freezer A", datePackaged: Date()))
}
