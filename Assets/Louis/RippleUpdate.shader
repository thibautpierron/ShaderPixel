Shader "CustomRenderTexture/Simple"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Tex("InputTex", 2D) = "white" {}
     }

     SubShader
     {
        Lighting Off
        Blend One Zero

        Pass
        {
            CGPROGRAM
            #include "UnityCustomRenderTexture.cginc"
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag
            #pragma target 3.0

            float4      _Color;
            sampler2D   _Tex;

            #define RES (1024.0)
            #define M (10.0)
            #define H (0.5)

            float4 frag(v2f_customrendertexture IN) : COLOR
            {
                float2 uv = IN.localTexcoord.xy;

                float w = (H - (uv.x)) * (_ScreenParams.x / _ScreenParams.y);
                float h = H - uv.y;
                float distanceFromCenter = sqrt(w * w + h * h);

                float sinArg = distanceFromCenter * M - _Time.y * M;
                float slope = cos(sinArg);

                return _Color * tex2D(_Tex, uv + normalize(float2(w, h)) * slope * 0.05);
            }
            ENDCG
        }
    }
}