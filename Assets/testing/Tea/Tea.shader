Shader "Custom/Tea" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Plane ("Plane", Vector) = (0, 1, 0, 0)
	}
	SubShader {
		Tags {"Queue" = "Transparent" "RenderType"="Transparent" } 

		Pass
		{
			Blend zero one
			CGPROGRAM
			#include "UnityCG.cginc"

			#pragma vertex vert
			#pragma fragment frag

			float4 _Plane;

			struct appdata{
				float4 vertex : POSITION;
			};

			struct v2f{
				float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD0;
			};

			v2f vert(appdata v){
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{
				clip(-dot(_Plane.xyz, i.worldPos) - _Plane.w);
				return 0;
			}
			ENDCG
		}

		LOD 200
		Cull Off

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf StandardDefaultGI fullforwardshadows alpha
		#include "UnityPBSLighting.cginc"

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
			float3 worldPos;
			fixed facing : VFACE;
			float4 color : COLOR;
			float3 viewDir;
		};

		half _Glossiness;
		fixed4 _Color;
		float4 _Plane;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		void vert (inout appdata_full v) {
			TANGENT_SPACE_ROTATION;
			float3 tangentUp = mul(rotation, _Plane.xyz);
			v.color = float4(tangentUp, 0);
		}

		inline half4 LightingStandardDefaultGI(SurfaceOutputStandard s, half3 viewDir, UnityGI gi)
		{
			s.Albedo = _Color.rgb;
			s.Alpha = _Color.a;
			return LightingStandard(s, viewDir, gi);
		}

		inline void LightingStandardDefaultGI_GI(
                SurfaceOutputStandard s,
                UnityGIInput data,
                inout UnityGI gi)
		{
			s.Albedo = _Color.rgb;
			s.Alpha = _Color.a;
			LightingStandard_GI(s, data, gi);
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			clip(-dot(_Plane.xyz, IN.worldPos) - _Plane.w);

			o.Smoothness = _Glossiness;
			

			if(IN.facing <= 0){
				o.Normal = IN.color.xyz;
				/* variable collection
					_WorldSpaceCameraPos
					IN.viewDir

					_Plane.xyz //normal
					_Plane.xyz * _Plane.w //origin
				*/
				float d = dot(_Plane.xyz * _Plane.w - _WorldSpaceCameraPos, _Plane.xyz) / 
						dot(IN.viewDir, _Plane.xyz);

				float3 surfacePoint = _WorldSpaceCameraPos + IN.viewDir * d;
				//o.Albedo = surfacePoint;
			}

		}
		ENDCG
	}
	FallBack "Diffuse"
}
