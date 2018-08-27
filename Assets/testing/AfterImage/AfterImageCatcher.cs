using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

[RequireComponent(typeof(MeshFilter))]
public class AfterImageCatcher : MonoBehaviour {
	
	public Material AfterImage;
	public Material white;

	public Texture2D positionLookup;
	private Vector3 size;
	private Vector3 center;

	private MeshFilter meshFilter;
	private Renderer render;
	private RenderTexture casterScreenTex;

	private RenderTexture surfaceAfterImage;
	private RenderTexture surfaceAfterImageBackBuffer;
	private Camera cam;
	

	void Start(){
		casterScreenTex = new RenderTexture(Screen.width, Screen.height, 24);

		surfaceAfterImage = new RenderTexture(1024, 1024, 24);
		surfaceAfterImageBackBuffer = new RenderTexture(1024, 1024, 24);
		cam = Camera.main;

		Graphics.SetRenderTarget(surfaceAfterImage);
		GL.Clear(true, true, Color.black);
		Graphics.SetRenderTarget(surfaceAfterImageBackBuffer);
		GL.Clear(true, true, Color.black);

		meshFilter = GetComponent<MeshFilter>();
		var mesh = meshFilter.sharedMesh;
		size = mesh.bounds.size;
		center = mesh.bounds.center;
	}

	[ContextMenu ("Bake texture")]
	void BakePositionTexture () {
		if(positionLookup == null){
			positionLookup = new Texture2D(64, 64, TextureFormat.RGBA32, false, true);
		}
		if(meshFilter == null){
			meshFilter = GetComponent<MeshFilter>();
			if(meshFilter == null)
				throw new Exception("you need a mesh");
		}
		var mesh = meshFilter.sharedMesh;
		size = mesh.bounds.size;
		center = mesh.bounds.center;

		Color[] positions = new Color[positionLookup.width * positionLookup.height];
		for(int i=0;i<positions.Length;i++){
			var uv = new Vector2(((i+0.5f) % positionLookup.width)/positionLookup.width, 
					((i+0.5f) / positionLookup.width)/positionLookup.height);
			var pos = UvTo3D(uv, mesh);
			pos = new Vector3(
				((pos.x - center.x) / size.x) * 0.5f + 0.5f, 
				(pos.y - center.y) / size.y * 0.5f + 0.5f, 
				(pos.z - center.z) / size.z * 0.5f + 0.5f);
			var color = new Color(pos.x, pos.y, pos.z);
		
			positions[i] = color;
		}
		positionLookup.SetPixels(positions);
		positionLookup.Apply(true);
	}
	
	void LateUpdate () {
		if(render == null){
			render = GetComponent<Renderer>();
		}

		Graphics.SetRenderTarget(casterScreenTex);
		GL.Clear(true, true, Color.black);
		white.SetPass(0);
		foreach(var caster in AfterImageCaster.casters){
			Graphics.DrawMeshNow(caster.mesh, caster.transform.localToWorldMatrix);
		}

		

		AfterImage.SetVector("_MeshSize", size);
		AfterImage.SetVector("_MeshCenter", center);
		AfterImage.SetTexture("_MeshPositions", positionLookup);
		AfterImage.SetMatrix("_MVP", MvpMatrix());
		
		Graphics.Blit(surfaceAfterImageBackBuffer, surfaceAfterImage, AfterImage);

		render.sharedMaterial.SetTexture("_AfterImage", surfaceAfterImage);
		render.sharedMaterial.SetMatrix("_MVP", MvpMatrix());
		render.sharedMaterial.SetTexture("_MeshPositions", positionLookup);
		render.sharedMaterial.SetVector("_MeshSize", size);
		render.sharedMaterial.SetVector("_MeshCenter", center);

		var tmp = surfaceAfterImage;
		surfaceAfterImage = surfaceAfterImageBackBuffer;
		surfaceAfterImageBackBuffer = tmp;
	}

		
	Vector3 UvTo3D(Vector2 uv, Mesh mesh) {
		
		int[] tris = mesh.triangles;
		var uvs = mesh.uv;
		var verts = mesh.vertices;
		for (int i = 0; i < tris.Length; i += 3){
			var u1 = uvs[tris[i]]; // get the triangle UVs
			var u2 = uvs[tris[i+1]];
			var u3 = uvs[tris[i+2]];
			// calculate triangle area - if zero, skip it
			var a = Area(u1, u2, u3); if (a == 0) continue;
			// calculate barycentric coordinates of u1, u2 and u3
			// if anyone is negative, point is outside the triangle: skip it
			var a1 = Area(u2, u3, uv)/a; if (a1 < 0) continue;
			var a2 = Area(u3, u1, uv)/a; if (a2 < 0) continue;
			var a3 = Area(u1, u2, uv)/a; if (a3 < 0) continue;
			// point inside the triangle - find mesh position by interpolation...
			var p3D = a1*verts[tris[i]]+a2*verts[tris[i+1]]+a3*verts[tris[i+2]];
			// and return it in object coordinates:
			return p3D;
		}
		//throw new Exception($"couldn't find triangle for uv {uv}");
		// point outside any uv triangle: return Vector3.zero
		return Vector3.zero;
	}

	// calculate signed triangle area using a kind of "2D cross product":
	float Area(Vector2 p1, Vector2 p2, Vector2 p3) {
		var v1 = p1 - p3;
		var v2 = p2 - p3;
		return (v1.x * v2.y - v1.y * v2.x)/2;
	}

	Matrix4x4 MvpMatrix(){
	    bool d3d = false;//SystemInfo.graphicsDeviceVersion.IndexOf("Direct3D") > -1;
		Matrix4x4 M = transform.localToWorldMatrix;
		Matrix4x4 V = cam.worldToCameraMatrix;
		Matrix4x4 P = cam.projectionMatrix;
		if (d3d) {
			// Invert Y for rendering to a render texture
			for (int i = 0; i < 4; i++) {
				P[1,i] = -P[1,i];
			}
			// Scale and bias from OpenGL -> D3D depth range
			for (int i = 0; i < 4; i++) {
				P[2,i] = P[2,i]*0.5f + P[3,i]*0.5f;
			}
		}
		Matrix4x4 MVP = P*V*M;
		return MVP;
	}
}
