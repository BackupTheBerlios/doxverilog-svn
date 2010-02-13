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


#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <qintdict.h>
#include "verilogdocgen.h"
#include "verilogscanner.h"
#include "membergroup.h"
#include "vhdldocgen.h"
#include "doxygen.h"
#include "searchindex.h"
#include "commentscan.h"
#include "verilogparser.hpp"

#define CHECK(str) \
    if(str.isEmpty()) return;


 int   VerilogDocGen::currState;
 int   VerilogDocGen::currVerilogType;

 static bool bScope=false;


Entry* VerilogDocGen::current;
Entry* VerilogDocGen::currentFunctionVerilog=0;
Entry* VerilogDocGen::lastModule=NULL;
Entry* VerilogDocGen::currentVerilog=0  ;
Entry  VerilogDocGen::prevDocEntryVerilog;
Entry* VerilogDocGen::current_rootVerilog  ;

bool VerilogDocGen::parseCode=FALSE; 
bool VerilogDocGen::generateItem=false;
bool VerilogDocGen::insideFunction=false;

QCString     VerilogDocGen::currVerilogClass;
QCString     VerilogDocGen::identVerilog; // last written word
QCString     VerilogDocGen::currVerilogInst;
QCString     VerilogDocGen::enumType;
QCString     VerilogDocGen::signType;
QCString     VerilogDocGen::sdataType;
QCString     VerilogDocGen::portType;
QCString     VerilogDocGen::paraType;
bool         VerilogDocGen::inDecl;

QCString     VerilogDocGen::labelName;
QCString     VerilogDocGen::prevName; 
QCString     VerilogDocGen::classQu;

QList<Entry> VerilogDocGen::nestedClass;
QList<Entry> VerilogDocGen::structList;
DefMemVList defDict;

static int iLineNr=0;

static QDict<MemberDef> variableDict(10007);
static QDict<MemberDef> functionDict(5003);
static QDict<MemberDef> globalMemDict(5003);
static QList<MemberDef> includeMemList;
static QDict<MemberDef> classglobDict(17);
static QDict<ClassDef>  classInnerDict(17);


// sets the member spec variable for global variables
// needed for writing file declarations
static void setType(MemberList* ml);
static void writeEnumeration(OutputList& ol,const ArgumentList* al,const MemberDef* mdef);
static void writeFunctionProto(OutputList& ol,const ArgumentList* al,const MemberDef* mdef);
static void addTypes(Entry *pTemp,QCString array,QCString argType);
static QCString parseVerilogDataType(QCString port,QCString & type,QCString & args,QCString & equ);
static void writeFuncTaskDocu(const MemberDef *md, OutputList& ol,const ArgumentList* al);
void writeDocEnumeration(OutputList& ol,const ArgumentList* al,const MemberDef* mdef);

static void parseDefineConstruct(QCString&, MemberDef*,OutputList& ol);
static bool findIncludeName(const char*);
static void addInnerClasses(const FileDef *fd);
static MemberDef* findInnerClassMember(ClassDef *cd,QCString & name);
static MemberDef* findFileLink(QCString&,int);

Entry* VerilogDocGen::getEntryAtLine(const Entry* ce,int line)
{
  EntryListIterator eli(*ce->children());
  Entry *found=0;
  Entry *rt;
  for (;(rt=eli.current());++eli)
  {
    if (rt->bodyLine==line)
    {
      found=rt;
    } // if
    if (!found) 
    {
      found=getEntryAtLine(rt,line);
    }
  }
  return found;
}// getEntryAtLine


void VerilogDocGen::adjustMemberName(QCString& nn) 
{
  QRegExp regg("[_a-zA-Z]");
  int j=nn.find(regg,0);

  if (j>0)
   nn=nn.mid(j,nn.length());

 }//adjustRecordMember



QCString VerilogDocGen::convertTypeToString(int type,bool sing)
{
  uint ttype=(uint)type;
  switch(type){
 case(VerilogDocGen::PROGRAM) :
   if(sing)return "program";
   return "program"; 
 case(VerilogDocGen::PACKAGE) :
   if(sing)return "package";
   return "packages"; 
 case(VerilogDocGen::INTERFACE) :
   if(sing)return "interface";
   return "interface";
 case(VerilogDocGen::CLASS) :
   if(sing)return "class";
   return "classes";
 case(VerilogDocGen::STRUCT) :
   if(sing)return "struct";
   return "structures";  
 case(VerilogDocGen::MODULE) :
   if(sing)return "Module";
   return "Modules"; 
 case( VerilogDocGen::DATA_STRUCTURE): 
  if(sing)return "Data Structure";
  return "Data Structures";
 case( VerilogDocGen::ENUMERATION): 
  if(sing)return "Enumeration";
  return "Enumerations";
 case( VerilogDocGen::FUNCTION): 
  if(sing)return "Function";
  return "Functions";
 case( VerilogDocGen::TASK): 
  if(sing)return "Task";
  return "Tasks";
  case(VerilogDocGen::PRIMITIVE):
  if(sing)return "Primitive";
  return "Primitives";
  case(VerilogDocGen::PARAMETER):  
  if(sing) return "Parameter";
  return "Parameters";
  case(VerilogDocGen::COMPONENT): 
  if(sing) return "Component Instance";
  return "Component Instances";
  case( VerilogDocGen::PORT):
  if(sing) return "Port";
  return "Ports";
  case( VerilogDocGen::ALWAYS): 
  if(sing) return "Always Construct";
  else
  return "Always Constructs";
  case( VerilogDocGen::INPUT): 
  if(sing)return "Input";
  return "Inputs";
  case( VerilogDocGen::OUTPUT): 
  if(sing) return "Output";
  return "Outputs";
  case( VerilogDocGen::INOUT): 
  if(sing) return "Inout";
  return "Inouts";
   case(VerilogDocGen::FEATURE): 
   if(sing) return "Define";
  else
  return "Defines"; 
  case( VerilogDocGen::TIME): 
  return "Time"; 
  case( VerilogDocGen::INCLUDE): 
  if(sing) return "Include";
  return "Includes"; 
  case( VerilogDocGen::SIGNAL): 
  if(sing) 
    return "Signal";
  return "Signals";  
  case( VerilogDocGen::IMPORT): 
  return "Import";  
   case( VerilogDocGen::CONSTRUCTOR): 
  return "Constructor"; 
   case VerilogDocGen::MODPORT: 
  if(sing) 
    return "Modport";
	   return ("Modports"); 
   case (VerilogDocGen::COVER): 
  if(sing) 
    return "Covergroup";
	   return "Covergroups"; 
  case (VerilogDocGen::CONSTRAINT): 
  if(sing) 
    return "Constraint";
	  return "Constraints"; 
  case (VerilogDocGen::NET_TYPE): 
  if(sing) 
    return "Net Data Type";
	  return "Net Data Types"; 
  case (VerilogDocGen::DATA_TYPE): 
  if(sing) 
    return "Data Type";
	 return "Data Types"; 
  case (VerilogDocGen::ATTRIB): 
  if(sing) 
    return "Attribute";
	  return "Attributes"; 
  case (VerilogDocGen::TIMEUNIT): 
  if(sing) 
    return "Timeunit";
  return "Timeunits"; 
  case (VerilogDocGen::TYPEDEF): 
  if(sing) 
    return "Typedef";
  return "Typedefs"; 
   case(VerilogDocGen::LIBRARY): 
  if(sing) 
    return "Library";
  return "Libraries"; 
  case(VerilogDocGen::CONFIGURATION): 
  if(sing) 
    return "Configuration";
  return "Configurations"; 
  default: return "???";
  }
  return "";
 
} // convertType

 void setType(MemberList *ml){
  if (ml==0) return ;
  MemberDef *mdd=0;
  MemberList::ListType lt=ml->listType();
  MemberListIterator mmli(*ml);
  for ( ; (mdd=mmli.current()); ++mmli )
  {
 
/*
  QCString nk=mdd->typeString();
  if(mdd->getMemberSpecifiers() == 0 && nk!="`define" )
	  {
		 mdd->setMemberSpecifiers(VerilogDocGen::FEATURE);  
       printf("\n %d %s",mdd->getVerilogType(),mdd->name().data());
	  }

*/
	  if(mdd->getMemberSpecifiers() != 0) continue;	 
        mdd->setMemberSpecifiers(mdd->getVerilogType());    
   }
  } 
                    
 void VerilogDocGen::writeVerilogDeclarations(MemberList* ml,OutputList &ol,
               ClassDef *cd,NamespaceDef *nd,FileDef *fd,GroupDef *gd,
               const char *title,const char *subtitle,bool showEnumValues,int type) {


  MemberDef *mdd=NULL;
 // if(ml==NULL) return;
  MemberListIterator mmli(*ml);
  setType(ml);
 
if (!VhdlDocGen::membersHaveSpecificType(ml,type)) return;
  
  if (title) 
  {
    ol.startMemberSections();
	ol.startMemberHeader();
    ol.parseText(title);
    ol.endMemberHeader();
	ol.docify(" ");
  }
  if (subtitle && subtitle[0]!=0) 
  {
    //printf("subtitle=`%s'\n",subtitle);
    ol.startMemberSubtitle();
    ol.parseDoc("[generated]",-1,0,0,subtitle,FALSE,FALSE);
    ol.endMemberSubtitle();
  } 
  
  VerilogDocGen::writePlainVerilogDeclarations(mdd,ml,ol,cd,nd,fd,gd,type);
 
  if (ml->getMemberGroupList())
  {
    MemberGroupListIterator mgli(*ml->getMemberGroupList());
    MemberGroup *mg;
    while ((mg=mgli.current()))
    {
     // assert(0);
       if (VhdlDocGen::membersHaveSpecificType(mg->members(),type))
    
     {
      //printf("mg->header=%s\n",mg->header().data());
      bool hasHeader=mg->header()!="[NOHEADER]";
      ol.startMemberGroupHeader(hasHeader);
      if (hasHeader)
      {
        ol.parseText(mg->header());
      }
      ol.endMemberGroupHeader();
      if (!mg->documentation().isEmpty())
      {
        //printf("Member group has docs!\n");
        ol.startMemberGroupDocs();
        ol.parseDoc("[generated]",-1,0,0,mg->documentation()+"\n",FALSE,FALSE);
        ol.endMemberGroupDocs();
      }
      ol.startMemberGroup();
      //printf("--- mg->writePlainDeclarations ---\n");
      //mg->writePlainDeclarations(ol,cd,nd,fd,gd);
          VerilogDocGen::writePlainVerilogDeclarations(0,mg->members(),ol,cd,nd,fd,gd,type);
   
      ol.endMemberGroup(hasHeader);
		   }
      ++mgli;
    }
  }
 
 }// writeVerilogDeclarations



void VerilogDocGen::writePlainVerilogDeclarations(MemberDef* mdef,MemberList* mlist,OutputList &ol,
               ClassDef *cd,NamespaceDef *nd,FileDef *fd,GroupDef *gd,int specifier){

  
  ol.pushGeneratorState();

  bool first=TRUE;
  MemberDef *md;
  MemberListIterator mli(*mlist);
  for ( ; (md=mli.current()); ++mli )
  { 
	int mems=md->getMemberSpecifiers();
	bool b=md->isBriefSectionVisible();
	//md->isBriefSectionVisible();
    if ( mems==specifier)
    {
		if (first){ ol.startMemberList(),first=FALSE;}
			VerilogDocGen::writeVerilogDeclarations(md,ol,cd,nd,fd,gd,false);
    }//if
  }//for
  if (!first){ ol.endMemberList();ol.endMemberSections();} 
  
}//plainDeclaration

