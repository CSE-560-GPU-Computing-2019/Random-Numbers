#include <stdio.h>
#include <math.h>
#include <ctime>
#include <stdlib.h>
#include <iostream>

using namespace std;

#define MAXCHAR 1000
#define PI 3.141592653589793f

typedef unsigned long long llu;


int main(){

    freopen("BoxMullerSerial.txt", "w", stdout);

    float ktime[6], tTime[6];
    int q = 0;
    for(int i = 16; i<=512; i*=2){
        // cout<<"HELLO_1";
        
        int X = 128;
        int Y = i;
        
        llu RAND_N = X*Y;
        FILE *fp = fopen("RANDOMNUMBERS_HT_CPU.txt", "r");

        const clock_t begin_time = clock();

        llu *uniform; 
        double *uniform_normal_host, *gaussian_host;
        uniform = (llu *)malloc(RAND_N * sizeof(llu));
        uniform_normal_host = (double *)malloc(RAND_N * sizeof(double));
        gaussian_host = (double *)malloc(RAND_N * sizeof(double));

        llu num;

        llu counter = 0;
        llu max = 0;

        while (fscanf(fp,"%llu",&num) != EOF && counter < RAND_N){
            if(num > max) max = num;
            // cout<<"HELLO_1";
            uniform[counter] = num;
            // printf("%llu\n", num);
            counter++;
        }

        for(int i = 0; i<counter; i++) uniform_normal_host[i] = uniform[i]/double(max);


        for(llu i = 1; i<RAND_N; i*=2){
            double r = sqrt(-2*log(uniform[i]));
            double theta = 2*PI*uniform[i+1];
            gaussian_host[i] = r*sin(theta);
            gaussian_host[i+1] = r*cos(theta);
            // cout<<"HELLO_2";
        }
        
        free(gaussian_host);
        free(uniform);
        free(uniform_normal_host);
        float runTime = (float)( clock() - begin_time ) /  CLOCKS_PER_SEC;
        printf("Time for generating %llu random numbers on CPU: %fs\n\n", RAND_N, runTime);
        // printf("%f ", runTime);
        
    }

}