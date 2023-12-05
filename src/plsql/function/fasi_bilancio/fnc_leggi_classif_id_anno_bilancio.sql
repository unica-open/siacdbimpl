/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_leggi_classif_id_anno_bilancio (
  cl_id integer,
  anno_bilancio integer
)
RETURNS integer AS
$body$
DECLARE

	ret_classif_id integer;

BEGIN

  select n.classif_id INTO ret_classif_id
    from siac_t_class o, siac_t_class n
    where o.classif_id=cl_id
    and o.classif_tipo_id=n.classif_tipo_id
    and o.classif_code=n.classif_code
    and n.classif_id<>o.classif_id
    and n.validita_inizio>=DATE (anno_bilancio || '-01-01') 
    and (n.validita_fine IS NULL OR n.validita_fine<DATE (anno_bilancio+1 || '-01-01'))
    and n.data_cancellazione IS NULL;

  return ret_classif_id;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;









