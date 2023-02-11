//
//  WatchingView.swift
//  joint-sample-streaming
//
//  Created by Yura on 12/17/22.
//

import SwiftUI
import Combine

struct WatchingView: View {
    @ObservedObject var session: Session
    
    @State var connection: AnyCancellable?
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                List {
                    ForEach(Array(session.activeStreamers.keys), id: \.self) { streamer in
                        NavigationLink(streamer, value: streamer)
                    }
                }
            }
            .onAppear() {
                session.connect()
                
                self.connection = session.$transportStatus
                    .sink(receiveValue: { status in
                        if status == .connected {
                            session.open(channel: .lobby)
                        }
                    })
            }
        } else {
            List {
                ForEach(Array(session.activeStreamers.keys), id: \.self) { streamer in
                    NavigationLink {
                        SwiftUI.EmptyView()
                    } label: {
                        Text(streamer)
                    }

                }
            }
            .onAppear() {
                session.connect()
                
                self.connection = session.$transportStatus
                    .sink(receiveValue: { status in
                        if status == .connected {
                            session.open(channel: .lobby)
                        }
                    })
            }
        }
    }
}

struct WatchingView_Previews: PreviewProvider {
    static var previews: some View {
        WatchingView(session: Session())
    }
}
