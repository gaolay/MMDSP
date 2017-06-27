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
*									*
*************************************************************************

		.include	iocscall.mac
		.include	doscall.mac
		.include	MMDSP.H


	.offset	0
DV_FONTSZ:	.ds.w	1
DV_OUTPUT:	.ds.w	1


			.text
			.even


*
*	＊ＤＯＣＶＩＥＷ＿ＩＮＩＴ
*入力：	Ｄ０	幅文字数（上位.w：横方向,下位.w：縦方向）
*	Ｄ１	表示開始位置（上位.w：Ｘ座標８ドット単位,下位.w：Ｙ４ドット単位）
*	Ｄ２.w	フォント指定
*	Ａ０	読み込みファイルネーム
*出力：	Ｄ０	負の場合はエラー
*
*参考：	FILE_BUFF(A6)を使う。
*

DOCVIEW_INIT:
		movem.l	d1-d2/d6-d7/a0,-(sp)

		bsr	docv_inipara		*引数待避＆計算

		clr.l	DOCV_MEMPTR(a6)		*MEM確保したかをチェックするため

		clr.w	-(sp)			*指定のファイルをオープン
		move.l	a0,-(sp)
		DOS	_OPEN
		addq.l	#6,sp

		move.l	d0,d7			*おーぷんできないぉ～
		bmi	docvinit_err

		bsr	docv_malloc		*メモリ確保
		tst.l	d0
		bmi	docvinit_err

		move.l	d0,DOCV_MEMPTR(a6)
		move.l	d0,a0
		addq.l	#1,d0			*最初の$00の次のアドレスを書く
		move.l	d0,DOCV_NOW(a6)
		move.l	d1,d6

		bsr	docv_fileread		*ファイル読み込み
		tst.l	d0
		bmi	docvinit_err
		move.l	a0,DOCV_MEMEND(a6)	*最後の$00の次のアドレスを書く

		move.l	d0,-(sp)		*メモリブロック変更
		move.l	DOCV_MEMPTR(a6),-(sp)
		DOS	_SETBLOCK
		addq.l	#8,sp
		tst.l	d0			*エラーは出ない筈だけど念のため
		bmi	docvinit_err

		move.w	d7,-(sp)		*ふぁいるくろーず～
		DOS	_CLOSE
		addq.l	#2,sp

		move.w	DOCV_TATE(a6),d0	*あどれすせっとー
docv_inisigend:
		bsr	DOCV_PTR_BACK
		dbra	d0,docv_inisigend
		move.l	a0,DOCV_SIGEND(a6)

		move.l	#TXTADR+512*$80,a0	*TEXT(0,512)-(512,527)をクリア
		moveq.l	#3,d0			*（これについては末メモ参照）
		bsr	TEXT_ACCESS_ON
		moveq.l	#64,d0
		bsr	TXLINE_CLEAR
		bsr	TEXT_ACCESS_OF


		moveq.l	#0,d0			*正常終了
		movem.l	(sp)+,d1-d2/d6-d7/a0
		rts

docvinit_err:
		move.l	DOCV_MEMPTR(a6),d0	*エラー発生したとき
		beq	docvinit_errj0		*メモリ確保してたなら開放する

		move.l	d0,-(sp)
		DOS	_MFREE
		addq.l	#4,sp
docvinit_errj0:
		tst.l	d7			*ファイルオープンしてたら閉じる
		bpl	docvinit_errj1

		move.w	d7,-(sp)
		DOS	_CLOSE
		addq.l	#2,sp
docvinit_errj1:
		moveq.l	#-1,d0			*エラー終了
		movem.l	(sp)+,d1-d2/d6-d7/a0
		rts

docv_inipara:
		movem.l	d0-d2/a1,-(sp)		*引数待避＆計算

		move.l	d0,DOCV_YOKO(a6)	*YOKO,TATE両方書くのに注意(.L size)

		lea.l	DOCV_FTABLE(pc),a1	*フォント別テーブルアドレス設定
		lsl.w	#2,d2			*FTABLEの１サイズは４バイト
		lea.l	0(a1,d2.w),a1
		move.l	a1,DOCV_FONT(a6)

		move.w	DV_FONTSZ(a1),d0	*ラスタ位置計算
		mulu.w	DOCV_TATE(a6),d0
		add.w	d1,d0
		move.b	d1,DOCV_RAS1(a6)
		move.b	d0,DOCV_RAS2(a6)

		move.l	#TXTADR,d0		*テキストアドレス計算
		swap.w	d1
		add.w	d1,d0
		clr.w	d1
		swap.w	d1
		lsl.l	#7,d1
		lsl.l	#2,d1
		add.l	d1,d0
		move.l	d0,DOCV_TXTADR(a6)

		move.w	DV_FONTSZ(a1),d1	*テキストアドレスその２
		lsl.w	#2,d1
		move.w	DOCV_TATE(a6),d0
		mulu.w	d1,d0
		sub.w	d1,d0
		ext.l	d0
		lsl.l	#7,d0
		move.l	DOCV_TXTADR(a6),d1
		add.l	d0,d1
		move.l	d1,DOCV_TXTAD2(a6)

		movem.l	(sp)+,d0-d2/a1
		rts

