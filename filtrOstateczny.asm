
.eqv BUFF_SIZE 100008
.data
inputPathRequestMsg:		.asciiz	"Input file name:\n"
header: 			.space   54 	
input_file:			.space	128 	
ask_output_msg:			.asciiz	"Output file name:\n"
input_err:			.asciiz "\nInput image not found! Restarting...\n\n"
output_err: 			.asciiz "\nOutput file error! Restarting...\n"
frame_size:			.asciiz "\nPodaj nieparzysty rozmiar ramki od 1 do :"
frame_choose:			.asciiz "Ustawiono: \n"
output_file: 			.space  128	
buff:				.space	BUFF_SIZE
resultBuff:			.space  BUFF_SIZE


.text
main:
	
	#pyta sie o sciezke wejsciowa
	li		$v0, 4			
	la		$a0, inputPathRequestMsg	
	syscall
	
	li		$v0, 8			
	la		$a0, input_file		
	li		$a1, 128		
	syscall
	
	#pyta sie o sciezke wyjsciowa
	li		$v0, 4			
	la		$a0, ask_output_msg	
	syscall
	
	li 		$v0, 8			
	la 		$a0, output_file	
	li 		$a1, 128		
	syscall
	
	# usuwa \n
	li 		$t0, '\n'		
	li 		$t1, 128		
	li 		$t2, 0			

# usuwa pozostale \n
clearPaths:

	li $t0, 0
	li $t1, 0
		
	clearInputPath:
		
		lb $t2, input_file($t0)
		addiu $t0, $t0, 1
		
		bne $t2, '\n' , clearInputPath
	
	#konczy inputPath
	subiu $t0, $t0, 1
	sb $zero, input_file($t0)
	
	clearOutputPath:
		
		lb $t2, output_file($t1)
		addiu $t1, $t1, 1
		
		bne $t2, '\n' , clearOutputPath
	
	#konczy outputPath
	subiu $t1, $t1, 1
	sb $zero, output_file($t1)		
	
descryptFile:
	
	#otwiera plik wejsciowy
	li		$v0, 13		
	la		$a0, input_file	
	li 		$a1, 0		
	li		$a2, 0		
	syscall
	bltz		$v0, wrongInput	
	move		$s0, $v0	
	
	#czyta i zapisuje dane z naglowka
	li		$v0, 14		
	move		$a0, $s0	
	la		$a1, header	
	li		$a2, 54		
	syscall
	

	lw 		$s7, header+18
	mul		$s7, $s7, 3
	
	lw		$s1, header+34	

	#ustawia wielkosc bufora
	li		$s2, BUFF_SIZE
	
	
	#open output file
	li		$v0, 13
	la		$a0, output_file
	li		$a1, 1		
	li		$a2, 0
	syscall
	
	# copy file descriptor
	move		$t2, $v0	
	
	#confirm that file exists 
	bltz		$t2, wrongOutput

	li		$v0, 15	
	move 		$a0, $t2
	la		$a1, header
	addi    	$a2, $zero, 54
	syscall
	
		

getFrame:	
	#prosi o rozmiar ramki
	li		$v0, 4			
	la		$a0, frame_size	
	syscall
	
	move		$t6, $s2
	div		$t6, $t6, $s7
        srl		$t6, $t6, 2
        
	move		$a0, $t6
	li		$v0, 1
	syscall
	
	li		$a0, '\n'
	li		$v0, 11
	syscall
	
	li		$v0, 5
	syscall
	
	move     	$t4, $v0
	
	#koryguje zly rozmiar - musi byc 
	#nieparzysty z podanego przedzialu
	#poniewaz przy wyborze danej ramki
	
	bge		$t4, 1,  lowEdgePos
	li		$t4, 1
	b initLoop
	
lowEdgePos: 
		
	ble		$t4, $t6, highEgdePos
	move		$s6, $t6
	b initLoop
	
	
highEgdePos:

	#czy parzysta
	srl		$t3, $t4, 1
	sll		$t3, $t3, 1
	
	bne     	$t3, $t4, initLoop
	subiu		$t4, $t4 , 1
