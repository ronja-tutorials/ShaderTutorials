Shader "Tutorial/046_Partial_Derivatives/uv"{
	//show values to edit in inspector
	Properties{
	
	}

	SubShader{
		//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}
		
		Cull Off

		Pass{
			CGPROGRAM

			//include useful shader functions
			#include "UnityCG.cginc"

			//define vertex and fragment shader
			#pragma vertex vert
			#pragma fragment frag

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
			
			//smooth version of step
			float aaStep(float compValue, float gradient){
			    float halfChange = fwidth(gradient) / 2;
			    //base the range of the inverse lerp on the change over one pixel
			    float lowerEdge = compValue - halfChange;
			    float upperEdge = compValue + halfChange;
			    //do the inverse interpolation
			    float stepped = (gradient - lowerEdge) / (upperEdge - lowerEdge);
			    stepped = saturate(stepped);
			    //smoothstep version here would be `smoothstep(lowerEdge, upperEdge, gradient)`
			    return stepped;
			}

			//the fragment shader
			fixed4 frag(v2f i) : SV_TARGET{
                float stepped = aaStep(0.5, i.uv.x); 
			    //value to greyscale color with full alpha
				fixed4 col = float4(stepped.xxx, 1);
				return col;
			}
			
			

			ENDCG
		}
	}
}