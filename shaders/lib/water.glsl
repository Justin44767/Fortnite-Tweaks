#ifndef NERO_WATER
#define NERO_WATER
#include "/lib/common.glsl"
float waveHeight(vec2 p) {
    float t=frameTimeCounter;
    return WATER_WAVES*(sin(dot(p,vec2(0.72,0.28))+t*1.1)*0.07+sin(dot(p,vec2(-0.48,1.15))-t*1.4)*0.035+sin(dot(p,vec2(2.1,1.7))+t*2.0)*0.012);
}
vec3 waterNormal(vec3 world,vec3 geometric) {
    float e=0.08, h=waveHeight(world.xz);
    vec2 gradient=vec2(waveHeight(world.xz+vec2(e,0))-h,waveHeight(world.xz+vec2(0,e))-h)/e;
    return safeNormalize(geometric+vec3(-gradient.x,0,-gradient.y));
}
float caustics(vec3 world) {
    vec2 p=world.xz*1.7+vec2(frameTimeCounter*0.32,-frameTimeCounter*0.25);
    float cell=abs(sin(p.x+sin(p.y))*sin(p.y-sin(p.x*0.8)));
    return pow(1.0-cell,12.0);
}
#endif
