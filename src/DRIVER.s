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

		.include	doscall.mac
		.include	MMDSP.h
		.include	DRIVER.h


*==================================================
* DRIVER テーブル
*==================================================

		.xref		MXDRV_ENTRY
		.xref		MADRV_ENTRY
		.xref		MLD_ENTRY
		.xref		RCD_ENTRY
		.xref		RCD3_ENTRY
		.xref		ZMUSIC_ENTRY
		.xref		MCDRV_ENTRY

driver_table:
		.dc.w	MXDRV_ENTRY-driver_table
		.dc.w	MADRV_ENTRY-driver_table
		.dc.w	MLD_ENTRY-driver_table
		.dc.w	RCD_ENTRY-driver_table
		.dc.w	RCD3_ENTRY-driver_table
		.dc.w	ZMUSIC_ENTRY-driver_table
		.dc.w	MCDRV_ENTRY-driver_table

*		新たなドライバに対応させる場合、ここに
*		エントリーテーブルのアドレスを追加する
		dc.w	0


*==================================================
* DRIVER 常駐チェック
*	常駐しているドライバをチェックする
*	DRV_MODE(a6) <- 指定ドライバ番号 (0なら自動選択)
*	d0.w -> ドライバ番号（０なら常駐していない）
*	参考: DRV_MODE(a6),DRV_ENTRY(a6)にも記録する
*==================================================

SEARCH_DRIVER:
		movem.l	d1,-(sp)
		move.w	DRV_MODE(a6),d0
		beq	search_driver10

		cmpi.w	#RCD,d0			*RCDモード指定の場合
		bne	search_driver01		*RCD3も探す
		moveq	#RCD3,d0
		bsr	check_driver
		bpl	search_driver30
		moveq	#RCD,d0
search_driver01:
		bsr	check_driver		*ドライバ指定がある場合
		bmi	search_driver90
		bra	search_driver30

search_driver10:
		moveq	#1,d1			*ドライバ自動選択の場合
search_driver20:
		move.w	d1,d0
		bsr	check_driver
		beq	search_driver90
		bpl	search_driver30
		addq.w	#1,d1
		bra	search_driver20
search_driver30:
		bsr	make_driverjmp
		movem.l	(sp)+,d1
		rts
search_driver90:
		moveq	#0,d0
		movem.l	(sp)+,d1
		rts

*ドライバ常駐チェック
*	d0.w <- ドライバ番号
*	d0.w -> ドライバ番号(負:常駐していない 0:全て調べ終わった)
*	a0.l -> ドライバエントリアドレス

check_driver:
		movem.l	d1/a1,-(sp)
		lea	driver_table(pc),a0
		move.w	d0,d1
		subq.w	#1,d0
		bmi	check_driver90
		add.w	d0,d0
		move.w	(a0,d0.w),d0
		beq	check_driver90
		lea	(a0,d0.w),a0
		move.w	(a0),d0
		jsr	(a0,d0.w)
		tst.l	d0
		bmi	check_driver90
		move.w	d1,d0
check_driver90:
		movem.l	(sp)+,d1/a1
		rts

*ドライバジャンプテーブル作成
*	d0.w <- ドライバ番号
*	a0.l <- ドライバエントリアドレス

make_driverjmp:
		movem.l	d0/a0-a2,-(sp)
		move.w	d0,DRV_MODE(a6)
		move.l	a0,DRV_ENTRY(a6)
		movea.l	a0,a2
		moveq	#DRIVER_CMDS-1,d1
		lea	DRIVER_JMPTBL(a6),a1
make_driverjmp10:
		moveq	#0,d0
		move.w	(a0)+,d0
		add.l	a2,d0
		move.l	d0,(a1)+
		dbra	d1,make_driverjmp10
		movem.l	(sp)+,d0/a0-a2
		rts


*==================================================
* DRIVER ステータス初期化
*	全てのトラックの変化ビットを立てる
*==================================================

STATUS_INIT:
		*次回のDRIVER_TRKSTATはrefresh_subを呼ぶ
		movem.l	d0-d1/a0-a1,-(sp)
		lea	DRIVER_JMPTBL+DRIVER_TRKSTAT*4(a6),a1
		move.l	(a1),REF_TRSTWORK(a6)
		lea	refresh_sub(pc),a0
		move.l	a0,(a1)

		lea	TRACK_STATUS+KEYONSTAT(a6),a0
		moveq	#0,d0
		moveq	#32-1,d1
status_init10:
		move.b	d0,(a0)
		lea	TRST(a0),a0
		dbra	d1,status_init10

		movem.l	(sp)+,d0-d1/a0-a1
		rts

refresh_sub:
		*本家のルーチンに戻す
		move.l	REF_TRSTWORK(a6),DRIVER_JMPTBL+DRIVER_TRKSTAT*4(a6)
		DRIVER	DRIVER_TRKSTAT

		movem.l	d0/d7/a0-a1,-(sp)
		lea	TRACK_STATUS(a6),a0
		lea	CHST_BF(a6),a1
		moveq	#32-1,d7
		moveq	#-1,d0
refresh_sub10:
		move.b	d0,STCHANGE(a0)
		move.b	d0,KEYONCHANGE(a0)
		move.b	d0,KEYCHANGE(a0)
		move.b	d0,VELCHANGE(a0)
*		move.w	d0,KBS_CHG(a1)
		lea	TRST(a0),a0
		lea	CHST(a1),a1
		dbra	d7,refresh_sub10
		move.l	d0,TRACK_CHANGE(a6)

		movem.l	(sp)+,d0/d7/a0-a1
		rts


*==================================================
* DRIVER キーオン初期化
*	全てのトラックをキーＯＦＦする
*==================================================

CLEAR_KEYON:
		*次回のDRIVER_TRKSTATはkeyoff_subを呼ぶ
		movem.l	a0-a1,-(sp)
		lea	DRIVER_JMPTBL+DRIVER_TRKSTAT*4(a6),a1
		move.l	(a1),CLR_KEYONWORK(a6)
		lea	keyoff_sub(pc),a0
		move.l	a0,(a1)
		movem.l	(sp)+,a0-a1
		rts

keyoff_sub:
		movem.l	d7/a0,-(sp)
		lea	TRACK_STATUS(a6),a0
		moveq	#32-1,d7
