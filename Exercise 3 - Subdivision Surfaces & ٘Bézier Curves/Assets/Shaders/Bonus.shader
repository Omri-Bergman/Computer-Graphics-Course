Shader "CG/Bonus"
{
    Properties
    {
        _CubeMap("Reflection Cube Map", Cube) = "" {}
        [NoScaleOffset] _AlbedoMap("Albedo Map", 2D) = "defaulttexture" {}
        _Ambient("Ambient", Range(0, 1)) = 0.5
        [NoScaleOffset] _SpecularMap("Specular Map", 2D) = "defaulttexture" {}
        _Shininess("Shininess", Range(0.1, 100)) = 80
        [NoScaleOffset] _HeightMap("Height Map", 2D) = "defaulttexture" {}
        _BumpScale("Bump Scale", Range(1, 100)) = 3
        _IceColor("Ice Color", Color) = (0.74, 0.83, 0.81, 1)
        _ColorScale("Color Intensity", Range(0.1, 2)) = 0.7
        _DistortionScale("Distortion Scale", Range(0.1, 2)) = 1.4
        _FresnelColor("Highligh Color", Color) = (0.75, 0.80, 0.79, 1)
        _FresnelIntensity("Highligh Intensity", Range(0.1, 1)) = 0.80
        _FresnelRadius("Highligh Scale", Range(0.1, 1.5)) = 0.85
        _TimeScale("Time Scale", Range(0.1, 5)) = 3 
        _NoiseScale("Texture Scale", Range(1, 100)) = 10 
        
        
    }
    SubShader
    {
        GrabPass
        {
            "_BackgroundTexture"
        }

        Pass
        {
        Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent+20000"}

            

            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "CGUtils.cginc"
                #include "CGRandom.cginc"

                #define DELTA 0.01
            
                uniform samplerCUBE _CubeMap;
                uniform sampler2D _AlbedoMap;
                uniform float _Ambient;
                uniform sampler2D _SpecularMap;
                uniform float _Shininess;
                uniform sampler2D _HeightMap;
                uniform float4 _HeightMap_TexelSize;
                uniform float _BumpScale;
                uniform fixed4 _IceColor;
                uniform float _ColorScale;
                uniform float _DistortionScale;
                sampler2D _BackgroundTexture;
                uniform fixed4 _FresnelColor;
                uniform float _FresnelIntensity;
                uniform float _FresnelRadius;
                uniform float _TimeScale;
                uniform float _NoiseScale;


             float waterNoise(float2 uv, float t)
                {
                    // Your implementation

                    //stage 8
                    return (perlin3d(float3(0.2*uv.x, 0.2*uv.y, 0.2*t)) + 0.5 * perlin3d(float3( uv.x, uv.y, t)) + 0.2 * perlin3d(float3(uv.x, 2*uv.y, t)))*0.01;

                    //basic
                    return perlin2d(uv);
                }

            
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
                    float4 worldPos : TEXCOORD0;
                    float3 normal   : TEXCOORD1;
                    float4 objPos   : TEXCOORD2;
                    float3 tangent  : TEXCOORD3;
                    float2 uv       : TEXCOORD4;
                    float4 grabPos  : TEXCOORD5;
                };

                v2f vert(appdata input)
                {
                    v2f output;
                    float t = _Time.y * _TimeScale;
                    input.vertex.xyz = (input.vertex.xyz) + _BumpScale*(input.normal*waterNoise(input.uv * _NoiseScale, t))*0.5;

                    
                    output.objPos = input.vertex;
                    output.pos = UnityObjectToClipPos(input.vertex);
                    output.grabPos = ComputeGrabScreenPos(output.pos);
                    output.worldPos = mul(unity_ObjectToWorld, input.vertex);

                    output.normal = normalize(mul(unity_ObjectToWorld, input.normal).xyz);
                    output.tangent = normalize(input.tangent.xyz);

                    output.uv = input.uv;

                    return output;
                }

                fixed4 frag (v2f input) : SV_Target
                {float t = _Time.y * _TimeScale;
                    bumpMapData bmd;
                    bmd.normal = normalize(input.normal);
                    bmd.tangent = normalize(input.tangent);
                    bmd.uv = input.uv;
                    bmd.heightMap = _HeightMap;
                    bmd.du = _HeightMap_TexelSize.x;
                    bmd.dv = _HeightMap_TexelSize.y;
                    bmd.bumpScale = _BumpScale / 10000;

                    float3 n = normalize(getBumpMappedNormal(bmd))+ _BumpScale*(input.normal*waterNoise(input.uv * _NoiseScale, t))*10;
                    float3 l = normalize(_WorldSpaceLightPos0.xyz - (input.worldPos * _WorldSpaceLightPos0.w))+ _BumpScale*(input.normal*waterNoise(input.uv * _NoiseScale, t))*10;
                    float3 v = normalize(_WorldSpaceCameraPos - input.worldPos.xyz)+ _BumpScale*(input.normal*waterNoise(input.uv * _NoiseScale, t))*10;

                    float4 distort = input.grabPos * (tex2D(_HeightMap, input.uv) + 1) +waterNoise(input.uv * _NoiseScale, t)*20;  // Distortion uv from scene background affected by the texture.
                    distort = lerp(distort, input.grabPos, _DistortionScale);  // More distortion according to scale.
                    fixed diameter = max(_FresnelIntensity * (_FresnelRadius - dot(n, v)), 0);  // Effect of fresnel.
                    float4 fresnel = float4(diameter, diameter, diameter, 0) * max(0.8, dot(n, l)) * _FresnelColor;  // Fresnel intensity affected by shadow,
                    // fixed4 albedo = tex2D(_AlbedoMap, input.uv)* _IceColor * _ColorScale; 
                    fixed4 albedo = (tex2Dproj(_BackgroundTexture, distort) + tex2D(_AlbedoMap, input.uv))* _IceColor * _ColorScale ;  // Color taken from background affected by given color.
                    // fixed4 albedo = lerp (cubeSample, cubeSample * textureSample, 1 - alphaSample); //Makes it brighter
                    fixed4 specularity = tex2D(_SpecularMap, input.uv);
                    float3 new_n = bmd.normal;
                    float3 ReflectedColor = 2*(dot(v,new_n))*n-v;
                    // return fixed4(blinnPhong(n, v, l, _Shininess, albedo, specularity, _Ambient), 1) + fresnel;

                    return fixed4(blinnPhong(n, v, l, _Shininess, albedo, specularity, _Ambient), 1) + fresnel * (1-max(0, dot(new_n,v))+0.2) * texCUBE(_CubeMap , ReflectedColor);
                }

            ENDCG
        }
    }
}
