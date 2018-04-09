using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class Rotate : MonoBehaviour {

	private Material material;
	public float rotateSpeed = 30.0f;
	public bool negative = false;

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

	public void SetRotationSpeed(float value) {
		rotateSpeed = value;
	}

	public void SetNegative(Text t) {
		negative = !negative;
		if (negative) {
			material.SetInt("_Neg", 1);
			t.text = "ON";
		}
		else {
			material.SetInt("_Neg", 0);
			t.text = "OFF";
		}
	}
}
