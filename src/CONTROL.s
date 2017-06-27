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


		.include iocscall.mac
		.include MMDSP.h
		.include CONTROL.h
		.include DRIVER.h
		.include SELECTOR.h
		.include KEYCODE.mac

IOCSKEY		.equ	$800		*IOCSのキーボードワーク


*時間経過をはかるマクロ - 1.計測開始
*	d0.w -> システムタイマー値

TIME_SET	macro
		MYONTIME
		move.w	d0,CONTROL_ONTIME(a6)
		endm

*時間経過をはかるマクロ - 2.経過チェック
*	d0.w -> (経過時間)-(目的時間)

TIME_PASS	macro	time
		MYONTIME
		sub.w	CONTROL_ONTIME(a6),d0
		endm


*==================================================
*自前の _ONTIMEサブルーチン
*	d0.w -> ONTIMEの下位ワード
*==================================================

set_myontime:
		move.w	$09d8.w,d0		*分単位ワーク
		cmp.w	ONTIME_WORK1(a6),d0
		bne	set_myontime10
		move.w	ONTIME_WORK2(a6),d0
		sub.w	$9cc.w,d0		*カウンタ値
		move.w	d0,ONTIME(a6)
		rts
set_myontime10:
		move.w	d0,ONTIME_WORK1(a6)
		mulu	#6000,d0
		add.w	$9ca.w,d0		*カウンタ初期値
		move.w	d0,ONTIME_WORK2(a6)
		sub.w	$9cc.w,d0		*カウンタ値
		move.w	d0,ONTIME(a6)
		rts

.if 0
MYONTIME:
		move.w	$09d8.w,d0		*分単位ワーク
		mulu	#6000,d0
		add.w	$9ca.w,d0		*カウンタ初期値
		sub.w	$9cc.w,d0		*カウンタ値
		rts
.endif

*IOCS_ONTIME:
*  0005314A	move.l	$09D6.w,D1
*  0005314E	cmp.l	#$05A00000,D1		*if ((d1 = work1) > 0x5a00000)
*  00053154	bcs.s	$00053158
*  00053156	moveq	#$00,D1				d1 = 0;
*  00053158	divu	#$05A0,D1		a0 = d1 / 1440;
*  0005315C	moveq	#$00,D0
*  0005315E	move.w	D1,D0
*  00053160	movea.l	D0,A0
*  00053162	swap	D1			d1 = (d1 % 1440)*6000
*  00053164	mulu	#$1770,D1
*  00053168	move.w	$09CA.w,D0		d0 = (work2-work3) + d1
*  0005316C	sub.w	$09CC.w,D0
*  00053170	add.l	D1,D0
*  00053172	move.l	A0,D1
*  00053174	rts


*==================================================
*MMDSP コントロールルーチン
*==================================================

CONTROL:
		bsr	set_myontime

control_key:
		bsr	EXEC_CMD		*パネルコマンドを実行する
		clr.w	NOWKEY(a6)

control_hotkey:
		tst.b	RESIDENT(a6)		*常駐モードで
		beq	control_hotkey90
		movea.w	HOTKEY1ADR(a6),a0	*起動キーが押されていたら
		move.b	(a0),d0
		cmp.b	HOTKEY1MASK(a6),d0
		bne	control_hotkey80
		movea.w	HOTKEY2ADR(a6),a0
		move.b	(a0),d0
		cmp.b	HOTKEY2MASK(a6),d0
		bne	control_hotkey80
		tst.b	HOTKEY_FLAG(a6)		*起動時からまだ離されていないなら待つ
		bne	control_hotkey90
		st.b	HOTKEY_FLAG(a6)
		move.w	#-1,QUIT_FLAG(a6)	*２度目に押されたならば終了
		bra	control90
control_hotkey80:
		clr.b	HOTKEY_FLAG(a6)
control_hotkey90:

control_key10:
		IOCS	_B_KEYSNS		*最後に押されたキーを調べる
		btst.l	#$10,d0
		beq	control_key20
		IOCS	_B_KEYINP
		tst.w	d0
		bmi	control_key10
		move.w	d0,NOWKEY(a6)
		bra	control_key10
control_key20:
		tst.w	DRUG_KEY(a6)		*ドラッグ中ならドラッグ処理をする
		beq	control_key30
		bsr	exec_drug
		bra	control_key90
control_key30:
		move.w	NOWKEY(a6),d1		*そうでないならキーコマンドを実行する
		beq	control_key90
		bsr	check_shift
		exg	d0,d1
		bsr	get_keycmd
		bmi	control_key90
		bsr	ENTER_CMD
		bsr	EXEC_CMD
		bsr	MOUSE_ERASE
