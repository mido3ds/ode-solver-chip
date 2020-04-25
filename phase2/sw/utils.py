import struct

import numpy as np


def py_float_to_float32(f: float) -> float:
    return struct.unpack('<f', (struct.pack('<f', f)))[0]


def py_float_to_float64(d: float) -> float:
    return struct.unpack('<d', (struct.pack('<d', d)))[0]


def py_float_to_fixed(f: float) -> int:
    return int(f * (2**7)) / (2 ** 7)


def get_float_caster(inp):
    if inp['Fixedpoint'] == 1:
        cast = py_float_to_fixed
    elif inp['Fixedpoint'] == 2:
        cast = py_float_to_float64
    else:
        cast = py_float_to_float32

    return cast, np.vectorize(cast)
