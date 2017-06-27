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

		.include LzzConst.mac

*ドライバ種類

MXDRV		equ	1
MADRV		equ	2
MLD		equ	3
RCD		equ	4
RCD3		equ	5
ZMUSIC		equ	6
MCDRV		equ	7

*ドライバ番号変更時には DRIVER.s の 外部参照および driver_table も書き換えること
*また _SYSDISP.s のロゴも書き換えること

*拡張子種類

_none		equ	0
_MDX		equ	1
_MDR		equ	2
_RCP		equ	3
_R36		equ	4
_MDF		equ	5
_MCP		equ	6
_MDI		equ	7
_SNG		equ	8
_MID		equ	9
_STD		equ	10
_MFF		equ	11
_SMF		equ	12
_SEQ		equ	13
_MDZ		equ	14
_MDN		equ	15
_KMD		equ	16
_ZMS		equ	17
_ZMD		equ	18
_OPM		equ	19
_ZDF		equ	20
_MM2		equ	21
_MMC		equ	22
_MDC		equ	23
_PIC		equ	24
_MAG		equ	25
_PI		equ	26
_JPG		equ	27
_EXTMAX		equ	28

*識別番号変更時にはFILES.sのtitle_jmpテーブルも書き換えること
*

*ドライバコールマクロ
*	a0.l 破壊

DRIVER		macro	call
		movea.l	DRIVER_JMPTBL+call*4(a6),a0
		jsr	(a0)
		endm

*ドライバコール名

		.offset	0
DRIVER_CHECK:	.ds.b	1		* 常駐チェック d0.l->常駐フラグ
DRIVER_NAME:	.ds.b	1		* ドライバ名取得 d0.l->ドライバ名
DRIVER_SETUP:	.ds.b	1		* ドライバ初期化
DRIVER_SYSSTAT:	.ds.b	1		* ドライバ状態取得
DRIVER_TRKSTAT:	.ds.b	1		* トラック情報取得
DRIVER_GETMASK:	.ds.b	1		* 演奏トラック取得
DRIVER_SETMASK:	.ds.b	1		* 演奏トラック設定
DRIVER_FILEEXT:	.ds.b	1		* 拡張子テーブル取得 d0.l->テーブル
DRIVER_FLOADP:	.ds.b	1		* データロード＆演奏 a1.l<-ファイル名 d0.b<-種類 d0.l->エラーコード
DRIVER_PLAY:	.ds.b	1		* 再演奏
DRIVER_PAUSE:	.ds.b	1		* 演奏中断
DRIVER_CONT:	.ds.b	1		* 演奏再開
DRIVER_STOP:	.ds.b	1		* 演奏停止
DRIVER_FADEOUT:	.ds.b	1		* フェードアウト
DRIVER_SKIP:	.ds.b	1		* 早送り d0.w<-開始フラグ
DRIVER_SLOW:	.ds.b	1		* スロー d0.w<-開始フラグ
DRIVER_CMDS:
		.text

*DRIVER_CHECK以外は、必ず常駐確認後に呼び出すこと
*各コールはd0/a0を破壊しても良い
*コールを増やした場合は、mmdsp.h内 DRIVER_JMPTBL の数も合わせること

