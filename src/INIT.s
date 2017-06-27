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
		.include	KEYCODE.mac

			.text
			.even

TIMERD_VECTOR:	.equ	$000110
VDISP_VECTOR:	.equ	$000118
TIMERA_VECTOR:	.equ	$000134
RASTER_VECTOR:	.equ	$000138


*==================================================
*起動時のイニシャライズ
*	a0.l <- 起動時に入ってくる値をそのまま渡してね
*	a6.l -> ワークエリアの先頭アドレス
*	d0.l -> 負なら、エラー(ccrにも返る)
*==================================================

SYSTEM_INIT:
		movem.l	a0-a2,-(sp)
		link	a5,#0
		movea.l	a0,a2
		movea.l	$30(a0),a1			*メモリブロック縮小
		lea.l	$10(a0),a0			*起動時のa1を使わないのは、
		adda.l	#BUF_SIZE,a1			*古いlzxでも動くようにするため
		suba.l	a0,a1
		move.l	a1,-(sp)
		move.l	a0,-(sp)
		DOS	_SETBLOCK
		tst.l	d0
		bpl	system_init10
		pea	MES_NOMEM(pc)
		DOS	_PRINT
		moveq	#8,d0
		bset.l	#31,d0
		bra	system_init90
system_init10:
		lea	START(pc),a6			*ワークエリアポインタ設定
		adda.l	#BUFFER-START,a6
		bsr	CLEAR_WORK			*ワークエリアのクリア

*		lea.l	DBF_ST(a6),a0
*		move.l	#DBF_ED-DBF_ST,d0	*バッファ初期化
*		bsr	HSCLR

		move.l	a2,MM_MEMPTR(a6)		*メモリ管理ポインタの保存
		pea.l	SYSTEM_TITLE(pc)		*タイトル表示っ！
		DOS	_PRINT
		moveq	#0,d0

system_verchk:
		DOS	_VERNUM			*Humanバージョンチェック
		move.l	d0,d1
		moveq	#0,d0
		cmpi.w	#$0200,d1		*v2.00以上
		bcs	system_verchk10
		swap	d1
		cmpi.w	#'68',d1
		beq	system_verchk90
system_verchk10:
		pea	MES_HUVER(pc)
		DOS	_PRINT
		moveq	#-1,d0
system_verchk90:

system_init90:
		unlk	a5
		movem.l	(sp)+,a0-a2
		tst.l	d0
		rts


*==================================================
*ワークエリア初期化
*==================================================

CLEAR_WORK:
		movem.l	d0-d1/a0,-(sp)
		move.w	#(DBF_ED-DBF_ST)/16-1,d1	*バッファ初期化
		lea.l	DBF_ST(a6),a0
		moveq	#0,d0
clear_work10:
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		dbra	d1,clear_work10
		movem.l	(sp)+,d0-d1/a0
		rts


*==================================================
*引数解析
*	a2.l <- コマンドライン
*	d0.l -> 負ならエラー
*==================================================

*引数解析メイン

CHECK_OPTION:
		movem.l	d1/a0/a2,-(sp)
		moveq	#0,d0
		tst.b	(a2)+
		beq	check_option90
check_option10:
		bsr	check_token		*引数のチェック
		bgt	check_option10		*引数の終わりかエラーまで繰り返す
check_option90:
		movem.l	(sp)+,d1/a0/a2
		rts

*引数のチェック

check_token:
		bsr	skip_space		*次がなければ、0を返す
		move.b	(a2)+,d0
		beq	check_token90
		cmpi.b	#'-',d0			*オプション文字 '-' '/'ならば、
		beq	set_option		*オプション解析
		cmpi.b	#'/',d0
		beq	set_option
		subq.l	#1,a2			*それ以外の文字ならば、ディレクトリ指定
		bra	set_directory
check_token90:
		moveq	#0,d0
		rts

*オプション解析

set_option:
		bsr	search_option
		bmi	usage
		bsr	exec_option
		bmi	usage
		moveq	#1,d0
		rts

*ディレクトリ指定

set_directory:
		lea	CURRENT(a6),a0		*ディレクトリ名をコピー
		tst.b	(a0)
		bne	usage
set_directory10:
		cmpi.b	#' ',(a2)
		bls	set_directory20
		move.b	(a2)+,(a0)+
		bra	set_directory10
set_directory20:
		clr.b	(a0)
		moveq	#1,d0
		rts

usage:
		pea.l	MES_USAGE(pc)		*使用法表示
		DOS	_PRINT
		addq.l	#4,sp
		moveq	#-1,d0
		rts

*オプションテーブルから探す
*	a2.l <- '-'の次の位置
*	d0.l -> オプション番号 (負ならエラー)
*	a2.l -> 次の位置

search_option:
		movem.l	d1-d2/a0-a1,-(sp)
		lea	option_tbl(pc),a1		*テーブルの最初から、
		moveq	#0,d2
search_option10:
		movea.l	a2,a0
search_option20:
		move.b	(a1)+,d1			*文字列比較して
		beq	search_option40
		move.b	(a0)+,d0
		ori.b	#$20,d0
		cmp.b	d1,d0
		beq	search_option20
search_option30:
		tst.b	(a1)+				*不一致なら、次のオプション
		bne	search_option30
		tst.b	(a1)				*テーブルの最後なら、終わる
		beq	search_option90
		addq.l	#1,d2
		bra	search_option10
search_option40:
		movea.l	a0,a2				*一致したら、その番号を返す
		move.l	d2,d0
		movem.l	(sp)+,d1-d2/a0-a1
		rts
search_option90:
		moveq	#-1,d0				*一致するオプションは無かった
		movem.l	(sp)+,d1-d2/a0-a1
		rts

