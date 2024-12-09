//
//  ShaderTypes.hpp
//  WavyBackgrounds
//
//  Created by Philipp Remy on 13.11.24.
//

#ifndef ShaderTypes_hpp
#define ShaderTypes_hpp

#include <simd/simd.h>

struct Vertex {
    simd_float4 position;
    simd_float2 texCoords;
};

struct Uniforms {
    float aspectRatio;
};

#endif /* ShaderTypes_hpp */
