//
//  CaseaListView.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/22.
//

import SwiftUI

struct CaseaListView: View {
    @StateObject var vm = CaseListVM()

    var body: some View {
        NavigationView {
            List {
                ForEach(vm.items) { c in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(c.patient_name).font(.headline)
                            if c.is_favorite { Image(systemName: "star.fill") }
                        }
                        Text("\(c.gender) • \(c.age)岁 • \(c.relationship)")
                        Text("诊断：\(c.diagnosis)")
                        Text("就诊：\(c.visit_date)  严重度：\(c.severity)")
                            .foregroundColor(.secondary)
                    }
                }

                Button{
                    Task{
                        await demoFlow()

                    }
                }label: {
                    Text("增加数据")
                }
                if vm.hasMore {
                    HStack {
                        Spacer()
                        ProgressView().onAppear { Task { await vm.loadMore() } }
                        Spacer()
                    }
                }
            }
            .navigationTitle("病例列表")
            
            .toolbar {
                Menu {
                    Button("日期降序（默认）") { vm.ordering = "-visit_date"; Task { await vm.resetAndLoad() } }
                    Button("日期升序")       { vm.ordering = "visit_date";  Task { await vm.resetAndLoad() } }
                    Button("年龄升序")       { vm.ordering = "age";         Task { await vm.resetAndLoad() } }
                    Button("年龄降序")       { vm.ordering = "-age";        Task { await vm.resetAndLoad() } }
                } label: {
                    Label("排序", systemImage: "arrow.up.arrow.down")
                }
            }
            .searchable(text: $vm.searchText, prompt: "搜索姓名/诊断/主诉/备注")
            .onSubmit(of: .search) { Task { await vm.resetAndLoad() } }
//            .task { // 首次加载（前提：已登录）
//                if Keychain.loadToken() == nil {
//                    // 简单示例：自动登录（生产环境请走登录页）
//                    try? await APIClient.shared.login(username: "zhaodk", password: "Zhao1029")
//                }
//
//                await vm.resetAndLoad()
//                await demoFlow()
//
//            }
        }
    }
    @MainActor
    func demoFlow() async {
        do {
            // 1) 登录获取 Token
//            try await APIClient.shared.login(username: "zhaodk", password: "Zhao1029")

            // 2) 创建病例
            let created = try await APIClient.shared.createCase(
                CaseDTO(
                    id: nil,
                    patient_name: "李明华",
                    age: 58,
                    gender: "女",
                    relationship: "妈妈",
                    chief_complaint: "头晕伴恶心呕吐3天",
                    diagnosis: "高血压、颈椎病",
                    symptoms: ["头晕","恶心","呕吐","颈部僵硬","视力模糊"],
                    severity: "medium",
                    visit_date: "2024-08-10",
                    status: "治疗中",
                    medications: ["苯磺酸氨氯地平片","颈复康颗粒"],
                    notes: "血压控制良好，建议继续用药",
                    is_favorite: true,
                    created_at: nil, updated_at: nil
                )
            )
            print("Created ID:", created.id ?? -1)

            // 3) 列表（搜索 + 排序 + 分页）
            let page1 = try await APIClient.shared.fetchCases(
                search: "李明华",
                ordering: "-age",
                status: "治疗中",
                page: 1,
                pageSize: 5
            )
            print("Total:", page1.count, "First page:", page1.results.count)

            // 4) 更新部分字段（PATCH）
            let updated = try await APIClient.shared.updateCase(id: created.id!, patch: ["notes": "复诊两周后复查"])
            print("Updated notes:", updated.notes ?? "")

            // 5) 删除
//            try await APIClient.shared.deleteCase(id: created.id!)
            print("Deleted.")

        } catch {
            print("API error:", error.localizedDescription)
        }
    }
}

#Preview {
    CaseaListView()
}
