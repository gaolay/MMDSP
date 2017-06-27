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
		.include	MMDSP.H


SPEANA_CHAR1	equ	%0000_0110_01100111		*スペアナバックキャラ
			*col:6 chr:$67
SPEANA_CHAR2	equ	%0000_0111_01101011
			*col:7 chr:$6B

BACK_PAL1	equ	02*64+02*2048+06*2
LEVEL_PAL1	equ	16*64+16*2048+31*2+1
BACK_PAL2	equ	01*64+01*2048+05*2
LEVEL_PAL2	equ	07*64+05*2048+22*2

MAXLVL_TIME_N	equ	60		*最高線保持時間ノーマル
MAXLVL_TIME_R	equ	60		*最高線保持時間レイン
MAXLVL_TIME_M	equ	60		*最高線保持時間ミラー

			.text
			.even


*
*	＊ＳＰＥＡＮＡ＿ＭＡＫＥ
*機能：スペクトラムアナライザ画面を作る
*入出力：なし
*参考：
*

SPEANA_MAKE:
		movem.l	d0-d2/a0-a1,-(sp)

		move.l	#TXTADR+31+20*8*$80+$80,a0
		moveq.l	#6,d0
		moveq.l	#%00000010,d1
		moveq.l	#%00000110,d2
speana_m_mlp:
		move.b	#%00001110,(a0)			*横の目盛りをかく
		move.b	d1,$080(a0)
		move.b	d2,$100(a0)
		move.b	d1,$180(a0)
		move.b	d2,$200(a0)
		move.b	d1,$280(a0)
		move.b	d2,$300(a0)
		move.b	d1,$380(a0)
		lea.l	$400(a0),a0
		dbra	d0,speana_m_mlp

		lea.l	SPEA_MOJI(pc),a0
		bsr	TEXT48AUTO

		lea	switch_pat(pc),a0		*スイッチの枠を描く
		move.l	#$00080003,d1
		moveq	#1,d0
		movea.l	#TXTADR+32+149*$80,a1
		bsr	PUT_PATTERN_OR
		movea.l	#TXTADR+37+149*$80,a1
		bsr	PUT_PATTERN_OR
		movea.l	#TXTADR+41+149*$80,a1
		bsr	PUT_PATTERN_OR
		movea.l	#TXTADR+45+149*$80,a1
		bsr	PUT_PATTERN_OR
		movea.l	#TXTADR+49+149*$80,a1
		bsr	PUT_PATTERN_OR

		moveq	#1,d1			*積分モード設定
		bsr	SPEASUM_SET

		clr.b	SPEA_REV(a6)		*反転モード解除
		moveq	#0,d1
		bsr	SPEAREV_SET

		move.w	SPEA_MODE(a6),d1	*スペアナモード初期値
		move.w	#-1,SPEA_MODE(a6)
		bsr	SPEAMODE_SET

		moveq	#4,d1			*スペアナ減衰スピード初期値
		bsr	SPEASNS_SET

		movem.l	(sp)+,d0-d2/a0-a1
		rts

switch_pat:
		.dc.w	%0111111111111111,%1111111111111000
		.dc.w	%1000000000000000,%0000000000000100
		.dc.w	%1000000000000000,%0000000000000100
		.dc.w	%1000000000000000,%0000000000000100
		.dc.w	%0000000000000000,%0000000000000000
		.dc.w	%1000000000000000,%0000000000000100
		.dc.w	%1000000000000000,%0000000000000100
		.dc.w	%1000000000000000,%0000000000000100
		.dc.w	%0111111111111111,%1111111111111000


*==================================================
*スペアナ感度設定
*==================================================


*スペアナ感度アップ

SPEASNS_UP:
		move.l	d1,-(sp)
		move.b	SPEA_RANGE(a6),d1
		subq.b	#1,d1
		bsr	SPEASNS_SET
		move.l	(sp)+,d1
		rts


*スペアナ感度ダウン

SPEASNS_DOWN:
		move.l	d1,-(sp)
		move.b	SPEA_RANGE(a6),d1
		addq.b	#1,d1
		bsr	SPEASNS_SET
		move.l	(sp)+,d1
		rts


*スペアナ感度設定
*	d1.b <- 感度(0-9)

SPEASNS_SET:
		movem.l	d0-d1/a0,-(sp)
		cmpi.b	#9,d1
		bhi	speasns_set90
		movea.l	#TXTADR+28+$80*169+$20000,a0
		bsr	clr_snslvl
		move.b	d1,SPEA_RANGE(a6)
		bsr	put_snslvl
		ext.w	d1
		lsl.w	#2,d1
		addi.w	#8,d1
		move.b	d1,SPEA_SPEED(a6)
speasns_set90:
		movem.l	(sp)+,d0-d1/a0
		rts

clr_snslvl:
		movem.l	d0/a0,-(sp)
		move.b	SPEA_RANGE(a6),d0
		lsl.w	#8,d0
		add.w	d0,d0
		lea	(a0,d0.w),a0
		clr.w	(a0)
		clr.w	$80(a0)
		clr.w	$100(a0)
