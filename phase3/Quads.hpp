#include "SymbolTable.hpp"
#include <string>
#include <assert.h>
#include <stdlib.h>
#include <vector>
#include <stack>

enum iopcode{ 
    assign_op,
    add_op,
    sub_op,
    mul_op,
    div_op,
    mod_op,
    uminus_op,
    and_op,
    or_op,
    not_op,
    if_eq_op,
    if_noteq_op,
    if_lesseq_op,
    if_greatereq_op,
    if_less_op,
    if_greater_op,
    call_op,
    param_op,
    ret_op,
    getretval_op,
    funcstart_op,
    funcend_op,
    tablecreate_op,
    tablegetelem_op,
    tablesetelem_op,
    jump_op
};

enum expr_t{
    var_e,
    tableitem_e,

    programfunc_e,
    libraryfunc_e,

    arithexpr_e,
    boolexpr_e,
    assignexpr_e,
    newtable_e,

    constnum_e,
    constbool_e,
    conststring_e,

    nil_e,

    label_e
};

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
        case jump_op:return "jump";
        /*maybe throw error here uwu*/
    }
}

class expr{
    private:
        expr_t type;
        expr* index;
        double numConst;
        std::string strConst;
        unsigned char boolConst;
        unsigned JumpLabel;
        expr* next;
    public:
        SymbolTableEntry* sym;
        expr(expr_t _type){
            type=_type;
        }
        expr(char* s){
            type=conststring_e;
            strConst=strdup(s);
        }
        expr(double _numConst){
            type=constnum_e;
            numConst=_numConst;
        }
        expr_t getType(){
            return type;
        }
        double getNumConst(){
            return numConst;
        }
        void setNumConst(double _numConst){
            numConst=_numConst;
        }
        void setStringConst(std::string _strConst){
            strConst=_strConst;
        }
        std::string getStringConst(){
            return strConst;
        }
        void setBoolConst(bool _boolConst){
            boolConst=_boolConst;
        }
        bool getBoolConst(){
            return boolConst;
        }
        expr* getIndex(){
            return index;
        }

        void setJumpLab(unsigned _label){
            JumpLabel = _label;
        }
        unsigned getJumpLab(){
            return JumpLabel;
        }
        std::string to_String(){
            if(type == var_e)return sym->getName();
            if(type == tableitem_e)return "tableitem not handles yet";
            if(type == programfunc_e)return sym->getName();
            if(type == libraryfunc_e)"libraryfunc not handled yet";
            if(type == arithexpr_e)return sym->getName();
            if(type == boolexpr_e)return sym->getName();
            if(type == assignexpr_e)return sym->getName();
            if(type == newtable_e)return"newtable not handled yet";
            if(type == constnum_e)return std::to_string(numConst);
            if(type == constbool_e) return"constbool not handled yet";
            if(type == conststring_e)return"constring not handled yet";
            if(type == nil_e)return "nil";
            if(type == label_e)return std::to_string(JumpLabel);
            return "fuck";
        }
};

class quad{
    private:
        iopcode op;
        expr* result = NULL;
        expr* arg1 = NULL;
        expr* arg2 = NULL;
        unsigned label;
        unsigned line;
    public:
        quad(iopcode _op,expr* _result,expr* _arg1, expr* _arg2, unsigned _label, unsigned _line){
            op = _op;
            result = _result;
            arg1=_arg1;
            arg2=_arg2;
            label=_label;
            line=_line;
        }
        iopcode getOP(){
            return op;
        }
        expr* getResult(){
            return result;
        }
        expr* getArg1(){
            return arg1;
        }
        expr* getArg2(){
            return arg2;
        }
        unsigned getLabel(){
            return label;
        }
        unsigned getLine(){
            return line;
        }
        std::string toString(){
            std::string retval = "label: "+to_string(label)+opcodeToString(op);
            if(result != NULL){retval = retval +" "+ result->to_String();}
            if(arg1 != NULL){retval = retval +" "+arg1->to_String();}
            if(arg2 != NULL){retval = retval +" "+arg2->to_String();}
            return retval;
        }
        
};
std::vector<expr*>tableEntries;
std::vector<quad> quads;
unsigned labelCounter = 1;
std::stack<expr*> funcExprStack;

/*
#define EXPAND_SIZE 1024
#define CURR_SIZE   (total*sizeof(quad))
#define NEW_SIZE    (EXPAND_SIZE*sizeof(quad)+CURR_SIZE )
*/


/* MIAS KAI XRHSIMOPOIOUME CPP DEN XREIAZETAI I EXPAND
void
expand(){
    assert(total==currQuad);
    quad* p=(quad*) malloc(NEW_SIZE);
    if(quads){
        memcpy(p,quads, CURR_SIZE);
        free(quads);
    }
    quads = p;
    total += EXPAND_SIZE;
}*/

unsigned getNextLabel(){
    unsigned retval = labelCounter;
    labelCounter++;
    return retval;
}

unsigned labelLookahead(){
    return labelCounter;
}

void
emit(iopcode op, expr* result, expr* arg1, expr* arg2, unsigned label, unsigned line){   
    
    quad newQuad(op,result, arg1, arg2, label, line);
    quads.push_back(newQuad);
}



