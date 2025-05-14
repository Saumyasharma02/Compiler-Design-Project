#include <stdio.h>

int main() {
    int x;
    int y;
    y=5;

    printf("Enter a number: ");
    scanf("%d", &x);

    if (x > y) {
        printf("x is greater than y\n");
    } else {
        printf("x is less than or equal to y\n");
    }

    int i;
    for (i = 0; i < x; i++) {
        printf("%d\n", i);
    }

    return 0;
}
