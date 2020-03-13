%{
    #include <stdio.h>
    extern int yylineno;
    extern char* yytext;
    extern FILE* yyin;
    int alpha_yylex(void* yylval);
%}

%start program

%token IDENT DOUBLECONST INTCONST STRING

%left "(" ")"
%left "[" "]"
%left "." ".."
%right "not" "++" "--" "-"
%left "*" "/" "%"
%right "+" 
%nonassoc ">" ">=" "<" "<="
%nonassoc "==" "!="
%left "and"
%left "or"
%right "="

%%
program :
    IDENT
    |
;
%%
int main(int argc, char** argv){
    
    if(argc > 1){
        if(!(yyin = fopen(argv[1], "r"))){
            fprintf(stderr, "Cannot read file: %s\n", argv[1]);
            return 1;
        }
    }
    else
        yyin = stdin;

    alpha_yylex(NULL);
    return 0;
}