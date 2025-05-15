%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symbol_table.h"

extern int yylineno;
extern FILE *yyin;
extern char *yytext;

void yyerror(const char* s);
int yylex(void);


%}

/* Define value types */
%union {
    int num;
    char* id;
    struct {
        char *type;
        char *place;  // For IR (intermediate code)
    } attr;
}

/* Tokens with types */
%token <num> NUMBER
%token <id> IDENTIFIER STRING FILENAME

%token INT VOID MAIN IF ELSE WHILE FOR PRINTF RETURN
%token EQ ASSIGN NE LE GE LT GT
%token PLUS MINUS MUL DIV
%token SEMICOLON LPAREN RPAREN LBRACE RBRACE
%token HASH INCLUDE DEFINE

/* Operator precedence */
%left PLUS MINUS
%left MUL DIV
%nonassoc EQ NE LT LE GT GE

%type <num> expression




%%

program:
    preprocessor_directives_opt INT MAIN LPAREN RPAREN LBRACE { current_scope++; } statements RBRACE { current_scope--; }
    {
        printf("✅ Program parsed successfully!\n");
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
    }
    | HASH DEFINE IDENTIFIER
    {
        printf("✅ Define directive: %s\n", $3);
    }
    ;

statements:
    statements statement
    | /* empty */
    ;

statement:
      declaration SEMICOLON
    | assignment SEMICOLON
    | print_stmt SEMICOLON
    | if_stmt
    | while_stmt
    | return_stmt
;

declaration:
    INT IDENTIFIER 
    {
        if(lookup_symbol($2,current_scope)) {
            printf("redeclaration of variable %s\n",$2);
        }
        else {
            insert_symbol($2,"int",current_scope);
        }
        
    }
    ;

assignment:
    IDENTIFIER ASSIGN expression
    {
        printf("✅ Assignment: %s = (expression)\n", $1);
        
    }
    ;

expression:
      expression PLUS expression
    | expression MINUS expression
    | expression MUL expression
    | expression DIV expression
    | expression EQ expression
    | expression NE expression
    | expression LT expression
    | expression GT expression
    | expression LE expression
    | expression GE expression
    | LPAREN expression RPAREN { $$ = $2; }
    | NUMBER { $$ = $1; }
    | IDENTIFIER { $$ = 0; /* Treat identifiers as dummy 0 */ }
    ;

print_stmt:
      PRINTF LPAREN IDENTIFIER RPAREN
    {
        printf("✅ Print identifier: %s\n", $3);
    }
    | PRINTF LPAREN STRING RPAREN
    {
        printf("✅ Print string: %s\n", $3);
    }
    ;

if_stmt:
    IF LPAREN expression RPAREN LBRACE statements RBRACE
    | IF LPAREN expression RPAREN LBRACE statements RBRACE ELSE LBRACE statements RBRACE
    ;

while_stmt:
    WHILE LPAREN expression RPAREN LBRACE { current_scope++; } statements RBRACE { current_scope--; }
    ;

return_stmt:
    RETURN expression SEMICOLON
    ;






%%

void yyerror(const char* s) {
    fprintf(stderr, "❌ Syntax Error: %s at line %d,yytext:%s\n", s, yylineno,yytext);
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
    print_symbol_table();
    return 0;
}
