Shader "Tutorial/034_2D_SDF_Basics/Cutoff"{
    Properties{
        _Color("Color", Color) = (1,1,1,1)
    }
	SubShader{
		Tags{ "RenderType"="Transparent" "Queue"="Transparent"}
        
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

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

            fixed3 _Color;

			v2f vert(appdata v){
				v2f o;
				//calculate the position in clip space to render the object
				o.position = UnityObjectToClipPos(v.vertex);
				//calculate world position of vertex
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}

            float scene(float2 position) {
                float2 circlePosition = position;
                circlePosition = rotate(circlePosition, _Time.y * 0.5);
                circlePosition = translate(circlePosition, float2(2, 0));
                float sceneDistance = rectangle(circlePosition, float2(1, 2));
                return sceneDistance;
            }

			fixed4 frag(v2f i) : SV_TARGET{
				float dist = scene(i.worldPos.xz);
                float distanceChange = fwidth(dist) * 0.5;
                float antialiasedCutoff = smoothstep(distanceChange, -distanceChange, dist);
                fixed4 col = fixed4(_Color, antialiasedCutoff);
				return col;
			}

			ENDCG
		}
	}
	FallBack "Standard" //fallback adds a shadow pass so we get shadows on other objects
}