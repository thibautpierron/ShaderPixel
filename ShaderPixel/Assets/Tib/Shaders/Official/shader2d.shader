Shader "Unlit/shader2d"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
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
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 v1 = _SinTime * 20 * i.uv.x;
				float3 v2 = _CosTime * 20 * i.uv.y;
				float3 v3 = _SinTime * 20 * (i.uv.x + i.uv.y);
				float3 v4 = _CosTime * 20 * (length(i.uv) + 1.7);
				float3 v = v1 + v2 + v3 + v4;
				
				float3 col;
				
				// if(i.uv.x < 1./10.)
				// 	col = v1;
				// else if(i.uv.x < 2./10.)
				// 	col = v2;
				// else if(i.uv.x < 3./10.)
				// 	col = v3;
				// else if(i.uv.x < 4./10.)
				// 	col = v4;
				// else if(i.uv.x < 5./10.)
				// 	col = v;	
				// else if(i.uv.x < 6./10.)
				// 	col = sin(2.0 * v);
				// else if(i.uv.x < 10./10.) {
					// v *= 1.0;
					col.x = sin(v);
					col.y = sin(v + 0.5 * 3.14);
					col.z = sin(v + 1.0 * 3.14);
					// col = float3(sin(v), sin(v + 0.5 * 3.14), sin(v + 1.0 * 3.14));
				// }	
				
				// col = 0.5 + 0.5 * col;
				fixed4 ret;
				ret.rgb = col;
				ret.a = 1;
				// ret.x = col.x;
				// ret.y = col.y;
				// ret.z = col.z;
				return ret;
			}
			ENDCG
		}
	}
}
