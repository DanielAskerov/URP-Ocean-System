using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CausticsUtility : MonoBehaviour
{
    [SerializeField] bool updateSunRotation = false;

    Renderer r;

    void Awake()
    {
        r = GetComponent<Renderer>();
        SendSunMatrix( r );
    }

    void FixedUpdate()
    {
        if ( updateSunRotation )
            SendSunMatrix( r );
    }

    void SendSunMatrix(Renderer r)
    {
        r.material.SetMatrix( Shader.PropertyToID( "_LightDirMatrix" ), RenderSettings.sun.transform.localToWorldMatrix );
    }
}
