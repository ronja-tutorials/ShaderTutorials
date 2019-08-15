Shader "Tutorial/044_SphereTracingShading"{
	//show values to edit in inspector
	Properties{
		_Color ("Color", Color) = (0, 0, 0, 1)
	}

	SubShader{
		//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
		Tags{ "RenderType"="Opaque" "Queue"="Geometry" "DisableBatching"="True"}

		Pass{
            ZWrite Off

			CGPROGRAM
			#include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            

			#pragma vertex vert
			#pragma fragment frag

            //surface color
			fixed4 _Color;

            //maximum amount of steps
            #define MAX_STEPS 10
            //furthest distance that's accepted as inside surface
            #define THICKNESS 0.01
            //distance from rendered point to sample SDF for normal calculation
            #define NORMAL_EPSILON 0.01

            //input data
            struct appdata{
				float4 vertex : POSITION;
			};

            //data that goes from vertex to fragment shader
			struct v2f{
				float4 position : SV_POSITION; //position in clip space
                float4 localPosition : TEXCOORD0; //position in local space
                float4 viewDirection : TEXCOORD1; //view direction in local space (not normalized!)
			};

			v2f vert(appdata v){
				v2f o;
                //position for rendering
				o.position = UnityObjectToClipPos(v.vertex);
                //save local position for origin
                o.localPosition = v.vertex;
                //get camera position in local space
                float4 objectSpaceCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                //get local view vector
                o.viewDirection = v.vertex - objectSpaceCameraPos;
				return o;
			}


            float scene(float3 pos){
                return length(pos) - 0.5;
            }

            float3 normal(float3 pos){
                //determine change in signed distance
                float changeX = scene(pos + float3(NORMAL_EPSILON, 0, 0)) - scene(pos + float3(-NORMAL_EPSILON, 0, 0));
                float changeY = scene(pos + float3(0, NORMAL_EPSILON, 0)) - scene(pos + float3(0, -NORMAL_EPSILON, 0));
                float changeZ = scene(pos + float3(0, 0, NORMAL_EPSILON)) - scene(pos + float3(0, 0, -NORMAL_EPSILON));
                //construct normal vector
                float3 surfaceNormal = float3(changeX, changeY, changeZ);
                //return normalized vector
                return normalize(surfaceNormal);
            }

            float4 shading(float3 position){
                //calculate needed surface and light data
                float3 surfaceNormal = normal(position);
                float3 lightDirection = _WorldSpaceLightPos0.xyz;

                //calculate simple shading
                float lightAngle = saturate(dot(surfaceNormal, lightDirection));

                //combine lighting and colors to final color
                float4 color = _Color * lightAngle * _LightColor0;

                return color;
            }

			fixed4 frag(v2f i) : SV_TARGET{
                //ray information
				float3 pos = i.localPosition;
                float3 dir = normalize(i.viewDirection.xyz);
                float progress = 0;
                
                //tracing loop
                for (uint iter = 0; iter < MAX_STEPS; iter++) {
                    //get current location on ray
                    float3 samplePoint = pos + dir * progress;
                    //get distance to closest shape
                    float distance = scene(samplePoint);
                    //return color if inside shape
                    if(distance < THICKNESS){
                        return shading(samplePoint);
                    }
                    //go forwards
                    progress = progress + distance;
                }
                //discard pixel if no shape was hit
                clip(-1);
                return 0;
			}

			ENDCG
		}
	}
}