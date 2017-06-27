*************************************************************************
*									*
*									*
*	    Ｘ６８０００　ＭＸＤＲＶ／ＭＡＤＲＶディスプレイ		*
*									*
*				ＭＭＤＳＰ				*
*									*
*									*
*	Copyright (C) 1992-94 Masao Takahashi				*
*									*
*									*
*************************************************************************


		.include	iocscall.mac
		.include	doscall.mac
		.include	MMDSP.h
		.include	ZMLABEL.h
		.include	DRIVER.h


*==================================================
* ZMUSIC エントリーテーブル
*==================================================

		.xdef	ZMUSIC_ENTRY

FUNC		.macro	entry
		.dc.w	entry-ZMUSIC_ENTRY
		.endm

ZMUSIC_ENTRY:
		FUNC	ZMUSIC_CHECK
		FUNC	ZMUSIC_NAME
		FUNC	ZMUSIC_INIT
		FUNC	ZMUSIC_SYSSTAT
		FUNC	ZMUSIC_TRKSTAT
		FUNC	ZMUSIC_GETMASK
		FUNC	ZMUSIC_SETMASK
		FUNC	ZMUSIC_FILEEXT
		FUNC	ZMUSIC_FLOADP
		FUNC	ZMUSIC_PLAY
		FUNC	ZMUSIC_PAUSE
		FUNC	ZMUSIC_CONT
		FUNC	ZMUSIC_STOP
		FUNC	ZMUSIC_FADEOUT
		FUNC	ZMUSIC_SKIP
		FUNC	ZMUSIC_SLOW


*==================================================
* ZMUSIC ローカルワークエリア
*==================================================

		.offset	DRV_WORK
playtrack	ds.l	1
abs_ch		ds.l	1
playwork	ds.l	1
complework	ds.l	1
dataptr		ds.l	32
trackno		ds.b	32
timer_value	ds.w	1
_FF_flg		ds.b	1
_SLOW_flg	ds.b	1
stopflag	ds.b	1
		.text

ZMUSIC		.macro	func		*ドライバのファンクションコール
		moveq.l	func,d1
		trap	#3
		.endm


*==================================================
* ZMUSIC 常駐チェック
*==================================================

ZMUSIC_CHECK:
		move.l	a0,-(sp)
		move.l	$23*4.w,a0
		cmp.l	#"ZmuS",-8(a0)
		bne	not_keeped
		cmp.w	#"iC",-4(a0)
		bne	not_keeped
		moveq	#0,d0				*バージョンは
		bra	keeped				*	よくわからない
not_keeped:
		moveq.l	#-1,d0
keeped:
		move.l	(sp)+,a0
		rts


*==================================================
* ZMUSIC ドライバ名取得
*==================================================

ZMUSIC_NAME:
		move.l	a0,-(sp)
		lea	name_buf(pc),a0
		move.l	a0,d0
		move.l	(sp)+,a0
		rts

name_buf:	.dc.b	'ZMUSIC',0
		.even


*==================================================
* ZMUSIC ドライバ初期化
*==================================================

ZMUSIC_INIT:
		movem.l	d0-d2/a0,-(sp)

		ZMUSIC	#$3A
		move.l	a0,playtrack(a6)
		move.l	d0,abs_ch(a6)

		moveq	#1,d2
		ZMUSIC	#$3C
		move.l	a0,playwork(a6)
		move.l	d0,complework(a6)

		clr.b	_FF_flg(a6)
		clr.b	_SLOW_flg(a6)

		move.w	#-1,SYS_LOOP(a6)
		move.w	#508,CYCLETIM(a6)
		move.w	#77,TITLELEN(a6)

		st.b	stopflag(a6)

		movem.l	(sp)+,d0-d2/a0
		rts


*==================================================
* ZMUSIC システムステータス取得
*==================================================

ZMUSIC_SYSSTAT:
		movem.l	d0-d2/a0,-(sp)

*		move.l	LAST_TITLE(a6),SYS_TITLE(a6)	*タイトル
		ZMUSIC	#$4e
		move.l	a0,SYS_TITLE(a6)

		moveq	#-1,d2				*m_tempo(-1)
		ZMUSIC	#$05
		move.w	d0,SYS_TEMPO(a6)

		tst.l	TRACK_ENABLE(a6)		*演奏中フラグ
		sne.b	d0
		ext.w	d0
		move.w	d0,PLAY_FLAG(a6)
		beq	sysstat10
		clr.b	stopflag(a6)
