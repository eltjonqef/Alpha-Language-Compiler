#include "Quads.hpp"
#include "generateCode.hpp"
#include "SymbolTable.hpp"
#include <math.h>
  
#define AVM_STACKSIZE 32768
#define AVM_STACKENV_SIZE 4
#define AVM_MAXINSTRUCTIONS (unsigned) nop_v

using namespace std;

#define AVM_ENDING_PC codeSize
vector<SymbolTableEntry*> symboltable;


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
    avm_memcell() {}
};
class avm_table_bucket{
    private:
        avm_memcell* key;
        avm_memcell* value;
    public:
        avm_table_bucket(){
            key=new avm_memcell();
            value=new avm_memcell();
        }
        avm_memcell *getKey(){
            return key;
        }
        avm_memcell *getValue(){
            return value;
        }
};

class avm_table{
    private:
        unsigned refCounter;
        map<int, avm_table_bucket*> numIndexed;
        map<string, avm_table_bucket*> strIndexed;
        unsigned total;
    public:
        avm_table(){
            refCounter=0;
            total=0;
        }
        void incrRefCounter(){
            refCounter++;
        }
        void decrRefCounter(){
            assert(refCounter>0);
            --refCounter;
        }
        avm_table_bucket *getTable_Bucket(int key){
            return numIndexed[key];
        }
        avm_table_bucket *getTable_Bucket(string key){
            return strIndexed[key];
        }
        void setTable_Bucket(int key, avm_table_bucket *bucket){
            numIndexed[key]=bucket;
        }
        void setTable_Bucket(string key, avm_table_bucket *bucket){
            strIndexed[key]=bucket;
        }
        void deleteBucket(int key){
            numIndexed.erase(key);
        }
        void deleteBucket(string key){
            strIndexed.erase(key);
        }
        void incrTotal(){
            total++;
        }
        void decrTotal(){
            total--;
        }
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


typedef void (*memclear_func_t)(avm_memcell*);

void avm_warning(string format);

void memclear_string(avm_memcell* m){
    //assert(m->d.strVal);
    //free(m->d.strVal);
    m->d.strVal = "";
}
void memclear_table(avm_memcell* m){
    assert(m->d.tableVal);
    //avm_tabledecrefcounter(m->d.tableVal);
}

memclear_func_t memclearFuncs[]{
    0, /*number*/
    memclear_string,
    0, /*bool*/
    memclear_table,
    0,/*userfunc*/
    0,/*livfunc*/
    0,/*nil*/
    0,/*undef*/

};

void avm_memcellclear(avm_memcell* m){
    if(m->type != undef_m){
        memclear_func_t f = memclearFuncs[m->type];
        if(f){
            (*f)(m);
            m->type = undef_m;
        }
    }
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
            reg->d.strVal = (stringVector[arg->getVal()-1]); //cpp dups "=" is overloaded
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
void execute_assign(instruction *t); //done
void execute_add(instruction *t);   //done
void execute_sub(instruction *t);   //done
void execute_mul(instruction *t);   //done
void execute_div(instruction *t);   //done
void execute_mod(instruction *t);   //done
void execute_ifeq(instruction *t);
void execute_ifnoteq(instruction *t);
void execute_iflesseq(instruction *t);
void execute_ifgreatereq(instruction *t);
void execute_ifless(instruction *t);
void execute_ifgreater(instruction *t);
void execute_call(instruction *t);
void execute_param(instruction *t);
void execute_ret(instruction *t);
void execute_getretval(instruction *t);
void execute_funcenter(instruction *t);
void execute_funcexit(instruction *t);
void execute_tableCreate(instruction *t);
void execute_tableGet(instruction *t);
void execute_tableSet(instruction *t);
void execute_jump(instruction *t);
void execute_nop(instruction *t);

void avm_assign(avm_memcell *lv, avm_memcell *rv);
void avm_getElem(avm_table *table, avm_memcell* index);
void avm_setElem(avm_table *table, avm_memcell* index, avm_memcell *content);

/*useful functions*/
typedef unsigned char (*tobool_func_t)(avm_memcell *);

unsigned char number_tobool(avm_memcell * m){return m->d.numVal != 0;}
unsigned char string_tobool(avm_memcell * m){return m->d.strVal[0] != 0;}
unsigned char bool_tobool(avm_memcell * m){return m->d.boolVal;}
unsigned char table_tobool(avm_memcell * m){return 1;}
unsigned char userfunc_tobool(avm_memcell * m){return 1;}
unsigned char libfunc_tobool(avm_memcell * m){return 1;}
unsigned char nil_tobool(avm_memcell * m){return 0;}
unsigned char undef_tobool(avm_memcell * m){assert(0);return(0);}

tobool_func_t toboolFuncs[]{
    number_tobool,
    string_tobool,
    bool_tobool,
    table_tobool,
    userfunc_tobool,
    libfunc_tobool,
    nil_tobool,
    undef_tobool
};

unsigned char avm_tobool(avm_memcell *m){
    assert((m->type >= 0) &&(m->type < undef_m));
    return (*toboolFuncs[m->type])(m);
}



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

void execute_cycle();

void readFile(){
    int magicNumber, loop;
    size_t len;
    FILE *f;
    f=fopen("binary.abc", "rb");
    fread(&magicNumber, sizeof(int), 1, f);
    fread(&loop, sizeof(int), 1, f);
    for(int i=0; i<loop; i++){
        char *data;
        fread(&len, sizeof(size_t), 1, f);
        data=(char*)malloc(sizeof(char)*(len+1));
        fread(data, sizeof(char), len, f);
        data[len]='\0';
        SymbolTableEntry *sym=new SymbolTableEntry(data);
        symboltable.push_back(sym);
    }
    fread(&loop, sizeof(int), 1, f);
    for(int i=0; i<loop; i++){
        int num;
        fread(&num, sizeof(int), 1, f);
        intVector.push_back(num);
    }
    fread(&loop, sizeof(int), 1, f);
    for(int i=0; i<loop; i++){
        double num;
        fread(&num, sizeof(double), 1, f);
        doubleVector.push_back(num);
    }
    fread(&loop, sizeof(int), 1, f);
    for(int i=0; i<loop; i++){
        char *data;
        fread(&len, sizeof(size_t), 1, f);
        data=(char*)malloc(sizeof(char)*(len+1));
        fread(data, sizeof(char), len, f);
        data[len]='\0';
        stringVector.push_back(data);
    }
    fread(&loop, sizeof(int), 1, f);
    for(int i=0; i<loop; i++){

        int num;        
        fread(&num, sizeof(int), 1, f);
        switch(num){
            case 0:{
                instruction *t=new instruction();
                t->setOpCode(assign_vm);
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setVal(num);
                fread(&num, sizeof(int), 1, f);
                t->getArg1()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getArg1()->setVal(num);
                instructionVector.push_back(t);
                break;
            }
            case 1:{
                instruction *t=new instruction();
                t->setOpCode(add_vm);
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setVal(num);
                fread(&num, sizeof(int), 1, f);
                t->getArg1()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getArg1()->setVal(num);
                fread(&num, sizeof(int), 1, f);
                t->getArg2()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getArg2()->setVal(num);
                instructionVector.push_back(t);
                break;
            }
            case 2:{
                instruction *t=new instruction();
                t->setOpCode(sub_vm);
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setVal(num);
                fread(&num, sizeof(int), 1, f);
                t->getArg1()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getArg1()->setVal(num);
                fread(&num, sizeof(int), 1, f);
                t->getArg2()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getArg2()->setVal(num);
                instructionVector.push_back(t);
                break;
            }
            case 3:{
                instruction *t=new instruction();
                t->setOpCode(mul_vm);
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setVal(num);
                fread(&num, sizeof(int), 1, f);
                t->getArg1()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getArg1()->setVal(num);
                fread(&num, sizeof(int), 1, f);
                t->getArg2()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getArg2()->setVal(num);
                instructionVector.push_back(t);
                break;
            }
            case 4:{
                instruction *t=new instruction();
                t->setOpCode(div_vm);
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setVal(num);
                fread(&num, sizeof(int), 1, f);
                t->getArg1()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getArg1()->setVal(num);
                fread(&num, sizeof(int), 1, f);
                t->getArg2()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getArg2()->setVal(num);
                instructionVector.push_back(t);
                break;
            }
            case 5:{
                instruction *t=new instruction();
                t->setOpCode(mod_vm);
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setVal(num);
                fread(&num, sizeof(int), 1, f);
                t->getArg1()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getArg1()->setVal(num);
                fread(&num, sizeof(int), 1, f);
                t->getArg2()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getArg2()->setVal(num);
                instructionVector.push_back(t);
                break;
            }
            case 6:{
                instruction *t=new instruction();
                t->setOpCode(if_eq_vm);
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setVal(num);
                fread(&num, sizeof(int), 1, f);
                t->getArg1()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getArg1()->setVal(num);
                fread(&num, sizeof(int), 1, f);
                t->getArg2()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getArg2()->setVal(num);
                instructionVector.push_back(t);
                break;
            }
            case 18:{
                instruction *t=new instruction();
                t->setOpCode(tablecreate_vm);
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setVal(num);
                instructionVector.push_back(t);
                break;
            }
            case 16:{
                instruction *t=new instruction();
                t->setOpCode(funcenter_vm);
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setVal(num);
                instructionVector.push_back(t);
                break;
            }
            case 17:{
                instruction *t=new instruction();
                t->setOpCode(funcexit_vm);
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setVal(num);
                instructionVector.push_back(t);
                break;
            }
            case 21:{
                instruction *t=new instruction();
                t->setOpCode(jump_vm);
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setVal(num);
                instructionVector.push_back(t);
                break;
            }
            case 19:{
                instruction *t=new instruction();
                t->setOpCode(tablegetelem_vm);
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setVal(num);
                fread(&num, sizeof(int), 1, f);
                t->getArg1()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getArg1()->setVal(num);
                fread(&num, sizeof(int), 1, f);
                t->getArg2()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getArg2()->setVal(num);
                instructionVector.push_back(t);
                break;
            }
            case 20:{
                instruction *t=new instruction();
                t->setOpCode(tablesetelem_vm);
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setVal(num);
                fread(&num, sizeof(int), 1, f);
                t->getArg1()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getArg1()->setVal(num);
                fread(&num, sizeof(int), 1, f);
                t->getArg2()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getArg2()->setVal(num);
                instructionVector.push_back(t);
                break;
            }
        }
    }
    fclose(f);
    codeSize=instructionVector.size();
    //printInstructions();
}



/*arithmetics*/




typedef double (*arithmetic_func_t)(double x,double y);

double add_impl (double x,double y){return x+y;}
double sub_impl (double x,double y){return x-y;}
double mul_impl (double x,double y){return x*y;}
double div_impl (double x,double y){
    assert(y != 0);//todo error instead of assert
    return x/y;
}
double mod_impl (double x,double y){
    assert(y != 0);
    return fmod(x,y);
}

arithmetic_func_t arithmeticFuncs[] = {
    add_impl,
    sub_impl,
    mul_impl,
    div_impl,
    mod_impl
};

void execute_arithmetic (instruction* instr){
    avm_memcell* lv = avm_translate_operand(instr->getResult(),(avm_memcell*) 0);
    avm_memcell* rv1 = avm_translate_operand(instr->getArg1(),ax);
    avm_memcell* rv2 = avm_translate_operand(instr->getArg2(),bx);

    //assert(lv && (&STACK[top] <= lv && &STACK[AVM_STACKSIZE] > lv || lv == &retval));
    assert(rv1 && rv2);
    if((rv1->type != number_m) ||(rv2->type != number_m)){
        cout<<"arithmetic error\n";
        executionFinished = 1;
    }else{
        arithmetic_func_t op = arithmeticFuncs[instr->getOP()-add_vm];
        avm_memcellclear(lv);
        lv->type = number_m;
        cout<<"rv1->d.numVal + rv2->d.numVal = "<<rv1->d.numVal+rv2->d.numVal<<"\n";
        lv->d.numVal = (*op)(rv1->d.numVal,rv2->d.numVal);
        cout<<"val->"<<lv->d.numVal<<"\n";
        //arithmetic_func_t op = arithmeticFuncs[instr->getOP()-add_vm];
    }
}

//relational

