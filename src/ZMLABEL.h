			.nlist
*ワークエリア
wk_size:	equ	256	*各トラックの演奏時のワークサイズ(変更不可)
wk_size2:	equ	8	*ワークサイズが２の何乗か(変更不可)

p_on_count:	equ	$00	*.w step time		!!! 順番を変えてはならない
p_gate_time:	equ	$02	*.w gate time		!!!
p_data_pointer:	equ	$04	*.l 現在のコマンドポインタ
p_fo_spd:	equ	$08	*.b フェードアウトスピード
p_ch:		equ	$09	*.b アサインされているチャンネル
p_not_empty:	equ	$0a	*.b トラックの生死(-1=dead/1=play end/0=alive)
p_amod_step:	equ	$0b	*.b AMのステップワーク
p_mstep_tbl:	equ	$0c	*.w 各ポイントに置けるﾓｼﾞｭﾚｰｼｮﾝステップ値($0c～$1b)
p_wvpm_loop:	equ	$0c	*.l 波形メモリループ開始アドレス
p_wvpm_lpmd:	equ	$10	*.w 波形メモリループモード
p_altp_flg:	equ	$12	*.b 波形メモリ反復モードフラグ
p_fo_mode:	equ	$1c	*.b fade out flag (0=off/1～127=on)	!!!
p_pgm:		equ	$1d	*.b last tone number(0-199)		!!!
p_pan:		equ	$1e	*.b last panpot(0～3)			!!!
p_vol:		equ	$1f	*.b last volume(127～0)			!!!
p_mrvs_tbl:	equ	$20	*.b 各ポイントに置けるﾓｼﾞｭﾚｰｼｮﾝ補正値($20～$27)
p_wvpm_point:	equ	$20	*.l 波形メモリ現在のポインタ
p_wvpm_end:	equ	$24	*.l 波形メモリ終了アドレス
p_sp_tie:	equ	$28	*.w MIDIのスペシャル・タイ用ワーク
p_om:		equ	$28	*.b オペレータマスク(&b0000-&b1111)
p_sync:		equ	$29	*.b LFOのシンクスイッチ(0=off,ne=on)
p_af:		equ	$2a	*.b AL/FB
p_se_mode:	equ	$2b	*.b se mode or not($ff=normal/0～=se mode)
p_pmod_tbl:	equ	$2c	*.w ﾓｼﾞｭﾚｰｼｮﾝ値ﾃｰﾌﾞﾙ($2c～$3b)
p_total:	equ	$3c	*.l トータルステップタイム
p_fo_lvl:	equ	$40	*.b 出力パーセンテージ(0-128)
*		equ	$41	*.b
p_note:		equ	$42	*.b 過去にﾉｰﾄｵﾝした音階達８個($42～$49)	!!!PCM ch以外では破壊
p_extra_ch:	equ	$4a	*.b 拡張ﾁｬﾝﾈﾙ番号(PCM8 MODE専用0-7)   ←!!!されることがある
p_aftc_n:	equ	$4b	*.b ｱﾌﾀｰﾀｯﾁｼｰｹﾝｽのポインタ(0～7)
p_bend_rng_f:	equ	$4c	*.w オートベンドのレンジ(FM)
p_bend_rng_m:	equ	$4e	*.w オートベンドのレンジ(MIDI)
p_detune_f:	equ	$50	*.w デチューン(FM用の値)	!!!順番をかえてはならない
p_detune_m:	equ	$52	*.w デチューン(MIDI用の値)	!!!
p_port_dly:	equ	$54	*.w ポルタメントディレイ	###順番をかえてはならない
p_bend_dly:	equ	$56	*.w ベンドディレイ値		###
p_port_work:	equ	$58	*.b ポルタメント用補正ワーク		!!!この3つのワークの
p_port_rvs:	equ	$59	*.b ポルタメント用補正パラメータ	!!!順番を変えては
p_port_work2:	equ	$5a	*.w ﾎﾟﾙﾀﾒﾝﾄ/ｵｰﾄﾍﾞﾝﾄﾞ用 現在のベンド値	!!!ならない
p_amod_tbl:	equ	$5c	*.b ＡＭ値ﾃｰﾌﾞﾙ($5c～$63)
p_arcc_tbl:	equ	$5c	*.b arcc値ﾃｰﾌﾞﾙ($5c～$63)
p_arvs_tbl:	equ	$64	*.b amod用補正値(FM)テーブル($64～$6b)
p_wvam_point:	equ	$64	*.l 波形メモリ現在のポインタ
p_wvam_end:	equ	$68	*.l 波形メモリ終了アドレス
p_pmod_work4:	equ	$6c	*.w ﾓｼﾞｭﾚｰｼｮﾝｽﾋﾟｰﾄﾞﾜｰｸ(FM)
p_port_flg:	equ	$6e	*.w ﾎﾟﾙﾀﾒﾝﾄｵﾝかｵﾌか(0=off/補正する方向-1 or 1) !!! 順番を
p_bend_flg:	equ	$70	*.w ﾍﾞﾝﾄﾞがｵﾝかｵﾌか(0=off/補正する方向-1 or 1) !!! 変えちゃﾀﾞﾒ
p_aftc_tbl:	equ	$72	*.b ｱﾌﾀｰﾀｯﾁｼｰｹﾝｽ値テーブル($72～$79)
p_aftc_dly:	equ	$7a	*.w ｱﾌﾀｰﾀｯﾁｼｰｹﾝｽﾃﾞｨﾚｲ値
p_aftc_work:	equ	$7c	*.w ｱﾌﾀｰﾀｯﾁｼｰｹﾝｽﾃﾞｨﾚｲﾜｰｸ
p_astep_tbl:	equ	$7e	*.b 各ポイントに置けるAMステップ値($7e～$85)
p_wvam_loop:	equ	$7e	*.l 波形メモリループ開始アドレス
p_wvam_lpmd:	equ	$82	*.w 波形メモリループモード
p_alta_flg:	equ	$84	*.b 波形メモリ反復モードフラグ
p_pmod_step2:	equ	$86	*.w ﾓｼﾞｭﾚｰｼｮﾝｽﾃｯﾌﾟﾜｰｸ(FM)	!!!
p_pmod_work:	equ	$88	*.w ﾓｼﾞｭﾚｰｼｮﾝﾃﾞｨﾚｲﾜｰｸ(MIDI/FM)	!!!位置も順番も
p_pmod_work2:	equ	$8a	*.w ﾓｼﾞｭﾚｰｼｮﾝﾎﾟｲﾝﾄﾜｰｸ(MIDI/FM)	!!!動かしては
p_pmod_work3:	equ	$8c	*.b ﾓｼﾞｭﾚｰｼｮﾝ用補正値ワーク(FM)	!!!ならない
p_pmod_n:	equ	$8d	*.b ﾓｼﾞｭﾚｰｼｮﾝﾃｰﾌﾞﾙﾎﾟｲﾝﾀ(MIDI/FM)!!!
p_sync_wk:	equ	$8e	*.b 強制同期コマンド用ワーク			!!!
p_rpt_last?:	equ	$8f	*.b 繰り返しが最後かどうか(bit pattern)		!!!
p_@b_range:	equ	$90	*.b ベンドレンジ(初期値=12)			!!!
p_arcc:		equ	$91	*.b ARCCのコントロールナンバー(MIDI)		!!!
p_pmod_flg:	equ	$92	*.w ﾓｼﾞｭﾚｰｼｮﾝﾌﾗｸﾞ(FMはﾜｰﾄﾞ/MIDIはﾊﾞｲﾄ)	!!!順番をかえては
p_pmod_sw:	equ	$94	*.b ピッチﾓｼﾞｭﾚｰｼｮﾝスイッチ(兼補正方向)	!!!ならない
p_amod_sw:	equ	$95	*.b AMODスイッチ(0=off,ne=on)		!!!
p_arcc_sw:	equ	$95	*.b ARCCスイッチ(0=off,ne=on)		!!!
p_bend_sw:	equ	$96	*.b オートベンドがアクティブか(0=no/ベンド方向=yes)	!!!
p_aftc_flg:	equ	$97	*.b ｱﾌﾀｰﾀｯﾁｼｰｹﾝｽﾌﾗｸﾞ (0=off/$ff=on)			!!!
p_md_flg:	equ	$98	*d0 @b:ﾍﾞﾝﾄﾞ値をﾘｾｯﾄすべきかどうか(MIDI専用 0=no/1=yes)	!!!
				*d1 @m:ﾓｼﾞｭﾚｰｼｮﾝ値をﾘｾｯﾄするかしないか(MIDI専用 0=no/1=yes)
				*d2 @a:AM値をﾘｾｯﾄするかしないか(MIDI専用 0=no/1=yes)
				*d3 midi tie mode
				*d4 pmd first time? or not
				*d5 amd first time? or not
				*d6 pmd hold or not
				*d7 amd hold or not
