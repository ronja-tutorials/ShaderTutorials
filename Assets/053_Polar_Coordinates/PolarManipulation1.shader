Shader "Tutorial/053_Polar_Coordinates/Polar_Manipilation_1"{
	//show values to edit in inspector
	Properties{
		_Color ("Tint", Color) = (0, 0, 0, 1)
		_MainTex ("Texture", 2D) = "white" {}
	}

	SubShader{
		//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
		Tags{ "RenderType"="Opaque" "Queue"="Geometry" }

		Pass{
			CGPROGRAM

			//include useful shader functions
			#include "UnityCG.cginc"
			#include "Polar.cginc"

			//define vertex and fragment shader functions
			#pragma vertex vert
			#pragma fragment frag

			//texture and transforms of the texture
			sampler2D _MainTex;
			float4 _MainTex_ST;

			//tint of the texture
			fixed4 _Color;

			//the mesh data thats read by the vertex shader
			struct appdata{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			//the data thats passed from the vertex to the fragment shader and interpolated by the rasterizer
			struct v2f {
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			//the vertex shader function
			v2f vert(appdata v){
				v2f o;
				//convert the vertex positions from object space to clip space so they can be rendered correctly
				o.position = UnityObjectToClipPos(v.vertex);
				//apply the texture transforms to the UV coordinates and pass them to the v2f struct
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			//the fragment shader function
			fixed4 frag (v2f i) : SV_Target {
        float2 uv = i.uv - 0.5; //get centered uvs
        uv = toPolar(uv); //make uvs polar

				//manipulate uvs in polar space here
      	uv.x += _Time.y * 0.1;
      	uv.y *= 1 + sin(_Time.y * 3) * 0.2;
      	
      	uv = toCartesian(uv); //convert uvs back to cartesian
        uv += 0.5; //make uvs start in corner again
        // sample the texture and apply tint
        fixed4 col = tex2D(_MainTex, uv) * _Color;
      	//return the final color to be drawn on screen
        return col;
      }
			
			ENDCG
		}
	}
	Fallback "VertexLit"
}