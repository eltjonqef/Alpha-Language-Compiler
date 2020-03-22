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
    bool LookUpScope(string name, int scope);
    bool LookUpFunction(string name);
    bool LookUpVariable(string variable);
    void isFormalFromAncestorFunction(string name);
    extern void initEnumMap();
    extern int yylineno;
    extern char* yytext;
    extern FILE* yyin;

    unsigned int currentScope = 0;

    
    map <string,vector<SymbolTableEntry*> > SymbolTable;
    map <int,vector<SymbolTableEntry*> > ScopeTable;
    map <string, int> libFunctions;
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
%token UMINUS
%type <stringValue> lvalue
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

assignexpr:       lvalue ASSIGN expr {
                                        if(libFunctions[$1])
                                            cout<<"ERROR:"<<$1<<" at line "<< yylineno<<" has same name with library function."<<endl;
                                    }
                ;

primary:          lvalue {}
                | call {}
                | objectdef {}
                | LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS {}
                | const {}
                ;


lvalue:           IDENT {
                            if(!LookUpScope($1, currentScope)){
                                if(LookUpVariable($1)){
                                    if(currentScope == 0){
                                        addToSymbolTable($1, currentScope, yylineno,GLOB);
                                    }else{
                                        addToSymbolTable($1, currentScope, yylineno,LOCL);
                                    }
                                }
                            }
                        }   
                | LOCAL IDENT {$$=$2; if(LookUpScope($2, currentScope) && !libFunctions[$2])
                                    addToSymbolTable($2, currentScope, yylineno, LOCL);
                              } 
                | COLON_COLON IDENT {
                    if(!LookUpScope($2, 0) && !libFunctions[$2]){
                        cout<<"ERROR:"<<$2<<" at line:"<<yylineno<<" Couldn't find global variable with same name."<<endl;
                    }
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
                | FUNCTION IDENT {if(LookUpFunction($2)) addToSymbolTable($2, currentScope, yylineno, USERFUNC);}  LEFT_PARENTHESIS {currentScope++;} idlist {currentScope--;} RIGHT_PARENTHESIS block 
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
    
    printSymbolTable();

    return 0;
}

void
addToSymbolTable(string _name, int _scope, int _line, SymbolType _type) {
    SymbolTableEntry *newEntry = new SymbolTableEntry(_name,_scope,_line,_type);
    SymbolTable[_name].push_back(newEntry);
    ScopeTable[_scope].push_back(newEntry);
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
    addToSymbolTable("sin",0,0,LIBFUNC);
    libFunctions["print"]=1;
    libFunctions["input"]=1;
    libFunctions["objectmemberkeys"]=1;
    libFunctions["objecttotalmembers"]=1;
    libFunctions["objectcopy"]=1;
    libFunctions["totalarguments"]=1;
    libFunctions["argument"]=1;
    libFunctions["typeof"]=1;
    libFunctions["strtonum"]=1;
    libFunctions["sqrt"]=1;
    libFunctions["cos"]=1;
    libFunctions["sin"]=1;
}

void
decreaseScope() {

    for(int i = 0; i < ScopeTable[currentScope].size(); i++) {
        ScopeTable[currentScope][i]->deactivate();
    }
    currentScope--;
}

/*
    LookUp when name is function
    Will possibly put this and LookUpVariable as one
*/
bool
LookUpFunction(string name){

    if(libFunctions[name]){
        cout<<"ERROR:"<<yytext<<" at line "<< yylineno<<" has same name with library function"<<endl;
        return false;
    }
    for(int i=0; i<SymbolTable[name].size(); i++){
        if(SymbolTable[name][i]->getType()<=2 && SymbolTable[name][i]->isActive()){
            cout<<"ERROR:"<<yytext<<" at line "<< yylineno<<" has same name with active variable at line:"<<SymbolTable[name][i]->getLine()<<endl;
            return false;
        }
    }
    return true;
}


/*
    LookUp when name is variable
    Will possibly put this and LookUpFunction as one
*/
bool
LookUpVariable(string name){
    if(libFunctions[name]){
        return false;
    }
    for(int i=0; i<SymbolTable[name].size(); i++){

        if(SymbolTable[name][i]->getType()<=2 && SymbolTable[name][i]->isActive()){
            return false;
        }
        if(SymbolTable[name][i]->getType()>2 && SymbolTable[name][i]->isActive()){
            return false;
        }
    }
    return true;
}

/*
    Searches in given scope for a variable or function with given name
*/
bool LookUpScope(string name,int scope) {

    for(int i=0;i<ScopeTable[scope].size();i++) {
        if(ScopeTable[scope][i]->getName() == name && ScopeTable[scope][i]->isActive()){
            return false;
        }
    }
    return true;
}

void
isFormalFromAncestorFunction(string name){

        if(SymbolTable[name][SymbolTable[name].size()-1]->isActive() && SymbolTable[name][SymbolTable[name].size()-1]->getType()==2 && currentScope>SymbolTable[name][SymbolTable[name].size()-1]->getScope()){
            cout<<"ERROR:"<<name<<" is formal variable of ancestor function.\n";
        }
}


void printSymbolTable() {
    map<int,vector<SymbolTableEntry*> >::iterator it = ScopeTable.begin();
    map<int,string> enumtype;
    enumtype[0]="global variable";
    enumtype[1]="local variable";
    enumtype[2]="formal variable";
    enumtype[3]="user function";
    enumtype[4]="library function";

    while(it != ScopeTable.end()) {
        cout<<"---------------     Scope #"<<it->first<<"     ---------------"<<endl;
        for(int i=0;i<ScopeTable[it->first].size();i++) {
            cout<<"\""<<ScopeTable[it->first][i]->getName()<<"\" ["<<enumtype[ScopeTable[it->first][i]->getType()]<<"] (line "<<
                ScopeTable[it->first][i]->getLine()<<") (scope "<<ScopeTable[it->first][i]->getScope()<<")\n";
        }
        it++;
    }

}