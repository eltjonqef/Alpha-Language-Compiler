#pragma once
#include <map>
using namespace std;
#include "Quads.hpp"
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

class incompleteJump{
    public:
        unsigned instructionNo;
        unsigned iaddress;
};
map<string, int> stringMap;
map<int, int> intMap;
map<double, int> doubleMap;
unsigned instructionLabel=0;
unsigned currentProssesedQuad = 0;

unsigned instructionLabelLookahead(){
    return instructionLabel;
}

unsigned getInstructionLabel(){
    unsigned holder = instructionLabel;
    instructionLabel++;
    return holder;
}

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
            break;
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

void make_retval_operand(vmarg* arg){
    arg->setType(ret_vm);
}
enum vmopcode_t{ 

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

class instruction{

    private:
        vmopcode_t opcode;
        vmarg *result;
        vmarg *arg1;
        vmarg *arg2;
        unsigned srcLine;
    public:
        instruction(){
            result=new vmarg();
            arg1=new vmarg();
            arg2=new vmarg();
        }
        void setOpCode(vmopcode_t _opcode){
            opcode=_opcode;
        }
        vmopcode_t getOP(){
            return opcode;
        }
        void setResult(vmarg *_result){
            result=_result;
        }
        vmarg *getResult(){
            return result;
        }
        vmarg *getArg1(){
            return arg1;
        }
        vmarg *getArg2(){
            return arg2;
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

vector<instruction*> instructionVector;

void generate_Simple(vmopcode_t op,quad quad){

    instruction *t=new instruction();
    t->setOpCode(op);
    make_operand(quad.getResult(), t->getResult());
    make_operand(quad.getArg1(), t->getArg1());
    make_operand(quad.getArg2(), t->getArg2());
    quad->setTaddress(instructionLabelLookahead());
    instructionVector.push_back(t);  
    //todo add emit
}

void generate_relational(vmopcode_t op,quad quad){
    instruction *t = new instruction();
    t->setOpCode(op);
    make_operand(quad.getArg1(),t->getArg1());
    make_operand(quad.getArg2(),t->getArg2());
    if(quad.getResult()<currentProssesedQuad){
        if((quad.getTaddress() == NULL)||(quad.getTaddress() < 0)){
            assert(0);
        }
        t->setResult(quad.getTaddress());
    }else{
        //todo add incomplete jump
    }
    quad->setTaddress(instructionLabelLookahead());
    instructionVector.push_back(t);
    //todo add emit
}

void generate_call(quad quad){
    quad.setTaddress(instructionLabelLookahead());
    instruction *t = new instruction();
    t->setOpCode(call_vm);
    make_operand(quad.getArg1(),t->getArg1());
    //todo add emit

}

void generate_retval(quad quad){
    quad.setTaddress(instructionLabelLookahead());
    instruction *t = new instruction();
    t->setOpCode(assign_vm);
    make_operand(quad.getResultt(),t->getResult());
    make_retval_operand(t->getArg1());
    //todo emit(t)
}

typedef void (*generator_func_t)(quad);

void generate_ASSIGN(quad quad){generate_Simple(assign_vm,quad);}
void generate_ADD(quad quad){generate_Simple(add_vm, quad);}
void generate_SUB(quad quad){generate_Simple(sub_vm,quad);}
void generate_MUL(quad quad){generate_Simple(mul_vm,quad);}
void generate_DIV(quad quad){generate_Simple(div_vm,quad);}
void generate_MOD(quad quad){generate_Simple(mod_vm, quad);}
void generate_UMINUS(quad quad){
    quad.setArg2(quad.getArg1());
    quad.setArg1(new expr(-1));
    quad.setOP(mul_op);
    generate_Simple(mul_vm, quad);
}

void generate_AND(quad quad){}
void generate_OR(quad quad){}
void generate_NOT(quad quad){}
void generate_IF_EQ(quad quad){generate_relational(if_eq_vm, quad);}
void generate_IF_NOTEQ(quad quad){generate_relational(if_noteq_vm, quad);}
void generate_IF_LESSEQ(quad quad){}
void generate_IF_GREATEREQ(quad quad){}
void generate_IF_LESS(quad quad){}
void generate_IF_GREATER(quad quad){}
void generate_CALL(quad quad){}
void generate_PARAM(quad quad){}
void generate_RET(quad quad){}
void generate_GETRETVAL(quad quad){}
void generate_FUNCSTART(quad quad){}
void generate_FUNCEND(quad quad){}
void generate_NEWTABLE(quad quad){generate_Simple(tablecreate_vm,quad);}
void generate_TABLEGETELEM(quad quad){generate_Simple(tablegetelem_vm,quad);}
void generate_TABLESETELEM(quad quad){generate_Simple(tablesetelem_vm,quad);}
void generate_JUMP(quad quad){}
void generate_NOP(quad quad){}//slide 18

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

void generate(){
    for(int i=0; i<quads.size(); i++){
        (*generators[quads[i].getOP()])(quads[i]);
    }
}

void printInstructions(){
    
    for(int i=0; i<instructionVector.size(); i++){
        switch(instructionVector[i]->getOP()){
            case assign_vm:{
                cout<<"ASSIGN"<<" "<<instructionVector[i]->getResult()->getVal()<<" "<<instructionVector[i]->getArg1()->getVal()<<" "<<instructionVector[i]->getArg2()->getVal()<<endl;
                break;
            }
            case add_vm:{
                cout<<"ADD"<<" "<<instructionVector[i]->getResult()->getVal()<<" "<<instructionVector[i]->getArg1()->getVal()<<" "<<instructionVector[i]->getArg2()->getVal()<<endl;
                break;
            }
        }
    }
}