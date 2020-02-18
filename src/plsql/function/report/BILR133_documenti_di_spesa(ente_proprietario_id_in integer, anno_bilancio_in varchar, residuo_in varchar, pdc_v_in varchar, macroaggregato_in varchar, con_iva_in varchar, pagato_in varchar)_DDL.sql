/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR133_documenti_di_spesa" (
  ente_proprietario_id_in integer,
  anno_bilancio_in varchar,
  residuo_in varchar,
  pdc_v_in varchar,
  macroaggregato_in varchar,
  con_iva_in varchar,
  pagato_in varchar
)
RETURNS TABLE (
  tipo_riga varchar,
  ente_proprietario_id integer,
  v_livello_pdc_fin varchar,
  v_livello_pdc_fin_desc varchar,
  anno_bilancio varchar,
  anno_impegno varchar,
  numero_impegno varchar,
  tipo_documento varchar,
  anno_documento varchar,
  numero_documento varchar,
  beneficiario varchar,
  quota_documento varchar,
  importo_quota numeric,
  importo_imponibile numeric,
  importo_imposta numeric,
  movgest_id integer,
  movgest_ts_id integer,
  residuo varchar,
  numero_prima_nota varchar,
  data_registrazione_prima_nota timestamp,
  tipo_conto varchar,
  codice_conto varchar,
  descrizione_conto varchar,
  importo_conto numeric,
  delta_dare numeric,
  delta_avere numeric,
  display_error varchar,
  sub_impegno varchar,
  delta_iva numeric
) AS
$body$
DECLARE

rec_ord record;
pnota_rec record;
tipo_riga_pnota VARCHAR;
tipo_riga_impegno VARCHAR;
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

IF pagato_in = '' OR pagato_in ='T' THEN
   pagato_in := null;
END IF;


/*
IF pdc_v_in is null AND macroaggregato_in is  null THEN
   display_error := 'Per visualizzare i dati inserire il V livello del pdc oppure il titolo/macroaggregato!';
   return next;
   return;
END IF;
*/

IF pdc_v_in is not null AND macroaggregato_in is not null  THEN
   display_error := 'Per visualizzare i dati inserire solo il V livello del pdc oppure il titolo/macroaggregato!';
   return next;
   return;
END IF;



