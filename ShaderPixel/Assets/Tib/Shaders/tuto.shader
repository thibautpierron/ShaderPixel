// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/tuto"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Centre ("Center", float) = 0.0
		_Radius ("Radius", float) = 0.5
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
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

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
			
			v2f vert (appdata v)
			{
				v2f o;
				// o.vertex = UnityObjectToClipPos(v.vertex);
				// o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}

			float sphereDistance (float3 p) {
				return distance(p, _Centre) - _Radius;
			}

			fixed4 raymarch(float3 position, float3 direction)
			{
				for (int i = 0; i < 32; i++)
				{
					float distance = sphereDistance(position);
					if (distance < 0.01)
						return fixed4(i / (float) 32, i / (float) 32, i / (float) 32, 1);
					position += distance * direction;
				}
				return fixed4(1,1,1,0);
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// // sample the texture
				// fixed4 col = tex2D(_MainTex, i.uv);

				float3 worldPosition = i.wPos;
				float3 viewDirection = normalize(i.wPos - _WorldSpaceCameraPos);

				return raymarch(worldPosition, viewDirection);
			}
			ENDCG
		}
	}
}
