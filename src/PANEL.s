*************************************************************************
*									*
*									*
*	    Ｘ６８０００　ＭＸＤＲＶ／ＭＡＤＲＶディスプレイ		*
*									*
*				ＭＭＤＳＰ				*
*									*
*									*
*	Copyright (C) 1992 Masao Takahashi				*
*									*
*									*
*************************************************************************


		.include	iocscall.mac
		.include	doscall.mac
		.include	MMDSP.h
		.include	CONTROL.h


*==================================================
* PANEL 構造体定義
*==================================================

		.offset	0
PNL_ACT		.ds.w	1			*パネルの有効フラグ
PNL_X		.ds.w	1			*パネルの左上x座標
PNL_Y		.ds.w	1			*     〃     y 〃
PNL_LX		.ds.w	1			*パネルのx方向の大きさ
PNL_LY		.ds.w	1			*   〃   y     〃
PNL_MAKE	.ds.w	1			*パネル描画関数
PNL_EVENT	.ds.w	1			*イベント処理関数
PNL_DRAG	.ds.w	1			*ドラッグ処理関数
		.text


*==================================================
* PANEL テーブル
*==================================================

PANEL		.macro	label
		dc.w	label-PANEL_TABLE
		endm

PANEL_TABLE:
		PANEL	CONSOLE_PANEL
		PANEL	GRAPH_PANEL
		PANEL	SPEAMODE_PANEL
		PANEL	SPEASNS_PANEL
		PANEL	LEVELSNS_PANEL
		PANEL	TRMASK_KB_PANEL
		PANEL	TRACKMASK_PANEL
		PANEL	KEYBD_PANEL
		PANEL	LEVEL_PANEL
		PANEL	BG_PANEL
		PANEL	SEL_PANEL
		PANEL	SELAUTO_PANEL
		PANEL	GTONE_PANEL
*		PANEL	PALET_PANEL
*		PANEL	ANIM_PANEL
*		新たなパネルを作成する場合、ここに
*		パネルテーブルのアドレスを追加する
		dc.w	0


*==================================================
* PANEL 描画
*	アクティブなパネルを描画する
*==================================================

PANEL_MAKE:
		movem.l	d0-d2/a0-a2,-(sp)
		lea	PANEL_TABLE(pc),a1
		movea.l	a1,a2

panel_make10:
		move.w	(a1)+,d0
		beq	panel_make90
		lea	(a2,d0.w),a0
		tst.w	PNL_ACT(a0)
		beq	panel_make10
		move.w	PNL_MAKE(a0),d0
		beq	panel_make10
		jsr	(a0,d0.w)
		bra	panel_make10

panel_make90:
		movem.l	(sp)+,d0-d2/a0-a2
		rts


*==================================================
* PANEL イベント処理
*	マウスが押された時の処理をする
*==================================================

PANEL_EVENT:
		movem.l	d0-d2/a0-a3,-(sp)
		lea	PANEL_TABLE(pc),a1
		movea.l	a1,a2

panel_event10:
		move.w	MOUSE_X(a6),d1
		move.w	MOUSE_Y(a6),d2
		move.w	(a1)+,d0
		beq	panel_event90

		lea	(a2,d0.w),a3
		tst.w	PNL_ACT(a3)		*有効チェック
		beq	panel_event10
		sub.w	PNL_X(a3),d1		*範囲チェック
		bcs	panel_event10
		sub.w	PNL_Y(a3),d2
		bcs	panel_event10
		cmp.w	PNL_LX(a3),d1
		bcc	panel_event10
		cmp.w	PNL_LY(a3),d2
		bcc	panel_event10

		move.w	PNL_EVENT(a3),d0		*パネル範囲内なら、その処理関数へ
		jsr	(a3,d0.w)
		tst.l	d0
		beq	panel_event90
		move.l	a3,DRAG_FUNC(a6)		*ドラッグ処理関数を登録する

panel_event90:
		movem.l	(sp)+,d0-d2/a0-a3
		rts


*==================================================
* PANEL ドラッグ処理
*	マウスがドラッグされた時の処理をする
*==================================================

PANEL_DRAG:
		movem.l	d0-d2/a0,-(sp)

		move.w	MOUSE_X(a6),d1
		move.w	MOUSE_Y(a6),d2
		move.l	DRAG_FUNC(a6),d0
		beq	panel_drag90
		movea.l	d0,a0

		tst.w	PNL_ACT(a0)		*有効チェック
		beq	panel_drag10
		sub.w	PNL_X(a0),d1
		sub.w	PNL_Y(a0),d2
		move.w	PNL_DRAG(a0),d0
		jsr	(a0,d0.w)
		tst.l	d0
		bne	panel_drag90
panel_drag10:
		clr.l	DRAG_FUNC(a6)		*ドラッグ処理関数を解除
panel_drag90:
		movem.l	(sp)+,d0-d2/a0
		rts


*----------------------------------------------------------------------
*パネル処理関数群
*

*時間経過をはかるマクロ - 1.計測開始
*	d0.w -> システムタイマー値

TIME_SET	macro
		MYONTIME
		move.w	d0,PANEL_ONTIME(a6)
		endm

*時間経過をはかるマクロ - 2.経過チェック
*	d0.w -> (経過時間)-(目的時間)

