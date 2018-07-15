Shader "Tutorial/nah"
{
	//show values to edit in inspector
	Properties{
		[HideInInspector]_MainTex ("Texture", 2D) = "white" {}
		_depthBias ("Depth Bias", Range(1,4)) = 1
		[PowerSlider(2)]_depthIntensity ("Depth Intensity", Range(0,8)) = 1

		_normalBias ("Normal Bias", Range(1,4)) = 1
		[PowerSlider(2)]_normalIntensity ("Normal Intensity", Range(0,8)) = 1
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
			float4 _CameraDepthNormalsTexture_TexelSize;

			//effect customisation
			float _depthBias;
			float _depthIntensity;

			float _normalBias;
			float _normalIntensity;


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

			float diff(inout float depthOutlines, inout float normalOutlines, float3 baseNormal, float baseDepth, float2 uv, float2 offset){
				//read depthnormal
				float4 depthnormal = tex2D(_CameraDepthNormalsTexture, uv + _CameraDepthNormalsTexture_TexelSize.xy * offset);
				//decode depthnormal
				float3 normal;
				float depth;
				DecodeDepthNormal(depthnormal, depth, normal);
				//get depth as distance from camera in units 
				depth = depth * _ProjectionParams.z;

				float3 diff = baseNormal - normal;
				float normalDiff = 1-dot(baseNormal, normal);

				float depthDiff = baseDepth - depth;

				depthOutlines += depthDiff;
				normalOutlines += normalDiff;

				return depthDiff;
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

				float depthOutlines = 0;
				float normalOutlines = 0;

				diff(depthOutlines, normalOutlines, normal, depth, i.uv, float2( 1, 0));
				diff(depthOutlines, normalOutlines, normal, depth, i.uv, float2(-1, 0));
				diff(depthOutlines, normalOutlines, normal, depth, i.uv, float2( 0, 1));
				diff(depthOutlines, normalOutlines, normal, depth, i.uv, float2( 0,-1));

				depthOutlines = depthOutlines * _depthIntensity;
				depthOutlines = saturate(depthOutlines);
				depthOutlines = pow(depthOutlines, _depthBias);

				normalOutlines = normalOutlines * _normalIntensity;
				normalOutlines = saturate(normalOutlines);
				normalOutlines = pow(normalOutlines, _normalBias);

				float outlines = max(depthOutlines, normalOutlines);
				
				return tex2D(_MainTex, i.uv)*(1-outlines);
			}
			ENDCG
		}
	}
}
