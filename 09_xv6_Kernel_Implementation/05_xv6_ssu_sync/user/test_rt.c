#include "types.h"
#include "stat.h"
#include "user.h"

#define INNER_LOOP 1000
#define OUTER_LOOP 20
#define PI 3.14 

int main(int argc, char **argv)
{
	int pid = getpid();
	float dummy = 0;
	int i,j;
	printf(1, "=== TEST START ===\n");
	pid = fork_rt(10);
	if (pid == 0)	/* [PA] Child, its priority must be 10 */
	{
		for (i=0; i<OUTER_LOOP/2; i++)
		{
			for (j=0; j<INNER_LOOP; j++)
				dummy += PI*j;
			printf(1, "PA, i = %d, dummy = %x\n", i, dummy);
		}
			
		pid = fork_rt(11);
		if (pid == 0) /* [PB] child-of-child, its priority must be 11 */
		{
			for (i=0; i<OUTER_LOOP/2; i++)
			{
				for (j=0; j<INNER_LOOP; j++)
					dummy += PI*j;
				printf(1, "PB, i = %d, dummy = %x\n", i, dummy);
			}
		}
		else	/* [PA] Child */
		{
			for (i=0; i<OUTER_LOOP/2; i++)
			{
				for (j=0; j<INNER_LOOP; j++)
					dummy += PI*j;
				printf(1, "PA, i = %d, dummy = %x\n", i, dummy);
			}
			wait();
		}
	} 
	else	/* [PC] its priority must be 20 */
	{
		for (i=0; i<OUTER_LOOP; i++)
		{
			for (j=0; j<INNER_LOOP; j++)
				dummy += PI*j;
			printf(1, "PC, i = %d, dummy = %x\n", i, dummy);
		}
		wait();
		printf(1, "=== TEST DONE ===\n");
	}
	exit();
}

