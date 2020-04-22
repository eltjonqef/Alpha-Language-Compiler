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
    expr* emit_if_table(expr* e);
    expr* member_item(expr* lv, char* name);
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
    expr* newexpr_constbool(bool a);
    expr* expressionHolder;
%}



%union {
    int intValue;
    char* stringValue;
    double doubleValue;
    class expr *expressionUnion;
    class forprefix *forprefix;
    class stmt_t *stmtLists;
}   

%start program

%token IF ELSE WHILE FOR FUNCTION RETURN BREAK CONTINUE AND NOT OR LOCAL TRUE FALSE NIL
%token '=' '+' '-' '*' '/' '%' EQUAL NOT_EQUAL PLUS_PLUS MINUS_MINUS '>' '<' GREATER_EQUAL LESS_EQUAL
%token ';' ',' ':' COLON_COLON '.' DOT_DOT '{' '}' '[' ']' '(' ')' 
%token UMINUS
%token <stringValue> IDENT
%token <intValue> INTCONST
%token <stringValue> STRING
%token <doubleValue> DOUBLECONST

%type <expressionUnion> const
%type <expressionUnion> primary
%type <expressionUnion> term
%type <expressionUnion> expr
%type <expressionUnion> assignexpr
%type <expressionUnion> lvalue
%type <expressionUnion> objectdef
%type <expressionUnion> member
%type <expressionUnion> ifstmt
%type <expressionUnion> elist
%type <expressionUnion> indexedelem
%type <expressionUnion> indexed
%type <forprefix> forprefix
%type <uintvalue> N
%type <uintvalue> M
%type <stmtLists> stmt;
%type <stmtLists> block;
%type <stmtLists> loopstmt;
%type <stmtLists> whilestmt;
%type <stmtLists> forstmt;
%type <stmtLists> ifstmt;


%right '='
%left OR
%left AND
%nonassoc EQUAL NOT_EQUAL
%nonassoc '>' GREATER_EQUAL '<' LESS_EQUAL
%left '+' '-' 
%left '*' '/' '%'
%right NOT PLUS_PLUS MINUS_MINUS UMINUS
%left '.' DOT_DOT
%left '[' ']'
%left '(' ')'






%%
program:          loopstmt {}
                ;

loopstmt:         loopstmt stmt {
                                    $$ = new stmt_t();
                                    
                                    $$->breakList = mergelist($1->breakList,$2->breakList);
                                    $$->continueList = mergelist($1->continueList,$2->continueList);
                                }
                | {$$ = new stmt_t();   }
                ;
stmt:             expr ';' {$$=new stmt_t();}
                | ifstmt {$$=$1;}
                | whilestmt {$$=$1;}
                | forstmt {$$=$1;}
                | {returnState=1;}returnstmt {returnState=0; if(!nestedFunctionCounter) {cout<<"ERROR at line "<<yylineno<<": return while not inside a function."<<endl;}$$=new stmt_t();}
                | BREAK ';' {   
                                if(!nestedLoopCounter) {
                                    cout<<"ERROR at line "<<yylineno<<": break while not inside a loop."<<endl;
                                }
                                int hold = labelLookahead();
                                expr* expression = new expr(label_e);
                                expression->setJumpLab(0);
                                emit(jump_op,NULL,expression,NULL,getNextLabel(),yylineno);
                                $$ = new stmt_t();
                                cout<<"HOLD "<<hold<<"\n";
                                $$->breakList = newList(hold);
                            }
                | CONTINUE ';' {
                                    if(!nestedLoopCounter) {
                                        cout<<"ERROR at line "<<yylineno<<": continue while not inside a loop."<<endl;
                                    }
                                    int hold = labelLookahead();
                                    expr* expression = new expr(label_e);
                                    expression->setJumpLab(0);
                                    emit(jump_op,NULL,expression,NULL,getNextLabel(),yylineno);
                                    $$ = new stmt_t();
                                    $$->continueList = newList(hold);
                               }
                | block {$$=$1;}
                | funcdef {$$=new stmt_t();}
                | ';' {}
                ;

