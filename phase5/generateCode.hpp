#pragma once
#include <map>
using namespace std;
#include "Quads.hpp"
#include <stack>
#include <fstream>
int quadIndex=0;
vector<SymbolTableEntry*> functionVector;
map<string, int> libMap;
map<string, int> funcMap;
vector<map<string, int>> funcVectorMap;
int globalCounter=0;

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
    label_a,
    retval_a
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
        vmarg_t &getType(){return type;}
        unsigned &getVal(){return val;}        
};

class incompleteJump{
    public:
        unsigned instrNo;
        unsigned iaddress;
};
vector<incompleteJump*> incompleteJumps;
vector<incompleteJump*> incompleteIfJumps;
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
vector<string> stringVector;
vector<int> intVector;
vector<double> doubleVector;
unsigned consts_newString(string _string){

    if(!stringMap[_string]){
        stringMap[_string]=stringMap.size();
        stringVector.push_back(_string);
    }
    return stringMap[_string];

}
unsigned consts_newNumber(int _number){

    if(!intMap[_number]){
        intMap[_number]=intMap.size();
        intVector.push_back(_number);
    }
    return intMap[_number];
}

unsigned consts_newNumber(double _number){

    if(!doubleMap[_number]){
        doubleMap[_number]=doubleMap.size();
        doubleVector.push_back(_number);
    }
    return doubleMap[_number];
}

unsigned userfuncs_newfunc(SymbolTableEntry *sym){

}

unsigned libfuncs_newUsed(string _libfunc){

}