control_key90:

control90:
		rts


*==================================================
*キーボードコマンド調査
*	d0.w <- _B_KEYINPの返り値
*	d1.b <- シフトキー状態
*	d0.w -> MMDSPコマンド番号(負ならエラー)
*	d1.w -> 引数
*==================================================

get_keycmd:
		move.l	a0,-(sp)
		tst.w	d0			*キー離しコードの場合は何もしない
		bmi	get_keycmd90
		andi.w	#$7f00,d0
		lsr.w	#8,d0
		mulu	#18,d0
		lea	KEY_TABLE(a6),a0
		lea	(a0,d0.w),a0
		tst.b	d1			*シフトキーの状態によって
		beq	get_keycmd20
get_keycmd10:
		addq.l	#2,a0			*テーブルの読む位置を変える
		lsr.b	#1,d1
		bcc	get_keycmd10
		beq	get_keycmd20		*２つ以上のシフトキーには対応していない
		moveq	#-1,d0
		bra	get_keycmd90
get_keycmd20:
		move.b	(a0)+,d0		*コマンドコードを読み出す
		ext.w	d0
		moveq	#0,d1
		move.b	(a0),d1
get_keycmd90:
		move.l	(sp)+,a0
		rts


*==================================================
*シフトキー状態調査
*	d0.b -> シフトキー状態
*		bit0:OPT1 n:XFn 6:SHIFT 7:CTRL
*==================================================

check_shift:
		move.l	d1,-(sp)
		move.b	IOCSKEY+$a.w,d1		*XF1-3
		andi.b	#%11100000,d1
		lsr.b	#4,d1
		move.b	IOCSKEY+$b.w,d0		*XF4-5
		andi.b	#%00000011,d0
		lsl.b	#4,d0
		or.b	d0,d1
		move.b	IOCSKEY+$e.w,d0		*OPT1
		btst.l	#2,d0
		beq	check_shift10
		bset.l	#0,d1
check_shift10:
		andi.b	#%00000011,d0		*SHIFT,CTRL
		lsl.b	#6,d0
		or.b	d0,d1
		move.b	d1,d0
		move.l	(sp)+,d1
		rts


*==================================================
*現在押されているキーをドラッグモードにする
*	d0.l <- ドラッグ中に呼ばれるルーチン(ないなら0)
*	a0.l <- ドラッグ解除時に呼ばれるルーチン(ないなら0)
*==================================================

set_drugmode:
		move.l	d1,-(sp)
		move.l	DRUG_OFFFUNC(a6),d1	*ドラッグ中のキーが有ったら
		beq	set_drugmode10
		movem.l	d0/a0,-(sp)
		movea.l	d1,a0			*解除ルーチンを呼ぶ
		jsr	(a0)
		movem.l	(sp)+,d0/a0
set_drugmode10:
		clr.w	DRUG_KEY(a6)		*初期化しておく
		clr.l	DRUG_ONFUNC(a6)
		clr.l	DRUG_OFFFUNC(a6)
		move.w	NOWKEY(a6),d1		*今のキーが有効だったら
		ble	set_drugmode90
		move.w	d1,DRUG_KEY(a6)		*モードをセットする
		move.l	d0,DRUG_ONFUNC(a6)
		move.l	a0,DRUG_OFFFUNC(a6)
set_drugmode90:
		move.l	(sp)+,d1
		rts


*==================================================
*ドラッグモードの処理
*==================================================

exec_drug:
		movem.l	d0-d1/a0,-(sp)
		move.b	DRUG_KEY(a6),d0		*キーが押されているか調べる
		beq	exec_drug90
		andi.w	#$007f,d0
		move.w	d0,d1
		lsr.w	#3,d1
		andi.w	#7,d0
		lea	IOCSKEY.w,a0
		btst.b	d0,(a0,d1.w)
		beq	exec_drug10
		move.l	DRUG_ONFUNC(a6),d0	*押されていたら
		beq	exec_drug90
		movea.l	d0,a0
		jsr	(a0)			*ドラッグ中実行ルーチンを呼ぶ
		bra	exec_drug90
exec_drug10:
		move.l	DRUG_OFFFUNC(a6),d0	*離されていたら
		beq	exec_drug20
		movea.l	d0,a0
		jsr	(a0)			*ドラッグ終了ルーチンを呼び
