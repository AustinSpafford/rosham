using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MimicScreenSize : MonoBehaviour
{
	public bool DebugLoggingEnabled = false;
	
	public void Awake()
	{
		fragmentShaderSimulation = GetComponent<FragmentShaderSimulation>();
	}

	public void Start()
	{
		UpdateSize();
	}

	public void Update()
	{
		if ((Screen.width != currentWidth) ||
			(Screen.height != currentHeight))
		{
			UpdateSize();
		}
	}
	
	private FragmentShaderSimulation fragmentShaderSimulation = null;

	private int currentWidth = -1;
	private int currentHeight = -1;
	
	private void UpdateSize()
	{
		if (DebugLoggingEnabled)
		{
			Debug.LogFormat(
				"Mimicking the screen size by changing from ({0}, {1}) to ({2}, {3}).",
				currentWidth,
				currentHeight,
				Screen.width,
				Screen.height);
		}

		currentWidth = Screen.width;
		currentHeight = Screen.height;
		
		float aspectRatio = (currentWidth / (float)currentHeight);

		Vector3 localScale = transform.localScale;
		localScale.x = (aspectRatio * localScale.y);
		transform.localScale = localScale;

		if (fragmentShaderSimulation != null)
		{
			fragmentShaderSimulation.TextureWidth = currentWidth;
			fragmentShaderSimulation.TextureHeight = currentHeight;
		}
	}	
}
