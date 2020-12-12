Shader "Custom/watershadertxt"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Transparency("Transparency",Range(0.0,1.0)) = 0.25

        //no scale offset because tiling and offset won't be changed
		[NoScaleOffset] _FlowMap ("Flow (RG, A noise)", 2D) = "black" {}
		[NoScaleOffset] _DerivHeightMap ("Deriv (AG) Height (B)", 2D) = "black" {}
		_UJump ("U jump per phase", Range(-0.25, 0.25)) = 0.25
		_VJump ("V jump per phase", Range(-0.25, 0.25)) = 0.25
		_Tiling ("Tiling", Float) = 1
		_FlowSpeed ("FlowSpeed", Float) = 1
		_FlowStrength ("Flow Strength", Float) = 1
		_FlowOffset ("Flow Offset", Float) = 0
		_HeightScale ("Height Scale, Constant", Float) = 0.25
		_HeightScaleModulated ("Height Scale, Modulated", Float) = 0.75

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

        sampler2D _MainTex, _FlowMap, _DerivHeightMap;
		float _UJump, _VJump, _Tiling, _FlowSpeed, _FlowStrength, _FlowOffset, _HeightScale, _HeightScaleModulated;

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

        float3 UnpackDerivativeHeight (float4 textureData) {
			float3 dh = textureData.agb;
			dh.xy = dh.xy * 2 - 1;
			return dh;
		}

		//time allows material to be animated
		float3 FlowUVW (float2 uv, float2 flowVector, float2 jump,float flowOffset, float tiling, float time, bool flowB) {
			float phaseOffset = flowB ? 0.5 : 0;
			float progress = frac(time + phaseOffset);
			float3 uvw;
			uvw.xy = uv - flowVector * (progress + flowOffset);
			uvw.xy *= tiling;
			uvw.xy += phaseOffset;
			uvw.xy += (time - progress) * jump;
			uvw.z = 1 - abs(1 - 2 * progress);
			return uvw;
		}
        
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
			float3 flow = tex2D(_FlowMap, IN.uv_MainTex).rgb;
			flow.xy = flow.xy * 2 - 1;
			flow *= _FlowStrength;
			float noise = tex2D(_FlowMap, IN.uv_MainTex).a;
			float time = _Time.y * _FlowSpeed + noise;
			float2 jump = float2(_UJump, _VJump);

			float3 uvwA = FlowUVW(IN.uv_MainTex, flow.xy, jump, _FlowOffset, _Tiling, time, false);
			float3 uvwB = FlowUVW(IN.uv_MainTex, flow.xy, jump, _FlowOffset, _Tiling, time, true);

			float finalHeightScale = flow.z * _HeightScaleModulated + _HeightScale;

			float3 dhA = UnpackDerivativeHeight(tex2D(_DerivHeightMap, uvwA.xy)) * (uvwA.z * finalHeightScale);
			float3 dhB = UnpackDerivativeHeight(tex2D(_DerivHeightMap, uvwB.xy)) * (uvwB.z * finalHeightScale);
			o.Normal = normalize(float3(-(dhA.xy + dhB.xy), 1));

			fixed4 texA = tex2D(_MainTex, uvwA.xy) * uvwA.z;
			fixed4 texB = tex2D(_MainTex, uvwB.xy) * uvwB.z;

            // Albedo comes from a texture tinted by color
            fixed4 c = (texA + texB) * _Color;
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
