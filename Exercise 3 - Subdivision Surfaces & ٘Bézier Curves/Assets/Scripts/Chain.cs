using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;

public class Chain : MonoBehaviour
{
    private BezierCurve curve; // The Bezier curve around which to build the chain
    private List<GameObject> chainLinks = new List<GameObject>(); // A list to contain the chain links GameObjects

    public GameObject ChainLink; // Reference to a GameObject representing a chain link
    public float LinkSize = 2.0f; // Distance between links

    // Awake is called when the script instance is being loaded
    public void Awake()
    {
        curve = GetComponent<BezierCurve>();
    }

    // Constructs a chain made of links along the given Bezier curve, updates them in the chainLinks List
    // public void ShowChain()
    // {
    //     // Clean up the list of old chain links
    //     foreach (GameObject link in chainLinks)
    //     {
    //         Destroy(link);
    //     }
    //     // Your implementation here...
    //
    //     Awake(); // TODO DELETE!!!!!
    //     Debug.Log("START");
    //     float f = 0;
    //     int counter = 0;
    //     curve.CalcCumLengths();
    //     float p_t = 0;
    //     while (f < curve.ArcLength()){
    //         float t = curve.ArcLengthToT(f);
    //         // Debug.Log("Dist: "+(t-p_t));
    //         p_t = t;
    //         if (counter%2 == 0){
    //             GameObject ch = CreateChainLink(curve.GetPoint(t), curve.GetTangent(t), curve.GetNormal(t));
    //         } else {
    //             GameObject ch = CreateChainLink(curve.GetPoint(t), curve.GetTangent(t), curve.GetBinormal(t));
    //         }
    //         counter++;
    //         f+=LinkSize;
    //     }
    // }
    
    public void ShowChain()

    {
        Debug.Log("len of chain" + chainLinks.Count);
        // Clean up the list of old chain links
        int i = 0;
        foreach (GameObject link in chainLinks)
        {
            Destroy(link);
            i++;
        }
        Debug.Log("deleted: " + i);
        chainLinks = new List<GameObject>(); // setting a new empty list


        // Your implementation here...

        //Awake(); // TODO DELETE!!!!!
        Debug.Log("START");
        float f = 0;
        int counter = 0;
        curve.CalcCumLengths();
        float p_t = 0;
        while (f < curve.ArcLength()){
            float t = curve.ArcLengthToT(f);
            // Debug.Log("Dist: "+(t-p_t));
            p_t = t;
            GameObject ch;
            if (counter%2 == 0){
                ch = CreateChainLink(curve.GetPoint(t), curve.GetTangent(t), curve.GetNormal(t));
            } else {
                ch = CreateChainLink(curve.GetPoint(t), curve.GetTangent(t), curve.GetBinormal(t));
            }
            chainLinks.Add(ch);
            counter++;
            f+=LinkSize;
        }
    }

    // Instantiates & returns a ChainLink at given position, oriented towards the given forward and up vectors
    public GameObject CreateChainLink(Vector3 position, Vector3 forward, Vector3 up)
    {
        GameObject chainLink = Instantiate(ChainLink);
        chainLink.transform.position = position;
        chainLink.transform.rotation = Quaternion.LookRotation(forward, up);
        chainLink.transform.parent = transform;
        return chainLink;
    }

    // Rebuild chain when BezierCurve component is changed
    public void CurveUpdated()
    {
        ShowChain();
    }
}

[CustomEditor(typeof(Chain))]
class ChainEditor : Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();
        if (GUILayout.Button("Show Chain"))
        {
            var chain = target as Chain;
            chain.ShowChain();
        }
    }
}