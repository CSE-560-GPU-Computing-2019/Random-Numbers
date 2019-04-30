#include <stdio.h>
#define MAXCHAR 1000

// correlation test
// pi test

int main(){

    FILE *fp = fopen("random.txt", "r");
    double num;
    // char str[MAXCHAR];

    while (fscanf(fp,"%lf",&num) != EOF)
    printf("%f\n", num);
    fclose(fp);
    
}