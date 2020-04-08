'''
input simulation output (stdin), simulation json to get the dimensinos (cli arg)
output json file format of the simulation output (stdout)

$ python3 output_formatter.py path/to/input.json <path/to/simulation_output
'''
import argparse
import json
import sys

import utils

# read input json
parser = argparse.ArgumentParser()
parser.add_argument('path_input_json',
                    help='path to json input, to get Xout dimensions')
path_input = parser.parse_args().path_input_json

with open(path_input, 'r') as f:
    inp = json.load(f)

# read input binary
binary = sys.stdin.read()

# cast binary to numbers
if inp['Fixedpoint'] == 1:
    batch_size = 16
    to_num = utils.bits_to_fixed
elif inp['Fixedpoint'] == 2:
    batch_size = 64
    to_num = utils.bits_to_double
else:
    batch_size = 32
    to_num = utils.bits_to_float

nums = []
for i in range(0, len(binary), batch_size):
    num = to_num(binary[i:i+batch_size])
    nums.append(num)

assert len(nums) == inp['N'] * inp['Count']

# output json file
print(json.dumps({'Xout': utils.unflatten(nums, inp['Count'])}))
