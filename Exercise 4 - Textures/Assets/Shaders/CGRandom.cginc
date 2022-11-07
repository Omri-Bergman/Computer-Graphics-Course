#ifndef CG_RANDOM_INCLUDED
// Upgrade NOTE: excluded shader from DX11 because it uses wrong array syntax (type[size] name)
#pragma exclude_renderers d3d11
#define CG_RANDOM_INCLUDED


// Returns a psuedo-random float between -1 and 1 for a given float c
float random(float c)
{
    return -1.0 + 2.0 * frac(43758.5453123 * sin(c));
}

// Returns a psuedo-random float2 with componenets between -1 and 1 for a given float2 c 
float2 random2(float2 c)
{
    c = float2(dot(c, float2(127.1, 311.7)), dot(c, float2(269.5, 183.3)));

    float2 v = -1.0 + 2.0 * frac(43758.5453123 * sin(c));
    return v;
}

// Returns a psuedo-random float3 with componenets between -1 and 1 for a given float3 c 
float3 random3(float3 c)
{
    float j = 4096.0 * sin(dot(c, float3(17.0, 59.4, 15.0)));
    float3 r;
    r.z = frac(512.0*j);
    j *= .125;
    r.x = frac(512.0*j);
    j *= .125;
    r.y = frac(512.0*j);
    r = -1.0 + 2.0 * r;
    return r.yzx;
}

// Interpolates a given array v of 4 float2 values using bicubic interpolation
// at the given ratio t (a float2 with components between 0 and 1)
//
// [0]=====o==[1]
//         |
//         t
//         |
// [2]=====o==[3]
//
float bicubicInterpolation(float2 v[4], float2 t)
{
    float2 u = t * t * (3.0 - 2.0 * t); // Cubic interpolation

    // Interpolate in the x direction
    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);

    // Interpolate in the y direction and return
    return lerp(x1, x2, u.y);
}

// Interpolates a given array v of 4 float2 values using biquintic interpolation
// at the given ratio t (a float2 with components between 0 and 1)
float biquinticInterpolation(float2 v[4], float2 t)
{
    // Your implementation
    float2 u = t * t * t * (6 * t * t - 15 * t + 10);

    // Interpolate in the x direction
    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);

    // Interpolate in the y direction and return
    return lerp(x1, x2, u.y);
}

// Interpolates a given array v of 8 float3 values using triquintic interpolation
// at the given ratio t (a float3 with components between 0 and 1)
float triquinticInterpolation(float3 v[8], float3 t)
{
    float3 u = t * t * t * (6 * t * t - 15 * t + 10);
    
    float2 lst[4];
    lst[0] = v[0].xy;
    lst[1] = v[1].xy;
    lst[2] = v[2].xy;
    lst[3] = v[3].xy;
    float a = biquinticInterpolation(lst, t.xy);
    lst[0] = v[4].xy;
    lst[1] = v[5].xy;
    lst[2] = v[6].xy;
    lst[3] = v[7].xy;
    float b = biquinticInterpolation(lst, t.xy);
    return lerp(a, b, u.z);
}

// Returns the value of a 2D value noise function at the given coordinates c
float value2d(float2 c)
{
    float2 b_l = random2(float2((int)(c[0]), (int)(c[1])));
    float2 b_r = random2(float2((int)(c[0])+1, (int)(c[1])));
    float2 t_l = random2(float2((int)(c[0]), (int)(c[1])+1));
    float2 t_r = random2(float2((int)(c[0])+1, (int)(c[1])+1));
    
    float2 lst[4];
    lst[2] = t_l;
    lst[3] = t_r;
    lst[0] = b_l;
    lst[1] = b_r;
    
    float2 new_c = float2(frac(c.x), frac(c.y));
    float rand = bicubicInterpolation(lst, new_c);
    return rand;
}

