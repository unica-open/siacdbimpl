/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_siac_controllo_importo_impegni_vincolati (listaIdAlAtto text)
RETURNS  TABLE (
  v_doc_anno		integer,
  v_doc_numero      varchar(200),
  v_subdoc_numero   integer,
  v_eldoc_anno      integer,
  v_eldoc_numero    integer,   
  v_subdoc_importo 	NUMERIC,
  v_acc_anno		integer,
  v_acc_numero      NUMERIC,
  v_importoOrd 		NUMERIC
)AS
$body$
DECLARE
 arrayIdAlAtto 		integer[];
 indice     		integer:=1;
 idAttoAll  		integer; 
 
 /* v_doc_anno		integer;
  v_doc_numero      VARCHAR(200);
  v_subdoc_numero   integer;
  v_eldoc_numero    integer; 
  v_eldoc_anno      integer; 
  v_subdoc_importo 	NUMERIC;
  v_acc_anno		integer;
  v_acc_numero      NUMERIC;
  v_importoOrd 		NUMERIC;*/
  strMessaggio		varchar(200);
  recVincolati      record;
begin

	arrayIdAlAtto = string_to_array(listaIdAlAtto,',');

    execute 'DROP TABLE IF EXISTS tmp_spesa_vincolata_non_finanziata;';
    execute 'CREATE TABLE tmp_spesa_vincolata_non_finanziata (
                                                                doc_anno			integer,
                                                                doc_numero      	VARCHAR(200),
                                                                subdoc_numero   	integer,
                                                                eldoc_anno      	integer,
                                                                eldoc_numero    	integer,                                                                 
                                                                subdoc_importo 		NUMERIC,
                                                                acc_anno            integer,
																acc_numero          NUMERIC,
                                                                importoOrd 			NUMERIC
    );';

