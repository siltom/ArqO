// ----------- Arqo P4-----------------------
// pescalar_serie
//

#include <stdio.h>
#include <stdlib.h>
#include "arqo4.h"

int main( int argc, char *argv[])
{
	float *A=NULL, *B=NULL;
	int t;
	long long k=0;
	struct timeval fin,ini;
	double sum=0;

	if( argc!=2 )
	{
		printf("Error: ./%s <vector size>\n", argv[0]);
		return -1;
	}
	
	t=atoi(argv[1]);

	A = generateVectorOne(t);
	B = generateVectorOne(t);
	if ( !A || !B )
	{
		printf("Error when allocationg vector\n");
		freeVector(A);
		freeVector(B);
		return -1;
	}
	
	gettimeofday(&ini,NULL);
	/* Bloque de computo */
	sum = 0;
	for(k=0;k<t;k++)
	{
		sum = sum + A[k]*B[k];
	}
	/* Fin del computo */
	gettimeofday(&fin,NULL);

	printf("Resultado: %f\n",sum);
	printf("Tiempo: %f\n", ((fin.tv_sec*1000000+fin.tv_usec)-(ini.tv_sec*1000000+ini.tv_usec))*1.0/1000000.0);
	freeVector(A);
	freeVector(B);

	return 0;
}