void VerilogDocGen::writeVerilogDeclarations(MemberList* ml,OutputList& ol,GroupDef* gd,ClassDef* cd,FileDef* fd){

	  VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::LIBRARY,FALSE),0,FALSE,VerilogDocGen::LIBRARY); 
	  VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::CONFIGURATION,FALSE),0,FALSE,VerilogDocGen::CONFIGURATION);   
	  VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::IMPORT,FALSE),0,FALSE,VerilogDocGen::IMPORT);
      VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::CONSTRUCTOR,FALSE),0,FALSE,VerilogDocGen::CONSTRUCTOR);
 	  VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::PORT,FALSE),0,FALSE,VerilogDocGen::PORT); 
      VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::MODULE,FALSE),0,FALSE,VerilogDocGen::MODULE);
      VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::FEATURE,FALSE),0,FALSE,VerilogDocGen::FEATURE);
      VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::INCLUDE,FALSE),0,FALSE,VerilogDocGen::INCLUDE);
	  VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::FUNCTION,FALSE),0,FALSE,VerilogDocGen::FUNCTION);
	  VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::ENUMERATION,FALSE),0,FALSE,VerilogDocGen::ENUMERATION);
      VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::DATA_STRUCTURE,FALSE),0,FALSE,VerilogDocGen::DATA_STRUCTURE);
      VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::STRUCT,FALSE),0,FALSE,VerilogDocGen::STRUCT);
      VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::ALWAYS,FALSE),0,FALSE,VerilogDocGen::ALWAYS);
      VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::TASK,FALSE),0,FALSE,VerilogDocGen::TASK);
      VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::INPUT,FALSE),0,FALSE,VerilogDocGen::INPUT);
      VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::INOUT,FALSE),0,FALSE,VerilogDocGen::INOUT);
      VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::OUTPUT,FALSE),0,FALSE,VerilogDocGen::OUTPUT);
      VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::PARAMETER,FALSE),0,FALSE,VerilogDocGen::PARAMETER);
      VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::COMPONENT,FALSE),0,FALSE,VerilogDocGen::COMPONENT);
      VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::SIGNAL,FALSE),0,FALSE,VerilogDocGen::SIGNAL);
	  VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::MODPORT,FALSE),0,FALSE,VerilogDocGen::MODPORT);
   //   VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::COVER,FALSE),0,FALSE,VerilogDocGen::COVER);
   //   VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::CONSTRAINT,FALSE),0,FALSE,VerilogDocGen::CONSTRAINT);
  

	  VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::NET_TYPE,FALSE),0,FALSE,VerilogDocGen::NET_TYPE);
	  VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::DATA_TYPE,FALSE),0,FALSE,VerilogDocGen::DATA_TYPE);
      VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::ATTRIB,FALSE),0,FALSE,VerilogDocGen::ATTRIB);
      VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::TIMEUNIT,FALSE),0,FALSE,VerilogDocGen::TIMEUNIT);
      VerilogDocGen::writeVerilogDeclarations(ml,ol,cd,0,fd,gd,VerilogDocGen::convertTypeToString(VerilogDocGen::TYPEDEF,FALSE),0,FALSE,VerilogDocGen::TYPEDEF);
  
 	 }


void VerilogDocGen::writeVerilogDeclarations(MemberDef* mdef,OutputList &ol,
                   ClassDef *cd,NamespaceDef *nd,FileDef *fd,GroupDef *gd,
                   bool inGroup) {
 
  static bool bComp=false;
  LockingPtr<MemberDef> lock(mdef,mdef);
 
  Definition *d=0;
  ASSERT (cd!=0 || nd!=0 || fd!=0 || gd!=0); // member should belong to something
 if (cd) d=cd; else if (nd) d=nd; else if (fd) d=fd; else d=gd;
//if (cd) d=cd;
  // write tag file information of this member
 int memType=mdef->getMemberSpecifiers();

  if (!Config_getString("GENERATE_TAGFILE").isEmpty())
  {
    Doxygen::tagFile << "    <member kind=\"";
    Doxygen::tagFile << VerilogDocGen::convertTypeToString(memType);
     
    Doxygen::tagFile << "\">" << endl;
    Doxygen::tagFile << "      <type>" << convertToXML(mdef->typeString()) << "</type>" << endl;
    Doxygen::tagFile << "      <name>" << convertToXML(mdef->name()) << "</name>" << endl;
    Doxygen::tagFile << "      <anchorfile>" << convertToXML(mdef->getOutputFileBase()+Doxygen::htmlFileExtension) << "</anchorfile>" << endl;
    Doxygen::tagFile << "      <anchor>" << convertToXML(mdef->anchor()) << "</anchor>" << endl;
  
	if(memType==VerilogDocGen::FUNCTION)
		Doxygen::tagFile << "      <arglist>" << convertToXML(VhdlDocGen::convertArgumentListToString(mdef->argumentList().pointer(),true)) << "</arglist>" << endl;
    else if(memType==VerilogDocGen::ALWAYS)
		Doxygen::tagFile << "      <arglist>" << convertToXML(VhdlDocGen::convertArgumentListToString(mdef->argumentList().pointer(),false)) << "</arglist>" << endl;
	else{
	Doxygen::tagFile << "      <arglist>" << convertToXML(mdef->argsString()) << "</arglist>" << endl;
   Doxygen::tagFile << "      <arglist>" << convertToXML(mdef->typeString()) << "</arglist>" << endl; 
    }
	mdef->writeDocAnchorsToTagFile();
    Doxygen::tagFile << "    </member>" << endl;
 
  }
  
  // write search index info
  if (Config_getBool("SEARCHENGINE"))
  {
    Doxygen::searchIndex->setCurrentDoc(mdef->qualifiedName(),mdef->getOutputFileBase(),mdef->anchor());
    Doxygen::searchIndex->addWord(mdef->localName(),TRUE);
    Doxygen::searchIndex->addWord(mdef->qualifiedName(),FALSE);
  }

  QCString cname  = d->name();
  QCString cfname = mdef->getOutputFileBase();

 // HtmlHelp *htmlHelp=0;
//  bool hasHtmlHelp = Config_getBool("GENERATE_HTML") && Config_getBool("GENERATE_HTMLHELP");
//  if (hasHtmlHelp) htmlHelp = HtmlHelp::getInstance();

  // search for the last anonymous scope in the member type
  ClassDef *annoClassDef=mdef->getClassDefOfAnonymousType();

  // start a new member declaration
  bool isAnonymous = annoClassDef; // || m_impl->annMemb || m_impl->annEnumType;
  ///printf("startMemberItem for %s\n",name().data());
  if(mdef->getMemberSpecifiers()==VerilogDocGen::FEATURE)
   ol.startMemberItem(3); //? 1 : m_impl->tArgList ? 3 : 0);
  else
   ol.startMemberItem( isAnonymous ); //? 1 : m_impl->tArgList ? 3 : 0);


  // If there is no detailed description we need to write the anchor here.
  bool detailsVisible = mdef->isDetailedSectionLinkable();
  if (!detailsVisible) // && !m_impl->annMemb)
  {
     QCString doxyName=mdef->name().copy();
    if (!cname.isEmpty()) doxyName.prepend(cname+"::");
    QCString doxyArgs=mdef->argsString();
    ol.startDoxyAnchor(cfname,cname,mdef->anchor(),doxyName,doxyArgs);

    ol.pushGeneratorState();
    ol.disable(OutputGenerator::Man);
    ol.disable(OutputGenerator::Latex);
    ol.docify("\n");
    ol.popGeneratorState();
    
  }
// *** write type
     /*Verilog CHANGE */
   VhdlDocGen::adjustRecordMember(mdef); 
  
   QCString ltype(mdef->typeString()); 
   QCString largs(mdef->argsString());
   QCString arr(mdef->getReadAccessor());
   int mm=mdef->getMemberSpecifiers();

   ClassDef *kl=NULL;
   FileDef *fdd=NULL;
   LockingPtr<ArgumentList> alp = mdef->argumentList();
   QCString nn;
   uint i=0;
   QRegExp ep=QRegExp("_1_1");
   if(gd)gd=NULL;
   switch(mm)
   {
   case VerilogDocGen::IMPORT: 
		 ltype=mdef->name();
		 ltype.replace(ep,"::");
		 VhdlDocGen::deleteAllChars(ltype,' ');
		 mdef->setName(ltype.data());
		 VhdlDocGen::writeLink(mdef,ol);
		 break;
   case VerilogDocGen::INCLUDE: 
     bool ambig;
     largs=mdef->name();
     fdd=findFileDef(Doxygen::inputNameDict,largs.data(),ambig);
     if(fdd){
      QCString fbb=fdd->getFileBase();
      fbb=fdd->getReference();
     fbb= fdd->getOutputFileBase();
     fbb=fdd->getSourceFileBase();
     fbb=fdd->convertNameToFile(largs.data(),true);
     fbb=fdd->getPath();
     fbb+=fdd->getOutputFileBase()+".html";
   
       ol.writeObjectLink(fdd->getReference(),
                     fdd->getOutputFileBase(),
		     0,
		     fdd->name());
	}
	else
	 VhdlDocGen::formatString(largs,ol,mdef);	
	
        break;
	case VerilogDocGen::FEATURE: 
       	parseDefineConstruct(largs,mdef,ol);
		break;
	case VerilogDocGen::MODULE: 
       	ol.startBold();
        VhdlDocGen::formatString(ltype,ol,mdef);
        ol.endBold();
		ol.insertMemberAlign();
	   //writeLink(mdef,ol);
	case VerilogDocGen::MODPORT:
		VhdlDocGen::writeLink(mdef,ol);
		break;
	case VerilogDocGen::PORT:
		  VhdlDocGen::writeLink(mdef,ol);
		 ol.insertMemberAlign();
		  if(largs.length()>0)
		    VhdlDocGen::formatString(largs,ol,mdef);
          if(ltype.length()>0)
		    VhdlDocGen::formatString(ltype,ol,mdef);	  
		  break;
    case VerilogDocGen::ALWAYS:
	     VhdlDocGen::writeLink(mdef,ol);  
	     ol.insertMemberAlign();
		 writeFunctionProto(ol,alp.pointer(),mdef);
		break;
	case VerilogDocGen::ENUMERATION:
  
		 VhdlDocGen::writeLink(mdef,ol);  
	   	  ol.docify("  ");// need for pdf has no effect in html
		// ol.insertMemberAlign();
		 if(ltype.length()>0)
		    VhdlDocGen::formatString(ltype,ol,mdef);
	 	   writeEnumeration(ol,alp.pointer(),mdef);
		 break;
	case VerilogDocGen::TYPEDEF:
		if(largs.length()>0)
		{
			 largs.stripPrefix("typedef");
			  VhdlDocGen::formatString(largs,ol,mdef);
		}
          ol.docify(" ");// need for pdf has no effect in html
		  ol.insertMemberAlign();
		  VhdlDocGen::writeLink(mdef,ol);  
	  
		break;
	case VerilogDocGen::CONSTRUCTOR:
	case VerilogDocGen::FUNCTION:
    case VerilogDocGen::TASK:      
         if(ltype.length()>0)
		    VhdlDocGen::formatString(ltype,ol,mdef);
          ol.docify(" ");// need for pdf has no effect in html
		  VhdlDocGen::writeLink(mdef,ol);  
	   	    ol.insertMemberAlign();
	 	   writeFunctionProto(ol,alp.pointer(),mdef);
		  break;
     case VerilogDocGen::ATTRIB:
        if(ltype=="sequence" || ltype=="constraint" || ltype=="property" || ltype =="covergroup")
		{
		    VhdlDocGen::formatString(ltype,ol,mdef);
			ol.insertMemberAlign();
            VhdlDocGen::writeLink(mdef,ol);  
			ol.docify(" ");
            VhdlDocGen::formatString(largs,ol,mdef);
		} else {
           if(largs.length()>0)
		    VhdlDocGen::formatString(largs,ol,mdef);
           ol.docify(" ");
       	    ol.insertMemberAlign();
           VhdlDocGen::writeLink(mdef,ol);  
            ol.docify(" ");
			VhdlDocGen::formatString(arr,ol,mdef); 
			if(ltype)
				ol.docify("=");
			VhdlDocGen::formatString(ltype,ol,mdef);
		}
	   break;
   case VerilogDocGen::NET_TYPE:
   case VerilogDocGen::SIGNAL:
   case VerilogDocGen::DATA_TYPE:
   case VerilogDocGen::TIMEUNIT: 
          if(largs.length()>0)
		    VhdlDocGen::formatString(largs,ol,mdef);
           ol.docify(" ");
       	    ol.insertMemberAlign();    
            VhdlDocGen::writeLink(mdef,ol);  
            ol.docify(" ");
			VhdlDocGen::formatString(arr,ol,mdef); 
			if(ltype)
				ol.docify("=");
			VhdlDocGen::formatString(ltype,ol,mdef);
			
        break;
   case VerilogDocGen::INPUT:
   case VerilogDocGen::OUTPUT:
   case VerilogDocGen::INOUT:
   case VerilogDocGen::PARAMETER:
	   if(largs.length()>0){
		    VhdlDocGen::formatString(largs,ol,mdef);
         ol.insertMemberAlign();
	   }else
        ol.insertMemberAlign();
      
	   VhdlDocGen::writeLink(mdef,ol);  
    	 ol.insertMemberAlign();
		
	    VhdlDocGen::formatString(arr,ol,mdef);  
		 ol.docify(" ");
		 if(ltype.data()) ol.docify("=");
		 ol.docify(" ");
		 VhdlDocGen::formatString(ltype,ol,mdef);
		
	 break;
	
     case VerilogDocGen::COMPONENT:
		 //VhdlDocGen::writeLink(mdef,ol);
	 if(true) {	
		nn=mdef->name().lower();
		kl=getClass(ltype);
	    ol.startBold();
	    QCString inst=ltype+"::"+mdef->name();
        ol.writeObjectLink(mdef->getReference(),  mdef->getOutputFileBase(),mdef->anchor(),inst.data());
        ol.docify("  ");
        ol.endBold();
       	ol.insertMemberAlign();
	
		if(kl) 
		{
		 nn=kl->getOutputFileBase();
	 	 ol.pushGeneratorState();
         ol.disableAllBut(OutputGenerator::Html);
         ol.docify("   ");
		 QCString name=kl->getNameFromClassType();//VerilogDocGen::getClassTitle(kl);
	     ol.startBold();
		 ol.docify(name.data());
		 ol.endBold();
		 ol.startEmphasis();
		 ol.docify(" ");
 	     ol.writeObjectLink(kl->getReference(),kl->getOutputFileBase(),0,ltype);
		 
	     ol.endEmphasis();
         ol.popGeneratorState();
		}
     
	  if(largs=="generate") 
	  {
		ol.pushGeneratorState();
		ol.docify(" [");
        ol.disableAllBut(OutputGenerator::Html);
        ol.docify(largs.data());
		ol.docify("]");
		ol.popGeneratorState();
	  }
	 }
		break;
	case VerilogDocGen::STRUCT:    
		ol.startBold();
	 if (!largs.isEmpty()) 
	    VhdlDocGen::formatString(largs,ol,mdef);
	 else{ 
	      VhdlDocGen::writeLink(mdef,ol);
          ol.docify("     : struct");
	      break;
	  }
	  
	  ol.insertMemberAlign();
      
	  if (!largs.isEmpty()) 
	      VhdlDocGen::writeLink(mdef,ol);
	  if (!ltype.isEmpty()) {
		  ol.docify("=");
	   VhdlDocGen::formatString(ltype,ol,mdef);
	  }
      ol.endBold();
      break;
     

  default: break;
   }

   bool htmlOn = ol.isEnabled(OutputGenerator::Html);
  if (htmlOn && Config_getBool("HTML_ALIGN_MEMBERS") && !ltype.isEmpty())
  {
    ol.disable(OutputGenerator::Html);
  }
  if (!ltype.isEmpty()) ol.docify(" ");
  
  if (htmlOn) 
  {
    ol.enable(OutputGenerator::Html);
  }

  if (!detailsVisible)// && !m_impl->annMemb)
  {
    ol.endDoxyAnchor(cfname,mdef->anchor());
  }

  //printf("endMember %s annoClassDef=%p annEnumType=%p\n",
  //    name().data(),annoClassDef,annEnumType);
  ol.endMemberItem();
   if (!mdef->briefDescription().isEmpty() &&   Config_getBool("BRIEF_MEMBER_DESC") /* && !annMemb */)
  {
    ol.startMemberDescription();
    ol.parseDoc(mdef->briefFile(),mdef->briefLine(),mdef->getOuterScope()?mdef->getOuterScope():d,mdef,mdef->briefDescription(),TRUE,FALSE);
    if (detailsVisible) 
    {
      ol.pushGeneratorState();
      ol.disableAllBut(OutputGenerator::Html);
      //ol.endEmphasis();
      ol.docify(" ");
      if (mdef->getGroupDef()!=0 && gd==0) // forward link to the group
      {
        ol.startTextLink(mdef->getOutputFileBase(),mdef->anchor());
      }
      else // local link
      {
        ol.startTextLink(0,mdef->anchor());
      }
      ol.endTextLink();
      //ol.startEmphasis();
      ol.popGeneratorState();
    }
    //ol.newParagraph();

    ol.endMemberDescription();
     if(VhdlDocGen::isComponent(mdef))
      ol.lineBreak();
  }
   mdef->warnIfUndocumented();

  }// end writeVerilogDeclaration


