using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WebcamBinder : MonoBehaviour
{	
	public Material TargetMaterial = null;
	public string ShaderTextureName = null;
	
	public bool DebugLoggingEnabled = false;

	public void Start()
	{
		webcamTexture = new WebCamTexture();

		TargetMaterial.SetTexture(ShaderTextureName, webcamTexture);

		if (DebugLoggingEnabled)
		{
			Texture validationTexture = TargetMaterial.GetTexture(ShaderTextureName);

			Debug.LogFormat(
				"WebcamBinder [{0}] in assigning the webcam texture.",
				((webcamTexture == validationTexture) ? "succeeded" : "failed"));
		}

		webcamTexture.Play();		
		
		if (DebugLoggingEnabled)
		{
			Debug.LogFormat(
				"Webcam (isPlaying:{0}).",
				webcamTexture.isPlaying);
		}
	}
	
	private WebCamTexture webcamTexture = null;
}
