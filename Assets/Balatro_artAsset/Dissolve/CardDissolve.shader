Shader "Custom/CardDissolve"
{
    Properties
    {
        _MainTex ("Card Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1, 1, 1, 1)

        _Dissolve ("Dissolve", Range(0, 1)) = 0
        _NoiseScale ("Noise Scale", Range(1, 30)) = 8
        _NoiseSeed ("Noise Offset XY", Vector) = (0, 0, 0, 0)
        _Aspect ("Card Width / Height", Float) = 0.7

        _EdgeWidth ("Burn Edge Width", Range(0.001, 0.2)) = 0.05
        [HDR] _EdgeColor ("Burn Edge Color", Color) = (3, 0.8, 0.1, 1)
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Tags { "LightMode" = "SRPDefaultUnlit" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _Color;
                float _Dissolve;
                float _NoiseScale;
                float4 _NoiseSeed;
                float _Aspect;
                float _EdgeWidth;
                float4 _EdgeColor;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 textureUV : TEXCOORD0;
                float2 cardUV : TEXCOORD1;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;

                output.positionCS =
                    TransformObjectToHClip(input.positionOS.xyz);

                output.textureUV = TRANSFORM_TEX(input.uv, _MainTex);

                output.cardUV = input.uv;

                return output;
            }

            float Hash21(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return frac(p.x * p.y);
            }

            float ValueNoise(float2 uv)
            {
                float2 cell = floor(uv);
                float2 f = frac(uv);

                f = f * f * (3.0 - 2.0 * f);

                float a = Hash21(cell);
                float b = Hash21(cell + float2(1, 0));
                float c = Hash21(cell + float2(0, 1));
                float d = Hash21(cell + float2(1, 1));

                return lerp(
                    lerp(a, b, f.x),
                    lerp(c, d, f.x),
                    f.y
                );
            }

            half4 Frag(Varyings input) : SV_Target
            {
                half4 color = SAMPLE_TEXTURE2D(
                    _MainTex,
                    sampler_MainTex,
                    input.textureUV
                ) * _Color;

                if (_Dissolve <= 0.0)
                    return color;

                if (_Dissolve >= 1.0)
                    discard;

                float2 noiseUV = float2(
                    input.cardUV.x * max(_Aspect, 0.001),
                    input.cardUV.y
                ) * _NoiseScale + _NoiseSeed.xy;

                float noise =
                    ValueNoise(noiseUV) * 0.75 +
                    ValueNoise(noiseUV * 2.0 + 17.3) * 0.25;

                float remaining = noise - _Dissolve;

                clip(remaining);

                float edge = 1.0 - smoothstep(
                    0.0,
                    max(_EdgeWidth, 0.0001),
                    remaining
                );

                color.rgb = lerp(
                    color.rgb,
                    _EdgeColor.rgb,
                    edge
                );

                return color;
            }

            ENDHLSL
        }
    }
}