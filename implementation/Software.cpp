#include<iostream>
#include <stdio.h>
#include <math.h>
using namespace std;

const int num_size = 16 , SF = 7;

void two_complement(int * arr,int sz = num_size)
{
    bool test = false;
    for (int k = 0; k < sz; k++)
    {
        if (!test)
            if (arr[k])
                test = true;
        else
            arr[k] = !arr[k];
    }
}
double bin_to_decimal(int * arr)
{
    int j = num_size-1;
    double dec_num = 0;

    for (int i = (num_size - 1 - SF); j >= 0 ; i--,j--)
        dec_num += arr[j] * pow(2, i);

    return dec_num;
}
int main()
{
    int Bin_Numb_1[num_size], Bin_Numb_2[num_size], Bin_add_result[num_size], Bin_multiply_result[2*num_size];
    float dec_num_1 = 0, dec_num_2 = 0, dec_multiply_result = 0, dec_add_result = 0;

    for (int i = 0; i <= 3; i++)
    {

        srand(time(NULL));
        // Generate the 2 numbers
        for (int i = 0; i < num_size; i++)
        {
            Bin_Numb_1[i] = rand() % 2;
            Bin_Numb_2[i] = rand() % 2;
        }

        cout << "First number : ";
        for (int i = num_size - 1; i >= 0; i--)
            cout << Bin_Numb_1[i];
        cout << endl;
        cout << "Second number : ";
        for (int i = num_size - 1; i >= 0; i--)
            cout << Bin_Numb_2[i];
        cout << endl;

        int sign_check = 0;
        int sign1 = 0, sign2 = 0;
        // Get 2's complement if negative
        if (Bin_Numb_1[15])
        {
            two_complement(Bin_Numb_1);
            sign1 = 1;
        }
        if (Bin_Numb_2[15])
        {
            two_complement(Bin_Numb_2);
            sign2 = 1;
        }

        dec_num_1 = bin_to_decimal(Bin_Numb_1);
        dec_num_2 = bin_to_decimal(Bin_Numb_2);

        dec_num_1 = (sign1 ? -dec_num_1 : dec_num_1);
        dec_num_2 = (sign2 ? -dec_num_2 : dec_num_2);

        dec_multiply_result = dec_num_1 * dec_num_2;
        dec_add_result = dec_num_1 + dec_num_2;

        cout << dec_num_1 << " * " << dec_num_2 << " = " << dec_multiply_result << endl;
        cout << dec_num_1 << " + " << dec_num_2 << " = " << dec_add_result << endl;

        int multiply_int_part = floor(abs(dec_multiply_result));
        double multiply_float_part = abs(dec_multiply_result)-multiply_int_part;
        int add_int_part = floor(abs(dec_add_result));
        double add_float_part = abs(dec_add_result)-add_int_part;

        // Set integer part
        for (int i = SF * 2; i< 2 * num_size; i++)
        {
            Bin_multiply_result[i] = multiply_int_part % 2;
            multiply_int_part /= 2;
        }
        for (int i = SF ; i < num_size; i++)
        {
            Bin_add_result[i] = add_int_part % 2;
            add_int_part /= 2;
        }

        // Set float part
        for (int i = 2 * SF - 1; i >= 0; i--)
        {
            double test1 = multiply_float_part * 2;
            int res = floor(test1);
            Bin_multiply_result[i] = res;
            multiply_float_part = test1 - res;
        }
        for (int i = SF - 1; i >= 0; i--)
        {
            double test1 = add_float_part * 2;
            int res = floor(test1);
            Bin_add_result[i] = res;
            add_float_part = test1 - res;
        }

        // Get 2's complement if result is negative
        if (dec_multiply_result < 0)
            two_complement(Bin_multiply_result, 2 * num_size);
        if (dec_add_result < 0)
            two_complement(Bin_add_result, 2 * num_size);

        cout << "Full multiplication result : ";
        for (int i = 2 * num_size - 1; i >= 0; i--)
            cout << Bin_multiply_result[i];
        cout << endl;

        cout << "16-bit multiplication result : ";
        for (int i = (2 * num_size - (num_size - SF) - 1); i >= SF; i--)
            cout << Bin_multiply_result[i];
        cout << endl;

        // Check for multiplication overflow
        int overflow = 0;
        for (int i = (2 * num_size - (num_size - SF) - 1); i<2 * num_size; i++)
            overflow += Bin_multiply_result[i];

        if (overflow == 0 || overflow == (num_size - SF + 1))
            cout << "No overflow occurred in multiplication" << endl;
        else
            cout << "Overflow occurred in multiplication" << endl;

        cout << "Addition result :";
        for (int i = num_size - 1; i >= 0; i--)
            cout << Bin_add_result[i];
        cout << endl;

        // Check for addition overflow
        int integer_bits = num_size - SF;
        int max_integer_number = pow(2, integer_bits);
        if (max_integer_number > dec_add_result)
            cout << "No overflow occurred in addition" << endl;
        else
            cout << "Overflow occurred in addition" << endl;
    }
    system("pause");
}