/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

-- FUNCTION: siac.fnc_pagopa_t_riconc_doc_cerca_dettagli_elab_di_aggregato(integer, integer, integer)

-- DROP FUNCTION siac.fnc_pagopa_t_riconc_doc_cerca_dettagli_elab_di_aggregato(integer, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_pagopa_t_riconc_doc_cerca_dettagli_elab_di_aggregato(
	p_pagopa_ric_id integer,
	p_pagopa_elab_flusso_id integer,
	p_codice_ente integer)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE
	strMessaggio    			VARCHAR(1500):='';  
    codicerisultato 			integer:=null;
    messaggiorisultato 			VARCHAR(1500):='';
	v_cnt 						integer:=null;
	v_count_dettagli_tutti		integer:=null;
	v_count_dettagli_elaborati	integer:=null;
	
BEGIN
     codicerisultato :=0;
	 v_cnt :=0;
	 v_count_dettagli_tutti := 0;
	 v_count_dettagli_elaborati := 0;
	 messaggiorisultato :='Inizio.';
    
    -- 2 errore generico
    -- 1 ko, non tutti i dettagli sono stati elaborati con successo
    -- 0 ok, tutti i dettagli sono stati elaborati con successo

	strMessaggio:= 'Verifica parametri di input.';
 	if (p_pagopa_ric_id is  null) 
	then
		codicerisultato :=2;	 
		messaggiorisultato := 'p_pagopa_ric_id NULL';
		return codicerisultato::varchar ||'-'||messaggiorisultato;
	end if;
	if (p_pagopa_elab_flusso_id is  null) 
	then
		codicerisultato :=2;	 
		messaggiorisultato := 'p_pagopa_elab_flusso_id NULL';
		return codicerisultato::varchar ||'-'||messaggiorisultato;
	end if;
	if (p_codice_ente is  null) 
	then
		codicerisultato :=2;	 
		messaggiorisultato := 'p_codice_ente NULL';
		return codicerisultato::varchar ||'-'||messaggiorisultato;
	end if;
	
	
	------------------------------------------------------------------------------------------- 
	--- Query che torna il numero di dettagli di una riconciliazione (aggregato)
	------------------------------------------------------------------------------------------- 
	
	strMessaggio:= 'Lettura v_count_dettagli_tutti';
	select count(*)
	into
	v_count_dettagli_tutti
	from siac.pagopa_t_riconciliazione_doc doc
	where doc.ente_proprietario_id = p_codice_ente
		 and doc.data_cancellazione is null
		 and doc.pagopa_ric_id = p_pagopa_ric_id
		 and doc.pagopa_elab_flusso_id = p_pagopa_elab_flusso_id
		 and doc.pagopa_ric_doc_flag_dett = true
		 and doc.pagopa_ric_doc_flag_con_dett = false;
	raise notice ' Letti: v_count_dettagli_tutti=% ',
		v_count_dettagli_tutti;
	
	
	------------------------------------------------------------------------------------------- 
	--- Query che torna il numero di dettagli di una riconciliazione (aggregato)
	--- che sono stati elaborati correttamente (senza errori)
	------------------------------------------------------------------------------------------- 
	strMessaggio:= 'Lettura v_count_dettagli_elaborati';
	select count(*)
	into
	v_count_dettagli_elaborati
	from siac.pagopa_t_riconciliazione_doc
	where pagopa_t_riconciliazione_doc.ente_proprietario_id = p_codice_ente
		 and pagopa_t_riconciliazione_doc.data_cancellazione is null
		 and pagopa_t_riconciliazione_doc.pagopa_ric_id = p_pagopa_ric_id
		 and pagopa_t_riconciliazione_doc.pagopa_elab_flusso_id = p_pagopa_elab_flusso_id
		 and pagopa_t_riconciliazione_doc.pagopa_ric_doc_flag_dett = true
		 and pagopa_t_riconciliazione_doc.pagopa_ric_doc_flag_con_dett = false
		 and pagopa_t_riconciliazione_doc.pagopa_ric_doc_stato_elab = 'S'
		 and pagopa_t_riconciliazione_doc.pagopa_ric_doc_subdoc_id is not null;
	raise notice ' Letti: v_count_dettagli_elaborati=% ',
		v_count_dettagli_elaborati;
		
		
	------------------------------------------------------------------------------------------- 
	--- Confrontiamo i due valori trovati per sapere se tutti i dettagli di una 
	--- riconciliazione (aggregato) sono stati elaborati correttamente
	
	--- (v_count_dettagli_tutti - v_count_dettagli_elaborati) =
	--- se 0 allora sono stati tutti correttamente (senza errori)
	--- se diverso da 0 allora non tutti i dettagli sono stati elaborati correttamente (senza errori)
	------------------------------------------------------------------------------------------- 
	codicerisultato :=(v_count_dettagli_tutti - v_count_dettagli_elaborati);

    return codicerisultato::varchar ; --||'-'||messaggiorisultato;

exception
    when RAISE_EXCEPTION THEN
    	raise notice 'ERRORE DB: % % %',strMessaggio,SQLSTATE, substring(upper(SQLERRM) from 1 for 2500);
        codicerisultato:=2;
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        return codicerisultato::varchar ||'-'||messaggiorisultato;
	when others  THEN
 		raise notice 'ERRORE DB: % % %',strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 2500);
        codicerisultato:=2;
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        return codicerisultato::varchar ||'-'||messaggiorisultato;
END;
$BODY$;

ALTER FUNCTION siac.fnc_pagopa_t_riconc_doc_cerca_dettagli_elab_di_aggregato(integer, integer, integer)
    OWNER TO siac;

GRANT EXECUTE ON FUNCTION siac.fnc_pagopa_t_riconc_doc_cerca_dettagli_elab_di_aggregato(integer, integer, integer) TO siac_rw;

GRANT EXECUTE ON FUNCTION siac.fnc_pagopa_t_riconc_doc_cerca_dettagli_elab_di_aggregato(integer, integer, integer) TO PUBLIC;

GRANT EXECUTE ON FUNCTION siac.fnc_pagopa_t_riconc_doc_cerca_dettagli_elab_di_aggregato(integer, integer, integer) TO siac;

