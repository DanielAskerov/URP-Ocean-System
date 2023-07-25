using UnityEngine;

public class GenerateGrid : MonoBehaviour
{
    [SerializeField] int tileSize;
    [SerializeField] GameObject tile;
    [SerializeField] GameObject ocean;

    void Awake()
    {
        OceanDisplacementData.tileSize = tileSize;

        for ( int z=0; z < tileSize; z++ )
        {
            for (int x=0; x < tileSize; x++)
            {
                Instantiate(tile, new Vector3( ( -tileSize * tile.transform.localScale.x + tile.transform.localScale.x) + ( x * tile.transform.localScale.x * 2 ), 
                                               0,
                                               ( -tileSize * tile.transform.localScale.z + tile.transform.localScale.z) + ( z * tile.transform.localScale.z * 2 )), 
                                               tile.transform.rotation, ocean.transform );
            }
        }

        StaticBatchingUtility.Combine(ocean);
    }
}
