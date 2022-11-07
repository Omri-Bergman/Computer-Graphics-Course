Shader "CG/Earth"
{
    Properties
    {
        [NoScaleOffset] _AlbedoMap ("Albedo Map", 2D) = "defaulttexture" {}
        _Ambient ("Ambient", Range(0, 1)) = 0.15
        [NoScaleOffset] _SpecularMap ("Specular Map", 2D) = "defaulttexture" {}
        _Shininess ("Shininess", Range(0.1, 100)) = 50
        [NoScaleOffset] _HeightMap ("Height Map", 2D) = "defaulttexture" {}
        _BumpScale ("Bump Scale", Range(1, 100)) = 30
        [NoScaleOffset] _CloudMap ("Cloud Map", 2D) = "black" {}
        _AtmosphereColor ("Atmosphere Color", Color) = (0.8, 0.85, 1, 1)
    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "CGUtils.cginc"

                // Declare used properties
                uniform sampler2D _AlbedoMap;
                uniform float _Ambient;
                uniform sampler2D _SpecularMap;
                uniform float _Shininess;
                uniform sampler2D _HeightMap;
                uniform float4 _HeightMap_TexelSize;
                uniform float _BumpScale;
                uniform sampler2D _CloudMap;
                uniform fixed4 _AtmosphereColor;

                struct appdata
                { 
                    float4 vertex : POSITION;
                };

                struct v2f
                { 
                    float4 pos : SV_POSITION;
                    float4 vertex : TEXCOORD0;
                    float3 norm : TEXCOORD1;
                    float3 worldPos : TEXCOORD2;
                };

                v2f vert (appdata input)
                {
                    v2f output;
                    output.norm = mul(unity_ObjectToWorld, normalize(input.vertex));
                    output.worldPos =  mul(unity_ObjectToWorld, input.vertex.xyz);

                    output.vertex = input.vertex;
                    output.pos = UnityObjectToClipPos(input.vertex);
                    
                    return output;
                }

                fixed4 frag (v2f input) : SV_Target
                {
                    float2 uv = getSphericalUV(normalize(input.vertex.xyz));

                    float3 n = normalize(input.norm);
                    bumpMapData newBumpMapData;
                    newBumpMapData.normal = n;
                    newBumpMapData.tangent = normalize(cross(n, float3(0,1,0)));
                    newBumpMapData.heightMap = _HeightMap;
                    newBumpMapData.uv = uv;
                    newBumpMapData.du = _HeightMap_TexelSize[0];
                    newBumpMapData.dv = _HeightMap_TexelSize[1];
                    newBumpMapData.bumpScale = _BumpScale/10000;

                    float3 final_normal = (1-tex2D(_SpecularMap, uv))* getBumpMappedNormal(newBumpMapData) +  tex2D(_SpecularMap, uv)* newBumpMapData.normal;
                    
                    float3 v = normalize(_WorldSpaceCameraPos - input.worldPos);
                    float3 l = normalize(_WorldSpaceLightPos0);

                    float lambert = max(0, dot(n,l));
                    
                    float3 atmosphere = (1 - max(0 , dot(n,v))) * sqrt(lambert) * _AtmosphereColor;
                    float3 clouds = tex2D(_CloudMap, uv) * (sqrt(lambert) + _Ambient);
            
                    fixed3 final_color = blinnPhong(final_normal, v, l, _Shininess, tex2D(_AlbedoMap, uv), tex2D(_SpecularMap, uv), _Ambient);
                    
                    return fixed4(final_color + atmosphere + clouds, 1);
                }

            ENDCG
        }
    }
}
