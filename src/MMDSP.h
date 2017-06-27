*************************************************************************
*									*
*									*
*	    Ｘ６８０００　ＭＸＤＲＶ／ＭＡＤＲＶディスプレイ		*
*									*
*				ＭＭＤＳＰ				*
*									*
*									*
*	Copyright (C)1991-94 Kyo Mikami / Masao Takahashi		*
*						 All Rights Reserved.	*
*									*
*									*
*************************************************************************


*==================================================
*バージョン
*==================================================

VERSION		macro
		.dc.b	'0.30β'
		endm

STAYID		equ	$31415926	*常駐識別ＩＤ


*==================================================
*定数
*==================================================

TXTADR		.equ	$E00000		*テキストアドレス０
TXTADR1		.equ	$E20000		*テキストアドレス１
TXTADR2		.equ	$E40000		*テキストアドレス２
TXTADR3		.equ	$E60000		*テキストアドレス３

BGADR		.equ	$EBC000		*ＢＧアドレス１
BGADR2		.equ	$EBE000		*ＢＧアドレス２

SPRITEREG	.equ	$EB0000		*スプライトレジスタアドレス
SPPALADR	.equ	$E82200		*スプライトパレットアドレス
PCGADR		.equ	$EB8000		*ＰＣＧアドレス

CRTC_GSCRL	.equ	$E80018		*グラフィックスクロールレジスタ

CRTC_MODE	.equ	$E80028		*CRTCモード
CRTC_ACM	.equ	$E8002A		*CRTCテキストアクセスモード

VIDEO_MODE	.equ	$E82400		*VCONメモリモード
VIDEO_PRIO	.equ	$E82500		*VCONプライオリティ
VIDEO_EFFECT	.equ	$E82600		*VCON特殊効果

GPALADR		.equ	$E82000		*グラフィックパレットアドレス

MFP		.equ	$E88000		*ＭＦＰ


*==================================================
*共通マクロ
*==================================================

MYONTIME	.macro
		move.w	ONTIME(a6),d0
		.endm


*==================================================
*グローバルラベル
*==================================================

*MMDSP.S
		.global		START
		.global		MM_HEADER
		.global		MM_STAYFLAG
		.global		BUFFER
*INIT.S
		.global		SYSTEM_INIT
		.global		CLEAR_WORK
		.global		CHECK_OPTION
		.global		SYSTEM_CHCK
		.global		PRINT_ERROR
		.global		DRIVER_INIT
		.global		VECTOR_INIT
		.global		VECTOR_DONE
		.global		RESID_CHECK
		.global		KILL_BREAK
		.global		RESUME_BREAK
		.global		DISP_INIT
		.global		DISP_DONE
		.global		DISPLAY_MAKE
		.global		TABLE_MAKE
		.global		SAVE_CURPATH
		.global		MOVE_CURPATH
		.global		RESUME_CURPATH
		.global		SAVE_DISPLAY
		.global		RESUME_DISPLAY
		.global		HSCOPY
		.global		HSCLR
*SPRITE.S
		.global		SPRITE_INIT
*BG.S
		.global		BG_PRINT	*D0:ADD A0:W_ADR A1:R_ADR
		.global		BG_LINE
						*D0:PRT A0:W_ADR
		.global		PRINT16_2KETA	*16進:	00
		.global		PRINT16_4KETA	*	00_00
		.global		PRINT16_6KETA	*	00_00_00
		.global		PRINT16_2KT_T	*	0_0
		.global		PRINT10_2KETA	*10進:	00
		.global		PRINT10_3KETA	*	00_0
		.global		PRINT10_5KETA	*	00_00_0
		.global		PRINT10_5KT_F	*	_:00_00_0
		.global		PRINT10_3KT_2	*	0_00
		.global		DIGIT10		*デジタル１０進数
		.global		DIGIT10S	*デジタル１０進数ゼロサプレス
		.global		DIGIT16		*デジタル１６進数
		.global		PUT_DIGIT	*デジタル文字表示
