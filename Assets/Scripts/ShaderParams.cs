using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShaderParams : MonoBehaviour {

	private Material material;

	void Start () {
		material = gameObject.GetComponent<Renderer>().material;
	}

	public void SetSpecular(float value) {
		material.SetFloat("_Specular", value);
	}

	public void SetGloss(float value) {
		material.SetFloat("_Gloss", value);
	}

	public void SetTransparency(float value) {
		material.SetFloat("_Alpha", value);
	}
}
