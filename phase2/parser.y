%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <iostream>
    #include <string>
    #include <map>
    #include <vector>
    #include <assert.h>
    int yyerror(std::string yaccProvideMessage);
    int yylex(void* yylval);
    extern void initEnumMap();
    extern int yylineno;
    extern char* yytext;
    extern FILE* yyin;

    unsigned int currentScope = 0;

    enum SymbolType {
      GLOB, LOCL, FORMAL, USERFUNC, LIBFUNC  
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
                } 
                else {
                    Variable *temp = new Variable(_name, _scope, _line);
                }
                type = _type;
            }

            bool isActive() { return enabled; }

            void activate() { enabled = true; }
            void deactivate() { enabled = false; }
            int getType(){
                return type;
            }
            
    };

    std::map <std::string,std::vector<SymbolTableEntry*> > SymbolTable;
    std::map <int,std::vector<SymbolTableEntry*> > ScopeTable;
    

    /*Symbol table Functions*/
    
    void addToSymbolTable(std::string _name, int _scope, int _line, SymbolType _type) {
        SymbolTableEntry *newEntry = new SymbolTableEntry(_name,_scope,_line,_type);
        SymbolTable[_name].push_back(newEntry);
        ScopeTable[_scope].push_back(newEntry);
    }

    void InitilizeLibraryFunctions(){
        SymbolType t = LIBFUNC;
        addToSymbolTable("print",0,0,t);
        addToSymbolTable("input",0,0,t);
        addToSymbolTable("objectmemberkeys",0,0,t);
        addToSymbolTable("objecttotalmembers",0,0,t);
        addToSymbolTable("objectcopy",0,0,t);
        addToSymbolTable("totalarguments",0,0,t);
        addToSymbolTable("argument",0,0,t);
        addToSymbolTable("typeof",0,0,t);
        addToSymbolTable("strtonum",0,0,t);
        addToSymbolTable("sqrt",0,0,t);
        addToSymbolTable("cos",0,0,t);
        addToSymbolTable("sin ",0,0,t);
    }


    
%}


%lex-param {NULL}
%start program

%token IF ELSE WHILE FOR FUNCTION RETURN BREAK CONTINUE AND NOT OR LOCAL TRUE FALSE NIL
%token ASSIGN PLUS MINUS MULTIPLY DIVIDE MOD EQUAL NOT_EQUAL PLUS_PLUS MINUS_MINUS GREATER LESS GREATER_EQUAL LESS_EQUAL
%token SEMICOLON COMMA COLON COLON_COLON DOT DOT_DOT LEFT_BRACE RIGHT_BRACE LEFT_BRACKET RIGHT_BRACKET LEFT_PARENTHESIS RIGHT_PARENTHESIS 
%token IDENT DOUBLECONST INTCONST STRING
%token UMINUS

%left LEFT_PARENTHESIS RIGHT_PARENTHESIS
%left LEFT_BRACKET RIGHT_BRACKET
%left DOT DOT_DOT
%right NOT PLUS_PLUS MINUS_MINUS UMINUS
%left MULTIPLY DIVIDE MOD
%left PLUS MINUS 
%nonassoc GREATER GREATER_EQUAL LESS LESS_EQUAL
%nonassoc EQUAL NOT_EQUAL
%left AND
%left OR
%right ASSIGN


%%
program:          stmt {}
                ;

stmt:             expr SEMICOLON {}
                | ifstmt {}
                | whilestmt {}
                | forstmt {}
                | returnstmt {}
                | BREAK SEMICOLON {}
                | CONTINUE SEMICOLON {}
                | block {}
                | funcdef {}
                | SEMICOLON {}
                ;

expr:             assignexpr {}
                | expr PLUS expr {}
                | expr MINUS expr {}
                | expr MULTIPLY expr {}
                | expr DIVIDE expr {}
                | expr MOD expr {}
                | expr GREATER expr {}
                | expr GREATER_EQUAL expr {}
                | expr LESS expr {}
                | expr LESS_EQUAL expr {}
                | expr EQUAL expr {}
                | expr NOT_EQUAL expr {}
                | expr AND expr {}
                | expr OR expr {}
                | term {}
                ;
