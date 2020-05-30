#include <iostream>
#include "avm.hpp"
#include "SymbolTable.hpp"
/*
#define execute_add execute_arithmetic
#define execute_sub execute_arithmetic
#define execute_mul execute_arithmetic
#define execute_div execute_arithmetic
#define execute_mod execute_arithmetic
*/
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

void execute_assign(instruction *t){ //done

    avm_memcell *lv=avm_translate_operand(t->getResult(), NULL);

    avm_memcell *rv=avm_translate_operand(t->getArg1(), ax);
    //mia poutsoassert exei edw
    assert(rv);
    avm_assign(lv, rv);
}
//arithmeric
void execute_add(instruction *t){execute_arithmetic(t);} //done
void execute_sub(instruction *t){execute_arithmetic(t);} //done
void execute_mul(instruction *t){execute_arithmetic(t);} //done
void execute_div(instruction *t){execute_arithmetic(t);} //done
void execute_mod(instruction *t){execute_arithmetic(t);} //done
//relational
void execute_ifeq(instruction *t){avm_jeq(t);} //almost done
void execute_ifnoteq(instruction *t){avm_jne(t);}//almost done
void execute_iflesseq(instruction *t){}
void execute_ifgreatereq(instruction *t){}
void execute_ifless(instruction *t){}
void execute_ifgreater(instruction *t){}
//function
void execute_call(instruction *t){}
void execute_param(instruction *t){}
void execute_ret(instruction *t){}
void execute_getretval(instruction *t){}
void execute_funcenter(instruction *t){}
void execute_funcexit(instruction *t){}
//table
void execute_tableCreate(instruction *t){
    avm_memcell *lv=avm_translate_operand(t->getResult(), NULL);
    //ALLH MIA MEGALI ASSERT
    //MEM CLEAR
    lv->type=table_m;
    lv->d.tableVal=new avm_table();
    lv->d.tableVal->incrRefCounter();
}
void execute_tableGet(instruction *t){
    avm_memcell *lv=avm_translate_operand(t->getResult(), NULL);
    avm_memcell *u=avm_translate_operand(t->getArg1(), NULL);
    avm_memcell *i=avm_translate_operand(t->getArg2(), ax);
    
    //
    //POUTSOASSERT
    //
    lv->type=nil_m;
    if(u->type!=table_m){
        cout<<"ERROR\n";
    }
    else{
        avm_memcell *content=avm_getElem(u->d.tableVal, i);
        if(content)
            avm_assign(lv, content);
        else{
            cout<<"not found\n";
        }
    }
}
void execute_tableSet(instruction *t){
    avm_memcell *r=avm_translate_operand(t->getResult(), NULL);
    avm_memcell *i=avm_translate_operand(t->getArg1(), ax);
    avm_memcell *c=avm_translate_operand(t->getArg2(), bx);
    //ASSERT
    //ASSERT
    if(r->type!=table_m)
        cout<<"ILLEGAL use of type\n";
    else
        avm_setElem(r->d.tableVal, i , c);
}
//simple
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
    if(lv->type==string_m)
        lv->d.strVal=string(rv->d.strVal);
    else if(lv->type==table_m)
        lv->d.tableVal->incrRefCounter();
}
void avm_getElem(avm_table *table, avm_memcell* index);
void avm_setElem(avm_table *table, avm_memcell* index, avm_memcell *content){

    avm_table_bucket *bucket;
    if(index->type==number_m){
        bucket=table->getTable_Bucket(index->d.numVal);
    }
    else if(index->type==string_m){
        bucket=table->getTable_Bucket(index->d.strVal);
    }
    if(bucket){
        if(content->type==nil_m){
            if(index->type==number_m){
                table->deleteBucket(index->d.numVal);
            }
            else if(index->type==string_m){
                table->deleteBucket(index->d.strVal);
            }
            table->decrTotal();
        }
        else{
            avm_assign(bucket->getValue(), content);
            table->incrTotal();
        }
    }
    else{
        bucket=new avm_table_bucket();
        avm_assign(bucket->getKey(), index);
        avm_assign(bucket->getValue(), content);
        if(index->type==number_m){
            table->setTable_Bucket(index->d.numVal, bucket);
        }
        else if(index->type==string_m){
            table->setTable_Bucket(index->d.strVal, bucket);
        }
        table->incrTotal();
    }
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

