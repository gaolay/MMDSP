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


		.include	iocscall.mac
		.include	doscall.mac
		.include	MMDSP.h
		.include	DRIVER.h


*==================================================
* MCDRV エントリーテーブル
*==================================================

		.xdef	MCDRV_ENTRY

FUNC		.macro	entry
		.dc.w	entry-MCDRV_ENTRY
		.endm

MCDRV_ENTRY:
		FUNC	MCDRV_CHECK
		FUNC	MCDRV_NAME
		FUNC	MCDRV_INIT
		FUNC	MCDRV_SYSSTAT
		FUNC	MCDRV_TRKSTAT
		FUNC	MCDRV_GETMASK
		FUNC	MCDRV_SETMASK
		FUNC	MCDRV_FILEEXT
		FUNC	MCDRV_FLOADP
		FUNC	MCDRV_PLAY
		FUNC	MCDRV_PAUSE
		FUNC	MCDRV_CONT
		FUNC	MCDRV_STOP
		FUNC	MCDRV_FADEOUT
		FUNC	MCDRV_SKIP
		FUNC	MCDRV_SLOW


*==================================================
* MCDRV ローカルワークエリア
*==================================================

		.offset	DRV_WORK
MC_BUF		.ds.l	1
MC_KEYONBUF	.ds.l	1
MC_KEYONOFST	.ds.w	1
		.text


*==================================================
* MCDRV 構造体定義
*==================================================


MCDRV		macro	callname
		moveq.l	#callname,d0
		trap	#4
		endm

_RELEASE	equ	$00
_TRANSMDC	equ	$01
_PLAYMUSIC	equ	$02
_TRANSPCM	equ	$03
_PAUSEMUSIC	equ	$04
_STOPMUSIC	equ	$05
_GETWORKPTR	equ	$06
_GETTRACKSTAT	equ	$07	*使用禁止
_GETVCTTBLADR	equ	$08
_GETKEYONPTR	equ	$09
_GETCURDATAPTR	equ	$0a
_GETPLAYFLG	equ	$0b
_SETTRANSPOSE	equ	$0c
_GETLOOPCOUNT	equ	$0d
_GETNOWCLOCK	equ	$0e
_GETTITLE	equ	$0f
_GETCOMMENT	equ	$10
_INTEXEC	equ	$11
_SETSUBEVENT	equ	$12
_UNREMOVE	equ	$13
_FADEOUT	equ	$14
_SETPARAM	equ	$15
_GETTEMPO	equ	$16
_GETPASSTIME	equ	$17
_SKIPPLAY	equ	$18



*============================================================
*		トラックワーク (256 byte)
*============================================================

*============================================================
*		トラックワーク (256 byte)
*============================================================

ACTIVE:		equ	$00	*.b トラックアクティビティ	-1=kill 0=active
WAITSIGNAL:	equ	$01	*.b トラック間通信		-1=wait 0=normal
MUTEMARK:	equ	$02	*.b 7:MUTE 6:LOCK 5:NORM 4:SE 3～0:unuse
CURCH:		equ	$03	*.b 物理ch.	0～7:OPM 10～1f:ADPCM 80～:MIDI ff:dummy
NOWPITCH:	equ	$04	*.w 現在のピッチ
	*	equ	$06	*.b 
NOWVOLUME:	equ	$07	*.b 現在のボリューム
EVENT:		equ	$08	*.w 各種イベント
STEP:		equ	$0a	*.w ステップタイムカウンター
PARAMCHGJOBADR:	equ	$0c	*.l パラメータ変更処理アドレス
PARAMCHG:	equ	$10	*.w パラメータ変更要求フラグ
WASPITCH:	equ	$12	*.w 過去のピッチ
WASVOLUME:	equ	$14	*.w 過去のボリューム
NEXTTRLINK:	equ	$16	*.w 後方へのトラックリンク
	*	equ	$18	*.l 未使用エリア
MMLPTR:		equ	$1c	*.l 次の命令のアドレス
BANKMSB:	equ	$20	*.b 音色バンク上位
MC_PROGRAM:	equ	$21	*.b 音色番号
VOLMST:		equ	$22	*.b ボリューム設定値
PANMST:		equ	$23	*.b 128段階パンポット
MC_BEND:	equ	$24	*.w ベンド値
CREVERB:	equ	$26	*.b リバーブ値
CCHORUS:	equ	$27	*.b コーラス値
NOWBAR:		equ	$28	*.w 現在の小節番号
NOWSTEP:	equ	$2a	*.b 現在のステップ (何命令実行したか)
MVOLMST:	equ	$2b	*.b マスターボリューム値
BANKLSB:	equ	$2c	*.b 音色バンク下位
BENDRANGE:	equ	$2d	*.b ベンドレンジ
MODMST:		equ	$2e	*.b モジュレーション
PHONS:		equ	$2f	*.b 発音数
WASPARAMCHG:	equ	$3c	*.l パラメータ変更フラグ(外部同期用)
		.offset	$40	* 以下外部からの参照＆使用禁止
