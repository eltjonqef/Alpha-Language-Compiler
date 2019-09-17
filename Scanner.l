%{
    #include <string>
    #include <stdlib.h>
    #include <string.h>
    #include <iostream>
    
    #ifdef _cplusplus
        static int yyinput(void);
    #else
        static int input(void);
    #endif

    #define YY_DECL int yylex(void)
    
    using namespace std;
%}

%option header-file = "./al.h"
%option yylineno
%option noyywrap

KEYWORD ("if")|("else")|("while")|("for")|("function")|("return")|("break")|("continue")|("and")|("not")|("or")|("local")|("true")|("false")|("nil")

OPERATOR ("=")|("+")|("-")|("*")|("/")|("%")|("==")|("!=")|("++")|("--")|(">")|("<")|(">=")|("<=")

INTCONST [0-9]+

DOUBLECONST [0-9]+\.[0-9]+

PUNMRKS (\;)|(\,)|(\:)|(\:\:)|(\.)|(\.\.)|(\{)|(\})|(\[)|(\])|(\()|(\))

IDENT [a-zA-Z][a-zA-Z_0-9]*

WHITESPACE [ \n\t\r]+

SCOMMENT "//".*

%%

{KEYWORD} {
    fprintf(stderr, "K %s, %d", yytext, yylineno);
}

{OPERATOR} {
    fprintf(stderr, "O %s, %d", yytext, yylineno);
}

{INTCONST} {
    fprintf(stderr, "I %s, %d", yytext, yylineno);
}

{DOUBLECONST} {
    fprintf(stderr, "D %s, %d", yytext, yylineno);
}

{PUNMRKS} {
    fprintf(stderr, "P %s, %d", yytext, yylineno);
}

{IDENT} {
    fprintf(stderr, "ID %s, %d", yytext, yylineno);
}

{SCOMMENT} {
    fprintf(stderr, "S %s, %d", yytext, yylineno);
}

\" {
    string tmp = "";
    char hia;

    while ((hia = yyinput())){
        if (hia == '\"') break;

        else if (hia == EOF) {
            fprintf(stderr, "Unclosed string in line %d", yylineno);
            return -1;
        }
        else if (hia != '\\' && hia != '\"') tmp += hia;
        
        else if (hia == '\\') {
            hia = yyinput();
            switch(hia){
                case 'n' : 
                    tmp += '\n';
                    break;
                case 't' : 
                    tmp += '\t';
                    break;
                case 'r' : 
                    tmp += '\r';
                    break;
                case 'b' : 
                    tmp += '\b';
                    break;
                case '\\' : 
                    tmp += '\\';
                    break;
                case '\"' : 
                    tmp += '\"';
                    break;
                default : 
                    fprintf(stderr, "error in line %d\n", yylineno);
                    return -1;
            }
        }
    }
    fprintf(stderr, "S %s in line %d\n", tmp.c_str(), yylineno);
}

{WHITESPACE} {}

<<EOF>> {return 0;}

%%

int main(int argc, char** argv){
        
    if (argc > 1){
        if(!(yyin = fopen(argv[1], "r"))){
            fprintf(stderr, "Cannot read file: %s\n", argv[1]);
            return 1;
        }
    }
    else
        yyin = stdin;

    yylex();
    return 0;
}