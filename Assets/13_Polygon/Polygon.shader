Shader "Tutorial/13_Polygon"
{
	//show values to edit in inspector
	Properties{
		_Color ("Color", Color) = (0, 0, 0, 1)
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

			//the variables for the corners
			uniform float2 _corners[1000];
			uniform uint _cornerCount;

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
			float isLeftOfLine(float2 pos, float2 linePoint1, float2 linePoint2){
				//variables we need for our calculations
				float2 lineDirection = linePoint2 - linePoint1;
				float2 lineNormal = float2(-lineDirection.y, lineDirection.x);
				float2 toPos = pos - linePoint1;

				//which side the tested position is on
				float side = dot(toPos, lineNormal);
				side = step(0, side);
				return side;
			}

			//the fragment shader
			fixed4 frag(v2f i) : SV_TARGET{

				float outsideTriangle = 0;
				
				[loop]
				for(uint index;index<_cornerCount;index++){
					outsideTriangle += isLeftOfLine(i.worldPos.xy, _corners[index], _corners[(index+1) % _cornerCount]);
				}

				clip(-outsideTriangle);
				return _Color;
			}

			ENDCG
		}
	}
}


