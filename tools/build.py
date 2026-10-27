#!/usr/bin/env python3
"""Deterministic Roblox XML place/model builder. Python 3.11+, no Studio dependency."""
from pathlib import Path
import math, json, zipfile, hashlib, wave, struct, random
import xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parents[1]
COLORS=[(255,91,129),(62,216,224),(255,210,80),(155,112,255),(103,231,151),(255,153,79)]
GAMES=['Lava','Bananas','Button','Duck','Ice','Disasters','Music','Race','Potato','Heads','Color','TNT','Flying','Sumo','Doors']
serial=0

def item(cls,name,parent=None,**props):
 global serial
 serial+=1
 n=E.Element('Item',{'class':cls,'referent':f'RBX{serial}'})
 E.SubElement(n,'Properties')
 prop(n,'Name',name)
 for k,v in props.items(): prop(n,k,v)
 if parent is not None: parent.append(n)
 return n

def typed(kind,value): return (kind,value)
def prop(n,name,value):
 p=n.find('Properties')
 for old in list(p):
  if old.get('name')==name:p.remove(old)
 if isinstance(value,tuple) and len(value)==2 and isinstance(value[0],str): kind,value=value
 elif isinstance(value,bool):kind='bool'
 elif isinstance(value,str):kind='string'
 elif isinstance(value,int):kind='int'
 else:kind='float'
 t=E.SubElement(p,kind,{'name':name})
 if kind in ('Vector3','Color3'):
  for k,v in zip(('X','Y','Z') if kind=='Vector3' else ('R','G','B'),value): E.SubElement(t,k).text=str(v)
 elif kind=='CoordinateFrame':
  for k,v in zip(('X','Y','Z','R00','R01','R02','R10','R11','R12','R20','R21','R22'),value):E.SubElement(t,k).text=str(v)
 elif kind=='Content':E.SubElement(t,'url').text=value
 elif kind in ('UDim2',):
  for k,v in zip(('XS','XO','YS','YO'),value):E.SubElement(t,k).text=str(v)
 else:t.text=str(value).lower() if kind=='bool' else str(value)
 return t

def vec(v):return typed('Vector3',v)
def rgb(c):return typed('Color3',tuple(x/255 for x in c))
def cf(pos,angle=0):
 c,s=math.cos(angle),math.sin(angle)
 return typed('CoordinateFrame',(*pos,c,0,s,0,1,0,-s,0,c))
def part(parent,name,pos,size,color=(100,110,140),shape=1,material=272,collide=True,alpha=0,angle=0,cls='Part'):
 return item(cls,name,parent,Anchored=True,CanCollide=collide,CanTouch=True,CanQuery=True,Size=vec(size),CFrame=cf(pos,angle),Color=rgb(color),Material=typed('token',material),Transparency=float(alpha),Shape=typed('token',shape)) if cls=='Part' else item(cls,name,parent,Anchored=True,CanCollide=collide,Size=vec(size),CFrame=cf(pos,angle),Color=rgb(color),Material=typed('token',material),Transparency=float(alpha))
def label(p,text,width=260,height=70):
 g=item('BillboardGui','Sign',p,Size=typed('UDim2',(0,width,0,height)),StudsOffset=vec((0,3,0)),AlwaysOnTop=False,MaxDistance=180.0)
 item('TextLabel','Text',g,Size=typed('UDim2',(1,0,1,0)),BackgroundTransparency=1.0,Text=text,TextScaled=True,TextColor3=rgb((255,255,255)),TextStrokeTransparency=.5,Font=typed('token',19))
def prompt(p,action,caption):item('ProximityPrompt','Prompt',p,ActionText=action,ObjectText=caption,HoldDuration=0.0,MaxActivationDistance=14.0,RequiresLineOfSight=False)
def marker(parent,name,pos):
 p=part(parent,name,pos,(2,1,2),collide=False,alpha=1)
 prop(p,'CanQuery',False);prop(p,'CanTouch',False);return p
