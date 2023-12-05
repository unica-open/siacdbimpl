/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR094_elenco_impegni_spesa" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  nome_ente varchar,
  bil_anno varchar,
  anno_capitolo integer,
  num_capitolo varchar,
  cod_articolo varchar,
  ueb varchar,
  descr_capitolo varchar,
  descr_articolo varchar,
  anno_provv varchar,
  num_provv integer,
  cod_tipo_provv varchar,
  desc_tipo_provv varchar,
  descr_strutt_amm varchar,
  cod_soggetto varchar,
  classe_soggetto varchar,
  descr_soggetto varchar,
  anno_impegno integer,
  num_impegno varchar,
  tipo_impegno varchar,
  stato_impegno varchar,
  descr_impegno varchar,
  importo_impegno numeric,
  scadenza_impegno date,
  progetto_impegno varchar,
  cig varchar,
  cup varchar,
  da_riaccertamento varchar,
  anno_riaccert integer,
  num_riaccert varchar,
  anno_impegno_origine integer,
  num_impegno_origine varchar,
  impegno_plurien varchar,
  anno_accert_vincolo integer,
  num_accert_vincolo varchar,
  importo_accert_vincolo numeric,
  movgest_id integer,
  movgest_ts_id integer,
  esistono_vincoli varchar,
  parere_finanziario varchar
) AS
$body$
DECLARE

 --g
 bil_id_in integer;
 
BEGIN

select a.bil_id,c.ente_denominazione,b.anno into bil_id_in,nome_ente , bil_anno 
from siac_T_bil a,siac_t_periodo b,siac_t_ente_proprietario c
where b.periodo_id=a.periodo_id
and c.ente_proprietario_id=A.ente_proprietario_id
and b.anno=p_anno
and a.ente_proprietario_id=p_ente_prop_id;

