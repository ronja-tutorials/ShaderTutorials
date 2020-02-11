Shader "Tutorial/003_Properties"{
	//show values to edit in inspector
	Properties{
		_Color ("Color", Color) = (0, 0, 0, 1)
	}

	SubShader{
		//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		Pass{
			CGPROGRAM
			#include "UnityCG.cginc"

			#pragma vertex vert
			#pragma fragment frag

			fixed4 _Color;

			struct appdata{
				float4 vertex : POSITION;
			};

			struct v2f{
				float4 position : SV_POSITION;
			};

			v2f vert(appdata v){
				v2f o;
				//calculate the position in clip space to render the object
				o.position = UnityObjectToClipPos(v.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{
				//Return the color the Object is rendered in
				return _Color;
			}

			ENDCG
		}
	}
}
