# Script para P4 ejercicio 3

#!/bin/bash

# inicializar variables
forAux=20  
fDAT=tablasPi.dat
 
# borrar el fichero DAT
rm -f $fDAT

# generar el fichero DAT vacío
touch $fDAT

echo "Running tablas Pi -> ..."
# ejecutar los programas matrix y matrix_par con matrices de tamaño N1, N2
# y cambiando la paralelización de los bucles, así como el número de hilos  
SerieTime=0
ParTime1=0
ParTime2=0
ParTime3=0
ParTime4=0
ParTime5=0
ParTime6=0
ParTime7=0

for i in $(seq 1 1 $forAux); do
	TimeAux1=$(./pi_serie | grep 'Tiempo' | awk '{print $2}')
    TimeAux2=($SerieTime+$TimeAux1)
	SerieTime=$(echo "scale=10; ${TimeAux2}"| bc | awk '{print $1}')

	TimeAux1=$(./pi_par1 | grep 'Tiempo' | awk '{print $2}')
    TimeAux2=($ParTime1+$TimeAux1)
	ParTime1=$(echo "scale=10; ${TimeAux2}"| bc | awk '{print $1}')

    TimeAux1=$(./pi_par2 | grep 'Tiempo' | awk '{print $2}')
    TimeAux2=($ParTime2+$TimeAux1)
	ParTime2=$(echo "scale=10; ${TimeAux2}"| bc | awk '{print $1}')

    TimeAux1=$(./pi_par3 | grep 'Tiempo' | awk '{print $2}')
    TimeAux2=($ParTime3+$TimeAux1)
	ParTime3=$(echo "scale=10; ${TimeAux2}"| bc | awk '{print $1}')

    TimeAux1=$(./pi_par4 | grep 'Tiempo' | awk '{print $2}')
    TimeAux2=($ParTime4+$TimeAux1)
	ParTime4=$(echo "scale=10; ${TimeAux2}"| bc | awk '{print $1}')

    TimeAux1=$(./pi_par5 | grep 'Tiempo' | awk '{print $2}')
    TimeAux2=($ParTime5+$TimeAux1)
	ParTime5=$(echo "scale=10; ${TimeAux2}"| bc | awk '{print $1}')

    TimeAux1=$(./pi_par6 | grep 'Tiempo' | awk '{print $2}')
    TimeAux2=($ParTime6+$TimeAux1)
	ParTime6=$(echo "scale=10; ${TimeAux2}"| bc | awk '{print $1}')

    TimeAux1=$(./pi_par7 | grep 'Tiempo' | awk '{print $2}')
    TimeAux2=($ParTime7+$TimeAux1)
	ParTime7=$(echo "scale=10; ${TimeAux2}"| bc | awk '{print $1}')
done

TimeAux1=($SerieTime/$forAux)
SerieTime=$(echo "scale=10; ${TimeAux1}"| bc | awk '{print $1}')
SerieResul=$(./pi_serie | grep 'Resultado' | awk '{print $3}')

TimeAux1=($ParTime1/$forAux)
ParTime1=$(echo "scale=10; ${TimeAux1}"| bc | awk '{print $1}')
ParResul1=$(./pi_par1 | grep 'Resultado' | awk '{print $3}')
SUaux=($SerieTime/$ParTime1)
SU1=$(echo "scale=10; ${SUaux}"| bc | awk '{print $1}')

TimeAux1=($ParTime2/$forAux)
ParTime2=$(echo "scale=10; ${TimeAux1}"| bc | awk '{print $1}')
ParResul2=$(./pi_par2 | grep 'Resultado' | awk '{print $3}')
SUaux=($SerieTime/$ParTime2)
SU2=$(echo "scale=10; ${SUaux}"| bc | awk '{print $1}')

TimeAux1=($ParTime3/$forAux)
ParTime3=$(echo "scale=10; ${TimeAux1}"| bc | awk '{print $1}')
ParResul3=$(./pi_par3 | grep 'Resultado' | awk '{print $3}')
SUaux=($SerieTime/$ParTime3)
SU3=$(echo "scale=10; ${SUaux}"| bc | awk '{print $1}')

TimeAux1=($ParTime4/$forAux)
ParTime4=$(echo "scale=10; ${TimeAux1}"| bc | awk '{print $1}')
ParResul4=$(./pi_par4 | grep 'Resultado' | awk '{print $3}')
SUaux=($SerieTime/$ParTime4)
SU4=$(echo "scale=10; ${SUaux}"| bc | awk '{print $1}')

TimeAux1=($ParTime5/$forAux)
ParTime5=$(echo "scale=10; ${TimeAux1}"| bc | awk '{print $1}')
ParResul5=$(./pi_par5 | grep 'Resultado' | awk '{print $3}')
SUaux=($SerieTime/$ParTime5)
SU5=$(echo "scale=10; ${SUaux}"| bc | awk '{print $1}')

TimeAux1=($ParTime6/$forAux)
ParTime6=$(echo "scale=10; ${TimeAux1}"| bc | awk '{print $1}')
ParResul6=$(./pi_par6 | grep 'Resultado' | awk '{print $3}')
SUaux=($SerieTime/$ParTime6)
SU6=$(echo "scale=10; ${SUaux}"| bc | awk '{print $1}')

TimeAux1=($ParTime7/$forAux)
ParTime7=$(echo "scale=10; ${TimeAux1}"| bc | awk '{print $1}')
ParResul7=$(./pi_par7 | grep 'Resultado' | awk '{print $3}')
SUaux=($SerieTime/$ParTime7)
SU7=$(echo "scale=10; ${SUaux}"| bc | awk '{print $1}')

echo "Resultado     Tiempo medio    Speed Up" >> $fDAT
echo "$SerieResul	$SerieTime  " >> $fDAT
echo "$ParResul1	$ParTime1	$SU1" >> $fDAT
echo "$ParResul2	$ParTime2	$SU2" >> $fDAT
echo "$ParResul3	$ParTime3	$SU3" >> $fDAT
echo "$ParResul4	$ParTime4	$SU4" >> $fDAT
echo "$ParResul5	$ParTime5	$SU5" >> $fDAT
echo "$ParResul6	$ParTime6	$SU6" >> $fDAT
echo "$ParResul7	$ParTime7	$SU7" >> $fDAT




