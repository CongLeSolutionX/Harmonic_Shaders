# Harmonic Shaders ✨

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![License: CC BY 4.0](https://licensebuttons.net/l/by/4.0/88x31.png)](LICENSE-CC-BY)

---

Copyright (c) 2025 Cong Le. All Rights Reserved.

---

**A mini-app showcasing a dynamic, interactive background effect blending SwiftUI with Metal Shaders.**

[![Platform](https://img.shields.io/badge/platform-iOS-blue.svg)](https://developer.apple.com/ios/)
[![Language](https://img.shields.io/badge/language-Swift%20%7C%20Metal-orange.svg)](https://developer.apple.com/swift/)
[![Framework](https://img.shields.io/badge/framework-SwiftUI-purple.svg)](https://developer.apple.com/xcode/swiftui/)

---

Welcome to Harmonic Shaders! This project isn't just about a pretty visual; it's a demonstration of how to create deeply integrated, custom visual effects in SwiftUI by leveraging the power of Metal shaders. Press and hold the screen to see the waves transform!

<!-- **(Consider adding a GIF demonstrating the effect here!)** -->

<!-- ![Aura Flow Demo GIF](placeholder_aura_flow_demo.gif) -->
<!-- *Replace 'placeholder_aura_flow_demo.gif' with a path to your actual screen recording/GIF.* -->

---

## Features

*   **Dynamic Shader Background:** A full-screen, animated background rendered entirely with Metal.
*   **Layered Harmonic Waves:** Multiple layers of glowing, sine-like waves create depth and complexity.
*   **Interactive Transformation:** Press and hold the screen to smoothly transition the wave's frequency, color, glow intensity, and animation speed.
*   **SwiftUI Native Integration:** Uses SwiftUI's `TimelineView` for animation updates and `.colorEffect` for seamless shader integration.
*   **Haptic Feedback:** Subtle feedback enhances the Binteraction experience.
*   **Readable Code:** Both the Swift/SwiftUI code and the Metal Shading Language (MSL) code are commented to explain the process.

---

## The Technique: SwiftUI ❤️ Metal

The core idea demonstrated here is bridging the declarative UI world of SwiftUI with the high-performance graphics capabilities of Metal.

1.  **The Bridge (`.colorEffect` & `ShaderLibrary`):**
    *   SwiftUI's `.colorEffect` modifier is the key. It allows applying a Metal shader function directly to any SwiftUI view (or shape, like the `Rectangle` used here).
    *   The shader function (e.g., `harmonicColorEffect` in `HarmonicShaders.metal`) must be marked `[[stitchable]]` and included in your project's default `ShaderLibrary`.
    *   SwiftUI automatically handles compiling the shader and passing necessary context like pixel position (`pos`) and view bounds (`bounds`).

2.  **Passing Data:**
    *   Crucially, you can pass dynamic data from your SwiftUI state directly into the shader function as arguments (e.g., `.float(elapsedTime)`, `.float(mixCoeff)`).
    *   This allows the shader's output to react in real-time to state changes, user input, or animation progress.

3.  **The Metal Shader (`HarmonicShaders.metal`):**
    *   **Coordinate Normalization:** Converts pixel positions into a standard coordinate system (e.g., [-0.5, 0.5]) suitable for mathematical functions.
    *   **Harmonic Wave SDF:** Uses a Signed Distance Field (SDF) approach (`harmonicSDF` function) to calculate the distance from any given pixel to the curve of a harmonic (cosine) wave. This is efficient for generating wave shapes.
    *   **Glow Effect:** Implements a simple inverse-power function (`glow`) to create a bright glow near the wave curve, fading with distance.
    *   **Layering:** A `for` loop iterates to draw `wavesCount` layers. Each layer gets a slightly different phase (`phase = time + i * ...`) based on the loop index `i` and the elapsed `time`, making the waves appear distinct and animated.
    *   **Parameter Modulation:** Base wave amplitude (`a`) and vertical offset (`offset`) are calculated based on the pixel's `uv.x`, creating visual variation across the screen.
    *   **Interaction via Interpolation (`mix`):** The shader receives a `mixCoeff` (0.0 for released, 1.0 for pressed). The `mix()` function is used extensively to linearly interpolate key visual parameters (like `frequency`, `glowWidth`, `glowIntensity`, and `waveColor`) between their "released" and "pressed" states, creating the smooth visual transition.
    *   **Color Palette:** A `getColor` function provides distinct colors for each wave layer when in the "pressed" state.

4.  **The Interaction Model (`ContentView.swift`):**
    *   **`TimelineView`:** Provides a reliable, periodic update mechanism (`context.date`) to drive the animation, independent of frame rate fluctuations.
    *   **`@State` Variables:** Track `elapsedTime` for animation, `amplitude` and `speedMultiplier` for visual state, and `isInteracting` (Bool) to represent the press state.
    *   **`DragGesture(minimumDistance: 0)`:** Used as a press-and-hold gesture detector. `onChanged` fires on touch down, `onEnded` fires on touch up.
    *   **`withAnimation(.spring(...))`:** Wraps state changes that affect visual parameters (`amplitude`, `speedMultiplier`) to create smooth, physical-feeling transitions.
    *   **`mixCoeff` Derivation:** The `isInteracting` boolean state is converted directly to the `mixCoeff` float (`isInteracting ? 1.0 : 0.0`) passed to the shader.
    *   **`ZStack` & `.allowsHitTesting(false)`:** The shader is applied to a background layer. The foreground UI (`Text`, `Image`) has `.allowsHitTesting(false)` so that the `DragGesture` on the background always receives the touch events.

---

## Key Code Highlights

*   **`HarmonicShaders.metal`:** Look for the `[[ stitchable ]] harmonicColorEffect(...)` function and its helpers (`harmonicSDF`, `glow`, `getColor`). Pay attention to the `mix()` calls driven by `mixCoeff`.
*   **`ContentView.swift`:** Examine the `@State` variables, the `TimelineView` setup, the `.colorEffect` modifier invocation with its `.float()` arguments, and the `DragGesture` implementation (`onChanged`, `onEnded`).

---

## How to Run

1.  Clone this repository:
    ```bash
    git clone <your-repository-url>
    cd Harmonic_Shaders
    ```
2.  Open `HarmonicShaders.xcodeproj` in Xcode.
3.  Select a target device (Physical iOS device recommended for best performance, or a Metal-capable simulator).
4.  Build and run the application (Cmd+R).
5.  Press and hold anywhere on the screen to interact!

---

## Customization & Ideas

Feel free to experiment!

*   **Adjust Parameters:** Tweak the `wavesCount`, `amplitude`, `speedMultiplier`, and the `mix()` target values in `ContentView.swift` and `HarmonicShaders.metal`.
*   **Change Colors:** Modify the `getColor` function in the Metal shader or implement a procedural color generation scheme.
*   **Different Interactions:** Use other gestures (like panning) to control different shader parameters.
*   **More Complex Shaders:** Explore different SDFs, noise functions (like Perlin or Simplex), or fragment shaders for entirely different visual effects.
*   **Performance:** Profile using Instruments, especially if increasing `wavesCount` significantly. Consider using `half` precision more where applicable in the shader.

---

## License

*   Code files within this repository (including the Mermaid.js diagram source files) are licensed under the [MIT License](LICENSE).
*   Documentation and textual explanations (README.md and associated files) are licensed under the [Creative Commons Attribution 4.0 International License (CC BY 4.0)](LICENSE-CC-BY).


---

*Created by Cong Le*
*Feel free to reach out or open an issue if you have questions!*



----


