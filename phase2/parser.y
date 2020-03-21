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
    void printSymbolTable();
    bool checkExistanceInScope(string name);
    bool checkIfExistingVariable(string name);
    bool checkVariableIsActive(string name);
    bool checkLibFunctions(string name);
    bool checkFunctionIsActive(string name);
    bool SearchInScope(int _scop,string _name);
    extern void initEnumMap();
    extern int yylineno;
    extern char* yytext;
    extern FILE* yyin;

    unsigned int currentScope = 0;

    
    map <string,vector<SymbolTableEntry*> > SymbolTable;
    map <int,vector<SymbolTableEntry*> > ScopeTable;
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
%type <stringValue> primary
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

assignexpr:       lvalue ASSIGN expr {if(checkFunctionIsActive($1)){
                                            cout<<"ERROR (assignexpr rule): Active function cant be assigned expr.\n";
                                        }
                                    }
                ;

primary:          lvalue {$$ =$1;}
                | call {}
                | objectdef {}
                | LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS {}
                | const {}
                ;


lvalue:           IDENT {
                       if(checkFunctionIsActive($1)){
                           cout<<"error: variable "<<$1<<" is already a function\n";
                        }else if(!checkVariableIsActive($1)){
                            if(currentScope == 0){
                                addToSymbolTable($1, currentScope, yylineno,GLOB);
                            }else{
                                addToSymbolTable($1, currentScope, yylineno,LOCL);
                            }
                        }
                        $$ = $1;
                    }
                | LOCAL IDENT {if(!SearchInScope(currentScope,$2)){
                                    if(!checkFunctionIsActive($2)){
                                        addToSymbolTable($2, currentScope, yylineno, LOCL);
                                    }else{
                                        cout<<"ERROR( local ident rule) : a function with that name already exists\n"; 
                                    }
                                }
                                $$ = $2;
                            } 
                | COLON_COLON IDENT {
                    if(!SearchInScope(0,$2)){
                        cout<<"ERROR (colon_colon rule): cant find global id\n";
                    }
                    $$ = $2;
                }
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
                | FUNCTION IDENT {if(checkLibFunctions($2) && checkVariableIsActive($2)) addToSymbolTable($2, currentScope, yylineno, USERFUNC);}  LEFT_PARENTHESIS {currentScope++;} idlist {decreaseScope();} RIGHT_PARENTHESIS block 
                ;

const:            INTCONST {}
                | DOUBLECONST {}
                | STRING {}
                | NIL {}
                | TRUE {}
                | FALSE {}
                ;

idlist:           IDENT {addToSymbolTable($1, currentScope, yylineno, FORMAL);}
                | IDENT COMMA idlist {addToSymbolTable($1, currentScope, yylineno, FORMAL);}
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
                | RETURN expr SEMICOLON {if(!SearchInScope(currentScope, $2)) cout << "Undecleared variable"<<endl;}
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
    
    printSymbolTable();

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
            cout<<"ERROR(checkLibFunction): Symbol: "<<name<<" at line: "<<yylineno<<" is a library function."<<endl;
            return false;
        }
    }
    return true;
}

bool
checkFunctionIsActive(string name){
/*    
    for (int sc = 1; sc == currentScope+1; sc += currentScope) {
        for (int i = 0; i < ScopeTable[sc-1].size(); i++) {
            if (ScopeTable[sc-1][i]->getType() >= 3 && ScopeTable[sc-1][i]->getName() == name) {
                cout<<"ERROR: Symbol: "<<name<<" at line: "<<yylineno<<" has same name as active function."<<endl;
                return true;
            }
        }
    }
*/
    for (int i = 0; i < ScopeTable[0].size(); i++) {
        if (ScopeTable[0][i]->getType() >= 3 && ScopeTable[0][i]->getName() == name) {
            cout<<"ERROR: Symbol: "<<name<<" at line: "<<yylineno<<" has same name as active function."<<endl;
            return true;
        }
    }
    for(int i = 0; i < ScopeTable[currentScope].size(); i++) {
        if (ScopeTable[currentScope][i]->getType() >= 3 && ScopeTable[currentScope][i]->getName() == name) {
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

bool
checkVariableIsActive(string name) {
/*  
    for (int sc = 1; sc == currentScope; sc += currentScope) {
        for (int i = 0; i < ScopeTable[sc-1].size(); i++) {
            if (ScopeTable[sc-1][i]->getType() <= 2 && ScopeTable[sc-1][i]->getName() == name) {
                cout << "Pre-existing variable: " << name << ", with type: " << SymbolTable[name][i]->getType() << ", at line: " << SymbolTable[name][i]->getLine() << endl;
                return true;
            }
        }
    }
*/
    for(int i=0;i<ScopeTable[0].size();i++){
        if (ScopeTable[0][i]->getType() <= 2 && ScopeTable[0][i]->getName() == name) {
            cout << "Pre-existing variable: " << name << ", with type: " << SymbolTable[name][i]->getType() << ", at line: " << SymbolTable[name][i]->getLine() << endl;
            return true;
        }
    }   
    for(int i=0;i<ScopeTable[currentScope].size();i++){     
        if (ScopeTable[currentScope][i]->getType() <= 2 && ScopeTable[currentScope][i]->getName() == name) {
            cout << "Pre-existing variable: " << name << ", with type: " << SymbolTable[name][i]->getType() << ", at line: " << SymbolTable[name][i]->getLine() << endl;
            return true;
        }
    }
    return false;
}

/*
    Searches in given scope for a variable or function with given name
*/
bool SearchInScope(int _scop,string _name) {
    for(int i=0;i<ScopeTable[_scop].size();i++) {
        if(ScopeTable[_scop][i]->getName() == _name) return true;
    }
    return false;
}

void printSymbolTable() {
    map<int,vector<SymbolTableEntry*> >::iterator it = ScopeTable.begin();
    map<int,string> enumtype;
    enumtype[0]="GLOBAl";
    enumtype[1]="LOCAL";
    enumtype[2]="FORMAL";
    enumtype[3]="USERFUNC";
    enumtype[4]="LIBFUNC";

    while(it != ScopeTable.end()) {
        for(int i=0;i<ScopeTable[it->first].size();i++) {
            cout<<"\" "<<ScopeTable[it->first][i]->getName()<<"\" ["<<enumtype[ScopeTable[it->first][i]->getType()]<<"] ( line "<<
                ScopeTable[it->first][i]->getLine()<<" ) ( scope "<<ScopeTable[it->first][i]->getScope()<<")\n";
        }
        it++;
    }

}