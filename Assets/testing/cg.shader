Shader "custom/FromScratch"{
    SubShader{
        Pass{
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            struct appdata{
                float4 position : POSITION;
            };

            struct v2f{
                float4 position : SV_POSITION;
            };

            v2f vert(appdata i){
                v2f o;
                o.position = UnityObjectToClipPos(i.position);
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                return fixed4(1, 0.7, 0.75, 1);
            }

            ENDCG
        }
    }
}