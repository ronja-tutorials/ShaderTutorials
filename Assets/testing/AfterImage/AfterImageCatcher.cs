using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using UnityEngine.Rendering;

[RequireComponent(typeof(Renderer))]
public class AfterImageCatcher : MonoBehaviour {

    public RenderTexture testTex;
    
    public Vector2Int TextureSize;

    private CommandBuffer _command;
    private Renderer _catcher;
    private Material _applyCasters;
    private Material _afterImageCaster;
    private Material _drawDepth;
    private Material _fade;
    private RenderTexture _afterImageTexture;
    private Camera _cam;

	void Start(){
        _cam = Camera.main;
		_command = new CommandBuffer();
        _catcher = GetComponent<Renderer>();
        _applyCasters = new Material(Shader.Find("Hidden/AfterImage"));
        _fade = new Material(Shader.Find("Hidden/Fade"));
        _afterImageCaster = new Material(Shader.Find("Hidden/DrawCaster"));
        _drawDepth = new Material(Shader.Find("Hidden/DepthOnly"));

        _afterImageTexture = new RenderTexture(TextureSize.x, TextureSize.y, 0);
        var mat = _catcher.material;
        mat.SetTexture("_AfterImage", _afterImageTexture);
        _catcher.material = mat;
	}

	
	void LateUpdate () {

        var blitTex = Shader.PropertyToID("_BlitTex");
        var screenspaceCasters = Shader.PropertyToID("_ScreenspaceCasters");
        var depthTexture = Shader.PropertyToID("_DepthTexture");

        var vpMatrix = VpMatrix();

        _command.Clear();

        //fade texture over time
        _command.GetTemporaryRT(blitTex, _afterImageTexture.width, _afterImageTexture.height);
        _command.Blit(_afterImageTexture, blitTex, _fade);
        _command.Blit(blitTex, _afterImageTexture);
        _command.ReleaseTemporaryRT(blitTex);

        //init screenspace tex
        _command.GetTemporaryRT(screenspaceCasters, Screen.width, Screen.height, 24);
        _command.SetRenderTarget(screenspaceCasters);
        _command.ClearRenderTarget(true, true, Color.clear);

        _drawDepth.SetMatrix("_MvpMatrix", vpMatrix * transform.localToWorldMatrix);
        _command.DrawRenderer(_catcher, _drawDepth);

        //draw casters
        foreach(var caster in AfterImageCaster.casters) {
            MaterialPropertyBlock block = new MaterialPropertyBlock();
            block.SetMatrix("_MvpMatrix", vpMatrix * caster.transform.localToWorldMatrix);
            block.SetColor("_Color", caster.CasterColor);
            caster.Renderer.SetPropertyBlock(block);
            _command.DrawRenderer(caster.Renderer, _afterImageCaster);
        }

        _command.SetRenderTarget(_afterImageTexture);
        _applyCasters.SetMatrix("_MvpMatrix", vpMatrix * transform.localToWorldMatrix);
        _command.DrawRenderer(_catcher, _applyCasters);
        _command.ReleaseTemporaryRT(screenspaceCasters);

        Graphics.ExecuteCommandBuffer(_command);
	}

    Matrix4x4 VpMatrix(){
	    bool d3d = false;//SystemInfo.graphicsDeviceVersion.IndexOf("Direct3D") > -1;
		Matrix4x4 V = _cam.worldToCameraMatrix;
		Matrix4x4 P = _cam.projectionMatrix;
		if (d3d) {
			// Invert Y for rendering to a render texture
			for (int i = 0; i < 4; i++) {
				P[1,i] = -P[1,i];
			}
			// Scale and bias from OpenGL -> D3D depth range
			for (int i = 0; i < 4; i++) {
				P[2,i] = P[2,i]*0.5f + P[3,i]*0.5f;
			}
		}
		Matrix4x4 VP = P*V;
		return VP;
    }
}
