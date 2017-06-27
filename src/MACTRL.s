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
* MADRV エントリーテーブル
*==================================================

		.xdef	MADRV_ENTRY

FUNC		.macro	entry
		.dc.w	entry-MADRV_ENTRY
		.endm

MADRV_ENTRY:
		FUNC	MADRV_CHECK
		FUNC	MADRV_NAME
		FUNC	MADRV_INIT
		FUNC	MADRV_SYSSTAT
		FUNC	MADRV_TRKSTAT
		FUNC	MADRV_GETMASK
		FUNC	MADRV_SETMASK
		FUNC	MADRV_FILEEXT
		FUNC	MADRV_FLOADP
		FUNC	MADRV_PLAY
		FUNC	MADRV_PAUSE
		FUNC	MADRV_CONT
		FUNC	MADRV_STOP
		FUNC	MADRV_FADEOUT
		FUNC	MADRV_SKIP
		FUNC	MADRV_SLOW


*==================================================
* MADRV ローカルワークエリア
*==================================================

		.offset	DRV_WORK
MA_BUF		.ds.l	1
SLOW_TEMPO	.ds.b	1
ORIG_TEMPO	.ds.b	1
		.text


MADRV		.macro	func
		moveq	func,d0
		TRAP	#4
		.endm

*==================================================
* MADRV 構造体定義
*==================================================

			.offset	0
MA_CM0		.ds.w	3		*TRANSFER_PCMDATA	*データ転送/スタンバイ
MA_CM1		.ds.w	3		*TRANSFER_MMLDATA	*データ転送/スタンバイ
MA_CM2		.ds.w	3		*PLAY_MUSIC		*演奏開始
MA_CM3		.ds.w	3		*STOP_MUSIC		*演奏停止
MA_CM4		.ds.w	3		*CONTINUE_MUSIC		*演奏再開
MA_CM5		.ds.w	3		*SET_TITLE		*タイトル等をコピーする
MA_CM6		.ds.w	3		*GET_TITLE		*タイトルを取り出す
MA_CM7		.ds.w	3		*GET_STATUS		*演奏状態を取り出す
MA_CM8		.ds.w	3		*RELEASE		*常駐解除
MA_CM9		.ds.w	3		*FADEOUT		*フェードアウト実行
MA_CM10		.ds.w	3		*GETWORKPTR		*WORKAREAへのPOINTER取出
MA_CM11		.ds.w	3		*GETCLOCK		*クロック取り出し
MA_CM12		.ds.w	3		*GETPCMPTR		*PCMBUFFERへのPOINTER取出
MA_CM13		.ds.w	3		*SETPCMPTR		*PCMBUFFERへPOINTER設定
MA_CM14		.ds.w	3		*SETFADE		*フェードアウト設定・禁止
MA_CM15		.ds.w	3		*SETINT			*OPM割り込みチェイン設定
MA_CM16		.ds.w	3		*UNREMOVE		*常駐解除禁止
MA_CM17		.ds.w	3		*STOPSIGNAL		*停止シグナル送信
MA_CM18		.ds.w	3		*GETMMLPTR		*MMLBUFFERへのPOINTER取出
MA_CM19		.ds.w	3		*SETMMLPTR		*MMLBUFFERへPOINTER設定
MA_CM20		.ds.w	3		*KEYBOARDCTRL		*1.07から追加
MA_CM21		.ds.w	3		*SETMASK
MA_CM22		.ds.w	3		*GETPCMFILE
MA_CM23		.ds.w	3		*FADEONETIME
MA_CM24		.ds.w	3		*GETLOOPCOUNTER
MA_CM25		.ds.w	3		*SETPRW
MA_CM26		.ds.w	3		*GETPCMFRAME
MA_CM27		.ds.w	3		*GETMMLFRAME


*
*	トラックワークエリア
*
		.offset	0
TRKPTR		ds.l	1	*トラックロケーションカウンタ
TRACKACT	ds.b	1	*トラックアクティビティフラグ
TRACKSIGNAL	ds.b	1	*シグナルフラグ
PCMBANK		ds.l	1	*PCM用バンクレジスタ
MAKEYCODE	ds.l	1	*キーコードバッファ	KEYCODE -> MAKEYCODE
KEYDETUNE	ds.l	1	*デチューン現在値
PR_PITCH	ds.l	1	*ポルタメント現在ピッチ
PR_MPITCH	ds.l	1	*ポルタメントピッチ
WASKEY		ds.w	1	*以前のキー値
NOWVOLUME	ds.w	1	*現在のボリューム
WAS_VOL		ds.w	1	*過去のボリューム
VOLUMESETJOB	ds.l	1	*音量設定処理アドレス
VOLUMEMAP	ds.b	4	*ボリューム設定値マップ
MPLFOJOB	ds.l	1	*ＬＦＯ処理アドレス
MPLFOJOB2	ds.l	1	*ＬＦＯ処理アドレス
MALFOJOB	ds.l	1	*ＬＦＯ処理アドレス
MALFOJOB2	ds.l	1	*ＬＦＯ処理アドレス
MP_LFOX0	ds.l	1	*LFO用ワークエリア
MP_LFOX1	ds.l	1	*
MP_LFOX2	ds.l	1	*
MP_LFOX3	ds.l	1	*
MP_LFOX4	ds.l	1	*
MP_LFOX5	ds.l	1	*
MP_LFOX6	ds.l	1	*
MA_LFOX0	ds.w	1	*LFO用ワークエリア
MA_LFOX1	ds.w	1	*
MA_LFOX2	ds.w	1	*
MA_LFOX3	ds.w	1	*
MA_LFOX4	ds.w	1	*
MA_LFOX5	ds.w	1	*
PCMFREQPAN	ds.w	1	*PCM周波数・音程 (PCM8用)
MASINPT		ds.w	1	*サイン波ＬＦＯカウンター
MZSINPT		ds.w	1	*
PROGRAM_PTR	ds.l	1	*プログラムへのポインタ
SEQDELTA	ds.b	1	*シーケンス・デルタタイマー
MH_SYNC		ds.b	1	*シンクロ有無(全体へ)
MH_AMSPMS	ds.b	1	*PMS/AMS(音色へ)
LFODELAY	ds.b	1	*LFOディレイ
LFODELTA	ds.b	1	*LFOタイマー
LFOACTIVE	ds.b	1	*LFOアクティベート
LFOMOTOR	ds.b	1	*LFOモーター
MPMOTOR		ds.b	1	*MPモーター	0:停止	1:動作
MAMOTOR		ds.b	1	*MAモーター	0:停止	1:動作
KEYONDELAY	ds.b	1	*キーオン・ディレイ
KEYONDELTA	ds.b	1	*キーオン・タイマー
KEYONMOTOR	ds.b	1	*キーオン・モーター
KEYOFGATE	ds.b	1	*キーオフ・ゲートタイム(@q用)
KEYOFDELTA	ds.b	1	*キーオフ・タイマー
KEYOFMOTOR	ds.b	1	*キーオフ・モーター
KEYONSIGNE	ds.b	1	*キーオン時に書き込む内容
NOWFLCON	ds.b	1	*FL&CON
NOWPAN		ds.b	1	*現在のパンポット
NOWVOLX		ds.b	1	*パンポット変移バッファ
PCMKEY		ds.b	1	*キーコード（ＭＭＬで記述される値）
WASPCMPAN	ds.b	1	*キーコード変移バッファ
KEYONFLAG	ds.b	1	*キーオンフラグ
CURPROG		ds.b	1	*プログラムチェンジバッファ
CURPROGNEW	ds.b	1	*プログラムチェンジ変移バッファ
KEYONWORK	ds.b	1	*キーオンワーク
EVENTWORK	ds.b	1	*イベントフラグワーク
CHVOL		ds.b	1	*チャンネル主音量
CHVOL_WORK	ds.b	1	*NOWVOLUME・保存値
REALTL		ds.l	1	*ディストーションワーク
REALTLWAS	ds.l	1	*ディストーション変移バッファ
DISTLVL		ds.b	1	*ディストーションレベル
WAS_MALFOX5	ds.b	1	*ＬＦＯ変移ワーク
DISTJOB		ds.l	1	*ディストーション処理アドレス
LFODELAY_A	ds.b	1	*LFOディレイ
LFODELTA_A	ds.b	1	*LFOタイマー
LFOACTIVE_A	ds.b	1	*LFOアクティベート
LFOMOTOR_A	ds.b	1	*LFOモーター
LFODELAY_Z	ds.b	1	*LFOディレイ
LFODELTA_Z	ds.b	1	*LFOタイマー
LFOACTIVE_Z	ds.b	1	*LFOアクティベート
LFOMOTOR_Z	ds.b	1	*LFOモーター
LFOINUSE	ds.l	1	*LFO処理フラグ用
MZ_LFOX0	ds.w	1	*LFO用ワークエリア
MZ_LFOX1	ds.w	1	*
MZ_LFOX2	ds.w	1	*
MZ_LFOX3	ds.w	1	*
MZ_LFOX4	ds.w	1	*
MZ_LFOX5	ds.w	1	*
MZMOTOR		ds.b	1	*ディストーションデルタカウンタ
DISTOFS		ds.b	1	*ディストーションオフセット
MZLFOJOB	ds.l	1	*ディストーション処理アドレス
MZLFOJOB2	ds.l	1	*
JMPTBLPTR	ds.l	1	*ジャンプテーブルへのアドレス
KEYONJOB	ds.l	1	*キーオン処理アドレス
CURCH		ds.w	1	*グローバルデバイス(出力先)
WASPCMKEY	ds.b	1	*キーコード変移保存ワーク
WAS_VOLF	ds.b	1	*音量変移ワーク
CTRLUNIT	ds.b	1	*デバイスチャンネル
NEWPAN		ds.b	1	*パンポット変移ワーク
BEND_SNS	ds.w	1	*ベンド感度
GLCH		ds.w	1	*システムチャンネル(物理 $00～$07:OPM ～$0F:PCM $80～$8F:MIDI)
POLY_PTR	ds.w	1	*ポリフォニックノートオンポインタ
POLY_WAS	ds.w	1	*ポリフォニックノートオンポインタ
BEND_RANGE	ds.b	1	*ベンドレンジ値
NOWVELX		ds.b	1	*ベロシティ変移ワーク
MAVELOCITY	ds.b	1	*ベロシティワーク	VELOCITY -> MAVELOCITY
MIDIKEYON	ds.b	1	*MIDIキーオンバッファ
MOD_SW		ds.b	1	*モジュレーションスイッチ
MOD_SWOF	ds.b	1	*モジュレーション・オフレベル
MOD_SWON	ds.b	1	*モジュレーション・オンレベル
MOD_LVL		ds.b	1	*モジュレーション・レベル
MOD_WAS		ds.b	1	*過去のモジュレーションレベル
MOD_DELAY	ds.b	1	*ディレイ
MOD_DELTA	ds.b	1	*デルタカウンタ
POLY_KEYON	ds.b	1	*ポリフォニックキーオンフラグ(実際にキーオンしている和音数)
POLY_STACK	ds.b	32	*ポリフォニックノートオンは１６音まで
BEND_MODE	ds.b	1	*ピッチベンダ・モード
BEND_RES	ds.b	1	*ピッチベンド・レスポンスタイム
BEND_RCNT	ds.b	1	*ピッチベンド・レスポンスカウンタ
UDEVICE		ds.b	1	*MIDIグローバルデバイス(MIDI機材)
MPOFS		ds.b	1	*ポルタメントオフセット
MAOFS		ds.b	1	*アンプリチュードオフセット
MZOFS		ds.b	1	*ディストーションオフセット
		.even


