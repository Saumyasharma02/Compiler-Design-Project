%{
#include "symbol_table.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylineno;
extern FILE *yyin;
extern char *yytext;

void yyerror(const char* s);
int yylex(void);

// TAC structure
typedef struct {
    char* result;
    char* op;
    char* arg1;
    char* arg2;
} TAC;

TAC tac_list[10000];
int tac_count = 0;
int temp_count = 0;
int label_count = 0;
char* current_function = NULL;

char* new_temp() {
    char* temp = malloc(10);
    sprintf(temp, "t%d", temp_count++);
    return temp;
}

char* new_label() {
    char* label = malloc(10);
    sprintf(label, "L%d", label_count++);
    return label;
}

void emit_tac(char* result, char* op, char* arg1, char* arg2) {
    tac_list[tac_count].result = result ? strdup(result) : NULL;
    tac_list[tac_count].op = op ? strdup(op) : NULL;
    tac_list[tac_count].arg1 = arg1 ? strdup(arg1) : NULL;
    tac_list[tac_count].arg2 = arg2 ? strdup(arg2) : NULL;
    tac_count++;
}

void print_single_tac(FILE *out, TAC *t) {
    if (t->op && strcmp(t->op, "func") == 0) {
        fprintf(out, "func %s\n", t->arg1 ? t->arg1 : "");
    } else if (t->op && strcmp(t->op, "endfunc") == 0) {
        fprintf(out, "endfunc %s\n", t->arg1 ? t->arg1 : "");
    } else if (t->op && strcmp(t->op, "label") == 0) {
        fprintf(out, "%s: label\n", t->result ? t->result : "");
    } else if (t->op && strcmp(t->op, "goto") == 0) {
        fprintf(out, "goto %s\n", t->arg1 ? t->arg1 : "");
    } else if (t->op && strcmp(t->op, "ifz") == 0) {
        fprintf(out, "ifz %s %s\n", t->arg1 ? t->arg1 : "", t->arg2 ? t->arg2 : "");
    } else if (t->op && strcmp(t->op, "printf") == 0) {
        fprintf(out, "printf %s%s%s\n", t->arg1 ? t->arg1 : "",
                t->arg2 ? " " : "", t->arg2 ? t->arg2 : "");
    } else if (t->op && strcmp(t->op, "scanf") == 0) {
        fprintf(out, "%s = scanf %s\n", t->result ? t->result : "", t->arg1 ? t->arg1 : "");
    } else if (t->op && strcmp(t->op, "return") == 0) {
        fprintf(out, "return %s\n", t->arg1 ? t->arg1 : "");
    } else if (t->op && strcmp(t->op, "declare") == 0) {
        fprintf(out, "%s: declare %s\n", t->result ? t->result : "", t->arg1 ? t->arg1 : "");
    } else if (t->op && strcmp(t->op, "=") == 0 && t->arg2 == NULL) {
        // Simple assignment like t0 = 10
        fprintf(out, "%s = %s\n", t->result ? t->result : "", t->arg1 ? t->arg1 : "");
    } else if (t->result) {
        // General format: result = arg1 op arg2
        fprintf(out, "%s = %s %s %s\n", t->result ? t->result : "",
                t->arg1 ? t->arg1 : "", t->op ? t->op : "",
                t->arg2 ? t->arg2 : "");
    } else {
        // Fallback
        fprintf(out, "%s %s %s\n", t->arg1 ? t->arg1 : "",
                t->op ? t->op : "", t->arg2 ? t->arg2 : "");
    }
}


void print_tac() {
    printf("\nThree-Address Code:\n");
    for (int i = 0; i < tac_count; i++) {
        print_single_tac(stdout, &tac_list[i]);
    }
}

void print_tac_to_file(const char *filename) {
    FILE *file = fopen(filename, "w");
    if (!file) {
        perror("Failed to open file");
        return;
    }

    fprintf(file, "Three-Address Code:\n");
    for (int i = 0; i < tac_count; i++) {
        print_single_tac(file, &tac_list[i]);
    }

    fclose(file);
}




%}

