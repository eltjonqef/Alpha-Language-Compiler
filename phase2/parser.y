%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <iostream>
    #include <string>
    #include <map>
    #include <vector>
    int yyerror(std::string yaccProvideMessage);
    int yylex(void* yylval);
    extern void initEnumMap();
    extern int yylineno;
    extern char* yytext;
    extern FILE* yyin;

    enum SymbolType 
    {
      GLOB, LOCL, FORMAL, USERFUNC, LIBFUNC  
    };

    typedef struct Variable{
        std::string name;
        unsigned int scope;
        unsigned int line;
    } variable;

    typedef struct Function{
        std::string name;
        unsigned int scope;
        unsigned int line;
    } function;

    typedef struct SymbolTableEntry{
        bool isActive;
        union{
            Variable *varValue;
            Function *funcValue;
        } value;
        SymbolType type;
    } symbol_table_entry;

    std::map <std::string,std::vector<SymbolTableEntry> > SymbolTable;
    std::map <int,std::vector<SymbolTableEntry*> > ScopeTable;
    
    void addToSymbolTable(std::string Name,int Scope,int Line,SymbolType Type){
        symbol_table_entry newEntry;
        if(Type == 3 || Type ==4){
            struct Function *temp=(struct Function*)malloc(sizeof(struct Function));
            newEntry.value.funcValue->name = Name;
            newEntry.value.funcValue->scope = Scope;
            newEntry.value.funcValue->line = Line;
        }
        else{
            struct Variable *temp=(struct Variable*)malloc(sizeof(struct Variable));
            //temp->name = Name; 
            //NEED TO CHANGE THIS SHIT...CANNOT ASSIGN STRING
            //LETS USE NEW AND FREE
            //I GUESS WE NEED TO USE CLASSES
            temp->scope=Scope;
            temp->line=Line;
            newEntry.value.varValue=temp;
        }
        newEntry.type = Type;
        newEntry.isActive = 1;

        SymbolTable[Name].push_back(newEntry);
    }
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
program:          stmt {}
                ;

stmt:             expr SEMICOLON {}
                | ifstmt {}
                | whilestmt {}
                | forstmt {}
                | returnstmt {}
                | BREAK SEMICOLON {}
                | CONTINUE SEMICOLON {}
                | block {}
                | funcdef {}
                | SEMICOLON {}
                ;

expr:             assignexpr {}
                | expr PLUS expr {}
                | expr MINUS expr {}
                | expr MULTIPLY expr {}
                | expr DIVIDE expr {}
                | expr MOD expr {}
                | expr GREATER expr {}
                | expr GREATER_EQUAL expr {}
                | expr LESS expr {}
                | expr LESS_EQUAL expr {}
                | expr EQUAL expr {}
                | expr NOT_EQUAL expr {}
                | expr AND expr {}
                | expr OR expr {}
                | term {}
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

term:             LEFT_PARENTHESIS expr RIGHT_PARENTHESIS {}
                | UMINUS expr {}
                | NOT expr {}
                | PLUS_PLUS lvalue {}
                | lvalue PLUS_PLUS {}
                | MINUS_MINUS lvalue {}
                | lvalue MINUS_MINUS {}
                | primary {}
                ;

assignexpr:       lvalue ASSIGN expr {}
                ;

primary:          lvalue {}
                | call {}
                | objectdef {}
                | LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS {}
                | const {}
                ;

lvalue:           IDENT {}
                | LOCAL IDENT {}
                | COLON_COLON IDENT {}
                | member {}
                ;

member:           lvalue DOT IDENT {}
                | lvalue LEFT_BRACKET expr RIGHT_BRACKET{}
                | call DOT IDENT {}
                | call LEFT_BRACKET expr RIGHT_BRACKET{}
                ;

call:             call LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {}
                | lvalue callsuffix {}
                | LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {}
                ;

callsuffix:       normcall {}
                | methodcall {}
                ;

normcall:         LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {}
                ;

methodcall:       DOT_DOT IDENT LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {}
                ;

elist:            expr {}
                | expr COMMA elist {}
                |
                ;

objectdef:        LEFT_BRACKET elist RIGHT_BRACKET {}
                | LEFT_BRACKET indexed RIGHT_BRACKET {}
                ;

indexed:          indexedelem {}
                | indexedelem COMMA indexed {}
                ;

indexedelem:      LEFT_BRACE expr COLON expr RIGHT_BRACE {}
                ;

block:            LEFT_BRACE RIGHT_BRACE {}
                | LEFT_BRACE stmt RIGHT_BRACE {}
                ;

funcdef:          FUNCTION LEFT_PARENTHESIS idlist RIGHT_PARENTHESIS block {}
                | FUNCTION IDENT LEFT_PARENTHESIS idlist RIGHT_PARENTHESIS block {}
                ;

const:            INTCONST {}
                | DOUBLECONST {}
                | STRING {}
                | NIL {}
                | TRUE {}
                | FALSE {}
                ;

idlist:           IDENT {}
                | IDENT COMMA idlist {}
                | {}
                ;


ifstmt:           IF LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt {}
                | IF LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt ELSE stmt {}
                ;

whilestmt:        WHILE LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt {}
                ;

forstmt:          FOR LEFT_PARENTHESIS elist SEMICOLON expr SEMICOLON elist RIGHT_PARENTHESIS stmt {}
                ;

returnstmt:       RETURN SEMICOLON {}
                | RETURN expr SEMICOLON {}
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
    addToSymbolTable("eltion", 0, 0, GLOB);
    std::cout<<"redre"<<std::endl;
    addToSymbolTable("eltion", 0, 0, LOCL);
    addToSymbolTable("sdsa", 0, 0, GLOB);
    std::cout<<SymbolTable.size()<<std::endl;
    std::cout<<SymbolTable["eltion"][1].type<<std::endl;
    return 0;
}