*		clr.w	$180(a0)
		movem.l	(sp)+,d0/a0
		rts

put_snslvl:
		movem.l	d0/a0,-(sp)
		move.b	SPEA_RANGE(a6),d0
		lsl.w	#8,d0
		add.w	d0,d0
		lea	(a0,d0.w),a0
		move.w	#%00000111_11111111,(a0)
		move.w	#%00000111_11111111,$80(a0)
		move.w	#%00000111_11111111,$100(a0)
*		move.w	#%00000111_11111111,$180(a0)
		movem.l	(sp)+,d0/a0
		rts


*==================================================
*スペアナ積分モード設定
*==================================================

SPEASUM_CHG:
		move.l	d1,-(sp)
		move.b	SPEA_SUM(a6),d1
		not.b	d1
		bsr	SPEASUM_SET
		move.l	(sp)+,d1
		rts

*積分モード設定
*	d1.b <- 積分モードフラグ(0:解除 0以外:設定)

SPEASUM_SET:
		movem.l	d0-d2/a0-a2,-(sp)
		tst.b	d1
		sne	d2
		move.b	d2,SPEA_SUM(a6)
		lea	sumswitch_pat1(pc),a0
		lea	RISE_TABLE_N(pc),a2
		tst.b	d2
		beq	speasum_set10
		lea	sumswitch_pat2(pc),a0
		lea	RISE_TABLE_S(pc),a2
speasum_set10:
		movea.l	#TXTADR+28+149*$80,a1
		moveq	#2,d0
		move.l	#$00080001,d1
		bsr	PUT_PATTERN
		move.l	a2,SPEA_RISETBL(a6)
speasum_set90:
		movem.l	(sp)+,d0-d2/a0-a2
		rts

sumswitch_pat1:
		.dc.w	%0000000000000000		*ノーマルモード
		.dc.w	%0000000000010000
		.dc.w	%0000000000010100
		.dc.w	%0000000000010101
		.dc.w	%0000010000010101
		.dc.w	%0000010100010101
		.dc.w	%0000010101010101
		.dc.w	%0000010101010101
		.dc.w	%0000010101010101

sumswitch_pat2:
		.dc.w	%0000000000000000		*積分モード
		.dc.w	%0000000001000000
		.dc.w	%0000000101010000
		.dc.w	%0000000101010000
		.dc.w	%0000010101010100
		.dc.w	%0000010101010101
		.dc.w	%0000010101010101
		.dc.w	%0000010101010101
		.dc.w	%0000010101010101


*==================================================
*スペアナリバースモード反転
*==================================================

SPEAREV_CHG:
		move.l	d1,-(sp)
		move.b	SPEA_REV(a6),d1
		not.b	d1
		bsr	SPEAREV_SET
		move.l	(sp)+,d1
		rts

*リバースモード設定
*	d1.b <- リバースモード(0:解除 0以外:設定)

SPEAREV_SET:
		movem.l	d0-d2/a0-a1,-(sp)
		tst.b	d1
		sne	d2
		movea.l	#TXTADR+32+149*$80,a1
		move.l	#$00080003,d1
		tst.b	d2
		beq	spearev_set10
		bsr	LIGHT_PATTERN
		bra	spearev_set20
spearev_set10:
		bsr	DARK_PATTERN
spearev_set20:
		cmp.b	SPEA_REV(a6),d2
		beq	spearev_set90
		move.b	d2,SPEA_REV(a6)
		movea.l	#SPPALADR,a0
		move.l	6*32+14*2(a0),d0
		swap	d0
		move.l	d0,6*32+14*2(a0)
		move.l	7*32+14*2(a0),d0
		swap	d0
		move.l	d0,7*32+14*2(a0)
spearev_set90:
		movem.l	(sp)+,d0-d2/a0-a1
		rts


*==================================================
*スペアナモード変更
*==================================================

*スペアナモード順送り

SPEAMODE_UP:
		move.l	d1,-(sp)
		move.w	SPEA_MODE(a6),d1
		addq.w	#1,d1
		andi.w	#3,d1
		bsr	SPEAMODE_SET
		move.l	(sp)+,d1
		rts

*スペアナモード逆送り

SPEAMODE_DOWN:
		move.l	d1,-(sp)
		move.w	SPEA_MODE(a6),d1
		subq.w	#1,d1
		andi.w	#3,d1
		bsr	SPEAMODE_SET
		move.l	(sp)+,d1
		rts

*スペアナモード変更
*	d1.w <- モード(0-3)

