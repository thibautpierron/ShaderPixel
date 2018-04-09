Shader "PixelShader/IFS"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Offset ("Offset", Vector) = (0.0, 0.0, 0.0)
		_Neg ("Neg", Int) = 0

	}
	SubShader
	{
		Tags {"Queue"="Transparent" "RenderType"="Transparent" }
		LOD 100

		ZWrite Off
	    Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 wPos : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			float3 viewDirection;
			float3 _Offset;
			float4x4 _Rotation;
			int _Neg;
			
			#define MAX_ITERATION 40
			#define DIAMETER 100.0
			#define EPS 1e-5

			float DE(float3 p, float3 pixsize)
			{
				const float3 p0 = float3(-1, -1, -1);
				const float3 p1 = float3(1, 1, -1);
				const float3 p2 = float3(1, -1, 1);
				const float3 p3 = float3(-1, 1, 1);

				const int maxit = 15;
				const float scale = 2;
				for (int i = 0; i < maxit; ++i)
				{
					float d = distance(p, p0);
					float3 c = p0;

					float t = distance(p, p1);
					if (t < d) {
						d = t;
						c = p1;
					}
					t = distance(p, p2);
					if (t < d) {
						d = t;
						c = p2;
					}
					t = distance(p, p3);
					if (t < d) {
						d = t;
						c = p3;
					}

					p = (p - c) * scale;
				}

				return length(p) * pow(scale, float(-maxit)) - pixsize;
			}

			fixed4 raymarch (float3 position, float3 direction)
			{
				float3 p = position;
				int it = MAX_ITERATION;
				float pixel_size = 1.0 / (_ScreenParams.x + _ScreenParams.y); 
				for (int i = 0; i < MAX_ITERATION; ++i)
				{
					if (dot(p, p) > DIAMETER)
					{
						it = i;
						break;
					}
					float d = DE(mul(_Rotation, p), pixel_size * distance(p, position));
					if (d < EPS) {
						it = i;
						break;
					}
					p += direction * d;
				}
				if (it == 0)
					return fixed4(0, 0, 0, 0);
				else {
					float t = float(it) / float(MAX_ITERATION);
					if (_Neg == 0)
						t = 1.0 - t;
					return fixed4(t, t, t, 1.0);
				}
			}

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 worldPosition = i.wPos;
				viewDirection = normalize(i.wPos - _WorldSpaceCameraPos);

				return raymarch(worldPosition - _Offset, viewDirection);
			}
			ENDCG
		}
	}
}
