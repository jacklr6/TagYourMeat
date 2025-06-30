//
//  TagYourMeetApp.swift
//  TagYourMeet
//
//  Created by Jack Rogers on 6/5/25.
//

import SwiftUI
import UIKit
import Firebase
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct TagYourMeet: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var auth = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                TagYourMeatMain()
                    .environmentObject(auth)
            }
        }
    }
}


#Preview {
    TagYourMeatMain()
}
