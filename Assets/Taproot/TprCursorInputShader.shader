Shader "Custom/TprCursorInputShader"
{
	Properties
	{
		_MainTex("Primary Texture (iterative)", 2D) = "black" {}
	
		_BlueprintFalloff("Blueprint Falloff", Range(0, 1)) = 0.02
		_EraserFalloff("Eraser Falloff", Range(0, 1)) = 0.05
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

			uniform float _BlueprintFalloff;
			uniform float _EraserFalloff;

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
				float4 self = tex2D(_MainTex, inputs.uv);

				float2 testCoord = TextureCoordToPerspectiveCorrected(inputs.uv, _MainTex_TexelSize.zw);
				float2 cursorCoord = TextureCoordToPerspectiveCorrected(_CursorPosition, _MainTex_TexelSize.zw);
				
				float2 selfToCursorDelta = (cursorCoord - testCoord);
				float distanceToCursorSq = dot(selfToCursorDelta, selfToCursorDelta);

				float4 result = self;
				
				// Left mouse button.
				if (_CursorButtonPressed.x > 0.0)
				{
					if (distanceToCursorSq <= (_BlueprintFalloff * _BlueprintFalloff))
					{					
						if (IsType(self.x, kTypeGround))
						{
							result.x = kTypeConveyor;
							//result.x = kTypeBlueprint;
							//result.w = -1; // Consume 1 plate to build the conveyor.
						}
					}
				}
				
				// Right mouse button.
				if (_CursorButtonPressed.y > 0.0)
				{
					if (distanceToCursorSq <= (_EraserFalloff * _EraserFalloff))
					{					
						if (IsType(self.x, kTypeBlueprint))
						{
							result.x = kTypeGround;
							result.y = -1;
						}
					}
				}

				return result;
			}

			ENDCG
		}
	}
}
