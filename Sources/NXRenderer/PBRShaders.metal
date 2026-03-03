// PBRShaders.metal
// Genolanx — Metal PBR shaders for 3D viewport rendering
//
// Simplified Cook-Torrance BRDF with procedural environment lighting (V1).
// IBL from DDS textures will be added in V2.

#include <metal_stdlib>
using namespace metal;

// ---------------------------------------------------------------------------
// MARK: - Shared Uniform Structures
// ---------------------------------------------------------------------------

struct SceneUniforms {
    float4x4 modelMatrix;
    float4x4 viewProjectionMatrix;
    float3   eyePosition;
    float    _pad0;
    float3   lightDirection;
    float    _pad1;
};

struct MaterialUniforms {
    float4 baseColor;     // RGBA
    float  metallic;
    float  roughness;
    float2 _pad;
};

// ---------------------------------------------------------------------------
// MARK: - PBR Mesh Shaders
// ---------------------------------------------------------------------------

struct MeshVertexIn {
    float3 position [[attribute(0)]];
    float3 normal   [[attribute(1)]];
};

struct MeshVertexOut {
    float4 clipPosition [[position]];
    float3 worldPosition;
    float3 worldNormal;
    float3 eyeDirection;
};

vertex MeshVertexOut meshVertexShader(
    MeshVertexIn in [[stage_in]],
    constant SceneUniforms& scene [[buffer(1)]])
{
    MeshVertexOut out;
    float4 worldPos = scene.modelMatrix * float4(in.position, 1.0);
    out.clipPosition  = scene.viewProjectionMatrix * worldPos;
    out.worldPosition = worldPos.xyz;
    out.worldNormal   = normalize((scene.modelMatrix * float4(in.normal, 0.0)).xyz);
    out.eyeDirection  = normalize(scene.eyePosition - worldPos.xyz);
    return out;
}

// GGX/Trowbridge-Reitz normal distribution
float distributionGGX(float NdotH, float roughness) {
    float a  = roughness * roughness;
    float a2 = a * a;
    float denom = NdotH * NdotH * (a2 - 1.0) + 1.0;
    return a2 / (M_PI_F * denom * denom);
}

// Schlick-GGX geometry function
float geometrySchlickGGX(float NdotV, float roughness) {
    float r = roughness + 1.0;
    float k = (r * r) / 8.0;
    return NdotV / (NdotV * (1.0 - k) + k);
}

// Smith's geometry function
float geometrySmith(float NdotV, float NdotL, float roughness) {
    return geometrySchlickGGX(NdotV, roughness) * geometrySchlickGGX(NdotL, roughness);
}

// Fresnel-Schlick approximation
float3 fresnelSchlick(float cosTheta, float3 F0) {
    return F0 + (1.0 - F0) * pow(saturate(1.0 - cosTheta), 5.0);
}

