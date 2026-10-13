Shader "Custom/CardPerspective"
{
    Properties
    {
        _MainTex ("Card Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1, 1, 1, 1)

        _Tilt ("Tilt XY", Vector) = (0, 0, 0, 0)
        _MaxAngle ("Max Angle", Range(0, 35)) = 15
        _PerspectiveDistance ("Perspective Distance", Range(1, 10)) = 2.5
        _Aspect ("Card Width / Height", Float) = 0.666667
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
            Name "Card"
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
                float3 uvProjective : TEXCOORD0;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;

                float aspect = max(_Aspect, 0.001);

                // 用卡牌高度作為單位
                float3 p = float3(
                    input.positionOS.x * aspect,
                    input.positionOS.y,
                    0.0
                );

                float2 tilt = clamp(_Tilt.xy, -1.0, 1.0);
                float angleX = radians(-tilt.y * _MaxAngle);
                float angleY = radians( tilt.x * _MaxAngle);

                // 繞 X 軸
                float sinX = sin(angleX);
                float cosX = cos(angleX);

                p = float3(
                    p.x,
                    p.y * cosX - p.z * sinX,
                    p.y * sinX + p.z * cosX
                );

                // 繞 Y 軸
                float sinY = sin(angleY);
                float cosY = cos(angleY);

                p = float3(
                    p.x * cosY + p.z * sinY,
                    p.y,
                    -p.x * sinY + p.z * cosY
                );

                float distance = max(_PerspectiveDistance, 1.0);
                float denominator = max(distance + p.z, 0.1);
                float perspective = distance / denominator;

                float3 projectedPosition = float3(
                    p.x * perspective / aspect,
                    p.y * perspective,
                    input.positionOS.z
                );

                output.positionCS =
                    TransformObjectToHClip(projectedPosition);

                float2 uv = TRANSFORM_TEX(input.uv, _MainTex);

                output.uvProjective = float3(
                    uv * perspective,
                    perspective
                );

                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                float2 uv =
                    input.uvProjective.xy / input.uvProjective.z;

                return SAMPLE_TEXTURE2D(
                    _MainTex,
                    sampler_MainTex,
                    uv
                ) * _Color;
            }
            ENDHLSL
        }
    }
}