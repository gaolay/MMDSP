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
		.include	SELECTOR.h
		.include	DRIVER.h
		.include	FILES.h


INIT_MODE	equ	0				*セレクタステータス値
KENS_MODE	equ	1
FSEL_MODE	equ	2
IDLE_MODE	equ	3

			.text
			.even


*==================================================
*セレクタ初期化
*==================================================

SELECTOR_INIT:
		rts

*==================================================
*セレクター画面を作る
*==================================================

SELECTOR_MAKE:
		movem.l	d0-d2/a0-a1,-(sp)

		movea.l	#BGADR+0*2+43*$80,a0		*上部バー
		move.w	#$16d,d0
		moveq.l	#63,d1
		bsr	BG_LINE

		movea.l	#BGADR+5*2+42*$80,a1		*上部スイッチを描く
		lea	switch_chr1u(pc),a0
		move.w	#$0100,d0
		bsr	BG_PRINT
		lea	$80(a1),a1
		lea	switch_chr1d(pc),a0
		bsr	BG_PRINT

		moveq	#0,d1
		bsr	PROGMODE_SET

		movea.l	#BGADR+0*2+45*$80,a0		*点線
		move.w	#$16f,d0
		moveq.l	#63,d1
		moveq.l	#8,d2
selector_make10:
		bsr	BG_LINE
		lea.l	$100(a0),a0
		dbra	d2,selector_make10

		move.l	#BGADR2+0*2+62*$80,a0		*下部バー
		move.w	#$16c,d0
		moveq.l	#63,d1
		bsr	BG_LINE
		lea.l	$80(a0),a0
		move.w	#$16d,d0
		bsr	BG_LINE

		movea.l	#BGADR2+32*2+62*$80,a1		*下部スイッチを描く
		lea	switch_chr2(pc),a0
		move.w	#$0100,d0
		bsr	BG_PRINT
		lea	$80(a1),a1
		move.w	#$0101,d0
		bsr	BG_PRINT

		moveq	#1,d1
		bsr	LOOPTIME_SET

		moveq	#2,d1
		bsr	BLANKTIME_SET

		moveq	#10,d1
		bsr	INTROTIME_SET

		move.l	#$00020002,d0			*ＳＥＬＥＣＴＯＲの文字
		move.l	#9*$10000+9,d1
		lea.l	STITLE(pc),a0
		move.l	#TXTADR+0+(499+1)*$80,a1
		bsr	PUT_PATTERN

		lea.l	FILESEL_MES(pc),a0		*テキストの文字表示
		bsr	TEXT48AUTO

		bsr	INIT_FNAMEBUF
		clr.b	DRV_TBLFLAG(a6)

		lea.l	G_MES_DEF(pc),a0		*デフォルトのメッセージを表示する
		bsr	G_MESSAGE_PRT2
		clr.w	G_MES_FLAG(a6)

		tst.b	SEL_NOUSE(a6)			*セレクタ無使用モードなら
		beq	selector_make80
		move.w	#IDLE_MODE,SEL_CHANGE(a6)	*アイドリングルーチンセット
		bra	selector_make90

selector_make80:
		move.b	AUTOMODE(a6),d1
		bsr	AUTOMODE_SET
		move.b	AUTOFLAG(a6),d1
		bsr	AUTOFLAG_SET

selector_make90:
		movem.l	(sp)+,d0-d2/a0-a1
		rts

*スイッチのBGキャラ
*__ST		equ	$74	't' 'u'
*__ED		equ	$76	'v' 'w'
*__SP		equ	$6C	'l' 'm'
*__ST2		equ	$2e	'.'
*__ED2		equ	$2f	'/'
*__SP2		equ	$70	'p'

switch_chr1u:	.dc.b	'/././.p/.',0
switch_chr1d:	.dc.b	'wuwuwumwu',0

switch_chr2:	.dc.b	'v','tlv','tlv'
		.dc.b	'tv'
		.dc.b	'tlv','tlv','tlv','tlv'
		.dc.b	'tv'
		.dc.b	'tlv','tlv','tlv'
		.dc.b	0
		.even


*==================================================
*ドライブ状態テーブルの作成
*	DRV_TBL[26]	ドライブ A - Z
*		bit8 : 0:使用可能 1:使用不可
*		bit7～3 :ユニット番号
*		bit1 : 0:2HD以外 1:2HDドライブ
*		bit0 : 0:レディ 1:ノットレディ
*==================================================

MAKE_DRVTBL:
		movem.l	d0-d2/d7/a0,-(sp)
		link	a5,#-96
		tst.b	DRV_TBLFLAG(a6)
		bne	make_drvtbl90
		st.b	DRV_TBLFLAG(a6)

		lea	DRV_TBL(a6),a0
		moveq	#1,d1
		moveq	#26-1,d7
make_drvtbl10:
		move.w	d1,-(sp)		*使用可能かどうか調べる
		DOS	_DRVCTRL
		addq.l	#2,sp
		tst.l	d0
		bmi	make_drvtbl11
		btst	#2,d0
		sne	d2
		andi.b	#$01,d2
		pea	-96(a5)			*2HDドライブかどうか調べる
		move.w	d1,-(sp)
		DOS	_GETDPB
		addq.l	#6,sp
		move.b	-96+1(a5),d0		*ユニット番号
		andi.b	#$1f,d0
		lsl.b	#3,d0
		or.b	d0,d2
		move.b	-96+22(a5),d0		*メディアID
		cmpi.b	#$fe,d0
		seq	d0
		andi.b	#$02,d0
		or.b	d2,d0
		move.b	d0,(a0)+
		bra	make_drvtbl12
make_drvtbl11:
		move.b	#$81,(a0)+		*使用不可
make_drvtbl12:
		addq.w	#1,d1
		dbra	d7,make_drvtbl10
make_drvtbl90:
		unlk	a5
		movem.l	(sp)+,d0-d2/d7/a0
		rts

*参考:この処理はまだやっていない
*	DOS _GETDPBによって、ドライブパラメーターブロックを得て
*	DPBPTR+$16のメディアバイトが$FE,$FD,$FC,$FB,$FAなら
*	それはＦＤであるとわかる。
*	（参考：メディアバイト）
*		$FE	:	ＦＤ
*		$FA	:	ＦＤ（２ＤＤ８セクタ）
*		$FB	:	ＦＤ（２ＤＤ９セクタ）
*		$FC	:	ＦＤ（２ＨＤ１８セクタ）
*		$FD	:	ＦＤ（２ＨＤ１５セクタ）


*==================================================
*機能：ドライブが使用可能か調べる
*	d0.w <- 調べるドライブ
*	d0.l -> _DRVCTRLの結果(負ならエラー) ccrにも返す
*==================================================

DRIVE_CHECK:
		move.w	d0,-(sp)
		DOS	_DRVCTRL
		addq.l	#2,sp
		tst.l	d0
		bmi	drivechk_done
		btst.l	#2,d0			*NOT READY
		beq	drivechk_done
		bset.l	#31,d0
drivechk_done:
		tst.l	d0
		rts

*==================================================
*ディスクイジェクト検出
*	d0.l -> 0以外なら挿入／イジェクトされた
*		下位1byteはDRV_TBLと同じ
*==================================================

EJECT_CHECK:
		movem.l	d1-d2/a0-a1,-(sp)
		moveq	#0,d2

		MYONTIME		*.5秒毎にチェックする
		lea	EJECT_ONTIME(pc),a0
		sub.w	(a0),d0
		cmpi.w	#50,d0
		bls	eject_check90
		add.w	d0,(a0)
eject_check10:
		move.b	CURRENT(a6),d1
		andi.w	#$00df,d1
		subi.w	#'A',d1
		lea	DRV_TBL(a6),a0
		lea	(a0,d1.w),a1
		move.b	(a1),d1
		btst	#1,d1
		bne	eject_check15
		clr.w	-(sp)			*(2HD以外)
		DOS	_DRVCTRL
		addq.l	#2,sp
		btst	#2,d0
		sne	d0
		bra	eject_check20
eject_check15:					*(2HD)
		lea	$9e6.w,a0
		move.b	d1,d0
		lsr.b	#2,d0
		andi.w	#$0006,d0
		tst.w	(a0,d0.w)
		spl	d0
eject_check20:
		eor.b	d0,d1
		btst	#0,d1
		beq	eject_check90
		bchg.b	#0,(a1)
		moveq	#-1,d2
		move.b	d0,d2
eject_check90:
		move.l	d2,d0
		movem.l	(sp)+,d1-d2/a0-a1
		rts

EJECT_ONTIME:	.dc.w	0


*==================================================
*カレントドライブイジェクト禁止
*==================================================

LOCK_DRIVE:
		move.l	d0,-(sp)
		tst.b	LOCKDRIVE(a6)		*ロックされているドライブがあったら
		beq	lock_drive10
		bsr	UNLOCK_DRIVE		*アンロックする
lock_drive10:
		move.b	CURRENT(a6),d0		*カレントドライブを求める
		andi.w	#$00df,d0
		subi.w	#'A',d0
		addq.w	#1,d0
		move.b	d0,LOCKDRIVE(a6)	*ロックドライブ番号をセット
		ori.w	#$0200,d0		*MD=2:EJECT禁止
		move.w	d0,-(sp)
		DOS	_DRVCTRL
		addq.l	#2,sp
		move.l	(sp)+,d0
		rts


*==================================================
*ロックしたドライブのイジェクトを許可
*==================================================

UNLOCK_DRIVE:
		move.l	d0,-(sp)
		moveq	#0,d0
		move.b	LOCKDRIVE(a6),d0
		ori.w	#$0300,d0		*MD=3:EJECT許可
		move.w	d0,-(sp)
		DOS	_DRVCTRL
		addq.l	#2,sp
		clr.b	LOCKDRIVE(a6)
		move.l	(sp)+,d0
		rts


