Shader "Tutorial/025_value_noise/1d" {
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

		void surf (Input i, inout SurfaceOutputStandard o) {
			float value = i.worldPos.x / _CellSize;
			float previousCellNoise = rand1dTo1d(floor(value));
			float nextCellNoise = rand1dTo1d(ceil(value));
			float interpolator = frac(value);
			interpolator = easeInOut(interpolator);
			float noise = lerp(previousCellNoise, nextCellNoise, interpolator);

			float dist = abs(noise - i.worldPos.y);
			float pixelHeight = fwidth(i.worldPos.y);
			float lineIntensity = smoothstep(0, pixelHeight, dist);
			o.Albedo = lineIntensity;
		}
		ENDCG
	}
	FallBack "Standard"
}