while coalesce(arrayIdAlAtto[indice],0)!=0
  loop
    idAttoAll:=arrayIdAlAtto[indice];
    --raise notice 'idAttoAll=% ',idAttoAll;
    indice:=indice+1;
	for recVincolati in (
	 select 
       sum(subdoc.subdoc_importo) as totale_importo_subdoc
      ,r_movgest.movgest_ts_a_id as acc_ts_id
       ,r_movgest.movgest_ts_b_id as imp_ts_id					 
	from 
		 siac_t_atto_allegato allegato
		,siac_r_atto_allegato_elenco_doc r_allegato_elenco
		,siac_t_elenco_doc elenco
		,siac_r_elenco_doc_subdoc r_elenco_subdoc
		,siac_r_subdoc_movgest_ts r_subdoc_movgest_ts
		,siac_t_movgest_ts imp_ts
		,siac_r_movgest_ts r_movgest 
		,siac_t_subdoc subdoc
	where
		-- condizioni di join
			allegato.attoal_id =  r_allegato_elenco.attoal_id
		and r_allegato_elenco.eldoc_id =  elenco.eldoc_id
		and elenco.eldoc_id =  r_elenco_subdoc.eldoc_id
		and r_elenco_subdoc.subdoc_id =  r_subdoc_movgest_ts.subdoc_id
		and r_subdoc_movgest_ts.movgest_ts_id =  imp_ts.movgest_ts_id
		and imp_ts.movgest_ts_id = r_movgest.movgest_ts_b_id --impegno 	
		and r_elenco_subdoc.subdoc_id = subdoc.subdoc_id 
		-- filtro su data cancellazione
		and allegato.data_cancellazione is null 
		and r_allegato_elenco.data_cancellazione is null
        and now() >= r_allegato_elenco.validita_inizio
		and now() <= coalesce(r_allegato_elenco.validita_fine::timestamp with time zone, now())		
		and elenco.data_cancellazione is null 
		and r_elenco_subdoc.data_cancellazione is null
        and now() >= r_elenco_subdoc.validita_inizio
		and now() <= coalesce(r_elenco_subdoc.validita_fine::timestamp with time zone, now())			
		and r_subdoc_movgest_ts.data_cancellazione is null 
		and now() >= r_subdoc_movgest_ts.validita_inizio
		and now() <= coalesce(r_subdoc_movgest_ts.validita_fine::timestamp with time zone, now())
		and imp_ts.data_cancellazione is null 
		and subdoc.data_cancellazione is null
		and r_movgest.data_cancellazione is null 
		and now() >= r_movgest.validita_inizio
		and now() <= coalesce(r_movgest.validita_fine::timestamp with time zone, now())
		-- filtro su id atto allegato		
		and allegato.attoal_id = idAttoAll
		-- gli accertamenti devono essere validi
		and exists (
			select 1
			from siac_r_movgest_ts_stato r_stato_acc
			,siac_d_movgest_stato acc_stato
			where r_stato_acc.data_cancellazione is null
			and acc_stato.movgest_stato_id = r_stato_acc.movgest_stato_id
			and r_stato_acc.movgest_ts_id = r_movgest.movgest_ts_a_id
			and now() >= r_stato_acc.validita_inizio
		    and now() <= coalesce(r_stato_acc.validita_fine::timestamp with time zone, now())
			and acc_stato.movgest_stato_code <> 'A'
		)
		--gli accertamenti devono essere di tipo accertamento
		and exists(
			select 1
			from siac_t_movgest_ts tmt
			,siac_t_movgest tm
			,siac_d_movgest_tipo dmt
			where tm.movgest_id = tmt.movgest_id
			and tmt.movgest_ts_id = r_movgest.movgest_ts_a_id
			and dmt.movgest_tipo_id = tm.movgest_tipo_id
			and dmt.movgest_tipo_code='A'
			and now() >= tm.validita_inizio
		    and now() <= coalesce(tm.validita_fine::timestamp with time zone, now())
			and now() >= tmt.validita_inizio
		    and now() <= coalesce(tmt.validita_fine::timestamp with time zone, now())
		)
		group by r_movgest.movgest_ts_a_id,r_movgest.movgest_ts_b_id
	)loop
	
	 v_doc_anno:=null;
	 v_doc_numero:=null;
	 v_subdoc_numero:=null;
	 v_eldoc_numero:=null; 
	 v_eldoc_anno:=null; 
	 v_subdoc_importo :=null;
	 v_acc_anno:=null;
	 v_acc_numero:=null;
	 v_importoOrd:=null;
  
	--calcolo l'importo riscosso
	SELECT	coalesce(sum(detA.ord_ts_det_importo),0) into v_importoOrd
		FROM  siac_t_ordinativo ordinativo, 
			  --siac_d_ordinativo_tipo tipo,
			  siac_r_ordinativo_stato rs, 
			  siac_d_ordinativo_stato stato,
			  siac_t_ordinativo_ts ts,
			  siac_t_ordinativo_ts_det detA , 
			  siac_d_ordinativo_ts_det_tipo tipoA,
			  siac_r_ordinativo_ts_movgest_ts r_ordinativo_movgest
		WHERE  r_ordinativo_movgest.movgest_ts_id = recVincolati.acc_ts_id
		and    ts.ord_ts_id=r_ordinativo_movgest.ord_ts_id
		and    ordinativo.ord_id=ts.ord_id
		and    rs.ord_id=ordinativo.ord_id
	    and    stato.ord_stato_id=rs.ord_stato_id
		and    stato.ord_stato_code!='A'