return query 
with movgest as (
select 
a.movgest_id,
c.movgest_ts_id,
a.movgest_anno anno_impegno,
a.movgest_numero num_impegno,
--b.movgest_tipo_code tipo_impegno,
f.movgest_stato_code||' - '||f.movgest_stato_desc stato_impegno,
a.movgest_desc descr_impegno,
c.movgest_ts_scadenza_data scadenza_impegno,
a.parere_finanziario,
--sum(g.movgest_ts_det_importo) importo_impegno
g.movgest_ts_det_importo importo_impegno
 from siac_t_movgest a,siac_d_movgest_tipo b,siac_t_movgest_ts c,siac_d_movgest_ts_tipo d,
siac_r_movgest_ts_stato e,siac_d_movgest_stato f,
siac_t_movgest_ts_det g,siac_d_movgest_ts_det_tipo h
 where a.bil_id=bil_id_in
and b.movgest_tipo_id=a.movgest_tipo_id
and b.movgest_tipo_code='I'
and d.movgest_ts_tipo_code='T'
and c.movgest_id=a.movgest_id
and d.movgest_ts_tipo_id=c.movgest_ts_tipo_id
and e.movgest_ts_id=c.movgest_ts_id
and f.movgest_stato_id=e.movgest_stato_id
--and f.movgest_stato_code<>'A'
and now() BETWEEN f.validita_inizio and COALESCE(f.validita_fine,now())
and g.movgest_ts_id=c.movgest_ts_id
and g.movgest_ts_det_tipo_id=h.movgest_ts_det_tipo_id
and h.movgest_ts_det_tipo_code='A'
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
),
cap as (
select 
a.movgest_id,
p_anno::integer anno_capitolo ,
b.elem_code  num_capitolo ,
b.elem_code2  cod_articolo ,
b.elem_code3  ueb ,
b.elem_desc  descr_capitolo ,
b.elem_desc2  descr_articolo  
from siac_r_movgest_bil_elem a, siac_t_bil_elem b
where b.elem_id=a.elem_id and a.data_cancellazione is NULL and b.data_cancellazione is null
and a.ente_proprietario_id=p_ente_prop_id
),
attoamm as (/*select a.movgest_ts_id,
b.attoamm_id,b.attoamm_anno anno_provv,b.attoamm_numero num_provv, 
e.attoamm_tipo_code cod_tipo_provv,e.attoamm_tipo_desc desc_tipo_provv
 from siac_r_movgest_ts_atto_amm a,siac_t_atto_amm b, siac_r_atto_amm_stato c,
siac_d_atto_amm_stato d,siac_d_atto_amm_tipo e where a.ente_proprietario_id=p_ente_prop_id
and b.attoamm_id=A.attoamm_id
and c.attoamm_id=b.attoamm_id
and d.attoamm_stato_id=c.attoamm_stato_id
and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now())
and d.attoamm_stato_code<>'ANNULLATO'
and e.attoamm_tipo_id=b.attoamm_tipo_id
and a.data_cancellazione is NULL 
and b.data_cancellazione is null
and c.data_cancellazione is NULL 
and d.data_cancellazione is null
and e.data_cancellazione is NULL */
with attoammsac as (select a.movgest_ts_id,
b.attoamm_id,b.attoamm_anno anno_provv,b.attoamm_numero num_provv, 
e.attoamm_tipo_code cod_tipo_provv,e.attoamm_tipo_desc desc_tipo_provv
 from siac_r_movgest_ts_atto_amm a,siac_t_atto_amm b, siac_r_atto_amm_stato c,
siac_d_atto_amm_stato d,siac_d_atto_amm_tipo e where a.ente_proprietario_id=p_ente_prop_id
and b.attoamm_id=A.attoamm_id
and c.attoamm_id=b.attoamm_id
and d.attoamm_stato_id=c.attoamm_stato_id
and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now())
and d.attoamm_stato_code<>'ANNULLATO'
and e.attoamm_tipo_id=b.attoamm_tipo_id
and a.data_cancellazione is NULL 
and b.data_cancellazione is null
and c.data_cancellazione is NULL 
and d.data_cancellazione is null
and e.data_cancellazione is NULL 
),
cdc as (select a.attoamm_id,
b2.classif_code||' - '||b2.classif_desc||' - '||b.classif_code||' - '||b.classif_desc descr_strutt_amm
 from siac_r_atto_amm_class a,siac_t_class b,siac_d_class_tipo c, siac_r_class_fam_tree d,
 siac_t_class b2
where a.ente_proprietario_id=p_ente_prop_id and b.classif_id=a.classif_id
and c.classif_tipo_id=b.classif_tipo_id
and c.classif_tipo_code in ('CDC')
and d.classif_id=b.classif_id
and d.classif_id_padre=b2.classif_id
and a.data_cancellazione is NULL 
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and b2.data_cancellazione is NULL 
)
,
cdr as (select a.attoamm_id,
b.classif_code||' - '||b.classif_desc descr_strutt_amm
 from siac_r_atto_amm_class a,siac_t_class b,siac_d_class_tipo c
where a.ente_proprietario_id=p_ente_prop_id and b.classif_id=a.classif_id
and c.classif_tipo_id=b.classif_tipo_id
and c.classif_tipo_code in ('CDR')
and a.data_cancellazione is NULL 
and b.data_cancellazione is null
and c.data_cancellazione is null
)
select attoammsac.*,
case when cdc.descr_strutt_amm is null then
coalesce(cdr.descr_strutt_amm::varchar,''::varchar) else coalesce(cdc.descr_strutt_amm::varchar,''::VARCHAR) end descr_strutt_amm
 from attoammsac left join