*	システムワークエリア

		.offset	0
		ds.b	$100*32	*トラックワークが３２個
PROGRAM_BANK	ds.l	256	*プログラム用テーブル
TO_MMLPTR	ds.l	1	*MML領域へのポインタ
TO_PCMPTR	ds.l	1	*PCM領域へのポインタ
LEN_MMLPTR	ds.l	1	*MML領域の長さ
LEN_MMLDATA	ds.l	1	*MMLに実際に入っているデータの長さ
LEN_PCMPTR	ds.l	1	*PCM領域の大きさ
PLAYFLAG	ds.l	1	*演奏状態フラグ(b0～b15に各トラック毎に)
ONPCMFLAG	ds.b	1	*PCMがあるか？
ONMMLFLAG	ds.b	1	*MMLはあるか？
STOP_SIGNAL	ds.b	1	*停止シグナル
PAUSE_MARK	ds.b	1
PCMFNAME	ds.b	128	*PCM8.xのパスネーム
PCM8VCT		ds.l	1
FADEP		ds.w	1	*フェードアウトピッチ
FADEPITCH	ds.w	1	*ピッチモーター
FADELVL		ds.w	1	*フェードアウトレベル(負数になったら終了)
WAS_VCT0	ds.l	1	*OPMのベクタ保存
WAS_VCT1	ds.l	1
WAS_VCT2	ds.l	1
WAS_VCTA	ds.l	1
WAS_VCTB	ds.l	1
WAS_VCTC	ds.l	1
WAS_VCTD	ds.l	1
NEW_VCT0	ds.l	1
NEW_VCT1	ds.l	1
NEW_VCT2	ds.l	1
NEW_VCTA	ds.l	1
NEW_VCTB	ds.l	1
NEW_VCTC	ds.l	1
NEW_VCTD	ds.l	1
MAXTRACK:	ds.w	1	*最大トラック(0～15)
NOWCLOCK:	ds.l	1	*外部クロック出力
TO_MMLPTR2:	ds.l	1	*MDX領域へのポインタ
TO_PCMPTR2:	ds.l	1	*PCM領域へのポインタ
INT_VCT		ds.l	1	*インタラプトベクタ
ATPCMPTR	ds.l	1	*暴走対策
ADPCM_BUSY	ds.b	1
ADPCM_Y0	ds.b	1
ADPCM_FREQ	ds.b	1
ADPCM_PAN	ds.b	1
EX_PCM2:	ds.b	1	*EX-PCMフラグ
TEMPO:		ds.b	1	*テンポ保持用
EX_PCM		ds.b	1	*EX-PCMフラグ
STOPFLAG	ds.b	1
EXOPKEY1	ds.b	1
GRAM_SELECT	ds.b	1
UNREMOVE_FLAG	ds.b	1
KEYCTRLFLAG	ds.b	1
WAS_VCTI	ds.l	1	*IOCS $F0
TRACKMASK	ds.l	1	*トラックマスク
LED_COUNTER	ds.w	1
MMLTITLE:	ds.b	512	*MMLのタイトル
DENDMASK	ds.l	1	*データエンドフラグ
FADEPM		ds.w	1	*フェードアウト
INTMASK		ds.w	1
LOOP_FLAG	ds.w	1	*ループフラグ
NOW_WAVEFORM	ds.b	1	*ハードウエアLFO WAVEFORM
NOW_LFREQ	ds.b	1	*LFREQ
NOW_PMD		ds.b	1	*PMD
NOW_AMD		ds.b	1	*AMD
NEWFILE		ds.b	1	*-1;新規ファイル設定
NEWHLFO		ds.b	1	*ハードウエアLFO新規設定
OPMINT_SUBCNT	ds.b	1	*サブ割り込み制御
WASTEMPO	ds.b	1
LED_DELAY	ds.b	1
MASTER_VOL	ds.b	1	*マスターボリューム
REWIND_VOL	ds.b	1	*早送り時のボリューム
PCM_NOREL	ds.b	1	*ノーマルMDX時にPCMパートをキーオフしない
EX_MIDI		ds.b	1	*ＭＩＤＩ拡張モード(ハードウエア有無)
EX_MIDI2	ds.b	1	*ＭＩＤＩ拡張モード(ＭＩＤＩ拡張モード演奏)
		EVEN
RANDOME_SEED	ds.w	1	*乱数種
REWIND_DELTA	ds.l	1
_REPEAT_HOME	ds.l	1	*リピート開始時のクロック
_REPEAT_HOMEC	ds.l	1	*リピート開始時のループカウンタ
_REPEAT_UNDO	ds.l	1	*リピート終了時のクロック
WAS_MCSV00	ds.l	1	*ベクターバッファ(MIDI用)
WAS_MCSV01	ds.l	1
WAS_MCSV02	ds.l	1
WAS_MCSV03	ds.l	1
WAS_MCSV04	ds.l	1
WAS_MCSV05	ds.l	1
WAS_MCSV06	ds.l	1
WAS_MCSV07	ds.l	1
WAS_MCSV08	ds.l	1
SCDBS_RAW	ds.w	1	*表示桁ワーク
DISPWORK	ds.b	64	*SC55液晶ワーク
CM64_PARTRSV	ds.b	16	*パーシャルリザーブバッファ
MT32_PARTRSV	ds.b	16	*
SC55_PARTRSV	ds.b	16	*

		.text
		.even


*==================================================
* MADRV 常駐チェック
*==================================================

MADRV_CHECK:
		move.l	a0,-(sp)
		move.l	$24*4.w,a0
		cmp.l	#"*MAD",-12(a0)
		bne	not_keeped
		cmp.l	#"RV3*",-8(a0)
		bne	not_keeped
		move.l	-4(a0),d0
		cmp.l	#109*$10000+15,d0		*バージョンは
		bcc	keeped				*	１．０９ｏ以上
