Shader "Custom/GheDisplayShader"
{
	Properties
	{
		_MainTex("Simulation Texture", 2D) = "black" {}
	
		_SparkColor("Spark Color", Color) = (0.0, 1.0, 1.0, 1.0)
		_TrailColor("Trail Color", Color) = (0.0, 0.6, 0.8, 1.0)
		_GlowColor("Glow Color", Color) = (0.0, 0.6, 0.2, 1.0)
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
			#include "..\ShaderIncludes\ColorSpaces.cginc"
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

			uniform float4 _SparkColor;
			uniform float4 _TrailColor;
			uniform float4 _GlowColor;

			uniform int _SimulationIterationIndex;
			uniform float _DeltaTime;

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

			float4 FragmentMain(
				VertexToFragment inputs) : SV_Target
			{
				float4 self = tex2D(_MainTex, inputs.uv);

				float4 result = float4(0, 0, 0, 1);

				result = lerp(result, _TrailColor, self.x);
				result = lerp(result, _SparkColor, pow(self.y, 0.25));

				return result;
			}

			ENDCG
		}
	}
}
