#!/usr/bin/env python3
"""Reproducible shaderpack, test-scene datapack and new test-world archives."""
from pathlib import Path
import argparse
import gzip
import hashlib
import json
import struct
import zipfile

ROOT=Path(__file__).resolve().parents[1]
DIST=ROOT/'dist'


def archive(path, files):
    with zipfile.ZipFile(path,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as out:
        for name,content in sorted(files.items()):
            item=zipfile.ZipInfo(name,date_time=(2026,1,1,0,0,0))
            item.compress_type=zipfile.ZIP_DEFLATED
            item.external_attr=0o100644<<16
            out.writestr(item,content)
    digest=hashlib.sha256(path.read_bytes()).hexdigest()
    path.with_name(path.name+'.sha256').write_text(f'{digest}  {path.name}\n')
    print(f'{path.name}: {path.stat().st_size} bytes, SHA256 {digest}')


def nbt_payload(kind,value):
    if kind==1: return struct.pack('>b',value)
    if kind==3: return struct.pack('>i',value)
    if kind==4: return struct.pack('>q',value)
    if kind==8:
        encoded=value.encode('utf8'); return struct.pack('>H',len(encoded))+encoded
    if kind==9:
        subtype,items=value
        return bytes([subtype])+struct.pack('>i',len(items))+b''.join(nbt_payload(subtype,item) for item in items)
    if kind==10:
        return b''.join(bytes([t])+nbt_payload(8,key)+nbt_payload(t,v) for key,(t,v) in value.items())+b'\0'
    raise ValueError(kind)


def world_level():
    def dimension(kind,biome_source,settings):
        return {'type':(8,kind),'generator':(10,{'type':(8,'minecraft:noise'),'settings':(8,settings),'biome_source':(10,biome_source)})}
    dimensions={
        'minecraft:overworld':(10,dimension('minecraft:overworld',{'type':(8,'minecraft:multi_noise'),'preset':(8,'minecraft:overworld')},'minecraft:overworld')),
        'minecraft:the_nether':(10,dimension('minecraft:the_nether',{'type':(8,'minecraft:multi_noise'),'preset':(8,'minecraft:nether')},'minecraft:nether')),
        'minecraft:the_end':(10,dimension('minecraft:the_end',{'type':(8,'minecraft:the_end')},'minecraft:end')),
    }
    data={
        'DataVersion':(3,4671),'version':(3,19133),
        'Version':(10,{'Name':(8,'1.21.11'),'Id':(3,4671),'Snapshot':(1,0),'Series':(8,'main')}),
        'LevelName':(8,'NERO REALISM ULTRA - Render Test'),
        'GameType':(3,1),'allowCommands':(1,1),'hardcore':(1,0),'Difficulty':(1,1),
        'initialized':(1,1),'SpawnX':(3,0),'SpawnY':(3,71),'SpawnZ':(3,28),
        'Time':(4,0),'DayTime':(4,6000),'LastPlayed':(4,0),
        'WorldGenSettings':(10,{'seed':(4,2026012111),'generate_features':(1,1),'bonus_chest':(1,0),'dimensions':(10,dimensions)}),
        'DataPacks':(10,{'Enabled':(9,(8,['vanilla','file/Nero-Test-Scene'])),'Disabled':(9,(8,[]))}),
    }
    raw=bytes([10])+nbt_payload(8,'')+nbt_payload(10,{'Data':(10,data)})
    return gzip.compress(raw,mtime=0)


def scene_files():
    files={
        'pack.mcmeta':json.dumps({'pack':{'description':'NERO test scene for Minecraft Java 1.21.11','min_format':[94,1],'max_format':[94,1]}},indent=2).encode(),
        'data/minecraft/tags/function/load.json':b'{"values":["nero_test:load"]}\n',
        'data/nero_test/function/load.mcfunction':b'execute unless data storage nero_test:state initialized run function nero_test:init\n',
        'data/nero_test/function/init.mcfunction':b'data modify storage nero_test:state initialized set value 1b\nforceload add -48 -48 48 48\nschedule function nero_test:build 40t replace\n',
    }
    commands=['# Only for the supplied NEW test world: replaces blocks around 0 64 0.','weather clear','time set 6000']
    # Each fill is below Minecraft's default volume limit (32768 blocks).
    for y in range(65,101,4): commands.append(f'fill -40 {y} -40 40 {y+3} 40 air')
    commands += ['fill -40 61 -40 40 63 40 stone','fill -40 64 -40 40 64 40 grass_block',
        'fill -25 64 -20 5 64 12 sand','fill -24 63 -19 4 63 11 sand',
        'fill -23 64 -18 3 64 10 water','fill -18 62 -13 -2 63 4 water',
        'fill -18 61 -13 -2 61 4 sand',
        'fill -28 65 14 18 65 17 stone_bricks',
        'fill 10 65 -8 14 69 -4 glass','fill 11 66 -7 13 68 -5 air',
        'fill 17 65 -8 19 67 -6 iron_block','fill 23 65 -8 25 67 -6 copper_block',
        'fill 29 65 -8 31 67 -6 gold_block',
        'fill 10 65 -17 15 67 -15 red_stained_glass','fill 20 65 -17 25 67 -15 blue_stained_glass',
        'fill 15 65 -34 35 70 -23 stone','fill 19 71 -33 32 76 -25 stone',
        'fill 23 77 -31 29 82 -27 stone','fill 24 83 -30 28 83 -28 snow_block',
        'fill -36 65 -35 -29 70 -28 stone','fill -35 71 -34 -30 73 -29 stone',
        'fill -6 65 20 6 65 30 smooth_stone']
    for x,z in [(-29,-14),(-30,0),(-17,16),(-7,-25),(7,-29),(19,3),(29,8)]:
        commands += [f'fill {x-2} 69 {z-2} {x+2} 71 {z+2} oak_leaves[persistent=true]',
                     f'fill {x-1} 72 {z-1} {x+1} 72 {z+1} oak_leaves[persistent=true]',
                     f'fill {x} 65 {z} {x} 70 {z} oak_log',f'setblock {x+3} 65 {z+1} short_grass']
    for x in (-25,-15,-5,5,15):
        commands += [f'setblock {x} 66 15 torch',f'setblock {x} 65 19 oak_fence',f'setblock {x} 66 19 lantern']
    commands += ['setblock 12 65 4 soul_lantern','setblock 15 65 4 sea_lantern',
                 'data modify storage nero_test:state built set value 1b',
                 'function nero_test:camera_water',
                 'tellraw @a {"text":"NERO test scene built. Use /function nero_test:camera_water or camera_forest, then compare shaders OFF/ON.","color":"aqua"}',
                 'forceload remove -48 -48 48 48']
    files['data/nero_test/function/build.mcfunction']=('\n'.join(commands)+'\n').encode()
    for name,body in {
        'camera_water':'tp @a -9 68 22 180 12',
        'camera_forest':'tp @a -32 67 12 180 -4',
        'camera_materials':'tp @a 21 67 6 180 8',
        'noon':'weather clear\ntime set 6000',
        'sunset':'weather clear\ntime set 12500',
        'night':'weather clear\ntime set 18000',
        'rain':'weather rain\ntime set 6000',
        'storm':'weather thunder\ntime set 6000',
        'nether':'execute in minecraft:the_nether run tp @s 0 90 0',
        'end':'execute in minecraft:the_end run tp @s 0 80 0',
        'overworld':'execute in minecraft:overworld run tp @s -9 68 22 180 12',
    }.items(): files[f'data/nero_test/function/{name}.mcfunction']=(body+'\n').encode()
    return files


def build(output_directory=None):
    dist=Path(output_directory) if output_directory else DIST
    dist.mkdir(parents=True,exist_ok=True)
    shaderfiles={p.relative_to(ROOT).as_posix():p.read_bytes() for p in sorted((ROOT/'shaders').rglob('*')) if p.is_file()}
    for name in ['README.md','CHANGELOG.md','docs/EFFECTS.md','docs/INSTALLATION.md','docs/TESTING.md','docs/COMPATIBILITY.md','docs/BRIEF.md']:
        shaderfiles[name]=(ROOT/name).read_bytes()
    archive(dist/'NeroRealismUltra-1.21.11.zip',shaderfiles)
    scene=scene_files()
    archive(dist/'Nero-Test-Scene-1.21.11.zip',scene)
    world={'Nero-Test-World/level.dat':world_level(), 'Nero-Test-World/README.txt':(ROOT/'docs/TESTING.md').read_bytes()}
    world.update({'Nero-Test-World/datapacks/Nero-Test-Scene/'+name:content for name,content in scene.items()})
    archive(dist/'Nero-Test-World-1.21.11.zip',world)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-directory',type=Path,default=DIST)
    build(parser.parse_args().output_directory)
