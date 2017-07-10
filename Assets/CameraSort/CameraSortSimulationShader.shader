Shader "Custom/CameraSortSimulationShader"
{
	Properties
	{
		_MainTex("Primary Texture (iterative)", 2D) = "black" {}
		_WebcamTex("Webcam Texture", 2D) = "black" {}
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
			
			sampler2D _WebcamTex;
			uniform half4 _WebcamTex_TexelSize;

			float4 FragmentMain(
				VertexToFragment inputs) : SV_Target
			{
				// Create alternating columns and rows of +/- multipliers.
				float2 partnerParities = float2(
					sign(frac(0.5 * (inputs.uv.x * _MainTex_TexelSize.z)) - 0.5),
					sign(frac(0.5 * (inputs.uv.y * _MainTex_TexelSize.w)) - 0.5));

				float2 neighborOffset;
				{
					float neighboringCycleFraction = frac(0.25 * float(_SimulationIterationIndex));
					
					if (neighboringCycleFraction < 0.1) // (cycle == 0.0)
					{
						// Right
						neighborOffset = float2((_MainTex_TexelSize.x * partnerParities.x), 0);
					}
					else if (neighboringCycleFraction < 0.3) // (cycle == 0.25)
					{
						// Up
						neighborOffset = float2(0, (_MainTex_TexelSize.y * partnerParities.y));
					}
					else if (neighboringCycleFraction < 0.6) // (cycle == 0.5)
					{
						// Left
						neighborOffset = float2((-1 * _MainTex_TexelSize.x * partnerParities.x), 0);
					}
					else // (cycle == 0.75)
					{
						// Down
						neighborOffset = float2(0, (-1 * _MainTex_TexelSize.y * partnerParities.y));
					}
				}

				float2 mainCoord = inputs.uv;
				float2 webcamCoord = float2((1.0 - inputs.uv.x), inputs.uv.y);
				
				float4 selfMain = tex2D(_MainTex, mainCoord);
				float4 selfWebcam = tex2D(_WebcamTex, webcamCoord);
				float4 partnerMain = tex2D(_MainTex, (mainCoord + neighborOffset));
				float4 partnerWebcam = tex2D(_WebcamTex, (webcamCoord + neighborOffset));

				float costStaying = (
					distance(selfMain, selfWebcam) +
					distance(partnerMain, partnerWebcam));

				float costSwitching = (
					distance(selfMain, partnerWebcam) +
					distance(partnerMain, selfWebcam));

				float4 result =
					(costStaying <= costSwitching) ?
						selfMain :
						partnerMain;

				return result;
			}

			ENDCG
		}
	}
}