docv_malloc:
		move.l	#$100000,-(sp)		*とりあえず１メガ確保
		DOS	_MALLOC			*いくら何でも１メガ以上のDOCを
		addq.l	#4,sp			*MMDSP上で見る人はいないでしょう^^;

		tst.l	d0
		bmi	docv_malloc_j0

		move.l	#$100000,d1		*１メガ確保出来たリッチな人は
		bra	docv_malloc_j1		*そのまま終了
docv_malloc_j0:
		sub.l	#$81000000,d0		*そうでない貧乏な人は
		move.l	d0,d1			*確保できる最大バイトを確保する
		move.l	d0,-(sp)
		DOS	_MALLOC
		addq.l	#4,sp			*ここで確保出来なくてもd0に負がはいる
docv_malloc_j1:
		rts


*d0 -> 実際に使ったメモリ（負の場合はエラー）
*d6 <- 確保したメモリの大きさ
*d7 <- ファイルハンドル
*a0 <- メモリへのポインタ
*   -> 処理後アドレス（a0+d0）

docv_fileread:
		movem.l	d1-d2/d4-d5/a1,-(sp)

		moveq.l	#0,d5			*実際使ったバイトカウンタ～
		moveq.l	#0,d2			*FILE_BUFFにあるバイト数
		move.w	DOCV_YOKO(a6),d4	*横幅残りバイト
		subq.w	#1,d4

		bsr	docv_chr_crlf		*最初に改行(stop check用)
		bmi	docv_fread_err		*まさか最初でMEM不足なんてないよね？^^;
docv_fread_lp:
		bsr	docv_fgetc
		tst.l	d0
		bpl	docv_fread_mn
docv_fread_dne:
		bsr	docv_chr_crlf		*最後は念のため改行をする
						*byte checkしなくてもすむ（と思う^^;）
		move.l	d5,d0
		movem.l	(sp)+,d1-d2/d4-d5/a1
		rts

docv_fread_err:
		moveq.l	#-1,d0
		movem.l	(sp)+,d1/d4-d5/a1
		rts

						*ここのソースはみにくいなぁ～（笑）
						*別プログラムの使い回し・・・(^^;)
docv_fread_mn:
		tst.b	d0
		beq	docv_fread_lp		*$00コードは無視する（手抜き）
		bpl	docv_chr1b		*$01～$7Fは１バイト文字（英数&CTRL）
		cmp.b	#$a0,d0
		bcs	docv_chr2b		*$80～$9Fは２バイト文字
		cmp.b	#$e0,d0			*$A0～$DFは１バイト文字（カナ）
		bcc	docv_chr2b		*$E0～$FFは２バイト文字

docv_chr1b:					*１バイト文字の時
		cmp.b	#9,d0			*タブはスペースに展開
		beq	docv_ctrl_tab
		cmp.b	#10,d0			*ＬＦコードは無視(^^;
		beq	docv_fread_lp
		cmp.b	#13,d0			*ＣＲコードは改行に(^^;
		beq	docv_ctrl_crlf

		subq.w	#1,d4
		bra	docv_chr1b_out		*書き込みへ


docv_chr2b:					*２バイト文字の時
		cmp.b	#$80,d0			* ～$80FF は半角
		beq	docv_chr2b_han
		cmp.b	#$f0,d0			* $F000～ も半角
		bcc	docv_chr2b_han

		tst.w	d4			*全角文字の時で
		bne	docv_chr2b_zen		*１行の残り文字が半角分しかなかったら
		move.w	d0,d1
		bsr	docv_chr_crlf		*改行をする
		bmi	docv_fread_err
		move.w	d1,d0
docv_chr2b_zen:
		subq.w	#2,d4
		bra	docv_chr2b_out
