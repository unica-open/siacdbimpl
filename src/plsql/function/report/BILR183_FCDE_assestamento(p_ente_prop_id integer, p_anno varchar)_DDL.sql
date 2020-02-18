/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac."BILR183_FCDE_assestamento" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titolo_id integer,
  code_titolo varchar,
  desc_titolo varchar,
  tipologia_id integer,
  code_tipologia varchar,
  desc_tipologia varchar,
  categoria_id integer,
  code_categoria varchar,
  desc_categoria varchar,
  elem_id integer,
  capitolo_prev varchar,
  elem_desc varchar,
  flag_acc_cassa varchar,
  pdce_code varchar,
  perc_delta numeric,
  imp_stanziamento_comp numeric,
  imp_accertamento_comp numeric,
  imp_reversale_comp numeric,
  percaccantonamento numeric
) AS
$body$
DECLARE

bilancio_id integer;
anno_int integer;
flagAccantGrad varchar;
RTN_MESSAGGIO text;
BEGIN
RTN_MESSAGGIO:='select 1';

anno_int:= p_anno::integer;

select a.bil_id
into  bilancio_id
from  siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id
and   b.periodo_id = a.periodo_id
and   b.anno = p_anno;

select attr_bilancio."boolean"
into flagAccantGrad
from siac_r_bil_attr attr_bilancio, siac_t_attr attr
where attr_bilancio.bil_id = bilancio_id
and   attr_bilancio.attr_id = attr.attr_id
and   attr.attr_code = 'accantonamentoGraduale'
and   attr_bilancio.data_cancellazione is null
and   attr_bilancio.ente_proprietario_id = p_ente_prop_id;


if flagAccantGrad = 'N' then
    percAccantonamento = 100;
else
    select COALESCE(attr_bilancio.numerico, 0)
    into percAccantonamento
    from siac_r_bil_attr attr_bilancio, siac_t_attr attr
    where attr_bilancio.bil_id = bilancio_id
    and attr_bilancio.attr_id = attr.attr_id
    and attr.attr_code = 'percentualeAccantonamentoAnno'
    and attr_bilancio.data_cancellazione is null
    and attr_bilancio.ente_proprietario_id = p_ente_prop_id;
end if;

