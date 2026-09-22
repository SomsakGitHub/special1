//
//  special1App.swift
//  special1
//
//  Created by somsak on 22/9/2569 BE.
//

import SwiftUI
import SwiftData

@main
struct special1App: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("หน้าแรก", systemImage: "house")
                    }
                MatchesView()
                    .tabItem {
                        Label("นัดการแข่งขัน", systemImage: "soccerball")
                    }
                StandingsView()
                    .tabItem {
                        Label("ตารางคะแนน", systemImage: "list.number")
                    }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
