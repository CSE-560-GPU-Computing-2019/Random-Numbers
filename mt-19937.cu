#include <shrUtils.h>

void loadMTGPU(const char *fname)
{
    FILE *fd = fopen(fname, "rb");
    if(!fd){
        shrLog("initMTGPU(): failed to open %s\n", fname);
        shrLog("FAILED\n");
        exit(0);
    }
    if( !fread(h_MT, sizeof(h_MT), 1, fd) ){
        shrLog("initMTGPU(): failed to load %s\n", fname);
        shrLog("FAILED\n");
        exit(0);
    }
    fclose(fd);
}

__global__ void gpuRand()
{

}


int main()
{
    shrSetLogFileName ("mt-19337.txt");

    float *d_rand_out, *h_rand_out;

    return 0;
}