#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

TEXTURE2D(_MetallicSpecGlossMap); 	SAMPLER(sampler_MetallicSpecGlossMap);
TEXTURE2D(_OcclusionMap); 			SAMPLER(sampler_OcclusionMap);
TEXTURE2D(_Displacement_1);			SAMPLER(sampler_Displacement_1);
TEXTURE2D(_Displacement_2);			SAMPLER(sampler_Displacement_2);
TEXTURE2D(_Derivatives_1);			SAMPLER(sampler_Derivatives_1);
TEXTURE2D(_Derivatives_2);			
TEXTURE2D(_ClearCoatMask);			SAMPLER(sampler_ClearCoatMask);
TEXTURE2D(_ClearCoatSmoothnessMask);SAMPLER(sampler_ClearCoatSmoothnessMask);
TEXTURE2D(_SeaFoam);				SAMPLER(sampler_SeaFoam);
TEXTURE2D(_SeaFoamNormalMap);
TEXTURE2D(_SeaFoamRoughnessMap);
TEXTURE2D(_CameraDepthTexture);		SAMPLER(sampler_CameraDepthTexture);
TEXTURE2D(_CameraOpaqueTexture);	SAMPLER(sampler_CameraOpaqueTexture);

half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha) {
	half4 specGloss;
	#ifdef _METALLICSPECGLOSSMAP
		specGloss = SAMPLE_TEXTURE2D(_MetallicSpecGlossMap, sampler_MetallicSpecGlossMap, uv);
		specGloss.a *= _Smoothness;

	#else // _METALLICSPECGLOSSMAP
		#if _SPECULAR_SETUP
			specGloss.rgb = _SpecColor.rgb;
		#else
			specGloss.rgb = _Metallic.rrr;
		#endif

		#ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			specGloss.a = albedoAlpha * _Smoothness;
		#else
			specGloss.a = _Smoothness;
		#endif
	#endif
	return specGloss;
}

half SampleOcclusion(float2 uv) {
	#ifdef _OCCLUSIONMAP
	#if defined(SHADER_API_GLES)
		return SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
	#else
		half occ = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
		return LerpWhiteTo(occ, _OcclusionStrength);
	#endif
	#else
		return 1.0;
	#endif
}

// ---------------------------------------------------------------------------
// SurfaceData
// ---------------------------------------------------------------------------

void InitializeSurfaceData(Varyings IN, out SurfaceData surfaceData){
	surfaceData = (SurfaceData)0; // avoids "not completely initalized" errors

	half4 albedoAlpha = SampleAlbedoAlpha(IN.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
	surfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);
	surfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb * IN.color.rgb;

	surfaceData.normalTS = SampleNormal(IN.uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
	surfaceData.emission = SampleEmission(IN.uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));
	surfaceData.occlusion = SampleOcclusion(IN.uv);
	
	half4 specGloss = SampleMetallicSpecGloss(IN.uv, albedoAlpha.a);
	#if _SPECULAR_SETUP
		surfaceData.metallic = 1.0h;
		surfaceData.specular = specGloss.rgb;
	#else
		surfaceData.metallic = specGloss.r;
		surfaceData.specular = half3(0.0h, 0.0h, 0.0h);
	#endif
	surfaceData.smoothness = specGloss.a;
}

void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData) {
	inputData = (InputData)0; // avoids "not completely initalized" errors

	inputData.positionWS = input.positionWS;

	#ifdef _NORMALMAP
		half3 viewDirWS = half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w); // viewDir has been stored in w components of these in vertex shader
		inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
	#else
		half3 viewDirWS = GetWorldSpaceNormalizeViewDir(inputData.positionWS);
		inputData.normalWS = input.normalWS;
	#endif

	inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);

	viewDirWS = SafeNormalize(viewDirWS);
	inputData.viewDirectionWS = viewDirWS;

	#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
		inputData.shadowCoord = input.shadowCoord;
	#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
		inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
	#else
		inputData.shadowCoord = float4(0, 0, 0, 0);
	#endif

	// Fog
	//#ifdef _ADDITIONAL_LIGHTS_VERTEX
	//	inputData.fogCoord = input.fogFactorAndVertexLight.x;
	//	inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
	//#else
	//	inputData.fogCoord = input.fogFactor;
	//	inputData.vertexLighting = half3(0, 0, 0);
	//#endif

	/* in v11/v12?, could use :
	#ifdef _ADDITIONAL_LIGHTS_VERTEX
		inputData.fogCoord = InitializeInputDataFog(float4(inputData.positionWS, 1.0), input.fogFactorAndVertexLight.x);
		inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
	#else
		inputData.fogCoord = InitializeInputDataFog(float4(inputData.positionWS, 1.0), input.fogFactor);
		inputData.vertexLighting = half3(0, 0, 0);
	#endif
	*/

	inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
	inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
	inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
}