/*-
 * Copyright (c) 2009 Doug Rabson
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

module objfile.dwarf;

//debug = line;

import objfile.objfile;
import objfile.debuginfo;
import machine.machine;
import std.string;
import std.stdio;
version(tangobos) import std.compat;
//import std.c.unix.unix;

import target;

enum {
    DW_TAG_array_type			= 0x01,
    DW_TAG_class_type			= 0x02,
    DW_TAG_entry_point			= 0x03,
    DW_TAG_enumeration_type		= 0x04,
    DW_TAG_formal_parameter		= 0x05,
    DW_TAG_imported_declaration		= 0x08,
    DW_TAG_label			= 0x0a,
    DW_TAG_lexical_block		= 0x0b,
    DW_TAG_member			= 0x0d,
    DW_TAG_pointer_type			= 0x0f,
    DW_TAG_reference_type		= 0x10,
    DW_TAG_compile_unit			= 0x11,
    DW_TAG_string_type			= 0x12,
    DW_TAG_structure_type		= 0x13,
    DW_TAG_subroutine_type		= 0x15,
    DW_TAG_typedef			= 0x16,
    DW_TAG_union_type			= 0x17,
    DW_TAG_unspecified_parameters	= 0x18,
    DW_TAG_variant			= 0x19,
    DW_TAG_common_block			= 0x1a,
    DW_TAG_common_inclusion		= 0x1b,
    DW_TAG_inheritance			= 0x1c,
    DW_TAG_inlined_subroutine		= 0x1d,
    DW_TAG_module			= 0x1e,
    DW_TAG_ptr_to_member_type		= 0x1f,
    DW_TAG_set_type			= 0x20,
    DW_TAG_subrange_type		= 0x21,
    DW_TAG_with_stmt			= 0x22,
    DW_TAG_access_declaration		= 0x23,
    DW_TAG_base_type			= 0x24,
    DW_TAG_catch_block			= 0x25,
    DW_TAG_const_type			= 0x26,
    DW_TAG_constant			= 0x27,
    DW_TAG_enumerator			= 0x28,
    DW_TAG_file_typei			= 0x29,
    DW_TAG_friend			= 0x2a,
    DW_TAG_namelist			= 0x2b,
    DW_TAG_namelist_item		= 0x2c,
    DW_TAG_packed_type			= 0x2d,
    DW_TAG_subprogram			= 0x2e,
    DW_TAG_template_type_parameter	= 0x2f,
    DW_TAG_template_value_parameter	= 0x30,
    DW_TAG_thrown_type			= 0x31,
    DW_TAG_try_block			= 0x32,
    DW_TAG_variant_part			= 0x33,
    DW_TAG_variable			= 0x34,
    DW_TAG_volatile_type		= 0x35,
    DW_TAG_dwarf_procedure		= 0x36,
    DW_TAG_restrict_type		= 0x37,
    DW_TAG_interface_type		= 0x38,
    DW_TAG_namespace			= 0x39,
    DW_TAG_imported_module		= 0x3a,
    DW_TAG_unspecified_type		= 0x3b,
    DW_TAG_partial_unit			= 0x3c,
    DW_TAG_imported_unit		= 0x3d,
    DW_TAG_condition			= 0x3f,
    DW_TAG_shared_type			= 0x40,
    DW_TAG_lo_user			= 0x4080,
    DW_TAG_hi_user			= 0xffff
}

string tagNames[] = [
    0x01: "DW_TAG_array_type",
    0x02: "DW_TAG_class_type",
    0x03: "DW_TAG_entry_point",
    0x04: "DW_TAG_enumeration_type",
    0x05: "DW_TAG_formal_parameter",
    0x08: "DW_TAG_imported_declaration",
    0x0a: "DW_TAG_label",
    0x0b: "DW_TAG_lexical_block",
    0x0d: "DW_TAG_member",
    0x0f: "DW_TAG_pointer_type",
    0x10: "DW_TAG_reference_type",
    0x11: "DW_TAG_compile_unit",
    0x12: "DW_TAG_string_type",
    0x13: "DW_TAG_structure_type",
    0x15: "DW_TAG_subroutine_type",
    0x16: "DW_TAG_typedef",
    0x17: "DW_TAG_union_type",
    0x18: "DW_TAG_unspecified_parameters",
    0x19: "DW_TAG_variant",
    0x1a: "DW_TAG_common_block",
    0x1b: "DW_TAG_common_inclusion",
    0x1c: "DW_TAG_inheritance",
    0x1d: "DW_TAG_inlined_subroutine",
    0x1e: "DW_TAG_module",
    0x1f: "DW_TAG_ptr_to_member_type",
    0x20: "DW_TAG_set_type",
    0x21: "DW_TAG_subrange_type",
    0x22: "DW_TAG_with_stmt",
    0x23: "DW_TAG_access_declaration",
    0x24: "DW_TAG_base_type",
    0x25: "DW_TAG_catch_block",
    0x26: "DW_TAG_const_type",
    0x27: "DW_TAG_constant",
    0x28: "DW_TAG_enumerator",
    0x29: "DW_TAG_file_typei",
    0x2a: "DW_TAG_friend",
    0x2b: "DW_TAG_namelist",
    0x2c: "DW_TAG_namelist_item",
    0x2d: "DW_TAG_packed_type",
    0x2e: "DW_TAG_subprogram",
    0x2f: "DW_TAG_template_type_parameter",
    0x30: "DW_TAG_template_value_parameter",
    0x31: "DW_TAG_thrown_type",
    0x32: "DW_TAG_try_block",
    0x33: "DW_TAG_variant_part",
    0x34: "DW_TAG_variable",
    0x35: "DW_TAG_volatile_type",
    0x36: "DW_TAG_dwarf_procedure",
    0x37: "DW_TAG_restrict_type",
    0x38: "DW_TAG_interface_type",
    0x39: "DW_TAG_namespace",
    0x3a: "DW_TAG_imported_module",
    0x3b: "DW_TAG_unspecified_type",
    0x3c: "DW_TAG_partial_unit",
    0x3d: "DW_TAG_imported_unit",
    0x3f: "DW_TAG_condition",
    0x40: "DW_TAG_shared_type",
    0x4080: "DW_TAG_lo_user",
    0xffff: "DW_TAG_hi_user"
    ];

enum
{
    DW_CHILDREN_no			= 0x00,
    DW_CHILDREN_yes			= 0x01
}

enum
{
    DW_AT_sibling			= 0x01,
    DW_AT_location			= 0x02,
    DW_AT_name				= 0x03,
    DW_AT_ordering			= 0x09,
    DW_AT_byte_size			= 0x0b,
    DW_AT_bit_offset			= 0x0c,
    DW_AT_bit_size			= 0x0d,
    DW_AT_stmt_list			= 0x10,
    DW_AT_low_pc			= 0x11,
    DW_AT_high_pc			= 0x12,
    DW_AT_language			= 0x13,
    DW_AT_discr				= 0x15,
    DW_AT_discr_value			= 0x16,
    DW_AT_visibility			= 0x17,
    DW_AT_import			= 0x18,
    DW_AT_string_length			= 0x19,
    DW_AT_common_reference		= 0x1a,
    DW_AT_comp_dir			= 0x1b,
    DW_AT_const_value			= 0x1c,
    DW_AT_containing_type		= 0x1d,
    DW_AT_default_value			= 0x1e,
    DW_AT_inline			= 0x20,
    DW_AT_is_optional			= 0x21,
    DW_AT_lower_bound			= 0x22,
    DW_AT_producer			= 0x25,
    DW_AT_prototyped			= 0x27,
    DW_AT_return_addr			= 0x2a,
    DW_AT_start_scope			= 0x2c,
    DW_AT_bit_stride			= 0x2e,
    DW_AT_upper_bound			= 0x2f,
    DW_AT_abstract_origin		= 0x31,
    DW_AT_accessibility			= 0x32,
    DW_AT_address_class			= 0x33,
    DW_AT_artificial			= 0x34,
    DW_AT_base_types			= 0x35,
    DW_AT_calling_convention		= 0x36,
    DW_AT_count				= 0x37,
    DW_AT_data_member_location		= 0x38,
    DW_AT_decl_column			= 0x39,
    DW_AT_decl_file			= 0x3a,
    DW_AT_decl_line			= 0x3b,
    DW_AT_declaration			= 0x3c,
    DW_AT_discr_list			= 0x3d,
    DW_AT_encoding			= 0x3e,
    DW_AT_external			= 0x3f,
    DW_AT_frame_base			= 0x40,
    DW_AT_friend			= 0x41,
    DW_AT_identifier_case		= 0x42,
    DW_AT_macro_info			= 0x43,
    DW_AT_namelist_item			= 0x44,
    DW_AT_priority			= 0x45,
    DW_AT_segment			= 0x46,
    DW_AT_specification			= 0x47,
    DW_AT_static_link			= 0x48,
    DW_AT_type				= 0x49,
    DW_AT_use_location			= 0x4a,
    DW_AT_variable_parameter		= 0x4b,
    DW_AT_virtuality			= 0x4c,
    DW_AT_vtable_elem_location		= 0x4d,
    DW_AT_allocated			= 0x4e,
    DW_AT_associated			= 0x4f,
    DW_AT_data_location			= 0x50,
    DW_AT_byte_stride			= 0x51,
    DW_AT_entry_pc			= 0x52,
    DW_AT_use_UTF8			= 0x53,
    DW_AT_extension			= 0x54,
    DW_AT_ranges			= 0x55,
    DW_AT_trampoline			= 0x56,
    DW_AT_call_column			= 0x57,
    DW_AT_call_file			= 0x58,
    DW_AT_call_line			= 0x59,
    DW_AT_description			= 0x5a,
    DW_AT_binary_scale			= 0x5b,
    DW_AT_decimal_scale			= 0x5c,
    DW_AT_small				= 0x5d,
    DW_AT_decimal_sign			= 0x5e,
    DW_AT_digit_count			= 0x5f,
    DW_AT_picture_string		= 0x60,
    DW_AT_mutable			= 0x61,
    DW_AT_threads_scaled		= 0x62,
    DW_AT_explicit			= 0x63,
    DW_AT_object_pointer		= 0x64,
    DW_AT_endianity			= 0x65,
    DW_AT_elemental			= 0x66,
    DW_AT_pure				= 0x67,
    DW_AT_recursive			= 0x68,
    DW_AT_lo_user			= 0x2000,
    DW_AT_hi_user			= 0x3fff
}

string attrNames[] = [
    0x01: "DW_AT_sibling",
    0x02: "DW_AT_location",
    0x03: "DW_AT_name",
    0x09: "DW_AT_ordering",
    0x0b: "DW_AT_byte_size",
    0x0c: "DW_AT_bit_offset",
    0x0d: "DW_AT_bit_size",
    0x10: "DW_AT_stmt_list",
    0x11: "DW_AT_low_pc",
    0x12: "DW_AT_high_pc",
    0x13: "DW_AT_language",
    0x15: "DW_AT_discr",
    0x16: "DW_AT_discr_value",
    0x17: "DW_AT_visibility",
    0x18: "DW_AT_import",
    0x19: "DW_AT_string_length",
    0x1a: "DW_AT_common_reference",
    0x1b: "DW_AT_comp_dir",
    0x1c: "DW_AT_const_value",
    0x1d: "DW_AT_containing_type",
    0x1e: "DW_AT_default_value",
    0x20: "DW_AT_inline",
    0x21: "DW_AT_is_optional",
    0x22: "DW_AT_lower_bound",
    0x25: "DW_AT_producer",
    0x27: "DW_AT_prototyped",
    0x2a: "DW_AT_return_addr",
    0x2c: "DW_AT_start_scope",
    0x2e: "DW_AT_bit_stride",
    0x2f: "DW_AT_upper_bound",
    0x31: "DW_AT_abstract_origin",
    0x32: "DW_AT_accessibility",
    0x33: "DW_AT_address_class",
    0x34: "DW_AT_artificial",
    0x35: "DW_AT_base_types",
    0x36: "DW_AT_calling_convention",
    0x37: "DW_AT_count",
    0x38: "DW_AT_data_member_location",
    0x39: "DW_AT_decl_column",
    0x3a: "DW_AT_decl_file",
    0x3b: "DW_AT_decl_line",
    0x3c: "DW_AT_declaration",
    0x3d: "DW_AT_discr_list",
    0x3e: "DW_AT_encoding",
    0x3f: "DW_AT_external",
    0x40: "DW_AT_frame_base",
    0x41: "DW_AT_friend",
    0x42: "DW_AT_identifier_case",
    0x43: "DW_AT_macro_info",
    0x44: "DW_AT_namelist_item",
    0x45: "DW_AT_priority",
    0x46: "DW_AT_segment",
    0x47: "DW_AT_specification",
    0x48: "DW_AT_static_link",
    0x49: "DW_AT_type",
    0x4a: "DW_AT_use_location",
    0x4b: "DW_AT_variable_parameter",
    0x4c: "DW_AT_virtuality",
    0x4d: "DW_AT_vtable_elem_location",
    0x4e: "DW_AT_allocated",
    0x4f: "DW_AT_associated",
    0x50: "DW_AT_data_location",
    0x51: "DW_AT_byte_stride",
    0x52: "DW_AT_entry_pc",
    0x53: "DW_AT_use_UTF8",
    0x54: "DW_AT_extension",
    0x55: "DW_AT_ranges",
    0x56: "DW_AT_trampoline",
    0x57: "DW_AT_call_column",
    0x58: "DW_AT_call_file",
    0x59: "DW_AT_call_line",
    0x5a: "DW_AT_description",
    0x5b: "DW_AT_binary_scale",
    0x5c: "DW_AT_decimal_scale",
    0x5d: "DW_AT_small",
    0x5e: "DW_AT_decimal_sign",
    0x5f: "DW_AT_digit_count",
    0x60: "DW_AT_picture_string",
    0x61: "DW_AT_mutable",
    0x62: "DW_AT_threads_scaled",
    0x63: "DW_AT_explicit",
    0x64: "DW_AT_object_pointer",
    0x65: "DW_AT_endianity",
    0x66: "DW_AT_elemental",
    0x67: "DW_AT_pure",
    0x68: "DW_AT_recursive",
    0x2000: "DW_AT_lo_user",
    0x3fff: "AT_hi_user"
    ];

enum
{
    DW_FORM_addr			= 0x01,
    DW_FORM_block2			= 0x03,
    DW_FORM_block4			= 0x04,
    DW_FORM_data2			= 0x05,
    DW_FORM_data4			= 0x06,
    DW_FORM_data8			= 0x07,
    DW_FORM_string			= 0x08,
    DW_FORM_block			= 0x09,
    DW_FORM_block1			= 0x0a,
    DW_FORM_data1			= 0x0b,
    DW_FORM_flag			= 0x0c,
    DW_FORM_sdata			= 0x0d,
    DW_FORM_strp			= 0x0e,
    DW_FORM_udata			= 0x0f,
    DW_FORM_ref_addr			= 0x10,
    DW_FORM_ref1			= 0x11,
    DW_FORM_ref2			= 0x12,
    DW_FORM_ref4			= 0x13,
    DW_FORM_ref8			= 0x14,
    DW_FORM_ref_udata			= 0x15,
    DW_FORM_indirect			= 0x16
}

enum
{
    DW_OP_addr				= 0x03,
    DW_OP_deref				= 0x06,
    DW_OP_const1u			= 0x08,
    DW_OP_const1s			= 0x09,
    DW_OP_const2u			= 0x0a,
    DW_OP_const2s			= 0x0b,
    DW_OP_const4u			= 0x0c,
    DW_OP_const4s			= 0x0d,
    DW_OP_const8u			= 0x0e,
    DW_OP_const8s			= 0x0f,
    DW_OP_constu			= 0x10,
    DW_OP_consts			= 0x11,
    DW_OP_dup				= 0x12,
    DW_OP_drop				= 0x13,
    DW_OP_over				= 0x14,
    DW_OP_pick				= 0x15,
    DW_OP_swap				= 0x16,
    DW_OP_rot				= 0x17,
    DW_OP_xderef			= 0x18,
    DW_OP_abs				= 0x19,
    DW_OP_and				= 0x1a,
    DW_OP_div				= 0x1b,
    DW_OP_minus				= 0x1c,
    DW_OP_mod				= 0x1d,
    DW_OP_mul				= 0x1e,
    DW_OP_neg				= 0x1f,
    DW_OP_not				= 0x20,
    DW_OP_or				= 0x21,
    DW_OP_plus				= 0x22,
    DW_OP_plus_uconst			= 0x23,
    DW_OP_shl				= 0x24,
    DW_OP_shr				= 0x25,
    DW_OP_shra				= 0x26,
    DW_OP_xor				= 0x27,
    DW_OP_skip				= 0x2f,
    DW_OP_bra				= 0x28,
    DW_OP_eq				= 0x29,
    DW_OP_ge				= 0x2a,
    DW_OP_gt				= 0x2b,
    DW_OP_le				= 0x2c,
    DW_OP_lt				= 0x2d,
    DW_OP_ne				= 0x2e,
    DW_OP_lit0				= 0x30,
    DW_OP_lit1				= 0x31,
    DW_OP_lit31				= 0x4f,
    DW_OP_reg0				= 0x50,
    DW_OP_reg1				= 0x51,
    DW_OP_reg31				= 0x6f,
    DW_OP_breg0				= 0x70,
    DW_OP_breg1				= 0x71,
    DW_OP_breg31			= 0x8f,
    DW_OP_regx				= 0x90,
    DW_OP_fbreg				= 0x91,
    DW_OP_bregx				= 0x92,
    DW_OP_piece				= 0x93,
    DW_OP_deref_size			= 0x94,
    DW_OP_xderef_size			= 0x95,
    DW_OP_nop				= 0x96,
    DW_OP_push_object_address		= 0x97,
    DW_OP_call2				= 0x98,
    DW_OP_call4				= 0x99,
    DW_OP_call_ref			= 0x9a,
    DW_OP_form_tls_address		= 0x9b,
    DW_OP_call_frame_cfa		= 0x9c,
    DW_OP_bit_piece			= 0x9d,
    DW_OP_lo_user			= 0xe0,
    DW_OP_hi_user			= 0xff,
}
int DW_OP_lit(int n)
{
    return DW_OP_lit0 + n;
}
int DW_OP_reg(int n)
{
    return DW_OP_reg0 + n;
}
int DW_OP_breg(int n)
{
    return DW_OP_breg0 + n;
}

enum
{
    DW_ATE_address			= 0x01,
    DW_ATE_boolean			= 0x02,
    DW_ATE_complex_float		= 0x03,
    DW_ATE_float			= 0x04,
    DW_ATE_signed			= 0x05,
    DW_ATE_signed_char			= 0x06,
    DW_ATE_unsigned			= 0x07,
    DW_ATE_unsigned_char		= 0x08,
    DW_ATE_imaginary_float		= 0x09,
    DW_ATE_packed_decimal		= 0x0a,
    DW_ATE_numeric_string		= 0x0b,
    DW_ATE_edited			= 0x0c,
    DW_ATE_signed_fixed			= 0x0d,
    DW_ATE_unsigned_fixed		= 0x0e,
    DW_ATE_decimal_float		= 0x0f,
    DW_ATE_lo_user			= 0x80,
    DW_ATE_hi_user			= 0xff,
}

enum
{
    DW_DS_unsigned			= 0x01,
    DW_DS_leading_overpunch		= 0x02,
    DW_DS_trailing_overpunch		= 0x03,
    DW_DS_leading_separate		= 0x04,
    DW_DS_trailing_separate		= 0x05,
}

enum
{
    DW_END_default			= 0x00,
    DW_END_big				= 0x01,
    DW_END_little			= 0x02,
    DW_END_lo_user			= 0x40,
    DW_END_hi_user			= 0xff,
}

enum
{
    DW_ACCESS_public			= 0x01,
    DW_ACCESS_protected			= 0x02,
    DW_ACCESS_private			= 0x03,
}

enum
{
    DW_VIS_local			= 0x01,
    DW_VIS_exported			= 0x02,
    DW_VIS_qualified			= 0x03,
}

enum
{
    DW_VIRTUALITY_none			= 0x00,
    DW_VIRTUALITY_virtual		= 0x01,
    DW_VIRTUALITY_pure_virtual		= 0x02,
}

enum
{
    DW_LANG_C89				= 0x0001,
    DW_LANG_C				= 0x0002,
    DW_LANG_Ada83			= 0x0003,
    DW_LANG_C_plus_plus			= 0x0004,
    DW_LANG_Cobol74			= 0x0005,
    DW_LANG_Cobol85			= 0x0006,
    DW_LANG_Fortran77			= 0x0007,
    DW_LANG_Fortran90			= 0x0008,
    DW_LANG_Pascal83			= 0x0009,
    DW_LANG_Modula2			= 0x000a,
    DW_LANG_Java			= 0x000b,
    DW_LANG_C99				= 0x000c,
    DW_LANG_Ada95			= 0x000d,
    DW_LANG_Fortran95			= 0x000e,
    DW_LANG_PLI				= 0x000f,
    DW_LANG_ObjC			= 0x0010,
    DW_LANG_ObjC_plus_plus		= 0x0011,
    DW_LANG_UPC				= 0x0012,
    DW_LANG_D				= 0x0013,
    DW_LANG_lo_user			= 0x8000,
    DW_LANG_hi_user			= 0xffff,
}

enum
{
    DW_ADDR_none			= 0
}

enum
{
    DW_ID_case_sensitive		= 0x00,
    DW_ID_up_case			= 0x01,
    DW_ID_down_case			= 0x02,
    DW_ID_case_insensitive		= 0x03,
}

enum
{
    DW_CC_normal			= 0x01,
    DW_CC_program			= 0x02,
    DW_CC_nocall			= 0x03,
    DW_CC_lo_user			= 0x40,
    DW_CC_hi_user			= 0xff,
}

enum
{
    DW_INL_not_inlined			= 0x00,
    DW_INL_inlined			= 0x01,
    DW_INL_declared_not_inlined		= 0x02,
    DW_INL_declared_inlined		= 0x03,
}

enum
{
    DW_ORD_row_major			= 0x00,
    DW_ORD_col_major			= 0x01,
}

enum
{
    DW_DSC_label			= 0x00,
    DW_DSC_range			= 0x01,
}

enum
{
    DW_LNS_copy				= 0x01,
    DW_LNS_advance_pc			= 0x02,
    DW_LNS_advance_line			= 0x03,
    DW_LNS_set_file			= 0x04,
    DW_LNS_set_column			= 0x05,
    DW_LNS_negate_stmt			= 0x06,
    DW_LNS_set_basic_block		= 0x07,
    DW_LNS_const_add_pc			= 0x08,
    DW_LNS_fixed_advance_pc		= 0x09,
    DW_LNS_set_prologue_end		= 0x0a,
    DW_LNS_set_epilogue_begin		= 0x0b,
    DW_LNS_set_isa			= 0x0c,
    DW_LNE_end_sequence			= 0x01,
    DW_LNE_set_address			= 0x02,
    DW_LNE_define_file			= 0x03,
    DW_LNE_lo_user			= 0x80,
    DW_LNE_hi_user			= 0xff,
}

enum
{
    DW_MACINFO_define			= 0x01,
    DW_MACINFO_undef			= 0x02,
    DW_MACINFO_start_file		= 0x03,
    DW_MACINFO_end_file			= 0x04,
    DW_MACINFO_vendor_ext		= 0xff,
}

enum
{
    DW_CFA_advance_loc			= 0x40,
    DW_CFA_offset			= 0x80,
    DW_CFA_restore			= 0xc0,
    DW_CFA_nop				= 0x00,
    DW_CFA_set_loc			= 0x01,
    DW_CFA_advance_loc1			= 0x02,
    DW_CFA_advance_loc2			= 0x03,
    DW_CFA_advance_loc4			= 0x04,
    DW_CFA_offset_extended		= 0x05,
    DW_CFA_restore_extended		= 0x06,
    DW_CFA_undefined			= 0x07,
    DW_CFA_same_value			= 0x08,
    DW_CFA_register			= 0x09,
    DW_CFA_remember_state		= 0x0a,
    DW_CFA_restore_state		= 0x0b,
    DW_CFA_def_cfa			= 0x0c,
    DW_CFA_def_cfa_register		= 0x0d,
    DW_CFA_def_cfa_offset		= 0x0e,
    DW_CFA_def_cfa_expression		= 0x0f,
    DW_CFA_expression			= 0x10,
    DW_CFA_offset_extended_sf		= 0x11,
    DW_CFA_def_cfa_sf			= 0x12,
    DW_CFA_def_cfa_offset_sf		= 0x13,
    DW_CFA_val_offset			= 0x14,
    DW_CFA_val_offset_sf		= 0x15,
    DW_CFA_val_expression		= 0x16,
    DW_CFA_lo_user			= 0x1c,
    DW_CFA_hi_user			= 0x3f,
}

private ubyte parseUByte(ref char* p)
{
    return *p++;
}

private byte parseSByte(ref char* p)
{
    byte v = *cast(byte*) p;
    p++;
    return v;
}

private ushort parseUShort(ref char* p)
{
    ushort v;
    v = p[0] + (p[1] << 8);
    p += 2;
    return v;
}

private short parseSShort(ref char* p)
{
    short v;
    v = p[0] + (p[1] << 8);
    p += 2;
    return v;
}

private uint parseUInt(ref char* p)
{
    uint v;
    v = p[0] + (p[1] << 8) + (p[2] << 16) + (p[3] << 24);
    p += 4;
    return v;
}

private uint parseSInt(ref char* p)
{
    int v;
    v = p[0] + (p[1] << 8) + (p[2] << 16) + (p[3] << 24);
    p += 4;
    return v;
}

private ulong parseULong(ref char* p)
{
    ulong lo, hi;
    lo = parseUInt(p);
    hi = parseUInt(p);
    return lo | (hi << 32);
}


private ulong parseSLong(ref char* p)
{
    return cast(long) parseULong(p);
}

private ulong parseOffset(ref char* p, bool is64)
{
    if (is64)
	return parseULong(p);
    else
	return parseUInt(p);
}

private ulong parseLength(ref char* p, bool is64)
{
    if (is64)
	return parseULong(p);
    else
	return parseUInt(p);
}

private void skipString(ref char* p)
{
    while (*p)
	p++;
    p++;
}

private string parseString(ref char* p)
{
    string v = std.string.toString(p);
    skipString(p);
    return v;
}

private size_t parseInitialLength(ref char* p, ref bool is64)
{
    uint v = parseUInt(p);
    if (v < 0xffffff00) {
	is64 = false;
	return v;
    }
    if (v != 0xffffffff)
	throw new Exception("Bad initial length");
    is64 = true;
    ulong lv;
    lv = parseUInt(p);
    lv |= (parseUInt(p) << 32);
    return lv;
}

private ulong parseULEB128(ref char* p)
{
    ulong v = 0;
    int shift = 0;
    bool done = false;
    char b;

    while (!done) {
	b = *p++;
	v |= (b & 0x7f) << shift;
	shift += 7;
	if ((b & 0x80) == 0)
	    done = true;
    }
    return v;
}

private long parseSLEB128(ref char* p)
{
    long v = 0;
    int shift = 0;
    bool done = false;
    char b;

    while (!done) {
	b = *p++;
	v |= (b & 0x7f) << shift;
	shift += 7;
	if ((b & 0x80) == 0)
	    done = true;
    }
    if (shift < 64 && (b & 0x40))
	v |= -(1 << shift);	// sign extend
    return v;
}

class DwarfFile: public DebugInfo
{
    this(Objfile obj)
    {
	obj_ = obj;

	if (obj_.hasSection(".debug_str"))
	    strtab_ = obj_.readSection(".debug_str");

	// Read .debug_pubnames if present
	if (obj_.hasSection(".debug_pubnames")) {
	    char[] pubnames = obj_.readSection(".debug_pubnames");
	    char* p = &pubnames[0], pEnd = p + pubnames.length;

	    while (p < pEnd) {
		bool is64;
		ulong len = parseInitialLength(p, is64);
		uint ver = parseUShort(p);

		NameSet set;
		set.cuOffset = parseOffset(p, is64);
		parseLength(p, is64);
		for (;;) {
		    ulong off = parseOffset(p, is64);
		    if (!off)
			break;
		    string name = parseString(p);
		    set.names[name] = off;
		    //writefln("%s = %d (cu %d)", name, off, set.sectionOffset);
		}
		pubnames_ ~= set;
	    }
	}

	// Read .debug_pubtypes if present
	if (obj_.hasSection(".debug_pubtypes")) {
	    char[] pubtypes = obj_.readSection(".debug_pubtypes");
	    char* p = &pubtypes[0], pEnd = p + pubtypes.length;

	    while (p < pEnd) {
		bool is64;
		ulong len = parseInitialLength(p, is64);
		uint ver = parseUShort(p);

		NameSet set;
		set.cuOffset = parseOffset(p, is64);
		parseLength(p, is64);
		for (;;) {
		    ulong off = parseOffset(p, is64);
		    if (!off)
			break;
		    string name = parseString(p);
		    set.names[name] = off;
		    writefln("%s = %d (cu %d)", name, off, set.cuOffset);
		}

	    }
	}

	// Read .debug_aranges if present
	if (obj_.hasSection(".debug_aranges")) {
	    char[] aranges = obj_.readSection(".debug_aranges");
	    char* p = &aranges[0], pEnd = p + aranges.length;

	    while (p < pEnd) {
		bool is64;
		ulong len = parseInitialLength(p, is64);
		uint ver = parseUShort(p);

		CompilationUnit cu = new CompilationUnit(this);
		cu.offset = parseOffset(p, is64);
		cu.addressSize = parseUByte(p);
		cu.segmentSize = parseUByte(p);

		// Undocumented: need to align to next multiple of
		// 2 * address size
		ulong a = is64 ? 16 : 8;
		if ((p - &aranges[0]) % a) {
		    p += a - ((p - &aranges[0]) % a);
		}

		ulong start, length;
		for (;;) {
		    start = parseOffset(p, is64);
		    length = parseLength(p, is64);
		    if (start == 0 && length == 0)
			break;
		    cu.addresses ~= AddressRange(start, start + length);
		}
		compilationUnits_[cu.offset] = cu;
	    }
	} else {
	    // If there is no .debug_aranges section, just read all
	    // the .debug_info section now.
	    char[] debugInfo = debugSection(".debug_info");
	    char* p = &debugInfo[0], pNext, ep = p + debugInfo.length;
	    bool is64;
	    size_t len;

	    do {
		CompilationUnit cu = new CompilationUnit(this);
		cu.offset = p - &debugInfo[0];
		parseCompilationUnit(cu, p);
		compilationUnits_[cu.offset] = cu;
	    } while (p < ep);
	}
	parseDebugFrame();
    }

    static bool hasDebug(Objfile obj)
    {
	if (obj.hasSection(".debug_line")
	    && obj.hasSection(".debug_info")
	    && obj.hasSection(".debug_abbrev"))
	    return true;
    }

    // DebugInfo compliance
    override {
	bool findLineByAddress(ulong address, out LineEntry[] res)
	{
	    bool found = false;
	    LineEntry lastEntry;

	    bool processEntry(LineEntry* le)
	    {
		debug (line)
		    writefln("%s:%d 0x%x", le.file, le.line, le.address);
		if (le.address <= address) {
		    lastEntry = *le;
		    found = true;
		} else if (address <= le.address) {
		    if (found) {
			res.length = 2;
			res[0] = lastEntry;
			res[1] = *le;
			return true; // stop now
		    }
		}
		return false;
	    }

	    debug (line)
		writefln("finding 0x%x", address);
	    auto cu = findCU(address);
	    if (cu) {
		uint lineOffset = cu.die[DW_AT_stmt_list].ul;
		char[] lines = debugSection(".debug_line");
		char* p = &lines[lineOffset];
		parseLineTable(p, &processEntry);
		return found;
	    }
	    return false;
	}

	bool findLineByName(string file, int line, out LineEntry[] res)
	{
	    bool found = false;

	    bool processEntry(LineEntry* le)
	    {
		if ((le.name == file || le.fullname == file)
		    && le.line == line) {
		    found = true;
		    res ~= *le;
		}
		return false;
	    }

	    foreach (cu; compilationUnits_) {
		cu.loadDIE;
		uint lineOffset = cu.die.attrs[DW_AT_stmt_list].ul;
		char[] lines = debugSection(".debug_line");
		char* p = &lines[lineOffset];
		parseLineTable(p, &processEntry);
	    }
	    return found;
	}
	bool findLineByFunction(string func, out LineEntry[] res)
	{
	    foreach (ns; pubnames_) {
		try {
		    CompilationUnit cu = compilationUnits_[ns.cuOffset];
		    ulong dieOff = ns.names[func];
		    cu.loadDIE;
		    DIE die = cu.dieMap[dieOff];
		    if (die.tag == DW_TAG_subprogram) {
			LineEntry[] le;
			if (findLineByAddress(die.attrs[DW_AT_low_pc].ul, le))
			    res ~= le[1];
		    }
		} catch {
		    continue;
		}
	    }
				       
	    return res.length > 0;
	}

	bool findFrameBase(MachineState state, out Location loc)
	{
	    auto pc = state.getGR(state.pcregno);
	    auto cu = findCU(pc);
	    if (cu) {
		try {
		    //writefln("CU offset=%x", cu.offset);
		    DIE func = cu.findSubprogram(pc);
		    if (func) {
			auto off = func[DW_AT_frame_base];
			if (off) {
			    //writefln("DW_AT_frame_base=%x", off.ul);
			    char[] locs = debugSection(".debug_loc");
			    return evalLoclist(cu, &locs[off.ul], state, loc);
			}
		    }
		} catch (Exception e) {
		    return false;
		}
	    }
	    return false;
	}

	MachineState unwind(MachineState state)
	{
	    auto pc = state.getGR(state.pcregno);

	    foreach (fde; fdes_)
		if (fde.contains(pc))
		    return fde.unwind(state);
	    return null;
	}
    }

private:
    char[] debugSection(string name)
    {
	try {
	    return debugSections_[name];
	} catch (Exception e) {
	    debugSections_[name] = obj_.readSection(name);
	    return debugSections_[name];
	}
    }

    void parseDebugFrame()
    {
	char[] debugFrame = debugSection(".debug_frame");
	char* pStart = &debugFrame[0];
	char* pEnd = pStart + debugFrame.length;
	char* p = pStart;

	CIE[ulong] cies;

	while (p < pEnd) {
	    bool is64;
	    ulong off = p - pStart;
	    auto len = parseInitialLength(p, is64);
	    auto entryStart = p;
	    auto cie_id = parseOffset(p, is64);

	    if ((is64 && cie_id == 0xffffffffffffffff)
		|| (!is64 && cie_id == 0xffffffff)) {
		// CIE
		CIE cie = new CIE;
		auto ver = parseUByte(p);
		auto augmentation = parseString(p);
		cie.codeAlign = parseULEB128(p);
		cie.dataAlign = parseSLEB128(p);
		cie.returnAddress = parseULEB128(p);
		cie.instructionStart = p;
		cie.instructionEnd = entryStart + len;
		cies[off] = cie;
	    } else {
		// FDE
		FDE fde = new FDE;
		fde.is64 = is64;
		fde.cie = cies[cie_id];
		fde.initialLocation = parseOffset(p, is64);
		fde.addressRange = parseOffset(p, is64);
		fde.instructionStart = p;
		fde.instructionEnd = entryStart + len;
		fdes_ ~= fde;
	    }
	    p = entryStart + len;
	}
    }

    void parseCompilationUnit(CompilationUnit cu, ref char* p)
    {
	bool is64;
	size_t len;
	char* base = p;
	char* pNext;

	len = parseInitialLength(p, is64);
	pNext = p + len;

	uint ver = parseUShort(p);
	uint abbrevOffset = parseOffset(p, is64);
	uint addrlen = parseUByte(p);

	char[] abbrev = debugSection(".debug_abbrev");
	char* abbrevp = &abbrev[abbrevOffset];
	char* abbrevTable[int];
	for (;;) {
	    ulong code = parseULEB128(abbrevp);
	    if (!code)
		break;
	    abbrevTable[code] = abbrevp;

	    // Skip entry
	    parseULEB128(abbrevp); // tag
	    abbrevp++;		   // hasChildren
	    for (;;) {
		ulong at = parseULEB128(abbrevp);
		ulong form = parseULEB128(abbrevp);
		if (!at)
		    break;
	    }
	}

	ulong off = p - base;
	ulong abbrevCode = parseULEB128(p);
	if (abbrevCode == 0)
	    return;

	cu.is64 = is64;
	cu.die = new DIE(cu, base, p, abbrevCode,
			 abbrevTable, addrlen, strtab_);
	cu.dieMap[off] = cu.die;
    }

    void parseLineTable(ref char* p, bool delegate(LineEntry*) dg)
    {
	struct DwarfLineEntry {
	    ulong address;
	    uint file;
	    uint line;
	    uint column;
	    bool isStatement;
	    bool basicBlock;
	    bool endSequence;
	    bool prologueEnd;
	    bool epilogueBegin;
	    int isa;
	}

	struct FileEntry {
	    string fullname;
	    char* name;
	    uint directoryIndex;
	    ulong modificationTime;
	    ulong length;
	}

	bool is64;
	size_t len;
	char* pEnd, pEndHeader;

	len = parseInitialLength(p, is64);
	pEnd = p + len;
	uint ver = parseUShort(p);
	ulong headerLength = parseLength(p, is64);
	pEndHeader = p + headerLength;
	uint instructionLength = parseUByte(p);
	bool defaultIsStatement = parseUByte(p) != 0;
	int lineBase = parseSByte(p);
	uint lineRange = parseUByte(p);
	ubyte standardOpcodeLengths[];
	uint opcodeBase = parseUByte(p);
	standardOpcodeLengths.length = opcodeBase;
	for (int i = 1; i < opcodeBase; i++)
	    standardOpcodeLengths[i] = parseUByte(p);

	char* includeDirectories[];
	while (*p) {
	    includeDirectories ~= p;
	    skipString(p);
	}
	p++;

	FileEntry fileNames[];
	while (*p) {
	    char* name = p;
	    skipString(p);
	    uint di = parseULEB128(p);
	    ulong mt = parseULEB128(p);
	    ulong fl = parseULEB128(p);
	    fileNames ~= FileEntry(null, name, di, mt, fl);
	}
	p++;

	if (p != pEndHeader)
	    throw new Exception("unexpected bytes in line table header");

	DwarfLineEntry le;

	le.address = 0;
	le.file = 1;
	le.line = 1;
	le.column = 0;
	le.isStatement = defaultIsStatement;
	le.basicBlock = false;
	le.endSequence = false;
	le.prologueEnd = false;
	le.epilogueBegin = false;
	le.isa = 0;

	int specialOpcodeAddressIncrement(ubyte op)
	{
	    op -= opcodeBase;
	    return (op / lineRange) * instructionLength;
	}

	int specialOpcodeLineIncrement(ubyte op)
	{
	    op -= opcodeBase;
	    return lineBase + (op % lineRange);
	}

	bool processRow(DwarfLineEntry* le)
	{
	    FileEntry* fe = &fileNames[le.file - 1];
	    if (fe.fullname == null) {
		string filename;
		if (fe.directoryIndex) {
		    filename =
			.toString(includeDirectories[fe.directoryIndex - 1]);
		    filename ~= "/";
		    filename ~= .toString(fe.name);
		} else {
		    filename = .toString(fe.name);
		}
		fe.fullname = filename;
	    }

	    LineEntry dle;
	    dle.address = le.address;
	    dle.name = .toString(fe.name);
	    dle.fullname = fe.fullname;
	    dle.line = le.line;
	    dle.column = le.column;
	    dle.isStatement = le.isStatement;
	    dle.basicBlock = le.basicBlock;
	    dle.endSequence = le.endSequence;
	    dle.prologueEnd = le.prologueEnd;
	    dle.epilogueBegin = le.epilogueBegin;
	    return dg(&dle);
	}

	debug (line)
	    writefln("opcodeBase=%d, lineBase=%d, lineRange=%d",
		     opcodeBase, lineBase, lineRange);
	while (p < pEnd) {
	    ubyte op = parseUByte(p);
	    if (op >= opcodeBase) {
		debug (line)
		    writefln("%d:special opcode %d:%d",
			     op,
			     specialOpcodeAddressIncrement(op),
			     specialOpcodeLineIncrement(op));
		le.address += specialOpcodeAddressIncrement(op);
		le.line += specialOpcodeLineIncrement(op);
		if (processRow(&le))
		    return;
		le.basicBlock = false;
		le.prologueEnd = false;
		le.epilogueBegin = false;
		continue;
	    }
	    switch (op) {
	    case 0:
		debug (line)
		    writefln("%d:extended opcode", op);
		// Extended opcode
		uint oplen = parseULEB128(p);
		char* pNext = p + oplen;
		switch (parseUByte(p)) {
		case DW_LNE_end_sequence:
		    debug (line)
			writefln(" %d:DW_LNE_end_sequence", op);
		    le.endSequence = true;
		    if (processRow(&le))
			return;
		    break;

		case DW_LNE_set_address:
		    le.address = parseOffset(p, is64);
		    debug (line)
			writefln(" %d:DW_LNE_set_address(0x%x)",
				 op, le.address);
		    break;

		case DW_LNE_define_file:
		    char* name = p;
		    skipString(p);
		    uint di = parseULEB128(p);
		    ulong mt = parseULEB128(p);
		    ulong fl = parseULEB128(p);
		    fileNames ~= FileEntry(null, name, di, mt, fl);
		    debug (line)
			writefln(" %d:DW_LNE_define_file(%s)",
				 op, .toString(name));
		    break;
		}
		p = pNext;
		break;

	    case DW_LNS_copy:
		debug (line)
		    writefln("%d:DW_LNS_copy", op);
		if (processRow(&le))
		    return;
		le.basicBlock = false;
		le.prologueEnd = false;
		le.epilogueBegin = false;
		break;

	    case DW_LNS_advance_pc:
		le.address += instructionLength * parseSLEB128(p);
		debug (line)
		    writefln("%d:DW_LNS_advance_pc(0x%x)", op, le.address);
		break;

	    case DW_LNS_advance_line:
		debug (line) {
		    char* pp = p;
		    writefln("%d:DW_LNS_advance_line(%d)",
			     op, *pp);
		}
		le.line += instructionLength * parseSLEB128(p);
		break;

	    case DW_LNS_set_file:
		le.file = parseULEB128(p);
		debug (line)
		    writefln("%d:DW_LNS_set_file(%s)",
			     op, .toString(fileNames[le.file].name));
		break;

	    case DW_LNS_set_column:
		le.column = parseULEB128(p);
		debug (line)
		    writefln("%d:DW_LNS_set_column(%s)", op, le.column);
		break;

	    case DW_LNS_negate_stmt:
		debug (line)
		    writefln("%d:DW_LNS_negate_stmt", op);
		le.isStatement = !le.isStatement;
		break;

	    case DW_LNS_set_basic_block:
		debug (line)
		    writefln("%d:DW_LNS_set_basic_block", op);
		le.basicBlock = true;
		break;

	    case DW_LNS_const_add_pc:
		debug (line)
		    writefln("%d:DW_LNS_add_pc(%d)", op,
			     specialOpcodeLineIncrement(255));
		le.address += specialOpcodeAddressIncrement(255);
		break;

	    case DW_LNS_fixed_advance_pc:
		debug (line) {
		    char* pp = p;
		    writefln("%d:DW_LNS_advance_pc", op, parseUShort(pp));
		}
		le.address += parseUShort(p);
		break;

	    case DW_LNS_set_prologue_end:
		debug (line)
		    writefln("%d:DW_LNS_set_prologue_end", op);
		le.prologueEnd = true;
		break;

	    case DW_LNS_set_epilogue_begin:
		debug (line)
		    writefln("%d:DW_LNS_set_epilogue_begin", op);
		le.epilogueBegin = true;
		break;

	    case DW_LNS_set_isa:
		debug (line)
		    writefln("%d:DW_LNS_set_isa", op);
		le.isa = parseULEB128(p);
		break;

	    default:
		throw new Exception("Unexpected line table opcode");
	    }
	}
    }

    bool evalLocation(CompilationUnit cu, char* p, char* pEnd,
		      MachineState state, out Location result)
    {
	struct ValueStack
	{
	    size_t length()
	    {
		return stack.length;
	    }
	    void push(long v)
	    {
		stack ~= v;
	    }
	    long pop()
	    {
		long v = top();
		stack.length = stack.length - 1;
		return v;
	    }
	    long top()
	    {
		return stack[stack.length - 1];
	    }
	    long opIndex(int i)
	    {
		return stack[stack.length - 1 - i];
	    }
	    void opIndexAssign(long v, int i)
	    {
		stack[stack.length - 1 - i] = v;
	    }
	    void clear()
	    {
		stack.length = 0;
	    }
	    long[] stack;
	}
	ValueStack stack;

	/**
	 * Evaluate the expression, leaving the result on the
	 * stack. Evaluation stops at the end of the expression or at
	 * the first DW_OP_piece or DW_OP_bit_piece.
	 */
	void evalExpr(ref char* p, char* pEnd)
	{
	    long v, v1;
	    int addrlen = cu.is64 ? 8 : 4;
	    ubyte[] t;
	    char* pp;

	    /**
	     * Wrap a value based on the target address size.
	     */
	    long addrWrap(long v)
	    {
		if (addrlen == 4)
		    v &= 0xffffffff;
		return v;
	    }

	    while (p < pEnd) {
		auto op = *p++;
		if (op >= DW_OP_lit0 && op <= DW_OP_lit31) {
		    stack.push(op - DW_OP_lit0);
		    continue;
		}
		if (op >= DW_OP_breg0 && op <= DW_OP_breg31) {
		    v = cast(long) state.getGR(op - DW_OP_breg0)
			+ parseSLEB128(p);
		    stack.push(v);
		    continue;
		}
		switch (op) {
		case DW_OP_addr:
		    stack.push(parseOffset(p, cu.is64));
		    break;
		
		case DW_OP_const1u:
		    stack.push(parseUByte(p));
		    break;
		
		case DW_OP_const1s:
		    stack.push(parseSByte(p));
		    break;
		
		case DW_OP_const2u:
		    stack.push(parseUShort(p));
		    break;
		
		case DW_OP_const2s:
		    stack.push(parseSShort(p));
		    break;

		case DW_OP_const4u:
		    stack.push(parseUInt(p));
		    break;
		
		case DW_OP_const4s:
		    stack.push(parseSInt(p));
		    break;

		case DW_OP_const8u:
		    stack.push(parseULong(p));
		    break;
		
		case DW_OP_const8s:
		    stack.push(parseSLong(p));
		    break;

		case DW_OP_constu:
		    stack.push(parseULEB128(p));
		    break;

		case DW_OP_consts:
		    stack.push(parseSLEB128(p));
		    break;

		case DW_OP_fbreg:
		    Location frame;
		    v = parseSLEB128(p);
		    if (findFrameBase(state, frame))
			stack.push(frame.address + v);
		    else
			stack.push(v);
		    break;

		case DW_OP_bregx:
		    v = cast(long) state.getGR(parseULEB128(p))
			+ parseSLEB128(p);
		    stack.push(v);
		    break;

		case DW_OP_dup:
		    stack.push(stack.top);
		    break;

		case DW_OP_drop:
		    stack.pop;
		    break;

		case DW_OP_pick:
		    stack.push(stack[*p++]);
		    break;
		
		case DW_OP_over:
		    stack.push(stack[1]);
		    break;

		case DW_OP_swap:
		    v = stack.top;
		    stack[0] = stack[1];
		    stack[1] = v;
		    break;

		case DW_OP_rot:
		    v = stack.top;
		    stack[0] = stack[1];
		    stack[1] = stack[2];
		    stack[2] = v;
		    break;

		case DW_OP_deref:
		    v = stack.pop;
		    t = state.readMemory(v, addrlen);
		    pp = cast(char*) &t[0];
		    stack.push(parseOffset(pp, cu.is64));
		    break;

		case DW_OP_deref_size:
		    v = stack.pop;
		    t = state.readMemory(v, *p++);
		    while (t.length < addrlen)
			t ~= 0;
		    pp = cast(char*) &t[0];
		    stack.push(parseOffset(pp, cu.is64));
		    break;

		case DW_OP_xderef:
		    throw new Exception("DW_OP_xderef not supported");

		case DW_OP_xderef_size:
		    throw new Exception("DW_OP_xderef_size not supported");

		case DW_OP_push_object_address:
		case DW_OP_form_tls_address:
		case DW_OP_call_frame_cfa:
		    throw new Exception("op not supported yet");


		case DW_OP_abs:
		    if (stack.top < 0)
			stack.push(addrWrap(-stack.pop));
		    break;

		case DW_OP_and:
		    v = stack.pop;
		    v1 = stack.pop;
		    stack.push(addrWrap(v1 & v));
		    break;

		case DW_OP_div:
		    v = stack.pop;
		    v1 = stack.pop;
		    stack.push(addrWrap(v1 / v));
		    break;

		case DW_OP_minus:
		    v = stack.pop;
		    v1 = stack.pop;
		    stack.push(addrWrap(v1 - v));
		    break;

		case DW_OP_mod:
		    v = stack.pop;
		    v1 = stack.pop;
		    stack.push(addrWrap(v1 % v));
		    break;

		case DW_OP_mul:
		    v = stack.pop;
		    v1 = stack.pop;
		    stack.push(addrWrap(v1 * v));
		    break;

		case DW_OP_neg:
		    stack.push(addrWrap(-stack.pop));
		    break;

		case DW_OP_not:
		    stack.push(addrWrap(~stack.pop));
		    break;

		case DW_OP_or:
		    v = stack.pop;
		    v1 = stack.pop;
		    stack.push(addrWrap(v1 | v));
		    break;

		case DW_OP_plus:
		    v = stack.pop;
		    v1 = stack.pop;
		    stack.push(addrWrap(v1 + v));
		    break;

		case DW_OP_plus_uconst:
		    v = stack.pop;
		    stack.push(addrWrap(v + parseULEB128(p)));
		    break;

		case DW_OP_shl:
		    v = stack.pop;
		    v1 = stack.pop;
		    stack.push(addrWrap(v1 << v));
		    break;

		case DW_OP_shr:
		    v = stack.pop;
		    v1 = stack.pop;
		    stack.push(addrWrap(v1 >>> v));
		    break;

		case DW_OP_shra:
		    v = stack.pop;
		    v1 = stack.pop;
		    stack.push(addrWrap(v1 >> v));
		    break;

		case DW_OP_xor:
		    v = stack.pop;
		    v1 = stack.pop;
		    stack.push(addrWrap(v1 ^ v));
		    break;

		case DW_OP_le:
		    v = stack.pop;
		    v1 = stack.pop;
		    stack.push(v1 <= v ? 1 : 0);
		    break;

		case DW_OP_ge:
		    v = stack.pop;
		    v1 = stack.pop;
		    stack.push(v1 >= v ? 1 : 0);
		    break;

		case DW_OP_eq:
		    v = stack.pop;
		    v1 = stack.pop;
		    stack.push(v1 == v ? 1 : 0);
		    break;

		case DW_OP_lt:
		    v = stack.pop;
		    v1 = stack.pop;
		    stack.push(v1 < v ? 1 : 0);
		    break;

		case DW_OP_gt:
		    v = stack.pop;
		    v1 = stack.pop;
		    stack.push(v1 > v ? 1 : 0);
		    break;

		case DW_OP_skip:
		    v = parseSShort(p);
		    p += v;
		    break;

		case DW_OP_bra:
		    v = parseSShort(p);
		    if (stack.pop != 0)
			p += v;
		    break;

		case DW_OP_call2:
		    v = parseUShort(p);
		    auto die = cu.dieMap[v];
		    try {
			auto loc = die.attrs[DW_AT_location];
			pp = loc.b.start;
			evalExpr(pp, pp + loc.b.length);
		    } catch (Exception e) {
		    }
		    break;

		case DW_OP_call4:
		    v = parseUInt(p);
		    auto die = cu.dieMap[v];
		    try {
			auto loc = die.attrs[DW_AT_location];
			pp = loc.b.start;
			evalExpr(pp, pp + loc.b.length);
		    } catch (Exception e) {
		    }
		    break;

		case DW_OP_call_ref:
		    throw new Exception("DW_OP_call_ref mot supported");

		case DW_OP_nop:
		    break;

		case DW_OP_piece:
		case DW_OP_bit_piece:
		    return;


		}
	    }
	}

	/*
	 * Loop over the expression finding pieces to compose into the
	 * final object.
	 */
	ubyte[] obj;
	Location loc;
	while (p < pEnd) {
	    /*
	     * Check for DW_OP_regN first, otherwise evaluate the
	     * expression to get an address.
	     */
	    auto op = *p;
	    if (op >= DW_OP_reg0 && op <= DW_OP_reg31) {
		p++;
		loc.type = Location.Type.Register;
		loc.register = op - DW_OP_reg0;
		loc.length = state.grWidth(loc.register) / 8;
	    } else if (op == DW_OP_regx) {
		p++;
		loc.type = Location.Type.Register;
		loc.register = parseULEB128(p);
		loc.length = state.grWidth(loc.register) / 8;
	    } else {
		loc.type = Location.Type.Address;
		loc.length = 1;
		evalExpr(p, pEnd);
		loc.address = stack.pop;
		stack.clear;
	    }
	    if (p == pEnd) {
		/*
		 * Simple location
		 */
		result = loc;
		return true;
	    }
	    if (p < pEnd) {
		/*
		 * Composite - add up the pieces
		 */
		op = *p++;
		ubyte[] t;
		switch (op) {
		case DW_OP_piece:
		    t.length = parseULEB128(p);
		    switch (loc.type) {
		    case Location.Type.Value:
			t[] = loc.value[0..t.length];
			break;

		    case Location.Type.Address:
			t[] = state.readMemory(loc.address, t.length);
			break;

		    case Location.Type.Register:
			ubyte buf[8];
			// XXX byte swap register value
			*cast(long*) &buf[0] = state.getGR(loc.register);
			t[] = buf[0..t.length];
			break;

		    }
		    obj ~= t;
		    break;

		case DW_OP_bit_piece:
		    auto nbits = parseULEB128(p);
		    auto boff = parseULEB128(p);

		    ulong getVal(ubyte[] t)
		    {
			// XXX assume LE for now.
			ulong v = 0;
			int shift;
			foreach (b; t) {
			    v |= b << shift;
			    shift += 8;
			}
			return v;
		    }

		    ulong pv;
		    switch (loc.type) {
		    case Location.Type.Value:
			pv = getVal(loc.value);
			break;

		    case Location.Type.Address:
			pv = getVal(state.readMemory(loc.address,
						     (nbits + 7) / 8));
			break;

		    case Location.Type.Register:
			pv = state.getGR(loc.register);
			break;
		    }

		    pv = (pv >>> boff) & ((1 << nbits) - 1);
		    // XXX not sure how to compose into obj - need example
		    //obj.length = 8; // XXX not correct
		    //*cast(long*) obj = pv;
		    break;

		defaut:
		    throw new Exception("Expected DW_OP_piece or DW_OP_bit_piece");
		}
	    }
	}
    }

    bool evalLoclist(CompilationUnit cu, char* p, MachineState state,
	out Location result)
    {
	ulong pc = state.getGR(state.pcregno);
	ulong s, e, base;

	base = cu.die[DW_AT_low_pc].ul;
	for (;;) {
	    s = parseOffset(p, cu.is64);
	    e = parseOffset(p, cu.is64);
	    if (s == 0 && e == 0)
		break;
	    if ((cu.is64 && s == 0xffffffffffffffff)
		|| (!cu.is64 && s == 0xffffffff)) {
		base = e;
		continue;
	    }
	    size_t expLen = parseUShort(p);
	    char* expStart = p;
	    char* expEnd = p + expLen;
	    p = expEnd;
	    if (pc >= base + s && pc < base + e) {
		return evalLocation(cu, expStart, expEnd, state, result);
	    }
	}
	return false;
    }

    /**
     * Return the CU that contains the given address, if any.
     */
    CompilationUnit findCU(ulong address)
    {
	foreach (cu; compilationUnits_) {
	    if (cu.contains(address)) {
		cu.loadDIE;
		return cu;
	    }
	}
	return null;
    }


    Objfile obj_;
    char[] debugSections_[string];
    char[] strtab_;
    NameSet[] pubnames_;
    CompilationUnit[ulong] compilationUnits_;
    FDE[] fdes_;
}