exec_drug20:
		clr.w	DRUG_KEY(a6)		*ドラッグワークをクリアする
		clr.l	DRUG_ONFUNC(a6)
		clr.l	DRUG_OFFFUNC(a6)
exec_drug90:
		movem.l	(sp)+,d0-d1/a0
		rts


*==================================================
*コマンドをバッファに登録
*	d0.w <- コマンドコード
*	d1.l <- 引数
*==================================================

ENTER_CMD:
		cmpi.w	#CMD_MAX,d0
		bcc	enter_cmd90
		move.w	d0,MMDSP_CMD(a6)
		move.l	d1,CMD_ARG(a6)
enter_cmd90:
		rts


*==================================================
*登録されているコマンドをクリア
*==================================================

CLEAR_CMD:
		bsr	CLEAR_KEYBUF
		clr.w	MMDSP_CMD(a6)
		rts


*==================================================
*キーバッファクリア
*==================================================

CLEAR_KEYBUF:
		move.l	d0,-(sp)
clear_keybuf10:
		IOCS	_B_KEYSNS
		tst.l	d0
		beq	clear_keybuf90
		IOCS	_B_KEYINP
		bra	clear_keybuf10
clear_keybuf90:
		move.l	(sp)+,d0
		rts


*==================================================
*コマンドを実行
*==================================================

EXEC_CMD:
		movem.l	d0-d1,-(sp)
		move.w	MMDSP_CMD(a6),d0
		bmi	exec_cmd90
		move.w	#-1,MMDSP_CMD(a6)
		move.l	CMD_ARG(a6),d1
		add.w	d0,d0
		move.w	FUNC_TABLE(pc,d0.w),d0
		jsr	FUNC_TABLE(pc,d0.w)
exec_cmd90:
		movem.l	(sp)+,d0-d1
		rts

FUNC		macro	label
		dc.w	label-FUNC_TABLE
		endm

FUNC_TABLE:
		FUNC	EXEC_NOP
		FUNC	EXEC_NEXT_DRIVE		*セレクタ関係
		FUNC	EXEC_PREV_DRIVE
		FUNC	EXEC_EJECT
		FUNC	EXEC_DATAWRITE
		FUNC	EXEC_DOCREAD
		FUNC	EXEC_DOCREADN
		FUNC	EXEC_GO_PARENT
		FUNC	EXEC_GO_ROOT
		FUNC	EXEC_NEXT_PAGE
		FUNC	EXEC_PREV_PAGE
		FUNC	EXEC_ROLL_UP
		FUNC	EXEC_ROLL_DOWN
		FUNC	EXEC_NEXT_LINE
		FUNC	EXEC_PREV_LINE
		FUNC	EXEC_NEXT_LINE_K
		FUNC	EXEC_PREV_LINE_K
		FUNC	EXEC_SELECT
		FUNC	EXEC_SELECTN
		FUNC	EXEC_PLAYDOWN
		FUNC	EXEC_PLAYUP
		FUNC	EXEC_CLEAR_SEL
		FUNC	EXEC_TOP_LINE
		FUNC	EXEC_BOTOM_LINE
		FUNC	AUTOMODE_CHG
		FUNC	AUTOMODE_SET
		FUNC	AUTOFLAG_CHG
		FUNC	AUTOFLAG_SET
		FUNC	LOOPTIME_UP
		FUNC	LOOPTIME_DOWN
		FUNC	LOOPTIME_SET
		FUNC	BLANKTIME_UP
		FUNC	BLANKTIME_DOWN
		FUNC	BLANKTIME_SET
		FUNC	INTROTIME_UP
		FUNC	INTROTIME_DOWN
		FUNC	INTROTIME_SET
		FUNC	PROGMODE_CHG
		FUNC	PROGMODE_SET
		FUNC	PROG_CLR
		FUNC	EXEC_PLAY		*コンソールパネル
		FUNC	EXEC_PAUSE
