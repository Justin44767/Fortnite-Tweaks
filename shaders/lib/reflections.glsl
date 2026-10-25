#ifndef NERO_REFLECTIONS
#define NERO_REFLECTIONS
#include "/lib/atmosphere.glsl"
uniform sampler2D depthtex1, colortex3;
vec3 projectView(vec3 p) {
    vec4 q=gbufferProjection*vec4(p,1);
    return vec3(q.xy/q.w*0.5+0.5+jitter(frameCounter)/screenSize(),q.z/q.w*0.5+0.5);
}
vec4 traceReflection(vec3 origin,vec3 direction,float roughness) {
#if SSR == 1
    float previousT=0.15;
    for(int i=0;i<REFLECTION_STEPS;i++) {
        float f=(float(i)+1.0)/float(REFLECTION_STEPS);
        float t=0.15+f*f*REFLECTION_DISTANCE;
        vec3 p=origin+direction*t;
        if(p.z>=-near) break;
        vec3 projected=projectView(p);
        if(any(lessThan(projected.xy,vec2(0.002)))||any(greaterThan(projected.xy,vec2(0.998)))) break;
        float d=texture(depthtex1,projected.xy).r;
        float sceneZ=viewFromDepth(projected.xy,d).z;
        float delta=sceneZ-p.z;
        if(d<0.99999 && delta>0.0 && delta<max(0.3,t*0.06)) {
            float low=previousT, high=t;
            for(int k=0;k<4;k++) {
                float mid=(low+high)*0.5;
                vec3 candidate=origin+direction*mid;
                vec3 uv=projectView(candidate);
                float z=viewFromDepth(uv.xy,texture(depthtex1,uv.xy).r).z;
                if(candidate.z<z) high=mid; else low=mid;
            }
            vec2 hit=projectView(origin+direction*high).xy;
            vec2 border=min(hit,1.0-hit);
            float confidence=smoothstep(0.0,0.08,min(border.x,border.y))*(1.0-f*0.4);
            vec2 blur=vec2(roughness*roughness*6.0)/screenSize();
            vec3 reflected=texture(colortex3,hit).rgb*0.4;
            reflected+=(texture(colortex3,hit+vec2(blur.x,0)).rgb+texture(colortex3,hit-vec2(blur.x,0)).rgb+texture(colortex3,hit+vec2(0,blur.y)).rgb+texture(colortex3,hit-vec2(0,blur.y)).rgb)*0.15;
            return vec4(reflected,confidence);
        }
        previousT=t;
    }
#endif
    return vec4(0);
}
vec3 reflectedScene(vec3 view,vec3 worldNormal,float roughness) {
    vec3 n=safeNormalize(mat3(gbufferModelView)*worldNormal), ray=reflect(safeNormalize(view),n);
    vec3 fallback=atmosphere(worldDirection(ray));
    fallback=mix(fallback,vec3(0.015),smoothstep(0.0,0.7,-worldDirection(ray).y));
    vec4 hit=traceReflection(view+n*0.12,ray,roughness);
    return mix(fallback,hit.rgb,hit.a);
}
#endif
