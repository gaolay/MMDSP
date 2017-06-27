*************************************************************************
*									*
*									*
*	    Ｘ６８０００　ＭＸＤＲＶ／ＭＡＤＲＶディスプレイ		*
*									*
*				ＭＭＤＳＰ				*
*									*
*									*
*	Copyright (C) 1991,1992 Kyo Mikami.  All Rights Reserved.	*
*									*
*	Modified Masao Takahashi					*
*									*
*************************************************************************


		.include	iocscall.mac
		.include	doscall.mac
		.include	MMDSP.h
		.include	DRIVER.h

			.text
			.even

*
*	＊ＳＹＳＤＩＳ＿ＭＡＫＥ
*機能：システムディスプレイ（？）画面を作る
*入出力：なし
*参考：
*

SYSDIS_MAKE:
		movem.l	d0-d1/a0-a2,-(sp)

		moveq	#2,d0				*ＭＭＤＳＰの文字
		move.l	#13*$10000+7,d1
		lea	TITLE(pc),a0
		movea.l	#TXTADR+28+1*$80,a1
		bsr	PUT_PATTERN

		moveq	#2,d0
		bsr	TEXT_ACCESS_ON

		movea.l	#$E00CB6,a0			*棒を書く
		bsr	put_bar
		movea.l	#$E018b6,a0
		bsr	put_bar
		movea.l	#$E024B6,a0
		bsr	put_bar
		movea.l	#$E030B6,a0
		bsr	put_bar
		movea.l	#TXTADR+29+97*$80,a0
		bsr	put_bar
		movea.l	#TXTADR+42+97*$80,a0
		bsr	put_bar

		bsr	TEXT_ACCESS_OF			*アクセスモード戻す

		lea.l	TMOJI(pc),a0
		bsr	TEXT48AUTO

		movea.l	#BGADR+0*2+42*$80,a0
		move.w	#$170,d0
		moveq.l	#5,d1
		bsr	BG_LINE

		lea.l	$C(a0),a0
		move.w	#$171,d0
		moveq.l	#57,d1
		bsr	BG_LINE

		move.w	DRV_MODE(a6),d0			*ドライバ名
		subq.w	#1,d0
		mulu	#5*8,d0
		lea	LOGO_MXDRV(pc),a0
		lea	(a0,d0.w),a0
		move.l	#$00010002,d0
		movea.l	#TXTADR+32+55*$80,a1
		move.l	#$0007_0004,d1
		bsr	PUT_PATTERN
.if 0
		movea.l	#BGADR+61*2+9*$80,a0		*テンポ
		moveq	#3,d1
		moveq	#0,d0
		bsr	DIGIT10
		clr.w	TEMPOCHK(a6)

		movea.l	#BGADR+60*2+12*$80,a0		*ループカウンタ
		move.l	#$02360236,(a0)
		move.l	#$023F023F,$80(a0)
		move.l	#$02360236,4(a0)
		move.l	#$023F023F,$84(a0)
		move.w	#-1,LOOPCHK(a6)
.endif

		movea.l	#BGADR+61*2+6*$80,a0		*経過時間のコロン
		move.w	#$0228,(a0)
		move.w	#$0229,$80(a0)

		movea.l	#BGADR+36*2+1*$80,a0		*下線1をひく
		move.w	#$026E,d0
		moveq	#27,d1
		bsr	BG_LINE

		movea.l	#BGADR+29*2+14*$80,a0		*下線2をひく
		move.w	#$026E,d0
		moveq	#34,d1
		bsr	BG_LINE

		moveq	#31,d1				*グラフィックトーン設定
		bsr	GTONE_SET

		move.b	GRAPH_MODE(a6),d1		*グラフィックモード設定
		bsr	SET_GMODE

		MYONTIME
		move.w	d0,SYS_ONTIME(a6)
		move.w	d0,CLKLAMP(a6)
		clr.w	CYCLECNT(a6)
		clr.w	SYS_TIME(a6)
		move.w	SYS_TEMPO(a6),d0
		not.w	d0
		move.w	d0,TEMPOCHK(a6)
		move.w	SYS_LOOP(a6),d0
		not.w	d0
		move.w	d0,LOOPCHK(a6)

		movem.l	(sp)+,d0-d1/a0-a2
		rts

