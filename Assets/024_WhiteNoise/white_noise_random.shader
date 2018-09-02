Shader "Tutorial/024_white_noise/random" {
	Properties {
	}
	SubShader {
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		CGPROGRAM

		#pragma surface surf Standard fullforwardshadows
		#pragma target 3.0

		#include "WhiteNoise.cginc"

		struct Input {
			float3 worldPos;
		};

		void surf (Input i, inout SurfaceOutputStandard o) {
			float3 value = i.worldPos;
			o.Albedo = rand3dTo3d(value);
		}
		ENDCG
	}
	FallBack "Standard"
}