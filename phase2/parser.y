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
    bool LookUpVariable(string variable, int flag);
    void LookUpRvalue(string name);
    void callFunction(string name);
    bool existsInScope(string name, int scope);
    int Flag=0;
    int callFlag=0;
    int nestedFunctionCounter=0;
    int nestedLoopCounter=0;
    int returnState=0;
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
%type <stringValue> member
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
program:          loopstmt {cout<<"program -> loopstmt\n";}
                ;

loopstmt:         loopstmt stmt {cout<<"loopstmt -> loopstmt stmt\n"};
                |
                ;
stmt:             expr SEMICOLON {cout<<"stmt -> expr SEMICOLON\n";}
                | ifstmt {cout<<"stmt -> ifstmt\n";}
                | whilestmt {cout<<"stmt -> whilestmt\n";}
                | forstmt {cout<<"stmt -> forstmt\n";}
                | {returnState=1;}returnstmt {returnState=0; if(!nestedFunctionCounter) {cout<<"ERROR at line "<<yylineno<<": return while not inside a function."<<endl;}
                    cout<<"stmt -> returnstmt\n";}
                | BREAK SEMICOLON {if(!nestedLoopCounter) {cout<<"ERROR at line "<<yylineno<<": break while not inside a loop."<<endl;} cout<<"stmt -> BREAK SEMICOLON\n"}
                | CONTINUE SEMICOLON {if(!nestedLoopCounter) {cout<<"ERROR at line "<<yylineno<<": continue while not inside a loop."<<endl;} cout<<"stmt -> CONTINUE SEMICOLON\n"}
                | block {cout<<"stmt -> block\n";}
                | funcdef {cout<<"stmt -> funcdef\n";}
                | SEMICOLON {cout<<"stmt -> SEMICOLON\n";}
                ;

expr:             assignexpr { cout<<"expr -> assignexpr\n";}
                | expr PLUS expr {cout<<"expr -> expr PLUS expr\n";}
                | expr MINUS expr {cout<<"expr -> expr MINUS expr\n";}
                | expr MULTIPLY expr {cout<<"expr -> expr MULTIPLY expr\n";}
                | expr DIVIDE expr {cout<<"expr -> expr DIVIDE expr\n";}
                | expr MOD expr {cout<<"expr -> expr MOD expr\n";}
                | expr GREATER expr {cout<<"expr -> expr GREATER expr\n";}
                | expr GREATER_EQUAL expr {cout<<"expr -> expr GREATER_EQUAL expr\n";}
                | expr LESS expr {cout<<"expr -> expr LESS expr\n";}
                | expr LESS_EQUAL expr {cout<<"expr -> expr LESS_EQUAL expr\n";}
                | expr EQUAL expr {cout<<"expr ->  expr EQUAL expr\n";}
                | expr NOT_EQUAL expr {cout<<"expr -> expr NOT_EQUAL expr\n";}
                | expr AND expr {cout<<"expr -> expr AND expr\n";}
                | expr OR expr {cout<<"expr -> expr OR expr\n";}
                | term {cout<<"expr -> term\n";}
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

term:             LEFT_PARENTHESIS expr RIGHT_PARENTHESIS {cout<<"term -> LEFT_PARENTHESIS expr RIGHT_PARENTHESIS \n";}
                | UMINUS expr {cout<<"term -> UMINUS expr \n";}
                | NOT expr {cout<<"term -> NOT expr \n";}
                | PLUS_PLUS lvalue {LookUpRvalue($2);cout<<"term -> PLUS_PLUS lvalue \n";}
                | lvalue PLUS_PLUS {LookUpRvalue($1);cout<<"term -> lvalue PLUS_PLUS \n";}
                | MINUS_MINUS lvalue {LookUpRvalue($2);cout<<"term -> MINUS_MINUS lvalue \n";}
                | lvalue MINUS_MINUS {LookUpRvalue($1);cout<<"term -> lvalue MINUS_MINUS \n";}
                | primary {cout<<"term -> primary \n";}
                ;

assignexpr:       lvalue {if(Flag==1) Flag=0; else LookUpRvalue($1);} ASSIGN expr {cout<<"assignexpr -> lvalue ASSIGN expr \n";}
                ;

primary:          lvalue {cout<<"primary -> lvalue \n";}
                | call {cout<<"primary -> call \n";}
                | objectdef {cout<<"primary -> objectdef \n";}
                | LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS {cout<<"primary -> LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS \n";}
                | const {cout<<"primary -> const \n";}
                ;


lvalue:           IDENT {   
                            if(LookUpVariable($1, 0)){
                                if(currentScope == 0){
                                    addToSymbolTable($1, currentScope, yylineno,GLOB);
                                }else{
                                    addToSymbolTable($1, currentScope, yylineno,LOCL);
                                }
                            }
                            cout<<"lvalue -> IDENT \n";
                        }   
                | LOCAL IDENT {$$=$2;if(LookUpVariable($2, 1)){
                                    addToSymbolTable($2, currentScope, yylineno, LOCL);Flag=1; }
                                    else if(libFunctions[$2])cout<<"ERROR at line "<<yylineno<<": Collision with library function"<<endl;
                                cout<<"lvalue -> LOCAL IDENT\n"
                              } 
                | COLON_COLON IDENT {LookUpScope($2, 0); Flag=1;cout<<"lvalue -> COLON_COLON IDENT\n";}
                | member {}
                ;

