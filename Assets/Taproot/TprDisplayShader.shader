Shader "Custom/TprDisplayShader"
{
	Properties
	{
		_MainTex("Simulation Texture", 2D) = "black" {}
	
		_BaseColor("Base Color", Color) = (1.0, 1.0, 0.0, 1.0)
		_BlueprintColor("Blueprint Color", Color) = (0.0, 0.6, 0.6, 1.0)
		_ConveyorColor("Conveyor Color", Color) = (0.3, 0.3, 0.3, 1.0)
		_GroundColor("Ground Color", Color) = (0.33, 0.22, 0.1, 1.0)
		_ObstacleColor("Obstacle Color", Color) = (0.8, 0.8, 0.8, 1.0)
		_VeinEmptyColor("Vein Empty Color", Color) = (0.35, 0.3, 0.45, 1.0)
		_VeinFullColor("Vein Full Color", Color) = (0.8, 0.8, 0.8, 1.0)
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
			#include "..\ShaderIncludes\ColorSpaces.cginc"
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

			uniform float4 _BaseColor;
			uniform float4 _BlueprintColor;
			uniform float4 _ConveyorColor;
			uniform float4 _GroundColor;
			uniform float4 _ObstacleColor;
			uniform float4 _VeinEmptyColor;
			uniform float4 _VeinFullColor;

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

				float4 result = float4(1, 0, 1, 1);

				// Ordered loosely by prevelence.
				if (IsType(self.x, kTypeGround))
				{
					result = _GroundColor;
				}
				else if (IsType(self.x, kTypeConveyor))
				{
					result = _ConveyorColor;

					if (self.y >= 0.0)
					{
						float pulseFraction = smoothstep(0.8, 1, sin((0.25 * self.y) + (0.1 * _SimulationIterationIndex)));

						result = lerp(result, float4(1.0, 0.75, 0.0, 1.0), pulseFraction);
					}
				}
				else if (IsType(self.x, kTypeBlueprint))
				{
					result = _BlueprintColor;
				}
				else if (IsType(self.x, kTypeObstacle))
				{
					result = _ObstacleColor;
				}
				else if (IsType(self.x, kTypeVein))
				{
					result = lerp(_VeinEmptyColor, _VeinFullColor, smoothstep(0.0, 50.0, self.z));
				}
				else if (IsType(self.x, kTypeBase))
				{
					result = _BaseColor;
				}

				return result;
			}

			ENDCG
		}
	}
}