not_keeped:
		moveq.l	#-1,d0
keeped:
		move.l	(sp)+,a0
		rts


*==================================================
* MADRV ドライバ名取得
*==================================================

MADRV_NAME:
		move.l	a0,-(sp)
		lea	name_buf(pc),a0
		move.l	a0,d0
		move.l	(sp)+,a0
		rts

name_buf:	.dc.b	'MADRV',0
		.even

*==================================================
* MADRV ドライバ初期化
*==================================================

MADRV_INIT:
		movem.l	d0/a0,-(sp)
		MADRV	#10
		move.l	d0,MA_BUF(a6)

		clr.l	TRACK_ENABLE(a6)
		move.w	#301,CYCLETIM(a6)		*238 at 16track
		move.w	#77,TITLELEN(a6)

		lea	TRACK_STATUS(a6),a0	*トラック番号初期化
		moveq	#1,d0
madrv_init10:
		move.b	d0,TRACKNO(a0)
		lea	TRST(a0),a0
		addq.w	#1,d0
		cmpi.w	#32,d0
		bls	madrv_init10

		movem.l	(sp)+,d0/a0
		rts


*==================================================
* MADRV システム情報取得
*==================================================

MADRV_SYSSTAT:
		movem.l	d0/a0,-(sp)

		MADRV	#6				*タイトル
		move.l	a0,SYS_TITLE(a6)

		move.l	MA_BUF(a6),a0			*ループカウンタ
		move.w	LOOP_FLAG(a0),SYS_LOOP(a6)

		moveq.l	#0,d0				*テンポ
		move.b	TEMPO(a0),d0
		move.w	d0,SYS_TEMPO(a6)

		tst.l	PLAYFLAG(a0)			*演奏中フラグ
		sne.b	d0
		ext.w	d0
		move.w	d0,PLAY_FLAG(a6)

		or.b	PAUSE_MARK(a0),d0		*演奏終了フラグ
		seq	d0
*		and.b	STOPFLAG(a0),d0
		ext.w	d0
		move.w	d0,PLAYEND_FLAG(a6)

		movem.l	(sp)+,d0/a0

		rts


*==================================================
* MADRV ステータス取得
*==================================================

MADRV_TRKSTAT:
		bsr	MADRV_KBSSET
		bsr	MADRV_TRACK
		rts


*
*	＊ＭＡＤＲＶ＿ＫＢＳＳＥＴ
*機能：ＭＡＤＲＶのキーボードステータスを得る
*入出力：なし
*参考：ＣＨＳＴ＿ＢＦ＿Ｗ（ａ６）にも書くべし
*

MADRV_KBSSET:
		movem.l	d0-d1/d6-d7/a0-a3,-(sp)

		lea.l	CHST_BF(a6),a0
		move.l	MA_BUF(a6),a2
		move.l	a2,a3

		moveq.l	#7,d7
ma_kbsset_loop:
		moveq.l	#0,d6

		move.b	EVENTWORK(a3),d0		*C:ＭＰ
		btst.l	#0,d0
		sne.b	d1
		cmp.b	KBS_MP(a0),d1
		beq	ma_kbsset_jp01
		bset.l	#$C,d6
		move.b	d1,KBS_MP(a0)
ma_kbsset_jp01:
		btst.l	#1,d0				*D:ＭＡ
		sne.b	d1
		cmp.b	KBS_MA(a0),d1
		beq	ma_kbsset_jp02
		bset.l	#$D,d6
		move.b	d1,KBS_MA(a0)
ma_kbsset_jp02:
		btst.l	#2,d0				*E:ＭＨ
		sne.b	d1
		cmp.b	KBS_MH(a0),d1
		beq	ma_kbsset_jp03
		bset.l	#$E,d6
		move.b	d1,KBS_MH(a0)
ma_kbsset_jp03:
		move.b	KEYONDELAY(a3),d0		*0:ｋ
		cmp.b	KBS_k(a0),d0
		beq	ma_kbsset_jp0
		bset.l	#0,d6
		move.b	d0,KBS_k(a0)
ma_kbsset_jp0:
		move.b	KEYOFGATE(a3),d0		*1:ｑ
		cmp.b	KBS_q(a0),d0
		beq	ma_kbsset_jp2
		bset.l	#1,d6
		move.b	d0,KBS_q(a0)
ma_kbsset_jp2:
		move.w	KEYDETUNE(a3),d0		*2:Ｄ
		cmp.w	KBS_D(a0),d0
		beq	ma_kbsset_jp3
		bset.l	#2,d6
		move.w	d0,KBS_D(a0)
ma_kbsset_jp3:
		move.w	MP_LFOX6(a3),d0			*3:Ｐ
		cmp.w	KBS_P(a0),d0
		beq	ma_kbsset_jp4
		bset.l	#3,d6
		move.w	d0,KBS_P(a0)
ma_kbsset_jp4:
		move.w	PR_PITCH(a3),d0			*4:Ｂ
		cmp.w	KBS_B(a0),d0
		beq	ma_kbsset_jp5
		bset.l	#4,d6
		move.w	d0,KBS_B(a0)
ma_kbsset_jp5:
		move.b	MA_LFOX5(a3),d0			*5:Ａ
		ext.w	d0
		neg.w	d0
		cmp.w	KBS_A(a0),d0
		beq	ma_kbsset_jp6
		bset.l	#5,d6
		move.w	d0,KBS_A(a0)
ma_kbsset_jp6:
		move.l	PROGRAM_PTR(a3),d0		*6:＠
		beq	ma_kbsset_jp8
		move.l	d0,a1
		moveq.l	#0,d0
		move.b	-1(a1),d0
		cmp.w	KBS_PROG(a0),d0
		beq	ma_kbsset_jp8
		bset.l	#6,d6
		move.w	d0,KBS_PROG(a0)
ma_kbsset_jp8:
		moveq.l	#0,d0
		move.b	NOWVOLX(a3),d0			*7:＠ｖ１
		bclr.l	#7,d0
		bne	ma_kbsset_jp9
		lea.l	VOL_DEFALT(pc),a1
		move.b	0(a1,d0.w),d0
		bra	ma_kbsset_jpA
ma_kbsset_jp9:	neg.b	d0
		add.b	#$7F,d0
ma_kbsset_jpA:	cmp.b	KBS_TL1(a0),d0
		beq	ma_kbsset_jpB
		bset.l	#7,d6
		move.b	d0,KBS_TL1(a0)
ma_kbsset_jpB:
		move.b	NOWVOLUME(a3),d0		*8:＠ｖ２
		add.b	MA_LFOX5(a3),d0
		add.b	FADELVL(a2),d0
		bpl	ma_kbsset_jpZ
		moveq.l	#$7F,d0
ma_kbsset_jpZ:	neg.b	d0
		add.b	#$7F,d0
		cmp.b	KBS_TL2(a0),d0
		beq	ma_kbsset_jpC
		bset.l	#8,d6
		move.b	d0,KBS_TL2(a0)
ma_kbsset_jpC:
		move.l	TRKPTR(a3),d0			*9:ＤＡＴＡ
		cmp.l	KBS_DATA(a0),d0
		beq	ma_kbsset_jpD
		bset.l	#9,d6
		move.l	d0,KBS_DATA(a0)
ma_kbsset_jpD:
		move.b	PCMKEY(a3),d0			*A:ＫＣ１
		lsl.w	#6,d0
		cmp.w	KBS_KC1(a0),d0
		beq	ma_kbsset_jpF
		bset.l	#$A,d6
		move.w	d0,KBS_KC1(a0)
ma_kbsset_jpF:
		move.w	MAKEYCODE(a3),d0		*B:ＫＣ２
		add.w	PR_PITCH(a3),d0
		add.w	MP_LFOX6(a3),d0
		cmp.w	KBS_KC2(a0),d0
		beq	ma_kbsset_jpG
		bset.l	#$B,d6
		move.w	d0,KBS_KC2(a0)
ma_kbsset_jpG:

		move.w	d6,KBS_CHG(a0)			*チェックフラグ書き込み

		lea.l	CHST(a0),a0
		lea.l	$100(a3),a3

		dbra	d7,ma_kbsset_loop

		movem.l	(sp)+,d0-d1/d6-d7/a0-a3

		rts


*==================================================
*MADRV トラック情報取得
*==================================================

MADRV_TRACK:
		movem.l	d0-d3/d5/d7/a0-a3,-(sp)
		movea.l	MA_BUF(a6),a0
		movea.l	a0,a3
		lea	TRACK_STATUS(a6),a1
		lea	VOL_DEFALT(pc),a2

		move.l	TRACKMASK(a0),d2
		not.l	d2
		and.l	PLAYFLAG(a0),d2

		moveq	#0,d1
		moveq	#32-1,d7