// returns the name of module/primitive

QCString VerilogDocGen::getClassTitle(const ClassDef* cdef){
if(cdef->protection()==Public)
  return cdef->className()+" Module";
return cdef->className()+" Primitive";
}// getClassTitle


//-----------------< Code Parsing >------------------------------------------------


void buildVariableDict(ClassDef *cd)
{
   
if(cd==0) return;

MemberNameInfoSDict *memDict=cd->memberNameInfoSDict();
 variableDict.clear();

 if(memDict==NULL)
	 return;


 MemberNameInfoSDict::Iterator mnii(*memDict);
 

 MemberNameInfo *mni;
  for (mnii.toFirst();(mni=mnii.current());++mnii)
  {
    MemberInfo *mi=mni->first();
    while (mi)
    {
      MemberDef *md=mi->memberDef;
	//  printf("\n ++++ %s  ++++",md->name().data());
	  variableDict.insert(md->name().data(),md);	 
	  mi=mni->next();
	}
  }
}

MemberDef* VerilogDocGen::findMember(QCString& className, QCString& memName,ClassDef *& cdd,int line )
{
	ClassDef* cd;
	//return 0;
	MemberDef *mdef=NULL;

	//printf("\n %s",memName.data());
	// printf("\n search: %s %d",memName.data(),globalMemDict.count());

	bool feat=false;

  
	cd=getClass(VerilogDocGen::currVerilogClass.data());
  //  if(!cd) return NULL;
  //   printAllMem(cd);
	//if(cd) printAllMem(cd);

    // printf("\n search < %s >",memName.data());

    if(memName.contains('`'))
     memName.stripPrefix("`");
   
	 mdef=VerilogDocGen::findMemberDef(cd,memName,MemberList::variableMembers,cdd,line);
     if(mdef) return mdef;
   
 //    mdef=VerilogDocGen::findMemberDef(cd,memName,MemberList::pubMethods,type,feat);
 //    if(mdef) return mdef;
   
//     QCString file=VerilogDocGen::getFileNameFromString(cd->getDefFileName().data());
//     mdef = findGlobalMember(file,memName);
	return mdef;

}//findMember




 MemberDef* VerilogDocGen::findMemberDef(ClassDef* cd,QCString key,MemberList::ListType type,ClassDef *& ccd,int line)
 {
    static QCString className;
	static QCString prevName;
    static ClassDef* sClass=0;

	MemberDef  *mem=NULL;

	if(cd==0)
	{       
 	  mem=globalMemDict.find(key.data());
	  if(mem) return mem;
	  return findFileLink(key,line);
	}
	className=cd->name();
	 
  if(prevName != className && !className.contains("::"))
  {
     prevName=className;
	 buildVariableDict(cd);
  }
  
  
  ClassDef* cc=NULL;
    
	  cc=classInnerDict.find(key.data());
   //   if(cc)
//		  printf("\n findClass %s",cc->name().data());
   
		  if(cc)
		  {
			  ccd=cc;
              sClass=cc;             
			  return 0;
		  }
	    	 
	  if(sClass)
	   {
		  mem=findInnerClassMember(sClass,key);
		  sClass=0;
		  if(mem) return mem;
	   }

      mem=findFileLink(key,line);
	  if(mem==0)
		  mem=variableDict.find(key.data());
	  if(mem)
	  { 
		  if(bScope)
		  {
		//	  printf("\n %s",mem->argsString());
			  QCString temp=mem->argsString();
			  QStringList ql=QStringList::split(' ',temp);
             	
			  uint size=ql.count();
			  if(size)
               temp=ql.last();
			  cc=getClass(temp.data());
			  if(cc)
				  sClass=cc;
		  }
		 return mem;
	  }
      mem=globalMemDict.find(key.data());
	  if(mem)
		 return mem;
	  	
 return NULL;

}//findMemberDef


MemberDef* VerilogDocGen::findDefinition(ClassDef *cd, QCString& memName){
 MemberDef *md;
 MemberList *ml=	cd->getMemberList(MemberList::variableMembers);
  if(ml==NULL) return NULL;
    MemberListIterator fmni(*ml);
     
	    for (fmni.toFirst();(md=fmni.current());++fmni)
        {
            if(md->getMemberSpecifiers()==VerilogDocGen::INCLUDE){
          
		
			ClassDef* cdef=getClass(md->name());
			 if(cdef){	 
			    MemberDef* mdd=VerilogDocGen::findMemberDef(cdef,memName,MemberList::variableMembers,cdef,0);
               MemberList *ml=	cdef->getMemberList(MemberList::variableMembers);
			   //assert(ml);
			   if(ml==NULL) return NULL;
			   if(mdd) return mdd;
			  MemberListIterator fmni(*ml);
      

			  //assert(false);
			 }
		  }
		}//for
 return NULL;
}//findDefinition

/*
MemberName* VerilogDocGen::findMemberNameSDict(QCString& mName,const QCString& className) 
{
MemberName *mn=0;
MemberDef *md;
  MemberNameSDict::Iterator mnli(*Doxygen::memberNameSDict);
  // for each member name
  for (mnli.toFirst();(mn=mnli.current());++mnli)
  {
    QCString temp(mn->memberName());
    VhdlDocGen::adjustMemberName(temp);
    if(stricmp(mName.data(),temp.data())==0){
      MemberNameIterator mni(*mn);
      for (mni.toFirst();(md=mni.current());++mni)
      {
        ClassDef *cd=md->getClassDef();
        if(cd){
         QCString nn=cd->displayName();
         if(stricmp(nn.data(),className.data())==0)
          return mn;
        }
      }
    }//if 
  }
  
  return 0;
  }//findMemberNameSdict
*/

void VerilogDocGen::initEntry(Entry *e)
{
  e->fileName +=getVerilogParsingFile();
  initGroupInfo(e);
}