%union {
    int num;
    char* id;
    struct { int value; char* type; char* id; } expr;
    struct { char* type; } type_spec;
    struct { char* label1; char* label2; char* label3; } labels;
}

%expect 1

%token <num> NUMBER
%token <id> IDENTIFIER STRING FILENAME
%token INT VOID MAIN IF ELSE WHILE FOR PRINTF SCANF RETURN
%token INC DEC EQ ASSIGN NE LE GE LT GT PLUS MINUS MUL DIV
%token SEMICOLON LPAREN RPAREN LBRACE RBRACE COMMA
%token HASH INCLUDE DEFINE AMPERSAND

%left PLUS MINUS
%left MUL DIV
%nonassoc EQ NE LT GT LE GE
%nonassoc ELSE

%type <expr> expression
%type <type_spec> type_specifier
%type <id> function_call
%type <labels> if_stmt
%type <labels> while_stmt
%type <labels> for_stmt
%type <labels> matched_stmt
%type <labels> statements
%type <labels> statement

%%

program:
    preprocessor_directives_opt declarations
    INT MAIN LPAREN RPAREN LBRACE
    {
        if (symbol_exists("main")) {
            yyerror("Redeclaration of main");
        } else {
            insert_symbol("main", "function");
            Symbol* func = lookup_symbol("main");
            func->declared = 1;
            func->type = strdup("int");
            current_function = strdup("main");
            emit_tac(NULL, "func", "main", NULL);
        }
        push_scope();
    }
    statements RBRACE
    {
        emit_tac(NULL, "endfunc", "main", NULL);
        pop_scope();
        free(current_function);
        current_function = NULL;
        printf("✅ Program parsed successfully!\n");
        print_symbol_table();
        print_tac();
        print_tac_to_file("tac_output.txt");
    }
    ;

preprocessor_directives_opt:
    preprocessor_directives
    | /* empty */
    ;

preprocessor_directives:
    preprocessor_directives preprocessor_directive
    | preprocessor_directive
    ;

preprocessor_directive:
    HASH INCLUDE LT FILENAME GT
    {
        printf("✅ Include directive: <%s>\n", $4);
        free($4);
    }
    | HASH DEFINE IDENTIFIER
    {
        printf("✅ Define directive: %s\n", $3);
        free($3);
    }
    ;

declarations:
    declarations declaration_item
    | /* empty */
    ;

declaration_item:
    function_prototype
    | function_definition
    ;

function_prototype:
    type_specifier IDENTIFIER LPAREN parameter_list RPAREN SEMICOLON
    {
        if (symbol_exists($2)) {
            yyerror("Redeclaration of function");
        } else {
            insert_symbol($2, "function");
            Symbol* func = lookup_symbol($2);
            func->declared = 1;
            func->type = strdup($1.type);
            printf("✅ Function prototype declared: %s\n", $2);
        }
        free($2);
        free($1.type);
    }
    | type_specifier IDENTIFIER LPAREN RPAREN SEMICOLON
    {
        if (symbol_exists($2)) {
            yyerror("Redeclaration of function");
        } else {
            insert_symbol($2, "function");
            Symbol* func = lookup_symbol($2);
            func->declared = 1;
            func->type = strdup($1.type);
            printf("✅ Function prototype declared: %s\n", $2);
        }
        free($2);
        free($1.type);
    }
    ;

type_specifier:
    INT { $$.type = strdup("int"); }
    | VOID { $$.type = strdup("void"); }
    ;

parameter_list:
    parameter
    | parameter_list COMMA parameter
    ;

parameter:
    type_specifier IDENTIFIER
    {
        Symbol* func = symbol_table;
        add_parameter(func, $2, $1.type);
        insert_symbol($2, $1.type);
        declare_symbol($2);
        free($1.type);
        free($2);
    }
    ;

