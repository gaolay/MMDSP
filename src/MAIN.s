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
		.include	MMDSP.h
		.include	DRIVER.h


			.text
			.even

*==================================================
*	＊ＤＩＳＰＬＡＹ＿ＭＡＩＮ
*機能：読んで時の通り（笑）
*入出力：なし
*参考：
*==================================================

DISPLAY_MAIN:
		movem.l	d0-d1/a1,-(sp)
		move.l	sp,SPSAVE_MAIN(a6)
		st.b	MMDSPON_FLAG(a6)

		bsr	set_myontime		*自前ONTIMEセットアップ(きたない)

		bsr	DISP_INIT			*画面モード初期化
		bsr	DRIVER_INIT			*ドライバ初期化
		bsr	DISPLAY_MAKE			*画面描画
		lea.l	VDISP_MAIN(pc),a0		*割り込みルーチン設定
		bsr	VECTOR_INIT
		bsr	STATUS_INIT

		lea	CURRENT(a6),a0			*指定ファイルの演奏
		bsr	PLAY_FILE

display_mn_lp:
		bsr	CONTROL				*全体のコントロール
		bsr	SYSTEM_DISP			*システム情報表示
		DRIVER	DRIVER_TRKSTAT			*ドライバステータス取得
		bsr	KEYBORD_DISP			*鍵盤表示
		bsr	LEVELM_DISP			*レベルメータ表示
		bsr	SPEANA_DISP			*スペアナ表示
		bsr	SELECTOR_MAIN			*セレクタ
		tst.w	QUIT_FLAG(a6)
		beq	display_mn_lp			*終了指示があるまでループ

display_mn_dne:
		bsr	VECTOR_DONE			*割り込み解除
		bsr	DISP_DONE			*画面を戻す

		move.w	#$FF,-(sp)			*キーバッファクリア
		move.w	#$06,-(sp)
		DOS	_KFLUSH
		addq.l	#4,sp

		clr.b	MMDSPON_FLAG(a6)
		move.l	SPSAVE_MAIN(a6),sp
		movem.l	(sp)+,d0-d1/a1
		rts


*==================================================
*	＊ＶＤＩＳＰ＿ＭＡＩＮ
*機能：垂直同期割り込みメイン
*==================================================

VDISP_MAIN:
		movem.l	d0-d7/a0-a6,-(sp)
		lea	BUFFER(pc),a6
		tst.w	VDISP_CNT(a6)
		bne	vdisp_main90
		move.w	#1,VDISP_CNT(a6)

		move.w	15*4(sp),d7			*割り込みレベルを下げ
		ori.w	#$2000,d7
		move.w	d7,sr

		movea.l	#CRTC_ACM,a0			*テキストマスクをＯＦＦ
		move.b	(a0),-(sp)
		clr.b	(a0)

vdisp_main10:
		bsr	MOUSE_MOVE
		bsr	LEVELM_GENS			*レベルメータ減衰
		bsr	SPEANA_GENS			*スペアナ減衰
*		bsr	PALET_ANIM			*パレットアニメ

		movea.l	#CRTC_ACM,a0			*テキストマスクを戻す
		move.b	(sp)+,(a0)

		clr.w	VDISP_CNT(a6)

vdisp_main90
		movem.l	(sp)+,d0-d7/a0-a6
		rte

		.end
