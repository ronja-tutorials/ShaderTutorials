Shader "Tutorial/034_2D_SDF_Basics/Circle"{

	SubShader{
		//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		Pass{
			CGPROGRAM

			#include "UnityCG.cginc"
            #include "2D_SDF.cginc"

			#pragma vertex vert
			#pragma fragment frag

			struct appdata{
				float4 vertex : POSITION;
			};

			struct v2f{
				float4 position : SV_POSITION;
				float4 worldPos : TEXCOORD0;
			};

			v2f vert(appdata v){
				v2f o;
				//calculate the position in clip space to render the object
				o.position = UnityObjectToClipPos(v.vertex);
				//calculate world position of vertex
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}

            float scene(float2 position) {
                float2 circlePosition = translate(position, float2(3, 2));
                float sceneDistance = circle(circlePosition, 2);
                return sceneDistance;
            }

			fixed4 frag(v2f i) : SV_TARGET{
				float dist = scene(i.worldPos.xz);
                fixed4 col = fixed4(dist, dist, dist, 1);
				return col;
			}

			ENDCG
		}
	}
	FallBack "Standard" //fallback adds a shadow pass so we get shadows on other objects
}