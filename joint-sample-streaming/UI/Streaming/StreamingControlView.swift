//
//  StreamingControlView.swift
//  joint-sample-streaming
//
//  Created by Yura on 12/24/22.
//

import SwiftUI

struct StreamingControlView: View {
    @State private var blinking = false
    
    @Binding var streaming: Bool
    
    var body: some View {
        Circle()
            .strokeBorder(.black, lineWidth: 2)
            .background(Circle().fill(.red))
            .frame(width: 75, height: 75)
            .shadow(radius: 3)
            .opacity(blinking ? 0 : 1)
            .onChange(of: streaming, perform: { _ in
                print("streaming=\(streaming)")
                
                var transaction = Transaction()
                transaction.disablesAnimations = streaming ? false : true
                
                if streaming {
                    withTransaction(transaction) {
                        withAnimation(Animation.linear(duration: 0.5).repeatForever()) {
                            blinking.toggle()
                        }
                    }
                } else {
                    blinking = false
                }
            })
    }
}

struct StreamingControlView_Previews: PreviewProvider {
    static var previews: some View {
        StreamingControlView(streaming: .constant(true))
    }
}
