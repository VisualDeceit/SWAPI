//
//  People.swift
//  SWAPI
//
//  Created by Александр Фомин on 10.04.2022.
//

import Foundation

struct PeoplePage: Decodable {
    var next: URL?
    var people: [People]
    
    enum PeoplePageCodingKeys: String, CodingKey {
        case next
        case people = "results"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PeoplePageCodingKeys.self)
        if let stringURL = try? container.decode(String.self, forKey: .next) {
            self.next = URL(string: stringURL)
        }
        self.people = try container.decode([People].self, forKey: .people)
    }
}

struct People: Decodable {
    let name: String
    let spacesUrl: [String]
    let homeWorldUrl: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case spacesUrl = "species"
        case homeWorldUrl = "homeworld"
    }
}
