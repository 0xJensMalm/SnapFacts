// CardShaders.metal

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h> // Required for SwiftUI shader integration

using namespace metal;

[[stitchable]] half4 cardEffect(
    float2 position, // The position of the current pixel in normalized coordinates (0-1)
    half4 color,     // The original color of the pixel from the SwiftUI view
    float2 size,     // The size of the view being shaded
    // We can add more uniforms here later (e.g., rotation, time, light position)
    float time // Example uniform
) {
    // For now, let's just return the original color, possibly tinted slightly
    // or vary color based on position to test
    half red = color.r * (position.x + 0.5); // Make red brighter towards the right
    return half4(red, color.g, color.b, color.a);
}
