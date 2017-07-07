using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FragmentShaderSimulation : MonoBehaviour
{
	public int TextureWidth = 512;
	public int TextureHeight = 512;
	public int TextureDepthBits = 0;
	public RenderTextureFormat TextureFormat = RenderTextureFormat.ARGBFloat;
	public TextureWrapMode TextureWrapMode = TextureWrapMode.Clamp;

	public RenderTexture DisplayTexture = null;
	
	public Material InitializationMaterial = null;
	public Material IterationMaterial = null;
	public Material DisplayMaterial = null;
	
	public bool DebugLoggingEnabled = false;
	public bool DebugDisplayRawSimulation = false;
	public bool DebugInitializeOnResize = false;
	public bool DebugSingleStepOnSpace = false;

	public void Awake()
	{
		if (DisplayTexture == null)
		{
			CreateOrUpdateRenderTextureConfiguration(ref DisplayTexture, false, "display");
		}
	}

	public void Update()
	{
		// Make sure the textures are created and set to the appropriate format.
		CreateOrUpdateRenderTextureConfiguration(ref DisplayTexture, false, "display");			
		CreateOrUpdateRenderTextureConfiguration(ref currentSimulationTexture, true, "current_sim");
		CreateOrUpdateRenderTextureConfiguration(ref previousSimulationTexture, true, "previous_sim");

		// Advance the simulation.
		if ((IterationMaterial != null) &&
			((DebugSingleStepOnSpace == false) || Input.GetKeyDown(KeyCode.Space)))
		{
			RenderTexture swapTemp = currentSimulationTexture;
			currentSimulationTexture = previousSimulationTexture;
			previousSimulationTexture = swapTemp;
			
			IterationMaterial.SetInt("_SimulationIterationIndex", simulationIterationIndex);

			Graphics.Blit(
				previousSimulationTexture,
				currentSimulationTexture,
				IterationMaterial);

			simulationIterationIndex++;
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

	private int simulationIterationIndex = 0;	

	private void CreateOrUpdateRenderTextureConfiguration(
		ref RenderTexture inoutTexture,
		bool isSimulationTexture,
		string debugTextureName)
	{
		if (inoutTexture == null)
		{
			if (DebugLoggingEnabled)
			{
				Debug.LogFormat("Creating the \"{0}\" texture.", debugTextureName);
			}

			inoutTexture = 
				new RenderTexture(
					TextureWidth, 
					TextureHeight,
					TextureDepthBits,
					TextureFormat);

			inoutTexture.wrapMode = TextureWrapMode;

			if (isSimulationTexture)
			{
				// Kill mip-mapping with a vengeance, because otherwise it'll completely bork the simulation.
				inoutTexture.autoGenerateMips = false;
				inoutTexture.useMipMap = false;

				// Assuming the shader is texel-aligned, this just saves us unecessary texture-reads.
				inoutTexture.filterMode = FilterMode.Point;
			}
			
			if (isSimulationTexture &&
				(InitializationMaterial != null))
			{
				if (DebugLoggingEnabled)
				{
					Debug.LogFormat("Initializing the \"{0}\" simulation texture (via the initialzation material).", debugTextureName);
				}

				Graphics.Blit(
					null, // sourceTexture
					inoutTexture,
					InitializationMaterial);
			}
		}
		else if (
			inoutTexture.width != TextureWidth ||
			inoutTexture.height != TextureHeight ||
			inoutTexture.depth != TextureDepthBits ||
			inoutTexture.format != TextureFormat ||
			inoutTexture.wrapMode != TextureWrapMode)
		{
			if (DebugLoggingEnabled)
			{
				Debug.LogFormat("Updating the \"{0}\" texture.", debugTextureName);
			}
			
			// Use the display texture as a scratch in an attempt to preserve/rescale the simulation state.
			if (isSimulationTexture)
			{
				Graphics.Blit(inoutTexture, DisplayTexture);
			}
			
			inoutTexture.Release();
			inoutTexture.width = TextureWidth;
			inoutTexture.height = TextureHeight;
			inoutTexture.depth = TextureDepthBits;
			inoutTexture.format = TextureFormat;
			inoutTexture.wrapMode = TextureWrapMode;
			inoutTexture.Create();
			
			if (isSimulationTexture)
			{
				Graphics.Blit(DisplayTexture, inoutTexture);
			}

			if (DebugInitializeOnResize &&
				isSimulationTexture)
			{
				Graphics.Blit(
					null, // sourceTexture
					inoutTexture,
					InitializationMaterial);
			}
		}
	}
}
