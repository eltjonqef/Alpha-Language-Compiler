%{
    #include <stdio.h>
    #include <iostream>
    #include <string>
    int yyerror(std::string yaccProvideMessage);
    int yylex(void* yylval);
    extern void initEnumMap();
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
%left PLUS MINUS 
%nonassoc GREATER GREATER_EQUAL LESS LESS_EQUAL
%nonassoc EQUAL NOT_EQUAL
%left AND
%left OR
%right ASSIGN


%%
program:          stmt {std::cout<<"program>>>stmt\n";}
                ;

stmt:             expr SEMICOLON {std::cout<<"stmt>>>expr SEMICOLON\n";}
                | ifstmt {std::cout<<"stmt>>>IF\n";}
                | whilestmt {std::cout<<"stmt>>>WHILE\n";}
                | forstmt {std::cout<<"stmt>>>FOR\n";}
                | returnstmt {std::cout<<"stmt>>>RETURN\n";}
                | BREAK SEMICOLON {std::cout<<"stmt>>>BREAK SEMICOLON\n";}
                | CONTINUE SEMICOLON {std::cout<<"stmt>>>CONTINUE SEMICOLON\n";}
                | block {std::cout<<"stmt>>>block\n";}
                | funcdef {std::cout<<"stmt>>>funcdef\n";}
                | SEMICOLON {std::cout<<"stmt>>>SEMICOLON\n";}
                ;

expr:             assignexpr {std::cout<<"expr>>>assignexpr\n";}
                | expr PLUS expr {std::cout<<"expr>>>expr plus expr\n";}
                | expr MINUS expr {std::cout<<"expr>>>expr minus expr\n";}
                | expr MULTIPLY expr {std::cout<<"expr>>>expr MULTIPLY expr\n";}
                | expr DIVIDE expr {std::cout<<"expr>>>expr divide expr\n";}
                | expr MOD expr {std::cout<<"expr>>>expr MOD expr\n";}
                | expr GREATER expr {std::cout<<"expr>>>expr GREATER expr\n";}
                | expr GREATER_EQUAL expr {std::cout<<"expr>>>expr GREATER expr\n";}
                | expr LESS expr {std::cout<<"expr>>>expr less expr\n";}
                | expr LESS_EQUAL expr {std::cout<<"expr>>>expr less equal expr\n";}
                | expr EQUAL expr {std::cout<<"expr>>>expr equal expr\n";}
                | expr NOT_EQUAL expr {std::cout<<"expr>>>expr not equal expr\n";}
                | expr AND expr {std::cout<<"expr>>>expr AND expr\n";}
                | expr OR expr {std::cout<<"expr>>>expr o expr\n";}
                | term {std::cout<<"expr>>>term\n";}
                ;
/*
op:               MULTIPLY {std::cout<<"op>>>MULTIPLY\n";}
                | DIVIDE {std::cout<<"op>>>DIVIDE\n";}
                | MOD {std::cout<<"op>>>MOD\n";}
                | GREATER {std::cout<<"op>>>GREATER\n";}
                | GREATER_EQUAL {std::cout<<"op>>>GREATER_EQUAL\n";}
                | LESS {std::cout<<"op>>>LESS\n";}
                | LESS_EQUAL {std::cout<<"op>>>LESS_EQUAL\n";}
                | EQUAL {std::cout<<"op>>>EQUAL\n";}
                | NOT_EQUAL {std::cout<<"op>>>NOT_EQUAL\n";}
                | AND {std::cout<<"op>>>AND\n";}
                | OR {std::cout<<"op>>>or\n";}
                ;
*/

term:             LEFT_PARENTHESIS expr RIGHT_PARENTHESIS {std::cout<<"term>>>LEFT_PARENTHESIS expr RIGHT_PARENTHESIS\n";}
                | UMINUS expr {std::cout<<"term>>>UMINUS expr\n";}
                | NOT expr {std::cout<<"term>>>NOT expr\n";}
                | PLUS_PLUS lvalue {std::cout<<"term>>>PLUS_PLUS lvalue\n";}
                | lvalue PLUS_PLUS {std::cout<<"term>>>lvalue PLUS_PLUS\n";}
                | MINUS_MINUS lvalue {std::cout<<"term>>>MINUS_MINUS lvalue\n";}
                | lvalue MINUS_MINUS {std::cout<<"term>>>lvalue MINUS_MINUS\n";}
                | primary {std::cout<<"term>>>primary\n";}
                ;

assignexpr:       lvalue ASSIGN expr {std::cout<<"assignexpr>>>lvalue ASSIGN expr\n";}
                ;

primary:          lvalue {std::cout<<"primary>>>lvalue\n";}
                | call {std::cout<<"primary>>>call\n";}
                | objectdef {std::cout<<"primary>>>objectdef\n";}
                | LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS {std::cout<<"primary>>>LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS\n";}
                | const {std::cout<<"primary>>>const\n";}
                ;

lvalue:           IDENT {std::cout<<"lvalue>>>IDENT\n";}
                | LOCAL IDENT {std::cout<<"lvalue>>>LOCAL IDENT\n";}
                | COLON_COLON IDENT {std::cout<<"lvalue>>>COLON_COLON IDENT\n";}
                | member {std::cout<<"lvalue>>>member\n";}
                ;

member:           lvalue DOT IDENT {std::cout<<"member>>>lvalue DOT IDENT\n";}
                | lvalue LEFT_BRACKET expr RIGHT_BRACKET{std::cout<<"member>>>lvalue LEFT_BRACKET expr RIGHT_BRACKET\n";}
                | call DOT IDENT {std::cout<<"member>>>call DOT IDENT\n";}
                | call LEFT_BRACKET expr RIGHT_BRACKET{std::cout<<"member>>>call LEFT_BRACKET expr RIGHT_BRACKET \n";}
                ;

call:             call LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {std::cout<<"call>>>call LEFT_PARENTHESIS elist RIGHT_PARENTHESIS\n";}
                | lvalue callsuffix {std::cout<<"call>>>lvalue callsuffix\n";}
                | LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {std::cout<<"call>>>LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS LEFT_PARENTHESIS elist RIGHT_PARENTHESIS\n";}
                ;

callsuffix:       normcall {std::cout<<"callsuffix>>>normcall\n";}
                | methodcall {std::cout<<"callsuffix>>>methodcall\n";}
                ;

normcall:         LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {std::cout<<"normcall>>>LEFT_PARENTHESIS elist RIGHT_PARENTHESIS\n";}
                ;

methodcall:       DOT_DOT IDENT LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {std::cout<<"methodcall>>>DOT_DOT IDENT LEFT_PARENTHESIS elist RIGHT_PARENTHESIS\n";}
                ;

elist:            expr {std::cout<<"elist>>>expr\n";}
                | expr COMMA elist {std::cout<<"elist>>>COMMA expr\n";}
                |
                ;

objectdef:        LEFT_BRACKET elist RIGHT_BRACKET {std::cout<<"objectdef>>>LEFT_BRACKET elist RIGHT_BRACKET\n";}
                | LEFT_BRACKET indexed RIGHT_BRACKET{std::cout<<"objectdef>>>LEFT_BRACKET indexed RIGHT_BRACKET\n";}
                ;

indexed:          indexedelem {std::cout<<"indexed>>>COMMA indexedelem\n";}
                | indexedelem COMMA indexed
                |
                ;

indexedelem:      LEFT_BRACE expr COLON expr RIGHT_BRACE {std::cout<<"indexedelem>>>LEFT_BRACE expr COLON expr RIGHT_BRACE\n";}
                ;

block:            LEFT_BRACE RIGHT_BRACE {std::cout<<"block>>>LEFT_BRACE RIGHT_BRACE\n";}
                | LEFT_BRACE stmt RIGHT_BRACE {std::cout<<"block>>>LEFT_BRACE stmt RIGHT_BRACE\n";}
                ;

funcdef:          FUNCTION LEFT_PARENTHESIS idlist RIGHT_PARENTHESIS block {std::cout<<"funcdef>>>FUNCTION LEFT_PARENTHESIS idlist RIGHT_PARENTHESIS block\n";}
                | FUNCTION IDENT LEFT_PARENTHESIS idlist RIGHT_PARENTHESIS block {std::cout<<"funcdef>>>FUNCTION IDENT LEFT_PARENTHESIS idlist RIGHT_PARENTHESIS block\n";}
                ;

const:            INTCONST {std::cout<<"const>>>INTCONST\n";}
                | DOUBLECONST {std::cout<<"const>>>DOUBLECONST\n";}
                | STRING {std::cout<<"const>>>STRING\n";}
                | NIL{std::cout<<"const>>>NIL\n";}
                | TRUE{std::cout<<"const>>>TRUE\n";}
                | FALSE{std::cout<<"const>>>FALSE\n";}
                ;

idlist:           IDENT {std::cout<<"idlist>>>IDENT\n";}
                | IDENT COMMA idlist
                |
                ;


ifstmt:           IF LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt {std::cout<<"ifstmt>>>IF LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt\n";}
                | IF LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt ELSE stmt {std::cout<<"ifstmt>>>IF LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt ELSE stmt\n";}
                ;

whilestmt:        WHILE LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt {std::cout<<"whilestmt>>> WHILE LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt\n";}
                ;

forstmt:          FOR LEFT_PARENTHESIS elist SEMICOLON expr SEMICOLON elist RIGHT_PARENTHESIS stmt {std::cout<<"forstmt>>>FOR LEFT_PARENTHESIS elist SEMICOLON expr SEMICOLON elist RIGHT_PARENTHESIS stmt\n";}
                ;

returnstmt:       RETURN SEMICOLON {std::cout<<"returnstmt>>>RETURN SEMICOLON\n";}
                | RETURN expr SEMICOLON {std::cout<<"returnstmt>>>RETURN expr SEMICOLON\n";}
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
    initEnumMap();
    yyparse();
    return 0;
}