SPEAMODE_SET:
		movem.l	d0-d1/a0-a1,-(sp)
		cmpi.w	#3,d1
		bhi	speamode_set90
		cmp.w	SPEA_MODE(a6),d1
		beq	speamode_set90
		bsr	clr_speamode
		move.w	d1,SPEA_MODE(a6)
		bsr	put_speamode

		lea	dummyjob(pc),a0
		move.l	a0,SPEA_INTJOB(a6)
		bsr	clear_bg
		bsr	clear_text
		bsr	clear_buf
		bsr	set_palet
		add.w	d1,d1
		move.w	spea_jmptbl(pc,d1.w),d1
		lea	spea_jmptbl(pc,d1.w),a0
		move.l	a0,SPEA_INTJOB(a6)
speamode_set90:
		movem.l	(sp)+,d0-d1/a0-a1
dummyjob:
		rts

spea_jmptbl:
		.dc.w	SPEA_GENS_NORM-spea_jmptbl
		.dc.w	SPEA_GENS_RAIN-spea_jmptbl
		.dc.w	SPEA_GENS_MIRR-spea_jmptbl
		.dc.w	SPEA_INT_DEMO-spea_jmptbl


clear_bg:
		movem.l	d0-d7/a0,-(sp)
		move.w	#SPEANA_CHAR1,d1
		move.w	#$0667,d1
		cmpi.w	#1,SPEA_MODE(a6)
		bne	clear_bg10
		move.w	#SPEANA_CHAR2,d1
clear_bg10:
		move.w	d1,d2
		move.w	d1,d3
		move.w	d1,d4
		move.w	d1,d5
		move.w	d1,d6
		move.w	d1,d7
		cmpi.w	#2,SPEA_MODE(a6)
		bne	clear_bg20
		move.w	#SPEANA_CHAR2,d6
		move.w	d6,d7
clear_bg20:
		moveq.l	#31,d0
		move.l	#BGADR+32*2+20*$80,a0
clear_bg30:
		move.w	d1,(a0)+			*デフォルトキャラで埋める
		move.w	d2,$080-2(a0)
		move.w	d3,$100-2(a0)
		move.w	d4,$180-2(a0)
		move.w	d5,$200-2(a0)
		move.w	d6,$280-2(a0)
		move.w	d7,$300-2(a0)
		move.w	#$26E,-$82(a0)
		dbra	d0,clear_bg30
		movem.l	(sp)+,d0-d7/a0
		rts

clear_text:
		movem.l	d0-d1/a0,-(sp)
		move.l	#TXTADR+32+20*8*$80+$80,a0
		moveq	#28-1,d1
		moveq	#0,d0
clear_text10:
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		lea	$80+$60(a0),a0
		dbra	d1,clear_text10
		movem.l	(sp)+,d0-d1/a0
		rts

clear_buf:
		movem.l	d0-d1/a0,-(sp)
		lea	SPEA_BF2(a6),a0
		moveq	#0,d0
		moveq	#32/2-1,d1
clear_buf10:
		move.b	1(a0),(a0)+
		move.b	d0,(a0)+
		move.l	d0,(a0)+
		move.b	1(a0),(a0)+
		move.b	d0,(a0)+
		move.l	d0,(a0)+
		dbra	d1,clear_buf10
		movem.l	(sp)+,d0-d1/a0
		rts

*スペアナパレットセット

set_palet:
		movem.l	d0-d1/a0,-(sp)
		move.w	SPEA_MODE(a6),d0
		lsl.w	#3,d0
		lea	spea_paltbl(pc,d0.w),a0
		move.l	(a0)+,d0
		move.l	(a0),d1
		movea.l	#SPPALADR,a0
		tst.b	SPEA_REV(a6)
		beq	spearev_set30
		swap	d0
		swap	d1
spearev_set30:
		move.l	d0,6*32+14*2(a0)
		move.l	d1,7*32+14*2(a0)
		movem.l	(sp)+,d0-d1/a0
		rts

spea_paltbl:
		dc.w	BACK_PAL1,LEVEL_PAL1		*モード０
		dc.w	LEVEL_PAL1,BACK_PAL1
		dc.w	BACK_PAL1,LEVEL_PAL1		*モード１
		dc.w	LEVEL_PAL1,BACK_PAL1
		dc.w	BACK_PAL1,LEVEL_PAL1		*モード２
		dc.w	LEVEL_PAL2,BACK_PAL2
		dc.w	BACK_PAL2,LEVEL_PAL2		*モード３
		dc.w	LEVEL_PAL2,BACK_PAL2


*スペアナモードスイッチ表示

put_speamode:
		movem.l	d1/a1,-(sp)
		move.w	SPEA_MODE(a6),d1
		add.w	d1,d1
		add.w	d1,d1
		movea.l	#TXTADR+37+149*$80,a1
		lea	(a1,d1.w),a1
		move.l	#$00080003,d1
		bsr	LIGHT_PATTERN
		movem.l	(sp)+,d1/a1
		rts

*スペアナモードスイッチ消去

clr_speamode:
		movem.l	d1/a1,-(sp)
		move.w	SPEA_MODE(a6),d1
		add.w	d1,d1
		add.w	d1,d1
		movea.l	#TXTADR+37+149*$80,a1
		lea	(a1,d1.w),a1
		move.l	#$00080003,d1
		bsr	DARK_PATTERN
		movem.l	(sp)+,d1/a1
		rts


