#include "types.h"
#include "stat.h"
#include "user.h"
#include "fcntl.h"

#define MAX 20 
#define LOOP 20 
#define INNERLOOP 5000000

int buffer[MAX];
int fill = 0;
int use = 0;

sem_t empty;
sem_t full;
sem_t mutex;

void put(int pipefd, int value){
  buffer[fill] = value;
  fill = (fill + 1) % MAX;
  write(pipefd, buffer, sizeof(buffer));
}

int get(int pipefd){
  read(pipefd, buffer, sizeof(buffer));
  int tmp = buffer[use];
  use = (use + 1) % MAX;
  return tmp;
}

void producer(int pipefd){
  int dummy = 0;
  for(int i = 0; i < LOOP; i++){
    for(int j=0; j < INNERLOOP; j++)
	    dummy += i*j;
    sem_wait(&empty);
    sem_wait(&mutex);
    put(pipefd, i);
    printf(1, "Producer puts %d\n", i);
    sem_post(&mutex);
    sem_post(&full);
  }
}

void consumer(int pipefd){
	int dummy = 0;
  for(int i = 0; i < LOOP; i++){
    for(int j=0; j < INNERLOOP; j++)
	    dummy += i*j;
    sem_wait(&full);
    sem_wait(&mutex);
    int tmp = get(pipefd);
    printf(1, "Consumer gets %d\n", tmp);
    sem_post(&mutex);
    sem_post(&empty);
  }
}

int main(int argc, char **argv)
{
  int pid = getpid();
  int pipefd[2];

  if(pipe(pipefd) < 0){
	  printf(1, "Failed to create pipe\n");
	  exit();
  }

  sem_init(&empty, MAX);
  sem_init(&full, 0);
  sem_init(&mutex, 1);

  printf(1, "=== TEST START ===\n");
  
  pid = fork();
  if (pid == 0){
    // Producer process (child)
    producer(pipefd[1]);
  }
  else{         
    // Consumer process (parent)
    consumer(pipefd[0]);
    wait();

    sem_destroy(&empty);
    sem_destroy(&full);
    sem_destroy(&mutex);
    printf(1, "=== TEST DONE ===\n");
  }

  close(pipefd[0]);
  close(pipefd[1]);
  exit();

}
