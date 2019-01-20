Shader "Tutorial/future/040_DitheredLighting" {
	//show values to edit in inspector
	Properties{
		_Color("Tint", Color) = (0, 0, 0, 1)
		_MainTex("Texture", 2D) = "white" {}

		_ShadowIntensity("Shadow Intensity", Range(0, 1)) = 1

		[Header(Shadow Core)]
		_ShadowCoreTex("Texture", 2D) = "white" {}
		_ShadowCoreSize("Size", Range(0, 1)) = 0.5
		_ShadowCoreSoftness("Softness", Range(0, 1)) = 0.2
	}
		SubShader{
		//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
		Tags{ "RenderType" = "Opaque" "Queue" = "Geometry"}

		CGPROGRAM

		//the shader is a surface shader, meaning that it will be extended by unity in the background to have fancy lighting and other features
		//our surface shader function is called surf and we use our custom lighting model
		//fullforwardshadows makes sure unity adds the shadow passes the shader might need
		#pragma surface surf Custom fullforwardshadows
		#pragma target 3.0

		sampler2D _MainTex;
		fixed4 _Color;
		float _ShadowIntensity;
		float _ShadowCoreSize;
		float _ShadowCoreSoftness;

		sampler2D _ShadowCoreTex;
		float4 _ShadowCoreTex_ST;

		//input struct which is automatically filled by unity
		struct Input {
			float2 uv_MainTex;
			float4 screenPos;
		};

		struct ToonSurfaceOutput {
			fixed3 Albedo;
			fixed3 Normal;
			half3 Emission;
			fixed Alpha;
			float2 screenUV;
		};

		//our lighting function. Will be called once per light
		float4 LightingCustom(ToonSurfaceOutput s, float3 lightDir, float atten) {
			//how much does the normal point towards the light?
			float towardsLight = dot(s.Normal, lightDir);
			float shadow = saturate(towardsLight) * atten;
			shadow = lerp(_ShadowIntensity, 1, shadow);
			
			float shadowCoreIntensity = smoothstep(-1 + _ShadowCoreSize, -1 + _ShadowCoreSize - _ShadowCoreSoftness, towardsLight);
			float shadowCoreTexture = tex2D(_ShadowCoreTex, TRANSFORM_TEX(s.screenUV, _ShadowCoreTex)).r;
			float shadowCore = lerp(shadowCoreTexture, 1, 1-shadowCoreIntensity);

			shadow = shadow * shadowCore;

			//combine the color
			float4 col;
			//intensity we calculated previously, diffuse color, light falloff and shadowcasting, color of the light
			col.rgb = shadow * s.Albedo * _LightColor0.rgb;

			col.a = 1;

			return col;
		}

		//the surface shader function which sets parameters the lighting function then uses
		void surf(Input i, inout ToonSurfaceOutput o) {
			//sample and tint albedo texture
			fixed4 col = tex2D(_MainTex, i.uv_MainTex);
			col *= _Color;
			o.Albedo = col.rgb;
			o.screenUV = i.screenPos.xy / i.screenPos.w;
		}
		ENDCG
	}
		FallBack "Standard"
}