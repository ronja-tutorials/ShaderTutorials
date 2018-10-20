using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class AfterImageCaster : MonoBehaviour {

	public static List<AfterImageCaster> casters = new List<AfterImageCaster>();
	[HideInInspector]public Renderer Renderer;
    public Color CasterColor = Color.yellow;


	void OnEnable(){
		casters.Add(this);
		Renderer = GetComponent<Renderer>();
	}
	void OnDisable(){
		casters.Remove(this);
	}
}
