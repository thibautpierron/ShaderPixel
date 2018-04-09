using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class VisualSound : MonoBehaviour {

	public AudioSource audioSource;
	private Material material;
	public int sampleNbr = 4;
	public FFTWindow fftWindow;
	private	float[] spectrum;
	void Start () {
		spectrum = new float[sampleNbr];
		material = gameObject.GetComponent<Renderer>().material;
	}
	
	void Update () {
		audioSource.GetSpectrumData(spectrum, 0, fftWindow);
		material.SetFloat("_R1", spectrum[0]);
		material.SetFloat("_R2", spectrum[1]);
		material.SetFloat("_R3", spectrum[2]);
		material.SetFloat("_R4", spectrum[3]);
	}
}
