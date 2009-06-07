/*-
 * Copyright (c) 2007 Doug Rabson
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

import target;
import libdwarf.libdwarf;
import std.string;
import std.stdint;
import std.stdio;
import std.c.unix.unix;

import target;

private extern (C) void dwarfErrorThunk(Dwarf_Error err,
					Dwarf_Ptr priv)
{
    DwarfModule dwmod = cast(DwarfModule) priv;
    dwmod.dwarfError(err);
}

class DwarfModule: TargetModule
{
    this(TargetModule mod)
    {
	int fd;

	mod_ = mod;
	fd = open(toStringz(mod.filename), O_RDONLY);
	if (fd > 0) {
	    int err = dwarf_init(fd,
				 DW_DLC_READ,
				 cast(Dwarf_Handler) &dwarfErrorThunk,
				 cast(void*) this,
				 &dwarf_,
				 null);
	    if (err) {
		writefln("can't load dwarf symbols for %s", mod.filename);
	    }
	}
    }

    void dwarfError(Dwarf_Error err)
    {
    }

    override {
	char[] filename()
	{
	    return mod_.filename;
	}
	uintptr_t start()
	{
	    return mod_.start;
	}
	uintptr_t end()
	{
	    return mod_.end;
	}
    }

private:
    TargetModule mod_;
    Dwarf_Debug dwarf_;
}