keyoff_sub10:
		clr.b	STCHANGE(a0)
		st.b	KEYONCHANGE(a0)
		st.b	KEYONSTAT(a0)
		clr.b	KEYCHANGE(a0)
		clr.b	VELCHANGE(a0)
		lea	TRST(a0),a0
		dbra	d7,keyoff_sub10

		move.l	#-1,TRACK_CHANGE(a6)
		clr.l	TRACK_ENABLE(a6)

		*本家のルーチンに戻す
		move.l	CLR_KEYONWORK(a6),DRIVER_JMPTBL+DRIVER_TRKSTAT*4(a6)

		movem.l	(sp)+,d7/a0
		rts


*==================================================
*トラックマスク
*==================================================

*１トラックマスク反転
*	d1.w <- トラック番号

TRMASK_CHG:
		movem.l	d0-d1,-(sp)
		DRIVER	DRIVER_GETMASK
		bchg.l	d1,d0
		move.l	d0,d1
		DRIVER	DRIVER_SETMASK
		movem.l	(sp)+,d0-d1
		rts

*全トラックＯＮ

TRMASK_ALLON:
		move.l	d1,-(sp)
		moveq	#-1,d1
		DRIVER	DRIVER_SETMASK
		move.l	(sp)+,d1
		rts

*全トラックＯＦＦ

TRMASK_ALLOFF:
		move.l	d1,-(sp)
		moveq	#0,d1
		DRIVER	DRIVER_SETMASK
		move.l	(sp)+,d1
		rts

*全トラック反転

TRMASK_ALLREV:
		movem.l	d0-d1,-(sp)
		DRIVER	DRIVER_GETMASK
		not.l	d0
		move.l	d0,d1
		DRIVER	DRIVER_SETMASK
		movem.l	(sp)+,d0-d1
		rts


*==================================================
*環境変数から探してオープンする
*	OPEN_FILE(char *name, char *env)
*	name	ファイル名
*	env	サーチパス環境変数名テーブル(0ならサーチしない)
*	d0.l -> ファイルハンドル(負ならエラー)
*==================================================

		.offset	-512
env_buff	.ds.b	256
open_buff	.ds.b	256
		.text

OPEN_FILE:
		movem.l	a0-a4,-(sp)
		movem.l	(5+1)*4(sp),a1-a2
		link	a6,#-512

		clr.w	-(sp)			*まずカレントを探す
		pea	(a1)
		DOS	_OPEN
		addq.l	#6,sp
		tst.l	d0
		bpl	open_file90

		move.l	a2,d0
		beq	open_file_err
open_file00:
		lea	dummy_form(pc),a3	*X68030対策(GETENV は cpRESTORE (a3)になる)
		pea	env_buff(a6)		*なければ、環境変数をサーチして
		clr.l	-(sp)
		pea	(a2)
		DOS	_GETENV
		lea	12(sp),sp
		tst.l	d0
		bmi	open_file_nextenv

		lea	env_buff(a6),a4
open_file10:
		tst.b	(a4)			*環境変数が終わるまで以下を繰り返す
		beq	open_file_nextenv
		lea	open_buff(a6),a3
open_file20:
		move.b	(a4),d0			*区切り文字( ,;| スペース タブ )
		beq	open_file30
		addq.l	#1,a4
		cmpi.b	#',',d0
		beq	open_file30
		cmpi.b	#';',d0
		beq	open_file30
		cmpi.b	#'|',d0
		beq	open_file30
		cmpi.b	#' ',d0
		beq	open_file30
		cmpi.b	#9,d0
		beq	open_file30
		move.b	d0,(a3)+		*がくるまで、パス名をコピー
		bra	open_file20
open_file30:
		move.b	-1(a4),d0		*パス名の最後が:か\でなかったら、
		cmpi.b	#':',d0
		beq	open_file40
		cmpi.b	#'\',d0	
		beq	open_file40
		move.b	#'\',(a3)+		*\を付け足す
open_file40:
		movea.l	a1,a0			*ファイル名を付け足して
open_file41:	move.b	(a0)+,(a3)+
		bne	open_file41

		pea	open_buff(a6)		*ディスクが入っていたら
		bsr	CHECK_DRIVE
		addq.l	#4,sp
		tst.l	d0
		bmi	open_file10

		clr.w	-(sp)			*オープンしてみる
		pea	open_buff(a6)
		DOS	_OPEN
		addq.l	#6,sp
		tst.l	d0
		bmi	open_file10
		bra	open_file90

open_file_nextenv:
		tst.b	(a2)+
		bne	open_file_nextenv
		tst.b	(a2)
		bne	open_file00

open_file_err:
		moveq	#-1,d0
open_file90:
		unlk	a6
		movem.l	(sp)+,a0-a4
		rts

dummy_form:	.dc.w	0


*==================================================
*ファイルをクローズする
*	CLOSE_FILE(short handle)
*	handle	ファイルハンドル(負ならクローズしない)
*	d0.l -> エラーコード
*==================================================

CLOSE_FILE:
		move.w	4(sp),d0
		ext.l	d0
		bmi	close_file90
		move.w	d0,-(sp)
		DOS	_CLOSE
		addq.l	#2,sp
close_file90:
		rts


*==================================================
*ディスクが入っているか調べる
*	CHECK_DRIVE(char *pathname)
*	pathname	アクセスしたいパス名
*	d0.l -> 負ならアクセス不可
*==================================================

CHECK_DRIVE:
		movea.l	4(sp),a0

		moveq	#0,d0			*ドライブ名がなければカレントを、
		cmpi.b	#':',1(a0)
		bne	check_drive10

		move.b	(a0),d0			*あればそのドライブを調べる
		andi.b	#$df,d0
		subi.b	#'A'-1,d0

check_drive10:
		move.w	d0,-(sp)
		DOS	_DRVCTRL
		addq.l	#2,sp
		btst.l	#2,d0
		sne	d0
		ext.w	d0
		ext.l	d0

		rts


*==================================================
*ファイルの長さを調べる
*	GET_FILELEN(short handle)
*	handle	ファイルハンドル
*	d0.l -> ファイルの長さ(負ならエラー)
*==================================================