private:

struct NameSet
{
    ulong cuOffset;
    ulong names[string];
}

class AttributeValue
{
    this(int f, ref char* p, int addrlen, char[] strtab)
    {
	form = f;
    again:
	switch (form) {
	case DW_FORM_ref_addr:
	case DW_FORM_addr:
	    if (addrlen == 4)
		ul = parseUInt(p);
	    else
		ul = parseULong(p);
	    break;

	case DW_FORM_block:
	    b.length = parseULEB128(p);
	    goto readBlock;

	case DW_FORM_block1:
	    b.length = parseUByte(p);
	    goto readBlock;

	case DW_FORM_block2:
	    b.length = parseUShort(p);
	readBlock:
	    b.start = p;
	    p += b.length;
	    break;

	case DW_FORM_block4:
	    b.length = parseUInt(p);
	    goto readBlock;
	    
	case DW_FORM_ref1:
	case DW_FORM_data1:
	    ul = parseUByte(p);
	    break;

	case DW_FORM_ref2:
	case DW_FORM_data2:
	    ul = parseUShort(p);
	    break;

	case DW_FORM_ref4:
	case DW_FORM_data4:
	    ul = parseUInt(p);
	    break;

	case DW_FORM_ref8:
	case DW_FORM_data8:
	    ul = parseULong(p);
	    break;

	case DW_FORM_string:
	    str = p;
	    while (*p)
		p++;
	    p++;
	    break;

	case DW_FORM_flag:
	    ul = parseUByte(p);
	    break;

	case DW_FORM_sdata:
	    l = parseSLEB128(p);
	    break;

	case DW_FORM_strp:
	    ulong off;
	    if (addrlen == 4)
		off = parseUInt(p);
	    else
		off = parseULong(p);
	    str = &strtab[off];
	    break;

	case DW_FORM_udata:
	case DW_FORM_ref_udata:
	    ul = parseULEB128(p);
	    break;

	case DW_FORM_indirect:
	    form = parseULEB128(p);
	    goto again;
	}
    }