*		FUNC	EXEC_CONT
		FUNC	EXEC_STOP
		FUNC	EXEC_FADE
		FUNC	EXEC_SKIP
		FUNC	EXEC_SLOW
		FUNC	EXEC_SKIPK
		FUNC	EXEC_SLOWK
		FUNC	EXEC_QUIT
		FUNC	EXEC_GMODE		*グラフィックパネル
		FUNC	GTONE_UP		*グラフィックトーンパネル
		FUNC	GTONE_DOWN
		FUNC	GTONE_SET
		FUNC	GHOME
		FUNC	GMOVE_U
		FUNC	GMOVE_D
		FUNC	GMOVE_L
		FUNC	GMOVE_R
		FUNC	SPEASNS_UP		*スペアナスピード
		FUNC	SPEASNS_DOWN
		FUNC	SPEASNS_SET
		FUNC	SPEAMODE_UP		*スペアナモード
		FUNC	SPEAMODE_DOWN
		FUNC	SPEAMODE_SET
		FUNC	SPEASUM_CHG		*スペアナ積分
		FUNC	SPEASUM_SET
		FUNC	SPEAREV_CHG		*スペアナリバース
		FUNC	SPEAREV_SET
		FUNC	LEVELSNS_UP		*レベルメータスピード
		FUNC	LEVELSNS_DOWN
		FUNC	LEVELSNS_SET
		FUNC	TRMASK_CHG		*トラックマスクパネル
		FUNC	TRMASK_ALLON
		FUNC	TRMASK_ALLOFF
		FUNC	TRMASK_ALLREV
		FUNC	KEYBD_UP		*キーボードパネル
		FUNC	KEYBD_DOWN
		FUNC	KEYBD_SET
		FUNC	LEVELPOS_UP		*レベルメータパネル
		FUNC	LEVELPOS_DOWN
		FUNC	LEVELPOS_SET
		FUNC	BG_SEL			*ＢＧパネル

EXEC_NOP:
		rts

EXEC_NEXT_DRIVE:
		move.w	#SEL_NEXTDRV,SEL_CMD(a6)
		rts

EXEC_PREV_DRIVE:
		move.w	#SEL_PREVDRV,SEL_CMD(a6)
		rts

EXEC_EJECT:
		move.w	#SEL_EJECT,SEL_CMD(a6)
		rts

EXEC_DATAWRITE:
		move.w	#SEL_DATAWRITE,SEL_CMD(a6)
		rts

EXEC_DOCREAD:
		move.w	#SEL_DOCREAD,SEL_CMD(a6)
		rts

EXEC_DOCREADN:
		move.w	#SEL_DOCREADN,SEL_CMD(a6)
		move.w	d1,SEL_ARG(a6)
		rts

EXEC_GO_PARENT:
		move.w	#SEL_PARENT,SEL_CMD(a6)
		rts

EXEC_GO_ROOT:
		move.w	#SEL_ROOT,SEL_CMD(a6)
		rts

EXEC_NEXT_PAGE:
		move.w	#SEL_NEXTPAGE,SEL_CMD(a6)
		rts

EXEC_PREV_PAGE:
		move.w	#SEL_PREVPAGE,SEL_CMD(a6)
		rts

EXEC_ROLL_UP:
		move.w	#SEL_ROLLUP,SEL_CMD(a6)
		rts

EXEC_ROLL_DOWN:
		move.w	#SEL_ROLLDOWN,SEL_CMD(a6)
		rts

EXEC_NEXT_LINE:
		move.w	#SEL_DOWN,SEL_CMD(a6)
		rts

EXEC_PREV_LINE:
		move.w	#SEL_UP,SEL_CMD(a6)
		rts

EXEC_NEXT_LINE_K:
		move.w	#SEL_DOWN,SEL_CMD(a6)
		move.w	#25,CONTROL_WORK(a6)
		TIME_SET
		moveq	#0,d0
		lea	exec_next_linek1(pc),a0
		exg	a0,d0
		bra	set_drugmode
exec_next_linek1:
		TIME_PASS			*0.05secごとに
		cmp.w	CONTROL_WORK(a6),d0
		bls	exec_next_linek0
		move.w	#SEL_DOWN,SEL_CMD(a6)
		move.w	#2,CONTROL_WORK(a6)
		TIME_SET
exec_next_linek0:
		rts

EXEC_PREV_LINE_K:
		move.w	#SEL_UP,SEL_CMD(a6)
		move.w	#25,CONTROL_WORK(a6)
		TIME_SET
		moveq	#0,d0
		lea	exec_prev_linek1(pc),a0
		exg	a0,d0
		bra	set_drugmode
exec_prev_linek1:
		TIME_PASS			*0.05secごとに
		cmp.w	CONTROL_WORK(a6),d0
		bls	exec_prev_linek0
		move.w	#SEL_UP,SEL_CMD(a6)
		move.w	#2,CONTROL_WORK(a6)
		TIME_SET
exec_prev_linek0:
		rts


EXEC_SELECT:
		move.w	#SEL_SEL,SEL_CMD(a6)
		rts

EXEC_SELECTN:
		move.w	#SEL_SELN,SEL_CMD(a6)
		move.w	d1,SEL_ARG(a6)
		rts

