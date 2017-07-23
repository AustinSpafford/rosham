Shader "Custom/PrifSimulationDecisionShader"
{
	Properties
	{
		_MainTex("Primary Texture (iterative)", 2D) = "black" {}
	
		_MinSpeed("Min Speed", Range(0, 2)) = 0.0
		_MaxSpeed("Max Speed", Range(0, 2)) = 2.0
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

			// 5x5 Circular Kernel. Derived by taking a circle inscribed in a square, and sudivided it into 5x5 cells.
			// Each cell's area represents its contribution to a circle with total area of 1.
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

			uniform float _MinSpeed;
			uniform float _MaxSpeed;

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
				float neighborhoodAverageMass = 0;
				{
					float2 neighborhoodAverageMomentum = 0;

					for (int index = 0; index < 25; index++)
					{
						float3 kernelCell = kNeighborhoodKernel[index];

						float2 neighborCoordDelta = (kernelCell.xy * _MainTex_TexelSize.xy);
						float4 neighbor = tex2D(_MainTex, (inputs.uv + neighborCoordDelta));

						neighborhoodAverageMomentum += (neighbor.xy * neighbor.z * kernelCell.z);
						neighborhoodCenterOfMass += (neighborCoordDelta * neighbor.z);
						neighborhoodAverageMass += (neighbor.z * kernelCell.z);
					}

					neighborhoodCenterOfMass /= max(0.0001, neighborhoodAverageMass);

					neighborhoodVelocity = (neighborhoodAverageMomentum / max(0.0001, neighborhoodAverageMass));
				}

				float2 idealVelocity;
				{
					idealVelocity = neighborhoodVelocity;

					// HAAAAAACK!
					if (neighborhoodAverageMass < 1.0)
					{
						idealVelocity += (1.0 * neighborhoodCenterOfMass);
					}
					else if (neighborhoodAverageMass > 3.0)
					{
						idealVelocity += (-1.0 * neighborhoodCenterOfMass);
					}
				}

				float2 newVelocity;
				{
					float2 unboundedVelocity = idealVelocity; // TODO: Add some acceleration?
					float unboundedSpeed = max(0.0001, length(unboundedVelocity));

					float2 newDirection = (unboundedVelocity / unboundedSpeed);
					float newSpeed = clamp(unboundedSpeed, _MinSpeed, _MaxSpeed);

					newVelocity = (newDirection * newSpeed);
				}

				// BUUUUUUUUUUUG! We're diffusing just the mass, instead of the momentum.
				// Slightly diffuse mass to keep ultra-dense cells from forming.
				self.z = lerp(self.z, neighborhoodAverageMass, 0.01);

				return float4(newVelocity.x, newVelocity.y, self.z, 0);
			}

			ENDCG
		}
	}
}
