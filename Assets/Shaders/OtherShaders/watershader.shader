Shader "Custom/watershader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Transparency("Transparency",Range(0.0,1.0)) = 0.25

        _Speed("Speed", float) = 0.5
        _WaveA ("Wave A (direction, steepness, wavelength)", Vector) = (1,0,0.5,10)
        _WaveB ("Wave B (direction, steepness, wavelength)", Vector) = (0,1,0.25,20)
        _WaveC ("Wave C (direction, steepness, wavelength)", Vector) = (1,1,0.15,10)
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 200

        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows alpha:fade vertex:vert addshadow

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        float _Transparency;

        float _Speed;
        //float _Amplitude;
        float4 _WaveA;
        float4 _WaveB;
        float4 _WaveC;
        
        float3 Wave(float4 wave, float3 pos, inout float3 tan, inout float3 binormal)
        {
        	float steepness = wave.z;
		    float wavelength = wave.w;
            float k = 2 * UNITY_PI / wavelength;
            float2 d = normalize(wave.xy);
            float f = k * (dot(d, pos.xz) - _Speed * _Time.y);
            float a = steepness / k;

            tan += float3(-d.x*d.x*(steepness * sin(f)), d.x * (steepness * cos(f)), -d.x * d.y * (steepness*sin(f)));
            binormal += float3(-d.x*d.y*(steepness*sin(f)),d.y*(steepness*cos(f)),-d.y*d.y*(steepness*sin(f)));
            return float3(d.x * (a * cos(f)),a * sin(f),d.y * (a*cos(f)));
        }

        void vert(inout appdata_full v) 
        {
        	float3 gridPoint = v.vertex.xyz;
        	float3 tan = float3(1,0,0);
        	float3 binormal = float3(0,0,1);
        	float3 pos = gridPoint;
        	pos += Wave(_WaveA,gridPoint,tan,binormal);
        	pos += Wave(_WaveB,gridPoint,tan,binormal);
        	pos += Wave(_WaveC,gridPoint,tan,binormal);
        	float3 normal = normalize(cross(binormal,tan));
        	v.vertex.xyz = pos;
        	v.normal = normal;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = _Transparency;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
