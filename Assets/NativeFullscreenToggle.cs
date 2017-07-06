using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class NativeFullscreenToggle : MonoBehaviour
{	
	public void Start()
	{
		wasFullscreen = Screen.fullScreen;
	}

	public void Update()
	{
		if (!wasFullscreen && Screen.fullScreen)
		{
			OnEnteredFullscreen();
		}
		else if (wasFullscreen && !Screen.fullScreen)
		{
			OnEnteredWindowed();
		}
		
		wasFullscreen = Screen.fullScreen;
	}

	private bool wasFullscreen;

	private void OnEnteredFullscreen()
	{
		// Before we disrupt the screen's resolution, save the last known window-size.
		PlayerPrefs.SetInt("Window Width", PlayerPrefs.GetInt("Screenmanager Resolution Width"));
		PlayerPrefs.SetInt("Window Height", PlayerPrefs.GetInt("Screenmanager Resolution Height"));

		Resolution highestResolution = 
			Screen.resolutions
				.OrderByDescending(elem => elem.height)
				.ThenByDescending(elem => elem.width)
				.First();
			
		// Attempt to switch to the display's native resolution.
		Screen.SetResolution(highestResolution.width, highestResolution.height, true);
	}

	private void OnEnteredWindowed()
	{
		// Restore the last known window size.
		Screen.SetResolution(
			PlayerPrefs.GetInt("Window Width", 800), 
			PlayerPrefs.GetInt("Window Height", 600), 
			false);
	}
}
