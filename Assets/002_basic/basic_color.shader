Shader "Tutorial/002_Basic"{
	SubShader{
		Pass{
			//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
			Tags{"RenderType"="Opaque" "Queue"="Geometry"}

			CGPROGRAM
			#include "UnityCG.cginc"

			#pragma vertex vert
			#pragma fragment frag

			struct appdata{
				float4 vertex : POSITION;
			};

			struct v2f{
				float4 position : SV_POSITION;
			};

			v2f vert(appdata v){
				v2f o;
				o.position = UnityObjectToClipPos(v.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{
				return fixed4(0.5, 0, 0, 1);
			}

			ENDCG
		}
	}
}