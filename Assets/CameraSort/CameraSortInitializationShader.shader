Shader "Custom/CameraSortInitialzationShader"
{
	Properties
	{
		// NOTE: No source texture, since this just intializes the simulation from scratch.
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

			VertexToFragment VertexMain(
				appdata vertexData)
			{
				VertexToFragment result;
				result.vertex = UnityObjectToClipPos(vertexData.vertex);
				result.uv = vertexData.uv;
				return result;
			}

			float4 FragmentMain(VertexToFragment inputs) : SV_Target
			{
				return 
					float4(
						HsbToRgb(
							inputs.uv.x,
							smoothstep(1.0, 0.5, inputs.uv.y),
							smoothstep(0.0, 0.5, inputs.uv.y)),
						1.0);
			}

			ENDCG
		}
	}
}
