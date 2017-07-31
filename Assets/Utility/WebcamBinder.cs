using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WebcamBinder : MonoBehaviour
{	
	public Material TargetMaterial = null;
	public string ShaderTextureName = null;

	public bool WebcamDesired = true;
	public bool LeftRightMirrorWebcam = true;

	public List<Texture> FallbackTextures = null;
	public bool DisplayFallbacksSequentially = false;
	public float MinSecondsPerFallbackChange = 2.0f;
	public float MaxSecondsPerFallbackChange = 5.0f;
	
	public bool DebugLoggingEnabled = false;

	public void Start()
	{
		webcamTexture = new WebCamTexture();
	}
	
	public void OnDisable()
	{
		webcamTexture.Stop();
	}

	public void Update()
	{
		if (webcamTexture.isPlaying && !WebcamDesired)
		{
			webcamTexture.Stop();

			secondsUntilFallbackChange = 0.0f;
		}
		else if (!webcamTexture.isPlaying && WebcamDesired)
		{
			webcamTexture.Play();
		}

		if (webcamTexture.isPlaying)
		{
			// Unfortunately, we need to spam texture-assignments to ensure the aspect ratio is up to date.
			TargetMaterial.SetTexture(ShaderTextureName, webcamTexture);

			TargetMaterial.SetInt("_WebcamIsLeftRightMirrored", (LeftRightMirrorWebcam ? 1 : 0));
		}
		else
		{
			secondsUntilFallbackChange -= Time.deltaTime;

			if (secondsUntilFallbackChange <= 0.0f)
			{
				currentFallbackTextureIndex = 
					DisplayFallbacksSequentially ? 
						((currentFallbackTextureIndex + 1) % FallbackTextures.Count) :
						Random.Range(0, FallbackTextures.Count); // TODO: Avoid duplicates.

				TargetMaterial.SetTexture(ShaderTextureName, FallbackTextures[currentFallbackTextureIndex]);
				
				TargetMaterial.SetInt("_WebcamIsLeftRightMirrored", 0);

				secondsUntilFallbackChange = Random.Range(MinSecondsPerFallbackChange, MaxSecondsPerFallbackChange);
			}
		}
	}
	
	private WebCamTexture webcamTexture = null;

	private int currentFallbackTextureIndex = -1;
	private float secondsUntilFallbackChange = 0.0f;
}
