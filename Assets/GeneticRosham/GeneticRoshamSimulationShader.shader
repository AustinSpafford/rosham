Shader "Custom/GeneticRoshamSimulationShader"
{
	Properties
	{
		_MainTex("Primary Texture (iterative)", 2D) = "black" {}
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

			VertexToFragment VertexMain(
				appdata vertexData)
			{
				VertexToFragment result;
				result.vertex = UnityObjectToClipPos(vertexData.vertex);
				result.uv = vertexData.uv;
				return result;
			}
			
			sampler2D _MainTex;
			uniform half4 _MainTex_TexelSize;

			float4 FragmentMain(VertexToFragment inputs) : SV_Target
			{
				// float2 adjacentTexCoordOffset = float2(_MainTex_TexelSize.x, 0.0f);
				// return frac(tex2D(_MainTex, inputs.uv) + float4(0.01, 0.02, 0.03, 0));
				// return tex2D(_MainTex, inputs.uv);

				float2 texelIndices = (inputs.uv * _MainTex_TexelSize.zw);

				return float4(
					max(frac(texelIndices.x * pow(0.5, 2)), frac(texelIndices.y * pow(0.5, 2))),
					max(frac(texelIndices.x * pow(0.5, 5)), frac(texelIndices.y * pow(0.5, 5))),
					max(frac(texelIndices.x * pow(0.5, 8)), frac(texelIndices.y * pow(0.5, 8))),
					1.0);
			}

			ENDCG
		}
	}
}
