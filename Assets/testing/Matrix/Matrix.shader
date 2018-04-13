Shader "Unlit/Matrix"
{
	Properties
	{
		_MainTex ("Font", 2D) = "white" {}
		_Freq ("Perlin Frequency", Range(0, 0.2)) = 0.1
		_Cutoff ("Perlin Cutoff", Range(0, 1)) = 0.5
		[Int]_Size ("Size (amount of letters)", Vector) = (1,1,1,1)
		_FallSpeed ("FallSpeed", Range(1, 20)) = 5
		_LetterChange ("Letter Change Rate", Range(0, 2)) = 1
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
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			#define PI 3.14201

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Freq;
			int2 _Size;
			float _FallSpeed;
			float _Cutoff;
			float _LetterChange;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			float rand(in float2 uv)
			{
				float2 noise = (frac(sin(dot(uv ,float2(12.9898,78.233)*2.0)) * 43758.5453));
				return abs(noise.x + noise.y) * 0.5;
			}

			float interpolate(float pa, float pb, float px)
			{
				float ft = px * PI;
				float f = (1 - cos(ft)) * 0.5;
				return pa * (1 - f) + pb * f;
			}

			float perlin(float t){
				t = t * _Freq;
				float p1 = round(t);
				float p1_jittered = p1 + (rand(p1)-0.5);
				if(t > p1_jittered){
					float p2 = p1 + 1;
					float p2_jittered = p2 + (rand(p2)-0.5);
					return interpolate(rand(p1_jittered), rand(p2_jittered), 
							smoothstep(p1_jittered, p2_jittered, t));
				} else {
					float p2 = p1 - 1;
					float p2_jittered = p2 + (rand(p2)-0.5);
					return interpolate(rand(p2_jittered), rand(p1_jittered), 
							smoothstep(p2_jittered, p1_jittered, t));
				}
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float2 letteruv = frac(i.uv * _Size);
				float2 letterpos = floor(i.uv * _Size);

				float4 letter = step(
					perlin(letterpos.y + rand(letterpos.x) * 420.69 + round(_Time.y*_FallSpeed)),
					_Cutoff);
				if(letter.x){
					float lowerLetter = step(
						perlin(letterpos.y - 1 + rand(letterpos.x) * 420.69 + round(_Time.y*_FallSpeed)),
						_Cutoff);
					if(lowerLetter){
						letter = float4(0, 1, 0, 1);
					} else {
						letter = 1;
					}
				}

				letteruv.x = 1-letteruv.x;
				letteruv = saturate(letteruv / _MainTex_ST.xy);
				letteruv += floor(float2(
						rand(letterpos.x + floor(_Time.y*_LetterChange*rand(letterpos))), 
						rand(letterpos.y + floor(_Time.y*_LetterChange*rand(letterpos+1)))) * _MainTex_ST.xy)
						/_MainTex_ST.xy;
				
				// sample the texture
				fixed4 col = tex2Dlod(_MainTex, float4(letteruv, 1, 1)).r * letter;
				return col;
			}
			ENDCG
		}
	}
}
