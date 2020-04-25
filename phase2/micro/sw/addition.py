class Adder():
    def __init__(self):
        self.number_of_bits = 16
        self.err = 0
        self.out = '0' * 16
        self.zero = 0
        self.posv = 0
        self.done = 0

    def complement(self,num):
        res = ""
        found = False
        for i in range(len(num)-1,-1,-1):
            if found:
                if num[i] == '1':
                    res = '0' + res
                else:
                    res = '1' + res
                continue
            if num[i] == '1':
                found = True
            res = num[i] + res
        return res

    def half_adder(self,a, b):
        sum = a ^ b
        carry = a and b
        return carry, sum

    def full_adder(self,carry_in, a, b):
        carry1, sum1 = self.half_adder(carry_in, a)
        carry2, sum = self.half_adder(sum1, b)
        carry = carry1 or carry2
        return carry, sum

    def with_operator(self, a, b, rst, enable, add_sub):
        if (rst == 1):
            self.posv = 0
            self.out = None
            self.err = 0
            self.zero = 0
            self.done = 0
        elif (rst == 0 and enable == 1):
            if (add_sub == 0):
                res = a + b
                binary = bin(res).replace("0b", "").zfill(32)
                if binary[0] == '-':  # negative
                    binary = self.complement(binary[1] + binary[1:])

                if binary[:10] != "1111111111" and binary[:10] != "0000000000":
                    self.err = 1
                self.out = binary
                if self.out == '0' * 32:
                    self.zero = 1
                else:
                    self.zero = 0
                if self.out[0] == '0' and self.zero == 0:
                    self.posv = 1
                else:
                    self.posv = 0
                self.done = 1
                return self.out, self.done, self.err, self.zero, self.posv
            else:
                res = a - b
                binary = bin(res).replace("0b", "").zfill(32)
                if binary[0] == '-':  # negative
                    binary = self.complement(binary[1] + binary[1:])

                if binary[:10] != "1111111111" and binary[:10] != "0000000000":
                    self.err = 1
                self.out = binary
                if self.out == '0' * 32:
                    self.zero = 1
                else:
                    self.zero = 0
                if self.out[0] == '0' and self.zero == 0:
                    self.posv = 1
                else:
                    self.posv = 0
                self.done = 1
                return self.out, self.done, self.err, self.zero, self.posv
        else:
            self.out = '0' * 32
            self.zero = 0
            self.posv = 0
            self.done = 0
            return self.out, self.done, self.err, self.zero, self.posv

    def first_algo(self, a, b, rst, enable, add_sub, carry_in):  # CLA Adder
        if (rst == 1):
            self.posv = 0
            self.out = None
            self.err = 0
            self.zero = 0
            self.done = 0
        elif (rst == 0 and enable == 1):
            if (add_sub == 0):
                num_bits = 16
                carry_generate = a & b
                carry_propagate = a ^ b
                initial_sum = a ^ b
                carry_generate = [(carry_generate >> bit) & 1 for bit in range(num_bits - 1, -1, -1)]
                carry_propagate = [(carry_propagate >> bit) & 1 for bit in range(num_bits - 1, -1, -1)]
                initial_sum = [(initial_sum >> bit) & 1 for bit in range(num_bits - 1, -1, -1)]
                carry_in_internal = [0] * 15
                carry_in_internal[14] = carry_generate[15] | (carry_propagate[15] & carry_in)
                for i in range(13, -1,-1):
                    carry_in_internal[i] = carry_generate[i+1] | (carry_propagate[i+1] & carry_in_internal[i-1])
                carry_out = carry_generate[0] | (carry_propagate[0] & carry_in_internal[0])
                sum = [0] * 16
                sum[15] = carry_in ^ initial_sum[15]
                for i in range(14,-1,-1):
                    sum[i] = initial_sum[i] ^ carry_in_internal[i]
                self.out = sum
                self.done=1
                if sum[0]==1 and a>0 and b>0:
                    self.err=1
                elif sum[0]==0 and a<0 and b<0:
                    self.err=1
                else:
                    self.err=0
                if sum ==[0]*16:
                    self.zero=1
                else:
                    self.zero=0
                if sum[0]==0:
                   self.posv=1
                else:
                    self.posv=0
                return self.out, self.done, self.err, self.zero, self.posv
            else:
                num_bits = 16
                b=b*-1
                carry_generate = a & b
                carry_propagate = a ^ b
                initial_sum = a ^ b
                carry_generate = [(carry_generate >> bit) & 1 for bit in range(num_bits - 1, -1, -1)]
                carry_propagate = [(carry_propagate >> bit) & 1 for bit in range(num_bits - 1, -1, -1)]
                initial_sum = [(initial_sum >> bit) & 1 for bit in range(num_bits - 1, -1, -1)]
                carry_in_internal = [0] * 15
                carry_in_internal[14] = carry_generate[15] | (carry_propagate[15] & carry_in)
                for i in range(13, -1, -1):
                    carry_in_internal[i] = carry_generate[i + 1] | (carry_propagate[i + 1] & carry_in_internal[i - 1])
                carry_out = carry_generate[0] | (carry_propagate[0] & carry_in_internal[0])
                sum = [0] * 16
                sum[15] = carry_in ^ initial_sum[15]
                for i in range(14, -1, -1):
                    sum[i] = initial_sum[i] ^ carry_in_internal[i]
                self.done = 1
                if sum[0] == 1 and a > 0 and b > 0:
                    self.err = 1
                elif sum[0] == 0 and a < 0 and b < 0:
                    self.err = 1
                else:
                    self.err = 0
                if sum == [0] * 16:
                    self.zero = 1
                else:
                    self.zero = 0
                if sum[0] == 0:
                    self.posv = 1
                else:
                    self.posv = 0
                return self.out, self.done, self.err, self.zero, self.posv

    def sec_algo(self, a, b, rst, enable, add_sub, carry_in): ## Caryy Select
        if (rst == 1):
            self.posv = 0
            self.out = None
            self.err = 0
            self.zero = 0
            self.done = 0
        elif (rst == 0 and enable == 1):
            if (add_sub == 0):
                num_bits = 16
                a_bits = [(a >> bit) & 1 for bit in range(num_bits - 1, -1, -1)]
                b_bits = [(b >> bit) & 1 for bit in range(num_bits - 1, -1, -1)]
                sum_0 = [0] * 16
                prev_carry,sum_0[15] = self.full_adder(0, a_bits[15], b_bits[15])
                for i in range(14,-1,-1):
                    carry,sum_0[i] = self.full_adder(prev_carry, a_bits[i], b_bits[i])
                    prev_carry = carry
                sum_1=[0]*16
                prev_carry,sum_1[15] = self.full_adder(1, a_bits[15], b_bits[15])
                for i in range(1, len(a_bits)):
                    carry,sum_1[i] = self.full_adder(prev_carry, a_bits[i], b_bits[i])
                    prev_caryy = carry
                self.out = sum_0
                self.done = 1
                if sum_0[0] == 1 and a > 0 and b > 0:
                    self.err = 1
                elif sum_0[0] == 0 and a < 0 and b < 0:
                    self.err = 1
                else:
                    self.err = 0
                if sum_0 == [0] * 16:
                    self.zero = 1
                else:
                    self.zero = 0
                if sum_0[0] == 0 and not self.zero:
                    self.posv = 1
                else:
                    self.posv = 0
                return self.out, self.done, self.err, self.zero, self.posv
            else:
                num_bits = 16
                a_bits = [(a >> bit) & 1 for bit in range(num_bits - 1, -1, -1)]
                binary = bin(b).replace("0b", "").zfill(16)
                b_string= self.complement(binary)
                b_bits=[0]*16
                for i in range(0,16):
                    b_bits[i]=int(b_string[i])
                sum_0 = [0] * 16
                prev_carry, sum_0[15] = self.full_adder(0, a_bits[15], b_bits[15])
                for i in range(14, -1, -1):
                    carry, sum_0[i] = self.full_adder(prev_carry, a_bits[i], b_bits[i])
                    prev_carry = carry
                sum_1 = [0] * 16
                prev_carry, sum_1[15] = self.full_adder(1, a_bits[15], b_bits[15])
                for i in range(14,-1,-1):
                    carry, sum_1[i] = self.full_adder(prev_carry, a_bits[i], b_bits[i])
                    prev_caryy = carry
                self.out = sum_0
                self.done = 1
                if sum_0[0] == 1 and a > 0 and b > 0:
                    self.err = 1
                elif sum_0[0] == 0 and a < 0 and b < 0:
                    self.err = 1
                else:
                    self.err = 0
                if sum_0 == [0] * 16:
                    self.zero = 1
                else:
                    self.zero = 0
                if sum_0[0] == 0 and not self.zero:
                    self.posv = 1
                else:
                    self.posv = 0
                return self.out, self.done, self.err, self.zero, self.posv


