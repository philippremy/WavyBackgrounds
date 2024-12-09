//
//  MTLSpacesViewShaders.metal
//  WavyBackgrounds
//
//  Created by Philipp Remy on 13.11.24.
//

#include <metal_stdlib>
using namespace metal;

#include "ShaderTypes.h"

struct VertexOut {
    simd_float4 position [[position]];
    simd_float2 texCoords;
};

vertex VertexOut
vertex_main(constant Vertex* vertices [[buffer(0)]],
                             constant Uniforms& uniforms [[buffer(1)]],
                             constant float& offsetFromRight [[buffer(2)]],
                             constant float& numberOfSpaces [[buffer(3)]],
                             constant float& padding [[buffer(4)]],
                             constant float& paddingGlobal [[buffer(5)]],
                             uint vertex_id [[vertex_id]])
{
    VertexOut out;
    
    // Apply aspect ratio
    float4 position = vertices[vertex_id].position;
    position *= uniforms.aspectRatio;
    
    // Normalize geometry to NDC
    float maxComponent = max(abs(position.x), abs(position.y));
    if (maxComponent > 1.0) {
        position /= maxComponent;
    }
    
    position.x /= numberOfSpaces;
    
    // Apply a resize because of padding
    // Normalize padding to a 0.0 to 1.0 scale
    float normalizedPadding = paddingGlobal / 100.0;

    // Convert normalized padding to a clip space scale factor (0.0 - 0.5)
    float scaleFactor = (1.0 - (normalizedPadding * numberOfSpaces) * 0.5);
    
    position.xy *= scaleFactor;
    
    // Align tris to the left
    position.x -= 1.0 - (1.0 / numberOfSpaces);
    
    // Apply calculated offset from the right (include padding)
    position.x += (1.0 / numberOfSpaces) * 2 * offsetFromRight;
    
    // Set output position in NDC
    position.w = 1;
    out.position = position;
    
    // Pass texture coordinates
    out.texCoords = vertices[vertex_id].texCoords;
    
    return out;
}


fragment float4
fragment_main(VertexOut in [[stage_in]],
              texture2d<float> texture [[texture(0)]],
              sampler textureSampler [[sampler(0)]])
{
    // Sample the texture
    return texture.sample(textureSampler, in.texCoords);
}
