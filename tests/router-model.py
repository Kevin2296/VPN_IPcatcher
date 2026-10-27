"""Small stateful IPv4 model for commands emitted by the production adapter.

This is not a kernel emulator. In particular it does not prove netfilter hook,
conntrack, acceleration, or firmware behavior; those require isolated ASUS QA.
"""
import ipaddress
import json
import os
import sys
from pathlib import Path

path = Path(os.environ['ROUTER_MODEL'])
state = json.loads(path.read_text()) if path.exists() else {'sets': {}, 'tables': {}}
args = sys.argv[2:]
kind = sys.argv[1]
code = 0


def contains(name, address):
    item = state['sets'][name]
    if item['type'] == 'list:set':
        return any(contains(child, address) for child in item['members'])
    return any(ipaddress.ip_address(address) in ipaddress.ip_network(net, strict=False)
               for net in item['members'])


if kind == 'ip':
    assert args[0] == 'rule'
    op = args[1]
    rules = state.setdefault('rules', [])
    if op == 'show':
        for rule in sorted(rules, key=lambda r: r['priority']):
            mark = f' fwmark {rule["mark"]}' if rule['mark'] else ''
            target = 'unreachable' if rule['target'] == 'unreachable' else f'lookup {rule["target"]}'
            print(f'{rule["priority"]}: from {rule["source"]}{mark} {target}')
    else:
        tokens = args[2:]
        rule = {'priority': int(tokens[tokens.index('priority') + 1]),
                'source': tokens[tokens.index('from') + 1],
                'mark': tokens[tokens.index('fwmark') + 1] if 'fwmark' in tokens else '',
                'target': 'unreachable' if tokens[0] == 'unreachable' else tokens[tokens.index('lookup') + 1]}
        if op == 'add':
            rules.append(rule)
        elif op == 'del':
            if rule in rules:
                rules.remove(rule)
            else:
                code = 1
        else:
            raise ValueError(args)
elif kind == 'lookup':
    source, initial_mark, empty_table = args
    mark = int(initial_mark, 0)
    for rule in sorted(state.get('rules', []), key=lambda r: r['priority']):
        if rule['source'] != 'all' and ipaddress.ip_address(source) not in ipaddress.ip_network(rule['source'], strict=False):
            continue
        if rule['mark']:
            expected, mask = map(lambda v: int(v, 0), rule['mark'].split('/'))
            if mark & mask != expected:
                continue
        if rule['target'] == empty_table:
            continue
        print(rule['target'])
        break
    else:
        print('main')
elif kind == 'ipset':
    op, name, *rest = args
    sets = state['sets']
    if op == 'create':
        if name in sets:
            code = 0 if '-exist' in rest else 1
        else:
            sets[name] = {'type': rest[0], 'members': [], 'schema': ' '.join(rest)}
    elif name not in sets:
        code = 1
    elif op == 'flush':
        sets[name]['members'] = []
    elif op == 'swap':
        sets[name], sets[rest[0]] = sets[rest[0]], sets[name]
    elif op == 'add':
        value = rest[0]
        if sets[name]['type'] == 'list:set':
            if value not in sets:
                code = 1
        else:
            ipaddress.ip_network(value, strict=False)
        if not code and value not in sets[name]['members']:
            sets[name]['members'].append(value)
    elif op == 'test':
        code = 0 if contains(name, rest[0]) else 1
    elif op == 'save':
        print(f'create {name} {sets[name]["schema"]}')
        for value in sets[name]['members']:
            print(f'add {name} {value}')
    elif op == 'list':
        print(f'Name: {name}\nMembers:')
        print('\n'.join(sets[name]['members']))
    else:
        raise ValueError(args)
elif kind == 'iptables':
    assert args[0] == '-t'
    table, op, *rest = args[1:]
    rules = state['tables'].setdefault(table, [])
    if op == '-S':
        print('\n'.join(' '.join(rule) for rule in rules))
    else:
        chain, *rule = rest
        if op == '-I':
            assert rule.pop(0) == '1'
        entry = ['-A', chain, *rule]
        if op == '-C':
            code = 0 if entry in rules else 1
        elif op == '-D':
            if entry in rules:
                rules.remove(entry)
            else:
                code = 1
        elif op == '-I':
            rules.insert(0, entry)
        elif op == '-A':
            rules.append(entry)
        else:
            raise ValueError(args)
elif kind == 'packet':
    source, destination, interface, initial_mark = args[:4]
    mark = int(initial_mark, 0)
    blocked = False
    for table, chain in [('mangle', 'PREROUTING'), ('filter', 'FORWARD')]:
        if table == 'filter' and args[4:] == ['clear-mark']:
            mark = 0
        for rule in state['tables'].get(table, []):
            if rule[1] != chain:
                continue
            matches = True
            for index, token in enumerate(rule):
                negate = index > 0 and rule[index - 1] == '!'
                if token == '--match-set':
                    value = source if rule[index + 2] == 'src' else destination
                    result = contains(rule[index + 1], value)
                elif token == '--mark':
                    expected, mask = map(lambda v: int(v, 0), rule[index + 1].split('/'))
                    result = mark & mask == expected
                elif token == '-o':
                    result = interface == rule[index + 1]
                else:
                    continue
                matches &= result != negate
            if matches:
                target = rule[rule.index('-j') + 1]
                if target == 'REJECT':
                    blocked = True
                    break
                if target == 'MARK':
                    value, mask = map(lambda v: int(v, 0), rule[-1].split('/'))
                    mark = mark & ~mask | value
    print(f'{hex(mark)} {"blocked" if blocked else "allowed"}')
else:
    raise ValueError(kind)
path.write_text(json.dumps(state))
sys.exit(code)