EXEC_PLAYDOWN:
		move.w	#SEL_PLAYDOWN,SEL_CMD(a6)
		rts

EXEC_PLAYUP:
		move.w	#SEL_PLAYUP,SEL_CMD(a6)
		rts

EXEC_CLEAR_SEL:
		move.w	#SEL_CLEAR,SEL_CMD(a6)
		rts

EXEC_TOP_LINE:
		move.w	#SEL_TOP,SEL_CMD(a6)
		rts

EXEC_BOTOM_LINE:
		move.w	#SEL_BOTOM,SEL_CMD(a6)
		rts

EXEC_PLAY:
		bsr	CLEAR_KEYON
		DRIVER	DRIVER_PLAY
		bsr	CLEAR_PASSTM
		move.w	#-1,PLAY_FLAG(a6)
		rts

EXEC_PAUSE:
		tst.w	PLAY_FLAG(a6)
		beq	EXEC_CONT
		DRIVER	DRIVER_PAUSE
		clr.w	PLAY_FLAG(a6)
		rts

EXEC_CONT:
		DRIVER	DRIVER_CONT
		move.w	#-1,PLAY_FLAG(a6)
		rts

EXEC_STOP:
		clr.w	PLAY_FLAG(a6)
		DRIVER	DRIVER_STOP
		rts

EXEC_FADE:
		DRIVER	DRIVER_FADEOUT
		rts

EXEC_SKIP:
		move.l	d1,d0
		DRIVER	DRIVER_SKIP
		rts

EXEC_SKIPK:
		moveq	#1,d0
		DRIVER	DRIVER_SKIP
		TIME_SET
		lea	exec_skipk1(pc),a0
		move.l	a0,d0
		lea	exec_skipk0(pc),a0
		bra	set_drugmode
exec_skipk0:
		moveq	#0,d0
		DRIVER	DRIVER_SKIP
		rts
exec_skipk1:
		TIME_PASS			*0.05secごとに
		cmpi.w	#05,d0
		bls	exec_skip1_90
		moveq	#1,d0			*早送りをかけ直す
		DRIVER	DRIVER_SKIP
		TIME_SET
exec_skip1_90:
		rts

EXEC_SLOW:
		move.l	d1,d0
		DRIVER	DRIVER_SLOW
		rts

EXEC_SLOWK:
		moveq	#1,d0
		DRIVER	DRIVER_SLOW
		TIME_SET
		lea	exec_slowk1(pc),a0
		move.l	a0,d0
		lea	exec_slowk0(pc),a0
		bra	set_drugmode
exec_slowk0:
		moveq	#0,d0
		DRIVER	DRIVER_SLOW
		rts
exec_slowk1:
		TIME_PASS			*0.05secごとに
		cmpi.w	#05,d0
		bls	exec_slow1_90
		moveq	#1,d0			*スローをかけ直す
		DRIVER	DRIVER_SLOW
		TIME_SET
exec_slow1_90
		rts

EXEC_QUIT:
		tst.b	SEL_VIEWMODE(a6)	*超暫定的解決(^^;)
		bne	EXEC_GO_PARENT
		move.w	#-1,QUIT_FLAG(a6)
		rts

EXEC_GMODE:
		bra	SET_GMODE


.if 0		*ＢＧ表示位置実験用
BGADR		equ	$EBC000				*ＢＧアドレス
BGX		equ	$eb080a

BGX_UP:
		move.w	BGX,d0
		addq.w	#1,d0
		bra	dispbgx
BGX_DOWN:
		move.w	BGX,d0
		subq.w	#1,d0

dispbgx:
		move.w	d0,BGX
		movea.l	#BGADR+40*2+80*$80,a0
		move.w	BGX,d0
		bsr	PRINT16_4KETA
		rts
.endif

*==================================================
*デフォルトキーボード定義
*==================================================

BIND_DEFAULT:
		movem.l	d0/a0-a1,-(sp)
		bsr	CLEAR_KEYBIND
		lea	DEFAULT_KEYTBL(pc),a0
		lea	KEY_TABLE(a6),a1
bind_default10:
		move.w	(a0)+,d0
		beq	bind_default90
		move.b	(a0)+,(a1,d0.w)
		move.b	(a0)+,1(a1,d0.w)
		bra	bind_default10
bind_default90:
		movem.l	(sp)+,d0/a0-a1
		rts


*==================================================
*キーバインド初期化
*==================================================

