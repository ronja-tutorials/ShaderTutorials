Shader "Tutorial/045_SphereTracingDepth"{
//show values to edit in inspector
    Properties{
        _Color ("Color", Color) = (0, 0, 0, 1)
    }

    SubShader{
        //the material is completely non-transparent and is rendered just after opaque geometry
        Tags{ "RenderType"="Opaque" "Queue"="Geometry+1" "DisableBatching"="True" "IgnoreProjector"="True"}

        Pass{
            ZWrite On

            CGPROGRAM
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            #pragma vertex vert
            #pragma fragment frag

            //surface color
            fixed4 _Color;

            //maximum amount of steps
            #define MAX_STEPS 32
            //furthest distance that's accepted as inside surface
            #define THICKNESS 0.001
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
                float changeX = scene(pos + float3(NORMAL_EPSILON, 0, 0)) - scene(pos - float3(NORMAL_EPSILON, 0, 0));
                float changeY = scene(pos + float3(0, NORMAL_EPSILON, 0)) - scene(pos - float3(0, NORMAL_EPSILON, 0));
                float changeZ = scene(pos + float3(0, 0, NORMAL_EPSILON)) - scene(pos - float3(0, 0, NORMAL_EPSILON));
                //construct normal vector
                float3 surfaceNormal = float3(changeX, changeY, changeZ);
                //convert normal vector into worldspace and make it uniform length
                surfaceNormal = mul(unity_ObjectToWorld, float4(surfaceNormal, 0));
                return normalize(surfaceNormal);
            }

            float4 lightColor(float3 position){
                //calculate needed surface and light data
                float3 surfaceNormal = normal(position);
                float3 lightDirection = _WorldSpaceLightPos0.xyz;

                //calculate simple shading
                float lightAngle = saturate(dot(surfaceNormal, lightDirection));
                return lightAngle * _LightColor0;
            }

            float4 renderSurface(float3 position){
                //get light color
                float4 light = lightColor(position);

                //combine base color and light color
                float4 color = _Color * light;

                return color;
            }
            
            void frag(v2f i, out fixed4 color : SV_TARGET, out float depth : SV_Depth){
                //ray information
                float3 pos = i.localPosition;
                float3 dir = normalize(i.viewDirection.xyz);
                float progress = 0;
                float3 samplePoint = 0;
                
                bool hitsurface = false;
                //tracing loop
                for (uint iter = 0; iter < MAX_STEPS; iter++) {
                    //get current location on ray
                    samplePoint = pos + dir * progress;
                    //get distance to closest shape
                    float distance = scene(samplePoint);
                    //return color if inside shape
                    if(distance < THICKNESS){
                        hitsurface = true;
                        break;
                    }
                    //go forwards
                    progress = progress + distance;
                }
                //discard pixel if no shape was hit
                clip(hitsurface ? 1 : -1);
                
                //calculate surface color
                color = renderSurface(samplePoint);
                //calculate surface depth
                float4 tracedClipPos = UnityObjectToClipPos(float4(samplePoint, 1.0));
                depth = tracedClipPos.z / tracedClipPos.w;
            }

            ENDCG
        }
    }
}