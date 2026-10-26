#include "/lib/common.glsl"
uniform sampler2D colortex0, colortex6;
in vec2 texcoord;
const bool colortex0MipmapEnabled=true;
/* DRAWBUFFERS:6 */
void main() {
    float average=luminance(textureLod(colortex0,vec2(0.5),floor(log2(max(viewWidth,viewHeight)))).rgb);
    float target=clamp(0.22/max(average,0.02),0.35,3.0);
    float previous=texture(colortex6,vec2(0.5)).r;
    float exposure=target;
    if(frameCounter>1 && previous>=0.35 && previous<=3.0) exposure=mix(previous,target,1.0-exp(-max(frameTime,0.001)*1.5));
    gl_FragData[0]=vec4(exposure,0,0,1);
}