sysstat10:
		bsr	get_playflag			*演奏終了フラグ
		move.w	d0,PLAYEND_FLAG(a6)

*		bsr	get_loopcount			*ループ回数
		ZMUSIC	#$4d
		subq.w	#1,d0
		move.w	d0,SYS_LOOP(a6)

		movem.l	(sp)+,d0-d2/a0
		rts


*演奏中かどうかトラックを調べる
*	d0.l -> 0:演奏中 -1:停止中

get_playflag:
		movem.l	d1/a0-a2,-(sp)
		movea.l	playtrack(a6),a1
		movea.l	playwork(a6),a2
		moveq	#-1,d0
		tst.b	stopflag(a6)
		bne	get_playflag90
get_playflag10:
		move.b	(a1)+,d1
		bmi	get_playflag90
		lsl.w	#8,d1
		lea	(a2,d1.w),a0
		cmpi.b	#1,p_not_empty(a0)
		beq	get_playflag10
		moveq	#0,d0
get_playflag90:
		movem.l	(sp)+,d1/a0-a2
		rts

.if 0		*同機能のZMUSICコールができたので不要
*ループ回数を調べる
*	d0.w -> ループ回数(0-255/-1)

get_loopcount:
		movem.l	d1/a0-a2,-(sp)
		movea.l	playtrack(a6),a1
		movea.l	playwork(a6),a2
		moveq	#-1,d1
get_loopcount10:
		move.b	(a1)+,d0		*有効トラック中最小の[do]回数を調べる
		bmi	get_loopcount20
		lsl.w	#8,d0
		lea	(a2,d0.w),a0
		tst.b	p_not_empty(a0)
		bne	get_loopcount10
		move.b	p_do_loop_flag(a0),d0
		cmp.b	d1,d0
		bcc	get_loopcount10
		moveq	#0,d1
		move.b	d0,d1
		bra	get_loopcount10
get_loopcount20:
		move.w	d1,d0			*[do]の数が１以下の場合はループしていない
		ble	get_loopcount90
		subq.w	#1,d0
get_loopcount90:
		movem.l	(sp)+,d1/a0-a2
		rts
.endif

*==================================================
* ZMUSIC トラックステータス取得
*==================================================

ZMUSIC_TRKSTAT:
		movem.l	d0-d5/d7/a0-a5,-(sp)

		movea.l	playtrack(a6),a1
		movea.l	playwork(a6),a2
		lea	TRACK_STATUS(a6),a3
		lea	dataptr(a6),a5
		moveq	#0,d3
		moveq	#0,d4
		moveq	#32-1,d7
zmus_track10:
		move.b	(a1)+,d0
		bpl	zmus_track20
		bsr	clear_stat
		bra	zmus_track30
zmus_track20:
		bsr	get_track
zmus_track30:
		lea	TRST(a3),a3
		addq.l	#4,a5
		addq.w	#1,d3
		dbra	d7,zmus_track10
zmus_track90:
		move.l	TRACK_ENABLE(a6),d0
		move.l	d4,TRACK_ENABLE(a6)
		eor.l	d4,d0
		move.l	d0,TRACK_CHANGE(a6)

		movem.l	(sp)+,d0-d5/d7/a0-a5
		rts

*演奏トラックテーブル作成

make_tracktbl:
		movea.l	playtrack(a6),a0
		lea	trackno(a6),a1
		moveq	#32-1,d0
make_tracktbl10:
		move.b	(a0)+,(a1)+
		dbmi	d0,make_tracktbl10
		bpl	make_tracktbl90
make_tracktbl20:
		move.b	#-1,(a1)+
		dbra	d0,make_tracktbl20
make_tracktbl90:
		rts


*ステータスクリアサブ
*	a3 <- TRACK_STATUS address

clear_stat:
		moveq	#0,d5
		clr.l	STCHANGE(a3)
		tst.b	INSTRUMENT(a3)		*instrument clear
		bne	clear_stat01
		tst.b	TRACKNO(a3)
		beq	clear_stat10		*track no clear
clear_stat01:
		clr.b	INSTRUMENT(a3)
		clr.b	TRACKNO(a3)
		bset.l	#0,d5
