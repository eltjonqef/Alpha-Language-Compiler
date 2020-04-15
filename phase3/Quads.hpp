#include "SymbolTable.hpp"
#include <string>
#include <assert.h>
#include <stdlib.h>
#include <vector>
using namespace std;

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
    tablesetelem_op
};

enum expr_t{
    var_e,
    tableitem_e,

    programfunc_e,
    libraryfunc_e,

    airthexpr_e,
    boolexpr_e,
    assignexpr_e,
    newtable_e,

    constnum_e,
    constbool_e,
    conststring_e,

    nil_e
};

class expr{
    private:
        expr_t type;
        SymbolTableEntry* sym;
        expr* index;
        double numConst;
        string strConst;
        unsigned char boolConst;
        expr* next;
    
};

class quad{
    public:
        iopcode op;
        expr* result;
        expr* arg1;
        expr* arg2;
        unsigned label;
        unsigned line;
    
    quad(iopcode _op,expr* _result, expr* _arg1, expr* _arg2, unsigned _label, unsigned _line){
        op = _op;
        result=_result;
        arg1=_arg1;
        arg2=_arg2;
        label=_label;
        line=_line;
    }
};

vector<quad> quads;
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

void
emit(iopcode op, expr* result, expr* arg1, expr* arg2, unsigned label, unsigned line){   
    
    quad newQuad(op,result, arg1, arg2, label, line);
    quads.push_back(newQuad);
}


unsigned programVarOffsetCounter = 0;
unsigned functionLocalOffsetCounter = 0;
unsigned formalArgOffsetCounter = 0;
int scopeSpaceCounter = 0;

enum scopespace_t{
    programvar,functionlocal,formalarg
}

enum symbol_t {var_s,programfunc_s,libraryfunc_s};

struct symbol {
    symbol_t type;
    string name;
    scopespace_t space;
    unsigned offset;
    unsigned scope;
    unsigned line;
}

scopespace_t getCurrentScopespace(void) {
    if(scopeSpaceCounter == 1){
        return programvar;
    }else if(scopaSpaceCounter % 2 == 0){
        return formalarg;
    }else{
        return functionlocal;
    }
}

unsinged currentOf