//Code partly based on: https://github.com/adrian-miasik/unity-shaders/blob/develop/Assets/Shaders/Shaders%20-%20Standard/Sine%20Vertex%20Displacement.shader
Shader "Custom/example"
{
     Properties
    {
        _Speed("Speed", float) = 0.5
        _Axis("Axis", Vector) = (0.1, 1, 0.1)
        _Color("Axis", Color) = (0.23, 0.95, 0.33, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

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
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            float _Speed;
            float3 _Axis;
            float4 _Color;

            float4 Unity_Combine_float(float R, float G, float B, float A)
            {
                return float4(R, G, B, A);
            }

            v2f vert (appdata v)
            {
                float time = _Speed * _Time * 200;

                float4 sineWave = sin(time + v.vertex/10);

                float3 waveX = sineWave * _Axis.r;
                float3 waveY = sineWave * _Axis.g;
                float3 waveZ = sineWave * _Axis.b;

                float4 modifiedVerts = Unity_Combine_float(v.vertex.x + waveX, v.vertex.y +  waveY, v.vertex.z +  waveZ, 1);

                v2f o;
                o.vertex = UnityObjectToClipPos(modifiedVerts);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _Color;
            }
            ENDCG
        }
    }
}