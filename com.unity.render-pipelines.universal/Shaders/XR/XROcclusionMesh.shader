Shader "Hidden/Universal Render Pipeline/XR/XROcclusionMesh"
{
    HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        #pragma exclude_renderers gles
        // Not all platforms properly support SV_RenderTargetArrayIndex
        #if defined(SHADER_API_D3D11) || defined(SHADER_API_VULKAN) || defined(SHADER_API_GLCORE) || defined(SHADER_API_GLES3) || defined(SHADER_API_PSSL)
            #pragma multi_compile _ XR_OCCLUSION_MESH_COMBINED
        #endif

        struct Attributes
        {
            float4 vertex : POSITION;
        };

        struct Varyings
        {
            float4 vertex : SV_POSITION;

        #if XR_OCCLUSION_MESH_COMBINED
            uint rtArrayIndex : SV_RenderTargetArrayIndex;
        #endif
        };

        Varyings Vert(Attributes input)
        {
            Varyings output;
            output.vertex = float4(input.vertex.xy * float2(2.0f, -2.0f) + float2(-1.0f, 1.0f), UNITY_NEAR_CLIP_VALUE, 1.0f);

        #if XR_OCCLUSION_MESH_COMBINED
            output.rtArrayIndex = input.vertex.z;
        #endif

            return output;
        }

        float4 Frag() : SV_Target
        {
            return (0.0f).xxxx;
        }

    ENDHLSL

    SubShader
    {
        Tags{ "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            ZWrite On ZTest Always Blend Off Cull Off
            ColorMask 0

            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment Frag
            ENDHLSL
        }
    }
    Fallback Off
}
