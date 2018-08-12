Shader "Tutorial/018_Normal_Postprocessing"{
	//show values to edit in inspector
	Properties{
		[HideInInspector]_MainTex ("Texture", 2D) = "white" {}
		_upCutoff ("up cutoff", Range(0,1)) = 0.7
		_topColor ("top color", Color) = (1,1,1,1)
	}

	SubShader{
		// markers that specify that we don't need culling 
		// or comparing/writing to the depth buffer
		Cull Off
		ZWrite Off 
		ZTest Always

		Pass{
			CGPROGRAM
			//include useful shader functions
			#include "UnityCG.cginc"

			//define vertex and fragment shader
			#pragma vertex vert
			#pragma fragment frag

			//the rendered screen so far
			sampler2D _MainTex;
			//matrix to convert from view space to world space
			float4x4 _viewToWorld;
			//the depth normals texture
			sampler2D _CameraDepthNormalsTexture;

			//effect customisation
			float _upCutoff;
			float4 _topColor;


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

			//the fragment shader
			fixed4 frag(v2f i) : SV_TARGET{
				//read depthnormal
				float4 depthnormal = tex2D(_CameraDepthNormalsTexture, i.uv);

				//decode depthnormal
				float3 normal;
				float depth;
				DecodeDepthNormal(depthnormal, depth, normal);

				//get depth as distance from camera in units 
				depth = depth * _ProjectionParams.z;

				normal = mul((float3x3)_viewToWorld, normal);

				float up = dot(float3(0,1,0), normal);
				up = step(_upCutoff, up);
				float4 source = tex2D(_MainTex, i.uv);
				float4 col = lerp(source, _topColor, up * _topColor.a);
				return col;
			}
			ENDCG
		}
	}
}

