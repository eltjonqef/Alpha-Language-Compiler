#include <string>

enum SymbolType {
    GLOB,
    LOCL,
    FORMAL,
    USERFUNC, 
    LIBFUNC  
};

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