    void print()
    {

	switch (form) {
	case DW_FORM_ref_addr:
	case DW_FORM_addr:
	case DW_FORM_ref1:
	case DW_FORM_data1:
	case DW_FORM_ref2:
	case DW_FORM_data2:
	case DW_FORM_ref4:
	case DW_FORM_data4:
	case DW_FORM_ref8:
	case DW_FORM_data8:
	case DW_FORM_flag:
	case DW_FORM_udata:
	case DW_FORM_ref_udata:
	    writefln("%d", ul);
	    break;

	case DW_FORM_block:
	case DW_FORM_block1:
	case DW_FORM_block2:
	case DW_FORM_block4:
	    writefln("block[%d]", b.length);
	    break;

	case DW_FORM_string:
	case DW_FORM_strp:
	    writefln("%s", std.string.toString(str));
	    break;

	case DW_FORM_sdata:
	    writefln("%ld", l);
	    break;

	default:
	    writefln("???");
	}
    }

    int form;
    struct block {
	size_t length;
	char* start;
    }

    union {
	ulong ul;
	long l;
	char* str;
	block b;
    }
}

struct AddressRange
{
    bool contains(ulong pc)
    {
	return pc >= start && pc < end;
    }

    ulong start;
    ulong end;
}

class DIE
{
    DwarfFile top;
    int tag;
    bool hasChildren;
    bool is64;
    AttributeValue attrs[int];
    DIE[] children;
    AddressRange[] addresses; // set of address ranges for this DIE

