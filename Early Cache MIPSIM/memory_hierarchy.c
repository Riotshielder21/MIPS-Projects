#include "mipssim.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
int index_bits;
int index_size;
uint32_t cache_type = 0;
 
int cache_block_get(int address, int op){
    
    switch (op){ // this is a simple hybrid function/macro to get bits of words that are commonly used
        case 0:;
            int ind = get_piece_of_a_word(address, arch_state.bits_for_cache_tag + 4, index_bits);
            return ind;
        case 1:;
            int tag = get_piece_of_a_word(address, 4, arch_state.bits_for_cache_tag);
            printf("tag %d\n",tag);
            return tag;
        case 2:;
            int off = get_piece_of_a_word(address, 0, 3);
            printf("offset %d\n",off);
            return off;
    };
};
struct Cache {//cache block struct, represent the tag bits using an integer
    uint16_t index;
    uint16_t tag;
    int valid;
    uint32_t offsetA; //word addressable cache content
    uint32_t offsetB;
    uint32_t offsetC;
    uint32_t offsetD; 
};
struct Cache **cache;
int first_time_run;

void memory_state_init(struct architectural_state* arch_state_ptr) {
    arch_state_ptr->memory = (uint32_t *) malloc(sizeof(uint32_t) * MEMORY_WORD_NUM);
    memset(arch_state_ptr->memory, 0, sizeof(uint32_t) * MEMORY_WORD_NUM);
    if(cache_size == 0){
        // CACHE DISABLED
        memory_stats_init(arch_state_ptr, 0); // WARNING: we initialize for no cache 0
    }else {
        arch_state.mem_stats.lw_cache_hits=0;
        arch_state.mem_stats.sw_cache_hits=0;

        switch (cache_type){
            case CACHE_TYPE_DIRECT:;

                index_bits = log2(cache_size/16);
                index_size = pow(2,index_bits);
                int tag = 32 - index_bits - 4;
                cache = malloc(index_size*sizeof(struct Cache *));//allocate index_size of pointers as array
                
                for (int i = 0; i<index_size; i++){//issue pointer to each item of dynamic array
                    cache[i] = malloc(sizeof(struct Cache));//cache at i is structure Cache
                };
                memory_stats_init(arch_state_ptr, tag);
                first_time_run = 1;
        };
    };
};

// returns data on memory[address / 4]
int memory_read(int address){
    arch_state.mem_stats.lw_total++;
    check_address_is_word_aligned(address);

    if(cache_size == 0){
        // CACHE DISABLED
        return (int) arch_state.memory[address / 4];
    }else{
        // CACHE ENABLED
        switch (cache_type){
            case CACHE_TYPE_DIRECT:;
                struct Cache ***cache_block = &cache;      
                int rindex = cache_block_get(address, 0);
                int rtag = cache_block_get(address, 1);
                int offset = cache_block_get(address, 2);
                int i = 0;
                printf("---------------------------------\n");
                printf("value at address %d: %d\n",address/4, arch_state.memory[address/ 4]);
                
                if (first_time_run == 0){
                    if ((*cache_block)[rindex]->tag == rtag){//check to see if there is a tag match
                        arch_state.mem_stats.lw_cache_hits++;
                        printf("hits now = %d\n", arch_state.mem_stats.lw_cache_hits);
                        switch (offset){
                            case 0:
                                printf("from cache: %d\n",(*cache_block)[rindex]->offsetA);
                                return (*cache_block)[rindex]->offsetA;
                                
                            case 4:
                                printf("from cache: %d\n",(*cache_block)[rindex]->offsetB);
                                return (*cache_block)[rindex]->offsetB;
                                
                            case 8:
                                printf("from cache: %d\n",(*cache_block)[rindex]->offsetC);
                                return (*cache_block)[rindex]->offsetC;
                                
                            case 12:
                                printf("from cache: %d\n",(*cache_block)[rindex]->offsetD);
                                return (*cache_block)[rindex]->offsetD;
                                
                        };
                    };
                    printf("Miss Read In ->\n");
                    (*cache_block)[rindex]->tag == rtag;
                    switch (offset){
                        case 0:
                            (*cache_block)[rindex]->offsetA = arch_state.memory[address / 4];           
                            (*cache_block)[rindex]->offsetB = arch_state.memory[address+4 / 4]; 
                            (*cache_block)[rindex]->offsetC = arch_state.memory[address+8 / 4];
                            (*cache_block)[rindex]->offsetD = arch_state.memory[(address/4)+12];
                            printf("index %d:\n+0:%d\n+4:%d\n+8:%d\n+12:%d\n", rindex, (*cache_block)[rindex]->offsetA, (*cache_block)[rindex]->offsetB, arch_state.memory[address+8 / 4],arch_state.memory[address+12 / 4]);
                        case 4:
                            (*cache_block)[rindex]->offsetA = arch_state.memory[address-4/4];           
                            (*cache_block)[rindex]->offsetB = arch_state.memory[address / 4];
                            (*cache_block)[rindex]->offsetC = arch_state.memory[address+4 / 4];
                            (*cache_block)[rindex]->offsetD = arch_state.memory[address+8 / 4];
                        case 8:
                            (*cache_block)[rindex]->offsetA = arch_state.memory[address-8/4];           
                            (*cache_block)[rindex]->offsetB = arch_state.memory[address-4/4];
                            (*cache_block)[rindex]->offsetC = arch_state.memory[address / 4];
                            (*cache_block)[rindex]->offsetD = arch_state.memory[address+4 / 4];
                        case 12:
                            (*cache_block)[rindex]->offsetA = arch_state.memory[address-12/4]; 
                            (*cache_block)[rindex]->offsetB = arch_state.memory[address-8/4];
                            (*cache_block)[rindex]->offsetC = arch_state.memory[address-4/4];
                            (*cache_block)[rindex]->offsetD = arch_state.memory[address / 4];
                    };
                
                    return (int) arch_state.memory[address / 4];
            }else{
                first_time_run = 0;
                printf("Read In ->\n");
                    (*cache_block)[0]->tag == 0;
                    (*cache_block)[rindex]->offsetA = arch_state.memory[address / 4];           
                    (*cache_block)[rindex]->offsetB = arch_state.memory[address+4 / 4]; 
                    (*cache_block)[rindex]->offsetC = arch_state.memory[address+8 / 4];
                    (*cache_block)[rindex]->offsetD = arch_state.memory[(address/4)+12];
                    printf("index %d:\n+0:%d\n+4:%d\n+8:%d\n+12:%d\n", rindex, (*cache_block)[rindex]->offsetA, (*cache_block)[rindex]->offsetB, arch_state.memory[address+8 / 4],arch_state.memory[address+12 / 4]);
                    return (int) arch_state.memory[address / 4];
            }

            case CACHE_TYPE_2_WAY:;
            case CACHE_TYPE_FULLY_ASSOC:;
        };
            //case 2-way
            //update LRU Policy for 2way  
            //search for index, check for tag
            // return cache value
                

            //case associative
            //update LRU Policy for Assoc

            //while pointer not null
                //search for tag

                //if match
                //return cache value
                
        //if cache miss
            //get the data from memory using address
            //take address and get rid of byte offsetaddress / 4
            //read into the cache at lowest free pointer
            
        //read -- get a block from memory, put it in the cache. 
        //In this class, read always allocates in the cache.//read -- get a block from memory, put it in the cache. In this class, read always allocates in the cache. In real processors, some times read blocks are not placed in the cache for various reasons; however, we don't get into these issues in this class. 
    };  
};