*==================================================
*セレクタメインルーチン
*==================================================

SELECTOR_MAIN:
		movem.l	d0-d7/a0-a5,-(sp)
		tst.b	SEL_NOUSE(a6)
		bne	selector_done

		bsr	G_MESSAGE_WAIT			*メッセージ時間待ちクリア
		bsr	EJECT_CHECK			*ディスクの状態が変化したら
		bpl	selector_main01
		btst	#0,d0
		beq	selector_main00
		bsr	INIT_FNAMEBUF			*イジェクトならバッファクリア
selector_main00:
		clr.w	SEL_CHANGE(a6)			*initモードへ移行する

selector_main01:
		move.w	SEL_CHANGE(a6),d0		*モード変更？
		bmi	selector_main10
		move.w	d0,SEL_STAT(a6)
		move.w	#-1,SEL_CHANGE(a6)

selector_main10:
		move.w	SEL_STAT(a6),d0
		and.w	#7,d0
		lsl.w	#2,d0
		jmp	selector_jtop(pc,d0.w)		*状態別でジャンプだっ！

selector_jtop:	bra.w	selmode_init
		bra.w	selmode_kens
		bra.w	selmode_tsel
		bra.w	selmode_idle
		bra.w	selmode_idle
		bra.w	selmode_idle
		bra.w	selmode_idle
		bra.w	selmode_idle

selector_done:
		movem.l	(sp)+,d0-d7/a0-a5
		rts


*==================================================
*アイドリング状態
*==================================================

selmode_idle:
		bra	selector_done


*==================================================
*初期状態
*==================================================

selmode_init:
		bsr	MAKE_DRVTBL

		lea	CURRENT(a6),a0
		bsr	GET_CURRENT
		bsr	PRINT_CURDIR			*カレントパス名表示

selmode_init10:
		bsr	LOCK_DRIVE			*ドライブをロックする
		bsr	FNAME_SET			*カレントディレクトリを登録
		tst.l	d0
		bpl	selmode_init20

		lea.l	G_MES_No5(pc),a0		*「バッファがあふれました」
		bsr	G_MESSAGE_PRT

		bsr	INIT_FNAMEBUF
		bsr	UNLOCK_DRIVE			*ロックドライブを解除する
		bra	selector_done

selmode_init20
		movea.l	d0,a0
		bsr	SET_SELECTOR			*セレクタ初期化
		bsr	REF_SELECTOR			*セレクタ表示

		movea.l	SEL_HEAD(a6),a0			*タイトル検索が完了していたら
		tst.b	KENS_FLAG(a0)
		beq	selmode_init30
		clr.b	SEL_SRC_F(a6)
		bsr	UNLOCK_DRIVE			*ロックドライブを解除する
		move.w	#FSEL_MODE,SEL_CHANGE(a6)	*つぎはセレクトだっ
		bra	selector_done

selmode_init30:
							*まだタイトル検索が残っていたら
*		lea.l	G_MES_No1(pc),a0		*「検索中です」
*		bsr	G_MESSAGE_PRT
*		clr.w	G_MES_FLAG(a6)
		st.b	SEL_SRC_F(a6)
		move.w	#KENS_MODE,SEL_CHANGE(a6)	*つぎは検索だっ
		bra	selector_done


*==================================================
*タイトル検索中
*==================================================

selmode_kens:
		bsr	SELECT_MAIN			*セレクタコマンド実行
		tst.w	SEL_CHANGE(a6)
		bpl	selector_done

selmode_kens10:
		tst.l	d0				*キー入力があったら、
		bmi	selmode_kens19
		MYONTIME
		move.w	d0,SEL_TIME(a6)
*		lea.l	G_MES_No2(pc),a0		*「検索を中断しました」
*		bsr	G_MESSAGE_PRT
		move.w	#FSEL_MODE,SEL_CHANGE(a6)
		bra	selector_done			*セレクトへ
selmode_kens19:

selmode_kens20:
		bsr	SEARCH_TITLE			*タイトル読み込み
		tst.l	d0
		bpl	selmode_kens29			*検索終了したら、
		clr.b	SEL_SRC_F(a6)
		movea.l	SEL_HEAD(a6),a0			*検索終了フラグをセット
		st.b	KENS_FLAG(a0)
		bsr	UNLOCK_DRIVE			*ロックドライブを解除する
*		lea.l	G_MES_No4(pc),a0		*「検索を終了しました」
*		bsr	G_MESSAGE_PRT
		move.w	#FSEL_MODE,SEL_CHANGE(a6)
		bra	selector_done			*セレクトへ
selmode_kens29:

selmode_kens30:
		tst.b	SEL_VIEWMODE(a6)		*ファイルセレクトモードで
		bne	selmode_kens39
		sub.w	SEL_BPRT(a6),d0			*かつ表示範囲内
		cmpi.w	#8,d0
		bhi	selmode_kens31
		bsr	TITLE_CLR1			*ならば表示
		bsr	TITLE_PRT1
selmode_kens31:
*		bsr	TITLE_PRT2			*表示範囲外ならば別場所に
selmode_kens39:
		bra	selector_done			*まだ続く


*==================================================
*ファイルセレクト中
*==================================================

selmode_tsel:
		bsr	SELECT_MAIN
		tst.w	SEL_CHANGE(a6)
		bpl	selector_done

		tst.l	d0				*キー入力があったら、
		bmi	select_tsel_j0

		MYONTIME
		move.w	d0,SEL_TIME(a6)
		bra	selector_done			*もどるっ

select_tsel_j0:
		tst.b	SEL_SRC_F(a6)			*未検索があるとき、
		beq	selector_done

		MYONTIME
		sub.w	SEL_TIME(a6),d0
		cmpi.w	#30,d0				*0.3秒キー入力が
		bcs	selector_done			*なかったら

*		lea.l	G_MES_No3(pc),a0		*「検索を再開します」
*		bsr	G_MESSAGE_PRT
*		clr.w	G_MES_FLAG(a6)

		move.w	#KENS_MODE,SEL_CHANGE(a6)	*検索モードへ
		bra	selector_done


*==================================================
*自動演奏メイン
*==================================================

selector_auto:
		tst.b	AUTOMODE(a6)
		beq	selector_auto90

		tst.w	STAT_OK(a6)
		beq	selector_auto90
		tst.w	PLAYEND_FLAG(a6)
		bne	selector_auto20			*演奏中なら
selector_auto10:
		clr.w	BLANK(a6)
		btst.b	#1,AUTOFLAG(a6)			*イントロモードで時間を超えたなら
		beq	selector_auto11
		move.w	SYS_PASSTM(a6),d0
		cmp.w	INTRO_TIME(a6),d0
		blt	selector_auto90
		bsr	PLAY_NEXT			*次の曲を演奏する
		bra	selector_auto90
selector_auto11:
		move.w	SYS_LOOP(a6),d0			*ループ回数が規定値以上なら
		cmp.w	LOOP_TIME(a6),d0
		blt	selector_auto90
		DRIVER	DRIVER_FADEOUT			*フェードアウトする
		bra	selector_auto90

selector_auto20:					*停止中なら
		move.w	BLANK(a6),d0			*曲間時間を超えたかまたは
		cmp.w	BLANK_TIME(a6),d0
		bcc	selector_auto21
		addq.w	#1,BLANK(a6)
		btst.b	#1,AUTOFLAG(a6)			*イントロモードなら
		beq	selector_auto90
selector_auto21:
		bsr	PLAY_NEXT			*次の曲を演奏する
selector_auto90:
		rts


*==================================================
*次の曲を演奏する（AUTO/SHUFFLEモード用）
*==================================================

PLAY_NEXT:
		movem.l	d0-d1,-(sp)

play_next10:
		cmpi.b	#2,AUTOMODE(a6)		*AUTOモード
		beq	play_next20
		bsr	search_next_auto	*次の有効な曲を見つける
		bmi	play_next_err		*無かったら、AUTOモード解除
		move.w	d0,d1			*有ったら、演奏する
		bra	play_next_ok

play_next20:
		bsr	search_next_shuffle	*SHUFFLEモード
		bpl	play_next21
		btst.b	#0,AUTOFLAG(a6)		*一度見つからなくても、リピートモードなら
		beq	play_next_err
		addq.b	#1,SHUFFLE_CODE(a6)	*シャフル値を変更して
		bsr	search_next_shuffle	*もう一度探す
		bmi	play_next_err		*それでも見つからなければ、モード解除
play_next21:
		move.w	d0,d1

play_next_ok:
		bsr	play_data		*演奏する
		bra	play_next90

play_next_err:
		DRIVER	DRIVER_FADEOUT
		moveq	#0,d1
		bsr	AUTOMODE_SET

play_next90:
		movem.l	(sp)+,d0-d1
		rts

.if 0
put_debugpos:
		movem.l	d0-d1/a0,-(sp)
		movea.l	#BGADR+40*2+16*$80,a0
		moveq	#4,d1
		bsr	DIGIT16
		movem.l	(sp)+,d0-d1/a0
		rts
.endif

*==================================================
*ディレクトリを移動し、演奏する（AUTO/SHUFFLEモード用）
*	d1.w <- ファイル番号
*==================================================

play_data:
		bsr	search_header
		move.w	d1,PAST_POS(a0)
		movea.l	PATH_ADR(a0),a0		*カレントディレクトリを変更し
		bsr	CHANGE_DIR
		move.w	d1,d0
		bsr	get_fnamebuf
		cmpi.b	#2,AUTOMODE(a6)		*SHUFFLEモードなら
		bne	play_data10		*SHUFFLEフラグセット
		tst.b	(a0)			*音楽データじゃなければ無視
		ble	play_data10
		move.b	SHUFFLE_CODE(a6),SHUFFLE_FLAG(a0)
