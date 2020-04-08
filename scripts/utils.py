import struct


def py_float_to_float32(f):
    return struct.unpack('<f', (struct.pack('<f', f)))[0]


def py_float_to_float64(d):
    return struct.unpack('<d', (struct.pack('<d', d)))[0]


def float_to_bits(f):
    s = struct.pack('<f', f)
    b = bin(struct.unpack('<L', s)[0])[2:]
    return '0'*(32-len(b))+b


def bits_to_float(b):
    b = '0b'+b
    s = struct.pack('<L', int(b, 2))
    return struct.unpack('<f', s)[0]


def double_to_bits(d):
    s = struct.pack('<d', d)
    b = bin(struct.unpack('<Q', s)[0])[2:]
    return '0'*(64-len(b))+b


def bits_to_double(b):
    b = '0b'+b
    s = struct.pack('<Q', int(b, 2))
    return struct.unpack('<d', s)[0]


def int_to_n_binary(i, n):
    # binary of integer `i` with `n` bits
    b = bin(i % (2**n))[2:]
    return '0'*(n-len(b)) + b


# testing
if __name__ == "__main__":
    for n in [0, 1, 2, .5, 0.00001, 0.004999999888241291, 12423421, 23414.123026175,
              121243.546875, -10, -1241.3309423828125001, -0, -1]:
        n32 = py_float_to_float32(n)
        assert bits_to_float(float_to_bits(n32)) == n32,\
            f'bits_to_float(float_to_bits({n32}))={bits_to_float(float_to_bits(n32))}'

        n64 = py_float_to_float64(n)
        assert bits_to_double(double_to_bits(n64)) == n64,\
            f'bits_to_double(double_to_bits({n64}))={bits_to_double(double_to_bits(n64))}'

    for n in range(1, 64):
        for i in range(-500, 5000):
            r = int_to_n_binary(i, n)

            assert int('0b'+r, 2) == (i % 2**n),\
                'int("0b"+{r}, 2) 1= ({i} % 2**n)'

            assert len(r) == n,\
                f'len({r})={len(r)}'
