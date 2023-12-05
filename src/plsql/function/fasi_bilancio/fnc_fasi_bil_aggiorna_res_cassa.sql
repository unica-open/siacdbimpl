/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop function if exists
fnc_fasi_bil_cap_aggiorna_res_cassa 
(
   p_elem_tipo_code       varchar
  ,p_elem_tipo_code_prev  varchar
  ,p_annoBilancio         integer
  ,p_ente_proprietario_id integer
  ,p_login_operazione     varchar
  ,p_calcolo_res 		  boolean
  ,p_calcolo_cassa        boolean
  ,p_res_calcolato        boolean
  ,p_aggiorna_stanz       boolean
  ,out faseBilElabId      integer
  ,out codicerisultato    integer
  ,out messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION fnc_fasi_bil_cap_aggiorna_res_cassa 
(
   p_elem_tipo_code       varchar  --  tipo capitolo da aggiornare [CAP-EP,CAP-EG,CAP-UG,CAP-UP]|[C,R,E] - il tipo aggiornamento obb. solo se p_aggiorna_stanz=true
   -- C : aggiorna cassa       ,  imposta p_calcolo_cassa=true p_calcolo_res=false
   -- R : aggiorna res         ,  imposta p_calcolo_res=true   p_calcolo_cassa=p_res_calcolo=false
   -- E : aggiorna, res e cassa,  imposta p_calcolo_cassa=p_res_calcolo=true p_calcolo_res=false   
  ,p_elem_tipo_code_prev  varchar  --  tipo capitolo su cui leggere residui (CAP-UG, CAP-EG)
  ,p_annoBilancio         integer 
  ,p_ente_proprietario_id integer
  ,p_login_operazione     varchar
  ,p_calcolo_res 		  boolean  --> se true lancia fnc_calcolo_res ( esclusivo con fnc_calcolo_cassa )
  ,p_calcolo_cassa        boolean  --> se true lancia fnc_calcolo_cassa ( esclusivo con fnc_calcolo_res )
  ,p_res_calcolato        boolean  --> utilizzato in caso di p_calcolo_cassa=true per calcolo cassa, se true residui ricalcolati, se false letti da STR 
  ,p_aggiorna_stanz       boolean  --> se true aggiorna gli stianziamenti sui capitoli in base al tipo di aggiornamento 
  ,out faseBilElabId      integer
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

    -- 06.05.2021 Sofia Jira SIAC-7193
    tipoAggiornamento      varchar(15):=null;

begin
    v_annoBilancio = p_annoBilancio::varchar;
    codicerisultato:=0;
    faseBilElabId:=null;

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
   /*  06.05.2021 Sofia Jira SIAC-7931
   if p_calcolo_res = true AND (p_res_calcolato is true or p_calcolo_cassa is true) then
      messaggiorisultato := 'OK. se p_calcolo_res is true p_res_calcolato e p_calcolo_cassa non possono essere  true';
      codicerisultato:=-1;
    raise notice 'KO p_calcolo_res e p_res_calcolato non possono essere entrambi true';
	return;
    end if;*/

	
    -- 06.05.2021 Sofia Jira SIAC-7931
    if p_calcolo_res=true and p_calcolo_cassa=true then
      messaggiorisultato := 'KO. Residuo e Cassa devono essere alternativi (p_calcolo_res=true e p_calcolo_cassa=true non consentito ).';
      codicerisultato:=-1;
	  raise notice '%',messaggiorisultato;
	  return;
    end if;

	-- 06.05.2021 Sofia Jira SIAC-7931
	if p_aggiorna_stanz=false and p_calcolo_cassa=false and p_calcolo_res=false then
	  messaggiorisultato := 'KO. Calcolo stanziamenti senza aggiornamento indicare almeno uno dei due calcoli da effettuare (p_calcolo_cassa=true o p_calcolo_res=true ).';
      codicerisultato:=-1;
	  raise notice '%',messaggiorisultato;
	  return;
	end if;
	
	
    /*  06.05.2021 Sofia Jira SIAC-7931
    if (p_aggiorna_stanz is true AND p_calcolo_cassa is false ) then

	    messaggiorisultato := 'OK. aggiornamento dei dati non possibile se non a seguito di calcolo cassa concomitante per cui valorizzare sia p_aggiorna_stanz che p_calcolo_cassa a true.';
	      codicerisultato:=-1;
	    raise notice 'OK. aggiornamento dei dati non possibile se non a seguito di calcolo cassa concomitante per cui valorizzare sia p_aggiorna_stanz che p_calcolo_cassa a true.';
		return;

    end if;*/

    -- 06.05.2021 Sofia Jira SIAC-7931
    if position('|' in p_elem_tipo_code)>0 then
		tipoAggiornamento:=substring(p_elem_tipo_code,position('|' in p_elem_tipo_code)+1);
	    p_elem_tipo_code:=substring(p_elem_tipo_code,1, position('|' in p_elem_tipo_code)-1);
    end if;
    raise notice 'p_elem_tipo_code=%',p_elem_tipo_code;
    raise notice 'tipoAggiornamento=%',tipoAggiornamento;
    raise notice 'p_aggiorna_stanz=%',p_aggiorna_stanz::varchar;

    if p_aggiorna_stanz is true then
    	if coalesce(tipoAggiornamento,'')='' then
	        messaggiorisultato := 'KO. Per aggiornamento stanziamenti specificare quali aggiornare [C|R|E] in coda al primo parametro.';
    		codicerisultato:=-1;
		    raise notice '%',messaggiorisultato;
	        return;
        end if;

        if tipoAggiornamento='E' then
          p_calcolo_res:=false;
          p_calcolo_cassa:=true;
          p_res_calcolato:=true;
        end if;

        if tipoAggiornamento='C'then
          p_calcolo_res:=false;
          p_calcolo_cassa:=true;
        end if;

        if tipoAggiornamento='R' then
          p_calcolo_res:=true;
          p_calcolo_cassa:=false;
          p_res_calcolato:=false;
        end if;
    end if;

    raise notice 'p_calcolo_res=%',p_calcolo_res::varchar;
    raise notice 'p_calcolo_cassa=%',p_calcolo_cassa::varchar;
    raise notice 'p_res_calcolato=%',p_res_calcolato::varchar;

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
            	update siac_t_bil_elem_det set elem_det_importo = recInsResCassa.stanziamento
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


	            -- 06.05.2021 Sofia Jira SIAC-7931
				if tipoAggiornamento in ('C','E') then
            /* -- 06.05.2021 Sofia Jira SIAC-7931
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
                      and siac_t_bil_elem.validita_fine is null
                      and siac_r_bil_elem_stato.data_cancellazione is null
                      and siac_r_bil_elem_stato.validita_fine is null
  --                    and siac_d_bil_elem_stato.elem_stato_code in ('PR','VA')
                      and siac_d_bil_elem_stato.elem_stato_code='VA'
                      and siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id
                      and siac_t_periodo.anno = v_annoBilancio
                      and siac_t_bil_elem.elem_code  = recInsResCassa.elem_code
                      and siac_t_bil_elem.elem_code2 = recInsResCassa.elem_code2
                      and siac_t_bil_elem.elem_code3 = recInsResCassa.elem_code3
                  );
            */
                  update siac_t_bil_elem_det detUPD
                  set elem_det_importo = recInsResCassa.stanziamento_cassa,
                      data_modifica=clock_timestamp(),
                      login_operazione=detUPD.login_operazione||'-'||p_login_operazione
		          from
				  (
                    select det.elem_det_id
                    from
                      siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
                      siac_r_bil_elem_stato rs,siac_d_bil_elem_stato stato,
                      siac_t_bil_elem_det det,siac_d_bil_elem_det_tipo tipo_det,
                      siac_t_periodo  per
                    where tipo.ente_proprietario_id=p_ente_proprietario_id
	                and   tipo.elem_tipo_code = p_elem_tipo_code
                    and	  e.elem_tipo_id =  tipo.elem_tipo_id
                    and   e.bil_id =        recInsResCassa.bil_id
                    and   e.elem_code  = recInsResCassa.elem_code
                    and   e.elem_code2 = recInsResCassa.elem_code2
                    and   e.elem_code3 = recInsResCassa.elem_code3
                    and   rs.elem_id = e.elem_id
                    and   stato.elem_stato_id = rs.elem_stato_id
                    and   stato.elem_stato_code='VA'
                    and   det.elem_id = e.elem_id
                    and   tipo_det.elem_det_tipo_id=det.elem_det_tipo_id
                    and   tipo_Det.elem_det_tipo_code = 'SCA'
                    and   det.periodo_id = per.periodo_id
                    and   per.anno = v_annoBilancio
                    and   e.data_cancellazione is null
                    and   e.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                  ) query_UPD
                  where detUPD.ente_proprietario_id=p_ente_proprietario_id
                  and   detUPD.elem_Det_id=query_UPD.elem_det_id
                  and   detUPD.data_cancellazione is null
                  and   detUPD.validita_fine is null;


                  strMessaggio    := strMessaggio||'update SCA.';
              end if;  -- 06.05.2021 Sofia Jira SIAC-7931

			  -- 06.05.2021 Sofia Jira SIAC-7931
			  if tipoAggiornamento in ('R','E') then
               /* 06.05.2021 Sofia Jira SIAC-7931
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
                          and siac_t_bil_elem.validita_fine is null
                          and siac_r_bil_elem_stato.data_cancellazione is null
                          and siac_r_bil_elem_stato.validita_fine is null
    --                      and siac_d_bil_elem_stato.elem_stato_code in ('PR','VA')
                          and siac_d_bil_elem_stato.elem_stato_code='VA'
                          and siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id
                          and siac_t_periodo.anno = v_annoBilancio
                          and siac_t_bil_elem.elem_code  = recInsResCassa.elem_code
                          and siac_t_bil_elem.elem_code2 = recInsResCassa.elem_code2
                          and siac_t_bil_elem.elem_code3 = recInsResCassa.elem_code3
                      );
*/
		          -- 06.05.2021 Sofia Jira SIAC-7931
	              update siac_t_bil_elem_det detUPD
                  set elem_det_importo = recInsResCassa.tot_impacc,
                      data_modifica=clock_timestamp(),
                      login_operazione=detUPD.login_operazione||'-'||p_login_operazione
		          from
				  (
                    select det.elem_det_id
                    from
                      siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
                      siac_r_bil_elem_stato rs,siac_d_bil_elem_stato stato,
                      siac_t_bil_elem_det det,siac_d_bil_elem_det_tipo tipo_det,
                      siac_t_periodo  per
                    where tipo.ente_proprietario_id=p_ente_proprietario_id
	                and   tipo.elem_tipo_code = p_elem_tipo_code
                    and	  e.elem_tipo_id =  tipo.elem_tipo_id
                    and   e.bil_id =        recInsResCassa.bil_id
                    and   e.elem_code  = recInsResCassa.elem_code
                    and   e.elem_code2 = recInsResCassa.elem_code2
                    and   e.elem_code3 = recInsResCassa.elem_code3
                    and   rs.elem_id = e.elem_id
                    and   stato.elem_stato_id = rs.elem_stato_id
                    and   stato.elem_stato_code='VA'
                    and   det.elem_id = e.elem_id
                    and   tipo_det.elem_det_tipo_id=det.elem_det_tipo_id
                    and   tipo_Det.elem_det_tipo_code = 'STR'
                    and   det.periodo_id = per.periodo_id
                    and   per.anno = v_annoBilancio
                    and   e.data_cancellazione is null
                    and   e.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                  ) query_UPD
                  where detUPD.ente_proprietario_id=p_ente_proprietario_id
                  and   detUPD.elem_Det_id=query_UPD.elem_det_id
                  and   detUPD.data_cancellazione is null
                  and   detUPD.validita_fine is null;
                  -- 06.05.2021 Sofia Jira SIAC-7931
                  strMessaggio    := strMessaggio||'update STR.';
				end if; -- 06.05.2021 Sofia Jira SIAC-7931

            end loop;

    end if;

     -----------------------------------------------------
     strMessaggio:='Aggiornamento fase elaborazione [fnc_fasi_bil_aggiorna_res_cassa].';
     update fase_bil_t_elaborazione set
          fase_bil_elab_esito='OK',
          fase_bil_elab_esito_msg='ELABORAZIONE CALCOLO RESIDUO E CASSA COMPLETATA.',
          validita_fine=now()
     where fase_bil_elab_id=v_faseBilElabId;

     faseBilElabId:=v_faseBilElabId;
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

alter function siac.fnc_fasi_bil_cap_aggiorna_res_cassa
( varchar, varchar,integer, integer ,varchar, boolean, boolean, boolean ,boolean, out integer,out integer,out varchar) owner to siac;
