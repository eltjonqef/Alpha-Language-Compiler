#include <iostream>
#include "avm.hpp"
#include "SymbolTable.hpp"
using namespace std;
void loadLibFuncs();

int main(){
    instruction *t=new instruction();
    t->setOpCode(nop_vm);
    instructionVector.push_back(t);
    readFile();
    loadLibFuncs();
    ax=new avm_memcell();
    bx=new avm_memcell();
    cx=new avm_memcell();
    while(!executionFinished)
        execute_cycle();
    return 0;
}

void execute_assign(instruction *t){

    avm_memcell *lv=avm_translate_operand(t->getResult(), NULL);

    avm_memcell *rv=avm_translate_operand(t->getArg1(), ax);
    //mia poutsoassert exei edw
    assert(rv);
    avm_assign(lv, rv);
}
void execute_add(instruction *t){}
void execute_sub(instruction *t){}
void execute_mul(instruction *t){}
void execute_div(instruction *t){}
void execute_mod(instruction *t){}
void execute_ifeq(instruction *t){}
void execute_ifnoteq(instruction *t){}
void execute_iflesseq(instruction *t){}
void execute_ifgreatereq(instruction *t){}
void execute_ifless(instruction *t){}
void execute_ifgreater(instruction *t){}
void execute_call(instruction *t){}
void execute_param(instruction *t){}
void execute_ret(instruction *t){}
void execute_getretval(instruction *t){}
void execute_funcenter(instruction *t){}
void execute_funcexit(instruction *t){}
void execute_tableCreate(instruction *t){}
void execute_tableGet(instruction *t){}
void execute_tableSet(instruction *t){}
void execute_jump(instruction *t){}
void execute_nop(instruction *t){}

void avm_assign(avm_memcell *lv, avm_memcell *rv){

    if(lv==rv)
        return;
    if(lv->type==table_m && rv->type==table_m && lv->d.tableVal==rv->d.tableVal)
        return;
    if(lv->type==undef_m)
        cout<<"ASSIGNING FROM UNDEF CONTENT"<<endl; //TO THELEI ME WARNIGN SUNARTISI
    
    //avm_memcellclear(lv);  NOT IMPLEMENTED YET

    memcpy(lv, rv, sizeof(avm_memcell));
    /*if(lv->type==string_m)
        lv->d.strVal=string(rv->d.strVal);
    else if(lv->type==table_m)
        cout<<"NOT IMPLEMENTED YET\n"; //avm_tableIncrefCounter(lv->d.tableVal);*/

}

void execute_cycle(){

    if(executionFinished) return;
    else if(pc==AVM_ENDING_PC){
        executionFinished=true;
    }
    else{
        assert(pc<AVM_ENDING_PC);
        instruction *t=instructionVector[pc];
        unsigned oldPc=pc;
        (*executionFunctions[t->getOP()])(t);
        if(pc==oldPc)
            ++pc;
    }
}

void loadLibFuncs(){
    libFuncVector.push_back("print");
    libFuncVector.push_back("input");
    libFuncVector.push_back("objectmemberkeys");
    libFuncVector.push_back("objecttotalmembers");
    libFuncVector.push_back("objectcopy");
    libFuncVector.push_back("totalarguments");
    libFuncVector.push_back("argument");
    libFuncVector.push_back("typeof");
    libFuncVector.push_back("sqrt");
    libFuncVector.push_back("cos");
    libFuncVector.push_back("sin");
}


avm_memcell* avm_translate_operand(vmarg* arg,avm_memcell* reg){
    switch(arg->getType()){
        case global_a: return &STACK[AVM_STACKSIZE-1-arg->getVal()];
        case local_a: return &STACK[topsp-arg->getVal()];
        case formal_a: return &STACK[topsp+AVM_STACKENV_SIZE+1+arg->getVal()];
        case retval_a: return retval;
        case int_a:{
            reg->type = number_m;
            reg->d.numVal = intVector[arg->getVal()-1];
            return reg;
        }
        case double_a:{
            reg->type = number_m;
            reg->d.numVal = doubleVector[arg->getVal()-1];
            return reg;
        }
        case string_a:{
            reg->type = string_m;
            reg->d.strVal = stringVector[arg->getVal()-1]; //cpp dups "=" is overloaded
            return reg;
        }
        case bool_a:{
            reg->type=bool_m;
            reg->d.boolVal = arg->getVal();
            return reg;
        }
        case nil_a:{
            reg->type = nil_m;
            return reg;
        }
        case userfunc_a:{
            reg->type = userfunc_m;
            reg->d.funcVal = arg->getVal();
            return reg;
        }
        case libfunc_a:{
            reg->type = libfunc_m;
            reg->d.libFuncVal = libFuncVector[arg->getVal()-1];
            return reg;
        }
        default: assert(0);
    }
}