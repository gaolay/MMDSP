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
*	Modified 1992-1994 Masao Takahashi				*
*									*
*************************************************************************


		.include	iocscall.mac
		.include	doscall.mac
		.include	MMDSP.H

*DISPTEST	.equ	0			*表示速度テスト用

			.text
			.even

START:
		bra.s	NORM_START

MM_HEADER:	.dc.b	'MMDSP000'		*識別ヘッダ(8bytes)
MM_STAYFLAG:	.dc.l	0			*常駐フラグ($31415926なら常駐)


*==================================================
*ＭＭＤＳＰスタートアップ
*==================================================

NORM_START:
		bsr	SYSTEM_INIT		*システム、ワークエリアの初期化
		bmi	ERROR_EXIT
		bsr	CHECK_OPTION		*オプション解析
		bmi	ERROR_EXIT

		suba.l	a1,a1			*スーパーバイザモードにする
		IOCS	_B_SUPER
		move.l	d0,SUPER(a6)
		movea.l	a6,a0			*スーパーバイザスタックの設定
		adda.l	#MYSTACK,a0		*子プロセス呼び出し時に問題が起きるので、
		movea.l	a0,sp			*ユーザーバイザスタックは起動時のまま

.ifdef	DISPTEST
		bra	disptest
.endif
		tst.b	RESIDENT(a6)		*常駐指定または
		bne	RESID_START
		tst.b	REMOVE(a6)		*解除指定の場合それぞれのスタートアップへ
		bne	REMOVE_START

		bsr	SYSTEM_CHCK		*起動可能チェック
		bsr	PRINT_ERROR
		bmi	ERROR_EXIT
		bsr	TABLE_MAKE		*各種テーブル作成
		bsr	BIND_DEFAULT		*キーバインド

		movea.l	sp,a5			*アボートアドレス設定
		lea	MYSTACK2(a6),sp
		pea	ABORT_NORM(pc)
		move.w	#_ERRJVC,-(sp)
		DOS	_INTVCS
		pea	ABORT_NORM(pc)
		move.w	#_CTRLVC,-(sp)
		DOS	_INTVCS
		movea.l	a5,sp

		bsr	KILL_BREAK		*ブレーク禁止
		bsr	SAVE_CURPATH		*カレントディレクトリを保存して、
		bsr	MOVE_CURPATH		*指定のディレクトリに移動する

		bsr	DISPLAY_MAIN		*MMDSPメイン

		bsr	RESUME_CURPATH		*カレントディレクトリを戻す
		bsr	UNLOCK_DRIVE		*ロックドライブを解除する
		bsr	RESUME_BREAK		*ブレーク禁止解除

*		move.l	SUPER(a6),a1
*		IOCS	_B_SUPER

		DOS	_EXIT

ERROR_EXIT:
		move.l	d0,d1

*		move.l	SUPER(a6),a1
*		IOCS	_B_SUPER

		move.w	d1,-(sp)
		DOS	_EXIT2

ABORT_NORM:
		lea	START(pc),a6
		adda.l	#BUFFER-START,a6
		tst.b	CHILD_FLAG(a6)
		bne	abort_child
		bsr	VECTOR_DONE			*割り込み解除
		bsr	DISP_DONE			*画面を戻す
		move.w	BREAKCK_SAVE(a6),-(sp)		*break 戻す
		DOS	_BREAKCK
		addq.l	#2,sp
		clr.b	MMDSPON_FLAG(a6)
abort_child:
		move.w	#-1,-(sp)
		DOS	_EXIT2


*==================================================
*常駐スタートアップ
*==================================================

RESID_START:
		bsr	RESID_CHECK			*MMDSPが既に常駐していたら、
		bmi	resid_start10
		pea	mes_keeperr(pc)			*その旨表示して終わる
		DOS	_PRINT
		addq.l	#4,sp
		moveq	#1,d0
		bra	ERROR_EXIT
