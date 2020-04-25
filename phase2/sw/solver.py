#!/usr/sbin/env python3
'''
Solver SW equivalent.

input:
    - from stdin: input json file to the ode-solver (see input dir).
output: Xout

requirements: $ pip3 install --user numpy

e.g. solve sample-f16 in (see input dir)
$ ./solver.py <sample-f16.json
'''
import json
import sys

import numpy as np

import utils
import interpolator as interp


def read_inputs():
    inp = json.load(sys.stdin)

    _, vcast = utils.get_float_caster(inp)

    ts = vcast(np.array([0, *inp['T']]))
    us = vcast(np.array([inp['U0'], *inp['Us']]))
    a = vcast(np.array(inp['A']))
    b = vcast(np.array(inp['B']))
    x = vcast(np.array(inp['X0']))

    mode = 'variable'
    if inp['Mode'] == 0:
        mode = 'fixed'

    return us, ts, a, b, x, mode, inp['H'], inp['Err']


def solve_fixed(us, ts, a, b, x, h) -> list:
    out_pts = ts[1:] - h
    xs = np.zeros((out_pts.size, x.size))
    i = 0

    for tk in np.arange(0, ts.max(), h):
        un = interp.interpolate(us, ts, tk)
        x = x + h * (a.dot(x) + b.dot(un))

        if tk in out_pts:
            xs[i] = x
            i += 1

    return xs.tolist()


def solve_var(us, ts, a, b, x, h, err) -> list:
    return x.tolist()


def solve(us, ts, a, b, x, mode, h, err) -> list:
    if mode == 'fixed':
        return solve_fixed(us, ts, a, b, x, h)
    else:
        return solve_var(us, ts, a, b, x, h, err)


if __name__ == "__main__":
    print(solve(*read_inputs()))
