//
//  MatchesView.swift
//  special1
//
//  Created by somsak on 22/9/2569 BE.
//

import SwiftUI

struct MatchesView: View {
    @State private var matches: [Match] = []
    @State private var errorMessage: String?
    @State private var isLoading = false
    private let client = APIClient()

    var body: some View {
        NavigationStack {
            Group {
                if let errorMessage {
                    ContentUnavailableView(
                        "โหลดข้อมูลไม่สำเร็จ",
                        systemImage: "wifi.exclamationmark",
                        description: Text(errorMessage)
                    )
                } else if isLoading && matches.isEmpty {
                    ProgressView("กำลังโหลด...")
                } else if matches.isEmpty {
                    ContentUnavailableView(
                        "ยังไม่มีข้อมูล",
                        systemImage: "soccerball",
                        description: Text("ลองดึงข้อมูลอีกครั้ง")
                    )
                } else {
                    List {
                        ForEach(matches) { match in
                            MatchRow(match: match)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("นัดการแข่งขัน")
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            matches = try await client.matches()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

private struct MatchRow: View {
    let match: Match

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("มัตเดย์ \(match.matchday)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(match.kickoffAt.map { $0.isEmpty ? "" : $0 } ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                TeamLabel(team: match.homeTeam)
                Spacer()

                if match.isFinished {
                    HStack(spacing: 6) {
                        Text("\(match.homeGoals ?? 0)")
                            .font(.title3.bold())
                            .frame(width: 28)
                        Text("–")
                            .foregroundStyle(.secondary)
                        Text("\(match.awayGoals ?? 0)")
                            .font(.title3.bold())
                            .frame(width: 28)
                    }
                } else {
                    Text("vs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                TeamLabel(team: match.awayTeam)
            }

            if let odds = formattedOdds {
                Text("ราคา: \(odds)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var formattedOdds: String? {
        guard let home = match.oddsHome, let away = match.oddsAway else { return nil }
        let draw = match.oddsDraw.map { String(format: "%.2f", $0) } ?? "-"
        return "เจ้าบ้าน \(String(format: "%.2f", home)) / เสมอ \(draw) / เยือน \(String(format: "%.2f", away))"
    }
}

private struct TeamLabel: View {
    let team: Team

    var body: some View {
        VStack(spacing: 4) {
            Text(team.shortName)
                .font(.headline)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(team.name)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(width: 110)
    }
}

#Preview {
    MatchesView()
}