option_tbl:
		.dc.b	'mxdrv',0
		.dc.b	'madrv',0
		.dc.b	'mld',0
		.dc.b	'rcd',0
		.dc.b	'zmusic',0
		.dc.b	'mcdrv',0
		.dc.b	'g',0
		.dc.b	'a',0
		.dc.b	's',0
		.dc.b	'n',0
		.dc.b	'f',0
		.dc.b	'k',0
		.dc.b	'r',0
		.dc.b	0
		.even

*オプション処理
*	d0.w <- オプション番号
*	d0.l -> 負ならエラー

exec_option:
		add.w	d0,d0
		move.w	option_jmp(pc,d0.w),d0
		jsr	option_jmp(pc,d0.w)
		rts

option_jmp:
		.dc.w	option_mxdrv-option_jmp
		.dc.w	option_madrv-option_jmp
		.dc.w	option_mld-option_jmp
		.dc.w	option_rcd-option_jmp
		.dc.w	option_zmusic-option_jmp
		.dc.w	option_mcdrv-option_jmp
		.dc.w	option_g-option_jmp
		.dc.w	option_a-option_jmp
		.dc.w	option_s-option_jmp
		.dc.w	option_n-option_jmp
		.dc.w	option_f-option_jmp
		.dc.w	option_k-option_jmp
		.dc.w	option_r-option_jmp


option_mxdrv:
		move.w	#MXDRV,DRV_MODE(a6)
		moveq	#0,d0
		rts

option_madrv:
		move.w	#MADRV,DRV_MODE(a6)
		moveq	#0,d0
		rts

option_mld:
		move.w	#MLD,DRV_MODE(a6)
		moveq	#0,d0
		rts

option_rcd:
		move.w	#RCD,DRV_MODE(a6)
		moveq	#0,d0
		rts

option_zmusic:
		move.w	#ZMUSIC,DRV_MODE(a6)
		moveq	#0,d0
		rts

option_mcdrv:
		move.w	#MCDRV,DRV_MODE(a6)
		moveq	#0,d0
		rts

option_g:					*グラフィック合成モード指定
		moveq	#1,d0			*default: 1
		bsr	get_num
		cmpi.w	#3,d0
		bhi	option_err
		move.b	d0,GRAPH_MODE(a6)
		moveq	#0,d0
		rts

option_a:
		move.b	#1,AUTOMODE(a6)		*AUTOモード指定
		bra	option_sa
option_s:
		move.b	#2,AUTOMODE(a6)		*SHUFFLEモード指定
option_sa:
		moveq	#0,d0
		bsr	get_4bin
		tst.l	d0
		bmi	option_err
		move.b	d0,AUTOFLAG(a6)
		moveq	#0,d0
		rts


*2進数4bit表現から数値に変換する
*	a2.l <- コマンドライン
*	d0.l <- デフォルト値
*	d0.l -> 数値(負ならエラー)

get_4bin:
		movem.l	d1-d2/d7,-(sp)
		bsr	skip_space

		move.b	(a2),d0		*最初の文字が0-1でなかったら、
		subi.b	#'0',d0
		cmpi.b	#1,d0
		bhi	get_4bin99	*デフォルト値をそのまま返す

		moveq	#0,d1
		moveq	#-1,d2
		moveq	#4-1,d7
get_4bin10:
		moveq	#0,d0
		move.b	(a2),d0
		subi.b	#'0',d0
		cmpi.b	#1,d0
		bhi	get_4bin90
		addq.l	#1,a2
		lsl.l	#3,d0
		lsr.l	d7,d0
		add.l	d0,d1
		dbra	d7,get_4bin10
		move.l	d1,d2
get_4bin90:
		move.l	d2,d0
get_4bin99:
		movem.l	(sp)+,d1-d2/d7
		rts


option_n:					*セレクタ無使用
		st.b	SEL_NOUSE(a6)
		moveq	#0,d0
		rts

option_f:					*テキスト強制使用
		st.b	FORCE_TVRAM(a6)
		moveq	#0,d0
		rts

option_k:
		st.b	RESIDENT(a6)
		moveq	#__XF4,d0		*起動キー1
		bsr	get_hex
		andi.w	#$7f,d0
		move.b	d0,HOTKEY1(a6)
		bset.b	d0,HOTKEY1MASK(a6)
		lsr.b	#3,d0
		addi.w	#$800,d0
		move.w	d0,HOTKEY1ADR(a6)

		moveq	#__XF5,d0		*起動キー2
		cmpi.b	#',',(a2)
		bne	option_k10
		addq.l	#1,a2
		bsr	get_hex
option_k10:
		andi.w	#$7f,d0
		move.b	d0,HOTKEY2(a6)
		move.b	d0,HOTKEY2(a6)
		bset.b	d0,HOTKEY2MASK(a6)
		lsr.b	#3,d0
		addi.w	#$800,d0
		move.w	d0,HOTKEY2ADR(a6)
		cmp.w	HOTKEY1ADR(a6),d0
		bne	option_k20
		move.b	HOTKEY2MASK(a6),d0
		or.b	HOTKEY1MASK(a6),d0
		move.b	d0,HOTKEY1MASK(a6)
		move.b	d0,HOTKEY2MASK(a6)
option_k20:
		moveq	#0,d0
		rts


option_r:
		st.b	REMOVE(a6)
		moveq	#0,d0
		rts

option_err:
		moveq	#-1,d0
		rts

*----------------------------------------
*１０進数を数値に変換
*	a2.l <- 文字列のポインタ
*	d0.w <- デフォルト値
*	d0.w -> 数値
*----------------------------------------

