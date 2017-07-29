Shader "Custom/GheInitialzationShader"
{
	Properties
	{
		// NOTE: No source texture, since this just intializes the simulation from scratch.
		
		_BaseInitialSteel("Base Initial Plates", Int) = 1000

		_VeinThreshold("Vein Threshold", Range(0, 1)) = 0.7
		_VeinMinOre("Vein Min Ore", Int) = 2
		_VeinMaxOre("Vein Max Ore", Int) = 100
	}

	SubShader
	{
		Cull Off // Avoid back-face culling (render both sides).
		ZTest Always // Prevent depth-tests from culling us.
		ZWrite Off // Avoid polluting the depth buffer.

		Pass
		{
			CGPROGRAM

			#pragma vertex VertexMain
			#pragma fragment FragmentMain
			
			#include "UnityCG.cginc"
			#include "..\ShaderIncludes\Coordinates.cginc"
			#include "..\ShaderIncludes\Random.cginc"

			struct appdata // TODO: Can this be renamed?
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct VertexToFragment
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			uniform int _BaseInitialSteel;

			uniform float _VeinThreshold;
			uniform int _VeinMinOre;
			uniform int _VeinMaxOre;

			VertexToFragment VertexMain(
				appdata vertexData)
			{
				VertexToFragment result;
				result.vertex = UnityObjectToClipPos(vertexData.vertex);
				result.uv = vertexData.uv;
				return result;
			}
			
			// NOTE: No actual _MainTex, since this is initialization.
			uniform half4 _MainTex_TexelSize;

			float4 FragmentMain(
				VertexToFragment inputs) : SV_Target
			{
				float4 result = float4(0, 0, 0, 0);

				return result;
			}

			ENDCG
		}
	}
}
