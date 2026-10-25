#ifndef NERO_LIGHTING
#define NERO_LIGHTING
#include "/lib/atmosphere.glsl"
#include "/lib/shadows.glsl"
vec3 fresnel(float cosine,vec3 f0) { return f0+(1.0-f0)*pow(1.0-sat(cosine),5.0); }
vec3 specularBRDF(vec3 n,vec3 v,vec3 l,float roughness,vec3 f0) {
    vec3 h=safeNormalize(v+l); float nl=sat(dot(n,l)), nv=max(dot(n,v),0.001);
    float nh=sat(dot(n,h)), vh=sat(dot(v,h));
    float a=max(roughness*roughness,0.005), a2=a*a;
    float d=a2/(PI*pow(nh*nh*(a2-1.0)+1.0,2.0));
    float k=pow(roughness+1.0,2.0)/8.0;
    float g=(nl/(nl*(1.0-k)+k))*(nv/(nv*(1.0-k)+k));
    return d*g*fresnel(vh,f0)/max(4.0*nv*nl,0.001)*nl;
}
vec3 shadeSurface(vec3 albedo,vec3 n,vec3 relative,vec2 lm,float roughness,float metal,float emission,float foliage) {
    vec3 v=safeNormalize(-relative), l=lightDirection();
    // camera-relative world origin is the camera, including view bobbing translation.
    v=worldDirection(-((gbufferModelView*vec4(relative,1)).xyz));
    vec3 f0=mix(vec3(0.04),albedo,metal);
    float nl=max(dot(n,l),0.0), sky=sat(lm.y);
    vec3 ambient=mix(vec3(0.012,0.018,0.032),vec3(0.20,0.29,0.43),daylight());
    ambient*=mix(0.35,1.0,n.y*0.5+0.5)*pow(sky,2.0);
#if NERO_DIMENSION == -1
    ambient=vec3(0.17,0.028,0.009);
#elif NERO_DIMENSION == 1
    ambient=vec3(0.10,0.065,0.18);
#endif
    float torch=pow(sat(lm.x),3.0);
    vec3 block=vec3(1.35,0.60,0.18)*torch;
    vec3 visibility=shadowVisibility(relative,n)*cloudShadow(relative+cameraPosition);
    vec3 direct=sunRadiance()*visibility;
#if NERO_DIMENSION != 0
    direct=vec3(0);
#endif
    float transmission=foliage*pow(sat(dot(-n,l)),2.0)*0.55;
    vec3 result=albedo*(ambient+block+vec3(0.004)+direct*(nl+transmission)/PI)*(1.0-metal*0.85);
    result+=specularBRDF(n,v,l,roughness,f0)*direct;
    result+=albedo*emission*4.0;
    result+=albedo*lightningBoltPosition.w*sky*0.6;
    result=mix(result,max(result,albedo*0.4),nightVision);
    return max(result,vec3(0));
}
#endif
