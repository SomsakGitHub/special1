//
//  Models.swift
//  special1
//
//  Created by somsak on 22/9/2569 BE.
//

import Foundation

struct Team: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let shortName: String
    let city: String?
    let primaryColor: String?
    let logoUrl: String?
}

struct Match: Codable, Identifiable, Hashable {
    let id: Int
    let matchday: Int
    let kickoffAt: String?
    let status: String
    let homeGoals: Int?
    let awayGoals: Int?
    let oddsHome: Double?
    let oddsDraw: Double?
    let oddsAway: Double?
    let homeTeam: Team
    let awayTeam: Team

    var isFinished: Bool { status == "finished" }
}

struct Standings: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let shortName: String
    let played: Int
    let won: Int
    let drawn: Int
    let lost: Int
    let goalsFor: Int
    let goalsAgainst: Int

    var points: Int { won * 3 + drawn }
    var goalDifference: Int { goalsFor - goalsAgainst }
}