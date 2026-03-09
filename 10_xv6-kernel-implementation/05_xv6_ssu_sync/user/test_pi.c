#include "types.h"
#include "stat.h"
#include "user.h"

#define INNER_LOOP 5000000
#define OUTER_LOOP 20
#define PI 3.14

int main(int argc, char **argv)
{
	int pid = getpid();
	float dummy = 0;
	int i, j;
	sem_t s;
	sem_init(&s, 1);	
	printf(1, "=== TEST START ===\n");
	
	pid = fork_rt(12);
	if (pid == 0) /* [PC], its priority must be 12 */
	{
		sem_wait(&s);
		printf(1, "PC holds the lock\n");
		for(i=0; i<OUTER_LOOP/4; i++)
		{
			for(j=0; j<INNER_LOOP; j++)
				dummy += PI*j;
			printf(1, "PC, i = %d, dummy = %x\n", i, dummy);
		}
		pid = fork_rt(11); /* [PB], its priority must be 11 */
		if (pid == 0)
		{
			dummy = 0;
			for(i=0; i<OUTER_LOOP/4; i++)
			{
				for(j=0; j<INNER_LOOP; j++)
					dummy += PI*j;
				printf(1, "PB, i = %d, dummy = %x\n", i, dummy);
			}
			pid = fork_rt(10); /* [PA], its priority must be 10 */
			if (pid == 0)
			{
				dummy = 0;
				for(i=0; i<OUTER_LOOP/10; i++)
				{
					for(j=0; j<INNER_LOOP; j++)
						dummy += PI*j;
					printf(1, "PA, i = %d, dummy = %x\n", i, dummy);
				}
        printf(1, "PA tries to hold the lock\n");
				sem_wait(&s);
				printf(1, "PA holds the lock\n");
				for(i=OUTER_LOOP/10; i<OUTER_LOOP/2; i++)
				{
					for(j=0; j<INNER_LOOP; j++)
						dummy += PI*j;
					printf(1, "PA, i = %d, dummy = %x\n", i, dummy);
				}
				printf(1, "PA releases the lock\n");
				sem_post(&s);
				wait();
			}
			else /* [PB] */
			{
				for(i=OUTER_LOOP/4; i<OUTER_LOOP/2; i++)
				{
					for(j=0; j<INNER_LOOP; j++)
						dummy += PI*j;
					printf(1, "PB, i = %d, dummy = %x\n", i, dummy);
				}
				wait();
			}
		}
		else /* [PC] */
		{
			for(i=OUTER_LOOP/4; i<OUTER_LOOP/2 - OUTER_LOOP/10; i++)
			{
				for(j=0; j<INNER_LOOP; j++)
					dummy += PI*j;
				printf(1, "PC, i = %d, dummy = %x\n", i, dummy);
			}
			printf(1, "PC releases the lock\n");
			sem_post(&s);

			for(i=OUTER_LOOP/2-OUTER_LOOP/10; i<OUTER_LOOP/2; i++){
				for(j=0; j<INNER_LOOP; j++)
					dummy += PI*j;
				printf(1, "PC, i = %d, dummy = %x\n", i, dummy);
			}
			wait();
		}
	}
	wait();
	exit();
}
