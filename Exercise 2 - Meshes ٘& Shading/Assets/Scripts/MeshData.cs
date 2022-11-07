using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class MeshData
{
    public List<Vector3> vertices; // The vertices of the mesh 
    public List<int> triangles; // Indices of vertices that make up the mesh faces
    public Vector3[] normals; // The normals of the mesh, one per vertex

    // Class initializer
    public MeshData()
    {
        vertices = new List<Vector3>();
        triangles = new List<int>();
    }

    // Returns a Unity Mesh of this MeshData that can be rendered
    public Mesh ToUnityMesh()
    {
        Mesh mesh = new Mesh
        {
            vertices = vertices.ToArray(),
            triangles = triangles.ToArray(),
            normals = normals
        };

        return mesh;
    }

    // Calculates surface normals for each vertex, according to face orientation
    public void CalculateNormals()
    {
        // Your implementation
        int counter = 0;
        Dictionary<int, List<Vector3>> dict = new Dictionary<int, List<Vector3>>();
        // foreach(Vector3 vec in vertices){
        for (int i = 0; i < vertices.Count ; i++){
            List<Vector3> newList = new List<Vector3>();
            dict.Add(i, newList);
        }


        while(counter < triangles.Count){
            Vector3 n = get_surfeace_normal(vertices[triangles[counter]], vertices[triangles[counter+1]], vertices[triangles[counter+2]]);
            dict[triangles[counter]].Add(n);
            dict[triangles[counter+1]].Add(n);
            dict[triangles[counter+2]].Add(n);
            counter += 3;
        }

        List<Vector3> tempNormals = new List<Vector3>();


        for (int i = 0; i < vertices.Count ; i++){
            Vector3 finalNoraml = new Vector3(0,0,0);
            foreach(Vector3 vec in dict[i]){
                finalNoraml += vec;
            }
            tempNormals.Add(finalNoraml.normalized);
        }

        normals = tempNormals.ToArray();
    }
    Vector3 get_surfeace_normal(Vector3 a, Vector3 b, Vector3 c)
    {
        Vector3 n = Vector3.Cross((a-b),(b-c));
        return n.normalized;
    }

    // Edits mesh such that each face has a unique set of 3 vertices
    public void MakeFlatShaded()
    {
        HashSet<int> verSet = new HashSet<int>();

        int counter = vertices.Count;

        for (int i = 0; i < triangles.Count ; i++){
            int tri = triangles[i];
            if (!verSet.Contains(tri)){
                verSet.Add(tri);
            }
            else{
                Vector3 newVec = vertices[tri];
                vertices.Add(newVec);
                triangles[i] = counter;
                counter++;
            }
        }
    }
}