Shader "Tutorial/038_dissolve" {
	Properties {
		_Color ("Tint", Color) = (0, 0, 0, 1)
		_MainTex ("Texture", 2D) = "white" {}
		_Smoothness ("Smoothness", Range(0, 1)) = 0
		_Metallic ("Metalness", Range(0, 1)) = 0
		[HDR] _Emission ("Emission", color) = (0,0,0)

        [Header(Dissolve)]
        _DissolveTex ("Dissolve Texture", 2D) = "black" {}
        _DissolveAmount ("Dissolve Amount", Range(0, 1)) = 0.5

        [Header(Glow)]
        [HDR]_GlowColor("Color", Color) = (1, 1, 1, 1)
        _GlowRange("Range", Range(0, .3)) = 0.1
        _GlowFalloff("Falloff", Range(0.001, .3)) = 0.1
	}
	SubShader {
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		CGPROGRAM

		#pragma surface surf Standard fullforwardshadows
		#pragma target 3.0

		sampler2D _MainTex;
		fixed4 _Color;

		half _Smoothness;
		half _Metallic;
		half3 _Emission;

        sampler2D _DissolveTex;
        float _DissolveAmount;

        float3 _GlowColor;
        float _GlowRange;
        float _GlowFalloff;

		struct Input {
			float2 uv_MainTex;
            float2 uv_DissolveTex;
		};

		void surf (Input i, inout SurfaceOutputStandard o) {
            float dissolve = tex2D(_DissolveTex, i.uv_DissolveTex).r;
            dissolve = dissolve * 0.999;
            float isVisible = dissolve - _DissolveAmount;
            clip(isVisible);

            float isGlowing = smoothstep(_GlowRange + _GlowFalloff, _GlowRange, isVisible);
            float3 glow = isGlowing * _GlowColor;

            fixed4 col = tex2D(_MainTex, i.uv_MainTex);
			col *= _Color;

			o.Albedo = col;
			o.Metallic = _Metallic;
			o.Smoothness = _Smoothness;
			o.Emission = _Emission + glow;
		}
		ENDCG
	}
	FallBack "Standard"
}