// writes data on memory[address / 4]
void memory_write(int address, int write_data){
    arch_state.mem_stats.sw_total++;
    check_address_is_word_aligned(address);

    if(cache_size == 0){
        // CACHE DISABLED
        arch_state.memory[address / 4] = (uint32_t) write_data;
    }else{
        //CACHE ENABLED
    // write no-allocate will not place a block in the cache unless it's already there.
    // If the block is in the cache, a write will always update it.

        switch (cache_type){
            case CACHE_TYPE_DIRECT:;
                struct Cache ***cache_block = &cache;           
                int windex = cache_block_get(address, 0); 
                int wtag = cache_block_get(address, 1); 
                int offset = cache_block_get(address, 2);
                arch_state.memory[address / 4] = (uint32_t) write_data;//In case there is a miss on write. The content will be written to memory only.
                printf("---------------------------------\n");
                printf("write value: %d\n", arch_state.memory[address/ 4]);
                for (int i = 1; i < index_size; i++) {
                    if ((*cache_block)[i]->index == windex){
                        if ((*cache_block)[i]->tag == wtag){//check to see if there is a tag match
                            arch_state.mem_stats.sw_cache_hits++;
                            switch (offset){
                                case 0:
                                    (*cache_block)[windex]->offsetA = (uint32_t) write_data;
                                    (*cache_block)[windex]->offsetB = arch_state.memory[address+4/4]; 
                                    (*cache_block)[windex]->offsetC = arch_state.memory[address+8/4];
                                    (*cache_block)[windex]->offsetD = arch_state.memory[address+12/4];
                                    printf("+0:%d\n+4:%d\n+8:%d\n+12:%d\n", arch_state.memory[address / 4], arch_state.memory[address+4 / 4],arch_state.memory[address+8 / 4],arch_state.memory[address+12 / 4]);
                                case 4:   
                                    (*cache_block)[windex]->offsetA = arch_state.memory[address-4/4];       
                                    (*cache_block)[windex]->offsetB = (uint32_t) write_data;
                                    (*cache_block)[windex]->offsetC = arch_state.memory[address+4]/4;
                                    (*cache_block)[windex]->offsetD = arch_state.memory[address+8/4];
                                case 8:
                                    (*cache_block)[windex]->offsetA = arch_state.memory[address-8/4];           
                                    (*cache_block)[windex]->offsetB = arch_state.memory[address-4/4];
                                    (*cache_block)[windex]->offsetC = (uint32_t) write_data;
                                    (*cache_block)[windex]->offsetD = arch_state.memory[address+4/4];
                                case 12:
                                    (*cache_block)[windex]->offsetA = arch_state.memory[address-12/4];           
                                    (*cache_block)[windex]->offsetB = arch_state.memory[address-8/4];
                                    (*cache_block)[windex]->offsetC = arch_state.memory[address-4/4];
                                    (*cache_block)[windex]->offsetD = (uint32_t) write_data;
                            };
                            break;
                        };
                    };
                };
                printf("Write Miss");
                break;
            case CACHE_TYPE_FULLY_ASSOC:;
            case CACHE_TYPE_2_WAY:;
        };
    };
};

