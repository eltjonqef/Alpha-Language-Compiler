%{
    #include <stdio.h>
    #include <stdlib.h>
    #include "SymbolTable.hpp"
    #include <iostream>
    #include <string>
    #include <string.h>
    #include <map>
    #include <vector>
    #include <assert.h>

    using namespace std;

    int yyerror(string yaccProvideMessage);
    int yylex();
    void InitilizeLibraryFunctions();
    void addToSymbolTable(string _name, int _scope, int _line, SymbolType _type);
    void decreaseScope();
    bool checkLibFunctions(string name);
    bool checkFunctionIsActive(string name);
    extern void initEnumMap();
    extern int yylineno;
    extern char* yytext;
    extern FILE* yyin;

    unsigned int currentScope = 0;

    
    map <string,vector<SymbolTableEntry*> > SymbolTable;
    map <int,vector<SymbolTableEntry*> > ScopeTable;
    
    /*
        Looks all active scopes (based on currentScope)
        returns true if a variable with that name exists
    */
    //todo
    bool checkVariableExists(string name) {
        for(int i=0;i<=currentScope;i++) {
            for (int j = 0; j < ScopeTable[i].size(); j++) {
                if (ScopeTable[i][j]->getType() <= 2 && ScopeTable[i][j]->getName() == name)
                    return true;
            }
        }
        return false;
    }

    /*
        Searches all active scopes(based on currentSocpe)
        returns true if a function with that name exists
    */
    //todo
    bool checkFunctionExists(string name){
        for(int i=0;i<=currentScope;i++) {
            for (int j = 0; j < ScopeTable[i].size(); j++) {
                if (ScopeTable[i][j]->getType() >= 3 && ScopeTable[i][j]->getName() == name)
                    return true;
            }
        }
        return false;
    }
%}



%union {
    int intValue;
    char* stringValue;
    double doubleValue;
}

%start program

%token IF ELSE WHILE FOR FUNCTION RETURN BREAK CONTINUE AND NOT OR LOCAL TRUE FALSE NIL
%token ASSIGN PLUS MINUS MULTIPLY DIVIDE MOD EQUAL NOT_EQUAL PLUS_PLUS MINUS_MINUS GREATER LESS GREATER_EQUAL LESS_EQUAL
%token SEMICOLON COMMA COLON COLON_COLON DOT DOT_DOT LEFT_BRACE RIGHT_BRACE LEFT_BRACKET RIGHT_BRACKET LEFT_PARENTHESIS RIGHT_PARENTHESIS 
%token <stringValue> IDENT
%token <intValue> INTCONST
%token <stringValue> STRING
%token <doubleValue> DOUBLECONST
%type <stringValue> lvalue
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
program:          loopstmt {}
                ;

loopstmt:         loopstmt stmt
                |
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
op:               MULTIPLY {cout<<"op>>>MULTIPLY\n";}
                | DIVIDE {cout<<"op>>>DIVIDE\n";}
                | MOD {cout<<"op>>>MOD\n";}
                | GREATER {cout<<"op>>>GREATER\n";}
                | GREATER_EQUAL {cout<<"op>>>GREATER_EQUAL\n";}
                | LESS {cout<<"op>>>LESS\n";}
                | LESS_EQUAL {cout<<"op>>>LESS_EQUAL\n";}
                | EQUAL {cout<<"op>>>EQUAL\n";}
                | NOT_EQUAL {cout<<"op>>>NOT_EQUAL\n";}
                | AND {cout<<"op>>>AND\n";}
                | OR {cout<<"op>>>or\n";}
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

assignexpr:       lvalue ASSIGN expr {if(checkLibFunctions($1) && !checkFunctionIsActive($1)) addToSymbolTable($1, currentScope, yylineno, GLOB);}
                ;

primary:          lvalue {}
                | call {}
                | objectdef {}
                | LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS {}
                | const {}
                ;

lvalue:           IDENT {$$=$1;}
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
                | expr COMMA expr {}
                |
                ;

