using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CubeAnimation : MonoBehaviour {

	public float speed = 1;

	void Update () {
		gameObject.transform.Rotate(Vector3.up * speed * Time.deltaTime);
	}
}