TIME_PASS	macro	time
		MYONTIME
		sub.w	PANEL_ONTIME(a6),d0
		endm


*==================================================
* コンソールパネル
*==================================================

CONSOLE_PANEL:
		.dc.w	1
		.dc.w	232
		.dc.w	23
		.dc.w	176
		.dc.w	26
		.dc.w	CONS_MAKE-CONSOLE_PANEL
		.dc.w	CONS_EVENT-CONSOLE_PANEL
		.dc.w	CONS_DRAG-CONSOLE_PANEL

CONS_MAKE:
		movea.l	#TXTADR+$80*28+34,a0
		bsr	cons_makebar
		addq.w	#5,a0
		bsr	cons_makebar
		addq.w	#5,a0
		bsr	cons_makebar

		movea.l	#TXTADR+$80*28+29,a0			*左括弧
		move.b	#%01111111,(a0)
		move.b	#%01010000,1(a0)
		move.b	#%01111111,$80*16(a0)
		move.b	#%01010000,$80*16+1(a0)
		move.b	#%10000000,d0
		bsr	cons_maketbar

		movea.l	#TXTADR+$80*28+51,a0			*右括弧
		move.b	#%00001010,(a0)
		move.b	#%11111110,1(a0)
		move.b	#%00001010,$80*16(a0)
		move.b	#%11111110,$80*16+1(a0)
		move.b	#%00000001,d0
		addq.l	#1,a0
		bsr	cons_maketbar

		lea	CONS_MES(pc),a0
		bsr	TEXT48AUTO
		rts

cons_makebar:
		move.b	#%10101111,(a0)
		move.b	#%10101111,$80*16(a0)
		move.b	#%11101010,1(a0)
		move.b	#%11101010,$80*16+1(a0)
		rts

cons_maketbar:
		moveq	#15-1,d1
cons_maketbar10:
		lea	$80(a0),a0
		move.b	d0,(a0)
		dbra	d1,cons_maketbar10
		rts

*			AC,詰,ＸＸ,ＹＹ,文字
CONS_MES:	.dc.b	02,00,31,2,0,24,'PLAY',0
		.dc.b	02,00,36,2,0,24,'PAUSE',0
		.dc.b	02,00,41,4,0,24,'STOP',0
		.dc.b	02,00,46,7,0,24,'FADE OUT',0
		.dc.b	02,00,36,5,0,40,'SKIP',0
		.dc.b	02,00,31,2,0,40,'SLOW',0
		.dc.b	02,00,46,4,0,40,'MMDSP QUIT',0
		.dc.b	0
		.even

CONS_EVENT:
		bsr	get_conscmd
		tst.w	d0
		beq	cons_event90

		cmpi.w	#1,d0
		beq	cons_event_play
		cmpi.w	#2,d0
		beq	cons_event_pause
		cmpi.w	#3,d0
		beq	cons_event_stop
		cmpi.w	#4,d0
		beq	cons_event_fade
		cmpi.w	#5,d0
		beq	cons_event_slow
		cmpi.w	#6,d0
		beq	cons_event_skip
		cmpi.w	#8,d0
		beq	cons_event_quit
cons_event90:
		moveq	#0,d0
		rts

cons_event_play:
		ENTER	CMD_PLAY
		bra	cons_event90

cons_event_pause:
		ENTER	CMD_PAUSE
		bra	cons_event90

cons_event_stop:
		ENTER	CMD_STOP
		bra	cons_event90

cons_event_fade:
		ENTER	CMD_FADE
		bra	cons_event90

cons_event_skip:
		moveq	#CMD_SKIP,d0
		bra	cons_event_slow10
cons_event_slow:
		moveq	#CMD_SLOW,d0
cons_event_slow10:
		move.w	d0,PANEL_WORK(a6)
		moveq	#1,d1
		bsr	ENTER_CMD
		TIME_SET
		moveq	#1,d0
		rts

cons_event_quit:
		ENTER	CMD_QUIT
		bra	cons_event90

get_conscmd:
		moveq	#0,d0
		cmpi.w	#160,d1
		bcs	get_conscmd10
		move.w	#159,d1
get_conscmd10:
		ext.l	d1
		divu	#40,d1			*40ドットで割って
		swap	d1
		cmpi.w	#15,d1			*横棒のところなら無視
		bls	get_conscmd90
		swap	d1
		addq.w	#1,d1
		cmpi.w	#9,d2
		bls	get_conscmd80
		cmpi.w	#14,d2			*２行の間なら無視
		bls	get_conscmd90
		addq.w	#4,d1
get_conscmd80:
		move.w	d1,d0
get_conscmd90:
		rts

CONS_DRAG:
		tst.w	MOUSE_L(a6)		*ボタンが押されていたら、
		beq	cons_drag_end
		TIME_PASS			*0.05secごとに
		cmpi.w	#05,d0
		bls	cons_drag90
		move.w	PANEL_WORK(a6),d0	*スキップ／スローをかけ直す
		moveq	#1,d1
		bsr	ENTER_CMD
		TIME_SET
cons_drag90:
		moveq	#1,d0
		rts

cons_drag_end:
		move.w	PANEL_WORK(a6),d0	*ボタンが離されたら、解除
		moveq	#0,d1
		bsr	ENTER_CMD
		moveq	#0,d0
		rts


