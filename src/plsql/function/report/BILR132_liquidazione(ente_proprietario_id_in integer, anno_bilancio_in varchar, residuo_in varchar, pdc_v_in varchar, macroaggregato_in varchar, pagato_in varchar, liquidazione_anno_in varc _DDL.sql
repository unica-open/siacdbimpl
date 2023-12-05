/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR132_liquidazione" (
  ente_proprietario_id_in integer,
  anno_bilancio_in varchar,
  residuo_in varchar,
  pdc_v_in varchar,
  macroaggregato_in varchar,
  pagato_in varchar,
  liquidazione_anno_in varchar,
  liquidazione_numero_in varchar
)
RETURNS TABLE (
  ente_proprietario_id integer,
  anno_bilancio varchar,
  v_livello_pdc_fin varchar,
  v_livello_pdc_fin_desc varchar,
  tipo_riga varchar,
  anno_impegno varchar,
  numero_impegno varchar,
  movgest_id integer,
  residuo varchar,
  anno_liquidazione varchar,
  numero_liquidazione varchar,
  descrizione_liquidazione varchar,
  liq_id integer,
  anno_allegato_atto varchar,
  numero_allegato_atto varchar,
  beneficiario varchar,
  importo_liquidazione numeric,
  numero_prima_nota varchar,
  data_registrazione_prima_nota timestamp,
  tipo_conto varchar,
  codice_conto varchar,
  descrizione_conto varchar,
  importo_conto numeric,
  pagato varchar,
  delta_dare numeric,
  delta_avere numeric,
  display_error varchar
) AS
$body$
DECLARE

cur_liq record;
DEF_NULL    constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
sql_query text;
v_movgest_ts_id integer;

BEGIN

display_error := '';

IF pdc_v_in = '' THEN
   pdc_v_in := null;
END IF;

IF  macroaggregato_in = '' OR  macroaggregato_in = 'T' THEN
   macroaggregato_in := null;
END IF;

IF pdc_v_in is not null AND macroaggregato_in is not null  THEN
   display_error := 'Per visualizzare i dati inserire solo il V livello del pdc oppure il titolo/macroaggregato!';
   return next;
   return;
END IF;

IF pagato_in = '' OR pagato_in ='T' THEN
   pagato_in := null;
END IF;

IF liquidazione_numero_in = ''  THEN
   liquidazione_numero_in := null;
END IF;

IF liquidazione_anno_in = ''  THEN
   liquidazione_anno_in := null;
END IF;

