//
//  TagYourMeetApp.swift
//  TagYourMeet
//
//  Created by Jack Rogers on 6/5/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct TagYourMeet: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            NavigationView {
                TagYourMeatMain()
            }
        }
    }
}


#Preview {
    TagYourMeatMain()
}
