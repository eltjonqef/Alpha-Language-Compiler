#include "Quads.hpp"
#include "generateCode.hpp"
#include "SymbolTable.hpp"
#include <math.h>
  
#define AVM_STACKSIZE 32768
#define AVM_STACKENV_SIZE 4
#define AVM_MAXINSTRUCTIONS (unsigned) nop_v
#define AVM_NUMACTUALS_OFFSET 4
#define AVM_SAVEDPC_OFFSET 3
#define AVM_SAVEDTOP_OFFSET 2
#define AVM_SAVEDTOPSP_OFFSET 2
using namespace std;

#define AVM_ENDING_PC codeSize
typedef void (*library_func_t)(void);

vector<SymbolTableEntry*> symboltable;
unsigned totalActuals=0;
int globals=0;
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
        unsigned getTotal(){
            return total;
        }
        map<string, avm_table_bucket*> getStrIndexed(){
            return strIndexed;
        }
        map<int, avm_table_bucket*> getNumIndexed(){
            return numIndexed;
        }
};

typedef string (*toString_func_t)(avm_memcell*);
avm_memcell STACK[32768]; 
avm_memcell *ax, *bx, *cx;
avm_memcell *retval;
unsigned top,topsp;
unsigned char executionFinished=0;
unsigned pc=0;
unsigned currLine=0;
unsigned codeSize=0;
vector<string> libFuncVector;
map<string, library_func_t> libFuncMap;

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
    cout<<"ARG "<<arg->getType()<<endl;
    switch(arg->getType()){
        case global_a: return &STACK[AVM_STACKSIZE-1-arg->getVal()];
        case local_a: return &STACK[topsp-arg->getVal()];
        case formal_a: return &STACK[topsp+AVM_STACKENV_SIZE+1+arg->getVal()];
        case retval_a: return retval;
        case int_a:{
            reg->type = number_m;
            reg->d.numVal = intVector[arg->getVal()-1];
            cout<<"ARITHMOS :"<<reg->d.numVal<<endl;
            return reg;
        }
        case double_a:{
            reg->type = number_m;
            reg->d.numVal = doubleVector[arg->getVal()-1];
            return reg;
        }
        case string_a:{
            reg->type = string_m;
            cout<<"TI EINAI AUTO"<<stringVector[arg->getVal()-1]<<endl;
            new(&reg->d.strVal) string(stringVector[arg->getVal()-1]); //cpp dups "=" is overloaded
            return reg;
        }
        case bool_a:{
            cout<<"translation sees bool\n";
            reg->type=bool_m;
            reg->d.boolVal = arg->getVal();
            return reg;
        }
        case nil_a:{
            cout<<"translation sees nil\n";
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
            new(&reg->d.libFuncVal) string(libFuncVector[arg->getVal()-1]);
            return reg;
        }
        default: assert(0);
    }

}




//arithmetic
void execute_assign(instruction *t); //done
void execute_add(instruction *t);   //done
void execute_sub(instruction *t);   //done
void execute_mul(instruction *t);   //done
void execute_div(instruction *t);   //done
void execute_mod(instruction *t);   //done
//relational
void execute_jeq(instruction *t); //done not tested
void execute_jne(instruction *t); //done not tested
void execute_jle(instruction *t); //done not tested
void execute_jge(instruction *t); //done not tested
void execute_jlt(instruction *t); //done not tested
void execute_jgt(instruction *t); //done not tested
//function
void execute_call(instruction *t);
void execute_param(instruction *t);
void execute_ret(instruction *t);
void execute_getretval(instruction *t);
void execute_funcenter(instruction *t);
void execute_funcexit(instruction *t);
//table
void execute_tableCreate(instruction *t);
void execute_tableGet(instruction *t);
void execute_tableSet(instruction *t);
//simple
void execute_jump(instruction *t);
void execute_nop(instruction *t);

void avm_assign(avm_memcell *lv, avm_memcell *rv);
avm_memcell* avm_getElem(avm_table *table, avm_memcell* index);
void avm_setElem(avm_table *table, avm_memcell* index, avm_memcell *content);
void avm_callsaveenvironment();
void avm_push_envvalue(unsigned val);
void avm_dec_top();
void avm_calllibfunc(string func);
unsigned avm_get_envvalue(unsigned i);
unsigned avm_totalactuals();
avm_memcell* avm_getactual(unsigned i);

void avm_jeq(instruction *t); //done not tested
void avm_jne(instruction *t); //done not tested
void avm_jle(instruction *t); //done not tested
void avm_jge(instruction *t); //done not tested
void avm_jlt(instruction *t); //done not tested
void avm_jgt(instruction *t); //done not tested


