Shader "Unlit/PlaneIntersection"{
	//show values to edit in inspector
	Properties{
		[HDR]_Color ("Color", Color) = (0, 0, 0, 1)
        _Thickness ("Thickness", float) = 0
	}

	SubShader{
		//the material is transparent and is rendered at the same time as the other transparent geometry
		Tags{ "RenderType"="Transparent" "Queue"="Transparent"}

		Pass{
            //render front and back, and render as transparent object without drawing to the zbuffer
            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

			CGPROGRAM
			#include "UnityCG.cginc"

			#pragma vertex vert
			#pragma fragment frag

			fixed4 _Color;
            float4 _Plane;
            float _Thickness;

			struct appdata{
				float4 vertex : POSITION;
			};

			struct v2f{
				float4 position : SV_POSITION;
                float3 worldPos : TEXCOORD0;
			};

			v2f vert(appdata v){
				v2f o;
				//calculate the position in clip space to render the object
				o.position = UnityObjectToClipPos(v.vertex);
                //calculate world position of vertex
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.worldPos = worldPos.xyz;
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{
                //calculate signed distance to plane
                float distance = dot(i.worldPos, _Plane.xyz);
                distance = distance + _Plane.w;

                //how much does the plane distance change in the neighboring pixels
                float aa = fwidth(distance);

                //calculate how the mesh should be cut off above and below the plane 
                //(the aa varable makes the result antialiased because it smoothes the edge)
                float cutoffAbove = smoothstep(_Thickness + aa, _Thickness, distance);
                float cutoffBelow = smoothstep(-_Thickness-aa, -_Thickness, distance);
                //combine the cutoff values
                float cutoff = cutoffAbove * cutoffBelow;

                //use the cutoff value as transparency
                float4 col = float4(_Color.rgb, cutoff);
				return col;
			}

			ENDCG
		}
	}
}
