# Script para P4 ejercicio 2

#!/bin/bash

# inicializar variables
T=140000
Tinicio=30000   #~(0.8*$T)
Tfinal=300000    #~(1.2*$T)
forAux=100
fDAT=tiempos_medios.dat
 
# borrar el fichero DAT
rm -f $fDAT

# generar el fichero DAT vacío
touch $fDAT

echo "Running T comparator -> ..."

SerieTime=0
ParTime=0
# ejecutar los programas pescalar_serie y pescalar_par3 con tamaño de vector T  

# Tamaño de vector = 0.8T
N=$Tinicio
echo "Vector size: $N"
for i in $(seq 1 1 $forAux); do
    SerieTimeAux1=$(./pescalar_serie $N | grep 'Tiempo' | awk '{print $2}')
	SerieTimeAux2=($SerieTime+$SerieTimeAux1)
	SerieTime=$(echo "scale=10; ${SerieTimeAux2}"| bc | awk '{print $1}')

    ParTimeAux1=$(./pescalar_par3 $N | grep 'Tiempo' | awk '{print $2}')
	ParTimeAux2=($ParTime+$ParTimeAux1)
	ParTime=$(echo "scale=10; ${ParTimeAux2}"| bc | awk '{print $1}')
done

SerieTimeAux1=($SerieTime/$forAux)
SerieTime=$(echo "scale=10; ${SerieTimeAux1}"| bc | awk '{print $1}')

ParTimeAux1=($ParTime/$forAux)
ParTime=$(echo "scale=10; ${ParTimeAux1}"| bc | awk '{print $1}')

echo "$N	$SerieTime	$ParTime" >> $fDAT

SerieTime=0
ParTime=0

# Tamaño de vector = T
N=$T
echo "Vector size: $N"
for i in $(seq 1 1 $forAux); do
    SerieTimeAux1=$(./pescalar_serie $N | grep 'Tiempo' | awk '{print $2}')
	SerieTimeAux2=($SerieTime+$SerieTimeAux1)
	SerieTime=$(echo "scale=10; ${SerieTimeAux2}"| bc | awk '{print $1}')

    ParTimeAux1=$(./pescalar_par3 $N | grep 'Tiempo' | awk '{print $2}')
	ParTimeAux2=($ParTime+$ParTimeAux1)
	ParTime=$(echo "scale=10; ${ParTimeAux2}"| bc | awk '{print $1}')
done

SerieTimeAux1=($SerieTime/$forAux)
SerieTime=$(echo "scale=10; ${SerieTimeAux1}"| bc | awk '{print $1}')

ParTimeAux1=($ParTime/$forAux)
ParTime=$(echo "scale=10; ${ParTimeAux1}"| bc | awk '{print $1}')

echo "$N	$SerieTime	$ParTime" >> $fDAT

SerieTime=0
ParTime=0

# Tamaño de vector = 1.2T
N=$Tfinal
echo "Vector size: $N"
for i in $(seq 1 1 $forAux); do
    SerieTimeAux1=$(./pescalar_serie $N | grep 'Tiempo' | awk '{print $2}')
	SerieTimeAux2=($SerieTime+$SerieTimeAux1)
	SerieTime=$(echo "scale=10; ${SerieTimeAux2}"| bc | awk '{print $1}')

    ParTimeAux1=$(./pescalar_par3 $N | grep 'Tiempo' | awk '{print $2}')
	ParTimeAux2=($ParTime+$ParTimeAux1)
	ParTime=$(echo "scale=10; ${ParTimeAux2}"| bc | awk '{print $1}')
done

SerieTimeAux1=($SerieTime/$forAux)
SerieTime=$(echo "scale=10; ${SerieTimeAux1}"| bc | awk '{print $1}')

ParTimeAux1=($ParTime/$forAux)
ParTime=$(echo "scale=10; ${ParTimeAux1}"| bc | awk '{print $1}')

echo "$N	$SerieTime	$ParTime" >> $fDAT







