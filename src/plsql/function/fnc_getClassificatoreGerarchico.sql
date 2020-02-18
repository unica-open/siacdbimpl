/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 17.02.2014 Sofia
-- Lettura dei dati relativi ad una famiglia di Classificatore generico gerarchico
-- Parametri
-- Ente Proprietario --> (OBB)
-- codiceFamiglia    --> (FAC) codice della famiglia di appartenenza
-- descriFamiglia    --> (FAC) descrizione della famiglia di appartenza
-- uno fra codiceFamiglia, descriFamiglia deve essere indicato
-- codiceClassif     --> (FAC) codice del particolare classificatore ricercato
-- se non è passato codiceClassif è restituito l'elenco intero di classificatori appartenenti dalla famiglia
-- ricercata in ordine gerarchico padre,figlio
-- è restituo un TABLE
-- elenco dei dati relativi alla famiglia gerarchica ( n-records )
-- un solo record nel caso in cui sia passato codiceClassif
CREATE OR REPLACE FUNCTION fnc_getClassificatoreGerarchico(enteProprietarioId integer,
														   codiceFamiglia varchar,descriFamiglia varchar,
														   codiceClassif varchar)
RETURNS TABLE (
  classif_classif_fam_tree_id integer,
  classif_fam_tree_id integer,
  classif_code varchar,
  classif_desc varchar,
  classif_tipo_desc varchar,
  classif_id integer,
  classif_id_padre integer,
  ordine varchar,
  level integer
) AS
$body$
DECLARE

rec record;
begin

	for rec in
		SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
		       t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
		       tb.ordine, tb.level
		FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
			   classif_id, classif_id_padre, ordine, livello, level, arrhierarchy) AS (
			    SELECT rt1.classif_classif_fam_tree_id,
                       rt1.classif_fam_tree_id, rt1.classif_id,
                       rt1.classif_id_padre, rt1.ordine, rt1.livello, 1,
                       ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
				FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1,siac_d_class_fam classFam
				WHERE tt1.classif_fam_tree_id = rt1.classif_fam_tree_id AND
			          rt1.classif_id_padre IS NULL AND
                      tt1.data_cancellazione is null and
                      date_trunc('seconds',CURRENT_TIMESTAMP)>= date_trunc('seconds',rt1.validita_inizio) and
					  (date_trunc('seconds',CURRENT_TIMESTAMP)< date_trunc('seconds',rt1.validita_fine)
                        or rt1.validita_fine is null )and
			          tt1.classif_fam_id=classFam.classif_fam_id and
                      ( codiceFamiglia is null or classFam.classif_fam_code=codiceFamiglia ) and
                      ( descriFamiglia is null or classFam.classif_fam_desc=descriFamiglia)
	    		UNION ALL
			    SELECT tn.classif_classif_fam_tree_id,
        		       tn.classif_fam_tree_id, tn.classif_id,
		               tn.classif_id_padre, tn.ordine, tn.livello,
        		       tp.level + 1, tp.arrhierarchy || tn.classif_id
		    	FROM rqname tp, siac_r_class_fam_tree tn
			    WHERE tp.classif_id = tn.classif_id_padre and
                	  tn.data_cancellazione is null and
                      date_trunc('seconds',CURRENT_TIMESTAMP)>= date_trunc('seconds',tn.validita_inizio) and
					  (date_trunc('seconds',CURRENT_TIMESTAMP)< date_trunc('seconds',tn.validita_fine)
                        or tn.validita_fine is null )
	   		)
		    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
    		       rqname.classif_id, rqname.classif_id_padre, rqname.ordine,
            	   rqname.livello, rqname.level,rqname.arrhierarchy
	  		       FROM rqname
		    ORDER BY rqname.arrhierarchy
    	   ) tb, siac_t_class t1,  siac_d_class_tipo ti1
		WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id = t1.classif_tipo_id and
		      t1.ente_proprietario_id=enteProprietarioId and
              (codiceClassif is null or t1.classif_code=codiceClassif) and
              t1.data_cancellazione is null and
              date_trunc('seconds',CURRENT_TIMESTAMP)>= date_trunc('seconds',t1.validita_inizio) and
			  (date_trunc('seconds',CURRENT_TIMESTAMP)< date_trunc('seconds',t1.validita_fine)
                       or t1.validita_fine is null )

   loop

    classif_classif_fam_tree_id :=rec.classif_classif_fam_tree_id;
	classif_fam_tree_id:=rec.classif_fam_tree_id;
	classif_code:=rec.classif_code;
	classif_desc:=rec.classif_desc;
	classif_tipo_desc:=rec.classif_tipo_desc;
	classif_id:=rec.classif_id;
	classif_id_padre:=rec.classif_id_padre;
	ordine:=rec.ordine;
	level:=rec.level;

--	classif_desc:='@'||classif_desc;
   	return next;

   end loop;
exception
	when no_data_found THEN
	raise notice 'nessun dato trovato';
	return;
	when others  THEN
	raise notice 'altro errore';
	return;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;