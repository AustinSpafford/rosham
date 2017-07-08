Shader "Custom/GeneticRoshamSimulationShader"
{
	Properties
	{
		_MainTex("Primary Texture (iterative)", 2D) = "black" {}
	
		_ImmunityDecayRate("Immunity Decay Rate", Float) = 1.0
		_MaxMutationStep("Max Mutation Step", Float) = 0.01
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

			float GetAttackStrength(
				float4 attacker,
				float4 defender)
			{
				float result = 0;

				if ((attacker.z > 0) && // Attacker is alive.
					(defender.y <= 0.001)) // Defender is no longer immune.
				{
					if (defender.z <= 0)
					{
						result = Random(attacker.xy);
					}
					else
					{
						float delta = frac(defender.x - attacker.x);

						if (((0.25 < delta) && (delta < 0.5)) &&
							((2 * delta) > defender.y))
						{
							result = delta;
						}
					}
				}

				return result;
			}

			void UpgradeStrongestNeighbor(
				inout float4 inoutStrongest,
				inout float inoutBestAttackStrength,
				float4 candidate,
				float4 self)
			{
				if (candidate.z > 0)
				{
					float candidateStrength = GetAttackStrength(candidate, self);

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

				float4 strongestNeighbor = float4(0, 0, 0, 0);
				float bestAttackStrength = 0;
				UpgradeStrongestNeighbor(strongestNeighbor, bestAttackStrength, tex2D(_MainTex, (inputs.uv + float2(_MainTex_TexelSize.x, 0))), self);
				UpgradeStrongestNeighbor(strongestNeighbor, bestAttackStrength, tex2D(_MainTex, (inputs.uv + float2(0, _MainTex_TexelSize.y))), self);
				UpgradeStrongestNeighbor(strongestNeighbor, bestAttackStrength, tex2D(_MainTex, (inputs.uv - float2(_MainTex_TexelSize.x, 0))), self);
				UpgradeStrongestNeighbor(strongestNeighbor, bestAttackStrength, tex2D(_MainTex, (inputs.uv - float2(0, _MainTex_TexelSize.y))), self);

				float4 result;
				if (bestAttackStrength > 0)
				{
					result = strongestNeighbor;

					result.x = 
						frac(
							result.x +
							lerp(
								(-1 * _MaxMutationStep), 
								_MaxMutationStep,
								Random(inputs.uv + float(_SimulationIterationIndex))));

					result.y = 1;
				}
				else
				{
					result = self;

					if (result.z > 0.0)
					{
						result.y = max(0, (result.y - (_ImmunityDecayRate * _DeltaTime)));
					}
				}

				return result;
			}

			ENDCG
		}
	}
}
