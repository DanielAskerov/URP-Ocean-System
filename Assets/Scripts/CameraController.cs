using UnityEngine;

public class CameraController : MonoBehaviour
{
    [SerializeField] float velocity = 50f;
    [SerializeField] float sensitivity = 1000f;

    float h;
    float v;
    float mouseX;
    float mouseY;

    void Update()
    {
        h = Input.GetAxis("Horizontal") * velocity * Time.deltaTime;
        v = Input.GetAxis("Vertical") * velocity * Time.deltaTime;
        mouseX += Input.GetAxis("Mouse X") * sensitivity * Time.deltaTime;
        mouseY += Input.GetAxis("Mouse Y") * sensitivity * Time.deltaTime;

        transform.Translate( Vector3.forward * v );
        transform.Translate( Vector3.right * h );

        transform.eulerAngles = ( new Vector3( -mouseY, mouseX, 0f) );
    }
}
