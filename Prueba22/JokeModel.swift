//
//  JokeModel.swift
//  Prueba22
//
//  Created by Victor Alejandro Perez Valdez on 04/11/26.
//

import Foundation

struct JokeModel: Decodable {
    let iconURL: String
    let id: String
    let url: String
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case iconURL = "icon_url"
        case id
        case url
        case description = "value"
    }
}

extension Array where Element == JokeModel {
    subscript(id: String) -> JokeModel? {
        return self.first { $0.id == id }
    }
}
