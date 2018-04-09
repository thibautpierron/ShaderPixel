Shader "PixelShader/shader2d"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_R1 ("random num1", float) = 0
		_R2 ("random num2", float) = 0
		_R3 ("random num3", float) = 0
		_R4 ("random num4", float) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

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
			float _R1;
			float _R2;
			float _R3;
			float _R4;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {		
				float3 col;
				if(i.uv.x < 1./4. && i.uv.y < _R1 * 2)
					col = _CosTime;
				else if(i.uv.x < 2./4. && i.uv.y < _R2 * 2)
					col = _CosTime * 0.2;
				else if(i.uv.x < 3./4. && i.uv.y < _R3 * 2)
					col = _CosTime * 0.4;
				else if(i.uv.x < 4./4. && i.uv.y < _R4 * 10)
					col = _CosTime * 0.6;
				else
					col = _SinTime * i.uv.y;

				fixed4 ret;
				ret.rgb = col;
				ret.a = 1;
				return ret;
			}
			ENDCG
		}
	}
}