*==================================================
*スペアナ表示
*参考：SPEA_BF2(a6)のフォーマット・・・
*	１チャンネル５バイト
*		+00.b:目標値
*		+01.b:現在の位置
*		+02.b:減衰カウンタ
*		+03.b:最高線用カウンタ(0なら減衰中)
*		+04.b:最高線の位置/0なら非表示
*		+05.b:dummy
*==================================================

SPEANA_DISP:
		movem.l	d0-d3/d6-d7/a0-a5,-(sp)

		lea.l	TRACK_STATUS(a6),a1
		lea.l	FROM96_TO32(a6),a2
		lea.l	SPEA_BF1(a6),a3
		moveq.l	#32-1,d7
speana_disp10:
		move.b	KEYONSTAT(a1),d3		*まずパートごとのループ
		not.b	d3
		and.b	KEYONCHANGE(a1),d3
		beq	speana_disp40

		lea	KEYCODE(a1),a4
		lea	VELOCITY(a1),a5
		moveq	#8-1,d6
speana_disp20:
		lsr.b	#1,d3				*和音ループ
		bcc	speana_disp30

		moveq	#0,d0				*キーＯＮ時
		move.b	(a4),d0
		add.w	KEYOFFSET(a1),d0
		cmpi.w	#127,d0
		bhi	speana_disp30
		move.b	(a2,d0.w),d0
		bmi	speana_disp30
		lea	(a3,d0.w),a0

		moveq	#0,d0
		move.b	(a5),d0

		add.w	d0,(a0)				*中央位置

		move.w	d0,d1		*d1 = tl / 4
		lsr.w	#2,d1
		move.w	d1,d2		*d2 = tl / 8
		lsr.w	#1,d2

		lsr.w	#1,d0				*3/4
		add.w	d1,d0
		add.w	d0,2(a0)			*右に１つ離れて
		add.w	d0,-2(a0)			*左に１つ離れて

		sub.w	d2,d0				*5/16
		lsr.w	#1,d0
		add.w	d0,4(a0)			*右２つ
		add.w	d0,-4(a0)			*左２つ

							*1/8
		add.w	d2,-6(a0)			*左３つ
		add.w	d2,6(a0)			*右３つ

							*1/4
		add.w	d1,8(a0)			*右４つ
		add.w	d1,-8(a0)			*左４つ

		lsr.w	#1,d2				*1/16
		add.w	d2,10(a0)			*右５つ
		add.w	d2,-10(a0)			*左５つ

speana_disp30:
		addq.l	#1,a4
		addq.l	#1,a5
		tst.b	d3
		dbeq	d6,speana_disp20
speana_disp40:
		lea	TRST(a1),a1
		dbra	d7,speana_disp10

		lea.l	SPEA_BF1+10(a6),a1		*で、今度は横ループね
		lea.l	SPEA_BF2(a6),a2
		lea.l	ROUTE(pc),a3
		lea.l	ROUTE_HALF(pc),a4
		moveq.l	#31,d7

speana_disp50:
		move.w	(a1)+,d0
		beq	speana_disp59
		clr.w	-2(a1)
		tst.b	SPEA_SUM(a6)			*積分モードなら
		beq	speana_disp51
		moveq	#0,d1				*現在の値を1/2して足す
		move.b	1(a2),d1
		add.w	d1,d1
		add.w	(a4,d1.w),d0
speana_disp51:
		movea.l	a3,a0			*ルート(かなり無駄かな)
speana_disp52:
		cmp.w	(a0)+,d0
		bhi	speana_disp52
		move.l	a0,d0
		sub.l	a3,d0
		lsr.w	#1,d0
		subq.w	#1,d0
		cmp.b	1(a2),d0		*今のレベルを超えたら、表示
		bcs	speana_disp59
		move.b	d0,(a2)
speana_disp59:
		addq.l	#6,a2
		dbra	d7,speana_disp50

		movem.l	(sp)+,d0-d3/d6-d7/a0-a5
		rts


*==================================================
*レベル表示
*	d0.b <- level(0-28)
*	a0.l <- BG address
*	a2.b <- VELO_BF address
*==================================================

.if 0
lvl_put:
		movem.l	d0-d1/a1,-(sp)
		lea	SPEA_BGTBL1(pc),a1
		clr.b	(a2)
		moveq	#3,d1
		and.w	d0,d1
		addi.w	#$0667,d1
		move.w	d1,12(a1)
		moveq	#$1C,d1
		and.w	d0,d1
		lsr.w	#1,d1
		lea	(a1,d1.w),a1
		move.w	(a1)+,-$380(a0)
		move.w	(a1)+,-$300(a0)
		move.w	(a1)+,-$280(a0)
		move.w	(a1)+,-$200(a0)
		move.w	(a1)+,-$180(a0)
		move.w	(a1)+,-$100(a0)
		move.w	(a1)+,-$80(a0)
		move.b	d0,(a2)
		movem.l	(sp)+,d0-d1/a1
		rts

