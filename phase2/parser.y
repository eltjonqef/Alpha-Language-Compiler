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
program     :    
                stmt*
                ;

stmt        :
                  expr SEMICOLON
                | IF
                | WHILE
                | FOR
                | RETURN
                | BREAK SEMICOLON
                | CONTINUE SEMICOLON
                | block
                | funcdef
                | SEMICOLON
                ;

expr        :
                  assignexpr
                | expr op expr
                | term

op          :
                  PLUS
                | MINUS
                | MULTIPLY
                | DIVIDE
                | MOD
                | GREATER
                | GREATER_EQUAL
                | LESS
                | LESS_EQUAL
                | EQUAL
                | NOT_EQUAL
                | AND
                | OR
                ;

term        :
                  LEFT_PARENTHESIS expr RIGHT_PARENTHESIS
                | MINUS expr
                | not expr
                | PLUS_PLUS lvalue
                | lvalue PLUS_PLUS
                | MINUS_MINUS lvalue
                | lvalue MINUS_MINUS
                | primary
                ;

assignexpr  :
                  lvalue ASSIGN expr
                ;

primary     :
                  lvalue
                | call
                | objectdef
                | LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS
                | const

lvalue      :
                  IDENT
                | local IDENT
                | COLON_COLON IDENT
                | member
                ;

member      :
                  lvalue DOT IDENT
                | lvalue LEFT_BRACKET expr RIGHT_BRACKET
                | call DOT IDENT
                | call LEFT_BRACKET expr RIGHT_BRACKET
                ;

call        :
                  call LEFT_PARENTHESIS elist RIGHT_PARENTHESIS
                | lvalue callsuffix
                | LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS LEFT_PARENTHESIS elist RIGHT_PARENTHESIS
                ;

callsuffix  :
                  normcall
                | methodcall
                ;

normcall    :
                  LEFT_PARENTHESIS elist RIGHT_PARENTHESIS
                ;

methodcall  :
                  DOT_DOT IDENT LEFT_PARENTHESIS elist RIGHT_PARENTHESIS
                | lvalue DOT IDENT LEFT_PARENTHESIS lvalue COMMA elist RIGHT_PARENTHESIS
                ;

elist       :
                  [expr [COMMA expr]*]
                ;

objectdef   :
                  LEFT_BRACKET [elist | indexed] RIGHT_BRACKET
                ;

indexed     :
                  [indexedelem [COMMA indexedelem]*]
                ;

indexedelem :
                  LEFT_BRACE expr COLON expr RIGHT_BRACE
                ;

block       :
                  LEFT_BRACE [stmt*] RIGHT_BRACE
                ;

funcdef     :
                  FUNCTION LEFT_PARENTHESIS idlist RIGHT_PARENTHESIS block
                | FUNCTION IDENT LEFT_PARENTHESIS idlist RIGHT_PARENTHESIS block
                ;

const       :
                  INTCONST
                | DOUBLECONST
                | STRING
                | NIL
                | TRUE
                | FALSE
                ;

idlist      :
                  [IDENT [COMMA IDENT]*]
                ;

ifstmt      :
                  IF LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt
                | IF LEFT_PARENTHESIS expr RIGHT_PARENTHESIS block
                | IF LEFT_PARENTHESIS expr RIGHT_PARENTHESIS block ELSE stmt
                | IF LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt ELSE block
                | IF LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt ELSE stmt
                | IF LEFT_PARENTHESIS expr RIGHT_PARENTHESIS block ELSE block
                ;

whilestmt   :
                  WHILE LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt
                ;

forstmt     :
                  FOR LEFT_PARENTHESIS elist SEMICOLON expr SEMICOLON elist RIGHT_PARENTHESIS stmt
                ;

returnstmt  :
                  RETURN SEMICOLON
                | RETURN expr SEMICOLON
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