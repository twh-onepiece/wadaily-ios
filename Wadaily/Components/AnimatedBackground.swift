//
//  AnimatedBackground.swift
//  Wadaily
//
//  Created on 2025/12/03.
//

import SwiftUI

struct AnimatedShape: Identifiable {
    let id = UUID()
    var offset: CGSize
    var scale: CGFloat
    var opacity: Double
    var color: Color
}

struct AnimatedBackground: View {
    @State private var shapes: [AnimatedShape] = []
    
    var body: some View {
        ZStack {
            ForEach(shapes) { shape in
                Circle()
                    .fill(shape.color.opacity(shape.opacity))
                    .frame(width: 150, height: 150)
                    .scaleEffect(shape.scale)
                    .offset(shape.offset)
                    .blur(radius: 20)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        shapes = (0..<5).map { _ in
            AnimatedShape(
                offset: randomOffset(),
                scale: Double.random(in: 0.5...3.0),
                opacity: Double.random(in: 0.1...0.2),
                color: [Color.blue, Color.purple, Color.pink, Color.orange].randomElement()!
            )
        }

        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 3)) {
                for i in 0..<shapes.count {
                    shapes[i].offset = randomOffset()
                    shapes[i].scale = Double.random(in: 0.5...3.0)
                }
            }
        }
    }
    
    private func randomOffset() -> CGSize {
        CGSize(
            width: CGFloat.random(in: -300...300),
            height: CGFloat.random(in: -400...400)
        )
    }
}

#Preview {
    AnimatedBackground()
}
