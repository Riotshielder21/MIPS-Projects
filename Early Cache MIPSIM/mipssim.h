#pragma once
#include <math.h>
#include "parser.h"

////////////////////////////////////////////////////////
/// Struct Definitions
////////////////////////////////////////////////////////
struct memory_stats_t{
    uint64_t lw_total;
    uint64_t sw_total;

    /// @students: your cache implementation must increment these properly
    uint64_t lw_cache_hits;
    uint64_t sw_cache_hits;
};


struct instr_meta{
    uint32_t instr;
    int immediate; // sing extended
    int opcode;
    uint8_t reg_21_25;
    uint8_t reg_16_20;
    uint8_t reg_11_15;
    uint8_t  type; //
    int function;
    int jmp_offset;
};

struct ctrl_signals {
    // 1-bit signals
    int RegDst;
    int RegWrite;
    int ALUSrcA;

    int MemRead;
    int MemWrite;
    int MemtoReg;

    int IorD;
    int IRWrite;

    int PCWrite;
    int PCWriteCond;

    //2-bit signals
    int ALUOp;
    int ALUSrcB;
    int PCSource;

};

struct pipe_regs {
    int pc;
    int IR;
    int A;
    int B;
    int ALUOut;
    int MDR;
};


struct architectural_state {
    int state;
    uint64_t clock_cycle;
    struct ctrl_signals control;
    struct instr_meta IR_meta;
    struct pipe_regs curr_pipe_regs;
    struct pipe_regs next_pipe_regs;
    int bits_for_cache_tag;
    struct memory_stats_t mem_stats;
    int registers[REGISTER_NUM];
    uint32_t *memory;
};

////////////////////////////////////////////////////////
/// Global Variables
////////////////////////////////////////////////////////
extern char mem_init_path[];
extern char reg_init_path[];
extern uint32_t  cache_size;
extern uint32_t cache_type;
extern struct architectural_state arch_state;


////////////////////////////////////////////////////////
/// Memory Functions
////////////////////////////////////////////////////////
void memory_state_init(struct architectural_state *);
int  memory_read(int address);
void memory_write (int address, int write_data);


static inline void check_after_clock_cycle() { }
static inline void checking_at_the_end(){ }


static inline void instruction_parser(uint32_t *memory,  char* instr_file_path,
                                      uint32_t *registers, char* reg_file_path)
{
    int instr_count = iterate_file(memory, instr_file_path, per_line_binary_parser, MEMORY_WORD_NUM);

    uint32_t *registers_but_zero = &registers[1]; // Init registers from $1 onwards
    int reg_count = iterate_file(registers_but_zero, reg_file_path, per_line_decimal_parser, REGISTER_NUM - 1);

    printf(" ~~~ Loaded Memory   :\n");
    print_uint32_bin_array(memory, instr_count);
    printf(" ~~~ Loaded Registers: (print starts from $1)\n");
    print_uint32_bin_array(registers_but_zero, reg_count);
}



////////////////////////////////////////////////////////
/// Helper Defines & Functions
////////////////////////////////////////////////////////

//Offsets and sizes
#define OPCODE_OFFSET 26
#define OPCODE_SIZE 6 // 6 bits to encode an opcode (26-31)
#define REGISTER_ID_SIZE 5 // 5 bits to encode an opcode
#define IMMEDIATE_OFFSET 0


//Instruction types
#define R_TYPE 1
#define EOP_TYPE 6
#define MEM_TYPE 0
#define BRANCH_TYPE 2
#define JUMP_TYPE 3
#define I_TYPE 4
#define JR_TYPE 7


// OPCODES
#define SPECIAL 0 // 000000
#define ADD 32    // 100000
#define ADDU 33   // 100001
#define ADDI 8    // 001000
#define LW 35     // 100011
#define SW 43     // 101011
#define BEQ  4    // 000100
#define J 2       // 000010
#define SLT 42    // 101010
#define EOP 63    // 111111


