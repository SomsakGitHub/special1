//
//  ContentView.swift
//  special1
//
//  Created by somsak on 22/9/2569 BE.
//

import SwiftUI

struct ContentView: View {
    private let client = APIClient()

    @State private var clubName = ""
    @State private var handicap: String?
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "soccerball")
                .font(.system(size: 72))
                .foregroundStyle(.red)

            if isLoading && clubName.isEmpty {
                ProgressView()
                    .controlSize(.small)
                    .padding(.top, 8)
                Text("กำลังโหลด...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(clubName)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)

                Text(formattedHandicap)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText(value: numericHandicap))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await load() }
        .animation(.easeInOut(duration: 0.4), value: clubName)
        .animation(.easeInOut(duration: 0.4), value: handicap)
        .animation(.easeInOut(duration: 0.3), value: isLoading)
    }

    private var numericHandicap: Double {
        Double(handicap ?? "") ?? 0
    }

    private var formattedHandicap: String {
        guard let handicap, let value = Double(handicap) else { return "–" }
        return value == 0 ? "0.0" : String(format: "%.1f", value)
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        guard let info = try? await client.home() else { return }
        clubName = info.club
        handicap = info.handicap
    }
}

#Preview {
    ContentView()
}