PROGRAMBANK:	ds.l	1	* OPM 音色データへのポインタ
BFTRLINK:	ds.w	1	* 前方へのトラックリンク
GTTRLINK:	ds.w	1	* ゲートカウンタトラックリンクの先頭
CHTRLINK:	ds.w	1	* チャンネル毎のトラックリンク
DETUNE:		ds.w	1	* デチューン
PCMFREQPAN:	ds.w	1	* ADPCM の再生周波数とパンポット
TIEBUF:		ds.w	1	* 過去の音からの差
WASKEYCODE:	ds.w	1	* 正規のキーコード
DELAYEVENT:	ds.w	1	* ディレイイベントのフラグ (ビットマップ)
PROGADR:	ds.l	1	* OPM 音色データへのアドレス
ADPCMBANK:	ds.w	1	* ADPCMテーブルのバンク
TIEFLAG:	ds.b	1	* タイフラグ
TIEFLAG2:	ds.b	1	* 過去のタイフラグ
UNIVFLG:	ds.b	1	* 各種フラグ (7:TIE 6:TIE2 5:SYNC 1:DS 0:DC)
CONFB:		ds.b	1	* CONNECTION/FEEDBACK
SLOTMASK:	ds.b	1	* スロットマスク
WASQUANT:	ds.b	1	* クオンタイズ指定値
QUANT:		ds.b	1	* クオンタイズ
PCMVOLUME:	ds.b	1	* PCMボリューム
SUBVOLUME:	ds.b	1	* サブボリューム

NOWVOLCMD:	ds.b	1	* ボリューム設定状態
VOLCENTER:	ds.b	1	* ボリュームセンター値
NOWMVOLCMD:	ds.b	1	* インボリューム設定状態
MVOLCENTER:	ds.b	1	* メインボリュームセンター値
NOWVELCMD:	ds.b	1	* ベロシティ設定状態
VELCENTER:	ds.b	1	* ベロシティセンター値
VELMST:		ds.b	1	* ベロシティ設定値
PANCENTER:	ds.b	1	* パンポットセンター値
NOWPANCMD:	ds.b	1	* パンポット設定状態

OPMPAN:		ds.b	1	* OPMパンポット(0～3)
TRKEYSHIFT:	ds.b	1	* キーシフト値
MHSYNC:		ds.b	1	* ハードＬＦＯのシンクロ有無
MHAMSPMS:	ds.b	1	* ハードＬＦＯ感度
CARRIER:	ds.b	1	* OPM キャリアの位置 (b7:op1 ～ b4:op4)
VOLMAP1:	ds.b	1	* OPM ボリュームの設定値マップ
VOLMAP2:	ds.b	1
VOLMAP3:	ds.b	1
VOLMAP4:	ds.b	1
		.even
TRLVL:		ds.b	1	* トラックレベル
TRPRI:		ds.b	1	* トラックプライオリティ

		.offset	$80
MP_JOBADR:	ds.l	1	* 音程LFOの処理アドレス		波形メモリ時
MP_SPDC:	ds.w	1	*	スピードカウンタ
MP_DPTA:	ds.l	1	*	加算する変移		波形先頭アドレス
MP_DPTD:	ds.l	1	*	現在ピッチ
MP_DPTM:	ds.l	1	*	初期変移
MP_SPDF:	ds.w	1	*	最初にロードするスピード
MP_SPDS:	ds.w	1	*	２回目以降にロードするスピード
MP_SPD:		ds.w	1	*	スピード (1/4波長)
MP_DPT:		ds.w	1	*	振幅
MA_JOBADR:	ds.l	1	* 音量LFOの処理アドレス
MA_SPDC:	ds.w	1	*	スピードカウンタ
MA_DPTA:	ds.l	1	*	加算する変移
MA_DPTD:	ds.l	1	*	現在ピッチ
MA_DPTM:	ds.l	1	*	初期変移
MA_DPTI:	ds.l	1	*	初期ピッチ
MA_SPDS:	ds.w	1	*	ロードするスピード
MA_SPD:		ds.w	1	*	スピード (1/4波長)
MA_DPT:		ds.w	1	*	振幅
MP_WAVE:	ds.b	1	*	波形番号
MA_WAVE:	ds.b	1	*	波形番号
		.even

