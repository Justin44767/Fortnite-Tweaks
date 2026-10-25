#include "/lib/common.glsl"
uniform sampler2D colortex0;
in vec2 texcoord;
/* DRAWBUFFERS:5 */
void main() {
    vec3 bloom=vec3(0); float weights=0.0;
#if BLOOM == 1
    for(int i=-8;i<=8;i++) {
        float weight=exp(-float(i*i)/24.0);
        vec3 c=texture(colortex0,texcoord+vec2(float(i)*2.0/viewWidth,0)).rgb;
        c*=max(luminance(c)-1.0,0.0)/max(luminance(c),0.001);
        bloom+=c*weight; weights+=weight;
    }
#endif
    gl_FragData[0]=vec4(bloom/max(weights,1.0),1);
}