resid_start10:
		pea	mes_keep(pc)
		DOS	_PRINT
		addq.l	#4,sp

		bsr	TABLE_MAKE			*各種テーブル作成
		bsr	BIND_DEFAULT			*キーバインド

		lea	MM_STAYFLAG(pc),a0
		move.l	#STAYID,(a0)

		move.w	#_B_KEYSNS+$100,d1		*IOCS _B_KEYSNSのフック
		lea	KEYSNSHOOK(pc),a1
		IOCS	_B_INTVCS
		lea	ORIG_KEYSNS(pc),a0
		move.l	d0,(a0)

		movea.l	MM_MEMPTR(a6),a0		*常駐終了
		move.l	$08(a0),d0
		lea	START(pc),a0
		sub.l	a0,d0
		clr.w	-(sp)
		move.l	d0,-(sp)
		DOS	_KEEPPR


*==================================================
*常駐解除スタートアップ
*==================================================

REMOVE_START:
		bsr	RESID_CHECK			*MMDSP常駐チェック
		bpl	remove_start10
		pea	mes_removeerr(pc)
		DOS	_PRINT
		addq.l	#4,sp
		moveq	#1,d1
		bra	ERROR_EXIT
remove_start10:
		movea.l	d0,a0
		clr.l	MM_STAYFLAG-START+$100(a0)	*常駐ＩＤのクリア
		pea	$10(a0)

		movea.l	ORIG_KEYSNS-START+$100(a0),a1
		move.w	#_B_KEYSNS+$100,d1		*IOCS _B_KEYSNSを戻す
		IOCS	_B_INTVCS

		DOS	_MFREE				*メモリの開放
		addq.l	#4,sp

		pea	mes_remove(pc)
		DOS	_PRINT
		addq.l	#4,sp

		DOS	_EXIT


*==================================================
*常駐部メイン
*==================================================

INDOSFLAG	.equ	$1c08		*Humanのワーク
INDOSNUM	.equ	$1c0a		*Humanのワーク
INDOSSP		.equ	$1c5c		*Humanのワーク

ORIG_KEYSNS:	.dc.l	0	*変更前のベクタアドレス(_B_KEYSNS)
		.even

KEYSNSHOOK:
		move.l	a6,-(sp)
		lea	START(pc),a6
		adda.l	#BUFFER-START,a6
		tst.b	MMDSPON_FLAG(a6)
		bne	keysnshook90

		movea.w	HOTKEY1ADR(a6),a0		*起動キーが押されていて
		move.b	(a0),d0
		cmp.b	HOTKEY1MASK(a6),d0
		bne	keysnshook80
		movea.w	HOTKEY2ADR(a6),a0
		move.b	(a0),d0
		cmp.b	HOTKEY2MASK(a6),d0
		bne	keysnshook80
		tst.b	HOTKEY_FLAG(a6)
		bne	keysnshook90

		move.w	sr,d0				*割り込み中でないなら
		andi.w	#$0700,d0
		bne	keysnshook90
		st.b	HOTKEY_FLAG(a6)
		bsr	DISP_ON				*起動
		bra	keysnshook90
keysnshook80:
		clr.b	HOTKEY_FLAG(a6)
keysnshook90:
		move.l	(sp)+,a6
		move.l	ORIG_KEYSNS(pc),-(sp)		*元のIOCS_KEYSNSへ
		rts


*==================================================
*常駐 MMDSP 起動
*==================================================

DISP_ON:
		movem.l	d0-d7/a0-a6,-(sp)
		move.l	sp,SPSAVE_RESI(a6)
		movea.l	a6,a0
		adda.l	#MYSTACK,a0
		movea.l	a0,sp

		bsr	SYSTEM_CHCK			*ドライバチェック
		bpl	DISP_ON00
		btst.l	#0,d0
		beq	DISP_ON90
		clr.w	DRV_MODE(a6)
		bsr	SYSTEM_CHCK
		bmi	DISP_ON90
DISP_ON00:
		move.l	INDOSSP.w,INDOSSP_SAVE(a6)	*妖しい処理（笑）
		move.w	INDOSFLAG.w,INDOSFLAG_SAVE(a6)
		clr.w	INDOSFLAG.w
		move.b	INDOSNUM.w,INDOSNUM_SAVE(a6)

