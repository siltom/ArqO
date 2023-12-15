#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

#include "arqo4.h"

float **compute(float **m1, float **m2, int n, float **mfinal);

int main( int argc, char *argv[])
{

int n;
float **m1 = NULL;
float **m2 = NULL;
float **mfinal = NULL;
struct timeval fin,ini;


if( argc!=2 ){
	printf("Error: ./%s <matrix size>\n", argv[0]);
	return -1;
} 
n=atoi(argv[1]);
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

printf("\n");

gettimeofday(&ini,NULL);

compute(m1, m2, n, mfinal);

gettimeofday(&fin,NULL);

printf("Execution time: %lf\n", ((fin.tv_sec*1000000+fin.tv_usec)-(ini.tv_sec*1000000+ini.tv_usec))*1.0/1000000.0);

freeMatrix(m1);
freeMatrix(m2);
freeMatrix(mfinal);
return 0;

}

float **compute(float **m1, float **m2, int n, float **mfinal){
    int i, j, k = 0;
    float s = 0;
    
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