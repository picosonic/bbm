#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define PWLEN 20

unsigned char lup[]={0x5, 0x0, 0x9, 0x4, 0xD, 0x7, 0x2, 0x6, 0xA, 0xF, 0xC, 0x3, 0x8, 0xb, 0xe, 0x1};

int main(int argc, char **argv)
{
  char inp[]="NMIHPLGKGJDJDJDJDJDH";
  unsigned char a, x, y, seed, stack, onef;
  int i;

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
  x=0;
  seed=x;

  do
  {
    a=inp[x];
    stack=a;
    a+=7;
    a+=seed;
    a=a & 0xf;
    inp[x]=a;
    a=stack;
    seed=a;
    x++;
  } while (x!=0x14);

  // Print decoded hex
  for (i=0; i<PWLEN; i++)
    printf("%.2x ", inp[i]);
  printf("\n");

  // Validate
  x=0;

  do
  {
    y=4;
    a=0;

    do
    {
      a+=inp[x];
      x++;
      y--;
    } while (y!=0);

    a=a & 0xf;
    if (a!=inp[x]) return 1;

    x++;
  } while (x!=0xf);

  a=inp[4];
  a=a<<1;
  onef=a;

  a=inp[9];
  a=a<<1;
  a+=onef;
  onef=a;

  a=inp[14];
  a=a<<1;
  a+=onef;

  x=4;

  do
  {
    a+=inp[14+x];
    x--;
  } while (x!=0);

  a=a & 0xf;

  if (a!=inp[19]) return 1;

  printf("\nPassword is valid\n\n");

  printf("Stage : %d\n", (inp[17] << 4) | inp[2]);
  printf("Score : %c%c%c%c%c%c%c00\n", inp[3]|0x30, inp[13]|0x30, inp[11]|0x30, inp[7]|0x30, inp[15]|0x30, inp[5]|0x30, inp[0]|0x30);

  printf("Remote detonator : %.2x\n", inp[1]);
  printf("Power : %.2x\n", inp[6]);
  printf("Firesuit : %.2x\n", inp[8]);
  printf("Bombs : %.2x\n", inp[10]);
  printf("Speed : %.2x\n", inp[12]);
  printf("DEBUG : %.2x\n", inp[16]);
  printf("No Clip : %.2x\n", inp[18]);

  return 0;
}
