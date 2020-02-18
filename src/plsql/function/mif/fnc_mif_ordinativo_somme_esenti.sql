/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_somme_esenti( ordinativoId integer,
 												            splitRevTipoId INTEGER,
                                                            enteProprietarioId integer,
                                                            dataElaborazione timestamp,
                                                            dataFineVal timestamp)
RETURNS varchar AS
$body$
DECLARE

strMessaggio varchar(1500):=null;

importoEsente numeric:=0;
totaleSommaEsente varchar(100):=null;

BEGIN


 strMessaggio:='Lettura ordindativo somme esenti.';

  select  sum(coalesce(doc.subdoc_splitreverse_importo,0)) into importoEsente
  from siac_t_ordinativo_ts ordts, siac_r_subdoc_ordinativo_ts ts, siac_t_subdoc doc,
       siac_r_subdoc_splitreverse_iva_tipo split
  where ordts.ord_id=ordinativoId
  and   ordts.data_cancellazione is null
  and   ordts.validita_fine is null
  and   ts.ord_ts_id=ordts.ord_ts_id
  and   ts.data_cancellazione is null
  and   ts.validita_fine is null
  and   doc.subdoc_id=ts.subdoc_id
  and   doc.data_cancellazione is null
  and   doc.validita_fine is null
  and   split.subdoc_id=doc.subdoc_id
  and   split.sriva_tipo_id=splitRevTipoId
  and   split.data_cancellazione  is null
  and   split.validita_fine is null;


  if importoEsente!=0 then
  	totaleSommaEsente:=trunc(importoEsente*100)::varchar;
  /*else
    totaleSommaEsente:='0';*/
  end if;

  return totaleSommaEsente;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 1000),'');
        return totaleSommaEsente;
    when TOO_MANY_ROWS THEN
        RAISE EXCEPTION '% Diverse righe lette.',coalesce(strMessaggio,'');
        return totaleSommaEsente;
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',coalesce(strMessaggio,'');
        return totaleSommaEsente;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',coalesce(strMessaggio,''),SQLSTATE,substring(SQLERRM from 1 for 1000);
        return totaleSommaEsente;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;