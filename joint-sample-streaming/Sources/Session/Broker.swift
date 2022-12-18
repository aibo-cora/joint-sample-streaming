//
//  Broker.swift
//  joint-sample-streaming
//
//  Created by Yura on 12/18/22.
//

import Foundation
import Joint

struct Broker: Server {
    var secure: Bool
    
    var ip: String
    
    var port: UInt32
    
    var username: String
    
    var password: String
}
