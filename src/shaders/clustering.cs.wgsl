// TODO-2: implement the light clustering compute shader

@group(${bindGroup_scene}) @binding(0) var<uniform> camera: CameraUniforms;
@group(${bindGroup_scene}) @binding(1) var<storage, read> lightSet: LightSet;
@group(${bindGroup_scene}) @binding(2) var<storage, read_write> clusterSet: ClusterSet;

// ------------------------------------
// Calculating cluster bounds:
// ------------------------------------
// For each cluster (X, Y, Z):
//     - Calculate the screen-space bounds for this cluster in 2D (XY).
//     - Calculate the depth bounds for this cluster in Z (near and far planes).
//     - Convert these screen and depth bounds into view-space coordinates.
//     - Store the computed bounding box (AABB) for the cluster.

// ------------------------------------
// Assigning lights to clusters:
// ------------------------------------
// For each cluster:
//     - Initialize a counter for the number of lights in this cluster.

//     For each light:
//         - Check if the light intersects with the cluster’s bounding box (AABB).
//         - If it does, add the light to the cluster's light list.
//         - Stop adding lights if the maximum number of lights is reached.

//     - Store the number of lights assigned to this cluster.

@compute
@workgroup_size(${clusteringWorkgroupSize})
fn main(@builtin(global_invocation_id) globalIdx: vec3u) {
    let clusterIdx = globalIdx.x;
    if (clusterIdx >= ${clusterX} * ${clusterY} * ${clusterZ}) {
        return;
    }

    let x = clusterIdx % ${clusterX};
    let y = (clusterIdx / ${clusterX}) % ${clusterY};
    let z = clusterIdx / (${clusterX} * ${clusterY});

    // tile bounds in ndc, then scaled so that view xy = ndc * tanHalfFov * depth
    let tiles = vec2f(${clusterX}, ${clusterY});
    let lo = (vec2f(f32(x), f32(y)) / tiles * 2.f - 1.f) * camera.tanHalfFov;
    let hi = (vec2f(f32(x + 1), f32(y + 1)) / tiles * 2.f - 1.f) * camera.tanHalfFov;
    let zNear = sliceDepth(z);
    let zFar = sliceDepth(z + 1);

    // the camera looks down -z in view space
    let aabbMin = vec3f(min(lo * zNear, lo * zFar), -zFar);
    let aabbMax = vec3f(max(hi * zNear, hi * zFar), -zNear);

    let cluster = &clusterSet.clusters[clusterIdx];
    var count = 0u;
    for (var lightIdx = 0u; lightIdx < lightSet.numLights; lightIdx++) {
        let lightPos = (camera.viewMat * vec4f(lightSet.lights[lightIdx].pos, 1.f)).xyz;
        // closest point of the box to the light
        let d = clamp(lightPos, aabbMin, aabbMax) - lightPos;
        if (dot(d, d) <= ${lightRadius} * ${lightRadius}) {
            (*cluster).lightIndices[count] = lightIdx;
            count++;
            if (count == ${maxLightsPerCluster}) {
                break;
            }
        }
    }
    (*cluster).numLights = count;
}
