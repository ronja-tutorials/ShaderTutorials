Shader "Tutorial/030_BakeTextures/Read3dTexture"
{
	//show values to edit in inspector
	Properties{
        _Height("Height", Range(0, 1)) = 0
		_Color ("Tint", Color) = (0, 0, 0, 1)
		_MainTex ("Texture", 3D) = "white" {}
	}

	SubShader{
		//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		Pass{
			CGPROGRAM

			//include useful shader functions
			#include "UnityCG.cginc"

			//define vertex and fragment shader
			#pragma vertex vert
			#pragma fragment frag

			//texture and transforms of the texture
			sampler3D _MainTex;
			float4 _MainTex_ST;

			//tint of the texture
			fixed4 _Color;

            float _Height;

			//the object data that's put into the vertex shader
			struct appdata{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			//the data that's used to generate fragments and can be read by the fragment shader
			struct v2f{
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			//the vertex shader
			v2f vert(appdata v){
				v2f o;
				//convert the vertex positions from object space to clip space so they can be rendered
				o.position = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			//the fragment shader
			fixed4 frag(v2f i) : SV_TARGET{
				fixed4 col = tex3D(_MainTex, float3(i.uv, _Height));
				col *= _Color;
				return col;
			}

			ENDCG
		}
	}
}