expr:             assignexpr {$$=$1; }
                | expr '+' expr {           
                                    expr* expression=new expr(arithexpr_e);
                                    expression->sym = addToSymbolTable(nextVariableName(), currentScope, yylineno,getGlobLocl(),var_s);
                                    expression->sym->setScopespace(getCurrentScopespace());
                                    expression->sym->setOffset(0);
                                    emit(add_op, expression, $1, $3, getNextLabel(), yylineno);
                                    $$=expression;
                                }
                | expr '-' expr {           
                                    expr* expression=new expr(arithexpr_e);
                                    expression->sym = addToSymbolTable(nextVariableName(), currentScope, yylineno,getGlobLocl(),var_s);
                                    expression->sym->setScopespace(getCurrentScopespace());
                                    expression->sym->setOffset(0);
                                    emit(sub_op, expression, $1, $3, getNextLabel(), yylineno);
                                    $$=expression;
                                }
                | expr '*' expr {           
                                    expr* expression=new expr(arithexpr_e);
                                    expression->sym = addToSymbolTable(nextVariableName(), currentScope, yylineno,getGlobLocl(),var_s);
                                    expression->sym->setScopespace(getCurrentScopespace());
                                    expression->sym->setOffset(0);
                                    emit(mul_op, expression, $1, $3, getNextLabel(), yylineno);
                                    $$=expression;
                                }
                | expr '/' expr {           
                                    expr* expression=new expr(arithexpr_e);
                                    expression->sym = addToSymbolTable(nextVariableName(), currentScope, yylineno,getGlobLocl(),var_s);
                                    expression->sym->setScopespace(getCurrentScopespace());
                                    emit(div_op, expression, $1, $3, getNextLabel(),yylineno);
                                    expression->sym->setOffset(0);
                                    $$=expression;
                                }
                | expr '%' expr {            
                                    expr* expression=new expr(arithexpr_e);
                                    expression->sym = addToSymbolTable(nextVariableName(), currentScope, yylineno,getGlobLocl(),var_s);
                                    expression->sym->setScopespace(getCurrentScopespace());
                                    expression->sym->setOffset(0);
                                    emit(mod_op, expression, $1, $3, getNextLabel(), yylineno);
                                    $$=expression;
                                }
                | expr '>' expr {
                    expr* expression=new expr(boolexpr_e);
                    expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                    expression->sym->setScopespace(getCurrentScopespace());
                    expression->sym->setOffset(0);
                    expr* jumpExp = new expr(label_e);
                    expr* ifJumpExp = new expr(label_e);
                    ifJumpExp->setJumpLab(labelLookahead()+3);

                    emit(if_greater_op,ifJumpExp,$1,$3,getNextLabel(),yylineno);
                    emit(assign_op,expression,newexpr_constbool(0),NULL,getNextLabel(),yylineno);
                    jumpExp->setJumpLab(labelLookahead()+2);
                    emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);
                    emit(assign_op,expression,newexpr_constbool(1),NULL,getNextLabel(),yylineno);
                    $$ = expression;
                }
                | expr GREATER_EQUAL expr {
                    expr* expression=new expr(boolexpr_e);
                    expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                    expression->sym->setScopespace(getCurrentScopespace());
                    expression->sym->setOffset(0);
                    expr* jumpExp = new expr(label_e);
                    expr* ifJumpExp = new expr(label_e);
                    ifJumpExp->setJumpLab(labelLookahead()+3);

                    emit(if_greatereq_op,ifJumpExp,$1,$3,getNextLabel(),yylineno);
                    emit(assign_op,expression,newexpr_constbool(0),NULL,getNextLabel(),yylineno);
                    jumpExp->setJumpLab(labelLookahead()+2);
                    emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);
                    emit(assign_op,expression,newexpr_constbool(1),NULL,getNextLabel(),yylineno);
                    $$ = expression;
                }
                | expr '<' expr {
                    expr* expression=new expr(boolexpr_e);
                    expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                    expression->sym->setScopespace(getCurrentScopespace());
                    expression->sym->setOffset(0);
                    expr* jumpExp = new expr(label_e);
                    expr* ifJumpExp = new expr(label_e);
                    ifJumpExp->setJumpLab(labelLookahead()+3);

                    emit(if_less_op,ifJumpExp,$1,$3,getNextLabel(),yylineno);
                    emit(assign_op,expression,newexpr_constbool(0),NULL,getNextLabel(),yylineno);
                    jumpExp->setJumpLab(labelLookahead()+2);
                    emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);
                    emit(assign_op,expression,newexpr_constbool(1),NULL,getNextLabel(),yylineno);
                    $$ = expression;
                }
                | expr LESS_EQUAL expr {
                    expr* expression=new expr(boolexpr_e);
                    expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                    expression->sym->setScopespace(getCurrentScopespace());
                    expression->sym->setOffset(0);
                    expr* jumpExp = new expr(label_e);
                    expr* ifJumpExp = new expr(label_e);
                    ifJumpExp->setJumpLab(labelLookahead()+3);

                    emit(if_lesseq_op,ifJumpExp,$1,$3,getNextLabel(),yylineno);
                    emit(assign_op,expression,newexpr_constbool(0),NULL,getNextLabel(),yylineno);
                    jumpExp->setJumpLab(labelLookahead()+2);
                    emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);
                    emit(assign_op,expression,newexpr_constbool(1),NULL,getNextLabel(),yylineno);
                    $$ = expression;
                }
                | expr EQUAL expr {
                    expr* expression=new expr(boolexpr_e);
                    expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                    expression->sym->setScopespace(getCurrentScopespace());
                    expression->sym->setOffset(0);
                    expr* jumpExp = new expr(label_e);
                    expr* ifJumpExp = new expr(label_e);
                    ifJumpExp->setJumpLab(labelLookahead()+3);

                    emit(if_eq_op,ifJumpExp,$1,$3,getNextLabel(),yylineno);
                    emit(assign_op,expression,newexpr_constbool(0),NULL,getNextLabel(),yylineno);
                    jumpExp->setJumpLab(labelLookahead()+2);
                    emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);
                    emit(assign_op,expression,newexpr_constbool(1),NULL,getNextLabel(),yylineno);
                    $$ = expression;
                }
                | expr NOT_EQUAL expr {
                    expr* expression=new expr(boolexpr_e);
                    expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                    expression->sym->setScopespace(getCurrentScopespace());
                    expression->sym->setOffset(0);
                    expr* jumpExp = new expr(label_e);
                    expr* ifJumpExp = new expr(label_e);
                    ifJumpExp->setJumpLab(labelLookahead()+3);

                    emit(if_noteq_op,ifJumpExp,$1,$3,getNextLabel(),yylineno);
                    emit(assign_op,expression,newexpr_constbool(0),NULL,getNextLabel(),yylineno);
                    jumpExp->setJumpLab(labelLookahead()+2);
                    emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);
                    emit(assign_op,expression,newexpr_constbool(1),NULL,getNextLabel(),yylineno);
                    $$ = expression;
                }
                | expr AND expr {
                    expr* expression = new expr(boolexpr_e);
                    expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                    emit(and_op,expression,$1,$3,getNextLabel(),yylineno);
                    $$ = expression;
                }
                | expr OR expr {
                    expr* expression = new expr(boolexpr_e);
                    expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                    emit(or_op,expression,$1,$3,getNextLabel(),yylineno);
                    $$ = expression;
                }
                | term {$$=$1;}
                ;

