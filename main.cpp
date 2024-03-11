#include <cstdio>

extern "C" void MyPrintf (const char* string, ...);

int main ()
{
    const char* str = "swaaaag";
    MyPrintf ("Aboba %d %d %h %s %b \n"
              "idwibi %c \n", 100, -100, -15, str, 15, 'f');
    return 0;
}
