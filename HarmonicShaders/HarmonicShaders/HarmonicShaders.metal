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

//  HarmonicShaders.metal
//  HarmonicShaders
//

//  Created by Cong Le on 4/29/25.
//  Defines Metal shader functions for creating dynamic, layered harmonic wave effects.
//  This shader is designed to be used with SwiftUI's .colorEffect modifier.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h> // Required for SwiftUI integration and the `[[stitchable]]` attribute

using namespace metal;

// Standard Metal constant for Pi (single precision float)
// #define M_PI_F 3.141592653589793f // Metal provides M_PI_F directly

// MARK: - Helper Functions

/**
 * @brief Calculates the signed distance field (SDF) value for a single harmonic wave.
 * This represents the shortest distance from a given point (uv) to the curve defined by the harmonic function.
 * The function calculates: |(y - offset) + A * cos(x*frequency + phase)|
 *
 * @param uv The normalized 2D texture coordinates, typically ranging from [-0.5, 0.5] or [0, 1].
 *           Assumed here to be centered around (0,0) for symmetrical effects.
 * @param a The modulated amplitude of the cosine wave at this specific uv coordinate.
 * @param offset The modulated vertical offset of the cosine wave at this specific uv coordinate.
 * @param f The frequency of the cosine wave, determining how many cycles appear horizontally.
 * @param phi The phase shift of the cosine wave, controlling its horizontal position.
 *
 * @return The absolute distance (unsigned) from the point `uv` to the harmonic wave curve.
 */
float harmonicSDF(float2 uv, float a, float offset, float f, float phi) {
    // Equation: |(y - offset) + A * cos(x*frequency + phase)|
    // uv.y represents the vertical position of the pixel.
    // (offset - cos(...) * a) represents the vertical position of the wave at uv.x.
    // The absolute difference gives the distance.
    return abs((uv.y - offset) + cos(uv.x * f + phi) * a);
}

/**
 * @brief Calculates a simple glow intensity based on the distance from a source (like an SDF).
 * The closer the point is to the source (smaller x), the brighter the glow.
 *
 * @param x The input distance, typically the result from an SDF calculation (`harmonicSDF`).
 * @param str The strength or falloff exponent of the glow. Higher values mean faster falloff.
 * @param dist The base intensity or brightness multiplier of the glow at zero distance.
 *
 * @return The calculated glow intensity, ranging from potentially high values near zero distance down to zero.
 */
float glow(float x, float str, float dist){
    // Intensity diminishes rapidly as distance (x) increases based on the power `str`.
    // Using pow(abs(x), str) ensures the function handles potential small negative distances robustly
    // and avoids issues with pow for negative bases if str is fractional (though str is likely > 0 here).
    return dist / pow(abs(x), str);
}

/**
 * @brief Returns a color from a predefined palette based on an index.
 * This provides distinct colors for different layers of the harmonic effect.
 * The palette used here is hardcoded based on an external reference/article.
 *
 * @param t The index used to select the color. Expected to be a whole number (0, 1, 2, ...).
 *
 * @return A float3 representing the RGB color corresponding to the index `t`. Returns white as a fallback.
 */
float3 getColor(float t) {
    // Using the hardcoded palette for distinct wave colors.
    // Rounding `t` provides some safety if `t` isn't perfectly integer due to float loop iterations.
    int index = int(round(t));

    // Palette indices mapped to specific RGB colors
    if (index == 0) {
        return float3(0.4823529412, 0.831372549, 0.8549019608); // Teal-ish
    }
    if (index == 1) {
        return float3(0.4117647059, 0.4117647059, 0.8470588235); // Purple-ish
    }
    if (index == 2) {
        return float3(0.9411764706, 0.3137254902, 0.4117647059); // Red-pink
    }
    if (index == 3) {
        return float3(0.2745098039, 0.4901960784, 0.9411764706); // Blue
    }
    if (index == 4) {
        return float3(0.0784313725, 0.862745098, 0.862745098); // Cyan
    }
    if (index == 5) {
        return float3(0.7843137255, 0.6274509804, 0.5490196078); // Brown-ish / Dusty Rose
    }
    // Default fallback color if the index is out of the defined range.
    return float3(1.0); // White
}

/* TODO: More research and update this section,
/// focusing on the math areas contributing to the related effects
// Alternatively, use a procedural color calculation based on index `t`:
float3 getColor(float t) {
  // Adjust t to typically be within a [0, 1] range if needed for trigonometric functions.
  // Example: Assuming t is the loop index and wavesCount is the total loop count.
  // float adjusted_t = t / float(wavesCount); // wavesCount needs to be passed in or known

  // Use cosine functions shifted in phase to generate varying RGB components.
  float r = 0.5 + 0.5 * cos(2.0 * M_PI_F * adjusted_t);
  float g = 0.5 + 0.5 * cos(2.0 * M_PI_F * adjusted_t + 2.0 * M_PI_F / 3.0); // Phase shift by 120 degrees
  float b = 0.5 + 0.5 * cos(2.0 * M_PI_F * adjusted_t + 4.0 * M_PI_F / 3.0); // Phase shift by 240 degrees

  // Clamp the result to the valid [0, 1] color range.
  return clamp(float3(r, g, b), 0.0, 1.0);
}
*/

// MARK: - Main Shader Function