CLEAR_KEYBIND:
		movem.l	d0-d1/a0,-(sp)
		lea	KEY_TABLE(a6),a0
		moveq	#128/2-1,d1
		moveq	#-1,d0
clear_keybind10:
		move.l	d0,(a0)+		*キー２個分クリア
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		dbra	d1,clear_keybind10
		movem.l	(sp)+,d0-d1/a0
		rts


*==================================================
*デフォルトキーテーブル
*==================================================

NORMAL		.equ	0
OPT1		.equ	1
XF1		.equ	2
XF2		.equ	3
XF3		.equ	4
XF4		.equ	5
XF5		.equ	6
SHIFT		.equ	7
CTRL		.equ	8

KEYDEF		macro	shift,key,cmd,param
		.dc.w	key*18+shift*2
		.dc.b	cmd
		.dc.b	param
		endm

KEYEND		macro
		.dc.w	0
		endm

		.even

DEFAULT_KEYTBL:
		KEYDEF	NORMAL,__ESC,CMD_QUIT,0			*QUIT
		KEYDEF	NORMAL,__｀４,CMD_PREV_DRIVE,0		*PREV_DRIVE
		KEYDEF	NORMAL,__LEFT,CMD_PREV_DRIVE,0
		KEYDEF	NORMAL,__｀６,CMD_NEXT_DRIVE,0		*NEXT_DRIVE
		KEYDEF	NORMAL,__RIGHT,CMD_NEXT_DRIVE,0
		KEYDEF	NORMAL,__BREAK,CMD_EJECT,0		*EJECT
		KEYDEF	NORMAL,__登録,CMD_DATAWRITE,0		*DATAWRITE
		KEYDEF	NORMAL,__TAB,CMD_DOCREAD,0
		KEYDEF	NORMAL,__CLR,CMD_CLEAR_SEL,0		*CLEAR_SEL
		KEYDEF	NORMAL,__｀０,CMD_GO_PARENT,0		*GO_PARENT
		KEYDEF	NORMAL,__｀．,CMD_GO_PARENT,0
		KEYDEF	NORMAL,__UNDO,CMD_GO_PARENT,0
		KEYDEF	NORMAL,__BS,CMD_GO_PARENT,0
		KEYDEF	NORMAL,__￥,CMD_GO_ROOT,0		*GO_ROOT
		KEYDEF	NORMAL,__｀８,CMD_PREV_LINE_K,0		*PREV_LINE
		KEYDEF	NORMAL,__UP,CMD_PREV_LINE_K,0
		KEYDEF	NORMAL,__｀２,CMD_NEXT_LINE_K,0		*NEXT_LINE
		KEYDEF	NORMAL,__DOWN,CMD_NEXT_LINE_K,0
		KEYDEF	NORMAL,__RUP,CMD_NEXT_PAGE,0		*NEXT_PAGE
		KEYDEF	NORMAL,__RDOWN,CMD_PREV_PAGE,0		*PREV_PAGE
		KEYDEF	NORMAL,__HOME,CMD_TOP_LINE,0		*TOP_LINE
		KEYDEF	NORMAL,__F1,CMD_TOP_LINE,0
		KEYDEF	NORMAL,__｀／,CMD_TOP_LINE,0
		KEYDEF	NORMAL,__DEL,CMD_BOTOM_LINE,0		*BOTOM_LINE
		KEYDEF	NORMAL,__F2,CMD_BOTOM_LINE,0
		KEYDEF	NORMAL,__｀＊,CMD_BOTOM_LINE,0
		KEYDEF	NORMAL,__CR,CMD_SELECT,0		*SELECT
		KEYDEF	NORMAL,__ENTER,CMD_SELECT,0		*SELECT
		KEYDEF	NORMAL,__SPACE,CMD_PLAYDOWN,0		*PLAYDOWN
		KEYDEF	NORMAL,__BS,CMD_PLAYUP,0		*PLAYUP
		KEYDEF	NORMAL,__A,CMD_AUTOMODE_CHG,1
		KEYDEF	NORMAL,__S,CMD_AUTOMODE_CHG,2
		KEYDEF	NORMAL,__＠,CMD_PROG_CLR,0
		KEYDEF	NORMAL,__P,CMD_PROGMODE_CHG,0
		KEYDEF	NORMAL,__Z,CMD_AUTOFLAG_CHG,1
		KEYDEF	NORMAL,__X,CMD_AUTOFLAG_CHG,2
		KEYDEF	NORMAL,__C,CMD_AUTOFLAG_CHG,4
		KEYDEF	NORMAL,__V,CMD_AUTOFLAG_CHG,8
		KEYDEF	NORMAL,__；,CMD_LOOPTIME_UP,0
		KEYDEF	NORMAL,__．,CMD_LOOPTIME_DOWN,0
		KEYDEF	NORMAL,__：,CMD_BLANKTIME_UP,0
		KEYDEF	NORMAL,__／,CMD_BLANKTIME_DOWN,0
		KEYDEF	NORMAL,__］,CMD_INTROTIME_UP,0
		KEYDEF	NORMAL,__＿,CMD_INTROTIME_DOWN,0
		KEYDEF	NORMAL,__F6,CMD_PLAY,0			*PLAY
		KEYDEF	NORMAL,__F7,CMD_PAUSE,0			*PAUSE
		KEYDEF	NORMAL,__F8,CMD_FADE,0			*FADE
		KEYDEF	NORMAL,__F9,CMD_SLOWK,0			*SLOW
		KEYDEF	NORMAL,__F10,CMD_SKIPK,0		*SKIP
		KEYDEF	CTRL,__F6,CMD_GMODE,0			*GMODE0
		KEYDEF	CTRL,__F7,CMD_GMODE,1			*GMODE1
		KEYDEF	CTRL,__F8,CMD_GMODE,2			*GMODE2
		KEYDEF	CTRL,__F9,CMD_GMODE,3			*GMODE3
		KEYDEF	CTRL,__F10,CMD_GMODE,4			*GMODE4
		KEYDEF	CTRL,__RDOWN,CMD_GTONE_UP,0		*GTONE_UP
		KEYDEF	CTRL,__RUP,CMD_GTONE_DOWN,0		*GTONE_DOWN
		KEYDEF	CTRL,__UNDO,CMD_GTONE_SET,16		*GTONE_SET
		KEYDEF	CTRL,__HOME,CMD_GHOME,0			*GHOME
		KEYDEF	CTRL,__UP,CMD_GMOVE_U,0			*GMOVE_U
		KEYDEF	CTRL,__DOWN,CMD_GMOVE_D,0		*GMOVE_D
		KEYDEF	CTRL,__LEFT,CMD_GMOVE_L,0		*GMOVE_L
		KEYDEF	CTRL,__RIGHT,CMD_GMOVE_R,0		*GMOVE_R
		KEYDEF	SHIFT,__F6,CMD_BG_SEL,0			*BG_SEL0
		KEYDEF	SHIFT,__F7,CMD_BG_SEL,1			*BG_SEL1
		KEYDEF	SHIFT,__F8,CMD_BG_SEL,2			*BG_SEL2
		KEYDEF	SHIFT,__F9,CMD_BG_SEL,3			*BG_SEL3
		KEYDEF	SHIFT,__F10,CMD_BG_SEL,4		*BG_SEL4
		KEYDEF	SHIFT,__RUP,CMD_KEYBD_UP,0		*KEYBD_UP
		KEYDEF	SHIFT,__RDOWN,CMD_KEYBD_DOWN,0		*KEYBD_DOWN
		KEYDEF	SHIFT,__HOME,CMD_KEYBD_SET,0		*KEYBD_DOWN
		KEYDEF	SHIFT,__DEL,CMD_KEYBD_SET,24		*KEYBD_DOWN
		KEYDEF	XF1,__UP,CMD_SPEASNS_UP,0		*SPEASNS_UP
		KEYDEF	XF1,__DOWN,CMD_SPEASNS_DOWN,0		*SPEASNS_DOWN
		KEYDEF	XF1,__UNDO,CMD_SPEASNS_SET,4		*SPEASNS_SET
		KEYDEF	XF1,__RIGHT,CMD_SPEAMODE_UP,0		*SPEAMODE_UP
		KEYDEF	XF1,__LEFT,CMD_SPEAMODE_DOWN,0		*SPEAMODE_DOWN
		KEYDEF	XF1,__DEL,CMD_SPEASUM_CHG,4		*SPEASUM_CHG
		KEYDEF	XF1,__HOME,CMD_SPEAREV_CHG,4		*SPEAREV_CHG
		KEYDEF	XF2,__RIGHT,CMD_LEVELPOS_UP,0		*LEVELPOS_UP
		KEYDEF	XF2,__LEFT,CMD_LEVELPOS_DOWN,0		*LEVELPOS_DOWN
		KEYDEF	XF2,__HOME,CMD_LEVELPOS_SET,0		*LEVELPOS_SET0
		KEYDEF	XF2,__DEL,CMD_LEVELPOS_SET,16		*LEVELPOS_SET16
		KEYDEF	XF2,__UP,CMD_LEVELSNS_UP,0		*LEVELSNS_UP
		KEYDEF	XF2,__DOWN,CMD_LEVELSNS_DOWN,0		*LEVELSNS_DOWN
		KEYDEF	XF2,__UNDO,CMD_LEVELSNS_SET,4		*LEVELSNS_SET
		KEYDEF	NORMAL,__1,CMD_TRMASK_CHG,0		*TRMASK_CHG0
		KEYDEF	NORMAL,__2,CMD_TRMASK_CHG,1		*TRMASK_CHG1
		KEYDEF	NORMAL,__3,CMD_TRMASK_CHG,2		*TRMASK_CHG2
		KEYDEF	NORMAL,__4,CMD_TRMASK_CHG,3		*TRMASK_CHG3
		KEYDEF	NORMAL,__5,CMD_TRMASK_CHG,4		*TRMASK_CHG4
		KEYDEF	NORMAL,__6,CMD_TRMASK_CHG,5		*TRMASK_CHG5
		KEYDEF	NORMAL,__7,CMD_TRMASK_CHG,6		*TRMASK_CHG6
		KEYDEF	NORMAL,__8,CMD_TRMASK_CHG,7		*TRMASK_CHG7
		KEYDEF	XF3,__1,CMD_TRMASK_CHG,8		*TRMASK_CHG8
		KEYDEF	XF3,__2,CMD_TRMASK_CHG,9		*TRMASK_CHG9
		KEYDEF	XF3,__3,CMD_TRMASK_CHG,10		*TRMASK_CHG10
		KEYDEF	XF3,__4,CMD_TRMASK_CHG,11		*TRMASK_CHG11
		KEYDEF	XF3,__5,CMD_TRMASK_CHG,12		*TRMASK_CHG12
		KEYDEF	XF3,__6,CMD_TRMASK_CHG,13		*TRMASK_CHG13
		KEYDEF	XF3,__7,CMD_TRMASK_CHG,14		*TRMASK_CHG14
		KEYDEF	XF3,__8,CMD_TRMASK_CHG,15		*TRMASK_CHG15
		KEYDEF	XF4,__1,CMD_TRMASK_CHG,16		*TRMASK_CHG16
		KEYDEF	XF4,__2,CMD_TRMASK_CHG,17		*TRMASK_CHG17
		KEYDEF	XF4,__3,CMD_TRMASK_CHG,18		*TRMASK_CHG18
		KEYDEF	XF4,__4,CMD_TRMASK_CHG,19		*TRMASK_CHG19
		KEYDEF	XF4,__5,CMD_TRMASK_CHG,20		*TRMASK_CHG20
		KEYDEF	XF4,__6,CMD_TRMASK_CHG,21		*TRMASK_CHG21
		KEYDEF	XF4,__7,CMD_TRMASK_CHG,22		*TRMASK_CHG22
		KEYDEF	XF4,__8,CMD_TRMASK_CHG,23		*TRMASK_CHG23
		KEYDEF	XF5,__1,CMD_TRMASK_CHG,24		*TRMASK_CHG24
		KEYDEF	XF5,__2,CMD_TRMASK_CHG,25		*TRMASK_CHG25
		KEYDEF	XF5,__3,CMD_TRMASK_CHG,26		*TRMASK_CHG26
		KEYDEF	XF5,__4,CMD_TRMASK_CHG,27		*TRMASK_CHG27
		KEYDEF	XF5,__5,CMD_TRMASK_CHG,28		*TRMASK_CHG28
		KEYDEF	XF5,__6,CMD_TRMASK_CHG,29		*TRMASK_CHG29
		KEYDEF	XF5,__7,CMD_TRMASK_CHG,30		*TRMASK_CHG30
		KEYDEF	XF5,__8,CMD_TRMASK_CHG,31		*TRMASK_CHG31
		KEYDEF	NORMAL,__9,CMD_TRMASK_ALLON,0		*TRMASK_ALLON
		KEYDEF	NORMAL,__0,CMD_TRMASK_ALLOFF,0		*TRMASK_ALLOFF
		KEYDEF	NORMAL,__－,CMD_TRMASK_ALLREV,0		*TRMASK_ALLREV
*		KEYDEF	NORMAL,__｀＋,CMD_BGX_UP,0
*		KEYDEF	NORMAL,__｀－,CMD_BGX_DOWN,0
		KEYEND
		.text
		.end
