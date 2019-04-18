Shader "Tutorial/041_HSV/HueCycle"{
	//show values to edit in inspector
	Properties{
		_Hue ("Hue", Range(0, 1)) = 0
		_MainTex ("Texture", 2D) = "white" {}
	}

	SubShader{
		//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		Pass{
			CGPROGRAM

			//include useful shader functions
			#include "UnityCG.cginc"
            #include "HSVLibrary.cginc"

			//define vertex and fragment shader
			#pragma vertex vert
			#pragma fragment frag

            //Hue to render
			float _Hue;

			sampler2D _MainTex;
			float4 _MainTex_ST;

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
				o.uv = v.uv;
				return o;
			}

			//the fragment shader
			fixed4 frag(v2f i) : SV_TARGET{
				float3 col = tex2D(_MainTex, i.uv);
				float3 hsv = rgb2hsv(col);
				hsv.x += _Time.y;
				col = hsv2rgb(hsv);
				return float4(col, 1);
			}

			ENDCG
		}
	}
}