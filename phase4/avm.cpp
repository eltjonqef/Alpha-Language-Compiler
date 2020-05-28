#include <iostream>
#include <fstream>
#include <stdlib.h>
#include <vector>
#include "Quads.hpp"
#include "generateCode.hpp"
#include "avm_workings.hpp"
using namespace std;

vector<SymbolTableEntry*> symboltable;
/*vector<int> intVector;
vector<double> doubleVector;
vector<string> stringVector;
*/
void readFile();
void loadLibFuncs();

int main(){
    instruction *t=new instruction();
    t->setOpCode(nop_vm);
    instructionVector.push_back(t);
    readFile();
    loadLibFuncs();
    return 0;
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
    printInstructions();
}

/*
21 10 7
16 8 0
21 10 6
16 8 1
17 8 1
17 8 0
1 0 1 5 1 6 1
1 0 2 0 1 5 1
1 0 3 0 2 4 1
1 0 4 0 3 6 2
1 0 5 0 4 4 2
1 0 6 0 5 4 1
1 0 7 0 6 6 1
0 0 0 0 7
0 0 8 0 0
*/