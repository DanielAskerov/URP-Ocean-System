using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BuoyantObject : MonoBehaviour
{
    [SerializeField] float buoyantForce;

    Texture2D displacementTex;
    Rigidbody rb;
    Vector3 displacement;
    
    float drag;
    int tileSize;
    int FFTSize;

    const float gravity = 9.81f;

    void Awake()
    {
        rb = GetComponent<Rigidbody>();
        drag = rb.drag;
    }

    void Start()
    {
        tileSize = OceanDisplacementData.tileSize;
        FFTSize = OceanDisplacementData.FFTSize;
    }

    void FixedUpdate() {

        int x =  WorldToTextureCoords( transform.position.x );
        int y =  WorldToTextureCoords( transform.position.z );

        displacement = GetDisplacementVector( x, y );

        if ( transform.position.y <= displacement.y )
        {
            Vector3 f =  new Vector3 ( displacement.x * buoyantForce,
                                     ( displacement.y - transform.position.y ) * buoyantForce * gravity,
                                       displacement.z * buoyantForce );
            rb.drag = 1f;
            rb.AddForce( f, ForceMode.Acceleration );
        }
        else
        {
            rb.drag = drag;
        }
    }

    int WorldToTextureCoords(float coord)
    {
        float clampedCoord = tileSize - Mathf.Abs( coord - ( tileSize * Mathf.Floor( coord / tileSize ) ) ); 
        float uvCoord = clampedCoord / tileSize;
        int texCoord = Mathf.FloorToInt( uvCoord * FFTSize );

        return texCoord;
    }

    Vector3 GetDisplacementVector(int x, int y)
    {
        RenderTexture.active = OceanDisplacementData.displacementData;
        if ( displacementTex == null )
            displacementTex = new Texture2D( 1, 1, TextureFormat.RGBAHalf, 1, false );

        displacementTex.ReadPixels( new Rect( x, y, 1, 1 ), 0, 0, false );
        Color displacementPix = displacementTex.GetPixel( x, y );

        return new Vector3( displacementPix.r, displacementPix.g, displacementPix.b );
    }
}