put_bar:
		move.b	#$70,d0
		moveq	#14-1,d1
put_bar1:
		move.b	d0,(a0)
		lea	$80(a0),a0
		dbra	d1,put_bar1
		rts

*
*	＊ＳＹＳＴＥＭ＿ＤＩＳＰ
*機能：システムディスプレイ表示
*入出力：なし
*参考：曲タイトル，インフォーメーション，時計など
*
SYSTEM_DISP:
		movem.l	d0-d2/a0-a1,-(sp)
		clr.w	STAT_OK(a6)

		addq.w	#1,CYCLECNT(a6)			*一定時間のカウント数を表示
		MYONTIME
		move.w	d0,d2
		sub.w	SYS_ONTIME(a6),d0
		cmp.w	CYCLETIM(a6),d0
		bcs	sys_disp10
		add.w	d0,SYS_ONTIME(a6)
		move.w	CYCLECNT(a6),d0
		lsr.w	#3,d0
		movea.l	#BGADR+12*$80+36*2,a0
		moveq	#3,d1
		bsr	DIGIT10
		clr.w	CYCLECNT(a6)

sys_disp10:
		move.w	d2,d0
		sub.w	CLKLAMP(a6),d0
		cmp.w	#50,d0
		bcs	sys_disp11

		movea.l	#BGADR+61*2+3*$80,a1		*時刻のコロン点滅
		move.w	#$022A,(a1)
		move.w	#$022B,$80(a1)

		move.w	d2,CLKLAMP(a6)

sys_disp11:
		IOCS	_TIMEGET			*現在時間表示
		cmp.w	SYS_TIME(a6),d0
		beq	sys_disp90			*すべての表示は１秒おきに行う

		move.w	d2,CLKLAMP(a6)

		movea.l	#BGADR+59*2+3*$80,a1		*時刻のコロン点滅
		move.w	#$0228,$04(a1)
		move.w	#$0229,$84(a1)

		move.w	d0,SYS_TIME(a6)
		move.l	d0,d2

		moveq	#2,d1				*分表示
		move.l	d2,d0
		lsr.w	#8,d0
		lea	6(a1),a0
		bsr	DIGIT16

		move.l	d2,d0				*時間表示
		swap.w	d0
		movea.l	a1,a0
		bsr	DIGIT16

sys_disp20:
		DRIVER	DRIVER_SYSSTAT
		move.w	#-1,STAT_OK(a6)

		move.l	SYS_TITLE(a6),a0		*曲タイトルを比較
		lea.l	MDXCHCK(a6),a1
		move.w	TITLELEN(a6),d1
		subq.w	#1,d1

sys_titlechk:	move.b	(a0)+,d0
		beq	sys_titlechk1
		cmp.b	(a1)+,d0
		dbne	d1,sys_titlechk
		beq	sys_disp30
		bra	sys_titlecpy
sys_titlechk1:	tst.b	(a1)
		beq	sys_disp30

sys_titlecpy:
		move.l	SYS_TITLE(a6),a0		*違ったらバッファにコピー
		lea.l	MDXCHCK(a6),a1
		move.w	TITLELEN(a6),d1
		subq.w	#1,d1

sys_titlecpy1:	move.b	(a0)+,(a1)+
		dbeq	d1,sys_titlecpy1
		clr.b	(a1)

		lea.l	MDXCHCK(a6),a0			*コントロールコードを抜く
		lea.l	MDXTITLE(a6),a1
		moveq.l	#77-1,d1