initLoop:	
	# rozmiar okna
	move		$s6, $t4

	#Informacja o rozmiarze ramki
	li		$v0, 4			
	la		$a0, frame_choose	
	syscall
	
	move		$a0, $t4
	li		$v0, 1
	syscall
	
	li		$a0, '\n'
	li		$v0, 11
	syscall
	
	# czyta pierwszy raz do bufora
	li		$v0, 14		
	move		$a0, $s0	
	la		$a1, buff	
	move		$a2, $s2	
	syscall
	
	# glowny iterator
	move		$t0, $zero
	# iterator po buforze ze zdjeciem
	la		$t1, buff
	# iterator po buforze wynikowym
	la		$s3, resultBuff  
	
	# rozmiar okna/2
	srl		$t3, $s6, 1
	
	# oblicza, ktory bit w buforze 
	# jest ostatnim do analizowania
	
	# ile pelnych wierszy jest w buforze
	divu		$t8, $s2, $s7
	
	# liczbe tych wierszy nalezy zmniejszyc
	# o rozmiar okna /2
	subu		$t8, $t8, $t3
	
	# nalezy policzyc ile lacznie jest pikseli
	# po ktorych mozna iterowac w buforze
	mul		$t8, $t8, $s7
	# trzeba obliczyc adres ostatniego takiego piksela
	# adres_koncowy = poczatek_bufora + po ilu mozna iterowac
	addu		$t8, $t1, $t8
	
	# adres ostatniego elementu w buforze wynikowym
	la		$s4, resultBuff
	addu		$s4, $s4, $s2
	
	# s5 - ostani element w buforze (buff + rozmiarBuff)
	la		$s5, buff
	addu		$s5, $s5, $s2
	
	# t9 - dopelnienie dlugosci wiersza do 4 ( w pixelach)
	
	move		$t9, $s7
	# t9 - wyrazone w pixelach, a nie w kolorach
	# dopelnia dlugosc wiersza do 3*4 w kolorach
	srl		$t9, $s7, 2
	sll		$t9, $t9, 2
	
	subu		$t9, $s7, $t9
	
	beqz		$t9, loop
	li		$a0, 4
	subu		$t9, $a0, $t9	
	
loop:
	
	# wyjdz jesli przetworzono wszystkie pixele

	
	# jesli nadpisano caly bufor wynikowy
	# zapisz ten bufor do obrazka
	bltu		$s3, $s4, doNotSaveToPicture
	
	la 		$t4, resultBuff

	# zajmuje sie paddingiem
padding:
	# nadpisuje zerami konce wiersza
	# zaczyna nadpisywac
	addu		$t4, $t4, $s7
	subu		$t4, $t4, $t9
	
	bge		$t4, $s4, storeResultBuff
	
	move		$a0, $t9
storeZero:

	blez		$a0, padding
	
	subiu		$a0, $a0, 1
	addiu		$t4, $t4, 1
	sb		$zero, ($t4)
	
	b storeZero
	
	
storeResultBuff:
	li		$v0, 15		
	move 		$a0, $t2
	la		$a1, resultBuff
	move		$a2, $s2
	syscall
		
	la		$s3, resultBuff
	
doNotSaveToPicture:
	
	
	# jesli aktualny pixel mozna analizowac
	# to nie nadpisuj bufora = czytaj kolejny bit z bufora
	blt		$t1, $t8, readNewBite
	
	# w przeciwnym wypadku, przepisz koniec bufora na poczatek
	# i nadpisz bufor za ostatnim przepisanym bitem
	
	# s5 - ostani element w buforze (buff + rozmiarBuff)

	# nalezy przepisac tak zeby mozna bylo iterowac po kazdym wierszu
	mul		$t4, $t3, $s7 
	subu		$t1, $t1, $t4 
	
	la		$t4, buff
	li		$t6, 0
cutLastBites:
		
	bgeu		$t1, $s5, writeBuff
	
	lb		$t5, ($t1)
	sb		$t5, ($t4)
	
	addiu		$t4, $t4, 1
	addiu		$t1, $t1, 1
	addiu		$t6, $t6, 1
	b cutLastBites

writeBuff:
	
	
	# nadpisz za ostatnim przepisanym
	li		$v0, 14		
	move		$a0, $s0
	# a1 - buff + ostatni zapisany + 1	
	move		$a1, $t4
	# a2 = s2 -t6
	# wczytaj tyle bitow ile wynosi dlugosc bufora
	# pozmniejszona o ilosc przepisanych bitow
		
	subu		$a2, $s2, $t6
	syscall
	
	# zacznij iterowac za $t3 wierszami
	la		$t1, buff    
	mul		$t4, $t3, $s7
	addu		$t1, $t1, $t4
	
