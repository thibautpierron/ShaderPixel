Shader "PixelShader/MengerSponge"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color ("Color", Color) = (0.5, 0.5, 0.5, 1)
		_Specular ("Specular", float) = 1.0
		_Gloss ("Gloss", float) = 1.0
		_Offset ("Offset", vector) = (0.0, 0.0, 0.0)
		_Light ("Light", vector) = (0.0, 0.0, 0.0)
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

			float MengerSponge(float3 p){				
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
				}

				float3 d = abs(p) - float3(1, 1, 1);
				float dis = min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));

				return 	dis *= pow(3.0, float(-4));
			}

			float map (float3 p) {
				float3 pt = p;
				p.x += - _Offset.x;
				p.y += - _Offset.y;
				p.z += - _Offset.z;
				return MengerSponge(p);
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

			fixed4 renderSurface(float3 p) {
				float3 n = normal(p);
				float occ = calcAO(p, n);
				return simpleLambert(n) * occ;
			}

			fixed4 raymarch(float3 position, float3 direction)
			{
				for (int i = 0; i < 64; i++)
				{
					float distance = map(position);
					if (distance < 0.0005) {
						float s = softshadow(position, _Light, 0.02, 2.5);
						fixed4 c = renderSurface(position) * s;
						c.a = 1;
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
