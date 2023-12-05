/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR134_ordinativo" (
  ente_proprietario_id_in integer,
  anno_bilancio_in varchar,
  residuo_in varchar,
  pdc_v_in varchar,
  macroaggregato_in varchar,
  anno_ordinativo_in varchar,
  numero_ordinativo_in varchar
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
  anno_ordinativo varchar,
  numero_ordinativo varchar,
  descrizione_ordinativo varchar,
  ord_id integer,
  beneficiario varchar,
  importo_ordinativo numeric,
  numero_prima_nota varchar,
  data_registrazione_prima_nota timestamp,
  tipo_conto varchar,
  codice_conto varchar,
  descrizione_conto varchar,
  importo_conto numeric,
  delta_dare numeric,
  delta_avere numeric,
  display_error varchar
) AS
$body$
DECLARE

cur_ord record;
tipo_riga_pnota VARCHAR;
tipo_riga_impegno VARCHAR;
DEF_NULL    constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
sql_query text;

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

IF numero_ordinativo_in = ''  THEN
   numero_ordinativo_in := null;
END IF;

IF anno_ordinativo_in = ''  THEN
   anno_ordinativo_in := null;
END IF;

--v_user:=fnc_siac_random_user();
sql_query:='
select tb.* from(with ord
as (
select  
a.ente_proprietario_id,
n.classif_code,n.classif_desc,
l.movgest_id,
l.movgest_anno,l.movgest_numero,
a.ord_id,a.ord_anno,a.ord_numero,a.ord_desc,
--d.ord_ts_id,
--d.ord_ts_code, 
c.anno anno_bilancio, 
case when l.movgest_anno::integer < c.anno::integer then ''S'' else ''N'' end residuo,
sum (e.ord_ts_det_importo) ord_importo
 from siac_t_ordinativo a,siac_t_bil b, siac_t_periodo c, siac_t_ordinativo_ts d,
  siac_t_ordinativo_ts_det e,
siac_d_ordinativo_ts_det_tipo f, 
siac_r_liquidazione_ord g, siac_r_liquidazione_movgest h,siac_t_movgest_ts i,
siac_t_movgest l, 
siac_r_movgest_class m ,siac_t_class n,siac_d_class_tipo o, siac_d_ordinativo_tipo p
where 
a.ente_proprietario_id='||ente_proprietario_id_in||'
and c.anno='''||anno_bilancio_in||'''
and b.bil_id=l.bil_id
and c.periodo_id=b.periodo_id
and p.ord_tipo_id=a.ord_tipo_id
and p.ord_tipo_code=''P''
and d.ord_id=a.ord_id
and e.ord_ts_id=d.ord_ts_id
and f.ord_ts_det_tipo_id=e.ord_ts_det_tipo_id
and f.ord_ts_det_tipo_code=''A''
and g.sord_id=d.ord_ts_id
and h.liq_id=g.liq_id
and h.movgest_ts_id=i.movgest_ts_id
and l.movgest_id=i.movgest_id
and m.movgest_ts_id=i.movgest_ts_id
and m.classif_id=n.classif_id
and n.classif_tipo_id=o.classif_tipo_id
and o.classif_tipo_code like ''PDC%''
and now() BETWEEN g.validita_inizio and COALESCE(g.validita_fine,now())
and now() BETWEEN h.validita_inizio and COALESCE(h.validita_fine,now())
and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
and a.data_cancellazione is null
and b.data_cancellazione is NULL
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is NULL
and f.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is NULL
and l.data_cancellazione is null
and m.data_cancellazione is null
and n.data_cancellazione is NULL
and o.data_cancellazione is null
group by 
a.ente_proprietario_id,
n.classif_code,n.classif_desc,
l.movgest_id,
l.movgest_anno,l.movgest_numero,
a.ord_id,a.ord_anno,a.ord_numero,a.ord_desc,
c.anno
)
, beneficiario as (select a.ord_id,b.soggetto_id,b.soggetto_code,b.soggetto_desc 
from siac_r_ordinativo_soggetto a, siac_t_soggetto b
where a.soggetto_id=b.soggetto_id
and now() BETWEEN a.validita_inizio and coalesce (a.validita_fine, now())
),
pnota as (select  
--''PRIMANOTA'' tiporiga,
a.campo_pk_id,
d.pnota_progressivogiornale pnota_numero, d.pnota_dataregistrazionegiornale pnota_data,
--d.pnota_numero,d.pnota_data,
e.movep_det_segno, i.pdce_conto_code, i.pdce_conto_desc,
 e.movep_det_importo,a.ente_proprietario_id
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
and h.collegamento_tipo_code in (''OP'')
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
select 
''ORDINATIVO'' tiporiga,
ORD.*, pnota.*,beneficiario.* from ord join pnota on ord.ord_id=pnota.campo_pk_id 
and ord.ente_proprietario_id=pnota.ente_proprietario_id
left join beneficiario on ord.ord_id=beneficiario.ord_id
order by 1,2,5,6,8,9,11,18,17)  tb';

raise notice '%', sql_query;

/*if (anno_impegno_in is not null and pdc_v_in is null and macroaggregato_in is null) then

sql_query:='select * from ('||sql_query||') tab where tab.movgest_anno='''||anno_impegno_in||'''';

elsif (anno_impegno_in is null and pdc_v_in is not null and macroaggregato_in is null) then*/

if (pdc_v_in is not null and macroaggregato_in is null) then

sql_query:='select * from ('||sql_query||') tab where tab.classif_code='''||pdc_v_in||'''';

/*elsif (anno_impegno_in is not null and pdc_v_in is not null and macroaggregato_in is null) then

sql_query:='select * from ('||sql_query||') tab where tab.movgest_anno='''||anno_impegno_in||''' and tab.classif_code='''||pdc_v_in||'''';
*/
end if;

if anno_ordinativo_in is not null THEN
sql_query:='select * from ('||sql_query||') tab where tab.ord_anno='''||anno_ordinativo_in||'''';
end if;

if numero_ordinativo_in is not null THEN
sql_query:='select * from ('||sql_query||') tab where tab.ord_numero='''||numero_ordinativo_in||'''';
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

for cur_ord in
EXECUTE sql_query
loop

tipo_riga:=cur_ord.tiporiga;
ente_proprietario_id:=cur_ord.ente_proprietario_id;
v_livello_pdc_fin:=cur_ord.classif_code;
v_livello_pdc_fin_desc:=cur_ord.classif_desc;
anno_bilancio:=cur_ord.anno_bilancio;
anno_impegno:=cur_ord.movgest_anno;
numero_impegno:=cur_ord.movgest_numero;
movgest_id:=cur_ord.movgest_id;
residuo:=cur_ord.residuo;
anno_ordinativo:=cur_ord.ord_anno;
numero_ordinativo:=cur_ord.ord_numero;
descrizione_ordinativo:=cur_ord.ord_desc;
ord_id:=cur_ord.ord_id;
importo_ordinativo:=cur_ord.ord_importo;
beneficiario:=cur_ord.soggetto_desc;
numero_prima_nota:=cur_ord.pnota_numero;
data_registrazione_prima_nota:=cur_ord.pnota_data;
tipo_conto:=cur_ord.movep_det_segno;
codice_conto:=cur_ord.pdce_conto_code;
descrizione_conto:=cur_ord.pdce_conto_desc;
importo_conto:=cur_ord.movep_det_importo;

/* calcolo gli importi DELTA come:
 - DELTA DARE = Importo Ordinativo meno Importo Dare
 - DELTA AVERE = Importo Ordinativo meno Importo Avere.
*/
 
if upper(TRIM(tipo_conto)) = 'DARE' THEN
  delta_dare:= COALESCE(importo_ordinativo, 0)- COALESCE(importo_conto, 0);
  delta_avere:=0;
ELSE
  delta_dare:= 0;
  delta_avere:= COALESCE(importo_ordinativo, 0)- COALESCE(importo_conto, 0) ;
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