Shader "Custom/PrifSimulationMoveShader"
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
			
			static const float2 kNeighborhoodKernel[25] =
			{
				float2(-2, 2),  float2(-1, 2),  float2(0, 2),  float2(1, 2),  float2(2, 2), 
				float2(-2, 1),  float2(-1, 1),  float2(0, 1),  float2(1, 1),  float2(2, 1), 
				float2(-2, 0),  float2(-1, 0),  float2(0, 0),  float2(1, 0),  float2(2, 0), 
				float2(-2, -1), float2(-1, -1), float2(0, -1), float2(1, -1), float2(2, -1), 
				float2(-2, -2), float2(-1, -2), float2(0, -2), float2(1, -2), float2(2, -2), 
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

			float ComputeTransferedMass(
				float2 sourceCoord,
				float4 sourceCell,
				float2 candidateDestinationCoord)
			{
				float2 idealDestinationCoord = (sourceCoord + (sourceCell.xy * _MainTex_TexelSize.xy));

				// How far away is the candidate from the ideal destination, in terms of texels.
				float2 idealToCandidateTexelDelta = 
					((candidateDestinationCoord - idealDestinationCoord) * _MainTex_TexelSize.zw);

				// Calculate a single bilinear-filtering weight to find out how much mass goes to the candidate.
				float2 transferCoefficients = (1.0 - saturate(abs(idealToCandidateTexelDelta)));
				float transferredMass = ((transferCoefficients.x * transferCoefficients.y) * sourceCell.z);

				return transferredMass;
			}

			float4 FragmentMain(
				VertexToFragment inputs) : SV_Target
			{
				float2 incomingMomentum = 0;
				float incomingMass = 0;
				for (int index = 0; index < 25; index++)
				{
					float2 kernelCell = kNeighborhoodKernel[index];

					float2 sourceCoord = (inputs.uv + (kernelCell.xy * _MainTex_TexelSize.xy));
					float4 sourceCell = tex2D(_MainTex, sourceCoord);

					float transferredMass = ComputeTransferedMass(sourceCoord, sourceCell, inputs.uv);

					incomingMomentum += (sourceCell.xy * transferredMass);
					incomingMass += transferredMass;
				}

				float2 resultVelocity = (incomingMomentum / max(0.0001, incomingMass));

				return float4(resultVelocity.x, resultVelocity.y, incomingMass, 0);
			}

			ENDCG
		}
	}
}
