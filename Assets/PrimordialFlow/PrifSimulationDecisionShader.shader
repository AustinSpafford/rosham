Shader "Custom/PrifSimulationDecisionShader"
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

			// Based on intersecting a circle with a square of equal radius that's been sudivided into 5x5 cells.
			// These areas represent each cell's contribution to a circle with total area of 1.
			#define kApexArea 0.050195145475
			#define kEdgeArea 0.039192412795
			#define kCornerArea 0.006837485935
			#define kMiddleArea 0.050925574666
			static const float3 kNeighborhoodKernel[25] =
			{
				float3(-2, 2, kCornerArea),  float3(-1, 2, kEdgeArea),    float3(0, 2, kApexArea),    float3(1, 2, kEdgeArea),    float3(2, 2, kCornerArea), 
				float3(-2, 1, kEdgeArea),    float3(-1, 1, kMiddleArea),  float3(0, 1, kMiddleArea),  float3(1, 1, kMiddleArea),  float3(2, 1, kEdgeArea), 
				float3(-2, 0, kApexArea),    float3(-1, 0, kMiddleArea),  float3(0, 0, kMiddleArea),  float3(1, 0, kMiddleArea),  float3(2, 0, kApexArea), 
				float3(-2, -1, kEdgeArea),   float3(-1, -1, kMiddleArea), float3(0, -1, kMiddleArea), float3(1, -1, kMiddleArea), float3(2, -1, kEdgeArea), 
				float3(-2, -2, kCornerArea), float3(-1, -2, kEdgeArea),   float3(0, -2, kApexArea),   float3(1, -2, kEdgeArea),   float3(2, -2, kCornerArea), 
			};

			uniform float _ImmunityDecayRate;
			uniform float _MaxMutationStep;

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

				float2 neighborhoodVelocity = 0;
				float2 neighborhoodCenterOfMass = 0;
				float neighborhoodTotalMass = 0;
				{
					for (int index = 0; index < 25; index++)
					{
						float3 kernelCell = kNeighborhoodKernel[index];

						float4 neighbor = tex2D(_MainTex, (inputs.uv + (kernelCell.xy * _MainTex_TexelSize.xy)));

						neighborhoodVelocity += (neighbor.xy * kernelCell.z);
						neighborhoodCenterOfMass += (kernelCell.xy * neighbor.z);
						neighborhoodTotalMass += (neighbor.z * kernelCell.z);
					}

					neighborhoodCenterOfMass /= neighborhoodTotalMass;
				}

				return float4(neighborhoodVelocity.x, neighborhoodVelocity.y, self.z, 0);
			}

			ENDCG
		}
	}
}
