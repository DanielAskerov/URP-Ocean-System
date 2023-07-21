using UnityEngine;

public class GenerateGrid : MonoBehaviour
{
    [SerializeField] int size;
    [SerializeField] GameObject tile;
    [SerializeField] GameObject ocean;

    void Start()
    {
        //int bound = (int)Mathf.Ceil(size / 2f ) + size % 2;
        for ( int z=0; z < size; z++ )
        {
            for (int x=0; x < size; x++)
            {
                Instantiate(tile, new Vector3( ( -size * tile.transform.localScale.x + tile.transform.localScale.x) + ( x * tile.transform.localScale.x * 2 ), 
                                               0,
                                               ( -size * tile.transform.localScale.z + tile.transform.localScale.z) + ( z * tile.transform.localScale.z * 2 )), 
                                               tile.transform.rotation, ocean.transform );
            }
        }

        StaticBatchingUtility.Combine(ocean);
    }
}
