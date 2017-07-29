Shader "Custom/GheSimulationHandshakeShader"
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

				float4 result = self;

				// If we're an empty cell, grant a single neighboring spark entry.
				if (self.y <= 0.0)
				{
					float bestDirection = -1;
					float bestScore = -1;
					{
						for (int index = 0; index < 8; index++)
						{
							float3 kernelCell = kNeighborhoodKernel[index];

							float2 neighborCoord = (inputs.uv + (kernelCell.xy * _MainTex_TexelSize.xy));
							float4 neighbor = tex2D(_MainTex, neighborCoord);

							// If the neighbor is a spark trying to move into our cell.
							if ((neighbor.y > 0.0) &&
								DirectionsAreEqual(neighbor.z, kernelCell.z))
							{
								// TODO: Definitely animate this random value!
								float staticNeighborRandom = Random(neighborCoord);

								if (bestScore < staticNeighborRandom)
								{
									bestDirection = neighbor.z;
									bestScore = staticNeighborRandom;
								}
							}
						}
					}

					result.z = bestDirection;
				}

				return result;
			}

			ENDCG
		}
	}
}
