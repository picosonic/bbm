#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdint.h>

// Melody table (file offset) and ROM Offset
#define TABLE 0x288c
#define TABLEOFFSET 0xbff0

// Number of melodies and channels per melody
#define MELODIES 10
#define CHANNELS 3

// Melody data commands
#define END  0xff
#define LOOP 0xfe

int main(int argc, char **argv)
{
  FILE *fp; // File handle
  int ch; // Input character
  struct stat st; // File metadata structure
  uint8_t *mem; // Memory pointer to loaded ROM
  uint8_t melody; // Current melody number
  uint8_t channel; // Current channel number
  char filename[20]; // Output filename string
  uint16_t offs; // Memory offset for current melody

  // Check for command line arg
  if (argc!=2)
  {
    fprintf(stderr, "Specify input file on command line\n");
    return 1;
  }

  // Check we can read file metadata
  if (stat(argv[1], &st)!=0)
  {
    fprintf(stderr, "Unable to read file metadata\n");
    return 2;
  }

  // Allocate enough memory to hold the whole file
  mem=malloc(st.st_size);

  // Check we got the memory we asked for
  if (mem==NULL)
  {
    fprintf(stderr, "Unable to allocate memory\n");
    return 3;
  }

  // Open the file
  fp=fopen(argv[1], "rb");
  if (fp==NULL)
  {
    fprintf(stderr, "Unable to open the inpu file\n");
    free(mem);
    return 4;
  }

  // Read the whole file into the buffer
  fread(mem, 1, st.st_size, fp);
  fclose(fp);

  // Read each entry from melodies table
  for (melody=0; melody<MELODIES; melody++)
  {
    // Process each of the channels
    for (channel=0; channel<CHANNELS; channel++)
    {
      // Calculate the offset to data for this channel from the melody table
      offs=mem[TABLE+(melody*8)+(channel*2)] | (mem[TABLE+(melody*8)+(channel*2)+1]<<8);

      // Show what we have so far
      printf("%d [%d] : %.4x\n", melody+1, channel+1, offs);

      // Only process offsets which are not zero and are above ROM offset
      if ((offs!=0) && (offs>=TABLEOFFSET))
      {
        // Convert ROM offset into file offset
        offs-=TABLEOFFSET;

        // Generate an output filename for this melody/channel data
        sprintf(filename, "M%.2dC%d.bin", melody+1, channel+1);

        // Open (and truncate) or create the output file
        fp=fopen(filename, "wb+");
        if (fp!=NULL)
        {
          // Loop through the melody data for this channel
          //   until we encounter either a LOOP or END command
          do
          {
            ch=mem[offs++];
            fprintf(fp, "%c", ch);
          } while ((ch!=END) && (ch!=LOOP));

          fclose(fp);
        }
      }
    }

    printf("\n");
  }

  free(mem);

  return 0;
}
