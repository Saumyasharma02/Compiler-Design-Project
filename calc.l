%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
extern int yylineno;
%}

%%

"int"       { return INT; }
"void"      { return VOID; }
"float"     { return FLOAT; }
"main"      { return MAIN; }
"if"        { return IF; }
"else"      { return ELSE; }
"while"     { return WHILE; }
"for"       { return FOR; }
"return"    { return RETURN; }
"printf"    { return PRINTF; }
"scanf"     { return SCANF; }

"++"        { return INC; }
"--"        { return DEC; }

"=="        { return EQ; }
"="         { return ASSIGN; }
"!="        { return NE; }
"<="        { return LE; }
">="        { return GE; }
"<"         { return LT; }
">"         { return GT; }
"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return MUL; }
"/"         { return DIV; }

";"         { return SEMICOLON; }
"("         { return LPAREN; }
")"         { return RPAREN; }
"{"         { return LBRACE; }
"}"         { return RBRACE; }

"&"         { return AMPERSAND; }
","         {return COMMA; }

"#"         { return HASH; }
"include"   { return INCLUDE; }
"define"    { return DEFINE; }

\"[^\"]*\"  { yylval.id = strdup(yytext); return STRING; }


[0-9]+"."[0-9]*                      { yylval.fnum = atof(yytext); return FLOAT_NUMBER; }
[0-9]+                  { yylval.num = atoi(yytext); return NUMBER; }
[a-zA-Z_][a-zA-Z0-9_]*[.][h]  { yylval.id = strdup(yytext); return FILENAME; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.id = strdup(yytext); return IDENTIFIER; }

[ \t\r\n]+              { /* skip whitespace */ }

.                       { printf("Unknown character: %s\n", yytext); }

%%

int yywrap() { return 1; }