/**TODO: More research on related math areas for this secton
 * @brief A Metal shader kernel function designed for SwiftUI's `colorEffect`.
 * It renders multiple layers of animated, glowing harmonic waves.
 * The appearance (frequency, glow, color) changes based on time and an interaction state (`mixCoeff`).
 *
 * @param pos The pixel position in the coordinate space of the view the shader is applied to.
 * @param color The original color of the pixel at `pos`. Not used in this effect, which overwrites the color.
 * @param bounds A float4 representing the bounding rectangle of the view (x, y, width, height). Used for normalization.
 * @param wavesCount The number of distinct harmonic wave layers to render and blend.
 * @param time The elapsed animation time, driving the wave motion (phase shifts).
 * @param amplitude The base amplitude value, controlled externally (e.g., by SwiftUI state), affecting wave height modulation.
 * @param mixCoeff A coefficient ranging from 0.0 to 1.0 used to interpolate between two visual states
 *                 (e.g., 0.0 for a 'released' state, 1.0 for a 'pressed' state). Affects frequency, glow, and color.
 *
 * @return A half4 color (RGBA) representing the final computed color for the pixel at `pos`. Alpha is always 1.0.
 */
[[ stitchable ]] // Makes this function usable by SwiftUI's `ShaderLibrary` and `colorEffect`.
half4 harmonicColorEffect(
    float2 pos,         // Pixel position in view coordinates (e.g., from 0,0 top-left)
    half4 color,        // Original pixel color from the view content (unused here)
    float4 bounds,      // Bounding rectangle: (bounds.x, bounds.y, bounds.z = width, bounds.w = height)
    float wavesCount,   // Number of harmonic waves to layer (passed as float from Swift)
    float time,         // Animation time elapsed (passed as float)
    float amplitude,    // Base amplitude, modulated by position (passed as float)
    float mixCoeff      // Interpolation coefficient [0.0, 1.0] (passed as float)
) {
    // --- 1. Coordinate Normalization ---
    // Convert pixel position `pos` to normalized coordinates `uv`.
    // Division by width (bounds.z) and height (bounds.w) maps coords to [0, 1].
    float2 uv = pos / float2(bounds.z, bounds.w);
    // Shift the origin to the center [-0.5, 0.5] for symmetrical calculations.
    uv -= float2(0.5, 0.5);

    // --- 2. Calculate Base Modulated Parameters ---
    // Modulate amplitude based on horizontal position (uv.x).
    // Creates a bulging effect towards the center. `amplitude` scales the overall effect.
    float a = cos(uv.x * 3.0) * amplitude * 0.2;
    // Modulate vertical offset based on horizontal position and time.
    // Creates a vertical undulation that moves horizontally.
    float offset = sin(uv.x * 12.0 + time) * a * 0.1;

    // --- 3. Interpolate Parameters Based on Interaction State (mixCoeff) ---
    // Linearly interpolate between two states for various parameters using `mixCoeff`.
    // Frequency changes from 3.0 (released) to 12.0 (pressed).
    float frequency = mix(3.0, 12.0, mixCoeff);
    // Glow falloff exponent changes from 0.6 (wider glow) to 0.9 (tighter glow).
    float glowWidth = mix(0.6, 0.9, mixCoeff);
    // Glow base intensity changes from 0.02 (brighter) to 0.01 (dimmer).
    float glowIntensity = mix(0.02, 0.01, mixCoeff);

    // --- 4. Loop Through Wave Layers ---
    float3 finalColor = float3(0.0); // Initialize final color accumulator (black)

    // Iterate for the specified number of waves.
    // Using float for loop counter to match `wavesCount` type and avoid casting warnings.
    // TODO: More research on type differences among float, float3, float4, half3, half4, Double, etc. between Metal ansd Swift environment
    for (float i = 0.0; i < wavesCount; i++) {
        // Calculate the phase shift for this specific wave layer.
        // Each layer `i` has a phase offset based on `i / wavesCount`, creating separation.
        // `time` provides the continuous animation.
        float phase = time + i * M_PI_F / wavesCount;

        // Calculate the distance from the current pixel `uv` to this wave layer using the SDF.
        // Uses the modulated amplitude `a`, offset `offset`, interpolated frequency, and calculated phase.
        float sdfDist = harmonicSDF(uv, a, offset, frequency, phase);

        // Apply the glow effect based on the SDF distance and interpolated glow parameters.
        float glowDist = glow(sdfDist, glowWidth, glowIntensity);

        // Determine the color for this wave layer.
        // Interpolates between white (1.0) when released (`mixCoeff`=0)
        // and a palette color (`getColor(i)`) when pressed (`mixCoeff`=1).
        float3 waveColor = mix(float3(1.0), getColor(i), mixCoeff);

        // Accumulate the color contribution of this wave layer.
        // The glow intensity (`glowDist`) modulates the wave's color.
        finalColor += waveColor * glowDist;
    }

    // --- 5. Finalize and Return Color ---
    // Clamp the final accumulated color to the valid [0.0, 1.0] range
    // to prevent potential over-bright pixels if glows overlap significantly.
    finalColor = clamp(finalColor, 0.0, 1.0);
    //TODO: Research more on the spectrum of color range and spectrum of wave length

    // Convert the final float3 RGB color to half3 for efficiency,
    // and combine it with a full alpha channel (1.0h) to create the half4 result.
    return half4(half3(finalColor), 1.0h);
}
