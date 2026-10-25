#include "/lib/lighting.glsl"
#include "/lib/reflections.glsl"
#include "/lib/water.glsl"
uniform sampler2D gtexture, normals, specular;
uniform vec4 entityColor;
in vec2 texcoord, lightcoord;
in vec4 vertexColor;
in vec3 worldNormal, relativePosition;
flat in float material;
#if defined(WEATHER) || defined(OVERLAY)
/* DRAWBUFFERS:0 */
#else
/* DRAWBUFFERS:012 */
#endif
/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGBA16F;
const int colortex2Format = RGBA8;
const int colortex3Format = RGBA16F;
const int colortex4Format = RGBA16F;
const int colortex5Format = RGBA16F;
const int colortex6Format = RGBA16F;
*/
const vec4 colortex1ClearColor=vec4(0.5,1.0,0.5,1.0);
// Iris's directive parser requires four literals; GLSL's scalar shorthand crashes it.
const vec4 colortex2ClearColor=vec4(0.0,0.0,0.0,0.0);
const bool colortex4Clear=false;
const bool colortex6Clear=false;
const float ambientOcclusionLevel=1.0;
void main() {
#ifdef BASIC
    vec4 sampleColor=vec4(1);
#else
    vec4 sampleColor=texture(gtexture,texcoord);
#endif
    float alpha=sampleColor.a;
#ifndef TERRAIN
    alpha*=vertexColor.a;
#endif
    if(alpha<0.1) discard;
    vec3 albedo=toLinear(sampleColor.rgb*vertexColor.rgb);
#ifdef ENTITY
    albedo=mix(albedo,toLinear(entityColor.rgb),entityColor.a);
#endif
    vec3 n=safeNormalize(worldNormal);
    if(!gl_FrontFacing) n=-n;
    float rough=0.8, metal=0.0, emission=0.0;
    float foliage=float(material>100.5 && material<102.5);
    if(material>105.5 && material<106.5) { metal=1.0; rough=0.28; }
    if(material>102.5 && material<104.5) emission=1.0;
#if PBR == 1
#ifndef BASIC
    vec4 normalMap=texture(normals,texcoord), specMap=texture(specular,texcoord);
    vec3 dp1=dFdx(relativePosition), dp2=dFdy(relativePosition);
    vec2 du1=dFdx(texcoord), du2=dFdy(texcoord);
    float determinant=du1.x*du2.y-du1.y*du2.x;
    vec3 tangent=(dp1*du2.y-dp2*du1.y)*sign(determinant);
    vec3 bitangent=(-dp1*du2.x+dp2*du1.x)*sign(determinant);
    if(dot(tangent,tangent)>1e-9 && dot(bitangent,bitangent)>1e-9 && normalMap.b>0.0) {
        vec2 xy=normalMap.xy*2.0-1.0;
        vec3 mapped=vec3(xy,sqrt(max(1.0-dot(xy,xy),0.001)));
        n=safeNormalize(mat3(safeNormalize(tangent),safeNormalize(bitangent),n)*mapped);
    }
    if(specMap.r+specMap.g+specMap.b>0.001) {
        rough=max(pow(1.0-specMap.r,2.0),0.035);
        metal=step(229.5/255.0,specMap.g);
    }
    if(specMap.a<0.999) emission=max(emission,specMap.a);
#endif
#endif
    vec3 world=relativePosition+cameraPosition;
#if NERO_DIMENSION == 0
    float rainWet=wetness*pow(sat(lightcoord.y),5.0)*sat(n.y);
    rough=mix(rough,0.10,rainWet*0.85);
    albedo*=1.0-rainWet*0.22;
#endif
    vec3 view=(gbufferModelView*vec4(relativePosition,1)).xyz;
    vec3 lit=shadeSurface(albedo,n,relativePosition,lightcoord,rough,metal,emission,foliage);
#ifdef EMISSIVE
    lit+=albedo*2.0;
#endif
    float tag=metal>0.5 ? 0.8 : (foliage>0.5 ? 0.4 : 0.0);
#ifdef TRANSLUCENT
    if(material>99.5 && material<100.5) {
        n=waterNormal(world,n); rough=0.045; tag=1.0;
        vec2 uv=gl_FragCoord.xy/screenSize();
        vec3 viewNormal=mat3(gbufferModelView)*n;
        vec2 refractUV=clamp(uv+viewNormal.xy*0.025,vec2(0.001),vec2(0.999));
        vec3 behind=viewFromDepth(refractUV,texture(depthtex1,refractUV).r);
        if(behind.z>view.z) { refractUV=uv; behind=viewFromDepth(uv,texture(depthtex1,uv).r); }
        float thickness=min(length(behind-view),40.0);
        vec3 absorption=exp(-vec3(0.28,0.075,0.035)*thickness/max(WATER_CLARITY,0.1));
        vec3 transmitted=texture(colortex3,refractUV).rgb*absorption;
        transmitted+=vec3(0.015,0.11,0.15)*(1.0-absorption)*mix(0.12,1.0,daylight());
        transmitted*=1.0+caustics(world)*exp(-thickness*0.12)*0.14*daylight();
        vec3 reflection=reflectedScene(view,n,rough);
        float f=fresnel(abs(dot(n,worldDirection(-view))),vec3(0.02)).r;
        lit=mix(transmitted,reflection,f);
        lit+=specularBRDF(n,worldDirection(-view),lightDirection(),rough,vec3(0.02))*sunRadiance()*shadowVisibility(relativePosition,n);
        alpha=1.0;
    }
#endif
#ifdef WEATHER
    lit=mix(vec3(0.25,0.32,0.42),vec3(0.75,0.82,0.95),daylight())*sampleColor.rgb;
#endif
    if(isEyeInWater==1) lit+=albedo*caustics(world)*sat(n.y)*0.18*pow(sat(lightcoord.y),3.0);
    gl_FragData[0]=vec4(lit,alpha);
    gl_FragData[1]=vec4(n*0.5+0.5,rough);
    gl_FragData[2]=vec4(albedo,tag);
}
