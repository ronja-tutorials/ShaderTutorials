Shader "Tutorial/028_voronoi_noise/2d" {
	Properties {
		_CellSize ("Cell Size", Range(0, 2)) = 2
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

		float4 voronoiNoise(float2 value){
			float2 baseCell = floor(value);
			float2 sampleBaseCellPos = frac(value);

			float minDistance = 10;
			float2 minDiff;
			float2 closestCell;
			float3 cellValue;
			[unroll]
			for(int x1=-1;x1<=1;x1++){
				[unroll]
				for(int y1=-1;y1<=1;y1++){
					float2 cellOffset = float2(x1, y1);
					float2 sampleCellPos = sampleBaseCellPos - float2(x1, y1);
					float2 cellPosition = rand2dTo2d(baseCell + cellOffset);
					float2 diff = cellPosition - sampleCellPos;
					float sqrDistance = diff.x * diff.x + diff.y * diff.y;
					if(minDistance > sqrDistance){
						minDistance = sqrDistance;
						minDiff = diff;
						closestCell = cellOffset;
						cellValue = rand2dTo3d(baseCell + cellOffset);
					}
				}
			}

			minDistance = 10;
			[unroll]
			for(int x2=-2;x2<=2;x2++){
				[unroll]
				for(int y2=-2;y2<=2;y2++){
					float2 cellOffset = closestCell + float2(x2, y2);
					float2 cellPosition = rand2dTo2d(baseCell + cellOffset);

					float2 relativePosition = cellOffset + cellPosition;
					float2 diff = relativePosition - sampleBaseCellPos;

					float2 differenceOffset = minDiff - diff;
					float differenceOffsetLength = differenceOffset.x * differenceOffset.x + differenceOffset.y * differenceOffset.y;

					if(differenceOffsetLength > 0.0000001){
						float uuh = dot(0.5*(minDiff+diff), normalize(diff-minDiff));
						minDistance = min(minDistance, uuh);
					}
				}
			}

			float4 noise = float4(cellValue, minDistance);
			return noise;
		}

		void surf (Input i, inout SurfaceOutputStandard o) {
			float2 value = i.worldPos.xz / _CellSize;
			//get noise and adjust it to be ~0-1 range
			float4 noise = voronoiNoise(value);
			float aa = fwidth(value.x);
			float3 color = lerp(0, noise.rgb, smoothstep(0.05-aa, 0.05+aa, noise.a));

			o.Albedo = color;
		}
		ENDCG
	}
	FallBack "Standard"
}