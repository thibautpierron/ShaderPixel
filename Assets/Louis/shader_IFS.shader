Shader "PixelShader/IFS"
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
	//	_Rotation ("Rotation", Matrix)

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
			
		//	#define STEPS			64
		//	#define STEP_SIZE		1.0
		//	#define ITER_DETAIL		0.003
		//	#define ITER_FRACTAL	7

		//	#define fixedRadius 	0.1
		//	#define minRadius   	0.05
		//	#define foldingLimit	(0.1)

		//	#define fixedRadius2	(fixedRadius * fixedRadius)
		//	#define minRadius2		(minRadius * minRadius)


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

		//	float  _Scale;
			float3 _Light;
			float3 _Specular;
			float3 _Gloss;
			fixed4 _Color;
			float3 viewDirection;
			float3 _Offset; //
			float4x4 _Rotation; //
			
			/*
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

			fixed4 renderSurface(float3 p) {
				float3 n = normal(p);
				float occ = calcAO(p, n);
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
			}*/

			/*
			#define A (1.0)
			#define B (A / 1.73205)
			#define C (A / 0.86603)
			#define PRECISION 0.002
			

			const float3 va = float3(  0.0,  B,  0.0 );
			const float3 vb = float3(  0.0, -A,  C );
			const float3 vc = float3(  A, -A, -B );
			const float3 vd = float3( -A, -A, -B );
			*/
/*
			const float3 va = float3(  0.0,  0.57735,  0.0 );
			const float3 vb = float3(  0.0, -1.0,  1.15470 );
			const float3 vc = float3(  1.0, -1.0, -0.57735 );
			const float3 vd = float3( -1.0, -1.0, -0.57735 );

			float2 map(float3 p)
			{
				float a = 0.0;
				float s = 1.0;
				float r = 1.0;
				float dm;
				float3 v;

				for (int i = 0; i < 8; ++i)
				{
					float d, t;

					d = dot(p - va, p - va);
					v = va;
					dm = d;
					t = 0.0;

					d = dot(p - vb, p - vb);
					if (d < dm)
					{
						v = vb;
						dm = d;
						t = 1.0;
					}

					d = dot(p - vc, p - vc);
					if (d < dm)
					{
						v = vc;
						dm = d;
						t = 2.0;
					}

					d = dot(p - vd, p - vd);
					if (d < dm)
					{
						v = vd;
						dm = d;
						t = 3.0;
					}

					p = v + 2.0 * (p - v);
					r *= 2.0;
					a = t + 4.0 * a;
					s *= 4.0;
				}
				return float2( (sqrt(dm) - 1.0)/r, a/s );
			}

			float3 intersect(in float3 position, in float3 direction)
			{
				float3 res = float3(1e20, 0.0, 0.0);
				float maxd = 5.0;

				float h = 1.0;
				float t = 0.5;
				float m = 0.0;

				float2 r;
				for (int i = 0; i < 100; i++)
				{
					r = map(position + direction * t);

					if (r.x < PRECISION || t > maxd) break;

					m = r.y;
					t += r.x;
				}
				if (t < maxd && r.x < PRECISION)
					res = float3(t, 2.0, m);
				return res;
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
				const float eps = PRECISION;
				
				return normalize( float3(
							map(p + float3(eps, 0, 0) ).x - map(p - float3(eps, 0, 0)).x,
							map(p + float3(0, eps, 0) ).x - map(p - float3(0, eps, 0)).x,
							map(p + float3(0, 0, eps) ).x - map(p - float3(0, 0, eps)).x
						)
					);
			}
			*/
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
					float t = 1.0 - float(it) / float(MAX_ITERATION);
					return fixed4(t, t, t, 1.0);
					/*
					if (t > 0)
						return fixed4(t, t, t, 1.0);
					else
						return (0, 0, 0, 1);
						*/
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
