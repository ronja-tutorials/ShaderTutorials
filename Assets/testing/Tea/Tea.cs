using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Tea : MonoBehaviour {

	public Transform surfaceRepresentation;
	public Plane surfacePlane;
	Material teaMaterial;

	// Use this for initialization
	void Start () {
		teaMaterial = GetComponent<Renderer>().material;
		surfacePlane = new Plane();
	}
	
	// Update is called once per frame
	void LateUpdate () {
		surfacePlane.SetNormalAndPosition(surfaceRepresentation.up, 
				surfaceRepresentation.position);
		
		teaMaterial.SetVector("_Plane", 
				new Vector4(surfacePlane.normal.x,
					surfacePlane.normal.y,
					surfacePlane.normal.z,
					surfacePlane.distance));
	}
}
