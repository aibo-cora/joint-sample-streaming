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
                List(Array(session.activeStreamers.keys), id: \.self) { room in
                    NavigationLink(room, value: room)
                }
                .navigationDestination(for: String.self) { room in
                    WatchStream(session: self.session, room: room)
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

struct WatchStream: View {
    @ObservedObject var session: Session
    
    let room: String
    
    var body: some View {
        Text(self.room)
            .onAppear() {
                self.session.open(channel: .custom(self.room))
            }
            .onDisappear() {
                self.session.close(channel: .custom(self.room))
            }
    }
}

struct WatchingView_Previews: PreviewProvider {
    static var previews: some View {
        WatchingView(session: Session())
    }
}