GET_FILELEN:
		movem.l	d1-d2,-(sp)
		move.w	(2+1)*4(sp),d0
		link	a6,#0

		move.w	#1,-(sp)		*現在の位置を調べ
		clr.l	-(sp)
		move.w	d0,-(sp)
		DOS	_SEEK
		move.l	d0,d1
		bmi	get_filelen90

		move.w	#2,6(sp)		*ファイルの最後へ行って位置を調べる
		DOS	_SEEK
		move.l	d0,d2
		bmi	get_filelen90

		clr.w	6(sp)			*元の位置へもどる
		move.l	d1,2(sp)
		DOS	_SEEK
		tst.l	d0
		bmi	get_filelen90

		move.l	d2,d0
get_filelen90:
		unlk	a6
		movem.l	(sp)+,d1-d2
		rts


*==================================================
*ファイルを読む
*	READ_FILE(char *name, char *env, int ofst)
*	name	ファイル名
*	env	サーチパス環境変数名テーブル(0ならサーチしない)
*	ofst	バッファの先頭につけるヘッダの大きさ
*	d0.l -> 読み込んだ長さ(負ならエラー)
*		-1 ロードエラー
*		-2 メモリ不足
*	a0.l -> 読み込んだポインタ
*==================================================

READ_FILE:
		movem.l	d1-d3/a1-a3,-(sp)
		movem.l	(6+1)*4(sp),a1-a3
		link	a6,#0

		moveq	#-1,d2
		moveq	#-1,d3

		pea	(a2)			*ファイルをオープンする
		pea	(a1)
		bsr	OPEN_FILE
		move.l	d0,d1
		bmi	read_file_loaderr

		move.w	d1,-(sp)		*ファイルの長さを調べ
		bsr	GET_FILELEN
		move.l	d0,d2
		bmi	read_file_loaderr

		pea	(a3,d2.l)		*その分のメモリを確保する
		DOS	_MALLOC
		move.l	d0,d3
		bmi	read_file_memerr

		move.l	d2,-(sp)		*ファイルをメモリに読み込む
		pea	(a3,d3.l)
		move.w	d1,-(sp)
		DOS	_READ
		cmp.l	d2,d0
		blt	read_file_loaderr
		bra	read_file90

read_file_memerr:
		move.l	d3,-(sp)
		bsr	FREE_MEM
		moveq	#-1,d3
		moveq	#-2,d2
		bra	read_file90

read_file_loaderr:
		move.l	d3,-(sp)
		bsr	FREE_MEM
		moveq	#-1,d3
		moveq	#-1,d2

read_file90:
		move.w	d1,-(sp)
		bsr	CLOSE_FILE

		move.l	d2,d0
		movea.l	d3,a0
		unlk	a6
		movem.l	(sp)+,d1-d3/a1-a3
		rts


*==================================================
*拡張子がなければ、デフォルトを付加する
*	ADD_EXT(char *name, char *ext)
*	name	ファイル名
*	ext	デフォルト拡張子
*	d0.l -> エラーコード
*==================================================

		.offset -92
nameckbuf	.ds.b	92
		.text

ADD_EXT:
		movem.l	a0-a1,-(sp)
		movem.l	(2+1)*4(sp),a0-a1
		link	a6,#-92

		pea	nameckbuf(a6)			*ファイル名を調べ
		pea	(a0)
		DOS	_NAMECK
		tst.l	d0
		bmi	add_ext90

		tst.b	nameckbuf+86(a6)		*拡張子がなければ
		bne	add_ext90

add_ext10:
		tst.b	(a0)+				*デフォルトを追加する
		bne	add_ext10
		subq.l	#1,a0
add_ext20:
		move.b	(a1)+,(a0)+
		bne	add_ext20

add_ext90:
		unlk	a6
		movem.l	(sp)+,a0-a1
		rts


*==================================================
*大文字/小文字の区別なしに文字列を比較する
*	STRCMPI(char *str1, char *str2)
*	d0.l -> 一致したら0
*==================================================

STRCMPI:
		movem.l	d1/a0-a1,-(sp)
		movem.l	(3+1)*4(sp),a0-a1

		moveq	#0,d0
strcmpi10:
		move.b	(a0)+,d0
		beq	strcmpi20
		andi.b	#$df,d0
		move.b	(a1)+,d1
		andi.b	#$df,d1
		sub.b	d1,d0
		beq	strcmpi10
		bra	strcmpi90

strcmpi20:
		move.b	(a1),d0

strcmpi90:
		movem.l	(sp)+,d1/a0-a1
		rts


*==================================================
*メモリを開放する
*	FREE_MEM(void *ptr)
*	ptr	メモリブロックへのポインタ(負なら開放しない)
*	d0.l -> エラーコード
*==================================================

FREE_MEM:
		move.l	4(sp),d0
		bmi	free_mem90
		move.l	d0,-(sp)
		DOS	_MFREE
		addq.l	#4,sp
free_mem90:
		rts


*==================================================
*ＺＤＦデータの使用を開始する
*	OPEN_ZDF(char *zdf, char *buf)
*	zdf	zdfファイルのロードされているアドレス
*	buf	内容が展開されるバッファ(54bytes)
*	d0.l -> lzzがロードされたアドレス(負ならエラー)
*==================================================

OPEN_ZDF:
		movem.l	d1/a0-a2,-(sp)
		movem.l	(4+1)*4(sp),a0-a1
		link	a6,#0

		moveq	#-1,d1			*LZZロードポインタ初期化

		cmpi.l	#'ZDF0',(a0)		*ZDFファイルかどうかチェックする
		bne	open_zdf_err
		cmpi.w	#$0d0a,4(a0)
		bne	open_zdf_err

		bsr	LOAD_LZZ		*LZZをロードして
		move.l	d0,d1
		bmi	open_zdf_err

		pea	(a1)			* ref_data を呼び出す
		pea	(a0)
		movea.l	d1,a2
		jsr	_ref_data(a2)
		addq.l	#8,sp
		tst.l	d0
		bmi	open_zdf90
		move.l	d1,d0
		bra	open_zdf90

open_zdf_err:
		move.l	d1,-(sp)		*エラーならLZZを開放する
		bsr	FREE_MEM
		moveq	#-1,d0

open_zdf90:
		unlk	a6
		movem.l	(sp)+,d1/a0-a2
		rts


*==================================================
*ＺＤＦデータを展開する
*	EXTRACT_ZDF(void *lzz, char *zdfdata, int len, int ofst)
*	lzz	lzzがロードされているアドレス
*	zdfdata	データ先頭アドレス
*	len	展開後のサイズ
*	ofst	バッファの先頭につけるヘッダの大きさ
*	d0.l -> 展開したバッファのアドレス(負ならエラー)
*==================================================

