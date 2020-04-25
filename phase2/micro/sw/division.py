class Divider():
    def __init__(self):
        self.number_of_bits = 16
        self.scale_factor = 7
        self.err = 0
        self.out = '0'*16
        self.zero = 0
        self.posv = 0
        self.done = 0

    def subtract(self,a,b):
        b = self.complement(b)
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
    
    def binary_to_decimal(self, binary, len = 16): 
        decimal, i = 0, 0
        while(i < len):
            if(binary[i] == '1'):
                decimal += pow(2, i) 
            i += 1
        return decimal  

    def shift_left(self, s, num = 1):
        for k in range(0, num): 
            str = "" 
            for i in range(1, len(s)): 
                str = str + s[i]
            str = str + '0'
            s = str
        return str
    def reverse(self, s): 
        str = "" 
        for i in s: 
            str = i + str
        return str
    def with_operators(self,a,b,rst,enbl):
        if rst == 1:
            self.out = '0'*16
            self.zero = 0
            self.posv = 0
            self.done = 0
            self.err = 0
            return self.out,self.done,self.err,self.zero,self.posv
        elif enbl == 1 :
            a_neg = 0
            b_neg = 0
            if(a[15]=='1'):
                a_neg = 1
                a = self.reverse(self.complement(self.reverse(a)))
            if(b[15]=='1') :
                b_neg = 1
                b = self.reverse(self.complement(self.reverse(b)))
            a_decimal = self.binary_to_decimal(a)
            a_decimal = a_decimal << self.scale_factor
            b_decimal = self.binary_to_decimal(b)
            res = 0
            
            # Check for divide by zero
            if(b_decimal == 0):
                divide_by_zero = 1
            else:
                divide_by_zero = 0
                res = a_decimal / b_decimal
            
            res_binary = self.reverse(bin(int(res)).replace("0b","").zfill(23))
   
            # Check for overflow
            if res_binary[16:23]!="1111111" and res_binary[16:23]!="0000000":
                ovfl = 1
            else:
                ovfl = 0
            self.err = ovfl or divide_by_zero
            if(a_neg ^ b_neg):
                self.out = self.reverse(self.complement(self.reverse(res_binary[0 : self.number_of_bits])))
            else:
                self.out = res_binary[0 : self.number_of_bits]
            
            if self.out == '0'*16 and self.err == 0:
                self.zero = 1
            else:
                self.zero = 0
            if not (a_neg ^ b_neg) and self.zero == 0 and self.err == 0:
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
            self.done = 0
            self.err = 0
            return self.out,self.done,self.err,self.zero,self.posv
        elif enbl == 1 :
            a_neg = 0
            b_neg = 0
            # Absolute value of inputs
            if(a[15]=='1'):
                a_neg = 1
                a = self.reverse(self.complement(self.reverse(a)))
            if(b[15]=='1') :
                b_neg = 1
                b = self.reverse(self.complement(self.reverse(b)))
            
            a_binary  = a.zfill(23)
            b_binary  = self.reverse(self.reverse(b).zfill(23))
            divider   = 23*'0'
            quotient  = ""
            for i in range(0, 23):
                divider = divider[1:23] + a_binary[22 - i]
                if(self.binary_to_decimal(self.reverse(divider), 23) < self.binary_to_decimal(b_binary, 23)):
                    quotient = quotient + '0'
                else:
                    quotient = quotient + '1'
                    divider = self.reverse(self.subtract(self.reverse(divider), b_binary))
                    
            res_binary = self.reverse(quotient)
            b_decimal =  self.binary_to_decimal(b)
            # Check for divide by zero
            if(b_decimal == 0):
                divide_by_zero = 1
            else:
                divide_by_zero = 0
   
            # Check for overflow
            if res_binary[16:23]!="1111111" and res_binary[16:23]!="0000000":
                ovfl = 1
            else:
                ovfl = 0
            self.err = ovfl or divide_by_zero
            if(a_neg ^ b_neg):
                self.out = self.reverse(self.complement(self.reverse(res_binary[0 : self.number_of_bits])))
            else:
                self.out = res_binary[0 : self.number_of_bits]
            
            if self.out == '0'*16 and self.err == 0:
                self.zero = 1
            else:
                self.zero = 0
            if not (a_neg ^ b_neg) and self.zero == 0 and self.err == 0:
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

        a = "0111111110000000"
        b = "0000000000000010"
        out , done , err , zero , posv = self.with_operators(self.reverse(a),self.reverse(b),0,1)
        if done != 1 or err != 1 or zero != 0 or posv != 0:
            print("with operators: overflow test failed")
            
        a = "0111111110000000"
        b = "0000000000000000"
        out , done , err , zero , posv = self.with_operators(self.reverse(a),self.reverse(b),0,1)
        if done != 1 or err != 1 or zero != 0 or posv != 0:
            print("with operators: divide by zero test failed")
        
        a = "0000000000000101"
        b = "0100100011100001"
        out , done , err , zero , posv = self.with_operators(self.reverse(a),self.reverse(b),1,0)
        if self.reverse(out) != '0'*16 or done != 0 or err != 0 or zero != 0 or posv != 0:
            print("with operators: reset test failed")
        
        a = "0111111110000000"
        b = "0000010100000000"
        out , done , err , zero , posv = self.with_operators(self.reverse(a),self.reverse(b),0,1)
        if self.reverse(out) != "0000110011000000" or done != 1 or err != 0 or zero != 0 or posv != 1:
            print("with operators: positive / positive test failed")
        
        a = "1000000010000000"
        b = "0000001010000000"
        out , done , err , zero , posv = self.with_operators(self.reverse(a),self.reverse(b),0,1)
        if self.reverse(out) != "1110011010000000" or done != 1 or err != 0 or zero != 0 or posv != 0:
            print("with operators: negative / positive test failed")
        
        a = "1000000010000000"
        b = "1111101100000000"
        out , done , err , zero , posv = self.with_operators(self.reverse(a),self.reverse(b),0,1)
        if self.reverse(out) != "0000110011000000" or done != 1 or err != 0 or zero != 0 or posv != 1:
            print("with operators: negative / negative test failed")
        
        a = "0000000000000000"
        b = "1000000010000000"
        out , done , err , zero , posv = self.with_operators(self.reverse(a),self.reverse(b),0,1)
        if self.reverse(out) != "0000000000000000" or done != 1 or err != 0 or zero != 1 or posv != 0:
            print("with operators: zero / number test failed")

        print("test with operators finished")

    def test_with_first_algo(self):
        self.err = 0

        a = "0111111110000000"
        b = "0000000000000010"
        out , done , err , zero , posv = self.first_algo(self.reverse(a),self.reverse(b),0,1)
        if done != 1 or err != 1 or zero != 0 or posv != 0:
            print("first algo: overflow test failed")
            
        a = "0111111110000000"
        b = "0000000000000000"
        out , done , err , zero , posv = self.first_algo(self.reverse(a),self.reverse(b),0,1)
        if done != 1 or err != 1 or zero != 0 or posv != 0:
            print("first algo: divide by zero test failed")
        
        a = "0000000000000101"
        b = "0100100011100001"
        out , done , err , zero , posv = self.first_algo(self.reverse(a),self.reverse(b),1,0)
        if self.reverse(out) != '0'*16 or done != 0 or err != 0 or zero != 0 or posv != 0:
            print("first algo: reset test failed")
        
        a = "0111111110000000"
        b = "0000010100000000"
        out , done , err , zero , posv = self.first_algo(self.reverse(a),self.reverse(b),0,1)
        if self.reverse(out) != "0000110011000000" or done != 1 or err != 0 or zero != 0 or posv != 1:
            print("first algo: positive / positive test failed")
        
        a = "1000000010000000"
        b = "0000001010000000"
        out , done , err , zero , posv = self.first_algo(self.reverse(a),self.reverse(b),0,1)
        if self.reverse(out) != "1110011010000000" or done != 1 or err != 0 or zero != 0 or posv != 0:
            print("first algo: negative / positive test failed")
        
        a = "1000000010000000"
        b = "1111101100000000"
        out , done , err , zero , posv = self.first_algo(self.reverse(a),self.reverse(b),0,1)
        if self.reverse(out) != "0000110011000000" or done != 1 or err != 0 or zero != 0 or posv != 1:
            print("first algo: negative / negative test failed")
        
        a = "0000000000000000"
        b = "1000000010000000"
        out , done , err , zero , posv = self.first_algo(self.reverse(a),self.reverse(b),0,1)
        if self.reverse(out) != "0000000000000000" or done != 1 or err != 0 or zero != 1 or posv != 0:
            print("first algo: zero / number test failed")

        print("test first algo finished")

    def test(self):
        self.test_with_operator()
        self.test_with_first_algo()
    
if __name__ == '__main__':
    m = Divider()
    m.test()