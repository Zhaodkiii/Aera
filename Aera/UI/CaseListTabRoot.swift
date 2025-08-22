//
//  CaseListTabRoot.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/19.
//
import SwiftUI

struct CaseListTabRoot: View {
    @State private var isPush = false

    var body: some View {
        
        NavigationStack {
            TabView {
                DjangoEndpointsDemoView()
                    .tabItem {
                        Label("问诊", systemImage: "stethoscope")
                    }
                CaseListView()
                    .tabItem {
                        Label("病例", systemImage: "rectangle.stack.person.crop")
                    }
                //                        .injectMetrics() // <<< 只需这一个
                
            }
            .navigationDestination(isPresented: $isPush) {
//                       AddCaseEntryView()
                DosingPlannerView()
                   }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        // 用户头像或个人中心
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.title3)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // 新增病例
                        isPush = true

                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                    }
                }
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