EXTRACT_ZDF:
		movem.l	d1/a0-a3,-(sp)
		movem.l	(5+1)*4(sp),a0-a3
		link	a6,#0

		pea	(a2,a3.l)		* 展開用バッファ確保
		DOS	_MALLOC
		move.l	d0,d1
		bmi	extract_zdf_err

		pea	(a3,d1.l)		* ext_data 呼び出し
		pea	(a1)
		jsr	_ext_data(a0)
		addq.l	#8,sp
		tst.l	d0
		bmi	extract_zdf90
		move.l	d1,d0
		bra	extract_zdf90

extract_zdf_err:
		move.l	d1,-(sp)
		bsr	FREE_MEM
		moveq	#-1,d0

extract_zdf90:
		unlk	a6
		movem.l	(sp)+,d1/a0-a3
		rts


*==================================================
*ＬＺＺをロードする
*	d0.l -> ロードしたアドレス(負ならエラー)
*==================================================

		.offset -512
nambuf		.ds.b	256
cmdlin		.ds.b	256
		.text

LOAD_LZZ:
		movem.l	d1-d2/a0,-(sp)
		link	a6,#-512

		moveq	#-1,d2			*バッファポインタ初期化

		lea	LzzName(pc),a0		*LZZか
		bsr	load_lzzsub
		bpl	load_lzz10

		lea	LzmName(pc),a0		*LZMを探す
		bsr	load_lzzsub
		bmi	load_lzz90

load_lzz10:
		pea	$ffff.w			*最大限メモリ確保して
		DOS	_MALLOC
		andi.l	#$00ffffff,d0
		move.l	d0,d1
		move.l	d0,(sp)
		DOS	_MALLOC
		move.l	d0,d2
		bmi	load_lzz_err

		add.l	d2,d1			*ロードする
		move.l	d1,-(sp)
		move.l	d2,-(sp)
		pea	nambuf(a6)
		move.b	#1,(sp)			*.rタイプ指定
		move.w	#3,-(sp)
		DOS	_EXEC
		tst.l	d0
		bmi	load_lzz_err

		movea.l	d2,a0
		cmpi.l	#'LzzR',_LzzCheck(a0)	* 本当にlzzかチェックする
		bne	load_lzz_err

		move.l	_LzzSize(a0),-(sp)	* メモリブロックを必要な大きさに縮小する
		pea	(a0)
		DOS	_SETBLOCK

		move.l	d2,d0
		bra	load_lzz90

load_lzz_err:
		move.l	d2,-(sp)
		bsr	FREE_MEM
		moveq	#-1,d0

load_lzz90:
		unlk	a6
		movem.l	(sp)+,d1-d2/a0
		rts


*パス検索
*	a0.l <- 起動ファイル名
*	d0.l -> 負ならエラー

load_lzzsub:
		movem.l	a0-a1,-(sp)
		lea	nambuf(a6),a1		* 起動ファイル名をコピー
load_lzzsub10:
		move.b	(a0)+,(a1)+
		bne	load_lzzsub10

		clr.l	-(sp)			* パス検索
		pea	cmdlin(a6)
		pea	nambuf(a6)
		move.w	#2,-(sp)
		DOS	_EXEC
		lea	14(sp),sp
		tst.l	d0
		movem.l	(sp)+,a0-a1
		rts

		.data
LzzName:	.dc.b	'lzz.r',0
LzmName:	.dc.b	'lzm.r',0
		.text


*********************************************************************
*
*
*	ＴＤＸローダー
*
*
*	A1:	PDXデータバッファ（あるいは展開先への）ポインタ
*	A2:	TDXデータポインタ
*	D1:	PDX展開先の大きさ
*	D2:	TDXデータ長
*
*	RETURN	D0.L=0	*PCMデータ編成に成功
*		  負数	*編成に失敗した
*
		.offset	-($300+30)
TDX_ALLOCPTR	DS.L	1	*TDXデータへのポインタ
TDX_ALLOCLEN	DS.L	1	*TDXデータの長さ
MAXBANK		DS.W	1	*最大バンクページ
CURBANK		DS.W	1	*現在のバンクページ
CURHEAD		DS.L	1	*現在のバンクオフセット
PCM_ALLOCPTR	DS.L	1	*PCMデータロード先
PCM_ALLOCLEN	DS.L	1	*PCMバッファ残り容量
PCM_HEADPTR	DS.L	1	*PCMヘッダエリアポインタ
NOW_PCMFILE	DS.W	1	*現在オープンしているPDXファイルのハンドル
PDXBLOCK	DS.B	$300	*PDXファイル・ヘッダブロック
		.text

TDX_LOAD:
	MOVEM.L	D1-D7/A0-A6,-(SP)
	link	a6,#-($300+30)
	MOVE.L	A2,TDX_ALLOCPTR(A6)
	MOVE.L	D2,TDX_ALLOCLEN(A6)
	MOVE.L	A1,PCM_HEADPTR(A6)
	MOVE.L	A1,PCM_ALLOCPTR(A6)
	MOVE.L	D1,PCM_ALLOCLEN(A6)
	CLR.W	CURBANK(A6)
	CLR.L	CURHEAD(A6)
	MOVE.W	#-1,NOW_PCMFILE(A6)
*
*
*	#で始まる行を見つける迄、ブランキングを行なう。
*
*
TDX_LOADINIT:
	BSR	GETLINE			*１行取り出し A0=ポインタ	D0=フラグ
	TST.L	D0
	BMI	TDX_ERROR1		*初期化文字列を見つけられないままファイルが終わった
	BSR	SKIPBRANK		*ブランク文字列除去
	CMP.B	#"#",(A0)+
	BNE	TDX_LOADINIT
	BSR	SKIPBRANK		*ブランク文字列除去
	BSR	TDXGETNUM		*バンク数取り出し
	MOVE.W	D0,D1
	MULU	#$300,D1
	BEQ	TDX_ERROR2		*確保する意味がない
	SUB.L	D1,PCM_ALLOCLEN(A6)	*ヘッダ用にメモリを減らす
	BCS	TDX_ERROR2		*メモリ不足が発生した
	ADD.L	D1,PCM_ALLOCPTR(A6)	*アロケーションバッファを確保
	MOVE.W	D0,MAXBANK(A6)		*最大バンク数設定

	MOVE.L	PCM_HEADPTR(A6),A0	*バンク領域をクリアする
	LSR.L	#6,D1
	SUB.L	#1,D1