madrv_track10:
		bsr	get_track
		lea	$100(a0),a0
		lea	TRST(a1),a1
		addq.w	#1,d1
		dbra	d7,madrv_track10

		move.l	TRACK_ENABLE(a6),d0
		move.l	d2,TRACK_ENABLE(a6)
		eor.l	d2,d0
		move.l	d0,TRACK_CHANGE(a6)

		movem.l	(sp)+,d0-d3/d5/d7/a0-a3
		rts

*	a0.l <- MADRV TRACK buffer address
*	a1.l <- TRACK_STATUS address
*	a2.l <- VOL_DEFALT address
*	a3.l <- MADRV buffer address
*	d1.l <- TRACK_NUM
*	d2.l <- TRACK_ENABLE
*	d3.l -- break

get_track:
		moveq	#0,d5
		clr.l	STCHANGE(a1)

		tst.b	TRACKACT(a0)
		bne	get_track10
		bclr	d1,d2

get_track10:
		move.b	CURCH(a0),d3			*INSTRUMENT
		bpl	get_track11
		moveq	#0,d0			*none
		cmpi.b	#$8f,d3
		bhi	get_track13
		moveq	#3,d0			*MIDI
		bra	get_track13
get_track11:
		moveq	#1,d0
		cmpi.b	#7,d3			*FM
		bls	get_track13
		moveq	#2,d0			*ADPCM
		cmpi.b	#15,d3
		bls	get_track13
		moveq	#0,d0			*none
get_track13:	cmp.b	INSTRUMENT(a1),d0
		beq	get_track20
		move.b	d0,INSTRUMENT(a1)
		bset	#0,d5
		cmp.b	#3,d0
		bne	get_track15
		moveq	#0,d0
		bra	get_track16
get_track15:	moveq	#15,d0
get_track16:	move.w	d0,KEYOFFSET(a1)

get_track20:
		cmp.b	#3,d0
		bne	get_track30
		move.w	PR_PITCH(a0),d0			*MIDI BEND
		subi.w	#8192,d0
		add.w	KEYDETUNE(a0),d0
		add.w	MP_LFOX6(a0),d0
		cmp.w	BEND(a1),d0
		beq	get_track21
		move.w	d0,BEND(a1)
		bset	#1,d5
get_track21:
		moveq	#127,d0				*MIDI PAN
		and.b	NOWPAN(a0),d0
		cmp.w	PAN(a1),d0
		beq	get_track50
		move.w	d0,PAN(a1)
		bset.l	#2,d5
		bra	get_track50

get_track30:
		move.w	KEYDETUNE(a0),d0		*FM BEND
		add.w	PR_PITCH(a0),d0
		add.w	MP_LFOX6(a0),d0
		cmp.w	BEND(a1),d0
		beq	get_track40
		move.w	d0,BEND(a1)
		bset	#1,d5
get_track40:
		moveq	#-1,d0				*FM PAN
		move.b	NOWPAN(a0),d0
		rol.b	#2,d0
		andi.b	#3,d0
		cmp.w	PAN(a1),d0
		beq	get_track50
		move.w	d0,PAN(a1)
		bset.l	#2,d5
get_track50:
		moveq	#0,d0				*PROGRAM
		move.b	CURPROG(a0),d0
		cmp.w	PROGRAM(a1),d0
		beq	get_track60
		move.w	d0,PROGRAM(a1)
		bset.l	#3,d5
get_track60:
		btst.l	d1,d2				*KEY ON
		beq	get_track62
		tst.b	KEYONWORK(a0)
		beq	get_track61
		clr.b	KEYONWORK(a0)
		move.b	#$01,KEYONCHANGE(a1)
		move.b	#$FE,KEYONSTAT(a1)
		bra	get_track70
get_track61:	tst.b	KEYONFLAG(a0)
		bne	get_track70
get_track62:	btst.b	#0,KEYONSTAT(a1)
		bne	get_track70
		move.b	#$01,KEYONCHANGE(a1)
		move.b	#$FF,KEYONSTAT(a1)
get_track70:
		move.b	PCMKEY(a0),d0			*KEYCODE
		cmp.b	KEYCODE(a1),d0
		beq	get_track80
		move.b	#$01,KEYCHANGE(a1)
		move.b	d0,KEYCODE(a1)
get_track80:
		move.b	NOWVOLUME(a0),d0			*VELOCITY
		add.b	MA_LFOX5(a0),d0
		add.b	FADELVL(a3),d0
		bpl	get_track81
		moveq.l	#$7F,d0
get_track81:	neg.b	d0
		add.b	#$7F,d0
get_track82:	cmp.b	VELOCITY(a1),d0
		beq	get_track90
		move.b	#$01,VELCHANGE(a1)
		move.b	d0,VELOCITY(a1)
get_track90:
		move.b	d5,STCHANGE(a1)
		rts


*==================================================
* MADRV 演奏トラック調査
*	d0 -> トラックフラグ
*==================================================

MADRV_GETMASK:
		move.l	a0,-(sp)
		move.l	MA_BUF(a6),a0
		move.l	TRACKMASK(a0),d0
		not.l	d0
		move.l	(sp)+,a0
		rts


*==================================================
* MADRV 演奏トラック設定
*	d1 <- トラックフラグ
*==================================================

MADRV_SETMASK:
		move.l	d1,-(sp)
		not.l	d1
		MADRV	#$15
		move.l	(sp)+,d1
		rts

*==================================================
*拡張子テーブル
*==================================================

MADRV_FILEEXT:
		move.l	a0,-(sp)
		lea	ext_buf(pc),a0
		move.l	a0,d0
		move.l	(sp)+,a0
		rts

ext_buf:	.dc.b	_MDX,'MDX'
		.dc.b	_MDR,'MDR'
		.dc.b	_ZDF,'ZDF'
		.dc.b	_ZMS,'ZMS'
		.dc.b	_OPM,'OPM'

		.dc.b	_PIC,'PIC'
		.dc.b	_MAG,'MAG'
		.dc.b	_PI,'PI',0
		.dc.b	_JPG,'JPG'

		.dc.b	0
		.even


*==================================================
*ＭＤＸデータ読み込みルーチン
*	a1.l <- ファイルネーム
*	d0.b <- 演奏データの識別コード
*	d0.l -> 下位word:エラー番号。
*		longが負なら演奏開始していない
*==================================================

MADRV_FLOADP:
		movem.l	d1/a1,-(sp)
		cmpi.b	#_MDX,d0
		beq	floadp_mdx
		cmpi.b	#_MDR,d0
		beq	floadp_mdx
		cmpi.b	#_ZDF,d0
		beq	floadp_zdf
		cmpi.b	#_ZMS,d0
		beq	floadp_zms
		cmpi.b	#_OPM,d0
		beq	floadp_zms


		cmpi.b	#_PIC,d0
		beq	floadp_pic

		cmpi.b	#_MAG,d0
		beq	floadp_mag

		cmpi.b	#_PI,d0
		beq	floadp_pi

		cmpi.b	#_JPG,d0
		beq	floadp_jpg

		movem.l	(sp)+,d1/a1
		moveq	#-1,d0
		rts

floadp_mdx:
		move.l	a1,-(sp)
		bsr	LOAD_MDX
		bra	floadp90
floadp_zdf:
		move.l	a1,-(sp)
		bsr	LOAD_ZDF
floadp90:
		addq.l	#4,sp
		neg.l	d0
		cmpi.w	#7,d0
		bls	floadp91
		moveq	#7,d0
floadp91:
		move.b	errcnvtbl(pc,d0.w),d1	*エラー番号変換
		ext.w	d1
		ext.l	d1
		andi.w	#$007f,d1
		bsr	MADRV_STOP		*演奏停止
		tst.l	d1
		bmi	floadp92
		bsr	MADRV_PLAY		*演奏開始
floadp92:
		move.l	d1,d0
		lea	MMDSP_NAME(pc),a0	*プレーヤ名はMMDSP
		movem.l	(sp)+,d1/a1
		rts

errcnvtbl:	.dc.b	$00,$82,$03,$85,$87,$08,$8a,$81
		.even

floadp_zms:
		lea	opm2mdr_name(pc),a0
		bsr	CALL_PLAYER
		movem.l	(sp)+,d1/a1
		rts

floadp_pic:
		st.b	VDISP_CNT(a6)
		lea	pic_name(pc),a0
		bsr	CALL_PLAYER
		clr.b	VDISP_CNT(a6)
		movem.l	(sp)+,d1/a1
		rts

floadp_mag:
		st.b	VDISP_CNT(a6)
		lea	mag_name(pc),a0
		bsr	CALL_PLAYER

		move.w	#5,-(sp)
		move.w	#16,-(sp)
		DOS	_CONCTRL
		addq.l	#4,sp

		clr.b	VDISP_CNT(a6)
		movem.l	(sp)+,d1/a1
		rts

