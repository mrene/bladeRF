#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int main(int argc, char **argv) {
	FILE *f = fopen(argv[1], "r");

	// Read by blocks of 1M samples
	int16_t *samples = malloc(1000000 * sizeof(int16_t));
	size_t read;
	size_t index = 0;
	size_t last_discontinuity = 0;

	struct {
		int16_t re;
		int16_t im;
	} counter = {
		.re = 256
	};

	while((read = fread(samples, sizeof(int16_t), 1000000, f))) {
		for (size_t i = 0; i < read; i += 2) {
			int16_t re = samples[i], 
					im = samples[i+1];


			re = round((float)re/16.0f);
			im = round((float)im/16.0f);

			counter.im = -counter.re;

			if (re != counter.re || im != counter.im) {
				printf("Found discontinuity at index %zu (%d %dj != %d %dj) missing %d samples (%zu since last discontinuity)\n",
					index, re, im, counter.re, counter.im, re - counter.re, index - last_discontinuity);

				last_discontinuity = index;

				counter.re = re;
			}

			if (counter.re < 2047) {
				counter.re++;
			} else {
				counter.re = -2047;
			}

			index++;
		}
	}

	fclose(f);

	return 0;
}