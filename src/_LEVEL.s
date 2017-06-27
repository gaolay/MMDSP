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


LEVEL_DEFALT	equ	%0000_0101_01100111__0100_0101_01100111
			*col:5 chr:$67			*レベルメーターバックキャラ
PAN1_DEFALT	equ	%0000_0110_01100000__0100_0110_01100000
PAN2_DEFALT	equ	%1000_0110_01100000__1100_0110_01100000
OVER_LINE	equ	%0000_0010_01101110__0000_0010_01101110
			*col:2 chr:$6e

			.text
			.even

*==================================================
*	＊ＬＥＶＥＬＭ＿ＭＡＫＥ
*機能：ベロシティーグラフィック画面を作る
*入出力：なし
*参考：
*==================================================

LEVELM_MAKE:
		movem.l	d0-d2/a0-a1,-(sp)

		move.l	#TXTADR+31+29*8*$80+$80,a0
		moveq.l	#6,d0
		moveq.l	#%00000010,d1
		moveq.l	#%00000110,d2
levelm_m_mlp:
		move.b	#%00001110,(a0)			*横の目盛りをかく
		move.b	d1,$080(a0)
		move.b	d2,$100(a0)
		move.b	d1,$180(a0)
		move.b	d2,$200(a0)
		move.b	d1,$280(a0)
		move.b	d2,$300(a0)
		move.b	d1,$380(a0)
		lea.l	$400(a0),a0
		dbra	d0,levelm_m_mlp

		lea.l	VELO_MOJI(pc),a0
		bsr	TEXT48AUTO

		moveq.l	#15,d1
		move.l	#BGADR+32*2+29*$80,a1
levelm_mloop:
		move.l	#LEVEL_DEFALT,d0		*デフォルトキャラで埋める
		move.l	d0,(a1)
		move.l	d0,$080(a1)
		move.l	d0,$100(a1)
		move.l	d0,$180(a1)
		move.l	d0,$200(a1)
		move.l	d0,$280(a1)
		move.l	d0,$300(a1)
		move.l	#PAN1_DEFALT,$380(a1)
		move.l	#PAN2_DEFALT,$400(a1)
		move.l	#OVER_LINE,-$80(a1)

*		moveq.l	#0,d0
*		lea.l	$80*9(a1),a0
*		bsr	PRINT10_3KT_2
*		lea.l	$80*10(a1),a0
*		bsr	PRINT10_3KT_2

		addq.l	#4,a1
		dbra	d1,levelm_mloop

		moveq	#4,d1			*レベルメータ減衰スピード初期値
		bsr	LEVELSNS_SET

		move.b	LEVEL_TROFST(a6),d1	*表示先頭トラック設定
		bsr	LEVELPOS_SET

		move.l	#128,d0			*ベロシティバッファクリア
		lea	VELO_BF(a6),a0
		bsr	HSCLR

		movem.l	(sp)+,d0-d2/a0-a1
		rts


*==================================================
*レベルメータ感度設定
*==================================================

*レベルメータ感度アップ

LEVELSNS_UP:
		move.l	d1,-(sp)
		move.b	LEVEL_RANGE(a6),d1
		subq.b	#1,d1
		bsr	LEVELSNS_SET
		move.l	(sp)+,d1
		rts


*レベルメータ感度ダウン

LEVELSNS_DOWN:
		move.l	d1,-(sp)
		move.b	LEVEL_RANGE(a6),d1
		addq.b	#1,d1
		bsr	LEVELSNS_SET
		move.l	(sp)+,d1
		rts


*レベルメータ感度設定
*	d1.b <- 感度(0-9)

LEVELSNS_SET:
		movem.l	d0-d1/a0,-(sp)
		cmpi.b	#9,d1
		bhi	levelsns_set90
		movea.l	#TXTADR+28+$80*241+$20000,a0
		bsr	clr_snslvl
		move.b	d1,LEVEL_RANGE(a6)
		bsr	put_snslvl
		ext.w	d1
		mulu	#10,d1
		addi.w	#20,d1
		move.b	d1,LEVEL_SPEED(a6)
levelsns_set90:
		movem.l	(sp)+,d0-d1/a0
		rts

clr_snslvl:
		movem.l	d0/a0,-(sp)
		move.b	LEVEL_RANGE(a6),d0
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
		move.b	LEVEL_RANGE(a6),d0
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
*レベルメータ表示範囲移動
*==================================================

*レベルメータ表示位置アップ

LEVELPOS_UP:
		move.l	d1,-(sp)
		move.b	LEVEL_TROFST(a6),d1
		addq.b	#1,d1
		bsr	move_level
levelpos_up90:
		move.l	(sp)+,d1
		rts

*レベルメータ表示位置ダウン

