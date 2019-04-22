using UnityEngine;
using System.Collections;

namespace TAK_CameraController
{
	enum MouseButtonDown
	{
		MBD_LEFT = 0,
		MBD_RIGHT,
		MBD_MIDDLE,
	};
	
	public class CameraController : MonoBehaviour
	{
		[SerializeField]
		private Vector3 focus = Vector3.up;
		[SerializeField]
		private GameObject focusObj = null;
		
		private Vector3 oldPos;
		
		void setupFocusObject(string name)
		{
			GameObject obj = this.focusObj = new GameObject(name);
			obj.transform.position = this.focus;
			obj.transform.LookAt(this.transform.position);
			
			return;
		}
		
		void Start ()
		{
			if (this.focusObj == null)
				this.setupFocusObject("CameraFocusObject");
			
			Transform trans = this.transform;
			transform.parent = this.focusObj.transform;

			trans.LookAt(this.focus + new Vector3(0, 1, 1));
			
			return;
		}
		
		void Update ()
		{
			this.mouseEvent();
			
			return;
		}
		
		void mouseEvent()
		{
			float delta = Input.GetAxis("Mouse ScrollWheel");
			if (delta != 0.0f)
				this.mouseWheelEvent(delta);
			
			if (Input.GetMouseButtonDown((int)MouseButtonDown.MBD_LEFT) ||
			    Input.GetMouseButtonDown((int)MouseButtonDown.MBD_MIDDLE) ||
			    Input.GetMouseButtonDown((int)MouseButtonDown.MBD_RIGHT))
				this.oldPos = Input.mousePosition;
			
			this.mouseDragEvent(Input.mousePosition);
			
			return;
		}
		
		void mouseDragEvent(Vector3 mousePos)
		{
			Vector3 diff = mousePos - oldPos;
			
			if (Input.GetMouseButton((int)MouseButtonDown.MBD_LEFT))
			{
				if (diff.magnitude > Vector3.kEpsilon)
					this.cameraTranslate(-diff / 100.0f);				
			}else if (Input.GetMouseButton((int)MouseButtonDown.MBD_MIDDLE))
			{
				if (diff.magnitude > Vector3.kEpsilon)
					this.cameraRotate(new Vector3(diff.y, diff.x, 0.0f));
				
			}else if (Input.GetMouseButton((int)MouseButtonDown.MBD_RIGHT))
			{

			}
			
			this.oldPos = mousePos;
			
			return;
		}
		
		public void mouseWheelEvent(float delta)
		{
			Vector3 focusToPosition = this.transform.position - this.focus;
			
			Vector3 post = focusToPosition * (1.0f + delta);
			
			if (post.magnitude > 0.01)
				this.transform.position = this.focus + post;
			
			return;
		}
		
		void cameraTranslate(Vector3 vec)
		{
			Transform focusTrans = this.focusObj.transform;
			
			vec.x *= -1;
			
			focusTrans.Translate(Vector3.right * vec.x);
			focusTrans.Translate(Vector3.up * vec.y);
			
			this.focus = focusTrans.position;
			
			return;
		}
		
		public void cameraRotate(Vector3 eulerAngle)
		{
			Transform focusTrans = this.focusObj.transform;
			focusTrans.localEulerAngles = focusTrans.localEulerAngles + eulerAngle;
			this.transform.LookAt(this.focus+ new Vector3(0, 1, 0));
			
			return;
		}
	}
}