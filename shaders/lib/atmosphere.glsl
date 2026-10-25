#ifndef NERO_ATMOSPHERE
#define NERO_ATMOSPHERE
#include "/lib/common.glsl"
float phaseMie(float mu,float g) { return (1.0-g*g)/(4.0*PI*pow(max(1.0+g*g-2.0*g*mu,0.02),1.5)); }
vec3 atmosphere(vec3 ray) {
#if NERO_DIMENSION == -1
    return mix(vec3(0.065,0.008,0.003),vec3(0.34,0.055,0.012),exp(-abs(ray.y)*4.0));
#elif NERO_DIMENSION == 1
    float nebula=pow(fbm(ray*5.0+vec3(0,0,frameTimeCounter*0.003)),3.0);
    float stars=pow(hash13(floor(ray*750.0)),1300.0);
    return vec3(0.012,0.009,0.035)+nebula*vec3(0.23,0.065,0.38)+stars*vec3(0.5,0.7,1.0);
#else
    vec3 sun=sunDirection();
    float day=daylight(), mu=dot(ray,sun), horizon=exp(-max(ray.y,0.0)*4.0);
    float sunset=1.0-smoothstep(0.03,0.35,abs(sun.y));
    vec3 rayleigh=vec3(0.18,0.42,0.86)*(0.65+0.35*mu*mu);
    vec3 daySky=mix(rayleigh,vec3(0.60,0.72,0.84),horizon*0.65);
    daySky=mix(daySky,vec3(0.95,0.26,0.07),horizon*sunset*sat(mu*0.5+0.5)*0.82);
    daySky+=vec3(1.0,0.65,0.32)*min(phaseMie(mu,0.78)*0.19,2.0)*(1.0-sunset*0.3);
    vec3 result=mix(vec3(0.003,0.007,0.019)*(1.0+horizon),daySky,day);
    result+=vec3(10,8,5)*smoothstep(0.99975,0.99991,mu)*day*(1.0-rainStrength);
    float moon=dot(ray,worldDirection(moonPosition));
    result+=vec3(0.6,0.72,0.95)*smoothstep(0.99965,0.99988,moon)*(1.0-day);
    float stars=pow(hash13(floor(ray*950.0)),1700.0)*smoothstep(0.0,0.25,ray.y);
    result+=stars*(1.0-day)*(1.0-rainStrength)*vec3(0.4,0.5,0.75);
    result=mix(result,vec3(luminance(result)*0.65),rainStrength*0.8);
    return max(result,vec3(0.001));
#endif
}
float cloudDensity(vec3 p) {
    float base=CLOUD_HEIGHT-rainStrength*22.0;
    float height=(p.y-base)/64.0;
    float shape=smoothstep(0.0,0.18,height)*(1.0-smoothstep(0.65,1.0,height));
    vec3 moving=p*vec3(0.006,0.011,0.006)+vec3(frameTimeCounter*0.007*CLOUD_SPEED,0,frameTimeCounter*0.002*CLOUD_SPEED);
    float coverage=CLOUD_DENSITY+rainStrength*0.22;
    return sat((fbm(moving)-(1.0-coverage))*3.2)*shape;
}
float cloudShadow(vec3 world) {
#if CLOUD_SHADOWS == 1 && NERO_DIMENSION == 0
    vec3 light=lightDirection();
    if (light.y<0.03) return 1.0;
    float t=(CLOUD_HEIGHT+28.0-world.y)/light.y;
    if (t<=0.0) return 1.0;
    float density=cloudDensity(world+light*t);
    return exp(-density*1.4);
#else
    return 1.0;
#endif
}
vec3 renderClouds(vec3 ray,vec3 background,float maxDistance) {
#if NERO_DIMENSION == 0
    if (abs(ray.y)<0.003) return background;
    float base=CLOUD_HEIGHT-rainStrength*22.0;
    float a=(base-cameraPosition.y)/ray.y, b=(base+64.0-cameraPosition.y)/ray.y;
    float begin=max(min(a,b),0.0), end=min(max(a,b),min(maxDistance,2400.0));
    if (end<=begin) return background;
    float stepSize=(end-begin)/float(CLOUD_STEPS), transmittance=1.0;
    vec3 scattering=vec3(0), light=lightDirection();
    float offset=hash13(vec3(gl_FragCoord.xy,float(frameCounter%8)));
    for(int i=0;i<CLOUD_STEPS;i++) {
        vec3 p=cameraPosition+ray*(begin+(float(i)+offset)*stepSize);
        float d=cloudDensity(p);
        if(d>0.001) {
            float optical=cloudDensity(p+light*18.0)*1.2+cloudDensity(p+light*40.0)*0.8;
            vec3 lighting=atmosphere(vec3(0,1,0))*0.35+sunRadiance()*exp(-optical)*(0.17+phaseMie(dot(ray,light),0.65)*0.8);
            float alpha=1.0-exp(-d*stepSize*0.065);
            scattering+=transmittance*alpha*lighting;
            transmittance*=1.0-alpha;
            if(transmittance<0.025) break;
        }
    }
    return background*transmittance+scattering;
#else
    return background;
#endif
}
#endif
