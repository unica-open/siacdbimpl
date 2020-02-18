/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_mif_estremi_atto_amm(attoAmmId integer,attoAmmMovgId integer,
                                                    attoAmmTipoSpr varchar,attoAmmTipoAll varchar,
                                                    dataElaborazione timestamp, dataFineVal timestamp,
                                                    out attoAmmEstremi varchar,
                                                    out attoAmmOggetto varchar)
RETURNS record AS
$body$
DECLARE

strMessaggio varchar(1500):=null;

attoAmmAnno varchar(50):=null;
attoAmmNumero integer:=null;
attoAmmOggettoTmp varchar(500):=null;
attoAmmTipoId integer :=null;
enteProprietarioId integer :=null;
attoAmmTipoCode varchar(50):=null;

attoAmmOrdId integer :=null;
attoAmmStrCode varchar(50):=null;

CDR_CLASS  CONSTANT VARCHAR:='CDR';
CDC_CLASS  CONSTANT VARCHAR:='CDC';
BEGIN

 strMessaggio:='Lettura atto amm.';

 attoAmmEstremi :=null;
 attoAmmOggetto :=null;

 strMessaggio:='Lettura estremi atto amm.';
 select amm.attoamm_anno,amm.attoamm_numero,amm.attoamm_oggetto,amm.attoamm_tipo_id,amm.ente_proprietario_id
        into attoAmmAnno,attoAmmNumero,attoAmmOggettoTmp,attoAmmTipoId,enteProprietarioId
 from siac_t_atto_amm amm
 where amm.attoamm_id=attoAmmId
 and   amm.data_cancellazione is null
 and   amm.validita_fine is null;

 if attoAmmTipoId is  null then
  RAISE EXCEPTION ' Dati non reperiti.';
 end if;

 strMessaggio:='Lettura tipo atto amm.';
 select tipo.attoamm_tipo_code into attoAmmTipoCode
 from siac_d_atto_amm_tipo tipo
 where tipo.attoamm_tipo_id=attoAmmTipoId
 and   tipo.data_cancellazione is null
 and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
-- and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
 and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

 if attoAmmTipoCode is null then
  RAISE EXCEPTION ' Dati non reperiti.';
 end if;


 if attoAmmTipoCode=coalesce(attoAmmTipoSpr,' ') then
 	-- senza provvedimento
    null;
 elsif attoAmmTipoCode=coalesce(attoAmmTipoAll,' ') then
  if attoAmmMovgId is not null then
    attoAmmTipoId:=null;
    attoAmmAnno:=null;
    attoAmmNumero:=null;
    attoAmmOggettoTmp:=null;

    strMessaggio:='Lettura estremi atto amm movimento.';
  	select amm.attoamm_anno,amm.attoamm_numero,amm.attoamm_oggetto,amm.attoamm_tipo_id
      	  into attoAmmAnno,attoAmmNumero,attoAmmOggettoTmp,attoAmmTipoId
 	from siac_t_atto_amm amm
 	where amm.attoamm_id=attoAmmMovgId
    and   amm.data_cancellazione is null
    and   amm.validita_fine is null;

    if attoAmmTipoId is null then
    	RAISE EXCEPTION ' Dati non reperiti.';
    end if;

    strMessaggio:='Lettura tipo atto amm movimento.';
    select tipo.attoamm_tipo_code into attoAmmTipoCode
 	from siac_d_atto_amm_tipo tipo
	where tipo.attoamm_tipo_id=attoAmmTipoId
    and   tipo.data_cancellazione is null
 	and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
-- 	and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
 	and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

 	if attoAmmTipoCode is null then
 	 RAISE EXCEPTION ' Dati non reperiti.';
	end if;

    if attoAmmTipoCode!=attoAmmTipoSpr then
    	attoAmmOrdId:=attoAmmMovgId;
  	else
        -- senza provvedimento
    	null;
    end if;

  end if;
 else
 	attoAmmOrdId:=attoAmmId;
 end if;

 if attoAmmOrdId is not null then
    strMessaggio:='Lettura Struttura Amm atto amm tipo'||CDR_CLASS||'.';
 	select cdr.classif_code into attoAmmStrCode
    from siac_r_atto_amm_class r, siac_t_class cdr, siac_d_class_tipo tipo
    where r.attoamm_id=attoAmmOrdId
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   cdr.classif_id=r.classif_id
    and   cdr.data_cancellazione is null
-- 	and   date_trunc('day',dataElaborazione)>=date_trunc('day',cdr.validita_inizio) 19.01.2017
-- 	and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(cdr.validita_fine,dataFineVal)) 19.01.2017
    and   tipo.classif_tipo_id=cdr.classif_tipo_id
    and   tipo.classif_tipo_code=CDR_CLASS
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
--    and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

   if attoAmmStrCode is null then
    strMessaggio:='Lettura Struttura Amm atto amm tipo'||CDC_CLASS||'.';
   	select cdr.classif_code into attoAmmStrCode
    from siac_r_atto_amm_class r, siac_t_class cdr, siac_d_class_tipo tipo
    where r.attoamm_id=attoAmmOrdId
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   cdr.classif_id=r.classif_id
    and   cdr.data_cancellazione is null
-- 	and   date_trunc('day',dataElaborazione)>=date_trunc('day',cdr.validita_inizio) 19.01.2017
-- 	and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(cdr.validita_fine,dataFineVal)) 19.01.2017
    and   tipo.classif_tipo_id=cdr.classif_tipo_id
    and   tipo.classif_tipo_code=CDC_CLASS
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
 	and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
-- 	and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
 	and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

   end if;

 end if;

 if attoAmmOrdId is not null then
 	if attoAmmStrCode is not null then
    	attoAmmEstremi:= attoAmmTipoCode||' '||attoAmmStrCode||' N.'||attoAmmNumero||' DEL '||attoAmmAnno;
    else
        attoAmmEstremi:= attoAmmTipoCode||' N.'||attoAmmNumero||' DEL '||attoAmmAnno;
    end if;
    attoAmmOggetto:=attoAmmOggettoTmp;
 end if;

 return;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',quote_nullable(strMessaggio)||' '||quote_nullable(substring(upper(SQLERRM) from 1 for 700));
        return;
    when TOO_MANY_ROWS THEN
        RAISE EXCEPTION '% Diverse righe lette.',quote_nullable(strMessaggio);
        return;
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',quote_nullable(strMessaggio);
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',quote_nullable(strMessaggio),SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;