// Returns the value of a 2D Perlin noise function at the given coordinates c
float perlin2d(float2 c)
{
    float2 b_l = random2(float2((int)(c[0]), (int)(c[1])));
    float2 b_r = random2(float2((int)(c[0])+1, (int)(c[1])));
    float2 t_l = random2(float2((int)(c[0]), (int)(c[1])+1));
    float2 t_r = random2(float2((int)(c[0])+1, (int)(c[1])+1));

    float2 corner_b_l = float2((int)(c[0]), (int)(c[1]));
    float2 corner_b_r =float2((int)(c[0])+1, (int)(c[1]));
    float2 corner_t_l =float2((int)(c[0]), (int)(c[1])+1);
    float2 corner_t_r =float2((int)(c[0])+1, (int)(c[1])+1);
    
    float2 dist_c_bl = c-corner_b_l;
    float2 dist_c_br = c-corner_b_r;
    float2 dist_c_tl = c-corner_t_l;
    float2 dist_c_tr = c-corner_t_r;

    float f_b_l = dot(dist_c_bl, b_l);
    float f_b_r = dot(dist_c_br, b_r);
    float f_t_l = dot(dist_c_tl, t_l);
    float f_t_r = dot(dist_c_tr, t_r);

    float2 lst[4];
    lst[2] = f_t_l;
    lst[3] = f_t_r;
    lst[0] = f_b_l;
    lst[1] = f_b_r;
    
    float2 new_c = float2(frac(c.x), frac(c.y));
    float perlin = biquinticInterpolation(lst, new_c);
    
    return perlin;
}

// Returns the value of a 3D Perlin noise function at the given coordinates c
float perlin3d(float3 c)
{                    
    // Your implementation
    //f - front, b - back
    float3 f_b_l = random3(float3((int)(c[0]), (int)(c[1]), (int)(c[2])));
    float3 f_b_r = random3(float3((int)(c[0])+1, (int)(c[1]),(int)(c[2])));
    float3 f_t_l = random3(float3((int)(c[0]), (int)(c[1])+1,(int)(c[2])));
    float3 f_t_r = random3(float3((int)(c[0])+1, (int)(c[1])+1,(int)(c[2])));
    float3 b_b_l = random3(float3((int)(c[0]), (int)(c[1]),(int)(c[2])+1));
    float3 b_b_r = random3(float3((int)(c[0])+1, (int)(c[1]),(int)(c[2])+1));
    float3 b_t_l = random3(float3((int)(c[0]), (int)(c[1])+1,(int)(c[2])+1));
    float3 b_t_r = random3(float3((int)(c[0])+1, (int)(c[1])+1,(int)(c[2])+1));

    float3 cornerf_b_l = (float3((int)(c[0]), (int)(c[1]), (int)(c[2])));
    float3 cornerf_b_r =float3((int)(c[0])+1, (int)(c[1]),(int)(c[2]));
    float3 cornerf_t_l =float3((int)(c[0]), (int)(c[1])+1,(int)(c[2]));
    float3 cornerf_t_r =float3((int)(c[0])+1, (int)(c[1])+1,(int)(c[2]));
    float3 cornerb_b_l = float3((int)(c[0]), (int)(c[1]),(int)(c[2])+1);
    float3 cornerb_b_r =float3((int)(c[0])+1, (int)(c[1]),(int)(c[2])+1);
    float3 cornerb_t_l =float3((int)(c[0]), (int)(c[1])+1,(int)(c[2])+1);
    float3 cornerb_t_r =float3((int)(c[0])+1, (int)(c[1])+1,(int)(c[2])+1);

    float3 dist_c_fbl = c-cornerf_b_l;
    float3 dist_c_fbr = c-cornerf_b_r;
    float3 dist_c_ftl = c-cornerf_t_l;
    float3 dist_c_ftr = c-cornerf_t_r;
    float3 dist_c_bbl = c-cornerb_b_l;
    float3 dist_c_bbr = c-cornerb_b_r;
    float3 dist_c_btl = c-cornerb_t_l;
    float3 dist_c_btr = c-cornerb_t_r;

    float f_f_b_l = dot(dist_c_fbl, f_b_l);
    float f_f_b_r = dot(dist_c_fbr, f_b_r);
    float f_f_t_l = dot(dist_c_ftl, f_t_l);
    float f_f_t_r = dot(dist_c_ftr, f_t_r);
    float f_b_b_l = dot(dist_c_bbl, b_b_l);
    float f_b_b_r = dot(dist_c_bbr, b_b_r);
    float f_b_t_l = dot(dist_c_btl, b_t_l);
    float f_b_t_r = dot(dist_c_btr, b_t_r);

    float3 lst[8];
    lst[2] = f_f_t_l;
    lst[3] = f_f_t_r;
    lst[0] = f_f_b_l;
    lst[1] = f_f_b_r;
    lst[6] = f_b_t_l;
    lst[7] = f_b_t_r;
    lst[4] = f_b_b_l;
    lst[5] = f_b_b_r;
    
    float3 new_c = float3(frac(c.x), frac(c.y), frac(c.z));
    float perlin = triquinticInterpolation(lst, new_c);
    return perlin;
}


#endif // CG_RANDOM_INCLUDED
