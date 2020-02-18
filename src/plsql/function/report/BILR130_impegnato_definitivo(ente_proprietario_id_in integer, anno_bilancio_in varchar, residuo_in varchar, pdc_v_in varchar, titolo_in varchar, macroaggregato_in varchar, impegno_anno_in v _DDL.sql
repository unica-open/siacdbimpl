/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR130_impegnato_definitivo" (
  ente_proprietario_id_in integer,
  anno_bilancio_in varchar,
  residuo_in varchar,
  pdc_v_in varchar,
  titolo_in varchar,
  macroaggregato_in varchar,
  impegno_anno_in varchar,
  impegno_numero_in varchar,
  subimpegno_numero_in varchar
)
RETURNS TABLE (
  ente_proprietario_id integer,
  anno_bilancio varchar,
  v_livello_pdc_fin varchar,
  v_livello_pdc_fin_desc varchar,
  tipo_riga varchar,
  anno_impegno varchar,
  numero_impegno varchar,
  numero_subimpegno varchar,
  modifica varchar,
  descrizione varchar,
  importo numeric,
  residuo varchar,
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

rec_impegni record;
DEF_NULL    constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
sql_query text;

BEGIN
-- Sezione aggiunta per gestire il relativo report INIZIO
display_error := '';

IF pdc_v_in = '' THEN
   pdc_v_in := null;
END IF;

IF impegno_anno_in = '' THEN
   impegno_anno_in := null;
END IF;

IF impegno_numero_in = '' THEN
   impegno_numero_in := null;
END IF;

IF subimpegno_numero_in = '' THEN
   subimpegno_numero_in := null;
END IF;

IF titolo_in = 'T' AND macroaggregato_in = 'T' THEN
   titolo_in := null;
   macroaggregato_in := null;
END IF;

IF pdc_v_in is not null AND macroaggregato_in is not null THEN
   display_error := 'Per visualizzare i dati inserire il V livello del pdc o titolo/macroaggregato!';
   return next;
   return;
END IF;

IF (residuo_in = 'N' AND impegno_anno_in < anno_bilancio_in)
   OR
   (residuo_in = 'S' AND impegno_anno_in >= anno_bilancio_in) THEN
   display_error := 'Per visualizzare i dati inserire l''anno di impegno coerente con l''impegno di competenza/residuo!';
   return next;
   return;
END IF;

IF ((impegno_anno_in is null OR impegno_numero_in is null) AND subimpegno_numero_in is not null)
   OR
   (impegno_anno_in is not null AND impegno_numero_in is null)
   OR
   (impegno_anno_in is null AND impegno_numero_in is not null) THEN
   display_error := 'Per visualizzare i dati inserire anno e numero impegno!';
   return next;
   return;   
END IF;
-- Sezione aggiunta per gestire il relativo report FINE

sql_query:='select tb2.* from (
with imp as (
select tb.* from (
select a.ente_proprietario_id,
p.classif_id,p.classif_code,p.classif_desc,
case when h.movgest_ts_tipo_code=''T'' then ''IMPEGNO'' else ''SUBIMPEGNO'' end tipo_riga,
c.movgest_id,c.movgest_anno, c.movgest_numero, 
case when h.movgest_ts_tipo_code=''T'' then null else e.movgest_ts_code end movgest_ts_code,
null mod_num,
c.movgest_desc,
b.anno anno_bilancio, 
case when c.movgest_anno::integer < b.anno::integer then ''S'' else ''N'' end residuo,
f.movgest_ts_det_importo,
''N'' modifica,
case when h.movgest_ts_tipo_code=''T'' then c.movgest_id else e.movgest_ts_id end campo_x_primanota,
case when h.movgest_ts_tipo_code=''T'' then ''I'' else ''SI'' end tipo_collegamento
 From 
siac_t_bil a,
siac_t_periodo b,
siac_t_movgest c,
siac_d_movgest_tipo d,
siac_t_movgest_ts e,
siac_t_movgest_ts_det f,
siac_d_movgest_ts_det_tipo g,
siac_d_movgest_ts_tipo h,
siac_r_movgest_class o,
siac_t_class p,
siac_d_class_tipo q
where 
a.periodo_id=b.periodo_id and c.bil_id=A.bil_id and c.ente_proprietario_id='||ente_proprietario_id_in||' and d.movgest_tipo_id=c.movgest_tipo_id
and b.anno='''||anno_bilancio_in||'''
and d.movgest_tipo_code=''I'' and e.movgest_id=c.movgest_id and e.movgest_ts_id=f.movgest_ts_id and g.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
and h.movgest_ts_tipo_id=e.movgest_ts_tipo_id 
and g.movgest_ts_det_tipo_code=''A''
and o.movgest_ts_id=e.movgest_ts_id
and p.classif_id=o.classif_id
and q.classif_tipo_id=p.classif_tipo_id
and q.classif_tipo_code like ''PDC%''
and now() BETWEEN o.validita_inizio and coalesce (o.validita_fine, now())
and a.data_cancellazione is null and b.data_cancellazione is null
and c.data_cancellazione is null and d.data_cancellazione is null and e.data_cancellazione is null
and f.data_cancellazione is null and g.data_cancellazione is null and h.data_cancellazione is null 
and o.data_cancellazione is null
and p.data_cancellazione is null
and q.data_cancellazione is null
union
select a.ente_proprietario_id,
p.classif_id,p.classif_code,p.classif_desc,
case when h.movgest_ts_tipo_code=''T'' then ''IMPEGNO'' else ''SUBIMPEGNO'' end tipo_riga,
c.movgest_id,c.movgest_anno, c.movgest_numero, 
case when h.movgest_ts_tipo_code=''T'' then null else e.movgest_ts_code end movgest_ts_code,
m.mod_num,
''modifica tipo '' || COALESCE(n.mod_tipo_desc, n.mod_tipo_desc||'' - '','''')||m.mod_desc movgest_desc,
b.anno anno_bilancio, 
case when c.movgest_anno::integer < b.anno::integer then ''S'' else ''N'' end residuo,
f.movgest_ts_det_importo,
''S'' modifica,
--case when h.movgest_ts_tipo_code=''T'' then c.movgest_id else e.movgest_ts_id end campo_x_primanota,
i.mod_id campo_x_primanota,
--case when h.movgest_ts_tipo_code=''T'' then ''I'' else ''SI'' end tipo_collegamento
''MMGS'' tipo_collegamento
 From 
siac_t_bil a,
siac_t_periodo b,
siac_t_movgest c,
siac_d_movgest_tipo d,
siac_t_movgest_ts e,
siac_t_movgest_ts_det_mod f,
siac_d_movgest_ts_det_tipo g,
siac_d_movgest_ts_tipo h,
siac_r_modifica_stato i,
siac_d_modifica_stato l,
siac_t_modifica m
	left join siac_d_modifica_tipo n
		ON(m.mod_tipo_id=n.mod_tipo_id and n.data_cancellazione is NULL),
siac_r_movgest_class o,
siac_t_class p,
siac_d_class_tipo q
where 
a.periodo_id=b.periodo_id
and c.bil_id=A.bil_id
and c.ente_proprietario_id='||ente_proprietario_id_in||' and 
d.movgest_tipo_id=c.movgest_tipo_id
and d.movgest_tipo_code=''I''
and b.anno='''||anno_bilancio_in||'''
and e.movgest_id=c.movgest_id
and e.movgest_ts_id=f.movgest_ts_id
and g.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
and h.movgest_ts_tipo_id=e.movgest_ts_tipo_id
and i.mod_stato_r_id=f.mod_stato_r_id
and l.mod_stato_id=i.mod_stato_id
and m.mod_id=i.mod_id
and g.movgest_ts_det_tipo_code=''A''
and o.movgest_ts_id=e.movgest_ts_id
and p.classif_id=o.classif_id
and q.classif_tipo_id=p.classif_tipo_id
and q.classif_tipo_code like ''PDC%''
and now() BETWEEN o.validita_inizio and coalesce (o.validita_fine, now())
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
and m.data_cancellazione is null
and o.data_cancellazione is null
and p.data_cancellazione is null
and q.data_cancellazione is null
and now() BETWEEN i.validita_inizio and coalesce (i.validita_fine, now())
and l.mod_stato_code <>''A'')
tb 
)
, 
pnota as (select  h.collegamento_tipo_code,a.campo_pk_id,
--d.pnota_numero,d.pnota_data,
d.pnota_progressivogiornale pnota_numero, d.pnota_dataregistrazionegiornale pnota_data,
trim(e.movep_det_segno) movep_det_segno, i.pdce_conto_code, i.pdce_conto_desc,
 e.movep_det_importo
 from siac_r_evento_reg_movfin a, siac_t_reg_movfin b, siac_t_mov_ep c, siac_t_prima_nota d,
siac_t_mov_ep_det e,siac_d_evento f,siac_d_evento_tipo g, siac_d_collegamento_tipo h, 
siac_t_pdce_conto i,siac_r_prima_nota_stato l,siac_d_prima_nota_stato m
where 
a.ente_proprietario_id='||ente_proprietario_id_in||'
and a.regmovfin_id=b.regmovfin_id
and b.regmovfin_id=c.regmovfin_id
and c.regep_id=d.pnota_id 
and e.movep_id=c.movep_id
and f.evento_id=a.evento_id
and g.evento_tipo_id=f.evento_tipo_id
and h.collegamento_tipo_id=f.collegamento_tipo_id
and h.collegamento_tipo_code in (''I'',''SI'',''MMGS'')
and i.pdce_conto_id=e.pdce_conto_id
and l.pnota_id=d.pnota_id
and m.pnota_stato_id=l.pnota_stato_id
and m.pnota_stato_code<>''A''
and now() between a.validita_inizio and COALESCE (a.validita_fine, now())
and now() between l.validita_inizio and COALESCE (l.validita_fine, now())
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null)
select * from imp left join 
pnota on IMP.campo_x_primanota=pnota.campo_pk_id
and imp.tipo_collegamento=collegamento_tipo_code
) tb2 
--filtro solo gli impegni che hanno un collegamento con primanota livello imp o subimp
where tb2.movgest_id in (with imp as (
select tb.* from (
select a.ente_proprietario_id,
p.classif_id,p.classif_code,p.classif_desc,
case when h.movgest_ts_tipo_code=''T'' then ''IMPEGNO'' else ''SUBIMPEGNO'' end tipo_riga,
c.movgest_id,c.movgest_anno, c.movgest_numero, 
case when h.movgest_ts_tipo_code=''T'' then null else e.movgest_ts_code end movgest_ts_code,
null mod_num,
c.movgest_desc,
b.anno anno_bilancio, 
case when c.movgest_anno::integer < b.anno::integer then ''S'' else ''N'' end residuo,
f.movgest_ts_det_importo,
''N'' modifica,
case when h.movgest_ts_tipo_code=''T'' then c.movgest_id else e.movgest_ts_id end campo_x_primanota,
case when h.movgest_ts_tipo_code=''T'' then ''I'' else ''SI'' end tipo_collegamento
 From 
siac_t_bil a,
siac_t_periodo b,
siac_t_movgest c,
siac_d_movgest_tipo d,
siac_t_movgest_ts e,
siac_t_movgest_ts_det f,
siac_d_movgest_ts_det_tipo g,
siac_d_movgest_ts_tipo h,
siac_r_movgest_class o,
siac_t_class p,
siac_d_class_tipo q
where 
a.periodo_id=b.periodo_id and c.bil_id=A.bil_id and c.ente_proprietario_id='||ente_proprietario_id_in||' and d.movgest_tipo_id=c.movgest_tipo_id
and d.movgest_tipo_code=''I'' and e.movgest_id=c.movgest_id and e.movgest_ts_id=f.movgest_ts_id and g.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
and h.movgest_ts_tipo_id=e.movgest_ts_tipo_id 
and g.movgest_ts_det_tipo_code=''A''
and o.movgest_ts_id=e.movgest_ts_id
and p.classif_id=o.classif_id
and q.classif_tipo_id=p.classif_tipo_id
and q.classif_tipo_code like ''PDC%''
and now() between o.validita_inizio and COALESCE (o.validita_fine, now())
and a.data_cancellazione is null and b.data_cancellazione is null
and c.data_cancellazione is null and d.data_cancellazione is null and e.data_cancellazione is null
and f.data_cancellazione is null and g.data_cancellazione is null and h.data_cancellazione is null
and o.data_cancellazione is null
and p.data_cancellazione is null
and q.data_cancellazione is null
union
select a.ente_proprietario_id,
p.classif_id,p.classif_code,p.classif_desc,
case when h.movgest_ts_tipo_code=''T'' then ''IMPEGNO'' else ''SUBIMPEGNO'' end tipo_riga,
c.movgest_id,c.movgest_anno, c.movgest_numero, 
case when h.movgest_ts_tipo_code=''T'' then null else e.movgest_ts_code end movgest_ts_code,
m.mod_num,
''modifica tipo '' || n.mod_tipo_desc||'' - ''||m.mod_desc movgest_desc,
b.anno anno_bilancio, 
case when c.movgest_anno::integer < b.anno::integer then ''S'' else ''N'' end residuo,
f.movgest_ts_det_importo,
''S'' modifica,
--case when h.movgest_ts_tipo_code=''T'' then c.movgest_id else e.movgest_ts_id end campo_x_primanota,
i.mod_id campo_x_primanota,
--case when h.movgest_ts_tipo_code=''T'' then ''I'' else ''SI'' end tipo_collegamento
''MMGS'' tipo_collegamento
 From 
siac_t_bil a,
siac_t_periodo b,
siac_t_movgest c,
siac_d_movgest_tipo d,
siac_t_movgest_ts e,
siac_t_movgest_ts_det_mod f,
siac_d_movgest_ts_det_tipo g,
siac_d_movgest_ts_tipo h,
siac_r_modifica_stato i,
siac_d_modifica_stato l,
siac_t_modifica m,
siac_d_modifica_tipo n,
siac_r_movgest_class o,
siac_t_class p,
siac_d_class_tipo q
where 
a.periodo_id=b.periodo_id
and c.bil_id=A.bil_id
and c.ente_proprietario_id='||ente_proprietario_id_in||' and 
d.movgest_tipo_id=c.movgest_tipo_id
and d.movgest_tipo_code=''I''
and e.movgest_id=c.movgest_id
and e.movgest_ts_id=f.movgest_ts_id
and g.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
and h.movgest_ts_tipo_id=e.movgest_ts_tipo_id
and i.mod_stato_r_id=f.mod_stato_r_id
and l.mod_stato_id=i.mod_stato_id
and m.mod_id=i.mod_id
and n.mod_tipo_id=m.mod_tipo_id
and g.movgest_ts_det_tipo_code=''A''
and o.movgest_ts_id=e.movgest_ts_id
and p.classif_id=o.classif_id
and q.classif_tipo_id=p.classif_tipo_id
and q.classif_tipo_code like ''PDC%''
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
and m.data_cancellazione is null
and n.data_cancellazione is null
and o.data_cancellazione is null
and p.data_cancellazione is null
and q.data_cancellazione is null
and now() between o.validita_inizio and COALESCE (o.validita_fine, now())
and now() BETWEEN i.validita_inizio and coalesce (i.validita_fine, now())
and l.mod_stato_code <>''A'')
tb 
)
, 
pnota as (select  h.collegamento_tipo_code,a.campo_pk_id,
--d.pnota_numero,d.pnota_data,
d.pnota_progressivogiornale pnota_numero, d.pnota_dataregistrazionegiornale pnota_data,
trim(e.movep_det_segno) movep_det_segno, i.pdce_conto_code, i.pdce_conto_desc,
 e.movep_det_importo
 from siac_r_evento_reg_movfin a, siac_t_reg_movfin b, siac_t_mov_ep c, siac_t_prima_nota d,
siac_t_mov_ep_det e,siac_d_evento f,siac_d_evento_tipo g, siac_d_collegamento_tipo h, 
siac_t_pdce_conto i,siac_r_prima_nota_stato l,siac_d_prima_nota_stato m
where 
a.ente_proprietario_id='||ente_proprietario_id_in||'
and a.regmovfin_id=b.regmovfin_id
and b.regmovfin_id=c.regmovfin_id
and c.regep_id=d.pnota_id 
and e.movep_id=c.movep_id
and f.evento_id=a.evento_id
and g.evento_tipo_id=f.evento_tipo_id
and h.collegamento_tipo_id=f.collegamento_tipo_id
and h.collegamento_tipo_code in (''I'',''SI'',''MMGS'')
and i.pdce_conto_id=e.pdce_conto_id
and l.pnota_id=d.pnota_id
and m.pnota_stato_id=l.pnota_stato_id
and m.pnota_stato_code<>''A''
and now() between a.validita_inizio and COALESCE (a.validita_fine, now())
and now() between l.validita_inizio and COALESCE (l.validita_fine, now())
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null)
select distinct IMP.movgest_id from imp join 
pnota on IMP.campo_x_primanota=pnota.campo_pk_id
and imp.tipo_collegamento=collegamento_tipo_code
and pnota.pnota_numero is not null
)';

/*if (anno_impegno_in is not null and pdc_v_in is null and macroaggregato_in is null) then

sql_query:='select * from ('||sql_query||') tab where tab.movgest_anno='''||anno_impegno_in||'''';

elsif (anno_impegno_in is null and pdc_v_in is not null and macroaggregato_in is null) then
*/

if (pdc_v_in is not null and macroaggregato_in is null) then

sql_query:='select * from ('||sql_query||') tab where tab.classif_code='''||pdc_v_in||'''';

/*elsif (anno_impegno_in is not null and pdc_v_in is not null and macroaggregato_in is null) then

sql_query:='select * from ('||sql_query||') tab where tab.movgest_anno='''||anno_impegno_in||''' and ttabb.classif_code='''||pdc_v_in||'''';
*/
end if;

if impegno_anno_in is not null THEN
sql_query:='select * from ('||sql_query||') tab where tab.movgest_anno='''||impegno_anno_in||'''';
end if;

if impegno_numero_in is not null THEN
sql_query:='select * from ('||sql_query||') tab where tab.movgest_numero='''||impegno_numero_in||'''';
end if;

if subimpegno_numero_in is not null THEN
sql_query:='select * from ('||sql_query||') tab where tab.movgest_ts_code='''||subimpegno_numero_in||'''';
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


sql_query:='select * from ('||sql_query||') tab order by tab.classif_code, tab.movgest_anno,tab.movgest_numero, COALESCE(tab.movgest_ts_code, ''0''), COALESCE(tab.mod_num, ''0'')';


raise notice '%', sql_query;

for rec_impegni in
EXECUTE sql_query
loop

ente_proprietario_id:=rec_impegni.ente_proprietario_id;
anno_bilancio:=rec_impegni.anno_bilancio;
v_livello_pdc_fin:=rec_impegni.classif_code;
v_livello_pdc_fin_desc:=rec_impegni.classif_desc;
tipo_riga:=rec_impegni.tipo_riga;
anno_impegno:=rec_impegni.movgest_anno;
numero_impegno:=rec_impegni.movgest_numero;
numero_subimpegno:=rec_impegni.movgest_ts_code;
modifica:=rec_impegni.mod_num;
descrizione:=rec_impegni.movgest_desc;
importo:=rec_impegni.movgest_ts_det_importo;
residuo:=rec_impegni.residuo;
numero_prima_nota:=rec_impegni.pnota_numero;
data_registrazione_prima_nota:=rec_impegni.pnota_data;
tipo_conto:=rec_impegni.movep_det_segno;
codice_conto:=rec_impegni.pdce_conto_code;
descrizione_conto:=rec_impegni.pdce_conto_desc;
importo_conto:=rec_impegni.movep_det_importo;
delta_dare:=null;
delta_avere:=null;

return next;

--raise notice 'impegno :% - % - % - % - % - % - % - % - % - % - % - %', tipo_riga_impegno,ente_proprietario_id,anno_bilancio,anno_impegno,numero_impegno,numero_subimpegno,tipo_sub,movgest_ts_id,descrizione,importo,residuo,modifica;

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