SPEA_BGTBL1:
		.dc.w	$0667,$0667,$0667,$0667,$0667,$0667
		.dc.w	$0667
		.dc.w	$066B,$066B,$066B,$066B,$066B,$066B,$066B
.endif

*==================================================
*ＭＡＸ線消去マクロ
*	a2.l <- SPEA_BF2
*	a5.l <- TEXT address
*==================================================

*NORMAL用
max_clr		macro
		local	max_clr_jp0
		move.w	4(a2),d0
		andi.w	#$ff00,d0
		beq	max_clr_jp0
		neg.w	d0
		clr.b	(a5,d0.w)
max_clr_jp0:
		endm

*RAIN用
max_clr2	macro
		local	max_clr_jp0
		move.w	4(a2),d0
		andi.w	#$ff00,d0
		beq	max_clr_jp0
		clr.b	(a5,d0.w)
max_clr_jp0:
		endm

*==================================================
*ＭＡＸ線表示マクロ
*	a2.l <- SPEA_BF2
*	a5.l <- TEXT address
*==================================================

*NORMAL用
max_put		macro
		local	max_put_jp0
		move.w	4(a2),d0
		andi.w	#$ff00,d0
		beq	max_put_jp0
		neg.w	d0
		move.b	#%01111111,(a5,d0.w)
max_put_jp0:
		endm

*RAIN用
max_put2	macro
		local	max_put_jp0
		move.w	4(a2),d0
		andi.w	#$ff00,d0
		beq	max_put_jp0
		move.b	#%01111111,(a5,d0.w)
max_put_jp0:
		endm


*==================================================
*スペアナ減衰処理
*	参考：割り込みより呼び出される。終了はＲＴＳ
*	SPEA_BF2(a6)のフォーマット・・・
*	１チャンネル５バイト
*		+00.b:目標値
*		+01.b:現在の位置
*		+02.b:減衰カウンタ
*		+03.b:最高線用カウンタ(0なら減衰中)
*		+04.b:最高線の位置/0なら非表示
*		+05.b:dummy
*==================================================

LEV1:		equ	SPPALADR+6*32+14*2+2
LEV2:		equ	SPPALADR+7*32+14*2+2

wk:		.dc.w	$0100
wkp1:		.dc.w	0
wkp2:		.dc.w	0

SPEANA_GENS:
.if 0
		lea	wk(pc),a0
		subq.b	#1,(a0)
		bne	skip
		not.b	1(a0)
		bne	sof
son:
		move.b	#2,(a0)
		move.w	2(a0),LEV1
		move.w	4(a0),LEV2
		bra	skip
sof:
		move.b	#1,(a0)
		move.w	LEV1,2(a0)
		move.w	LEV2,4(a0)
		clr.w	LEV1
		clr.w	LEV2
skip:
.endif

		movea.l	SPEA_INTJOB(a6),a0
		jmp	(a0)

*==================================================
*ＮＯＲＭＡＬモード
*==================================================

SPEA_GENS_NORM:
		move.l	#BGADR+32*2+26*$80,a1
		lea	SPEA_BF2(a6),a2
		movea.l	SPEA_RISETBL(a6),a3
		movea.l	#TXTADR+32+27*8*$80+$80,a5
		move.b	SPEA_SPEED(a6),d2
		moveq.l	#31,d7
gens_norm_loop:
		move.b	(a2),d3
		sub.b	1(a2),d3
		bhi	gens_norm_rise
		bcs	gens_norm_fall
		clr.b	(a2)
gens_norm_next:
		subq.b	#1,3(a2)		*最高線を一定時間保持
		bcc	gens_norm_next10
		move.b	4(a2),d0
		beq	gens_norm_next10
		tst.b	1(a2)
		sne	d1
		andi.b	#4,d1
		addq.b	#1,d1
		move.b	d1,3(a2)
		cmp.b	1(a2),d0
		bls	gens_norm_next10
		max_clr				*最高線を移動する
		subq.b	#1,4(a2)
		max_put
gens_norm_next10:
		addq.l	#1,a5
		addq.l	#2,a1
		addq.l	#6,a2
		dbra	d7,gens_norm_loop
		rts

gens_norm_fall:
		move.b	1(a2),d1		*減衰カウンタ処理
		sub.b	d1,2(a2)
		bhi	gens_norm_next
		add.b	d2,2(a2)
		bpl	gens_norm_fall10
		clr.b	2(a2)
gens_norm_fall10:
		subq.b	#1,d1			*メーター１レベル減らす
		move.b	d1,1(a2)
		moveq	#3,d0
		and.b	d1,d0
		addi.w	#$0667,d0
		lsl.w	#5,d1
		andi.w	#$380,d1
		neg.w	d1
		move.w	d0,(a1,d1.w)
		bra	gens_norm_next