get_num:
		move.l	d1,-(sp)
		bsr	skip_space

		moveq	#0,d1
		move.b	(a2)+,d1		*最初の文字が数字でなかったら、
		subi.b	#'0',d1
		cmpi.b	#9,d1
		bhi	get_num2		*デフォルト値を持って返る

		move.w	d1,d0
get_num1:
		move.b	(a2)+,d1
		subi.b	#'0',d1
		cmpi.b	#9,d1
		bhi	get_num2
		mulu	#10,d0
		add.w	d1,d0
		bra	get_num1
get_num2:
		subq.l	#1,a2
		move.l	(sp)+,d1
		rts

*----------------------------------------
*１６進数を数値に変換
*	a2.l <- 文字列のポインタ
*	d0.w <- デフォルト値
*	d0.w -> 数値
*----------------------------------------

GET_HEXN	macro
		local	get_hexn9
		move.b	(a2)+,d1
		subi.b	#'0',d1
		cmpi.b	#9,d1
		bls	get_hexn9
		addi.b	#'0',d1
		andi.b	#$df,d1
		subi.b	#'A'-10,d1
		cmpi.b	#15,d1
get_hexn9:
		endm

get_hex:
		move.l	d1,-(sp)
		bsr	skip_space

		GET_HEXN			*最初の文字が16進文字でなかったら、
		bhi	get_hex90		*デフォルト値を持って返る

		move.w	d1,d0
get_hex10:
		GET_HEXN
		bhi	get_hex90
		lsl.w	#4,d0
		add.b	d1,d0
		bra	get_hex10
get_hex90:
		subq.l	#1,a2
		move.l	(sp)+,d1
		rts

*----------------------------------------
*スペースを飛ばす
*	a2.l <- 文字列のポインタ
*	a2.l -> 次のスペースでない文字のポインタ
*----------------------------------------

skip_space:
		move.l	d0,-(sp)
skip_space10:
		move.b	(a2)+,d0
		cmpi.b	#' ',d0			*スペースと、
		beq	skip_space10
		cmpi.b	#9,d0			*タブを飛ばす
		beq	skip_space10
		subq.l	#1,a2
		move.l	(sp)+,d0
		rts


*==================================================
*起動可能かチェックする
*	d0.l -> エラーコード(負なら起動不可能、ccrにも返る)
*		3210
*		|||+--	ドライバが組み込まれていない又はバージョンの低すぎ
*		||+---	TEXT VRAMが使用中
*		|+----	TimerA/Raster/Vdisp/TimerD割り込みがすべて使用中
*		+-----	
*==================================================

SYSTEM_CHCK:
		movem.l	d1/d7/a0-a1,-(sp)
		moveq	#0,d7

syschk_driver:
		bsr	SEARCH_DRIVER			*ドライバ常駐チェック
		tst.l	d0
		bne	syschk_driver90
		bset.l	#31,d7				*ドライバが常駐していない
		bset.l	#0,d7
		bra	syschk_error
syschk_driver90:

syschk_text:
		tst.b	FORCE_TVRAM(a6)			*テキスト使用チェック
		bne	syschk_text90
		moveq	#1,d1
		moveq	#-1,d2
		IOCS	_TGUSEMD
		cmpi.b	#2,d0
		bne	syschk_text90
		bset.l	#31,d7				*テキスト使用中
		bset.l	#1,d7
		bra	syschk_error
syschk_text90:

syschk_vector:
		moveq	#1,d0				*ベクタ使用チェック
		tst.b	TIMERA_VECTOR.w
		bne	syschk_vector90
		moveq	#2,d0
		tst.b	RASTER_VECTOR.w
		bne	syschk_vector90
		moveq	#3,d0
		cmpi.b	#$ff,VDISP_VECTOR.w+1
		beq	syschk_vector90
		moveq	#4,d0
		tst.b	TIMERD_VECTOR.w
		bne	syschk_vector90
		bset.l	#31,d7				*ベクタが全て使用中
		bset.l	#2,d7
		bra	syschk_error
syschk_vector90:
		move.w	d0,VECTMODE(a6)

syschk_error:
syschk90:
		move.l	d7,d0
		movem.l	(sp)+,d1/d7/a0-a1
		rts


*==================================================
*エラーメッセージの表示
*	d0.l <- SYSTEM_CHCKで得られた結果
*	ccr  -> tst.l d0の結果(d0.lは壊れない)
*==================================================

PRINT_ERROR:
		movem.l	d0/a0,-(sp)

prnerr_driver:
		btst.l	#0,d0
		beq	prnerr_driver90
		lea	DRIVER_NONE(pc),a0
		tst.w	DRV_MODE(a6)
		beq	prnerr_driver10
		lea	DRIVER_NONE2(pc),a0
prnerr_driver10:
		pea	(a0)
		bra	print_error10
prnerr_driver90:

prnerr_text:
		btst.l	#1,d0
		beq	prnerr_text90
		pea	TEXT_AUSE(pc)
		bra	print_error10
prnerr_text90:

prnerr_vector:
		btst.l	#2,d0
		beq	prnerr_vector90
		pea.l	VECTOR_AUSE(pc)
		bra	print_error10
prnerr_vector90:

		DRIVER	DRIVER_NAME			*ドライバの名前を表示
		move.l	d0,-(sp)
		DOS	_PRINT
		addq.l	#4,sp
		pea	MES_MODE(pc)

print_error10:
		DOS	_PRINT
		addq.l	#4,sp

		movem.l	(sp)+,d0/a0
		tst.l	d0
		rts


*==================================================
*ドライバ関係の初期化
*==================================================

