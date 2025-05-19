#include "symbol_table.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

Symbol* symbol_table = NULL;
Symbol* current_scope = NULL;

Symbol* create_symbol(char* name, char* type) {
    Symbol* new_symbol = (Symbol*)malloc(sizeof(Symbol));
    new_symbol->name = strdup(name);
    new_symbol->type = strdup(type);
    new_symbol->declared = 0;
    new_symbol->params = NULL;
    new_symbol->param_count = 0;
    new_symbol->next = NULL;
    new_symbol->scope = NULL;
    return new_symbol;
}

void insert_symbol(char* name, char* type) {
    Symbol* new_symbol = create_symbol(name, type);
    new_symbol->scope = current_scope;
    new_symbol->next = symbol_table;
    symbol_table = new_symbol;
}

int symbol_exists(char* name) {
    Symbol* current = symbol_table;
    while (current != NULL) {
        if (strcmp(current->name, name) == 0 && current->scope == current_scope) {
            return 1;
        }
        current = current->next;
    }
    return 0;
}

Symbol* lookup_symbol(char* name) {
    Symbol* current = symbol_table;
    while (current != NULL) {
        if (strcmp(current->name, name) == 0) {
            return current;
        }
        current = current->next;
    }
    return NULL;
}

void declare_symbol(char* name) {
    Symbol* current = symbol_table;
    while (current != NULL) {
        if (strcmp(current->name, name) == 0 && current->scope == current_scope) {
            current->declared = 1;
            return;
        }
        current = current->next;
    }
}

void add_parameter(Symbol* func, char* param_name, char* param_type) {
    Parameter* param = (Parameter*)malloc(sizeof(Parameter));
    param->name = strdup(param_name);
    param->type = strdup(param_type);
    param->next = func->params;
    func->params = param;
    func->param_count++;
}

void push_scope() {
    Symbol* new_scope = (Symbol*)malloc(sizeof(Symbol));
    new_scope->name = strdup("scope");
    new_scope->type = strdup("scope");
    new_scope->declared = 0;
    new_scope->params = NULL;
    new_scope->param_count = 0;
    new_scope->next = NULL;
    new_scope->scope = current_scope;
    current_scope = new_scope;
}

void pop_scope() {
    Symbol* current = symbol_table;
    while (current != NULL && current->scope == current_scope) {
        current->scope = NULL; // Mark as out of scope
        current = current->next;
    }
    if (current_scope) {
        Symbol* temp = current_scope;
        current_scope = current_scope->scope;
        free(temp->name);
        free(temp->type);
        free(temp);
    }
}

void print_symbol_table() {
    Symbol* current = symbol_table;
    printf("Symbol Table:\n");
    while (current != NULL) {
        printf("Name: %s, Type: %s, Declared: %s, Scope: %p",
               current->name, current->type, current->declared ? "Yes" : "No", (void*)current->scope);
        if (strcmp(current->type, "function") == 0) {
            printf(", Parameters: ");
            Parameter* param = current->params;
            while (param) {
                printf("%s(%s) ", param->name, param->type);
                param = param->next;
            }
        }
        printf("\n");
        current = current->next;
    }
}