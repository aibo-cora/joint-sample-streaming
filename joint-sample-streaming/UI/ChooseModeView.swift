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
    
    @ViewBuilder var body: some View {
        switch session.configuration.status {
        case .ready:
            Text("Ready")
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
        case .failed:
            Text("Configuration Failed")
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
