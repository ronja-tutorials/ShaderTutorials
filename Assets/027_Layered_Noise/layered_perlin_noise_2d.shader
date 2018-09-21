Shader "Tutorial/027_layered_noise/2d" {
	Properties {
		_CellSize ("Cell Size", Range(0, 2)) = 2
		_Roughness ("Roughness", Range(1, 8)) = 3
		_Persistance ("Persistance", Range(0, 1)) = 0.4
	}
	SubShader {
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		CGPROGRAM

		#pragma surface surf Standard fullforwardshadows
		#pragma target 3.0

		#include "Random.cginc"

		//global shader variables
		#define OCTAVES 4 

		float _CellSize;
		float _Roughness;
		float _Persistance;

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

		float perlinNoise(float2 value){
			//generate random directions
			float2 lowerLeftDirection = rand2dTo2d(float2(floor(value.x), floor(value.y))) * 2 - 1;
			float2 lowerRightDirection = rand2dTo2d(float2(ceil(value.x), floor(value.y))) * 2 - 1;
			float2 upperLeftDirection = rand2dTo2d(float2(floor(value.x), ceil(value.y))) * 2 - 1;
			float2 upperRightDirection = rand2dTo2d(float2(ceil(value.x), ceil(value.y))) * 2 - 1;

			float2 fraction = frac(value);

			//get values of cells based on fraction and cell directions
			float lowerLeftFunctionValue = dot(lowerLeftDirection, fraction - float2(0, 0));
			float lowerRightFunctionValue = dot(lowerRightDirection, fraction - float2(1, 0));
			float upperLeftFunctionValue = dot(upperLeftDirection, fraction - float2(0, 1));
			float upperRightFunctionValue = dot(upperRightDirection, fraction - float2(1, 1));

			float interpolatorX = easeInOut(fraction.x);
			float interpolatorY = easeInOut(fraction.y);

			//interpolate between values
			float lowerCells = lerp(lowerLeftFunctionValue, lowerRightFunctionValue, interpolatorX);
			float upperCells = lerp(upperLeftFunctionValue, upperRightFunctionValue, interpolatorX);

			float noise = lerp(lowerCells, upperCells, interpolatorY);
			return noise;
		}

		float sampleLayeredNoise(float2 value){
			float noise = 0;
			float frequency = 1;
			float factor = 1;

			[unroll]
			for(int i=0; i<OCTAVES; i++){
				noise = noise + perlinNoise(value * frequency + i * 0.72354) * factor;
				factor *= _Persistance;
				frequency *= _Roughness;
			}

			return noise;
		}

		void surf (Input i, inout SurfaceOutputStandard o) {
			float2 value = i.worldPos.xz / _CellSize;
			//get noise and adjust it to be ~0-1 range
			float noise = sampleLayeredNoise(value) + 0.5;

			o.Albedo = noise;
		}
		ENDCG
	}
	FallBack "Standard"
}