using System.Collections.Generic;
using System.Linq;
using UnityEngine;


public class BezierCurve : MonoBehaviour
{
    // Bezier control points
    public Vector3 p0;
    public Vector3 p1;
    public Vector3 p2;
    public Vector3 p3;

    private float[] cumLengths; // Cumulative lengths lookup table
    private readonly int numSteps = 128; // Number of points to sample for the cumLengths LUT

    // Returns position B(t) on the Bezier curve for given parameter 0 <= t <= 1
    public Vector3 GetPoint(float t)
    {
        Vector3 res = Mathf.Pow((1-t),3)*p0+3*Mathf.Pow((1-t),2)*t*p1+3*(1-t)*t*t*p2+t*t*t*p3;
        return res;
    }

    // Returns first derivative B'(t) for given parameter 0 <= t <= 1
    public Vector3 GetFirstDerivative(float t)
    {
        Vector3 res = 3*Mathf.Pow((1-t),2)*(p1-p0)+6*(1-t)*t*(p2-p1)+3*t*t*(p3-p2);
        return res;
    }

    // Returns second derivative B''(t) for given parameter 0 <= t <= 1
    public Vector3 GetSecondDerivative(float t)
    {
        Vector3 res = 6*(1-t)*(p2-2*p1+p0)+6*t*(p3-2*p2+p1);
        return res;
    }

    // Returns the tangent vector to the curve at point B(t) for a given 0 <= t <= 1
    public Vector3 GetTangent(float t)
    {
        Vector3 der = GetFirstDerivative(t);
        return der.normalized;
    }

    // Returns the Frenet normal to the curve at point B(t) for a given 0 <= t <= 1
    public Vector3 GetNormal(float t)
    {
        Vector3 der = GetFirstDerivative(t);
        Vector3 sec_der = GetSecondDerivative(t);
        Vector3 frenet_normal = Vector3.Cross(GetBinormal(t),GetTangent(t));
        return frenet_normal.normalized;
    }

    // Returns the Frenet binormal to the curve at point B(t) for a given 0 <= t <= 1
    public Vector3 GetBinormal(float t)
    {
        Vector3 der = GetFirstDerivative(t);
        Vector3 sec_der = GetSecondDerivative(t);
        Vector3 t_tag = (der+sec_der).normalized;
        Vector3 binormal = Vector3.Cross(GetTangent(t),t_tag);
        return binormal.normalized;
    }

    // Calculates the arc-lengths lookup table
    public void CalcCumLengths()
    {
        // Your implementation here...
        cumLengths = new float[numSteps+1];
        cumLengths[0]=(0);
        float t_prev = 0;
        Vector3 s_prev = GetPoint(t_prev);
        for (int i = 1 ; i< numSteps+1; i++){
            float t = (float)i / numSteps;
            Vector3 s = GetPoint(t);
            cumLengths[i] = Vector3.Distance(s,s_prev)+cumLengths[i-1];
            s_prev = s;
        }
    }

    // Returns the total arc-length of the Bezier curve
    public float ArcLength()
    {
        return cumLengths[numSteps];
    }

    // Returns approximate t s.t. the arc-length to B(t) = arcLength
    public float ArcLengthToT(float a)
    {
        //i
        int i = 0;
        while ( cumLengths[i] < a && i <= cumLengths.Length){	
            if (cumLengths[i+1] >= a){
                break;
                }
            i++;
        }
        Debug.Log("A: "+a+" I: "+i);
         //ii
         float lerp = 0;
         if (i < cumLengths.Length){
            // Debug.Log("CUMLENGTH[i] = "+cumLengths[i]);
            
            lerp = Mathf.InverseLerp(cumLengths[i],cumLengths[i+1], a);
            // Debug.Log("LERP: "+lerp);
         }
         return (i+lerp)/numSteps;
    }

    // Start is called before the first frame update
    public void Start()
    {
        Refresh();
    }

    // Update the curve and send a message to other components on the GameObject
    public void Refresh()
    {
        CalcCumLengths();
        if (Application.isPlaying)
        {
            SendMessage("CurveUpdated", SendMessageOptions.DontRequireReceiver);
        }
    }

    // Set default values in editor
    public void Reset()
    {
        p0 = new Vector3(1f, 0f, 1f);
        p1 = new Vector3(1f, 0f, -1f);
        p2 = new Vector3(-1f, 0f, -1f);
        p3 = new Vector3(-1f, 0f, 1f);

        Refresh();
    }
}



