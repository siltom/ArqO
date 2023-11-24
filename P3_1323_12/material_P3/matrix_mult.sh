# Script para P3 ejercicio 3

#!/bin/bash

# inicializar variables
P=5
forAux=10
Ninicio=(128+16*$P)
Npaso=256
Nfinal=(2176+16*$P)
#add() { n="$@"; bc <<< "${n// /+}"; }
fDAT=mult.dat
CachConfigM="valgrind --tool=cachegrind --cachegrind-out-file=multMatrix_out.dat"
CachConfigMT="valgrind --tool=cachegrind --cachegrind-out-file=multMatrixT_out.dat"
fPNGcr=mult_cache_read.png
fPNGcw=mult_cache_write.png
fPNGt=mult_time.png

# borrar ficheros DAT y ficheros PNG
rm -f $fDAT fPNGcr fPNG fPNGcw fPNGt

# generar el ficheros DAT vacíos
touch $fDAT
touch "multMatrix_out.dat"
touch "multMatrixT_out.dat"

echo "Running matrix multiplication..."
# bucle para N desde P hasta Q 
for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
	echo "N: $N / $Nfinal..."
	
	matrix=0
	matrixT=0
	# ejecutar los programas slow y fast consecutivamente con tamaño de matriz N
	# para cada uno, filtrar la línea que contiene el tiempo y seleccionar la
	# tercera columna (el valor del tiempo). Dejar los valores en variables
	# para poder imprimirlos en la misma línea del fichero de datos
	for i in $(seq 1 1 $forAux); do
		matrixAux1=$(./matrix $N | grep 'time' | awk '{print $3}')
		matrixAux2=($matrix+$matrixAux1)
		matrix=$(echo "scale=10; ${matrixAux2}"| bc | awk '{print $1}')

		matrixTAux1=$(./matrix_t $N | grep 'time' | awk '{print $3}')
		matrixTAux2=($matrixT+$matrixTAux1)
		matrixT=$(echo "scale=10; ${matrixTAux2}"| bc | awk '{print $1}')
	done

	matrixAux1=($matrix/$forAux)
	matrix=$(echo "scale=10; ${matrixAux1}"| bc | awk '{print $1}')

	matrixTAux1=($matrixT/$forAux)
	matrixT=$(echo "scale=10; ${matrixTAux1}"| bc | awk '{print $1}')

	echo "Media tiempos tamano $N:"
	echo "Matriz		Matriz traspuesta"
	echo "$matrix		$matrixT"

	echo "Comprobando fallos de cache..."
	D1mrMatriz=$($CachConfigM ./matrix $N | awk '/summary/ {print $6}' multMatrix_out.dat)
	D1mwMatriz=$(awk '/summary/ {print $9}' multMatrix_out.dat)
	D1mrMatrizT=$($CachConfigMT ./matrix_t $N | awk '/summary/ {print $6}' multMatrixT_out.dat)
	D1mwMatrizT=$(awk '/summary/ {print $9}' multMatrixT_out.dat)

	echo "$N	$matrix 	$D1mrMatriz		$D1mwMatriz		$matrixT	$D1mrMatrizT	$D1mwMatrizT" >> $fDAT
done


echo "Generating plot..."
    gnuplot << END_GNUPLOT
    set title "Fallos lectura multiplicacion"
    set ylabel "Number of errors"
    set xlabel "Matrix Size"
    set key right top
    set grid
    set term png
    set output "$fPNGcr"
    plot "mult.dat" using 1:3 with lines lw 2 title "matriz", \
         "mult.dat" using 1:6 with lines lw 2 title "matriz traspuesta"
    replot
    quit
END_GNUPLOT

    gnuplot << END_GNUPLOT
    set title "Fallos escritura multiplicacion"
    set ylabel "Number of errors"
    set xlabel "Matrix Size"
    set key left top
    set grid
    set term png
    set output "$fPNGcw"
    plot "mult.dat" using 1:4 with lines lw 2 title "matriz", \
         "mult.dat" using 1:7 with lines lw 2 title "matriz traspuesta"
    replot
    quit
END_GNUPLOT

    gnuplot << END_GNUPLOT
    set title "Tiempos medios multiplicacion"
    set ylabel "Average time"
    set xlabel "Matrix Size"
    set key left top
    set grid
    set term png
    set output "$fPNGt"
    plot "mult.dat" using 1:2 with lines lw 2 title "matriz", \
         "mult.dat" using 1:5 with lines lw 2 title "matriz traspuesta"
    replot
    quit
END_GNUPLOT