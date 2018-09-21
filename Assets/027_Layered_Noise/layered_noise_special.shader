Shader "Tutorial/027_layered_noise/special_use_case" {
	Properties {
		_CellSize ("Cell Size", Range(0, 16)) = 2
		_Roughness ("Roughness", Range(1, 8)) = 3
		_Persistance ("Persistance", Range(0, 1)) = 0.4
		_Amplitude("Amplitude", Range(0, 10)) = 1
		_ScrollDirection("Scroll Direction", Vector) = (0, 1, 0, 0)
	}
	SubShader {
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		CGPROGRAM

		#pragma surface surf Standard fullforwardshadows vertex:vert addshadow
		#pragma target 3.0 

		#include "Random.cginc"

		//global shader variables
		#define OCTAVES 4 

		float _CellSize;
		float _Roughness;
		float _Persistance;
		float _Amplitude;

		float2 _ScrollDirection;

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
		
		void vert(inout appdata_full data){
			//get real base position
			float3 localPos = data.vertex / data.vertex.w;

			//calculate new posiiton
			float3 modifiedPos = localPos;
			float2 basePosValue = mul(unity_ObjectToWorld, modifiedPos).xz / _CellSize + _ScrollDirection * _Time.y;
			float basePosNoise = sampleLayeredNoise(basePosValue) + 0.5;
			modifiedPos.y += basePosNoise * _Amplitude;
			
			//calculate new position based on pos + tangent
			float3 posPlusTangent = localPos + data.tangent * 0.02;
			float2 tangentPosValue = mul(unity_ObjectToWorld, posPlusTangent).xz / _CellSize + _ScrollDirection * _Time.y;
			float tangentPosNoise = sampleLayeredNoise(tangentPosValue) + 0.5;
			posPlusTangent.y += tangentPosNoise * _Amplitude;

			//calculate new position based on pos + bitangent
			float3 bitangent = cross(data.normal, data.tangent);
			float3 posPlusBitangent = localPos + bitangent * 0.02;
			float2 bitangentPosValue = mul(unity_ObjectToWorld, posPlusBitangent).xz / _CellSize + _ScrollDirection * _Time.y;
			float bitangentPosNoise = sampleLayeredNoise(bitangentPosValue) + 0.5;
			posPlusBitangent.y += bitangentPosNoise * _Amplitude;

			//get recalculated tangent and bitangent
			float3 modifiedTangent = posPlusTangent - modifiedPos;
			float3 modifiedBitangent = posPlusBitangent - modifiedPos;

			//calculate new normal and set position + normal
			float3 modifiedNormal = cross(modifiedTangent, modifiedBitangent);
			data.normal = normalize(modifiedNormal);
			data.vertex = float4(modifiedPos.xyz, 1);
		}

		void surf (Input i, inout SurfaceOutputStandard o) {
			o.Albedo = 1;
		}
		ENDCG
	}
	FallBack "Standard"
}