--v_user:=fnc_siac_random_user();
sql_query:='
select tb.* from(
with liq as (
select a.ente_proprietario_id,
h.classif_code,h.classif_desc,
d.movgest_id,
d.movgest_anno,d.movgest_numero ,
a.liq_id,a.liq_anno,a.liq_numero,a.liq_desc,a.liq_importo,
f.anno anno_bilancio, 
case when d.movgest_anno::integer < f.anno::integer then ''S'' else ''N'' end residuo,
case when l.movgest_ts_tipo_code=''T'' then null else c.movgest_ts_code end movgest_ts_code
from siac_t_liquidazione a,
siac_r_liquidazione_movgest b ,siac_t_movgest_ts c,
siac_t_movgest d, siac_t_bil e, siac_t_periodo f,
siac_r_movgest_class g,siac_t_class h, siac_d_class_tipo i,
siac_d_movgest_ts_tipo l
where a.liq_id=b.liq_id
and f.anno='''||anno_bilancio_in||'''
and c.movgest_ts_id=b.movgest_ts_id
and d.movgest_id=c.movgest_id
and e.bil_id=d.bil_id
and f.periodo_id=e.periodo_id
and g.movgest_ts_id=c.movgest_ts_id
and h.classif_id=g.classif_id
and i.classif_tipo_id=h.classif_tipo_id
and l.movgest_ts_tipo_id=c.movgest_ts_tipo_id 
and i.classif_tipo_code like ''PDC%''
and a.ente_proprietario_id='||ente_proprietario_id_in||'
and now() BETWEEN b.validita_inizio and coalesce (b.validita_fine, now())
and now() BETWEEN g.validita_inizio and coalesce (g.validita_fine, now())
and a.data_cancellazione is null 
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
and l.data_cancellazione is null
)
, attoallegato as (select a.liq_id,
b.attoamm_anno,
 b.attoamm_numero from siac_r_liquidazione_atto_amm a, siac_t_atto_amm b ,siac_t_atto_allegato c
where a.attoamm_id=b.attoamm_id
and c.attoamm_id=b.attoamm_id
and now() BETWEEN a.validita_inizio and coalesce (a.validita_fine, now())
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a.ente_proprietario_id='||ente_proprietario_id_in||'
)
, beneficiario as (select a.liq_id,b.soggetto_id,b.soggetto_code,b.soggetto_desc from 
siac_r_liquidazione_soggetto a, siac_t_soggetto b
where a.soggetto_id=b.soggetto_id
and now() BETWEEN a.validita_inizio and coalesce (a.validita_fine, now())
and a.ente_proprietario_id='||ente_proprietario_id_in||'
and a.data_cancellazione is null
and b.data_cancellazione is null
)
,pnota as (select  
--''PRIMANOTA'' tiporiga,
a.campo_pk_id,
d.pnota_progressivogiornale pnota_numero, d.pnota_dataregistrazionegiornale pnota_data,
--d.pnota_numero,d.pnota_data,
e.movep_det_segno, i.pdce_conto_code, i.pdce_conto_desc,
 e.movep_det_importo
 from siac_r_evento_reg_movfin a, siac_t_reg_movfin b, siac_t_mov_ep c, siac_t_prima_nota d,
siac_t_mov_ep_det e,siac_d_evento f,siac_d_evento_tipo g, siac_d_collegamento_tipo h, 
siac_t_pdce_conto i,siac_r_prima_nota_stato l,siac_d_prima_nota_stato m
where 
a.regmovfin_id=b.regmovfin_id
and b.regmovfin_id=c.regmovfin_id
and c.regep_id=d.pnota_id 
and e.movep_id=c.movep_id
and f.evento_id=a.evento_id
and g.evento_tipo_id=f.evento_tipo_id
and h.collegamento_tipo_id=f.collegamento_tipo_id
and h.collegamento_tipo_code in (''L'')
and i.pdce_conto_id=e.pdce_conto_id
and l.pnota_id=d.pnota_id
and m.pnota_stato_id=l.pnota_stato_id
and m.pnota_stato_code<>''A''
and now() between a.validita_inizio and COALESCE (a.validita_fine, now())
and now() between l.validita_inizio and COALESCE (l.validita_fine, now())
and a.ente_proprietario_id='||ente_proprietario_id_in||'
--condizione per primenonte definitive
and d.pnota_progressivogiornale is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null)
--condizione pagato se  ordinativo presente
, pagato as (select distinct a.liq_id from siac_r_liquidazione_ord a where a.ente_proprietario_id='||ente_proprietario_id_in||'
and now() between a.validita_inizio and COALESCE (a.validita_fine, now()) 
)
select ''LIQUIDAZIONE'' tiporiga,
liq.*,pnota.*,
beneficiario.soggetto_desc, attoallegato.attoamm_anno,attoallegato.attoamm_numero,
case when pagato.liq_id is null then ''N'' else ''S'' end pagato
from liq 
join pnota
on liq.liq_id=pnota.campo_pk_id
left join beneficiario 
on liq.liq_id=beneficiario.liq_id
left join attoallegato
on liq.liq_id=attoallegato.liq_id 
left join pagato
on liq.liq_id=pagato.liq_id 
)  tb';




/*if (anno_impegno_in is not null and pdc_v_in is null and macroaggregato_in is null) then

sql_query:='select * from ('||sql_query||') tab where tab.movgest_anno='''||anno_impegno_in||'''';

elsif (anno_impegno_in is null and pdc_v_in is not null and macroaggregato_in is null) then*/

if (pdc_v_in is not null and macroaggregato_in is null) then

