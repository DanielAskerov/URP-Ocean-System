using UnityEngine;

public class OceanTile
{   
    public int size;                // N
    public int length;              // L
    public float smallWaveFactor;   // Lw
    public float windSpeed;         // V
    public float fetch;             // F
    public float depth;             // D
    public Vector2 windDirection;   // w

    public float waveRangeMin;
    public float waveRangeMax;

    public ComputeShader initialSpectrum;
    public ComputeShader timeDependentSpectrum;
    public ComputeShader generateButterflyTex;
    public ComputeShader fastFourierTransform;
    public ComputeShader mergeTextures;
    public ComputeShader upscaleTexture;

    RenderTexture h0k;
    RenderTexture h0kConj;
    RenderTexture h0kt_x;
    RenderTexture h0kt_y;
    RenderTexture h0kt_z;

    RenderTexture butterflyTex;
    RenderTexture pingPong0;
    RenderTexture pingPong1;

    RenderTexture pdyx;
    RenderTexture pdyz;
    RenderTexture pdxx;
    RenderTexture pdzz;
    RenderTexture pdxz;

    public RenderTexture displacement;
    public RenderTexture derivatives;

    public float t;

    int KERNEL_GENERATE_INITIAL_SPECTRUMS;
    int KERNEL_CALCULATE_CONJUGATE;
    int KERNEL_TIME_DEPENDENT_SPECTRUM;
    int KERNEL_HORIZONTAL_FFT;
    int KERNEL_VERTICAL_FFT;
    int KERNEL_INV_PERM;
    int KERNEL_MERGE_TEXTURES;

    float time;
    bool pingPong;
    int butterflyWidth;

    Texture2D noise;

    int TG_X;
    int TG_Y;
    int TG_Z;

    public OceanTile(int N, Texture2D noiseTex, RenderTexture butterfly,
                      ComputeShader cs1,
                      ComputeShader cs2,
                      ComputeShader cs3,
                      ComputeShader cs4)
    {
        size = N;

        noise = noiseTex;
        butterflyTex = butterfly;

        initialSpectrum = cs1;
        timeDependentSpectrum = cs2;
        fastFourierTransform = cs3;
        mergeTextures = cs4;

        TG_X = size / 16;
        TG_Y = size / 16;
        TG_Z = 1;

        time = 1000f;

        butterflyWidth = (int)Mathf.Log(size, 2);
    }

    public void InitializeTile()
    {
        h0k = CreateRenderTexture(size, size, false, RenderTextureFormat.RGHalf, RenderTextureReadWrite.sRGB, FilterMode.Point);
        h0kConj = CreateRenderTexture(size, size, false, RenderTextureFormat.RGHalf, RenderTextureReadWrite.sRGB, FilterMode.Point);
        h0kt_x = CreateRenderTexture(size, size, false, RenderTextureFormat.RGHalf, RenderTextureReadWrite.sRGB, FilterMode.Point);
        h0kt_y = CreateRenderTexture(size, size, false, RenderTextureFormat.RGHalf, RenderTextureReadWrite.sRGB, FilterMode.Point);
        h0kt_z = CreateRenderTexture(size, size, false, RenderTextureFormat.RGHalf, RenderTextureReadWrite.sRGB, FilterMode.Point);

        pingPong0 = CreateRenderTexture(size, size, false, RenderTextureFormat.RGHalf, RenderTextureReadWrite.sRGB, FilterMode.Point);
        pingPong1 = CreateRenderTexture(size, size, false, RenderTextureFormat.RGHalf, RenderTextureReadWrite.sRGB, FilterMode.Point);

        pdyx = CreateRenderTexture(size, size, false, RenderTextureFormat.RGHalf, RenderTextureReadWrite.sRGB, FilterMode.Point);
        pdyz = CreateRenderTexture(size, size, false, RenderTextureFormat.RGHalf, RenderTextureReadWrite.sRGB, FilterMode.Point);
        pdxx = CreateRenderTexture(size, size, false, RenderTextureFormat.RGHalf, RenderTextureReadWrite.sRGB, FilterMode.Point);
        pdzz = CreateRenderTexture(size, size, false, RenderTextureFormat.RGHalf, RenderTextureReadWrite.sRGB, FilterMode.Point);
        pdxz = CreateRenderTexture(size, size, false, RenderTextureFormat.RGHalf, RenderTextureReadWrite.sRGB, FilterMode.Point);

        displacement = CreateRenderTexture(size, size, true, RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.sRGB, FilterMode.Trilinear);
        derivatives = CreateRenderTexture(size, size, true, RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.sRGB, FilterMode.Bilinear);

        GetKernels();
        SetProperties();
    }

