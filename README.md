WebGL Forward+ and Clustered Deferred Shading
======================

**University of Pennsylvania, CIS 565: GPU Programming and Architecture, Project 4**

* Chen Cheng
  * [LinkedIn](https://www.linkedin.com/in/chen-andrew-cheng-34a133229/), [GitHub](https://github.com/ischencheng)
* Tested on: **Google Chrome 155** on Windows 11, i5-12500H @ 2.50GHz 16GB, NVIDIA GeForce RTX 2050 4GB (personal laptop)

### Live Demo

[![thumb](img/thumb.png)](https://ischencheng.github.io/Project4-WebGPU-Forward-Plus-and-Clustered-Deferred/)

### Demo Video/GIF

![demo](img/demo.gif)

### Description

This project renders the Sponza atrium lit by up to 5000 moving point lights in WebGPU. Each light only reaches 2 units, so a pixel only needs the few lights near it. The GUI switches between three renderers:

* Naive: every fragment loops over every light
* Forward+: a compute shader sorts the lights into clusters, and every fragment only loops over the lights of its cluster
* Clustered Deferred: the same clusters, but the scene is drawn into a G-buffer first and then lit once per pixel

### Naive

The naive renderer draws the scene once and every fragment loops over all the lights. I only had to give it the camera: the view-projection matrix goes into a uniform buffer in `camera.ts`, the buffer goes into the bind group in `naive.ts`, and `naive.vs.wgsl` multiplies each vertex by it. It is very slow with many lights, because every pixel checks every light, and pixels that are hidden behind other geometry later check them too.

### Forward+

![clusters](img/clusters.png)

Forward+ cuts the view frustum into a 3D grid of clusters: 32 x 18 tiles on the screen, and 32 slices in depth. A compute shader (`clustering.cs.wgsl`) runs one thread per cluster. The thread builds the cluster's bounding box in view space, tests every light's sphere against the box, and writes the indices of the lights that touch it. In the fragment shader, each fragment finds its cluster from its pixel position and depth, and only loops over that cluster's lights. In the picture above I temporarily made the fragment shader output a color for each cluster index.

The depth slices are spaced in log scale, so the near slices are thin and the far slices are thick. Slice 0 goes from the camera to depth 1, because almost nothing is that close to the camera. The other 31 slices go from 1 to 50 (the whole scene fits in 50), and slice $k$ starts at

$$z_k = 50^{\frac{k-1}{31}}, \quad k = 1, \dots, 31$$

Each cluster can hold 1023 light indices, so the cluster buffer is 32 x 18 x 32 x 1024 x 4 bytes = 75 MB. With 5000 lights the busiest cluster on screen has about 800 lights, so no light gets cut off.

![heat](img/heat.png)

This heat map shows how many lights the cluster of each pixel has with 5000 lights (blue is few, red is 400 or more). The lights only move inside a box in the middle of the atrium (x from -10 to 10). The arches near the camera are inside this box, so they are red, and the end of the hall is outside of it, so it is blue.

### Clustered Deferred

![gbuffer](img/gbuffer.png)

The deferred renderer reuses the same clustering pass. First a G-buffer pass draws the scene and only writes the albedo (`rgba8unorm`), the normal and the world position (`rgba16float`) of the closest surface (above, from left to right). Then a fullscreen pass reads these three textures and does the same cluster lighting as Forward+. This way each pixel is lit exactly once, no matter how many surfaces were drawn on top of each other.

### Credits

- [Vite](https://vitejs.dev/)
- [loaders.gl](https://loaders.gl/)
- [dat.GUI](https://github.com/dataarts/dat.gui)
- [stats.js](https://github.com/mrdoob/stats.js)
- [wgpu-matrix](https://github.com/greggman/wgpu-matrix)
