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
    expr* make_call(expr* lv, expr* reversed_elist);
%}


%union {
    unsigned int uintvalue;
    int intValue;
    char* stringValue;
    double doubleValue;
    class expr *expressionUnion;
    class stmtLists *sttLists;
    class forprefix *forprefix;
    class call *call;
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
%type <expressionUnion> elist
%type <expressionUnion> indexedelem
%type <expressionUnion> indexed
%type <expressionUnion> returnstmt
%type <expressionUnion> call
%type <expressionUnion> funcdef
%type <forprefix> forprefix
%type <uintvalue> N
%type <uintvalue> M
%type <sttLists> ifstmt
%type <sttLists> stmt1
%type <sttLists> loopstmt
%type <sttLists> stmt
%type <sttLists> whilestmt
%type <sttLists> forstmt
%type <sttLists> block
%type <call> callsuffix
%type <call> normcall
%type <call> methodcall

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
                                cout<<"loopstmt\n";
                                   stmtLists* statement = new stmtLists();
                                   int a = $1->breaklist;
                                   int b = $2->breaklist;
                                   statement->breaklist = mergelist($1->breaklist,$2->breaklist);
                                   statement->continuelist = mergelist($1->continuelist,$2->continuelist);
                                   cout<<"loopstmt breaklist"<<statement->breaklist<<"  AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n";
                                   $$ = statement; 
                                }
                | {$$ = new stmtLists();cout<<"empty\n";}
                ;
