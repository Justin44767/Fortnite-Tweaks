uniform sampler2D gtexture;
in vec2 texcoord;
in vec4 vertexColor;
flat in float material;
/* DRAWBUFFERS:0 */
void main() {
    vec4 c=texture(gtexture,texcoord)*vertexColor;
    if(c.a<0.1) discard;
    if(material>99.5 && material<100.5) c=vec4(0.55,0.8,0.9,0.18);
    gl_FragData[0]=c;
}
