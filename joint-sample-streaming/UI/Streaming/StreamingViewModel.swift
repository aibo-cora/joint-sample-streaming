//
//  StreamingViewModel.swift
//  joint-sample-streaming
//
//  Created by Yura on 12/17/22.
//

import Foundation
import Joint
import Combine
import CoreGraphics
import AVFoundation
import UIKit

class StreamingViewModel: ObservableObject {
    @Published var cameraFeed: CGImage?
    @Published var transportStatus = TransportStatus.disconnected
    
    var jointSession: JointSession?
    private var subscriptions = [AnyCancellable]()
    
    let video = AVCaptureVideoDataOutput()
    let audio = PassthroughSubject<AVAudioPCMBuffer, Never>()
    
    init() {
        let id = UIDevice.current.identifierForVendor?.uuidString ?? "NoID"
        
        let server = Broker(secure: true,
                                ip: "ec4735464b1046269ee2cea58d53b355.s1.eu.hivemq.cloud",
                              port: 8883,
                          username: "aibo-cora",
                          password: "sq!2L!EcFz9b!JA")
        
        
        
        jointSession = JointSession(
            datasource: id,
                 using: .MQTT(server),
                 video: video,
                 audio: audio)
        
        jointSession?.$sampleBuffer
            .compactMap( { $0 } )
            .compactMap( { $0.imageBuffer })
            .map( { CGImage.create(from: $0) })
            .handleEvents(receiveOutput: { image in
                print("Received buffer")
            })
            .assign(to: &$cameraFeed)
        
        jointSession?.$transportStatus
            .assign(to: &$transportStatus)
        
        jointSession?.$transportError
            .sink(receiveValue: { error in
                print("Transport error=\(error)")
            })
            .store(in: &subscriptions)
    }
    
    func connect() {
        jointSession?.connect()
    }
    
    func start() throws {
        try jointSession?.start()
    }
    
    func stop() {
        jointSession?.stop()
    }
}

struct Broker: Server {
    var secure: Bool
    
    var ip: String
    
    var port: UInt32
    
    var username: String
    
    var password: String
}
