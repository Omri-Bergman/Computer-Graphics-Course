#ifndef CG_UTILS_INCLUDED
#define CG_UTILS_INCLUDED

#define PI 3.141592653

// A struct containing all the data needed for bump-mapping
struct bumpMapData
{ 
    float3 normal;       // Mesh surface normal at the point
    float3 tangent;      // Mesh surface tangent at the point
    float2 uv;           // UV coordinates of the point
    sampler2D heightMap; // Heightmap texture to use for bump mapping
    float du;            // Increment size for u partial derivative approximation
    float dv;            // Increment size for v partial derivative approximation
    float bumpScale;     // Bump scaling factor
};


// Receives pos in 3D cartesian coordinates (x, y, z)
// Returns UV coordinates corresponding to pos using spherical texture mapping
float2 getSphericalUV(float3 pos)
{
    float r = sqrt(pow(pos.x, 2)+pow(pos.y, 2)+pow(pos.z, 2));
    float teta = atan2(pos.z,pos.x);
    float phi = acos(pos.y/r);
    float u = 0.5 + teta/(2*PI);
    float v = 1 - phi/PI;
    return float2(u,v);
}

// Implements an adjusted version of the Blinn-Phong lighting model
fixed3 blinnPhong(float3 n, float3 v, float3 l, float shininess, fixed4 albedo, fixed4 specularity, float ambientIntensity)
{
    // Your implementation
    float3 ambient = ambientIntensity * albedo.xyz;
    float3 diffuse = max(0, dot(n,l)) * albedo.xyz;
    float3 h = normalize(l+v);
    float3 specular = pow(max(0 ,  dot(n,h)), shininess) * specularity.xyz;

    return ambient+diffuse+specular;
}

// Returns the world-space bump-mapped normal for the given bumpMapData
float3 getBumpMappedNormal(bumpMapData i)
{
    // Your implementation
    float f_u_der = (tex2D(i.heightMap, float2(i.uv[0] + i.du, i.uv[1])) - tex2D(i.heightMap, i.uv))/i.du;
    float f_v_der = (tex2D(i.heightMap, float2(i.uv[0], i.uv[1] + i.dv)) - tex2D(i.heightMap, i.uv))/i.dv;


    // float f_u_der = (tex2D(i.heightMap, i.uv + i.du) - tex2D(i.heightMap, i.uv))/i.du;
    // float f_v_der = (tex2D(i.heightMap, i.uv + i.dv) - tex2D(i.heightMap, i.uv))/i.dv;
    
    float3 nh = float3(-1*i.bumpScale*f_u_der, -1*i.bumpScale*f_v_der , 1);
    nh = normalize(nh);

    float3 bi_normal = cross(i.tangent, i.normal);
    float3 n_world = normalize(i.tangent*nh.x + i.normal*nh.z + bi_normal*nh.y);
    
    return n_world;
}


#endif // CG_UTILS_INCLUDED
