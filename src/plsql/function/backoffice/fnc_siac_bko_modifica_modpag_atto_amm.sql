
/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/



drop FUNCTION IF EXISTS  siac.fnc_siac_bko_modifica_modpag_atto_amm(id_ente integer, id_bilancio integer, anno_atto_amm integer, numero_atto_amm integer, codice_soggetto text, id_modpag integer, login_oper text);

drop FUNCTION IF EXISTS  siac.fnc_siac_bko_modifica_modpag_atto_amm(id_ente integer, id_bilancio integer, id_attoamm integer, codice_soggetto text, id_modpag integer, login_oper text);

-- 04.08.2021 Sofia JIRA SIAC-8216
--CREATE OR REPLACE 
--FUNCTION siac.fnc_siac_bko_modifica_modpag_atto_amm(id_ente integer, id_bilancio integer, anno_atto_amm integer, numero_atto_amm integer, codice_soggetto text, id_modpag integer, login_oper text)
CREATE OR REPLACE 
FUNCTION siac.fnc_siac_bko_modifica_modpag_atto_amm(id_ente integer, id_bilancio integer, id_attoamm integer, codice_soggetto text, id_modpag integer, login_oper text)

 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE

atto_amministrativo siac_t_atto_amm%ROWTYPE;
liquidazione siac_t_liquidazione%ROWTYPE;
ordinativo siac_t_ordinativo%ROWTYPE;
soggetto siac_t_soggetto%ROWTYPE;
id_soggetto_relazione siac_r_soggetto_relaz.soggetto_relaz_id%type;


begin
	
	-- return 'MANUTENZIONE IN CORSO';

	
	/* 04.08.2021 Sofia JIRA SIAC-8216
	  select * into atto_amministrativo from siac_t_atto_amm staa, siac_d_atto_amm_tipo sdaat 
		where staa.attoamm_anno = CAST(anno_atto_amm AS varchar)
		and staa.attoamm_numero = numero_atto_amm
		and staa.ente_proprietario_id = id_ente
		and sdaat.attoamm_tipo_code = 'ALG' 
		AND sdaat.ente_proprietario_id= staa.ente_proprietario_id
		AND sdaat.attoamm_tipo_id = staa.attoamm_tipo_id;*/
	
	-- 04.08.2021 Sofia JIRA SIAC-8216
	select * into atto_amministrativo from siac_t_atto_amm staa, siac_d_atto_amm_tipo sdaat 
		WHERE staa.attoamm_id=id_attoamm
		and staa.ente_proprietario_id = id_ente
		AND sdaat.ente_proprietario_id= staa.ente_proprietario_id
		AND sdaat.attoamm_tipo_id = staa.attoamm_tipo_id;
	
	--return atto_amministrativo.attoamm_oggetto::text;

	select sts.* into soggetto from siac_t_soggetto sts, siac_d_ambito sda
		where sts.soggetto_code = codice_soggetto
		and sts.ente_proprietario_id = id_ente
		and sda.ambito_id = sts.ambito_id 
		and sda.ambito_code = 'AMBITO_FIN'
		and sda.ente_proprietario_id = sts.ente_proprietario_id
		and not exists (
			select 1 from siac_r_soggetto_relaz srsr, siac_d_relaz_tipo sdrt 
			where srsr.soggetto_id_a=sts.soggetto_id 
			and srsr.relaz_tipo_id=sdrt.relaz_tipo_id 
			and sdrt.relaz_tipo_code = 'SEDE_SECONDARIA'
			and sdrt.ente_proprietario_id = sts.ente_proprietario_id
		)
	;

	
	-- controlli
	
	select stl.* into liquidazione from 
		 siac_t_liquidazione stl, 
		 siac_r_liquidazione_atto_amm srlaa , 
		 siac_r_liquidazione_soggetto srls,
		 siac_r_liquidazione_stato srlst,  
		 siac_d_liquidazione_stato sdls
    where atto_amministrativo.attoamm_id = srlaa.attoamm_id
		and srlaa.liq_id = stl.liq_id
		and srlaa.data_cancellazione is null
		and srlaa.validita_fine is null
		and stl.liq_id = srls.liq_id
		and srls.soggetto_id = soggetto.soggetto_id
		and stl.liq_id = srlst.liq_id
		and srlst.data_cancellazione is NULL
		AND srlst.validita_inizio < CURRENT_TIMESTAMP    
		AND (srlst.validita_fine IS NULL OR srlst.validita_fine > CURRENT_TIMESTAMP)  
		and srlst.liq_stato_id = sdls.liq_stato_id
		and sdls.liq_stato_code != 'A'
		and sdls.ente_proprietario_id= id_ente
		and stl.bil_id = id_bilancio;
	

	if liquidazione is NULL then
		return 'la liquidazione associata non e'' presente sull''anno di bilancio corrente';
	end if;

		
	select sto.* into ordinativo from 
			siac_r_liquidazione_ord srlo, siac_t_ordinativo_ts stot, siac_t_ordinativo sto, siac_r_ordinativo_stato sros, siac_d_ordinativo_stato sdos 
		where srlo.liq_id = liquidazione.liq_id
		and stot.ord_ts_id=srlo.sord_id 
		and sto.ord_id=stot.ord_id 
		and sros.ord_id=sto.ord_id 
		and sdos.ord_stato_id=sros.ord_stato_id
		and sdos.ord_stato_code != 'A'
		AND sto.data_cancellazione is null   
		AND sto.validita_inizio < CURRENT_TIMESTAMP    
		AND (sto.validita_fine IS NULL OR sto.validita_fine > CURRENT_TIMESTAMP)  
		AND stot.data_cancellazione is null   
		AND stot.validita_inizio < CURRENT_TIMESTAMP    
		AND (stot.validita_fine IS NULL OR stot.validita_fine > CURRENT_TIMESTAMP)  
		AND sros.data_cancellazione is null   
		AND sros.validita_inizio < CURRENT_TIMESTAMP    
		AND (sros.validita_fine IS NULL OR sros.validita_fine > CURRENT_TIMESTAMP) 
		limit 1;

	if ordinativo.ord_id is not null then
		return 'la liquidazione ' || liquidazione.liq_anno || '/' || liquidazione.liq_numero || ' e'' associata all''ordinativo ' || ordinativo.ord_anno || '/' || ordinativo.ord_numero;
	end if;
	
	
	-- aggiornamenti
	
		update siac_r_subdoc_modpag srsm
		set    data_cancellazione=CURRENT_TIMESTAMP,
			   validita_fine=CURRENT_TIMESTAMP,
			   login_Operazione=login_oper
 		from siac_r_subdoc_atto_amm srsaa, siac_t_subdoc sts, 
 			siac_r_doc_sog srds 
 		where srsaa.attoamm_id = atto_amministrativo.attoamm_id 
		and srsaa.subdoc_id = sts.subdoc_id 
		and srds.doc_id = sts.doc_id 
		and soggetto.soggetto_id = srds.soggetto_id 
		and srsm.subdoc_id = sts.subdoc_id 
 		and srsaa.data_cancellazione is NULL
		AND srsaa.validita_inizio < CURRENT_TIMESTAMP    
		AND (srsaa.validita_fine IS NULL OR srsaa.validita_fine > CURRENT_TIMESTAMP)  
 		and srsm.data_cancellazione is NULL
		AND srsm.validita_inizio < CURRENT_TIMESTAMP    
		AND (srsm.validita_fine IS NULL OR srsm.validita_fine > CURRENT_TIMESTAMP)  
