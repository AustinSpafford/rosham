using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class FragmentShaderSimulation : MonoBehaviour
{
	public int TextureWidth = 512;
	public int TextureHeight = 512;
	public int TextureDepthBits = 0;
	public RenderTextureFormat TextureFormat = RenderTextureFormat.ARGBFloat;
	public TextureWrapMode TextureWrapMode = TextureWrapMode.Clamp;
	public FilterMode TextureFilterMode = FilterMode.Point;

	public RenderTexture DisplayTexture = null;
	
	public Material InitializationMaterial = null;
	public List<Material> SimulationPassMaterials = null;
	public Material DisplayMaterial = null;
	public Material CursorInputMaterial = null;

	public int IterationsPerUpdate = 1;
	
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

		// Provide cursor-input.
		if (CursorInputMaterial != null)
		{
			RenderTexture swapTemp = currentSimulationTexture;
			currentSimulationTexture = previousSimulationTexture;
			previousSimulationTexture = swapTemp;
			
			CursorInputMaterial.SetInt("_SimulationIterationIndex", simulationIterationIndex);
			CursorInputMaterial.SetFloat("_DeltaTime", Time.deltaTime);

			Rect screenRect = new Rect(0, 0, Screen.width, Screen.height);
			bool cursorIsActive = screenRect.Contains(Input.mousePosition);

			Vector3 screenToNormalized = new Vector3((1.0f / Screen.width), (1.0f / Screen.height), 1.0f);
			Vector3 normalizedCursorPosition = Vector3.Scale(Input.mousePosition, screenToNormalized);
			
			// To keep the reported cursor from jumping across an entire window when the OS-cursor moved around
			// the outside, only report deltas between consecutive valid frames.
			Vector3 cursorPositionDelta = 
				(previousCursorIsActive && cursorIsActive) ?
					(normalizedCursorPosition - previousCursorPosition) :
					Vector3.zero;

			CursorInputMaterial.SetInt("_CursorIsActive", (cursorIsActive ? 1 : 0));
			CursorInputMaterial.SetVector("_CursorPosition", normalizedCursorPosition);
			CursorInputMaterial.SetVector("_CursorPositionDelta", cursorPositionDelta);
			CursorInputMaterial.SetVector("_CursorButtonPressed", new Vector3((Input.GetMouseButton(0) ? 1.0f : 0.0f), (Input.GetMouseButton(1) ? 1.0f : 0.0f), (Input.GetMouseButton(2) ? 1.0f : 0.0f)));
			CursorInputMaterial.SetVector("_CursorButtonClicked", new Vector3((Input.GetMouseButtonDown(0) ? 1.0f : 0.0f), (Input.GetMouseButtonDown(1) ? 1.0f : 0.0f), (Input.GetMouseButtonDown(2) ? 1.0f : 0.0f)));
			CursorInputMaterial.SetVector("_CursorButtonUnclicked", new Vector3((Input.GetMouseButtonUp(0) ? 1.0f : 0.0f), (Input.GetMouseButtonUp(1) ? 1.0f : 0.0f), (Input.GetMouseButtonUp(2) ? 1.0f : 0.0f)));

			Graphics.Blit(
				previousSimulationTexture,
				currentSimulationTexture,
				CursorInputMaterial);

			previousCursorIsActive = cursorIsActive;
			previousCursorPosition = normalizedCursorPosition;
		}

		// Advance the simulation.
		if ((DebugSingleStepOnSpace == false) || 
			Input.GetKeyDown(KeyCode.Space))
		{
			float iterationDeltaTime = (Time.deltaTime / (float)IterationsPerUpdate);

			for (int index = 0; index < IterationsPerUpdate; index++)
			{
				foreach (Material simulationPassMaterial in SimulationPassMaterials.Where(elem => (elem != null)))
				{
					RenderTexture swapTemp = currentSimulationTexture;
					currentSimulationTexture = previousSimulationTexture;
					previousSimulationTexture = swapTemp;
			
					simulationPassMaterial.SetInt("_SimulationIterationIndex", simulationIterationIndex);
					simulationPassMaterial.SetFloat("_DeltaTime", iterationDeltaTime);

					Graphics.Blit(
						previousSimulationTexture,
						currentSimulationTexture,
						simulationPassMaterial);
				}
				
				simulationIterationIndex++;
			}
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
			DisplayMaterial.SetInt("_SimulationIterationIndex", simulationIterationIndex);
			DisplayMaterial.SetFloat("_DeltaTime", Time.deltaTime);

			Graphics.Blit(
				currentSimulationTexture,
				DisplayTexture,
				DisplayMaterial);
		}
	}
	
	private RenderTexture currentSimulationTexture = null;
	private RenderTexture previousSimulationTexture = null;

	private int simulationIterationIndex = 0;	

	private bool previousCursorIsActive = false;
	private Vector3 previousCursorPosition = Vector3.zero;

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
			}
			
			if (isSimulationTexture &&
				(InitializationMaterial != null))
			{
				if (DebugLoggingEnabled)
				{
					Debug.LogFormat("Initializing the \"{0}\" simulation texture (via the initialzation material).", debugTextureName);
				}
				
				InitializationMaterial.SetVector(
					"_MainTex_TexelSize", 
					new Vector4(
						(1.0f / TextureWidth), 
						(1.0f / TextureHeight), 
						TextureWidth, 
						TextureHeight));

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
			inoutTexture.wrapMode != TextureWrapMode ||
			inoutTexture.filterMode != TextureFilterMode)
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
			inoutTexture.filterMode = TextureFilterMode;
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