MZ_WAVE:	ds.b	1	*	波形番号
MZ_CNTR:	ds.b	1	*	コントロール値
MP_DLY:		ds.w	1	* 各種ディレイ設定値 ****************************
MA_DLY:		ds.w	1
MZ_DLY:		ds.w	1
MH_DLY:		ds.w	1
PORTDLY:	ds.w	1
APANDLY:	ds.w	1

REPEATDEPTH:	ds.b	1	* 
REPEATSTAT:	ds.b	9	* ループネスト
REPEXITFLG:	ds.w	1	* ループ終了マーク

PORTSTEP:	ds.w	1	* ポルタメントのステップ値
PORTDELTA:	ds.l	1	* ポルタメントの増加量
PORTDELTA2:	ds.l	1	* ポルタメントの現在ピッチ
STEP2:		ds.l	1	* ステップカウント全体
STEP3:		ds.l	1	* ステップカウント積算カウンタ

SAMEMEASBUF:	ds.l	1	* セームメジャー用バッファ
JUMPSTACK:	ds.l	4	* ジャンプ元退避バッファ
JUMPSTACKPTR:	ds.b	1	* ジャンプ元退避バッファ用ポインタ

		.even
TRACKKIND:	equ	$fe	*.b トラック種類
NUMOFTRACK:	equ	$ff	*.b トラック番号
TRACKWORKSIZE:	equ	$100


*============================================================
*		システムワーク構造
*============================================================

SYSTEMWORKSIZE:	equ	4096+512

		.offset	0-SYSTEMWORKSIZE
CHTRLINKBUF:	ds.w	256		* チャンネルトラックリンクバッファ
SYSTEMWORK:	ds.w	1		* アクティブリストダミー
GTTOP:		ds.w	1
		ds.w	1
		ds.w	1		* トラックリンクダミー
		ds.w	1
		ds.w	1		* 空リストダミー
GTEMP:		ds.w	1
		ds.w	1
GTBUF:		ds.b	16*128		* ゲートタイム管理バッファ
OPMCHSTAT:	ds.b	1		* OPM キーオンバッファ
		ds.b	1
ADPCMCHSTAT:	ds.w	1		* ADPCM キーオン状態
		ds.w	5
MCKEYONPTR:	ds.w	1		* キーオン情報	(FIFO POINTER)
MCKEYONBUF:	ds.b	256*4		*		(FIFO BUFFER)
OPMCHKC:	ds.b	8		* OPMのチャンネル毎のキーコード
OPMCHKF:	ds.b	8		* OPMのチャンネル毎のキーフラクション
OPMCHTRLK:	ds.w	8		* OPM使用チャンネルリンク
OPMCHVELO:	ds.b	8
PAUSEMARK:	ds.w	1		* ポーズマーク
DIVISION:	ds.w	1		* ４分音符あたりのクロック数
TRUETEMPO:	ds.w	1		* データ直接のテンポ
TEMPO:		ds.w	1		* 音楽的テンポ
WASTEMPO:	ds.w	1		* 過去のテンポ
TEMPOSNS:	ds.w	1		* テンポの感度
TRACKNUM:	ds.w	1		* トラック数		(default 64 trk)
TRACKUSE:	ds.w	1		* 使用トラック数
*	OFFSET		+0	+4	+8	+12
*	TRACK(=BIT)	127～96	95～64	63～32	31～0
TRACKFLGSZ:	ds.w	1		* トラックフラグサイズ	(現在４固定)
PLAYTRACKFLG:	ds.l	4		* 演奏トラックフラグ	(外部参照用)
TRACKMASK:	ds.l	4		* トラックマスクフラグ	(外部参照用)
TRACKACT:	ds.l	4		* 永久ループ感知用	(Main演奏のみ使用する)
FSTTR:		ds.w	1		* 最初のトラック
FSTTRSE:	ds.w	1		* SE演奏最初のトラック
GTTOPSE:	ds.l	1		* SE用ゲートカウンタ
COMMENTADR:	ds.l	1		* コメントのアドレス
RANDOMESEED:	ds.l	1		* 乱数種
CURMDCADR:	ds.l	1		* MDC の先頭アドレス
CURMDCSIZE:	ds.l	1		* 	    サイズ
CURPCMADR:	ds.l	1		* PCM の先頭アドレス
CURPCMSIZE:	ds.l	1		* 	    サイズ
TRANSMDCBUF:	ds.l	1		* MDC 転送ルーチン用のバッファ
TRANSPCMBUF:	ds.l	1		* PCM 転送ルーチン用のバッファ
EXCSENDWAIT:	ds.w	1		* エクスクルーシブ送信ウェイト
EXCSENDPTR:	ds.l	1		* データポインタ
PLAYMODE:	ds.l	1		* 演奏処理へのアドレス
FPITCH:		ds.l	1
FDELTA:		ds.l	1
FLVL:		ds.w	1