floadp_pi:
		st.b	VDISP_CNT(a6)
		lea	pi_name(pc),a0
		bsr	CALL_PLAYER
		clr.b	VDISP_CNT(a6)
		movem.l	(sp)+,d1/a1
		rts

floadp_jpg:
		st.b	VDISP_CNT(a6)
		lea	jpg_name(pc),a0
		bsr	CALL_PLAYER
		clr.b	VDISP_CNT(a6)
		movem.l	(sp)+,d1/a1
		rts

pic_name:	.dc.b	'HAPIC -n',0
mag_name:	.dc.b	'MAG',0
pi_name:	.dc.b	'PI',0
jpg_name:	.dc.b	'JPEGED -f2 -n',0


opm2mdr_name:	.dc.b	'OPM2MDR -pq',0
		.even

*==================================================
*MDX/MDRファイルをロードする
*	LOAD_MDX(char *name)
*	name	ファイル名
*	d0.l -> 負なら、エラー
*		-1 MDXロードエラー
*		-2 PDXロードエラー
*		-3 メモリ不足
*		-4 MDXバッファ不足
*		-5 PCMバッファ不足
*		-6 フォーマットエラー
*==================================================

		.offset	-256
oldpdx_name	.ds.b	256
		.text

LOAD_MDX:
		movem.l	d1-d4/a0-a2,-(sp)
		movea.l	(7+1)*4(sp),a0
		link	a6,#-256

		moveq	#-1,d2			*MDXバッファポインタ
		moveq	#0,d4

		lea	oldpdx_name(a6),a2	*MADRV内のPDX名をバッファに取っておく
		clr.b	(a2)			*(ヘッダ解析をすると変わってしまうため)
		MADRV	#$16
		tst.l	d0
		beq	load_mdx19
		movea.l	d0,a1
load_mdx10:
		move.b	(a1)+,(a2)+
		bne	load_mdx10
load_mdx19:

		pea	ext_mdx(pc)		*拡張子がなければつける
		pea	(a0)
		bsr	ADD_EXT

		clr.l	-(sp)			*MDXファイルを読み込む
		pea	env_MADRV(pc)		*環境変数MADRV,mxpを探す
		pea	(a0)
		bsr	READ_FILE
		move.l	d0,d3
		bpl	load_mdx20
		addq.l	#1,d0
		beq	load_mdx_loaderr
		bra	load_mdx_memerr

load_mdx20:
		move.l	a0,d2			*ヘッダを解析して
		movea.l	d2,a1
		MADRV	#$05
		tst.l	d0
		beq	load_mdx30

		pea	oldpdx_name(a6)		*PDXがあればロードする
		move.l	d0,-(sp)
		bsr	LOAD_PDX
		move.l	d0,d4

load_mdx30:
		exg	d1,d3			*MMLをドライバに転送する
		sub.l	d3,d1
		movea.l	a0,a1
		move.w	sr,-(sp)
		ori.w	#$0700,sr
		MADRV	#$01
		move.w	(sp)+,sr
		tst.l	d0
		bmi	load_mdx_buferr
		move.l	d4,d0
		bra	load_mdx90

load_mdx_loaderr:
		moveq	#-1,d0
		bra	load_mdx90
load_mdx_memerr:
		moveq	#-3,d0
		bra	load_mdx90
load_mdx_buferr:
		moveq	#-4,d0
load_mdx90:
		move.l	d0,d1
		move.l	d2,-(sp)		*MDXのメモリを開放する
		bsr	FREE_MEM
		move.l	d1,d0
		unlk	a6
		movem.l	(sp)+,d1-d4/a0-a2
		rts


*==================================================
*PDXファイルをロードする
*	LOAD_PDX(char *name, char *oldname)
*	name	ファイル名
*	oldname	ドライバ内のPDXファイル名
*	d0.l -> 負なら、エラー
*		-1 MDXロードエラー
*		-2 PDXロードエラー
*		-3 メモリ不足
*		-4 MDXバッファ不足
*		-5 PCMバッファ不足
*		-6 フォーマットエラー
*==================================================

		.offset	-256
pdx_name	.ds.b	256
		.text

LOAD_PDX:
		movem.l	d1-d4/a0-a2,-(sp)
		movem.l	(7+1)*4(sp),a1-a2
		link	a6,#-256

		moveq	#-1,d2			*PDXバッファポインタ
		moveq	#0,d4			*エラーコード

		lea	pdx_name(a6),a0		*PDXファイル名をコピー
load_pdx10:
		move.b	(a1)+,(a0)+
		bne	load_pdx10
		lea	pdx_name(a6),a1

		pea	(a1)			*同じならば、何もしない
		pea	(a2)
		bsr	STRCMPI
		tst.l	d0
		beq	load_pdx90

load_pdx20:
		pea	ext_pdx(pc)		*拡張子がなければつける
		pea	(a1)
		bsr	ADD_EXT

		movea.l	a1,a0			*TDXだったら
		bsr	CHECK_TDX
		bne	load_pdx21
		bsr	LOAD_TDX		*TDXをロードする
		move.l	d0,d4
		bra	load_pdx90

load_pdx21:
		moveq	#-2,d4
		clr.l	-(sp)			*PDXファイルを読み込む
		pea	env_MADRV(pc)		*環境変数MADRV,mxpを探す
		pea	(a1)
		bsr	READ_FILE
		move.l	d0,d3
		bpl	load_pdx30
		addq.l	#1,d0
		beq	load_pdx90
		moveq	#-3,d4
		bra	load_pdx90

load_pdx30:
		moveq	#-5,d4
		move.l	a0,d2			*PDXをドライバに転送する
		moveq	#0,d1
		MADRV	#$00
		move.l	d3,d1
		movea.l	d2,a1
		MADRV	#$00
		tst.l	d0
		bmi	load_pdx90
		moveq	#0,d4

load_pdx90:
		move.l	d2,-(sp)		*PDXのメモリを開放する
		bsr	FREE_MEM
		tst.l	d4
		bpl	load_pdx91
		moveq	#0,d1			*エラーだったら
		MADRV	#$00			*ドライバのバッファを初期化し
		MADRV	#$16			*ドライバ内のPDX名を消す
		tst.l	d0
		beq	load_pdx91
		movea.l	d0,a1
		clr.b	(a1)
load_pdx91:
		move.l	d4,d0
		unlk	a6
		movem.l	(sp)+,d1-d4/a0-a2
		rts


*==================================================
*ＴＤＸ読み込み
*	a0.l <- ファイル名
*==================================================

LOAD_TDX:
		movem.l	d1-d2/a0-a2,-(sp)
		moveq	#-1,d0
		movea.l	d0,a2

		clr.l	-(sp)			*TDXファイルを読み込む
		pea	env_MADRV(pc)		*環境変数MADRV,mxpを探す
		pea	(a0)
		bsr	READ_FILE
		lea	12(sp),sp
		move.l	d0,d2
		bmi	load_tdx_err
		movea.l	a0,a2

		MADRV	#$0c			*ドライバのバッファにTDXを展開
		move.l	d0,a1
		bsr	TDX_LOAD
		bne	load_tdx_err

		moveq.l	#-1,d1			*PDXをスタンバイさせる
		MADRV	#$00
		moveq	#0,d0
		bra	load_tdx90

load_tdx_err:
		moveq	#-2,d0
load_tdx90:
		move.l	d0,d2
		pea	(a2)			*TDXのメモリを開放
		bsr	FREE_MEM
		addq.l	#4,sp
		move.l	d2,d0
		movem.l	(sp)+,d1-d2/a0-a2
		rts


*ファイル名がTDXならEQUを返す
*	a0.l <- ファイル名

CHECK_TDX:
		movem.l	a0,-(sp)
		moveq	#0,d0
check_tdx10:
		tst.b	(a0)
		beq	check_tdx20
		lsl.l	#8,d0
		move.b	(a0)+,d0
		bra	check_tdx10
check_tdx20:
		andi.l	#$ffdfdfdf,d0
		cmpi.l	#'.TDX',d0
		movem.l	(sp)+,a0
		rts

*==================================================
*ＺＤＦファイルをロードする
*	LOAD_ZDF(char *name)
*	name	ファイル名
*	d0.l -> 負なら、エラー
*		-1 MDXロードエラー
*		-2 PDXロードエラー
*		-3 メモリ不足
*		-4 MDXバッファ不足
*		-5 PCMバッファ不足
*		-6 フォーマットエラー
*==================================================

		.offset	-310
zdf_table	.ds.b	54
zoldpdx_name	.ds.b	256
		.text

