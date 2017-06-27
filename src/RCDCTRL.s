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


		.include	iocscall.mac
		.include	doscall.mac
		.include	MMDSP.h
		.include	DRIVER.h

*==================================================
* RCD エントリーテーブル
*==================================================

		.xdef	RCD_ENTRY

FUNC		.macro	entry
		.dc.w	entry-RCD_ENTRY
		.endm

RCD_ENTRY:
		FUNC	RCD_CHECK
		FUNC	RCD_NAME
		FUNC	RCD_INIT
		FUNC	RCD_SYSSTAT
		FUNC	RCD_TRKSTAT
		FUNC	RCD_GETMASK
		FUNC	RCD_SETMASK
		FUNC	RCD_FILEEXT
		FUNC	RCD_FLOADP
		FUNC	RCD_PLAY
		FUNC	RCD_PAUSE
		FUNC	RCD_CONT
		FUNC	RCD_STOP
		FUNC	RCD_FADEOUT
		FUNC	RCD_SKIP
		FUNC	RCD_SLOW


*==================================================
* RCD ローカルワークエリア
*==================================================

		.include rcddef293.mac

		.offset	DRV_WORK
cnoteptr	.ds.l	1
keyon_buf	.ds.b	TRK_NUM*2
		.text

rcd_adr:	.ds.l	1			*構造体のアドレス


*==================================================
* RCD 常駐チェック
*==================================================

O_title		equ	$0100
O_version	equ	$0104
O_staymark	equ	$0108

RCD_CHECK:
		movem.l	a0-a1,-(sp)
		movea.l	MM_MEMPTR(a6),a1
rcd_check10:
		move.l	(a1),d0				*最初のメモリブロックを探す
		beq	rcd_check11
		movea.l	d0,a1
		bra	rcd_check10
rcd_check11:
		cmpi.l	#"RCD ",O_title(a1)		*RCD文字のチェック
		bne	rcd_check19
		cmpi.l	#$12345678,O_staymark(a1)	*常駐マークのチェック
		bne	rcd_check19
		cmpi.l	#'2.92',O_version(a1)		*バージョンのチェック
		bcs	rcd_check19
		cmpi.l	#'3.00',O_version(a1)
		bcc	rcd_check19
		lea	O_title(a1),a0			*全てのチェックが通ったら、
		move.l	a0,d0
		and.l	#$00ffffff,d0
		lea	rcd_adr(pc),a0			*アドレスを記憶して返る
		move.l	d0,(a0)
		bra	rcd_check99
rcd_check19:
		move.l	$0c(a1),d0			*次のメモリブロックへ
		movea.l	d0,a1
		bne	rcd_check11
rcd_check90:
		moveq	#-1,d0				*見つからなかったら負を返す
rcd_check99:
		movem.l	(sp)+,a0-a1
		rts

*==================================================
* RCD ドライバ名取得
*==================================================

RCD_NAME:
		move.l	a0,-(sp)
		lea	name_buf(pc),a0
		move.l	a0,d0
		move.l	(sp)+,a0
		rts

name_buf:	.dc.b	'RCD2.9',0
		.even

*==================================================
* RCD ドライバ初期化
*==================================================
rcd		reg	a5

RCD_INIT:
		movem.l	d0-d1/a0/rcd,-(sp)
		movea.l	rcd_adr(pc),rcd
		move.l	noteptr(rcd),cnoteptr(a6)

		lea	TRACK_STATUS(a6),a0	*音源種類などの初期化
		moveq	#TRK_NUM-1,d0
		moveq	#1,d1
rcd_init10:
		move.b	d1,TRACKNO(a0)
		move.b	#3,INSTRUMENT(a0)
		clr.w	KEYOFFSET(a0)
		move.b	#$FF,KEYONSTAT(a0)
		addq.w	#1,d1
		lea	TRST(a0),a0
		dbra	d0,rcd_init10

rcd_init20:
		clr.l	TRACK_ENABLE(a6)
		move.w	#-1,SYS_LOOP(a6)
		move.w	#169,CYCLETIM(a6)

		movem.l	(sp)+,d0-d1/a0/rcd
		rts

*==================================================
* RCD 各種ステータス取得
*==================================================

rcd		reg	a5

RCD_SYSSTAT:
		movem.l	d0/a0/a5,-(sp)

		movea.l	rcd_adr(pc),rcd
		move.l	panel_tempo(rcd),d0		*テンポ
		move.w	d0,SYS_TEMPO(a6)

		lea	dummy_title(pc),a0		*データ無効時タイトル
		moveq	#64,d0
		tst.b	data_valid(rcd)
		beq	rcd_sysstat20

		movea.l	data_adr(rcd),a0		*タイトル
		tst.b	fmt(rcd)
		bne	rcd_sysstat10
		lea	2(a0),a0			*MCPならば、2バイト目から30バイト
		moveq	#30,d0
		bra	rcd_sysstat20
