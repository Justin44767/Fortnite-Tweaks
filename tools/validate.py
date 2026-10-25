#!/usr/bin/env python3
"""Compile every Iris program and exercise GLSL on Mesa/EGL, without Minecraft.

This validates raw GLSL and selected rendering behavior, not Iris's runtime patcher
or a real Minecraft world. See docs/TESTING.md for the separate in-game gate.
"""
import argparse
import ctypes
import hashlib
import json
import math
import os
from pathlib import Path
import re
import struct
import sys
import zlib

os.environ.setdefault('PYOPENGL_PLATFORM', 'egl')
from OpenGL import EGL, GL
from OpenGL.EGL.EXT.platform_base import eglGetPlatformDisplayEXT

ROOT = Path(__file__).resolve().parents[1]
SHADERS = ROOT / 'shaders'
sys.path.insert(0, str(ROOT / 'tools'))
from generate_programs import programs


def expand(path, options=None, stack=()):
    path = path.resolve()
    if not path.is_relative_to(SHADERS) or path in stack:
        raise ValueError(f'Unsafe or recursive shader include: {path}')
    source = path.read_text()
    def include(match):
        name = match.group(1)
        target = SHADERS / name.lstrip('/') if name.startswith('/') else path.parent / name
        return expand(target, options, (*stack, path))
    source = re.sub(r'^\s*#include\s+"([^"]+)"\s*$', include, source, flags=re.M)
    for key, value in (options or {}).items():
        source = re.sub(r'^(#define\s+' + re.escape(key) + r')\s+[^\s/]+', lambda m: m[1]+' '+str(value), source, flags=re.M)
        source = re.sub(r'^(const\s+(?:int|float)\s+' + re.escape(key) + r'\s*=\s*)[^;]+', lambda m: m[1]+str(value), source, flags=re.M)
    return source


def profiles():
    result = {}
    for line in (SHADERS / 'shaders.properties').read_text().splitlines():
        if line.startswith('profile.'):
            name, body = line.split('=', 1)
            result[name[8:]] = dict(token.split(':', 1) for token in body.split())
    return result