gens_norm_rise:
		ext.w	d3
		move.b	(a3,d3.w),d3
gens_norm_rise10:
		move.b	1(a2),d1
		add.b	d3,d1			*DEST d1 = NOW + DIF
		move.b	d1,d0
		subq.b	#1,d0
		moveq	#3,d4			*BGPAT d4 = OFST + (DEST-1) % 4
		and.b	d0,d4
		addi.w	#$0668,d4
		lsl.w	#5,d0			*DPOS a4 = ADR + (DEST-1)/4
		andi.w	#$380,d0
		neg.w	d0
		lea	(a1,d0.w),a4
		moveq	#3,d0			*BGNUM d0 = ((NOW%4)+(DIF-1))/4
		and.b	1(a2),d0
		add.b	d3,d0
		subq.b	#5,d0
		bcs	gens_norm_rise14
		subq.b	#4,d0
		bcs	gens_norm_rise13
		subq.b	#4,d0
		bcs	gens_norm_rise12
		subq.b	#4,d0
		bcs	gens_norm_rise11
		move.w	#$066B,$200(a4)
gens_norm_rise11:
		move.w	#$066B,$180(a4)
gens_norm_rise12:
		move.w	#$066B,$100(a4)
gens_norm_rise13:
		move.w	#$066B,$80(a4)
gens_norm_rise14:
		move.w	d4,(a4)
gens_norm_rise40:
		move.b	d1,1(a2)
		cmp.b	(a2),d1			*目標に到達したら
		bcs	gens_norm_rise41
		clr.b	(a2)			*カウンタを初期化する
		clr.b	2(a2)
gens_norm_rise41:
		cmp.b	4(a2),d1		*最高線を追い越したら
		bls	gens_norm_next
		max_clr				*最高線を移動する
		move.b	d1,4(a2)
		max_put
		move.b	#MAXLVL_TIME_N,3(a2)
		bra	gens_norm_next


*==================================================
*ＲＡＩＮモード
*==================================================

SPEA_GENS_RAIN:
		move.l	#BGADR+32*2+20*$80,a1
		lea	SPEA_BF2(a6),a2
		movea.l	SPEA_RISETBL(a6),a3
		movea.l	#TXTADR+32+20*8*$80-$80,a5
		move.b	SPEA_SPEED(a6),d2
		moveq.l	#31,d7
gens_rain_loop:
		move.b	(a2),d3
		sub.b	1(a2),d3
		bhi	gens_rain_rise
		bcs	gens_rain_fall
		clr.b	(a2)
gens_rain_next:
		subq.b	#1,3(a2)
		bcc	gens_rain_next10
		move.b	4(a2),d0		*最高線を一定時間保持
		beq	gens_rain_next10
		addq.b	#1,3(a2)
		max_clr2			*最高線を落下させる
		addq.b	#1,4(a2)
		cmpi.b	#28,4(a2)
		bls	gens_rain_next01
		clr.b	4(a2)
gens_rain_next01:
		max_put2
gens_rain_next10:
		addq.l	#1,a5
		addq.l	#2,a1
		addq.l	#6,a2
		dbra	d7,gens_rain_loop
		rts

gens_rain_fall:
		move.b	1(a2),d1		*減衰カウンタ処理
		sub.b	d1,2(a2)
		bhi	gens_rain_next
		add.b	d2,2(a2)
		bpl	gens_rain_fall10
		clr.b	2(a2)
gens_rain_fall10:
		subq.b	#1,d1			*メーター１レベル減らす
		move.b	d1,1(a2)
		moveq	#3,d0
		and.b	d1,d0
		subi.w	#$076B,d0
		neg.w	d0
		lsl.w	#5,d1
		andi.w	#$380,d1
		move.w	d0,(a1,d1.w)
		bra	gens_rain_next


gens_rain_rise:
		ext.w	d3
		move.b	(a3,d3.w),d3
gens_rain_rise10:
		move.b	1(a2),d1
		add.b	d3,d1			*DEST d1 = NOW + DIF
		move.b	d1,d0
		subq.b	#1,d0
		moveq	#3,d4			*BGPAT d4 = OFST + 4 - (DEST-1) % 4
		and.b	d0,d4
		subi.w	#$076A,d4
		neg.w	d4
		lsl.w	#5,d0			*DPOS a4 = ADR + (DEST-1)/4
		andi.w	#$380,d0
		lea	(a1,d0.w),a4
		moveq	#3,d0			*BGNUM d0 = ((NOW%4)+(DIF-1))/4
		and.b	1(a2),d0
		add.b	d3,d0
		subq.b	#5,d0
		bcs	gens_rain_rise14
		subq.b	#4,d0
		bcs	gens_rain_rise13
		subq.b	#4,d0
		bcs	gens_rain_rise12
		subq.b	#4,d0
		bcs	gens_rain_rise11
		move.w	#$0767,-$200(a4)
