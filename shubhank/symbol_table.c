#include "symbol_table.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static Symbol *symbol_table = NULL;
int current_scope = 0;
void insert_symbol(const char *name, const char *type, int scope) {
    if (lookup_symbol(name, scope)) return;
    Symbol *s = malloc(sizeof(Symbol));
    s->name = strdup(name);
    s->type = strdup(type);
    s->scope = scope;
    s->next = symbol_table;
    symbol_table = s;
}

Symbol* lookup_symbol(const char *name, int scope) {
    Symbol *s = symbol_table;
    while (s) {
        if (strcmp(s->name, name) == 0 && s->scope <= scope) return s;
        s = s->next;
    }
    return NULL;
}

void print_symbol_table() {
    Symbol* s= symbol_table;
    while(s) {
        printf("%s---%s----%d",s->name,s->type,s->scope);
        s=s->next;
    }
}
