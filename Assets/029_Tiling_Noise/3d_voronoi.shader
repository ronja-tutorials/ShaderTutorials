Shader "Tutorial/029_tiling_noise/repeating_3d_voronoi" {
	Properties {
		_Height ("Z coordinate (height)", Range(0, 1)) = 0
		_CellAmount ("Cell Amount", Range(1, 32)) = 2
		_Period ("Repeat every X cells", Vector) = (4, 4, 4, 0)
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
			float3 _Period;
			float _Height;

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

			float3 modulo(float3 divident, float3 divisor){
				float3 positiveDivident = divident % divisor + divisor;
				return positiveDivident % divisor;
			}

			float3 voronoiNoise(float3 value, float3 period){
				float3 baseCell = floor(value);

				//first pass to find the closest cell
				float minDistToCell = 10;
				float3 toClosestCell;
				float3 closestCell;
				[unroll]
				for(int x1=-1; x1<=1; x1++){
					[unroll]
					for(int y1=-1; y1<=1; y1++){
						[unroll]
						for(int z1=-1; z1<=1; z1++){
							float3 cell = baseCell + float3(x1, y1, z1);
							float3 tiledCell = modulo(cell, period);
							float3 cellPosition = cell + rand3dTo3d(tiledCell);
							float3 toCell = cellPosition - value;
							float distToCell = length(toCell);
							if(distToCell < minDistToCell){
								minDistToCell = distToCell;
								closestCell = cell;
								toClosestCell = toCell;
							}
						}
					}
				}

				//second pass to find the distance to the closest edge
				float minEdgeDistance = 10;
				[unroll]
				for(int x2=-1; x2<=1; x2++){
					[unroll]
					for(int y2=-1; y2<=1; y2++){
						[unroll]
						for(int z2=-1; z2<=1; z2++){
							float3 cell = baseCell + float3(x2, y2, z2);
							float3 tiledCell = modulo(cell, period);
							float3 cellPosition = cell + rand3dTo3d(tiledCell);
							float3 toCell = cellPosition - value;

							float3 diffToClosestCell = abs(closestCell - cell);
							bool isClosestCell = diffToClosestCell.x + diffToClosestCell.y + diffToClosestCell.z < 0.1;
							if(!isClosestCell){
								float3 toCenter = (toClosestCell + toCell) * 0.5;
								float3 cellDifference = normalize(toCell - toClosestCell);
								float edgeDistance = dot(toCenter, cellDifference);
								minEdgeDistance = min(minEdgeDistance, edgeDistance);
							}
						}
					}
				}

				float random = rand3dTo1d(closestCell);
				return float3(minDistToCell, random, minEdgeDistance);
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
				float3 value = float3(i.uv, _Height) * _CellAmount;
				//get noise and adjust it to be ~0-1 range
				float noise = voronoiNoise(value, _Period).z;

				return noise;
			}
			ENDCG
		}
	}
	FallBack "Standard"
}