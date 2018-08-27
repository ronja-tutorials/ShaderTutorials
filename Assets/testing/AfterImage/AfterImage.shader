Shader "Custom/Postprocessing/AfterImage"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
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
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			sampler2D _MainTex;
			sampler2D _MeshPositions;

			float4 _MeshCenter;
			float4 _MeshSize;
			float4x4 _MVP;

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MeshPositions, i.uv);
				col = col * 2 - 1;
				col = (col * _MeshSize) + _MeshCenter;
				float4 screenPos = mul(_MVP, col);
				//screenPos = float4((screenPos.xy / screenPos.w + 1) * .5, 0, 1);
				return screenPos;
			}
			ENDCG
		}
	}
}