docv_chr2b_han:
		subq.w	#1,d4
docv_chr2b_out:
		bsr	docv_memputc		*２バイト文字の１バイト目書き込み
		tst.l	d0
		bmi	docv_fread_err

		bsr	docv_fgetc		*２バイト文字の２バイト目を取ってくる
		tst.l	d0
		bmi	docv_fread_dne

docv_chr1b_out:
		bsr	docv_memputc		*書き込み
		tst.l	d0
		bmi	docv_fread_err

		tst.w	d4
		bpl	docv_fread_lp
docv_ctrl_crlf:
		bsr	docv_chr_crlf		*もし、行の終わりにきたら
		bmi	docv_fread_err		*改行する
		bra	docv_fread_lp

docv_ctrl_tab:
		move.w	DOCV_YOKO(a6),d1	*タブをスペースに展開して出力
		subq.w	#1,d1
		sub.w	d4,d1

		and.w	#7,d1		*ここらへんを手直し（手抜きだけど（笑）
		eori.w	#7,d1

		cmp.w	#7,d4
		bcs	docv_ctrl_crlf
docv_ctrl_tab1:
		moveq.l	#32,d0
		bsr	docv_memputc
		tst.l	d0
		bmi	docv_fread_err
		subq.w	#1,d4

		dbra	d1,docv_ctrl_tab1
		bra	docv_fread_lp

docv_chr_crlf:					*改行コード出力
		move.w	DOCV_YOKO(a6),d4	*横幅残りバイト再設定
		subq.w	#1,d4

		moveq.l	#0,d0			*内部改行コードは＄００
		bsr	docv_memputc
		tst.l	d0
		rts

*docv_fgetc
*ファイルから１バイト取り出す
*１０２４単位でディスクから読み出してくる
*FILE_BUFF(a6)をバッファに使う
*●似たようなルーチンってどっかになかったっけ？（笑）
*（ＺＭＵＳＩＣのタイトル検索辺りに・・・^^;;）

docv_fgetc:
		tst.w	d2
		bne	docv_fgetc_jp0

		lea.l	FILE_BUFF(a6),a1
		move.l	#1024,-(sp)
		move.l	a1,-(sp)
		move.w	d7,-(sp)
		DOS	_READ
		lea.l	10(sp),sp

		move.w	d0,d2			*実際に読み込んだバイト数
		beq	docv_fgetc_err		*もし１バイトも読んでなかったら
						*ファイルの終わりと見なす
docv_fgetc_jp0:
		moveq.l	#0,d0
		move.b	(a1)+,d0
		subq.w	#1,d2
		rts
docv_fgetc_err:
		moveq.l	#-1,d0
		rts


*docv_memputc
*メモリへ１バイト書き出す
*最大バイトチェックをする
*

docv_memputc:
		move.b	d0,(a0)+
		addq.l	#1,d5
		cmp.l	d6,d5
		bge	docv_memputer
		moveq.l	#0,d0
		rts
docv_memputer:
		moveq.l	#-1,d0
		rts

*DOCV_PTR_NEXT
*a0 -> 移動後位置（$00の次のアドレス）
*CCR -> 負:ERR
DOCV_PTR_NEXT:
		tst.b	(a0)+
		bne	DOCV_PTR_NEXT

		cmp.l	DOCV_MEMEND(a6),a0
		beq	docv_ptr_nxerr

		andi.b	#%11110111,CCR
		rts
docv_ptr_nxerr:
		bsr	DOCV_PTR_BACK		*元に戻す（手抜き^^;）
		ori.b	#%00001000,CCR
		rts

*DOCV_PTR_BACK
*a0 -> 移動後位置（$00の次のアドレス）
*CCR -> 負:ERR
DOCV_PTR_BACK:
		subq.l	#1,a0
		cmp.l	DOCV_MEMPTR(a6),a0
		beq	docv_ptr_bkerr
docv_ptr_back0:
		tst.b	-(a0)
		bne	docv_ptr_back0

		addq.l	#1,a0
		andi.b	#%11110111,CCR
		rts
docv_ptr_bkerr:
		addq.l	#1,a0
		ori.b	#%00001000,CCR
		rts


