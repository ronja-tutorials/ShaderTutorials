using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Rotator : MonoBehaviour {
	[Range(-2, 2)]public float rotationsPerSecond = 1;
	
	void Update () {
		transform.Rotate(Vector3.up, Time.deltaTime * rotationsPerSecond * 360, Space.World);
	}
}
