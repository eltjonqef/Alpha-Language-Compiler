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
    retval=new avm_memcell();
    top=AVM_STACKSIZE-1-globals-2;
    topsp=AVM_STACKSIZE-1;
    while(!executionFinished){
        execute_cycle();
    }    
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
void execute_jeq(instruction *t){avm_jeq(t);} //done not tested
void execute_jne(instruction *t){avm_jne(t);}//done not tested
void execute_jle(instruction *t){avm_jle(t);}//done not tested
void execute_jge(instruction *t){avm_jge(t);}//done not tested
void execute_jlt(instruction *t){avm_jlt(t);}//done not tested
void execute_jgt(instruction *t){avm_jgt(t);}//done not tested
//function
void execute_call(instruction *t){
    avm_memcell *func=avm_translate_operand(t->getResult(), ax);
    avm_callsaveenvironment(); //NOT IMPLEMENTED YET
    switch(func->type){
        case userfunc_m:{
            pc=func->d.funcVal;
            assert(pc<AVM_ENDING_PC);
            assert(instructionVector[pc]->getOP()==funcenter_vm);
            break;
        }
        case string_m:{
            avm_calllibfunc(func->d.strVal); //NOT IMPLEMENTED YET
            break;
        }
        case libfunc_m:{
            avm_calllibfunc(func->d.libFuncVal); //NOT IMPLEMENTED YET
            break;
        }
        default:{
            executionFinished=1;
        }
    }
}
void execute_param(instruction *t){
    avm_memcell *arg=avm_translate_operand(t->getResult(), ax);
    avm_assign(&STACK[top], arg);
    ++totalActuals;
    avm_dec_top();
}
void execute_ret(instruction *t){}
void execute_getretval(instruction *t){}
void execute_funcenter(instruction *t){
    avm_memcell *function=avm_translate_operand(t->getResult(), ax);
    assert(function);
    //assert(pc==function->d.numVal);
    totalActuals=0;
    func *f=symboltable[t->getResult()->getVal()];
    topsp=top;
    top=top-f->localsSize;
}
void execute_funcexit(instruction *t){
    top=avm_get_envvalue(topsp+AVM_SAVEDTOP_OFFSET);
    pc=avm_get_envvalue(topsp+AVM_SAVEDPC_OFFSET);
    topsp=avm_get_envvalue(topsp+AVM_SAVEDTOPSP_OFFSET);
}
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
void execute_jump(instruction *t){avm_jump(t);}
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
avm_memcell* avm_getElem(avm_table *table, avm_memcell* index){
    avm_table_bucket *bucket;
    if(index->type==number_m){
        bucket=table->getTable_Bucket(index->d.numVal);
    }
    else{
        bucket=table->getTable_Bucket(index->d.strVal);
    }
    return bucket->getValue();
}
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
void avm_callsaveenvironment(){
    avm_push_envvalue(totalActuals);
    avm_push_envvalue(pc+1);
    avm_push_envvalue(top+totalActuals+2);
    avm_push_envvalue(topsp);
}
void avm_push_envvalue(unsigned val){
    STACK[top].type=number_m;
    STACK[top].d.numVal=val;
    avm_dec_top();
}
void avm_dec_top(){
    if(!top){
        cout<<"STACK OVERFLOW\n";
        executionFinished=1;
    }
    else{
        --top;
    }
}
void avm_calllibfunc(string func){
    //TO DO IF NOT EXISTING
    library_func_t f=libFuncMap[func];
    if(!f){
        cout<<"CALL LIB ERROR\n";
        executionFinished=1;
    }
    else{
        topsp=top;
        totalActuals=0;
        (*f)();
        if(!executionFinished){
            execute_funcexit(instructionVector[pc]);
        }
    }
}
string avm_tostring(avm_memcell* m){
    assert(m->type>=0 && m->type<undef_m);
    return (*toStringFuncs[m->type])(m);
}

unsigned avm_get_envvalue(unsigned i){
    if(STACK[i].type!=number_m){cout<<"found nul\n";}
    assert(STACK[i].type==number_m);
    unsigned val=(unsigned) STACK[i].d.numVal;
    assert(STACK[i].d.numVal==(double)val);
    return val;
}

unsigned avm_totalactuals(){
    return avm_get_envvalue(topsp+AVM_NUMACTUALS_OFFSET);
}

avm_memcell* avm_getactual(unsigned i){
    assert(i<avm_totalactuals());
    return &STACK[topsp+AVM_STACKENV_SIZE+1+i];
}