sys_titlecpy4:
		move.b	(a0)+,d0
		beq	sys_titlecpy5
		cmpi.b	#$0d,d0
		beq	sys_titlecpy5
		cmpi.b	#' ',d0
		bcc	sys_tcpy_jp1
		moveq.l	#' ',d0
sys_tcpy_jp1:	move.b	d0,(a1)+
		dbra	d1,sys_titlecpy4
		bra	sys_tcpy_jp2
sys_titlecpy5:
		move.b	#' ',(a1)+
		dbra	d1,sys_titlecpy5
sys_tcpy_jp2:
		clr.b	(a1)

		moveq.l	#3,d0
		moveq.l	#0,d1
		lea.l	MDXTITLE(a6),a0
		movea.l	#TXTADR+6+324*$80,a1
		bsr	TEXT_6_16

		bsr	CLEAR_PASSTM			*経過時間クリア

sys_disp30:
		move.w	SYS_TEMPO(a6),d0		*TIMER-B CYCLE 表示
		cmp.w	TEMPOCHK(a6),d0
		beq	sys_disp40
		move.w	d0,TEMPOCHK(a6)
		movea.l	#BGADR+61*2+9*$80,a0
		moveq	#3,d1
		bsr	DIGIT10
sys_disp40:
		move.w	SYS_LOOP(a6),d0			*ループカウンタ表示
		cmp.w	LOOPCHK(a6),d0
		beq	sys_disp50
		move.w	d0,LOOPCHK(a6)
		movea.l	#BGADR+60*2+12*$80,a0
		cmpi.w	#9999,d0
		bhi	sys_disp41
		moveq	#4,d1
		bsr	DIGIT10
		bra	sys_disp50
sys_disp41:
		move.l	#$02360236,(a0)
		move.l	#$023F023F,$80(a0)
		move.l	#$02360236,4(a0)
		move.l	#$023F023F,$84(a0)

sys_disp50:
		move.w	BLANK(a6),d0			*ブランク中であれば
		ble	sys_disp55
		movea.l	#BGADR+59*2+6*$80,a0
		move.l	#$02360236,(a0)+		*空白表示
		move.l	#$023F023F,$80-4(a0)
		addq.l	#2,a0
		sub.w	BLANK_TIME(a6),d0		*ブランク残り時間表示
		neg.w	d0
		moveq	#2,d1
		bsr	DIGIT10
		bra	sys_disp59
sys_disp55:
		tst.w	PLAY_FLAG(a6)
		beq	sys_disp57
		move.w	SYS_PASSTM(a6),d0
		addq.w	#1,d0
		cmpi.w	#60*60,d0
		bcs	sys_disp56
		moveq	#0,d0
sys_disp56:
		move.w	d0,SYS_PASSTM(a6)
sys_disp57:
		moveq	#0,d0
		move.w	SYS_PASSTM(a6),d0		*経過時間表示
		bpl	sys_disp58
		moveq	#0,d0
sys_disp58:
		divu	#60,d0
		movea.l	#BGADR+59*2+6*$80,a0
		moveq	#2,d1
		bsr	DIGIT10
		lea	6(a0),a0
		swap	d0
		bsr	DIGIT10
sys_disp59:

sys_disp60:
		tst.w	PLAY_FLAG(a6)		*演奏状態表示
		sne	d1
		tst.w	PLAYEND_FLAG(a6)
		sne	d0
		andi.w	#$0001,d1		*0:PAUSE 1:PLAY 2:END 3:---
		andi.w	#$0002,d0
		or.w	d1,d0
		lsl.w	#4,d0
		lea	STATDIGIT0(pc,d0.w),a0
		move.w	#$0200,d0
		movea.l	#BGADR+47*2+12*$80,a1
		bsr	BG_PRINT
		addq.l	#8,a0
		lea	$80(a1),a1
		bsr	BG_PRINT

sys_disp90:
		movem.l	(sp)+,d0-d2/a0-a1
		rts