LOAD_ZDF:
		movem.l	d1-d3/a0-a2,-(sp)
		move.l	(6+1)*4(sp),a0
		link	a6,#-310

		moveq	#-1,d1			*ZDFバッファポインタ
		moveq	#-1,d2			*LZZバッファポインタ
		moveq	#-1,d3			*MDXバッファポインタ

		lea	zoldpdx_name(a6),a2	*MADRV内のPDX名をバッファに取っておく
		clr.b	(a2)			*(ヘッダ解析をすると変わってしまうため)
		MADRV	#$16
		tst.l	d0
		beq	load_zdf19
		movea.l	d0,a1
load_zdf10:
		move.b	(a1)+,(a2)+
		bne	load_zdf10
load_zdf19:

		pea	ext_zdf(pc)		*拡張子がなければつける
		pea	(a0)
		bsr	ADD_EXT

		clr.l	-(sp)			*ZDFファイルを読み込む
		pea	env_MADRV(pc)		*環境変数MADRV,mxpを探す
		pea	(a0)
		bsr	READ_FILE
		tst.l	d0
		bmi	load_zdf_mdxloaderr
		move.l	a0,d1

		pea	zdf_table(a6)		*ZDFデータをオープン
		move.l	d1,-(sp)
		bsr	OPEN_ZDF
		move.l	d0,d2
		bmi	load_zdf_mdxloaderr

		lea	zdf_table(a6),a0	*MDXデータがあるか調べ、
		tst.w	(a0)+
		beq	load_zdf_mdxloaderr
		cmpi.w	#ZDF_MDX,(a0)
		beq	load_zdf20
		cmpi.w	#ZDF_MDR,(a0)
		bne	load_zdf_mdxloaderr

load_zdf20:
		clr.l	-(sp)			*あれば、解凍して
		move.l	6(a0),-(sp)
		move.l	2(a0),-(sp)
		move.l	d2,-(sp)
		bsr	EXTRACT_ZDF
		move.l	d0,d3
		bmi	load_zdf_mdxloaderr

		movea.l	d3,a1			*ヘッダを解析して
		MADRV	#$05

		move.l	d0,-(sp)
		sub.l	zdf_table+8(a6),d1	*MMLをドライバに転送する
		neg.l	d1
		movea.l	a0,a1
		move.w	sr,-(sp)
		ori.w	#$0700,sr
		MADRV	#$01
		move.w	(sp)+,sr
		tst.l	d0
		bmi	load_zdf_mdxbuferr

		move.l	(sp)+,d0		*pdxがあれば
		beq	load_zdf90
		move.l	d2,-(sp)		*転送する
		pea	zdf_table(a6)
		pea	zoldpdx_name(a6)
		move.l	d0,-(sp)
		bsr	TRANS_ZPDX
		bra	load_zdf90

load_zdf_mdxbuferr:
		moveq	#-4,d0
		bra	load_zdf90

load_zdf_mdxloaderr:
		moveq	#-1,d0

load_zdf90
		movea.l	d0,a0
		move.l	d1,-(sp)		*ZDFのメモリと
		bsr	FREE_MEM
		move.l	d2,(sp)			*LZZのメモリと
		bsr	FREE_MEM
		move.l	d3,(sp)			*MDXのメモリを開放する
		bsr	FREE_MEM
		move.l	a0,d0
		unlk	a6
		movem.l	(sp)+,d1-d3/a0-a2
		rts


*==================================================
*ＺＤＦ内のＰＤＸをドライバに転送する
*	TRANS_ZPDX(char *pdxname, char *oldname, short *zdftbl, void *lzz)
*	pdxname	pdxファイル名
*	oldname	ドライバ内のPDXファイル名
*	zdftbl	OPEN_ZDFで得られるテーブル
*	lzz	lzzがロードされているアドレス
*	d0.l -> 負ならエラー
*==================================================

		.offset	-256
zpdx_name	.ds.b	256
		.text

TRANS_ZPDX:
		movem.l	d1-d2/a0-a3,-(sp)
		movem.l	(6+1)*4(sp),a0-a3
		link	a6,#-256

		moveq	#-1,d2			*PDXのバッファポインタ

		pea	(a0)			*ドライバ内のPDXと同じなら何もしない
		pea	(a1)
		bsr	STRCMPI
		tst.l	d0
		beq	trans_zpdx90

		lea	zpdx_name(a6),a1	*PDXファイル名をコピー
trans_zpdx10:
		move.b	(a0)+,(a1)+
		bne	trans_zpdx10
		lea	zpdx_name(a6),a1

		pea	ext_pdx(pc)		*拡張子をつけて
		pea	(a1)
		bsr	ADD_EXT

trans_zpdx20:
		move.w	(a2)+,d0		*ZDF内にPDXがあるか調べる
		beq	trans_zpdx30
trans_zpdx21:
		cmpi.w	#ZDF_MDX+ZDF_PCM,(a2)
		beq	trans_zpdx40
		cmpi.w	#ZDF_MDR+ZDF_PCM,(a2)
		beq	trans_zpdx40
		lea	10(a2),a2
		subq.w	#1,d0
		bne	trans_zpdx21

trans_zpdx30:
		clr.l	-(sp)			*なければファイルをロードする
		pea	(a1)
		bsr	LOAD_PDX
		bra	trans_zpdx90

trans_zpdx40:
		clr.l	-(sp)			*あれば解凍して
		move.l	6(a2),-(sp)
		move.l	2(a2),-(sp)
		pea	(a3)
		bsr	EXTRACT_ZDF
		move.l	d0,d2
		bmi	trans_zpdx_loaderr

		moveq	#0,d1			*ドライバに転送する
		MADRV	#$00
		move.l	6(a2),d1
		movea.l	d2,a1
		MADRV	#$00
		tst.l	d0
		bpl	trans_zpdx90
		moveq	#-5,d0
		bra	trans_zpdx90

trans_zpdx_loaderr:
		moveq	#-2,d0
trans_zpdx90:
		exg	d0,d2			*PDXのバッファを開放する
		move.l	d0,-(sp)
		bsr	FREE_MEM
		tst.l	d2
		bpl	trans_zpdx91
		moveq	#0,d1			*エラーだったら
		MADRV	#$00			*ドライバのバッファを初期化し
		MADRV	#$16			*ドライバ内のPDX名を消す
		tst.l	d0
		beq	load_pdx91
		movea.l	d0,a0
		clr.b	(a0)
trans_zpdx91:
		move.l	d2,d0
		unlk	a6
		movem.l	(sp)+,d1-d2/a0-a3
		rts


		.data
env_MADRV:	.dc.b	'MADRV',0
		.dc.b	'mxp',0,0
ext_mdx		.dc.b	'.mdx',0
ext_pdx		.dc.b	'.pdx',0
ext_zdf:	.dc.b	'.zdf',0
		.text


*==================================================
* MADRV 演奏開始
*==================================================

MADRV_PLAY:
		MADRV	#$02
		rts


*==================================================
* MADRV 演奏中断
*==================================================

MADRV_PAUSE:
		MADRV	#$03
		rts


*==================================================
* MADRV 演奏再開
*==================================================

MADRV_CONT:
		MADRV	#$04
		rts


*==================================================
* MADRV 演奏停止
*==================================================

MADRV_STOP:
		MADRV	#$1C
		rts


*==================================================
* MADRV フェードアウト
*==================================================

MADRV_FADEOUT:
		move.l	d1,-(sp)
		moveq	#10,d1
		MADRV	#$17
		MADRV	#$09
		move.l	(sp)+,d1
		rts


*==================================================
* MADRV スキップ
*	d0.w <- スキップ開始フラグ
*==================================================

MADRV_SKIP:
		movem.l	d1-d2,-(sp)
		tst.w	d0
		beq	madrv_skip90
		moveq	#5,d1
		moveq	#$60,d2
		MADRV	#$1e		*ワープ
madrv_skip90:
		movem.l	(sp)+,d1-d2
		rts


*==================================================
* MADRV スロー
*	d0.w <- スロー開始フラグ
*==================================================

MADRV_SLOW:
		movem.l	d1,-(sp)
		movea.l	MA_BUF(a6),a0		* MADRV の現在のテンポ
		lea	TEMPO(a0),a0
		move.b	SLOW_TEMPO(a6),d1	* スロー時のテンポ

		tst.w	d0
		beq	madrv_slow50

		tst.b	d1			* スローを開始する時と
		beq	madrv_slow10
		cmp.b	(a0),d1			* テンポが変わった時に
		beq	madrv_slow90
madrv_slow10:
		move.b	(a0),d0			* テンポを遅くする(1/2にする)
		move.b	d0,ORIG_TEMPO(a6)
		lsr.b	#2,d0
		addq.b	#1,d0
		move.b	d0,(a0)
		move.b	d0,SLOW_TEMPO(a6)
		bra	madrv_slow90

