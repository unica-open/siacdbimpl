/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR228_parametri_obiettivi_per_comuni" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_code_report varchar
)
RETURNS TABLE (
  importo_p1 numeric,
  importo_p2 numeric,
  importo_p3 numeric,
  importo_p4 numeric,
  importo_p5 numeric,
  importo_p6 numeric,
  importo_p7 numeric,
  importo_p8 numeric,
  nome_ente varchar,
  sigla_prov varchar,
  provincia varchar,
  display_error varchar
) AS
$body$
DECLARE

RTN_MESSAGGIO text;
denom_ente varchar;

variabiliRendiconto record;
entrataRendiconto record;
spesaRendiconto record;
fpvAnnoPrecRendiconto record;

ripiano_disav_rnd numeric;
anticip_tesoreria_rnd numeric;
max_previsto_norma_rnd numeric;
impegni_estinz_anticip_rnd numeric;
disav_iscrit_spesa_rnd numeric;
importo_debiti_fuori_bil_ricon_rnd numeric;
importo_debiti_fuori_bil_corso_ricon_rnd numeric;
importo_debiti_fuori_bil_ricon_corso_finanz_rnd numeric;

rend_accert_A_titoli_123 numeric; 
rend_prev_def_cassa_CS_titoli_123 numeric; 
rend_risc_conto_comp_RC_pdce_E_1_01 numeric;
rend_risc_conto_res_RR_pdce_E_1_01 numeric;
rend_risc_conto_comp_RC_pdce_E_1_01_04 numeric;
rend_risc_conto_res_RR_pdce_E_1_01_04 numeric;
rend_risc_conto_comp_RC_pdce_E_3 numeric;
rend_risc_conto_res_RR_pdce_E_3 numeric;
rend_accert_A_pdce_E_4_02_06 numeric;
rend_accert_A_pdce_E_4_03_01 numeric;
rend_accert_A_pdce_E_4_03_04 numeric;
TotaleRiscossioniTR numeric;
TotaleAccertatoA numeric;
TotaleResAttiviRS numeric;

rend_impegni_I_macroagg101 numeric;
rend_FPV_macroagg_101 numeric;
rend_impegni_I_macroagg107 numeric;
rend_impegni_I_titolo_4 numeric;
rend_impegni_I_pdce_U_1_02_01_01 numeric;
rend_FPV_anno_prec_macroagg101 numeric;
rend_impegni_i_pdce_U_1_07_06_02 numeric;
rend_impegni_i_pdce_U_1_07_06_04 numeric;
rend_impegni_I_titoli_1_2 numeric;

indic_13_2_app numeric;
indic_13_3_app numeric;

id_report_config integer;

BEGIN

/*
	Questa procedura e' utilizzata dai report BILR228, BILR229, BILR330, BILR331,
    BILR332, BILR333, BILR334 e BILR335 per estrarre i dati che servono per il 
    calcolo dei paramentri obiettivi.
    I dati sono quelli estratti per gli indicatori di rendiconto.
    Sono estratti i dati delle variabili e per farlo sono richiamate le seguenti 
    procedure usate nei report degli indicatori:
    - BILR186_indic_sint_ent_rend_org_er; per le entrate;
    - BILR186_indic_sint_spe_rend_org_er; per le spese;
    - BILR186_indic_sint_spe_rend_FPV_anno_prec; per l'FPV anno precedente.
    
    La procedura effettua il calcolo dei singoli valori usati per il calcolo
    applicando gli algoritmi che per gli indicatori sono utilizzati all'interno 
    dei report.
    In questo modo la procedura restiruisce i valori degli indicatori gia' calcolati
    ed il report deve solo mostrarne il valore ed eventualmente cambiare il colore
    della cella se il dato e' fuori soglia.
    
*/

importo_p1:=0;
importo_p2:=0;
importo_p3:=0;
importo_p4:=0;
importo_p5:=0;
importo_p6:=0;
importo_p7:=0;
importo_p8:=0;
nome_ente:='';
sigla_prov:='';
provincia:='';
display_error:='';

select ente_denominazione
	into denom_ente
from siac_t_ente_proprietario
where ente_proprietario_id = p_ente_prop_id
	and data_cancellazione IS NULL;

if denom_ente IS NULL THEN
	denom_ente :='';
end if;
    