clear_stat10:
		tst.w	PROGRAM(a3)		*program clear
		beq	clear_stat20
		clr.w	PROGRAM(a3)
		bset.l	#3,d5
clear_stat20:
		clr.b	KEYONCHANGE(a3)		*keyon clear
		cmpi.b	#$FF,KEYONSTAT(a3)
		beq	clear_stat30
		st.b	KEYONCHANGE(a3)
		st.b	KEYONSTAT(a3)
clear_stat30:
		clr.b	KEYCHANGE(a3)		*keycode clear
		tst.b	KEYCODE(a3)
		beq	clear_stat40
		clr.b	KEYCODE(a3)
		move.b	#$01,KEYCHANGE(a3)
clear_stat40:
		clr.b	VELCHANGE(a3)		*velocity clear
		tst.b	VELOCITY(a3)
		beq	clear_stat90
		clr.b	VELOCITY(a3)
		move.b	#$01,VELCHANGE(a3)
clear_stat90:
		move.b	d5,STCHANGE(a3)

		moveq	#115,d0			*時間つぶし
wait:
		dbra	d0,wait
		rts


*	d0.b <- zmusic track no
*	d1.l xx
*	d2.l xx
*	a0.l xx
*	a2.l <- playwork track1 address
*	a3.l <- TRACK_STATUS address
*	a4.l xx
*	a5.l <- last mml data address
*	d3.l <- mmdsp track no
*	d4.l <- mmdsp track enable
*	d5.l xx

get_track:
		moveq	#0,d5				*status change flag
		clr.l	STCHANGE(a3)

		move.b	d0,d1
		lsl.w	#8,d0
		lea	(a2,d0.w),a0			*zmusic track work

		addq.b	#1,d1				*track no
		cmp.b	TRACKNO(a3),d1
		beq	get_track00
		bset.l	#0,d5
		move.b	d1,TRACKNO(a3)
get_track00:
		tst.b	p_not_empty(a0)			*TRACK ENABLE
		bne	get_track01
		tst.b	p_se_mode(a0)
		bpl	get_track01
		bset.l	d3,d4
get_track01:
		move.b	p_ch(a0),d0			*INSTRUMENT
		cmpi.b	#8,d0				*このへん要改善
		bmi	get_track02	*FM
		bhi	get_track03	*MIDI
		moveq	#2,d0		*ADPCM
		moveq	#0,d1
		bra	get_track04
get_track02:
		moveq	#1,d0
		moveq	#0,d1
		bra	get_track04
get_track03:
		moveq	#3,d0
		moveq	#0,d1
get_track04:
		cmp.b	INSTRUMENT(a3),d0
		beq	get_track10
		bset.l	#0,d5
		move.b	d0,INSTRUMENT(a3)
		move.w	d1,KEYOFFSET(a3)
get_track10:
		cmpi.b	#9,p_ch(a0)			*BEND
		bls	get_track11
		move.w	p_detune_m(a0),d0
		bra	get_track12
get_track11:	move.w	p_detune_f(a0),d0
		tst.w	p_pmod_flg(a0)			*FM 時のみp_mod_work2有効
		beq	get_track12
		add.w	p_pmod_work2(a0),d0
get_track12:	tst.w	p_port_flg(a0)
		bne	get_track13
		tst.w	p_bend_flg(a0)
		beq	get_track14
get_track13:	add.w	p_port_work2(a0),d0
get_track14:	cmp.w	BEND(a3),d0
		beq	get_track20
		bset.l	#1,d5
		move.w	d0,BEND(a3)
get_track20:
		moveq	#0,d0				*PAN
		move.b	p_pan2(a0),d0
		cmp.w	PAN(a3),d0
		beq	get_track30
		bset.l	#2,d5
		move.w	d0,PAN(a3)
get_track30:
		moveq	#0,d0				*PROGRAM
		move.b	p_pgm(a0),d0
		addq.b	#1,d0
		cmp.w	PROGRAM(a3),d0
		beq	get_track40
		bset.l	#3,d5
		move.w	d0,PROGRAM(a3)
get_track40:
		move.l	d3,-(sp)
		lea	p_note(a0),a4			*KEYON & KEYCODE & VELOCITY
		moveq	#0,d1
		moveq	#0,d2
		move.b	p_velo(a0),d3			*velocity
		cmpi.b	#8,p_ch(a0)
		bhi	get_track41
		move.b	p_vol(a0),d3
		not.b	d3
		andi.b	#$7f,d3
