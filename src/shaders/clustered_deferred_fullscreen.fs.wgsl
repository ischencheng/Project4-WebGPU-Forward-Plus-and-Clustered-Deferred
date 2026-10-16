// TODO-3: implement the Clustered Deferred fullscreen fragment shader

// Similar to the Forward+ fragment shader, but with vertex information coming from the G-buffer instead.

@group(${bindGroup_scene}) @binding(0) var<uniform> camera: CameraUniforms;
@group(${bindGroup_scene}) @binding(1) var<storage, read> lightSet: LightSet;
@group(${bindGroup_scene}) @binding(2) var<storage, read> clusterSet: ClusterSet;
@group(${bindGroup_scene}) @binding(3) var albedoTex: texture_2d<f32>;
@group(${bindGroup_scene}) @binding(4) var normalTex: texture_2d<f32>;
@group(${bindGroup_scene}) @binding(5) var positionTex: texture_2d<f32>;

@fragment
fn main(@builtin(position) fragPos: vec4f) -> @location(0) vec4f
{
    let pixel = vec2i(fragPos.xy);
    let albedo = textureLoad(albedoTex, pixel, 0);
    if (albedo.a == 0.f) {
        return vec4f(0, 0, 0, 0); // background
    }
    let nor = textureLoad(normalTex, pixel, 0).xyz;
    let pos = textureLoad(positionTex, pixel, 0).xyz;

    let viewDepth = -(camera.viewMat * vec4f(pos, 1.f)).z;
    let cluster = &clusterSet.clusters[clusterIndex(fragPos.xy, viewDepth, camera.screenSize)];

    var totalLightContrib = vec3f(0, 0, 0);
    for (var i = 0u; i < (*cluster).numLights; i++) {
        let light = lightSet.lights[(*cluster).lightIndices[i]];
        totalLightContrib += calculateLightContrib(light, pos, nor);
    }

    return vec4f(albedo.rgb * totalLightContrib, 1);
}
