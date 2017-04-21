# Visual C++ & Intel(R) NMakefile for PDCurses library - Win32 VC++ 2.0+
#
# Usage: nmake -f [path\]vcwin32.mak [DEBUG=] [DLL=] [WIDE=] [UTF8=]
#           [ICC=] [CHTYPE_32=] [IX86=] [CHTYPE_16=] [target]
#
# where target can be any of:
# [all|demos|pdcurses.lib|testcurs.exe...]
#  CHTYPE_## is used to override the default 64-bit chtypes in favor
#  of "traditional" 32- or 16-bit chtypes.
#  IX86 is used to build 32-bit code instead of 64-bit
#  ICC is used to invoke Intel (R) tools icl.exe and xilink.exe,  instead of
#    MS tools cl.exe and link.exe

O = obj

!ifndef PDCURSES_SRCDIR
PDCURSES_SRCDIR = ..
!endif

!ifdef DEBUG
OUTDIR 	= Debug
!else
OUTDIR 	= Release
!endif

OBJDIR	= Obj\$(OUTDIR)

!include $(PDCURSES_SRCDIR)\version.mif
!include $(PDCURSES_SRCDIR)\libobjs.mif

osdir      = $(PDCURSES_SRCDIR)\win32a

PDCURSES_WIN_H   = $(osdir)\pdcwin.h

!ifdef ICC
CC      = icl.exe -nologo
LINK    = xilink.exe -nologo
!else
CC      = cl.exe -nologo
LINK    = link.exe -nologo
!endif

!ifdef DEBUG
CFLAGS       = -Zi -DPDCDEBUG -MDd -D_CRT_SECURE_NO_WARNINGS
LDFLAGS      = -debug -pdb:$(OUTDIR)\pdcurses.pdb
!else
CFLAGS       = -Ox -MD -W3 -D_CRT_SECURE_NO_WARNINGS
LDFLAGS      =
!endif

BASEDEF      = $(PDCURSES_SRCDIR)\exp-base.def
WIDEDEF      = $(PDCURSES_SRCDIR)\exp-wide.def

DEFDEPS      = $(BASEDEF)

!ifdef WIDE
WIDEOPT      = -DPDC_WIDE
DEFDEPS      = $(DEFDEPS) $(WIDEDEF)
DEFFILE      = $(OUTDIR)\pdcursew.def
!else
DEFFILE      = $(OUTDIR)\pdcurses.def
!endif

!ifdef UTF8
UTF8OPT      = -DPDC_FORCE_UTF8
!endif

!ifdef CHTYPE_32
CHTYPE_FLAGS= -DCHTYPE_32
!endif

!ifdef CHTYPE_16
CHTYPE_FLAGS= -DCHTYPE_16
!endif

CCLIBS      = user32.lib gdi32.lib advapi32.lib shell32.lib comdlg32.lib
# may need to add msvcrt.lib for VC 2.x, VC 5.0 doesn't want it
#CCLIBS      = msvcrt.lib user32.lib gdi32.lib advapi32.lib comdlg32.lib

LIBEXE      = lib -nologo

LIBCURSES   = $(OUTDIR)\pdcurses.lib
CURSESDLL   = $(OUTDIR)\pdcurses.dll

!ifdef DLL
DLLOPT      = -DPDC_DLL_BUILD
PDCLIBS     = $(CURSESDLL)
!else
PDCLIBS     = $(LIBCURSES)
!endif

SHL_LD 		= link $(LDFLAGS) /NOLOGO /DLL /OUT:$(CURSESDLL) /DEF:$(DEFFILE)

BUILD      	= $(CC) -Fo$(OBJDIR)\ -Fd$(OBJDIR)\ -I$(PDCURSES_SRCDIR) -c $(CFLAGS) $(CHTYPE_FLAGS) $(DLLOPT) \
$(WIDEOPT) $(UTF8OPT)

all: $(PDCLIBS) $(DEMOS)
clean:
   -rmdir /s /q $(OUTDIR)
   -rmdir /s /q $(OBJDIR)

$(LIBOBJS) $(PDCOBJS) : $(PDCURSES_HEADERS) $(OUTDIR) $(OBJDIR) 
$(PDCOBJS) : $(PDCURSES_WIN_H)
$(DEMOOBJS) : $(PDCURSES_CURSES_H)
$(DEMOS) : $(LIBCURSES)
panel.obj : $(PANEL_HEADER)
terminfo.obj: $(TERM_HEADER)


$(OUTDIR) : 
	@IF NOT EXIST $(OUTDIR) ( mkdir $(OUTDIR) )

$(OBJDIR) :
	@IF NOT EXIST $(OBJDIR) ( mkdir $(OBJDIR) )

!ifndef DLL
$(LIBCURSES) : $(LIBOBJS) $(PDCOBJS)
	$(LIBEXE) /OUT:$@ $(LIBOBJS) $(PDCOBJS)
!endif

$(DEFFILE) : $(DEFDEPS)
   echo LIBRARY pdcurses > $(DEFFILE)
   echo EXPORTS >> $(DEFFILE)
   type $(BASEDEF) >> $(DEFFILE)
!ifdef WIDE
   type $(WIDEDEF) >> $(DEFFILE)
!endif

$(CURSESDLL) : $(LIBOBJS) $(PDCOBJS) $(DEFFILE) $(OBJDIR)\pdcurses.obj
   $(SHL_LD) $(LIBOBJS) $(PDCOBJS) $(OBJDIR)\pdcurses.obj $(CCLIBS)

pdcurses.res $(OBJDIR)\pdcurses.obj: $(osdir)\pdcurses.rc $(osdir)\pdcurses.ico
   rc /r /fopdcurses.res $(osdir)\pdcurses.rc
!ifdef IX86
   cvtres /MACHINE:IX86 /NOLOGO /OUT:$(OBJDIR)\pdcurses.obj pdcurses.res
!else
   cvtres /MACHINE:X64 /NOLOGO /OUT:$(OBJDIR)\pdcurses.obj pdcurses.res
!endif

{$(srcdir)\}.c{$(OBJDIR)\}.obj::
	$(BUILD) $<

{$(osdir)\}.c{$(OBJDIR)\}.obj::	
	$(BUILD) $<

{$(demodir)\}.c{$(OBJDIR)\}.obj::
	$(BUILD) $<

{$(OBJDIR)\}.obj{$(OUTDIR)\}.exe:
   	$(LINK) $(LDFLAGS) /OUT:$(OUTDIR)\$(@F) $< $(LIBCURSES) $(CCLIBS)

$(OUTDIR)\tuidemo.exe: $(OBJDIR)\tuidemo.obj $(OBJDIR)\tui.obj
	@echo tuidemo
	$(LINK) $(LDFLAGS) /OUT:$*.exe $** $(CCLIBS)

$(OBJDIR)\tui.obj: $(demodir)\tui.c $(demodir)\tui.h
	@echo tui.obj
	$(BUILD) -I$(demodir) $(demodir)\tui.c

$(OBJDIR)\tuidemo.obj: $(demodir)\tuidemo.c
	@echo tuidemo.obj
	$(BUILD) -I$(demodir) $(demodir)\tuidemo.c

PLATFORM1 = Visual C++
PLATFORM2 = Microsoft Visual C/C++ for Win32
ARCNAME = pdc$(VER)_vc_w32

!include $(PDCURSES_SRCDIR)\makedist.mif
