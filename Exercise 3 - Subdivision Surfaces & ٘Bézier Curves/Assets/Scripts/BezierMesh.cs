using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;

[ExecuteInEditMode]
public class BezierMesh : MonoBehaviour
{
    private BezierCurve curve; // The Bezier curve around which to build the mesh

    public float Radius = 0.5f; // The distance of mesh vertices from the curve
    public int NumSteps = 2; // Number of points along the curve to sample
    public int NumSides = 4; // Number of vertices created at each point

    // Awake is called when the script instance is being loaded
    public void Awake()
    {
        curve = GetComponent<BezierCurve>();
        BuildMesh();
    }

    // Returns a "tube" Mesh built around the given Bézier curve
    public static Mesh GetBezierMesh(BezierCurve curve, float radius, int numSteps, int numSides)
    {
        QuadMeshData meshData = new QuadMeshData();
        
        // Your implementation here...
        List<Vector3> points = new List<Vector3>();
        List<Vector4> faces = new List<Vector4>();
        for (int i =0; i < numSteps+1 ; i++){
            float t = (float)i / numSteps;
            Vector3 s = curve.GetPoint(t);
            
            Vector3 normal = curve.GetNormal(t);
            Vector3 binormal = curve.GetBinormal(t);
            for (int j = 0; j < numSides; j++){

                Vector2 mekadmin = GetUnitCirclePoint((float)((float)j/numSides) * 360);
                Vector3 point = s + Mathf.Sqrt(radius)*(normal*mekadmin[1] + binormal*mekadmin[0]);
                points.Add(point);
                // GameObject cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
                // cube.transform.position = point;
                // cube.transform.localScale = new Vector3(0.05f,0.05f,0.05f);
              
            }
        }
        for (int i = 0; i < numSteps; i++){
            for (int j = 0; j < numSides; j ++){
                Vector4 face = new Vector4();
                face[0] =   i*numSides+j;
                face[1] = i*numSides+((j+1)%numSides);
                face[2] =  (i+1)*numSides+((j+1)%numSides);
                face[3] =   (i+1)*numSides+j;
                faces.Add(face);
            }
        }

        meshData.vertices = points;
        meshData.quads = faces;
        // Debug.Log("points: "+meshData.vertices.Count);
        // foreach(Vector3 p in meshData.vertices){
        //     print("POINT: "+p);
        // }
        // foreach(Vector4 p in meshData.quads){
        //     print("FACE: "+p);
        // }
        // Debug.Log("faces: "+meshData.quads.Count);
        return meshData.ToUnityMesh();
    }

    // Returns 2D coordinates of a point on the unit circle at a given angle from the x-axis
    private static Vector2 GetUnitCirclePoint(float degrees)
    {
        float radians = degrees * Mathf.Deg2Rad;
        return new Vector2(Mathf.Sin(radians), Mathf.Cos(radians));
    }

    public void BuildMesh()
    {
        var meshFilter = GetComponent<MeshFilter>();
        meshFilter.mesh = GetBezierMesh(curve, Radius, NumSteps, NumSides);
    }

    // Rebuild mesh when BezierCurve component is changed
    public void CurveUpdated()
    {
        BuildMesh();
    }
}



[CustomEditor(typeof(BezierMesh))]
class BezierMeshEditor : Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();
        if (GUILayout.Button("Update Mesh"))
        {
            var bezierMesh = target as BezierMesh;
            bezierMesh.BuildMesh();
        }
    }
}