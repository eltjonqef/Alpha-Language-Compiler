%{
    #include <stdio.h>
    //#include <stdlib.h>
    //#include "SymbolTable.hpp"
    #include <iostream>
    #include <string>
    #include <string.h>
    #include <map>
    #include <vector>
    #include "Quads.hpp"

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
    extern void initEnumMap();
    extern int yylineno;
    extern char* yytext;
    extern FILE* yyin;

    unsigned int currentScope = 0;

    
    map <string,vector<SymbolTableEntry*> > SymbolTable;
    map <int,vector<SymbolTableEntry*> > ScopeTable;
    map <string, int> libFunctions;

    //phase3
    string iopcodeToString(iopcode _opcode);
    void printQuads();
    unsigned int tempVariableCount = 0;
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
program:          loopstmt {}
                ;

loopstmt:         loopstmt stmt {}
                | {}
                ;
stmt:             expr SEMICOLON {}
                | ifstmt {}
                | whilestmt {}
                | forstmt {}
                | {returnState=1;}returnstmt {returnState=0; if(!nestedFunctionCounter) {cout<<"ERROR at line "<<yylineno<<": return while not inside a function."<<endl;}
                    }
                | BREAK SEMICOLON {if(!nestedLoopCounter) {cout<<"ERROR at line "<<yylineno<<": break while not inside a loop."<<endl;}}
                | CONTINUE SEMICOLON {if(!nestedLoopCounter) {cout<<"ERROR at line "<<yylineno<<": continue while not inside a loop."<<endl;}}
                | block {}
                | funcdef {}
                | SEMICOLON {}
                ;

expr:             assignexpr { }
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

term:             LEFT_PARENTHESIS expr RIGHT_PARENTHESIS {}
                | UMINUS expr {}
                | NOT expr {}
                | PLUS_PLUS lvalue {LookUpRvalue($2);}
                | lvalue PLUS_PLUS {LookUpRvalue($1);}
                | MINUS_MINUS lvalue {LookUpRvalue($2);}
                | lvalue MINUS_MINUS {LookUpRvalue($1);}
                | primary {}
                ;

assignexpr:       lvalue {if(Flag==1) Flag=0; else LookUpRvalue($1);} ASSIGN expr {}
                ;

primary:          lvalue {}
                | call {}
                | objectdef {}
                | LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS {}
                | const {}
                ;


lvalue:           IDENT {   
                            $$ = $1;
                            if(LookUpVariable($1, 0)){
                                if(currentScope == 0){
                                    addToSymbolTable($1, currentScope, yylineno,GLOB);
                                }else{
                                    addToSymbolTable($1, currentScope, yylineno,LOCL);
                                }
                            }
                            
                        }   
                | LOCAL IDENT {$$=$2;if(LookUpVariable($2, 1)){
                                    addToSymbolTable($2, currentScope, yylineno, LOCL);Flag=1; }
                                    else if(libFunctions[$2])cout<<"ERROR at line "<<yylineno<<": Collision with library function"<<endl;
                                
                              } 
                | COLON_COLON IDENT {LookUpScope($2, 0); Flag=1;$$=$2;}
                | member {}
                ;

member:           lvalue DOT IDENT {$$=$3;}
                | lvalue LEFT_BRACKET expr RIGHT_BRACKET{}
                | call DOT IDENT {$$=$3;}
                | call LEFT_BRACKET expr RIGHT_BRACKET{}
                ;

call:             call LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {}
                | lvalue callsuffix {if(callFlag==1){callFlag=0;}else {if(!returnState) callFunction($1);} }
                | LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {}
                ;

callsuffix:       normcall {}
                | methodcall {}
                ;

normcall:         LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {}
                ;

methodcall:       DOT_DOT IDENT {if(!returnState) callFlag=1; callFunction($2);} LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {}
                ;

elist:            expr {}
                | expr COMMA elist {}
                |{}
                ;

objectdef:        LEFT_BRACKET elist RIGHT_BRACKET {}
                | LEFT_BRACKET indexed RIGHT_BRACKET {}
                ;

indexed:          indexedelem {}
                | indexedelem COMMA indexed {}
                ;

indexedelem:      LEFT_BRACE expr COLON expr RIGHT_BRACE {}
                ;

block:            LEFT_BRACE {currentScope++;} loopstmt {decreaseScope();} RIGHT_BRACE {}
                ;

funcdef:          FUNCTION {nestedFunctionCounter++;} LEFT_PARENTHESIS {currentScope++;} idlist {currentScope--;}RIGHT_PARENTHESIS block {nestedFunctionCounter--;}
                | FUNCTION IDENT {if(LookUpFunction($2)) addToSymbolTable($2, currentScope, yylineno, USERFUNC); nestedFunctionCounter++;}  LEFT_PARENTHESIS {currentScope++;} idlist {currentScope--;} RIGHT_PARENTHESIS block {nestedFunctionCounter--;}
                ;

const:            INTCONST {}
                | DOUBLECONST {}
                | STRING {}
                | NIL {}
                | TRUE {}
                | FALSE {}
                ;

idlist:           IDENT {
                            if(libFunctions[$1]) {
                                cout<<"ERROR at line "<<yylineno<<": Collision with library function"<<endl;
                            }else{
                                if(existsInScope($1, currentScope)){
                                    addToSymbolTable($1, currentScope, yylineno, FORMAL);
                                }
                            }
                                
                        }
                | idlist COMMA IDENT {
                            if(libFunctions[$3]){
                                cout<<"ERROR at line "<<yylineno<<": Collision with library function"<<endl;
                            }else{ 
                                if(existsInScope($3, currentScope)){
                                    addToSymbolTable($3, currentScope, yylineno, FORMAL);
                                }
                            }
                               
                        }
                | {}
                ;


ifstmt:           IF LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt {}
                | IF LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt ELSE stmt {}
                ;

whilestmt:        WHILE {nestedLoopCounter++;} LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt {nestedLoopCounter--;}
                ;

forstmt:          FOR {nestedLoopCounter++;} LEFT_PARENTHESIS elist SEMICOLON expr SEMICOLON elist RIGHT_PARENTHESIS stmt {nestedLoopCounter--;}
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

string opcodeToString(iopcode _opcode){
    iopcode temp = _opcode;
    switch(temp){
        case assign_op:return "assign";
        case add_op:return "add";
        case sub_op:return "sub";
        case mul_op:return "mul";
        case div_op:return "div";
        case mod_op:return "mod";
        case uminus_op:return "uminus";
        case and_op:return "and";
        case or_op:return "or";
        case not_op:return "not";
        case if_eq_op: return "if_eq";
        case if_noteq_op:return "if_noteq";
        case if_lesseq_op:return "if_lesseq";
        case if_greatereq_op:return "if_greatereq_op";
        case if_less_op:return "if_less";
        case if_greater_op:return "if_greater";
        case call_op:return "call";
        case param_op:return "param";
        case ret_op:return "return";
        case getretval_op: return "getretval";
        case funcstart_op:return "funcstart";
        case funcend_op:return "funcend";
        case tablecreate_op:return "tablecreate";
        case tablegetelem_op:return "tablegetelem";
        case tablesetelem_op:return "tablesetelem";
        /*maybe throw error here uwu*/
    }
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

void
LookUpRvalue(string name){
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
bool
LookUpScope(string name, int scope) {
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