    this(CompilationUnit cu, char* base, ref char* diep,
	 uint abbrevCode, char*[int] abbrevTable,
	 int addrlen, char[] strtab)
    {
	top = cu.parent;

	char* abbrevp = abbrevTable[abbrevCode];
	tag = parseULEB128(abbrevp);
	hasChildren = *abbrevp++ == DW_CHILDREN_yes;
	is64 = cu.is64;

	for (;;) {
	    int at = parseULEB128(abbrevp);
	    int form = parseULEB128(abbrevp);
	    if (!at)
		break;
	    AttributeValue val = new AttributeValue(form, diep,
						    addrlen, strtab);
	    attrs[at] = val;
	}
	if (hasChildren) {
	    char* p = diep;
	    while ((abbrevCode = parseULEB128(diep)) != 0) {
		DIE die = new DIE(cu, base, diep,
				  abbrevCode, abbrevTable,
				  addrlen, strtab);

		cu.dieMap[p - base] = die;
		children ~= die;
		p = diep;
	    }
	}
    }

    AttributeValue opIndex(int at)
    {
	try {
	    return attrs[at];
	} catch (Exception e) {
	    return null;
	}
    }

    bool contains(ulong pc)
    {
	if (addresses.length) {
	    for (int i = 0; i < addresses.length; i++)
		if (addresses[i].contains(pc))
		    return true;
	} else {
	    if (this[DW_AT_low_pc]
		&& this[DW_AT_high_pc]) {
		addresses ~= AddressRange(this[DW_AT_low_pc].ul,
					  this[DW_AT_high_pc].ul);
	    } else if (this[DW_AT_ranges]) {
		char[] ranges = top.debugSection(".debug_ranges");
		char* p = &ranges[this[DW_AT_ranges].ul];
		for (;;) {
		    ulong start, end;
		    start = parseOffset(p, is64);
		    end = parseOffset(p, is64);
		    if (start == 0 && end == 0)
			break;
		    addresses ~= AddressRange(start, end);
		}
	    } else {
		throw new Exception(
		    "DIE has no address range info");
	    }

	    // Now that we have parsed the DIE's location, try again
	    return contains(pc);
	}
    }

