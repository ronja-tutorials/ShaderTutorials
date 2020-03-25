using UnityEngine;
using UnityEngine.Serialization;

//behaviour which should lie on the same gameobject as the main camera
public class DepthPostprocessing : MonoBehaviour {
	//material that's applied when doing postprocessing
	[FormerlySerializedAs("postprocessMaterial"), SerializeField]
	public Material PostprocessMaterial;
	[FormerlySerializedAs("waveSpeed"), SerializeField]
	public float WaveSpeed;
	[FormerlySerializedAs("waveActive"), SerializeField]
	public bool WaveActive;
	
	private float waveDistance;

	private void Start(){
		//get the camera and tell it to render a depth texture
		Camera cam = GetComponent<Camera>();
		cam.depthTextureMode = cam.depthTextureMode | DepthTextureMode.Depth;
	}

	private void Update(){
		//if the wave is active, make it move away, otherwise reset it
		if(WaveActive){
			waveDistance = waveDistance + WaveSpeed * Time.deltaTime;
		} else {
			waveDistance = 0;
		}
	}

	//method which is automatically called by unity after the camera is done rendering
	private void OnRenderImage(RenderTexture source, RenderTexture destination){
		//sync the distance from the script to the shader
		PostprocessMaterial.SetFloat("_WaveDistance", waveDistance);
		//draws the pixels from the source texture to the destination texture
		Graphics.Blit(source, destination, PostprocessMaterial);
	}
}