a = Adder()
# with operator
out,done,err,zero,posv=a.with_operator(52, 44, 0, 1, 0)
if out != '00000000000000000000000001100000' or done != 1 or err!=0 or zero!=0 or posv!=1:
    print("Error test 1")

out,done,err,zero,posv=a.with_operator(-18, 56, 0, 1, 0)
if out != '00000000000000000000000000100110' or done != 1 or err!=0 or zero!=0 or posv!=1:
    print("Error test 2")
    
out,done,err,zero,posv=a.with_operator(8, 2, 0, 1, 0)
if out != '00000000000000000000000000001010' or done != 1 or err!=0 or zero!=0 or posv!=1:
    print("Error test 3")

out,done,err,zero,posv=a.with_operator(172, -196, 0, 1, 0)
if out != '11111111111111111111111111101000' or done != 1 or err!=0 or zero!=0 or posv!=0:
    print("Error test 4")
    
out,done,err,zero,posv=a.with_operator(322, -322, 0, 1, 0)
if out != '00000000000000000000000000000000' or done != 1 or err!=0 or zero!=1 or posv!=0:
    print("Error test 5")

out,done,err,zero,posv=a.with_operator(-82, -60, 0, 1, 0)
if out != '11111111111111111111111101110010' or done != 1 or err!=0 or zero!=0 or posv!=0:
    print("Error test 6")
    
