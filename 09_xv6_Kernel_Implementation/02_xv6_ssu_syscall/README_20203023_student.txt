README - Notes on Assignment Modifications

Dear Professor

I would like to inform you of some specific changes I made while working on the assignment.

1. To set the inital priority of the init process to 5, I modified the userinit() in proc.c for case 1.

2. I discovered that in case 6, a child process didn't copy the priority from its parent. So that I modified the fork() in proc.c.

userinit() proc.c : 130
fork() proc.c : 203

Thank you for your attention.

Best regards

[Woo Sang Wook] 20203023
