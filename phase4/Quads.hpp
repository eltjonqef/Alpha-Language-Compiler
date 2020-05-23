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
    jump_op,
    nop
};
bool reverseResultPrintOrder(iopcode opcd);
enum expr_t{
    var_e,
    tableitem_e,

    programfunc_e,
    libraryfunc_e,

    arithexpr_e,
    boolexpr_e,
    assignexpr_e,
    newtable_e,

    constnumInt_e,
    constnumDouble_e,
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
        case if_greatereq_op:return "if_greatereq";
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
        case nop:return "";
        /*maybe throw error here uwu*/
    }
}

class expr{
    private:
        expr_t type;
        expr* index;
        double numConstDouble;
        int numConstInt;
        std::string strConst;
        unsigned char boolConst;
        unsigned JumpLabel;
        expr* next;
    public:
        int truelist=0;
        int falselist=0;
        SymbolTableEntry* sym;
        expr(expr_t _type){
            type=_type;
        }
        expr(char* s){
            type=conststring_e;
            strConst=strdup(s);
        }
        expr(int _numConst){
            type=constnumInt_e;
            numConstInt=_numConst;
        }
        expr(double _numConst){
            type=constnumDouble_e;
            numConstDouble=_numConst;
        }
        expr_t getType(){
            return type;
        }
        void setType(expr_t _type){
            type=_type;
        }
        void setNumConst(double _numConst){
            numConstDouble=_numConst;
        }
        int getIntConst(){
            return numConstInt;
        }
        double getDoubleConst(){
            return numConstDouble;
        }
        void setNumConst(int _numConst){
            numConstInt=_numConst;
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
        void setIndex(expr* _index){
            index=_index;
        }
        void setJumpLab(unsigned _label){
            JumpLabel = _label;
        }
        unsigned getJumpLab(){
            return JumpLabel;
        }
        void setNext(expr* _next){
            next=_next;
        }
        expr* getNext(){
            return next;
        }
        std::string to_String(){
            if(type == var_e)return sym->getName();
            if(type == tableitem_e)return sym->getName();
            if(type == programfunc_e)return sym->getName();
            if(type == libraryfunc_e)return sym->getName();
            if(type == arithexpr_e)return sym->getName();
            if(type == boolexpr_e)return sym->getName();
            if(type == assignexpr_e)return sym->getName();
            if(type == newtable_e)return sym->getName();
            if(type == constnumInt_e)return std::to_string(numConstInt);
            if(type == constnumDouble_e)return std::to_string(numConstDouble);
            if(type == constbool_e){if(boolConst == 1)return "'true'";return "'false'";}
            if(type == conststring_e)return "\""+getStringConst()+"\"";
            if(type == nil_e)return "nil";
            if(type == label_e)return std::to_string(JumpLabel);
            return "err";
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
        void setArg1(expr* _arg1){
            arg1 = _arg1;
        }
        void setResult(expr* _result){
            result = _result;
        }
        std::string toString(){
            std::string retval = "label: "+to_string(label)+" "+opcodeToString(op);
            if((result != NULL)&&(!reverseResultPrintOrder(op))){retval = retval +" "+ result->to_String();}
            if(arg1 != NULL){retval = retval +" "+arg1->to_String();}
            if(arg2 != NULL){retval = retval +" "+arg2->to_String();}
            if((result != NULL)&&(reverseResultPrintOrder(op))){retval = retval +" "+ result->to_String();}
            return retval;
        }
        
};   
std::vector<expr*>tableEntries;
std::vector<quad> quads;
unsigned int labelCounter = 0;
std::stack<expr*> funcExprStack;
std::stack<unsigned int> ifQuadStack;
std::stack<unsigned int> whileStartStack;
std::stack<unsigned int> whileSecondStack;
std::stack<int> returnStack;

class stmtLists{
    public:
    int breaklist,continuelist;
    stmtLists(){
        breaklist = 0;
        continuelist = 0;
    }
};

int newList(int i){
        quads[i].getArg1()->setJumpLab(0);
        return i;
}

int mergelist(int l1,int l2){
    if(!l1){
        return l2;
    }else if(!l2){
        return l1;
    }else{
        int i=l1;
        
        while(quads[i].getArg1()->getJumpLab()){
            i = quads[i].getArg1()->getJumpLab();
        }
        quads[i].getArg1()->setJumpLab(l2);
        return l1;
    }
}  

void patchlist(int list,int label){
    while(list){
        if(quads[list].getResult() == NULL){
            int next;
            if(quads.size()<list){
                 next=0;
            }else{
             next = quads[list].getArg1()->getJumpLab();
            }
            quads[list].getArg1()->setJumpLab(label);
            list = next;
        }else{
            int next = quads[list].getArg1()->getJumpLab();
            quads[list].getResult()->setJumpLab(label);
            list = next;
        }
    }
}

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

unsigned int getNextLabel(){
    unsigned retval = labelCounter;
    labelCounter++;
    return retval;
}

unsigned int labelLookahead(){
    return labelCounter;
}

void
emit(iopcode op, expr* result, expr* arg1, expr* arg2, unsigned label, unsigned line){   
    
    quad newQuad(op,result, arg1, arg2, label, line);
    quads.push_back(newQuad);
}


bool reverseResultPrintOrder(iopcode opcd){
    if((opcd == if_greatereq_op)||(opcd == if_greater_op)||(opcd == if_eq_op)||(opcd == if_less_op)||(opcd == if_lesseq_op)||(opcd == if_noteq_op)){
        return true;
    }
    return false;
}

void backpatchArg1(int index,expr* _arg){
     quads[index].setArg1(_arg);
     /*
     *quad _quads = quads[index];
     * _quads.setArg1(_arg);
     * DOES NOT WORK, arg1 remains null after
     * 
     */
}     

void backpatchResult(int index,expr* _res){
    quads[index].setResult(_res);
}

quad getQuadFromLabel(unsigned int lbl){
    assert(lbl>1);
    return quads[lbl];
}

class forprefix{

    private:
        unsigned int test;
        unsigned int enter;
    public:
        forprefix(){}
        void setTest(unsigned int _test){
            test=_test;
        }
        unsigned int getTest(){
            return test;
        }
        void setEnter(unsigned int _enter){
            enter=_enter;
        }
        unsigned int getEnter(){
            return enter;
        }
};

class call{

    private:
        expr* elist;
        std::string name;
        bool method;
    public:
        call(expr* _elist, std::string _name, bool _method){
            elist=_elist;
            name=_name;
            method=_method;
        }
        expr* getEList(){
            return elist;
        }
        std::string getName(){
            return name;
        }
        bool getMethod(){
            return method;
        }
        void setEList(expr* _elist){
            elist=_elist;
        }
};