void writeFuncTaskDocu(const MemberDef *mdef, OutputList& ol,const ArgumentList* al){
  if (al==0)return;
  ArgumentListIterator ali(*al);
  Argument *arg;
  
  bool sem=FALSE;
  int len=al->count();
  
  if(len==0){ ol.startBold();ol.docify("()");ol.endBold(); return;}
  
  ol.startBold();
  ol.docify(" ( ");    
  ol.endBold();
  
  bool first=TRUE;
  ol.startParameterList(FALSE); 
  
  for (;(arg=ali.current());++ali)
  {
  
	ol.startParameterType(first,"");  
	ol.startBold();
    
    QCString nn=arg->name;
    VerilogDocGen::adjustMemberName(nn);
    QCString qargs=arg->type;
    QCString att=arg->defval;
	QCString range=arg->attrib;
    if (!nn.isEmpty()) 
    { 
      const QCString* str=VerilogDocGen::findKeyWord(nn.data());
      nn+=" ";
	  if (str==0)
	 VhdlDocGen::formatString(nn,ol,mdef);
      else
		  VhdlDocGen::startFonts(nn,str->data(),ol);         
    }  
	if (!att.isEmpty()) 
    { 
 	VhdlDocGen::formatString(att,ol,mdef);
    if(range.data())
		VhdlDocGen::formatString(range,ol,mdef);
	//  else
    }  
	if(qargs.data()){
     ol.docify(" = ");
    const QCString* str=VerilogDocGen::findKeyWord(qargs.data());
   // ol.startEmphasis();
    if (str==0)
      VhdlDocGen::formatString(qargs,ol,mdef);
    else
      VhdlDocGen::startFonts(qargs,str->data(),ol);         
 	}
    
	if (--len)
		ol.docify(" , ");
	else
		ol.docify(")");

    sem=TRUE;        
    first=FALSE;  
    ol.endBold();
  	
	ol.endParameterName(FALSE,FALSE,FALSE); 
     
  }// for
  
  ol.endParameterList();
} // writeDocFunProc


void writeDocEnumeration(OutputList& ol,const ArgumentList* al,const MemberDef* mdef)
{
  if (al==0) return;
  ArgumentListIterator ali(*al);
  Argument *arg;
  int len=al->count();
  
  //ol.insertMemberAlign();
 
  bool first=true;
  ol.startParameterList(false); 
 
  for (;(arg=ali.current());++ali)
  {
    QCString nn=arg->name;
    VerilogDocGen::adjustMemberName(nn);
	ol.startParameterType(first,"");  
	ol.startBold();
    if(first) ol.docify("{");    
	 VhdlDocGen::formatString(nn,ol,mdef);
		
	if (--len )
      ol.docify(" , ");
	else
       ol.docify(" } ");
   ol.endBold(); 
    first=FALSE;  
    ol.endParameterName(FALSE,FALSE,FALSE);   
  }
   
   ol.endParameterList();
}//writeDocEnumerationProcess

void writeEnumeration(OutputList& ol,const ArgumentList* al,const MemberDef* mdef)
{
  if (al==0) return;
  ArgumentListIterator ali(*al);
  Argument *arg;
  int len=al->count();
  
  ol.insertMemberAlign();
  ol.startBold();
  ol.docify(" { ");    
  bool first=true;
  bool liBreak=(len>3);
  if(liBreak) 
	  ol.docify("\n");
  for (;(arg=ali.current());++ali)
  {
    QCString nn=arg->name;
    VerilogDocGen::adjustMemberName(nn);
	VhdlDocGen::formatString(nn,ol,mdef);
		
	if (--len )
      ol.docify(" , ");
      
   if(liBreak)
	   ol.docify("\n");
  }
   
   ol.docify(" } ");
   ol.endBold();  
 
}//writeEnumeration



 /*!
 * writes a function/Task prototype to the output
 */

void writeFunctionProto(OutputList& ol,const ArgumentList* al,const MemberDef* mdef)
{
  if (al==0) return;
  ArgumentListIterator ali(*al);
  Argument *arg;
  bool sem=FALSE;
  int len=al->count();
  ol.startBold();
  ol.docify(" ( ");    
  ol.endBold();
  if (len>2)
  {
    ol.docify("\n");
	
  }
  for (;(arg=ali.current());++ali)
  {
    ol.startBold();
    if (sem && len < 3)
    {
    
		ol.docify(" , ");
    }
   
	QCString nn=arg->name.simplifyWhiteSpace();
    VerilogDocGen::adjustMemberName(nn);
    QCString qargs=arg->type;
    QCString att=arg->defval;
	QCString range=arg->attrib;
    if (!nn.isEmpty()) 
    { 
      const QCString*  str=VerilogDocGen::findKeyWord(nn.data());
      nn+=" ";
	  if (str==0)
	 VhdlDocGen::formatString(nn,ol,mdef);
      else
		  VhdlDocGen::startFonts(nn,str->data(),ol);         
    }  
	if (!att.isEmpty()) 
    { 
     // int str=VerilogDocGen::findKeyWord(att.data());
    //  att+=" ";
    //  if (str==0)
	VhdlDocGen::formatString(att,ol,mdef);
    if(range.data())
		VhdlDocGen::formatString(range,ol,mdef);
	//  else
//	VhdlDocGen::startFonts(att,"vhdlchar",ol);         
    }  
	if(qargs.data()){
 ol.docify(" = ");
    //VhdlDocGen::startFonts("in ","stringliteral",ol);
    const QCString* str=VerilogDocGen::findKeyWord(qargs.data());
   // ol.startEmphasis();
    if (str==0)
      VhdlDocGen::formatString(qargs,ol,mdef);
    else
      VhdlDocGen::startFonts(qargs,str->data(),ol);         
  //   ol.endEmphasis();
	}
     sem=TRUE;    
    ol.endBold();
    if (len > 2)    
    {
      ol.docify("\n");
    }
  }
  ol.startBold();    
  ol.docify(" )");  
  ol.endBold();
  
}
 
  QCString VerilogDocGen::getFileNameFromString(const char* fileName){
  
  QCString qfile(fileName);
    QStringList ql=QStringList::split('/',qfile);
    return (QCString)ql.last();
  
  }

//-------------------------------------------------------------------------------------------------------------------------

// extracts module/primitive name

void VerilogDocGen::parseModule(QCString & name){
 
 CHECK(name);
	if(name.isEmpty()) return;
 if(parseCode) {
 //generateVerilogClassOrGlobalLink(mod.data());
  QCString className;
  ClassSDict::Iterator cli(*Doxygen::classSDict);
  ClassDef *cd;
  for (cli.toFirst() ; (cd=cli.current()) ; ++cli )
  {
   // printf("\n -------------------------class----------------------------------------\n");
    className =cd->className();
	if(className==name) break;
	int index=className.findRev("::");
	if(index > 0){
	   QCString cl=className.right(className.length()-index-2);
	   if(cl==name){
         currVerilogClass = className;
		 return;
	   }
	}
  }
currVerilogClass=className;
 return;
 }
  currentVerilog->name=name;
 }//parseModuleName


// extracts module instances [ module_name name,module_name #(...) name]

void VerilogDocGen::parseModuleInst(QCString& first, QCString& sec) {
 
if(currVerilogType==VerilogDocGen::DEFPARAM  ) return;



 VhdlDocGen::deleteAllChars(sec,'(');
 VhdlDocGen::deleteAllChars(sec,')');
 VhdlDocGen::deleteAllChars(sec,' ');
 VhdlDocGen::deleteAllChars(sec,',');
 VhdlDocGen::deleteAllChars(sec,';');
 QCString temp=sec;
// while(sec.stripPrefix(" "));
// QCString fsdf=getVerilogString();
if(sec!=first && (sec.contains("#")==0))
{ 
 //QStringList ql=QStringList::split(first.data(),sec,false);
int oo=sec.findRev(first.data());
if(oo>0) 
 sec=sec.left(oo);
}
else
 sec=getLastLetter();

if(temp.contains("#"))
{ 
 int ii=temp.find("#");
 sec=temp.left(ii);
while(sec.stripPrefix(" "));
}

 if(parseCode){
    currVerilogInst=sec;
   return;
  }
 else {
  Entry* pTemp=VerilogDocGen::makeNewEntry(sec.data(),Entry::VARIABLE_SEC,VerilogDocGen::COMPONENT,c_lloc.first_line);
  pTemp->type=first;
 
  if(generateItem)
    pTemp->args="generate";
  else  
    pTemp->args="";
   
 
 if(sec==first)return;
if(currentVerilog)
 if(!findExtendsComponent(currentVerilog->extends,first)){	
  	BaseInfo *bb=new BaseInfo(first,Private,Normal);
    currentVerilog->extends->append(bb);						
   }
  }
}


void VerilogDocGen::parseListOfPorts() {
 
  QCString type;

 QCString mod(getVerilogString());
 
 VhdlDocGen::deleteAllChars(mod,' ');
 VhdlDocGen::deleteAllChars(mod,';');
 VhdlDocGen::deleteAllChars(mod,')');
 VhdlDocGen::deleteAllChars(mod,'(');
  QStringList ql=QStringList::split(",",mod,false);
  QCString name=(QCString)ql[0];
if(!parseCode) {
  for(uint j=0;j<ql.count();j++) {
  QCString name=(QCString)ql[j];
   int i=name.find('[');
  if(i > 0){
    type=mod.right(mod.length()-i);
    name=mod.left(i);
  }
  
 name.prepend(VhdlDocGen::getRecordNumber().data());
 Entry* pTemp=VerilogDocGen::makeNewEntry(name.data(),Entry::VARIABLE_SEC,VerilogDocGen::PORT,c_lloc.first_line);
  pTemp->type=type; 
   }
  return;
 }	

 }//parseListOfPorts



// sets the current parsing module (only for parsing inline_sources)             
void VerilogDocGen::setCurrVerilogClass(QCString& cl){ currVerilogClass = cl;}
 
void VerilogDocGen::parseReg(Entry* e){

// "wire"|"tri"|"tri1"|"supply0"|"wand"|"triand"|"tri0"|"supply1"|"wor"|"trior"|"trireg"

if(parseCode) return;     

if((generateItem || VerilogDocGen::currState==FUNCTION || VerilogDocGen::currState==TASK )) return;

QCString mod(getVerilogString());

 mod=mod.simplifyWhiteSpace(); 
  
 VerilogDocGen::parseSignal(mod,true);
 vbufreset();
 return;

} // parsReg


// extracts function/task prototype 

void VerilogDocGen::parseFunction(Entry* curF)
{
  QCString mod(getVerilogString());
  QCString type; 
 
 VhdlDocGen::deleteAllChars(mod,';');
  while(mod.stripPrefix(" "));
 
  int i=mod.findRev(']');
  if(i > 0){
    type=mod.left(i+1);
   	mod=mod.right(mod.length()-i-1);
  }
  else {
  QStringList ql=QStringList::split(" ",mod,false);
  if(ql.count()>1) {
    type=(QCString)ql[0];
	mod=(QCString)ql[1];
  }
  }
 
 VhdlDocGen::deleteAllChars(mod,' ');
 VhdlDocGen::deleteAllChars(type,' ');

  curF->name+=mod;
  if(type.stripPrefix("automatic"))
   curF->type+="automatic "+type; 
   else
  curF->type+=type;
}
							   

// extract (local)parameter declaration 