string avm_tostring(avm_memcell* m);
void libfunc_print();
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

void avm_clearStack(){
    for(int i=0;i<AVM_STACKSIZE;i++){
        STACK[i].type=undef_m;
    }
}

void avm_initStack(){
    avm_clearStack();
    //input global variables
}

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
    execute_jeq,
    execute_jne,
    execute_jle,
    execute_jge,
    execute_jlt,
    execute_jgt,
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
string number_toString(avm_memcell *cell);
string string_toString(avm_memcell *cell);
string bool_toString(avm_memcell *cell);
string table_toString(avm_memcell *cell);
string userfunc_toString(avm_memcell *cell);
string libfunc_toString(avm_memcell *cell);
string nil_toString(avm_memcell *cell);
string undef_toString(avm_memcell *cell);

toString_func_t toStringFuncs[]={
    number_toString,
    string_toString,
    bool_toString,
    table_toString,
    userfunc_toString,
    libfunc_toString,
    nil_toString,
    undef_toString
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
    fread(&globals, sizeof(int), 1, f);
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
            case 7:{
                instruction *t=new instruction();
                t->setOpCode(if_noteq_vm);
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
            case 8:{
                instruction *t=new instruction();
                t->setOpCode(if_lesseq_vm);
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
            case 9:{
                instruction *t=new instruction();
                t->setOpCode(if_greatereq_vm);
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
            case 10:{
                instruction *t=new instruction();
                t->setOpCode(if_less_vm);
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
            case 11:{
                instruction *t=new instruction();
                t->setOpCode(if_greater_vm);
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
            case 12:{
                instruction *t=new instruction();
                t->setOpCode(call_vm);
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setVal(num);
                instructionVector.push_back(t);
                break;
            }
            case 13:{
                instruction *t=new instruction();
                t->setOpCode(param_vm);
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setType(vmarg_t(num));
                fread(&num, sizeof(int), 1, f);
                t->getResult()->setVal(num);
                instructionVector.push_back(t);
                break;
            }
        }
    }
    fclose(f);
    codeSize=instructionVector.size();
    //printInstructions();
}

/*jump*/

void avm_jump(instruction *t){
    if(!executionFinished && t->getResult()->getVal()){
        pc = t->getResult()->getVal();
    }
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

library_func_t libfuncs[]={
    libfunc_print
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
typedef double (*relational_func_t)(avm_memcell *);

string typeStrings[] ={
    "number",
    "string",
    "bool",
    "table",
    "userfunc",
    "libfunc",
    "nil",
    "undef"

};

void avm_jeq(instruction *t){
    cout<<"JEQ CALLED\n";
    assert(t->getResult()->getType() == label_a);
    avm_memcell *rv1 = avm_translate_operand(t->getArg1(),ax);
    cout<<"rv1type ->"<<rv1->type<<"\n";
    avm_memcell *rv2 = avm_translate_operand(t->getArg2(),bx);
    cout<<"rv2type ->"<<rv2->type<<"\n";

    unsigned char result = 0;
    if((rv1->type == undef_m) || (rv2->type == undef_m)){
        //todo throw runtime error
        executionFinished = 1;
        cout<<"RUNTIME ERROR undefined type involved in equality\n";
    }else if((rv1->type == nil_m) || (rv2->type == nil_m)){
        cout<<"nils\n";
        result = ((rv1->type==nil_m) &&(rv2->type==nil_m));
    }else if((rv1->type == bool_m)&&(rv2->type == bool_m)){
        cout<<"bools\n";
        result = (avm_tobool(rv1) == avm_tobool(rv2));
    }else if(rv1->type != rv2->type){
        //todo throw runtime error
        executionFinished = 1;
        cout<<"RUNTIME ERROR can't compare "<<typeStrings[rv1->type]<<" with "<<typeStrings[rv2->type]<<"\n";
    }else{
        cout<<"in else\n";
        if(rv1->type == string_m){
            result = rv1->d.strVal.compare(rv2->d.strVal);
            if(result == 0){
                result = 1;
            }else{
                result = 0;
            }
            cout<<"in eq strcompare says "<<result<<"\n";
        }else if(rv1->type == number_m){
            cout<<"nums\n";
            result = (rv1->d.numVal == rv2->d.numVal);
        }else if(rv1->type == libfunc_m){
            result = rv1->d.libFuncVal.compare(rv2->d.libFuncVal);
        }else if(rv1->type == table_m){//todo tables
            result = 0; //must change
        }else if(rv1->type == userfunc_m){//todo userfuncs
            result = 0;
        }
    }
    if(!executionFinished && result){
        cout<<"equality passed setting pc -> "<<t->getResult()->getVal()<<"\n";
        pc = t->getResult()->getVal();
    }
    cout<<"JEQ done\n";
}
void avm_jne(instruction *t){
    assert(t->getResult()->getType() == label_a);
    avm_memcell *rv1 = avm_translate_operand(t->getArg1(),ax);
    avm_memcell *rv2 = avm_translate_operand(t->getArg2(),bx);

    unsigned char result = 0;
    if((rv1->type == undef_m) || (rv2->type == undef_m)){
        executionFinished = 1;
        //todo runtime error
        cout<<"RUNTIME ERROR undefined type involved in jne\n";
    }else if((rv1->type==nil_m)&&(rv2->type==nil_m)){
        result = 0;
    }else if(rv1->type == bool_m){
        result = avm_tobool(rv1) != avm_tobool(rv2);
    }else if(((rv1->type==table_m) && (rv2->type==nil_m))||((rv2->type==table_m) && (rv1->type==nil_m))){
        result = 1; //dialeksi 9 slide 22
    }else if(rv1->type != rv2->type){
        executionFinished = 1;
        cout<<"RUNTIME ERROR can't compare "<<typeStrings[rv1->type]<<" with "<<typeStrings[rv2->type]<<"\n";
    }else{
        if(rv1->type == string_m){
            result = rv1->d.strVal.compare(rv2->d.strVal);
            if(result != 0 ){
                result =1;
            }
        }else if(rv1->type == number_m){
            result = (rv1->d.numVal != rv2->d.numVal);
        }else if(rv1->type == libfunc_m){
            result = !(rv1->d.libFuncVal.compare(rv2->d.libFuncVal));
        }else if(rv1->type == table_m){
            result = 0; //todo
        }else if(rv1->type == userfunc_m){
            result = 0; //todo
        }
    }
    if(!executionFinished && result){
        pc = t->getResult()->getVal();
    }
}

void avm_jle(instruction *t){
    assert(t->getResult()->getType() == label_a);
    avm_memcell *rv1 = avm_translate_operand(t->getArg1(),ax);
    avm_memcell *rv2 = avm_translate_operand(t->getArg2(),bx);

    unsigned char result = 0;
    if(rv1->type == undef_m || rv2->type == undef_m){
        //todo throw runtime error
        executionFinished = 1;
        cout<<"RUNTIME ERROR undefined type involved in jle\n";
    }else if(rv1->type == nil_m && rv1->type == nil_m){
        result =0;
    }else if(rv1->type == bool_m && rv2->type == bool_m){
        result = avm_tobool(rv1) <= avm_tobool(rv2);
    }else if(rv1->type != rv2->type){
        //todo throw runtime error
        executionFinished = 1;
        cout<<"RUNTIME ERROR can't compare "<<typeStrings[rv1->type]<<" with "<<typeStrings[rv2->type]<<"\n";
    }else{
        if(rv1->type == string_m){
            cout<<"non numerical comparison is set false\n";
            result = 0;//dialeksi 9 slide 22
        }else if(rv1->type == number_m){
            result = rv1->d.numVal <= rv2->d.numVal;
        }else if(rv1->type == libfunc_m){
            cout<<"non numerical comparison is set false\n";
            result = 0 ; //dialeksi 9 slide 22
        }else if(rv1->type == table_m){
        cout<<"non numerical comparison is set false\n";
            result = 0; //dialeksi 9 slide 22
        }else if(rv1->type == userfunc_m){
        cout<<"non numerical comparison is set false\n";
            result = 0;//dialeksi 9 slide 22
        }
    }
    if(!executionFinished && result){
        pc = t->getResult()->getVal();
    }
}
void avm_jge(instruction *t){
    assert(t->getResult()->getType() == label_a);
    avm_memcell *rv1 = avm_translate_operand(t->getArg1(),ax);
    avm_memcell *rv2 = avm_translate_operand(t->getArg2(),bx);

    unsigned char result = 0;
    if(rv1->type == undef_m || rv2->type == undef_m){
        //todo throw runtime error
        executionFinished = 1;
        cout<<"RUNTIME ERROR undefined type involved in jge\n";
    }else if(rv1->type == nil_m && rv1->type == nil_m){
        result =0;
    }else if(rv1->type == bool_m && rv2->type == bool_m){
        result = avm_tobool(rv1) >= avm_tobool(rv2);
    }else if(rv1->type != rv2->type){
        //todo throw runtime error
        executionFinished = 1;
        cout<<"RUNTIME ERROR can't compare "<<typeStrings[rv1->type]<<" with "<<typeStrings[rv2->type]<<"\n";
    }else{
        if(rv1->type == string_m){
            cout<<"non numerical comparison is set false\n";
            result = 0; //dialeksi 9 slide 22
        }else if(rv1->type == number_m){
            result = rv1->d.numVal >= rv2->d.numVal;
        }else if(rv1->type == libfunc_m){
            cout<<"non numerical comparison is set false\n";
            result = 0 ; //dialeksi 9 slide 22
        }else if(rv1->type == table_m){
            cout<<"non numerical comparison is set false\n";
            result = 0; //dialeksi 9 slide 22
        }else if(rv1->type == userfunc_m){
            cout<<"non numerical comparison is set false\n";
            result = 0;//dialeksi 9 slide 22
        }
    }
    if(!executionFinished && result){
        pc = t->getResult()->getVal();
    }
}
void avm_jlt(instruction *t){
    assert(t->getResult()->getType() == label_a);
    avm_memcell *rv1 = avm_translate_operand(t->getArg1(),ax);
    avm_memcell *rv2 = avm_translate_operand(t->getArg2(),bx);

    unsigned char result = 0;
    if(rv1->type == undef_m || rv2->type == undef_m){
        //todo throw runtime error
        executionFinished = 1;
        cout<<"RUNTIME ERROR undefined type involved in jlt\n";
    }else if(rv1->type == nil_m && rv1->type == nil_m){
        result =0;
    }else if(rv1->type == bool_m && rv2->type == bool_m){
        result = avm_tobool(rv1) < avm_tobool(rv2);
    }else if(rv1->type != rv2->type){
        //todo throw runtime error
        executionFinished = 1;
        cout<<"RUNTIME ERROR can't compare "<<typeStrings[rv1->type]<<" with "<<typeStrings[rv2->type]<<"\n";
    }else{
        if(rv1->type == string_m){
            cout<<"non numerical comparison is set false\n";
            result = 0;//dialeksi 9 slide 22
        }else if(rv1->type == number_m){
            result = rv1->d.numVal < rv2->d.numVal;
        }else if(rv1->type == libfunc_m){
            cout<<"non numerical comparison is set false\n";
            result = 0 ;//dialeksi 9 slide 22
        }else if(rv1->type == table_m){
        cout<<"non numerical comparison is set false\n";
            result = 0; //dialeksi 9 slide 22
        }else if(rv1->type == userfunc_m){
        cout<<"non numerical comparison is set false\n";
            result = 0;//dialeksi 9 slide 22
        }
    }
    if(!executionFinished && result){
        pc = t->getResult()->getVal();
    }
}
void avm_jgt(instruction *t){
    assert(t->getResult()->getType() == label_a);
    avm_memcell *rv1 = avm_translate_operand(t->getArg1(),ax);
    avm_memcell *rv2 = avm_translate_operand(t->getArg2(),bx);

    unsigned char result = 0;
    if(rv1->type == undef_m || rv2->type == undef_m){
        //todo throw runtime error
        executionFinished = 1;
        cout<<"RUNTIME ERROR undefined type involved in jgte\n";
    }else if(rv1->type == nil_m && rv1->type == nil_m){
        result =0;
    }else if(rv1->type == bool_m && rv2->type == bool_m){
        result = avm_tobool(rv1) > avm_tobool(rv2);
    }else if(rv1->type != rv2->type){
        //todo throw runtime error
        executionFinished = 1;
        cout<<"RUNTIME ERROR can't compare "<<typeStrings[rv1->type]<<" with "<<typeStrings[rv2->type]<<"\n";
    }else{
        if(rv1->type == string_m){
            cout<<"non numerical comparison is set false\n";
            result = 0; //dialeksi 9 slide 22
        }else if(rv1->type == number_m){
            result = rv1->d.numVal > rv2->d.numVal;
        }else if(rv1->type == libfunc_m){
            cout<<"non numerical comparison is set false\n";
            result = 0 ; //dialeksi 9 slide 22
        }else if(rv1->type == table_m){
            cout<<"non numerical comparison is set false\n";
            result = 0; //dialeksi 9 slide 22
        }else if(rv1->type == userfunc_m){
            cout<<"non numerical comparison is set false\n";
            result = 0;//dialeksi 9 slide 22
        }
    }
    if(!executionFinished && result){
        pc = t->getResult()->getVal();
    }
}