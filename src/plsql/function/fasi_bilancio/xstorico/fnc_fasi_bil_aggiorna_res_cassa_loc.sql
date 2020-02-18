/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_fasi_bil_cap_aggiorna_res_cassa (
   p_elem_tipo_code       varchar--  'CAP-UP'
  ,p_elem_tipo_code_prev  varchar--  'CAP-UP'
  ,p_annoBilancio         integer--  2017
  ,p_ente_proprietario_id integer
  ,p_login_operazione     varchar
  ,p_calcolo_res 		  boolean       --> se true lancia fnc_calcolo_res
  ,p_calcolo_cassa        boolean     --> se true lancia fnc_calcolo_cassa
  ,p_res_calcolato        boolean     --> se true calcolo_cassa, se true res_calcolato calcolo residui, altrimenti leggo da stanziamento
  ,p_aggiorna_stanz       boolean   --> se true aggiorna gli stianziamenti sui capitoli
  ,out codicerisultato    integer
  ,out messaggiorisultato varchar
)
RETURNS record  AS
$body$
declare
    v_dataElaborazione  	timestamp := now();
    ris_res					record;
    ris_res_cassa			record;
    strMessaggio            varchar;
    v_faseBilElabId         integer;
    recInsResCassa          record;
    v_annoBilancio          varchar;
