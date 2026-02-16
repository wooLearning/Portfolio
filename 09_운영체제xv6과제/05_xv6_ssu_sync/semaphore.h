
struct semaphore {

  /* ******************** */
  /* * WRITE YOUR CODE    */
  /* ******************** */
  
  int value;
  struct spinlock lock;

  //prioroity Inheritance protocl
  struct proc *p;
};

extern struct semaphore usema[NLOCK];
