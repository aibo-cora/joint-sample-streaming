//
//  StreamingView.swift
//  joint-sample-streaming
//
//  Created by Yura on 12/17/22.
//

import SwiftUI
import Combine

struct StreamingView: View {
    @ObservedObject var session: Session
    
    @State private var subscription: AnyCancellable?
    
    var body: some View {
        CameraVideoFeed(frame: session.cameraFeed)
            .onAppear {
                subscription = session.$transportStatus
                    .sink { status in
                        if status == .connected {
                            session.start()
                        }
                    }
                session.connect()
            }
            .onDisappear { session.stop() }
            .ignoresSafeArea()
    }
}

struct CameraVideoFeed: View {
    let frame: CGImage?
    
    var body: some View {
        if let frame = frame {
            GeometryReader { geometry in
                Image(frame, scale: 1.0, orientation: .leftMirrored, label: Text("Camera feed"))
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                    .clipped()
            }
        } else {
            ProgressView()
        }
    }
}

struct StreamingView_Previews: PreviewProvider {
    static var previews: some View {
        StreamingView(session: Session())
    }
}
