//
//  ContentView.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/18.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        LoginView()

    }
}

#Preview {
    ContentView()
}


struct EntryView: View {
    @State private var showRegister = false

    var body: some View {
        VStack(spacing: 16) {
            // 你的登录 UI …
            Button("去注册") { showRegister = true }
        }
        .sheet(isPresented: $showRegister) {
            CaseaListView()
//            RegisterView()
        }
    }
}
