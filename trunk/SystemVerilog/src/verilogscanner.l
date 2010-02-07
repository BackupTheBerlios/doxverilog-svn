/******************************************************************************
* Copyright (c) M.Kreis,2009 
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation; either version 2 of the License, or
* (at your option) any later version.
*
*
* This program is   distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU Library General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
*
* You may use and distribute this software under the terms of the
* GNU General Public License, version 2 or later
*****************************************************************************/

/****************************************************************************
 * Simple Scanner for Verilog 2001 subset
 * Date: 02/2009             
 * supports the IEEE Std 1364-2001 (Revision of IEEE Std 1364-1995)Verilog subset
 * Date: 01/2010
 * supports SystemVerilog 3.1
 *****************************************************************************/


%{

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>
#include <ctype.h>
#include "commentscan.h"
#include "verilogscanner.h"
#include "doxygen.h"
#include "searchindex.h"
#include "verilogdocgen.h"
#include <ctype.h>
#include "scanner.h"
#include "vhdldocgen.h"
#include "util.h"
#include "verilogparser.hpp"
#include "bufstr.h"
#include "preVerilog.h"
#include "message.h"
//--------------------------------------------------------------------------

static ParserInterface *g_thisParser;

static int lastToken;
static int yyLineNr =1;
static int yyPrevLine=1;
static int yyEndLine=1;
static char* g_buf;
static int verilogState;
static int inputPosition;
static Entry* curRoots;
static int defineLineContinue=0;
static int startComment;
static int iSize=0;
static const char* inString;
static QFile inputFile;
static QCString yyFileName;
static QList<QCString> qlist;

// stores global   variables like `define xxxx
static QDict<Entry>   globalMemberList(1009);

static MyParserConv *pconv;

static QCString lastLetter;
static int totLines=0;
static bool multLineComment=false;
static QCString strComment;
static int iDocLine=-1;
// ----------------- <verilog-code > ----------------------------------

static QCString   g_CurrClass;
static QCString   g_tempComp;
static CodeOutputInterface * g_code;

static QCString      g_curClassName;
static const char *  g_inputString;   //!< the  code fragment as text
static int           g_inputLines=0;      //!<number of line in the code fragment
static bool          g_needsTermination;

static QCString      g_exampleName;
static QCString      g_exampleFile;
static bool doxComment=false; // doxygen comment ? 
static QCString      g_CurrScope;
static FileDef *     g_sourceFileDef;
static Definition *  g_currentDefinition;
static MemberDef *   g_currentMemberDef;
static bool          g_includeCodeFragment;
static const char *  g_currentFontClass;
static bool          g_lexInit = FALSE;
static bool          g_parseCode=FALSE;

// ------------------< functions for verilog code scanner >---------------

static void writeFont(const char *s,const char* text);
static void generateMemLink(CodeOutputInterface &ol,QCString &clName,QCString& memberName);
static bool writeColoredWord(QCString& word );
static void startCodeLine();
static bool generateClassOrGlobalLink(CodeOutputInterface &ol,char *clName, bool typeOnly=FALSE);
static bool generateMemLink(CodeOutputInterface &ol,QCString &clName,QCString& memberName,int type);
static void codifyLines(char *text,char *cl=NULL);
static void addToSearchIndex(const char *text);
static void writeMultiLineCodeLink(CodeOutputInterface &ol,
                  const char *ref,const char *file,
                  const char *anchor,const char *text);
static void startFontClass(const char *s);
static void endFontClass();

//-------------------------------------------------------------------

static void parseGlobalMember();
static void parseLib(char *);
static void composeString(QCString& q);
static void writeInclude(QCString);
static void printLineString(QCString&);

// static void addVerilogIncludes();
//-------------------------------------------------------------------

#define YY_NEVER_INTERACTIVE 1

//-----------------------------------------------------------
// dictionaries for keywords
static QDict<QCString> verilogKeyDict(17,false);
static QDict<QCString> verilogGlobalDict(17,false);
static QDict<QCString> verilogDefineDict(17,false);
static QDict<QCString> verilogDataTypeDict(17,false);

static const QCString g_verilogkeyword("vhdlkeyword");
static const QCString g_verilogDefinition("preprocessor");
static void writeDefineString(const char*);

int currState=0;

                                      

static void buildKeyMap()
{
	 const char* data_types[]={"logic","reg", "byte","bit","shortint","int","longint","integer","time","real","shortreal","realtime",""};
	 
	 const char* VerilogDefineMap[] = {
	                                   "`accelerate","`autoexepand_vectornets",
                                       "`begin_keywords",
                                       "`celldefine",
                                       "`default_nettype","`define","`default_decay_time","`default_trieg_distributed","`default_trireg_strength","`delay_mode_distributed","`delay_mode_path","`delay_mode_unit","`delay_mode_zero",
                                       "`else","`elsif","`endcelldefine","`endif","`end_keywords","`endprotect","`endprotected","`expand_vectornets",
                                       "`file",
                                       "`ifdef","`ifndef","`include",
                                       "`line",
                                       "`noaccelerate","`noexpand_vectornets","`noremove_gatenames","`noremove_netnames","`nounconnected_drive",
                                       "`pragma","`protect","`endprotect",
                                       "`remove_gatenames","`remove_netnames","`resetall",
                                       "`timescale",
                                       "`unconnected_drive","`undef","`uselib",""
	                                   };
	 
	 const char* VerilogKeyMap[] = {  "alias","assign","always","always_comb","always_ff","always_latch","and","assert","assig","assume","automatic",
                                          "before","begin","bind","bins","binsof","bit","break","buf","bufif0","bufif1","byte",
                                           "case","casex","casez","cell","chandle","class","clocking","cmos","config","const","constraint","context","continue","cover","covergroup","coverpoint","cross",
                                           "deassign","default","defparam","design","disable","dist","do",
                                           "edge","else","end","endcase","endclass","endclocking","endconfig","endfunction","endgenerate","endgroup","endinterface","endmodule","endpackage","endprimitive","endprogram","endproperty","endspecify","endsequence","endtable","endtask","enum","event","expect","export","extends","extern",
                                           "final","first_match","for","force","foreach","forever","fork","forkjoin","function",
                                           "generate","genvar",
                                           "highz0","highz1",
                                           "if","iff","ifnone","ignore_bins","illegal_bins","import","incdir","include","initial","inout","input","inside","instance","int","integer","interface","intersect",
                                           "join","join_any","join_none",
                                           "large","liblist","library","local","localparam","logic","longint",
                                           "macromodule","matches","medium","modport","module","nand","negedge","new","nmos",
                                           "nor","noshowcancelled","not","notif0","notif1","null",
                                           "or","output",
                                           "package","packed","parameter","pmos","posedge","primitive","priority","program","property","protected","pull0","pull1","pulldown","pullup","pulsestyle_onevent","pulsestyle_ondetect","pure",
                                           "rand","randc","randcase","randsequence","rcmos","real","realtime","ref","reg","release","repeat","return","rnmos","rpmos","rtran","rtranif0","rtranif1",
                                           "scalared","sequence","shortint","shortreal","showcancelled","signed","small","solve","specify","specparam","static","string","strong0","strong1","struct","super","supply0","supply1",
                                           "table","tagged","task","this","throughout","time","timeprecision","timeunit","tran","tranif0","tranif1","tri","tri0","tri1","triand","trior","trireg","type","typedef",
                                           "union","unique","unsigned","use",
                                           "var","vectored","virtual","void",
                                           "wait","wait_order","wand","weak0","weak1","while","wildcard","wire","with","within","wor",
                                           "xnor","xor",""
                                          };

	
	// some but not all system words
const char* VerilogSystemMap[] = {"$async$and$array","$async$and$plane","$async$nand$array", "$async$nand$plane","$async$or$array", "$async$or$plane",
                                    "$async$nor$array", "$async$nor$plane","$sync$and$array", "$sync$and$plane","$sync$nand$array", "$sync$nand$plane",
                                    "$sync$or$array", "$sync$or$plane","$sync$nor$array", "$sync$nor$plane","$display", "$strobe",
                                    "$displayb", "$strobeb","$displayh", "$strobeh","$displayo","$strobeo","$monitor", "$write","$monitorb", "$writeb",
                                    "$monitorh", "$writeh","$monitoro", "$writeo","$monitoroff", "$monitoron","$fclose", "$fopen","$fdisplay", "$fstrobe",
                                    "$fdisplayb", "$fstrobeb","$fdisplayh", "$fstrobeh","$fdisplayo", "$fstrobeo","$fgetc", "$ungetc","$fflush", "$ferror",
                                    "$fgets", "$rewind","$fmonitor", "$fwrite","$fmonitorb", "$fwriteb","$fmonitorh",  "$fwriteh",
                                    "$fmonitoro", "$fwriteo","$readmemb", "$readmemh","$swrite", "$swriteb","$swriteo", "$swriteh",
                                    "$sformat", "$sdf_annotate","$fscanf", "$sscanf","$fread", "$ftell","$fseek", "$printtimescale", 
                                    "$timeformat" ,"$finish", "$stop", "$realtime","$stime", "$time","$bitstoreal", "$realtobits",
                                    "$itor", "$rtoi","$signed", "$unsigned","$test$plusargs", "$value$plusargs","$q_initialize", "$q_add",
                                    "$q_remove", "$q_full","$q_exam",
                                   
                                    /* system words from SystemVerilog */
                                   
                                    "$assertkill","$assertoff","$asserton","$bits","$bitstoshortreal","$cast","$cast()",
                                    "$countones","$coverage_control","$coverage_merge","$coverage_save","$dimensions","$error","$exit","$fatal","$fell",
                                    "$get_coverage","$high","$increment","$info","$isunbounded","$isunknown","$left",
                                    "$load_coverage_db","$low","$onehot","$onehot0","$past","$readmemb","$readmemh","$right",
                                    "$root","$rose","$sampled","$set_coverage_db_name","$shortrealtobits","$random", 
                                    "$size","$stable","$typename","$typeof","$unit","$urandom","$urandom_range","$warning","$writememb","$writememh",""};
	
	int j=0;
    
    verilogGlobalDict.setAutoDelete(true);
    verilogKeyDict.setAutoDelete(true);
    verilogDefineDict.setAutoDelete(true);
	qlist.setAutoDelete(true);
	globalMemberList.setAutoDelete(true);
    verilogDataTypeDict.setAutoDelete(true);
	
	QCString p=VerilogKeyMap[0];
    
	while(!p.isEmpty())
	{
		verilogKeyDict.insert(p,new QCString(p.data()));
    	p=VerilogKeyMap[++j];	  
	}

	j=0;
    p=VerilogSystemMap[0]; 
	while(!p.isEmpty())
	{
		verilogGlobalDict.insert(p,new QCString(p.data()));
    	p=VerilogSystemMap[++j];	  
	}

   j=0;
    p=VerilogDefineMap[0]; 
	while(!p.isEmpty())
	{
		verilogDefineDict.insert(p,new QCString(p.data()));
    	p=VerilogDefineMap[++j];	  
	}
	
	j=0;
      //verilogDataTypeDict
    p=data_types[0]; 
	while(!p.isEmpty())
	{
		 
		  verilogDataTypeDict.insert(p,new QCString(p.data()));
    	  p=data_types[++j];	  
	}

}// buildKeypMap

const QCString* VerilogDocGen::findKeyWord(const char *str)
{
    QCString word(str);
	if (word.isEmpty() || word.at(0)=='\0') return 0;
	
	if(verilogKeyDict.find(word))
	  return &g_verilogkeyword;
 
    if(verilogGlobalDict.find(word))
	  return &g_verilogDefinition;
	  
	if(verilogDefineDict.find(word))
	 return &g_verilogDefinition;  
          
   return 0;
}





bool VerilogDocGen::findDataType(const QCString &  word)
{
	static QRegExp epr("[\\s\\[]");
	if (word.isEmpty() || word.at(0)=='\0') return false;
	
	QStringList qq=QStringList::split(epr,word,false);
	
	for(uint i=0;i<qq.count();i++)
	if( verilogDataTypeDict.find(qq[i]))
	  return true;
 
   
   return false;
}


void writeVerilogFont(const char* col,const char* text)
{
  writeFont(col,text);
}

// writes a coloured word to the  output

static void writeVWord(QCString& qcs){
 static bool stripComment=Config_getBool("STRIP_CODE_COMMENTS");
   if(qcs.isEmpty())return;
    QCString temp=qcs;
	if(qcs.stripPrefix("\n")){
	     codifyLines(temp.data());return;}
	else if(qcs.stripPrefix(" "))
	     {g_code->codify(temp.data()); return;}   
 	if(qcs.stripPrefix("\""))
        {
        if(temp.contains('\n'))
         printLineString(temp);
         else
         writeFont("keyword",temp.data());
        return;
         }
	   if(qcs.stripPrefix("//"))
        {
        if (stripComment && temp.contains(vlogComment))
        {
         yyLineNr+=temp.contains("\n");
	    return;
        }
        else 
          writeFont("keyword",temp.data());
          return;
          }
    
    if(qcs.stripPrefix("§")){
            if(qcs.contains('\n'))
                   return; // exit(0);
               
         qcs.stripPrefix("§");   
		 VhdlDocGen::deleteAllChars(qcs,'§');
		 writeFont("undoc",qcs.data());
		 return;					
		}

	if(qcs.stripPrefix("/*!")) 
	 if( stripComment){
		 yyLineNr+=temp.contains("\n");
		 return;					
		}
        else
         qcs.prepend("/*");

	if(qcs.stripPrefix("/*")){
	     startFontClass("keyword");
	     codifyLines(temp.data());
		 endFontClass();
		 return;					
		}
    
     	 if(qcs.stripPrefix("`"))
	     {
	        qcs=temp;
		    if(qcs.stripPrefix("`define"))
		     {
              writeFont("preprocessor","`define");     
              writeInclude(qcs);
              return;
              }
		   
		   if(qcs.stripPrefix("`include"))
		     {
              writeFont("preprocessor","`include");     
              writeInclude(qcs);
              return;
              }
		  }//
		  
		   const QCString *ss=VerilogDocGen::findKeyWord(qcs.data());
	      if (ss)
          {writeFont(ss->data(),qcs.data());return;}
   
		   
	   
		   MemberDef* md=findGlobalMember(temp);  
            if(md)
             { 
	         g_code->writeCodeLink(md->getReference(),
	                      md->getOutputFileBase(),
			              md->anchor(),
			              temp.data(),
			              md->briefDescriptionAsTooltip());
              return;
              }
		   
		   
		      QCString  tempClass = getCurrVerilogParsingClass();
		        bool feat=generateVerilogMemLink(tempClass,temp,VerilogDocGen::FEATURE);
		        if(feat) return;
		     /*   
		        if(!feat)
		        {
	             writeWord(qcs.data());	
		         return;
		        }
            */
            
     if(qcs.length()==1)
         {codifyLines(qcs.data());return;}
     if(qcs.stripPrefix("$"))
          writeFont("vhdlkeyword",temp.data());
     else  g_code->codify(temp.data());
	  
}//writeVWord


// writes the rest of the input buffer
void printVerilogBuffer(bool b)
{
  QCString qbuffer;
  uint len=qlist.count();
  for(uint j=0;j<len;j++) {
    QCString *qcs=(QCString*)qlist.at(j);
	writeVWord(*qcs);
        
 }//for
 qlist.clear();
}//printVerilogBuffer


void writePrevVerilogWords(const QCString& qcs){

 uint len=qlist.count();
 uint v=0;
  
  for(uint j=0;j<len;j++) {
    QCString *word=(QCString*)qlist.getFirst();
//	printf("\n++++++++++++++++++ %s",qcs.data()); 
//if(qcs.contains("`"))
//	 printVerilogStringList();
	 if(strcmp(qcs.data(),word->data()) != 0) {
      writeVWord(*word);
      qlist.removeFirst();
     }else { 
//	   QCString *wsord=(QCString*)qlist.getFirst();
	  qlist.removeFirst();
	 v=j; 
	 break; 
	 }
   }//for

} // writePrevVerilogWords

// only for debugging 
void printVerilogStringList()
{
  QCString qbuffer;
  int len=qlist.count();
 for(int j=0;j<len;j++) {
    QCString *qcs=(QCString*)qlist.at(j);
	 qbuffer+=qcs->data();
  }
  fprintf(stderr,"\n[%s]",qbuffer.data());
}


void codifyVerilogString(char* c,char* color)
{
 if(color==NULL)
  g_code->codify(c);
 else
  writeFont(color,c);
 }

bool  generateVerilogMemLink(QCString &clName,QCString& memberName,int type)
{
 return generateMemLink(*g_code,clName,memberName,type);
}


static bool generateMemLink(CodeOutputInterface &ol,QCString &clName,QCString& memberName,int type)
{
  	if(memberName.isEmpty()) return false; 

  	if(memberName.length()==1 && (isalpha(memberName.at(0))==0) )
  	 return false;

 // if(clName.isEmpty() || memberName.isEmpty()) return false; 

  bool isLocal=false;

  MemberDef *md=0;
  if(memberName.contains('`'))
   isLocal=true;

  ClassDef *cd=NULL;

   md=VerilogDocGen::findMember(clName,memberName,cd,yyLineNr );
  
  if(isLocal)
    memberName.prepend("`");
  
  if(cd)
  {
     ol.linkableSymbol(yyLineNr,memberName,cd, g_currentMemberDef ? g_currentMemberDef : g_currentDefinition);
     writeMultiLineCodeLink(ol,cd->getReference(),cd->getOutputFileBase(),0,memberName);
     addToSearchIndex(memberName);
     return true;
  }
 
  if (md && md->isLinkable()) // is it a linkable class
  {
    addToSearchIndex(memberName);
    if(isLocal) memberName.prepend("`");
	 writeMultiLineCodeLink(ol,md->getReference(),md->getOutputFileBase(),md->anchor(),memberName);
   return true;
  }

 
 addToSearchIndex(memberName);

 return false;
}// generateMemLink



static void endCodeLine()
{
  if (g_currentFontClass) { g_code->endFontClass(); }
  g_code->endCodeLine();
}

static void addToSearchIndex(const char *text)
{
  static bool searchEngineEnabled=Config_getBool("SEARCHENGINE");
  if (searchEngineEnabled)
  {
    Doxygen::searchIndex->addWord(text,FALSE);
  }
}


/*! writes a link to a fragment \a text that may span multiple lines, inserting
 * line numbers for each line. If \a text contains newlines, the link will be 
 * split into multiple links with the same destination, one for each line.
 */
static void writeMultiLineCodeLink(CodeOutputInterface &ol,
                  const char *ref,const char *file,
                  const char *anchor,const char *text)
{
  bool done=FALSE;
  char *p=(char *)text;
  while (!done)
  {
    char *sp=p;
    char c;
    while ((c=*p++) && c!='\n');
    if (c=='\n')
    {
      yyLineNr++;
      *(p-1)='\0';
     // printf("writeCodeLink(%s,%s,%s,%s)\n",ref,file,anchor,sp);
      ol.writeCodeLink(ref,file,anchor,sp,0);
      endCodeLine();
      if (yyLineNr<g_inputLines) 
      {
	startCodeLine();
      }
    }
    else
    {
    //  printf("writeCodeLink(%s,%s,%s,%s)\n",ref,file,anchor,sp);
      ol.writeCodeLink(ref,file,anchor,sp,0);
      done=TRUE;
    }
  }
}

bool generateVerilogClassOrGlobalLink(char *clName)
{
  return generateClassOrGlobalLink(*g_code,clName,FALSE);
}


static bool generateClassOrGlobalLink(CodeOutputInterface &ol,char *clName, bool typeOnly)
{
  QCString className=QCString(clName);

  if(className.isEmpty()) return false;

  ClassDef *cd=0;
   cd = getClass(className.data()); 
  
  if (cd && cd->isLinkable()) // is it a linkable class
  {
  	  QCString temp=cd->displayName();
	  ol.linkableSymbol(yyLineNr,temp,cd, g_currentMemberDef ? g_currentMemberDef : g_currentDefinition);
      writeMultiLineCodeLink(ol,cd->getReference(),cd->getOutputFileBase(),0,temp);
      addToSearchIndex(className);
   return true;
  }
 return false;
}// generateClassOrGLink  


static void startFontClass(const char *s)
{
  if(s==NULL) return;
  g_code->startFontClass(s);
  g_currentFontClass=s;
}

static void writeFont(const char *s,const char* text)
{
  if(s==NULL) return;
  g_code->startFontClass(s);
  g_code->codify(text);
  g_code->endFontClass();
}



/*! counts the number of lines in the input */
static int countLines()
{
  const char *p=inString;
  char c;
  int count=1;
  while ((c=*p)) 
  { 
    p++ ; 
    if (c=='\n') count++;  
  }
  if (p>g_inputString && *(p-1)!='\n') 
  { // last line does not end with a \n, so we add an extra
    // line and explicitly terminate the line after parsing.
    count++, 
    g_needsTermination=TRUE; 
  } 
  return count;
}

/*! writes a word to the output.
 *  If curr_class is defined, the word belongs to a class
 *  and will be linked.
 */

static void writeWord(char *word,char* curr_class=NULL)
{
   if(word==NULL)return;
  
   if(VerilogDocGen::findKeyWord(word))
     writeFont("vhdlkeyword",word);
   else
   g_code->codify(word); 
  return;
}// writeWord



/*! write a code fragment `text' that may span multiple lines, inserting
 * line numbers for each line.
 */
static void codifyLines(char *text,char *cl)
{
 // printf("codifyLines(%d,\"%d\")\n",yyLineNr,strlen(text));
  if(text==NULL) return;
  char *p=text,*sp=p;
  char c;
  bool done=FALSE;
  while (!done)
  {
    sp=p;
    while ((c=*p++) && c!='\n');
    if (c=='\n')
    {
      yyLineNr++;
      *(p-1)='\0';
       writeWord(sp,cl);
	  endCodeLine();
      if (yyLineNr<g_inputLines) 
      {
    	startCodeLine();
      }
    }
    else
    {
      writeWord(sp,cl);
	  done=TRUE;
    }
  }
}


static void setCurrentDoc(const QCString &name,const QCString &base,const QCString &anchor="")
{
  static bool searchEngineEnabled=Config_getBool("SEARCHENGINE");
  if (searchEngineEnabled)
  {
    Doxygen::searchIndex->setCurrentDoc(name,base,anchor);
  }
}


/*! start a new line of code, inserting a line number if g_sourceFileDef
 * is TRUE. If a definition starts at the current line, then the line
 * number is linked to the documentation of that definition.
 */
static void startCodeLine()
{
  //if (g_currentFontClass) { g_code->endFontClass(); }
  if (g_sourceFileDef)
  {
     if((yyLineNr % 1000) == 0) 
	 fprintf(stderr,"\r parsing line %d:",yyLineNr);
    Definition *d   = g_sourceFileDef->getSourceDefinition(yyLineNr);
   // printf("startCodeLine %d d=%s\n", yyLineNr,d ? d->name().data() : "<null>");
    if (!g_includeCodeFragment && d)
    {
      g_currentDefinition = d;
      g_currentMemberDef = g_sourceFileDef->getSourceMember(yyLineNr);
      if(!g_tempComp.isEmpty() && g_currentMemberDef )
	  {
      //  ClassDef *cf=VhdlDocGen::getClass(g_tempComp.data());
	    QCString nn=g_currentMemberDef->name();
	    ClassDef *ccd;
		MemberDef* mdeff=VerilogDocGen::findMember(g_tempComp,nn,ccd,yyLineNr);
		if(mdeff)
          g_currentMemberDef=mdeff;
	  
	  }
       
       QCString lineAnchor;
      lineAnchor.sprintf("l%05d",yyLineNr);
      if (g_currentMemberDef)
      {
     	g_code->writeLineNumber(g_currentMemberDef->getReference(),
	                        g_currentMemberDef->getOutputFileBase(),
	                        g_currentMemberDef->anchor(),yyLineNr);
        setCurrentDoc(
                                g_currentMemberDef->qualifiedName(),
	                        g_sourceFileDef->getSourceFileBase(),
	                        lineAnchor);
      }
      else if (d->isLinkableInProject())
      {
        g_code->writeLineNumber(d->getReference(),
	                        d->getOutputFileBase(),
	                        0,yyLineNr);
        setCurrentDoc(
                                d->qualifiedName(),
	                        g_sourceFileDef->getSourceFileBase(),
	                        lineAnchor);
      }
    }
    else
    {
      g_code->writeLineNumber(0,0,0,yyLineNr);
    }
  }
  g_code->startCodeLine(); 
  if (g_currentFontClass)
  {
    g_code->startFontClass(g_currentFontClass);
  }
}


static void endFontClass()
{
  if (g_currentFontClass)
  {
    g_code->endFontClass();
    g_currentFontClass=0;
  }
}

//---------------------------------------------------------------

static void addText(char* c,int len);
static void addToken(const char *);
static int startLex();
static void resetScanner(const char* s,MyParserConv* parse);



#undef	YY_INPUT
#define	YY_INPUT(buf,result,max_size) result=verilogScanYYread(buf,max_size);


static int verilogScanYYread(char *buf,int max_size)
{
 int c=0;
  while ( c < max_size && inString[inputPosition] )
  {
    *buf = inString[inputPosition++] ;
    c++; buf++;
  }
  
  return c;
}

// checks if we have found a correct parsed word or
// part of a word like (reg)ister
static bool check(bool bb=true)
{
  bool b=true;
  char c=yy_hold_char;
 
  if(iSize==0){
   if(g_parseCode){
      qlist.append(new QCString(verilogScanYYtext)); 
  }
  return true;
 }
 
  char d = g_buf[iSize-1];
  int l=isdigit(c);
  int k=isdigit(d);

  if(k!=0 || l!=0 || d=='$') return false;

  l=islower(c);
  k=islower(d);

  if(k!=0 || l!=0) 
    return false;

  l=isupper(c);
  k=isupper(d);

  if(k!=0 || l!=0) 
    return false;

  if(c=='_' || d=='_') return false;
  					               
  if(g_parseCode){
   qlist.append(new QCString(verilogScanYYtext));
  }

  return true;
}

static void parseToken(const char* s){
     if(g_parseCode)    
	 qlist.append(new QCString(verilogScanYYtext));
	 c_lval.ctype=s[0];
	 addToken(s);
	}

//<Start>"option" {if(check())      return  OPTIONDOT_TOK;REJECT;}
//<Start>"type_option." {if(check())      return  TYPEOPTIONDOT_TOK;REJECT;}


%}




