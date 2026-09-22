//
//  ContentView.swift
//  special1
//
//  Created by somsak on 22/9/2569 BE.
//

import SwiftUI

struct ContentView: View {
    private let client = APIClient()

    @State private var clubName = "Manchester Unitad"
    @State private var handicap = "-0.0"

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "soccerball")
                .font(.system(size: 72))
                .foregroundStyle(.red)

            Text(clubName)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text(handicap)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await load() }
    }

    private func load() async {
        guard let info = try? await client.home() else { return }
        clubName = info.club
        if let handicap = info.handicap {
            self.handicap = handicap
        }
    }
}

#Preview {
    ContentView()
}
