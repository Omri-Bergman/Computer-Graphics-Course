// Implements an adjusted version of the Blinn-Phong lighting model
float3 blinnPhong(float3 n, float3 v, float3 l, float shininess, float3 albedo)
{
    // Your implementation
    float3 diffuse = max(0, dot(n,l))*albedo;
    float3 h = normalize(l+v);
    float3 specular = pow(max(0, dot(n,h)), shininess) * 0.4;
    return float3(diffuse + specular);
}

// Reflects the given ray from the given hit point
void reflectRay(inout Ray ray, RayHit hit)
{
    // Your implementation
    float3 r = 2 * dot(-ray.direction, hit.normal)*hit.normal + ray.direction;
    r = normalize(r);

    Ray reflect = CreateRay(hit.position + (hit.normal*EPS), r, ray.energy * hit.material.specular);
    ray = reflect;   
}

// Refracts the given ray from the given hit point
void refractRay(inout Ray ray, RayHit hit)
{
    // Your implementation
    float3 i = ray.direction;
    float3 n = hit.normal;
    float c_1 = abs(dot(i,n));
    float ref;
    if (dot(i , n)  <= 0)
    {
        //enter material
        ref = 1/hit.material.refractiveIndex;
    } else
    {
        //exit material
        ref = hit.material.refractiveIndex;
        n = -n;
    }
    float c_2 = sqrt(1-(ref*ref)*(1-(c_1*c_1)));
    float3 t = ref*i + (ref*c_1 - c_2)*n;
    
    Ray refract = CreateRay(hit.position + (-n*EPS),t ,ray.energy);
    ray = refract;
    
}

// Samples the _SkyboxTexture at a given direction vector
float3 sampleSkybox(float3 direction)
{
    float theta = acos(direction.y) / -PI;
    float phi = atan2(direction.x, -direction.z) / -PI * 0.5f;
    return _SkyboxTexture.SampleLevel(sampler_SkyboxTexture, float2(phi, theta), 0).xyz;
}