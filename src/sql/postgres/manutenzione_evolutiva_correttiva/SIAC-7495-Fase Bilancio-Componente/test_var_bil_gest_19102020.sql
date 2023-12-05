/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


rollback;
begin;

do $$declare

elencoVar text:='';
annoBilancio integer:=null;
enteProprietarioId integer:=null;
rec record;
recResult record;
nomeTabella varchar:=null;
flagCambiaStato varchar:=null;
flagApplicaVar  varchar:=null;
statoVar        varchar:=null;
insertSql varchar:=null;
codResult integer:=null;
begin

--nomeTabella:='pippo_table';
for rec in
(select var.variazione_num ,anno.anno_bilancio,var.ente_proprietario_id
 from siac_t_variazione var,siac_r_variazione_stato rs,siac_d_variazione_stato stato,
      siac_v_bko_anno_bilancio anno
 where stato.ente_proprietario_id=2
 --and   stato.variazione_Stato_tipo_code='B'
 and   rs.variazione_Stato_tipo_id=stato.variazione_Stato_tipo_id
 and   var.variazione_id=rs.variazione_id
 and   anno.bil_id=var.bil_id
 and   anno.anno_bilancio=2020
 and   var.variazione_num in (74)
 and   rs.data_cancellazione is null
 and   rs.validita_fine is null
 order by rs.validita_inizio
 )
 loop
 --raise notice 'var_num=%',rec.variazione_num;
 if coalesce(elencoVar,'')!=''  then elencoVar:=elencoVar||','; end if;
 elencoVar:=elencovar||rec.variazione_num::varchar;

 if nometabella is not null then
   insertSql:='insert into '||nomeTabella||' (variazione_num) values ('||rec.variazione_num::varchar||')';
   execute insertSql;
 end if;

 if enteProprietarioId is null then
 	annoBilancio:=rec.anno_bilancio;
    enteProprietarioId:=rec.ente_proprietario_id;
 end if;
 end loop;

 --elencoVar:=null;
 raise notice 'elencoVar=%',elencoVar;
 nomeTabella:=null;
 raise notice 'nomeTabella=%', nomeTabella;
 if nomeTabella is not null then
   insertSql:='select count(*) from '||nomeTabella;
   execute insertSql into codResult;
   raise notice 'count=%',codResult;
 end if;
 flagCambiaStato:='0';
 flagApplicaVar:='1';
 statoVar:='D';
 select
 fnc_fasi_bil_variazione_gest
 (
  annoBilancio::varchar,
  elencoVar,
  nomeTabella,
  flagCambiaStato,   -- [1,0],[true,false]
  flagApplicaVar,    -- [1,0],[true,false]
  statoVar,
  enteProprietarioId::varchar,
  'test-job',
  now()::TIMESTAMP
 ) into recResult;
 if nomeTabella is not null then
   insertSql:='delete from '||nomeTabella;
   execute insertSql;
 end if;
end$$;

create table pippo_table
(
variazione_num integer
)
select * from pippo_table
delete from pippo_table
/*select *
from fase_bil_t_elaborazione fase
where fase.ente_proprietario_id=2
order by fase.fase_bil_elab_id desc

select *
from fase_bil_t_variazione_gest fase where fase.fase_bil_elab_id=498*/

Gestione variazione 185/2020. others - COLUMN "ATTOAMM_VARBIL_ID" OF RELATION "SIAC_R_VARIAZIONE_STATO" DOES NOT EXIST
select var.variazione_num ,anno.anno_bilancio,var.ente_proprietario_id, stato.variazione_stato_tipo_code,
       rs.*
 from siac_t_variazione var,siac_r_variazione_stato rs,siac_d_variazione_stato stato,
      siac_v_bko_anno_bilancio anno
 where stato.ente_proprietario_id=2
 --and   stato.variazione_Stato_tipo_code='B'
 and   rs.variazione_Stato_tipo_id=stato.variazione_Stato_tipo_id
 and   var.variazione_id=rs.variazione_id
 and   anno.bil_id=var.bil_id
 and   anno.anno_bilancio=2020
 and   var.variazione_num::integer in (113,117)
 and   rs.data_cancellazione is null
 and   rs.validita_fine is null
 order by rs.validita_inizio
select var.variazione_num::integer variazione_num, var.variazione_id, rs.variazione_stato_id,  bil.bil_id,per.anno::integer anno, stato.variazione_stato_tipo_code, stato.variazione_stato_tipo_id  from siac_t_variazione var,siac_r_variazione_stato rs,siac_d_variazione_stato stato ,  siac_t_bil bil,siac_t_periodo per  where stato.ente_proprietario_id=2 and   stato.variazione_stato_tipo_code!='A'  and   rs.variazione_stato_tipo_id=stato.variazione_stato_tipo_id and   var.variazione_id=rs.variazione_id  and   bil.bil_id=var.bil_id and per.periodo_id=bil.periodo_Id and   per.anno::integer=2020 and   var.variazione_num in (74) and   rs.data_cancellazione is null and rs.validita_fine is null  order by rs.validita_inizio, var.variazione_num::integer
7422
7423
7426
7427
begin;
select
(fnc_siac_bko_gestisci_variazione
(
  2,
  2020,
  74,
  true,
  'B',
  false,
  'test',
  now()::timestamp
)).*

 select var.variazione_num ,anno.anno_bilancio,var.ente_proprietario_id,stato.variazione_stato_tipo_code,
        rs.attoamm_id,
        dvar.*
 from siac_t_variazione var,siac_r_variazione_stato rs,siac_d_variazione_stato stato,
      siac_v_bko_anno_bilancio anno,siac_t_bil_elem_det_var dvar
 where stato.ente_proprietario_id=2
-- and   stato.variazione_Stato_tipo_code='B'
 and   rs.variazione_Stato_tipo_id=stato.variazione_Stato_tipo_id
 and   var.variazione_id=rs.variazione_id
 and   anno.bil_id=var.bil_id
 and   anno.anno_bilancio=2020
 and   dvar.variazione_stato_id=rs.variazione_stato_id
 and   var.variazione_num::integer in (113,117)
 and   rs.data_cancellazione is null
 and   rs.validita_fine is null
 and   dvar.data_cancellazione is null
 order by rs.validita_inizio

 rollback;
begin;
 select
 fnc_fasi_bil_variazione_gest
 (
  '2020',
  '76'::text,
  null,
  '1', -- [1,0],[true,false]
  '0',  -- [1,0],[true,false]
  'P',
  2,
  'batch',
  NOW()::timestamp
)