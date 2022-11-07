Shader "CG/Water"
{
    Properties
    {
        _CubeMap("Reflection Cube Map", Cube) = "" {}
        _NoiseScale("Texture Scale", Range(1, 100)) = 10 
        _TimeScale("Time Scale", Range(0.1, 5)) = 3 
        _BumpScale("Bump Scale", Range(0, 0.5)) = 0.05
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "CGUtils.cginc"
                #include "CGRandom.cginc"

                #define DELTA 0.01

                // Declare used properties
                uniform samplerCUBE _CubeMap;
                uniform float _NoiseScale;
                uniform float _TimeScale;
                uniform float _BumpScale;

                struct appdata
                { 
                    float4 vertex   : POSITION;
                    float3 normal   : NORMAL;
                    float4 tangent  : TANGENT;
                    float2 uv       : TEXCOORD0;
                };

                struct v2f
                {
                    float4 pos      : SV_POSITION;
                    float2 uv : TEXCOORD1;
                    float4 vertex: TEXCOORD2;
                    float3 worldPos : TEXCOORD3;
                    float3 norm : TEXCOORD4;
                    float4 tangent : TEXCOORD5;
                };

                // Returns the value of a noise function simulating water, at coordinates uv and time t
                float waterNoise(float2 uv, float t)
                {
                    // Your implementation

                    //stage 8
                    return (perlin3d(float3(0.5*uv.x, 0.5*uv.y, 0.5*t)) + 0.5 * perlin3d(float3( uv.x, uv.y, t)) + 0.2 * perlin3d(float3(2*uv.x, 2*uv.y, 3*t)));

                    //basic
                    return perlin2d(uv);
                }

                // Returns the world-space bump-mapped normal for the given bumpMapData and time t
                float3 getWaterBumpMappedNormal(bumpMapData i, float t)
                {
                    float f_u_der = (waterNoise(float2(i.uv[0] + i.du, i.uv[1]), t) - waterNoise(float2(i.uv[0], i.uv[1]), t))/i.du;
                    float f_v_der = (waterNoise(float2(i.uv[0], i.uv[1]+ i.dv), t) - waterNoise(float2(i.uv[0], i.uv[1]), t))/i.dv;
                        
                    float3 nh = float3(-i.bumpScale*f_u_der, -i.bumpScale*f_v_der , 1);
                    nh = normalize(nh);

                    float3 bi_normal = cross(i.tangent, i.normal);
                    float3 n_world = i.tangent*nh.x + i.normal*nh.z + bi_normal*nh.y;
        
                    return n_world;
                }
            
                v2f vert (appdata input)
                {
                    v2f output;
        
                    float t = _Time.y * _TimeScale;
                    input.vertex.xyz = (input.vertex.xyz) + _BumpScale*(input.normal*waterNoise(input.uv * _NoiseScale, t));
                    
                    output.norm = mul(unity_ObjectToWorld, normalize(input.normal)); 
                    output.worldPos =  mul(unity_ObjectToWorld, input.vertex.xyz);
                    output.vertex = input.vertex;
                    output.pos = UnityObjectToClipPos(input.vertex);
                    output.uv = input.uv;
                    output.tangent =  mul(unity_ObjectToWorld, input.tangent);
                    return output;
                }

                fixed4 frag (v2f input) : SV_Target
                {
                    float3 n = normalize(input.norm);
                    
                    bumpMapData newBumpMapData;
                    newBumpMapData.normal = n;
                    newBumpMapData.tangent = input.tangent;
                    newBumpMapData.uv = input.uv * _NoiseScale;
                    newBumpMapData.du = DELTA;
                    newBumpMapData.dv = DELTA;
                    newBumpMapData.bumpScale = _BumpScale;

                     //calculate reflected view direction
                    float3 v = normalize(_WorldSpaceCameraPos - input.worldPos);
                    float t = _Time.y * _TimeScale;
                    float3 new_n = getWaterBumpMappedNormal(newBumpMapData, t);
                    
                    //stage 5&6
                    float3 ReflectedColor = 2*(dot(v,new_n))*n-v;
                    return (1-max(0, dot(new_n,v))+0.2) * texCUBE(_CubeMap , ReflectedColor);
                }

            ENDCG
        }
    }
}