--		and    tipo.ord_tipo_id=ordinativo.ord_tipo_id		
--      and    tipo.ord_tipo_code='I'
		and    detA.ord_ts_id=ts.ord_ts_id
		and    tipoA.ord_ts_det_tipo_id=detA.ord_ts_det_tipo_id
		and    tipoA.ord_ts_det_tipo_code='A'
		and    ordinativo.data_cancellazione is null
		and    now() >= ordinativo.validita_inizio
		and    now() <= coalesce(ordinativo.validita_fine::timestamp with time zone, now())
		and    ts.data_cancellazione is null
		and    now() >= ts.validita_inizio
		and    now() <= coalesce(ts.validita_fine::timestamp with time zone, now())
		and    detA.data_cancellazione is null
		and    now() >= detA.validita_inizio
		and    now() <= coalesce(detA.validita_fine::timestamp with time zone, now())
		and    rs.data_cancellazione is null
		and    now() >= rs.validita_inizio
		and    now() <= coalesce(rs.validita_fine::timestamp with time zone, now())
		and    now() >= r_ordinativo_movgest.validita_inizio
		and    now() <= coalesce(r_ordinativo_movgest.validita_fine::timestamp with time zone, now());
		
		
		if v_importoOrd < recVincolati.totale_importo_subdoc then
			--SIAC-6688
			select distinct tm.movgest_anno, tm.movgest_numero into v_acc_anno, v_acc_numero
			from siac_t_movgest tm
			,siac_t_movgest_ts tmt
			where tm.movgest_id = tmt.movgest_id
			and tmt.movgest_ts_id = recVincolati.acc_ts_id;
			
            --versione con tabella
			--/*
            insert into tmp_spesa_vincolata_non_finanziata
				select doc.doc_anno
				,doc.doc_numero 
				,subdoc.subdoc_numero 
                ,elenco.eldoc_anno  
				,elenco.eldoc_numero				
				,subdoc.subdoc_importo			
				,v_acc_anno
				,v_acc_numero
				,v_importoOrd
		  -- */
           --versione con next
			/*select doc.doc_anno::integer
				  ,doc.doc_numero 
				  ,subdoc.subdoc_numero::integer   
				  ,elenco.eldoc_numero::integer    
				  ,elenco.eldoc_anno::integer
				  ,subdoc.subdoc_importo
            into 
				  v_doc_anno,
			      v_doc_numero,
				  v_subdoc_numero,
				  v_eldoc_numero,
				  v_eldoc_anno, 
				  v_subdoc_importo
            */
			from siac_t_subdoc subdoc
				,siac_t_doc doc
				,siac_r_elenco_doc_subdoc r_elenco_sub
				,siac_t_elenco_doc elenco
                ,siac_r_subdoc_movgest_ts r_subdoc_movgest
                ,siac_r_atto_allegato_elenco_doc r_allegato_elenco				
				where doc.doc_id = subdoc.doc_id
				and  r_elenco_sub.subdoc_id = subdoc.subdoc_id
			    and  elenco.eldoc_id = r_elenco_sub.eldoc_id
                and r_allegato_elenco.eldoc_id = elenco.eldoc_id
                and r_allegato_elenco.attoal_id = idAttoAll 
                and r_subdoc_movgest.subdoc_id = r_elenco_sub.subdoc_id
				and r_subdoc_movgest.movgest_ts_id = recVincolati.imp_ts_id
                and r_subdoc_movgest.data_cancellazione is null				
				and doc.data_cancellazione is null
				and subdoc.data_cancellazione is null
				and r_elenco_sub.data_cancellazione is null
				and elenco.data_cancellazione is null
                and r_allegato_elenco.data_cancellazione is null
                and exists(
                	select 1 
                	from siac_r_elenco_doc_stato r_elenco_stato
                	,siac_d_elenco_doc_stato elenco_stato
                	where r_elenco_stato.eldoc_id = elenco.eldoc_id
                	and r_elenco_stato.eldoc_stato_id = elenco_stato.eldoc_stato_id
                	and elenco_stato.eldoc_stato_code = 'B'
                	and r_elenco_stato.data_cancellazione is null
                );
		-- return next;
		 
		end if;
    end loop;   
  end loop;

	RETURN QUERY 
    
    SELECT 
      *
    from
    	tmp_spesa_vincolata_non_finanziata
        order by acc_anno, acc_numero, eldoc_anno, eldoc_numero;
 
  -- return;
 
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;