TDX_LOADINIT0:
	CLR.L	(A0)+
	CLR.L	(A0)+
	CLR.L	(A0)+
	CLR.L	(A0)+
	CLR.L	(A0)+
	CLR.L	(A0)+
	CLR.L	(A0)+
	CLR.L	(A0)+
	CLR.L	(A0)+
	CLR.L	(A0)+
	CLR.L	(A0)+
	CLR.L	(A0)+
	CLR.L	(A0)+
	CLR.L	(A0)+
	CLR.L	(A0)+
	CLR.L	(A0)+
	SUBQ.L	#1,D1
	BCC	TDX_LOADINIT0
TDX_LOADMAIN:
	BSR	GETLINE		*１行取り出す
	TST.L	D0
	BMI	TDX_LOADQUIT	*ロード終了
	BSR	SKIPBRANK	*ブランク文字を飛ばす
	MOVE.B	(A0),D0
	BEQ	TDX_LOADMAIN	*空行
	CMP.B	#"+",D0
	BEQ	PDX_FILEOPEN	*PDXファイルオープン指示
	CMP.B	#"@",D0
	BEQ	PDX_BANKSELECT	*ストア・バンクセレクト
	CMP.B	#"*",D0
	BEQ	PDX_TARGETBANK	*ターゲットバンク指定
	CMP.B	#";",D0
	BEQ	TDX_LOADMAIN	*コメント行
	CMP.B	#"&",D0
	BEQ	PDX_MULTIASSIGN	*マルチアサイン
	CMP.B	#"N",D0
	BEQ	PDX_KEY		*数値でロードする
	CMP.B	#"n",D0
	BEQ	PDX_KEY		*数値でロードする
	CMP.B	#"A",D0
	BCS	TDX_ERROR3	*シンタックスエラー
	CMP.B	#"G"+1,D0
	BCS	PDX_KEY		*アルファベットでロードする
	CMP.B	#"a",D0
	BCS	TDX_ERROR3	*シンタックスエラー
	CMP.B	#"g"+1,D0
	BCS	PDX_KEY		*アルファベット指定でロードする
	BRA	TDX_ERROR3	*シンタックスエラー
*
*	１行取り出して、そのポインタを帰す
*
GETLINE:
	MOVE.L	TDX_ALLOCPTR(A6),A0	*該当行
*	MOVE.L	A0,REPORT_WORK
*
*	スキップ処理
*
	PEA	(A1)
	MOVE.L	A0,A1
GETLINE_SKIP:
	SUBQ.L	#1,TDX_ALLOCLEN(A6)
	BMI	GETLINE_EOF		*ファイルの終わりまで読み出した(bcs -> bmi)
	TST.B	(A1)
	BEQ	GETLINE_EOF		*NULがあったらEOF処理
	CMP.B	#$0D,(A1)+
	BNE	GETLINE_SKIP
	CLR.B	-1(A1)			*$0Dがあった場所をNULにする
	ADDQ.W	#1,A1
	MOVE.L	A1,TDX_ALLOCPTR(A6)	*読み出した位置を登録しておく
	SUBQ.L	#1,TDX_ALLOCLEN(A6)	*(added)
	MOVE.L	(SP)+,A1
	MOVEQ.L	#0,D0
	RTS
GETLINE_EOF:
	MOVEQ.L	#-1,D0
	MOVE.L	(SP)+,A1
	RTS
*
*	ブランク文字のスキップ
*
SKIPBRANK:
	CMP.B	#" ",(A0)
	BEQ	SKIPBRANK1		*ブランクする
	CMP.B	#9,(A0)
	BEQ	SKIPBRANK1		*ブランクする
	RTS
SKIPBRANK1:
	ADDQ.W	#1,A0
	BRA	SKIPBRANK
*
*	数値を取り出す
*
*	数値=D0
*
TDXGETNUM:
	MOVEM.L	D1-D7/A1-A6,-(SP)
	MOVEQ.L	#0,D1
	MOVEQ.L	#0,D0
TDXGETNUM0:
	MOVE.B	(A0)+,D0
	SUB.B	#"0",D0
	BCS	TDXGETNUM_QUIT
	CMP.B	#9+1,D0
	BCC	TDXGETNUM_QUIT
	ADD.L	D1,D1	*2
	MOVE.L	D1,D2
	ADD.L	D1,D1	*4
	ADD.L	D1,D1	*8
	ADD.L	D2,D1	*10
	ADD.L	D0,D1
	BRA	TDXGETNUM0
TDXGETNUM_QUIT:
	MOVE.L	D1,D0
	MOVEM.L	(SP)+,D1-D7/A1-A6
	RTS
*
*	PDXファイル・オープン処理
*
PDX_FILEOPEN
	TST.W	NOW_PCMFILE(A6)
	BMI	PDX_FILEOPEN1
	MOVE.W	NOW_PCMFILE(A6),-(SP)	*前のファイルはクローズする
	DOS	_CLOSE
	ADDQ.W	#2,SP
PDX_FILEOPEN1:
	ADDQ.W	#1,A0
	BSR	SKIPBRANK		*ブランク文字をスキップする

*	PEA	(A1)
*	LEA	EXT2(PC),A1
*	BSR	FILE_SEARCH
*	MOVE.L	(SP)+,A1

*
	movem.l	a0-a1,-(sp)
	link	a6,#-128
	lea	-128(a6),a1
pdx_fileopen2:
	move.b	(a0)+,(a1)+
	bne	pdx_fileopen2
	pea	EXT2(pc)
	pea	-128(a6)
	bsr	ADD_EXT
	pea	env_MADRV(pc)
	pea	-128(a6)
	bsr	OPEN_FILE
	unlk	a6
	movem.l	(sp)+,a0-a1
*

	TST.L	D0
	BMI	TDX_ERROR4		*ファイルがみつからない

	MOVE.W	D0,NOW_PCMFILE(A6)	*ファイルハンドル登録
	MOVE.L	#$300,-(SP)		*手始めにバンク０を読み出しておく
	PEA	PDXBLOCK(A6)
	MOVE.W	D0,-(SP)
	DOS	_READ
	LEA	10(SP),SP
	TST.L	D0
	BMI	TDX_ERROR5		*PCMファイル読み出しエラー
	BRA	TDX_LOADMAIN
