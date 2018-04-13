Shader "Tutorial/00_Basic"{
	SubShader{
		Pass{
			CGPROGRAM
			#include "UnityCG.cginc"

			#pragma vertex vert
			#pragma fragment frag

			struct vertex2fragment{
				float4 position : SV_POSITION;
			};

			vertex2fragment vert(appdata_base vertex_input){
				vertex2fragment output;
				output.position = UnityObjectToClipPos(vertex_input.vertex);
				return output;
			}

			fixed4 frag() : SV_TARGET{
				return fixed4(0.5, 0, 0, 1);
			}

			ENDCG
		}
	}
}