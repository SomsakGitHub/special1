//
//  StandingsView.swift
//  special1
//
//  Created by somsak on 22/9/2569 BE.
//

import SwiftUI

struct StandingsView: View {
    @State private var standings: [Standings] = []
    @State private var errorMessage: String?
    @State private var isLoading = false
    private let client = APIClient()

    private let columns = [
        GridItem(.fixed(28), alignment: .trailing),
        GridItem(.flexible(), alignment: .leading),
        GridItem(.fixed(30), alignment: .trailing),
        GridItem(.fixed(30), alignment: .trailing),
        GridItem(.fixed(30), alignment: .trailing),
        GridItem(.fixed(30), alignment: .trailing),
        GridItem(.fixed(30), alignment: .trailing),
    ]

    var body: some View {
        NavigationStack {
            Group {
                if let errorMessage {
                    ContentUnavailableView(
                        "โหลดข้อมูลไม่สำเร็จ",
                        systemImage: "wifi.exclamationmark",
                        description: Text(errorMessage)
                    )
                } else if isLoading && standings.isEmpty {
                    ProgressView("กำลังโหลด...")
                } else if standings.isEmpty {
                    ContentUnavailableView(
                        "ยังไม่มีตารางคะแนน",
                        systemImage: "list.number",
                        description: Text("ลองดึงข้อมูลอีกครั้ง")
                    )
                } else {
                    ScrollView(.horizontal) {
                        VStack(alignment: .leading, spacing: 8) {
                            header
                            ForEach(Array(standings.enumerated()), id: \.element.id) { index, team in
                                row(index: index + 1, team: team)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("ตารางคะแนน")
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private var header: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            Text("#")
            Text("ทีม")
            Text("แข่ง")
            Text("ชนะ")
            Text("เสมอ")
            Text("แพ้")
            Text("แต้ม")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
    }

    private func row(index: Int, team: Standings) -> some View {
        LazyVGrid(columns: columns, spacing: 12) {
            Text("\(index)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Text(team.shortName)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
            Text("\(team.played)")
                .font(.subheadline.monospacedDigit())
            Text("\(team.won)")
                .font(.subheadline.monospacedDigit())
            Text("\(team.drawn)")
                .font(.subheadline.monospacedDigit())
            Text("\(team.lost)")
                .font(.subheadline.monospacedDigit())
            Text("\(team.points)")
                .font(.subheadline.monospacedDigit().weight(.bold))
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            standings = try await client.standings()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    StandingsView()
}