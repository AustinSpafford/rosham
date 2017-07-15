Shader "Custom/ReplicantSimulationShader"
{
	Properties
	{
		_MainTex("Primary Texture (iterative)", 2D) = "black" {}
		_WebcamTex("Webcam Texture", 2D) = "black" {}

		_MaxMutationStep("Max Mutation Step", Float) = 0.01
		_StaminaDecayRate("Stamina Decay Rate", Float) = 1.0
		_StaminaDefenseScalar("Stamina Defense Scalar", Float) = 1.0
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

			uniform float _MaxMutationStep;
			uniform float _StaminaDecayRate;
			uniform float _StaminaDefenseScalar;

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

			float GetAttackStrength(
				float4 attacker,
				float4 defender,
				float3 webcamSample)
			{
				float result = 0;

				if (attacker.a > 0)
				{
					if (defender.a <= 0)
					{
						// Cell is unoccupied, so grant it to a random attacker.
						result = Random(float2(attacker.r, (attacker.g + attacker.b)) + float(_SimulationIterationIndex));
					}
					else
					{
						float attackerCost = distance(attacker.rgb, webcamSample);
						float defenderCost = distance(defender.rgb, webcamSample);

						float baseAttackStrength = (defenderCost - attackerCost);
						float defenderRandomFraction = Random(float2(defender.r, (defender.g + defender.b)) + float(_SimulationIterationIndex));

						if (baseAttackStrength > (_StaminaDefenseScalar * defender.a * defenderRandomFraction))
						{
							result = baseAttackStrength;
						}
					}
				}

				return result;
			}

			void UpgradeStrongestNeighbor(
				inout float4 inoutStrongest,
				inout float inoutBestAttackStrength,
				float4 candidate,
				float4 self,
				float3 webcamSample)
			{
				if (candidate.a > 0)
				{
					float candidateStrength = GetAttackStrength(candidate, self, webcamSample);

					if (candidateStrength > inoutBestAttackStrength)
					{
						inoutStrongest = candidate;
						inoutBestAttackStrength = candidateStrength;
					}
				}
			}

			float4 FragmentMain(
				VertexToFragment inputs) : SV_Target
			{				
				float4 self = tex2D(_MainTex, inputs.uv);
				
				float2 webcamCoord = float2((1.0 - inputs.uv.x), inputs.uv.y);
				float3 webcamSample = tex2D(_WebcamTex, webcamCoord).rgb;

				float4 strongestNeighbor = float4(0, 0, 0, 0);
				float bestAttackStrength = 0;
				UpgradeStrongestNeighbor(strongestNeighbor, bestAttackStrength, tex2D(_MainTex, (inputs.uv + float2(_MainTex_TexelSize.x, 0))), self, webcamSample);
				UpgradeStrongestNeighbor(strongestNeighbor, bestAttackStrength, tex2D(_MainTex, (inputs.uv + float2(0, _MainTex_TexelSize.y))), self, webcamSample);
				UpgradeStrongestNeighbor(strongestNeighbor, bestAttackStrength, tex2D(_MainTex, (inputs.uv - float2(_MainTex_TexelSize.x, 0))), self, webcamSample);
				UpgradeStrongestNeighbor(strongestNeighbor, bestAttackStrength, tex2D(_MainTex, (inputs.uv - float2(0, _MainTex_TexelSize.y))), self, webcamSample);
				
				float4 result;
				if (bestAttackStrength > 0)
				{
					result = strongestNeighbor;

					float3 mutationSignedFractions =
						float3(
							lerp(-1, 1, Random(inputs.uv + float2(self.x, result.x) + float(_SimulationIterationIndex) + 0)),
							lerp(-1, 1, Random(inputs.uv + float2(self.x, result.x) + float(_SimulationIterationIndex) + 1)),
							lerp(-1, 1, Random(inputs.uv + float2(self.x, result.x) + float(_SimulationIterationIndex) + 2)));

					result.rgb = 
						saturate(
							result.rgb +
							(_MaxMutationStep * mutationSignedFractions));

					result.a = 1;
				}
				else
				{
					result = self;

					// If the cell is alive, weaken its stamina.
					if (result.a >= 0.0)
					{
						result.a = max(0, (result.a - (_StaminaDecayRate * _DeltaTime)));
					}
				}

				return result;
			}

			ENDCG
		}
	}
}
