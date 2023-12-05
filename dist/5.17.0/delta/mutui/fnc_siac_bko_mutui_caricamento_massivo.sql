/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--drop function if exists siac.fnc_siac_bko_mutui_caricamento_massivo (offset_mutuo_numero integer,p_ente_code varchar);
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_mutui_caricamento_massivo (
  offset_mutuo_numero integer,
  p_ente_code varchar
)
RETURNS VOID
AS
$body$
DECLARE

BEGIN
	
	if offset_mutuo_numero is null then
		raise notice 'offset_mutuo_numero is null';
		return;
	end if;
	if p_ente_code is null then
		raise notice 'p_ente_code is null';
		return;
	end if;
	
	raise notice 'insert into siac_t_mutuo';
	
	INSERT INTO siac.siac_t_mutuo
	(mutuo_numero, mutuo_oggetto, mutuo_stato_id, mutuo_tipo_tasso_id, mutuo_data_atto, mutuo_somma_iniziale, mutuo_somma_effettiva, mutuo_tasso, mutuo_tasso_euribor,mutuo_tasso_spread,mutuo_durata_anni, mutuo_anno_inizio, mutuo_anno_fine, mutuo_periodo_rimborso_id
	, mutuo_data_scadenza_prima_rata, mutuo_annualita, mutuo_preammortamento, mutuo_contotes_id, mutuo_attoamm_id, ente_proprietario_id, validita_inizio, data_creazione, data_modifica, login_operazione, login_creazione, login_modifica)
	select 
		offset_mutuo_numero+sbtm.bko_mutuo_numero,
		bko_mutuo_oggetto,
		sdms.mutuo_stato_id,
		sdmtt.mutuo_tipo_tasso_id,
		bko_mutuo_data_atto,
		bko_mutuo_somma_mutuata,
		bko_mutuo_somma_mutuata,
		bko_mutuo_tasso,
		bko_mutuo_tasso_euribor,
		bko_mutuo_tasso_spread,
		bko_mutuo_durata_anni,
		bko_mutuo_anno_inizio,
		bko_mutuo_anno_fine,
		sdmpr.mutuo_periodo_rimborso_id,
		to_date(bko_mutuo_scadenza_giorono||'/'||bko_mutuo_scadenza_mese||'/'||bko_mutuo_anno_inizio, 'dd/MM/yyyy'), -- data scadenza prima rata
		bko_t_mutuo_rata_group.importo_diviso_nrrate * (12/sdmpr.mutuo_periodo_numero_mesi), -- mutuo_annualita
		null, -- mutuo_preammortamento
		null, --mutuo_contotes_id
		null, --mutuo_attoamm_id
		step.ente_proprietario_id,
		now(),
		now(),
		now(), 
		'migrazione_mutui', 
		'migrazione_mutui', 
		'migrazione_mutui'
	from siac_bko_t_mutuo sbtm
	, siac_d_mutuo_stato sdms 
	, siac_d_mutuo_tipo_tasso sdmtt 
	, siac_d_mutuo_periodo_rimborso sdmpr 
	, siac_t_ente_proprietario step
	, (select
		sbtmr .bko_mutuo_numero,
		(sum(sbtmr .bko_mutuo_rata_importo_quota_capitale) + sum(sbtmr .bko_mutuo_rata_importo_quota_interessi) + sum(sbtmr .bko_mutuo_rata_importo_quota_oneri))
			/ count(*) as importo_diviso_nrrate  
		from siac_bko_t_mutuo_rata sbtmr
		group by sbtmr .bko_mutuo_numero) as  bko_t_mutuo_rata_group
	where sdms .mutuo_stato_code = 'D'
	and sdmtt.mutuo_tipo_tasso_code = sbtm.bko_mutuo_tipo_tasso
	and sdmpr.mutuo_periodo_numero_mesi = sbtm.bko_mutuo_periodo_rimborso
	and step.ente_code = p_ente_code
	and step.in_uso
	and not exists (
		select 1 from siac_t_mutuo, siac_t_ente_proprietario e
		where mutuo_numero = offset_mutuo_numero+sbtm.bko_mutuo_numero
		and e.ente_proprietario_id = step.ente_proprietario_id 
	)
	and bko_t_mutuo_rata_group.bko_mutuo_numero = sbtm.bko_mutuo_numero;

 	raise notice 'update siac_t_mutuo_num';
 	
	update siac_t_mutuo_num 
	set mutuo_numero = (select max(mutuo_numero) from siac_t_mutuo stm , siac_t_ente_proprietario step 
		where stm.ente_proprietario_id = step.ente_proprietario_id 
		and step.ente_code = p_ente_code
		and step.in_uso)
	, login_operazione = 'migrazione_mutui'
	, data_modifica = now()
	where ente_proprietario_id = (select ente_proprietario_id from siac_t_ente_proprietario step 
		where step.ente_code = p_ente_code
		and step.in_uso);
	
	raise notice 'bonifica soggetti siac_t_mutuo';
	
	update siac_t_mutuo stm
	set mutuo_soggetto_id = sts.soggetto_id
	from 
	siac_t_soggetto sts
	, (select distinct bko_mutuo_istituto_codice , bko_mutuo_istituto from siac_bko_t_mutuo sbtm ) as istituto_distinc
	, siac_bko_t_mutuo a
	where upper(sts.soggetto_desc ) like upper('%'||istituto_distinc.bko_mutuo_istituto||'%')
	and a.bko_mutuo_istituto_codice = istituto_distinc.bko_mutuo_istituto_codice
	and offset_mutuo_numero+a.bko_mutuo_numero = stm.mutuo_numero
	and stm.ente_proprietario_id=sts.ente_proprietario_id;	

	raise notice 'insert into siac.siac_t_mutuo_rata';
	
	INSERT INTO siac.siac_t_mutuo_rata
	(mutuo_id, mutuo_rata_anno, mutuo_rata_num_rata_piano, mutuo_rata_num_rata_anno, mutuo_rata_data_scadenza, mutuo_rata_importo, mutuo_rata_importo_quota_interessi, mutuo_rata_importo_quota_capitale, mutuo_rata_importo_quota_oneri
	, mutuo_rata_debito_residuo, mutuo_rata_debito_iniziale, ente_proprietario_id, validita_inizio, data_creazione, data_modifica, login_operazione, login_creazione, login_modifica)
	select 
		stm.mutuo_id,
		stbmr.bko_mutuo_rata_anno,
		(stbmr.bko_mutuo_rata_anno - stm.mutuo_anno_inizio ) * (12/sdmpr.mutuo_periodo_numero_mesi) + stbmr.bko_mutuo_rata_num_rata as numero_rata_piano,
		stbmr.bko_mutuo_rata_num_rata
		,stm.mutuo_data_scadenza_prima_rata + ((stbmr.bko_mutuo_rata_anno - stm.mutuo_anno_inizio - 1) *  (12/sdmpr.mutuo_periodo_numero_mesi) + stbmr.bko_mutuo_rata_num_rata + floor((12 - date_part('month', stm.mutuo_data_scadenza_prima_rata)) / sdmpr.mutuo_periodo_numero_mesi + 1) - 1) * CAST(sdmpr.mutuo_periodo_numero_mesi||' month' AS Interval) as  mutuo_rata_data_scadenza,
		bko_mutuo_rata_importo_quota_interessi+bko_mutuo_rata_importo_quota_capitale+bko_mutuo_rata_importo_quota_oneri as mutuo_rata_importo,
		bko_mutuo_rata_importo_quota_interessi,
		bko_mutuo_rata_importo_quota_capitale,
		bko_mutuo_rata_importo_quota_oneri,
		bko_mutuo_rata_debito_residuo,
		bko_mutuo_rata_debito_iniziale,
		step.ente_proprietario_id,
		now(),
		now(),
		now(), 
		'migrazione_mutui', 
		'migrazione_mutui', 
		'migrazione_mutui'
	from siac_bko_t_mutuo_rata stbmr
	, siac_t_mutuo stm
	, siac_t_ente_proprietario step
	, siac_d_mutuo_periodo_rimborso sdmpr 
	where stm.mutuo_numero = offset_mutuo_numero + stbmr .bko_mutuo_numero
	and step.ente_code = p_ente_code
	and step.in_uso
	and sdmpr.mutuo_periodo_rimborso_id = stm.mutuo_periodo_rimborso_id
	and not exists (
		select 1 from siac_t_mutuo_rata, siac_t_ente_proprietario e
		where siac_t_mutuo_rata.mutuo_id = stm.mutuo_id 
		and siac_t_mutuo_rata.mutuo_rata_num_rata_anno = bko_mutuo_rata_num_rata
		and siac_t_mutuo_rata.mutuo_rata_anno = bko_mutuo_rata_anno
		and e.ente_proprietario_id  = step.ente_proprietario_id
	);
	
exception
/*    when no_data_found THEN
        raise notice 'nessun valore trovato' ;
        return;*/
    when others  THEN
     RAISE EXCEPTION '% Errore : %-%.',' altro errore',SQLSTATE,SQLERRM;
	
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;