p_waon_flg:	equ	$99	*.b 和音かそれともシングルか(0=single/$ff=chord)	!!!
p_pmod_dly:	equ	$9a	*.w モジュレーションディレイ値(FM/MIDI)	!!!順番をかえては
p_amod_dly:	equ	$9c	*.w ＡＭディレイ値(FM)			!!!ならない
p_arcc_dly:	equ	$9c	*.w ARCCディレイ値(MIDI)		!!!ならない
p_port_step:	equ	$9e	*.w ポルタメント用加算ワーク
p_bank_msb:	equ	$a0	*.b MIDI bank MSB
p_ol1:		equ	$a0	*.b (OUT PUT LEVEL OP1)
p_bank_lsb:	equ	$a1	*.b MIDI bank LSB
p_ol2:		equ	$a1	*.b (OUT PUT LEVEL OP2)
p_effect1:	equ	$a2	*.b effect parameter 1
p_ol3:		equ	$a2	*.b (OUT PUT LEVEL OP3)
p_effect3:	equ	$a3	*.b effect parameter 3
p_ol4:		equ	$a3	*.b (OUT PUT LEVEL OP4)
p_d6_last:	equ	$a4	*.b d6.bのワーク(MIDI)
p_cf:		equ	$a4	*.b (CARRIER かどうかのフラグ bit pattern:bit=1 carrier1)
p_amod_step2:	equ	$a5	*.b AMｽﾃｯﾌﾟﾜｰｸ
p_pb_add:	equ	$a6	*.b 未使用					!!!
p_vset_flg:	equ	$a7	*.b ボリュームリセットフラグ(FM)		!!!
p_arcc_rst:	equ	$a8	*.b ARCCのリセットバリュー(default:0)		!!!
p_arcc_def:	equ	$a9	*.b ARCCデフォルト値(default:127)		!!!
p_coda_ptr:	equ	$aa	*.l [coda]のある位置
p_pointer:	equ	$ae	*.l [segno]のある位置
p_do_loop_ptr:	equ	$b2	*.l [do]のある位置
p_pmod_work5:	equ	$b6	*.w ｽﾃｯﾌﾟﾀｲﾑの1/8(FM)
p_pmod_work6:	equ	$b8	*.w ｽﾃｯﾌﾟﾀｲﾑの1/8ワーク(FM)
p_amod_flg:	equ	$ba	*.b ARCCﾌﾗｸﾞ(FM)			!!!順番を
p_arcc_flg:	equ	$ba	*.b ARCCﾌﾗｸﾞ(MIDI)			!!!順番を
p_aftc_sw:	equ	$bb	*.b ｱﾌﾀｰﾀｯﾁｼｰｹﾝｽのｽｲｯﾁ(0=off/$ff=on)	!!!変えては
p_dumper:	equ	$bc	*.b dumper on or off (0=off/$ff=on)	!!!ならない
p_tie_flg:	equ	$bd	*.b タイだったか(0=no/ff=yes)		!!!
p_pmod_dpt:	equ	$be	*.w ﾋﾟｯﾁﾓｼﾞｭﾚｰｼｮﾝﾃﾞﾌﾟｽ(FM)			!!!
p_seq_flag:	equ	$c0	*.b []コマンド系の処理フラグビットパターン	!!!
				*d0:[d.c.]処理をしたことがあるか(0=no/1=yes)
				*d1:[fine]処理をすべきかどうか(0=no/1=yes)
				*d2:[coda]を以前に設定したことがあるか(0=no/1=yes)
				*d3:[segno]があるかないかのフラグ(0=no/1=yes)
				*d4:[d.s.]処理をしたことがあるか(0=no/1=yes)
				*d5 [!]コマンドワーク(0=normal/1=jumping)
				*d6:key off bit
				*d7:key on bit
