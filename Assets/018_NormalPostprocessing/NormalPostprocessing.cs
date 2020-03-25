using UnityEngine;
using UnityEngine.Serialization;

//behaviour which should lie on the same gameobject as the main camera
public class NormalPostprocessing : MonoBehaviour {
	//material that's applied when doing postprocessing
	[FormerlySerializedAs("postprocessMaterial"), SerializeField]
	public Material PostprocessMaterial;

	private Camera cam;

	private void Start(){
		//get the camera and tell it to render a depthnormals texture
		cam = GetComponent<Camera>();
		cam.depthTextureMode = cam.depthTextureMode | DepthTextureMode.DepthNormals;
	}

	//method which is automatically called by unity after the camera is done rendering
	private void OnRenderImage(RenderTexture source, RenderTexture destination){
		//get viewspace to worldspace matrix and pass it to shader
		Matrix4x4 viewToWorld = cam.cameraToWorldMatrix;
		PostprocessMaterial.SetMatrix("_viewToWorld", viewToWorld);
		//draws the pixels from the source texture to the destination texture
		Graphics.Blit(source, destination, PostprocessMaterial);
	}
}