play_data10:
		bsr	PLAY_MUSIC		*演奏する
play_data90:
		rts


.if 0		*内部バッファ表示（デバッグ用）
debug:
		movem.l	d0/a0,-(sp)
		move.l	#BGADR+0*2+44*$80,a0

*
		move.w	SEL_FMAX(a6),d0
		bsr	PRINT10_5KETA
		addq.l	#6,a0
*
		move.w	SEL_BTOP(a6),d0
		bsr	PRINT10_5KETA
		addq.l	#6,a0
*
		move.w	SEL_BMAX(a6),d0
		bsr	PRINT10_5KETA
		addq.l	#6,a0
*
		move.w	SEL_BPRT(a6),d0
		bsr	PRINT10_5KETA
		addq.l	#6,a0
*
		move.w	SEL_BSCH(a6),d0
		bsr	PRINT10_5KETA
		addq.l	#6,a0
*
		move.w	SEL_FCP(a6),d0
		bsr	PRINT10_5KETA
		addq.l	#6,a0
*
		move.w	SEL_CUR(a6),d0
		bsr	PRINT10_5KETA
		addq.l	#6,a0
*
		movem.l	(sp)+,d0/a0
		rts
.endif

*==================================================
*カレントドライブパス名表示
*==================================================

PRINT_CURDIR:
		movem.l	d0-d1/a0-a1,-(sp)

		bsr	OVER_RIGHT_CLR

		movea.l	#TXTADR+344*$80+46,a1	*表示位置調整
		lea	CURRENT(a6),a0
		moveq	#0,d0
print_curdir10:
		addq.w	#1,d0
		tst.b	(a0)+
		bne	print_curdir10
		lsr.w	#1,d0
		subi.w	#18,d0
		bls	print_curdir30
		cmpi.w	#12,d0
		bls	print_curdir20
		moveq	#12,d0
print_curdir20:
		suba.w	d0,a1

print_curdir30:
		lea	CURRENT(a6),a0		*4*8ドットでテキストの(368,344)に表示
		moveq	#2,d0
		moveq	#0,d1
		bsr	TEXT_4_8

		movem.l	(sp)+,d0-d1/a0-a1
		rts


*==================================================
*セレクタ制御コマンドを実行する
*	d0.l -> 負なら、FCPポインタが移動していない
*==================================================

SELECT_MAIN:
		bsr	selector_auto			*AUTOモード処理

		tst.b	SEL_VIEWMODE(a6)		*ビューワモード
		bne	VIEWER_MAIN

*		bsr	debug
		clr.b	SEL_PLAYCHK(a6)			*演奏したかどうかのチェック用
		move.w	SEL_FCP(a6),-(sp)
		lea	selt_jmp_fsel(pc),a0		*セレクタコマンド実行
		bsr	select_jump
		move.w	(sp)+,d0
		cmp.w	SEL_FCP(a6),d0
		beq	select_main80			*移動していたら
		bsr	disp_linenum

		movea.l	SEL_HEAD(a6),a0			*現在位置を保存
		move.w	SEL_FCP(a6),PAST_POS(a0)

		move.w	SEL_BPRT(a6),SEL_BSCH(a6)	*タイトル検索開始位置もセット
