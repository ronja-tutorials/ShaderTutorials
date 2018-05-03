Shader "Tutorial/08_Color_Blending/Plain"{
	//show values to edit in inspector
	Properties{
		_Color ("Color", Color) = (0, 0, 0, 1) //the base color
		_SecondaryColor ("Secondary Color", Color) = (1,1,1,1) //the color to blend to
		_Blend ("Blend Value", Range(0,1)) = 0 //0 is the first color, 1 the second
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

			//the value that's used to blend between the colors
			float _Blend;

			//the colors to blend between
			fixed4 _Color;
			fixed4 _SecondaryColor;

			//the object data that's put into the vertex shader
			struct appdata{
				float4 vertex : POSITION;
			};

			//the data that's used to generate fragments and can be read by the fragment shader
			struct v2f{
				float4 position : SV_POSITION;
			};

			//the vertex shader
			v2f vert(appdata v){
				v2f o;
				//convert the vertex positions from object space to clip space so they can be rendered
				o.position = UnityObjectToClipPos(v.vertex);
				return o;
			}

			//the fragment shader
			fixed4 frag(v2f i) : SV_TARGET{
				fixed4 col = lerp(_Color, _SecondaryColor, _Blend);
				return col;
			}

			ENDCG
		}
	}
}