*==================================================
* グラフィックパネル
*==================================================

GRAPH_PANEL:
		.dc.w	1
		.dc.w	360
		.dc.w	55
		.dc.w	64
		.dc.w	10
		.dc.w	GRAPH_MAKE-GRAPH_PANEL
		.dc.w	GRAPH_EVENT-GRAPH_PANEL
		.dc.w	GRAPH_DRAG-GRAPH_PANEL

GRAPH_MAKE:
		move.l	a1,-(sp)
		moveq	#1,d0
		move.l	#5*$10000+7,d1
		lea	graph_pat1(pc),a0
		movea.l	#TXTADR+45+$80*57,a1
		bsr	PUT_PATTERN
		moveq	#2,d0
		lea	graph_pat2(pc),a0
		bsr	PUT_PATTERN
		move.l	(sp)+,a1
		rts
.if 1
graph_pat1:
	.dc.w	%0000000000000000,%0000000000000000,%0000000011111110,%0000000011111110
	.dc.w	%0000000000000001,%0000000001111101,%0000000010101010,%0000000011111110
	.dc.w	%0000000000000001,%0000000001111101,%0000000011010100,%0000000011111110
	.dc.w	%0000000000000001,%0000000001111101,%0000000010101010,%0000000011111110
	.dc.w	%0000000000000001,%0000000000000001,%0000000011010100,%0000000011111110
	.dc.w	%0000000001111111,%0000000001111111,%0000000000000000,%0000000000000000

graph_pat2:
	.dc.w	%0000111011111110,%0000111011111110,%0000111000000000,%0000111000000000
	.dc.w	%0000101010000010,%0000101010000010,%0000101001010101,%0000101000000001
	.dc.w	%0000101010000010,%0000101010000010,%0000101000101011,%0000101000000001
	.dc.w	%0000101010000010,%0000101010000010,%0000101001010101,%0000101000000001
	.dc.w	%0000101011111110,%0000101011111110,%0000101000101011,%0000101000000001
	.dc.w	%0000111000000000,%0000111000000000,%0000111001111111,%0000111001111111
.else
graph_pat1:
	.dc.w	%0000000000000000,%0000000000000000,%0000111111111110,%0000111111111110
	.dc.w	%0000000000000001,%0000011111111101,%0000101010101010,%0000111111111110
	.dc.w	%0000000000000001,%0000011111111101,%0000110101010100,%0000111111111110
	.dc.w	%0000000000000001,%0000011111111101,%0000101010101010,%0000111111111110
	.dc.w	%0000000000000001,%0000000000000001,%0000110101010100,%0000111111111110
	.dc.w	%0000011111111111,%0000011111111111,%0000000000000000,%0000000000000000

graph_pat2:
	.dc.w	%0000111111111110,%0000111111111110,%0000000000000000,%0000000000000000
	.dc.w	%0000100000000010,%0000100000000010,%0000010101010101,%0000000000000001
	.dc.w	%0000100000000010,%0000100000000010,%0000001010101011,%0000000000000001
	.dc.w	%0000100000000010,%0000100000000010,%0000010101010101,%0000000000000001
	.dc.w	%0000111111111110,%0000111111111110,%0000001010101011,%0000000000000001
	.dc.w	%0000000000000000,%0000000000000000,%0000011111111111,%0000011111111111
.endif

GRAPH_EVENT:
		move.w	d1,d0
		lsr.w	#4,d1
		andi.w	#$0F,d0				*パネルの隙間だったら無視する
		cmpi.w	#2,d0
		bls	graph_event80
		bsr	SET_GMODE			*合成モードセット
		moveq	#1,d0
		cmp.w	#3,d1				*gonlyモードなら、ドラッグ用意
		beq	graph_event90
graph_event80:
		moveq	#0,d0
graph_event90:
		rts

GRAPH_DRAG:
		moveq	#1,d0
		tst.w	MOUSE_LC(a6)
		beq	GRAPH_DRAG90
		moveq	#0,d1
		bsr	SET_GMODE
		moveq	#0,d0
GRAPH_DRAG90:
		rts


*==================================================
*スペアナモードパネル
*==================================================

SPEAMODE_PANEL:
		.dc.w	1
		.dc.w	229
		.dc.w	149
		.dc.w	205
		.dc.w	10
		.dc.w	0
		.dc.w	SPEAMODE_EVENT-SPEAMODE_PANEL
		.dc.w	0

SPEAMODE_EVENT:
		cmpi.w	#10,d1
		bhi	speamode_event10
		bsr	SPEASUM_CHG			*積分モード
		bra	speamode_event90
speamode_event10:
		cmpi.w	#27,d1
		bls	speamode_event90
		cmpi.w	#57,d1
		bhi	speamode_event20
		bsr	SPEAREV_CHG			*リバースモード
		bra	speamode_event90
speamode_event20:
		subi.w	#67,d1				*ディスプレイモード
		bcs	speamode_event90
		lsr.w	#5,d1
		ENTER	CMD_SPEAMODE_SET
speamode_event90:
		moveq	#0,d0
		rts


*==================================================
* スペアナスピードパネル
*==================================================