*		move.w	SEL_BPRT(a6),d0			*(９個前から検索する場合）
*		subi.w	#9,d0
*		bcc	select_main50
*		cmp.w	SEL_BTOP(a6),d0
*		bcc	aa
*		move.w	SEL_BTOP(a6),d0
*select_main50:
*		move.w	d0,SEL_BSCH(a6)

		tst.b	SEL_PLAYCHK(a6)			*mmove = (playchk)? 0 : -1;
		seq	SEL_MMOVE(a6)
		moveq	#0,d0
		bra	select_main90
select_main80:
		moveq	#-1,d0
select_main90:
		rts


*==================================================
*セレクタ制御コマンドを実行する（ドキュメントビューワ）
*	d0.l -> 負なら、カーソル移動が無かった
*==================================================

VIEWER_MAIN:
		move.l	DOCV_NOW(a6),-(sp)		*今の表示位置を覚えておく
		lea	selt_jmp_view(pc),a0		*ビューワコマンド実行
		bsr	select_jump
		move.l	(sp)+,d0
		cmp.l	DOCV_NOW(a6),d0
		beq	viewer_main80			*表示位置が変わっていたら0
		moveq	#0,d0
		bra	viewer_main90
viewer_main80:
		moveq	#-1,d0				*変ってなかったら-1
viewer_main90:
		rts


*==================================================
*セレクタ制御コマンド処理ルーチンへジャンプ
*	a0.l <- ジャンプテーブル
*==================================================

select_jump:
		movea.l	a0,a1
		move.w	SEL_CMD(a6),d0		*コマンドチェック
		beq	selt_none
		cmpi.w	#SEL_CMDNUM,d0
		bcc	selt_none

		move.w	SEL_ARG(a6),d1
		subq.w	#1,d0
		lsl.w	#2,d0
		lea	(a0,d0.w),a0
		move.w	(a0)+,d0
		tst.w	(a0)
		beq	select_jump10		*ファイルがないとだめなコマンドの場合
		tst.w	SEL_FMAX(a6)		*ファイルが０個なら
		beq	selt_none		*何もしない
select_jump10:
		jsr	(a1,d0.w)		*コマンド実行
selt_none:
		clr.w	SEL_CMD(a6)
		rts


CMD_FSEL	macro	label,flag
		.dc.w	label-selt_jmp_fsel
		.dc.w	flag		*ファイルが無ければ実行できないコマンドなら1
		endm

selt_jmp_fsel:
		CMD_FSEL	selt_rolldw_one,1
		CMD_FSEL	selt_rollup_one,1
		CMD_FSEL	selt_cur_up,1
		CMD_FSEL	selt_cur_down,1
		CMD_FSEL	selt_enter_cmd,1
		CMD_FSEL	selt_enter,1
		CMD_FSEL	selt_drive_right,0
		CMD_FSEL	selt_drive_left,0
		CMD_FSEL	selt_parent,0
		CMD_FSEL	selt_root,0
		CMD_FSEL	selt_roll_up,1
		CMD_FSEL	selt_roll_dw,1
		CMD_FSEL	selt_refresh,0
		CMD_FSEL	selt_top,1
		CMD_FSEL	selt_botom,1
		CMD_FSEL	selt_playdown,1
		CMD_FSEL	selt_playup,1
		CMD_FSEL	selt_eject,0
		CMD_FSEL	selt_datawrite,1
		CMD_FSEL	selt_docread,1
		CMD_FSEL	selt_docreadn,1

CMD_VIEW	macro	label,flag
		.dc.w	label-selt_jmp_view
		.dc.w	flag		*ファイルが無ければ実行できないコマンドなら1
		endm

selt_jmp_view:
		CMD_VIEW	view_rolldw_one,1
		CMD_VIEW	view_rollup_one,1
		CMD_VIEW	view_cur_up,1
		CMD_VIEW	view_cur_down,1
		CMD_VIEW	view_enter_cmd,0
		CMD_VIEW	view_enter,1
		CMD_VIEW	view_drive_right,0
		CMD_VIEW	view_drive_left,0
		CMD_VIEW	view_parent,0
		CMD_VIEW	view_root,0
		CMD_VIEW	view_roll_up,1
		CMD_VIEW	view_roll_dw,1
		CMD_VIEW	view_refresh,0
		CMD_VIEW	view_top,1
		CMD_VIEW	view_botom,1
		CMD_VIEW	view_playdown,1
		CMD_VIEW	view_playup,1
		CMD_VIEW	view_eject,0
		CMD_VIEW	view_datawrite,1
		CMD_VIEW	view_docread,1
		CMD_VIEW	view_docreadn,1


*==================================================
*セレクタコマンドサブルーチン（ファイルセレクタ）
*==================================================

*バッファクリア

selt_refresh:
		moveq	#0,d1
		bsr	AUTOMODE_SET
		bsr	AUTOFLAG_SET
		bsr	PROGMODE_SET
		bsr	INIT_FNAMEBUF
		clr.w	SEL_CHANGE(a6)
		rts

*親ディレクトリに移動

selt_parent:
		lea	FNAM_BUFF(a6),a0
		move.b	#'.',(a0)
		move.b	#'.',1(a0)
		move.b	#'\',2(a0)
		clr.b	3(a0)
		bsr	CHANGE_DIR
		rts

*ルートディレクトリに移動

selt_root:
		lea	FNAM_BUFF(a6),a0
		move.b	#'\',(a0)
		clr.b	1(a0)
		bsr	CHANGE_DIR
		rts

*１つ若いドライブに移動

selt_drive_left:
		move.b	CURRENT(a6),d0
		andi.w	#$00df,d0
		subi.w	#'A',d0
		beq	selt_drv_left90

		lea	DRV_TBL(a6),a0
selt_drv_left10:
		subq.w	#1,d0				*有効ドライブを見つけて
		bcs	selt_drv_left90
		tst.b	(a0,d0.w)
		bmi	selt_drv_left10

		move.w	d0,-(sp)			*ドライブ移動
		DOS	_CHGDRV
		addq.l	#2,sp
		clr.w	SEL_CHANGE(a6)
selt_drv_left90:
		rts

*１つ次のドライブに移動

selt_drive_right:
		move.b	CURRENT(a6),d0
		andi.w	#$00df,d0
		subi.w	#'A',d0

		lea	DRV_TBL(a6),a0
selt_drv_right10:
		addq.w	#1,d0				*有効ドライブを見つけて
		cmpi.w	#25,d0
		bhi	selt_drv_right90
		tst.b	(a0,d0.w)
		bmi	selt_drv_right10

		move.w	d0,-(sp)			*ドライブ移動
		DOS	_CHGDRV
		addq.l	#2,sp
		clr.w	SEL_CHANGE(a6)
selt_drv_right90:
		rts

*演奏してから次の行へ移動

selt_playdown:
		tst.b	AUTOMODE(a6)		*AUTO/SHUFFLEモードで
		beq	selt_playdown10
		tst.b	PROG_MODE(a6)		*かつPROGモードでなかったら
		bne	selt_playdown10
		bsr	PLAY_NEXT		*次の曲へすぐ移る
		bra	selt_playdown90
selt_playdown10:
		move.w	SEL_FCP(a6),d0		*今の行がデータだったら、
		bsr	get_fnamebuf
		tst.b	(a0)
		ble	selt_playdown11
		bsr	selt_enter		*演奏/選択する
selt_playdown11:
		bsr	selt_cur_down		*次の行へ移動する
selt_playdown90:
		rts

*前の行へ移動して演奏

selt_playup:
		bsr	selt_cur_up		*前の行へ移動して
		move.w	SEL_FCP(a6),d0		*今の行がデータだったら
		bsr	get_fnamebuf
		tst.b	(a0)
		ble	selt_playup90
		bsr	selt_enter		*演奏/選択する
selt_playup90:
		rts

*ディスクイジェクト

selt_eject:
		bsr	UNLOCK_DRIVE		*ロックされているドライブを解除
		move.w	#$0100,-(sp)
		DOS	_DRVCTRL		*カレントドライブをイジェクト
		addq.l	#2,sp
		clr.w	SEL_CHANGE(a6)		*initモードへ
		rts


*	＊ＥＮＴＥＲ，ＲＥＴＵＲＮ時

selt_enter_cmd:
		move.w	SEL_ARG(a6),d0
		add.w	SEL_BPRT(a6),d0
		cmp.w	SEL_BMAX(a6),d0
		bcc	selt_enter_done
		move.w	d0,SEL_FCP(a6)
		move.w	SEL_ARG(a6),d0
		move.w	d0,SEL_CUR(a6)
		bsr	LINE_CUR_ON

selt_enter:
		tst.b	PROG_MODE(a6)
		bne	selt_enter_prog

		moveq	#0,d0
		bsr	DRIVE_CHECK		*ドライブレディチェック
		bmi	selt_enter_done
		move.w	SEL_FCP(a6),d0		*バッファアドレス計算
		bsr	get_fnamebuf
		tst.b	(a0)
		beq	selt_enter_dir
		bsr	PLAY_MUSIC		*曲データだったら演奏
		bra	selt_enter_done
selt_enter_dir:
		lea	FILE_NAME(a0),a0	*ディレクトリだったらカレント移動
		bsr	CHANGE_DIR
selt_enter_done:
		rts

selt_enter_prog:
		move.w	SEL_FCP(a6),d0		*バッファアドレス計算
		bsr	get_fnamebuf
		tst.b	(a0)
		ble	selt_enter_dir
		tst.b	PROG_FLAG(a0)		*PROGフラグ反転
		seq	PROG_FLAG(a0)
		move.w	SEL_CUR(a6),d0		*表示
		bsr	TITLE_PRT1
selt_enter_prog90:
		rts


*先頭行へ移動

selt_top:
		move.w	SEL_BTOP(a6),d0			*いま先頭なら、無視する
		cmp.w	SEL_FCP(a6),d0
		beq	selt_top90
		move.w	d0,SEL_FCP(a6)			*表示
		cmp.w	SEL_BPRT(a6),d0
		beq	selt_top80
		move.w	d0,SEL_BPRT(a6)
		bsr	TITLE_NP_PRT
selt_top80:
		moveq	#0,d0
		move.w	d0,SEL_CUR(a6)			*カーソルを先頭に
		bsr	LINE_CUR_ON
selt_top90:
		rts


*最終行へ移動

selt_botom:
		move.w	SEL_BMAX(a6),d1
		subq.w	#1,d1
		move.w	d1,SEL_FCP(a6)
		subq.w	#8,d1
		cmp.w	SEL_BTOP(a6),d1
		bge	selt_botom10
		move.w	SEL_BTOP(a6),d1
selt_botom10:
		move.w	SEL_FCP(a6),d0
		sub.w	d1,d0
		move.w	d0,SEL_CUR(a6)
		bsr	LINE_CUR_ON
		cmp.w	SEL_BPRT(a6),d1
		beq	selt_botom90
		move.w	d1,SEL_BPRT(a6)
		bsr	TITLE_NP_PRT			*表示
selt_botom90:
		rts


*	＊ＲＯＬＬ　ＵＰ時
selt_roll_up:
		bsr	selt_rollup_one
		bsr	selt_rollup_one
		bsr	selt_rollup_one
		bsr	selt_rollup_one
		bsr	selt_rollup_one
		bsr	selt_rollup_one
		bsr	selt_rollup_one
		bsr	selt_rollup_one
		bsr	selt_rollup_one
		rts

		move.w	SEL_FCP(a6),d0			*最後にいたら、無視する
		addq.w	#1,d0
		cmp.w	SEL_BMAX(a6),d0
		beq	selt_rldw_done

		move.w	SEL_BPRT(a6),d1

		cmpi.w	#9,SEL_FMAX(a6)			*if (fmax <= 9) {
		bhi	selt_roll_up10
		move.w	SEL_BTOP(a6),SEL_BPRT(a6)	*	bprt = btop;
		move.w	SEL_BMAX(a6),SEL_FCP(a6)	*	fcp = bmax - 1;
		subq.w	#1,SEL_FCP(a6)
		bra	selt_roll_up20
selt_roll_up10:
		move.w	SEL_BMAX(a6),d0			*} else if (fcp >= bmax - 9) {
		subi.w	#9,d0
		cmp.w	SEL_FCP(a6),d0
		bhi	selt_roll_up11
		move.w	d0,SEL_BPRT(a6)			*	bprt = bmax - 9;
		addq.w	#8,d0
		move.w	d0,SEL_FCP(a6)			*	fcp = bmax - 1;
		bra	selt_roll_up20
selt_roll_up11:
		addi.w	#9,SEL_FCP(a6)			*} else {
		addi.w	#9,SEL_BPRT(a6)			*	fcp += 9;
		cmp.w	SEL_BPRT(a6),d0			*	bprt += 9;
		bcc	selt_roll_up20			*	if(bprt > bmax - 9)
		move.w	d0,SEL_BPRT(a6)			*		bprt = bmax - 9;
							*}

selt_roll_up20:
		move.w	SEL_FCP(a6),d0
		sub.w	SEL_BPRT(a6),d0
		move.w	d0,SEL_CUR(a6)

		bsr	LINE_CUR_ON
		cmp.w	SEL_BPRT(a6),d1
		beq	selt_rlup_done
		bsr	TITLE_NP_PRT			*表示
selt_rlup_done:
		rts


*	＊ＲＯＬＬ　ＤＯＷＮ時

selt_roll_dw:

		bsr	selt_rolldw_one
		bsr	selt_rolldw_one
		bsr	selt_rolldw_one
		bsr	selt_rolldw_one
		bsr	selt_rolldw_one
		bsr	selt_rolldw_one
		bsr	selt_rolldw_one
		bsr	selt_rolldw_one
		bsr	selt_rolldw_one
		rts


		move.w	SEL_FCP(a6),d0			*先頭にいたら、無視する
		cmp.w	SEL_BTOP(a6),d0
		beq	selt_rldw_done

		move.w	SEL_BPRT(a6),d1

		move.w	SEL_BTOP(a6),d0			*if(fcp < btop + 9) {
		addi.w	#9,d0
		cmp.w	SEL_FCP(a6),d0
		bls	selt_roll_dw10
		move.w	SEL_BTOP(a6),SEL_BPRT(a6)	*	bprt = btop;
		move.w	SEL_BTOP(a6),SEL_FCP(a6)	*	fcp = btop;
		bra	selt_roll_dw20			*} else {
selt_roll_dw10:
		subi.w	#9,SEL_FCP(a6)			*	fcp -= 9;
		subi.w	#9,SEL_BPRT(a6)			*	bprt -= 9;
		move.w	SEL_BTOP(a6),d0			*	if (bprt < btop)
		cmp.w	SEL_BPRT(a6),d0
		ble	selt_roll_dw20			*		bprt = btop;
		move.w	d0,SEL_BPRT(a6)			*}

selt_roll_dw20:
		move.w	SEL_FCP(a6),d0			*cur = fcp - bprt;
		sub.w	SEL_BPRT(a6),d0
		move.w	d0,SEL_CUR(a6)

		bsr	LINE_CUR_ON
		cmp.w	SEL_BPRT(a6),d1
		beq	selt_rldw_done
		bsr	TITLE_NP_PRT			*表示
selt_rldw_done:
		rts

*	＊テンキー２

selt_cur_down:
		cmpi.w	#8,SEL_CUR(a6)			*スクロールするか？
		bne	selt_cur_down10
		bsr	selt_rollup_one			*スクロール
		bra	selt_cdw_done
selt_cur_down10:
		move.w	SEL_FCP(a6),d0			*下があるか？
		addq.w	#1,d0
		cmp.w	SEL_BMAX(a6),d0
		bcc	selt_cdw_done
		move.w	d0,SEL_FCP(a6)
		addq.w	#1,SEL_CUR(a6)			*カーソル移動
		move.w	SEL_CUR(a6),d0
		bsr	LINE_CUR_ON
