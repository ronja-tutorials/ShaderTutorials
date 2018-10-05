Shader "Breakdown/Retrowave/Ground" {
	Properties {
		_CellSize ("Cell Size", Range(0, 64)) = 2
		_Roughness ("Roughness", Range(1, 8)) = 3
		_Persistance ("Persistance", Range(0, 1)) = 0.4
		_Amplitude("Amplitude", Range(0, 64)) = 1
		_ScrollDirection("Scroll Direction", Vector) = (0, 1, 0, 0)
		[PowerSlider(4)]_FresnelExponent("Fresnel Exponent", Range(0, 8)) = 1
		_FresnelColor ("Fresnel Color", Color) = (1,1,1,1)
		_Offset ("Negative Mountain Offset", Range(0, 50)) = 0
	}
	SubShader {
		Pass{
			Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0 

			#include "Random.cginc"
			#include "UnityCG.cginc"

			//global shader variables
			#define OCTAVES 2
			#define PI 3.14159265359

			float _CellSize;
			float _Roughness;
			float _Persistance;
			float _Amplitude;

			float2 _ScrollDirection;
			float _FresnelExponent;
			float3 _FresnelColor;
			float _Offset;

			struct v2f{
				float4 vertex : SV_POSITION;
				nointerpolation float3 normal : NORMAL;
				float3 worldpos : TEXCOORD0;
				float3 viewDir : TEXCOORD1;
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
			
			v2f vert(appdata_full data){
				float mask = sin(clamp(abs(data.vertex.x) * 100 - 0.25, 0, PI *0.5));
				mask *= _Amplitude;

				data.vertex.z += frac(_ScrollDirection.y / _Time.y) / 324;

				//get real base position
				float3 localPos = data.vertex / data.vertex.w;

				//calculate new posiiton
				float3 modifiedPos = localPos;
				float2 basePosValue = mul(unity_ObjectToWorld, modifiedPos).xz / _CellSize + float2(0, ( _Time.y * 0.38));
				float basePosNoise = sampleLayeredNoise(basePosValue) + 0.5;
				modifiedPos.y = max(0, modifiedPos.y + basePosNoise * mask - _Offset);
				
				//calculate new position based on pos + tangent
				float3 posPlusTangent = localPos + data.tangent * 0.02;
				float2 tangentPosValue = mul(unity_ObjectToWorld, posPlusTangent).xz / _CellSize;
				float tangentPosNoise = sampleLayeredNoise(tangentPosValue) + 0.5;
				posPlusTangent.y = max(0, posPlusTangent.y + tangentPosNoise * mask - _Offset);

				//calculate new position based on pos + bitangent
				float3 bitangent = cross(data.normal, data.tangent);
				float3 posPlusBitangent = localPos + bitangent * 0.02;
				float2 bitangentPosValue = mul(unity_ObjectToWorld, posPlusBitangent).xz / _CellSize;
				float bitangentPosNoise = sampleLayeredNoise(bitangentPosValue) + 0.5;
				posPlusBitangent.y = max(0, posPlusBitangent.y + bitangentPosNoise * mask - _Offset);

				//get recalculated tangent and bitangent
				float3 modifiedTangent = posPlusTangent - modifiedPos;
				float3 modifiedBitangent = posPlusBitangent - modifiedPos;

				//calculate new normal and set position + normal
				float3 modifiedNormal = cross(modifiedTangent, modifiedBitangent);

				v2f o;
				o.vertex = UnityObjectToClipPos(float4(modifiedPos.xyz, 1));
				o.worldpos = mul(unity_ObjectToWorld, modifiedPos.xyz);
				o.normal = UnityObjectToWorldNormal(normalize(modifiedNormal));
				o.viewDir = WorldSpaceViewDir(data.vertex);
				return o;
			}

			float3 frag (v2f i) : SV_TARGET {
				float3 viewDir = normalize(i.viewDir);
				float3 fresnel = dot(i.normal, viewDir);
				fresnel = saturate(1 - fresnel);
				fresnel = pow(fresnel, _FresnelExponent);
				fresnel = fresnel * _FresnelColor;
				float2 fraction = frac(i.worldpos.xz / 4 - float2(0, frac(_ScrollDirection.y / _Time.y)));
				float2 aa = fwidth(fraction);
				float2 grid = smoothstep(aa, 0, fraction) + smoothstep(1 - aa, 1, fraction);
				return fresnel + grid.x + grid.y;
			}
			ENDCG
		}
	}
	FallBack "Standard"
}