DRIVER_INIT:
		movem.l	d0/a0,-(sp)

		lea	TRACK_STATUS(a6),a0
		move.l	a0,KEYB_TRBUF(a6)
		move.l	a0,LEVEL_TRBUF(a6)
		lea	CHST_BF(a6),a0
		move.l	a0,KEYB_CHBUF(a6)

		DRIVER	DRIVER_SETUP			*ドライバ初期化

		movem.l	(sp)+,d0/a0
driver_rts:	rts


*==================================================
*割り込みベクタの設定
*	a0.l <- 割り込み処理アドレス
*==================================================

VECTOR_INIT:
		movem.l	d0-d1/a0-a1,-(sp)
		ori.w	#$0700,sr
		movea.l	a0,a1
		move.w	VECTMODE(a6),d0
		cmpi.w	#1,d0
		beq	set_timera
		cmpi.w	#2,d0
		beq	set_raster
		cmpi.w	#3,d0
		beq	set_vdisp
		cmpi.w	#4,d0
		beq	set_timerd
set_vdisp:
		move.l	VDISP_VECTOR.w,ORIG_VECTOR(a6)
		move.l	a1,VDISP_VECTOR.w	*VDISP割り込み設定
		movea.l	#MFP,a0
		bset.b	#6,$09(a0)		*VDISP ENABLE
		bset.b	#6,$15(a0)		*VDISP MASK CLEAR
		bra	vector_init10
set_timera:
		move.w	#$001,d1		*垂直同期割り込み設定
		IOCS	_VDISPST
		bra	vector_init10
set_raster:
		moveq	#0,d1			*ラスタ割り込み設定
		IOCS	_CRTCRAS
		bra	vector_init10
set_timerd:
		move.w	#$07ff,d1		*ＴｉｍｅｒＤ割り込み設定
		IOCS	_TIMERDST
vector_init10:
*		pea	trap14_patch(pc)	*エラー処理ルーチン設定
*		move.w	#$2e,-(sp)
*		DOS	_INTVCS
*		addq.l	#6,sp
*		lea	trap14_vector(pc),a0
*		move.l	d0,(a0)

		andi.w	#$F8FF,sr

		movem.l	(sp)+,d0-d1/a0-a1
dummyjob:
		rts


*==================================================
*ＭＭＤＳＰ常駐チェック
*	d0.l -> 常駐MEMPTR(負なら常駐していない。ccrにも返る)
*==================================================

RESID_CHECK:
		movem.l	a0,-(sp)
		movea.l	MM_MEMPTR(a6),a0
resid_check10:
		move.l	(a0),d0				*最初のメモリブロックを探す
		beq	resid_check11
		movea.l	d0,a0
		bra	resid_check10
resid_check11:
		cmpi.l	#'MMDS',MM_HEADER-START+$100(a0)	*識別文字のチェック
		bne	resid_check19
		cmpi.l	#'P000',MM_HEADER-START+$104(a0)
		bne	resid_check19
		cmpi.l	#STAYID,MM_STAYFLAG-START+$100(a0)	*常駐マークのチェック
		bne	resid_check19
		move.l	a0,d0
		bra	resid_check90
resid_check19:
		move.l	$0c(a0),d0			*次のメモリブロックへ
		movea.l	d0,a0
		bne	resid_check11
		moveq	#-1,d0				*見つからなかったら負を返す
resid_check90:
		movem.l	(sp)+,a0
		rts


*==================================================
*ブレーク禁止
*==================================================

KILL_BREAK:
		move.w	#-1,-(sp)		*break kill
		DOS	_BREAKCK
		move.w	d0,BREAKCK_SAVE(a6)
		move.w	#2,-(sp)
		DOS	_BREAKCK
		addq.l	#4,sp
		rts


*==================================================
*ブレーク禁止解除
*==================================================

RESUME_BREAK:
		move.w	BREAKCK_SAVE(a6),-(sp)	*break 戻す
		DOS	_BREAKCK
		addq.l	#2,sp
		rts


.if 0	*不要
*==================================================
*エラー処理ルーチン
*==================================================

trap14_patch:
		cmpi.w	#$1000,d7			*ドライブの準備ができていない
		bcs	trap14_orig
		cmpi.w	#$8000,d7
		bcc	trap14_orig
		cmpi.b	#$02,d7
		bne	trap14_orig
		moveq	#2,d7				*ならば、強制的に無視を選択
		rte

trap14_orig:
		move.l	trap14_vector(pc),-(sp)		*それ以外のエラーは、本家へ
		rts

trap14_vector:
		.dc.l	0
.endif


*==================================================
*割り込みベクタ復帰
*==================================================

VECTOR_DONE:
		movem.l	d0-d1/a0-a1,-(sp)

		ori.w	#$0700,sr
		suba.l	a1,a1
		move.w	VECTMODE(a6),d0
		cmpi.w	#1,d0
		beq	res_timera
		cmpi.w	#2,d0
		beq	res_raster
		cmpi.w	#3,d0
		beq	res_vdisp
		cmpi.w	#4,d0
		beq	res_timerd
res_vdisp:
		move.l	ORIG_VECTOR(a6),VDISP_VECTOR.w	*VDISP割り込み解除
		movea.l	#MFP,a0
		bclr.b	#6,$09(a0)		*VDISP DISABLE
		bclr.b	#6,$15(a0)		*VDISP MASK SET
		bra	vector_done90
res_timera:
		IOCS	_VDISPST		*垂直同期割り込み解除
		bra	vector_done90
res_raster:
		IOCS	_CRTCRAS		*ラスタ割り込み解除
		bra	vector_done90