*
*	ターゲットバンク変更
*
PDX_TARGETBANK:
	TST.W	NOW_PCMFILE(A6)
	BMI	TDX_ERROR6		*ファイルオープンしていない
	ADDQ.W	#1,A0
	BSR	SKIPBRANK
	BSR	TDXGETNUM		*バンク番号を取り出す

	MULU	#$300,D0
	CLR.W	-(SP)
	MOVE.L	D0,-(SP)
	MOVE.W	NOW_PCMFILE(A6),-(SP)
	DOS	_SEEK
	ADDQ.W	#8,SP
	TST.L	D0
	BMI	TDX_ERROR5		*シークエラー

	MOVE.L	#$300,-(SP)		*該当バンクを読み出しておく
	PEA	PDXBLOCK(A6)
	MOVE.W	NOW_PCMFILE(A6),-(SP)
	DOS	_READ
	LEA	10(SP),SP
	TST.L	D0
	BMI	TDX_ERROR5		*PCMファイル読み出しエラー
	BRA	TDX_LOADMAIN
*
*	ストアバンク・変更
*
PDX_BANKSELECT:
	ADDQ.W	#1,A0
	BSR	SKIPBRANK
	BSR	TDXGETNUM		*PDXバンク取り出し
	CMP.W	MAXBANK(A6),D0
	BPL	TDX_ERROR6		*最大バンク数を超えた
PDX_BANKSELECT1:
	MOVE.W	D0,CURBANK(A6)		*バンク番号設定
	MULU	#$300,D0
	MOVE.L	D0,CURHEAD(A6)		*バンクオフセット設定
	BRA	TDX_LOADMAIN
*
*	任意キーをロードして処理する
*
PDX_KEY:
	BSR	GETKEYCODE
	TST.L	D0
	BMI	TDX_ERROR7		*キー範囲が異常
	MOVE.W	D0,D7			*D7=ストアすべきキー番号
	BSR	SKIPBRANK
	CMP.B	#"=",(A0)+
	BNE	TDX_ERROR3		*構文異常
	BSR	SKIPBRANK
	BSR	GETKEYCODE		*読み出し先のキー番号取り出し
	TST.L	D0
	BMI	TDX_ERROR7		*キー番号異常
	MOVE.W	D0,D6			*読み出したいキーの番号

	TST.W	NOW_PCMFILE(A6)
	BMI	TDX_ERROR6		*まだファイルオープンしていない

	ADD.W	D0,D0			*word
	ADD.W	D0,D0			*longword
	ADD.W	D0,D0			*longword×2

	LEA	PDXBLOCK(A6),A1
	ADD.W	D0,A1
	MOVE.L	(A1)+,D1		*D1=ファイルオフセット
	MOVE.L	(A1)+,D2		*D2=データ長
	BEQ	TDX_ERROR8		*PCMデータが存在しない

	SUB.L	D2,PCM_ALLOCLEN(A6)
	BCS	TDX_ERROR2		*メモリが不足する

	CLR.W	-(SP)			*指定のPCM位置へシークする
	MOVE.L	D1,-(SP)
	MOVE.W	NOW_PCMFILE(A6),-(SP)
	DOS	_SEEK
	ADDQ.W	#8,SP
	CMP.L	D1,D0
	BNE	TDX_ERROR5		*シークエラー

	MOVE.L	D2,-(SP)		*データ長
	MOVE.L	PCM_ALLOCPTR(A6),-(SP)	*ロード位置
	MOVE.W	NOW_PCMFILE(A6),-(SP)
	DOS	_READ
	LEA	10(SP),SP

	CMP.L	D2,D0
	BNE	TDX_ERROR5		*実際に読み出した長さと違う
	MOVE.L	PCM_ALLOCPTR(A6),D3	*メモリにストアした位置
	SUB.L	PCM_HEADPTR(A6),D3
	BMI	TDX_ERROR2		*まずありえないが・・

	ADD.L	D2,PCM_ALLOCPTR(A6)	*ポインタを進める

	MOVE.L	PCM_HEADPTR(A6),A0
	ADD.L	CURHEAD(A6),A0		*バンク先頭アドレス

	ADD.W	D7,D7
	ADD.W	D7,D7
	ADD.W	D7,D7

	TST.L	(A0,D7.W)
	BNE	TDX_ERROR9		*２重定義
	TST.L	4(A0,D7.W)
	BNE	TDX_ERROR9

	MOVE.L	D3,(A0,D7.W)		*データポインタ
	MOVE.L	D2,4(A0,D7.W)		*データ長
	BRA	TDX_LOADMAIN
*
*	既にロード済みのバンクから再アサインを行なう
*
PDX_MULTIASSIGN:
	BSR	GETKEYCODE
	TST.L	D0
	BMI	TDX_ERROR7		*キー範囲が異常
	MOVE.W	D0,D7			*D7=ストアすべきキー番号
	BSR	SKIPBRANK
	CMP.B	#"=",(A0)+
	BNE	TDX_ERROR3		*構文異常
	BSR	SKIPBRANK
	BSR	TDXGETNUM
	MOVE.W	D0,D5			*ターゲットバンク番号
	BSR	SKIPBRANK
	BSR	GETKEYCODE		*読み出し先のキー番号取り出し
	TST.L	D0
	BMI	TDX_ERROR7		*キー番号異常
	MOVE.W	D0,D6			*読み出したいキーの番号

	MOVE.L	PCM_HEADPTR(A6),A0
	ADD.L	CURHEAD(A6),A0		*バンク先頭アドレス
	ADD.W	D7,D7
	ADD.W	D7,D7
	ADD.W	D7,D7

	MOVE.L	PCM_HEADPTR(A6),A1
	CMP.W	MAXBANK(A6),D5
	BPL	TDX_ERROR6		*最大バンク数を超えた
PDX_MULTI0:
	MULU	#$300,D5
	ADD.L	D5,A1			*バンク先頭アドレス
	ADD.W	D6,D6
	ADD.W	D6,D6
	ADD.W	D6,D6

	TST.L	(A0,D7.W)
	BNE	TDX_ERROR9		*２重定義
	TST.L	4(A0,D7.W)
	BNE	TDX_ERROR9

	TST.L	(A0,D6.W)
	BEQ	TDX_ERROR8		*データが存在しない
	TST.L	4(A0,D6.W)
	BEQ	TDX_ERROR8

	MOVE.L	(A0,D6.W),(A0,D7.W)
	MOVE.L	4(A0,D6.W),4(A0,D7.W)
	BRA	TDX_LOADMAIN