madrv_slow50:
		tst.b	d1			* スロー状態で
		beq	madrv_slow90
		cmp.b	(a0),d1			* かつテンポが変わってなければ
		bne	madrv_slow90
		move.b	ORIG_TEMPO(a6),(a0)	* 保存しておいたテンポに戻す
		clr.b	SLOW_TEMPO(a6)

madrv_slow90:
		movem.l	(sp)+,d1
		rts

		.end



ＯＰＭレジスタ設定値の求め方

(1) プログラム内容

  トラックワーク(以後TWAと略する)のPROGRAM_PTRが示すアドレスに、音色データが(MADRV.MANに
示されたフォーマットの状態で)格納されています。PROGRAM_PTRは破壊して構いません。通常は
NILを設定し、NIL以外になった時新規プログラムであると認識する事ができます。

(2) 各チャンネルの音量

  プログラム内容あるいは、VOLUMEMAP(TWA)と、MA_LFOX5(TWA)上位バイト・NOWVOLUME(TWA)上位バイト
FADELVL(TWA)上位バイトの合計が現在の音量です。

(3) 各チャンネルのパンポット

  NOWPAN(TWA)の上位2bitがパンポット情報です。

(4) キーオン状態

  KEYONFLAG(TWA)に$00:キーオフ $FF:キーオンのステータス内容が返ります。また、KEYONWORK(TWA)に
$FFが、キーオン瞬間に書き込まれるので、キーオンタイミングを取り出す事ができます（取り出した後は
KEYONWORKをクリアして、次のキーオン取り出しに備えて下さい）。また、スロットマスクはKEYONSIGNE
(TWA)にOPMへ書き込まれるキーオンデータそのものが入っています。


ＭＤＸステータスの求め方

(1) 音程

  KEYCODE(TWA)+PR_PITCH(TWA)+MP_LFOX6(TWA).Hの合計が現在の音程です。KEYCODE(TWA)にはデチューン
情報が含まれています。純粋な音程を取り出したい時は、PCMKEY(TWA)を参照して下さい。

(2) 音量

  NOWVOLX(TWA)に0～15/-128～-1の値が入ります。この値はvコマンド、@vコマンドのパラメータ
そのものが設定されています。

(3) LFOパラメータ

  システムワーク(以後SWAと省略)の、NEWHLFOで「新しいハードウエアLFO情報」が設定された事を
表示します。実際のハードウエアLFOのオン・オフは、EVENTWORK(TWA)を参照してください。
また、NOW_LFREQ～NOW_AMD(SWA)にはOPMに設定する値そのものが格納されています。これらはyコ
マンドや、MHコマンドで設定された内容を複写したものです。


各ラベルの解説

TRKPTR		ds.l	1	トラックロケーションカウンタ	($????????)

　mmlをシーケンスする都度にインクリメントされ、一つのフレームを完了すると書き戻される
ストリームポインタです。命令実行の都度に増えるのではなく、あるていどまとめて変化するので、
リアルタイムに追従しても、それほど意味はありません。

TRACKACT	ds.b	1	トラックアクティビティ		($00/$FF)

　トラックがスリープ状態になると$ffが書き込まれ、次のシーケンスが行なわれません。

TRACKSIGNAL	ds.b	1	トラック間通信フラグ		($00/$FF)

　$ffが書き込まれると、スリープ状態になります。しかしTRACKACTと違って、こちらは
解除する事ができます。また、わざと受信待ちにして、ソフトウエア外部から演奏開始を
任意ブロックずつ切り出して行なうといった芸当もできます（これは音声合成に用いる物で、
1.10でファンクションコール化します。FFTパッケージも平行して開発中です）。

PCMBANK		ds.l	1	PCM用バンクレジスタ		($00??????)

　pcmパートで@コマンドを使うと、それに応じてヘッダアドレスを変更する為の値がここに
設定されます。しかしPCMのバンクナンバーは、ここから取り出すより、後述のリアルタイム
プログラムナンバーを参照した方が合理的です。

KEYCODE		ds.l	1	キー				($0000～$17FF)

　キーコード＋デチューンがここに設定されます。キーコードはキーオンディレイに関係なく
ロードされますが、デチューンは実際にキーオンするまでロードされません。

KEYDETUNE	ds.l	1	デチューン設定値		($8000～$7FFF)

　デチューンの設定値です。こちらはMMLに同期して即座に変化します。

PR_PITCH	ds.l	1	ポルタメント現在ピッチ		($8000～$7FFF)

　ポルタメント変移が有効であれば、ここにそのピッチがロードされます。

PR_MPITCH	ds.l	1	ポルタメントピッチ		($E800～$17FF)

　ポルタメント変移そのものがロードされます。0ならポルタメントは動作していません。

WASKEY		ds.w	1	以前のキー値			($0000～$17FF)

　過去の音程です。内部で使用します。

NOWVOLUME	ds.w	1	現在のボリューム		($0000～$7F00)

　現在の音量で、0.75db単位の減衰量です。

WAS_VOL		ds.w	1	過去のボリューム		($0000～$7F00)

　過去の音量で、内部で使用します。

VOLUMESETJOB	ds.l	1	音量設定内部処理アドレス	($????????)

　音量設定処理へのポインタです。内部で使用します。

VOLUMEMAP	ds.b	4	ボリューム設定値マップ		($00.4～$7F.4)

　各スロット分の減衰量です。実際にOPMに設定される値は、NOWVOLUMEにこれら４つそれぞれの
和が、書き込まれます。

MPLFOJOB	ds.l	1	内部処理アドレス		($????????)

　LFO処理アドレスポインタです。内部で使用します。

MPLFOJOB2	ds.l	1					($????????)

　LFO処理アドレスポインタです。内部で使用します。

MALFOJOB	ds.l	1	

　LFO処理アドレスポインタです。内部で使用します。

MALFOJOB2	ds.l	1

　LFO処理アドレスポインタです。内部で使用します。

MP_LFOX0	ds.l	1	LFO用ワークエリア

  LFOワークエリアです。内部で使用します。

MP_LFOX1	ds.l	1

  LFOワークエリアです。内部で使用します。

MP_LFOX2	ds.l	1

  LFOワークエリアです。内部で使用します。

MP_LFOX3	ds.l	1

  LFOワークエリアです。内部で使用します。

MP_LFOX4	ds.l	1

  LFOワークエリアです。内部で使用します。

MP_LFOX5	ds.l	1

  LFOワークエリアです。内部で使用します。

MP_LFOX6	ds.l	1

  実際に音程に加算される値が上位ワードにロードされます。下位ワードは小数点以下の成分です。

MA_LFOX0	ds.w	1	LFO用ワークエリア

  LFOワークエリアです。内部で使用します。

MA_LFOX1	ds.w	1

  LFOワークエリアです。内部で使用します。

MA_LFOX2	ds.w	1

  LFOワークエリアです。内部で使用します。

MA_LFOX3	ds.w	1

  LFOワークエリアです。内部で使用します。

MA_LFOX4	ds.w	1

  LFOワークエリアです。内部で使用します。

MA_LFOX5	ds.w	1

  実際に音量に加算される値が上位バイトにロードされます。下位バイトは小数点以下の成分です。

PCMFREQPAN	ds.w	1	PCM周波数・音程		(IOCS _ADPCMOUTに準ずる)

　PCMパートのレート・位相です。

KEYOFGATE2	ds.l	1	内部テーブルへのポインタ	($????????)

　ゲートタイムテーブルへのポインタです。内部で使用します。

PROGRAM_PTR	ds.l	1	プログラムへのポインタ		($????????)

　プログラム（音色データ）へのポインタです。MADRV動作そのものには関与しません。

SEQDELTA	ds.b	1	シーケンス・デルタタイマー	($00～$FF)

　同期を取るためのタイマーです。

MH_SYNC		ds.b	1	シンクロ有無(全体へ)		($00/$20)

  LFOシンクロデータです。

MH_AMSPMS	ds.b	1	PMS/AMS(音色へ)		($00～$FF)

　ハードウエアLFOパラメータのひとつです。

LFODELAY	ds.b	1	LFOディレイ			($00～$FF)

  LFO動作までのディレイタイムが格納されます。0でフルタイムLFOです。

LFODELTA	ds.b	1	LFOタイマー			($00～$FF)

　LFOディレイタイムをカウントするタイマーです。

LFOACTIVE	ds.b	1	LFOアクティベート		($00/$FF)

  LFOが動作すると$ffとなります。

LFOMOTOR	ds.b	1	LFOモーター			($00/$01)

  LFOが動作すると$00となってカウントダウンを禁止します。

MPMOTOR		ds.b	1	MPモーター			($00/$01)

  ポルタメントLFO動作を禁止・動作させます($01で動作)