res_timerd:
		IOCS	_TIMERDST		*ＴｉｍｅｒＤ割り込み解除
vector_done90:

		andi.w	#$F8FF,sr

		movem.l	(sp)+,d0-d1/a0-a1
		rts


*==================================================
*画面の初期化
*==================================================

DISP_INIT:
		movem.l	d0-d2,-(sp)

		moveq.l	#1,d1				*テキスト使用中セット
		moveq.l	#2,d2
		IOCS	_TGUSEMD

		move.w	#3,-(sp)			*ファンクションキー状態保存
		move.w	#14,-(sp)
		DOS	_CONCTRL
		addq.l	#4,sp
		move.w	d0,FUNCMD(a6)

		moveq	#-1,d1				*CRTモード保存
		IOCS	_CRTMOD
		move.w	d0,CRTMD(a6)

		movea.l	#SPPALADR,a0			*テキストパレット保存
		lea	TXTPALSAVE(a6),a1
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+

		clr.w	VIDEO_EFFECT

		move.w	#$10C,d1
		IOCS	_CRTMOD

		IOCS	_OS_CUROF

		bsr	CLEAR_TEXT

		bsr	MOUSE_INIT
		bsr	SPRITE_INIT

		movem.l	(sp)+,d0-d2
		rts


*==================================================
*実行前の画面の復帰
*==================================================

DISP_DONE:
		movem.l	d0-d2,-(sp)

		move.w	CRTMD(a6),d1
		ori.w	#$0100,d1
		IOCS	_CRTMOD

		bsr	CLEAR_TEXT

		lea	TXTPALSAVE(a6),a0		*テキストパレット復旧
		movea.l	#SPPALADR,a1
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+

*		clr.w	-(sp)
*		move.w	#16,-(sp)
*		DOS	_CONCTRL
*		addq.l	#4,sp

		move.w	FUNCMD(a6),-(sp)
		move.w	#14,-(sp)
		DOS	_CONCTRL
		addq.l	#4,sp

		moveq	#1,d1				*テキスト使用中解除
		moveq	#3,d2
		IOCS	_TGUSEMD

		IOCS	_MS_INIT
		IOCS	_OS_CURON
		bsr	MOUSE_ERASE

		movem.l	(sp)+,d0-d2
		rts


*==================================================
*起動時のパレットを保存する
*==================================================

SAVE_GPALET:
		movem.l	d0/a0-a1,-(sp)
		movea.l	#GPALADR,a0
		movea.l	GTONE_TBL(a6),a1
		lea	512*32(a1),a1
		moveq	#16-1,d0
save_gpalet10:
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		dbra	d0,save_gpalet10
		movem.l	(sp)+,d0/a0-a1
		rts


*==================================================
*起動時のパレットに戻す
*==================================================

RESUME_GPALET:
		movem.l	d0/a0-a1,-(sp)
		movea.l	GTONE_TBL(a6),a0
		lea	512*32(a0),a0
		movea.l	#GPALADR,a1
		moveq	#16-1,d0
resume_gpalet10:
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		dbra	d0,resume_gpalet10
		movem.l	(sp)+,d0/a0-a1
		rts


*==================================================
*ＭＭＤＳＰ画面をつくる
*==================================================

DISPLAY_MAKE:
		bsr	SYSDIS_MAKE
		bsr	KEYBORD_MAKE
*		bsr	REGISTER_MAKE
		bsr	LEVELM_MAKE
		bsr	PANEL_MAKE
		bsr	SPEANA_MAKE
		bsr	SELECTOR_MAKE
		rts


*==================================================
*各処理用のテーブルを作る
*	参考：テーブルの内容は
*	１６／１０進表示：ワードサイズのＢＧキャラ／カラーコード
*	３分の１化	：１byte(0-127)を３分の１にした物*2が格納されている
*	８－＞６ビット	：(0-255)を６ビットに圧縮したものが格納されている
*	８－＞４ビット	：(0-255)を４ビットに圧縮したものが格納されている
*	パレット	：0-31の濃度のパレットテーブルの内容(512bytes*32)
*==================================================

TABLE_MAKE:
		movem.l	d0-d3/a0-a1,-(sp)

		bsr	MAKE_BGTBL
		bsr	MAKE_96TO32
		bsr	MAKE_8TO6
		bsr	MAKE_8TO4
		bsr	MAKE_PALTBL

		movem.l	(sp)+,d0-d3/a0-a1
		rts

*ＢＧ数値表示用テーブル作成

MAKE_BGTBL::
		lea.l	BG16_TB(a6),a0			*１６進表示用
		move.w	#$0C_80,d1
		move.w	#255,d0
make_bgtbl10:
		move.w	d1,(a0)+
		add.w	#$01_00,d1
		btst.l	#12,d1
		beq	make_bgtbl11
		addq.b	#1,d1
make_bgtbl11:
		and.w	#$0F_FF,d1
		or.w	#$0C_00,d1
		dbra	d0,make_bgtbl10

		lea.l	BG16_TB(a6),a0			*同１０進用
		lea.l	BG10_TB(a6),a1
		move.w	#9,d0
make_bgtbl20:
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		lea.l	12(a0),a0
		dbra	d0,make_bgtbl20
		rts

*１／３化テーブル作成

MAKE_96TO32::
		lea.l	FROM96_TO32(a6),a0		*１／３化テーブル
		moveq	#-1,d1
		moveq.l	#129/3-1,d0
make_96to32_10:
		move.b	d1,(a0)+
		move.b	d1,(a0)+
		move.b	d1,(a0)+
		dbra	d0,make_96to32_10

		lea.l	FROM96_TO32(a6),a0
		moveq.l	#0,d1
		moveq.l	#32+10-1,d0
