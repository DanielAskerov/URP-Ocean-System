Shader "WaterCaustics" {
	Properties {
		_MainTex ("Example Texture", 2D) = "white" {}
		_Color ("Example Colour", Color) = ( 1, 1, 1, 1 )
		_CausticsTex ("Caustics Texture", 2D) = "white" {}
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
		float4 _MainTex_ST;
		float4 _Color;

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
				float2 uv			: TEXCOORD0;
				float4 color		: COLOR;
			};

			struct Interpolators 
			{
				float4 positionCS 	: SV_POSITION;
				float2 uv			: TEXCOORD0;
				float4 color		: COLOR;
				float4 positionSS	: TEXCOORD1;
			};

			half4x4 _LightDirMatrix;

			TEXTURE2D(_MainTex);		SAMPLER(sampler_MainTex);
			TEXTURE2D(_CausticsTex);	SAMPLER(sampler_CausticsTex);

			Interpolators UnlitVert(MeshData IN) 
			{
				Interpolators OUT;

				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.positionSS = ComputeScreenPos(OUT.positionCS);

				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
				OUT.color = IN.color;
				return OUT;
			}

			half4 UnlitFrag(Interpolators IN) : SV_Target 
			{
				float2 uv = IN.positionSS.xy / IN.positionSS.w;

				float depth = SampleSceneDepth(uv);

				float3 positionWS = ComputeWorldSpacePosition(uv, depth, UNITY_MATRIX_I_VP);

				if(depth < 0.0001) 
					return half4(0,0,0,0);

				float3 positionOS = TransformWorldToObject(positionWS);

				float2 uvWS = mul(positionWS, _LightDirMatrix).xy;
				half4 causticsColor = _CausticsTex.Sample(sampler_CausticsTex, uvWS);

				float boundingBoxMask = all(step(positionOS, 0.5) * (1 - step(positionOS, -0.5)));

				half shadowMask = MainLightRealtimeShadow(TransformWorldToShadowCoord(positionWS));

				return causticsColor * shadowMask * boundingBoxMask;

			}
			ENDHLSL
		}
	}
}