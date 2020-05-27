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
        instruction *t=new instruction();
        cout<<vmarg_tToString(vmarg_t(stoi(data)))<<endl;
        switch(stoi(data)){
            case 0:{
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
        }
        len--;
    }
    for(int i=0; i<instructionVector.size(); i++){
        cout<<" ("<<vmarg_tToString(instructionVector[i]->getResult()->getType())<<")"<<instructionVector[i]->getResult()->getVal();
        cout<<" ("<<vmarg_tToString(instructionVector[i]->getArg1()->getType())<<")"<<instructionVector[i]->getArg1()->getVal();
        cout<<endl;
    }
}