#include "/lib/atmosphere.glsl"
uniform sampler2D colortex0, colortex1, colortex2, depthtex0;
in vec2 texcoord;
/* DRAWBUFFERS:07 */
void main() {
    float depth=texture(depthtex0,texcoord).r;
    vec3 view=viewFromDepth(texcoord,depth), ray=worldDirection(view);
    vec3 color=texture(colortex0,texcoord).rgb;
    if(depth>=0.99999) {
        color=renderClouds(ray,atmosphere(ray),2400.0);
    } else {
        vec3 n=safeNormalize(mat3(gbufferModelView)*(texture(colortex1,texcoord).xyz*2.0-1.0));
        float occlusion=0.0;
        vec3 indirect=vec3(0), albedo=texture(colortex2,texcoord).rgb;
        float radius=clamp(1.2/max(-view.z,0.1),0.002,0.10);
        float angle=hash13(vec3(gl_FragCoord.xy,0))*2.0*PI;
        for(int i=0;i<AO_SAMPLES;i++) {
            float a=float(i)*2.399963+angle;
            vec2 uv=texcoord+vec2(cos(a)*viewHeight/viewWidth,sin(a))*radius*sqrt((float(i)+0.5)/float(AO_SAMPLES));
            if(any(lessThan(uv,vec2(0)))||any(greaterThan(uv,vec2(1)))) continue;
            float d=texture(depthtex0,uv).r;
            if(d>=0.99999) continue;
            vec3 p=viewFromDepth(uv,d), delta=p-view;
            float distanceSquared=dot(delta,delta);
            vec3 direction=safeNormalize(delta);
            float cosReceiver=max(dot(n,direction)-0.08,0.0);
            float falloff=1.0-smoothstep(0.2,3.5,sqrt(distanceSquared));
            occlusion+=cosReceiver*falloff;
#if SSGI == 1
            vec3 sourceNormal=safeNormalize(mat3(gbufferModelView)*(texture(colortex1,uv).xyz*2.0-1.0));
            float geometry=cosReceiver*max(dot(sourceNormal,-direction),0.0)/(1.0+distanceSquared);
            indirect+=min(texture(colortex0,uv).rgb,vec3(4))*geometry;
#endif
        }
        color*=1.0-clamp(occlusion/float(AO_SAMPLES)*AO_STRENGTH*2.5,0.0,0.75);
        color+=indirect*albedo*SSGI_STRENGTH/float(AO_SAMPLES);
        // Finite distances also allow clouds to occlude distant mountains.
        color=renderClouds(ray,color,length(view));
    }
    gl_FragData[0]=vec4(color,1);
    // colortex7 is readable by gbuffers_water; colortex0..3 are fullscreen-only in Iris.
    gl_FragData[1]=vec4(color,1);
}