gens_rain_rise11:
		move.w	#$0767,-$180(a4)
gens_rain_rise12:
		move.w	#$0767,-$100(a4)
gens_rain_rise13:
		move.w	#$0767,-$80(a4)
gens_rain_rise14:
		move.w	d4,(a4)
gens_rain_rise40:
		move.b	d1,1(a2)
		cmp.b	(a2),d1			*目標に到達したら
		bcs	gens_rain_rise41
		clr.b	(a2)			*カウンタを初期化する
		clr.b	2(a2)
gens_rain_rise41:
		cmp.b	4(a2),d1		*最高線を追い越したら
		bls	gens_rain_next
		max_clr2				*最高線を移動する
		move.b	d1,4(a2)
		max_put2
		neg.b	d1
		add.b	#MAXLVL_TIME_R,d1
		move.b	d1,3(a2)
		bra	gens_rain_next


*==================================================
*ＭＩＲＲＯＲモード
*==================================================

SPEA_GENS_MIRR:
		move.l	#BGADR+32*2+24*$80,a1
		lea	SPEA_BF2(a6),a2
		movea.l	SPEA_RISETBL(a6),a3
		movea.l	#TXTADR+32+25*8*$80+$80,a5
		move.b	SPEA_SPEED(a6),d2
		moveq.l	#31,d7
gens_mirr_loop:
		move.b	(a2),d3
		sub.b	1(a2),d3
		bhi	gens_mirr_rise
		bcs	gens_mirr_fall
		clr.b	(a2)
gens_mirr_next:
		subq.b	#1,3(a2)		*最高線を一定時間保持
		bcc	gens_mirr_next10
		move.b	4(a2),d0
		beq	gens_mirr_next10
		tst.b	1(a2)
		sne	d1
		andi.b	#4,d1
		addq.b	#1,d1
		move.b	d1,3(a2)
		cmp.b	1(a2),d0
		bls	gens_mirr_next10
		max_clr				*最高線を移動する
		subq.b	#1,4(a2)
		max_put
gens_mirr_next10:
		addq.l	#1,a5
		addq.l	#2,a1
		addq.l	#6,a2
		dbra	d7,gens_mirr_loop
		rts

gens_mirr_fall:
		move.b	1(a2),d1		*減衰カウンタ処理
		sub.b	d1,2(a2)
		bhi	gens_mirr_next
		add.b	d2,2(a2)
		bpl	gens_mirr_fall10
		clr.b	2(a2)
gens_mirr_fall10:
		subq.b	#1,d1			*メーター１レベル減らす
		move.b	d1,1(a2)
		moveq	#3,d0
		and.b	d1,d0
		addi.w	#$0667,d0
		lsl.w	#5,d1
		andi.w	#$380,d1
		neg.w	d1
		move.w	d0,(a1,d1.w)

		moveq	#$f,d0			*影の部分を描く
		and.w	(a1),d0
		subi.w	#$000b+$0007,d0
		neg.w	d0
		addi.w	#$0760,d0
		move.w	d0,$80(a1)
		moveq	#$f,d0			*影の部分を描く
		and.w	-$80(a1),d0
		subi.w	#$000b+$0007,d0
		neg.w	d0
		addi.w	#$0760,d0
		move.w	d0,$100(a1)
		bra	gens_mirr_next

gens_mirr_rise:
		move.b	1(a2),d1
		cmpi.b	#20,(a2)
		bls	gens_mirr_rise00
		moveq	#20,d3
		move.b	d3,(a2)
		sub.b	d1,d3
		bls	gens_mirr_rise40
gens_mirr_rise00:
		ext.w	d3
		move.b	(a3,d3.w),d3
gens_mirr_rise10:
		add.b	d3,d1			*DEST d1 = NOW + DIF
		move.b	d1,d0
		subq.b	#1,d0
		moveq	#3,d4			*BGPAT d4 = OFST + (DEST-1) % 4
		and.b	d0,d4
		addi.w	#$0668,d4
		lsl.w	#5,d0			*DPOS a4 = ADR + (DEST-1)/4
		andi.w	#$380,d0
		neg.w	d0
		lea	(a1,d0.w),a4
		moveq	#3,d0			*BGNUM d0 = ((NOW%4)+(DIF-1))/4
		and.b	1(a2),d0
		add.b	d3,d0
		subq.b	#5,d0
		bcs	gens_mirr_rise14
		subq.b	#4,d0
		bcs	gens_mirr_rise13
		subq.b	#4,d0
		bcs	gens_mirr_rise12
		subq.b	#4,d0
		bcs	gens_mirr_rise11
		move.w	#$066B,$200(a4)
gens_mirr_rise11:
		move.w	#$066B,$180(a4)
gens_mirr_rise12:
		move.w	#$066B,$100(a4)
gens_mirr_rise13:
		move.w	#$066B,$80(a4)
gens_mirr_rise14:
		move.w	d4,(a4)
