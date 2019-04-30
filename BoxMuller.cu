#include <stdio.h>
#include <math.h>
#include <iostream>

using namespace std;

#define MAXCHAR 1000
#define PI 3.141592653589793f

typedef unsigned long long llu;


__device__ double2 Box(double a, double b){
    double r = sqrt(-2*log(a));
    double theta = 2*PI*b;
    double2 xx = make_double2(r*sin(theta), r*cos(theta));
    return xx;
}


__global__ void RandomBM(double *uniform_normal_device, double *gaussian_device){
    const int tid = blockDim.x * blockIdx.x + threadIdx.x;
    double2 uni = Box(uniform_normal_device[tid*2], uniform_normal_device[tid*2 + 1]);
    gaussian_device[tid*2] = uni.x;
    gaussian_device[tid*2 + 1] = uni.y;
}


int main(){
    // freopen("BoxMullerParallel.txt", "w", stdout);

    float ktime[6], tTime[6];
    int q = 0;
    for(int i = 512; i<=512; i*=2){
        printf("%d ", i);
        printf("\n");
        cudaEvent_t start, stop, memstart, memstop;
        cudaEventCreate(&memstart);
        cudaEventCreate(&memstop);
        cudaEventCreate(&start);
        cudaEventCreate(&stop);

        int X = 256;
        int Y = i;
        llu RAND_N = X*Y;
        FILE *fp = fopen("RANDOMNUMBERS_HT_GPU.txt", "r");
        llu num;
        llu *uniform;
        double *uniform_normal_device;
        double *uniform_normal_host;
        double *gaussian_device;
        double *gaussian_host;

        uniform = (llu *)malloc(RAND_N * sizeof(llu));
        uniform_normal_host = (double *)malloc(RAND_N * sizeof(double));
        gaussian_host = (double *)malloc(RAND_N * sizeof(double));

        cudaEventRecord(memstart);

        cudaMalloc((void**)&uniform_normal_device, RAND_N * sizeof(double));
        cudaMalloc((void**)&gaussian_device, RAND_N * sizeof(double));


        llu counter = 0;
        llu max = 0;

        while (fscanf(fp,"%llu",&num) != EOF && counter < RAND_N){
            if(num > max) max = num;
            uniform[counter] = num;
            // printf("%llu\n", num);
            counter++;
        }
        // printf("Counter: %llu\n",counter);
        // printf("MAX: %llu\n",max);

        for(int i = 0; i<counter; i++) uniform_normal_host[i] = uniform[i]/double(max);
        // printf("--------------\n\n");
        // for(int i = 0; i<counter; i++) printf("%.17g\n", uniform_normal_host[i]); 
        // printf("--------------\n\n");

        cudaMemcpy(uniform_normal_device, uniform_normal_host, RAND_N * sizeof(double), cudaMemcpyHostToDevice);

        free(uniform);

        cudaEventRecord(start);
        RandomBM<<<X, Y/2>>>(uniform_normal_device, gaussian_device);
        cudaEventRecord(stop);    

        cudaMemcpy(gaussian_host, gaussian_device, RAND_N * sizeof(double), cudaMemcpyDeviceToHost);

        cudaEventRecord(memstop);

        cudaEventSynchronize(stop);
        cudaEventSynchronize(memstop);


        // WRITE TO A FILE
        FILE *F;
        F = freopen("NORMAL_RANDOMNUMBERS_BOX_GPU.txt", "w", stdout);
        for(int i = 0; i<counter; i++) printf("%.17g\n", gaussian_host[i]); 
        fclose(F);

        float kernelTime, totalTime;
        cudaEventElapsedTime(&kernelTime, start, stop);
        cudaEventElapsedTime(&totalTime, memstart, memstop);
        kernelTime /= 1000.0f;
        totalTime /= 1000.0f;

        cout << "Time taken for " << RAND_N << " random numbers: \n";
        cout << "Kernel Execution time: " << kernelTime << "s\n";
        cout << "Overall Time: " << totalTime << "s\n";
        ktime[q] = kernelTime;
        tTime[q] = totalTime;

        cudaFree(gaussian_device);
        cudaFree(uniform_normal_device);

        free(gaussian_host);
        free(uniform_normal_host);

        fclose(fp);
        q++;
    }
    for (int i = 0; i < 6; ++i) 
        printf("%f ", ktime[i]);
    printf("\n");
    for (int i = 0; i < 6; ++i) 
        printf("%f ", tTime[i]);
    printf("\n");

}