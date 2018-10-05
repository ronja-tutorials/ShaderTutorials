using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ModuloMove : MonoBehaviour {

	public Vector3 Axis;
	public float Speed;
	public float Modulo;

	private Vector3 _basePosition;

	void Start(){
		_basePosition = transform.position;
	}
	
	// Update is called once per frame
	void Update () {
		transform.position = _basePosition + Axis * ((Time.time * Speed) % Modulo);
	}
}