    public void TileInitialSpectrum()
    {
        initialSpectrum.SetInt(N_ID, size);
        initialSpectrum.SetInt(L_ID, length);
        initialSpectrum.SetFloat(Ls_ID, smallWaveFactor);
        initialSpectrum.SetFloat(V_ID, windSpeed);
        initialSpectrum.SetFloat(F_ID, fetch);
        initialSpectrum.SetFloat(D_ID, depth);
        initialSpectrum.SetFloats(w_ID, new float[2] { windDirection.x, windDirection.y });
        initialSpectrum.SetFloat(wrMin_ID, waveRangeMin);
        initialSpectrum.SetFloat(wrMax_ID, waveRangeMax);
        initialSpectrum.Dispatch(KERNEL_GENERATE_INITIAL_SPECTRUMS, TG_X, TG_Y, TG_Z);
        initialSpectrum.Dispatch(KERNEL_CALCULATE_CONJUGATE, TG_X, TG_Y, TG_Z);
    }

    public void UpdateTile()
    {
        // adding to time skips early development of ocean
        time += Time.fixedDeltaTime * t;

        timeDependentSpectrum.SetInt(L_ID, length);
        timeDependentSpectrum.SetFloat(t_ID, time);
        timeDependentSpectrum.SetFloat(D_ID, depth);
        timeDependentSpectrum.Dispatch(KERNEL_TIME_DEPENDENT_SPECTRUM, TG_X, TG_Y, TG_Z);

        FFT(h0kt_x);
        FFT(h0kt_y);
        FFT(h0kt_z);
        FFT(pdyx);
        FFT(pdyz);
        FFT(pdxx);
        FFT(pdzz);
        FFT(pdxz);

        mergeTextures.SetTexture(KERNEL_MERGE_TEXTURES, tex1_ID, h0kt_x);
        mergeTextures.SetTexture(KERNEL_MERGE_TEXTURES, tex2_ID, h0kt_y);
        mergeTextures.SetTexture(KERNEL_MERGE_TEXTURES, tex3_ID, h0kt_z);
        mergeTextures.SetTexture(KERNEL_MERGE_TEXTURES, tex4_ID, pdxz);
        mergeTextures.SetTexture(KERNEL_MERGE_TEXTURES, output_ID, displacement);
        mergeTextures.Dispatch(KERNEL_MERGE_TEXTURES, TG_X, TG_Y, TG_Z);

        mergeTextures.SetTexture(KERNEL_MERGE_TEXTURES, tex1_ID, pdyx);
        mergeTextures.SetTexture(KERNEL_MERGE_TEXTURES, tex2_ID, pdyz);
        mergeTextures.SetTexture(KERNEL_MERGE_TEXTURES, tex3_ID, pdxx);
        mergeTextures.SetTexture(KERNEL_MERGE_TEXTURES, tex4_ID, pdzz);
        mergeTextures.SetTexture(KERNEL_MERGE_TEXTURES, output_ID, derivatives);
        mergeTextures.Dispatch(KERNEL_MERGE_TEXTURES, TG_X, TG_Y, TG_Z);

        derivatives.GenerateMips();
    }