SPEASNS_PANEL:
		.dc.w	1
		.dc.w	229
		.dc.w	169
		.dc.w	11
		.dc.w	39
		.dc.w	SPEASNS_MAKE-SPEASNS_PANEL
		.dc.w	SPEASNS_EVENT-SPEASNS_PANEL
		.dc.w	SPEASNS_DRAG-SPEASNS_PANEL

SPEASNS_MAKE:
		movea.l	#BGADR+28*2+$80*21,a0
		bsr	put_snsbar
		rts

put_snsbar:
		move.w	#$012C,(a0)
		move.w	#$012D,$02(a0)
		move.w	#$012C,$80(a0)
		move.w	#$012D,$82(a0)
		move.w	#$012C,$100(a0)
		move.w	#$012D,$102(a0)
		move.w	#$012C,$180(a0)
		move.w	#$012D,$182(a0)
		move.w	#$012C,$200(a0)
		move.w	#$012D,$202(a0)
		rts

SPEASNS_EVENT:
		move.w	d2,d1
		lsr.w	#2,d1
		tst.b	MOUSE_LC(a6)
		bne	speasns_event10
		moveq	#4,d1
speasns_event10:
		bsr	SPEASNS_SET
		moveq	#1,d0
		rts

SPEASNS_DRAG:
		moveq	#0,d0
		tst.b	MOUSE_L(a6)
		beq	speasns_drag90
		move.w	d2,d1
		lsr.w	#2,d1
		cmp.b	SPEA_RANGE(a6),d1
		beq	speasns_drag80
		bsr	SPEASNS_SET
speasns_drag80:
		moveq	#1,d0
speasns_drag90:
		rts


*==================================================
* レベルメータスピードパネル
*==================================================

LEVELSNS_PANEL:
		.dc.w	1
		.dc.w	229
		.dc.w	241
		.dc.w	11
		.dc.w	39
		.dc.w	LEVELSNS_MAKE-LEVELSNS_PANEL
		.dc.w	LEVELSNS_EVENT-LEVELSNS_PANEL
		.dc.w	LEVELSNS_DRAG-LEVELSNS_PANEL

LEVELSNS_MAKE:
		movea.l	#BGADR+28*2+$80*30,a0
		bsr	put_snsbar
		rts

LEVELSNS_EVENT:
		move.w	d2,d1
		lsr.w	#2,d1
		tst.b	MOUSE_LC(a6)
		bne	levelsns_event10
		moveq	#4,d1
levelsns_event10:
		bsr	LEVELSNS_SET
		moveq	#1,d0
		rts

LEVELSNS_DRAG:
		moveq	#0,d0
		tst.b	MOUSE_L(a6)
		beq	levelsns_drag90
		move.w	d2,d1
		lsr.w	#2,d1
		cmp.b	LEVEL_RANGE(a6),d1
		beq	levelsns_drag80
		bsr	LEVELSNS_SET
levelsns_drag80:
		moveq	#1,d0
levelsns_drag90:
		rts


*==================================================
* トラックマスクパネル（キーボード部分）
*==================================================

TRMASK_KB_PANEL:
		.dc.w	1
		.dc.w	0
		.dc.w	0
		.dc.w	24
		.dc.w	318
		.dc.w	0
		.dc.w	TRMASK_KB_EVENT-TRMASK_KB_PANEL
		.dc.w	TRMASK_KB_DRAG-TRMASK_KB_PANEL

TRMASK_KB_EVENT:
		moveq	#0,d0
		ext.l	d2
		divu	#40,d2			*トラックマスク１つ反転
		move.w	d2,d1
		add.b	KEYB_TROFST(a6),d1
		cmpi.w	#31,d1
		bhi	trmask_kb_event90
		move.w	d1,PANEL_WORK(a6)
		ENTER	CMD_TRMASK_CHG
		moveq	#1,d0
trmask_kb_event90:
		rts

TRMASK_KB_DRAG:
		moveq	#0,d0
		tst.w	MOUSE_L(a6)
		beq	trmask_kb_drag90
		ext.l	d2
		divu	#40,d2
		move.w	d2,d1
		add.b	KEYB_TROFST(a6),d1
		cmpi.w	#31,d1
		bhi	trmask_kb_drag80
		cmp.w	PANEL_WORK(a6),d1
		beq	trmask_kb_drag80
		move.w	d1,PANEL_WORK(a6)
		ENTER	CMD_TRMASK_CHG
trmask_kb_drag80:
		moveq	#1,d0
trmask_kb_drag90:
		rts


*==================================================
* トラックマスクパネル（ＰＡＮ部分）
*==================================================

TRACKMASK_PANEL:
		.dc.w	1
		.dc.w	228
		.dc.w	288
		.dc.w	284
		.dc.w	16
		.dc.w	0
		.dc.w	TRMASK_EVENT-TRACKMASK_PANEL
		.dc.w	TRMASK_DRAG-TRACKMASK_PANEL

TRMASK_EVENT:
		sub.w	#28,d1			*マスク一括ON/OFF/REV
		bhi	trmask_event20
		moveq	#CMD_TRMASK_ALLREV,d0
		tst.b	MOUSE_RC(a6)
		bne	trmask_event10
		moveq	#CMD_TRMASK_ALLON,d0
		cmpi.w	#-14,d1
		blt	trmask_event10
		moveq	#CMD_TRMASK_ALLOFF,d0
