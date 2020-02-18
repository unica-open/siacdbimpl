/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_fasi_bil_cap_calcolo_res (
  p_elem_tipo_code varchar,
  p_elem_tipo_code_prec varchar,
  p_annobilancio integer,
  p_ente_proprietario_id integer,
  p_login_operazione varchar,
  faseBilElabId    integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
declare
    v_dataElaborazione  	timestamp := now();
    v_movgest_id  			integer  := 0 ;
    v_bil_id      			integer  := 0 ;
    v_bil_id_prec      		integer  := 0 ;
    v_movgest_ts_id 		integer  := 0 ;
    strMessaggio 			VARCHAR  :='Inizio elab.';
    strCapTmp 		    	VARCHAR;
    strImpTmp 		    	VARCHAR;
    v_annoBilancio       	varchar;
    v_annoBilancioPrec  	varchar;
    recCap   				record;
    recMovgest 				record;
    recliq					record;
    v_impegnatoXcapitolo 	numeric := 0;
    v_pagatoIncXcapitolo     	numeric := 0;
    v_resXCapitolo		 	numeric := 0;
    v_tot_impacc 			numeric := 0;
    v_stanziamento 			numeric := 0;
    v_stanziamento_cassa 	numeric := 0;
    v_pagato_incassato      numeric := 0;
    v_tipo_movgest          varchar :='I';
   -- v_faseBilElabId         integer :=0;
begin
	codicerisultato :=0;
    v_annoBilancio = p_annoBilancio::varchar;
    v_annoBilancioPrec = (p_annoBilancio-1)::varchar;

	select siac_t_bil.bil_id
	into v_bil_id
	from
	siac_t_bil,
	siac_t_periodo
	where
	siac_t_bil.periodo_id = siac_t_periodo.periodo_id
	and siac_t_periodo.anno = v_annoBilancio
	and siac_t_bil.ente_proprietario_id = p_ente_proprietario_id;



	select siac_t_bil.bil_id
	into v_bil_id_prec
	from
	siac_t_bil,
	siac_t_periodo
	where
	siac_t_bil.periodo_id = siac_t_periodo.periodo_id
	and siac_t_periodo.anno = v_annoBilancioPrec
	and siac_t_bil.ente_proprietario_id = p_ente_proprietario_id;

	strMessaggio :=strMessaggio||'estratto id biancio '||v_bil_id::varchar||' biancio precedente '||v_bil_id_prec::VARCHAR||'.';


    for recCap IN(select distinct
                     siac_t_bil_elem.elem_code
                    ,siac_t_bil_elem.elem_code2
                    ,siac_t_bil_elem.elem_code3
                    ,siac_t_bil_elem.elem_id
          			,siac_t_bil_elem.elem_tipo_id
                    ,siac_t_bil_elem_det.elem_det_importo
                  from
                    siac_t_bil_elem ,
                    siac_d_bil_elem_tipo,
                    siac_t_bil,
                    siac_r_bil_elem_stato,
                    siac_d_bil_elem_stato,
                    siac_t_bil_elem_det,
                    siac_d_bil_elem_det_tipo,
                    siac_t_periodo,
                    siac_r_bil_elem_categoria,
                    siac_d_bil_elem_categoria
                  where
                        siac_t_bil.bil_id = siac_t_bil_elem.bil_id
                    and	siac_t_bil_elem.elem_tipo_id =  siac_d_bil_elem_tipo.elem_tipo_id
                    and siac_t_bil_elem.elem_id = siac_r_bil_elem_stato.elem_id
                    and siac_r_bil_elem_stato.elem_stato_id = siac_d_bil_elem_stato.elem_stato_id
                    and siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id
                    and siac_t_bil_elem_det.elem_det_tipo_id=siac_d_bil_elem_det_tipo.elem_det_tipo_id
					and siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
                    and siac_d_bil_elem_tipo.elem_tipo_code = p_elem_tipo_code--'CAP-UP'
                    and siac_t_bil.bil_id = v_bil_id
                    and siac_t_bil_elem.ente_proprietario_id = p_ente_proprietario_id
                    and siac_t_bil_elem.data_cancellazione is null
                    and siac_r_bil_elem_stato.data_cancellazione is null
                    and siac_d_bil_elem_stato.elem_stato_code in ('PR','VA')
                    and siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id
                    and siac_t_periodo.anno = v_annoBilancio
                    and siac_t_bil_elem.elem_id =  siac_r_bil_elem_categoria.elem_id
                    and siac_r_bil_elem_categoria.elem_cat_id = siac_d_bil_elem_categoria.elem_cat_id
                    and siac_r_bil_elem_categoria.data_cancellazione is null
                    and siac_r_bil_elem_categoria.validita_fine is null
                    and siac_d_bil_elem_categoria.elem_cat_code = 'STD'
                    order by siac_t_bil_elem.elem_code
                            ,siac_t_bil_elem.elem_code2
                            ,siac_t_bil_elem.elem_code3
    ) LOOP
    strCapTmp    := 'CAPITOLO elem_code-->'||recCap.elem_code||' elem_code2-->'||recCap.elem_code2||' elem_code3-->'||recCap.elem_code3||'.';
    strMessaggio := strCapTmp;

    v_impegnatoXcapitolo :=0;
    v_pagatoIncXcapitolo    :=0;

    	if p_elem_tipo_code = 'CAP-UG' OR p_elem_tipo_code ='CAP-UP' then
    		v_tipo_movgest :='I';
        ELSE
           v_tipo_movgest :='A';
        end if;

    	for recMovgest IN(select
                             siac_t_movgest_ts.movgest_ts_id
                             ,siac_d_movgest_ts_tipo.movgest_ts_tipo_code
                             ,siac_t_movgest_ts_det.movgest_ts_det_importo
                          from
                             siac_t_bil_elem
                            ,siac_d_bil_elem_tipo
                            ,siac_r_movgest_bil_elem
                            ,siac_t_movgest
                            ,siac_t_movgest_ts
                            ,siac_t_movgest_ts_det
                            ,siac_d_movgest_stato
                            ,siac_d_movgest_tipo
                            ,siac_r_movgest_ts_stato
                            ,siac_d_movgest_ts_tipo
                            ,siac_d_movgest_ts_det_tipo
                          where
                                siac_t_bil_elem.elem_id             	   			= siac_r_movgest_bil_elem.elem_id
                            and siac_r_movgest_bil_elem.movgest_id  	   			= siac_t_movgest.movgest_id
                            and siac_t_movgest.movgest_id           	  		 	= siac_t_movgest_ts.movgest_id
                            and	siac_t_bil_elem.elem_tipo_id                        = siac_d_bil_elem_tipo.elem_tipo_id
                            and siac_d_bil_elem_tipo.elem_tipo_code                 = p_elem_tipo_code_prec
                            and siac_t_movgest_ts.movgest_ts_id            			= siac_r_movgest_ts_stato.movgest_ts_id
                            and siac_r_movgest_ts_stato.movgest_stato_id   			= siac_d_movgest_stato.movgest_stato_id
                            and siac_t_movgest_ts.movgest_ts_id            			= siac_t_movgest_ts_det.movgest_ts_id
                            and siac_t_movgest.movgest_tipo_id             			= siac_d_movgest_tipo.movgest_tipo_id
                            and siac_t_movgest_ts.movgest_ts_tipo_id       			= siac_d_movgest_ts_tipo.movgest_ts_tipo_id
                            and siac_t_movgest_ts_det.movgest_ts_det_tipo_id 		= siac_d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
							and siac_d_movgest_tipo.movgest_tipo_code      			= v_tipo_movgest--'I'
							and siac_d_movgest_stato.movgest_stato_code    			in ('D','N','P')
							-- faccio la if dopo
                            --and siac_d_movgest_ts_tipo.movgest_ts_tipo_code	    = 'T'
							and siac_d_movgest_ts_det_tipo.movgest_ts_det_tipo_code = 'A'
                            and siac_t_bil_elem.elem_code  				   			= recCap.elem_code
                            and siac_t_bil_elem.elem_code2 				   			= recCap.elem_code2
                            and siac_t_bil_elem.elem_code3 				   			= recCap.elem_code3
                            and siac_t_bil_elem.bil_id     				   			= v_bil_id_prec
                            and siac_t_movgest.ente_proprietario_id        			= p_ente_proprietario_id
                            and siac_t_movgest.movgest_anno::integer                <=v_annoBilancioPrec::integer
                            and siac_r_movgest_bil_elem.data_cancellazione 			is null
                            and siac_r_movgest_ts_stato.data_cancellazione 			is null
                            and siac_r_movgest_bil_elem.validita_fine 			    is null
                            and siac_r_movgest_ts_stato.validita_fine 			    is null
                            and siac_t_movgest.data_cancellazione                   is null
							and siac_t_movgest.validita_fine                        is null
                            and  siac_t_movgest_ts.data_cancellazione 				is null
                            and  siac_t_movgest_ts.validita_fine 					is null
                            and  siac_t_movgest_ts_det.data_cancellazione 			is null
                            and  siac_t_movgest_ts_det.validita_fine 				is null

                            )loop

            if recMovgest.movgest_ts_tipo_code = 'T' THEN
                v_impegnatoXcapitolo := v_impegnatoXcapitolo + recMovgest.movgest_ts_det_importo;
            end if;

            if p_elem_tipo_code = 'CAP-UG' OR p_elem_tipo_code ='CAP-UP' then

                    for recliq IN(select siac_t_liquidazione.liq_id
                                         --,siac_t_liquidazione.liq_importo
                              from
                                siac_r_liquidazione_movgest,
                                siac_t_liquidazione,
                                siac_r_liquidazione_stato,
                                siac_d_liquidazione_stato
                              where
                                siac_r_liquidazione_movgest.liq_id        = siac_t_liquidazione.liq_id and
                                siac_t_liquidazione.liq_id                = siac_r_liquidazione_stato.liq_id AND
                                siac_r_liquidazione_stato.liq_stato_id    = siac_d_liquidazione_stato.liq_stato_id and
                                siac_d_liquidazione_stato.liq_stato_code    !='A' and
                                siac_r_liquidazione_movgest.movgest_ts_id = recMovgest.movgest_ts_id and
                                siac_r_liquidazione_movgest.ente_proprietario_id = p_ente_proprietario_id and

                                siac_r_liquidazione_movgest.data_cancellazione is null and
                                siac_t_liquidazione.data_cancellazione is null and
                                siac_r_liquidazione_stato.data_cancellazione is null and
                                siac_d_liquidazione_stato.data_cancellazione is null and
                                siac_r_liquidazione_movgest.validita_fine is null and
                                siac_t_liquidazione.validita_fine is null and
                                siac_r_liquidazione_stato.validita_fine is null and
                                siac_d_liquidazione_stato.validita_fine is null and
                                siac_r_liquidazione_stato.data_cancellazione is null and
                                siac_r_liquidazione_stato.validita_fine      is null


                                )   loop

                            select
                                sum(siac_t_ordinativo_ts_det.ord_ts_det_importo)
                            into v_pagato_incassato
                            from
                               siac_r_liquidazione_ord
                              ,siac_t_ordinativo
                              ,siac_r_ordinativo_stato
                              ,siac_d_ordinativo_stato
                              ,siac_d_ordinativo_tipo
                              ,siac_t_ordinativo_ts
                              ,siac_t_ordinativo_ts_det
                              ,siac_d_ordinativo_ts_det_tipo
                            where
                                siac_r_liquidazione_ord.liq_id = recliq.liq_id
                            and siac_r_liquidazione_ord.sord_id =  siac_t_ordinativo_ts.ord_ts_id
                            and siac_t_ordinativo.ord_id= siac_t_ordinativo_ts.ord_id
                            and siac_t_ordinativo.ord_id =siac_r_ordinativo_stato.ord_id
                            and siac_r_ordinativo_stato.ord_stato_id = siac_d_ordinativo_stato.ord_stato_id
                            and siac_d_ordinativo_stato.ord_stato_code !='A'
                            and siac_t_ordinativo.ord_tipo_id =  siac_d_ordinativo_tipo.ord_tipo_id
                    		and siac_d_ordinativo_tipo.ord_tipo_code='P'
                            and siac_t_ordinativo_ts.ord_ts_id=siac_t_ordinativo_ts_det.ord_ts_id
                            and siac_t_ordinativo_ts_det.ord_ts_det_tipo_id =siac_d_ordinativo_ts_det_tipo.ord_ts_det_tipo_id
                            and siac_d_ordinativo_ts_det_tipo.ord_ts_det_tipo_code = 'A'
                            and siac_t_ordinativo_ts.ente_proprietario_id = p_ente_proprietario_id
                            and siac_r_liquidazione_ord.data_cancellazione is null
                            and siac_t_ordinativo.data_cancellazione is null
                            and siac_r_ordinativo_stato.data_cancellazione is null
                            and siac_d_ordinativo_stato.data_cancellazione is null
                            and siac_d_ordinativo_tipo.data_cancellazione is null
                            and siac_t_ordinativo_ts.data_cancellazione is null
                            and siac_t_ordinativo_ts_det.data_cancellazione is null
                            and siac_d_ordinativo_ts_det_tipo.data_cancellazione is null
                            and siac_r_liquidazione_ord.validita_fine is null
                            and siac_t_ordinativo.validita_fine is null
                            and siac_r_ordinativo_stato.validita_fine is null
                            and siac_d_ordinativo_stato.validita_fine is null
                            and siac_d_ordinativo_tipo.validita_fine   is null
                            and siac_t_ordinativo_ts.validita_fine is null
                            and siac_t_ordinativo_ts_det.validita_fine is null
                            and siac_d_ordinativo_ts_det_tipo.validita_fine is null;


                    if v_pagato_incassato is null then
                        v_pagato_incassato:=0;
                    end if;

                    v_pagatoIncXcapitolo := v_pagatoIncXcapitolo +v_pagato_incassato; --+ recliq.liq_importo;

                    end loop;--fine loop recMovgest associati al movimento
            else
            		--caso accertamento	(entrata)
                    select
                        sum(siac_t_ordinativo_ts_det.ord_ts_det_importo)
                    into v_pagato_incassato
                    from
                       siac_r_ordinativo_ts_movgest_ts
                      ,siac_t_ordinativo
                      ,siac_r_ordinativo_stato
                      ,siac_d_ordinativo_stato
                      ,siac_d_ordinativo_tipo
                      ,siac_t_ordinativo_ts
                      ,siac_t_ordinativo_ts_det
                      ,siac_d_ordinativo_ts_det_tipo
                    where

                        siac_r_ordinativo_ts_movgest_ts.movgest_ts_id = recMovgest.movgest_ts_id
                    and siac_r_ordinativo_ts_movgest_ts.ord_ts_id     =  siac_t_ordinativo_ts.ord_ts_id
                    and siac_t_ordinativo.ord_id                      = siac_t_ordinativo_ts.ord_id
                    and siac_t_ordinativo.ord_id                      = siac_r_ordinativo_stato.ord_id
                    and siac_r_ordinativo_stato.ord_stato_id          = siac_d_ordinativo_stato.ord_stato_id
                    and siac_d_ordinativo_stato.ord_stato_code       != 'A'
                    and siac_t_ordinativo.ord_tipo_id                 =  siac_d_ordinativo_tipo.ord_tipo_id
                    and siac_d_ordinativo_tipo.ord_tipo_code          = 'I'
                    and siac_t_ordinativo_ts.ord_ts_id                = siac_t_ordinativo_ts_det.ord_ts_id
                    and siac_t_ordinativo_ts_det.ord_ts_det_tipo_id   = siac_d_ordinativo_ts_det_tipo.ord_ts_det_tipo_id
                    and siac_d_ordinativo_ts_det_tipo.ord_ts_det_tipo_code = 'A'
					and siac_t_ordinativo_ts.ente_proprietario_id = p_ente_proprietario_id
                    and siac_r_ordinativo_ts_movgest_ts.data_cancellazione is null
                    and siac_t_ordinativo.data_cancellazione is null
                    and siac_r_ordinativo_stato.data_cancellazione is null
                    and siac_d_ordinativo_stato.data_cancellazione is null
                    and siac_d_ordinativo_tipo.data_cancellazione is null
                    and siac_t_ordinativo_ts.data_cancellazione is null
                    and siac_t_ordinativo_ts_det.data_cancellazione is null
                    and siac_d_ordinativo_ts_det_tipo.data_cancellazione is null
                    and siac_r_ordinativo_ts_movgest_ts.validita_fine is null
                    and siac_t_ordinativo.validita_fine is null
                    and siac_r_ordinativo_stato.validita_fine is null
                    and siac_d_ordinativo_stato.validita_fine  is null
                    and siac_d_ordinativo_tipo.validita_fine is null
                    and siac_t_ordinativo_ts.validita_fine is null
                    and siac_t_ordinativo_ts_det.validita_fine is null
                    and siac_d_ordinativo_ts_det_tipo.validita_fine is null;

                    if v_pagato_incassato is null then
                        v_pagato_incassato:=0;
                    end if;
                    --calcolo il totimpacc
                    v_pagatoIncXcapitolo := v_pagatoIncXcapitolo +v_pagato_incassato; --+ recliq.liq_importo;

            end if;

    	end loop;--fine loop movGest associati al capitolo in questione

        v_tot_impacc :=v_impegnatoXcapitolo - v_pagatoIncXcapitolo;
        v_stanziamento := recCap.elem_det_importo;
        v_stanziamento_cassa =v_tot_impacc + v_stanziamento;

        v_stanziamento :=0;
        v_stanziamento_cassa:=0;

		strMessaggio := 'prima di inserire la riga v_impegnatoXcapitolo--> '||v_impegnatoXcapitolo::varchar||' v_impegnatoXcapitolo-->'||v_impegnatoXcapitolo::varchar||' stanziato'||v_stanziamento||' v_stanziamento_cassa'||v_stanziamento_cassa::varchar||'.';


		insert into fase_bil_t_cap_calcolo_res (fase_bil_elab_id,elem_code ,elem_code2 ,elem_code3,bil_id ,elem_id,elem_tipo_id ,tot_impacc,stanziamento,stanziamento_cassa ,validita_inizio,validita_fine,data_cancellazione ,ente_proprietario_id ,login_operazione )
        values(faseBilElabId,recCap.elem_code,recCap.elem_code2,recCap.elem_code3 ,v_bil_id ,recCap.elem_id ,recCap.elem_tipo_id   ,v_tot_impacc,v_stanziamento ,v_stanziamento_cassa ,now(),null,null,p_ente_proprietario_id,p_login_operazione );

        strMessaggio := 'riga inserita per capitolo elem_code-->'||recCap.elem_code||' elem_code2-->'||recCap.elem_code2||' elem_code3-->'||recCap.elem_code3||'.';

    end loop;--fine loop capitolo

    messaggiorisultato := 'OK. '|| strMessaggio||'fine elaborazione.';
exception
    when RAISE_EXCEPTION THEN
    codicerisultato :=-1;
    	raise notice '%   ERRORE : %',strMessaggio,substring(upper(SQLERRM) from 1 for 2500);
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        return;
	when others  THEN
    codicerisultato :=-1;
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