STATDIGIT0:	.dc.b	$30,$30,$33,$34,$34,0,0,0	*PAUSE
		.dc.b	$3e,$3d,$37,$3a,$39,0,0,0
STATDIGIT1:	.dc.b	$30,$35,$30,$33,$36,0,0,0	*PLAY
		.dc.b	$3e,$23,$3d,$3a,$3f,0,0,0
STATDIGIT2:	.dc.b	$36,$36,$36,$36,$36,0,0,0	*-----
		.dc.b	$3f,$3f,$3f,$3f,$3f,0,0,0
STATDIGIT3:	.dc.b	$36,$36,$36,$36,$36,0,0,0	*-----
		.dc.b	$3f,$3f,$3f,$3f,$3f,0,0,0
		.even


*==================================================
*経過時間のクリア
*==================================================

CLEAR_PASSTM:
		movem.l	d0-d1/a0,-(sp)
		move.w	#-1,SYS_PASSTM(a6)
		movea.l	#BGADR+59*2+6*$80,a0
		moveq	#0,d0
		moveq	#2,d1
		bsr	DIGIT10
		lea	6(a0),a0
		bsr	DIGIT10
		movem.l	(sp)+,d0-d1/a0
		rts


*==================================================
*グラフィック合成モード設定
*	d1.b <- graph mode(0-4)
*		0:グラフィックなし
*		1:重ね合せ
*		2:半透明
*		3:グラフィックセル
*		4:グラフィックのみ
*==================================================

SET_GMODE:
		movem.l	d0-d1/a0,-(sp)
		cmpi.b	#4,d1
		bhi	set_gmode90
		move.b	d1,GRAPH_MODE(a6)

		moveq	#0,d0
		move.w	d1,d0
		lsl.w	#2,d0				*レジスタにデータセット
		lea	graph_regdat(pc,d0.w),a0
		move.b	VIDEO_PRIO,d0
		andi.b	#$C0,d0
		or.w	(a0)+,d0
		move.b	d0,VIDEO_PRIO
		move.w	(a0)+,VIDEO_EFFECT

		move.w	#$210E,d0			*デジタル数字のパレット変更
		cmpi.b	#1,d1
		beq	set_gmode10
		cmpi.b	#4,d1
		bne	set_gmode11
set_gmode10:	moveq	#0,d0
set_gmode11:	move.w	d0,SPPALADR+2*32+2*2

set_gmode20:
		tst.b	GRAPH_MODE(a6)			*グラフィックなし以外のモードで
		beq	set_gmode29
		tst.w	GTONE(a6)			*グラフィックトーンが０なら
		bne	set_gmode29
		moveq	#16,d1				*ハーフトーンにする
		bsr	GTONE_SET
set_gmode29:

set_gmode90:
		movem.l	(sp)+,d0-d1/a0
		rts

graph_regdat:
		dc.w	%00000000_00010010,%00000000_01100000	*no graphic
		dc.w	%00000000_00010010,%00000000_01101111	*blight priority
*		dc.w	%00000000_00100100,%00011001_01101111	*half tone
		dc.w	%00000000_00100001,%00011001_01101111	*half tone(text prior)
		dc.w	%00000000_00100100,%00000000_01101111	*graphic cell
		dc.w	%00000000_00100100,%00000000_00001111	*graphic only
*		dc.w	%00000000_00010010,%00011001_01101111	*dark priority


*==================================================
*グラフィックトーン変更
*==================================================

*グラフィックトーンアップ

GTONE_UP:
		move.l	d1,-(sp)
		move.w	GTONE(a6),d1
		addq.w	#1,d1
		bsr	GTONE_SET
		move.l	(sp)+,d1
		rts

*グラフィックトーンダウン

GTONE_DOWN:
		move.l	d1,-(sp)
		move.w	GTONE(a6),d1
		subq.w	#1,d1
		bsr	GTONE_SET
		move.l	(sp)+,d1
		rts

