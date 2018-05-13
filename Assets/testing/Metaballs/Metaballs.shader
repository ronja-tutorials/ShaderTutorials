Shader "Unlit/Metaballs"
{
	Properties
	{
		[PowerSlider(4)]_Threshold ("Threshold", Range(0,64)) = 0.01
		[PowerSlider(2)]_ColorPower ("Color Power", Range(1,16)) = 2
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
		Cull Off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			float _Threshold;

			float4 _Points[1000];
			float4 _Colors[1000];
			float4 _Properties[1000]; // size, hole
			int _PointLength;
			float _ColorPower;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				float value = 0;

				float3 pos = i.worldPos;
				float4 color = 0;
				float colorsum = 0;

				[loop]
				for(int i=0; i<_PointLength; i++){
					//general stuff
					float dist = distance(pos, _Points[i].xyz);
					float inverseDistance = (1 / dist);
					
					//range
					float hole = dist / _Properties[i].y;
					value += min(inverseDistance * _Properties[i].x, hole);


					//color stuff
					float isPositive = step(0, _Properties[i].x);
					float colorEffect = pow(inverseDistance, _ColorPower) * isPositive * abs(_Properties[i].x); //bit expensive but fancy
					color += _Colors[i] * colorEffect;
					colorsum += colorEffect;
				}				

				fixed4 col = step(_Threshold, value) * (color / colorsum);

				return col;
			}
			ENDCG
		}
	}
}
