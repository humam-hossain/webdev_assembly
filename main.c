#include <stdio.h>

#include <sys/types.h>         
#include <sys/socket.h>

int main()
{
    printf("AF_INET = %d\nSOCK_STREAM = %d\n", AF_INET, SOCK_STREAM);

    return 0;
}