*グラフィックトーン設定
*	d1.w <- トーン(0-31)

GTONE_SET:
		movem.l	d0-d1/a0-a1,-(sp)
		cmpi.w	#31,d1
		bhi	gtone_set90
		move.w	d1,GTONE(a6)
		movea.l	GTONE_TBL(a6),a0
		lsl.w	#8,d1
		add.w	d1,d1
		lea	(a0,d1.w),a0
		movea.l	#GPALADR,a1
		moveq	#16-1,d0
gtone_set10:
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		dbra	d0,gtone_set10
gtone_set90:
		movem.l	(sp)+,d0-d1/a0-a1
		rts


*==================================================
*グラフィックスクロール
*==================================================

GHOME:
		clr.l	GSCROL_X(a6)
		bra	gscrol

GMOVE_U:
		move.w	GSCROL_Y(a6),d0
		subq.w	#8,d0
		cmpi.w	#1023,d0
		bls	gmove_u10
		move.w	#1023,d0
gmove_u10:
		move.w	d0,GSCROL_Y(a6)
		bra	gscrol

GMOVE_D:
		move.w	GSCROL_Y(a6),d0
		addq.w	#8,d0
		cmpi.w	#1023,d0
		bls	gmove_d10
		clr.w	d0
gmove_d10:
		move.w	d0,GSCROL_Y(a6)
		bra	gscrol

GMOVE_L:
		move.w	GSCROL_X(a6),d0
		subq.w	#8,d0
		cmpi.w	#1023,d0
		bls	gmove_l10
		move.w	#1023,d0
gmove_l10:
		move.w	d0,GSCROL_X(a6)
		bra	gscrol

GMOVE_R:
		move.w	GSCROL_X(a6),d0
		addq.w	#8,d0
		cmpi.w	#1023,d0
		bls	gmove_r10
		clr.w	d0
gmove_r10:
		move.w	d0,GSCROL_X(a6)
*		bra	gscrol

gscrol:
		movem.l	d0/a0,-(sp)
		movea.l	#CRTC_GSCRL,a0
		move.l	GSCROL_X(a6),d0
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		movem.l	(sp)+,d0/a0
		rts


*==================================================
*ＢＧパターン選択
*	d1.w <- パターン番号(0-4)
*==================================================

BG_SEL:
		movem.l	d0-d1/a0,-(sp)
		moveq	#0,d0
		subq.w	#1,d1
		bmi	bg_sel10
		addi.w	#$0224,d1
		move.w	d1,d0
		swap	d0
		move.w	d1,d0
bg_sel10
		movea.l	#BGADR2,a0
		move.w	#64*62/8-1,d1
bg_sel20:
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		dbra	d1,bg_sel20

		move.l	#BGADR2+32*2+20*$80,a0	*スペアナと
		bsr	bgclr_spot
		move.l	#BGADR2+32*2+29*$80,a0	*レベルメータの部分はＢＧを抜く
		bsr	bgclr_spot
		movem.l	(sp)+,d0-d1/a0
		rts

bgclr_spot:
		moveq	#0,d0
		moveq	#7-1,d1
bgclr_spot10:
		swap	d1
		move.w	#4-1,d1
bgclr_spot20:
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		dbra	d1,bgclr_spot20
		lea	32*2(a0),a0
		swap	d1
		dbra	d1,bgclr_spot10
		rts


.if	0	*泣く泣く削除する(:_;)

*==================================================
*パレットアニメ
*==================================================

