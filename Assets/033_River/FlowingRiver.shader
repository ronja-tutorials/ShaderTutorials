Shader "Tutorial/033_River" {
	Properties {
		_Color ("Base Color", Color) = (1,1,1,1)

        [Header(Spec Layer 1)]
		_Specs1 ("Specs", 2D) = "white" {}
        _SpecColor1 ("Spec Color", Color) = (1,1,1,1)
        _SpecDirection1 ("Spec Direction", Vector) = (0, 1, 0, 0)

        [Header(Spec Layer 2)]
		_Specs2 ("Specs", 2D) = "white" {}
        _SpecColor2 ("Spec Color", Color) = (1,1,1,1)
        _SpecDirection2 ("Spec Direction", Vector) = (0, 1, 0, 0)

        [Header(Foam)]
        _FoamNoise("Foam Noise", 2D) = "white" {}
        _FoamDirection ("Foam Direction", Vector) = (0, 1, 0, 0)
        _FoamColor ("Foam Color", Color) = (1,1,1,1)
        _FoamAmount ("Foam Amount", Range(0, 2)) = 1
	}
	SubShader {
		Tags { "RenderType"="Transparent" "Queue"="Transparent" "ForceNoShadowCasting"="True"}
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types, then set it to render transparent
		#pragma surface surf Standard vertex:vert fullforwardshadows alpha

		#pragma target 4.0

		struct Input {
			float2 uv_Specs1;
            float2 uv_Specs2;
            float2 uv_FoamNoise;
            float eyeDepth;
            float4 screenPos;
		};

        sampler2D_float _CameraDepthTexture;

		fixed4 _Color;

        sampler2D _Specs1;
        fixed4 _SpecColor1;
        float2 _SpecDirection1;

        sampler2D _Specs2;
        fixed4 _SpecColor2;
        float2 _SpecDirection2;

        sampler2D _FoamNoise;
        fixed4 _FoamColor;
        float _FoamAmount;
        float2 _FoamDirection;

        void vert (inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            COMPUTE_EYEDEPTH(o.eyeDepth);
        }

		void surf (Input IN, inout SurfaceOutputStandard o) {
            //set river base color
			fixed4 col = _Color;

            //add first layer of moving specs
            float2 specCoordinates1 = IN.uv_Specs1 + _SpecDirection1 * _Time.y;
            fixed4 specLayer1 = tex2D(_Specs1, specCoordinates1) * _SpecColor1;
            col.rgb = lerp(col.rgb, specLayer1.rgb, specLayer1.a);
            col.a = lerp(col.a, 1, specLayer1.a);

            //add second layer of moving specs
            float2 specCoordinates2 = IN.uv_Specs2 + _SpecDirection2 * _Time.y;
            fixed4 specLayer2 = tex2D(_Specs2, specCoordinates2) * _SpecColor2;
            col.rgb = lerp(col.rgb, specLayer2.rgb, specLayer2.a);
            col.a = lerp(col.a, 1, specLayer2.a);

            //get scene and surface depth
            float4 projCoords = UNITY_PROJ_COORD(IN.screenPos);
            float rawZ = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, projCoords);
            float sceneZ = LinearEyeDepth(rawZ);
            float surfaceZ = IN.eyeDepth;

            //add foam
            float2 foamCoords = IN.uv_FoamNoise + _FoamDirection * _Time.y;
            float foamNoise = tex2D(_FoamNoise, foamCoords).r;
            float foam = 1-((sceneZ - surfaceZ) / _FoamAmount);
            foam = saturate(foam - foamNoise);
            col.rgb = lerp(col.rgb, _FoamColor.rgb, foam);
            col.a = lerp(col.a, 1, foam * _FoamColor.a);

            //apply values to output struct
			o.Albedo = col.rgb;
			o.Alpha = col.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
