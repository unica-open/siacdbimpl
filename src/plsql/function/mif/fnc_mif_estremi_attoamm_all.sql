/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_mif_estremi_attoamm_all(attoAmmId integer,attoAmmTipoAll varchar,
  									                   attoAmmStrCodeTipo varchar,
                                                       dataElaborazione timestamp, dataFineVal timestamp)
RETURNS varchar AS
$body$
DECLARE

strMessaggio varchar(1500):=null;

attoAmmAnno varchar(50):=null;
attoAmmNumero integer:=null;
enteProprietarioId integer :=null;

attoAmmStrCode varchar(50):=null;

attoAmmEstremi varchar(100):=null;
attoAmmTipoCode varchar(100):=null;

attoAmmTipoId integer := null;

CDR_CLASS  CONSTANT VARCHAR:='CDR';
CDC_CLASS  CONSTANT VARCHAR:='CDC';
BEGIN

 strMessaggio:='Lettura atto amm tipo '||attoAmmTipoAll||'.';



 strMessaggio:='Lettura estremi atto amm tipo '||attoAmmTipoAll||'.';
 select amm.attoamm_anno,amm.attoamm_numero,amm.ente_proprietario_id,amm.attoamm_tipo_id
        into attoAmmAnno,attoAmmNumero,enteProprietarioId, attoAmmTipoId
 from siac_t_atto_amm amm
 where amm.attoamm_id=attoAmmId
 and   amm.data_cancellazione is null
 and   amm.validita_fine is null;


 if attoAmmTipoId is  null then
  RAISE EXCEPTION ' Dati non reperiti.';
 end if;

 strMessaggio:='Lettura tipo code atto amm tipo '||attoAmmTipoAll||'.';
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

 if attoAmmTipoCode!=attoAmmTipoAll then
 	return attoAmmEstremi;
 end if;

 if attoAmmStrCodeTipo is null or attoAmmStrCodeTipo='' or
 	(attoAmmStrCodeTipo is not null and attoAmmStrCodeTipo!='' and attoAmmStrCodeTipo=CDR_CLASS) then
  strMessaggio:='Lettura Struttura Amm atto amm tipo '||attoAmmTipoAll||' per struttura tipo '||CDR_CLASS||'.';
  select cdr.classif_code into attoAmmStrCode
  from siac_r_atto_amm_class r, siac_t_class cdr,  siac_d_class_tipo tipo
  where r.attoamm_id=attoAmmId
  and   r.data_cancellazione is null
  and   r.validita_fine is null
  and   cdr.classif_id=r.classif_id
  and   cdr.data_cancellazione is null
--  and   date_trunc('day',dataElaborazione)>=date_trunc('day',cdr.validita_inizio) 19.01.2017
--  and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(cdr.validita_fine,dataFineVal)) 19.01.2017
  and   tipo.classif_tipo_id=cdr.classif_tipo_id
  and   tipo.classif_tipo_code=CDR_CLASS
  and   tipo.ente_proprietario_id=enteProprietarioId
  and   tipo.data_cancellazione is null
  and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
--  and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
  and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

 end if;

 if attoAmmStrCode is null and
    (attoAmmStrCodeTipo is null or attoAmmStrCodeTipo='' or
 	 (attoAmmStrCodeTipo is not null and attoAmmStrCodeTipo!='' and attoAmmStrCodeTipo=CDC_CLASS) ) then
    strMessaggio:='Lettura Struttura Amm atto amm tipo '||attoAmmTipoAll||' per struttura tipo '||CDC_CLASS||'.';
   	select cdr.classif_code into attoAmmStrCode
 	from siac_r_atto_amm_class r, siac_t_class cdr,  siac_d_class_tipo tipo
	where r.attoamm_id=attoAmmId
	and   r.data_cancellazione is null
    and   r.validita_fine is null
	and   cdr.classif_id=r.classif_id
	and   cdr.data_cancellazione is null
--	and   date_trunc('day',dataElaborazione)>=date_trunc('day',cdr.validita_inizio) 19.01.2017
--	and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(cdr.validita_fine,dataFineVal)) 19.01.2017
    and   tipo.classif_tipo_id=cdr.classif_tipo_id
    and   tipo.classif_tipo_code=CDC_CLASS
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
--    and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

 end if;


 if attoAmmStrCode is not null then
    	attoAmmEstremi:= attoAmmAnno||' '||attoAmmNumero||' '||attoAmmStrCode;
 else
        attoAmmEstremi:= attoAmmAnno||' '||attoAmmNumero;
 end if;


 return attoAmmEstremi;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 700),'');
        return attoAmmEstremi;
    when TOO_MANY_ROWS THEN
        RAISE EXCEPTION '% Diverse righe lette.',coalesce(strMessaggio,'');
        return attoAmmEstremi;
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',coalesce(strMessaggio,'');
        return attoAmmEstremi;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',coalesce(strMessaggio,''),SQLSTATE,substring(SQLERRM from 1 for 1000);
        return attoAmmEstremi;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;