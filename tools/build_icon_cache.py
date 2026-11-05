"""Extract icon references/recipes from the supplied place without executing its scripts.

Usage: python tools/build_icon_cache.py --source rbxBinaryParser_tmp/testhub_game.json
"""
from pathlib import Path
import argparse
import hashlib
import json
import re
from tree_sitter import Language, Parser
import tree_sitter_luau

ROOT = Path(__file__).resolve().parents[1]
CATEGORIES = {
    'Pets': ('pets', 'Pet'), 'Eggs': ('eggs', None), 'Potions': ('potions', 'Potion'),
    'Powerups': ('items', 'Powerup'), 'Runes': ('runes', 'Rune'),
    'Currency': ('currencies', 'Currency'), 'PermanentBuffs': ('buffs', 'PermanentBuff'),
    'Fish': ('fish', 'Fish'), 'FishingRods': ('fishing/rods', 'FishingRod'),
    'FishingBait': ('fishing/bait', 'Bait'), 'FishingBobbers': ('fishing/bobbers', 'Bobber'),
}
parser = Parser(Language(tree_sitter_luau.language()))

def key_of(node):
    value = node.text.decode('utf-8')
    if node.type == 'string':
        return value[1:-1].replace('\\"', '"').replace("\\'", "'")
    return value

def fields(node):
    return {key_of(f.named_children[0]): f.named_children[-1]
            for f in node.named_children if f.type == 'field' and len(f.named_children) >= 2}

