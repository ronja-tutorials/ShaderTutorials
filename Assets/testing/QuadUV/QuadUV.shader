Shader "Testing/QuadUV"
{
	//show values to edit in inspector
	Properties{
		_Color ("Color", Color) = (0, 0, 0, 1)
        _MainTex("Texture", 2D) = "white" {}

        _Corner1("Corner 1", Vector) = ( 1, 1, 0, 0)
        _Corner2("Corner 2", Vector) = ( 1,-1, 0, 0)
        _Corner3("Corner 3", Vector) = (-1,-1, 0, 0)
        _Corner4("Corner 4", Vector) = (-1, 1, 0, 0)
	}

	SubShader{
		//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		Pass{
			CGPROGRAM

			//include useful shader functions
			#include "UnityCG.cginc"

			//define vertex and fragment shader
			#pragma vertex vert
			#pragma fragment frag

			fixed4 _Color;
            sampler2D _MainTex;

			float4 _Corner1;
            float4 _Corner2;
            float4 _Corner3;
            float4 _Corner4;

			//the object data that's put into the vertex shader
			struct appdata{
				float4 vertex : POSITION;
			};

			//the data that's used to generate fragments and can be read by the fragment shader
			struct v2f{
				float4 position : SV_POSITION;
				float3 worldPos : TEXCOORD0;
			};

			//the vertex shader
			v2f vert(appdata v){
				v2f o;
				//convert the vertex positions from object space to clip space so they can be rendered
				o.position = UnityObjectToClipPos(v.vertex);
				//calculate and assign vertex position in the world
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.worldPos = worldPos.xyz;
				return o;
			}

			//return 1 if a thing is left of the line, 0 if not
			float sideOfLine(float2 pos, float2 linePoint1, float2 linePoint2){
				//variables we need for our calculations
				float2 lineDirection = linePoint2 - linePoint1;
				float2 lineNormal = normalize(float2(lineDirection.y, -lineDirection.x));
				float2 toPos = pos - linePoint1;

				//which side the tested position is on
				float side = dot(toPos, lineNormal);
				return side;
			}

			//the fragment shader
			fixed4 frag(v2f i) : SV_TARGET{

				float rightEdge = sideOfLine(i.worldPos, _Corner1, _Corner2);
                float bottomEdge = sideOfLine(i.worldPos, _Corner2, _Corner3);
                float leftEdge = sideOfLine(i.worldPos, _Corner3, _Corner4);
                float topEdge = sideOfLine(i.worldPos, _Corner4, _Corner1);

                clip(rightEdge);
                clip(bottomEdge);
                clip(leftEdge);
                clip(topEdge);

                float horizontalRatio = leftEdge / (leftEdge + rightEdge);
                float verticalRatio = bottomEdge / (topEdge + bottomEdge);

                float4 color = tex2D(_MainTex, float2(horizontalRatio, verticalRatio));

				return color;
			}

			ENDCG
		}
	}
}