function_definition:
    type_specifier IDENTIFIER LPAREN parameter_list RPAREN LBRACE
    {
        if (symbol_exists($2)) {
            yyerror("Redeclaration of function");
        } else {
            insert_symbol($2, "function");
            Symbol* func = lookup_symbol($2);
            func->declared = 1;
            func->type = strdup($1.type);
            current_function = strdup($2);
            emit_tac(NULL, "func", $2, NULL);
        }
        push_scope();
    }
    statements RBRACE
    {
        emit_tac(NULL, "endfunc", $2, NULL);
        printf("✅ Function defined: %s\n", $2);
        pop_scope();
        free(current_function);
        current_function = NULL;
        free($2);
        free($1.type);
    }
    | type_specifier IDENTIFIER LPAREN RPAREN LBRACE
    {
        if (symbol_exists($2)) {
            yyerror("Redeclaration of function");
        } else {
            insert_symbol($2, "function");
            Symbol* func = lookup_symbol($2);
            func->declared = 1;
            func->type = strdup($1.type);
            current_function = strdup($2);
            emit_tac(NULL, "func", $2, NULL);
        }
        push_scope();
    }
    statements RBRACE
    {
        emit_tac(NULL, "endfunc", $2, NULL);
        printf("✅ Function defined: %s\n", $2);
        pop_scope();
        free(current_function);
        current_function = NULL;
        free($2);
        free($1.type);
    }
    ;

statements:
    statements statement
    {
        $$.label1 = NULL;
        $$.label2 = NULL;
        $$.label3 = NULL;
    }
    | /* empty */
    {
        $$.label1 = NULL;
        $$.label2 = NULL;
        $$.label3 = NULL;
    }
    ;

statement:
    matched_stmt
    {
        $$.label1 = $1.label1;
        $$.label2 = $1.label2;
        $$.label3 = $1.label3;
    }
    ;

matched_stmt:
    declaration SEMICOLON
    {
        $$.label1 = NULL;
        $$.label2 = NULL;
        $$.label3 = NULL;
    }
    | assignment SEMICOLON
    {
        $$.label1 = NULL;
        $$.label2 = NULL;
        $$.label3 = NULL;
    }
    | print_stmt SEMICOLON
    {
        $$.label1 = NULL;
        $$.label2 = NULL;
        $$.label3 = NULL;
    }
    | input_stmt SEMICOLON
    {
        $$.label1 = NULL;
        $$.label2 = NULL;
        $$.label3 = NULL;
    }
    | while_stmt
    {
        $$.label1 = $1.label1;
        $$.label2 = $1.label2;
        $$.label3 = $1.label3;
    }
    | for_stmt
    {
        $$.label1 = $1.label1;
        $$.label2 = $1.label2;
        $$.label3 = $1.label3;
    }
    | increment SEMICOLON
    {
        $$.label1 = NULL;
        $$.label2 = NULL;
        $$.label3 = NULL;
    }
    | return_stmt
    {
        $$.label1 = NULL;
        $$.label2 = NULL;
        $$.label3 = NULL;
    }
    | function_call SEMICOLON
    {
        $$.label1 = NULL;
        $$.label2 = NULL;
        $$.label3 = NULL;
    }
    | LBRACE
    {
        push_scope();
    }
    statements RBRACE
    {
        pop_scope();
        $$.label1 = NULL;
        $$.label2 = NULL;
        $$.label3 = NULL;
    }
    | if_stmt
    {
        $$.label1 = $1.label1;
        $$.label2 = $1.label2;
        $$.label3 = $1.label3;
    }
    ;