p_do_loop_flag:	equ	$c1	*.b [do]が以前に設定されているか/ループ回数	!!!
p_pmod_spd:	equ	$c2	*.w ＰＭの１／４周期	!!!
p_amod_spd:	equ	$c4	*.w ＡＭの１／４周期	!!!
p_total_olp:	equ	$c6	*.l ﾙｰﾌﾟ外のﾄｰﾀﾙｽﾃｯﾌﾟｲﾑ
p_pmod_step:	equ	$ca	*.w ﾓｼﾞｭﾚｰｼｮﾝ用加算ワーク
p_tie_pmod:	equ	$cc	*.b tieの途中でパラメータチェンジが行われたかどうか	!!!
p_tie_bend:	equ	$cd	*.b (0=no,$ff=yes)					!!!
p_tie_amod:	equ	$ce	*.b							!!!
p_tie_arcc:	equ	$ce	*.b							!!!
p_tie_aftc:	equ	$cf	*.b							!!!
p_pan2:		equ	$d0	*.b パンポット(FM/MIDI L 0～M64～127 R)	!!!
p_non_off:	equ	$d1	*.b キーオフ無しモード(0=no,$ff=yes)	!!!
p_frq:		equ	$d2	*.b ADPCMの周波数(0-6)			!!!
p_velo:		equ	$d3	*.b velocity(0-127)			!!!
p_amod_work4:	equ	$d4	*.w ﾓｼﾞｭﾚｰｼｮﾝｽﾋﾟｰﾄﾞﾜｰｸ(FM)
p_pmod_rvs:	equ	$d6	*.b モジュレーション用補正ﾊﾟﾗﾒｰﾀ
p_waon_dly:	equ	$d7	*.b 和音用ディレイ値
p_waon_work:	equ	$d8	*.b 和音用ディレイワーク
p_waon_num:	equ	$d9	*.b 何番目ノーノートをキーオンするのか(minus=end)
p_note_last:	equ	$d9	*.b ノートの一時退避(MIDI)同時には起こり得ないから安心
p_rpt_cnt:	equ	$da	*.b repeat count work($da～$e1)
p_maker:	equ	$e2	*.b ﾒｰｶｰID(MIDI)
p_device:	equ	$e3	*.b ﾃﾞﾊﾞｲｽID(MIDI)
p_module:	equ	$e4	*.b ﾓｼﾞｭｰﾙID(MIDI)
p_last_aft:	equ	$e5	*.b 前回のアフタータッチ値(FM専用)
p_amod_work:	equ	$e6	*.w AMODﾃﾞｨﾚｲﾜｰｸ(FM)		!!!
p_arcc_work:	equ	$e6	*.w ARCCﾃﾞｨﾚｲﾜｰｸ(MIDI)		!!!
p_arcc_work2:	equ	$e8	*.b ARCCﾎﾟｲﾝﾄﾜｰｸ(MIDI)		!!!
p_amod_work2:	equ	$e8	*.b AMODﾎﾟｲﾝﾄﾜｰｸ(FM)		!!!
p_amod_work3:	equ	$e9	*.b ﾓｼﾞｭﾚｰｼｮﾝ用補正値ワーク(FM)	!!!
p_amod_work7:	equ	$ea	*.b ノコギリ波専用ワーク!!!
p_amod_n:	equ	$eb	*.b AMﾃｰﾌﾞﾙﾎﾟｲﾝﾀ(FM)	!!!
p_arcc_n:	equ	$eb	*.b ARCCﾃｰﾌﾞﾙﾎﾟｲﾝﾀ(MIDI)!!!
p_arcc_work5:	equ	$ec	*.w ｽﾃｯﾌﾟﾀｲﾑの1/8(FM)
p_amod_work5:	equ	$ec	*.w ｽﾃｯﾌﾟﾀｲﾑの1/8(FM)
p_arcc_work6:	equ	$ee	*.w ｽﾃｯﾌﾟﾀｲﾑの1/8ワーク(FM)
p_amod_work6:	equ	$ee	*.w ｽﾃｯﾌﾟﾀｲﾑの1/8ワーク(FM)
p_pmod_wf:	equ	$f0	*.b ソフトＬＦＯ(ＰＭ)の波形タイプ(FM:-1,0,1)	!!!
p_amod_dpt:	equ	$f1	*.b FM音源AMDデプス				!!!
p_amod_wf:	equ	$f2	*.b ソフトＬＦＯ(ＡＭ)の波形タイプ(FM:-1,0,1)	!!!
p_dmp_n:	equ	$f3	*.b FM音源用ダンパー処理ワーク			!!!
p_pmod_omt:	equ	$f4	*.b 1/8-PMODの省略ビットパターン			!!!
p_arcc_omt:	equ	$f5	*.b 1/8-ARCCの省略ビットパターン
p_amod_omt:	equ	$f5	*.b 1/8-AMODの省略ビットパターン			!!!
p_pmod_mode:	equ	$f6	*.b MIDIモジュレーションの形式(-1:normal/0:FM/1:MIDI)	!!!
p_arcc_mode:	equ	$f7	*.b MIDI ARCCの形式(-1:normal/1～127:extended mode)	!!!
p_pmod_chain:	equ	$f8	*.b PMの接続フラグ
p_amod_chain:	equ	$f9	*.b AMの接続フラグ
p_velo_dmy:	equ	$fa	*.b 臨時ベロシティ用ワーク				 !!!
p_waon_mark:	equ	$fb	*.b 主ﾁｬﾝﾈﾙのパラメータを設定したか(0=not yet,1=done)	 !!!
p_marker:	equ	$fc	*.w ﾌｪｰﾄﾞｱｳﾄ時に使用 (p_maker(a5)=se track or not,+1=flg)!!!
p_amod_rvs:	equ	$fe	*.b amod用補正値(FM)
p_ne_buff:	equ	$ff	*.b p_not_emptyの一時退避場所(se mode 専用ワーク)
p_user:		equ	$ff	*.b ユーザー汎用ワーク

