#!/usr/bin/env python3
"""Offline checks. Does not claim to run Roblox physics, Studio or multiplayer."""
from pathlib import Path
import argparse, subprocess, tempfile, unittest, sys, xml.etree.ElementTree as E, json, re, hashlib, zipfile, math
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
import build
class PlaceTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.tree=E.parse(ROOT/'dist/NeroChaosParty.rbxlx');cls.items=list(cls.tree.iter('Item'))
  cls.names={}
  for i in cls.items:cls.names.setdefault(i.find("Properties/string[@name='Name']").text,[]).append(i)
 def test_unique_referents_and_properties(self):
  refs=[i.get('referent') for i in self.items];self.assertEqual(len(refs),len(set(refs)))
  for i in self.items:
   props=[p.get('name') for p in i.find('Properties')];self.assertEqual(len(props),len(set(props)))
 def test_all_maps_are_built_and_have_sixteen_spawns(self):
  for name in build.GAMES:
   m=next(i for i in self.names[name] if i.get('class')=='Model')
   self.assertGreaterEqual(len(list(m.iter('Item'))),22,name)
   spawns=next(i for i in m.findall('Item') if i.find("Properties/string[@name='Name']").text=='Spawns')
   self.assertEqual(len(spawns.findall('Item')),16,name)
   if name in ['Race','Heads','Doors','Duck']:self.assertTrue(any(i.find("Properties/string[@name='Name']").text=='Finish' for i in m.findall('Item')),name)
 def test_actual_scripts_embedded_without_source_drift(self):
  embedded={i.find("Properties/string[@name='Name']").text:i.find("Properties/ProtectedString[@name='Source']").text for i in self.items if i.get('class') in ['Script','LocalScript','ModuleScript']}
  # Server and client entrypoints share Main as their Studio name; compare all source strings instead.
  sources=[i.find("Properties/ProtectedString[@name='Source']").text for i in self.items if i.get('class') in ['Script','LocalScript','ModuleScript']]
  files=list((ROOT/'src').rglob('*.luau'));self.assertEqual(len(sources),len(files))
  for f in files:self.assertIn(f.read_text(),sources,str(f))
 def test_catalog_handlers_assets_and_products_resolve(self):
  catalog=(ROOT/'src/shared/Catalog.luau').read_text()
  events=(ROOT/'src/server/ChaosEvents.luau').read_text();games=(ROOT/'src/server/Minigames.luau').read_text()
  event_block=catalog.split('Catalog.Events = {')[1].split('Catalog.Products')[0]
  for id in re.findall(r'Id="([^"]+)"',event_block):self.assertIn('handlers.'+id+'=',events)
  for id in build.GAMES:self.assertIn('Games.'+id+'=',games)
  for model in re.findall(r'Model="([^"]+)"',catalog):self.assertIn(model,self.names)
  self.assertEqual(len(re.findall(r'Id="([^"]+)"',event_block)),25)
 def test_lobby_is_decorated_and_interactive(self):
  lobby=self.names['Lobby'][0]
  self.assertGreater(len(list(lobby.iter('Item'))),150)
  prompts=[i for i in lobby.iter('Item') if i.get('class')=='ProximityPrompt'];self.assertGreaterEqual(len(prompts),8)
  for name in ['LobbySpawn','WinsBoard','LevelBoard','TimeBoard','Shop','Pets','SpinWheel','AFK','VIP','Photo','Trampoline']:self.assertIn(name,self.names)
 def test_finite_positive_geometry(self):
  for i in self.items:
   if i.get('class') not in ['Part','SpawnLocation']:continue
   size=i.find("Properties/Vector3[@name='Size']")
   self.assertTrue(all(math.isfinite(float(v.text)) and float(v.text)>0 for v in size))
   cf=i.find("Properties/CoordinateFrame[@name='CFrame']")
   self.assertTrue(all(math.isfinite(float(v.text)) for v in cf))
 def test_zip_and_checksums(self):
  with zipfile.ZipFile(ROOT/'dist/NeroChaosParty-Source.zip') as z:
   self.assertIsNone(z.testzip())
   for p in (ROOT/'src').rglob('*.luau'):self.assertEqual(z.read(p.relative_to(ROOT).as_posix()),p.read_bytes())
   self.assertIn('assets/models/Maps.rbxmx',z.namelist());self.assertIn('README.md',z.namelist())
  for line in (ROOT/'dist/SHA256SUMS.txt').read_text().splitlines():
   digest,name=line.split('  ');self.assertEqual(hashlib.sha256((ROOT/'dist'/name).read_bytes()).hexdigest(),digest)
 def test_original_audio(self):
  import wave
  for name in ['Bounce','Fall','Chicken','Duck','Horn','Victory','Countdown','Explosion','LevelUp','Music']:
   with wave.open(str(ROOT/'assets/audio'/f'{name}.wav')) as w:self.assertEqual(w.getnchannels(),1);self.assertGreater(w.getnframes(),2000)

def check_api(path):
 api=json.loads(Path(path).read_text());classes={c['Name']:c for c in api['Classes']};enums={e['Name']:{i['Value'] for i in e['Items']} for e in api['Enums']}
 def props(cls):
  c=classes[cls];result=props(c['Superclass']) if c['Superclass'] in classes else {}
  result.update({m['Name']:m for m in c['Members'] if m['MemberType']=='Property'});return result
 count=0
 for item in E.parse(ROOT/'dist/NeroChaosParty.rbxlx').iter('Item'):
  cls=item.get('class');members=props(cls)
  for p in item.find('Properties'):
   name=p.get('name');assert name in members,(cls,name,'unknown property');m=members[name]
   assert m.get('Serialization',{}).get('CanLoad',True),(cls,name,'not loadable')
   if p.tag=='token' and m['ValueType']['Category']=='Enum':assert int(p.text) in enums[m['ValueType']['Name']],(cls,name,p.text)
   count+=1
 print(f'Roblox API schema: {count} serialized properties checked')

def main():
 parser=argparse.ArgumentParser();parser.add_argument('--luau',required=True);parser.add_argument('--compiler',required=True);parser.add_argument('--api-dump');args=parser.parse_args()
 files=sorted(str(p) for p in (ROOT/'src').rglob('*.luau'))
 subprocess.run([args.compiler,'--null',*files],check=True)
 subprocess.run([args.luau,'tests/rules.spec.luau'],cwd=ROOT,check=True)
 sources={"DataService":(ROOT/'src/server/DataService.luau').read_text(),"Scope":(ROOT/'src/shared/Scope.luau').read_text()}
 # Keep relative require paths in the tests directory; cleanup even after failures.
 generated=ROOT/'tests/.runtime-generated.luau'
 try:
  generated.write_text('local SOURCES={\n'+''.join(f'{k}=[====[{v}]====],\n' for k,v in sources.items())+'}\n'+(ROOT/'tests/runtime.spec.luau').read_text())
  subprocess.run([args.luau,str(generated)],cwd=ROOT,check=True)
 finally:generated.unlink(missing_ok=True)
 suite=unittest.defaultTestLoader.loadTestsFromTestCase(PlaceTests)
 result=unittest.TextTestRunner(verbosity=2).run(suite)
 if not result.wasSuccessful():raise SystemExit(1)
 if args.api_dump:check_api(args.api_dump)
 print('PASS offline checks. Roblox Studio / actual clients: NOT RUN.')
if __name__=='__main__':main()