make_96to32_20:
		move.b	d1,(a0)+
		move.b	d1,(a0)+
		move.b	d1,(a0)+
		addq.b	#2,d1
		dbra	d0,make_96to32_20
		rts

*８→６ドット変換テーブル作成

MAKE_8TO6::
		lea	TO6BIT_TBL(a6),a0		*６ビット化テーブル
		moveq	#0,d2
make_8to6_10:
		move.b	d2,d0
		move.b	d0,d1
		add.b	d0,d0
		and.b	#%1000_1000,d1
		or.b	d0,d1

		and.b	#%1110_1110,d1
		move.b	d1,d0
		add.b	d1,d1

		and.b	#%1110_0000,d0
		and.b	#%0001_1100,d1
		or.b	d1,d0

		move.b	d0,(a0)+
		addq.b	#1,d2
		bcc	make_8to6_10
		rts

*８→４ドット変換テーブル作成

MAKE_8TO4::
		lea	TO4BIT_TBL(a6),a0		*４ビット化テーブル
		moveq	#0,d2
make_8to4_10:
		move.b	d2,d1		*7-5-3-1-
		add.b	d1,d1		*6-4-2-0-
		or.b	d2,d1		*a-b-c-d-
		moveq	#0,d0
		roxr.b	#2,d1
		roxr.b	#1,d0		*d0000000
		roxr.b	#2,d1
		roxr.b	#1,d0		*cd000000
		roxr.b	#2,d1
		roxr.b	#1,d0		*bcd00000
		roxr.b	#2,d1
		roxr.b	#1,d0		*abcd0000
		move.b	d0,d1
		ror.b	#4,d1
		or.b	d1,d0		*abcdabcd
		move.b	d0,(a0)+
		addq.b	#1,d2
		bcc	make_8to4_10
		rts

*パレットテーブル作成

*パレット下位計算
*	d1.w <- tone(0-31)
*	d2.w <- palet low(0-255)
*	a1.l <- 乗算テーブル
*	d3.b -> toned palet low

GTONE_CALC_LOW	macro
		moveq	#$3e,d3			*BLUE (Iは無視)
		and.w	d2,d3
		lsr.w	#1,d3
		move.b	(a1,d3.w),d3
		add.b	d3,d3
		move.w	d2,d0			*RED LOW
		rol.b	#2,d0
		andi.w	#$0003,d0
		move.b	(a1,d0.w),d0
		ror.b	#2,d0
		or.b	d0,d3
		endm

*パレット上位計算
*	d1.w <- tone(0-31)
*	d2.w <- palet hi(0-255)
*	a1.l <- 乗算テーブル
*	d3.b -> toned palet hi

GTONE_CALC_HI	macro
		moveq	#$07,d3			*RED HI
		and.w	d2,d3
		move.b	(a1,d3.w),d3
		move.w	d2,d0			*GREEN
		lsr.w	#3,d0
		move.b	(a1,d0.w),d0
		lsl.b	#3,d0
		or.b	d0,d3
		endm

MAKE_PALTBL::
		link	a5,#-40

		lea	GTONE_BUF(a6),a0		*パレットテーブルの確保
		move.l	a0,GTONE_TBL(a6)

		moveq	#0,d0
		moveq	#512/16-1,d1
make_paltbl10:
		move.l	d0,(a0)+			*輝度１は計算しない
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		dbra	d1,make_paltbl10

		moveq	#2,d1				*輝度２から
make_paltbl20:
		movea.l	sp,a1				*乗算テーブルを作成し
		clr.b	(a1)+
		moveq	#1,d2
		moveq	#31-1,d3
make_paltbl21:
		move.w	d1,d0
		mulu	d2,d0
		lsr.w	#5,d0
		move.b	d0,(a1)+
		addq.w	#1,d2
		dbra	d3,make_paltbl21

		moveq	#0,d2				*各輝度のパレットを計算する
		movea.l	sp,a1
make_paltbl30:
		GTONE_CALC_LOW
		move.b	d3,(a0)+
		ori.b	#1,d3
		move.b	d3,(a0)+
		GTONE_CALC_HI
		move.b	d3,(a0)+
		addq.b	#1,d2
		GTONE_CALC_HI
		move.b	d3,(a0)+
		addq.b	#1,d2
		bne	make_paltbl30
		addq.w	#1,d1				*輝度３２まで繰り返す
		cmpi.w	#32,d1
		bls	make_paltbl20

		unlk	a5
		rts


*==================================================
*起動時のカレントパスを保存する
*==================================================

SAVE_CURPATH:
		move.l	a0,-(sp)
		lea	INIT_PATH(a6),a0
		bsr	GET_CURRENT
		move.l	(sp)+,a0
		rts

*==================================================
*指定のパスへ移動する
*==================================================

MOVE_CURPATH:
		move.l	a0,-(sp)
		lea	CURRENT(a6),a0
		tst.b	(a0)
		beq	move_curpath90
		bsr	SET_CURRENT
move_curpath90:
		move.l	(sp)+,a0
		rts


*==================================================
*起動時のカレントパスを復帰する
*==================================================

RESUME_CURPATH:
		move.l	a0,-(sp)
		lea	INIT_PATH(a6),a0
		bsr	SET_CURRENT
		move.l	(sp)+,a0
		rts


*==================================================
*起動時の画面を保存する
*	d0.l -> -1:画面モードが起動には不適切
*==================================================

SAVE_DISPLAY:
		movem.l	d1-d2/a0-a1,-(sp)

