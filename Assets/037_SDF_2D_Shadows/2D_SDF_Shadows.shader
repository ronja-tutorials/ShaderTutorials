Shader "Tutorial/037_2D_SDF_Shadows"{
    Properties{
    }

	SubShader{
		//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		Pass{
			CGPROGRAM

			#include "UnityCG.cginc"
            #include "2D_SDF.cginc"

			#pragma vertex vert
			#pragma fragment frag

			struct appdata{
				float4 vertex : POSITION;
			};

			struct v2f{
				float4 position : SV_POSITION;
				float4 worldPos : TEXCOORD0;
			};

			v2f vert(appdata v){
				v2f o;
				//calculate the position in clip space to render the object
				o.position = UnityObjectToClipPos(v.vertex);
				//calculate world position of vertex
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}

            float scene(float2 position) {
                float bounds = -rectangle(position, 2);

                float2 quarterPos = abs(position);

                float corner = rectangle(translate(quarterPos, 1), 0.5);
                corner = subtract(corner, rectangle(position, 1.2));

                float diamond = rectangle(rotate(position, 0.125), .5);

                float world = merge(bounds, corner);
                world = merge(world, diamond);

                return world;
            }

            #define STARTDISTANCE 0.00001
            #define MINSTEPDIST 0.02
            #define SAMPLES 32

            float traceShadows(float2 position, float2 lightPosition, float hardness){
                float2 direction = normalize(lightPosition - position);
                float lightDistance = length(lightPosition - position);

                float lightSceneDistance = scene(lightPosition) * 0.8;

                float rayProgress = 0.0001;
                float shadow = 9999;
                for(int i=0 ;i<SAMPLES; i++){
                    float sceneDist = scene(position + direction * rayProgress);

                    if(sceneDist <= 0){
                        return 0;
                    }
                    if(rayProgress > lightDistance){
                        return saturate(shadow);
                    }

                    shadow = min(shadow, hardness * sceneDist / rayProgress);
                    rayProgress = rayProgress + max(sceneDist, 0.02);
                }

                return 0;
            }

			fixed4 frag(v2f i) : SV_TARGET{
                float2 position = i.worldPos.xz;

                float2 lightPos1 = float2(sin(_Time.y), -1);
                float shadows1 = traceShadows(position, lightPos1, 20);
                float3 light1 = shadows1 * float3(.6, .6, 1);

                float2 lightPos2 = float2(-sin(_Time.y) * 1.75, 1.75);
				float shadows2 = traceShadows(position, lightPos2, 10);
                float3 light2 = shadows2 * float3(1, .6, .6);

                float sceneDistance = scene(position);
                float distanceChange = fwidth(sceneDistance) * 0.5;
                float binaryScene = smoothstep(distanceChange, -distanceChange, sceneDistance);
                float3 geometry = binaryScene * float3(0, 0.3, 0.1);

                float3 col = geometry + light1 + light2;

				return float4(col, 1);
			}

			ENDCG
		}
	}
	FallBack "Standard" //fallback adds a shadow pass so we get shadows on other objects
}