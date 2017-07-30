Shader "Custom/GheCursorInputShader"
{
	Properties
	{
		_MainTex("Primary Texture (iterative)", 2D) = "black" {}
	
		_SparkerInnerFalloff("Sparker Inner Falloff", Range(0, 1)) = 0.1
		_SparkerOuterFalloff("Sparker Outer Falloff", Range(0, 1)) = 0.2
		_SparkerCreationProbability("Sparker Creation Probability", Range(0, 1)) = 0.02
			
		_EraserFalloff("Eraser Falloff", Range(0, 1)) = 0.3
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

			uniform float _SparkerInnerFalloff;
			uniform float _SparkerOuterFalloff;
			uniform float _SparkerCreationProbability;

			uniform float _EraserFalloff;

			uniform int _SimulationIterationIndex;
			uniform float _SimulationIterationRandomFraction;
			uniform float _DeltaTime;

			uniform int _CursorIsActive;
			uniform float2 _CursorPosition;
			uniform float2 _CursorPositionDelta;
			uniform float3 _CursorButtonPressed;
			uniform float3 _CursorButtonClicked;
			uniform float3 _CursorButtonUnclicked;

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

				float2 testCoord = TextureCoordToPerspectiveCorrected(inputs.uv, _MainTex_TexelSize.zw);
				float2 cursorCoord = TextureCoordToPerspectiveCorrected(_CursorPosition, _MainTex_TexelSize.zw);
				
				float3 dynamicRandom = Random3(testCoord + _SimulationIterationRandomFraction);
				
				float2 selfToCursorDelta = (cursorCoord - testCoord);
				float distanceToCursorSq = dot(selfToCursorDelta, selfToCursorDelta);

				float4 result = self;
				
				// Left mouse button.
				if (_CursorButtonPressed.x > 0.0)
				{
					if (distanceToCursorSq <= (_SparkerOuterFalloff * _SparkerOuterFalloff))
					{
						float distanceToCursor = sqrt(distanceToCursorSq);
						float cursorFraction = smoothstep(_SparkerOuterFalloff, _SparkerInnerFalloff, distanceToCursor);
						float creationProbability = (_SparkerCreationProbability * cursorFraction);

						if (dynamicRandom.x < creationProbability)
						{
							result.y = lerp(0.25, 1.0, dynamicRandom.y);
							result.z = floor(7.999 * dynamicRandom.z);
						}
					}
				}
				
				// Right mouse button.
				if (_CursorButtonPressed.y > 0.0)
				{
					if (distanceToCursorSq <= (_EraserFalloff * _EraserFalloff))
					{
						result.y = 0.0;
					}
				}

				return result;
			}

			ENDCG
		}
	}
}