class GPU:
    def __init__(self):
        self.display = eglGetPlatformDisplayEXT(0x31DD, EGL.EGL_DEFAULT_DISPLAY, None)
        major, minor = EGL.EGLint(), EGL.EGLint()
        EGL.eglInitialize(self.display, major, minor)
        EGL.eglBindAPI(EGL.EGL_OPENGL_API)
        attrs = (EGL.EGLint*7)(EGL.EGL_SURFACE_TYPE, EGL.EGL_PBUFFER_BIT, EGL.EGL_RENDERABLE_TYPE, EGL.EGL_OPENGL_BIT, EGL.EGL_RED_SIZE, 8, EGL.EGL_NONE)
        config, count = EGL.EGLConfig(), EGL.EGLint()
        EGL.eglChooseConfig(self.display, attrs, ctypes.byref(config), 1, count)
        ctxattrs = (EGL.EGLint*7)(0x3098, 3, 0x30FB, 3, 0x30FD, 2, EGL.EGL_NONE)
        self.context = EGL.eglCreateContext(self.display, config, EGL.EGL_NO_CONTEXT, ctxattrs)
        EGL.eglMakeCurrent(self.display, EGL.EGL_NO_SURFACE, EGL.EGL_NO_SURFACE, self.context)
        self.renderer = GL.glGetString(GL.GL_RENDERER).decode()
        self.version = GL.glGetString(GL.GL_VERSION).decode()
        self.width, self.height = 64, 48
        self.fbo = GL.glGenFramebuffers(1)
        self.textures = []
        self.programs = []
        self.identity = (1.,0,0,0, 0,1.,0,0, 0,0,1.,0, 0,0,0,1.)
        # OpenGL perspective, 90-degree vertical FOV, near=.1, far=200.
        a = self.height/self.width
        n, f = .1, 200.
        b, c = -(f+n)/(f-n), -2*f*n/(f-n)
        self.projection = (a,0,0,0, 0,1.,0,0, 0,0,b,-1., 0,0,c,0)
        self.projection_inverse = (1/a,0,0,0, 0,1.,0,0, 0,0,0,1/c, 0,0,-1.,b/c)

    def compile(self, vertex, fragment, label):
        shaders = []
        try:
            for kind, source in ((GL.GL_VERTEX_SHADER, vertex), (GL.GL_FRAGMENT_SHADER, fragment)):
                shader = GL.glCreateShader(kind)
                shaders.append(shader)
                GL.glShaderSource(shader, source)
                GL.glCompileShader(shader)
                if not GL.glGetShaderiv(shader, GL.GL_COMPILE_STATUS):
                    raise RuntimeError(f'{label}: {GL.glGetShaderInfoLog(shader).decode()}')
            program = GL.glCreateProgram()
            for shader in shaders:
                GL.glAttachShader(program, shader)
            GL.glLinkProgram(program)
            if not GL.glGetProgramiv(program, GL.GL_LINK_STATUS):
                message = GL.glGetProgramInfoLog(program).decode()
                GL.glDeleteProgram(program)
                raise RuntimeError(f'{label}: {message}')
            self.programs.append(program)
            return program
        finally:
            for shader in shaders:
                GL.glDeleteShader(shader)

    def program(self, name, dimension=0, options=None):
        folder = SHADERS / f'world{dimension}'
        return self.compile(expand(folder/f'{name}.vsh', options), expand(folder/f'{name}.fsh', options), f'{dimension}/{name}')

    def uniform(self, program, name, value):
        loc = GL.glGetUniformLocation(program, name)
        if loc == -1:
            return
        if isinstance(value, int): GL.glUniform1i(loc, value)
        elif isinstance(value, float): GL.glUniform1f(loc, value)
        elif len(value) == 16: GL.glUniformMatrix4fv(loc, 1, False, (ctypes.c_float*16)(*value))
        elif name == 'eyeBrightnessSmooth': GL.glUniform2i(loc, *value)
        else: getattr(GL, f'glUniform{len(value)}f')(loc, *value)

    def texture(self, color=(0.,0.,0.,1.), width=None, height=None, pixels=None):
        w,h = width or self.width, height or self.height
        data = list(pixels) if pixels is not None else list(color)*(w*h)
        tex = GL.glGenTextures(1)
        self.textures.append(tex)
        GL.glBindTexture(GL.GL_TEXTURE_2D, tex)
        GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR)
        GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_LINEAR)
        GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_WRAP_S, GL.GL_CLAMP_TO_EDGE)
        GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_WRAP_T, GL.GL_CLAMP_TO_EDGE)
        GL.glTexImage2D(GL.GL_TEXTURE_2D, 0, GL.GL_RGBA32F, w, h, 0, GL.GL_RGBA, GL.GL_FLOAT, (ctypes.c_float*len(data))(*data))
        return tex

    def defaults(self, program, overrides=None):
        values = dict(viewWidth=float(self.width),viewHeight=float(self.height),frameTimeCounter=3.,frameTime=1/60.,near=.1,far=200.,frameCounter=0,isEyeInWater=0,rainStrength=0.,wetness=0.,blindness=0.,nightVision=0.,temperature=.8,eyeBrightnessSmooth=(0,240),cameraPosition=(0.,65.,0.),previousCameraPosition=(0.,65.,0.),sunPosition=(0.,0.7,-0.7),moonPosition=(0.,-0.7,0.7),shadowLightPosition=(0.,0.7,-0.7),lightningBoltPosition=(0.,0.,0.,0.),entityColor=(0.,0.,0.,0.))
        for name in ['gbufferModelView','gbufferModelViewInverse','gbufferPreviousModelView','shadowModelView','shadowModelViewInverse','shadowProjection']:
            values[name] = self.identity
        values['gbufferProjection'] = values['gbufferPreviousProjection'] = self.projection
        values['gbufferProjectionInverse'] = self.projection_inverse
        values.update(overrides or {})
        for name, value in values.items():
            self.uniform(program, name, value)

    def render(self, program, inputs=None, overrides=None, attachments=1, size=None, draw=None):
        w,h = size or (self.width,self.height)
        outputs = [self.texture(width=w,height=h) for _ in range(attachments)]
        GL.glBindFramebuffer(GL.GL_FRAMEBUFFER,self.fbo)
        for i in range(3):
            GL.glFramebufferTexture2D(GL.GL_FRAMEBUFFER,GL.GL_COLOR_ATTACHMENT0+i,GL.GL_TEXTURE_2D,outputs[i] if i<attachments else 0,0)
        GL.glDrawBuffers(attachments,[GL.GL_COLOR_ATTACHMENT0+i for i in range(attachments)])
        if GL.glCheckFramebufferStatus(GL.GL_FRAMEBUFFER)!=GL.GL_FRAMEBUFFER_COMPLETE:
            raise RuntimeError('Incomplete test framebuffer')
        GL.glViewport(0,0,w,h)
        GL.glDisable(GL.GL_BLEND)
        GL.glDisable(GL.GL_DEPTH_TEST)
        GL.glUseProgram(program)
        self.defaults(program,overrides)
        for unit,(name,tex) in enumerate((inputs or {}).items()):
            GL.glActiveTexture(GL.GL_TEXTURE0+unit)
            GL.glBindTexture(GL.GL_TEXTURE_2D,tex)
            self.uniform(program,name,unit)
        GL.glActiveTexture(GL.GL_TEXTURE0)
        GL.glMatrixMode(GL.GL_PROJECTION); GL.glLoadIdentity()
        GL.glMatrixMode(GL.GL_MODELVIEW); GL.glLoadIdentity()
        GL.glMatrixMode(GL.GL_TEXTURE); GL.glLoadIdentity()
        GL.glMatrixMode(GL.GL_MODELVIEW)
        if draw:
            draw(program)
        else:
            GL.glBegin(GL.GL_QUADS)
            for x,y,u,v in [(-1,-1,0,0),(1,-1,1,0),(1,1,1,1),(-1,1,0,1)]:
                GL.glTexCoord2f(u,v); GL.glVertex3f(x,y,0)
            GL.glEnd()
        GL.glFinish()
        GL.glReadBuffer(GL.GL_COLOR_ATTACHMENT0)
        buffer=(ctypes.c_float*(w*h*4))()
        GL.glReadPixels(0,0,w,h,GL.GL_RGBA,GL.GL_FLOAT,buffer)
        data=list(buffer)
        if not all(math.isfinite(v) for v in data): raise AssertionError('Non-finite render output')
        error=GL.glGetError()
        if error: raise RuntimeError(f'OpenGL error: {error}')
        return outputs,data

    def geometry(self, material=0):
        def draw(program):
            GL.glMatrixMode(GL.GL_PROJECTION)
            GL.glLoadMatrixf((ctypes.c_float*16)(*self.projection))
            GL.glMatrixMode(GL.GL_MODELVIEW)
            GL.glLoadIdentity()
            for name,values in [('mc_Entity',(float(material),0.,0.,0.)),('mc_midTexCoord',(.5,.5))]:
                loc=GL.glGetAttribLocation(program,name)
                if loc!=-1: getattr(GL,f'glVertexAttrib{len(values)}f')(loc,*values)
            GL.glColor4f(1.,1.,1.,1.)
            GL.glNormal3f(0.,0.,1.)
            GL.glMultiTexCoord2f(GL.GL_TEXTURE1,.5,1.)
            GL.glBegin(GL.GL_QUADS)
            for x,y,u,v in [(-4,-3,0,0),(4,-3,1,0),(4,3,1,1),(-4,3,0,1)]:
                GL.glTexCoord2f(u,v); GL.glVertex3f(x,y,-3.)
            GL.glEnd()
        return draw

    def close(self):
        for p in self.programs: GL.glDeleteProgram(p)
        if self.textures: GL.glDeleteTextures(self.textures)
        GL.glDeleteFramebuffers(1,[self.fbo])
        EGL.eglMakeCurrent(self.display,EGL.EGL_NO_SURFACE,EGL.EGL_NO_SURFACE,EGL.EGL_NO_CONTEXT)
        EGL.eglDestroyContext(self.display,self.context)
        EGL.eglTerminate(self.display)