*FONT.S
		.global		CHR_00
		.global		CH6_00
*TEXT.S
		.global		TEXT_ACCESS_ON	*D0:A_PL
		.global		TEXT_ACCESS_OF	*D0:A_PL
		.global		CLEAR_TEXT
		.global		TEXT48AUTO	*A0:D_AD
		.global		TEXT_4_8	*D0:A_PL D1:Dset A0:R_AD A1:W_AD
		.global		TEXT_6_16	*D0:A_PL D1:Dset A0:R_AD A1:W_AD
		.global		text_mask_set
		.global		TXLINE_CLEAR	*D0:Count A0:W_AD
		.global		DARK_PATTERN	*D1:SIZE A1:W_AD
		.global		LIGHT_PATTERN	*D1:SIZE A1:W_AD
		.global		PUT_PATTERN_OR	*D1:SIZE A0:R_AD A1:W_AD
		.global		PUT_PATTERN	*D0:A_PL D1:SIZE A0:R_AD A1:W_AD
*MOUSE.S
		.global		MOUSE_INIT
		.global		MOUSE_MOVE
		.global		MOUSE_ERASE
*PANEL.S
		.global		PANEL_MAKE
		.global		PANEL_EVENT
		.global		PANEL_DRUG
*CONTROL.S
		.global		CONTROL
		.global		ENTER_CMD
		.global		CLEAR_CMD
		.global		BIND_DEFAULT
		.global		set_myontime
*MAIN.S
		.global		DISPLAY_MAIN
		.global		VDISP_MAIN
*_SYSDISP.S
		.global		SYSDIS_MAKE
		.global		SYSTEM_DISP
		.global		CLEAR_PASSTM
		.global		SET_GMODE
		.global		BG_SEL
		.global		GTONE_UP
		.global		GTONE_DOWN
		.global		GTONE_SET
		.global		GHOME
		.global		GMOVE_U
		.global		GMOVE_D
		.global		GMOVE_L
		.global		GMOVE_R
*		.global		PALET_ANIM			*(:_;)
*_KEYBORD.S
		.global		KEYBORD_MAKE
		.global		KEYBD_UP
		.global		KEYBD_DOWN
		.global		KEYBD_SET
		.global		KEYBORD_DISP
*_REGISTER.S
*		.global		REGISTER_MAKE
*		.global		REGISTER_DISP
*_LEVEL.S
		.global		LEVELM_MAKE
		.global		LEVELSNS_UP
		.global		LEVELSNS_DOWN
		.global		LEVELSNS_SET
		.global		LEVELPOS_UP
		.global		LEVELPOS_DOWN
		.global		LEVELPOS_SET
		.global		LEVELM_DISP
		.global		LEVELM_GENS
*_SPEANA.S
		.global		SPEANA_MAKE
		.global		SPEASNS_UP
		.global		SPEASNS_DOWN
		.global		SPEASNS_SET
		.global		SPEASUM_CHG
		.global		SPEASUM_SET
		.global		SPEAREV_CHG
		.global		SPEAREV_SET
		.global		SPEAMODE_UP
		.global		SPEAMODE_DOWN
		.global		SPEAMODE_SET
		.global		SPEANA_DISP
		.global		SPEANA_GENS
*_SELECTOR.S
		.global		SELECTOR_INIT
		.global		SELECTOR_MAKE
		.global		SELECTOR_MAIN
		.global		GET_CURRENT
		.global		SET_CURRENT
		.global		UNLOCK_DRIVE
		.global		DRIVE_CHECK
		.global		AUTOMODE_CHG
		.global		AUTOMODE_SET
		.global		AUTOFLAG_CHG
		.global		AUTOFLAG_SET
		.global		LOOPTIME_UP
		.global		LOOPTIME_DOWN
		.global		LOOPTIME_SET
		.global		BLANKTIME_UP
		.global		BLANKTIME_DOWN
		.global		BLANKTIME_SET
		.global		INTROTIME_UP
		.global		INTROTIME_DOWN
		.global		INTROTIME_SET
		.global		PROGMODE_CHG
		.global		PROGMODE_SET
		.global		PROG_CLR

		.global		TITLE_CLR1
		.global		TITLE_PRT1

