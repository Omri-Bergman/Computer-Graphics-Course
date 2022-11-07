Shader "CG/Bricks"
{
    Properties
    {
        [NoScaleOffset] _AlbedoMap ("Albedo Map", 2D) = "defaulttexture" {}
        _Ambient ("Ambient", Range(0, 1)) = 0.15
        [NoScaleOffset] _SpecularMap ("Specular Map", 2D) = "defaulttexture" {}
        _Shininess ("Shininess", Range(0.1, 100)) = 50
        [NoScaleOffset] _HeightMap ("Height Map", 2D) = "defaulttexture" {}
        _BumpScale ("Bump Scale", Range(-100, 100)) = 40
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

                struct appdata
                { 
                    float4 vertex   : POSITION;
                    float3 normal   : NORMAL;
                    float4 tangent  : TANGENT;
                    float2 uv       : TEXCOORD0;
                };

                struct v2f
                { 
                    float4 pos : SV_POSITION;
                    float2 uv  : TEXCOORD0;
                    float3 norm : TEXOORD1;
                    float4 tangent : TEXCOORD3;
                    float3 worldPos : TEXCOORD4;
                };

                v2f vert (appdata input)
                {
                    v2f output;
                    output.tangent = mul(unity_ObjectToWorld, input.tangent);
                    output.norm = normalize(mul(unity_ObjectToWorld, input.normal));
                    output.uv = input.uv;
                    
                
                   output.worldPos =  mul(unity_ObjectToWorld, input.vertex.xyz);
                    output.pos = UnityObjectToClipPos(input.vertex);
                    return output;
                }

                fixed4 frag (v2f input) : SV_Target
                {
                    // float3 worldPos =  mul(unity_ObjectToWorld, input.vertex); //TODO: should be inpot.pos / input.vertex?!

                    bumpMapData newBumpMapData;
                    newBumpMapData.normal = normalize(input.norm);
                    // newBumpMapData.normal = input.norm;
                    newBumpMapData.heightMap = _HeightMap;
                    newBumpMapData.uv = input.uv;
                    // newBumpMapData.du = _HeightMap_TexelSize[0]*_HeightMap_TexelSize[2];
                    // newBumpMapData.dv = _HeightMap_TexelSize[1]*_HeightMap_TexelSize[3];
                    newBumpMapData.du = _HeightMap_TexelSize[0];
                    newBumpMapData.dv = _HeightMap_TexelSize[1];
                    newBumpMapData.bumpScale = _BumpScale/10000;
                    newBumpMapData.tangent = normalize(input.tangent);
                    
                    
                    float3 n = getBumpMappedNormal(newBumpMapData);
                    float3 v = normalize(_WorldSpaceCameraPos - input.worldPos);
                    float3 l = normalize(_WorldSpaceLightPos0); 
                    fixed3 final_color = blinnPhong(n, v, l, _Shininess, tex2D(_AlbedoMap, input.uv), tex2D(_SpecularMap, input.uv), _Ambient);
                    
                    return fixed4(final_color, 1);
                }

            ENDCG
        }
    }
}
