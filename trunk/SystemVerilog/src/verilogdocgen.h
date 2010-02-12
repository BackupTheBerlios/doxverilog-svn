
/******************************************************************************
* Copyright (c) M.Kreis,2009 
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation; either version 2 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
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


#ifndef VerilogDocGen_h
#define VerilogDocGen_h

#include "entry.h"
#include "verilogscanner.h"
#include "vhdlscanner.h"
#include "qlist.h"
#include "definition.h"




//   wrapper class for the parser

class MyParserConv  
{
  
 public:
  uint iFileSize; 

  ~MyParserConv(){}
  MyParserConv(){}
  
 int parse(MyParserConv*);
 int doLex();
 
 
};


class DefMemVList : public DefinitionList
{
    public:
  
	int compareItems(GCI item1,GCI item2 )
	{
      Definition *d1=(Definition*)item1;
	  Definition *d2=(Definition*)item2;
	   
      int k = d1->getDefLine();
	  int l= d2->getDefLine();

      if(k==l) return 0;
	  if(k<l) return -1;
	  return 1;
	}
}; 


class VerilogDocGen  
{
public:
 
  static int          currState;
  static int          currVerilogType;
  static int          specType;

  static Entry        prevDocEntryVerilog;
  static Entry*       current;
  static Entry*		  current_rootVerilog  ;
  static Entry*       currentFunctionVerilog;
  static Entry*       lastModule;
  static Entry*		  currentVerilog ;

  static bool         parseCode; 
  static bool         generateItem;
  static bool         insideFunction;


  static QCString     currVerilogClass;
  static QCString     identVerilog; // last written word
  static QCString     currVerilogInst;
  static QCString     enumType;
  static QCString     signType;
  static QCString     sdataType;
  static QCString     portType;
  static QCString     paraType;
  static QCString     classQu;
  static QList<Entry> nestedClass;
  static QList<Entry> structList;
  static QCString     prevName; 
  static QCString     labelName;
  static bool inDecl;

 // enum VerilogClasses {ENTITYCLASS,PACKBODYCLASS,ARCHITECTURECLASS,PACKAGECLASS};
 	
  enum States {STATE_FUNCTION=0x100,STATE_MODULE,STATE_UDP,STATE_TASK,STATE_GENERATE,STATE_PROGRAM,STATE_INTERFACE,STATE_CLASS,STATE_COVER,STATE_PROPERTY,STATE_STRUCT};
 
	enum VerilogKeyWords
	{
	  MODULE=0x1000,
	  CLASS,
	  INTERFACE,
	  PROGRAM,
	  FUNCTION,
	  ENUMERATION,
	  STRUCT,
	  TYPEDEF_STRUCT,
	  TYPEDEF,
	  PACKAGE,
	  COVER,//0x100A
	  DATA_STRUCTURE,
	  FEATURE,
	  PRIMITIVE,
	  COMPONENT, 
	  PORT,// 0x100F
      PARAMETER,
	  ALWAYS,
	  TASK,
	  OUTPUT,
	  INPUT,
	  DEFPARAM,
	  SPECPARAM,// 0x1015
	  GENERATE,
	  INOUT,
	  INCLUDE,
	  TIME,
	  SIGNAL, // 0x101b
	  IMPORT,
	  REF,
	  EXPORT,
	  EXTENDS,
	  TIMEUNIT,
	  CONSTRUCTOR,
	  MODPORT,
	  COVERGROUP,
	  CONSTRAINT,
	  PROPERTY,
	  SEQUENCE,
	  NET_TYPE,
	  DATA_TYPE,
	  ATTRIB,
	  LIBRARY,
	  CONFIGURATION
	  };

// functions for  verilog parser ---------------------


static QCString convertTypeToString(int type,bool sing=true);

static void writeVerilogDeclarations(MemberList* ml,OutputList &ol,
               ClassDef *cd,NamespaceDef *nd,FileDef *fd,GroupDef *gd,
               const char *title,const char *subtitle,bool showEnumValues,int type);

static void writeVerilogDeclarations(MemberList* ml,OutputList& ol,GroupDef* gd,ClassDef* cd,FileDef* fd=NULL);

static void writePlainVerilogDeclarations(MemberDef* mdef,MemberList* mlist,OutputList &ol,
               ClassDef *cd,NamespaceDef *nd,FileDef *fd,GroupDef *gd,int specifier);

static void writeVerilogDeclarations(MemberDef* mdef,OutputList &ol,
                   ClassDef *cd,NamespaceDef *nd,FileDef *fd,GroupDef *gd,
                   bool inGroup);


// insert a new entry
static Entry* makeNewEntry(char* name=NULL,int sec=0,int spec=0,int line=0,bool add=true);

static MemberDef* findMember(QCString& className, QCString& memName,ClassDef *&,int line);

static MemberDef* findMemberDef(ClassDef* cd,QCString key,MemberList::ListType type,
                                ClassDef *&,int line);


static void setCurrVerilogClass(QCString&);

// returns the definition which is found in class
static MemberDef* findDefinition(ClassDef* cd,  QCString& memName);

// return the module/primitve name
static QCString getClassTitle(const ClassDef*);

// returns an integer if a keyword is found
static const QCString* findKeyWord(const char *str);

static void initEntry(Entry *e);

static QCString getFileNameFromString(const char* fileName);

static void adjustMemberName(QCString& nn); 
// returns the entry found at line
static Entry* getEntryAtLine(const Entry* ce,int line);

static void writeVHDLTypeDocumentation(const MemberDef* mdef, const Definition *d, OutputList &ol);
static void parseString();
static void writeDigit();
static void initVerilogParser();
static void parseModule(QCString & name);
static void parseFunction(Entry* e);
static void parseReg(Entry* e);
static void parsePortDir();
static void parseParam(Entry* e);
static void parseListOfPorts();
static void parseAlways(bool b=false);
static void parseModuleInst(QCString& first,QCString& sec);
static void parseEnum();
static void parseEnumeration(QCString);
static void parseSignal(QCString,bool net_type=false);
static void getResultSignal(QCString& ,QCString& );
static void parseListOfPorts(QCString& );
static void parseStruct(QCString& );
static void parseImport();
static void parseTypeDef();
static Entry* getPreviusClass();
static void getNameOfPrevClass(Entry *e);
static void resetTypes();
static void deleteVerilogClass();

static bool findExtendsComponent(QList<BaseInfo> *extend,QCString& compName);

static QCString getClassScopeName();
static void createStruct(const char * type);
static void parseAttribute(char*);
static void addFunction(const char*);

static bool findVerilogKey(const QCString q,const char* key);
static bool findDataType(const QCString &  word);

static void addModPort(const char*);
static void addSubEntry(Entry* root, Entry* e);
static void addConstructor(bool);
static void addProperty(int);
static void addCovergroup(int);
static void addVerilogClass(Entry *e);
static void addTypedef(const char*);
static void printIntMems(const ClassDef *cd) ;
static void printGlobalVars(const FileDef *fd) ;
static void buildGlobalVerilogVariableDict(const FileDef* fileDef,bool clear=FALSE,int level=0);
static void printAllMem(ClassDef *cd);
static bool findVerilogKeyWord(const QCString & word);



private:
static  void computeStruct(QCString mod);
};

// start prefix for each comment 

//% a one line comment

//% a 
//% multi line
//% comment 
static const char* vlogComment="//%";
//static int          currState;

#endif