ERROR	MACRO
	ENDM

TDX_ERROR1:
	ERROR	EM1
	MOVEQ.L	#-1,D0
	BRA	TDX_LOADFINAL		*初期化文字列がない
TDX_ERROR2:
	ERROR	EM2
	MOVEQ.L	#-2,D0
	BRA	TDX_LOADFINAL		*メモリが不足している
TDX_ERROR3:
	ERROR	EM3
	MOVEQ.L	#-3,D0
	BRA	TDX_LOADFINAL		*構文がおかしい
TDX_ERROR4:
	ERROR	EM4
	MOVEQ.L	#-4,D0
	BRA	TDX_LOADFINAL		*ファイルがみつからない
TDX_ERROR5:
	ERROR	EM5
	MOVEQ.L	#-5,D0
	BRA	TDX_LOADFINAL		*ファイルを読み出す時エラーがおきた
TDX_ERROR6:
	ERROR	EM6
	MOVEQ.L	#-6,D0
	BRA	TDX_LOADFINAL		*ファイルを指定していない
TDX_ERROR7:
	ERROR	EM7
	MOVEQ.L	#-7,D0
	BRA	TDX_LOADFINAL		*不当な音階を指定した
TDX_ERROR8:
	ERROR	EM8
	MOVEQ.L	#-8,D0
	BRA	TDX_LOADFINAL		*存在しないPCMデータにアクセスした
TDX_ERROR9:
	ERROR	EM9
	MOVEQ.L	#-9,D0
	BRA	TDX_LOADFINAL		*２重定義を行なった

TDX_LOADQUIT:
	MOVEQ.L	#0,D0
TDX_LOADFINAL:
	unlk	a6
	MOVEM.L	(SP)+,D1-D7/A0-A6
	RTS
*
*	キーコードを取り出す
*
GETKEYCODE:
	CLR.W	D0
	MOVE.B	(A0)+,D0
	ANDI.B	#$DF,D0
	CMP.B	#"N",D0
	BEQ	NUM_KEYCODE
	CMP.B	#"A",D0
	BCS	KEYCODE_ERROR		*音程ではない
	CMP.B	#"G"+1,D0
	BCS	ALPHA_KEYCODE
KEYCODE_ERROR:
	MOVEQ.L	#-1,D0
	RTS
NUM_KEYCODE:
	BSR	SKIPBRANK
	BSR	TDXGETNUM			*数値として音程を取り出す
	TST.W	D0
	BMI	KEYCODE_ERROR
	CMP.W	#96,D0
	BPL	KEYCODE_ERROR
	RTS
KEYCODE_TBL:	*AB  C D E F G
	DC.B	9,11,0,2,4,5,7
	EVEN
ALPHA_KEYCODE:
	CLR.W	D1
	SUB.B	#"A",D0
	MOVE.B	KEYCODE_TBL(PC,D0.W),D1		*音程コードベース(1)
	BSR	SKIPBRANK
	CMP.B	#"+",(A0)
	BEQ	ADAPTIVE_PLUSE
	CMP.B	#"-",(A0)
	BEQ	ADAPTIVE_MINUSE
	BRA	ADAPTIVE_OCTABE
ADAPTIVE_PLUSE:
	ADDQ.W	#1,D1
	ADDQ.W	#1,A0
	BRA	ADAPTIVE_OCTABE
ADAPTIVE_MINUSE:
	SUBQ.W	#1,D1
	ADDQ.W	#1,A0
ADAPTIVE_OCTABE:
	BSR	SKIPBRANK
	BSR	TDXGETNUM
	MULU	#12,D0
	ADD.W	D1,D0
	SUBQ.W	#4,D0
	BCS	KEYCODE_ERROR
	CMP.W	#96,D0
	BPL	KEYCODE_ERROR
	RTS


		.data
EXT2:
		.dc.b	'.PDX',0
env_MADRV:
		.dc.b	'MADRV',0
		.dc.b	'mxp',0,0
		.text

*==================================================
*ファイルを演奏する
*	a0.l <- ファイル名
*	d0.l -> 負ならエラー
*==================================================

PLAY_FILE:
		movem.l	d1-d2/a0-a1,-(sp)
		link	a5,#-96
		movea.l	a0,a1

		pea	-96(a5)			*ファイル名の拡張子部分を取り出して
		move.l	a1,-(sp)
		DOS	_NAMECK
		addq.l	#8,sp
		tst.l	d0
		bne	play_file90
		move.l	-96+86(a5),d1
		andi.l	#$00dfdfdf,d1

		DRIVER	DRIVER_FILEEXT		*拡張子識別コードを調べて
		movea.l	d0,a0
play_file10:
		moveq	#0,d0
		move.b	(a0),d0
		beq	play_file90
		move.l	(a0)+,d2
		andi.l	#$00dfdfdf,d2
		cmp.l	d2,d1
		bne	play_file10

		DRIVER	DRIVER_FLOADP		*演奏する
		bra	play_file99

play_file90:
		moveq	#-1,d0
play_file99:
		unlk	a5
		movem.l	(sp)+,d1-d2/a0-a1
		rts


*==================================================
* プレイヤー呼び出し
*	a0.l <- コマンド名
*	a1.l <- パラメータ
*	d0.l -> 終了コード、負ならエラー
*==================================================

nambuf		=	-512
cmdlin		=	-256

CALL_PLAYER:
		link	a5,#-512
		movem.l	d1-d7/a0-a6,-(sp)
		lea	nambuf(a5),a2
		move.w	#254-1,d0
call_player10:
		move.b	(a0)+,(a2)+		*起動ファイル名をローカルエリアにコピー
		dbeq	d0,call_player10
		bne	call_player80
		move.b	#' ',-1(a2)
call_player20:
		move.b	(a1)+,(a2)+		*パラメータをコピー
		dbeq	d0,call_player20
		bne	call_player80
		clr.b	(a2)
		clr.l	-(sp)			*自分と同じ環境で、
		pea.l	cmdlin(a5)
		pea.l	nambuf(a5)
		move.w	#2,-(sp)		*パスの検索
		DOS	_EXEC
		tst.l	d0
		bmi	call_player70
		clr.w	(sp)			*ロード＆実行
		st.b	CHILD_FLAG(a6)
		DOS	_EXEC
