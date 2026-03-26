#include <metal_stdlib>
using namespace metal;

// MARK: - Vertex Shader
vertex float4 vertexShader(
    uint vertexId [[vertex_id]],
    constant float &time [[buffer(0)]]) {
    
    // Full screen quad vertices
    float2 positions[] = {
        float2(-1, -1),
        float2( 1, -1),
        float2( 1,  1),
        float2(-1, -1),
        float2( 1,  1),
        float2(-1,  1)
    };
    
    return float4(positions[vertexId], 0, 1);
}

// MARK: - Fragment Shader with Visual Effects
fragment float4 fragmentShader(
    float4 position [[position]],
    constant float &time [[buffer(0)]]) {
    
    float2 uv = position.xy / float2(1440, 3120); // Adjust based on screen size
    float2 center = float2(0.5, 0.5);
    
    // Effect 1: Animated waves
    float wave = sin(uv.x * 10.0 + time * 2.0) * cos(uv.y * 10.0 + time * 1.5);
    wave = (wave + 1.0) * 0.5;
    
    // Effect 2: Radial gradient with time
    float dist = distance(uv, center);
    float radial = sin(dist * 5.0 - time * 3.0) * 0.5 + 0.5;
    
    // Effect 3: Color rotation
    float3 color = float3(
        0.5 + 0.5 * sin(time + uv.x * 3.0),
        0.5 + 0.5 * sin(time + uv.y * 3.0 + 2.094),
        0.5 + 0.5 * sin(time + (uv.x + uv.y) * 3.0 + 4.189)
    );
    
    // Combine effects
    float intensity = wave * radial;
    color *= intensity;
    
    // Add subtle scanlines
    float scanline = sin(position.y * 0.5) * 0.1 + 0.9;
    color *= scanline;
    
    return float4(color, 1.0);
}