selt_cdw_done:
		rts

*	＊テンキー８

selt_cur_up:
		tst.w	SEL_CUR(a6)			*スクロールするか？
		bne	selt_cur_up10
		bsr	selt_rolldw_one			*スクロール
		bra	selt_cup_done
selt_cur_up10:
		move.w	SEL_FCP(a6),d0			*上があるか？
		subq.w	#1,d0
		cmp.w	SEL_BTOP(a6),d0
		bcs	selt_cup_done
		move.w	d0,SEL_FCP(a6)
		sub.w	#1,SEL_CUR(a6)			*でなければカーソル移動
		move.w	SEL_CUR(a6),d0
		bsr	LINE_CUR_ON
selt_cup_done:
		rts

*１行ロールダウン

selt_rolldw_one:
		move.w	SEL_BPRT(a6),SEL_FCP(a6)	*カーソルを一番上に
		moveq	#0,d0
		move.w	d0,SEL_CUR(a6)
		bsr	LINE_CUR_ON

		move.w	SEL_BPRT(a6),d0			*スクロールできるか
		cmp.w	SEL_BTOP(a6),d0
		bls	selt_rldw_one90

		subq.w	#1,SEL_BPRT(a6)
		subq.w	#1,SEL_FCP(a6)

		bsr	TITLE_SCUP			*すっくろーるっ
		move.w	SEL_FCP(a6),d0			*バッファアドレス計算
		bsr	get_fnamebuf
		moveq.l	#0,d0				*タイトル表示
		bsr	TITLE_PRT1
selt_rldw_one90:
		rts

*１行ロールアップ

selt_rollup_one:
		moveq	#8,d0				*カーソルを一番下に
		cmp.w	SEL_FMAX(a6),d0
		bcs	selt_rlup_one10
		move.w	SEL_FMAX(a6),d0
		subq.w	#1,d0
selt_rlup_one10:
		move.w	d0,SEL_CUR(a6)
		bsr	LINE_CUR_ON
		add.w	SEL_BPRT(a6),d0
		move.w	d0,SEL_FCP(a6)

		move.w	SEL_BPRT(a6),d0			*スクロールできるか
		addi.w	#9,d0
		cmp.w	SEL_BMAX(a6),d0
		bcc	selt_rlup_one90

		addq.w	#1,SEL_BPRT(a6)
		addq.w	#1,SEL_FCP(a6)

		bsr	TITLE_SCDW			*すっくろーるっ
		move.w	SEL_FCP(a6),d0
		bsr	get_fnamebuf			*バッファアドレス計算
		moveq.l	#8,d0				*タイトル表示
		bsr	TITLE_PRT1
selt_rlup_one90:
		rts

selt_docreadn:
		move.w	SEL_ARG(a6),d0
		add.w	SEL_BPRT(a6),d0
		cmp.w	SEL_BMAX(a6),d0
		bcc	selt_docreadn90
		move.w	d0,SEL_FCP(a6)
		move.w	SEL_ARG(a6),d0
		move.w	d0,SEL_CUR(a6)
		bsr	LINE_CUR_ON
		bsr	selt_docread
selt_docreadn90:
		rts

selt_docread:
		link	a5,#-24
		move.w	SEL_FCP(a6),d0			*現在位置のファイルを調べ
		bsr	get_fnamebuf
		tst.b	DOC_FLAG(a0)
		beq	selt_docread90
		lea	FILE_NAME(a0),a0		*ドキュメントファイル名を作る
		lea	-24(a5),a1
		bsr	change_ext_doc
		tst.l	d0
		bmi	selt_docread90

		lea	-24(a5),a0			*ビューワを初期化する
*		move.l	#$0080_000c,d0			*表示範囲の設定
		move.l	#$0055_0009,d0			*表示範囲の設定
		move.l	#$0000_0058,d1			*表示位置の設定
		moveq.l	#0,d2				*フォント指定
		bsr	DOCVIEW_INIT
		tst.l	d0
		bmi	selt_docread90
		bsr	LINE_CUR_OFF
		bsr	DOCV_NOW_PRT
		st.b	SEL_VIEWMODE(a6)
selt_docread90:
		unlk	a5
		rts

*データファイル書き出し

selt_datawrite:
		lea	mes_datawrite1(pc),a0
		bsr	G_MESSAGE_PRT
		bsr	write_datafile
		lea	mes_datawrite2(pc),a0
		bsr	G_MESSAGE_PRT
		rts

mes_datawrite1:	.dc.b	'データファイル書き出し中...',0
mes_datawrite2:	.dc.b	'データファイル書き出し終了',0
		.even


*==================================================
*セレクタコマンドサブルーチン（ビューワ）
*==================================================

view_roll_dw:
		bra	DOCV_ROLLDOWN

view_roll_up:
		bra	DOCV_ROLLUP

view_rolldw_one:
view_cur_up:
		bra	DOCVIEW_UP

view_rollup_one:
view_cur_down:
		bra	DOCVIEW_DOWN

view_drive_right:
view_drive_left:
view_playdown:
view_playup:
view_eject:
view_datawrite:
view_top:
view_botom:
		rts				*何もしない

view_enter:
view_enter_cmd:
view_refresh:
view_parent:
view_root:
view_docread:
view_docreadn:
		clr.b	SEL_VIEWMODE(a6)		*ビューワを抜ける
		clr.w	SEL_CHANGE(a6)
		rts


*==================================================
*曲データを演奏する
*	a0.l <- バッファアドレス
*==================================================

PLAY_MUSIC:
		movem.l	d0-d1/a0-a1,-(sp)
		bsr	SHRINK_CONSOLE		*表示エリア変更
		movea.l	a0,a1
		move.b	DATA_KIND(a0),d1	*音楽データだったら、
		beq	play_music90
		DRIVER	DRIVER_FADEOUT		*フェードアウトして
		bsr	CLEAR_KEYON		*キーＯＮクリアして
		lea	FILE_NAME(a1),a1	*ロード＆演奏
		move.b	d1,d0
		DRIVER	DRIVER_FLOADP		*d0.b:code a1.l:filename
		tst.w	d0
		beq	play_music10		*何かエラーが発生したら、
		bsr	GET_PLAYERRMES		*エラーメッセージを表示する
		bsr	G_MESSAGE_PRT
play_music10:
		tst.l	d0
		bmi	play_music90		*演奏開始したら、
		bsr	CLEAR_PASSTM		*経過時間クリア
		clr.w	BLANK(a6)
		bra	play_music90
play_music90:
		bsr	CLEAR_CMD		*たまっているコマンドをクリアする
		clr.w	SEL_CMD(a6)
		clr.b	SEL_MMOVE(a6)		*手動移動フラグと
		st.b	SEL_PLAYCHK(a6)		*演奏コマンドフラグをセットする
		bsr	RESUME_CONSOLE		*表示エリア戻す
		movem.l	(sp)+,d0-d1/a0-a1
		rts


*==================================================
*プログラムモードセット
*	d1.b <- モードフラグ(0:OFF 0以外:ON)
*==================================================

PROGMODE_CHG:
		move.l	d1,-(sp)		*PROG設定モードトグル動作
		tst.b	PROG_MODE(a6)
		seq	d1
		bsr	PROGMODE_SET
		move.l	(sp)+,d1
		rts

PROGMODE_SET:
		movem.l	d0-d1/a1,-(sp)		*PROG設定モードセット
		tst.b	d1
		sne	d1
		tst.b	SEL_NOUSE(a6)		*セレクタ無使用モードならクリア
		beq	progmode_set10
		moveq	#0,d1
progmode_set10
		move.b	d1,PROG_MODE(a6)
		move.b	d1,d0			*スイッチを表示する
		move.l	#$00070001,d1
		movea.l	#TXTADR+6+344*$80,a1
		bsr	put_automodesub
		movem.l	(sp)+,d0-d1/a1
		rts


*==================================================
*プログラムクリア
*==================================================

PROG_CLR:
		movem.l	d0/a0,-(sp)
		movea.l	#SEL_FNAME,a0
		move.w	SEL_FILENUM(a6),d0
		subq.w	#1,d0
		bcs	prog_clr90
prog_clr10:
		tst.b	(a0)
		ble	prog_clr19
		clr.b	PROG_FLAG(a0)
prog_clr19:
		lea	32(a0),a0
		dbra	d0,prog_clr10

		bsr	TITLE_NP_PRT
prog_clr90:
		movem.l	(sp)+,d0/a0
		rts


*==================================================
*ＡＵＴＯモードセット
*	d1.b <- モード(0:NORMAL 1:AUTO 2:SHUFFLE)
*==================================================

AUTOMODE_CHG:
		move.l	d1,-(sp)		*AUTOモードトグル動作
		cmp.b	AUTOMODE(a6),d1
		bne	automode_chg10
		moveq	#0,d1
automode_chg10:
		bsr	AUTOMODE_SET
		move.l	(sp)+,d1
		rts

AUTOMODE_SET:
		movem.l	d0-d1/a1,-(sp)		*AUTOモードセット
		cmpi.b	#2,d1
		bhi	automode_set90
		tst.b	SEL_NOUSE(a6)		*セレクタ無使用モードならAUTO解除
		beq	automode_set10
		moveq	#0,d1
automode_set10:
		clr.w	BLANK(a6)		*ブランク時間をクリアする
		move.b	d1,AUTOMODE(a6)
		beq	automode_set20
		tst.w	PLAY_FLAG(a6)		*演奏中でなければ
		bne	automode_set11
		DRIVER	DRIVER_STOP		*演奏を完全に停止させる
