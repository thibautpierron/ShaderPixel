using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Controls : MonoBehaviour {

	public float speed = 1;
	public float sensibility = 1;
	private CharacterController cc;
	private GameManager gm;
    private float yaw = 90;
    private float pitch = 0;
	private bool freeMouse = false;

	void Start () {
		cc = GetComponent<CharacterController>();
		gm = GameObject.Find("GameManager").GetComponent<GameManager>();
	}

	// Update is called once per frame
	void Update () {
		if (Input.GetMouseButtonDown(1)) { 
			freeMouse = !freeMouse;
		}
		if (freeMouse == false) {
			int acc = 1;
			// if (Input.GetKeyDown("a"))
			// 	gameObject.GetComponent<AudioSource>().Play();
			// if (Input.GetKeyUp("a"))
			// 	gameObject.GetComponent<AudioSource>().Stop();

			if (Input.GetKey(KeyCode.LeftShift))
				acc = 2;

			yaw += sensibility * Input.GetAxis("Mouse X");
			pitch -= sensibility * Input.GetAxis("Mouse Y");
			Camera.main.transform.eulerAngles = new Vector3(pitch, yaw, 0.0f);

			Vector3 camForward = new Vector3(Camera.main.transform.forward.x, 0, Camera.main.transform.forward.z);
			Vector3 camRight = new Vector3(Camera.main.transform.right.x, 0, Camera.main.transform.right.z);
			camForward.Normalize();
			camRight.Normalize();
			cc.Move(camForward * Input.GetAxis("Vertical") * Time.deltaTime * speed * acc);
			cc.Move(camRight * Input.GetAxis("Horizontal") * Time.deltaTime * speed * acc);
			cc.Move(new Vector3(0, -9.8f * Time.deltaTime, 0));
		}
	}
}