rcd_sysstat10:
		lea	32(a0),a0			*RCPならば、32バイト目から64バイト
rcd_sysstat20:
		move.w	d0,TITLELEN(a6)
		move.l	a0,SYS_TITLE(a6)

		tst.l	act(rcd)			*演奏中フラグ
		sne.b	d0
		ext.w	d0
		move.w	d0,PLAY_FLAG(a6)
		not.w	d0				*演奏終了フラグ
		cmpi.l	#1,sts(rcd)
		bne	rcd_sysstat30
		moveq	#0,d0
rcd_sysstat30:
		move.w	d0,PLAYEND_FLAG(a6)

		movem.l	(sp)+,d0/a0/a5
		rts

dummy_title:	.dc.b	0
		.even

*==================================================
* RCD キーオン情報取得
*==================================================

rcd		reg	a5

RCD_TRKSTAT:
		movem.l	d0-d5/d7/a0-a3/rcd,-(sp)
		movea.l	rcd_adr(pc),rcd

		cmpi.l	#2,sts(rcd)
		beq	rcd_keyget90

		bsr	get_noterun

		lea	keyon_buf(a6),a1
		lea	TRACK_STATUS(a6),a2
		moveq	#0,d1
		moveq	#0,d2				*track enable
		moveq	#16-1,d7
rcd_keyget10:
		bsr	get_track
		addq.w	#1,d1
		addq.l	#2,a1
		lea	TRST(a2),a2
		dbra	d7,rcd_keyget10

rcd_keyget90:
		move.l	TRACK_ENABLE(a6),d0
		move.l	d2,TRACK_ENABLE(a6)
		eor.l	d2,d0
		move.l	d0,TRACK_CHANGE(a6)

		movem.l	(sp)+,d0-d5/d7/a0-a3/rcd
		rts

*キーＯＮ情報取得
*	a0.l    temp
*	a1.l    note_adr(rcd) address
*	a2.l    temp
*	a3.l    temp
*	d0.l    temp
*	d1.l    noteoffset

get_noterun:
		lea	TRACK_STATUS(a6),a2

		movea.l	a2,a0				*TRACK_STATUSクリア
		moveq	#TRK_NUM-1,d0
get_noterun01:
		clr.l	STCHANGE(a0)
		lea	TRST(a0),a0
		dbra	d0,get_noterun01

		movea.l	note_adr(rcd),a1		*keyon_buf セット
		move.l	cnoteptr(a6),d1
get_noterun10:
		cmp.l	noteptr(rcd),d1
		beq	get_noterun90
		moveq	#0,d0
		move.b	(a1,d1.l),d0			*track no
		cmpi.w	#TRK_NUM,d0
		bcc	get_noterun50
		tst.b	trk_mask(rcd,d0.w)
		bne	get_noterun50
		mulu	#TRST,d0
		lea	(a2,d0.w),a0
		lea	KEYCODE(a0),a3
		move.b	1(a1,d1.l),d2			*keycode
		bmi	get_noterun30
		move.b	3(a1,d1.l),d3			*velocity
		bne	get_noterun40
		moveq	#8-1,d0				*キーＯＦＦ
get_noterun20:
		cmp.b	(a3)+,d2
		dbeq	d0,get_noterun20
		bne	get_noterun50
		subq.w	#8-1,d0
		neg.w	d0
		bset.b	d0,KEYONCHANGE(a0)
		bset.b	d0,KEYONSTAT(a0)
		bra	get_noterun50
get_noterun30:
		cmp.b	#255,d2
		bne	get_noterun50
		move.b	#$FF,KEYONCHANGE(a0)
		move.b	#$FF,KEYONSTAT(a0)
		bra	get_noterun50
get_noterun40:
		moveq	#8-1,d0				*キーＯＮ
get_noterun41:	cmp.b	(a3)+,d2
		dbeq	d0,get_noterun41
		bne	get_noterun42
		subq.w	#8-1,d0				*同じ音があったら、そこをＯＦＦ
		neg.w	d0
		bset.b	d0,KEYONCHANGE(a0)
		bset.b	d0,KEYONSTAT(a0)
get_noterun42:	move.b	KEYONSTAT(a0),d0		*キーＯＦＦの音を探してＯＮする
		moveq	#8-1,d4
