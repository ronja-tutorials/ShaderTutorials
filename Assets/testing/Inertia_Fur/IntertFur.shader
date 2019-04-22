// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/IntertFur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma target 5.0

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                uint id : SV_VertexID;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            uniform RWStructuredBuffer<float4> data : register(u1);

            float rand1dTo1d(float3 value, float mutator = 0.546){
                float random = frac(sin(value + mutator) * 143758.5453);
                return random;
            }

            float rand2dTo1d(float2 value, float2 dotDir = float2(12.9898, 78.233)){
                float2 smallValue = sin(value);
                float random = dot(smallValue, dotDir);
                random = frac(sin(random) * 143758.5453);
                return random;
            }

            v2f vert (appdata v)
            {
                v2f o;

                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                float3 worldNormal = mul( unity_ObjectToWorld, float4( v.normal, 0.0 ) ).xyz;

                float3 normalWorldPos = worldPos.xyz/worldPos.w;

                float3 speed = (normalWorldPos.xyz - data[v.id].xyz);
                float absSpeed = length(speed);
                float rand = rand2dTo1d(v.uv);
                float backside = dot(normalize(worldNormal), speed);
                float extensionRange = min(0, rand * backside * 10 );

                float3 extension = absSpeed > 0 ? (speed * extensionRange) : 0;

                o.color = float4(abs(extension), 1);
                worldPos.xyz += extension;

                o.vertex = mul(UNITY_MATRIX_VP, worldPos);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                data[v.id].xyz = normalWorldPos.xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = i.color;
                return col;
            }
            ENDCG
        }
    }
}
