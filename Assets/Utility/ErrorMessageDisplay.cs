using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ErrorMessageDisplay : MonoBehaviour
{
	public float FadeInSeconds = 0.25f;
	public float SustainSeconds = 3.0f;
	public float FadeOutSeconds = 1.0f;

	public void Awake()
	{
		textControl = GetComponentInChildren<Text>();
	}

	public void Start()
	{
		textControl.gameObject.SetActive(false);
	}

	public void DisplayMessage(
		string message)
	{
		StopAllCoroutines();

		StartCoroutine(DisplayMessageAsync(message));
	}

	private IEnumerator DisplayMessageAsync(
		string message)
	{
		textControl.text = message;

		textControl.gameObject.SetActive(true);

		textControl.canvasRenderer.SetAlpha(0.0f);
		textControl.CrossFadeAlpha(1.0f, FadeInSeconds, false);
		yield return new WaitForSeconds(FadeInSeconds + SustainSeconds);
		
		textControl.CrossFadeAlpha(0.0f, FadeOutSeconds, false);
		yield return new WaitForSeconds(FadeOutSeconds);

		textControl.gameObject.SetActive(false);
	}

	private Text textControl = null;
}
