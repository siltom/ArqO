#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <omp.h>

#include "arqo4.h"

float **compute1(float **m1, float **m2, int n, float **mfinal);
float **compute2(float **m1, float **m2, int n, float **mfinal);
float **compute3(float **m1, float **m2, int n, float **mfinal);


int main( int argc, char *argv[])
{

int n, loop, hilos;
float **m1 = NULL;
float **m2 = NULL;
float **mfinal = NULL;
struct timeval fin,ini;


if( argc!= 4){
	printf("Error: ./%s <loop paralelization> <number of threads> <matrix size> \n", argv[0]);
	return -1;
} 
n=atoi(argv[3]);
loop=atoi(argv[1]);
hilos=atoi(argv[2]);

m1=generateMatrix(n);
if( !m1 ){
    fprintf(stdout, "Error generando matriz 1");
	return -1;
}

m2=generateMatrix(n);
if( !m2 ){
    fprintf(stdout, "Error generando matriz 2");
	return -1;
}

mfinal=generateEmptyMatrix(n);
if( !mfinal ){
    printf("Error generando matriz resultado");
	return -1;
}

omp_set_num_threads(hilos);
switch (loop)
{
case 1:
    gettimeofday(&ini,NULL);
    compute1(m1, m2, n, mfinal);
    gettimeofday(&fin,NULL);
    break;
case 2:
    gettimeofday(&ini,NULL);
    compute2(m1, m2, n, mfinal);
    gettimeofday(&fin,NULL);
    break;
case 3:
    gettimeofday(&ini,NULL);
    compute3(m1, m2, n, mfinal);
    gettimeofday(&fin,NULL);
    break;
default:
    printf("Error. Introduce un numero 1, 2, 3\n");
    return -1;
}

printf("Execution time: %lf\n", ((fin.tv_sec*1000000+fin.tv_usec)-(ini.tv_sec*1000000+ini.tv_usec))*1.0/1000000.0);

freeMatrix(m1);
freeMatrix(m2);
freeMatrix(mfinal);
return 0;

}

float **compute1(float **m1, float **m2, int n, float **mfinal){
    int i, j, k = 0;
    float s = 0;
    
    for (i=0; i<n; i++){
        for (j=0; j<n; j++){
            s = 0;
            #pragma omp parallel for reduction(+:s)
            for (k=0; k<n; k++){
                s += m1[i][k] * m2[k][j];
            }
            mfinal[i][j] = s;
        }
    }
    return mfinal;
}

float **compute2(float **m1, float **m2, int n, float **mfinal){
    int i, j, k = 0;
    float s = 0;
    
    for (i=0; i<n; i++){
        #pragma omp parallel for reduction(+:s) private(k)
        for (j=0; j<n; j++){
            s = 0;
            for (k=0; k<n; k++){
                s += m1[i][k] * m2[k][j];
            }
            mfinal[i][j] = s;
        }
    }
    return mfinal;
}

float **compute3(float **m1, float **m2, int n, float **mfinal){
    int i, j, k = 0;
    float s = 0;
    
    #pragma omp parallel for reduction(+:s) private(j,k)
    for (i=0; i<n; i++){
        for (j=0; j<n; j++){
            s = 0;
            for (k=0; k<n; k++){
                s += m1[i][k] * m2[k][j];
            }
            mfinal[i][j] = s;
        }
    }
    return mfinal;
}