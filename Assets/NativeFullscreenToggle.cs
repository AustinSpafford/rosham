using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class NativeFullscreenToggle : MonoBehaviour
{
	public bool DebugLoggingEnabled = false;

	public void Update()
	{
		if ((Input.GetKey(KeyCode.LeftAlt) || Input.GetKey(KeyCode.RightAlt)) && 
			Input.GetKeyDown(KeyCode.Return))
		{
			// BLARG! Instead, we need to just respond with resolution-fixes when the built in Alt+Enter takes action.

			if (Screen.fullScreen)
			{
				Screen.SetResolution(savedWindowResolution.width, savedWindowResolution.height, false);
			}
			else
			{
				savedWindowResolution = Screen.currentResolution;

				Resolution highestResolution = 
					Screen.resolutions
						.OrderByDescending(elem => elem.height)
						.ThenByDescending(elem => elem.width)
						.First();

				Screen.SetResolution(highestResolution.width, highestResolution.height, true);
			}
		}
	}

	private Resolution savedWindowResolution;
}