/* -------------- VERLIOG SECTION -----------------------------------*/

LL          [ \t]
LF          [ \t\n]
COMMENT     "//"[^\n]*
COMMENT1    "//!"[^\n]*
MIT         [^\\\n]*
STRING      ["][^"]*["]
FEATURE     ("`include"|"`line"|"`timescale"|"`define"|"`elsif"|"`ifndef"|"`ifdef"|"`else"|"`endif"|"`elsif"|"`undef")[^\n]*
FEATURE1    [`][a-zA-Z0-9_]+
FEATUREX     ("`define"){MIT}


SIGNEDBASE  ['][sS][oOhHbBdD]
BASE	    ("'b"|"'B"|"'o"|"'O"|"'d"|"'D"|"'h"|"'H"|{SIGNEDBASE})[ ]?
NETTYPE	    "wire"|"tri"|"tri1"|"supply0"|"wand"|"triand"|"tri0"|"supply1"|"wor"|"trior"|"trireg"
STRENGTH1	"supply1"|"strong1"|"pull1"|"weak1"|"highz1"
STRENGTH0	"supply0"|"strong0"|"pull0"|"weak0"|"highz0"
GATETYPE  	"and"|"nand"|"nor"|"xor"|"xnor"|"buf"|"bufif0"|"bufif1"|"not"|"notif0"|"notif1"|"pulldown"|"pullup"|"nmos"|"rnmos"|"pmos"|"rpmos"|"cmos"|"rcmos"|"tran"|"rtran"|"tranif0"|"rtranif0"|"tranif1"|"rtranif1"

%option noyywrap


  /* language parsing states */

%x Start
%x Commentt
%x FindBegin
%x StartComment
%x tagComment
%x EndOfText
%%

.	{
    BEGIN(Start);  
	}


             
<EndOfText>[^\\\n]* {
                   if(yy_hold_char=='\\')
                   {
                    if(g_parseCode) 
                     writeDefineString(verilogScanYYtext);
                     // qlist.append(new QCString(verilogScanYYtext));
                    else
                    {
                        addText(verilogScanYYtext,verilogScanYYleng);
                     }
                     BEGIN(EndOfText);
                    }
                     else
                     {
                      if(!g_parseCode)
                      { 
                       QCString s=verilogScanYYtext;
                       addText(verilogScanYYtext,verilogScanYYleng);
                       parseGlobalMember();
                       vbufreset();
                      }
                     else{
                          qlist.append(new QCString(verilogScanYYtext));
                         }
                      BEGIN(Start);
                    }
                    }

<EndOfText>[\\] { 
                 if(g_parseCode)
                  { 
                      char c=yy_hold_char;
                      qlist.append(new QCString("\\"));
                      if(yy_hold_char==32)
                      qlist.append(new QCString("\n"));
                   }
                      else{
                           addText(verilogScanYYtext,verilogScanYYleng);
                           if(yy_hold_char==10)
                                addText("?",1);
                           if(yy_hold_char==32)
                           yyLineNr++;
                          }
                 }

<Start>"§"[^\n]* { // grey out undefined code
                   // QCString uu(verilogScanYYtext);
                    if(g_parseCode)
                    {
                    //  fprintf(stderr,"\n%s",uu.data());
                      qlist.append(new QCString(verilogScanYYtext));
                    }
                 }   


<Start>{FEATURE} { 
              //    fprintf(stderr,"<[ %s ]>",verilogScanYYtext);
				   QCString q(verilogScanYYtext);
                   char c=yy_hold_char;
                   defineLineContinue=yyLineNr;
				    vbufreset();  
				   if(!g_parseCode)
				   {
				    addText(verilogScanYYtext,verilogScanYYleng);
				    uint le=q.length()-1;
				    if(q.at(le)=='\\')
				    {			  
				    addText("?",1);
				     BEGIN(EndOfText); 
				    } else{
                     parseGlobalMember();
                     vbufreset();
                     }
                   }
 
                 if(g_parseCode) 
                 {
                      VhdlDocGen::deleteAllChars(q,'§');                                              
                      uint le=q.length()-1;
                      bool newLine=(q.at(le)=='\\');
                      QCString com=checkVerilogComment(q);
                     // qlist.append(new QCString(q.data())); 
                      if(!q.contains("`include"))
                       composeString(q);
                      else
                        qlist.append(new QCString(q.data()));
                      if(!com.isEmpty())
                         qlist.append(new QCString(com.data())); 
                    
                     
				      if(newLine)
				      {
				      BEGIN(EndOfText); 
				      }               
                  }//if
                 }       
 
 <Start>{FEATUREX} {  
                    // assert(0);
                    } 
                 
<Start>{FEATURE1} {
				    QCString s(verilogScanYYtext);
				    DefineDict* gDict=getFileDefineDictVerilog();
				    VhdlDocGen::deleteAllChars(s,'`');
				
				    Define *def=gDict->find(s);
					 
				 	if(g_parseCode)
				 	{
                      QCString *yy=new QCString(verilogScanYYtext);
                      c_lval.cstr[0]='\0';                                                   
                     qlist.append(yy);
                    }
                    s.prepend("`");
					bool bDef=verilogDefineDict.find(s);
					if(!bDef)
					{            
					if(!g_parseCode)
					 addText(verilogScanYYtext,verilogScanYYleng);
				    }
				  	
				  	if(!def && !bDef)// && !def->definition.isEmpty())
					if(Config_getBool("WARNINGS"))
					 printf(" ");  
							 if(!bDef) 
							  return  LETTER_TOK;	
				
					}
<Start>"~§~" {return INLINEBODY_TOK; }
<Start>"library"{LF}+[^;]+    {  parseLib(verilogScanYYtext);return LIBRARY_TOK;  }
<Start>"ifnone"    {if(check())      return  IFNONE_TOK;REJECT;}
<Start>"realtime"    {if(check()) {yyPrevLine=yyLineNr;addText(verilogScanYYtext,verilogScanYYleng); return  REALTIME_TOK;}REJECT;}
<Start>"design"    {if(check())      return  DESIGN_TOK;REJECT;}
<Start>"covergroup" {if(check())  {yyPrevLine=yyLineNr;return  COVERGROUP_TOK;}REJECT;}
<Start>"endgroup" {if(check())      return  ENDGROUP_TOK;REJECT;}
<Start>"coverpoint" {if(check())      return  COVERPOINT_TOK;REJECT;}
<Start>"wildcard" {if(check())      return  WILDCARD_TOK;REJECT;}
<Start>"bins" {if(check())      return  BINS_TOK;REJECT;}
<Start>"illegal_bins" {if(check())      return ILLEGALBINS_TOK;REJECT;}
<Start>"ignore_bins" {if(check())      return  IGNOREBINS_TOK;REJECT;}
<Start>"binsof" {if(check())      return  BINSOF_TOK;REJECT;}
<Start>"cross" {if(check())      return  CROSS_TOK;REJECT;}
<Start>"interface" {if(check()){yyPrevLine=yyLineNr;verilogState=VerilogDocGen::INTERFACE;      return  INTERFACE_TOK; }REJECT;}
<Start>"endinterface" { if(check()){return  ENDINTERFACE_TOK;} REJECT;}
<Start>"this" { if(check()){return THISDOT_TOK;} REJECT;}
<Start>"super" { if(check()){return  SUPERDOT_TOK;} REJECT;}
<Start>"config" {if(check())      return  CONFIG_TOK;REJECT;}
<Start>"endconfig" { if(check()){return  ENDCONFIG_TOK;} REJECT;}
<Start>"include"   {if(check())      return  INCLUDE_TOK;REJECT;}
<Start>"use"   {if(check())      return  USE_TOK;REJECT;}
<Start>"liblist"  { if(check())     return  LIBLIST_TOK;REJECT;}
<Start>"instance"   {if(check())      return  INSTANCE_TOK;REJECT;}
<Start>"cell"  { if(check())     return  CELL_TOK;REJECT;}
<Start>"showcancelled"   {if(check())      return  SHOWCANCEL_TOK;REJECT;}
<Start>"noshowcancelled"  { if(check())     return  NOSHOWCANCEL_TOK;REJECT;}
<Start>"pulsestyle_onevent"   {if(check())      return  PULSEONE_EVENT_TOK;REJECT;}
<Start>"pulsestyle_ondetect"  { if(check())     return  PULSEON_DETECT_TOK;REJECT;}
<Start>"edge"    {if(check())      return  EDGE_TOK;REJECT;}
<Start>"negedge" {if(check()) {addText(verilogScanYYtext,verilogScanYYleng);     return  NEGEDGE_TOK;}REJECT;}
<Start>"posedge" { if(check()){addText(verilogScanYYtext,verilogScanYYleng);return  POSEDGE_TOK;} REJECT;}
<Start>"$root"   {if(check())      return  ROOT_TOK;REJECT;}
<Start>"$unit"   {if(check())      return  UNIT_TOK;REJECT;}
<Start>"$fullskew"   {if(check())      return  FULLSKEW_TOK;REJECT;}
<Start>"$recrem"   {if(check())      return  RECREM_TOK;REJECT;}
<Start>"$removal"   {if(check())      return  REMOVAL_TOK;REJECT;}
<Start>"$timeskew"   {if(check())      return  TIMESKEW_TOK;REJECT;}
<Start>"$nochange"   {if(check())      return  NOCHANGE_TOK;REJECT;}
<Start>"$hold"   {if(check())      return  DHOLD_TOK;REJECT;}
<Start>"$setup"  { if(check())     return  DSETUP_TOK;REJECT;}
<Start>"$setuphold" {if(check())   return  DSETUPHOLD_TOK;REJECT;}
<Start>"$recovery" {if(check())    return  DRECOVERY_TOK;REJECT;}
<Start>"$skew"     {if(check())    return  DSKEW_TOK;REJECT;}
<Start>"$width"    {if(check())    return  DWIDTH_TOK;REJECT;}
<Start>"$period"   {if(check())    return  DPERIOD_TOK;REJECT;}
<Start>"endclass"   {if(check()){ return  ENDCLASS_TOK;}REJECT;}
<Start>"class"   {if(check()) {yyPrevLine=yyLineNr;verilogState=VerilogDocGen::CLASS; return  CLASS_TOK; } REJECT;}
<Start>"timeunit"   {if(check())      return  TIMEUNIT_TOK;REJECT;}
<Start>"timeprecision"   {if(check())      return  TIMEPRECISION_TOK;REJECT;}
<Start>"final"   {if(check()){addText(verilogScanYYtext,verilogScanYYleng);  return  FINAL_TOK; } REJECT;}
<Start>"iff"   {if(check())        return  IFF_TOK;REJECT;}
<Start>"clocking"   {if(check())      return  CLOCKING_TOK;REJECT;}
<Start>"endclocking"   {if(check())      return  ENDCLOCKING_TOK;REJECT;}
<Start>"void"   {if(check()){addText(verilogScanYYtext,verilogScanYYleng);       return  VOID_TOK;}REJECT;}
<Start>"endsequence"   {if(check())      return  ENDSEQUENCE_TOK;REJECT;}
<Start>"randsequence"   {if(check())      return  RANDSEQUENCE_TOK;REJECT;}
<Start>"inside"   {if(check()) {addText(verilogScanYYtext,verilogScanYYleng);     return  INSIDE_TOK;}REJECT;}
<Start>"tagged"   {if(check()){addText(verilogScanYYtext,verilogScanYYleng);       return  TAGGED_TOK; } REJECT;}
<Start>"rand"   {if(check()) {addText(verilogScanYYtext,verilogScanYYleng);     return  RAND_TOK;} REJECT;}
<Start>"program"   {if(check()){yyPrevLine=yyLineNr;verilogState=VerilogDocGen::PROGRAM;      return  PROGRAM_TOK;} REJECT;}
<Start>"endprogram"   {if(check())      return  ENDPROGRAM_TOK;REJECT;}
<Start>"solve"   {if(check())      return  SOLVE_TOK;REJECT;}
<Start>"constraint"   {if(check())      return  CONSTRAINT_TOK;REJECT;}
<Start>"before"   {if(check())      return BEFORE_TOK;REJECT;}
<Start>"dist"   {if(check())      return DIST_TOK;REJECT;}
<Start>"throughout"   {if(check())      return  THROUGHOUT_TOK;REJECT;}
<Start>"within"   {if(check())      return  WITHIN_TOK;REJECT;}
<Start>"intersect"   {if(check())      return  INTERSECT_TOK;REJECT;}
<Start>"first_match"   {if(check())      return  FIRST_MATCH_TOK;REJECT;}
 <Start>"sequence"   {if(check())      return  SEQUENCE_TOK;REJECT;}
<Start>"cover"   {if(check())      return  COVER_TOK;REJECT;}
<Start>"assume"   {if(check())      return  ASSUME_TOK;REJECT;}
<Start>"property"   {if(check())      return  PROPERTY_TOK;REJECT;}
<Start>"endproperty"   {if(check())      return  ENDPROPERTY_TOK;REJECT;}
<Start>"assert"   {if(check())      return  ASSERT_TOK;REJECT;}
<Start>"bind"   {if(check())      return  BIND_TOK;REJECT;}
<Start>"expect"   {if(check())      return  EXPECT_TOK;REJECT;}
<Start>"modport"   {if(check())      return  MODPORT_TOK;REJECT;}
<Start>"context"   {if(check()) {addText(verilogScanYYtext,verilogScanYYleng);      return  CONTEXT_TOK; } REJECT;}
<Start>"export"   {if(check())  {addText(verilogScanYYtext,verilogScanYYleng);     return  EXPORT_TOK; }REJECT;}
<Start>"pure"   {if(check())  {addText(verilogScanYYtext,verilogScanYYleng);     return  PURE_TOK;} REJECT;}
<Start>"const"   {if(check()) {addText(verilogScanYYtext,verilogScanYYleng); return  CONST_TOK; } REJECT;}
<Start>"unique"   {if(check())      return  UNIQUE_TOK;REJECT;}
<Start>"priority"   {if(check())      return  PRIORITY_TOK;REJECT;}
<Start>"matches"   {if(check())      return  MATCHES_TOK;REJECT;}
<Start>"randcase"   {if(check())      return  RANDCASE_TOK;REJECT;}
<Start>"randc"   {if(check())      return  RANDC_TOK;REJECT;}
<Start>"foreach"   {if(check())      return  FOREACH_TOK;REJECT;}
<Start>"do"   {if(check())      return  DO_TOK;REJECT;}
<Start>"with"   {if(check())      return  WITH_TOK;REJECT;}
<Start>"null"   {if(check()) { addText(verilogScanYYtext,verilogScanYYleng);     return  NULL_TOK;} REJECT;}
<Start>"int"   {if(check()){ addText(verilogScanYYtext,verilogScanYYleng);   return  INT_TOK; } REJECT;}
<Start>"shortint"   {if(check()) {addText(verilogScanYYtext,verilogScanYYleng); return  SHORTINT_TOK; } REJECT;}
<Start>"longint"   {if(check()){addText(verilogScanYYtext,verilogScanYYleng); return  LONGINT_TOK; } REJECT;}
<Start>"byte"   {if(check()) {addText(verilogScanYYtext,verilogScanYYleng);  return  BYTE_TOK; }REJECT;}
<Start>"bit"   {if(check()) {addText(verilogScanYYtext,verilogScanYYleng);  return  BIT_TOK; } REJECT;}
<Start>"logic"   {if(check()) {addText(verilogScanYYtext,verilogScanYYleng);  return  LOGIC_TOK; } REJECT;}
<Start>"unsigned"   {if(check()) { addText(verilogScanYYtext,verilogScanYYleng);  return  UNSIGNED_TOK; } REJECT;}
<Start>"shortreal"   {if(check()) {addText(verilogScanYYtext,verilogScanYYleng); return  SHORTREAL_TOK; } REJECT;}
<Start>"static"   {if(check()) { addText(verilogScanYYtext,verilogScanYYleng); return  STATIC_TOK; }REJECT;}
<Start>"enum"   {if(check())      return  ENUM_TOK;REJECT;}
<Start>"type"   {if(check()) {addText(verilogScanYYtext,verilogScanYYleng);      return  TYPE_TOK; } REJECT;}
<Start>"typedef"   {if(check()) {VerilogDocGen::portType="typedef ";     return  TYPEDEF_TOK;}REJECT;}
<Start>"import"   {if(check()) { addText(verilogScanYYtext,verilogScanYYleng);    return  IMPORT_TOK;}REJECT;}
<Start>"ref"   {if(check()) {addText(verilogScanYYtext,verilogScanYYleng);   return  REF_TOK; } REJECT;}
<Start>"chandle"   {if(check()){addText(verilogScanYYtext,verilogScanYYleng);       return  CHANDLE_TOK; } REJECT;}
<Start>"virtual"   {if(check())  {addText(verilogScanYYtext,verilogScanYYleng); VerilogDocGen::portType+="";  return  VIRTUAL_TOK;} REJECT;}
<Start>"time"      { if(check()){yyPrevLine=yyLineNr; addText(verilogScanYYtext,verilogScanYYleng); return  TIME_TOK;} REJECT; }
<Start>"specparam" {if(check())    return  SPECPARAM_TOK;REJECT;}
<Start>"endspecify" {if(check())   return  ENDSPECIFY_TOK;REJECT;}
<Start>"specify"   {  if(check())   return  SPECIFY_TOK;REJECT;}
<Start>"end"        { if(check()) {   yyEndLine=yyLineNr;  strncpy(c_lval.cstr,verilogScanYYtext,verilogScanYYleng);c_lval.cstr[verilogScanYYleng]='\0';return  END_TOK;}REJECT;}
<Start>"begin" {if(check(false))  return  BEGIN_TOK; REJECT;}
<Start>"fork" {if(check(false))  return  FORK_TOK; REJECT;}
<Start>"generate" { if(check())     return  GENERATE_TOK;REJECT;}
<Start>"endgenerate" { if(check())     return  ENDGENERATE_TOK;REJECT;}
<Start>"genvar" { if(check())     return  GENVAR_TOK;REJECT;}
<Start>"default" { if(check())     return  DEFAULT_TOK;REJECT;}
<Start>"automatic" { if(check()){ addText(verilogScanYYtext,verilogScanYYleng);     return  AUTO_TOK;}REJECT;}
<Start>"signed" { if(check()){ yyPrevLine=yyLineNr; addText(verilogScanYYtext,verilogScanYYleng);    return  SIGNED_TOK;}REJECT;}
<Start>"default" { if(check())     return  DEFAULT_TOK;REJECT;}
<Start>"endcase" { if(check())     return  ENDCASE_TOK;REJECT;}
<Start>"else"     { if(check())    return  ELSE_TOK; REJECT;}
<Start>"while"    { if(check())    return  WHILE_TOK; REJECT;}
<Start>"repeat"   { if(check())    return  REPEAT_TOK;REJECT;}
<Start>"forever"  { if(check())    return  FOREVER_TOK;REJECT;}
<Start>"casez"    { if(check())    return  CASEZ_TOK; REJECT;}
<Start>"casex"    { if(check())    return  CASEX_TOK;REJECT;}
<Start>"case"     { if(check())    return  CASE_TOK;REJECT;}
<Start>"if"       { if(check())    return  IF_TOK;REJECT;}
<Start>"disable"  { if(check())    return  DISABLE_TOK;REJECT;}
<Start>"deassign" { if(check())    return  DEASSIGN_TOK;REJECT;}
<Start>"release"  { if(check())    return  RELEASE_TOK; REJECT;}
<Start>"force"    { if(check())    return  FORCE_TOK; REJECT; }
<Start>"wait"     { if(check())    return  WAIT_TOK; REJECT;}
<Start>"join"     { if(check())    return  JOIN_TOK; REJECT;}
<Start>"join_any"     { if(check())    return  JOINANY_TOK; REJECT;}
<Start>"join_none"     { if(check())    return  JOINNONE_TOK; REJECT;}
<Start>"wait_order"     { if(check())    return  WAITORDER_TOK; REJECT;}
<Start>"return"     { if(check())    return  RETURN_TOK; REJECT;}
<Start>"break"     { if(check())    return  BREAK_TOK; REJECT;}
<Start>"continue"     { if(check())    return  CONTINUE_TOK; REJECT;}
<Start>"or"     { if(check()){ addText(verilogScanYYtext,verilogScanYYleng);   return  SOR_TOK;} REJECT;}
<Start>"for"      { if(check())    return  FOR_TOK; REJECT;}
<Start>"packed"   { if(check()) {  yyPrevLine=yyLineNr;  addText(verilogScanYYtext,verilogScanYYleng); return  PACKED_TOK;}REJECT;}
<Start>"union"   { if(check()) {  yyPrevLine=yyLineNr;  return  UNION_TOK;}REJECT;}
<Start>"struct"   { if(check()) {  yyPrevLine=yyLineNr;  return  STRUCT_TOK;}REJECT;}
<Start>"always"   { if(check()) {  yyPrevLine=yyLineNr;  return  ALWAYS_TOK;}REJECT;}
<Start>"always_comb"   { if(check()) {  yyPrevLine=yyLineNr;  return  ALWAYSCOMB_TOK;}REJECT;}
<Start>"always_ff"   { if(check()) {  yyPrevLine=yyLineNr;  return  ALWAYSFF_TOK;}REJECT;}
<Start>"always_latch"   { if(check()) {  yyPrevLine=yyLineNr;  return  ALWAYSLATCH_TOK;}REJECT;}
<Start>"alias"   { if(check()) {  yyPrevLine=yyLineNr;  return  ALIAS_TOK;}REJECT;}
<Start>"new"   { if(check()) { addText(verilogScanYYtext,verilogScanYYleng); yyPrevLine=yyLineNr;  return  NEW_TOK;}REJECT;}
<Start>"package"  { if(check()){yyPrevLine=yyLineNr; verilogState=VerilogDocGen::PACKAGE; return  PACKAGE_TOK;} REJECT;}
<Start>"endpackage"  { if(check()){yyPrevLine=yyLineNr;  return  ENDPACKAGE_TOK;} REJECT;}
<Start>"forkjoin"  { if(check())  return  FORKJOIN_TOK; REJECT;}
<Start>"protected"  { if(check()){addText(verilogScanYYtext,verilogScanYYleng);  return  PROTECTED_TOK;} REJECT;}
<Start>"extern"  { if(check()) { addText(verilogScanYYtext,verilogScanYYleng); return  EXTERN_TOK;} REJECT;}
<Start>"extends"  { if(check())  return  EXTEND_TOK; REJECT;}
<Start>"string"  { if(check()) {yyPrevLine=yyLineNr;addText(verilogScanYYtext,verilogScanYYleng);   return  SSTRING_TOK; } REJECT;}
<Start>"endfunction"  { if(check()){yyEndLine=yyLineNr;  return  ENDFUNC_TOK;} REJECT;}
<Start>"function"     { if(check()){yyPrevLine=yyLineNr;  return  FUNC_TOK;} REJECT;}
<Start>"endtask"      { if(check()){yyEndLine=yyLineNr; return  ENDTASK_TOK;}REJECT;}
<Start>"task"         { if(check()){yyPrevLine=yyLineNr;  return  TASK_TOK;} REJECT;}
<Start>"table"        { if(check())  return  TABLE_TOK; REJECT;}
<Start>"endtable"     { if(check())  return  ENDTABLE_TOK; REJECT;}
<Start>"initial"      { if(check()) {return  INITIAL_TOK;} REJECT;}
<Start>"endprimitive" { if(check())  return  ENDPRIMITIVE_TOK;REJECT;}
<Start>"primitive"    { if(check()){yyPrevLine=yyLineNr; verilogState=VerilogDocGen::PRIMITIVE; return  PRIMITIVE_TOK;} REJECT;}
<Start>"macromodule"  { if(check()){ verilogState=VerilogDocGen::MODULE;   return  MACRO_MODUL_TOK; } REJECT;}
<Start>"module"       { if(check()){ verilogState=VerilogDocGen::MODULE; yyPrevLine=yyLineNr; return  MODUL_TOK; } REJECT;}
<Start>"endmodule"   { if(check())   return  ENDMODUL_TOK;REJECT;}
<Start>"reg"         { if(check()) {yyPrevLine=yyLineNr; addText(verilogScanYYtext,verilogScanYYleng);return  REG_TOK; } REJECT;}
<Start>"integer"     { if(check()) {yyPrevLine=yyLineNr; addText(verilogScanYYtext,verilogScanYYleng);return  INTEGER_TOK;}REJECT;}
<Start>"defparam" { if(check()) return  DEFPARAM_TOK; REJECT;}
<Start>"real"     { if(check()) {yyPrevLine=yyLineNr; addText(verilogScanYYtext,verilogScanYYleng); return  REAL_TOK; } REJECT; }
<Start>"event"    { if(check()){yyPrevLine=yyLineNr;addText(verilogScanYYtext,verilogScanYYleng); return  EVENT_TOK;}REJECT;}
<Start>"assign"   { if(check()) return  ASSIGN_TOK; REJECT;}
<Start>"scalared" { if(check()) return  SCALAR_TOK;REJECT;}
<Start>"vectored" { if(check()) {addText(verilogScanYYtext,verilogScanYYleng); return  VEC_TOK; }  REJECT;}
<Start>"small"    { if(check()) {addText(verilogScanYYtext,verilogScanYYleng); return  SMALL_TOK;}REJECT;}
<Start>"medium"   { if(check()) {addText(verilogScanYYtext,verilogScanYYleng); return  MEDIUM_TOK;} REJECT;}
<Start>"large"    { if(check()) {addText(verilogScanYYtext,verilogScanYYleng); return  LARGE_TOK;} REJECT;}
<Start>"output"   { if(check())  {yyPrevLine=yyLineNr;  addText(verilogScanYYtext,verilogScanYYleng);   return  OUTPUT_TOK; }REJECT;}
<Start>"input"    { if(check()) {yyPrevLine=yyLineNr; addText(verilogScanYYtext,verilogScanYYleng); return  INPUT_TOK;} REJECT;}
<Start>"inout"    { if(check()) {yyPrevLine=yyLineNr; addText(verilogScanYYtext,verilogScanYYleng);    return  INOUT_TOK; }REJECT;}
<Start>"parameter" { if(check()) {yyPrevLine=yyLineNr;return  PARAMETER_TOK;}REJECT;}
<Start>"localparam" { if(check()) {yyPrevLine=yyLineNr; return  LOCALPARAM_TOK;}REJECT;}
<Start>"local" { if(check()) {addText(verilogScanYYtext,verilogScanYYleng);yyPrevLine=yyLineNr; return  LOCAL_TOK;}REJECT;}

<Start>{NETTYPE}   { if(check()) { yyPrevLine=yyLineNr; addText(verilogScanYYtext,verilogScanYYleng);return  NET_TOK;} REJECT;}
<Start>{STRENGTH0} { if(check()) {  addText(verilogScanYYtext,verilogScanYYleng);   return  STR0_TOK;} REJECT;}
<Start>{STRENGTH1} { if(check()) {  addText(verilogScanYYtext,verilogScanYYleng); return  STR1_TOK;}REJECT;}
<Start>{GATETYPE}  { if(check()) {  addText(verilogScanYYtext,verilogScanYYleng);  return  GATE_TOK;}REJECT;}

<*>{LL}*"//%"[^{}\n][^\n]*\n/{LL}*"//%" { // found multiline comment
                     QCString text(verilogScanYYtext);
                     if(!g_parseCode){
                     if(iDocLine==-1){
                       iDocLine=yyLineNr; 
                     }
                      
                      Entry* pTemp=VerilogDocGen::getEntryAtLine(curRoots,iDocLine);
    
                      
  if (pTemp)
  { // found one line comment, add it to the entry on this line
    pTemp->briefLine=yyLineNr;
    pTemp->brief+=yytext;
    VhdlDocGen::prepareComment(pTemp->brief);
  }
    else { 
      strComment+=verilogScanYYtext;
	  multLineComment=true;
	}			                     
     
      yyLineNr+=text.contains('\n');
                      
     }
					 if(g_parseCode) {
					     int v=text.find("//%");
					     if(v>0)
					     {
					     QCString left=text.left(v);
					     qlist.append(new QCString(left));
					     text=text.right(text.length()-v);
					    }
					     QStringList ql=QStringList::split('\n',text,false);
					     QCString trial=(QCString)ql[0];
					     qlist.append(new QCString(trial.data()));   
					     qlist.append(new QCString("\n"));   
					     if(ql.count()>1)
					     qlist.append(new QCString((QCString)ql[1]));   			     
					  
					  }
					 c_lval.ctype=' ';
  BEGIN(tagComment);
  }

<tagComment>{LL}*"//%"[^\n]* {
  if (iDocLine==-1) iDocLine=yyLineNr;
  if(!g_parseCode)
   strComment+=verilogScanYYtext;
  
   if(g_parseCode) 
   { 
      QCString text(verilogScanYYtext);
      int v=text.find("//%");
      if(v>0)
	  {
	   QCString left=text.left(v);
	   qlist.append(new QCString(left));
	   text=text.right(text.length()-v);
	  }
     qlist.append(new QCString(text)); 
   } 
  BEGIN(tagComment);
}

<tagComment>.|\n {
  // found end of comment block
  if(!g_parseCode){
   strComment+=verilogScanYYtext;
   VhdlDocGen::prepareComment(strComment);
   handleVerilogCommentBlock(strComment,FALSE,iDocLine);
   unput(*verilogScanYYtext);
   }
   
   if(g_parseCode) // && !Config_getBool("STRIP_CODE_COMMENTS"))
   { 
     qlist.append(new QCString(verilogScanYYtext)); 
   } 

   strComment.resize(0);
   BEGIN(Start);
}


<*>"//%"[^\n]* { // one line comment
  if (iDocLine==-1) iDocLine=yyLineNr;
  QCString qcs(verilogScanYYtext);
 if(!g_parseCode){
   VhdlDocGen::prepareComment(qcs);
   //printf("--> handleCommentBlock line %d\n",yyLineNr);
   Entry* pTemp=VerilogDocGen::getEntryAtLine(curRoots,iDocLine);
                            
  if (pTemp)
  {
    pTemp->briefLine=yyLineNr;
    pTemp->brief+=qcs;
    iDocLine=-1;
  }
  else
  {
    handleVerilogCommentBlock(qcs,TRUE,iDocLine);
  }
   //printf("--> end: handleCommentBlock line %d\n",yyLineNr);
  //  bufferClear();
 }//if
  if(g_parseCode) // && !Config_getBool("STRIP_CODE_COMMENTS"))
   { 
     qlist.append(new QCString(verilogScanYYtext)); 
   } 

} 


<Start>{COMMENT} {
       QCString text(verilogScanYYtext); 
					  int b=text.contains(vlogComment);
					  if(b && !g_parseCode){  
                       strComment+=verilogScanYYtext;
                        if (iDocLine==-1) iDocLine=yyLineNr;
                         VhdlDocGen::prepareComment(strComment);
                   
                         if(multLineComment){
                          handleVerilogCommentBlock(strComment,FALSE,iDocLine);
                          multLineComment=false;
                         }
                         else{
                              Entry* pTemp=VerilogDocGen::getEntryAtLine(curRoots,iDocLine);
                              if (pTemp){
                                     pTemp->briefLine=iDocLine;
                                     pTemp->brief+=strComment;
                                     strComment.resize(0);
                                     iDocLine=-1;
                                }
                            else
                            handleVerilogCommentBlock(strComment,true,iDocLine);
                          }//else 
                         }
                           strComment.resize(0);      
                         
					 
					 if(g_parseCode)
					 { 
				               qlist.append(new QCString(verilogScanYYtext));
					 } 
					 c_lval.ctype=verilogScanYYtext[0];
                   }

<Start>{STRING}    {
                  //   fprintf(stderr,"\n [%s : %c %d] string\n",verilogScanYYtext,verilogScanYYtext[verilogScanYYleng-2],verilogScanYYleng);
                      QCString temp(verilogScanYYtext);
                      
                      if((verilogScanYYleng > 2) && verilogScanYYtext[verilogScanYYleng-2] != 92) {
                      addText(verilogScanYYtext,verilogScanYYleng);
                      if(!g_parseCode)
                        yyLineNr+=temp.contains('\n');
                      if(g_parseCode) 
                       {
                        qlist.append(new QCString(temp.data()));
                        c_lval.ctype=verilogScanYYtext[0];
                       }
                      
                      return  STRING_TOK;
                      }
                      if(verilogScanYYleng == 2){ 
                         if(g_parseCode) { qlist.append(new QCString(verilogScanYYtext)); }   
                        return  STRING_TOK;
                        } 
                     unput(verilogScanYYtext[verilogScanYYleng-1]);
                     yymore();
                     }

<Start>"\t"|"\r" {
                   if(yytext[0]=='\t'){
                    if(!g_parseCode)
                    parseToken(" ");
                   else
                    parseToken(verilogScanYYtext);
                  }
                  c_lval.ctype=' ';} 

<Start,EndOfText>[\n] {
   	   		// fprintf(stderr,"\nparse line of code : [line: %d]",yyLineNr);
               addToken("\n");
              
			   if(g_parseCode){
			     qlist.append(new QCString(verilogScanYYtext));
			   } 
                else
	           yyLineNr+=QCString(verilogScanYYtext).contains('\n');
	           c_lval.ctype=verilogScanYYtext[0];
               }

<Start>[ ]+  { parseToken(verilogScanYYtext);}
<Start>[0-9]+|[0-9][0-9_]+|[0-9]+{BASE}[0-9a-zA-Z_?]+|[0-9]+"."[0-9eE]+|{BASE}[0-9a-zA-Z_?]+|['][01xz] {
                                                      addText(verilogScanYYtext,verilogScanYYleng);
                                                      if(verilogScanYYleng>1023){
                                                        strncpy(c_lval.cstr,verilogScanYYtext,1023);
                                                        c_lval.cstr[1023]='\0';
                                                      }
                                                      else{
                                                      strncpy(c_lval.cstr,verilogScanYYtext,verilogScanYYleng);
                                                      c_lval.cstr[verilogScanYYleng]='\0';
                                                      }
                                                      if(g_parseCode) qlist.append(new QCString(verilogScanYYtext)); 
					                                  return  DIGIT_TOK;
                                                     }

<Start>[a-zA-Z]+|[_a-zA-Z$][_a-zA-Z0-9$]+ {
						                 addText(verilogScanYYtext,verilogScanYYleng);
						   	           // yyPrevLine=yyLineNr;
										 if(g_parseCode){ 
										   qlist.append(new QCString(verilogScanYYtext));
						                  }
						                   if(verilogScanYYleng>1023){
                                                        strncpy(c_lval.cstr,verilogScanYYtext,1023);
                                                        c_lval.cstr[1023]='\0';
                                                      }
                                             else{      
						                         strncpy(c_lval.cstr,verilogScanYYtext,verilogScanYYleng);
                                                 c_lval.cstr[verilogScanYYleng]='\0'; 
						                         }
						                  c_lloc.first_line=yyLineNr;
						                  return  LETTER_TOK;
                                         }

 
<Start>.  {
   c_lval.ctype=verilogScanYYtext[0];
  REJECT;

 }         

<Start>"(*"   {  parseToken(verilogScanYYtext);  return   ATL_TOK;}
<Start>"*)"   {  parseToken(verilogScanYYtext);  return   ATR_TOK;}
<Start>"~^"   {  parseToken(verilogScanYYtext);  return   SNNOT_TOK;}
<Start>"^~"   {  parseToken(verilogScanYYtext);  return   NOTSN_TOK;}
<Start>"&&&"   {  parseToken(verilogScanYYtext);  return   AAAND_TOK;}
<Start>"&&"   {  parseToken(verilogScanYYtext);  return   AAND_TOK;}
<Start>"<<<"   {  parseToken(verilogScanYYtext);  return   LLLT_TOK;}
<Start>"<<"   {  parseToken(verilogScanYYtext);  return   LLT_TOK;}
<Start>">>>"   {  parseToken(verilogScanYYtext);  return   GGGT_TOK;}
<Start>">>"   {  parseToken(verilogScanYYtext);  return    GGT_TOK;}
<Start>"||"   {  parseToken(verilogScanYYtext);  return   OOR_TOK;}
<Start>"!"   {  parseToken(verilogScanYYtext);  return   EXCLAMATION_TOK;}
<Start>";"   {  parseToken(verilogScanYYtext); return  SEM_TOK;}
<Start>"."   {  parseToken(verilogScanYYtext);  return  DOT_TOK;}
<Start>","   {  parseToken(verilogScanYYtext); return  COMMA_TOK;}
<Start>"?"   {  parseToken(verilogScanYYtext);return  QUESTION_TOK;}
<Start>"+"   {  parseToken(verilogScanYYtext);return  PLUS_TOK;}
<Start>"++"   {  parseToken(verilogScanYYtext);return  PPLUS_TOK;}
<Start>"--"   {  parseToken(verilogScanYYtext);return  DMINUS_TOK;}
<Start>"-"   {  parseToken(verilogScanYYtext);return  MINUS_TOK;}
<Start>":"   {   parseToken(verilogScanYYtext); return  COLON_TOK;}
<Start>"::"   {   parseToken(verilogScanYYtext); return  CCOLON_TOK;}
<Start>".*"   {   parseToken(verilogScanYYtext); return  DOTMULT_TOK;}
<Start>"("   { parseToken(verilogScanYYtext);if(g_parseCode) { c_lval.cstr[0]=' ';} return  LBRACE_TOK;}
<Start>")"   { parseToken(verilogScanYYtext);return  RBRACE_TOK;}
<Start>"}"   { parseToken(verilogScanYYtext);return  RRAM_TOK;}
<Start>"{"   { parseToken(verilogScanYYtext);return  LRAM_TOK;}
<Start>"["   {  parseToken(verilogScanYYtext);return  LBRACKET_TOK;}
<Start>"]"   { parseToken(verilogScanYYtext);return  RBRACKET_TOK;}
<Start>"&"   { parseToken(verilogScanYYtext);return  AND_TOK;}
<Start>"|"   { parseToken(verilogScanYYtext); return  OR_TOK;}
<Start>"="   { parseToken(verilogScanYYtext);  return  EQU_TOK;}
<Start>"==="   { parseToken(verilogScanYYtext);  return  EEEQU_TOK;}
<Start>"=?="   { parseToken(verilogScanYYtext);  return  EQU_Q_EQU_TOK;}
<Start>"!?="   { parseToken(verilogScanYYtext);  return  EX_Q_EQU_TOK;}
<Start>"!=="   { parseToken(verilogScanYYtext);  return  EX_EQU_EQU_TOK;}
<Start>"<"   { parseToken(verilogScanYYtext); return  GT_TOK;}
<Start>"=>"   { parseToken(verilogScanYYtext); return  EQULT_TOK;}
<Start>">"   { parseToken(verilogScanYYtext);return  LT_TOK;}
<Start>"->"   { parseToken(verilogScanYYtext);return  MINUSLT_TOK;}
<Start>"|->"   { parseToken(verilogScanYYtext);return  PROPLT_TOK;}
<Start>"|=>"   { parseToken(verilogScanYYtext);return  PROPEQU_TOK;}
<Start>"^"   { parseToken(verilogScanYYtext);return  NOT_TOK;}
<Start>"~"   { parseToken(verilogScanYYtext); return  SN_TOK;}
<Start>"*"   {parseToken(verilogScanYYtext);return  MULT_TOK;}
<Start>"%"   { parseToken(verilogScanYYtext); return  PERCENTAL_TOK;}
<Start>"@" { parseToken(verilogScanYYtext);return  AT_TOK;}
<Start>"#" { parseToken(verilogScanYYtext);	return  PARA_TOK;}
<Start>"##" { parseToken(verilogScanYYtext);	return  DOUBLEPARA_TOK;}
<Start>"$" {  parseToken(verilogScanYYtext); return  DOLLAR_TOK;}
<Start>"'" { if(g_parseCode) parseToken(verilogScanYYtext); return  APOS_TOK;}
<Start>"/" {
 					  char c=yy_hold_char;
                         if(c !='/'){ 
						 parseToken(verilogScanYYtext);
						 return  ENV_TOK;
                         }
						 unput('/');// found "//"
						 REJECT;}

<Start>"/*" {
                 vbufreset(); 
				 addText(verilogScanYYtext,verilogScanYYleng);
				 if(yy_hold_char=='!') // found  comment starting with "/*!"
				  doxComment=true;
				 startComment=yyLineNr;
				 BEGIN(StartComment); 
				 }
<Start>"/" {
 					  char c=yy_hold_char;
                         if(c !='/'){ 
						 parseToken(verilogScanYYtext);
						 return  ENV_TOK;
                         }
						 unput('/');// found "//"
						 REJECT;}


<StartComment>[^*]*[*]+    {
                       QCString tt(verilogScanYYtext);
					   int len=tt.length();
					  if(!g_parseCode){
					   if(verilogScanYYtext[len-1]=='*' && tt.contains('\n'))
					        {
					         QCString ss=tt;
					         VhdlDocGen::deleteAllChars(ss,' ');
					         if(ss.data()  && ss.at(ss.length()-2)=='\n')
					         {
					          tt=tt.left(len-1);
					          len--;
					          }
					         }
					   }
					   addText(tt.data(),len);
                       char c=yy_hold_char;
                         if(c =='/'){
						   unput('*');
						   BEGIN(Commentt);
						 }
					     else BEGIN(StartComment);
					 }

<Commentt>"*/" {	 
						 
						  QCString *qq=new QCString(getVerilogString());
						  qq->append("*/");
                       
						  if(g_parseCode){ 
							   	 	qlist.append(qq);		
							}
							else{
				             if(doxComment){  
						      qq->stripPrefix("/*!");
						        *qq=qq->left(qq->length()-2);
						        handleVerilogCommentBlock(*qq,FALSE,startComment);
							    }
							   yyLineNr+=qq->contains('\n');
							 
							
							  doxComment=false;
							delete qq;
							}
                      	 vbufreset();
                         BEGIN(Start);
                }


%%

//------ ------------------------------------------------------------------------------------------------

// do parsing
 int MyParserConv::doLex()
 {
   int token;
 
   token=yylex();
   lastToken=token;
   return token;
  } 
 
 void resetScanner(const char* s,MyParserConv* parse) { }

 void setBuffer(char *text) 
 {
  vbufreset();
  addText (text,strlen(text));
 }


 void vbufreset() 
 {
  int i;
  i=getVerilogToken();
  memset(&g_buf[0],'\0',iSize);
  iSize=0;
  if(i==LETTER_TOK){
   lastLetter=verilogScanYYtext;
   }
  }

 void addToken (const char* s)
 {
   
    if(iSize>inputPosition)
	  {
	  vbufreset();
	 // assert(0);
	 }
   if(strlen(s)>1)
   {
    g_buf[iSize]=*s;
    iSize++;
    g_buf[iSize]=*s; 
   }
   else
      g_buf[iSize]=*s;   
      iSize++;
      g_buf[iSize]='\0'; 

 } 

 QCString getLastLetter(){ return lastLetter; }

 void  addText (char *word, int len)
 {
  	  while(len-->0)
        g_buf[iSize++]=*word++;
  
      g_buf[iSize]='\0'; 
  } 

const char* getVerilogString() {if(iSize) return &g_buf[0];return NULL;}
const char* getVerilogParsingFile(){return yyFileName.data();}


int getVerilogLine() { return yyLineNr; }
int getVerilogPrevLine() { return yyPrevLine; }
int getVerilogEndLine(){ return yyEndLine; }
int getVerilogState(){return verilogState;}
int getLastToken() {return lastToken;  }
char getNextToken() {return yy_hold_char; }

void VerilogScanner::resetCodeParserState(){}
bool VerilogScanner::needsPreprocessing(const QCString &extension){ return true; }
void VerilogScanner::parsePrototype(const char *text){ }


void VerilogScanner::parseInput(const char *fileName,const char *fileBuf,Entry *root)
{
     QCString pPuffer(" ");
	 pPuffer+=fileBuf;
	 if(!g_lexInit)
	 buildKeyMap();
	 inputFile.setName(fileName);

     
	 yyFileName=QCString(fileName);
	   if(g_lexInit)
		 verilogScanYYrestart( verilogScanYYin );
	   g_lexInit=TRUE;
	   curRoots=root;	
 	   initVerilogParser(curRoots,false);
       g_thisParser=this;
	   iSize=0;
       int len =inputFile.size();
       inputPosition=0;
	   g_buf=new char[len+1024];
       assert(g_buf);
       inString=pPuffer.data();
       g_inputLines  = countLines();
	   totLines=g_inputLines;
	   yyLineNr=1;
       pconv=new MyParserConv();
       resetScanner(NULL,pconv);
          groupEnterFile(fileName,yyLineNr);
     
       int ok=pconv->parse(pconv);
	 //  globalMemberList.clear();
	   qlist.clear();
	   VerilogDocGen::nestedClass.clear();
       VerilogDocGen::structList.clear();

	   delete [] g_buf;g_buf=0;
	   delete pconv;	  	  
}

 void VerilogScanner::parseCode(CodeOutputInterface &codeOutIntf,
                   const char *scopeName,
                   const QCString &input,
				   bool isExampleBlock,
                   const char *exampleName,
                   FileDef *fileDef,
                   int startLine,
                   int endLine,
                   bool inlineFragment,
                   MemberDef *memberDef
                  )
				  { 
				
                   QCString pPuffer(" ",1);
                   QCString ff(fileDef->getDefFileName());
                   BufStr preBuf(input.length());
                        
                   if (Config_getBool("ENABLE_PREPROCESSING") && startLine==-1)
                     {
                        if(ff.data())
                        fprintf(stderr,"\nPreprocessing file %s...\n",ff.data());
                        preprocessVerilogFile(ff,preBuf,0,-1);
                         preBuf.addChar('\0');
                       pPuffer+=preBuf.data();              
                  
                   }
                   else
                    pPuffer+=input.data();
                
                   initVerilogParser(0,true);
                   VerilogDocGen::buildGlobalVerilogVariableDict(fileDef,true);
                  
                  if(memberDef)// write code for function body
                   {
                    ClassDef *dd=memberDef->getClassDef();
	                if(dd)
	                g_CurrClass=dd->className();
                    VerilogDocGen::setCurrVerilogClass(g_CurrClass);
					startLine--;
                    pPuffer.prepend("~§~");
                   }
                      g_code = &codeOutIntf;
                      inString   = pPuffer.data();
                      inputPosition = 0;
					  iSize=0;
                      g_buf=new char[input.length()+1024];
                      assert(g_buf);
				  
					  g_currentFontClass = 0;
                      g_needsTermination = FALSE;
 
                      if (endLine!=-1)
                      g_inputLines  = endLine+1;
					    else
                      g_inputLines  = countLines();
                      totLines=g_inputLines;
				      if (startLine!=-1)
                        yyLineNr    = startLine;
                      else
                        yyLineNr    = 1;
                         g_exampleName   = exampleName;
                        g_sourceFileDef = fileDef;
                        yyFileName=fileDef->fileName();
                        if (isExampleBlock && fileDef==0)
                        {
                          // create a dummy filedef for the example
                         g_sourceFileDef = new FileDef("",exampleName);
                        }
 
                       if (g_sourceFileDef) 
                       {
                        setCurrentDoc(g_sourceFileDef->name(),g_sourceFileDef->getSourceFileBase());
                       }
 
                       g_currentDefinition = 0;
                       g_currentMemberDef = 0;
               
  
                      if (!g_exampleName.isEmpty())
                      {
                       g_exampleFile = convertNameToFile(g_exampleName+"-example");
                       }
  
                      g_includeCodeFragment = inlineFragment;
                        if(!memberDef) startCodeLine();
             
                     
  		             verilogScanYYrestart( verilogScanYYin );
				    g_parseCode=true;
                    MyParserConv conv;
 	                resetScanner(input.data(),&conv);
                     int ok=conv.parse(&conv);
					if (isExampleBlock && g_sourceFileDef)
                    {
                     // delete the temporary file definition used for this example
                       delete g_sourceFileDef;
                       g_sourceFileDef=0;
                    }
                   
				    printVerilogBuffer(true);
				  //  globalMemberList.clear();
				    g_parseCode=false;
				    delete [] g_buf;g_buf=0;
				   return;
                    }

//-------------------------------------------------------------------------------------------------------

//	parse 'include /'define
static void parseGlobalMember(){
        QCString tmp,args,name,comment;
		QCString qcs(getVerilogString());
        int specLine=yyLineNr;
        bool bInc=qcs.contains("`include"); 
       
        
        if(qcs.stripPrefix("`define") || qcs.stripPrefix("`include"))
	    {
         comment=checkVerilogComment(qcs);
           if(!comment.stripPrefix("//%"))
              comment.resize(0);
         QRegExp reg("[^a-zA-Z_0-9$]+");
		 qcs=qcs.stripWhiteSpace();
	     int ll=qcs.find(reg,0);
		 if(ll>0){
			 args=qcs.mid(ll,qcs.length());
		     name=qcs.left(ll);
			 }
		 
		 if(ll==-1)
		 {
            int len;
			QRegExp reg("[[a-zA-Z_][a-zA-Z_0-9$]+");
			int ll=reg.match(qcs,0,&len);
			int strlen=qcs.length();
			if(strlen==len)
				 name=qcs;
		 }
		  
		if(!comment.isEmpty())
        handleVerilogCommentBlock(comment,true,yyLineNr);
    
        if(bInc)
         {
          VhdlDocGen::deleteAllChars(qcs,'"');
          qcs.simplifyWhiteSpace();
          if(qcs.isEmpty())return;
          qcs=VerilogDocGen::getFileNameFromString(qcs.data());
          qcs.prepend(VhdlDocGen::getRecordNumber().data());
          Entry* pTemp=VerilogDocGen::makeNewEntry(qcs.data(),Entry::VARIABLE_SEC,VerilogDocGen::INCLUDE,yyLineNr,true);
          pTemp->type="include";
          return;
        }


         Entry* pTemp=NULL;
         int tok=getLastToken();
         if((tok==ENDMODUL_TOK ||tok==ENDPACKAGE_TOK || tok==ENDCLASS_TOK || tok==ENDINTERFACE_TOK || tok==ENDPROGRAM_TOK) && getCurrVerilog()!=0)
         {
          pTemp=new Entry;
          pTemp->bodyLine=defineLineContinue;
          pTemp->startLine=defineLineContinue;
          pTemp->name=name;
          pTemp->section=Entry::VARIABLE_SEC;
          pTemp->spec=VerilogDocGen::FEATURE;
          pTemp->vSpec=VerilogDocGen::FEATURE;;
          curRoots->addSubEntry(pTemp);
          pTemp->type="feature";
         }
         else
          pTemp=VerilogDocGen::makeNewEntry(name.data(),Entry::VARIABLE_SEC,VerilogDocGen::FEATURE,defineLineContinue,true);
         pTemp->args=args;
       //   printf("\n globalMem %s",args.data());
       
         pTemp->type="feature";

         if(getCurrVerilog()!=0) return; // found definition outside a module(not global)
         
         pTemp->spec=0;
         Entry *pNew=new Entry(*pTemp);
         globalMemberList.insert(pNew->name,pNew);
        }

}// parseGlobalMember


bool handleVerilogCommentBlock(const QCString &doc,bool brief,int iDoc)
{
  int position=0;
  bool needsEntry=FALSE;
   if(g_parseCode) return 0;
  Entry* curr=getCurrVerilogEntry();
  if(curr==NULL){
//  assert(0);
  curr=new Entry();
   curRoots->addSubEntry(curr);
  }
  Protection protection=Public;
  if (brief) 
    curr->briefLine = iDoc; 
  else 
    curr->docLine = iDoc;

 // printf("parseCommentBlock %p [%s]\n",curr,doc.data());
  while(parseCommentBlock(
	g_thisParser,
	curr,
	doc,        // text
	yyFileName, // file
	iDocLine,   // line of block start
	brief, 
	false,
	FALSE,
	protection,
     position,
     needsEntry
     )){
         if (needsEntry)
         {
         // fprintf(stderr,"\n<<need new entry in while%s>>",doc.data());
           VerilogDocGen::makeNewEntry(curr->name.data(),curr->section,curr->spec,0,true);
           }
        }
  
  if (needsEntry)
  {
    //fprintf(stderr,"\n<<need new entry %s>>",doc.data());
    VerilogDocGen::makeNewEntry(curr->name.data(),curr->section,curr->spec,0,true);
  }

  iDocLine=-1;
  return false;
}

// returns the stored member in the global list
// file : file in which the member is found

MemberDef* findGlobalMember(const QCString & file, const QCString& memName){
 MemberDef *md;
 bool ambig;
  FileDef *fd=findFileDef(Doxygen::inputNameDict,file,ambig);
  if(!fd) return NULL;
     MemberList * ml=fd->getMemberList(MemberList::allMembersList);
         
  if(ml==NULL) return NULL;
 
    MemberListIterator fmni(*ml);
     
	    for (fmni.toFirst();(md=fmni.current());++fmni)
        {
            if(md->getMemberSpecifiers()==0 || md->getMemberSpecifiers()==VerilogDocGen::FEATURE ){
             if(strcmp(md->name().data(),memName.data())==0) return md;  
		  }
		}//for
 return NULL;
}//findDefinition


MemberDef* findGlobalMember(const QCString& memName){
 QCString temp=memName;
 temp.stripPrefix("`");
  Entry* ee=globalMemberList.find(temp.data());  
		   if(ee){
	       QCString file=VerilogDocGen::getFileNameFromString(ee->fileName.data());
	        return findGlobalMember(file,temp);
	        }
	  
	  return NULL;      
  }
  
  
 void parseLib(char *str)
{
 QRegExp ep("[\t ]");
 QCString temp=str;

 temp.stripPrefix("library");
 QCString lib=temp.simplifyWhiteSpace();
 
 if(!g_parseCode)
 {
   yyLineNr+=temp.contains('\n');
   int i=lib.find(ep);
   //assert(i>0);
   if(i<=0) return;
   Entry* pTemp=VerilogDocGen::makeNewEntry(lib.left(i).data(),Entry::VARIABLE_SEC,VerilogDocGen::LIBRARY,yyLineNr);
   pTemp->type="library";
   Entry *pNew=new Entry(*pTemp);
   globalMemberList.insert(pNew->name,pNew);
   
}
else
  {
      // qlist.append(new QCString(verilogScanYYtext)); 
      printVerilogBuffer(true);
      writeFont("vhdlkeyword","library");
      codifyLines(temp.data());
  }

}//parseLib

QCString checkVerilogComment(QCString& q)
{
 
 int ll=q.contains("\\?");
 if(ll>1) return q;
 
  QCString comment;
  int j=q.find("//");
  if(j>0){
   comment=q.right(q.length()-j);
   q=q.left(j);
   return comment;
  }
  
  int k=q.find("/*");
  int l=q.find("*/");
  
  if((k>0) &&(l>k) )
  {
   comment=q.right(q.length()-k);
   q=q.left(k);
  }
  return comment;
}

 void composeString(QCString& q)
{
  QRegExp ep("[`a-zA-Z0-9_]+");
  QRegExp ep2("[\\s]+");
 //  j = reg.match(temp.data(),0,&len);
 int len;
 int j=ep.match(q.data(),0,&len );
 while(j>=0){
 QCString left=q.left(len);
  qlist.append(new QCString(left.data())); 
  q=q.right(q.length()-len);
  
  j=ep2.match(q.data(),0,&len);
  
  if(j>=0)
  {
   left=q.left(len);
   qlist.append(new QCString(left.data())); 
   q=q.right(q.length()-len);
  }
  
 j=ep.match(q.data(),0,&len);
 }
if(!q.isEmpty()) 
 qlist.append(new QCString(q.data())); 
}

static void writeInclude(QCString inc)
{
   if(inc.isEmpty())  return;
   int i=inc.find("\"");
   int j=inc.findRev("\"");
   
   if(i>=0 && j>i)
   {
    QCString first=inc.left(i+1);
    QCString third=inc.right(inc.length()-j);
    QCString mid=inc.mid(i+1,j-i-1);
    QCString ff=VerilogDocGen::getFileNameFromString(mid.data());
    bool ambig;
     FileDef *fd=findFileDef(Doxygen::inputNameDict,ff,ambig);
     if(fd)
     {
       g_code->codify(first.data());
       g_code->writeCodeLink(fd->getReference(),
	                      fd->getOutputFileBase(),
			              fd->fileName(),
			              mid.data(),0
			              );
       g_code->codify(third.data());  
     }
     else
      writeWord(inc.data());
 
   }
}
       
void writeDefineString(const char* str)
{
 static QRegExp reg("[^_a-zA-Z0-9]+");
 QCString qcs(str);
 int u=qcs.find(reg);
 
 int len=qcs.length();
 
 while(!qcs.isEmpty())
 {
  int j,len;
  j = reg.match(qcs.data(),0,&len);
   
   if(j==-1)
   {
     qlist.append(new QCString(qcs.data()));
     return;
   }
   
   if(j>0)
   {
     QCString tt=qcs.left(j);
     qlist.append(new QCString(tt.data()));
     tt=qcs.mid(j,len);
     qlist.append(new QCString(tt.data()));
     qcs.remove(0,len+j);
   }
   else 
   {
     QCString t=qcs.left(len);
     if(t.contains("//"))
     {
       while(qcs.stripPrefix(" "))
        qlist.append(new QCString(" "));
        
       qlist.append(new QCString(qcs.data())); 
       return;
     }
     qlist.append(new QCString(t.data()));
     qcs.remove(0,len);
    }  
   }// while
 }
       
void printLineString(QCString & str)
 {
  int u=str.find('\n'); 
   while(u>=0)
  {
   QCString left=str.left(u);
   writeFont("keyword",left.data());
   QCString t("\n");
   codifyLines(t.data());
   str.remove(u,1);
   str.stripPrefix(left.data());
   u=str.find('\n');               
  }
  if(str.data())
   writeFont("keyword",str.data());
 }       
 