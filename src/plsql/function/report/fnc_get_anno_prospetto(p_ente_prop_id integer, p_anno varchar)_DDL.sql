/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_get_anno_prospetto (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  anno_prospetto varchar
) AS
$body$
DECLARE

anno_bilancio integer;
v_anno_prospetto integer;

BEGIN

anno_bilancio := p_anno::integer;

FOR counter IN 1..3 LOOP

  select
/*        case 
         when fase_operativa.fase_operativa_code = 'P' then
              anno_bilancio-1
         else
              anno_bilancio
        end anno_prospetto*/
        anno_bilancio as anno_prospetto
  into  v_anno_prospetto                   
  from  siac_d_fase_operativa fase_operativa, 
        siac_r_bil_fase_operativa bil_fase_operativa, 
        siac_t_bil bil, 
        siac_t_periodo periodo
  where fase_operativa.fase_operativa_id = bil_fase_operativa.fase_operativa_id
  and   bil_fase_operativa.bil_id = bil.bil_id
  and   periodo.periodo_id = bil.periodo_id
  and   fase_operativa.fase_operativa_code in ('P','E','G') -- SIAC-5778 Aggiunto G
  and   bil.ente_proprietario_id = p_ente_prop_id
  and   periodo.anno = p_anno
  and   fase_operativa.data_cancellazione is null
  and   bil_fase_operativa.data_cancellazione is null 
  and   bil.data_cancellazione is null 
  and   periodo.data_cancellazione is null;
 
  anno_prospetto := v_anno_prospetto::varchar;
  anno_bilancio  := anno_bilancio + 1;
  
  return next; 

END LOOP;
  
EXCEPTION
  when others  THEN
  RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(SQLERRM from 1 for 500);
  return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;