PALET_ANIM:
		tst.w	PLAY_FLAG(a6)
		beq	palet_anim90
		movem.l	d0-d1/a0,-(sp)
		lea	palet_wait(pc),a0
		subq.w	#1,(a0)
		bcc	palet_anim80
		move.w	#1,(a0)
		movea.l	#SPPALADR+$A*32+30,a0
		move.l	-(a0),2(a0)
		move.l	-(a0),2(a0)
		move.l	-(a0),2(a0)
		move.l	-(a0),2(a0)
		move.l	-(a0),2(a0)
		move.l	-(a0),2(a0)
		move.l	-(a0),2(a0)
		move.w	palet_cnt(pc),d0
		move.w	palet_tbl(pc,d0.w),(a0)
		addq.w	#2,d0
		move.w	palet_tbl(pc,d0.w),d1
		bne	palet_anim10
		moveq	#0,d0
palet_anim10:
		lea	palet_cnt(pc),a0
		move.w	d0,(a0)
palet_anim80:
		movem.l	(sp)+,d0-d1/a0
palet_anim90:
		rts

palet_cnt:	.dc.w	0
palet_wait:	.dc.w	1

RGB_COL:	.macro	R1,G1,B1,dm1,R2,G2,B2,dm2,R3,G3,B3,dm3,R4,G4,B4
		.dc.w	B1*2+R1*64+G1*2048
		.dc.w	B2*2+R2*64+G2*2048
		.dc.w	B3*2+R3*64+G3*2048
		.dc.w	B4*2+R4*64+G4*2048
		.endm

palet_tbl:
*		RGB_COL	31,31,31,__,30,30,30,__,29,29,29,__,28,28,28
*		RGB_COL	27,27,27,__,26,26,26,__,25,25,25,__,24,24,24
*		RGB_COL	23,23,23,__,22,22,22,__,21,21,21,__,19,19,19
*		RGB_COL	17,17,17,__,15,15,15,__,13,13,13,__,00,00,00

		RGB_COL	01,01,01,__,02,02,02,__,03,03,03,__,04,04,04
		RGB_COL	05,05,05,__,06,06,06,__,07,07,07,__,08,08,08
		RGB_COL	09,09,09,__,10,10,10,__,11,11,11,__,12,12,12
		RGB_COL	13,13,13,__,14,14,14,__,15,15,15,__,16,16,16
		RGB_COL	17,17,17,__,18,18,18,__,19,19,19,__,20,20,20
		RGB_COL	21,21,21,__,22,22,22,__,23,23,23,__,24,24,24
		RGB_COL	25,25,25,__,26,26,26,__,27,27,27,__,28,28,28
		RGB_COL	29,29,29,__,30,30,30,__,31,31,31,__,30,30,30
		RGB_COL	29,29,29,__,28,28,28,__,27,27,27,__,26,26,26
		RGB_COL	25,25,25,__,24,24,24,__,23,23,23,__,22,22,22
		RGB_COL	21,21,21,__,20,20,20,__,19,19,19,__,18,18,18
		RGB_COL	17,17,17,__,16,16,16,__,15,15,15,__,14,14,14
		RGB_COL	13,13,13,__,12,12,12,__,11,11,11,__,10,10,10
		RGB_COL	09,09,09,__,08,08,08,__,07,07,07,__,06,06,06
		RGB_COL	05,05,05,__,04,04,04,__,03,03,03,__,02,02,02
		RGB_COL	01,01,01,__,01,01,01,__,01,01,01,__,01,01,01
		RGB_COL	01,01,01,__,01,01,01,__,01,01,01,__,01,01,01
		RGB_COL	01,01,01,__,01,01,01,__,01,01,01,__,01,01,01
		RGB_COL	01,01,01,__,01,01,01,__,01,01,01,__,01,01,01
		RGB_COL	01,01,01,__,01,01,01,__,01,01,01,__,00,00,00

.endif


			.data
			.even

*			AC,詰,ＸＸ,ＹＹ,文字
TMOJI:		.dc.b	01,00,36,0,0,00,'Version'
		VERSION
		.dc.b	' COPYRIGHT 1991-94 MiahMie, Gao',0
		.dc.b	02,00,36,0,0,08,'SYNTHETIC DISPLAY for MXDRV/MADRV/RCD/MLD/Z',0
		.dc.b	02,00,57,6,0,08,'CONTROL PANEL',0
		.dc.b	01,00,29,1,0,56,'DRIVER:',0
		.dc.b	01,00,39,3,0,56,'GRAPHIC',0
