# Script para P4 ejercicio 3

#!/bin/bash

# inicializar variables
N1=1000
N2=1500 
Npaso=500   
paralLoop=3
fDAT=tablas.dat
 
# borrar el fichero DAT
rm -f $fDAT

# generar el fichero DAT vacío
touch $fDAT

echo "Running Tuples -> ..."
# ejecutar los programas matrix y matrix_par con matrices de tamaño N1, N2
# y cambiando la paralelización de los bucles, así como el número de hilos  

for((N = N1 ; N <= N2 ; N += Npaso)); do
	echo "Matrix size: $N"

	echo "Mult en serie..."
	SerieTime=$(./matrix $N | grep 'time' | awk '{print $3}')
	echo "$N	Serie	$SerieTime" >> $fDAT
	echo "Mult en paralelo..."
	for i in $(seq 1 1 $paralLoop); do
		ParTime1=$(./matrix_par $i 1 $N | grep 'time' | awk '{print $3}')
		ParTime2=$(./matrix_par $i 2 $N | grep 'time' | awk '{print $3}')
		ParTime3=$(./matrix_par $i 3 $N | grep 'time' | awk '{print $3}')
		ParTime4=$(./matrix_par $i 4 $N | grep 'time' | awk '{print $3}')

		SUaux=($SerieTime/$ParTime1)
		SU1=$(echo "scale=10; ${SUaux}"| bc | awk '{print $1}')
		SUaux=($SerieTime/$ParTime2)
		SU2=$(echo "scale=10; ${SUaux}"| bc | awk '{print $1}')
		SUaux=($SerieTime/$ParTime3)
		SU3=$(echo "scale=10; ${SUaux}"| bc | awk '{print $1}')
		SUaux=($SerieTime/$ParTime4)
		SU4=$(echo "scale=10; ${SUaux}"| bc | awk '{print $1}')

		echo "$N	Paral	$ParTime1	$ParTime2	$ParTime3	$ParTime4" >> $fDAT
		echo "$N	SpeedUp	$SU1	$SU2	$SU3	$SU4" >> $fDAT
	done
done