void VerilogDocGen::parseParam(Entry* e)
{
static QCString prevType;
QRegExp re("[a-zA-Z]");
bool bEnd=false;
QCString argType,temp,ltype,largs,lequ;
	
 if(parseCode) return;

  if((currState==DEFPARAM || currState==FUNCTION || currState==TASK  || generateItem)) return;
  
  QCString mod(getVerilogString());
  if(mod.isEmpty())return;
  if(!mod.contains(re))return;
  int u=mod.find('(');
  int v=mod.find('#');

  if(v>=0 && u>v)
	  mod=mod.right(mod.length()-u-1);

  bEnd=mod.contains(';');
  mod.remove(mod.length()-1,1);

mod=mod.simplifyWhiteSpace();
mod=parseVerilogDataType(mod,ltype,largs,lequ); 

  mod.prepend(VhdlDocGen::getRecordNumber().data());
  Entry* pTemp=VerilogDocGen::makeNewEntry(mod.data(),Entry::VARIABLE_SEC,PARAMETER,getVerilogPrevLine());
  //pTemp->fileName+=getVerilogParsingFile();
 if(ltype.isEmpty()) 
  pTemp->args=prevType;
 else{ 
 pTemp->args=ltype;
 prevType=ltype;
 }
  pTemp->type=lequ;
 if(bEnd) prevType.resize(0);

 pTemp->args.prepend("parameter ");

 vbufreset();
 portType.resize(0);
}


// extract  input/output ports

void VerilogDocGen::parsePortDir()
{

 bool bEnd=false;
static const QRegExp re("[a-zA-Z]");
static QCString prevType;
QCString argType,temp,ltype,largs,lequ;

int sec=0;

QCString port(getVerilogString());

if(port.isEmpty()) return;
if(!port.contains(re))
 return;

 bEnd=port.contains(';'); 
VhdlDocGen::deleteAllChars(port,';');
VhdlDocGen::deleteAllChars(port,',');



port=port.simplifyWhiteSpace();



if(parseCode) { vbufreset(); return; }
 
bool bTrue=(currState==MODULE || currState==INTERFACE || currState==CLASS || currState==PROGRAM); 
 if(!bTrue) return;

 VhdlDocGen::deleteAllChars(port,',');
 
 if(port.at(port.length()-1)==')') 
  port.remove(port.length()-1,1);

 if(port.at(0)=='(') 
  port.remove(0,1);

 if(port.at(0)=='{')
   port.remove(0,1);

 if(port.at(port.length()-1)=='}') 
  port.remove(port.length()-1,1);

 if(port.at(0)=='.'){
 int u=port.find('(');
 int v=port.find('[');
   if(u<1) return;
  
   if(v<1) port=port.right(port.length()-u-1);
   else 
   port=port.mid(u+1,v-u-1);
}

port=port.simplifyWhiteSpace();
portType=portType.simplifyWhiteSpace();


if(findVerilogKey(portType,"input")){
sec=INPUT; 
port.stripPrefix("input");
}
else if(findVerilogKey(portType,"output")){
sec=OUTPUT;  
port.stripPrefix("output");
}
else if(findVerilogKey(portType,"inout")){
sec=INOUT; 
port.stripPrefix("inout");
}
else
sec=PORT;

    port=parseVerilogDataType(port,ltype,largs,lequ); 
  // assert(port.data());
   CHECK(port)
       port.prepend(VhdlDocGen::getRecordNumber());
	   Entry* ee=VerilogDocGen::makeNewEntry(port.data(),Entry::VARIABLE_SEC,sec,c_lloc.first_line);
	  
	   
    
	   if(ltype.isEmpty()){
         ee->args=prevType;
	   }
	   else{
            ee->args=ltype;
 	        prevType=ltype;
	       }
       
	
	   if(portType=="interface"){
	    ee->args+=" [interface]";	  
	   }

		addTypes(ee,largs,lequ);    

		 if(sec>0 && (prevType != ltype)) prevType.resize(0);

 
  //assert(currVerilogType);
  //portType.resize(0);
  vbufreset();
}// parsePortDir

void VerilogDocGen::parseAlways(bool bBody)
{

	if(currState!=ALWAYS || generateItem) return ;

QRegExp regg1("[ \t]or[ \t]");

QCString mod(getVerilogString());
QCString type; 
QStringList ql;
bool sem=false;

 VhdlDocGen::deleteAllChars(mod,'@');
 VhdlDocGen::deleteAllChars(mod,'(');
 VhdlDocGen::deleteAllChars(mod,')');
 VhdlDocGen::deleteAllChars(mod,';'); 

if(mod.contains(","))
  ql=QStringList::split(",",mod,false);
 //else
 // ql=QStringList::split(regg1,mod,false);
 

if(!parseCode) {
 currentFunctionVerilog=VerilogDocGen::makeNewEntry(VhdlDocGen::getProcessNumber().data(),Entry::FUNCTION_SEC,ALWAYS);
  currentFunctionVerilog->stat=TRUE;
  currentFunctionVerilog->fileName=getVerilogParsingFile();
  if(!labelName.isEmpty())
      currentFunctionVerilog->name=labelName;
									
  if(ql.count()==0){
      Argument *arg=new Argument;
      arg->name=mod;	
	  currentFunctionVerilog->argList->append(arg);
      currentFunctionVerilog->args+=mod; 
	  return;
  }
  for(uint j=0;j<ql.count();j++) {
  QCString ll=(QCString)ql[j];
  if(sem)
	  currentFunctionVerilog->args+=',';

      
      Argument *arg=new Argument;
      arg->name=ll;	
	  currentFunctionVerilog->argList->append(arg);
      currentFunctionVerilog->args+=ll; 
      sem = true;
 }
 
 return;
}


}//parseAlways

void VerilogDocGen::writeDigit()
 {
   if(parseCode) {
     writePrevVerilogWords(identVerilog);
	 writeVerilogFont("vhdllogic",identVerilog.data());
	 identVerilog.resize(0);
	 printVerilogBuffer(true);
	 }
 }// writeDigit

// prints and links the parsed identifiers  

void VerilogDocGen::parseString(){				
					if(parseCode ) { 
					  //identVerilog=identVerilog.stripWhiteSpace();
				 		if(getNextToken()=='.' || getNextToken()==':')
						  bScope=true;
						else
                         bScope=false;

						writePrevVerilogWords(identVerilog);
						 bool b=false;
					 
					 if(currVerilogType==DEFPARAM){
				       QCString s(getVerilogString());
                       if(s.contains(".")==0)
                           b=generateVerilogMemLink(currVerilogClass,identVerilog,COMPONENT);
				       else if(s.contains("="))
                           b=generateVerilogMemLink(currVerilogClass,identVerilog,-1);
                       else
				         b=generateVerilogMemLink(currVerilogInst,identVerilog,-1);	       
				     }
					 else if(currVerilogType==COMPONENT){
					    QCString tt(getVerilogString());
					    if(tt.contains('('))
					     b=generateVerilogMemLink(currVerilogClass,identVerilog,PORT);
				        else if(!b)   
				         b=generateVerilogMemLink(currVerilogInst,identVerilog,PORT);
				        if(!b)   
				         b=generateVerilogMemLink(currVerilogClass,identVerilog,-1);    
					   }
				    /*
				      else if(currVerilogType==NETTYPE){
                       QCString tt(getVerilogString());
                      if(tt.contains("["))
                         b=generateVerilogMemLink(currVerilogClass,identVerilog,-1);
                       else{
                      	 codifyVerilogString(identVerilog.data(),"vhdlcharacter");
				         b=true;
				          }
                      	 }
				      */
				      else if(currVerilogType==PORT)
                        b=generateVerilogMemLink(currVerilogClass,identVerilog,PORT);
				     else if(currVerilogType==PARAMETER)
                        b=generateVerilogMemLink(currVerilogClass,identVerilog,PARAMETER);
				     else if(currVerilogType==SIGNAL)
                        b=generateVerilogMemLink(currVerilogClass,identVerilog,SIGNAL);
				     else if(currVerilogType==INPUT)
                        b=generateVerilogMemLink(currVerilogClass,identVerilog,INPUT);				       
         		     else if(currVerilogType==OUTPUT)
                        b=generateVerilogMemLink(currVerilogClass,identVerilog,OUTPUT);
				     else if(currVerilogType==INOUT)
                        b=generateVerilogMemLink(currVerilogClass,identVerilog,INOUT);
				   
				     else if(currVerilogType==ALWAYS)
                        b=generateVerilogMemLink(currVerilogClass,identVerilog,ALWAYS);
						
				     if(!b){
					   b =  generateVerilogMemLink(currVerilogClass,identVerilog,-1); 
					   if(!b && getClass(identVerilog.data()))
                       b=generateVerilogClassOrGlobalLink(identVerilog.data());
					  if(!b){
					   const QCString*  col=VerilogDocGen::findKeyWord(identVerilog.data());
					   if(col)
					    codifyVerilogString(identVerilog.data(),col->data());
					     else
					    codifyVerilogString(identVerilog.data(),"vhdlchar");
					   }   
					 }
					   printVerilogBuffer(true);
					  }
					prevName=identVerilog;
				   identVerilog.resize(0);
				 
}// parseString


void 
VerilogDocGen::parseEnum()
{

static QCString prevType;
static const QRegExp re("[a-zA-Z]");
static QCString type; 




if(parseCode) 
{ 
	vbufreset(); return; 
}

if(currState==VerilogDocGen::COVER) return;
if(currState==VerilogDocGen::COVERGROUP)
{ 
	signType+=getVerilogString(); return;
}


QCString mod(getVerilogString());
 
if(mod.isEmpty()) return;
if(!mod.contains(re)) return;
 
// fprintf(stderr,"\n en[%s]",mod.data());
 mod=mod.simplifyWhiteSpace();

 if(currVerilogType==ENUMERATION) 
	 parseEnumeration(mod);
 
 if(currVerilogType==SIGNAL && !currentFunctionVerilog && !insideFunction) 
	 parseSignal(mod);
 
 if(currState==VerilogDocGen::FUNCTION && currentFunctionVerilog)// && !insideFunction)
    parseListOfPorts(mod);
 
 if(currState==VerilogDocGen::STRUCT && currentFunctionVerilog)
 {
	VerilogDocGen::computeStruct(mod);
	portType="";
 }

vbufreset();
}// parseEnum


void 
VerilogDocGen::parseEnumeration(QCString en)
{
 
 static Entry *enumEntry=0;
 QRegExp regg("[{}]");
 QStringList ql;
 QCString q2;

 bool bTypedef=findVerilogKey(portType,"typedef");

 if(en.contains("{"))
 {
   
   enumEntry = VerilogDocGen::makeNewEntry("",Entry::FUNCTION_SEC,VerilogDocGen::ENUMERATION,c_lloc.first_line);
  
   ql=QStringList::split(regg,en,false);
   uint j=ql.count();
   //assert(j>1 && j<4);
   if(j==3){ 
   enumEntry->type+=(QCString)ql[0].simplifyWhiteSpace();
   q2=(QCString)ql[1].simplifyWhiteSpace();
   enumEntry->name =(QCString)ql[2].simplifyWhiteSpace();
   if(bTypedef) enumEntry->args+="typedef ";
   }
   else{
   q2=(QCString)ql[0].simplifyWhiteSpace();
   enumEntry->name =(QCString)ql[1].simplifyWhiteSpace();
   }
   VhdlDocGen::deleteAllChars(enumEntry->name,',');
   VhdlDocGen::deleteAllChars(enumEntry->name,';');  
   QStringList enumTypes=QStringList::split(",",q2,false);
  
   int i=enumTypes.count();
   
   for(int k=0;k<i;k++){
        Argument *arg=new Argument;
        arg->name=(QCString)enumTypes[k].simplifyWhiteSpace();
  	    enumEntry->argList->append(arg);
   }
 } else { /* copy  the first enum */
   VhdlDocGen::deleteAllChars(en,',');
   Entry* pTemp = VerilogDocGen::makeNewEntry(en.data(),Entry::FUNCTION_SEC,VerilogDocGen::ENUMERATION,c_lloc.first_line);
   pTemp->stat=TRUE;
   pTemp->type=enumEntry->type;
   ArgumentList * al=enumEntry->argList;
   int j=al->count();
   for(int k=0;k<j;k++){
      Argument *arg=(Argument*)al->at(k);
      Argument *argNew=new Argument;
      argNew->name=arg->name;
      pTemp->argList->append(argNew);
   }
   
}
}// parseEnumeration
 //---------------------------------------------------------------------------------------------------  