// FSM STATES
#define INSTR_FETCH 0
#define DECODE 1
#define MEM_ADDR_COMP 2
#define MEM_ACCESS_LD 3
#define WB_STEP 4
#define MEM_ACCESS_ST 5
#define EXEC 6
#define R_TYPE_COMPL 7
#define BRANCH_COMPL 8
#define JUMP_COMPL 9
#define EXIT_STATE 10
#define I_TYPE_EXEC 11
#define I_TYPE_COMPL 12

// CACHE TYPE
#define CACHE_TYPE_DIRECT 1
#define CACHE_TYPE_FULLY_ASSOC 2
#define CACHE_TYPE_2_WAY 3

static inline void print_cache_stats(struct memory_stats_t *stats){
   if (cache_size == 0) return;
   double sw_hit_rate = stats->sw_cache_hits * 100.0 / stats->sw_total;
   double lw_hit_rate = stats->lw_cache_hits * 100.0 / stats->lw_total;

   uint64_t total_hits = stats->sw_cache_hits + stats->lw_cache_hits;
   uint64_t total_accesses = stats->sw_total+ stats->lw_total;
   double hit_rate =  total_hits * 100.0 / total_accesses;

   printf("ABSOLUTE: cache_hits: %lu/%lu | cache_lw_hits: %lu/%lu | cache_sw_hit_rate: %lu/%lu\n",
                  total_hits, total_accesses, stats->lw_cache_hits, stats->lw_total,  stats->sw_cache_hits, stats->sw_total);

   printf("RATIOS: cache_hit_rate: %.2f%% | cache_lw_hit_rate: %.2f%% | cache_sw_hit_rate: %.2f%%\n",
                  hit_rate, lw_hit_rate, sw_hit_rate);
}

static inline void check_is_valid_reg_id(int reg_id)
{
    assert(reg_id >= 0);
    assert(reg_id < REGISTER_NUM);
}

static inline void check_address_is_word_aligned(int address)
{
    assert(address >= 0);
    assert(address % WORD_SIZE == 0);
    assert(address <= MEMORY_WORD_NUM);
}

// Used to get a sign extended immediate (sign extension from 16 bit to 32)
static inline int get_sign_extended_imm_id(int instr, uint8_t offset)
{
    short int imm = (short int)(instr >> offset);
    return (int) imm;
}

static inline int get_piece_of_a_word(int word, uint8_t start, uint8_t size)
{
    int mask = 1 << size;
    mask--;
    return (word >> start) & mask;
}

static inline void parse_arguments(int argc, const char* argv[])
{
    assert(argc == 5 && "Four arguments are expected in the following order: " &&
           "1. <cache_size> (in bytes, use 0 to disable cache)" &&
           "2. <cache_type> (1: direct mapped, 2: fully associative, 3: 2-way set associative)" &&
           "3. <init_memory_file_path>" &&
           "4. <init_register_file_path>");
    sscanf(argv[1],"%d", &cache_size); // Use cache size to dynamically allocate the size of your cache
    sscanf(argv[2],"%u", &cache_type);
    assert(cache_type == CACHE_TYPE_DIRECT ||
           cache_type == CACHE_TYPE_2_WAY ||
           cache_type == CACHE_TYPE_FULLY_ASSOC);

    sscanf(argv[3],"%s", mem_init_path);
    sscanf(argv[4],"%s", reg_init_path);
    printf("Cache size: %d, Cache type: %d, Mem path: %s, Reg path: %s, \n",
           cache_size, cache_type, mem_init_path, reg_init_path);
}

static inline void arch_state_init(struct architectural_state* arch_state_ptr)
{

    memset(arch_state_ptr, 0, sizeof(struct architectural_state));
    memory_state_init(arch_state_ptr);
    arch_state_ptr->state = INSTR_FETCH;
    // Loads the "binary" into the memory array, and init registers
    instruction_parser(arch_state_ptr->memory, mem_init_path,
                       (uint32_t *) arch_state_ptr->registers, reg_init_path);
}

static inline void memory_stats_init(struct architectural_state *state, int bits_for_cache_tag)
{
    state->mem_stats.sw_total= 0;
    state->mem_stats.lw_total= 0;
    state->mem_stats.lw_cache_hits = 0;
    state->mem_stats.sw_cache_hits = 0;
    state->bits_for_cache_tag = bits_for_cache_tag;
}