cdc on attoammsac.attoamm_id=cdc.attoamm_id
left join cdr on attoammsac.attoamm_id=cdr.attoamm_id
)/*,
cdc as (select a.movgest_ts_id,
b2.classif_code||' - '||b2.classif_desc||' - '||b.classif_code||' - '||b.classif_desc descr_strutt_amm
 from siac_r_movgest_class a,siac_t_class b,siac_d_class_tipo c, siac_r_class_fam_tree d,
 siac_t_class b2
where a.ente_proprietario_id=p_ente_prop_id and b.classif_id=a.classif_id
and c.classif_tipo_id=b.classif_tipo_id
and c.classif_tipo_code in ('CDC')
and d.classif_id=b.classif_id
and d.classif_id_padre=b2.classif_id
and a.data_cancellazione is NULL 
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and b2.data_cancellazione is NULL 
)
,
cdr as (select a.movgest_ts_id,
b.classif_code||' - '||b.classif_desc descr_strutt_amm
 from siac_r_movgest_class a,siac_t_class b,siac_d_class_tipo c
where a.ente_proprietario_id=p_ente_prop_id and b.classif_id=a.classif_id
and c.classif_tipo_id=b.classif_tipo_id
and c.classif_tipo_code in ('CDR')
and a.data_cancellazione is NULL 
and b.data_cancellazione is null
and c.data_cancellazione is null
)*/,
sog as (select a.movgest_ts_id,b.soggetto_code cod_soggetto,b.soggetto_desc descr_soggetto from siac_r_movgest_ts_sog a,siac_t_soggetto b
where a.ente_proprietario_id=p_ente_prop_id and b.soggetto_id=a.soggetto_id
and a.data_cancellazione is null 
and b.data_cancellazione is null),
sogcla as (select a.movgest_ts_id,b.soggetto_classe_code||' - '||b.soggetto_classe_desc classe_soggetto
from siac_r_movgest_ts_sogclasse a,siac_d_soggetto_classe b
where a.ente_proprietario_id=p_ente_prop_id and b.soggetto_classe_id=a.soggetto_classe_id
and a.data_cancellazione is null 
and b.data_cancellazione is null),
progr as (select a.movgest_ts_id,b.programma_code|| ' - '||b.programma_desc progetto_impegno
from siac_r_movgest_ts_programma a, siac_t_programma b
where 
a.ente_proprietario_id=p_ente_prop_id and 
b.programma_id=a.programma_id
--20/04/2020 SIAC-7594
-- aggiunto il controllo sull'anno del bilancio per i progetti.
and (b.bil_id = bil_id_in OR b.bil_id IS NULL)
and a.data_cancellazione is null 
and b.data_cancellazione is null),
cig as (SELECT a.movgest_ts_id--, a.boolean
, a.testo cig
from siac_r_movgest_ts_attr a,siac_t_attr b
where 
a.ente_proprietario_id=p_ente_prop_id 
--and a.attr_id=2820 --attr_id_cig
and b.attr_id=a.attr_id and 
 b.attr_code='cig'
and a.data_cancellazione IS NULL
and a.testo is not null and a.testo<>''
),
cup as (SELECT a.movgest_ts_id--, a.boolean
, a.testo cup
from siac_r_movgest_ts_attr a,
siac_t_attr b
where 
a.ente_proprietario_id=p_ente_prop_id 
--and a.attr_id=2794 --attr_id_cup
and b.attr_id=a.attr_id and 
 b.attr_code='cup'
and a.data_cancellazione IS NULL
and a.testo is not null and a.testo<>''
)
,
numeroRiaccertato as (SELECT a.movgest_ts_id--, a.boolean
, a.testo num_riaccert
from siac_r_movgest_ts_attr a,
siac_t_attr b
where 
a.ente_proprietario_id=p_ente_prop_id 
and a.attr_id=b.attr_id
and b.attr_code='numeroRiaccertato'
and a.testo is not null and a.testo<>''
and a.data_cancellazione IS NULL
--and b.data_cancellazione IS NULL  
)
,
annoRiaccertato as (SELECT a.movgest_ts_id--, a.boolean
, a.testo::integer anno_riaccert
from siac_r_movgest_ts_attr a,
siac_t_attr b
where 
a.ente_proprietario_id=p_ente_prop_id 
and a.attr_id=b.attr_id
and b.attr_code='annoRiaccertato'
and a.data_cancellazione IS NULL
and a.testo is not null and a.testo<>''
--and b.data_cancellazione IS NULL  
),
flagDaRiaccertamento as (SELECT a.movgest_ts_id--, a.boolean
, a."boolean" da_riaccertamento
from siac_r_movgest_ts_attr a,
siac_t_attr b
where 
a.ente_proprietario_id=p_ente_prop_id 
and a.attr_id=b.attr_id
and b.attr_code='flagDaRiaccertamento'
and a.data_cancellazione IS NULL
and a."boolean" is not null and a."boolean"<>''
--and b.data_cancellazione IS NULL  
),
--20/04/2020 SIAC-7594
-- aggiunto il distinct per evitare la duplicazione dei dati se nella
-- tabella siac_r_movgest_ts l'impegno e' presente piu' volte.
vincoli as (select distinct
movgest_ts_b_id movgest_ts_id
            from siac_r_movgest_ts a where a.ente_proprietario_id = p_ente_prop_id            		
and a.data_cancellazione is null),
tipoimp as
(select a.movgest_ts_id,b.classif_desc tipo_impegno from siac_r_movgest_class a,
siac_t_class b,siac_d_class_tipo c
 where a.ente_proprietario_id = p_ente_prop_id   
 and b.classif_id=a.classif_id
 and c.classif_tipo_id=b.classif_tipo_id  
 and c.classif_tipo_code ='TIPO_IMPEGNO'       		
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
          )