trmask_event10:
		bsr	ENTER_CMD
		moveq	#0,d0
		bra	trmask_event90

trmask_event20:
		moveq	#0,d0
		lsr.w	#4,d1			*トラックマスク１つ反転
		add.b	LEVEL_TROFST(a6),d1
		cmpi.w	#31,d1
		bhi	trmask_event90
		move.w	d1,PANEL_WORK(a6)
		ENTER	CMD_TRMASK_CHG
		moveq	#1,d0
trmask_event90:
		rts

TRMASK_DRAG:
		moveq	#0,d0
		tst.w	MOUSE_L(a6)
		beq	trmask_drag90

		sub.w	#28,d1
		lsr.w	#4,d1
		add.b	LEVEL_TROFST(a6),d1
		cmpi.w	#31,d1
		bhi	trmask_drag80
		cmp.w	PANEL_WORK(a6),d1
		beq	trmask_drag80
		move.w	d1,PANEL_WORK(a6)
		ENTER	CMD_TRMASK_CHG
trmask_drag80:
		moveq	#1,d0
trmask_drag90:
		rts


*==================================================
* キーボードパネル
*==================================================

KEYBD_PANEL:
		.dc.w	1
		.dc.w	24
		.dc.w	0
		.dc.w	224-24
		.dc.w	318
		.dc.w	0
		.dc.w	KEYBD_EVENT-KEYBD_PANEL
		.dc.w	KEYBD_DRAG-KEYBD_PANEL

KEYBD_EVENT:
		bsr	slide_keybd
		TIME_SET
		moveq	#1,d0
		rts

KEYBD_DRAG:
		moveq	#0,d0
		tst.w	MOUSE_L(a6)
		beq	keybd_drag90
		TIME_PASS
		cmpi.w	#25,d0			*リピート間隔0.25sec
		bls	keybd_drag80
		bsr	slide_keybd
keybd_drag80:
		moveq	#1,d0
keybd_drag90:
		rts

slide_keybd:
		moveq	#CMD_KEYBD_UP,d0
		tst.b	MOUSE_L(a6)		*左クリックでup、右クリックでdown
		bne	slide_keybd10
		moveq	#CMD_KEYBD_DOWN,d0
slide_keybd10:
		bsr	ENTER_CMD
		rts


*==================================================
* レベルメータパネル
*==================================================

LEVEL_PANEL:
		.dc.w	1
		.dc.w	256
		.dc.w	232
		.dc.w	256
		.dc.w	56
		.dc.w	0
		.dc.w	LEVEL_EVENT-LEVEL_PANEL
		.dc.w	LEVEL_DRAG-LEVEL_PANEL

LEVEL_EVENT:
		moveq	#CMD_LEVELPOS_DOWN,d0
		tst.b	MOUSE_LC(a6)
		bne	level_event20
		moveq	#CMD_LEVELPOS_UP,d0
level_event20:
		bsr	ENTER_CMD
		TIME_SET
		moveq	#1,d0
		rts

LEVEL_DRAG:
		moveq	#0,d0
		tst.w	MOUSE_L(a6)
		beq	level_drag90
		TIME_PASS
		cmpi.w	#25,d0			*リピート間隔0.25sec
		bls	level_drag80
		moveq	#CMD_LEVELPOS_DOWN,d0
		tst.b	MOUSE_L(a6)
		bne	level_drag10
		moveq	#CMD_LEVELPOS_UP,d0
level_drag10:
		bsr	ENTER_CMD
level_drag80:
		moveq	#1,d0
level_drag90:
		rts


*==================================================
* ＢＧパターンパネル
*==================================================

BG_PANEL:
		.dc.w	1
		.dc.w	312
		.dc.w	72
		.dc.w	112
		.dc.w	16
		.dc.w	BG_MAKE-BG_PANEL
		.dc.w	BG_EVENT-BG_PANEL
		.dc.w	0

BG_MAKE:
		move.l	a1,-(sp)
		lea	bg_makepat(pc),a1
		movea.l	#BGADR+42*2+9*$80,a0
		move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+
		lea	bg_makepat(pc),a1
		movea.l	#BGADR+42*2+10*$80,a0
		move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+
		move.l	(sp)+,a1
		rts

bg_makepat:
		.dc.w	$0224,$0224,$0000,$0225
		.dc.w	$0225,$0000,$0226,$0226
		.dc.w	$0000,$0227,$0227,$0000

BG_EVENT:
		ext.l	d1
		divu	#24,d1
		cmpi.w	#4,d1
		bhi	bg_event90
		swap	d1			*パネルの隙間だったら無視する
		cmpi.w	#15,d1
		bhi	bg_event90
		swap	d1
		bsr	BG_SEL
bg_event90:
		moveq	#0,d0
		rts


*==================================================
* セレクタパネル
*==================================================

SEL_PANEL:
		.dc.w	1
		.dc.w	0
		.dc.w	342
		.dc.w	512
		.dc.w	154
		.dc.w	0
		.dc.w	SEL_EVENT-SEL_PANEL
		.dc.w	SEL_DRAG-SEL_PANEL

