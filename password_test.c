#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define PWLEN 20
#define CHUNK 5

#define OFFS_SCORE_100S 0
#define OFFS_DETONATOR 1
#define OFFS_STAGE_LO 2
#define OFFS_SCORE_100000000S 3
#define OFFS_CXSUM1 4

#define OFFS_SCORE_1000S 5
#define OFFS_POWER 6
#define OFFS_SCORE_100000S 7
#define OFFS_FIRESUIT 8
#define OFFS_CXSUM2 9

#define OFFS_BOMBS 10
#define OFFS_SCORE_1000000S 11
#define OFFS_SPEED 12
#define OFFS_SCORE_10000000S 13
#define OFFS_CXSUM3 14

#define OFFS_SCORE_10000S 15
#define OFFS_DEBUG 16
#define OFFS_STAGE_HI 17
#define OFFS_NOCLIP 18
#define OFFS_CXSUM4 19

unsigned char lup[]={0x5, 0x0, 0x9, 0x4, 0xd, 0x7, 0x2, 0x6, 0xa, 0xf, 0xc, 0x3, 0x8, 0xb, 0xe, 0x1};

int main(int argc, char **argv)
{
  char inp[]="NMIHPLGKGJDJDJDJDJDH";
  unsigned char a, seed;
  int i, j;

  if (argc==2)
  {
    if (strlen(argv[1])==PWLEN)
      strncpy(inp, argv[1], PWLEN);
  }

  // Print as ASCII
  for (i=0; i<PWLEN; i++)
    printf("%c ", inp[i]);
  printf("\n");

  // Convert from input chars to password chars
  for (i=0; i<PWLEN; i++)
    inp[i]=lup[inp[i] & 0xf];

  // Decode
  seed=0;

  for (i=0; i<PWLEN; i++)
  {
    unsigned char prev;

    prev=inp[i];
    inp[i]=(inp[i]+7+seed) & 0xf;
    seed=prev;
  }

  // Print decoded hex
  for (i=0; i<PWLEN; i++)
    printf("%X ", inp[i]);
  printf("\n");

  // Validate first 3 checksums
  for (i=0; i<3; i++)
  {
    a=0;
    
    for (j=0; j<(CHUNK-1); j++)
      a=(a+inp[(i*CHUNK)+j]) & 0xf;
    
    if (a!=inp[(i*CHUNK)+(CHUNK-1)])
    {
      printf("\nPassword is not valid\n\n");

      return 1;
    }
  }

  // Validate final checksum
  a=(inp[OFFS_CXSUM1]+inp[OFFS_CXSUM2]+inp[OFFS_CXSUM3]) * 2;

  for (i=0; i<(CHUNK-1); i++)
    a=(a+inp[(CHUNK*3)+i]) & 0xf;

  if (a!=inp[OFFS_CXSUM4])
  {
    printf("\nPassword is not valid\n\n");

    return 1;
  }

  printf("\nPassword is valid\n\n");

  printf("Stage : %d\n", (inp[OFFS_STAGE_HI] << 4) | inp[OFFS_STAGE_LO]);
  printf("Score : %c%c%c%c%c%c%c00\n", inp[OFFS_SCORE_100000000S]+'0', inp[OFFS_SCORE_10000000S]+'0', inp[OFFS_SCORE_1000000S]+'0', inp[OFFS_SCORE_100000S]+'0', inp[OFFS_SCORE_10000S]+'0', inp[OFFS_SCORE_1000S]+'0', inp[OFFS_SCORE_100S]+'0');

  printf("Remote detonator : %s\n", inp[OFFS_DETONATOR]==0?"False":"True");
  printf("Power : %d\n", inp[OFFS_POWER]);
  printf("Firesuit : %s\n", inp[OFFS_FIRESUIT]==0?"False":"True");
  printf("Bombs : %d\n", inp[OFFS_BOMBS]+1);
  printf("Speed : %d\n", inp[OFFS_SPEED]);
  printf("DEBUG : %s\n", inp[OFFS_DEBUG]==0?"False":"True");
  printf("No Clip : %s\n", inp[OFFS_NOCLIP]==0?"False":"True");

  return 0;
}