return query
select zz.* from (
with strut_bilancio as(
select  *
from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno, null)),
capitoli as(
select cl.classif_id categoria_id,
anno_eserc.anno anno_bilancio,
e.elem_id,
e.elem_code||'/'||e.elem_code2||'/'||e.elem_code3 capitolo_prev,
e.elem_desc,
r_bil_elem_dubbia_esig.acc_fde_id
from  siac_r_bil_elem_class rc,
      siac_t_bil_elem e,
      siac_d_class_tipo ct,
      siac_t_class cl,
      siac_t_bil bilancio,
      siac_t_periodo anno_eserc,
      siac_d_bil_elem_tipo tipo_elemento,
      siac_d_bil_elem_stato stato_capitolo,
      siac_r_bil_elem_stato r_capitolo_stato,
      siac_d_bil_elem_categoria cat_del_capitolo,
      siac_r_bil_elem_categoria r_cat_capitolo,
      siac_r_bil_elem_acc_fondi_dubbia_esig r_bil_elem_dubbia_esig
where ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id
and bilancio.periodo_id				=	anno_eserc.periodo_id
and e.bil_id						=	bilancio.bil_id
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id
and e.elem_id						=	rc.elem_id
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and r_bil_elem_dubbia_esig.elem_id  =   e.elem_id
and e.ente_proprietario_id			=	p_ente_prop_id
and e.bil_id                        =   bilancio_id
and tipo_elemento.elem_tipo_code 	= 	'CAP-EP'
and	stato_capitolo.elem_stato_code	=	'VA'
and ct.classif_tipo_code			=	'CATEGORIA'
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	rc.data_cancellazione				is null
and	ct.data_cancellazione 				is null
and	cl.data_cancellazione 				is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
and r_bil_elem_dubbia_esig.data_cancellazione is null
-- and now() between rc.validita_inizio and COALESCE(rc.validita_fine,now())
-- and now() between r_cat_capitolo.validita_inizio and COALESCE(r_cat_capitolo.validita_fine,now())
),
conto_pdce as(
select t_class_upb.classif_code, r_capitolo_upb.elem_id
from
    siac_d_class_tipo	class_upb,
    siac_t_class		t_class_upb,
    siac_r_bil_elem_class r_capitolo_upb
where
    t_class_upb.classif_tipo_id = class_upb.classif_tipo_id
    and t_class_upb.classif_id = r_capitolo_upb.classif_id
    and t_class_upb.ente_proprietario_id = p_ente_prop_id
    and class_upb.classif_tipo_code like 'PDC_%'
    and	class_upb.data_cancellazione 			is null
    and t_class_upb.data_cancellazione 			is null
    and r_capitolo_upb.data_cancellazione 			is null
),
flag_acc_cassa as (
select rbea."boolean", rbea.elem_id
from   siac_r_bil_elem_attr rbea, siac_t_attr ta
where  rbea.attr_id = ta.attr_id
and    rbea.data_cancellazione is null
and    ta.data_cancellazione is null
and    ta.attr_code = 'FlagAccertatoPerCassa'
and    ta.ente_proprietario_id = p_ente_prop_id
),
fondo  as (
select fondi_dubbia_esig.acc_fde_id, fondi_dubbia_esig.perc_delta
from   siac_t_acc_fondi_dubbia_esig fondi_dubbia_esig
where  fondi_dubbia_esig.ente_proprietario_id = p_ente_prop_id
and    fondi_dubbia_esig.data_cancellazione is null
),
stanziamento_comp as (
select 	capitolo.elem_code||'/'||capitolo.elem_code2||'/'||capitolo.elem_code3 capitolo_rend,
        sum(capitolo_importi.elem_det_importo) imp_stanziamento_comp
from 	siac_t_bil_elem_det capitolo_importi,
        siac_d_bil_elem_det_tipo capitolo_imp_tipo,
        siac_t_periodo capitolo_imp_periodo,
        siac_t_bil_elem capitolo,
        siac_d_bil_elem_tipo tipo_elemento,
        siac_t_bil bilancio,
        siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
        siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where 	bilancio.periodo_id				=	capitolo_imp_periodo.periodo_id
and	capitolo.bil_id						=	bilancio_id
and	capitolo.elem_id					=	capitolo_importi.elem_id
and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id
and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id
and	capitolo.elem_id					=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
and	capitolo.elem_id					=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
and capitolo_importi.ente_proprietario_id = p_ente_prop_id
and	tipo_elemento.elem_tipo_code 		= 	'CAP-EG'
and	stato_capitolo.elem_stato_code		=	'VA'
and	capitolo_imp_periodo.anno           = 	p_anno
and	cat_del_capitolo.elem_cat_code		=	'STD'
and capitolo_imp_tipo.elem_det_tipo_code  = 'STA'
and	capitolo_importi.data_cancellazione 	is null
and	capitolo_imp_tipo.data_cancellazione 	is null
and	capitolo_imp_periodo.data_cancellazione is null
and	capitolo.data_cancellazione 			is null
and	tipo_elemento.data_cancellazione 		is null
and	bilancio.data_cancellazione 			is null
and	stato_capitolo.data_cancellazione 		is null
and	r_capitolo_stato.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione 	is null
and	r_cat_capitolo.data_cancellazione 		is null
group by capitolo.elem_code||'/'||capitolo.elem_code2||'/'||capitolo.elem_code3
),
accertamento_comp as (
select capitolo.elem_code||'/'||capitolo.elem_code2||'/'||capitolo.elem_code3 capitolo_rend,
       sum (dt_movimento.movgest_ts_det_importo) imp_accertamento_comp
from   siac_t_bil_elem     capitolo ,
       siac_r_movgest_bil_elem   r_mov_capitolo,
       siac_d_bil_elem_tipo    t_capitolo,
       siac_t_movgest     movimento,
       siac_d_movgest_tipo    tipo_mov,
       siac_t_movgest_ts    ts_movimento,
       siac_r_movgest_ts_stato   r_movimento_stato,
       siac_d_movgest_stato    tipo_stato,
       siac_t_movgest_ts_det   dt_movimento,
       siac_d_movgest_ts_tipo   ts_mov_tipo,
       siac_d_movgest_ts_det_tipo  dt_mov_tipo
where capitolo.elem_tipo_id      		= t_capitolo.elem_tipo_id
and r_mov_capitolo.elem_id    		    = capitolo.elem_id
and r_mov_capitolo.movgest_id    		= movimento.movgest_id
and movimento.movgest_tipo_id    		= tipo_mov.movgest_tipo_id
and movimento.movgest_id      		    = ts_movimento.movgest_id
and ts_movimento.movgest_ts_id    	    = r_movimento_stato.movgest_ts_id
and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id
and ts_movimento.movgest_ts_tipo_id     = ts_mov_tipo.movgest_ts_tipo_id
and ts_movimento.movgest_ts_id    	    = dt_movimento.movgest_ts_id
and dt_movimento.movgest_ts_det_tipo_id = dt_mov_tipo.movgest_ts_det_tipo_id
and movimento.ente_proprietario_id      = p_ente_prop_id
and t_capitolo.elem_tipo_code    		= 'CAP-EG'
and movimento.movgest_anno              = anno_int
and movimento.bil_id                    = bilancio_id
and capitolo.bil_id     				= bilancio_id
and tipo_mov.movgest_tipo_code    	    = 'A'
and tipo_stato.movgest_stato_code       in ('D','N')
and ts_mov_tipo.movgest_ts_tipo_code    = 'T'
and dt_mov_tipo.movgest_ts_det_tipo_code = 'A'
and now()
  between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
and now()
  between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
and capitolo.data_cancellazione     	is null
and r_mov_capitolo.data_cancellazione is null
and t_capitolo.data_cancellazione    	is null
and movimento.data_cancellazione     	is null
and tipo_mov.data_cancellazione     	is null
and r_movimento_stato.data_cancellazione   is null
and ts_movimento.data_cancellazione   is null
and tipo_stato.data_cancellazione    	is null
and dt_movimento.data_cancellazione   is null
and ts_mov_tipo.data_cancellazione    is null
and dt_mov_tipo.data_cancellazione    is null
group by capitolo.elem_code||'/'||capitolo.elem_code2||'/'||capitolo.elem_code3
),
reversale_comp as (
select capitolo.elem_code||'/'||capitolo.elem_code2||'/'||capitolo.elem_code3 capitolo_rend,
       sum (t_ord_ts_det.ord_ts_det_importo) imp_reversale_comp
from   siac_t_bil_elem     capitolo ,
       siac_r_ordinativo_bil_elem   r_ord_capitolo,
       siac_d_bil_elem_tipo    t_capitolo,
       siac_t_ordinativo t_ordinativo,
       siac_t_ordinativo_ts t_ord_ts,
       siac_t_ordinativo_ts_det t_ord_ts_det,
       siac_d_ordinativo_ts_det_tipo d_ts_det_tipo,
       siac_r_ordinativo_stato r_ord_stato,
       siac_d_ordinativo_stato d_ord_stato,
       siac_d_ordinativo_tipo d_ord_tipo,
-- ST SIAC-6291 inserita condizione per movimento di competenza: tavole
       siac_r_ordinativo_ts_movgest_ts    r_ord_mov,
       siac_t_movgest     movimento,
       siac_t_movgest_ts    ts_movimento
where capitolo.elem_tipo_id      		 = t_capitolo.elem_tipo_id
and   r_ord_capitolo.elem_id    		 = capitolo.elem_id
and   t_ordinativo.ord_id                = r_ord_capitolo.ord_id
and   t_ordinativo.ord_id                = t_ord_ts.ord_id
and   t_ord_ts.ord_ts_id                 = t_ord_ts_det.ord_ts_id
and   t_ordinativo.ord_id                = r_ord_stato.ord_id
and   r_ord_stato.ord_stato_id           = d_ord_stato.ord_stato_id
and   d_ord_tipo.ord_tipo_id             = t_ordinativo.ord_tipo_id
AND   d_ts_det_tipo.ord_ts_det_tipo_id   = t_ord_ts_det.ord_ts_det_tipo_id
and   t_ordinativo.ente_proprietario_id  = p_ente_prop_id
--ST SIAC-6291 condizione per movimento di competenza: Join
and   movimento.movgest_id      		 = ts_movimento.movgest_id
and   r_ord_mov.movgest_ts_id      		 = ts_movimento.movgest_ts_id
and   r_ord_mov.ord_ts_id                = t_ord_ts.ord_ts_id
--
and   t_capitolo.elem_tipo_code    		 =  'CAP-EG'
and   t_ordinativo.ord_anno              = anno_int
and   capitolo.bil_id                    = bilancio_id
and   t_ordinativo.bil_id                = bilancio_id
and   d_ord_stato.ord_stato_code         <>'A'
and   d_ord_tipo.ord_tipo_code           = 'I'
and   d_ts_det_tipo.ord_ts_det_tipo_code = 'A'
and   capitolo.data_cancellazione     	is null
and   r_ord_capitolo.data_cancellazione     	is null
and   t_capitolo.data_cancellazione     	is null
and   t_ordinativo.data_cancellazione     	is null
and   t_ord_ts.data_cancellazione     	is null
and   t_ord_ts_det.data_cancellazione     	is null
and   d_ts_det_tipo.data_cancellazione     	is null
and   r_ord_stato.data_cancellazione     	is null
and   r_ord_stato.validita_fine is null -- S.T. SIACC-6280
and   d_ord_stato.data_cancellazione     	is null
and   d_ord_tipo.data_cancellazione     	is null
-- ST SIAC-6291 condizione per movimento di competenza
and   r_ord_mov.data_cancellazione      is null
and movimento.movgest_anno              = anno_int
--
group by capitolo.elem_code||'/'||capitolo.elem_code2||'/'||capitolo.elem_code3
)
select
p_anno,
strut_bilancio.titolo_id::integer titolo_id,
strut_bilancio.titolo_code::varchar code_titolo,
strut_bilancio.titolo_desc::varchar desc_titolo,
strut_bilancio.tipologia_id::integer tipologia_id,
strut_bilancio.tipologia_code::varchar code_tipologia,
strut_bilancio.tipologia_desc::varchar desc_tipologia,
strut_bilancio.categoria_id::integer categoria_id,
strut_bilancio.categoria_code::varchar code_categoria,
strut_bilancio.categoria_desc::varchar desc_categoria,
capitoli.elem_id::integer elem_id,
capitoli.capitolo_prev::varchar capitolo_prev,
capitoli.elem_desc::varchar elem_desc,
COALESCE(flag_acc_cassa."boolean", 'N')::varchar flag_acc_cassa,
conto_pdce.classif_code::varchar pdce_code,
COALESCE(fondo.perc_delta,0)::numeric perc_delta,
COALESCE(stanziamento_comp.imp_stanziamento_comp,0)::numeric imp_stanziamento_comp,
COALESCE(accertamento_comp.imp_accertamento_comp,0)::numeric imp_accertamento_comp,
COALESCE(reversale_comp.imp_reversale_comp,0)::numeric imp_reversale_comp,
percAccantonamento::numeric
from strut_bilancio
inner join capitoli on strut_bilancio.categoria_id = capitoli.categoria_id
inner join conto_pdce on conto_pdce.elem_id = capitoli.elem_id
left join  fondo on fondo.acc_fde_id = capitoli.acc_fde_id
left join  flag_acc_cassa on flag_acc_cassa.elem_id = capitoli.elem_id
left join  stanziamento_comp on stanziamento_comp.capitolo_rend = capitoli.capitolo_prev
left join  accertamento_comp on accertamento_comp.capitolo_rend = capitoli.capitolo_prev
left join  reversale_comp on reversale_comp.capitolo_rend = capitoli.capitolo_prev
) as zz;

exception
when no_data_found THEN
raise notice 'nessun dato trovato per struttura bilancio';
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