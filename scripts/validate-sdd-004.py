#!/usr/bin/env python3
"""Validate the TrackIA 004 SDD documents; never claims runtime implementation."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
FEATURE = ROOT / 'specs/004-trackia-experience'
errors = []


def check(condition, message):
    if not condition:
        errors.append(message)


required = ['spec.md', 'plan.md', 'research.md', 'data-model.md', 'quickstart.md',
            'tasks.md', 'traceability.md', 'checklists/requirements.md',
            'contracts/assistant-blocks.md', 'contracts/reminders-android.md',
            'contracts/visual-tokens.md']
for name in required:
    check((FEATURE / name).is_file(), f'Missing {name}')
if errors:
    sys.exit('\n'.join(errors))

spec = (FEATURE / 'spec.md').read_text()
tasks = (FEATURE / 'tasks.md').read_text()
trace = (FEATURE / 'traceability.md').read_text()

reqs = re.findall(r'\*\*((?:FR|SC)-\d{3})\*\*', spec)
frs = [r for r in reqs if r.startswith('FR')]
scs = [r for r in reqs if r.startswith('SC')]
check(frs == [f'FR-{n:03}' for n in range(1, len(frs) + 1)], 'FR IDs not unique and ordered')
check(scs == [f'SC-{n:03}' for n in range(1, len(scs) + 1)], 'SC IDs not unique and ordered')

stories = re.findall(r'^### User Story (\d+) .+\(Priority: (P\d)', spec, re.M)
check([int(s) for s, _ in stories] == list(range(1, len(stories) + 1)), 'Stories not US1..USn')
story_ids = {s for s, _ in stories}

lines = [line for line in tasks.splitlines() if re.match(r'^- \[[ xX]\] T', line)]
pattern = re.compile(
    r'^- \[([ xX])\] (T\d{3})(?: \[P\])?(?: \[US(\d+)\])?(?: \[OWNER\])? .+`[^`]+\.[^`]+`.*'
    r'\(((?:FR|SC)-\d{3}(?: (?:FR|SC)-\d{3})*)\)$')
ids, refs = [], {}
all_lines = tasks.splitlines()
for line in lines:
    match = pattern.match(line)
    check(bool(match), f'Task format/path/reference invalid: {line[:100]}')
    if not match:
        continue
    done, tid, story, cited = match.groups()
    ids.append(tid)
    check(story is None or story in story_ids, f'Unknown story in {tid}')
    for req in cited.split():
        check(req in reqs, f'{tid} cites unknown {req}')
        refs.setdefault(req, []).append(tid)
    if done in 'xX':
        index = all_lines.index(line)
        following = all_lines[index + 1] if index + 1 < len(all_lines) else ''
        check(following.strip().startswith('- Evidencia:'),
              f'{tid} is checked without an Evidencia line below it')
check(ids == [f'T{n:03}' for n in range(1, len(ids) + 1)], 'Task IDs not sequential/unique')

for req in reqs:
    check(req in refs, f'{req} has no task')
    row = re.search(r'^\| ' + req + r' \|.*$', trace, re.M)
    check(bool(row), f'No traceability row: {req}')
    if row:
        mapped = re.findall(r'T\d{3}', row[0])
        check(sorted(mapped) == sorted(refs.get(req, [])),
              f'Traceability for {req} differs from tasks.md: {mapped} vs {refs.get(req)}')

authored = [FEATURE / name for name in required] + [ROOT / 'specs/README.md']
for path in authored:
    content = path.read_text()
    check(not re.search(r'NEEDS CLARIFICATION|TKTK|\bTODO\b|\[FEATURE\]|\[DATE\]|\[###', content),
          f'Unresolved placeholder: {path.relative_to(ROOT)}')
    for target in re.findall(r'(?<!!)\[[^\]]+\]\(([^)]+)\)', content):
        if re.match(r'^(?:https?://|mailto:|#)', target):
            continue
        dest = target.split('#', 1)[0]
        check((path.parent / dest).exists(), f'Broken link in {path.relative_to(ROOT)}: {target}')

if errors:
    sys.exit('\n'.join(errors))
done = sum(1 for line in lines if line.startswith('- [x]') or line.startswith('- [X]'))
print(f'SDD 004 OK: {len(frs)} FR, {len(scs)} SC, {len(stories)} historias, '
      f'{len(ids)} tareas ({done} hechas).')
