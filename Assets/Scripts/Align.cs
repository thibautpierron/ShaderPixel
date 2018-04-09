using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Align : MonoBehaviour {

	private Material material;
	public bool onlyAtStart = false;
	void Start () {
		material = gameObject.GetComponent<Renderer>().material;
		material.SetVector("_Offset", transform.position);
	}
	
	// Update is called once per frame
	void Update () {
		if (!onlyAtStart)
			material.SetVector("_Offset", transform.position);
	}
}
