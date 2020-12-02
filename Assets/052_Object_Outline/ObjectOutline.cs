using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class ObjectOutline : MonoBehaviour
{
	public Renderer OutlinedObject;

	public Material WriteObject;
	public Material ApplyOutline;

	void Update()
	{
		if (Input.GetMouseButtonDown(0))
		{
			var ray = Camera.main.ScreenPointToRay(Input.mousePosition);
			bool hitSelectable = Physics.Raycast(ray, out var hit) && hit.transform.CompareTag("Selectable");
			if (hitSelectable) {
				OutlinedObject = hit.transform.GetComponent<Renderer>();
			} else {
				OutlinedObject = null;
			}
		}
	}

	void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		//setup stuff
		var commands = new CommandBuffer();
		int selectionBuffer = Shader.PropertyToID("_SelectionBuffer");
		commands.GetTemporaryRT(selectionBuffer, source.descriptor);
		//render selection buffer
		commands.SetRenderTarget(selectionBuffer);
		commands.ClearRenderTarget(true, true, Color.clear);
		if (OutlinedObject != null)
		{
			commands.DrawRenderer(OutlinedObject, WriteObject);
		}
		//apply everything and clean up in commandbuffer
		commands.Blit(source, destination, ApplyOutline);
		commands.ReleaseTemporaryRT(selectionBuffer);
		
		//execute and clean up commandbuffer itself
		Graphics.ExecuteCommandBuffer(commands);
		commands.Dispose();
	}
	
}
