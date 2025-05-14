#include <stdio.h>

int main() {
    int num;
    int i;
    i=0;

    printf("Enter a number: ");
    scanf("%d", &num);

    if (num > 0) {
        printf("You entered a positive number\n");
    } else if (num < 0) {
        printf("You entered a negative number\n");
    } else {
        printf("You entered zero\n");
    }

    printf("Counting from 1 to %d\n", num);

    while (i < num) {
        i++;
        printf("%d\n", i);
    }

    return 0;
}
