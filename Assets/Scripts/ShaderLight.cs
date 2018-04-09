using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShaderLight : MonoBehaviour {

	public GameObject shaderSupport;
	public GameObject lightSupport;
	public float speed = 10;
	private Material material;
	void Start () {
		material = shaderSupport.GetComponent<MeshRenderer>().material;
	}
	
	// Update is called once per frame
	void Update () {
		transform.Rotate(new Vector3(0, Time.deltaTime * speed, 0));
		material.SetVector("_Light", Vector3.Normalize(lightSupport.transform.position - shaderSupport.transform.position));
	}
}
