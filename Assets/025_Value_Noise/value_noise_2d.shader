Shader "Tutorial/025_value_noise/2d" {
	Properties {
		_CellSize ("Cell Size", Range(0, 1)) = 1
	}
	SubShader {
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		CGPROGRAM

		#pragma surface surf Standard fullforwardshadows
		#pragma target 3.0

		#include "Random.cginc"

		float _CellSize;

		struct Input {
			float3 worldPos;
		};

		float easeIn(float interpolator){
			return interpolator * interpolator;
		}

		float easeOut(float interpolator){
			return 1 - easeIn(1 - interpolator);
		}

		float easeInOut(float interpolator){
			float easeInValue = easeIn(interpolator);
			float easeOutValue = easeOut(interpolator);
			return lerp(easeInValue, easeOutValue, interpolator);
		}

		float ValueNoise2d(float2 value){
			float upperLeftCell = rand2dTo1d(float2(floor(value.x), ceil(value.y)));
			float upperRightCell = rand2dTo1d(float2(ceil(value.x), ceil(value.y)));
			float lowerLeftCell = rand2dTo1d(float2(floor(value.x), floor(value.y)));
			float lowerRightCell = rand2dTo1d(float2(ceil(value.x), floor(value.y)));

			float interpolatorX = easeInOut(frac(value.x));
			float interpolatorY = easeInOut(frac(value.y));

			float upperCells = lerp(upperLeftCell, upperRightCell, interpolatorX);
			float lowerCells = lerp(lowerLeftCell, lowerRightCell, interpolatorX);

			float noise = lerp(lowerCells, upperCells, interpolatorY);
			return noise;
		}

		void surf (Input i, inout SurfaceOutputStandard o) {
			float2 value = i.worldPos.xy / _CellSize;
			float noise = ValueNoise2d(value);

			o.Albedo = noise;
		}
		ENDCG
	}
	FallBack "Standard"
}