void make_operand(expr *e, vmarg *arg){
    if(e==NULL){
        arg=NULL;
        return;
    }
    switch(e->getType()){       
        case var_e:
        case tableitem_e:
        case arithexpr_e:
        case boolexpr_e:
        case assignexpr_e:
        case newtable_e: {
            arg->setVal(e->sym->getOffset());
            switch(e->sym->getScopespace()){
                case programvar:
                    globalCounter++;
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
            for(int i=0; i<functionVector.size(); i++){
                if(functionVector[i]->getName()==e->sym->getName() && functionVector[i]->getScope()==e->sym->getScope()){
                    arg->setVal(i);
                }
            }
            //arg->setVal(funcMap[e->sym->getName()]);
            break;
        }
        case libraryfunc_e:{
            arg->setType(libfunc_a);
            arg->setVal(libMap[e->sym->getName()]);
            break;
        }
        default:
            assert(0);
    }
}

void make_retval_operand(vmarg* arg){
    arg->setType(retval_a);
}
enum vmopcode_t{ 

    assign_vm,//
    add_vm,//
    sub_vm,//
    mul_vm,//
    div_vm,//
    mod_vm,//
    if_eq_vm,//
    if_noteq_vm,///
    if_lesseq_vm,///
    if_greatereq_vm,///
    if_less_vm,///
    if_greater_vm,///teq_vm
    call_vm,
    param_vm,
    ret_vm,
    getretval_vm,
    funcenter_vm,//
    funcexit_vm,//
    tablecreate_vm,//
    tablegetelem_vm,//
    tablesetelem_vm,//
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
        int index;
    public:
        instruction(){
            result=new vmarg();
            arg1=new vmarg();
            arg2=new vmarg();
            index=0;
        }
        void setOpCode(vmopcode_t _opcode){
            opcode=_opcode;
        }
        vmopcode_t& getOP(){
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

void generate_Simple(vmopcode_t op,quad *quad){

    instruction *t=new instruction();
    t->setOpCode(op);
   
    make_operand(quad->getResult(), t->getResult());
    make_operand(quad->getArg1(), t->getArg1());
    make_operand(quad->getArg2(), t->getArg2());
    quads[quad->getLabel()].setTaddress(instructionLabelLookahead());
    quad->setTaddress(getInstructionLabel());
    instructionVector.push_back(t);  
}

void generate_relational(vmopcode_t op,quad *quad){
    instruction *t = new instruction();
    t->setOpCode(op);
    t->getResult()->setType(label_a);
    if(op != jump_vm){
        make_operand(quad->getArg1(),t->getArg1());
        make_operand(quad->getArg2(),t->getArg2());
    }       
    t->getResult()->setVal(quad->getResult()->getJumpLab());
    //make_operand(quad->getResult(), t->getResult());
    /*if(quad->getResult()->getJumpLab()<currentProssesedQuad){
        if((quad->getTaddress() <= 0)){
            assert(0);
        }
        t->getResult()->setVal(quads[quad->getResult()->getJumpLab()].getTaddress());
    }else{
        incompleteJump *ij = new incompleteJump();
        ij->instrNo = instructionVector.size();
        ij->iaddress  = quad->getResult()->getJumpLab();
        incompleteJumps.push_back(ij);
    }*/
    //quads[quad->getLabel()].setTaddress(instructionLabelLookahead());
    //quad->setTaddress(getInstructionLabel());
    instructionVector.push_back(t);
}
     

void patch_incomplete_jumps(){
    for(vector<incompleteJump*>::iterator it = incompleteJumps.begin();it != incompleteJumps.end();++it){
        if((*it)->iaddress == quads.size()){
            instructionVector[(*it)->instrNo]->getResult()->setVal(currentProssesedQuad);
        }else{
            instructionVector[(*it)->instrNo]->getResult()->setVal(quads[(*it)->iaddress].getTaddress());
        }
    }
}


typedef void (*generator_func_t)(quad*);

void generate_ASSIGN(quad *quad){generate_Simple(assign_vm,quad);}
void generate_ADD(quad *quad){generate_Simple(add_vm, quad);}
void generate_SUB(quad *quad){generate_Simple(sub_vm,quad);}
void generate_MUL(quad *quad){generate_Simple(mul_vm,quad);}
void generate_DIV(quad *quad){generate_Simple(div_vm,quad);}
void generate_MOD(quad *quad){generate_Simple(mod_vm, quad);}
void generate_UMINUS(quad *quad){
    quad->setArg2(quad->getArg1());
    quad->setArg1(new expr(-1));
    quad->setOP(mul_op);
    generate_Simple(mul_vm, quad);
}

void generate_AND(quad *quad){}
void generate_OR(quad *quad){}
void generate_NOT(quad *quad){}
void generate_IF_EQ(quad *quad){generate_relational(if_eq_vm, quad);}
void generate_IF_NOTEQ(quad *quad){generate_relational(if_noteq_vm, quad);}
void generate_IF_LESSEQ(quad *quad){generate_relational(if_lesseq_vm, quad);}
void generate_IF_GREATEREQ(quad *quad){generate_relational(if_greatereq_vm, quad);}
void generate_IF_LESS(quad *quad){generate_relational(if_less_vm, quad);}
void generate_IF_GREATER(quad *quad){generate_relational(if_greater_vm, quad);}

void generate_CALL(quad *quad){
    quads[quad->getLabel()].setTaddress(instructionLabelLookahead());
    quad->setTaddress(getInstructionLabel());
    instruction *t = new instruction();
    t->setOpCode(call_vm);
    quads[quad->getLabel()].setTaddress(instructionLabelLookahead());
    quad->setTaddress(getInstructionLabel());
    make_operand(quad->getResult(),t->getResult());
    instructionVector.push_back(t);    
}

void generate_PARAM(quad *quad){
    quads[quad->getLabel()].setTaddress(instructionLabelLookahead());
    quad->setTaddress(getInstructionLabel());
    instruction *t=new instruction();
    t->setOpCode(param_vm);
    make_operand(quad->getResult(), t->getResult());
    instructionVector.push_back(t);
}
class function{
    public:
        SymbolTableEntry* sym;
        vector<unsigned> returnList;
};
stack<function*> functionStack;
void generate_RET(quad *quad){  
    quad->setTaddress(getInstructionLabel());
    instruction *t=new instruction();
    t->setOpCode(assign_vm);
    make_operand(quad->getResult(), t->getArg1());
    make_retval_operand(t->getResult());
    instructionVector.push_back(t);
    function *f=functionStack.top();
    f->returnList.push_back(currentProssesedQuad+1);
    /*instruction *jumpIns=new instruction();
    jumpIns->setOpCode(jump_vm);
    jumpIns->getResult()->setType(label_a);
    instructionVector.push_back(jumpIns);
    quadIndex++;
    currentProssesedQuad++;*/
}
void generate_GETRETVAL(quad *quad){
    quad->setTaddress(getInstructionLabel());
    instruction *t = new instruction();
    t->setOpCode(assign_vm);
    make_operand(quad->getResult(),t->getResult());
    make_retval_operand(t->getArg1());
    instructionVector.push_back(t);
}


void generate_FUNCSTART(quad *quad){
    SymbolTableEntry* f=quad->getResult()->sym;
    //funcMap[quad->getResult()->sym->getName()]=functionVector.size();
    //f->setTaddress(functionVector.size());
    f->setinID(instructionVector.size());
    functionVector.push_back(f);
    quad->setTaddress(getInstructionLabel());
    function *aa=new function();
    aa->sym=f;
    functionStack.push(aa);
    instruction *t=new instruction();
    t->setOpCode(funcenter_vm);
    make_operand(quad->getResult(), t->getResult());
    instructionVector.push_back(t);
}

void backpatch_lastfunc(function *f, unsigned target){
    for(int index=0; index<(f->returnList.size());index++){
        instructionVector[f->returnList[index]]->getResult()->setVal(target);
    }
}

void generate_FUNCEND(quad *quad){
    function *f=functionStack.top();
    backpatch_lastfunc(f, currentProssesedQuad);
    //funcendVec.push_back(currentProssesedQuad);
    functionStack.pop();
    //to do BACKpatch returnList
    //f->getReturnList();
    quad->setTaddress(getInstructionLabel());
    instruction *t=new instruction();
    t->setOpCode(funcexit_vm);
    make_operand(quad->getResult(), t->getResult());
    instructionVector.push_back(t);
}
void generate_NEWTABLE(quad *quad){generate_Simple(tablecreate_vm,quad);}
void generate_TABLEGETELEM(quad *quad){generate_Simple(tablegetelem_vm,quad);}
void generate_TABLESETELEM(quad *quad){generate_Simple(tablesetelem_vm,quad);}
void generate_JUMP(quad *quad){
    generate_relational(jump_vm,quad);
}
void generate_NOP(quad *quad){
    quad->setTaddress(getInstructionLabel());
    instruction *t = new instruction();
    t->setOpCode(nop_vm);
    instructionVector.push_back(t);
}

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
    for(quadIndex=0; quadIndex<quads.size(); quadIndex++){
        (*generators[quads[quadIndex].getOP()])(&quads[quadIndex]);
        currentProssesedQuad++;
    }
    patch_incomplete_jumps();
}
string opcodeToString(vmopcode_t _opcode){

    vmopcode_t temp=_opcode;
    switch(temp){
        case assign_vm: return "ASSIGN";
        case add_vm: return "ADD";
        case sub_vm: return "SUB";
        case mul_vm: return "MUL";
        case div_vm: return "DIV";
        case mod_vm: return "MOD";
        case if_eq_vm: return "IFEQ";
        case if_noteq_vm: return "IFNEQ";
        case if_lesseq_vm: return "IFLESSEQ";
        case if_greatereq_vm: return "IFGREATEREQ";
        case if_less_vm: return "IFLESS";
        case if_greater_vm: return "IFGREATER";
        case call_vm: return "CALL";
        case param_vm: return "PARAM";
        case ret_vm: return "RETURN";
        case getretval_vm: return "GETRETVAL";
        case funcenter_vm: return "FUNCENTER";
        case funcexit_vm: return "FUNCEXIT";
        case tablecreate_vm: return "CREATETABLE";
        case tablegetelem_vm: return "TABLEGETELEM";
        case tablesetelem_vm: return "TABLESETELEM";
        case jump_vm: return "JUMP";
        case nop_vm: return "";
    }        
}
string vmarg_tToString(vmarg_t type){

    vmarg_t temp=type;
    switch(temp){
        case global_a: return "GLOBAL";
        case local_a: return "LOCAL";
        case formal_a: return "FORMAL";
        case bool_a: return "BOOL";
        case string_a: return "STRING";
        case int_a: return "INT";
        case double_a: return "DOUBLE";
        case nil_a: return "NIL";
        case userfunc_a: return "USERFUNC";
        case libfunc_a: return "LIBFUNC";
        case retval_a: return "RETVAL";
        case label_a: return "LABEL";
    }
}
void printInstructions(){
    ofstream fs;
    fs.open("./instructions.txt");
    fs<<"-------------Functions---------------\n";
    for(int i=0; i<functionVector.size(); i++){
        fs<<i<<" "<<functionVector[i]->getName()<<" "<<functionVector[i]->getScope()<<endl;
    }
    fs<<"--------------Int Map----------------\n";
    for(int i=0; i<intVector.size(); i++){
        fs<<intVector[i]<<endl;
    }
    fs<<"-------------Double Map--------------\n";
    for(int i=0; i<doubleVector.size(); i++){
        fs<<doubleVector[i]<<endl;
    }
    fs<<"-------------String Map--------------\n";
    for(int i=0; i<stringVector.size(); i++){
        fs<<stringVector[i]<<endl;
    }
    fs<<"------------Instructions-------------\n";
    for(int i=1; i<instructionVector.size(); i++){
        fs<<i<<": "<<opcodeToString(instructionVector[i]->getOP());
        switch(instructionVector[i]->getOP()){
            case assign_vm:{
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getResult()->getType())<<")"<<instructionVector[i]->getResult()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg1()->getType())<<")"<<instructionVector[i]->getArg1()->getVal();
                fs<<endl;
                break;
            }
            case add_vm:{
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getResult()->getType())<<")"<<instructionVector[i]->getResult()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg1()->getType())<<")"<<instructionVector[i]->getArg1()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg2()->getType())<<")"<<instructionVector[i]->getArg2()->getVal();
                fs<<endl;
                break;
            }
            case sub_vm:{
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getResult()->getType())<<")"<<instructionVector[i]->getResult()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg1()->getType())<<")"<<instructionVector[i]->getArg1()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg2()->getType())<<")"<<instructionVector[i]->getArg2()->getVal();
                fs<<endl;
                break;
            }
            case mul_vm:{
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getResult()->getType())<<")"<<instructionVector[i]->getResult()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg1()->getType())<<")"<<instructionVector[i]->getArg1()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg2()->getType())<<")"<<instructionVector[i]->getArg2()->getVal();
                fs<<endl;
                break;
            }
            case div_vm:{
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getResult()->getType())<<")"<<instructionVector[i]->getResult()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg1()->getType())<<")"<<instructionVector[i]->getArg1()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg2()->getType())<<")"<<instructionVector[i]->getArg2()->getVal();
                fs<<endl;
                break;
            }
            case mod_vm:{
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getResult()->getType())<<")"<<instructionVector[i]->getResult()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg1()->getType())<<")"<<instructionVector[i]->getArg1()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg2()->getType())<<")"<<instructionVector[i]->getArg2()->getVal();
                fs<<endl;
                break;
            }
            case tablesetelem_vm:{
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getResult()->getType())<<")"<<instructionVector[i]->getResult()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg1()->getType())<<")"<<instructionVector[i]->getArg1()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg2()->getType())<<")"<<instructionVector[i]->getArg2()->getVal();
                fs<<endl;
                break;
            }
            case tablegetelem_vm:{
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getResult()->getType())<<")"<<instructionVector[i]->getResult()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg1()->getType())<<")"<<instructionVector[i]->getArg1()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg2()->getType())<<")"<<instructionVector[i]->getArg2()->getVal();
                fs<<endl;
                break;
            }
            case call_vm:{
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getResult()->getType())<<")"<<instructionVector[i]->getResult()->getVal();
                fs<<endl;
                break;
            }
            case param_vm:{
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getResult()->getType())<<")"<<instructionVector[i]->getResult()->getVal();
                fs<<endl;
                break;
            }
            case if_eq_vm:{
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getResult()->getType())<<")"<<instructionVector[i]->getResult()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg1()->getType())<<")"<<instructionVector[i]->getArg1()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg2()->getType())<<")"<<instructionVector[i]->getArg2()->getVal();
                fs<<endl;
                break;
            }
            case if_greatereq_vm:{
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getResult()->getType())<<")"<<instructionVector[i]->getResult()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg1()->getType())<<")"<<instructionVector[i]->getArg1()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg2()->getType())<<")"<<instructionVector[i]->getArg2()->getVal();
                fs<<endl;
                break;
            }
            case if_noteq_vm:{
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getResult()->getType())<<")"<<instructionVector[i]->getResult()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg1()->getType())<<")"<<instructionVector[i]->getArg1()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg2()->getType())<<")"<<instructionVector[i]->getArg2()->getVal();
                fs<<endl;
                break;
            }
            case if_lesseq_vm:{
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getResult()->getType())<<")"<<instructionVector[i]->getResult()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg1()->getType())<<")"<<instructionVector[i]->getArg1()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg2()->getType())<<")"<<instructionVector[i]->getArg2()->getVal();
                fs<<endl;
                break;
            }
            case if_greater_vm:{
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getResult()->getType())<<")"<<instructionVector[i]->getResult()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg1()->getType())<<")"<<instructionVector[i]->getArg1()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg2()->getType())<<")"<<instructionVector[i]->getArg2()->getVal();
                fs<<endl;
                break;
            }
            case if_less_vm:{
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getResult()->getType())<<")"<<instructionVector[i]->getResult()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg1()->getType())<<")"<<instructionVector[i]->getArg1()->getVal();
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getArg2()->getType())<<")"<<instructionVector[i]->getArg2()->getVal();
                fs<<endl;
                break;
            }
            case jump_vm:{
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getResult()->getType())<<")"<<instructionVector[i]->getResult()->getVal();
                fs<<endl;
                break;
            }
            case tablecreate_vm:{
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getResult()->getType())<<")"<<instructionVector[i]->getResult()->getVal();
                fs<<endl;
                break;
            }
            case funcenter_vm:{
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getResult()->getType())<<")"<<instructionVector[i]->getResult()->getVal();
                fs<<endl;
                break;
            }
            case funcexit_vm:{
                fs<<" ("<<vmarg_tToString(instructionVector[i]->getResult()->getType())<<")"<<instructionVector[i]->getResult()->getVal();
                fs<<endl;
                break;
            }
        }
    }
    fs.close();
}

