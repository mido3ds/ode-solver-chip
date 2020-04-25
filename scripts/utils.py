import struct
import re


def py_float_to_float32(f: float) -> float:
    return struct.unpack('<f', (struct.pack('<f', f)))[0]


def py_float_to_float64(d: float) -> float:
    return struct.unpack('<d', (struct.pack('<d', d)))[0]


def float_to_bits(f: float) -> str:
    s = struct.pack('<f', f)
    b = bin(struct.unpack('<L', s)[0])[2:]
    return '0'*(32-len(b))+b


def bits_to_float(b: str) -> float:
    b = '0b'+b
    s = struct.pack('<L', int(b, 2))
    return struct.unpack('<f', s)[0]


def double_to_bits(d: float) -> str:
    s = struct.pack('<d', d)
    b = bin(struct.unpack('<Q', s)[0])[2:]
    return '0'*(64-len(b))+b


def bits_to_double(b: str) -> float:
    b = '0b'+b
    s = struct.pack('<Q', int(b, 2))
    return struct.unpack('<d', s)[0]


def int_to_n_binary(i: int, n: int) -> str:
    # binary of integer `i` with `n` bits
    b = bin(i % (2**n))[2:]
    return '0'*(n-len(b)) + b


def py_float_to_fixed(f: float) -> int:
    return int(f * (2**7))


def fixed_to_py_float(i: int) -> float:
    return i / (2**7)


def fixed_to_bits(n: float) -> str:
    return int_to_n_binary(py_float_to_fixed(n), 16)


def bits_to_fixed(b: str) -> float:
    return fixed_to_py_float(int('0b'+b, 2))


def flatten(arr: [[]]) -> []:
    # 2d array -> 1d array
    # e.g. [[1,2,3], [4,5,6], [7,8,9]] -> [1,2,3,4,5,6,7,8,9]
    for subarr in arr:
        for x in subarr:
            yield x


def unflatten(arr: [], cols: int) -> [[]]:
    # 1d array -> 2d arry
    # e.g. assert unflatten(flatten(xs)) == xs
    assert len(arr) % cols == 0
    return [arr[i:i+cols] for i in range(0, len(arr), cols)]


def compress_rle(s: str):
    ptrn = re.compile('(0{1,8}|1{1,8})')

    out = ''
    for x in ptrn.finditer(s):
        g = x.group()
        assert type(g) == str and len(g) <= 8 and len(g) > 0
        out += int_to_n_binary(len(g)-1, 3) + g[0]

    return out


def decompress_rle(s: str):
    assert len(s) % 4 == 0

    out = ''
    for i in range(0, len(s), 4):
        n = int('0b'+s[i:i+3], 2)+1
        b = s[i+3]
        out += b * n

    return out


# testing
if __name__ == "__main__":

    print (fixed_to_bits (38))
    print (fixed_to_bits (84))
    print (fixed_to_bits (130))
    # for n in [0, 1, 2, .5, 0.00001, 0.004999999888241291, 12423421, 23414.123026175,
    #           121243.546875, -10, -1241.3309423828125001, -0, -1]:
    #     n32 = py_float_to_float32(n)
    #     assert bits_to_float(float_to_bits(n32)) == n32,\
    #         f'bits_to_float(float_to_bits({n32}))={bits_to_float(float_to_bits(n32))}'

    #     n64 = py_float_to_float64(n)
    #     assert bits_to_double(double_to_bits(n64)) == n64,\
    #         f'bits_to_double(double_to_bits({n64}))={bits_to_double(double_to_bits(n64))}'

    # for n in range(1, 64):
    #     for i in range(-500, 5000):
    #         r = int_to_n_binary(i, n)

    #         assert int('0b'+r, 2) == (i % 2**n),\
    #             'int("0b"+{r}, 2) 1= ({i} % 2**n)'

    #         assert len(r) == n,\
    #             f'len({r})={len(r)}'

    # test_str = '1010101000000000101011111110110100011011110101010000'
    # assert decompress_rle(compress_rle(test_str)) == test_str,\
    #     f'compress_rle({test_str})={compress_rle(test_str)}, \
    #         decompress={decompress_rle(compress_rle(test_str))}'

    # test_arr = [[i for i in range(100)] for _ in range(10)]
    # flattened = [x for x in flatten(test_arr)]
    # assert unflatten(flattened, 100) == test_arr
