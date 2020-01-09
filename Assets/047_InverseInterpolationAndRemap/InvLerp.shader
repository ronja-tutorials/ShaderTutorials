Shader "Tutorial/047_InvLerp_Remap/InvLerp"{
	//show values to edit in inspector
	Properties{
		_ZeroValue ("0 Value", Range(0, 1)) = 0 //min value
		_OneValue ("1 Color", Range(0, 1)) = 1 //max value
	}

	SubShader{
		//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		Pass{
			CGPROGRAM

			//include useful shader functions
			#include "UnityCG.cginc"
			#include "Interpolation.cginc"

			//define vertex and fragment shader
			#pragma vertex vert
			#pragma fragment frag

			//the colors to blend between
			float _ZeroValue;
			float _OneValue;

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
			    float blend = i.uv.y;
			    float result = invLerp(_ZeroValue, _OneValue, blend);
				fixed4 col = fixed4((fixed3)result, 1);
				return col;
			}

			ENDCG
		}
	}
}