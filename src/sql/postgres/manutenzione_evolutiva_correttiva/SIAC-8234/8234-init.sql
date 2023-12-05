select fnc_siac_bko_inserisci_azione('OP-FLUSSO-TEFA', 'Gestione Flusso TEFA', 
	'/../siacintegser/ElaboraFileService', 'AZIONE_SECONDARIA', 'FIN_BASE2');
	

	
INSERT INTO siac_d_file_tipo
( file_tipo_code,
  file_tipo_desc,
  azione_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione)
SELECT 
	'FLUSSO_TEFA',
    'Flusso TEFA',
    (SELECT a.azione_id FROM siac_t_azione a 
    WHERE a.azione_code='OP-FLUSSO-TEFA' 
    AND a.ente_proprietario_id=e.ente_proprietario_id),
    NOW(),
    e.ente_proprietario_id,
	'admin'    
FROM siac_t_ente_proprietario e
WHERE NOT EXISTS (
	SELECT 1 FROM siac_d_file_tipo ft
    WHERE ft.file_tipo_code='FLUSSO_TEFA' 
    AND ft.ente_proprietario_id=e.ente_proprietario_id
);


-- Drop table

DROP TABLE if exists siac.siac_d_tefa_trib_tipologia;

CREATE TABLE if not exists siac_d_tefa_trib_tipologia (
	tefa_trib_tipologia_id serial NOT NULL,
	tefa_trib_tipologia_code varchar(50) NULL,
	tefa_trib_tipologia_desc varchar(250) NULL,
	validita_inizio timestamp NOT NULL DEFAULT now(),
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NULL,
	data_cancellazione timestamp NULL,
	login_operazione varchar(250) NULL,
	ente_proprietario_id int4 NOT NULL,
	CONSTRAINT pk_siac_d_tefa_trib_tipo PRIMARY KEY (tefa_trib_tipologia_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_tefa_trib_tipo FOREIGN KEY (ente_proprietario_id) REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
);
CREATE INDEX if not exists siac_d_tefa_trib_tipologia_fk_ente_proprietario_id_idx ON siac.siac_d_tefa_trib_tipologia USING btree (ente_proprietario_id);

DROP TABLE if exists siac.siac_d_tefa_tributo;

CREATE TABLE if not exists siac_d_tefa_tributo (
	tefa_trib_id serial NOT NULL,
	tefa_trib_code varchar(50) NULL,
	tefa_trib_desc varchar(250) NULL,
	tefa_trib_tipologia_id int4 NULL,
	validita_inizio timestamp NOT NULL DEFAULT now(),
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NULL,
	data_cancellazione timestamp NULL,
	login_operazione varchar(250) NULL,
	ente_proprietario_id int4 NOT NULL,
	CONSTRAINT pk_siac_d_tefa_trib PRIMARY KEY (tefa_trib_id),
	CONSTRAINT siac_d_tefa_trib_tipoologia_siac_d_tefa_tributo FOREIGN KEY (tefa_trib_tipologia_id) REFERENCES siac_d_tefa_trib_tipologia(tefa_trib_tipologia_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_tefa_trib FOREIGN KEY (ente_proprietario_id) REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
);
CREATE INDEX if not exists siac_d_tefa_tributo_fk_ente_proprietario_id_idx ON siac.siac_d_tefa_tributo USING btree (ente_proprietario_id);
CREATE INDEX if not exists siac_d_tefa_tributo_fk_siac_d_tefa_tipologia_idx ON siac.siac_d_tefa_tributo USING btree (tefa_trib_tipologia_id);

-- Drop table

DROP TABLE if exists siac.siac_d_tefa_trib_comune;

CREATE TABLE if not exists siac_d_tefa_trib_comune (
	tefa_trib_comune_id serial NOT NULL,
	tefa_trib_comune_code varchar(50) NULL,
	tefa_trib_comune_desc varchar(250) NULL,
	tefa_trib_comune_cat_code varchar(50) NULL,
	tefa_trib_comune_cat_desc varchar(250) NULL,
	validita_inizio timestamp NOT NULL DEFAULT now(),
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NULL,
	data_cancellazione timestamp NULL,
	login_operazione varchar(250) NULL,
	ente_proprietario_id int4 NOT NULL,
	CONSTRAINT pk_siac_d_tefa_trib_comune PRIMARY KEY (tefa_trib_comune_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_tefa_trib_comune FOREIGN KEY (ente_proprietario_id) REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
);
CREATE INDEX if not exists siac_d_tefa_trib_comune_fk_ente_proprietario_id_idx ON siac.siac_d_tefa_trib_comune USING btree (ente_proprietario_id);



-- Drop table

-- DROP TABLE siac.siac_d_tefa_trib_tipologia;

CREATE TABLE if not exists siac_d_tefa_trib_tipologia (
	tefa_trib_tipologia_id serial NOT NULL,
	tefa_trib_tipologia_code varchar(50) NULL,
	tefa_trib_tipologia_desc varchar(250) NULL,
	validita_inizio timestamp NOT NULL DEFAULT now(),
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NULL,
	data_cancellazione timestamp NULL,
	login_operazione varchar(250) NULL,
	ente_proprietario_id int4 NOT NULL,
	CONSTRAINT pk_siac_d_tefa_trib_tipo PRIMARY KEY (tefa_trib_tipologia_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_tefa_trib_tipo FOREIGN KEY (ente_proprietario_id) REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
);
CREATE INDEX if not exists siac_d_tefa_trib_tipologia_fk_ente_proprietario_id_idx ON siac.siac_d_tefa_trib_tipologia USING btree (ente_proprietario_id);

DROP TABLE if exists siac.siac_d_tefa_trib_gruppo_tipo;

CREATE TABLE IF NOT EXISTS siac_d_tefa_trib_gruppo_tipo (
	tefa_trib_gruppo_tipo_id serial NOT NULL,
	tefa_trib_gruppo_tipo_code varchar(10) NULL,
	tefa_trib_gruppo_tipo_desc varchar(50) NULL,
	tefa_trib_gruppo_tipo_f1_id int4 NULL,
	tefa_trib_gruppo_tipo_f2_id int4 NULL,
	tefa_trib_gruppo_tipo_f3_id int4 NULL,
	validita_inizio timestamp NOT NULL DEFAULT now(),
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NULL,
	data_cancellazione timestamp NULL,
	login_operazione varchar(250) NULL,
	ente_proprietario_id int4 NOT NULL,
	CONSTRAINT pk_siac_d_tefa_trib_gruppo_tipo PRIMARY KEY (tefa_trib_gruppo_tipo_id)
);

-- Drop table

DROP TABLE if exists siac.siac_d_tefa_trib_gruppo;

CREATE TABLE IF NOT EXISTS siac_d_tefa_trib_gruppo (
	tefa_trib_gruppo_id serial NOT NULL,
	tefa_trib_gruppo_code varchar(50) NULL,
	tefa_trib_gruppo_desc varchar(250) NULL,
	tefa_trib_gruppo_anno varchar(50) NULL,
	tefa_trib_gruppo_f1_id int4 NULL,
	tefa_trib_gruppo_f2_id int4 NULL,
	tefa_trib_gruppo_f3_id int4 NULL,
	tefa_trib_tipologia_id int4 NOT NULL,
	tefa_trib_gruppo_tipo_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL DEFAULT now(),
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NULL,
	data_cancellazione timestamp NULL,
	login_operazione varchar(250) NULL,
	ente_proprietario_id int4 NOT NULL,
	CONSTRAINT pk_siac_d_tefa_trib_gruppo PRIMARY KEY (tefa_trib_gruppo_id)
);



-- Drop table

DROP TABLE if exists siac.siac_r_tefa_tributo_gruppo;

CREATE TABLE if not exists siac_r_tefa_tributo_gruppo (
	tefa_trib_gruppo_r_id serial NOT NULL,
	tefa_trib_id int4 NOT NULL,
	tefa_trib_gruppo_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL DEFAULT now(),
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NULL,
	data_cancellazione timestamp NULL,
	login_operazione varchar(250) NULL,
	ente_proprietario_id int4 NOT NULL,
	CONSTRAINT pk_siac_r_tefa_trib_gruooi PRIMARY KEY (tefa_trib_gruppo_r_id),
	CONSTRAINT siac_d_tefa_trib_gruppo_siac_r_tefa_trib_gruppo FOREIGN KEY (tefa_trib_gruppo_id) REFERENCES siac_d_tefa_trib_gruppo(tefa_trib_gruppo_id),
	CONSTRAINT siac_d_tefa_trib_siac_r_tefa_trib_gruppo FOREIGN KEY (tefa_trib_id) REFERENCES siac_d_tefa_tributo(tefa_trib_id),
	CONSTRAINT siac_t_ente_proprietario_siac_r_tefa_trib_gruppo FOREIGN KEY (ente_proprietario_id) REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
);
CREATE INDEX if not exists siac_r_tefa_trib_gruppo_fk_ente_proprietario_id_idx ON siac.siac_r_tefa_tributo_gruppo USING btree (ente_proprietario_id);
CREATE INDEX if not exists siac_r_tefa_trib_gruppo_fk_siac_d_tefa_trib_gruppo_idx ON siac.siac_r_tefa_tributo_gruppo USING btree (tefa_trib_gruppo_id);
CREATE INDEX if not exists siac_r_tefa_trib_gruppo_fk_siac_d_tefa_trib_idx ON siac.siac_r_tefa_tributo_gruppo USING btree (tefa_trib_id);


-- Drop table

DROP TABLE if exists siac.siac_t_tefa_trib_gruppo_upload;

CREATE TABLE IF NOT EXISTS siac_t_tefa_trib_gruppo_upload (
	tefa_trib_gruppo_upload_id serial NOT NULL,
	tefa_trib_file_id int4 NOT NULL,
	tefa_trib_gruppo_tipo_id int4 NULL,
	tefa_trib_gruppo_id int4 NULL,
	tefa_trib_gruppo_upload varchar(250) NULL,
	validita_inizio timestamp NOT NULL DEFAULT now(),
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NULL,
	data_cancellazione timestamp NULL,
	login_operazione varchar(250) NULL,
	ente_proprietario_id int4 NOT NULL,
	CONSTRAINT pk_siac_t_tefa_trib_gruppo_upd PRIMARY KEY (tefa_trib_gruppo_upload_id),
	CONSTRAINT siac_d_tefa_trib_gruppo_siac_t_tefa_trib_gruppo_upd FOREIGN KEY (tefa_trib_gruppo_id) REFERENCES siac_d_tefa_trib_gruppo(tefa_trib_gruppo_id),
	CONSTRAINT siac_d_tefa_trib_gruppo_tipo_siac_t_tefa_trib_gruppo_upd FOREIGN KEY (tefa_trib_gruppo_tipo_id) REFERENCES siac_d_tefa_trib_gruppo_tipo(tefa_trib_gruppo_tipo_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_tefa_trib_gruppo_upd FOREIGN KEY (ente_proprietario_id) REFERENCES siac_t_ente_proprietario(ente_proprietario_id),
	CONSTRAINT siac_t_file_siac_t_tefa_trib_gruppo_upd FOREIGN KEY (tefa_trib_file_id) REFERENCES siac_t_file(file_id)
);
CREATE INDEX IF NOT EXISTS siac_t_tefa_trib_gruppo_upd_fk_ente_proprietario_id_idx ON siac.siac_t_tefa_trib_gruppo_upload USING btree (ente_proprietario_id);
CREATE INDEX IF NOT EXISTS siac_t_tefa_trib_gruppo_upd_fk_tefa_trib_gruppo_idx ON siac.siac_t_tefa_trib_gruppo_upload USING btree (tefa_trib_gruppo_id);
CREATE INDEX IF NOT EXISTS siac_t_tefa_trib_gruppo_upd_fk_tefa_trib_gruppo_tipo_idx ON siac.siac_t_tefa_trib_gruppo_upload USING btree (tefa_trib_gruppo_tipo_id);
CREATE INDEX IF NOT EXISTS siac_t_tefa_trib_gruppo_upd_tefa_trib_upload_id_idx ON siac.siac_t_tefa_trib_gruppo_upload USING btree (tefa_trib_file_id);

-- Drop table

--DROP TABLE siac.siac_t_tefa_trib_importi;

CREATE TABLE IF NOT EXISTS siac_t_tefa_trib_importi (
	tefa_trib_id serial NOT NULL,
	tefa_trib_tipo_record varchar(50) NULL,
	tefa_trib_data_ripart varchar(50) NULL,
	tefa_trib_progr_ripart varchar(250) NULL,
	tefa_trib_provincia_code varchar(100) NULL,
	tefa_trib_ente_code varchar(100) NULL,
	tefa_trib_data_bonifico varchar(50) NULL,
	tefa_trib_progr_trasm varchar(250) NULL,
	tefa_trib_progr_delega varchar(250) NULL,
	tefa_trib_progr_modello varchar(250) NULL,
	tefa_trib_tipo_modello varchar(100) NULL,
	tefa_trib_comune_code varchar(100) NULL,
	tefa_trib_tributo_code varchar(100) NULL,
	tefa_trib_valuta varchar(50) NULL,
	tefa_trib_importo_versato_deb numeric NULL,
	tefa_trib_importo_compensato_cred numeric NULL,
	tefa_trib_numero_immobili varchar(100) NULL,
	tefa_trib_rateazione varchar(100) NULL,
	tefa_trib_anno_rif varchar(50) NULL,
	tefa_trib_anno_rif_str varchar(50) NULL,
	tefa_trib_file_id int4 NOT NULL,
	tefa_nome_file varchar(255) NOT NULL,
	validita_inizio timestamp NOT NULL DEFAULT now(),
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NULL,
	data_cancellazione timestamp NULL,
	login_operazione varchar(250) NULL,
	ente_proprietario_id int4 NOT NULL,
	CONSTRAINT pk_siac_t_tefa_trib PRIMARY KEY (tefa_trib_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_tefa_trib_imp FOREIGN KEY (ente_proprietario_id) REFERENCES siac_t_ente_proprietario(ente_proprietario_id),
	CONSTRAINT siac_t_file_siac_t_tefa_trib_imp FOREIGN KEY (tefa_trib_file_id) REFERENCES siac_t_file(file_id)
);
CREATE INDEX IF NOT EXISTS  siac_t_tefa_trib_fk_ente_proprietario_id_idx ON siac.siac_t_tefa_trib_importi USING btree (ente_proprietario_id);
CREATE INDEX IF NOT EXISTS  siac_t_tefa_trib_fk_upload_id_idx ON siac.siac_t_tefa_trib_importi USING btree (tefa_trib_file_id);






/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--drop FUNCTION if exists siac.fnc_tefa_trib_raggruppamento( p_tefa_trib_gruppo_id integer);
drop FUNCTION if exists siac.fnc_tefa_trib_raggruppamento_all( p_tefa_trib_gruppo_tipo_id integer,p_tefa_trib_gruppo_id integer);

CREATE OR REPLACE FUNCTION siac.fnc_tefa_trib_raggruppamento_all( p_tefa_trib_gruppo_tipo_id integer,p_tefa_trib_gruppo_id integer)
RETURNS TEXT AS
$body$
DECLARE

elenco_trib text:=null;
rec_trib record;
BEGIN


for rec_trib IN
(
WITH
gruppi as
(
select trib.tefa_trib_code,gruppo.tefa_trib_gruppo_anno
from siac_r_tefa_tributo_gruppo r_tefa,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo
where gruppo.tefa_trib_gruppo_tipo_id=coalesce(p_tefa_trib_gruppo_tipo_id,gruppo.tefa_trib_gruppo_tipo_id)
and   gruppo.tefa_trib_gruppo_id=coalesce(p_tefa_trib_gruppo_id,gruppo.tefa_trib_gruppo_id)
and   r_tefa.tefa_trib_id=trib.tefa_trib_id
and   gruppo.tefa_trib_gruppo_id=r_tefa.tefa_trib_gruppo_id
and   r_tefa.data_cancellazione is null
and   r_tefa.validita_fine is null
and   trib.data_cancellazione is null
and   trib.validita_fine is null
and   gruppo.data_cancellazione is null
and   gruppo.validita_fine is null
order by 1 desc
)
select gruppi.tefa_trib_code,gruppi.tefa_trib_gruppo_anno
from gruppi
order by 1 desc
)
loop
 elenco_trib:= coalesce(elenco_trib,' ')||rec_trib.tefa_trib_code||'-';

end loop;

if elenco_trib is not null then
 elenco_trib:=trim(both from substring(elenco_trib,1,length(elenco_trib)-1));
end if;

return elenco_trib;


exception
	when others  THEN
 	RAISE EXCEPTION ' Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
    return elenco_trib;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;




/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--drop FUNCTION if exists siac.fnc_tefa_trib_raggruppamento( p_tefa_trib_gruppo_id integer);
drop FUNCTION if exists siac.fnc_tefa_trib_raggruppamento( p_tefa_trib_gruppo_tipo_id integer,p_tefa_trib_gruppo_id integer,p_tefa_trib_upload_id integer);

CREATE OR REPLACE FUNCTION siac.fnc_tefa_trib_raggruppamento(p_tefa_trib_gruppo_tipo_id integer, p_tefa_trib_gruppo_id integer, p_tefa_trib_upload_id integer)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE

elenco_trib text:=null;
rec_trib record;
BEGIN


for rec_trib IN
(
with 
raggruppa_sel as
(
select gruppo.tefa_trib_gruppo_anno, trib.tefa_trib_code
from siac_r_tefa_tributo_gruppo r_tefa,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo
where gruppo.tefa_trib_gruppo_tipo_id=coalesce(p_tefa_trib_gruppo_tipo_id,gruppo.tefa_trib_gruppo_tipo_id)
and   gruppo.tefa_trib_gruppo_id=coalesce(p_tefa_trib_gruppo_id,gruppo.tefa_trib_gruppo_id)
and   r_tefa.tefa_trib_id=trib.tefa_trib_id
and   gruppo.tefa_trib_gruppo_id=r_tefa.tefa_trib_gruppo_id
and  trib.data_cancellazione is null
and  trib.validita_fine is null
and  gruppo.data_cancellazione is null
and  gruppo.validita_fine is null
and  r_tefa.data_cancellazione is null
and  r_tefa.validita_fine is null
),
tefa_sel as
(
select trib_imp.tefa_trib_tributo_code, trib_imp.tefa_trib_anno_rif_str
from siac_t_tefa_trib_importi trib_imp
where trib_imp.tefa_trib_file_id=p_tefa_trib_upload_id
and   trib_imp.tefa_trib_tipo_record='D'
and   trib_imp.data_cancellazione is null
and   trib_imp.validita_fine is null
)
select  distinct raggruppa_sel.tefa_trib_code 
from raggruppa_sel, tefa_sel 
where tefa_sel.tefa_trib_tributo_code=raggruppa_sel.tefa_trib_code
and   tefa_sel.tefa_trib_anno_rif_str=raggruppa_sel.tefa_trib_gruppo_anno
order by 1 DESC
/*select distinct trib.tefa_trib_code
from siac_r_tefa_tributo_gruppo r_tefa,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo,
     siac_t_tefa_trib_importi trib_imp
where gruppo.tefa_trib_gruppo_tipo_id=coalesce(p_tefa_trib_gruppo_tipo_id,gruppo.tefa_trib_gruppo_tipo_id)
and   gruppo.tefa_trib_gruppo_id=coalesce(p_tefa_trib_gruppo_id,gruppo.tefa_trib_gruppo_id)
and   r_tefa.tefa_trib_id=trib.tefa_trib_id
and   gruppo.tefa_trib_gruppo_id=r_tefa.tefa_trib_gruppo_id
and   trib_imp.ente_proprietario_id=gruppo.ente_proprietario_id
and   trib_imp.tefa_trib_file_id=p_tefa_trib_upload_id
and   trib_imp.tefa_trib_tributo_code=trib.tefa_trib_code
and   trib_imp.tefa_trib_tipo_record='D'
and   gruppo.tefa_trib_gruppo_anno=trib_imp.tefa_trib_anno_rif_str*/
/*     ( case when trib_imp.tefa_trib_anno_rif::INTEGER<=2019 then '<=2019'
           when trib_imp.tefa_trib_anno_rif::INTEGER=2020 then '=2020'
           when trib_imp.tefa_trib_anno_rif::INTEGER>=2021 then '>=2021' end )*/
/*and  trib.data_cancellazione is null
and  trib.validita_fine is null
and  trib_imp.data_cancellazione is null
and  trib_imp.validita_fine is null
and  gruppo.data_cancellazione is null
and  gruppo.validita_fine is null
and  r_tefa.data_cancellazione is null
and  r_tefa.validita_fine is null
order by 1 DESC*/
)
loop
-- raise notice 'tefa_trib_code=%',rec_trib.tefa_trib_code;
 elenco_trib:= coalesce(elenco_trib,' ')||rec_trib.tefa_trib_code||'-';
-- raise notice 'elenco_trib=%',elenco_trib;

end loop;

if elenco_trib is not null then
 elenco_trib:=trim(both from substring(elenco_trib,1,length(elenco_trib)-1));
end if;

return elenco_trib;


exception
	when others  THEN
 	RAISE EXCEPTION ' Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
    return elenco_trib;
END;
$function$
;






/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop FUNCTION if exists siac.fnc_tefa_trib_calcolo_formule(p_tefa_trib_formula_id integer, p_tefa_trib_importo numeric);

CREATE OR REPLACE FUNCTION siac.fnc_tefa_trib_calcolo_formule(p_tefa_trib_formula_id integer, p_tefa_trib_importo numeric)
 RETURNS numeric
 LANGUAGE plpgsql
AS $function$
DECLARE

tefa_trib_importo numeric:=0;

BEGIN


case coalesce(p_tefa_trib_formula_id,0)
  when 1 then  -- ARROTONDA((C/100)*5/105;5)
--    tefa_trib_importo:=round((p_tefa_trib_importo/100)*5/105,5);
    tefa_trib_importo:=round((p_tefa_trib_importo)*5/105,5);
  when 2 then  -- ARROTONDA((C/100);5)
--    tefa_trib_importo:=round((p_tefa_trib_importo/100),5);
    tefa_trib_importo:=round((p_tefa_trib_importo),5);
  when 3 then  -- ARROTONDA(H*0,3/100;5)
--    tefa_trib_importo:=round((p_tefa_trib_importo*0.3/100),5);
    tefa_trib_importo:=round((p_tefa_trib_importo/100*0.3),5);   
  else   tefa_trib_importo:=null;
end case;

return tefa_trib_importo;


exception
	when others  THEN
 	RAISE EXCEPTION ' Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
    return tefa_trib_importo;
END;
$function$
;


--' and   com.ente_proprietario_id='||p_ente_proprietario_id::varchar||
--' and   com.tefa_trib_comune_code=tefa.tefa_trib_comune_code

CREATE OR REPLACE FUNCTION siac.fnc_tefa_trib_comune_anno_rif_estrai(p_ente_proprietario_id integer, p_tefa_trib_upload_id integer, p_tefa_trib_comune_anno integer)
 RETURNS TABLE(codice_comune character varying, raggruppamento_codice_tributo character varying, importo_a_debito_versato numeric, importo_a_credito_compensato numeric, anno_di_riferimento_str character varying, ente character varying, anno_di_riferimento character varying, tipologia character varying, importo_tefa_lordo numeric, importo_credito numeric, importo_comm numeric, importo_tefa_netto numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE

annoPrec integer;
annoPrecPrec integer;

sql_query text;

BEGIN

 raise notice 'p_ente_proprietario_id=%',p_ente_proprietario_id::varchar;
 raise notice 'p_tefa_trib_upload_id=%',p_tefa_trib_upload_id::varchar;
 raise notice 'p_tefa_trib_comune_anno=%',p_tefa_trib_comune_anno::varchar;

 annoPrecPrec:=p_tefa_trib_comune_anno-2;
 annoPrec:=p_tefa_trib_comune_anno-1;

 raise notice 'annoPrecPrec=%',annoPrecPrec::varchar;
 raise notice 'annoPrec=%',annoPrec::varchar;

 sql_query:=
 'select query.codice_comune::varchar,
       upd.tefa_trib_gruppo_upload::varchar raggruppamento_codice_tributo,
       query.importo_a_debito_versato::numeric,
       query.importo_a_credito_compensato::numeric,
       query.anno_di_riferimento_str::varchar,
       query.ente::varchar,
       query.anno_di_riferimento::varchar,
       query.tipologia::varchar,
       query.importo_tefa_lordo::numeric,
       query.importo_credito::numeric,
       query.importo_comm::numeric,
       query.importo_tefa_netto::numeric
 from
 (

 with 
 raggruppa_sel as
 (
 select tipo.tefa_trib_tipologia_code,
        tipo.tefa_trib_tipologia_desc,
        gruppo.tefa_trib_gruppo_code,
        gruppo.tefa_trib_gruppo_desc,
        gruppo.tefa_trib_gruppo_anno,
        gruppo.tefa_trib_gruppo_f1_id,
        gruppo.tefa_trib_gruppo_f2_id,
        gruppo.tefa_trib_gruppo_f3_id,
        trib.tefa_trib_code,
        trib.tefa_trib_desc,
        trib.tefa_trib_id,
        gruppo.tefa_trib_gruppo_id,        
        tipo.tefa_trib_tipologia_id
 from  siac_d_tefa_tributo trib,siac_r_tefa_tributo_gruppo r_gruppo,
       siac_d_tefa_trib_gruppo gruppo,siac_d_tefa_trib_tipologia tipo
  where trib.ente_proprietario_id='||p_ente_proprietario_id::varchar||
' and  r_gruppo.tefa_trib_id=trib.tefa_trib_id
  and  gruppo.tefa_trib_gruppo_id=r_gruppo.tefa_trib_gruppo_id
  and  tipo.tefa_trib_tipologia_id=gruppo.tefa_trib_tipologia_id
  and  trib.data_cancellazione is null
  and  trib.validita_fine is null
  and  gruppo.data_cancellazione is null
  and  gruppo.validita_fine is null
  and  tipo.data_cancellazione is null
  and  tipo.validita_fine is null
  and  r_gruppo.data_cancellazione is null
  and  r_gruppo.validita_fine is null
 ),
 tefa_sel as 
 (
 select tefa.tefa_trib_file_id,
        tefa.tefa_trib_tributo_code,
        tefa.tefa_trib_comune_code,
        tefa.tefa_trib_importo_versato_deb,
        tefa.tefa_trib_importo_compensato_cred,
        tefa.tefa_trib_anno_rif_str,
		tefa.tefa_trib_anno_rif,
        com.tefa_trib_comune_cat_desc
 from siac_t_tefa_trib_importi tefa 
      left join siac_d_tefa_trib_comune com on (com.ente_proprietario_id=tefa.ente_proprietario_id and com.tefa_trib_comune_code=tefa.tefa_trib_comune_code and com.data_cancellazione is null )
 where tefa.ente_proprietario_id='||p_ente_proprietario_id::varchar||      
' and   tefa.tefa_trib_file_id='||p_tefa_trib_upload_id::varchar||
' and   tefa.tefa_trib_tipo_record=''D''
 and   tefa.data_cancellazione is null
 and   tefa.validita_fine is null
 )
 select
   tefa_sel.tefa_trib_file_id,
   tefa_sel.tefa_trib_comune_code codice_comune,
   raggruppa_sel.tefa_trib_gruppo_id ,
   raggruppa_sel.tefa_trib_gruppo_code,
   sum(tefa_sel.tefa_trib_importo_versato_deb) importo_a_debito_versato,
   sum(tefa_sel.tefa_trib_importo_compensato_cred)    importo_a_credito_compensato,
   ( case when tefa_sel.tefa_trib_anno_rif::INTEGER<='||annoPrecPrec::VARCHAR||' then ''<='||annoPrecPrec::VARCHAR||''''||
          ' when tefa_sel.tefa_trib_anno_rif::INTEGER='||annoPrec::varchar||' then ''''''='||annoPrec::varchar||''''||
          ' when tefa_sel.tefa_trib_anno_rif::INTEGER>='||p_tefa_trib_comune_anno::varchar||' then ''>='||p_tefa_trib_comune_anno::varchar||''''||
          ' end ) anno_di_riferimento_str,
   tefa_sel.tefa_trib_comune_cat_desc ente,
  (case when tefa_sel.tefa_trib_anno_rif::integer<='||annoPrecPrec::VARCHAR||' then '||annoPrecPrec::VARCHAR||
   	     ' when tefa_sel.tefa_trib_anno_rif::integer='||annoPrec::varchar||' then tefa_sel.tefa_trib_anno_rif::integer
           when tefa_sel.tefa_trib_anno_rif::integer>='||p_tefa_trib_comune_anno::varchar||' then tefa_sel.tefa_trib_anno_rif::integer else null end ) anno_di_riferimento,   
   raggruppa_sel.tefa_trib_tipologia_desc tipologia,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa_sel.tefa_trib_importo_versato_deb)
                                 ) importo_tefa_lordo,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa_sel.tefa_trib_importo_compensato_cred)
                                  ) importo_credito,
   fnc_tefa_trib_calcolo_formule((case
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f3_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f3_id
                                   else null
                                   end
                                  ),
                                  fnc_tefa_trib_calcolo_formule
                                  (
                                  (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                   ),
                                   sum(tefa_sel.tefa_trib_importo_versato_deb))
                                )  importo_comm,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa_sel.tefa_trib_importo_versato_deb)) -
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa_sel.tefa_trib_importo_compensato_cred)) -
   fnc_tefa_trib_calcolo_formule((case
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f3_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f3_id
                                   else null
                                   end
                                  ),fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa_sel.tefa_trib_importo_versato_deb) )
                                  ) importo_tefa_netto
from  raggruppa_sel , tefa_sel
where raggruppa_sel.tefa_trib_code=tefa_sel.tefa_trib_tributo_code
  and raggruppa_sel.tefa_trib_gruppo_anno=tefa_sel.tefa_trib_anno_rif_str
group by tefa_sel.tefa_trib_file_id,
	     tefa_sel.tefa_trib_comune_code,
         raggruppa_sel.tefa_trib_gruppo_id,
		 raggruppa_sel.tefa_trib_gruppo_code,
         raggruppa_sel.tefa_trib_gruppo_f1_id,raggruppa_sel.tefa_trib_gruppo_f2_id,raggruppa_sel.tefa_trib_gruppo_f3_id,
		 ( case when tefa_sel.tefa_trib_anno_rif::INTEGER<='||annoPrecPrec::VARCHAR||' then ''<='||annoPrecPrec::VARCHAR||''''||
          ' when tefa_sel.tefa_trib_anno_rif::INTEGER='||annoPrec::varchar||' then ''''''='||annoPrec::varchar||''''||
          ' when tefa_sel.tefa_trib_anno_rif::INTEGER>='||p_tefa_trib_comune_anno::varchar||' then ''>='||p_tefa_trib_comune_anno::varchar||''''||
          ' end ),
         tefa_sel.tefa_trib_comune_cat_desc,
         (case when tefa_sel.tefa_trib_anno_rif::integer<='||annoPrecPrec::VARCHAR||' then '||annoPrecPrec::VARCHAR||
   	     ' when tefa_sel.tefa_trib_anno_rif::integer='||annoPrec::varchar||' then tefa_sel.tefa_trib_anno_rif::integer
           when tefa_sel.tefa_trib_anno_rif::integer>='||p_tefa_trib_comune_anno::varchar||' then tefa_sel.tefa_trib_anno_rif::integer else null end ),
         raggruppa_sel.tefa_trib_tipologia_desc
order by 2,4
) query,siac_t_tefa_trib_gruppo_upload upd
where upd.tefa_trib_file_id=query.tefa_trib_file_id
and   upd.tefa_trib_gruppo_id=query.tefa_trib_gruppo_id
and   upd.data_cancellazione is null 
and   upd.validita_fine is null
order by 1,query.tefa_trib_gruppo_code::integer;'::text;

raise notice 'sql_query=%',sql_query::varchar;
return query execute sql_query;

exception
	when no_data_found THEN
    raise notice 'Nessun dato trovato.';
	when others  THEN
 	RAISE EXCEPTION ' Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
    return;
END;
$function$
;




/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


drop FUNCTION if exists siac.fnc_tefa_trib_comune_estrai(p_ente_proprietario_id integer, p_tefa_trib_upload_id integer, p_tefa_trib_comune_anno integer);

CREATE OR REPLACE FUNCTION siac.fnc_tefa_trib_comune_estrai(p_ente_proprietario_id integer, p_tefa_trib_upload_id integer, p_tefa_trib_comune_anno integer)
 RETURNS TABLE(codice_comune character varying, raggruppamento_codice_tributo character varying, importo_a_debito_versato numeric, importo_a_credito_compensato numeric, anno_di_riferimento_str character varying, ente character varying, tipologia character varying, importo_tefa_lordo numeric, importo_credito numeric, importo_comm numeric, importo_tefa_netto numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE

annoPrec integer;
annoPrecPrec integer;

sql_query text;

BEGIN

 raise notice 'p_ente_proprietario_id=%',p_ente_proprietario_id::varchar;
 raise notice 'p_tefa_trib_upload_id=%',p_tefa_trib_upload_id::varchar;
 raise notice 'p_tefa_trib_comune_anno=%',p_tefa_trib_comune_anno::varchar;

 annoPrecPrec:=p_tefa_trib_comune_anno-2;
 annoPrec:=p_tefa_trib_comune_anno-1;

 raise notice 'annoPrecPrec=%',annoPrecPrec::varchar;
 raise notice 'annoPrec=%',annoPrec::varchar;

 sql_query:=
 'select query.codice_comune::varchar,
       upd.tefa_trib_gruppo_upload::varchar raggruppamento_codice_tributo,
       query.importo_a_debito_versato::numeric,
       query.importo_a_credito_compensato::numeric,
       query.anno_di_riferimento_str::varchar,
       query.ente::varchar,
       query.tipologia::varchar,
       query.importo_tefa_lordo::numeric,
       query.importo_credito::numeric,
       query.importo_comm::numeric,
       query.importo_tefa_netto::numeric
 from
 (

select
    tefa.tefa_trib_file_id,
    tefa.tefa_trib_comune_code codice_comune,
    gruppo.tefa_trib_gruppo_id ,
    sum(tefa.tefa_trib_importo_versato_deb) importo_a_debito_versato,
    sum(tefa.tefa_trib_importo_compensato_cred)    importo_a_credito_compensato,
   ( case when tefa.tefa_trib_anno_rif::INTEGER<='||annoPrecPrec::VARCHAR||' then ''<='||annoPrecPrec::VARCHAR||''''||
          ' when tefa.tefa_trib_anno_rif::INTEGER='||annoPrec::varchar||' then ''''''='||annoPrec::varchar||''''||
          ' when tefa.tefa_trib_anno_rif::INTEGER>='||p_tefa_trib_comune_anno::varchar||' then ''>='||p_tefa_trib_comune_anno::varchar||''''||
          ' end ) anno_di_riferimento_str,
   com.tefa_trib_comune_cat_desc ente,
   tipo.tefa_trib_tipologia_desc tipologia,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa.tefa_trib_importo_versato_deb)
                                 ) importo_tefa_lordo,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa.tefa_trib_importo_compensato_cred)
                                  ) importo_credito,
   fnc_tefa_trib_calcolo_formule((case
                                   when coalesce(gruppo.tefa_trib_gruppo_f3_id,0)!=0 then gruppo.tefa_trib_gruppo_f3_id
                                   else null
                                   end
                                  ),
                                  fnc_tefa_trib_calcolo_formule
                                  (
                                  (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                   ),
                                   sum(tefa.tefa_trib_importo_versato_deb))
                                )  importo_comm,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa.tefa_trib_importo_versato_deb)) -
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa.tefa_trib_importo_compensato_cred)) -
   fnc_tefa_trib_calcolo_formule((case
                                   when coalesce(gruppo.tefa_trib_gruppo_f3_id,0)!=0 then gruppo.tefa_trib_gruppo_f3_id
                                   else null
                                   end
                                  ),fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa.tefa_trib_importo_versato_deb) )
                                  ) importo_tefa_netto
from siac_t_tefa_trib_importi tefa,siac_d_tefa_trib_comune com,
     siac_d_tefa_tributo trib,siac_r_tefa_tributo_gruppo r_gruppo,
     siac_d_tefa_trib_gruppo gruppo,siac_d_tefa_trib_tipologia tipo
where tefa.ente_proprietario_id='||p_ente_proprietario_id::varchar||
' and   tefa.tefa_trib_file_id='||p_tefa_trib_upload_id::varchar||
' and   com.ente_proprietario_id='||p_ente_proprietario_id::varchar||
' and   com.tefa_trib_comune_code=tefa.tefa_trib_comune_code
  and   trib.ente_proprietario_id='||p_ente_proprietario_id::varchar||
' and   trib.tefa_trib_code=tefa.tefa_trib_tributo_code
  and   r_gruppo.tefa_trib_id=trib.tefa_trib_id
  and   gruppo.tefa_trib_gruppo_id=r_gruppo.tefa_trib_gruppo_id
  and   gruppo.tefa_trib_gruppo_anno=
       ( case when tefa.tefa_trib_anno_rif::INTEGER<='||annoPrecPrec::varchar||' then ''<='||annoPrecPrec::varchar||''''||
       '   when tefa.tefa_trib_anno_rif::INTEGER='||annoPrec::varchar||' then ''='||annoPrec::varchar||''''||
       '   when tefa.tefa_trib_anno_rif::INTEGER>='||p_tefa_trib_comune_anno::VARCHAR||' then ''>='||p_tefa_trib_comune_anno::VARCHAR||''' end )
  and   tipo.tefa_trib_tipologia_id=gruppo.tefa_trib_tipologia_id
  and   tefa.tefa_trib_tipo_record=''D''
  and   tefa.data_cancellazione is null
  and   tefa.validita_fine is null
  and   r_gruppo.data_cancellazione is null
  and   r_gruppo.validita_fine is null
  group by tefa.tefa_trib_file_id,
	     tefa.tefa_trib_comune_code,
         gruppo.tefa_trib_gruppo_id,
         gruppo.tefa_trib_gruppo_f1_id,gruppo.tefa_trib_gruppo_f2_id,gruppo.tefa_trib_gruppo_f3_id,
		 ( case when tefa.tefa_trib_anno_rif::INTEGER<='||annoPrecPrec::VARCHAR||' then ''<='||annoPrecPrec::VARCHAR||''''||
          ' when tefa.tefa_trib_anno_rif::INTEGER='||annoPrec::varchar||' then ''''''='||annoPrec::varchar||''''||
          ' when tefa.tefa_trib_anno_rif::INTEGER>='||p_tefa_trib_comune_anno::varchar||' then ''>='||p_tefa_trib_comune_anno::varchar||''''||
          ' end ),
         com.tefa_trib_comune_cat_desc,
         tipo.tefa_trib_tipologia_desc
order by 2,3
) query,siac_t_tefa_trib_gruppo_upload upd
where upd.tefa_trib_file_id=query.tefa_trib_file_id
and   upd.tefa_trib_gruppo_id=query.tefa_trib_gruppo_id
order by 1,query.tefa_trib_gruppo_id;'::text;

raise notice 'sql_query=%',sql_query::varchar;
return query execute sql_query;

exception
	when no_data_found THEN
    raise notice 'Nessun dato trovato.';
	when others  THEN
 	RAISE EXCEPTION ' Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
    return;
END;
$function$
;





/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop FUNCTION if exists siac.fnc_tefa_trib_versamenti_estrai(p_ente_proprietario_id integer,p_tefa_trib_upload_id integer, p_tefa_trib_comune_anno integer);

CREATE OR REPLACE FUNCTION siac.fnc_tefa_trib_versamenti_estrai(p_ente_proprietario_id integer, p_tefa_trib_upload_id integer, p_tefa_trib_comune_anno integer)
 RETURNS TABLE(data_ripartizione character varying, data_bonifico character varying, raggruppamento_codice_tributo character varying, importo_a_debito_versato numeric, importo_a_credito_compensato numeric, anno_di_riferimento_str character varying, importo_tefa_lordo numeric, importo_credito numeric, importo_comm numeric, importo_tefa_netto numeric)
 LANGUAGE plpgsql
AS $function$ DECLARE  annoPrec integer; annoPrecPrec integer;  sql_query text;  BEGIN   raise notice 'p_ente_proprietario_id=%',p_ente_proprietario_id::varchar;  raise notice 'p_tefa_trib_upload_id=%',p_tefa_trib_upload_id::varchar;  raise notice 'p_tefa_trib_comune_anno=%',p_tefa_trib_comune_anno::varchar;   annoPrecPrec:=p_tefa_trib_comune_anno-2;  annoPrec:=p_tefa_trib_comune_anno-1;   raise notice 'annoPrecPrec=%',annoPrecPrec::varchar;  raise notice 'annoPrec=%',annoPrec::varchar;   sql_query:=   'select query.data_ripartizione::varchar,           query.data_bonifico::varchar,           upd.tefa_trib_gruppo_upload::varchar raggruppamento_codice_tributo,           query.importo_a_debito_versato::numeric,           query.importo_a_credito_compensato::numeric,           query.anno_di_riferimento_str::varchar,           query.importo_tefa_lordo::numeric,           query.importo_credito::numeric,           query.importo_comm::numeric,           query.importo_tefa_netto::numeric   from   (    with   raggruppa_sel as    (    select trib.tefa_trib_code, trib.tefa_trib_desc,           gruppo.tefa_trib_gruppo_code,           gruppo.tefa_trib_gruppo_desc,           gruppo.tefa_trib_gruppo_f1_id,           gruppo.tefa_trib_gruppo_f2_id,           gruppo.tefa_trib_gruppo_f3_id,           gruppo.tefa_trib_gruppo_anno, 	      tipo.tefa_trib_gruppo_tipo_code, 	      tipo.tefa_trib_gruppo_tipo_desc,  	      tipo.tefa_trib_gruppo_tipo_f1_id, 	      tipo.tefa_trib_gruppo_tipo_f2_id, 	      tipo.tefa_trib_gruppo_tipo_f3_id	, 	      trib.tefa_trib_id, 	      gruppo.tefa_trib_gruppo_id, 	      gruppo.tefa_trib_gruppo_tipo_id    from siac_d_tefa_tributo trib,siac_r_tefa_tributo_gruppo r_gruppo,         siac_d_tefa_trib_gruppo gruppo,siac_d_tefa_trib_gruppo_tipo tipo    where trib.ente_proprietario_id='||p_ente_proprietario_id::varchar|| '  and   r_gruppo.tefa_trib_id=trib.tefa_trib_id    and   gruppo.tefa_trib_gruppo_id=r_gruppo.tefa_trib_gruppo_id    and   tipo.tefa_trib_gruppo_tipo_id=gruppo.tefa_trib_gruppo_tipo_id    and   trib.data_cancellazione is null    and   trib.validita_fine is null    and   gruppo.data_cancellazione is null     and   gruppo.validita_fine is null     and   tipo.data_cancellazione is null     and   tipo.validita_fine is null     and   r_gruppo.data_cancellazione is null    and   r_gruppo.validita_fine  is null   ), '|| ' tefa_sel as    (   select tefa.tefa_trib_file_id ,tefa.tefa_trib_tributo_code,tefa.tefa_trib_data_ripart,tefa.tefa_trib_data_bonifico,tefa.tefa_trib_anno_rif,tefa.tefa_trib_anno_rif_str,          tefa.tefa_trib_importo_versato_deb,tefa.tefa_trib_importo_compensato_cred   from  siac_t_tefa_trib_importi tefa   where tefa.ente_proprietario_id='||p_ente_proprietario_id::varchar|| ' and   tefa.tefa_trib_file_id='||p_tefa_trib_upload_id::varchar|| ' and   tefa.tefa_trib_tipo_record=''D''   and   tefa.data_cancellazione is null    and   tefa.validita_fine is null    ) '||  ' select    tefa_sel.tefa_trib_file_id,    (case when tefa_sel.tefa_trib_data_ripart like '''||chr(37)||'-'||chr(37)||''' then               tefa_sel.tefa_trib_data_ripart           else              substring(tefa_sel.tefa_trib_data_ripart,7,4)||''/''||substring(tefa_sel.tefa_trib_data_ripart,4,2)||''/''||substring(tefa_sel.tefa_trib_data_ripart,1,2)     end)::timestamp  data_ripartizione_dt,    (case when tefa_sel.tefa_trib_data_bonifico like '''||chr(37)||'-'||chr(37)||''' then               tefa_sel.tefa_trib_data_bonifico           else              substring(tefa_sel.tefa_trib_data_bonifico,7,4)||''/''||substring(tefa_sel.tefa_trib_data_bonifico,4,2)||''/''||substring(tefa_sel.tefa_trib_data_bonifico,1,2)     end)::timestamp  data_bonifico_dt,    (case when tefa_sel.tefa_trib_data_ripart like '''||chr(37)||'-'||chr(37)||''' then          substring(tefa_sel.tefa_trib_data_ripart,9,2)||''/''||substring(tefa_sel.tefa_trib_data_ripart,6,2)||''/''||substring(tefa_sel.tefa_trib_data_ripart,1,4)          else      tefa_sel.tefa_trib_data_ripart end)  data_ripartizione,    (case when tefa_sel.tefa_trib_data_bonifico like '''||chr(37)||'-'||chr(37)||''' then          substring(tefa_sel.tefa_trib_data_bonifico,9,2)||''/''||substring(tefa_sel.tefa_trib_data_bonifico,6,2)||''/''||substring(tefa_sel.tefa_trib_data_bonifico,1,4)          else      tefa_sel.tefa_trib_data_bonifico end)  data_bonifico,    raggruppa_sel.tefa_trib_gruppo_tipo_id,    tefa_sel.tefa_trib_anno_rif_str anno_di_riferimento_str,    sum(tefa_sel.tefa_trib_importo_versato_deb) importo_a_debito_versato ,    sum(tefa_sel.tefa_trib_importo_compensato_cred)    importo_a_credito_compensato,    fnc_tefa_trib_calcolo_formule( (case      							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f1_id                                    when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f2_id                                    else null                                    end                                   ),                                   sum(tefa_sel.tefa_trib_importo_versato_deb)                                  ) importo_tefa_lordo ,    fnc_tefa_trib_calcolo_formule( (case      							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f1_id                                    when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f2_id                                    else null                                    end                                   ),                                   sum(tefa_sel.tefa_trib_importo_compensato_cred)                                  ) importo_credito,    fnc_tefa_trib_calcolo_formule( (case      							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f3_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f3_id                                    else null                                    end                                   ),                                   fnc_tefa_trib_calcolo_formule( (case      							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f1_id                                    when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f2_id                                    else null                                    end                                   ),                                   sum(tefa_sel.tefa_trib_importo_versato_deb)                                  )                                  ) importo_comm,    fnc_tefa_trib_calcolo_formule( (case      							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f1_id                                    when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f2_id                                    else null                                    end                                   ),                                   sum(tefa_sel.tefa_trib_importo_versato_deb)                                  ) -   fnc_tefa_trib_calcolo_formule( (case      							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f1_id                                    when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f2_id                                    else null                                    end                                   ),                                   sum(tefa_sel.tefa_trib_importo_compensato_cred)                                  ) -  (  fnc_tefa_trib_calcolo_formule( (case      							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f3_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f3_id                                    else null                                    end                                   ),                                   fnc_tefa_trib_calcolo_formule( (case      							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f1_id                                    when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f2_id                                    else null                                    end                                   ),                                   sum(tefa_sel.tefa_trib_importo_versato_deb)                                  )                                  )  ) importo_tefa_netto from tefa_sel, raggruppa_sel where raggruppa_sel.tefa_trib_code=tefa_sel.tefa_trib_tributo_code and   raggruppa_sel.tefa_trib_gruppo_anno=tefa_sel.tefa_trib_anno_rif_str group by tefa_sel.tefa_trib_file_id, 	     tefa_sel.tefa_trib_data_ripart,          tefa_sel.tefa_trib_data_bonifico,          raggruppa_sel.tefa_trib_gruppo_tipo_id,          raggruppa_sel.tefa_trib_gruppo_tipo_f1_id,raggruppa_sel.tefa_trib_gruppo_tipo_f2_id,raggruppa_sel.tefa_trib_gruppo_tipo_f3_id,          tefa_sel.tefa_trib_anno_rif_str order by 2,3,raggruppa_sel.tefa_trib_gruppo_tipo_id ) query,siac_t_tefa_trib_gruppo_upload upd where upd.tefa_trib_file_id=query.tefa_trib_file_id and   upd.tefa_trib_gruppo_tipo_id=query.tefa_trib_gruppo_tipo_id order by query.data_ripartizione_dt,query.data_bonifico_dt,          query.tefa_trib_gruppo_tipo_id;'::text;  raise notice 'sql_query=%',sql_query::varchar;  return query execute sql_query;  exception 	when no_data_found THEN     raise notice 'Nessun dato trovato.'; 	when others  THEN  	RAISE EXCEPTION ' Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);     return; END; $function$
;



-- /////////////////////////////








insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '16','>=2021 TARI','>=2021',4,2,2,NULL,5, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TARI'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='5'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='16' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );


insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '17','>=2021 TARI INTERESSI','>=2021',5,2,2,null,5, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TARI INTERESSI'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='5'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='17' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
			
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '18','>=2021 TARI SANZIONE','>=2021',6,2,2,null,5, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TARI SANZIONE'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='5'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='18' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
            












-- siac_d_tefa_trib_tipologia
INSERT INTO siac.siac_d_tefa_trib_tipologia
(tefa_trib_tipologia_code, tefa_trib_tipologia_desc, validita_inizio, login_operazione, ente_proprietario_id)
select 'TEFA', 'TEFA', now(), 'SIAC-8206', ente.ente_proprietario_id
from siac_t_ente_proprietario ente 
where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
and   not exists 
(
select 1 
from siac_d_tefa_trib_tipologia tefa
where tefa.ente_proprietario_id=ente.ente_proprietario_id
and   tefa.tefa_trib_tipologia_code='TEFA'
and   tefa.data_cancellazione is null
and   tefa.validita_fine is null
);

INSERT INTO siac.siac_d_tefa_trib_tipologia
(tefa_trib_tipologia_code, tefa_trib_tipologia_desc, validita_inizio, login_operazione, ente_proprietario_id)
select 'INTERESSI', 'INTERESSI', now(),'SIAC-8206', ente.ente_proprietario_id
from siac_t_ente_proprietario ente 
where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
and   not exists 
(
select 1 
from siac_d_tefa_trib_tipologia tefa
where tefa.ente_proprietario_id=ente.ente_proprietario_id
and   tefa.tefa_trib_tipologia_code='INTERESSI'
and   tefa.data_cancellazione is null
and   tefa.validita_fine is null
);

INSERT INTO siac.siac_d_tefa_trib_tipologia
(tefa_trib_tipologia_code, tefa_trib_tipologia_desc, validita_inizio, login_operazione, ente_proprietario_id)
select 'SANZIONE', 'SANZIONE', now(), 'SIAC-8206', ente.ente_proprietario_id
from siac_t_ente_proprietario ente 
where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
and   not exists 
(
select 1 
from siac_d_tefa_trib_tipologia tefa
where tefa.ente_proprietario_id=ente.ente_proprietario_id
and   tefa.tefa_trib_tipologia_code='SANZIONE'
and   tefa.data_cancellazione is null
and   tefa.validita_fine is null
);

INSERT INTO siac.siac_d_tefa_trib_tipologia
(tefa_trib_tipologia_code, tefa_trib_tipologia_desc, validita_inizio, login_operazione, ente_proprietario_id)
select 'TARI', 'TARI', now(), 'SIAC-8206', ente.ente_proprietario_id
from siac_t_ente_proprietario ente 
where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
and   not exists 
(
select 1 
from siac_d_tefa_trib_tipologia tefa
where tefa.ente_proprietario_id=ente.ente_proprietario_id
and   tefa.tefa_trib_tipologia_code='TARI'
and   tefa.data_cancellazione is null
and   tefa.validita_fine is null
);

INSERT INTO siac.siac_d_tefa_trib_tipologia
(tefa_trib_tipologia_code, tefa_trib_tipologia_desc, validita_inizio, login_operazione, ente_proprietario_id)
Select 'TARI INTERESSI', 'TARI INTERESSI', now(), 'SIAC-8206', ente.ente_proprietario_id
from siac_t_ente_proprietario ente 
where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
and   not exists 
(
select 1 
from siac_d_tefa_trib_tipologia tefa
where tefa.ente_proprietario_id=ente.ente_proprietario_id
and   tefa.tefa_trib_tipologia_code='TARI INTERESSI'
and   tefa.data_cancellazione is null
and   tefa.validita_fine is null
);

INSERT INTO siac.siac_d_tefa_trib_tipologia
(tefa_trib_tipologia_code, tefa_trib_tipologia_desc, validita_inizio, login_operazione, ente_proprietario_id)
Select 'TARI SANZIONE', 'TARI SANZIONE', now(), 'SIAC-8206', ente.ente_proprietario_id
from siac_t_ente_proprietario ente 
where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
and   not exists 
(
select 1 
from siac_d_tefa_trib_tipologia tefa
where tefa.ente_proprietario_id=ente.ente_proprietario_id
and   tefa.tefa_trib_tipologia_code='TARI SANZIONE'
and   tefa.data_cancellazione is null
and   tefa.validita_fine is null
);


--- siac_d_tefa_trib_gruppo_tipo
insert into siac_d_tefa_trib_gruppo_tipo 
 (tefa_trib_gruppo_tipo_code, tefa_trib_gruppo_tipo_desc,tefa_trib_gruppo_tipo_f1_id,tefa_trib_gruppo_tipo_f2_id, tefa_trib_gruppo_tipo_f3_id,validita_inizio,login_operazione,ente_proprietario_Id ) 
 select '1','1-2-3',1,1,3,now(),'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
 where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
 and   not exists
 (
 select 1
 from siac_d_tefa_trib_gruppo_tipo tipo
 where tipo.ente_proprietario_id=ente.ente_proprietario_id
 and   tipo.tefa_trib_gruppo_tipo_code='1' 
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
 );
insert into siac_d_tefa_trib_gruppo_tipo 
 (tefa_trib_gruppo_tipo_code, tefa_trib_gruppo_tipo_desc,tefa_trib_gruppo_tipo_f1_id,tefa_trib_gruppo_tipo_f2_id, tefa_trib_gruppo_tipo_f3_id,validita_inizio,login_operazione,ente_proprietario_Id ) 
 select '2','4-5-6',2,2,3,now(),'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
 where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
 and   not exists
 (
 select 1
 from siac_d_tefa_trib_gruppo_tipo tipo
 where tipo.ente_proprietario_id=ente.ente_proprietario_id
 and   tipo.tefa_trib_gruppo_tipo_code='2' 
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
 );
insert into siac_d_tefa_trib_gruppo_tipo 
 (tefa_trib_gruppo_tipo_code, tefa_trib_gruppo_tipo_desc,tefa_trib_gruppo_tipo_f1_id,tefa_trib_gruppo_tipo_f2_id, tefa_trib_gruppo_tipo_f3_id,validita_inizio,login_operazione,ente_proprietario_Id ) 
 select '3','7-12',1,1,3,now(),'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
 where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
 and   not exists
 (
 select 1
 from siac_d_tefa_trib_gruppo_tipo tipo
 where tipo.ente_proprietario_id=ente.ente_proprietario_id
 and   tipo.tefa_trib_gruppo_tipo_code='3' 
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
 );
insert into siac_d_tefa_trib_gruppo_tipo 
 (tefa_trib_gruppo_tipo_code, tefa_trib_gruppo_tipo_desc,tefa_trib_gruppo_tipo_f1_id,tefa_trib_gruppo_tipo_f2_id, tefa_trib_gruppo_tipo_f3_id,validita_inizio,login_operazione,ente_proprietario_Id ) 
 select '4','13-14-15',2,2,3,now(),'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
 where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
 and   not exists
 (
 select 1
 from siac_d_tefa_trib_gruppo_tipo tipo
 where tipo.ente_proprietario_id=ente.ente_proprietario_id
 and   tipo.tefa_trib_gruppo_tipo_code='4' 
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
 );
insert into siac_d_tefa_trib_gruppo_tipo 
 (tefa_trib_gruppo_tipo_code, tefa_trib_gruppo_tipo_desc,tefa_trib_gruppo_tipo_f1_id,tefa_trib_gruppo_tipo_f2_id, tefa_trib_gruppo_tipo_f3_id,validita_inizio,login_operazione,ente_proprietario_Id ) 
 select '5','16-17-18',1,1,3,now(),'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
 where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
 and   not exists
 (
 select 1
 from siac_d_tefa_trib_gruppo_tipo tipo
 where tipo.ente_proprietario_id=ente.ente_proprietario_id
 and   tipo.tefa_trib_gruppo_tipo_code='5' 
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
 );
insert into siac_d_tefa_trib_gruppo_tipo 
 (tefa_trib_gruppo_tipo_code, tefa_trib_gruppo_tipo_desc,tefa_trib_gruppo_tipo_f1_id,tefa_trib_gruppo_tipo_f2_id, tefa_trib_gruppo_tipo_f3_id,validita_inizio,login_operazione,ente_proprietario_Id ) 
 select '6','19-20-21',2,2,3,now(),'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
 where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
 and   not exists
 (
 select 1
 from siac_d_tefa_trib_gruppo_tipo tipo
 where tipo.ente_proprietario_id=ente.ente_proprietario_id
 and   tipo.tefa_trib_gruppo_tipo_code='6' 
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
 );

 -- siac_d_tefa_trib_gruppo
 insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) 
 select '1','<=2019 TEFA','<=2019',1,1,1,3,1, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TEFA'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='1'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='1' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) 
   select '2','<=2019 INTERESSI','<=2019',2,1,1,3,1, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='INTERESSI'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='1'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='2' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '3','<=2019 SANZIONE','<=2019',3,1,1,3,1, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='SANZIONE'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='1'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='3' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '4','<=2019 TEFA','<=2019',1,2,2,3,2, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TEFA'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='2'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='4' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '5','<=2019 INTERESSI','<=2019',2,2,2,3,2, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='INTERESSI'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='2'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='5' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '6','<=2019 SANZIONE','<=2019',3,2,2,3,2, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='SANZIONE'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='2'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='6' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '7','=2020 TEFA','=2020',1,1,1,3,3, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TEFA'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='3'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='7' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '8','=2020 INTERESSI','=2020',2,1,1,3,3, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='INTERESSI'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='3'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='8' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '9','=2020 SANZIONE','=2020',3,1,1,3,3, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='SANZIONE'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='3'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='9' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '10','=2020 TEFA','=2020',1,1,1,3,3, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TEFA'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='3'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='10' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '11','=2020 INTERESSI','=2020',2,1,1,3,3, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='INTERESSI'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='3'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='11' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '12','=2020 SANZIONE','=2020',3,1,1,3,3, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='SANZIONE'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='3'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='12' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '13','=2020 TEFA','=2020',1,2,2,3,4, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TEFA'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='4'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='13' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '14','=2020 INTERESSI','=2020',2,2,2,3,4, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='INTERESSI'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='4'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='14' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '15','=2020 SANZIONE','=2020',3,2,2,3,4, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='SANZIONE'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='4'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='15' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );



insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '19','>=2021 TEFA','>=2021',1,2,2,3,6, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TEFA'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='6'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='19' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '20','>=2021 INTERESSI','>=2021',2,2,2,3,6, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='INTERESSI'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='6'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='20' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '21','>=2021 SANZIONE','>=2021',3,2,2,3,6, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='SANZIONE'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='6'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='21' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );

insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '16','>=2021 TARI','>=2021',4,2,2,NULL,5, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TARI'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='5'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='16' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );

insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '17','>=2021 TARI INTERESSI','>=2021',5,2,2,null,5, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TARI INTERESSI'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='5'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='17' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
			
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '18','>=2021 TARI SANZIONE','>=2021',6,2,2,null,5, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TARI SANZIONE'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='5'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='18' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
            
            
            
            

insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '17','>=2021 TARI INTERESSI','>=2021',5,2,2,null,5, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TARI INTERESSI'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='5'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='17' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
			
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '18','>=2021 TARI SANZIONE','>=2021',6,2,2,null,5, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TARI SANZIONE'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='5'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='18' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
            
            
            
            

			
-- siac_d_tefa_tributo

insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '3920','3920', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='3920' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '3921','3921', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='3921' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '3922','3922', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='3922' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '3944','3944', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='3944' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '3945','3945', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='3945' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '3946','3946', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='3946' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '3950','3950', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='3950' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '3951','3951', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='3951' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '3952','3952', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='3952' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '365E','365E', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='365E' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '366E','366E', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='366E' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '367E','367E', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='367E' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '368E','368E', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='368E' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '369E','369E', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='369E' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '370E','370E', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='370E' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'TEFA','TEFA', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='TEFA' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'TEFN','TEFN', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='TEFN' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  
select 'TEFZ','TEFZ', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='TEFZ' and tefa.data_cancellazione is null and tefa.validita_fine is null );
			
-- siac_d_tefa_trib_comune
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A074','AGLIE''','A074','AGLIE'' (07044)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A074'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A109','AIRASCA','A109','AIRASCA (07166)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A109'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A117','ALA DI STURA','A117','ALA DI STURA (07117)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A117'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A157','ALBIANO D''IVREA','A157','ALBIANO D''IVREA (07073)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A157'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A199','ALICE SUPERIORE','A199','ALICE SUPERIORE (07102)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A199'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A218','ALMESE','A218','ALMESE (06963)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A218'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A221','ALPETTE','A221','ALPETTE (07056)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A221'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A222','ALPIGNANO','A222','ALPIGNANO (07204)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A222'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A275','ANDEZENO','A275','ANDEZENO (06979)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A275'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A282','ANDRATE','A282','ANDRATE (07089)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A282'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A295','ANGROGNA','A295','ANGROGNA (07174)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A295'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A405','ARIGNANO','A405','ARIGNANO (06980)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A405'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A518','AVIGLIANA','A518','AVIGLIANA (06959)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A518'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A525','AZEGLIO','A525','AZEGLIO (07072)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A525'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A584','BAIRO','A584','BAIRO (07045)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A584'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A587','BALANGERO','A587','BALANGERO (07108)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A587'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A590','BALDISSERO CANAVESE','A590','BALDISSERO CANAVESE (07048)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A590'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A591','BALDISSERO TORINESE','A591','BALDISSERO TORINESE (06981)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A591'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A599','BALME','A599','BALME (07118)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A599'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A607','BANCHETTE','A607','BANCHETTE (07080)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A607'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A625','BARBANIA','A625','BARBANIA (07015)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A625'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A651','BARDONECCHIA','A651','BARDONECCHIA (07244)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A651'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A673','BARONE CANAVESE','A673','BARONE CANAVESE (07227)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A673'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A734','BEINASCO','A734','BEINASCO (07198)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A734'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A853','BIBIANA','A853','BIBIANA (07152)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A853'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A910','BOBBIO PELLICE','A910','BOBBIO PELLICE (07175)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A910'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A941','BOLLENGO','A941','BOLLENGO (07067)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A941'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A990','BORGARO TORINESE','A990','BORGARO TORINESE (07024)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A990'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B003','BORGIALLO','B003','BORGIALLO (07033)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B003'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B015','BORGOFRANCO D''IVREA','B015','BORGOFRANCO D''IVREA (07090)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B015'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B021','BORGOMASINO','B021','BORGOMASINO (07221)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B021'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B024','BORGONE SUSA','B024','BORGONE SUSA (07256)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B024'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B075','BOSCONERO','B075','BOSCONERO (07189)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B075'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B121','BRANDIZZO','B121','BRANDIZZO (06993)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B121'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B171','BRICHERASIO','B171','BRICHERASIO (07148)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B171'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B205','BROSSO','B205','BROSSO (07097)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B205'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B209','BROZOLO','B209','BROZOLO (06999)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B209'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B216','BRUINO','B216','BRUINO (07199)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B216'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B225','BRUSASCO','B225','BRUSASCO (06998)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B225'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B232','BRUZOLO','B232','BRUZOLO (07246)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B232'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B278','BURIASCO','B278','BURIASCO (07153)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B278'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B279','BUROLO','B279','BUROLO (07068)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B279'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B284','BUSANO','B284','BUSANO (07185)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B284'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B297','BUSSOLENO','B297','BUSSOLENO (07245)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B297'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B305','BUTTIGLIERA ALTA','B305','BUTTIGLIERA ALTA (06960)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B305'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B350','CAFASSE','B350','CAFASSE (07115)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B350'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B435','CALUSO','B435','CALUSO (07226)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B435'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B462','CAMBIANO','B462','CAMBIANO (06982)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B462'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B512','CAMPIGLIONE FENILE','B512','CAMPIGLIONE FENILE (07157)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B512'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B588','CANDIA CANAVESE','B588','CANDIA CANAVESE (07228)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B588'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B592','CANDIOLO','B592','CANDIOLO (07200)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B592'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B605','CANISCHIO','B605','CANISCHIO (07034)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B605'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B628','CANTALUPA','B628','CANTALUPA (07159)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B628'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B637','CANTOIRA','B637','CANTOIRA (07119)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B637'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B705','CAPRIE','B705','CAPRIE (06967)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B705'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B733','CARAVINO','B733','CARAVINO (07222)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B733'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B762','CAREMA','B762','CAREMA (07091)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B762'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B777','CARIGNANO','B777','CARIGNANO (07130)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B777'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B791','CARMAGNOLA','B791','CARMAGNOLA (06973)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B791'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B867','CASALBORGONE','B867','CASALBORGONE (07003)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B867'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B953','CASCINETTE D''IVREA','B953','CASCINETTE D''IVREA (07069)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B953'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B955','CASELETTE','B955','CASELETTE (07205)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B955'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B960','CASELLE TORINESE','B960','CASELLE TORINESE (07023)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B960'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C045','CASTAGNETO PO','C045','CASTAGNETO PO (06994)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C045'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C048','CASTAGNOLE PIEMONTE','C048','CASTAGNOLE PIEMONTE (07167)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C048'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C133','CASTELLAMONTE','C133','CASTELLAMONTE (07047)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C133'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C241','CASTELNUOVO NIGRA','C241','CASTELNUOVO NIGRA (07049)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C241'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C307','CASTIGLIONE TORINESE','C307','CASTIGLIONE TORINESE (07007)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C307'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C369','CAVAGNOLO','C369','CAVAGNOLO (07000)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C369'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C404','CAVOUR','C404','CAVOUR (07156)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C404'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C487','CERCENASCO','C487','CERCENASCO (07262)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C487'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C497','CERES','C497','CERES (07116)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C497'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C505','CERESOLE REALE','C505','CERESOLE REALE (07053)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C505'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C564','CESANA TORINESE','C564','CESANA TORINESE (07251)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C564'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C604','CHIALAMBERTO','C604','CHIALAMBERTO (07120)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C604'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C610','CHIANOCCO','C610','CHIANOCCO (07247)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C610'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C624','CHIAVERANO','C624','CHIAVERANO (07070)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C624'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C627','CHIERI','C627','CHIERI (06978)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C627'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C629','CHIESANUOVA','C629','CHIESANUOVA (07035)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C629'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C639','CHIOMONTE','C639','CHIOMONTE (07234)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C639'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C655','CHIUSA DI SAN MICHELE','C655','CHIUSA DI SAN MICHELE (06961)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C655'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C665','CHIVASSO','C665','CHIVASSO (06992)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C665'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C679','CICONIO','C679','CICONIO (07183)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C679'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C711','CINTANO','C711','CINTANO (07050)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C711'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C715','CINZANO','C715','CINZANO (07013)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C715'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C722','CIRIE''','C722','CIRIE'' (07014)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C722'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C793','CLAVIERE','C793','CLAVIERE (07252)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C793'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C801','COASSOLO TORINESE','C801','COASSOLO TORINESE (07109)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C801'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C803','COAZZE','C803','COAZZE (06969)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C803'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C860','COLLEGNO','C860','COLLEGNO (07206)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C860'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C867','COLLERETTO CASTELNUOVO','C867','COLLERETTO CASTELNUOVO (07036)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C867'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C868','COLLERETTO GIACOSA','C868','COLLERETTO GIACOSA (07081)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C868'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C955','CONDOVE','C955','CONDOVE (06966)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C955'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D008','CORIO','D008','CORIO (07025)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D008'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D092','COSSANO CANAVESE','D092','COSSANO CANAVESE (07223)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D092'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D197','CUCEGLIO','D197','CUCEGLIO (07213)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D197'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D202','CUMIANA','D202','CUMIANA (07158)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D202'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D208','CUORGNE''','D208','CUORGNE'' (07032)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D208'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D373','DRUENTO','D373','DRUENTO (06955)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D373'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D433','EXILLES','D433','EXILLES (07235)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D433'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D520','FAVRIA','D520','FAVRIA (07179)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D520'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D524','FELETTO','D524','FELETTO (07180)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D524'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D532','FENESTRELLE','D532','FENESTRELLE (07139)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D532'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D562','FIANO','D562','FIANO (07027)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D562'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D608','FIORANO CANAVESE','D608','FIORANO CANAVESE (07078)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D608'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D646','FOGLIZZO','D646','FOGLIZZO (07011)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D646'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D725','FORNO CANAVESE','D725','FORNO CANAVESE (07186)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D725'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D781','FRASSINETTO','D781','FRASSINETTO (07057)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D781'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D805','FRONT','D805','FRONT (07016)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D805'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D812','FROSSASCO','D812','FROSSASCO (07160)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D812'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D931','GARZIGLIANA','D931','GARZIGLIANA (07149)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D931'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D933','GASSINO TORINESE','D933','GASSINO TORINESE (07006)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D933'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D983','GERMAGNANO','D983','GERMAGNANO (07110)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D983'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E009','GIAGLIONE','E009','GIAGLIONE (07236)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E009'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E020','GIAVENO','E020','GIAVENO (06968)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E020'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E067','GIVOLETTO','E067','GIVOLETTO (07207)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E067'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E154','GRAVERE','E154','GRAVERE (07237)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E154'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E199','GROSCAVALLO','E199','GROSCAVALLO (07121)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E199'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E203','GROSSO','E203','GROSSO (07111)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E203'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E216','GRUGLIASCO','E216','GRUGLIASCO (07194)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E216'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E301','INGRIA','E301','INGRIA (07058)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E301'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E311','INVERSO PINASCA','E311','INVERSO PINASCA (07135)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E311'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E345','ISOLABELLA','E345','ISOLABELLA (06975)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E345'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E368','ISSIGLIO','E368','ISSIGLIO (07103)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E368'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E379','IVREA','E379','IVREA (07066)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E379'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E394','LA CASSA','E394','LA CASSA (07208)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E394'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E423','LA LOGGIA','E423','LA LOGGIA (07131)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E423'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E445','LANZO TORINESE','E445','LANZO TORINESE (07107)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E445'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E484','LAURIANO','E484','LAURIANO (07004)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E484'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E518','LEINI','E518','LEINI (07031)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E518'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E520','LEMIE','E520','LEMIE (07122)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E520'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E551','LESSOLO','E551','LESSOLO (07077)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E551'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E566','LEVONE','E566','LEVONE (07187)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E566'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E635','LOCANA','E635','LOCANA (07052)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E635'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E660','LOMBARDORE','E660','LOMBARDORE (07190)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E660'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E661','LOMBRIASCO','E661','LOMBRIASCO (07265)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E661'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E683','LORANZE''','E683','LORANZE'' (07082)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E683'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E727','LUGNACCO','E727','LUGNACCO (07104)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E727'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E758','LUSERNA SAN GIOVANNI','E758','LUSERNA SAN GIOVANNI (07162)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E758'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E759','LUSERNETTA','E759','LUSERNETTA (07163)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E759'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E763','LUSIGLIE''','E763','LUSIGLIE'' (07064)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E763'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E782','MACELLO','E782','MACELLO (07154)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E782'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E817','MAGLIONE','E817','MAGLIONE (07224)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E817'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M316','MAPPANO','M316','MAPPANO (00000)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M316'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E941','MARENTINO','E941','MARENTINO (06983)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E941'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F041','MASSELLO','F041','MASSELLO (07144)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F041'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F053','MATHI','F053','MATHI (07112)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F053'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F058','MATTIE','F058','MATTIE (07238)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F058'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F067','MAZZE''','F067','MAZZE'' (07229)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F067'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F074','MEANA DI SUSA','F074','MEANA DI SUSA (07239)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F074'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F140','MERCENASCO','F140','MERCENASCO (07214)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F140'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F164','MEUGLIANO','F164','MEUGLIANO (07098)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F164'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F182','MEZZENILE','F182','MEZZENILE (07123)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F182'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F315','MOMBELLO DI TORINO','F315','MOMBELLO DI TORINO (06984)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F315'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F318','MOMPANTERO','F318','MOMPANTERO (07240)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F318'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F327','MONASTERO DI LANZO','F327','MONASTERO DI LANZO (07113)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F327'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F335','MONCALIERI','F335','MONCALIERI (07127)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F335'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D553','MONCENISIO','D553','MONCENISIO (07241)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D553'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F407','MONTALDO TORINESE','F407','MONTALDO TORINESE (06985)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F407'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F411','MONTALENGHE','F411','MONTALENGHE (07230)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F411'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F420','MONTALTO DORA','F420','MONTALTO DORA (07071)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F420'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F422','MONTANARO','F422','MONTANARO (07010)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F422'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F651','MONTEU DA PO','F651','MONTEU DA PO (07002)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F651'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F733','MORIONDO TORINESE','F733','MORIONDO TORINESE (06986)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F733'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F889','NICHELINO','F889','NICHELINO (07128)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F889'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F906','NOASCA','F906','NOASCA (07054)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F906'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F925','NOLE','F925','NOLE (07017)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F925'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F927','NOMAGLIO','F927','NOMAGLIO (07092)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F927'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F931','NONE','F931','NONE (07165)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F931'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F948','NOVALESA','F948','NOVALESA (07242)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F948'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G010','OGLIANICO','G010','OGLIANICO (07181)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G010'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G087','ORBASSANO','G087','ORBASSANO (07197)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G087'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G109','ORIO CANAVESE','G109','ORIO CANAVESE (07231)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G109'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G151','OSASCO','G151','OSASCO (07169)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G151'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G152','OSASIO','G152','OSASIO (07266)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G152'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G196','OULX','G196','OULX (07258)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G196'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G202','OZEGNA','G202','OZEGNA (07182)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G202'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G262','PALAZZO CANAVESE','G262','PALAZZO CANAVESE (07074)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G262'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G303','PANCALIERI','G303','PANCALIERI (07264)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G303'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G330','PARELLA','G330','PARELLA (07083)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G330'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G387','PAVAROLO','G387','PAVAROLO (06987)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G387'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G392','PAVONE CANAVESE','G392','PAVONE CANAVESE (07079)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G392'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G396','PECCO','G396','PECCO (07105)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G396'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G398','PECETTO TORINESE','G398','PECETTO TORINESE (06988)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G398'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G463','PEROSA ARGENTINA','G463','PEROSA ARGENTINA (07134)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G463'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G462','PEROSA CANAVESE','G462','PEROSA CANAVESE (07215)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G462'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G465','PERRERO','G465','PERRERO (07143)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G465'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G477','PERTUSIO','G477','PERTUSIO (07037)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G477'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G505','PESSINETTO','G505','PESSINETTO (07124)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G505'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G559','PIANEZZA','G559','PIANEZZA (07203)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G559'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G672','PINASCA','G672','PINASCA (07136)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G672'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G674','PINEROLO','G674','PINEROLO (07147)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G674'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G678','PINO TORINESE','G678','PINO TORINESE (06989)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G678'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G684','PIOBESI TORINESE','G684','PIOBESI TORINESE (07133)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G684'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G691','PIOSSASCO','G691','PIOSSASCO (07211)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G691'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G705','PISCINA','G705','PISCINA (07155)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G705'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G719','PIVERONE','G719','PIVERONE (07075)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G719'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G777','POIRINO','G777','POIRINO (06974)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G777'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G805','POMARETTO','G805','POMARETTO (07137)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G805'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G826','PONT CANAVESE','G826','PONT CANAVESE (07055)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G826'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G900','PORTE','G900','PORTE (07150)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G900'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G973','PRAGELATO','G973','PRAGELATO (07140)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G973'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G978','PRALI','G978','PRALI (07145)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G978'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G979','PRALORMO','G979','PRALORMO (06976)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G979'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G982','PRAMOLLO','G982','PRAMOLLO (07170)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G982'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G986','PRAROSTINO','G986','PRAROSTINO (07171)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G986'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G988','PRASCORSANO','G988','PRASCORSANO (07038)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G988'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G997','PRATIGLIONE','G997','PRATIGLIONE (07039)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G997'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H100','QUAGLIUZZO','H100','QUAGLIUZZO (07084)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H100'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H120','QUASSOLO','H120','QUASSOLO (07093)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H120'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H127','QUINCINETTO','H127','QUINCINETTO (07094)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H127'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H207','REANO','H207','REANO (06970)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H207'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H270','RIBORDONE','H270','RIBORDONE (07059)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H270'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H337','RIVA PRESSO CHIERI','H337','RIVA PRESSO CHIERI (06990)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H337'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H333','RIVALBA','H333','RIVALBA (07008)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H333'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H335','RIVALTA DI TORINO','H335','RIVALTA DI TORINO (07201)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H335'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H338','RIVARA','H338','RIVARA (07184)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H338'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H340','RIVAROLO CANAVESE','H340','RIVAROLO CANAVESE (07178)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H340'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H344','RIVAROSSA','H344','RIVAROSSA (07191)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H344'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H355','RIVOLI','H355','RIVOLI (07193)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H355'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H367','ROBASSOMERO','H367','ROBASSOMERO (07028)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H367'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H386','ROCCA CANAVESE','H386','ROCCA CANAVESE (07026)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H386'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H498','ROLETTO','H498','ROLETTO (07161)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H498'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H511','ROMANO CANAVESE','H511','ROMANO CANAVESE (07216)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H511'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H539','RONCO CANAVESE','H539','RONCO CANAVESE (07060)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H539'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H547','RONDISSONE','H547','RONDISSONE (06995)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H547'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H554','RORA''','H554','RORA'' (07164)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H554'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H583','ROSTA','H583','ROSTA (07195)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H583'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H555','ROURE','H555','ROURE (07141)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H555'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H627','RUBIANA','H627','RUBIANA (06964)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H627'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H631','RUEGLIO','H631','RUEGLIO (07106)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H631'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H691','SALASSA','H691','SALASSA (07040)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H691'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H684','SALBERTRAND','H684','SALBERTRAND (07259)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H684'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H702','SALERANO CANAVESE','H702','SALERANO CANAVESE (07085)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H702'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H734','SALZA DI PINEROLO','H734','SALZA DI PINEROLO (07146)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H734'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H753','SAMONE','H753','SAMONE (07086)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H753'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H775','SAN BENIGNO CANAVESE','H775','SAN BENIGNO CANAVESE (07188)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H775'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H789','SAN CARLO CANAVESE','H789','SAN CARLO CANAVESE (07018)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H789'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H804','SAN COLOMBANO BELMONTE','H804','SAN COLOMBANO BELMONTE (07041)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H804'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H820','SAN DIDERO','H820','SAN DIDERO (07248)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H820'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H847','SAN FRANCESCO AL CAMPO','H847','SAN FRANCESCO AL CAMPO (07019)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H847'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H862','SAN GERMANO CHISONE','H862','SAN GERMANO CHISONE (07172)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H862'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H873','SAN GILLIO','H873','SAN GILLIO (07209)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H873'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H890','SAN GIORGIO CANAVESE','H890','SAN GIORGIO CANAVESE (07063)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H890'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H900','SAN GIORIO DI SUSA','H900','SAN GIORIO DI SUSA (07249)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H900'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H936','SAN GIUSTO CANAVESE','H936','SAN GIUSTO CANAVESE (07065)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H936'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H997','SAN MARTINO CANAVESE','H997','SAN MARTINO CANAVESE (07217)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H997'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I024','SAN MAURIZIO CANAVESE','I024','SAN MAURIZIO CANAVESE (07020)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I024'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I030','SAN MAURO TORINESE','I030','SAN MAURO TORINESE (06956)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I030'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I090','SAN PIETRO VAL LEMINA','I090','SAN PIETRO VAL LEMINA (07151)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I090'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I126','SAN PONSO','I126','SAN PONSO (07042)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I126'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I137','SAN RAFFAELE CIMENA','I137','SAN RAFFAELE CIMENA (07009)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I137'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I152','SAN SEBASTIANO DA PO','I152','SAN SEBASTIANO DA PO (07005)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I152'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I154','SAN SECONDO DI PINEROLO','I154','SAN SECONDO DI PINEROLO (07168)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I154'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H855','SANGANO','H855','SANGANO (07202)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H855'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I258','SANT''AMBROGIO DI TORINO','I258','SANT'' AMBROGIO DI TORINO (06962)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I258'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I296','SANT''ANTONINO DI SUSA','I296','SANT''ANTONINO DI SUSA (07255)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I296'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I327','SANTENA','I327','SANTENA (06991)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I327'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I466','SAUZE D''OULX','I466','SAUZE D''OULX (07260)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I466'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I465','SAUZE DI CESANA','I465','SAUZE DI CESANA (07253)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I465'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I490','SCALENGHE','I490','SCALENGHE (07263)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I490'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I511','SCARMAGNO','I511','SCARMAGNO (07218)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I511'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I539','SCIOLZE','I539','SCIOLZE (07012)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I539'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I692','SESTRIERE','I692','SESTRIERE (07254)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I692'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I701','SETTIMO ROTTARO','I701','SETTIMO ROTTARO (07076)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I701'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I703','SETTIMO TORINESE','I703','SETTIMO TORINESE (06957)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I703'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I702','SETTIMO VITTONE','I702','SETTIMO VITTONE (07088)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I702'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I886','SPARONE','I886','SPARONE (07061)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I886'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I969','STRAMBINELLO','I969','STRAMBINELLO (07087)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I969'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I970','STRAMBINO','I970','STRAMBINO (07212)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I970'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L013','SUSA','L013','SUSA (07233)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L013'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L066','TAVAGNASCO','L066','TAVAGNASCO (07095)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L066'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L219','TORINO','L219','TORINO (06954)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L219'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L238','TORRAZZA PIEMONTE','L238','TORRAZZA PIEMONTE (06996)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L238'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L247','TORRE CANAVESE','L247','TORRE CANAVESE (07046)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L247'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L277','TORRE PELLICE','L277','TORRE PELLICE (07173)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L277'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L327','TRANA','L327','TRANA (06971)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L327'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L338','TRAUSELLA','L338','TRAUSELLA (07099)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L338'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L345','TRAVERSELLA','L345','TRAVERSELLA (07100)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L345'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L340','TRAVES','L340','TRAVES (07114)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L340'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L445','TROFARELLO','L445','TROFARELLO (07129)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L445'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L515','USSEAUX','L515','USSEAUX (07142)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L515'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L516','USSEGLIO','L516','USSEGLIO (07125)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L516'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L538','VAIE','L538','VAIE (07257)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L538'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L555','VAL DELLA TORRE','L555','VAL DELLA TORRE (07210)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L555'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M405','VAL DI CHY','M405','VAL DI CHY (99997)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M405'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M415','VALCHIUSA','M415','VALCHIUSA (99998)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M415'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L578','VALGIOIE','L578','VALGIOIE (06972)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L578'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L629','VALLO TORINESE','L629','VALLO TORINESE (07029)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L629'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L644','VALPERGA','L644','VALPERGA (07043)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L644'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B510','VALPRATO SOANA','B510','VALPRATO SOANA (07062)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B510'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L685','VARISELLA','L685','VARISELLA (07030)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L685'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L698','VAUDA CANAVESE','L698','VAUDA CANAVESE (07021)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L698'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L727','VENARIA REALE','L727','VENARIA REALE (06958)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L727'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L726','VENAUS','L726','VENAUS (07243)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L726'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L779','VEROLENGO','L779','VEROLENGO (06997)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L779'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L787','VERRUA SAVOIA','L787','VERRUA SAVOIA (07001)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L787'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L811','VESTIGNE''','L811','VESTIGNE'' (07225)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L811'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L830','VIALFRE''','L830','VIALFRE'' (07219)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L830'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L548','VICO CANAVESE','L548','VICO CANAVESE (07096)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L548'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L857','VIDRACCO','L857','VIDRACCO (07051)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L857'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L898','VIGONE','L898','VIGONE (07261)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L898'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L948','VILLAFRANCA PIEMONTE','L948','VILLAFRANCA PIEMONTE (07268)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L948'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L982','VILLANOVA CANAVESE','L982','VILLANOVA CANAVESE (07022)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L982'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L999','VILLAR DORA','L999','VILLAR DORA (06965)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L999'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M007','VILLAR FOCCHIARDO','M007','VILLAR FOCCHIARDO (07250)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M007'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M013','VILLAR PELLICE','M013','VILLAR PELLICE (07176)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M013'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M014','VILLAR PEROSA','M014','VILLAR PEROSA (07138)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M014'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M002','VILLARBASSE','M002','VILLARBASSE (07196)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M002'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M004','VILLAREGGIA','M004','VILLAREGGIA (07232)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M004'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M027','VILLASTELLONE','M027','VILLASTELLONE (06977)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M027'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M060','VINOVO','M060','VINOVO (07132)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M060'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M069','VIRLE PIEMONTE','M069','VIRLE PIEMONTE (07267)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M069'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M071','VISCHE','M071','VISCHE (07220)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M071'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M080','VISTRORIO','M080','VISTRORIO (07101)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M080'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M094','VIU''','M094','VIU'' (07126)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M094'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M122','VOLPIANO','M122','VOLPIANO (07192)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M122'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M133','VOLVERA','M133','VOLVERA (07177)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M133'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );

			
-- siac_r_tefa_tributo_gruppo
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3920' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='1' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3944' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='1' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3950' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='1' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='365E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='1' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='368E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='1' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3921' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='2' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3945' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='2' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3951' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='2' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='366E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='2' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='369E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='2' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3922' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='3' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3946' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='3' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3952' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='3' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='367E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='3' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='370E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='3' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='TEFA' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='4' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='TEFN' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='5' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='TEFZ' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='6' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3920' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='7' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3921' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='8' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3922' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='9' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3944' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='10' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3950' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='10' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='365E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='10' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='368E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='10' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3945' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='11' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3951' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='11' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='366E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='11' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='369E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='11' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3946' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='12' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3952' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='12' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='367E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='12' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='370E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='12' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='TEFA' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='13' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='TEFN' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='14' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='TEFZ' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='15' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3920' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='16' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3944' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='16' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3950' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='16' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='365E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='16' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='368E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='16' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3921' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='17' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3945' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='17' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3951' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='17' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='366E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='17' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='369E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='17' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3922' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='18' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3946' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='18' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3952' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='18' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='367E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='18' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='370E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='18' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='TEFA' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='19' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='TEFN' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='20' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='TEFZ' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='21' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );

           
 --//////////////////////////// 



CREATE INDEX if not exists siac_t_tefa_trib_fk_tefa_nome_file_idx ON siac_t_tefa_trib_importi USING btree (tefa_nome_file);

            
 CREATE INDEX if not exists siac_d_tefa_tributo_fk_siac_d_tefa_trib_code_idx ON siac.siac_d_tefa_tributo USING btree (ente_proprietario_id, tefa_trib_code);



