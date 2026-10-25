#include "/lib/common.glsl"
#include "/lib/water.glsl"
in vec4 mc_Entity;
in vec2 mc_midTexCoord;
out vec2 texcoord, lightcoord;
out vec4 vertexColor;
out vec3 worldNormal, relativePosition;
flat out float material;
void main() {
    texcoord=(gl_TextureMatrix[0]*gl_MultiTexCoord0).xy;
    lightcoord=(gl_TextureMatrix[1]*gl_MultiTexCoord1).xy;
    vertexColor=gl_Color;
    vec4 view=gl_ModelViewMatrix*gl_Vertex;
    relativePosition=(gbufferModelViewInverse*view).xyz;
    worldNormal=safeNormalize(mat3(gbufferModelViewInverse)*gl_NormalMatrix*gl_Normal);
    material=0.0;
#ifdef TERRAIN
    material=mc_Entity.x;
    vec3 absolute=relativePosition+cameraPosition;
    relativePosition+=windOffset(absolute,material,step(texcoord.y,mc_midTexCoord.y));
    if(material>99.5 && material<100.5 && abs(worldNormal.y)>0.5) relativePosition.y+=waveHeight(absolute.xz);
    view=gbufferModelView*vec4(relativePosition,1);
#endif
    gl_Position=gl_ProjectionMatrix*view;
    gl_Position.xy+=jitter(frameCounter)*2.0/screenSize()*gl_Position.w;
}
