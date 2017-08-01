Shader "Custom/GheSimulationMoveShader"
{
	Properties
	{
		_MainTex("Primary Texture (iterative)", 2D) = "black" {}
		_WebcamTex("Webcam Texture", 2D) = "black" {}
		
		_AmbientSpawnProbability("Ambient-Spawn Probability", Range(0, 1)) = 0.01

		_BurstSpawnAverageIterationPeriod("Burst-Spawn Average Iteration Period", Int) = 120
		_BurstSpawnIterationDuration("Burst-Spawn Iteration Duration", Int) = 30
		_BurstSpawnRadiusMin("Burst-Spawn Radius Min", Float) = 0.05
		_BurstSpawnRadiusMax("Burst-Spawn Radius Max", Float) = 0.5
		_BurstSpawnPerCellProbability("Burst-Spawn Per-Cell Probability", Range(0, 1)) = 0.02
			
		_LightningSpawnAverageIterationPeriod("Lightning-Spawn Average Iteration Period", Int) = 1200
		_LightningSpawnIterationDuration("Lightning-Spawn Iteration Duration", Int) = 30
		_LightningSpawnPerCellProbability("Lightning-Spawn Per-Cell Probability", Range(0, 1)) = 0.001

		_SparkAgingRate("Spark Aging Rate", Float) = 0.1
			
		_WebcamSteeringProbability("Webcam Steering Probability", Range(0, 1)) = 0.9
		_RandomSteeringProbability("Random Steering Probability", Range(0, 1)) = 0.02
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
			#include "..\ShaderIncludes\Coordinates.cginc"
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

			uniform float _AmbientSpawnProbability;
			
			uniform int _BurstSpawnAverageIterationPeriod;
			uniform int _BurstSpawnIterationDuration;
			uniform float _BurstSpawnRadiusMin;
			uniform float _BurstSpawnRadiusMax;
			uniform float _BurstSpawnPerCellProbability;
			
			uniform int _LightningSpawnAverageIterationPeriod;
			uniform int _LightningSpawnIterationDuration;
			uniform float _LightningSpawnPerCellProbability;

			uniform float _SparkAgingRate;

			uniform float _WebcamSteeringProbability;
			uniform float _RandomSteeringProbability;

			uniform int _WebcamIsLeftRightMirrored;

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

			float SampleWebcamBrightness(
				float2 canvasCoord)
			{
				float2 webcamCoord = TransformFromCanvasTextureToFramedTexture(canvasCoord, _MainTex_TexelSize.zw, _WebcamTex_TexelSize.zw);

				if (_WebcamIsLeftRightMirrored)
				{
					webcamCoord.x = lerp(1, 0, webcamCoord.x);
				}

				float4 webcamSample =
					TextureCoordIsInBounds(webcamCoord) ?
						tex2D(_WebcamTex, webcamCoord) :
						float4(0, 0, 0, 1);

				float webcamBrightness = (0.333 * (webcamSample.r + webcamSample.g + webcamSample.b));

				return webcamBrightness;
			}

			float SampleWebcamBrightnessForSteering(
				float2 sparkCoord,
				float4 sparkState,
				float directionDelta)
			{
				float direction = SnapDirection(sparkState.z + directionDelta);

				float2 kernelCell = kNeighborhoodKernel[FloatToIntRound(direction)];
					
				float2 canvasNeighborCoord = (sparkCoord + (kernelCell.xy * _MainTex_TexelSize.xy));

				return SampleWebcamBrightness(canvasNeighborCoord);
			}

			float4 FragmentMain(
				VertexToFragment inputs) : SV_Target
			{
				float4 self = tex2D(_MainTex, inputs.uv);

				float4 result = self;
				
				float4 dynamicRandom = Random4(inputs.uv + _SimulationIterationRandomFraction);

				if (self.y <= 0.0)
				{
					// If we're an empty cell that has accepted a spark.
					if (self.z >= 0.0)
					{
						float2 kernelCell = kNeighborhoodKernel[FloatToIntRound(ReverseDirection(self.z))];

						float2 neighborCoord = (inputs.uv + (kernelCell.xy * _MainTex_TexelSize.xy));
						float4 neighbor = tex2D(_MainTex, neighborCoord);

						// Become the spark.
						result.yzw = neighbor.yzw;

						float selfBrightness = SampleWebcamBrightness(inputs.uv);

						float effectiveWebcamSteeringProbability = (result.w * _WebcamSteeringProbability);

						if (dynamicRandom.x < effectiveWebcamSteeringProbability)
						{
							float leftBrightness = SampleWebcamBrightnessForSteering(inputs.uv, result, 1);
							float centerBrightness = SampleWebcamBrightnessForSteering(inputs.uv, result, 0);
							float rightBrightness = SampleWebcamBrightnessForSteering(inputs.uv, result, -1);

							/*
							float totalBrightness = (leftBrightness + centerBrightness + rightBrightness);
							float randomBrightness = (dynamicRandom.z * totalBrightness);

							float directionDelta =
								(randomBrightness < leftBrightness) ? -1 :
								(((totalBrightness - rightBrightness) < randomBrightness) ? 1 : 0);
							*/

							bool leftIsBrightest = ((leftBrightness > centerBrightness) && (leftBrightness > rightBrightness));
							bool rightIsBrightest = ((rightBrightness > centerBrightness) && (rightBrightness > leftBrightness));
							float directionDelta = (leftIsBrightest ? 1 : (rightIsBrightest ? -1 : 0));

							result.z = SnapDirection(result.z + directionDelta);
						}
						else if (((1.0 - effectiveWebcamSteeringProbability) * dynamicRandom.y) < _RandomSteeringProbability)
						{
							result.z = SnapDirection(result.z + ((dynamicRandom.z < 0.5) ? 1.0 : -1.0));
						}
					}
					else // Else we're just an empty cell with nothing special going on.
					{
						// Spawn ambient-sparks.
						if (_AmbientSpawnProbability > 0.0)
						{
							float webcamBrightness = SampleWebcamBrightness(inputs.uv);

							// If we're inside the webcam image.
							if (webcamBrightness > 0.0)
							{
								// Note: Massive wonkiness was happening when trying to compare super-low probabilities,
								// hence the bodged approach of testing against two random values.
								if ((dynamicRandom.x < _AmbientSpawnProbability) &&
									(dynamicRandom.y < _AmbientSpawnProbability))
								{
									result.y = lerp(0.02, 0.1, dynamicRandom.z);
									result.z = floor(7.999 * dynamicRandom.w);
									result.w = 0.1;
								}
							}
						}

						// Spawn burst-sparks.
						{
							uint currentPeriodIndex = ((uint)_SimulationIterationIndex / (uint)_BurstSpawnAverageIterationPeriod);
							uint currentSubperiodIndex = (_SimulationIterationIndex - (currentPeriodIndex * _BurstSpawnAverageIterationPeriod));

							float4 burstSpawnRandom = Random4(currentPeriodIndex);

							float burstStartSubperiodIndex = (burstSpawnRandom.x * (_BurstSpawnAverageIterationPeriod - _BurstSpawnIterationDuration));
							float burstProgressFraction = saturate((currentSubperiodIndex - burstStartSubperiodIndex) / (float)_BurstSpawnIterationDuration);

							// If a burst is currently active.
							if ((0.0 < burstProgressFraction) && (burstProgressFraction < 1.0))
							{
								float eventualBurstRadius = lerp(_BurstSpawnRadiusMin, _BurstSpawnRadiusMax, burstSpawnRandom.y);
								float currentBurstRadius = (burstProgressFraction * eventualBurstRadius);

								// Note: We're using perspective-correction to make the burst circular (instead of an oval).
								float2 testCoord = TextureCoordToPerspectiveCorrected(inputs.uv, _MainTex_TexelSize.zw);
								float2 burstCenterCoord = lerp(-1, 1, burstSpawnRandom.zw);

								// Bias towards the center to increase the odds of highlighting the face.
								burstCenterCoord = (sign(burstCenterCoord) * pow(abs(burstCenterCoord), 3.0));

								float2 selfToBurstCenterDelta = (burstCenterCoord - testCoord);
								float distanceToBurstCenterSq = dot(selfToBurstCenterDelta, selfToBurstCenterDelta);

								if (distanceToBurstCenterSq <= (currentBurstRadius * currentBurstRadius))
								{
									float distanceToBurstCenter = sqrt(distanceToBurstCenterSq);
									
									float burstStrengthFraction = (
										pow((distanceToBurstCenter / currentBurstRadius), 2.0) *
										(1.0 - burstProgressFraction));

									float creationProbability = (_BurstSpawnPerCellProbability * burstStrengthFraction);
									
									// Note: Massive wonkiness was happening when trying to compare super-low probabilities,
									// hence the bodged approach of testing against two random values.
									if ((dynamicRandom.x < creationProbability) &&
										(dynamicRandom.y < creationProbability))
									{
										result.y = lerp(0.25, 1.0, dynamicRandom.z);
										result.z = floor(7.999 * dynamicRandom.w);
										result.w = 1.0;
									}
								}
							}
						}

						// Spawn lightning-sparks.
						{
							uint currentPeriodIndex = ((uint)_SimulationIterationIndex / (uint)_LightningSpawnAverageIterationPeriod);
							uint currentSubperiodIndex = (_SimulationIterationIndex - (currentPeriodIndex * _LightningSpawnAverageIterationPeriod));

							float4 lightningSpawnRandom = Random4(currentPeriodIndex);

							float lightningStartSubperiodIndex = (lightningSpawnRandom.x * (_LightningSpawnAverageIterationPeriod - _LightningSpawnIterationDuration));
							float lightningProgressFraction = saturate((currentSubperiodIndex - lightningStartSubperiodIndex) / (float)_LightningSpawnIterationDuration);

							// If a lightning blast is currently active.
							if ((0.0 < lightningProgressFraction) && (lightningProgressFraction < 1.0))
							{
								float creationProbability = lerp(_LightningSpawnPerCellProbability, 0.0, lightningProgressFraction);
									
								// Note: Massive wonkiness was happening when trying to compare super-low probabilities,
								// hence the bodged approach of testing against two random values.
								if ((dynamicRandom.x < creationProbability) &&
									(dynamicRandom.y < creationProbability))
								{
									result.y = lerp(0.01, 0.5, pow(dynamicRandom.z, 2.0));
									result.z = floor(7.999 * dynamicRandom.w);
									result.w = 0.5;
								}
							}
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
					result.y = max(0.0, (result.y - (_SparkAgingRate * _DeltaTime)));

					// If the spark just died, clear the direction to keep it from appearing to be an empty spaec that failed its handshake.
					result.z = ((result.y <= 0.0) ? -1.0 : result.z);
				}
				else
				{
					result.x = max(0.0, (result.x - 0.02));
				}

				//result.w = SampleWebcamBrightnessForSteering(inputs.uv, result, 0);

				return result;
			}

			ENDCG
		}
	}
}