get_track41:
		move.b	(a4)+,d0
		bpl	get_track42
		bset.l	d1,d2
get_track42:
		cmp.b	KEYCODE(a3,d1.w),d0		*keycode change
		beq	get_track43
		bset.b	d1,KEYCHANGE(a3)
		move.b	d0,KEYCODE(a3,d1.w)
get_track43:
		cmp.b	VELOCITY(a3,d1.w),d3		*velocity change
		beq	get_track44
		bset.b	d1,VELCHANGE(a3)
		move.b	d3,VELOCITY(a3,d1.w)
get_track44:
		addq.w	#1,d1
		cmpi.w	#7,d1
		bls	get_track41
get_track45:
		movea.l	p_data_pointer(a0),a4	*oldptr != nowptr
		cmpa.l	(a5),a4
		sne	d3
		move.l	a4,(a5)
		or.b	KEYONSTAT(a3),d3	* || keyonstat == OFF
		tst.b	p_tie_flg(a0)		* && p_tie_flg == OFF
		seq	d0
		and.b	d0,d3
		move.l	p_on_count(a0),d0	* && step >= gate
		move.w	d0,d1
		swap	d0
		cmp.w	d1,d0
		scc	d0
		and.b	d0,d3
		move.b	d2,d0			* && p_note == ON
		not.b	d0
		and.b	d0,d3
		bclr.b	#7,p_seq_flag(a0)	* || p_seq_flag (前にもってけば速くなる^^;)
		sne	d0
		or.b	d0,d3
		beq	get_track46
		bclr.l	#0,d2			*強制keyon
get_track46:
		move.b	KEYONSTAT(a3),d0	*keyon change
		eor.b	d2,d0
		or.b	d3,d0
		move.b	d0,KEYONCHANGE(a3)
		move.b	d2,KEYONSTAT(a3)
get_track49:
		move.l	(sp)+,d3
get_track90:
		move.b	d5,STCHANGE(a3)
		rts


* 参考：キーオン判定方法
*
*p_seq_flagに反映せずにキーオンするZMDコマンドがあるため、しかたなく次の条件式を使う
*
*if (p_seq_flag ||
*    p_note == ON && p_tie_flg == OFF && step >= gate &&
*    (oldptr != nowptr || keyonstat == OFF)) {
*	keyon();
*}
*
* 結局過去のルーチンより複雑になってしまった。
* せっかく付けてもらった p_seq_flag の bit7 だが、これではほとんど役に立たない。
* キーオン時に素直に立ってくれればよいだけなのに。
* ほかにも、演奏データの総クロック数を演奏前にワークに入れてくれてもいいと思う。
* 高速化するための制限を持つのはZMSCだけにしたほうが良いのではないか。


*==================================================
* ZMUSIC 演奏トラック調査
*	d0 -> トラックフラグ
*==================================================

ZMUSIC_GETMASK:
		move.l	TRACK_ENABLE(a6),d0
		rts


*==================================================
* ZMUSIC 演奏トラック設定
*	d1 <- トラックフラグ
*==================================================

ZMUSIC_SETMASK:
		movem.l	d0-d4/a0-a1,-(sp)
		bsr	make_tracktbl
		lea	trackno(a6),a1
		moveq	#31,d3
		move.l	d1,d4
setmask10:
		moveq	#0,d2
		move.b	(a1,d3.w),d2
		bmi	setmask12
		addq.l	#1,d2
		btst.l	d3,d4
		bne	setmask11
		neg.l	d2
setmask11:
		ZMUSIC	#$4B
setmask12:
		dbra	d3,setmask10
		movem.l	(sp)+,d0-d4/a0-a1
		rts


*==================================================
* ZMUSIC 拡張子テーブルアドレス取得
*	d0.l -> テーブルアドレス
*==================================================

ZMUSIC_FILEEXT:
		move.l	a0,-(sp)
		lea	ext_buf(pc),a0
		move.l	a0,d0
		move.l	(sp)+,a0
		rts

