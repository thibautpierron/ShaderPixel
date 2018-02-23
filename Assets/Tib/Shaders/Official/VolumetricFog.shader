Shader "PixelShader/VolumetricFog"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color ("Color", Color) = (0.5, 0.5, 0.5, 1)
		_Specular ("Specular", float) = 1.0
		_Gloss ("Gloss", float) = 1.0
		_Offset ("Offset", vector) = (0.0, 0.0, 0.0)
		_Light ("Light", vector) = (0.0, 0.0, 0.0)
		_Alpha ("Alpha", Range(0, 1)) = 0.5
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
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float3 wPos : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			float _Specular;
			float _Gloss;
			float _Alpha;
			float3 _Offset;
			float3 _Light;
			float3 viewDirection;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}

			fixed4 simpleLambert(fixed3 normal) {
				fixed3 lightDir = _Light.xyz;
				fixed3 lightCol = _LightColor0.rgb;

				fixed3 NdotL = max(dot(normal, lightDir), 0);

				fixed3 h = (lightDir - viewDirection) / 2;
				fixed specular = pow( dot(normal, h), _Specular) * _Gloss;

				fixed4 c;
				c.rgb = _Color * lightCol * NdotL + specular;
				c.a = 1;
				return c;
			}

			float sdf_plane(float3 p, float3 n, float distanceFromOrigin) {
				return dot(p, n) + distanceFromOrigin;
			}

			float sdf_sphere(float3 p, float3 c, float r) {
				return distance(p, c) - r;
			}

			float sdf_box(float3 p, float3 c, float3 s) {
				float x = max
				(   p.x - c.x - float3(s.x / 2., 0, 0),
					c.x - p.x - float3(s.x / 2., 0, 0)
				);
			
				float y = max
				(   p.y - c.y - float3(s.y / 2., 0, 0),
					c.y - p.y - float3(s.y / 2., 0, 0)
				);
				
				float z = max
				(   p.z - c.z - float3(s.z / 2., 0, 0),
					c.z - p.z - float3(s.z / 2., 0, 0)
				);
			
				float d = x;
				d = max(d,y);
				d = max(d,z);
				return d;
			}

			float noise3D(float3 p) {
				return frac(sin(dot(p ,float3(12.9898,78.233,128.852))) * 43758.5453)*2.0-1.0;
			}

			float simplex3D(float3 p) {
				float f3 = 1.0/3.0;
				float s = (p.x+p.y+p.z)*f3;
				int i = int(floor(p.x+s));
				int j = int(floor(p.y+s));
				int k = int(floor(p.z+s));
				
				float g3 = 1.0/6.0;
				float t = float((i+j+k))*g3;
				float x0 = float(i)-t;
				float y0 = float(j)-t;
				float z0 = float(k)-t;
				x0 = p.x-x0;
				y0 = p.y-y0;
				z0 = p.z-z0;
				
				int i1,j1,k1;
				int i2,j2,k2;
				
				if(x0>=y0)
				{
					if(y0>=z0){ i1=1; j1=0; k1=0; i2=1; j2=1; k2=0; }
					else if(x0>=z0){ i1=1; j1=0; k1=0; i2=1; j2=0; k2=1; }
					else { i1=0; j1=0; k1=1; i2=1; j2=0; k2=1; } 
				}
				else 
				{ 
					if(y0<z0) { i1=0; j1=0; k1=1; i2=0; j2=1; k2=1; }
					else if(x0<z0) { i1=0; j1=1; k1=0; i2=0; j2=1; k2=1; }
					else { i1=0; j1=1; k1=0; i2=1; j2=1; k2=0; }
				}
				
				float x1 = x0 - float(i1) + g3; 
				float y1 = y0 - float(j1) + g3;
				float z1 = z0 - float(k1) + g3;
				float x2 = x0 - float(i2) + 2.0*g3; 
				float y2 = y0 - float(j2) + 2.0*g3;
				float z2 = z0 - float(k2) + 2.0*g3;
				float x3 = x0 - 1.0 + 3.0*g3; 
				float y3 = y0 - 1.0 + 3.0*g3;
				float z3 = z0 - 1.0 + 3.0*g3;	
							
				float3 ijk0 = float3(i,j,k);
				float3 ijk1 = float3(i+i1,j+j1,k+k1);	
				float3 ijk2 = float3(i+i2,j+j2,k+k2);
				float3 ijk3 = float3(i+1,j+1,k+1);	
						
				float3 gr0 = normalize(float3(noise3D(ijk0),noise3D(ijk0*2.01),noise3D(ijk0*2.02)));
				float3 gr1 = normalize(float3(noise3D(ijk1),noise3D(ijk1*2.01),noise3D(ijk1*2.02)));
				float3 gr2 = normalize(float3(noise3D(ijk2),noise3D(ijk2*2.01),noise3D(ijk2*2.02)));
				float3 gr3 = normalize(float3(noise3D(ijk3),noise3D(ijk3*2.01),noise3D(ijk3*2.02)));
				
				float n0 = 0.0;
				float n1 = 0.0;
				float n2 = 0.0;
				float n3 = 0.0;

				float t0 = 0.5 - x0*x0 - y0*y0 - z0*z0;
				if(t0>=0.0)
				{
					t0*=t0;
					n0 = t0 * t0 * dot(gr0, float3(x0, y0, z0));
				}
				float t1 = 0.5 - x1*x1 - y1*y1 - z1*z1;
				if(t1>=0.0)
				{
					t1*=t1;
					n1 = t1 * t1 * dot(gr1, float3(x1, y1, z1));
				}
				float t2 = 0.5 - x2*x2 - y2*y2 - z2*z2;
				if(t2>=0.0)
				{
					t2 *= t2;
					n2 = t2 * t2 * dot(gr2, float3(x2, y2, z2));
				}
				float t3 = 0.5 - x3*x3 - y3*y3 - z3*z3;
				if(t3>=0.0)
				{
					t3 *= t3;
					n3 = t3 * t3 * dot(gr3, float3(x3, y3, z3));
				}
				return 96.0*(n0+n1+n2+n3);
			}

			float fbm(float3 p) {
				float f;
				f  = 0.50000*simplex3D( p ); p = p*2.01;
				f += 0.25000*simplex3D( p ); p = p*2.02;
				f += 0.12500*simplex3D( p ); p = p*2.03;
				f += 0.06250*simplex3D( p ); p = p*2.04;
				f += 0.03125*simplex3D( p );
				return f;
			}

			fixed4 raymarch(float3 position, float3 direction) {
				float3 ro = position;
				float3 rd = direction;
				rd = normalize(rd);

				float3 rp = ro;
				if (pow(dot(rd, ro - float3(0, 0, 0)), 2.0) - pow(length(ro - float3(0, 0, 0)), 2.0) + 1.0 > 0.0)
				{
					float d = - dot(rd, (ro - float3(0, 0, 0))) - sqrt(pow(dot(rd, ro - float3(0, 0, 0)), 2.0) - pow(length(ro - float3(0, 0, 0)), 2.0) + 1.0);
					rp += rd * d;
					float t = 0.05;
					float tmp = 0;
					for(int i = 0; i < 64; i++)
					{
						rp += rd * t;
						float ds = length(rp) - 1.0;
						if(ds > 0.0) {
							if (tmp < 0)
								return fixed4(1, 0, 0, 0);
							return fixed4(tmp, tmp, tmp, tmp);
						}
						tmp = lerp(tmp, 1, fbm(rp * 1.5).x );
					}
				}
				return fixed4(0, 0, 0, 0);
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
