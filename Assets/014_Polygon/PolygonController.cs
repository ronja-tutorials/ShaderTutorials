using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Renderer))]
public class PolygonController : MonoBehaviour {
	
	public Vector2[] corners;

	private Material _mat;

	void Start(){
		UpdateMaterial();
	}

	void OnValidate(){
		UpdateMaterial();
	}
	
	void UpdateMaterial(){
		//fetch material if we haven't already
		if(_mat == null)
			_mat = GetComponent<Renderer>().sharedMaterial;
		
		//allocate and fill array to pass
		Vector4[] vec4Corners = new Vector4[1000];
		for(int i=0;i<corners.Length;i++){
			vec4Corners[i] = corners[i];
		}

		//pass array to material
		_mat.SetVectorArray("_corners", vec4Corners);
		_mat.SetInt("_cornerCount", corners.Length);
	} 

}

