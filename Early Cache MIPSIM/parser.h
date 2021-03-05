#pragma once

#include <stdlib.h>
#include <assert.h>
#include <stdint.h>
#include <errno.h>
#include <limits.h>
#include <string.h>
#include <stdio.h>
#include <stdbool.h>

#define WORD_SIZE 4 // Bytes
#define REGISTER_NUM 32
#define MEMORY_WORD_NUM (1024 * 1024)

#define COMMENT_PREFIX '#'

////////////////////////////////////////////////////////
/// Number String to long long int
////////////////////////////////////////////////////////
static inline bool safe_str_to_llong(const char *str, long long int *ret_long)
{
    // reset errno to 0 before call
    errno = 0;

    // call to strtoll assigning return to number
    char *end_ptr;
    long long int number = strtoll(str, &end_ptr, 10);

    // test return to number and errno values
    if (str == end_ptr)
        printf (" number : %lld  invalid  (no digits found, 0 returned)\n", number);
    else if (errno == ERANGE && number == LLONG_MIN)
        printf (" number : %lld  invalid  (underflow occurred)\n", number);
    else if (errno == ERANGE && number == LLONG_MAX)
        printf (" number : %lld  invalid  (overflow occurred)\n", number);
    else if (errno != 0 && number == 0)
        printf (" number : %lld  invalid  (unspecified error occurred)\n", number);
    else{
        assert(errno == 0);
        *ret_long = number;
        return true;
    }

    return false;
}


////////////////////////////////////////////////////////
/// Token Identifiers
////////////////////////////////////////////////////////
static inline bool is_comment(const char *str){
    return str[0] == COMMENT_PREFIX ? true : false;
}

static inline bool is_number(char* str)
{
    char *end_ptr;
    const char *n_ptr = str;

    // call to strtoll assigning return to number
    strtoll(str, &end_ptr, 10);

    return n_ptr != end_ptr ? true : false;
}

static inline bool is_long_within_bounds(char *str, long int l_bound, long int u_bound)
{
    long long int num;
    if(is_number(str) && safe_str_to_llong(str, &num))
        return num >= l_bound && num <= u_bound ? true : false;
    return false;
}


////////////////////////////////////////////////////////
/// Conversion between str <--> binary  & prints
////////////////////////////////////////////////////////
// prints the bits_to_print (least significant bits of a byte)
static inline void print_binary_32bit_or_less_lsb(uint32_t b, uint8_t bits_to_print)
{
    assert(bits_to_print <= 32);
    uint8_t iter = 0;
    for(uint32_t i = 0x80000000; i != 0; i >>= 1){
        if(bits_to_print >= 32 - iter)
            printf("%c", (b & i) ? '1' : '0');
        iter++;
    }
}

static inline void print_uint32_bin_array(uint32_t *array, uint16_t array_size_to_print)
{
    for(int i = 0; i < array_size_to_print; ++i){
        print_binary_32bit_or_less_lsb(array[i], 32);
        printf("\n");
    }
}

// gets a string of 0's and 1's and converts it to binary up to 32 bits and set's it to *bin
static inline void str_to_bin(char* str, uint32_t *bin)
{
    *bin = 0;
    assert(strlen(str) < 33);
    for(int i = 0; i < strlen(str); ++i){
        char c = str[i];
        (*bin) <<= 1;
        if(c == '1'){
            (*bin)++;
        } else{
            assert(c == '0' && "String contains chars other than 0 and 1");
        }
    }
}


////////////////////////////////////////////////////////
/// File parser(s)
////////////////////////////////////////////////////////
// Parses a line of 32 chars w/ 0's and 1's and returns it in binary
static inline uint32_t per_line_binary_parser(char *line)
{
    uint32_t instr = 0;
    line[32] = '\0'; // replace \n with \0
    str_to_bin(line, &instr);
    return instr;
}

static inline uint32_t per_line_decimal_parser(char *line)
{
    long long int value;
    safe_str_to_llong(line, &value);
    int32_t value_32bit = value;
    uint32_t instr;
    memcpy(&instr, &value_32bit, sizeof(int32_t));
    return instr;
}

typedef uint32_t (per_line_parser)(char*);//
static inline int iterate_file(uint32_t *array_to_fill, char* instr_file_path,
                               per_line_parser per_line_func, uint32_t max_slots_to_init)
{
    char *line = NULL;
    size_t len = 0;

//    printf("Loading instructions from file:\n - %s\n", instr_file_path);

    FILE* fp = fopen(instr_file_path, "r");

    if (fp == NULL){
        printf("File: %s not found, parser is exiting \n", instr_file_path);
        exit(EXIT_FAILURE);
    }

    int i = 0;
    while (getline(&line, &len, fp) != -1) {
        if(is_comment(line)) continue;
        array_to_fill[i] = per_line_func(line);
        i++;
        assert(i < max_slots_to_init && "Tried to initialized more than available slots");
    }

    fclose(fp);
    if (line != NULL){
        free(line);
    }

    return i;
}


