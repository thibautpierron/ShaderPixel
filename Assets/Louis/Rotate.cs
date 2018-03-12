using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Rotate : MonoBehaviour {

	private Material material;
	public float rotateSpeed = 30.0f;

	void Start () {
		material = gameObject.GetComponent<Renderer>().material;
	}
	
	// Update is called once per frame
	void Update () {
		float amount = Time.time * rotateSpeed;
		Quaternion rot = Quaternion.Euler(amount, amount, amount);
        Matrix4x4 m = Matrix4x4.TRS(Vector3.zero, rot, Vector3.one);
        material.SetMatrix("_Rotation", m);
	}
}