out,done,err,zero,posv=a.with_operator(52, 44, 0, 1, 1)
if out != '00000000000000000000000000001000' or done != 1 or err!=0 or zero!=0 or posv!=1:
    print("Error test 7")
    
out,done,err,zero,posv=a.with_operator(-18, 56, 0, 1, 1)
if out != '11111111111111111111111110110110' or done != 1 or err!=0 or zero!=0 or posv!=0:
    print("Error test 8")
    
out,done,err,zero,posv=a.with_operator(8, 2, 0, 1, 1)
if out != '00000000000000000000000000000110' or done != 1 or err!=0 or zero!=0 or posv!=1:
    print("Error test 9")

out,done,err,zero,posv=a.with_operator(-82, -60, 0, 1, 0)
if out != '11111111111111111111111101110010' or done != 1 or err!=0 or zero!=0 or posv!=0:
    print("Error test 10")  
    

# first algo
out,done,err,zero,posv=a.sec_algo(52, 44, 0, 1, 0,0)
if out != [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0] or done != 1 or err!=0 or zero!=0 or posv!=1:
    print("Error test 1")

out,done,err,zero,posv=a.sec_algo(-18, 56, 0, 1, 0,0)
if out != [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0] or done != 1 or err!=0 or zero!=0 or posv!=1:
    print("Error test 2")
    
