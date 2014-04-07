/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;


/*
 *  Add Your own definitions here
 */

int commentlevel = 0;
int stringsize = 0;
int inbadstring = 0;

void add_to_string (char *text) {
	stringsize += strlen(text);
	if (! inbadstring) {
		if (stringsize > MAX_STR_CONST) {
			inbadstring = 1;
		}
	}
}

%}

/*
 * Define names for regular expressions here.
 */

%x COMMENT
%x STRING
%x MLCOMMENT

%%

 /*
  *  Nested comments
  */

"--"				BEGIN(COMMENT);
<COMMENT>[^\n]*\n	{
						curr_lineno++;
						BEGIN(INITIAL);
					}

"\(\*"				{ commentlevel++; BEGIN(MLCOMMENT);}
<MLCOMMENT>\(\*		{ commentlevel++; }
<MLCOMMENT>\n		{ curr_lineno++; }
<MLCOMMENT>\*\)		{ commentlevel--;  if (commentlevel == 0) BEGIN(INITIAL); }
<MLCOMMENT><<EOF>>	{ yylval.error_msg = "EOF in comment"; BEGIN(INITIAL); return (ERROR);}
<MLCOMMENT>.		
"\*\)"				{ yylval.error_msg = "Unmatched *"; return (ERROR); }

 /*
  *  The multiple-character operators.
  */
=>		{ return (DARROW); }
"<-"	{ return (ASSIGN); }
"<="	{ return (LE);}

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

(?i:class)			{ return (CLASS);}
(?i:else)			{ return (ELSE);}
(?i:fi)	    		{ return (FI);}
(?i:if)        		{ return (IF);}
(?i:in)        		{ return (IN);}
(?i:inherits)  		{ return (INHERITS);}
(?i:let)      		{ return (LET);}
(?i:loop)      		{ return (LOOP);}
(?i:pool)      		{ return (POOL);}
(?i:then)      		{ return (THEN);}
(?i:while)     		{ return (WHILE);}
(?i:case)      		{ return (CASE);}
(?i:esac)      		{ return (ESAC);}
(?i:of)        		{ return (OF);}
(?i:new)       		{ return (NEW);}
(?i:isvoid)   		{ return (ISVOID);}
(?i:not)       		{ return (NOT);}


[0-9]+				{ 
					  yylval.symbol = inttable.add_string(yytext);
					  return (INT_CONST);
					}

f[aA][lL][sS][eE]	{ 
					  yylval.boolean = false;
					  return (BOOL_CONST);
					}

t[rR][uU][eE]		{ 
					  yylval.boolean = true;
					  return (BOOL_CONST);
					}

[:@,;\(\)\{\}=<~/\-\*\+\.] { return *(yytext); }

[\t\f\r\v ]+ {}

\n					{curr_lineno++;}

[A-Z][A-Za-z_0-9]*	{
					  yylval.symbol = inttable.add_string(yytext);
					  return (TYPEID);
					}

[a-z][A-Za-z_0-9]*	{
					  yylval.symbol = inttable.add_string(yytext);
					  return (OBJECTID);
					}
 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

\" { 
	string_buf_ptr = string_buf;
	stringsize = 0;
	inbadstring = 0;
	BEGIN(STRING);
}
<STRING>\"		{
					BEGIN(INITIAL);
					if (stringsize > MAX_STR_CONST) {
						yylval.error_msg = "String constant too long";
						return(ERROR);
					}
					else {
						yylval.symbol = inttable.add_string(string_buf);
						return(STR_CONST);
					}
				}
<STRING>\\\n	{ add_to_string("\n");}
<STRING>\\n		{ add_to_string("\n");}
<STRING>\n		{ 
					curr_lineno++; 
					yylval.error_msg = "Unterminated string constant";
					inbadstring = 1;
					return(ERROR);
				}
<STRING><<EOF>>	{ yylval.error_msg = "EOF in string constant"; BEGIN(INITIAL);return(ERROR);}
<STRING>\\0		{ 
					yylval.error_msg = "String contains null character"; 
					inbadstring = 1;
					return(ERROR);
				}
<STRING>\\t		{ add_to_string("\t");}
<STRING>\\b		{ add_to_string("\b");}
<STRING>\\f		{ add_to_string("\f");}
<STRING>.		{ add_to_string(yytext); }



.	{
		yylval.error_msg = yytext;
		return (ERROR);
	}

  


%%

