#ifndef NERO_COMMON
#define NERO_COMMON
#include "/lib/options.glsl"
const float PI = 3.14159265359;
uniform float viewWidth, viewHeight, frameTimeCounter, frameTime, rainStrength, wetness;
uniform float near, far, blindness, nightVision, temperature;
uniform int frameCounter, isEyeInWater;
uniform ivec2 eyeBrightnessSmooth;
uniform vec3 cameraPosition, previousCameraPosition, sunPosition, moonPosition, shadowLightPosition;
uniform vec3 fogColor, skyColor;
uniform vec4 lightningBoltPosition;
uniform mat4 gbufferModelView, gbufferModelViewInverse, gbufferProjection, gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView, gbufferPreviousProjection;
uniform mat4 shadowModelView, shadowModelViewInverse, shadowProjection;
float sat(float x) { return clamp(x, 0.0, 1.0); }
vec3 safeNormalize(vec3 x) { return x * inversesqrt(max(dot(x,x), 1e-12)); }
float luminance(vec3 c) { return dot(c, vec3(0.2126,0.7152,0.0722)); }
float hash13(vec3 p) { p=fract(p*0.1031); p+=dot(p,p.yzx+33.33); return fract((p.x+p.y)*p.z); }
float noise3(vec3 p) {
    vec3 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(mix(hash13(i),hash13(i+vec3(1,0,0)),f.x),mix(hash13(i+vec3(0,1,0)),hash13(i+vec3(1,1,0)),f.x),f.y),
               mix(mix(hash13(i+vec3(0,0,1)),hash13(i+vec3(1,0,1)),f.x),mix(hash13(i+vec3(0,1,1)),hash13(i+vec3(1,1,1)),f.x),f.y),f.z);
}
float fbm(vec3 p) { return noise3(p)*0.55+noise3(p*2.03)*0.27+noise3(p*4.11)*0.13+noise3(p*8.2)*0.05; }
vec2 screenSize() { return max(vec2(viewWidth,viewHeight),vec2(1)); }
vec2 jitter(int frame) {
#if TAA == 1
    const vec2 sequence[8]=vec2[8](vec2(0,-0.166667),vec2(-0.25,0.166667),vec2(0.25,-0.388889),vec2(-0.375,-0.055556),vec2(0.125,0.277778),vec2(-0.125,-0.277778),vec2(0.375,0.055556),vec2(-0.4375,0.388889));
    return sequence[(frame%8+8)%8];
#else
    return vec2(0);
#endif
}
vec3 viewFromDepth(vec2 uv,float depth) {
    vec4 p=gbufferProjectionInverse*vec4((uv-jitter(frameCounter)/screenSize())*2.0-1.0,depth*2.0-1.0,1);
    return p.xyz/max(abs(p.w),1e-6)*sign(p.w);
}
vec3 relativeWorld(vec3 view) { return (gbufferModelViewInverse*vec4(view,1)).xyz; }
vec3 worldDirection(vec3 view) { return safeNormalize(mat3(gbufferModelViewInverse)*view); }
vec3 lightDirection() { return worldDirection(shadowLightPosition); }
vec3 sunDirection() { return worldDirection(sunPosition); }
float daylight() { return smoothstep(-0.10,0.12,sunDirection().y); }
vec3 sunRadiance() {
    float elevation=abs(lightDirection().y);
    vec3 day=mix(vec3(2.8,0.85,0.25),vec3(3.6,3.35,2.95),smoothstep(0.02,0.35,elevation));
    return mix(vec3(0.075,0.105,0.17),day,daylight())*(1.0-rainStrength*0.72);
}
vec3 windOffset(vec3 world,float material,float upper) {
#if WIND == 1
    if (material>100.5 && material<102.5) {
        float weight=material<101.5 ? 0.055 : 0.12*upper;
        return vec3(sin(world.x*0.7+world.z*0.45+frameTimeCounter*1.6),0,sin(world.z*0.6+frameTimeCounter*1.2))*weight;
    }
#endif
    return vec3(0);
}
vec3 distortShadow(vec3 clip) { float d=0.15+length(clip.xy)*0.85; return vec3(clip.xy/d,clip.z*0.2); }
vec3 toLinear(vec3 c) { return pow(max(c,vec3(0)),vec3(2.2)); }
#endif
