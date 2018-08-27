// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/AfterImageTest"
{
	Properties
	{
		_AfterImage ("Texture", 2D) = "cyan" {}
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

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 object : TEXCOORD1;
				float4 screenPos : TEXCOORD2;
			};

			sampler2D _AfterImage;
			sampler2D _MeshPositions;

			float4x4 _MVP;
			float4x4 m;
			float4x4 v;
			float4x4 p;
			float4 _MeshCenter;
			float4 _MeshSize;

			v2f vert (appdata i)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(i.vertex);
				o.object = i.vertex;
				//o.vertex = mul(_MVP, i.vertex);
				o.uv = i.uv;
				o.screenPos = ComputeScreenPos(o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				float4 screenPos = float4(i.vertex.xy/_ScreenParams.xy, 0, 1);
				float4 pos = tex2D(_MeshPositions, i.uv);
				pos = pos * 2 - 1;
				pos = (pos * _MeshSize) + _MeshCenter;

				float4 col = tex2D(_AfterImage, i.uv);
				
				float4 clipPos = (mul(_MVP, col));

				//clipPos = float4((clipPos.xy / clipPos.w + 1) * .5, 0, 1);
				col = step(col, 0);
				return col;
			}
			ENDCG
		}
	}
}
