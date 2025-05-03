// MIT License
//
// Copyright (c) 2025 Cong Le
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

//  ContentView.swift
//  HarmonicShaders
//
//  Created by Cong Le on 4/29/25.
//  Displays a full-screen background effect using the `harmonicColorEffect` Metal shader.
//  Allows interaction (holding down) to change the shader's appearance and animation speed.
//

import SwiftUI

struct ContentView: View {
    // MARK: - State Variables

    /// Controls the speed of the animation time progression. 1.0 is normal speed.
    @State private var speedMultiplier: Double = 1.0
    /// Controls the base amplitude passed to the shader, affecting wave height modulation.
    @State private var amplitude: Float = 0.5 // Initial resting amplitude
    /// Tracks the elapsed time for the animation, continuously updated. Drives shader animation.
    @State private var elapsedTime: Double = 0.0
    /// Defines the approximate time interval for animation updates (targets ~60 FPS).
    private let updateInterval: Double = 0.016 // 1.0 / 60.0

    /// Tracks whether the user is currently pressing down on the view. Drives shader interpolation (`mixCoeff`).
    @State private var isInteracting: Bool = false

    // MARK: - Body
    var body: some View {
        // `TimelineView` provides a periodic pulse (`context.date`) used to drive the animation updates.
        // The schedule updates based on `updateInterval` adjusted by `speedMultiplier`.
        TimelineView(.periodic(from: .now, by: updateInterval / speedMultiplier)) { context in
            // `ZStack` layers the shader background effect underneath the main UI content.
            ZStack {

                // --- 1. Background Shader Layer & Gesture Detection ---
                // An invisible Color.clear fills the space, allowing it to receive gestures
                // and serve as the canvas for the background shader effect.
                Color.clear
                    .ignoresSafeArea() // Ensure it covers the entire screen area.
                    .background {
                        // A Rectangle shape provides the geometry onto which the shader is drawn.
                        Rectangle()
                            .ignoresSafeArea()
                            // Apply the Metal shader using the `.colorEffect` modifier.
                            .colorEffect(ShaderLibrary.default.harmonicColorEffect(
                                // Pass the view's bounds to the shader for coordinate normalization.
                                .boundingRect,
                                // Pass the static number of wave layers (note: Swift Float needed).
                                .float(6),
                                // Pass the current animation time.
                                .float(elapsedTime),
                                // Pass the current amplitude state variable.
                                .float(amplitude),
                                // Pass the interaction coefficient: 1.0 if interacting, 0.0 otherwise.
                                .float(isInteracting ? 1.0 : 0.0)
                            ))
                    }
                    // Attach a DragGesture to detect touch down and release events.
                    // `minimumDistance: 0` makes it trigger immediately on touch, behaving like a press/hold gesture.
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                // Called when the touch *starts* or moves.
                                // We only want to trigger the "pressed" state change once per interaction.
                                if !isInteracting {
                                    isInteracting = true // Set interaction state
                                    // Animate the amplitude and speed TO the "active" state using a spring effect.
                                    withAnimation(.spring(duration: 0.3)) {
                                        amplitude = 2.0 // Increase amplitude
                                        speedMultiplier = 2.0 // Speed up animation
                                    }
                                    // Explicitly trigger haptic feedback on press *start*.
                                    // Note: May be slightly redundant if `.sensoryFeedback` below is sufficient,
                                    // but ensures feedback happens exactly here if needed.
                                     UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                }
                            }
                            .onEnded { _ in
                                // Called when the touch *ends* (finger lifted).
                                // Only trigger the "released" state change if we were actually interacting.
                                if isInteracting {
                                    // Set interaction state *before* the animation block
                                    // so the animation targets the correct final values.
                                    isInteracting = false
                                    // Animate the amplitude and speed BACK to the "resting" state.
                                    withAnimation(.spring(duration: 0.3)) {
                                        amplitude = 0.5 // Return to base amplitude
                                        speedMultiplier = 1.0 // Return to normal speed
                                    }
                                }
                            }
                    )
                    // Triggered by the `TimelineView` updating `context.date`.
                    // Updates the `elapsedTime` state variable on each frame tick.
                    // The increment is scaled by `speedMultiplier` for animation speed control.
                    .onChange(of: context.date) { _, _ in // Use _ for unused old/new values
                         elapsedTime += updateInterval * speedMultiplier
                     }
                    // Provides declarative haptic feedback.
                    // Triggers an impact feedback whenever the `isInteracting` state changes
                    // from `false` to `true` (i.e., at the start of a press).
                    .sensoryFeedback(.impact, trigger: isInteracting)

                // --- 2. Foreground UI Content ---
                // This is the visible UI layered on top of the shader background.
                VStack {
                    Spacer() // Pushes content towards the bottom.

                    // Text display changes based on the interaction state.
                    Text(isInteracting ? "Holding..." : "Hold Anywhere!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white) // Ensure text is visible against the shader
                        .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2) // Add shadow for contrast
                        .padding(.bottom, 50)
                        // Animate the text change smoothly.
                        .animation(.easeInOut(duration: 0.1), value: isInteracting)

                    // Example image content.
                    Image("My-meme-orange-microphone")
                        .resizable()
                        .scaledToFit() // Use scaledToFit to maintain aspect ratio
                        .frame(width: 280, height: 200)

                }
                .padding()
                // VERY IMPORTANT: Prevent the foreground UI from intercepting touch events.
                // This allows the `DragGesture` on the background layer to always receive touches.
                .allowsHitTesting(false)

            } // End ZStack
        } // End TimelineView
    } // End body
}

// MARK: - Preview

#Preview {
    ContentView()
}