*行儀のいい場合（笑）でもこうすると穴がある(さらにINDOSSPも保存できない)
*		DOS	_INDOSFLG
*		movea.l	d0,a0
*		move.w	(a0),INDOSFLAG_SAVE(a6)
*		clr.w	(a0)
*		move.b	2(a0),INDOSNUM_SAVE(a6)

		DOS	_GETPDB				*環境変数を現プロセスにあわせて
		movea.l	d0,a0
		move.l	(a0),d0
		movea.l	MM_MEMPTR(a6),a0
		lea	$10(a0),a0
		move.l	d0,(a0)
		move.l	a0,-(sp)			*自分を現プロセスにする
		DOS	_SETPDB
		addq.l	#4,sp
		move.l	d0,PDB_SAVE(a6)

		bsr	KILL_BREAK			*ブレーク禁止

		movea.l	sp,a5				*アボートアドレス設定
		lea	MYSTACK2(a6),sp
		pea	ABORT_RESI(pc)
		move.w	#_ERRJVC,-(sp)
		DOS	_INTVCS
		pea	ABORT_RESI(pc)
		move.w	#_CTRLVC,-(sp)
		DOS	_INTVCS
		movea.l	a5,sp

		bsr	SAVE_DISPLAY			*画面状態を保存
		bmi	DISP_ON20
		bsr	SAVE_CURPATH			*カレントディレクトリを保存
		bsr	MOVE_CURPATH			*指定のディレクトリに移動する

		clr.w	QUIT_FLAG(a6)
		bsr	DISPLAY_MAIN

DISP_ON10:
		bsr	RESUME_CURPATH			*カレントディレクトリを戻す
		bsr	UNLOCK_DRIVE			*ロックドライブ解除
		bsr	RESUME_DISPLAY			*画面状態を戻す
DISP_ON20:
		bsr	RESUME_BREAK			*ブレーク禁止解除

		move.l	PDB_SAVE(a6),-(sp)
		DOS	_SETPDB
		addq.l	#4,sp

		move.l	INDOSSP_SAVE(a6),INDOSSP.w	*妖しい処理その２（笑）
		move.w	INDOSFLAG_SAVE(a6),INDOSFLAG.w
		move.b	INDOSNUM_SAVE(a6),INDOSNUM.w
*行儀のいい場合だと
*		DOS	_INDOSFLG
*		movea.l	d0,a0
*		move.w	INDOSFLG_SAVE(a6),(a0)
*		move.b	INDOSNUM_SAVE(a6),2(a0)

DISP_ON90:
		move.l	SPSAVE_RESI(a6),sp
		movem.l	(sp)+,d0-d7/a0-a6
		rts

ABORT_RESI:
		lea	START(pc),a6
		adda.l	#BUFFER-START,a6
		tst.b	CHILD_FLAG(a6)
		bne	abort_child
		bsr	VECTOR_DONE			*割り込み解除
		bsr	DISP_DONE			*画面を戻す
		clr.b	MMDSPON_FLAG(a6)
		bra	DISP_ON10

.ifdef DISPTEST
*==================================================
*文字表示速度計測 (デバッグ用)
*==================================================

*４＊８ドット
*     han   / zen
*0.22  15.76 / 26.58
*0.25  10.03 / 15.66	Rate 57%up / 70%up
*0.28   7.55 / 13.18	     33%up / 19%up
*0.29   5.99 / 11.98	     26%up / 10%up

*６＊１６ドット
*     han   / zen
*0.22  14.58 / 23.47
*0.25  12.97 / 22.78	Rate 12%up / 3%up
*0.28  10.63   20.45	     22%up / 11%up
*0.29   9.14   18.66	     16%up / 10%up

disptest:
		bsr	TABLE_MAKE

		moveq	#3,d0
		moveq	#0,d1
		lea	mes(pc),a0
		movea.l	#TXTADR,a1
		move.w	#5000-1,d7
loop:
*		bsr	TEXT_6_16
		bsr	TEXT_4_8
		dbra	d7,loop

		move.l	SUPER(a6),a1
		IOCS	_B_SUPER

		DOS	_EXIT
*mes		dc.b	'0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',0
mes		dc.b	'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほま',0
		.even
.endif


mes_keeperr:	.dc.b	'既に常駐しています.',13,10,0
mes_keep:	.dc.b	'常駐しました.',13,10,0
mes_removeerr:	.dc.b	'MMDSPは常駐していません.',13,10,0
mes_remove:	.dc.b	'常駐解除しました.',13,10,0
		.even

			.bss
			.even

BUFFER:		.ds.b	BUF_SIZE

		.end	START

