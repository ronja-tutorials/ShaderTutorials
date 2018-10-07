Shader "Tutorial/029_material_baking/layered_repeating_perlin" {
	Properties {
		_CellAmount ("Cell Amount", Range(1, 32)) = 2
		_Period ("Repeat every X cells", Vector) = (4, 4, 0, 0)
		[IntRange]_Roughness ("Roughness", Range(1, 8)) = 3
		_Persistance ("Persistance", Range(0, 1)) = 0.4
	}
	SubShader {
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		Pass{
			CGPROGRAM

			//include useful shader functions
			#include "UnityCG.cginc"

			//define vertex and fragment shader
			#pragma vertex vert
			#pragma fragment frag

			#pragma target 3.0

			#include "Random.cginc"

			//global shader variables
			#define OCTAVES 4 

			float _CellAmount;
			float _Roughness;
			float _Persistance;
			float2 _Period;

			//the object data that's put into the vertex shader
			struct appdata{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			//the data that's used to generate fragments and can be read by the fragment shader
			struct v2f{
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
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

			float2 modulo(float2 divident, float2 divisor){
				float2 positiveDivident = divident % divisor + divisor;
				return positiveDivident % divisor;
			}

			float perlinNoise(float2 value, float2 period){
				float2 cellsMimimum = floor(value);
				float2 cellsMaximum = ceil(value);

				cellsMimimum = modulo(cellsMimimum, period);
				cellsMaximum = modulo(cellsMaximum, period);

				//generate random directions
				float2 lowerLeftDirection = rand2dTo2d(float2(cellsMimimum.x, cellsMimimum.y)) * 2 - 1;
				float2 lowerRightDirection = rand2dTo2d(float2(cellsMaximum.x, cellsMimimum.y)) * 2 - 1;
				float2 upperLeftDirection = rand2dTo2d(float2(cellsMimimum.x, cellsMaximum.y)) * 2 - 1;
				float2 upperRightDirection = rand2dTo2d(float2(cellsMaximum.x, cellsMaximum.y)) * 2 - 1;

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
					noise = noise + perlinNoise(value * frequency + i * 0.72354, _Period * frequency) * factor;
					factor *= _Persistance;
					frequency *= _Roughness;
				}

				return noise;
			}

			//the vertex shader
			v2f vert(appdata v){
				v2f o;
				//convert the vertex positions from object space to clip space so they can be rendered
				o.position = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			float4 frag (v2f i) : SV_TARGET{
				float2 value = i.uv * _CellAmount;
				//get noise and adjust it to be ~0-1 range
				float noise = sampleLayeredNoise(value) + 0.5;

				return noise;
			}
			ENDCG
		}
	}
	FallBack "Standard"
}