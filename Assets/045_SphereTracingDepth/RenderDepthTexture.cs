using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RenderDepthTexture : MonoBehaviour
{
    void Start()
    {
        var cam = GetComponent<Camera>();
        cam.depthTextureMode |= DepthTextureMode.Depth;
    }
}
