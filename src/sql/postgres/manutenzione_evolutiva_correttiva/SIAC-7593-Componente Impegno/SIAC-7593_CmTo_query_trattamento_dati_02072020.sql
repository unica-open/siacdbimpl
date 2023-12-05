/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/*select tipo.*
from siac_d_bil_elem_det_comp_tipo tipo
where tipo.ente_proprietario_id=3*/

select query_ext.*
from
(
select
       query.anno_impegno,
       query.numero_impegno,
       query.numero_subimpegno,
       query.componente_impegno_tipo,
       comp.elem_det_comp_tipo_desc,
       query.impegno_da_ror,
       query.impegno_da_reanno,
       query.avav_tipo_code,
       query.avav_tipo_desc,
       query.accertamento_anno,
       query.accertamento_numero,
       query.accertamento_subnumero,
       query.movgest_ts_importo,
       query.movgest_ts_r_id,
       ( select ( case when coalesce(count(*),0)!=0 then 'S' else 'N' end ) multi_vinc
   	     from siac_r_movgest_ts rvinc
	     where rvinc.movgest_ts_b_id=query.movgest_ts_id
	     and   rvinc.movgest_ts_r_id!=query.movgest_ts_r_id
		 and   rvinc.data_cancellazione is null
	     and  rvinc.validita_fine is null
       ) multi_vincolo
--       ( case when coalesce(rvinc.movgest_ts_r_id::varchar,'N')='N' then 'N' else 'S' end ) multi_vincolo
from
(
with
impegno as
(
select imp.movgest_anno, imp.movgest_numero,imp.movgest_subnumero,
       imp.movgest_ts_id,
       coalesce(rattr.boolean,'N')       impegno_da_ror,
       coalesce(rattrReanno.boolean,'N') impegno_da_reanno,
       imp.ente_proprietario_id
from siac_v_bko_Impegno_valido imp
     left join siac_r_movgest_ts_attr rattr
               join  siac_t_attr attr on ( attr.attr_id=rattr.attr_id and attr.attr_code='flagDaRiaccertamento' )
          on ( rattr.movgest_ts_id=imp.movgest_ts_id and rattr.data_cancellazione is null and rattr.validita_fine  is null )
	 left join siac_r_movgest_ts_attr rattrReanno
                join siac_t_attr attrReanno on (attrReanno.attr_id=rattrReanno.attr_id and attrReanno.attr_code='flagDaReanno')
		  on ( rattrReanno.movgest_ts_id=imp.movgest_ts_id and rattrReanno.data_cancellazione is null and rattrReanno.validita_fine  is null )
where imp.ente_proprietario_id=3
and   imp.anno_bilancio=2020
and   imp.movgest_subnumero=0
),
vincolo as
(
with
avanzo as
(
select tipo.avav_tipo_code,
       r.movgest_ts_b_id,
       tipo.avav_tipo_desc,
       null::integer  accertamento_anno,
       null::integer  accertamento_numero,
       null::integer  accertamento_subnumero,
       r.movgest_ts_importo,
       avav.avav_id,
       null::integer movgest_ts_a_id,
       r.movgest_ts_r_id
from siac_t_avanzovincolo avav,siac_d_avanzovincolo_tipo tipo,
     siac_r_movgest_ts r
where tipo.ente_proprietario_id=3
and   avav.avav_tipo_id=tipo.avav_tipo_Id
and   extract ( year from avav.validita_inizio)::integer=2020
and   tipo.avav_tipo_Code in ('AAM','FPVSC','FPVCC')
and   r.avav_id=avav.avav_id
and   r.data_Cancellazione is null
and   r.validita_fine is null
and   avav.data_Cancellazione is null
and   avav.validita_fine is null
),
accertamento as
(
select 'ACC'::varchar avav_tipo_code,
       r.movgest_ts_b_id,
       null::varchar avav_tipo_desc,
       imp.movgest_anno accertamento_anno,
       imp.movgest_numero accertamento_numero,
       imp.movgest_subnumero accertamento_subnumero,
       r.movgest_ts_importo,
       null::integer avav_id,
       r.movgest_ts_a_id,
       r.movgest_ts_r_id
from siac_v_bko_accertamento_valido imp,
     siac_r_movgest_ts r
where imp.ente_proprietario_id=3
and   imp.anno_bilancio=2020
and   r.movgest_ts_a_id=imp.movgest_ts_id
and   r.data_Cancellazione is null
and   r.validita_fine is null
)
select  *
from avanzo
union
select *
from accertamento
)
select impegno.movgest_anno anno_impegno,
       impegno.movgest_numero numero_impegno,
       impegno.movgest_subnumero numero_subimpegno,
       impegno.movgest_ts_id,
       (case
        --  (A)	Verrà utilizzata la componente Fresco per gli impegni vincolati ad accertamenti della medesima annualità.
        --  Acc. competenza Fresco
             when coalesce(vincolo.avav_tipo_code,'')!='' and coalesce(vincolo.avav_tipo_code,'')='ACC'
              and impegno.movgest_anno=vincolo.accertamento_anno then 'parte fresca'
        -- (B)	Verrà utilizzata la componente FPV da ROR per gli impegni vincolati a FPV
		--      o ad accertamenti di annualità antecedenti con flag “da riaccertamento” a sì.
        -- Riaccertamento S, FPV o acc < imp
            when impegno.impegno_da_ror='S'
            and  coalesce(vincolo.avav_tipo_code,'')!=''
            and  ( coalesce(vincolo.avav_tipo_code,'') like 'FPV%'
             or   ( coalesce(vincolo.avav_tipo_code,'')='ACC' and vincolo.accertamento_anno<impegno.movgest_anno )
             	 )  then 'finanziata da FPV da ROR'
        -- (C)	Verrà utilizzata la componente FPV per gli impegni vincolati a FPV o
        --      ad accertamenti di annualità antecedenti con il flag “da riaccertamento” a no.
        -- Riaccertamento N , FPV o acc < imp
            when impegno.impegno_da_ror='N'
            and  coalesce(vincolo.avav_tipo_code,'')!=''
            and  ( coalesce(vincolo.avav_tipo_code,'') like 'FPV%'
             or   ( coalesce(vincolo.avav_tipo_code,'')='ACC' and vincolo.accertamento_anno<impegno.movgest_anno )
             	 ) then 'finanziata da FPV non ROR'
        -- (D) Verrà utilizzata la componente Avanzo per gli impegni vincolati a AAM.
        --  AAM
             when coalesce(vincolo.avav_tipo_code,'')!=''
             and  coalesce(vincolo.avav_tipo_code,'')='AAM' then 'finanziata da AVANZO'
        --  (E)
            when impegno.impegno_da_ror='S'
            and  coalesce(vincolo.avav_tipo_code,'')=''
                 then 'ROR NO VINCOLO'
        --  (F)
            when impegno.impegno_da_ror='N'
             and  coalesce(vincolo.avav_tipo_code,'')=''
                 then 'NO ROR NO VINCOLO'
        end ) componente_impegno_tipo,
        impegno.impegno_da_ror,
        impegno.impegno_da_reanno,
        vincolo.avav_tipo_code,
        vincolo.avav_tipo_desc,
        vincolo.accertamento_anno,
        vincolo.accertamento_numero,
        vincolo.accertamento_subnumero,
        vincolo.movgest_ts_importo,
        impegno.ente_proprietario_Id,
        vincolo.movgest_ts_r_id
from impegno
     left join vincolo       on (impegno.movgest_ts_id=vincolo.movgest_ts_b_id)
) query
  left join  siac_d_bil_elem_det_comp_tipo comp
    on (comp.ente_proprietario_id=query.ente_proprietario_id
    and ( case when query.componente_impegno_tipo='parte fresca' then comp.elem_det_comp_tipo_desc='NUOVA RICHIESTA'
    	       when query.componente_impegno_tipo like '%FPV%'    then comp.elem_det_comp_tipo_desc='FPV APPLICATO'
          else comp.elem_det_comp_tipo_desc=query.componente_impegno_tipo end )
    and comp.data_cancellazione is  null )
  ) query_ext
--here query_ext.elem_det_comp_tipo_desc is not null
order by 1,2,3,4;

