//
//  ContentView.swift
//  special1
//
//  Created by somsak on 22/9/2569 BE.
//

import SwiftUI

struct ContentView: View {
    private let clubName = "Manchester United"

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "soccerball")
                    .font(.system(size: 72))
                    .foregroundStyle(.red)

                Text(clubName)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text("-0.5")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    ContentView()
}
