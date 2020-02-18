/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_associato( ordinativoId integer,
														 relazTipoOrd varchar,
                                                         ordinativoTipoId integer,
                                                         ordTsDetTipoId integer,
                                                         enteProprietarioId integer,
                                                         dataElaborazione timestamp,
                                                         dataFineVal timestamp)
RETURNS table
(
    numeroOrdAssociato varchar,
    annoOrdAssociato   varchar,
    importoOrdAssociato varchar,
    ordAssociatoId integer

) AS
$body$
DECLARE

strMessaggio varchar(1500):=null;

ordinativoRec record;

BEGIN

 numeroOrdAssociato:=null;
 annoOrdAssociato:=null;
 importoOrdAssociato:=null;
 ordAssociatoId:=null;

 strMessaggio:='Lettura ordinativi associati.';

 for ordinativoRec in
 (select rord.ord_id_a ord_id, ord.ord_numero numeroOrd, per.anno annoOrd
  from siac_r_ordinativo rOrd, siac_d_relaz_tipo tipo, siac_t_ordinativo ord,
       siac_t_bil bil,siac_t_periodo per
  where rord.ord_id_da=ordinativoId
  and   rord.data_cancellazione is null
  and   rord.validita_fine is null
  and   tipo.relaz_tipo_id=rord.relaz_tipo_id
  and   tipo.relaz_tipo_code=coalesce(relazTipoOrd,tipo.relaz_tipo_code)
  and   tipo.data_cancellazione is null
  and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
  and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal))
  and   ord.ord_id=rord.ord_id_a
  and   ord.ord_tipo_id=ordinativoTipoId
  and   ord.data_cancellazione is null
  and   ord.validita_fine is null
  and   bil.bil_id=ord.bil_id
  and   per.periodo_id=bil.periodo_id
  order by rord.ord_id_a
 )
 loop

 	numeroOrdAssociato:=null;
    annoOrdAssociato:=null;
    importoOrdAssociato:=null;
    ordAssociatoId:=null;


    numeroOrdAssociato:=lpad(ordinativoRec.numeroOrd::varchar,7,'0');
    annoOrdAssociato:=ordinativoRec.annoOrd;
    strMessaggio:='Lettura ordinativo associato. Importo.';
 	importoOrdAssociato:= fnc_mif_importo_ordinativo (  ordinativoRec.ord_id,ordTsDetTipoId);
    ordAssociatoId:=ordinativoRec.ord_id;

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