raise notice 'Ente = %', denom_ente;

--verifico se l'ente e' abilitato all'utilizzo del report.
id_report_config:=NULL;
select a.report_param_def_id, a.nome_ente, a.sigla_prov, a.provincia
into id_report_config, nome_ente, sigla_prov, provincia
from siac_t_config_ente_report_param_def a
where a.ente_proprietario_id = p_ente_prop_id
	and a.rep_codice = p_code_report
    and a.data_cancellazione IS NULL
    and a.validita_fine IS NULL;
 
raise notice 'id_report_config = %', id_report_config;

if id_report_config IS NULL THEN
	display_error := 'L''ENTE ''' || denom_ente || ''' NON E'' ABILITATO ALL''UTILIZZO DEL REPORT '||p_code_report;
    nome_ente:=denom_ente;
    return next;
    return;
end if;


  
--variabili
ripiano_disav_rnd:=0;
anticip_tesoreria_rnd:=0;
max_previsto_norma_rnd:=0;
impegni_estinz_anticip_rnd:=0;
disav_iscrit_spesa_rnd:=0;
importo_debiti_fuori_bil_ricon_rnd:=0;
importo_debiti_fuori_bil_corso_ricon_rnd:=0;
importo_debiti_fuori_bil_ricon_corso_finanz_rnd:=0;
indic_13_2_app:=0;
indic_13_3_app:=0;


--entrate importo_accertato_a titoli 1,2,3
rend_accert_A_titoli_123:=0;
--entrate importo_prev_def_cassa_cs titoli 1,2,3
rend_prev_def_cassa_CS_titoli_123:=0;
--entrate importo_risc_conto_comp_rc pdce 'E.1.01'
rend_risc_conto_comp_RC_pdce_E_1_01 :=0;
--entrate importo_risc_conto_comp_rc pdce  'E.1.01.04'
rend_risc_conto_comp_RC_pdce_E_1_01_04:=0;
--entrate importo_risc_conto_comp_rc pdce   'E.3'
rend_risc_conto_comp_RC_pdce_E_3:=0;
--entrate "importo_risc_conto_res_rr pdce   'E.1.01'
rend_risc_conto_res_RR_pdce_E_1_01:=0;
--entrate "importo_risc_conto_res_rr pdce   'E.1.01.04'
rend_risc_conto_res_RR_pdce_E_1_01_04:=0;
--entrate "importo_risc_conto_res_rr pdce   'E.3'
rend_risc_conto_res_RR_pdce_E_3:=0;
--entrate importo_accertato_a pdce   'E.4.02.06'
rend_accert_A_pdce_E_4_02_06:=0;
--entrate importo_accertato_a pdce   'E.4.03.01'
rend_accert_A_pdce_E_4_03_01:=0;
--entrate importo_accertato_a pdce   'E.4.03.04'
rend_accert_A_pdce_E_4_03_04:=0;
--entrate totale RISCOSSIONI 
TotaleRiscossioniTR:=0;
--entrate totale ACCERTATO
TotaleAccertatoA:=0;
--entrate totale RSIDUI ATTIVI
TotaleResAttiviRS:=0;

--spese imp_impegnato_i macroagg '101'
rend_impegni_I_macroagg101:=0;
--spese imp_impegnato_i FPV macroagg '101'
rend_FPV_macroagg_101:=0;
--spese imp_impegnato_i macroagg '107'
rend_impegni_I_macroagg107:=0;
--spese imp_impegnato_i titolo '4'
rend_impegni_I_titolo_4:=0;
--spese imp_impegnato_i pdce 'U.1.02.01.01'
rend_impegni_I_pdce_U_1_02_01_01:=0;
--spese anno_prec spese_fpv_anni_prec macroagg '101'
rend_FPV_anno_prec_macroagg101:=0;
--spese imp_impegnato_i pdce 'U.1.07.06.02'
rend_impegni_i_pdce_U_1_07_06_02:=0;
--spese imp_impegnato_i pdce 'U.1.07.06.04'
rend_impegni_i_pdce_U_1_07_06_04:=0;
--spese imp_impegnato_i titoli '1', '2'
rend_impegni_I_titoli_1_2:=0;

	-- estraggo la parte relativa alle variabili.
for variabiliRendiconto IN
  select t_voce_conf_indicatori_sint.voce_conf_ind_codice,
      t_voce_conf_indicatori_sint.voce_conf_ind_desc,
      t_conf_indicatori_sint.conf_ind_valore_anno,
      t_conf_indicatori_sint.conf_ind_valore_anno_1,
      t_conf_indicatori_sint.conf_ind_valore_anno_2
  from siac_t_conf_indicatori_sint t_conf_indicatori_sint,
      siac_t_voce_conf_indicatori_sint t_voce_conf_indicatori_sint,
      siac_t_bil t_bil,
      siac_t_periodo t_periodo
  where t_conf_indicatori_sint.bil_id=t_bil.bil_id
      and t_bil.periodo_id=t_periodo.periodo_id
      and t_voce_conf_indicatori_sint.voce_conf_ind_id=t_conf_indicatori_sint.voce_conf_ind_id
      and t_conf_indicatori_sint.ente_proprietario_id =p_ente_prop_id
      and t_periodo.anno=p_anno
      and t_voce_conf_indicatori_sint.voce_conf_ind_tipo='R'
      and t_voce_conf_indicatori_sint.voce_conf_ind_codice in ('ripiano_disav_rnd',
      	'anticip_tesoreria_rnd', 'max_previsto_norma_rnd','impegni_estinz_anticip_rnd',
        'importo_debiti_fuori_bil_ricon_rnd','importo_debiti_fuori_bil_corso_ricon_rnd',
        'importo_debiti_fuori_bil_ricon_corso_finanz_rnd')
      and t_conf_indicatori_sint.data_cancellazione IS NULL
      and t_bil.data_cancellazione IS NULL
      and t_periodo.data_cancellazione IS NULL
      and t_voce_conf_indicatori_sint.data_cancellazione IS NULL
loop
      if variabiliRendiconto.voce_conf_ind_codice = 'ripiano_disav_rnd' THEN
      	ripiano_disav_rnd := COALESCE(variabiliRendiconto.conf_ind_valore_anno,0);
      end if;
      if variabiliRendiconto.voce_conf_ind_codice = 'anticip_tesoreria_rnd' THEN
      	anticip_tesoreria_rnd := COALESCE(variabiliRendiconto.conf_ind_valore_anno,0);
      end if;
      if variabiliRendiconto.voce_conf_ind_codice = 'max_previsto_norma_rnd' THEN
      	max_previsto_norma_rnd := COALESCE(variabiliRendiconto.conf_ind_valore_anno,0);
      end if;
      if variabiliRendiconto.voce_conf_ind_codice = 'impegni_estinz_anticip_rnd' THEN
      	impegni_estinz_anticip_rnd := COALESCE(variabiliRendiconto.conf_ind_valore_anno,0);
      end if;           
      if variabiliRendiconto.voce_conf_ind_codice = 'importo_debiti_fuori_bil_ricon_rnd' THEN
      	importo_debiti_fuori_bil_ricon_rnd := COALESCE(variabiliRendiconto.conf_ind_valore_anno,0);
      end if;   
      if variabiliRendiconto.voce_conf_ind_codice = 'importo_debiti_fuori_bil_corso_ricon_rnd' THEN
      	importo_debiti_fuori_bil_corso_ricon_rnd := COALESCE(variabiliRendiconto.conf_ind_valore_anno,0);
      end if;  
      if variabiliRendiconto.voce_conf_ind_codice = 'importo_debiti_fuori_bil_ricon_corso_finanz_rnd' THEN
      	importo_debiti_fuori_bil_ricon_corso_finanz_rnd := COALESCE(variabiliRendiconto.conf_ind_valore_anno,0);
      end if;        
end loop;


	-- estraggo la parte relativa al rendiconto di ENTRATA e calcolo
    -- i singoli valori.
for entrataRendiconto in  
  select code_titolo, pdce_code,
      sum(importo_accertato_a) importo_accertato_a, 
      sum(importo_prev_def_cassa_cs) importo_prev_def_cassa_cs, 
      sum(importo_risc_conto_comp_rc) importo_risc_conto_comp_rc,
      sum(importo_risc_conto_res_rr) importo_risc_conto_res_rr,
      sum(importo_tot_risc_tr) importo_tot_risc_tr   ,
      sum(importo_res_attivi_rs) importo_res_attivi_rs
  from "BILR186_indic_sint_ent_rend_org_er"(p_ente_prop_id, p_anno)
  group by code_titolo, pdce_code
loop 
	TotaleRiscossioniTR:= TotaleRiscossioniTR +
    	COALESCE(entrataRendiconto.importo_tot_risc_tr,0);
    TotaleAccertatoA:=TotaleAccertatoA +
    	COALESCE(entrataRendiconto.importo_accertato_a,0);   
    TotaleResAttiviRS:= TotaleResAttiviRS +
    	COALESCE(entrataRendiconto.importo_res_attivi_rs,0);      

	if entrataRendiconto.code_titolo in ('1','2','3') THEN
    	rend_accert_A_titoli_123:=rend_accert_A_titoli_123 +
        	COALESCE(entrataRendiconto.importo_accertato_a,0);
        rend_prev_def_cassa_CS_titoli_123:=rend_prev_def_cassa_CS_titoli_123 +
        	COALESCE(entrataRendiconto.importo_prev_def_cassa_cs,0);
    end if;
    if left(entrataRendiconto.pdce_code,6) = 'E.1.01' then
    	rend_risc_conto_comp_RC_pdce_E_1_01:=rend_risc_conto_comp_RC_pdce_E_1_01 +
        	COALESCE(entrataRendiconto.importo_risc_conto_comp_rc,0);
        rend_risc_conto_res_RR_pdce_E_1_01:=rend_risc_conto_res_RR_pdce_E_1_01 +
        	COALESCE(entrataRendiconto.importo_risc_conto_res_rr,0);
    end if;
    if left(entrataRendiconto.pdce_code,9) = 'E.1.01.04' then
    	rend_risc_conto_comp_RC_pdce_E_1_01_04:=rend_risc_conto_comp_RC_pdce_E_1_01_04 +
        	COALESCE(entrataRendiconto.importo_risc_conto_comp_rc,0);
        rend_risc_conto_res_RR_pdce_E_1_01_04:=rend_risc_conto_res_RR_pdce_E_1_01_04 +
        	COALESCE(entrataRendiconto.importo_risc_conto_res_rr,0);
    end if;
    if left(entrataRendiconto.pdce_code,3) = 'E.3' then
    	rend_risc_conto_comp_RC_pdce_E_3:=rend_risc_conto_comp_RC_pdce_E_3 +
        	COALESCE(entrataRendiconto.importo_risc_conto_comp_rc,0);
        rend_risc_conto_res_RR_pdce_E_3:=rend_risc_conto_res_RR_pdce_E_3 +
        	COALESCE(entrataRendiconto.importo_risc_conto_res_rr,0);
    end if;    
    if left(entrataRendiconto.pdce_code,9) = 'E.4.02.06' then
    	rend_accert_A_pdce_E_4_02_06:=rend_accert_A_pdce_E_4_02_06 +
        	COALESCE(entrataRendiconto.importo_risc_conto_comp_rc,0);
    end if;       
    if left(entrataRendiconto.pdce_code,9) = 'E.4.03.01' then
    	rend_accert_A_pdce_E_4_03_01:=rend_accert_A_pdce_E_4_03_01 +
        	COALESCE(entrataRendiconto.importo_risc_conto_comp_rc,0);
    end if;        
    if left(entrataRendiconto.pdce_code,9) = 'E.4.03.04' then
    	rend_accert_A_pdce_E_4_03_04:=rend_accert_A_pdce_E_4_03_04 +
        	COALESCE(entrataRendiconto.importo_risc_conto_comp_rc,0);
    end if;            

    
end loop;

	-- estraggo la parte relativa al rendiconto di SPESA e calcolo
    -- i singoli valori.
for spesaRendiconto in  
  select code_titolo, code_macroagg, tipo_capitolo, pdce_code,
      sum(imp_impegnato_i) imp_impegnato_i 
  from "BILR186_indic_sint_spe_rend_org_er"(p_ente_prop_id, p_anno)
  group by code_titolo, code_macroagg, tipo_capitolo, pdce_code
loop 
	if left(spesaRendiconto.code_macroagg,3) = '101' then
    	rend_impegni_I_macroagg101:=rend_impegni_I_macroagg101+
        	COALESCE(spesaRendiconto.imp_impegnato_i,0);
        if spesaRendiconto.tipo_capitolo = 'FPV' then
        	rend_FPV_macroagg_101:=rend_FPV_macroagg_101+
            	COALESCE(spesaRendiconto.imp_impegnato_i,0);
        end if;
    end if;
    if left(spesaRendiconto.code_macroagg,3) = '107' then
		rend_impegni_I_macroagg107:=rend_impegni_I_macroagg107+
        	COALESCE(spesaRendiconto.imp_impegnato_i,0);
    end if;
    if  spesaRendiconto.code_titolo = '4' then
		rend_impegni_I_titolo_4:=rend_impegni_I_titolo_4+
        	COALESCE(spesaRendiconto.imp_impegnato_i,0);
    end if;    
    if  left(spesaRendiconto.pdce_code,12) = 'U.1.02.01.01' then
		rend_impegni_I_pdce_U_1_02_01_01:=rend_impegni_I_pdce_U_1_02_01_01+
        	COALESCE(spesaRendiconto.imp_impegnato_i,0);
    end if;  
    if  left(spesaRendiconto.pdce_code,12) = 'U.1.07.06.02' then
		rend_impegni_i_pdce_U_1_07_06_02:=rend_impegni_i_pdce_U_1_07_06_02+
        	COALESCE(spesaRendiconto.imp_impegnato_i,0);
    end if;  
    if  left(spesaRendiconto.pdce_code,12) = 'U.1.07.06.04' then
		rend_impegni_i_pdce_U_1_07_06_04:=rend_impegni_i_pdce_U_1_07_06_04+
        	COALESCE(spesaRendiconto.imp_impegnato_i,0);
    end if;  
    if  spesaRendiconto.code_titolo in ('1','2') then
		rend_impegni_I_titoli_1_2:=rend_impegni_I_titoli_1_2+
        	COALESCE(spesaRendiconto.imp_impegnato_i,0);
    end if;  

end loop;

	--estraggo il valore FPV anno precedente per macroaggreagato 101.
select COALESCE(sum(spese_fpv_anni_prec),0) 
	into rend_FPV_anno_prec_macroagg101
   from "BILR186_indic_sint_spe_rend_FPV_anno_prec"(p_ente_prop_id, p_anno)
   where left(code_macroagg,3) = '101';

/* I commenti riportati nel seguito per ogni variabile sono i calcoli che
	vengono effettuati all'interno dei report degli indicatori.
*/    

/* IMPORTO P1 = Indicatore 1.2 = 
	var Denom = row._outer["rend_accert_A_titoli_123"];

	(dataSetRow["ripiano_disav_rnd"]+
	 row._outer._outer._outer["rend_impegni_I_macroagg101"] +
	 row._outer._outer._outer["rend_impegni_I_pdce_U.1.02.01.01"] -
	 row._outer._outer["rend_FPV_anno_prec_macroagg101"] +
 	 row._outer._outer._outer["rend_FPV_macroagg_101"] +
 	 row._outer._outer._outer["rend_impegni_I_macroagg107"] +
 	 row._outer._outer._outer["rend_impegni_I_titolo_4"]) /
 	 Denom;
*/
if rend_accert_A_titoli_123 != 0 then
	importo_p1 :=
		(ripiano_disav_rnd + rend_impegni_I_macroagg101
        + rend_impegni_I_pdce_U_1_02_01_01 
        - rend_FPV_anno_prec_macroagg101 + rend_FPV_macroagg_101
        + rend_impegni_I_macroagg107 + rend_impegni_I_titolo_4) /
        rend_accert_A_titoli_123;
end if;

/* IMPORTO P2 = Indicatore 2.8 = 
	(dataSetRow["rend_risc_conto_comp_RC_pdce_E.1.01"] + dataSetRow["rend_risc_conto_res_RR_pdce_E.1.01"]
	 - dataSetRow["rend_risc_conto_comp_RC_pdce_E.1.01.04"] - dataSetRow["rend_risc_conto_res_RR_pdce_E.1.01.04"]
	 +dataSetRow["rend_risc_conto_comp_RC_pdce_E.3"] +dataSetRow["rend_risc_conto_res_RR_pdce_E.3"]) /
	dataSetRow["rend_prev_def_cassa_CS_titoli_123"]
*/    
if rend_prev_def_cassa_CS_titoli_123 != 0 then
	importo_p2 := 
	(rend_risc_conto_comp_RC_pdce_E_1_01+rend_risc_conto_res_RR_pdce_E_1_01
     - rend_risc_conto_comp_RC_pdce_E_1_01_04 - rend_risc_conto_res_RR_pdce_E_1_01_04 
     + rend_risc_conto_comp_RC_pdce_E_3 + rend_risc_conto_res_RR_pdce_E_3) /
	rend_prev_def_cassa_CS_titoli_123;
end if;

/* IMPORTO P3 = Indicatore 3.2 = 
	dataSetRow["anticip_tesoreria_rnd"] /
	dataSetRow["max_previsto_norma_rnd"];
*/
if max_previsto_norma_rnd != 0 then
	importo_p3 := anticip_tesoreria_rnd / max_previsto_norma_rnd;
end if;

/* IMPORTO P4 = Indicatore 10.3 =
(row._outer._outer["rend_impegni_I_macroagg107"] -
	 row._outer._outer["rend_impegni_I_pdce_U.1.07.06.02"] -
	 row._outer._outer["rend_impegni_I_pdce_U.1.07.06.04"] +
	 row._outer._outer["rend_impegni_I_titolo_4"] -
	 row["impegni_estinz_anticip_rnd"] -
	 (row._outer["rend_accert_A_pdce_E.4.02.06"] +
	  row._outer["rend_accert_A_pdce_E.4.03.01"] +
	  row._outer["rend_accert_A_pdce_E.4.03.04"])) /
	  row._outer["rend_accert_A_titoli_123"];
*/

if rend_accert_A_titoli_123 != 0 then
	importo_p4 := 
    (rend_impegni_I_macroagg107 - rend_impegni_i_pdce_U_1_07_06_02
     - rend_impegni_i_pdce_U_1_07_06_04 + rend_impegni_I_titolo_4
     - impegni_estinz_anticip_rnd
     - (rend_accert_A_pdce_E_4_02_06 + rend_accert_A_pdce_E_4_03_01
        + rend_accert_A_pdce_E_4_03_04)) /
    rend_accert_A_titoli_123;
end if;

/* IMPORTO P5 = Indicatore 12.4 =
	dataSetRow["disav_iscrit_spesa_rnd"] /
	row._outer["rend_accert_A_titoli_123"];
    
*/

if rend_accert_A_titoli_123 != 0 then
	importo_p5 := disav_iscrit_spesa_rnd / rend_accert_A_titoli_123;
end if;    

/* IMPORTO P6 = Indicatore 13.1 =
    	dataSetRow["importo_debiti_fuori_bil_ricon_rnd"] /
	row._outer["rend_impegni_I_titoli_1_2"];
    
*/

if rend_impegni_I_titoli_1_2 != 0 then
	importo_p6 := 
    	importo_debiti_fuori_bil_ricon_rnd/ rend_impegni_I_titoli_1_2;
end if;



/* IMPORTO P7 = Indicatore 13.2 + 13.3 =
	13.2
		dataSetRow["importo_debiti_fuori_bil_corso_ricon_rnd"] /
		row._outer["rend_accert_A_titoli_123"];
    13.3
    dataSetRow["importo_debiti_fuori_bil_ricon_corso_finanz_rnd"] /
		row._outer["rend_accert_A_titoli_123"] ;
*/    
if rend_accert_A_titoli_123 != 0 then
	importo_p7 :=
    	(importo_debiti_fuori_bil_corso_ricon_rnd / rend_accert_A_titoli_123) +
        (importo_debiti_fuori_bil_ricon_corso_finanz_rnd / rend_accert_A_titoli_123);
end if;

/* IMPORTO P8 = Indicatore Analitico report BILR191, colonna
% di riscossione complessiva: (Riscossioni c/comp+ Riscossioni c/residui)/ 
	(Accertamenti + residui definitivi iniziali)
    
    Poiche' la procedura BILR181_indic_ana_ent_rend_org_er (usata nel report BILR91)
    estrae gli stessi dati della BILR186_indic_sint_ent_rend_org_er solo raggruppati
    in modo diverso evito di chiamare la BILR181_indic_ana_ent_rend_org_er in quanto
    serve solo il dato toale.
    
	row._outer["TotaleRiscossioniTR"] / 
	(row._outer["TotaleAccertatoA"] + row._outer["TotaleResAttiviRS"]);    

*/
if TotaleAccertatoA + TotaleResAttiviRS != 0 then	
	importo_p8 :=
		TotaleRiscossioniTR /
		(TotaleAccertatoA + TotaleResAttiviRS);
end if;
        
raise notice '';
raise notice '               IMPORTI VARIABILI';
raise notice 'ripiano_disav_rnd = %', ripiano_disav_rnd;
raise notice 'anticip_tesoreria_rnd = %', anticip_tesoreria_rnd;
raise notice 'max_previsto_norma_rnd = %', max_previsto_norma_rnd;
raise notice 'impegni_estinz_anticip_rnd = %', impegni_estinz_anticip_rnd;
raise notice 'importo_debiti_fuori_bil_ricon_rnd = %', importo_debiti_fuori_bil_ricon_rnd;
raise notice 'importo_debiti_fuori_bil_corso_ricon_rnd = %', importo_debiti_fuori_bil_corso_ricon_rnd;
raise notice 'importo_debiti_fuori_bil_ricon_corso_finanz_rnd = %', importo_debiti_fuori_bil_ricon_corso_finanz_rnd;

raise notice '';
raise notice '               IMPORTI ENTRATE'; 
raise notice 'rend_accert_A_titoli_123 = %', rend_accert_A_titoli_123;
raise notice 'rend_prev_def_cassa_CS_titoli_123 = %', rend_prev_def_cassa_CS_titoli_123;
raise notice 'rend_risc_conto_comp_RC_pdce_E_1_01 = %', rend_risc_conto_comp_RC_pdce_E_1_01;
raise notice 'rend_risc_conto_res_RR_pdce_E_1_01 = %', rend_risc_conto_res_RR_pdce_E_1_01;
raise notice 'rend_risc_conto_comp_RC_pdce_E_1_01_04 = %', rend_risc_conto_comp_RC_pdce_E_1_01_04;
raise notice 'rend_risc_conto_res_RR_pdce_E_1_01_04 = %', rend_risc_conto_res_RR_pdce_E_1_01_04;
raise notice 'rend_risc_conto_comp_RC_pdce_E_3 = %', rend_risc_conto_comp_RC_pdce_E_3;
raise notice 'rend_risc_conto_res_RR_pdce_E_3 = %', rend_risc_conto_res_RR_pdce_E_3;  
raise notice 'rend_accert_A_pdce_E_4_02_06 = %', rend_accert_A_pdce_E_4_02_06;
raise notice 'rend_accert_A_pdce_E_4_03_01 = %', rend_accert_A_pdce_E_4_03_01;
raise notice 'rend_accert_A_pdce_E_4_03_04 = %', rend_accert_A_pdce_E_4_03_04;  
raise notice 'TotaleRiscossioniTR = %', TotaleRiscossioniTR;
raise notice 'TotaleAccertatoA = %', TotaleAccertatoA;
raise notice 'TotaleResAttiviRS = %', TotaleResAttiviRS;
        
raise notice '';
raise notice '               IMPORTI SPESE';   
raise notice 'rend_impegni_I_macroagg101 = %', rend_impegni_I_macroagg101;    
raise notice 'rend_FPV_macroagg_101 = %', rend_FPV_macroagg_101;    
raise notice 'rend_impegni_I_macroagg107 = %', rend_impegni_I_macroagg107; 
raise notice 'rend_impegni_I_titolo_4 = %', rend_impegni_I_titolo_4;
raise notice 'rend_impegni_I_pdce_U_1_02_01_01 = %', rend_impegni_I_pdce_U_1_02_01_01;
raise notice 'rend_FPV_anno_prec_macroagg101 = %', rend_FPV_anno_prec_macroagg101;
raise notice 'rend_impegni_i_pdce_U_1_07_06_02 = %', rend_impegni_i_pdce_U_1_07_06_02;
raise notice 'rend_impegni_i_pdce_U_1_07_06_04 = %', rend_impegni_i_pdce_U_1_07_06_04;
raise notice 'rend_impegni_I_titoli_1_2 = %', rend_impegni_I_titoli_1_2;

return next;

exception
	when no_data_found THEN
		raise notice 'Nessun dato trovato';
		return;
	when others  THEN
		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
		return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;