*コンバート時のワークエリア
cnv_wk_size:	equ	$8c	*各トラックのMMLｺﾝﾊﾟｲﾙ用ﾜｰｸサイズ(絶対に偶数)

cv_data_adr:	equ	$00	*.l コンパイルデータポインタ
cv_l_com:	equ	$04	*.w デフォルト音長
cv_oct:		equ	$06	*.b オクターブ値
cv_device:	equ	$07	*.b 出力デバイス(0=internal ch / 1=adpcm / $ff=MIDI ch)
cv_len:		equ	$08	*.l コンパイルデータの現在の総サイズ
cv_rep_cnt:	equ	$0c	*.b リピートカウンタ管理ワーク($0c-$13)8個
cv_q_com:	equ	$14	*.w ゲートタイム
cv_cnv_flg:	equ	$16	*.b フラグワーク
				*d0 ﾍﾞﾛｼﾃｨｼｰｹﾝｽｽｲｯﾁ(0=off/1=on)
				*d1 臨時ベロシティ解除コード生成フラグ(0=off/1=on)
cv_velo_n:	equ	$17	*.b ベロシティシーケンス用ポインタ
cv_port_dly:	equ	$18	*.w ポルタメント用ディレイ
cv_bend_dly:	equ	$1a	*.w ベンドディレイ
cv_ktrans:	equ	$1c	*.b キートランスポーズ
cv_rltv_velo:	equ	$1d	*.b 相対ベロシティ値ワーク
cv_rltv_vol:	equ	$1e	*.b 相対ボリューム値ワーク
cv_waon_dly:	equ	$1f	*.b 和音用ディレイ
cv_velo2:	equ	$20	*.b 前回指定されたベロシティ(fmの場合はボリュームも表す)
cv_k_sig:	equ	$21	*.b 調号($21～$27)7個
cv_rep_start:	equ	$28	*.l |:(OPMDRV.xと互換を保つため)
cv_rep_exit:	equ	$2c	*.l |n用ワーク($2c～$4b)8個
cv_rep_addr:	equ	$4c	*.6bリピートアドレス管理テーブル(.l,.w)($4c～$7b)48Bytes
cv_velo:	equ	$7c	*.b ベロシティシーケンス用ワーク($7c～$8b)16個
*		equ	$8c	*.b

		.list
