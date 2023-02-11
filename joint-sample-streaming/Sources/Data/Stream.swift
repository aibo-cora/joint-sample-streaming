//
//  Stream.swift
//  joint-sample-streaming
//
//  Created by Yura on 1/29/23.
//

import Foundation

struct Stream: Codable {
    let status: Status
    let source: String
    
    enum Status: Codable {
        case active, completed, terminated
    }
    
    enum Errors: String, Error {
        case encoding
    }
}
