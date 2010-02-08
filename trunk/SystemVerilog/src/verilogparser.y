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

/******************************************************************************
 * Simple Parser for Verilog 2001 subset
 * Date: 04/2008
 * supports the IEEE Std 1364-2001 (Revision of IEEE Std 1364-1995)Verilog subset
 *
 * Date: 01/2010
 * supports SystemVerilog 3.1
 *****************************************************************************/

%locations
%skeleton "glr.c" 
%name-prefix="c_"
%debug

%{

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "verilogdocgen.h"
#include "membergroup.h"
//#include "verilogparser.hpp"
#include "vhdldocgen.h"
#include "doxygen.h"
#include "searchindex.h"
#include "verilogscanner.h"
#include "commentscan.h"
#include "qstack.h"
#define YYMAXDEPTH 15000

static MyParserConv* myconv=0;




// functions for  verilog parser ---------------------
int c_lex (void);
void c_error (char const *);

%}

%union {
	int itype;	/* for count */
	char ctype;	/* for char */
	char cstr[1024];
	}

%initial-action
{
  /* turn on/off debugging mode */
 yydebug=FALSE;
// yydebug=TRUE;
};
	
	
%token NET_TOK STR0_TOK STR1_TOK GATE_TOK  STRING_TOK  SSTRING_TOK 
%token DIGIT_TOK SEM_TOK DOT_TOK 
%token LETTER_TOK  PLUS_TOK MINUS_TOK
%token COLON_TOK LBRACE_TOK RBRACE_TOK LBRACKET_TOK RBRACKET_TOK AND_TOK
%token OR_TOK EQU_TOK GT_TOK LT_TOK NOT_TOK  MULT_TOK PERCENTAL_TOK
%token ENV_TOK PARA_TOK AT_TOK DOLLAR_TOK 
%token SN_TOK EXCLAMATION_TOK RRAM_TOK LRAM_TOK
%token PARAMETER_TOK  OUTPUT_TOK INOUT_TOK
%token SMALL_TOK MEDIUM_TOK LARGE_TOK VEC_TOK SCALAR_TOK REG_TOK TIME_TOK REAL_TOK  EVENT_TOK
%token ASSIGN_TOK DEFPARAM_TOK MODUL_TOK ENDMODUL_TOK MACRO_MODUL_TOK
%token ENDPRIMITIVE_TOK PRIMITIVE_TOK INITIAL_TOK TABLE_TOK ENDTABLE_TOK ALWAYS_TOK
%token TASK_TOK ENDTASK_TOK FUNC_TOK ENDFUNC_TOK
%token IF_TOK CASE_TOK CASEX_TOK CASEZ_TOK FOREVER_TOK REPEAT_TOK
%token FOR_TOK JOIN_TOK WAIT_TOK FORCE_TOK RELEASE_TOK DEASSIGN_TOK DISABLE_TOK
%token WHILE_TOK ELSE_TOK ENDCASE_TOK BEGIN_TOK DEFAULT_TOK FORK_TOK
%token END_TOK SPECIFY_TOK ENDSPECIFY_TOK SPECPARAM_TOK
%token DSETUP_TOK DHOLD_TOK  DWIDTH_TOK DPERIOD_TOK DSKEW_TOK DRECOVERY_TOK DSETUPHOLD_TOK
%token POSEDGE_TOK NEGEDGE_TOK EDGE_TOK
%token COMMA_TOK  QUESTION_TOK AUTO_TOK INPUT_TOK SIGNED_TOK LOCALPARAM_TOK INTEGER_TOK  NOCHANGE_TOK
%token GENERATE_TOK ENDGENERATE_TOK  GENVAR_TOK
%token LIBRARY_TOK CONFIG_TOK ENDCONFIG_TOK INCLUDE_TOK PULSEON_DETECT_TOK PULSEONE_EVENT_TOK
%token USE_TOK LIBLIST_TOK INSTANCE_TOK CELL_TOK SHOWCANCEL_TOK NOSHOWCANCEL_TOK
%token REMOVAL_TOK FULLSKEW_TOK TIMESKEW_TOK RECREM_TOK
%token IFNONE_TOK REALTIME_TOK DESIGN_TOK 
%token OOR_TOK AAND_TOK SNNOT_TOK NOTSN_TOK AAAND_TOK DOTMULT_TOK
%token ENDINTERFACE_TOK INTERFACE_TOK  THISDOT_TOK SUPERDOT_TOK UNIT_TOK
%token INT_TOK SHORTINT_TOK LONGINT_TOK BYTE_TOK BIT_TOK LOGIC_TOK
%token ROOT_TOK NULL_TOK UNSIGNED_TOK SHORTREAL_TOK APOS_TOK WITH_TOK GGT_TOK  LLT_TOK PPLUS_TOK DMINUS_TOK IFF_TOK
%token TAGGED_TOK INSIDE_TOK RANDSEQUENCE_TOK ENDSEQUENCE_TOK 	CLOCKING_TOK ENDCLOCKING_TOK VOID_TOK			
%token DO_TOK FOREACH_TOK UNIQUE_TOK PRIORITY_TOK  RANDCASE_TOK CCOLON_TOK MATCHES_TOK			
%token SOR_TOK BREAK_TOK CONTINUE_TOK RETURN_TOK JOINANY_TOK JOINNONE_TOK WAITORDER_TOK NEW_TOK  ALWAYSCOMB_TOK ALWAYSLATCH_TOK ALWAYSFF_TOK
%token ALIAS_TOK EXTERN_TOK HIGHZ0_TOK  UNION_TOK STRUCT_TOK STATIC_TOK PACKED_TOK VIRTUAL_TOK CHANDLE_TOK      
%token ENUM_TOK TYPE_TOK CONST_TOK TYPEDEF_TOK CLASS_TOK IMPORT_TOK REF_TOK CONTEXT_TOK PURE_TOK EXPORT_TOK
%token BIND_TOK MODPORT_TOK EXPECT_TOK ASSERT_TOK PROPERTY_TOK ENDPROPERTY_TOK ASSUME_TOK COVER_TOK SEQUENCE_TOK 
%token FIRST_MATCH_TOK INTERSECT_TOK WITHIN_TOK THROUGHOUT_TOK DIST_TOK BEFORE_TOK CONSTRAINT_TOK SOLVE_TOK PROGRAM_TOK ENDPROGRAM_TOK
%token RAND_TOK RANDC_TOK LOCAL_TOK PROTECTED_TOK FORKJOIN_TOK  FINAL_TOK TIMEUNIT_TOK TIMEPRECISION_TOK
%token ENDCLASS_TOK ENDPACKAGE_TOK PACKAGE_TOK EXTEND_TOK
%token DOUBLEPARA_TOK ATR_TOK ATL_TOK
%token COVERGROUP_TOK ENDGROUP_TOK   COVERPOINT_TOK WILDCARD_TOK BINS_TOK ILLEGALBINS_TOK
%token IGNOREBINS_TOK CROSS_TOK BINSOF_TOK PROPEQU_TOK PROPLT_TOK 
%token EEEQU_TOK EQU_Q_EQU_TOK EX_Q_EQU_TOK EX_EQU_EQU_TOK LLLT_TOK GGGT_TOK MINUSLT_TOK EQULT_TOK 
%token INLINEBODY_TOK







%start file 
/* -------------- rules section -------------- */
%%
file	: {VerilogDocGen::identVerilog.resize(0);}lines 	
	    ;
lines 	: description  
           | lines  description {VerilogDocGen::identVerilog.resize(0);}
		   | INLINEBODY_TOK always_construct
	       | INLINEBODY_TOK class_item 
		    ;


//------------------------------------------------------------------------------------------------------
//----------------------------   A.1.1 Library source text  --------------------------------------------
//-----------------------------------------------------------------------------------------------------

library_text : library_descriptions
              ; 
library_descriptions : library_declaration
                     | include_statement
                     | config_declaration
					 ;

library_declaration : LIBRARY_TOK SEM_TOK
                      

file_path_spec : simple_identifier
                | STRING_TOK
				;

include_statement :  INCLUDE_TOK GT_TOK file_path_spec LT_TOK SEM_TOK
                   | INCLUDE_TOK error SEM_TOK
				   ;
//------------------------------------------------------------------------------------------------------
//----------------------------  A.1.2 Configuration source text  -------------------------------------------------------
//-----------------------------------------------------------------------------------------------------

config_declaration : CONFIG_TOK simple_identifier SEM_TOK  design_statement config_rule_statement_list ENDCONFIG_TOK
                   | CONFIG_TOK simple_identifier SEM_TOK  design_statement  ENDCONFIG_TOK      				  
				  ; 

design_statement : DESIGN_TOK  aidentifier_list  SEM_TOK
                 | DESIGN_TOK error SEM_TOK
				 ;



config_rule_statement_list:config_rule_statement
                          | config_rule_statement_list config_rule_statement
						  ;


config_rule_statement : DEFAULT_TOK liblist_clause SEM_TOK
                      | inst_clause liblist_clause SEM_TOK
                      | inst_clause use_clause SEM_TOK
                      | cell_clause liblist_clause SEM_TOK
                      | cell_clause use_clause SEM_TOK
					  ;


aidentifier_list : simple_identifier
                | aidentifier_list simple_identifier
                ;


inst_clause :INSTANCE_TOK simple_identifier
            ;

cell_clause : CELL_TOK simple_identifier
            ;
             

liblist_clause : LIBLIST_TOK  
               | LIBLIST_TOK aidentifier_list 
               ;

use_clause : USE_TOK simple_identifier config 
		    ;  

config : /* empty6 */
       | COLON_TOK CONFIG_TOK


//------------------------------------------------------------------------------------------------------
//----------------------------  A.1.3 Module and primitive source text  -------------------------------------------------------
//-----------------------------------------------------------------------------------------------------

description : module_declaration
             | udp_declaration
             | interface_declaration
             | program_declaration
             | package_declaration
             | attribute_instance  package_item
             | attribute_instance  bind_directive
			 | library_text		
			
             ;
		   
                    
module_ansi_header :  attribute_instance  module_keyword xlifetime class_identifier xmodule_parameter_port_list mod {vbufreset();}

mod: list_of_ports SEM_TOK                       
   | SEM_TOK                                      
   |  LBRACE_TOK DOTMULT_TOK RBRACE_TOK SEM_TOK   
   |  LBRACE_TOK RBRACE_TOK SEM_TOK               

class_identifier : identifier {
                            QCString modName=$<cstr>1;
                         //   if(VerilogDocGen::parseCode)  fprintf(stderr,"\n[%s]", modName.data());
                            if(!VerilogDocGen::parseCode) { 
								             VerilogDocGen::portType.resize(0);
							  				 Entry* lastMod=VerilogDocGen::makeNewEntry("",Entry::CLASS_SEC,getVerilogState());
											 if(VerilogDocGen::portType.contains("virtual"))
											 lastMod->virt=Virtual;
											 VerilogDocGen::currState=getVerilogState();
											 if(VerilogDocGen::lastModule && !VerilogDocGen::lastModule->name.isEmpty()){
												 modName.prepend("::");
												 modName.prepend(VerilogDocGen::lastModule->name.data());
											 }
											 lastMod->name=modName;
                                             VerilogDocGen::addVerilogClass(lastMod);
                                             VerilogDocGen::currentVerilog=lastMod;
                                             VerilogDocGen::currentVerilog->protection=Public;
					                         VerilogDocGen::parseModule(modName);
    									    }
                                            else {
											      VerilogDocGen::parseModule(modName);
                                         		  }
                               VerilogDocGen::currVerilogType=0;
							   VerilogDocGen::portType.resize(0);
							   vbufreset();
							 }
			  

module_declaration : module_ansi_header  module_item_list end_module  {vbufreset();}
                   | module_ansi_header error end_module              {vbufreset();}
                   | module_ansi_header    end_module                 {vbufreset();}
                   | EXTERN_TOK module_ansi_header                    {vbufreset();}
				   ;

		   
				   
interface_ansi_header : attribute_instance  INTERFACE_TOK xlifetime class_identifier xmodule_parameter_port_list list_of_ports  SEM_TOK		  {vbufreset();}		   
                      | attribute_instance  INTERFACE_TOK xlifetime class_identifier error SEM_TOK                                             {vbufreset();}
                      | attribute_instance  INTERFACE_TOK xlifetime class_identifier xmodule_parameter_port_list SEM_TOK                       {vbufreset();}

interface_declaration : interface_ansi_header xtime_declaration  interface_item_list end_interface  {vbufreset();}
                      | interface_ansi_header xtime_declaration  error end_interface  {vbufreset();}
                      | interface_ansi_header  end_interface  {vbufreset();}
              //        |  attribute_instance  INTERFACE_TOK xlifetime  identifier LBRACE_TOK DOTMULT_TOK RBRACE_TOK SEM_TOK  {vbufreset();}
                      | EXTERN_TOK interface_ansi_header  {vbufreset();}
				      ;


xtime_declaration : /* empty5 */           {vbufreset();}
                  | timeunits_declaration {vbufreset();}
                  ;				  

module_item_list : module_item
                 | module_item_list module_item
				 ;

interface_item_list : interface_item
                 | interface_item_list interface_item				 

program_item_list : program_item
                 | program_item_list program_item				 

program_nonansi_header : attribute_instance  PROGRAM_TOK xlifetime class_identifier xmodule_parameter_port_list mod
            
program_declaration :program_nonansi_header   program_item_list end_program  {vbufreset();}
                   | program_nonansi_header  error end_program  {vbufreset();}
                   | program_nonansi_header  end_program  {vbufreset();}
                   | EXTERN_TOK  program_nonansi_header
              	   ;

				   
				   
class_declaration : virti CLASS_TOK  xlifetime class_identifier xmodule_parameter_port_list SEM_TOK  {vbufreset();}  class_item_list end_class	 {vbufreset();}			   
				  | virti CLASS_TOK  xlifetime class_identifier xmodule_parameter_port_list EXTEND_TOK extends_identifier SEM_TOK  {vbufreset();}  class_item_list end_class  {vbufreset();}
				  | virti CLASS_TOK  xlifetime class_identifier xmodule_parameter_port_list EXTEND_TOK extends_identifier LBRACE_TOK list_of_arguments RBRACE_TOK SEM_TOK  {VerilogDocGen::portType.resize(0);vbufreset();} class_item_list end_class  {vbufreset();}
				  | virti CLASS_TOK  xlifetime class_identifier xmodule_parameter_port_list EXTEND_TOK extends_identifier LBRACE_TOK list_of_arguments RBRACE_TOK SEM_TOK  {vbufreset();} error end_class  {vbufreset();}
				  | virti CLASS_TOK  xlifetime class_identifier xmodule_parameter_port_list SEM_TOK  {vbufreset();} error end_class	 {vbufreset();}			   
				  | virti CLASS_TOK  xlifetime class_identifier xmodule_parameter_port_list SEM_TOK   end_class	 {vbufreset();}			   
				  | virti CLASS_TOK  xlifetime class_identifier xmodule_parameter_port_list EXTEND_TOK extends_identifier LBRACE_TOK list_of_arguments RBRACE_TOK SEM_TOK  {VerilogDocGen::portType.resize(0);vbufreset();} end_class  {vbufreset();}
                  | virti CLASS_TOK  xlifetime class_identifier xmodule_parameter_port_list EXTEND_TOK extends_identifier  SEM_TOK  {VerilogDocGen::portType.resize(0);vbufreset();} end_class  {vbufreset();}
				  | virti CLASS_TOK error end_class
				  ;
				   
extends_identifier : simple_identifier { 
					 						 if(!VerilogDocGen::parseCode)
											 { 
	                                         QCString ex=getVerilogString();
											  VhdlDocGen::deleteAllChars(ex,' ');
											 VhdlDocGen::deleteAllChars(ex,';');
											 if(VerilogDocGen::currentVerilog)
                                                 if(!VerilogDocGen::findExtendsComponent(VerilogDocGen::currentVerilog->extends,ex))
												 {	
                                                 	BaseInfo *bb=new BaseInfo(ex.data(),Public,Normal);
                     	                            VerilogDocGen::currentVerilog->extends->append(bb);	
                                                  }// findExtendsComponent
												 VerilogDocGen::paraType.resize(0);
											 }
					                   }
 
virti : /*empty*/
					 | VIRTUAL_TOK {VerilogDocGen::portType+="virtual";}
       ;				  
				  
class_item_list : class_item {VerilogDocGen::portType.resize(0);};
	   |  class_item_list class_item  {VerilogDocGen::portType.resize(0);}	
        ;
				   
				   
package_item_list : attribute_instance package_item
                  |   package_item_list attribute_instance package_item		
                  ;

			  
package_declaration :  attribute_instance PACKAGE_TOK class_identifier SEM_TOK  xtime_declaration  package_item_list end_package  {vbufreset();}
                    |  attribute_instance PACKAGE_TOK class_identifier  SEM_TOK  end_package   {vbufreset();}
	 				|  attribute_instance PACKAGE_TOK class_identifier  SEM_TOK  xtime_declaration  error end_package   {vbufreset();}
	                ;
	                
module_keyword : MODUL_TOK  
               | MACRO_MODUL_TOK 
			   ;

end_class : ENDCLASS_TOK  { VerilogDocGen::resetTypes(); }
            | ENDCLASS_TOK COLON_TOK identifier  {  VerilogDocGen::resetTypes(); }
			;

end_package : ENDPACKAGE_TOK  {  VerilogDocGen::resetTypes(); }
            | ENDPACKAGE_TOK COLON_TOK identifier  {  VerilogDocGen::resetTypes(); }
			;
			   
end_module : ENDMODUL_TOK  { VerilogDocGen::resetTypes();  }
            | ENDMODUL_TOK COLON_TOK identifier  {  VerilogDocGen::resetTypes(); }
			;

end_interface : ENDINTERFACE_TOK  {   VerilogDocGen::resetTypes();  }
            | ENDINTERFACE_TOK COLON_TOK identifier  { VerilogDocGen::resetTypes(); }
			;

end_program : ENDPROGRAM_TOK  {  VerilogDocGen::resetTypes(); }
            | ENDPROGRAM_TOK COLON_TOK identifier  {  VerilogDocGen::resetTypes(); }
			;
			
xlifetime : /* empty4 */
      | lifetime
      ;	  
	  
xmodule_parameter_port_list : /*empty*/
                             | module_parameter_port_list
							
							 ;
//------------------------------------------------------------------------------------------------------
//---------------------------- A.1.4 Module parameters and ports  -------------------------------------------------------
//-----------------------------------------------------------------------------------------------------

module_parameter_port_list : PARA_TOK  LBRACE_TOK  parameter_declaration_list  RBRACE_TOK {vbufreset();}        
                           | PARA_TOK  LBRACE_TOK error RBRACE_TOK                                     {vbufreset();}
						   ;

parameter_declaration_list:  data_type_or_implicit   param_assignment                                     
                           | TYPE_TOK param_assignment  
                           | parameter_declaration_list COMMA_TOK PARAMETER_TOK data_type_or_implicit   param_assignment
						   | parameter_declaration_list COMMA_TOK data_type_or_implicit    param_assignment 
						   | parameter_declaration_list COMMA_TOK TYPE_TOK     param_assignment 
						   | PARAMETER_TOK  data_type_or_implicit param_assignment
						   | PARAMETER_TOK TYPE_TOK param_assignment
						   | parameter_declaration_list COMMA_TOK PARAMETER_TOK TYPE_TOK     param_assignment 
						   
						   ;


						  
list_of_ports :  LBRACE_TOK  {VerilogDocGen::currVerilogType=VerilogDocGen::PORT;}  port_list RBRACE_TOK  {VerilogDocGen::portType="";}                
               | LBRACE_TOK  error RBRACE_TOK  {VerilogDocGen::currVerilogType=0;vbufreset();}
			   ;


 

 port_list :
		   | port                      {VerilogDocGen::parsePortDir();vbufreset();}                 
           | port_list COMMA_TOK port  {VerilogDocGen::parsePortDir();vbufreset();}
		   ;

port : port_expression                                               {VerilogDocGen::parsePortDir();vbufreset();}
     | DOT_TOK port_expression LBRACE_TOK RBRACE_TOK                 {VerilogDocGen::parsePortDir();vbufreset();}
	 | DOT_TOK port_expression LBRACE_TOK port_expression RBRACE_TOK {VerilogDocGen::parsePortDir();vbufreset();}
   
    