stmt:             expr ';' {$$ = new stmtLists();cout<<"exp\n"; /*PROOF THAT IM RETARDED*/}
                | ifstmt {$$=$1;cout<<"if\n";}
                | whilestmt {$1->breaklist=0;$1->continuelist=0;$$=$1;cout<<"while\n";}
                | forstmt {$1->breaklist=0;$1->continuelist=0;$$=$1;cout<<"for\n";}
                | {returnState=1;}returnstmt {
                                                /*returnState=0; 
                                                if(!nestedFunctionCounter) {
                                                    cout<<"ERROR at line "<<yylineno<<": return while not inside a function."<<endl;
                                                }
                                                emit();
                                                */
                                                $$ = new stmtLists();
                                             }
                | BREAK ';' {
                            if(!nestedLoopCounter) {
                                cout<<"ERROR at line "<<yylineno<<": break while not inside a loop."<<endl;
                            }
                            stmtLists* statement = new stmtLists();
                            statement->breaklist = labelLookahead();
                            cout<<"break emited at "<<statement->breaklist<<"\n";
                            cout<<"break label will be "<<labelLookahead()<<"\n";
                            expr* expression = new expr(label_e);
                            expression->setJumpLab(0);
                            emit(jump_op,NULL,expression,NULL,getNextLabel(),yylineno);
                            $$ = statement;
                            cout<<"break\n";
                        }
                | CONTINUE ';' {
                                    if(!nestedLoopCounter) {
                                        cout<<"ERROR at line "<<yylineno<<": continue while not inside a loop."<<endl;
                                    }
                                    stmtLists* statement = new stmtLists();
                                    statement->continuelist = labelLookahead();
                                    cout<<"continue emited at "<<statement->continuelist<<"\n";
                                    expr* expression = new expr(label_e);
                                    expression->setJumpLab(0);
                                    emit(jump_op,NULL,expression,NULL,getNextLabel(),yylineno);
                                    $$ = statement;
                                    cout<<"CONTINUE\n";
                                }
                | block {$$=$1;cout<<"block\n";}
                | funcdef {$$ = new stmtLists();cout<<"funcdef\n";}
                | ';' {$$ = new stmtLists();cout<<"wtfwtfwtf\n";}
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
                    if($1->getType()==boolexpr_e){
                        patchlist($1->truelist,labelLookahead());
                        patchlist($1->falselist,labelLookahead()+2);
                        expr* expression = new expr(boolexpr_e);
                        expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                        expression->sym->setScopespace(getCurrentScopespace());
                        expression->sym->setOffset(0);
                        expression->setJumpLab(0);
                        expr* jumpExp = new expr(label_e);
                        jumpExp->setJumpLab(labelLookahead()+3);

                        emit(assign_op,NULL,expression,newexpr_constbool(1),getNextLabel(),yylineno);
                        emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);
                        emit(assign_op,NULL,expression,newexpr_constbool(0),getNextLabel(),yylineno);
                        $1=expression;
                    }
                    if($3->getType()==boolexpr_e){
                        patchlist($3->truelist,labelLookahead());
                        patchlist($3->falselist,labelLookahead()+2);
                        expr* expression = new expr(boolexpr_e);
                        expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                        expression->sym->setScopespace(getCurrentScopespace());
                        expression->sym->setOffset(0);
                        expression->setJumpLab(0);
                        expr* jumpExp = new expr(label_e);
                        jumpExp->setJumpLab(labelLookahead()+3);

                        emit(assign_op,NULL,expression,newexpr_constbool(1),getNextLabel(),yylineno);
                        emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);
                        emit(assign_op,NULL,expression,newexpr_constbool(0),getNextLabel(),yylineno);
                        $3=expression;
                    }
                    expr* expression=new expr(boolexpr_e);
                    expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                    expression->sym->setScopespace(getCurrentScopespace());
                    expression->sym->setOffset(0);
                    expr* jumpExp = new expr(label_e);
                    expr* ifJumpExp = new expr(label_e);
                    ifJumpExp->setJumpLab(0);
                    expression->truelist = labelLookahead();
                    expression->falselist = labelLookahead()+1;

                    emit(if_greater_op,ifJumpExp,$1,$3,getNextLabel(),yylineno);
                    jumpExp->setJumpLab(0);
                    emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);
                    $$ = expression;
                }
                | expr GREATER_EQUAL expr {
                    if($1->getType()==boolexpr_e){
                        patchlist($1->truelist,labelLookahead());
                        patchlist($1->falselist,labelLookahead()+2);
                        expr* expression = new expr(boolexpr_e);
                        expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                        expression->sym->setScopespace(getCurrentScopespace());
                        expression->sym->setOffset(0);
                        expression->setJumpLab(0);
                        expr* jumpExp = new expr(label_e);
                        jumpExp->setJumpLab(labelLookahead()+3);

                        emit(assign_op,NULL,expression,newexpr_constbool(1),getNextLabel(),yylineno);
                        emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);
                        emit(assign_op,NULL,expression,newexpr_constbool(0),getNextLabel(),yylineno);
                        $1=expression;
                    }
                    if($3->getType()==boolexpr_e){
                        patchlist($3->truelist,labelLookahead());
                        patchlist($3->falselist,labelLookahead()+2);
                        expr* expression = new expr(boolexpr_e);
                        expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                        expression->sym->setScopespace(getCurrentScopespace());
                        expression->sym->setOffset(0);
                        expression->setJumpLab(0);
                        expr* jumpExp = new expr(label_e);
                        jumpExp->setJumpLab(labelLookahead()+3);

                        emit(assign_op,NULL,expression,newexpr_constbool(1),getNextLabel(),yylineno);
                        emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);
                        emit(assign_op,NULL,expression,newexpr_constbool(0),getNextLabel(),yylineno);
                        $3=expression;
                    }
                    expr* expression=new expr(boolexpr_e);
                    expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                    expression->sym->setScopespace(getCurrentScopespace());
                    expression->sym->setOffset(0);
                    expr* jumpExp = new expr(label_e);
                    expr* ifJumpExp = new expr(label_e);
                    ifJumpExp->setJumpLab(0);
                    expression->truelist = labelLookahead();
                    expression->falselist = labelLookahead()+1;

                    emit(if_greatereq_op,ifJumpExp,$1,$3,getNextLabel(),yylineno);
                    jumpExp->setJumpLab(0);
                    emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);
                    $$ = expression;
                }
                | expr '<' expr {
                    if($1->getType()==boolexpr_e){
                        patchlist($1->truelist,labelLookahead());
                        patchlist($1->falselist,labelLookahead()+2);
                        expr* expression = new expr(boolexpr_e);
                        expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                        expression->sym->setScopespace(getCurrentScopespace());
                        expression->sym->setOffset(0);
                        expression->setJumpLab(0);
                        expr* jumpExp = new expr(label_e);
                        jumpExp->setJumpLab(labelLookahead()+3);

                        emit(assign_op,NULL,expression,newexpr_constbool(1),getNextLabel(),yylineno);
                        emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);
                        emit(assign_op,NULL,expression,newexpr_constbool(0),getNextLabel(),yylineno);
                        $1=expression;
                    }
                    if($3->getType()==boolexpr_e){
                        patchlist($3->truelist,labelLookahead());
                        patchlist($3->falselist,labelLookahead()+2);
                        expr* expression = new expr(boolexpr_e);
                        expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                        expression->sym->setScopespace(getCurrentScopespace());
                        expression->sym->setOffset(0);
                        expression->setJumpLab(0);
                        expr* jumpExp = new expr(label_e);
                        jumpExp->setJumpLab(labelLookahead()+3);

                        emit(assign_op,NULL,expression,newexpr_constbool(1),getNextLabel(),yylineno);
                        emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);
                        emit(assign_op,NULL,expression,newexpr_constbool(0),getNextLabel(),yylineno);
                        $3=expression;
                    }
                    expr* expression=new expr(boolexpr_e);
                    expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                    expression->sym->setScopespace(getCurrentScopespace());
                    expression->sym->setOffset(0);
                    expr* jumpExp = new expr(label_e);
                    expr* ifJumpExp = new expr(label_e);
                    ifJumpExp->setJumpLab(0);
                    expression->truelist = labelLookahead();
                    expression->falselist = labelLookahead()+1;

                    emit(if_less_op,ifJumpExp,$1,$3,getNextLabel(),yylineno);
                    jumpExp->setJumpLab(0);
                    emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);
                    $$ = expression;
                }
                | expr LESS_EQUAL expr {
                    if($1->getType()==boolexpr_e){
                        patchlist($1->truelist,labelLookahead());
                        patchlist($1->falselist,labelLookahead()+2);
                        expr* expression = new expr(boolexpr_e);
                        expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                        expression->sym->setScopespace(getCurrentScopespace());
                        expression->sym->setOffset(0);
                        expression->setJumpLab(0);
                        expr* jumpExp = new expr(label_e);
                        jumpExp->setJumpLab(labelLookahead()+3);

                        emit(assign_op,NULL,expression,newexpr_constbool(1),getNextLabel(),yylineno);
                        emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);
                        emit(assign_op,NULL,expression,newexpr_constbool(0),getNextLabel(),yylineno);
                        $1=expression;
                    }
                    if($3->getType()==boolexpr_e){
                        patchlist($3->truelist,labelLookahead());
                        patchlist($3->falselist,labelLookahead()+2);
                        expr* expression = new expr(boolexpr_e);
                        expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                        expression->sym->setScopespace(getCurrentScopespace());
                        expression->sym->setOffset(0);
                        expression->setJumpLab(0);
                        expr* jumpExp = new expr(label_e);
                        jumpExp->setJumpLab(labelLookahead()+3);

                        emit(assign_op,NULL,expression,newexpr_constbool(1),getNextLabel(),yylineno);
                        emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);
                        emit(assign_op,NULL,expression,newexpr_constbool(0),getNextLabel(),yylineno);
                        $3=expression;
                    }
                    expr* expression=new expr(boolexpr_e);
                    expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                    expression->sym->setScopespace(getCurrentScopespace());
                    expression->sym->setOffset(0);
                    expr* jumpExp = new expr(label_e);
                    expr* ifJumpExp = new expr(label_e);
                    ifJumpExp->setJumpLab(0);
                    expression->truelist = labelLookahead();
                    expression->falselist = labelLookahead()+1;

                    emit(if_lesseq_op,ifJumpExp,$1,$3,getNextLabel(),yylineno);
                    jumpExp->setJumpLab(0);
                    emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);
                    $$ = expression;
                }
                | expr EQUAL expr {
                    if($1->getType()==boolexpr_e){
                        patchlist($1->truelist,labelLookahead());
                        patchlist($1->falselist,labelLookahead()+2);
                        expr* expression = new expr(boolexpr_e);
                        expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                        expression->sym->setScopespace(getCurrentScopespace());
                        expression->sym->setOffset(0);
                        expression->setJumpLab(0);
                        expr* jumpExp = new expr(label_e);
                        jumpExp->setJumpLab(labelLookahead()+3);

                        emit(assign_op,NULL,expression,newexpr_constbool(1),getNextLabel(),yylineno);
                        emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);
                        emit(assign_op,NULL,expression,newexpr_constbool(0),getNextLabel(),yylineno);
                        $1=expression;
                    }
                    if($3->getType()==boolexpr_e){
                        patchlist($3->truelist,labelLookahead());
                        patchlist($3->falselist,labelLookahead()+2);
                        expr* expression = new expr(boolexpr_e);
                        expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                        expression->sym->setScopespace(getCurrentScopespace());
                        expression->sym->setOffset(0);
                        expression->setJumpLab(0);
                        expr* jumpExp = new expr(label_e);
                        jumpExp->setJumpLab(labelLookahead()+3);

                        emit(assign_op,NULL,expression,newexpr_constbool(1),getNextLabel(),yylineno);
                        emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);
                        emit(assign_op,NULL,expression,newexpr_constbool(0),getNextLabel(),yylineno);
                        $3=expression;
                    }
                    expr* expression=new expr(boolexpr_e);
                    expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                    expression->sym->setScopespace(getCurrentScopespace());
                    expression->sym->setOffset(0);
                    expr* jumpExp = new expr(label_e);
                    expr* ifJumpExp = new expr(label_e);
                    ifJumpExp->setJumpLab(0);
                    expression->truelist = labelLookahead();
                    expression->falselist = labelLookahead()+1;

                    emit(if_eq_op,ifJumpExp,$1,$3,getNextLabel(),yylineno);
                    jumpExp->setJumpLab(0);
                    emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);

                    $$ = expression;
                }
                | expr NOT_EQUAL expr {
                    if($1->getType()==boolexpr_e){
                        patchlist($1->truelist,labelLookahead());
                        patchlist($1->falselist,labelLookahead()+2);
                        expr* expression = new expr(boolexpr_e);
                        expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                        expression->sym->setScopespace(getCurrentScopespace());
                        expression->sym->setOffset(0);
                        expression->setJumpLab(0);
                        expr* jumpExp = new expr(label_e);
                        jumpExp->setJumpLab(labelLookahead()+3);

                        emit(assign_op,NULL,expression,newexpr_constbool(1),getNextLabel(),yylineno);
                        emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);
                        emit(assign_op,NULL,expression,newexpr_constbool(0),getNextLabel(),yylineno);
                        $1=expression;
                    }
                    if($3->getType()==boolexpr_e){
                        patchlist($3->truelist,labelLookahead());
                        patchlist($3->falselist,labelLookahead()+2);
                        expr* expression = new expr(boolexpr_e);
                        expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                        expression->sym->setScopespace(getCurrentScopespace());
                        expression->sym->setOffset(0);
                        expression->setJumpLab(0);
                        expr* jumpExp = new expr(label_e);
                        jumpExp->setJumpLab(labelLookahead()+3);

                        emit(assign_op,NULL,expression,newexpr_constbool(1),getNextLabel(),yylineno);
                        emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);
                        emit(assign_op,NULL,expression,newexpr_constbool(0),getNextLabel(),yylineno);
                        $3=expression;
                    }
                    expr* expression=new expr(boolexpr_e);
                    expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                    expression->sym->setScopespace(getCurrentScopespace());
                    expression->sym->setOffset(0);
                    expr* jumpExp = new expr(label_e);
                    expr* ifJumpExp = new expr(label_e);
                    ifJumpExp->setJumpLab(0);
                    expression->truelist = labelLookahead();
                    expression->falselist = labelLookahead()+1;

                    emit(if_noteq_op,ifJumpExp,$1,$3,getNextLabel(),yylineno);
                    jumpExp->setJumpLab(0);
                    emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);
                    expression->truelist=mergelist(expression->truelist,$1->truelist);
                    expression->truelist=mergelist(expression->truelist,$3->truelist);
                    expression->falselist=mergelist(expression->falselist,$1->falselist);
                    expression->falselist=mergelist(expression->falselist,$3->falselist);
                    $$ = expression;
                }
                | expr AND {
                                int exp1true=0,exp1false=0;
                                if($1->getType() != boolexpr_e){
                                exp1true = labelLookahead();
                                exp1false = labelLookahead()+1;
                                expr* ex1 = new expr(label_e);
                                ex1->setJumpLab(0);
                                cout<<"preorder "<<$1->getJumpLab()<<"\n";
                                expr* ifjump = new expr(label_e);
                                ifjump->setJumpLab(0);
                                emit(if_eq_op,ifjump,$1,newexpr_constbool(1),getNextLabel(),yylineno);//add to truelist
                                emit(jump_op,NULL,ex1,NULL,getNextLabel(),yylineno);//add to falselist

                                $1->truelist = mergelist($1->truelist,exp1true);
                                $1->falselist=mergelist($1->falselist,exp1false);
                                //$M = $M +2;
                            }
                    }M expr {
                    
                    int exp2true=0,exp2false=0;
                    
                    if($5->getType() != boolexpr_e){
                        exp2true = labelLookahead();
                        exp2false = labelLookahead()+1;
                        expr* ex2 = new expr(label_e);
                        ex2->setJumpLab(0);
                        expr* ifjump = new expr(label_e);
                        ifjump->setJumpLab(0);

                        emit(if_eq_op,ifjump,$5,newexpr_constbool(1),getNextLabel(),yylineno);//add to truelist
                        emit(jump_op,NULL,ex2,NULL,getNextLabel(),yylineno);//add to falselist

                        $5->truelist = mergelist($5->truelist,exp2true);
                        $5->falselist = mergelist($5->falselist,exp2false);
                    }


                    patchlist($1->truelist,$M);
                    expr* expression = new expr(boolexpr_e);
                    expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                    expression->truelist = $5->truelist;
                    cout<<"the falselists 1-4 "<<$1->falselist<<"-"<<$5->falselist<<"\n";
                    expression->falselist = mergelist($1->falselist,$5->falselist);
                    cout<<"after merge "<<expression->falselist<<"\n";

                    $$ = expression;
                    $$->setJumpLab(0);
                }
                | expr OR{
                            int exp1true=0,exp1false=0;
                            if($1->getType() != boolexpr_e){
                        exp1true = labelLookahead();
                        exp1false = labelLookahead()+1;
                        expr* ex1 = new expr(label_e);
                        ex1->setJumpLab(0);
                        expr* ifjump = new expr(label_e);
                        ifjump->setJumpLab(0);
                        emit(if_eq_op,ifjump,$1,newexpr_constbool(1),getNextLabel(),yylineno);//add to truelist
                        emit(jump_op,NULL,ex1,NULL,getNextLabel(),yylineno);//add to falselist
                        cout<<"orex1 list - case = "<<$1->truelist<<" - "<<exp1true<<"\n";

                        $1->truelist = mergelist($1->truelist,exp1true);
                        cout<<"ex1 after "<<$1->truelist<<"\n";
                        $1->falselist=mergelist($1->falselist,exp1false);
                        //$M = $M +2;
                    }
                } M expr {
                  
                    int exp2true=0,exp2false=0;
                    
                    if($5->getType() != boolexpr_e){
                        exp2true = labelLookahead();
                        exp2false = labelLookahead()+1;
                        expr* ex2 = new expr(label_e);
                        ex2->setJumpLab(0);
                        expr* ifjump = new expr(label_e);
                        ifjump->setJumpLab(0);

                        emit(if_eq_op,ifjump,$5,newexpr_constbool(1),getNextLabel(),yylineno);//add to truelist
                        emit(jump_op,NULL,ex2,NULL,getNextLabel(),yylineno);//add to falselist
                        cout<<"orex1 list - case = "<<$1->truelist<<" - "<<exp2true<<"\n";
                        $5->truelist = mergelist($5->truelist,exp2true);
                        cout<<"ex1 after "<<$5->truelist<<"\n";
                        $5->falselist = mergelist($5->falselist,exp2false);
                    }
                    
                    patchlist($1->falselist,$M);
                    expr* expression = new expr(boolexpr_e);
                    expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                    cout<<"true merges "<<$1->truelist<<" %^&* "<<$5->truelist<<"\n";
                    expression->truelist = mergelist($1->truelist,$5->truelist);
                    expression->falselist = $5->falselist;
                    $$ = expression;
                    $$->setJumpLab(0);
                }
                | term {
                    $$=$1;
                    if($1->getType()==0){
                        cout<"IN TERM RESET\n"; 
                        $$->truelist=0;
                        $$->falselist=0;
                        $$->setJumpLab(0);
                    }
                }
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
                        
                                cout<<"not in non boolean called\n";
                                expr* expression=new expr(boolexpr_e);
                                expression->sym = addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                                expression->sym->setScopespace(getCurrentScopespace());
                                expression->sym->setOffset(0);
                                expr* jumpExp = new expr(label_e);
                                expr* ifJumpExp = new expr(label_e);
                                ifJumpExp->setJumpLab(0);
                                expression->truelist = labelLookahead()+1;
                                expression->falselist = labelLookahead();

                                emit(if_eq_op,ifJumpExp,$2,newexpr_constbool(1),getNextLabel(),yylineno);
                                jumpExp->setJumpLab(0);
                                emit(jump_op,NULL,jumpExp,NULL,getNextLabel(),yylineno);                                
                               
                                cout<<"NOT LISTS t-f "<<expression->truelist<<"-"<<expression->falselist<<"\n";
                                $$ = expression;
                        if($expr->getType()==boolexpr_e){
                            cout<<"not in boolean called\n";
                            int holder = $2->truelist;
                            $2->truelist = $2->falselist;
                            $2->falselist = holder;
                            expression->truelist=(expression->truelist,$2->truelist);
                            expression->falselist=(expression->falselist,$2->falselist);

                        }   
                        $$=expression;     
                            }
                | PLUS_PLUS lvalue  {/*LookUpRvalue($2);*/
                                        if($2->getType() != tableitem_e){
                                            expr *arrExpr=new expr(constnumInt_e);
                                            arrExpr->setNumConst(1);
                                            emit(add_op, $2, $2, arrExpr, getNextLabel(), yylineno);
                                            expr* expression= new expr(arithexpr_e);
                                            expression->sym=addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                                            expression->sym->setScopespace(getCurrentScopespace());
                                            expression->sym->setOffset(0);
                                            emit(assign_op, expression, $2, NULL, getNextLabel(), yylineno);
                                            $$=expression;
                                        }
                                        else{
                                            $$=emit_if_table($2);
                                            emit(add_op, $$, $$, new expr(1), getNextLabel(), yylineno);
                                            emit(tablesetelem_op, $2,$2->getIndex(), $$,getNextLabel(), yylineno);
                                        }
                                    }
                | lvalue PLUS_PLUS {/*LookUpRvalue($1);*/
                                        if($1->getType() != tableitem_e){
                                            expr* expression= new expr(arithexpr_e);
                                            expression->sym=addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                                            expression->sym->setScopespace(getCurrentScopespace());
                                            expression->sym->setOffset(0);
                                            emit(assign_op, expression, $1, NULL, getNextLabel(), yylineno);
                                            expr *arrExpr=new expr(constnumInt_e);
                                            arrExpr->setNumConst(1);
                                            emit(add_op, $1, $1, arrExpr, getNextLabel(), yylineno);
                                            $$=expression; 
                                        }
                                        else{
                                            expr *temp=new expr(arithexpr_e);
                                            temp->sym=addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                                            $$=emit_if_table($1);
                                            emit(assign_op, temp, $$, NULL, getNextLabel(), yylineno);
                                            emit(add_op, $$, $$, new expr(1), getNextLabel(), yylineno);
                                            emit(tablesetelem_op, $1,$1->getIndex(), $$,getNextLabel(), yylineno);
                                            $$=temp;
                                        }
                                   }
                | MINUS_MINUS lvalue {/*LookUpRvalue($2);*/
                                        if($2->getType() != tableitem_e){
                                            expr *arrExpr=new expr(constnumInt_e);
                                            arrExpr->setNumConst(1);
                                            emit(sub_op, $2, $2, arrExpr, getNextLabel(), yylineno);
                                            expr* expression= new expr(arithexpr_e);
                                            expression->sym=addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                                            expression->sym->setScopespace(getCurrentScopespace());
                                            expression->sym->setOffset(0);
                                            emit(assign_op, expression, $2, NULL, getNextLabel(), yylineno);
                                            $$=expression;
                                        }
                                        else{
                                            $$=emit_if_table($2);
                                            emit(sub_op, $$, $$, new expr(1), getNextLabel(), yylineno);
                                            emit(tablesetelem_op, $2,$2->getIndex(), $$,getNextLabel(), yylineno);
                                        }
                                     }
                | lvalue MINUS_MINUS {/*LookUpRvalue($1);*/
                                        if($1->getType() != tableitem_e){
                                            expr* expression= new expr(arithexpr_e);
                                            expression->sym=addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                                            expression->sym->setScopespace(getCurrentScopespace());
                                            expression->sym->setOffset(0);
                                            emit(assign_op, expression, $1, NULL, getNextLabel(), yylineno);
                                            expr *arrExpr=new expr(constnumInt_e);
                                            arrExpr->setNumConst(1);
                                            emit(sub_op, $1, $1, arrExpr, getNextLabel(), yylineno);
                                            $$=expression; 
                                        }
                                        else{
                                            expr *temp=new expr(arithexpr_e);
                                            temp->sym=addToSymbolTable(nextVariableName(),currentScope,yylineno,getGlobLocl(),var_s);
                                            $$=emit_if_table($1);
                                            emit(assign_op, temp, $$, NULL, getNextLabel(), yylineno);
                                            emit(sub_op, $$, $$, new expr(1), getNextLabel(), yylineno);
                                            emit(tablesetelem_op, $1,$1->getIndex(), $$,getNextLabel(), yylineno);
                                            $$=temp;
                                        }
                                     }
                | primary {$$=$1;}
                ;

