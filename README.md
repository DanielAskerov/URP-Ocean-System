# Unity URP FFT Ocean

FFT Ocean simulation system built with Unity URP. 

Every frame, wave spectrum textures containing all relevant wave information is generated. These textures are transformed from the frequency domain to the spatial domain using the Cooley-Tukey FFT algorithm. Resulting textures include a displacement and  normal map. These textures are applied to a grid of tiles ultimately generating a seamless tileable ocean.

![FFT_Water_Thumbnail](https://github.com/DanielAskerov/URP-Ocean-System/assets/140186597/daf6d4ff-0b1c-4fb6-b46d-c43c34ee68ea)

## Features

* Simple buoyancy
* Subsurface scattering approximation
* Refraction
* Caustics
* Custom surface fog
* Underwater fog
* Foam & whitecaps
* LOD & static batching


## Motivations

I began this project with the simple goal of producing stunning water in real-time. In my research, I had discovered Tessendorf's approach to wave simulation using the Fast Fourier transform. After reading the relevant literature, I realized this would be a perfect learning opportunity for a number of core technical art skills. 

The system was initially meant to be built with HDRP, for which there is unfortunately no substantial shader documentation outside of Shader Graph. Seeing as I was dead-set on writing the water shader with HLSL for more control, I tried URP instead. URP shaders had no official documentation either, but there was an adequate amount of resources provided by developers in the community, namely [Cyanilux](https://www.cyanilux.com/). While I couldn't get the visual fidelity I wanted out of the box from HDRP, I did have to work a little harder for my goals which ultimately provided more learning opportunities for myself.
## Challenges

The visual fidelity of the normals is entirely dependent on the resolution of the fourier grid, which gets **very** expensive at 2048x2048. I've attempted a rough real-time upscaling of normals which gave me strange results with several upscaling algorithms. I instead used a high resolution perlin noise texture to dither the water. This sharpened the important details of the water, while giving an interesting texture to the water that isn't exactly realistic, but I personally found charming.

One of the challenges of an effective ocean solution is to have believable shoreline interactions. While there is a number of decent methods to get passable waves along the shore, I've personally never been satisfied with them. I've tried one approach involving baking depth related information to a texture relative to world space. By having the ocean shader read a pixel in this texture corresponding to its location, it could behave a certain way to mimic a wave crashing against the shore. I put a halt to exploring that idea after discovering a [method](https://matthias-research.github.io/pages/publications/SPHShallow.pdf) that combines FFT water in deep waters with a particle based fluid simulation at shallow waters. The implementations that I've seen in regards to performance were exactly what I was looking for; I'll continue with this at a later time when I can stop to learn fluid dynamics.
## References

### FFT Ocean Theory & Implementation

* [Jerry Tessendorf - Simulating Ocean Water](https://people.computing.clemson.edu/~jtessen/reports/papers_files/coursenotes2004.pdf)
* [Fynn-Jorin FlÃ¼gge - Realtime GPGPU FFT Ocean Water Simulation](https://tore.tuhh.de/entities/publication/1cd390d3-732b-41c1-aa2b-07b71a64edd2/publicationdetails)
* [Thomas Gamper - Ocean Surface Generation and Rendering](https://www.cg.tuwien.ac.at/research/publications/2018/GAMPER-2018-OSG/)
* [Christopher J. Horvath - Empirical Directional Wave Spectra For Computer Graphics](https://dl.acm.org/doi/10.1145/2791261.2791267)
* [Jacob Eriksson & Joakim WingÃ¥rd, Improving the Accuracy of FFT-based GPGPU Ocean Surface Simulations](https://gupea.ub.gu.se/handle/2077/74347)
* [Tim Tcheblokov @ CGDC 2015 - Ocean Simulation and Rendering in War Thunder ](https://developer.download.nvidia.com/assets/gameworks/downloads/regular/events/cgdc15/CGDC2015_ocean_simulation_en.pdf)

### URP Shaders & Features

* [Cyanilux - Writing Shader Code in Universal RP (v2)](https://www.cyanilux.com/tutorials/urp-shader-code/)
* [Cyanilux - Depth](https://www.cyanilux.com/tutorials/depth/)
* [Colin Barre-Brisebois @ GDC 2011 - Approximating Translucency for a Fast, Cheap and Convincing Subsurface Scattering Look](https://www.gdcvault.com/play/1014538/Approximating-Translucency-for-a-Fast)
* [Catlike Coding - Looking Through Water, Underwater Fog and Refraction](https://catlikecoding.com/unity/tutorials/flow/looking-through-water/)
* [Alexander Ameye - Rendering realtime caustics](https://ameye.dev/notes/realtime-caustics/)
