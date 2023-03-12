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
        /// Capture session artifact
        jointSession?.$sampleBuffer
            .compactMap( { $0 } )
            .compactMap( { $0.imageBuffer })
            .map( { CGImage.create(from: $0) })
            .receive(on: DispatchQueue.main)
            .assign(to: &$cameraFeed)
        /// Transport monitor
        jointSession?.$transportStatus
            .sink(receiveValue: { status in
                self.transportStatus = status
            })
            .store(in: &subscriptions)
        jointSession?.$transportError
            .sink(receiveValue: { error in
                print("Transport error=\(error)")
            })
            .store(in: &subscriptions)
        /// Traffic
        jointSession?.$outgoing
            .compactMap { $0 }
            .sink(receiveValue: { message in
                print("Message containing video data sent to=\(message.channel), payload=\(message.payload)")
            })
            .store(in: &subscriptions)
        jointSession?.$incoming
            .compactMap { $0 }
            .sink(receiveValue: { message in
                self.process(message: message)
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
    
    func publish(message: Message) {
        if self.transportStatus == .connected {
            print("Heartbeat message sent to=\(message.channel), data=\(message.payload)")
            jointSession?.publish(message: message)
        }
    }
    
    @Published var activeStreamers: [String: Int?] = [:]
    @Published var incomingVideoMessage: Message?
    
    func process(message: Message) {
        print("Message received from=\(message.channel), data=\(message.payload)")
        
        do {
            let metadata = try JSONDecoder().decode(Stream.self, from: message.payload)
            
            self.activeStreamers[metadata.source] = metadata.status == .active ? 0 : nil
        } catch {
            /// If it is not `Stream` metadata of a heartbeat, it must be binary data of an active stream and needs to be displayed.
            self.incomingVideoMessage = message
        }
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
        jointSession?.transport(enabled: enabled) // This can be set when the first watcher joins the stream.
        
        heartbeat()
        
        /// Send a heart beat message to the main channel containing a list of all streamers to announce the status of a stream.
        func heartbeat() {
            let stream = Stream(status: enabled ? .active : .completed, source: self.id)
            
            do {
                let data = try JSONEncoder().encode(stream)
                
                if enabled {
                    self.timer = Timer.publish(every: 5.0, on: .main, in: .default)
                        .autoconnect()
                        .sink { _ in
                            self.publish(message: Message(for: self.streamListChannel, carrying: data)) }
                } else {
                    self.timer?.cancel()
                    self.publish(message: Message(for: self.streamListChannel, carrying: data))
                }
            } catch {
                print("Stream Error - \(Stream.Errors.encoding.rawValue)")
            }
        }
    }
    
    var timer: AnyCancellable?
    
    func disconnect() {
        jointSession?.disconnect()
    }
    
    func open(channel: Session.Channels) {
        let link: String
        
        switch channel {
        case .lobby:
            link = self.streamListChannel
        case .custom(let channel):
            link = channel
        }
        print("Subscribed to channel=\(link)")
        jointSession?.updateLinks(subscribeTo: [link], unsubscribeFrom: [])
    }
    
    func close(channel: Session.Channels) {
        let link: String
        
        switch channel {
        case .lobby:
            link = self.streamListChannel
        case .custom(let channel):
            link = channel
        }
        print("Unsubscribed from channel=\(link)")
        jointSession?.updateLinks(subscribeTo: [], unsubscribeFrom: [link])
    }
}

extension Session {
    enum Channels {
        case lobby, custom(String)
    }
}
