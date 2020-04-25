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
import math
import sys

import numpy as np

import interpolator as interp
import utils


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


def one_step_euler(us, ts, tk, a, b, x, h):
    un = interp.interpolate(us, ts, tk)
    return x + h * (a.dot(x) + b.dot(un))


def solve_fixed(us, ts, a, b, x, h) -> np.array:
    out_pts = ts[1:] - h
    xs = np.zeros((out_pts.size, x.size))
    i = 0

    for tk in np.arange(0, ts.max(), h):
        x = one_step_euler(us, ts, tk, a, b, x, h)

        if tk in out_pts:
            xs[i] = x
            i += 1

    return xs


def solve_var(us, ts, a, b, x, h, err) -> np.array:
    out_pts = ts[1:] - h
    xs = np.zeros((out_pts.size, x.size))
    i = 0

    for tk in np.arange(0, ts.max(), h):
        e = math.inf
        while true:
            x0 = one_step_euler(us, ts, tk, a, b, x, h)

            x1 = one_step_euler(us, ts, tk, a, b, x, h/2)
            x1 = one_step_euler(us, ts, tk, a, b, x1, h/2)
            x = x1

            e = np.sum(np.abs(x1-x0))

            if e <= err:
                out_pts = ts[1:] - h
                break
            else:
                h = (0.9*(h**2)*err)/(e)

        if tk in out_pts:
            xs[i] = x
            i += 1

    return xs


def solve(us, ts, a, b, x, mode, h, err) -> np.array:
    if mode == 'fixed':
        return solve_fixed(us, ts, a, b, x, h)
    else:
        return solve_var(us, ts, a, b, x, h, err)


if __name__ == "__main__":
    print(solve(*read_inputs()).tolist())
