#include <stdio.h>
#include <stdlib.h>

int main() {
  system("stty raw");

  while (1) {
    int ch = getchar();
    printf("Got char code %d.\n", ch);
    if (ch == 32) break;
  }

  system("stty cooked");
  return 0;
}
