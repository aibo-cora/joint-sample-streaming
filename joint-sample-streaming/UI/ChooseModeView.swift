//
//  ChooseModeView.swift
//  joint-sample-streaming
//
//  Created by Yura on 12/13/22.
//

import SwiftUI
import Combine

struct ChooseModeView: View {
    @StateObject private var session = Session()
    
    @State private var streaming = false
    @State private var watching = false
    
    @ViewBuilder var body: some View {
        switch session.status {
        case .ready:
            VStack {
                VStack {
                    Text("Show yourself to the world")
                    Button {
                        self.streaming.toggle()
                    } label: {
                        Text("Stream")
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                
                Divider()
                    .padding(50)
                
                VStack {
                    Text("Watch someone do magic")
                    Button {
                        self.watching.toggle()
                    } label: {
                        Text("Watch")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .sheet(isPresented: $streaming) { StreamingView(session: session) }
            .sheet(isPresented: $watching) { WatchingView() }
        case .unknown:
            ProgressView()
        case .restricted:
            VStack {
                Text("Allow Camera & Microphone permissions in Settings.")
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            }
            .padding()
        case .configuring:
            ProgressView {
                Text("Configuring")
            }
        case .failed(let message):
            Text(message)
        }
    }
}

struct ChooseModeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChooseModeView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro Max"))
                .previewDisplayName("iPhone 14 Pro Max")
            ChooseModeView()
                .previewDevice(PreviewDevice(rawValue: "iPad mini (6th generation)"))
                .previewDisplayName("iPad mini (6th generation)")
        }
    }
}
