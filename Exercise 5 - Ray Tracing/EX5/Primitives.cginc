// Checks for an intersection between a ray and a sphere
// The sphere center is given by sphere.xyz and its radius is sphere.w
void intersectSphere(Ray ray, inout RayHit bestHit, Material material, float4 sphere)
{
    // Your implementation
    //ray(t) = o + dt; where o - origin, d - direction, t > 0;
    float A = 1;
    float B =  2 * dot((ray.origin - sphere.xyz), ray.direction);
    float C = dot((ray.origin - sphere.xyz) , (ray.origin - sphere.xyz)) - sphere.w*sphere.w;
    float disc = B*B - 4*A*C;
    if (disc < 0)
    {
        if (bestHit.distance > 0)
        {
            return;
        } 
       
    }
    float t;
    if (disc == 0){
        t = -B / (2*A);
    } else{
        t = min ((-B + sqrt(disc)) / (2*A) , (-B - sqrt(disc)) / (2*A));
        if ( t < 0 )
        {
            t = max ((-B + sqrt(disc)) / (2*A) , (-B - sqrt(disc)) / (2*A));
        }
    }
    
    if (bestHit.distance > 0 && t < bestHit.distance && t > 0)
    {
        bestHit.distance = t;
        bestHit.position = ray.origin + (t* ray.direction);
        bestHit.normal = normalize(bestHit.position - sphere.xyz);
        bestHit.material = material;  
    }
    
    return;
}

// Checks for an intersection between a ray and a plane
// The plane passes through point c and has a surface normal n
void intersectPlane(Ray ray, inout RayHit bestHit, Material material, float3 c, float3 n)
{
    // Your implementation
    float t = -(dot((ray.origin - c), n) / dot(ray.direction, n));
    if (bestHit.distance > 0 && t > 0 && t < bestHit.distance)
    {
        bestHit.distance = t;
        bestHit.position =  ray.origin + t*ray.direction;
        bestHit.normal =  normalize(n);
        bestHit.material = material;
    } 
    
}

// Checks for an intersection between a ray and a plane
// The plane passes through point c and has a surface normal n
// The material returned is either m1 or m2 in a way that creates a checkerboard pattern 
void intersectPlaneCheckered(Ray ray, inout RayHit bestHit, Material m1, Material m2, float3 c, float3 n)
{
    // Your implementation
    float t = -(dot((ray.origin - c), n) / dot(ray.direction, n));
    if (bestHit.distance > 0 && t > 0 && t < bestHit.distance)
    {
        bestHit.distance = t;
        bestHit.position =  ray.origin + t*ray.direction;
        bestHit.normal =  normalize(n);
            if ((floor(bestHit.position.x*2) + floor(bestHit.position.z*2))%2 == 0)
            {
                bestHit.material = m1;
            } else
            {
                bestHit.material = m2;
            }
    } 
}


// Checks for an intersection between a ray and a triangle
// The triangle is defined by points a, b, c
void intersectTriangle(Ray ray, inout RayHit bestHit, Material material, float3 a, float3 b, float3 c)
{
    // Your implementation
    float3 n = normalize(cross((a-c), (b-c)));
    float t = -(dot((ray.origin - c), n) / dot(ray.direction, n));
    float3 p = ray.origin + t*ray.direction;
    float state1 = dot(cross((b-a),(p-a)), n);
    float state2 = dot(cross((c-b),(p-b)), n);
    float state3 = dot(cross((a-c),(p-c)), n);
    if (state1 >= 0 && state2 >= 0 && state3 >= 0)
    {
        if (bestHit.distance > 0 && t > 0 && t < bestHit.distance)
        {
            bestHit.distance = t;
            bestHit.position = p;
            bestHit.normal =  n;
            bestHit.material = material;
        } 
    }
    
}


// Checks for an intersection between a ray and a 2D circle
// The circle center is given by circle.xyz, its radius is circle.w and its orientation vector is n 
void intersectCircle(Ray ray, inout RayHit bestHit, Material material, float4 circle, float3 n)
{
    // Your implementation
    n  =  normalize(n);
    float t = -(dot((ray.origin - circle.xyz), n) / dot(ray.direction, n));
    float3 p = ray.origin + t*ray.direction;
    float dist = sqrt(pow((p.x-circle.x),2) + pow((p.y-circle.y),2) + pow((p.z-circle.z),2));
    if (dist <= circle.w && bestHit.distance > 0 && t > 0 && t < bestHit.distance)
    {
        bestHit.distance = t;
        bestHit.position = p;
        bestHit.normal =  n;
        bestHit.material = material;
    }
    
}


// Checks for an intersection between a ray and a cylinder aligned with the Y axis
// The cylinder center is given by cylinder.xyz, its radius is cylinder.w and its height is h
void intersectCylinderY(Ray ray, inout RayHit bestHit, Material material, float4 cylinder, float h)
{
    // Your implementation
    float4 top_circle_center = float4(cylinder.x, cylinder.y+h/2, cylinder.z, cylinder.w);
    intersectCircle(ray, bestHit, material, top_circle_center, float3(0,1,0));
    float4 bottom_circle_center = float4(cylinder.x, cylinder.y-h/2, cylinder.z, cylinder.w);
    intersectCircle(ray, bestHit, material, bottom_circle_center, float3(0,-1,0));
    

    float A = pow((ray.direction.x), 2) + pow((ray.direction.z), 2); 
    float B =  -2 * ((ray.direction.x)*(cylinder.x - ray.origin.x) + (ray.direction.z)*(cylinder.z - ray.origin.z));
    float C = pow((cylinder.x - ray.origin.x), 2) + pow((cylinder.z - ray.origin.z), 2) - pow(cylinder.w, 2);

    
    float disc = B*B - 4*A*C;
    if (disc < 0)
    {
        if (bestHit.distance > 0)
        {
            return;
        } 
    }
    float t;
    if (disc == 0){
        t = -B / (2*A);
    } else{
        t = min ((-B + sqrt(disc)) / (2*A) , (-B - sqrt(disc)) / (2*A));
        if ( t < 0 )
        {
            t = max ((-B + sqrt(disc)) / (2*A) , (-B - sqrt(disc)) / (2*A));
        }
    }
    
    if (bestHit.distance > 0 && t < bestHit.distance && t > 0 && (ray.origin.y + t*ray.direction.y) <= top_circle_center.y &&  (ray.origin.y + t*ray.direction.y) >= bottom_circle_center.y)
    {
        bestHit.distance = t;
        bestHit.position = ray.origin + (t* ray.direction);
        if (ray.origin.y + t*ray.direction.y == top_circle_center.y)
        {
            bestHit.normal = float3(0, 1, 0);
        }
        else
        {
            if (ray.origin.y + t*ray.direction.y == bottom_circle_center.y)
            {
                bestHit.normal = float3(0, -1, 0);
            }
            else
            {
                bestHit.normal = normalize(bestHit.position - float3(cylinder.x, bestHit.position.y, cylinder.z));
            }
            
        }
        
        bestHit.material = material;  
    }
    
    return;
}
