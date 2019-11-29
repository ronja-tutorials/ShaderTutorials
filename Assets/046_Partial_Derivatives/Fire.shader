Shader "Tutorial/046_Partial_Derivatives/fire"{
	//show values to edit in inspector
	Properties{
	    _MainTex ("Fire Noise", 2D) = "white" {}
	    _ScrollSpeed("Animation Speed", Range(0, 2)) = 1
	
		_Color1 ("Color 1", Color) = (0, 0, 0, 1)
		_Color2 ("Color 2", Color) = (0, 0, 0, 1)
		_Color3 ("Color 3", Color) = (0, 0, 0, 1)
		
		_Edge1 ("Edge 1-2", Range(0, 1)) = 0.25
		_Edge2 ("Edge 2-3", Range(0, 1)) = 0.5
	}

	SubShader{
		//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
		Tags{ "RenderType"="transparent" "Queue"="transparent"}
		
		Cull Off
		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite Off

		Pass{
			CGPROGRAM

			//include useful shader functions
			#include "UnityCG.cginc"

			//define vertex and fragment shader
			#pragma vertex vert
			#pragma fragment frag

			//tint of the texture
			fixed4 _Color1;
			fixed4 _Color2;
			fixed4 _Color3;
			
			float _Edge1;
			float _Edge2;
			
			float _ScrollSpeed;
			
			sampler2D _MainTex;
			float4 _MainTex_ST;

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
			    float change = fwidth(gradient);
			    //base the range of the inverse lerp on the change over two pixels
			    float lowerEdge = compValue - change;
			    float upperEdge = compValue + change;
			    //do the inverse interpolation
			    float stepped = (gradient - lowerEdge) / (upperEdge - lowerEdge);
			    stepped = saturate(stepped);
			    //smoothstep version here would be `smoothstep(lowerEdge, upperEdge, gradient)`
			    return stepped;
			}

			//the fragment shader
			fixed4 frag(v2f i) : SV_TARGET{
			    //I square this here to make the fire look a bit more "full"
			    float fireGradient = 1 - i.uv.y;
			    fireGradient = fireGradient * fireGradient;
			    //calculate fire UVs and animate them
			    float2 fireUV = TRANSFORM_TEX(i.uv, _MainTex);
			    fireUV.y -= _Time.y * _ScrollSpeed;
			    //get the noise texture
			    float fireNoise = tex2D(_MainTex, fireUV).x;
			    
			    //calculate whether fire is visibe at all and which colors should be shown
                float outline = aaStep(fireNoise, fireGradient);
                float edge1 = aaStep(fireNoise, fireGradient - _Edge1);
                float edge2 = aaStep(fireNoise, fireGradient - _Edge2);
			    
			    //define shape of fire
			    fixed4 col = _Color1 * outline;
			    //add other colors
			    col = lerp(col, _Color2, edge1);
			    col = lerp(col, _Color3, edge2);
			    
			    //uv to color
				return col;
			}

			ENDCG
		}
	}
}