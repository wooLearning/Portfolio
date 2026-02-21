#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "spinlock.h"
#include "slab.h"

//fixed size
int sizes[NSLAB] = {16, 32, 64, 128, 256, 512, 1024, 2048};


struct {
	struct spinlock lock;
	struct slab slab[NSLAB];
} stable;

void slabinit(){
	/* fill in the blank */
    int i=0, j=0;
    struct slab* s;

     for(i=0; i < NSLAB; i++){

        //struct slab init
        s = &stable.slab[i];

        //fixed size init
        s->size = sizes[i];

        //when init must single page alloc
        s->num_pages = 1;

        // #define PGSIZE          4096    // bytes mapped by a page from mmu.h
        //number of free objects of a slab allocator
        s->num_free_objects = PGSIZE / sizes[i];

        //number of used ojbects of a slab allocator
        s->num_used_objects = 0;

        //number of objects per page
        s->num_objects_per_page = PGSIZE / sizes[i];

        //bitmap: allocation bitmap for a slab allocator
        s->bitmap = kalloc();
        memset(s->bitmap,0,PGSIZE);//init 0 vlaue

        //page alloc max 100 pages s
        s->page[0] = kalloc();// first single page alloc

        for(j=1;j<MAX_PAGES_PER_SLAB;j++){
            s->page[j] = 0;
        }

    }
    //acquire(&stable.lock);
    //block
    //release(&stable.lock);
}

//find smallest poer of 2 greater than equal
unsigned int nextPowerOf2(unsigned int n){
    unsigned count = 0;

    //is for the case where n is 0
    if(n && !(n & (n-1))){
        return n;
    }

    while(n!=0){
        n >>= 1;
        count += 1;
    }

    return 1 << count;

}

char *kmalloc(int size){
	/* fill in the blank */

    char *obj;
    struct slab* s;
    int alloc_size;
    int i,j;
    int bit;
    
    alloc_size = nextPowerOf2(size);

    //alloc range check
    if(alloc_size < sizes[0]) alloc_size = sizes[0];

    for(i = 0; i< NSLAB; i++){ // find size index => i
        if(sizes[i] == alloc_size) break;
    }
    
    //slab table
    s = &stable.slab[i];

    acquire(&stable.lock);

    //limite 100 page
    if(s->num_free_objects == 0){
        if(s->num_pages < MAX_PAGES_PER_SLAB){
            s->page[s->num_pages] = kalloc();
            s->num_pages++;
            s->num_free_objects += s->num_objects_per_page;
        }else {
            release(&stable.lock);
            return 0;
        }
    }

    //slab alloc
    for(i = 0; i < s->num_pages; i++){
        //bit = (s->num_objects_per_page >8) ? i * s->num_objects_per_page: i*8;
        for(j = 0; j < s->num_objects_per_page; j++){
            bit = i * s->num_objects_per_page + j;
            if( (s->bitmap[(bit) >> 3] & (1 << (bit & 7))) == 0 ){
                s->bitmap[(bit) >> 3] |= 1 << (bit & 7);
                s->num_free_objects--;
                s->num_used_objects++;
                obj = s->page[i] + j * s->size;
                release(&stable.lock);
                return obj;
            }
        }
    }

    release(&stable.lock);

	return 0x00;
}

void kmfree(char *addr, int size){
	/* fill in the blank */

    int alloc_size;
    struct slab *s;
    int i,j;
    int obj_idx,bit;
    int isEmpty;

    if(size <= 0 || size > 2048) {
        cprintf("non valid size");
        return;
    }
    alloc_size = nextPowerOf2(size);

    //alloc range check
    if(alloc_size < sizes[0]) alloc_size = sizes[0];

    for(i = 0; i< NSLAB; i++){ // find size index => i
        if(sizes[i] == alloc_size) break;
    }
    
    //slab variable
    s = &stable.slab[i];
   
    acquire(&stable.lock);
    
    //check addr for finding page index => i
    for(i=0;i<s->num_pages;i++){
        if(addr >= s->page[i] && addr < s->page[i] + PGSIZE) break;
    }
    
    //abnormal detection
    if(i == s->num_pages){
        release(&stable.lock);
        return;
    }
    
    //index setting
    obj_idx = (addr - s->page[i]) / s->size;
    bit = i * s->num_objects_per_page + obj_idx;
    
    //already free index abnormal detect
    if( !(s->bitmap[bit>>3] & (1 << (bit & 7))) ){
        release(&stable.lock);
        return;
    }
    
    //bit map update 
    s->bitmap[bit>>3] &= ~(1 << (bit&7));
    s->num_used_objects--;
    s->num_free_objects++;
    
    
    bit -= obj_idx;
    isEmpty = 1;
    for(j=0;j<s->num_objects_per_page;j++){
        if( s->bitmap[(bit+j) >> 3] & (1 << ((bit+j) & 7)) ){
            isEmpty = 0;
            break;
        }
    }
    
    

    if(isEmpty && s->num_pages > 1){
        int last = s->num_pages -1;
        char* old = s->page[i];
        
        if(i != last){
            //page exchange
            s->page[i] = s->page[last];
            s->page[last] = 0;
            
            int per = s->num_objects_per_page;
            for (int k = 0; k < per; k++) {
                int bit_src = last * per + k;
                int bit_dst = i    * per + k;

                int src_byte = bit_src >> 3, src_off = bit_src & 7;
                int dst_byte = bit_dst >> 3, dst_off = bit_dst & 7;

                int bitval = (s->bitmap[src_byte] >> src_off) & 1;

                // dst update 
                if (bitval)  s->bitmap[dst_byte] |=  1 << dst_off;
                else         s->bitmap[dst_byte] &= ~(1 << dst_off);

                /// src clean 
                s->bitmap[src_byte] &= ~(1 << src_off);
            }
            
        } else {
            s->page[last] = 0;
        }
        s->num_pages--;
        s->num_free_objects -= s->num_objects_per_page;
        kfree(old);    
    }

    release(&stable.lock);
}


/* Helper functions */
void slabdump(){
	cprintf("__slabdump__\n");

	struct slab *s;

	cprintf("size\tnum_pages\tused_objects\tfree_objects\n");

	for(s = stable.slab; s < &stable.slab[NSLAB]; s++){
		cprintf("%d\t%d\t\t%d\t\t%d\n", 
			s->size, s->num_pages, s->num_used_objects, s->num_free_objects);
	}
}
//for debug// bitmap print
void slabprint(){
    struct slab *s;
    unsigned char p;
    for(s=stable.slab; s<&stable.slab[NSLAB];s++){
        for(int i=0;i<15;i++){
            p = 0x80;
            for(int j=0;j<8;j++){
                if((s->bitmap[i])& p){
                    cprintf("1");
                }else{
                    cprintf("0");
                }
                p = p>>1;
            }
            cprintf("\t");
        }
        cprintf("\n");
    }
}

int numobj_slab(int slabid)
{
	return stable.slab[slabid].num_used_objects;
}

int numpage_slab(int slabid)
{
	return stable.slab[slabid].num_pages;
}