    void SetProperties()
    {
        initialSpectrum.SetTexture(KERNEL_GENERATE_INITIAL_SPECTRUMS, noise_ID, noise);
        initialSpectrum.SetTexture(KERNEL_GENERATE_INITIAL_SPECTRUMS, h0k_ID, h0k);
        initialSpectrum.SetTexture(KERNEL_GENERATE_INITIAL_SPECTRUMS, h0kConj_ID, h0kConj);
        initialSpectrum.SetTexture(KERNEL_CALCULATE_CONJUGATE, h0k_ID, h0k);
        initialSpectrum.SetTexture(KERNEL_CALCULATE_CONJUGATE, h0kConj_ID, h0kConj);


        timeDependentSpectrum.SetInt(N_ID, size);
        timeDependentSpectrum.SetTexture(KERNEL_TIME_DEPENDENT_SPECTRUM, h0k_ID, h0k);
        timeDependentSpectrum.SetTexture(KERNEL_TIME_DEPENDENT_SPECTRUM, h0kConj_ID, h0kConj);
        timeDependentSpectrum.SetTexture(KERNEL_TIME_DEPENDENT_SPECTRUM, h0kt_x_ID, h0kt_x);
        timeDependentSpectrum.SetTexture(KERNEL_TIME_DEPENDENT_SPECTRUM, h0kt_y_ID, h0kt_y);
        timeDependentSpectrum.SetTexture(KERNEL_TIME_DEPENDENT_SPECTRUM, h0kt_z_ID, h0kt_z);
        timeDependentSpectrum.SetTexture(KERNEL_TIME_DEPENDENT_SPECTRUM, pdyx_ID, pdyx);
        timeDependentSpectrum.SetTexture(KERNEL_TIME_DEPENDENT_SPECTRUM, pdyz_ID, pdyz);
        timeDependentSpectrum.SetTexture(KERNEL_TIME_DEPENDENT_SPECTRUM, pdxx_ID, pdxx);
        timeDependentSpectrum.SetTexture(KERNEL_TIME_DEPENDENT_SPECTRUM, pdzz_ID, pdzz);
        timeDependentSpectrum.SetTexture(KERNEL_TIME_DEPENDENT_SPECTRUM, pdxz_ID, pdxz);


        fastFourierTransform.SetTexture(KERNEL_HORIZONTAL_FFT, butterflyTex_ID, butterflyTex);
        fastFourierTransform.SetTexture(KERNEL_VERTICAL_FFT, butterflyTex_ID, butterflyTex);

        fastFourierTransform.SetTexture(KERNEL_INV_PERM, pingPong0_ID, pingPong0);
        fastFourierTransform.SetTexture(KERNEL_INV_PERM, pingPong1_ID, pingPong1);
    }

    void GetKernels()
    {
        KERNEL_GENERATE_INITIAL_SPECTRUMS = initialSpectrum.FindKernel("GenerateInitialSpectrum");
        KERNEL_CALCULATE_CONJUGATE = initialSpectrum.FindKernel("GenerateConjugateSpectrum");
        KERNEL_TIME_DEPENDENT_SPECTRUM = timeDependentSpectrum.FindKernel("CalculateTimeDependentSpectrum");
        KERNEL_INV_PERM = fastFourierTransform.FindKernel("InvPerm");
        KERNEL_HORIZONTAL_FFT = fastFourierTransform.FindKernel("HorizontalFFT");
        KERNEL_VERTICAL_FFT = fastFourierTransform.FindKernel("VerticalFFT");
        KERNEL_MERGE_TEXTURES = mergeTextures.FindKernel("MergeTextures");
    }