*FILES.S
		.global		INIT_FNAMEBUF
		.global		READ_FILEBUFF
		.global		FNAME_SET
		.global		SEARCH_TITLE
		.global		search_next_auto
		.global		search_next_shuffle
		.global		search_header
		.global		get_fnamebuf
		.global		write_datafile
		.global		change_ext_doc
*DOCVIEW.S
		.global		DOCVIEW_INIT
		.global		DOCV_NOW_PRT
		.global		DOCVIEW_UP
		.global		DOCVIEW_DOWN
		.global		DOCV_ROLLUP
		.global		DOCV_ROLLDOWN
		.global		DOCV_CLRALL
*DRIVER.S
		.global		SEARCH_DRIVER
		.global		STATUS_INIT
		.global		CLEAR_KEYON
		.global		TRMASK_CHG
		.global		TRMASK_ALLON
		.global		TRMASK_ALLOFF
		.global		TRMASK_ALLREV
		.global		OPEN_FILE
		.global		CLOSE_FILE
		.global		CHECK_DRIVE
		.global		GET_FILELEN
		.global		READ_FILE
		.global		ADD_EXT
		.global		STRCMPI
		.global		FREE_MEM
		.global		OPEN_ZDF
		.global		EXTRACT_ZDF
		.global		LOAD_LZZ
		.global		TDX_LOAD
		.global		PLAY_FILE
		.global		CALL_PLAYER
		.global		GET_PLAYERRMES
		.global		MMDSP_NAME
		.global		VOL_DEFALT

*==================================================
*トラック情報バッファ
*==================================================

		.offset	0

STCHANGE	.ds.b	1	*ステータス変化フラグ(bit0-3)
				*bit0:音源種類 & TRACKNO
				*bit1:BEND
				*bit2:PAN
				*bit3:PROGRAM
KEYONCHANGE:	.ds.b	1	*キーＯＮ状態変化フラグ
VELCHANGE:	.ds.b	1	*ベロシティ変化フラグ
KEYCHANGE:	.ds.b	1	*キーコード変化フラグ

INSTRUMENT:	.ds.b	1	*0:音源の種類(0:none 1:FM 2:ADPCM 3:MIDI)
CHANNEL:	.ds.b	1	*音源のチャンネル番号(OPM1-8,ADPCM1-8,MIDI1-32)
KEYOFFSET:	.ds.w	1	*KEYCODEのMIDIコードとの差
BEND:		.ds.w	1	*1:ベンド
PAN:		.ds.w	1	*2:パン
PROGRAM:	.ds.w	1	*3:プログラム
KEYONSTAT:	.ds.b	1	*キーＯＮ状態(bit0-7 0:keyon 1:keyoff)
TRACKNO:	.ds.b	1	*トラック番号
KEYCODE:	.ds.b	8	*キーコード
VELOCITY:	.ds.b	8	*ベロシティ
TRST:

		.text

*==================================================
*トラック情報（その他）
*==================================================

		.offset	0

KBS_CHG:	.ds.w	1	*チェックフラグ（変化したパラメータのビットが立つ）

KBS_MP:		.ds.b	1	*C:ＭＰ　のＯＮ／ＯＦＦ
KBS_MA:		.ds.b	1	*D:ＭＡ
KBS_MH:		.ds.b	1	*E:ＭＨ

KBS_k:		.ds.b	1	*0:ｋ
KBS_q:		.ds.b	1	*1:ｑ(bit7: @vフラグ)
			.ds.b	1

KBS_D:		.ds.w	1	*2345:ＤＰＢＡの現在の値
KBS_P:		.ds.w	1
KBS_B:		.ds.w	1
KBS_A:		.ds.w	1

