$input vTexCoord0

#include <forward_pipeline.sh>

uniform vec4 uCamDir;
uniform vec4 uFade;

SAMPLER2D(uBaseOpacityMap, 0);

// 'static' keeps these mutable file-scope globals out of the $Global uniform
// block on the HLSL->Metal path (glslang); without it: "can't modify a uniform".
static float material, total;

#define R uResolution
#define N(x,y,z) normalize(vec3(x,y,z))
#define ss(a,b,t) smoothstep(a,b,t)
#define repeat(p,r) (mod(p,r)-r/2.)

float remap(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

mat2 rot(float a) { return mat2(cos(a),-sin(a),sin(a),cos(a)); }

vec3 orient_ray(vec3 ray) {
	// uCamDir.x/z encode the pitch & yaw angles already processed on the CPU side.
	ray.yz = mul(ray.yz, rot(uCamDir.x));
	ray.xz = mul(ray.xz, rot(uCamDir.z));
	return ray;
}

float gyroid(vec3 p) { return dot(sin(p), cos(p.yzx)); }

const uint k = 1103515245U;

vec3 hash(uvec3 x)
{
	x = ((x>>8U)^x.yzx)*k;
	x = ((x>>8U)^x.yzx)*k;
	x = ((x>>8U)^x.yzx)*k;
	return vec3(x)*(1.0/float(0xffffffffU));
}

float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise(inout vec3 p)
{
	float result = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; ++i)
	{
		result += (gyroid(p/a)*a);
		a *= 0.5;
	}
	return result;
}

float noise2(vec3 p)
{
	float result = 0.0;
	float a = 0.5;
	for (int i = 0; i < 6; ++i)
	{
		p.z += result * 0.5;
		result += abs(gyroid(p/a)*a);
		a *= 0.5;
	}
	return result;
}

float noise3(vec3 p)
{
	float result = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; ++i)
	{
		p.y += result * 0.5 + uClock.x * 0.05;
		result += abs(gyroid(p/a)*a);
		a *= 0.5;
	}
	return result;
}

float noise4(vec3 p)
{
	float result = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; ++i)
	{
		p.y += result * 0.5;
		result += abs(gyroid(p/a)*a);
		a *= 0.5;
	}
	return result;
}

float map(vec3 p)
{
	float dist = 100.0;

	p.x += 0.7;
	p.z -= uClock.x * 0.1;

	vec3 q = p;

	p.z *= 0.5;
	dist = noise(p);

	float grid = 0.5;
	float shape = length(repeat(p,grid))-grid/1.5;
	shape = max(dist, abs(shape)-0.1);
	dist = max(dist, -abs(shape)*0.5);

	p = q*5.0;
	p.y *= 0.3;
	dist += abs(noise(p))*0.2;

	p = q*10.0;
	p.y *= 0.2;
	dist += pow(abs(noise(p)), 4.0)*0.1;

	p = q;
	p.y += cos(p.z*2.0)*0.05;
	p.zx *= 0.3;
	dist -= pow(abs(noise4(p*10.0)), 4.0)*0.03;

	p = q*10.0;
	p.z *= 2.0;
	dist -= noise2(p) * 0.05;

	dist -= 0.1;
	dist -= 0.1 * sin(q.z);

	dist -= max(0.0, p.y) * 0.02;

	float water = q.y + 1.0 + noise3(q*2.0) * 0.01;

	material = water < dist ? 1.0 : 0.0;
	dist = min(water, dist);

	return dist;
}

vec3 getNormal(vec3 pos, float e)
{
	vec2 noff = vec2(e,0.0);
	return normalize(map(pos)-vec3(map(pos-noff.xyy), map(pos-noff.yxy), map(pos-noff.yyx)));
}

vec3 getColor(vec3 pos, vec3 normal, vec3 ray, float shade)
{
	vec3 color = 0.5+0.5*cos(vec3(1,2,3)*5.9+normal.y-normal.z*0.5-0.5);
	color *= dot(normal, -normalize(pos))*0.5+0.5;
	color *= shade*shade;
	return color;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	vec3 color = vec3(0.0, 0.0, 0.0);

	vec2 p = (2.0 * fragCoord - R.xy) / R.y;
	vec3 pos = vec3(0.0, 0.0, 0.0);
	vec3 ray = normalize(vec3(p, -1.0));
	ray = orient_ray(ray); // align the ray with the external camera direction
	vec3 rng = hash(uvec3(fragCoord, 0.0));

	total = 0.0;
	float shade = 0.0;
	bool marched = false;
	for (int i = 0; i < 200; ++i)
	{
		shade = 1.0 - float(i) / 200.0;
		float dist = map(pos);
		if (dist < 0.001*total || total > 20.0)
		{
			marched = true;
			break;
		}
		dist *= 0.12 + 0.05*rng.z;
		pos += ray * dist;
		total += dist;
	}
	if (!marched)
	{
		shade = 0.0;
	}

	if (shade > 0.01)
	{
		float mat = material;
		vec3 normal = getNormal(pos, 0.003*total);

		if (mat == 0.0)
		{
			color = getColor(pos, normal, ray, shade);

			float spec = pow(max(dot(-ray, normal)*0.5+0.5, 0.0), 100.0);
			color += 0.2*spec*ss(0.5,0.0,pos.y+1.0);
		}
		else
		{
			ray = reflect(ray, normal);
			pos += ray * 0.05;
			total = 0.0;
			bool reflect_marched = false;
			for (int i = 0; i < 80; ++i)
			{
				shade = 1.0 - float(i) / 80.0;
				float dist = map(pos);
				if (dist < 0.05*total || total > 20.0)
				{
					reflect_marched = true;
					break;
				}
				dist *= 0.2;
				pos += ray * dist;
				total += dist;
			}
			if (!reflect_marched)
			{
				shade = 0.0;
			}

			color = getColor(pos, getNormal(pos, 0.001), ray, shade);
			color *= ss(1.0,0.0,pos.y+1.0);
			color *= ss(0.0,0.6,(pos.y+1.2));
		}
	}

	fragColor = vec4(color, 1.0);
}

void main()
{
	vec2 fragCoord = vTexCoord0.xy * uResolution.xy;
	vec4 fragColor;

	vec4 frameColor = vec4(1.0, 0.0, 1.0, 1.0);
    vec4 color_opacity;

// Fetch alpha blending level from the color/opacity texture
#if USE_BASE_COLOR_OPACITY_MAP
    color_opacity = texture2D(uBaseOpacityMap, vTexCoord0);
#else
    color_opacity = vec4(1.0, 0.0, 1.0, 1.0);
#endif

	mainImage(fragColor, fragCoord);

	if (vTexCoord0.y > 0.85) {
		fragColor.xyz = vec3(1.0, 1.0, 1.0);
	}

	vec4 final_color = mix(color_opacity, fragColor, clamp(remap(color_opacity.w, 0.25, 1.0, 0.0, 1.0), 0.0, 1.0));

	gl_FragColor = vec4(final_color.xyz, final_color.w * uFade.x);
}
