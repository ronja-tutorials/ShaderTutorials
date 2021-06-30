Shader "Tutorial/054_UnlitDynamicDecal"{
	//show values to edit in inspector
	Properties{
		[HDR] _Color ("Tint", Color) = (0, 0, 0, 1)
		_MainTex ("Texture", 2D) = "white" {}
	}

	SubShader{
		//the material is completely transparent and is rendered before other transparent geometry by default (at 2500)
		Tags{ "RenderType"="Transparent" "Queue"="Transparent-400" "DisableBatching"="True"}

		//Blend via alpha
		Blend SrcAlpha OneMinusSrcAlpha
		//dont write to zbuffer because we have semitransparency
		ZWrite off

		Pass{
			CGPROGRAM

			//include useful shader functions
			#include "UnityCG.cginc"

			//define vertex and fragment shader functions
			#pragma vertex vert
			#pragma fragment frag

			//texture and transforms of the texture
			sampler2D _MainTex;
			float4 _MainTex_ST;

			//tint of the texture
			fixed4 _Color;

			//global texture that holds depth information
			sampler2D_float _CameraDepthTexture;

			//the mesh data thats read by the vertex shader
			struct appdata{
				float4 vertex : POSITION;
			};

			//the data thats passed from the vertex to the fragment shader and interpolated by the rasterizer
			struct v2f{
				float4 position : SV_POSITION;
				float4 screenPos : TEXCOORD0;
				float3 ray : TEXCOORD1;
			};

			//the vertex shader function
			v2f vert(appdata v){
				v2f o;
				//convert the vertex positions from object space to clip space so they can be rendered correctly
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.position = UnityWorldToClipPos(worldPos);
				//calculate the ray between the camera to the vertex
				o.ray = worldPos - _WorldSpaceCameraPos;
				//calculate the screen position
				o.screenPos = ComputeScreenPos (o.position);
				return o;
			}

			float3 getProjectedObjectPos(float2 screenPos, float3 worldRay){
				//get depth from depth texture
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos);
				depth = Linear01Depth (depth) * _ProjectionParams.z;
				//get a ray thats 1 long on the axis from the camera away (because thats how depth is defined)
				worldRay = normalize(worldRay);
				//the 3rd row of the view matrix has the camera forward vector encoded, so a dot product with that will give the inverse distance in that direction
				worldRay /= dot(worldRay, -UNITY_MATRIX_V[2].xyz);
				//with that reconstruct world and object space positions
				float3 worldPos = _WorldSpaceCameraPos + worldRay * depth;
				float3 objectPos =  mul (unity_WorldToObject, float4(worldPos,1)).xyz;
				//discard pixels where any component is beyond +-0.5
				clip(0.5 - abs(objectPos));
				//get -0.5|0.5 space to 0|1 for nice texture stuff if thats what we want
				objectPos += 0.5;
				return objectPos;
			}

			//the fragment shader function
			fixed4 frag(v2f i) : SV_TARGET{
				//unstretch screenspace uv and get uvs from function
				float2 screenUv = i.screenPos.xy / i.screenPos.w;
				float2 uv = getProjectedObjectPos(screenUv, i.ray).xz;
			  //read the texture color at the uv coordinate
				fixed4 col = tex2D(_MainTex, uv);
				//multiply the texture color and tint color
				col *= _Color;
				//return the final color to be drawn on screen
				return col;
			}

			ENDCG
		}
	}
}