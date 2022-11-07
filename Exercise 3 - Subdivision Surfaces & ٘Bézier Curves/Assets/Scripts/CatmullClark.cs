using System;
using System.Collections.Generic;
using UnityEngine;



public class CCMeshData
{
    public List<Vector3> points; // Original mesh points
    public List<Vector4> faces; // Original mesh quad faces
    public List<Vector4> edges; // Original mesh edges
    public List<Vector3> facePoints; // Face points, as described in the Catmull-Clark algorithm
    public List<Vector3> edgePoints; // Edge points, as described in the Catmull-Clark algorithm
    public List<Vector3> newPoints; // New locations of the original mesh points, according to Catmull-Clark
}


public static class CatmullClark
{
    // Returns a QuadMeshData representing the input mesh after one iteration of Catmull-Clark subdivision.
    public static QuadMeshData Subdivide(QuadMeshData quadMeshData)
    {
        // Create and initialize a CCMeshData corresponding to the given QuadMeshData
        CCMeshData meshData = new CCMeshData();
        meshData.points = quadMeshData.vertices;
        meshData.faces = quadMeshData.quads;
        meshData.edges = GetEdges(meshData);
        meshData.facePoints = GetFacePoints(meshData);
        meshData.edgePoints = GetEdgePoints(meshData);
        meshData.newPoints = GetNewPoints(meshData);

        // Combine facePoints, edgePoints and newPoints into a subdivided QuadMeshData


        List<Vector4> new_faces = new List<Vector4>();
        List<Vector3> new_vertices = quadMeshData.vertices;

        //<face inedx, face point>
        Dictionary<int, Vector3> face_points = Face2FacePointsDict(meshData);

        //<p1 index ,p2 index>, new edge point>
        Dictionary<Tuple<int, int>, int> edge_points = addEdgesToAnExistVerticesList(new_vertices, meshData);

        //<point index, new point>
        Dictionary<int, Vector3> new_points = points2NewPoints(meshData);


        for (int i = 0; i < quadMeshData.quads.Count; i++)
        {
            Vector3 newFacePoint = face_points[i];
            new_vertices.Add(newFacePoint);
            int facePointIndex = new_vertices.Count - 1;

            for (int j = 0; j < 4; j++)
            {

                int currP = (int)quadMeshData.quads[i][j];

                quadMeshData.vertices[currP] = new_points[currP]; // updating old point to new point

                int nextP = (int)quadMeshData.quads[i][(j + 1) % 4]; // get edge to first neighbor
                Tuple<int, int> firstEdge = new Tuple<int, int>(Math.Min(currP, nextP), Math.Max(currP, nextP));
                int firstEdgePointIndex = edge_points[firstEdge];

                int prevP = (int)quadMeshData.quads[i][(j + 3) % 4]; // get edge to second neighbor
                Tuple<int, int> secondEdge = new Tuple<int, int>(Math.Min(currP, prevP), Math.Max(currP, prevP));
                int secondExgePointIndex = edge_points[secondEdge];

             // Vector4 new_face = new Vector4();
                Vector4 new_face = new Vector4(facePointIndex, secondExgePointIndex, currP, firstEdgePointIndex);
                new_faces.Add(new_face);

            }
        }

        QuadMeshData res = new QuadMeshData();
        res.vertices = new_vertices;
        res.quads = new_faces;

        // int check = meshData.facePoints.Count+meshData.edgePoints.Count+meshData.newPoints.Count;
        Debug.Log("edges: " + meshData.edges.Count);
        Debug.Log("facePoints: " + meshData.facePoints.Count);
        Debug.Log("edgePoints: " + meshData.edgePoints.Count);
        Debug.Log("newPoints: " + meshData.newPoints.Count);
        Debug.Log("num of new faces: " + new_faces.Count);
        Debug.Log("num of new vertices: " + new_vertices.Count);
        return res;
    }


    public class TupleEdgeComparer : EqualityComparer<Tuple<int, int>>
    {
        private static readonly float EPSILON = 0.00001f;

        public override bool Equals(Tuple<int, int> tuple1, Tuple<int, int> tuple2)
        {
            Debug.Log("A: " + tuple1 + " , B: " + tuple2);
            if ((Math.Abs(tuple1.Item1 - tuple2.Item1) + Math.Abs(tuple1.Item2 - tuple2.Item2)) < EPSILON)
            {
                return true;
            }
            return false;

        }

        // override object.GetHashCode
        public override int GetHashCode(Tuple<int, int> tuple1)
        {
            return 0;
        }
    }

