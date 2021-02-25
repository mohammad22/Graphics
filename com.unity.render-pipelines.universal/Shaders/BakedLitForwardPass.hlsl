
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    float4 positionOS       : POSITION;
    float2 uv               : TEXCOORD0;
    float2 lightmapUV       : TEXCOORD1;
    float3 normalOS         : NORMAL;
    float4 tangentOS        : TANGENT;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float3 uv0AndFogCoord : TEXCOORD0; // xy: uv0, z: fogCoord
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
    half3 normalWS : TEXCOORD2;

    #if defined(_NORMALMAP)
    half4 tangentWS : TEXCOORD3;
    #endif

    #if defined(_DEBUG_SHADER)
    float3 positionWS : TEXCOORD4;
    float3 viewDirWS : TEXCOORD5;
    #endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

InputData CreateInputData(Varyings input, half3 normalTS)
{
    InputData inputData = (InputData)0;

    #if defined(_DEBUG_SHADER)
    inputData.positionWS = input.positionWS;
    inputData.viewDirectionWS = input.viewDirWS;
    #else
    inputData.positionWS = float3(0, 0, 0);
    inputData.viewDirectionWS = half3(0, 0, 1);
    #endif

    #if defined(_NORMALMAP)
    float sgn = input.tangentWS.w;      // should be either +1 or -1
    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);

    inputData.tangentMatrixWS = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
    inputData.normalWS = TransformTangentToWorld(normalTS, inputData.tangentMatrixWS);
    #else
    inputData.normalWS = input.normalWS;
    #endif

    inputData.shadowCoord = float4(0, 0, 0, 0);
    inputData.fogCoord = input.uv0AndFogCoord.z;
    inputData.vertexLighting = half3(0, 0, 0);
    inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
    inputData.shadowMask = half4(1, 1, 1, 1);
    inputData.normalTS = normalTS;

    #if defined(LIGHTMAP_ON)
    inputData.lightmapUV = input.lightmapUV;
    #else
    inputData.vertexSH = input.vertexSH;
    #endif

    return inputData;
}

Varyings BakedLitForwardPassVertex(Attributes input)
{
    Varyings output;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    output.positionCS = vertexInput.positionCS;
    output.uv0AndFogCoord.xy = TRANSFORM_TEX(input.uv, _BaseMap);
    output.uv0AndFogCoord.z = ComputeFogFactor(vertexInput.positionCS.z);

    // normalWS and tangentWS already normalize.
    // this is required to avoid skewing the direction during interpolation
    // also required for per-vertex SH evaluation
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.normalWS = normalInput.normalWS;
    #if defined(_NORMALMAP)
    real sign = input.tangentOS.w * GetOddNegativeScale();
    output.tangentWS = half4(normalInput.tangentWS.xyz, sign);
    #endif
    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normalWS, output.vertexSH);

    #if defined(_DEBUG_SHADER)
    output.positionWS = vertexInput.positionWS;
    output.viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
    #endif

    return output;
}

half4 BakedLitForwardPassFragment(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    half2 uv = input.uv0AndFogCoord.xy;
    #if defined(_NORMALMAP)
    half3 normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap)).xyz;
    #else
    half3 normalTS = half3(0, 0, 1);
    #endif
    InputData inputData = CreateInputData(input, normalTS);
    SETUP_DEBUG_TEXTURE_DATA(inputData, input.uv0AndFogCoord.xy, _BaseMap);

    half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
    half3 color = texColor.rgb * _BaseColor.rgb;
    half alpha = texColor.a * _BaseColor.a;

    AlphaDiscard(alpha, _Cutoff);

    half4 finalColor = UniversalFragmentBakedLit(inputData, color, alpha, normalTS);

    finalColor.a = OutputAlpha(finalColor.a, _Surface);
    return finalColor;
}
