%{
    #include "parser.hpp"
    #include <string>
    #include <stdlib.h>
    #include <string>
    #include <iostream>
    #include <vector>
    #include <map>
    
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
    
    #define YY_DECL int yylex()

    int tokenCounter = 0;

    std::vector<alpha_tok> alpha_token_list;

    std::map<std::string, int> enumMap;

    void initEnumMap(){
        enumMap["="] = ASSIGN;
        enumMap["+"] = PLUS;
        enumMap["-"] = MINUS;
        enumMap["*"] = MULTIPLY;
        enumMap["/"] = DIVIDE;
        enumMap["%"] = MOD;
        enumMap["=="]= EQUAL;
        enumMap["!="]= NOT_EQUAL;
        enumMap["++"]= PLUS_PLUS;
        enumMap["--"]= MINUS_MINUS;
        enumMap[">"] = GREATER;
        enumMap["<"] = LESS;
        enumMap[">="]= GREATER_EQUAL;
        enumMap["<="]= LESS_EQUAL;

        enumMap["if"] = IF;
        enumMap["else"] = ELSE;
        enumMap["while"] = WHILE;
        enumMap["for"] = FOR;
        enumMap["function"] = FUNCTION;
        enumMap["return"] = RETURN;
        enumMap["break"] = BREAK;
        enumMap["continue"] = CONTINUE;
        enumMap["and"] = AND;
        enumMap["not"] = NOT;
        enumMap["or"] = OR;
        enumMap["local"] = LOCAL;
        enumMap["true"] = TRUE;
        enumMap["false"] = FALSE;
        enumMap["nil"] = NIL;

        enumMap[";"] = SEMICOLON;
        enumMap[","] = COMMA;
        enumMap[":"] = COLON;
        enumMap["::"] = COLON_COLON;
        enumMap["."] = DOT;
        enumMap[".."] = DOT_DOT;
        enumMap["{"] = LEFT_BRACE;
        enumMap["}"] = RIGHT_BRACE;
        enumMap["["] = LEFT_BRACKET;
        enumMap["]"] = RIGHT_BRACKET;
        enumMap["("] = LEFT_PARENTHESIS;
        enumMap[")"] = RIGHT_PARENTHESIS;
    }
%}

%option header-file = "./scanner.h"
%option yylineno
%option noyywrap

KEYWORD ("if")|("else")|("while")|("for")|("function")|("return")|("break")|("continue")|("and")|("not")|("or")|("local")|("true")|("false")|("nil")

OPERATOR ("=")|("+")|("-")|("*")|("/")|("%")|("==")|("!=")|("++")|("--")|(">")|("<")|(">=")|("<=")

INTCONST [0-9]+

DOUBLECONST [0-9]+\.[0-9]+

PUNMARKS (";")|(",")|(":")|("::")|(".")|("..")|("{")|("}")|("[")|("]")|("(")|(")")

IDENT [a-zA-Z][a-zA-Z_0-9]*

WHITESPACE [ \n\t\r]+

SCOMMENT "//".*

MCOMMENT "/*"

UNDEFINEDCHAR ("$")|("_d")|("~")|("?")|("#")|("&&")|("||")|("!")

%%

{KEYWORD} { return enumMap[yytext]; }

{OPERATOR} { return enumMap[yytext]; }

{INTCONST} {
    yylval.intValue=atoi(yytext);
    return INTCONST; 
}

{DOUBLECONST} { 
    yylval.doubleValue=atof(yytext);
    return DOUBLECONST; 
}

{PUNMARKS} { return enumMap[yytext]; }

{IDENT} { 
    yylval.stringValue=yytext;
    return IDENT;
}

{SCOMMENT} { int rewrwer =2;}

\" {
    std::string tmp = "";
    char parse;
    int startingLine=yylineno;
    while ((parse = yyinput())){
        if (parse == '\"') break;

        else if (parse == EOF) {
            fprintf(stderr, "Unclosed string in line %d\n", startingLine);
            return -1;
        }
        else if (parse != '\\' && parse != '\"') tmp += parse;
        
        else if (parse == '\\') {
            parse = yyinput();
            switch(parse){
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
   return STRING;
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
        printf("Comment starting in line %d is not closed properly.\n", startingLine);
        
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
/*
int main(int argc, char** argv){
        
    if (argc > 1){
        if(!(yyin = fopen(argv[1], "r"))){
            fprintf(stderr, "Cannot read file: %s\n", argv[1]);
            return 1;
        }
    }
    else
        yyin = stdin;

    initEnumMap();

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
}*/