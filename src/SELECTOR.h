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

*セレクタコマンド SEL_CMD 一覧
*引数	SEL_ARG

		.offset	0
SEL_NONE	.ds.b	1
SEL_ROLLDOWN	.ds.b	1	*１行ロールダウン
SEL_ROLLUP	.ds.b	1	*１行ロールアップ
SEL_UP		.ds.b	1	*１つ上へ
SEL_DOWN	.ds.b	1	*１つ下へ
SEL_SELN	.ds.b	1	*指定位置のファイルを実行
SEL_SEL		.ds.b	1	*カーソル位置のファイルを実行
SEL_NEXTDRV	.ds.b	1	*ドライブ左移動
SEL_PREVDRV	.ds.b	1	*ドライブ右移動
SEL_PARENT	.ds.b	1	*親ディレクトリに移動
SEL_ROOT	.ds.b	1	*ルートディレクトリに移動
SEL_NEXTPAGE	.ds.b	1	*次のページへ
SEL_PREVPAGE	.ds.b	1	*前のページへ
SEL_CLEAR	.ds.b	1	*バッファクリア
SEL_TOP		.ds.b	1	*先頭行へ
SEL_BOTOM	.ds.b	1	*最終行へ
SEL_PLAYDOWN:	.ds.b	1	*演奏してから次の行に移動
SEL_PLAYUP	.ds.b	1	*前の行へ移動して演奏
SEL_EJECT	.ds.b	1	*イジェクト
SEL_DATAWRITE	.ds.b	1	*データファイル書き出し
SEL_DOCREAD	.ds.b	1	*ドキュメントモード
SEL_DOCREADN	.ds.b	1	*ドキュメントモード(行指定)
SEL_CMDNUM	.ds.b	1	*コマンド数
		.text



