using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Rotator : MonoBehaviour {
	[Range(0, 5)]public float rotationsPerSecond = 1;
	
	void Update () {
		transform.localEulerAngles = Time.time * rotationsPerSecond * 360 * Vector3.up;
	}
}
