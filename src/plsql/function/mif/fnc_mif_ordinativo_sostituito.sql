/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_sostituito( ordSostituitivoId integer,
 														  ordRelazCodeTipoId INTEGER,
                                                          dataElaborazione timestamp,
                                                          dataFineVal timestamp,
														  out ordNumeroSostituto numeric,
                                                          out ordAnnoSostituto   integer)
RETURNS record AS
$body$
DECLARE

strMessaggio varchar(1500):=null;

ordSosId integer:=0;
ordAnno varchar(10):=null;
ordNumero numeric:=null;
BEGIN


 strMessaggio:='Lettura ordindativo sostituito.';

 ordNumeroSostituto:=null;
 ordAnnoSostituto:=null;

 select ord.ord_id_da into ordSosId
 from siac_r_ordinativo ord
 where ord.ord_id_a=ordSostituitivoId
 and   ord.relaz_tipo_id=ordRelazCodeTipoId
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null
 order by ord.ord_r_id
 limit 1;

 if ordSosId is not null then
 	select  ord.ord_numero, per.anno into ordNumero , ordAnno
    from siac_t_ordinativo ord, siac_t_bil bil , siac_t_periodo per
    where ord.ord_id=ordSosId
    and   ord.data_cancellazione is null
	and   ord.validita_fine is null
    and   bil.bil_id=ord.bil_id
    and   per.periodo_id=bil.periodo_id;
 end if;

 if ordNumero is not null and ordAnno is not null then
 	ordNumeroSostituto:=ordNumero;
    ordAnnoSostituto:=ordAnno;
 end if;

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