DOCV_NOW_PRT:
		movem.l	d0-d1/d7/a0-a2,-(sp)

		bsr	DOCV_CLRALL

		move.l	DOCV_FONT(a6),a2	*フォント別アドレス取り出し
		move.w	DV_OUTPUT(a2),d0
		lea.l	DOCV_JPPTR(pc,d0.w),a2

		move.l	DOCV_NOW(a6),a0
		move.l	DOCV_TXTADR(a6),a1

		move.w	DOCV_TATE(a6),d7
		subq.w	#1,d7

		moveq.l	#3,d0			*d1のbit31が1でもTEXT_6_16に影響はない
		moveq.l	#0,d1			*あんまり気持ち良くないけど、手抜き^^;
		bset.l	#31,d1			*あ、わかってると思うけどこのビットは
docv_nowprt_lp:					*TEXT_4_8で使うんだよ～。
		jsr	(a2)

		bsr	DOCV_PTR_NEXT
		dbmi	d7,docv_nowprt_lp

		move.l	a0,DOCV_NEXT(a6)

		movem.l	(sp)+,d0-d1/d7/a0-a2
		rts

DOCV_JPPTR:
DOCV_FP16:
		bsr	TEXT_6_16
		lea.l	$80*16(a1),a1
		rts
DOCV_FP8:
		bsr	TEXT_4_8
		lea.l	$80*12(a1),a1
		rts

DOCVIEW_UP:
		movem.l	d0-d2/a0-a2,-(sp)

		move.l	DOCV_NOW(a6),a0
		bsr	DOCV_PTR_BACK
		bmi	docview_updne

		move.l	DOCV_TXTADR(a6),a1
		move.l	a0,DOCV_NOW(a6)

		bsr	DOCV_SCUP

		moveq.l	#3,d0
		moveq.l	#0,d1
		bset.l	#31,d1

		move.l	DOCV_FONT(a6),a2	*フォント別アドレス取り出し
		move.w	DV_OUTPUT(a2),d2
		lea.l	DOCV_JPPTR(pc),a2
		jsr	0(a2,d2.w)

		move.l	DOCV_NEXT(a6),a0
		bsr	DOCV_PTR_BACK
		move.l	a0,DOCV_NEXT(a6)

docview_updne:
		movem.l	(sp)+,d0-d2/a0-a2
		rts

DOCVIEW_DOWN:
		movem.l	d0-d2/a0-a2,-(sp)

		move.l	DOCV_NOW(a6),a0
		cmp.l	DOCV_SIGEND(a6),a0
		beq	docview_dwdne

		bsr	DOCV_PTR_NEXT
		bmi	docview_dwdne
		move.l	a0,DOCV_NOW(a6)

		bsr	DOCV_SCDW

		moveq.l	#3,d0
		moveq.l	#0,d1
		bset.l	#31,d1
		move.l	DOCV_NEXT(a6),a0
		move.l	DOCV_TXTAD2(a6),a1

		move.l	DOCV_FONT(a6),a2
		move.w	DV_OUTPUT(a2),d2
		lea.l	DOCV_JPPTR(pc),a2
		jsr	0(a2,d2.w)

		bsr	DOCV_PTR_NEXT
		move.l	a0,DOCV_NEXT(a6)

docview_dwdne:
		movem.l	(sp)+,d0-d2/a0-a2
		rts

DOCV_ROLLUP:
		movem.l	d0/a0,-(sp)

		move.l	DOCV_NOW(a6),a0		*ロールアップ出来るか？
		cmp.l	DOCV_SIGEND(a6),a0
		beq	docv_rlup_done

		move.w	DOCV_TATE(a6),d0	*ポインタ移動
		subq.w	#1,d0
		bmi	docv_rlup_done
docv_rlup_lp:
		bsr	DOCV_PTR_NEXT
		bmi	docv_rlup_prt
		cmp.l	DOCV_SIGEND(a6),a0
		dbeq	d0,docv_rlup_lp
docv_rlup_prt:
		move.l	a0,DOCV_NOW(a6)
		bsr	DOCV_NOW_PRT
docv_rlup_done:
		movem.l	(sp)+,d0/a0
		rts

DOCV_ROLLDOWN:
		movem.l	d0/a0,-(sp)

		move.l	DOCV_NOW(a6),a0		*ロールダウン出来るか？
		bsr	DOCV_PTR_BACK
		bmi	docv_rldw_done

		move.w	DOCV_TATE(a6),d0	*ポインタ移動
		subq.w	#2,d0			*－２なのはさっき１回PTR_BACKしたから
		bmi	docv_rldw_prt
docv_rldw_lp:
		bsr	DOCV_PTR_BACK
		dbmi	d0,docv_rldw_lp
docv_rldw_prt:
		move.l	a0,DOCV_NOW(a6)
		bsr	DOCV_NOW_PRT
