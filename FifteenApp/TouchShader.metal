#include <metal_stdlib>
using namespace metal;

// MARK: - Vertex Shader
vertex float4 touchVertexShader(
    uint vertexId [[vertex_id]],
    constant float &time [[buffer(0)]]) {
    
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

// MARK: - Touch-Responsive Fragment Shader
fragment float4 touchFragmentShader(
    float4 position [[position]],
    constant float &time [[buffer(0)]],
    constant float2 &screenSize [[buffer(1)]],
    constant float2 *touchPoints [[buffer(2)]],
    constant bool *touchActive [[buffer(3)]]) {
    
    float2 uv = position.xy / screenSize;
    float2 center = float2(0.5, 0.5);
    
    // Initialize color
    float3 color = float3(0.05, 0.05, 0.1);
    
    // Process each touch point
    for (int i = 0; i < 10; i++) {
        if (touchActive[i]) {
            float2 touchNormalized = touchPoints[i] / screenSize;
            float dist = distance(uv, touchNormalized);
            
            // Ripple effect from touch
            float ripple = sin(dist * 20.0 - time * 5.0) / (dist * 2.0 + 0.5);
            ripple = max(0.0, ripple);
            
            // Color based on touch index
            float3 touchColor = float3(
                0.5 + 0.5 * sin(float(i) * 0.628 + time),
                0.5 + 0.5 * cos(float(i) * 0.628 + time),
                0.5 + 0.5 * sin(float(i) * 0.628 + time + 1.57)
            );
            
            // Glow effect
            float glow = exp(-dist * 3.0) * 0.8;
            
            // Add to final color
            color += touchColor * (ripple + glow) * 0.6;
        }
    }
    
    // Background animation
    float wave = sin(uv.x * 5.0 + time * 0.5) * cos(uv.y * 5.0 + time * 0.3);
    color += float3(0.02, 0.03, 0.05) * (wave * 0.5 + 0.5);
    
    // Add subtle grid
    float gridX = sin(uv.x * 30.0) * 0.05;
    float gridY = sin(uv.y * 30.0) * 0.05;
    color += float3(gridX, gridY, gridX + gridY) * 0.1;
    
    // Tone mapping
    color = color / (color + float3(1.0));
    
    return float4(color, 1.0);
}