void 
VerilogDocGen::parseListOfPorts(QCString& port)
{
 
 static bool loops=false;
QCString argType,temp;
QRegExp regg("[\\s]");
 
if(currState==VerilogDocGen::FUNCTION){
 
 portType=portType.simplifyWhiteSpace();
 
 bool b = findVerilogKey(portType, "input")  ||  findVerilogKey(portType,"output") ||  findVerilogKey(portType,"inout") ;
 
 if(!b && insideFunction) return;
}

if(port.at(port.length()-1)==')') 
  port.remove(port.length()-1,1);
 
VhdlDocGen::deleteAllChars(port,',');
 
 if(port.contains('='))
 getResultSignal(port,argType);

 int nn=port.contains('[');
 int index=port.findRev("[");
	  if(nn>1){
      temp=port.right(port.length()-index);
	  port=port.left(index);
	  }

 QStringList qq=QStringList::split(regg,port,false);
 
 if(qq.count()==1 || (currState==VerilogDocGen::STRUCT && port.contains(';')))
 {
  VhdlDocGen::deleteAllChars(port,')');
 
 if(currState==VerilogDocGen::STRUCT){
   VhdlDocGen::deleteAllChars(port,';');
   if(enumType){
   int j=enumType.findRev(']');
    //assert(j>0);
    if(j<=0) return;
	QCString temp=enumType.right(enumType.length()-j-1);
    QCString temp1=enumType.left(j+1);
    port=temp.simplifyWhiteSpace();
    sdataType+=" ";
    sdataType+=temp1.simplifyWhiteSpace();
   }
 }
 
  Argument *arg=new Argument;
  arg->attrib=temp; 
  arg->defval=port; 
  arg->type=argType;                       
  arg->name=sdataType; //(QCString)ql[j];	
  currentFunctionVerilog->argList->append(arg);
  return;
 }
 
 port=port.simplifyWhiteSpace();
 enumType=enumType.simplifyWhiteSpace();
  
  if(enumType.data() && port.stripPrefix(enumType.data())){
   int i=enumType.findRev(']');
  // assert(i>0);
   if(i<=0) return;
   sdataType=enumType.left(i+1);
   port=enumType.right(enumType.length()-i-1);
   port=port.simplifyWhiteSpace();
   }
  else 
  {
     QStringList qq=QStringList::split(regg,port,false);
     uint len=qq.count();
     //assert(len>1);
	 if(len<=1) return;
     sdataType.resize(0);
     
     for(uint i=0;i<len-1;i++)
     {
       sdataType+=qq[i]+" ";
     }
     port=qq[len-1];
  }

  VhdlDocGen::deleteAllChars(port,')');
  Argument *arg=new Argument;
  arg->attrib=temp;
  VhdlDocGen::deleteAllChars(port,';');
  arg->defval=port;                          
  arg->name=sdataType;
  arg->type=argType;
  currentFunctionVerilog->argList->append(arg);

 }// parseListOfPorts
 

void 
VerilogDocGen::parseSignal(QCString port,bool net_type)
{

bool bEnd=false;
static QCString prevType;
int attrib;
QCString argType,temp,ltype,largs,lequ;

if(parseCode) return;

port=port.simplifyWhiteSpace();

int len=port.length();

if(port.at(0)==';')
{
 port.remove(0,1);
 port=port.simplifyWhiteSpace();
 len=port.length();
}

if(port.at(len-1)==';' && len)
{
 port.remove(len-1,1);
 bEnd=true;
}

if(port.at(len-1)==',' && len)
 port.remove(len-1,1);

  portType=portType.simplifyWhiteSpace();
  port=port.simplifyWhiteSpace();
  port=parseVerilogDataType(port,ltype,largs,lequ); 
  // assert(port.data());
  CHECK(port)
   if(net_type)
	   attrib=NET_TYPE;
   else if(VerilogDocGen::findDataType(portType))
	   attrib=DATA_TYPE;
   else
	   attrib=ATTRIB;

       port.prepend(VhdlDocGen::getRecordNumber());
	   Entry* ee=VerilogDocGen::makeNewEntry(port.data(),Entry::VARIABLE_SEC,attrib,c_lloc.first_line);
	   
	   if(!paraType.isEmpty())
		   prevType+=paraType;
	   
	   if(ltype.isEmpty())
	     ee->args=prevType;
	   else{
		   ee->args=ltype.simplifyWhiteSpace();
 	        prevType=ee->args;
	       }

	   if(!ee->args.contains(portType.data()))
	   {
		   ee->args.prepend(" ");
		   ee->args.prepend(portType.data());
	       
	   }
 
	   ltype=ltype.simplifyWhiteSpace();
	   int u=portType.find(ltype.data());
	  	  
	   if(u>0)
		   ee->args=portType;
     
	    u=portType.find(prevType.data());
	 
	   if(u>0)
		   ee->args=portType;




		addTypes(ee,largs,lequ);    
       
		if(bEnd)
		{
			portType.resize(0);
            prevType.resize(0);
		}
		paraType.resize(0);
}//parseSignal
 
void 
VerilogDocGen::getResultSignal(QCString& sigType,QCString& endResult) 
{
     //QRegExp regg1("[;=]");
     int index=sigType.find('=');
	 if(sigType.at(sigType.length()-1)==';')
		 sigType=sigType.remove(sigType.length()-1,1);
	 if(index<=0)
		  index++;
	 //assert(index>0);
	 if(index<=0) return;
	 endResult=sigType.right(sigType.length()-index-1).simplifyWhiteSpace();
     sigType=sigType.left(index).simplifyWhiteSpace();     
	  }

void 
VerilogDocGen::addConstructor(bool ports)
{
                      if(parseCode) return;
					   if(lastModule==0){
                         insideFunction=true;
						 return;
					   }
                         // assert(currentVerilog);
                          if(currentVerilog==NULL) return;
					      QCString className=currentVerilog->name;
						  CHECK(className)
                          currentFunctionVerilog=VerilogDocGen::makeNewEntry(className.data(),Entry::FUNCTION_SEC,VerilogDocGen::CONSTRUCTOR,getVerilogPrevLine());
						  currentFunctionVerilog->fileName=getVerilogParsingFile();
						 if(ports)
						  currState=VerilogDocGen::FUNCTION;
                          QCString qcs=getVerilogString();
						  int k=qcs.findRev('(');
						
						  if(k>0){
							  qcs=qcs.right(qcs.length()-k-1);						
							  setBuffer(qcs.data());
						  }
						  else
						      vbufreset();
                         
}// addConstructor


void 
VerilogDocGen::addProperty(int p)
{
  if(parseCode) return;
     
   QCString type;
 // assert(p != 1 && classQu.data() );
  switch(p)
  {
  case 0: 
     type="property";
	  break;
  case 1: 
	  classQu=getVerilogString();
	  VhdlDocGen::deleteAllChars(classQu,'{');
	  VhdlDocGen::deleteAllChars(classQu,';');
	  classQu=classQu.simplifyWhiteSpace();
	  CHECK(classQu)
	  type="constraint";
	  break;
  case 2:
	   type="sequence";
	  break;
  default: 
	  break;
  }

      QCString mod=getVerilogString();

      VhdlDocGen::deleteAllChars(mod,';');
      mod=mod.simplifyWhiteSpace();
      Entry* pTemp=VerilogDocGen::makeNewEntry(classQu.data(),Entry::VARIABLE_SEC,ATTRIB,c_lloc.first_line);
      pTemp->type=type;

	  if(type != "constraint")
	  pTemp->args=mod;	

 classQu.resize(0);
}


// adding covergroup declarations
void 
VerilogDocGen::addCovergroup(int cov)
{

if(VerilogDocGen::parseCode) return ;

CHECK(classQu)
Entry *ee=VerilogDocGen::makeNewEntry(classQu.data(),Entry::VARIABLE_SEC,VerilogDocGen::ATTRIB,c_lloc.first_line);
ee->args=signType;	
ee->type="covergroup";

classQu.resize(0);
signType.resize(0);
}

void 
VerilogDocGen::deleteVerilogClass()
{
 if(nestedClass.isEmpty()) return;
   Entry *cc=nestedClass.last();

  // if(cc)
  //	   printf("\n delelete Class:%s",cc->name.data());

    nestedClass.removeLast();
   
   if(!nestedClass.isEmpty()){
     lastModule=nestedClass.getLast();    
   } 
   else
     lastModule=0;
 
   if(parseCode)
	   VerilogDocGen::currVerilogClass=lastModule->name;
}


void 
VerilogDocGen::parseStruct(QCString& port)
{
 
 bool bEnd=false;
static QCString prevType;
QCString argType,temp,ltype,largs,lequ;

QRegExp regg("[\\s]");
  
 VhdlDocGen::deleteAllChars(port,',');

 bEnd=port.contains(';');

 if(port.at(0)=='{')
	 port.remove(0,1);

 temp=port;
 if((temp.stripPrefix("packed") || temp.stripPrefix("tagged") ) && temp.contains('{') && currentFunctionVerilog){
	 int j=port.find('{');

	 currentFunctionVerilog->read+=" "+port.left(j);
	 port=port.right(port.length()-j-1);
 }

  VhdlDocGen::deleteAllChars(port,')');
  VhdlDocGen::deleteAllChars(port,';');
 
   port=parseVerilogDataType(port,ltype,largs,lequ); 
   CHECK(port)

       port.prepend(VhdlDocGen::getRecordNumber());
       Entry* ee=VerilogDocGen::makeNewEntry(port.data(),Entry::VARIABLE_SEC,VerilogDocGen::STRUCT,c_lloc.first_line);
	   if(ltype.isEmpty())
	     ee->args=prevType;
	   else{
        ee->args=ltype;
        prevType=ltype;
	   }
       addTypes(ee,largs,lequ);             
}// parseStruct

void 
VerilogDocGen::getNameOfPrevClass(Entry *e)
{
	int len= nestedClass.count();
	if(len>1){
      Entry *temp=nestedClass.at(len-2);
	  if(!temp->name.isEmpty()){
		  e->name.prepend("::"); 
	      e->name.prepend(temp->name.data());
		  while(!structList.isEmpty()){
           Entry *ee=structList.getFirst();
		   ee->name.prepend("::"); 
	       ee->name.prepend(e->name.data());
		   structList.removeFirst();
		  }
	  }
	  else {
		  structList.prepend(e);
	  }
	}
	else if(len==1){
		structList.prepend(e);
		Entry *eTemp;
		QCString temp;// adding  scopes to nested classes/structures
	while(!structList.isEmpty()){
            Entry *ee=structList.getFirst();
			 temp=ee->name;
			QListIterator<Entry> eli(*ee->children());
			for (eli.toFirst();(eTemp=eli.current());++eli){		 
				if(eTemp->section==Entry::CLASS_SEC){
		        eTemp->name.prepend("::"); 
	            eTemp->name.prepend(temp.data());
		    }
			}//for
            structList.removeFirst();
		  }//while
	}
}

