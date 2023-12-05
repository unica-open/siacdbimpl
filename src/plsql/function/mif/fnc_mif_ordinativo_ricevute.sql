/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
REATE OR REPLACE FUNCTION fnc_mif_ordinativo_ricevute( ordinativoId integer,
														mantieniDec boolean,
                                                        enteProprietarioId integer,
                                                        dataElaborazione timestamp,
                                                        dataFineVal timestamp)
RETURNS table
(
    annoRicevuta varchar(50),
    numeroRicevuta VARCHAR(50),
    importoRicevuta varchar,
    provRicevutaId  integer
) AS
$body$
DECLARE

strMessaggio varchar(1500):=null;

ricevutaRec record;

BEGIN

 annoRicevuta:=null;
 numeroRicevuta:=null;
 importoRicevuta:=null;
 provRicevutaId:=null;


 strMessaggio:='Lettura ricevute.';
 /* JIRA-2977 05.02.2016  - prendeva importo provvisorio invece di quello regolarizzato
    select prov.provc_anno annoProv, prov.provc_numero numeroProv, prov.provc_importo importoProv, prov.provc_id idProv */
 for ricevutaRec in
 ( select prov.provc_anno annoProv, prov.provc_numero numeroProv, rprov.ord_provc_importo importoProv, prov.provc_id idProv
    from siac_r_ordinativo_prov_cassa rprov, siac_t_prov_cassa prov
    where rprov.ord_id=ordinativoId
    and   rprov.data_cancellazione is null
    and   rprov.validita_fine is null
    and   prov.provc_id=rprov.provc_id
    and   prov.data_cancellazione is null
    and   prov.validita_fine is null
   order by rprov.ord_provc_id
 )
 loop

	annoRicevuta:=ricevutaRec.annoProv;

    if mantieniDec=true then
    	importoRicevuta:=ricevutaRec.importoProv::VARCHAR;
        numeroRicevuta:=ricevutaRec.numeroProv::varchar;
    else
		importoRicevuta:=trunc(ricevutaRec.importoProv*100)::VARCHAR;
        numeroRicevuta:=lpad(ricevutaRec.numeroProv::varchar,7,'0');
    end if;
	provRicevutaId:=ricevutaRec.idProv;

    return next;
 end loop;



 return;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 1000),'');
        return;
    when TOO_MANY_ROWS THEN
        RAISE EXCEPTION '% Diverse righe lette.',coalesce(strMessaggio,'');
        return;
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',coalesce(strMessaggio,'');
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',coalesce(strMessaggio,''),SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;