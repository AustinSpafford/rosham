Shader "Custom/GeneticRoshamDisplayShader"
{
	Properties
	{
		_MainTex("Simulation Texture", 2D) = "black" {}
	
		_ImmunityEffectFraction("Immunity Saturation Effect", Range(0, 1)) = 1.0
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

			uniform float _ImmunityEffectFraction;

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
				float4 simState = tex2D(_MainTex, inputs.uv);

				float hue = simState.x;
				float saturation = lerp(0.75, 1, simState.y);
				float brightness = (simState.z * pow(lerp(0.5, 1, simState.y), 3));

				saturation = lerp(1, saturation, _ImmunityEffectFraction);
				brightness = lerp(simState.z, brightness, _ImmunityEffectFraction);

				return float4(
					HsbToRgb(float3(hue, saturation, brightness)),
					1);
			}

			ENDCG
		}
	}
}
