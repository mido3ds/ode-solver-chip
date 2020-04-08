'''
read input json
ouput simulation input ready file

$ python3 preprocessor.py <path/to/input.json >path/to/output.sin
'''
import json
import sys

# TODO
# read file
inp = json.load(sys.stdin)

# verify input
assert inp['N'] < 2**6 and inp['N'] > 0
assert inp['M'] < 2**6 and inp['M'] > 0
assert inp['Count'] <= 5 and inp['Count'] > 0

assert len(inp['A']) == inp['N']
for a in inp['A']:
    assert len(a) == inp['N'], \
        f'a={a}, inp["N"]={inp["N"]}'

assert len(inp['B']) == inp['N']
for b in inp['B']:
    assert len(b) == inp['M'], \
        f'b={b}, inp["M"]={inp["M"]}'

assert len(inp['Us']) == inp['M']
for u in inp['Us']:
    assert len(u) == inp['Count'], \
        f'u={u}, inp["Count"]={inp["Count"]}'

assert len(inp['T']) == inp['Count']
assert len(inp['U0']) == inp['Count']
assert len(inp['X0']) == inp['N']

assert inp['Mode'] in [1, 2]
if inp['Mode'] == 1:
    assert 'H' in inp
    assert 'Err' in inp

assert inp['Fixedpoint'] in [1, 2, 3]

# prepare simulation input
# cast numbers to binary stream
# compress binary stream
# output compressed data