if con_iva_in='N' then 
sql_query:='select tbsubdoc.* from (
with doc as (
select 
a.ente_proprietario_id,
f.classif_code, f.classif_desc,
h.movgest_anno,h.movgest_numero, o.movgest_ts_tipo_code, i.doc_tipo_code, 
a.doc_anno,a.doc_numero, 
b.subdoc_numero,
b.subdoc_importo, a.doc_id, b.subdoc_id,
case when h.movgest_anno::integer < m.anno::integer then ''S'' else ''N'' end residuo,
case when o.movgest_ts_tipo_code=''T'' then '''' else d.movgest_ts_code end sub_impegno,
m.anno anno_bilancio,
d.movgest_id,d.movgest_ts_id
 from siac_t_doc a, siac_t_subdoc b, 
siac_r_subdoc_movgest_ts c, siac_t_movgest_ts d,
siac_r_movgest_class e, siac_t_class f, siac_d_class_tipo g,siac_t_movgest h, siac_d_doc_tipo i,
siac_d_doc_fam_tipo l,siac_t_periodo m, siac_t_bil n, siac_d_movgest_ts_tipo o
where a.doc_id=b.doc_id
and m.anno='''||anno_bilancio_in||'''
and c.subdoc_id=b.subdoc_id
and c.movgest_ts_id=d.movgest_ts_id
and a.ente_proprietario_id='||ente_proprietario_id_in||'
and e.movgest_ts_id=d.movgest_ts_id
and f.classif_id=e.classif_id
and g.classif_tipo_id=f.classif_tipo_id
and g.classif_tipo_code like ''PDC%''
and now() BETWEEN e.validita_inizio and COALESCE(e.validita_fine,now())
and h.movgest_id=d.movgest_id
and i.doc_tipo_id=a.doc_tipo_id
and l.doc_fam_tipo_id=i.doc_fam_tipo_id
and l.doc_fam_tipo_code=''S''
and n.bil_id=h.bil_id
and n.periodo_id=m.periodo_id
and o.movgest_ts_tipo_id=d.movgest_ts_tipo_id
and a.data_cancellazione is NULL
and b.data_cancellazione is NULL
and c.data_cancellazione is NULL
and d.data_cancellazione is NULL
and e.data_cancellazione is NULL
and f.data_cancellazione is NULL
and g.data_cancellazione is NULL
and h.data_cancellazione is NULL
and i.data_cancellazione is NULL
and l.data_cancellazione is NULL
and m.data_cancellazione is NULL
and n.data_cancellazione is NULL
and o.data_cancellazione is NULL
)
, sog as (
select a.doc_id, b.soggetto_code, b.soggetto_desc from siac_r_doc_sog a, siac_t_soggetto b
where b.soggetto_id=a.soggetto_id
and a.data_cancellazione is null
and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now())
and a.ente_proprietario_id='||ente_proprietario_id_in||'
),
--condizione pagato se  ordinativo presente
pagato as (select distinct a.subdoc_id from siac_r_subdoc_ordinativo_ts a where a.ente_proprietario_id='||ente_proprietario_id_in||'
and now() between a.validita_inizio and COALESCE (a.validita_fine, now())) ,
pnota as (select  
''PRIMANOTA'' tiporiga,
a.campo_pk_id,
d.pnota_progressivogiornale pnota_numero,d.pnota_data,e.movep_det_segno, i.pdce_conto_code, i.pdce_conto_desc,
--d.pnota_id, a.regmovfin_id, e.movep_det_id, c.movep_id,c.movep_code,c.movep_desc, 
 e.movep_det_importo, a.ente_proprietario_id
 -- numero_prima_nota,data_registrazione_prima_nota,tipo_conto,codice_conto,descrizione_conto,importo_conto
 from siac_r_evento_reg_movfin a, siac_t_reg_movfin b, siac_t_mov_ep c, siac_t_prima_nota d,
siac_t_mov_ep_det e,siac_d_evento f,siac_d_evento_tipo g, siac_d_collegamento_tipo h, 
siac_t_pdce_conto i, siac_r_prima_nota_stato l, siac_d_prima_nota_stato m
where 
a.ente_proprietario_id='||ente_proprietario_id_in||'
and a.regmovfin_id=b.regmovfin_id
and b.regmovfin_id=c.regmovfin_id
and c.regep_id=d.pnota_id 
and e.movep_id=c.movep_id
and f.evento_id=a.evento_id
and g.evento_tipo_id=f.evento_tipo_id
and h.collegamento_tipo_id=f.collegamento_tipo_id
and h.collegamento_tipo_code = ''SS'' 
and i.pdce_conto_id=e.pdce_conto_id
and l.pnota_id=d.pnota_id
and l.pnota_stato_id=m.pnota_stato_id
--condizione per primenonte definitive
and d.pnota_progressivogiornale is not null
and m.pnota_stato_code<>''A''
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
and m.data_cancellazione is null)
select *,
case when pagato.subdoc_id is null then ''N'' else ''S'' end pagato
from doc 
join pnota on (doc.subdoc_id=pnota.campo_pk_id and doc.ente_proprietario_id=pnota.ente_proprietario_id)
left join sog on doc.doc_id=sog.doc_id
left join pagato on doc.subdoc_id=pagato.subdoc_id
) tbsubdoc';
elsif con_iva_in='S' then
sql_query:='select tbsubdoc.* from (
with doc as (
select 
a.ente_proprietario_id,
f.classif_code, f.classif_desc,
h.movgest_anno,h.movgest_numero, o.movgest_ts_tipo_code, i.doc_tipo_code, 
a.doc_anno,a.doc_numero, 
b.subdoc_numero,
b.subdoc_importo, a.doc_id, b.subdoc_id,
case when h.movgest_anno::integer < m.anno::integer then ''S'' else ''N'' end residuo,
case when o.movgest_ts_tipo_code=''T'' then '''' else d.movgest_ts_code end sub_impegno,
m.anno anno_bilancio,
d.movgest_id,d.movgest_ts_id
 from siac_t_doc a, siac_t_subdoc b, 
siac_r_subdoc_movgest_ts c, siac_t_movgest_ts d,
siac_r_movgest_class e, siac_t_class f, siac_d_class_tipo g,siac_t_movgest h, siac_d_doc_tipo i,
siac_d_doc_fam_tipo l,siac_t_periodo m, siac_t_bil n, siac_d_movgest_ts_tipo o
where a.doc_id=b.doc_id
and m.anno='''||anno_bilancio_in||'''
and c.subdoc_id=b.subdoc_id
and c.movgest_ts_id=d.movgest_ts_id
and a.ente_proprietario_id='||ente_proprietario_id_in||'
and e.movgest_ts_id=d.movgest_ts_id
and f.classif_id=e.classif_id
and g.classif_tipo_id=f.classif_tipo_id
and g.classif_tipo_code like ''PDC%''
and now() BETWEEN e.validita_inizio and COALESCE(e.validita_fine,now())
and h.movgest_id=d.movgest_id
and i.doc_tipo_id=a.doc_tipo_id
and l.doc_fam_tipo_id=i.doc_fam_tipo_id
and l.doc_fam_tipo_code=''S''
and n.bil_id=h.bil_id
and n.periodo_id=m.periodo_id
and o.movgest_ts_tipo_id=d.movgest_ts_tipo_id
and a.data_cancellazione is NULL
and b.data_cancellazione is NULL
and c.data_cancellazione is NULL
and d.data_cancellazione is NULL
and e.data_cancellazione is NULL
and f.data_cancellazione is NULL
and g.data_cancellazione is NULL
and h.data_cancellazione is NULL
and i.data_cancellazione is NULL
and l.data_cancellazione is NULL
and m.data_cancellazione is NULL
and n.data_cancellazione is NULL
and o.data_cancellazione is NULL
)
, sog as (
select a.doc_id, b.soggetto_code, b.soggetto_desc from siac_r_doc_sog a, siac_t_soggetto b
where b.soggetto_id=a.soggetto_id
and a.data_cancellazione is null
and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now())
and a.ente_proprietario_id='||ente_proprietario_id_in||'
),
pnota as (select  
''PRIMANOTA'' tiporiga,
a.campo_pk_id,
d.pnota_numero,d.pnota_data,e.movep_det_segno, i.pdce_conto_code, i.pdce_conto_desc,
--d.pnota_id, a.regmovfin_id, e.movep_det_id, c.movep_id,c.movep_code,c.movep_desc, 
 e.movep_det_importo, a.ente_proprietario_id
 -- numero_prima_nota,data_registrazione_prima_nota,tipo_conto,codice_conto,descrizione_conto,importo_conto
 from siac_r_evento_reg_movfin a, siac_t_reg_movfin b, siac_t_mov_ep c, siac_t_prima_nota d,
siac_t_mov_ep_det e,siac_d_evento f,siac_d_evento_tipo g, siac_d_collegamento_tipo h, 
siac_t_pdce_conto i
where 
a.ente_proprietario_id='||ente_proprietario_id_in||'
and a.regmovfin_id=b.regmovfin_id
and b.regmovfin_id=c.regmovfin_id
and c.regep_id=d.pnota_id 
and e.movep_id=c.movep_id
and f.evento_id=a.evento_id
and g.evento_tipo_id=f.evento_tipo_id
and h.collegamento_tipo_id=f.collegamento_tipo_id
and h.collegamento_tipo_code = ''SS'' 
and i.pdce_conto_id=e.pdce_conto_id
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
and i.data_cancellazione is null),
--condizione pagato se  ordinativo presente
pagato as (select distinct a.subdoc_id from siac_r_subdoc_ordinativo_ts a where a.ente_proprietario_id='||ente_proprietario_id_in||'
and now() between a.validita_inizio and COALESCE (a.validita_fine, now())) ,
iva as ( select distinct c.doc_id, g.ivaaliquota_tipo_code, f.ivaaliquota_perc_indetr
from siac_t_subdoc_iva a, siac_r_subdoc_subdoc_iva b,
	siac_t_subdoc c, siac_r_ivamov d, siac_t_ivamov e, 
    siac_t_iva_aliquota f,
    siac_d_iva_aliquota_tipo g
where a.subdociva_id=b.subdociva_id
and b.subdoc_id=c.subdoc_id
and d.subdociva_id=a.subdociva_id
and e.ivamov_id= d.ivamov_id
and f.ivaaliquota_id=e.ivaaliquota_id
and g.ivaaliquota_tipo_id=f.ivaaliquota_tipo_id
and a.ente_proprietario_id='||ente_proprietario_id_in||'
and (g.ivaaliquota_tipo_code=''P'' 
	OR (g.ivaaliquota_tipo_code=''C'' AND f.ivaaliquota_perc_indetr <>100))
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
union select distinct b.doc_id, g.ivaaliquota_tipo_code, f.ivaaliquota_perc_indetr
from siac_t_subdoc_iva a, siac_r_doc_iva b,
	siac_t_subdoc c, siac_r_ivamov d, siac_t_ivamov e, 
    siac_t_iva_aliquota f,
    siac_d_iva_aliquota_tipo g
where a.dociva_r_id=b.dociva_r_id
and b.doc_id=c.doc_id
and d.subdociva_id=a.subdociva_id
and e.ivamov_id= d.ivamov_id
and f.ivaaliquota_id=e.ivaaliquota_id
and g.ivaaliquota_tipo_id=f.ivaaliquota_tipo_id
and a.ente_proprietario_id='||ente_proprietario_id_in||'
and (g.ivaaliquota_tipo_code=''P'' 
	OR (g.ivaaliquota_tipo_code=''C'' AND f.ivaaliquota_perc_indetr <>100))
and a.data_cancellazione is null
and b.data_cancellazione is null
)
select *,
case when pagato.subdoc_id is null then ''N'' else ''S'' end pagato
from doc
join pnota on (doc.subdoc_id=pnota.campo_pk_id and doc.ente_proprietario_id=pnota.ente_proprietario_id)
left join sog on doc.doc_id=sog.doc_id
join iva on iva.doc_id=doc.doc_id
left join pagato on doc.subdoc_id=pagato.subdoc_id
) tbsubdoc';
end if;
/*
if (anno_impegno_in is not null and pdc_v_in is null and macroaggregato_in is null) then

sql_query:='select * from ('||sql_query||') tb where tb.movgest_anno='''||anno_impegno_in||'''';

elsif (anno_impegno_in is null and pdc_v_in is not null and macroaggregato_in is null) then*/