SEL_EVENT:
		subi.w	#12,d2			*タイトルエリア左側の場合
		bcs	sel_drive
		cmpi.w	#80,d1
		bcc	sel_move
		tst.b	MOUSE_LC(a6)
		bne	sel_event10
		ENTER	CMD_GO_PARENT		*右ボタンで親移動
		bra	sel_event90
sel_event10:
		cmpi.w	#52,d1
		bcc	sel_event20
		move.w	d2,d1
		lsr.w	#4,d1
		ENTER	CMD_SELECTN		*左ボタンで演奏／ディレクトリ移動
		bra	sel_event90
sel_event20:
		move.w	d2,d1
		lsr.w	#4,d1
		ENTER	CMD_DOCREADN		*左ボタンでドキュメントモード

sel_event90:
		moveq	#0,d0
		rts

sel_drive:
		cmpi.w	#6*8,d1
		bcs	sel_playdown
		cmpi.w	#10*8,d1
		bcs	sel_prog
		cmpi.w	#13*8,d1
		bcs	sel_eject
		moveq	#CMD_NEXT_DRIVE,d0	*上部表示部分の場合
		tst.b	MOUSE_LC(a6)		*左ボタンで次ドライブ移動
		bne	sel_drive10
		moveq	#CMD_PREV_DRIVE,d0	*右ボタンで前ドライブ移動
sel_drive10:
		bsr	ENTER_CMD
		moveq	#0,d0
		rts

sel_move:
		moveq	#CMD_NEXT_LINE,d0	*タイトルエリア右側の場合
		tst.b	MOUSE_L(a6)		*左ボタンでロールアップ
		bne	sel_move10
		moveq	#CMD_PREV_LINE,d0	*右ボタンでロールダウン
sel_move10:
		bsr	ENTER_CMD
*		TIME_SET
		moveq	#1,d0			*ドラッグ処理設定
		rts

sel_playdown:
		moveq	#CMD_PLAYDOWN,d0
		tst.b	MOUSE_LC(a6)
		bne	sel_playdown10
		moveq	#CMD_PLAYUP,d0
sel_playdown10:
		bsr	ENTER_CMD
		moveq	#0,d0
		rts

sel_prog:
		cmpi.w	#6*8,d1
		bcs	sel_prog90
		moveq	#CMD_PROGMODE_CHG,d0
		cmpi.w	#8*8,d1
		bcs	sel_prog10
		moveq	#CMD_PROG_CLR,d0
sel_prog10:
		bsr	ENTER_CMD
sel_prog90:
		moveq	#0,d0
		rts

sel_eject:
		ENTER	CMD_EJECT
		moveq	#0,d0
		rts

SEL_DRAG:
		moveq	#0,d0
		tst.w	MOUSE_L(a6)
		beq	sel_drag90
*		TIME_PASS
*		cmpi.w	#10,d0			*リピート間隔0.10sec
*		bls	sel_drag80
		moveq	#CMD_NEXT_LINE,d0
		tst.b	MOUSE_L(a6)
		bne	sel_drag10
		moveq	#CMD_PREV_LINE,d0
sel_drag10:
		bsr	ENTER_CMD
sel_drag80:
		moveq	#1,d0
sel_drag90:
		rts



*==================================================
* セレクタオート関係パネル
*==================================================

SELAUTO_PANEL:
		.dc.w	1
		.dc.w	0
		.dc.w	496
		.dc.w	512
		.dc.w	16
		.dc.w	0
		.dc.w	SELAUTO_EVENT-SELAUTO_PANEL
		.dc.w	SELAUTO_DRAG-SELAUTO_PANEL

SELAUTO_EVENT:
		cmpi.w	#61*8,d1
		bcc	selat_introtime
		cmpi.w	#58*8,d1
		bcc	selat_blanktime
		cmpi.w	#55*8,d1
		bcc	selat_looptime
		cmpi.w	#53*8,d1
		bcc	selat_event90
		cmpi.w	#50*8,d1
		bcc	selat_prog
		cmpi.w	#47*8,d1
		bcc	selat_alldir
		cmpi.w	#44*8,d1
		bcc	selat_intro
		cmpi.w	#41*8,d1
		bcc	selat_repeat
		cmpi.w	#39*8,d1
		bcc	selat_event90
		cmpi.w	#36*8,d1
		bcc	selat_shuffle
		cmpi.w	#33*8,d1
		bcc	selat_auto
selat_event90:
		moveq	#0,d0
		rts
selat_event_drag:
		TIME_SET
		moveq	#1,d0
		rts


selat_shuffle:
		moveq	#2,d1
		bra	selat_auto10
selat_auto:
		moveq	#1,d1
selat_auto10:
		ENTER	CMD_AUTOMODE_CHG
		bra	selat_event90

selat_repeat:
		moveq	#1,d1
		ENTER	CMD_AUTOFLAG_CHG
		bra	selat_event90

selat_intro:
		moveq	#2,d1
		ENTER	CMD_AUTOFLAG_CHG
		bra	selat_event90

selat_alldir:
		moveq	#4,d1
		ENTER	CMD_AUTOFLAG_CHG
		bra	selat_event90

selat_prog:
		moveq	#8,d1
		ENTER	CMD_AUTOFLAG_CHG
		bra	selat_event90

selat_looptime:
		clr.w	PANEL_WORK(a6)
		bsr	selauto_time
		bra	selat_event_drag

