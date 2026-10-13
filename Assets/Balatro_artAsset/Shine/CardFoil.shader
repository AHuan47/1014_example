Shader "Custom/CardFoil"
{
    Properties
    {
        _MainTex ("Card Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1, 1, 1, 1)

        _Tilt ("Tilt XY", Vector) = (0, 0, 0, 0)
        _MaxAngle ("Max Angle", Range(0, 35)) = 15
        _PerspectiveDistance ("Perspective Distance", Range(1, 10)) = 2.5

        _FoilStrength ("Rainbow Strength", Range(0, 1)) = 0.45
        _RainbowScale ("Rainbow Scale", Range(0.1, 8)) = 2
        _AngleSensitivity ("Angle Sensitivity", Range(0, 3)) = 1

        _ShineStrength ("Shine Strength", Range(0, 3)) = 0.8
        _ShineWidth ("Shine Width", Range(0.01, 0.8)) = 0.25
        [HDR] _ShineColor ("Shine Color", Color) = (1, 1, 1, 1)

        _PatternScale ("Foil Pattern Scale", Range(1, 100)) = 35
        _PatternStrength ("Foil Pattern Strength", Range(0, 1)) = 0.25
        _Aspect ("Card Width / Height", Float) = 0.7
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
                float4 _Tilt;
                float _MaxAngle;
                float _PerspectiveDistance;
                float _FoilStrength;
                float _RainbowScale;
                float _AngleSensitivity;
                float _ShineStrength;
                float _ShineWidth;
                float4 _ShineColor;
                float _PatternScale;
                float _PatternStrength;
                float _Aspect;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 textureUVProjective : TEXCOORD0;
                float3 cardUVProjective : TEXCOORD1;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;

                float aspect = max(_Aspect, 0.001);

                float3 p = float3(
                    input.positionOS.x * aspect,
                    input.positionOS.y,
                    0.0
                );

                float2 tilt = clamp(_Tilt.xy, -1.0, 1.0);
                float angleX = radians(-tilt.y * _MaxAngle);
                float angleY = radians( tilt.x * _MaxAngle);

                float sinX = sin(angleX);
                float cosX = cos(angleX);

                p = float3(
                    p.x,
                    p.y * cosX - p.z * sinX,
                    p.y * sinX + p.z * cosX
                );

                float sinY = sin(angleY);
                float cosY = cos(angleY);

                p = float3(
                    p.x * cosY + p.z * sinY,
                    p.y,
                    -p.x * sinY + p.z * cosY
                );

                float cameraDistance = max(_PerspectiveDistance, 1.0);
                float perspective =
                    cameraDistance / max(cameraDistance + p.z, 0.1);

                float3 projectedPosition = float3(
                    p.x * perspective / aspect,
                    p.y * perspective,
                    input.positionOS.z
                );

                output.positionCS =
                    TransformObjectToHClip(projectedPosition);

                float2 textureUV = TRANSFORM_TEX(input.uv, _MainTex);

                output.textureUVProjective = float3(
                    textureUV * perspective,
                    perspective
                );

                output.cardUVProjective = float3(
                    input.uv * perspective,
                    perspective
                );

                return output;
            }

            // ±m­i
            float3 Rainbow(float phase)
            {
                return 0.5 + 0.5 * cos(
                    6.2831853 * (
                        phase + float3(0.0, 0.333333, 0.666667)
                    )
                );
            }

            half4 Frag(Varyings input) : SV_Target
            {
                float2 textureUV =
                    input.textureUVProjective.xy / input.textureUVProjective.z;

                float2 cardUV =
                    input.cardUVProjective.xy / input.cardUVProjective.z;

                half4 card = SAMPLE_TEXTURE2D(
                    _MainTex,
                    sampler_MainTex,
                    textureUV
                ) * _Color;

                float2 p = cardUV - 0.5;
                p.x *= max(_Aspect, 0.001);

                float2 tilt =
                    clamp(_Tilt.xy, -1.0, 1.0)
                    * (_MaxAngle / 15.0)
                    * _AngleSensitivity;

                float patternX = sin(
                    (p.x + p.y) * _PatternScale * 6.2831853
                    + tilt.x * 4.0
                );

                float patternY = sin(
                    (p.x - p.y) * _PatternScale * 6.2831853
                    + tilt.y * 4.0
                );

                float pattern = 0.5 + 0.5 * patternX * patternY;

                float phase =
                    (p.x + p.y * 0.65) * _RainbowScale
                    + tilt.x * 0.65
                    + tilt.y * 0.45
                    + (pattern - 0.5) * _PatternStrength;

                float3 rainbow = Rainbow(phase);

                float shineCoordinate = p.x + p.y * 0.6;
                float shineCenter = tilt.x * 0.45 + tilt.y * 0.3;

                float shine = 1.0 - smoothstep(
                    0.0,
                    max(_ShineWidth, 0.001),
                    abs(shineCoordinate - shineCenter)
                );

                float3 foilTint = lerp(
                    float3(1.0, 1.0, 1.0),
                    0.35 + rainbow * 0.85,
                    _FoilStrength
                );

                float3 result = card.rgb * foilTint;

                float3 reflectionColor = lerp(
                    rainbow,
                    float3(1.0, 1.0, 1.0),
                    0.35
                );

                result +=
                    reflectionColor
                    * _ShineColor.rgb
                    * shine
                    * _ShineStrength
                    * lerp(1.0, 0.5 + pattern * 0.5, _PatternStrength);

                return half4(result, card.a);
            }

            ENDHLSL
        }
    }
}