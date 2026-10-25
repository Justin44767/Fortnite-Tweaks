#include "/lib/common.glsl"
#include "/lib/water.glsl"
in vec4 mc_Entity;
in vec2 mc_midTexCoord;
out vec2 texcoord;
out vec4 vertexColor;
flat out float material;
void main() {
    texcoord=(gl_TextureMatrix[0]*gl_MultiTexCoord0).xy;
    vertexColor=gl_Color; material=mc_Entity.x;
    vec4 lightView=gl_ModelViewMatrix*gl_Vertex;
    vec3 relative=(shadowModelViewInverse*lightView).xyz;
    vec3 world=relative+cameraPosition;
    relative+=windOffset(world,material,step(texcoord.y,mc_midTexCoord.y));
    vec3 normal=safeNormalize(mat3(shadowModelViewInverse)*gl_NormalMatrix*gl_Normal);
    if(material>99.5 && material<100.5 && abs(normal.y)>0.5) relative.y+=waveHeight(world.xz);
    vec4 p=gl_ProjectionMatrix*shadowModelView*vec4(relative,1);
    p.xyz=distortShadow(p.xyz/p.w)*p.w;
    gl_Position=p;
}
