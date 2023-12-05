/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
REATE OR REPLACE FUNCTION fnc_mif_ordinativo_informazioni_tes( ordinativoId integer,
														    notetesId INTEGER,
                                                       	    enteProprietarioId integer,
                                                            dataElaborazione timestamp,
                                                            dataFineVal timestamp)
RETURNS varchar AS
$body$
DECLARE

strMessaggio varchar(1500):=null;


cartaContRec record;
informazioniTes varchar(1000):=null;
informazioniTesTemp varchar(500):='CARTE CONTABILI ';

numCarte integer:=0;
BEGIN

 strMessaggio:='Lettura informazioni tesoriere.';


 strMessaggio:='Lettura informazioni tesoriere.Lettura carte contabili collegate.';

 for cartaContRec in
 ( select cartaCont.cartac_numero::varchar numeroCarta
   from siac_t_cartacont cartaCont ,
     (select rCartaDet.cartac_id
      from siac_t_cartacont_det rCartaDet, siac_r_cartacont_det_subdoc rcarta, siac_r_subdoc_ordinativo_ts subdoc,
           siac_t_ordinativo_ts ordts
       where   rcarta.cartac_det_id=rcartadet.cartac_det_id
         and   subdoc.subdoc_id=rcarta.subdoc_id
         and   ordts.ord_ts_id=subdoc.ord_ts_id
         and   ordts.ord_id=ordinativoId
         and   rCartaDet.data_cancellazione is null
         and   rCartaDet.validita_fine is null
         and   rcarta.data_cancellazione is null
         and   rcarta.validita_fine is null
         and   subdoc.data_cancellazione is null
         and   subdoc.validita_fine is null
         and   ordts.data_cancellazione is null
         and   ordts.validita_fine is null
      ) rel
   where cartaCont.ente_proprietario_id=enteProprietarioId
	 and cartaCont.data_cancellazione is null
	 and cartaCont.validita_fine is null
	 and rel.cartac_id=cartaCont.cartac_id
   order by cartaCont.cartac_id
 )
 loop
 	 exit when length(informazioniTesTemp)+length(cartaContRec.numeroCarta)>=150;
     informazioniTesTemp:=informazioniTesTemp||' '||cartaContRec.numeroCarta;
     numCarte:=numCarte+1;
 end loop;

 if numCarte>=1 then
    informazioniTes:=informazioniTesTemp;
    if length(informazioniTesTemp)>150 then
    	informazioniTes:=substring(informazioniTesTemp from 1 for 150);
    	return informazioniTes;
    end if;
 end if;

 informazioniTesTemp:=null;
 if notetesId is not null then
 /*	27.11.2015 Sofia spostate in dati a disposizione ente
    strMessaggio:='Lettura informazioni tesoriere.Lettura note tesoriere [siac_d_note_tesoriere]';

 	select note.notetes_desc into informazioniTesTemp
    from siac_d_note_tesoriere note
    where note.notetes_id=notetesId
    and   note.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',note.validita_inizio)
  	and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(note.validita_fine,dataFineVal));*/

    strMessaggio:='Lettura informazioni tesoriere.Lettura attributo note ordinativo [siac_r_ordinativo_attr]';
    select attr.testo into informazioniTesTemp
    from siac_r_ordinativo_attr attr
    where attr.ord_attr_id=notetesId;

 end if;

 if informazioniTesTemp is not null then
 	if informazioniTes is not null then
	 	informazioniTes:=informazioniTes||'.'||informazioniTesTemp;
    else
	    informazioniTes:=informazioniTesTemp;
    end if;

    if length(informazioniTes)>150 then
    	informazioniTes:=substring(informazioniTes from 1 for 150);
    end if;
 end if;

 return informazioniTes;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 1000),'');
        return informazioniTes;
    when TOO_MANY_ROWS THEN
        RAISE EXCEPTION '% Diverse righe lette.',coalesce(strMessaggio,'');
        return informazioniTes;
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',coalesce(strMessaggio,'');
        return informazioniTes;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',coalesce(strMessaggio,''),SQLSTATE,substring(SQLERRM from 1 for 1000);
        return informazioniTes;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;