def png(path, width, height, floats):
    def chunk(name, body):
        return struct.pack('!I',len(body))+name+body+struct.pack('!I',zlib.crc32(name+body)&0xffffffff)
    rows=[]
    for y in reversed(range(height)):
        rows.append(b'\0'+bytes(max(0,min(255,round(floats[(y*width+x)*4+k]*255))) for x in range(width) for k in range(3)))
    path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('!2I5B',width,height,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(b''.join(rows)))+chunk(b'IEND',b''))


def run(output):
    output.mkdir(parents=True,exist_ok=True)
    for path,content in programs():
        if (SHADERS/path).read_text()!=content: raise AssertionError(f'Stale generated entry point: {path}')
    gpu=GPU()
    report={'renderer':gpu.renderer,'opengl':gpu.version,'minecraft_tested':False,'compiled_programs':0,'checks':[]}
    try:
        for name,options in profiles().items():
            for path in sorted(SHADERS.glob('world*/*.vsh')):
                p=gpu.compile(expand(path,options),expand(path.with_suffix('.fsh'),options),f'{name}/{path.relative_to(SHADERS)}')
                GL.glDeleteProgram(p); gpu.programs.remove(p)
                report['compiled_programs']+=1
            print(f'PASS all programs link: {name}',flush=True)
        # Root fallback programs and optional branches not selected by default profiles.
        for path in sorted(SHADERS.glob('*.vsh')):
            p=gpu.compile(expand(path,{'MOTION_BLUR':1,'DOF':1,'TAA':0,'BLOOM':0,'AUTO_EXPOSURE':0}),expand(path.with_suffix('.fsh'),{'MOTION_BLUR':1,'DOF':1,'TAA':0,'BLOOM':0,'AUTO_EXPOSURE':0}),str(path.name))
            GL.glDeleteProgram(p); gpu.programs.remove(p)
            report['compiled_programs']+=1

        fullscreen='#version 330 compatibility\n'+expand(SHADERS/'program/fullscreen.vsh')
        def probe(name,lib,expression,inputs=None,overrides=None,dimension=0,options=None):
            fragment='#version 330 compatibility\n#define NERO_DIMENSION '+str(dimension)+'\n'+expand(SHADERS/lib,options)+'\nin vec2 texcoord;\nvoid main(){gl_FragColor='+expression+';}\n'
            program=gpu.compile(fullscreen,fragment,name)
            return gpu.render(program,inputs,overrides)[1]
        def check(name,condition):
            if not condition: raise AssertionError(name)
            report['checks'].append(name); print('PASS '+name,flush=True)
        def difference(a,b): return sum(abs(x-y) for x,y in zip(a,b))/len(a)

        sky=gpu.texture((1,1,1,1)); black=gpu.texture((0,0,0,1))
        inputs={'colortex0':black,'colortex1':gpu.texture((.5,1,.5,.8)),'colortex2':gpu.texture((.4,.3,.2,0)),'depthtex0':sky}
        deferred=gpu.program('deferred')
        day_tex,day=gpu.render(deferred,inputs,attachments=2)
        _,night=gpu.render(deferred,inputs,{'sunPosition':(0.,-.7,.7),'moonPosition':(0.,.7,-.7),'shadowLightPosition':(0.,.7,-.7)},attachments=2)
        check('day/night atmosphere changes actual rendered pixels',difference(day,night)>.03)
        _,rain=gpu.render(deferred,inputs,{'rainStrength':1.},attachments=2)
        check('weather changes cloud and atmospheric lighting',difference(day,rain)>.01)
        _,nether=gpu.render(gpu.program('deferred',-1),inputs,attachments=2)
        _,end=gpu.render(gpu.program('deferred',1),inputs,attachments=2)
        check('Nether and End produce distinct finite renders',difference(day,nether)>.03 and difference(nether,end)>.01)
        waves=probe('water normal','lib/water.glsl','vec4(waterNormal(vec3(texcoord*20.0,0).xzy,vec3(0,1,0))*0.5+0.5,1)',overrides={'frameTimeCounter':0.})
        waves2=probe('water animated normal','lib/water.glsl','vec4(waterNormal(vec3(texcoord*20.0,0).xzy,vec3(0,1,0))*0.5+0.5,1)',overrides={'frameTimeCounter':3.})
        check('water wave normals animate in world space',difference(waves,waves2)>.005)
        shadow_inputs={'shadowtex0':black,'shadowtex1':black,'shadowcolor0':gpu.texture((1.,.1,.1,.3))}
        blocked=probe('shadow blocked','lib/shadows.glsl','vec4(shadowTap(vec3(0.5),0.0001),1)',shadow_inputs)
        lit=probe('shadow clear','lib/shadows.glsl','vec4(shadowTap(vec3(0.5),0.0001),1)',{**shadow_inputs,'shadowtex0':sky,'shadowtex1':sky})
        colored=probe('shadow color','lib/shadows.glsl','vec4(shadowTap(vec3(0.5),0.0001),1)',{**shadow_inputs,'shadowtex1':sky})
        check('shadow depth occludes direct light',blocked[0]<.01 and lit[0]>.99)
        check('translucent shadow transmits its material color',colored[0]>colored[1]*5 and colored[0]<lit[0])
        cloud=probe('clouds','lib/atmosphere.glsl','vec4(renderClouds(normalize(vec3((texcoord-0.5)*2.0,1).xzy),vec3(0.1),2400.0),1)')
        cloud_clear=probe('clear','lib/atmosphere.glsl','vec4(0.1,0.1,0.1,1)')
        check('raymarched clouds alter sky radiance',difference(cloud,cloud_clear)>.005)
        # Synthetic opaque depth field with a near foreground strip and a bright source.
        depth=[]; scene=[]
        for y in range(gpu.height):
            for x in range(gpu.width):
                distance=4. if x<gpu.width//3 else 12.
                d=(200.1/199.9-0.20010005/distance)*.5+.5
                depth.extend((d,d,d,1.))
                scene.extend((8. if x>gpu.width*3//4 else .3,.2,.1,1.))
        depth_tex=gpu.texture(pixels=depth); scene_tex=gpu.texture(pixels=scene)
        ssr=probe('SSR hit','lib/reflections.glsl','traceReflection(vec3(0,0,-1),vec3(0,0,-1),0.1)',{'depthtex1':depth_tex,'colortex3':scene_tex})
        check('SSR ray march finds an opaque depth intersection',ssr[3]>.2 and ssr[0]>.1)
        ssr_miss=probe('SSR miss','lib/reflections.glsl','traceReflection(vec3(0,0,-1),vec3(0,0,1),0.1)',{'depthtex1':depth_tex,'colortex3':scene_tex})
        check('SSR rejects rays leaving the view volume',ssr_miss[3]==0.)
        material_inputs={'gtexture':gpu.texture((.5,.6,.3,1.)),'normals':gpu.texture((.5,.5,1.,1.)),'specular':gpu.texture((0.,0.,0.,1.)),'shadowtex0':sky,'shadowtex1':sky,'shadowcolor0':sky,'depthtex1':depth_tex,'colortex3':scene_tex}
        sun={'sunPosition':(0.,.7,.7),'shadowLightPosition':(0.,.7,.7)}
        terrain_program=gpu.program('gbuffers_terrain')
        _,terrain=gpu.render(terrain_program,material_inputs,sun,attachments=3,draw=gpu.geometry())
        _,terrain_shadow=gpu.render(terrain_program,{**material_inputs,'shadowtex0':black,'shadowtex1':black},sun,attachments=3,draw=gpu.geometry())
        check('geometry pass uses shadow maps in surface lighting',difference(terrain,terrain_shadow)>.005)
        _,mapped=gpu.render(terrain_program,{**material_inputs,'normals':gpu.texture((.85,.5,1.,1.)),'specular':gpu.texture((.8,.95,0.,1.))},sun,attachments=3,draw=gpu.geometry())
        check('PBR normal and specular maps change geometry shading',difference(terrain,mapped)>.01)
        water_program=gpu.program('gbuffers_water')
        _,water=gpu.render(water_program,material_inputs,{**sun,'frameTimeCounter':0.},attachments=3,draw=gpu.geometry(100))
        _,water_next=gpu.render(water_program,material_inputs,{**sun,'frameTimeCounter':2.},attachments=3,draw=gpu.geometry(100))
        check('water pass visibly refracts and animates the opaque scene',difference(water,terrain)>.05 and difference(water,water_next)>.0001)
        synthetic={**inputs,'depthtex0':depth_tex,'colortex0':scene_tex}
        opaque,_=gpu.render(deferred,synthetic,attachments=2)
        composite_inputs={**synthetic,'colortex0':opaque[0],'colortex3':opaque[1],'depthtex1':depth_tex,**{k:sky for k in ['shadowtex0','shadowtex1','shadowcolor0']}}
        composite=gpu.program('composite')
        fogged,fog=gpu.render(composite,composite_inputs)
        _,underwater=gpu.render(composite,composite_inputs,{'isEyeInWater':1})
        check('underwater absorption changes red relative to blue',difference(fog,underwater)>.02 and underwater[0]/max(underwater[2],.001)<fog[0]/max(fog[2],.001))
        temporal=gpu.program('composite1')
        temporal_inputs={'colortex0':fogged[0],'depthtex0':depth_tex,'colortex4':black}
        resolved,first=gpu.render(temporal,temporal_inputs,attachments=2)
        check('first temporal frame rejects uninitialized history',difference(first,fog)<1e-5)
        _,reset=gpu.render(temporal,{**temporal_inputs,'colortex4':gpu.texture((100.,0,0,12.))},{'frameCounter':4,'previousCameraPosition':(100.,65.,0.)},attachments=2)
        check('camera teleport rejects temporal history',difference(reset,fog)<1e-5)
        bloom,blur=gpu.render(gpu.program('composite2'),{'colortex0':scene_tex})
        check('bloom extracts bright sources',max(blur[::4])>.5 and min(blur[::4])<.01)
        GL.glBindTexture(GL.GL_TEXTURE_2D,resolved[0]); GL.glGenerateMipmap(GL.GL_TEXTURE_2D)
        exposure,exp=gpu.render(gpu.program('composite3'),{'colortex0':resolved[0],'colortex6':black},size=(1,1))
        check('auto exposure stays within documented bounds',.35-1e-5<=exp[0]<=3.+1e-5)
        _,final=gpu.render(gpu.program('final'),{'colortex0':resolved[0],'colortex5':bloom[0],'colortex6':exposure[0],'depthtex0':depth_tex})
        check('postprocessing yields bounded nonblack output',all(-1e-6<=v<=1.000001 for v in final) and max(final[::4])>.2)
        png(output/'synthetic-pipeline.png',gpu.width,gpu.height,final)
        # Metadata proves which source tree this report corresponds to.
        digest=hashlib.sha256()
        for path in sorted(SHADERS.rglob('*')):
            if path.is_file(): digest.update(str(path.relative_to(SHADERS)).encode()+b'\0'+path.read_bytes())
        report['shader_tree_sha256']=digest.hexdigest()
        report['status']='passed'
        (output/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
        print(f"PASS {report['compiled_programs']} program links; {len(report['checks'])} rendering checks; Minecraft: NOT RUN",flush=True)
    finally:
        gpu.close()


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=ROOT/'build/validation')
    args=parser.parse_args()
    run(args.output)
