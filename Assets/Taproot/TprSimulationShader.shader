Shader "Custom/TprSimulationShader"
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

			#include "TprCommon.cginc"

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

			static const float3 kNeighborhoodKernel[8] =
			{
				float3(-1, 1, 1.414),  float3(0, 1, 1.0),  float3(1, 1, 1.414),
				float3(-1, 0, 1.0),                        float3(1, 0, 1.0),
				float3(-1, -1, 1.414), float3(0, -1, 1.0), float3(1, -1, 1.414),
			};
			
			sampler2D _MainTex;
			uniform half4 _MainTex_TexelSize;

			float4 FragmentMain(
				VertexToFragment inputs) : SV_Target
			{
				float4 self = tex2D(_MainTex, inputs.uv);

				bool typeTransportsMaterials = false;
				if (IsType(self.x, kTypeGround))
				{
					// TODO: Maybe grow plants?
				}
				else if (IsType(self.x, kTypeConveyor))
				{
					typeTransportsMaterials = true;
				}
				else if (IsType(self.x, kTypeBlueprint))
				{
					// HAAAAAAAAAAAACK!
					typeTransportsMaterials = true;
				}
				/*
				else if (IsType(self.x, kTypeObstacle))
				{
				}
				else if (IsType(self.x, kTypeVein))
				{
				}
				*/
				else if (IsType(self.x, kTypeBase))
				{
					typeTransportsMaterials = true;
				}

				if (typeTransportsMaterials)
				{
					for (int index = 0; index < 8; index++)
					{
						float3 kernelCell = kNeighborhoodKernel[index];
						
						float2 neighborCoordDelta = (kernelCell.xy * _MainTex_TexelSize.xy);
						float4 neighbor = tex2D(_MainTex, (inputs.uv + neighborCoordDelta));

						// If the neighbor contains a connection to the base.
						if (neighbor.y >= 0.0)
						{
							float distanceThroughNeighbor = (neighbor.y + kernelCell.z);

							self.y =
								(self.y >= 0.0) ?
									min(self.y, distanceThroughNeighbor) :
									distanceThroughNeighbor;
						}
					}
				}

				return self;
			}

			ENDCG
		}
	}
}
