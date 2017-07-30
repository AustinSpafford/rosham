Shader "Custom/GheSimulationMoveShader"
{
	Properties
	{
		_MainTex("Primary Texture (iterative)", 2D) = "black" {}
		_WebcamTex("Webcam Texture", 2D) = "black" {}
		
		_StraightMovementProbability("Straight Movement Probability", Range(0, 1)) = 0.99
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

			#include "GheCommon.cginc"

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
			uniform float _SimulationIterationRandomFraction;
			uniform float _DeltaTime;

			uniform float _StraightMovementProbability;

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
				float4 self = tex2D(_MainTex, inputs.uv);

				float4 result = self;
				
				float2 dynamicRandom = Random2(inputs.uv + _SimulationIterationRandomFraction);

				if (self.y <= 0.0)
				{
					// If we're an empty cell that has accepted a spark.
					if (self.z >= 0.0)
					{
						float2 kernelCell = kNeighborhoodKernel[FloatToIntRound(ReverseDirection(self.z))];

						float2 neighborCoord = (inputs.uv + (kernelCell.xy * _MainTex_TexelSize.xy));
						float4 neighbor = tex2D(_MainTex, neighborCoord);

						// Become the spark.
						result.y = neighbor.y;
						result.z = neighbor.z;

						// Randomly steer around.
						if (_StraightMovementProbability < dynamicRandom.x)
						{
							result.z = SnapDirection(result.z + ((dynamicRandom.y < 0.5) ? 1.0 : -1.0));
						}
					}
				}
				else
				{
					float2 kernelCell = kNeighborhoodKernel[FloatToIntRound(self.z)];
					
					float2 neighborCoord = (inputs.uv + (kernelCell.xy * _MainTex_TexelSize.xy));
					float4 neighbor = tex2D(_MainTex, neighborCoord);

					// If we're a spark that is moving into an empty cell that has accepted us.
					if ((neighbor.y <= 0.0) &&
						DirectionsAreEqual(neighbor.z, self.z))
					{
						// Become an empty cell.
						result.y = 0.0;
						result.z = -1.0;
					}
					else
					{						
						// Randomize our steering to avoid traffic jams.
						result.z = SnapDirection(result.z + ((dynamicRandom.x < 0.5) ? 1.0 : -1.0));
					}
				}

				if (result.y > 0.0)
				{
					result.x = max(result.x, pow(result.y, 0.25));
					result.y = max(0.0, (result.y - 0.001));

					// If the spark just died, clear the direction to keep it from appearing to be an empty spaec that failed its handshake.
					result.z = ((result.y <= 0.0) ? -1.0 : result.z);
				}
				else
				{
					result.x = max(0.0, (result.x - 0.02));
				}

				return result;
			}

			ENDCG
		}
	}
}