term:             '(' expr ')' {$$=$2;}
                | '-' expr %prec UMINUS{
                                expr* expression = new expr(arithexpr_e);
                                expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                                expression->sym->setScopespace(getCurrentScopespace());
                                expression->sym->setOffset(0);
                                emit(uminus_op,expression,$2,NULL,getNextLabel(),yylineno);
                                $$=expression;
                              }
                | NOT expr  {
                                expr* expression=new expr(boolexpr_e);
                                expression->sym=addToSymbolTable(nextVariableName(), currentScope, yylineno,getGlobLocl(),var_s);
                                expression->sym->setOffset(0);
                                expression->sym->setScopespace(getCurrentScopespace());
                                emit(not_op, expression, $2, NULL, getNextLabel(), yylineno);
                                $$=expression;
                            }
                | PLUS_PLUS lvalue  {/*LookUpRvalue($2);*/
                                        expr *arrExpr=new expr(constnum_e);
                                        arrExpr->setNumConst(1);
                                        emit(add_op, $2, $2, arrExpr, getNextLabel(), yylineno);
                                        expr* expression= new expr(arithexpr_e);
                                        expression->sym=addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                                        expression->sym->setScopespace(getCurrentScopespace());
                                        expression->sym->setOffset(0);
                                        emit(assign_op, expression, $2, NULL, getNextLabel(), yylineno);
                                        $$=expression;
                                    }
                | lvalue PLUS_PLUS {/*LookUpRvalue($1);*/
                                        expr* expression= new expr(arithexpr_e);
                                        expression->sym=addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                                        expression->sym->setScopespace(getCurrentScopespace());
                                        expression->sym->setOffset(0);
                                        emit(assign_op, expression, $1, NULL, getNextLabel(), yylineno);
                                        expr *arrExpr=new expr(constnum_e);
                                        arrExpr->setNumConst(1);
                                        emit(add_op, $1, $1, arrExpr, getNextLabel(), yylineno);
                                        $$=expression; 
                                   }
                | MINUS_MINUS lvalue {/*LookUpRvalue($2);*/
                                        expr *arrExpr=new expr(constnum_e);
                                        arrExpr->setNumConst(1);
                                        emit(sub_op, $2, $2, arrExpr, yylineno, 0);
                                        expr* expression= new expr(arithexpr_e);
                                        expression->sym=addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                                        expression->sym->setScopespace(getCurrentScopespace());
                                        expression->sym->setOffset(0);
                                        emit(assign_op, expression, $2, NULL, getNextLabel(), yylineno);
                                        $$=expression;
                                     }
                | lvalue MINUS_MINUS {/*LookUpRvalue($1);*/
                                        expr* expression= new expr(arithexpr_e);
                                        expression->sym=addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                                        expression->sym->setScopespace(getCurrentScopespace());
                                        expression->sym->setOffset(0);
                                        emit(assign_op, expression, $1, NULL, getNextLabel(), yylineno);
                                        expr *arrExpr=new expr(constnum_e);
                                        arrExpr->setNumConst(1);
                                        emit(sub_op, $1, $1, arrExpr, getNextLabel(), yylineno);
                                        $$=expression; 
                                     }
                | primary {$$=$1;}
                ;

