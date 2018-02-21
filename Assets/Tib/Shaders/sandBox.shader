// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/mandel"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Centre ("Center", float) = 0.0
		_Radius ("Radius", float) = 0.5
		_Color ("Color", Color) = (0.5, 0.5, 0.5, 1)
		_Specular ("Specular", float) = 1.0
		_Gloss ("Gloss", float) = 1.0
		_Offset ("Offset", vector) = (0.0, 0.0, 0.0)
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
			float _Centre;
			float _Radius;
			fixed4 _Color;
			float _Specular;
			float _Gloss;
			float _Alpha;
			float3 _Offset;
			float3 viewDirection;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}

			fixed4 simpleLambert(fixed3 normal) {
				fixed3 lightDir = _WorldSpaceLightPos0.xyz;
				fixed3 lightCol = _LightColor0.rgb;

				fixed3 NdotL = max(dot(normal, lightDir), 0);

				fixed3 h = (lightDir - viewDirection) / 2;
				fixed specular = pow( dot(normal, h), _Specular) * _Gloss;

				fixed4 c;
				c.rgb = _Color * lightCol * NdotL + specular;
				c.a = 1;
				return c;
			}

			float MengerSponge(float3 p){
				// float orbit = 1e20;
				
				for(int n=0;n < 4;n++) {
					p = abs(p);
					
					if(p.x<p.y) p.xy = p.yx;
					if(p.x<p.z) p.xz = p.zx;
					if(p.y<p.z) p.zy = p.yz;	 
					
					p.z -=  1./3.;
					p.z  = -abs(p.z);
					p.z +=  1./3.;
					
					p   *= 3.;  
					p.x -= 2.;
					p.y -= 2.;
					
					// orbit = min(orbit,length(p));
				}
				
				//distance to a cube
				float3 d = abs(p) - float3(1, 1, 1);
				float dis = min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
				
				//back to real scale
				return 	dis *= pow(3.0, float(-4));
				
				// return vec2(dis,orbit); 
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

			float intersectSDF(float a, float b) {
				return max(a, b);
			}

			float unionSDF(float a, float b) {
				return min(a, b);
			}

			float differenceSDF(float a, float b) {
				return max(a, -b);
			}

			float map (float3 p) {
				// sdf_sphere(p, - float3(1.5, 0, 0), 2),
				// float3 pt = p;
				// p.x += - _Offset.x;
				// p.y += - _Offset.y;
				// p.z += - _Offset.z;

				float a = sdf_sphere(p, + _Offset, 1.1);
				float b = sdf_box(p, _Offset, float3(1.8, 1.8, 1.8));
				// float c = sdf_plane(p, float3(0, 1, 0), 1.2);

				return differenceSDF(b, a);
				// return MengerSponge(p);
				// return unionSDF(differenceSDF(b, a), c);
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
				return clamp(res, 0.0, 1.0);
			}

			fixed4 renderSurface(float3 p) {
				float3 n = normal(p);
				return simpleLambert(n);
			}

			fixed4 raymarch(float3 position, float3 direction)
			{
				for (int i = 0; i < 64; i++)
				{
					float distance = map(position);
					if (distance < 0.0005) {
						float s = softshadow(position, _WorldSpaceLightPos0.xyz, 0.02, 2.5);
						fixed4 c = renderSurface(position) * s;
						// fixed4 c = renderSurface(position);
						c.a = _Alpha;
						return c;
					}
					position += distance * direction;
				}
				return fixed4(1,1,1,0.0);
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