LEVELPOS_DOWN:
		move.l	d1,-(sp)
		move.b	LEVEL_TROFST(a6),d1
		subq.b	#1,d1
		bsr	move_level
		move.l	(sp)+,d1
		rts

*レベルメータ移動
*	d1.b <- 位置(0-16)

LEVELPOS_SET:
move_level:
		movem.l	d0-d1/a0,-(sp)
		cmpi.b	#16,d1		*範囲チェック
		bhi	move_level90
move_level20:
*		cmp.b	LEVEL_TROFST(a6),d1
*		beq	move_level90
		move.b	d1,LEVEL_TROFST(a6)		*表示トラック変更
		st.b	LEVEL_TRCHG(a6)
		ext.w	d1
		mulu	#TRST,d1
		lea	TRACK_STATUS(a6),a0
		lea	(a0,d1.w),a0
		move.l	a0,LEVEL_TRBUF(a6)
		movea.l	#TXTADR+33+224*$80,a0		*トラック番号表示
		moveq	#0,d0
		move.b	LEVEL_TROFST(a6),d0
		addq.b	#1,d0
		bsr	put_tracknum
		movea.l	#TXTADR+49+224*$80,a0
		addq.b	#8,d0
		bsr	put_tracknum
move_level90:
		movem.l	(sp)+,d0-d1/a0
		rts

put_tracknum:
		movem.l	d0-d1/a0-a1,-(sp)
		movea.l	a0,a1
		lea	tracknum(pc),a0
		divu	#10,d0
		addi.b	#'0',d0
		move.b	d0,(a0)
		swap	d0
		addi.b	#'0',d0
		move.b	d0,1(a0)
		moveq	#1,d0
		moveq	#0,d1
		bsr	TEXT_4_8
		movem.l	(sp)+,d0-d1/a0-a1
		rts

tracknum:
		.dc.b	'00 ',0
		.even

*==================================================
*ベロシティーグラフィックの表示
*参考：VELO_BF(a6)のフォーマット・・・
*	１チャンネル４バイト
*		+00(a?):現在の位置
*		+01(a?):減衰カウンタ
*		+02(a?):ＶＥＬＯＣＩＴＹの位置(0:非表示)
*		+03(a?):キーＯＦＦフラグ
*==================================================

LEVELM_DISP:
		tst.b	LEVEL_TRCHG(a6)
		beq	LEVELM_DISPM

		clr.b	LEVEL_TRCHG(a6)
		bsr	clear_status			*先頭トラックが変化した場合
		bsr	LEVELM_DISPM
		bsr	resume_status
		rts

LEVELM_DISPM:
		movem.l	d0-d3/d7/a0-a4,-(sp)

		movea.l	#BGADR+32*2+36*$80,a1
		movea.l	LEVEL_TRBUF(a6),a2
		lea	VELO_BF(a6),a3
		movea.l	#TXTADR+32+36*8*$80-$80,a4

		move.b	LEVEL_TROFST(a6),d2		*トラック番号
		move.l	TRACK_CHANGE(a6),d3		*トラックマスク変化
		moveq	#16-1,d7			*トラック数

levelm_disp10:
		move.b	STCHANGE(a2),d1			*パンが変化した、
		btst.l	#2,d1
		bne	levelm_disp11
		btst.l	d2,d3				*またはマスクが変化したら、
		beq	levelm_disp20
levelm_disp11:
		bsr	put_pan				*パンを表示する。
levelm_disp20:
		btst.l	#3,d1
		beq	levelm_disp30
		bsr	put_program
levelm_disp30:
		btst.b	#0,KEYCHANGE(a2)
		beq	levelm_disp40
		bsr	put_keycode
levelm_disp40:
		btst.l	d2,d3			*またはマスクが変化したら、
		bne	levelm_disp41
		btst.b	#0,VELCHANGE(a2)
		beq	levelm_disp50
levelm_disp41:
		bsr	put_velocity
levelm_disp50:
		tst.b	KEYONCHANGE(a2)
		beq	levelm_disp90
		bsr	put_keyon
levelm_disp90:
		addq.l	#4,a1
		lea	TRST(a2),a2
		addq.b	#1,d2
		addq.l	#4,a3
		addq.l	#2,a4
		dbra	d7,levelm_disp10

		movem.l	(sp)+,d0-d3/d7/a0-a4
		rts

pan_dataFM:	dc.w	$FFFF,$0000,$007F,$0040

put_pan:
		move.l	TRACK_ENABLE(a6),d0		*マスクされていたら、暗くする
		btst.l	d2,d0
		beq	put_pan20

		lea	PANCHR(pc),a0
		move.w	PAN(a2),d0			*MIDI PANに変換
		bpl	put_pan01
		add.w	d0,d0
		andi.w	#$0006,d0
		move.w	pan_dataFM(pc,d0.w),d0
		bmi	put_pan10
