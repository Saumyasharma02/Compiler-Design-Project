#include "symbol_table.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

Symbol *symbol_table = NULL;

// Function to create and return a new symbol
Symbol* create_symbol(char *name, char *type) {
    Symbol *new_symbol = (Symbol *) malloc(sizeof(Symbol));
    new_symbol->name = strdup(name);
    new_symbol->type = strdup(type);  // Store the type of the symbol
    new_symbol->declared = 0;  // Initially not declared
    new_symbol->is_function = 0;
    new_symbol->param_count = 0;
    new_symbol->next = NULL;
    return new_symbol;
}
// Function to insert a symbol into the symbol table
void insert_symbol(char *name, char *type) {
    Symbol *new_symbol = create_symbol(name, type);
    new_symbol->next = symbol_table;
    symbol_table = new_symbol;
}

// Function to check if a symbol exists in the table
int symbol_exists(char *name) {
    Symbol *current = symbol_table;
    while (current != NULL) {
        if (strcmp(current->name, name) == 0) {
            return 1;  // Symbol exists
        }
        current = current->next;
    }
    return 0;  // Symbol doesn't exist
}

// Function to mark a symbol as declared
void declare_symbol(char *name) {
    Symbol *current = symbol_table;
    while (current != NULL) {
        if (strcmp(current->name, name) == 0) {
            current->declared = 1;
            return;
        }
        current = current->next;
    }
}

// Function to print the symbol table
void print_symbol_table() {
    Symbol *current = symbol_table;
    printf("Symbol Table:\n");
    while (current != NULL) {
        printf("Name: %s, Type: %s, Declared: %s\n",
            current->name,
            current->type,
            current->declared ? "Yes" : "No");
        current = current->next;
    }
}

void insert_function(char *name, char *return_type, int param_count) {
    if (symbol_exists(name)) return;  // Prevent duplicate insertions
    Symbol *f = create_symbol(name, return_type);
    f->is_function = 1;
    f->param_count = param_count;
    f->declared = 1;
    f->next = symbol_table;
    symbol_table = f;
}

Symbol* get_symbol(char *name) {
    Symbol *current = symbol_table;
    while (current != NULL) {
        if (strcmp(current->name, name) == 0) {
            return current;
        }
        current = current->next;
    }
    return NULL;
}