begin
    v_annoBilancio = p_annoBilancio::varchar;
    codicerisultato:=0;
    strMessaggio:='Inserimento fase elaborazione [fnc_fasi_bil_aggiorna_res_cassa].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
    fase_bil_elab_tipo_id,
    ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE CALCOLO RESIDUO E CASSA IN CORSO.',
            tipo.fase_bil_elab_tipo_id,p_ente_proprietario_id, now(), p_login_operazione
    from fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=p_ente_proprietario_id
    and   tipo.fase_bil_elab_tipo_code='APE_CAP_CALC_RES'
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null)
    returning fase_bil_elab_id into v_faseBilElabId;

	----------------------------------------------------
    if p_calcolo_res = true AND (p_res_calcolato is true or p_calcolo_cassa is true) then
      messaggiorisultato := 'OK. se p_calcolo_res is true p_res_calcolato e p_calcolo_cassa non possono essere  true';
      codicerisultato:=-1;
    raise notice 'KO p_calcolo_res e p_res_calcolato non possono essere entrambi true';
	return;
    end if;


    if (p_aggiorna_stanz is true AND p_calcolo_cassa is false ) then

	    messaggiorisultato := 'OK. aggiornamento dei dati non possibile se non a seguito di calcolo cassa concomitante per cui valorizzare sia p_aggiorna_stanz che p_calcolo_cassa a true.';
	      codicerisultato:=-1;
	    raise notice 'OK. aggiornamento dei dati non possibile se non a seguito di calcolo cassa concomitante per cui valorizzare sia p_aggiorna_stanz che p_calcolo_cassa a true.';
		return;

    end if;


    if p_calcolo_res = true then
    	select * into ris_res from fnc_fasi_bil_cap_calcolo_res ( p_elem_tipo_code ,p_elem_tipo_code_prev,p_annoBilancio,p_ente_proprietario_id,p_login_operazione,v_faseBilElabId);
    	if ris_res.codiceRisultato = -1 then
    	    strMessaggio := ris_res.strMessaggio;
    		raise notice '%   ERRORE : %',ris_res.strMessaggio,substring(upper(SQLERRM) from 1 for 2500);
    	end if;
   	end if;

    if p_calcolo_cassa = true then
    	select * into ris_res_cassa from fnc_fasi_bil_cap_calcolo_cassa (p_annoBilancio ,p_elem_tipo_code ,p_elem_tipo_code_prev , p_res_calcolato ,p_ente_proprietario_id ,p_login_operazione , v_faseBilElabId);
    	if ris_res_cassa.codiceRisultato = -1 then
    	    strMessaggio := ris_res_cassa.messaggiorisultato;
    		raise notice '%   ERRORE : %',ris_res_cassa.messaggiorisultato,substring(upper(SQLERRM) from 1 for 2500);
    	end if;
    end if;

   	if p_aggiorna_stanz = true then

    		strMessaggio :=strMessaggio||'Inizio aggiorno le tabelle sul siac.';
    		--if p_calcolo_cassa = false AND p_calcolo_res = false then
            	--select max(faseBilElabId) into v_faseBilElabId from fase_bil_t_cap_calcolo_res where  ente_proprietario_id = p_ente_proprietario_id;
            --end if;



            for recInsResCassa IN( select * from fase_bil_t_cap_calcolo_res where ente_proprietario_id = p_ente_proprietario_id and fase_bil_elab_id = v_faseBilElabId) LOOP



			strMessaggio    := 'CAPITOLO elem_code-->'||recInsResCassa.elem_code||' elem_code2-->'||recInsResCassa.elem_code2||' elem_code3-->'||recInsResCassa.elem_code3||'v_faseBilElabId-->'||v_faseBilElabId::varchar||'.';

				/*
            	update siac_t_bil_elem_det.elem_det_importo set elem_det_importo = recInsResCassa.stanziamento
                where elem_det_id in (
                  select
                    siac_t_bil_elem_det.elem_det_id
                  from
                    siac_t_bil_elem ,
                    siac_d_bil_elem_tipo,
                    siac_t_bil,
                    siac_r_bil_elem_stato,
                    siac_d_bil_elem_stato,
                    siac_t_bil_elem_det,
                    siac_d_bil_elem_det_tipo,
                    siac_t_periodo
                  where
                        siac_t_bil.bil_id = siac_t_bil_elem.bil_id
                    and	siac_t_bil_elem.elem_tipo_id =  siac_d_bil_elem_tipo.elem_tipo_id
                    and siac_t_bil_elem.elem_id = siac_r_bil_elem_stato.elem_id
                    and siac_r_bil_elem_stato.elem_stato_id = siac_d_bil_elem_stato.elem_stato_id
                    and siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id
                    and siac_t_bil_elem_det.elem_det_tipo_id=siac_d_bil_elem_det_tipo.elem_det_tipo_id
					and siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
                    and siac_d_bil_elem_tipo.elem_tipo_code = p_elem_tipo_code--'CAP-UP'
                    and siac_t_bil.bil_id = recInsResCassa.bil_id
                    and siac_t_bil_elem.ente_proprietario_id = p_ente_proprietario_id
                    and siac_t_bil_elem.data_cancellazione is null
                    and siac_r_bil_elem_stato.data_cancellazione is null
                    and siac_d_bil_elem_stato.elem_stato_code in ('PR','VA')
                    and siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id
                    and siac_t_periodo.anno = v_annoBilancio
                    and siac_t_bil_elem.elem_code  = recInsResCassa.elem_code
                    and siac_t_bil_elem.elem_code2 = recInsResCassa.elem_code2
                    and siac_t_bil_elem.elem_code3 = recInsResCassa.elem_code3

                );
                */

--- Sofia                update siac_t_bil_elem_det.elem_det_importo set elem_det_importo = recInsResCassa.stanziamento_cassa
                update siac_t_bil_elem_det set elem_det_importo = recInsResCassa.stanziamento_cassa
                where elem_det_id in (
                  select
                    siac_t_bil_elem_det.elem_det_id
                  from
                    siac_t_bil_elem ,
                    siac_d_bil_elem_tipo,
                    siac_t_bil,
                    siac_r_bil_elem_stato,
                    siac_d_bil_elem_stato,
                    siac_t_bil_elem_det,
                    siac_d_bil_elem_det_tipo,
                    siac_t_periodo
                  where
                        siac_t_bil.bil_id = siac_t_bil_elem.bil_id
                    and	siac_t_bil_elem.elem_tipo_id =  siac_d_bil_elem_tipo.elem_tipo_id
                    and siac_t_bil_elem.elem_id = siac_r_bil_elem_stato.elem_id
                    and siac_r_bil_elem_stato.elem_stato_id = siac_d_bil_elem_stato.elem_stato_id
                    and siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id
                    and siac_t_bil_elem_det.elem_det_tipo_id=siac_d_bil_elem_det_tipo.elem_det_tipo_id
					and siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA'
                    and siac_d_bil_elem_tipo.elem_tipo_code = p_elem_tipo_code--'CAP-UP'
                    and siac_t_bil.bil_id = recInsResCassa.bil_id
                    and siac_t_bil_elem.ente_proprietario_id = p_ente_proprietario_id
                    and siac_t_bil_elem.data_cancellazione is null
                    and siac_r_bil_elem_stato.data_cancellazione is null
                    and siac_d_bil_elem_stato.elem_stato_code in ('PR','VA')
                    and siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id
                    and siac_t_periodo.anno = v_annoBilancio
                    and siac_t_bil_elem.elem_code  = recInsResCassa.elem_code
                    and siac_t_bil_elem.elem_code2 = recInsResCassa.elem_code2
                    and siac_t_bil_elem.elem_code3 = recInsResCassa.elem_code3
                );


