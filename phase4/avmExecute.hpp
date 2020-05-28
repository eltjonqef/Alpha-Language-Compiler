#pragma once

#include "generateCode.hpp"
#include "avm_workings.hpp"

void execute_assign(instruction *t){

    avm_memcell *lv=avm_translate_operand(t->getResult(), NULL);
    avm_memcell *rv=avm_translate_operand(t->getArg1(), ax);

    //mia poutsoassert exei edw
    assert(rv);
    avm_assign(lv, rv);
}

void avm_assign(avm_memcell *lv, avm_memcell *rv){

    if(lv==rv)
        return;
    if(lv->type==table_m && rv->type==table_m && lv->data.tableVal==rv->data.tableVal)
        return;
    if(lv->type==undef_m)
        cout<<"ASSIGNING FROM UNDEF CONTENT"<<endl; //TO THELEI ME WARNIGN SUNARTISI
    
    //avm_memcellclear(lv);  NOT IMPLEMENTED YET

    memcpy(lv, rv, sizeof(avm_memcell));

    if(lv->type==string_m)
        lv->data.strVal=strdup(rv->data.strVal);
    else if(lv->type==table_m)
        cout<<"NOT IMPLEMENTED YET\n"; //avm_tableIncrefCounter(lv->data.tableVal);

}