using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GUITrigger : MonoBehaviour {

	public GameObject panel;

	void OnTriggerEnter(Collider other) {
		panel.SetActive(true);
	}

	void OnTriggerExit(Collider other) {
		panel.SetActive(false);
	}
}