selat_blanktime:
		move.w	#1,PANEL_WORK(a6)
		bsr	selauto_time
		bra	selat_event_drag

selat_introtime:
		move.w	#2,PANEL_WORK(a6)
		bsr	selauto_time
		bra	selat_event_drag

SELAUTO_DRAG:
		moveq	#0,d1
		tst.w	MOUSE_L(a6)		*マウスが離されていたら終わる
		beq	selauto_drag90
		moveq	#1,d1
		TIME_PASS
		cmpi.w	#30,d0			*リピート間隔0.30sec
		bls	selauto_drag90
		bsr	selauto_time		*数値上下
selauto_drag90:
		move.l	d1,d0
		rts

selauto_time:
		moveq	#3,d0
		and.w	PANEL_WORK(a6),d0		*スイッチの番号と
		add.w	d0,d0
		tst.b	MOUSE_L(a6)			*マウスボタンの状態から
		beq	selauto_time10
		addq.w	#1,d0
selauto_time10:
		move.b	looptime_cmd(pc,d0.w),d0	*設定すべきコマンドを得る
		bsr	ENTER_CMD
		rts

looptime_cmd:
		dc.b	CMD_LOOPTIME_DOWN
		dc.b	CMD_LOOPTIME_UP
		dc.b	CMD_BLANKTIME_DOWN
		dc.b	CMD_BLANKTIME_UP
		dc.b	CMD_INTROTIME_DOWN
		dc.b	CMD_INTROTIME_UP
		dc.b	CMD_NOP
		dc.b	CMD_NOP
		.even

*==================================================
*グラフィックトーンパネル
*==================================================

GTONE_PANEL:
		.dc.w	1
		.dc.w	344
		.dc.w	56
		.dc.w	16
		.dc.w	8
		.dc.w	GTONE_MAKE-GTONE_PANEL
		.dc.w	GTONE_EVENT-GTONE_PANEL
		.dc.w	GTONE_DRAG-GTONE_PANEL

GTONE_MAKE:
		move.l	a1,-(sp)
		move.l	#$00060001,d1
		lea	gtone_pat(pc),a0
		movea.l	#TXTADR1+43+56*$80,a1
		bsr	PUT_PATTERN_OR
		move.l	(sp)+,a1
		rts

gtone_pat:
		.dc.w	%0000000000011000
		.dc.w	%0111111100111000
		.dc.w	%0100001001111000
		.dc.w	%0100010011111000
		.dc.w	%0100100111111000
		.dc.w	%0101001111111000
		.dc.w	%0100000000000000

GTONE_EVENT:
		bsr	gtone_move
		moveq	#1,d0
		rts

GTONE_DRAG:
		moveq	#0,d0
		tst.w	MOUSE_L(a6)
		beq	gtone_drag90
		bsr	gtone_move
		moveq	#1,d0
gtone_drag90:
		rts

gtone_move:
		tst.b	MOUSE_L(a6)
		beq	gtone_move10
		bsr	GTONE_DOWN
		bra	gtone_move90
gtone_move10:
		bsr	GTONE_UP
gtone_move90:
		rts

.if 0
*==================================================
* パレットパネル
*==================================================

PALET_PANEL:
		.dc.w	1
		.dc.w	328
		.dc.w	96
		.dc.w	80
		.dc.w	20
		.dc.w	PALET_MAKE-PALET_PANEL
		.dc.w	PALET_EVENT-PALET_PANEL
		.dc.w	PALET_DRAG-PALET_PANEL

PALET_MAKE:
		movea.l	#BGADR+44*2+12*$80,a0
		move.w	#$0B6D,(a0)
		move.w	#$0B6D,$80(a0)
		bsr	read_palet
		rts

PALET_EVENT:
		cmpi.w	#16,d1
		bhi	palet_change
		moveq	#1,d0
		move.w	#$0f,d2
		cmpi.w	#7,d1
		bhi	palet_event10
		moveq	#$10,d0
		move.w	#$f0,d2
palet_event10:
		lea	palet_block(pc),a0
		tst.b	MOUSE_LC(a6)
		bne	palet_event20
		neg.w	d0
palet_event20:
		add.w	(a0),d0
		and.w	d2,d0
		not.w	d2
		and.w	d2,(a0)
		or.w	d0,(a0)
palet_event90:
		bsr	read_palet
		moveq	#0,d0
		rts
palet_event_drag:
		TIME_SET
		moveq	#1,d0
		rts

palet_change:
		subi.w	#32,d1
		bcs	palet_event90
		moveq	#1,d0			*BLUE shift
		cmpi.w	#31,d1
		bhi	palet_change10
		moveq	#11,d0			*GREEN shift
		cmpi.w	#15,d1
		bhi	palet_change10
		moveq	#6,d0			*RED shift
palet_change10:
		move.w	d0,PANEL_WORK(a6)
		bsr	move_palet
		bra	palet_event_drag


PALET_DRAG:
		moveq	#0,d0
		tst.w	MOUSE_L(a6)
		beq	palet_drag_end
		TIME_PASS
		cmpi.w	#25,d0			*リピート間隔0.25sec
		bls	palet_drag90
		bsr	move_palet
palet_drag90:
		moveq	#1,d0
palet_drag_end:
		rts


