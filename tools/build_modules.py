"""Build GitHub modules while retaining the source's exact statement order.

Install build dependencies: python -m pip install tree-sitter tree-sitter-luau
Run from the project root: python tools/build_modules.py
"""
from pathlib import Path
from collections import Counter, defaultdict
import hashlib
import json
import re
from tree_sitter import Language, Parser
import tree_sitter_luau
from port_halloween_shrine import generate as port_halloween_shrine

ROOT = Path(__file__).resolve().parents[1]
port_halloween_shrine()
source_path = ROOT / 'larplite.lua'
if not source_path.exists():
    source_path = ROOT / 'src/larplite.lua'
source = source_path.read_bytes().replace(b'\r\n', b'\n')
parser = Parser(Language(tree_sitter_luau.language()))
tree = parser.parse(source)
assert not tree.root_node.has_error, 'Source has syntax errors'
tabs = {
    'scriptStateDB': 'main', 'BGSI_Lite_StatsTab': 'stats',
    'BGSI_Lite_ServerTab': 'server', 'eggTab': 'eggs',
    'halloweenTab': 'halloween', 'compTab': 'comp', 'scriptStateCZ': 'event',
    'potionTab': 'chests', 'scriptStateYT': 'potions', 'riftsTab': 'rifts',
    'gameTab': 'game', 'scriptStateTJ': 'enchant', 'scriptStateUC': 'quests',
    'BGSI_Lite_GuildTab': 'guilds', 'scriptStateOB': 'shrines',
    'scriptStateGB': 'rebirth', 'scriptStateKM': 'webhooks',
    'scriptStateAFW': 'other',
}
groups = []
declarations = []
statement_count = 0
for node in tree.root_node.named_children:
    if node.type == 'comment':
        continue
    statement_count += 1
    text = source[node.start_byte:node.end_byte].decode()
    # Only script-scope locals cross module boundaries. Inner scopes stay intact.
    if node.type == 'variable_declaration':
        statement = node.named_children[0]
        variables = statement.named_children[0] if statement.type == 'assignment_statement' else statement
        names = [source[n.start_byte:n.end_byte].decode() for n in variables.named_children]
        declarations.extend(names)
        text = re.sub(r'^local\s+', '', text, count=1)
        if statement.type != 'assignment_statement':
            text += ' = ' + ', '.join('nil' for _ in names)
    elif node.type == 'function_declaration' and text.startswith('local function '):
        declarations.append(node.child_by_field_name('name').text.decode())
        text = text.removeprefix('local ')
    owners = {v for k, v in tabs.items() if re.search(r'\b' + k + r'\b', text)}
    if 'BGSI_Lite_FleetInit = function' in text:
        owner = 'leader'
    elif 'local fishingTab = scriptStateOG:AddTab' in text:
        owner = 'fishing'
    elif 'activeStates.BGSI_Lite_ReleaseHistory = {' in text:
        owner = 'changelog'
    elif len(owners) == 1:
        owner = owners.pop()
    else:
        owner = 'core'
    if groups and groups[-1]['owner'] == owner:
        groups[-1]['code'].append(text)
    else:
        groups.append({'owner': owner, 'code': [text]})

duplicates = [key for key, count in Counter(declarations).items() if count > 1]
assert not duplicates, f'Shadowed script locals need explicit handling: {duplicates}'
blocks = defaultdict(list)
steps = []
for group in groups:
    name = group['owner']
    blocks[name].append('\n'.join(group['code']))
    steps.append([name, len(blocks[name])])

out = ROOT / 'modular_dist'
out.mkdir(exist_ok=True)
files = []
modules = {}
for name, fragments in blocks.items():
    content = '-- Generated from larplite.lua; rebuild with tools/build_modules.py.\nreturn {\n'
    content += ',\n'.join('function(...)\n' + code + '\nend' for code in fragments)
    content += '\n}\n'
    parsed = parser.parse(content.encode())
    assert not parsed.root_node.has_error, f'Invalid generated module: {name}'
    digest = hashlib.sha256(content.encode()).hexdigest()[:20]
    path = f'modules/{name}/{digest}.lua'
    target = out / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding='utf-8', newline='\n')
    modules[name] = {'path': path, 'bytes': len(content.encode()), 'blocks': len(fragments)}
    files.append(path)

version = re.search(r'BGSI_Lite_ScriptVersion\s*=\s*"([^"]+)"', source.decode())[1]
manifest = {'version': version, 'modules': modules, 'steps': steps,
            'locals': declarations, 'statements': statement_count}
manifest_text = json.dumps(manifest, indent=2) + '\n'
(out / 'modules-manifest.json').write_text(manifest_text, encoding='utf-8', newline='\n')
template = (ROOT / 'tools/loader.template.lua').read_text(encoding='utf-8')
module_lines = ',\n'.join(f'\t["{name}"] = {{ path = "{v["path"]}", bytes = {v["bytes"]}, blocks = {v["blocks"]} }}' for name, v in modules.items())
step_lines = ',\n'.join(f'\t{{ "{name}", {index} }}' for name, index in steps)
local_lines = ', '.join(f'["{name}"] = true' for name in declarations)
loader = template.replace('@VERSION@', version).replace('@MODULES@', module_lines).replace('@STEPS@', step_lines).replace('@LOCALS@', local_lines)
assert not parser.parse(loader.encode()).root_node.has_error, 'Loader syntax error'
(out / 'larp').write_text(loader, encoding='utf-8', newline='\n')
files.extend(['larp', 'modules-manifest.json'])
(out / 'publish-files.json').write_text(json.dumps(files), encoding='utf-8')
print(f'Built {len(modules)} modules, {len(steps)} ordered blocks, {statement_count} source statements; loader {len(loader):,} bytes')
