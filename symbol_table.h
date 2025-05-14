#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

typedef struct Symbol {
    char *name;
    int declared;  // 1 if declared, 0 if not
    char *type;
    struct Symbol *next;
} Symbol;

// Function to create and return a new symbol
Symbol* create_symbol(char *name, char *type);

// Function to insert a symbol into the symbol table
void insert_symbol(char *name, char *type);

// Function to check if a symbol exists in the table
int symbol_exists(char *name);

// Function to mark a symbol as declared
void declare_symbol(char *name);

// Function to print the symbol table
void print_symbol_table();

#endif