FADEPITCH:	ds.w	1		* フェードピッチ
FADELVL:	ds.w	1		* フェードレベル
FADELVLS:	ds.w	1		* フェードレベル合計
OPMFADELVL:	ds.w	1		* 内蔵音源用のフェードレベル
FADECOUNT:	ds.w	1
FADEMODE:	ds.w	1
FADESELECT:	ds.w	1		* MUSIC/SE どちらにフェード処理を適用するか
MASTERVOLMST:	ds.w	1		* マスターボリューム設定値
MASTERVOL:	ds.w	1		* マスターボリューム
WASMASTERVOL:	ds.w	1		* 過去のマスターボリューム
SRCHMEAS:	ds.w	1		* サーチメジャー
JUMPDELTA:	ds.l	1		* 演奏のジャンプ
JUMPDELTAX:	ds.w	1		* 実際のジャンプステップ
LOOPCOUNTER:	ds.w	1		* ループカウンター
LOOPCLOCK:	ds.l	1		* ループ時のクロック
ENDCLOCK:	ds.l	1		* 演奏終了のクロック
NOWCLOCK:	ds.l	1		* 現在の経過クロック
INTSPACE:	ds.l	1		* 割り込み間隔 (単位μs)
PASSTIMEC:	ds.l	1		* 1/10^6秒カウンタ (初期値1000000-1)
PASSTIME:	ds.l	1		* 経過時間(hw:分 lw:秒)
BUFSIZE:	ds.l	1		* バッファサイズ	(default 320 kB)
BUFPTR:		ds.l	1		* バッファポインタ
INTEXECNUM:	ds.w	1		* _INTEXEC 登録数
INTEXECBUF:	ds.l	8		* _INTEXEC 用のバッファ
SUBEVENTNUM:	ds.w	1		* 何個のサブイベントが登録されているか
SUBEVENTADR:	ds.l	8		* _SETSUBEVENT アドレスバッファ
SUBEVENTID:	ds.l	8		* _SETSUBEVENT IDバッファ
WASRSVCT:	ds.l	8		* VECTOR $58～$5F の初期値 (SCC)
WASMIDIBVCT:	ds.l	8		* VECTOR $80～$8E の初期値 (MIDI BOARD #1)
WASMIDIBVCT2:	ds.l	8		* VECTOR $90～$9E の初期値 (MIDI BOARD #2)
WASOPMVCT:	ds.l	1		* OPM割り込みベクタ
WASTRAP4:	ds.l	1		* 過去のTRAP4ベクタ
NOWTRAP4:	ds.l	1		* 常駐解除チェック用
WASTRAP2:	ds.l	1		* PCM8 常駐禁止用
UNREMOVEFLG:	ds.w	1		* 常駐解除制御

TIMERAWORK:	ds.w	1		* TIMER-A 分周モード用ワーク
TIMERAWAIT:	ds.w	1		* TIMER-A 分周モード用ウェイト
TIMERBWORK:	ds.w	1		* TIMER-A 分周モード用ワーク
TIMERBWAIT:	ds.w	1		* TIMER-A 分周モード用ウェイト
ADPCMNAME:	ds.b	96		* 現在のADPCMデータ名
MIDIFIFOB1:	ds.l	1
MIDIFIFOB2:	ds.l	1
RSMIDIBUF:	ds.l	1
MIDIFIFOPP:	ds.l	1
CURMIDIBUF:	ds.l	1
MIDICHPRI:	ds.l	1		* MIDI デバイスプライオリティ

		.offset	-256-64
WASDMA3DONE:	ds.l	1
NOWDMA3DONE:	ds.l	1
WASDMA3ERR:	ds.l	1
NOWDMA3ERR:	ds.l	1
WASDMA3NIV:	ds.b	1
WASDMA3EIV:	ds.b	1

NEXTADPDATA:	ds.w	1		* ダミー (movem を使うので動かさないように)
NEXTADPMODE:	ds.w	1		* 次ＡＤＰＣＭ予約情報
NEXTADPd1:	ds.l	1
NEXTADPd2:	ds.l	1
NEXTADPa1:	ds.l	1

CONTADPd2:	ds.l	1
CONTADPa1:	ds.l	1

ADPNEXTF:	ds.b	1		* 次動作指定フラグ($00:指定なし $01:継続動作 $FF:予約あり)
ADPPLAYF:	ds.b	1		* ADPCM動作フラグ ($00:停止中 $0?:動作中 $FF:$80*26data)
ADPPAUSEF:	ds.b	1		* ADPCMポーズフラグ
ADPCMBUSY:	ds.b	1		* ADPCM BUSY (マルチゲインADPCM用)

		.offset	-256		* フラグエリア
MASTERVOLUME_:	ds.b	1		* マスターボリューム
MASTERTP:	ds.b	1		* マスターキートランスポーズ
USERTP:		ds.b	1		* ユーザーキートランスポーズ
KEYTRANSPOSE:	ds.b	1		* キートランスポーズ
ONDATA:		ds.b	1		* バッファ内にデータがあるか 0=無い
PCMON:		ds.b	1		* 
PCM8ON:		ds.b	1		* PCM8 が常駐しているか?
CANMIDIOUTD:	ds.b	1		* 出力可能な MIDI デバイス
					* b7:BOARD1 b6:BOARD2 b5:RSMIDI b4:POLYPHONE
MIDIBOARDON:	ds.b	1		* MIDI ボードが実装されているか
POLYPHONON:	ds.b	1		* POLYPHONON ボードが実装されているか
RSMIDI:		ds.b	1		* RSMIDI モードか
MHWAVEFORM:	ds.b	1		*
MHLFREQ:	ds.b	1
MHPMD:		ds.b	1
MHAMD:		ds.b	1
NEWHLFOFLG:	ds.b	1
ANOTHERTIMMD:	ds.b	1		* 裏タイマーモード
OPMSTAT:	ds.b	1		* OPM割り込み発生状況
TEMPOGAP:	ds.w	1		* テンポずれ検出用フラグ
NOWINTMASK:	ds.b	1		* 割り込みする前の割り込みレベル
KBCTRLSEL:	ds.b	1		* キーボードコントロール禁止 = -1
KBXF:		ds.w	1		* XF4/XF5の状態
KB80E:		ds.b	1		* SHIFT CTRL OPT1 OPT2 の状態
PCMTYPE:	ds.b	1		* 0:PDX 1:ZPD 2:PDN
INJUMP:		ds.b	1		* ジャンプ中フラグ
RESTARTDATA:	ds.b	1		* 
SEPRI:		ds.b	1		* 効果音の最高レベル
		.offset	0
TRACKWORK:	ds.b	TRACKWORKSIZE*64	* トラックバッファ
TRACKWORKASIZE:

WORKAREASIZE:	equ	SYSTEMWORKSIZE+TRACKWORKASIZE


		.text
		.even


*==================================================
* MCDRV 常駐チェック
*==================================================

MCDRV_CHECK:
		move.l	a0,-(sp)
		move.l	$24*4.w,a0
		cmp.l	#"-MCD",-12(a0)
		bne	not_keeped
		cmp.l	#"RV0-",-8(a0)
		bne	not_keeped
		move.l	-4(a0),d0
		cmpi.l	#$00130000,d0		* バージョンチェック
		bcc	keeped
not_keeped:
		moveq.l	#-1,d0
keeped:
		move.l	(sp)+,a0
		rts


*==================================================
* MCDRV ドライバ名取得
*==================================================

MCDRV_NAME:
		move.l	a0,-(sp)
		lea	name_buf(pc),a0
		move.l	a0,d0
		move.l	(sp)+,a0
		rts

name_buf:	.dc.b	'MCDRV',0
		.even

*==================================================
* MCDRV ドライバ初期化
*==================================================

MCDRV_INIT:
		movem.l	d0/a0-a1,-(sp)
		MCDRV	_GETKEYONPTR
		movea.l	d0,a0
		move.l	a0,MC_KEYONBUF(a6)
		move.w	(a0),d0
		move.w	d0,MC_KEYONOFST(a6)

		MCDRV	_GETWORKPTR
		move.l	d0,MC_BUF(a6)
		movea.l	d0,a0

		clr.l	TRACK_ENABLE(a6)
		move.w	#202,CYCLETIM(a6)
		move.w	#77,TITLELEN(a6)

		lea	TRACK_STATUS(a6),a0	*トラック番号初期化
		moveq	#1,d0
mcdrv_init10:
		move.b	d0,TRACKNO(a0)
		lea	TRST(a0),a0
		addq.w	#1,d0
		cmpi.w	#32,d0
		bls	mcdrv_init10

		movem.l	(sp)+,d0/a0-a1
		rts


*==================================================
* MCDRV システム情報取得
*==================================================

MCDRV_SYSSTAT:
		movem.l	d0/a0,-(sp)

		MCDRV	_GETTITLE		*タイトル
		move.l	d0,SYS_TITLE(a6)

		MCDRV	_GETLOOPCOUNT		*ループカウンタ
		move.w	d0,SYS_LOOP(a6)

		MCDRV	_GETTEMPO
		move.w	d0,SYS_TEMPO(a6)	*テンポ

		movea.l	MC_BUF(a6),a0
		move.w	PAUSEMARK(a0),d1
		tst.b	d1
		sne	d0			*演奏終了フラグ
		ext.w	d0
		move.w	d0,PLAYEND_FLAG(a6)
		andi.w	#$ff00,d1
		seq	d0			*演奏中フラグ
		ext.w	d0
		move.w	d0,PLAY_FLAG(a6)

		movem.l	(sp)+,d0/a0
		rts

dummy_title:	.dc.b	0
		.even

*==================================================
* MCDRV ステータス取得
*==================================================

MCDRV_TRKSTAT:
		bsr	MCDRV_TRACK
		bsr	MCDRV_KEYON
		rts

*==================================================
*MCDRV トラック情報取得
*==================================================

MCDRV_TRACK:
		movem.l	d0-d3/d5/d7/a0-a3,-(sp)
		movea.l	MC_BUF(a6),a0
		lea	TRACK_STATUS(a6),a1
		lea	VOL_DEFALT(pc),a2
		movea.l	MC_BUF(a6),a3

		MCDRV	_GETPLAYFLG
		move.l	d0,d2

		moveq	#0,d1
		moveq	#32-1,d7
MCDRV_track10:
		bsr	get_track
		lea	$100(a0),a0
		lea	TRST(a1),a1
		addq.w	#1,d1
		dbra	d7,MCDRV_track10

		move.l	TRACK_ENABLE(a6),d0
		move.l	d2,TRACK_ENABLE(a6)
		eor.l	d2,d0
		move.l	d0,TRACK_CHANGE(a6)

		movem.l	(sp)+,d0-d3/d5/d7/a0-a3
		rts

*	a0.l <- MCDRV TRACK buffer address
*	a1.l <- TRACK_STATUS address
*	a2.l <- VOL_DEFALT address
*	a3.l <- MCDRV buffer address
*	d1.l <- TRACK_NUM
*	d2.l <- TRACK_ENABLE
*	d3.l -- break

get_track:
		moveq	#0,d5
		clr.l	STCHANGE(a1)

*		tst.b	ACTIVE(a0)
*		beq	get_track10
*		bclr	d1,d2

get_track10:
		move.b	CURCH(a0),d3			*INSTRUMENT
		tst.b	d3
		bpl	get_track11
		moveq	#0,d0			*none
		cmpi.b	#$8f,d3
		bhi	get_track13
		moveq	#3,d0			*MIDI
		bra	get_track13
get_track11:
		moveq	#1,d0
		cmpi.b	#15,d3			*FM
		bls	get_track13
		moveq	#2,d0			*ADPCM
		cmpi.b	#31,d3
		bls	get_track13
		moveq	#0,d0			*none
get_track13:	cmp.b	INSTRUMENT(a1),d0
		beq	get_track20
		move.b	d0,INSTRUMENT(a1)
		bset	#0,d5
		moveq	#0,d0
		move.w	d0,KEYOFFSET(a1)

get_track20:
		cmp.b	#3,d0
		bne	get_track30
*		move.w	PR_PITCH(a0),d0			*MIDI BEND
*		subi.w	#8192,d0
*		add.w	KEYDETUNE(a0),d0
*		add.w	MP_LFOX6(a0),d0
		move.w	WASPITCH(a0),d0
		cmp.w	BEND(a1),d0
		beq	get_track21
		move.w	d0,BEND(a1)
		bset	#1,d5
get_track21:
*		eori.w	#$5555,$e82200

		moveq	#127,d0				*MIDI PAN
		and.b	PANMST(a0),d0
		cmp.w	PAN(a1),d0
		beq	get_track50
		move.w	d0,PAN(a1)
		bset.l	#2,d5
		bra	get_track50

get_track30:
	*	move.w	DETUNE(a0),d0			*FM BEND
		move.w	WASPITCH(a0),d0
*		add.w	PR_PITCH(a0),d0
*		add.w	MP_LFOX6(a0),d0
		cmp.w	BEND(a1),d0
		beq	get_track40
		move.w	d0,BEND(a1)
		bset	#1,d5
get_track40:
		moveq	#127,d0
		and.b	PANMST(a0),d0		*FM PAN
		cmp.w	PAN(a1),d0
		beq	get_track50
		move.w	d0,PAN(a1)
		bset.l	#2,d5
get_track50:
		moveq	#0,d0				*PROGRAM
		move.b	MC_PROGRAM(a0),d0
		cmp.w	PROGRAM(a1),d0
		beq	get_track90
		move.w	d0,PROGRAM(a1)
		bset.l	#3,d5
get_track90:
		move.b	d5,STCHANGE(a1)
		rts



*==================================================
*MCDRV キーＯＮ情報取得
*==================================================


TRK_NUM		equ	32


MCDRV_KEYON:
		movem.l	d0-d4/a0-a4,-(sp)

		lea	TRACK_STATUS(a6),a2

		movea.l	a2,a0				*TRACK_STATUSクリア
*		moveq	#TRK_NUM-1,d0
*MCDRV_KEYON10:
*		clr.l	STCHANGE(a0)
*		lea	TRST(a0),a0
*		dbra	d0,MCDRV_KEYON10

		movea.l	MC_KEYONBUF(a6),a1
		move.w	MC_KEYONOFST(a6),d7
		bra	MCDRV_KEYON80

MCDRV_KEYON20:
		lea	2(a1,d7.w),a0
		moveq	#0,d0
		move.b	(a0)+,d0		*track
		cmpi.w	#TRK_NUM,d0
		bcc	MCDRV_KEYON29
		mulu	#TRST,d0
		lea	(a2,d0.w),a4
		lea	KEYCODE(a4),a3
		move.b	(a0)+,d2		*note
		move.b	(a0)+,d3		*velocity
		bne	MCDRV_KEYON22

		moveq	#8-1,d0				*キーＯＦＦ
MCDRV_KEYON21:
		cmp.b	(a3)+,d2
		dbeq	d0,MCDRV_KEYON21
		bne	MCDRV_KEYON29
		subq.w	#8-1,d0
		neg.w	d0
		bset.b	d0,KEYONCHANGE(a4)
		bset.b	d0,KEYONSTAT(a4)
		bra	MCDRV_KEYON29

MCDRV_KEYON22:
		moveq	#8-1,d0				*キーＯＮ
MCDRV_KEYON23:	cmp.b	(a3)+,d2
		dbeq	d0,MCDRV_KEYON23
		bne	MCDRV_KEYON24
		subq.w	#8-1,d0				*同じ音があったら、そこをＯＦＦ
		neg.w	d0
		bset.b	d0,KEYONCHANGE(a4)
		bset.b	d0,KEYONSTAT(a4)
MCDRV_KEYON24	move.b	KEYONSTAT(a4),d0		*キーＯＦＦの音を探してＯＮする
		moveq	#8-1,d4
MCDRV_KEYON25:	lsr.b	#1,d0
		dbcs	d4,MCDRV_KEYON25
		bcc	MCDRV_KEYON26
		moveq	#8-1,d0
		sub.w	d4,d0
		bra	MCDRV_KEYON27
MCDRV_KEYON26:	moveq	#0,d0				*キーＯＦＦの音が無い
MCDRV_KEYON27:
		bset.b	d0,KEYONCHANGE(a4)
		bclr.b	d0,KEYONSTAT(a4)
		bset.b	d0,KEYCHANGE(a4)
		move.b	d2,KEYCODE(a4,d0.w)
		cmp.b	VELOCITY(a4,d0.w),d3
		beq	MCDRV_KEYON29
		bset.b	d0,VELCHANGE(a4)
		move.b	d3,VELOCITY(a4,d0.w)


MCDRV_KEYON29:
		addq.w	#4,d7
		andi.w	#$03ff,d7
MCDRV_KEYON80:
		cmp.w	(a1),d7
		bne	MCDRV_KEYON20

		move.w	d7,MC_KEYONOFST(a6)
		movem.l	(sp)+,d0-d4/a0-a4
		rts


*==================================================
* MCDRV 演奏トラック調査
*	d0 -> トラックフラグ
*==================================================

MCDRV_GETMASK:
		move.l	d1,-(sp)
		MCDRV	_GETPLAYFLG
		move.l	(sp)+,d1
		rts


*==================================================
* MCDRV 演奏トラック設定
*	d1 <- トラックフラグ
*==================================================

MCDRV_SETMASK:
		rts

*==================================================
*拡張子テーブル
*==================================================

MCDRV_FILEEXT:
		move.l	a0,-(sp)
		lea	ext_buf(pc),a0
		move.l	a0,d0
		move.l	(sp)+,a0
		rts

ext_buf:	.dc.b	_MDX,'MDX'
		.dc.b	_MDR,'MDR'
		.dc.b	_RCP,'RCP'
		.dc.b	_RCP,'R36'
		.dc.b	_MID,'MID'
		.dc.b	_STD,'STD'
		.dc.b	_MFF,'MFF'
		.dc.b	_SMF,'SMF'
		.dc.b	_ZMS,'ZMS'
		.dc.b	_OPM,'OPM'
		.dc.b	_ZDF,'ZDF'
		.dc.b	_MDF,'MDF'

		.dc.b	0
		.even


*==================================================
*曲データ読み込みルーチン
*	a1.l <- ファイルネーム
*	d0.b <- 演奏データの識別コード
*	d0.l -> 負ならエラー
*==================================================

MCDRV_FLOADP:
		move.l	a1,-(sp)
		cmpi.b	#_MDX,d0
		beq	floadp_mdx
		cmpi.b	#_MDR,d0
		beq	floadp_mdx
		cmpi.b	#_RCP,d0
		beq	floadp_rcp
		cmpi.b	#_R36,d0
		beq	floadp_rcp
		cmpi.b	#_ZMS,d0
		beq	floadp_zms
		cmpi.b	#_OPM,d0
		beq	floadp_zms
		cmpi.b	#_MID,d0
		beq	floadp_smf
		cmpi.b	#_STD,d0
		beq	floadp_smf
		cmpi.b	#_MFF,d0
		beq	floadp_smf
		cmpi.b	#_SMF,d0
		beq	floadp_smf
		cmpi.b	#_ZDF,d0
		beq	floadp_mmcp
		cmpi.b	#_MDF,d0
		beq	floadp_mmcp

		move.l	(sp)+,a1
		moveq	#-1,d0
		rts

floadp_mdx:
		lea	mdx2mdc_name(pc),a0
		bsr	CALL_PLAYER
		bra	floadp90

floadp_rcp:
		lea	rcp2mdc_name(pc),a0
		bsr	CALL_PLAYER
		bra	floadp90

floadp_smf:
		lea	smf2mdc_name(pc),a0
		bsr	CALL_PLAYER
		bra	floadp90

floadp_zms:
		lea	zms2mdc_name(pc),a0
		bsr	CALL_PLAYER
		bra	floadp90

floadp_mmcp:
		lea	mmcp_name(pc),a0
		bsr	CALL_PLAYER
		bra	floadp90

floadp90:
*		move.l	d0,-(sp)
*		bsr	MCDRV_STOP
*		bsr	MCDRV_PLAY
*		move.l	(sp)+,d0
		move.l	(sp)+,a1
		rts

mdx2mdc_name:	.dc.b	'MDX2MDC.R',0
rcp2mdc_name:	.dc.b	'RCP2MDC.R',0
smf2mdc_name:	.dc.b	'SMF2MDC.R',0
zms2mdc_name:	.dc.b	'ZMS2MDC.R',0
mmcp_name:	.dc.b	'MMCP.R',0
		.even


*==================================================
* MCDRV 演奏開始
*==================================================

MCDRV_PLAY:
		MCDRV	_STOPMUSIC
		MCDRV	_PLAYMUSIC
		rts


*==================================================
* MCDRV 演奏中断
*==================================================

MCDRV_PAUSE:
		MCDRV	_PAUSEMUSIC
		rts


*==================================================
* MCDRV 演奏再開
*==================================================

MCDRV_CONT:
		MCDRV	_PAUSEMUSIC
		rts


*==================================================
* MCDRV 演奏停止
*==================================================

MCDRV_STOP:
		MCDRV	_STOPMUSIC
		rts


*==================================================
* MCDRV フェードアウト
*==================================================

MCDRV_FADEOUT:
		move.l	d1,-(sp)
		moveq	#10,d1
		MCDRV	_FADEOUT
		move.l	(sp)+,d1
		rts


*==================================================
* MCDRV スキップ
*	d0.w <- スキップ開始フラグ
*==================================================

MCDRV_SKIP:	move.l	d1,-(sp)
		moveq.l	#12,d1
		MCDRV	_SKIPPLAY
		move.l	(sp)+,d1
		rts


*==================================================
* MCDRV スロー
*	d0.w <- スロー開始フラグ
*==================================================

MCDRV_SLOW:
		rts

		.end