automode_set11:
		move.w	#-1,BLANK(a6)
		cmpi.b	#2,d1			*SHUFFLEモードだったら
		bne	automode_set20
		addq.b	#1,SHUFFLE_CODE(a6)	*シャフルコードを変更する
		clr.b	SEL_MMOVE(a6)		*手動移動フラグをクリアする
automode_set20:
		move.b	d1,d0			*スイッチを表示する
		move.l	#$00070002,d1
		movea.l	#TXTADR+33+502*$80,a1
		bsr	put_automodesub
		lea	3(a1),a1
		bsr	put_automodesub

automode_set90:
		movem.l	(sp)+,d0-d1/a1
		rts

put_automodesub:
		lsr.b	#1,d0			*d0.bを右シフトして
		bcs	LIGHT_PATTERN		*bit on ならスイッチを明るくする
		bra	DARK_PATTERN		*bit offなら暗くする


*==================================================
*ＡＵＴＯフラグセット
*	d1.b <- フラグ(bit0:REPEAT bit1:INTRO bit2:ALLDIR bit3:PROG)
*==================================================

AUTOFLAG_CHG:
		movem.l	d0-d1,-(sp)		*AUTOフラグトグル動作
		move.b	AUTOFLAG(a6),d0
		eor.b	d0,d1
		bsr	AUTOFLAG_SET
		movem.l	(sp)+,d0-d1
		rts

AUTOFLAG_SET:
		movem.l	d0-d1/a1,-(sp)		*AUTOフラグセット
		tst.b	SEL_NOUSE(a6)		*セレクタ無使用モードならAUTOフラグ解除
		beq	autoflag_set10
		moveq	#0,d1
autoflag_set10:
		andi.w	#$000f,d1
		move.b	d1,AUTOFLAG(a6)
		move.b	d1,d0			*スイッチを表示する
		move.l	#$00070002,d1
		movea.l	#TXTADR+41+502*$80,a1
		bsr	put_automodesub
		lea	3(a1),a1
		bsr	put_automodesub
		lea	3(a1),a1
		bsr	put_automodesub
		lea	3(a1),a1
		bsr	put_automodesub
autoflag_set90:
		movem.l	(sp)+,d0-d1/a1
		rts


*==================================================
*ループ回数セット
*==================================================

LOOPTIME_UP:
		move.l	d1,-(sp)
		move.w	LOOP_TIME(a6),d1
		addq.w	#1,d1
		bsr	LOOPTIME_SET
		move.l	(sp)+,d1
		rts
LOOPTIME_DOWN:
		move.l	d1,-(sp)
		move.w	LOOP_TIME(a6),d1
		subq.w	#1,d1
		bsr	LOOPTIME_SET
		move.l	(sp)+,d1
		rts
LOOPTIME_SET:
		movem.l	d0-d1/a0,-(sp)
		cmpi.w	#99,d1
		bhi	looptime_set90
		tst.w	d1
		beq	looptime_set90
		move.w	d1,LOOP_TIME(a6)
		tst.b	SEL_NOUSE(a6)		*セレクタ使用モードなら表示する
		bne	looptime_set90
		move.w	d1,d0
		moveq	#2,d1
		movea.l	#BGADR+56*2+62*$80,a0
		bsr	DIGIT10
looptime_set90:
		movem.l	(sp)+,d0-d1/a0
		rts


*==================================================
*曲間ブランク時間セット
*==================================================

BLANKTIME_UP:
		move.l	d1,-(sp)
		move.w	BLANK_TIME(a6),d1
		addq.w	#1,d1
		bsr	BLANKTIME_SET
		move.l	(sp)+,d1
		rts
BLANKTIME_DOWN:
		move.l	d1,-(sp)
		move.w	BLANK_TIME(a6),d1
		subq.w	#1,d1
		bsr	BLANKTIME_SET
		move.l	(sp)+,d1
		rts
BLANKTIME_SET:
		movem.l	d0-d1/a0,-(sp)
		cmpi.w	#99,d1
		bhi	blanktime_set90
		move.w	d1,BLANK_TIME(a6)
		tst.b	SEL_NOUSE(a6)		*セレクタ使用モードなら表示する
		bne	blanktime_set90
		move.w	d1,d0
		moveq	#2,d1
		movea.l	#BGADR+59*2+62*$80,a0
		bsr	DIGIT10
blanktime_set90:
		movem.l	(sp)+,d0-d1/a0
		rts


*==================================================
*イントロ時間セット
*==================================================

INTROTIME_UP:
		move.l	d1,-(sp)
		move.w	INTRO_TIME(a6),d1
		addq.w	#1,d1
		bsr	INTROTIME_SET
		move.l	(sp)+,d1
		rts
INTROTIME_DOWN:
		move.l	d1,-(sp)
		move.w	INTRO_TIME(a6),d1
		subq.w	#1,d1
		bsr	INTROTIME_SET
		move.l	(sp)+,d1
		rts
INTROTIME_SET:
		movem.l	d0-d1/a0,-(sp)
		cmpi.w	#99,d1
		bhi	introtime_set90
		tst.w	d1
		beq	introtime_set90
		move.w	d1,INTRO_TIME(a6)
		tst.b	SEL_NOUSE(a6)		*セレクタ使用モードなら表示する
		bne	introtime_set90
		move.w	d1,d0
		moveq	#2,d1
		movea.l	#BGADR+62*2+62*$80,a0
		bsr	DIGIT10
introtime_set90:
		movem.l	(sp)+,d0-d1/a0
		rts


*==================================================
*セレクタ初期化
*	a0.l <- ディレクトリヘッダ
*==================================================

SET_SELECTOR:
		move.l	d0,-(sp)

		move.l	a0,SEL_HEAD(a6)

		move.w	TOP_POS(a0),SEL_BTOP(a6)
		move.w	PAST_POS(a0),SEL_FCP(a6)
		move.w	FILE_NUM(a0),d0
		move.w	d0,SEL_FMAX(a6)
		add.w	SEL_BTOP(a6),d0
		move.w	d0,SEL_BMAX(a6)

		move.w	SEL_BTOP(a6),d0		*if( fcp < btop + 4 | fmax <= 9) {
		addi.w	#4,d0
		cmp.w	SEL_FCP(a6),d0
		bhi	set_selector10		*	bprt = btop;
		cmpi.w	#9,SEL_FMAX(a6)
		bls	set_selector10
		move.w	SEL_BMAX(a6),d0		*} else if ( fcp > bmax - 5 ) {
		subi.w	#5,d0
		cmp.w	SEL_FCP(a6),d0
		bcs	set_selector11		*	bprt = bmax - 9;
		move.w	SEL_FCP(a6),d0		*} else bprt = fcp - 4;
		subq.w	#4,d0
		move.w	d0,SEL_BPRT(a6)
		bra	set_selector20

set_selector10:
		move.w	SEL_BTOP(a6),SEL_BPRT(a6)
		bra	set_selector20
set_selector11:
		move.w	SEL_BMAX(a6),d0
		subi.w	#9,d0
		move.w	d0,SEL_BPRT(a6)

set_selector20:
		move.w	SEL_FCP(a6),d0		*cur = fcp - bprt
		sub.w	SEL_BPRT(a6),d0
		move.w	d0,SEL_CUR(a6)

		move.w	SEL_BPRT(a6),SEL_BSCH(a6)

		move.l	(sp)+,d0
		rts


*==================================================
*セレクタ再表示
*==================================================

REF_SELECTOR:
		movem.l	d0-d1/a0-a1,-(sp)

		tst.b	SEL_VIEWMODE(a6)
		bne	ref_selector90

		bsr	disp_linenum		*現在位置を表示
		bsr	LINE_CUR_OFF		*カーソルを消して
		bsr	TITLE_NP_PRT		*画面を描き直す
		movea.l	SEL_HEAD(a6),a0		*ダミーのヘッダなら、
		tst.l	PATH_ADR(a0)
		bne	ref_selector10
		moveq	#1,d0			*'NO DISK'と表示
		moveq	#0,d1
		lea	mes_nodisk(pc),a0
		movea.l	#TXTADR+58+481*$80,a1
		bsr	TEXT_6_16
		bra	ref_selector90
ref_selector10:
		tst.w	SEL_FMAX(a6)		*ファイルが一個でもあるなら
		beq	ref_selector90
		move.w	SEL_CUR(a6),d0		*カーソルを表示する
		bsr	LINE_CUR_ON
ref_selector90:
		movem.l	(sp)+,d0-d1/a0-a1
		rts

mes_nodisk:
		.dc.b	'NO DISK',0
		.even


*==================================================
*バッファ内のタイトルを１つ表示
*	a0.l <- バッファポインタアドレス
*	d0.w <- 表示位置(0-8)
*==================================================

TITLE_PRT1:
		movem.l	d0-d2/a0-a3,-(sp)
		movea.l	a0,a2

		tst.b	SEL_VIEWMODE(a6)
		bne	title_prt1_90

		move.l	#TXTADR+(352+7)*$80,a1		*テキストアドレス計算
		and.w	#15,d0
		ext.l	d0
		lsl.l	#7,d0
		lsl.l	#4,d0
		add.l	d0,a1
		moveq	#0,d1

		move	#3,d0				*ディレクトリ:アクセスモード３
		tst.b	DATA_KIND(a2)
		bne	title_prt1_10
		lea	dir_mes(pc),a0
		bsr	TEXT_4_8
		lea	-$80*7+10(a1),a1
		lea	FILE_NAME(a2),a0
		bsr	TEXT_6_16
		bra	title_prt1_90

title_prt1_10:
		moveq	#1,d0				*未検索:アクセスモード１
		tst.l	TITLE_ADR(a2)
		beq	title_prt1_20
		moveq	#2,d0				*ファイル:アクセスモード２
