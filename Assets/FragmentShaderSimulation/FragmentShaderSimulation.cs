using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FragmentShaderSimulation : MonoBehaviour
{
	public int TextureWidth = 512;
	public int TextureHeight = 512;
	public int TextureDepthBits = 0;
	public RenderTextureFormat TextureFormat = RenderTextureFormat.ARGBFloat;

	public RenderTexture DisplayTexture = null;
	
	public Material InitializationMaterial = null;
	public Material IterationMaterial = null;
	public Material DisplayMaterial = null;
	
	public bool DebugDisplayRawSimulation = false;
	public bool DebugLoggingEnabled = false;

	public void Start()
	{
		if (DisplayTexture == null)
		{
			DisplayTexture =
				new RenderTexture(
					TextureWidth, 
					TextureHeight, 
					TextureDepthBits, 
					TextureFormat);
		}
	}

	public void Update()
	{
		// Make sure the textures are of an appropriate format.
		{
			MatchOutputTextureToRequirements();
			
			MatchSimulationTextureToDisplayTexture(ref currentSimulationTexture, "current");
			MatchSimulationTextureToDisplayTexture(ref previousSimulationTexture, "previous");
		}

		// Advance the simulation.
		if (IterationMaterial != null)
		{
			RenderTexture swapTemp = currentSimulationTexture;
			currentSimulationTexture = previousSimulationTexture;
			previousSimulationTexture = swapTemp;

			Graphics.Blit(
				previousSimulationTexture,
				currentSimulationTexture,
				IterationMaterial);
		}
		else
		{
			Debug.Log("The iteration-material is missing!");
		}

		// Output to the display texture.
		if (DebugDisplayRawSimulation || (DisplayMaterial == null))
		{
			Graphics.Blit(
				currentSimulationTexture,
				DisplayTexture);
		}
		else
		{
			Graphics.Blit(
				currentSimulationTexture,
				DisplayTexture,
				DisplayMaterial);
		}
	}
	
	private RenderTexture currentSimulationTexture = null;
	private RenderTexture previousSimulationTexture = null;

	private void MatchOutputTextureToRequirements()
	{
		if (DisplayTexture.width != TextureWidth ||
			DisplayTexture.height != TextureHeight ||
			DisplayTexture.depth != TextureDepthBits ||
			DisplayTexture.format != TextureFormat)
		{
			if (DebugLoggingEnabled)
			{
				Debug.LogFormat(
					"Changing the output texture from ({0}, {1}, {2}, {3}) to ({4}, {5}, {6}, {7}).",
					DisplayTexture.width,
					DisplayTexture.height,
					DisplayTexture.depth,
					DisplayTexture.format,
					TextureWidth,
					TextureHeight,
					TextureDepthBits,
					TextureFormat);
			}

			DisplayTexture.Release();
			DisplayTexture.width = TextureWidth;
			DisplayTexture.height = TextureHeight;
			DisplayTexture.depth = TextureDepthBits;
			DisplayTexture.format = TextureFormat;
			DisplayTexture.Create();
		}
	}

	private void MatchSimulationTextureToDisplayTexture(
		ref RenderTexture inoutSimulationTexture,
		string debugTextureName)
	{
		if (inoutSimulationTexture == null)
		{
			if (DebugLoggingEnabled)
			{
				Debug.LogFormat("Creating the \"{0}\" simulation texture to match the display texture.", debugTextureName);
			}

			inoutSimulationTexture = 
				new RenderTexture(
					DisplayTexture.width, 
					DisplayTexture.height,
					DisplayTexture.depth,
					DisplayTexture.format);
			
			if (InitializationMaterial != null)
			{
				if (DebugLoggingEnabled)
				{
					Debug.LogFormat("Initializing the \"{0}\" simulation texture (via the initialzation material).", debugTextureName);
				}

				Graphics.Blit(
					null, // sourceTexture
					inoutSimulationTexture,
					InitializationMaterial);
			}
		}
		else if (
			inoutSimulationTexture.width != DisplayTexture.width ||
			inoutSimulationTexture.height != DisplayTexture.height ||
			inoutSimulationTexture.depth != DisplayTexture.depth ||
			inoutSimulationTexture.format != DisplayTexture.format)
		{
			if (DebugLoggingEnabled)
			{
				Debug.LogFormat("Updating the \"{0}\" simulation texture to match the display texture.", debugTextureName);
			}
			
			// Attempt to preserve/rescale the simulation's state.
			Graphics.Blit(inoutSimulationTexture, DisplayTexture);
			
			inoutSimulationTexture.Release();
			inoutSimulationTexture.width = DisplayTexture.width;
			inoutSimulationTexture.height = DisplayTexture.height;
			inoutSimulationTexture.depth = DisplayTexture.depth;
			inoutSimulationTexture.format = DisplayTexture.format;
			inoutSimulationTexture.Create();
			
			Graphics.Blit(DisplayTexture, inoutSimulationTexture);
		}
	}
}