def floor(m,size=100,color=(65,72,112)):return part(m,'Floor',(0,0,400),(size,2,size),color)
def spawns(m,positions=None):
 f=item('Folder','Spawns',m)
 if positions is None:positions=[((i%4-1.5)*6,5,400+(i//4-1.5)*6) for i in range(16)]
 for i,p in enumerate(positions):marker(f,str(i+1),p)
def finish(m,pos,size=(25,8,3)):
 p=part(m,'Finish',pos,size,(105,255,160),material=288,collide=False,alpha=.35);label(p,'ZIEL',160,45)
def platform(m,name,pos,size,color=None):return part(m,name,pos,size,color or COLORS[len(m)%6])
def build_lobby():
 m=item('Model','Lobby')
 part(m,'PartyIsland',(0,-3,0),(250,6,240),(55,63,100))
 part(m,'Plaza',(0,.1,0),(110,1,110),(92,104,143))
 for i in range(8):
  a=i*math.pi/4
  part(m,'NeonPath',(math.cos(a)*62,.7,math.sin(a)*62),(4,.25,58),COLORS[i%6],material=288,angle=-a+math.pi/2)
 spawn=part(m,'LobbySpawn',(0,2,24),(18,1,18),(80,230,210),cls='SpawnLocation');prop(spawn,'Duration',0);prop(spawn,'Neutral',True)
 stage=part(m,'Stage',(0,3,-63),(65,6,30),(100,80,170));label(stage,'NERO CHAOS PARTY\nRUN. FALL. LAUGH. REPEAT.',540,110)
 for x in [-36,36]:
  part(m,'Speaker',(x,9,-65),(9,18,9),(25,30,48))
  for y in [5,13]:part(m,'SpeakerCone',(x,y,-59.8),(6,6,1),(120,110,180),shape=0)
 for i in range(15):part(m,'DanceTile',((i%5-2)*10,6.2,-67+(i//5)*8),(9,.3,7),COLORS[i%6],material=288)
 part(m,'FountainBasin',(0,2,-6),(25,4,25),(90,180,220),shape=0)
 part(m,'Water',(0,4,-6),(23,1,23),(70,225,255),shape=0,material=1568,alpha=.35)
 part(m,'FountainJet',(0,10,-6),(2,12,2),(120,240,255),material=288,collide=False)
 for i in range(10):
  a=i*math.pi/5
  part(m,'Droplet',(math.cos(a)*6,10+math.sin(i)*2,-6+math.sin(a)*6),(1.2,1.2,1.2),(160,245,255),shape=0,collide=False)
 buildings=[('Shop',(-76,0,-36),'CHAOS SHOP',(255,115,150)),('Pets',(76,0,-36),'PET CLUB',(100,215,230)),('Rewards',(-76,0,35),'DAILY + SPIN',(255,200,80)),('Profile',(76,0,35),'HALL OF CHAOS',(170,130,255))]
 for name,(x,y,z),title,col in buildings:
  part(m,'ShopBase',(x,1,z),(36,2,34),col)
  for dx in [-17,17]:part(m,'Column',(x+dx,12,z-12),(3,24,3),col)
  part(m,'BackWall',(x,11,z-16),(36,22,2),col)
  part(m,'Roof',(x,25,z),(40,4,38),col)
  counter=part(m,name,(x,4,z+7),(24,7,4),col);label(counter,title);prompt(counter,'Öffnen',title)
 for i in range(8):
  a=i*math.pi/4
  part(m,'WheelSegment',(-76+math.cos(a)*8,14+math.sin(a)*8,25),(5,5,1),COLORS[i%6],collide=False)
 spin=part(m,'SpinWheel',(-76,14,26),(5,5,2),(255,240,200),shape=0);prompt(spin,'Täglich drehen','Glücksrad');label(spin,'1× TÄGLICH · KOSTENLOS',230,42)
 for x in [-108,108]:
  p=part(m,'Trampoline',(x,2,55),(18,2,18),(255,120,195));label(p,'BOING!',130,36)
 for i in range(12):part(m,'SlideStep',(-110+i*1.7,2+i*2,-40),(8,2,8),COLORS[i%6])
 slide=part(m,'Slide',(-72,13,-82),(50,2,12),(255,210,80))
 # Rotate slide around Z: descend toward +X.
 a=-.45;c,s=math.cos(a),math.sin(a)
 prop(slide,'CFrame',typed('CoordinateFrame',(-72,13,-82,c,-s,0,s,c,0,0,0,1)))
 afk=part(m,'AFK',(-35,1,85),(32,2,26),(120,150,240));label(afk,'AFK LOUNGE');prompt(afk,'AFK umschalten','Pause')
 vip=part(m,'VIP',(36,1,85),(32,2,26),(255,215,90));label(vip,'VIP LOUNGE');prompt(vip,'Lounge betreten','VIP / Owner')
 marker(m,'VipSpawn',(36,6,85))
 photo=part(m,'Photo',(0,9,106),(40,18,2),(160,90,220));label(photo,'NERO · PARTY CREW',350,60);prompt(photo,'Pose & Kamera','Fotowand')
 for x in [-21,21]:part(m,'PhotoLight',(x,10,104),(2,20,2),(90,240,240),material=288)
 for i,(name,text) in enumerate([('WinsBoard','MOST WINS'),('LevelBoard','HIGHEST LEVEL'),('TimeBoard','MOST PLAYTIME')]):
  p=part(m,name,(-37+i*37,10,-99),(30,18,2),(35,40,70));label(p,text+'\nLade Rangliste …',240,150)
 for i in range(18):
  a=i*math.pi/9;x,z=math.cos(a)*116,math.sin(a)*106
  part(m,'PalmTrunk',(x,8,z),(2,16,2),(155,105,70))
  for j in range(3):part(m,'PalmLeaf',(x,17,z),(19,1,4),(80,205,150),angle=j*math.pi/3)
  part(m,'Lantern',(x,19,z),(2,2,2),COLORS[i%6],shape=0,material=288)
 return m

def build_map(id):
 m=item('Model',id)
 if id in ['Race','Heads','Duck','Doors']:
  spawns(m,[((i%4-1.5)*5,5,316+(i//4)*4) for i in range(16)])
  part(m,'Start',(0,0,324),(40,2,30),(95,115,180))
  if id=='Duck':
   part(m,'Floor',(0,0,420),(80,2,190),(255,207,95))
   for i in range(6):part(m,'MazeWall',((-1 if i%2 else 1)*18,7,350+i*24),(52,14,3),COLORS[i%6])
   finish(m,(0,5,511));marker(m,'ChaserStart',(0,5,320))
  elif id=='Doors':
   part(m,'Floor',(0,0,420),(70,2,190),(95,80,145))
   doors=item('Folder','Doors',m)
   for row in range(4):
    z=355+row*40
    for col in range(3):
     x=(col-1)*22
     p=part(doors,f'Door_{row+1}_{col+1}',(x,6,z),(14,12,2),COLORS[(row+col)%6],collide=False,alpha=.15);label(p,str(col+1),80,35)
     for dx in [-9,9]:part(m,'DoorFrame',(x+dx,7,z),(4,14,3),(38,34,65))
    for x in [-36,36]:part(m,'SideWall',(x,7,420),(2,14,190),(55,45,85))
   finish(m,(0,5,508))
  else:
   for i in range(9):
    z=350+i*18;x=math.sin(i*1.8)*(8 if id=='Race' else 5)
    platform(m,'Moving' if i in [3,6] else 'Platform',(x,0 if id=='Heads' else i%3,z),(18 if id=='Race' else 10,2,13))
    if i in [1,4,7]:part(m,'Spinner',(x,4,z),(25,1.5,2),(255,85,140),material=288)
    if i in [2,5]:part(m,'Spring',(x,2,z),(8,1,8),(105,245,185),material=288)
    if i==8:finish(m,(x,6,z),(20,9,3))
 elif id in ['Color','Music','TNT']:
  tiles=item('Folder','Tiles',m)
  for x in range(9):
   for z in range(9):
    col=(x*3+z)%6
    part(tiles,f'Tile_{x}_{z}_{col+1}',((x-4)*10,0,400+(z-4)*10),(9.7,2,9.7),COLORS[col])
  spawns(m)
 elif id=='Lava':
  floor(m,100)
  for level in range(12):
   a=level*.9
   platform(m,'Platform',(math.cos(a)*28,3+level*3.6,400+math.sin(a)*28),(16,2,16))
  for i in range(8):platform(m,'Platform',((i%4-1.5)*16,3,400+(i//4-.5)*32),(13,2,13))
  part(m,'Lava',(0,-3,400),(104,2,104),(255,85,40),material=288,collide=False)
  spawns(m)
 elif id=='Flying':
  floor(m,110,(115,100,190));spawns(m)
  rings=item('Folder','Rings',m)
  for i in range(10):
   x=math.sin(i*2.4)*42;z=400+math.cos(i*2.4)*42;y=12+(i%3)*7
   ring=item('Model',f'Ring{i+1}',rings)
   marker(ring,'Center',(x,y,z))
   for j in range(12):
    a=j*math.pi/6
    part(ring,'Ring',(x+math.cos(a)*5,y+math.sin(a)*5,z),(2,2,1),(255,220,80),material=288,collide=False)
 elif id=='Sumo':
  # A cylinder's axis is X; rotate around Z to make a horizontal disc.
  p=part(m,'Floor',(0,0,400),(2,70,70),(165,110,240),shape=2)
  prop(p,'CFrame',typed('CoordinateFrame',(0,0,400,0,-1,0,1,0,0,0,0,1)));spawns(m)
 else:
  floor(m,90,(165,225,250) if id=='Ice' else (70,85,135));spawns(m)
  if id=='Button':
   p=part(m,'ChaosButton',(0,3,400),(12,4,12),(255,65,90),shape=0,material=288);prompt(p,'DRÜCKEN','Bloß nicht drücken!')
  if id=='Disasters':
   for x in [-28,28]:
    for z in [372,428]:
     for step in range(5):platform(m,'Shelter',(x+(step-2)*3,step*3,z),(8,2,13))
  if id=='Potato':
   for x in [-25,25]:part(m,'Bumper',(x,3,400),(7,6,25),(255,170,90),shape=0)
 # Distinct arenas sit on decorated floating islands; trim is non-colliding so it cannot rescue eliminated players.
 theme=COLORS[GAMES.index(id)%len(COLORS)]
 if id not in ['Race','Heads','Duck','Doors']:
  part(m,'IslandUnderside',(0,-6,400),(84,8,84),(37,43,75),collide=False)
 for x,z in [(-59,341),(59,341),(-59,459),(59,459)]:
  part(m,'ArenaPillar',(x,10,z),(3,22,3),theme,collide=False)
  part(m,'ArenaBeacon',(x,23,z),(5,5,5),theme,shape=0,material=288,collide=False)
 banner=part(m,'ArenaBanner',(0,24,335),(42,3,1),theme,collide=False)
 label(banner,id.upper()+'  /  NERO',300,50)
 # Kill floor is intentionally absent: server handles bounds / falls and rescues lobby characters.
 return m

def build_model(name):
 m=item('Model',name);yellow=(255,220,60);white=(245,245,235)
 def p(n,pos,size,col,shape=1):return part(m,n,pos,size,col,shape=shape,collide=False)
 if name in ['Duck','Chicken','Dragon','Cat','Dino','Robot','Ghost']:
  c={'Duck':yellow,'Chicken':white,'Dragon':(170,115,255),'Cat':(255,130,200),'Dino':(110,220,140),'Robot':(100,205,220),'Ghost':(205,240,255)}[name]
  p('Body',(0,0,0),(2.6,2.7,2.3),c,0 if name!='Robot' else 1)
  p('Head',(0,1.5,-.3),(2,1.7,1.8),c,0)
  for x in [-.45,.45]:p('Eye',(x,1.7,-1.15),(.25,.35,.22),(25,28,45),0)
  if name in ['Duck','Chicken']:p('Beak',(0,1.3,-1.5),(1.2,.35,.9),(255,155,55))
  if name=='Chicken':p('Comb',(0,2.5,-.2),(.4,.7,1),(255,80,100))
  if name in ['Cat','Dragon','Dino']:
   for x in [-.8,.8]:p('Ear',(x,2.3,-.2),(.5,.8,.6),c)
   p('Tail',(0,-.3,1.8),(.6,.6,2),c)
  if name in ['Dragon','Chicken','Duck']:
   for x in [-1.6,1.6]:p('Wing',(x,.4,.2),(.6,1.2,2),c)
  if name=='Robot':p('Antenna',(0,2.8,0),(.3,1,.3),yellow)
 elif name=='Banana':
  for i in range(5):p('Peel',((i-2)*.55,((i-2)**2)*.2,0),(.9,1.1,1),yellow,0)
 elif name in ['Ball','Donut']:
  for i in range(12):
   a=i*math.pi/6;p('Segment',(math.cos(a)*1.3,math.sin(a)*1.3,0),(.9,.9,.9),COLORS[i%6],0)
  if name=='Ball':p('Core',(0,0,0),(2.5,2.5,2.5),(100,220,255),0)
 elif name=='Crown':
  p('Band',(0,0,0),(2.8,.5,2.4),yellow)
  for x in [-1,0,1]:p('Point',(x,.7,-1),(.6,1.2,.6),yellow)
 elif name=='Wings':
  for side in [-1,1]:
   for i in range(4):p('Feather',(side*(1+i*.5),.5-i*.25,.4),(.7,2.3-i*.2,.3),white)
 elif name=='Hammer':p('Handle',(0,0,0),(.4,3,.4),(160,110,70));p('Head',(0,1.4,0),(3,1.5,1.5),(190,120,255))
 elif name in ['Blaster','Cannon','Horn','Rocket','Boot']:
  p('Body',(0,0,0),(1,1,2.5),(100,210,235));p('Tip',(0,0,-1.5),(1.3,1.3,.6),(255,150,190),0)
  if name=='Rocket':p('Fin',(0,-.8,.7),(2,.3,1),yellow)
  if name=='Boot':p('Sole',(0,-.8,0),(1.3,.4,3),yellow)
  else:p('Grip',(0,-1,.5),(.6,1.5,.6),(150,110,225))
 return m

def xml(roots,path):
 doc=E.Element('roblox',{'version':'4'})
 E.SubElement(doc,'External').text='null';E.SubElement(doc,'External').text='nil'
 for r in roots:doc.append(r)
 E.indent(doc,space='  ')
 path.parent.mkdir(parents=True,exist_ok=True)
 E.ElementTree(doc).write(path,encoding='utf-8',xml_declaration=True)

def scripts(parent,path):
 for f in sorted(path.iterdir()):
  if f.is_dir():scripts(item('Folder',f.name,parent),f)
  elif f.suffix=='.luau':
   cls='LocalScript' if f.name.endswith('.client.luau') else 'Script' if f.name.endswith('.server.luau') else 'ModuleScript'
   name=f.name.removesuffix('.luau').removesuffix('.client').removesuffix('.server')
   item(cls,name,parent,Source=typed('ProtectedString',f.read_text()))

def audio():
 rng=random.Random(42);sr=22050
 # Original synthetic sounds, no third-party samples. Uploaded asset IDs go into Config.Audio.
 tones={'Bounce':(350,.3),'Fall':(480,.6),'Chicken':(800,.35),'Duck':(280,.4),'Horn':(440,.7),'Victory':(523,1.2),'Countdown':(880,.15),'Explosion':(65,.65),'LevelUp':(660,.8),'Music':(262,8)}
 for name,(freq,duration) in tones.items():
  frames=[]
  for i in range(int(sr*duration)):
   t=i/sr;env=min(1,t/.015)*max(0,1-t/duration)**1.3
   f=freq*(1.5-t/duration if name=='Fall' else 1+t/duration*.8 if name in ['Bounce','LevelUp'] else 1)
   if name in ['Victory','Music']: f*= [1,1.25,1.5,2][int(t*4)%4]
   v=math.sin(2*math.pi*f*t)*.2+math.sin(4*math.pi*f*t)*.05
   if name in ['Duck','Chicken']:v*=.6+.4*math.sin(t*70)
   if name=='Explosion':v=rng.uniform(-.35,.35)*(1-t/duration)
   frames.append(struct.pack('<h',int(v*env*32767)))
  with wave.open(str(ROOT/'assets/audio'/f'{name}.wav'),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(sr);w.writeframes(b''.join(frames))

def build():
 workspace=item('Workspace','Workspace',Gravity=196.2,StreamingEnabled=False,FallenPartsDestroyHeight=-100.0)
 lobby=build_lobby();workspace.append(lobby)
 ss=item('ServerStorage','ServerStorage');maps=item('Folder','Maps',ss)
 for id in GAMES:maps.append(build_map(id))
 rs=item('ReplicatedStorage','ReplicatedStorage');shared=item('Folder','Shared',rs);scripts(shared,ROOT/'src/shared')
 assets=item('Folder','Assets',rs)
 for name in ['Duck','Chicken','Dragon','Cat','Dino','Robot','Ghost','Banana','Ball','Donut','Crown','Wings','Hammer','Blaster','Cannon','Horn','Rocket','Boot']:assets.append(build_model(name))
 server=item('ServerScriptService','ServerScriptService');scripts(server,ROOT/'src/server')
 starter=item('StarterPlayer','StarterPlayer',CharacterWalkSpeed=16.0,CharacterJumpPower=50.0)
 clients=item('StarterPlayerScripts','StarterPlayerScripts',starter);scripts(clients,ROOT/'src/client')
 gui=item('StarterGui','StarterGui');screen=item('ScreenGui','Loading',gui,ResetOnSpawn=False)
 item('TextLabel','LoadingLabel',screen,Size=typed('UDim2',(1,0,1,0)),BackgroundColor3=rgb((21,24,45)),Text='NERO CHAOS PARTY\nParty wird vorbereitet …',TextColor3=rgb((255,255,255)),TextSize=32.0,Font=typed('token',19))
 light=item('Lighting','Lighting',Brightness=2.5,ClockTime=14.0,GlobalShadows=True,Ambient=rgb((120,115,145)),OutdoorAmbient=rgb((150,150,170)))
 item('Atmosphere','PartyAtmosphere',light,Density=.18,Offset=.1,Color=rgb((205,225,255)),Decay=rgb((160,165,200)),Glare=.1,Haze=.8)
 sound=item('SoundService','SoundService',RespectFilteringEnabled=True)
 roots=[workspace,ss,rs,server,starter,gui,light,sound]
 xml(roots,ROOT/'dist/NeroChaosParty.rbxlx')
 xml([lobby],ROOT/'assets/models/Lobby.rbxmx');xml([maps],ROOT/'assets/models/Maps.rbxmx');xml([assets],ROOT/'assets/models/Assets.rbxmx')
 audio()
 # Browsers display raw .rbxlx as text. This ZIP downloads as a binary attachment.
 with zipfile.ZipFile(ROOT/'dist/NeroChaosParty-Download.zip','w',compression=zipfile.ZIP_DEFLATED) as z:
  for name,data in [
   ('NeroChaosParty.rbxlx',(ROOT/'dist/NeroChaosParty.rbxlx').read_bytes()),
   ('START-HIER.txt',('NERO CHAOS PARTY\n\n1. ZIP entpacken (Windows: Rechtsklick > Alle extrahieren).\n'
    '2. Roblox Studio starten.\n3. File > Open from File waehlen.\n'
    '4. Die entpackte NeroChaosParty.rbxlx auswaehlen.\n5. Play druecken.\n\n'
    'Studio-Mehrspielertests stehen noch aus. Im Studio werden Daten standardmaessig nur fuer die Sitzung gespeichert.\n').encode('utf-8'))]:
   info=zipfile.ZipInfo(name,date_time=(2026,10,27,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED;z.writestr(info,data)
 with zipfile.ZipFile(ROOT/'dist/NeroChaosParty-Source.zip','w',compression=zipfile.ZIP_DEFLATED) as z:
  for folder in ['src','assets','docs','tools','tests']:
   for f in sorted((ROOT/folder).rglob('*')):
    if f.is_file() and '__pycache__' not in str(f):
     info=zipfile.ZipInfo(f.relative_to(ROOT).as_posix(),date_time=(2026,10,27,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED
     z.writestr(info,f.read_bytes())
  for f in [ROOT/'README.md',ROOT/'default.project.json',ROOT/'LICENSE']:
   if f.exists():
    info=zipfile.ZipInfo(f.name,date_time=(2026,10,27,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED;z.writestr(info,f.read_bytes())
 manifest={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted((ROOT/'dist').glob('*')) if p.suffix in ['.zip','.rbxlx']}
 (ROOT/'dist/SHA256SUMS.txt').write_text(''.join(f'{v}  {k}\n' for k,v in manifest.items()))
 print(json.dumps(manifest,indent=2))
if __name__=='__main__':build()