*		moveq	#-1,d0				*SPRITE表示ONの時は起動しない
*		btst.b	#6,VIDEO_EFFECT+1
*		bne	save_display90

		moveq	#-1,d1				*表示位置保存
		moveq	#-1,d2
		IOCS	_B_LOCATE
		move.l	d0,LOCATESAVE(a6)

		moveq	#-1,d1
		moveq	#-1,d2
		IOCS	_B_CONSOL
		movem.l	d1-d2,CONSOLSAVE(a6)

		move.b	$992.w,CURSORSAVE(a6)		*カーソル点滅状態保存
		IOCS	_OS_CUROF			*カーソル点滅禁止

		movea.l	#CRTC_ACM,a0			*テキスト画面保存
		move.w	(a0),-(sp)
		clr.w	(a0)
		movea.l	#TXTADR,a0
		movea.l	#TXTADR2+128*512,a1
		move.l	#128*512,d0
		bsr	HSCOPY
		movea.l	#TXTADR1,a0
		movea.l	#TXTADR3+128*512,a1
		bsr	HSCOPY
		move.w	(sp)+,CRTC_ACM

		move.w	CRTC_MODE,CRTCMODE_SAVE(a6)	*CRTCモード保存
		move.w	CRTC_ACM,CRTCACM_SAVE(a6)
		move.w	VIDEO_MODE,VIDEOMODE_SAVE(a6)	*VCONモード保存
		move.w	VIDEO_PRIO,VIDEOPRIO_SAVE(a6)
		move.w	VIDEO_EFFECT,VIDEOEFF_SAVE(a6)
		move.w	SPRITEREG+$808,BGCTRL_SAVE(a6)	*BGコントロール保存
		bsr	SAVE_GPALET

		move.l	$960.w,IOCSXLEN_SAVE(a6)	*IOCS グラフィックモード保存
		move.w	$964.w,IOCSGMODE_SAVE(a6)
		move.l	$968.w,IOCSWIN_SAVE1(a6)
		move.l	$96c.w,IOCSWIN_SAVE2(a6)

		moveq	#-1,d1				*IOCS APAGE保存
		IOCS	_APAGE
		move.b	d0,APAGE_SAVE(a6)

		moveq	#-1,d1				*IOCS VPAGE保存
		IOCS	_VPAGE
		move.b	d0,VPAGE_SAVE(a6)

		moveq	#0,d0
save_display90:
		movem.l	(sp)+,d1-d2/a0-a1
		rts


*==================================================
*起動前の画面を再現する
*==================================================

RESUME_DISPLAY:
		movem.l	d1-d2/a0-a1,-(sp)

		move.w	CRTCMODE_SAVE(a6),CRTC_MODE	*CRTCモード復旧
		move.w	CRTCACM_SAVE(a6),CRTC_ACM
		move.w	VIDEOMODE_SAVE(a6),VIDEO_MODE	*VCONモード復旧
		move.w	VIDEOPRIO_SAVE(a6),VIDEO_PRIO
		move.w	VIDEOEFF_SAVE(a6),VIDEO_EFFECT
		move.w	BGCTRL_SAVE(a6),SPRITEREG+$808	*BGコントロール復旧

		move.l	IOCSXLEN_SAVE(a6),$960.w	*IOCS グラフィックモード復旧
		move.w	IOCSGMODE_SAVE(a6),$964.w
		move.l	IOCSWIN_SAVE1(a6),$968.w
		move.l	IOCSWIN_SAVE2(a6),$96c.w

		move.b	APAGE_SAVE(a6),d1		*IOCS APAGE復旧
		IOCS	_APAGE

		move.b	VPAGE_SAVE(a6),d1		*IOCS VPAGE復旧
		IOCS	_VPAGE

		bsr	RESUME_GPALET

		movem.l	CONSOLSAVE(a6),d1-d2
		IOCS	_B_CONSOL

		move.l	LOCATESAVE(a6),d2
		move.l	d2,d1
		swap	d1
		IOCS	_B_LOCATE

		IOCS	_OS_CUROF

		movea.l	#CRTC_ACM,a0			*テキスト画面復旧
		move.w	(a0),-(sp)
		clr.w	(a0)
		movea.l	#TXTADR2+128*512,a0
		movea.l	#TXTADR,a1
		move.l	#128*512,d0
		bsr	HSCOPY
		movea.l	#TXTADR3+128*512,a0
		movea.l	#TXTADR1,a1
		bsr	HSCOPY
		move.w	(sp)+,CRTC_ACM

		tst.b	CURSORSAVE(a6)
		beq	resume_display10
		IOCS	_OS_CURON
resume_display10:

		movem.l	(sp)+,d1-d2/a0-a1
		rts


*============================================================
*高速データ転送ルーチン
*	in	d0.l	データのバイト数
*		a0	転送元アドレス(絶対偶数)
*		a1	転送先アドレス(   〃   )
*============================================================

HSCOPY:		movem.l	d0-d7/a0-a3,-(sp)
		move.l	d0,d1
		cmpa.l	a0,a1
		bhi	hscopy_rf		* 転送先が転送元より上位にある場合の転送へ
		beq	hscopy90

hscopy_fr:	andi.w	#$7f,d0			* 余り128バイトの転送準備
		lsr.l	#7,d1			* 128バイト単位の転送準備
		bra	hscopy18

hscopy10:	movem.l	(a0)+,d2-d7/a2-a3	* 32 byte 転送 * 4
		movem.l	d2-d7/a2-a3,(a1)
		movem.l	(a0)+,d2-d7/a2-a3	*
		movem.l	d2-d7/a2-a3,32(a1)
		movem.l	(a0)+,d2-d7/a2-a3	*
		movem.l	d2-d7/a2-a3,64(a1)
		movem.l	(a0)+,d2-d7/a2-a3	*
		movem.l	d2-d7/a2-a3,96(a1)
		lea	128(a1),a1		* ポインタを進める
