#include "/lib/lighting.glsl"
#include "/lib/reflections.glsl"
uniform sampler2D colortex0, colortex1, colortex2, depthtex0;
in vec2 texcoord;
/* DRAWBUFFERS:0 */
void main() {
    float depth=texture(depthtex0,texcoord).r;
    vec3 view=viewFromDepth(texcoord,depth), relative=relativeWorld(view);
    vec3 color=texture(colortex0,texcoord).rgb;
    float distanceToSurface=min(length(view),far);
    vec3 ray=worldDirection(view);
    if(depth<0.99999) {
        vec4 normalRough=texture(colortex1,texcoord), data=texture(colortex2,texcoord);
        vec3 n=safeNormalize(normalRough.rgb*2.0-1.0);
        float metallic=float(data.a>0.7 && data.a<0.9);
        bool water=data.a>0.95;
        if(!water && (metallic>0.5 || normalRough.a<0.45)) {
            vec3 reflected=reflectedScene(view,n,normalRough.a);
            vec3 f=fresnel(sat(dot(n,worldDirection(-view))),mix(vec3(0.04),data.rgb,metallic));
            color=mix(color,reflected,f*(1.0-normalRough.a*0.7));
        }
    }
    if(isEyeInWater==1) {
        vec3 trans=exp(-vec3(0.22,0.075,0.04)*distanceToSurface/max(WATER_CLARITY,0.1));
        color=color*trans+vec3(0.015,0.10,0.14)*(1.0-trans)*mix(0.15,1.0,daylight());
    } else if(isEyeInWater==2) {
        color=mix(color,vec3(0.65,0.12,0.015),1.0-exp(-distanceToSurface*1.4));
    } else if(isEyeInWater==3) {
        color=mix(color,vec3(0.68,0.80,0.95),1.0-exp(-distanceToSurface*0.45));
    }
    float limit=min(distanceToSurface,192.0), stepSize=limit/float(FOG_STEPS);
    vec3 scattering=vec3(0); float transmittance=1.0;
    float offset=hash13(vec3(gl_FragCoord.xy,float(frameCounter%8)));
    vec3 fogLight=atmosphere(ray)*0.28;
    for(int i=0;i<FOG_STEPS;i++) {
        float distance=(float(i)+offset)*stepSize;
        vec3 sampleRelative=ray*distance;
        float height=cameraPosition.y+sampleRelative.y;
        float lowMist=exp(-max(height-62.0,0.0)*0.035);
        float density=(0.0008+lowMist*0.004+rainStrength*0.007)*FOG_DENSITY;
#if NERO_DIMENSION == -1
        density=0.018*FOG_DENSITY; fogLight=vec3(0.28,0.035,0.008);
#elif NERO_DIMENSION == 1
        density=0.004*FOG_DENSITY; fogLight=vec3(0.075,0.035,0.15);
#endif
        if(isEyeInWater==1) density=0.018*FOG_DENSITY;
        float visibility=1.0;
#if NERO_DIMENSION == 0
        visibility=luminance(shadowTap(shadowCoordinates(sampleRelative),0.00015))*cloudShadow(sampleRelative+cameraPosition);
#endif
        float phase=phaseMie(dot(ray,lightDirection()),isEyeInWater==1 ? 0.7 : 0.55);
        vec3 lighting=fogLight;
#if NERO_DIMENSION == 0
        lighting+=sunRadiance()*phase*visibility;
#endif
        float alpha=1.0-exp(-density*stepSize);
        scattering+=transmittance*alpha*lighting;
        transmittance*=1.0-alpha;
    }
    color=color*transmittance+scattering;
    color*=1.0-sat(blindness)*smoothstep(0.0,6.0,distanceToSurface);
    gl_FragData[0]=vec4(max(color,vec3(0)),1);
}
