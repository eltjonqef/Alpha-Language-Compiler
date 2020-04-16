%{
    #include <stdio.h>
    #include <iostream>
    #include <string>
    #include <string.h>
    #include <map>
    #include <vector>
    #include "Quads.hpp"

    

    int yyerror(string yaccProvideMessage);
    int yylex();
    void InitilizeLibraryFunctions();
    SymbolTableEntry *addToSymbolTable(string _name, int _scope, int _line, SymbolType _type,symbol_t _symtype);
    void decreaseScope();
    void printSymbolTable();
    bool LookUpScope(string name, int scope);
    bool LookUpFunction(string name);
    SymbolTableEntry *LookUpVariable(string variable, int flag);
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


    int anonymousFuntionCounter=0;
    map <string,vector<SymbolTableEntry*> > SymbolTable;
    map <int,vector<SymbolTableEntry*> > ScopeTable;
    map <string, int> libFunctions;

    //phase3
    string iopcodeToString(iopcode _opcode);
    void printQuads();
    unsigned int tempVariableCount = 0;
    string nextVariableName();
    SymbolType getGlobLocl();
%}



%union {
    int intValue;
    char* stringValue;
    double doubleValue;
    class expr *expressionUnion;
}   

%start program

%token IF ELSE WHILE FOR FUNCTION RETURN BREAK CONTINUE AND NOT OR LOCAL TRUE FALSE NIL
%token ASSIGN PLUS MINUS MULTIPLY DIVIDE MOD EQUAL NOT_EQUAL PLUS_PLUS MINUS_MINUS GREATER LESS GREATER_EQUAL LESS_EQUAL
%token SEMICOLON COMMA COLON COLON_COLON DOT DOT_DOT LEFT_BRACE RIGHT_BRACE LEFT_BRACKET RIGHT_BRACKET LEFT_PARENTHESIS RIGHT_PARENTHESIS 
%token IDENT
%token INTCONST
%token STRING
%token DOUBLECONST
%token UMINUS

%type <expressionUnion> const
%type <expressionUnion> primary
%type <expressionUnion> term
%type <expressionUnion> expr

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
                | expr PLUS expr {           
                                expr *expression=new expr(arithexpr_e);
                                expression->sym=addToSymbolTable(nextVariableName(), currentScope, yylineno,getGlobLocl(),var_s);
                                expression->sym->setScopespace(getCurrentScopespace());
                                emit(add_op, expression, $1, $3, yylineno, 0);
                            }
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
                | term {$$=$1;}
                ;

term:             LEFT_PARENTHESIS expr RIGHT_PARENTHESIS {}
                | UMINUS expr {}
                | NOT expr {}
                | PLUS_PLUS lvalue {LookUpRvalue($2);}
                | lvalue PLUS_PLUS {LookUpRvalue($1);}
                | MINUS_MINUS lvalue {LookUpRvalue($2);}
                | lvalue MINUS_MINUS {LookUpRvalue($1);}
                | primary {$$=$1;}
                ;

assignexpr:       lvalue {if(Flag==1) Flag=0; else LookUpRvalue($1);} ASSIGN expr {}
                ;

primary:          lvalue {}
                | call {}
                | objectdef {}
                | LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS {}
                | const {$$=$1;}
                ;

   
lvalue:           IDENT {   
                            expr *expression=new expr(var_e);
                            expression->sym=LookUpVariable($1,0);
                            if(expression->sym==NULL){
                                if(currentScope == 0){
                                    expression->sym=addToSymbolTable($1, currentScope, yylineno,GLOB,var_s);
                                    expression->sym->setOffset(currentOffset());
                                    expression->sym->setScopespace(getCurrentScopespace());
                                    incCurScopeOffset();
                                }else{
                                    expression->sym=addToSymbolTable($1, currentScope, yylineno,LOCL,var_s);
                                    expression->sym->setOffset(currentOffset());
                                    expression->sym->setScopespace(getCurrentScopespace());
                                    incCurScopeOffset();
                                }
                            }
                            
                        }   
                | LOCAL IDENT {expr *expression=new expr(var_e);expression->sym=LookUpVariable($2, 1); if(expression->sym==NULL){
                                    expression->sym=addToSymbolTable($2, currentScope, yylineno, LOCL,var_s);Flag=1;expression->sym->setOffset(currentOffset());expression->sym->setScopespace(getCurrentScopespace());incCurScopeOffset(); }
                                    else if(libFunctions[$2])cout<<"ERROR at line "<<yylineno<<": Collision with library function"<<endl;

                              } 
                | COLON_COLON IDENT { /*expr *expression=new expr(var_e); expression->sym=LookUpScope($2, 0); Flag=1;*/}
                | member {}
                ;

member:           lvalue DOT IDENT {}
                | lvalue LEFT_BRACKET expr RIGHT_BRACKET{}
                | call DOT IDENT {}
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

funcdef:          FUNCTION {nestedFunctionCounter++; expr *expression=new expr(programfunc_e); expression->sym=addToSymbolTable("$"+to_string(anonymousFuntionCounter++), currentScope, yylineno, USERFUNC,programfunc_s); }  LEFT_PARENTHESIS {currentScope++;enterScopespace();} idlist {currentScope--;enterScopespace();saveAndResetFunctionOffset();}RIGHT_PARENTHESIS block {nestedFunctionCounter--;exitScopespace();exitScopespace();getPrevFunctionOffset();}
                | FUNCTION IDENT {if(LookUpFunction($2)) {expr *expression=new expr(programfunc_e);expression->sym= addToSymbolTable($2, currentScope, yylineno, USERFUNC,programfunc_s); nestedFunctionCounter++;} } LEFT_PARENTHESIS {currentScope++;enterScopespace();resetFormalArgOffsetCounter();} idlist {currentScope--;} RIGHT_PARENTHESIS {enterScopespace();saveAndResetFunctionOffset();}block {nestedFunctionCounter--;exitScopespace();exitScopespace();getPrevFunctionOffset();}
                ;