assignexpr:       lvalue '=' expr {
                                    if($1->getType()==tableitem_e){
                                            emit(tablesetelem_op, $1->getIndex(), $1, $3, getNextLabel(), yylineno);
                                            expr* expression=emit_if_table($1);
                                            expression->setType(assignexpr_e);
                                            $$=expression;
                                        }
                                    else{           
                                        emit(assign_op, $1, $3, NULL, getNextLabel(), yylineno);
                                        expr* expression=new expr(assignexpr_e);
                                        expression->sym = addToSymbolTable(nextVariableName(), currentScope, yylineno,getGlobLocl(),var_s);
                                        expression->sym->setScopespace(getCurrentScopespace());
                                        expression->sym->setOffset(0);
                                        emit(assign_op, expression,$1, NULL, getNextLabel(), yylineno);
                                        $$=expression;
                                    }
                                  }
                ;

primary:          lvalue {
                            expr* expression=emit_if_table($1);
                            $$=expression;
                         }
                | call {}
                | objectdef {$$=$1;}
                | '(' funcdef ')' {}
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
                            $$=expression;
                        }   
                | LOCAL IDENT {expr *expression=new expr(var_e);expression->sym=LookUpVariable($2, 1); if(expression->sym==NULL){
                                    expression->sym=addToSymbolTable($2, currentScope, yylineno, LOCL,var_s);Flag=1;expression->sym->setOffset(currentOffset());expression->sym->setScopespace(getCurrentScopespace());incCurScopeOffset(); }
                                    else if(libFunctions[$2])cout<<"ERROR at line "<<yylineno<<": Collision with library function"<<endl;

                              } 
                | COLON_COLON IDENT { /*expr *expression=new expr(var_e); expression->sym=LookUpScope($2, 0); Flag=1;*/}
                | member {$$=$1;}
                ;

