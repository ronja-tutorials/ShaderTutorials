Shader "Tutorial/042_Dithering/DistanceFade"{
	//show values to edit in inspector
	Properties{
		_MainTex ("Texture", 2D) = "white" {}
		_Color ("Tint", Color) = (1,1,1,1)
        _DitherPattern ("Dithering Pattern", 2D) = "white" {}
		_MinDistance ("Minimum Fade Distance", Float) = 0
		_MaxDistance ("Maximum Fade Distance", Float) = 1
	}

	SubShader {
		//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		CGPROGRAM

		//the shader is a surface shader, meaning that it will be extended by unity in the background to have fancy lighting and other features
		//our surface shader function is called surf and we use our custom lighting model
		#pragma surface surf Standard
		#pragma target 3.0

		//texture and tint of color
		sampler2D _MainTex;
		float4 _Color;

		//The dithering pattern
		sampler2D _DitherPattern;
		float4 _DitherPattern_TexelSize;

		//remapping of distance
		float _MinDistance;
		float _MaxDistance;

		//input struct which is automatically filled by unity
		struct Input {
			float2 uv_MainTex;
			float4 screenPos;
		};

		//the surface shader function which sets parameters the lighting function then uses
		void surf (Input i, inout SurfaceOutputStandard o) {
			//read texture and write it to diffuse color
			float3 texColor = tex2D(_MainTex, i.uv_MainTex);
			o.Albedo = texColor.rgb * _Color;

			//value from the dither pattern
			float2 screenPos = i.screenPos.xy / i.screenPos.w;
			float2 ditherCoordinate = screenPos * _ScreenParams.xy * _DitherPattern_TexelSize.xy;
			float ditherValue = tex2D(_DitherPattern, ditherCoordinate).r;

			//get relative distance from the camera
			float relDistance = i.screenPos.w;
			relDistance = relDistance - _MinDistance;
			relDistance = relDistance / (_MaxDistance - _MinDistance);
			//discard pixels accordingly
			clip(relDistance - ditherValue);
		}
		ENDCG
	}
}