port_expression : port_reference
                |  LRAM_TOK  port_reference_list RRAM_TOK
				|  LRAM_TOK  error RRAM_TOK
                ;

port_reference_list: port_reference_list COMMA_TOK port_reference   {VerilogDocGen::parsePortDir();vbufreset();}
                   | port_reference                                 {VerilogDocGen::parsePortDir();vbufreset();}
                   ;

port_reference : function_type_or_implicit1                     
               //  | identifier LBRACKET_TOK range_expression RBRACKET_TOK
			     | port_direction 	variable_type	
			     | function_type_or_implicit1 variable_type
			     | port_direction function_type_or_implicit variable_type
			     ;

port_declaration : attribute_instance inout_declaration  { VerilogDocGen::currVerilogType=0;vbufreset();VerilogDocGen::portType.resize(0);}
				  | attribute_instance input_declaration  { VerilogDocGen::currVerilogType=0;vbufreset();VerilogDocGen::portType.resize(0);}
                 | attribute_instance output_declaration { VerilogDocGen::currVerilogType=0;vbufreset();VerilogDocGen::portType.resize(0);}
                 | attribute_instance ref_declaration    { VerilogDocGen::currVerilogType=0;vbufreset();VerilogDocGen::portType.resize(0);}
                 | error SEM_TOK		                 { VerilogDocGen::currVerilogType=0;vbufreset();VerilogDocGen::portType.resize(0);}
				;


timeunits_declaration : TIMEUNIT_TOK primary_literal SEM_TOK        { VerilogDocGen::parseAttribute("timeunit");}    {vbufreset();}
				| TIMEPRECISION_TOK primary_literal SEM_TOK         { VerilogDocGen::parseAttribute("timeprecision"); }{vbufreset();}
                      ;

//------------------------------------------------------------------------------------------------------
//---------------------------- A.1.5 Module items  -------------------------------------------------------
//-----------------------------------------------------------------------------------------------------

module_item : port_declaration SEM_TOK 
			| non_port_module_item
			;



non_port_module_item : generated_instantiation 
                    | module_or_generate_item
                    | specify_block
                    | attribute_instance  specparam_declaration
                    | program_declaration
                    | module_declaration
                    | timeunits_declaration
                    ;

module_common_item : module_or_generate_item_declaration
                  //  | interface_instantiation
                 //  | program_instantiation
                   | concurrent_assertion_item
                   | bind_directive
                   | continuous_assign
                   | net_alias
				   | initial_construct {vbufreset();VerilogDocGen::insideFunction=FALSE;VerilogDocGen::currentFunctionVerilog=0;}
                   | final_construct   {vbufreset();VerilogDocGen::insideFunction=FALSE;VerilogDocGen::currentFunctionVerilog=0;}
				   | always_construct  {
					                      VerilogDocGen::currentFunctionVerilog=0;vbufreset();
					                    }
                   ;

module_or_generate_item :  attribute_instance  parameter_override
					    |  attribute_instance  gate_instantiation {vbufreset();}
                        |  attribute_instance  udp_instantiation
                      //  |  attribute_instance  module_instantiation
                        |  attribute_instance  module_common_item
                        ;

module_or_generate_item_declaration : genvar_declaration                    
                                    | package_or_generate_item_declaration  {VerilogDocGen::currVerilogType=0;vbufreset();}
                                    | clocking_declaration                   {VerilogDocGen::currVerilogType=0;vbufreset();}
                                    | DEFAULT_TOK CLOCKING_TOK identifier SEM_TOK
                                    ;

package_or_generate_item_declaration : SEM_TOK
										   | data_declaration { VerilogDocGen::parseEnum();vbufreset();  VerilogDocGen::currState=0;VerilogDocGen::currentFunctionVerilog=0; VerilogDocGen::portType.resize(0);}
                                     //  |  module_instantiation             
                                       | task_declaration
                                       | function_declaration
                                    //   | dpi_import_export
                                       | extern_constraint_declaration
                                       | class_declaration
                                    //   | class_constructor_declaration
                                       | parameter_declaration    { VerilogDocGen::portType="";}
                                       | local_parameter_declaration { VerilogDocGen::portType="";}
									   | covergroup_declaration { VerilogDocGen::portType="";}
                                       | overload_declaration
                                       | concurrent_assertion_item_declaration { VerilogDocGen::portType="";}
                                       | net_declaration 
									   ;
									   
parameter_override : DEFPARAM_TOK { VerilogDocGen::currState=VerilogDocGen::DEFPARAM;} list_of_param_assignments SEM_TOK { VerilogDocGen::currState=VerilogDocGen::DEFPARAM;}  {vbufreset(); if(VerilogDocGen::parseCode) VerilogDocGen::currVerilogType=0;} 
                   | DEFPARAM_TOK error SEM_TOK                                                                                 {vbufreset(); if(VerilogDocGen::parseCode) VerilogDocGen::currVerilogType=0;} 
                   ;


bind_directive : BIND_TOK hierachical_identifier identifier real_type_spec SEM_TOK
					

//------------------------------------------------------------------------------------------------------
//---------------------------- A.1.6 interface items
//-----------------------------------------------------------------------------------------------------

interface_or_generate_item : attribute_instance  module_common_item
                           | attribute_instance  modport_declaration
                           | attribute_instance  extern_tf_declaration
                           ;
							
extern_tf_declaration : EXTERN_TOK method_prototype SEM_TOK 
                      | EXTERN_TOK FORKJOIN_TOK task_prototype SEM_TOK
                      | EXTERN_TOK error SEM_TOK
                      ;
					  
interface_item : port_declaration SEM_TOK
               | non_port_interface_item
	           ;
			   
non_port_interface_item : generated_instantiation
                        | attribute_instance  specparam_declaration
                        | interface_or_generate_item
                        | program_declaration
                        | interface_declaration
                        | timeunits_declaration
                        ;						
				   
//------------------------------------------------------------------------------------------------------
//---------------------------- A.1.7 program items
//-----------------------------------------------------------------------------------------------------

	program_item : port_declaration SEM_TOK
                 | non_port_program_item

non_port_program_item : attribute_instance  continuous_assign
                      | attribute_instance  module_or_generate_item_declaration
                      | attribute_instance  specparam_declaration
					  | attribute_instance  initial_construct {vbufreset();VerilogDocGen::insideFunction=FALSE;VerilogDocGen::currentFunctionVerilog=0;}
                      | attribute_instance  concurrent_assertion_item
                      | attribute_instance  timeunits_declaration
                      ;

					  
//------------------------------------------------------------------------------------------------------
//---------------------------- A.1.8 class items
//-----------------------------------------------------------------------------------------------------



data_declaration11 : variable_declaration11
                 | life_const variable_declaration
                 | life_const class_item_qualifier_list variable_declaration
                 | type_declaration
				 | package_import_declaration {vbufreset();VerilogDocGen::insideFunction=FALSE;VerilogDocGen::currentFunctionVerilog=0;VerilogDocGen::currState=0;}
                 ;

variable_declaration11 : data_type_virt list_of_variable_identifiers_spec SEM_TOK  { VerilogDocGen::parseEnum();VerilogDocGen::currVerilogType=0;} 
                       | data_type_virt error SEM_TOK
                       | data_type_virt function_call_v
					  ;


variable_declaration : data_type list_of_variable_identifiers_spec SEM_TOK { VerilogDocGen::parseEnum();VerilogDocGen::currVerilogType=0; }
                     | data_type error SEM_TOK 
                     ;


data_declaration : lifetime variable_declaration
                 | variable_declaration
                 | life_const variable_declaration
                 | life_const class_item_qualifier_list variable_declaration
                 | lifetime class_item_qualifier_list variable_declaration
                 | type_declaration
                 | package_import_declaration {vbufreset();VerilogDocGen::insideFunction=FALSE;VerilogDocGen::currentFunctionVerilog=0;VerilogDocGen::currState=0;}
                 ;


class_item :  attribute_instance  timeunits_declaration    {VerilogDocGen::currVerilogType=0;vbufreset();}
           |  attribute_instance  class_method             {VerilogDocGen::currVerilogType=0;vbufreset();}
           |  attribute_instance  class_constraint         {VerilogDocGen::currVerilogType=0;vbufreset();}
           |  attribute_instance  class_declaration        {VerilogDocGen::currVerilogType=0;vbufreset();}
           |  attribute_instance  class_property           {VerilogDocGen::currVerilogType=0;vbufreset(); VerilogDocGen::currState=0; VerilogDocGen::currentFunctionVerilog =0;}
		   |  attribute_instance  S_STAT                   {VerilogDocGen::currVerilogType=0;vbufreset();}
		   |  attribute_instance  S_VIRT                   {VerilogDocGen::currVerilogType=0;vbufreset();}
           |  attribute_instance covergroup_declaration    {VerilogDocGen::currentFunctionVerilog=0;VerilogDocGen::currVerilogType=0;vbufreset();}
           |  SEM_TOK                                      {VerilogDocGen::currVerilogType=0;VerilogDocGen::currentFunctionVerilog=0;vbufreset();}
           ;

new_stat: class_constraint    
        | class_method
		| class_property
    

S_STAT : STATIC_TOK  { VerilogDocGen::portType+="static ";}   new_stat
	   											  
	|  STATIC_TOK VIRTUAL_TOK            { VerilogDocGen::portType+="static ";} class_method
    |  STATIC_TOK PURE_TOK VIRTUAL_TOK   { VerilogDocGen::portType+="static pure ";} class_method  
	;    
      
S_VIRT :    VIRTUAL_TOK   class_method 
		|   class_item_qualifier11 VIRTUAL_TOK    class_method 
		|   class_item_qualifier11 VIRTUAL_TOK  class_property 
	    |   VIRTUAL_TOK    class_property
	  	;
     
class_property :  data_declaration11 
               | property_qualifier_list data_declaration11 
               | property_qualifier_list STATIC_TOK {VerilogDocGen::portType+="static ";} data_declaration11               
			   ;
			   
class_method : task_declaration
             | function_declaration
             | method_qualifier  task_declaration
             | method_qualifier  function_declaration
			 | EXTERN_TOK  method_qualifier_list  method_prototype  
			 | EXTERN_TOK method_prototype     
	 	 	 |  PURE_TOK method_qualifier_list method_prototype 
		 	 | EXTERN_TOK  method_qualifier_list class_constructor_prototype 
             | EXTERN_TOK  class_constructor_prototype                   
             ;
			 
class_constructor_prototype : class_const_desc
 
class_constraint : constraint_prototype
                 | constraint_declaration
                  ;

class_item_qualifier11:  PROTECTED_TOK {  VerilogDocGen::portType+="protected ";}
                    | LOCAL_TOK        {  VerilogDocGen::portType+="local ";}
					
					;
  
class_item_qualifier_list : class_item_qualifier_list class_item_qualifier
                          | class_item_qualifier

class_item_qualifier: PROTECTED_TOK {  VerilogDocGen::portType+="protected ";}
                    | LOCAL_TOK     {  VerilogDocGen::portType+="local ";}
                    | STATIC_TOK    {  VerilogDocGen::portType+="static ";}
				//		| PROTECTED_TOK VIRTUAL_TOK
				
					;


property_qualifier_list: property_qualifier_list property_qualifier
                       | property_qualifier

property_qualifier :  RAND_TOK         { VerilogDocGen::portType+="rand "; }
						 |  RANDC_TOK  { VerilogDocGen::portType+="randc ";}
                  | class_item_qualifier11
                   ;
				   
method_qualifier : class_item_qualifier11
		          ;

method_qualifier_list: method_qualifier11
                     | method_qualifier_list  method_qualifier11

method_qualifier11 : class_item_qualifier 
					 | VIRTUAL_TOK {VerilogDocGen::portType+="virtual ";}
		           ;
		          
		          				  
 class_const_desc : FUNC_TOK  NEW_TOK SEM_TOK                                                             {VerilogDocGen::addConstructor(false);} 
				  | FUNC_TOK  NEW_TOK    LBRACE_TOK   {VerilogDocGen::addConstructor(true); }tf_port_list RBRACE_TOK SEM_TOK   
				  | FUNC_TOK  NEW_TOK    LBRACE_TOK  RBRACE_TOK SEM_TOK                                    {VerilogDocGen::addConstructor(false);} 
				//  | FUNC_TOK  NEW_TOK    LBRACE_TOK error RBRACE_TOK SEM_TOK                              {vbufreset(); }
		      	  ;
				  

supnew :  SUPERDOT_TOK DOT_TOK NEW_TOK LBRACE_TOK RBRACE_TOK SEM_TOK
	   | SUPERDOT_TOK DOT_TOK NEW_TOK LBRACE_TOK list_of_arguments RBRACE_TOK SEM_TOK
	   | SUPERDOT_TOK DOT_TOK NEW_TOK LBRACE_TOK error RBRACE_TOK SEM_TOK
	     |SUPERDOT_TOK DOT_TOK NEW_TOK SEM_TOK
	   ;
	   
	   
	   
//------------------------------------------------------------------------------------------------------
//---------------------------- A.1.9 Constraints
//-----------------------------------------------------------------------------------------------------

constraint_declaration :CONSTRAINT_TOK identifier {VerilogDocGen::classQu=$<cstr>1;VerilogDocGen::addProperty(1); } constraint_block
                    //   | STATIC_TOK CONSTRAINT_TOK identifier { } constraint_block
					   ;

constraint_block : LRAM_TOK constraint_block_item_list RRAM_TOK
                 |  LRAM_TOK RRAM_TOK
                 | LRAM_TOK error RRAM_TOK
                 ;

constraint_block_item_list : constraint_block_item
                           | constraint_block_item_list constraint_block_item
						   ;
						   
constraint_block_item : SOLVE_TOK list_of_identifiers BEFORE_TOK  list_of_identifiers SEM_TOK
                       | constraint_expression
                       ;
					   
constraint_expression : expression_or_dist SEM_TOK
                       | expression MINUSLT_TOK constraint_set
                       | IF_TOK LBRACE_TOK expression RBRACE_TOK constraint_set 
                       | IF_TOK LBRACE_TOK expression RBRACE_TOK constraint_set ELSE_TOK constraint_set
  				       | FOREACH_TOK LBRACE_TOK identifier  RBRACE_TOK constraint_set
                       | FOREACH_TOK LBRACE_TOK identifier LBRACKET_TOK list_of_array_identifiers RBRACKET_TOK  RBRACE_TOK constraint_set
                       ;
                       
                       
list_of_array_identifiers : identifier
		                  | list_of_array_identifiers COMMA_TOK identifier
						  ;
						  
constraint_set :constraint_expression
               | LRAM_TOK constraint_expression_list RRAM_TOK
               | LRAM_TOK error RRAM_TOK
               ;

constraint_expression_list : constraint_expression_list constraint_expression
						   | constraint_expression
						   ;

dist_list : dist_item 
          |  dist_list COMMA_TOK dist_item
          ;
          
           
dist_item : LBRACKET_TOK expression COLON_TOK expression RBRACKET_TOK dist_weight
          | expression dist_weight
          ; 

dist_weight : 
			| COLON_TOK EQU_TOK expression
            | COLON_TOK ENV_TOK expression
            ;

			   

		 
constraint_prototype :CONSTRAINT_TOK identifier {VerilogDocGen::classQu=$<cstr>1;VerilogDocGen::addProperty(1);} SEM_TOK
                	 ;

extern_constraint_declaration : CONSTRAINT_TOK ps_or_hier_identifier {VerilogDocGen::classQu=$<cstr>1;VerilogDocGen::addProperty(1); } constraint_block
									| STATIC_TOK CONSTRAINT_TOK  ps_or_hier_identifier identifier {VerilogDocGen::classQu=$<cstr>1;VerilogDocGen::addProperty(1);} constraint_block
							   ;
							   
	
//------------------------------------------------------------------------------------------------------
//---------------------------- A.1.10  Package items
//-----------------------------------------------------------------------------------------------------
    package_item : package_or_generate_item_declaration
                 | specparam_declaration
                 | anonymous_program
                 | timeunits_declaration


									 
anonymous_program : PROGRAM_TOK SEMP_TOK anonymous_program_item_list ENDPROGRAM_TOK { VerilogDocGen::resetTypes(); }
                  | PROGRAM_TOK SEMP_TOK error ENDPROGRAM_TOK                       { VerilogDocGen::resetTypes(); }
                  | PROGRAM_TOK SEMP_TOK  ENDPROGRAM_TOK                            { VerilogDocGen::resetTypes(); }
				  ;

SEMP_TOK : SEM_TOK {
                                          QCString prog;
				                           if(!VerilogDocGen::parseCode) 
							               { 
								             VerilogDocGen::portType.resize(0);
											 prog=VhdlDocGen::getRecordNumber();
                                             prog.prepend("anonymous_program_");
							  				 Entry* lastMod=VerilogDocGen::makeNewEntry("",Entry::CLASS_SEC,getVerilogState());
											 VerilogDocGen::currState=getVerilogState();
											 if(VerilogDocGen::lastModule && !VerilogDocGen::lastModule->name.isEmpty())
											{
												 prog.prepend("::");
												 prog.prepend(VerilogDocGen::lastModule->name.data());
											 }
											 lastMod->name=prog;
                                             VerilogDocGen::addVerilogClass(lastMod);
                                             VerilogDocGen::currentVerilog=lastMod;
                                             VerilogDocGen::currentVerilog->protection=Public;
					                         VerilogDocGen::parseModule(prog);
    									    }
                                            else {
											     VerilogDocGen::parseModule(prog);
                                         		  }
                               VerilogDocGen::currVerilogType=0;
							   VerilogDocGen::portType.resize(0);
							   vbufreset();
							 }

anonymous_program_item_list: anonymous_program_item
                            | anonymous_program_item_list anonymous_program_item
                            ;

							
anonymous_program_item : task_declaration
                       | function_declaration
                       | class_declaration
                       | covergroup_declaration { VerilogDocGen::currentFunctionVerilog=0;vbufreset();}
                       ;
       
//------------------------------------------------------------------------------------------------------
//---------------------------- A.2.1.1 Declaration types
//-----------------------------------------------------------------------------------------------------

local_parameter_declaration : LOCALPARAM_TOK   data_type_or_implicit list_of_param_assignments SEM_TOK           
							|  LOCALPARAM_TOK error SEM_TOK 
							;

parameter_declaration :      PARAMETER_TOK    data_type_or_implicit  list_of_param_assignments SEM_TOK                   
                    	    | PARAMETER_TOK  TYPE_TOK  data_type_or_implicit   list_of_param_assignments SEM_TOK                  
                            | PARAMETER_TOK error SEM_TOK 
							 ;
	
specparam_declaration : SPECPARAM_TOK  dimension list_of_specparam_assignments SEM_TOK 
				      | SPECPARAM_TOK   list_of_specparam_assignments SEM_TOK       
                      | SPECPARAM_TOK error SEM_TOK 
					  ;

//------------------------------------------------------------------------------------------------------
//---------------------------- A.2.1.2 Port declarations ---------------------------------------------
//-----------------------------------------------------------------------------------------------------

inout_declaration :  INOUT_TOK  {VerilogDocGen::portType+="inout "; VerilogDocGen::currVerilogType=VerilogDocGen::INOUT; } xsigned xrange   identifier                           {if(!VerilogDocGen::parseCode)VerilogDocGen::parsePortDir();}
				   | INOUT_TOK  {VerilogDocGen::portType+="inout "; VerilogDocGen::currVerilogType=VerilogDocGen::INOUT; } net_type xsigned xrange identifier                    {if(!VerilogDocGen::parseCode)VerilogDocGen::parsePortDir();}
				   | inout_declaration COMMA_TOK xsigned xrange identifier             {if(!VerilogDocGen::parseCode){VerilogDocGen::portType="";VerilogDocGen::portType+="inout ";VerilogDocGen::parsePortDir();}}                         
				   | inout_declaration COMMA_TOK net_type xsigned xrange identifier    {if(!VerilogDocGen::parseCode){VerilogDocGen::portType="";VerilogDocGen::portType+="inout ";VerilogDocGen::parsePortDir();}}                         			  
				   ;

