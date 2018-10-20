using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class SineWobble : MonoBehaviour {

	public Vector3 StartPos;
    public Vector3 EndPos;
    public float WobbleSpeed;
	
	// Update is called once per frame
	void Update () {
		transform.position = Vector3.Lerp(StartPos, EndPos, Mathf.Sin(Time.time * WobbleSpeed) * 0.5f + 0.5f);
        Debug.DrawLine(StartPos, EndPos, Color.red, 0, false);
	}
}
