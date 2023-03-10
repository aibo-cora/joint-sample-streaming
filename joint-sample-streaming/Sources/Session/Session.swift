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
                    self.jointSession?.updateLinks(subscribeTo: [self.id], unsubscribeFrom: [])
                }
                self.transportStatus = status
            })
            .store(in: &subscriptions)
        
        jointSession?.$transportError
            .sink(receiveValue: { error in
                print("Transport error=\(error)")
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
    
    func transport(enabled: Bool) {
        jointSession?.transport(enabled: enabled)
    }
    
    func disconnect() {
        jointSession?.disconnect()
    }
}

extension Session {
    class Configuration: ObservableObject {
        @Published var status: Session.Status = .unknown
        
        private let session = AVCaptureSession()
        private let sessionQueue = DispatchQueue(label: "capture.session.serial")
        private let permissions: Permission
        
        private var subscriptions = [AnyCancellable]()
        
        let video = AVCaptureVideoDataOutput()
        let audio = PassthroughSubject<AVAudioPCMBuffer, Never>()
        
        init() {
            self.permissions = Permission()
            self.permissions.$status
                .sink { status in
                    switch status {
                    case .unknown:
                        self.update(status: .unknown)
                    case .restricted:
                        self.update(status: .restricted("Session configuration status=\(status), cannot continue without camera and microphone permissions."))
                    case .allowed:
                        self.configure()
                    }
                }
                .store(in: &subscriptions)
        }
        
        private func update(status: Status) {
            self.status = status
            print("Session configuration status=\(status)")
        }
        
        private func configure() {
            update(status: .configuring)
            
            session.sessionPreset = .high
            session.beginConfiguration()
            
            do {
                var defaultVideoDevice: AVCaptureDevice?
                
                // Choose the back dual camera, if available, otherwise default to a wide angle camera.
                
                if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .front) {
                    defaultVideoDevice = dualCameraDevice
                } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                    // If a rear dual camera is not available, default to the front wide angle camera.
                    defaultVideoDevice = backCameraDevice
                } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                    // If the rear wide angle camera isn't available, default to the front wide angle camera.
                    defaultVideoDevice = frontCameraDevice
                }
                guard let videoDevice = defaultVideoDevice else {
                    self.update(status: .failed("Default video device is unavailable."))
                    session.commitConfiguration()
                    
                    return
                }
                let input = try AVCaptureDeviceInput(device: videoDevice)
                
                if session.canAddInput(input) {
                    session.addInput(input)
                } else {
                    self.update(status: .failed("Couldn't add video device input to the session."))
                    session.commitConfiguration()
                    
                    return
                }
                if session.canAddOutput(video) {
                    session.addOutput(video)
                } else {
                    self.update(status: .failed("Couldn't add video device output to the session."))
                    session.commitConfiguration()
                    
                    return
                }
            } catch {
                self.update(status: .failed("Couldn't create device input for the session."))
                
                return
            }
            session.commitConfiguration()
            
            self.update(status: .ready)
        }
        
        func start() {
            print("Starting capture session...")
            sessionQueue.async {
                self.session.startRunning()
            }
        }
        
        func stop() {
            print("Stopping capture session...")
            sessionQueue.async {
                if self.session.isRunning {
                    self.session.stopRunning()
                }
            }
        }
    }
}

extension Session.Configuration {
    /// Identify AV permissions user selcted.
    class Permission: ObservableObject {
        enum Status {
            case unknown, restricted, allowed
        }
        @Published var status: Status = .unknown
        
        init() { validate() }
        
        private func validate() {
            Task {
                let audioResult = await avAuthorization(type: .audio)
                let videoResult = await avAuthorization(type: .video)
                
                if audioResult && videoResult {
                    Task { await update(status: .allowed) }
                } else {
                    Task { await update(status: .restricted) }
                }
            }
        }
        
        private func avAuthorization(type: AVMediaType) async -> Bool {
            switch AVCaptureDevice.authorizationStatus(for: type) {
            case .denied, .restricted:
                return false
            case .authorized:
                return true
            case .notDetermined:
                return await AVCaptureDevice.requestAccess(for: type)
            @unknown default:
                return false
            }
        }
        
        @MainActor
        private func update(status: Status) {
            self.status = status
        }
    }
}
