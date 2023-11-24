# Script para P3 ejercicio 2

#!/bin/bash

# inicializar variables
P=5
Ninicio=(1024+128*$P)
Npaso=1024
Nfinal=(5120+128*$P)
CachInicio=1024
CachFinal=8192
CachConfigS="valgrind --tool=cachegrind --cachegrind-out-file=slow_out.dat --LL=8192,1,64"
CachConfigF="valgrind --tool=cachegrind --cachegrind-out-file=fast_out.dat --LL=8192,1,64"
fPNGR=cache_lectura.png
fPNGW=cache_escritura.png

# borrar ficheros ficheros PNG
rm -f fPNGR fPNGW
 
# generar el ficheros DAT vacíos
touch "slow_out.dat"
touch "fast_out.dat"

echo "Running cache -> TamCache..."
for ((C = CachInicio ; C <= CachFinal ; C = C*2)); do
    fDAT=cache_$C.dat

    # borrar el fichero DAT
    rm -f $fDAT

    # generar el fichero DAT vacío
    touch $fDAT

	# ejecutar los programas slow y fast con tamaño de matriz N para cada tamaño de 
	# caché, filtrar la línea que contiene la lectura de memoria y seleccionar las
	# columna 6 y 9 (fallos de lectura y escritura en la memoria de datos). Dejar los
    # valores en variables para poder imprimirlos en la misma línea del fichero de datos
	for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
    	echo "Cache size: $C"
        echo "N: $N / $Nfinal..."
		D1mrslow=$($CachConfigS --I1=$C,1,64 --D1=$C,1,64 ./slow $N | awk '/summary/ {print $6}' slow_out.dat)
        D1mwslow=$(awk '/summary/ {print $9}' slow_out.dat)
        D1mrfast=$($CachConfigF --I1=$C,1,64 --D1=$C,1,64 ./fast $N | awk '/summary/ {print $6}' fast_out.dat)
		D1mwfast=$(awk '/summary/ {print $9}' fast_out.dat)
		echo "$N	$D1mrslow   $D1mwslow   $D1mrfast   $D1mwfast" >> $fDAT
	done
done

echo "Generating plot..."
    gnuplot << END_GNUPLOT
    set title "Fallos lectura"
    set ylabel "Number of error(s)"
    set xlabel "Matrix Size"
    set key right top
    set grid
    set term png
    set output "$fPNGR"
    plot "cache_1024.dat" using 1:2 with lines lw 2 title "slow 1024", \
         "cache_2048.dat" using 1:2 with lines lw 2 title "slow 2048", \
         "cache_4096.dat" using 1:2 with lines lw 2 title "slow 4096", \
         "cache_8192.dat" using 1:2 with lines lw 2 title "slow 8192", \
         "cache_1024.dat" using 1:4 with lines lw 2 title "fast 1024", \
         "cache_2048.dat" using 1:4 with lines lw 2 title "fast 2048", \
         "cache_4096.dat" using 1:4 with lines lw 2 title "fast 4096", \
         "cache_8192.dat" using 1:4 with lines lw 2 title "fast 8192"
    replot
    quit
END_GNUPLOT

    gnuplot << END_GNUPLOT
    set title "Fallos escritura"
    set ylabel "Number of error(s)"
    set xlabel "Matrix Size"
    set key left top
    set grid
    set term png
    set output "$fPNGW"
    plot "cache_1024.dat" using 1:3 with lines lw 2 title "slow 1024", \
         "cache_2048.dat" using 1:3 with lines lw 2 title "slow 2048", \
         "cache_4096.dat" using 1:3 with lines lw 2 title "slow 4096", \
         "cache_8192.dat" using 1:3 with lines lw 2 title "slow 8192", \
         "cache_1024.dat" using 1:5 with lines lw 2 title "fast 1024", \
         "cache_2048.dat" using 1:5 with lines lw 2 title "fast 2048", \
         "cache_4096.dat" using 1:5 with lines lw 2 title "fast 4096", \
         "cache_8192.dat" using 1:5 with lines lw 2 title "fast 8192"
    replot
    quit
END_GNUPLOT