fragment float4 meshFragmentShader(
    MeshVertexOut in [[stage_in]],
    constant MaterialUniforms& material [[buffer(0)]],
    constant SceneUniforms& scene [[buffer(1)]])
{
    float3 N = normalize(in.worldNormal);
    float3 V = normalize(in.eyeDirection);
    float3 L = normalize(scene.lightDirection);
    float3 H = normalize(V + L);

    float3 albedo    = material.baseColor.rgb;
    float  metalness = material.metallic;
    float  roughness = max(material.roughness, 0.04);

    // Fresnel
    float3 F0 = mix(float3(0.04), albedo, metalness);

    float NdotV = max(dot(N, V), 0.001);
    float NdotL = max(dot(N, L), 0.0);
    float NdotH = max(dot(N, H), 0.0);
    float HdotV = max(dot(H, V), 0.0);

    // Cook-Torrance specular BRDF
    float  D = distributionGGX(NdotH, roughness);
    float  G = geometrySmith(NdotV, NdotL, roughness);
    float3 F = fresnelSchlick(HdotV, F0);

    float3 numerator  = D * G * F;
    float  denominator = 4.0 * NdotV * NdotL + 0.0001;
    float3 specular = numerator / denominator;

    float3 kD = (1.0 - F) * (1.0 - metalness);
    float3 diffuse = kD * albedo / M_PI_F;

    // Main directional light (warm white)
    float3 lightColor = float3(1.0, 0.98, 0.95) * 2.5;
    float3 Lo = (diffuse + specular) * lightColor * NdotL;

    // Fill light (cool blue, from below-left)
    float3 fillDir = normalize(float3(-0.5, -0.3, -0.7));
    float fillNdotL = max(dot(N, -fillDir), 0.0);
    Lo += albedo * float3(0.6, 0.7, 0.9) * 0.3 * fillNdotL;

    // Hemisphere ambient (sky + ground)
    float skyFactor = N.z * 0.5 + 0.5;  // Z-up: 1=sky, 0=ground
    float3 skyColor    = float3(0.4, 0.5, 0.7);
    float3 groundColor = float3(0.3, 0.25, 0.2);
    float3 ambient = mix(groundColor, skyColor, skyFactor) * 0.15 * albedo;

    float3 color = Lo + ambient;

    // Tone mapping (ACES approximation)
    float3 x = color;
    color = (x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14);

    return float4(saturate(color), material.baseColor.a);
}

// ---------------------------------------------------------------------------
// MARK: - PolyLine Shaders
// ---------------------------------------------------------------------------

struct LineVertexIn {
    float3 position [[attribute(0)]];
};

struct LineVertexOut {
    float4 clipPosition [[position]];
    float4 color;
};

vertex LineVertexOut lineVertexShader(
    LineVertexIn in [[stage_in]],
    constant SceneUniforms& scene [[buffer(1)]],
    constant float4& lineColor [[buffer(2)]])
{
    LineVertexOut out;
    float4 worldPos = scene.modelMatrix * float4(in.position, 1.0);
    out.clipPosition = scene.viewProjectionMatrix * worldPos;
    out.color = lineColor;
    return out;
}

fragment float4 lineFragmentShader(LineVertexOut in [[stage_in]]) {
    return in.color;
}

// ---------------------------------------------------------------------------
// MARK: - Grid Shader (infinite ground grid)
// ---------------------------------------------------------------------------

struct GridVertexOut {
    float4 clipPosition [[position]];
    float3 worldPosition;
};

vertex GridVertexOut gridVertexShader(
    uint vertexID [[vertex_id]],
    constant SceneUniforms& scene [[buffer(1)]],
    constant float& gridSize [[buffer(2)]])
{
    // Full-screen quad: 6 vertices for 2 triangles
    float2 positions[6] = {
        float2(-1, -1), float2(1, -1), float2(1, 1),
        float2(-1, -1), float2(1,  1), float2(-1, 1)
    };
    float2 pos = positions[vertexID] * gridSize;

    GridVertexOut out;
    float4 worldPos = float4(pos.x, pos.y, 0.0, 1.0);
    out.clipPosition  = scene.viewProjectionMatrix * worldPos;
    out.worldPosition = worldPos.xyz;
    return out;
}

fragment float4 gridFragmentShader(GridVertexOut in [[stage_in]]) {
    float2 coord = in.worldPosition.xy;

    // Major grid lines every 10mm
    float2 grid10 = abs(fract(coord / 10.0 - 0.5) - 0.5) / fwidth(coord / 10.0);
    float line10 = min(grid10.x, grid10.y);

    // Minor grid lines every 1mm
    float2 grid1 = abs(fract(coord - 0.5) - 0.5) / fwidth(coord);
    float line1 = min(grid1.x, grid1.y);

    float alpha = 1.0 - min(line10, 1.0) * 0.7;
    alpha = max(alpha, (1.0 - min(line1, 1.0)) * 0.15);

    // Fade with distance
    float dist = length(coord);
    alpha *= saturate(1.0 - dist / 200.0);

    return float4(0.5, 0.5, 0.5, alpha * 0.4);
}