input_declaration :  INPUT_TOK xsigned xrange   {VerilogDocGen::portType="";VerilogDocGen::portType+="input "; VerilogDocGen::currVerilogType=VerilogDocGen::INPUT; }  identifier                             {if(!VerilogDocGen::parseCode)VerilogDocGen::parsePortDir();} 
				   | INPUT_TOK net_type xsigned xrange   {VerilogDocGen::portType="";VerilogDocGen::portType+="input "; VerilogDocGen::currVerilogType=VerilogDocGen::INPUT; } identifier                     {if(!VerilogDocGen::parseCode)VerilogDocGen::parsePortDir();} 
				   | input_declaration COMMA_TOK xsigned xrange identifier              {if(! VerilogDocGen::parseCode)VerilogDocGen::parsePortDir();}
				   | input_declaration COMMA_TOK net_type xsigned xrange identifier     {if(! VerilogDocGen::parseCode)VerilogDocGen::parsePortDir();}                        
			       | INPUT_TOK error SEM_TOK
				   ;


output_declaration : OUTPUT_TOK  s_type {VerilogDocGen::portType="";VerilogDocGen::portType+="output "; VerilogDocGen::currVerilogType=VerilogDocGen::OUTPUT; } identifier                                      {if(!VerilogDocGen::parseCode)VerilogDocGen::parsePortDir();}
				   | OUTPUT_TOK         {VerilogDocGen::portType="";VerilogDocGen::portType+="output "; VerilogDocGen::currVerilogType=VerilogDocGen::OUTPUT; } identifier                                            {if(!VerilogDocGen::parseCode)VerilogDocGen::parsePortDir();}
                   | output_declaration COMMA_TOK  OUTPUT_TOK net_assignment            {if(!VerilogDocGen::parseCode)VerilogDocGen::parsePortDir();}
            	   | output_declaration COMMA_TOK identifier                            {if(!VerilogDocGen::parseCode)VerilogDocGen::parsePortDir();}                        
			       | output_declaration COMMA_TOK OUTPUT_TOK s_type identifier          {if(!VerilogDocGen::parseCode)VerilogDocGen::parsePortDir();}                     
			       | output_declaration COMMA_TOK OUTPUT_TOK  identifier                {if(!VerilogDocGen::parseCode)VerilogDocGen::parsePortDir();}                    				   
			       ;
			       
ref_declaration  : REF_TOK data_type list_of_identifiers                                {if(!VerilogDocGen::parseCode){VerilogDocGen::portType+="ref ";VerilogDocGen::parsePortDir();}}
//------------------------------------------------------------------------------------------------------
//-------------------------------------A.2.1.3 Type declarations----------------------------------------
//-----------------------------------------------------------------------------------------------------

lifetime : STATIC_TOK {
				    VerilogDocGen::portType+="static ";
		           }
         | AUTO_TOK
		 ;

life_const : CONST_TOK {VerilogDocGen::portType+="const ";}
         //  | lifetime
           ;
		 



package_import_declaration : IMPORT_TOK package_import_item_list  SEM_TOK {VerilogDocGen::parseImport();}
                 
                  | IMPORT_TOK STRING_TOK  dpi_function_import_property  c_identifier  dpi_function_proto SEM_TOK
                  | IMPORT_TOK STRING_TOK  dpi_function_import_property  c_identifier  dpi_task_proto SEM_TOK
                  | IMPORT_TOK STRING_TOK    c_identifier  dpi_function_proto SEM_TOK
                  | IMPORT_TOK STRING_TOK    c_identifier  dpi_task_proto SEM_TOK
                  | IMPORT_TOK STRING_TOK  error SEM_TOK
                  | EXPORT_TOK STRING_TOK   c_identifier  dpi_function_proto SEM_TOK {VerilogDocGen::parseImport(); }
                 // | EXPORT_TOK STRING_TOK   c_identifier  FUNC_TOK identifier SEM_TOK                 
				  | EXPORT_TOK STRING_TOK   c_identifier  dpi_task_proto SEM_TOK {VerilogDocGen::parseImport(); }
                  | EXPORT_TOK STRING_TOK   error  SEM_TOK
                  ;
                       

package_import_item:identifier CCOLON_TOK identifier
                   | identifier CCOLON_TOK MULT_TOK
                      
package_import_item_list : package_import_item
                         | package_import_item_list COMMA_TOK package_import_item       

type_declaration : TYPEDEF_TOK  ZUI
                  | TYPEDEF_TOK suc identifier SEM_TOK       {VerilogDocGen::addTypedef(getVerilogString()); }
                  | TYPEDEF_TOK ENUM_TOK  identifier SEM_TOK {VerilogDocGen::portType+=" _enum ";VerilogDocGen::addTypedef(getVerilogString()); }
                  ;

ZUI : data_type real_type  SEM_TOK  { VerilogDocGen::parseTypeDef(); vbufreset();}
//	| identifier SEM_TOK                 {VerilogDocGen::addTypedef(getVerilogString()); }
	;

suc :  STRUCT_TOK {VerilogDocGen::portType+="struct ";}
     | UNION_TOK {VerilogDocGen::portType+="union ";}
     | CLASS_TOK {VerilogDocGen::portType+="class ";}
     ;

                
                
                     
//------------------------------------------------------------------------------------------------------
//---------------------------- A.2.2.1 Net and variable types ---------------------------------------------
//-----------------------------------------------------------------------------------------------------


