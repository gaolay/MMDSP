# MMDSP
multi music status display MMDSP

This program was named MMDSP (Multi Music status Displayer / Selector / Player).
It is a real time display & file selector that supports various music drivers that run on SHARP X68000.

MMDSP supports six types of music drivers: MXDRV, MADRV, MCDRV, RCD, MLD, and ZMUSIC.

You can enjoy functions such as semi-transparency of the background graphic screen (512 * 512 65536 color mode), partial transparency (by GVRAM bit0), and so on.

MMDSP has continuous playback function.
You can enjoy auto / random / simple program play easily without creating any data files.

You can reside and call it at any time with XF4 + XF5 key. (Specified on the command line)

MMDSP is characterized by a realistic movement spectrum analyzer, but when you play PCM8 compatible data on a 10 MHz model, the operation may be slightly heavy depending on the data.

<img src="https://user-images.githubusercontent.com/320167/27649690-79370cc2-5c6d-11e7-8b16-0b612150564f.png">
<a href="https://www.youtube.com/results?search_query=MMDSP">Also, there are some MMDSP videos on Youtube.</a>

# How to build

## 1. Please configure makefile according to your environment.

    AS	= a:/usr/asm/as.x
    ASFLAGS	= -w -u
    LD	= a:/usr/asm/lk.x

## 2.make

    A:\> make
