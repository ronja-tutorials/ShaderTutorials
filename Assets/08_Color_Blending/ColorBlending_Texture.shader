Shader "Tutorial/08_Color_Blending/Texture"{
	Properties{
		//_Color ("Color", Color) = (0, 0, 0, 1) //the base color
		//_SecondaryColor ("Secondary Color", Color) = (1,1,1,1) //the color to blend to
		_MainTex ("Texture", 2D) = "white" {}
		_SecondaryTex ("Secondary Texture", 2D) = "white" {}
		_Blend ("Blend Value", Range(0,1)) = 0
	}

	SubShader{
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		Pass{
			CGPROGRAM

			#include "UnityCG.cginc"

			#pragma vertex vert
			#pragma fragment frag

			float _Blend;

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _SecondaryTex;
			float4 _SecondaryTex_ST;

			//fixed4 _Color;
			//fixed4 _SecondaryColor;

			struct appdata{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f{
				float4 position : SV_POSITION;
				float2 main_uv : TEXCOORD0;
				float2 secondary_uv : TEXCOORD1;
			};

			v2f vert(appdata v){
				v2f o;
				o.position = UnityObjectToClipPos(v.vertex);
				o.main_uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.secondary_uv = TRANSFORM_TEX(v.uv, _SecondaryTex);
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{
				fixed4 mainColor = tex2D(_MainTex, i.main_uv);
				fixed4 secondaryColor = tex2D(_SecondaryTex, i.secondary_uv);

				fixed4 col = lerp(mainColor, secondaryColor, _Blend);
				return col;
			}

			ENDCG
		}
	}
}