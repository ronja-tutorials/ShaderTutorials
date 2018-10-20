Shader "Hidden/DepthOnly"
{
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

        //ColorMask 0
        Blend Zero One

        ZTest Always
        ZWrite On

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

            float4x4 _MvpMatrix;

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
                float4 projPos:TEXCOORD1;
			};
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = mul(_MvpMatrix, v.vertex);
                o.projPos = ComputeScreenPos (o.pos);
                COMPUTE_EYEDEPTH(o.projPos.z);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
                return 0;
			}
			ENDCG
		}
	}
}
