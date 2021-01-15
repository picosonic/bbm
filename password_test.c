#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define PWLEN 20

unsigned char lup[]={0x5, 0x0, 0x9, 0x4, 0xD, 0x7, 0x2, 0x6, 0xA, 0xF, 0xC, 0x3, 0x8, 0xb, 0xe, 0x1};

int main(int argc, char **argv)
{
  char inp[]="NMIHPLGKGJDJDJDJDJDH";
  unsigned char a, seed, prev;
  int i, j;

  if (argc==2)
  {
    if (strlen(argv[1])==PWLEN)
      strncpy(inp, argv[1], PWLEN);
  }

  // Print as ASCII
  for (i=0; i<PWLEN; i++)
    printf(" %c ", inp[i]);
  printf("\n");

  // Convert from input chars to password chars
  for (i=0; i<PWLEN; i++)
    inp[i]=lup[inp[i] & 0xf];

  // Decode
  seed=0;

  for (i=0; i<PWLEN; i++)
  {
    prev=inp[i];
    inp[i]=(inp[i]+7+seed) & 0xf;
    seed=prev;
  }

  // Print decoded hex
  for (i=0; i<PWLEN; i++)
    printf("%.2x ", inp[i]);
  printf("\n");

  // Validate first 3 checksums
  for (i=0; i<3; i++)
  {
    a=0;
    
    for (j=0; j<4; j++)
      a=(a+inp[(i*5)+j]) & 0xf;
    
    if (a!=inp[(i*5)+4])
    {
      printf("\nPassword is not valid\n\n");
      return 1;
    }
  }

  // Validate final checksum
  a=(inp[4]*2)+(inp[9]*2)+(inp[14]*2);

  for (i=0; i<4; i++)
    a=(a+inp[15+i]) & 0xf;

  if (a!=inp[19])
  {
    printf("\nPassword is not valid\n\n");
    return 1;
  }

  printf("\nPassword is valid\n\n");

  printf("Stage : %d\n", (inp[17] << 4) | inp[2]);
  printf("Score : %c%c%c%c%c%c%c00\n", inp[3]|0x30, inp[13]|0x30, inp[11]|0x30, inp[7]|0x30, inp[15]|0x30, inp[5]|0x30, inp[0]|0x30);

  printf("Remote detonator : %s\n", inp[1]==0?"False":"True");
  printf("Power : %d\n", inp[6]);
  printf("Firesuit : %s\n", inp[8]==0?"False":"True");
  printf("Bombs : %d\n", inp[10]+1);
  printf("Speed : %d\n", inp[12]);
  printf("DEBUG : %s\n", inp[16]==0?"False":"True");
  printf("No Clip : %s\n", inp[18]==0?"False":"True");

  return 0;
}
