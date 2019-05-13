Shader "Tutorial/042_Dithering/DistanceFade"{
	//show values to edit in inspector
	Properties{
		_MainTex ("Texture", 2D) = "white" {}
        _DitherPattern ("Dithering Pattern", 2D) = "white" {}
		_MinDistance ("Minimum Fade Distance", Float) = 0
		_MaxDistance ("Maximum Fade Distance", Float) = 1
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
			sampler2D _MainTex;
			float4 _MainTex_ST;

            //The dithering pattern
            sampler2D _DitherPattern;
            float4 _DitherPattern_TexelSize;

			//remapping of distance
			float _MinDistance;
			float _MaxDistance;

			//the object data that's put into the vertex shader
			struct appdata{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			//the data that's used to generate fragments and can be read by the fragment shader
			struct v2f{
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
                float4 screenPosition : TEXCOORD1;
			};

			//the vertex shader
			v2f vert(appdata v){
				v2f o;
				//convert the vertex positions from object space to clip space so they can be rendered
				o.position = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenPosition = ComputeScreenPos(o.position);
				return o;
			}

			//the fragment shader
			fixed4 frag(v2f i) : SV_TARGET{
				float distance = i.screenPosition.w;
				distance = distance / (_MaxDistance - _MinDistance) - _MinDistance;

                float2 screenPos = i.screenPosition.xy / i.screenPosition.w;
                float2 ditherCoordinate = screenPos * _ScreenParams.xy * _DitherPattern_TexelSize.xy;
				float ditherValue = tex2D(_DitherPattern, ditherCoordinate).r;

				clip(distance - ditherValue);

                float4 col = tex2D(_MainTex, i.uv);
				return col;
			}

			ENDCG
		}
	}

    Fallback "Standard"
}