/*
op:               MULTIPLY {std::cout<<"op>>>MULTIPLY\n";}
                | DIVIDE {std::cout<<"op>>>DIVIDE\n";}
                | MOD {std::cout<<"op>>>MOD\n";}
                | GREATER {std::cout<<"op>>>GREATER\n";}
                | GREATER_EQUAL {std::cout<<"op>>>GREATER_EQUAL\n";}
                | LESS {std::cout<<"op>>>LESS\n";}
                | LESS_EQUAL {std::cout<<"op>>>LESS_EQUAL\n";}
                | EQUAL {std::cout<<"op>>>EQUAL\n";}
                | NOT_EQUAL {std::cout<<"op>>>NOT_EQUAL\n";}
                | AND {std::cout<<"op>>>AND\n";}
                | OR {std::cout<<"op>>>or\n";}
                ;
*/

term:             LEFT_PARENTHESIS expr RIGHT_PARENTHESIS {}
                | UMINUS expr {}
                | NOT expr {}
                | PLUS_PLUS lvalue {}
                | lvalue PLUS_PLUS {}
                | MINUS_MINUS lvalue {}
                | lvalue MINUS_MINUS {}
                | primary {}
                ;

assignexpr:       lvalue ASSIGN expr {}
                ;

primary:          lvalue {}
                | call {}
                | objectdef {}
                | LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS {}
                | const {}
                ;

lvalue:           IDENT {}
                | LOCAL IDENT {}
                | COLON_COLON IDENT {}
                | member {}
                ;

member:           lvalue DOT IDENT {}
                | lvalue LEFT_BRACKET expr RIGHT_BRACKET{}
                | call DOT IDENT {}
                | call LEFT_BRACKET expr RIGHT_BRACKET{}
                ;

call:             call LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {}
                | lvalue callsuffix {}
                | LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {}
                ;

callsuffix:       normcall {}
                | methodcall {}
                ;

normcall:         LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {}
                ;

methodcall:       DOT_DOT IDENT LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {}
                ;

elist:            expr {}
                | expr COMMA elist {}
                |
                ;

objectdef:        LEFT_BRACKET elist RIGHT_BRACKET {}
                | LEFT_BRACKET indexed RIGHT_BRACKET {}
                ;

indexed:          indexedelem {}
                | indexedelem COMMA indexed {}
                ;

indexedelem:      LEFT_BRACE expr COLON expr RIGHT_BRACE {}
                ;

block:            LEFT_BRACE RIGHT_BRACE {}
                | LEFT_BRACE stmt RIGHT_BRACE {}
                ;

funcdef:          FUNCTION LEFT_PARENTHESIS idlist RIGHT_PARENTHESIS block {}
                | FUNCTION IDENT LEFT_PARENTHESIS idlist RIGHT_PARENTHESIS block {}
                ;

const:            INTCONST {}
                | DOUBLECONST {}
                | STRING {}
                | NIL {}
                | TRUE {}
                | FALSE {}
                ;

idlist:           IDENT {}
                | IDENT COMMA idlist {}
                | {}
                ;


ifstmt:           IF LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt {}
                | IF LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt ELSE stmt {}
                ;

whilestmt:        WHILE LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt {}
                ;

forstmt:          FOR LEFT_PARENTHESIS elist SEMICOLON expr SEMICOLON elist RIGHT_PARENTHESIS stmt {}
                ;

returnstmt:       RETURN SEMICOLON {}
                | RETURN expr SEMICOLON {}
                ;
            
%%

int
yyerror(std::string yaccProvideMessage){

    std::cout<<yaccProvideMessage<<": at line "<< yylineno<<", before token: "<<yytext<<std::endl;
    fprintf(stderr, "INPUT NOT VALID\n");
}

int
main(int argc, char** argv){

    if(argc > 1){
        if(!(yyin = fopen(argv[1], "r"))){
            fprintf(stderr, "Cannot read file: %s\n", argv[1]);
            return 1;
        }
    }
    else
        yyin = stdin;
    initEnumMap();
    yyparse();
    std::cout<<"redre"<<std::endl;
    addToSymbolTable("eltion", 0, 0, LOCL);
    std::cout<<SymbolTable["eltion"][0]->getType()<<std::endl;
    std::cout<<ScopeTable[0][0]->getType()<<std::endl;
    /*addToSymbolTable("sdsa", 0, 0, GLOB);
    std::cout<<SymbolTable.size()<<std::endl;
    std::cout<<SymbolTable["eltion"][1].type<<std::endl;*/
    return 0;
}