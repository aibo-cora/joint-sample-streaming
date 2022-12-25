//
//  Session.swift
//  JointSample
//
//  Created by Yura on 12/13/22.
//

import Foundation
import AVFoundation
import Combine
import Joint
import UIKit

class Session: ObservableObject {
    @Published var status: Status = .unknown
    
    @Published var cameraFeed: CGImage?
    @Published var transportStatus = TransportStatus.disconnected
    
    enum Status {
        case unknown, restricted(String), configuring, failed(String), ready
    }
    
    let configuration = Configuration()
    
    private var jointSession: JointSession?
    private var subscriptions = [AnyCancellable]()
    
    init() {
        configuration.$status
            .delay(for: 0.5, scheduler: DispatchQueue.main)
            .assign(to: &$status)
    }
    
    let id = UIDevice.current.identifierForVendor?.uuidString ?? "NoID"
    let streamListChannel = "joint/sample/stream/list"
    
    func configure() {
        jointSession?.$sampleBuffer
            .compactMap( { $0 } )
            .compactMap( { $0.imageBuffer })
            .map( { CGImage.create(from: $0) })
            .receive(on: DispatchQueue.main)
            .assign(to: &$cameraFeed)
        jointSession?.$transportStatus
            .sink(receiveValue: { status in
                if status == .connected {
                    /// Subscribe to the general channel for live streams.
                    self.jointSession?.updateLinks(subscribeTo: [self.streamListChannel], unsubscribeFrom: [])
                }
                self.transportStatus = status
            })
            .store(in: &subscriptions)
        jointSession?.$transportError
            .sink(receiveValue: { error in
                print("Transport error=\(error)")
            })
            .store(in: &subscriptions)
        jointSession?.$outgoing
            .sink(receiveValue: { message in
                print("Message sent.")
            })
            .store(in: &subscriptions)
    }
    
    func connect() {
        let server = Broker(secure: true,
                                ip: "ec4735464b1046269ee2cea58d53b355.s1.eu.hivemq.cloud",
                              port: 8883,
                          username: "aibo-cora",
                          password: "sq!2L!EcFz9b!JA")
        
        jointSession = JointSession(
            datasource: id,
                 using: .MQTT(server),
                 video: configuration.video,
                 audio: configuration.audio)
        configure()
        
        jointSession?.connect()
    }
    
    func start() {
        configuration.start()
        
        jointSession?.startCapture()
    }
    
    func stop() {
        configuration.stop()
        
        jointSession?.stopCapture()
    }
    
    /// Subscribe to the channel representing the client.
    /// - Parameter enabled: Toggle switch.
    func transport(enabled: Bool) {
        jointSession?.transport(enabled: enabled)
    }
    
    func disconnect() {
        jointSession?.disconnect()
    }
}