if_stmt:
    IF LPAREN expression RPAREN statement
    {
        char* label1 = new_label();
        emit_tac(NULL, "ifz", $3.id, label1);
        emit_tac(label1, "label", NULL, NULL);
        $$.label1 = label1;
        $$.label2 = NULL;
        $$.label3 = NULL;
        free($3.type);
        free($3.id);
    }
    | IF LPAREN expression RPAREN statement ELSE statement
    {
        char* label1 = new_label();
        char* label2 = new_label();
        emit_tac(NULL, "ifz", $3.id, label1);
        emit_tac(NULL, "goto", label2, NULL);
        emit_tac(label1, "label", NULL, NULL);
        emit_tac(label2, "label", NULL, NULL);
        $$.label1 = label1;
        $$.label2 = label2;
        $$.label3 = NULL;
        free($3.type);
        free($3.id);
    }
    ;

declaration:
    INT IDENTIFIER
    {
        if (symbol_exists($2)) {
            yyerror("Redeclaration of variable");
        } else {
            insert_symbol($2, "int");
            declare_symbol($2);
            printf("✅ Declaration: %s of type int\n", $2);
            emit_tac($2, "declare", "int", NULL);
        }
        free($2);
    }
    ;

assignment:
    IDENTIFIER ASSIGN expression
    {
        if (!symbol_exists($1)) {
            yyerror("Assignment to undeclared variable");
        } else {
            emit_tac($1, "=", $3.id, NULL);
            printf("✅ Assignment: %s = (expression)\n", $1);
        }
        free($1);
        free($3.type);
        free($3.id);
    }
    ;

