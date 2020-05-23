#include <map>
using namespace std;

enum vmarg_t{

    global_a,
    local_a,
    formal_a,
    bool_a,
    string_a,
    int_a,
    double_a,
    nil_a,
    userfunc_a,
    libfunc_a,
};

class vmarg{

    private:
        vmarg_t type;
        unsigned val;
    public:
        vmarg(){}
        void setType(vmarg_t _type){
            type=_type;
        }
        void setVal(unsigned _val){
            val=_val;
        }
        vmarg_t getType(){return type;}
        unsigned getVal(){return val;}        
};

map<string, int> stringMap;
map<int, int> intMap;
map<double, int> doubleMap;

unsigned consts_newString(string _string){

    if(!stringMap[_string])
        stringMap[_string]=stringMap.size();
    
    return stringMap[_string];

}
unsigned consts_newNumber(int _number){

    if(!intMap[_number])
        intMap[_number]=intMap.size();
    
    return intMap[_number];
}

unsigned consts_newNumber(double _number){

    if(!doubleMap[_number])
        doubleMap[_number]=doubleMap.size();
    
    return doubleMap[_number];
}

unsigned libfuncs_newUsed(string _libfunc){

}

void make_operand(expr *e, vmarg *arg){

    switch(e->getType()){
        
        case var_e:
        case tableitem_e:
        case arithexpr_e:
        case boolexpr_e:
        case newtable_e: {
            arg->setVal(e->sym->getOffset());
            switch(e->sym->getScopespace()){
                case programvar: 
                    arg->setType(global_a);
                    break;
                case functionlocal:
                    arg->setType(local_a);
                    break;
                case formalarg:
                    arg->setType(formal_a);
                    break;
                default:
                    assert(0);
            }
        }
        case constbool_e:{
            arg->setVal(e->getBoolConst());
            arg->setType(bool_a);
            break;
        }
        case conststring_e:{
            arg->setVal(consts_newString(e->getStringConst()));
            arg->setType(string_a);
            break;
        }
        case constnumInt_e:{
            arg->setVal(consts_newNumber(e->getIntConst()));
            arg->setType(int_a);
            break;
        }
        case constnumDouble_e:{
            arg->setVal(consts_newNumber(e->getDoubleConst()));
            arg->setType(double_a);
            break;
        }
        case nil_e:{
            arg->setType(nil_a);
            break;
        }
        case programfunc_e:{
            arg->setType(userfunc_a);
            //arg->setVal(e->sym->taddress); DEN EXW TIN PARAMIKRI IDEA TI EINAI TO TADDRESS
            break;
        }
        case libraryfunc_e:{
            arg->setType(libfunc_a);
            arg->setVal(libfuncs_newUsed(e->sym->getName()));
            break;
        }
        default:
            assert(0);
    }
}

enum vmopcode{ 

    assign_vm,
    add_vm,
    sub_vm,
    mul_vm,
    div_vm,
    mod_vm,
    if_eq_vm,
    if_noteq_vm,
    if_lesseq_vm,
    if_greatereq_vm,
    if_less_vm,
    if_greater_vm,
    call_vm,
    param_vm,
    ret_vm,
    getretval_vm,
    funcenter_vm,
    funcexit_vm,
    tablecreate_vm,
    tablegetelem_vm,
    tablesetelem_vm,
    jump_vm,
    nop_vm
};


void generate(vmopcode opcode, quad *_quad){
    cout<<"\n";
}

typedef void (*generator_func_t)(quad*);

void generate_ASSIGN(quad *quad){}
void generate_ADD(quad *quad){}
void generate_SUB(quad *quad){}
void generate_MUL(quad *quad){}
void generate_DIV(quad *quad){}
void generate_MOD(quad *quad){}
void generate_UMINUS(quad *quad){}
void generate_AND(quad *quad){}
void generate_OR(quad *quad){}
void generate_NOT(quad *quad){}
void generate_IF_EQ(quad *quad){}
void generate_IF_NOTEQ(quad *quad){}
void generate_IF_LESSEQ(quad *quad){}
void generate_IF_GREATEREQ(quad *quad){}
void generate_IF_LESS(quad *quad){}
void generate_IF_GREATER(quad *quad){}
void generate_CALL(quad *quad){}
void generate_PARAM(quad *quad){}
void generate_RET(quad *quad){}
void generate_GETRETVAL(quad *quad){}
void generate_FUNCSTART(quad *quad){}
void generate_FUNCEND(quad *quad){}
void generate_NEWTABLE(quad *quad){}
void generate_TABLEGETELEM(quad *quad){}
void generate_TABLESETELEM(quad *quad){}
void generate_JUMP(quad *quad){}
void generate_NOP(quad *quad){}

generator_func_t generators[]={
    
    generate_ASSIGN,
    generate_ADD,
    generate_SUB,
    generate_MUL,
    generate_DIV,
    generate_MOD,
    generate_UMINUS,
    generate_AND,
    generate_OR,
    generate_NOT,
    generate_IF_EQ,
    generate_IF_NOTEQ,
    generate_IF_LESSEQ,
    generate_IF_GREATEREQ,
    generate_IF_LESS,
    generate_IF_GREATER,
    generate_CALL,
    generate_PARAM,
    generate_RET,
    generate_GETRETVAL,
    generate_FUNCSTART,
    generate_FUNCEND,
    generate_NEWTABLE,
    generate_TABLEGETELEM,
    generate_TABLESETELEM,
    generate_JUMP,
    generate_NOP
};


class instruction{

    private:
        vmopcode opcode;
        vmarg *result;
        vmarg *arg1;
        vmarg *arg2;
        unsigned srcLine;
    public:
        instruction(){}
        void setResult(vmarg *_result){
            result=_result;
        }
        void setArg1(vmarg *_arg1){
            arg1=_arg1;
        }
        void setArg2(vmarg *_arg2){
            arg2=_arg2;
        }
        void setSrcLine(unsigned _srcLine){
            srcLine=_srcLine;
        }
};