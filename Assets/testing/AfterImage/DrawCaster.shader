Shader "Hidden/DrawCaster"{
	//show values to edit in inspector
	Properties{
		[PerRendererData]_Color ("Color", Color) = (0, 0, 0, 1)
	}

	SubShader{
		//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

        ZTest Always
        ZWrite On

		Pass{
			CGPROGRAM
            #pragma multi_compile_instancing

			#include "UnityCG.cginc"

			#pragma vertex vert
			#pragma fragment frag


			fixed4 _Color;
            sampler2D _DepthTexture;

			struct appdata{
				float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f{
				float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float2 depth : TEXCOORD1;
			};

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float4x4, _MvpMatrix)
            UNITY_INSTANCING_BUFFER_END(Props)

			v2f vert(appdata v){
				v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
				//calculate the position in clip space to render the object
                float4x4 mvp = UNITY_ACCESS_INSTANCED_PROP(Props, _MvpMatrix);
				o.pos = mul(mvp, v.vertex);
                
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{
                return _Color;
			}

			ENDCG
		}
	}
}