get_noterun43:	lsr.b	#1,d0
		dbcs	d4,get_noterun43
		bcc	get_noterun44
		moveq	#8-1,d0
		sub.w	d4,d0
		bra	get_noterun45
get_noterun44:	moveq	#0,d0				*キーＯＦＦの音が無い
get_noterun45:
		bset.b	d0,KEYONCHANGE(a0)
		bclr.b	d0,KEYONSTAT(a0)
		bset.b	d0,KEYCHANGE(a0)
		move.b	d2,KEYCODE(a0,d0.w)
		cmp.b	VELOCITY(a0,d0.w),d3
		beq	get_noterun50
		bset.b	d0,VELCHANGE(a0)
		move.b	d3,VELOCITY(a0,d0.w)

get_noterun50:
		addq.l	#4,d1
		andi.l	#$3ff,d1
		bra	get_noterun10
get_noterun90:
		move.l	d1,cnoteptr(a6)
		rts

*	a0.l    temp
*	a2.l <- TRACK_STATUS address
*	d1.w <- track no
*	d2.l <-> track mask
*	d3.l    midi ch
*	d5.l    STCHANGE

get_track:
		moveq	#0,d5
		lea	midich(rcd),a0
		moveq	#0,d3
		move.b	(a0,d1.w),d3			*midi ch

		lea	trk_mask(rcd),a0		*TRACK_ENABLE
		tst.b	(a0,d1.w)
		bne	get_track10
		lea	active(rcd),a0
		tst.b	(a0,d1.w)
		beq	get_track10
		bset.l	d1,d2
		bra	get_track20
get_track10:	move.b	KEYONSTAT(a2),d0
		not.b	d0
		beq	get_track20
		move.b	#$FF,KEYONCHANGE(a2)
		move.b	#$FF,KEYONSTAT(a2)
get_track20:
		lea	ch_pbend(rcd),a0		*BEND
		move.w	d3,d0
		add.w	d0,d0
		add.w	d0,d0
		move.l	(a0,d0.w),d0
		subi.w	#8192,d0
		cmp.w	BEND(a2),d0
		beq	get_track30
		bset.l	#1,d5
		move.w	d0,BEND(a2)
get_track30:
		lea	ch_panpot(rcd),a0		*PAN
		moveq	#0,d0
		move.b	(a0,d3.w),d0
		cmp.w	PAN(a2),d0
		beq	get_track40
		bset.l	#2,d5
		move.w	d0,PAN(a2)
get_track40:
		lea	ch_prg(rcd),a0			*PROGRAM
		moveq	#0,d0
		move.b	(a0,d3.w),d0
		addq.b	#1,d0
		cmp.w	PROGRAM(a2),d0
		beq	get_track90
		bset.l	#3,d5
		move.w	d0,PROGRAM(a2)
get_track90:
		move.b	d5,STCHANGE(a2)
		rts

*==================================================
* RCD 演奏トラック調査
*	d0.l -> トラックフラグ
*==================================================

RCD_GETMASK:
		move.l	TRACK_ENABLE(a6),d0
		rts


*==================================================
* RCD 演奏トラック設定
*	d1.l <- トラックフラグ
*==================================================

RCD_SETMASK:
		movem.l	d0-d2/a0,-(sp)
		movea.l	rcd_adr(pc),a0
		lea	trk_mask(a0),a0
		moveq	#TRK_NUM-1,d0
rcd_setmask10:
		lsr.l	#1,d1
		scc	d2
		move.b	d2,(a0)+
		dbra	d0,rcd_setmask10
		movem.l	(sp)+,d0-d2/a0
		rts


*==================================================
* RCD 拡張子テーブルアドレス取得
*	a0.l -> テーブルアドレス
*==================================================

RCD_FILEEXT:
		move.l	a0,-(sp)
		lea	ext_buf(pc),a0
		move.l	a0,d0
		move.l	(sp)+,a0
		rts

ext_buf:
		.dc.b	_RCP,'RCP'
		.dc.b	_R36,'R36'
		.dc.b	_MDF,'MDF'
		.dc.b	_MCP,'MCP'
		.dc.b	_MDI,'MDI'
		.dc.b	_SNG,'SNG'
		.dc.b	_MID,'MID'
		.dc.b	_STD,'STD'
		.dc.b	_MFF,'MFF'
		.dc.b	_SMF,'SMF'
		.dc.b	_SEQ,'SEQ'
		.dc.b	_MM2,'MM2'
		.dc.b	_MMC,'MMC'
		.dc.b	0
		.even


*==================================================
* RCD データファイルロード＆演奏
*	a1.l <- ファイル名
*	d0.b <- 識別コード
*	d0.l -> 負ならエラー
*==================================================