title_prt1_20:
		lea	FILE_NAME(a2),a0
		bsr	TEXT_4_8			*ファイル名表示

		movem.l	d0-d1/a1/a3,-(sp)
		movea.l	a1,a3
		lea	-3*$80(a3),a1
		tst.b	PROG_FLAG(a2)			*プログラムされていれば
		sne	d0
		ext.w	d0
		move.w	d0,(a1)				*バーを表示する
		move.w	d0,$80(a1)

		tst.b	DOC_FLAG(a2)			*ドキュメントが有れば
		beq	title_prt1_21
		lea	doc_pat(pc),a0			* [DOC]を表示する
		lea	-6*$80+6(a3),a1
		adda.l	#$20000,a1
		move.l	(a0)+,(a1)
		move.l	(a0)+,$80(a1)
		move.l	(a0)+,$100(a1)
		move.l	(a0)+,$180(a1)
		move.l	(a0)+,$200(a1)
title_prt1_21:
		movem.l	(sp)+,d0-d1/a1/a3

		move.l	TITLE_ADR(a2),d0
		beq	title_prt1_90
		movea.l	d0,a0				*タイトル表示
		moveq	#2,d0
		lea.l	-$80*7+10(a1),a1
		tst.b	(a0)
		bne	title_prt1_30			*タイトルの代りにファイル名表示
		lea	$80*8(a1),a1
		lea	file_mes(pc),a0
		bsr	TEXT_4_8
		lea	-$80*8+7(a1),a1
		lea	FILE_NAME(a2),a0
title_prt1_30:
		bsr	TEXT_6_16

title_prt1_90:
		movem.l	(sp)+,d0-d2/a0-a3
		rts

dir_mes:	.dc.b	'<DIRECTORY>',0
file_mes:	.dc.b	'[NO TITLE] ___',$7F,0
prog_mes:	.dc.b	'PROG',0
		.even
doc_pat:	.dc.l	%00000100111100011100011110010000
		.dc.l	%00001000100010100010100000001000
		.dc.l	%00001000000000000000000000001000
		.dc.l	%00001000100010100010100000001000
		.dc.l	%00000100111100011100011110010000

*==================================================
*タイトル行消去
*	d0.w <- 表示位置
*==================================================

TITLE_CLR1:
		movem.l	d0/a0,-(sp)

		tst.b	SEL_VIEWMODE(a6)
		bne	title_clr1_90

		move.l	#TXTADR+352*$80,a0
		and.w	#15,d0
		ext.l	d0
		lsl.l	#7,d0
		lsl.l	#4,d0
		add.l	d0,a0

		moveq.l	#3,d0
		bsr	TEXT_ACCESS_ON

		moveq.l	#64,d0
		bsr	TXLINE_CLEAR

		bsr	TEXT_ACCESS_OF

title_clr1_90:
		movem.l	(sp)+,d0/a0
		rts


.if 0		*とりあえず削除
*
*	＊ＴＩＴＬＥ＿ＰＲＴ２
*機能：バッファ内のタイトルを特別位置に１つ表示
*入力：	Ａ０	ファイルネームバッファアドレス
*出力：なし
*参考：バッファ内にタイトルデーターの有無を問わずに表示するので注意
*

TITLE_PRT2:
		movem.l	d0-d1/a0-a2,-(sp)

		move.l	a0,a2
		move.l	#TXTADR+496*$80+28,a0		*表示エリア消去
		moveq.l	#3,d0
		bsr	TEXT_ACCESS_ON
		moveq.l	#36,d0
		bsr	TXLINE_CLEAR
		bsr	TEXT_ACCESS_OF
		lea.l	$80*8(a0),a1

		movea.l	TITLE_ADR(a2),a0
		moveq.l	#3,d0
		moveq.l	#0,d1
		bset.l	#31,d1
		bsr	TEXT_4_8

		MYONTIME
		move.w	d0,G_MES_TIME(a6)
		move.w	#-1,G_MES_FLAG(a6)

		movem.l	(sp)+,d0-d1/a0-a2
		rts
.endif

*
*	＊ＴＩＴＬＥ＿ＮＰ＿ＰＲＴ
*機能：SEL_BPRT(a6)位置のバッファを表示
*入出力：なし
*参考：
*

TITLE_NP_PRT:
		movem.l	d0-d2/a0,-(sp)

		tst.b	SEL_VIEWMODE(a6)
		bne	title_np_done

		bsr	TITLE_CLRALL

		tst.w	SEL_FMAX(a6)			*ファイルが１つもなければおわる
		beq	title_np_done

		move.w	SEL_BPRT(a6),d1			*バッファアドレス計算
		move.w	d1,d0
		bsr	get_fnamebuf

		moveq	#0,d0
		moveq.l	#9-1,d2				*９個表示する
title_np_lp0:
		bsr	TITLE_PRT1
		lea.l	32(a0),a0
		addq.w	#1,d0
		addq.w	#1,d1				*ファイルがなくなったら、おわる
		cmp.w	SEL_BMAX(a6),d1
		bcc	title_np_done
		dbra	d2,title_np_lp0

title_np_done:
		movem.l	(sp)+,d0-d2/a0
		rts

TITLE_CLRALL:
		movem.l	d0-d3,-(sp)

		move.w	#$7C7B,d1
		move.w	#$24,d2
		move.w	#$FF03,d3
		IOCS	_TXRASCPY

		movem.l	(sp)+,d0-d3
		rts

TITLE_SCDW:
		movem.l	d0-d3,-(sp)

		move.w	#$5C58,d1
		move.w	#$20,d2
		move.w	#%11,d3
		IOCS	_TXRASCPY

		moveq.l	#8,d0
		bsr	TITLE_CLR1

		movem.l	(sp)+,d0-d3
		rts

TITLE_SCUP:
		movem.l	d0-d3,-(sp)

		move.w	#$777B,d1
		move.w	#$20,d2
		move.w	#$FF03,d3
		IOCS	_TXRASCPY

		moveq.l	#0,d0
		bsr	TITLE_CLR1

		movem.l	(sp)+,d0-d3
		rts


*==================================================
*行番号を表示する
*==================================================

disp_linenum:
*		move.w	SEL_FCP(a6),d0
*		sub.w	SEL_BTOP(a6),d0
*		addq.w	#1,d0
*		movea.l	#BGADR+14*2+43*$80,a0
*		bsr	PRINT10_5KETA
*		move.w	SEL_FMAX(a6),d0
*		movea.l	#BGADR+17*2+43*$80,a0
*		bsr	PRINT10_5KETA
		rts


*==================================================
*メッセージ他消去
*==================================================

OVER_RIGHT_CLR:
		movem.l	d0-d1/a0,-(sp)				*ディレクトリ表示部分

		movea.l	#TXTADR+344*$80+34,a0
		moveq	#30,d1
		bra	g_mes_jp0


OVER_LINE_CLR:
		movem.l	d0-d1/a0,-(sp)				*見出し部分

		move.l	#TXTADR+344*$80,a0
		moveq	#34,d1
		bra	g_mes_jp0

G_MESSAGE_CLR:							*メッセージ部分
		movem.l	d0-d1/a0,-(sp)

		move.l	#TXTADR+496*$80+11,a0
		moveq	#21,d1

g_mes_jp0:
		moveq.l	#3,d0
		bsr	TEXT_ACCESS_ON

		move.w	d1,d0
		bsr	TXLINE_CLEAR

		bsr	TEXT_ACCESS_OF

		movem.l	(sp)+,d0-d1/a0
		rts

*==================================================
*メッセージ表示
*	a0.l <- メッセージ
*	G_MESSAGE_PRT  はアクセスモード３
*	G_MESSAGE_PRT2 はアクセスモード２
*==================================================

G_MESSAGE_PRT2:
		movem.l	d0-d1/a1,-(sp)
		moveq.l	#2,d0
		bra	g_message_jp
G_MESSAGE_PRT:
		movem.l	d0-d1/a1,-(sp)
		moveq.l	#3,d0

g_message_jp:
		bsr	G_MESSAGE_CLR

		move.l	#TXTADR+503*$80+11,a1
		moveq.l	#0,d1
		bsr	TEXT_4_8

		MYONTIME
		move.w	d0,G_MES_TIME(a6)
		move.w	#-1,G_MES_FLAG(a6)

		movem.l	(sp)+,d0-d1/a1
		rts


*==================================================
*メッセージ時間待ち消去
*	a0.l <- メッセージ
*	G_MESSAGE_PRT  はアクセスモード３
*	G_MESSAGE_PRT2 はアクセスモード２
*==================================================

G_MESSAGE_WAIT:
		movem.l	d0-d1,-(sp)

		tst.w	G_MES_FLAG(a6)
		beq	g_message_wait90

		MYONTIME			*表示から２秒たったら、
		sub.w	G_MES_TIME(a6),d0
		cmpi.w	#200,d0
		bls	g_message_wait90

		lea.l	G_MES_DEF(pc),a0		*デフォルトのメッセージを表示する
		bsr	G_MESSAGE_PRT2

		clr.w	G_MES_FLAG(a6)

g_message_wait90:
		movem.l	(sp)+,d0-d1
		rts

*==================================================
*ラインカーソル表示
*	d0.b <- カーソル位置
*==================================================

LINE_CUR_ON:
		movem.l	d0-d1/a0,-(sp)
		lea.l	linecur_pos(pc),a0

		move.b	(a0),d1
		cmp.b	d0,d1
		beq	line_cout_done

		bsr	LINE_CUR_OFF
		move.b	d0,(a0)

		move.l	#BGADR+0*2+45*$80,a0
		ext.w	d0
		lsl.w	#8,d0
		add.w	d0,a0

		move.w	#$172,d0
		moveq.l	#63,d1
		bsr	BG_LINE

