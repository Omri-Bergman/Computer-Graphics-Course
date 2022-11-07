using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CharacterAnimator : MonoBehaviour
{
    public TextAsset BVHFile; // The BVH file that defines the animation and skeleton
    public bool animate; // Indicates whether or not the animation should be running

    private BVHData data; // BVH data of the BVHFile will be loaded here
    private int currFrame = 0; // Current frame of the animation

    private int last_currFrame = -1; // last Current frame of the animation
    private float time_passed = 0; // check how much time passed

    // Start is called before the first frame update
    void Start()
    {
        BVHParser parser = new BVHParser();
        data = parser.Parse(BVHFile);
        CreateJoint(data.rootJoint, Vector3.zero);
    
    }

    // Returns a Matrix4x4 representing a rotation aligning the up direction of an object with the given v
    Matrix4x4 RotateTowardsVector(Vector3 v)
    {
        // Your code here
        //1
        v = v.normalized;

        //2
        //XY Plane
        float angle_x = 90 - Mathf.Rad2Deg*Mathf.Atan2(v.y, v.z);
        // print("angle x: "+angle_x);
        Matrix4x4 R_x =  MatrixUtils.RotateX(angle_x);

        //YZ
        float angle_z = 90 - Mathf.Rad2Deg*Mathf.Atan2(Mathf.Sqrt(v.y*v.y + v.z*v.z), v.x);
        // print("angle Z: "+angle_z);
        Matrix4x4 R_z =  MatrixUtils.RotateZ(-angle_z);


        return R_x*R_z;
    }

    // Creates a Cylinder GameObject between two given points in 3D space
    GameObject CreateCylinderBetweenPoints(Vector3 p1, Vector3 p2, float diameter)
    {
        // Your code here
        
        //1
        GameObject cylinder = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        Matrix4x4 basic_scale =  MatrixUtils.Scale(new Vector3(1,2,1));
        MatrixUtils.ApplyTransform(cylinder, basic_scale);

        //2
         Matrix4x4 trans1 =  MatrixUtils.Translate(p1);
         Matrix4x4 trans2 =  MatrixUtils.Translate((p2-p1)*0.5f);
        Matrix4x4 trans = trans2 * trans1;
        Matrix4x4 rotate = RotateTowardsVector(p2-p1);
        Vector3 scale_vector = new Vector3 (diameter,((p2-p1).magnitude)*0.5f,diameter);
        Matrix4x4 scale = MatrixUtils.Scale(scale_vector);

        Matrix4x4 M = trans*rotate*scale;
        MatrixUtils.ApplyTransform(cylinder, M);


        return cylinder;
    }

    // Creates a GameObject representing a given BVHJoint and recursively creates GameObjects for it's child joints
    GameObject CreateJoint(BVHJoint joint, Vector3 parentPosition)
    {
        // Your code here
        //1
        joint.gameObject = new GameObject(joint.name);

        //2
        GameObject sphere = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        sphere.transform.parent = joint.gameObject.transform;

        //3
        if (joint.name == "Head")
        {
           Matrix4x4 scale =  MatrixUtils.Scale(new Vector3(8,8,8));
           MatrixUtils.ApplyTransform(sphere, scale);
        } else {
            Matrix4x4 scale =  MatrixUtils.Scale(new Vector3(2,2,2));
           MatrixUtils.ApplyTransform(sphere, scale);
        }

        //4 + 5?
        Matrix4x4 trans =  MatrixUtils.Translate(parentPosition+joint.offset);
        MatrixUtils.ApplyTransform(joint.gameObject, trans);

        //cylinder
        if (joint != data.rootJoint){
            GameObject cyl = CreateCylinderBetweenPoints(parentPosition ,sphere.transform.position, 0.5f);
            cyl.transform.parent = joint.gameObject.transform;
        }

        //6
        foreach (BVHJoint child_jnt in joint.children)
        {
            CreateJoint(child_jnt, parentPosition+joint.offset);
        }
        
        //TODO need to return?
        return sphere;
    }

    // Transforms BVHJoint according to the keyframe channel data, and recursively transforms its children
    private void TransformJoint(BVHJoint joint, Matrix4x4 parentTransform, float[] keyframe)
    {
        Matrix4x4 rot = Matrix4x4.identity;;
        Matrix4x4 trans = Matrix4x4.identity;
        Matrix4x4 scale = Matrix4x4.identity;

        // move joint 
        Matrix4x4 rot_x = MatrixUtils.RotateX(keyframe[joint.rotationChannels.x]);
        Matrix4x4 rot_y =  MatrixUtils.RotateY(keyframe[joint.rotationChannels.y]);
        Matrix4x4 rot_z =  MatrixUtils.RotateZ(keyframe[joint.rotationChannels.z]);

        //SORRY :(
        if (joint.rotationOrder.x == 0 && joint.rotationOrder.y == 1){
             rot = rot_x*rot_y*rot_z;
        }
        else if (joint.rotationOrder.y == 0 && joint.rotationOrder.x == 1){
            rot = rot_y*rot_x*rot_z;
        }
        else if (joint.rotationOrder.x == 0 && joint.rotationOrder.z == 1){
            rot = rot_x*rot_z*rot_y;
        }
        else if (joint.rotationOrder.z == 0 && joint.rotationOrder.x == 1){
            rot = rot_z*rot_x*rot_y;
        }
        else if (joint.rotationOrder.y == 0 && joint.rotationOrder.z == 1){
            rot = rot_y*rot_z*rot_x;
        }
        else if (joint.rotationOrder.z == 0 && joint.rotationOrder.y == 1){
            rot = rot_z*rot_y*rot_x;
        }


        //TODO if (joint.positionChannels){... (CHANNELS 6 OR CHANNELS 3)
        if (joint == data.rootJoint){
            Vector3 trans_vec = new Vector3
            (keyframe[joint.positionChannels.x], keyframe[joint.positionChannels.y], keyframe[joint.positionChannels.z]);
            trans =  MatrixUtils.Translate(trans_vec);
        }
        trans *= MatrixUtils.Translate(joint.offset);
        

        Matrix4x4 M = parentTransform * trans * scale;
        MatrixUtils.ApplyTransform(joint.gameObject, M);
        M = parentTransform * trans * rot * scale;

        //for children in joint call TransformJoint
        foreach (BVHJoint child_jnt in joint.children)
        {
            TransformJoint(child_jnt, M, keyframe);
        }

    }

    // Update is called once per frame
    void Update()
    { 
        if (animate)
        {
            time_passed += Time.deltaTime;
            currFrame = (int)Mathf.Floor(time_passed/data.frameLength);
            if (currFrame >= data.numFrames){
                time_passed = 0;
                currFrame = (int)Mathf.Floor(time_passed/data.frameLength);
                }
            if (currFrame != last_currFrame){
                last_currFrame = currFrame;
                TransformJoint(data.rootJoint, Matrix4x4.identity, data.keyframes[currFrame]);
            }
        }
    }
}
