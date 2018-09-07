Shader "Tutorial/025_value_noise/3d" {
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

		float3 ValueNoise3d(float3 value){
			float interpolatorX = easeInOut(frac(value.x));
			float interpolatorY = easeInOut(frac(value.y));
			float interpolatorZ = easeInOut(frac(value.z));

			float3 cellNoiseZ[2];
			[unroll]
			for(int z=0;z<=1;z++){
				float3 cellNoiseY[2];
				[unroll]
				for(int y=0;y<=1;y++){
					float3 cellNoiseX[2];
					[unroll]
					for(int x=0;x<=1;x++){
						float3 cell = floor(value) + float3(x, y, z);
						cellNoiseX[x] = rand3dTo3d(cell);
					}
					cellNoiseY[y] = lerp(cellNoiseX[0], cellNoiseX[1], interpolatorX);
				}
				cellNoiseZ[z] = lerp(cellNoiseY[0], cellNoiseY[1], interpolatorY);
			}
			float3 noise = lerp(cellNoiseZ[0], cellNoiseZ[1], interpolatorZ);
			return noise;
		}

		void surf (Input i, inout SurfaceOutputStandard o) {
			float3 value = i.worldPos.xyz / _CellSize;
			float3 noise = ValueNoise3d(value);

			o.Albedo = noise;
		}
		ENDCG
	}
	FallBack "Standard"
}