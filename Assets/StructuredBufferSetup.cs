using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class StructuredBufferSetup : MonoBehaviour
{
    public MeshFilter MeshHolder;
    public SkinnedMeshRenderer SkinnedRenderer;
    public Material material;

    ComputeBuffer _buffer;

    void Start()
    {
        if(_buffer != null)
            return;
        Mesh mesh;
        if(MeshHolder != null){
            mesh = MeshHolder.sharedMesh;
        } else {
            mesh = SkinnedRenderer.sharedMesh;
        }
        _buffer = new ComputeBuffer(mesh.vertices.Length, sizeof(float) * 4, ComputeBufferType.Default);
        Graphics.ClearRandomWriteTargets();
        material.SetPass(0);
        material.SetBuffer("data", _buffer);
        Graphics.SetRandomWriteTarget(1, _buffer, false);
    }
}
