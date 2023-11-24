# Script para P3 ejercicio 3

#!/bin/bash

# inicializar variables
P=5
Ninicio=(128+16*$P)
Npaso=256
Nfinal=(2176+16*$P)
fDAT=mult.dat
#fPNGcr=mult_cache_read.png
#fPNGcw=mult_cache_write.png
#fPNGt=mult_time.png

# borrar el fichero DAT y el fichero PNG
rm -f $fDAT fPNG

# generar el fichero DAT vacío
touch $fDAT

echo "Running matrix multiplication..."
# bucle para N desde P hasta Q 
for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
	echo "N: $N / $Nfinal..."
	
	# ejecutar los programas slow y fast consecutivamente con tamaño de matriz N
	# para cada uno, filtrar la línea que contiene el tiempo y seleccionar la
	# tercera columna (el valor del tiempo). Dejar los valores en variables
	# para poder imprimirlos en la misma línea del fichero de datos
	for i in $(seq 1 1 10); do
		matrix=$(./matrix $N | grep 'time' | awk '{print $3}')
		matrixT=$(./matrix_t $N | grep 'time' | awk '{print $3}')
		echo "$N	$matrix 	$matrixT" >> $fDAT
	done
done