KBS_PROG:	.ds.w	1	*6:＠

KBS_TL1:	.ds.b	1	*7:＠ｖ
KBS_TL2:	.ds.b	1	*8:変化後の＠ｖ

KBS_DATA:	.ds.l	1	*9:ＤＡＴＡ

KBS_KC1:	.ds.w	1	*A:ＫＣ
KBS_KC2:	.ds.w	1	*B:変化後

CHST:
		.text

*==================================================
*MMDSPワークエリア
*==================================================

		.offset	0

DBF_ST:				*初期化するバッファ開始位置

*環境保存関係 --------------------
INIT_PATH:	.ds.b	256	*起動時のカレントディレクトリ
SUPER:		.ds.l	1	*ＳＳＰ
MM_MEMPTR:	.ds.l	1	*MMDSPのメモリ管理ポインタ
CRTMD:		.ds.w	1	*ＣＲＴモード
FUNCMD:		.ds.w	1	*ファンクションキー行モード
LOCATESAVE:	.ds.l	1	*カーソル位置
CONSOLSAVE:	.ds.l	2	*コンソール範囲
CURSORSAVE:	.ds.b	1	*カーソル表示状態
CHILD_FLAG:	.ds.b	1	*子プロセス実行中フラグ

CRTCMODE_SAVE:	.ds.w	1	*CRTCモード
CRTCACM_SAVE:	.ds.w	1	*CRTCテキストアクセス
VIDEOMODE_SAVE:	.ds.w	1	*VCONモード
VIDEOPRIO_SAVE:	.ds.w	1	*VCONプライオリティ
VIDEOEFF_SAVE:	.ds.w	1	*VCON特殊効果
BGCTRL_SAVE:	.ds.w	1	*BGモード
IOCSXLEN_SAVE:	.ds.l	1	*IOCSグラフィックモード
IOCSGMODE_SAVE:	.ds.w	1	*IOCSグラフィックモード
IOCSWIN_SAVE1:	.ds.l	1	*IOCSグラフィックモード
IOCSWIN_SAVE2:	.ds.l	1	*IOCSグラフィックモード
APAGE_SAVE:	.ds.b	1	*IOCS APAGE
VPAGE_SAVE:	.ds.b	1	*IOCS VPAGE

TXTPALSAVE:	.ds.b	2*16
VECTMODE:	.ds.w	1	*使用割り込み種類(1:TIMERA 2:RASTER 3:VDISP 4:TIMER_D)
ORIG_VECTOR:	.ds.l	1	*変更前のベクタアドレス(VDISP)
BREAKCK_SAVE:	.ds.w	1	*
PDB_SAVE:	.ds.l	1	*
INDOSFLAG_SAVE:	.ds.w	1	*
INDOSNUM_SAVE:	.ds.b	1	*
		.even
INDOSSP_SAVE:	.ds.l	1

		.even
SPSAVE_RESI:	.ds.l	1	*
SPSAVE_MAIN:	.ds.l	1	*

*環境設定関係 --------------------
GTONE:		.ds.w	1	*グラフィックトーン(0-31)
GTONE_TBL:	.ds.l	1	*グラフィックトーンテーブルのアドレス(512*32bytes)
GSCROL_X:	.ds.w	1	*グラフィック画面スクロール位置Ｘ
GSCROL_Y:	.ds.w	1	*グラフィック画面スクロール位置Ｙ

SEL_NOUSE:	.ds.b	1	*セレクタ無使用フラグ
FORCE_TVRAM:	.ds.b	1	*テキスト強制使用フラグ
GRAPH_MODE:	.ds.b	1	*グラフィック画面合成モード(0-3)
RESIDENT:	.ds.b	1	*常駐モードフラグ
REMOVE:		.ds.b	1	*常駐モード解除フラグ
		.even