member:           lvalue DOT IDENT {$$=$3;cout<<"member -> lvalue DOT IDENT\n";}
                | lvalue LEFT_BRACKET expr RIGHT_BRACKET{cout<<"member -> lvalue LEFT_BRACKET expr RIGHT_BRACKET \n";}
                | call DOT IDENT {$$=$3;cout<<"member -> call DOT IDENT\n";}
                | call LEFT_BRACKET expr RIGHT_BRACKET{cout<<"call LEFT_BRACKET expr RIGHT_BRACKET \n";}
                ;

call:             call LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {cout<<"call -> call LEFT_PARENTHESIS elist RIGHT_PARENTHESIS\n";}
                | lvalue callsuffix {if(callFlag==1){callFlag=0;}else {if(!returnState) callFunction($1);} cout<<"call -> lvalue callsuffix\n";}
                | LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {cout<<"call -> LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS LEFT_PARENTHESIS elist RIGHT_PARENTHESIS\n";}
                ;

callsuffix:       normcall {cout<<"callsuffix -> normcall\n";}
                | methodcall {cout<<"callsuffix -> methodcall \n";}
                ;

normcall:         LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {cout<<"normcall -> LEFT_PARENTHESIS elist RIGHT_PARENTHESIS\n";}
                ;

methodcall:       DOT_DOT IDENT {if(!returnState) callFlag=1; callFunction($2);} LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {cout<<"methodcall -> DOT_DOT IDENT LEFT_PARENTHESIS elist RIGHT_PARENTHESIS \n";}
                ;

elist:            expr {cout<<"elist -> expr \n";}
                | expr COMMA elist {cout<<"elist -> expr COMMA elist\n";}
                |{cout<<"elist ->  \n";}
                ;

objectdef:        LEFT_BRACKET elist RIGHT_BRACKET {cout<<"objectdef -> LEFT_BRACKET elist RIGHT_BRACKET\n";}
                | LEFT_BRACKET indexed RIGHT_BRACKET {cout<<"objectdef -> LEFT_BRACKET indexed RIGHT_BRACKET\n";}
                ;

indexed:          indexedelem {cout<<"indexed -> indexedelem\n";}
                | indexedelem COMMA indexed {cout<<"indexed -> indexedelem COMMA indexed\n";}
                ;

indexedelem:      LEFT_BRACE expr COLON expr RIGHT_BRACE {cout<<"indexedelem -> LEFT_BRACE expr COLON expr RIGHT_BRACE \n";}
                ;

block:            LEFT_BRACE {currentScope++;} loopstmt {decreaseScope();} RIGHT_BRACE {cout<<"block -> LEFT_BRACE loopstmt RIGHT_BRACE \n";}
                ;

funcdef:          FUNCTION {nestedFunctionCounter++;} LEFT_PARENTHESIS {currentScope++;} idlist {currentScope--;}RIGHT_PARENTHESIS block {nestedFunctionCounter--;cout<<"funcdef -> FUNCTION LEFT_PARENTHESIS idlist RIGHT_PARENTHESIS block \n";}
                | FUNCTION IDENT {if(LookUpFunction($2)) addToSymbolTable($2, currentScope, yylineno, USERFUNC); nestedFunctionCounter++;}  LEFT_PARENTHESIS {currentScope++;} idlist {currentScope--;} RIGHT_PARENTHESIS block {nestedFunctionCounter--;cout<<"funcdef -> FUNCTION IDENT LEFT_PARENTHESIS idlist RIGHT_PARENTHESIS block\n";}
                ;

const:            INTCONST {cout<<"const -> INTCONST\n";}
                | DOUBLECONST {cout<<"const -> DOUBLECONST\n";}
                | STRING {cout<<"const -> String\n";}
                | NIL {cout<<"const -> NIL\n";}
                | TRUE {cout<<"const -> TRUE\n";}
                | FALSE {cout<<"const -> FALSE\n";}
                ;

idlist:           IDENT {
                            if(libFunctions[$1]) {
                                cout<<"ERROR at line "<<yylineno<<": Collision with library function"<<endl;
                            }else{
                                if(existsInScope($1, currentScope)){
                                    addToSymbolTable($1, currentScope, yylineno, FORMAL);
                                }
                            }
                            cout<<"idlist -> IDENT\n";    
                        }
                | idlist COMMA IDENT {
                            if(libFunctions[$3]){
                                cout<<"ERROR at line "<<yylineno<<": Collision with library function"<<endl;
                            }else{ 
                                if(existsInScope($3, currentScope)){
                                    addToSymbolTable($3, currentScope, yylineno, FORMAL);
                                }
                            }
                            cout<<"idlist -> idlist COMMA IDENT\n";   
                        }
                | {cout<<"idlist -> \n";}
                ;


