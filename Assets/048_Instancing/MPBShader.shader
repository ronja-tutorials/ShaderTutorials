Shader "Tutorial/048_Instancing" {
	//show values to edit in inspector
	Properties{
		[PerRendererData] _Color ("Color", Color) = (0, 0, 0, 1)
	}

	SubShader{
		//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		Pass{
			CGPROGRAM
			//allow instancing
			#pragma multi_compile_instancing

            //shader functions
			#pragma vertex vert
			#pragma fragment frag
			
			//use unity shader library
			#include "UnityCG.cginc"

            //per vertex data that comes from the model/parameters
			struct appdata{
				float4 vertex : POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

            //per vertex data that gets passed from the vertex to the fragment function
			struct v2f{
				float4 position : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
            UNITY_INSTANCING_BUFFER_END(Props)

			v2f vert(appdata v){
				v2f o;
				
				//setup instance id
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                
                float4 color =  UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
				
				//calculate the position in clip space to render the object
				o.position = UnityObjectToClipPos(v.vertex + color);
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{
			    //setup instance id
                UNITY_SETUP_INSTANCE_ID(i);
			    //get _Color Property from buffer
			    fixed4 color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
				//Return the color the Object is rendered in
				return color;
			}

			ENDCG
		}
	}
}