Entry* 
VerilogDocGen::getPreviusClass()
{
	int len = nestedClass.count();
	if(len>1)
      return nestedClass.at(len-2);	
  return NULL;
}

void 
VerilogDocGen::resetTypes()		   
 { 
     paraType.resize(0);
     portType.resize(0);
	 currState=0;
	 lastModule=0;	
	 deleteVerilogClass();
	 currentVerilog=lastModule;
	 currentFunctionVerilog=0;
 }

void 
VerilogDocGen::parseImport()
{

	QRegExp ep=QRegExp("::");
	
if(parseCode) { vbufreset(); return; }
QRegExp regg("[\\s,;]");
QCString mod(getVerilogString());
mod=mod.simplifyWhiteSpace(); 
 mod.stripPrefix("import");
if(mod.isEmpty()) return;
  QStringList qstr=QStringList::split(regg,mod,false);
  uint ll=qstr.count();
 // assert(ll>0);
   if(ll<0) return;
  for(uint u=0;u<ll;u++){
	QCString imp =  (QCString)qstr[u];
    imp.replace(ep,"_1_1");
	Entry* ee=VerilogDocGen::makeNewEntry(imp.data(),Entry::VARIABLE_SEC,VerilogDocGen::IMPORT,c_lloc.first_line);
    ee->type="Import";                       

  }
}

                                                                                                                                                  
	
void 
VerilogDocGen::addSubEntry(Entry* root, Entry* e) 
{
 if(e==NULL || root==NULL) return;
  root->addSubEntry(e);
 }



Entry* 
VerilogDocGen::makeNewEntry(char* name,int sec,int spec,int line,bool add)
{
 
  Entry *e=current;
 
 if(parseCode) // should not happen!
 assert(0);

if(add){ // features like 'include xxx or 'define xxx must not be inserted here
 if(lastModule)
    addSubEntry(lastModule,e); 
  else
    addSubEntry(current_rootVerilog,e); 
}
   if(line){
  	  e->bodyLine=line;
      e->startLine=line;
  }else
   {
     e->bodyLine=getVerilogPrevLine();
     e->startLine=getVerilogPrevLine();
   }
   
  e->section=sec;
  e->spec=spec;
  e->name=name;
  e->vSpec=spec;// needed for global types if global scope spec=0

  current=new Entry;
  VerilogDocGen::initEntry(current);
  
  return e;
 }

bool 
VerilogDocGen::findExtendsComponent(QList<BaseInfo> *extend,QCString& compName)
{
 for(uint j=0;j<extend->count();j++){
  BaseInfo *bb=extend->at(j);
  if(bb->name==compName)
   return true;
 }
 return false;
}// findExtendsComponent



void 
VerilogDocGen::addVerilogClass(Entry *e)
{
 if(e==0)return;
  VerilogDocGen::lastModule=e;
  VerilogDocGen::nestedClass.append(e);
}

 QCString parseVerilogDataType(QCString port,QCString & type,QCString & args,QCString& equ){
  // expression = [ equ ]
  // int clk[args]  
  // type = const ref|static const| reg signed[8:0]

 QRegExp regg("[\\s]");
 QCString name,temp;
 
// printf("port %s ",port.data());

 if(port.contains('=')) VerilogDocGen::getResultSignal(port,equ);


 int len=port.length();
 
 
 while(port.at(len-1)==']')
  {
     int i=port.findRev('[');
	 //assert(i>0);
	 if(i<=0) return "";
	 args.prepend(port.right(len-i).data());
	 port=port.left(i);
	 port=port.simplifyWhiteSpace();
	 len=port.length();
  }
 
  int i=port.findRev(']');
  if(i>0){
	 len=port.length();
	 name=port.right(len-i-1).simplifyWhiteSpace();
	 type=port.left(i+1).simplifyWhiteSpace();
  }
  else
  {
     QStringList qq=QStringList::split(regg,port,false);
     uint len=qq.count();
    // assert(len>1);
    
     for(uint k=0;k<len-1;k++)
     {
       type+=qq[k]+" ";
     }
	 name=qq[len-1].simplifyWhiteSpace();
  
  }//else

 return name;
 }// parseVerilogDataType

void addTypes(Entry *pTemp,QCString array,QCString argType) {
        pTemp->read=array;
		pTemp->type+=argType.data();
	}
 


void 
VerilogDocGen::parseTypeDef()
{
 if(parseCode) return; 

 if( currentFunctionVerilog && (findVerilogKey(currentFunctionVerilog->read,"struct") || findVerilogKey(currentFunctionVerilog->read,"union"))){ 
	                    currState=VerilogDocGen::STRUCT; 
                         parseEnum(); 
						 if(currentFunctionVerilog){
						 currentFunctionVerilog->read.prepend(" ");	 
						 }
 }
 else if(findVerilogKey(portType,"enum"))
 {
	 currVerilogType=VerilogDocGen::ENUMERATION;portType="typedef "; parseEnum();
 }
 else  {
        int o,p;
	    QCString mod(getVerilogString());
	    QCString q=mod;
		QRegExp regg("[\\s,;\\]]");
		while(((o=mod.find('['))>0) && ((p=mod.find(']'))>o))
		{
          mod=mod.remove(o,p-o+1);
		}
		QStringList qstr=QStringList::split(regg,mod,false);
		//assert(qstr.count()>0);
		if(qstr.count()==0) return;
		QCString name=(QCString)qstr[qstr.count()-1];
		Entry* tmp=VerilogDocGen::makeNewEntry(name.data(),Entry::VARIABLE_SEC,VerilogDocGen::TYPEDEF,c_lloc.first_line);
        int	 i=	q.findRev(name.data());
       // assert(i>=0);
		if(i<0) return;
		QCString qcs=q.left(i);
		qcs=qcs.simplifyWhiteSpace();
		tmp->args+="typedef "+qcs+paraType;  
         }																																						 
 	   enumType.resize(0);		
	   paraType.resize(0);
 } // parseTypeDef     

void 
VerilogDocGen::computeStruct(QCString mod)
{
 static bool endStruct=false;
    
 
  if(mod.at(0)=='}')
     endStruct=true;
    // VhdlDocGen::deleteAllChars(mod,' ');
     if(endStruct){
		 mod.remove(0,1);
		 //VhdlDocGen::deleteAllChars(mod,'}');
       if(mod.contains(';')){
        QCString args;
		endStruct=false;
		if(mod.contains('='))
		VerilogDocGen::getResultSignal(mod,args);
        VhdlDocGen::deleteAllChars(mod,';');
        lastModule->name+=mod;
		getNameOfPrevClass(lastModule);
		lastModule->bodyLine=c_lloc.first_line;
        lastModule->startLine=c_lloc.first_line;
		lastModule->write=args;
		deleteVerilogClass();
       }// sem
       else if(mod.contains(',')){
        int len=mod.length();   
        if(mod.at(len-1)==',')
			mod.remove(len-1,1);

		mod=mod.simplifyWhiteSpace();
		Entry *ee=new Entry(*currentFunctionVerilog);
               ee->section=Entry::CLASS_SEC;
               ee->spec=VerilogDocGen::STRUCT;
               ee->name=mod;
               ee->startLine=c_lloc.first_line;
               ee->bodyLine=c_lloc.first_line;  
               ee->type="struct";
			  
		
		Entry *tmp=getPreviusClass();
		if(tmp==NULL)
         VerilogDocGen::addSubEntry(current_rootVerilog,ee); // found global struct 
		else
		 VerilogDocGen::addSubEntry(tmp,ee); 
	  
		 getNameOfPrevClass(ee);
	   }  
     } 
     else 
     parseStruct(mod);
	 }//endStruct


void 
VerilogDocGen::createStruct(const char * type)
{



if(parseCode) return;

 currState=STRUCT;
 currentFunctionVerilog = VerilogDocGen::makeNewEntry("",Entry::CLASS_SEC,STRUCT,c_lloc.first_line);
 currentFunctionVerilog->type=type;
 currentFunctionVerilog->read=portType;
 portType.resize(0);
 vbufreset();
 addVerilogClass(currentFunctionVerilog);                
								
}// createStruct

bool VerilogDocGen::findVerilogKey(const QCString q,const char* s){
QRegExp re("[\\s\\[\\]\"]");

if(q.contains(s))
return true;

QCString key(s);
QStringList qq=QStringList::split(re,q);

if(qq.contains(key))
 return true;

return false;
}

void 
VerilogDocGen::parseAttribute(char* time_type)
{
if(parseCode) return;
QCString mod=getVerilogString();
mod=mod.simplifyWhiteSpace();
VhdlDocGen::deleteAllChars(mod,';');
QCString time(time_type);
time.prepend(VhdlDocGen::getRecordNumber());
Entry *ee=VerilogDocGen::makeNewEntry(time.data(),Entry::VARIABLE_SEC,TIMEUNIT,c_lloc.first_line);
ee->type=mod;
vbufreset();
}


void 
VerilogDocGen::addFunction(const char *str)
{
 if(parseCode)  return ;
                        if(insideFunction)  return ;
                         QCString funcName=getVerilogString();
						 bool bFunc=funcName.contains("::"); // class scope
                         QCString fname=str;
						
						 int j=funcName.findRev(fname.data());
												
						 if(bFunc)
							 {
						//	 printf("\n funcName %s",funcName.data());
							 int i=funcName.findRev("::");
							  fname=funcName.right(funcName.length()-j);
							  VhdlDocGen::deleteAllChars(fname,'(');
							 }
					//	QCString fname=str;
						  const char* ss="DPI";
                         if(lastModule || findVerilogKey(funcName,ss) ||  bFunc)
						 {
						    currState=FUNCTION;
						    currentFunctionVerilog=VerilogDocGen::makeNewEntry(fname.data(),Entry::FUNCTION_SEC,FUNCTION);
						    currentFunctionVerilog->fileName=getVerilogParsingFile();	
							currentFunctionVerilog->type+=VerilogDocGen::portType; 
						    currentFunctionVerilog->endBodyLine=c_lloc.first_line+1;
						 
							if(!bFunc && lastModule)
								currentFunctionVerilog->proto=true;
						  if(j>0)
						   {
							  funcName=funcName.left(j).simplifyWhiteSpace();
							  portType=portType.simplifyWhiteSpace();
							if(!portType.contains(funcName))
								{
						         if(findVerilogKey(funcName,portType.data()))
                                   currentFunctionVerilog->type=funcName;
						 	     else
                                   currentFunctionVerilog->type+=funcName;
								}
							}						 
						  }
						  
						  currVerilogType=0;
						 // currentFunctionVerilog=0;
                         					 
						  portType.resize(0);	                         
						  vbufreset();
 

}//addFunction


void 
VerilogDocGen::addModPort(const char* str)
{
if(parseCode) return;

QCString mod(str);
Entry* ee=VerilogDocGen::makeNewEntry(mod.data(),Entry::FUNCTION_SEC,MODPORT,c_lloc.first_line);
if(lastModule)
	{ 
	 ee->args=lastModule->name;
	 ee->type="modport";
	}
}//addModPort

void 
VerilogDocGen::addTypedef(const char* n)
 {
   
  if(parseCode) return;	 
   QCString tt=getVerilogString();
   VhdlDocGen::deleteAllChars(tt,';');
   tt=tt.simplifyWhiteSpace();
   VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL; 
   Entry * ee=VerilogDocGen::makeNewEntry(tt.data(),Entry::VARIABLE_SEC,VerilogDocGen::TYPEDEF,c_lloc.first_line);
   ee->args=VerilogDocGen::portType;
   vbufreset();
 }


 
/*!
 * writes a function|procedure documentation to the output
 */

