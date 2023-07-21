using System;
using System.Collections.Generic;
using UnityEngine;

public class PrecomputeTextures
{
    static public int size = 256;

    static int mean = 0;
    static int stdDev = 1;

    static double spare;
    static bool hasSpare = false;

    static public Texture2D GenerateGaussianNoiseTexture()
    {
        Texture2D texture = new Texture2D(size, size, TextureFormat.RGFloat, false, true);

        var rand = new System.Random();

        for (int y = 0; y < size; y++)
        {
            for (int x = 0; x < size; x++)
            {
                float r = (float)CalculateGaussian(mean, stdDev, rand);
                float i = (float)spare;
                hasSpare = false;
                Color pixColor = new Color(r, i, 0, 1);
                texture.SetPixel(x, y, pixColor);
            }
        }
        texture.Apply();

        return texture;
    }

    static double CalculateGaussian(double mean, double stdev, System.Random rand)
    {
        if (hasSpare)
        {
            hasSpare = false;
            return spare * stdev + mean;
        }
        else
        {
            double u, v, s;
            do
            {
                u = rand.NextDouble() * 2.0 - 1.0;
                v = rand.NextDouble() * 2.0 - 1.0;
                s = u * u + v * v;
            } while (s >= 1 || s == 0);
            s = Math.Sqrt(-2 * Math.Log(s) / s);
            spare = mean + stdev * v * s;
            hasSpare = true;
            return mean + stdev * u * s;
        }
    }

    static public RenderTexture GenerateButterflyTexture(ComputeShader cs)
    {
        int w = (int)Mathf.Log(size, 2);
        RenderTexture butterflyTexture = new RenderTexture(w, size, 32, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
        butterflyTexture.enableRandomWrite = true;
        butterflyTexture.filterMode = FilterMode.Point;
        butterflyTexture.Create();

        List<int> br_indices = new List<int>();
        br_indices = BitReversal(br_indices);
        int[] br_indices_arr = br_indices.ToArray();

        ComputeBuffer indicesBuffer = new ComputeBuffer(size, sizeof(int));
        indicesBuffer.SetData(br_indices_arr);

        int k = cs.FindKernel("GenerateButterflyTexture");
        cs.SetInt(Shader.PropertyToID("N"), size);
        cs.SetTexture(k, Shader.PropertyToID("butterflyTexture"), butterflyTexture);
        cs.SetBuffer(k, Shader.PropertyToID("bit_reversed"), indicesBuffer);
        cs.Dispatch(k, w, size/16, size/16);

        br_indices = null;
        indicesBuffer.Release();
        indicesBuffer = null;

        return butterflyTexture;
    }

    static List<int> BitReversal(List<int> a)
    {
        int l = a.Count;
        if (l == size)
        {
            return a;
        }
        else if (a.Count == 0)
        {
            a.Add(0);
            return BitReversal(a);
        }
        else
        {
            for (int i = 0; i < l; i++)
            {
                a.Add(a[i] * 2 + 1);
                a[i] *= 2;
            }
            return BitReversal(a);
        }
    }
}
