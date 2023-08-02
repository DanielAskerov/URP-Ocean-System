Shader "WaterCaustics" {
	Properties {
		[HDR] _Color ("HDR Color", Color) = (1,1,1,1)
		_CausticsTex ("Caustics Texture", 2D) = "white" {}
		_VoronoiTex ("Voronoi Noise Texture", 2D) = "white" {}
		_VoronoiStrength ("Voronoi Strength", float) = 1
		_ShadowThreshold ("Shadow Threshold", float) = 0
		_CausticsSpeed ("Caustics Speed", float) = 1
		_CausticsThreshold ("Caustics Threshold", float) = 1
		_Strength("Strength", float) = 1

		[Space(20)]
		_Direction_a ("Caustics A Direction", Range(0,360)) = 0
		_Direction_b ("Caustics B Direction", Range(0,360)) = 0
		_Direction_n ("Voronoi Noise Direction", Range(0,360)) = 0
	}
	SubShader {
		Tags {
			"RenderPipeline"="UniversalPipeline"
			"RenderType"="Transparent"
			"Queue"="Transparent"
			//"RenderType"="Opaque"
			//"Queue"="Geometry"
		}

		HLSLINCLUDE

		#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
		#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

		CBUFFER_START(UnityPerMaterial)
		float4 _Color;
		float4 _CausticsTex_ST;
		float4 _VoronoiTex_ST;
		float _VoronoiStrength;
		float _ShadowThreshold;
		float _CausticsSpeed;
		float _CausticsThreshold;
		float _Strength;
		float _Direction_a;
		float _Direction_b;
		float _Direction_n;
		CBUFFER_END
		ENDHLSL

		Pass {
			Name "Unlit"
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			Cull Front
			ZTest Always


			HLSLPROGRAM
			#pragma vertex UnlitVert
			#pragma fragment UnlitFrag

			struct MeshData 
			{
				float4 positionOS	: POSITION;
			};

			struct Interpolators 
			{
				float4 positionCS 	: SV_POSITION;
				float4 positionSS	: TEXCOORD1;
			};

			half4x4 _LightDirMatrix;

			TEXTURE2D(_MainTex);		SAMPLER(sampler_MainTex);
			TEXTURE2D(_CausticsTex);	SAMPLER(sampler_CausticsTex);
			TEXTURE2D(_VoronoiTex);		SAMPLER(sampler_VoronoiTex);

			Interpolators UnlitVert(MeshData IN) 
			{
				Interpolators OUT;

				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.positionSS = ComputeScreenPos(OUT.positionCS);

				return OUT;
			}

			half4 UnlitFrag(Interpolators IN) : SV_Target 
			{
				float2 uv = IN.positionSS.xy / IN.positionSS.w;

				float depth = SampleSceneDepth( uv );

				float3 positionWS = ComputeWorldSpacePosition( uv, depth, UNITY_MATRIX_I_VP );

				if(depth < 0.0001) 
					return half4(0,0,0,0);

				float3 positionOS = TransformWorldToObject( positionWS );

				float2 uvWS = mul( positionWS, _LightDirMatrix ).xy;
				float2 uvWS_c = TRANSFORM_TEX( uvWS, _CausticsTex );
				float2 uvWS_v = TRANSFORM_TEX( uvWS, _VoronoiTex );

				float  directionRad_a = _Direction_a * 3.141592 / 180;
				float  directionRad_b = _Direction_b * 3.141592 / 180;
				float  directionRad_n = _Direction_n * 3.141592 / 180;

				float2 directionVec_a = float2( cos( directionRad_a ), sin( directionRad_a ) );
				float2 directionVec_b = float2( cos( directionRad_b ), sin( directionRad_b ) );
				float2 directionVec_n = float2( cos( directionRad_n ), sin( directionRad_n ) );

				float2 uvWS_a = uvWS_c + directionVec_a * _CausticsSpeed * _Time.y; 
				float2 uvWS_b = uvWS_c + directionVec_b * _CausticsSpeed * _Time.y; 
				uvWS_v = uvWS_v + directionVec_n * _CausticsSpeed * _Time.y; 

				half4 causticsColor_a = _CausticsTex.Sample( sampler_CausticsTex,  uvWS_a );
				half4 causticsColor_b = _CausticsTex.Sample( sampler_CausticsTex,  uvWS_b );
				half4 voronoiNoiseCol = _VoronoiTex.Sample( sampler_VoronoiTex,  uvWS_v );

				float boundingBoxMask = all( step( positionOS, 0.5 ) * ( 1 - step( positionOS, -0.5 ) ) );

				half shadowMask = MainLightRealtimeShadow( TransformWorldToShadowCoord( positionWS ) );

				float causticsMask = shadowMask * boundingBoxMask;
				
				if ( causticsMask > _ShadowThreshold ) {
						//return causticsColor_a * causticsColor_b * causticsMask * voronoiNoiseCol * _Strength;
						float4 color = saturate( lerp( causticsColor_a, causticsColor_b, voronoiNoiseCol.r * _VoronoiStrength ) * causticsMask ) * _Color;
						if (color.r > _CausticsThreshold) {
							return color;
						}
				}
					
				return 0;

			}
			ENDHLSL
		}
	}
}