member:           lvalue '.' IDENT {
                                        $$=member_item($1, $3);
                                   }
                | lvalue '[' expr ']'{
                                        $1=emit_if_table($1);
                                        expr* expression=new expr(tableitem_e);
                                        expression->sym=$1->sym;
                                        expression->setIndex($3);
                                        $$=expression;
                                     }
                | call '.' IDENT {}
                | call '[' expr ']'{}
                ;

call:             call '(' elist ')' {}
                | lvalue callsuffix {/*if(callFlag==1){callFlag=0;}else {if(!returnState) callFunction($1);} */}
                | '(' funcdef ')' '(' elist ')' {}
                ;

callsuffix:       normcall {}
                | methodcall {}
                ;

normcall:         '(' elist ')' {}
                ;

methodcall:       DOT_DOT IDENT {if(!returnState) callFlag=1; callFunction($2);} '(' elist ')' {}
                ;

elist:            expr {$$=$1; $$->setNext(NULL);}
                | expr ',' elist {$1->setNext($3); $$=$1;}
                |{}
                ;

objectdef:        '[' elist ']' {
                                    expr* expression=new expr(newtable_e);
                                    expression->sym=addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                                    expression->sym->setScopespace(getCurrentScopespace());
                                    expression->sym->setOffset(0);
                                    emit(tablecreate_op, expression, NULL, NULL, getNextLabel(), yylineno);
                                    for(int i=0; $2; $2=$2->getNext()){
                                       emit(tablesetelem_op,expression,new expr(i++), $2, getNextLabel(), yylineno); 
                                    }
                                    tableEntries.clear();
                                    $$=expression;

                                }
                | '[' indexed ']'{
                                    expr* expression=new expr(newtable_e);
                                    expression->sym=addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                                    expression->sym->setScopespace(getCurrentScopespace());
                                    expression->sym->setOffset(0);
                                    emit(tablecreate_op, expression, NULL, NULL, getNextLabel(), yylineno);
                                    for(int i=0; $2; $2=$2->getNext()){
                                        emit(tablesetelem_op, expression, $2->getIndex(), $2, getNextLabel(), yylineno);
                                    }
                                    $$=expression;
                                 }
                ;

indexed:          indexedelem {$$=$1; $$->setNext(NULL);}
                | indexedelem ',' indexed {$1->setNext($3); $$=$1;}
                ;

indexedelem:      '{' expr ':' expr '}' {$4->setIndex($2); $$=$4;}
                ;

block:            '{' {currentScope++;} loopstmt {decreaseScope();} '}' {}
                ;

