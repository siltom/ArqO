# Definir el inicio y fin de la lista en memoria
.data
lista:  		.word   9, 3, 6, 1, 8, 2, 7, 5, 10, 4	# Lista desordenada
lista_nueva:		.word	0, 0, 0, 0, 0, 0, 0, 0, 0, 0	#Lista ordenada 
n:      		.word   9                   	        # Longitud de la lista
# Definir la ubicacion de memoria para la lista ordenada
.text
main:
	la t4, lista_nueva #Posicion lista_nueva
	la t2, lista	#Source_copia
	li t5, -1 	#Contador copia
	lw s2, n		#Numero de numeros
	j copiar

inicio:
	la t0, lista_nueva 	#T0 valor de memoria de lista 1
	addi t0, t0, -4
	la t3, lista_nueva	#T3 valor de memoria de lista 2
	addi t3, t3, -4
	li t1, -1 	#Contador GRANDE
	
bucle_grande:
	addi t0, t0, 4
	addi t1, t1, 1 	#Aumentar INDICE bucle grande
	addi t2, t1, 1 	#Resetear INCDICE bucle pequeño
	addi t3, t0, 0
	lw a1, 0(t0) 	#Primer numero
	blt t1, s2, bucle_peque
	j fin
	
bucle_peque:
	addi, t3, t3, 4
	addi t2, t2, 1
	lw a2,	0(t3)
	bge a2, a1, cambiar
bucle_peque2:
	ble t2, s2, bucle_peque
	j bucle_grande
	
cambiar:
	sw a2, 0(t0)
	sw a1, 0(t3)
	lw a1, 0(t0)
	lw a2, 0(t3)	
	j bucle_peque2
	
copiar:
	addi t5, t5, 1	#Aumentar contador
	bgt t5, s2, inicio #Bucle
	lw a0, 0(t2)
	sw a0, 0(t4)
	addi t2, t2, 4
	addi t4, t4, 4
	j copiar
	
	
fin:
	
