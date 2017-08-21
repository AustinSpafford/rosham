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

			uniform float _SimulationSeedFraction;
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

			bool OreTransferIsValid(
				float4 sourceCell,
				float4 destinationCell)
			{
				return (
					((destinationCell.z < 0.0) && (sourceCell.z > 0.0)) && // Destination wants ore, and source can provide ore.
					(0.0 <= destinationCell.y) && // Destination transports materials.
					((sourceCell.y < 0.0) || (destinationCell.y < sourceCell.y))); // This moves ore towards the base.
			}

			float4 FragmentMain(
				VertexToFragment inputs) : SV_Target
			{
				float4 self = tex2D(_MainTex, inputs.uv);

				// Transport materials.
				// NOTE: This must be performed first, because our neighbors operate on the prior-frame's state.
				{
					// Take ore, else give ore.
					if (self.z < 0.0)
					{
						for (int index = 0; index < 8; index++)
						{
							float3 kernelCell = kNeighborhoodKernel[index];

							float2 neighborCoordDelta = (kernelCell.xy * _MainTex_TexelSize.xy);
							float4 neighbor = tex2D(_MainTex, (inputs.uv + neighborCoordDelta));

							if (OreTransferIsValid(neighbor, self))
							{
								self.z = max(self.z, 0.0); // Remove the "ore wanted" flag.
								self.z += 1.0;
							}
						}
					}
					else if (self.z > 0.0)
					{
						for (int index = 0; index < 8; index++)
						{
							float3 kernelCell = kNeighborhoodKernel[index];

							float2 neighborCoordDelta = (kernelCell.xy * _MainTex_TexelSize.xy);
							float4 neighbor = tex2D(_MainTex, (inputs.uv + neighborCoordDelta));
							
							if (OreTransferIsValid(self, neighbor))
							{
								self.z -= 1.0;

								if ((self.z < 0.001) &&
									IsType(self.x, kTypeVein))
								{
									self = ConvertToBlueprint(self);
								}
							}
						}
					}

					// Take plates.
					if (self.w < 0.0)
					{
					}

					// Give plates.
					if (self.w > 0.0)
					{
					}
				}

				bool typeTransportsMaterials = false;
				if (IsType(self.x, kTypeGround))
				{
					// TODO: Maybe fog-of-war calculations?
				}
				else if (IsType(self.x, kTypeConveyorConnected))
				{
					typeTransportsMaterials = true;

					// If we're out of ore, request more.
					if (IsZero(self.z))
					{
						self.z = -1.0;
					}

					// If we're out of plates, request more.
					if (IsZero(self.w))
					{
						self.w = -1.0;
					}
				}
				else if (IsType(self.x, kTypeConveyorDisconnected))
				{
					typeTransportsMaterials = true;

					// Clear our ore/plate requests.
					self.zw = max(self.zw, 0.0);
				}
				else if (IsType(self.x, kTypeBlueprint))
				{
					if (self.w >= 0.0)
					{
						// NOTE: We'll transport materials on the next-frame.
						self.x = kTypeConveyorDisconnected;
					}
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

					// Smelt ore into plates at infinite-speed.
					if (self.z >= 0.0)
					{
						float consumedOre = clamp(self.z, 0.0, 100.0);
						self.w += consumedOre;
						self.z -= consumedOre;

						if (IsZero(self.z))
						{
							self.z = -1.0;
						}
					}
				}

				// Propogate the distance-to-base network.
				if (typeTransportsMaterials)
				{
					bool haveInitializedNeighbor = false;
					float minDistanceThroughNeighbor = 1000000.0;

					for (int index = 0; index < 8; index++)
					{
						float3 kernelCell = kNeighborhoodKernel[index];
						
						float2 neighborCoordDelta = (kernelCell.xy * _MainTex_TexelSize.xy);
						float4 neighbor = tex2D(_MainTex, (inputs.uv + neighborCoordDelta));

						// If the neighbor contains a connection to the base.
						if (neighbor.y >= 0.0)
						{
							float distanceThroughNeighbor = (neighbor.y + kernelCell.z);

							minDistanceThroughNeighbor = min(minDistanceThroughNeighbor, distanceThroughNeighbor);
							haveInitializedNeighbor = true;
						}
					}

					if (haveInitializedNeighbor && 
						(self.y != 0.0))
					{
						if (IsType(self.x, kTypeConveyorDisconnected) &&
							(minDistanceThroughNeighbor <= self.y))
						{
							self.x = kTypeConveyorConnected;
						}
						else if (IsType(self.x, kTypeConveyorConnected) &&
							(minDistanceThroughNeighbor > self.y))
						{
							self.x = kTypeConveyorDisconnected;
						}

						// NOTE: If we've become disconnected from the base, we'll start to float upwards
						// in distance until reconnected. That's okay, since that's safe to do.
						self.y = minDistanceThroughNeighbor;
					}
				}

				return self;
			}

			ENDCG
		}
	}
}
