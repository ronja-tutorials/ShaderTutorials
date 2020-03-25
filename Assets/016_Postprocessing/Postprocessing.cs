using UnityEngine;
using UnityEngine.Serialization;

//behaviour which should lie on the same gameobject as the main camera
public class Postprocessing : MonoBehaviour {
	//material that's applied when doing postprocessing
	[FormerlySerializedAs("postprocessMaterial"), SerializeField]
	public Material PostprocessMaterial;

	//method which is automatically called by unity after the camera is done rendering
	void OnRenderImage(RenderTexture source, RenderTexture destination){
		//draws the pixels from the source texture to the destination texture
		Graphics.Blit(source, destination, PostprocessMaterial);
	}
}