#ifndef NERO_SHADOWS
#define NERO_SHADOWS
#include "/lib/common.glsl"
uniform sampler2D shadowtex0, shadowtex1, shadowcolor0;
const int shadowMapResolution = 2048; // [512 1024 2048 4096]
const float shadowDistance = 128.0; // [48.0 80.0 128.0 192.0 256.0]
const float sunPathRotation = -25.0;
const bool shadowHardwareFiltering = false;
vec3 shadowCoordinates(vec3 relative) {
    vec4 p=shadowProjection*shadowModelView*vec4(relative,1);
    return distortShadow(p.xyz/p.w)*0.5+0.5;
}
vec3 shadowTap(vec3 coord,float bias) {
    if(any(lessThan(coord,vec3(0.001)))||any(greaterThan(coord,vec3(0.999)))) return vec3(1);
    float opaque=step(coord.z-bias,texture(shadowtex1,coord.xy).r);
    float allDepth=step(coord.z-bias,texture(shadowtex0,coord.xy).r);
    vec4 tint=texture(shadowcolor0,coord.xy);
    return opaque*mix(toLinear(tint.rgb)*(1.0-tint.a),vec3(1),allDepth);
}
vec3 shadowVisibility(vec3 relative,vec3 normal) {
#if NERO_DIMENSION != 0
    return vec3(1);
#else
    vec3 coord=shadowCoordinates(relative+normal*0.035);
    float slope=1.0-sat(dot(normal,lightDirection()));
    float bias=(0.00009+slope*0.0003)*(2048.0/float(shadowMapResolution));
    float angle=hash13(floor(relative*4.0))*2.0*PI;
    vec3 visibility=vec3(0);
    for(int i=0;i<SHADOW_SAMPLES;i++) {
        float a=float(i)*2.399963+angle;
        float r=sqrt((float(i)+0.5)/float(SHADOW_SAMPLES))*SHADOW_SOFTNESS/float(shadowMapResolution);
        visibility+=shadowTap(coord+vec3(cos(a)*r,sin(a)*r,0),bias);
    }
    float edge=smoothstep(shadowDistance*0.75,shadowDistance,length(relative.xz));
    return mix(visibility/float(SHADOW_SAMPLES),vec3(1),edge);
#endif
}
#endif
