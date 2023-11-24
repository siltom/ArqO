#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

#include "arqo3.h"


tipo **compute(tipo **m1, tipo **m2, int n, tipo **mtras, tipo **mfinal);

int main( int argc, char *argv[])
{

int i, j = 0;
int n;
tipo **m1 = NULL;
tipo **m2 = NULL;
tipo **mfinal = NULL;
tipo **mtras = NULL;
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


for (i=0; i<n; i++){
    for (j=0; j<n; j++){
        fprintf(stdout, "%f    ", m1[i][j]);
    }
    printf("\n");
}
printf("\n");

m2=generateMatrix(n);
if( !m2 ){
    fprintf(stdout, "Error generando matriz 2");
	return -1;
}

for (i=0; i<n; i++){
    for (j=0; j<n; j++){
        fprintf(stdout, "%f    ", m2[i][j]);
    }
    printf("\n");
}
printf("\n");

mfinal=generateEmptyMatrix(n);
if( !mfinal ){
    printf("Error generando matriz resultado");
	return -1;
}


mtras=generateEmptyMatrix(n);
if( !mtras ){
    printf("Error generando matriz traspuesta");
	return -1;
}


gettimeofday(&ini,NULL);

compute(m1, m2, n, mtras, mfinal);

gettimeofday(&fin,NULL);
printf("Execution time: %lf\n", ((fin.tv_sec*1000000+fin.tv_usec)-(ini.tv_sec*1000000+ini.tv_usec))*1.0/1000000.0);

printf("Matriz resultante:\n");	
for (i=0; i<n; i++){
    for (j=0; j<n; j++){
        printf("%f    ", mfinal[i][j]);
    }
    printf("\n");
}
printf("\n");

freeMatrix(m1);
freeMatrix(m2);
freeMatrix(mtras);
freeMatrix(mfinal);
return 0;

}

tipo **compute(tipo **m1, tipo **m2, int n, tipo **mtras, tipo **mfinal){
    int i, j, k = 0;
    int s = 0;

    for (i=0; i<n; i++){
        for (j=0; j<n; j++){
            mtras[j][i] = m2[i][j];
        }
    }
    
    for (i=0; i<n; i++){
        for (j=0; j<n; j++){
            s = 0;
            for (k=0; k<n; k++){
                s += m1[i][k] * mtras[k][j];
            }
            mfinal[i][j] = s;
        }
    }
    return mfinal;
}