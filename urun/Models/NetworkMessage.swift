//
//  NetworkMessage.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-05-14.
//

/// Handles any String message passed on from the server. Usually used for error messages and databased problems
///
/// var message: String
struct NetworkMessage: Decodable {
    let message: String

    enum CodingKeys: String, CodingKey {
        case message
    }

    init() {
        self.message = ""
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.message = try container.decode(String.self, forKey: .message)
    }
}
