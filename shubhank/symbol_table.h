typedef struct Symbol {
    char *name;
    char *type;
    int scope;
    struct Symbol *next;
} Symbol;

void insert_symbol(const char *name, const char *type, int scope);
Symbol* lookup_symbol(const char *name, int scope);
void print_symbol_table();
extern int current_scope;