    // Returns a list of all edges in the mesh defined by given points and faces.
    // Each edge is represented by Vector4(p1, p2, f1, f2)
    // p1, p2 are the edge vertices
    // f1, f2 are faces incident to the edge. If the edge belongs to one face only, f2 is -1
    public static List<Vector4> GetEdges(CCMeshData mesh)
    {
        List<Vector4> res = new List<Vector4>();
        Dictionary<Tuple<int, int>, List<int>> dict = new Dictionary<Tuple<int, int>, List<int>>();
        for (int face_ind = 0; face_ind < mesh.faces.Count; face_ind++)
        {
            for (int i = 0; i < 4; i++)
            {

                int minIndex = Math.Min((int)mesh.faces[face_ind][i % 4], (int)mesh.faces[face_ind][(i + 1) % 4]);
                int maxIndex = Math.Max((int)mesh.faces[face_ind][i % 4], (int)mesh.faces[face_ind][(i + 1) % 4]);

                Tuple<int, int> edge = new Tuple<int, int>(minIndex, maxIndex);
                if (dict.ContainsKey(edge))
                {
                    dict[edge].Add(face_ind);
                }

                else
                {
                    dict.Add(edge, new List<int>());
                    dict[edge].Add(face_ind);
                }
            }
        }
        foreach (Tuple<int, int> edge in dict.Keys)
        {
            if (dict[edge].Count > 1)
            {
                res.Add(new Vector4(edge.Item1, edge.Item2, dict[edge][0], dict[edge][1]));
            }
            else
            {
                Debug.Log("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" + dict[edge].Count);
                Debug.Log(dict[edge]);
                res.Add(new Vector4(edge.Item1, edge.Item2, dict[edge][0], -1));
            }
        }
        // foreach (Tuple<int, int> a in dict.Keys){
        //     Debug.Log(a);
        // }
        return res;
    }

    // Returns a list of "face points" for the given CCMeshData, as described in the Catmull-Clark algorithm 
    public static List<Vector3> GetFacePoints(CCMeshData mesh)
    {
        List<Vector3> face_points = new List<Vector3>();
        // for (int face_index = 0; face_index < mesh.faces.Count; face_index++){
        //     face_points.Add(get_face_point(face_index, mesh));
        // } 
        Dictionary<int, Vector3> face_points_dict = Face2FacePointsDict(mesh);
        face_points.AddRange(face_points_dict.Values);
        //If not working use below
        // foreach (Vector3 face in face_points_dict.Values){
        //     face_points.Add(face);
        // }
        return face_points;
    }

    public static Dictionary<int, Vector3> Face2FacePointsDict(CCMeshData mesh)
    // returns a dict that maches face index to the face's face point.
    {
        Dictionary<int, Vector3> res = new Dictionary<int, Vector3>();

        for (int face_index = 0; face_index < mesh.faces.Count; face_index++)
        {
            res.Add(face_index, get_face_point(face_index, mesh));
        }
        return res;
    }

    private static Vector3 get_face_point(int face_index, CCMeshData mesh)
    {
        Vector3 avrg = new Vector3();
        for (int i = 0; i < 4; i++)
        {
            avrg += mesh.points[(int)mesh.faces[face_index][i]];
        }
        return avrg / 4;
    }

    // Returns a list of "edge points" for the given CCMeshData, as described in the Catmull-Clark algorithm 
    public static List<Vector3> GetEdgePoints(CCMeshData mesh)
    {
        List<Vector3> edge_points = new List<Vector3>();
        // foreach (Vector4 edge in GetEdges(mesh)){
        //     //edge = p1, p2, f1 ,f2
        //     Vector3 edge_point = new Vector3();
        //     if (edge[3] >= 0){
        //          edge_point = mesh.points[(int)edge[0]] + mesh.points[(int)edge[1]]
        //          + get_face_point((int)edge[2], mesh) +get_face_point((int)edge[3], mesh);
        //          edge_point /= 4;
        //     } else {
        //             edge_point = mesh.points[(int)edge[0]] + mesh.points[(int)edge[1]]
        //          + get_face_point((int)edge[2], mesh);
        //          edge_point /= 3;
        //     }
        //     edge_points.Add(edge_point);
        // }

        edge_points.AddRange(Edge2EdgePointDict(mesh).Values);
        return edge_points;
    }


    public static Dictionary<Tuple<int, int>, Vector3> Edge2EdgePointDict(CCMeshData mesh)
    // returns a dict that maches edge index to the edge's edge point.
    {
        Dictionary<Tuple<int, int>, Vector3> res = new Dictionary<Tuple<int, int>, Vector3>();
        foreach (Vector4 edge in GetEdges(mesh))
        {
            //edge = p1, p2, f1 ,f2
            Vector3 edge_point = new Vector3();
            if (edge[3] >= 0)
            {
                edge_point = mesh.points[(int)edge[0]] + mesh.points[(int)edge[1]]
                + get_face_point((int)edge[2], mesh) + get_face_point((int)edge[3], mesh);
                edge_point /= 4;
            }
            else
            {
                edge_point = mesh.points[(int)edge[0]] + mesh.points[(int)edge[1]]
             + get_face_point((int)edge[2], mesh);
                edge_point /= 3;
            }
            res.Add(Tuple.Create<int, int>((int)edge[0], (int)edge[1]), edge_point);
        }
        return res;
    }

