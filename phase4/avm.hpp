#include "Quads.hpp"
#include "generateCode.hpp"
#include "SymbolTable.hpp"

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


avm_memcell* avm_translate_operand(vmarg* arg,avm_memcell* reg);

void execute_assign(instruction *t);
void execute_add(instruction *t);
void execute_sub(instruction *t);
void execute_mul(instruction *t);
void execute_div(instruction *t);
void execute_mod(instruction *t);
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
        }
    }
    fclose(f);
    codeSize=instructionVector.size();
    printInstructions();
}
