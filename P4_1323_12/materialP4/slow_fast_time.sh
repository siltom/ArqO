# Script para P3 ejercicio 1

#!/bin/bash

# inicializar variables
Ninicio=1024
Npaso=1024
Nfinal=16384
forAux=10
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
	
	slowTime=0
	fastTime=0
	# ejecutar los programas slow y fast consecutivamente con tamaño de matriz N
	# para cada uno, filtrar la línea que contiene el tiempo y seleccionar la
	# tercera columna (el valor del tiempo). Dejar los valores en variables
	# para poder imprimirlos en la misma línea del fichero de datos
	for i in $(seq 1 1 $forAux); do
		slowTimeAux1=$(./slow $N | grep 'time' | awk '{print $3}')
		slowTimeAux2=($slowTime+$slowTimeAux1)
		slowTime=$(echo "scale=10; ${slowTimeAux2}"| bc | awk '{print $1}')

		fastTimeAux1=$(./fast $N | grep 'time' | awk '{print $3}')
		fastTimeAux2=($fastTime+$fastTimeAux1)
		fastTime=$(echo "scale=10; ${fastTimeAux2}"| bc | awk '{print $1}')
	done

	slowTimeAux1=($slowTime/$forAux)
	slowTime=$(echo "scale=10; ${slowTimeAux1}"| bc | awk '{print $1}')

	fastTimeAux1=($fastTime/$forAux)
	fastTime=$(echo "scale=10; ${fastTimeAux1}"| bc | awk '{print $1}')

	echo "$N	$slowTime	$fastTime" >> $fDAT

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
