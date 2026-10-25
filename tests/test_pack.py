import gzip
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import re
import struct
import unittest
import zipfile

ROOT=Path(__file__).resolve().parents[1]
DIST=Path(os.environ.get('NERO_DIST_DIR',ROOT/'dist'))
spec=importlib.util.spec_from_file_location('nero_build',ROOT/'tools/build.py')
build=importlib.util.module_from_spec(spec)
spec.loader.exec_module(build)


def read_nbt(stream,kind):
    if kind in (1,3,4):
        format={1:'>b',3:'>i',4:'>q'}[kind]
        return struct.unpack(format,stream.read(struct.calcsize(format)))[0]
    if kind==8:
        size=struct.unpack('>H',stream.read(2))[0]
        return stream.read(size).decode('utf8')
    if kind==9:
        subtype=stream.read(1)[0]
        count=struct.unpack('>i',stream.read(4))[0]
        return [read_nbt(stream,subtype) for _ in range(count)]
    if kind==10:
        result={}
        while True:
            subtype=stream.read(1)[0]
            if subtype==0: return result
            name=read_nbt(stream,8)
            result[name]=read_nbt(stream,subtype)
    raise ValueError(f'Unsupported NBT type {kind}')


class PackTests(unittest.TestCase):
    def test_zip_has_direct_shader_root_and_exact_sources(self):
        with zipfile.ZipFile(DIST/'NeroRealismUltra-26.3.zip') as pack:
            self.assertIn('shaders/shaders.properties',pack.namelist())
            self.assertEqual(len(pack.namelist()),len(set(pack.namelist())))
            self.assertFalse(any('..' in Path(name).parts or name.startswith('/') for name in pack.namelist()))
            for path in (ROOT/'shaders').rglob('*'):
                if path.is_file():
                    self.assertEqual(pack.read(path.relative_to(ROOT).as_posix()),path.read_bytes(),str(path))
            self.assertIsNone(pack.testzip())

    def test_all_archives_have_matching_checksums(self):
        archives=list(DIST.glob('*.zip'))
        self.assertEqual(len(archives),3)
        for archive in archives:
            expected=archive.with_name(archive.name+'.sha256').read_text().split()[0]
            self.assertEqual(expected,hashlib.sha256(archive.read_bytes()).hexdigest())

    def test_program_pairs_in_all_dimensions(self):
        for directory in ['','world0','world-1','world1']:
            folder=ROOT/'shaders'/directory
            vertex=list(folder.glob('*.vsh'))
            self.assertGreaterEqual(len(vertex),21)
            for path in vertex:
                self.assertTrue(path.with_suffix('.fsh').is_file())
                for include in re.findall(r'#include "(/[^\"]+)"',path.read_text()):
                    self.assertTrue((ROOT/'shaders'/include.lstrip('/')).is_file())

    def test_iris_clear_colors_have_four_literal_components(self):
        # Iris reads these values outside the GLSL compiler. GLSL's vec4(scalar)
        # shorthand crashes DispatchingDirectiveHolder instead of expanding it.
        declarations=[]
        for path in (ROOT/'shaders').rglob('*'):
            if path.suffix not in ('.fsh','.glsl'): continue
            for name,value in re.findall(r'^\s*const\s+vec4\s+((?:colortex|shadowcolor)\d+ClearColor)\s*=\s*([^;]+);',path.read_text(),re.M):
                declarations.append(name)
                with self.subTest(path=path.relative_to(ROOT),directive=name):
                    constructor=re.fullmatch(r'vec4\s*\(([^()]*)\)',value.strip())
                    self.assertIsNotNone(constructor,'Iris requires a literal vec4 constructor')
                    components=constructor[1].split(',')
                    self.assertEqual(len(components),4,'Iris requires four explicit components, even for zero')
                    for component in components:
                        self.assertRegex(component.strip(),r'^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?[fF]?$',
                                         'Iris requires numeric literals, not GLSL expressions')
        self.assertTrue(declarations,'No clear-color directives were checked')

    def test_profiles_and_menus_reference_real_options(self):
        properties=(ROOT/'shaders/shaders.properties').read_text()
        source='\n'.join(p.read_text() for p in (ROOT/'shaders/lib').glob('*.glsl'))
        options=set(re.findall(r'^#define[ \t]+(\w+)[ \t]+[^\n]*//\s*\[',source,re.M))
        options.update(re.findall(r'^const\s+(?:int|float)\s+(\w+)\s*=[^\n]*//\s*\[',source,re.M))
        profiles=[line for line in properties.splitlines() if line.startswith('profile.')]
        self.assertEqual(len(profiles),5)
        for line in profiles:
            for token in line.split('=',1)[1].split(): self.assertIn(token.split(':')[0],options)
        for line in properties.splitlines():
            if re.match(r'screen\.[A-Z]+=',line):
                for option in line.split('=',1)[1].split(): self.assertIn(option,options)
        for language in ('de_DE','en_US'):
            text=(ROOT/f'shaders/lang/{language}.lang').read_text()
            for option in options: self.assertIn(f'option.{option}=',text)

    def test_testworld_has_target_version_and_registered_datapack(self):
        with zipfile.ZipFile(DIST/'Nero-Test-World-26.3.zip') as world:
            stream=io.BytesIO(gzip.decompress(world.read('Nero-Test-World/level.dat')))
            self.assertEqual(stream.read(1),b'\x0a')
            self.assertEqual(read_nbt(stream,8),'')
            data=read_nbt(stream,10)['Data']
            self.assertEqual(stream.read(),b'')
            self.assertEqual(data['DataVersion'],5023)
            self.assertEqual(data['Version']['Name'],'26.3')
            self.assertEqual(data['Version']['Id'],5023)
            self.assertEqual(data['GameType'],1)
            self.assertIn('file/Nero-Test-Scene',data['DataPacks']['Enabled'])
            self.assertEqual(set(data['WorldGenSettings']['dimensions']),{'minecraft:overworld','minecraft:the_nether','minecraft:the_end'})
            metadata=json.loads(world.read('Nero-Test-World/datapacks/Nero-Test-Scene/pack.mcmeta'))
            self.assertEqual(metadata['pack']['min_format'],[121,0])
            self.assertEqual(metadata['pack']['max_format'],[121,0])

    def test_scene_functions_resolve_and_fills_fit_default_limit(self):
        files=build.scene_files()
        for name,body in files.items():
            if not name.endswith('.mcfunction'): continue
            text=body.decode()
            for function in re.findall(r'\bfunction (nero_test:[\w]+)',text):
                self.assertIn('data/nero_test/function/'+function.split(':')[1]+'.mcfunction',files)
            for line in text.splitlines():
                if line.startswith('fill '):
                    x,y,z,a,b,c=map(int,line.split()[1:7])
                    self.assertLessEqual((abs(a-x)+1)*(abs(b-y)+1)*(abs(c-z)+1),32768,line)

    def test_build_is_byte_reproducible(self):
        before={p.name:p.read_bytes() for p in DIST.glob('*.zip')}
        build.build(DIST)
        after={p.name:p.read_bytes() for p in DIST.glob('*.zip')}
        self.assertEqual(before,after)


if __name__=='__main__': unittest.main()