put_pan01:
		cmpi.w	#127,d0
		bhi	put_pan10
		addq.w	#8,d0				*パターン番号計算
		lsr.w	#1,d0
		andi.w	#$00F8,d0
		lea.l	8(a0,d0.w),a0
put_pan10:
		move.w	(a0)+,(a1)			*表示
		move.w	(a0)+,$02(a1)
		move.w	(a0)+,$80(a1)
		move.w	(a0)+,$82(a1)
		bra	put_pan90
put_pan20:
		move.w	#$0660,(a1)			*暗い○表示
		move.w	#$4660,$02(a1)
		move.w	#$8660,$80(a1)
		move.w	#$C660,$82(a1)
put_pan90:
		rts

put_program:
		move.w	PROGRAM(a2),d0
		lea.l	$80*2(a1),a0
		bsr	PRINT10_3KT_2
		rts

put_keycode:
		moveq	#0,d0
		move.b	KEYCODE(a2),d0
		lea.l	$80*3(a1),a0
		bsr	PRINT10_3KT_2
		rts

put_velocity:
		move.l	TRACK_ENABLE(a6),d0		*マスクされていたら、max線下に
		btst.l	d2,d0
		beq	put_velocity00

		move.b	VELOCITY(a2),d0
		andi.b	#$7f,d0
		lsr.b	#2,d0
		sub.b	#4,d0
		bpl	put_velocity10
put_velocity00
		moveq.l	#0,d0
put_velocity10:
		cmp.b	(a3),d0
		bhi	put_velocity20
		bsr	lvl_put
put_velocity20:
		bsr	max_clr
		move.b	d0,2(a3)
		bsr	max_put
		rts

put_keyon:
		move.b	KEYONSTAT(a2),d0
		not.b	d0
		beq	put_keyon20
put_keyon10:
		and.b	KEYONCHANGE(a2),d0
		beq	put_keyon11
		move.b	LEVEL_SPEED(a6),1(a3)		*キーＯＮなら
		clr.b	3(a3)
		move.b	2(a3),d0
		bsr	lvl_put				*レベル表示する
put_keyon11:	rts
put_keyon20:
		moveq	#2,d0				*キーＯＦＦなら
		cmpi.b	#27,LEVEL_SPEED(a6)
		bhi	put_keyon21
		moveq	#-1,d0
put_keyon21:	move.b	d0,3(a3)			*減衰スピードを上げる
		rts


*==================================================
* ステータスオールクリア
*==================================================

clear_status:
		movem.l	d0/d7/a0-a1,-(sp)
		movea.l	LEVEL_TRBUF(a6),a0
		lea	STSAVE(a6),a1
		moveq	#-1,d0

		move.l	TRACK_CHANGE(a6),(a1)+
		move.l	d0,TRACK_CHANGE(a6)
		moveq	#16-1,d7
clear_status10:
		move.b	STCHANGE(a0),(a1)+
		move.b	KEYONCHANGE(a0),(a1)+
		move.b	KEYCHANGE(a0),(a1)+
		move.b	VELCHANGE(a0),(a1)+
		move.b	d0,STCHANGE(a0)
		move.b	d0,KEYONCHANGE(a0)
		move.b	d0,KEYCHANGE(a0)
		move.b	d0,VELCHANGE(a0)
		lea	TRST(a0),a0
		dbra	d7,clear_status10
		movem.l	(sp)+,d0/d7/a0-a1
		rts

resume_status:
		movem.l	d7/a0-a1,-(sp)
		movea.l	LEVEL_TRBUF(a6),a0
		lea	STSAVE(a6),a1

		move.l	(a1)+,TRACK_CHANGE(a6)
		moveq	#16-1,d7
resume_status10:
		move.b	(a1)+,STCHANGE(a0)
		move.b	(a1)+,KEYONCHANGE(a0)
		move.b	(a1)+,KEYCHANGE(a0)
		move.b	(a1)+,VELCHANGE(a0)
		lea	TRST(a0),a0
		dbra	d7,resume_status10
		movem.l	(sp)+,d7/a0-a1
		rts


*==================================================
*レベル表示
*	d0.b <- level(0-27)
*	a1.l <- BG address
*	a3.b <- VELO_BF address
*==================================================

lvl_put:
		movem.l	d0-d1/a0,-(sp)
		lea	LEVEL_BGTBL1(pc),a0
		clr.b	(a3)
		move.w	d0,d1
		swap	d0
		move.w	d1,d0
		andi.l	#$00030003,d0
		addi.l	#$05674567,d0
		move.l	d0,24(a0)
		moveq	#$1C,d0
		and.w	d1,d0
		lea	(a0,d0.w),a0
		move.l	(a0)+,-$380(a1)
		move.l	(a0)+,-$300(a1)
		move.l	(a0)+,-$280(a1)
		move.l	(a0)+,-$200(a1)
		move.l	(a0)+,-$180(a1)
		move.l	(a0)+,-$100(a1)
		move.l	(a0)+,-$80(a1)
		move.b	d1,(a3)
		movem.l	(sp)+,d0-d1/a0
		rts

