using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Align : MonoBehaviour {

	private Material material;
	void Start () {
		material = gameObject.GetComponent<Renderer>().material;
	}
	
	// Update is called once per frame
	void Update () {
		material.SetVector("_Offset", transform.position);
	}
}
