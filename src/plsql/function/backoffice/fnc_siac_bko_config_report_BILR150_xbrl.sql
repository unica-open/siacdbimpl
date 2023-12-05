/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- Function: fnc_siac_bko_config_report_BILR150_xbrl()


CREATE OR REPLACE FUNCTION fnc_siac_bko_config_report_BILR150_xbrl()
  RETURNS character varying AS
$BODY$
DECLARE
  rec_enti	record;
  sMsgReturn	varchar(1000):='';
  sReport varchar(10);
  nIdEnte	integer;
BEGIN
    sReport:='BILR150';
    sMsgReturn:='';
    for rec_enti in
      select A.ente_proprietario_id, A.ente_denominazione, D.eptipo_code
      from siac_t_ente_proprietario A, siac_r_ente_proprietario_tipo T, siac_d_ente_proprietario_tipo D
      where A.ente_proprietario_id = T.ente_proprietario_id
        and T.eptipo_id = D.eptipo_id
      order by A.ente_proprietario_id
    loop
      nIdEnte:=rec_enti.ente_proprietario_id;

      DELETE FROM siac.siac_t_xbrl_mapping_fatti WHERE xbrl_mapfat_rep_codice=sReport AND ente_proprietario_id=nIdEnte;
      DELETE FROM siac.siac_t_xbrl_report WHERE xbrl_rep_codice=sReport AND ente_proprietario_id=nIdEnte;

      INSERT INTO siac.siac_t_xbrl_report (xbrl_rep_codice,  xbrl_rep_fase_code,  xbrl_rep_tipologia_code,  xbrl_rep_xsd_tassonomia,  validita_inizio,  ente_proprietario_id,  login_operazione) VALUES ('BILR150','REND','SDB','bdap-sdb-rend_2017-09-29.xsd',now(),nIdEnte,'admin');

      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','fondo_cassa_ini_eser','RISAMM_FondoCassa1Gen','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','tot_riscossioni','RISAMM_Riscossioni','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','tot_riscossioni_residui','RISAMM_RiscossioniResidui','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','tot_riscossioni_competenza','RISAMM_RiscossioniCompetenza','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','tot_pagamenti','RISAMM_Pagamenti','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','tot_pagamenti_residui','RISAMM_PagamentiResidui','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','tot_pagamenti_competenza','RISAMM_PagamentiCompetenza','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','saldo_cassa_31_dicembre','RISAMM_SaldoCassa31Dic','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','pagam_azioni_esecutive','RISAMM_PagamentiAzioniEsecutiveNonRegolarizzate31Dic','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','fondo_cassa_31_dicembre','RISAMM_FondoCassa31Dic','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','totale_residui_attivi','RISAMM_ResiduiAttivi','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','tot_residui_attivi_residui','RISAMM_ResiduiAttiviResidui','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','tot_residui_attivi_competenza','RISAMM_ResiduiAttiviCompetenza','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','di_cui_deriv_accertamenti','RISAMM_ResiduiAttiviDaAccertamentiTributi','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','totale_residui_passivi','RISAMM_ResiduiPassivi','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','tot_residui_passivi_residui','RISAMM_ResiduiPassiviResidui','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','tot_residui_passivi_competenza','RISAMM_ResiduiPassiviCompetenza','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','tot_fpv_spese_correnti','RISAMM_FondoPluriennaleVincolatoSpeseCorrenti','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','tot_fpv_conto_capitale','RISAMM_FondoPluriennaleVincolatoSpeseContoCapitale','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','ris_amm_31_dicembre','RISAMM_RisultatoAmministrazione31Dic','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','fondo_crediti_dubbia_esi','RISAMM_AccantFondoCreditiDubbiaEsigibilita','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','fondo_anticipaz_liquid','RISAMM_AccantFondoAnticipazioniLiquidita','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','fondo_perdite_soc_partecipate','RISAMM_AccantFondoPerditeSocietaPartecipate','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','fondo_contenzioso','RISAMM_AccantFondoContenzioso','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','altri_accantonamenti','RISAMM_AccantAltri','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','totale_parte_accantonata','RISAMM_ParteAccantonataTotale','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','vincoli_leggi_princ_contabili','RISAMM_VincoliLeggiPrincipiContabili','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','vincoli_trasferimenti','RISAMM_VincoliTrasferimenti','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','vincoli_contraz_mutui','RISAMM_VincoliContrazioneMutui','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','vincoli_attrib_ente','RISAMM_VincoliAttributiEnte','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','vincoli_altri','RISAMM_VincoliAltri','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','totale_parte_vincolata','RISAMM_ParteVincolataTotale','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','totale_parte_investimenti','RISAMM_ParteDestinataInvestimentiTotale','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','totale_parte_disponibile','RISAMM_ParteDisponibile','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR150','accantonamenti_residui_perenti','RISAMM_AccantResiduiPerenti','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
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
ALTER FUNCTION fnc_siac_bko_config_report_BILR150_xbrl()
  OWNER TO siac;
GRANT EXECUTE ON FUNCTION fnc_siac_bko_config_report_BILR150_xbrl() TO public;
GRANT EXECUTE ON FUNCTION fnc_siac_bko_config_report_BILR150_xbrl() TO siac;
GRANT EXECUTE ON FUNCTION fnc_siac_bko_config_report_BILR150_xbrl() TO siac_rw;
