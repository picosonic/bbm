#include <stdio.h>
#include <stdlib.h>

// Flip lookup table generator

int main()
{
  int i;

  for (i=0; i<256; i++)
    printf("&%.2x, ", ((i&0x11)<<3) | ((i&0x22)<<1) | ((i&0x44)>>1) | ((i&0x88)>>3));

  return 0;
}
