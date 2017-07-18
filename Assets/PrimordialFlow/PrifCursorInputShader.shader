Shader "Custom/PrifCursorInputShader"
{
	Properties
	{
		_MainTex("Primary Texture (iterative)", 2D) = "black" {}
	
		_CursorFalloffInner("Cursor Falloff Inner", Range(0, 1)) = 0.08
		_CursorFalloffOuter("Cursor Falloff Outer", Range(0, 1)) = 0.12
			
		_CursorSmudgeStrength("Cursor Smudge Strength", float) = 1.0
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

			uniform float _CursorFalloffInner;
			uniform float _CursorFalloffOuter;
			uniform float _CursorSmudgeStrength;

			uniform int _SimulationIterationIndex;
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
				float4 result = tex2D(_MainTex, inputs.uv);

				float2 selfToCursorDelta = (inputs.uv - _CursorPosition);

				// Persepective-correct and factor in screen-wrapping.
				selfToCursorDelta = (frac(selfToCursorDelta + 0.5) - 0.5);
				selfToCursorDelta.x *= (_MainTex_TexelSize.z / _MainTex_TexelSize.w);

				float distanceToCursorSq = dot(selfToCursorDelta, selfToCursorDelta);

				if (distanceToCursorSq <= (_CursorFalloffOuter * _CursorFalloffOuter))
				{
					float distanceToCursor = sqrt(distanceToCursorSq);
					float cursorEffectFraction = smoothstep(_CursorFalloffOuter, _CursorFalloffInner, distanceToCursor);
					
					// Left mouse button.
					if (_CursorButtonPressed.x > 0.0)
					{
						result.xy += (_CursorSmudgeStrength * _CursorPositionDelta * cursorEffectFraction);
					}

					// Right mouse button.
					if (_CursorButtonPressed.y > 0.0)
					{
						float2 stirringDirection = normalize(float2(selfToCursorDelta.y, (-1 * selfToCursorDelta.x)));

						result.xy += (stirringDirection * (4.0 + (100.0 * length(_CursorPositionDelta))) * _DeltaTime * cursorEffectFraction);
					}

					// Middle mouse button.
					if (_CursorButtonPressed.z > 0.0)
					{						
						result.xy = lerp(result.xy, 0.0, saturate(10.0 * length(_CursorPositionDelta) * cursorEffectFraction));
					}
				}

				return result;
			}

			ENDCG
		}
	}
}