assignexpr:       lvalue '=' expr {
                                    if($1->getType()==tableitem_e){
                                            emit(tablesetelem_op, $1,$1->getIndex(), $3, getNextLabel(), yylineno);
                                            expr* expression=emit_if_table($1);
                                            expression->setType(assignexpr_e);
                                            $$=expression;
                                        }
                                    else if($3->getType()==boolexpr_e){
                                        cout<<" in asexpr as exp\n";
                                        patchlist($3->truelist,labelLookahead());
                                        patchlist($3->falselist,labelLookahead()+2);

                                        expr* exr = new expr(assignexpr_e);
                                        exr->sym = addToSymbolTable(nextVariableName(), currentScope, yylineno,getGlobLocl(),var_s);
                                        exr->sym->setScopespace(getCurrentScopespace());
                                        exr->sym->setOffset(0);

                                        emit(assign_op,exr,newexpr_constbool(1),NULL,getNextLabel(),yylineno);

                                        expr* jumpEx = new expr(label_e);
                                        jumpEx->setJumpLab(labelLookahead()+2);
                                        emit(jump_op,NULL,jumpEx,NULL,getNextLabel(),yylineno);

                                        emit(assign_op,exr,newexpr_constbool(0),NULL,getNextLabel(),yylineno);

                                        emit(assign_op,$1,exr,NULL,getNextLabel(),yylineno);

                                        expr* expression=new expr(assignexpr_e);
                                        expression->sym = addToSymbolTable(nextVariableName(), currentScope, yylineno,getGlobLocl(),var_s);
                                        expression->sym->setScopespace(getCurrentScopespace());
                                        expression->sym->setOffset(0);
                                        emit(assign_op, expression,$1, NULL, getNextLabel(), yylineno);
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
                            expression->truelist = 0;
                            expression->falselist = 0;
                            expression->setJumpLab(0);
                            $$=expression;
                         }
                | call {}
                | objectdef {$$=$1;}
                | '(' funcdef ')' {$$=$2;}
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
                | LOCAL IDENT {   
                            expr *expression=new expr(var_e);
                            expression->sym=LookUpVariable($2,0);
                            if(expression->sym==NULL){
                                    expression->sym=addToSymbolTable($2, currentScope, yylineno,LOCL,var_s);
                                    expression->sym->setOffset(currentOffset());
                                    expression->sym->setScopespace(getCurrentScopespace());
                                    incCurScopeOffset();
                            }
                            $$=expression;
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

call:             call '(' elist ')' {$$=make_call($1, $3);}
                | lvalue callsuffix {
                                        /*if(callFlag==1){callFlag=0;}else {if(!returnState) callFunction($1);} */
                                        $1=emit_if_table($1);
                                        if($2->getMethod()){
                                            expr* t=$1;
                                            $1=emit_if_table(member_item(t, strdup($2->getName().c_str())));
                                            t->setNext($2->getEList());
                                            $2->setEList(t);
                                        }    
                                        $$=make_call($1, $2->getEList());
                                    }
                | '(' funcdef ')' '(' elist ')' {
                                                    expr* expression=new expr(programfunc_e);
                                                    expression->sym=$2->sym;
                                                    $$=make_call(expression, $5);
                                                    $$->setJumpLab(0);
                                                }
                ;

callsuffix:       normcall {$$=$1;}
                | methodcall {$$=$1;}
                ;

normcall:         '(' elist ')' {
                                    call *newcall=new call($2, "", 0);
                                    $$=newcall;
                                }
                ;

methodcall:       DOT_DOT IDENT '(' elist ')'   {
                                                    call *newCall=new call($4, $2, true);
                                                    $$=newCall;
                                                }
                ;

elist:            expr {$$=$1; $$->setNext(NULL);}
                | expr ',' elist {$1->setNext($3); $$=$1;}
                |{$$=NULL;}
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
                                    $$=expression;

                                }
                | '[' indexed ']' {
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

indexedelem:      '{' expr ':' expr '}' {$4->setIndex($2); $$=$4;
                                            if(($2->getType()==boolexpr_e) &&($4->getType()==boolexpr_e)){
                                                                patchlist($2->truelist,labelLookahead());
                                                                patchlist($2->falselist,labelLookahead()+2);
                                                                emit(assign_op,NULL,$2,newexpr_constbool(1),getNextLabel(),yylineno);
                                                                expr* lab = new expr(label_e);
                                                                lab->setJumpLab(labelLookahead()+2);
                                                                emit(jump_op,NULL,lab,NULL,getNextLabel(),yylineno);
                                                                emit(assign_op,NULL,$2,newexpr_constbool(0),getNextLabel(),yylineno);
                                                                
                                                                patchlist($4->truelist,labelLookahead());
                                                                patchlist($4->falselist,labelLookahead()+2);
                                                                emit(assign_op,NULL,$4,newexpr_constbool(1),getNextLabel(),yylineno);
                                                                expr* lab2 = new expr(label_e);
                                                                lab2->setJumpLab(labelLookahead()+2);
                                                                emit(jump_op,NULL,lab2,NULL,getNextLabel(),yylineno);
                                                                emit(assign_op,NULL,$4,newexpr_constbool(0),getNextLabel(),yylineno);
                                                            }else if($2->getType()==boolexpr_e){
                                                                patchlist($2->truelist,labelLookahead());
                                                                patchlist($2->falselist,labelLookahead()+2);
                                                                emit(assign_op,NULL,$2,newexpr_constbool(1),getNextLabel(),yylineno);
                                                                expr* lab = new expr(label_e);
                                                                lab->setJumpLab(labelLookahead()+2);
                                                                emit(jump_op,NULL,lab,NULL,getNextLabel(),yylineno);
                                                                emit(assign_op,NULL,$2,newexpr_constbool(0),getNextLabel(),yylineno);
                                                            }else if($4->getType()==boolexpr_e){
                                                                patchlist($4->truelist,labelLookahead());
                                                                patchlist($4->falselist,labelLookahead()+2);
                                                                emit(assign_op,NULL,$4,newexpr_constbool(1),getNextLabel(),yylineno);
                                                                expr* lab = new expr(label_e);
                                                                lab->setJumpLab(labelLookahead()+2);
                                                                emit(jump_op,NULL,lab,NULL,getNextLabel(),yylineno);
                                                                emit(assign_op,NULL,$4,newexpr_constbool(0),getNextLabel(),yylineno);
                                                            }
                                        }
                ;

block:            '{' {;currentScope++;} loopstmt {decreaseScope();} '}' {cout<<"block in\n";$$ = $loopstmt;cout<<"block out\n";}
                ;

funcdef:          FUNCTION N {
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
                ')' block  {
                                nestedFunctionCounter--;
                                exitScopespace();exitScopespace();
                                getPrevFunctionOffset();
                                emit(funcend_op,funcExprStack.top(),NULL,NULL,getNextLabel(),yylineno);
                                expr *temp1= new expr(label_e);
                                temp1->setJumpLab(labelLookahead());
                                backpatchResult($N, temp1);
                                expr* lab = new expr(label_e);
                                lab->setJumpLab(labelLookahead());
                                $$=funcExprStack.top();
                                $$->truelist=0;
                                $$->falselist=0;
                                $$->setJumpLab(0);
                                funcExprStack.pop();
                            }
                | FUNCTION IDENT N{
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
                                }
                        block   {
                                    nestedFunctionCounter--;
                                    exitScopespace();exitScopespace();
                                    getPrevFunctionOffset();
                                    emit(funcend_op,funcExprStack.top(),NULL,NULL,getNextLabel(),yylineno);
                                    expr *temp1= new expr(label_e);
                                    temp1->setJumpLab(labelLookahead());
                                    backpatchResult($N, temp1);
                                    $$=funcExprStack.top();
                                    $$->truelist=0;
                                    $$->falselist=0;
                                    $$->setJumpLab(0);
                                    funcExprStack.pop();
                                }
                ;

const:            INTCONST {expr *expression=new expr(constnumInt_e); expression->setNumConst($1);$$=expression;}
                | DOUBLECONST {expr *expression=new expr(constnumDouble_e); expression->setNumConst($1);$$=expression;}
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


ifprefix:       IF '(' expr ')' {
                                    patchlist($expr->truelist,labelLookahead());
                                    patchlist($expr->falselist,labelLookahead()+2);
                                    cout<<"if type "<<$expr->getType()<<"\n";
                                    if(($expr->getType()==boolexpr_e)){
                                        cout<<"in IF IF\n";
                                        emit(assign_op,NULL,$expr,newexpr_constbool(1),getNextLabel(),yylineno);
                                        expr* lab = new expr(label_e);
                                        lab->setJumpLab(labelLookahead()+2);
                                        emit(jump_op,NULL,lab,NULL,getNextLabel(),yylineno);
                                        emit(assign_op,NULL,$expr,newexpr_constbool(0),getNextLabel(),yylineno);
                                    }    

                                    expr* expression = new expr(label_e);
                                    expression->setJumpLab(labelLookahead()+2);
                                    emit(if_eq_op,expression,$expr,newexpr_constbool(1),getNextLabel(),yylineno);
                                    ifQuadStack.push(labelLookahead());
                                    cout<<"pushed "<<labelLookahead()<<"\n";
                                    emit(jump_op,NULL,NULL,NULL,getNextLabel(),yylineno);
                                 }
                ;
stmt1:          stmt {
                        expr* expression = new expr(label_e);
                        expression->setJumpLab(labelLookahead()+1);
                        backpatchArg1(ifQuadStack.top(),expression);
                        ifQuadStack.pop();
                        ifQuadStack.push(labelLookahead());
                        emit(jump_op,NULL,NULL,NULL,getNextLabel(),yylineno);
                        $$=$1;
                    }
                ;

ifstmt:         ifprefix stmt {
                                expr* expression = new expr(label_e);
                                expression->setJumpLab(labelLookahead());
                                backpatchArg1(ifQuadStack.top(),expression);
                                ifQuadStack.pop();
                                $$=$stmt;
                            }
                | ifprefix stmt1 ELSE stmt   {
                                expr* expression = new expr(label_e);
                                expression->setJumpLab(labelLookahead());
                                backpatchArg1(ifQuadStack.top(),expression);
                                //emit(jump_op,NULL,expression,NULL,getNextLabel(),yylineno);
                                ifQuadStack.pop();
                                $stmt->breaklist = mergelist($stmt->breaklist,$stmt1->breaklist);
                                $stmt->continuelist = mergelist($stmt->continuelist,$stmt1->continuelist);
                                $$=$stmt;
                           }
                ;

whilestmt:        WHILE {nestedLoopCounter++;
                            whileStartStack.push(labelLookahead());
                        } 
            '(' expr ')'{
                            patchlist($expr->truelist,labelLookahead());
                            patchlist($expr->falselist,labelLookahead()+2);
                            if(($expr->getType()==boolexpr_e)){
                                cout<<"OOOOOO\n";
                                emit(assign_op,NULL,$expr,newexpr_constbool(1),getNextLabel(),yylineno);
                                expr* lab = new expr(label_e);
                                lab->setJumpLab(labelLookahead()+2);
                                emit(jump_op,NULL,lab,NULL,getNextLabel(),yylineno);
                                emit(assign_op,NULL,$expr,newexpr_constbool(0),getNextLabel(),yylineno);
                            }
                            expr* expression = new expr(label_e);
                            expression->setJumpLab(labelLookahead()+2);
                            cout<<"while jump created to "<<expression->getJumpLab()<<"\n";
                            emit(if_eq_op,expression,$expr,newexpr_constbool(1),getNextLabel(),yylineno);

                            whileSecondStack.push(labelLookahead());
                            emit(jump_op,NULL,NULL,NULL,getNextLabel(),yylineno);
                        } 
                   stmt {
                            cout<<"up\n";
                            nestedLoopCounter--;

                            expr* expression = new expr(label_e);
                            expression->setJumpLab(whileStartStack.top());
                            
                            cout<<"first jump set on "<<expression->getJumpLab()<<"\n";
                            emit(jump_op,NULL,expression,NULL,getNextLabel(),yylineno);

                            expr* expression2 = new expr(label_e);
                            expression2->setJumpLab(labelLookahead());
                            cout<<"backpatching on "<<whileSecondStack.top()<<" -> "<<expression2->getJumpLab()<<"\n";
                            backpatchArg1(whileSecondStack.top(),expression2);
                            whileSecondStack.pop();
                            cout<<"breaklist candidate "<<$stmt->breaklist<<" and lookahead "<<labelLookahead()<<"\n";
                            patchlist($stmt->breaklist,labelLookahead());
                            patchlist($stmt->continuelist,whileStartStack.top());
                            whileStartStack.pop();
                            $$ = $stmt;
                            cout<<"down\n";
                        }
                ;

M:{$$ = labelLookahead();};
N:{$$=labelLookahead();emit(jump_op, NULL, NULL, NULL, getNextLabel(), yylineno);};

forprefix:              FOR '(' elist ';' M expr ';' {
                                                        forprefix *forprx=new forprefix();
                                                        forprx->setTest($M);
                                                        
                                                        if($expr->getType()==boolexpr_e){
                                                            patchlist($expr->truelist,labelLookahead());
                                                            patchlist($expr->falselist,labelLookahead()+2);
                                                            emit(assign_op,NULL,$expr,newexpr_constbool(1),getNextLabel(),yylineno);
                                                            expr* lab = new expr(label_e);
                                                            lab->setJumpLab(labelLookahead()+2);
                                                            emit(jump_op,NULL,lab,NULL,getNextLabel(),yylineno);
                                                            emit(assign_op,NULL,$expr,newexpr_constbool(0),getNextLabel(),yylineno);
                                                        }

                                                        forprx->setEnter(labelLookahead());
                                                        emit(if_eq_op,NULL, $expr, newexpr_constbool(1), getNextLabel(),yylineno);
                                                        $$=forprx;
                                                        nestedLoopCounter++;
                                                    }
                        ;
forstmt:          forprefix N elist ')' N stmt N{
                                                    
                                                    expr *temp1= new expr(label_e);
                                                    temp1->setJumpLab($5 + 1);
                                                    backpatchResult($1->getEnter(), temp1);
                                                    expr *temp2= new expr(label_e);
                                                    temp2->setJumpLab(labelLookahead());
                                                    backpatchResult($2, temp2);
                                                    
                                                    expr *temp3= new expr(label_e);
                                                    temp3->setJumpLab($1->getTest());
                                                    backpatchArg1($5, temp3);
                                                    
                                                    expr *temp4= new expr(label_e);
                                                    temp4->setJumpLab($2 + 1);
                                                    backpatchArg1($7, temp4);
                                                    nestedLoopCounter--;
                                                    
                                                    patchlist($stmt->breaklist,labelLookahead());
                                                    cout<<"continue list is at "<<$stmt->continuelist<<"\n";    
                                                    patchlist($stmt->continuelist,$2+1);
                                                    $$ = $stmt;
                                                    cout<<"for break "<<$$->breaklist<<"\n";
                                                }
                ;

returnstmt:       RETURN ';' {
                                emit(ret_op,NULL,NULL,NULL,getNextLabel(),yylineno);
                             }
                | RETURN expr ';' {
                                    if($expr->getType()==boolexpr_e){
                                        patchlist($expr->truelist,labelLookahead());
                                        patchlist($expr->falselist,labelLookahead()+2);
                                        emit(assign_op,NULL,$expr,newexpr_constbool(1),getNextLabel(),yylineno);
                                        expr* lab = new expr(label_e);
                                        lab->setJumpLab(labelLookahead()+2);
                                        emit(jump_op,NULL,lab,NULL,getNextLabel(),yylineno);
                                        emit(assign_op,NULL,$expr,newexpr_constbool(0),getNextLabel(),yylineno);
                                    }
                                    emit(ret_op,NULL,$expr,NULL,getNextLabel(),yylineno);
                                  }
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
    emit(nop,NULL,NULL,NULL,getNextLabel(),0);
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
    string RetVal = "^"+numberInString;
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
    for(int i=1; i<quads.size(); i++){
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

expr* make_call(expr* lv, expr* reversed_elist){

    expr* func=emit_if_table(lv);
    vector<expr*> reverseVector;
    while(reversed_elist){
        reverseVector.push_back(reversed_elist);
        reversed_elist=reversed_elist->getNext();
    }
    for(int i=reverseVector.size()-1; i>=0; i--){
        emit(param_op, reverseVector[i], NULL, NULL, getNextLabel(),yylineno);
    }
    emit(call_op, func, NULL, NULL, getNextLabel(), yylineno);
    expr* result=new expr(var_e);
    result->sym=addToSymbolTable(nextVariableName(), currentScope, yylineno,getGlobLocl(),var_s);
    emit(getretval_op, NULL, NULL, result, getNextLabel(), yylineno);
    return result;
}