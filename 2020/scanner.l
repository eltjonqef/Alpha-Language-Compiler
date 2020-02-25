%{
    #include <string>
    #include <stdlib.h>
    #include <string.h>
    #include <iostream>
    #include <vector>
    
    #ifdef _cplusplus
        static int yyinput(void);
    #else
        static int input(void);
    #endif

    typedef struct alpha_token_t {
        unsigned int     numline;
        unsigned int     numToken;
        std::string      content;
        std::string      category;
        std::string      formalContent;
        std::string      tokenType;
    } alpha_tok;
    
    #define YY_DECL int alpha_yylex(void* yylval)

    int tokenCounter = 0;

    std::vector<alpha_tok> alpha_token_list;
    
%}

%option header-file = "./scanner.h"
%option yylineno
%option noyywrap

KEYWORD ("if")|("else")|("while")|("for")|("function")|("return")|("break")|("continue")|("and")|("not")|("or")|("local")|("true")|("false")|("nil")

OPERATOR ("=")|("+")|("-")|("*")|("/")|("%")|("==")|("!=")|("++")|("--")|(">")|("<")|(">=")|("<=")

INTCONST [0-9]+

DOUBLECONST [0-9]+\.[0-9]+

PUNMRKS (";")|(",")|(":")|("::")|(".")|("..")|("{")|("}")|("[")|("]")|("(")|(")")

IDENT [a-zA-Z][a-zA-Z_0-9]*

WHITESPACE [ \n\t\r]+

SCOMMENT "//".*

MCOMMENT "/*"

UNDEFINEDCHAR ("$")|("_d")|("~")|("?")|("#")|("&&")|("||")|("!")

%%

{KEYWORD} {
    alpha_tok temp;
    temp.numline = yylineno;
    temp.numToken = ++tokenCounter;
    temp.content = yytext;
    temp.category = "KEYWORD";
    std::string yytextTemp=yytext;
    temp.formalContent="";
    for(int i=0; i<yytextTemp.size(); i++){
        temp.formalContent+=toupper(yytext[i]);
    }
    temp.tokenType = "enumerated";
    alpha_token_list.push_back(temp);
}

{OPERATOR} {
    alpha_tok temp;
    temp.numline = yylineno;
    temp.numToken = ++tokenCounter;
    temp.content = yytext;
    temp.category = "OPERATOR";
    temp.tokenType = "enumerated";
    alpha_token_list.push_back(temp);
}

{INTCONST} {
    alpha_tok temp;
    temp.numline = yylineno;
    temp.numToken = ++tokenCounter;
    temp.content = yytext;
    temp.category = "INTCONST";
    temp.formalContent=yytext;
    temp.tokenType = "int";
    alpha_token_list.push_back(temp);
}

{DOUBLECONST} {
    alpha_tok temp;
    temp.numline = yylineno;
    temp.numToken = ++tokenCounter;
    temp.content = yytext;
    temp.category = "DOUBLECONST";
    temp.formalContent=yytext;
    temp.tokenType = "double";
    alpha_token_list.push_back(temp);
}

{PUNMRKS} {
    alpha_tok temp;
    temp.numline = yylineno;
    temp.numToken = ++tokenCounter;
    temp.content = yytext;
    temp.category = "PUNMRKS";
    temp.formalContent=yytext;
    temp.tokenType = "enumerated";
    alpha_token_list.push_back(temp);
}

{IDENT} {
    alpha_tok temp;
    temp.numline = yylineno;
    temp.numToken = ++tokenCounter;
    temp.content = yytext;
    temp.category = "IDENT";
    temp.formalContent="\"";
    temp.formalContent+=yytext;
    temp.formalContent+="\"";
    temp.tokenType = "char*";
    alpha_token_list.push_back(temp);
}

{SCOMMENT} {
    alpha_tok temp;
    temp.numline = yylineno;
    temp.numToken = ++tokenCounter;
    temp.content = yytext;
    temp.category = "SCOMMENT";
    temp.formalContent="LINE_COMMENT";
    temp.tokenType = "enumerated";
    alpha_token_list.push_back(temp);
}

\" {
    std::string tmp = "";
    char hia;

    while ((hia = yyinput())){
        if (hia == '\"') break;

        else if (hia == EOF) {
            fprintf(stderr, "Unclosed string in line %d\n", yylineno);
            return -1;
        }
        else if (hia != '\\' && hia != '\"') tmp += hia;
        
        else if (hia == '\\') {
            hia = yyinput();
            switch(hia){
                case 'n' : 
                    tmp += '\n';
                    break;
                case 't' : 
                    tmp += '\t';
                    break;
                case 'r' : 
                    tmp += '\r';
                    break;
                case 'b' : 
                    tmp += '\b';
                    break;
                case '\\' : 
                    tmp += '\\';
                    break;
                case '\"' : 
                    tmp += '\"';
                    break;
                default : 
                    fprintf(stderr, "error in line %d\n", yylineno);
                    return -1;
            }
        }
    }
    alpha_tok temp;
    temp.numline = yylineno;
    temp.numToken = ++tokenCounter;
    temp.content = tmp.c_str();
    temp.category = "STRING";
    temp.formalContent=tmp.c_str();
    temp.tokenType = "char*";
    alpha_token_list.push_back(temp);
}

{MCOMMENT} {
    char parse;
    int state = 0; // 0 = normal,1 = read "/",2 = read "*"
    int commentCounter=0;
    int tempCounter = 0;
    int errorFlag = 0;
    int startingLine=yylineno;
    while((parse=yyinput())){
        if( parse == '*'){
            if(state == 1){
                //opens new comment
                tempCounter++;
                commentCounter++;
                state = 0;
            }else{
                state = 2;
            }
        }
        else if(parse == '/'){
            if((state == 0 ) || (state == 1)){
                state = 1;
            }else if(state == 2){
                //closes comment
                if(tempCounter == 0){
                    break;
                }
                tempCounter--;
                state = 0;
            }
        }else{
            state = 0;
        }
        if(parse == EOF){
            errorFlag = 1;
            break;
        }
    }
    if(errorFlag){
        printf("this is an error message\n");
        
    }else if(commentCounter == 0){
        printf("Simple multiline comment at line %d\n", startingLine);
    }else{
        printf("Nested multiline comment %d (in total,not depth) at line %d\n",commentCounter, startingLine);
    }
    
}

{UNDEFINEDCHAR} {
    std::cout<<"Undefined character "<<yytext<<" at line "<<yylineno<<std::endl;
}
{WHITESPACE} {}

<<EOF>> {return 0;}

%%

int main(int argc, char** argv){
        
    if (argc > 1){
        if(!(yyin = fopen(argv[1], "r"))){
            fprintf(stderr, "Cannot read file: %s\n", argv[1]);
            return 1;
        }
    }
    else
        yyin = stdin;

    alpha_yylex(NULL);

    for(int i = 0; i < alpha_token_list.size(); i++) {
        std::cout << alpha_token_list[i].numline << ": #"
        << alpha_token_list[i].numToken << " \""
        << alpha_token_list[i].content << "\" "
        << alpha_token_list[i].category << " "
        << alpha_token_list[i].formalContent <<" <-"
        << alpha_token_list[i].tokenType <<std::endl;
    }

    return 0;
}