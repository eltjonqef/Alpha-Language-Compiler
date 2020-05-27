#include <iostream>
#include <fstream>
#include <stdlib.h>
#include <vector>
#include "Quads.hpp"
    #include "generateCode.hpp"
using namespace std;

vector<SymbolTableEntry*> symboltable;
vector<int> intVector;
vector<double> doubleVector;
vector<string> stringVector;

void readFile();

int main(){

    readFile();
    return 0;
}

void readFile(){

    ifstream fs;
    fs.open("binary.abc");
    string magicNumber;
    fs>>magicNumber;
    string readLen;
    fs>>readLen;
    int len=stoi(readLen);
    string data;
    
    while(len){
        fs>>data;
        SymbolTableEntry *sym=new SymbolTableEntry(data);
        symboltable.push_back(sym);
        len--;
    }
    fs>>readLen;
    len=stoi(readLen);
    while(len){
        fs>>data;
        intVector.push_back(stoi(data));
        len--;
    }
    fs>>readLen;
    len=stoi(readLen);
    while(len){
        fs>>data;
        doubleVector.push_back(atof(data.c_str()));
        len--;
    }
    fs>>readLen;
    len=stoi(readLen);
    while(len){
        fs>>data;
        stringVector.push_back(data);
        len--;
    }
    fs>>readLen;
    len=stoi(readLen);
    while(len){
        fs>>data;
        
        switch(stoi(data)){
            case 0:{
                instruction *t=new instruction();
                t->setOpCode(assign_vm);
                fs>>data;
                
                t->getResult()->setType(vmarg_t(stoi(data)));
                fs>>data;
                
                t->getResult()->setVal(stoi(data));
                fs>>data;
                
                t->getArg1()->setType(vmarg_t(stoi(data)));
                fs>>data;
                
                t->getArg1()->setVal(stoi(data));
                instructionVector.push_back(t);
                break;
            }
            case 1:{
                fs>>data;
                
                fs>>data;
                fs>>data;
                fs>>data;
                fs>>data;
                fs>>data;
                break;
            }
            case 2:{
                fs>>data;
                
                fs>>data;
                fs>>data;
                fs>>data;
                fs>>data;
                fs>>data;
                break;
            }
            case 3:{
                fs>>data;
                
                fs>>data;
                fs>>data;
                fs>>data;
                fs>>data;
                fs>>data;
                break;
            }
            case 4:{
                fs>>data;
                
                fs>>data;
                fs>>data;
                fs>>data;
                fs>>data;
                fs>>data;
                break;
            }
            case 5:{
                fs>>data;
                
                fs>>data;
                fs>>data;
                fs>>data;
                fs>>data;
                fs>>data;
                break;
            }
            case 6:{
                fs>>data;
                
                fs>>data;
                fs>>data;
                fs>>data;
                fs>>data;
                fs>>data;
                break;
            }
            case 18:{
                fs>>data;
                fs>>data;
                break;
            }
            case 16:{
                fs>>data;
                fs>>data;
                break;
            }
            case 17:{
                fs>>data;
                fs>>data;
                break;
            }
            case 21:{
                instruction *t=new instruction();
                t->setOpCode(jump_vm);
                fs>>data;
                t->getResult()->setType(vmarg_t(stoi(data)));
                fs>>data;
                t->getResult()->setVal(stoi(data));
                instructionVector.push_back(t);
                break;
            }
            default:
                break;
        }
            /*case 0:{
                cout<<vmarg_tToString(vmarg_t(stoi(data)))<<endl;
                return;
                t->setOpCode(assign_vm);
                fs>>data;
                t->getResult()->setType(vmarg_t(stoi(data)));
                fs>>data;
                t->getResult()->setVal(stoi(data));
                fs>>data;
                t->getArg1()->setType(vmarg_t(stoi(data)));
                fs>>data;
                t->getArg1()->setVal(stoi(data));
                instructionVector.push_back(t);
                break;
            }
        }*/
        len--;
    }
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