call_player70:	lea	14(sp),sp
		bra	call_player90
call_player80:
		moveq	#-1,d0			*コマンドラインが長過ぎた場合
call_player90:
		movem.l	(sp)+,d1-d7/a0-a6
		clr.b	CHILD_FLAG(a6)
		unlk	a5
		rts


*==================================================
*エラーメッセージ取得
*	d0.w <- エラーメッセージ番号(1～)
*	a0.l <- プレーヤ名
*	a0.l -> エラーメッセージ
*==================================================

GET_PLAYERRMES:
		movem.l	d0/a1-a2,-(sp)
		subq.w	#1,d0
		cmpi.w	#MAXERRMES,d0
		bls	get_playerrmes00
		move.w	#1,d0
get_playerrmes00:
		lea	PLAY_ERRORMES(pc),a1
		lea	FILE_BUFF(a6),a2		*FILE_BUFFを一時的に使う
		bra	get_playerrmes19
get_playerrmes10:					*指定番号のメッセージを探して、
		tst.b	(a1)+
		bne	get_playerrmes10
get_playerrmes19:
		dbra	d0,get_playerrmes10

get_playerrmes20:
		move.b	(a0)+,(a2)+			*頭にプレーヤ名をコピーして、
		bne	get_playerrmes20
		move.b	#':',-1(a2)
		move.b	#' ',(a2)+

get_playerrmes30:
		cmpi.b	#'%',(a1)
		bne	get_playerrmes39
		addq.l	#1,a1
		move.b	(a1)+,d0
get_playerrmesD:
		cmpi.b	#'D',d0				*先頭の%Dをドライバ名に、
		bne	get_playerrmesP
		move.l	a0,-(sp)
		DRIVER	DRIVER_NAME
		move.l	d0,a0
get_playerrmesD1:
		move.b	(a0)+,(a2)+
		bne	get_playerrmesD1
		subq.l	#1,a2
		move.l	(sp)+,a0
		bra	get_playerrmes39
get_playerrmesP:
		cmpi.b	#'P',d0				*%Pをプレーヤ名に置換する
		bne	get_playerrmes39
		move.b	#' ',-2(a2)
		subq.l	#1,a2
get_playerrmes39:

get_playerrmes40:
		move.b	(a1)+,(a2)+			*メッセージをコピー
		bne	get_playerrmes40

		lea	FILE_BUFF(a6),a0		*FILE_BUFFを返す
get_playerrmes90:
		movem.l	(sp)+,d0/a1-a2
		rts


*==================================================
* Ｖコマンドの＠ｖ値
*==================================================

		.data
VOL_DEFALT:	.dc.b	$55,$57,$5A,$5D,$5F,$62,$65,$67
		.dc.b	$6A,$6D,$6F,$72,$75,$77,$7A,$7D
		.text


*==================================================
* エラーメッセージ
*==================================================

PLAY_ERRORMES:
no01:		.dc.b	'エラーが発生しました',0
no02:		.dc.b	'曲データがロードできません',0
no03:		.dc.b	'PCM データがロードできません',0
no04:		.dc.b	'音色定義データがロードできません',0
no05:		.dc.b	'メモリが足りません',0
no06:		.dc.b	'%D のバージョンが違います',0
no07:		.dc.b	'%D のトラックバッファが足りません',0
no08:		.dc.b	'%D の PCM バッファが足りません',0
no09:		.dc.b	'%D のワーク不足の可能性があります',0
no10:		.dc.b	'異常なデータです',0
no11:		.dc.b	'PCM データが異常です',0
no12:		.dc.b	'%P が見つかりません',0
no13:		.dc.b	'MIDI ボードがありません',0
no14:		.dc.b	'コンバートに失敗しました',0
no15:		.dc.b	'LZM.x(LZZ.r) が見つかりません',0
no16:		.dc.b	'LZZ.r が見つかりません',0
no17:		.dc.b	'LZZ で展開に失敗しました',0
no18:		.dc.b	'コンバータ (??toZ.x) が見つかりません',0
no19:		.dc.b	'データの種類が違います',0
no20:		.dc.b	'%D でエラーが発生しました',0
no21:		.dc.b	'コンバート中に異常なコードを発見しました',0
no22:		.dc.b	'書き込みできません',0
no23:		.dc.b	'ファイルが作れません',0
no24:		.dc.b	'内部バッファが不足です',0
no25:		.dc.b	'RC のコンバータでエラーが発生しました',0
no26:		.dc.b	'RC のコンバータ(?toR.x)がありません',0
no27:		.dc.b	'Human のバージョンが低過ぎます',0
MAXERRMES	equ	27
MMDSP_NAME:	.dc.b	'MMDSP',0

		.even

		.end

--------------------------------------------------------------------------------
・ＤＲＩＶＥＲ処理関数の作成方法について

  まず、ドライバ処理関数のソースに次のようなテーブルを定義し、DRIVER.o
から参照できるようにしておく。

FUNC		.macro	entry
		.dc.w	entry-RCD_ENTRY
		.endm

		.xdef	RCD_ENTRY

RCD_ENTRY:
		FUNC	RCD_CHECK		*常駐チェック
		FUNC	RCD_NAME		*ドライバ名取得
		FUNC	RCD_INIT		*初期化
		FUNC	RCD_GETSTAT		*ステータス取得
		FUNC	RCD_TRKSTAT		*トラック情報取得
		FUNC	RCD_GETMASK		*演奏トラック取得
		FUNC	RCD_SETMASK		*演奏トラック設定
		FUNC	RCD_FILEEXT		*拡張子テーブル取得
		FUNC	RCD_FLOADP		*データファイルロード＆演奏開始
		FUNC	RCD_PLAY		*演奏開始
		FUNC	RCD_PAUSE		*演奏一時停止
		FUNC	RCD_CONT		*演奏再開
		FUNC	RCD_STOP		*演奏終了
		FUNC	RCD_FADE		*フェードアウト
		FUNC	RCD_SKIP		*早送り
		FUNC	RCD_SLOW		*スロー
?		FUNC	RCD_FILINFO		*データファイル情報取得

そしてこのソースの driver_table にその先頭アドレスを追加する。

レジスタは、d0以外は破壊してはならない。