// writeDocFunProc

  /* writes a vhdl type documentation */
void 
VerilogDocGen::writeVHDLTypeDocumentation(const MemberDef* mdef, const Definition *d, OutputList &ol)
{
  bool bNotSignal=false;
   QCString hh;

  ClassDef *cd=(ClassDef*)d;
  if (cd==0) return;
  
  bool bParseVerilogFunc=false;
  int specfier=mdef->getMemberSpecifiers();
  QCString na=mdef->name();
  QCString typ=mdef->typeString();
  QCString arge=mdef->argsString();
  QCString param=VhdlDocGen::trTypeString(specfier);
  
 if(specfier != VerilogDocGen::SIGNAL) {
    hh=VhdlDocGen::trTypeString(specfier);
    bNotSignal=true;
  }
   
   if(!mdef->isVariable())
    bParseVerilogFunc=true;

 if (bParseVerilogFunc)
  {
    MemberDef* memdef;
    QCString nn=mdef->name();
    nn=nn.stripWhiteSpace();
    QCString na=cd->name();
    memdef=VhdlDocGen::findMember(na,nn);
    if (memdef && memdef->isLinkable()) 
    { 
      ol.startBold();
	 

	  QCString ttype=mdef->typeString();
      ol.docify(" ");
	  VhdlDocGen::formatString(ttype,ol,mdef);
	  VhdlDocGen::writeLink(memdef,ol);
      ol.endBold();
      ol.docify(" ");
    }
    else
    {
      VhdlDocGen::formatString(typ,ol,mdef);
      ol.docify(" ");  
	  ol.docify(mdef->name());
	}
   if(specfier==ENUMERATION)   
	writeDocEnumeration(ol,mdef->argumentList().pointer(),mdef);
   else	
    writeFuncTaskDocu(mdef,ol, mdef->argumentList().pointer());
 }

  if (mdef->isVariable())
  { 
    if(specfier==ATTRIB && (typ =="constraint" || typ == "property" || typ=="sequence" || typ =="covergroup"))
	{
      VhdlDocGen::formatString(typ,ol,mdef);
      ol.docify(" ");
	  ol.startFontClass("stringliteral");
	  VhdlDocGen::writeLink(mdef,ol);
      ol.endFontClass();
	  ol.docify(" ");
      VhdlDocGen::formatString(arge,ol,mdef);
      return;
	}
      
      if(specfier==COMPONENT)
		  {
		  VhdlDocGen::writeStringLink(mdef,typ,ol);
		  ol.docify("::");
          VhdlDocGen::writeLink(mdef,ol);
		   return;
		  }
    
    if(specfier != VerilogDocGen::FEATURE) 	
	  VhdlDocGen::formatString(arge,ol,mdef);
	  ol.docify(" ");
	
      ol.startFontClass("stringliteral");
	  VhdlDocGen::writeLink(mdef,ol);
      ol.endFontClass();
  
      ol.docify(" ");
  
  if(specfier==VerilogDocGen::INCLUDE)
   return;

  if(specfier==VerilogDocGen::FEATURE)
   {
	 QCString arg=mdef->getDefinition();
	 int kr=arg.find("\\?");	  
     
	 if(kr>=0)
	 {
       arg=arg.left(kr);
	   arg.stripPrefix("feature");
	   arg=arg.simplifyWhiteSpace();
	   arg.stripPrefix(mdef->name().data());
	   arg.append(" { . . . }");
	   VhdlDocGen::formatString(arg,ol,mdef);
	 }
	 else{
     QCString ttype=mdef->typeString();
	 ttype.stripPrefix("feature");
	 VhdlDocGen::formatString(ttype,ol,mdef);
	 ol.docify(" ");
	 VhdlDocGen::formatString(arge,ol,mdef);
	 }
	return ;
    }
  
	if(specfier!=VerilogDocGen::FEATURE){
 	//if(arge.data()){
	//	 VhdlDocGen::formatString(typ,ol,mdef);
	//	 ol.docify(" ");
	// }
		if(param == "Import") return;
		if(param !="Module Instance" && typ.data()) {
		ol.docify("=");
	 VhdlDocGen::formatString(typ,ol,mdef);
		}
	}
  }
  }//write

void 
VerilogDocGen::printIntMems(const ClassDef *cd) 
{
 MemberNameInfoSDict *po=cd->memberNameInfoSDict();
			   if(po){
			    MemberNameInfoSDict::Iterator minf(*po);
			   MemberNameInfo *mni;

				for(minf.toFirst();mni=minf.current();++minf)
				{
			//		printf("\n< %s class %s>",mni->memberName(),cd->name().data());

				}
			   }

}

void 
printMem(MemberList *ml)
{
  if(ml==0) return;
//  printf("\n-----------------<Global Members>-----------------------------------------");
  
   MemberDef *mdef;
   MemberListIterator iter(*ml);
   for (iter.toFirst();mdef=iter.current(); ++iter)
   {
	//   printf("\n mem %s ",mdef->name().data());
   }
//  printf("\n-------------------------------------------------------------------");
}

void 
VerilogDocGen::printGlobalVars(const FileDef *fd)
{
	printMem(fd->getMemberList(MemberList::decVarMembers));
    printMem(fd->getMemberList(MemberList::decFuncMembers));
 
 //  decFuncMembers          = 43 + declarationLists,
 //  decVarMembers           = 44 + declarationLists,
      
}


void 
parseDefineConstruct(QCString & largs, MemberDef* mdef ,OutputList& ol)
{
        
//	QCString largs=mdef->getDefinition();
	    int kr=largs.contains("\\?");	  
	//	printf("\n defined: %s",largs.data());
	
	    ol.startBold();
        VhdlDocGen::writeLink(mdef,ol);
	    ol.docify(" ");
		ol.insertMemberAlign();
		ol.startTextBlock();
		if(kr>0)
		{
			largs=mdef->getDefinition();
			largs.stripPrefix("feature");
			while(largs.stripPrefix(" "));
			largs.stripPrefix(mdef->name().data());
			QStringList ql=QStringList::split("\\?",largs,false);
			for(uint i=0;i<ql.count();i++)
			{
			//	ol.startParagraph();
				QCString val=ql[i].data();			
				val+="\\";//ol.codify(val.data());
				if(val.contains("//") || (val.contains("/*") && val.contains("*/")))
					{
					 QCString tt=checkVerilogComment(val);
					 VhdlDocGen::formatString(val,ol,mdef);
					 if(tt.data())
					 writeVerilogFont("keyword",tt.data());
					}
				else 			
				 VhdlDocGen::formatString(val,ol,mdef);			
			    // ol.lineBreak();
				//	ol.endParagraph();
			}
		}
		else
		VhdlDocGen::formatString(largs,ol,mdef);
		ol.endTextBlock(true);
	  	ol.endBold();
}


static int llevel=0;

void 
VerilogDocGen::buildGlobalVerilogVariableDict(const FileDef* fd,bool clear,int level)
{
   if(fd==0)return;
   
   if(clear)
   {
     globalMemDict.clear();
     classInnerDict.clear();
   }

   addInnerClasses(fd);

   MemberDef *md=NULL;
   MemberList *ml=	fd->getMemberList(MemberList::decVarMembers);
   if(ml!=NULL) 
   {
   MemberListIterator fmni(*ml);
      
	for (fmni.toFirst();(md=fmni.current());++fmni)
	{
		VhdlDocGen::adjustRecordMember(md);
		if(stricmp(md->typeString(),"include")==0)
		if(!findIncludeName(md->name().data()))
		{
			//	printf("\n insert %s",md->name());	
			    includeMemList.append(md);
		}		    
//		printf("\n %s ....  ",md->name().data());
//		ClassDef *ch=md->getClassDef();
//		if(ch==0)
		globalMemDict.insert(md->name().data(),md);
	}
   }

   ml=	fd->getMemberList(MemberList::decFuncMembers);
   if(ml!=0)
   {
   MemberListIterator fmni(*ml);
   for (fmni.toFirst();(md=fmni.current());++fmni)
	{
		VhdlDocGen::adjustRecordMember(md);
		//if(md->getMemberSpecifiers()==VerilogDocGen::STRUCT)
//		printf("\n  ***** %s  **** ",md->name().data());
		globalMemDict.insert(md->name().data(),md);
	}
   }
   int icount=includeMemList.count();
   while(llevel<icount)
   {
	   bool ambig;
	   llevel++;
	   MemberDef* md=includeMemList.at(llevel-1);
	   FileDef* fd=findFileDef(Doxygen::inputNameDict,md->name().data(),ambig);
	   
	   if(fd)
	   {
		 //  printf("\n<--- search file: %s ---->",fd->name().data());
           buildGlobalVerilogVariableDict(fd,false,0);
	   }
	   icount=includeMemList.count();
   }
}

bool 
findIncludeName(const char* name)
{
	if(includeMemList.isEmpty()) return false;

	int count=includeMemList.count();
	for(int i=0;i<count;i++) 
	{
		MemberDef *md=includeMemList.at(i);
		if(stricmp(md->name().data(),name)==0)
			return true;

	}
	return false;	
}

void 
addInnerClasses(const FileDef *fd)
{
  if(fd==NULL) return;
  iLineNr=0;
  ClassSDict *mDict=fd->getClassSDict();
  if(mDict==0) return; 	
  ClassSDict::Iterator cli(*mDict);
  ClassDef *cd;
  
  for ( ; (cd=cli.current()) ; ++cli )
  {
	//  printf("\n class: %s",cd->name());
	  VerilogDocGen::printAllMem(cd);
	  classInnerDict.insert(cd->symbolName().data(),cd);
  }

   defDict.sort();
   Definition *defi;
   
   int count=defDict.count();


   for(int j=0;j<count;j++)
  {
      defi=(Definition*)defDict.at(j);	 
	//  printf("\n allMem : %s %d",defi->name().data(),defi->getDefLine());
  }
}

void VerilogDocGen::printAllMem(ClassDef *cd)
{

if(cd==0) return;

MemberNameInfoSDict *memDict=cd->memberNameInfoSDict();
 
if(memDict==0) return;



//variableDict.clear();

 MemberNameInfoSDict::Iterator mnii(*memDict);
  MemberNameInfo *mni;
  for (mnii.toFirst();(mni=mnii.current());++mnii)
  {
    MemberInfo *mi=mni->first();
    while (mi)
    {
      MemberDef *md=mi->memberDef;
//	  printf("\n found mem %s %d in class %s %d",md->name().data(),md->getDefLine(),cd->name().data(),defDict.count());
	  defDict.append(md);	 
	  mi=mni->next();
	}
  }
}


MemberDef* findInnerClassMember(ClassDef *cd,QCString & name)
{
   
if(cd==0) return NULL;

MemberNameInfoSDict *memDict=cd->memberNameInfoSDict();
 
if(memDict==0) return NULL;

 MemberNameInfoSDict::Iterator mnii(*memDict);
  MemberNameInfo *mni;
  for (mnii.toFirst();(mni=mnii.current());++mnii)
  {
    MemberInfo *mi=mni->first();
    while (mi)
    {
      MemberDef *md=mi->memberDef;
	  if(stricmp(name.data(),md->name().data())==0)
		  return md;
	  mi=mni->next();
	}
  }
  return NULL;
}

MemberDef* findFileLink(QCString & mem,int line)
{
	int count=defDict.count();

	for(int u=iLineNr;u<count;u++)
	{
        Definition *d=(Definition*)defDict.at(u);
		int li=d->getDefLine();
		if(li==line && d->name() == mem)
			return (MemberDef*)d;
        
		if(li>line) break; 
		iLineNr=u;
	}
	
	
	return NULL;
}