out,done,err,zero,posv=a.sec_algo(8, 2, 0, 1, 0,0)
if out != [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0]or done != 1 or err!=0 or zero!=0 or posv!=1:
    print("Error test 3")
    
out,done,err,zero,posv=a.sec_algo(172, -196, 0, 1, 0,0)
if out != [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 0, 0] or done != 1 or err!=0 or zero!=0 or posv!=0:
    print("Error test 4")
    
out,done,err,zero,posv=a.sec_algo(322, -322, 0, 1, 0,0)
if out != [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] or done != 1 or err!=0 or zero!=1 or posv!=0:
    print("Error test 5")

out,done,err,zero,posv=a.sec_algo(-82, -60, 0, 1, 0,0)
if out != [1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 1, 0] or done != 1 or err!=0 or zero!=0 or posv!=0:
    print("Error test 6")
    
out,done,err,zero,posv=a.sec_algo(52, 44, 0, 1, 1,0)
if out !=[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0]or done != 1 or err!=0 or zero!=0 or posv!=1:
    print("Error test 7")
    
out,done,err,zero,posv=a.sec_algo(-18, 56, 0, 1, 1,0)
if out != [1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0]or done != 1 or err!=0 or zero!=0 or posv!=0:
    print("Error test 8")
    
out,done,err,zero,posv=a.sec_algo(8, 2, 0, 1, 1,0)
if out != [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0]or done != 1 or err!=0 or zero!=0 or posv!=1:
    print("Error test 9")

out,done,err,zero,posv=a.sec_algo(-82, -60, 0, 1, 0,0)
if out != [1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 1, 0] or done != 1 or err!=0 or zero!=0 or posv!=0:
    print("Error test 10")



#second algo
out,done,err,zero,posv=a.sec_algo(52, 44, 0, 1, 0,0)
if out != [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0] or done != 1 or err!=0 or zero!=0 or posv!=1:
    print("Error test 1")

out,done,err,zero,posv=a.sec_algo(-18, 56, 0, 1, 0,0)
if out != [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0] or done != 1 or err!=0 or zero!=0 or posv!=1:
    print("Error test 2")
    
out,done,err,zero,posv=a.sec_algo(8, 2, 0, 1, 0,0)
if out != [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0]or done != 1 or err!=0 or zero!=0 or posv!=1:
    print("Error test 3")
    
out,done,err,zero,posv=a.sec_algo(172, -196, 0, 1, 0,0)
if out != [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 0, 0] or done != 1 or err!=0 or zero!=0 or posv!=0:
    print("Error test 4")
    
out,done,err,zero,posv=a.sec_algo(322, -322, 0, 1, 0,0)
if out != [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] or done != 1 or err!=0 or zero!=1 or posv!=0:
    print("Error test 5")

out,done,err,zero,posv=a.sec_algo(-82, -60, 0, 1, 0,0)
if out != [1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 1, 0] or done != 1 or err!=0 or zero!=0 or posv!=0:
    print("Error test 6")
    
out,done,err,zero,posv=a.sec_algo(52, 44, 0, 1, 1,0)
if out !=[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0]or done != 1 or err!=0 or zero!=0 or posv!=1:
    print("Error test 7")
    
out,done,err,zero,posv=a.sec_algo(-18, 56, 0, 1, 1,0)
if out != [1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0]or done != 1 or err!=0 or zero!=0 or posv!=0:
    print("Error test 8")
    
out,done,err,zero,posv=a.sec_algo(8, 2, 0, 1, 1,0)
if out != [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0]or done != 1 or err!=0 or zero!=0 or posv!=1:
    print("Error test 9")

out,done,err,zero,posv=a.sec_algo(-82, -60, 0, 1, 0,0)
if out != [1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 1, 0] or done != 1 or err!=0 or zero!=0 or posv!=0:
    print("Error test 10")
