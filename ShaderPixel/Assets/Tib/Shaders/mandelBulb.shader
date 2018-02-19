// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/tuto"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Centre ("Center", float) = 0.0
		_Radius ("Radius", float) = 0.5
		_Color ("Color", Color) = (0.5, 0.5, 0.5, 1)
		_Specular ("Specular", float) = 1.0
		_Gloss ("Gloss", float) = 1.0
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

			float map (float3 p) {
				// return max(
				// 	sdf_sphere(p, - float3(1.5, 0, 0), 2),
				// 	sdf_sphere(p, + float3(1.5, 0, 0), 2)
				// );

				return sdf_box(p, float3(0, 0, 0), float3(1, 1, 1));
			}

			float3 sphereNormal(float3 p) {
				const float eps = 0.01;
				
				return normalize( float3(
							map(p + float3(eps, 0, 0) ) - map(p - float3(eps, 0, 0)),
							map(p + float3(0, eps, 0) ) - map(p - float3(0, eps, 0)),
							map(p + float3(0, 0, eps) ) - map(p - float3(0, 0, eps))
						)
					);
			}

			fixed4 renderSurface(float3 p) {
				float3 n = sphereNormal(p);
				return simpleLambert(n);
			}

			fixed4 raymarch(float3 position, float3 direction)
			{
				for (int i = 0; i < 32; i++)
				{
					float distance = map(position);
					if (distance < 0.01)
						return renderSurface(position);
					position += distance * direction;
				}
				return fixed4(1,1,1,0.5);
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
