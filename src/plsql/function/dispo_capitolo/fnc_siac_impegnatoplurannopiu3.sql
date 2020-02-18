/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatoplurannopiu3 (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE
number_out numeric;

BEGIN
select det.elem_det_importo
into number_out from siac_t_bil_elem_det det,
siac_t_bil_elem el where el.elem_id=det.elem_id
and
el.elem_id=id_in;


number_out:=5000;
return number_out;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;