/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_td_sac_crea_cdr (
  p_ente_proprietario_id integer,
  cdr_codice varchar,
  cdr_descrizione varchar,
  cdr_inizio_validita varchar,
  numero_incident varchar
)
RETURNS varchar AS
$body$
DECLARE
v_messaggiorisultato varchar;
classif_id_new siac_t_class.classif_id%type;
classif_classif_fam_tree_id_new siac_r_class_fam_tree.classif_classif_fam_tree_id%type;
login_operazione_new siac_r_variazione_stato.login_operazione%type;
data_creazione_new siac_r_variazione_stato.data_creazione%type;
BEGIN
v_messaggiorisultato :='Errore';


INSERT INTO siac_t_class(classif_code, classif_desc, validita_inizio,
 ente_proprietario_id, login_operazione, classif_tipo_id)
select cdr_codice,
       cdr_descrizione,
       to_timestamp(cdr_inizio_validita, 'dd/mm/yyyy'),
       a.ente_proprietario_id,
       numero_incident,
       a.classif_tipo_id
from siac_d_class_tipo a
where a.classif_tipo_code = 'CDR' and
      a.ente_proprietario_id = p_ente_proprietario_id and
      not exists (
                   select 1
                   from siac_t_class b
                   where b.classif_code = cdr_codice and
                         b.classif_tipo_id = a.classif_tipo_id
      )
returning classif_id, login_operazione,data_creazione  into classif_id_new,      
 login_operazione_new, data_creazione_new
      ;



INSERT INTO siac.siac_r_class_fam_tree(
classif_fam_tree_id, classif_id, ordine, livello, validita_inizio,  ente_proprietario_id, login_operazione)
select tc.classif_fam_tree_id,cdr.classif_id,cdr.classif_code, 1,
       cdr.validita_inizio, p_ente_proprietario_id,  numero_incident
from siac_t_class cdr,
     siac_d_class_tipo cdrt,
     siac_t_class_fam_tree tc
where cdr.classif_tipo_id = cdrt.classif_tipo_id and
      cdrt.classif_tipo_code = 'CDR' and
      cdr.classif_code = cdr_codice and
      cdr.ente_proprietario_id = p_ente_proprietario_id and
      tc.class_fam_code = 'Struttura Amministrativa Contabile'
      and tc.ente_proprietario_id=cdr.ente_proprietario_id
      and cdr.data_cancellazione is null 
      and cdrt.data_cancellazione is null 
      and tc.data_cancellazione is null 
      AND
      not exists (
                   select 1
                   from siac_r_class_fam_tree z
                   where z.classif_fam_tree_id = tc.classif_fam_tree_id and
                         z.classif_id = cdr.classif_id and
                         z.classif_id_padre is null
      )
returning 
siac_r_class_fam_tree.classif_classif_fam_tree_id
into 
classif_classif_fam_tree_id_new
;


    if classif_id_new is null and classif_classif_fam_tree_id_new is null then 
	    v_messaggiorisultato:='nessun dato aggiornato';
    elsif classif_id_new is not null and classif_classif_fam_tree_id_new is null then
 		RAISE EXCEPTION 'Impossibile creare il CDR, perchè impossibile inserire su siac_r_class_fam_tree'; 
    else 
        v_messaggiorisultato:= 'Eseguito inserimento del classif_id '||classif_id_new::varchar ||' nuovo classif_classif_fam_tree_id: '''||
        classif_classif_fam_tree_id_new::varchar||''' , eseguito da '''||login_operazione_new || ''' in data : ' ||data_creazione_new::varchar;        
    end if;
    
    return v_messaggiorisultato;
    
exception
    when RAISE_EXCEPTION THEN
    v_messaggiorisultato:=v_messaggiorisultato|| ' - ' ||substring(upper(SQLERRM) from 1 for 2500);
    	--raise notice '%',v_messaggiorisultato;
        return v_messaggiorisultato;
    when others  THEN
	v_messaggiorisultato:=v_messaggiorisultato|| ' others - ' ||substring(upper(SQLERRM) from 1 for 2500);
    	--raise notice '%',v_messaggiorisultato;
        return v_messaggiorisultato;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;
