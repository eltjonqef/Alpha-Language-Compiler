#pragma once
   
#include <iostream>
#include <fstream>
#include <stdlib.h>
#include <vector>
#include <string>
#include "generateCode.hpp"

#define AVM_STACKSIZE 32768
#define AVM_STACKENV_SIZE 4
#define AVM_MAXINSTRUCTIONS (unsigned) nop_v
using namespace std;

#define AVM_ENDING_PC codeSize


enum avm_memcell_t{
    number_m=0,
    string_m=1,
    bool_m=2,
    table_m=3,
    userfunc_m=4,
    libfunc_m=5,
    nil_m=6,
    undef_m=7
};
  



class avm_table;
class avm_memcell{
    public:
    avm_memcell_t type;
    union data{
        double numVal;
        string strVal;
        unsigned char boolVal;
        avm_table* tableVal;
        unsigned funcVal;
        string libFuncVal;
        data(){}
        ~data(){}
    };
    data d;
    avm_memcell() = default;
};


avm_memcell STACK[32768]; 
avm_memcell *ax, *bx, *cx;
avm_memcell *retval;
unsigned top,topsp;
unsigned char executionFinished=0;
unsigned pc=0;
unsigned currLine=0;
unsigned codeSize=0;
vector<string> libFuncVector;


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

void execute_assign(instruction *t){}
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

typedef void(*execute_func_t)(instruction*);

execute_func_t executionFunctions[]={
    execute_assign,
    execute_add,
    execute_sub,
    execute_mul,
    execute_div,
    execute_mod,
    execute_ifeq,
    execute_ifnoteq,
    execute_iflesseq,
    execute_ifgreatereq,
    execute_ifless,
    execute_ifgreater,
    execute_call,
    execute_param,
    execute_ret,
    execute_getretval,
    execute_funcenter,
    execute_funcexit,
    execute_tableCreate,
    execute_tableGet,
    execute_tableSet,
    execute_jump,
    execute_nop
};

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