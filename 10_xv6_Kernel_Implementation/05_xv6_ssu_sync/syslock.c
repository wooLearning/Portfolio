// LOCK system calls.

#include "types.h"
#include "defs.h"
#include "stat.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "semaphore.h"

struct semaphore usema[NLOCK];
int *dict[NLOCK] = {0};
static int find_empty_lock(void);
static int search_lock(int *);

int
sys_sem_init(void)
{
  char *lock_ptr;
  int init_value;
  if (argptr(0, &lock_ptr, sizeof(int)) < 0 || argint(1, &init_value) < 0)
    return -1;

  int *lock_value = (int *)lock_ptr;
  int lock_idx = find_empty_lock(); 
  if (lock_idx != -1)
    dict[lock_idx] = lock_value;
  else {
    cprintf("no lock available\n");
    return -1;
  }

  sem_init(&usema[lock_idx], init_value);
  return 0;
}

int
sys_sem_wait(void)
{
  char *lock_ptr;
  if (argptr(0, &lock_ptr, sizeof(int)) < 0)
    return -1;

  int *lock_value = (int *)lock_ptr;
  int lock_idx = search_lock(lock_value);
  if (lock_idx == -1)
    return -1;

  sem_wait(&usema[lock_idx]);
  return 0;
}

int
sys_sem_post(void)
{ 
  char *lock_ptr;
  if (argptr(0, &lock_ptr, sizeof(int)) < 0)
    return -1;

  int *lock_value = (int *)lock_ptr;
  int lock_idx = search_lock(lock_value);
  if (lock_idx == -1)
    return -1;

  sem_post(&usema[lock_idx]);
  return 0;
}

int
sys_sem_destroy(void)
{
  char *lock_ptr;
  if (argptr(0, &lock_ptr, sizeof(int)) < 0)
    return -1;

  int *lock_value = (int *)lock_ptr;
  int lock_idx = search_lock(lock_value);
  if (lock_idx == -1)
    return -1;

  sem_destroy(&usema[lock_idx]);
  dict[lock_idx] = 0;
  return 0;
}

int
find_empty_lock(void)
{
  for (int i=0; i < NLOCK; i++)
  {
    if (dict[i] == 0)
      return i;
  }
  return -1;
}

int
search_lock(int *value)
{
  for(int i = 0; i < NLOCK; i++)
  {
    if (dict[i] == value)
      return i;
  }
  return -1;
}
