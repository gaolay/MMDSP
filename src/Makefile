#----------------------------------------
#	設定
#----------------------------------------

AS	= a:/usr/asm/as.x
#AS	= as.x
ASFLAGS	= -w -u
LD	= a:/usr/asm/lk.x
#LD	= lk.x
LDFLAGS =

#----------------------------------------
#	生成規則
#----------------------------------------

.SUFFIXES :
.SUFFIXES : .s .o .x .r

.s.o:
	$(AS) $(ASFLAGS) $<

.x.r:
	-cv $<

#----------------------------------------
#	ファイル指定
#----------------------------------------

EXEC	= MMDSP.x

OBJS	= MMDSP.o INIT.o MOUSE.o PANEL.o CONTROL.o \
	_LEVEL.o _SELECTOR.o _SPEANA.o _SYSDISP.o _KEYBORD.o MAIN.o \
	BG.o FONT.o SPRITE.o TEXT.o FILES.o DOCVIEW.o \
	DRIVER.o MXCTRL.o MACTRL.o RCDCTRL.o RCDCTRL3.o MLDCTRL.o ZMCTRL.o MCCTRL.o

#----------------------------------------
#	実行ファイル制作
#----------------------------------------

all:	$(EXEC:.x=.r)

$(EXEC):	$(OBJS)
	$(LD) -o $(EXEC) $(OBJS)

MMDSP.o:	MMDSP.h
INIT.o:		MMDSP.h DRIVER.h KEYCODE.mac
MAIN.o:		MMDSP.h DRIVER.h
MOUSE.o:	MMDSP.h
PANEL.o:	MMDSP.h CONTROL.h
CONTROL.o:	MMDSP.h CONTROL.h DRIVER.h SELECTOR.h KEYCODE.mac

BG.o:		MMDSP.h
FONT.o:		MMDSP.h
SPRITE.o:	MMDSP.h
TEXT.o:		MMDSP.h
DOCVIEW.o:	MMDSP.h

_KEYBORD.o:	MMDSP.h
_LEVEL.o:	MMDSP.h
_REGISTER.o:	MMDSP.h
_SELECTOR.o:	MMDSP.h SELECTOR.h DRIVER.h FILES.h
_SPEANA.o:	MMDSP.h
_SYSDISP.o:	MMDSP.h DRIVER.h

DRIVER.o:	MMDSP.h DRIVER.h
FILES.o:	MMDSP.h DRIVER.h FILES.h
MXCTRL.o:	MMDSP.h DRIVER.h
MACTRL.o:	MMDSP.h DRIVER.h
RCDCTRL.o:	MMDSP.h DRIVER.h
RCDCTRL3.o:	MMDSP.h DRIVER.h RCDDEF300.mac
MLDCTRL.o:	MMDSP.h DRIVER.h
ZMCTRL.o:	MMDSP.h DRIVER.h ZMLABEL.h
MCCTRL.o:	MMDSP.h DRIVER.h