expression:
    expression PLUS expression
    {
        if (strcmp($1.type, "int") != 0 || strcmp($3.type, "int") != 0) {
            yyerror("Type mismatch in addition");
        }
        char* temp = new_temp();
        emit_tac(temp, "+", $1.id, $3.id);
        $$.type = strdup("int");
        $$.id = temp;
        $$.value = 0;
        free($1.type);
        free($3.type);
        free($1.id);
        free($3.id);
    }
    | expression MINUS expression
    {
        if (strcmp($1.type, "int") != 0 || strcmp($3.type, "int") != 0) {
            yyerror("Type mismatch in subtraction");
        }
        char* temp = new_temp();
        emit_tac(temp, "-", $1.id, $3.id);
        $$.type = strdup("int");
        $$.id = temp;
        $$.value = 0;
        free($1.type);
        free($3.type);
        free($1.id);
        free($3.id);
    }
    | expression MUL expression
    {
        if (strcmp($1.type, "int") != 0 || strcmp($3.type, "int") != 0) {
            yyerror("Type mismatch in multiplication");
        }
        char* temp = new_temp();
        emit_tac(temp, "*", $1.id, $3.id);
        $$.type = strdup("int");
        $$.id = temp;
        $$.value = 0;
        free($1.type);
        free($3.type);
        free($1.id);
        free($3.id);
    }
    | expression DIV expression
    {
        if (strcmp($1.type, "int") != 0 || strcmp($3.type, "int") != 0) {
            yyerror("Type mismatch in division");
        }
        char* temp = new_temp();
        emit_tac(temp, "/", $1.id, $3.id);
        $$.type = strdup("int");
        $$.id = temp;
        $$.value = 0;
        free($1.type);
        free($3.type);
        free($1.id);
        free($3.id);
    }
    | expression EQ expression
    {
        if (strcmp($1.type, "int") != 0 || strcmp($3.type, "int") != 0) {
            yyerror("Type mismatch in equality");
        }
        char* temp = new_temp();
        emit_tac(temp, "==", $1.id, $3.id);
        $$.type = strdup("int");
        $$.id = temp;
        $$.value = 0;
        free($1.type);
        free($3.type);
        free($1.id);
        free($3.id);
    }
    | expression NE expression
    {
        if (strcmp($1.type, "int") != 0 || strcmp($3.type, "int") != 0) {
            yyerror("Type mismatch in inequality");
        }
        char* temp = new_temp();
        emit_tac(temp, "!=", $1.id, $3.id);
        $$.type = strdup("int");
        $$.id = temp;
        $$.value = 0;
        free($1.type);
        free($3.type);
        free($1.id);
        free($3.id);
    }
    | expression LT expression
    {
        if (strcmp($1.type, "int") != 0 || strcmp($3.type, "int") != 0) {
            yyerror("Type mismatch in less than");
        }
        char* temp = new_temp();
        emit_tac(temp, "<", $1.id, $3.id);
        $$.type = strdup("int");
        $$.id = temp;
        $$.value = 0;
        free($1.type);
        free($3.type);
        free($1.id);
        free($3.id);
    }
    | expression GT expression
    {
        if (strcmp($1.type, "int") != 0 || strcmp($3.type, "int") != 0) {
            yyerror("Type mismatch in greater than");
        }
        char* temp = new_temp();
        emit_tac(temp, ">", $1.id, $3.id);
        $$.type = strdup("int");
        $$.id = temp;
        $$.value = 0;
        free($1.type);
        free($3.type);
        free($1.id);
        free($3.id);
    }
    | expression LE expression
    {
        if (strcmp($1.type, "int") != 0 || strcmp($3.type, "int") != 0) {
            yyerror("Type mismatch in less than or equal");
        }
        char* temp = new_temp();
        emit_tac(temp, "<=", $1.id, $3.id);
        $$.type = strdup("int");
        $$.id = temp;
        $$.value = 0;
        free($1.type);
        free($3.type);
        free($1.id);
        free($3.id);
    }
    | expression GE expression
    {
        if (strcmp($1.type, "int") != 0 || strcmp($3.type, "int") != 0) {
            yyerror("Type mismatch in greater than or equal");
        }
        char* temp = new_temp();
        emit_tac(temp, ">=", $1.id, $3.id);
        $$.type = strdup("int");
        $$.id = temp;
        $$.value = 0;
        free($1.type);
        free($3.type);
        free($1.id);
        free($3.id);
    }
    | LPAREN expression RPAREN
    {
        $$.type = $2.type;
        $$.id = $2.id;
        $$.value = $2.value;
    }
    | NUMBER
    {
        char* temp = new_temp();
        char num_str[20];
        sprintf(num_str, "%d", $1);
        emit_tac(temp, "=", num_str, NULL);
        $$.type = strdup("int");
        $$.id = temp;
        $$.value = $1;
    }
    | IDENTIFIER
    {
        Symbol* sym = lookup_symbol($1);
        if (!sym) {
            yyerror("Undeclared variable in expression");
            $$.type = strdup("int");
            $$.id = strdup("0");
        } else {
            $$.type = strdup(sym->type);
            $$.id = strdup($1);
        }
        $$.value = 0;
        free($1);
    }
    | function_call
    {
        $$.type = strdup("int");
        $$.id = $1;
        $$.value = 0;
    }
    ;

print_stmt:
    PRINTF LPAREN STRING RPAREN
    {
        emit_tac(NULL, "printf", $3, NULL);
        printf("✅ Print string: %s\n", $3);
        free($3);
    }
    | PRINTF LPAREN STRING COMMA IDENTIFIER RPAREN
    {
        if (!symbol_exists($5)) {
            yyerror("Undeclared variable in printf");
        } else {
            emit_tac(NULL, "printf", $3, $5);
            printf("✅ Print formatted string: %s with variable: %s\n", $3, $5);
        }
        free($3);
        free($5);
    }
    ;

input_stmt:
    SCANF LPAREN STRING COMMA AMPERSAND IDENTIFIER RPAREN
    {
        if (!symbol_exists($6)) {
            yyerror("Undeclared variable in scanf");
        } else {
            emit_tac($6, "scanf", $3, NULL);
            printf("✅ Scanf input for variable: %s\n", $6);
        }
        free($3);
        free($6);
    }
    ;