def extract(module, source):
    tree = parser.parse(source.encode())
    assert not tree.root_node.has_error, module
    records = {}
    def walk(node):
        if node.type == 'field' and len(node.named_children) >= 2:
            name = key_of(node.named_children[0])
            value = node.named_children[-1]
            text = value.text.decode('utf-8')
            props = fields(value) if value.type == 'table_constructor' else {}
            builder = re.search(r'(PetBuilder|EggBuilder)\.new\(', text)
            is_record = builder or (value.type == 'table_constructor' and
                bool(set(props) & {'Icon', 'Image', 'Images', 'Description', 'Rarity', 'OneLevel', 'Tiers', 'Gradient', 'Buff'}))
            if is_record and name not in {'Data', 'Tiers', 'Cost', 'Normal', 'Shiny', 'Mythic', 'MythicShiny'}:
                image_ids = re.findall(r'rbxassetid://(\d+)', text)
                images = {}
                if builder:
                    image_call = re.search(r':Image\(([^)]*)\)', text)
                    values = re.findall(r'rbxassetid://\d+', image_call[1]) if image_call else []
                    keys = ['Normal', 'Shiny', 'Mythic', 'MythicShiny'] if module == 'Pets' else ['Image']
                    images = dict(zip(keys, values))
                else:
                    for key in ['Image', 'Icon']:
                        if key in props:
                            match = re.fullmatch(r'["\'](rbxassetid://\d+)["\']', props[key].text.decode())
                            if match: images['Image'] = match[1]
                kind = CATEGORIES[module][1]
                item = ({'Type': kind, 'Currency' if kind == 'Currency' else 'Name': name} if kind else None)
                if kind == 'Potion': item['Level'] = 1
                if kind == 'Rune': item['Tier'] = 1
                records[name] = {'name': name, 'images': images, 'assetIds': sorted(set(image_ids)),
                                 'item': item, 'recipe': 'egg-image-or-model' if not kind else 'native-item',
                                 'sourceModule': module}
                return
        for child in node.named_children: walk(child)
    walk(tree.root_node)
    if module == 'Runes':
        # This decompilation builds Runes through t1/t2/... table references.
        # Evaluate only literal table/field assignments; never execute game code.
        variables = {}
        def literal(node):
            if node.type == 'table_constructor': return {k: literal(v) for k,v in fields(node).items()}
            if node.type == 'identifier': return variables.get(node.text.decode())
            if node.type == 'string': return key_of(node)
            if node.type == 'number': return float(node.text)
            return None
        for node in tree.root_node.named_children:
            assignment = node.named_children[0] if node.type == 'variable_declaration' else node
            if assignment.type != 'assignment_statement': continue
            left, right = assignment.named_children[0], assignment.named_children[-1]
            if len(left.named_children)!=1 or len(right.named_children)!=1: continue
            lhs, rhs = left.named_children[0].text.decode(), right.named_children[0]
            value = literal(rhs)
            if re.fullmatch(r't\d+', lhs): variables[lhs] = value
            else:
                match = re.fullmatch(r'(t\d+)(?:\.(\w+)|\[(\d+)\])', lhs)
                if match and isinstance(variables.get(match[1]), dict): variables[match[1]][match[2] or match[3]] = value
        for name, rune in (variables.get('t1') or {}).items():
            if not isinstance(rune,dict): continue
            tiers = rune.get('Tiers') or {}
            images = {f'Tier{tier}': value['Icon'] for tier,value in tiers.items() if isinstance(value,dict) and isinstance(value.get('Icon'),str)}
            records[name] = {'name':name,'images':images,'assetIds':[x.split('://')[-1] for x in images.values()],
                             'item':{'Type':'Rune','Name':name,'Tier':1},'recipe':'native-item','sourceModule':module}
    return records

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--source', type=Path, required=True)
    args = ap.parse_args()
    data = json.loads(args.source.read_text(encoding='utf-8'))
    out = ROOT / 'icon-cache'
    out.mkdir(exist_ok=True)
    paths, summary, publish, asset_ids = {}, {}, [], set()
    for module, (folder, _) in CATEGORIES.items():
        entry = next(x for x in data if x['path'] == 'ReplicatedStorage/Shared/Data/' + module)
        records = extract(module, entry['source'])
        category = out / folder
        (category / 'records').mkdir(parents=True, exist_ok=True)
        for name, record in sorted(records.items()):
            slug = re.sub(r'[^a-z0-9]+', '-', name.lower()).strip('-')[:70] or 'unnamed'
            suffix = hashlib.sha256(name.encode()).hexdigest()[:8]
            path = category / 'records' / f'{slug}-{suffix}.json'
            path.write_text(json.dumps(record, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
            publish.append(path.relative_to(ROOT).as_posix())
            asset_ids.update(record['assetIds'])
        source_ids = sorted(set(re.findall(r'rbxassetid://(\d+)', entry['source'])))
        asset_ids.update(source_ids)
        source_assets = category / 'source-assets.json'
        source_assets.write_text(json.dumps(source_ids,indent=2)+'\n',encoding='utf-8')
        publish.append(source_assets.relative_to(ROOT).as_posix())
        payload = json.dumps({'schema': 1, 'category': module, 'entries': records}, ensure_ascii=True, separators=(',', ':')) + '\n'
        digest = hashlib.sha256(payload.encode()).hexdigest()[:20]
        path = category / f'{digest}.json'
        path.write_text(payload, encoding='utf-8', newline='\n')
        paths[module] = path.relative_to(ROOT).as_posix()
        publish.append(paths[module])
        summary[module] = {'records': len(records), 'path': paths[module]}
    recipes = out / 'recipes'
    recipes.mkdir(exist_ok=True)
    for renderer in ['PotionIcon', 'OrbIcon']:
        module_path = 'ReplicatedStorage/Shared/Utils/Stats/ItemUtil/' + renderer
        entry = next(x for x in data if x['path'] == module_path)
        ids = sorted(set(re.findall(r'rbxassetid://(\d+)', entry['source'])))
        asset_ids.update(ids)
        path = recipes / f'{renderer}.json'
        path.write_text(json.dumps({'renderer':module_path,'assetIds':ids,
            'recipe':'Use the game renderer with the cached item Name/Level or Tier; retain native gradients.'},indent=2)+'\n',encoding='utf-8')
        publish.append(path.relative_to(ROOT).as_posix())
    manifest = {'schema': 1, 'sourceSHA256': hashlib.sha256(args.source.read_bytes()).hexdigest(),
                'categories': summary, 'uniqueAssets': len(asset_ids),
                'storage': 'Roblox asset references and native rendering recipes; PNG mirrors require authorized access.'}
    for file, value in [('manifest.json', manifest), ('paths.json', paths), ('assets.json', sorted(asset_ids))]:
        path = out / file
        path.write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8', newline='\n')
        publish.append(path.relative_to(ROOT).as_posix())
    (out / 'publish-files.json').write_text(json.dumps(publish), encoding='utf-8')
    print(json.dumps({'categories': {k: v['records'] for k,v in summary.items()},
                      'records': sum(v['records'] for v in summary.values()), 'uniqueAssets': len(asset_ids), 'files': len(publish)}))

if __name__ == '__main__': main()
