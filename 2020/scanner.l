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
        std::string      type;
    } alpha_tok;
    
    #define YY_DECL int alpha_yylex()

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

PUNMRKS (\;)|(\,)|(\:)|(\:\:)|(\.)|(\.\.)|(\{)|(\})|(\[)|(\])|(\()|(\))

IDENT [a-zA-Z][a-zA-Z_0-9]*

WHITESPACE [ \n\t\r]+

SCOMMENT "//".*

%%

{KEYWORD} {
    alpha_tok temp;
    temp.numline = yylineno;
    temp.numToken = ++tokenCounter;
    temp.content = yytext;
    temp.type = "KEYWORD";
    alpha_token_list.push_back(temp);
}

{OPERATOR} {
    alpha_tok temp;
    temp.numline = yylineno;
    temp.numToken = ++tokenCounter;
    temp.content = yytext;
    temp.type = "OPERATOR";
    alpha_token_list.push_back(temp);
}

{INTCONST} {
    alpha_tok temp;
    temp.numline = yylineno;
    temp.numToken = ++tokenCounter;
    temp.content = yytext;
    temp.type = "INTCONST";
    alpha_token_list.push_back(temp);
}

{DOUBLECONST} {
    alpha_tok temp;
    temp.numline = yylineno;
    temp.numToken = ++tokenCounter;
    temp.content = yytext;
    temp.type = "DOUBLECONST";
    alpha_token_list.push_back(temp);
}

{PUNMRKS} {
    alpha_tok temp;
    temp.numline = yylineno;
    temp.numToken = ++tokenCounter;
    temp.content = yytext;
    temp.type = "PUNMRKS";
    alpha_token_list.push_back(temp);
}

{IDENT} {
    alpha_tok temp;
    temp.numline = yylineno;
    temp.numToken = ++tokenCounter;
    temp.content = yytext;
    temp.type = "IDENT";
    alpha_token_list.push_back(temp);
}

{SCOMMENT} {
    alpha_tok temp;
    temp.numline = yylineno;
    temp.numToken = ++tokenCounter;
    temp.content = yytext;
    temp.type = "SCOMMENT";
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
    temp.type = "STRING";
    alpha_token_list.push_back(temp);
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

    alpha_yylex();

    for(int i = 0; i < alpha_token_list.size(); i++) {
        std::cout << alpha_token_list[i].numline << ": #"
        << alpha_token_list[i].numToken << " \""
        << alpha_token_list[i].content << "\" "
        << alpha_token_list[i].type << "\n";
    }

    return 0;
}