funcdef:          FUNCTION {
                                nestedFunctionCounter++; expr *expression=new expr(programfunc_e); 
                                expression->sym=addToSymbolTable("$"+to_string(anonymousFuntionCounter++), currentScope, yylineno, USERFUNC,programfunc_s);
                                funcExprStack.push(expression);
                                emit(funcstart_op,expression,NULL,NULL,getNextLabel(),yylineno);
                            }  
                        '(' {
                                currentScope++;
                                enterScopespace();
                            } 
                    idlist {
                                currentScope--;enterScopespace();
                                saveAndResetFunctionOffset();
                            }
                        ')' {
                                loopCounterStack.push(nestedFunctionCounter);
                                nestedFunctionCounter = 0;
                            }
                    block  {
                                nestedFunctionCounter--;
                                exitScopespace();exitScopespace();
                                getPrevFunctionOffset();
                                emit(funcend_op,funcExprStack.top(),NULL,NULL,getNextLabel(),yylineno);
                                funcExprStack.pop();
                                nestedFunctionCounter = loopCounterStack.top();
                                loopCounterStack.pop();
                            }
                | FUNCTION IDENT {
                                    if(LookUpFunction($2)) {
                                        expr *expression=new expr(programfunc_e);
                                        expression->sym= addToSymbolTable($2, currentScope, yylineno, USERFUNC,programfunc_s); 
                                        nestedFunctionCounter++;
                                        funcExprStack.push(expression);
                                        emit(funcstart_op,expression,NULL,NULL,getNextLabel(),yylineno);
                                    }else{
                                        assert(0);
                                    }
                                } 
                            '(' {
                                    currentScope++;
                                    enterScopespace();
                                    resetFormalArgOffsetCounter();
                                } 
                        idlist {
                                    currentScope--;
                                } 
                        ')'    {
                                    enterScopespace();
                                    saveAndResetFunctionOffset();
                                    loopCounterStack.push(nestedFunctionCounter);
                                    nestedFunctionCounter = 0;
                                }
                        block   {
                                    nestedFunctionCounter--;
                                    exitScopespace();exitScopespace();
                                    getPrevFunctionOffset();
                                    emit(funcend_op,funcExprStack.top(),NULL,NULL,getNextLabel(),yylineno);
                                    funcExprStack.pop();
                                    nestedFunctionCounter = loopCounterStack.top();
                                    loopCounterStack.pop();
                                }
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
                | idlist ',' IDENT {
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


ifstmt:           IF '(' expr ')'{
                                    expr* expression = new expr(label_e);
                                    expression->setJumpLab(labelLookahead()+2);
                                    emit(if_eq_op,expression,$expr,newexpr_constbool(1),getNextLabel(),yylineno);
                                    ifQuadStack.push(labelLookahead());
                                    cout<<"pushed "<<labelLookahead()<<"\n";
                                    emit(jump_op,NULL,NULL,NULL,getNextLabel(),yylineno);
                                 }
                            stmt {
                                expr* expression = new expr(label_e);
                                expression->setJumpLab(labelLookahead());
                                cout<<"patching "<<labelLookahead()<<" at quad "<<getQuadFromLabel(ifQuadStack.top()).getLabel()<<endl;
                                backpatchArg1(ifQuadStack.top()-1,expression);
                                cout<<"popped "<<ifQuadStack.top()<<"\n";
                                ifQuadStack.pop();
                            }
                | IF '(' expr ')'{
                                    expr* expression = new expr(label_e);
                                    expression->setJumpLab(labelLookahead()+2);
                                    emit(if_eq_op,expression,$expr,newexpr_constbool(1),getNextLabel(),yylineno);
                                    ifQuadStack.push(labelLookahead());
                                    emit(jump_op,NULL,NULL,NULL,getNextLabel(),yylineno);
                                 } 
                            stmt {
                                expr* expression = new expr(label_e);
                                expression->setJumpLab(labelLookahead()+1);
                                backpatchArg1(ifQuadStack.top()-1,expression);
                                ifQuadStack.pop();
                                ifQuadStack.push(labelLookahead());
                                emit(jump_op,NULL,NULL,NULL,getNextLabel(),yylineno);
                                } 
                    ELSE stmt   {
                                expr* expression = new expr(label_e);
                                expression->setJumpLab(labelLookahead());
                                backpatchArg1(ifQuadStack.top()-1,expression);
                                ifQuadStack.pop();
                           }
                ;

whilestmt:        WHILE {nestedLoopCounter++;
                            whileStartStack.push(labelLookahead());
                        } 
            '(' expr ')'{
                            expr* expression = new expr(label_e);
                            expression->setJumpLab(labelLookahead()+2);
                            emit(if_eq_op,expression,$expr,newexpr_constbool(1),getNextLabel(),yylineno);

                            whileSecondStack.push(labelLookahead());
                            emit(jump_op,NULL,NULL,NULL,getNextLabel(),yylineno);
                        } 
                   stmt {
                            nestedLoopCounter--;

                            expr* expression = new expr(label_e);
                            expression->setJumpLab(whileStartStack.top());
                            
                            cout<<"first jump set on "<<expression->getJumpLab()<<"\n";
                            emit(jump_op,NULL,expression,NULL,getNextLabel(),yylineno);

                            expr* expression2 = new expr(label_e);
                            expression2->setJumpLab(labelLookahead());
                            backpatchArg1(whileSecondStack.top()-1,expression2);
                            whileSecondStack.pop();
                            patchlist($stmt->breakList,labelLookahead());
                            patchlist($stmt->continueList,whileStartStack.top());
                            whileStartStack.pop();
                            //must add continue-break stuff
                        }
                ;

N: {$$=labelLookahead(); emit(jump_op, NULL, NULL, NULL, getNextLabel(), yylineno);}
M: {$$=labelLookahead();}

forprefix:              FOR {nestedLoopCounter++;} '(' elist ';' M expr ';' {
                                                                            forprefix *forprx=new forprefix();
                                                                            forprx->setTest($M);
                                                                            forprx->setEnter(labelLookahead());
                                                                            emit(if_eq_op,$expr, newexpr_constbool(1), 0, getNextLabel(),yylineno);
                                                                            $$=forprx;
                                                                          }
forstmt:          forprefix N elist ')' N stmt N{
                                                    nestedLoopCounter--;
                                                    expr *temp1= new expr(label_e);
                                                    temp1->setJumpLab($5+1);
                                                    backpatchArg1($1->getEnter(), temp1);
                                                    expr *temp2= new expr(label_e);
                                                    temp2->setJumpLab(labelLookahead());
                                                    backpatchArg1($2, temp2);
                                                    expr *temp3= new expr(label_e);
                                                    temp3->setJumpLab($1->getTest());
                                                    backpatchArg1($5, temp3);
                                                    
                                                    expr *temp4= new expr(label_e);
                                                    temp4->setJumpLab($2+1);
                                                    backpatchArg1($7, temp4);

                                                }
                ;

returnstmt:       RETURN ';' {}
                | RETURN expr ';' {}
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

expr*
emit_if_table(expr* e){

    if(e->getType() != tableitem_e){
        return e;
    }
    else{
        expr *result= new expr(var_e);
        result->sym=addToSymbolTable(nextVariableName(), currentScope, yylineno,getGlobLocl(),var_s);
        emit(tablegetelem_op, result, e, e->getIndex(), getNextLabel(), yylineno);
        return result;
    }
}


expr* newexpr_constbool(bool a){
    expr* retval;
    retval = new expr(constbool_e);
    if(!a){
        retval->setBoolConst(0);
    }else{
        retval->setBoolConst(1);
    }
    return retval;
}


expr* member_item(expr* lv, char* name){
    lv=emit_if_table(lv);
    expr* ti=new expr(tableitem_e);
    ti->sym=lv->sym;
    ti->setIndex(new expr(name));
    return ti;
}