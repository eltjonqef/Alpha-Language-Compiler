#include <string>
#include <stack>
#include <assert.h>
enum SymbolType {
    GLOB,
    LOCL,
    FORMAL,
    USERFUNC, 
    LIBFUNC  
};

enum scopespace_t{
    programvar,functionlocal,formalarg
}
enum symbol_t {var_s,programfunc_s,libraryfunc_s};


unsigned programVarOffsetCounter = 0;
unsigned functionLocalOffsetCounter = 0;
unsigned formalArgOffsetCounter = 0;
int scopeSpaceCounter = 1;
stack<unsigned> functionOffsets;


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
        return functionOffsets.pop();
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



unsinged currentOffset({
    switch(getCurrentScopespace()) {
        case programvar : return programVarOffsetCounter;
        case formalarg : return formalArgOffsetCounter;
        case functionlocal : return functionLocalOffsetCounter;
        default: assert(0);
    }
})

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
        symbol_t type;
        scopespace_t space;
        unsigned offset;
    public:
        Variable(std::string _name, unsigned int _scope, unsigned int _line,symbol_t _type,scopespace_t _space,unsigned _offset) {
            name = _name;
            scope = _scope;
            line = _line;
            type = _type;
            space = _space;
            offset = _offset;
        }

        std::string getName() { return name; }
        unsigned int getScope() { return scope; }
        unsigned int getLine() { return line; }
        symbol_t getType() {return type;}
        scopespace_t getScopespace {return space;}
        unsigned getOffset() {return offset;}
};

class Function {
    private:
        std::string name;
        unsigned int scope;
        unsigned int line;
        symbol_t type;

    public:
        Function(std::string _name, unsigned int _scope, unsigned int _line,symbol_t _type) {
            name = _name;
            scope = _scope;
            line = _line;
            type = _type;

        }
        
        std::string getName() { return name; }
        unsigned int getScope() { return scope; }
        unsigned int getLine() { return line; }
        symbol_t getType() {return type;}
        scopespace_t getScopespace {return space;}
        unsigned getOffset() {return offset;}
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

    public:
        SymbolTableEntry(std::string _name, int _scope, int _line, SymbolType _type) {
            if(_type == 3 || _type == 4) {
                Function *temp = new Function(_name, _scope, _line);
                value.funcValue=temp;
            } 
            else {
                Variable *temp = new Variable(_name, _scope, _line);
                value.varValue=temp;
            }
            enabled=true;
            type = _type;
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
        
        
};