    void printIndent(int indent)
    {
	for (int i = 0; i < indent; i++)
	    writef(" ");
    }

    void print(int indent)
    {
	printIndent(indent);
	writefln("%s", tagNames[tag]);
	foreach (at, val; attrs) {
	    printIndent(indent + 1);
	    writef("%s = ", attrNames[at]);
	    val.print();
	}
	if (hasChildren) {
	    foreach (kid; children)
		kid.print(indent + 2);
	}
    }
}


class CompilationUnit
{
    this(DwarfFile df)
    {
	parent = df;
    }

    bool contains(ulong pc)
    {
	if (addresses.length) {
	    for (int i = 0; i < addresses.length; i++)
		if (addresses[i].contains(pc))
		    return true;
	    return false;
	} else {
	    // Load the DIE if necessary and check its attributes
	    assert(die is null);
	    loadDIE();
	    addresses = die.addresses;

	    // Now that we have loaded the DIE, try again
	    return contains(pc);
	}
    }

    void loadDIE()
    {
	if (!die) {
	    char[] info = parent.debugSection(".debug_info");
	    char* p = &info[offset];
	    parent.parseCompilationUnit(this, p);
	    if (!die)
		throw new Exception(
		    "Can't load DIE for compilation unit");
	}
    }

    DIE findSubprogram(ulong pc)
    {
	foreach (kid; die.children)
	    if (kid.tag == DW_TAG_subprogram && kid.contains(pc))
		return kid;
	return null;
    }

