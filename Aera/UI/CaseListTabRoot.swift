//
//  CaseListTabRoot.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/19.
//
import SwiftUI

struct CaseListTabRoot: View {
    var body: some View {
        TabView {
            Text("问诊内容占位")
                .tabItem {
                    Label("问诊", systemImage: "stethoscope")
                }
            CaseListView()
                .tabItem {
                    Label("病例", systemImage: "rectangle.stack.person.crop")
                }
        }
    }
}

struct CaseListView_Previews: PreviewProvider {
    static var previews: some View {
        CaseListTabRoot()
            .environment(\.locale, .init(identifier: "zh-Hans"))
    }
}