*コントロール関係 --------------------
VDISP_CNT:	.ds.w	1	*割り込み回数カウンタ
MMDSP_CMD:	.ds.w	1	*MMDSPコマンドバッファ
CMD_ARG:	.ds.l	1	*コマンド引数
QUIT_FLAG:	.ds.w	1	*ＭＭＤＳＰ終了フラグ
DRUG_KEY:	.ds.w	1	*ドラッグされているキーコード
DRUG_ONFUNC:	.ds.l	1	*ドラッグ中に呼ばれるルーチン
DRUG_OFFFUNC:	.ds.l	1	*ドラッグ解除時に呼ばれるルーチン
CONTROL_ONTIME:	.ds.w	1	*時間計測用
CONTROL_WORK:	.ds.w	1	*時間計測用
HOTKEY1:	.ds.b	1	*起動キー1のコード
HOTKEY1MASK:	.ds.b	1	*起動キー1のワーク内ビットマスク
HOTKEY1ADR:	.ds.w	1	*起動キー1のワークアドレス
HOTKEY2:	.ds.b	1	*起動キー2のコード
HOTKEY2MASK:	.ds.b	1	*起動キー2のワーク内ビットマスク
HOTKEY2ADR:	.ds.w	1	*起動キー2のワークアドレス
MMDSPON_FLAG:	.ds.b	1	*MMDSP動作中フラグ
HOTKEY_FLAG:	.ds.b	1	*起動キーが押されたままか
ONTIME_WORK1:	.ds.w	1
ONTIME_WORK2:	.ds.w	1
ONTIME:		.ds.w	1

		.even

*ドライバ関係 --------------------
DRV_MODE:	.ds.w	1	*使用するドライバ(0:none 1:MX 2:MA 3:MLD 4:RCD 5:ZMUS )
DRV_ENTRY:	.ds.l	1	*ドライバのエントリアドレス
DRV_WORK:	.ds.b	256	*ドライバで使用するワークエリア
NOWKEY:		.ds.w	1	*キー入力用
REF_TRSTWORK:	.ds.l	1	*REFRESH_TRST 用のワーク
CLR_KEYONWORK:	.ds.l	1	*CLEAR_KEYON 用のワーク
DRIVER_JMPTBL:	.ds.l	20	*ドライバコールのジャンプテーブル

*パネル関係 --------------------
MOUSE_X:	.ds.w	1	*マウスx座標
MOUSE_Y:	.ds.w	1	*マウスy座標
MOUSE_L:	.ds.b	1	*左ボタン状態(on:$FF off:$00)
MOUSE_R:	.ds.b	1	*右ボタン状態(on:$FF off:$00)
MOUSE_LC:	.ds.b	1	*左ボタンクリックフラグ(click:$FF no change:$00)
MOUSE_RC:	.ds.b	1	*右ボタンクリックフラグ(click:$FF no change:$00)
DRUG_FUNC:	.ds.l	1	*ドラッグ処理関数のアドレス
PANEL_ONTIME:	.ds.w	1	*PANEL.s用
PANEL_WORK:	.ds.l	1	*汎用ワーク（主にDRUG関数内で使用）

*テキスト画面関係 --------------------
TX_ACM:		.ds.w	1	*テキストアクセスモード保存用
TX_BF_1:	.ds.b	32	*外部フォント文字表示バッファ
MASK_WORK:	.ds.w	1	*テキストマスクワーク

BG16_TB:	.ds.w	256	*１６進表示用テーブル
BG10_TB:	.ds.w	100	*１０進
FROM96_TO32:	.ds.b	130	*３分の１化テーブル
TO6BIT_TBL:	.ds.b	256	*８－＞６ビット変換テーブル
TO4BIT_TBL:	.ds.b	256	*８－＞４ビット変換テーブル

*システム情報関係 --------------------
SYS_ONTIME:	.ds.w	1	*CPU負荷測定用
CYCLECNT:	.ds.w	1	*CPU負荷測定用
CYCLETIM:	.ds.w	1	*CPU負荷測定用
CLKLAMP:	.ds.w	1	*時計':'点滅用

