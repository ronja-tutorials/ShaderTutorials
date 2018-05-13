using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

[ExecuteInEditMode]
public class ColorMetaballs : MonoBehaviour {

	public Vector4[] positions;
	public Color[] colors;
	public Vector4[] properties;

	Renderer render;
	Material mat;

	// Use this for initialization
	void Start () {
		render = GetComponent<Renderer>();
		mat = render.sharedMaterial;

		if(positions == null)
			positions = new Vector4[0];
		if(colors == null)
			colors = new Color[0];
		if(properties == null)
			properties = new Vector4[0];

		UpdateMaterial();
	}

	public void UpdateMaterial(){
		int length = Math.Min(Math.Min(positions.Length, colors.Length), properties.Length);
		Vector4[] materialPoints = new Vector4[1000];
		Color[] materialColors = new Color[1000];
		Vector4[] materialProperties = new Vector4[1000];

		Array.Copy(positions, materialPoints, length);
		Array.Copy(colors, materialColors, length);
		Array.Copy(properties, materialProperties, length);

		mat.SetColorArray("_Colors", materialColors);
		mat.SetVectorArray("_Points", materialPoints);
		mat.SetVectorArray("_Properties", materialProperties);
		mat.SetInt("_PointLength", length);
	}

	public void OnValidate(){
		UpdateMaterial();
	}
}
