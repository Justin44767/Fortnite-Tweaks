#include "/lib/common.glsl"
uniform sampler2D colortex0, colortex5, colortex6, depthtex0;
#if NERO_DIAGNOSTIC == 2
uniform sampler2D colortex1;
#endif
in vec2 texcoord;
vec3 filmic(vec3 x) { return clamp((x*(2.51*x+0.03))/(x*(2.43*x+0.59)+0.14),0.0,1.0); }
void main() {
    vec2 uv=texcoord;
    if(isEyeInWater==1) uv+=vec2(sin(uv.y*30.0+frameTimeCounter*1.8),cos(uv.x*26.0+frameTimeCounter*1.5))*0.0015;
    vec3 color=texture(colortex0,uv).rgb;
    float depth=texture(depthtex0,uv).r;
#if DOF == 1
    float focus=max(-viewFromDepth(vec2(0.5),texture(depthtex0,vec2(0.5)).r).z,0.1);
    float distance=max(-viewFromDepth(uv,depth).z,0.1);
    float coc=min(abs(1.0/distance-1.0/focus)*DOF_STRENGTH*50.0,12.0);
    vec3 sum=color; float weight=1.0;
    for(int i=0;i<12;i++) {
        float a=float(i)*2.399963;
        vec2 p=uv+vec2(cos(a),sin(a))*sqrt((float(i)+0.5)/12.0)*coc/screenSize();
        float sampleDistance=-viewFromDepth(p,texture(depthtex0,p).r).z;
        if(sampleDistance>=distance*0.85) { sum+=texture(colortex0,p).rgb; weight+=1.0; }
    }
    color=sum/weight;
#endif
#if MOTION_BLUR == 1
    vec3 world=relativeWorld(viewFromDepth(uv,depth))+cameraPosition-previousCameraPosition;
    vec4 p=gbufferPreviousProjection*gbufferPreviousModelView*vec4(world,1);
    if(frameCounter>1 && p.w>0.0 && length(cameraPosition-previousCameraPosition)<8.0) {
        vec2 velocity=clamp(uv-(p.xy/p.w*0.5+0.5),vec2(-0.025),vec2(0.025));
        vec3 sum=color;
        for(int i=1;i<6;i++) sum+=texture(colortex0,uv-velocity*(float(i)/5.0-0.5)).rgb;
        color=sum/6.0;
    }
#endif
#if DOF == 0 && MOTION_BLUR == 0
    vec2 px=1.0/screenSize();
    vec3 blurred=(texture(colortex0,uv+vec2(px.x,0)).rgb+texture(colortex0,uv-vec2(px.x,0)).rgb+texture(colortex0,uv+vec2(0,px.y)).rgb+texture(colortex0,uv-vec2(0,px.y)).rgb)*0.25;
    color=max(color+(color-blurred)*SHARPENING,vec3(0));
#endif
#if BLOOM == 1
    vec3 glow=vec3(0); float weights=0.0;
    for(int i=-8;i<=8;i++) { float w=exp(-float(i*i)/24.0); glow+=texture(colortex5,uv+vec2(0,float(i)*2.0/viewHeight)).rgb*w; weights+=w; }
    color+=glow/weights*BLOOM_STRENGTH;
#endif
    float exposure=EXPOSURE;
#if AUTO_EXPOSURE == 1
    exposure*=clamp(texture(colortex6,vec2(0.5)).r,0.35,3.0);
#endif
    color=filmic(color*exposure);
    float saturation=SATURATION,contrast=CONTRAST;
#if COLOR_PROFILE == 1
    color*=vec3(1.04,1.0,0.94); saturation*=0.88; contrast*=1.08;
#elif COLOR_PROFILE == 2
    saturation*=1.22;
#elif COLOR_PROFILE == 3
    saturation*=0.92; contrast*=0.95;
#elif COLOR_PROFILE == 4
    color*=vec3(0.86,0.91,1.04); saturation*=0.78; contrast*=1.13;
#endif
    color=mix(vec3(luminance(color)),color,saturation);
    // Compress around middle gray without adding a gray floor to black pixels.
    // Lower contrast opens shadows and lowers highlights while keeping black black.
    color=clamp(0.18*pow(max(color,vec3(0))/0.18,vec3(contrast)),0.0,1.0);
    color=pow(color,vec3(1.0/2.2));
    color+=(hash13(vec3(gl_FragCoord.xy,float(frameCounter%8)))-0.5)/255.0;
#if NERO_DIAGNOSTIC == 2
    // Inspect the geometry output directly, without exposure, bloom or TAA.
    color=texture(depthtex0,texcoord).r>=0.99999 ? vec3(0.04) : clamp(texture(colortex1,texcoord).rgb,0.0,1.0);
#endif
#if NERO_DIAGNOSTIC != 0
    // A fixed two-color frame proves this final pass is running, even over black
    // or unchanged scene buffers. It is intentionally independent of lighting.
    vec2 edge=min(texcoord,1.0-texcoord)*screenSize();
    float border=max(6.0,min(viewWidth,viewHeight)*0.015);
    if(min(edge.x,edge.y)<border) color=texcoord.x<0.5 ? vec3(0,1,1) : vec3(1,0,1);
#endif
    gl_FragColor=vec4(clamp(color,0.0,1.0),1);
}