data_type_spec :  non_integer_type
           |  integer_atom_type signing
		   | integer_atom_type
		   | integer_atom_type dimension_list
		   | integer_atom_type signing dimension_list
		   | integer_vector_type
           | integer_vector_type dimension_list
           | integer_vector_type signing
           | integer_vector_type signing packed_dimension_list		   
           | struct_union pack_opt LRAM_TOK struct_union_member_list RRAM_TOK                         {}
           | struct_union pack_opt LRAM_TOK struct_union_member_list RRAM_TOK packed_dimension_list   {}
		   | CHANDLE_TOK                                   {VerilogDocGen::portType+="chandle ";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
		   | SSTRING_TOK                                   {VerilogDocGen::portType+="string ";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
		   | VIRTUAL_TOK simple_identifier                 {VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
		   | VIRTUAL_TOK INTERFACE_TOK simple_identifier   {VerilogDocGen::portType="virtual interface";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
           | INTERFACE_TOK simple_identifier   {VerilogDocGen::portType="interface";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
		   | EVENT_TOK                                     {VerilogDocGen::portType+="event ";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
  	       | ENUM_TOK  enum_base_type LRAM_TOK error RRAM_TOK
           | ENUM_TOK  LRAM_TOK error RRAM_TOK
           | ENUM_TOK  enum_base_type LRAM_TOK  {VerilogDocGen::portType+="enum ";VerilogDocGen::currVerilogType=VerilogDocGen::ENUMERATION;} enum_name_declaration_list RRAM_TOK    
	  	   | ENUM_TOK  LRAM_TOK  
		                       {
								   VerilogDocGen::portType+="enum ";
								   VerilogDocGen::currVerilogType=VerilogDocGen::ENUMERATION;
		                       } enum_name_declaration_list RRAM_TOK                   
           ;
 		
		   
		   
 data_type_virt : non_integer_type
           | integer_atom_type signing
		   | integer_atom_type packed_dimension_list		 
		   | integer_atom_type
		   | integer_vector_type
		    | integer_vector_type signing 
		   | integer_vector_type signing packed_dimension_list		   
           | integer_vector_type packed_dimension_list
           | struct_union pack_opt LRAM_TOK struct_union_member_list RRAM_TOK                           
           | struct_union pack_opt LRAM_TOK error RRAM_TOK                                               
           | struct_union pack_opt LRAM_TOK struct_union_member_list RRAM_TOK  packed_dimension_list    { }
		   | struct_union pack_opt LRAM_TOK error RRAM_TOK packed_dimension_list                       { }
           | CHANDLE_TOK                                         {VerilogDocGen::portType+="chandle ";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
		   | SSTRING_TOK                                         {VerilogDocGen::portType+="string ";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
		   | INTERFACE_TOK simple_identifier                     {VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
		   | EVENT_TOK                                           {VerilogDocGen::portType+="event";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
		   | ps_or_hier_identifier                               {
		                                                           VerilogDocGen::sdataType=$<cstr>1;
		                                                           VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;
		                                                           }
	  	   | ENUM_TOK  enum_base_type LRAM_TOK error RRAM_TOK
           | ENUM_TOK  LRAM_TOK error RRAM_TOK
           | ENUM_TOK  enum_base_type LRAM_TOK  {VerilogDocGen::portType+="enum ";VerilogDocGen::currVerilogType=VerilogDocGen::ENUMERATION;} enum_name_declaration_list RRAM_TOK    
	  	   | ENUM_TOK  LRAM_TOK  
		                       {
								   VerilogDocGen::portType+="enum ";
								   VerilogDocGen::currVerilogType=VerilogDocGen::ENUMERATION;
		                       } enum_name_declaration_list RRAM_TOK                   
           ;
 
 data_type : non_integer_type
           | integer_atom_type signing
		   | integer_atom_type packed_dimension_list		 
		   | integer_atom_type
		   | integer_vector_type
		   | integer_vector_type signing 	
		   | integer_vector_type signing packed_dimension_list		   
           | integer_vector_type packed_dimension_list
           | struct_union pack_opt LRAM_TOK struct_union_member_list RRAM_TOK                               {}
           | struct_union pack_opt LRAM_TOK error RRAM_TOK                                                  {}
           | struct_union pack_opt LRAM_TOK struct_union_member_list RRAM_TOK packed_dimension_list         {}		   
		   | struct_union pack_opt LRAM_TOK error RRAM_TOK packed_dimension_list                            {}  
           | CHANDLE_TOK                                         {VerilogDocGen::portType+="chandle ";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
		   | SSTRING_TOK                                         {VerilogDocGen::portType+="string ";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
		   | VIRTUAL_TOK simple_identifier                       {VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
		   | VIRTUAL_TOK INTERFACE_TOK simple_identifier         {VerilogDocGen::portType+="interface ";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
		   | EVENT_TOK                                           {VerilogDocGen::portType+="event ";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
		   | ps_or_hier_identifier          {
		                                     VerilogDocGen::sdataType=$<cstr>1;
		                                     VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;
		                                     }
           | ENUM_TOK  enum_base_type LRAM_TOK error RRAM_TOK
           | ENUM_TOK  LRAM_TOK error RRAM_TOK
           | ENUM_TOK  enum_base_type LRAM_TOK  {VerilogDocGen::portType+="enum ";VerilogDocGen::currVerilogType=VerilogDocGen::ENUMERATION;} enum_name_declaration_list RRAM_TOK    
	  	   | ENUM_TOK  LRAM_TOK  
		                       {
								   VerilogDocGen::portType+="enum ";
								   VerilogDocGen::currVerilogType=VerilogDocGen::ENUMERATION;
		                       } enum_name_declaration_list RRAM_TOK                   
           ;

			
 pack_opt : /*empty*/
							   | PACKED_TOK {VerilogDocGen::portType+="packed" ;}
							   | PACKED_TOK signing {VerilogDocGen::portType.prepend("packed ");}
 
 non_integer_type : SHORTREAL_TOK {VerilogDocGen::portType+="shortreal";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
                  | REAL_TOK      {VerilogDocGen::portType+="real";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
                  | REALTIME_TOK  {VerilogDocGen::portType+="realtime";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
                  ;
  
enum_base_type : integer_atom_type xsigning                                           {VerilogDocGen::enumType=getVerilogString();}
               | integer_vector_type  xsigning packed_dimension_list                  {VerilogDocGen::enumType=getVerilogString();} 
			   | integer_vector_type xsigning                                         {VerilogDocGen::enumType=getVerilogString();}
			   | identifier                                                           {VerilogDocGen::enumType=getVerilogString();}
			   | identifier packed_dimension                                          {VerilogDocGen::enumType=getVerilogString();}
			   ;
			   
 
enum_name_declaration : identifier int_num 
                        | identifier int_num EQU_TOK expression 
                        ;

 enum_name_declaration_list : enum_name_declaration 
                            | enum_name_declaration_list COMMA_TOK enum_name_declaration 
                            ;
							
 int_num : /* empty3 */ 
         | LBRACKET_TOK DIGIT_TOK RBRACKET_TOK
         | LBRACKET_TOK DIGIT_TOK COLON_TOK DIGIT_TOK RBRACKET_TOK
         ;
		 
 data_type_or_implicit :   
                       | data_type_spec
                       | signing 
					   | signing packed_dimension_list
					   | packed_dimension_list
 					   ;					   
  
 signing          : SIGNED_TOK    { VerilogDocGen::portType+="signed ";}
                  | UNSIGNED_TOK  { VerilogDocGen::portType+="unsigned ";}
                  ;
 
 xsigning         : /* empty2 */ 
                  | SIGNED_TOK    { VerilogDocGen::portType+="signed ";}
                  | UNSIGNED_TOK  { VerilogDocGen::portType+="unsigned ";}
                  ;
 
integer_vector_type : BIT_TOK      {VerilogDocGen::portType+="bit ";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
                    | LOGIC_TOK    {VerilogDocGen::portType+="logic ";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
                    | REG_TOK      {VerilogDocGen::portType+="reg ";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
                    ;
                    
integer_atom_type : BYTE_TOK      {VerilogDocGen::portType+="byte ";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
                   | INT_TOK       {VerilogDocGen::portType+="int ";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
                   | LONGINT_TOK   {VerilogDocGen::portType+="longint ";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
                   | SHORTINT_TOK  {VerilogDocGen::portType+="shortint ";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
                   | INTEGER_TOK   {VerilogDocGen::portType+="integer ";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
                   | TIME_TOK      {VerilogDocGen::portType+="time ";VerilogDocGen::currVerilogType=VerilogDocGen::SIGNAL;}
                   ;
                   
 integer_type : integer_vector_type 
              | integer_atom_type 
              ;
              
 simple_type : integer_type
             | non_integer_type
	          ;
                   
                  
output_var_type:TIME_TOK
               | INTEGER_TOK
			   ;

casting_type : 
			 | signing
             | simple_type
             | DIGIT_TOK
			 ;

s_type : net_type
			 | dimension {VerilogDocGen::enumType=getVerilogString(); }
		   | signed
		   | REG_TOK
		   | s_type SIGNED_TOK
		   | s_type dimension  {VerilogDocGen::enumType=getVerilogString(); }
      	   | s_type output_var_type
		   ;

net_type : NET_TOK
		 ;

genvar_declaration :GENVAR_TOK list_of_genvar_identifiers SEM_TOK {vbufreset();}
                   | GENVAR_TOK error SEM_TOK                      {vbufreset();}
				    ;

net_declaration : NET_TOK     xscalared xsigned xrange list_of_net_identifiers  SEM_TOK                               
                | NET_TOK xscalared xsigned xrange     list_of_net_decl_assignments  SEM_TOK                        
	            | NET_TOK xscalared xsigned xrange  delay3   list_of_net_decl_assignments SEM_TOK                  
	            | NET_TOK xscalared xsigned xrange  delay3   list_of_net_identifiers SEM_TOK                  
	            | NET_TOK drive_strength xscalared xsigned xrange  delay3   list_of_net_decl_assignments SEM_TOK   
	            | NET_TOK drive_strength xscalared xsigned xrange    list_of_net_decl_assignments SEM_TOK          
	            | NET_TOK drive_strength xscalared xsigned xrange    list_of_net_identifiers SEM_TOK           
	            | NET_TOK  charge_strength xscalared xsigned xrange     list_of_net_identifiers SEM_TOK        
	            | NET_TOK charge_strength xscalared xsigned xrange delay3    list_of_net_identifiers SEM_TOK         
	            | NET_TOK charge_strength xscalared xsigned xrange     list_of_net_decl_assignments SEM_TOK  
	            | NET_TOK  error SEM_TOK                                                                     
			   	;


xscalared:/*empty*/ 
		| scalared
		;

scalared: VEC_TOK    {VerilogDocGen::portType+="vector ";}
		| SCALAR_TOK {VerilogDocGen::portType+="scalared ";}
		;

data_type_or_void :  VOID_TOK
                  | data_type
				  ;

struct_union_member_list : struct_union_member                                      
					     | struct_union_member_list struct_union_member 
				         ;
						 
struct_union_member : attribute_instance  data_type_or_void list_of_variable_identifiers SEM_TOK			   
struct_union : STRUCT_TOK             {VerilogDocGen::portType+="struct "; VerilogDocGen::createStruct("struct");}
             | UNION_TOK              {VerilogDocGen::portType+="union "; VerilogDocGen::createStruct("union");}
			 | UNION_TOK TAGGED_TOK	  {VerilogDocGen::portType+="union tagged"; VerilogDocGen::createStruct("union tagged");}		   
//------------------------------------------------------------------------------------------------------
//---------------------------- A.2.2.2 Strengths --------------------------------------------
//-----------------------------------------------------------------------------------------------------

drive_strength:  LBRACE_TOK STR0_TOK COMMA_TOK STR1_TOK RBRACE_TOK
	            | LBRACE_TOK STR1_TOK COMMA_TOK STR0_TOK RBRACE_TOK
				| LBRACE_TOK STR1_TOK RBRACE_TOK
                | LBRACE_TOK STR0_TOK RBRACE_TOK
				| LBRACE_TOK error RBRACE_TOK
				| LBRACE_TOK STR1_TOK COMMA_TOK HIGHZ0_TOK RBRACE_TOK
          		;


charge_strength : LBRACE_TOK SMALL_TOK RBRACE_TOK {VerilogDocGen::portType+=" (small)";}
             	| LBRACE_TOK MEDIUM_TOK RBRACE_TOK {VerilogDocGen::portType+=" (medium)";}
	            | LBRACE_TOK LARGE_TOK RBRACE_TOK {VerilogDocGen::portType+=" (large)";}
           	    ;


//------------------------------------------------------------------------------------------------------
//----------------------------A.2.2.3 Delays --------------------------------------------
//-----------------------------------------------------------------------------------------------------


delay3 :  PARA_TOK LBRACE_TOK delay_value_list RBRACE_TOK 
        | PARA_TOK LBRACE_TOK error  RBRACE_TOK
        | PARA_TOK ps_or_hier_identifier
        | PARA_TOK DIGIT_TOK
      //  | PARA_TOK DIGIT_TOK LETTER_TOK
	   ;

delay_value_list : delay_value 
                 | delay_value_list COMMA_TOK delay_value
				 ;

delay2 : delay3
       ;
	   
delay_value : mintypemax_expression
            ;

//------------------------------------------------------------------------------------------------------
//----------------------------A.2.3 Declaration lists --------------------------------------------
//-----------------------------------------------------------------------------------------------------

list_of_event_identifiers :   list_of_event_lists                        
						      | dim_list                                 

list_of_event_lists:hierachical_identifier                                {VerilogDocGen::parseReg(VerilogDocGen::currentVerilog);}
                   |list_of_event_lists COMMA_TOK hierachical_identifier  {VerilogDocGen::parseReg(VerilogDocGen::currentVerilog);}
                   ;


dim_list: hierachical_identifier dimension_list                         {VerilogDocGen::parseReg(VerilogDocGen::currentVerilog);}
	       | dim_list COMMA_TOK hierachical_identifier dimension_list   {VerilogDocGen::parseReg(VerilogDocGen::currentVerilog);}
							;
		   ;
		    

list_of_genvar_identifiers : identifier 
                           | list_of_genvar_identifiers COMMA_TOK identifier
						    ;
							
list_of_net_decl_assignments : net_decl_assignment  
                              | list_of_net_decl_assignments COMMA_TOK net_decl_assignment  
 							  ;

list_of_net_identifiers : list_of_event_identifiers 
                        ;

list_of_param_assignments : param_assignment 
                          | list_of_param_assignments COMMA_TOK param_assignment 
						  ;

						 

real_type :identifier
          | DIGIT_TOK
          | identifier dimension_list EQU_TOK expression 
          | identifier EQU_TOK expression THISDOT_TOK
          | identifier EQU_TOK expression 
          | identifier dimension_list
          | identifier EQU_TOK class_new 
     //     | EQU_TOK class_new	 
		  ;

real_type_spec : DIGIT_TOK
          | ps_or_hier_identifier EQU_TOK expression 
          | ps_or_hier_identifier {
                                                               QCString tt=getVerilogString();
		                                                      VerilogDocGen::parseEnum();
		                          }                           
       
          | ps_or_hier_identifier LBRACE_TOK {
                                             QCString s=$<cstr>0; 
                                             QCString s1=$<cstr>1; 
                                             //assert(s1.data() && s.data());
											  if(s1.data()!=0  && s.data()!=0)
                                             VerilogDocGen::parseModuleInst(s,s1);
		  } list_of_port_connections  RBRACE_TOK {vbufreset();}
		  | ps_or_hier_identifier LBRACE_TOK    {
                                                         QCString s=$<cstr>0; 
                                             QCString s1=$<cstr>1; 
                                             //if(s1.data()==0 && s.data()==0)
												 
                                             if(s1.data()!=0  && s.data()!=0)
											 {
											  VerilogDocGen::parseModuleInst(s,s1); 
											 }
		                                                   }RBRACE_TOK {vbufreset();}
		  | ps_or_hier_identifier EQU_TOK class_new 
          | parameter_value_assignment {
                                                               QCString tt=getVerilogString();
		                                                     }module_instance_list  
		  
		  ;
		  
		  
variable_type:real_type
              ;

list_of_identifiers :  simple_identifier
                   | list_of_identifiers COMMA_TOK simple_identifier

list_of_specparam_assignments : specparam_assignment 
							   | list_of_specparam_assignments COMMA_TOK specparam_assignment 				
                               ;

list_of_variable_identifiers  : variable_type                                         { VerilogDocGen::parseEnum();}                          
						      |	list_of_variable_identifiers COMMA_TOK variable_type  { VerilogDocGen::parseEnum();}      
							  ;
	
							  
list_of_variable_identifiers_spec  : real_type_spec                                          {VerilogDocGen::parseEnum();}      
						      |	list_of_variable_identifiers_spec COMMA_TOK real_type_spec  { VerilogDocGen::parseEnum();}      
							  ;
							  
							  						  
//------------------------------------------------------------------------------------------------------
//----------------------------A.2.4 Declaration assignments --------------------------------------------
//-----------------------------------------------------------------------------------------------------
      
net_decl_assignment : hierachical_identifier EQU_TOK expression                {VerilogDocGen::parseReg(VerilogDocGen::currentVerilog);} 
                    | hierachical_identifier dimension_list EQU_TOK expression {VerilogDocGen::parseReg(VerilogDocGen::currentVerilog);}
					; 

param_assignment : simple_identifier EQU_TOK expression                 { VerilogDocGen::parseParam(VerilogDocGen::currentVerilog); }
                  | simple_identifier dimension_list EQU_TOK expression {  VerilogDocGen::parseParam(VerilogDocGen::currentVerilog); }
	              | simple_identifier EQU_TOK data_type_spec            { VerilogDocGen::parseParam(VerilogDocGen::currentVerilog); }
	              ;


				 
specparam_assignment : identifier EQU_TOK mintypemax_expression  {  VerilogDocGen::parseParam(VerilogDocGen::currentVerilog); }
                     // | PATHPULSE_TOK EQU_TOK mintypemax_expression 
					  ;
					  
					  
					  
class_new   : NEW_TOK 
            | NEW_TOK  LBRACE_TOK list_of_arguments RBRACE_TOK 
		    | NEW_TOK  LBRACE_TOK  RBRACE_TOK 
			| NEW_TOK ps_or_hier_identifier 
			;
			
dynamic_array_new : NEW_TOK LBRACKET_TOK expression RBRACKET_TOK
                   | NEW_TOK LBRACKET_TOK expression RBRACKET_TOK LBRACE_TOK expression RBRACE_TOK 
                   ;
					  
//------------------------------------------------------------------------------------------------------
//----------------------------A.2.5 Declaration ranges --------------------------------------------
//-----------------------------------------------------------------------------------------------------

dimension : LBRACKET_TOK range_expression  RBRACKET_TOK
           | LBRACKET_TOK expression RBRACKET_TOK   
		   | LBRACKET_TOK MULT_TOK RBRACKET_TOK
		   | LBRACKET_TOK RBRACKET_TOK
		   | LBRACKET_TOK data_type_spec RBRACKET_TOK
		   | LBRACKET_TOK error RBRACKET_TOK
           ;

dimension_list: dimension
              | dimension_list dimension
			   ;


packed_dimension  : LBRACKET_TOK RBRACKET_TOK   
                  | LBRACKET_TOK MULT_TOK RBRACKET_TOK
                  | LBRACKET_TOK msb_constant_expression COLON_TOK lsb_constant_expression RBRACKET_TOK   
                  | LBRACKET_TOK error RBRACKET_TOK
                  ;
                  
packed_dimension_list : dimension                       {VerilogDocGen::enumType=getVerilogString();}
                      | dimension_list dimension {VerilogDocGen::enumType=getVerilogString();}
                      ;
					  
//unsized_dimension : LBRACKET_TOK RBRACKET_TOK

//queue_dimension : LBRACKET_TOK DOLLAR_TOK RBRACKET_TOK
//                |  LBRACKET_TOK DOLLAR_TOK COLON_TOK expression RBRACKET_TOK 
//				;

//variable_dimension : sized_or_unsized_dimension 
//                     | associative_dimension
//                     | queue_dimension
//					 ;
					 
//associative_dimension : LBRACKET_TOK MULT_TOK RBRACKET_TOK
//                      |  LBRACKET_TOK data_type RBRACKET_TOK 
//					  ;

//sized_or_unsized_dimension : dimension
//                            | unsized_dimension
//							;
//------------------------------------------------------------------------------------------------------
//----------------------------A.2.6 Function declarations --------------------------------------------
//-----------------------------------------------------------------------------------------------------

xrange:/*empty*/
							 | dimension  {VerilogDocGen::enumType=getVerilogString();}
	  ;
 
xsigned: /*empty*/
       | SIGNED_TOK
	   ;
	   
automatic : /* leer1 */
	   | STATIC_TOK   {VerilogDocGen::portType+="static ";}
		   | AUTO_TOK {}
	   ;
	
function_type_or_implicit : VOID_TOK  
                       | data_type_spec
                       | simple_identifier
					   | zz identifier
					   | zz zz identifier
					   | packed_dimension_list
					   | signing packed_dimension_list				  
					   | signing
					   ;					   


function_type_or_implicit1 : VOID_TOK  
                       | data_type_spec
                       | simple_identifier 
                       ;	

zz: identifier CCOLON_TOK 
   

 constructor : zz NEW_TOK  {VerilogDocGen::addConstructor(true);} 
             |  NEW_TOK  {
                           {VerilogDocGen::addConstructor(true);} 
                        }
             | zz zz   NEW_TOK   {VerilogDocGen::addConstructor(true);} 
              | zz zz zz  NEW_TOK  {VerilogDocGen::addConstructor(true);} 
             ;
             
                                         
function_declaration : FUNC_TOK automatic function_body_declaration	

SEMM_TOK : SEM_TOK { VerilogDocGen::insideFunction=TRUE; }

function_body_declaration: function_type_or_implicit func_name SEMM_TOK tf_declaration_list function_statement_or_null_list end_func
		                  |  func_name SEMM_TOK tf_declaration_list function_statement_or_null_list end_func	
                     	  | function_type_or_implicit func_name SEMM_TOK  function_statement_or_null_list end_func	
                          | function_type_or_implicit func_name SEMM_TOK end_func	
                         
                          |  func_name SEMM_TOK  function_statement_or_null_list end_func	
						  |  func_name SEMM_TOK tf_declaration_list end_func	
						  |  func_name SEMM_TOK  end_func	
						
						  |  func_name SEMM_TOK error end_func	
						  | function_type_or_implicit func_name SEMM_TOK tf_declaration_list end_func
                          | function_type_or_implicit func_name SEMM_TOK error end_func
                          | function_type_or_implicit func_name LBRACE_TOK tf_port_list_empty RBRACE_TOK SEMM_TOK tf_declaration_list function_statement_or_null_list end_func
		                  |  func_name LBRACE_TOK tf_port_list_empty RBRACE_TOK  SEMM_TOK tf_declaration_list function_statement_or_null_list end_func	
                     	  | function_type_or_implicit func_name LBRACE_TOK tf_port_list_empty RBRACE_TOK SEMM_TOK  function_statement_or_null_list end_func	
                          |   func_name LBRACE_TOK tf_port_list_empty RBRACE_TOK SEMM_TOK  function_statement_or_null_list end_func	
						  |  func_name LBRACE_TOK tf_port_list_empty RBRACE_TOK  SEMM_TOK tf_declaration_list end_func	
						  |  func_name LBRACE_TOK tf_port_list_empty RBRACE_TOK  SEMM_TOK  end_func	
						 
						 | function_type_or_implicit func_name LBRACE_TOK tf_port_list_empty RBRACE_TOK SEMM_TOK  end_func
                         
						   
						  | function_type_or_implicit func_name LBRACE_TOK tf_port_list_empty RBRACE_TOK SEMM_TOK tf_declaration_list end_func
                        
					      | constructor SEMM_TOK supnew function_statement_or_null_list end_func	
					      | constructor SEMM_TOK  block_item_declaration_list  supnew  end_func	
					      | constructor SEMM_TOK  block_item_declaration_list  supnew function_statement_or_null_list end_func	
					      | constructor SEMM_TOK    supnew  end_func	
					      | constructor SEMM_TOK  block_item_declaration_list  function_statement_or_null_list end_func	
					      | constructor SEMM_TOK  function_statement_or_null_list end_func	
					      | constructor SEMM_TOK    end_func	
					    
					       | constructor  LBRACE_TOK tf_port_list_empty RBRACE_TOK  SEMM_TOK block_item_declaration_list function_statement_or_null_list  end_func	
					       | constructor  LBRACE_TOK tf_port_list_empty RBRACE_TOK  SEMM_TOK block_item_declaration_list   end_func	
					       | constructor  LBRACE_TOK tf_port_list_empty RBRACE_TOK  SEMM_TOK block_item_declaration_list  supnew  end_func	
					       | constructor   LBRACE_TOK tf_port_list_empty RBRACE_TOK SEMM_TOK block_item_declaration_list  supnew function_statement_or_null_list end_func	
					       | constructor   LBRACE_TOK tf_port_list_empty RBRACE_TOK SEMM_TOK supnew  end_func	
					       | constructor   LBRACE_TOK tf_port_list_empty RBRACE_TOK SEMM_TOK supnew function_statement_or_null_list end_func	
					       | constructor   LBRACE_TOK tf_port_list_empty RBRACE_TOK SEMM_TOK end_func					
						   | constructor   LBRACE_TOK tf_port_list_empty RBRACE_TOK SEMM_TOK  function_statement_or_null_list end_func	
					     
						  ;
					      
						    
 function_statement_or_null_list : function_statement_or_null
                                 | function_statement_or_null_list function_statement_or_null                         
                                 ;
 
 tf_port_list_empty : /* emppty111 */
                    |  tf_port_list {VerilogDocGen::portType="";}
                    ; 

end_func : ENDFUNC_TOK                       {if(!VerilogDocGen::parseCode &&  VerilogDocGen::currentFunctionVerilog) {
					                          VerilogDocGen::currentFunctionVerilog->endBodyLine=getVerilogEndLine();}
		                                      
		                                      VerilogDocGen::currentFunctionVerilog=0; 
											  VerilogDocGen::portType.resize(0);
											  vbufreset();
											  VerilogDocGen::insideFunction=FALSE;
		                                      }
         | ENDFUNC_TOK COLON_TOK identifier  {if(!VerilogDocGen::parseCode &&  VerilogDocGen::currentFunctionVerilog ){ VerilogDocGen::currentFunctionVerilog->endBodyLine=getVerilogEndLine(); VerilogDocGen::portType.resize(0);}
		                                       VerilogDocGen::currentFunctionVerilog=0; vbufreset();VerilogDocGen::insideFunction=FALSE;}
		 | ENDFUNC_TOK COLON_TOK NEW_TOK     {if(!VerilogDocGen::parseCode &&  VerilogDocGen::currentFunctionVerilog) {VerilogDocGen::currentFunctionVerilog->endBodyLine=getVerilogEndLine(); VerilogDocGen::portType.resize(0);}VerilogDocGen::currentFunctionVerilog=0; vbufreset();VerilogDocGen::insideFunction=FALSE;}
         ;

function_prototype : FUNC_TOK function_type_or_implicit func_name  LBRACE_TOK tf_port_list_empty RBRACE_TOK
                    | FUNC_TOK  func_name  LBRACE_TOK tf_port_list_empty RBRACE_TOK
                    | FUNC_TOK  function_type_or_implicit func_name                   
					;
                    
 func_name : simple_identifier {
					             VerilogDocGen::addFunction($<cstr>1);
                               }                 
                    
dpi_function_import_property : CONTEXT_TOK            {VerilogDocGen::portType+="context ";}
                              | PURE_TOK VIRTUAL_TOK  {VerilogDocGen::portType+="pure ";}
							  | PURE_TOK              {VerilogDocGen::portType+="pure ";}
                              ;
                              

                         
 c_identifier :  /* empty*/
              | identifier EQU_TOK
              ;                         
                  
dpi_function_proto :function_prototype {vbufreset();}

dpi_task_proto : task_prototype {vbufreset();}

task_prototype : TASK_TOK func_name LBRACE_TOK tf_port_list_empty RBRACE_TOK {if(!VerilogDocGen::parseCode && VerilogDocGen::currentFunctionVerilog){VerilogDocGen::currentFunctionVerilog->spec=VerilogDocGen::TASK;}}

//------------------------------------------------------------------------------------------------------
//---------------------------- A.2.7 Task declarations  --------------------------------------------
//-----------------------------------------------------------------------------------------------------

task_declaration : TASK_TOK   automatic func_name SEMM_TOK 
                    tf_declaration_list statement_list end_task                                     
     			
				| TASK_TOK   automatic func_name SEMM_TOK end_task   
                            
    			| TASK_TOK   automatic func_name SEMM_TOK 
                    statement_list end_task                 
                
				 |  TASK_TOK  automatic  func_name  LBRACE_TOK  tf_port_list_empty RBRACE_TOK SEMM_TOK 
                    block_item_declaration_list statement_list end_task                                    
  				
				 |  TASK_TOK  automatic  func_name LBRACE_TOK  tf_port_list_empty RBRACE_TOK SEMM_TOK 
                     statement_list end_task                                    
                	
                 |  TASK_TOK  automatic  func_name  LBRACE_TOK  tf_port_list_empty RBRACE_TOK SEMM_TOK 
                    block_item_declaration_list end_task                                    
  			
				 | TASK_TOK error end_task   
				 | TASK_TOK  automatic  func_name LBRACE_TOK  tf_port_list_empty RBRACE_TOK SEMM_TOK  end_task
				 ;

				 
end_task : ENDTASK_TOK   {
				   if(!VerilogDocGen::parseCode &&  VerilogDocGen::currentFunctionVerilog )
				    {
						VerilogDocGen::currentFunctionVerilog->endBodyLine=getVerilogEndLine();
						VerilogDocGen::currentFunctionVerilog->spec=VerilogDocGen::TASK;
				   }
				   VerilogDocGen::currentFunctionVerilog=0;
				   vbufreset();
				   VerilogDocGen::insideFunction=FALSE;
		    }

         | ENDTASK_TOK COLON_TOK identifier {
			  if(! VerilogDocGen::parseCode &&  VerilogDocGen::currentFunctionVerilog)
			   {
		       VerilogDocGen::currentFunctionVerilog->endBodyLine=getVerilogEndLine();
			   VerilogDocGen::currentFunctionVerilog->spec=VerilogDocGen::TASK;
			  } 
			  VerilogDocGen::currState=0;
			  VerilogDocGen::insideFunction=FALSE;
			  vbufreset();
			  VerilogDocGen::currentFunctionVerilog=0;
		  }
        ;		 
				 

tf_port_list : tf_port_item                          
              | tf_port_list COMMA_TOK tf_port_item  
              |  tf_port_list COMMA_TOK
			  | COMMA_TOK
			  ;


data_type_or_implicit11 : data_type 
                        | signing    
					    | signing packed_dimension_list  
					    | packed_dimension_list  
                        ;
             			 
tf_port_item : 	port_direction data_type_or_implicit11	variable_type	{ VerilogDocGen::parseEnum();vbufreset();}
			   | data_type_or_implicit11  variable_type                 {VerilogDocGen::parseEnum();vbufreset();} 
			   | variable_type                                          { VerilogDocGen::parseEnum();vbufreset();} 
			   | port_direction variable_type                           {VerilogDocGen::parseEnum();vbufreset();} 
			  // | THISDOT_TOK
			   ;
				 

	
port_direction : INPUT_TOK port_types  {VerilogDocGen::portType="";VerilogDocGen::portType+="input ";}
               | OUTPUT_TOK port_types {VerilogDocGen::portType="";VerilogDocGen::portType+="output ";}
			   | INOUT_TOK port_types  {VerilogDocGen::portType="";VerilogDocGen::portType+="inout ";}
			   | CONST_TOK REF_TOK port_types  {VerilogDocGen::portType="";VerilogDocGen::portType+="const ref ";}
			   | REF_TOK
			   ;	
	
port_types : /*empty */ 
          | NET_TOK	    
	      ;
	      
	      
block_item_declaration_list :block_item_declaration_list block_item_declaration
							|  block_item_declaration
							;

tf_declaration_list :tf_declaration_list tf_item_declaration
							|  tf_item_declaration
                             ;


tf_item_declaration : block_item_declaration
                    | tf_port_declaration 
					;

tf_port_declaration : attribute_instance  port_direction list_of_variable_identifiers SEM_TOK	
                    | attribute_instance  port_direction  data_type_or_implicit11 list_of_variable_identifiers SEM_TOK	
				    | error SEM_TOK
                    ;
                    	
					 
//------------------------------------------------------------------------------------------------------
//---------------------------- A.2.8 Block item declarations   --------------------------------------------
//-----------------------------------------------------------------------------------------------------

block_item_declaration :    attribute_instance  data_declaration { VerilogDocGen::parseEnum();VerilogDocGen::portType.resize(0); }
                         |  attribute_instance  local_parameter_declaration 
                         |  attribute_instance  parameter_declaration 
                         |  attribute_instance  overload_declaration
                         ;


overload_declaration : BIND_TOK overload_operator FUNC_TOK data_type identifier LBRACE_TOK overload_proto_formals RBRACE_TOK SEM_TOK

overload_operator : PPLUS_TOK
					| PLUS_TOK
					| MULT_TOK
					| MULT_TOK MULT_TOK
					| MINUS_TOK 
					| DMINUS_TOK
					| EQU_TOK
					| EQU_TOK EQU_TOK
					| GT_TOK
					| LT_TOK
					| GT_TOK EQU_TOK
					| EXCLAMATION_TOK EQU_TOK
					| LT_TOK EQU_TOK
					| ENV_TOK
					| PERCENTAL_TOK
                    ;


overload_proto_formals : 
					   | data_type
                       | overload_proto_formals COMMA_TOK data_type
                       ;


//------------------------------------------------------------------------------------------------------
//------------------------------------A.2.9 Interface declarations-------------------------------------
//------------------------------------------------------------------------------------------------------



modport_declaration :MODPORT_TOK modport_item_list SEM_TOK {vbufreset();VerilogDocGen::insideFunction=FALSE;}
                    | MODPORT_TOK error SEM_TOK            {vbufreset();VerilogDocGen::insideFunction=FALSE;}

modport_item_list : modport_item
                  | modport_item_list COMMA_TOK modport_item
                  ;
                  
modport_item :  identifier  LBRACE_TOK  {VerilogDocGen::addModPort($<cstr>1);VerilogDocGen::insideFunction=TRUE;} modport_ports_declaration_list RBRACE_TOK
					|  identifier LBRACE_TOK error RBRACE_TOK
             ;

modport_ports_declaration_list : modport_ports_declaration
                          | modport_ports_declaration_list COMMA_TOK modport_ports_declaration

modport_ports_declaration : attribute_instance  modport_simple_ports_declaration
                          |  attribute_instance  modport_hierarchical_ports_declaration
                          |  attribute_instance  modport_tf_ports_declaration
                          |  attribute_instance  modport_clocking_declaration
                          ;

modport_clocking_declaration : CLOCKING_TOK identifier
                       

modport_tf_port_list : modport_tf_port 
                     | modport_tf_port_list COMMA_TOK modport_tf_port
                     ;

modport_simple_ports_declaration :  port_direction  modport_simple_port_list
                                 ;
                              

modport_simple_port_list : modport_simple 
                      
 modport_simple  : identifier   
                  | DOT_TOK identifier LBRACE_TOK RBRACE_TOK
               	  | DOT_TOK identifier LBRACE_TOK expression RBRACE_TOK 
                  ;          
                                 


modport_hierarchical_ports_declaration : simple_identifier 
                                       | simple_identifier LBRACKET_TOK expression RBRACKET_TOK DOT_TOK identifier
                                       | DOT_TOK identifier LBRACE_TOK RBRACE_TOK
               	                       | DOT_TOK identifier LBRACE_TOK expression RBRACE_TOK 
              
                                       ;
                                       
modport_tf_ports_declaration : import_export modport_tf_port_list

modport_tf_port : method_prototype 
                 | identifier
                ;
method_prototype : task_prototype 
                 | function_prototype 
                 ;
                 

import_export : IMPORT_TOK 
              | EXPORT_TOK
              ;
              
//------------------------------------------------------------------------------------------------------
//------------------------------------A.2.10 Assertion declarations-------------------------------------
//------------------------------------------------------------------------------------------------------
	
concurrent_assertion_item :concurrent_assertion_statement	{vbufreset();}
								 |  ps_or_hier_identifier COLON_TOK concurrent_assertion_statement {vbufreset();}
		 	 ;
							 
  concurrent_assertion_statement : assert_property_statement
                                  | assume_property_statement
                                  | cover_property_statement
                                  ;
								  
	assert_property_statement: ASSERT_TOK PROPERTY_TOK LBRACE_TOK property_spec RBRACE_TOK action_block
	                        |  ASSERT_TOK PROPERTY_TOK LBRACE_TOK error RBRACE_TOK action_block
	                        ;
	                        
	assume_property_statement : ASSUME_TOK PROPERTY_TOK LBRACE_TOK property_spec RBRACE_TOK SEM_TOK
	                          | ASSUME_TOK PROPERTY_TOK LBRACE_TOK error RBRACE_TOK SEM_TOK
	                          ;
	                          
	expect_property_statement: EXPECT_TOK LBRACE_TOK property_spec RBRACE_TOK action_block
	                         | EXPECT_TOK LBRACE_TOK error RBRACE_TOK action_block
	                         ;
	                         
	cover_property_statement:COVER_TOK PROPERTY_TOK LBRACE_TOK property_spec RBRACE_TOK statement_or_null
	                        | COVER_TOK PROPERTY_TOK LBRACE_TOK error RBRACE_TOK statement_or_null
                            ;
                            
   property_declaration : PROPERTY_TOK property_identifier  LBRACE_TOK list_of_formals RBRACE_TOK sem_exp property_spec SEM_TOK endprop
                         | PROPERTY_TOK property_identifier  LBRACE_TOK  RBRACE_TOK sem_exp property_spec SEM_TOK endprop                   
						 | PROPERTY_TOK property_identifier  sem_exp property_spec SEM_TOK endprop
	                     | PROPERTY_TOK property_identifier  sem_exp assertion_variable_declaration_list sequence_expr SEM_TOK endprop
	                     | PROPERTY_TOK property_identifier LBRACE_TOK list_of_formals RBRACE_TOK sem_exp assertion_variable_declaration_list sequence_expr SEM_TOK endprop
						 | PROPERTY_TOK property_identifier LBRACE_TOK RBRACE_TOK sem_exp assertion_variable_declaration_list sequence_expr SEM_TOK endprop
	                     | PROPERTY_TOK error endprop 
	                     ;
	                     
	
sem_exp : SEM_TOK {
						VerilogDocGen::addProperty(0);
                    }	
	                     
  property_identifier : identifier { 
                            if(! VerilogDocGen::parseCode) { 
								VerilogDocGen::classQu=$<cstr>1;
                                 vbufreset();
						       } 
                        }
	
endprop : ENDPROPERTY_TOK
	        | ENDPROPERTY_TOK COLON_TOK identifier
    
	property_spec :  property_expr
                   | DISABLE_TOK IFF_TOK LBRACE_TOK dist_list RBRACE_TOK  property_expr
				   | clocking_event DISABLE_TOK IFF_TOK LBRACE_TOK dist_list RBRACE_TOK  property_expr
	              
    
     property_expr : sequence_expr			  
                   | sequence_expr PROPLT_TOK  property_expr
                   | sequence_expr PROPEQU_TOK property_expr
                    ;

  concurrent_assertion_item_declaration : sequence_declaration   { VerilogDocGen::currentFunctionVerilog=0;vbufreset();}
                                         |  property_declaration { VerilogDocGen::currentFunctionVerilog=0;vbufreset();}
										 ;
	
	                     
	 sequence_instance :    hierachical_identifier LBRACE_TOK arg_commend RBRACE_TOK
	                    |   hierachical_identifier LBRACE_TOK event_expression_list RBRACE_TOK
						;
	 
	 arg_commend      : DOT_TOK hierachical_identifier  LBRACE_TOK event_expression RBRACE_TOK 
	                  | arg_commend COMMA_TOK DOT_TOK hierachical_identifier  LBRACE_TOK event_expression RBRACE_TOK 
	                  ;

	sequence_declaration : SEQUENCE_TOK identifier_seq  LBRACE_TOK list_of_formals RBRACE_TOK semp_tok sequence_expr SEM_TOK endsec
                         | SEQUENCE_TOK identifier_seq  LBRACE_TOK  RBRACE_TOK semp_tok sequence_expr SEM_TOK endsec
						 | SEQUENCE_TOK identifier_seq  semp_tok sequence_expr SEM_TOK endsec
						 | SEQUENCE_TOK identifier_seq  semp_tok assertion_variable_declaration_list sequence_expr SEM_TOK endsec 
	                     | SEQUENCE_TOK identifier_seq LBRACE_TOK list_of_formals RBRACE_TOK semp_tok assertion_variable_declaration_list sequence_expr SEM_TOK endsec 
	                     | SEQUENCE_TOK identifier_seq LBRACE_TOK RBRACE_TOK semp_tok assertion_variable_declaration_list sequence_expr SEM_TOK endsec 
	 					 | SEQUENCE_TOK error SEM_TOK endsec 
	                    ;

semp_tok : SEM_TOK { VerilogDocGen::addProperty(2); }

identifier_seq : identifier {
						   VerilogDocGen::classQu=$<cstr>1; vbufreset();
						   VerilogDocGen::currState=VerilogDocGen::COVER;
				           }

endsec : ENDSEQUENCE_TOK                                {VerilogDocGen::currState=0;}
				 | ENDSEQUENCE_TOK COLON_TOK identifier {VerilogDocGen::currState=0;}
	

 
	 sequence_expr  : expression_or_dist //	cycle_seq_list
	                | cycle_seq_list
                    | sequence_expr cycle_seq_list			 
	                | expression_or_dist  boolean_abbrev 
           	        | LBRACE_TOK expression_or_dist sequence_match_item_list RBRACE_TOK  boolean_abbrev 
                    | LBRACE_TOK expression_or_dist sequence_match_item_list RBRACE_TOK   
	                | LBRACE_TOK sequence_expr RBRACE_TOK 
				    | sequence_expr OOO  sequence_expr
                    | clocking_event sequence_expr
	                | FIRST_MATCH_TOK LBRACE_TOK sequence_expr  sequence_match_item_list RBRACE_TOK 
	                | FIRST_MATCH_TOK LBRACE_TOK sequence_expr RBRACE_TOK 
	
	                   
	cycle_seq_list : cycle_delay_range sequence_expr	
	               | cycle_seq_list cycle_delay_range sequence_expr 	
	                ;
	
	                
	 OOO : INTERSECT_TOK 
	      | WITHIN_TOK  
	      | THROUGHOUT_TOK 
		  | GATE_TOK 
		 
	      ;               
	            			   
	
	cycle_delay_range : cycle_delay 
	                  | DOUBLEPARA_TOK LBRACKET_TOK expression RBRACKET_TOK
	                  | DOUBLEPARA_TOK LBRACKET_TOK range_expression RBRACKET_TOK
	                  ;					  
	
	sequence_match_item_list : COMMA_TOK sequence_match_item
                             | sequence_match_item_list	COMMA_TOK sequence_match_item
							 ;
	
	sequence_match_item : operator_assignment
                        | inc_or_dec_expression
                        | function_call
	                    ;
	
	list_of_formals : formal_list_item 
	                | list_of_formals COMMA_TOK formal_list_item 
					;
					
					
	formal_list_item : identifier 
				     | data_type_spec identifier
	                 | identifier EQU_TOK actual_arg_expr
					  ;
	
	actual_arg_expr : event_expression

	
	boolean_abbrev : dimension
               //   | non_consecutive_repetition
               //    | goto_repetition
                   ;
                   
                   
                     
	expression_or_dist : expression
	                   | expression_or_dist DIST_TOK  
                       | expression_or_dist LRAM_TOK dist_list RRAM_TOK  
	                  	                 
					   | boolean_abbrev
	                    ;
	
	assertion_variable_declaration_list: assertion_variable_declaration
	                              | assertion_variable_declaration_list assertion_variable_declaration
	                              ;
								  
	assertion_variable_declaration : data_type list_of_variable_identifiers SEM_TOK
	                               ;
//------------------------------------------------------------------------------------------------------
//------------------------------------A.2.11 Covergroup declarations -----------------------------------
//------------------------------------------------------------------------------------------------------
	
covergroup_declaration : COVERGROUP_TOK cover_ident  coverage_event SEM_TOK {VerilogDocGen::addCovergroup(0);} coverage_spec_or_option_list endcover
                       | COVERGROUP_TOK cover_ident  SEM_TOK {VerilogDocGen::addCovergroup(2);} coverage_spec_or_option_list endcover  
                       | COVERGROUP_TOK cover_ident  LBRACE_TOK  tf_port_list  RBRACE_TOK SEM_TOK {VerilogDocGen::addCovergroup(3);} coverage_spec_or_option_list endcover  
                       | COVERGROUP_TOK cover_ident LBRACE_TOK  tf_port_list  RBRACE_TOK coverage_event SEM_TOK {VerilogDocGen::addCovergroup(4);} coverage_spec_or_option_list endcover   
                       | COVERGROUP_TOK  error endcover 
                       ;
                         
                       
cover_ident : identifier   {
						    VerilogDocGen::classQu=$<cstr>1; vbufreset();
						    VerilogDocGen::currState=VerilogDocGen::COVERGROUP;
			              }                    
                          
endcover : ENDGROUP_TOK  COLON_TOK identifier   {VerilogDocGen::currState=0;vbufreset();} 
         | ENDGROUP_TOK                         {VerilogDocGen::currState=0;vbufreset();}
         ;

coverage_spec_or_option_list : coverage_spec_or_option_list coverage_spec_or_option   
                             | coverage_spec_or_option     
         
coverage_spec_or_option :  coverage_spec  
                        |  coverage_option 

coverage_option : simple_identifier EQU_TOK expression SEM_TOK
               // | TYPEOPTIONDOT_TOK  identifier EQU_TOK expression
                ;

coverage_spec : cover_point
              | cover_cross
              ;
              
coverage_event : clocking_event
               | AT_TOK AT_TOK LBRACE_TOK block_event_expression RBRACE_TOK
               | AT_TOK AT_TOK LBRACE_TOK error RBRACE_TOK
               ;
               
block_event_expression : block_event_expression SOR_TOK block_event_expression
                       | BEGIN_TOK ps_or_hier_identifier
                       | END_TOK ps_or_hier_identifier
                       ;

cover_point :identifier COLON_TOK COVERPOINT_TOK expression iff_expr_empty bins_or_empty
             | COVERPOINT_TOK expression iff_expr_empty bins_or_empty
             | COVERPOINT_TOK error bins_or_empty
             ;

bins_or_empty : LRAM_TOK attribute_instance bins_or_options_list RRAM_TOK
              | LRAM_TOK error RRAM_TOK
              | LRAM_TOK RRAM_TOK
              | SEM_TOK
              ;

bins_or_options_list :  bins_or_options SEM_TOK              
                     | bins_or_options_list bins_or_options SEM_TOK
                     ;
                     
bins_or_options : coverage_option
                | bins_keyword identifier express_empty  EQU_TOK right_side 
                | WILDCARD_TOK bins_keyword identifier express_empty  EQU_TOK right_side
                ;

right_side : DEFAULT_TOK SEQUENCE_TOK iff_expr_empty
          | DEFAULT_TOK iff_expr_empty
          | LRAM_TOK range_list RRAM_TOK iff_expr_empty              
          | trans_list iff_expr_empty 
          ;
                          
                
express_empty : /*empty*/
              | LBRACKET_TOK RBRACKET_TOK
              | LBRACKET_TOK expression RBRACKET_TOK   
              ;
              
                
iff_expr_empty : /*empty*/
               | iff_expr
               ;                
                
bins_keyword: BINS_TOK 
            | ILLEGALBINS_TOK
            | IGNOREBINS_TOK
             ;

trans_list : LBRACE_TOK trans_set RBRACE_TOK
           | trans_list COMMA_TOK LBRACE_TOK  trans_set RBRACE_TOK
           | LBRACE_TOK error RBRACE_TOK
           ;

trans_set : trans_range_list EQULT_TOK trans_range_list 
         // | trans_range_list  EQULT_TOK trans_range_list tr_list
         | trans_set  tr_list
		 ;
 
tr_list : tr_list EQULT_TOK trans_range_list
            | EQULT_TOK trans_range_list
            ;                   

trans_range_list : trans_item
                 | trans_item  LBRACKET_TOK MULT_TOK repeat_range RBRACKET_TOK
                 | trans_item  LBRACKET_TOK EQU_TOK repeat_range RBRACKET_TOK
                 | trans_item  LBRACKET_TOK error RBRACKET_TOK
                 ;
    
 
range_list :  value_range
            | range_list COMMA_TOK value_range
           ;
                
                              
trans_item : range_list

repeat_range : expression
             | expression COLON_TOK expression
             ;

cover_cross : identifier COLON_TOK CROSS_TOK list_of_coverpoints iff_expr select_bins_or_empty
            | CROSS_TOK list_of_coverpoints iff_expr select_bins_or_empty
            | CROSS_TOK list_of_coverpoints  select_bins_or_empty
            | CROSS_TOK error   select_bins_or_empty
            | identifier COLON_TOK CROSS_TOK list_of_coverpoints  select_bins_or_empty
            ;
 
list_of_coverpoints:cross_item
                   | list_of_coverpoints COMMA_TOK cross_item
                   ;
                   

cross_item : ps_or_hier_identifier
           ;

select_bins_or_empty : LRAM_TOK   bins_selection_or_option_list   RRAM_TOK
                     | LRAM_TOK   error   RRAM_TOK
                     | LRAM_TOK RRAM_TOK
                     | SEM_TOK
                     ;

                     
bins_selection_or_option_list :   bins_selection_or_option_list    bins_selection_or_option
                              |   bins_selection_or_option 
                              ;
                                        
bins_selection_or_option : attribute_instance coverage_option SEM_TOK
                         |  attribute_instance  bins_selection SEM_TOK
                         ;
                         
bins_selection : bins_keyword identifier EQU_TOK select_expression 
               |  bins_keyword identifier EQU_TOK select_expression iff_expr 
               ;
  
iff_expr :   IFF_TOK  LBRACE_TOK expression RBRACE_TOK              
                            
select_expression : select_condition
                  | EXCLAMATION_TOK select_condition
                  | LBRACE_TOK select_expression RBRACE_TOK
                  | LBRACE_TOK error RBRACE_TOK
                  | select_expression AAND_TOK select_expression
                  | select_expression OOR_TOK select_expression            
                  ;

select_condition : BINSOF_TOK LBRACE_TOK bins_expression RBRACE_TOK
                | BINSOF_TOK LBRACE_TOK bins_expression RBRACE_TOK INTERSECT_TOK LRAM_TOK open_range_list RRAM_TOK
                ;
                  
bins_expression : ps_or_hier_identifier 
                ;
                
open_range_list: value_range 
               | open_range_list	COMMA_TOK	value_range 
               ;
//------------------------------------------------------------------------------------------------------
//---------------------------- A.3.1 Primitive instantiation and instances -----------------------------
//------------------------------------------------------------------------------------------------------

gate_instantiation : gate_ident delay3 cmos_switch_instance_list SEM_TOK 
				   | gate_ident cmos_switch_instance_list SEM_TOK        
				   | gate_ident drive_strength cmos_switch_instance_list SEM_TOK				  
				   | gate_ident drive_strength delay3 cmos_switch_instance_list SEM_TOK				  
			       | gate_ident pull_gate_instance_list SEM_TOK           
				   | gate_ident error SEM_TOK 
				   ;

gate_ident: GATE_TOK
          | SOR_TOK
          ;
          
pull_gate_instance_list: pull_gate_instance
                       | pull_gate_instance_list COMMA_TOK pull_gate_instance
					   ;

cmos_switch_instance_list:cmos_switch_instance
                         | cmos_switch_instance_list COMMA_TOK cmos_switch_instance
                          ;



cmos_switch_instance :name_of_gate_instance  LBRACE_TOK output_terminal COMMA_TOK expression_list RBRACE_TOK
                     | LBRACE_TOK output_terminal COMMA_TOK expression_list RBRACE_TOK
                     | LBRACE_TOK error RBRACE_TOK
                     ; 



pull_gate_instance : name_of_gate_instance  LBRACE_TOK output_terminal RBRACE_TOK
                   | LBRACE_TOK output_terminal RBRACE_TOK
                   ;  

name_of_gate_instance : identifier dimension 
                      | identifier
					  ;

//------------------------------------------------------------------------------------------------------
//---------------------------- A.3.2 Primitive strengths  --------------------------------------------
//-----------------------------------------------------------------------------------------------------


output_terminal : net_lvalue
                ;

//------------------------------------------------------------------------------------------------------
//---------------------------- A.4.1 Module instantiation  --------------------------------------------
//-----------------------------------------------------------------------------------------------------

					 
module_instance_list:  module_instance
                      | module_instance_list COMMA_TOK module_instance 
                     ;

parameter_value_assignment : PARA_TOK LBRACE_TOK list_of_parameter_assignments RBRACE_TOK  {
					                                                                       QCString tt=getVerilogString();
																						   if(!VerilogDocGen::parseCode)
																						   {
																							//   int u=tt.find('#');
																							//   if(u>0)
																							    VerilogDocGen::paraType=tt.simplifyWhiteSpace();
																							//	   VerilogDocGen::paraType=tt.right(tt.length()-u);
																						   }
																						   vbufreset();
							                                                               }
                            |  PARA_TOK LBRACE_TOK error RBRACE_TOK  SEM_TOK
                            ;
list_of_parameter_assignments : ordered_parameter_assignment_list
                               | named_parameter_assignment_list
                               ;

ordered_parameter_assignment_list:ordered_parameter_assignment {}
								 | ordered_parameter_assignment_list COMMA_TOK ordered_parameter_assignment {}
                                 ;

ordered_parameter_assignment : expression
						     | data_type_spec identifier
							 | data_type_spec
                             ;

 named_parameter_assignment_list :  named_parameter_assignment {}
                                 |  named_parameter_assignment_list COMMA_TOK named_parameter_assignment {}
                                 ;
                             

named_parameter_assignment : DOT_TOK identifier LBRACE_TOK  expression  RBRACE_TOK 
                           | DOT_TOK identifier LBRACE_TOK    RBRACE_TOK 
                           | DOT_TOK identifier
                            ;




module_instance : identifier11  LBRACE_TOK  list_of_port_connections  RBRACE_TOK 
                | identifier11  LBRACE_TOK  error  RBRACE_TOK 
				| identifier11  LBRACE_TOK   RBRACE_TOK   {
                     QCString j=getVerilogString();
				  }
			    ;

identifier11:ps_or_hier_identifier xrange {
                                            if(! VerilogDocGen::parseCode){
                                            QCString s=getVerilogString();
                                            VerilogDocGen::parseModuleInst(VerilogDocGen::sdataType,s);
                                            VerilogDocGen::sdataType="";
											}
                                             }
             ;

				 
list_of_port_connections : ordered_port_connection_list 
                         | named_port_connection_list 
						 ;
						 
ordered_port_connection_list : ordered_port_connection
                             | ordered_port_connection_list COMMA_TOK ordered_port_connection
							 ;

ordered_port_connection : attribute_instance  expression 
                       
						;
							 
named_port_connection_list : named_port_connection
                           | named_port_connection_list COMMA_TOK named_port_connection
						   ;

named_port_connection : attribute_instance named_parameter_assignment
                      | attribute_instance DOTMULT_TOK
                      ;

//------------------------------------------------------------------------------------------------------
//---------------------------A 4.1.3 Interface/Program instantiation --------------------------------------------
//-----------------------------------------------------------------------------------------------------

//interface_instantiation : identifier parameter_value_assignment module_instance_list SEM_TOK       {fprintf(stderr,"\ninterface instant");assert(0);}
//						| identifier LBRACE_TOK list_of_port_connections RBRACE_TOK SEM_TOK        {fprintf(stderr,"\ninterface instant");assert(0);}

//------------------------------------------------------------------------------------------------------
//---------------------------- A.4.2 Generated instantiation  --------------------------------------------
//-----------------------------------------------------------------------------------------------------
//generated_instantiation ::= generate { generate_item } endgenerate

generated_instantiation :  GENERATE_TOK {VerilogDocGen::generateItem=true;}  generate_item_list  ENDGENERATE_TOK {VerilogDocGen::generateItem=false;}
                        |  GENERATE_TOK error  ENDGENERATE_TOK 
            			;
            					              
generate_item_list :generate_item
                   | generate_item_list generate_item
				   ;
   
   
generate_item_or_null : generate_item   
                      | SEM_TOK
			           ;		  


generate_item : generate_conditional_statement
              | generate_case_statement      
              | generate_loop_statement        
              | generate_block               
			  | module_or_generate_item      
			  ;

generate_conditional_statement  :  IF_TOK LBRACE_TOK  expression RBRACE_TOK generate_item_or_null 
                                 |   IF_TOK LBRACE_TOK  expression RBRACE_TOK generate_item_or_null  ELSE_TOK  generate_item_or_null 
     						     ;

generate_case_statement :CASE_TOK  LBRACE_TOK  expression RBRACE_TOK  genvar_module_case_item_list  ENDCASE_TOK    
							   ;

genvar_module_case_item_list  :  genvar_case_item  
							  |  genvar_module_case_item_list COMMA_TOK genvar_case_item 
							  ;

genvar_case_item   :  expression_list COLON_TOK  generate_item_or_null
                   | DEFAULT_TOK   COLON_TOK  generate_item_or_null
                   | DEFAULT_TOK   generate_item_or_null
				   ;


generate_loop_statement  : FOR_TOK  LBRACE_TOK  genvar_assignment SEM_TOK  expression SEM_TOK  genvar_assignment  RBRACE_TOK BEGIN_TOK COLON_TOK identifier  generate_item_list  END_TOK 
                         ;

genvar_assignment : identifier EQU_TOK expression
                  ;

generate_block  :  BEGIN_TOK COLON_TOK identifier  generate_item_list  END_TOK  
                             |  BEGIN_TOK generate_item_list END_TOK
                             |  BEGIN_TOK error END_TOK 
                             |  BEGIN_TOK COLON_TOK identifier error END_TOK 
                             ;


//------------------------------------------------------------------------------------------------------
//---------------------------- A.5.1 UDP declaration  --------------------------------------------
//-----------------------------------------------------------------------------------------------------

udp_nonansi_declaration : attribute_instance PRIMITIVE_TOK name_of_udp LBRACE_TOK  udp_port_list RBRACE_TOK SEM_TOK
udp_ansi_declaration : attribute_instance  PRIMITIVE_TOK name_of_udp LBRACE_TOK udp_declaration_port_list RBRACE_TOK SEM_TOK


udp_declaration : attribute_instance  PRIMITIVE_TOK name_of_udp  LBRACE_TOK  udp_port_list RBRACE_TOK SEM_TOK
                  udp_port_declaration_list udp_body endprim
                 | attribute_instance  PRIMITIVE_TOK name_of_udp LBRACE_TOK udp_declaration_port_list RBRACE_TOK SEM_TOK
                  udp_port_declaration_list udp_body endprim
             	 | EXTERN_TOK udp_nonansi_declaration
				 | EXTERN_TOK udp_ansi_declaration
				 | attribute_instance PRIMITIVE_TOK name_of_udp LBRACE_TOK DOTMULT_TOK RBRACE_TOK SEM_TOK
				   udp_declaration_port_list udp_body endprim
				 | udp_ansi_declaration udp_body endprim
				 |  attribute_instance  PRIMITIVE_TOK  error endprim {vbufreset();}
				 ;

endprim : ENDPRIMITIVE_TOK { VerilogDocGen::resetTypes(); }
        | ENDPRIMITIVE_TOK COLON_TOK identifier { VerilogDocGen::resetTypes(); }
        ;		
				
name_of_udp:        class_identifier //{assert(0);}
                         ;
 //------------------------------------------------------------------------------------------------------
//---------------------------- A.5.2 UDP Ports  --------------------------------------------
//-----------------------------------------------------------------------------------------------------


udp_port_list : identifier                            
              | udp_port_list COMMA_TOK  identifier 
			  ;
udp_declaration_port_list : udp_output_declaration COMMA_TOK  udp_input_declaration_list
                          ;

udp_input_declaration_list:udp_input_declaration
                           | udp_input_declaration_list COMMA_TOK udp_input_declaration
                           | udp_input_declaration_list COMMA_TOK identifier 
							;

udp_port_declaration_list:udp_port_declaration 
                         | udp_port_declaration_list  udp_port_declaration 
						 ;  

udp_port_declaration : udp_output_declaration SEM_TOK
                     | udp_input_declaration SEM_TOK
                     | udp_reg_declaration SEM_TOK
     				 | udp_port_declaration SEM_TOK
					 ;

udp_output_declaration : attribute_instance  OUTPUT_TOK identifier                                   
                       | attribute_instance  OUTPUT_TOK REG_TOK identifier                         
                       | attribute_instance  OUTPUT_TOK REG_TOK identifier  EQU_TOK expression    
                       | udp_output_declaration COMMA_TOK identifier                                 
					  ;

udp_input_declaration : attribute_instance  INPUT_TOK identifier       
                       | udp_input_declaration COMMA_TOK identifier    
                       ;
udp_reg_declaration :  attribute_instance  REG_TOK identifier             
                     | udp_reg_declaration COMMA_TOK identifier           
					 ;
//------------------------------------------------------------------------------------------------------
//----------------------------5.3 body  --------------------------------------------
//-----------------------------------------------------------------------------------------------------

udp_body :  combinational_body 
         ;

combinational_body : TABLE_TOK combinational_entry_list ENDTABLE_TOK                         
                    | TABLE_TOK error ENDTABLE_TOK                                         
				    | udp_initial_statement  TABLE_TOK combinational_entry_list ENDTABLE_TOK 
					;

combinational_entry_list:combinational_entry
                        | combinational_entry_list combinational_entry
                         ;

combinational_entry : edge_input_list COLON_TOK  output_symbol SEM_TOK
                    | edge_input_list COLON_TOK current_state COLON_TOK next_state SEM_TOK
					;



udp_initial_statement : INITIAL_TOK identifier EQU_TOK init_val SEM_TOK 
                      | INITIAL_TOK error SEM_TOK                        
					  ;

init_val : DIGIT_TOK { VerilogDocGen::identVerilog+=$<cstr>1;VerilogDocGen::writeDigit(); } 
         ;

				   
edge_input_list :edge_indicator
                | level_symbol
                | edge_input_list edge_indicator 
			    | edge_input_list level_symbol
				; 

edge_indicator : LBRACE_TOK level_symbol RBRACE_TOK
               | LBRACE_TOK level_symbol level_symbol RBRACE_TOK
			 //  |  edge_indicator LBRACE_TOK level_symbol RBRACE_TOK
			   | LBRACE_TOK error RBRACE_TOK
			   ;

current_state :level_symbol
              ; 
next_state : output_symbol 
           | MINUS_TOK
		    ;

output_symbol : level_symbol


level_symbol : DIGIT_TOK { VerilogDocGen::identVerilog+=$<cstr>1;VerilogDocGen::writeDigit(); } 
             | QUESTION_TOK
			 | MULT_TOK
			 | LETTER_TOK 

			 ;

//------------------------------------------------------------------------------------------------------
//----------------------------A.5.4 UDP instantiation  --------------------------------------------
//-----------------------------------------------------------------------------------------------------

udp_instantiation : identifierMod   udp_instance_list SEM_TOK
                  | identifierMod drive_strength   udp_instance_list1 SEM_TOK
				  | identifierMod drive_strength  delay2 udp_instance_list1 SEM_TOK
              //	   | identifierMod delay2 udp_instance_list1 SEM_TOK
				  ;


identifierMod: ps_or_hier_identifier {
					        QCString modu=$<cstr>1;
			              }
			  // | zz identifier 

udp_instance_list1: udp_instance1  { vbufreset(); }
                 | udp_instance_list1 COMMA_TOK udp_instance1  { vbufreset(); }
				 ;


udp_instance1 :  LBRACE_TOK  output_terminal COMMA_TOK expression_list RBRACE_TOK  { vbufreset(); }
         	 | identifier  LBRACE_TOK output_terminal COMMA_TOK expression_list RBRACE_TOK  { vbufreset(); }



udp_instance_list: udp_instance  { vbufreset(); }
                 | udp_instance_list COMMA_TOK udp_instance  { vbufreset(); }
				 ;


udp_instance :  LBRACE_TOK output_terminal COMMA_TOK expression_list RBRACE_TOK  { vbufreset(); }
udp_instance :  LBRACE_TOK output_terminal  RBRACE_TOK  { vbufreset(); }


//------------------------------------------------------------------------------------------------------
//----------------------------A.6 Behavioral statements --------------------------------------------
//-----------------------------------------------------------------------------------------------------

continuous_assign : ASSIGN_TOK  drive_strength  delay3  list_of_net_assignments SEM_TOK {vbufreset();}
                  | ASSIGN_TOK    delay3  list_of_net_assignments SEM_TOK              {vbufreset();}
				  | ASSIGN_TOK     list_of_net_assignments SEM_TOK                      {vbufreset();}
				  | ASSIGN_TOK  drive_strength  list_of_net_assignments SEM_TOK         {vbufreset();}
                  | ASSIGN_TOK  error SEM_TOK                                           {vbufreset();}
                  ;

net_alias : ALIAS_TOK net_alias_list SEM_TOK {VerilogDocGen::parseAttribute("alias");}
          | ALIAS_TOK error SEM_TOK
          ;
          	
net_alias_list  :  net_lvalue EQU_TOK net_lvalue
                | net_alias_list EQU_TOK net_lvalue
			    ;
list_of_net_assignments : net_assignment 
                        | list_of_net_assignments COMMA_TOK net_assignment
						;

net_assignment : net_lvalue EQU_TOK expression
               ;

initial_construct : INITIAL_TOK {VerilogDocGen::insideFunction=TRUE;} statement 
                   |INITIAL_TOK error END_TOK  
				   ;

always_keyword : ALWAYS_TOK 
               | ALWAYSCOMB_TOK 
			   | ALWAYSLATCH_TOK 
			   | ALWAYSFF_TOK
               ;
//          {if(!parseCode && currVerilogType==VerilogDocGen::ALWAYS)parseAlways(true);} // alway without ()
   			   
always_construct : always_keyword  {
				       VerilogDocGen::currState=VerilogDocGen::ALWAYS;
				      VerilogDocGen::labelName.resize(0);
				   
				   }
				   
				   statement { if(! VerilogDocGen::parseCode){
					                     
					                         if(VerilogDocGen::currentFunctionVerilog)
											 {
											  VerilogDocGen::currentFunctionVerilog->endBodyLine=getVerilogEndLine();
											  if(  VerilogDocGen::currentFunctionVerilog->endBodyLine<VerilogDocGen::currentFunctionVerilog->startLine || c_lloc.first_line>VerilogDocGen::currentFunctionVerilog->endBodyLine ) // awlays without end
											    VerilogDocGen::currentFunctionVerilog->endBodyLine=c_lloc.first_line;
											    VerilogDocGen::currVerilogType=0;
											    VerilogDocGen::currentFunctionVerilog=0;
												if(!VerilogDocGen::labelName.isEmpty())
													VerilogDocGen::currentFunctionVerilog->name=VerilogDocGen::labelName;
										  }
											 else { // always without ()
                                                 vbufreset();												
												 VerilogDocGen::parseAlways(true);
												 VerilogDocGen::currState=0;
											 }
				   }
											   vbufreset();}
                  | always_construct error END_TOK { vbufreset();VerilogDocGen::currVerilogType=0; VerilogDocGen::currentFunctionVerilog=0;}
				  ; 


				  
blocking_assignment : net_lvalue EQU_TOK delay_or_event_control  expression
              	 	| net_lvalue  EQU_TOK error SEM_TOK					
					| net_lvalue EQU_TOK dynamic_array_new
                    | operator_assignment
					| net_lvalue EQU_TOK class_new
					
					;

nonblocking_assignment : net_lvalue GT_TOK EQU_TOK delay_or_event_control  expression
                    | net_lvalue GT_TOK EQU_TOK error SEM_TOK
					| net_lvalue GT_TOK EQU_TOK   expression
					| net_lvalue GT_TOK EQU_TOK  cycle_delay expression
			        ;

 //------------------------------------------------------------------------------------------------------
//----------------------------A.6.2 Procedureal blocks and assignments--------------------------------------------
//-----------------------------------------------------------------------------------------------------

procedural_continuous_assignments : ASSIGN_TOK variable_assignment 
                                   | DEASSIGN_TOK net_lvalue       
                                   | FORCE_TOK net_assignment     
                                   | RELEASE_TOK net_lvalue        
                                   ;




function_statement_or_null : function_statement
                          |  attribute_instance  SEM_TOK
						    ;

							
operator_assignment :net_lvalue assignment_operator expression
				  

assignment_operator : EQU_TOK
                    | PLUS_TOK EQU_TOK
					| MINUS_TOK EQU_TOK
					 | MULT_TOK EQU_TOK 
					 | ENV_TOK EQU_TOK
					 | PERCENTAL_TOK EQU_TOK
					 | AND_TOK EQU_TOK
					 | OR_TOK EQU_TOK 
					 | NOT_TOK EQU_TOK
					 | GGT_TOK EQU_TOK
					 | LLT_TOK EQU_TOK
					 | GGGT_TOK EQU_TOK
					 | LLLT_TOK EQU_TOK
					 ;

//------------------------------------------------------------------------------------------------------
//----------------------------A.6.3 Parallel and sequential blocks--------------------------------------------
//-----------------------------------------------------------------------------------------------------


						
variable_assignment : net_lvalue EQU_TOK expression  
				    ;  
					


action_block : statement_or_null
             | statement ELSE_TOK statement_or_null
             | ELSE_TOK statement_or_null
              ;
			  
par_block : FORK_TOK  statement_list join_keyword
          | FORK_TOK block_item_declaration_list join_keyword
		  | FORK_TOK block_item_declaration_list statement_list join_keyword 
          
		  | FORK_TOK COLON_TOK identifier block_item_declaration_list statement_list join_keyword
		  | FORK_TOK COLON_TOK identifier statement_list  join_keyword
          | FORK_TOK COLON_TOK identifier block_item_declaration_list join_keyword
		 		 
		  | FORK_TOK join_keyword
		  | FORK_TOK error join_keyword
		   ;
		   

seq_block : BEGIN_TOK    statement_list  end_word
          | BEGIN_TOK   block_item_declaration_list statement_list  end_word
    	   | BEGIN_TOK   block_item_declaration_list end_word
		   | BEGIN_TOK  always_label end_word
		  | BEGIN_TOK  always_label block_item_declaration_list statement_list  end_word
		   | BEGIN_TOK  always_label statement_list  end_word
          | BEGIN_TOK  always_label  block_item_declaration_list  end_word
				
		   | BEGIN_TOK  end_word
           | BEGIN_TOK error end_word
		  ;

 always_label:     COLON_TOK identifier  {
                                            if(! VerilogDocGen::parseCode)
											{
                                             if( VerilogDocGen::currentFunctionVerilog &&  VerilogDocGen::currentFunctionVerilog->spec==VerilogDocGen::ALWAYS)
										     {
                                              VerilogDocGen::adjustMemberName(VerilogDocGen::prevName); 
                                              QCString nk=$<cstr>2;
										      VerilogDocGen::currentFunctionVerilog->name=nk;
                                            }
											 else {
												 if(VerilogDocGen::currState==VerilogDocGen::ALWAYS)
													 VerilogDocGen::labelName=$<cstr>2;
												  }
										  }
                                         }

end_word : END_TOK
         | END_TOK COLON_TOK identifier		  
		  
statement_list:statement
              | statement_list statement
			  ;

			  
join_keyword : JOIN_TOK 
             | JOINANY_TOK 
			 | JOINNONE_TOK
			 | join_keyword COLON_TOK identifier
			 ;
//------------------------------------------------------------------------------------------------------
//----------------------------A.6.4 Statements --------------------------------------------
//-----------------------------------------------------------------------------------------------------


statement : attribute_instance  blocking_assignment SEM_TOK
          | attribute_instance  case_statement
          |  attribute_instance  conditional_statement
          |  attribute_instance  disable_statement
          |  attribute_instance  event_trigger
          |  attribute_instance  loop_statement
          |  attribute_instance  nonblocking_assignment SEM_TOK 
          |  attribute_instance  par_block
          |  procedural_assertion_statement
		  |  attribute_instance inc_or_dec_expression SEM_TOK
          |  attribute_instance  procedural_continuous_assignments SEM_TOK {vbufreset();}
          |  attribute_instance  seq_block {vbufreset();} 
          |  attribute_instance  system_task_enable
          |  attribute_instance  wait_statement 
		  |  attribute_instance  jump_statement 	
 	  	  |  attribute_instance randsequence_statement
		  |  attribute_instance randcase_statement
  		  |  attribute_instance subroutine_call_statement
		  |  attribute_instance  clocking_drive SEM_TOK
		  |  attribute_instance procedural_timing_control_statement
		  |  expect_property_statement
		   ;

statement_or_null  : statement
                  |   SEM_TOK
  			      ;

final_construct : FINAL_TOK function_statement				  

function_statement : statement


//------------------------------------------------------------------------------------------------------
//----------------------------A.6.5 Timing control statements--------------------------------------------
//-----------------------------------------------------------------------------------------------------

procedural_timing_control_statement : procedural_timing_control statement_or_null 

delay_or_event_control : delay3
                       | event_control 
                       | REPEAT_TOK LBRACE_TOK expression  RBRACE_TOK  event_control {VerilogDocGen::currVerilogType=0;}
                       ;

disable_statement : DISABLE_TOK ps_or_hier_identifier SEM_TOK
                   | DISABLE_TOK FORK_TOK SEM_TOK
     			  ;

event_control : AT_TOK MULT_TOK                                         { VerilogDocGen::parseAlways(); VerilogDocGen::prevName=getVerilogString();vbufreset();VerilogDocGen::currVerilogType=0; VerilogDocGen::currState=0;}                     
	          | AT_TOK LBRACE_TOK event_expression_list RBRACE_TOK 		{ VerilogDocGen::parseAlways(); VerilogDocGen::prevName=getVerilogString();vbufreset();VerilogDocGen::currVerilogType=0; VerilogDocGen::currState=0;}  
              | AT_TOK LBRACE_TOK error RBRACE_TOK 		{ VerilogDocGen::parseAlways(); VerilogDocGen::prevName=getVerilogString();vbufreset();VerilogDocGen::currVerilogType=0; VerilogDocGen::currState=0;}  
          	  | AT_TOK  ps_or_hier_identifier                           { VerilogDocGen::parseAlways(); VerilogDocGen::prevName=getVerilogString();vbufreset();VerilogDocGen::currVerilogType=0; VerilogDocGen::currState=0;}         
              | AT_TOK LBRACE_TOK MULT_TOK RBRACE_TOK                   { VerilogDocGen::parseAlways(); VerilogDocGen::prevName=getVerilogString();vbufreset();VerilogDocGen::currVerilogType=0; VerilogDocGen::currState=0;} 
              | AT_TOK ATL_TOK  RBRACE_TOK                              { VerilogDocGen::parseAlways(); VerilogDocGen::prevName=getVerilogString();vbufreset();VerilogDocGen::currVerilogType=0; VerilogDocGen::currState=0;} 
			  | AT_TOK sequence_instance
			  ;

			
				  
event_trigger : MINUSLT_TOK ps_or_hier_identifier SEM_TOK
              | MINUS_TOK LLT_TOK ps_or_hier_identifier SEM_TOK
			  | MINUS_TOK LLT_TOK delay3 ps_or_hier_identifier SEM_TOK
              | MINUS_TOK LLT_TOK error SEM_TOK
			  ;

procedural_timing_control : event_control
                          | delay3
                          ;

jump_statement : RETURN_TOK expression SEM_TOK
               | RETURN_TOK SEM_TOK
               | BREAK_TOK SEM_TOK
			   | CONTINUE_TOK SEM_TOK
                ;			   
	
event_expression : expression
                 | edge_identifier expression
                 |  edge_identifier expression  IFF_TOK expression
				 | expression  IFF_TOK expression
			   //  | event_expression COMMA_TOK event_expression
				// | event_expression SOR_TOK event_expression
				 | sequence_instance IFF_TOK expression
				
				;

event_expression_list : event_expression 
                      | event_expression_list COMMA_TOK event_expression 
					  | event_expression_list gate_ident event_expression 
                       ; 

wait_statement : WAIT_TOK LBRACE_TOK expression RBRACE_TOK statement_or_null
               | WAIT_TOK FORK_TOK SEM_TOK
			   | WAITORDER_TOK LBRACE_TOK list_of_variable_identifiers RBRACE_TOK action_block

//------------------------------------------------------------------------------------------------------
//----------------------------A.6.6 Conditional statements--------------------------------------------
//-----------------------------------------------------------------------------------------------------




conditional_statement : IF_TOK LBRACE_TOK cond_predicate RBRACE_TOK statement_or_null
	                   | IF_TOK LBRACE_TOK error RBRACE_TOK statement_or_null
                       | IF_TOK LBRACE_TOK cond_predicate RBRACE_TOK statement_or_null ELSE_TOK statement_or_null
	                   | IF_TOK LBRACE_TOK cond_predicate RBRACE_TOK error ELSE_TOK statement_or_null
	                   | unique_priority_if_statement
					   | unique_priority unique_priority_if_statement
	                   ;

					   
unique_priority_if_statement : IF_TOK LBRACE_TOK cond_predicate RBRACE_TOK statement_or_null elif_list	
                             | IF_TOK LBRACE_TOK cond_predicate RBRACE_TOK statement_or_null elif_list ELSE_TOK statement_or_null				   
					       
                             ;
							 
elif_list : ELSE_TOK IF_TOK LBRACE_TOK cond_predicate RBRACE_TOK statement_or_null
           | elif_list ELSE_TOK IF_TOK LBRACE_TOK cond_predicate RBRACE_TOK statement_or_null
		   ;
					   
 unique_priority : UNIQUE_TOK 
                 | PRIORITY_TOK
				 ;

				 
				 
				 
cond_predicate : expression_or_cond_pattern and_expression_or_cond_list 
               |  expression_or_cond_pattern
			   ;

and_expression_or_cond_list:AAND_TOK expression_or_cond_pattern
                           | and_expression_or_cond_list AAND_TOK expression_or_cond_pattern
                           ;

expression_or_cond_pattern : expression 
                           | cond_pattern
						   ;
						   
cond_pattern : expression MATCHES_TOK pattern
             ;
//-----------------------------------------------------------------------------------------------------
//----------------------------     A.6.7 Case statements   --------------------------------------------
//-----------------------------------------------------------------------------------------------------


case_statement:	unique_priority case_keyword LBRACE_TOK expression RBRACE_TOK case_item_list ENDCASE_TOK
              | case_keyword LBRACE_TOK expression RBRACE_TOK case_item_list ENDCASE_TOK
              | case_keyword LBRACE_TOK expression RBRACE_TOK error ENDCASE_TOK
						
			  | case_keyword error ENDCASE_TOK 
			  | case_keyword LBRACE_TOK expression RBRACE_TOK MATCHES_TOK case_pattern_item_list ENDCASE_TOK
			  | unique_priority  case_keyword LBRACE_TOK expression RBRACE_TOK MATCHES_TOK case_pattern_item_list ENDCASE_TOK
  			 ;


case_keyword : CASE_TOK 
             | CASEZ_TOK 
			 | CASEX_TOK			   

case_item_list: case_item
              | case_item_list case_item
              ;


case_item :expression_list  COLON_TOK statement_or_null
	      | DEFAULT_TOK COLON_TOK  statement_or_null
	      | DEFAULT_TOK statement_or_null
          ;

case_pattern_item_list : case_pattern_item
                       | case_pattern_item_list case_pattern_item
		  
case_pattern_item :pattern COLON_TOK statement_or_null
                 | pattern AAND_TOK expression COLON_TOK statement_or_null
				 | DEFAULT_TOK COLON_TOK statement_or_null
                 | DEFAULT_TOK  statement_or_null
				 

randcase_statement : RANDCASE_TOK randcase_item_list ENDCASE_TOK
                   | RANDCASE_TOK error ENDCASE_TOK
		           ;
		           
randcase_item_list : randcase_item
                   | randcase_item_list  randcase_item
                   ;
				   
randcase_item : expression COLON_TOK statement_or_null
               ;
			   
//------------------------------------------------------------------------------------------------------
//----------------------------A.6.7.1 Pattern  --------------------------------------------
//-----------------------------------------------------------------------------------------------------

pattern : identifier
        | DOTMULT_TOK
        | DOT_TOK expression
        | TAGGED_TOK identifier  pattern 
		| TAGGED_TOK identifier
		| LRAM_TOK pattern_list RRAM_TOK
        | LRAM_TOK mem_pattern_list RRAM_TOK
        | LRAM_TOK error RRAM_TOK
        ;
		
pattern_list: pattern
            | pattern_list COMMA_TOK pattern
            ;
			
mem_pattern_list : mpd
                 | mem_pattern_list COMMA_TOK mpd
                 ;
				 
mpd        : identifier COLON_TOK pattern
			
//------------------------------------------------------------------------------------------------------
//----------------------------A.6.8 Looping statements--------------------------------------------
//-----------------------------------------------------------------------------------------------------



loop_statement : FOREVER_TOK statement_or_null
               | REPEAT_TOK LBRACE_TOK expression RBRACE_TOK statement_or_null
               | WHILE_TOK LBRACE_TOK expression RBRACE_TOK statement_or_null
                | FOR_TOK LBRACE_TOK for_initialization SEM_TOK expression SEM_TOK for_step_list RBRACE_TOK statement // must add          
               | DO_TOK statement_or_null WHILE_TOK LBRACE_TOK expression RBRACE_TOK SEM_TOK
			   | FOREACH_TOK LBRACE_TOK dot_identifier LBRACKET_TOK list_of_variable_identifiers RBRACKET_TOK RBRACE_TOK statement
			//    | FOREACH_TOK LBRACE_TOK identifier LBRACKET_TOK list_of_variable_identifiers RBRACKET_TOK RBRACE_TOK statement
			
			   ;

for_initialization :  data_type_or_implicit variable_assignment
                   | for_initialization COMMA_TOK  data_type_or_implicit variable_assignment

for_step_list : for_step_assignment 
              | for_step_list COMMA_TOK for_step_assignment 

for_step_assignment : operator_assignment
                    | inc_or_dec_expression
					;
	
inc_or_dec_expression : inc_or_dec_operator  net_lvalue
                      | net_lvalue  inc_or_dec_operator // two shift reduce	
					  ;
					  
//------------------------------------------------------------------------------------------------------
//----------------------------A.6.9 Task enable statements--------------------------------------------
//-----------------------------------------------------------------------------------------------------

system_task_enable : ps_or_hier_identifier  LBRACE_TOK expression_list RBRACE_TOK SEM_TOK
                   | ps_or_hier_identifier  LBRACE_TOK error  RBRACE_TOK SEM_TOK
				   | ps_or_hier_identifier  LBRACE_TOK data_type_spec  RBRACE_TOK SEM_TOK
				   | ps_or_hier_identifier SEM_TOK
				   ;




subroutine_call_statement :  VOID_TOK APOS_TOK LBRACE_TOK function_call RBRACE_TOK SEM_TOK   
                          | function_call SEM_TOK
                          ;
						  
//-----------------------------------------------------------------------------------------------------
//----------------------------------- 6.10 Assertion statements----------------------------------------
//-----------------------------------------------------------------------------------------------------

procedural_assertion_statement : concurrent_assertion_statement
                              | immediate_assert_statement
                               ;
 immediate_assert_statement : ASSERT_TOK LBRACE_TOK expression RBRACE_TOK  action_block	    {vbufreset();}						 
								  | ASSERT_TOK LBRACE_TOK error RBRACE_TOK  action_block	{vbufreset();}
 //-----------------------------------------------------------------------------------------------------
//---------------------------- A.6.11 Clocking block       --------------------------------------------
//-----------------------------------------------------------------------------------------------------

clocking_declaration : clock_case_one clocking_event SEM_TOK {} clocking_item_list end_clock 
					   | clock_case_one clocking_event SEM_TOK {}  end_clock	  


end_clock      : ENDCLOCKING_TOK
               | ENDCLOCKING_TOK COLON_TOK identifier
			   ;
			   
clock_case_one : DEFAULT_TOK CLOCKING_TOK identifier
               | DEFAULT_TOK CLOCKING_TOK
			   | CLOCKING_TOK identifier
			   ;

clocking_event : event_control

clocking_item_list : clocking_item
                   | clocking_item_list clocking_item

clocking_item : DEFAULT_TOK clocking_direction SEM_TOK
              | clocking_direction list_of_variable_identifiers SEM_TOK
              | clocking_direction SEM_TOK
              | error SEM_TOK
              | attribute_instance concurrent_assertion_item_declaration
			  ;

clocking_direction : clocking_direction_in
                   | clocking_direction_out
                   | clocking_direction_in clocking_direction_out 
				   | INOUT_TOK
				   ;

clocking_direction_in : INPUT_TOK clocking_skew 
                      | INPUT_TOK
					  ;
					  
clocking_direction_out : OUTPUT_TOK clocking_skew 
                      |  OUTPUT_TOK
					  ;
					  
// list_of_clocking_decl_assign: list_of_net_decl_assignments

clocking_skew : edge_identifier 
              | edge_identifier delay3
              | delay3
              ;
              
clocking_drive :  cycle_delay GT_TOK EQU_TOK expression
                | cycle_delay GT_TOK EQU_TOK DOUBLEPARA_TOK expression   
                | cycle_delay clockvar_expression GT_TOK EQU_TOK  expression	
               // | cycle_delay clockvar_expression GT_TOK EQU_TOK expression	
			| cycle_delay	
               ;
			   
cycle_delay : DOUBLEPARA_TOK identifier
            | DOUBLEPARA_TOK DIGIT_TOK
            | DOUBLEPARA_TOK LBRACE_TOK expression RBRACE_TOK
            ;
      
clockvar_expression : ps_or_hier_identifier 
                      ;
//------------------------------------------------------------------------------------------------------
//---------------------------- A.6.12 Randsequence         --------------------------------------------
//-----------------------------------------------------------------------------------------------------


randsequence_statement: RANDSEQUENCE_TOK LBRACE_TOK RBRACE_TOK  production_list ENDSEQUENCE_TOK
                      | RANDSEQUENCE_TOK LBRACE_TOK RBRACE_TOK  error ENDSEQUENCE_TOK
                      ;
                      
 production_list : production
                 |  production_list production
                 ;				 

				 
production       : identifier RBRACE_TOK tf_port_list RBRACE_TOK COLON_TOK rs_rule_list SEM_TOK 
				 | identifier COLON_TOK rs_rule_list SEM_TOK 
				 ;
				 
rs_rule_list     : rs_rule
                 | rs_rule_list OR_TOK rs_rule
				 ;
				 
rs_rule          : rs_prod_list
                 | rs_prod_list COLON_TOK EQU_TOK expression				 
				 
rs_prod_list     : rs_prod
                 | rs_prod_list rs_prod
				 ;
				 
rs_prod          : production_item
                 | rs_if_else
				 | rs_code_block
				 | rs_repeat
				 | rs_case
				 ;
	
				 
rs_code_block : LRAM_TOK data_declaration  statement_or_null  RRAM_TOK		
              | LRAM_TOK data_declaration  RRAM_TOK		
              | LRAM_TOK   RRAM_TOK		
              | LRAM_TOK error RRAM_TOK
              ;
              
				 			 
production_item  : identifier 
                 | identifier LBRACE_TOK list_of_arguments RBRACE_TOK 
				 
rs_if_else       : IF_TOK LBRACE_TOK expression RBRACE_TOK production_item
                 | IF_TOK LBRACE_TOK expression RBRACE_TOK production_item ELSE_TOK production_item
				 | IF_TOK LBRACE_TOK expression RBRACE_TOK error ELSE_TOK production_item
				 
rs_repeat        : REPEAT_TOK LBRACE_TOK expression RBRACE_TOK production_item
				 
rs_case           : CASE_TOK LBRACE_TOK expression RBRACE_TOK rs_case_item_list ENDCASE_TOK				 
				 ;
rs_case_item_list : rs_case_item
                  | rs_case_item_list rs_case_item
				  ;
				 
rs_case_item : expression_list COLON_TOK production_item
             | DEFAULT_TOK production_item
			 | DEFAULT_TOK COLON_TOK production_item
			 ;
//------------------------------------------------------------------------------------------------------
//----------------------------A.7.1 Specify block declaration -------------------------------------------
//-----------------------------------------------------------------------------------------------------

specify_block:SPECIFY_TOK  ENDSPECIFY_TOK
             | SPECIFY_TOK  specify_item_list ENDSPECIFY_TOK { vbufreset(); }
			 | SPECIFY_TOK error ENDSPECIFY_TOK  { vbufreset(); }
			  ;


specify_item_list:specify_item { vbufreset(); }
              | specify_item_list specify_item { vbufreset(); }
              ;


specify_item: specparam_declaration {vbufreset();}
	        | path_declaration {vbufreset();}
	        | system_timing_check {vbufreset();}
	        | pulsestyle_declaration {vbufreset();}
            | showcancelled_declaration {vbufreset();}
            ;
			

pulsestyle_declaration : PULSEON_DETECT_TOK list_of_path_outputs SEM_TOK
                       | PULSEONE_EVENT_TOK list_of_path_outputs SEM_TOK
                       | PULSEONE_EVENT_TOK error SEM_TOK
					   ;


showcancelled_declaration : SHOWCANCEL_TOK list_of_path_outputs SEM_TOK
                          | NOSHOWCANCEL_TOK  list_of_path_outputs SEM_TOK
                          | NOSHOWCANCEL_TOK error SEM_TOK
						  ;

 //------------------------------------------------------------------------------------------------------
//----------------------------A.7.1 Specify Task declaration -------------------------------------------
//-----------------------------------------------------------------------------------------------------

path_declaration : simple_path_declaration SEM_TOK
                 | edge_sensitive_path_declaration SEM_TOK
                 | state_dependent_path_declaration SEM_TOK
                 ;


simple_path_declaration : parallel_path_description EQU_TOK path_delay_value
                       // | full_path_description EQU_TOK path_delay_value
                         ;


parallel_path_description : LBRACE_TOK specify_input_terminal_descriptor  EQULT_TOK specify_input_terminal_descriptor RBRACE_TOK
						  | LBRACE_TOK list_of_path_inputs  connection list_of_path_outputs RBRACE_TOK
                          | LBRACE_TOK list_of_path_inputs    MULT_TOK LT_TOK list_of_path_outputs RBRACE_TOK
					      | LBRACE_TOK error RBRACE_TOK
	                    ;

list_of_path_inputs : specify_input_terminal_descriptor
                    | list_of_path_inputs COMMA_TOK specify_input_terminal_descriptor 
                    ;

list_of_path_outputs : list_of_path_inputs 
                     ;
          
connection:polarity_operator EQULT_TOK
   | polarity_operator  MULT_TOK LT_TOK 
   ;

//specify_output_terminal_descriptor
//                    | list_of_path_output COMMA_TOK specify_output_terminal_descriptor 
//                    ;
//------------------------------------------------------------------------------------------------------
//----------------------------A.7.3 Specify block terminals -------------------------------------------
//-----------------------------------------------------------------------------------------------------

specify_input_terminal_descriptor : identifier
                                  | identifier LBRACKET_TOK range_expression RBRACKET_TOK 
								  | identifier LBRACKET_TOK expression RBRACKET_TOK 
								  ;


path_delay_value : list_of_path_delay_expressions
                  | LBRACE_TOK list_of_path_delay_expressions RBRACE_TOK
                 ;


list_of_path_delay_expressions:path_delay_expression
	            | LBRACE_TOK path_delay_expression COMMA_TOK path_delay_expression RBRACE_TOK
	            | LBRACE_TOK path_delay_expression COMMA_TOK path_delay_expression COMMA_TOK path_delay_expression RBRACE_TOK
	            | LBRACE_TOK path_delay_expression COMMA_TOK path_delay_expression COMMA_TOK path_delay_expression COMMA_TOK path_delay_expression COMMA_TOK path_delay_expression COMMA_TOK path_delay_expression RBRACE_TOK
	            | LBRACE_TOK path_delay_expression COMMA_TOK path_delay_expression COMMA_TOK path_delay_expression COMMA_TOK path_delay_expression COMMA_TOK path_delay_expression COMMA_TOK path_delay_expression COMMA_TOK path_delay_expression COMMA_TOK path_delay_expression COMMA_TOK path_delay_expression COMMA_TOK path_delay_expression COMMA_TOK path_delay_expression COMMA_TOK path_delay_expression RBRACE_TOK
	            ;

//------------------------------------------------------------------------------------------------------
//----------------------------A.7.4 Specify path delays -------------------------------------------
//-----------------------------------------------------------------------------------------------------


path_delay_expression:mintypemax_expression


edge_sensitive_path_declaration : parallel_edge_sensitive_path_description EQU_TOK path_delay_value
                                | full_edge_sensitive_path_description EQU_TOK path_delay_value
                                ;


parallel_edge_sensitive_path_description : LBRACE_TOK  edge_identifier  specify_input_terminal_descriptor EQULT_TOK example
                                          |  LBRACE_TOK  specify_input_terminal_descriptor EQULT_TOK example                                           
										   ;


full_edge_sensitive_path_description : LBRACE_TOK edge_identifier  list_of_path_inputs MULT_TOK LT_TOK
                                        list_of_path_outputs  pol_op  COLON_TOK data_source_expression RBRACE_TOK
                                     | LBRACE_TOK   list_of_path_inputs MULT_TOK LT_TOK
                                        list_of_path_outputs  pol_op  COLON_TOK data_source_expression RBRACE_TOK
                                      ;



example:   specify_input_terminal_descriptor  pol_op  COLON_TOK data_source_expression RBRACE_TOK
       |  LBRACE_TOK specify_input_terminal_descriptor  pol_op  COLON_TOK data_source_expression RBRACE_TOK RBRACE_TOK // rule for altera
	   ;                               


data_source_expression :  expression
                        ;
edge_identifier :   POSEDGE_TOK
	            | NEGEDGE_TOK
                ;


state_dependent_path_declaration : IF_TOK LBRACE_TOK expression RBRACE_TOK simple_path_declaration
                                 | IF_TOK LBRACE_TOK  expression RBRACE_TOK edge_sensitive_path_declaration
                                 | IFNONE_TOK simple_path_declaration
                                 ;


polarity_operator :  pol_op
                   ;


//------------------------------------------------------------------------------------------------------
//----------------------------A.7.5.1 System timing check commands -------------------------------------------
//-----------------------------------------------------------------------------------------------------


system_timing_check :setup_timing_check
                    | hold_timing_check
                    | setuphold_timing_check
                    | recovery_timing_check
                    | removal_timing_check
                    | skew_timing_check
                    | period_timing_check 
                    | width_timing_check
                    | nochange_timing_check		 
					| recrem_timing_check
                    | fullskew_timing_check 
					| timingskew_timing_check 				    
					;


fullskew_timing_check : FULLSKEW_TOK LBRACE_TOK data_event COMMA_TOK reference_event COMMA_TOK timing_check_limit COMMA_TOK notify_register_list  RBRACE_TOK SEM_TOK
                     | FULLSKEW_TOK LBRACE_TOK data_event COMMA_TOK reference_event COMMA_TOK timing_check_limit RBRACE_TOK SEM_TOK
                     ;

timingskew_timing_check : TIMESKEW_TOK LBRACE_TOK data_event COMMA_TOK reference_event COMMA_TOK timing_check_limit COMMA_TOK notify_register_list  RBRACE_TOK SEM_TOK
                     | TIMESKEW_TOK LBRACE_TOK data_event COMMA_TOK reference_event COMMA_TOK timing_check_limit RBRACE_TOK SEM_TOK
                     ;


recrem_timing_check  : RECREM_TOK  LBRACE_TOK timing_check_event  COMMA_TOK  timing_check_event  COMMA_TOK  timing_check_limit  COMMA_TOK  timing_check_limit  COMMA_TOK notify_register_list RBRACE_TOK SEM_TOK
                        | RECREM_TOK  LBRACE_TOK timing_check_event  COMMA_TOK  timing_check_event  COMMA_TOK  timing_check_limit  COMMA_TOK  timing_check_limit  RBRACE_TOK SEM_TOK
                        ; 
 

setup_timing_check : DSETUP_TOK LBRACE_TOK data_event COMMA_TOK reference_event COMMA_TOK timing_check_limit COMMA_TOK notify_register_list  RBRACE_TOK SEM_TOK
                   | DSETUP_TOK LBRACE_TOK data_event COMMA_TOK reference_event COMMA_TOK timing_check_limit RBRACE_TOK SEM_TOK
                   | DSETUP_TOK LBRACE_TOK error RBRACE_TOK
				   ;

hold_timing_check : DHOLD_TOK LBRACE_TOK data_event COMMA_TOK reference_event COMMA_TOK timing_check_limit COMMA_TOK notify_register_list RBRACE_TOK SEM_TOK
                   | DHOLD_TOK LBRACE_TOK data_event COMMA_TOK reference_event COMMA_TOK timing_check_limit RBRACE_TOK SEM_TOK
                   | DHOLD_TOK error SEM_TOK
				   ;


setuphold_timing_check  : DSETUPHOLD_TOK  LBRACE_TOK timing_check_event  COMMA_TOK  timing_check_event  COMMA_TOK  timing_check_limit  COMMA_TOK  timing_check_limit  COMMA_TOK notify_register_list RBRACE_TOK SEM_TOK
                        | DSETUPHOLD_TOK  LBRACE_TOK timing_check_event  COMMA_TOK  timing_check_event  COMMA_TOK  timing_check_limit  COMMA_TOK  timing_check_limit  RBRACE_TOK SEM_TOK
                        ; 

recovery_timing_check:DRECOVERY_TOK LBRACE_TOK data_event COMMA_TOK reference_event COMMA_TOK timing_check_limit COMMA_TOK notify_register_list  RBRACE_TOK SEM_TOK
                     | DRECOVERY_TOK LBRACE_TOK data_event COMMA_TOK reference_event COMMA_TOK timing_check_limit RBRACE_TOK SEM_TOK
                     ;
removal_timing_check: REMOVAL_TOK LBRACE_TOK data_event COMMA_TOK reference_event COMMA_TOK timing_check_limit COMMA_TOK notify_register_list  RBRACE_TOK SEM_TOK
                     | REMOVAL_TOK LBRACE_TOK data_event COMMA_TOK reference_event COMMA_TOK timing_check_limit RBRACE_TOK SEM_TOK
                     ;


skew_timing_check : DSKEW_TOK LBRACE_TOK data_event COMMA_TOK reference_event COMMA_TOK timing_check_limit COMMA_TOK notify_register_list  RBRACE_TOK SEM_TOK
                     | DSKEW_TOK LBRACE_TOK data_event COMMA_TOK reference_event COMMA_TOK timing_check_limit RBRACE_TOK SEM_TOK
                     ;

 nochange_timing_check	:  NOCHANGE_TOK  LBRACE_TOK timing_check_event COMMA_TOK timing_check_event COMMA_TOK mintypemax_expression COMMA_TOK mintypemax_expression RBRACE_TOK SEM_TOK
	                    | NOCHANGE_TOK   LBRACE_TOK timing_check_event COMMA_TOK timing_check_event COMMA_TOK mintypemax_expression COMMA_TOK mintypemax_expression COMMA_TOK notify_register_list RBRACE_TOK SEM_TOK
	                    ;

width_timing_check :  DWIDTH_TOK  LBRACE_TOK controlled_timing_check_event COMMA_TOK timing_check_limit COMMA_TOK expression COMMA_TOK notify_register_list RBRACE_TOK SEM_TOK
                     |  DWIDTH_TOK  LBRACE_TOK controlled_timing_check_event COMMA_TOK timing_check_limit RBRACE_TOK SEM_TOK

					 ;

period_timing_check :DPERIOD_TOK   LBRACE_TOK controlled_timing_check_event COMMA_TOK timing_check_limit RBRACE_TOK SEM_TOK
                     | DPERIOD_TOK  LBRACE_TOK controlled_timing_check_event COMMA_TOK timing_check_limit COMMA_TOK notify_register_list RBRACE_TOK SEM_TOK
                     ;

notify_register_list:notify_register
                    | notify_register_list COMMA_TOK notify_register
					;

 notify_register:expression

                   

//------------------------------------------------------------------------------------------------------
//----------------------------A.7.5.2 System timing check command arguments  -------------------------------------------
//-----------------------------------------------------------------------------------------------------

timing_check_limit :  expression
                   ;
data_event : timing_check_event
           ;

reference_event : timing_check_event
           ;

timing_check_event :timing_check_event_control specify_terminal_descriptor AAAND_TOK timing_check_condition
                    | timing_check_event_control specify_terminal_descriptor 
                    | specify_terminal_descriptor AAAND_TOK timing_check_condition
                    | specify_terminal_descriptor 
					 ;

controlled_timing_check_event:timing_check_event
                            
                             ;

timing_check_event_control :POSEDGE_TOK
	                       | NEGEDGE_TOK
                           | edge_control_specifier
                           ;

edge_control_specifier :EDGE_TOK  LBRACKET_TOK edge_descriptor_list RBRACKET_TOK
                       | error RBRACKET_TOK
					   ;

edge_descriptor : DIGIT_TOK DIGIT_TOK 
	             | DIGIT_TOK LETTER_TOK
				 | LETTER_TOK DIGIT_TOK
                 ;

edge_descriptor_list :  edge_descriptor
	             | edge_descriptor_list COMMA_TOK edge_descriptor
				 ;

specify_terminal_descriptor : specify_input_terminal_descriptor 
                            ;


timing_check_condition : mintypemax_expression //scalar_timing_check_condition
	                     ;

//------------------------------------------------------------------------------------------------------
//--- -------------------------A.8.1 Concatenations  -------------------------------------------
//-----------------------------------------------------------------------------------------------------


concatenation : LRAM_TOK expression_list RRAM_TOK
               | LRAM_TOK member_label_list RRAM_TOK
		       ;
		                            
multiple_concatenation :   LRAM_TOK expression concatenation RRAM_TOK 
                        ; 
member_label_list: member_label COLON_TOK member_label
                 | member_label_list COMMA_TOK member_label COLON_TOK member_label
                 ;
				 
						
member_label : DEFAULT_TOK
             |	expression
             ;			 
						
net_concatenation : LRAM_TOK net_concatenation_value_list RRAM_TOK
                  | LRAM_TOK error RRAM_TOK
                  ;
                  
net_concatenation_value_list: net_lvalue
                            | net_concatenation_value_list COMMA_TOK net_lvalue
							 ;
							 
      //------------------------------------------------------------------------------------------------------


list_of_arguments : list_of_arguments_new
             | expression_list COMMA_TOK list_of_arguments_new
             | expression_list
			 | COMMA_TOK expression_list
             ;

list_of_arguments_new : argument
             | list_of_arguments_new COMMA_TOK argument     
			  | list_of_arguments_new COMMA_TOK 
             ;
argument : DOT_TOK identifier LBRACE_TOK RBRACE_TOK
             | DOT_TOK identifier LBRACE_TOK expression RBRACE_TOK
             | data_type_spec    
			 ;
//------------------------------------------------------------------------------------------------------
//----------------------------A.8.3 Expressions  -------------------------------------------
//-----------------------------------------------------------------------------------------------------

expression_bracket_list: LBRACKET_TOK expression RBRACKET_TOK
                       | LBRACKET_TOK error RBRACKET_TOK
                       | expression_bracket_list LBRACKET_TOK expression RBRACKET_TOK
  					   
					   ; 




range_expression :  expression COLON_TOK lsb_constant_expression
                 | expression PLUS_TOK COLON_TOK width_constant_expression
                 | expression MINUS_TOK COLON_TOK width_constant_expression
                 ;

expression_list: expression
               | expression_list COMMA_TOK expression 
			   | expression_list COMMA_TOK
			   ;


//------------------------------------------------------------------------------------------------------
//----------------------------A.8.4 Primaries  -------------------------------------------
//-----------------------------------------------------------------------------------------------------


primary : ps_or_hier_identifier ps_tok 
		| LBRACE_TOK mintypemax_expression RBRACE_TOK 
        | concatenation
        | multiple_concatenation
		| cast
		| number
		| NULL_TOK
		| THISDOT_TOK
	    | primary_literal
		| empty_queue
		| streaming_expression
		| inc_or_dec_operator net_lvalue
        | TAGGED_TOK primary       
  	 	;

		
ps_tok :     
       | cast
	   | inc_or_dec_operator
       |  expression_bracket_list
       | LBRACKET_TOK range_expression RBRACKET_TOK 
       |  expression_bracket_list LBRACKET_TOK range_expression RBRACKET_TOK   
       | function_call_v	
	   | function_call_v WITH_TOK LBRACE_TOK expression RBRACE_TOK
       | function_call_v WITH_TOK constraint_block	
	   ;
//----------------------------A.8.2 Concatenations  -------------------------------------------
//-----------------------------------------------------------------------------------------------------



function_call:   ps_or_hier_identifier function_call_v
                | ps_or_hier_identifier function_call_v WITH_TOK LBRACE_TOK expression RBRACE_TOK
             	| ps_or_hier_identifier WITH_TOK LBRACE_TOK expression RBRACE_TOK
                | ps_or_hier_identifier WITH_TOK constraint_block
				;
              
                                 
 // method_call_body :  ident_func function_call_v
  //            | ident_func
   //           |  ident_func  WITH_TOK LBRACE_TOK expression RBRACE_TOK
   //           |  ident_func function_call_v WITH_TOK LBRACE_TOK expression RBRACE_TOK
    //          ;
  
function_call_v  :  LBRACE_TOK  list_of_arguments  RBRACE_TOK 
			 | LBRACE_TOK   RBRACE_TOK
			 | attribute_instance11 LBRACE_TOK  list_of_arguments  RBRACE_TOK
			 ;

//ident_func:UNIQUE_TOK
//           | SOR_TOK
//           | ps_or_hier_identifier 
//            ;


		
streaming_expression: LRAM_TOK stream_operator LRAM_TOK stream_concatenation RRAM_TOK RRAM_TOK
                    | LRAM_TOK stream_operator identifier LRAM_TOK stream_concatenation RRAM_TOK RRAM_TOK
                    | LRAM_TOK stream_operator LRAM_TOK error RRAM_TOK RRAM_TOK
                    | LRAM_TOK stream_operator identifier LRAM_TOK error RRAM_TOK RRAM_TOK
                  
                      ;

stream_concatenation: stream_expression 
                    | stream_concatenation COMMA_TOK stream_expression
                    ;
stream_expression :expression 
                  | expression WITH_TOK LBRACKET_TOK value_range RBRACKET_TOK
                  ;
                  
                
                  
stream_operator : LLT_TOK 
                |  GGT_TOK 
                ;
                
 empty_queue : LRAM_TOK RRAM_TOK
 primary_literal : DIGIT_TOK simple_identifier  

 cast    : casting_type APOS_TOK LBRACE_TOK mintypemax_expression RBRACE_TOK 
         | casting_type APOS_TOK concatenation
		 | casting_type APOS_TOK LRAM_TOK RRAM_TOK
         ;

 unprim:   primary
		   | STRING_TOK
  		   | unary_operator primary
           | unary_operator attribute_instance11 primary	  
		   ;

expression : unprim
           | expression binary_operator  unprim
	       | expression  binary_operator attribute_instance11  unprim
		   | expression QUESTION_TOK expression COLON_TOK unprim 
		   | expression INSIDE_TOK LRAM_TOK range_list RRAM_TOK
			;

value_range : expression
            | LBRACKET_TOK range_expression RBRACKET_TOK			
            ;
			

			   
mintypemax_expression : expression
                      | expression COLON_TOK expression COLON_TOK mintypemax_expression 
                       ;

lsb_constant_expression :expression
                        ;
msb_constant_expression :expression
                        ; 
width_constant_expression :expression

//------------------------------------------------------------------------------------------------------
//----------------------------A.8.6 Operators  -------------------------------------------
//-----------------------------------------------------------------------------------------------------

inc_or_dec_operator : PPLUS_TOK
                    | DMINUS_TOK
					;
                     
unary_operator :  EXCLAMATION_TOK 
			   |  AND_TOK
			   |   NOT_TOK
			   |  SN_TOK
			   |  SN_TOK AND_TOK
			   |  SNNOT_TOK
			   |  OR_TOK
			   |  SN_TOK OR_TOK
			   |  pol_op
			   |  NOTSN_TOK 
		        ;


binary_operator : PERCENTAL_TOK
				| pol_op // PLUS_TOK
				| EQU_TOK EQU_TOK 
			    | EEEQU_TOK               // ===
			    | EXCLAMATION_TOK EQU_TOK // !==
			    | EX_EQU_EQU_TOK 
				| AAND_TOK
				| OOR_TOK
		        | LT_TOK
				| GT_TOK 
				| GGT_TOK
				| GT_TOK EQU_TOK
				| LT_TOK EQU_TOK
				| LLT_TOK
				| MULT_TOK
				| ENV_TOK
				| NOT_TOK
				| AND_TOK
				| OR_TOK
				| SN_TOK
				| SNNOT_TOK
	            | NOTSN_TOK 
                | MULT_TOK MULT_TOK      // vlog 2001
				| GGGT_TOK // vlog2001
				| LLLT_TOK // vlog2001
				| EX_Q_EQU_TOK  // !?=
				| EQU_Q_EQU_TOK // =?=
                ;


//------------------------------------------------------------------------------------------------------
//----------------------------A.8.5 Expression left-side values  -------------------------------------------
//-----------------------------------------------------------------------------------------------------

net_lvalue : net_lvalue_v
        
net_lvalue_v : ps_or_hier_identifier LBRACKET_TOK range_expression RBRACKET_TOK
           | ps_or_hier_identifier expression_bracket_list 
           | ps_or_hier_identifier LBRACKET_TOK RBRACKET_TOK EQU_TOK dynamic_array_new 
		   | ps_or_hier_identifier expression_bracket_list LBRACKET_TOK range_expression RBRACKET_TOK
         //  |  ps_or_hier_identifier  EQU_TOK class_new
		   | net_concatenation
           | ps_or_hier_identifier
		   ;

hierachical_identifier :  ROOT_TOK DOT_TOK simple_identifier 
               	       |  simple_identifier            
					        ;



dot_identifier : identifier
               | dot_identifier DOT_TOK identifier
			   | implicit_class_handle identifier
			   | dot_identifier CCOLON_TOK identifier
            		   
simple_identifier : identifier
			| identifier dimension_list {  }
            | simple_identifier parameter_value_assignment
			| simple_identifier DOT_TOK identifier	
            | simple_identifier CCOLON_TOK identifier       
			| simple_identifier DOT_TOK identifier dimension	
            | simple_identifier CCOLON_TOK identifier dimension	
           ;
           
             
package_scope: UNIT_TOK  CCOLON_TOK hierachical_identifier
			  ;

ps_or_hier_identifier :  package_scope 
                      |  hierachical_identifier
                      |  implicit_class_handle  hierachical_identifier
                     ;
   					   
 
 implicit_class_handle:  THISDOT_TOK DOT_TOK
                       | SUPERDOT_TOK DOT_TOK
                      ;

 signed :  SIGNED_TOK
		;

pol_op:MINUS_TOK
      | PLUS_TOK
                 ;
				  

number : DIGIT_TOK { VerilogDocGen::identVerilog+=$<cstr>1;VerilogDocGen::writeDigit(); } 
	     | pol_op DIGIT_TOK  {if( VerilogDocGen::parseCode) {writePrevVerilogWords(VerilogDocGen::identVerilog);writeVerilogFont("vhdllogic",VerilogDocGen::identVerilog.data());VerilogDocGen::identVerilog.resize(0);}}
      ;



//------------------------------------------------------------------------------------------------------
//----------------------------A.9.1 Attributes  -------------------------------------------
//-----------------------------------------------------------------------------------------------------


     
attribute_instance11 : ATL_TOK attr_spec_list ATR_TOK  {vbufreset();}
	  |  ATL_TOK error ATR_TOK { vbufreset(); }
                   ;

attribute_instance : /* empty55 */                
				   |  ATL_TOK attr_spec_list ATR_TOK { vbufreset(); }
				   |  ATL_TOK  error ATR_TOK  { vbufreset(); }
                   ;

attr_spec_list: attr_spec
              | attr_spec_list COMMA_TOK attr_spec
			  ;				   

attr_spec : identifier EQU_TOK expression
		  | identifier
		  ;

 		  
identifier:ident { VerilogDocGen::parseString(); }
         			


ident : LETTER_TOK  {
			if(VerilogDocGen::parseCode)
			                  { 
                                				  VerilogDocGen::identVerilog+=$<cstr>1; 
			                  }
		            }
        | DOLLAR_TOK 
		;
			


%%
//------ ------------------------------------------------------------------------------------------------

 Entry* getCurrVerilogEntry(){return VerilogDocGen::current;}
 Entry* getCurrVerilog()
 {
	 return VerilogDocGen::currentVerilog; 
 }
 QCString getCurrVerilogParsingClass(){return VerilogDocGen::currVerilogClass; }

 void initVerilogParser(Entry* ee,bool pc){
  VerilogDocGen::currVerilogInst.resize(0);
  VerilogDocGen::currVerilogClass.resize(0);
  VerilogDocGen::prevDocEntryVerilog.reset();
  VerilogDocGen::currentVerilog=0;
  VerilogDocGen::generateItem=false;
  VerilogDocGen::currentFunctionVerilog=0;
  VerilogDocGen::sdataType.resize(0);
  VerilogDocGen::portType.resize(0);
  VerilogDocGen::enumType.resize(0);
  VerilogDocGen::parseCode=pc;
  VerilogDocGen::currState=0;
  VerilogDocGen::lastModule=0;
  VerilogDocGen::generateItem=false;
  VerilogDocGen::insideFunction=false;

if(pc) return;
  VerilogDocGen::current_rootVerilog=ee;
  VerilogDocGen::lastModule=0;
  VerilogDocGen::current=new Entry;
  VerilogDocGen::initEntry(VerilogDocGen::current);
  VerilogDocGen::current_rootVerilog->name=QCString("XXX"); // dummy name for root
}
  
 //-------------------------------------------------------------------------------------------  
           
 int MyParserConv::parse(MyParserConv* conv){
  myconv=conv;
  assert(myconv);
  return c_parse();
 } 
        
int c_lex(void){
 return myconv->doLex(); 
}


void c_error(const char * err)
{
   if(err && ! VerilogDocGen::parseCode)
   {
   // fprintf(stderr,"\n\nerror  at line [%d]... : in file [%s]\n\n",c_lloc.first_line,getVerilogParsingFile());
  //  printf("\n\nerror  at line [%d]... : in file [%s]\n\n",c_lloc.first_line,getVerilogParsingFile());
    vbufreset();
 //   if(yydebug) 
  //    exit(0);
    }
 } 
    
int getVerilogToken(){return c_char;}
 //------------------------------------------------------------------------------------------------  




 
  
