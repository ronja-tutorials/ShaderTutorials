Shader "Tutorial/08_Color_Blending/TextureBasedBlending"{
	Properties{
		_MainTex ("Texture", 2D) = "white" {}
		_SecondaryTex ("Secondary Texture", 2D) = "white" {}
		_BlendTex ("Blend Texture", 2D) = "grey" {}
	}

	SubShader{
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		Pass{
			CGPROGRAM

			#include "UnityCG.cginc"

			#pragma vertex vert
			#pragma fragment frag

			sampler2D _BlendTex;
			float4 _BlendTex_ST;

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _SecondaryTex;
			float4 _SecondaryTex_ST;

			struct appdata{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f{
				float4 position : SV_POSITION;
				float2 main_uv : TEXCOORD0;
				float2 secondary_uv : TEXCOORD1;
				float2 blend_uv : TEXCOORD2;
			};

			v2f vert(appdata v){
				v2f o;
				o.position = UnityObjectToClipPos(v.vertex);
				o.main_uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.secondary_uv = TRANSFORM_TEX(v.uv, _SecondaryTex);
				o.blend_uv = TRANSFORM_TEX(v.uv, _BlendTex);
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{
				fixed4 mainColor = tex2D(_MainTex, i.main_uv);
				fixed4 secondaryColor = tex2D(_SecondaryTex, i.secondary_uv);
				fixed blend = tex2D(_BlendTex, i.blend_uv).r;

				fixed4 col = lerp(mainColor, secondaryColor, blend);
				return col;
			}

			ENDCG
		}
	}
}