ext_buf:	.dc.b	_ZMS,'ZMS'
		.dc.b	_ZMD,'ZMD'
		.dc.b	_OPM,'OPM'
		.dc.b	_MDN,'MDN'
		.dc.b	_MDX,'MDX'
		.dc.b	_MDF,'MDF'
		.dc.b	_RCP,'RCP'
		.dc.b	_R36,'R36'
		.dc.b	_MCP,'MCP'
		.dc.b	_MDZ,'MDZ'
		.dc.b	_MDI,'MDI'
		.dc.b	_MID,'MID'
		.dc.b	_STD,'STD'
		.dc.b	_MFF,'MFF'
		.dc.b	_SMF,'SMF'
		.dc.b	_ZDF,'ZDF'
		.dc.b	0
		.even


*==================================================
* ZMUSIC データファイルロード＆演奏
*	a1.l <- ファイル名
*	d0.b <- 識別コード
*	d0.l -> 負ならエラー
*	a0.l -> プレーヤ名
*==================================================

ZMUSIC_FLOADP:
		move.l	a1,-(sp)
		move.l	d0,d1

		lea	mzp_name(pc),a0			*MZPを呼び出す
		bsr	CALL_PLAYER
		tst.l	d0
		bpl	zmusic_floadp90			*MZPが実行できたら終わる
		moveq	#12,d0

		cmpi.b	#_ZMS,d1			*ZMSかZMDかOPMだったら
		beq	zmusic_floadp10
		cmpi.b	#_ZMD,d1
		beq	zmusic_floadp10
		cmpi.b	#_OPM,d1
		bne	zmusic_floadp92
zmusic_floadp10:
		movea.l	a1,a0				*自前でOPMにコピーする
		bsr	trans_zms
		lea	opm_name(pc),a0
		moveq	#1,d0
		bra	zmusic_floadp92

zmusic_floadp90:
		cmpi.w	#19,d0
		bls	zmusic_floadp91
		moveq	#1,d0
zmusic_floadp91:
		move.b	errcnvtbl(pc,d0.w),d0
zmusic_floadp92:
		ext.w	d0
		ext.l	d0
		andi.w	#$007f,d0
		movea.l	(sp)+,a1
		clr.b	stopflag(a6)
		rts

*			0   1   2   3   4   5   6   7   8   9
errcnvtbl:	.dc.b	$00,$01,$05,$02,$12,$13,$14,$06,$08,$0e
*			10  11  12  13  14  15  16  17  18  19
		.dc.b	$16,$17,$18,$10,$19,$1A,$09,$07,$11,$1B
		.even


*OPMにファイルをコピーする
*	a0.l <- ファイル名
*	d0.l -> 負ならエラー

trans_zms:
		movem.l	d1/a0,-(sp)
		clr.l	-(sp)			*ファイルを読んで
		clr.l	-(sp)
		move.l	a0,-(sp)
		bsr	READ_FILE
		lea	12(sp),sp
		move.l	d0,d1
		bmi	trans_zms90

		move.w	#1,-(sp)		*OPMをオープンして
		pea	opm_name(pc)
		DOS	_OPEN
		addq.l	#6,sp
		tst.l	d0
		bmi	trans_zms90

		move.l	d1,-(sp)		*データを書き出し
		move.l	a0,-(sp)
		move.w	d0,-(sp)
		DOS	_WRITE
		DOS	_CLOSE			*クローズする
		lea	10(sp),sp

trans_zms90:
		move.l	a0,-(sp)
		bsr	FREE_MEM
		addq.l	#4,sp
		movem.l	(sp)+,d1/a0
		rts

mzp_name:	.dc.b	'MZP',0
opm_name:	.dc.b	'OPM',0
		.even


*==================================================
* ZMUSIC 演奏開始
*==================================================

ZMUSIC_PLAY:
		movem.l	d0-d4/a0,-(sp)
		moveq	#0,d2
		moveq	#0,d3
		moveq	#0,d4
		ZMUSIC	#$08
		clr.b	stopflag(a6)
		movem.l	(sp)+,d0-d4/a0
		rts


*==================================================
* ZMUSIC 演奏中断
*==================================================

ZMUSIC_PAUSE:
		movem.l	d0-d4/a0,-(sp)
		moveq	#0,d2
		moveq	#0,d3
		moveq	#0,d4
		ZMUSIC	#$0A
		movem.l	(sp)+,d0-d4/a0
		rts


*==================================================
* ZMUSIC 演奏再開
*==================================================

ZMUSIC_CONT:
		movem.l	d0-d4/a0,-(sp)
		moveq	#0,d2
		moveq	#0,d3
		moveq	#0,d4
		ZMUSIC	#$0B
		movem.l	(sp)+,d0-d4/a0
		rts


