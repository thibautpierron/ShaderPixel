Shader "Unlit/unlit"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}

		_Scale ("Scale", Float) = 2
		_Light ("Light", vector) = (0.0, 0.0, 0.0)
		_Specular ("Specular", float) = 1.0
		_Gloss ("Gloss", float) = 1.0

		_Color ("Color", Color) = (0.5, 0.5, 0.5, 1)

		_Offset ("Offset", Vector) = (0.0, 0.0, 0.0) //

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
			
			#define STEPS			64
			#define STEP_SIZE		0.1
			#define ITER_DETAIL		0.03
			#define ITER_FRACTAL	8

			#define fixedRadius2	(1.0 * 1.0)
			#define minRadius2		(0.5 * 0.5)
			#define foldingLimit	(1.0)

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

			float  _Scale;
			float3 _Light;
			float3 _Specular;
			float3 _Gloss;

			fixed4 _Color;

			float3 viewDirection;

			float3 _Offset; //
			
			void boxFold(inout float3 z, inout float dz)
			{
				z = clamp(z, -foldingLimit, foldingLimit) * 2.0 - z;
			}

			void sphereFold(inout float3 z, inout float dz)
			{
				float r2 = dot(z, z);
				if (r2 < minRadius2)
				{
					float temp = (fixedRadius2 / minRadius2);
					z *= temp;
					dz *= temp;
				}
				else if (r2 < fixedRadius2)
				{
					float temp = (fixedRadius2 / r2);
					z *= temp;
					dz *= temp;
				}
			}

			float mandelbox(in float3 z)
			{
				float3 offset = z;
				float  dr = 1.0;

				for (int n = 0; n < ITER_FRACTAL; ++n)
				{
					boxFold(z, dr);
					sphereFold(z, dr);
					z = _Scale * z + offset;
					dr = dr * abs(_Scale) + 1.0;
				}
				float r = length(z);
				return r / abs(dr);
			}

			float map (float3 p) {
				return mandelbox(p);
			}

			float calcAO( in float3 p, in float3 n ) {
				float occ = 0.0;
				float sca = 1.0;
				for (int i = 0; i < 5; i++) {
					float hr = 0.01 + 0.12 * float(i) / 4.0;
					float3 aopos =  n * hr + p;
					float dd = map(aopos).x;
					occ += - (dd - hr) * sca;
					sca *= 0.95;
				}
				return clamp( 1.0 - 3.0 * occ, 0.0, 1.0 );    
			}

			fixed4 simpleLambert(fixed3 normal) {
				fixed3 lightDir = _Light.xyz;
				fixed3 lightCol = _LightColor0.rgb;
				fixed3 ambient = (0.2, 0.2, 0.2);

				fixed3 NdotL = max(dot(normal, lightDir), 0);

				fixed3 h = (lightDir - viewDirection) / 2;
				fixed specular = pow( dot(normal, h), _Specular) * _Gloss;

				fixed4 c;
				c.rgb = ambient + _Color * lightCol * NdotL + specular;
				c.a = 1;
				return c;
			}

			float3 normal(float3 p) {
				const float eps = 0.01;
				
				return normalize( float3(
							map(p + float3(eps, 0, 0) ) - map(p - float3(eps, 0, 0)),
							map(p + float3(0, eps, 0) ) - map(p - float3(0, eps, 0)),
							map(p + float3(0, 0, eps) ) - map(p - float3(0, 0, eps))
						)
					);
			}

			fixed4 renderSurface(float3 p) {
				float3 n = normal(p);
			//	float occ = calcAO(p, n);
				return simpleLambert(n);
			}
			
			float softshadow( float3 ro, float3 rd, float mint, float maxt)
			{
				float res = 1.0;
				float t = mint;
				for (int i = 0; i < 16; i++)
				{
					float h = map(ro + rd * t);
					res = min(res, 8.0 * h / t);
					t += clamp(h, 0.02, 0.1);
					if (h < 0.001 || t > maxt)
						break;
				}
				return clamp(res, 0.2, 1.0);
			}

			fixed4 raymarch (float3 position, float3 direction)
			{
				float totalDist = 0.0;
				for (int i = 0; i < STEPS; i++)
				{
//					position += totalDist * direction;
					float3 p = position + totalDist * direction;
					float dist = min(mandelbox(p), 1.0); // 3.0
					totalDist += dist;
					if (dist < ITER_DETAIL)
					{
					//	float s = softshadow(position, _Light, 0.02, 2.5);
						fixed4 c = renderSurface(p); // * s;
						c.a = 1;
					//	fixed4 c = fixed4(1, 1, 1, 1);
						return c;
					}
				}
				return fixed4(0, 0, 0, 0);
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

				return raymarch(worldPosition, viewDirection);
			}
			ENDCG
		}
	}
}