*		.dc.b	02,00,43,1,0,56,'TONE',0
		.dc.b	01,00,29,1,0,80,'BACKGROUND PATTERN',0
		.dc.b	01,00,39,1,0,80,'NONE',0
		.dc.b	01,00,00,0,1,68,'NOW PLAYING',0
		.dc.b	01,00,00,1,1,76,' MUSIC DATA',$1C,0
		.dc.b	02,00,55,3,0,24,'DIGITAL',0
		.dc.b	02,00,55,7,0,32,'CLOCK',$7F,0
		.dc.b	02,00,55,3,0,48,'PASSED',0
		.dc.b	02,00,56,5,0,56,'TIME',$7F,0
		.dc.b	02,00,55,1,0,72,'TIMER-B',0
		.dc.b	02,00,55,7,0,80,'CYCLE',$7F,0
		.dc.b	02,00,56,3,0,96,'LOOP',0
		.dc.b	02,00,54,7,0,104,'COUNTER',$7F,0
		.dc.b	02,00,30,5,0,96,'CPU CYCLE',0
		.dc.b	02,00,30,0,0,104,'PERCENTAGE',$7F,0
		.dc.b	02,00,43,0,0,96,'DRIVER',0
		.dc.b	02,00,43,0,0,104,'STATUS',$7F,0
		.dc.b	0

		.dc.b	0

			.even

TITLE:	.dc.w	%0000001100001100,%0110000110011111,%1110000111111111,%0111111111000000
	.dc.w	%0000011110011110,%1111001111011111,%1111001111111111,%0111111111100000
	.dc.w	%0000011111111110,%1111111111011000,%0011001100000000,%0110000001100000
	.dc.w	%0000011011110110,%1101111011011000,%0001101100000000,%0110000001100000
	.dc.w	%0000011001100110,%1100110011011000,%0001101100000000,%0110000001100000
	.dc.w	%0000011000000110,%1100000011011000,%0001101111111110,%0110000001100000
	.dc.w	%0000011000000110,%1100000011011000,%0001100111111111,%0111111111100000
	.dc.w	%0000011000000110,%1100000011011000,%0001100000000011,%0111111111000000
	.dc.w	%0000011000000110,%1100000011011000,%0001100000000011,%0110000000000000
	.dc.w	%0000011000000110,%1100000011011000,%0011000000000011,%0110000000000000
	.dc.w	%0000011000000110,%1100000011011111,%1111001111111111,%0110000000000000
	.dc.w	%0000011000000110,%1100000011011111,%1110001111111110,%0110000000000000
	.dc.w	%0000000000000000,%0000000000000000,%0000000000000000,%0000000000000000
	.dc.w	%0000011111111111,%1111111111111111,%1111111111111111,%1111111111100000


LOGO_MXDRV:
	.dc.b	%00100000,%10100001,%01111100,%11111001,%00001000
	.dc.b	%00100000,%10010010,%01000010,%10000101,%00001000
	.dc.b	%00110001,%10010010,%01000010,%10000101,%00001000
	.dc.b	%00110001,%10001100,%01000010,%10000100,%10010000
	.dc.b	%00101010,%10001100,%01000010,%10111000,%10010000
	.dc.b	%00101010,%10010010,%01000010,%10000100,%10010000
	.dc.b	%00100100,%10010010,%01000010,%10000100,%01000000
	.dc.b	%00100100,%10100001,%01011100,%10000100,%01100000