;



	insert into siac_r_subdoc_modpag
	(
		subdoc_id,
		modpag_id,
		validita_inizio,
		login_Operazione,
		ente_proprietario_id
	)
	select sts.subdoc_id,
		   id_modpag,
		   CURRENT_TIMESTAMP,
		   login_oper,
		   id_ente
	from siac_r_subdoc_atto_amm srsaa, 
		siac_t_subdoc sts,
		siac_t_doc std, 
		siac_r_doc_sog srds
	where atto_amministrativo.attoamm_id = srsaa.attoamm_id
		and srsaa.subdoc_id = sts.subdoc_id
		and sts.ente_proprietario_id = id_ente
		and sts.doc_id = std.doc_id
		and std.doc_id = srds.doc_id
		and std.ente_proprietario_id = id_ente
		and srds.soggetto_id = soggetto.soggetto_id
		and srsaa.data_cancellazione is NULL
		AND srsaa.validita_inizio < CURRENT_TIMESTAMP    
		AND (srsaa.validita_fine IS NULL OR srsaa.validita_fine > CURRENT_TIMESTAMP)  
		and srds.data_cancellazione is NULL
		AND srds.validita_inizio < CURRENT_TIMESTAMP    
		AND (srds.validita_fine IS NULL OR srds.validita_fine > CURRENT_TIMESTAMP)  
	;
	

	select srsr.soggetto_relaz_id into id_soggetto_relazione from siac_r_soggrel_modpag srsm, siac_r_soggetto_relaz srsr 
		where srsm.modpag_id = id_modpag
		and srsr.soggetto_relaz_id = srsm.soggetto_relaz_id 
		and srsr.soggetto_id_da = soggetto.soggetto_id;
	

	update siac_t_liquidazione stl
	   set modpag_id = case when id_soggetto_relazione is NULL then id_modpag else NULL end,
	   	   soggetto_relaz_id = case when id_soggetto_relazione is NULL then NULL else id_soggetto_relazione end, 
		   data_modifica = CURRENT_TIMESTAMP,
		   login_operazione = login_oper 
	from siac_r_liquidazione_atto_amm srlaa , 
		 siac_r_liquidazione_soggetto srls,
		 siac_r_liquidazione_stato srlst,  
		 siac_d_liquidazione_stato sdls
    where atto_amministrativo.attoamm_id = srlaa.attoamm_id
		and srlaa.liq_id = stl.liq_id
		and srlaa.data_cancellazione is null
		and srlaa.validita_fine is null
		and stl.liq_id = srls.liq_id
		and srls.soggetto_id = soggetto.soggetto_id
		and stl.bil_id = id_bilancio
		and stl.liq_id = srlst.liq_id
		and srlst.liq_stato_id = sdls.liq_stato_id
		and srlst.data_cancellazione is NULL
		AND srlst.validita_inizio < CURRENT_TIMESTAMP    
		AND (srlst.validita_fine IS NULL OR srlst.validita_fine > CURRENT_TIMESTAMP)  
		and sdls.liq_stato_code != 'A'
		and sdls.ente_proprietario_id=id_ente
	;

	--

	
    return null;

exception
        when others  THEN
            return SQLERRM;
END;
$function$
;

alter function
siac.fnc_siac_bko_modifica_modpag_atto_amm
(
 integer, integer, integer, text, integer, text) OWNER to siac;