RCD_FLOADP:
		cmpi.b	#_RCP,d0		*RCP MCP : rcp
		beq	call_rcp
		cmpi.b	#_R36,d0
		beq	call_rcp
		cmpi.b	#_MCP,d0
		beq	call_rcp
		cmpi.b	#_MDF,d0		*MDF: lzm
		beq	call_lzm
		cmpi.b	#_ZDF,d0		*ZDF: lzz
		beq	call_lzz
		cmpi.b	#_MDI,d0		*MDI: DtoR
		beq	call_DtoR
		cmpi.b	#_SNG,d0		*SNG: StoR/UtoR
		beq	call_SUtoR
		cmpi.b	#_MID,d0		*MID STD MFF SMF: ItoR
		beq	call_ItoR
		cmpi.b	#_STD,d0
		beq	call_ItoR
		cmpi.b	#_MFF,d0
		beq	call_ItoR
		cmpi.b	#_SMF,d0
		beq	call_ItoR
		cmpi.b	#_SEQ,d0		*SEQ: QtoR
		beq	call_QtoR
		cmpi.b	#_MM2,d0		*MM2: CtoR
		beq	call_CtoR
		cmpi.b	#_MMC,d0		*MMC: CtoR
		beq	call_CtoR
		moveq	#-1,d0
rcd_floadp90:
		move.l	a0,-(sp)
		tst.l	d0
		beq	rcd_floadp99
		bpl	rcd_floadp91
		moveq	#12,d0			*プレーヤが見つからなかった
		bra	rcd_floadp99
rcd_floadp91:
		moveq	#1,d0
rcd_floadp99:
		movea.l	rcd_adr(pc),a0			*noteptr初期化
		move.l	noteptr(a0),cnoteptr(a6)
		move.l	(sp)+,a0
		rts

call_rcp:
		lea	rcp_name(pc),a0
		bsr	CALL_PLAYER
		bra	rcd_floadp90

call_lzm:
		lea	lzm_name(pc),a0
		bsr	CALL_PLAYER
		tst.l	d0
		bpl	call_lzm90
		lea	lzz_name(pc),a0
		bsr	CALL_PLAYER
call_lzm90:
		bra	rcd_floadp90

call_lzz:
		lea	lzz_name(pc),a0
		bsr	CALL_PLAYER
		bra	rcd_floadp90

call_DtoR:
		lea	DtoR_name(pc),a0
		bsr	CALL_PLAYER
		bra	rcd_floadp90

call_SUtoR:
		movea.l	a1,a0
		bsr	READ_FILEBUFF

		lea	UtoR_name(pc),a0
		lea	FILE_BUFF(a6),a0
		cmpi.l	#'BALL',(a0)
		bne	call_UtoR
		cmpi.l	#'ADE ',4(a0)
		bne	call_UtoR
		cmpi.l	#'SONG',8(a0)
		bne	call_UtoR
		lea	StoR_name(pc),a0
call_UtoR:
		bsr	CALL_PLAYER
		bra	rcd_floadp90

call_ItoR:
		lea	ItoR_name(pc),a0
		bsr	CALL_PLAYER
		bra	rcd_floadp90

call_QtoR:
		lea	QtoR_name(pc),a0
		bsr	CALL_PLAYER
		bra	rcd_floadp90

call_CtoR:
		lea	CtoR_name(pc),a0
		bsr	CALL_PLAYER
		bra	rcd_floadp90

rcp_name:	.dc.b	'rcp',0
lzm_name:	.dc.b	'lzm -bn',0
lzz_name:	.dc.b	'lzz -bn',0
DtoR_name:	.dc.b	'DtoR -bn',0
StoR_name:	.dc.b	'StoR -bn',0
UtoR_name:	.dc.b	'UtoR -bn',0
ItoR_name:	.dc.b	'ItoR -bn',0
QtoR_name:	.dc.b	'QtoR -bn',0
CtoR_name:	.dc.b	'CtoR -bn',0
WRDP_name:	.dc.b	'WRDP',0
		.even


*==================================================
* RCD 演奏開始
*==================================================

RCD_PLAY:
		move.l	a0,-(sp)
		movea.l	rcd_adr(pc),a0			*データが有効だったら
		tst.b	data_valid(a0)
		beq	rcd_play90

		movea.l	init(a0),a0			*初期化して
		jsr	(a0)

		movea.l	rcd_adr(pc),a0			*演奏する
		movea.l	begin(a0),a0
		jsr	(a0)

		movea.l	rcd_adr(pc),a0			*ノートポインタ初期化
		move.l	noteptr(a0),cnoteptr(a6)