ifstmt:           IF LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt {cout<<"ifstmt -> IF LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt\n";}
                | IF LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt ELSE stmt {cout<<" ifstmt -> IF LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt\n";}
                ;

whilestmt:        WHILE {nestedLoopCounter++;} LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt {nestedLoopCounter--;cout<<"whilestmt -> WHILE LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt\n";}
                ;

forstmt:          FOR {nestedLoopCounter++;} LEFT_PARENTHESIS elist SEMICOLON expr SEMICOLON elist RIGHT_PARENTHESIS stmt {nestedLoopCounter--;cout<<"forstmt -> FOR LEFT_PARENTHESIS elist SEMICOLON expr SEMICOLON elist RIGHT_PARENTHESIS stmt\n";}
                ;

returnstmt:       RETURN SEMICOLON {cout<<"returnstmt -> RETURN SEMICOLON\n";}
                | RETURN expr SEMICOLON {cout<<"RETURN expr SEMICOLON\n";}
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
        cout<<"ERROR:"<<name<<" at line "<< yylineno<<" has same name with library function"<<endl;
        return false;
    }
    for(int i=0; i<SymbolTable[name].size(); i++){
        if(SymbolTable[name][i]->getType()<=2 && SymbolTable[name][i]->isActive()){
            cout<<"ERROR:"<<name<<" at line "<< yylineno<<" has same name with active variable at line:"<<SymbolTable[name][i]->getLine()<<endl;
            return false;
        }
        if(SymbolTable[name][i]->getType()>=3 && SymbolTable[name][i]->isActive() && SymbolTable[name][i]->getScope()==currentScope){
            cout<<"ERROR at line "<<yylineno<<": Collision with function from line "<<SymbolTable[name][i]->getLine()<<endl;
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
LookUpVariable(string name, int flag){
    if(libFunctions[name]){
        return false;
    }
    for(int i=SymbolTable[name].size()-1; i>=0; i--){
        if(SymbolTable[name][i]->isActive()){
            if(flag==0){
                if(SymbolTable[name][i]->getType()==2 && currentScope>SymbolTable[name][i]->getScope())
                    cout<<"ERROR:"<<name<<" at line:"<<yylineno<<" is formal variable of a previous scope function."<<endl;
                if(SymbolTable[name][i]->getType()==1 && !LookUpScope("", SymbolTable[name][i]->getScope()))
                    cout<<"ERROR:"<<name<<" at line:"<<yylineno<<" is local variable of a previous scope function."<<endl;
                return false;
            }
            else
                return true;
        }
    }
    return true;
}

void LookUpRvalue(string name){
    for(int i=SymbolTable[name].size()-1; i>=0 ;i--) {
        if(SymbolTable[name][i]->isActive()){
            if(SymbolTable[name][i]->getType()==1)
                break;
            else if(SymbolTable[name][i]->getType()>2){
                cout<<"ERROR:"<<name<<" at line:"<<yylineno<<" is an active user function and it cannot be l-value."<<endl;
                break;
            }
        }
    }
}
/*
    Searches in given scope for a variable or function with given name
*/
bool LookUpScope(string name, int scope) {
    if(name==""){
        for(int it=currentScope-1; it>=scope; it--){
            for(int i=0; i<ScopeTable[it].size(); i++){
                if(ScopeTable[it][i]->getType()==3 && ScopeTable[it][i]->isActive()&& it!=0 && libFunctions[ScopeTable[it][i]->getName()]!=1){
                    return false;
                }
            }
        }
    }
    else{
        for(int i=0; i<ScopeTable[0].size(); i++){
            if(ScopeTable[0][i]->getName()==name){
                return true;
            }
        }
        cout<<"ERROR:"<<name<<" at line:"<<yylineno<<" Couldn't find global variable with same name."<<endl;
        return false;
    }
    return true;
}
bool
existsInScope(string name, int scope){

    for(int i=0; i<ScopeTable[scope].size(); i++){
        if(ScopeTable[scope][i]->getName()==name && ScopeTable[scope][i]->isActive()){
            cout<<"ERROR:"<<name<<" at line:"<<yylineno<<" . Variable already defined."<<endl;
            return false;
        }
    }
    return true;
}
void
isFormalFromAncestorFunction(string name){

        if(SymbolTable[name][SymbolTable[name].size()-1]->isActive() && currentScope>SymbolTable[name][SymbolTable[name].size()-1]->getScope()){
            if(SymbolTable[name][SymbolTable[name].size()-1]->getType()==2)
                cout<<"ERROR:"<<name<<" is formal variable of ancestor function.\n";
            else if(SymbolTable[name][SymbolTable[name].size()-1]->getType()==1)
                cout<<"ERROR:"<<name<<" is local variable of ancestor function.\n";
        }
}

void
callFunction(string name){
    
    for(int i=0; i<SymbolTable[name].size(); i++){
        if(SymbolTable[name][i]->isActive() && SymbolTable[name][i]->getType()==1 and !libFunctions[name]){
            cout<<"ERROR at line "<<yylineno<<": can't call a variable."<<name<<endl;
        }
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