line_cout_done:
		movem.l	(sp)+,d0-d1/a0
		rts

*==================================================
*ラインカーソル消去
*==================================================

LINE_CUR_OFF:
		movem.l	d0-d1/a0,-(sp)

		move.b	linecur_pos(pc),d0
		bmi	line_coff_done

		move.l	#BGADR+0*2+45*$80,a0
		ext.w	d0
		lsl.w	#8,d0
		add.w	d0,a0

		move.w	#$16f,d0
		moveq.l	#63,d1
		bsr	BG_LINE

		lea.l	linecur_pos(pc),a0
		st.b	(a0)
line_coff_done:
		movem.l	(sp)+,d0-d1/a0
		rts

linecur_pos:	.dc.b	-1
		.even


*==================================================
*カレントディレクトリを得る
*	a0.l <- パスネームの返るバッファ
*==================================================

GET_CURRENT:
		movem.l	d0/a0-a1,-(sp)
		move.b	#'.',(a0)
		move.b	#'\',1(a0)
		clr.b	2(a0)
		movea.l	a0,a1
		bsr	EXTRACT_FNAME
		movem.l	(sp)+,d0/a0-a1
		rts

*==================================================
*カレントディレクトリを移動
*	a0.l <- パスネームの入っているバッファ
*		ドライブ移動もする
*==================================================

SET_CURRENT:
		movem.l	d0-d1/a0-a1,-(sp)
		link	a5,#-256
		movea.l	sp,a1
		bsr	EXTRACT_FNAME
		move.l	d0,d1
		move.b	(a1),d0
		subi.b	#'A',d0
		ext.w	d0
		move.w	d0,-(sp)
		DOS	_CHGDRV
		move.w	(sp)+,d0
		addq.w	#1,d0
		bsr	DRIVE_CHECK
		bmi	set_current90
		move.l	a1,-(sp)		*移動してみて
		DOS	_CHDIR
		addq.l	#6,sp
		tst.l	d0
		bpl	set_current90
		clr.b	(a1,d1.l)		*だめならディレクトリ名だけにする
		move.l	a1,-(sp)
		DOS	_CHDIR
		addq.l	#4,sp
set_current90:
		unlk	a5
		movem.l	(sp)+,d0-d1/a0-a1
		rts


*==================================================
*カレントディレクトリ移動
*	a0.l <- ディレクトリ名(絶対、相対なんでもあり）
*==================================================

CHANGE_DIR:
		bsr	SET_CURRENT
		clr.w	SEL_CHANGE(a6)
		rts


*==================================================
*ファイル名展開
*	a0.l <- ファイル名
*	a1.l <- 絶対パス名格納アドレス
*	d0.l -> ディレクトリ名の長さ(ファイル名含まず)
*==================================================

EXTRACT_FNAME:
		movem.l	d1-d2/a0-a2,-(sp)
		link	a5,#-96			*ローカルエリア確保
		movea.l	sp,a2
		moveq	#0,d2

		move.l	a2,-(sp)		*絶対パスネームに展開
		move.l	a0,-(sp)
		DOS	_NAMECK
		addq.l	#8,sp
		move.l	d0,d1
		bmi	extract_fname90

		movea.l	a2,a0
extract_fname10:
		move.b	(a0)+,(a1)+		*パス名コピー
		bne	extract_fname10
		subq.l	#1,a1
		move.l	a0,d2
		sub.l	a2,d2
		subq.l	#1,d2
		cmpi.b	#$FF,d1			*ファイル名の指定があれば、
		beq	extract_fname90

		lea	67(a2),a0
extract_fname20:
		move.b	(a0)+,(a1)+		*ファイル名コピー
		bne	extract_fname20
		subq.l	#1,a1

		lea	86(a2),a0
extract_fname30:
		move.b	(a0)+,(a1)+		*拡張子コピー
		bne	extract_fname30
		subq.l	#1,a1

extract_fname90:
		clr.b	(a1)
		move.l	d2,d0
		unlk	a5			*ローカルエリア開放
		movem.l	(sp)+,d1-d2/a0-a2
		rts


*==================================================
* コンソール範囲縮小
*==================================================

SHRINK_CONSOLE:
		movem.l	d0-d2/a0-a1,-(sp)

		move.l	#0*$10000+512,d1	*表示エリアを(0,512)-(1023,527)に変更
		move.l	#127*$10000+0,d2
		IOCS	_B_CONSOL
		movem.l	d1-d2,CONSOLE(a6)

		movem.l	(sp)+,d0-d2/a0-a1
		rts

*==================================================
* コンソール範囲戻す
*==================================================

RESUME_CONSOLE:
		movem.l	d0-d2/a0-a1,-(sp)

		movem.l	CONSOLE(a6),d1-d2		*表示エリアを戻す
		IOCS	_B_CONSOL

		movem.l	(sp)+,d0-d2/a0-a1
		rts


			.data
			.even

*			AC,詰,ＸＸ,ＹＹ,文字
FILESEL_MES:	.dc.b	02,00,00,0,1,088,'FILENAME',0
		.dc.b	01,00,06,2,1,088,'PRG',0
		.dc.b	01,00,08,2,1,088,'CLR',0
		.dc.b	01,00,10,2,1,088,'EJECT',0
		.dc.b	02,00,20,1,1,088,'MUSIC TITLE or DIRECTORY TITLE',0
		.dc.b	01,00,33,4,1,246,'AUTO',0
		.dc.b	01,00,36,2,1,246,'SHUFF',0
		.dc.b	01,00,41,6,1,246,'REP.',0
		.dc.b	01,00,44,3,1,246,'INTRO',0
		.dc.b	01,00,47,1,1,246,'ALLDIR',0
		.dc.b	01,00,50,3,1,246,'PROG.',0
		.dc.b	01,00,55,1,1,248,'LT',0
		.dc.b	01,00,58,1,1,248,'BT',0
		.dc.b	01,00,61,1,1,248,'IT',0
		.dc.b	0

DIRECTORY:	.dc.b	'< dir >',0
G_MES_DEF:	.dc.b	'"MMDSP" REALTIME GRAPHICAL USER INTERFACE.',0
*G_MES_No1:	.dc.b	'タイトル検索中です',0
*G_MES_No2:	.dc.b	'タイトル検索を中断しました',0
*G_MES_No3:	.dc.b	'タイトル検索を再開します',0
*G_MES_No4:	.dc.b	'タイトル検索を終了しました',0
G_MES_No5:	.dc.b	'バッファがあふれました',0
*G_MES_No6:	.dc.b	'エラーが発生しました',0
		.dc.b	0

CURDRV_BACK:	.dc.b	0

		.even

STITLE:	.dc.w	%0111111110011111,%1110110000000001,%1111111001111111,%1011111111110011,%1111100111111110
	.dc.w	%1111111110111111,%1110110000000011,%1111111011111111,%1011111111110111,%1111110111111111
*	.dc.w	%1100000000110000,%0000110000000011,%0000000011000000,%0000001100000110,%0000110110000011
	.dc.w	%1100000000110000,%0000110000000011,%0000000011000000,%0000001100000110,%0000110110000011
	.dc.w	%1111111100111111,%1000110000000011,%1111100011000000,%0000001100000110,%0000110111111111
	.dc.w	%0111111110111111,%1000110000000011,%1111100011000000,%0000001100000110,%0000110111111110
*	.dc.w	%0000000110110000,%0000110000000011,%0000000011000000,%0000001100000110,%0000110110000011
	.dc.w	%0000000110110000,%0000110000000011,%0000000011000000,%0000001100000110,%0000110110000011
	.dc.w	%1111111110111111,%1110111111111011,%1111111011111111,%1000001100000111,%1111110110000011
	.dc.w	%1111111100011111,%1110011111111001,%1111111001111111,%1000001100000011,%1111100110000011
	.dc.w	%0000000000000000,%0000000000000000,%0000000000000000,%0000000000000000,%0000000000000000
	.dc.w	%1111111111111111,%1111111111111111,%1111111111111111,%1111111111111111,%1111111111111111

		.end

ファイルネームバッファ(32byte/file)
+00.b	データ種別(0:dir 1:mdx...) マイナスだったらディレクトリ名
+01.b	オート時演奏済みフラグ
+02.w	(ディレクトリの場合ならファイル数がくる)
+04.l	タイトルバッファのアドレス、未検索なら0
+08.b	ファイル名+$00
+31	終わり

タイトルバッファ
+00	タイトル
+??	$00


ファイルセレクタに関しての構想・・・

状態
０：何も行われてない、初めての状態
１：タイトル検索中	(title)
２：ファイルセレクト中	(title)
３：ドライブセレクト中	(title)
*４：ファイルセレクト中	(file)
*５：ドライブセレクト中	(file)


拡張子と純正ドライバ一覧
*MDX:MXDRV
*MDR:MADRV
*RCP:RCD
*MDF:LZM
*MCP:RCD
*MDI:MDD
*SNG:ミュージくん/Mu-1/MusicStudio
*MID:STD MIDI
*STD:STD MIDI
*MFF:STD MIDI
*SEQ:芸達者
*MDZ:MLD
*MDN:NAGDRV
*KMD:KIMELA
*ZMS:ZMUSIC
*ZMD:ZMUSIC
*OPM:OPMDRV
*ZDF:LZZ
*MM2:
*MMC:

*演奏ファイル識別コード一覧
* 0:none 1:MDX  2:MDR  3:RCP  4:MDF  5:MCP  6:MDI  7:SNG
* 8:MID  9:STD 10:MFF 11:SEQ 12:MDZ 13:MDN 14:KMD 15:ZMS
*16:ZMD 17:OPM 18:ZDF 19:MM2 20:MMC