*==================================================
* ZMUSIC 演奏停止
*==================================================

ZMUSIC_STOP:
		movem.l	d0-d4/a0,-(sp)
		moveq	#0,d2
		moveq	#0,d3
		moveq	#0,d4
		ZMUSIC	#$0A
		st.b	stopflag(a6)
		movem.l	(sp)+,d0-d4/a0
		rts

*==================================================
* ZMUSIC フェードアウト
*==================================================

ZMUSIC_FADEOUT:
		movem.l	d0-d2/a0,-(sp)
		moveq	#40,d2
		ZMUSIC	#$1A
		movem.l	(sp)+,d0-d2/a0
		rts

*==================================================
* ZMUSIC スキップ
*	d0.w <- スキップ開始フラグ
*==================================================

ZMUSIC_SKIP:
		movem.l	d0-d3/a0,-(sp)
		tst.w	d0
		bne	_FF
		moveq.l	#-1,d2			*通常テンポに戻す
		ZMUSIC #$05
		move.l	a0,d2
		ZMUSIC	#$3f
		clr.b	_FF_flg(a6)
zmusic_skip90:
		movem.l	(sp)+,d0-d3/a0
		rts

*_FF と _SLOW はZP.sから一部拝借

_FF:						*早送り
		tst.b	_SLOW_flg(a6)		*低速演奏か?
		bne	zmusic_skip90
_ff0:
		ZMUSIC	#$3d			*get timer type
		tst.l	d0
		beq	tm_a
		move.w	#$fa,timer_value(a6)
		bsr	init_timer	*B
		bra	set_ff_flg
tm_a:
		move.w	#$3a0,timer_value(a6)
		bsr	init_timer_a	*A
set_ff_flg:
		st.b	_FF_flg(a6)
		bra	zmusic_skip90

init_timer:					*タイマーBに値を書き込む
		moveq.l	#$12,d1			*reg number
		move.w	timer_value(a6),d2	*timer B value
		IOCS	_OPMSET
		rts

init_timer_a:					*タイマーAに値を書き込む
		moveq.l	#$10,d1			*reg number
		move.w	timer_value(a6),d2	*timer A value
		lsr.w	#2,d2
		IOCS	_OPMSET
		moveq.l	#$11,d1
		move.w	timer_value(a6),d2	*timer A value
		andi.b	#3,d2
		IOCS	_OPMSET
		rts


*==================================================
* ZMUSIC スロー
*==================================================

ZMUSIC_SLOW:
		movem.l	d0-d2/a0,-(sp)
		tst.w	d0
		bne	_SLOW
		moveq.l	#-1,d2			*通常テンポに戻す
		ZMUSIC #$05
		move.l	a0,d2
		ZMUSIC	#$3f
		clr.b	_SLOW_flg(a6)
zmusic_slow90:
		movem.l	(sp)+,d0-d2/a0
		rts

_SLOW:						*低速演奏
		tst.b	_FF_flg(a6)		*早送り演奏か?
		bne	zmusic_slow90
		ZMUSIC	#$3d			*get timer type
		tst.l	d0
		beq	slw_tm_a
		move.w	#$5d,timer_value(a6)
		bsr	init_timer	*B
		bra	set_slow_flg
slw_tm_a:
		clr.w	timer_value(a6)
		bsr	init_timer_a	*A
set_slow_flg:
		st.b	_SLOW_flg(a6)
		bra	zmusic_slow90

		.end

参考:MZP終了コード
　１	コマンドラインが異常
　２	メモリが不足
　３	指定されたファイルが見つからない
　４	??toZ.x がない
　５	データの種類が違う
　６	演奏できなかった（ Z-MUSIC でエラー発生）
　７	Z-MUSIC が常駐していない（あるいはバージョンが低い）
　８	PCMバッファが不足
　９	コンバート中に異常なコードを見付けた（バグの可能性もあり）
１０	書き込みできない
１１	ファイルを作れない
１２	内部バッファが不足
１３	lzm(lzz) がない
１４	lzm(lzz) か RC のコンバータでエラーが発生した
１５	RC のコンバータがない
１６	MIDIデータの文字型データ変換失敗（主に Z-MUSIC のワーク不足）
１７	トラックバッファが不足
１８	lzz で展開に失敗した
１９	Human68k のバージョンが低い


