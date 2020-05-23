#pragma once

#include <string>      
#include <stack>
#include <assert.h>
using namespace std;
enum SymbolType {
    GLOB,
    LOCL,
    FORMAL,
    USERFUNC, 
    LIBFUNC 
};  
   
enum scopespace_t{
    programvar,functionlocal,formalarg
};
enum symbol_t {var_s,programfunc_s,libraryfunc_s};


unsigned programVarOffsetCounter = 0;
unsigned functionLocalOffsetCounter = 0;
unsigned formalArgOffsetCounter = 0;
int scopeSpaceCounter = 1;
std::stack<unsigned> functionOffsets;



void saveAndResetFunctionOffset(){
    functionOffsets.push(functionLocalOffsetCounter);
    functionLocalOffsetCounter = 0;
}

void resetFormalArgOffsetCounter(){
    formalArgOffsetCounter = 0;
}

unsigned getPrevFunctionOffset(){
    if(functionOffsets.empty()){
        assert(0);
    }else{
        unsigned retval = functionOffsets.top();
        functionOffsets.pop();
        return retval;
    }
}




scopespace_t getCurrentScopespace(void) {
    if(scopeSpaceCounter == 1){
        return programvar;
    }else if(scopeSpaceCounter % 2 == 0){
        return formalarg;
    }else{
        return functionlocal;
    }
}



unsigned currentOffset(){
    switch(getCurrentScopespace()) {
        case programvar : return programVarOffsetCounter;
        case formalarg : return formalArgOffsetCounter;
        case functionlocal : return functionLocalOffsetCounter;
        default: assert(0);
    }
}

void incCurScopeOffset(){
    switch(getCurrentScopespace()){
        case programvar : ++programVarOffsetCounter;return;
        case formalarg : ++formalArgOffsetCounter;return;
        case functionlocal : ++functionLocalOffsetCounter;return;
        default : assert(0);
    }
} 

void enterScopespace(){
    ++scopeSpaceCounter;
}

void exitScopespace(){
    assert(scopeSpaceCounter>1);--scopeSpaceCounter;
}



class Variable {
    private:
        std::string name;
        unsigned int scope;
        unsigned int line;
    public:
        Variable(std::string _name, unsigned int _scope, unsigned int _line) {
            name = _name;
            scope = _scope;
            line = _line;
        }

        std::string getName() { return name; }
        unsigned int getScope() { return scope; }
        unsigned int getLine() { return line; }


};
class Function {
    private:
        std::string name;
        unsigned int scope;
        unsigned int line;

    public:
        Function(std::string _name, unsigned int _scope, unsigned int _line) {
            name = _name;
            scope = _scope;
            line = _line;
        }
        
        std::string getName() { return name; }
        unsigned int getScope() { return scope; }
        unsigned int getLine() { return line; }
};

//meant to be called from addToSymbolTableOnly
class SymbolTableEntry {

    private:
        bool enabled;
        union {
            Variable *varValue;
            Function *funcValue;
        } value;
        SymbolType type;
        symbol_t type_t;
        scopespace_t space;
        unsigned offset;
        int UnionFlag; //0 for variable , 1 for function

    public:
        SymbolTableEntry(std::string _name, int _scope, int _line, SymbolType _type,symbol_t _symtype) {
            if(_type == 3 || _type == 4) {
                Function *temp = new Function(_name, _scope, _line);
                value.funcValue=temp;
                UnionFlag = 1;
            } 
            else {
                Variable *temp = new Variable(_name, _scope, _line);
                value.varValue=temp;
                UnionFlag = 0;
            }
            enabled=true;
            type = _type;
            type_t = _symtype;
        }

        symbol_t getType_t(){return type_t;}
        scopespace_t getScopespace(){return space;}
        unsigned getOffset(){
            return offset;
        }

        std::string Type_t_toString(){//var_s,programfunc_s,libraryfunc_s
            if(type_t == var_s){return "var_s";}
            if(type_t == programfunc_s){return "programfunc_s";}
            if(type_t == libraryfunc_s){return "libraryfunc_s";}
            else{
                assert(0);
            }
            return "";
        }
        std::string Scopespace_toString(){ //programvar,functionlocal,formalarg
            switch (space)
            {
                case programvar:return"programvar";
                case functionlocal:return"functionlocal";
                case formalarg:return"formalarg";
                default:return"N/A";
            }
        }

        std::string getName(){ 
            if(type == 3 || type ==4){
                return value.funcValue->getName();
            }
            else{
                return value.varValue->getName();
            }
        }

        unsigned int getScope(){
            if(type == 3 || type ==4){
                return value.funcValue->getScope();
            }
            else{
                return value.varValue->getScope();
            }
        }

        unsigned int getLine(){
            if(type == 3 || type ==4){
                return value.funcValue->getLine();
            }
            else{
                return value.varValue->getLine();
            }
        }

        int getType(){
            return type;
        }

        bool isActive() { return enabled; }

        void activate() { enabled = true; }
        void deactivate() { enabled = false; }
        
        void setOffset(unsigned _offset){

            offset = _offset;
        }
        void setScopespace(scopespace_t _space){
            space = _space;
        }
};

