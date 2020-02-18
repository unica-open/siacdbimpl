/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac_for.inseriscecapitolo (
)
RETURNS integer AS
$body$
DECLARE
    bilElemId integer := 0;
    bilElemIdIniz integer:=40908870;
BEGIN
--    RAISE NOTICE 'Quantity here is %', quantity;  -- Quantity here is 30
--    quantity := 50;
    --
    -- Create a subblock
    --


--        quantity integer := 80;
	insert into siac_t_bil_elem
	(elem_code,elem_code2,elem_code3, elem_desc,elem_desc2,
	 elem_id_padre,elem_tipo_id, bil_id,ordine,livello,
	 validita_inizio , ente_proprietario_id,data_creazione,login_operazione)
	(select capitolo.elem_code,capitolo.elem_code2,3,capitolo.elem_desc,capitolo.elem_desc2,
           capitolo.elem_id_padre,capitolo.elem_tipo_id,capitolo.bil_id,capitolo.ordine,capitolo.livello,
           CURRENT_TIMESTAMP,capitolo.ente_proprietario_id,CURRENT_TIMESTAMP,capitolo.login_operazione
	 from siac_t_bil_elem capitolo
 	 where capitolo.elem_id=bilElemIdIniz)
     returning elem_id into bilElemId ;

     RAISE NOTICE 'Capitolo id=%', bilElemId;
	 insert into siac_r_bil_elem_stato
     (elem_id,elem_stato_id,validita_inizio,ente_proprietario_id,
     data_creazione,login_operazione)
     (select bilElemId,capitoloStato.elem_stato_id,CURRENT_TIMESTAMP,capitoloStato.ente_proprietario_id,capitoloStato.login_operazione
     from  siac_r_bil_elem_stato capitoloStato
     where capitoloStato.elem_id= bilElemIdIniz);

     RAISE NOTICE 'Capitolo Stato inserito ';
	insert into siac_r_bil_elem_attr 
    (elem_id,attr_id,tabella_id,boolean,percentuale,testo,numerico,validita_inizio,
     ente_proprietario_id,data_creazione,login_operazione)
    (select bilElemId,capitoloAttr.attr_id,capitoloAttr.tabella_id,
            capitoloAttr.boolean,capitoloAttr.percentuale,capitoloAttr.testo,capitoloAttr.numerico,
            CURRENT_TIMESTAMP,
	        capitoloAttr.ente_proprietario_id,CURRENT_TIMESTAMP,capitoloAttr.login_operazione
     from siac_r_bil_elem_attr capitoloAttr
     where capitoloAttr.elem_id= bilElemIdIniz and 
     	   capitoloAttr.validita_fine is null);
     
     RAISE NOTICE 'Capitolo attributi inseriti ';
	 return bilElemId;
--    RAISE NOTICE 'Quantity here is %', quantity;  -- Quantity here is 50

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;