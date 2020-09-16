using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;

public class ProceduralComputeSpheres : MonoBehaviour
{
    //rough outline for data
    public int SphereAmount = 17;
    public ComputeShader Shader;

    //what is rendered
    public Mesh Mesh;
    public Material Material;
    public float Scale = 1;
    
    //internal data
    ComputeBuffer resultBuffer;
    ComputeBuffer meshTriangles;
    ComputeBuffer meshPositions;
    int kernel;
    uint threadGroupSize;
    Bounds bounds;
    int threadGroups;

    void Start()
    {
        //program we're executing
        kernel = Shader.FindKernel("Spheres");
        Shader.GetKernelThreadGroupSizes(kernel, out threadGroupSize, out _, out _);
        
        //amount of thread groups we'll need to dispatch
        threadGroups = (int) ((SphereAmount + (threadGroupSize - 1)) / threadGroupSize);
        
        //gpu buffer for the sphere positions
        resultBuffer = new ComputeBuffer(SphereAmount, sizeof(float) * 3);
        
        //gpu buffers for the mesh
        int[] triangles = Mesh.triangles;
        meshTriangles = new ComputeBuffer(triangles.Length, sizeof(int));
        meshTriangles.SetData(triangles);
        Vector3[] positions = Mesh.vertices.Select(p => p * Scale).ToArray(); //adjust scale here
        meshPositions = new ComputeBuffer(positions.Length, sizeof(float) * 3);
        meshPositions.SetData(positions);

        //give data to shaders
        Shader.SetBuffer(kernel, "Result", resultBuffer);
        
        Material.SetBuffer("SphereLocations", resultBuffer);
        Material.SetBuffer("Triangles", meshTriangles);
        Material.SetBuffer("Positions", meshPositions);
        
        //bounds for frustum culling (20 is a magic number (radius) from the compute shader)
        bounds = new Bounds(Vector3.zero, Vector3.one * 20);
    }

    void Update()
    {
        //calculate positions
        Shader.SetFloat("Time", Time.time);
        Shader.Dispatch(kernel, threadGroups, 1, 1);
        
        //draw result
        Graphics.DrawProcedural(Material, bounds, MeshTopology.Triangles, meshTriangles.count, SphereAmount);
    }

    void OnDestroy()
    {
        resultBuffer.Dispose();
        meshTriangles.Dispose();
        meshPositions.Dispose();
    }
}
