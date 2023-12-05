/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR262_elenco_versione_fcde_assestamento" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  afde_bil_id integer,
  afde_bil_versione integer,
  versione_desc varchar
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;


BEGIN


/*
Funzione creata per la SIAC-8664 - 07/10/2022.
Restituisce l'elenco delle versioni FCDE di Assestamento disponibili.
E' stata creata una funzione per rendere piu' semplici eventuali modifiche sul
formato della descrizione da visualizzare nel report, sul filtro (solo DEFINITIVE
o anche BOZZA) e sull'ordinamento dei dati.

*/

return query
select fondi_bil.afde_bil_id, fondi_bil.afde_bil_versione,
('Versione #' || fondi_bil.afde_bil_versione|| ' del '||to_char(fondi_bil.validita_inizio,'dd/MM/yyyy')|| ' in stato ' ||stato.afde_stato_code)::varchar versione_desc
from siac_t_acc_fondi_dubbia_esig_bil fondi_bil,
	siac_d_acc_fondi_dubbia_esig_tipo tipo,
    siac_d_acc_fondi_dubbia_esig_stato stato,
    siac_t_bil bil,
    siac_t_periodo per
where fondi_bil.afde_tipo_id =tipo.afde_tipo_id
	and fondi_bil.afde_stato_id = stato.afde_stato_id
	and fondi_bil.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
	and fondi_bil.ente_proprietario_id = p_ente_prop_id
	and per.anno= p_anno
    and tipo.afde_tipo_code ='GESTIONE' -- = Assestamento
    and stato.afde_stato_code = 'DEFINITIVA'
    and fondi_bil.data_cancellazione IS NULL
    and tipo.data_cancellazione IS NULL
    and stato.data_cancellazione IS NULL
order by fondi_bil.afde_bil_versione desc;     


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'Nessun dato trovato.' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='Ricerca dati fcde';
		 RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR262_elenco_versione_fcde_assestamento" (p_ente_prop_id integer, p_anno varchar)
  OWNER TO siac;