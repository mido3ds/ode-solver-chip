'''
input input json (stdin)
ouput simulation input ready file (stdout)

$ python3 preprocessor.py <path/to/input.json >path/to/simulation_input.in
'''
import json
import sys

import utils

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

assert inp['Mode'] in (0, 1)
if inp['Mode'] == 1:
    assert 'H' in inp
    assert 'Err' in inp

assert inp['Fixedpoint'] in (1, 2, 3)

# choose to_bits mapper
if inp['Fixedpoint'] == 1:
    to_bits = utils.fixed_to_bits
elif inp['Fixedpoint'] == 2:
    to_bits = utils.double_to_bits
else:
    to_bits = utils.float_to_bits

# prepare input to simulation
# data structure here follows `Section 0.13 - Input Format`
out_arr = [
    # Header
    utils.int_to_n_binary(inp['N'], 6),
    utils.int_to_n_binary(inp['M'], 6),
    utils.int_to_n_binary(inp['Mode'], 1),
    utils.int_to_n_binary(inp['Fixedpoint']-1, 2),
    '0',
    utils.int_to_n_binary(inp['Count'], 3),
    '0'*13,

    # H
    to_bits(inp['H']),

    # Error
    to_bits(inp['Err']),

    # A
    *[to_bits(num) for num in utils.flatten(inp['A'])],

    # B
    *[to_bits(num) for num in utils.flatten(inp['B'])],

    # X
    *[to_bits(num) for num in inp['X0']],

    # U0
    *[to_bits(num) for num in inp['U0']],

    # T
    *[to_bits(num) for num in inp['T']],

    # Us
    *[to_bits(num) for num in utils.flatten(inp['Us'])],
]

assert len(out_arr) > 0

# cast numbers to binary stream
out_stream = ''.join(out_arr)

assert len(out_stream) > 0

# compress binary stream
out_compressed = utils.compress_rle(out_stream)

assert len(out_compressed) > 0

# add padding
if len(out_compressed) % 32 != 0:
    out_compressed += '0'*(32 - len(out_compressed) % 32)

assert len(out_compressed) % 32 == 0

# output out_compressed data
for i in range(0, len(out_compressed), 32):
    print(out_compressed[i:i+32])