-- Sofia              update siac_t_bil_elem_det.elem_det_importo set elem_det_importo = recInsResCassa.tot_impacc
              update siac_t_bil_elem_det set elem_det_importo = recInsResCassa.tot_impacc
                  where elem_det_id in (
                    select
                      siac_t_bil_elem_det.elem_det_id
                    from
                      siac_t_bil_elem ,
                      siac_d_bil_elem_tipo,
                      siac_t_bil,
                      siac_r_bil_elem_stato,
                      siac_d_bil_elem_stato,
                      siac_t_bil_elem_det,
                      siac_d_bil_elem_det_tipo,
                      siac_t_periodo
                    where
                          siac_t_bil.bil_id = siac_t_bil_elem.bil_id
                      and	siac_t_bil_elem.elem_tipo_id =  siac_d_bil_elem_tipo.elem_tipo_id
                      and siac_t_bil_elem.elem_id = siac_r_bil_elem_stato.elem_id
                      and siac_r_bil_elem_stato.elem_stato_id = siac_d_bil_elem_stato.elem_stato_id
                      and siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id
                      and siac_t_bil_elem_det.elem_det_tipo_id=siac_d_bil_elem_det_tipo.elem_det_tipo_id
                      and siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
                      and siac_d_bil_elem_tipo.elem_tipo_code = p_elem_tipo_code--'CAP-UP'
                      and siac_t_bil.bil_id = recInsResCassa.bil_id
                      and siac_t_bil_elem.ente_proprietario_id = p_ente_proprietario_id
                      and siac_t_bil_elem.data_cancellazione is null
                      and siac_r_bil_elem_stato.data_cancellazione is null
                      and siac_d_bil_elem_stato.elem_stato_code in ('PR','VA')
                      and siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id
                      and siac_t_periodo.anno = v_annoBilancio
                      and siac_t_bil_elem.elem_code  = recInsResCassa.elem_code
                      and siac_t_bil_elem.elem_code2 = recInsResCassa.elem_code2
                      and siac_t_bil_elem.elem_code3 = recInsResCassa.elem_code3
                  );





            end loop;

    end if;

     -----------------------------------------------------
     strMessaggio:='Aggiornamento fase elaborazione [fnc_fasi_bil_aggiorna_res_cassa].';
     update fase_bil_t_elaborazione set
          fase_bil_elab_esito='OK',
          fase_bil_elab_esito_msg='ELABORAZIONE CALCOLO RESIDUO E CASSA COMPLETATA.',
          validita_fine=now()
     where fase_bil_elab_id=v_faseBilElabId;

    messaggiorisultato := 'OK. '|| strMessaggio||'fine elaborazione.';
exception
    when RAISE_EXCEPTION THEN
    	codicerisultato:=-1;
    	raise notice '%   ERRORE : %',strMessaggio,substring(upper(SQLERRM) from 1 for 2500);
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        return;
	when others  THEN
	    codicerisultato:=-1;
		raise notice ' % ERRORE DB: % %',strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 2500);
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;