void libfunc_print(){
    unsigned n=avm_totalactuals();
    for(unsigned i=0; i<n; i++){
        //cout<<"ARITHMOS\n"<<avm_getactual(i)->d.numVal<<endl;
        cout<<avm_tostring(avm_getactual(i));
    }cout<<endl;
}
void libfunc_input(){}
void libfunc_objectmemberkeys(){
    unsigned n=avm_totalactuals();
    if(n!=1)
        cout<<"ERROR typeof\n";
    else{
        map<string, avm_table_bucket*> strMap=avm_getactual(0)->d.tableVal->getStrIndexed();
        map<int, avm_table_bucket*> numMap=avm_getactual(0)->d.tableVal->getNumIndexed();
        int i=0;
        retval->type=table_m;
        retval->d.tableVal=new avm_table();
        retval->d.tableVal->incrRefCounter();
        for(auto const &entry: strMap){
            avm_memcell *index=new avm_memcell();
            index->type=number_m;
            index->d.numVal=i++;
            avm_setElem(retval->d.tableVal, index, entry.second->getKey());
        }
        for(auto const &entry: numMap){
            avm_memcell *index=new avm_memcell();
            index->type=number_m;
            index->d.numVal=i++;
            avm_setElem(retval->d.tableVal, index, entry.second->getKey());
        }
    }
}
void libfunc_objecttotalmembers(){
    unsigned n=avm_totalactuals();
    if(n!=1)
        cout<<"ERROR typeof\n";
    else{
        retval->type=number_m;
        retval->d.numVal=avm_getactual(0)->d.tableVal->getTotal();
        //new(&retval->d.strVal) string(typeStrings[avm_getactual(0)->type]);
    }
}
void libfunc_objectcopy(){}
void libfunc_totalarguments(){}
void libfunc_argument(){}
void libfunc_typeof(){
    unsigned n=avm_totalactuals();
    if(n!=1)
        cout<<"ERROR typeof\n";
    else{
        retval->type=string_m;
        new(&retval->d.strVal) string(typeStrings[avm_getactual(0)->type]);
    }
}
void libfunc_sqrt(){
    unsigned n=avm_totalactuals();
    if(n!=1)
        cout<<"ERROR typeof\n";
    else{
        retval->type=number_m;
        retval->d.numVal=sqrt(avm_getactual(0)->d.numVal);
        //new(&retval->d.strVal) string(typeStrings[avm_getactual(0)->type]);
    }
}
void libfunc_cos(){
    unsigned n=avm_totalactuals();
    if(n!=1)
        cout<<"ERROR typeof\n";
    else{
        retval->type=number_m;
        retval->d.numVal=cos(avm_getactual(0)->d.numVal * PI /180);
        //new(&retval->d.strVal) string(typeStrings[avm_getactual(0)->type]);
    }
}
void libfunc_sin(){
    unsigned n=avm_totalactuals();
    if(n!=1)
        cout<<"ERROR typeof\n";
    else{
        retval->type=number_m;
        retval->d.numVal=sin(avm_getactual(0)->d.numVal * PI /180);
        //new(&retval->d.strVal) string(typeStrings[avm_getactual(0)->type]);
    }
}
string number_toString(avm_memcell *m){
    
    if(fmod(m->d.numVal,1)==0){
        return to_string((int)m->d.numVal);
    }
    return to_string(m->d.numVal);
}
string string_toString(avm_memcell *m){
    return m->d.strVal;
}
string bool_toString(avm_memcell *m){
    if(m->d.boolVal==0)
        return "FALSE";
    else
        return "TRUE";
}
string table_toString(avm_memcell *m){
    string toReturn="";
    toReturn+="[";
    map<string, avm_table_bucket*> strMap=m->d.tableVal->getStrIndexed();
    map<int, avm_table_bucket*> numMap=m->d.tableVal->getNumIndexed();
    for(auto const &entry: strMap){
        toReturn+="{";
        toReturn+=avm_tostring(entry.second->getKey());
        toReturn+=":";
        toReturn+=avm_tostring(entry.second->getValue());
        toReturn+="}\n";
    }
    for(auto const &entry: numMap){
        toReturn+="{";
        toReturn+=avm_tostring(entry.second->getKey());
        toReturn+=":";
        toReturn+=avm_tostring(entry.second->getValue());
        toReturn+="}\n";
    }
    toReturn+="]\n";
    return toReturn;
}
string userfunc_toString(avm_memcell *m){}
string libfunc_toString(avm_memcell *m){}
string nil_toString(avm_memcell *m){
    return "nil";
}
string undef_toString(avm_memcell *m){}
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
    libFuncMap["print"]=libfunc_print;
    libFuncVector.push_back("input");
    libFuncMap["input"]=libfunc_input;
    libFuncVector.push_back("objectmemberkeys");
    libFuncMap["objectmemberkeys"]=libfunc_objectmemberkeys;
    libFuncVector.push_back("objecttotalmembers");
    libFuncMap["objecttotalmembers"]=libfunc_objecttotalmembers;
    libFuncVector.push_back("objectcopy");
    libFuncMap["objectcopy"]=libfunc_objectcopy;
    libFuncVector.push_back("totalarguments");
    libFuncMap["totalarguments"]=libfunc_totalarguments;
    libFuncVector.push_back("argument");
    libFuncMap["argument"]=libfunc_argument;
    libFuncVector.push_back("typeof");
    libFuncMap["typeof"]=libfunc_typeof;
    libFuncVector.push_back("sqrt");
    libFuncMap["sqrt"]=libfunc_sqrt;
    libFuncVector.push_back("cos");
    libFuncMap["cos"]=libfunc_cos;
    libFuncVector.push_back("sin");
    libFuncMap["sin"]=libfunc_sin;
}

