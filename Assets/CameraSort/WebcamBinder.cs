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

		webcamTexture.Play();
	}
	
	private WebCamTexture webcamTexture = null;
}