MAMOTOR		ds.b	1	MAモーター			($00/$01)

  アンプリチュードLFO動作を禁止・動作させます($01で動作)

KEYONDELAY	ds.b	1	キーオン・ディレイ		($00～$FF)

　キーオンまでのディレイタイムがロードされます。

KEYONDELTA	ds.b	1	キーオン・タイマー		($00～$FF)

　キーオンまでのディレイタイムをカウントするタイマーです。

KEYONMOTOR	ds.b	1	キーオン・モーター		($00/$FF)

　キーオンすると$00となってカウントダウンを禁止します。

KEYOFGATE	ds.b	1	キーオフ・ゲートタイム(@q用)	($00～$08/$80～$FF)

　キーオフまでのゲートタイムがロードされます。

KEYOFDELTA	ds.b	1	キーオフ・タイマー		($00～$FF)

　キーオフまでのゲートタイムをカウントするタイマーです。

KEYOFMOTOR	ds.b	1	キーオフ・モーター		($00/$FF)

　キーオフされると$00となってカウントダウンを禁止します。

KEYONSIGNE	ds.b	1	キーオン時に書き込む内容	(??)

　キーオン時にOPMに書き込む内容がロードされています。

NOWFLCON	ds.b	1	FL&CON				(??)

　現在のフィードバックレベル・アルゴリズムが指定されています。

NOWPAN		ds.b	1	現在のパンポット		(??)

　現在のパンポットです。

NOWVOLX		ds.b	1	現在の音量			($00～$0F/$80～$FF)

　現在のMML指定音量が格納されます。

PCMKEY		ds.b	1	PCM用キーコード		($00～$5F)

　PCM用のキーコードで、0～95の範囲（一切の小数点以下情報を持たない）ものです。

WASPCMPAN	ds.b	1	過去のPCMパンポット		(??)

　過去のPCMパンポット情報で内部で使用します。

KEYONFLAG	ds.b	1	キーオンフラグ			($00/$FF)

　キーオンされると$ffとなり、二重にキーオンされるのを抑制します。

CURPROG		ds.b	1	カレントプログラム番号		($00～$FF)

　現在のプログラム番号を指定します。

CURPROGNEW	ds.b	1	新規プログラムセット指示	($00/$FF)

  $ffが書き込まれると、CURPROGに従って音色をセットします。

KEYONWORK	ds.b	1	キーオンタイミング読み出し	($FF)

　キーオンの都度に$ffが書き込まれます。

EVENTWORK	ds.b	1	LFOイベント			※2

　LFO状態がON/OFFされる都度に設定されます。

PROGRAM_BANK	ds.l	256	プログラム用テーブル

　音色２５６個分をキープするポインタテーブルです。

TO_MMLPTR	ds.l	1	MML領域へのポインタ		($????????)

　MMLデータ領域へのポインタです。

TO_PCMPTR	ds.l	1	PCM領域へのポインタ		($????????)

  PCMデータ領域へのポインタです。

LEN_MMLPTR	ds.l	1	MML領域の長さ			($????????)

  MML領域の長さです。

LEN_MMLDATA	ds.l	1	MMLの実際に入っているデータ長	($????????)

  MMLの実装量が入っています。

LEN_PCMPTR	ds.l	1	PCM領域の大きさ		($????????)

  PCM領域の長さです。

PLAYFLAG	ds.l	1	演奏状態フラグ			(b0～b15に各トラック毎に)

  演奏状態が32bitそれぞれに入っています。

ONPCMFLAG	ds.b	1	PCMがあるか？			($FF:PCM存在)

  PCMがあれば$ffが設定されます。

ONMMLFLAG	ds.b	1	MMLはあるか？			($FF:MML存在)

  MMLがあれば$ffが設定されます。

STOP_SIGNAL	ds.b	1	停止シグナル			($FF:停止動作開始)

  停止動作指示を行なう為のもので、内部で使用します。

PAUSE_MARK	ds.b	1	停止中フラグ			($FF:停止)

  停止している間は$ffがセットされます。

PCMFNAME	ds.b	128	PCMファイル名			(ASCII)

  PCMファイル名が入っています。

FADEP		ds.w	1	フェードアウトピッチ		($0000～$FFFF)

  フェードアウト速度が入ります。

FADEPITCH	ds.w	1	ピッチモーター			($0000～$FFFF)

  内部で使用します。

FADELVL		ds.w	1	フェードアウトレベル		($0000～$7FFF/$8000)

  内部で使用します。

WAS_VCT0	ds.l	1	各種ベクタ保存			($????????)
WAS_VCT1	ds.l	1
WAS_VCT2	ds.l	1
WAS_VCTA	ds.l	1
WAS_VCTB	ds.l	1
WAS_VCTC	ds.l	1
WAS_VCTD	ds.l	1
NEW_VCT0	ds.l	1	実際の処理アドレス
NEW_VCT1	ds.l	1
NEW_VCT2	ds.l	1
NEW_VCTA	ds.l	1
NEW_VCTB	ds.l	1
NEW_VCTC	ds.l	1
NEW_VCTD	ds.l	1

  以上の内容は絶対に変更してはなりません。

MAXTRACK	ds.w	1	最大トラック			(0～31)

  現在演奏しているデータの最大トラック数が入ります。

NOWCLOCK	ds.l	1	外部クロック出力		($????????)

　現在のクロック数が入ります。

TO_MMLPTR2	ds.l	1	MDX領域へのポインタ		($????????)

  MDX領域へのポインタが返ります。内部で使用します。

TO_PCMPTR2	ds.l	1	PCM領域へのポインタ		($????????)

  PCM領域へのポインタが返ります。内部で使用します。

INT_VCT		ds.l	1	インタラプトベクタ		($????????)

  変更してはなりません。

ATPCMPTR	ds.l	1	暴走対策			($????????)

  変更してはなりません。

ADPCM_BUSY	ds.b	1	ノイズレスADPCMドライブワーク

  PCM動作フラグ。

ADPCM_Y0	ds.b	1

  PCMワーク。

ADPCM_FREQ	ds.b	1

  PCMレート。

ADPCM_PAN	ds.b	1

  PCM位相。

EX_PCM2		ds.b	1	EX-PCMフラグ			($00/$FF/$01/$02)

  PCM8常駐状態が入ります。$00:非常駐 $FF:とても古いPCM8 $01:ちょっと古いPCM8 $02:当り前のPCM8

TEMPO		ds.b	1	テンポ保持用			(??)

  テンポ状態が返ります。変更するとデッドロックする恐れがあります。

EX_PCM		ds.b	1	EX-PCMフラグ			($00/$FF/$01/$02)

  PCM8常駐状態が入ります。$00:非常駐 $FF:とても古いPCM8 $01:ちょっと古いPCM8 $02:当り前のPCM8

STOPFLAG	ds.b	1	停止中マーク			(内部使用)

  停止フラグ。内部で使用します。

EXOPKEY1	ds.b	1	キーボード操作フラグ		(内部コード)

  キーボード用フラグ。内部で使用します。

GRAM_SELECT	ds.b	1	GRAM使用中フラグ

  変更してはなりません。

UNREMOVE_FLAG	ds.b	1	常駐解除禁止フラグ

  変更してはなりません。

KEYCTRLFLAG	ds.b	1	キーボード操作禁止フラグ

  変更してはなりません。

WAS_VCTI	ds.l	1	TRAP #4用保存ベクタ		($????????)

  変更してはなりません。

TRACKMASK	ds.l	1	トラックマスク			(b31～b0:tr31～tr0)

  変更してはなりません。

LED_COUNTER	ds.w	1	LED用カウンタ			($????)

  変更してはなりません。

MMLTITLE	ds.b	512	MMLのタイトル			(ASCII)

  MDXデータのタイトルのASCII文字列が格納されます。

DENDMASK	ds.l	1	データエンドフラグ		(b31～b0:tr32～tr0)

  変更してはなりません。

FADEPM		ds.w	1	フェードアウト			($????)

  変更してはなりません。

INTMASK		ds.w	1	割り込みマスクレジスタ		(内部コード)

  変更してはなりません。

LOOP_FLAG	ds.w	1	ループフラグ			($????)

  ループ回数が入ります。

NOW_WAVEFORM	ds.b	1	ハードウエアLFO WAVEFORM	(OPMに準ずる)
NOW_LFREQ	ds.b	1	LFREQ
NOW_PMD		ds.b	1	PMD
NOW_AMD		ds.b	1	AMD

  ハードウエアLFO状態値です。

NEWFILE		ds.b	1	ワークエリア初期化フラグ	($FF:初期化)

  新しいファイルがセットされると、$FFが書き込まれます。

NEWHLFO		ds.b	1	ハードウエアLFO新規設定	($FF:設定)

  新しいLFOデータがセットされると$FFが書き込まれます。


