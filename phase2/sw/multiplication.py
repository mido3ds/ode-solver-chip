class Multiplier():
    def __init__(self):
        self.number_of_bits = 16
        self.err = 0
        self.out = '0'*16
        self.zero = 0
        self.posv = 0
        self.done = 0

    def ADD(self,a,b):
        res = ""
        carry = 0
        for i in range(len(a)-1,-1,-1):
            a1 = int(a[i])
            a2 = int(b[i])
            res += str((a1^a2^carry))
            carry = (a1 and a2) or (carry and a1) or (carry and a2)
        
        return res[::-1]

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

    def with_operators(self,a,b,rst,enbl):
        if rst == 1:
            self.out = '0'*16
            self.zero = 0
            self.posv = 0
            self.done = 1
            self.err = 0
            return self.out,self.done,self.err,self.zero,self.posv
        elif enbl == 1 and self.err == 0:
            res = a*b
            binary = bin(res).replace("0b","").zfill(32)
            if binary[0] == '-':    #negative
                binary = self.complement(binary[1]+binary[1:])

            if binary[:10]!="1111111111" and binary[:10]!="0000000000":
                self.err = 1
            self.out = binary[9:25]
            if self.out == '0'*16:
                self.zero = 1
            else:
                self.zero = 0
            if self.out[0] == '0' and self.zero == 0:
                self.posv = 1
            else:
                self.posv = 0
            self.done = 1

            return self.out,self.done,self.err,self.zero,self.posv

        elif enbl == 0:
            self.out = '0'*16
            self.zero = 0
            self.posv = 0
            self.done = 0
            return self.out,self.done,self.err,self.zero,self.posv
        else:
            return self.out,self.done,self.err,self.zero,self.posv

    def first_algo(self,a,b,rst,enbl):
        if rst == 1:
            self.out = '0'*16
            self.zero = 0
            self.posv = 0
            self.done = 1
            self.err = 0
            return self.out,self.done,self.err,self.zero,self.posv
        elif enbl == 1 and self.err == 0:
            # booth algorithm
            multiplier = bin(b).replace("0b","").zfill(16)
            num = bin(a).replace("0b","").zfill(16)
            comp = ""
            if multiplier[0] == '-':
                multiplier = self.complement("0"+multiplier[1:])
            multiplier += "0"
            if num[0] == '-':
                num = self.complement("0"+num[1:])
            
            comp = self.complement(num)
            
            output = '0'*32     
            for i in range(len(num),0,-1):
                if multiplier[i-1:i+1] == "10":
                    res = self.ADD(output[i:i+16],comp)
                    output = output[:i-1]+res[0]+res+output[i+16:]
                elif multiplier[i-1:i+1] == "01":
                    res = self.ADD(output[i:i+16],num)
                    output = output[:i-1]+res[0]+res+output[i+16:]
                else:
                    output = output[:i-1]+output[i]+output[i:]

            if output[:10]!="1111111111" and output[:10]!="0000000000":
                self.err = 1
            self.out = output[9:25]
            if self.out == '0'*16:
                self.zero = 1
            else:
                self.zero = 0
            if self.out[0] == '0' and self.zero == 0:
                self.posv = 1
            else:
                self.posv = 0
            self.done = 1

            return self.out,self.done,self.err,self.zero,self.posv
        elif enbl == 0:
            self.out = '0'*16
            self.zero = 0
            self.posv = 0
            self.done = 0
            return self.out,self.done,self.err,self.zero,self.posv
        else:
            return self.out,self.done,self.err,self.zero,self.posv
    def sec_algo(self,a,b,rst,enbl):
        if rst == 1:
            self.out = '0'*16
            self.zero = 0
            self.posv = 0
            self.done = 1
            self.err = 0
            return self.out,self.done,self.err,self.zero,self.posv
        elif enbl == 1 and self.err == 0:
            multiplier = bin(b).replace("0b","").zfill(16)
            num = bin(a).replace("0b","").zfill(32)
            comp = ""
            if multiplier[0] == '-':
                multiplier = self.complement("0"+multiplier[1:])
            if num[0] == '-':
                num = self.complement("0"+num[1:])
            comp = self.complement(num)

            output = '0'*32   

            for i in range(len(multiplier)-1 , 0 , -1):
                if multiplier[i] == '1':
                    res = self.ADD(output[:i+17],num[31-(i+16):])
                    output = res + output[i+17:]
            if multiplier[0] == '1':
                res = self.ADD(output[:17],comp[15:])
                output = res + output[17:]

            if output[:10]!="1111111111" and output[:10]!="0000000000":
                self.err = 1
            self.out = output[9:25]
            if self.out == '0'*16:
                self.zero = 1
            else:
                self.zero = 0
            if self.out[0] == '0' and self.zero == 0:
                self.posv = 1
            else:
                self.posv = 0
            self.done = 1
            return self.out,self.done,self.err,self.zero,self.posv

        elif enbl == 0:
            self.out = '0'*16
            self.zero = 0
            self.posv = 0
            self.done = 0
            return self.out,self.done,self.err,self.zero,self.posv
        else:
            return self.out,self.done,self.err,self.zero,self.posv

    def test_with_operator(self):
        self.err = 0

        out , done , err , zero , posv = self.with_operators(-22555,18657,0,1)
        if out != "1101010111110000" or done != 1 or err != 1 or zero != 0 or posv != 0:
            print("test1 with operators failed")

        out , done , err , zero , posv = self.with_operators(5,18657,0,1)
        if out != "1101010111110000" or done != 1 or err != 1 or zero != 0 or posv != 0:
            print("test2 with operators failed")

        out , done , err , zero , posv = self.with_operators(5,18657,0,0)
        if out != '0'*16 or done != 0 or err != 1 or zero != 0 or posv != 0:
            print("test3 with operators failed")

        out , done , err , zero , posv = self.with_operators(5,18657,1,0)
        if out != '0'*16 or done != 1 or err != 0 or zero != 0 or posv != 0:
            print("test4 with operators failed")

        out , done , err , zero , posv = self.with_operators(5,18657,0,1)
        if out != "0000001011011000" or done != 1 or err != 0 or zero != 0 or posv != 1:
            print("test5 with operators failed")

        out , done , err , zero , posv = self.with_operators(-5,18657,0,1)
        if out != "1111110100100111" or done != 1 or err != 0 or zero != 0 or posv != 0:
            print("test6 with operators failed")

        out , done , err , zero , posv = self.with_operators(-5,-14111,0,1)
        if out != "0000001000100111" or done != 1 or err != 0 or zero != 0 or posv != 1:
            print("test7 with operators failed")
        
        out , done , err , zero , posv = self.with_operators(-5,0,0,1)
        if out != "0000000000000000" or done != 1 or err != 0 or zero != 1 or posv != 0:
            print("test8 with operators failed")

        out , done , err , zero , posv = self.with_operators(-5,18657,0,0)
        if out != "0000000000000000" or done != 0 or err != 0 or zero != 0 or posv != 0:
            print("test9 with operators failed")

        print("with operator tests passed")
    def test_with_first_algo(self):
        self.err = 0

        out , done , err , zero , posv = self.first_algo(-22555,18657,0,1)
        if out != "1101010111110000" or done != 1 or err != 1 or zero != 0 or posv != 0:
            print("test1 with first algo failed")

        out , done , err , zero , posv = self.first_algo(5,18657,0,1)
        if out != "1101010111110000" or done != 1 or err != 1 or zero != 0 or posv != 0:
            print("test2 with first algo failed")

        out , done , err , zero , posv = self.first_algo(5,18657,0,0)
        if out != '0'*16 or done != 0 or err != 1 or zero != 0 or posv != 0:
            print("test3 with first algo failed")

        out , done , err , zero , posv = self.first_algo(5,18657,1,0)
        if out != '0'*16 or done != 1 or err != 0 or zero != 0 or posv != 0:
            print("test4 with first algo failed")

        out , done , err , zero , posv = self.first_algo(5,18657,0,1)
        if out != "0000001011011000" or done != 1 or err != 0 or zero != 0 or posv != 1:
            print("test5 with first algo failed")

        out , done , err , zero , posv = self.first_algo(-5,18657,0,1)
        if out != "1111110100100111" or done != 1 or err != 0 or zero != 0 or posv != 0:
            print("test6 with first algo failed")

        out , done , err , zero , posv = self.first_algo(-5,-14111,0,1)
        if out != "0000001000100111" or done != 1 or err != 0 or zero != 0 or posv != 1:
            print("test7 with first algo failed")

        out , done , err , zero , posv = self.first_algo(-5,0,0,1)
        if out != "0000000000000000" or done != 1 or err != 0 or zero != 1 or posv != 0:
            print("test8 with first algo failed")

        out , done , err , zero , posv = self.first_algo(-5,18657,0,0)
        if out != "0000000000000000" or done != 0 or err != 0 or zero != 0 or posv != 0:
            print("test9 with first algo failed")

        print("first algo tests passed")
    def test_with_sec_algo(self):
        self.err = 0

        out , done , err , zero , posv = self.sec_algo(-22555,18657,0,1)
        if out != "1101010111110000" or done != 1 or err != 1 or zero != 0 or posv != 0:
            print("test1 with sec algo failed")

        out , done , err , zero , posv = self.sec_algo(5,18657,0,1)
        if out != "1101010111110000" or done != 1 or err != 1 or zero != 0 or posv != 0:
            print("test2 with sec algo failed")

        out , done , err , zero , posv = self.sec_algo(5,18657,0,0)
        if out != '0'*16 or done != 0 or err != 1 or zero != 0 or posv != 0:
            print("test3 with sec algo failed")

        out , done , err , zero , posv = self.sec_algo(5,18657,1,0)
        if out != '0'*16 or done != 1 or err != 0 or zero != 0 or posv != 0:
            print("test4 with sec algo failed")

        out , done , err , zero , posv = self.sec_algo(5,18657,0,1)
        if out != "0000001011011000" or done != 1 or err != 0 or zero != 0 or posv != 1:
            print("test5 with sec algo failed")

        out , done , err , zero , posv = self.sec_algo(-5,18657,0,1)
        if out != "1111110100100111" or done != 1 or err != 0 or zero != 0 or posv != 0:
            print("test6 with sec algo failed")

        out , done , err , zero , posv = self.sec_algo(-5,-14111,0,1)
        if out != "0000001000100111" or done != 1 or err != 0 or zero != 0 or posv != 1:
            print("test7 with sec algo failed")

        out , done , err , zero , posv = self.sec_algo(-5,0,0,1)
        if out != "0000000000000000" or done != 1 or err != 0 or zero != 1 or posv != 0:
            print("test8 with sec algo failed")

        out , done , err , zero , posv = self.sec_algo(-5,18657,0,0)
        if out != "0000000000000000" or done != 0 or err != 0 or zero != 0 or posv != 0:
            print("test9 with sec algo failed")
    
        print("sec algo tests passed")

    def test(self):
       self.test_with_operator()
       self.test_with_first_algo()
       self.test_with_sec_algo()
if __name__ == '__main__':
    m = Multiplier()
    m.test()
