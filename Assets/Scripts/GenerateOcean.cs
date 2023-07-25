using UnityEngine;

public class GenerateOcean : MonoBehaviour
{
    [Header("Tile Scales")]
    [SerializeField] int L1 = 0;
    [SerializeField] int L2 = 0;

    [Header("Wave Settings")]
    [SerializeField] bool recalculateSpectrum = false;
    [SerializeField] int size = 0;
    [SerializeField] float timeScale = 1;
    [SerializeField] float windSpeed = 0f;
    [SerializeField] float smallWaveFactor = 0f;
    [SerializeField] float fetch1 = 0f;
    [SerializeField] float fetch2 = 0f;
    [SerializeField] float depth1 = 0f;
    [SerializeField] float depth2 = 0f;
    [SerializeField] Vector2 windDirection = Vector2.zero;

    [Header("Compute Shaders")]
    [SerializeField] ComputeShader initialSpectrum;
    [SerializeField] ComputeShader timeDependentSpectrum;
    [SerializeField] ComputeShader generateButterflyTex;
    [SerializeField] ComputeShader fastFourierTransform;
    [SerializeField] ComputeShader mergeTextures;
    [SerializeField] ComputeShader upscaleTexture;

    [Header("Material")]
    public Material water;

    OceanTile OT1;
    OceanTile OT2;

    Texture2D noise;
    RenderTexture butterfly;

    void Awake()
    {
        OceanDisplacementData.FFTSize = size;
        OceanDisplacementData.windDirection = windDirection.normalized;

        PrecomputeTextures.size = size;
        noise = PrecomputeTextures.GenerateGaussianNoiseTexture();
        butterfly = PrecomputeTextures.GenerateButterflyTexture(generateButterflyTex);


        OT1 = new OceanTile(size, noise, butterfly,
                            Instantiate(initialSpectrum),
                            Instantiate(timeDependentSpectrum),
                            Instantiate(fastFourierTransform),
                            Instantiate(mergeTextures));



        OT2 = new OceanTile(size, noise, butterfly,
                            Instantiate(initialSpectrum),
                            Instantiate(timeDependentSpectrum),
                            Instantiate(fastFourierTransform),
                            Instantiate(mergeTextures));

        SetTileParams();

        OT1.InitializeTile();
        OT2.InitializeTile();

        OT1.TileInitialSpectrum();
        OT2.TileInitialSpectrum();

        water.SetTexture("_Displacement_1", OT1.displacement, UnityEngine.Rendering.RenderTextureSubElement.Color);
        water.SetTexture("_Derivatives_1", OT1.derivatives, UnityEngine.Rendering.RenderTextureSubElement.Color);

        water.SetTexture("_Displacement_2", OT2.displacement, UnityEngine.Rendering.RenderTextureSubElement.Color);
        water.SetTexture("_Derivatives_2", OT2.derivatives, UnityEngine.Rendering.RenderTextureSubElement.Color);
    }

    void FixedUpdate()
    {
        if ( recalculateSpectrum )
        {
            SetTileParams();
            OT1.TileInitialSpectrum();
            OT2.TileInitialSpectrum();
        }
        OT1.UpdateTile();
        OT2.UpdateTile();

        OceanDisplacementData.displacementData = OT1.displacement;
    }

    void SetTileParams()
    {
        OT1.length = L1;
        OT1.depth = depth1;
        OT1.fetch = fetch1;
        OT1.t = timeScale;
        OT1.waveRangeMin = 0.0001f;
        OT1.waveRangeMax = 2f * Mathf.PI / L1 * 10f;

        OT1.smallWaveFactor = smallWaveFactor;
        OT1.windSpeed = windSpeed;
        OT1.windDirection = windDirection;

        OT2.length = L2;
        OT2.depth = depth2;
        OT2.fetch = fetch2;
        OT2.t = timeScale;
        OT2.waveRangeMin = 2f * Mathf.PI / L2 * 10f;
        OT2.waveRangeMax = 999f;

        OT2.smallWaveFactor = smallWaveFactor;
        OT2.windSpeed = windSpeed;
        OT2.windDirection = windDirection;

        OceanDisplacementData.windDirection = windDirection.normalized;
    }
}