//MPOROUME NA VGALOUME ENTELWS TO OBJECT DEF KAI NA STAMATHSEI H ANAGWGI STA PROIGOUMENA
objectdef:        LEFT_BRACKET elist RIGHT_BRACKET {}
                | LEFT_BRACKET indexed RIGHT_BRACKET {}
                ;

indexed:          indexedelem {}
                | indexedelem COMMA indexedelem {}
                ;

indexedelem:      LEFT_BRACE expr COLON expr RIGHT_BRACE {}
                ;

block:            LEFT_BRACE {currentScope++;} loopstmt {decreaseScope();} RIGHT_BRACE
                ;

funcdef:          FUNCTION LEFT_PARENTHESIS {currentScope++;} idlist {decreaseScope();}RIGHT_PARENTHESIS block {}
                | FUNCTION IDENT {if(checkLibFunctions($2)) addToSymbolTable($2, currentScope, yylineno, USERFUNC);}  LEFT_PARENTHESIS {currentScope++;} idlist {decreaseScope();} RIGHT_PARENTHESIS block 
                ;

const:            INTCONST {}
                | DOUBLECONST {}
                | STRING {}
                | NIL {}
                | TRUE {}
                | FALSE {}
                ;

idlist:           IDENT {cout<<"ident1 "<<$1<<endl;}
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
yyerror(string yaccProvideMessage) {

    cout<<yaccProvideMessage<<": at line "<< yylineno<<", before token: "<<yytext<<endl;
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
    InitilizeLibraryFunctions();
    yyparse();
    for(int i=0; i<ScopeTable.size(); i++){
        cout<<"-------------------     Scope #"<<i<<"     -------------------"<<endl;
        for(int j=0; j<ScopeTable[i].size(); j++){
            cout<<ScopeTable[i][j]->getName()<<" "<<ScopeTable[i][j]->getType()<<endl;
        }
    }
    return 0;
}

void
addToSymbolTable(string _name, int _scope, int _line, SymbolType _type) {
    SymbolTableEntry *newEntry = new SymbolTableEntry(_name,_scope,_line,_type);
    SymbolTable[_name].push_back(newEntry);
    ScopeTable[_scope].push_back(newEntry);
}

bool
checkLibFunctions(string name) {

    for(int i=0; i<ScopeTable[0].size(); i++) {
        if (ScopeTable[0][i]->getName()==name && ScopeTable[0][i]->getType()==4) {
            cout<<"ERROR: Symbol: "<<name<<" at line: "<<yylineno<<" is a library function."<<endl;
            return false;
        }
    }
    return true;
}

bool
checkFunctionIsActive(string name){
    
    for(int i=0; i<SymbolTable[name].size(); i++){
        if(SymbolTable[name][i]->isActive()){
            cout<<"ERROR: Symbol: "<<name<<" at line: "<<yylineno<<" has same name as active function."<<endl;
            return true;
        }
    }
    return false;
}

void
InitilizeLibraryFunctions(){

    addToSymbolTable("print",0,0,LIBFUNC);
    addToSymbolTable("input",0,0,LIBFUNC);
    addToSymbolTable("objectmemberkeys",0,0,LIBFUNC);
    addToSymbolTable("objecttotalmembers",0,0,LIBFUNC);
    addToSymbolTable("objectcopy",0,0,LIBFUNC);
    addToSymbolTable("totalarguments",0,0,LIBFUNC);
    addToSymbolTable("argument",0,0,LIBFUNC);
    addToSymbolTable("typeof",0,0,LIBFUNC);
    addToSymbolTable("strtonum",0,0,LIBFUNC);
    addToSymbolTable("sqrt",0,0,LIBFUNC);
    addToSymbolTable("cos",0,0,LIBFUNC);
    addToSymbolTable("sin ",0,0,LIBFUNC);
}

void
decreaseScope() {

    for(int i = 0; i < ScopeTable[currentScope].size(); i++) {
        ScopeTable[currentScope][i]->deactivate();
    }
    currentScope--;
}