while_stmt:
    WHILE LPAREN expression RPAREN statement
    {
        char* label1 = new_label();
        char* label2 = new_label();
        emit_tac(label1, "label", NULL, NULL);
        emit_tac(NULL, "ifz", $3.id, label2);
        free($3.type);
        free($3.id);
        emit_tac(NULL, "goto", label1, NULL);
        emit_tac(label2, "label", NULL, NULL);
        $$.label1 = label1;
        $$.label2 = label2;
        $$.label3 = NULL;
    }
    ;

for_stmt:
    FOR LPAREN assignment SEMICOLON expression SEMICOLON increment RPAREN statement
    {
        char* label1 = new_label();
        char* label2 = new_label();
        char* label3 = new_label();
        emit_tac(label1, "label", NULL, NULL);
        emit_tac(NULL, "ifz", $5.id, label2);
        free($5.type);
        free($5.id);
        emit_tac(NULL, "goto", label3, NULL);
        emit_tac(label3, "label", NULL, NULL);
        emit_tac(NULL, "goto", label1, NULL);
        emit_tac(label2, "label", NULL, NULL);
        $$.label1 = label1;
        $$.label2 = label2;
        $$.label3 = label3;
    }
    ;

increment:
    IDENTIFIER INC
    {
        if (!symbol_exists($1)) {
            yyerror("Undeclared variable in increment");
        } else {
            char* temp = new_temp();
            emit_tac(temp, "+", $1, "1");
            emit_tac($1, "=", temp, NULL);
            printf("✅ Increment: %s++\n", $1);
        }
        free($1);
    }
    | IDENTIFIER DEC
    {
        if (!symbol_exists($1)) {
            yyerror("Undeclared variable in decrement");
        } else {
            char* temp = new_temp();
            emit_tac(temp, "-", $1, "1");
            emit_tac($1, "=", temp, NULL);
            printf("✅ Decrement: %s--\n", $1);
        }
        free($1);
    }
    ;

return_stmt:
    RETURN expression SEMICOLON
    {
        if (!current_function) {
            yyerror("Return statement outside function");
        } else {
            Symbol* func = lookup_symbol(current_function);
            if (func && strcmp($2.type, func->type) != 0) {
                yyerror("Return type mismatch");
            }
            emit_tac(NULL, "return", $2.id, NULL);
        }
        free($2.type);
        free($2.id);
    }
    ;

function_call:
    IDENTIFIER LPAREN argument_list RPAREN
    {
        Symbol* func = lookup_symbol($1);
        char* temp = new_temp();
        if (!func || strcmp(func->type, "function") != 0) {
            yyerror("Call to undeclared function");
            emit_tac(temp, "=", "0", NULL);
        } else {
            emit_tac(temp, "call", $1, NULL);
            printf("✅ Function call: %s\n", $1);
        }
        $$ = temp;
        free($1);
    }
    | IDENTIFIER LPAREN RPAREN
    {
        Symbol* func = lookup_symbol($1);
        char* temp = new_temp();
        if (!func || strcmp(func->type, "function") != 0) {
            yyerror("Call to undeclared function");
            emit_tac(temp, "=", "0", NULL);
        } else {
            emit_tac(temp, "call", $1, NULL);
            printf("✅ Function call: %s\n", $1);
        }
        $$ = temp;
        free($1);
    }
    ;

argument_list:
    expression
    {
        emit_tac(NULL, "param", $1.id, NULL);
        free($1.type);
        free($1.id);
    }
    | argument_list COMMA expression
    {
        emit_tac(NULL, "param", $3.id, NULL);
        free($3.type);
        free($3.id);
    }
    ;

%%

void yyerror(const char* s) {
    fprintf(stderr, "❌ Error: %s at line %d, near '%s'\n", s, yylineno, yytext);
}

int main(int argc, char **argv) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            perror("❌ Error opening file");
            return 1;
        }
    } else {
        fprintf(stderr, "❌ Usage: %s <source_file>\n", argv[0]);
        return 1;
    }

    yyparse();
    return 0;
}