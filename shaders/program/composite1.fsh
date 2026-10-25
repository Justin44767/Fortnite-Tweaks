#include "/lib/common.glsl"
uniform sampler2D colortex0, colortex4, depthtex0;
in vec2 texcoord;
/* DRAWBUFFERS:04 */
void main() {
    vec3 current=texture(colortex0,texcoord).rgb;
    float depth=texture(depthtex0,texcoord).r;
    vec3 view=viewFromDepth(texcoord,depth);
    float distance=-view.z;
#if TAA == 1
    vec3 world=relativeWorld(view)+cameraPosition-previousCameraPosition;
    vec4 previousView=gbufferPreviousModelView*vec4(world,1);
    vec4 previous=gbufferPreviousProjection*previousView;
    vec2 historyUV=previous.xy/max(previous.w,1e-6)*0.5+0.5+jitter(frameCounter-1)/screenSize();
    bool valid=frameCounter>1 && previous.w>0.0 && length(cameraPosition-previousCameraPosition)<8.0;
    valid=valid && all(greaterThan(historyUV,vec2(0))) && all(lessThan(historyUV,vec2(1)));
    if(valid) {
        vec4 history=texture(colortex4,historyUV);
        float depthError=abs(history.a+previousView.z);
        valid=depthError<max(0.15,abs(previousView.z)*0.025);
        vec3 low=current,high=current;
        for(int y=-1;y<=1;y++) for(int x=-1;x<=1;x++) {
            vec3 neighbor=texture(colortex0,texcoord+vec2(x,y)/screenSize()).rgb;
            low=min(low,neighbor); high=max(high,neighbor);
        }
        vec3 clipped=clamp(history.rgb,low,high);
        float velocity=length((historyUV-texcoord)*screenSize());
        float weight=valid ? mix(0.88,0.45,sat(velocity/24.0)) : 0.0;
        if(depth>=0.99999) weight=min(weight,0.65);
        current=mix(current,clipped,weight);
    }
#endif
    gl_FragData[0]=vec4(current,1);
    gl_FragData[1]=vec4(current,min(distance,65000.0));
}
