*************************************************************************
*									*
*									*
*	    Ｘ６８０００　ＭＸＤＲＶ／ＭＡＤＲＶディスプレイ		*
*									*
*				ＭＭＤＳＰ				*
*									*
*									*
*	Copyright (C) 1991,1992 Kyo Mikami.				*
*	Copyright (C) 1994 Masao Takahashi				*
*									*
*									*
*************************************************************************

		.include	doscall.mac
		.include	MMDSP.h
		.include	DRIVER.h
		.include	FILES.h


*==================================================
*ファイルネームバッファ位置を求める
*	d0.w <- buffer pos.
*	a0.l -> buffer address
*==================================================

get_fnamebuf:
		move.l	d0,-(sp)
		movea.l	#SEL_FNAME,a0		*バッファ位置計算
		ext.l	d0
		lsl.l	#5,d0
		adda.l	d0,a0
		move.l	(sp)+,d0
		rts


*==================================================
*ファイルネームバッファを初期化する
*==================================================

INIT_FNAMEBUF:
		move.l	a0,-(sp)
		clr.w	SEL_FILENUM(a6)
		move.l	#SEL_BUFFER1,SEL_TITLE(a6)
		clr.w	SEL_TITLEBANK(a6)
		clr.w	SEL_CHANGE(a6)

		st.b	SEL_MMOVE(a6)

*		lea	mes_test(pc),a0
*		bsr	G_MESSAGE_PRT

		move.l	(sp)+,a0
		rts

*mes_test:	.dc.b	'バッファがクリアされました。',0
*		.even


*==================================================
*自分のディレクトリヘッダを探す
*	d1.w <- 今いるファイル番号
*	d0.w -> ヘッダのファイル番号
*	a0.l -> ヘッダのアドレス
*==================================================

search_header:
		cmp.w	SEL_FILENUM(a6),d1
		bcc	search_header11
		move.w	d1,d0
		bmi	search_header11
		bsr	get_fnamebuf
search_header10:
		tst.b	(a0)
		bmi	search_header90
		lea	-32(a0),a0
		dbra	d0,search_header10
search_header11:
		moveq	#0,d0			*おかしい時は、いちばん先頭のヘッダを返す
		bsr	get_fnamebuf
search_header90:
		rts


*==================================================
*次のデータを探す（AUTOモード用）
*	d1.w <- 検索を開始するファイル番号
*	d0.l -> 見つけたファイル番号(負ならエラー)
*==================================================

search_next_auto:
		movem.l	d1-d2/a0,-(sp)
		tst.w	SEL_BMAX(a6)		*バッファに１つもファイルがなければエラー
		beq	search_next_auto_err
		tst.w	SEL_FMAX(a6)		*ディレクトリにファイルが無くて
		bne	search_next_auto01
		btst.b	#2,AUTOFLAG(a6)		*ALLDIRモードだったら
		beq	search_next_auto_err
		moveq	#0,d0			*先頭から探す
		moveq	#0,d2
		bsr	get_fnamebuf
		bra	search_next_auto10
search_next_auto01:
		move.w	SEL_FCP(a6),d0
		move.w	d0,d2
		bsr	get_fnamebuf
		tst.b	SEL_MMOVE(a6)		*カーソルが動かされていなければ
		beq	search_next_auto20	*１つ次の曲から探す