readNewBite:


	# a0 - aktualne minimum
	# a1 - aktualna pozycja wzgledem kolumny
	# a2 - aktualna pozycja wzgledem wiersza
	# s6 - rozmiar okna
	
	li		$a0, 255
	li		$a1, 0
	li		$a2, 0
	
	# pobierz bit z lewego dolnego rogu okna
	# oblicza wartosc tego bitu ze wzoru
	# bit_lewy_dolny = aktualny_bit - (dlugosc_wiersza+3)*[rozmiar_maski/2]
	
	# t7 - lewy dolny bit
	# t1 - aktualny bit
	# s7 - dlugosc wiersza
	# t4 - wyniki tymczasowe
	# t3 - dlugosc maski/2
	
	# dlugosc wiersza + 3
	addiu		$t4, $s7, 3
	# (dlugosc wiersza + 3)* rozmiar maski
	mul		$t4, $t4, $t3
	
	subu		$t7, $t1, $t4
	
analiseInARow:	

	
	# jesli jest poza obrazkiem
	# traktuj jak element wiekszy niz
	# aktualne minimum
	la		$t4, buff
		
	blt		$t7, $t4, newElementIsBigger
	# ostatni element w buforze
	bgt		$t7, $s5, newElementIsBigger
	
	lb		$t5,($t7)
	
	# sprawdz czy nowy element jest wiekszy
	bgt		$t5, $a0, newElementIsBigger
	# jesli jest mniejszy, to zmien minimum
	move		$a0, $t5
	
newElementIsBigger:
	
	# wez kolejny pixel o rozpatrywanym kolorze
	addiu		$t7, $t7, 3
	# zapisz informacje o przejsciu do kolejnego pixela
	addiu		$a1, $a1, 1
	
	# jesli przetworzyles tyle pixeli ile wynosi
	# rozmiar okna, przejdz do kolejnego wiersza
	
	bne		$a1, $s6, analiseInARow
	
	# jesli a1 == s6 przejdz do kolejnego wiersza
	# nalezy zwiekszyc t7 o dlugosc wiersza, odjac szerokosc okna
	# a nastepnie dodac 3 ("nastepny kolor tego samego rodzaju")
	
	addu		$t7, $t7, $s7
	subu		$t7, $t7, $s6
	addiu		$t7, $t7, 3
	
	# zapisz informacje o przejsciu do kolejnego wiersza
	addiu		$a2, $a2, 1
	# wyzeruj licznik pixeli w wierszu
	li		$a1, 0
	
	# jesli nie przetworzyles wszyskich wierszy
	# pozostac w oknie
	bne		$a2, $s6, analiseInARow
	
	sb 		$a0,($s3)
	addi 		$s3,$s3,1

	# zwieksz licznik petli
	addiu		$t0, $t0, 1
	# przejdz do kolejnego bitu w buforze
	addiu		$t1, $t1, 1
	
	bleu		$t0, $s1, loop	
	
	# zapisuje ostani raz i konczy program :/
	
	# czysci koniec bufora
	move		$t0, $s3
clearBuff:
	
	bgtu		$t0, $s4, padLast
	
	sb		$zero, ($t0)
	addiu		$t0, $t0, 1
	
	b clearBuff
	
	la		$t4, resultBuff
	# ostatni raz usuwa padding
padLast:
	
	addu		$t4, $t4, $s7
	
	# usuwanie paddingu w pozostalych przypadkach
	# polegalo na przeszukiwaniu pixeli z calego bufora
	bge		$t4, $s3, storeResultBuffLast
	subu		$t4, $t4, $t9
	move		$a0, $t9
	
storeZeroLast:

	blez		$a0, padLast
	
	subiu		$a0, $a0, 1
	addiu		$t4, $t4, 1
	sb		$zero, ($t4)
	
	b storeZeroLast

storeResultBuffLast:
	# zapisuje bufor koncowy
	li		$v0, 15		
	move 		$a0, $t2
	#la		$a1, buff
	la		$a1, resultBuff
	# zapisz tyle pixeli ile przetworzono dzieki s3
	subu		$a2, $s3, $a1
	addiu		$a2, $a2, 1
	syscall
	
	b leave
	
leave:
	
	#zamknij plik
	move		$a0, $s0		
	li		$v0, 16			
	syscall
	
	li 		$v0, 10
	syscall
	
	
wrongInput:
	#wiadomosc o zlym pliku wejsciowym
	li		$v0, 4			
	la		$a0, input_err		
	syscall
        b		main

wrongOutput:
	#wiadomosc o zlym pliku wyjsciowym
	li		$v0, 4			
	la		$a0, output_err		
	syscall
	b		main


