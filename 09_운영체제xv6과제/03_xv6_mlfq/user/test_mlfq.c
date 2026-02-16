#include "types.h"
#include "stat.h"
#include "user.h"

#define INNER_LOOP 1000000
#define OUTER_LOOP 30
#define STOP_POINT 20
#define PI 3.14 

const char *level[] = {"high", "mid", "low"};

int main(int argc, char **argv)
{
	int pid = getpid();
	float dummy = 0;
	int i,j;
	printf(1, "=== TEST START ===\n");
	pid = fork();
	if (pid == 0)	/* [P2] Child  */
	{
		pid = fork();
		if (pid == 0) /* [P3] child-of-child */
		{
			for (i=0; i<OUTER_LOOP; i++)
			{
				for (j=0; j<INNER_LOOP; j++)
					dummy += PI*j;
				int lev = getlevel();
				printf(1, "P3 (%s), i = %d, dummy = %x\n", level[lev], i, dummy);
			}
		}
		else	/* [P2] Child */
		{
			for (i=0; i<OUTER_LOOP; i++) // 0 ~ 30
			{
				for (j=0; j<INNER_LOOP; j++)
					dummy += PI*j;
				int lev = getlevel();

				printf(1, "P2 (%s), i = %d, dummy = %x\n", level[lev], i, dummy);
			}

			wait();
			exit();
		}
	} 
	else	/* [P1] Parent */
	{
		for (i=0; i<STOP_POINT; i++)    // 0~ 19 loop
		{
			for (j=0; j<INNER_LOOP; j++)
				dummy += PI*j;
			int lev = getlevel();

			printf(1, "P1 (%s), i = %d, dummy = %x\n", level[lev], i, dummy);
		}
	
		pid = fork();
		if(pid == 0){                       /* [P4] child --> high level queue (MLFQ)*/
			printf(1,"P4 ARRIVED\n");
			for (i=0; i<OUTER_LOOP; i++)
			{
				for (j=0; j<INNER_LOOP; j++)
					dummy += PI*j;
				int lev = getlevel();

				printf(1, "P4 (%s), i = %d, dummy = %x\n", level[lev], i, dummy);
			}
			exit();
		}

		else{
			for (i=STOP_POINT; i< OUTER_LOOP; i++){    // p1: 20 ~
				for (j=0; j<INNER_LOOP; j++)
					dummy += PI*j;
				int lev = getlevel();
				
				printf(1, "P1 (%s), i = %d, dummy = %x\n", level[lev], i, dummy);
			}
			wait();
		}
		
		wait();
		printf(1, "=== TEST DONE ===\n");
	}
	exit();
}

