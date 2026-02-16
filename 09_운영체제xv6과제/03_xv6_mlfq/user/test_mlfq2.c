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
	int pid =getpid();
	float dummy = 0;
	int i,j,k;
	printf(1, "=== TEST START ===\n");

	pid = fork();
	if(pid == 0)
	{
			for(k=0; k<5; k++)
			{
				sleep(5);
				pid = fork();
				if(pid == 0)
				{	
					printf(1, "P2 ARRIVED\n");
					for(i=0; i<STOP_POINT; i++)
					{
						for(j=0; j<STOP_POINT; j++)
								dummy += PI*j;
						int lev = getlevel();
						printf(1, "P2 (%s), i = %d, dummy = %x\n", level[lev], i, dummy);
					}
					exit();
				}
				else{
					wait();
				}
			}
			exit();
	}
	else
	{
		for (i=0; i< OUTER_LOOP; i++){    // p1: 20 ~ 30
			for (j=0; j<INNER_LOOP; j++)
					dummy += PI*j;
			int lev = getlevel();
			printf(1, "P1 (%s), i = %d, dummy = %x\n", level[lev], i, dummy);
		}
		wait();
		printf(1, "=== TEST DONE ===\n");
	}
	exit();
}