const:            INTCONST {expr *expression=new expr(constnum_e); expression->setNumConst($1);$$=expression;}
                | DOUBLECONST {expr *expression=new expr(constnum_e); expression->setNumConst($1);$$=expression;}
                | STRING {expr *expression=new expr(conststring_e); expression->setStringConst($1);$$=expression;}
                | NIL {expr *expression=new expr(nil_e); $$=expression;}
                | TRUE {expr *expression=new expr(constbool_e); expression->setBoolConst(1);$$=expression;}
                | FALSE {expr *expression=new expr(constbool_e); expression->setBoolConst(0);$$=expression;}
                ;
 
idlist:           IDENT {
                            if(libFunctions[$1]) {
                                cout<<"ERROR at line "<<yylineno<<": Collision with library function"<<endl;
                            }else{
                                if(existsInScope($1, currentScope)){
                                    expr *expression=new expr(var_e);expression->sym=addToSymbolTable($1, currentScope, yylineno, FORMAL,var_s);
                                    expression->sym->setOffset(currentOffset());
                                    expression->sym->setScopespace(getCurrentScopespace());
                                    incCurScopeOffset();
                                }
                            }
                                
                        }
                | idlist COMMA IDENT {
                            if(libFunctions[$3]){
                                cout<<"ERROR at line "<<yylineno<<": Collision with library function"<<endl;
                            }else{ 
                                if(existsInScope($3, currentScope)){
                                    expr *expression=new expr(var_e); expression->sym=addToSymbolTable($3, currentScope, yylineno, FORMAL,var_s);
                                    expression->sym->setOffset(currentOffset());
                                    expression->sym->setScopespace(getCurrentScopespace());
                                    incCurScopeOffset();
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
    printQuads();
    return 0;
}



SymbolType getGlobLocl(){
    if(currentScope ==0)return GLOB;
    return LOCL;
}


string nextVariableName(){
    string numberInString = to_string(tempVariableCount);
    string RetVal = "_t"+numberInString;
    tempVariableCount++;
    return RetVal;
}




SymbolTableEntry*
addToSymbolTable(string _name, int _scope, int _line, SymbolType _type,symbol_t _symtype) {
    SymbolTableEntry *newEntry = new SymbolTableEntry(_name,_scope,_line,_type,_symtype);
    SymbolTable[_name].push_back(newEntry);
    ScopeTable[_scope].push_back(newEntry);
    return newEntry;
}


/*
enum scopespace_t{
    programvar,functionlocal,formalarg
};
enum symbol_t {var_s,programfunc_s,libraryfunc_s};
*/



void
InitilizeLibraryFunctions(){
    addToSymbolTable("print",0,0,LIBFUNC,libraryfunc_s);
    addToSymbolTable("input",0,0,LIBFUNC,libraryfunc_s);
    addToSymbolTable("objectmemberkeys",0,0,LIBFUNC,libraryfunc_s);
    addToSymbolTable("objecttotalmembers",0,0,LIBFUNC,libraryfunc_s);
    addToSymbolTable("objectcopy",0,0,LIBFUNC,libraryfunc_s);
    addToSymbolTable("totalarguments",0,0,LIBFUNC,libraryfunc_s);
    addToSymbolTable("argument",0,0,LIBFUNC,libraryfunc_s);
    addToSymbolTable("typeof",0,0,LIBFUNC,libraryfunc_s);
    addToSymbolTable("strtonum",0,0,LIBFUNC,libraryfunc_s);
    addToSymbolTable("sqrt",0,0,LIBFUNC,libraryfunc_s);
    addToSymbolTable("cos",0,0,LIBFUNC,libraryfunc_s);
    addToSymbolTable("sin",0,0,LIBFUNC,libraryfunc_s);
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
SymbolTableEntry*
LookUpVariable(string name, int flag){
    if(libFunctions[name]){
        return NULL;
    }
    for(int i=SymbolTable[name].size()-1; i>=0; i--){
        if(SymbolTable[name][i]->isActive()){
            /*if(flag==0){
                if(SymbolTable[name][i]->getType()==2 && currentScope>SymbolTable[name][i]->getScope())
                    cout<<"ERROR:"<<name<<" at line:"<<yylineno<<" is formal variable of a previous scope function."<<endl;
                if(SymbolTable[name][i]->getType()==1 && !LookUpScope("", SymbolTable[name][i]->getScope()))
                    cout<<"ERROR:"<<name<<" at line:"<<yylineno<<" is local variable of a previous scope function."<<endl;
                return SymbolTable[name][i];
            }
            else*/
                return SymbolTable[name][i];
        }
    }
    return NULL;
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
                ScopeTable[it->first][i]->getLine()<<") (scope "<<ScopeTable[it->first][i]->getScope()<<" symtype:"<<
                ScopeTable[it->first][i]->Type_t_toString()<<" space:"<<ScopeTable[it->first][i]->Scopespace_toString()
                <<" offset:"<<ScopeTable[it->first][i]->getOffset()<<")\n";
        }
        it++;
    }

}

void printQuads(){
    for(int i=0; i<quads.size(); i++){
        cout<<quads[i].toString()<<endl;
    }
}