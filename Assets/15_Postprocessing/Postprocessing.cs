using UnityEngine;

//behaviour which should lie on the same gameobject as the main camera
public class Postprocessing : MonoBehaviour {
	//material that's applied when doing postprocessing
	[SerializeField]
	private Material postprocesssMaterial;

	//method which is automatically called by unity after the camera is done rendering
	void OnRenderImage(RenderTexture source, RenderTexture destination){
		//draws the pixels from the source texture to the destination texture
		Graphics.Blit(source, destination, postprocesssMaterial);
	}
}