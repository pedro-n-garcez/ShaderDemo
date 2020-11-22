Shader "Unlit/RivShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "gray" {}
        _TintColor("Tint Color", Color) = (1,1,1,1)
        _Transparency("Transparency",Range(0.0,1.0)) = 0.25

        _Speed("Speed", float) = 0.5
        _Wavelength("Wavelength",float) = 10
        //_Amplitude("Amplitude", float) = 1
        _Steepness("Steepness",Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 100

        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _TintColor;
            float _Transparency;

            float _Speed;
            //float _Amplitude;
            float _Steepness;
            float _Wavelength;

            //simple water simulation based on https://catlikecoding.com/unity/tutorials/flow/waves/
            v2f vert (appdata v)
            {
            	float3 pos = v.vertex.xyz;
                float k = 2 * UNITY_PI / _Wavelength;
                float f = k * pos.x - _Speed * _Time.y;
                float a = _Steepness / k;

                pos.x += a * cos(f);
                pos.y = a * sin(f);
                v.vertex.xyz = pos;

                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) + _TintColor;
                col.a = _Transparency;
                return col;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}