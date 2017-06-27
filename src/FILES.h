*************************************************************************
*									*
*									*
*	    Ｘ６８０００　ＭＸＤＲＶ／ＭＡＤＲＶディスプレイ		*
*									*
*				ＭＭＤＳＰ				*
*									*
*									*
*	Copyright (C) 1994 Masao Takahashi				*
*									*
*									*
*************************************************************************

MAXFILE		equ	(512-16)*4			*論理最大32767まで

SEL_FNAME	equ	$E10000+$80*16			*ファイルネームバッファアドレス
SEL_BUFFER1	equ	$E30000+$80*16			*タイトルバッファアドレス1
SEL_BUFFER2	equ	$E50000+$80*12			*タイトルバッファアドレス2
SEL_BUFFER3	equ	$E70000+$80*12			*タイトルバッファアドレス3


		.offset	0
HEAD_MARK:	.ds.b	1		*ディレクトリヘッダの構造(32bytes)
KENS_FLAG:	.ds.b	1
FILE_NUM:	.ds.w	1
PATH_ADR:	.ds.l	1		*ここが0ならダミーのヘッダ
NEXT_DIR:	.ds.l	1
PAST_POS:	.ds.w	1
TOP_POS:	.ds.w	1
		.text

		.offset	0
DATA_KIND:	.ds.b	1			*ファイルネームバッファの構造(32bytes)
SHUFFLE_FLAG:	.ds.b	1
PROG_FLAG:	.ds.b	1
DOC_FLAG:	.ds.b	1
TITLE_ADR:	.ds.l	1
FILE_NAME:	.ds.b	24
		.text

MMDATVER	equ	'0.01'			*タイトルデータファイルフォーマット