void writeBinary(){
    FILE *f;
    f=fopen("binary.abc", "wb");
    int magicNumber=4567978;
    fwrite(&magicNumber, sizeof(int), 1, f);
    int loop;
    size_t len;
    loop=functionVector.size();
    fwrite(&loop, sizeof(int), 1, f);
    for(int i=0; i<functionVector.size(); i++){
        fwrite(&functionVector[i]->getinID(), sizeof(unsigned), 1, f);
        fwrite(&functionVector[i]->getTotalFormalArgumentsOffset(), sizeof(unsigned), 1, f);
        fwrite(&functionVector[i]->getTotalLocalVariablesOffset(), sizeof(unsigned), 1,f);
        len=functionVector[i]->getName().length();
        fwrite(&len, sizeof(size_t), 1, f);
        char *ctext=const_cast<char*>(functionVector[i]->getName().c_str());
        fwrite(ctext, sizeof(char), len, f);
    }
    loop=intVector.size();
    fwrite(&loop, sizeof(int), 1, f);
    for(int i=0; i<intVector.size(); i++){
        fwrite(&intVector[i],sizeof(int), 1, f);
    }
    loop=doubleVector.size();
    fwrite(&loop, sizeof(int), 1, f);
    for(int i=0; i<doubleVector.size(); i++){
        fwrite(&doubleVector[i],sizeof(double), 1, f);
    }
    loop=stringVector.size();
    fwrite(&loop, sizeof(int), 1, f);
    for(int i=0; i<stringVector.size(); i++){
        len=stringVector[i].length();
        fwrite(&len, sizeof(size_t), 1, f);
        char *ctext=const_cast<char*>(stringVector[i].c_str());
        fwrite(ctext, sizeof(char), len, f);
    }
    fwrite(&globalCounter, sizeof(int), 1,f);
    loop=instructionVector.size()-1;
    fwrite(&loop, sizeof(int), 1, f);
    for(int i=1; i<instructionVector.size(); i++){
        fwrite(&(instructionVector[i]->getOP()), sizeof(int), 1, f);
        switch(instructionVector[i]->getOP()){
            case assign_vm:{
                fwrite(&(instructionVector[i]->getResult()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getResult()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getVal()), sizeof(int), 1, f);
                break;
            }
            case add_vm:{
                fwrite(&(instructionVector[i]->getResult()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getResult()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getVal()), sizeof(int), 1, f);
                break;
            }
            case sub_vm:{
                fwrite(&(instructionVector[i]->getResult()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getResult()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getVal()), sizeof(int), 1, f);
                break;
            }
            case mul_vm:{
                fwrite(&(instructionVector[i]->getResult()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getResult()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getVal()), sizeof(int), 1, f);
                break;
            }
            case div_vm:{
                fwrite(&(instructionVector[i]->getResult()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getResult()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getVal()), sizeof(int), 1, f);
                break;
            }
            case mod_vm:{
                fwrite(&(instructionVector[i]->getResult()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getResult()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getVal()), sizeof(int), 1, f);
                break;
            }
            case tablesetelem_vm:{
                fwrite(&(instructionVector[i]->getResult()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getResult()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getVal()), sizeof(int), 1, f);
                break;
            }
            case tablegetelem_vm:{
                fwrite(&(instructionVector[i]->getResult()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getResult()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getVal()), sizeof(int), 1, f);
                break;
            }
            case call_vm:{
                fwrite(&(instructionVector[i]->getResult()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getResult()->getVal()), sizeof(int), 1, f);
                break;
            }
            case param_vm:{
                fwrite(&(instructionVector[i]->getResult()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getResult()->getVal()), sizeof(int), 1, f);
                break;
            }
            case if_eq_vm:{
                fwrite(&(instructionVector[i]->getResult()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getResult()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getVal()), sizeof(int), 1, f);
                break;
            }
            case if_noteq_vm:{
                fwrite(&(instructionVector[i]->getResult()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getResult()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getVal()), sizeof(int), 1, f);
                break;
            }
            case if_lesseq_vm:{
                fwrite(&(instructionVector[i]->getResult()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getResult()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getVal()), sizeof(int), 1, f);
                break;
            }
            case if_greatereq_vm:{
                fwrite(&(instructionVector[i]->getResult()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getResult()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getVal()), sizeof(int), 1, f);
                break;
            }
            case if_less_vm:{
                fwrite(&(instructionVector[i]->getResult()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getResult()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getVal()), sizeof(int), 1, f);
                break;
            }
            case if_greater_vm:{
                fwrite(&(instructionVector[i]->getResult()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getResult()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg1()->getVal()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getArg2()->getVal()), sizeof(int), 1, f);
                break;
            }
            case jump_vm:{
                fwrite(&(instructionVector[i]->getResult()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getResult()->getVal()), sizeof(int), 1, f);
                break;
            }
            case tablecreate_vm:{
                fwrite(&(instructionVector[i]->getResult()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getResult()->getVal()), sizeof(int), 1, f);
                break;
            }
            case funcenter_vm:{
                fwrite(&(instructionVector[i]->getResult()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getResult()->getVal()), sizeof(int), 1, f);
                break;
            }
            case funcexit_vm:{
                fwrite(&(instructionVector[i]->getResult()->getType()), sizeof(int), 1, f);
                fwrite(&(instructionVector[i]->getResult()->getVal()), sizeof(int), 1, f);
                break;
            }
        }
    }
    fclose(f);
}