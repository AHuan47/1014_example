Shader "Custom/CRTFullscreen"
{
    Properties
    {
        _ScanlineIntensity ("Scanline Intensity", Range(0, 1)) = 0.12
        _ScanlineCount ("Scanline Count", Float) = 540

        _ChromaticAberration (
            "Chromatic Aberration", Range(0, 0.02)
        ) = 0.0005

        _VignetteIntensity (
            "Vignette Intensity", Range(0, 2)
        ) = 0.08
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }

        ZWrite Off
        ZTest Always
        Cull Off

        Pass
        {
            Name "CRT Pass"

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float _ScanlineIntensity;
                float _ScanlineCount;
                float _ChromaticAberration;
                float _VignetteIntensity;
            CBUFFER_END

            half4 Frag(Varyings input) : SV_Target
            {
                float2 uv = input.texcoord;

                // ¦â®t
                float2 offset =
                    float2(_ChromaticAberration, 0.0);

                float r = SAMPLE_TEXTURE2D_X(
                    _BlitTexture, sampler_LinearClamp,
                    uv + offset
                ).r;

                float g = SAMPLE_TEXTURE2D_X(
                    _BlitTexture, sampler_LinearClamp,
                    uv
                ).g;

                float b = SAMPLE_TEXTURE2D_X(
                    _BlitTexture, sampler_LinearClamp,
                    uv - offset
                ).b;

                float3 color = float3(r, g, b);

                //±½´y½u
                float scanline =
                    sin(uv.y * _ScanlineCount * 6.2831853);

                float scanlineFactor =
                    1.0 - _ScanlineIntensity
                    * (scanline * 0.5 + 0.5);

                color *= scanlineFactor;

                // ·t¨¤
                float2 centered = uv * 2.0 - 1.0;

                float vignette =
                    1.0 - dot(centered, centered)
                    * _VignetteIntensity * 0.5;

                color *= saturate(vignette);

                return half4(saturate(color), 1);
            }

            ENDHLSL
        }
    }
}