#include "types.h"
#include "defs.h"
#include "param.h"
#include "x86.h"
#include "memlayout.h"
#include "mmu.h"
#include "proc.h"
#include "spinlock.h"
#include "semaphore.h"

void
sem_init(struct semaphore *s, int init_value)
{
  /* * WRITE YOUR CODE    */
  s->value = init_value;
  s->p = 0;
}

void
sem_wait(struct semaphore *s)
{
  /* * WRITE YOUR CODE    */ 

  
  acquire(&s->lock);
 
  //decrement the value of semaphore s by one
  s->value--;

  //wait if value of semaphore s is negativee;
  if(s->value < 0){
    
    //for pip block 
    if(s->p && s->p->priority > myproc()->priority){
        s->p->priority = myproc()->priority;
    } 

    sleep(s,&s->lock);
  } 
 
  s->p = myproc();
  release(&s->lock);
  
  /*
  acquire(&s->lock);
 
  //decrement the value of semaphore s by one
  s->value--;

  //wait if value of semaphore s is negativee;
  if(s->value < 0){
    sleep(s, &s->lock);  
  } 
  
  release(&s->lock);
  */


}

void
sem_post(struct semaphore *s)
{
  /* ******************** */
  /* * WRITE YOUR CODE    */
  /* ******************** */

   
  acquire(&s->lock);
  //increment the value of semaphore s by one
  s->value++;
  //if there are one or more threads waiting, wake one;
  if(s->value <= 0){
    wakeup(s);
  }

  if(myproc()->priority < myproc()->prev_priority){
    myproc()->priority = myproc()->prev_priority;
  }
  s->p = 0;//for pip
  release(&s->lock);



  /*
  acquire(&s->lock);
  //increment the value of semaphore s by one
  s->value++;
  //if there are one or more threads waiting, wake one;
  if(s->value <= 0){
    wakeup(s);
  }

  release(&s->lock);
  */

}

void
sem_destroy(struct semaphore *s)
{
  /* ******************** */
  /* * WRITE YOUR CODE    */
  /* ******************** */
  
  
  acquire(&s->lock);
  wakeup(s);
  s->value=0;
  s->p = 0;
  release(&s->lock);

  /*
  acquire(&s->lock);
  wakeup(s);
  s->value=0;
  release(&s->lock);
  */
}
