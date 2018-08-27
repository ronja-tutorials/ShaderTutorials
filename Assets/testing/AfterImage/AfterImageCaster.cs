using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class AfterImageCaster : MonoBehaviour {

	public static List<AfterImageCaster> casters = new List<AfterImageCaster>();
	public Mesh mesh;


	void OnEnable(){
		casters.Add(this);
		mesh = GetComponent<MeshFilter>().sharedMesh;
	}
	void OnDisable(){
		casters.Remove(this);
	}
}