    void FFT(RenderTexture rt)
    {
        pingPong = false;

        fastFourierTransform.SetTexture(KERNEL_HORIZONTAL_FFT, pingPong0_ID, rt);
        fastFourierTransform.SetTexture(KERNEL_HORIZONTAL_FFT, pingPong1_ID, pingPong1);
        for (int stage = 0; stage < butterflyWidth; stage++)
        {
            fastFourierTransform.SetBool(pingPong_ID, pingPong);
            fastFourierTransform.SetInt(stage_ID, stage);
            fastFourierTransform.Dispatch(KERNEL_HORIZONTAL_FFT, TG_X, TG_Y, TG_Z);

            pingPong = !pingPong;

            if (stage == 0)
                fastFourierTransform.SetTexture(KERNEL_HORIZONTAL_FFT, pingPong0_ID, pingPong0);
        }

        fastFourierTransform.SetTexture(KERNEL_VERTICAL_FFT, pingPong0_ID, pingPong0);
        fastFourierTransform.SetTexture(KERNEL_VERTICAL_FFT, pingPong1_ID, pingPong1);
        for (int stage = 0; stage < butterflyWidth; stage++)
        {
            fastFourierTransform.SetBool(pingPong_ID, pingPong);
            fastFourierTransform.SetInt(stage_ID, stage);
            fastFourierTransform.Dispatch(KERNEL_VERTICAL_FFT, TG_X, TG_Y, TG_Z);

            pingPong = !pingPong;
        }

        fastFourierTransform.SetBool(pingPong_ID, pingPong);

        fastFourierTransform.SetTexture(KERNEL_INV_PERM, output_ID, rt);
        fastFourierTransform.Dispatch(KERNEL_INV_PERM, TG_X, TG_Y, TG_Z);
    }

    RenderTexture CreateRenderTexture(int w, int h, bool mip, RenderTextureFormat rtf, RenderTextureReadWrite rtrw, FilterMode fm)
    {
        RenderTexture tex = new RenderTexture(w, h, 24, rtf, rtrw);
        tex.useMipMap = mip;
        tex.autoGenerateMips = false;
        tex.wrapMode = TextureWrapMode.Repeat;
        tex.enableRandomWrite = true;
        tex.filterMode = fm;
        if (fm == FilterMode.Point)
            tex.anisoLevel = 9;
        tex.Create();

        return tex;
    }

    static readonly int
        noise_ID = Shader.PropertyToID("noise"),
        h0k_ID = Shader.PropertyToID("h0k"),
        h0kConj_ID = Shader.PropertyToID("h0kConj"),
        h0kt_x_ID = Shader.PropertyToID("h0kt_x"),
        h0kt_y_ID = Shader.PropertyToID("h0kt_y"),
        h0kt_z_ID = Shader.PropertyToID("h0kt_z"),
        pdyx_ID = Shader.PropertyToID("pdyx"),
        pdyz_ID = Shader.PropertyToID("pdyz"),
        pdxx_ID = Shader.PropertyToID("pdxx"),
        pdzz_ID = Shader.PropertyToID("pdzz"),
        pdxz_ID = Shader.PropertyToID("pdxz"),
        butterflyTex_ID = Shader.PropertyToID("butterflyTexture"),
        pingPong0_ID = Shader.PropertyToID("pingPong0"),
        pingPong1_ID = Shader.PropertyToID("pingPong1"),
        output_ID = Shader.PropertyToID("output"),
        tex1_ID = Shader.PropertyToID("tex1"),
        tex2_ID = Shader.PropertyToID("tex2"),
        tex3_ID = Shader.PropertyToID("tex3"),
        tex4_ID = Shader.PropertyToID("tex4"),
        stage_ID = Shader.PropertyToID("stage"),
        pingPong_ID = Shader.PropertyToID("pingPong"),
        N_ID = Shader.PropertyToID("N"),
        L_ID = Shader.PropertyToID("L"),
        Ls_ID = Shader.PropertyToID("Ls"),
        V_ID = Shader.PropertyToID("V"),
        F_ID = Shader.PropertyToID("F"),
        D_ID = Shader.PropertyToID("D"),
        t_ID = Shader.PropertyToID("t"),
        w_ID = Shader.PropertyToID("w"),
        wrMin_ID = Shader.PropertyToID("wrMin"),
        wrMax_ID = Shader.PropertyToID("wrMax");
}