move_palet:
		move.w	palet_block(pc),d0
		add.w	d0,d0
		movea.l	#SPPALADR,a0
		adda.w	d0,a0
		move.w	(a0),d1
		move.w	PANEL_WORK(a6),d2
		ror.w	d2,d1
		move.w	d1,d0
		andi.w	#%0_00000_00000_11111,d0
		andi.w	#%1_11111_11111_00000,d1
		addq.w	#1,d0
		tst.b	MOUSE_L(a6)		*増加／減少
		bne	move_palet10
		subq.w	#2,d0
move_palet10:
		cmpi.w	#31,d0
		bhi	move_palet20
		or.w	d0,d1
		rol.w	d2,d1
		move.w	d1,(a0)
move_palet20:
		bsr	read_palet
		rts

read_palet:
		movem.l	d0-d2/a0-a1,-(sp)
		movea.l	#SPPALADR,a1
		movea.l	#BGADR+41*2+12*$80,a0
		moveq	#2,d1
		move.w	palet_block(pc),d0
		bsr	DIGIT16
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		move.w	d0,$0B*32+$0F*2(a1)

		movea.l	#BGADR+45*2+12*$80,a1
		moveq	#2,d1
		move.w	d0,d2
		lsr.w	#1,d2			*BLUE
		move.w	d2,d0
		andi.w	#31,d0
		lea	4*2(a1),a0
		bsr	DIGIT10
		lsr.w	#5,d2			*RED
		move.w	d2,d0
		andi.w	#31,d0
		lea	(a1),a0
		bsr	DIGIT10
		lsr.w	#5,d2			*GREEN
		move.w	d2,d0
		andi.w	#31,d0
		lea	2*2(a1),a0
		bsr	DIGIT10

		movem.l	(sp)+,d0-d2/a0-a1
		rts

palet_block:	.dc.w	0
.endif


.if 0		*涙を飲んで削除・・・・(:_;)
		*重い曲だと画面にノイズがでるの
*==================================================
* パレットアニメパネル
*==================================================

ANIM_PANEL:
		.dc.w	1
		.dc.w	320
		.dc.w	104
		.dc.w	96
		.dc.w	16
		.dc.w	ANIM_MAKE-ANIM_PANEL
		.dc.w	ANIM_EVENT-ANIM_PANEL
		.dc.w	0

ANIM_MAKE:
		movea.l	#BGADR+42*2+12*$80,a0
		move.w	#$0A74,d0
		move.w	#$CA7D,d1
		moveq	#10-1,d2
anim_make10:
		move.w	d1,$80(a0)
		move.w	d0,(a0)+
		addq.w	#1,d0
		subq.w	#1,d1
		dbra	d2,anim_make10
		rts

ANIM_EVENT:
		moveq	#0,d0
		rts

.endif

		.end


-------------------------------------------------------------------------------
・ＰＡＮＥＬ処理関数の作成方法について

  パネル処理関数の先頭で、次のようなパネルテーブルを定義する。（別ソー
スの場合は先頭アドレスが PANEL.o から参照出来るように宣言しておく）そ
して、先頭アドレスをこのソース中の PANEL_TABLE に追加する。

	.xdef CONSOLE_PANEL

FUNC	macro	entry
	.dc.w	entry-CONSOLE_PANEL
	endm

CONSOLE_PANEL:
	dc.w	1			*パネル有効フラグ
	dc.w	100			*パネルの左上x座標
	dc.w	100			*     〃     y 〃
	dc.w	50			*パネルのx方向の大きさ
	dc.w	40			*   〃   y     〃
	FUNC	CONS_MAKE		*パネル描画関数
	FUNC	CONS_EVENT		*イベント処理関数
	FUNC	0			*ドラッグ処理関数(なし)

  パネル描画関数は、このテーブルに書かれている座標を元に画面を作成する
のが望ましいが、現在はパネルの移動を行なわないので、その必要はない。

  イベント処理関数は、マウスがクリックされた時に呼ばれる。この時、d1.w
にはパネルの左上からのx座標、d2.wにはy座標が入っている。イベント処理関
数内部でマウスの状態を参照する場合、以下のワークエリアが使用できる。

	MOUSE_X:	.ds.w	1	*マウスx座標
	MOUSE_Y:	.ds.w	1	*マウスy座標
	MOUSE_L:	.ds.b	1	*左ボタン状態(on:$FF off:$00)
	MOUSE_R:	.ds.b	1	*右ボタン状態(on:$FF off:$00)
	MOUSE_LC:	.ds.b	1	*左ボタンクリックフラグ(click:$FF no change:$00)
	MOUSE_RC:	.ds.b	1	*右ボタンクリックフラグ(click:$FF no change:$00)

  イベント処理関数の戻り値(d0)に0以外を指定すると、次回からはVDISP割り
込み処理が入る度にそのパネルのドラッグ処理関数が呼ばれる。ドラッグ処理
関数が d0.lに0を返せば、この状態は解除される。

  パネル描画関数及びドラッグ処理関数は省略できる(テーブルに0をおく)が、
イベント処理関数だけは実体を(たとえrtsのみでも)用意しなくてはならない。

  なお、各処理関数は、d0-d2/a0 以外のレジスタを破壊してはならない。

-------------------------------------------------------------------------------