    public static Dictionary<Tuple<int, int>, int> addEdgesToAnExistVerticesList(List<Vector3> currentVertices, CCMeshData mesh)
    {

        Dictionary<Tuple<int, int>, int> res = new Dictionary<Tuple<int, int>, int>();

        Dictionary<Tuple<int, int>, Vector3> edgesToEdgePoints = Edge2EdgePointDict(mesh);

        foreach (Tuple<int, int> edge in edgesToEdgePoints.Keys)
        {
            currentVertices.Add(edgesToEdgePoints[edge]);
            res.Add(edge, currentVertices.Count - 1);
        }

        return res;
    }

    private static Dictionary<int, HashSet<int>> pointes2facesDict(CCMeshData mesh)
    {
        // matches between an index of a point to a list of indecies of faces that connected to it?
        Dictionary<int, HashSet<int>> dict = new Dictionary<int, HashSet<int>>();
        List<Vector4> edges = GetEdges(mesh);
        for (int i = 0; i < edges.Count; i++)
        {

            if (!dict.ContainsKey((int)edges[i][0]))
            {
                dict.Add((int)edges[i][0], new HashSet<int>());
            }
            dict[(int)edges[i][0]].Add((int)edges[i][2]);
            if ((int)edges[i][3] != -1)
            {
                dict[(int)edges[i][0]].Add((int)edges[i][3]);
            }

            if (!dict.ContainsKey((int)edges[i][1]))
            {
                dict.Add((int)edges[i][1], new HashSet<int>());
            }
            dict[(int)edges[i][1]].Add((int)edges[i][2]);
            if ((int)edges[i][3] != -1)
            {
                dict[(int)edges[i][1]].Add((int)edges[i][3]);
            }
        }
        return dict;
    }

    private static Dictionary<int, HashSet<Tuple<int, int>>> pointes2edgesDict(CCMeshData mesh)
    {
        // matches between an index of a point to a list of indecies of faces that connected to it?
        Dictionary<int, HashSet<Tuple<int, int>>> dict = new Dictionary<int, HashSet<Tuple<int, int>>>();
        List<Vector4> edges = GetEdges(mesh);
        for (int i = 0; i < edges.Count; i++)
        {
            if (!dict.ContainsKey((int)edges[i][0]))
            {
                dict.Add((int)edges[i][0], new HashSet<Tuple<int, int>>());
            }
            dict[(int)edges[i][0]].Add(new Tuple<int, int>((int)edges[i][0], (int)edges[i][1]));

            if (!dict.ContainsKey((int)edges[i][1]))
            {
                dict.Add((int)edges[i][1], new HashSet<Tuple<int, int>>());
            }
            dict[(int)edges[i][1]].Add(new Tuple<int, int>((int)edges[i][0], (int)edges[i][1]));
        }
        return dict;
    }




    // Returns a list of new locations of the original points for the given CCMeshData, as described in the CC algorithm 
    public static List<Vector3> GetNewPoints(CCMeshData mesh)
    {

        List<Vector3> result = new List<Vector3>();

        // Dictionary<int, HashSet<int>> pointes2faces = pointes2facesDict(mesh);
        // Dictionary <int, HashSet<Tuple<int,int>>> points2edges = pointes2edgesDict(mesh);

        // for (int i = 0; i < mesh.points.Count; i++){
        //     if (pointes2faces.ContainsKey(i)){
        //         int n = pointes2faces[i].Count;
        //         Vector3 f = new Vector3();
        //         foreach (int j in pointes2faces[i]){
        //             f += get_face_point(j ,mesh);
        //         }
        //         f /= n;

        //         Vector3 r = new Vector3();
        //         foreach (Tuple<int,int> edge in points2edges[i]){
        //             r += (mesh.points[edge.Item1] + mesh.points[edge.Item2])/2;
        //         }
        //         r /= n;

        //         result.Add((f+2*r+(n-3)*mesh.points[i])/n);
        //     }
        // }
        // return result;
        result.AddRange(points2NewPoints(mesh).Values);
        return result;
    }

    public static Dictionary<int, Vector3> points2NewPoints(CCMeshData mesh)
    {

        // List<Vector3> result = new List<Vector3>();
        Dictionary<int, Vector3> res = new Dictionary<int, Vector3>();
        Dictionary<int, HashSet<int>> pointes2faces = pointes2facesDict(mesh);
        Dictionary<int, HashSet<Tuple<int, int>>> points2edges = pointes2edgesDict(mesh);

        for (int i = 0; i < mesh.points.Count; i++)
        {
            if (pointes2faces.ContainsKey(i))
            {
                int n = pointes2faces[i].Count;
                Vector3 f = new Vector3();
                foreach (int j in pointes2faces[i])
                {
                    f += get_face_point(j, mesh);
                }
                f /= n;

                Vector3 r = new Vector3();
                foreach (Tuple<int, int> edge in points2edges[i])
                {
                    r += (mesh.points[edge.Item1] + mesh.points[edge.Item2]) / 2;
                }
                r /= n;

                // Debug.Log(f+2*r+(n-3)*mesh.points[i])/n);

                Vector3 np = (f + 2 * r + (n - 3) * mesh.points[i]) / n;
                res.Add(i, np);
            }
        }
        return res;
    }
}


