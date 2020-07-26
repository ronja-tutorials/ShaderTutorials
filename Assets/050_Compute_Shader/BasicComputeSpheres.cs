using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BasicComputeSpheres : MonoBehaviour
{
    public int SphereAmount = 17;
    public ComputeShader Shader;

    public GameObject Prefab;
    
    ComputeBuffer resultBuffer;
    int kernel;
    Vector3[] output;

    Transform[] instances;
    
    void Start()
    {
        //program we're executing
        kernel = Shader.FindKernel("Spheres");
        
        //buffer on the gpu in the ram
        resultBuffer = new ComputeBuffer(SphereAmount, sizeof(float) * 3);
        output = new Vector3[SphereAmount];

        //spheres we use for visualisation
        instances = new Transform[SphereAmount];
        for (int i = 0; i < SphereAmount; i++)
        {
            instances[i] = Instantiate(Prefab, transform).transform;
        }
    }

    void Update()
    {
        Shader.SetFloat("Time", Time.time);
        Shader.SetBuffer(kernel, "Result", resultBuffer);
        Shader.Dispatch(kernel, SphereAmount, 1, 1);
        resultBuffer.GetData(output);

        for (int i = 0; i < instances.Length; i++)
            instances[i].localPosition = output[i];
    }

    void OnDestroy()
    {
        resultBuffer.Dispose();
    }
}