gens_mirr_rise40:
		moveq	#$f,d0			*影の部分を描く
		and.w	(a1),d0
		subi.w	#$000b+$0007,d0
		neg.w	d0
		addi.w	#$0760,d0
		move.w	d0,$80(a1)
		moveq	#$f,d0			*影の部分を描く
		and.w	-$80(a1),d0
		subi.w	#$000b+$0007,d0
		neg.w	d0
		addi.w	#$0760,d0
		move.w	d0,$100(a1)

		move.b	d1,1(a2)
		cmp.b	(a2),d1			*目標に到達したら
		bcs	gens_mirr_rise41
		clr.b	(a2)			*カウンタを初期化する
		clr.b	2(a2)
gens_mirr_rise41:
		cmp.b	4(a2),d1		*最高線を追い越したら
		bls	gens_mirr_next
		max_clr				*最高線を移動する
		move.b	d1,4(a2)
		max_put
		neg.b	d1
		add.b	#MAXLVL_TIME_M,d1
		move.b	d1,3(a2)
		bra	gens_mirr_next


*==================================================
*ＤＥＭＯモード
*==================================================

SPEA_INT_DEMO:
		rts

			.data
			.even

*			AC,詰,ＸＸ,ＹＹ,文字,0
SPEA_MOJI:	.dc.b	01,00,30,4,0,152,'dB',0
		.dc.b	02,00,55,6,0,152,'SPECTRUM ANALYZER',0
		.dc.b	01,00,28,5,0,160,'MAX',0
		.dc.b	01,00,30,4,0,160,'63',0
		.dc.b	01,00,28,3,0,208,'sens',0
		.dc.b	01,00,30,5,0,208,' 0',0
		.dc.b	01,00,32,3,0,150,'REVERS',0
		.dc.b	01,00,37,4,0,150,'NORMAL',0
		.dc.b	01,00,42,1,0,150,'RAIN',0
		.dc.b	01,00,45,4,0,150,'MIRROR',0
		.dc.b	01,00,50,0,0,150,'KILL',0
		.dc.b	03,-1,30,0,0,216
		.dc.b	'TUNE----28------55------110-----220-----'
		.dc.b	'440-----880-----1.8k---3.5k-',0
		.dc.b	0


*上昇速度テーブル（ノーマル）
*			0,1,2,3,4,5,6,7,8,9,10,11,12,13,14
RISE_TABLE_N:	.dc.b	1,1,2,2,4,4,4,4,8,8,08,08,08,08,08
*			15,16,17,18,19,20,21,22,23,24,25,26,27,28
		.dc.b	08,08,08,08,08,08,08,08,08,08,08,08,08,08

*上昇速度テーブル（積分モード)
*			0,1,2,3,4,5,6,7,8,9,10,11,12,13,14
RISE_TABLE_S:	.dc.b	1,1,1,2,2,3,3,4,4,5,05,06,06,07,07
*			15,16,17,18,19,20,21,22,23,24,25,26,27,28
		.dc.b	08,08,09,09,10,10,11,11,12,12,13,13,14,14


YMAX = 640
XMAX = 28
A = 100		*x^3
B = 00		*x^2
C = 100		*x

CURVE		macro	x
		.dc.w	YMAX*((A*x/XMAX+B)*x/XMAX+C)*x/XMAX/(A+B+C)
		endm

		.even
*ROUTE::
*		.dc.w	0
*		CURVE	1
*		CURVE	2
*		CURVE	3
*		CURVE	4
*		CURVE	5
*		CURVE	6
*		CURVE	7
*		CURVE	8
*		CURVE	9
*		CURVE	10
*		CURVE	11
*		CURVE	12
*		CURVE	13
*		CURVE	14
*		CURVE	15
*		CURVE	16
*		CURVE	17
*		CURVE	18
*		CURVE	19
*		CURVE	20
*		CURVE	21
*		CURVE	22
*		CURVE	23
*		CURVE	24
*		CURVE	25
*		CURVE	26
*		CURVE	27
**		CURVE	28
*		.dc.w	65535

ROUTE:		.dc.w	0,1,4,9,16,24,35,47,61,77,94
		.dc.w	113,133,155,179,204,230,258,287,317,348
		.dc.w	381,415,450,486,523,561,600,65535

ROUTE_HALF	.dc.w	0,0,1,2,4,6,9,12,16,20,25
		.dc.w	30,36,42,49,56,64,72,81,90,100
		.dc.w	108,121,132,144,156,169,182,196,0

*ROUTE_HALF:	.dc.w	0,0,2,4,8,12,17,23,30,38,47
*		.dc.w	56,66,77,89,102,115,129,143,158,174
*		.dc.w	190,207,225,243,261,280,300,320

*ROUTE		.dc.w	0,1,4,9,16,25,36,49,64,81,100
*		.dc.w	121,144,169,196,225,256,289,324,361,400
*		.dc.w	432,484,529,576,625,676,729,784,65535

		.end