LOGO_MADRV:
	.dc.b	%00100000,%10001100,%01111100,%11111001,%00001000
	.dc.b	%00100000,%10001100,%01000010,%10000101,%00001000
	.dc.b	%00110001,%10010010,%01000010,%10000101,%00001000
	.dc.b	%00110001,%10010010,%01000010,%10000100,%10010000
	.dc.b	%00101010,%10010010,%01000010,%10111000,%10010000
	.dc.b	%00101010,%10100001,%01000010,%10000100,%10010000
	.dc.b	%00100100,%10101111,%01000010,%10000100,%01000000
	.dc.b	%00100100,%10100001,%01011100,%10000100,%01100000

LOGO_MLD:
	.dc.b	%00100000,%10100000,%01111100,%00000000,%00000000
	.dc.b	%00100000,%10100000,%01000010,%00000000,%00000000
	.dc.b	%00110001,%10100000,%01000010,%00000000,%00000000
	.dc.b	%00110001,%10100000,%01000010,%00000000,%00000000
	.dc.b	%00101010,%10100000,%01000010,%00000000,%00000000
	.dc.b	%00101010,%10100000,%01000010,%00000000,%00000000
	.dc.b	%00100100,%10100000,%01000010,%00000000,%00000000
	.dc.b	%00100100,%10011111,%01011100,%00000000,%00000000

LOGO_RCD:
	.dc.b	%00111110,%00111110,%11111000,%00000000,%00000000
	.dc.b	%00100001,%01000000,%10000100,%00011110,%00000000
	.dc.b	%00100001,%01000000,%10000100,%00000001,%00000000
	.dc.b	%00100001,%01000000,%10000100,%00000001,%00000000
	.dc.b	%00101110,%01000000,%10000100,%00001110,%00000000
	.dc.b	%00100001,%01000000,%10000100,%00010000,%00000000
	.dc.b	%00100001,%01000000,%10000100,%00010000,%00000000
	.dc.b	%00100001,%00111110,%10111001,%11011111,%00000000

LOGO_RCD3:
	.dc.b	%00111110,%00111110,%11111000,%00000000,%00000000
	.dc.b	%00100001,%01000000,%10000100,%00011110,%00000000
	.dc.b	%00100001,%01000000,%10000100,%00000001,%00000000
	.dc.b	%00100001,%01000000,%10000100,%00000001,%00000000
	.dc.b	%00101110,%01000000,%10000100,%00001110,%00000000
	.dc.b	%00100001,%01000000,%10000100,%00000001,%00000000
	.dc.b	%00100001,%01000000,%10000100,%00000001,%00000000
	.dc.b	%00100001,%00111110,%10111001,%11011110,%00000000

LOGO_ZMUSIC:
	.dc.b	%00111111,%01000001,%01000010,%01111101,%00111110
	.dc.b	%00000001,%01000001,%01000010,%10000001,%01000000
	.dc.b	%00000010,%01100011,%01000010,%10000001,%01000000
	.dc.b	%00000100,%01100011,%01000010,%01111001,%01000000
	.dc.b	%00001000,%01010101,%01000010,%00000101,%01000000
	.dc.b	%00010000,%01010101,%01000010,%00000101,%01000000
	.dc.b	%00100000,%01001001,%01000010,%00000101,%01000000
	.dc.b	%00111111,%01001001,%00111100,%11111001,%00111110

LOGO_MCDRV:
	.dc.b	%00100000,%10011111,%01111100,%11111001,%00001000
	.dc.b	%00100000,%10100000,%01000010,%10000101,%00001000
	.dc.b	%00110001,%10100000,%01000010,%10000101,%00001000
	.dc.b	%00110001,%10100000,%01000010,%10000100,%10010000
	.dc.b	%00101010,%10100000,%01000010,%10111000,%10010000
	.dc.b	%00101010,%10100000,%01000010,%10000100,%10010000
	.dc.b	%00100100,%10100000,%01000010,%10000100,%01000000
	.dc.b	%00100100,%10011111,%01011100,%10000100,%01100000

		.even

		.end
