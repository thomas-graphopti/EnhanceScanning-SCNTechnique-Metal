//
//  DepthFiltering.metal
//  Enhance-Scanning
//
//  Created by thomas(thomas@graphopti.com) on 30/09/2024.
//



#include <metal_stdlib>
using namespace metal;
#include <SceneKit/scn_metal>

struct VertexInput {
    float4 position [[attribute(SCNVertexSemanticPosition)]];
    float2 texCoords [[attribute(SCNVertexSemanticTexcoord0)]];
};

struct VertexOutput {
    float4 position [[position]];
    float2 texCoords;
};


struct custom_node_t3 {
    float4x4 modelTransform;
    float4x4 modelViewTransform;
    float4x4 normalTransform;
    float4x4 modelViewProjectionTransform;
};

struct custom_vertex_t
{
    float4 position [[attribute(SCNVertexSemanticPosition)]];
    float4 normal [[attribute(SCNVertexSemanticNormal)]];
};

struct out_vertex_t
{
    float4 position [[position]];
    float2 uv;
};

typedef struct {
    float3 glowColor;
} Inputs;


vertex out_vertex_t depth_filtering_vertex(custom_vertex_t in [[stage_in]])
{
    out_vertex_t out;
    out.position = in.position;
    out.uv = float2( (in.position.x + 1.0) * 0.5, 1.0 - (in.position.y + 1.0) * 0.5 );
    return out;
};


fragment half4 depth_filtering_fragment(out_vertex_t vert [[stage_in]],
                                texture2d<float, access::sample> colorSampler [[texture(0)]],
                                texture2d<float, access::sample> depthSampler [[texture(1)]],
                                constant Inputs& inputs [[buffer(0)]])
{
    // Assume a sampler 's' is defined elsewhere
    constexpr sampler s(filter::linear, address::repeat);

    float4 FragmentColor = colorSampler.sample(s, vert.uv);
    float depthValue = depthSampler.sample(s, vert.uv).r;

    // Check if the depth is zero
    if (depthValue == 0.0f) {
        // Mix the color with the red mask
        float3 redColor = float3(1.0, 0.0, 0.0);
        float mixFactor = 0.9f; // Adjust the mixing factor as needed
        float3 mixedColor = mix(FragmentColor.rgb, redColor, mixFactor);

        // Convert float components to half and construct half4
        half3 mixedColorHalf = half3(mixedColor);
        half alpha = half(1.0);
        return half4(mixedColorHalf, alpha);
    } else {
        // Set the color as original (transparent)
        half3 fragmentColorHalf = half3(FragmentColor.rgb);
        half alpha = half(1.0); // set alpha to 1.0 for the image output
        return half4(fragmentColorHalf, alpha);
    }
}






