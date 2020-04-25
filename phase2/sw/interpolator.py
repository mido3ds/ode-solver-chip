#!/usr/sbin/env python3
'''
Interpolator SW equivalent.

input: 
    - from stdin: input json file to the ode-solver (see input dir).
    - from command line: time Tk to calculate Uk at.
output: Uk at given Tk using given input json

requirements: $ pip3 install --user numpy

e.g. to use sample-f16 and calculate Uk at T=1.5:
$ ./interpolator.py 1.5 <input/sample-f16.json
'''
import json
import sys

import numpy as np

import utils


def read_inputs():
    if len(sys.argv) != 2:
        print('usage: $ ./interpolator.py Tk </path/to/input.json')
        sys.exit(1)

    inp = json.load(sys.stdin)

    cast, vcast = utils.get_float_caster(inp)

    ts = vcast(np.array([0, *inp['T']]))
    us = vcast(np.array([inp['U0'], *inp['Us']]))

    tk = cast(float(sys.argv[1]))
    assert tk >= 0 and tk <= np.max(ts)
    assert ts.size == us.shape[0]

    return us, ts, tk


def get_range(us, ts, tk):
    for i in range(len(ts)-1):
        if tk >= ts[i] and tk < ts[i+1]:
            return i, i+1
    return len(ts)-1, len(ts)-1


def interpolate(us, ts, tk):
    if tk in ts:
        return us[np.where(ts == tk)][0]
    else:
        n, z = get_range(us, ts, tk)
        return us[n] + (tk - ts[n]) / (ts[z] - ts[n]) * (us[z] - us[n])


if __name__ == "__main__":
    print(interpolate(*read_inputs()))
