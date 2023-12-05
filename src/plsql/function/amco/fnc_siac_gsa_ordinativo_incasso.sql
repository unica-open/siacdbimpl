/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop FUNCTION if exists siac.fnc_siac_gsa_ordinativo_incasso 
(
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
);

 CREATE OR REPLACE FUNCTION siac.fnc_siac_gsa_ordinativo_incasso (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

v_user_table varchar;
params varchar;
p_bilancio_id integer:=null;

BEGIN


select fnc_siac_random_user()
into	v_user_table;


IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;
IF p_anno_bilancio IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Anno di bilancio nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;


select bil.bil_id into p_bilancio_id
from siac_t_bil bil,siac_t_periodo per 
where bil.ente_proprietario_id =p_ente_proprietario_id 
and      per.periodo_id=bil.periodo_id 
and      per.anno::integer=p_anno_bilancio::integer;
if p_bilancio_id is null then 
   RAISE EXCEPTION 'Errore: Parametro BilancioId non determina da Anno di bilancio';
   RETURN;
end if;

params := p_anno_bilancio||' - '||p_bilancio_id::varchar||' - '||p_ente_proprietario_id::varchar||' - '||p_data::varchar;

esito:= 'Inizio funzione carico ordinativi  incasso GSA (fnc_siac_gsa_ordinativo_incasso) - '||clock_timestamp();
RETURN NEXT;
insert into
siac_gsa_ordinativi_log_elab 
(
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values 
(
p_ente_proprietario_id,
'fnc_siac_gsa_ordinativo_incasso',
esito,
clock_timestamp(),
v_user_table
);

esito:='Parametri='||params;
RETURN NEXT;
insert into
siac_gsa_ordinativi_log_elab 
(
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values 
(
p_ente_proprietario_id,
'fnc_siac_gsa_ordinativo_incasso',
params,
clock_timestamp(),
v_user_table
);


esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
insert into
siac_gsa_ordinativi_log_elab 
(
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values 
(
p_ente_proprietario_id,
'fnc_siac_gsa_ordinativo_incasso',
esito,
clock_timestamp(),
v_user_table
);

DELETE FROM siac.siac_gsa_ordinativo_incasso
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   anno_bilancio = p_anno_bilancio::integer;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;
insert into
siac_gsa_ordinativi_log_elab 
(
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values 
(
p_ente_proprietario_id,
'fnc_siac_gsa_ordinativo_incasso',
esito,
clock_timestamp(),
v_user_table
);

esito:= '  Inizio caricamento dati into siac_gsa_ordinativo_incasso  - '||clock_timestamp();
return next;
insert into
siac_gsa_ordinativi_log_elab 
(
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values 
(
p_ente_proprietario_id,
'fnc_siac_gsa_ordinativo_incasso',
esito,
clock_timestamp(),
v_user_table
);

INSERT INTO siac.siac_gsa_ordinativo_incasso
 (
    ente_proprietario_id,
	anno_bilancio,
	ord_anno,
	ord_numero,
	ord_desc,
	ord_stato_code,
	ord_data_emissione,
	ord_data_firma,
	ord_data_quietanza,
	ord_data_annullo,
    numero_capitolo,
    numero_articolo,
    capitolo_desc,
    soggetto_code,
    soggetto_desc,
    pdc_fin_liv_5,
    pdc_fin_liv_4,
    pdc_fin_liv_3,
    pdc_fin_liv_2,
    pdc_fin_liv_1,
	ord_sub_numero, 
	ord_sub_importo,
	ord_sub_desc,
    movgest_anno,
    movgest_numero,
    movgest_sub_numero,
    movgest_gsa,
    movgest_attoamm_tipo_code,
    movgest_attoamm_anno,
    movgest_attoamm_numero,
    movgest_attoamm_sac,
    ord_attoamm_tipo_code,
    ord_attoamm_anno,
    ord_attoamm_numero,
    ord_attoamm_sac
)
select 
    ord_gsa.ente_proprietario_id,
	ord_gsa.anno_bilancio,
	ord_gsa.ord_anno,
	ord_gsa.ord_numero,
	ord_gsa.ord_desc,
	ord_gsa.ord_stato_code,
	ord_gsa.ord_data_emissione,
	ord_gsa.ord_data_firma,
	ord_gsa.ord_data_quietanza,
	ord_gsa.ord_data_annullo,
    ord_gsa.numero_capitolo,
    ord_gsa.numero_articolo,
    ord_gsa.capitolo_desc,
    ord_gsa.soggetto_code,
    ord_gsa.soggetto_desc,
    ord_gsa.pdc_fin_liv_5,
    ord_gsa.pdc_fin_liv_4,
    ord_gsa.pdc_fin_liv_3,
    ord_gsa.pdc_fin_liv_2,
    ord_gsa.pdc_fin_liv_1,
	ord_gsa.ord_sub_numero, 
	ord_gsa.ord_sub_importo,
	ord_gsa.ord_sub_desc,
    ord_gsa.movgest_anno,
    ord_gsa.movgest_numero,
    ord_gsa.movgest_sub_numero,
    ord_gsa.movgest_gsa,
    ord_gsa.movgest_attoamm_tipo_code,
    ord_gsa.movgest_attoamm_anno,
    ord_gsa.movgest_attoamm_numero,
    ord_gsa.movgest_attoamm_sac,
    ord_gsa.ord_attoamm_tipo_code,
    ord_gsa.ord_attoamm_anno,
    ord_gsa.ord_attoamm_numero,
    ord_gsa.ord_attoamm_sac
from 
(
with ordinativo as 
(
SELECT 
                  ente.ente_proprietario_id, 
                  per.anno::integer anno_bilancio,
				  ord.ord_anno, ord.ord_numero, 
				  ord.ord_desc, 
				  stato.ord_stato_code, 
				  ord.ord_emissione_data ord_data_emissione,
			      ord.ord_id, 
				  bil.bil_id,
				  rs.validita_inizio data_inizio_val_stato_ord
FROM siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
			 siac_t_bil bil, siac_t_periodo per,
             siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato,
             siac_t_ente_proprietario  ente
where  ente.ente_proprietario_id = p_ente_proprietario_id
and       bil.ente_proprietario_id =ente.ente_proprietario_id 
and       per.periodo_id=bil.periodo_id 
and       per.anno::integer=p_anno_bilancio::integer
and       tipo.ente_proprietario_id =p_ente_proprietario_id 
and       tipo.ord_tipo_code='I' 
and       ord.ord_tipo_id=tipo.ord_tipo_id 
and       ord.bil_id=bil.bil_id 
and       rs.ord_id=ord.ord_id 
and       stato.ord_stato_id=rs.ord_stato_id 
and       exists 
(
select 1
from siac_t_ordinativo_ts ts,siac_r_ordinativo_ts_movgest_ts rmov,
          siac_r_movgest_ts_attr rattr,siac_t_attr attr 
where ts.ord_id=ord.ord_id 
and     rmov.ord_ts_id =ts.ord_ts_id 
and     rattr.movgest_ts_id =rmov.movgest_ts_id 
and     attr.attr_id =rattr.attr_id 
and     attr.attr_code='FlagAttivaGsa'
and     rattr."boolean" ='S'
and     ts.data_cancellazione is null 
and     ts.validita_fine  is null 
and     rmov.data_cancellazione  is null 
and     rmov.validita_fine  is null 
and     rattr.data_cancellazione  is null 
and     rattr.validita_fine  is null 
)
and       (stato.ord_stato_code!='A' or date_trunc('DAY',rs.validita_inizio)>date_trunc('DAY',ord.data_creazione))
and       ord.data_cancellazione  is null 
and       rs.data_cancellazione  is null 
and       ord.validita_fine  is null
and       rs.validita_fine  is null
),
ord_firma as 
(
select r.ord_id, r.ord_firma_data ord_data_firma 
from siac_r_ordinativo_firma r 
where r.ente_proprietario_id =p_ente_proprietario_id 
and     r.data_cancellazione  is null 
and     r.validita_fine  is null 
--limit 1
),
ord_quietanza as 
(
select r.ord_id, r.ord_quietanza_data ord_data_quietanza
from siac_r_ordinativo_quietanza  r 
where r.ente_proprietario_id =p_ente_proprietario_id 
and     r.data_cancellazione  is null 
and     r.validita_fine  is null 
--limit 1
),
ord_capitolo as
(
select  re.ord_id, 
             e.elem_code::integer numero_capitolo ,
             e.elem_code2::integer numero_articolo,
             substring( e.elem_desc,1,500) capitolo_desc 
from siac_r_ordinativo_bil_elem re,siac_t_bil_elem e 
where re.ente_proprietario_id =p_ente_proprietario_id 
and      e.elem_id=re.elem_id 
and      re.data_cancellazione  is null 
and      re.validita_fine  is null 
--limit 1
),
ord_sub as 
(
 with 
 ord_dettagli as 
 (
  select ts.ord_ts_code::integer ord_sub_numero, ts.ord_ts_desc ord_sub_desc,
              det.ord_ts_det_importo ord_sub_importo,
              ts.ord_id,ts.ord_ts_id
  from siac_d_ordinativo_ts_det_tipo tipo, siac_t_ordinativo_ts_det det,siac_t_ordinativo_ts ts,siac_t_ordinativo ord
  where tipo.ente_proprietario_id =p_ente_proprietario_id 
  and     tipo.ord_ts_det_tipo_code ='A'
  and     det.ord_ts_det_tipo_id =tipo.ord_ts_det_tipo_id
  and     ts.ord_ts_id =det.ord_ts_id 
  and     ord.ord_id=ts.ord_id 
  and     ord.bil_id= p_bilancio_id
  and      ts.data_cancellazione  is null 
  and      ts.validita_fine  is null 
  and      det.data_cancellazione  is null 
  and      det.validita_fine  is null 
  and      ord.data_cancellazione  is null 
  and      ord.validita_fine  is null 
 ),
 ord_movimenti as 
 (
  with 
  movimenti as 
  (
  select rord.ord_ts_id,rord.movgest_ts_id, 
              mov.movgest_anno, mov.movgest_numero,  
              ( case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_sub_numero 
  from  siac_r_ordinativo_ts_movgest_ts rord,siac_t_movgest_ts ts, siac_t_movgest mov ,siac_d_movgest_ts_tipo tipo 
  where tipo.ente_proprietario_id =p_ente_proprietario_id 
  and     ts.movgest_ts_tipo_id=tipo.movgest_ts_tipo_id 
  and     mov.movgest_id=ts.movgest_id
  and     mov.bil_id= p_bilancio_id
  and     rord.movgest_ts_id=ts.movgest_ts_id 
  and     mov.data_cancellazione  is null 
  and     mov.validita_fine  is null 
  and     ts.data_cancellazione  is null 
  and     ts.validita_fine  is null 
  and     rord.data_cancellazione  is null 
  and     rord.validita_fine  is null 
  ),
  movim_atto as 
  (
  select  atto.attoamm_anno::integer   movgest_attoamm_anno,
		     atto.attoamm_numero::integer movgest_attoamm_numero,
		     c.classif_code movgest_attoamm_sac,
		     tipo.attoamm_tipo_code movgest_attoamm_tipo_code,
		     ratto.movgest_ts_id
  from siac_r_movgest_ts_atto_amm  ratto, siac_d_atto_amm_tipo tipo ,
            siac_t_atto_amm atto 
                left join siac_r_atto_amm_class rc  
                        join siac_t_class c join siac_d_class_tipo tipo_c on ( tipo_c.classif_tipo_id=c.classif_tipo_id and tipo_c.classif_tipo_code in ('CDC','CDR') )
                                on (c.classif_id=rc.classif_id )
                        on ( atto.attoamm_id=rc.attoamm_id and  rc.data_cancellazione  is null and rc.validita_fine is null )         
  where tipo.ente_proprietario_id=p_ente_proprietario_id   
  and      atto.attoamm_tipo_id=tipo.attoamm_tipo_id 
  and      ratto.attoamm_id=atto.attoamm_id 
  and      ratto.data_cancellazione   is null 
  and      ratto.validita_fine  is null 
  ),
  movimento_gsa as 
  (
  select rattr.movgest_Ts_id 
  from siac_r_movgest_ts_Attr rattr,siac_t_attr attr 
  where attr.ente_proprietario_id =p_ente_proprietario_id 
  and     attr.attr_code='FlagAttivaGsa'
  and     rattr.attr_id=attr.attr_id
  and     rattr."boolean" ='S'
  and     rattr.data_cancellazione  is null 
  and     rattr.validita_fine is null 
  )
  select movimenti.*,
              movim_atto.movgest_attoamm_tipo_code ,
              movim_atto.movgest_attoamm_anno,
              movim_atto.movgest_attoamm_numero,
              movim_atto.movgest_attoamm_sac,
              (case when movimento_gsa.movgest_ts_id is not null then true else false end)::boolean movgest_gsa
  from movimenti 
             left join movim_atto on (movimenti.movgest_ts_id=movim_atto.movgest_ts_id )
             left join movimento_gsa on ( movimenti.movgest_ts_id=movimento_gsa.movgest_ts_id)
  )
 select det.*,
             mov.*
 from ord_dettagli det , ord_movimenti mov 
 where mov.ord_ts_id=det.ord_ts_id 
),
ord_soggetto as 
(
select rsog.ord_id, 
           sog.soggetto_code::integer soggetto_code ,
           sog.soggetto_desc
from siac_r_ordinativo_soggetto  rsog,siac_t_soggetto sog 
where sog.ente_proprietario_id =p_ente_proprietario_id 
and     rsog.soggetto_id=sog.soggetto_id 
and     rsog.data_cancellazione  is null 
and     rsog.validita_fine  is null 
--limit 1
),
ord_pdc_fin as 
(
select rc.ord_id, c.classif_code pdc_fin
from siac_r_ordinativo_class rc,siac_t_class c,siac_d_class_tipo tipo 
where tipo.ente_proprietario_id =p_ente_proprietario_id 
and     tipo.classif_tipo_code='PDC_V'
and     c.classif_tipo_id=tipo.classif_tipo_id 
and     rc.classif_id=c.classif_id 
and     rc.data_cancellazione  is null 
and     rc.validita_fine  is null 
--limit 1
),
pdc_fin_livelli as
(
select c.classif_code level_classif_code, query.classif_id level_classif_id, 
            query.level,
            query.ord_id
from 
(
WITH 
 RECURSIVE rqname(ord_id,classif_classif_fam_tree_id, classif_fam_tree_id, classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, level) 
 AS 
 (
                 SELECT 
                    rc.ord_id,
                    rtree.classif_classif_fam_tree_id,
                    rtree.classif_fam_tree_id,
                    rtree.classif_id,
                    rtree.classif_id_padre,
                    rtree.ente_proprietario_id,
                    rtree.ordine,
                    rtree.livello,
                    rtree.livello
                  from siac_t_class c,siac_d_class_tipo tipo ,siac_r_class_fam_tree  rtree,siac_r_ordinativo_class rc 
				  where tipo.ente_proprietario_id =p_ente_proprietario_id 
				  and     tipo.classif_tipo_code='PDC_V'
	              and     c.classif_tipo_id=tipo.classif_tipo_id 
				  and     rtree.classif_id =c.classif_id 
				  and    rc.classif_id=c.classif_id
	              and    rtree.data_cancellazione  is null 
	              and    rtree.validita_fine  is null
   	              and    rc.data_cancellazione  is null 
	              and    rc.validita_fine  is null
            UNION ALL
             SELECT 
                    tp.ord_id,
                    tn.classif_classif_fam_tree_id,
                    tn.classif_fam_tree_id,
                    tn.classif_id,
                    tn.classif_id_padre,
                    tn.ente_proprietario_id,
                    tn.ordine,
                    tn.livello,
                    tp.level - 1
                   FROM rqname tp,        siac_r_class_fam_tree tn
                  WHERE tp.classif_id_padre  = tn.classif_id 
                  AND tn.ente_proprietario_id = tp.ente_proprietario_id 
                  AND tn.data_cancellazione  is null 
                  and   tn.validita_fine  is null
    )
    SELECT 
            rqname.ord_id,
            rqname.classif_classif_fam_tree_id,
            rqname.classif_fam_tree_id,
            rqname.classif_id,
            rqname.classif_id_padre,
            rqname.ente_proprietario_id,
            rqname.ordine,
            rqname.livello,
            rqname.level
           FROM rqname
          ORDER BY rqname.level
 ) query,siac_t_class c
 where c.classif_id=query.classif_id 
),
ord_attoamm as 
(
select  atto.attoamm_anno::integer   ord_attoamm_anno,
		     atto.attoamm_numero::integer ord_attoamm_numero,
		     c.classif_code ord_attoamm_sac,
		     tipo.attoamm_tipo_code ord_attoamm_tipo_code,
		     ratto.ord_id
  from siac_r_ordinativo_atto_amm  ratto, siac_d_atto_amm_tipo tipo ,
            siac_t_atto_amm atto 
                left join siac_r_atto_amm_class rc  
                        join siac_t_class c join siac_d_class_tipo tipo_c on ( tipo_c.classif_tipo_id=c.classif_tipo_id and tipo_c.classif_tipo_code in ('CDC','CDR') )
                                on (c.classif_id=rc.classif_id ) 
                        on ( atto.attoamm_id=rc.attoamm_id and  rc.data_cancellazione  is null and rc.validita_fine is null )         
  where tipo.ente_proprietario_id= p_ente_proprietario_id   
  and      atto.attoamm_tipo_id=tipo.attoamm_tipo_id 
  and      ratto.attoamm_id=atto.attoamm_id 
  and      ratto.data_cancellazione   is null 
  and      ratto.validita_fine  is null 
--  limit 1
)
select 
    ordinativo.ente_proprietario_id,
	ordinativo.anno_bilancio,
	ordinativo.ord_anno,
	ordinativo.ord_numero,
	ordinativo.ord_desc,
	ordinativo.ord_stato_code,
	ordinativo.ord_data_emissione,
	ord_firma.ord_data_firma,
	ord_quietanza.ord_data_quietanza,
	(case when ordinativo.ord_stato_code='A' then ordinativo.data_inizio_val_stato_ord else null end ) 	ord_data_annullo,
    ord_capitolo.numero_capitolo,
    ord_capitolo.numero_articolo,
    ord_capitolo.capitolo_desc,
    ord_soggetto.soggetto_code,
    ord_soggetto.soggetto_desc,
--    pdc_fin_liv_5.pdc_fin pdc_fin_liv_5,
--    pdc_fin_liv_4.level_classif_code  pdc_fin_liv_4,
--    pdc_fin_liv_3.level_classif_code  pdc_fin_liv_3,
--    pdc_fin_liv_2.level_classif_code  pdc_fin_liv_2,
--    pdc_fin_liv_1.level_classif_code  pdc_fin_liv_1,
    -- 26.04.2023 Sofia SIAC-TASK-82 - inizio 
    split_part(substring(pdc_fin_liv_5.pdc_fin,3+2+3+3+3,3),'.',1) pdc_fin_liv_5,
    split_part(substring( pdc_fin_liv_4.level_classif_code,3+2+3+3,2),'.',1) pdc_fin_liv_4,
    split_part(substring(pdc_fin_liv_3.level_classif_code,3+2+3,2),'.',1) pdc_fin_liv_3,
    split_part(substring(pdc_fin_liv_2.level_classif_code,3+2,2),'.',1) pdc_fin_liv_2,
    split_part(substring(pdc_fin_liv_1.level_classif_code,3,1),'.',1)  pdc_fin_liv_1,
    -- 26.04.2023 Sofia SIAC-TASK-82 - fine     
	ord_sub.ord_sub_numero, 
	ord_sub.ord_sub_importo,
	ord_sub.ord_sub_desc,
    ord_sub.movgest_anno,
    ord_sub.movgest_numero,
    ord_sub.movgest_sub_numero,
    ord_sub.movgest_attoamm_tipo_code,
    ord_sub.movgest_attoamm_anno,
    ord_sub.movgest_attoamm_numero,
    ord_sub.movgest_attoamm_sac,
    ord_attoamm.ord_attoamm_tipo_code,
    ord_attoamm.ord_attoamm_anno,
    ord_attoamm.ord_attoamm_numero,
    ord_attoamm.ord_attoamm_sac,
    ord_sub.movgest_gsa
from ord_sub, ord_capitolo,
           ordinativo 
            left join ord_quietanza   on (ordinativo.ord_id=ord_quietanza.ord_id )
            left join ord_firma          on (ordinativo.ord_id=ord_firma.ord_id)
            left join ord_soggetto     on (ordinativo.ord_id=ord_soggetto.ord_id)
            left join ord_attoamm   on (ordinativo.ord_id=ord_attoamm.ord_id)
            left join ord_pdc_fin  pdc_fin_liv_5    on (ordinativo.ord_id=pdc_fin_liv_5.ord_id)
            left join pdc_fin_livelli pdc_fin_liv_4 on (pdc_fin_liv_4.ord_id=ordinativo.ord_id and pdc_fin_liv_4.level=4)
            left join pdc_fin_livelli pdc_fin_liv_3 on (pdc_fin_liv_3.ord_id=ordinativo.ord_id and pdc_fin_liv_3.level=3)
            left join pdc_fin_livelli pdc_fin_liv_2 on (pdc_fin_liv_2.ord_id=ordinativo.ord_id and pdc_fin_liv_2.level=2)
            left join pdc_fin_livelli pdc_fin_liv_1 on (pdc_fin_liv_1.ord_id=ordinativo.ord_id and pdc_fin_liv_1.level=1)
            
where ordinativo.ord_id=ord_capitolo.ord_id 
and      ordinativo.ord_id=ord_sub.ord_id
)  ord_gsa;


esito:= '  Fine caricamento dati into siac_gsa_ordinativo_incasso  - '||clock_timestamp();
return next;
insert into
siac_gsa_ordinativi_log_elab 
(
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values 
(
p_ente_proprietario_id,
'fnc_siac_gsa_ordinativo_incasso',
esito,
clock_timestamp(),
v_user_table
);

esito:= 'Fine funzione carico ordinativi  incasso GSA (fnc_siac_gsa_ordinativo_incasso) - '||clock_timestamp();
RETURN NEXT;
insert into
siac_gsa_ordinativi_log_elab 
(
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values 
(
p_ente_proprietario_id,
'fnc_siac_gsa_ordinativo_incasso',
esito,
clock_timestamp(),
v_user_table
);

 
update siac_gsa_ordinativi_log_elab  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()- fnc_elaborazione_inizio
where fnc_user=v_user_table;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico ordinativi  incasso GSA (fnc_siac_gsa_ordinativo_incasso) terminata con errori '||sqlstate||'-'||SQLERRM;
  raise notice 'esito=%',esito;
--  RAISE NOTICE '% %-%.',esito, SQLSTATE,SQLERRM;
  return next;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

alter function  siac.fnc_siac_gsa_ordinativo_incasso (  varchar, integer, timestamp) owner to siac;
