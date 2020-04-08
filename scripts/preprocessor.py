'''
read input json
ouput simulation input ready file

$ python3 preprocessor.py <path/to/input.json >path/to/simulation_input
'''
import json
import sys

from utils import double_to_bits, int_to_n_binary, flatten, compress_rle

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

assert inp['Fixedpoint'] in (0, 1, 2)

# prepare input to simulation
# data structure here follows `Section 0.13 - Input Format`
out_arr = [
    # Header
    int_to_n_binary(inp['N'], 6),
    int_to_n_binary(inp['M'], 6),
    int_to_n_binary(inp['Mode'], 1),
    int_to_n_binary(inp['Fixedpoint'], 2),
    '0',
    int_to_n_binary(inp['Count'], 3),
    '0'*13,

    # H
    double_to_bits(inp['H']),

    # Error
    double_to_bits(inp['Err']),

    # A
    *[double_to_bits(num) for num in flatten(inp['A'])],

    # B
    *[double_to_bits(num) for num in flatten(inp['B'])],

    # X
    *[double_to_bits(num) for num in inp['X0']],

    # U0
    *[double_to_bits(num) for num in inp['U0']],

    # T
    *[double_to_bits(num) for num in inp['T']],

    # Us
    *[double_to_bits(num) for num in flatten(inp['Us'])],
]

assert len(out_arr) > 0

# cast numbers to binary stream
out_stream = ''.join(out_arr)

assert len(out_stream) > 0

# compress binary stream
out_compressed = compress_rle(out_stream)

assert len(out_compressed) > 0

# add padding
if len(out_compressed) % 32 != 0:
    out_compressed += '0'*(32 - len(out_compressed) % 32)

assert len(out_compressed) % 32 == 0

# output out_compressed data
for i in range(0, len(out_compressed), 32):
    print(out_compressed[i:i+32])