search_next_auto10:				*do {
		tst.b	(a0)			*if(データファイル &&
		ble	search_next_auto20
		btst.b	#3,AUTOFLAG(a6)		*  (!PROGMODE || PROGFILE)
		beq	search_next_auto90
		tst.b	PROG_FLAG(a0)
		bne	search_next_auto90	*	return pos;

search_next_auto20:
		lea	32(a0),a0		*pos++;
		addq.w	#1,d0
		cmp.w	SEL_FILENUM(a6),d0	*if( バッファエンド ||
		bcc	search_next_auto21
		tst.b	(a0)			*  (ディレクトリエンド && !ALLDIR)) {
		bpl	search_next_auto30
		btst.b	#2,AUTOFLAG(a6)
		bne	search_next_auto30
search_next_auto21:
		btst.b	#0,AUTOFLAG(a6)		*	if( !REPEAT ) return -1;
		beq	search_next_auto_err
		subq.w	#1,d0
		lea	-32(a0),a0
		bsr	get_repeatpos		*	リピート位置へ移動;
						*}
search_next_auto30:
		cmp.w	d2,d0
		bne	search_next_auto10 	*} while (pos != startpos);

		tst.b	SEL_MMOVE(a6)		*対象が１曲だとMMOVEで飛ばされてしまうので
		bne	search_next_auto_err	*ここで再度チェックする
		tst.b	(a0)			*if(データファイル &&
		ble	search_next_auto_err
		btst.b	#3,AUTOFLAG(a6)		*  (!PROGMODE || PROGFILE)
		beq	search_next_auto90
		tst.b	PROG_FLAG(a0)
		bne	search_next_auto90	*	return pos;

search_next_auto_err:
		moveq	#-1,d0			*return -1;
search_next_auto90:
		tst.w	d0
		movem.l	(sp)+,d1-d2/a0
		rts


*==================================================
*リピートする位置を求める
*	d0.w <- 現在の位置(番号)
*	a0.l <- 現在の位置(アドレス)
*	d0.w -> リピートする位置(番号)
*	a0.l -> リピートする位置(アドレス)
*==================================================

get_repeatpos:
		move.l	d1,-(sp)
		btst.b	#2,AUTOFLAG(a6)
		bne	get_repeatpos20
get_repeatpos10:
		move.w	d0,d1			*ALLDIRモードじゃないなら
		bsr	search_header		*自分のヘッダの位置を返す
		bra	get_repeatpos90
get_repeatpos20:
		moveq	#0,d0			*ALLDIRモードなら
		bsr	get_fnamebuf		*バッファの一番先頭の位置を返す
get_repeatpos90:
		move.l	(sp)+,d1
		rts


*==================================================
*次のデータを探す（SHUFFLEモード用）
*	d1.w <- 検索を開始するファイル番号
*	d0.l -> 見つけたファイル番号(負ならエラー)
*==================================================

search_next_shuffle:
		movem.l	d1-d2/a0,-(sp)
		tst.w	SEL_BMAX(a6)		*バッファに１つもファイルがなければエラー
		beq	search_next_shuf_err
		tst.w	SEL_FMAX(a6)		*ファイルが無くて
		bne	search_next_shuf02
		btst.b	#2,AUTOFLAG(a6)
		beq	search_next_shuf_err	*ALLDIRモードでなければエラー
search_next_shuf02:
		bsr	get_random		*乱数で位置を決める
		moveq	#0,d1
		move.w	d0,d1
		moveq	#0,d2			*オフセット
		move.w	SEL_FILENUM(a6),d0	*ALLDIRモードなら全体対象
		btst.b	#2,AUTOFLAG(a6)
		bne	search_next_shuf03
		move.w	SEL_BTOP(a6),d2
		move.w	SEL_FMAX(a6),d0		*そうでないならディレクトリ内対象
search_next_shuf03:
		divu	d0,d1
		swap	d1			*余りを使う
		add.w	d2,d1
search_next_shuf09:

		move.w	d1,d0
		move.w	d1,d2
		bsr	get_fnamebuf

search_next_shuf10:				*do {
		tst.b	(a0)			*if(データファイル &&
		ble	search_next_shuf20
		btst.b	#3,AUTOFLAG(a6)		*  (!PROGMODE || PROGFILE) &&
		beq	search_next_shuf11
		tst.b	PROG_FLAG(a0)
		beq	search_next_shuf20
search_next_shuf11:
		move.b	SHUFFLE_CODE(a6),d1	*  SHUFFLE_FLAG != SHAFFLE_CODE )
		cmp.b	SHUFFLE_FLAG(a0),d1
		bne	search_next_shuf90	*	return pos;

search_next_shuf20:
		lea	32(a0),a0		*pos++;
		addq.w	#1,d0
		cmp.w	SEL_FILENUM(a6),d0	*if( バッファエンド ||
		bcc	search_next_shuf21
		tst.b	(a0)			*  (ディレクトリエンド && !ALLDIR)) {
		bpl	search_next_shuf30
		btst.b	#2,AUTOFLAG(a6)
		bne	search_next_shuf30
search_next_shuf21:
		subq.w	#1,d0
		lea	-32(a0),a0
		bsr	get_repeatpos		*	リピート位置へ移動;
						*}

search_next_shuf30:
		cmp.w	d2,d0
		bne	search_next_shuf10 	*} while (pos != startpos);
search_next_shuf_err:
		moveq	#-1,d0			*return -1;
search_next_shuf90:
		tst.w	d0
		movem.l	(sp)+,d1-d2/a0
		rts


*==================================================
*乱数を得る
*	d0.w -> 乱数
*==================================================

get_random:
		movem.l	d1/a0,-(sp)
		MYONTIME
		move.w	RND_WORK(a6),d1
		not.w	d0
		eor.w	d1,d0
		rol.w	#8,d0
		move.w	d0,RND_WORK(a6)
		movem.l	(sp)+,d1/a0
		rts


*==================================================
*カレントのデータファイルを書き出す
*==================================================

write_datafile:
		movem.l	d1-d2/a1,-(sp)
		moveq	#-1,d2

		movea.l	SEL_HEAD(a6),a1
		move.w	FILE_NUM(a1),d1
		subq.w	#1,d1
		bcs	write_datafile90

		move.w	#$20,-(sp)
		pea	name_datafile(pc)
		DOS	_CREATE
		addq.l	#6,sp
		move.l	d0,d2
		bmi	write_datafile90

		move.w	d2,-(sp)
		pea	datafile_head(pc)
		DOS	_FPUTS
		addq.l	#6,sp

write_datafile10:
		lea	32(a1),a1
		tst.b	(a1)
		beq	write_datafile19
		move.w	d2,-(sp)
		tst.b	DOC_FLAG(a1)
		beq	write_datafile11
		move.w	#'+',-(sp)
		DOS	_FPUTC
		addq.l	#2,sp
write_datafile11:
		pea	FILE_NAME(a1)
		DOS	_FPUTS
		addq.l	#4,sp
		tst.l	TITLE_ADR(a1)
		beq	write_datafile15
		move.w	#9,-(sp)
		DOS	_FPUTC
		addq.l	#2,sp
		move.l	TITLE_ADR(a1),-(sp)
		DOS	_FPUTS
		addq.l	#4,sp
write_datafile15:
		move.w	#13,-(sp)
		DOS	_FPUTC
		move.w	#10,(sp)
		DOS	_FPUTC
		addq.l	#4,sp
write_datafile19:
		dbra	d1,write_datafile10

write_datafile90:
		tst.l	d2
		bmi	write_datafile91
		move.w	d2,-(sp)
		DOS	_CLOSE
		addq.l	#2,sp
write_datafile91:
		movem.l	(sp)+,d1-d2/a1
		rts


name_datafile:	.dc.b	'MMDSP.DAT',0
datafile_head:	.dc.b	'MMDSPDAT'
		.dc.l	MMDATVER
		.dc.b	13,10,0
		.even


*==================================================
*データファイルを読み込む
*	a0.l <- ディレクトリヘッダ
*==================================================

read_datafile:
		movem.l	d0-d4/a0-a4,-(sp)

		movea.l	a0,a3			*a3 <- dir head

		clr.l	-(sp)			*カレントのデータファイルを読み込んで
		clr.l	-(sp)
		pea	name_datafile(pc)
		bsr	READ_FILE
		lea	12(sp),sp
		move.l	a0,-(sp)
		movea.l	a0,a4			*a4 <- data adr
		move.l	d0,d4			*d4 <- data len
		bmi	read_datafile90

		bsr	read_datafile_check	*バージョンチェック
		bne	read_datafile90
		bsr	read_datafile_next

read_datafile10:
		bsr	read_datafile_search	*一致するファイルを探してタイトル取得
		bsr	read_datafile_next	*次の行へ
		tst.l	d4
		bgt	read_datafile10

read_datafile90:
		bsr	FREE_MEM
		addq.l	#4,sp
		movem.l	(sp)+,d0-d4/a0-a4
		rts

*----------------------------------------
*データをチェックする
*	a4.l <- データファイルのバッファアドレス
*	d0.l -> 0なら適合データ (ccrにも返る)

read_datafile_check:
		cmpi.l	#'MMDS',(a4)
		bne	read_datafile_checkerr
		cmpi.l	#'PDAT',4(a4)
		bne	read_datafile_checkerr
		cmpi.l	#MMDATVER,8(a4)
		bne	read_datafile_checkerr
		moveq	#0,d0
		bra	read_datafile_check90
read_datafile_checkerr:
		moveq	#-1,d0
read_datafile_check90:
		rts


*----------------------------------------
*データファイルからタイトルを取得
*	a3.l <- ディレクトリヘッダのアドレス
*	a4.l <- データファイルのバッファアドレス
*	d4.l <- データファイルの残り長さ

read_datafile_search:
		tst.l	d4				*データの終わりか、
		ble	read_datafile_search90
		cmpi.b	#' ',(a4)			*文字以外だったら何もしない
		bls	read_datafile_search90
		cmpi.b	#'+',(a4)
		seq.b	d2
		bne	read_datafile_search09
		addq.l	#1,a4
read_datafile_search09:

		move.w	TOP_POS(a3),d0			*ディレクトリの最初から、
		bsr	get_fnamebuf
		lea	FILE_NAME-32(a0),a2
		move.w	FILE_NUM(a3),d3
read_datafile_search10:
		move.b	(a4),d0
		bra	read_datafile_search19
read_datafile_search11:
		cmp.b	(a2),d0				*最初の１文字が一致するものを探し、
read_datafile_search19:
		lea	32(a2),a2
		dbeq	d3,read_datafile_search11
		bne	read_datafile_search90
		lea	-32(a2),a2

read_datafile_search20:
		lea	1(a2),a0			*残りの文字が一致するかしらべ、
		lea	1(a4),a1
read_datafile_search21:
		move.b	(a0)+,d0
		beq	read_datafile_search30
		cmp.b	(a1)+,d0
		beq	read_datafile_search21
		bra	read_datafile_search10		*違っていれば次へ

read_datafile_search30:
		cmpi.b	#9,(a1)				*ファイル名が完全に一致したら
		bne	read_datafile_search10		*タブチェックして
read_datafile_search31:
		cmpi.b	#9,(a1)+			*タブを飛ばす
		beq	read_datafile_search31
		subq.l	#1,a1

		link	a5,#-128			*タイトルをコピーして
		movea.l	sp,a0
		moveq	#127-1,d1
read_datafile_search32:
		move.b	(a1)+,d0
		cmpi.b	#$0d,d0
		beq	read_datafile_search33
		move.b	d0,(a0)+
		dbra	d1,read_datafile_search32
read_datafile_search33:
		clr.b	(a0)
		movea.l	sp,a0				*タイトル登録
		bsr	COPY_TITLE
		move.l	d0,TITLE_ADR-FILE_NAME(a2)
		move.b	d2,DOC_FLAG-FILE_NAME(a2)	*DOCフラグセット
		unlk	a5

read_datafile_search90:
		rts

*----------------------------------------
*データファイルの次の行へ
*	a4.l <-> データファイルのバッファアドレス
*	d4.l <-> データファイルの残り長さ

read_datafile_next:
read_datafile_next10:
		tst.l	d4
		ble	read_datafile_next90
		subq.l	#1,d4
		cmpi.b	#$0a,(a4)+
		bne	read_datafile_next10
read_datafile_next90:
		rts


*==================================================
*SEL_FNAMEにカレントディレクトリをセットする
*	d0.l -> ディレクトリヘッダのアドレス、負ならエラー
*==================================================

FNAME_SET:
		movem.l	d1/a0-a2,-(sp)
		moveq	#0,d0			*カレントドライブが使えない場合
		bsr	DRIVE_CHECK
		bpl	fname_set10
		lea	DUMMY_HEAD(pc),a0	*ダミーのヘッダを返す
		move.l	a0,d0
		bra	fname_set90

fname_set10:
		lea	CURRENT(a6),a1		*ドライブが使える場合
		movea.l	a1,a0
		bsr	CHECK_DIRDUP		*ヘッダ登録ずみなら、おわる
		tst.l	d0
		bpl	fname_set90

		movea.l	a1,a0			*ディレクトリヘッダを登録
		bsr	STORE_DIRHED
		tst.l	d0
		bmi	fname_set90

		move.l	d0,a2			*ファイル名登録開始っ
		lea	SEL_FILES(a6),a1

		moveq	#$10,d0			*まずディレクトリ属性で検索
		bsr	fname_setsub

		moveq	#$20,d0			*次にファイル属性で検索
		bsr	fname_setsub

		movea.l	a2,a0			*データファイルがあれば読み込む
		bsr	read_datafile

		move.l	d1,d0
		bmi	fname_set90
		move.l	a2,d0

fname_set90:
		movem.l	(sp)+,d1/a0-a2
		rts

fname_setsub:
		move.w	d0,-(sp)
		pea	FILES_WILD(pc)
		pea	(a1)
		DOS	_FILES
		bra	fname_setsub20
fname_setsub10:
		move.l	a2,a0
		bsr	STORE_FNAME
		move.l	d0,d1
		bmi	fname_setsub30
		DOS	_NFILES
fname_setsub20:
		tst.l	d0
		bpl	fname_setsub10
fname_setsub30:
		lea	10(sp),sp
		rts

DUMMY_HEAD:	.dc.b	$FF,$FF,$00,$00,$00,$00,$00,$00
		.dc.b	$00,$00,$00,$00,$00,$00,$00,$00
FILES_WILD:	.dc.b	'*.*',0
		.even

*==================================================
*ディレクトリ登録有無調査
*	a0 <- 調べたいディレクトリの絶対パス名
*	d0 -> ディレクトリヘッダのアドレス、なければ負
*==================================================

CHECK_DIRDUP:
		movem.l	a0-a3,-(sp)
		tst.w	SEL_FILENUM(a6)
		beq	check_dirdup80

		movea.l	#SEL_FNAME,a2			*最初から
check_dirdup10:
		movea.l	a0,a3
		movea.l	PATH_ADR(a2),a1
check_dirdup20:
		move.b	(a3)+,d0			*パス名を比較
		beq	check_dirdup30
		cmp.b	(a1)+,d0
		beq	check_dirdup20
		bra	check_dirdup40
check_dirdup30:
		move.l	a2,d0
		tst.b	(a1)
		beq	check_dirdup90
check_dirdup40:
		movea.l	NEXT_DIR(a2),a2			*次のディレクトリ
		move.l	a2,d0
		bne	check_dirdup10

check_dirdup80:
		moveq	#-1,d0
check_dirdup90:
		movem.l	(sp)+,a0-a3
		rts


*==================================================
*ディレクトリヘッダを登録する
*	a0.l <- 登録するディレクトリの絶対パス名
*	d0.l -> 登録したディレクトリヘッダのアドレス
*		負ならファイル数オーバー
*==================================================

STORE_DIRHED:
		movem.l	a0-a2,-(sp)

		cmpi.w	#MAXFILE,SEL_FILENUM(a6)	*ファイル数上限チェック
		bcc	store_dirhed_err

		movea.l	a0,a2
		move.w	SEL_FILENUM(a6),d0		*バッファアドレス計算
		bsr	get_fnamebuf
		exg	a0,a2

		tst.w	SEL_FILENUM(a6)
		beq	store_dirhed20
		movea.l	#SEL_FNAME,a1			*前のヘッダとリンクする
store_dirhed10:
		move.l	NEXT_DIR(a1),d0
		beq	store_dirhed11
		movea.l	d0,a1
		bra	store_dirhed10
store_dirhed11:
		move.l	a2,NEXT_DIR(a1)

store_dirhed20:
		move.b	#$FF,HEAD_MARK(a2)		*各項目セット
		clr.b	KENS_FLAG(a2)
		clr.w	FILE_NUM(a2)
		clr.l	NEXT_DIR(a2)
		move.w	SEL_FILENUM(a6),d0
		addq.w	#1,d0
		move.w	d0,SEL_FILENUM(a6)
		move.w	d0,PAST_POS(a2)
		move.w	d0,TOP_POS(a2)

		bsr	COPY_TITLE			*ディレクトリ名コピー
		move.l	d0,PATH_ADR(a2)

		move.l	a2,d0
		movem.l	(sp)+,a0-a2
		rts

store_dirhed_err:
		moveq	#-1,d0
		movem.l	(sp)+,a0-a2
		rts

*==================================================
*ファイル名を登録する
*	a0.l <- ディレクトリヘッダ
*	a1.l <- _FILES バッファ
*	d0.l -> 負なら、ファイル数オーバー
*==================================================

STORE_FNAME:
		movem.l	d1/a0-a2,-(sp)

		cmpi.w	#MAXFILE,SEL_FILENUM(a6)	*ファイル数上限チェック
		bcc	store_fname_err

		bsr	DIRECTORY_CHCK			*演奏可能ファイルor<dir>か？
		move.l	d0,d1
		bmi	store_fname90

		addq.w	#1,FILE_NUM(a0)

		move.w	SEL_FILENUM(a6),d0		*バッファアドレス計算
		bsr	get_fnamebuf

		move.b	d1,DATA_KIND(a0)		*識別コードセット

		pea	30(a1)				*ファイル名をコピー
		pea	FILE_NAME(a0)
		bsr	COPY_STRING
		addq.l	#8,sp

		clr.l	TITLE_ADR(a0)			*タイトルアドレスクリア

		move.b	SHUFFLE_CODE(a6),d0
		subq.b	#1,d0
		move.b	d0,SHUFFLE_FLAG(a0)		*シャフルフラグと
		clr.b	PROG_FLAG(a0)			*プログラムフラグと
		clr.b	DOC_FLAG(a0)			*ドキュメント存在フラグをクリア

		addq.w	#1,SEL_FILENUM(a6)

store_fname90:
		moveq	#0,d0
		movem.l	(sp)+,d1/a0-a2
		rts

store_fname_err:
		moveq	#-1,d0
		movem.l	(sp)+,d1/a0-a2
		rts


*==================================================
*タイトルバッファにタイトル登録
*	a0.l <- タイトル
*	d0.l -> 登録したアドレス
*==================================================

COPY_TITLE:
		movem.l	a0-a2,-(sp)

		move.l	SEL_TITLE(a6),a2

		move.l	a0,a1				*タイトルの長さを調べる
copy_title10:
		tst.b	(a1)+
		bne	copy_title10
		suba.l	a0,a1

		move.w	a2,d1				*オーバーしたら、次のバッファへ
		add.w	a1,d1
		bcc	copy_title30
		move.w	SEL_TITLEBANK(a6),d0
		beq	copy_title20
		cmpi.w	#1,d0
		beq	copy_title21
		lea	INVALID_TITLE(pc),a2		*バッファ使い尽くした時
		bra	copy_title40
copy_title20:
		movea.l	#SEL_BUFFER2,a2
		bra	copy_title22
copy_title21:
		movea.l	#SEL_BUFFER3,a2
copy_title22:
		addq.w	#1,SEL_TITLEBANK(a6)

copy_title30:
		adda.l	a2,a1				*次のアドレス
		move.l	a1,SEL_TITLE(a6)

		move.l	a0,-(sp)			*タイトルコピー
		move.l	a2,-(sp)
		bsr	COPY_STRING
		addq.l	#8,sp

copy_title40:
		move.l	a2,d0
copy_title90:
		movem.l	(sp)+,a0-a2
		rts

INVALID_TITLE:	.dc.b	'- title area over -',0
		.even

*==================================================
*	＊ＤＩＲＥＣＴＯＲＹ＿ＣＨＣＫ
*機能：ＭＤＸファイルかディレクトリかを判断する
*入力：	ＳＥＬ＿ＦＩＬＥＳ
*出力：	Ｄ０	演奏ファイル識別コード（１～
*		－１：範囲外ファイル
*		　０：ディレクトリ
*参考：SEL_FILESにDOS _(N)FILESの結果を入れてコールすること
*==================================================

DIRECTORY_CHCK:
		movem.l	d1-d2/a0-a2,-(sp)

		DRIVER	DRIVER_FILEEXT			*■ラベルは変えてもいいよ
		movea.l	d0,a2
		lea.l	SEL_FILES(a6),a0

		btst.b	#4,21(a0)			*ディレクトリか？
		beq	dirchk_jp0

		lea.l	30(a0),a1
		cmp.w	#$2E00,(a1)			*「.   < dir >」をなくす
		beq	dirchk_chker

		moveq.l	#0,d0
		bra	dirchk_done

dirchk_jp0:
		lea.l	30(a0),a1			*ディレクトリでない時
		moveq	#0,d1
dirchk_lp0:
		move.b	(a1)+,d0			*拡張子位置に合わせる
		beq	dirchk_jp1
		cmpi.b	#'.',d0
		bne	dirchk_lp0
		move.l	a1,d1
		bra	dirchk_lp0
dirchk_jp1:
		tst.l	d1
		beq	dirchk_chker
		movea.l	d1,a1
		moveq.l	#0,d1
		move.b	(a1)+,d1
		beq	dirchk_jp2
		lsl.l	#8,d1
		move.b	(a1)+,d1
		beq	dirchk_jp2
		lsl.l	#8,d1
		move.b	(a1)+,d1
dirchk_jp2:
		and.l	#$DFDFDF,d1
		move.l	a2,a0
dirchk_lp1:
		moveq.l	#0,d0
		move.b	(a0),d0
		beq	dirchk_chker
		move.l	(a0)+,d2
		and.l	#$DFDFDF,d2
		cmp.l	d1,d2
		beq	dirchk_done
		bra	dirchk_lp1

dirchk_chker:
		moveq.l	#-1,d0
dirchk_done:
		movem.l	(sp)+,d1-d2/a0-a2
		rts


*==================================================
*タイトルを検索する
*	d0.l -> タイトル取得したファイルの番号
*		負なら、検索終了
*	a0.l -> 対応するアドレス
*==================================================

SEARCH_TITLE:
		move.l	d1,-(sp)
		bsr	MIKEN_CHECK			*未検索あるかなぁ～っ？
		tst.l	d0
		bmi	search_title90
		move.l	d0,d1
		bsr	CHECK_DOCFILE			*ドキュメントの有無チェック
		bsr	GET_TITLE			*タイトル読み込み
		move.l	d1,d0
search_title90:
		move.l	(sp)+,d1
		rts


*==================================================
*	＊ＭＩＫＥＮ＿ＣＨＥＣＫ
*機能：タイトル未検索のバッファ位置を求める
*入力：なし
*出力：	Ｄ０	バッファ位置／負の場合は未検索なし
*	Ａ０	対応するアドレス
*参考：SEL_BSCHから順に調べ始める
*==================================================

MIKEN_CHECK:
		move.l	d1,-(sp)

		move.w	SEL_BSCH(a6),d1			*検索開始位置を求める
		cmp.w	SEL_BMAX(a6),d1
		bcs	miken_check01
		move.w	SEL_BTOP(a6),d1
miken_check01:
		move.w	d1,d0
		bsr	get_fnamebuf

		moveq	#-1,d0
		move.w	SEL_FMAX(a6),d2
		beq	miken_check90
		subq.w	#1,d2
miken_check10:
		tst.b	DATA_KIND(a0)			*データファイルで
		ble	miken_check20
		tst.l	TITLE_ADR(a0)			*タイトルが検索されていなければ
		beq	miken_check30			*その位置を返す
miken_check20:
		addq.w	#1,d1				*バッファの終わりに来たら、
		cmp.w	SEL_BMAX(a6),d1
		bne	miken_check21
		move.w	SEL_BTOP(a6),d1			*バッファの先頭へ戻る
		move.w	d1,d0
		bsr	get_fnamebuf
		bra	miken_check22
miken_check21:
		lea	32(a0),a0
miken_check22:
		dbra	d2,miken_check10
		moveq	#-1,d0
		bra	miken_check90

miken_check30:
		moveq	#0,d0
		move.w	d1,d0
		addq.w	#1,d1
		move.w	d1,SEL_BSCH(a6)
miken_check90:
		move.l	(sp)+,d1
		rts


*==================================================
*ドキュメント有無チェック
*	a0.l <- ファイルネームバッファ
*	d0.l -> ドキュメントの有無(0:無 それ以外:有)
*		DOC_FLAGにもセットされる
*==================================================

CHECK_DOCFILE:
		movem.l	d1/a0-a2,-(sp)
		link	a5,#-24
		moveq	#0,d1
		movea.l	a0,a2
		lea	FILE_NAME(a2),a0		*拡張子を.docにして
		movea.l	sp,a1
		bsr	change_ext_doc
		tst.l	d0
		bmi	check_docfile90
		move.w	#-1,-(sp)			*属性を調べる
		move.l	a1,-(sp)
		DOS	_CHMOD
		addq.l	#6,sp
		tst.l	d0				*DOSエラーがなく、
		bmi	check_docfile90
		btst.l	#5,d0				*アーカイブ属性が立っていれば
		beq	check_docfile90
		moveq	#1,d1				*ドキュメントは存在する
check_docfile90:
		move.b	d1,DOC_FLAG(a2)
		unlk	a5
		movem.l	(sp)+,d1/a0-a2
		rts


*==================================================
*拡張子を.docにする
*	a0.l <- ファイル名
*	a1.l <- 結果の入るバッファ
*	d0.l -> 負ならファイル名不正
*==================================================

change_ext_doc:
		movem.l	a0-a1,-(sp)
		moveq	#23-1,d0
change_ext_doc10:
		move.b	(a0)+,(a1)+
		dbeq	d0,change_ext_doc10
		bne	change_ext_doc_err		*ファイル名が終わってない！
		sub.w	#23-1,d0
		neg.w	d0
		subq.w	#1,d0
		bmi	change_ext_doc_err		*ファイル名が無い！
change_ext_doc20:
		cmpi.b	#'.',-(a1)
		dbeq	d0,change_ext_doc20
		bne	change_ext_doc_err		*拡張子が見つからない！
		addq.l	#1,a1
		move.b	#'d',(a1)+
		move.b	#'o',(a1)+
		move.b	#'c',(a1)+
		clr.b	(a1)
		movem.l	(sp)+,a0-a1
		moveq	#0,d0
		rts

change_ext_doc_err:
		movem.l	(sp)+,a0-a1
		moveq	#-1,d0
		rts


*==================================================
*タイトル取得
*	a0.l <- ファイルネームバッファ
*==================================================

GET_TITLE:
		movem.l	d0-d2/a0-a1,-(sp)
		link	a5,#-256
		movea.l	sp,a1
		movea.l	a0,a2
		lea	FILE_NAME(a2),a0		*ファイルの頭を少し読んで
		bsr	READ_FILEBUFF
		tst.l	d0
		bpl	get_title10
		lea	ERROR_TITLE(pc),a0		*エラーならエラータイトル登録
		move.l	a0,TITLE_ADR(a2)
		bra	get_title90
get_title10:
		move.b	DATA_KIND(a2),d0		*拡張子に対応したサブへジャンプ
		cmpi.b	#_EXTMAX,d0
		bls	get_title11
		moveq	#0,d0
get_title11:
		ext.w	d0
		add.w	d0,d0
		lea	title_jmp(pc),a0
		move.w	(a0,d0.w),d0
		jsr	(a0,d0.w)
get_title20:
		movea.l	sp,a0				*タイトル登録
		bsr	COPY_TITLE
		move.l	d0,TITLE_ADR(a2)
get_title90:
		unlk	a5
		movem.l	(sp)+,d0-d2/a0-a1
		rts

ERROR_TITLE:	.dc.b	'- file read error -',0
		.even

title_jmp:
		.dc.w	title_non-title_jmp	* 0:none
		.dc.w	title_mdx-title_jmp	* 1:MDX
		.dc.w	title_mdx-title_jmp	* 2:MDR
		.dc.w	title_rcp-title_jmp	* 3:RCP
		.dc.w	title_rcp-title_jmp	* 4:R36
		.dc.w	title_mdf-title_jmp	* 5:MDF
		.dc.w	title_mcp-title_jmp	* 6:MCP
		.dc.w	title_mdx-title_jmp	* 7:MDI
		.dc.w	title_sng-title_jmp	* 8:SNG
		.dc.w	title_smf-title_jmp	* 9:MID
		.dc.w	title_smf-title_jmp	*10:STD
		.dc.w	title_smf-title_jmp	*11:MFF
		.dc.w	title_smf-title_jmp	*12:SMF
		.dc.w	title_non-title_jmp	*13:SEQ
		.dc.w	title_mdx-title_jmp	*14:MDZ
		.dc.w	title_mdn-title_jmp	*15:MDN
		.dc.w	title_kmd-title_jmp	*16:KMD
		.dc.w	title_zms-title_jmp	*17:ZMS
		.dc.w	title_zmd-title_jmp	*18:ZMD
		.dc.w	title_zms-title_jmp	*19:OPM
		.dc.w	title_mdf-title_jmp	*20:ZDF
		.dc.w	title_non-title_jmp	*21:MM2
		.dc.w	title_non-title_jmp	*22:MMC
		.dc.w	title_non-title_jmp	*23:MDC
		.dc.w	title_pic-title_jmp	*PIC
		.dc.w	title_mag-title_jmp	*MAG
		.dc.w	title_pi-title_jmp	*PI
		.dc.w	title_jpg-title_jmp	*JPG

*----------------------------------------
title_non:
		clr.b	(a1)
		rts

*----------------------------------------
title_mdx:
		lea	FILE_BUFF(a6),a0
		moveq	#72-1,d1
title_mdx10:
		move.b	(a0)+,d0
		beq	title_mdx20			*$00,$0D,$0A,$1Aで終了
		cmpi.b	#$0D,d0
		beq	title_mdx20
		cmpi.b	#$0A,d0
		beq	title_mdx20
		cmpi.b	#$1A,d0
		beq	title_mdx20
		move.b	d0,(a1)+
		dbra	d1,title_mdx10
title_mdx20:
		clr.b	(a1)
		rts

*----------------------------------------
title_rcp:
		lea	FILE_BUFF+32(a6),a0
		moveq	#64-1,d1
title_rcp10:
		move.b	(a0)+,d0
		beq	title_rcp20			*$00で終了
		move.b	d0,(a1)+
		dbra	d1,title_rcp10
title_rcp20:
		clr.b	(a1)
		rts

*----------------------------------------
title_mcp:
		lea	FILE_BUFF+2(a6),a0
		moveq	#30-1,d1
title_mcp10:
		move.b	(a0)+,(a1)+
		dbra	d1,title_mcp10
		clr.b	(a1)
		rts

*----------------------------------------
title_mdf:
		lea	FILE_BUFF+6(a6),a0
		moveq	#72-1,d1
title_mdf10:
		move.b	(a0)+,d0
		beq	title_mdf20			*$00,$0D,$0A,$1Aで終了
		cmpi.b	#$0D,d0
		beq	title_mdf20
		cmpi.b	#$0A,d0
		beq	title_mdf20
		cmpi.b	#$1A,d0
		beq	title_mdf20
		move.b	d0,(a1)+
		dbra	d1,title_mdf10
title_mdf20:
		clr.b	(a1)
		rts
*----------------------------------------
title_sng:
		lea	FILE_BUFF(a6),a0
		cmpi.l	#'BALL',(a0)
		bne	title_sng_mro
		cmpi.l	#'ADE ',4(a0)
		bne	title_sng_mro
		cmpi.l	#'SONG',8(a0)
		bne	title_sng_mro

		moveq	#16-1,d1
title_sng10:
		move.b	(a0)+,d0
		beq	title_sng20			*$00で終了
		move.b	d0,(a1)+
		dbra	d1,title_sng10
title_sng20:
		clr.b	(a1)
		rts

title_sng_mro:
		cmpi.b	#$0A,(a0)+			*2行目を探す
		bne	title_sng_mro
		moveq	#72-1,d1
title_sng_mro10:
		move.b	(a0)+,d0
		beq	title_sng_mro20			*$00,$0D,$0A,$1Aで終了
		cmpi.b	#$0D,d0
		beq	title_sng_mro20
		cmpi.b	#$0A,d0
		beq	title_sng_mro20
		cmpi.b	#$1A,d0
		beq	title_sng_mro20
		move.b	d0,(a1)+
		dbra	d1,title_sng_mro10
title_sng_mro20:
		clr.b	(a1)
		rts

*----------------------------------------
Getlong		.macro				*(a0)からロングワードをd0にとってくる
.if 0
		move.b	(a0)+,d0		*素直なコーディング版
		lsl.l	#8,d0
		move.b	(a0)+,d0
		lsl.l	#8,d0
		move.b	(a0)+,d0
		lsl.l	#8,d0
		move.b	(a0)+,d0
		subq.l	#4,d1
		bcs	title_smf90
.else
		move.b	(a0)+,-(sp)		*姑息なスタック技版
		move.w	(sp)+,d0
		move.b	(a0)+,d0
		swap	d0
		move.b	(a0)+,-(sp)
		move.w	(sp)+,d0
		move.b	(a0)+,d0
		subq.l	#4,d1
		bcs	title_smf90
.endif
		.endm

title_smf:
		movem.l	d1-d4/a2-a3,-(sp)
		lea	FILE_BUFF(a6),a0
		lea	title_smf_dum(pc),a2
		movea.l	a2,a3
		moveq	#0,d2
		moveq	#0,d3
		move.l	#1024-1,d1
		Getlong				*ヘッダブロックを飛ばす
		cmpi.l	#'MThd',d0
		bne	title_smf90
title_smf10:
		Getlong
		sub.l	d0,d1			*トラックブロックを探す
		bls	title_smf90
		adda.l	d0,a0
		Getlong
		cmpi.l	#'MTrk',d0
		bne	title_smf10
		Getlong
title_smf20:
		bsr	getvarlen		*delta-time飛ばす
		tst.l	d0
		bne	title_smf30
		tst.l	d1
		blt	title_smf30
		subq.l	#2,d1			*メタイベントを取得
		bcs	title_smf30
		cmpi.b	#$ff,(a0)+
		bne	title_smf30
		move.b	(a0)+,d4
		bsr	getvarlen
		tst.l	d1
		blt	title_smf30
title_smf21:
		cmpi.b	#$01,d4			*FF 01(汎用テキストイベント）か
		bne	title_smf22
		tst.b	(a2)
		bne	title_smf29
		movea.l	a0,a2
		move.l	d0,d2
		bra	title_smf29
title_smf22:
		cmpi.b	#$02,d4			*FF 02(著作権表示）か
		bne	title_smf23
		movea.l	a0,a3
		move.l	d0,d3
		bra	title_smf29
title_smf23:
		cmpi.b	#$03,d4			*FF 03(シーケンス名)なら、アドレス保存
		bne	title_smf29
		movea.l	a0,a2
		move.l	d0,d2
title_smf29:
		adda.l	d0,a0			*それ以外ならスキップしてループ
		sub.l	d0,d1
		bcc	title_smf20

title_smf30:
		clr.b	(a2,d2.l)
		clr.b	(a3,d3.l)
		moveq	#72-1,d1
		tst.l	d2
		beq	title_smf32
title_smf31:
		move.b	(a2)+,(a1)+		*シーケンス名をコピー
		dbeq	d1,title_smf31
		bne	title_smf90
		move.b	#' ',-1(a1)
title_smf32
		move.b	(a3)+,(a1)+		*著作権表示をコピー
		dbeq	d1,title_smf32

title_smf90:
		clr.b	(a1)
		movem.l	(sp)+,d1-d4/a2-a3
		rts

getvarlen:
		movem.l	d2,-(sp)
		moveq	#0,d0
get_varlen10:
		subq.l	#1,d1
		blt	get_varlen90
		move.b	(a0)+,d2
		bpl	get_varlen20
		andi.b	#$7f,d2
		or.b	d2,d0
		lsl.l	#7,d0
		bra	get_varlen10
get_varlen20:
		or.b	d2,d0
get_varlen90:
		movem.l	(sp)+,d2
		rts

title_smf_dum:	.dc.w	0


*----------------------------------------
title_mdn:
		lea	FILE_BUFF+64(a6),a0
		moveq	#72-1,d1
title_mdn10:
		move.b	(a0)+,d0
		beq	title_mdn20			*$00でタイトル終了
		move.b	d0,(a1)+
		dbra	d1,title_mdn10
		bra	title_mdn60
title_mdn20:
		move.b	#' ',(a1)+
title_mdn30:
		move.b	(a0)+,d0
		beq	title_mdn40			*$00で作曲者終了
		move.b	d0,(a1)+
		dbra	d1,title_mdn30
		bra	title_mdn60
title_mdn40:
		move.b	#' ',(a1)+
title_mdn50:
		move.b	(a0)+,d0
		beq	title_mdn60			*$00で制作者終了
		move.b	d0,(a1)+
		dbra	d1,title_mdn50
title_mdn60
		clr.b	(a1)
		rts

*----------------------------------------
title_kmd:
		lea	FILE_BUFF+42(a6),a0
		moveq	#72-1,d1
title_kmd10:
		move.b	(a0)+,d0
		beq	title_kmd20			*$00で終了
		move.b	d0,(a1)+
		dbra	d1,title_kmd10
title_kmd20:
		clr.b	(a1)
		rts

*----------------------------------------
title_zms:						*ZMUSICは、なにかと面倒なのだ
		move.l	a2,-(sp)			*みよ、このコードの長さ（笑）
		lea	FILE_BUFF(a6),a0		*MIDファイル程じゃないけどね(^^;)
		move.w	#1024-1,d2

title_zms10:
		cmpi.b	#' ',(a0)+			*スペースを飛ばし、
		dbhi	d2,title_zms10
		bls	title_zms_none

		subq.w	#1,d2
		bcs	title_zms_none
		move.b	-1(a0),d0			*行頭が'.'か'#'ならば、
		cmpi.b	#'.',d0
		beq	title_zms20
		cmpi.b	#'#',d0
		bne	title_zms22

title_zms20:
		lea	comment_str(pc),a2
title_zms21:
		move.b	(a2)+,d0			*'COMMENT'があるかチェックする
		beq	title_zms30
		move.b	(a0)+,d1
		subq.w	#1,d2
		bcs	title_zms_none
		andi.b	#$DF,d1
		cmp.b	d0,d1
		beq	title_zms21
title_zms22:
		cmpi.b	#$0A,(a0)+			*なければ、次の行へ
		dbeq	d2,title_zms22
		bne	title_zms_none
		subq.w	#1,d2
		bcs	title_zms_none
		bra	title_zms10

title_zms30:
		move.b	(a0)+,d0			*あれば、スペース飛ばし
		subq.w	#1,d2
		bcs	title_zms50
		cmpi.b	#' ',d0
		beq	title_zms30
		cmpi.b	#9,d0
		beq	title_zms30

		addq.w	#1,d2
		subq.l	#1,a0				*72文字タイトル取得
		moveq	#72-1,d1
title_zms40:
		move.b	(a0)+,d0
		beq	title_zms50			*$00/$0D/$0A/$1Aで終了
		cmpi.b	#$0D,d0
		beq	title_zms50
		cmpi.b	#$0A,d0
		beq	title_zms50
		cmpi.b	#$1A,d0
		beq	title_zms50
		subq.w	#1,d2
		bcs	title_zms50
		move.b	d0,(a1)+
		dbra	d1,title_zms40
title_zms50:
title_zms_none:
		clr.b	(a1)
		move.l	(sp)+,a2
		rts

comment_str:	.dc.b	'COMMENT',0

*----------------------------------------
title_zmd:				*ZMDもタイトルの位置くらい決めておいて欲しかった
		lea	FILE_BUFF+8(a6),a0

		cmpi.b	#$7F,(a0)+			*先頭に$7Fがないとだめなの
		bne	title_zmd20

		moveq	#72-1,d1
title_zmd10:
		move.b	(a0)+,d0
		beq	title_zmd20			*$00で終了
		move.b	d0,(a1)+
		dbra	d1,title_zmd10
title_zmd20:
		clr.b	(a1)
		rts

*----------------------------------------
title_pic:
		lea	FILE_BUFF(a6),a0
		cmpi.b	#'P',(a0)+
		bne	title_pic20
		cmpi.b	#'I',(a0)+
		bne	title_pic20
		cmpi.b	#'C',(a0)+
		bne	title_pic20
		moveq	#72-1,d1
title_pic10:
		move.b	(a0)+,d0
		beq	title_pic20			*$00,$0d,$1aで終了
		cmpi.b	#$0d,d0
		beq	title_pic20
		cmpi.b	#$1a,d0
		beq	title_pic20
		cmpi.b	#' ',d0				*コントロールコードは削除
		bcs	title_pic10
		move.b	d0,(a1)+
		dbra	d1,title_pic10
title_pic20:
		clr.b	(a1)
		rts

*----------------------------------------
title_pi:
		lea	FILE_BUFF(a6),a0
		cmpi.b	#'P',(a0)+
		bne	title_pi20
		cmpi.b	#'i',(a0)+
		bne	title_pi20
		moveq	#72-1,d1
title_pi10:
		move.b	(a0)+,d0
		beq	title_pi20			*$00,$0d,$1aで終了
		cmpi.b	#$0d,d0
		beq	title_pi20
		cmpi.b	#$1a,d0
		beq	title_pi20
		cmpi.b	#' ',d0				*コントロールコードは削除
		bcs	title_pi10
		move.b	d0,(a1)+
		dbra	d1,title_pi10
title_pi20:
		clr.b	(a1)
		rts

*----------------------------------------
title_mag:
		lea	FILE_BUFF(a6),a0
		cmpi.l	#'MAKI',(a0)+
		bne	title_mag20
		cmpi.l	#'02  ',(a0)+
		bne	title_mag20
		moveq	#72-1,d1
title_mag10:
		move.b	(a0)+,d0
		beq	title_mag20			*$00,$0d,$1aで終了
		cmpi.b	#$0d,d0
		beq	title_mag20
		cmpi.b	#$1a,d0
		beq	title_mag20
		cmpi.b	#' ',d0				*コントロールコードは削除
		bcs	title_mag10
		move.b	d0,(a1)+
		dbra	d1,title_mag10
title_mag20:
		clr.b	(a1)
		rts


*----------------------------------------
title_jpg:
		lea	FILE_BUFF(a6),a0
		move.w	#1024-1,d2

title_jpg10:
		cmpi.b	#$ff,(a0)+		*画像開始コード(SOI:FFD8)を探す
		dbeq	d2,title_jpg10
		bne	title_jpg90
		subq.w	#1,d2
		bcs	title_jpg90
		cmpi.b	#$d8,(a0)+
		dbeq	d2,title_jpg10
		bne	title_jpg90
		subq.w	#1,d2
		bcs	title_jpg90
title_jpg11:
		move.b	(a0)+,d0		*コメントブロック(FFFE)を探す
		lsl.w	#8,d0
		move.b	(a0)+,d0
		cmpi.w	#$fffe,d0
		beq	title_jpg19
		move.b	(a0)+,d0
		lsl.w	#8,d0
		move.b	(a0)+,d0
		lea	-2(a0,d0.w),a0
		addq.w	#2,d0
		sub.w	d0,d2
		bcc	title_jpg11
		bra	title_jpg90
title_jpg19:

title_jpg20:
		move.b	(a0)+,d1		*みつかったらコメントをバッファにコピー
		lsl.w	#8,d1
		move.b	(a0)+,d1
		subq.w	#3,d1
		cmp.w	d2,d1
		bls	title_jpg21
		move.w	d2,d1
title_jpg21:
		cmpi.w	#72-1,d1
		bls	title_jpg23
		moveq	#72-1,d1
title_jpg23:
		move.b	(a0)+,d0
		beq	title_jpg90			*$00,$0d,$1aで終了
		cmpi.b	#$0d,d0
		beq	title_jpg90
		cmpi.b	#$1a,d0
		beq	title_jpg90
		cmpi.b	#' ',d0				*コントロールコードは削除
		bcs	title_jpg24
		move.b	d0,(a1)+
title_jpg24:
		dbra	d1,title_jpg23
title_jpg90:
		clr.b	(a1)
		rts


*==================================================
*ファイルバッファに1024バイト読み込む
*	a0.l <- ファイルネーム
*	d0.l -> 負ならエラー
*==================================================

READ_FILEBUFF:
		movem.l	d1,-(sp)

		clr.w	-(sp)		*オープン
		move.l	a0,-(sp)
		DOS	_OPEN
		addq.l	#6,sp
		move.l	d0,d1
		bmi	read_filebuff90

		move.l	#1024,-(sp)	*読み込み
		pea	FILE_BUFF(a6)
		move.w	d1,-(sp)
		DOS	_READ
		lea.l	10(sp),sp
		tst.l	d0
		bmi	read_filebuff90

		move.w	d1,-(sp)	*クローズ
		DOS	_CLOSE
		addq.l	#2,sp

read_filebuff90:
		movem.l	(sp)+,d1
		rts

*==================================================
*文字列コピー
*	COPY_STRING( dest, sour )
*==================================================

COPY_STRING:
		movem.l	a0-a1,-(sp)
		movem.l	12(sp),a0-a1
copy_string10:
		move.b	(a1)+,(a0)+
		bne	copy_string10
		movem.l	(sp)+,a0-a1
		rts