hscopy18:	subq.l	#1,d1
		bcc	hscopy10
		bra	hscopy28

hscopy20:	move.b	(a0)+,(a1)+		* 余り128バイトをコピーする
hscopy28:	dbra	d0,hscopy20
		bra	hscopy90		* 転送終了

hscopy_rf:	adda.l	d0,a0			* ブロック後方から転送をする
		adda.l	d0,a1
		andi.w	#$7f,d0			* 余り128バイトの転送準備
		lsr.l	#7,d1			* 128バイト単位の転送準備

		bra	hscopy68
hscopy60:	move.b	-(a0),-(a1)		* 余り128バイトをコピーする
hscopy68:	dbra	d0,hscopy60

		bra	hscopy58
hscopy50:	lea	-128(a0),a0		* ポインタを進める
		movem.l	96(a0),d2-d7/a2-a3	* 32 byte 転送 * 4
		movem.l	d2-d7/a2-a3,-(a1)
		movem.l	64(a0),d2-d7/a2-a3
		movem.l	d2-d7/a2-a3,-(a1)
		movem.l	32(a0),d2-d7/a2-a3
		movem.l	d2-d7/a2-a3,-(a1)
		movem.l	(a0),d2-d7/a2-a3
		movem.l	d2-d7/a2-a3,-(a1)
hscopy58:	subq.l	#1,d1
		bcc	hscopy50

hscopy90:	movem.l	(sp)+,d0-d7/a0-a3
		rts


*============================================================
*高速クリアルーチン
* in	d0.l	クリアするサイズ
*	a0.l	クリアするアドレス
*============================================================

HSCLR:		movem.l	d0-d7/a0-a2,-(sp)

		moveq.l	#0,d2
		move.l	d2,d3
		move.l	d2,d4
		move.l	d2,d5
		move.l	d2,d6
		move.l	d2,d7
		movea.l	d2,a1
		movea.l	d2,a2

		adda.l	d0,a0			* 後ろから消去
		moveq.l	#$7f,d1			* 取りあえず端数をクリア
		and.w	d0,d1

		lsr.w	#1,d1			* 奇数サイズも考慮
		bcc	hsclr15
		move.b	d2,-(a0)
		bra	hsclr15

hsclr10:	move.w	d2,-(a0)
hsclr15:	dbra	d1,hsclr10

		lsr.l	#7,d0
		bra	hsclr25

hsclr20:	movem.l	d2-d7/a1-a2,-(a0)	* 128バイトクリア
		movem.l	d2-d7/a1-a2,-(a0)
		movem.l	d2-d7/a1-a2,-(a0)
		movem.l	d2-d7/a1-a2,-(a0)
hsclr25:	dbra	d0,hsclr20
		addq.w	#1,d0
		subq.l	#1,d0
		bcc	hsclr20

		movem.l	(sp)+,d0-d7/a0-a2
		rts


*==================================================
*メッセージ
*==================================================

SYSTEM_TITLE:	.dc.b	'X68k multi music status display MMDSP.r v'
		VERSION
		.dc.b	' (c)1991-94 Miahmie, Gao',13,10,0

MES_USAGE:	.dc.b  '【使用法】mmdsp [オプション] [ディレクトリ/演奏ファイル名]',13,10
		.dc.b  '	-<name>		ドライバ指定(-mxdrv -madrv -mld -rcd -zmusic -mcdrv)',13,10
		.dc.b  '	-g[n]		グラフィック表示モード(n:0-3)',13,10
		.dc.b  '	-a[bbbb]	AUTOモード		REP. INTRO ALLDIR PROG.のon/offは',13,10
		.dc.b  '	-s[bbbb]	SHUFFLEモード		[bbbb]に 1/0 で指定(例:-a1010)',13,10
		.dc.b  '	-n		セレクタを使用しない',13,10
		.dc.b  '	-f		テキスト強制使用モード',13,10
		.dc.b  '	-k[key1,key2]	常駐    key1,key2は起動キーのコード(def: XF4+XF5)',13,10
		.dc.b  '	-r		常駐解除',13,10
		.dc.b	13,10,0

MES_NOMEM:	.dc.b	'メモリが足りません.',13,10,0
MES_HUVER:	.dc.b	'Human v2.00以上で起動して下さい.',13,10,0
MES_MODE:	.dc.b	'モードで起動します.',13,10,0

DRIVER_NONE:	.dc.b  'ドライバが組み込まれていないか、対応していないバージョンです.',13,10
		.dc.b	13,10
		.dc.b  '【対応ドライバおよびバージョン一覧】',13,10
		.dc.b  '	MXDRV	v2.06+16 以上',13,10
		.dc.b  '	MADRV	v1.09o 以上',13,10
		.dc.b  '	RCD	v2.92 (v3.00以降不完全）',13,10
		.dc.b  '	MLD	v2.36 以上',13,10
		.dc.b  '	ZMUSIC	v1.43 以上',13,10
		.dc.b  '	MCDRV	v0.19 以上',13,10,0

DRIVER_NONE2:	.dc.b	'指定されたドライバは組み込まれていないか、対応していないバージョンです.',13,10,0

TEXT_AUSE:	.dc.b	'TEXT-VRAMがアプリケーションにより使用されています.',13,10
		.dc.b	'強制使用する時は、-f オプションを指定してください.',13,10,0

VECTOR_AUSE:	.dc.b	'TimerA/Raster/Vdisp/TimerD 割り込みが全て使用されています.',13,10,0

		.even
		.end