TRACK_STATUS:	.ds.b	TRST*32	*トラック情報
TRACK_ENABLE:	.ds.l	1	*トラック有効フラグ
TRACK_CHANGE:	.ds.l	1	*トラック有効状態変化フラグ
PLAY_FLAG:	.ds.w	1	*演奏中フラグ
PLAYEND_FLAG:	.ds.w	1	*演奏終了フラグ
STAT_OK:	.ds.w	1	*１秒毎のステータス取得フラグ
CHST_BF:	.ds.b	CHST*32	*チャンネルステータスバッファ

SYS_TITLE:	.ds.l	1	*曲タイトルアドレス
SYS_LOOP:	.ds.w	1	*ループカウンタ
SYS_TEMPO:	.ds.w	1	*テンポ
SYS_DATE:	.ds.w	1	*日時
SYS_TIME:	.ds.w	1	*時間
SYS_PASSTM:	.ds.w	1	*経過時間
BLANK:		.ds.w	1	*曲間時間計測用

LOOPCHK:	.ds.w	1
TEMPOCHK:	.ds.w	1
MDXCHCK:	.ds.b	80
MDXTITLE:	.ds.b	80
TITLELEN:	.ds.w	1

*鍵盤関係 --------------------
KEYB_TROFST:	.ds.b	1	*キーボード先頭トラック番号
KEYB_TRCHG:	.ds.b	1	*キーボード先頭トラック番号変化フラグ
KEYB_TRBUF:	.ds.l	1	*キーボード用先頭トラックバッファアドレス
KEYB_CHBUF:	.ds.l	1	*キーボード用先頭トラックCHSTバッファアドレス
STSAVE:		.ds.b	80	*ステータス保存用

*レベルメータ関係 --------------------
LEVEL_TROFST:	.ds.b	1	*レベルメータ用先頭トラック番号
LEVEL_TRCHG:	.ds.b	1	*レベルメータ用先頭トラック番号変化フラグ
LEVEL_TRBUF:	.ds.l	1	*レベルメータ用先頭トラックバッファアドレス
VELO_BF:	.ds.l	32	*ベロシティーバッファ
LEVEL_SPEED:	.ds.b	1	*レベルメータ減衰速度
LEVEL_RANGE:	.ds.b	1	*レベルメータ速度レンジ
		.even

*スペアナ関係 --------------------
SPEA_MODE:	.ds.w	1	*スペアナモード
SPEA_INTJOB:	.ds.l	1	*スペアナ減衰処理ルーチンのアドレス
SPEA_RISETBL:	.ds.l	1	*上昇速度テーブルのアドレス
		.ds.w	10	*スペアナはみ出し吸い取り用（笑）
SPEA_BF1:	.ds.w	32+10	*スペアナバッファ１
		.ds.w	10	*同吸い取り
SPEA_BF2:	.ds.b	32*6	*スペアナバッファ２
SPEA_SPEED:	.ds.b	1	*スペアナ減衰速度
SPEA_RANGE:	.ds.b	1	*スペアナ速度レンジ
SPEA_SUM:	.ds.b	1	*スペアナ積分モード
SPEA_REV:	.ds.b	1	*スペアナリバースモード
		.even

*セレクタ関係 --------------------
SEL_CMD:	.ds.w	1	*セレクタコマンド
SEL_ARG:	.ds.w	1	*引数

SEL_STAT:	.ds.w	1	*ステータスフラグ
SEL_VIEWMODE:	.ds.b	1	*ビューワモードフラグ
		.ds.b	1

SEL_HEAD:	.ds.l	1	*ディレクトリヘッダアドレス
SEL_BTOP:	.ds.w	1	*バッファ先頭位置
SEL_BPRT:	.ds.w	1	*表示先頭位置
SEL_BSCH:	.ds.w	1	*タイトル検索開始位置
SEL_CUR:	.ds.w	1	*画面カーソル位置
SEL_FCP:	.ds.w	1	*カーソルSEL_FNAME位置
SEL_FMAX:	.ds.w	1	*ディレクトリ中のファイルの全個数
SEL_BMAX:	.ds.w	1	*バッファの最終位置+1

