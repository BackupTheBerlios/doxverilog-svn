
/* A Bison parser, made by GNU Bison 2.4.1.  */

/* Skeleton interface for Bison GLR parsers in C
   
      Copyright (C) 2002, 2003, 2004, 2005, 2006 Free Software Foundation, Inc.
   
   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.
   
   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */


/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     NET_TOK = 258,
     STR0_TOK = 259,
     STR1_TOK = 260,
     GATE_TOK = 261,
     STRING_TOK = 262,
     SSTRING_TOK = 263,
     DIGIT_TOK = 264,
     SEM_TOK = 265,
     DOT_TOK = 266,
     LETTER_TOK = 267,
     PLUS_TOK = 268,
     MINUS_TOK = 269,
     COLON_TOK = 270,
     LBRACE_TOK = 271,
     RBRACE_TOK = 272,
     LBRACKET_TOK = 273,
     RBRACKET_TOK = 274,
     AND_TOK = 275,
     OR_TOK = 276,
     EQU_TOK = 277,
     GT_TOK = 278,
     LT_TOK = 279,
     NOT_TOK = 280,
     MULT_TOK = 281,
     PERCENTAL_TOK = 282,
     ENV_TOK = 283,
     PARA_TOK = 284,
     AT_TOK = 285,
     DOLLAR_TOK = 286,
     SN_TOK = 287,
     EXCLAMATION_TOK = 288,
     RRAM_TOK = 289,
     LRAM_TOK = 290,
     PARAMETER_TOK = 291,
     OUTPUT_TOK = 292,
     INOUT_TOK = 293,
     SMALL_TOK = 294,
     MEDIUM_TOK = 295,
     LARGE_TOK = 296,
     VEC_TOK = 297,
     SCALAR_TOK = 298,
     REG_TOK = 299,
     TIME_TOK = 300,
     REAL_TOK = 301,
     EVENT_TOK = 302,
     ASSIGN_TOK = 303,
     DEFPARAM_TOK = 304,
     MODUL_TOK = 305,
     ENDMODUL_TOK = 306,
     MACRO_MODUL_TOK = 307,
     ENDPRIMITIVE_TOK = 308,
     PRIMITIVE_TOK = 309,
     INITIAL_TOK = 310,
     TABLE_TOK = 311,
     ENDTABLE_TOK = 312,
     ALWAYS_TOK = 313,
     TASK_TOK = 314,
     ENDTASK_TOK = 315,
     FUNC_TOK = 316,
     ENDFUNC_TOK = 317,
     IF_TOK = 318,
     CASE_TOK = 319,
     CASEX_TOK = 320,
     CASEZ_TOK = 321,
     FOREVER_TOK = 322,
     REPEAT_TOK = 323,
     FOR_TOK = 324,
     JOIN_TOK = 325,
     WAIT_TOK = 326,
     FORCE_TOK = 327,
     RELEASE_TOK = 328,
     DEASSIGN_TOK = 329,
     DISABLE_TOK = 330,
     WHILE_TOK = 331,
     ELSE_TOK = 332,
     ENDCASE_TOK = 333,
     BEGIN_TOK = 334,
     DEFAULT_TOK = 335,
     FORK_TOK = 336,
     END_TOK = 337,
     SPECIFY_TOK = 338,
     ENDSPECIFY_TOK = 339,
     SPECPARAM_TOK = 340,
     DSETUP_TOK = 341,
     DHOLD_TOK = 342,
     DWIDTH_TOK = 343,
     DPERIOD_TOK = 344,
     DSKEW_TOK = 345,
     DRECOVERY_TOK = 346,
     DSETUPHOLD_TOK = 347,
     POSEDGE_TOK = 348,
     NEGEDGE_TOK = 349,
     EDGE_TOK = 350,
     COMMA_TOK = 351,
     QUESTION_TOK = 352,
     AUTO_TOK = 353,
     INPUT_TOK = 354,
     SIGNED_TOK = 355,
     LOCALPARAM_TOK = 356,
     INTEGER_TOK = 357,
     NOCHANGE_TOK = 358,
     GENERATE_TOK = 359,
     ENDGENERATE_TOK = 360,
     GENVAR_TOK = 361,
     LIBRARY_TOK = 362,
     CONFIG_TOK = 363,
     ENDCONFIG_TOK = 364,
     INCLUDE_TOK = 365,
     PULSEON_DETECT_TOK = 366,
     PULSEONE_EVENT_TOK = 367,
     USE_TOK = 368,
     LIBLIST_TOK = 369,
     INSTANCE_TOK = 370,
     CELL_TOK = 371,
     SHOWCANCEL_TOK = 372,
     NOSHOWCANCEL_TOK = 373,
     REMOVAL_TOK = 374,
     FULLSKEW_TOK = 375,
     TIMESKEW_TOK = 376,
     RECREM_TOK = 377,
     IFNONE_TOK = 378,
     REALTIME_TOK = 379,
     DESIGN_TOK = 380,
     OOR_TOK = 381,
     AAND_TOK = 382,
     SNNOT_TOK = 383,
     NOTSN_TOK = 384,
     AAAND_TOK = 385,
     DOTMULT_TOK = 386,
     ENDINTERFACE_TOK = 387,
     INTERFACE_TOK = 388,
     THISDOT_TOK = 389,
     SUPERDOT_TOK = 390,
     UNIT_TOK = 391,
     INT_TOK = 392,
     SHORTINT_TOK = 393,
     LONGINT_TOK = 394,
     BYTE_TOK = 395,
     BIT_TOK = 396,
     LOGIC_TOK = 397,
     ROOT_TOK = 398,
     NULL_TOK = 399,
     UNSIGNED_TOK = 400,
     SHORTREAL_TOK = 401,
     APOS_TOK = 402,
     WITH_TOK = 403,
     GGT_TOK = 404,
     LLT_TOK = 405,
     PPLUS_TOK = 406,
     DMINUS_TOK = 407,
     IFF_TOK = 408,
     TAGGED_TOK = 409,
     INSIDE_TOK = 410,
     RANDSEQUENCE_TOK = 411,
     ENDSEQUENCE_TOK = 412,
     CLOCKING_TOK = 413,
     ENDCLOCKING_TOK = 414,
     VOID_TOK = 415,
     DO_TOK = 416,
     FOREACH_TOK = 417,
     UNIQUE_TOK = 418,
     PRIORITY_TOK = 419,
     RANDCASE_TOK = 420,
     CCOLON_TOK = 421,
     MATCHES_TOK = 422,
     SOR_TOK = 423,
     BREAK_TOK = 424,
     CONTINUE_TOK = 425,
     RETURN_TOK = 426,
     JOINANY_TOK = 427,
     JOINNONE_TOK = 428,
     WAITORDER_TOK = 429,
     NEW_TOK = 430,
     ALWAYSCOMB_TOK = 431,
     ALWAYSLATCH_TOK = 432,
     ALWAYSFF_TOK = 433,
     ALIAS_TOK = 434,
     EXTERN_TOK = 435,
     HIGHZ0_TOK = 436,
     UNION_TOK = 437,
     STRUCT_TOK = 438,
     STATIC_TOK = 439,
     PACKED_TOK = 440,
     VIRTUAL_TOK = 441,
     CHANDLE_TOK = 442,
     ENUM_TOK = 443,
     TYPE_TOK = 444,
     CONST_TOK = 445,
     TYPEDEF_TOK = 446,
     CLASS_TOK = 447,
     IMPORT_TOK = 448,
     REF_TOK = 449,
     CONTEXT_TOK = 450,
     PURE_TOK = 451,
     EXPORT_TOK = 452,
     BIND_TOK = 453,
     MODPORT_TOK = 454,
     EXPECT_TOK = 455,
     ASSERT_TOK = 456,
     PROPERTY_TOK = 457,
     ENDPROPERTY_TOK = 458,
     ASSUME_TOK = 459,
     COVER_TOK = 460,
     SEQUENCE_TOK = 461,
     FIRST_MATCH_TOK = 462,
     INTERSECT_TOK = 463,
     WITHIN_TOK = 464,
     THROUGHOUT_TOK = 465,
     DIST_TOK = 466,
     BEFORE_TOK = 467,
     CONSTRAINT_TOK = 468,
     SOLVE_TOK = 469,
     PROGRAM_TOK = 470,
     ENDPROGRAM_TOK = 471,
     RAND_TOK = 472,
     RANDC_TOK = 473,
     LOCAL_TOK = 474,
     PROTECTED_TOK = 475,
     FORKJOIN_TOK = 476,
     FINAL_TOK = 477,
     TIMEUNIT_TOK = 478,
     TIMEPRECISION_TOK = 479,
     ENDCLASS_TOK = 480,
     ENDPACKAGE_TOK = 481,
     PACKAGE_TOK = 482,
     EXTEND_TOK = 483,
     DOUBLEPARA_TOK = 484,
     ATR_TOK = 485,
     ATL_TOK = 486,
     COVERGROUP_TOK = 487,
     ENDGROUP_TOK = 488,
     COVERPOINT_TOK = 489,
     WILDCARD_TOK = 490,
     BINS_TOK = 491,
     ILLEGALBINS_TOK = 492,
     IGNOREBINS_TOK = 493,
     CROSS_TOK = 494,
     BINSOF_TOK = 495,
     PROPEQU_TOK = 496,
     PROPLT_TOK = 497,
     EEEQU_TOK = 498,
     EQU_Q_EQU_TOK = 499,
     EX_Q_EQU_TOK = 500,
     EX_EQU_EQU_TOK = 501,
     LLLT_TOK = 502,
     GGGT_TOK = 503,
     MINUSLT_TOK = 504,
     EQULT_TOK = 505,
     INLINEBODY_TOK = 506
   };
#endif


#ifndef YYSTYPE
typedef union YYSTYPE
{

/* Line 2638 of glr.c  */
#line 59 "g:\\XXX\\doxygen-1.5.8\\src\\\\..\\src\\verilogparser.y"

	int itype;	/* for count */
	char ctype;	/* for char */
	char cstr[1024];
	


/* Line 2638 of glr.c  */
#line 309 "g:\\XXX\\doxygen-1.5.8\\src\\\\..\\src\\verilogparser.hpp"
} YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
#endif

#if ! defined YYLTYPE && ! defined YYLTYPE_IS_DECLARED
typedef struct YYLTYPE
{

  int first_line;
  int first_column;
  int last_line;
  int last_column;

} YYLTYPE;
# define YYLTYPE_IS_DECLARED 1
# define YYLTYPE_IS_TRIVIAL 1
#endif



extern YYSTYPE c_lval;

extern YYLTYPE c_lloc;