    DwarfFile parent;
    ulong offset;		// Offset in .debug_info
    bool is64;		// CU uses 64bit dwarf
    uint addressSize;	// size in bytes of an address
    uint segmentSize;	// size in bytes of a segment
    AddressRange[] addresses; // set of address ranges for this CU
    DIE die;		// top-level DIE for this CU
    DIE[ulong] dieMap;	// map DIE offset to loaded DIE
}

class CIE
{
    uint codeAlign;
    int dataAlign;
    uint returnAddress;
    char* instructionStart;
    char* instructionEnd;
}

class FDE
{
    bool is64;
    CIE cie;
    ulong initialLocation;
    ulong addressRange;
    char* instructionStart;
    char* instructionEnd;

    struct RLoc {
	enum Rule {
	    undefined,
	    sameValue,
	    offsetN,
	    valOffsetN,
	    registerR,
	    expressionE,
	    valExpressionE,
	}
	Rule rule;
	union {
	    long N;
	    uint R;
	    struct block {
		char* start;
		char* end;
	    }
	    block E;
	}
    }
    struct FrameState {
	void clear(FDE fde, uint numRegs)
	{
	    regs.length = numRegs;
	    foreach (rloc; regs) {
		rloc.rule = RLoc.Rule.undefined;
	    }
	    loc = fde.initialLocation;
	}

