Shader "Tutorial/051_ProceduralSpheres"{
	//show values to edit in inspector
	Properties{
		[HDR] _Color ("Tint", Color) = (0, 0, 0, 1)
	}

	SubShader{
		//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
		Tags{ "RenderType"="Opaque" "Queue"="Geometry" }

		Pass{
			CGPROGRAM

			//include useful shader functions
			#include "UnityCG.cginc"

			//define vertex and fragment shader functions
			#pragma vertex vert
			#pragma fragment frag

			//tint of the texture
			fixed4 _Color;

			//buffers
			StructuredBuffer<float3> SphereLocations;
			StructuredBuffer<int> Triangles;
			StructuredBuffer<float3> Positions;

			//the vertex shader function
			float4 vert(uint vertex_id: SV_VertexID, uint instance_id: SV_InstanceID) : SV_POSITION{
				//get vertex position
				int positionIndex = Triangles[vertex_id];
				float3 position = Positions[positionIndex];
				//add sphere position
				position += SphereLocations[instance_id];
				//convert the vertex position from world space to clip space
				return mul(UNITY_MATRIX_VP, float4(position, 1));
			}

			//the fragment shader function
			fixed4 frag() : SV_TARGET{
				//return the final color to be drawn on screen
				return _Color;
			}
			
			ENDCG
		}
	}
	Fallback "VertexLit"
}