select 
nome_ente::varchar nome_ente,
bil_anno::varchar bil_anno,
coalesce(cap.anno_capitolo::integer,0::integer) anno_capitolo
,coalesce(cap.num_capitolo::varchar,''::VARCHAR) num_capitolo,
coalesce(cap.cod_articolo::varchar,''::VARCHAR) cod_articolo,
coalesce(cap.ueb::varchar,''::VARCHAR) ueb,
coalesce(cap.descr_capitolo::varchar,''::VARCHAR) descr_capitolo,
coalesce(cap.descr_articolo::varchar,''::VARCHAR) descr_articolo,
coalesce(attoamm.anno_provv::varchar,''::VARCHAR) anno_provv,
coalesce(attoamm.num_provv::integer,0::INTEGER) num_provv,
coalesce(attoamm.cod_tipo_provv::varchar,''::VARCHAR) cod_tipo_provv,
coalesce(attoamm.desc_tipo_provv::varchar,''::VARCHAR) desc_tipo_provv,
/*case when cdc.descr_strutt_amm is null then
coalesce(cdr.descr_strutt_amm::varchar,''::varchar) else coalesce(cdc.descr_strutt_amm::varchar,''::VARCHAR) end descr_strutt_amm,
*/
attoamm.descr_strutt_amm::varchar descr_strutt_amm,
coalesce(sog.cod_soggetto::varchar,''::VARCHAR) cod_soggetto,
coalesce(sogcla.classe_soggetto::varchar,''::VARCHAR)  classe_soggetto,
coalesce(sog.descr_soggetto::varchar,''::VARCHAR) descr_soggetto ,
movgest.anno_impegno::integer anno_impegno,
movgest.num_impegno::varchar num_impegno,
tipoimp.tipo_impegno::varchar tipo_impegno,
movgest.stato_impegno::varchar stato_impegno,
movgest.descr_impegno::varchar descr_impegno,
movgest.importo_impegno::numeric importo_impegno,
movgest.scadenza_impegno::date scadenza_impegno,
coalesce(progr.progetto_impegno::varchar,''::VARCHAR) progetto_impegno,
coalesce(cig.cig::varchar,''::varchar) cig,
coalesce(cup.cup::varchar,''::varchar) cup,
coalesce(flagDaRiaccertamento.da_riaccertamento::varchar,''::varchar) da_riaccertamento,
coalesce(annoRiaccertato.anno_riaccert::integer,0::integer) anno_riaccert,
coalesce(numeroRiaccertato.num_riaccert::varchar,''::varchar) num_riaccert,
0::integer anno_impegno_origine ,
''::varchar  num_impegno_origine,
  ''::varchar impegno_plurien,
0::integer anno_accert_vincolo ,
 ''::varchar num_accert_vincolo ,
0::numeric   importo_accert_vincolo ,
  movgest.movgest_id::integer v,
  movgest.movgest_ts_id::integer movgest_ts_id,
 case when vincoli.movgest_ts_id is not null then 'S'::varchar else 'N'::varchar end  esistono_vincoli,
  case when 
  movgest.parere_finanziario is true then 'S'::varchar else 'N'::varchar end parere_finanziario
from movgest 
--left 
join 
cap
on movgest.movgest_id=cap.movgest_id
left join attoamm
on movgest.movgest_ts_id=attoamm.movgest_ts_id
/*left join cdc
on movgest.movgest_ts_id=cdc.movgest_ts_id
left join cdr
on movgest.movgest_ts_id=cdr.movgest_ts_id*/
left join sog
on movgest.movgest_ts_id=sog.movgest_ts_id
left join sogcla
on movgest.movgest_ts_id=sogcla.movgest_ts_id
left join progr
on movgest.movgest_ts_id=progr.movgest_ts_id
left join cig
on movgest.movgest_ts_id=cig.movgest_ts_id
left join cup
on movgest.movgest_ts_id=cup.movgest_ts_id
left join numeroRiaccertato
on movgest.movgest_ts_id=numeroRiaccertato.movgest_ts_id
left join annoRiaccertato
on movgest.movgest_ts_id=annoRiaccertato.movgest_ts_id
left join flagDaRiaccertamento
on movgest.movgest_ts_id=flagDaRiaccertamento.movgest_ts_id
left join vincoli
on movgest.movgest_ts_id=vincoli.movgest_ts_id
left join tipoimp
on movgest.movgest_ts_id=tipoimp.movgest_ts_id
;



exception
	when no_data_found THEN
		raise notice 'Dati degli impegni non trovati.' ;
		--return next;
	when others  THEN
		--raise notice 'errore nella lettura delle prime note ';
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'IMPEGNI',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
RETURNS NULL ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;