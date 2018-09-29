Shader "Tutorial/028_voronoi_noise/2d" {
	Properties {
		_CellSize ("Cell Size", Range(0, 2)) = 2
		_BorderColor ("Border Color", Color) = (0,0,0,1)
	}
	SubShader {
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		CGPROGRAM

		#pragma surface surf Standard fullforwardshadows
		#pragma target 3.0

		#include "Random.cginc"

		float _CellSize;
		float3 _BorderColor;

		struct Input {
			float3 worldPos;
		};

		float3 voronoiNoise(float2 value){
			float2 baseCell = floor(value);

			//first pass to find the closest cell
			float minDistToCell = 10;
			float2 toClosestCell;
			float2 closestCell;
			[unroll]
			for(int x1=-1; x1<=1; x1++){
				[unroll]
				for(int y1=-1; y1<=1; y1++){
					float2 cell = baseCell + float2(x1, y1);
					float2 cellPosition = cell + rand2dTo2d(cell);
					float2 toCell = cellPosition - value;
					float distToCell = length(toCell);
					if(distToCell < minDistToCell){
						minDistToCell = distToCell;
						closestCell = cell;
						toClosestCell = toCell;
					}
				}
			}

			//second pass to find the distance to the closest edge
			float minEdgeDistance = 10;
			[unroll]
			for(int x2=-1; x2<=1; x2++){
				[unroll]
				for(int y2=-1; y2<=1; y2++){
					float2 cell = baseCell + float2(x2, y2);
					float2 cellPosition = cell + rand2dTo2d(cell);
					float2 toCell = cellPosition - value;

					float2 diffToClosestCell = abs(closestCell - cell);
					bool isClosestCell = diffToClosestCell.x + diffToClosestCell.y < 0.1;
					if(!isClosestCell){
						float2 toCenter = (toClosestCell + toCell) * 0.5;
						float2 cellDifference = normalize(toCell - toClosestCell);
						float edgeDistance = dot(toCenter, cellDifference);
						minEdgeDistance = min(minEdgeDistance, edgeDistance);
					}
				}
			}

			float random = rand2dTo1d(closestCell);
    		return float3(minDistToCell, random, minEdgeDistance);
		}

		void surf (Input i, inout SurfaceOutputStandard o) {
			float2 value = i.worldPos.xz / _CellSize;
			float3 noise = voronoiNoise(value);

			float3 cellColor = rand1dTo3d(noise.y); 
			float valueChange = length(fwidth(value)) * 0.5;
			float isBorder = 1 - smoothstep(0.05 - valueChange, 0.05 + valueChange, noise.z);
			float3 color = lerp(cellColor, _BorderColor, isBorder);
			o.Albedo = color;
		}
		ENDCG
	}
	FallBack "Standard"
}