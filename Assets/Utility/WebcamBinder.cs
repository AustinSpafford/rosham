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
		if ((webLoader != null) &&
			webLoader.isDone)
		{
			if (System.String.IsNullOrEmpty(webLoader.error))
			{
				Texture2D webTexture = new Texture2D(4, 4, TextureFormat.DXT1, false);

				webLoader.LoadImageIntoTexture(webTexture);

				FallbackTextures.Clear();
				FallbackTextures.Add(webTexture);
		
				WebcamDesired = false;
				secondsUntilFallbackChange = 0.0f;
			}
			else
			{
				ErrorMessageDisplay errorMessageDisplay = GameObject.FindObjectOfType<ErrorMessageDisplay>();

				errorMessageDisplay.DisplayMessage("Error: " + webLoader.error);
			}
			
			webLoader.Dispose();
			webLoader = null;
		}

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
				int newFallbackTextureIndex;
				if (DisplayFallbacksSequentially)
				{
					newFallbackTextureIndex = ((currentFallbackTextureIndex + 1) % FallbackTextures.Count);
				}
				else
				{
					if (FallbackTextures.Count > 1)
					{
						// Avoid repeats by only choosing among textures *other* than the current one.
						newFallbackTextureIndex = Random.Range(0, (FallbackTextures.Count - 1));

						if (newFallbackTextureIndex >= currentFallbackTextureIndex)
						{
							newFallbackTextureIndex++;
						}
					}
					else
					{
						newFallbackTextureIndex = 0;
					}
				}

				currentFallbackTextureIndex = newFallbackTextureIndex;

				TargetMaterial.SetTexture(ShaderTextureName, FallbackTextures[currentFallbackTextureIndex]);
				
				TargetMaterial.SetInt("_WebcamIsLeftRightMirrored", 0);

				secondsUntilFallbackChange = Random.Range(MinSecondsPerFallbackChange, MaxSecondsPerFallbackChange);
			}
		}
	}

	public void HaaaaaackLoadFallbackFromUrl(
		UnityEngine.UI.Text urlSource)
	{
		if (webLoader != null)
		{
			webLoader.Dispose();
			webLoader = null;
		}

		webLoader = new WWW(urlSource.text);
	}
	
	private WebCamTexture webcamTexture = null;
	
	private WWW webLoader = null;

	private int currentFallbackTextureIndex = -1;
	private float secondsUntilFallbackChange = 0.0f;
}
