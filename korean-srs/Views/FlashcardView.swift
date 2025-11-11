//
//  FlashcardView.swift
//  korean-srs-app
//
//  Created by Auto on 1/1/25.
//

import SwiftUI

struct FlashcardView: View {
    let frontText: String
    let backText: String
    var onFlip: (() -> Void)? = nil
    
    @State private var flipped = false
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            Text(flipped ? backText : frontText)
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .padding()
                .frame(width: 300, height: 400)
                .opacity(flipped ? (rotation > 90 ? 1 : 0) : (rotation < 90 ? 1 : 0))
                .rotation3DEffect(
                    .degrees(flipped ? -rotation : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .rotation3DEffect(
            .degrees(rotation),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .onTapGesture {
            if !flipped {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    flipped = true
                    rotation = 180
                    onFlip?()
                }
            }
        }
    }
}

#Preview {
    FlashcardView(frontText: "안녕하세요", backText: "Hello")
}