	RLoc regs[];
	ulong loc;
	uint cfaReg;
	long cfaOffset;
    }

    bool contains(ulong pc)
    {
	return pc >= initialLocation && pc < initialLocation + addressRange;
    }

    MachineState unwind(MachineState state)
    {
	FrameState cieFs, fdeFs;

	cieFs.clear(this, state.grCount);
	fdeFs.clear(this, state.grCount);

	void execute(char* p, char* pEnd, ulong pc, ref FrameState fs)
	{
	    uint reg;

	    while (p < pEnd) {
		auto op = *p++;
		switch ((op & 0xc0) ? (op & 0xc0) : op) {
		case DW_CFA_set_loc:
		    fs.loc = parseOffset(p, is64);
		    break;

		case DW_CFA_advance_loc:
		    fs.loc += (op & 0x3f) * cie.codeAlign;
		    break;

		case DW_CFA_advance_loc1:
		    fs.loc += parseUByte(p) * cie.codeAlign;
		    break;

		case DW_CFA_advance_loc2:
		    fs.loc += parseUShort(p) * cie.codeAlign;
		    break;

		case DW_CFA_advance_loc4:
		    fs.loc += parseUInt(p) * cie.codeAlign;
		    break;

		case DW_CFA_def_cfa:
		    fs.cfaReg = parseULEB128(p);
		    fs.cfaOffset = parseULEB128(p);
		    break;

		case DW_CFA_def_cfa_sf:
		    fs.cfaReg = parseULEB128(p);
		    fs.cfaOffset = parseSLEB128(p) * cie.dataAlign;
		    break;

		case DW_CFA_def_cfa_register:
		    fs.cfaReg = parseULEB128(p);
		    break;

		case DW_CFA_def_cfa_offset:
		    fs.cfaOffset = parseULEB128(p);
		    break;

		case DW_CFA_def_cfa_offset_sf:
		    fs.cfaOffset = parseSLEB128(p) * cie.dataAlign;
		    break;

		case DW_CFA_def_cfa_expression:
		    throw new Exception("no support for CFA expressions");

		case DW_CFA_undefined:
		    fs.regs[parseULEB128(p)].rule = RLoc.Rule.undefined;
		    break;

		case DW_CFA_same_value:
		    fs.regs[parseULEB128(p)].rule = RLoc.Rule.sameValue;
		    break;

		case DW_CFA_offset:
		    reg= op & 0x3f;
		    fs.regs[reg].rule = RLoc.Rule.offsetN;
		    fs.regs[reg].N = parseULEB128(p) * cie.dataAlign;
		    break;
			
		case DW_CFA_offset_extended:
		    reg = parseULEB128(p);
		    fs.regs[reg].rule = RLoc.Rule.offsetN;
		    fs.regs[reg].N = parseULEB128(p) * cie.dataAlign;
		    break;

		case DW_CFA_offset_extended_sf:
		    reg = parseULEB128(p);
		    fs.regs[reg].rule = RLoc.Rule.offsetN;
		    fs.regs[reg].N = parseSLEB128(p) * cie.dataAlign;
		    break;

		case DW_CFA_val_offset:
		    reg = parseULEB128(p);
		    fs.regs[reg].rule = RLoc.Rule.valOffsetN;
		    fs.regs[reg].N = parseULEB128(p) * cie.dataAlign;
		    break;

		case DW_CFA_register:
		    reg = parseULEB128(p);
		    fs.regs[reg] = fs.regs[parseULEB128(p)];
		    break;

		case DW_CFA_expression:
		    throw new Exception("no support for CFA expressions");

		case DW_CFA_val_expression:
		    throw new Exception("no support for CFA expressions");

		case DW_CFA_restore:
		    reg = op & 0x3f;
		    fs.regs[reg] = cieFs.regs[op & 0x3f];
		    break;

		case DW_CFA_restore_extended:
		    reg = parseULEB128(p);
		    fs.regs[reg] = cieFs.regs[op & 0x3f];

		case DW_CFA_remember_state:
		case DW_CFA_restore_state:
		    throw new Exception("no support for frame state stacks");

		case DW_CFA_nop:
		    break;
		}
		// If we have advanced past the PC, stop
		if (pc < fs.loc)
		    return;
	    }
	}

	auto pc = state.getGR(state.pcregno);
	execute(cie.instructionStart, cie.instructionEnd, pc, cieFs);

	fdeFs = cieFs;
	execute(instructionStart, instructionEnd, pc, fdeFs);

	if (fdeFs.regs[cie.returnAddress].rule == RLoc.Rule.undefined)
	    return null;
	MachineState newState = state.dup;
	ulong cfa = state.getGR(fdeFs.cfaReg) + fdeFs.cfaOffset;
	foreach (i, rl; fdeFs.regs) {
	    long off;
	    ubyte[] b;
	    switch (rl.rule) {
	    case RLoc.Rule.undefined:
	    case RLoc.Rule.sameValue:
		break;

	    case RLoc.Rule.offsetN:
		off = rl.N;
		b = state.readMemory(cfa + off, is64 ? 8 : 4);
		// XXX endian
		if (is64)
		    newState.setGR(i, *cast(ulong*) &b[0]);
		else
		    newState.setGR(i, *cast(uint*) &b[0]);
		break;

	    case RLoc.Rule.valOffsetN:
		off = rl.N;
		newState.setGR(i, cfa + off);
		break;
		    
	    case RLoc.Rule.registerR:
		newState.setGR(i, state.getGR(rl.R));
		break;

	    case RLoc.Rule.expressionE:
	    case RLoc.Rule.valExpressionE:
		throw new Exception("no support for frame state stacks");
	    }
	}
	return newState;
    }
}