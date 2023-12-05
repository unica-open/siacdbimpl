/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿/*drop function fnc_mif_ordinativo_ritenute( ordinativoId integer,
														relazRitOrd varchar,
                                                        relazSubOrd varchar,
                                                        relazSpr varchar,
                                                        tipoOnereIrpefId integer,
                                                        tipoOnereInpsId integer,
														ordStatoAnnullatoId integer,
                                                        ordTsDetTipoId integer,
                                                        mantieniDec boolean,
                                                        enteProprietarioId integer,
                                                        dataElaborazione timestamp,
                                                        dataFineVal timestamp); */


CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_ritenute( ordinativoId integer,
														relazRitOrd varchar,
                                                        relazSubOrd varchar,
                                                        relazSpr varchar,
                                                        tipoOnereIrpefId integer,
                                                        tipoOnereInpsId integer,
                                                        tipoOnereIrpegId integer, -- 30.08.2016 Sofia-HD-INC000001208683
														ordStatoAnnullatoId integer,
                                                        ordTsDetTipoId integer,
                                                        mantieniDec boolean,
                                                        enteProprietarioId integer,
                                                        dataElaborazione timestamp,
                                                        dataFineVal timestamp)
RETURNS table
(
	tipoRitenuta varchar,
    numeroRitenuta varchar,
    importoRitenuta varchar,
    ordRitenutaId integer

) AS
$body$
DECLARE

strMessaggio varchar(1500):=null;

ritenutaRec record;
tipoOnereOk integer:=null;
-- 04.01.2017 Sofia HD-INC000001463515
statoOrd integer:=null;
STATO_ORD_A CONSTANT varchar:='A';

BEGIN

 tipoRitenuta:=null;
 numeroRitenuta:=null;
 importoRitenuta:=null;
 ordRitenutaId:=null;

 strMessaggio:='Lettura ritenute.';

 for ritenutaRec in
 (select rord.ord_id_a ord_id, tipo.relaz_tipo_code tipo_ritenuta, ord.ord_numero
  from siac_r_ordinativo rOrd, siac_d_relaz_tipo tipo, siac_t_ordinativo ord,siac_r_ordinativo_stato rstato
  where rord.ord_id_da=ordinativoId
  and   rord.data_cancellazione is null
  and   rord.validita_fine is null
  and   tipo.relaz_tipo_id=rord.relaz_tipo_id
  and   tipo.relaz_tipo_code in (relazRitOrd,relazSubOrd,relazSpr)
  and   tipo.data_cancellazione is null
  and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
---  and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal))
  and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione))
  and   ord.ord_id=rord.ord_id_a
  and   ord.data_cancellazione is null
  and   ord.validita_fine is null
  and   rstato.ord_id=ord.ord_id
--  and   rstato.ord_stato_id!=ordStatoAnnullatoId 29.07.2019 Sofia siac-6971 - la validita della relazione siac_r_ordinativo deve guidare
  and   rstato.data_cancellazione is null
  and   rstato.validita_fine is null -- 19.01.2017
 -- and   date_trunc('day',dataElaborazione)>=date_trunc('day',rstato.validita_inizio) 19.01.2017
--  and  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(rstato.validita_fine,dataFineVal)) 19.01.2017
  order by rord.ord_id_a
 )
 loop

 	tipoRitenuta:=null;
	numeroRitenuta:=null;
	importoRitenuta:=null;
    tipoOnereOk:=null;
    statoOrd:=null;

 	if ritenutaRec.tipo_ritenuta=relazRitOrd then
    	-- controllare l'onere tipo se non irpef/inps/irpeg saltare
--        raise notice 'tipo ritenuta irpef/inps/irpeg';
--        raise notice 'tipoonereInpsId %',tipoOnereInpsId;
--        raise notice 'tipoOnereIrpefId %',tipoOnereIrpefId;
--        raise notice 'tipoOnereIrpegId %',tipoOnereIrpegId;
        select distinct 1 into tipoOnereOk
		from siac_d_onere onere, siac_t_ordinativo_ts ordts, siac_r_doc_onere  rdoc, siac_t_subdoc doc, siac_r_subdoc_ordinativo_ts ts
		where onere.ente_proprietario_id=enteProprietarioId
--		and   onere.onere_tipo_id  in (tipoOnereInpsId,tipoOnereIrpefId) -- 30.08.2016 Sofia-HD-INC000001208683
		and   onere.onere_tipo_id  in (tipoOnereInpsId,tipoOnereIrpefId,tipoOnereIrpegId) -- 30.08.2016 Sofia-HD-INC000001208683
		and   onere.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',onere.validita_inizio)
--	    and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(onere.validita_fine,dataFineVal)) 19.01.2017
	    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(onere.validita_fine,dataElaborazione))
		and   ordts.ord_id=ordinativoId
		and   ordts.data_cancellazione is null
		and   ordts.validita_fine is null
		and   ts.ord_ts_id=ordts.ord_ts_id
		and   ts.data_cancellazione is null
		and   ts.validita_fine is null
		and   doc.subdoc_id=ts.subdoc_id
		and   doc.data_cancellazione is null
		and   doc.validita_fine is null
		and   rdoc.doc_id=doc.doc_id
		and   rdoc.onere_id=onere.onere_id
		and   rdoc.data_cancellazione is null
		and   rdoc.validita_fine is null;

  --      raise notice 'tipoOnere %', tipoOnereOk;

        if tipoOnereOk is null then
        	continue;
        end if;
    end if;

	-- 29.07.2019 Sofia siac-6971
    /*
    -- 04.01.2017 Sofia HD-INC000001463515
    select 1 into statoOrd
    from siac_r_ordinativo_stato r, siac_d_ordinativo_stato stato
    where r.ord_id=ritenutaRec.ord_id
    and   stato.ord_stato_id=r.ord_stato_id
    and   stato.ord_stato_code!=STATO_ORD_A
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

    -- 04.01.2017 Sofia HD-INC000001463515
    if statoOrd is null then
    	continue;
    end if;*/

    tipoRitenuta:=ritenutaRec.tipo_ritenuta;
	if mantieniDec=false then
	    numeroRitenuta:=lpad(ritenutaRec.ord_numero::varchar,7,'0');
    else
    	numeroRitenuta:=ritenutaRec.ord_numero::varchar;
    end if;


    strMessaggio:='Lettura ritenute. Importo.';
 	importoRitenuta:= fnc_mif_importo_ordinativo (  ritenutaRec.ord_id,ordTsDetTipoId,mantieniDec); -- 20.01.2016 Sofia ABI36
    ordRitenutaId:=ritenutaRec.ord_id;

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