docv_rldw_done:
		movem.l	(sp)+,d0/a0
		rts

DOCV_CLRALL:
		movem.l	d0-d3,-(sp)		*view範囲をクリア

		move.w	#$8000,d1		*（末メモ参照・・）
		or.b	DOCV_RAS1(a6),d1

		moveq.l	#1,d2			*(0,512)からクリアする～
		move.w	#%11,d3
		IOCS	_TXRASCPY

		move.b	DOCV_RAS2(a6),d2	*一気にらすたコピークリア
		sub.b	DOCV_RAS1(a6),d2
		subq.w	#1,d2

		move.l	d1,d0
		lsl.w	#8,d1
		and.w	#$FF,d0
		addq.w	#1,d0
		or.w	d0,d1

		move.w	#%11,d3
		IOCS	_TXRASCPY

		movem.l	(sp)+,d0-d3
		rts

DOCV_SCDW:
		movem.l	d0-d3/a1,-(sp)

		move.l	DOCV_FONT(a6),a1	*ラスタ計算

		moveq.l	#0,d2
		move.b	DOCV_RAS2(a6),d2	*ここらの計算は範囲が同じなら毎回同じ
		sub.b	DOCV_RAS1(a6),d2	*値が出るのでいっそのことワークに
		sub.w	DV_FONTSZ(a1),d2	*保存するのが望ましいと思われる(^^;

		moveq.l	#0,d1
		move.b	DOCV_RAS1(a6),d1
		add.w	DV_FONTSZ(a1),d1
		lsl.w	#8,d1
		move.b	DOCV_RAS1(a6),d1

		move.w	#%11,d3
		IOCS	_TXRASCPY


		move.w	#$8000,d1		*（末メモ参照・・・）
		or.b	DOCV_RAS2(a6),d1
		move.w	DV_FONTSZ(a1),d2
		sub.w	d2,d1

		move.w	#%11,d3
		IOCS	_TXRASCPY

		movem.l	(sp)+,d0-d3/a1
		rts

DOCV_SCUP:
		movem.l	d0-d3/a1,-(sp)

		move.l	DOCV_FONT(a6),a1	*ラスタ計算

		moveq.l	#0,d2
		move.b	DOCV_RAS2(a6),d2	*SCDWと同じような処理
		sub.b	DOCV_RAS1(a6),d2
		sub.w	DV_FONTSZ(a1),d2

		moveq.l	#0,d1
		move.b	DOCV_RAS2(a6),d1
		sub.w	DV_FONTSZ(a1),d1
		subq.w	#1,d1
		lsl.w	#8,d1
		move.b	DOCV_RAS2(a6),d1
		subq.w	#1,d1

		move.w	#$FF03,d3
		IOCS	_TXRASCPY


		move.w	#$8000,d1		*（末メモ参照・・・）
		or.b	DOCV_RAS1(a6),d1
		move.w	DV_FONTSZ(a1),d2

		move.w	#%11,d3
		IOCS	_TXRASCPY

		movem.l	(sp)+,d0-d3/a1
		rts


			.data
			.even

DOCVFDATA:	.macro	fysize,label1
		.dc.w	fysize			*＜現在最高４まで・・
		.dc.w	label1-DOCV_JPPTR
		.endm

DOCV_FTABLE:
		DOCVFDATA	4,DOCV_FP16
		DOCVFDATA	3,DOCV_FP8

			.end

メモ：
TEXT(0,512)-(512,527)をクリアしてびゅわ範囲クリアの時に
そこから真っ黒４ラインもってきてくりあする～（わかりにくいけど^^;）
よーするに、２段階でくりあしてるんだね。^^;;;
もっと詳しく解説すると～(^^;

+(ｸﾘｱﾊﾝｲ----	∠∠∠___●2:ここにコピーして
|	●3:ﾗｽﾀｺﾋﾟｰｸﾘｱ	|
|		↓	|
|		↓	|
+(ｺｺﾏﾃﾞ-----		|
|    :			|
(0,512)-----●1:ここから~
+-----------

現在のところ、スクロールして、新しくできた行をクリアするのに
(0,512)のいちからラスタコピークリアをするので、フォントドットサイズが
Ｙ１６ドットまでという制限がつく。（詳しくはソース参照）ﾐﾃﾓﾜｶﾝﾅｲｶ･･･^^;;
（まぁ縦１６ドット以上の文字なんて表示してもねぇ・・・^^;）

