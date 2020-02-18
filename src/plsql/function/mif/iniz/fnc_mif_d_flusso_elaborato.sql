/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_mif_d_flusso_elaborato
(  flussoElabMifTipoId integer,flussoElabMifCampo varchar ,enteProprietarioId integer,
   out flussoElabMifId integer,
   out flussoElabMifAttivo boolean,
   out flussoElabMifDef varchar,
   out flussoElabMifElab boolean,
   out flussoElabMifParam varchar
)
RETURNS record AS
$body$
DECLARE

strMessaggio varchar(1500):=null;


BEGIN

 strMessaggio:='Lettura configurazione campo '||flussoElabMifCampo||'.';

 flussoElabMifId :=null;
 flussoElabMifAttivo :=false;
 flussoElabMifDef :=null;
 flussoElabMifElab :=false;
 flussoElabMifParam :=null;

 select mif.flusso_elab_mif_id,
        mif.flusso_elab_mif_attivo,mif.flusso_elab_mif_default,
        mif.flusso_elab_mif_elab,mif.flusso_elab_mif_param
        into flussoElabMifId,flussoElabMifAttivo, flussoElabMifDef,flussoElabMifElab,flussoElabMifParam
 from mif_d_flusso_elaborato mif
 where mif.flusso_elab_mif_tipo_id=flussoElabMifTipoId
   and mif.flusso_elab_mif_campo=flussoElabMifCampo
   and mif.ente_proprietario_id=enteProprietarioId
   and mif.data_cancellazione is null;



 return;


exception
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;