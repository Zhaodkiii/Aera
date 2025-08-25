//
//  AeraApp.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/18.
//

import SwiftUI

@main
struct AeraApp: App {
    init() {
         FirstRunGuard.cleanKeychainIfFreshInstall()
     }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