LEVEL_BGTBL1:
		.dc.l	$05674567,$05674567,$05674567,$05674567
		.dc.l	$05674567,$05674567,$05674547
		.dc.l	$056B456B,$056B456B,$056B456B,$056B456B
		.dc.l	$056B456B,$056B456B,$056B456B


*==================================================
*ＭＡＸ線消去
*	a3.l <- VELO_BF
*	a4.l <- TEXT address
*==================================================

max_clr:
		move.l	d0,-(sp)

		move.w	2(a3),d0
		andi.w	#$1F00,d0
		neg.w	d0
		clr.w	(a4,d0.w)

		movem.l	(sp)+,d0
		rts


*==================================================
*ＭＡＸ線表示
*	a3.l <- VELO_BF
*	a4.l <- TEXT address
*==================================================

max_put:
		move.l	d0,-(sp)

		move.w	2(a3),d0
		andi.w	#$1F00,d0
		neg.w	d0
		move.w	#%0111111111111110,(a4,d0.w)

		move.l	(sp)+,d0
		rts

*
*	＊ＬＥＶＥＬＭ＿ＧＥＮＳ
*機能：ベロシティーの減衰
*入出力：なし
*参考：割り込みより呼び出される。終了はＲＴＳ
*

LEVELM_GENS:
		move.l	#BGADR+32*2+35*$80,a1
		lea.l	VELO_BF(a6),a2
		moveq.l	#15,d7
levelm_gens_lp:
		move.b	(a2),d2
		beq	levelm_gen_jp2
		tst.b	3(a2)			*キーＯＦＦなら高速減衰
		beq	levelm_gen_jp0
		bmi	levelm_gen_jp1
		bchg.b	#0,3(a2)
		beq	levelm_gen_jp1
		bra	levelm_gen_jp2
levelm_gen_jp0:
		sub.b	d2,1(a2)
		bhi	levelm_gen_jp2
		move.b	LEVEL_SPEED(a6),d0
		add.b	d0,1(a2)
		bpl	levelm_gen_jp1
		clr.b	1(a2)
levelm_gen_jp1:
		ext.w	d2
		subq.b	#1,d2				*メーター１ドット減らす
		move.b	d2,(a2)
		moveq	#3,d0
		and.w	d2,d0
		move.l	#$45670567,d1
		add.b	d0,d1
		swap.w	d1
		add.b	d0,d1
		andi.w	#$001c,d2
		lsl.w	#5,d2
		neg.w	d2
		move.l	d1,(a1,d2.w)
levelm_gen_jp2:
		addq.l	#4,a1
		addq.l	#4,a2
		dbra	d7,levelm_gens_lp

		rts


		.data
		.even

*			AC,詰,ＸＸ,ＹＹ,文字,0
VELO_MOJI:	.dc.b	01,00,30,4,0,224,'@v',0
		.dc.b	01,00,32,0,0,224,'Tr01 ',0
		.dc.b	01,00,48,0,0,224,'Tr09 ',0
		.dc.b	02,00,56,2,0,224,'VELOCITY GRAPHICS',0
		.dc.b	01,00,28,5,0,232,'MAX',0
		.dc.b	01,00,30,1,0,232,'127',0
		.dc.b	01,00,30,4,1,000,'63',0
		.dc.b	01,00,28,3,1,024,'sens',0
		.dc.b	01,00,30,5,1,024,' 0',0
		.dc.b	03,00,28,2,1,032,'  PANPOT',0
		.dc.b	03,00,28,2,1,040,'  ON/OFF',0
		.dc.b	03,00,28,1,1,048,' PROGRAM',0
		.dc.b	03,00,28,1,1,056,' KEYCODE',0
		.dc.b	0
		.even

PANCHR:
		.dc.w	$0560,$4560,$8560,$C560		*off
		.dc.w	$0560,$4560,$8562,$C560		*0(left)
		.dc.w	$0560,$4560,$8563,$C560		*1
		.dc.w	$0563,$4560,$8560,$C560		*2
		.dc.w	$0562,$4560,$8560,$C560		*3
		.dc.w	$0561,$4561,$8560,$C560		*4(center)
		.dc.w	$0560,$4562,$8560,$C560		*5
		.dc.w	$0560,$4563,$8560,$C560		*6
		.dc.w	$0560,$4560,$8560,$C563		*7
		.dc.w	$0560,$4560,$8560,$C562		*8(right)

		.end
