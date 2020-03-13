%{
    #include <stdio.h>
    #include <iostream>
    #include <string>
    int yyerror(std::string yaccProvideMessage);
    int yylex(void* yylval);
    extern int yylineno;
    extern char* yytext;
    extern FILE* yyin;
%}
%lex-param {NULL}
%start program

%token IF ELSE WHILE FOR FUNCTION RETURN BREAK CONTINUE AND NOT OR LOCAL TRUE FALSE NIL
%token ASSIGN PLUS MINUS MULTIPLY DIVIDE MOD EQUAL NOT_EQUAL PLUS_PLUS MINUS_MINUS GREATER LESS GREATER_EQUAL LESS_EQUAL
%token SEMICOLON COMMA COLON COLON_COLON DOT DOT_DOT LEFT_BRACE RIGHT_BRACE LEFT_BRACKET RIGHT_BRACKET LEFT_PARENTHESIS RIGHT_PARENTHESIS 
%token IDENT DOUBLECONST INTCONST STRING
%token UMINUS

%left LEFT_PARENTHESIS RIGHT_PARENTHESIS
%left LEFT_BRACKET RIGHT_BRACKET
%left DOT DOT_DOT
%right NOT PLUS_PLUS MINUS_MINUS UMINUS
%left MULTIPLY DIVIDE MOD
%right PLUS MINUS 
%nonassoc GREATER GREATER_EQUAL LESS LESS_EQUAL
%nonassoc EQUAL NOT_EQUAL
%left AND
%left OR
%right ASSIGN

%%
program :
    IDENT {std::cout<<IDENT<<" ffefe\n";}
    |
;
%%

int
yyerror(std::string yaccProvideMessage){

    std::cout<<yaccProvideMessage<<": at line "<< yylineno<<", before token: "<<yytext<<std::endl;
    fprintf(stderr, "INPUT NOT VALID\n");
}

int
main(int argc, char** argv){
    
    if(argc > 1){
        if(!(yyin = fopen(argv[1], "r"))){
            fprintf(stderr, "Cannot read file: %s\n", argv[1]);
            return 1;
        }
    }
    else
        yyin = stdin;

    yyparse();
    return 0;
}