SEL_CHANGE:	.ds.w	1	*状態変更フラグ
SEL_SRC_F:	.ds.w	1	*未検索あり／なしフラグ
SEL_TIME:	.ds.w	1	*キー入力タイムカウンタ
SEL_FILENUM:	.ds.w	1	*セレクタ全ファイル数
SEL_TITLE:	.ds.l	1	*タイトルバッファアドレス
SEL_TITLEBANK:	.ds.w	1	*タイトルバッファ番号(0-2)
G_MES_TIME:	.ds.w	1	*メッセージタイムカウンタ
G_MES_FLAG:	.ds.w	1	*メッセージ表示中フラグ

RND_WORK:	.ds.w	1	*直前の乱数値
LOOP_TIME:	.ds.w	1	*次の曲に移るループ回数
BLANK_TIME:	.ds.w	1	*曲間の待ち時間
INTRO_TIME:	.ds.w	1	*イントロスキャンの時間
SEL_PLAYCHK:	.ds.b	1	*現在位置の曲が演奏されいないフラグ
SEL_MMOVE:	.ds.b	1	*前回演奏時以降、手動でカーソル移動したフラグ
AUTOMODE:	.ds.b	1	*0:NORMAL 1:AUTO 2:SHUFFLE
AUTOFLAG:	.ds.b	1	*bit0:REPEAT bit1:INTRO bit2:ALLDIR bit3:PROG
SHUFFLE_CODE:	.ds.b	1	*シャフルの演奏判別フラグ用数値
PROG_MODE:	.ds.b	1	*プログラムモード
		.even

CONSOLE:	.ds.l	2
SEL_FILES:	.ds.b	54
FNAM_BUFF:	.ds.b	256
CURRENT:	.ds.b	256	*カレントディレクトリの絶対パス名
DRV_TBL:	.ds.b	26	*ドライブ状態テーブル
DRV_TBLFLAG:	.ds.b	2	*ドライブテーブル作成フラグ
LOCKDRIVE:	.ds.b	1	*イジェクト禁止したドライブ(0:none 1:A 2:B ...)
		.even

*ドキュメントビュワー関係 --------------------
DOCV_MEMPTR:	.ds.l	1	*確保したメモリのPSP+$10アドレス
DOCV_MEMEND:	.ds.l	1	*確保したメモリの最終アドレス+1
DOCV_NOW:	.ds.l	1	*現在のバッファ表示位置
DOCV_NEXT:	.ds.l	1	*バッファ表示位置の下
DOCV_SIGEND:	.ds.l	1	*表示可能最終バッファ位置
DOCV_TXTADR:	.ds.l	1	*表示開始するテキストアドレス
DOCV_TXTAD2:	.ds.l	1	*表示範囲一番下のテキストアドレス
DOCV_YOKO:	.ds.w	1	*横文字数
DOCV_TATE:	.ds.w	1	*縦文字数

DOCV_FONT:	.ds.l	1	*フォント別テーブルアドレス
DOCV_RAS1:	.ds.b	1	*スクロール用ラスタナンバー
DOCV_RAS2:	.ds.b	1	*スクロール用ラスタナンバー

* --------------------
DBF_ED:				*初期化するバッファ終了位置
		.even
*		.ds.b	2	*スタックをlong境界に合わせるためのダミー

FILE_BUFF:	.ds.b	1024	*ファイル一部読み込み用バッファ
MYSTACK2:			*アボート時のスタック
KEY_TABLE:	.ds.b	128*18	*キーバインドテーブル
GTONE_BUF:	.ds.b	512*32	*グラフィックパレットテーブル
		.ds.l	2048	*スタックエリア(8Kbytes)
MYSTACK:

BUF_SIZE:
		.text