if (pdc_v_in is not null and macroaggregato_in is null) then

sql_query:='select * from ('||sql_query||') tb where tb.classif_code='''||pdc_v_in||'''';

/*elsif (anno_impegno_in is not null and pdc_v_in is not null and macroaggregato_in is null) then

sql_query:='select * from ('||sql_query||') tb where tb.movgest_anno='''||anno_impegno_in||''' and tb.classif_code='''||pdc_v_in||'''';
*/
end if;

if pagato_in is not null THEN
sql_query:='select * from ('||sql_query||') tab where tab.pagato='''||pagato_in||'''';
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

for rec_ord in
EXECUTE sql_query
loop

tipo_riga_impegno:=rec_ord.tiporiga;
ente_proprietario_id:=rec_ord.ente_proprietario_id;
v_livello_pdc_fin:=rec_ord.classif_code;
v_livello_pdc_fin_desc:=rec_ord.classif_desc;
anno_bilancio:=rec_ord.anno_bilancio;
anno_impegno:=rec_ord.movgest_anno;
numero_impegno:=rec_ord.movgest_numero;
tipo_documento:=rec_ord.doc_tipo_code;
anno_documento:=rec_ord.doc_anno;
numero_documento:=rec_ord.doc_numero;
beneficiario:=rec_ord.soggetto_desc;  
quota_documento:=rec_ord.subdoc_numero;
importo_quota:=rec_ord.subdoc_importo;
/*importo_imponibile:=rec_ord.
importo_imposta:=rec_ord.*/
importo_imponibile:=null;
importo_imposta:=null;
movgest_id:=rec_ord.movgest_id;
movgest_ts_id:=rec_ord.movgest_ts_id;
residuo:=rec_ord.residuo;
numero_prima_nota:=rec_ord.pnota_numero;
data_registrazione_prima_nota:=rec_ord.pnota_data;
tipo_conto:=rec_ord.movep_det_segno;
codice_conto:=rec_ord.pdce_conto_code;
descrizione_conto:=rec_ord.pdce_conto_desc;
importo_conto:=rec_ord.movep_det_importo;
sub_impegno:=rec_ord.sub_impegno;

if upper(TRIM(tipo_conto)) = 'DARE' and codice_conto <> '1.3.2.01.01.03.002' THEN
  delta_dare:= COALESCE(importo_quota, 0)- COALESCE(importo_conto, 0);
  delta_avere:=0;
  delta_iva:=0;
ELSIF upper(TRIM(tipo_conto)) = 'AVERE' and codice_conto <> '1.3.2.01.01.03.002' THEN
  delta_dare:= 0;
  delta_avere:= COALESCE(importo_quota, 0)- COALESCE(importo_conto, 0) ;
  delta_iva:=0;
ELSE 
  delta_dare:= 0;
  delta_avere:=0;
  delta_iva:= COALESCE(importo_quota, 0)- COALESCE(importo_conto, 0) ;
END IF ;


--raise notice 'impegno :% - % - % - % - % - % - % - % - % - % - % - %', tipo_riga_impegno,ente_proprietario_id,anno_bilancio,anno_impegno,numero_impegno,numero_subimpegno,tipo_sub,movgest_ts_id,descrizione,importo,residuo,modifica;



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