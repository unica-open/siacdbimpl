/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- Function: fnc_siac_bko_config_report_prevind_xbrl()

-- DROP FUNCTION fnc_siac_bko_config_report_prevind_xbrl();

CREATE OR REPLACE FUNCTION fnc_siac_bko_config_report_BILR124_xbrl()
  RETURNS character varying AS
$BODY$
DECLARE
  rec_enti	record;
  sMsgReturn	varchar(1000):='';
  nIdEnte	integer;
BEGIN
    sMsgReturn:='';
    for rec_enti in
      select A.ente_proprietario_id, A.ente_denominazione, D.eptipo_code
      from siac_t_ente_proprietario A, siac_r_ente_proprietario_tipo T, siac_d_ente_proprietario_tipo D
      where A.ente_proprietario_id = T.ente_proprietario_id
        and T.eptipo_id = D.eptipo_id
      order by A.ente_proprietario_id  
    loop
      nIdEnte:=rec_enti.ente_proprietario_id;

      DELETE FROM siac.siac_t_xbrl_mapping_fatti WHERE xbrl_mapfat_rep_codice='BILR124' AND ente_proprietario_id=nIdEnte;
      DELETE FROM siac.siac_t_xbrl_report WHERE xbrl_rep_codice='BILR124' AND ente_proprietario_id=nIdEnte;

      INSERT INTO siac.siac_t_xbrl_report (xbrl_rep_codice,  xbrl_rep_fase_code,  xbrl_rep_tipologia_code,  xbrl_rep_xsd_tassonomia,  validita_inizio,  ente_proprietario_id,  login_operazione) VALUES ('BILR124','REND','SDB','bdap-sdb-rend-enti_2017-09-29.xsd',now(),nIdEnte,'admin');

      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotResiduiPassEsePrecMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_EP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotResiduiPassEserCompetMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_EC','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotTotResPassRiportMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_TR','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotResiduiPassiviMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_RS','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPrevDefCompetenzaMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_CP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPrevDefCassaMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_CS','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPagamResiduiMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_PR','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotEconomieCompetMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_ECP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','ResiduiPassivi','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[= ''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_RS','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','PrevDefCompetenza','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_CP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','PrevDefCassa','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_CS','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','PagamResidui','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_PR','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','PagamCompetenza','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_PC','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotalePagamenti','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_TP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','RiaccResidui','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_R','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','Impegni','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_I','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','FondoPluriVinc','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_FPV','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','EconomieCompet','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_ECP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','ResiduiPassEserPrec','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_EP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','ResiduiPassEserCompet','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_EC','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotResPassRiport','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_TR','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotResiduiPassiviProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_RS','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPrevDefCompetenzaProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_CP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPrevDefCassaProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_CS','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPagamResiduiProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_PR','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPagamCompetenzaProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_PC','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotalePagamentiProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_TP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotRiaccResiduiProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_R','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotImpegniProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_I','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotFondoPluriVincProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_FPV','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotEconomieCompetProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_ECP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotResiduiPassEserPrecProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_EP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotResiduiPassEserCompetProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_EC','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotTotResPassRiportProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_TR','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotResiduiPassiviMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_RS','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPrevDefCassaMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_CS','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPagamResiduiMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_PR','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPagamCompetenzaMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_PC','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotalePagamentiMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_TP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotRiaccResiduiMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_R','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotImpegniMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_I','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotFondoPluriVincMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_FPV','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPagamCompetenzaMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_PC','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotalePagamentiMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_TP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotRiaccResiduiMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_R','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotImpegniMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_I','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotFondoPluriVincMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_FPV','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotEconomieCompetMissCompl2','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_ECP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotResiduiPassEsePrecMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_EP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotResiduiPassEserCompetMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_EC','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotTotResPassRiportMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_TR','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPrevDefCompetenzaMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_CP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
    end loop;

    return sMsgReturn;

exception
	when others THEN
		raise notice 'Errore di configurazione' ;
		sMsgReturn:='Errore di configurazione';
		return sMsgReturn;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fnc_siac_bko_config_report_BILR124_xbrl()
  OWNER TO siac;
GRANT EXECUTE ON FUNCTION fnc_siac_bko_config_report_BILR124_xbrl() TO public;
GRANT EXECUTE ON FUNCTION fnc_siac_bko_config_report_BILR124_xbrl() TO siac;
GRANT EXECUTE ON FUNCTION fnc_siac_bko_config_report_BILR124_xbrl() TO siac_rw;