rcd_play90:
		move.l	(sp)+,a0
		rts


*==================================================
* RCD 演奏中断
*==================================================

RCD_PAUSE:
		move.l	a0,-(sp)
		movea.l	rcd_adr(pc),a0
		tst.l	act(a0)
		beq	rcd_pause90
		moveq	#1,d0
		move.l	d0,sts(a0)
		clr.l	act(a0)
rcd_pause90:
		move.l	(sp)+,a0
		rts


*==================================================
* RCD 演奏再開
*==================================================

RCD_CONT:
		move.l	a0,-(sp)
		movea.l	rcd_adr(pc),a0
		cmpi.l	#1,sts(a0)
		bne	rcd_cont90
		moveq	#0,d0
		move.l	d0,sts(a0)
		moveq	#1,d0
		move.l	d0,act(a0)
rcd_cont90:
		move.l	(sp)+,a0
		rts


*==================================================
* RCD 演奏終了
*==================================================

RCD_STOP:
		move.l	a0,-(sp)
		movea.l	rcd_adr(pc),a0
		movea.l	end(a0),a0
		jsr	(a0)
		bsr	CLEAR_KEYON
		move.l	(sp)+,a0
		rts

*==================================================
* RCD フェードアウト
*==================================================

RCD_FADEOUT:
		move.l	a0,-(sp)
		movea.l	rcd_adr(pc),a0
		move.w	#5,fade_time(a0)
		move.b	#128,fade_count(a0)
		move.l	(sp)+,a0
		rts

*==================================================
* RCD スキップ
*	d0.w <- スキップ開始フラグ
*==================================================

RCD_SKIP:
		tst.w	d0
		bne	rcd_skip10
		move.b	#$00,$80e.w
		bra	rcd_skip20
rcd_skip10:
		move.b	#$0A,$80e.w		*CTRL+OPT2
rcd_skip20:
		rts

*==================================================
* RCD スロー
*	d0.w <- スロー開始フラグ
*==================================================

RCD_SLOW:
		tst.w	d0
		bne	rcd_slow10
		move.b	#$00,$80e.w
		bra	rcd_slow20
rcd_slow10:
		move.b	#$06,$80e.w		*CTRL+OPT1
rcd_slow20:
		rts

		.end

=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
(#MIDI /#26) ＭＩＤＩに関する話題         92/07/02 14:28 (   703文字)
[ 5051/ 5063:0] SPS0219[ TURBO  ]【re:ちょっとお願いが             】
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

>ＲＣＤで、演奏中の各チャンネルのキーオン状態や、音色番号、
>テンポなど、リアルタイムディスプレイに必要な情報を得る方法
>についての資料を捜しています。

資料はちょっと古いのですが、これが#LX68Kに有ります。

8:RCDDEF / RCDｱｸｾｽ技術情報 2.80    SPS0616[HARPOON ] 90/12/31  1519   8003

それから、キーのオンオフはこういったルーチンで得ているようです。

-	-	-	-	-	-	-	-	-	-
	if( rcd->sts != 2 ) {
		while( rcd->noteptr != cnoteptr ) {
			np = rcd->note_adr;
			kb_disp( np[ cnoteptr ],		/*note*/
				 np[ cnoteptr + 1 ],		/*step*/
				 np[ cnoteptr + 2 ],		/*gate*/
				 np[ cnoteptr + 3 ] );		/*velo*/
			cnoteptr = ( cnoteptr + 4 ) & 0x3ff;
		}
	}
-	-	-	-	-	-	-	-	-	-

							TURBO

参考:rcp.xの終了コード
 1:usage
16:～					(演奏できなかった場合)
17:RCD が常駐してません。
18:違うバージョンの RCD が常駐しています。
127:メモリが足りません			(CLIB内_main.oのエラー)

ITOR.xの終了コード
 1:不正MIDIメッセージ
16:～					(演奏できなかった場合)
   ファイルが読めません。 ( %s )
   ファイルリードに失敗しました。
   RCDバッファ容量不足です。
   ファイルライトに失敗しました。
   ファイルが作成出来ません。( %s )
   トラックサイズが128KBを超えました。
   トラックサイズが256KBを超えました。
17:～					(変換できなかった場合)
   メモリが足りません
   標準MIDIファイルではありません
   FORMAT %d は変換出来ません。
   デルタタイムが異常です。
18:フォーマットが異常です。
20:usage
21:RCD が常駐していません。
   違うバージョンの RCD が常駐しています
127:メモリが足りません			(CLIB内_main.oのエラー)

