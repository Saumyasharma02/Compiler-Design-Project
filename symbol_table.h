
#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

typedef struct Parameter {
    char* name;
    char* type;
    struct Parameter* next;
} Parameter;

typedef struct Symbol {
    char* name;
    char* type; // "int", "void", or "function"
    int declared; // 1 if declared, 0 if not
    Parameter* params; // For functions
    int param_count; // Number of parameters
    struct Symbol* next;
    struct Symbol* scope; // For scoping (linked list of symbols in current scope)
} Symbol;

extern Symbol* symbol_table;

Symbol* create_symbol(char* name, char* type);
void insert_symbol(char* name, char* type);
int symbol_exists(char* name);
void declare_symbol(char* name);
void print_symbol_table();
void push_scope();
void pop_scope();
void add_parameter(Symbol* func, char* param_name, char* param_type);
Symbol* lookup_symbol(char* name);

#endif
