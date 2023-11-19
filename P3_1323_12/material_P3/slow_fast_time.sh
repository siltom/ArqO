# Script para P3 ejercicio 1

#!/bin/bash

# inicializar variables
Ninicio=1024
Npaso=1024
Nfinal=16384
fDAT=time_slow_fast.dat
fPNG=time_slow_fast.png

# borrar el fichero DAT y el fichero PNG
rm -f $fDAT fPNG

# generar el fichero DAT vacío
touch $fDAT

echo "Running slow and fast..."
# bucle para N desde P hasta Q 
for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
	echo "N: $N / $Nfinal..."
	
	# ejecutar los programas slow y fast consecutivamente con tamaño de matriz N
	# para cada uno, filtrar la línea que contiene el tiempo y seleccionar la
	# tercera columna (el valor del tiempo). Dejar los valores en variables
	# para poder imprimirlos en la misma línea del fichero de datos
	for i in $(seq 1 1 15); do
		slowTime=$(./slow $N | grep 'time' | awk '{print $3}')
		fastTime=$(./fast $N | grep 'time' | awk '{print $3}')
		echo "$N	$slowTime	$fastTime" >> $fDAT
	done
done

echo "Generating plot..."
# llamar a gnuplot para generar el gráfico y pasarle directamente por la entrada
# estándar el script que está entre "<< END_GNUPLOT" y "END_GNUPLOT"
gnuplot << END_GNUPLOT
set title "Slow-Fast Execution Time"
set ylabel "Execution time (s)"
set xlabel "Matrix Size"
set key right bottom
set grid
set term png
set output "$fPNG"
plot "$fDAT" using 1:2 with lines lw 2 title "slow", \
     "$fDAT" using 1:3 with lines lw 2 title "fast"
replot
quit
END_GNUPLOT