sql_query:='select * from ('||sql_query||') tab where tab.classif_code='''||pdc_v_in||'''';

/*elsif (anno_impegno_in is not null and pdc_v_in is not null and macroaggregato_in is null) then

sql_query:='select * from ('||sql_query||') tab where tab.movgest_anno='''||anno_impegno_in||''' and tb.classif_code='''||pdc_v_in||'''';
*/
end if;

if pagato_in is not null THEN
sql_query:='select * from ('||sql_query||') tab where tab.pagato='''||pagato_in||'''';
end if;


if liquidazione_anno_in is not null THEN
sql_query:='select * from ('||sql_query||') tab where tab.liq_anno='''||liquidazione_anno_in||'''';
end if;



if liquidazione_numero_in is not null THEN
sql_query:='select * from ('||sql_query||') tab where tab.liq_numero='''||liquidazione_numero_in||'''';
end if;

if residuo_in is not null THEN
sql_query:='select * from ('||sql_query||') tab where tab.residuo='''||residuo_in||'''';
end if;

if (macroaggregato_in is not null and pdc_v_in is null)  THEN
sql_query:='select * from ('||sql_query||') tab where SUBSTRING(replace(tab.classif_code,''.'','''') from 2 for 3)||''0000''='''||macroaggregato_in||'''';

/*sql_query_add=', siac_t_class cc,siac_d_class_tipo dd where 
cc.ente_proprietario_id=tab.ente_proprietario_id
and dd.classif_tipo_id=cc.classif_tipo_id
and dd.classif_tipo_code=''MACROAGGREGATO''
and SUBSTRING(replace(tab.classif_code,'.','') from 2 for 3)=substring(cc.classif_code from 1 for 3)
and cc.classif_code='''||macroaggregato_in||'''';

sql_query:='select * from ('||sql_query||') tab'||sql_query_add;*/

end if;

raise notice '%', sql_query;

for cur_liq in
EXECUTE sql_query
loop

raise notice 'IMP = % - SUB =%', cur_liq.movgest_numero,cur_liq.movgest_ts_code;
tipo_riga:=cur_liq.tiporiga;
ente_proprietario_id:=cur_liq.ente_proprietario_id;
v_livello_pdc_fin:=cur_liq.classif_code;
v_livello_pdc_fin_desc:=cur_liq.classif_desc;
anno_bilancio:=cur_liq.anno_bilancio;
anno_impegno:=cur_liq.movgest_anno;
numero_impegno:=cur_liq.movgest_numero;

if cur_liq.movgest_ts_code IS NOT NULL THEN
	numero_impegno=numero_impegno||' - '||cur_liq.movgest_ts_code;
end if;

raise notice 'IMPEGNO =%', numero_impegno;
movgest_id:=cur_liq.movgest_id;
residuo:=cur_liq.residuo;
anno_liquidazione:=cur_liq.liq_anno;
numero_liquidazione:=cur_liq.liq_numero;
descrizione_liquidazione:=cur_liq.liq_desc;
liq_id:=cur_liq.liq_id;
importo_liquidazione:=cur_liq.liq_importo;
anno_allegato_atto:=cur_liq.attoamm_anno;
numero_allegato_atto:=cur_liq.attoamm_numero;
beneficiario:=cur_liq.soggetto_desc;
numero_prima_nota:=cur_liq.pnota_numero;
data_registrazione_prima_nota:=cur_liq.pnota_data;
tipo_conto:=cur_liq.movep_det_segno;
codice_conto:=cur_liq.pdce_conto_code;
descrizione_conto:=cur_liq.pdce_conto_desc;
importo_conto:=cur_liq.movep_det_importo;
pagato:=cur_liq.pagato;

/* calcolo gli importi DELTA come:
 - DELTA DARE = Importo Liquidazione meno Importo Dare
 - DELTA AVERE = Importo Liquidazione meno Importo Avere.
 E' GIUSTO ????? */
 
if upper(TRIM(tipo_conto)) = 'DARE' THEN
  delta_dare:= COALESCE(importo_liquidazione, 0)- COALESCE(importo_conto, 0);
  delta_avere:=0;
ELSE
  delta_dare:= 0;
  delta_avere:= COALESCE(importo_liquidazione, 0)- COALESCE(importo_conto, 0) ;
END IF ;


return next;

end loop;

exception
    when no_data_found THEN
        raise notice 'nessun valore trovato' ;
        return;
        when others  THEN
        --RTN_MESSAGGIO:='capitolo altro errore';
         RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,SQLERRM;
return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;