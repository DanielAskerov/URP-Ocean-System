// Using URP PBR template by @Cyanilux
// https://www.cyanilux.com/tutorials/urp-shader-code

Shader "PBROceanWater" {

	Properties {
		[MainTexture][NoScaleOffset] _BaseMap("Main Texture", 2D) = "white" {}
		[MainColor] _BaseColor("Color", Color) = (1, 1, 1, 1)

		[Space(20)]
		[Toggle(_SPECULAR_SETUP)] _MetallicSpecToggle ("ON: Specular | OFF: Metallic", int) = 0
		_Metallic("Metallic", Range(0.0, 1.0)) = 0
		_Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
		_SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 0.5)
		[Toggle(_METALLICSPECGLOSSMAP)] _MetallicSpecGlossMapToggle ("Metallic/Specular Gloss Map Toggle", int) = 0
		[NoScaleOffset] _MetallicSpecGlossMap("Metallic/Specular Gloss Map", 2D) = "black" {}

		[Space(20)]
		[Toggle(_NORMALMAP)] _NormalMapToggle ("Use Normal Map", Float) = 0
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1
        _NormalStrength("Normal strength", Range(0, 10)) = 1

		[Space(20)]
		[Toggle(_OCCLUSIONMAP)] _OcclusionToggle ("Use Occlusion Map", Float) = 0
		[NoScaleOffset] _OcclusionMap("Occlusion Map", 2D) = "bump" {}
		_OcclusionStrength("Occlusion Strength", Range(0.0, 1.0)) = 1.0

		[Space(20)]
		[Toggle(_EMISSION)] _Emission ("Emission", Float) = 0
		[HDR] _EmissionColor("Emission Color", Color) = (0,0,0)
		[NoScaleOffset]_EmissionMap("Emission Map", 2D) = "black" {}

		[Space(20)]
		[Toggle(_SPECULARHIGHLIGHTS_OFF)] _SpecularHighlights("Specular Highlights Toggle", int) = 0
		[Toggle(_ENVIRONMENTREFLECTIONS_OFF)] _EnvironmentalReflections("Environmental Reflections Toggle", int) = 0
		[Toggle(_RECEIVE_SHADOWS_OFF)] _ReceiveShadows("Receive Shadows", int) = 0

		[Space(20)]
        [NoScaleOffset] _Displacement_1("Displacement 1", 2D) = "white" {}
        [NoScaleOffset] _Displacement_2("Displacement 2", 2D) = "white" {}

        [NoScaleOffset] _Derivatives_1("Derivatives 1", 2D) = "white" {}
        [NoScaleOffset] _Derivatives_2("Derivatives 2", 2D) = "white" {}

		[Space(20)]
		_SeaFoam("Sea foam", 2D) = "white" {}
		[NoScaleOffset] _SeaFoamNormalMap("Sea foam Normal Map", 2D) = "bump" {}
		[NoScaleOffset] _SeaFoamRoughnessMap("Sea foam Roughness Map", 2D) = "black" {}
		[NoScaleOffset] _SeaFoamThreshold("Sea Foam Threshold", Range(0, 1)) = 0.5
		[NoScaleOffset] _SeaFoamStrength("Sea foam strength", Range(0, 100)) = 1

		[Space(20)]
        [NoScaleOffset] _ClearCoatMask("Clear coat mask", 2D) = "white" {}
        _ClearCoatStrength("Clear coat strength", Range(0, 1)) = 0
        [NoScaleOffset] _ClearCoatSmoothnessMask("Clear coat smoothness mask", 2D) = "white" {}
        _ClearCoatSmoothness("Clear coat smoothness", Range(0, 1)) = 0

		[Space(20)]
		_DisplacementScale("Displacement scale", float) = 1
		_DisplacementFog("Displacement fog", range(0,100)) = 1
		_FogColor("Fog color", Color) = (1,1,1)
		_FogScale("Fog Scale", float) = 1
		_DetailFogScale("Detail fog scale", float) = 0

		[Space(20)]
		[HDR] _SSSColor ("Subsurface Scattering Color", Color) = (0,0,0)
		_SSSDistortion("Subsurface scattering distortion", float) = 1
		_SSSPower("Subsurface scattering power", float) = 1
		_SSSScale("Subsurface scattering scale", float) = 1
		_SSSAttenuation("Subsurface scattering Attenuation", float) = 1
		_SSSAmbient("Subsurface scattering ambient", float) = 1

		[Space(20)]
		_WaterFogColor ("Underwater Fog Color", Color) = (0, 0, 0)
		_WaterFogDensity ("Water Fog Density", float) = 0
		_EdgeFoamFactor ("Edge Foam Factor", float) = 0
		_EdgeFoamStrength ("Edge Foam Strength", float) = 0
		_EdgeOutlineThickness ("Edge Outline Thickness", float) = 0
		_EdgeOutlineStrength ("Edge Outline Strength", float) = 0
		_RefractionStrength ("Refraction Strength", float) = 0
		_Translucency ("Translucency", float) = 0
	}
	SubShader {
		Tags {
			"RenderPipeline"="UniversalPipeline"
			"RenderType"="Transparent"
			"Queue"="Transparent"
			"DisableBatching"="False"
		}

		HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

		CBUFFER_START(UnityPerMaterial)
		float4 _BaseMap_ST;
		float4 _BumpMap_ST;
		float4 _BaseColor;
		float4 _EmissionColor;
		float4 _SpecColor;
		float _Metallic;
		float _Smoothness;
		float _OcclusionStrength;
		float _Cutoff;
		float _BumpScale;
		float _NormalStrength;
		float _ClearCoatStrength;
		float _ClearCoatSmoothness;
		float _DisplacementScale;
		float _DisplacementFog;
		float4 _FogColor;
		float _FogScale;
		float _DetailFogScale;
		float4 _SSSColor;
		float _SSSDistortion;
		float _SSSPower;
		float _SSSScale;
		float _SSSAttenuation;
		float _SSSAmbient;
		float _SeaFoamThreshold;
		float4 _WaterFogColor;
		float _WaterFogDensity;
		float _EdgeFoamFactor;
		float _EdgeFoamStrength;
		float _EdgeOutlineThickness;
		float _EdgeOutlineStrength;
		float4 _SeaFoam_ST;
		float _SeaFoamStrength;
		float _RefractionStrength;
		float _Translucency;
		

		float4 _CameraDepthTexture_TexelSize;
		CBUFFER_END
		ENDHLSL

		Pass {
			Name "ForwardLit"
			Tags { "LightMode"="UniversalForward" }
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
			cull Back

			HLSLPROGRAM
			#pragma vertex LitPassVertex
			#pragma fragment LitPassFragment

            #define _CLEARCOATMAP

			#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			#pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
			#pragma shader_feature_local_fragment _EMISSION
			#pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
			#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature_local_fragment _OCCLUSIONMAP

			#pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
			#pragma shader_feature_local_fragment _SPECULAR_SETUP
			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF

			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN

			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile_fragment _ _SHADOWS_SOFT
			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION // v10+ only (for SSAO support)
			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING // v10+ only, renamed from "_MIXED_LIGHTING_SUBTRACTIVE"
			#pragma multi_compile _ SHADOWS_SHADOWMASK // v10+ only

			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile_fog

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			struct Attributes {
				float4 positionOS	: POSITION;
				#ifdef _NORMALMAP
					float4 tangentOS 	: TANGENT;
				#endif
				float4 normalOS		: NORMAL;
				float2 uv		    : TEXCOORD0;
				float2 lightmapUV	: TEXCOORD1;
				float4 color		: COLOR;
			};

			struct Varyings {
				float4 positionCS 					: SV_POSITION;
				float2 uv		    				: TEXCOORD0;
				DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
				float3 positionWS					: TEXCOORD2;

				half4 normalWS					: TEXCOORD3;    // xyz: normal, w: viewDir.x
				half4 tangentWS					: TEXCOORD4;    // xyz: tangent, w: viewDir.y
				half4 bitangentWS				: TEXCOORD5;    // xyz: bitangent, w: viewDir.z
				
				#ifdef _ADDITIONAL_LIGHTS_VERTEX
					half4 fogFactorAndVertexLight	: TEXCOORD6; // x: fogFactor, yzw: vertex light
				#else
					half  fogFactor					: TEXCOORD6;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					float4 shadowCoord 				: TEXCOORD7;
				#endif
					float4 screenPos				: TEXCOORD8;
				half3 viewDir						: TEXCOORD9;
				float4 color						: COLOR;
			};

			#include "PBROceanWaterUtility.hlsl"

			Varyings LitPassVertex(Attributes IN) {
				Varyings OUT;
				
				float normalizedDistInv = 1 - saturate( ( 1 / _ProjectionParams.z * _DisplacementFog ) * length( GetWorldSpaceViewDir(  mul( unity_ObjectToWorld, IN.positionOS ) ) ) );

				float3 displacement = _Displacement_1.SampleLevel(sampler_Displacement_1, IN.uv.xy, 0).rgb + 
									  _Displacement_2.SampleLevel(sampler_Displacement_2, IN.uv.xy, 0).rgb;
				displacement.xz *= _DisplacementScale;
				IN.positionOS.xyz += mul( unity_ObjectToWorld, float4(displacement, 1.0)).xyz * normalizedDistInv;

				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);

				#ifdef _NORMALMAP
					VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS.xyz, IN.tangentOS);
				#else
					VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS.xyz);
				#endif
				
				OUT.positionCS = positionInputs.positionCS;
				OUT.positionWS = positionInputs.positionWS;
				OUT.screenPos  = ComputeScreenPos(OUT.positionCS);

				half3 viewDirWS = GetWorldSpaceViewDir(positionInputs.positionWS);
				half3 vertexLight = VertexLighting(positionInputs.positionWS, normalInputs.normalWS);
				half fogFactor = ComputeFogFactor(positionInputs.positionCS.z);
				
				OUT.normalWS = half4(normalInputs.normalWS, viewDirWS.x);
				OUT.tangentWS = half4(normalInputs.tangentWS, viewDirWS.y);
				OUT.bitangentWS = half4(normalInputs.bitangentWS, viewDirWS.z);

				OUTPUT_LIGHTMAP_UV(IN.lightmapUV, unity_LightmapST, OUT.lightmapUV);
				OUTPUT_SH(OUT.normalWS.xyz, OUT.vertexSH);

				#ifdef _ADDITIONAL_LIGHTS_VERTEX
					OUT.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
				#else
					OUT.fogFactor = fogFactor;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					OUT.shadowCoord = GetShadowCoord(positionInputs);
				#endif

				OUT.viewDir = viewDirWS;
				OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
				OUT.color = IN.color;
				return OUT;
			}
			
			half4 LitPassFragment(Varyings IN) : SV_Target {

				float viewDist = length( IN.viewDir );
				float normalizedDistInv = 1 - saturate( ( 1 / _ProjectionParams.z * _DetailFogScale ) * viewDist );
				float normalizedDist = saturate( ( 1 / _ProjectionParams.z * _FogScale ) * viewDist );

				// r: yx g: yz b: xx a: zz
				float4 derivative = _Derivatives_1.Sample(sampler_Derivatives_1, IN.uv.xy).rgba + 
									_Derivatives_2.Sample(sampler_Derivatives_1, IN.uv.xy).rgba;
				float2 slope = float2( derivative.r / ( _DisplacementScale * derivative.b + 1.0 ), derivative.g / ( _DisplacementScale * derivative.a + 1.0) );
				float3 normal = normalize( float3( -slope.x, 1.0, -slope.y ) ) * _NormalStrength;
				IN.normalWS.xyz = normal * normalizedDistInv;

				float3 tangent = cross( normal, float3(1,0,0) );
				if ( length(tangent) == 0)
					tangent = cross( normal, float3(0,1,0) );

				// last partial derivative & Y-axis displacement for other features
				float2 pdxz_y = _Displacement_1.Sample(sampler_Displacement_1, IN.uv.xy).ag + _Displacement_2.Sample(sampler_Displacement_2, IN.uv.xy).ag;

				float3 roughness = 0;
				float3 emissivity = 0;

				// jacobian determinant
				float jacobian = ( ( _DisplacementScale * derivative.b + 1.0 ) * ( _DisplacementScale * derivative.a + 1.0 ) ) - ( _DisplacementScale * pdxz_y.x  * _DisplacementScale * pdxz_y.x );

				// sea foam
				float2 seaFoamUV = TRANSFORM_TEX(IN.uv.xy, _SeaFoam);
				float3 seaFoamColor     =		      _SeaFoam.Sample(sampler_SeaFoam, seaFoamUV);
				//float4 seaFoamNormal    =	 _SeaFoamNormalMap.Sample(sampler_SeaFoam, seaFoamUV);
				float3 seaFoamRoughness = _SeaFoamRoughnessMap.Sample(sampler_SeaFoam, seaFoamUV);

				float3 seaFoamNormalTS = SampleNormal(seaFoamUV, TEXTURE2D_ARGS(_SeaFoamNormalMap, sampler_SeaFoam), _BumpScale);
				half3 viewDirWS = half3(IN.normalWS.w, IN.tangentWS.w, IN.bitangentWS.w); // viewDir has been stored in w components of these in vertex shader
				float3 seaFoamNormalWS = TransformTangentToWorld(seaFoamNormalTS, half3x3(IN.tangentWS.xyz, IN.bitangentWS.xyz, IN.normalWS.xyz));

				IN.color.rgb    += saturate(_SeaFoamThreshold - jacobian) * seaFoamColor    * _SeaFoamStrength* _SeaFoamStrength * normalizedDistInv;
				IN.normalWS.rgb += saturate(_SeaFoamThreshold - jacobian) * seaFoamNormalWS * _SeaFoamStrength* _SeaFoamStrength;
				//roughness	 += jacobian < _SeaFoamThreshold ? lerp( seaFoamRoughness * _SeaFoamStrength, 0, saturate( jacobian ) ) * _SeaFoamStrength : 0;
				
				// subsurface scattering approximation; utilizing Y displacement as a "thickness" map
				half3 SSSlight = normalize( GetMainLight().direction.xyz + normal * _SSSDistortion );
				half  SSSDot = pow( saturate ( dot( GetWorldSpaceViewDir(IN.positionWS), -SSSlight ) ), _SSSPower ) * _SSSScale;
				emissivity += saturate( _SSSAttenuation * ( SSSDot * _SSSAmbient ) * pdxz_y.y ) * _SSSColor;

				// water depth & translucency
				float2 uvOffset = tangent.xy * _RefractionStrength * float2( 0, _CameraDepthTexture_TexelSize.z * abs( _CameraDepthTexture_TexelSize.y ) );
				float2 uvScreen = ( IN.screenPos.xy + uvOffset ) / IN.screenPos.w;
				#if UNITY_UV_STARTS_AT_TOP
					if (_CameraDepthTexture_TexelSize.y < 0) {
						uvScreen.y = 1 - uvScreen.y;
					}
				#endif
				uvScreen = ( floor( uvScreen * _CameraDepthTexture_TexelSize.zw ) + 0.5 ) * abs( _CameraDepthTexture_TexelSize.xy );
				float  backDepth = 1.0 / ( _ZBufferParams.z * SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, sampler_CameraDepthTexture, uvScreen ) + _ZBufferParams.w );
				float  surfDepth = UNITY_Z_0_FAR_FROM_CLIPSPACE( IN.screenPos.z );
				float  depthDiff = backDepth - surfDepth;
				
				uvOffset *= saturate( depthDiff );
				uvScreen = ( IN.screenPos.xy + uvOffset ) / IN.screenPos.w;
				#if UNITY_UV_STARTS_AT_TOP
					if (_CameraDepthTexture_TexelSize.y < 0) {
						uvScreen.y = 1 - uvScreen.y;
					}
				#endif
				uvScreen = ( floor( uvScreen * _CameraDepthTexture_TexelSize.zw ) + 0.5 ) * abs( _CameraDepthTexture_TexelSize.xy );
				backDepth = 1.0 / ( _ZBufferParams.z * SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, sampler_CameraDepthTexture, uvScreen ) + _ZBufferParams.w );
				depthDiff = backDepth - surfDepth;

				float3 backColor = _CameraOpaqueTexture.Sample( sampler_CameraOpaqueTexture, uvScreen ).rgb ;
				float  fogFactor = exp2( -_WaterFogDensity * depthDiff );
				IN.color.rgb *= lerp( _WaterFogColor, backColor, fogFactor ) * _Translucency;

				// color at shallow depth
				IN.color.rgb += fogFactor * _BaseColor * _Translucency;

				//IN.color.rgb += lerp( _EdgeOutlineThickness, seaFoamColor, fogFactor) * _EdgeOutlineStrength;
				//IN.color.rgb += fogFactor * _EdgeOutlineThickness * seaFoamColor + _EdgeOutlineThickness;

				// FOAM WIP

				SurfaceData surfaceData;
				InitializeSurfaceData(IN, surfaceData, TRANSFORM_TEX(IN.uv, _BumpMap));

				surfaceData.clearCoatMask = SAMPLE_TEXTURE2D(_ClearCoatMask, sampler_ClearCoatMask, IN.uv.xy).r * _ClearCoatStrength ;
				surfaceData.clearCoatSmoothness = SAMPLE_TEXTURE2D(_ClearCoatSmoothnessMask, sampler_ClearCoatSmoothnessMask, IN.uv.xy).r * _ClearCoatSmoothness * normalizedDistInv;
				surfaceData.emission += emissivity;



				// WIP
				//#if _SPECULAR_SETUP
				//	surfaceData.specular = 0;
				//#else
				//	surfaceData.metallic += 0 ;
				//#endif
				//surfaceData.smoothness += saturate( 1 - roughness);

				InputData inputData;
				InitializeInputData(IN, surfaceData.normalTS, inputData);
				half4 color = UniversalFragmentPBR(inputData, surfaceData);

				// FOG
				color.rgb += _FogColor * normalizedDist * normalizedDist;

				color.a = 1;

				color.rgb = MixFog(color.rgb, inputData.fogCoord);
				return color;
			}
			ENDHLSL
		}

		Pass {
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual

			HLSLPROGRAM

			#pragma fragment ShadowPassFragment

			#pragma shader_feature_local_fragment _ALPHATEST_ON
			#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			#pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"

			#pragma vertex DisplacedShadowPassVertex

			TEXTURE2D(_Displacement_1);		SamplerState sampler_Displacement_1;
			TEXTURE2D(_Displacement_2);		SamplerState sampler_Displacement_2;
			
			Varyings DisplacedShadowPassVertex(Attributes input) {
				Varyings output = (Varyings)0;

				float3 displacement = _Displacement_1.SampleLevel(sampler_Displacement_1, input.texcoord.xy, 0).rgb + 
									  _Displacement_2.SampleLevel(sampler_Displacement_2, input.texcoord.xy, 0).rgb;
				input.positionOS.xyz +=  mul( unity_WorldToObject, displacement );
				
				output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
				output.positionCS = GetShadowPositionHClip(input);
				return output;
			}

			ENDHLSL
		}

		Pass {
			Name "DepthNormals"
			Tags { "LightMode"="DepthNormals" }

			ZWrite Off
			ZTest LEqual

			HLSLPROGRAM
			#pragma vertex DepthNormalsVertex
			#pragma fragment DepthNormalsFragment

			#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"

			#pragma vertex DisplacedDepthNormalsVertex
			TEXTURE2D(_Displacement_1);		SamplerState sampler_Displacement_1;
			TEXTURE2D(_Displacement_2);		SamplerState sampler_Displacement_2;

			Varyings DisplacedDepthNormalsVertex(Attributes input) {
				Varyings output = (Varyings)0;

				float3 displacement = _Displacement_1.SampleLevel(sampler_Displacement_1, input.texcoord.xy, 0).rgb + 
									  _Displacement_2.SampleLevel(sampler_Displacement_2, input.texcoord.xy, 0).rgb;
				input.positionOS.xyz +=  mul( unity_WorldToObject, displacement );
				
				output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
				output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
				VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal, input.tangentOS);
				output.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);
				return output;
			}
			
			ENDHLSL
		}

		Pass {
			Name "Meta"
			Tags{"LightMode" = "Meta"}

			Cull Off

			HLSLPROGRAM
			#pragma vertex UniversalVertexMeta
			#pragma fragment UniversalFragmentMeta

			#pragma shader_feature_local_fragment _SPECULAR_SETUP
			#pragma shader_feature_local_fragment _EMISSION
			#pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			#pragma shader_feature_local_fragment _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			#pragma shader_feature_local_fragment _SPECGLOSSMAP

			struct Attributes {
				float4 positionOS   : POSITION;
				float3 normalOS     : NORMAL;
				float2 uv0          : TEXCOORD0;
				float2 uv1          : TEXCOORD1;
				float2 uv2          : TEXCOORD2;
				#ifdef _TANGENT_TO_WORLD
					float4 tangentOS     : TANGENT;
				#endif
				float4 color		: COLOR;
			};

			struct Varyings {
				float4 positionCS   : SV_POSITION;
				float2 uv           : TEXCOORD0;
				float4 color		: COLOR;
			};

			#include "PBROceanWaterUtility.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

			Varyings UniversalVertexMeta(Attributes input) {
				Varyings output;

				output.positionCS = MetaVertexPosition(input.positionOS, input.uv1, input.uv2, unity_LightmapST, unity_DynamicLightmapST);
				output.uv = TRANSFORM_TEX(input.uv0, _BaseMap);
				output.color = input.color;
				return output;
			}

			half4 UniversalFragmentMeta(Varyings input) : SV_Target {
				SurfaceData surfaceData;
				InitializeSurfaceData(input, surfaceData);

				BRDFData brdfData;
				InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);

				MetaInput metaInput;
				metaInput.Albedo = brdfData.diffuse + brdfData.specular * brdfData.roughness * 0.5;
				metaInput.SpecularColor = surfaceData.specular;
				metaInput.Emission = surfaceData.emission;

				return MetaFragment(metaInput);
			}

			ENDHLSL
		}
	}
}
