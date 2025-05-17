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
%}

/* Define value types */
%union {
    int num;
    char* id;
}

/* Tokens with types */
%token <num> NUMBER
%token <id> IDENTIFIER STRING FILENAME

%token INT VOID MAIN IF ELSE WHILE FOR PRINTF SCANF RETURN
%token INC DEC
%token EQ ASSIGN NE LE GE LT GT
%token PLUS MINUS MUL DIV
%token SEMICOLON LPAREN RPAREN LBRACE RBRACE COMMA
%token HASH INCLUDE DEFINE AMPERSAND

/* Operator precedence */
%left PLUS MINUS
%left MUL DIV
%nonassoc EQ NE LT LE GT GE
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE 

/* Non-terminal types */
%type <num> expression
%type <id> type_specifier
%type <num> parameter_list_opt parameter_list
%type <num>  argument_list_opt argument_list
%type <num> function_call



%%

program:
    preprocessor_directives_opt
    function_definition
    INT MAIN LPAREN RPAREN LBRACE statements RBRACE
    {
        printf("✅ Program parsed successfully!\n");
        print_symbol_table();
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


type_specifier:
      INT  { $$ = "int"; }
    | VOID { $$ = "void"; }
    ;


parameter_list_opt:
      parameter_list       { $$ = $1; }
    | /* empty */          { $$ = 0; }
    ;

parameter_list:
      parameter                    { $$ = 1; }
    | parameter_list COMMA parameter { $$ = $1 + 1; }
    ;


parameter:
      type_specifier IDENTIFIER
    ;

function_definition:
      type_specifier IDENTIFIER LPAREN parameter_list_opt RPAREN compound_statement
    {
        if (symbol_exists($2)) {
            yyerror("❌ Function already declared");
        } else {
            int param_count = $4;  // $4 should return number of parameters
            insert_function($2, $1, param_count);
            printf("✅ Function defined: %s with %d params\n", $2, param_count);
        }
    }
;


compound_statement:
      LBRACE statements RBRACE
;

function_call:
    IDENTIFIER LPAREN argument_list_opt RPAREN
    {
        if (!symbol_exists($1)) {
            yyerror("❌ Call to undefined function");
        } else {
            Symbol *f = get_symbol($1);
            if (!f->is_function) {
                yyerror("❌ Identifier is not a function");
            } else if (f->param_count != $3) {
                yyerror("❌ Argument count mismatch in function call");
            } else {
                printf("✅ Function call: %s with %d args\n", $1, $3);
            }
        }
        $$ = 0;
    }
    ;

argument_list_opt:
      argument_list { $$ = $1; }
    | /* empty */   { $$ = 0; }
    ;

argument_list:
      expression               { $$ = 1; }
    | argument_list COMMA expression { $$ = $1 + 1; }
    ;



statements:
    statements statement
    | /* empty */
    ;

statement:
      declaration SEMICOLON
    | assignment SEMICOLON
    | print_stmt SEMICOLON
    | input_stmt SEMICOLON
    | if_stmt
    | while_stmt
    | for_stmt
    | increment SEMICOLON
    | return_stmt
    | function_call SEMICOLON 
    ;

declaration:
    INT IDENTIFIER
    {
        if (symbol_exists($2)) {
            yyerror("❌ Redeclaration of variable");
        } else {
            insert_symbol($2, "int");  // Insert with the type "int"
            declare_symbol($2);
            printf("✅ Declaration: %s of type int\n", $2);
        }
    }
;



assignment:
    IDENTIFIER ASSIGN expression
    {
        // Check if the symbol is declared in the symbol table
        if (!symbol_exists($1)) {
            yyerror("❌ Assignment to undeclared variable");
        } else {
            // Optional: Type checking can go here (if you store types in the symbol table)
            printf("✅ Assignment: %s = (expression)\n", $1);
        }
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
    | function_call { $$ = 0; } 
    ;

print_stmt:
      PRINTF LPAREN STRING RPAREN
    {
        printf("✅ Print string: %s\n", $3);
    }
    | PRINTF LPAREN STRING COMMA IDENTIFIER RPAREN
    {
         printf("✅ Print formatted string: %s with variable: %s\n", $3, $5);
    }
    ;

input_stmt:
    SCANF LPAREN STRING COMMA AMPERSAND IDENTIFIER RPAREN
    {
        printf("✅ Scanf input for variable: %s\n", $6);
    }
    ;

if_stmt:
    IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
    | IF LPAREN expression RPAREN statement ELSE statement
    ;


while_stmt:
    WHILE LPAREN expression RPAREN LBRACE statements RBRACE
    ;

for_stmt:
    FOR LPAREN assignment SEMICOLON expression SEMICOLON increment RPAREN LBRACE statements RBRACE
    {
        printf("✅ For loop parsed\n");
    }
;


increment:
      IDENTIFIER INC {
          printf("✅ Increment: %s++\n", $1);
      }
    | IDENTIFIER DEC {
          printf("✅ Decrement: %s--\n", $1);
      }
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
    return 0;
}
