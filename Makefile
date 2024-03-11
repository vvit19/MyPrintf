all: main

main: myprintf.o main.o
		g++ -no-pie myprintf.o main.o -o main

myprintf.o:	myprintf.s
		nasm -f elf64 myprintf.s -o myprintf.o

main.o: main.cpp
		g++ -c main.cpp -o main.o

clean:
		rm *.o
