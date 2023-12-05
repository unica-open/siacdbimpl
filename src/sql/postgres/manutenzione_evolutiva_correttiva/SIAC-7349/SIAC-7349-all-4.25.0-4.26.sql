/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--Riferimenti  sql inclusi:
--SIAC-7349-ddl-componenti-23022020.sql
--SIAC-7349.siac_r_movgest_bil_elem-24032020.sql
--SIAC-7349-ddl-siac_v_dwh_bil_elem_comp_cap.sql
--SIAC-7349-ddl-siac_v_dwh_bil_elem_comp_tipo.sql
--SIAC-7349-insert_codifiche_componenti_v01_23032020.sql
--SIAC-7349-insert_PREGRESSO_componenti_v01_24032020.sql


-- DDL
DROP VIEW if exists siac.siac_v_dwh_bil_elem_comp_tipo;
DROP VIEW if exists siac.siac_v_dwh_bil_elem_comp_cap;
--ALTER TABLE siac.siac_d_bil_elem_det_comp_tipo  DROP if exists elem_det_comp_tipo_imp_id;
--drop table if exists siac.siac_d_bil_elem_det_comp_tipo_imp;






CREATE TABLE IF NOT EXISTS  siac.siac_d_bil_elem_det_comp_tipo_imp
(
                elem_det_comp_tipo_imp_id SERIAL,
                elem_det_comp_tipo_imp_code VARCHAR(200) NOT NULL,
                elem_det_comp_tipo_imp_desc VARCHAR(500) NOT NULL,
                validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
                validita_fine TIMESTAMP,
                ente_proprietario_id INTEGER NOT NULL,
                data_creazione TIMESTAMP DEFAULT now() NOT NULL,
                data_modifica TIMESTAMP DEFAULT now() NOT NULL,
                data_cancellazione TIMESTAMP,
                login_operazione VARCHAR(200) NOT NULL,
                CONSTRAINT pk_siac_d_bil_elem_det_comp_tipo_imp PRIMARY KEY (elem_det_comp_tipo_imp_id)
);
COMMENT ON TABLE siac.siac_d_bil_elem_det_comp_tipo_imp IS 'Impegnabile del Componente in fase di assunzione di nuovi impegni ';  
COMMENT ON COLUMN siac.siac_d_bil_elem_det_comp_tipo_imp.elem_det_comp_tipo_imp_code IS ' Valore ammessi Si, No, Automatica';

SELECT * FROM  fnc_dba_add_fk_constraint('siac_d_bil_elem_det_comp_tipo_imp', 'siac_t_ente_proprietario_siac_d_bil_elem_det_comp_tipo_imp', 'ente_proprietario_id', 'siac_t_ente_proprietario', 'ente_proprietario_id');	

SELECT * FROM fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo_imp', 'siac_d_bil_elem_det_comp_tipo_imp_fk_ente_proprietario_id_idx','ente_proprietario_id', null, false);
SELECT * FROM fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo_imp', 'siac_d_bil_elem_det_comp_tipo_imp_idx_1','elem_det_comp_tipo_imp_code,validita_inizio, ente_proprietario_id', 'data_cancellazione is null', false);

 
 
 ALTER TABLE siac.siac_d_bil_elem_det_comp_tipo_imp OWNER TO siac;
 


SELECT * FROM  fnc_dba_add_column_params ( 'siac_d_bil_elem_det_comp_tipo', 'elem_det_comp_tipo_imp_id', 'INTEGER');
SELECT * FROM fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo', 'siac_d_bil_elem_det_comp_tipo_fk_imp_id_idx','elem_det_comp_tipo_imp_id', null, false);
SELECT * FROM  fnc_dba_add_fk_constraint('siac_d_bil_elem_det_comp_tipo', 'siac_d_bil_elem_det_comp_tipo_elem_det_comp_tipo_imp', 'elem_det_comp_tipo_imp_id', 'siac_d_bil_elem_det_comp_tipo_imp', 'elem_det_comp_tipo_imp_id');

ALTER TABLE siac_d_bil_elem_det_comp_tipo  ALTER COLUMN elem_det_comp_tipo_gest_aut DROP NOT NULL;
  
 

-- Table: siac.siac_r_movgest_ts_det_mod

-- DROP TABLE siac.siac_r_movgest_ts_det_mod;



CREATE TABLE IF NOT EXISTS siac.siac_r_movgest_ts_det_mod
(
	
	movgest_ts_det_mod_r_id SERIAL,
	movgest_ts_det_mod_entrata_id integer NOT NULL,
	movgest_ts_det_mod_spesa_id integer NOT NULL,
	movgest_ts_det_mod_importo numeric,
	movgest_ts_det_mod_impo_residuo numeric,
    validita_inizio timestamp without time zone NOT NULL,
    validita_fine timestamp without time zone,
    ente_proprietario_id integer NOT NULL,
    data_creazione timestamp without time zone NOT NULL DEFAULT now(),
    data_modifica timestamp without time zone NOT NULL DEFAULT now(),
    data_cancellazione timestamp without time zone,
    login_operazione character varying(200) NOT NULL,
    CONSTRAINT pk_r_movgest_ts_det_mod PRIMARY KEY (movgest_ts_det_mod_r_id)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;
COMMENT ON TABLE siac.siac_r_movgest_ts_det_mod IS 'Associazione delle modifiche tra impegni e accertamenti';

ALTER TABLE siac.siac_r_movgest_ts_det_mod
    OWNER to siac;
	
SELECT * FROM  fnc_dba_add_fk_constraint('siac_r_movgest_ts_det_mod', 'siac_t_ente_proprietario_siac_r_movgest_ts_det_mod', 'ente_proprietario_id', 'siac_t_ente_proprietario', 'ente_proprietario_id');	
SELECT * FROM  fnc_dba_add_fk_constraint('siac_r_movgest_ts_det_mod', 'siac_t_movgest_ts_det_mod_siac_r_movgest_ts_det_mod_entrata', 'movgest_ts_det_mod_entrata_id', 'siac_t_movgest_ts_det_mod', 'movgest_ts_det_mod_id');	
SELECT * FROM  fnc_dba_add_fk_constraint('siac_r_movgest_ts_det_mod', 'siac_t_movgest_ts_det_mod_siac_r_movgest_ts_det_mod_spesa', 'movgest_ts_det_mod_spesa_id', 'siac_t_movgest_ts_det_mod', 'movgest_ts_det_mod_id');	
	
	
SELECT * FROM fnc_dba_create_index('siac_r_movgest_ts_det_mod', 'idx_siac_r_movgest_ts_det_mod_1','movgest_ts_det_mod_entrata_id, movgest_ts_det_mod_spesa_id,validita_inizio, ente_proprietario_id', 'data_cancellazione is null', false);
SELECT * FROM fnc_dba_create_index('siac_r_movgest_ts_det_mod', 'siac_r_movgest_ts_det_mod_imp_fk_ente_proprietario_id_idx','ente_proprietario_id', null, false);
SELECT * FROM fnc_dba_create_index('siac_r_movgest_ts_det_mod', 'siac_r_movgest_ts_det_mod_imp_mod_entrata_id_idx','movgest_ts_det_mod_entrata_id', null, false);
SELECT * FROM fnc_dba_create_index('siac_r_movgest_ts_det_mod', 'siac_r_movgest_ts_det_mod_imp_mod_spesa_id_idx','movgest_ts_det_mod_spesa_id', null, false);
 
 
 

-- View: siac.siac_v_dwh_bil_elem_comp_cap

-- DROP VIEW siac.siac_v_dwh_bil_elem_comp_cap;


CREATE OR REPLACE VIEW siac.siac_v_dwh_bil_elem_comp_cap
 AS
 SELECT ente.ente_proprietario_id,
    ente.ente_denominazione,
    query.elem_anno_bilancio,
    query.elem_tipo_code_capitolo,
    query.elem_tipo_desc_capitolo,
    query.elem_code_capitolo,
    query.elem_code_articolo,
    query.elem_code_ueb,
    query.elem_stato_code_capitolo,
    query.elem_stato_desc_capitolo,
    query.elem_det_anno,
    query.elem_det_importo,
    query.elem_det_comp_importo,
    query.elem_det_comp_tipo_code,
    query.elem_det_comp_tipo_desc,
    query.elem_det_comp_macro_tipo_code,
    query.elem_det_comp_macro_tipo_desc,
    query.elem_det_comp_sotto_tipo_code,
    query.elem_det_comp_sotto_tipo_desc,
    query.elem_det_comp_tipo_ambito_code,
    query.elem_det_comp_tipo_ambito_desc,
    query.elem_det_comp_tipo_fonte_code,
    query.elem_det_comp_tipo_fonte_desc,
    query.elem_det_comp_tipo_fase_code,
    query.elem_det_comp_tipo_fase_desc,
    query.elem_det_comp_tipo_def_code,
    query.elem_det_comp_tipo_def_desc,
    query.elem_det_comp_tipo_gest_aut,
	query.elem_det_comp_tipo_imp_code, 
	query.elem_det_comp_tipo_imp_desc,
    query.elem_det_comp_tipo_anno
   FROM ( WITH comp_tipo AS (
                 SELECT macro.elem_det_comp_macro_tipo_code,
                    macro.elem_det_comp_macro_tipo_desc,
                    sotto_tipo.elem_det_comp_sotto_tipo_code,
                    sotto_tipo.elem_det_comp_sotto_tipo_desc,
                    tipo.elem_det_comp_tipo_code,
                    tipo.elem_det_comp_tipo_desc,
                    ambito_tipo.elem_det_comp_tipo_ambito_code,
                    ambito_tipo.elem_det_comp_tipo_ambito_desc,
                    fonte_tipo.elem_det_comp_tipo_fonte_code,
                    fonte_tipo.elem_det_comp_tipo_fonte_desc,
                    fase_tipo.elem_det_comp_tipo_fase_code,
                    fase_tipo.elem_det_comp_tipo_fase_desc,
                    def_tipo.elem_det_comp_tipo_def_code,
                    def_tipo.elem_det_comp_tipo_def_desc,
                     CASE
                     WHEN tipo.elem_det_comp_tipo_gest_aut = true THEN 'Solo automatica'::text
                     ELSE 'Manuale'::text
                      END::character varying(50) AS elem_det_comp_tipo_gest_aut,
					imp_tipo.elem_det_comp_tipo_imp_code, 
					imp_tipo.elem_det_comp_tipo_imp_desc,						
                    per.anno::integer AS elem_det_comp_tipo_anno,
                    tipo.elem_det_comp_tipo_id,
                    per.periodo_id AS elem_det_comp_periodo_id
                   FROM siac_d_bil_elem_det_comp_tipo_stato stato,
                    siac_d_bil_elem_det_comp_macro_tipo macro,
                    siac_d_bil_elem_det_comp_tipo tipo
                     LEFT JOIN siac_d_bil_elem_det_comp_sotto_tipo sotto_tipo ON tipo.elem_det_comp_sotto_tipo_id = sotto_tipo.elem_det_comp_sotto_tipo_id
                     LEFT JOIN siac_d_bil_elem_det_comp_tipo_ambito ambito_tipo ON tipo.elem_det_comp_tipo_ambito_id = ambito_tipo.elem_det_comp_tipo_ambito_id
                     LEFT JOIN siac_d_bil_elem_det_comp_tipo_fonte fonte_tipo ON tipo.elem_det_comp_tipo_fonte_id = fonte_tipo.elem_det_comp_tipo_fonte_id
                     LEFT JOIN siac_d_bil_elem_det_comp_tipo_fase fase_tipo ON tipo.elem_det_comp_tipo_fase_id = fase_tipo.elem_det_comp_tipo_fase_id
                     LEFT JOIN siac_d_bil_elem_det_comp_tipo_def def_tipo ON tipo.elem_det_comp_tipo_def_id = def_tipo.elem_det_comp_tipo_def_id
					 --SIAC-7349
					 LEFT JOIN siac_d_bil_elem_det_comp_tipo_imp imp_tipo ON tipo.elem_det_comp_tipo_imp_id = imp_tipo.elem_det_comp_tipo_imp_id
                     LEFT JOIN siac_t_periodo per ON tipo.periodo_id = per.periodo_id
                  WHERE stato.elem_det_comp_tipo_stato_id = tipo.elem_det_comp_tipo_stato_id AND macro.elem_det_comp_macro_tipo_id = tipo.elem_det_comp_macro_tipo_id AND tipo.data_cancellazione IS NULL
                ), capitolo AS (
                 SELECT e.elem_code,
                    e.elem_code2,
                    e.elem_code3,
                    tipo.elem_tipo_code,
                    tipo.elem_tipo_desc,
                    stato.elem_stato_code,
                    stato.elem_stato_desc,
                    per.anno AS elem_anno_bilancio,
                    per_det.anno AS elem_det_anno,
                    det.elem_det_importo,
                    e.elem_id,
                    det.elem_det_id,
                    det.elem_det_tipo_id,
                    bil.bil_id,
                    per.periodo_id,
                    per_det.periodo_id AS periodo_det_id,
                    e.ente_proprietario_id
                   FROM siac_t_bil_elem e,
                    siac_d_bil_elem_tipo tipo,
                    siac_r_bil_elem_stato rs,
                    siac_d_bil_elem_stato stato,
                    siac_t_bil bil,
                    siac_t_periodo per,
                    siac_t_bil_elem_det det,
                    siac_d_bil_elem_det_tipo tipo_det,
                    siac_t_periodo per_det
                  WHERE (tipo.elem_tipo_code::text = ANY (ARRAY['CAP-UG'::character varying::text, 'CAP-UP'::character varying::text])) AND e.elem_tipo_id = tipo.elem_tipo_id AND rs.elem_id = e.elem_id AND stato.elem_stato_id = rs.elem_stato_id AND bil.bil_id = e.bil_id AND per.periodo_id = bil.periodo_id AND det.elem_id = e.elem_id AND tipo_det.elem_det_tipo_id = det.elem_det_tipo_id AND tipo_det.elem_det_tipo_code::text = 'STA'::text AND per_det.periodo_id = det.periodo_id AND e.data_cancellazione IS NULL AND det.data_cancellazione IS NULL AND rs.data_cancellazione IS NULL AND rs.validita_fine IS NULL
                ), capitolo_det_comp AS (
                 SELECT comp.elem_det_comp_id,
                    comp.elem_det_id,
                    comp.elem_det_comp_tipo_id,
                    comp.elem_det_importo,
                    comp.validita_inizio,
                    comp.validita_fine,
                    comp.ente_proprietario_id,
                    comp.data_creazione,
                    comp.data_modifica,
                    comp.data_cancellazione,
                    comp.login_operazione
                   FROM siac_t_bil_elem_det_comp comp
                  WHERE comp.data_cancellazione IS NULL
                )
         SELECT capitolo.elem_code AS elem_code_capitolo,
            capitolo.elem_code2 AS elem_code_articolo,
            capitolo.elem_code3 AS elem_code_ueb,
            capitolo.elem_tipo_code AS elem_tipo_code_capitolo,
            capitolo.elem_tipo_desc AS elem_tipo_desc_capitolo,
            capitolo.elem_stato_code AS elem_stato_code_capitolo,
            capitolo.elem_stato_desc AS elem_stato_desc_capitolo,
            capitolo.elem_anno_bilancio,
            capitolo.elem_det_anno,
            capitolo.elem_det_importo,
            capitolo.elem_id,
            capitolo.elem_det_id,
            capitolo.elem_det_tipo_id,
            capitolo.bil_id,
            capitolo.periodo_id,
            capitolo.periodo_det_id,
            capitolo.ente_proprietario_id,
            capitolo_det_comp.elem_det_importo AS elem_det_comp_importo,
            comp_tipo.elem_det_comp_macro_tipo_code,
            comp_tipo.elem_det_comp_macro_tipo_desc,
            comp_tipo.elem_det_comp_sotto_tipo_code,
            comp_tipo.elem_det_comp_sotto_tipo_desc,
            comp_tipo.elem_det_comp_tipo_code,
            comp_tipo.elem_det_comp_tipo_desc,
            comp_tipo.elem_det_comp_tipo_ambito_code,
            comp_tipo.elem_det_comp_tipo_ambito_desc,
            comp_tipo.elem_det_comp_tipo_fonte_code,
            comp_tipo.elem_det_comp_tipo_fonte_desc,
            comp_tipo.elem_det_comp_tipo_fase_code,
            comp_tipo.elem_det_comp_tipo_fase_desc,
            comp_tipo.elem_det_comp_tipo_def_code,
            comp_tipo.elem_det_comp_tipo_def_desc,
			comp_tipo.elem_det_comp_tipo_gest_aut,
			comp_tipo.elem_det_comp_tipo_imp_code, 
			comp_tipo.elem_det_comp_tipo_imp_desc,
            comp_tipo.elem_det_comp_tipo_anno,
            comp_tipo.elem_det_comp_periodo_id
           FROM capitolo,
            capitolo_det_comp,
            comp_tipo
          WHERE capitolo.elem_det_id = capitolo_det_comp.elem_det_id AND comp_tipo.elem_det_comp_tipo_id = capitolo_det_comp.elem_det_comp_tipo_id) query,
    siac_t_ente_proprietario ente
  WHERE query.ente_proprietario_id = ente.ente_proprietario_id;

ALTER TABLE siac.siac_v_dwh_bil_elem_comp_cap
    OWNER TO siac;
	
	
-- View: siac.siac_v_dwh_bil_elem_comp_tipo

-- DROP VIEW siac.siac_v_dwh_bil_elem_comp_tipo;

CREATE OR REPLACE VIEW siac.siac_v_dwh_bil_elem_comp_tipo
 AS
 SELECT ente.ente_proprietario_id,
    ente.ente_denominazione,
    tipo.elem_det_comp_tipo_code,
    tipo.elem_det_comp_tipo_desc,
    macro.elem_det_comp_macro_tipo_code,
    macro.elem_det_comp_macro_tipo_desc,
    sotto_tipo.elem_det_comp_sotto_tipo_code,
    sotto_tipo.elem_det_comp_sotto_tipo_desc,
    ambito_tipo.elem_det_comp_tipo_ambito_code,
    ambito_tipo.elem_det_comp_tipo_ambito_desc,
    fonte_tipo.elem_det_comp_tipo_fonte_code,
    fonte_tipo.elem_det_comp_tipo_fonte_desc,
    fase_tipo.elem_det_comp_tipo_fase_code,
    fase_tipo.elem_det_comp_tipo_fase_desc,
    def_tipo.elem_det_comp_tipo_def_code,
    def_tipo.elem_det_comp_tipo_def_desc,
         CASE
            WHEN tipo.elem_det_comp_tipo_gest_aut = true THEN 'Solo automatica'::text
            ELSE 'Manuale'::text
        END::character varying(50) AS elem_det_comp_tipo_gest_aut,
	imp_tipo.elem_det_comp_tipo_imp_code, 
	imp_tipo.elem_det_comp_tipo_imp_desc,
    per.anno::integer AS elem_det_comp_tipo_anno,
    stato.elem_det_comp_tipo_stato_code,
    stato.elem_det_comp_tipo_stato_desc,
    tipo.validita_inizio,
    tipo.validita_fine
   FROM siac_t_ente_proprietario ente,
    siac_d_bil_elem_det_comp_tipo_stato stato,
    siac_d_bil_elem_det_comp_macro_tipo macro,
    siac_d_bil_elem_det_comp_tipo tipo
     LEFT JOIN siac_d_bil_elem_det_comp_sotto_tipo sotto_tipo ON tipo.elem_det_comp_sotto_tipo_id = sotto_tipo.elem_det_comp_sotto_tipo_id
     LEFT JOIN siac_d_bil_elem_det_comp_tipo_ambito ambito_tipo ON tipo.elem_det_comp_tipo_ambito_id = ambito_tipo.elem_det_comp_tipo_ambito_id
     LEFT JOIN siac_d_bil_elem_det_comp_tipo_fonte fonte_tipo ON tipo.elem_det_comp_tipo_fonte_id = fonte_tipo.elem_det_comp_tipo_fonte_id
     LEFT JOIN siac_d_bil_elem_det_comp_tipo_fase fase_tipo ON tipo.elem_det_comp_tipo_fase_id = fase_tipo.elem_det_comp_tipo_fase_id
     LEFT JOIN siac_d_bil_elem_det_comp_tipo_def def_tipo ON tipo.elem_det_comp_tipo_def_id = def_tipo.elem_det_comp_tipo_def_id
	 --SIAC-7349
	 LEFT JOIN siac_d_bil_elem_det_comp_tipo_imp imp_tipo ON tipo.elem_det_comp_tipo_imp_id = imp_tipo.elem_det_comp_tipo_imp_id
     LEFT JOIN siac_t_periodo per ON tipo.periodo_id = per.periodo_id
  WHERE stato.ente_proprietario_id = ente.ente_proprietario_id AND stato.elem_det_comp_tipo_stato_id = tipo.elem_det_comp_tipo_stato_id AND macro.elem_det_comp_macro_tipo_id = tipo.elem_det_comp_macro_tipo_id AND tipo.data_cancellazione IS NULL;

ALTER TABLE siac.siac_v_dwh_bil_elem_comp_tipo
    OWNER TO siac;

	

-- /DDL

-- DML

--- impegnabile
insert into siac_d_bil_elem_det_comp_tipo_imp
(
	elem_det_comp_tipo_imp_code,
    elem_det_comp_tipo_imp_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '01',
    'Si',
    now(),
    'SIAC-7349',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_imp tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_imp_code='01'
and   tipo.elem_det_comp_tipo_imp_desc='Si'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);


insert into siac_d_bil_elem_det_comp_tipo_imp
(
	elem_det_comp_tipo_imp_code,
    elem_det_comp_tipo_imp_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '02',
    'No',
    now(),
    'SIAC-7349',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_imp tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_imp_code='02'
and   tipo.elem_det_comp_tipo_imp_desc='No'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);




insert into siac_d_bil_elem_det_comp_tipo_imp
(
	elem_det_comp_tipo_imp_code,
    elem_det_comp_tipo_imp_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '03',
    'Auto',
    now(),
    'SIAC-7349',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_imp tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_imp_code='03'
and   tipo.elem_det_comp_tipo_imp_desc='Auto'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

UPDATE siac.siac_d_bil_elem_det_comp_tipo
   SET  elem_det_comp_tipo_imp_id= (SELECT elem_det_comp_tipo_imp_id FROM siac.siac_d_bil_elem_det_comp_tipo_imp where elem_det_comp_tipo_imp_desc ='Si')
	WHERE  elem_det_comp_macro_tipo_id IN ( SELECT elem_det_comp_macro_tipo_id FROM siac.siac_d_bil_elem_det_comp_macro_tipo	where elem_det_comp_macro_tipo_desc in ('Fresco','Avanzo') );

 UPDATE siac.siac_d_bil_elem_det_comp_tipo
   SET  elem_det_comp_tipo_imp_id= (SELECT elem_det_comp_tipo_imp_id FROM siac.siac_d_bil_elem_det_comp_tipo_imp where elem_det_comp_tipo_imp_desc ='No')
	WHERE  elem_det_comp_macro_tipo_id = ( SELECT elem_det_comp_macro_tipo_id 	FROM siac.siac_d_bil_elem_det_comp_macro_tipo	where elem_det_comp_macro_tipo_desc ='Da attribuire');


UPDATE siac.siac_d_bil_elem_det_comp_tipo
   SET  elem_det_comp_tipo_imp_id= (SELECT elem_det_comp_tipo_imp_id FROM siac.siac_d_bil_elem_det_comp_tipo_imp where elem_det_comp_tipo_imp_desc ='No')
	WHERE  elem_det_comp_macro_tipo_id = ( SELECT elem_det_comp_macro_tipo_id FROM siac.siac_d_bil_elem_det_comp_macro_tipo	where elem_det_comp_macro_tipo_desc ='FPV')
	AND  elem_det_comp_sotto_tipo_id = ( SELECT elem_det_comp_sotto_tipo_id FROM siac.siac_d_bil_elem_det_comp_sotto_tipo	where elem_det_comp_sotto_tipo_desc ='Cumulato' );


UPDATE siac.siac_d_bil_elem_det_comp_tipo
   SET  elem_det_comp_tipo_imp_id= (SELECT elem_det_comp_tipo_imp_id FROM siac.siac_d_bil_elem_det_comp_tipo_imp where elem_det_comp_tipo_imp_desc ='Auto')
	WHERE  elem_det_comp_macro_tipo_id = ( SELECT elem_det_comp_macro_tipo_id  FROM siac.siac_d_bil_elem_det_comp_macro_tipo	where elem_det_comp_macro_tipo_desc ='FPV')
	AND  elem_det_comp_sotto_tipo_id =( SELECT elem_det_comp_sotto_tipo_id 	FROM siac.siac_d_bil_elem_det_comp_sotto_tipo	where elem_det_comp_sotto_tipo_desc ='Applicato' )
	AND  elem_det_comp_tipo_fase_id  IN ( SELECT elem_det_comp_tipo_fase_id FROM siac.siac_d_bil_elem_det_comp_tipo_fase	where elem_det_comp_tipo_fase_desc IN ('Gestione','ROR effettivo'));
-- /DML

select * from fnc_dba_add_column_params ( 'siac_r_movgest_bil_elem', 'elem_det_comp_tipo_id', 'INTEGER');
select * from fnc_dba_add_fk_constraint('siac_r_movgest_bil_elem', 'siac_t_bil_elem_det_comp_tipo_siac_r_movgest_bil_elem', 'elem_det_comp_tipo_id', 'siac_d_bil_elem_det_comp_tipo', 'elem_det_comp_tipo_id');
	

-- function da eseguire presenti nella cartella SIAC-7349 MR 22/05/2020

-- Start fnc_siac_disponibilitaimpegnareugcomp_anno1
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitaimpegnareugcomp_anno1(
	id_in integer,
	idcomp_in integer)
    RETURNS numeric
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE

COMPONENTE_IMPEGNABILE varchar:='Si';

dispImpegnare numeric:=0;
enteProprietarioId integer:=0;
flagImpegnabileComponente varchar:=null;
annoBilancio varchar:=null;
stanzEffettivoRec record;
diCuiImpegnatoRec record;

strMessaggio varchar(1500):=null;
 ---    ANNASILVIA CMTO FORZATURA
ente_prop_in NUMERIC:=0;

BEGIN

 	strMessaggio:='Calcolo disponibile impegnare elem_id='||id_in||
        	          'idcomp_in='||idcomp_in||'.';

	strMessaggio:='Calcolo disponibile impegnare elem_id='||id_in||'idcomp_in='||idcomp_in||
    			  '.Lettura anno di bilancio e tipo elemento bilancio.';
    
 
    -- 04.08.2017 Sofia HD-INC000001937155- commentato in seguito ad approvazione bilancio di previsione
    ---    ANNASILVIA CMTO FORZATURA 13-01-2017 INIZIO 

    /*    select a.ente_proprietario_id 
        into ente_prop_in from siac_t_bil_elem a
        where a.elem_id = id_in;

        if ente_prop_in = 3 then
            	dispImpegnare := 9999999999;
    			return dispImpegnare;
        end if;*/
    ---    ANNASILVIA CMTO FORZATURA 13-01-2017 FINE 
    -- 04.08.2017 Sofia HD-INC000001937155- commentato in seguito ad approvazione bilancio di previsione

    

	select per.anno, bilElem.ente_proprietario_id into strict annoBilancio, enteProprietarioId
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;
    
    --SIAC-7349 
    --Se componente ha flag impegnabile = No o AUTO, restituire dispImpegnare=0
    select tipo.elem_det_comp_tipo_imp_desc into flagImpegnabileComponente
    from siac_d_bil_elem_det_comp_tipo componente 
    join siac_d_bil_elem_det_comp_tipo_imp tipo
    on tipo.elem_det_comp_tipo_imp_id = componente.elem_det_comp_tipo_imp_id
    where componente.elem_det_comp_tipo_id=idcomp_in
    and componente.ente_proprietario_id=enteProprietarioId
    and tipo.ente_proprietario_id=enteProprietarioId;
    /*and componente.validita_fine is null
    and componente.data_cancellazione is null
    and tipo.validita_fine is null 
    and tipo.data_cancellazione is null*/

    if flagImpegnabileComponente <> COMPONENTE_IMPEGNABILE THEN
        dispImpegnare=0;
        return dispImpegnare;
    end if;


    strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||
    			  '.Calcolo stanziamento effettivo per anno='||annoBilancio|| 
				   ' idcomp_in='||idcomp_in||'.';

    select * into stanzEffettivoRec
	from fnc_siac_stanz_effettivo_ug_anno_comp (id_in,annoBilancio,idcomp_in);

    strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||
                  '.Calcolo impegnato per anno='||annobilancio|| 
				  ' idcomp_in='||idcomp_in||'.';

    select * into diCuiImpegnatoRec
    from fnc_siac_dicuiimpegnatoug_comp_anno_comp (id_in,annoBilancio,idcomp_in);

   if stanzEffettivoRec.massimoimpegnabile is null then
     dispImpegnare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;
   ELSE
     if stanzEffettivoRec.massimoimpegnabile<stanzEffettivoRec.stanzEffettivo then
     	dispImpegnare:=stanzEffettivoRec.massimoImpegnabile-diCuiImpegnatoRec.diCuiImpegnato;
     else
	    dispImpegnare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;
     end if;
   end if;

return dispImpegnare;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return -1;
    when no_data_found then
			RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return -1;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return -1;
END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_disponibilitaimpegnareugcomp_anno1(integer, integer)
    OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitaimpegnareugcomp_anno1(integer, integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitaimpegnareugcomp_anno1(integer, integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitaimpegnareugcomp_anno1(integer, integer) TO siac;

-----End fnc_siac_disponibilitaimpegnareugcomp_anno1


---Start fnc_siac_disponibilitaimpegnareugcomp_anno2
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitaimpegnareugcomp_anno2(
	id_in integer,
	idcomp_in integer)
    RETURNS numeric
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE

COMPONENTE_IMPEGNABILE varchar:='Si';

dispImpegnare numeric:=0;
annoBilancio varchar:=null;
enteProprietarioId integer:=0;
flagImpegnabileComponente varchar:=null;
stanzEffettivoRec record;
diCuiImpegnatoRec record;

strMessaggio varchar(1500):=null;
 ---    ANNASILVIA CMTO FORZATURA
ente_prop_in NUMERIC:=0;
BEGIN

 	strMessaggio:='Calcolo disponibile impegnare elem_id='||id_in||
        	          'idcomp_in='||idcomp_in||'.';

	strMessaggio:='Calcolo disponibile impegnare elem_id='||id_in||'idcomp_in='||idcomp_in||
    			  '.Lettura anno di bilancio e tipo elemento bilancio.';

 
-- 04.08.2017 Sofia HD-INC000001937155- commentato in seguito ad approvazione bilancio di previsione
---    ANNASILVIA CMTO FORZATURA 13-01-2017 INIZIO 
     
/*    select a.ente_proprietario_id 
    into ente_prop_in from siac_t_bil_elem a
    where a.elem_id = id_in;
    
    if ente_prop_in = 3 then
        	dispImpegnare := 9999999999;
			return dispImpegnare;
    end if;*/
---    ANNASILVIA CMTO FORZATURA 13-01-2017 FINE 
-- 04.08.2017 Sofia HD-INC000001937155- commentato in seguito ad approvazione bilancio di previsione
 
	select per.anno, bilElem.ente_proprietario_id into strict annoBilancio, enteProprietarioId
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;
    
    --SIAC-7349 
    --Se componente ha flag impegnabile = No o AUTO, restituire dispImpegnare=0
    select tipo.elem_det_comp_tipo_imp_desc into flagImpegnabileComponente
    from siac_d_bil_elem_det_comp_tipo componente 
    join siac_d_bil_elem_det_comp_tipo_imp tipo
    on tipo.elem_det_comp_tipo_imp_id = componente.elem_det_comp_tipo_imp_id
    where componente.elem_det_comp_tipo_id=idcomp_in
    and componente.ente_proprietario_id=enteProprietarioId
    and tipo.ente_proprietario_id=enteProprietarioId;
    /*and componente.validita_fine is null
    and componente.data_cancellazione is null
    and tipo.validita_fine is null 
    and tipo.data_cancellazione is null*/

    if flagImpegnabileComponente <> COMPONENTE_IMPEGNABILE THEN
        dispImpegnare=0;
        return dispImpegnare;
    end if;

    annoBilancio:=((annoBilancio::INTEGER)+1)::varchar;

    strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||
    			  '.Calcolo stanziamento effettivo per anno='||annoBilancio|| 
				   ' idcomp_in='||idcomp_in||'.';

    select * into stanzEffettivoRec
	from fnc_siac_stanz_effettivo_ug_anno_comp (id_in,annoBilancio,idcomp_in);

    strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||
                  '.Calcolo impegnato per anno='||annobilancio|| 
				  ' idcomp_in='||idcomp_in||'.';

    select * into diCuiImpegnatoRec
    from fnc_siac_dicuiimpegnatoug_comp_anno_comp (id_in,annoBilancio,idcomp_in);

   if stanzEffettivoRec.massimoimpegnabile is null then
     dispImpegnare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;
   ELSE
     if stanzEffettivoRec.massimoimpegnabile<stanzEffettivoRec.stanzEffettivo then
     	dispImpegnare:=stanzEffettivoRec.massimoImpegnabile-diCuiImpegnatoRec.diCuiImpegnato;
     else
	    dispImpegnare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;
     end if;
   end if;

return dispImpegnare;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return -1;
    when no_data_found then
			RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return -1;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return -1;
END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_disponibilitaimpegnareugcomp_anno2(integer, integer)
    OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitaimpegnareugcomp_anno2(integer, integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitaimpegnareugcomp_anno2(integer, integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitaimpegnareugcomp_anno2(integer, integer) TO siac;
--end fnc_siac_disponibilitaimpegnareugcomp_anno2


--Start fnc_siac_disponibilitaimpegnareugcomp_anno3
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitaimpegnareugcomp_anno3(
	id_in integer,
	idcomp_in integer)
    RETURNS numeric
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE

COMPONENTE_IMPEGNABILE varchar:='Si';

dispImpegnare numeric:=0;
annoBilancio varchar:=null;
enteProprietarioId integer:=0;
flagImpegnabileComponente varchar:=null;
stanzEffettivoRec record;
diCuiImpegnatoRec record;

strMessaggio varchar(1500):=null;
 ---    ANNASILVIA CMTO FORZATURA
ente_prop_in NUMERIC:=0;

BEGIN

 	strMessaggio:='Calcolo disponibile impegnare elem_id='||id_in||
        	          'idcomp_in='||idcomp_in||'.';

	strMessaggio:='Calcolo disponibile impegnare elem_id='||id_in||'idcomp_in='||idcomp_in||
    			  '.Lettura anno di bilancio e tipo elemento bilancio.';
 
-- 04.08.2017 Sofia HD-INC000001937155- commentato in seguito ad approvazione bilancio di previsione
---    ANNASILVIA CMTO FORZATURA 13-01-2017 INIZIO 
     
/*    select a.ente_proprietario_id 
    into ente_prop_in from siac_t_bil_elem a
    where a.elem_id = id_in;
    
    if ente_prop_in = 3 then
        	dispImpegnare := 9999999999;
			return dispImpegnare;
    end if;
*/	
---    ANNASILVIA CMTO FORZATURA 13-01-2017 FINE 
-- 04.08.2017 Sofia HD-INC000001937155- commentato in seguito ad approvazione bilancio di previsione

	select per.anno, bilElem.ente_proprietario_id into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;
    
    --SIAC-7349 
    --Se componente ha flag impegnabile = No o AUTO, restituire dispImpegnare=0
    select tipo.elem_det_comp_tipo_imp_desc into flagImpegnabileComponente
    from siac_d_bil_elem_det_comp_tipo componente 
    join siac_d_bil_elem_det_comp_tipo_imp tipo
    on tipo.elem_det_comp_tipo_imp_id = componente.elem_det_comp_tipo_imp_id
    where componente.elem_det_comp_tipo_id=idcomp_in
    and componente.ente_proprietario_id=enteProprietarioId
    and tipo.ente_proprietario_id=enteProprietarioId;
    /*and componente.validita_fine is null
    and componente.data_cancellazione is null
    and tipo.validita_fine is null 
    and tipo.data_cancellazione is null*/

    if flagImpegnabileComponente <> COMPONENTE_IMPEGNABILE THEN
        dispImpegnare=0;
        return dispImpegnare;
    end if;

    annoBilancio:=((annoBilancio::INTEGER)+2)::varchar;

    strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||
    			  '.Calcolo stanziamento effettivo per anno='||annoBilancio|| 
				   ' idcomp_in='||idcomp_in||'.';

    select * into stanzEffettivoRec
	from fnc_siac_stanz_effettivo_ug_anno_comp (id_in,annoBilancio,idcomp_in);

    strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||
                  '.Calcolo impegnato per anno='||annobilancio||
       	          ' idcomp_in='||idcomp_in||'.';

    select * into diCuiImpegnatoRec
    from fnc_siac_dicuiimpegnatoug_comp_anno_comp (id_in,annoBilancio,idcomp_in);

    if stanzEffettivoRec.massimoimpegnabile is null then
     dispImpegnare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;
    ELSE
     if stanzEffettivoRec.massimoimpegnabile<stanzEffettivoRec.stanzEffettivo then
     	dispImpegnare:=stanzEffettivoRec.massimoImpegnabile-diCuiImpegnatoRec.diCuiImpegnato;
     else
	    dispImpegnare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;
     end if;
    end if;

return dispImpegnare;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return -1;
    when no_data_found then
			RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return -1;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return -1;
END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_disponibilitaimpegnareugcomp_anno3(integer, integer)
    OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitaimpegnareugcomp_anno3(integer, integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitaimpegnareugcomp_anno3(integer, integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitaimpegnareugcomp_anno3(integer, integer) TO siac;

--end fnc_siac_disponibilitaimpegnareugcomp_anno3

--Start fnc_siac_disponibilitaimpegnareup_anno1
DROP FUNCTION if exists siac.fnc_siac_disponibilitaimpegnareup_anno1(integer);
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitaimpegnareup_anno1(
	id_in integer)
    RETURNS numeric
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE

dispImpegnare numeric:=0;
annoBilancio varchar:=null;

stanzEffettivoRec record;
diCuiImpegnatoRec record;

strMessaggio varchar(1500):=null;
BEGIN

    strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||'.';


	strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||
    			  '.Lettura anno di bilancio.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;


    strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||
    			  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
    select * into stanzEffettivoRec
	from fnc_siac_stanz_effettivo_up_anno (id_in,annoBilancio);

    strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||
                  '.Calcolo impegnato per anno='||annobilancio||'.';
    select * into diCuiImpegnatoRec
    from fnc_siac_dicuiimpegnatoup_comp_anno (id_in,annoBilancio);

    if stanzEffettivoRec.massimoimpegnabile is null then
     dispImpegnare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;
    ELSE
     if stanzEffettivoRec.massimoimpegnabile<stanzEffettivoRec.stanzEffettivo then
     	dispImpegnare:=stanzEffettivoRec.massimoImpegnabile-diCuiImpegnatoRec.diCuiImpegnato;
     else
	    dispImpegnare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;
     end if;
    end if;


return dispImpegnare;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return -1;
    when no_data_found then
			RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return -1;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return -1;
END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_disponibilitaimpegnareup_anno1(integer)
    OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitaimpegnareup_anno1(integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitaimpegnareup_anno1(integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitaimpegnareup_anno1(integer) TO siac;

--end fnc_siac_disponibilitaimpegnareup_anno1

--Start fnc_siac_disponibilitaimpegnareup_anno2
DROP FUNCTION if exists siac.fnc_siac_disponibilitaimpegnareup_anno2(integer);
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitaimpegnareup_anno2(
	id_in integer)
  RETURNS numeric
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE

dispImpegnare numeric:=0;
annoBilancio varchar:=null;

stanzEffettivoRec record;
diCuiImpegnatoRec record;

strMessaggio varchar(1500):=null;
 ---    ANNASILVIA CMTO FORZATURA
ente_prop_in NUMERIC:=0;
BEGIN

    strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||'.';


	strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||
    			  '.Lettura anno di bilancio.';
  
 
-- 04.08.2017 Sofia HD-INC000001937155- commentato in seguito ad approvazione bilancio di previsione
---    ANNASILVIA CMTO FORZATURA 13-01-2017 INIZIO 
     
/*    select a.ente_proprietario_id 
    into ente_prop_in from siac_t_bil_elem a
    where a.elem_id = id_in;
    
    if ente_prop_in = 3 then
        	dispImpegnare := 9999999999;
			return dispImpegnare;
    end if;*/
---    ANNASILVIA CMTO FORZATURA 13-01-2017 FINE 
-- 04.08.2017 Sofia HD-INC000001937155- commentato in seguito ad approvazione bilancio di previsione
 
	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;

    annoBilancio:=((annoBilancio::INTEGER)+1)::varchar;

    strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||
    			  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
    select * into stanzEffettivoRec
	from fnc_siac_stanz_effettivo_up_anno (id_in,annoBilancio);

    strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||
                  '.Calcolo impegnato per anno='||annobilancio||'.';
    select * into diCuiImpegnatoRec
    from fnc_siac_dicuiimpegnatoup_comp_anno (id_in,annoBilancio);

   if stanzEffettivoRec.massimoimpegnabile is null then
     dispImpegnare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;
   ELSE
     if stanzEffettivoRec.massimoimpegnabile<stanzEffettivoRec.stanzEffettivo then
     	dispImpegnare:=stanzEffettivoRec.massimoImpegnabile-diCuiImpegnatoRec.diCuiImpegnato;
     else
	    dispImpegnare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;
     end if;
   end if;


return dispImpegnare;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return -1;
    when no_data_found then
			RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return -1;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return -1;
END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_disponibilitaimpegnareup_anno2(integer)
    OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitaimpegnareup_anno2(integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitaimpegnareup_anno2(integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitaimpegnareup_anno2(integer) TO siac;


--end fnc_siac_disponibilitaimpegnareup_anno2

--Start fnc_siac_disponibilitaimpegnareup_anno3
DROP FUNCTION if exists siac.fnc_siac_disponibilitaimpegnareup_anno3(integer);
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitaimpegnareup_anno3(
	id_in integer)
    RETURNS numeric
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE

dispImpegnare numeric:=0;
annoBilancio varchar:=null;

stanzEffettivoRec record;
diCuiImpegnatoRec record;

strMessaggio varchar(1500):=null;
 ---    ANNASILVIA CMTO FORZATURA
ente_prop_in NUMERIC:=0;

BEGIN

    strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||'.';


	strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||
    			  '.Lettura anno di bilancio.';
 
-- 04.08.2017 Sofia HD-INC000001937155- commentato in seguito ad approvazione bilancio di previsione
---    ANNASILVIA CMTO FORZATURA 13-01-2017 INIZIO 
     
/*    select a.ente_proprietario_id 
    into ente_prop_in from siac_t_bil_elem a
    where a.elem_id = id_in;
    
    if ente_prop_in = 3 then
        	dispImpegnare := 9999999999;
			return dispImpegnare;
    end if;
*/	
---    ANNASILVIA CMTO FORZATURA 13-01-2017 FINE 
-- 04.08.2017 Sofia HD-INC000001937155- commentato in seguito ad approvazione bilancio di previsione



	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;

    annoBilancio:=((annoBilancio::INTEGER)+2)::varchar;

    strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||
    			  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
    select * into stanzEffettivoRec
	from fnc_siac_stanz_effettivo_up_anno (id_in,annoBilancio);

    strMessaggio:='Calcolo disponibilita impegnare elem_id='||id_in||
                  '.Calcolo impegnato per anno='||annobilancio||'.';
    select * into diCuiImpegnatoRec
    from fnc_siac_dicuiimpegnatoup_comp_anno (id_in,annoBilancio);

    if stanzEffettivoRec.massimoimpegnabile is null then
     dispImpegnare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;
    ELSE
     if stanzEffettivoRec.massimoimpegnabile<stanzEffettivoRec.stanzEffettivo then
     	dispImpegnare:=stanzEffettivoRec.massimoImpegnabile-diCuiImpegnatoRec.diCuiImpegnato;
     else
	    dispImpegnare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;
     end if;
    end if;


return dispImpegnare;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return -1;
    when no_data_found then
			RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return -1;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return -1;
END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_disponibilitaimpegnareup_anno3(integer)
    OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitaimpegnareup_anno3(integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitaimpegnareup_anno3(integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitaimpegnareup_anno3(integer) TO siac;
--end fnc_siac_disponibilitaimpegnareup_anno3


--Start fnc_siac_disponibilitavariareupcomp_anno1
DROP FUNCTION if exists siac.fnc_siac_disponibilitavariareupcomp_anno1(integer, integer);
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitavariareupcomp_anno1 (
  id_in integer,
  id_comp integer
)
    RETURNS numeric
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE

/*Constants*/
CAP_UP_TIPO constant varchar:='CAP-UP';

/*Variables*/
dispVariare   numeric:=0;
annoBilancio  varchar:=null;
tipoCapitolo  varchar:=null;
stanzEffettivoRec record;
diCuiImpegnatoRec record;

strMessaggio varchar(1500):=null;
BEGIN

	strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
	' - Id componente='||id_comp||'.';

	strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
    			  '.Lettura anno di bilancio e tipo elemento bilancio.';
	
	/*Calcolo annoBilancio e TipoCapitolo*/
	select per.anno, tipo.elem_tipo_code into strict annoBilancio, tipoCapitolo
	from siac_t_bil_elem bilElem,siac_d_bil_elem_tipo tipo,
         siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in
    and   bilElem.data_cancellazione is null and bilElem.validita_fine is null
    and   tipo.elem_tipo_id=bilElem.elem_tipo_id
    and   bil.bil_id=bilElem.bil_id
    and   per.periodo_id=bil.periodo_id;

	case
      when tipoCapitolo=CAP_UP_TIPO then
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UP_TIPO||
					  'Id componente='||id_comp||
    				  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
	    
		select * into stanzEffettivoRec
		from fnc_siac_stanz_effettivo_up_anno_comp (id_in, id_comp, annoBilancio);

		
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UP_TIPO||
    	              '.Calcolo impegnato per anno='||annobilancio||'.';
	    
		select * into diCuiImpegnatoRec
    	from fnc_siac_dicuiimpegnatoup_comp_anno_comp(id_in, id_comp, annoBilancio, false); --7349 MR Evita la restituzione delle modifiche provvisorie

        dispVariare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;

    end case;


return dispVariare;

exception
   when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return -1;
   when too_many_rows then
    	RAISE EXCEPTION '% Diversi records presenti in archivio.',strMessaggio;
        return -1;
    when no_data_found then
			RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return -1;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return -1;
END;
$BODY$;


ALTER FUNCTION siac.fnc_siac_disponibilitavariareupcomp_anno1 (id_in integer, id_comp integer)
  OWNER TO siac;
 
--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariareupcomp_anno1 (id_in integer, id_comp integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariareupcomp_anno1 (id_in integer, id_comp integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariareupcomp_anno1 (id_in integer, id_comp integer) TO siac;
--end fnc_siac_disponibilitavariareupcomp_anno1

--Start fnc_siac_disponibilitavariareupcomp_anno2
DROP FUNCTION if exists siac.fnc_siac_disponibilitavariareupcomp_anno2(integer, integer);
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitavariareupcomp_anno2 (
  id_in integer,
  id_comp integer
)
    RETURNS numeric
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE

/*Constants*/
CAP_UP_TIPO constant varchar:='CAP-UP';

/*Variables*/
dispVariare   numeric:=0;
annoBilancio  varchar:=null;
tipoCapitolo  varchar:=null;
stanzEffettivoRec record;
diCuiImpegnatoRec record;

strMessaggio varchar(1500):=null;
BEGIN

	strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
	' - Id componente='||id_comp||'.';

	strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
    			  '.Lettura anno di bilancio e tipo elemento bilancio.';
	
	/*Calcolo annoBilancio e TipoCapitolo*/
	select per.anno, tipo.elem_tipo_code into strict annoBilancio, tipoCapitolo
	from siac_t_bil_elem bilElem,siac_d_bil_elem_tipo tipo,
         siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in
    and   bilElem.data_cancellazione is null and bilElem.validita_fine is null
    and   tipo.elem_tipo_id=bilElem.elem_tipo_id
    and   bil.bil_id=bilElem.bil_id
    and   per.periodo_id=bil.periodo_id;

	case
      when tipoCapitolo=CAP_UP_TIPO then
	  	/*Incremento anno di bilancio +1 - riferito all'anno 2*/
	  	annoBilancio:=((annoBilancio::INTEGER)+1)::varchar;
		
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UP_TIPO||
					  'Id componente='||id_comp||
    				  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
	    select * into stanzEffettivoRec
		from fnc_siac_stanz_effettivo_up_anno_comp (id_in, id_comp, annoBilancio);

		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UP_TIPO||
    	              '.Calcolo impegnato per anno='||annobilancio||'.';
	    select * into diCuiImpegnatoRec
    	from fnc_siac_dicuiimpegnatoup_comp_anno_comp(id_in, id_comp, annoBilancio, false); --7349 MR Evita la restituzione delle modifiche provvisorie

        dispVariare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;

    end case;


return dispVariare;

exception
   when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return -1;
   when too_many_rows then
    	RAISE EXCEPTION '% Diversi records presenti in archivio.',strMessaggio;
        return -1;
    when no_data_found then
			RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return -1;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return -1;
END;
$BODY$;


ALTER FUNCTION siac.fnc_siac_disponibilitavariareupcomp_anno2 (id_in integer, id_comp integer)
  OWNER TO siac;
 
--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariareupcomp_anno2 (id_in integer, id_comp integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariareupcomp_anno2 (id_in integer, id_comp integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariareupcomp_anno2 (id_in integer, id_comp integer) TO siac;
--end fnc_siac_disponibilitavariareupcomp_anno2
  

--Start fnc_siac_disponibilitavariareupcomp_anno3
DROP FUNCTION if exists siac.fnc_siac_disponibilitavariareupcomp_anno3(integer, integer);
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitavariareupcomp_anno3 (
  id_in integer,
  id_comp integer
)
    RETURNS numeric
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE


/*Constants*/
CAP_UP_TIPO constant varchar:='CAP-UP';


/*Variables*/
dispVariare   numeric:=0;
annoBilancio  varchar:=null;
tipoCapitolo  varchar:=null;
stanzEffettivoRec record;
diCuiImpegnatoRec record;

strMessaggio varchar(1500):=null;
BEGIN

	strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
	' - Id componente='||id_comp||'.';

	strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
    			  '.Lettura anno di bilancio e tipo elemento bilancio.';

	/*Calcolo annoBilancio e TipoCapitolo*/
	select per.anno, tipo.elem_tipo_code into strict annoBilancio, tipoCapitolo
	from siac_t_bil_elem bilElem,siac_d_bil_elem_tipo tipo,
         siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in
    and   bilElem.data_cancellazione is null and bilElem.validita_fine is null
    and   tipo.elem_tipo_id=bilElem.elem_tipo_id
    and   bil.bil_id=bilElem.bil_id
    and   per.periodo_id=bil.periodo_id;

	case
      when tipoCapitolo=CAP_UP_TIPO then
	  	
		  annoBilancio:=((annoBilancio::INTEGER)+2)::varchar; /*Anno + 2*/
		
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
    		          'Tipo elemento di bilancio='||CAP_UP_TIPO||
					  'Id componente='||id_comp||
    				  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
		select * into stanzEffettivoRec
		from fnc_siac_stanz_effettivo_up_anno_comp (id_in, id_comp, annoBilancio);	
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
    		          'Tipo elemento di bilancio='||CAP_UP_TIPO||
    	              '.Calcolo impegnato per anno='||annobilancio||'.';
		select * into diCuiImpegnatoRec
    	from fnc_siac_dicuiimpegnatoup_comp_anno_comp(id_in, id_comp, annoBilancio, false); --7349 MR Evita la restituzione delle modifiche provvisorie	
    	dispVariare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;

    end case;


return dispVariare;

exception
   when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return -1;
   when too_many_rows then
    	RAISE EXCEPTION '% Diversi records presenti in archivio.',strMessaggio;
        return -1;
    when no_data_found then
			RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return -1;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return -1;
END;
$BODY$;


ALTER FUNCTION siac.fnc_siac_disponibilitavariareupcomp_anno3 (id_in integer, id_comp integer)
  OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariareupcomp_anno3 (id_in integer, id_comp integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariareupcomp_anno3 (id_in integer, id_comp integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariareupcomp_anno3 (id_in integer, id_comp integer) TO siac;
--end fnc_siac_disponibilitavariareupcomp_anno3



--Start fnc_siac_dicuiimpegnatoug_comp_anno_comp
CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno_comp (
  id_in integer,
  anno_in varchar,
  idcomp_in integer,
  verifica_mod_prov boolean = true
)
RETURNS TABLE (
  annocompetenza varchar,
  dicuiimpegnato numeric
) AS
$body$
DECLARE


-- constant
TIPO_CAP_UG constant varchar:='CAP-UG';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';

TIPO_IMP    constant varchar:='I';
TIPO_IMP_T  constant varchar:='T';

STATO_DEF   constant varchar:='D';
STATO_N     constant varchar:='N';
STATO_P     constant varchar:='P';
STATO_A     constant varchar:='A';
IMPORTO_ATT constant varchar:='A';

STATO_MOD_V  constant varchar:='V';
STATO_ATTO_P constant varchar:='PROVVISORIO';

-- anna_economie inizio
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoModifINS  numeric:=0;
-- anna_economie fine

strMessaggio varchar(1500):=NVL_STR;

bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;

movGestTipoId integer:=0;
movGestTsTipoId integer:=0;
movGestStatoId integer:=0;
movGestTsDetTipoId integer:=0;

movGestTsId integer:=0;

importoAttuale numeric:=0;
importoCurAttuale numeric:=0;
importoModifNeg  numeric:=0;

modStatoVId integer:=0;
attoAmmStatoPId integer:=0;

movGestIdRec record;

esisteRmovgestidelemid INTEGER:=0;

BEGIN

select el.elem_id into esisteRmovgestidelemid from siac_r_movgest_bil_elem el, siac_t_movgest mv
where
mv.movgest_id=el.movgest_id
and el.elem_id=id_in
and mv.movgest_anno=anno_in::integer
and el.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
;

 -- 02.02.2016 Sofia JIRA 2947
if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;

if esisteRmovgestidelemid <>0 then

 annoCompetenza:=null;
 diCuiImpegnato:=0;

 strMessaggio:='Calcolo impegnato di competenza elem_id='||id_in||'.Controllo parametri.';

 if anno_in is null or anno_in=NVL_STR then
	 RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
	 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
 end if;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
			   ||'.Calcolo bilancioId enteProprietarioId  annoBilancio.';

 select bil.bil_id,  bil.ente_proprietario_id,  per.anno
        into strict bilancioId, enteProprietarioId, annoBilancio
 from siac_t_bil bil,siac_t_bil_elem bilElem, siac_t_periodo per
 where bilElem.elem_id=id_in
 and   bilElem.data_cancellazione is null
 and   bil.bil_id=bilElem.bil_id
 and   per.periodo_id=bil.periodo_id;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTipoId.';
 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
 from  siac_d_movgest_tipo tipoMovGest
 where tipoMovGest.ente_proprietario_id=enteProprietarioId
 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsTipoId.';

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsStatoId.';

 select movGestStato.movgest_stato_id into strict movGestStatoId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_A;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsDetTipoId.';

 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

 -- 16.03.2017 Sofia JIRA-SIAC-4614
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo modStatoVId.';
 select d.mod_stato_id into strict modStatoVId
 from siac_d_modifica_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.mod_stato_code=STATO_MOD_V;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo attoAmmStatoPId.';
 select d.attoamm_stato_id into strict attoAmmStatoPId
 from siac_d_atto_amm_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.attoamm_stato_code=STATO_ATTO_P;
 -- 16.03.2017 Sofia JIRA-SIAC-4614

 -- anna_economie inizio
 select d.attoamm_stato_id into strict attoAmmStatoDId
 from siac_d_atto_amm_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.attoamm_stato_code=STATO_ATTO_D;
 -- anna_economie fine

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Inizio calcolo totale importo attuale impegni per anno_in='||anno_in||'.';

 --nuovo G
   	importoCurAttuale:=0;

    select tb.importo into importoCurAttuale
 from (
  select
      coalesce(sum(e.movgest_ts_det_importo),0)  importo
      , c.movgest_ts_tipo_id
    from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id=a.movgest_id and
      a.elem_id=id_in and
	  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
      and c.movgest_id=b.movgest_id
      and d.movgest_ts_id=c.movgest_ts_id
      and d.validita_fine is null
      and e.movgest_ts_id=c.movgest_ts_id
	and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
     and e.data_cancellazione is null
     and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
    and e.movgest_ts_det_tipo_id=movGestTsDetTipoId
    group by
   c.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;


 -- 02.02.2016 Sofia JIRA 2947
 if importoCurAttuale is null then importoCurAttuale:=0; end if;

 -- 16.03.2017 Sofia JIRA-SIAC-4614
-- if importoCurAttuale>0 then
 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

  strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Calcolo totale modifiche negative su atti provvisori per anno_in='||anno_in||'.';

 select tb.importo into importoModifNeg
 from
 (
 	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
    	 siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
	     siac_t_movgest_ts_det_mod moddet,
    	 siac_t_modifica mod, siac_r_modifica_stato rmodstato,
	     siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
         siac_d_modifica_tipo tipom
	where rbil.elem_id=id_in
	 and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
	and	  mov.movgest_id=rbil.movgest_id
	and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
    and   mov.movgest_anno=anno_in::integer
    and   mov.bil_id=bilancioId
	and   ts.movgest_id=mov.movgest_id
	and   rstato.movgest_ts_id=ts.movgest_ts_id
	and   rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
	and   tsdet.movgest_ts_id=ts.movgest_ts_id
	and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	and   moddet.movgest_ts_det_importo<0 -- importo negativo
	and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
	and   mod.mod_id=rmodstato.mod_id
	and   atto.attoamm_id=mod.attoamm_id
	and   attostato.attoamm_id=atto.attoamm_id
	and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
    and   tipom.mod_tipo_id=mod.mod_tipo_id
    and   tipom.mod_tipo_code <> 'ECONB'
	-- date
	and rbil.data_cancellazione is null
	and rbil.validita_fine is null
	and mov.data_cancellazione is null
	and mov.validita_fine is null
	and ts.data_cancellazione is null
	and ts.validita_fine is null
	and rstato.data_cancellazione is null
	and rstato.validita_fine is null
	and tsdet.data_cancellazione is null
	and tsdet.validita_fine is null
	and moddet.data_cancellazione is null
	and moddet.validita_fine is null
	and mod.data_cancellazione is null
	and mod.validita_fine is null
	and rmodstato.data_cancellazione is null
	and rmodstato.validita_fine is null
	and attostato.data_cancellazione is null
	and attostato.validita_fine is null
	and atto.data_cancellazione is null
	and atto.validita_fine is null
    group by ts.movgest_ts_tipo_id
  ) tb, siac_d_movgest_ts_tipo tipo
  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
  order by tipo.movgest_ts_tipo_code desc
  limit 1;
  -- 21.06.2017 Sofia - aggiunto parametro verifica_mod_prov, ripreso da prod CmTo dove era stato implementato
  if importoModifNeg is null or verifica_mod_prov is false then importoModifNeg:=0; end if;

  -- anna_economie inizio
   select tb.importo into importoModifINS
 from
 (
 	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
    	 siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
	     siac_t_movgest_ts_det_mod moddet,
    	 siac_t_modifica mod, siac_r_modifica_stato rmodstato,
	     siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
         siac_d_modifica_tipo tipom
	where rbil.elem_id=id_in
	and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
	and	  mov.movgest_id=rbil.movgest_id
	and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
    and   mov.movgest_anno=anno_in::integer
    and   mov.bil_id=bilancioId
	and   ts.movgest_id=mov.movgest_id
	and   rstato.movgest_ts_id=ts.movgest_ts_id
	and   rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
	and   tsdet.movgest_ts_id=ts.movgest_ts_id
	and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	and   moddet.movgest_ts_det_importo<0 -- importo negativo
	and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
	and   mod.mod_id=rmodstato.mod_id
	and   atto.attoamm_id=mod.attoamm_id
	and   attostato.attoamm_id=atto.attoamm_id
	and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
    and   tipom.mod_tipo_id=mod.mod_tipo_id
    and   tipom.mod_tipo_code = 'ECONB'
	-- date
	and rbil.data_cancellazione is null
	and rbil.validita_fine is null
	and mov.data_cancellazione is null
	and mov.validita_fine is null
	and ts.data_cancellazione is null
	and ts.validita_fine is null
	and rstato.data_cancellazione is null
	and rstato.validita_fine is null
	and tsdet.data_cancellazione is null
	and tsdet.validita_fine is null
	and moddet.data_cancellazione is null
	and moddet.validita_fine is null
	and mod.data_cancellazione is null
	and mod.validita_fine is null
	and rmodstato.data_cancellazione is null
	and rmodstato.validita_fine is null
	and attostato.data_cancellazione is null
	and attostato.validita_fine is null
	and atto.data_cancellazione is null
	and atto.validita_fine is null
    group by ts.movgest_ts_tipo_id
  ) tb, siac_d_movgest_ts_tipo tipo
  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
  order by tipo.movgest_ts_tipo_code desc
  limit 1;
  
  if importoModifINS is null then importoModifINS:=0; end if;
  
  -- anna_economie fine

 end if;

 --nuovo G
 importoAttuale:=importoAttuale+importoCurAttuale+abs(importoModifNeg); -- 16.03.2017 Sofia JIRA-SIAC-4614
 --fine nuovoG

 -- anna_economie inizio
 importoAttuale:=importoAttuale+abs(importoModifINS);
 -- anna_economie fine 

 annoCompetenza:=anno_in;
 diCuiImpegnato:=importoAttuale;

 return next;

else

annoCompetenza:=anno_in;
diCuiImpegnato:=0;

return next;

end if;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
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
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno_comp(integer, varchar, integer, boolean)
    OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno_comp(integer, varchar, integer, boolean) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno_comp(integer, varchar, integer, boolean) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno_comp(integer, varchar, integer, boolean) TO siac;

--end fnc_siac_dicuiimpegnatoug_comp_anno_comp


--Start fnc_siac_dicuiimpegnatoup_annisucc
/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoup_annisucc (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE
annoBilancio varchar:=null;
annoEsercizio varchar:=null;
annoMovimento varchar:=null;
impegnatoDefinitivo numeric:=0;
elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;
NVL_STR     constant varchar:='';
faseOpCode varchar(20):=NVL_STR;
bilancioId integer:=0;
elemTipoCode VARCHAR(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;
enteProprietarioId INTEGER:=0;
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
FASE_OP_BIL_PREV constant VARCHAR:='P';
STATO_A     constant varchar:='A';
STATO_P     constant varchar:='P';
TIPO_IMP    constant varchar:='I';
movGestStatoIdAnnullato integer:=0;
movGestStatoIdProvvisorio integer:=0;
movGestTipoId integer:=0;
IMPORTO_ATT constant varchar:='A';
movGestTsDetTipoId integer:=0;
IMPORTO_INIZIALE constant varchar:='I';
movGestTsDetTipoIdIniziale integer:=0;
STATO_MOD_V  constant varchar:='V';
modStatoVId integer:=0;
attoAmmStatoPId integer:=0;
STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoCurAttuale numeric:=0;
esisteRmovgestidelemid INTEGER:=0;
importoModifDelta  numeric:=0;
impegniDaRibaltamento integer:=0;
pluriennaliDaRibaltamento integer:=0;
flagNMaggioreNPiu2 integer:=0;
importoImpegnato integer:=0;

strMessaggio varchar(1500):=null;
BEGIN

    strMessaggio:='Calcolo totale impegnato per anni successivi elem_id='||id_in||'.';

	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;

	strMessaggio:='Calcolo totale impegnato  elem_id='||id_in||'. Lettura anno di bilancio del capitolo UP.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;


	strMessaggio:='Calcolo totale impegnato  elem_id='||id_in||'. Determina capitolo di gestione equivalente in anno esercizio di calcolato. Calcolo bilancioId e elem_tipo_code.';
	 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
	 into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
	 from 	siac_t_bil_elem bilElem,
	 		siac_d_bil_elem_tipo tipoBilElem,
		  	siac_t_bil bil, siac_t_periodo per
	 where bilElem.elem_id=id_in
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
	   and bil.bil_id=bilElem.bil_id
	   and per.periodo_id=bil.periodo_id;

	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UP then
			RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
	 end if;

	 strMessaggio:='Calcolo totale impegnato  elem_id='||id_in||'. Determina capitolo di gestione equivalente in anno esercizio calcolato. Calcolo fase operativa per bilancioId='||bilancioId||' , per ente='||enteProprietarioId||' e per elem_id='||id_in||'.';

	 select  faseOp.fase_operativa_code into  faseOpCode
	 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
	 where bilFase.bil_id =bilancioId
	   and bilfase.data_cancellazione is null
	   and bilFase.validita_fine is null
	   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
	   and faseOp.data_cancellazione is null
	 order by bilFase.bil_fase_operativa_id desc;

	 if NOT FOUND THEN
	   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
	 end if;

	 strMessaggio:='Calcolo impegnato  elem_id='||id_in||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

	 strMessaggio:='Calcolo impegnato competenza anni successivi elem_id='||id_in||
				  '. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO'
				  '. Calcolo movGestTsStatoIdProvvisorio per movgest_stato_code=PROVVISORIO';

	 select movGestStato.movgest_stato_id into strict movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;

	 select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_P;

	 strMessaggio:='Calcolo impegnato competenza anni successivi elem_id='||id_in||
				  '. Calcolo movGestTsDetTipoId per movgest_ts_det_tipo_code=IMPORTO ATTUALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT; --'A'

	 strMessaggio:='Calcolo impegnato competenza anni successivi elem_id='||id_in||
				  '. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE; --'I'

	 strMessaggio:='Calcolo impegnato competenza anni successivi elem_id='||id_in||
              '. Calcolo modStatoVId per mod_stato_code=VALIDO.';
	 select d.mod_stato_id into strict modStatoVId
	 from siac_d_modifica_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.mod_stato_code=STATO_MOD_V;

	 strMessaggio:='Calcolo impegnato competenza anni successivi elem_id='||id_in||
				  '. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	 select d.attoamm_stato_id into strict attoAmmStatoPId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_P;

	 strMessaggio:='Calcolo impegnato competenza anni successivi elem_id='||id_in||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINITIVO';
	 select d.attoamm_stato_id into strict attoAmmStatoDId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_D;

 	-- Calcolo Impegnato definitivo - Anno > N+2:
	-- - Se presenti i movimenti gestione provenienti dal ribaltamento
	--		Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in e anno movimento > N+2 e anno esercizio N
	-- - Se non presenti i movimenti gestione provenienti dal ribaltamento
	-- 		Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in e anno movimento > N+2 e anno esercizio N-1
	-- Il capitolo usato per determinare gli impegni e' quello UG Equivalente

	-- Verifica se presenti i movimenti di gestione provenienti dal ribaltamento
	-- Per "ribaltamento" si intende  il batch di ribaltamento residui che gira prima del ROR
	--		e che "copia" gli impegni dell'anno N-1 nel bilancio dell'anno N (di solito il 2 gennaio)
	-- Per verificare che il batch di ribaltamento sia stato eseguito controllo le seguenti tabelle
	-- 		fase_bil_t_gest_apertura_liq_imp per gli impegni residui
	--  	fase_bil_t_gest_apertura_pluri per i pluriennli (sia impegni che accertamenti)
	-- In entrambe c'e' sia il bil_id che il bil_id_orig ovvero l'anno nuovo su cui si stanno ribaltando i movimenti e l'anno prec
	-- c'e' anche un campo fl_elab che ti dice se i dati sono stati elaborati con scarto o con successo
	strMessaggio:='Calcolo totale impegnato anni successivi elem_id='||id_in||
				 '.Verifica se presenti i movimenti di gestione provenienti dal ribaltamento per anno di esercizio N.';

	impegniDaRibaltamento:=0;
	pluriennaliDaRibaltamento:=0;
	importoCurAttuale:=0;
	importoModifDelta:=0;

	select  count(*) into impegniDaRibaltamento
	from fase_bil_t_gest_apertura_liq_imp fb
	where
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;

	select  count(*) into  pluriennaliDaRibaltamento
	from fase_bil_t_gest_apertura_pluri fb
	where
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;

	if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then

	-- - Se presenti i movimenti gestione provenienti dal ribaltamento
	--		ImpegnatoDefinitivo = Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in
	--		e anno movimento > N+2 e anno esercizio N

		annoEsercizio:=annoBilancio;
		annoMovimento:=((annoBilancio::INTEGER)+2)::varchar;
		flagNMaggioreNPiu2:=1;
	else

		-- - Se non presenti i movimenti gestione provenienti dal ribaltamento
		-- 	ImpegnatoDefinitivo = Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in
		-- 	e anno movimento > N+2 e anno esercizio N-1

		annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
		annoMovimento:=((annoBilancio::INTEGER)+2)::varchar;
		flagNMaggioreNPiu2:=1;
	end if;

	strMessaggio:='Calcolo totale impegnato anni successivi elem_id='||id_in||'. Determina capitolo di gestione equivalente in anno esercizio calcolato.';
				   --Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    -- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo impegnato competenza UP anni successivi.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;
	else

		strMessaggio:='Calcolo totale impegnato anni successivi elem_id='||id_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq||
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento||
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno>annoMovimento::integer
			--and el.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349, punto 21/04/2020
			;

		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;

		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato anni successivi elem_id='||id_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq||
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

			importoCurAttuale:=0;
			select tb.importo into importoCurAttuale
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq  -- UID del capitolo di gestione equivalente
				  --and a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  -- SIAC-7737 GS 31/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  -- and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno > annoMovimento::integer -- anno dell impegno > annoMovimento
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;

			-- 02.02.2016 Sofia JIRA 2947
			 if importoCurAttuale is null then importoCurAttuale:=0; end if;

			 -- 16.03.2017 Sofia JIRA-SIAC-4614
			-- if importoCurAttuale>0 then

			 /*COMMENTO MLR adeguamento 7349 SPRINT-5
			 Non e' piu' richiesto di restituire all'impegnato le modifiche provvisorie 
				if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

				strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq||
				'. Calcolo totale modifiche su atti provvisori per annoMovimento='||annoMovimento||'.';

				select tb.importo into importoModifDelta
				 from
				 (
					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil,
					 	 siac_t_movgest mov,
					 	 siac_t_movgest_ts ts,
						 siac_r_movgest_ts_stato rstato,
					  	 siac_t_movgest_ts_det tsdet,
						 siac_t_movgest_ts_det_mod moddet,
						 siac_t_modifica mod,
					 	 siac_r_modifica_stato rmodstato,
						 siac_r_atto_amm_stato attostato,
					 	 siac_t_atto_amm atto,
						 siac_d_modifica_tipo tipom
					where
						rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
						--and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349 in questo caso, non sulla componente
						and	  mov.movgest_id=rbil.movgest_id
						and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
						and   mov.movgest_anno>annoMovimento::integer -- anno dell impegno = annoMovimento
						and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
						and   ts.movgest_id=mov.movgest_id
						and   rstato.movgest_ts_id=ts.movgest_ts_id
						and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
						and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
					    and   tsdet.movgest_ts_id=ts.movgest_ts_id
						and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
					 	and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
						and   tipom.mod_tipo_id=mod.mod_tipo_id
						and   tipom.mod_tipo_code <> 'ECONB'
						-- date
						and rbil.data_cancellazione is null
						and rbil.validita_fine is null
						and mov.data_cancellazione is null
						and mov.validita_fine is null
						and ts.data_cancellazione is null
						and ts.validita_fine is null
						and rstato.data_cancellazione is null
						and rstato.validita_fine is null
						and tsdet.data_cancellazione is null
						and tsdet.validita_fine is null
						and moddet.data_cancellazione is null
						and moddet.validita_fine is null
						and mod.data_cancellazione is null
						and mod.validita_fine is null
						and rmodstato.data_cancellazione is null
						and rmodstato.validita_fine is null
						and attostato.data_cancellazione is null
						and attostato.validita_fine is null
						and atto.data_cancellazione is null
						and atto.validita_fine is null
						group by ts.movgest_ts_tipo_id
					  ) tb, siac_d_movgest_ts_tipo tipo
					  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
					  order by tipo.movgest_ts_tipo_code desc
					  limit 1;

 				if importoModifDelta is null then importoModifDelta:=0; end if;


			end if;		*/
		end if;
	end if;
    --FIX 7349 SPRINT5
    importoModifDelta:=0;
    --END FIX
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente per l'anno N-1
	impegnatoDefinitivo:=impegnatoDefinitivo+importoCurAttuale-(importoModifDelta);

	return impegnatoDefinitivo;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return -1;
    when no_data_found then
	RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return -1;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return -1;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100;


ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoup_annisucc (id_in integer)
  OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_annisucc (id_in integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_annisucc (id_in integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_annisucc (id_in integer) TO siac;
    
--end fnc_siac_dicuiimpegnatoup_annisucc

--Start fnc_siac_dicuiimpegnatoup_annoprec
/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoup_annoprec (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE
annoBilancio varchar:=null;
annoEsercizio varchar:=null;
annoMovimento varchar:=null;
impegnatoDefinitivo numeric:=0;
elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;
NVL_STR     constant varchar:='';
faseOpCode varchar(20):=NVL_STR;
bilancioId integer:=0;
elemTipoCode VARCHAR(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;
enteProprietarioId INTEGER:=0;
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
FASE_OP_BIL_PREV constant VARCHAR:='P';
STATO_A     constant varchar:='A';
STATO_P     constant varchar:='P';
TIPO_IMP    constant varchar:='I';
movGestStatoIdAnnullato integer:=0;
movGestStatoIdProvvisorio integer:=0;
movGestTipoId integer:=0;
IMPORTO_ATT constant varchar:='A';
movGestTsDetTipoId integer:=0;
IMPORTO_INIZIALE constant varchar:='I';
movGestTsDetTipoIdIniziale integer:=0;
STATO_MOD_V  constant varchar:='V';
modStatoVId integer:=0;
attoAmmStatoPId integer:=0;
STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoCurAttuale numeric:=0;
esisteRmovgestidelemid INTEGER:=0;
importoModifDelta  numeric:=0;
impegniDaRibaltamento integer:=0;
pluriennaliDaRibaltamento integer:=0;
flagNMaggioreNPiu2 integer:=0;
importoImpegnato integer:=0;

strMessaggio varchar(1500):=null;
BEGIN



    strMessaggio:='Calcolo totale impegnato anno precedente elem_id='||id_in||'.';

	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;

	strMessaggio:='Calcolo totale impegnato anno precedente elem_id='||id_in||'. Lettura anno di bilancio del capitolo UP.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;


	strMessaggio:='Calcolo totale impegnato anno precedente elem_id='||id_in||'. Determina capitolo di gestione equivalente in anno esercizio di calcolato. Calcolo bilancioId e elem_tipo_code.';
	 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
	 into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
	 from 	siac_t_bil_elem bilElem,
	 		siac_d_bil_elem_tipo tipoBilElem,
		  	siac_t_bil bil, siac_t_periodo per
	 where bilElem.elem_id=id_in
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
	   and bil.bil_id=bilElem.bil_id
	   and per.periodo_id=bil.periodo_id;

	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UP then
			RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
	 end if;

	 strMessaggio:='Calcolo totale impegnato anno precedente elem_id='||id_in||'. Determina capitolo di gestione equivalente in anno esercizio calcolato. Calcolo fase operativa per bilancioId='||bilancioId||' , per ente='||enteProprietarioId||' e per elem_id='||id_in||'.';

	 select  faseOp.fase_operativa_code into  faseOpCode
	 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
	 where bilFase.bil_id =bilancioId
	   and bilfase.data_cancellazione is null
	   and bilFase.validita_fine is null
	   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
	   and faseOp.data_cancellazione is null
	 order by bilFase.bil_fase_operativa_id desc;

	 if NOT FOUND THEN
	   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
	 end if;

	 strMessaggio:='Calcolo impegnato anno precedente elem_id='||id_in||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

	 strMessaggio:='Calcolo impegnato anno precedente elem_id='||id_in||
				  '. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO'
				  '. Calcolo movGestTsStatoIdProvvisorio per movgest_stato_code=PROVVISORIO';

	 select movGestStato.movgest_stato_id into strict movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;

	 select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_P;

	 strMessaggio:='Calcolo impegnato anno precedente elem_id='||id_in||
				  '. Calcolo movGestTsDetTipoId per movgest_ts_det_tipo_code=IMPORTO ATTUALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT; --'A'

	 strMessaggio:='Calcolo impegnato anno precedente elem_id='||id_in||
				  '. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE; --'I'

	 strMessaggio:='Calcolo impegnato anno precedente elem_id='||id_in||
              '. Calcolo modStatoVId per mod_stato_code=VALIDO.';
	 select d.mod_stato_id into strict modStatoVId
	 from siac_d_modifica_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.mod_stato_code=STATO_MOD_V;

	 strMessaggio:='Calcolo impegnato anno precedente elem_id='||id_in||
				  '. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	 select d.attoamm_stato_id into strict attoAmmStatoPId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_P;

	 strMessaggio:='Calcolo impegnato anno precedente elem_id='||id_in||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINITIVO';
	 select d.attoamm_stato_id into strict attoAmmStatoDId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_D;

 	-- Calcolo Impegnato per  Anno = N-1 :

	importoCurAttuale:=0;
	importoModifDelta:=0;
	annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
	annoMovimento:=((annoBilancio::INTEGER)-1)::varchar;


	strMessaggio:='Calcolo totale impegnato anno precedente elem_id='||id_in||'. Determina capitolo di gestione equivalente in anno esercizio calcolato.';
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo impegnato anno precedente UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;
	else

		strMessaggio:='Calcolo totale impegnato anno precedente elem_id='||id_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq||
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento||
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno=annoMovimento::integer
			--and el.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349, punto 21/04/2020
			;

		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;

		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato anno precedente elem_id='||id_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq||
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

			importoCurAttuale:=0;
			select tb.importo into importoCurAttuale
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq  -- UID del capitolo di gestione equivalente
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  -- SIAC-7737 GS 31/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  -- and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno = annoMovimento::integer -- anno dell impegno = annoMovimento
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;

			-- 02.02.2016 Sofia JIRA 2947
			 if importoCurAttuale is null then importoCurAttuale:=0; end if;

			 -- 16.03.2017 Sofia JIRA-SIAC-4614
			-- if importoCurAttuale>0 then

			 /*COMMENTO MLR adeguamento 7349 SPRINT-5
			 Non si deve piu' restituire le modifiche provvisorie e le ECONB all'impegnato
			 
				if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

				strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq||
				'. Calcolo totale modifiche su atti provvisori per annoMovimento='||annoMovimento||'.';

				select tb.importo into importoModifDelta
				 from
				 (
					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil,
					 	 siac_t_movgest mov,
					 	 siac_t_movgest_ts ts,
						 siac_r_movgest_ts_stato rstato,
					  	 siac_t_movgest_ts_det tsdet,
						 siac_t_movgest_ts_det_mod moddet,
						 siac_t_modifica mod,
					 	 siac_r_modifica_stato rmodstato,
						 siac_r_atto_amm_stato attostato,
					 	 siac_t_atto_amm atto,
						 siac_d_modifica_tipo tipom
					where
						rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
						--and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349 in questo caso, non sulla componente
						and	  mov.movgest_id=rbil.movgest_id
						and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
						and   mov.movgest_anno>annoMovimento::integer -- anno dell impegno = annoMovimento
						and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
						and   ts.movgest_id=mov.movgest_id
						and   rstato.movgest_ts_id=ts.movgest_ts_id
						and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
						and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
					    and   tsdet.movgest_ts_id=ts.movgest_ts_id
						and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
						and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
						and   tipom.mod_tipo_id=mod.mod_tipo_id
						and   tipom.mod_tipo_code <> 'ECONB'
						-- date
						and rbil.data_cancellazione is null
						and rbil.validita_fine is null
						and mov.data_cancellazione is null
						and mov.validita_fine is null
						and ts.data_cancellazione is null
						and ts.validita_fine is null
						and rstato.data_cancellazione is null
						and rstato.validita_fine is null
						and tsdet.data_cancellazione is null
						and tsdet.validita_fine is null
						and moddet.data_cancellazione is null
						and moddet.validita_fine is null
						and mod.data_cancellazione is null
						and mod.validita_fine is null
						and rmodstato.data_cancellazione is null
						and rmodstato.validita_fine is null
						and attostato.data_cancellazione is null
						and attostato.validita_fine is null
						and atto.data_cancellazione is null
						and atto.validita_fine is null
						group by ts.movgest_ts_tipo_id
					  ) tb, siac_d_movgest_ts_tipo tipo
					  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
					  order by tipo.movgest_ts_tipo_code desc
					  limit 1;

 				if importoModifDelta is null then importoModifDelta:=0; end if;


			end if;		*/
		end if;
	end if;
    --FIX 7349 SPRINT 5
    importoModifDelta:=0;
    --END FIX
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente per l'anno N-1
	impegnatoDefinitivo:=impegnatoDefinitivo+importoCurAttuale-(importoModifDelta);

	return impegnatoDefinitivo;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        impegnatoDefinitivo:=0;
        return impegnatoDefinitivo;
    when no_data_found then
    	RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        impegnatoDefinitivo:=0;
        return impegnatoDefinitivo;
    when others  THEN
    	RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        impegnatoDefinitivo:=0;
        return impegnatoDefinitivo;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100;


ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoup_annoprec (id_in integer)
  OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_annoprec(integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_annoprec(integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_annoprec(integer) TO siac;
--end fnc_siac_dicuiimpegnatoup_annoprec

--Start fnc_siac_dicuiimpegnatoup_comp_anno_comp
CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno_comp(
	id_in integer,
	id_comp integer,
	anno_in character varying,
	verifica_mod_prov boolean = true)
    RETURNS TABLE(annocompetenza character varying, dicuiimpegnato numeric) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
AS $BODY$
DECLARE
/* 
Calcolo dell'impegnato di un capitolo di previsione id_in su una componente id_comp per l'anno anno_it,
utile al calcolo della disponibilita' a variare
quindi non tiene conto di grandezze da considerare solo per disponibilita' ad impegnare: limite massimo impegnabile e modifiche di impegno negative su provvedimento provvisorio
*/

-- constant
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';

FASE_OP_BIL_PREV constant VARCHAR:='P';

STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';

STATO_MOD_V  constant varchar:='V';

TIPO_IMP    constant varchar:='I';
TIPO_IMP_T  constant varchar:='T';

STATO_DEF   constant varchar:='D';
STATO_N     constant varchar:='N';
STATO_P     constant varchar:='P';
STATO_A     constant varchar:='A';
IMPORTO_ATT constant varchar:='A';

strMessaggio varchar(1500):=NVL_STR;

attoAmmStatoDId integer:=0;
attoAmmStatoPId integer:=0;
bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;

modStatoVId integer:=0;
movGestTipoId integer:=0;
movGestTsTipoId integer:=0;
movGestStatoId integer:=0;
movGestTsDetTipoId integer:=0;
movGestStatoIdProvvisorio integer:=0;
movGestTsId integer:=0;


importoAttuale numeric:=0;
importoCurAttuale numeric:=0;
importoModifDelta  numeric:=0;
importoModifINS numeric:=0; --aggiunta per ECONB

movGestIdRec record;

elemTipoCode VARCHAR(20):=NVL_STR;
faseOpCode varchar(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;

elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;

BEGIN

 annoCompetenza:=null;
 diCuiImpegnato:=0;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.Controllo parametri.';

 if anno_in is null or anno_in=NVL_STR then
	 RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
	 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
 end if;

 strMessaggio:='Calcolo impegnato competenza UP elem_id='||id_in||'.';

 strMessaggio:='Calcolo impegnato competenza UP.Calcolo bilancioId e elem_tipo_code per elem_id='||id_in||'.';
 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
       into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem,
      siac_t_bil bil, siac_t_periodo per
 where bilElem.elem_id=id_in
   and bilElem.data_cancellazione is null
   and bilElem.validita_fine is null
   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
   and bil.bil_id=bilElem.bil_id
   and per.periodo_id=bil.periodo_id;

 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UP then
        RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
 end if;

 strMessaggio:='Calcolo impegnato competenza UP.Calcolo fase operativa per bilancioId='||bilancioId
               ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

 select  faseOp.fase_operativa_code into  faseOpCode
 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
 where bilFase.bil_id =bilancioId
   and bilfase.data_cancellazione is null
   and bilFase.validita_fine is null
   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
   and faseOp.data_cancellazione is null
 order by bilFase.bil_fase_operativa_id desc;

 if NOT FOUND THEN
   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
 end if;

 strMessaggio:='Calcolo impegnato competenza UP.Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
              ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
 -- lettura elemento bil di gestione equivalente
 if faseOpCode is not null and faseOpCode!=NVL_STR then
  	if  faseOpCode = FASE_OP_BIL_PREV then
      	-- lettura bilancioId annoBilancio precedente per lettura elemento di bilancio equivalente
            	select bil.bil_id into strict bilIdElemGestEq
                from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
                where per.anno=((annoBilancio::integer)-1)::varchar
                  and per.ente_proprietario_id=enteProprietarioId
                  and bil.periodo_id=per.periodo_id
                  and perTipo.periodo_tipo_id=per.periodo_tipo_id
                  and perTipo.periodo_tipo_code='SY';
    else
        	bilIdElemGestEq:=bilancioId;
    end if;
 else
	 RAISE EXCEPTION '% Fase non valida.',strMessaggio;
 end if;

 -- lettura elemIdGestEq
 strMessaggio:='Calcolo impegnato competenza UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
              ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

 select bilelem.elem_id into elemIdGestEq
 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
 where bilElem.elem_code=elemCode
   and bilElem.elem_code2=elemCode2
   and bilElem.elem_code3=elemCode3
   and bilElem.ente_proprietario_id=enteProprietarioId
   and bilElem.data_cancellazione is null
   and bilElem.validita_fine is null
   and bilElem.bil_id=bilIdElemGestEq
   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

if NOT FOUND THEN
else
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTipoId.';
 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
 from  siac_d_movgest_tipo tipoMovGest
 where tipoMovGest.ente_proprietario_id=enteProprietarioId
 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTsTipoId.';
 select movGestTsTipo.movgest_ts_tipo_id into strict movGestTsTipoId
 from siac_d_movgest_ts_tipo movGestTsTipo
 where movGestTsTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsTipo.movgest_ts_tipo_code=TIPO_IMP_T;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
               ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTsStatoId.';

 select movGestStato.movgest_stato_id into strict movGestStatoId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_A;
 
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||id_comp
				  ||'. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	  select d.attoamm_stato_id into strict attoAmmStatoPId
	  from siac_d_atto_amm_stato d
	  where d.ente_proprietario_id=enteProprietarioId
	  and d.attoamm_stato_code=STATO_ATTO_P;
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||id_comp
				  ||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINTIVO';
	  
	  select d.attoamm_stato_id into strict attoAmmStatoDId
	  from siac_d_atto_amm_stato d
	  where d.ente_proprietario_id=enteProprietarioId
	  and  d.attoamm_stato_code=STATO_ATTO_D;
	
	select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	  from siac_d_movgest_stato movGestStato
	  where movGestStato.ente_proprietario_id=enteProprietarioId
	  and   movGestStato.movgest_stato_code=STATO_P;
	 
	select d.mod_stato_id into strict modStatoVId
	  from siac_d_modifica_stato d
	  where d.ente_proprietario_id=enteProprietarioId
	  and   d.mod_stato_code=STATO_MOD_V;

	  

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
               ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTsDetTipoId.';

 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
              ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'. Inizio ciclo per anno_in='||anno_in||'.';
 for movGestIdRec in
 (
     select movGestRel.movgest_id
     from siac_r_movgest_bil_elem movGestRel
     where movGestRel.elem_id=elemIdGestEq
     and   movGestRel.data_cancellazione is null
	 and movGestRel.elem_det_comp_tipo_id=id_comp
     and   exists (select 1 from siac_t_movgest movGest
   				   where movGest.movgest_id=movGestRel.movgest_id
			       and	 movGest.bil_id = bilIdElemGestEq
			       and   movGest.movgest_tipo_id=movGestTipoId
				   and   movGest.movgest_anno = anno_in::integer
                   and   movGest.data_cancellazione is null
                   and   movGest.validita_fine is null)
 )
 loop
   	importoCurAttuale:=0;

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
				      ||'.Per elemento gest equivalente elem_id='||elemIdGestEq
                      ||'.Calcolo impegnato anno_in='||anno_in
                      ||'.Lettura siac_t_movgest_ts movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';

    select movgestts.movgest_ts_id into  movGestTsId
    from siac_t_movgest_ts movGestTs
    where movGestTs.movgest_id = movGestIdRec.movgest_id
    and   movGestTs.data_cancellazione is null
    and   movGestTs.movgest_ts_tipo_id=movGestTsTipoId
    and   exists (select 1 from siac_r_movgest_ts_stato movGestTsRel
                  where movGestTsRel.movgest_ts_id=movGestTs.movgest_ts_id
                  and   movGestTsRel.movgest_stato_id!=movGestStatoId
                  and   movGestTsRel.validita_fine is null
                  and   movGestTsRel.data_cancellazione is null);
	


    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
				      ||'.Per elemento gest equivalente elem_id='||elemIdGestEq
                      ||'.Calcolo accertato anno_in='||anno_in||'.Somma siac_t_movgest_ts_det movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';
    if NOT FOUND then
    else
       select coalesce(sum(movGestTsDet.movgest_ts_det_importo),0) into importoCurAttuale
           from siac_t_movgest_ts_det movGestTsDet
           where movGestTsDet.movgest_ts_id=movGestTsId
           and   movGestTsDet.movgest_ts_det_tipo_id=movGestTsDetTipoId;
		   
	   if importoCurAttuale>=0 then  

		  select tb.importo into importoModifDelta
				from
				(
					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil,
					 	siac_t_movgest mov,
					 	siac_t_movgest_ts ts,
						siac_r_movgest_ts_stato rstato,
					  siac_t_movgest_ts_det tsdet,
						siac_t_movgest_ts_det_mod moddet,
						siac_t_modifica mod,
					 	siac_r_modifica_stato rmodstato,
						siac_r_atto_amm_stato attostato,
					 	siac_t_atto_amm atto,
						siac_d_modifica_tipo tipom
					where
						rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
						and rbil.elem_det_comp_tipo_id=id_comp::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
						and	 mov.movgest_id=rbil.movgest_id
						and  mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
						and  mov.movgest_anno=anno_in::integer -- anno dell impegno = annoMovimento
						and  mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
						and  ts.movgest_id=mov.movgest_id
						and  rstato.movgest_ts_id=ts.movgest_ts_id
						and  rstato.movgest_stato_id!=movGestStatoId -- Impegno non ANNULLATO
						and  rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
					  and  tsdet.movgest_ts_id=ts.movgest_ts_id
						and  moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and  moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
						and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
						and   tipom.mod_tipo_id=mod.mod_tipo_id
						and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
						-- date
						and rbil.data_cancellazione is null
						and rbil.validita_fine is null
						and mov.data_cancellazione is null
						and mov.validita_fine is null
						and ts.data_cancellazione is null
						and ts.validita_fine is null
						and rstato.data_cancellazione is null
						and rstato.validita_fine is null
						and tsdet.data_cancellazione is null
						and tsdet.validita_fine is null
						and moddet.data_cancellazione is null
						and moddet.validita_fine is null
						and mod.data_cancellazione is null
						and mod.validita_fine is null
						and rmodstato.data_cancellazione is null
						and rmodstato.validita_fine is null
						and attostato.data_cancellazione is null
						and attostato.validita_fine is null
						and atto.data_cancellazione is null
						and atto.validita_fine is null
						group by ts.movgest_ts_tipo_id
					  ) tb, siac_d_movgest_ts_tipo tipo
					  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
					  order by tipo.movgest_ts_tipo_code desc
					  limit 1;
				-- 14.05.2020 Manuel - aggiunto parametro verifica_mod_prov
				if importoModifDelta is null or verifica_mod_prov is false then importoModifDelta:=0; end if;
		
		/*Aggiunta delle modifiche ECONB*/
				 -- anna_economie inizio
   				select tb.importo into importoModifINS
 				from
 				(
 					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
 			   	 	siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
				    siac_t_movgest_ts_det_mod moddet,
 			   	 	siac_t_modifica mod, siac_r_modifica_stato rmodstato,
				    siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
 			        siac_d_modifica_tipo tipom
				where rbil.elem_id=elemIdGestEq
				and rbil.elem_det_comp_tipo_id=id_comp::integer --SIAC-7349
				and	  mov.movgest_id=rbil.movgest_id
				and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
 			   	and   mov.movgest_anno=anno_in::integer
 			   	and   mov.bil_id=bilancioId
				and   ts.movgest_id=mov.movgest_id
				and   rstato.movgest_ts_id=ts.movgest_ts_id
				and   rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
				and   tsdet.movgest_ts_id=ts.movgest_ts_id
				and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
				and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
				and   moddet.movgest_ts_det_importo<0 -- importo negativo
				and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
				and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
				and   mod.mod_id=rmodstato.mod_id
				and   atto.attoamm_id=mod.attoamm_id
				and   attostato.attoamm_id=atto.attoamm_id
				and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
 			   and   tipom.mod_tipo_id=mod.mod_tipo_id
 			   and   tipom.mod_tipo_code = 'ECONB'
				-- date
				and rbil.data_cancellazione is null
				and rbil.validita_fine is null
				and mov.data_cancellazione is null
				and mov.validita_fine is null
				and ts.data_cancellazione is null
				and ts.validita_fine is null
				and rstato.data_cancellazione is null
				and rstato.validita_fine is null
				and tsdet.data_cancellazione is null
				and tsdet.validita_fine is null
				and moddet.data_cancellazione is null
				and moddet.validita_fine is null
				and mod.data_cancellazione is null
				and mod.validita_fine is null
				and rmodstato.data_cancellazione is null
				and rmodstato.validita_fine is null
				and attostato.data_cancellazione is null
				and attostato.validita_fine is null
				and atto.data_cancellazione is null
				and atto.validita_fine is null
 			   group by ts.movgest_ts_tipo_id
 			 ) tb, siac_d_movgest_ts_tipo tipo
 			 where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
 			 order by tipo.movgest_ts_tipo_code desc
 			 limit 1;
			 
			 if importoModifINS is null then 
			 	importoModifINS = 0;
			 end if;
		   
		   
		   
		   end if;
		   
    end if;

    importoAttuale:=importoAttuale+importoCurAttuale-(importoModifDelta);
  --aggiunta per ECONB
	importoAttuale:=importoAttuale+abs(importoModifINS);
 end loop;
end if;

annoCompetenza:=anno_in;
diCuiImpegnato:=importoAttuale;

return next;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
	when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno_comp(integer, integer, character varying, boolean)
    OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno_comp(integer, integer, character varying, boolean) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno_comp(integer, integer, character varying, boolean) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno_comp(integer, integer, character varying, boolean) TO siac;
--end fnc_siac_dicuiimpegnatoup_comp_anno_comp    
    
--Start fnc_siac_impegnatodefinitivoup_comp_annisucc_nostanz
CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp_annisucc_nostanz(
	id_in integer,
	idcomp_in INT[])
    RETURNS TABLE(
    	elemdetcompid integer, 
    	elemdetcompdesc character varying,
    	impegnatodefinitivo numeric,
		elemdetcompmacrotipodesc character varying) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
AS $BODY$
DECLARE


annoBilancio varchar:=null;
annoEsercizio varchar:=null;
annoMovimento varchar:=null;

elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;
NVL_STR     constant varchar:='';
faseOpCode varchar(20):=NVL_STR;
bilancioId integer:=0;
elemTipoCode VARCHAR(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;
enteProprietarioId INTEGER:=0;
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
FASE_OP_BIL_PREV constant VARCHAR:='P';
STATO_A     constant varchar:='A';
STATO_P     constant varchar:='P';
TIPO_IMP    constant varchar:='I';
movGestStatoIdAnnullato integer:=0;
movGestStatoIdProvvisorio integer:=0;
movGestTipoId integer:=0;
IMPORTO_ATT constant varchar:='A';
movGestTsDetTipoId integer:=0;
IMPORTO_INIZIALE constant varchar:='I';
movGestTsDetTipoIdIniziale integer:=0;
STATO_MOD_V  constant varchar:='V';
modStatoVId integer:=0;
attoAmmStatoPId integer:=0;
STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoCurAttuale numeric:=0;
esisteRmovgestidelemid INTEGER:=0;
importoModifDelta  numeric:=0;
importoModifINS numeric:=0; --aggiunta per ECONB
impegniDaRibaltamento integer:=0;
pluriennaliDaRibaltamento integer:=0;
flagNMaggioreNPiu2 integer:=0;
flagDeltaPagamenti integer:=0;
importoImpegnato numeric:=0;
importoPagatoDelta numeric:=0;
ordStatoAId          integer:=null;
ordTsDetTipoAId      integer:=null;
-- stati ordinativi
STATO_ORD_A    constant varchar:='A'; -- ANNULLATO
-- importoAttuale ordinativi
ORD_TS_DET_TIPO_A  constant varchar:='A';

sidcomp_in  varchar:=null;
strMessaggio varchar(1500):=null;

impComponenteRec record;

BEGIN

/* Calcola impegnato definitivo per quelle componenti per le quali pur non essendoci stanziamento
 * esistono quote di impegnato nell'anno > N+2 
 * Le componenti per le quali esiste stanziamento (e quindi da non considerare) sono passate in input nell'array idcomp_in
 * NOTA: per problemi Java/Hibernate idcomp_in non puo' essere un array vuoto, quindi 
 *		l'array in input conterra' sempre la componente fittizia idcomp = -1
 */
-- CALCOLO IMPEGNATO DEFINITIVO 
-- Stiamo sempre parlando di impegnato sul capitolo di gestione equivalente	
-- I valori di impegnato dovranno essere calcolati tenendo conto del solo impegnato definitivo.
-- Escluse dal calcolo quindi:
--     le modifiche di impegno provvisorie (modifiche con provvedimento in stato provvisorio - di qualsiasi segno
--     gli  impegni in stato provvisorio

	sidcomp_in:=array_to_string(idcomp_in, ',');
    strMessaggio:='Calcolo totale impegnato definitovo elem_id='||id_in|| ' escludo idcomp_in='||sidcomp_in|| '.';

	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;
 
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||
    			  '.Lettura anno di bilancio del capitolo UP.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;
		  

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||
    			  '. Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId e elem_tipo_code.';
	 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
	 into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
	 from 	siac_t_bil_elem bilElem, 
	 		siac_d_bil_elem_tipo tipoBilElem,
		  	siac_t_bil bil, siac_t_periodo per
	 where bilElem.elem_id=id_in
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
	   and bil.bil_id=bilElem.bil_id
	   and per.periodo_id=bil.periodo_id;

	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UP then
			RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
	 end if;

	 strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||
				   '. Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   'Calcolo fase operativa per bilancioId='||bilancioId
				   ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select  faseOp.fase_operativa_code into  faseOpCode
	 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
	 where bilFase.bil_id =bilancioId
	   and bilfase.data_cancellazione is null
	   and bilFase.validita_fine is null
	   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
	   and faseOp.data_cancellazione is null
	 order by bilFase.bil_fase_operativa_id desc;

	 if NOT FOUND THEN
	   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
	 end if;

	 strMessaggio:='Calcolo impegnato definitivo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO'
				  ||'. Calcolo movGestTsStatoIdProvvisorio per movgest_stato_code=PROVVISORIO';

	 select movGestStato.movgest_stato_id into strict movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;

	 select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_P; 
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTsDetTipoId per movgest_ts_det_tipo_code=IMPORTO ATTUALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE;
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
              ||'. Calcolo modStatoVId per mod_stato_code=VALIDO.';
	 select d.mod_stato_id into strict modStatoVId
	 from siac_d_modifica_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.mod_stato_code=STATO_MOD_V;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	 select d.attoamm_stato_id into strict attoAmmStatoPId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_P;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINITIVO';
	 select d.attoamm_stato_id into strict attoAmmStatoDId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_D;

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
				 '.Verifica se presenti i movimenti di gestione provenienti dal ribaltamento per anno di esercizio N.';
	
	impegniDaRibaltamento:=0;
	pluriennaliDaRibaltamento:=0;
	importoCurAttuale:=0;	
	importoModifDelta:=0;
	importoModifINS := 0;
	
	select  count(*) into impegniDaRibaltamento 
	from fase_bil_t_gest_apertura_liq_imp fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;

	select  count(*) into  pluriennaliDaRibaltamento
	from fase_bil_t_gest_apertura_pluri fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;
				
	if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then

	--  Se presenti i movimenti gestione provenienti dal ribaltamento 
	--		ImpegnatoDefinitivo = Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in 
	--		e anno movimento > N+2 e anno esercizio N

		annoEsercizio:=annoBilancio;
		annoMovimento:=((annoBilancio::INTEGER)+2)::varchar;
		flagNMaggioreNPiu2:=1;
	else

		--  Se non presenti i movimenti gestione provenienti dal ribaltamento 
		-- 	ImpegnatoDefinitivo = Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in 
		-- 	e anno movimento > N+2 e anno esercizio N-1

		annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
		annoMovimento:=((annoBilancio::INTEGER)+2)::varchar;
		flagNMaggioreNPiu2:=1;
	end if;
	
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    -- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo impegnato competenza UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else
	
		strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento|| 
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid 
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno>annoMovimento::integer 
			and NOT (el.elem_det_comp_tipo_id = ANY( idcomp_in)) --SIAC-7349
			;
		
		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;
	
		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

/*			importoCurAttuale:=0;			
			select tb.importo into importoCurAttuale
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
				  NOT ( a.elem_det_comp_tipo_id = ANY( idcomp_in))--SIAC-7349 non deve essere sulla componente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno > annoMovimento::integer -- anno dell impegno > annoMovimento 
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;		
*/

			/* Versione con group by per le componenti non da escludere e ciclo per ogni componente */
			for impComponenteRec in
			 (
				select tb.elem_det_comp_tipo_id as compId, 
				 g.elem_det_comp_tipo_desc as compDesc, 
				 tb.importo as importoCurAttuale,
				 h.elem_det_comp_macro_tipo_desc as compMacroTipoDesc 
				 -- tb.importo into importoCurAttuale
				from (
				  select
					  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id, a.elem_det_comp_tipo_id
				  from
					  siac_r_movgest_bil_elem a,
					  siac_t_movgest b,
					  siac_t_movgest_ts c,
					  siac_r_movgest_ts_stato d,
					  siac_t_movgest_ts_det e,
					  siac_d_movgest_ts_det_tipo f
				  where
					  b.movgest_id=a.movgest_id 
					  and a.elem_id=elemIdGestEq 
					  and NOT( a.elem_det_comp_tipo_id = ANY(idcomp_in)) --SIAC-7349 --id componente diversa da quella ricevuta in input
					  and b.bil_id = bilIdElemGestEq
					  and b.movgest_tipo_id=movGestTipoId
					  and d.movgest_stato_id<>movGestStatoIdAnnullato
					  and d.movgest_stato_id<>movGestStatoIdProvvisorio
					  and b.movgest_anno > annoMovimento::integer -- per gli anni oltre N+2
					  and c.movgest_id=b.movgest_id
					  and d.movgest_ts_id=c.movgest_ts_id
					  and d.validita_fine is null
					  and e.movgest_ts_id=c.movgest_ts_id
					  and a.data_cancellazione is null
					  and b.data_cancellazione is null
					  and c.data_cancellazione is null
					  and e.data_cancellazione is null
					  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
					  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId
					  group by 	c.movgest_ts_tipo_id, 
								a.elem_det_comp_tipo_id -- SIAC-7349
						) tb, 
					siac_d_movgest_ts_tipo t,
					siac_d_bil_elem_det_comp_tipo g,
				 	siac_d_bil_elem_det_comp_macro_tipo h
				where 
					tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
					and g.elem_det_comp_tipo_id = tb.elem_det_comp_tipo_id --SIAC-7349 recupera anche la descrizione della componente
					and g.elem_det_comp_macro_tipo_id = h.elem_det_comp_macro_tipo_id --SIAC-7349 recupera anche la descrizione del macrotipo della componente
				 order by t.movgest_ts_tipo_code desc
 			) 
			loop
			

					-- 02.02.2016 Sofia JIRA 2947
					 if impComponenteRec.importoCurAttuale is null then impComponenteRec.importoCurAttuale:=0; end if;

					 -- 16.03.2017 Sofia JIRA-SIAC-4614
					-- if importoCurAttuale>0 then
					 if impComponenteRec.importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

						strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'  impComponenteRec.compId='||impComponenteRec.compId||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Calcolo totale modifiche su atti provvisori per annoMovimento='||annoMovimento||'.';

						select tb.importo into importoModifDelta
						 from
						 (
							select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
							from siac_r_movgest_bil_elem rbil, 
								 siac_t_movgest mov,
								 siac_t_movgest_ts ts,
								 siac_r_movgest_ts_stato rstato,
								 siac_t_movgest_ts_det tsdet,
								 siac_t_movgest_ts_det_mod moddet,
								 siac_t_modifica mod, 
								 siac_r_modifica_stato rmodstato,
								 siac_r_atto_amm_stato attostato, 
								 siac_t_atto_amm atto,
								 siac_d_modifica_tipo tipom
							where 
								rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
								and rbil.elem_det_comp_tipo_id=impComponenteRec.compId --SIAC-7349 deve essere sulla compoenente del record 
								and	  mov.movgest_id=rbil.movgest_id
								and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
								and   mov.movgest_anno>annoMovimento::integer -- anno dell impegno = annoMovimento 
								and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
								and   ts.movgest_id=mov.movgest_id
								and   rstato.movgest_ts_id=ts.movgest_ts_id
								and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
								and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
								and   tsdet.movgest_ts_id=ts.movgest_ts_id
								and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
								and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
								-- SIAC-7349 Prendo tutti gli importi, sia con segno negativo che con segno positivo
								-- La loro somma produce il valore importoModifDelta che devo sottrarre all'impegnato calcolato
								-- ad esempio: modifiche su atto provv +100, -322 -> somma -222 si tratta di un delta che devo sottrarre
								-- all'impegnato calcolato = impegnato calcolato - (-222) = +222 (aggiungo quello che avevo tolto)
								-- and   moddet.movgest_ts_det_importo<0 -- importo negativo
								and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
								and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
								and   mod.mod_id=rmodstato.mod_id
								and   atto.attoamm_id=mod.attoamm_id
								and   attostato.attoamm_id=atto.attoamm_id
								and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
								and   tipom.mod_tipo_id=mod.mod_tipo_id
								and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
								-- date
								and rbil.data_cancellazione is null
								and rbil.validita_fine is null
								and mov.data_cancellazione is null
								and mov.validita_fine is null
								and ts.data_cancellazione is null
								and ts.validita_fine is null
								and rstato.data_cancellazione is null
								and rstato.validita_fine is null
								and tsdet.data_cancellazione is null
								and tsdet.validita_fine is null
								and moddet.data_cancellazione is null
								and moddet.validita_fine is null
								and mod.data_cancellazione is null
								and mod.validita_fine is null
								and rmodstato.data_cancellazione is null
								and rmodstato.validita_fine is null
								and attostato.data_cancellazione is null
								and attostato.validita_fine is null
								and atto.data_cancellazione is null
								and atto.validita_fine is null
								group by ts.movgest_ts_tipo_id
							  ) tb, siac_d_movgest_ts_tipo tipo
							  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
							  order by tipo.movgest_ts_tipo_code desc
							  limit 1;		

						if importoModifDelta is null then importoModifDelta:=0; end if;
						  /*Aggiunta delle modifiche ECONB*/
						 -- anna_economie inizio
						select tb.importo into importoModifINS
						from
						(
							select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
							from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
							siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
							siac_t_movgest_ts_det_mod moddet,
							siac_t_modifica mod, siac_r_modifica_stato rmodstato,
							siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
							siac_d_modifica_tipo tipom
						where rbil.elem_id=elemIdGestEq
						and rbil.elem_det_comp_tipo_id=impComponenteRec.compId --SIAC-7349
						and	  mov.movgest_id=rbil.movgest_id
						and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
						and   mov.movgest_anno=annoMovimento::integer
						and   mov.bil_id=bilancioId
						and   ts.movgest_id=mov.movgest_id
						and   rstato.movgest_ts_id=ts.movgest_ts_id
						and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- impegno non annullato
						and   tsdet.movgest_ts_id=ts.movgest_ts_id
						and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
						and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
					   and   tipom.mod_tipo_id=mod.mod_tipo_id
					   and   tipom.mod_tipo_code = 'ECONB'
						-- date
						and rbil.data_cancellazione is null
						and rbil.validita_fine is null
						and mov.data_cancellazione is null
						and mov.validita_fine is null
						and ts.data_cancellazione is null
						and ts.validita_fine is null
						and rstato.data_cancellazione is null
						and rstato.validita_fine is null
						and tsdet.data_cancellazione is null
						and tsdet.validita_fine is null
						and moddet.data_cancellazione is null
						and moddet.validita_fine is null
						and mod.data_cancellazione is null
						and mod.validita_fine is null
						and rmodstato.data_cancellazione is null
						and rmodstato.validita_fine is null
						and attostato.data_cancellazione is null
						and attostato.validita_fine is null
						and atto.data_cancellazione is null
						and atto.validita_fine is null
					   group by ts.movgest_ts_tipo_id
					 ) tb, siac_d_movgest_ts_tipo tipo
					 where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
					 order by tipo.movgest_ts_tipo_code desc
					 limit 1;

					 if importoModifINS is null then 
						importoModifINS = 0;
					 end if;


					end if;		
	

			elemDetCompId:=impComponenteRec.compId;
			elemdetcompdesc:=impComponenteRec.compDesc;
			elemdetcompmacrotipodesc:=impComponenteRec.compMacroTipoDesc;
			impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente  
			impegnatoDefinitivo:=impegnatoDefinitivo+impComponenteRec.importoCurAttuale-(importoModifDelta);
			--aggiunta per ECONB
			impegnatoDefinitivo:=impegnatoDefinitivo+abs(importoModifINS);
			return next;	



	end loop;
	end if;
	end if;

	return;
 

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
		return;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
		return;
END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp_annisucc_nostanz(integer, INT[])
    OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp_annisucc_nostanz(integer, INT[]) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp_annisucc_nostanz(integer, INT[]) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp_annisucc_nostanz(integer, INT[]) TO siac;
--end fnc_siac_impegnatodefinitivoup_comp_annisucc_nostanz


--Start fnc_siac_impegnatodefinitivoup_comp
CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp(
	id_in integer,
	idcomp_in integer)
    RETURNS TABLE(indiceannualita integer, elemdetcompid integer, impegnatodefinitivo numeric) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
AS $BODY$
DECLARE

annoBilancio varchar:=null;
annoEsercizio varchar:=null;
annoMovimento varchar:=null;

elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;
NVL_STR     constant varchar:='';
faseOpCode varchar(20):=NVL_STR;
bilancioId integer:=0;
elemTipoCode VARCHAR(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;
enteProprietarioId INTEGER:=0;
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
FASE_OP_BIL_PREV constant VARCHAR:='P';
STATO_A     constant varchar:='A';
STATO_P     constant varchar:='P';
TIPO_IMP    constant varchar:='I';
movGestStatoIdAnnullato integer:=0;
movGestStatoIdProvvisorio integer:=0;
movGestTipoId integer:=0;
IMPORTO_ATT constant varchar:='A';
movGestTsDetTipoId integer:=0;
IMPORTO_INIZIALE constant varchar:='I';
movGestTsDetTipoIdIniziale integer:=0;
STATO_MOD_V  constant varchar:='V';
modStatoVId integer:=0;
attoAmmStatoPId integer:=0;
STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoCurAttuale numeric:=0;
esisteRmovgestidelemid INTEGER:=0;
importoModifDelta  numeric:=0;
importoModifINS numeric:=0; --aggiunta per ECONB
impegniDaRibaltamento integer:=0;
pluriennaliDaRibaltamento integer:=0;
flagNMaggioreNPiu2 integer:=0;
flagDeltaPagamenti integer:=0;
importoImpegnato numeric:=0;
importoPagatoDelta numeric:=0;
ordStatoAId          integer:=null;
ordTsDetTipoAId      integer:=null;
-- stati ordinativi
STATO_ORD_A    constant varchar:='A'; -- ANNULLATO
-- importoAttuale ordinativi
ORD_TS_DET_TIPO_A  constant varchar:='A';

strMessaggio varchar(1500):=null;
BEGIN


    strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in|| 'idcomp_in='||idcomp_in|| '.';

	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;
	if idcomp_in is null or idcomp_in=0 then
		 RAISE EXCEPTION '% Identificativo componente mancante.',strMessaggio;
	end if;
 
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
    			  '.Lettura anno di bilancio del capitolo UP.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;
		  

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
    			  '. Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId e elem_tipo_code.';
	 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
	 into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
	 from 	siac_t_bil_elem bilElem, 
	 		siac_d_bil_elem_tipo tipoBilElem,
		  	siac_t_bil bil, siac_t_periodo per
	 where bilElem.elem_id=id_in
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
	   and bil.bil_id=bilElem.bil_id
	   and per.periodo_id=bil.periodo_id;

	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UP then
			RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
	 end if;

	 strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				   '. Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   'Calcolo fase operativa per bilancioId='||bilancioId
				   ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select  faseOp.fase_operativa_code into  faseOpCode
	 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
	 where bilFase.bil_id =bilancioId
	   and bilfase.data_cancellazione is null
	   and bilFase.validita_fine is null
	   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
	   and faseOp.data_cancellazione is null
	 order by bilFase.bil_fase_operativa_id desc;

	 if NOT FOUND THEN
	   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
	 end if;

	 strMessaggio:='Calcolo impegnato definitivo elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO'
				  ||'. Calcolo movGestTsStatoIdProvvisorio per movgest_stato_code=PROVVISORIO';

	 select movGestStato.movgest_stato_id into strict movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;

	 select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_P; 
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo movGestTsDetTipoId per movgest_ts_det_tipo_code=IMPORTO ATTUALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE;
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
              ||'. Calcolo modStatoVId per mod_stato_code=VALIDO.';
	 select d.mod_stato_id into strict modStatoVId
	 from siac_d_modifica_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.mod_stato_code=STATO_MOD_V;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	 select d.attoamm_stato_id into strict attoAmmStatoPId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_P;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINITIVO';
	 select d.attoamm_stato_id into strict attoAmmStatoDId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_D;

 
--- CICLO SU TUTTE LE POSSIBILI ANNUALITA': N-1, N, N+1, N+2 e >N+2
FOR loop_counter IN  0..6  LOOP
CASE loop_counter

 WHEN 0 THEN


	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
    			  '.Determina anno esercizio ed anno movimento per i quali calcolare.';
    annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
    annoMovimento:=((annoBilancio::INTEGER)-1)::varchar;
	flagNMaggioreNPiu2:=0;
	
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    -- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo impegnato competenza UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else

		strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento|| 
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid 
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno=annoMovimento::integer
			and el.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
			;
		
		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;
		
		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

			importoCurAttuale:=0;			
			select tb.importo into importoCurAttuale
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
				  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno = annoMovimento::integer -- anno dell impegno = annoMovimento
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;		

			-- 02.02.2016 Sofia JIRA 2947
			 if importoCurAttuale is null then importoCurAttuale:=0; end if;

			 -- 16.03.2017 Sofia JIRA-SIAC-4614
			-- if importoCurAttuale>0 then
			 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

				strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Calcolo totale modifiche su atti provvisori per annoMovimento='||annoMovimento||'.';

				select tb.importo into importoModifDelta
				 from
				 (
					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, 
					 	 siac_t_movgest mov,
					 	 siac_t_movgest_ts ts,
						 siac_r_movgest_ts_stato rstato,
					  	 siac_t_movgest_ts_det tsdet,
						 siac_t_movgest_ts_det_mod moddet,
						 siac_t_modifica mod, 
					 	 siac_r_modifica_stato rmodstato,
						 siac_r_atto_amm_stato attostato, 
					 	 siac_t_atto_amm atto,
						 siac_d_modifica_tipo tipom
					where 
						rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
						and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
						and	  mov.movgest_id=rbil.movgest_id
						and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
						and   mov.movgest_anno=annoMovimento::integer -- anno dell impegno = annoMovimento
						and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
						and   ts.movgest_id=mov.movgest_id
						and   rstato.movgest_ts_id=ts.movgest_ts_id
						and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
						and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
					    and   tsdet.movgest_ts_id=ts.movgest_ts_id
						and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
						-- SIAC-7349 Prendo tutti gli importi, sia con segno negativo che con segno positivo
					 	-- La loro somma produce il valore importoModifDelta che devo sottrarre all'impegnato calcolato
					 	-- ad esempio: modifiche su atto provv +100, -322 -> somma -222 si tratta di un delta che devo sottrarre
					 	-- all'impegnato calcolato = impegnato calcolato - (-222) = +222 (aggiungo quello che avevo tolto)
					 	-- and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
						and   tipom.mod_tipo_id=mod.mod_tipo_id
						and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
						-- date
						and rbil.data_cancellazione is null
						and rbil.validita_fine is null
						and mov.data_cancellazione is null
						and mov.validita_fine is null
						and ts.data_cancellazione is null
						and ts.validita_fine is null
						and rstato.data_cancellazione is null
						and rstato.validita_fine is null
						and tsdet.data_cancellazione is null
						and tsdet.validita_fine is null
						and moddet.data_cancellazione is null
						and moddet.validita_fine is null
						and mod.data_cancellazione is null
						and mod.validita_fine is null
						and rmodstato.data_cancellazione is null
						and rmodstato.validita_fine is null
						and attostato.data_cancellazione is null
						and attostato.validita_fine is null
						and atto.data_cancellazione is null
						and atto.validita_fine is null
						group by ts.movgest_ts_tipo_id
					  ) tb, siac_d_movgest_ts_tipo tipo
					  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
					  order by tipo.movgest_ts_tipo_code desc
					  limit 1;		
					  
 				if importoModifDelta is null then importoModifDelta:=0; end if;
				 /*Aggiunta delle modifiche ECONB*/
				 -- anna_economie inizio
   				select tb.importo into importoModifINS
 				from
 				(
 					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
 			   	 	siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
				    siac_t_movgest_ts_det_mod moddet,
 			   	 	siac_t_modifica mod, siac_r_modifica_stato rmodstato,
				    siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
 			        siac_d_modifica_tipo tipom
				where rbil.elem_id=elemIdGestEq
				and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
				and	  mov.movgest_id=rbil.movgest_id
				and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
 			   	and   mov.movgest_anno=annoMovimento::integer
 			   	and   mov.bil_id=bilancioId
				and   ts.movgest_id=mov.movgest_id
				and   rstato.movgest_ts_id=ts.movgest_ts_id
				and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- impegno non annullato
				and   tsdet.movgest_ts_id=ts.movgest_ts_id
				and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
				and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
				and   moddet.movgest_ts_det_importo<0 -- importo negativo
				and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
				and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
				and   mod.mod_id=rmodstato.mod_id
				and   atto.attoamm_id=mod.attoamm_id
				and   attostato.attoamm_id=atto.attoamm_id
				and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
 			   and   tipom.mod_tipo_id=mod.mod_tipo_id
 			   and   tipom.mod_tipo_code = 'ECONB'
				-- date
				and rbil.data_cancellazione is null
				and rbil.validita_fine is null
				and mov.data_cancellazione is null
				and mov.validita_fine is null
				and ts.data_cancellazione is null
				and ts.validita_fine is null
				and rstato.data_cancellazione is null
				and rstato.validita_fine is null
				and tsdet.data_cancellazione is null
				and tsdet.validita_fine is null
				and moddet.data_cancellazione is null
				and moddet.validita_fine is null
				and mod.data_cancellazione is null
				and mod.validita_fine is null
				and rmodstato.data_cancellazione is null
				and rmodstato.validita_fine is null
				and attostato.data_cancellazione is null
				and attostato.validita_fine is null
				and atto.data_cancellazione is null
				and atto.validita_fine is null
 			   group by ts.movgest_ts_tipo_id
 			 ) tb, siac_d_movgest_ts_tipo tipo
 			 where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
 			 order by tipo.movgest_ts_tipo_code desc
 			 limit 1;
			 
			 if importoModifINS is null then 
			 	importoModifINS = 0;
			 end if;

		
			end if;		
		end if;
	end if;

	-- restituisco il record risultato
	indiceAnnualita:=loop_counter;
	elemDetCompId:=idcomp_in;
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente per l'anno N-1
	impegnatoDefinitivo:=impegnatoDefinitivo+importoCurAttuale-(importoModifDelta);

	--aggiunta per ECONB
	impegnatoDefinitivo:=impegnatoDefinitivo+abs(importoModifINS);

	return next;

	
	
 WHEN 1,2,3 THEN

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				 '.Verifica se presenti i movimenti di gestione provenienti dal ribaltamento per anno di esercizio N.';
	
	impegniDaRibaltamento:=0;
	pluriennaliDaRibaltamento:=0;
	importoCurAttuale:=0;	
	importoModifDelta:=0;
	importoModifINS:=0;
	
	select  count(*) into impegniDaRibaltamento 
	from fase_bil_t_gest_apertura_liq_imp fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;

	select  count(*) into  pluriennaliDaRibaltamento
	from fase_bil_t_gest_apertura_pluri fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;
				
	if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then

		--  Se presenti i movimenti gestione provenienti dal ribaltamento:
		--	ImpegnatoDefinitivo = 	Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in 
		--			e anno movimento [N | N+1 | N+2] e anno esercizio N

		annoEsercizio:=annoBilancio;
		annoMovimento:=((annoBilancio::INTEGER)+loop_counter-1)::varchar;
		flagNMaggioreNPiu2:=0;
	else

		--  Se non presenti i movimenti gestione provenienti dal ribaltamento
		--	ImpegnatoDefinitivo = Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in 
		-- 			e anno movimento [N | N+1 | N+2] e anno esercizio N-1  

		annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
		annoMovimento:=((annoBilancio::INTEGER)+loop_counter-1)::varchar;
		flagNMaggioreNPiu2:=0;
	end if;
	
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    -- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo impegnato competenza UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else

		strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento|| 
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid 
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno=annoMovimento::integer
			and el.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
			;
		
		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;
		
		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

					
			select tb.importo into importoCurAttuale
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
				  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno = annoMovimento::integer -- anno dell impegno = annoMovimento
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;		

			-- 02.02.2016 Sofia JIRA 2947
			 if importoCurAttuale is null then importoCurAttuale:=0; end if;

			 -- 16.03.2017 Sofia JIRA-SIAC-4614
			-- if importoCurAttuale>0 then
			 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

				strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Calcolo totale modifiche su atti provvisori per annoMovimento='||annoMovimento||'.';

				select tb.importo into importoModifDelta
				 from
				 (
					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, 
					 	 siac_t_movgest mov,
					 	 siac_t_movgest_ts ts,
						 siac_r_movgest_ts_stato rstato,
					  	 siac_t_movgest_ts_det tsdet,
						 siac_t_movgest_ts_det_mod moddet,
						 siac_t_modifica mod, 
					 	 siac_r_modifica_stato rmodstato,
						 siac_r_atto_amm_stato attostato, 
					 	 siac_t_atto_amm atto,
						 siac_d_modifica_tipo tipom
					where 
						rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
						and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
						and	  mov.movgest_id=rbil.movgest_id
						and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
						and   mov.movgest_anno=annoMovimento::integer -- anno dell impegno = annoMovimento
						and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
						and   ts.movgest_id=mov.movgest_id
						and   rstato.movgest_ts_id=ts.movgest_ts_id
						and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
						and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
					    and   tsdet.movgest_ts_id=ts.movgest_ts_id
						and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
						-- SIAC-7349 Prendo tutti gli importi, sia con segno negativo che con segno positivo
					 	-- La loro somma produce il valore importoModifDelta che devo sottrarre all'impegnato calcolato
					 	-- ad esempio: modifiche su atto provv +100, -322 -> somma -222 si tratta di un delta che devo sottrarre
					 	-- all'impegnato calcolato = impegnato calcolato - (-222) = +222 (aggiungo quello che avevo tolto)
					 	-- and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
						and   tipom.mod_tipo_id=mod.mod_tipo_id
						and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
						-- date
						and rbil.data_cancellazione is null
						and rbil.validita_fine is null
						and mov.data_cancellazione is null
						and mov.validita_fine is null
						and ts.data_cancellazione is null
						and ts.validita_fine is null
						and rstato.data_cancellazione is null
						and rstato.validita_fine is null
						and tsdet.data_cancellazione is null
						and tsdet.validita_fine is null
						and moddet.data_cancellazione is null
						and moddet.validita_fine is null
						and mod.data_cancellazione is null
						and mod.validita_fine is null
						and rmodstato.data_cancellazione is null
						and rmodstato.validita_fine is null
						and attostato.data_cancellazione is null
						and attostato.validita_fine is null
						and atto.data_cancellazione is null
						and atto.validita_fine is null
						group by ts.movgest_ts_tipo_id
					  ) tb, siac_d_movgest_ts_tipo tipo
					  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
					  order by tipo.movgest_ts_tipo_code desc
					  limit 1;		
					  
 				if importoModifDelta is null then importoModifDelta:=0; end if;
				  /*Aggiunta delle modifiche ECONB*/
				 -- anna_economie inizio
   				select tb.importo into importoModifINS
 				from
 				(
 					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
 			   	 	siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
				    siac_t_movgest_ts_det_mod moddet,
 			   	 	siac_t_modifica mod, siac_r_modifica_stato rmodstato,
				    siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
 			        siac_d_modifica_tipo tipom
				where rbil.elem_id=elemIdGestEq
				and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
				and	  mov.movgest_id=rbil.movgest_id
				and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
 			   	and   mov.movgest_anno=annoMovimento::integer
 			   	and   mov.bil_id=bilancioId
				and   ts.movgest_id=mov.movgest_id
				and   rstato.movgest_ts_id=ts.movgest_ts_id
				and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- impegno non annullato
				and   tsdet.movgest_ts_id=ts.movgest_ts_id
				and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
				and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
				and   moddet.movgest_ts_det_importo<0 -- importo negativo
				and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
				and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
				and   mod.mod_id=rmodstato.mod_id
				and   atto.attoamm_id=mod.attoamm_id
				and   attostato.attoamm_id=atto.attoamm_id
				and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
 			   and   tipom.mod_tipo_id=mod.mod_tipo_id
 			   and   tipom.mod_tipo_code = 'ECONB'
				-- date
				and rbil.data_cancellazione is null
				and rbil.validita_fine is null
				and mov.data_cancellazione is null
				and mov.validita_fine is null
				and ts.data_cancellazione is null
				and ts.validita_fine is null
				and rstato.data_cancellazione is null
				and rstato.validita_fine is null
				and tsdet.data_cancellazione is null
				and tsdet.validita_fine is null
				and moddet.data_cancellazione is null
				and moddet.validita_fine is null
				and mod.data_cancellazione is null
				and mod.validita_fine is null
				and rmodstato.data_cancellazione is null
				and rmodstato.validita_fine is null
				and attostato.data_cancellazione is null
				and attostato.validita_fine is null
				and atto.data_cancellazione is null
				and atto.validita_fine is null
 			   group by ts.movgest_ts_tipo_id
 			 ) tb, siac_d_movgest_ts_tipo tipo
 			 where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
 			 order by tipo.movgest_ts_tipo_code desc
 			 limit 1;
			 
			 if importoModifINS is null then 
			 	importoModifINS = 0;
			 end if;

		
			end if;		
		end if;
	end if;

	indiceAnnualita:=loop_counter;
	elemDetCompId:=idcomp_in;
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente per l'anno N-1
	impegnatoDefinitivo:=impegnatoDefinitivo+importoCurAttuale-(importoModifDelta);
	
	impegnatoDefinitivo:=impegnatoDefinitivo+abs(importoModifINS);
	
	return next;

 	
 WHEN 4 THEN
 	
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				 '.Verifica se presenti i movimenti di gestione provenienti dal ribaltamento per anno di esercizio N.';
	
	impegniDaRibaltamento:=0;
	pluriennaliDaRibaltamento:=0;
	importoCurAttuale:=0;	
	importoModifDelta:=0;
	importoModifINS := 0;
	
	select  count(*) into impegniDaRibaltamento 
	from fase_bil_t_gest_apertura_liq_imp fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;

	select  count(*) into  pluriennaliDaRibaltamento
	from fase_bil_t_gest_apertura_pluri fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;
				
	if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then

	--  Se presenti i movimenti gestione provenienti dal ribaltamento 
	--		ImpegnatoDefinitivo = Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in 
	--		e anno movimento > N+2 e anno esercizio N

		annoEsercizio:=annoBilancio;
		annoMovimento:=((annoBilancio::INTEGER)+2)::varchar;
		flagNMaggioreNPiu2:=1;
	else

		--  Se non presenti i movimenti gestione provenienti dal ribaltamento 
		-- 	ImpegnatoDefinitivo = Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in 
		-- 	e anno movimento > N+2 e anno esercizio N-1

		annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
		annoMovimento:=((annoBilancio::INTEGER)+2)::varchar;
		flagNMaggioreNPiu2:=1;
	end if;

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    -- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo impegnato competenza UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else

		strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento|| 
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid 
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno>annoMovimento::integer 
			and el.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
			;
		
		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;
		
		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

			importoCurAttuale:=0;			
			select tb.importo into importoCurAttuale
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
				  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno > annoMovimento::integer -- anno dell impegno > annoMovimento 
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;		

			-- 02.02.2016 Sofia JIRA 2947
			 if importoCurAttuale is null then importoCurAttuale:=0; end if;

			 -- 16.03.2017 Sofia JIRA-SIAC-4614
			-- if importoCurAttuale>0 then
			 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

				strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Calcolo totale modifiche su atti provvisori per annoMovimento='||annoMovimento||'.';

				select tb.importo into importoModifDelta
				 from
				 (
					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, 
					 	 siac_t_movgest mov,
					 	 siac_t_movgest_ts ts,
						 siac_r_movgest_ts_stato rstato,
					  	 siac_t_movgest_ts_det tsdet,
						 siac_t_movgest_ts_det_mod moddet,
						 siac_t_modifica mod, 
					 	 siac_r_modifica_stato rmodstato,
						 siac_r_atto_amm_stato attostato, 
					 	 siac_t_atto_amm atto,
						 siac_d_modifica_tipo tipom
					where 
						rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
						and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
						and	  mov.movgest_id=rbil.movgest_id
						and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
						and   mov.movgest_anno>annoMovimento::integer -- anno dell impegno = annoMovimento 
						and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
						and   ts.movgest_id=mov.movgest_id
						and   rstato.movgest_ts_id=ts.movgest_ts_id
						and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
						and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
					    and   tsdet.movgest_ts_id=ts.movgest_ts_id
						and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
						-- SIAC-7349 Prendo tutti gli importi, sia con segno negativo che con segno positivo
					 	-- La loro somma produce il valore importoModifDelta che devo sottrarre all'impegnato calcolato
					 	-- ad esempio: modifiche su atto provv +100, -322 -> somma -222 si tratta di un delta che devo sottrarre
					 	-- all'impegnato calcolato = impegnato calcolato - (-222) = +222 (aggiungo quello che avevo tolto)
					 	-- and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
						and   tipom.mod_tipo_id=mod.mod_tipo_id
						and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
						-- date
						and rbil.data_cancellazione is null
						and rbil.validita_fine is null
						and mov.data_cancellazione is null
						and mov.validita_fine is null
						and ts.data_cancellazione is null
						and ts.validita_fine is null
						and rstato.data_cancellazione is null
						and rstato.validita_fine is null
						and tsdet.data_cancellazione is null
						and tsdet.validita_fine is null
						and moddet.data_cancellazione is null
						and moddet.validita_fine is null
						and mod.data_cancellazione is null
						and mod.validita_fine is null
						and rmodstato.data_cancellazione is null
						and rmodstato.validita_fine is null
						and attostato.data_cancellazione is null
						and attostato.validita_fine is null
						and atto.data_cancellazione is null
						and atto.validita_fine is null
						group by ts.movgest_ts_tipo_id
					  ) tb, siac_d_movgest_ts_tipo tipo
					  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
					  order by tipo.movgest_ts_tipo_code desc
					  limit 1;		
					  
 				if importoModifDelta is null then importoModifDelta:=0; end if;
				  /*Aggiunta delle modifiche ECONB*/
				 -- anna_economie inizio
   				select tb.importo into importoModifINS
 				from
 				(
 					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
 			   	 	siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
				    siac_t_movgest_ts_det_mod moddet,
 			   	 	siac_t_modifica mod, siac_r_modifica_stato rmodstato,
				    siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
 			        siac_d_modifica_tipo tipom
				where rbil.elem_id=elemIdGestEq
				and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
				and	  mov.movgest_id=rbil.movgest_id
				and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
 			   	and   mov.movgest_anno=annoMovimento::integer
 			   	and   mov.bil_id=bilancioId
				and   ts.movgest_id=mov.movgest_id
				and   rstato.movgest_ts_id=ts.movgest_ts_id
				and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- impegno non annullato
				and   tsdet.movgest_ts_id=ts.movgest_ts_id
				and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
				and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
				and   moddet.movgest_ts_det_importo<0 -- importo negativo
				and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
				and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
				and   mod.mod_id=rmodstato.mod_id
				and   atto.attoamm_id=mod.attoamm_id
				and   attostato.attoamm_id=atto.attoamm_id
				and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
 			   and   tipom.mod_tipo_id=mod.mod_tipo_id
 			   and   tipom.mod_tipo_code = 'ECONB'
				-- date
				and rbil.data_cancellazione is null
				and rbil.validita_fine is null
				and mov.data_cancellazione is null
				and mov.validita_fine is null
				and ts.data_cancellazione is null
				and ts.validita_fine is null
				and rstato.data_cancellazione is null
				and rstato.validita_fine is null
				and tsdet.data_cancellazione is null
				and tsdet.validita_fine is null
				and moddet.data_cancellazione is null
				and moddet.validita_fine is null
				and mod.data_cancellazione is null
				and mod.validita_fine is null
				and rmodstato.data_cancellazione is null
				and rmodstato.validita_fine is null
				and attostato.data_cancellazione is null
				and attostato.validita_fine is null
				and atto.data_cancellazione is null
				and atto.validita_fine is null
 			   group by ts.movgest_ts_tipo_id
 			 ) tb, siac_d_movgest_ts_tipo tipo
 			 where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
 			 order by tipo.movgest_ts_tipo_code desc
 			 limit 1;
			 
			 if importoModifINS is null then 
			 	importoModifINS = 0;
			 end if;

		
			end if;		
		end if;
	end if;

	indiceAnnualita:=loop_counter;
	elemDetCompId:=idcomp_in;
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente per l'anno N-1
	impegnatoDefinitivo:=impegnatoDefinitivo+importoCurAttuale-(importoModifDelta);
	--aggiunta per ECONB
	impegnatoDefinitivo:=impegnatoDefinitivo+abs(importoModifINS);
	return next;

 WHEN 5 THEN
	-- Calcolo Residuo Iniziale: 
	--  Se presenti i movimenti gestione provenienti dal ribaltamento 
	--	 	Sommatoria dell'importo iniziale di tutti gli Impegni assunti sul capitolo in questione su idcomp_in
	--		con anno movimento < N e anno esercizio N.
	--  Se non presenti i movimenti gestione provenienti dal ribaltamento 
	-- 		Sommatoria di tutti gli Impegni (valore effettivo aka finale) assunti sul capitolo in questione su incomp_in
	--		con anno movimento < N e anno esercizio N-1 diminuiti dalla sommatoria del pagato sui medesimi impegni nell'esercizio N-1.

	impegniDaRibaltamento:=0;
	pluriennaliDaRibaltamento:=0;
	importoImpegnato:=0;	
	importoPagatoDelta:=0;
	
	select  count(*) into impegniDaRibaltamento 
	from fase_bil_t_gest_apertura_liq_imp fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;

	select  count(*) into  pluriennaliDaRibaltamento
	from fase_bil_t_gest_apertura_pluri fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;
				
	if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then

		--  Se presenti i movimenti gestione provenienti dal ribaltamento 
		--		Residuo Iniziale = 
		--	 		Sommatoria dell'importo iniziale di tutti gli Impegni assunti sul capitolo in questione su idcomp_in
		--			con anno movimento < N e anno esercizio N.

		annoEsercizio:=annoBilancio;
		annoMovimento:=annoBilancio;
 		flagDeltaPagamenti:=0; -- non e' necessario scomputare il pagato
		
 	else

		--  Se non presenti i movimenti gestione provenienti dal ribaltamento 
		-- 		Residuo Iniziale =	
		--			Sommatoria di tutti gli Impegni (valore effettivo aka finale) assunti sul capitolo in questione su incomp_in
		--			con anno movimento < N e anno esercizio N-1  
		--			diminuiti dalla sommatoria del pagato sui medesimi impegni nell'esercizio N-1.

		annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
		annoMovimento:=annoBilancio;
		flagDeltaPagamenti:=1; -- bisogna sottrarre la sommatoria del pagato sui medesimi impegni nell'esercizio N-1

	end if;

	strMessaggio:='Calcolo residuo iniziale elem_id='||id_in||'idcomp_in='||idcomp_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    -- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo residuo iniziale.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else

		strMessaggio:='Calcolo residuo iniziale elem_id='||id_in||'idcomp_in='||idcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento||'.'; 

		impegnatoDefinitivo:=0;
		strMessaggio:='Calcolo residuo iniziale elem_id='||id_in||'idcomp_in='||idcomp_in||
			'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
			'. Inizio calcolo totale importo  impegni per annoMovimento='||annoMovimento||'.';

		if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then
			--  Sommatoria dell'importo iniziale di tutti gli Impegni assunti sul capitolo in questione 
			--	su Componente X con anno movimento < N e anno esercizio N

		importoImpegnato:=0;			
		select tb.importo into importoImpegnato
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
				  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno < annoMovimento::integer -- anno dell impegno < annoMovimento 
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoIdIniziale -- considerare l'importo iniziale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;		
			-- 02.02.2016 Sofia JIRA 2947
			if importoImpegnato is null then importoImpegnato:=0; end if;

		else
			-- Sommatoria di tutti gli Impegni assunti (valore effettivo aka finale) sul capitolo in questione su Componente X 
			-- con anno movimento < N e anno esercizio N-1
			-- diminuiti dalla sommatoria del pagato sui medesimi impegni nell'esercizio N-1.
			importoImpegnato:=0;			
			select tb.importo into importoImpegnato
				from (
				  select
					  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
				  from
					  siac_r_movgest_bil_elem a,
					  siac_t_movgest b,
					  siac_t_movgest_ts c,
					  siac_r_movgest_ts_stato d,
					  siac_t_movgest_ts_det e,
					  siac_d_movgest_ts_det_tipo f
				  where
					  b.movgest_id=a.movgest_id and
					  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
					  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
					  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
					  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
					  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
					  and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
					  and b.movgest_anno < annoMovimento::integer -- anno dell impegno < annoMovimento 
					  and c.movgest_id=b.movgest_id
					  and d.movgest_ts_id=c.movgest_ts_id
					  and d.validita_fine is null
					  and e.movgest_ts_id=c.movgest_ts_id
					  and a.data_cancellazione is null
					  and b.data_cancellazione is null
					  and c.data_cancellazione is null
					  and e.data_cancellazione is null
					  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
					  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
					  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
				where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
				order by t.movgest_ts_tipo_code desc
				limit 1;	

			-- 16.03.2017 Sofia JIRA-SIAC-4614
			-- if importoImpegnato>0 then
			if importoImpegnato>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

				strMessaggio:='Calcolo residuo iniziale elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Calcolo sommatoria del pagato sui medesimi impegni nell''esercizio N-1.';

			   strMessaggio:='Lettura identificativo ord_stato_code='||STATO_ORD_A||'.';
			   select ordstato.ord_stato_id into ordStatoAId
			   from siac_d_ordinativo_stato ordstato
			   where ordstato.ente_proprietario_id=enteProprietarioId
			   and   ordstato.ord_stato_code=STATO_ORD_A;

			   select tipo.ord_ts_det_tipo_id into ordTsDetTipoAId
			   from siac_d_ordinativo_ts_det_tipo tipo
			   where tipo.ente_proprietario_id=enteProprietarioId
			   and   tipo.ord_ts_det_tipo_code=ORD_TS_DET_TIPO_A;

				select coalesce(sum(e.ord_ts_det_importo),0) into importoPagatoDelta
				from  
					 siac_r_movgest_bil_elem a,  --rmov,
					 siac_t_movgest b, -- mov, 
					 siac_t_movgest_ts c, --ts,
					 siac_r_liquidazione_movgest rliq,
					 siac_r_liquidazione_ord rord, 
					 siac_t_ordinativo_ts ordts, 
					 siac_t_ordinativo ord,
					 siac_r_ordinativo_stato rordstato,
					 siac_t_ordinativo_ts_det e, --tsdet,
					 siac_r_movgest_ts_stato d
				where
					b.movgest_id=a.movgest_id and
					a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
					a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
					and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
					and ord.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
					and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
					and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
					and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
					and b.movgest_anno < annoMovimento::integer -- anno dell impegno < annoMovimento 
					and c.movgest_id=b.movgest_id
					and d.movgest_ts_id=c.movgest_ts_id	
					and   rliq.movgest_ts_id=c.movgest_ts_id
					and   rord.liq_id=rliq.liq_id
					and   ordts.ord_ts_id=rord.sord_id
					and   ord.ord_id=ordts.ord_id
					and   rordstato.ord_id=ord.ord_id
					and   rordstato.ord_stato_id!=ordStatoAId -- non deve essere Annullato
					and   e.ord_ts_id=ordts.ord_ts_id
					and   e.ord_ts_det_tipo_id=ordTsDetTipoAId -- importo attuale
					and   e.data_cancellazione is null
					and   e.validita_fine is null
					and   b.data_cancellazione is null
					and   b.validita_fine is null
					and   c.data_cancellazione is null
					and   c.validita_fine is null
					and   a.data_cancellazione is null
					and   a.validita_fine is null
					and   rord.data_cancellazione is null
					and   rord.validita_fine is null
					and   rliq.data_cancellazione is null
					and   rliq.validita_fine is null
					and   ordts.data_cancellazione is null
					and   ordts.validita_fine is null
					and   ord.data_cancellazione is null
					and   ord.validita_fine is null
					and   rordstato.data_cancellazione is null
					and   rordstato.validita_fine is null
					and   d.data_cancellazione is null
					and   d.validita_fine is null;

				if importoPagatoDelta is null then importoPagatoDelta:=0; end if;

			end if;		
		end if;
	end if;

	indiceAnnualita:=loop_counter;
	elemDetCompId:=idcomp_in;
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente per l'anno N-1
	if flagDeltaPagamenti != 0 then
		impegnatoDefinitivo:=impegnatoDefinitivo+importoImpegnato-(importoPagatoDelta);
	else 
		impegnatoDefinitivo:=impegnatoDefinitivo+importoImpegnato;
	end if;
	return next;

	

 WHEN 6 THEN
	-- Calcolo Residuo Finale (In presenza della colonna finale e in assenza di qualsiasi colonna):
	--  Se presenti i movimenti gestione provenienti dal ribaltamento 
	--		Sommatoria dell'importo attuale di tutti gli Impegni assunti sul capitolo in questione su idcomp_in 
	--		con anno movimento < N e anno esercizio N.
	--  Se non presenti i movimenti gestione provenienti dal ribaltamento 
	-- 		Sommatoria di tutti gli Impegni (valore effettivo aka finale aka attuale) assunti sul capitolo in questione su incomp_in 
	--		con anno movimento < N e anno esercizio N-1 diminuiti dalla sommatoria del pagato sui medesimi impegni nell'esercizio N-1.

	impegniDaRibaltamento:=0;
	pluriennaliDaRibaltamento:=0;
	importoImpegnato:=0;	
	importoPagatoDelta:=0;
	
	select  count(*) into impegniDaRibaltamento 
	from fase_bil_t_gest_apertura_liq_imp fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;

	select  count(*) into  pluriennaliDaRibaltamento
	from fase_bil_t_gest_apertura_pluri fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;
				
	if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then

		--  Se presenti i movimenti gestione provenienti dal ribaltamento 
		--		Residuo Finale = 
		--	 		Sommatoria dell'importo attuale di tutti gli Impegni assunti sul capitolo in questione su idcomp_in
		--			con anno movimento < N e anno esercizio N.

		annoEsercizio:=annoBilancio;
		annoMovimento:=annoBilancio;
 		flagDeltaPagamenti:=0; -- non e' necessario scomputare il pagato
		
 	else

		--  Se non presenti i movimenti gestione provenienti dal ribaltamento 
		-- 		Residuo Finale =	
		--			Sommatoria di tutti gli Impegni (valore effettivo aka finale) assunti sul capitolo in questione su incomp_in
		--			con anno movimento < N e anno esercizio N-1  
		--			diminuiti dalla sommatoria del pagato sui medesimi impegni nell'esercizio N-1.

		annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
		annoMovimento:=annoBilancio;
		flagDeltaPagamenti:=1; -- bisogna sottrarre la sommatoria del pagato sui medesimi impegni nell'esercizio N-1

	end if;

	strMessaggio:='Calcolo residuo finale elem_id='||id_in||'idcomp_in='||idcomp_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    -- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo residuo finale.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else

		strMessaggio:='Calcolo residuo finale elem_id='||id_in||'idcomp_in='||idcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento||'.'; 

		impegnatoDefinitivo:=0;
		strMessaggio:='Calcolo residuo finale elem_id='||id_in||'idcomp_in='||idcomp_in||
			'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
			'. Inizio calcolo totale importo  impegni per annoMovimento='||annoMovimento||'.';

		if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then
			--  Sommatoria dell'importo attuale di tutti gli Impegni assunti sul capitolo in questione 
			--	su Componente X con anno movimento < N e anno esercizio N

		importoImpegnato:=0;			
		select tb.importo into importoImpegnato
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
				  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno < annoMovimento::integer -- anno dell impegno < annoMovimento 
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;		
			-- 02.02.2016 Sofia JIRA 2947
			if importoImpegnato is null then importoImpegnato:=0; end if;

		else
			-- Sommatoria di tutti gli Impegni assunti (valore effettivo aka finale) sul capitolo in questione su Componente X 
			-- con anno movimento < N e anno esercizio N-1
			-- diminuiti dalla sommatoria del pagato sui medesimi impegni nell'esercizio N-1.
			importoImpegnato:=0;			
			select tb.importo into importoImpegnato
				from (
				  select
					  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
				  from
					  siac_r_movgest_bil_elem a,
					  siac_t_movgest b,
					  siac_t_movgest_ts c,
					  siac_r_movgest_ts_stato d,
					  siac_t_movgest_ts_det e,
					  siac_d_movgest_ts_det_tipo f
				  where
					  b.movgest_id=a.movgest_id and
					  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
					  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
					  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
					  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
					  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
					  and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
					  and b.movgest_anno < annoMovimento::integer -- anno dell impegno < annoMovimento 
					  and c.movgest_id=b.movgest_id
					  and d.movgest_ts_id=c.movgest_ts_id
					  and d.validita_fine is null
					  and e.movgest_ts_id=c.movgest_ts_id
					  and a.data_cancellazione is null
					  and b.data_cancellazione is null
					  and c.data_cancellazione is null
					  and e.data_cancellazione is null
					  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
					  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
					  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
				where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
				order by t.movgest_ts_tipo_code desc
				limit 1;	

			-- 16.03.2017 Sofia JIRA-SIAC-4614
			-- if importoImpegnato>0 then
			if importoImpegnato>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

				strMessaggio:='Calcolo residuo finale elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Calcolo sommatoria del pagato sui medesimi impegni nell''esercizio N-1.';

			   strMessaggio:='Lettura identificativo ord_stato_code='||STATO_ORD_A||'.';
			   select ordstato.ord_stato_id into ordStatoAId
			   from siac_d_ordinativo_stato ordstato
			   where ordstato.ente_proprietario_id=enteProprietarioId
			   and   ordstato.ord_stato_code=STATO_ORD_A;

			   select tipo.ord_ts_det_tipo_id into ordTsDetTipoAId
			   from siac_d_ordinativo_ts_det_tipo tipo
			   where tipo.ente_proprietario_id=enteProprietarioId
			   and   tipo.ord_ts_det_tipo_code=ORD_TS_DET_TIPO_A;

				select coalesce(sum(e.ord_ts_det_importo),0) into importoPagatoDelta
				from  
					 siac_r_movgest_bil_elem a,  --rmov,
					 siac_t_movgest b, -- mov, 
					 siac_t_movgest_ts c, --ts,
					 siac_r_liquidazione_movgest rliq,
					 siac_r_liquidazione_ord rord, 
					 siac_t_ordinativo_ts ordts, 
					 siac_t_ordinativo ord,
					 siac_r_ordinativo_stato rordstato,
					 siac_t_ordinativo_ts_det e, --tsdet,
					 siac_r_movgest_ts_stato d
				where
					b.movgest_id=a.movgest_id and
					a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
					a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
					and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
					and ord.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
					and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
					and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
					and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
					and b.movgest_anno < annoMovimento::integer -- anno dell impegno < annoMovimento 
					and c.movgest_id=b.movgest_id
					and d.movgest_ts_id=c.movgest_ts_id	
					and   rliq.movgest_ts_id=c.movgest_ts_id
					and   rord.liq_id=rliq.liq_id
					and   ordts.ord_ts_id=rord.sord_id
					and   ord.ord_id=ordts.ord_id
					and   rordstato.ord_id=ord.ord_id
					and   rordstato.ord_stato_id!=ordStatoAId -- non deve essere Annullato
					and   e.ord_ts_id=ordts.ord_ts_id
					and   e.ord_ts_det_tipo_id=ordTsDetTipoAId -- importo attuale
					and   e.data_cancellazione is null
					and   e.validita_fine is null
					and   b.data_cancellazione is null
					and   b.validita_fine is null
					and   c.data_cancellazione is null
					and   c.validita_fine is null
					and   a.data_cancellazione is null
					and   a.validita_fine is null
					and   rord.data_cancellazione is null
					and   rord.validita_fine is null
					and   rliq.data_cancellazione is null
					and   rliq.validita_fine is null
					and   ordts.data_cancellazione is null
					and   ordts.validita_fine is null
					and   ord.data_cancellazione is null
					and   ord.validita_fine is null
					and   rordstato.data_cancellazione is null
					and   rordstato.validita_fine is null
					and   d.data_cancellazione is null
					and   d.validita_fine is null;

				if importoPagatoDelta is null then importoPagatoDelta:=0; end if;

			end if;		
		end if;
	end if;

	indiceAnnualita:=loop_counter;
	elemDetCompId:=idcomp_in;
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente per l'anno N-1
	if flagDeltaPagamenti != 0 then
		impegnatoDefinitivo:=impegnatoDefinitivo+importoImpegnato-(importoPagatoDelta);
	else 
		impegnatoDefinitivo:=impegnatoDefinitivo+importoImpegnato;
	end if;
	return next;

END CASE;
END LOOP;

return;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
		return;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
		return;
END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp(integer, integer)
    OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp(integer, integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp(integer, integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp(integer, integer) TO siac;
--end fnc_siac_impegnatodefinitivoup_comp


--Start fnc_siac_stanz_effettivo_ug_anno_comp
CREATE OR REPLACE FUNCTION siac.fnc_siac_stanz_effettivo_ug_anno_comp (
  id_in integer,
  anno_comp_in character varying,
  idcomp_in integer
)
RETURNS TABLE (
  elemid integer,
  annocompetenza character varying,
  stanzeffettivo numeric,
  stanzeffettivocassa numeric,
  massimoimpegnabile numeric
)
LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
AS $BODY$
DECLARE

-- constant
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';
STA_IMP_SCA     constant varchar:='SCA';
STA_IMP_MI     constant varchar:='MI'; -- tipo importo massimo impegnabile

-- fasi di bilancio
FASE_BIL_PREV  constant varchar:='P'; -- previsione
FASE_BIL_PROV  constant varchar:='E'; -- esercizio provvisorio
FASE_BIL_GEST  constant varchar:='G'; -- esercizio gestione
FASE_BIL_CONS  constant varchar:='O'; -- esercizio consuntivo
FASE_BIL_CHIU  constant varchar:='C'; -- esercizio chiuso

-- stati variazioni di importo
STATO_VAR_G    constant varchar:='G'; -- GIUNTA
STATO_VAR_C    constant varchar:='C'; -- CONSIGLIO
STATO_VAR_B    constant varchar:='B'; -- BOZZA
STATO_VAR_D    constant varchar:='D'; -- DEFINITIVA
STATO_VAR_P    constant varchar:='P'; -- PRE-DEFINITIVA -- 31.03.2016 Sofia JIRA-SIAC-3304

bilancioId integer:=0;
bilElemId  integer:=0;
bilElemPrevId  integer:=0;
strMessaggio varchar(1500):=NVL_STR;
bilFaseOperativa varchar(10):=NVL_STR;
annoBilancio varchar(10):=NVL_STR;

stanziamentoPrev numeric:=0;
stanziamentoPrevCassa numeric:=0;

stanziamento numeric:=0;
stanziamentoEff numeric:=0;
deltaMenoPrev numeric:=0;
varImpGestione numeric:=0;
deltaMenoGest numeric:=0;
deltaMenoPrevCassa numeric:=0;
varImpGestioneCassa numeric:=0;
deltaMenoGestCassa numeric:=0;
stanziamentoEffCassa numeric:=0;
stanziamentoCassa numeric:=0;
stanzMassimoImpegnabile numeric:=null;

periodoId integer:=0;
periodoCompId integer:=0;
enteProprietarioId integer:=0;
detCompCap integer:=0; --SIAC-7349 Numero dettagli componente per capitolo di previsione equivalente - fix per componente assente

BEGIN

 annoCompetenza:=null;
 stanzEffettivo:=null;
 stanzEffettivoCassa:=null;
 elemId:=null;
 massimoImpegnabile:=null;

 -- controllo parametri
 -- anno_comp_in obbligatorio
 -- id_in obbligatorio
 -- idcomp_in obbligatorio

 strMessaggio:='Calcolo stanziamento effettivo.Controllo parametri.';

 if anno_comp_in is null or anno_comp_in=NVL_STR then
    	RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
    	RAISE EXCEPTION '% Id_in  mancante.',strMessaggio;
 end if;

 if idcomp_in is null or idcomp_in=0 then
    	RAISE EXCEPTION '% Id_in  mancante.',strMessaggio;
 end if;

 strMessaggio:='Lettura identificativo bilancioId, annoBilancio e enteProprietarioId da elemento di bilancio elem_id='||id_in||'.';
 select bil.bil_id, per.anno, bilElem.ente_proprietario_id
               into strict bilancioId, annoBilancio, enteProprietarioId
 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem,
             siac_t_bil bil, siac_t_periodo per
 where bilElem.elem_id=id_in
        and   bilElem.data_cancellazione is null
        and   bilElem.validita_fine is null
        and   tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
        and   tipoBilElem.elem_tipo_code = TIPO_CAP_UG
        and   bil.bil_id=bilElem.bil_id
        and   per.periodo_id=bil.periodo_id;

  bilElemId:=id_in;

  if bilancioId is not null and bilancioId!=0 then
  strMessaggio:='Lettura identificativo annoBilancio enteProprietarioId periodoId elemento di bilancio elem_id='||id_in
              ||' per bilancioId='||bilancioId||'.';

  select per.anno,  bil.ente_proprietario_id, per.periodo_id
        into strict annoBilancio, enteProprietarioId, periodoId
  from siac_t_bil bil, siac_t_periodo per
  where bil.bil_id=bilancioId and
        per.periodo_id=bil.periodo_id;
 end if;

 if bilElemId is null or bilElemId=0 then
   strMessaggio:='Lettura identificativo elemento di bilancio '||ele_code_in||'/'||ele_code2_in||'/'||ele_code3_in||'.';
   if bilancioId is not null and bilancioId!=0 then
 	 strMessaggio:='Lettura identificativo elemento di bilancio '||ele_code_in||'/'||ele_code2_in||'/'||ele_code3_in
                    ||'  per bilancioId='||bilancioId||' .';
     select bilElem.elem_id into strict bilElemId
     from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem
     where bilElem.bil_id=bilancioId
     and   bilElem.elem_code=ele_code_in
     and   bilElem.elem_code2=ele_code2_in
     and   bilElem.elem_code3=ele_code3_in
     and   bilElem.data_cancellazione is null
     and   bilElem.validita_fine is null
     and   tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
     and   tipoBilElem.elem_tipo_code = TIPO_CAP_UG;
   else
	 strMessaggio:='Lettura identificativo elemento di bilancio '||ele_code_in||'/'||ele_code2_in||'/'||ele_code3_in
                    ||'  bilancioId periodoId per annoBilancioIn='||anno_in||' enteProprietarioIn'||ente_prop_in||' .';
     select bilElem.elem_id, bilelem.bil_id, per.periodo_id
            into strict bilElemId, bilancioId, periodoId
     from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem,
          siac_t_bil bil, siac_t_periodo per, siac_d_periodo_tipo tipoPer
     where per.anno=anno_in
     and   per.ente_proprietario_id=ente_prop_in
     and   tipoPer.periodo_tipo_id=per.periodo_tipo_id
     and   tipoPer.periodo_tipo_code='SY'
     and   bil.periodo_id=per.periodo_id
     and   bilElem.bil_id=bil.bil_id
     and   bilElem.elem_code=ele_code_in
     and   bilElem.elem_code2=ele_code2_in
     and   bilElem.elem_code3=ele_code3_in
     and   bilElem.data_cancellazione is null
     and   bilElem.validita_fine is null
     and   tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
     and   tipoBilElem.elem_tipo_code = TIPO_CAP_UG;

     annoBilancio:=anno_in;
     enteProprietarioId:=ente_prop_in;

   end if;

 end  if;

 strMessaggio:='Lettura fase di bilancio corrente per  anno bilancio='||annoBilancio||' bilancioId='||bilancioId
                ||' per elem_id='||bilElemId||' .';

 select faseop.fase_operativa_code into strict bilFaseOperativa
 from siac_d_fase_operativa faseOp, siac_r_bil_fase_operativa bilFaseOp
 where bilfaseop.bil_id=bilancioId and
       bilfaseop.data_cancellazione is null and
       bilfaseop.validita_fine is null  and
       faseOp.ente_proprietario_id=bilFaseOp.ente_proprietario_id and
       faseOp.fase_operativa_id = bilfaseop.fase_operativa_id and
       faseOp.data_cancellazione is null and
       faseOp.validita_fine is null;

 if bilFaseOperativa in ( FASE_BIL_PREV ) then
    	return next;
        return;
 elsif bilFaseOperativa not in ( FASE_BIL_PROV, FASE_BIL_GEST,FASE_BIL_CONS,FASE_BIL_CHIU) then
    	RAISE EXCEPTION '% Fase non ammessa per il calcolo richiesto.',strMessaggio;
 end if;

if anno_comp_in!=annoBilancio then
 	strMessaggio:='Lettura periodoCompId per anno_comp_in='||anno_comp_in||' elem_id='||bilElemId||'.';

 	select  per.periodo_id into strict periodoCompId
    from siac_t_periodo per, siac_d_periodo_tipo perTipo
    where per.anno=anno_comp_in
    and   per.ente_proprietario_id=enteProprietarioId
    and   perTipo.periodo_tipo_id=per.periodo_tipo_id
    and   perTipo.periodo_tipo_code='SY';
 else
     periodoCompId:=periodoId;
 end if;

 if bilFaseOperativa = FASE_BIL_PROV then
    -- [stanziamento previsione - 'delta-previsione' + variazioni def di gestione]
		
    	strMessaggio:='Lettura elemento di bilancio equivalente di previsione per elem_id='||bilElemId||'.';
	    select bilElemPrev.elem_id into  bilElemPrevId
    	from siac_t_bil_elem bilElemPrev, siac_d_bil_elem_tipo tipoPrev,
        	 siac_t_bil_elem bilElemGest
    	where bilElemGest.elem_id=bilElemId and
              bilElemPrev.elem_code=bilElemGest.elem_code and
              bilElemPrev.elem_code2=bilElemGest.elem_code2 and
              bilElemPrev.elem_code3=bilElemGest.elem_code3 and
              bilElemPrev.ente_proprietario_id=bilElemGest.ente_proprietario_id and
              bilElemPrev.bil_id=bilElemGest.bil_id and
              bilElemPrev.data_cancellazione is null and bilElemPrev.validita_fine is null and
              tipoPrev.elem_tipo_id=bilElemPrev.elem_tipo_id and
              tipoPrev.elem_tipo_code=TIPO_CAP_UP;

        if NOT FOUND then
         bilElemPrevId:=0;
        else
			--SIAC-7349 controllo se esiste la componente nel capitolo di previsione equivalente
			strMessaggio:='Lettura numero stanziamenti di previsione per elem_id='||bilElemPrevId||
																' anno_comp_in='||anno_comp_in||
																' idcomp_in='||idcomp_in|| '.';
			
			select count(comp.elem_det_id) into detCompCap
			 from siac_t_bil_elem_det importiPrev,
				  siac_d_bil_elem_det_tipo tipoImpPrev,
				  siac_t_bil_elem_det_comp comp,
				  siac_d_bil_elem_det_comp_tipo comptipo
			 where importiPrev.elem_id=bilElemPrevId AND
				   comp.elem_det_id = importiPrev.elem_det_id and
				   importiPrev.data_cancellazione is null and importiPrev.validita_fine is null and
				   tipoImpPrev.elem_det_tipo_id=importiPrev.elem_det_tipo_id and
				   tipoImpPrev.elem_det_tipo_code=STA_IMP and
				   comp.data_cancellazione is null and comp.validita_fine is null and
				   importiPrev.periodo_id=periodoCompId
				   and comptipo.data_cancellazione is null and comptipo.validita_fine is null  
				   and comp.elem_det_comp_tipo_id = comptipo.elem_det_comp_tipo_id
				   and comptipo.elem_det_comp_tipo_id = idcomp_in                                                 
					-- SIAC-7349 Aggiunto non exists per escludere le componenti che sono collegate come "nuovi dettagli" tramite variazione in stato diverso da definitivo
				   and not (exists ( 
					select siactbilel4_.elem_det_var_comp_id
					from 	siac_t_bil_elem_det_var_comp siactbilel4_
							cross join siac_t_bil_elem_det_var siactbilel5_
							cross join siac_r_variazione_stato siacrvaria6_
							cross join siac_d_variazione_stato siacdvaria7_
					where 	siactbilel4_.elem_det_var_id=siactbilel5_.elem_det_var_id
						and siactbilel5_.variazione_stato_id=siacrvaria6_.variazione_stato_id
						and siacrvaria6_.variazione_stato_tipo_id=siacdvaria7_.variazione_stato_tipo_id
						and siactbilel4_.elem_det_comp_id=comp.elem_det_comp_id
						and siactbilel4_.elem_det_flag='N'
						and siacdvaria7_.variazione_stato_tipo_code<>'D'
						and siactbilel4_.data_cancellazione is null
						and siactbilel5_.data_cancellazione is null
						and siacrvaria6_.data_cancellazione is null
					));
					
				   
			--SIAC-7349                                                   
			if detCompCap = 0 then
				stanziamentoPrev:=0;
				deltaMenoPrev:=0;
				
			
			else
        	
				strMessaggio:='Lettura stanziamenti di previsione per elem_id='||bilElemPrevId||
																' anno_comp_in='||anno_comp_in||
																' idcomp_in='||idcomp_in|| '.';
	   
				select comp.elem_det_importo  into strict stanziamentoPrev
				from siac_t_bil_elem_det importiPrev,
				  siac_d_bil_elem_det_tipo tipoImpPrev,
				  siac_t_bil_elem_det_comp comp,
				  siac_d_bil_elem_det_comp_tipo comptipo
				where importiPrev.elem_id=bilElemPrevId AND
				   comp.elem_det_id = importiPrev.elem_det_id and
				   importiPrev.data_cancellazione is null and importiPrev.validita_fine is null and
				   tipoImpPrev.elem_det_tipo_id=importiPrev.elem_det_tipo_id and
				   tipoImpPrev.elem_det_tipo_code=STA_IMP and
				   comp.data_cancellazione is null and comp.validita_fine is null and
				   importiPrev.periodo_id=periodoCompId
				and comptipo.data_cancellazione is null and comptipo.validita_fine is null  
				and comp.elem_det_comp_tipo_id = comptipo.elem_det_comp_tipo_id
				and comptipo.elem_det_comp_tipo_id = idcomp_in
				-- SIAC-7349 Aggiunto non exists per escludere le componenti che sono collegate come "nuovi dettagli" tramite variazione in stato diverso da definitivo
				and not (exists (
					select siactbilel4_.elem_det_var_comp_id
					from 	siac_t_bil_elem_det_var_comp siactbilel4_
							cross join siac_t_bil_elem_det_var siactbilel5_
							cross join siac_r_variazione_stato siacrvaria6_
							cross join siac_d_variazione_stato siacdvaria7_
					where 	siactbilel4_.elem_det_var_id=siactbilel5_.elem_det_var_id
						and siactbilel5_.variazione_stato_id=siacrvaria6_.variazione_stato_id
						and siacrvaria6_.variazione_stato_tipo_id=siacdvaria7_.variazione_stato_tipo_id
						and siactbilel4_.elem_det_comp_id=comp.elem_det_comp_id
						and siactbilel4_.elem_det_flag='N'
						and siacdvaria7_.variazione_stato_tipo_code<>'D'
						and siactbilel4_.data_cancellazione is null
						and siactbilel5_.data_cancellazione is null
						and siacrvaria6_.data_cancellazione is null
					));

				 --- calcolo dei 'delta-previsione', variazioni agli importi del CAP-UP in stato
				 --- diverso da BOZZA,DEFINTIVO,ANNULLATO
				 --- 31.03.2016 Sofia SIAC-3304 aggiunto stato P
				 strMessaggio:='Lettura variazioni delta-meno-prev per elem_id='||bilElemPrevId||' anno_comp_in='||
								anno_comp_in||
								' idcomp_in='||idcomp_in|| '.';
				/* SIAC-7349*/
       	 
				select   coalesce(sum(abs(bilElemDetVarComp.elem_det_importo)),0) into strict deltaMenoPrev
				from siac_t_variazione var,
					  siac_r_variazione_stato statoVar,
					  siac_d_variazione_stato tipoStatoVar,
					  siac_t_bil_elem_det_var bilElemDetVar,
					  siac_d_bil_elem_det_tipo bilElemDetVarTipo,
					  siac_t_bil_elem_det_var_comp bilElemDetVarComp,
					  siac_d_bil_elem_det_comp_tipo bilElemDetCompTipo --adeguamento 
				where bilElemDetVar.elem_id=bilElemPrevId and
					   bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
					   bilElemDetVar.periodo_id=periodoCompId and
					   bilElemDetVar.elem_det_importo<0 AND
					   bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
					   bilElemDetVarTipo.elem_det_tipo_code=STA_IMP and
					   bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
					   statoVar.data_cancellazione is null and statoVar.validita_fine is null and
					   tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
					   -- tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) and -- 1109015 Sofia aggiunto STATO_VAR_B
					   tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) and -- Sofia 26072016 JIRA-SIAC-3887
					   var.variazione_id=statoVar.variazione_id and
					   var.data_cancellazione is null and var.validita_fine is null and
					   var.bil_id= bilancioId and
					   bilElemDetVarComp.data_cancellazione is null and bilElemDetVarComp.validita_fine is null and
					   bilElemDetVarComp.elem_det_var_id = bilElemDetVar.elem_det_var_id				
					and bilElemDetCompTipo.elem_det_comp_tipo_id = idcomp_in; --adeguamento
			end if;                                                   

  end if;
        --- calcolo variazioni applicate alla gestione, variazioni agli importi CAP-UG
      	strMessaggio:='Lettura variazioni di gestione per elem_id='||bilElemId||' anno_comp_in='||
                       anno_comp_in||
					   ' idcomp_in='||idcomp_in|| '.';

		select coalesce(sum(bilElemDetVarComp.elem_det_importo),0) into strict varImpGestione
        from siac_t_variazione var,
             siac_r_variazione_stato statoVar,
             siac_d_variazione_stato tipoStatoVar,
             siac_t_bil_elem_det_var bilElemDetVar,
             siac_d_bil_elem_det_tipo bilElemDetVarTipo,
             siac_t_bil_elem_det_var_comp bilElemDetVarComp,
             siac_d_bil_elem_det_comp_tipo bilElemDetCompTipo, --adeguamento
             siac_t_bil_elem_det_comp bilElemDetComp
          where bilElemDetVar.elem_id=bilElemId and
              bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
              bilElemDetVar.periodo_id=periodoCompId and
  	          bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
              bilElemDetVarTipo.elem_det_tipo_code=STA_IMP and
              bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
              statoVar.data_cancellazione is null and statoVar.validita_fine is null and
              tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
              tipoStatoVar.variazione_stato_tipo_code=STATO_VAR_D and
              var.variazione_id=statoVar.variazione_id and
              var.data_cancellazione is null and var.validita_fine is null and
              var.bil_id=bilancioId and
              bilElemDetVarComp.elem_det_var_id = bilElemDetVar.elem_det_var_id
              and bilElemDetVarComp.elem_det_comp_id = bilElemDetComp.elem_det_comp_id
			  and bilElemDetComp.elem_det_comp_tipo_id =  bilElemDetCompTipo.elem_det_comp_tipo_id
			  and bilElemDetCompTipo.elem_det_comp_tipo_id = idcomp_in --adeguamento
			  and bilElemDetVarComp.data_cancellazione is null and bilElemDetVarComp.validita_fine is null 
              and bilElemDetComp.data_cancellazione is null and bilElemDetComp.validita_fine is null;

	    if anno_comp_in=annoBilancio then
         if bilElemPrevId!=0 then

/* SIAC-7349 la cassa non ci serve?
          strMessaggio:='Lettura stanziamenti di previsione cassa per elem_id='||bilElemPrevId||' anno_comp_in='||anno_comp_in||'.';
          select importiprev.elem_det_importo into strict stanziamentoPrevCassa
	      from siac_t_bil_elem_det importiPrev, siac_d_bil_elem_det_tipo tipoImpPrev
	      where importiPrev.elem_id=bilElemPrevId AND
		   	    importiPrev.data_cancellazione is null and importiPrev.validita_fine is null and
     	   	    tipoImpPrev.elem_det_tipo_id=importiPrev.elem_det_tipo_id and
	            tipoImpPrev.elem_det_tipo_code=STA_IMP_SCA and
	            importiPrev.periodo_id=periodoCompId;
*/

          --- calcolo dei 'delta-previsione', variazioni agli importi di cassa del CAP-UP in stato
	      --- diverso da BOZZA,DEFINTIVO,ANNULLATO
          --- 31.03.2016 Sofia SIAC-3304 aggiunto stato P
/* SIAC-7349 la cassa non ci serve?
          strMessaggio:='Lettura variazioni delta-meno-prev cassa per elem_id='||bilElemPrevId||' anno_comp_in='||
                         anno_comp_in||'.';
       	  select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into strict deltaMenoPrevCassa
          from siac_t_variazione var,
               siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
               siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo
          where bilElemDetVar.elem_id=bilElemPrevId and
          	    bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
                bilElemDetVar.periodo_id=periodoCompId and
		        bilElemDetVar.elem_det_importo<0 AND
  	            bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
                bilElemDetVarTipo.elem_det_tipo_code=STA_IMP_SCA and
                bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
                statoVar.data_cancellazione is null and statoVar.validita_fine is null and
                tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
--                tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) and --1109015 Sofia aggiunto STATO_VAR_B
                tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) and -- 26072016 Sofia JIRA-SIAC-3887
                var.variazione_id=statoVar.variazione_id and
                var.data_cancellazione is null and var.validita_fine is null and
                var.bil_id=bilancioId;
*/
         end if;

         --- calcolo variazioni applicate alla gestione, variazioni agli importi di cassa CAP-UG
       	 strMessaggio:='Lettura variazioni di gestione cassa per elem_id='||bilElemId||' anno_comp_in='||
                        anno_comp_in||'.';
/* SIAC-7349 la cassa non ci serve?
       	 select coalesce(sum(bilElemDetVar.elem_det_importo),0) into strict varImpGestioneCassa
         from siac_t_variazione var,
          	  siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
              siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo
         where bilElemDetVar.elem_id=bilElemId and
         	   bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
               bilElemDetVar.periodo_id=periodoCompId and
  	           bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
               bilElemDetVarTipo.elem_det_tipo_code=STA_IMP_SCA and
               bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
               statoVar.data_cancellazione is null and statoVar.validita_fine is null and
               tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
               tipoStatoVar.variazione_stato_tipo_code=STATO_VAR_D and
               var.variazione_id=statoVar.variazione_id and
               var.data_cancellazione is null and var.validita_fine is null and
               var.bil_id=bilancioId;
*/
       end if;

	   /*  04.07.2016 Sofia ID-INC000001114035 non considerare le variazioni di gestione
	   -- stanziamenti di previsione competenza e cassa adeguati a
       -- relativi 'delta-meno' e variazioni def. applicate alle gestione

       stanziamentoPrev:= stanziamentoPrev-deltaMenoPrev+varImpGestione;
       stanziamentoPrevCassa:= stanziamentoPrevCassa-deltaMenoPrevCassa+varImpGestioneCassa; */

	   /*  04.07.2016 Sofia ID-INC000001114035 */
       stanziamentoPrev:= stanziamentoPrev-deltaMenoPrev;
       stanziamentoPrevCassa:= stanziamentoPrevCassa-deltaMenoPrevCassa;

 end if;

 if bilFaseOperativa in ( FASE_BIL_PROV, FASE_BIL_GEST,FASE_BIL_CONS,FASE_BIL_CHIU) then
       strMessaggio:='Lettura stanziamenti di gestione per elem_id='||bilElemId||
	   					' anno_comp_in='||anno_comp_in||
						' idcomp_in='||idcomp_in|| '.';
/* SIAC-7349
       select importiGest.elem_det_importo into strict stanziamento
	   from siac_t_bil_elem_det importiGest, siac_d_bil_elem_det_tipo tipoImp
	   where importiGest.elem_id=bilElemId AND
       	     importiGest.data_cancellazione is null and importiGest.validita_fine is null and
    	 	 tipoImp.elem_det_tipo_id=importiGest.elem_det_tipo_id and
             tipoImp.elem_det_tipo_code=STA_IMP and
    	     importiGest.periodo_id=periodoCompId;
*/
       select comp.elem_det_importo	into strict stanziamento
	   from siac_t_bil_elem_det importiGest,
       		siac_d_bil_elem_det_tipo tipoImp,
                siac_t_bil_elem_det_comp comp,
		siac_d_bil_elem_det_comp_tipo comptipo
	   where importiGest.elem_id=bilElemId AND
       	     importiGest.data_cancellazione is null and importiGest.validita_fine is null and
    	     tipoImp.elem_det_tipo_id=importiGest.elem_det_tipo_id and
             tipoImp.elem_det_tipo_code=STA_IMP and
    	     importiGest.periodo_id=periodoCompId and
             comp.elem_det_id = importiGest.elem_det_id and
	     	 comp.elem_det_comp_tipo_id = comptipo.elem_det_comp_tipo_id and
	         comp.data_cancellazione is null and comp.validita_fine is null and
             comptipo.data_cancellazione is null
            -- posso avere anche componenti non piu' valide
			 -- and comptipo.validita_fine is null and
			 and comptipo.elem_det_comp_tipo_id = idcomp_in
			-- SIAC-7349 Aggiunto non exists per escludere le componenti che sono collegate come "nuovi dettagli" tramite variazione in stato diverso da definitivo
			and not (exists (
				select siactbilel4_.elem_det_var_comp_id
				from 	siac_t_bil_elem_det_var_comp siactbilel4_
						cross join siac_t_bil_elem_det_var siactbilel5_
						cross join siac_r_variazione_stato siacrvaria6_
						cross join siac_d_variazione_stato siacdvaria7_
				where 	siactbilel4_.elem_det_var_id=siactbilel5_.elem_det_var_id
					and siactbilel5_.variazione_stato_id=siacrvaria6_.variazione_stato_id
					and siacrvaria6_.variazione_stato_tipo_id=siacdvaria7_.variazione_stato_tipo_id
					and siactbilel4_.elem_det_comp_id=comp.elem_det_comp_id
					and siactbilel4_.elem_det_flag='N'
					and siacdvaria7_.variazione_stato_tipo_code<>'D'
					and siactbilel4_.data_cancellazione is null
					and siactbilel5_.data_cancellazione is null
					and siacrvaria6_.data_cancellazione is null
				));

       --- calcolo dei 'delta-gestione', variazioni agli importi del CAP-UG in stato
 	   --- diverso da BOZZA,DEFINTIVO,ANNULLATO
       strMessaggio:='Lettura variazioni delta-meno-gest per elem_id='||bilElemId||' anno_comp_in='||
                           anno_comp_in||
						' idcomp_in='||idcomp_in|| '.';
       --- 31.03.2016 Sofia SIAC-3304 aggiunto stato P
/* SIAC-7349
       select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into strict deltaMenoGest
       from siac_t_variazione var,
            siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
	        siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo
       where bilElemDetVar.elem_id=bilElemId and
             bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
             bilElemDetVar.periodo_id=periodoCompId and
			 bilElemDetVar.elem_det_importo<0 AND
  	    	 bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
	         bilElemDetVarTipo.elem_det_tipo_code=STA_IMP and
    	     bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
	         statoVar.data_cancellazione is null and statoVar.validita_fine is null and
    	     tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
--  	         tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) and --1109015 Sofia aggiunto STATO_VAR_B
--  	         tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) and -- 26072016 Sofia JIRA-SIAC-3887
  	         tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P,STATO_VAR_B) and -- 14.102016 Sofia JIRA-SIAC-4099 riaggiunto B
        	 var.variazione_id=statoVar.variazione_id and
             var.data_cancellazione is null and var.validita_fine is null and
	         var.bil_id=bilancioId;
*/
       select coalesce(sum(abs(bilElemDetVarComp.elem_det_importo)),0) into strict deltaMenoGest
       from siac_t_variazione var,
            siac_r_variazione_stato statoVar,
            siac_d_variazione_stato tipoStatoVar,
	        siac_t_bil_elem_det_var bilElemDetVar,
            siac_d_bil_elem_det_tipo bilElemDetVarTipo,
            siac_t_bil_elem_det_var_comp bilElemDetVarComp,
            siac_d_bil_elem_det_comp_tipo bilElemDetCompTipo, --adeguamento
            siac_t_bil_elem_det_comp bilElemDetComp
       where bilElemDetVar.elem_id=bilElemId and
             bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
             bilElemDetVar.periodo_id=periodoCompId and
			 bilElemDetVar.elem_det_importo<0 AND
  	    	 bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
	         bilElemDetVarTipo.elem_det_tipo_code=STA_IMP and
    	     bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
	         statoVar.data_cancellazione is null and statoVar.validita_fine is null and
    	     tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
--  	         tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) and --1109015 Sofia aggiunto STATO_VAR_B
--  	         tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) and -- 26072016 Sofia JIRA-SIAC-3887
  	         tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P,STATO_VAR_B) and -- 14.102016 Sofia JIRA-SIAC-4099 riaggiunto B
        	 var.variazione_id=statoVar.variazione_id and
             var.data_cancellazione is null and var.validita_fine is null and
	         var.bil_id=bilancioId and
             bilElemDetVarComp.elem_det_var_id = bilElemDetVar.elem_det_var_id
             and bilElemDetVarComp.elem_det_comp_id = bilElemDetComp.elem_det_comp_id
			 and bilElemDetVarComp.data_cancellazione is null and bilElemDetVarComp.validita_fine is null  
             and bilElemDetComp.data_cancellazione is null and bilElemDetComp.validita_fine is null  
			 and bilElemDetComp.elem_det_comp_tipo_id =  bilElemDetCompTipo.elem_det_comp_tipo_id
			 and bilElemDetCompTipo.elem_det_comp_tipo_id = idcomp_in; --adeguamento

      if anno_comp_in=annoBilancio then
        strMessaggio:='Lettura stanziamenti di gestione cassa per elem_id='||bilElemId||' anno_comp_in='||anno_comp_in||'.';
/* SIAC-7349 la cassa non ci serve?
        select importiGest.elem_det_importo into strict stanziamentoCassa
		from siac_t_bil_elem_det importiGest, siac_d_bil_elem_det_tipo tipoImp
	    where importiGest.elem_id=bilElemId AND
       		  importiGest.data_cancellazione is null and importiGest.validita_fine is null and
	   		  tipoImp.elem_det_tipo_id=importiGest.elem_det_tipo_id and
	          tipoImp.elem_det_tipo_code=STA_IMP_SCA and
	    	  importiGest.periodo_id=periodoCompId;
*/
         --- calcolo dei 'delta-gestione', variazioni agli importi di cassa del CAP-UG in stato
 	     --- diverso da BOZZA,DEFINTIVO,ANNULLATO
       	strMessaggio:='Lettura variazioni delta-meno-gest cassa per elem_id='||bilElemId||' anno_comp_in='||
                           anno_comp_in||'.';
	             --- 31.03.2016 Sofia SIAC-3304 aggiunto stato P
/* SIAC-7349 la cassa non ci serve?
        select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into strict deltaMenoGestCassa
        from siac_t_variazione var,
        	 siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
	         siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo
        where bilElemDetVar.elem_id=bilElemId and
              bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
              bilElemDetVar.periodo_id=periodoCompId and
		      bilElemDetVar.elem_det_importo<0 AND
  	          bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
	          bilElemDetVarTipo.elem_det_tipo_code=STA_IMP_SCA and
    	      bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
	          statoVar.data_cancellazione is null and statoVar.validita_fine is null and
    	      tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
--   	          tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) and -- 1109015 Sofia aggiunto STATO_VAR_B
--   	          tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) and -- 26072016 Sofia JIRA-SIAC-3887
   	          tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P,STATO_VAR_B) and -- 14102016 Sofia JIRA-SIAC-4099
       	      var.variazione_id=statoVar.variazione_id and
              var.data_cancellazione is null and var.validita_fine is null and
	          var.bil_id=bilancioId;
*/
        end if;
        -- importo massimo impegnabile
        stanzMassimoImpegnabile:=null;
        strMessaggio:='Lettura massimo impegnabile per elem_id='||bilElemId||
							' anno_comp_in='||anno_comp_in||
							' idcomp_in='||idcomp_in|| '.';

		select importiGest.elem_det_importo into stanzMassimoImpegnabile
		from siac_t_bil_elem_det importiGest, siac_d_bil_elem_det_tipo tipoImp
     	where importiGest.elem_id=bilElemId AND
              importiGest.data_cancellazione is null and importiGest.validita_fine is null and
	   	 	  tipoImp.elem_det_tipo_id=importiGest.elem_det_tipo_id and
		      tipoImp.elem_det_tipo_code=STA_IMP_MI and
	    	  importiGest.periodo_id=periodoCompId;

 end if;

 strMessaggio:='Stanziamento effettivo elem_id='||bilElemId ||
						' idcomp_in='||idcomp_in|| '.';
 case
  ---    ANNASILVIA CMTO FORZATURA 13-01-2017 aggiunta condizione  and ente_prop_in <> 3
  ---    10/02/2017 - richiesta REGP (DI MICHELE) - eliminare controllo tra previsione e gestione
  ---    in esercizio provvisorio
--   when bilFaseOperativa=FASE_BIL_PROV and ente_prop_in = 0 then
-- 01.06.2017 Sofia HD-INC000001805128 CmTo richiede di attivare il controllo
   when bilFaseOperativa=FASE_BIL_PROV and enteProprietarioId = 3 then

--   		if stanziamentoPrev>stanziamento then
--      26072016 Sofia JIRA-SIAC-3887
   		if stanziamentoPrev>stanziamento-deltaMenoGest then

             /*  04.07.2016 Sofia ID-INC000001114035 non considerare le variazioni di gestione
                 nello stanziamento non sono considerate le variazioni di gestione,
                 se poi lo stanziamento effettivo e quello di gestione allora
                 consideriamo i deltamenoGest per abbatterlo ulteriormente */
        	 --stanziamentoEff:=stanziamento;
             -- stanziamentoEff abbattutto dai 'delta-gestione'
	         stanziamentoEff:=stanziamento-deltaMenoGest;
        else stanziamentoEff:=stanziamentoPrev;
        end if;

        if anno_comp_in=annoBilancio then
 --       if stanziamentoPrevCassa>stanziamentoCassa then
        --      26072016 Sofia JIRA-SIAC-3887
         if stanziamentoPrevCassa>stanziamentoCassa-deltaMenoGestCassa then
           /*  04.07.2016 Sofia ID-INC000001114035 non considerare le variazioni di gestione
               nello stanziamento non sono considerate le variazioni di gestione,
               se poi lo stanziamento effettivo e quello di gestione allora
               consideriamo i deltamenoGest per abbatterlo ulteriormente */
        	/*  stanziamentoEffCassa:=stanziamentoCassa; */
              stanziamentoEffCassa:=stanziamentoCassa-deltaMenoGestCassa;
         else stanziamentoEffCassa:=stanziamentoPrevCassa;
         end if;
        end if;
   ELSE
        /*  04.07.2016 Sofia ID-INC000001114035
   		stanziamentoEff:=stanziamento; */
        stanziamentoEff:=stanziamento-deltaMenoGest;
        if anno_comp_in=annoBilancio then
          /*  04.07.2016 Sofia ID-INC000001114035
          stanziamentoEffCassa:=stanziamentoCassa; */
          stanziamentoEffCassa:=stanziamentoCassa-deltaMenoGestCassa;
        end if;
 end case;
  /*  04.07.2016 Sofia ID-INC000001114035 spostato sopra per considerare i deltaMenoGest
     solo se lo stanziamento effettivo da considerare e quello di gestione
 -- stanziamentoEff abbattutto dai 'delta-gestione'
 stanziamentoEff:=stanziamentoEff-deltaMenoGest;
 if anno_comp_in=annoBilancio then
  stanziamentoEffCassa:=stanziamentoEffCassa-deltaMenoGestCassa;
 end if; */

 strMessaggio:='Stanziamento effettivo elem_id='||bilElemId||
			 			'anno_comp_in='||anno_comp_in||
						' idcomp_in='||idcomp_in|| '.';
 elemId:=bilElemId;
 annoCompetenza:=anno_comp_in;
 stanzEffettivo:=stanziamentoEff;
 if anno_comp_in=annoBilancio then
     stanzEffettivoCassa:=stanziamentoEffCassa;
 end if;
 if stanzMassimoImpegnabile is not null then
 	massimoImpegnabile:=stanzMassimoImpegnabile;
 end if;

 return next;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
	when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
        
END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_stanz_effettivo_ug_anno_comp (id_in integer, anno_comp_in character varying, idcomp_in integer)
  OWNER TO siac;
--GRANT EXECUTE ON FUNCTION siac.fnc_siac_stanz_effettivo_ug_anno_comp(integer, character varying, integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_stanz_effettivo_ug_anno_comp(integer, character varying, integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_stanz_effettivo_ug_anno_comp(integer, character varying, integer) TO siac;
--end fnc_siac_stanz_effettivo_ug_anno_comp


--Start fnc_siac_stanz_effettivo_up_anno_comp
CREATE OR REPLACE FUNCTION siac.fnc_siac_stanz_effettivo_up_anno_comp (
  id_in integer,
  id_comp integer,
  anno_comp_in varchar
  
)
RETURNS TABLE (
  elemid integer,
  annocompetenza varchar,
  stanzeffettivo numeric,
  stanzeffettivocassa numeric,
  massimoimpegnabile numeric
)
LANGUAGE 'plpgsql'
COST 100
VOLATILE
ROWS 1000
AS $BODY$
DECLARE


-- constant
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';
STA_IMP_SCA     constant varchar:='SCA';
STA_IMP_MI     constant varchar:='MI'; -- tipo importo massimo impegnabile

-- fasi di bilancio
FASE_BIL_PREV  constant varchar:='P'; -- previsione
FASE_BIL_PROV  constant varchar:='E'; -- esercizio provvisorio
FASE_BIL_GEST  constant varchar:='G'; -- esercizio gestione
FASE_BIL_CONS  constant varchar:='O'; -- esercizio consuntivo
FASE_BIL_CHIU  constant varchar:='C'; -- esercizio chiuso

-- stati variazioni di importo
STATO_VAR_G    constant varchar:='G'; -- GIUNTA
STATO_VAR_C    constant varchar:='C'; -- CONSIGLIO
STATO_VAR_D    constant varchar:='D'; -- DEFINITIVA
STATO_VAR_B    constant varchar:='B'; -- BOZZA
--- 31.03.2016 Sofia SIAC-3304 aggiunto stato P
STATO_VAR_P    constant varchar:='P'; -- PRE-DEFINITIVO

bilancioId integer:=0;
bilElemId  integer:=0;
bilElemGestId  integer:=0;

strMessaggio varchar(1500):=NVL_STR;

bilFaseOperativa varchar(10):=NVL_STR;
annoBilancio varchar(10):=NVL_STR;

stanziamentoPrev numeric:=0;
stanziamentoPrevCassa numeric:=0;
stanziamento numeric:=0;
stanziamentoEff numeric:=0;
deltaMenoPrev numeric:=0;
varImpGestione numeric:=0;
deltaMenoGest numeric:=0;
deltaMenoPrevCassa numeric:=0;
varImpGestioneCassa numeric:=0;
deltaMenoGestCassa numeric:=0;
stanziamentoEffCassa numeric:=0;
stanziamentoCassa numeric:=0;
stanzMassimoImpegnabile numeric:=null;
enteProprietarioId INTEGER:=0;
periodoId integer:=0;
periodoCompId integer:=0;

BEGIN

     annoCompetenza:=null;
     stanzEffettivo:=null;
     stanzEffettivoCassa:=null;
     elemId:=null;
     massimoImpegnabile:=null;

      -- controllo parametri
      -- anno_comp_in obbligatorio
      -- se id_in non serve altro
      -- diversamente deve essere passato
      -- ente_prop_id, anno_in o bil_id_in
      --  e  la chiave logica del capitolo
      -- ele_code_in,ele_code2_in,ele_code3_in

     strMessaggio:='Calcolo stanziamento effettivo.Controllo parametri.';

     if anno_comp_in is null or anno_comp_in=NVL_STR then
         	RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
     end if;
 
     if id_comp is null or id_comp=0 then
         	RAISE EXCEPTION '% Id componente mancante.',strMessaggio;
     end if;

     if id_in is null or id_in=0 then

          if  ( (bil_id_in is null or bil_id_in=0) and (ente_prop_in is null or ente_prop_in=0)) then
         	     RAISE EXCEPTION '% Id ente proprietario mancante.',strMessaggio;
          end if;

          if ele_code_in is null or ele_code_in=NVL_STR or ele_code2_in is null or ele_code2_in=NVL_STR or ele_code3_in is null or ele_code3_in=NVL_STR then
         	     RAISE EXCEPTION '% Chiave logica elem.Bil. mancante.',strMessaggio;
          end if;

          if ( (bil_id_in is null or bil_id_in=0 ) and (anno_in is null or anno_in=NVL_STR)) then
         	     RAISE EXCEPTION '% Anno bilancio mancante.',strMessaggio;
          end if;
     end if;


     if id_in is not null and id_in!=0 then

          strMessaggio:='Lettura identificativo bilancioId, annoBilancio e enteProprietarioId da elemento di bilancio elem_id='||id_in||'.';
         	select bil.bil_id, per.anno, bilElem.ente_proprietario_id
                    into strict bilancioId, annoBilancio, enteProprietarioId
             from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem,
                  siac_t_bil bil, siac_t_periodo per
             where bilElem.elem_id=id_in
             and   bilElem.data_cancellazione is null
             and   bilElem.validita_fine is null
             and   tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
             and   tipoBilElem.elem_tipo_code = TIPO_CAP_UP
             and   bil.bil_id=bilElem.bil_id
             and   per.periodo_id=bil.periodo_id;
             bilElemId:=id_in;
     else
          if bil_id_in is not null and bil_id_in!=0  then
      	     bilancioId:=bil_id_in;
          end if;
     end if;

     if bilancioId is not null and bilancioId!=0 then
          strMessaggio:='Lettura identificativo annoBilancio enteProprietarioId periodoId elemento di bilancio elem_id='||id_in
                   ||' per bilancioId='||bilancioId||'.';

          select per.anno,  bil.ente_proprietario_id, per.periodo_id into strict annoBilancio, enteProprietarioId, periodoId
          from siac_t_bil bil, siac_t_periodo per
          where bil.bil_id=bilancioId 
                and per.periodo_id=bil.periodo_id;
     end if;

     if bilElemId is null or bilElemId=0 then
          strMessaggio:='Lettura identificativo elemento di bilancio '||ele_code_in||'/'||ele_code2_in||'/'||ele_code3_in||'.';
          if bilancioId is not null and bilancioId!=0 then
      	     strMessaggio:='Lettura identificativo elemento di bilancio '||ele_code_in||'/'||ele_code2_in||'/'||ele_code3_in
                         ||'  per bilancioId='||bilancioId||' .';
               select bilElem.elem_id into strict bilElemId
               from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem
               where bilElem.bil_id=bilancioId
               and   bilElem.elem_code=ele_code_in
               and   bilElem.elem_code2=ele_code2_in
               and   bilElem.elem_code3=ele_code3_in
               and   bilElem.data_cancellazione is null
               and   bilElem.validita_fine is null
               and   tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
               and   tipoBilElem.elem_tipo_code = TIPO_CAP_UP;
          else
     	     strMessaggio:='Lettura identificativo elemento di bilancio '||ele_code_in||'/'||ele_code2_in||'/'||ele_code3_in
                         ||'  bilancioId periodoId per annoBilancioIn='||anno_in||' enteProprietarioIn'||ente_prop_in||' .';
               select bilElem.elem_id, bilelem.bil_id, per.periodo_id into strict bilElemId, bilancioId, periodoId
               from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem,
               siac_t_bil bil, siac_t_periodo per, siac_d_periodo_tipo tipoPer
               where per.anno=anno_in
               and   per.ente_proprietario_id=ente_prop_in
               and   tipoPer.periodo_tipo_id=per.periodo_tipo_id
               and   tipoPer.periodo_tipo_code='SY'
               and   bil.periodo_id=per.periodo_id
               and   bilElem.bil_id=bil.bil_id
               and   bilElem.elem_code=ele_code_in
               and   bilElem.elem_code2=ele_code2_in
               and   bilElem.elem_code3=ele_code3_in
               and   bilElem.data_cancellazione is null
               and   bilElem.validita_fine is null
               and   tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
               and   tipoBilElem.elem_tipo_code = TIPO_CAP_UP;

               annoBilancio:=anno_in;
               enteProprietarioId:=ente_prop_in;

          end if;    
     end if;

     strMessaggio:='Lettura fase di bilancio corrente per  anno bilancio='||annoBilancio||' bilancioId='||bilancioId||'.';
     select faseop.fase_operativa_code into strict bilFaseOperativa
     from siac_d_fase_operativa faseOp, siac_r_bil_fase_operativa bilFaseOp
     where bilfaseop.bil_id=bilancioId 
          and bilfaseop.data_cancellazione is null
          and bilfaseop.validita_fine is null
          and faseOp.fase_operativa_id = bilfaseop.fase_operativa_id
          and faseOp.data_cancellazione is null
          and faseOp.validita_fine is null;


     if bilFaseOperativa not in ( FASE_BIL_PREV, FASE_BIL_PROV, FASE_BIL_GEST,FASE_BIL_CONS,FASE_BIL_CHIU) then
        	RAISE EXCEPTION '% Fase non ammessa per il calcolo richiesto.',strMessaggio;
     end if;

     if anno_comp_in!=annoBilancio then
      	strMessaggio:='Lettura periodoCompId per anno_comp_in='||anno_comp_in||' elem_id='||bilElemId||'.';
          select  per.periodo_id into strict periodoCompId
          from siac_t_periodo per, siac_d_periodo_tipo perTipo
          where per.anno=anno_comp_in
          and   per.ente_proprietario_id=enteProprietarioId
          and   perTipo.periodo_tipo_id=per.periodo_tipo_id
          and   perTipo.periodo_tipo_code='SY';
     else
          periodoCompId:=periodoId;
     end if;

     if bilFaseOperativa = FASE_BIL_PROV then
          strMessaggio:='Lettura elemento di bilancio equivalente di gestione per elem_id='||bilElemId||'.';
          select bilElemGest.elem_id into  bilElemGestId
          from siac_t_bil_elem bilElemPrev, siac_d_bil_elem_tipo tipoGest,
               siac_t_bil_elem bilElemGest
          where bilElemPrev.elem_id=bilElemId
          and bilElemGest.elem_code=bilElemPrev.elem_code
          and bilElemGest.elem_code2=bilElemPrev.elem_code2 
          and bilElemGest.elem_code3=bilElemPrev.elem_code3
          and bilElemGest.ente_proprietario_id=bilElemPrev.ente_proprietario_id
          and bilElemGest.bil_id=bilElemPrev.bil_id
          and bilElemGest.data_cancellazione is null 
          and bilElemGest.validita_fine is null
          and tipoGest.elem_tipo_id=bilElemGest.elem_tipo_id
          and tipoGest.elem_tipo_code=TIPO_CAP_UG;

          if NOT FOUND then
          	bilElemGestId:=0;
          end if;
     end if;

     strMessaggio:='Lettura stanziamenti di previsione per elem_id='||bilElemId||' anno_comp_in='||anno_comp_in||'.';

     /*SIAC - 7349*/
     select comp.elem_det_importo  into strict stanziamentoPrev
     from siac_t_bil_elem_det importiPrev,
     	siac_d_bil_elem_det_tipo tipoImpPrev,
     	siac_t_bil_elem_det_comp comp,
     	siac_d_bil_elem_det_comp_tipo comptipo
     where importiPrev.elem_id=bilElemId
     	and comp.elem_det_id = importiPrev.elem_det_id
          and importiPrev.data_cancellazione is null 
          and importiPrev.validita_fine is null
     	and tipoImpPrev.elem_det_tipo_id=importiPrev.elem_det_tipo_id 
          and tipoImpPrev.elem_det_tipo_code=STA_IMP
     	and comp.data_cancellazione is null and comp.validita_fine is null
          and importiPrev.periodo_id=periodoCompId
     	and comptipo.data_cancellazione is null 
        -- SIAC-7796
		-- and comptipo.validita_fine is null  
     	and comp.elem_det_comp_tipo_id = comptipo.elem_det_comp_tipo_id
     	and comptipo.elem_det_comp_tipo_id = id_comp
	-- SIAC-7349 Aggiunto non exists per escludere le componenti che sono collegate come "nuovi dettagli" tramite variazione in stato diverso da definitivo
		and not (exists (
			select siactbilel4_.elem_det_var_comp_id
			from 	siac_t_bil_elem_det_var_comp siactbilel4_
					cross join siac_t_bil_elem_det_var siactbilel5_
					cross join siac_r_variazione_stato siacrvaria6_
					cross join siac_d_variazione_stato siacdvaria7_
			where 	siactbilel4_.elem_det_var_id=siactbilel5_.elem_det_var_id
				and siactbilel5_.variazione_stato_id=siacrvaria6_.variazione_stato_id
				and siacrvaria6_.variazione_stato_tipo_id=siacdvaria7_.variazione_stato_tipo_id
				and siactbilel4_.elem_det_comp_id=comp.elem_det_comp_id
				and siactbilel4_.elem_det_flag='N'
				and siacdvaria7_.variazione_stato_tipo_code<>'D'
				and siactbilel4_.data_cancellazione is null
				and siactbilel5_.data_cancellazione is null
				and siacrvaria6_.data_cancellazione is null
			));

     if anno_comp_in=annoBilancio then
           strMessaggio:='Lettura stanziamenti di previsione cassa per elem_id='||bilElemId||' anno_comp_in='||anno_comp_in||'.';
           select importiprev.elem_det_importo into strict stanziamentoPrevCassa
           from siac_t_bil_elem_det importiPrev, siac_d_bil_elem_det_tipo tipoImpPrev
           where importiPrev.elem_id=bilElemId
      	     and importiPrev.data_cancellazione is null 
               and importiPrev.validita_fine is null
        	   	and tipoImpPrev.elem_det_tipo_id=importiPrev.elem_det_tipo_id
     	     and tipoImpPrev.elem_det_tipo_code=STA_IMP_SCA
     	     and importiPrev.periodo_id=periodoCompId;
     end if;


  
     if bilFaseOperativa in (FASE_BIL_PROV,FASE_BIL_PREV) then --1
          --- calcolo dei 'delta-previsione', variazioni agli importi del CAP-UP in stato
     	--- diverso da BOZZA,DEFINTIVO,ANNULLATO
        	strMessaggio:='Lettura variazioni delta-meno-prev per elem_id='||bilElemId||' anno_comp_in='||
                            anno_comp_in||'.';
     
     	/*SIAC - 7349*/
         /*ERRORE RISCONTRATO NEL TEST FASE DI PREV - mr*/
	     /*select   coalesce(sum(abs(bilElemDetVarComp.elem_det_importo)),0) into strict deltaMenoPrev
          from siac_t_variazione var,
              	siac_r_variazione_stato statoVar,
	     	siac_d_variazione_stato tipoStatoVar,
               siac_t_bil_elem_det_var bilElemDetVar,
	     	siac_d_bil_elem_det_tipo bilElemDetVarTipo,
               siac_t_bil_elem_det_var_comp bilElemDetVarComp,
               siac_d_bil_elem_det_comp_tipo bilElemDetCompTipo, 
               siac_t_bil_elem_det_comp bilElemDetComp
              where bilElemDetVar.elem_id=bilElemId
             	     and bilElemDetVar.data_cancellazione is null 
                    and bilElemDetVar.validita_fine is null
                    and bilElemDetVar.periodo_id=periodoCompId
	     	     and bilElemDetVar.elem_det_importo<0
  	               and bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id
                    and bilElemDetVarTipo.elem_det_tipo_code=STA_IMP
                    and bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id
                    and statoVar.data_cancellazione is null 
                    and statoVar.validita_fine is null
                    and tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id
                    and tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) -- 1109015 Sofia aggiunto STATO_VAR_B
	     		and tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) -- Sofia 26072016 JIRA-SIAC-3887
                    and var.variazione_id=statoVar.variazione_id
                    and var.data_cancellazione is null and var.validita_fine is null
                    and var.bil_id= bilancioId
	     		and bilElemDetVarComp.data_cancellazione is null and bilElemDetVarComp.validita_fine is null
	     		and bilElemDetComp.data_cancellazione is null and bilElemDetComp.validita_fine is null
                    and bilElemDetVarComp.elem_det_var_id = bilElemDetVar.elem_det_var_id
                    and bilElemDetComp.elem_det_comp_tipo_id =  bilElemDetCompTipo.elem_det_comp_tipo_id
	     		and bilElemDetCompTipo.elem_det_comp_tipo_id = id_comp; --adeguamento*/
          
          select  coalesce(sum(abs(bilElemDetVarComp.elem_det_importo)),0) into strict deltaMenoPrev
			from siac_t_variazione var,
			siac_r_variazione_stato statoVar,
			siac_d_variazione_stato tipoStatoVar,
			siac_t_bil_elem_det_var bilElemDetVar,
			siac_d_bil_elem_det_tipo bilElemDetVarTipo,
			siac_t_bil_elem_det_var_comp bilElemDetVarComp,
			siac_d_bil_elem_det_comp_tipo bilElemDetCompTipo --adeguamento 
			where bilElemDetVar.elem_id=bilElemId and
			bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
			bilElemDetVar.periodo_id=periodoCompId and
			bilElemDetVar.elem_det_importo<0 AND
			bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
			bilElemDetVarTipo.elem_det_tipo_code=STA_IMP and
			bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
			statoVar.data_cancellazione is null and statoVar.validita_fine is null and
			tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
			-- tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) and -- 1109015 Sofia aggiunto STATO_VAR_B
			tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) and -- Sofia 26072016 JIRA-SIAC-3887
			var.variazione_id=statoVar.variazione_id and
			var.data_cancellazione is null and var.validita_fine is null and
			var.bil_id= bilancioId and
			bilElemDetVarComp.data_cancellazione is null and bilElemDetVarComp.validita_fine is null and
			bilElemDetVarComp.elem_det_var_id = bilElemDetVar.elem_det_var_id				
			and bilElemDetCompTipo.elem_det_comp_tipo_id = id_comp;                  

          if  bilFaseOperativa =FASE_BIL_PROV and bilElemGestId!=0 then --2
          --- calcolo variazioni applicate alla gestione, variazioni agli importi CAP-UG
               strMessaggio:='Lettura variazioni di gestione per elem_id='||bilElemGestId||' anno_comp_in='||
                       anno_comp_in||'.';
	
	          select coalesce(sum(bilElemDetVarComp.elem_det_importo),0) into strict varImpGestione
                  from siac_t_variazione var,
                       siac_r_variazione_stato statoVar,
                       siac_d_variazione_stato tipoStatoVar,
                       siac_t_bil_elem_det_var bilElemDetVar,
                       siac_d_bil_elem_det_tipo bilElemDetVarTipo,
                       siac_t_bil_elem_det_var_comp bilElemDetVarComp,
                       siac_d_bil_elem_det_comp_tipo bilElemDetCompTipo, --adeguamento
                       siac_t_bil_elem_det_comp bilElemDetComp
                     -- where bilElemDetVar.elem_id=bilElemId --SIAC-7349 Fix TC su calcolo disponibilita' variare - GS - 10/07/2020
                    where bilElemDetVar.elem_id=bilElemGestId --SIAC-7349 Fix TC su calcolo disponibilita' variare - GS - 10/07/2020
                    and bilElemDetVar.data_cancellazione is null 
                    and bilElemDetVar.validita_fine is null
                    and bilElemDetVar.periodo_id=periodoCompId
  	               and bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id
                    and bilElemDetVarTipo.elem_det_tipo_code=STA_IMP
                    and bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id
                    and statoVar.data_cancellazione is null and statoVar.validita_fine is null
                    and tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id
                    and tipoStatoVar.variazione_stato_tipo_code=STATO_VAR_D
                    and var.variazione_id=statoVar.variazione_id
                    and var.data_cancellazione is null 
                    and var.validita_fine is null
                    and var.bil_id=bilancioId
                    and bilElemDetVarComp.elem_det_var_id = bilElemDetVar.elem_det_var_id
                    and bilElemDetVarComp.elem_det_comp_id = bilElemDetComp.elem_det_comp_id
	          	and bilElemDetComp.elem_det_comp_tipo_id =  bilElemDetCompTipo.elem_det_comp_tipo_id
	          	and bilElemDetCompTipo.elem_det_comp_tipo_id = id_comp --adeguamento
	          	and bilElemDetVarComp.data_cancellazione is null 
                    and bilElemDetVarComp.validita_fine is null 
                    and bilElemDetComp.data_cancellazione is null 
                    and bilElemDetComp.validita_fine is null;


          end if; --2
     end if; --1

     if bilFaseOperativa in ( FASE_BIL_PROV) and bilElemGestId!=0 then


			  strMessaggio:='Lettura stanziamenti di gestione per elem_id='||bilElemGestId||' anno_comp_in='||anno_comp_in||'.';
			--SIAC-7349
				-- SIAC-7796: 	defaultato a zero gli importi nel caso di componente mancante in gestione equivalente 
				-- select comp.elem_det_importo	into strict stanziamento
			  select coalesce(comp.elem_det_importo, 0) into stanziamento
			from siac_t_bil_elem_det importiGest,
			siac_d_bil_elem_det_tipo tipoImp,
			  siac_t_bil_elem_det_comp comp,
			siac_d_bil_elem_det_comp_tipo comptipo
			-- where importiGest.elem_id=bilElemId --SIAC-7349 Fix TC su calcolo disponibilita' variare - GS - 10/07/2020
			where importiGest.elem_id=bilElemGestId --SIAC-7349 Fix TC su calcolo disponibilita' variare - GS - 10/07/2020    	
			and importiGest.data_cancellazione is null 
			  and importiGest.validita_fine is null
				 and tipoImp.elem_det_tipo_id=importiGest.elem_det_tipo_id
			  and tipoImp.elem_det_tipo_code=STA_IMP
				 and importiGest.periodo_id=periodoCompId
			  and comp.elem_det_id = importiGest.elem_det_id
			 and comp.elem_det_comp_tipo_id = comptipo.elem_det_comp_tipo_id
			 and comp.data_cancellazione is null 
			  and comp.validita_fine is null
			  and comptipo.data_cancellazione is null 
			  -- SIAC-7796
			  -- and comptipo.validita_fine is null
			 and comptipo.elem_det_comp_tipo_id = id_comp
			-- SIAC-7349 Aggiunto non exists per escludere le componenti che sono collegate come "nuovi dettagli" tramite variazione in stato diverso da definitivo
			and not (exists (
				select siactbilel4_.elem_det_var_comp_id
				from 	siac_t_bil_elem_det_var_comp siactbilel4_
						cross join siac_t_bil_elem_det_var siactbilel5_
						cross join siac_r_variazione_stato siacrvaria6_
						cross join siac_d_variazione_stato siacdvaria7_
				where 	siactbilel4_.elem_det_var_id=siactbilel5_.elem_det_var_id
					and siactbilel5_.variazione_stato_id=siacrvaria6_.variazione_stato_id
					and siacrvaria6_.variazione_stato_tipo_id=siacdvaria7_.variazione_stato_tipo_id
					and siactbilel4_.elem_det_comp_id=comp.elem_det_comp_id
					and siactbilel4_.elem_det_flag='N'
					and siacdvaria7_.variazione_stato_tipo_code<>'D'
					and siactbilel4_.data_cancellazione is null
					and siactbilel5_.data_cancellazione is null
					and siacrvaria6_.data_cancellazione is null
				));	     

	     
	     
          --- calcolo dei 'delta-gestione', variazioni agli importi del CAP-UG in stato
          --- diverso da BOZZA,DEFINTIVO,ANNULLATO
          strMessaggio:='Lettura variazioni delta-meno-gest per elem_id='||bilElemGestId||' anno_comp_in='||
                           anno_comp_in||'.';
		
     	--SIAC-7349
     	select coalesce(sum(abs(bilElemDetVarComp.elem_det_importo)),0) into strict deltaMenoGest
          from siac_t_variazione var,
          siac_r_variazione_stato statoVar,
          siac_d_variazione_stato tipoStatoVar,
	     siac_t_bil_elem_det_var bilElemDetVar,
          siac_d_bil_elem_det_tipo bilElemDetVarTipo,
          siac_t_bil_elem_det_var_comp bilElemDetVarComp,
          siac_d_bil_elem_det_comp_tipo bilElemDetCompTipo, --adeguamento
          siac_t_bil_elem_det_comp bilElemDetComp
     	  -- where bilElemDetVar.elem_id=bilElemId --SIAC-7349 Fix TC su calcolo disponibilita' variare - GS - 10/07/2020
          where bilElemDetVar.elem_id=bilElemGestId --SIAC-7349 Fix TC su calcolo disponibilita' variare - GS - 10/07/2020    	
          and bilElemDetVar.data_cancellazione is null 
          and bilElemDetVar.validita_fine is null
          and bilElemDetVar.periodo_id=periodoCompId
		and bilElemDetVar.elem_det_importo<0
  	    	and bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id
	     and bilElemDetVarTipo.elem_det_tipo_code=STA_IMP
    	     and bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id
	     and statoVar.data_cancellazione is null 
          and statoVar.validita_fine is null
    	     and tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id
       	--and tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) and --1109015 Sofia aggiunto STATO_VAR_B
      	--and tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) and -- 26072016 Sofia JIRA-SIAC-3887
       	and tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P,STATO_VAR_B) -- 14.102016 Sofia JIRA-SIAC-4099 riaggiunto B
          and var.variazione_id=statoVar.variazione_id
          and var.data_cancellazione is null and var.validita_fine is null
     	and var.bil_id=bilancioId
          and bilElemDetVarComp.elem_det_var_id = bilElemDetVar.elem_det_var_id
          and bilElemDetVarComp.elem_det_comp_id = bilElemDetComp.elem_det_comp_id
     	and bilElemDetVarComp.data_cancellazione is null 
          and bilElemDetVarComp.validita_fine is null  
          and bilElemDetComp.data_cancellazione is null 
          and bilElemDetComp.validita_fine is null  
     	and bilElemDetComp.elem_det_comp_tipo_id =  bilElemDetCompTipo.elem_det_comp_tipo_id
     	and bilElemDetCompTipo.elem_det_comp_tipo_id = id_comp; --adeguamento

     end if;


     stanziamentoPrev:= stanziamentoPrev-deltaMenoPrev;




     strMessaggio:='Stanziamento effettivo elem_id='||bilElemId||'.';
     case
          when bilFaseOperativa=FASE_BIL_PROV then
 --  		
   		     if stanziamentoPrev>stanziamento-deltaMenoGest then
                    stanziamentoEff:=stanziamento-deltaMenoGest;
               else 
                    stanziamentoEff:=stanziamentoPrev;
               end if;

               if anno_comp_in=annoBilancio then
--             if stanziamentoPrevCassa>stanziamentoCassa then 26072016 Sofia JIRA-SIAC-3887
                    if stanziamentoPrevCassa>stanziamentoCassa-deltaMenoGestCassa then
                    /* 04.07.2016 Sofia ID-INC000001114035
        	          stanziamentoEffCassa:=stanziamentoCassa; **/
                         stanziamentoEffCassa:=stanziamentoCassa-deltaMenoGestCassa;
                    else 
                         stanziamentoEffCassa:=stanziamentoPrevCassa;
                    end if;
               end if;
     else

   	     stanziamentoEff:=stanziamentoPrev;
          if anno_comp_in=annoBilancio then
               stanziamentoEffCassa:=stanziamentoPrevCassa;
          end if;

     end case;

  /* 04.07.2016 Sofia ID-INC000001114035
 -- stanziamentoEff abbattutto dai 'delta-gestione'
 stanziamentoEff:=stanziamentoEff-deltaMenoGest;
 if anno_comp_in = annoBilancio then
  stanziamentoEffCassa:=stanziamentoEffCassa-deltaMenoGestCassa;
 end if; */



     elemId:=bilElemId;
     annoCompetenza:=anno_comp_in;
     stanzEffettivo:=stanziamentoEff;
     if anno_comp_in = annoBilancio then
     stanzEffettivoCassa:=stanziamentoEffCassa;
     end if;
     if stanzMassimoImpegnabile is not null then
        	massimoImpegnabile:=stanzMassimoImpegnabile;
     end if;

     return next;


     exception
         when RAISE_EXCEPTION THEN
             RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
             return;
     	when no_data_found then
     		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
             return;
     	when others  THEN
      		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
             return;

END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_stanz_effettivo_up_anno_comp (id_in integer, id_comp integer, anno_comp_in varchar)
  OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_stanz_effettivo_up_anno_comp (id_in integer, id_comp integer, anno_comp_in varchar) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_stanz_effettivo_up_anno_comp (id_in integer, id_comp integer, anno_comp_in varchar) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_stanz_effettivo_up_anno_comp (id_in integer, id_comp integer, anno_comp_in varchar) TO siac;
--end fnc_siac_stanz_effettivo_up_anno_comp

--Start fnc_siac_disponibilitavariareugcomp_anno1
DROP FUNCTION if exists fnc_siac_disponibilitavariareugcomp_anno1(integer, integer);
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitavariareugcomp_anno1 (
  id_in integer,
  id_comp integer
)
    RETURNS numeric
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS $BODY$
DECLARE

/*Constants*/
CAP_UG_TIPO constant varchar:='CAP-UG';

/*Variables*/
dispVariare   numeric:=0;
annoBilancio  varchar:=null;
tipoCapitolo  varchar:=null;
stanzEffettivoRec record;
diCuiImpegnatoRec record;

strMessaggio varchar(1500):=null;
BEGIN

	strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
	' - Id componente='||id_comp||'.';

	strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
    			  '.Lettura anno di bilancio e tipo elemento bilancio.';

	/*Calcolo annoBilancio e TipoCapitolo*/
	select per.anno, tipo.elem_tipo_code into strict annoBilancio, tipoCapitolo
	from siac_t_bil_elem bilElem,siac_d_bil_elem_tipo tipo,
         siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in
    and   bilElem.data_cancellazione is null and bilElem.validita_fine is null
    and   tipo.elem_tipo_id=bilElem.elem_tipo_id
    and   bil.bil_id=bilElem.bil_id
    and   per.periodo_id=bil.periodo_id;

	case
      when tipoCapitolo=CAP_UG_TIPO then
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UG_TIPO||
					  'Id componente='||id_comp||
    				  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';

		select * into stanzEffettivoRec
		from fnc_siac_stanz_effettivo_ug_anno_comp (id_in, annoBilancio, id_comp);


		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UG_TIPO||
    	              '.Calcolo impegnato per anno='||annobilancio||'.';

		select * into diCuiImpegnatoRec
    	from fnc_siac_dicuiimpegnatoug_comp_anno_comp(id_in, annoBilancio, id_comp, false); --7349 Nel caso di disp var passo il parametro a false per non restituire le modifiche in negativo

        dispVariare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;

    end case;


return dispVariare;

exception
   when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return -1;
   when too_many_rows then
    	RAISE EXCEPTION '% Diversi records presenti in archivio.',strMessaggio;
        return -1;
    when no_data_found then
			RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return -1;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return -1;
END;
$BODY$;


ALTER FUNCTION siac.fnc_siac_disponibilitavariareugcomp_anno1 (id_in integer, id_comp integer)
  OWNER TO siac;
--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariareugcomp_anno1 (id_in integer, id_comp integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariareugcomp_anno1 (id_in integer, id_comp integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariareugcomp_anno1 (id_in integer, id_comp integer) TO siac;
--end fnc_siac_disponibilitavariareugcomp_anno1

--Start fnc_siac_disponibilitavariareugcomp_anno2
DROP FUNCTION if exists fnc_siac_disponibilitavariareugcomp_anno2(integer, integer);
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitavariareugcomp_anno2 (
  id_in integer,
  id_comp integer
)
    RETURNS numeric
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS $BODY$
DECLARE

/*Constants*/
CAP_UG_TIPO constant varchar:='CAP-UG';

/*Variables*/
dispVariare   numeric:=0;
annoBilancio  varchar:=null;
tipoCapitolo  varchar:=null;
stanzEffettivoRec record;
diCuiImpegnatoRec record;

strMessaggio varchar(1500):=null;
BEGIN

	strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
	' - Id componente='||id_comp||'.';

	strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
    			  '.Lettura anno di bilancio e tipo elemento bilancio.';

	/*Calcolo annoBilancio e TipoCapitolo*/
	select per.anno, tipo.elem_tipo_code into strict annoBilancio, tipoCapitolo
	from siac_t_bil_elem bilElem,siac_d_bil_elem_tipo tipo,
         siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in
    and   bilElem.data_cancellazione is null and bilElem.validita_fine is null
    and   tipo.elem_tipo_id=bilElem.elem_tipo_id
    and   bil.bil_id=bilElem.bil_id
    and   per.periodo_id=bil.periodo_id;

	case
      when tipoCapitolo=CAP_UG_TIPO then
	  	/*Incremento anno di bilancio +1 - riferito all'anno 2*/
	  	annoBilancio:=((annoBilancio::INTEGER)+1)::varchar;

		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UG_TIPO||
					  'Id componente='||id_comp||
    				  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
	    select * into stanzEffettivoRec
		from fnc_siac_stanz_effettivo_ug_anno_comp (id_in, annoBilancio, id_comp);

		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UG_TIPO||
    	              '.Calcolo impegnato per anno='||annobilancio||'.';
	    select * into diCuiImpegnatoRec
    	from fnc_siac_dicuiimpegnatoug_comp_anno_comp(id_in, annoBilancio, id_comp, false); --7349 Nel caso di disp var passo il parametro a false per non restituire le modifiche in negativo

        dispVariare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;

    end case;


return dispVariare;

exception
   when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return -1;
   when too_many_rows then
    	RAISE EXCEPTION '% Diversi records presenti in archivio.',strMessaggio;
        return -1;
    when no_data_found then
			RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return -1;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return -1;
END;
$BODY$;


ALTER FUNCTION siac.fnc_siac_disponibilitavariareugcomp_anno2 (id_in integer, id_comp integer)
  OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariareugcomp_anno2 (id_in integer, id_comp integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariareugcomp_anno2 (id_in integer, id_comp integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariareugcomp_anno2 (id_in integer, id_comp integer) TO siac;
--end fnc_siac_disponibilitavariareugcomp_anno2

--Start fnc_siac_disponibilitavariareugcomp_anno3
DROP FUNCTION if exists fnc_siac_disponibilitavariareugcomp_anno3(integer, integer);
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitavariareugcomp_anno3 (
  id_in integer,
  id_comp integer
)
    RETURNS numeric
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS $BODY$
DECLARE


/*Constants*/
CAP_UG_TIPO constant varchar:='CAP-UG';


/*Variables*/
dispVariare   numeric:=0;
annoBilancio  varchar:=null;
tipoCapitolo  varchar:=null;
stanzEffettivoRec record;
diCuiImpegnatoRec record;

strMessaggio varchar(1500):=null;
BEGIN

	strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
	' - Id componente='||id_comp||'.';

	strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
    			  '.Lettura anno di bilancio e tipo elemento bilancio.';

	/*Calcolo annoBilancio e TipoCapitolo*/
	select per.anno, tipo.elem_tipo_code into strict annoBilancio, tipoCapitolo
	from siac_t_bil_elem bilElem,siac_d_bil_elem_tipo tipo,
         siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in
    and   bilElem.data_cancellazione is null and bilElem.validita_fine is null
    and   tipo.elem_tipo_id=bilElem.elem_tipo_id
    and   bil.bil_id=bilElem.bil_id
    and   per.periodo_id=bil.periodo_id;

	case
      when tipoCapitolo=CAP_UG_TIPO then

		  annoBilancio:=((annoBilancio::INTEGER)+2)::varchar; /*Anno + 2*/

		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
    		          'Tipo elemento di bilancio='||CAP_UG_TIPO||
					  'Id componente='||id_comp||
    				  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
		select * into stanzEffettivoRec
		from fnc_siac_stanz_effettivo_ug_anno_comp (id_in, annoBilancio, id_comp);
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
    		          'Tipo elemento di bilancio='||CAP_UG_TIPO||
    	              '.Calcolo impegnato per anno='||annobilancio||'.';
		select * into diCuiImpegnatoRec
    	from fnc_siac_dicuiimpegnatoug_comp_anno_comp(id_in, annoBilancio, id_comp, false); --7349 Nel caso di disp var passo il parametro a false per non restituire le modifiche in negativo
    	dispVariare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;

    end case;


return dispVariare;

exception
   when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return -1;
   when too_many_rows then
    	RAISE EXCEPTION '% Diversi records presenti in archivio.',strMessaggio;
        return -1;
    when no_data_found then
			RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return -1;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return -1;
END;
$BODY$;


ALTER FUNCTION siac.fnc_siac_disponibilitavariareugcomp_anno3 (id_in integer, id_comp integer)
  OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariareugcomp_anno3 (id_in integer, id_comp integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariareugcomp_anno3 (id_in integer, id_comp integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariareugcomp_anno3 (id_in integer, id_comp integer) TO siac;
--end fnc_siac_disponibilitavariareugcomp_anno3


--Start fnc_siac_impegnatodefinitivoug_comp
CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatodefinitivoug_comp (
  id_in integer,
  idcomp_in integer
)
RETURNS TABLE (
  indiceannualita integer,
  elemdetcompid integer,
  impegnatodefinitivo numeric
) AS
$body$
DECLARE


annoBilancio varchar:=null;
annoEsercizio varchar:=null;
annoMovimento varchar:=null;

elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;
NVL_STR     constant varchar:='';
faseOpCode varchar(20):=NVL_STR;
bilancioId integer:=0;
elemTipoCode VARCHAR(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;
enteProprietarioId INTEGER:=0;
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
FASE_OP_BIL_PREV constant VARCHAR:='P';
STATO_A     constant varchar:='A';
STATO_P     constant varchar:='P';
TIPO_IMP    constant varchar:='I';
movGestStatoIdAnnullato integer:=0;
movGestStatoIdProvvisorio integer:=0;
movGestTipoId integer:=0;
IMPORTO_ATT constant varchar:='A';
movGestTsDetTipoId integer:=0;
IMPORTO_INIZIALE constant varchar:='I';
movGestTsDetTipoIdIniziale integer:=0;
STATO_MOD_V  constant varchar:='V';
modStatoVId integer:=0;
attoAmmStatoPId integer:=0;
STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoCurAttuale numeric:=0;
esisteRmovgestidelemid INTEGER:=0;
importoModifDelta  numeric:=0;
importoModifINS numeric:=0; --aggiunta per ECONB

flagNMaggioreNPiu2 integer:=0;
flagDeltaPagamenti integer:=0;
importoImpegnato numeric:=0;
importoPagatoDelta numeric:=0;
ordStatoAId          integer:=null;
ordTsDetTipoAId      integer:=null;
-- stati ordinativi
STATO_ORD_A    constant varchar:='A'; -- ANNULLATO
-- importoAttuale ordinativi
ORD_TS_DET_TIPO_A  constant varchar:='A';

strMessaggio varchar(1500):=null;
BEGIN
-- CALCOLO IMPEGNATO DEFINITIVO 
-- IN TUTTI I CASI:
-- I valori di impegnato dovranno essere calcolati tenendo conto del solo impegnato definitivo.
-- Escluse dal calcolo quindi:
--		- le modifiche di impegno provvisorie (modifiche con provvedimento in stato provvisorio - di qualsiasi segno
-- 		- gli  impegni in stato provvisorio

    strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in|| 'idcomp_in='||idcomp_in|| '.';

	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;
	if idcomp_in is null or idcomp_in=0 then
		 RAISE EXCEPTION '% Identificativo componente mancante.',strMessaggio;
	end if;
 
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
    			  '.Lettura anno di bilancio del capitolo UG.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;
		  

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
    			  '. Determina capitolo dati del capitolo di gestione in anno esercizio calcolato' || 
				   '. Calcolo bilancioId e elem_tipo_code.';
	 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
	 into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
	 from 	siac_t_bil_elem bilElem, 
	 		siac_d_bil_elem_tipo tipoBilElem,
		  	siac_t_bil bil, siac_t_periodo per
	 where bilElem.elem_id=id_in
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
	   and bil.bil_id=bilElem.bil_id
	   and per.periodo_id=bil.periodo_id;

	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UG then
			RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
	 end if;

	 strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				   'Calcolo fase operativa per bilancioId='||bilancioId
				   ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select  faseOp.fase_operativa_code into  faseOpCode
	 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
	 where bilFase.bil_id =bilancioId
	   and bilfase.data_cancellazione is null
	   and bilFase.validita_fine is null
	   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
	   and faseOp.data_cancellazione is null
	 order by bilFase.bil_fase_operativa_id desc;

	 if NOT FOUND THEN
	   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
	 end if;

	 strMessaggio:='Calcolo impegnato definitivo elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO'
				  ||'. Calcolo movGestTsStatoIdProvvisorio per movgest_stato_code=PROVVISORIO';

	 select movGestStato.movgest_stato_id into strict movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;

	 select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_P; 
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo movGestTsDetTipoId per movgest_ts_det_tipo_code=IMPORTO ATTUALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE;
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
              ||'. Calcolo modStatoVId per mod_stato_code=VALIDO.';
	 select d.mod_stato_id into strict modStatoVId
	 from siac_d_modifica_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.mod_stato_code=STATO_MOD_V;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	 select d.attoamm_stato_id into strict attoAmmStatoPId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_P;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINITIVO';
	 select d.attoamm_stato_id into strict attoAmmStatoDId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_D;

 
--- CICLO SU TUTTE LE POSSIBILI ANNUALITA': N-1, N, N+1, N+2 e >N+2
FOR loop_counter IN  0..6  LOOP
CASE loop_counter

 WHEN 0 THEN
	-- Calcolo Impegnato definitivo - Anno N-1: 
	-- Sommatoria di tutti gli Impegni assunti sul capitolo di previsione id_in su Componente idcomp_in
	-- con anno movimento N-1 e anno esercizio N-1.
	-- I valori di impegnato dovranno essere calcolati tenendo conto del solo impegnato definitivo.
	-- Escluse dal calcolo quindi:
	--		- le modifiche di impegno provvisorie (modifiche con provvedimento in stato provvisorio - di qualsiasi segno)
	-- 		- gli  impegni in stato provvisorio

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
    			  '.Determina anno esercizio ed anno movimento per i quali calcolare.';
    annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
    annoMovimento:=((annoBilancio::INTEGER)-1)::varchar;
	flagNMaggioreNPiu2:=0;
	
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				   '. Calcolo bilancioId per annoEsercizio='||annoEsercizio
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
         -- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- verifica esistenza capitolo ed assegna a  elemIdGestEq
	 strMessaggio:='Calcolo impegnato competenza UG.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;


	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else

		strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento|| 
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid 
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno=annoMovimento::integer
			and el.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
			;
		
		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;
		
		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

			importoCurAttuale:=0;			
			select tb.importo into importoCurAttuale
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
				  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  -- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  -- and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno = annoMovimento::integer -- anno dell impegno = annoMovimento
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;		

			-- 02.02.2016 Sofia JIRA 2947
			 if importoCurAttuale is null then importoCurAttuale:=0; end if;

			 -- 16.03.2017 Sofia JIRA-SIAC-4614
			-- if importoCurAttuale>0 then
			 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

				strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Calcolo totale modifiche su atti provvisori per annoMovimento='||annoMovimento||'.';

				select tb.importo into importoModifDelta
				 from
				 (
					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, 
					 	 siac_t_movgest mov,
					 	 siac_t_movgest_ts ts,
						 siac_r_movgest_ts_stato rstato,
					  	 siac_t_movgest_ts_det tsdet,
						 siac_t_movgest_ts_det_mod moddet,
						 siac_t_modifica mod, 
					 	 siac_r_modifica_stato rmodstato,
						 siac_r_atto_amm_stato attostato, 
					 	 siac_t_atto_amm atto,
						 siac_d_modifica_tipo tipom
					where 
						rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
						and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
						and	  mov.movgest_id=rbil.movgest_id
						and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
						and   mov.movgest_anno=annoMovimento::integer -- anno dell impegno = annoMovimento
						and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
						and   ts.movgest_id=mov.movgest_id
						and   rstato.movgest_ts_id=ts.movgest_ts_id
						and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
						-- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
						-- and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
					    and   tsdet.movgest_ts_id=ts.movgest_ts_id
						and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
						and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
						and   tipom.mod_tipo_id=mod.mod_tipo_id
						and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
						-- date
						and rbil.data_cancellazione is null
						and rbil.validita_fine is null
						and mov.data_cancellazione is null
						and mov.validita_fine is null
						and ts.data_cancellazione is null
						and ts.validita_fine is null
						and rstato.data_cancellazione is null
						and rstato.validita_fine is null
						and tsdet.data_cancellazione is null
						and tsdet.validita_fine is null
						and moddet.data_cancellazione is null
						and moddet.validita_fine is null
						and mod.data_cancellazione is null
						and mod.validita_fine is null
						and rmodstato.data_cancellazione is null
						and rmodstato.validita_fine is null
						and attostato.data_cancellazione is null
						and attostato.validita_fine is null
						and atto.data_cancellazione is null
						and atto.validita_fine is null
						group by ts.movgest_ts_tipo_id
					  ) tb, siac_d_movgest_ts_tipo tipo
					  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
					  order by tipo.movgest_ts_tipo_code desc
					  limit 1;		
					  
 				if importoModifDelta is null then importoModifDelta:=0; end if;
				 /*Aggiunta delle modifiche ECONB*/
				 -- anna_economie inizio
   				select tb.importo into importoModifINS
 				from
 				(
 					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
 			   	 	siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
				    siac_t_movgest_ts_det_mod moddet,
 			   	 	siac_t_modifica mod, siac_r_modifica_stato rmodstato,
				    siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
 			        siac_d_modifica_tipo tipom
				where rbil.elem_id=elemIdGestEq
				and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
				and	  mov.movgest_id=rbil.movgest_id
				and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
 			   	and   mov.movgest_anno=annoMovimento::integer
 			   	and   mov.bil_id=bilancioId
				and   ts.movgest_id=mov.movgest_id
				and   rstato.movgest_ts_id=ts.movgest_ts_id
				and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- impegno non annullato
				and   tsdet.movgest_ts_id=ts.movgest_ts_id
				and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
				and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
				and   moddet.movgest_ts_det_importo<0 -- importo negativo
				and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
				and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
				and   mod.mod_id=rmodstato.mod_id
				and   atto.attoamm_id=mod.attoamm_id
				and   attostato.attoamm_id=atto.attoamm_id
				and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
 			   and   tipom.mod_tipo_id=mod.mod_tipo_id
 			   and   tipom.mod_tipo_code = 'ECONB'
				-- date
				and rbil.data_cancellazione is null
				and rbil.validita_fine is null
				and mov.data_cancellazione is null
				and mov.validita_fine is null
				and ts.data_cancellazione is null
				and ts.validita_fine is null
				and rstato.data_cancellazione is null
				and rstato.validita_fine is null
				and tsdet.data_cancellazione is null
				and tsdet.validita_fine is null
				and moddet.data_cancellazione is null
				and moddet.validita_fine is null
				and mod.data_cancellazione is null
				and mod.validita_fine is null
				and rmodstato.data_cancellazione is null
				and rmodstato.validita_fine is null
				and attostato.data_cancellazione is null
				and attostato.validita_fine is null
				and atto.data_cancellazione is null
				and atto.validita_fine is null
 			   group by ts.movgest_ts_tipo_id
 			 ) tb, siac_d_movgest_ts_tipo tipo
 			 where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
 			 order by tipo.movgest_ts_tipo_code desc
 			 limit 1;
			 
			 if importoModifINS is null then 
			 	importoModifINS = 0;
			 end if;

		
			end if;		
		end if;
	end if;

	
	-- restituisco il record risultato
	
	--FIX Adeguamento 7349 MR
	-- Non dobbiamo piu' restituire al impegnato le modifiche provvisorie e le ECONB
	importoModifDelta:=0;
	importoModifINS:=0;
	--
	
	indiceAnnualita:=loop_counter;
	elemDetCompId:=idcomp_in;
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente per l'anno N-1
	impegnatoDefinitivo:=impegnatoDefinitivo+importoCurAttuale-(importoModifDelta);

	--aggiunta per ECONB
	impegnatoDefinitivo:=impegnatoDefinitivo+abs(importoModifINS);

	return next;

	
	
 WHEN 1,2,3 THEN
 	-- Calcolo Impegnato definitivo - Anno N: 
	-- - Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in e anno movimento N e anno esercizio N

	-- Calcolo Impegnato definitivo - Anno N+1: 
	-- - Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in e anno movimento N+1 e anno esercizio N

	-- Calcolo Impegnato definitivo - Anno N+2: 
	-- - Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in e anno movimento N+2 e anno esercizio N
	
	-- I valori di impegnato dovranno essere calcolati tenendo conto del solo impegnato definitivo.
	-- Escluse dal calcolo quindi:
	--		- le modifiche di impegno provvisorie (modifiche con provvedimento in stato provvisorio - di qualsiasi segno)
	-- 		- gli  impegni in stato provvisorio

	importoCurAttuale:=0;	
	importoModifDelta:=0;
	importoModifINS:=0;

				
	--	ImpegnatoDefinitivo = 	Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in 
	--			e anno movimento [N | N+1 | N+2] e anno esercizio N

	annoEsercizio:=annoBilancio;
	annoMovimento:=((annoBilancio::INTEGER)+loop_counter-1)::varchar;
	flagNMaggioreNPiu2:=0;
	
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per e per annoEsercizio='||annoEsercizio
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    	-- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo impegnato competenza UG.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else

		strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento|| 
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid 
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno=annoMovimento::integer
			and el.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
			;
		
		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;
		
		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

					
			select tb.importo into importoCurAttuale
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
				  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  -- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  -- and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno = annoMovimento::integer -- anno dell impegno = annoMovimento
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;		

			-- 02.02.2016 Sofia JIRA 2947
			 if importoCurAttuale is null then importoCurAttuale:=0; end if;

			 -- 16.03.2017 Sofia JIRA-SIAC-4614
			-- if importoCurAttuale>0 then
			 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

				strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Calcolo totale modifiche su atti provvisori per annoMovimento='||annoMovimento||'.';

				select tb.importo into importoModifDelta
				 from
				 (
					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, 
					 	 siac_t_movgest mov,
					 	 siac_t_movgest_ts ts,
						 siac_r_movgest_ts_stato rstato,
					  	 siac_t_movgest_ts_det tsdet,
						 siac_t_movgest_ts_det_mod moddet,
						 siac_t_modifica mod, 
					 	 siac_r_modifica_stato rmodstato,
						 siac_r_atto_amm_stato attostato, 
					 	 siac_t_atto_amm atto,
						 siac_d_modifica_tipo tipom
					where 
						rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
						and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
						and	  mov.movgest_id=rbil.movgest_id
						and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
						and   mov.movgest_anno=annoMovimento::integer -- anno dell impegno = annoMovimento
						and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
						and   ts.movgest_id=mov.movgest_id
						and   rstato.movgest_ts_id=ts.movgest_ts_id
						and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
						-- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  		-- and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
					    and   tsdet.movgest_ts_id=ts.movgest_ts_id
						and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
						and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
						and   tipom.mod_tipo_id=mod.mod_tipo_id
						and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
						-- date
						and rbil.data_cancellazione is null
						and rbil.validita_fine is null
						and mov.data_cancellazione is null
						and mov.validita_fine is null
						and ts.data_cancellazione is null
						and ts.validita_fine is null
						and rstato.data_cancellazione is null
						and rstato.validita_fine is null
						and tsdet.data_cancellazione is null
						and tsdet.validita_fine is null
						and moddet.data_cancellazione is null
						and moddet.validita_fine is null
						and mod.data_cancellazione is null
						and mod.validita_fine is null
						and rmodstato.data_cancellazione is null
						and rmodstato.validita_fine is null
						and attostato.data_cancellazione is null
						and attostato.validita_fine is null
						and atto.data_cancellazione is null
						and atto.validita_fine is null
						group by ts.movgest_ts_tipo_id
					  ) tb, siac_d_movgest_ts_tipo tipo
					  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
					  order by tipo.movgest_ts_tipo_code desc
					  limit 1;		
					  
 				if importoModifDelta is null then importoModifDelta:=0; end if;
				  /*Aggiunta delle modifiche ECONB*/
				 -- anna_economie inizio
   				select tb.importo into importoModifINS
 				from
 				(
 					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
 			   	 	siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
				    siac_t_movgest_ts_det_mod moddet,
 			   	 	siac_t_modifica mod, siac_r_modifica_stato rmodstato,
				    siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
 			        siac_d_modifica_tipo tipom
				where rbil.elem_id=elemIdGestEq
				and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
				and	  mov.movgest_id=rbil.movgest_id
				and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
 			   	and   mov.movgest_anno=annoMovimento::integer
 			   	and   mov.bil_id=bilancioId
				and   ts.movgest_id=mov.movgest_id
				and   rstato.movgest_ts_id=ts.movgest_ts_id
				and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- impegno non annullato
				and   tsdet.movgest_ts_id=ts.movgest_ts_id
				and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
				and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
				and   moddet.movgest_ts_det_importo<0 -- importo negativo
				and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
				and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
				and   mod.mod_id=rmodstato.mod_id
				and   atto.attoamm_id=mod.attoamm_id
				and   attostato.attoamm_id=atto.attoamm_id
				and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
 			   and   tipom.mod_tipo_id=mod.mod_tipo_id
 			   and   tipom.mod_tipo_code = 'ECONB'
				-- date
				and rbil.data_cancellazione is null
				and rbil.validita_fine is null
				and mov.data_cancellazione is null
				and mov.validita_fine is null
				and ts.data_cancellazione is null
				and ts.validita_fine is null
				and rstato.data_cancellazione is null
				and rstato.validita_fine is null
				and tsdet.data_cancellazione is null
				and tsdet.validita_fine is null
				and moddet.data_cancellazione is null
				and moddet.validita_fine is null
				and mod.data_cancellazione is null
				and mod.validita_fine is null
				and rmodstato.data_cancellazione is null
				and rmodstato.validita_fine is null
				and attostato.data_cancellazione is null
				and attostato.validita_fine is null
				and atto.data_cancellazione is null
				and atto.validita_fine is null
 			   group by ts.movgest_ts_tipo_id
 			 ) tb, siac_d_movgest_ts_tipo tipo
 			 where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
 			 order by tipo.movgest_ts_tipo_code desc
 			 limit 1;
			 
			 if importoModifINS is null then 
			 	importoModifINS = 0;
			 end if;

		
			end if;		
		end if;
	end if;
	
	--FIX Adeguamento 7349 MR
	-- Non dobbiamo piu' restituire al impegnato le modifiche provvisorie e le ECONB
	importoModifDelta:=0;
	importoModifINS:=0;
	--
	
	indiceAnnualita:=loop_counter;
	elemDetCompId:=idcomp_in;
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente per l'anno N-1
	impegnatoDefinitivo:=impegnatoDefinitivo+importoCurAttuale-(importoModifDelta);
	--aggiunta per ECONB
	impegnatoDefinitivo:=impegnatoDefinitivo+abs(importoModifINS);
	
	return next;

 	
 WHEN 4 THEN
 	-- Calcolo Impegnato definitivo - Anno > N+2:
 	-- - Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in e anno movimento > N+2 e anno esercizio N
	-- I valori di impegnato dovranno essere calcolati tenendo conto del solo impegnato definitivo.
	-- Escluse dal calcolo quindi:
	--		- le modifiche di impegno provvisorie (modifiche con provvedimento in stato provvisorio - di qualsiasi segno)
	-- 		- gli  impegni in stato provvisorio

	importoCurAttuale:=0;	
	importoModifDelta:=0;
	importoModifINS := 0;
	
				
 	--	ImpegnatoDefinitivo = Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in 
	--	e anno movimento > N+2 e anno esercizio N

	annoEsercizio:=annoBilancio;
	annoMovimento:=((annoBilancio::INTEGER)+2)::varchar;
	flagNMaggioreNPiu2:=1;

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per annoEsercizio='||annoEsercizio
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    -- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo impegnato competenza UG.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else

		strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento|| 
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid 
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno>annoMovimento::integer 
			and el.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
			;
		
		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;
		
		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

			importoCurAttuale:=0;			
			select tb.importo into importoCurAttuale
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
				  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  -- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  -- and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno > annoMovimento::integer -- anno dell impegno > annoMovimento 
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;		

			-- 02.02.2016 Sofia JIRA 2947
			 if importoCurAttuale is null then importoCurAttuale:=0; end if;

			 -- 16.03.2017 Sofia JIRA-SIAC-4614
			-- if importoCurAttuale>0 then
			 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

				strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Calcolo totale modifiche su atti provvisori per annoMovimento='||annoMovimento||'.';

				select tb.importo into importoModifDelta
				 from
				 (
					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, 
					 	 siac_t_movgest mov,
					 	 siac_t_movgest_ts ts,
						 siac_r_movgest_ts_stato rstato,
					  	 siac_t_movgest_ts_det tsdet,
						 siac_t_movgest_ts_det_mod moddet,
						 siac_t_modifica mod, 
					 	 siac_r_modifica_stato rmodstato,
						 siac_r_atto_amm_stato attostato, 
					 	 siac_t_atto_amm atto,
						 siac_d_modifica_tipo tipom
					where 
						rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
						and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
						and	  mov.movgest_id=rbil.movgest_id
						and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
						and   mov.movgest_anno>annoMovimento::integer -- anno dell impegno = annoMovimento 
						and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
						and   ts.movgest_id=mov.movgest_id
						and   rstato.movgest_ts_id=ts.movgest_ts_id
						and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
						-- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				        -- and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
					    and   tsdet.movgest_ts_id=ts.movgest_ts_id
						and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
						and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
						and   tipom.mod_tipo_id=mod.mod_tipo_id
						and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
						-- date
						and rbil.data_cancellazione is null
						and rbil.validita_fine is null
						and mov.data_cancellazione is null
						and mov.validita_fine is null
						and ts.data_cancellazione is null
						and ts.validita_fine is null
						and rstato.data_cancellazione is null
						and rstato.validita_fine is null
						and tsdet.data_cancellazione is null
						and tsdet.validita_fine is null
						and moddet.data_cancellazione is null
						and moddet.validita_fine is null
						and mod.data_cancellazione is null
						and mod.validita_fine is null
						and rmodstato.data_cancellazione is null
						and rmodstato.validita_fine is null
						and attostato.data_cancellazione is null
						and attostato.validita_fine is null
						and atto.data_cancellazione is null
						and atto.validita_fine is null
						group by ts.movgest_ts_tipo_id
					  ) tb, siac_d_movgest_ts_tipo tipo
					  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
					  order by tipo.movgest_ts_tipo_code desc
					  limit 1;		
					  
 				if importoModifDelta is null then importoModifDelta:=0; end if;
				  /*Aggiunta delle modifiche ECONB*/
				 -- anna_economie inizio
   				select tb.importo into importoModifINS
 				from
 				(
 					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
 			   	 	siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
				    siac_t_movgest_ts_det_mod moddet,
 			   	 	siac_t_modifica mod, siac_r_modifica_stato rmodstato,
				    siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
 			        siac_d_modifica_tipo tipom
				where rbil.elem_id=elemIdGestEq
				and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
				and	  mov.movgest_id=rbil.movgest_id
				and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
 			   	and   mov.movgest_anno=annoMovimento::integer
 			   	and   mov.bil_id=bilancioId
				and   ts.movgest_id=mov.movgest_id
				and   rstato.movgest_ts_id=ts.movgest_ts_id
				and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- impegno non annullato
				and   tsdet.movgest_ts_id=ts.movgest_ts_id
				and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
				and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
				and   moddet.movgest_ts_det_importo<0 -- importo negativo
				and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
				and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
				and   mod.mod_id=rmodstato.mod_id
				and   atto.attoamm_id=mod.attoamm_id
				and   attostato.attoamm_id=atto.attoamm_id
				and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
 			   and   tipom.mod_tipo_id=mod.mod_tipo_id
 			   and   tipom.mod_tipo_code = 'ECONB'
				-- date
				and rbil.data_cancellazione is null
				and rbil.validita_fine is null
				and mov.data_cancellazione is null
				and mov.validita_fine is null
				and ts.data_cancellazione is null
				and ts.validita_fine is null
				and rstato.data_cancellazione is null
				and rstato.validita_fine is null
				and tsdet.data_cancellazione is null
				and tsdet.validita_fine is null
				and moddet.data_cancellazione is null
				and moddet.validita_fine is null
				and mod.data_cancellazione is null
				and mod.validita_fine is null
				and rmodstato.data_cancellazione is null
				and rmodstato.validita_fine is null
				and attostato.data_cancellazione is null
				and attostato.validita_fine is null
				and atto.data_cancellazione is null
				and atto.validita_fine is null
 			   group by ts.movgest_ts_tipo_id
 			 ) tb, siac_d_movgest_ts_tipo tipo
 			 where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
 			 order by tipo.movgest_ts_tipo_code desc
 			 limit 1;
			 
			 if importoModifINS is null then 
			 	importoModifINS = 0;
			 end if;

		
			end if;		
		end if;
	end if;
	
	--FIX Adeguamento 7349 MR
	-- Non dobbiamo piu' restituire al impegnato le modifiche provvisorie e le ECONB
	importoModifDelta:=0;
	importoModifINS:=0;
	--
	
	
	indiceAnnualita:=loop_counter;
	elemDetCompId:=idcomp_in;
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente per l'anno N-1
	impegnatoDefinitivo:=impegnatoDefinitivo+importoCurAttuale-(importoModifDelta);
	--aggiunta per ECONB
	impegnatoDefinitivo:=impegnatoDefinitivo+abs(importoModifINS);
	return next;

 WHEN 5 THEN
	-- Calcolo Residuo Iniziale: 
	--	 Sommatoria dell'importo iniziale di tutti gli Impegni assunti sul capitolo in questione su idcomp_in
	--	con anno movimento < N e anno esercizio N.

	importoImpegnato:=0;	
	importoPagatoDelta:=0;
	
 
	--		Residuo Iniziale = 
	--	 		Sommatoria dell'importo iniziale di tutti gli Impegni assunti sul capitolo in questione su idcomp_in
	--			con anno movimento < N e anno esercizio N.

	annoEsercizio:=annoBilancio;
	annoMovimento:=annoBilancio;
	flagDeltaPagamenti:=0; -- non e' necessario scomputare il pagato
		
 	

	strMessaggio:='Calcolo residuo iniziale elem_id='||id_in||'idcomp_in='||idcomp_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per annoEsercizio='||annoEsercizio
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    -- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo residuo iniziale.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else

		strMessaggio:='Calcolo residuo iniziale elem_id='||id_in||'idcomp_in='||idcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento||'.'; 

		impegnatoDefinitivo:=0;
		strMessaggio:='Calcolo residuo iniziale elem_id='||id_in||'idcomp_in='||idcomp_in||
			'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
			'. Inizio calcolo totale importo  impegni per annoMovimento='||annoMovimento||'.';


		importoImpegnato:=0;			
		select tb.importo into importoImpegnato
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
				  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  -- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  -- and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno < annoMovimento::integer -- anno dell impegno < annoMovimento 
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoIdIniziale -- considerare l'importo iniziale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;		
			-- 02.02.2016 Sofia JIRA 2947
			if importoImpegnato is null then importoImpegnato:=0; end if;

	end if;

	indiceAnnualita:=loop_counter;
	elemDetCompId:=idcomp_in;
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente per l'anno N-1
	if flagDeltaPagamenti != 0 then
		impegnatoDefinitivo:=impegnatoDefinitivo+importoImpegnato-(importoPagatoDelta);
	else 
		impegnatoDefinitivo:=impegnatoDefinitivo+importoImpegnato;
	end if;
	return next;

	

 WHEN 6 THEN
	-- Calcolo Residuo Finale (In presenza della colonna finale e in assenza di qualsiasi colonna):
	--		Sommatoria dell'importo attuale di tutti gli Impegni assunti sul capitolo in questione su idcomp_in 
	--		con anno movimento < N e anno esercizio N.
 
	importoImpegnato:=0;	
	importoPagatoDelta:=0;
	

	--		Residuo Finale = 
	--	 		Sommatoria dell'importo attuale di tutti gli Impegni assunti sul capitolo in questione su idcomp_in
	--			con anno movimento < N e anno esercizio N.

	annoEsercizio:=annoBilancio;
	annoMovimento:=annoBilancio;
	flagDeltaPagamenti:=0; -- non e' necessario scomputare il pagato
		

	strMessaggio:='Calcolo residuo finale elem_id='||id_in||'idcomp_in='||idcomp_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per annoEsercizio='||annoEsercizio
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    -- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo residuo finale.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else

		strMessaggio:='Calcolo residuo finale elem_id='||id_in||'idcomp_in='||idcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento||'.'; 

		impegnatoDefinitivo:=0;
		strMessaggio:='Calcolo residuo finale elem_id='||id_in||'idcomp_in='||idcomp_in||
			'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
			'. Inizio calcolo totale importo  impegni per annoMovimento='||annoMovimento||'.';

		importoImpegnato:=0;			
		select tb.importo into importoImpegnato
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
				  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  -- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  -- and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno < annoMovimento::integer -- anno dell impegno < annoMovimento 
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;		
			-- 02.02.2016 Sofia JIRA 2947
			if importoImpegnato is null then importoImpegnato:=0; end if;


	end if;

	indiceAnnualita:=loop_counter;
	elemDetCompId:=idcomp_in;
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente per l'anno N-1
	if flagDeltaPagamenti != 0 then
		impegnatoDefinitivo:=impegnatoDefinitivo+importoImpegnato-(importoPagatoDelta);
	else 
		impegnatoDefinitivo:=impegnatoDefinitivo+importoImpegnato;
	end if;
	return next;

END CASE;
END LOOP;

return;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
		return;
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
PARALLEL UNSAFE
COST 100 ROWS 1000;


ALTER FUNCTION siac.fnc_siac_impegnatodefinitivoug_comp (id_in integer, idcomp_in integer)
  OWNER TO siac;
 
--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatodefinitivoug_comp (id_in integer, idcomp_in integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatodefinitivoug_comp (id_in integer, idcomp_in integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatodefinitivoug_comp (id_in integer, idcomp_in integer) TO siac;

--End fnc_siac_impegnatodefinitivoug_comp
  
--Start fnc_siac_dicuiimpegnatoug_annisucc
/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoug_annisucc (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE
annoBilancio varchar:=null;
annoEsercizio varchar:=null;
annoMovimento varchar:=null;
impegnatoDefinitivo numeric:=0; 
elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;
NVL_STR     constant varchar:='';
faseOpCode varchar(20):=NVL_STR;
bilancioId integer:=0;
elemTipoCode VARCHAR(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;
enteProprietarioId INTEGER:=0;
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
FASE_OP_BIL_PREV constant VARCHAR:='P';
STATO_A     constant varchar:='A';
STATO_P     constant varchar:='P';
TIPO_IMP    constant varchar:='I';
movGestStatoIdAnnullato integer:=0;
movGestStatoIdProvvisorio integer:=0;
movGestTipoId integer:=0;
IMPORTO_ATT constant varchar:='A';
movGestTsDetTipoId integer:=0;
IMPORTO_INIZIALE constant varchar:='I';
movGestTsDetTipoIdIniziale integer:=0;
STATO_MOD_V  constant varchar:='V';
modStatoVId integer:=0;
attoAmmStatoPId integer:=0;
STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoCurAttuale numeric:=0;
esisteRmovgestidelemid INTEGER:=0;
importoModifDelta  numeric:=0;
impegniDaRibaltamento integer:=0;
pluriennaliDaRibaltamento integer:=0;
flagNMaggioreNPiu2 integer:=0;
importoImpegnato integer:=0;

strMessaggio varchar(1500):=null;
BEGIN

-- CALCOLO IMPEGNATO DEFINITIVO 
-- IN TUTTI I CASI:
-- Stiamo sempre parlando di impegnato sul capitolo di gestione equivalente	
-- I valori di impegnato dovranno essere calcolati tenendo conto del solo impegnato definitivo.
-- Escluse dal calcolo quindi:
--		- le modifiche di impegno provvisorie (modifiche con provvedimento in stato provvisorio - di qualsiasi segno
-- 		- gli  impegni in stato provvisorio

    strMessaggio:='Calcolo totale impegnato definitvo per anni successivi elem_id='||id_in||'.';

	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;
 
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'. Lettura anno di bilancio del capitolo UG.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;
		  

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'. Determina capitolo di gestione  in anno esercizio di calcolato. Calcolo bilancioId e elem_tipo_code.';
	 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
	 into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
	 from 	siac_t_bil_elem bilElem, 
	 		siac_d_bil_elem_tipo tipoBilElem,
		  	siac_t_bil bil, siac_t_periodo per
	 where bilElem.elem_id=id_in
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
	   and bil.bil_id=bilElem.bil_id
	   and per.periodo_id=bil.periodo_id;

	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UG then
			RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
	 end if;

	 strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'. Determina capitolo di gestione  in anno esercizio calcolato. Calcolo fase operativa per bilancioId='||bilancioId||' , per ente='||enteProprietarioId||' e per elem_id='||id_in||'.';

	 select  faseOp.fase_operativa_code into  faseOpCode
	 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
	 where bilFase.bil_id =bilancioId
	   and bilfase.data_cancellazione is null
	   and bilFase.validita_fine is null
	   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
	   and faseOp.data_cancellazione is null
	 order by bilFase.bil_fase_operativa_id desc;

	 if NOT FOUND THEN
	   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
	 end if;

	 strMessaggio:='Calcolo impegnato definitivo elem_id='||id_in||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||
				  '. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO'
				  '. Calcolo movGestTsStatoIdProvvisorio per movgest_stato_code=PROVVISORIO';

	 select movGestStato.movgest_stato_id into strict movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;

	 select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_P; 
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||
				  '. Calcolo movGestTsDetTipoId per movgest_ts_det_tipo_code=IMPORTO ATTUALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT; --'A'

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||
				  '. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE; --'I'
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||
              '. Calcolo modStatoVId per mod_stato_code=VALIDO.';
	 select d.mod_stato_id into strict modStatoVId
	 from siac_d_modifica_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.mod_stato_code=STATO_MOD_V;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||
				  '. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	 select d.attoamm_stato_id into strict attoAmmStatoPId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_P;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINITIVO';
	 select d.attoamm_stato_id into strict attoAmmStatoDId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_D;

 	-- Calcolo Impegnato definitivo - Anno > N+2:
	-- - Se presenti i movimenti gestione provenienti dal ribaltamento 
	--		Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in e anno movimento > N+2 e anno esercizio N
	-- - Se non presenti i movimenti gestione provenienti dal ribaltamento 
	-- 		Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in e anno movimento > N+2 e anno esercizio N-1
	-- I valori di impegnato dovranno essere calcolati tenendo conto del solo impegnato definitivo.
	-- Escluse dal calcolo quindi:
	--		- le modifiche di impegno provvisorie (modifiche con provvedimento in stato provvisorio - di qualsiasi segno)
	-- 		- gli  impegni in stato provvisorio

	-- Verifica se presenti i movimenti di gestione provenienti dal ribaltamento
	-- Per "ribaltamento" si intende  il batch di ribaltamento residui che gira prima del ROR 
	--		e che "copia" gli impegni dell'anno N-1 nel bilancio dell'anno N (di solito il 2 gennaio)
	-- Per verificare che il batch di ribaltamento sia stato eseguito controllo le seguenti tabelle
	-- 		fase_bil_t_gest_apertura_liq_imp per gli impegni residui
	--  	fase_bil_t_gest_apertura_pluri per i pluriennli (sia impegni che accertamenti)
	-- In entrambe c'e' sia il bil_id che il bil_id_orig ovvero l'anno nuovo su cui si stanno ribaltando i movimenti e l'anno prec
	-- c'e' anche un campo fl_elab che ti dice se i dati sono stati elaborati con scarto o con successo 
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||
				 '.Verifica se presenti i movimenti di gestione provenienti dal ribaltamento per anno di esercizio N.';
	
	impegniDaRibaltamento:=0;
	pluriennaliDaRibaltamento:=0;
	importoCurAttuale:=0;	
	importoModifDelta:=0;
	
	select  count(*) into impegniDaRibaltamento 
	from fase_bil_t_gest_apertura_liq_imp fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;

	select  count(*) into  pluriennaliDaRibaltamento
	from fase_bil_t_gest_apertura_pluri fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;
				
	if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then

	-- - Se presenti i movimenti gestione provenienti dal ribaltamento 
	--		ImpegnatoDefinitivo = Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in 
	--		e anno movimento > N+2 e anno esercizio N

		annoEsercizio:=annoBilancio;
		annoMovimento:=((annoBilancio::INTEGER)+2)::varchar;
		flagNMaggioreNPiu2:=1;
	else

		-- - Se non presenti i movimenti gestione provenienti dal ribaltamento 
		-- 	ImpegnatoDefinitivo = Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in 
		-- 	e anno movimento > N+2 e anno esercizio N-1

		annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
		annoMovimento:=((annoBilancio::INTEGER)+2)::varchar;
		flagNMaggioreNPiu2:=1;
	end if;

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'. Determina capitolo di gestione  in anno esercizio calcolato.'; 
				   --Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    -- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo impegnato competenza UG.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else

		strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento|| 
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid 
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno>annoMovimento::integer 
			--and el.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349, punto 21/04/2020
			;
		
		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;
		
		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

			importoCurAttuale:=0;			
			select tb.importo into importoCurAttuale
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq  -- UID del capitolo di gestione equivalente
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  -- SIAC-7737 GS 31/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  -- and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno > annoMovimento::integer -- anno dell impegno > annoMovimento 
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;		

			-- 02.02.2016 Sofia JIRA 2947
			 if importoCurAttuale is null then importoCurAttuale:=0; end if;

			 -- 16.03.2017 Sofia JIRA-SIAC-4614
			-- if importoCurAttuale>0 then
			 /*Adeguamento MR SIAC-7349 Sprint 5
			 Per il calcolo del impegnato non si tiene conto delle modifiche provvisorie
			 Queste devono essere restituite al impegno solo quando si calcola 
			 la disponibilita ad impegnare
			 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

				strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Calcolo totale modifiche su atti provvisori per annoMovimento='||annoMovimento||'.';

				select tb.importo into importoModifDelta
				 from
				 (
					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, 
					 	 siac_t_movgest mov,
					 	 siac_t_movgest_ts ts,
						 siac_r_movgest_ts_stato rstato,
					  	 siac_t_movgest_ts_det tsdet,
						 siac_t_movgest_ts_det_mod moddet,
						 siac_t_modifica mod, 
					 	 siac_r_modifica_stato rmodstato,
						 siac_r_atto_amm_stato attostato, 
					 	 siac_t_atto_amm atto,
						 siac_d_modifica_tipo tipom
					where 
						rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
						--and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349 in questo caso, non sulla componente
						and	  mov.movgest_id=rbil.movgest_id
						and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
						and   mov.movgest_anno>annoMovimento::integer -- anno dell impegno = annoMovimento 
						and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
						and   ts.movgest_id=mov.movgest_id
						and   rstato.movgest_ts_id=ts.movgest_ts_id
						and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
						and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
					    and   tsdet.movgest_ts_id=ts.movgest_ts_id
						and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
					 	and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
						and   tipom.mod_tipo_id=mod.mod_tipo_id
						-- and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
						-- date
						and rbil.data_cancellazione is null
						and rbil.validita_fine is null
						and mov.data_cancellazione is null
						and mov.validita_fine is null
						and ts.data_cancellazione is null
						and ts.validita_fine is null
						and rstato.data_cancellazione is null
						and rstato.validita_fine is null
						and tsdet.data_cancellazione is null
						and tsdet.validita_fine is null
						and moddet.data_cancellazione is null
						and moddet.validita_fine is null
						and mod.data_cancellazione is null
						and mod.validita_fine is null
						and rmodstato.data_cancellazione is null
						and rmodstato.validita_fine is null
						and attostato.data_cancellazione is null
						and attostato.validita_fine is null
						and atto.data_cancellazione is null
						and atto.validita_fine is null
						group by ts.movgest_ts_tipo_id
					  ) tb, siac_d_movgest_ts_tipo tipo
					  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
					  order by tipo.movgest_ts_tipo_code desc
					  limit 1;		
					  
 				if importoModifDelta is null then importoModifDelta:=0; end if;

		
			end if;	*/	
		end if;
	end if;
    --FIX Sprint5 7349
    importoModifDelta:=0;
    --
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente per l'anno N-1
	impegnatoDefinitivo:=impegnatoDefinitivo+importoCurAttuale-(importoModifDelta);
	
	return impegnatoDefinitivo;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return -1;
    when no_data_found then
	RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return -1;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return -1;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100;


ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoug_annisucc (id_in integer) OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoug_annisucc (id_in integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoug_annisucc (id_in integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoug_annisucc (id_in integer) TO siac;
  
--end fnc_siac_dicuiimpegnatoug_annisucc

--Start fnc_siac_dicuiimpegnatoug_annoprec
/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoug_annoprec (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE
annoBilancio varchar:=null;
annoEsercizio varchar:=null;
annoMovimento varchar:=null;
impegnatoDefinitivo numeric:=0; 
elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;
NVL_STR     constant varchar:='';
faseOpCode varchar(20):=NVL_STR;
bilancioId integer:=0;
elemTipoCode VARCHAR(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;
enteProprietarioId INTEGER:=0;
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
FASE_OP_BIL_PREV constant VARCHAR:='P';
STATO_A     constant varchar:='A';
STATO_P     constant varchar:='P';
TIPO_IMP    constant varchar:='I';
movGestStatoIdAnnullato integer:=0;
movGestStatoIdProvvisorio integer:=0;
movGestTipoId integer:=0;
IMPORTO_ATT constant varchar:='A';
movGestTsDetTipoId integer:=0;
IMPORTO_INIZIALE constant varchar:='I';
movGestTsDetTipoIdIniziale integer:=0;
STATO_MOD_V  constant varchar:='V';
modStatoVId integer:=0;
attoAmmStatoPId integer:=0;
STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoCurAttuale numeric:=0;
esisteRmovgestidelemid INTEGER:=0;
importoModifDelta  numeric:=0;
importoImpegnato integer:=0;

strMessaggio varchar(1500):=null;
BEGIN



    strMessaggio:='Calcolo totale impegnato per anni precedenti elem_id='||id_in||'.';

	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;
 
	strMessaggio:='Calcolo totale impegnato per anni precedenti elem_id='||id_in||'. Lettura anno di bilancio del capitolo UG.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;
		  

	strMessaggio:='Calcolo totale impegnato per anni precedenti elem_id='||id_in||'. Determina capitolo di gestione  in anno esercizio di calcolato. Calcolo bilancioId e elem_tipo_code.';
	 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
	 into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
	 from 	siac_t_bil_elem bilElem, 
	 		siac_d_bil_elem_tipo tipoBilElem,
		  	siac_t_bil bil, siac_t_periodo per
	 where bilElem.elem_id=id_in
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
	   and bil.bil_id=bilElem.bil_id
	   and per.periodo_id=bil.periodo_id;

	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UG then
			RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
	 end if;

	 strMessaggio:='Calcolo totale impegnato per anni precedenti elem_id='||id_in||'. Determina capitolo di gestione  in anno esercizio calcolato. Calcolo fase operativa per bilancioId='||bilancioId||' , per ente='||enteProprietarioId||' e per elem_id='||id_in||'.';

	 select  faseOp.fase_operativa_code into  faseOpCode
	 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
	 where bilFase.bil_id =bilancioId
	   and bilfase.data_cancellazione is null
	   and bilFase.validita_fine is null
	   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
	   and faseOp.data_cancellazione is null
	 order by bilFase.bil_fase_operativa_id desc;

	 if NOT FOUND THEN
	   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
	 end if;

	 strMessaggio:='Calcolo impegnato per anni precedenti elem_id='||id_in||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

	 strMessaggio:='Calcolo impegnato competenza anni precedenti elem_id='||id_in||
				  '. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO'
				  '. Calcolo movGestTsStatoIdProvvisorio per movgest_stato_code=PROVVISORIO';

	 select movGestStato.movgest_stato_id into strict movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;

	 select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_P; 
	 
	 strMessaggio:='Calcolo impegnato competenza anni precedenti elem_id='||id_in||
				  '. Calcolo movGestTsDetTipoId per movgest_ts_det_tipo_code=IMPORTO ATTUALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT; --'A'

	 strMessaggio:='Calcolo impegnato competenza anni precedenti elem_id='||id_in||
				  '. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE; --'I'
	 
	 strMessaggio:='Calcolo impegnato competenza anni precedenti elem_id='||id_in||
              '. Calcolo modStatoVId per mod_stato_code=VALIDO.';
	 select d.mod_stato_id into strict modStatoVId
	 from siac_d_modifica_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.mod_stato_code=STATO_MOD_V;

	 strMessaggio:='Calcolo impegnato competenza anni precedenti elem_id='||id_in||
				  '. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	 select d.attoamm_stato_id into strict attoAmmStatoPId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_P;

	 strMessaggio:='Calcolo impegnato competenza anni precedenti elem_id='||id_in||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINITIVO';
	 select d.attoamm_stato_id into strict attoAmmStatoDId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_D;
 

	importoCurAttuale:=0;	
	importoModifDelta:=0;
	annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
        annoMovimento:=((annoBilancio::INTEGER)-1)::varchar;


	strMessaggio:='Calcolo totale impegnato anni precedenti elem_id='||id_in||'. Determina capitolo di gestione  in anno esercizio calcolato.'; 
				   --Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    	-- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo impegnato anno precedente UG.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else

		strMessaggio:='Calcolo totale impegnato anno precedente elem_id='||id_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento|| 
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid 
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno=annoMovimento::integer 
			--and el.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349, punto 21/04/2020
			;
		
		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;
		
		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato anno precedente elem_id='||id_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

			importoCurAttuale:=0;			
			select tb.importo into importoCurAttuale
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq  -- UID del capitolo di gestione equivalente
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  -- SIAC-7737 GS 31/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  -- and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno = annoMovimento::integer -- anno dell impegno = annoMovimento 
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;		

			-- 02.02.2016 Sofia JIRA 2947
			 if importoCurAttuale is null then importoCurAttuale:=0; end if;

			 -- 16.03.2017 Sofia JIRA-SIAC-4614
			-- if importoCurAttuale>0 then
			 /*Adeguamento MR SIAC-7349 Sprint 5
			 	Non restituiamo le modifiche provvisorie al valore dell'impegnato
				
			 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

				strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Calcolo totale modifiche su atti provvisori per annoMovimento='||annoMovimento||'.';

				select tb.importo into importoModifDelta
				 from
				 (
					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, 
					 	 siac_t_movgest mov,
					 	 siac_t_movgest_ts ts,
						 siac_r_movgest_ts_stato rstato,
					  	 siac_t_movgest_ts_det tsdet,
						 siac_t_movgest_ts_det_mod moddet,
						 siac_t_modifica mod, 
					 	 siac_r_modifica_stato rmodstato,
						 siac_r_atto_amm_stato attostato, 
					 	 siac_t_atto_amm atto,
						 siac_d_modifica_tipo tipom
					where 
						rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
						--and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349 in questo caso, non sulla componente
						and	  mov.movgest_id=rbil.movgest_id
						and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
						and   mov.movgest_anno>annoMovimento::integer -- anno dell impegno = annoMovimento 
						and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
						and   ts.movgest_id=mov.movgest_id
						and   rstato.movgest_ts_id=ts.movgest_ts_id
						and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
						and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
					    and   tsdet.movgest_ts_id=ts.movgest_ts_id
						and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
					 	and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
						and   tipom.mod_tipo_id=mod.mod_tipo_id
						-- and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
						-- date
						and rbil.data_cancellazione is null
						and rbil.validita_fine is null
						and mov.data_cancellazione is null
						and mov.validita_fine is null
						and ts.data_cancellazione is null
						and ts.validita_fine is null
						and rstato.data_cancellazione is null
						and rstato.validita_fine is null
						and tsdet.data_cancellazione is null
						and tsdet.validita_fine is null
						and moddet.data_cancellazione is null
						and moddet.validita_fine is null
						and mod.data_cancellazione is null
						and mod.validita_fine is null
						and rmodstato.data_cancellazione is null
						and rmodstato.validita_fine is null
						and attostato.data_cancellazione is null
						and attostato.validita_fine is null
						and atto.data_cancellazione is null
						and atto.validita_fine is null
						group by ts.movgest_ts_tipo_id
					  ) tb, siac_d_movgest_ts_tipo tipo
					  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
					  order by tipo.movgest_ts_tipo_code desc
					  limit 1;		
					  
 				if importoModifDelta is null then importoModifDelta:=0; end if;

		
			end if;	*/	
		end if;
	end if;
    --FIX Sprint5 7349
    importoModifDelta:=0;
    --
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato per l'anno N-1
	impegnatoDefinitivo:=impegnatoDefinitivo+importoCurAttuale-(importoModifDelta);
	
	return impegnatoDefinitivo;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        impegnatoDefinitivo:=0;
        return impegnatoDefinitivo;
    when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        impegnatoDefinitivo:=0;
        return impegnatoDefinitivo;
    when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        impegnatoDefinitivo:=0;
        return impegnatoDefinitivo;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100;


ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoug_annoprec (id_in integer)
  OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoug_annoprec(integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoug_annoprec(integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoug_annoprec(integer) TO siac;
--end fnc_siac_dicuiimpegnatoug_annoprec

--Start fnc_siac_impegnatodefinitivoug_comp_annisucc_nostanz
/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EfL-1.2
*/
-- DROP FUNCTION fnc_siac_impegnatodefinitivoug_comp_annisucc_nostanz(integer,integer[]);

CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatodefinitivoug_comp_annisucc_nostanz(
	id_in integer,
	idcomp_in INT[])
    RETURNS TABLE(
    	elemdetcompid integer, 
    	elemdetcompdesc character varying,
    	impegnatodefinitivo numeric,
	elemdetcompmacrotipodesc character varying) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
AS $BODY$
DECLARE


annoBilancio varchar:=null;
annoEsercizio varchar:=null;
annoMovimento varchar:=null;

elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;
NVL_STR     constant varchar:='';
faseOpCode varchar(20):=NVL_STR;
bilancioId integer:=0;
elemTipoCode VARCHAR(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;
enteProprietarioId INTEGER:=0;
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
FASE_OP_BIL_PREV constant VARCHAR:='P';
STATO_A     constant varchar:='A';
STATO_P     constant varchar:='P';
TIPO_IMP    constant varchar:='I';
movGestStatoIdAnnullato integer:=0;
movGestStatoIdProvvisorio integer:=0;
movGestTipoId integer:=0;
IMPORTO_ATT constant varchar:='A';
movGestTsDetTipoId integer:=0;
IMPORTO_INIZIALE constant varchar:='I';
movGestTsDetTipoIdIniziale integer:=0;
STATO_MOD_V  constant varchar:='V';
modStatoVId integer:=0;
attoAmmStatoPId integer:=0;
STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoCurAttuale numeric:=0;
esisteRmovgestidelemid INTEGER:=0;
importoModifDelta  numeric:=0;
importoModifINS numeric:=0; --aggiunta per ECONB
impegniDaRibaltamento integer:=0;
pluriennaliDaRibaltamento integer:=0;
flagNMaggioreNPiu2 integer:=0;
flagDeltaPagamenti integer:=0;
importoImpegnato numeric:=0;
importoPagatoDelta numeric:=0;
ordStatoAId          integer:=null;
ordTsDetTipoAId      integer:=null;
-- stati ordinativi
STATO_ORD_A    constant varchar:='A'; -- ANNULLATO
-- importoAttuale ordinativi
ORD_TS_DET_TIPO_A  constant varchar:='A';

sidcomp_in  varchar:=null;
strMessaggio varchar(1500):=null;

impComponenteRec record;

BEGIN

/* Calcola impegnato definitivo per quelle componenti per le quali pur non essendoci stanziamento
 * esistono quote di impegnato nell'anno > N+2 
 * Le componenti per le quali esiste stanziamento (e quindi da non considerare) sono passate in input nell'array idcomp_in
 * NOTA: per problemi Java/Hibernate idcomp_in non puo' essere un array vuoto, quindi 
 *		l'array in input conterra' sempre la componente fittizia idcomp = -1
 */
-- CALCOLO IMPEGNATO DEFINITIVO 
-- I valori di impegnato dovranno essere calcolati tenendo conto del solo impegnato definitivo.
-- Escluse dal calcolo quindi:
--		- le modifiche di impegno provvisorie (modifiche con provvedimento in stato provvisorio - di qualsiasi segno
-- 		- gli  impegni in stato provvisorio

	sidcomp_in:=array_to_string(idcomp_in, ',');
    	strMessaggio:='Calcolo totale impegnato definitovo elem_id='||id_in|| ' escludo idcomp_in='||sidcomp_in|| '.';

	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;
 
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||
    			  '.Lettura anno di bilancio del capitolo UG.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;
		  

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||
    				   '. Calcolo bilancioId e elem_tipo_code.';
	 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
	 into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
	 from 	siac_t_bil_elem bilElem, 
	 		siac_d_bil_elem_tipo tipoBilElem,
		  	siac_t_bil bil, siac_t_periodo per
	 where bilElem.elem_id=id_in
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
	   and bil.bil_id=bilElem.bil_id
	   and per.periodo_id=bil.periodo_id;

	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UG then
			RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
	 end if;

	 strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||
				   'Calcolo fase operativa per bilancioId='||bilancioId
				   ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select  faseOp.fase_operativa_code into  faseOpCode
	 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
	 where bilFase.bil_id =bilancioId
	   and bilfase.data_cancellazione is null
	   and bilFase.validita_fine is null
	   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
	   and faseOp.data_cancellazione is null
	 order by bilFase.bil_fase_operativa_id desc;

	 if NOT FOUND THEN
	   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
	 end if;

	 strMessaggio:='Calcolo impegnato definitivo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO'
				  ||'. Calcolo movGestTsStatoIdProvvisorio per movgest_stato_code=PROVVISORIO';

	 select movGestStato.movgest_stato_id into strict movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;

	 select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_P; 
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTsDetTipoId per movgest_ts_det_tipo_code=IMPORTO ATTUALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE;
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
              ||'. Calcolo modStatoVId per mod_stato_code=VALIDO.';
	 select d.mod_stato_id into strict modStatoVId
	 from siac_d_modifica_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.mod_stato_code=STATO_MOD_V;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	 select d.attoamm_stato_id into strict attoAmmStatoPId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_P;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINITIVO';
	 select d.attoamm_stato_id into strict attoAmmStatoDId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_D;

 	 	-- Calcolo Impegnato definitivo - Anno > N+2:
	-- - Se presenti i movimenti gestione provenienti dal ribaltamento 
	--		Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente e anno movimento > N+2 e anno esercizio N
	-- - Se non presenti i movimenti gestione provenienti dal ribaltamento 
	-- 		Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente e anno movimento > N+2 e anno esercizio N-1
	-- I valori di impegnato dovranno essere calcolati tenendo conto del solo impegnato definitivo.
	-- Escluse dal calcolo quindi:
	--		- le modifiche di impegno provvisorie (modifiche con provvedimento in stato provvisorio - di qualsiasi segno)
	-- 		- gli  impegni in stato provvisorio

	-- Verifica se presenti i movimenti di gestione provenienti dal ribaltamento
	-- Per "ribaltamento" si intende  il batch di ribaltamento residui che gira prima del ROR 
	--		e che "copia" gli impegni dell'anno N-1 nel bilancio dell'anno N (di solito il 2 gennaio)
	-- Per verificare che il batch di ribaltamento sia stato eseguito controllo le seguenti tabelle
	-- 		fase_bil_t_gest_apertura_liq_imp per gli impegni residui
	--  	fase_bil_t_gest_apertura_pluri per i pluriennli (sia impegni che accertamenti)
	-- In entrambe c'e' sia il bil_id che il bil_id_orig ovvero l'anno nuovo su cui si stanno ribaltando i movimenti e l'anno prec
	-- c'e' anche un campo fl_elab che ti dice se i dati sono stati elaborati con scarto o con successo 

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in;
	
	importoCurAttuale:=0;	
	importoModifDelta:=0;
	importoModifINS := 0;
	

	--		ImpegnatoDefinitivo = Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in 
	--		e anno movimento > N+2 e anno esercizio N

	annoEsercizio:=annoBilancio;
	annoMovimento:=((annoBilancio::INTEGER)+2)::varchar;
	flagNMaggioreNPiu2:=1;
	
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per annoEsercizio='||annoEsercizio
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    	-- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo impegnato competenza UG.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else
	
		strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento|| 
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid 
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno>annoMovimento::integer 
			and NOT (el.elem_det_comp_tipo_id = ANY( idcomp_in)) --SIAC-7349
			;
		
		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;
	
		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

/*			importoCurAttuale:=0;			
			select tb.importo into importoCurAttuale
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
				  NOT ( a.elem_det_comp_tipo_id = ANY( idcomp_in))--SIAC-7349 non deve essere sulla componente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno > annoMovimento::integer -- anno dell impegno > annoMovimento 
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;		
*/

			/* Versione con group by per le componenti non da escludere e ciclo per ogni componente */
			for impComponenteRec in
			 (
				select tb.elem_det_comp_tipo_id as compId, 
				 g.elem_det_comp_tipo_desc as compDesc, 
				 tb.importo as importoCurAttuale,
				 h.elem_det_comp_macro_tipo_desc as compMacroTipoDesc 
				 -- tb.importo into importoCurAttuale
				from (
				  select
					  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id, a.elem_det_comp_tipo_id
				  from
					  siac_r_movgest_bil_elem a,
					  siac_t_movgest b,
					  siac_t_movgest_ts c,
					  siac_r_movgest_ts_stato d,
					  siac_t_movgest_ts_det e,
					  siac_d_movgest_ts_det_tipo f
				  where
					  b.movgest_id=a.movgest_id 
					  and a.elem_id=elemIdGestEq
					  and NOT( a.elem_det_comp_tipo_id = ANY(idcomp_in)) --SIAC-7349 --id componente diversa da quella ricevuta in input
					  and b.bil_id = bilIdElemGestEq
					  and b.movgest_tipo_id=movGestTipoId
					  and d.movgest_stato_id!=movGestStatoIdAnnullato
					  -- SIAC-7737 GS 31/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				      -- and d.movgest_stato_id!=movGestStatoIdProvvisorio
					  and b.movgest_anno > annoMovimento::integer -- per gli anni oltre N+2
					  and c.movgest_id=b.movgest_id
					  and d.movgest_ts_id=c.movgest_ts_id
					  and d.validita_fine is null
					  and e.movgest_ts_id=c.movgest_ts_id
					  and a.data_cancellazione is null
					  and b.data_cancellazione is null
					  and c.data_cancellazione is null
					  and e.data_cancellazione is null
					  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
					  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId
					  group by 	c.movgest_ts_tipo_id, 
								a.elem_det_comp_tipo_id -- SIAC-7349
						) tb, 
					siac_d_movgest_ts_tipo t,
					siac_d_bil_elem_det_comp_tipo g,
				 	siac_d_bil_elem_det_comp_macro_tipo h
				where 
					tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
					and g.elem_det_comp_tipo_id = tb.elem_det_comp_tipo_id --SIAC-7349 recupera anche la descrizione della componente
					and g.elem_det_comp_macro_tipo_id = h.elem_det_comp_macro_tipo_id --SIAC-7349 recupera anche la descrizione del macrotipo della componente
				 order by t.movgest_ts_tipo_code desc
 			) 
			loop
			

					-- 02.02.2016 Sofia JIRA 2947
					 if impComponenteRec.importoCurAttuale is null then impComponenteRec.importoCurAttuale:=0; end if;

					 -- 16.03.2017 Sofia JIRA-SIAC-4614
					-- if importoCurAttuale>0 then
					 if impComponenteRec.importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

						strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'  impComponenteRec.compId='||impComponenteRec.compId||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Calcolo totale modifiche su atti provvisori per annoMovimento='||annoMovimento||'.';

						select tb.importo into importoModifDelta
						 from
						 (
							select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
							from siac_r_movgest_bil_elem rbil, 
								 siac_t_movgest mov,
								 siac_t_movgest_ts ts,
								 siac_r_movgest_ts_stato rstato,
								 siac_t_movgest_ts_det tsdet,
								 siac_t_movgest_ts_det_mod moddet,
								 siac_t_modifica mod, 
								 siac_r_modifica_stato rmodstato,
								 siac_r_atto_amm_stato attostato, 
								 siac_t_atto_amm atto,
								 siac_d_modifica_tipo tipom
							where 
								rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
								and rbil.elem_det_comp_tipo_id=impComponenteRec.compId --SIAC-7349 deve essere sulla compoenente del record 
								and	  mov.movgest_id=rbil.movgest_id
								and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
								and   mov.movgest_anno>annoMovimento::integer -- anno dell impegno = annoMovimento 
								and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
								and   ts.movgest_id=mov.movgest_id
								and   rstato.movgest_ts_id=ts.movgest_ts_id
								and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
								-- SIAC-7737 GS 31/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
							    -- and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
								and   tsdet.movgest_ts_id=ts.movgest_ts_id
								and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
								and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
								-- SIAC-7349 Prendo tutti gli importi, sia con segno negativo che con segno positivo
								-- La loro somma produce il valore importoModifDelta che devo sottrarre all'impegnato calcolato
								-- ad esempio: modifiche su atto provv +100, -322 -> somma -222 si tratta di un delta che devo sottrarre
								-- all'impegnato calcolato = impegnato calcolato - (-222) = +222 (aggiungo quello che avevo tolto)
								-- and   moddet.movgest_ts_det_importo<0 -- importo negativo
								and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
								and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
								and   mod.mod_id=rmodstato.mod_id
								and   atto.attoamm_id=mod.attoamm_id
								and   attostato.attoamm_id=atto.attoamm_id
								and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
								and   tipom.mod_tipo_id=mod.mod_tipo_id
								and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
								-- date
								and rbil.data_cancellazione is null
								and rbil.validita_fine is null
								and mov.data_cancellazione is null
								and mov.validita_fine is null
								and ts.data_cancellazione is null
								and ts.validita_fine is null
								and rstato.data_cancellazione is null
								and rstato.validita_fine is null
								and tsdet.data_cancellazione is null
								and tsdet.validita_fine is null
								and moddet.data_cancellazione is null
								and moddet.validita_fine is null
								and mod.data_cancellazione is null
								and mod.validita_fine is null
								and rmodstato.data_cancellazione is null
								and rmodstato.validita_fine is null
								and attostato.data_cancellazione is null
								and attostato.validita_fine is null
								and atto.data_cancellazione is null
								and atto.validita_fine is null
								group by ts.movgest_ts_tipo_id
							  ) tb, siac_d_movgest_ts_tipo tipo
							  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
							  order by tipo.movgest_ts_tipo_code desc
							  limit 1;		

						if importoModifDelta is null then importoModifDelta:=0; end if;
						  /*Aggiunta delle modifiche ECONB*/
						 -- anna_economie inizio
						select tb.importo into importoModifINS
						from
						(
							select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
							from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
							siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
							siac_t_movgest_ts_det_mod moddet,
							siac_t_modifica mod, siac_r_modifica_stato rmodstato,
							siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
							siac_d_modifica_tipo tipom
						where rbil.elem_id=elemIdGestEq
						and rbil.elem_det_comp_tipo_id=impComponenteRec.compId --SIAC-7349
						and	  mov.movgest_id=rbil.movgest_id
						and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
						and   mov.movgest_anno=annoMovimento::integer
						and   mov.bil_id=bilancioId
						and   ts.movgest_id=mov.movgest_id
						and   rstato.movgest_ts_id=ts.movgest_ts_id
						and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- impegno non annullato
						and   tsdet.movgest_ts_id=ts.movgest_ts_id
						and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
						and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
					   and   tipom.mod_tipo_id=mod.mod_tipo_id
					   and   tipom.mod_tipo_code = 'ECONB'
						-- date
						and rbil.data_cancellazione is null
						and rbil.validita_fine is null
						and mov.data_cancellazione is null
						and mov.validita_fine is null
						and ts.data_cancellazione is null
						and ts.validita_fine is null
						and rstato.data_cancellazione is null
						and rstato.validita_fine is null
						and tsdet.data_cancellazione is null
						and tsdet.validita_fine is null
						and moddet.data_cancellazione is null
						and moddet.validita_fine is null
						and mod.data_cancellazione is null
						and mod.validita_fine is null
						and rmodstato.data_cancellazione is null
						and rmodstato.validita_fine is null
						and attostato.data_cancellazione is null
						and attostato.validita_fine is null
						and atto.data_cancellazione is null
						and atto.validita_fine is null
					   group by ts.movgest_ts_tipo_id
					 ) tb, siac_d_movgest_ts_tipo tipo
					 where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
					 order by tipo.movgest_ts_tipo_code desc
					 limit 1;

					 if importoModifINS is null then 
						importoModifINS = 0;
					 end if;


					end if;		
	
			--Fix MR adeguamento sprint5
			-- Non restituiamo piu' all'impegnato il valore delle modifiche negative provvisorie
			-- e delle economie ECONB
          		importoModifDelta:=0;
            		importoModifINS:=0;
	    
			elemDetCompId:=impComponenteRec.compId;
			elemdetcompdesc:=impComponenteRec.compDesc;
			elemdetcompmacrotipodesc:=impComponenteRec.compMacroTipoDesc;
			impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente  
			impegnatoDefinitivo:=impegnatoDefinitivo+impComponenteRec.importoCurAttuale-(importoModifDelta);
			--aggiunta per ECONB
			impegnatoDefinitivo:=impegnatoDefinitivo+abs(importoModifINS);
			return next;	



	end loop;
	end if;
	end if;

	return;
 

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
		return;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
		return;
END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_impegnatodefinitivoug_comp_annisucc_nostanz(integer, INT[])
    OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatodefinitivoug_comp_annisucc_nostanz(integer, INT[]) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatodefinitivoug_comp_annisucc_nostanz(integer, INT[]) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatodefinitivoug_comp_annisucc_nostanz(integer, INT[]) TO siac;

--end fnc_siac_impegnatodefinitivoug_comp_annisucc_nostanz

--Start siac.fnc_siac_cons_entita_impegno_from_capitolospesa
DROP FUNCTION if exists siac.fnc_siac_cons_entita_impegno_from_capitolospesa(integer, character varying, character varying,integer,integer);
CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_impegno_from_capitolospesa(
	_uid_capitolospesa integer,
	_anno character varying,
	_filtro_crp character varying,
	_limit integer,
	_page integer)
    RETURNS TABLE(
        uid integer,
        impegno_anno integer,
        impegno_numero numeric,
        impegno_desc character varying,
        impegno_stato character varying,
        impegno_importo numeric,
        soggetto_code character varying,
        soggetto_desc character varying,
        attoamm_numero integer,
        attoamm_anno character varying,
        attoamm_desc character varying,
        attoamm_tipo_code character varying,
        attoamm_tipo_desc character varying,
        attoamm_stato_desc character varying,
        attoamm_sac_code character varying,
        attoamm_sac_desc character varying,
        pdc_code character varying,
        pdc_desc character varying,
        impegno_anno_capitolo integer,
        impegno_nro_capitolo integer,
        impegno_nro_articolo integer,
        impegno_flag_prenotazione character varying,
        impegno_cup character varying,
        impegno_cig character varying,
        impegno_tipo_debito character varying,
        impegno_motivo_assenza_cig character varying,
        --11.05.2020 SIAC-7349 SR210
        impegno_componente character varying
    )
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
    ROWS 1000
AS $BODY$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
		with imp_sogg_attoamm as (
			with imp_sogg as (
				select distinct
					soggall.uid,
					soggall.movgest_anno,
					soggall.movgest_numero,
					soggall.movgest_desc,
					soggall.movgest_stato_desc,
					soggall.movgest_ts_id,
					soggall.movgest_ts_det_importo,
					case when soggall.zzz_soggetto_code is null then soggall.zzzz_soggetto_code else soggall.zzz_soggetto_code end soggetto_code,
					case when soggall.zzz_soggetto_desc is null then soggall.zzzz_soggetto_desc else soggall.zzz_soggetto_desc end soggetto_desc,
					soggall.pdc_code,
					soggall.pdc_desc,
                    -- 29.06.2018 Sofia jira siac-6193
					soggall.impegno_nro_capitolo,
					soggall.impegno_nro_articolo,
					soggall.impegno_anno_capitolo,
                    soggall.impegno_flag_prenotazione,
                    soggall.impegno_cig,
  					soggall.impegno_cup,
                    soggall.impegno_motivo_assenza_cig,
            		soggall.impegno_tipo_debito,
                    -- 11.05.2020 SIAC-7349 SR210
                    soggall.impegno_componente

				from (
					with za as (
						select
							zzz.uid,
							zzz.movgest_anno,
							zzz.movgest_numero,
							zzz.movgest_desc,
							zzz.movgest_stato_desc,
							zzz.movgest_ts_id,
							zzz.movgest_ts_det_importo,
							zzz.zzz_soggetto_code,
							zzz.zzz_soggetto_desc,
							zzz.pdc_code,
							zzz.pdc_desc,
                            -- 29.06.2018 Sofia jira siac-6193
                            zzz.impegno_nro_capitolo,
                            zzz.impegno_nro_articolo,
                            zzz.impegno_anno_capitolo,
                            zzz.impegno_flag_prenotazione,
                            zzz.impegno_cig,
  							zzz.impegno_cup,
                            zzz.impegno_motivo_assenza_cig,
            				zzz.impegno_tipo_debito,
                            --11/05/2020 SIAC-7349 SR210
                            zzz.impegno_componente
						from (
							with impegno as (


								select
									a.movgest_id as uid,
									a.movgest_anno,
									a.movgest_numero,
									a.movgest_desc,
									e.movgest_stato_desc,
									c.movgest_ts_id,
									f.movgest_ts_det_importo,
									q.classif_code pdc_code,
									q.classif_desc pdc_desc,
                                    -- 29.06.2018 Sofia jira siac-6193
                                    bilelem.elem_code::integer impegno_nro_capitolo,
                                    bilelem.elem_code2::integer impegno_nro_articolo,
                                    t.anno::integer impegno_anno_capitolo,
                                    c.siope_assenza_motivazione_id,
                                    c.siope_tipo_debito_id,
                                    --11.05.2020 Mr SIAC-7349 SR210 tiro fuori l'id per la join con la tabella del tipo componente
                                    b.elem_det_comp_tipo_id
                                    --
								from
									siac_t_bil_elem bilelem,
									siac_t_movgest a,
									siac_r_movgest_bil_elem b,
									siac_r_movgest_ts_stato d,
									siac_d_movgest_stato e,
									siac_t_movgest_ts_det f,
									siac_d_movgest_ts_tipo j,
									siac_d_movgest_ts_det_tipo k,
									siac_r_movgest_class p,
									siac_t_class q,
									siac_d_class_tipo r,
									siac_t_bil s,
									siac_t_periodo t,
									siac_t_movgest_ts c
								where a.movgest_id=b.movgest_id
								and c.movgest_id=a.movgest_id
								and d.movgest_ts_id=c.movgest_ts_id
								and e.movgest_stato_id=d.movgest_stato_id
								and p.movgest_ts_id = c.movgest_ts_id
								and q.classif_id = p.classif_id
								and r.classif_tipo_id = q.classif_tipo_id
								and j.movgest_ts_tipo_id=c.movgest_ts_tipo_id
								and k.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
								and s.bil_id = a.bil_id
								and t.periodo_id = s.periodo_id
								and now() between d.validita_inizio and coalesce(d.validita_fine, now())
								and now() between b.validita_inizio and coalesce(b.validita_fine, now())
								and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
								and f.movgest_ts_id=c.movgest_ts_id
								and a.data_cancellazione is null
								and b.data_cancellazione is null
								and c.data_cancellazione is null
								and d.data_cancellazione is null
								and e.data_cancellazione is null
								and f.data_cancellazione is null
								and p.data_cancellazione is null
								and q.data_cancellazione is null
								and r.data_cancellazione is null
								and s.data_cancellazione is null
								and t.data_cancellazione is null
								and bilelem.data_cancellazione is null
								and e.movgest_stato_code<>'A'
								and j.movgest_ts_tipo_code='T'
								and k.movgest_ts_det_tipo_code='A'
								and r.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
								and b.elem_id=bilelem.elem_id
								and bilelem.elem_id=_uid_capitolospesa
                                and t.anno = _anno
							),
							siope_assenza_motivazione as
                            (
								select
									d.siope_assenza_motivazione_id,
									d.siope_assenza_motivazione_code,
									d.siope_assenza_motivazione_desc
								from siac_d_siope_assenza_motivazione d
								where d.data_cancellazione is null
							),

							siope_tipo_debito as
                            (
								select
									d.siope_tipo_debito_id,
									d.siope_tipo_debito_code,
									d.siope_tipo_debito_desc
								from siac_d_siope_tipo_debito d
								where d.data_cancellazione is null
							),
							soggetto as
                            (
								select
									g.soggetto_code,
									g.soggetto_desc,
									h.movgest_ts_id
								from
									siac_t_soggetto g,
									siac_r_movgest_ts_sog h
								where h.soggetto_id=g.soggetto_id
								and now() between h.validita_inizio and coalesce(h.validita_fine, now())
								and g.data_cancellazione is null
								and h.data_cancellazione is null
							),
							impegno_flag_prenotazione as
                            (
								select
									r.movgest_ts_id,
									r.boolean
								from
									siac_r_movgest_ts_attr r,
									siac_t_attr t
								where r.attr_id = t.attr_id
								and now() between r.validita_inizio and coalesce(r.validita_fine, now())
								and r.data_cancellazione is null
								and t.data_cancellazione is null
								and t.attr_code = 'flagPrenotazione'
							),
							impegno_cig as
                            (
								select
									r.movgest_ts_id,
									r.testo
								from
									siac_r_movgest_ts_attr r,
									siac_t_attr t
								where r.attr_id = t.attr_id
								and now() between r.validita_inizio and coalesce(r.validita_fine, now())
								and r.data_cancellazione is null
								and t.data_cancellazione is null
								and t.attr_code = 'cig'
							),
							impegno_cup as
                            (
								select
									r.movgest_ts_id,
									r.testo
								from
									siac_r_movgest_ts_attr r,
									siac_t_attr t
								where r.attr_id = t.attr_id
								and now() between r.validita_inizio and coalesce(r.validita_fine, now())
								and r.data_cancellazione is null
								and t.data_cancellazione is null
								and t.attr_code = 'cup'
							),
                            --11.05.2020 SIAC-7349 MR SR210 lista di tutte le componenti
                            componente_desc AS
                            (
                                select * from 
                                siac_d_bil_elem_det_comp_tipo tipo
                                --where tipo.data_cancellazione is NULL --da discuterne. in questo caso prende solo le componenti non cancellate
                            )
							select
								impegno.uid,
								impegno.movgest_anno,
								impegno.movgest_numero,
								impegno.movgest_desc,
								impegno.movgest_stato_desc,
								impegno.movgest_ts_id,
								impegno.movgest_ts_det_importo,
								soggetto.soggetto_code zzz_soggetto_code,
								soggetto.soggetto_desc zzz_soggetto_desc,
								impegno.pdc_code,
								impegno.pdc_desc,
                                -- 29.06.2018 Sofia jira siac-6193
                                impegno.impegno_nro_capitolo,
                                impegno.impegno_nro_articolo,
                                impegno.impegno_anno_capitolo,
                                siope_assenza_motivazione.siope_assenza_motivazione_desc impegno_motivo_assenza_cig,
                                siope_tipo_debito.siope_tipo_debito_desc impegno_tipo_debito,
                                coalesce(impegno_flag_prenotazione.boolean,'N') impegno_flag_prenotazione,
                                impegno_cig.testo  impegno_cig,
                                impegno_cup.testo  impegno_cup,
                                --11.05.2020 MR SIAC-7349 SR210
                                componente_desc.elem_det_comp_tipo_desc impegno_componente
							from impegno
                              left outer join soggetto on impegno.movgest_ts_id=soggetto.movgest_ts_id
                              left outer join impegno_flag_prenotazione on impegno.movgest_ts_id=impegno_flag_prenotazione.movgest_ts_id
                              left outer join impegno_cig on impegno.movgest_ts_id=impegno_cig.movgest_ts_id
                              left outer join impegno_cup on impegno.movgest_ts_id=impegno_cup.movgest_ts_id
                              left outer join siope_assenza_motivazione on impegno.siope_assenza_motivazione_id=siope_assenza_motivazione.siope_assenza_motivazione_id
                              left outer join siope_tipo_debito on impegno.siope_tipo_debito_id=siope_tipo_debito.siope_tipo_debito_id
                              --11.05.2020 MR SIAC-7349 SR210
                              left outer join componente_desc on impegno.elem_det_comp_tipo_id=componente_desc.elem_det_comp_tipo_id
						) as zzz
					),
					zb as (
						select
							zzzz.uid,
							zzzz.movgest_anno,
							zzzz.movgest_numero,
							zzzz.movgest_desc,
							zzzz.movgest_stato_desc,
							zzzz.movgest_ts_id,
							zzzz.movgest_ts_det_importo,
							zzzz.soggetto_code zzzz_soggetto_code,
							zzzz.soggetto_desc zzzz_soggetto_desc
						from (
							with impegno as (
								select
									a.movgest_id as uid,
									a.movgest_anno,
									a.movgest_numero,
									a.movgest_desc,
									e.movgest_stato_desc,
									c.movgest_ts_id,
									f.movgest_ts_det_importo
								from
									siac_t_movgest a,
									siac_r_movgest_bil_elem b,
									siac_t_movgest_ts c,
									siac_r_movgest_ts_stato d,
									siac_d_movgest_stato e,
									siac_t_movgest_ts_det f,
									siac_d_movgest_ts_tipo j,
									siac_d_movgest_ts_det_tipo k,
									siac_t_bil l,
									siac_t_periodo m
								where a.movgest_id=b.movgest_id
								and c.movgest_id=a.movgest_id
								and d.movgest_ts_id=c.movgest_ts_id
								and e.movgest_stato_id=d.movgest_stato_id
								and j.movgest_ts_tipo_id=c.movgest_ts_tipo_id
								and k.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
								and l.bil_id = a.bil_id
								and m.periodo_id = l.periodo_id
								and now() between d.validita_inizio and coalesce(d.validita_fine, now())
								and now() between b.validita_inizio and coalesce(b.validita_fine, now())
								and f.movgest_ts_id=c.movgest_ts_id
								and a.data_cancellazione is null
								and b.data_cancellazione is null
								and c.data_cancellazione is null
								and d.data_cancellazione is null
								and e.data_cancellazione is null
								and f.data_cancellazione is null
								and e.movgest_stato_code<>'A'
								and j.movgest_ts_tipo_code='T'
								and k.movgest_ts_det_tipo_code='A'
								and b.elem_id=_uid_capitolospesa
								and m.anno = _anno
							),
							soggetto as (
                                select
									l.soggetto_classe_code soggetto_code,
									l.soggetto_classe_desc soggetto_desc,
									h.movgest_ts_id
								from
									siac_r_movgest_ts_sogclasse h,
									siac_d_soggetto_classe l
								where
								    h.soggetto_classe_id=l.soggetto_classe_id
                                and now() between h.validita_inizio and coalesce(h.validita_fine, now())
								and h.data_cancellazione is null
							)
							select
								impegno.uid,
								impegno.movgest_anno,
								impegno.movgest_numero,
								impegno.movgest_desc,
								impegno.movgest_stato_desc,
								impegno.movgest_ts_id,
								impegno.movgest_ts_det_importo,
								soggetto.soggetto_code,
								soggetto.soggetto_desc
							from impegno
							left outer join soggetto on impegno.movgest_ts_id=soggetto.movgest_ts_id
						) as zzzz
					)
					select
						za.*,
						zb.zzzz_soggetto_code,
						zb.zzzz_soggetto_desc
					from za
					left join zb on za.movgest_ts_id=zb.movgest_ts_id
				) soggall
			),

			attoamm as (
				select
					movgest_ts_id,
					n.attoamm_id,
					n.attoamm_numero,
					n.attoamm_anno,
                    --29.06.2018 Sofia jira siac-6193
                    n.attoamm_oggetto,
					q.attoamm_stato_desc,
					o.attoamm_tipo_code,
					o.attoamm_tipo_desc
				from
					siac_r_movgest_ts_atto_amm m,
					siac_t_atto_amm n,
					siac_d_atto_amm_tipo o,
					siac_r_atto_amm_stato p,
					siac_d_atto_amm_stato q
				where n.attoamm_id=m.attoamm_id
				and o.attoamm_tipo_id=n.attoamm_tipo_id
				and p.attoamm_id=n.attoamm_id
				and p.attoamm_stato_id=q.attoamm_stato_id
				and now() BETWEEN m.validita_inizio and coalesce (m.validita_fine,now())
				and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
				and q.attoamm_stato_code<>'ANNULLATO'
				and m.data_cancellazione is null
				and n.data_cancellazione is null
				and o.data_cancellazione is null
				and p.data_cancellazione is null
				and q.data_cancellazione is null
			)
			select
				imp_sogg.uid,
				imp_sogg.movgest_anno,
				imp_sogg.movgest_numero,
				imp_sogg.movgest_desc,
				imp_sogg.movgest_stato_desc,
				imp_sogg.movgest_ts_det_importo,
				imp_sogg.soggetto_code,
				imp_sogg.soggetto_desc,
				attoamm.attoamm_id,
				attoamm.attoamm_numero,
				attoamm.attoamm_anno,
                -- 29.06.2018 Sofia jira siac-6193
                attoamm.attoamm_oggetto,
				attoamm.attoamm_tipo_code,
				attoamm.attoamm_tipo_desc,
				attoamm.attoamm_stato_desc,
				imp_sogg.pdc_code,
				imp_sogg.pdc_desc,
                -- 29.06.2018 Sofia jira siac-6193
                imp_sogg.impegno_nro_capitolo,
           		imp_sogg.impegno_nro_articolo,
           		imp_sogg.impegno_anno_capitolo,
                imp_sogg.impegno_flag_prenotazione,
                imp_sogg.impegno_cig,
                imp_sogg.impegno_cup,
                imp_sogg.impegno_motivo_assenza_cig,
                imp_sogg.impegno_tipo_debito,
                --11.05.2020 MR SIAC-7349 SR210
                imp_sogg.impegno_componente

			from imp_sogg

			 left outer join attoamm ON imp_sogg.movgest_ts_id=attoamm.movgest_ts_id
            where (case when coalesce(_filtro_crp,'X')='R' then imp_sogg.movgest_anno<_anno::integer
                     	when coalesce(_filtro_crp,'X')='C' then imp_sogg.movgest_anno=_anno::integer
                        when coalesce(_filtro_crp,'X')='P' then imp_sogg.movgest_anno>_anno::integer
		                else true end ) -- 29.06.2018 Sofia jira siac-6193
		),
		sac_attoamm as (
			select
				y.classif_code,
				y.classif_desc,
				z.attoamm_id
			from
				siac_r_atto_amm_class z,
				siac_t_class y,
				siac_d_class_tipo x
			where z.classif_id=y.classif_id
			and x.classif_tipo_id=y.classif_tipo_id
			and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
			and x.classif_tipo_code  IN ('CDC', 'CDR')
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
		)
		select
			imp_sogg_attoamm.uid,
			imp_sogg_attoamm.movgest_anno as impegno_anno,
			imp_sogg_attoamm.movgest_numero as impegno_numero,
			imp_sogg_attoamm.movgest_desc as impegno_desc,
			imp_sogg_attoamm.movgest_stato_desc as impegno_stato,
			imp_sogg_attoamm.movgest_ts_det_importo as impegno_importo,
			imp_sogg_attoamm.soggetto_code,
			imp_sogg_attoamm.soggetto_desc,
			imp_sogg_attoamm.attoamm_numero,
			imp_sogg_attoamm.attoamm_anno,
            -- 29.06.2018 Sofia jira siac-6193
            imp_sogg_attoamm.attoamm_oggetto attoamm_desc,
			imp_sogg_attoamm.attoamm_tipo_code,
			imp_sogg_attoamm.attoamm_tipo_desc,
			imp_sogg_attoamm.attoamm_stato_desc,
			sac_attoamm.classif_code as attoamm_sac_code,
			sac_attoamm.classif_desc as attoamm_sac_desc,
			imp_sogg_attoamm.pdc_code,
			imp_sogg_attoamm.pdc_desc,
            -- 29.06.2018 Sofia jira siac-6193
            imp_sogg_attoamm.impegno_anno_capitolo,
            imp_sogg_attoamm.impegno_nro_capitolo,
            imp_sogg_attoamm.impegno_nro_articolo,
            imp_sogg_attoamm.impegno_flag_prenotazione::varchar,
			imp_sogg_attoamm.impegno_cup,
            imp_sogg_attoamm.impegno_cig,
            imp_sogg_attoamm.impegno_tipo_debito,
            imp_sogg_attoamm.impegno_motivo_assenza_cig,
            --11.05.2020 SIAC-7349 MR SR210
            imp_sogg_attoamm.impegno_componente
		from imp_sogg_attoamm
		left outer join sac_attoamm on imp_sogg_attoamm.attoamm_id=sac_attoamm.attoamm_id
		order by
			imp_sogg_attoamm.movgest_anno,
			imp_sogg_attoamm.movgest_numero


		LIMIT _limit
		OFFSET _offset;
END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_cons_entita_impegno_from_capitolospesa(integer, character varying, character varying, integer, integer)
    OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_cons_entita_impegno_from_capitolospesa(integer, character varying, character varying, integer, integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_cons_entita_impegno_from_capitolospesa(integer, character varying, character varying, integer, integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_cons_entita_impegno_from_capitolospesa(integer, character varying, character varying, integer, integer) TO siac;

--end siac.fnc_siac_cons_entita_impegno_from_capitolospesa

--Start fnc_siac_dicuiimpegnatoup_anno1
DROP FUNCTION if exists siac.fnc_siac_dicuiimpegnatoup_anno1(integer);
CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoup_anno1 (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE

diCuiImpegnato numeric:=0;
annoBilancio varchar:=null;

diCuiImpegnatoRec record;

strMessaggio varchar(1500):=null;
BEGIN

    strMessaggio:='Calcolo totale impegnato UP elem_id='||id_in||'.';

	strMessaggio:='Calcolo totale impegnato UP elem_id='||id_in||
    			  '.Lettura anno di bilancio.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;

	/* SIAC-7349 mantengo questa chiamata perche cosi' il default del parametro verifica_mod_provv = TRUE 
	 * forza la restituzione delle modifiche provvisorie al valore dicuiimpegnato
	 * che qui servira' per il calcolo della disponibilita' ad impegnare  */
    strMessaggio:='Calcolo totale impegnato UP elem_id='||id_in||'.';
    select * into diCuiImpegnatoRec
    from  fnc_siac_dicuiimpegnatoup_comp_anno (id_in,annoBilancio);
    
    diCuiImpegnato:=diCuiImpegnatoRec.diCuiImpegnato;


return diCuiImpegnato;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        diCuiImpegnato:=0;
        return diCuiImpegnato;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        diCuiImpegnato:=0;
        return diCuiImpegnato;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        diCuiImpegnato:=0;
        return diCuiImpegnato;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100;


ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoup_anno1 (id_in integer)
  OWNER TO siac;
  
--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_anno1(integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_anno1(integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_anno1(integer) TO siac;
--end fnc_siac_dicuiimpegnatoup_anno1


--Start fnc_siac_dicuiimpegnatoup_anno2
DROP FUNCTION if exists siac.fnc_siac_dicuiimpegnatoup_anno2(integer);
CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoup_anno2 (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE

diCuiImpegnato numeric:=0;
annoBilancio varchar:=null;

diCuiImpegnatoRec record;

strMessaggio varchar(1500):=null;
BEGIN

	strMessaggio:='Calcolo totale impegnato UP elem_id='||id_in||'.';

	strMessaggio:='Calcolo totale impegnato UP elem_id='||id_in||
    			  '.Lettura anno di bilancio.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;


	/* SIAC-7349 mantengo questa chiamata perche cosi' il default del parametro verifica_mod_provv = TRUE 
	 * forza la restituzione delle modifiche provvisorie al valore dicuiimpegnato
	 * che qui servira' per il calcolo della disponibilita' ad impegnare  */
	strMessaggio:='Calcolo totale impegnato UP elem_id='||id_in||'.';
	select * into diCuiImpegnatoRec
	from  fnc_siac_dicuiimpegnatoup_comp_anno (id_in, ((annoBilancio::integer)+1)::varchar);
	
    diCuiImpegnato:=diCuiImpegnatoRec.diCuiImpegnato;


return diCuiImpegnato;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        diCuiImpegnato:=0;
        return diCuiImpegnato;
   when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        diCuiImpegnato:=0;
        return diCuiImpegnato;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        diCuiImpegnato:=0;
        return diCuiImpegnato;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100;


ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoup_anno2 (id_in integer)
  OWNER TO siac;
  
--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_anno2(integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_anno2(integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_anno2(integer) TO siac;

--end fnc_siac_dicuiimpegnatoup_anno2


--Start fnc_siac_dicuiimpegnatoup_anno3
DROP FUNCTION if exists siac.fnc_siac_dicuiimpegnatoup_anno3(integer);
CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoup_anno3 (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE

diCuiImpegnato numeric:=0;
annoBilancio varchar:=null;

diCuiImpegnatoRec record;

strMessaggio varchar(1500):=null;
BEGIN

    strMessaggio:='Calcolo totale impegnato UP elem_id='||id_in||'.';

	strMessaggio:='Calcolo totale impegnato UP elem_id='||id_in||
    			  '.Lettura anno di bilancio.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;

	/* SIAC-7349 mantengo questa chiamata perche cosi' il default del parametro verifica_mod_provv = TRUE 
	 * forza la restituzione delle modifiche provvisorie al valore dicuiimpegnato
	 * che qui servira' per il calcolo della disponibilita' ad impegnare  */
    strMessaggio:='Calcolo totale impegnato UP elem_id='||id_in||'.';
    select * into diCuiImpegnatoRec
    from  fnc_siac_dicuiimpegnatoup_comp_anno (id_in,((annoBilancio::INTEGER)+2)::varchar);
	
    diCuiImpegnato:=diCuiImpegnatoRec.diCuiImpegnato;


    return diCuiImpegnato;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        diCuiImpegnato:=0;
        return diCuiImpegnato;
    when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        diCuiImpegnato:=0;
        return diCuiImpegnato;

	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        diCuiImpegnato:=0;
        return diCuiImpegnato;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100;


ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoup_anno3 (integer)
  OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_anno3(integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_anno3(integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_anno3(integer) TO siac;

--end fnc_siac_dicuiimpegnatoup_anno3

--Start fnc_siac_dicuiimpegnatoup_comp_anno
DROP FUNCTION if exists siac.fnc_siac_dicuiimpegnatoup_comp_anno ( integer,character varying);
CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno (
  id_in integer,
  anno_in character varying,
  verifica_mod_prov boolean = true -- SIAC-7349 se true vengono restituite all'impegnato le modifiche provvisorie 
)
RETURNS TABLE (
  annocompetenza varchar,
  dicuiimpegnato numeric
) AS
$body$
DECLARE

-- constant
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';

FASE_OP_BIL_PREV constant VARCHAR:='P';
STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';
STATO_MOD_V  constant varchar:='V';
TIPO_IMP    constant varchar:='I';
TIPO_IMP_T  constant varchar:='T';

STATO_DEF   constant varchar:='D';
STATO_N     constant varchar:='N';
STATO_P     constant varchar:='P';
STATO_A     constant varchar:='A';
IMPORTO_ATT constant varchar:='A';

strMessaggio varchar(1500):=NVL_STR;

attoAmmStatoDId integer:=0; -- SIAC-7349
attoAmmStatoPId integer:=0;-- SIAC-7349
bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;
modStatoVId integer:=0; -- SIAC-7349
movGestTipoId integer:=0;
movGestTsTipoId integer:=0;
movGestStatoId integer:=0;
movGestTsDetTipoId integer:=0;
movGestStatoIdProvvisorio integer:=0; -- SIAC-7349
movGestTsId integer:=0;

importoAttuale numeric:=0;
importoCurAttuale numeric:=0;
importoModifDelta  numeric:=0;
importoModifINS numeric:=0; -- SIAC-7349 --aggiunta per ECONB

movGestIdRec record;

elemTipoCode VARCHAR(20):=NVL_STR;
faseOpCode varchar(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;

elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;

BEGIN


 annoCompetenza:=null;
 diCuiImpegnato:=0;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.Controllo parametri.';

 if anno_in is null or anno_in=NVL_STR then
	 RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
	 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
 end if;


 strMessaggio:='Calcolo impegnato competenza UP elem_id='||id_in||'.';


 strMessaggio:='Calcolo impegnato competenza UP.Calcolo bilancioId e elem_tipo_code per elem_id='||id_in||'.';
 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
       into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem,
      siac_t_bil bil, siac_t_periodo per
 where bilElem.elem_id=id_in
   and bilElem.data_cancellazione is null
   and bilElem.validita_fine is null
   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
   and bil.bil_id=bilElem.bil_id
   and per.periodo_id=bil.periodo_id;

 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UP then
        RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
 end if;


 strMessaggio:='Calcolo impegnato competenza UP.Calcolo fase operativa per bilancioId='||bilancioId
               ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

 select  faseOp.fase_operativa_code into  faseOpCode
 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
 where bilFase.bil_id =bilancioId
   and bilfase.data_cancellazione is null
   and bilFase.validita_fine is null
   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
   and faseOp.data_cancellazione is null
 order by bilFase.bil_fase_operativa_id desc;

 if NOT FOUND THEN
   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
 end if;


 strMessaggio:='Calcolo impegnato competenza UP.Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
              ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
 -- lettura elemento bil di gestione equivalente
 if faseOpCode is not null and faseOpCode!=NVL_STR then
  	if  faseOpCode = FASE_OP_BIL_PREV then
      	-- lettura bilancioId annoBilancio precedente per lettura elemento di bilancio equivalente
            	select bil.bil_id into strict bilIdElemGestEq
                from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
                where per.anno=((annoBilancio::integer)-1)::varchar
                  and per.ente_proprietario_id=enteProprietarioId
                  and bil.periodo_id=per.periodo_id
                  and perTipo.periodo_tipo_id=per.periodo_tipo_id
                  and perTipo.periodo_tipo_code='SY';
    else
        	bilIdElemGestEq:=bilancioId;
    end if;
 else
	 RAISE EXCEPTION '% Fase non valida.',strMessaggio;
 end if;

 -- lettura elemIdGestEq
 strMessaggio:='Calcolo impegnato competenza UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
              ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

 select bilelem.elem_id into elemIdGestEq
 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
 where bilElem.elem_code=elemCode
   and bilElem.elem_code2=elemCode2
   and bilElem.elem_code3=elemCode3
   and bilElem.ente_proprietario_id=enteProprietarioId
   and bilElem.data_cancellazione is null
   and bilElem.validita_fine is null
   and bilElem.bil_id=bilIdElemGestEq
   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

if NOT FOUND THEN
else
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTipoId.';
 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
 from  siac_d_movgest_tipo tipoMovGest
 where tipoMovGest.ente_proprietario_id=enteProprietarioId
 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTsTipoId.';
 select movGestTsTipo.movgest_ts_tipo_id into strict movGestTsTipoId
 from siac_d_movgest_ts_tipo movGestTsTipo
 where movGestTsTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsTipo.movgest_ts_tipo_code=TIPO_IMP_T;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
               ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTsStatoId.';

 select movGestStato.movgest_stato_id into strict movGestStatoId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_A;

-- SIAC-7349 INIZIO
strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	  select d.attoamm_stato_id into strict attoAmmStatoPId
	  from siac_d_atto_amm_stato d
	  where d.ente_proprietario_id=enteProprietarioId
	  and d.attoamm_stato_code=STATO_ATTO_P;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINTIVO';

	  select d.attoamm_stato_id into strict attoAmmStatoDId
	  from siac_d_atto_amm_stato d
	  where d.ente_proprietario_id=enteProprietarioId
	  and  d.attoamm_stato_code=STATO_ATTO_D;

	select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	  from siac_d_movgest_stato movGestStato
	  where movGestStato.ente_proprietario_id=enteProprietarioId
	  and   movGestStato.movgest_stato_code=STATO_P;

	select d.mod_stato_id into strict modStatoVId
	  from siac_d_modifica_stato d
	  where d.ente_proprietario_id=enteProprietarioId
	  and   d.mod_stato_code=STATO_MOD_V;
-- SIAC-7349 FINE 

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
               ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTsDetTipoId.';

 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
              ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'. Inizio ciclo per anno_in='||anno_in||'.';
 for movGestIdRec in
 (
     select movGestRel.movgest_id
     from siac_r_movgest_bil_elem movGestRel
     where movGestRel.elem_id=elemIdGestEq
     and   movGestRel.data_cancellazione is null
     and   exists (select 1 from siac_t_movgest movGest
   				   where movGest.movgest_id=movGestRel.movgest_id
			       and	 movGest.bil_id = bilIdElemGestEq
			       and   movGest.movgest_tipo_id=movGestTipoId
				   and   movGest.movgest_anno = anno_in::integer
                   and   movGest.data_cancellazione is null
                   and   movGest.validita_fine is null)
 )
 loop
   	importoCurAttuale:=0;

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
				      ||'.Per elemento gest equivalente elem_id='||elemIdGestEq
                      ||'.Calcolo impegnato anno_in='||anno_in
                      ||'.Lettura siac_t_movgest_ts movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';

    select movgestts.movgest_ts_id into  movGestTsId
    from siac_t_movgest_ts movGestTs
    where movGestTs.movgest_id = movGestIdRec.movgest_id
    and   movGestTs.data_cancellazione is null
    and   movGestTs.movgest_ts_tipo_id=movGestTsTipoId
    and   exists (select 1 from siac_r_movgest_ts_stato movGestTsRel
                  where movGestTsRel.movgest_ts_id=movGestTs.movgest_ts_id
                  and   movGestTsRel.movgest_stato_id!=movGestStatoId
                  and   movGestTsRel.validita_fine is null
                  and   movGestTsRel.data_cancellazione is null);

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
				      ||'.Per elemento gest equivalente elem_id='||elemIdGestEq
                      ||'.Calcolo accertato anno_in='||anno_in||'.Somma siac_t_movgest_ts_det movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';
    if NOT FOUND then
    else
       select coalesce(sum(movGestTsDet.movgest_ts_det_importo),0) into importoCurAttuale
           from siac_t_movgest_ts_det movGestTsDet
           where movGestTsDet.movgest_ts_id=movGestTsId
           and   movGestTsDet.movgest_ts_det_tipo_id=movGestTsDetTipoId;
	   -- SIAC-7349 INIZIO 
           if importoCurAttuale>=0 then
              ----------------
              select tb.importo into importoModifDelta
	          from
	          (
	          	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
	          	from siac_r_movgest_bil_elem rbil,
	          	 	siac_t_movgest mov,
	          	 	siac_t_movgest_ts ts,
	          		siac_r_movgest_ts_stato rstato,
	          	  siac_t_movgest_ts_det tsdet,
	          		siac_t_movgest_ts_det_mod moddet,
	          		siac_t_modifica mod,
	          	 	siac_r_modifica_stato rmodstato,
	          		siac_r_atto_amm_stato attostato,
	          	 	siac_t_atto_amm atto,
	          		siac_d_modifica_tipo tipom
	          	where
	          		rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
	          		and	 mov.movgest_id=rbil.movgest_id
	          		and  mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
	          		and  mov.movgest_anno=anno_in::integer -- anno dell impegno = annoMovimento
	          		and  mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
	          		and  ts.movgest_id=mov.movgest_id
	          		and  rstato.movgest_ts_id=ts.movgest_ts_id
	          		and  rstato.movgest_stato_id!=movGestStatoId -- Impegno non ANNULLATO
	          		and  rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
	          	  and  tsdet.movgest_ts_id=ts.movgest_ts_id
	          		and  moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	          		and  moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	          	 	and   moddet.movgest_ts_det_importo<0 -- importo negativo
	          		and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	          		and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
	          		and   mod.mod_id=rmodstato.mod_id
	          		and   atto.attoamm_id=mod.attoamm_id
	          		and   attostato.attoamm_id=atto.attoamm_id
	          		and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
	          		and   tipom.mod_tipo_id=mod.mod_tipo_id
	          		and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
	          		and rbil.data_cancellazione is null
	          		and rbil.validita_fine is null
	          		and mov.data_cancellazione is null
	          		and mov.validita_fine is null
	          		and ts.data_cancellazione is null
	          		and ts.validita_fine is null
	          		and rstato.data_cancellazione is null
	          		and rstato.validita_fine is null
	          		and tsdet.data_cancellazione is null
	          		and tsdet.validita_fine is null
	          		and moddet.data_cancellazione is null
	          		and moddet.validita_fine is null
	          		and mod.data_cancellazione is null
	          		and mod.validita_fine is null
	          		and rmodstato.data_cancellazione is null
	          		and rmodstato.validita_fine is null
	          		and attostato.data_cancellazione is null
	          		and attostato.validita_fine is null
	          		and atto.data_cancellazione is null
	          		and atto.validita_fine is null
	          		group by ts.movgest_ts_tipo_id
	          	  ) tb, siac_d_movgest_ts_tipo tipo
	          	  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
	          	  order by tipo.movgest_ts_tipo_code desc
	          	  limit 1;
	      	  -- 14.05.2020 Manuel - aggiunto parametro verifica_mod_prov
	          if importoModifDelta is null or verifica_mod_prov is false then importoModifDelta:=0; end if;

                  /*Aggiunta delle modifiche ECONB*/
		        -- anna_economie inizio
	          select tb.importo into importoModifINS
		                from
		                (
		                	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
		                	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
	                   	siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
		                  siac_t_movgest_ts_det_mod moddet,
	                   	siac_t_modifica mod, siac_r_modifica_stato rmodstato,
		                  siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
	                    siac_d_modifica_tipo tipom
		                where rbil.elem_id=elemIdGestEq
		                and	 mov.movgest_id=rbil.movgest_id
		                and  mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
	                  and  mov.movgest_anno=anno_in::integer
	                  and  mov.bil_id=bilancioId
		                and  ts.movgest_id=mov.movgest_id
		                and  rstato.movgest_ts_id=ts.movgest_ts_id
		                and  rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
		                and  tsdet.movgest_ts_id=ts.movgest_ts_id
		                and  moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
		                and  moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
		                and   moddet.movgest_ts_det_importo<0 -- importo negativo
		                and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
		                and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
		                and   mod.mod_id=rmodstato.mod_id
		                and   atto.attoamm_id=mod.attoamm_id
		                and   attostato.attoamm_id=atto.attoamm_id
		                and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
	                   and   tipom.mod_tipo_id=mod.mod_tipo_id
	                   and   tipom.mod_tipo_code = 'ECONB'
		                -- date
		                and rbil.data_cancellazione is null
		                and rbil.validita_fine is null
		                and mov.data_cancellazione is null
		                and mov.validita_fine is null
		                and ts.data_cancellazione is null
		                and ts.validita_fine is null
		                and rstato.data_cancellazione is null
		                and rstato.validita_fine is null
		                and tsdet.data_cancellazione is null
		                and tsdet.validita_fine is null
		                and moddet.data_cancellazione is null
		                and moddet.validita_fine is null
		                and mod.data_cancellazione is null
		                and mod.validita_fine is null
		                and rmodstato.data_cancellazione is null
		                and rmodstato.validita_fine is null
		                and attostato.data_cancellazione is null
		                and attostato.validita_fine is null
		                and atto.data_cancellazione is null
		                and atto.validita_fine is null
	                   group by ts.movgest_ts_tipo_id
	                  ) tb, siac_d_movgest_ts_tipo tipo
	                  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
	                  order by tipo.movgest_ts_tipo_code desc
	                  limit 1;

       			 if importoModifINS is null then
	 	            importoModifINS = 0;
	            end if;
            end if;
    end if;
  --importoAttuale:=importoAttuale+importoCurAttuale;
  importoAttuale:=importoAttuale+importoCurAttuale-(importoModifDelta);
  --aggiunta per ECONB
  importoAttuale:=importoAttuale+abs(importoModifINS);

 end loop;
end if;

annoCompetenza:=anno_in;
diCuiImpegnato:=importoAttuale;

return next;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
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
PARALLEL UNSAFE
COST 100 ROWS 1000;


ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno (integer, varchar, boolean)
  OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno (integer, varchar, boolean) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno (integer, varchar, boolean) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno (integer, varchar, boolean) TO siac;

--end fnc_siac_dicuiimpegnatoup_comp_anno

--Start fnc_siac_disponibilitavariare_anno1
DROP FUNCTION if exists siac.fnc_siac_disponibilitavariare_anno1(integer);
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitavariare_anno1(
	id_in integer)
    RETURNS numeric
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE

CAP_UG_TIPO constant varchar:='CAP-UG';
CAP_UP_TIPO constant varchar:='CAP-UP';

CAP_EG_TIPO constant varchar:='CAP-EG';
CAP_EP_TIPO constant varchar:='CAP-EP';

dispImpegnare numeric:=0;
dispAccertare numeric:=0;
dispVariare   numeric:=0;
annoBilancio  varchar:=null;
tipoCapitolo  varchar:=null;

stanzEffettivoRec record;
diCuiImpegnatoRec record;
diCuiAccertatoRec record;

strMessaggio varchar(1500):=null;
BEGIN

	strMessaggio:='Calcolo disponibile variare elem_id='||id_in||'.';

	strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
    			  '.Lettura anno di bilancio e tipo elemento bilancio.';
	select per.anno, tipo.elem_tipo_code into strict annoBilancio, tipoCapitolo
	from siac_t_bil_elem bilElem,siac_d_bil_elem_tipo tipo,
         siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in
    and   bilElem.data_cancellazione is null and bilElem.validita_fine is null
    and   tipo.elem_tipo_id=bilElem.elem_tipo_id
    and   bil.bil_id=bilElem.bil_id
    and   per.periodo_id=bil.periodo_id;

	case
      when tipoCapitolo=CAP_UP_TIPO then
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UP_TIPO||
    				  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
	    select * into stanzEffettivoRec
		from fnc_siac_stanz_effettivo_up_anno (id_in,annoBilancio);
		
		/* SIAC-7349 10:44
			sia per UP che per UG, il calcolo dell'impegnato ai fini del Calcolo della disponibilita' a variare
			dobbiamo restituire le ECONB ma non le modifiche negative provvisorie 
			-> modif<0 provvisorie non riconteggiate, danno disp. al capitolo
		*/
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UP_TIPO||
    	              '.Calcolo impegnato per anno='||annobilancio||'.';
	    select * into diCuiImpegnatoRec
    	-- SIAC-7349 from fnc_siac_dicuiimpegnatoup_comp_anno (id_in,annoBilancio);
   		from fnc_siac_dicuiimpegnatoup_comp_anno (id_in,annoBilancio,false);

        dispVariare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;
      when  tipoCapitolo=CAP_EP_TIPO then
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_EP_TIPO||
    				  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
	    select * into stanzEffettivoRec
		from fnc_siac_stanz_effettivo_ep_anno (id_in,annoBilancio);

		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_EP_TIPO||
    	              '.Calcolo accertato per anno='||annobilancio||'.';
	    select * into diCuiAccertatoRec
    	from fnc_siac_dicuiaccertatoep_comp_anno (id_in,annoBilancio);

        dispVariare:=stanzEffettivoRec.stanzEffettivo-diCuiAccertatoRec.diCuiAccertato;
      when tipoCapitolo=CAP_UG_TIPO then
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UG_TIPO||
    				  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
	    select * into stanzEffettivoRec
		from fnc_siac_stanz_effettivo_ug_anno (id_in,annoBilancio);

		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UG_TIPO||
    	              '.Calcolo impegnato per anno='||annobilancio||'.';
	    select * into diCuiImpegnatoRec
    	from fnc_siac_dicuiimpegnatoug_comp_anno (id_in,annoBilancio, false);
        dispVariare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;
      when tipoCapitolo=CAP_EG_TIPO then
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_EG_TIPO||
    				  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
	    select * into stanzEffettivoRec
		from fnc_siac_stanz_effettivo_eg_anno (id_in,annoBilancio);

		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_EG_TIPO||
    	              '.Calcolo accertato per anno='||annobilancio||'.';
	    select * into diCuiAccertatoRec
    	from fnc_siac_dicuiaccertatoeg_comp_anno (id_in,annoBilancio);

        dispVariare:=stanzEffettivoRec.stanzEffettivo-diCuiAccertatoRec.diCuiAccertato;
    end case;

return dispVariare;

exception
   when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return -1;
   when too_many_rows then
    	RAISE EXCEPTION '% Diversi records presenti in archivio.',strMessaggio;
        return -1;
    when no_data_found then
			RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return -1;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return -1;
END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_disponibilitavariare_anno1(integer)
    OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariare_anno1(integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariare_anno1(integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariare_anno1(integer) TO siac;
--end fnc_siac_disponibilitavariare_anno1


--Start fnc_siac_disponibilitavariare_anno2
DROP FUNCTION if exists siac.fnc_siac_disponibilitavariare_anno2(integer);
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitavariare_anno2(
	id_in integer)
    RETURNS numeric
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE

CAP_UG_TIPO constant varchar:='CAP-UG';
CAP_UP_TIPO constant varchar:='CAP-UP';

CAP_EG_TIPO constant varchar:='CAP-EG';
CAP_EP_TIPO constant varchar:='CAP-EP';

dispImpegnare numeric:=0;
dispAccertare numeric:=0;
dispVariare   numeric:=0;
annoBilancio  varchar:=null;
tipoCapitolo  varchar:=null;

stanzEffettivoRec record;
diCuiImpegnatoRec record;
diCuiAccertatoRec record;

strMessaggio varchar(1500):=null;
BEGIN

	strMessaggio:='Calcolo disponibile variare elem_id='||id_in||'.';

	strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
    			  '.Lettura anno di bilancio e tipo elemento bilancio.';
	select per.anno, tipo.elem_tipo_code into strict annoBilancio, tipoCapitolo
	from siac_t_bil_elem bilElem,siac_d_bil_elem_tipo tipo,
         siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in
    and   bilElem.data_cancellazione is null and bilElem.validita_fine is null
    and   tipo.elem_tipo_id=bilElem.elem_tipo_id
    and   bil.bil_id=bilElem.bil_id
    and   per.periodo_id=bil.periodo_id;

	annoBilancio:=((annoBilancio::INTEGER)+1)::varchar;

	case
      when tipoCapitolo=CAP_UP_TIPO then
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UP_TIPO||
    				  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
	    select * into stanzEffettivoRec
		from fnc_siac_stanz_effettivo_up_anno (id_in,annoBilancio);

		/* SIAC-7349 10:44
			sia per UP che per UG, il calcolo dell'impegnato ai fini del Calcolo della disponibilita' a variare
			dobbiamo restituire le ECONB ma non le modifiche negative provvisorie 
			-> modif<0 provvisorie non riconteggiate, danno disp. al capitolo
		*/
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UP_TIPO||
    	              '.Calcolo impegnato per anno='||annobilancio||'.';
	    select * into diCuiImpegnatoRec
    	from fnc_siac_dicuiimpegnatoup_comp_anno (id_in,annoBilancio, false);
--    	from fnc_siac_dicuiimpegnatoup_comp_anno (id_in,annoBilancio); -- SIAC-7349

        dispVariare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;
      when  tipoCapitolo=CAP_EP_TIPO then
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_EP_TIPO||
    				  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
	    select * into stanzEffettivoRec
		from fnc_siac_stanz_effettivo_ep_anno (id_in,annoBilancio);

		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_EP_TIPO||
    	              '.Calcolo accertato per anno='||annobilancio||'.';
	    select * into diCuiAccertatoRec
    	from fnc_siac_dicuiaccertatoep_comp_anno (id_in,annoBilancio);

        dispVariare:=stanzEffettivoRec.stanzEffettivo-diCuiAccertatoRec.diCuiAccertato;
      when tipoCapitolo=CAP_UG_TIPO then
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UG_TIPO||
    				  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
	    select * into stanzEffettivoRec
		from fnc_siac_stanz_effettivo_ug_anno (id_in,annoBilancio);

		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UG_TIPO||
    	              '.Calcolo impegnato per anno='||annobilancio||'.';
	    select * into diCuiImpegnatoRec
    	from fnc_siac_dicuiimpegnatoug_comp_anno (id_in,annoBilancio, false);
        dispVariare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;
      when tipoCapitolo=CAP_EG_TIPO then
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_EG_TIPO||
    				  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
	    select * into stanzEffettivoRec
		from fnc_siac_stanz_effettivo_eg_anno (id_in,annoBilancio);

		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_EG_TIPO||
    	              '.Calcolo accertato per anno='||annobilancio||'.';
	    select * into diCuiAccertatoRec
    	from fnc_siac_dicuiaccertatoeg_comp_anno (id_in,annoBilancio);

        dispVariare:=stanzEffettivoRec.stanzEffettivo-diCuiAccertatoRec.diCuiAccertato;
    end case;

return dispVariare;

exception
   when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return -1;
   when too_many_rows then
    	RAISE EXCEPTION '% Diversi records presenti in archivio.',strMessaggio;
        return -1;
   when no_data_found then
			RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return -1;
   when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return -1;
END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_disponibilitavariare_anno2(integer)
    OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariare_anno2(integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariare_anno2(integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariare_anno2(integer) TO siac;
--end fnc_siac_disponibilitavariare_anno2

--Start fnc_siac_disponibilitavariare_anno3
DROP FUNCTION if exists siac.fnc_siac_disponibilitavariare_anno3(integer);
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitavariare_anno3(
	id_in integer)
    RETURNS numeric
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE

CAP_UG_TIPO constant varchar:='CAP-UG';
CAP_UP_TIPO constant varchar:='CAP-UP';

CAP_EG_TIPO constant varchar:='CAP-EG';
CAP_EP_TIPO constant varchar:='CAP-EP';

dispImpegnare numeric:=0;
dispAccertare numeric:=0;
dispVariare   numeric:=0;
annoBilancio  varchar:=null;
tipoCapitolo  varchar:=null;

stanzEffettivoRec record;
diCuiImpegnatoRec record;
diCuiAccertatoRec record;

strMessaggio varchar(1500):=null;
BEGIN

	strMessaggio:='Calcolo disponibile variare elem_id='||id_in||'.';

	strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
    			  '.Lettura anno di bilancio e tipo elemento bilancio.';
	select per.anno, tipo.elem_tipo_code into strict annoBilancio, tipoCapitolo
	from siac_t_bil_elem bilElem,siac_d_bil_elem_tipo tipo,
         siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in
    and   bilElem.data_cancellazione is null and bilElem.validita_fine is null
    and   tipo.elem_tipo_id=bilElem.elem_tipo_id
    and   bil.bil_id=bilElem.bil_id
    and   per.periodo_id=bil.periodo_id;

	annoBilancio:=((annoBilancio::INTEGER)+2)::varchar;

	case
      when tipoCapitolo=CAP_UP_TIPO then
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UP_TIPO||
    				  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
	    select * into stanzEffettivoRec
		from fnc_siac_stanz_effettivo_up_anno (id_in,annoBilancio);

		/* SIAC-7349 10:44
			sia per UP che per UG, il calcolo dell'impegnato ai fini del Calcolo della disponibilita' a variare
			dobbiamo restituire le ECONB ma non le modifiche negative provvisorie 
			-> modif<0 provvisorie non riconteggiate, danno disp. al capitolo
		*/
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UP_TIPO||
    	              '.Calcolo impegnato per anno='||annobilancio||'.';
	    select * into diCuiImpegnatoRec
    	from fnc_siac_dicuiimpegnatoup_comp_anno (id_in,annoBilancio, false); --SIAC-7349
		-- from fnc_siac_dicuiimpegnatoup_comp_anno (id_in,annoBilancio);

        dispVariare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;
      when  tipoCapitolo=CAP_EP_TIPO then
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_EP_TIPO||
    				  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
	    select * into stanzEffettivoRec
		from fnc_siac_stanz_effettivo_ep_anno (id_in,annoBilancio);

		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_EP_TIPO||
    	              '.Calcolo accertato per anno='||annobilancio||'.';
	    select * into diCuiAccertatoRec
    	from fnc_siac_dicuiaccertatoep_comp_anno (id_in,annoBilancio);

        dispVariare:=stanzEffettivoRec.stanzEffettivo-diCuiAccertatoRec.diCuiAccertato;
      when tipoCapitolo=CAP_UG_TIPO then
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UG_TIPO||
    				  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
	    select * into stanzEffettivoRec
		from fnc_siac_stanz_effettivo_ug_anno (id_in,annoBilancio);

		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_UG_TIPO||
    	              '.Calcolo impegnato per anno='||annobilancio||'.';
	    select * into diCuiImpegnatoRec
    	from fnc_siac_dicuiimpegnatoug_comp_anno (id_in,annoBilancio, false);

        dispVariare:=stanzEffettivoRec.stanzEffettivo-diCuiImpegnatoRec.diCuiImpegnato;
      when tipoCapitolo=CAP_EG_TIPO then
		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_EG_TIPO||
    				  '.Calcolo stanziamento effettivo per anno='||annoBilancio||'.';
	    select * into stanzEffettivoRec
		from fnc_siac_stanz_effettivo_eg_anno (id_in,annoBilancio);

		strMessaggio:='Calcolo disponibile variare elem_id='||id_in||
        	          'Tipo elemento di bilancio='||CAP_EG_TIPO||
    	              '.Calcolo accertato per anno='||annobilancio||'.';
	    select * into diCuiAccertatoRec
    	from fnc_siac_dicuiaccertatoeg_comp_anno (id_in,annoBilancio);

        dispVariare:=stanzEffettivoRec.stanzEffettivo-diCuiAccertatoRec.diCuiAccertato;
    end case;

return dispVariare;

exception
   when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return -1;
   when too_many_rows then
    	RAISE EXCEPTION '% Diversi records presenti in archivio.',strMessaggio;
        return 0;
   when no_data_found then
			RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return -1;
   when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return -1;
END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_disponibilitavariare_anno3(integer)
    OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariare_anno3(integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariare_anno3(integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_disponibilitavariare_anno3(integer) TO siac;
--end fnc_siac_disponibilitavariare_anno3

--Start fnc_siac_impegnatodefinitivoup_comp_annisucc_nostanz
/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- DROP FUNCTION fnc_siac_impegnatodefinitivoup_comp_annisucc_nostanz(integer,integer[]);
CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp_annisucc_nostanz (
  id_in integer,
  idcomp_in INT [])
RETURNS TABLE (
  elemdetcompid integer,
  elemdetcompdesc character varying,
  impegnatodefinitivo numeric,
  elemdetcompmacrotipodesc character varying
) AS
$body$
DECLARE


annoBilancio varchar:=null;
annoEsercizio varchar:=null;
annoMovimento varchar:=null;

elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;
NVL_STR     constant varchar:='';
faseOpCode varchar(20):=NVL_STR;
bilancioId integer:=0;
elemTipoCode VARCHAR(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;
enteProprietarioId INTEGER:=0;
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
FASE_OP_BIL_PREV constant VARCHAR:='P';
STATO_A     constant varchar:='A';
STATO_P     constant varchar:='P';
TIPO_IMP    constant varchar:='I';
movGestStatoIdAnnullato integer:=0;
movGestStatoIdProvvisorio integer:=0;
movGestTipoId integer:=0;
IMPORTO_ATT constant varchar:='A';
movGestTsDetTipoId integer:=0;
IMPORTO_INIZIALE constant varchar:='I';
movGestTsDetTipoIdIniziale integer:=0;
STATO_MOD_V  constant varchar:='V';
modStatoVId integer:=0;
attoAmmStatoPId integer:=0;
STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoCurAttuale numeric:=0;
esisteRmovgestidelemid INTEGER:=0;
importoModifDelta  numeric:=0;
importoModifINS numeric:=0; --aggiunta per ECONB
impegniDaRibaltamento integer:=0;
pluriennaliDaRibaltamento integer:=0;
flagNMaggioreNPiu2 integer:=0;
flagDeltaPagamenti integer:=0;
importoImpegnato numeric:=0;
importoPagatoDelta numeric:=0;
ordStatoAId          integer:=null;
ordTsDetTipoAId      integer:=null;
-- stati ordinativi
STATO_ORD_A    constant varchar:='A'; -- ANNULLATO
-- importoAttuale ordinativi
ORD_TS_DET_TIPO_A  constant varchar:='A';

sidcomp_in  varchar:=null;
strMessaggio varchar(1500):=null;

impComponenteRec record;

BEGIN

/* Calcola impegnato definitivo per quelle componenti per le quali pur non essendoci stanziamento
 * esistono quote di impegnato nell'anno > N+2 
 * Le componenti per le quali esiste stanziamento (e quindi da non considerare) sono passate in input nell'array idcomp_in
 * NOTA: per problemi Java/Hibernate idcomp_in non puo' essere un array vuoto, quindi 
 *		l'array in input conterra' sempre la componente fittizia idcomp = -1
 */
-- CALCOLO IMPEGNATO DEFINITIVO 
-- Stiamo sempre parlando di impegnato sul capitolo di gestione equivalente	

	sidcomp_in:=array_to_string(idcomp_in, ',');
    	strMessaggio:='Calcolo totale impegnato definitovo elem_id='||id_in|| ' escludo idcomp_in='||sidcomp_in|| '.';

	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;
 
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||
    			  '.Lettura anno di bilancio del capitolo UP.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;
		  

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||
    			  '. Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId e elem_tipo_code.';
	 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
	 into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
	 from 	siac_t_bil_elem bilElem, 
	 		siac_d_bil_elem_tipo tipoBilElem,
		  	siac_t_bil bil, siac_t_periodo per
	 where bilElem.elem_id=id_in
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
	   and bil.bil_id=bilElem.bil_id
	   and per.periodo_id=bil.periodo_id;

	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UP then
			RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
	 end if;

	 strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||
				   '. Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   'Calcolo fase operativa per bilancioId='||bilancioId
				   ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select  faseOp.fase_operativa_code into  faseOpCode
	 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
	 where bilFase.bil_id =bilancioId
	   and bilfase.data_cancellazione is null
	   and bilFase.validita_fine is null
	   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
	   and faseOp.data_cancellazione is null
	 order by bilFase.bil_fase_operativa_id desc;

	 if NOT FOUND THEN
	   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
	 end if;

	 strMessaggio:='Calcolo impegnato definitivo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO'
				  ||'. Calcolo movGestTsStatoIdProvvisorio per movgest_stato_code=PROVVISORIO';

	 select movGestStato.movgest_stato_id into strict movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;

	 select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_P; 
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTsDetTipoId per movgest_ts_det_tipo_code=IMPORTO ATTUALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE;
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
              ||'. Calcolo modStatoVId per mod_stato_code=VALIDO.';
	 select d.mod_stato_id into strict modStatoVId
	 from siac_d_modifica_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.mod_stato_code=STATO_MOD_V;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	 select d.attoamm_stato_id into strict attoAmmStatoPId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_P;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINITIVO';
	 select d.attoamm_stato_id into strict attoAmmStatoDId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_D;

 	-- Calcolo Impegnato definitivo - Anno > N+2:
	-- - Se presenti i movimenti gestione provenienti dal ribaltamento 
	--		Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente e anno movimento > N+2 e anno esercizio N
	-- - Se non presenti i movimenti gestione provenienti dal ribaltamento 
	-- 		Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente e anno movimento > N+2 e anno esercizio N-1
	-- Il capitolo usato per determinare gli impegni   quello UG Equivalente 

	-- Verifica se presenti i movimenti di gestione provenienti dal ribaltamento
	-- Per "ribaltamento" si intende  il batch di ribaltamento residui che gira prima del ROR 
	--	e che "copia" gli impegni dell'anno N-1 nel bilancio dell'anno N (di solito il 2 gennaio)
	-- Per verificare che il batch di ribaltamento sia stato eseguito controllo le seguenti tabelle
	-- 		fase_bil_t_gest_apertura_liq_imp per gli impegni residui
	--  	fase_bil_t_gest_apertura_pluri per i pluriennli (sia impegni che accertamenti)
	-- In entrambe c'e' sia il bil_id che il bil_id_orig ovvero l'anno nuovo su cui si stanno ribaltando i movimenti e l'anno prec
	-- c'e' anche un campo fl_elab che ti dice se i dati sono stati elaborati con scarto o con successo 

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
				 '.Verifica se presenti i movimenti di gestione provenienti dal ribaltamento per anno di esercizio N.';
	
	impegniDaRibaltamento:=0;
	pluriennaliDaRibaltamento:=0;
	importoCurAttuale:=0;	
	importoModifDelta:=0;
	importoModifINS := 0;
	
	select  count(*) into impegniDaRibaltamento 
	from fase_bil_t_gest_apertura_liq_imp fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;

	select  count(*) into  pluriennaliDaRibaltamento
	from fase_bil_t_gest_apertura_pluri fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;
				
	if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then

	-- - Se presenti i movimenti gestione provenienti dal ribaltamento 
	-- ImpegnatoDefinitivo = Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in 
	-- e anno movimento > N+2 e anno esercizio N

		annoEsercizio:=annoBilancio;
		annoMovimento:=((annoBilancio::INTEGER)+2)::varchar;
		flagNMaggioreNPiu2:=1;
	else

		-- - Se non presenti i movimenti gestione provenienti dal ribaltamento 
		-- 	ImpegnatoDefinitivo = Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in 
		-- 	e anno movimento > N+2 e anno esercizio N-1

		annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
		annoMovimento:=((annoBilancio::INTEGER)+2)::varchar;
		flagNMaggioreNPiu2:=1;
	end if;
	
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    	-- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo impegnato competenza UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else
	
		strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento|| 
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid 
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno>annoMovimento::integer 
			and NOT (el.elem_det_comp_tipo_id = ANY( idcomp_in)) --SIAC-7349
			;
		
		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;
	
		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

/*			importoCurAttuale:=0;			
			select tb.importo into importoCurAttuale
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
				  NOT ( a.elem_det_comp_tipo_id = ANY( idcomp_in))--SIAC-7349 non deve essere sulla componente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno > annoMovimento::integer -- anno dell impegno > annoMovimento 
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;		
*/

			/* Versione con group by per le componenti non da escludere e ciclo per ogni componente */
			for impComponenteRec in
			 (
				select tb.elem_det_comp_tipo_id as compId, 
				 g.elem_det_comp_tipo_desc as compDesc, 
				 tb.importo as importoCurAttuale,
				 h.elem_det_comp_macro_tipo_desc as compMacroTipoDesc 
				 -- tb.importo into importoCurAttuale
				from (
				  select
					  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id, a.elem_det_comp_tipo_id
				  from
					  siac_r_movgest_bil_elem a,
					  siac_t_movgest b,
					  siac_t_movgest_ts c,
					  siac_r_movgest_ts_stato d,
					  siac_t_movgest_ts_det e,
					  siac_d_movgest_ts_det_tipo f
				  where
					  b.movgest_id=a.movgest_id 
					  and a.elem_id=elemIdGestEq 
					  and NOT( a.elem_det_comp_tipo_id = ANY(idcomp_in)) --SIAC-7349 --id componente diversa da quella ricevuta in input
					  and b.bil_id = bilIdElemGestEq
					  and b.movgest_tipo_id=movGestTipoId
					  and d.movgest_stato_id<>movGestStatoIdAnnullato
					  -- SIAC-7737 GS 31/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				      -- and d.movgest_stato_id<>movGestStatoIdProvvisorio
					  and b.movgest_anno > annoMovimento::integer -- per gli anni oltre N+2
					  and c.movgest_id=b.movgest_id
					  and d.movgest_ts_id=c.movgest_ts_id
					  and d.validita_fine is null
					  and e.movgest_ts_id=c.movgest_ts_id
					  and a.data_cancellazione is null
					  and b.data_cancellazione is null
					  and c.data_cancellazione is null
					  and e.data_cancellazione is null
					  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
					  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId
					  group by 	c.movgest_ts_tipo_id, 
								a.elem_det_comp_tipo_id -- SIAC-7349
						) tb, 
					siac_d_movgest_ts_tipo t,
					siac_d_bil_elem_det_comp_tipo g,
				 	siac_d_bil_elem_det_comp_macro_tipo h
				where 
					tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
					and g.elem_det_comp_tipo_id = tb.elem_det_comp_tipo_id --SIAC-7349 recupera anche la descrizione della componente
					and g.elem_det_comp_macro_tipo_id = h.elem_det_comp_macro_tipo_id --SIAC-7349 recupera anche la descrizione del macrotipo della componente
				 order by t.movgest_ts_tipo_code desc
 			) 
			loop
			

					-- 02.02.2016 Sofia JIRA 2947
					 if impComponenteRec.importoCurAttuale is null then impComponenteRec.importoCurAttuale:=0; end if;

					 -- 16.03.2017 Sofia JIRA-SIAC-4614
					-- if importoCurAttuale>0 then
					 if impComponenteRec.importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

						strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'  impComponenteRec.compId='||impComponenteRec.compId||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Calcolo totale modifiche su atti provvisori per annoMovimento='||annoMovimento||'.';

						select tb.importo into importoModifDelta
						 from
						 (
							select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
							from siac_r_movgest_bil_elem rbil, 
								 siac_t_movgest mov,
								 siac_t_movgest_ts ts,
								 siac_r_movgest_ts_stato rstato,
								 siac_t_movgest_ts_det tsdet,
								 siac_t_movgest_ts_det_mod moddet,
								 siac_t_modifica mod, 
								 siac_r_modifica_stato rmodstato,
								 siac_r_atto_amm_stato attostato, 
								 siac_t_atto_amm atto,
								 siac_d_modifica_tipo tipom
							where 
								rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
								and rbil.elem_det_comp_tipo_id=impComponenteRec.compId --SIAC-7349 deve essere sulla compoenente del record 
								and	  mov.movgest_id=rbil.movgest_id
								and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
								and   mov.movgest_anno>annoMovimento::integer -- anno dell impegno = annoMovimento 
								and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
								and   ts.movgest_id=mov.movgest_id
								and   rstato.movgest_ts_id=ts.movgest_ts_id
								and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
								-- SIAC-7737 GS 31/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
							    -- and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
								and   tsdet.movgest_ts_id=ts.movgest_ts_id
								and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
								and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
								-- SIAC-7349 Prendo tutti gli importi, sia con segno negativo che con segno positivo
								-- La loro somma produce il valore importoModifDelta che devo sottrarre all'impegnato calcolato
								-- ad esempio: modifiche su atto provv +100, -322 -> somma -222 si tratta di un delta che devo sottrarre
								-- all'impegnato calcolato = impegnato calcolato - (-222) = +222 (aggiungo quello che avevo tolto)
								-- and   moddet.movgest_ts_det_importo<0 -- importo negativo
								and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
								and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
								and   mod.mod_id=rmodstato.mod_id
								and   atto.attoamm_id=mod.attoamm_id
								and   attostato.attoamm_id=atto.attoamm_id
								and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
								and   tipom.mod_tipo_id=mod.mod_tipo_id
								and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
								-- date
								and rbil.data_cancellazione is null
								and rbil.validita_fine is null
								and mov.data_cancellazione is null
								and mov.validita_fine is null
								and ts.data_cancellazione is null
								and ts.validita_fine is null
								and rstato.data_cancellazione is null
								and rstato.validita_fine is null
								and tsdet.data_cancellazione is null
								and tsdet.validita_fine is null
								and moddet.data_cancellazione is null
								and moddet.validita_fine is null
								and mod.data_cancellazione is null
								and mod.validita_fine is null
								and rmodstato.data_cancellazione is null
								and rmodstato.validita_fine is null
								and attostato.data_cancellazione is null
								and attostato.validita_fine is null
								and atto.data_cancellazione is null
								and atto.validita_fine is null
								group by ts.movgest_ts_tipo_id
							  ) tb, siac_d_movgest_ts_tipo tipo
							  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
							  order by tipo.movgest_ts_tipo_code desc
							  limit 1;		

						if importoModifDelta is null then importoModifDelta:=0; end if;
						  /*Aggiunta delle modifiche ECONB*/
						 -- anna_economie inizio
						select tb.importo into importoModifINS
						from
						(
							select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
							from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
							siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
							siac_t_movgest_ts_det_mod moddet,
							siac_t_modifica mod, siac_r_modifica_stato rmodstato,
							siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
							siac_d_modifica_tipo tipom
						where rbil.elem_id=elemIdGestEq
						and rbil.elem_det_comp_tipo_id=impComponenteRec.compId --SIAC-7349
						and	  mov.movgest_id=rbil.movgest_id
						and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
						and   mov.movgest_anno=annoMovimento::integer
						and   mov.bil_id=bilancioId
						and   ts.movgest_id=mov.movgest_id
						and   rstato.movgest_ts_id=ts.movgest_ts_id
						and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- impegno non annullato
						and   tsdet.movgest_ts_id=ts.movgest_ts_id
						and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
						and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
					   and   tipom.mod_tipo_id=mod.mod_tipo_id
					   and   tipom.mod_tipo_code = 'ECONB'
						-- date
						and rbil.data_cancellazione is null
						and rbil.validita_fine is null
						and mov.data_cancellazione is null
						and mov.validita_fine is null
						and ts.data_cancellazione is null
						and ts.validita_fine is null
						and rstato.data_cancellazione is null
						and rstato.validita_fine is null
						and tsdet.data_cancellazione is null
						and tsdet.validita_fine is null
						and moddet.data_cancellazione is null
						and moddet.validita_fine is null
						and mod.data_cancellazione is null
						and mod.validita_fine is null
						and rmodstato.data_cancellazione is null
						and rmodstato.validita_fine is null
						and attostato.data_cancellazione is null
						and attostato.validita_fine is null
						and atto.data_cancellazione is null
						and atto.validita_fine is null
					   group by ts.movgest_ts_tipo_id
					 ) tb, siac_d_movgest_ts_tipo tipo
					 where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
					 order by tipo.movgest_ts_tipo_code desc
					 limit 1;

					 if importoModifINS is null then 
						importoModifINS = 0;
					 end if;


					end if;		
	
			--Fix MR adeguamento sprint 5
			-- Mon restituiamo piu' al valore impegnato le modifiche provvisorie e le ECONB
           		importoModifDelta:=0;
            		importoModifINS:=0;
            --
			elemDetCompId:=impComponenteRec.compId;
			elemdetcompdesc:=impComponenteRec.compDesc;
			elemdetcompmacrotipodesc:=impComponenteRec.compMacroTipoDesc;
			impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente  
			impegnatoDefinitivo:=impegnatoDefinitivo+impComponenteRec.importoCurAttuale-(importoModifDelta);
			--aggiunta per ECONB
			impegnatoDefinitivo:=impegnatoDefinitivo+abs(importoModifINS);
			return next;	



	end loop;
	end if;
	end if;

	return;
 

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
		return;
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
PARALLEL UNSAFE
COST 100 ROWS 1000;


ALTER FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp_annisucc_nostanz (id_in integer, idcomp_in integer [])
  OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp_annisucc_nostanz (id_in integer, idcomp_in integer []) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp_annisucc_nostanz (id_in integer, idcomp_in integer []) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp_annisucc_nostanz (id_in integer, idcomp_in integer []) TO siac;
-- end fnc_siac_impegnatodefinitivoup_comp_annisucc_nostanz

--Start fnc_siac_impegnatodefinitivoup_comp

CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp (
  id_in integer,
  idcomp_in integer
)
RETURNS TABLE (
  indiceannualita integer,
  elemdetcompid integer,
  impegnatodefinitivo numeric
) AS
$body$
DECLARE

annoBilancio varchar:=null;
annoEsercizio varchar:=null;
annoMovimento varchar:=null;

elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;
NVL_STR     constant varchar:='';
faseOpCode varchar(20):=NVL_STR;
bilancioId integer:=0;
elemTipoCode VARCHAR(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;
enteProprietarioId INTEGER:=0;
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
FASE_OP_BIL_PREV constant VARCHAR:='P';
STATO_A     constant varchar:='A';
STATO_P     constant varchar:='P';
TIPO_IMP    constant varchar:='I';
movGestStatoIdAnnullato integer:=0;
movGestStatoIdProvvisorio integer:=0;
movGestTipoId integer:=0;
IMPORTO_ATT constant varchar:='A';
movGestTsDetTipoId integer:=0;
IMPORTO_INIZIALE constant varchar:='I';
movGestTsDetTipoIdIniziale integer:=0;
STATO_MOD_V  constant varchar:='V';
modStatoVId integer:=0;
attoAmmStatoPId integer:=0;
STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoCurAttuale numeric:=0;
esisteRmovgestidelemid INTEGER:=0;
importoModifDelta  numeric:=0;
importoModifINS numeric:=0; --aggiunta per ECONB
impegniDaRibaltamento integer:=0;
pluriennaliDaRibaltamento integer:=0;
flagNMaggioreNPiu2 integer:=0;
flagDeltaPagamenti integer:=0;
importoImpegnato numeric:=0;
importoPagatoDelta numeric:=0;
ordStatoAId          integer:=null;
ordTsDetTipoAId      integer:=null;
-- stati ordinativi
STATO_ORD_A    constant varchar:='A'; -- ANNULLATO
-- importoAttuale ordinativi
ORD_TS_DET_TIPO_A  constant varchar:='A';

strMessaggio varchar(1500):=null;
BEGIN

    strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in|| 'idcomp_in='||idcomp_in|| '.';

	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;
	if idcomp_in is null or idcomp_in=0 then
		 RAISE EXCEPTION '% Identificativo componente mancante.',strMessaggio;
	end if;
 
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
    			  '.Lettura anno di bilancio del capitolo UP.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;
		  

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
    			  '. Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId e elem_tipo_code.';
	 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
	 into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
	 from 	siac_t_bil_elem bilElem, 
	 		siac_d_bil_elem_tipo tipoBilElem,
		  	siac_t_bil bil, siac_t_periodo per
	 where bilElem.elem_id=id_in
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
	   and bil.bil_id=bilElem.bil_id
	   and per.periodo_id=bil.periodo_id;

	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UP then
			RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
	 end if;

	 strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				   '. Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   'Calcolo fase operativa per bilancioId='||bilancioId
				   ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select  faseOp.fase_operativa_code into  faseOpCode
	 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
	 where bilFase.bil_id =bilancioId
	   and bilfase.data_cancellazione is null
	   and bilFase.validita_fine is null
	   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
	   and faseOp.data_cancellazione is null
	 order by bilFase.bil_fase_operativa_id desc;

	 if NOT FOUND THEN
	   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
	 end if;

	 strMessaggio:='Calcolo impegnato definitivo elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO'
				  ||'. Calcolo movGestTsStatoIdProvvisorio per movgest_stato_code=PROVVISORIO';

	 select movGestStato.movgest_stato_id into strict movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;

	 select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_P; 
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo movGestTsDetTipoId per movgest_ts_det_tipo_code=IMPORTO ATTUALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE;
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
              ||'. Calcolo modStatoVId per mod_stato_code=VALIDO.';
	 select d.mod_stato_id into strict modStatoVId
	 from siac_d_modifica_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.mod_stato_code=STATO_MOD_V;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	 select d.attoamm_stato_id into strict attoAmmStatoPId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_P;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||idcomp_in
				  ||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINITIVO';
	 select d.attoamm_stato_id into strict attoAmmStatoDId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_D;

 
--- CICLO SU TUTTE LE POSSIBILI ANNUALITA': N-1, N, N+1, N+2 e >N+2
FOR loop_counter IN  0..6  LOOP
CASE loop_counter

 WHEN 0 THEN
	-- Calcolo Impegnato definitivo - Anno N-1: 
	-- Sommatoria di tutti gli Impegni assunti sul capitolo di previsione id_in su Componente idcomp_in
	-- con anno movimento N-1 e anno esercizio N-1.
	-- Il capitolo usato per determinare gli impegni e' quello UG Equivalente gia' esistente nel bilancio dell'esercizio N-1
	-- I valori di impegnato dovranno essere calcolati tenendo conto del solo impegnato definitivo.
	-- Escluse dal calcolo quindi:
	--		- le modifiche di impegno provvisorie (modifiche con provvedimento in stato provvisorio - di qualsiasi segno)
	-- 		- gli  impegni in stato provvisorio

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
    			  '.Determina anno esercizio ed anno movimento per i quali calcolare.';

    annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
    annoMovimento:=((annoBilancio::INTEGER)-1)::varchar;
    
	flagNMaggioreNPiu2:=0;
	
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    -- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo impegnato competenza UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else

		strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento|| 
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid 
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno=annoMovimento::integer
			and el.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
			;
		
		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;
		
		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

			importoCurAttuale:=0;			
			select tb.importo into importoCurAttuale
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
				  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  -- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  -- and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno = annoMovimento::integer -- anno dell impegno = annoMovimento
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;		

			-- 02.02.2016 Sofia JIRA 2947
			 if importoCurAttuale is null then importoCurAttuale:=0; end if;

			 -- 16.03.2017 Sofia JIRA-SIAC-4614
			-- if importoCurAttuale>0 then
			 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

				strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Calcolo totale modifiche su atti provvisori per annoMovimento='||annoMovimento||'.';

				select tb.importo into importoModifDelta
				 from
				 (
					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, 
					 	 siac_t_movgest mov,
					 	 siac_t_movgest_ts ts,
						 siac_r_movgest_ts_stato rstato,
					  	 siac_t_movgest_ts_det tsdet,
						 siac_t_movgest_ts_det_mod moddet,
						 siac_t_modifica mod, 
					 	 siac_r_modifica_stato rmodstato,
						 siac_r_atto_amm_stato attostato, 
					 	 siac_t_atto_amm atto,
						 siac_d_modifica_tipo tipom
					where 
						rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
						and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
						and	  mov.movgest_id=rbil.movgest_id
						and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
						and   mov.movgest_anno=annoMovimento::integer -- anno dell impegno = annoMovimento
						and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
						and   ts.movgest_id=mov.movgest_id
						and   rstato.movgest_ts_id=ts.movgest_ts_id
						and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
						-- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  		--and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
					    and   tsdet.movgest_ts_id=ts.movgest_ts_id
						and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
						and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
						and   tipom.mod_tipo_id=mod.mod_tipo_id
						and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
						-- date
						and rbil.data_cancellazione is null
						and rbil.validita_fine is null
						and mov.data_cancellazione is null
						and mov.validita_fine is null
						and ts.data_cancellazione is null
						and ts.validita_fine is null
						and rstato.data_cancellazione is null
						and rstato.validita_fine is null
						and tsdet.data_cancellazione is null
						and tsdet.validita_fine is null
						and moddet.data_cancellazione is null
						and moddet.validita_fine is null
						and mod.data_cancellazione is null
						and mod.validita_fine is null
						and rmodstato.data_cancellazione is null
						and rmodstato.validita_fine is null
						and attostato.data_cancellazione is null
						and attostato.validita_fine is null
						and atto.data_cancellazione is null
						and atto.validita_fine is null
						group by ts.movgest_ts_tipo_id
					  ) tb, siac_d_movgest_ts_tipo tipo
					  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
					  order by tipo.movgest_ts_tipo_code desc
					  limit 1;		
					  
 				if importoModifDelta is null then importoModifDelta:=0; end if;
				 /*Aggiunta delle modifiche ECONB*/
				 -- anna_economie inizio
   				select tb.importo into importoModifINS
 				from
 				(
 					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
 			   	 	siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
				    siac_t_movgest_ts_det_mod moddet,
 			   	 	siac_t_modifica mod, siac_r_modifica_stato rmodstato,
				    siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
 			        siac_d_modifica_tipo tipom
				where rbil.elem_id=elemIdGestEq
				and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
				and	  mov.movgest_id=rbil.movgest_id
				and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
 			   	and   mov.movgest_anno=annoMovimento::integer
 			   	and   mov.bil_id=bilancioId
				and   ts.movgest_id=mov.movgest_id
				and   rstato.movgest_ts_id=ts.movgest_ts_id
				and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- impegno non annullato
				and   tsdet.movgest_ts_id=ts.movgest_ts_id
				and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
				and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
				and   moddet.movgest_ts_det_importo<0 -- importo negativo
				and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
				and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
				and   mod.mod_id=rmodstato.mod_id
				and   atto.attoamm_id=mod.attoamm_id
				and   attostato.attoamm_id=atto.attoamm_id
				and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
 			   and   tipom.mod_tipo_id=mod.mod_tipo_id
 			   and   tipom.mod_tipo_code = 'ECONB'
				-- date
				and rbil.data_cancellazione is null
				and rbil.validita_fine is null
				and mov.data_cancellazione is null
				and mov.validita_fine is null
				and ts.data_cancellazione is null
				and ts.validita_fine is null
				and rstato.data_cancellazione is null
				and rstato.validita_fine is null
				and tsdet.data_cancellazione is null
				and tsdet.validita_fine is null
				and moddet.data_cancellazione is null
				and moddet.validita_fine is null
				and mod.data_cancellazione is null
				and mod.validita_fine is null
				and rmodstato.data_cancellazione is null
				and rmodstato.validita_fine is null
				and attostato.data_cancellazione is null
				and attostato.validita_fine is null
				and atto.data_cancellazione is null
				and atto.validita_fine is null
 			   group by ts.movgest_ts_tipo_id
 			 ) tb, siac_d_movgest_ts_tipo tipo
 			 where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
 			 order by tipo.movgest_ts_tipo_code desc
 			 limit 1;
			 
			 if importoModifINS is null then 
			 	importoModifINS = 0;
			 end if;
			
		
			end if;		
		end if;
	end if;

	-- restituisco il record risultato
	indiceAnnualita:=loop_counter;
	elemDetCompId:=idcomp_in;
    	--FIX adeguamento SIAC-7349 SPRINT 5
	-- Non restituisco piu' al impegnato le modifiche provvisorie e le ECONB
    	importoModifINS:=0;
    	importoModifDelta:=0;
    	--
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente per l'anno N-1
    	impegnatoDefinitivo:=impegnatoDefinitivo+importoCurAttuale-(importoModifDelta);

	--aggiunta per ECONB
	impegnatoDefinitivo:=impegnatoDefinitivo+abs(importoModifINS);

	return next;

	
	
 WHEN 1,2,3 THEN
 	-- Calcolo Impegnato definitivo - Anno N: 
	-- - Se presenti i movimenti gestione provenienti dal ribaltamento:
	--		Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in e anno movimento N e anno esercizio N
	-- - Se non presenti i movimenti gestione provenienti dal ribaltamento
	--		Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in e anno movimento N e anno esercizio N-1  

	-- Calcolo Impegnato definitivo   Anno N+1: 
	-- - Se presenti i movimenti gestione provenienti dal ribaltamento 
	--	 	Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in e anno movimento N+1 e anno esercizio N
	-- - Se non presenti i movimenti gestione provenienti dal ribaltamento 
	--		Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in e anno movimento N+1 e anno esercizio N-1

	-- Calcolo Impegnato definitivo   Anno N+2: 
	-- - Se presenti i movimenti gestione provenienti dal ribaltamento
	--		Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in e anno movimento N+2 e anno esercizio N
	-- - Se non presenti i movimenti gestione provenienti dal ribaltamento 
	--		Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in e anno movimento N+2 e anno esercizio N-1	
	-- Il capitolo usato per determinare gli impegni e' quello UG Equivalente  
	
	-- Verifica se presenti i movimenti di gestione provenienti dal ribaltamento
	-- Per "ribaltamento" si intende  il batch di ribaltamento residui che gira prima del ROR 
	--	e che "copia" gli impegni dell'anno N-1 nel bilancio dell'anno N (di solito il 2 gennaio)
	-- Per verificare che il batch di ribaltamento sia stato eseguito controllo le seguenti tabelle
	-- 		fase_bil_t_gest_apertura_liq_imp per gli impegni residui
	--  	fase_bil_t_gest_apertura_pluri per i pluriennli (sia impegni che accertamenti)
	-- In entrambe c'e' sia il bil_id che il bil_id_orig ovvero l'anno nuovo su cui si stanno ribaltando i movimenti e l'anno prec
	-- c'e' anche un campo fl_elab che ti dice se i dati sono stati elaborati con scarto o con successo 
	strMessaggio:='Calcolo totale impegnato  elem_id='||id_in||'idcomp_in='||idcomp_in||
				 '.Verifica se presenti i movimenti di gestione provenienti dal ribaltamento per anno di esercizio N.';
	
	impegniDaRibaltamento:=0;
	pluriennaliDaRibaltamento:=0;
	importoCurAttuale:=0;	
	importoModifDelta:=0;
	importoModifINS:=0;
	
	select  count(*) into impegniDaRibaltamento 
	from fase_bil_t_gest_apertura_liq_imp fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;

	select  count(*) into  pluriennaliDaRibaltamento
	from fase_bil_t_gest_apertura_pluri fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;
				
	if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then

		-- - Se presenti i movimenti gestione provenienti dal ribaltamento:
		--	ImpegnatoDefinitivo = 	Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in 
		--	e anno movimento [N | N+1 | N+2] e anno esercizio N

		annoEsercizio:=annoBilancio;
		annoMovimento:=((annoBilancio::INTEGER)+loop_counter-1)::varchar;
		flagNMaggioreNPiu2:=0;
	else

		-- - Se non presenti i movimenti gestione provenienti dal ribaltamento
		--	ImpegnatoDefinitivo = Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in 
		-- 	e anno movimento [N | N+1 | N+2] e anno esercizio N-1

		annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
		annoMovimento:=((annoBilancio::INTEGER)+loop_counter-1)::varchar;
		flagNMaggioreNPiu2:=0;
	end if;
	
	strMessaggio:='Calcolo totale impegnato  elem_id='||id_in||'idcomp_in='||idcomp_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
   	-- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo impegnato competenza UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else

		strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento|| 
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid 
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno=annoMovimento::integer
			and el.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
			;
		
		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;
		
		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

					
			select tb.importo into importoCurAttuale
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
				  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  -- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  --and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno = annoMovimento::integer -- anno dell impegno = annoMovimento
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;		

			-- 02.02.2016 Sofia JIRA 2947
			 if importoCurAttuale is null then importoCurAttuale:=0; end if;

			 -- 16.03.2017 Sofia JIRA-SIAC-4614
			-- if importoCurAttuale>0 then
			 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

				strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Calcolo totale modifiche su atti provvisori per annoMovimento='||annoMovimento||'.';

				select tb.importo into importoModifDelta
				 from
				 (
					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, 
					 	 siac_t_movgest mov,
					 	 siac_t_movgest_ts ts,
						 siac_r_movgest_ts_stato rstato,
					  	 siac_t_movgest_ts_det tsdet,
						 siac_t_movgest_ts_det_mod moddet,
						 siac_t_modifica mod, 
					 	 siac_r_modifica_stato rmodstato,
						 siac_r_atto_amm_stato attostato, 
					 	 siac_t_atto_amm atto,
						 siac_d_modifica_tipo tipom
					where 
						rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
						and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
						and	  mov.movgest_id=rbil.movgest_id
						and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
						and   mov.movgest_anno=annoMovimento::integer -- anno dell impegno = annoMovimento
						and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
						and   ts.movgest_id=mov.movgest_id
						and   rstato.movgest_ts_id=ts.movgest_ts_id
						and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
						-- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  		--and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
					    and   tsdet.movgest_ts_id=ts.movgest_ts_id
						and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
						and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
						and   tipom.mod_tipo_id=mod.mod_tipo_id
						and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
						-- date
						and rbil.data_cancellazione is null
						and rbil.validita_fine is null
						and mov.data_cancellazione is null
						and mov.validita_fine is null
						and ts.data_cancellazione is null
						and ts.validita_fine is null
						and rstato.data_cancellazione is null
						and rstato.validita_fine is null
						and tsdet.data_cancellazione is null
						and tsdet.validita_fine is null
						and moddet.data_cancellazione is null
						and moddet.validita_fine is null
						and mod.data_cancellazione is null
						and mod.validita_fine is null
						and rmodstato.data_cancellazione is null
						and rmodstato.validita_fine is null
						and attostato.data_cancellazione is null
						and attostato.validita_fine is null
						and atto.data_cancellazione is null
						and atto.validita_fine is null
						group by ts.movgest_ts_tipo_id
					  ) tb, siac_d_movgest_ts_tipo tipo
					  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
					  order by tipo.movgest_ts_tipo_code desc
					  limit 1;		
					  
 				if importoModifDelta is null then importoModifDelta:=0; end if;
				  /*Aggiunta delle modifiche ECONB*/
				 -- anna_economie inizio
   				select tb.importo into importoModifINS
 				from
 				(
 					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
 			   	 	siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
				    siac_t_movgest_ts_det_mod moddet,
 			   	 	siac_t_modifica mod, siac_r_modifica_stato rmodstato,
				    siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
 			        siac_d_modifica_tipo tipom
				where rbil.elem_id=elemIdGestEq
				and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
				and	  mov.movgest_id=rbil.movgest_id
				and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
 			   	and   mov.movgest_anno=annoMovimento::integer
 			   	and   mov.bil_id=bilancioId
				and   ts.movgest_id=mov.movgest_id
				and   rstato.movgest_ts_id=ts.movgest_ts_id
				and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- impegno non annullato
				and   tsdet.movgest_ts_id=ts.movgest_ts_id
				and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
				and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
				and   moddet.movgest_ts_det_importo<0 -- importo negativo
				and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
				and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
				and   mod.mod_id=rmodstato.mod_id
				and   atto.attoamm_id=mod.attoamm_id
				and   attostato.attoamm_id=atto.attoamm_id
				and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
 			   and   tipom.mod_tipo_id=mod.mod_tipo_id
 			   and   tipom.mod_tipo_code = 'ECONB'
				-- date
				and rbil.data_cancellazione is null
				and rbil.validita_fine is null
				and mov.data_cancellazione is null
				and mov.validita_fine is null
				and ts.data_cancellazione is null
				and ts.validita_fine is null
				and rstato.data_cancellazione is null
				and rstato.validita_fine is null
				and tsdet.data_cancellazione is null
				and tsdet.validita_fine is null
				and moddet.data_cancellazione is null
				and moddet.validita_fine is null
				and mod.data_cancellazione is null
				and mod.validita_fine is null
				and rmodstato.data_cancellazione is null
				and rmodstato.validita_fine is null
				and attostato.data_cancellazione is null
				and attostato.validita_fine is null
				and atto.data_cancellazione is null
				and atto.validita_fine is null
 			   group by ts.movgest_ts_tipo_id
 			 ) tb, siac_d_movgest_ts_tipo tipo
 			 where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
 			 order by tipo.movgest_ts_tipo_code desc
 			 limit 1;
			 
			 if importoModifINS is null then 
			 	importoModifINS = 0;
			 end if;

		
			end if;		
		end if;
	end if;

	indiceAnnualita:=loop_counter;
	elemDetCompId:=idcomp_in;
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente per l'anno N-1
	--FIX adeguamento SIAC-7349 SPRINT 5
	-- Non restituisco piu' le modifiche provvisorie e le ECONB al impegnato
    	importoModifINS:=0;
    	importoModifDelta:=0;
    	--
    	impegnatoDefinitivo:=impegnatoDefinitivo+importoCurAttuale-(importoModifDelta);
	--aggiunta per ECONB
	impegnatoDefinitivo:=impegnatoDefinitivo+abs(importoModifINS);
	
	return next;

 	
 WHEN 4 THEN
	-- Calcolo Impegnato definitivo - Anno > N+2:
	-- - Se presenti i movimenti gestione provenienti dal ribaltamento 
	--		Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in e anno movimento > N+2 e anno esercizio N
	-- - Se non presenti i movimenti gestione provenienti dal ribaltamento 
	-- 		Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in e anno movimento > N+2 e anno esercizio N-1
	-- Il capitolo usato per determinare gli impegni e' quello UG Equivalente  

	-- Verifica se presenti i movimenti di gestione provenienti dal ribaltamento
	-- Per "ribaltamento" si intende  il batch di ribaltamento residui che gira prima del ROR 
	--	e che "copia" gli impegni dell'anno N-1 nel bilancio dell'anno N (di solito il 2 gennaio)
	-- Per verificare che il batch di ribaltamento sia stato eseguito controllo le seguenti tabelle
	-- 		fase_bil_t_gest_apertura_liq_imp per gli impegni residui
	--  	fase_bil_t_gest_apertura_pluri per i pluriennli (sia impegni che accertamenti)
	-- In entrambe c'e' sia il bil_id che il bil_id_orig ovvero l'anno nuovo su cui si stanno ribaltando i movimenti e l'anno prec
	-- c'e' anche un campo fl_elab che ti dice se i dati sono stati elaborati con scarto o con successo 
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				 '.Verifica se presenti i movimenti di gestione provenienti dal ribaltamento per anno di esercizio N.';
	
	impegniDaRibaltamento:=0;
	pluriennaliDaRibaltamento:=0;
	importoCurAttuale:=0;	
	importoModifDelta:=0;
	importoModifINS := 0;
	
	select  count(*) into impegniDaRibaltamento 
	from fase_bil_t_gest_apertura_liq_imp fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;

	select  count(*) into  pluriennaliDaRibaltamento
	from fase_bil_t_gest_apertura_pluri fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;
				
	if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then

		-- - Se presenti i movimenti gestione provenienti dal ribaltamento 
		--	ImpegnatoDefinitivo = Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in 
		--	e anno movimento > N+2 e anno esercizio N

		annoEsercizio:=annoBilancio;
		annoMovimento:=((annoBilancio::INTEGER)+2)::varchar;
		flagNMaggioreNPiu2:=1;
	else

		-- - Se non presenti i movimenti gestione provenienti dal ribaltamento 
		-- 	ImpegnatoDefinitivo = Sommatoria di tutti gli Impegni assunti sul capitolo in questione su Componente idcomp_in 
		-- 	e anno movimento > N+2 e anno esercizio N-1

		annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
		annoMovimento:=((annoBilancio::INTEGER)+2)::varchar;
		flagNMaggioreNPiu2:=1;
	end if;

	strMessaggio:='Calcolo totale impegnato elem_id='||id_in||'idcomp_in='||idcomp_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    	-- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo impegnato competenza UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else

		strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento|| 
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid 
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno>annoMovimento::integer 
			and el.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
			;
		
		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;
		
		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

			importoCurAttuale:=0;			
			select tb.importo into importoCurAttuale
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
				  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  -- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  --and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno > annoMovimento::integer -- anno dell impegno > annoMovimento 
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;		

			-- 02.02.2016 Sofia JIRA 2947
			 if importoCurAttuale is null then importoCurAttuale:=0; end if;

			 -- 16.03.2017 Sofia JIRA-SIAC-4614
			-- if importoCurAttuale>0 then
			 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

				strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Calcolo totale modifiche su atti provvisori per annoMovimento='||annoMovimento||'.';

				select tb.importo into importoModifDelta
				 from
				 (
					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, 
					 	 siac_t_movgest mov,
					 	 siac_t_movgest_ts ts,
						 siac_r_movgest_ts_stato rstato,
					  	 siac_t_movgest_ts_det tsdet,
						 siac_t_movgest_ts_det_mod moddet,
						 siac_t_modifica mod, 
					 	 siac_r_modifica_stato rmodstato,
						 siac_r_atto_amm_stato attostato, 
					 	 siac_t_atto_amm atto,
						 siac_d_modifica_tipo tipom
					where 
						rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
						and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
						and	  mov.movgest_id=rbil.movgest_id
						and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
						and   mov.movgest_anno>annoMovimento::integer -- anno dell impegno = annoMovimento 
						and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
						and   ts.movgest_id=mov.movgest_id
						and   rstato.movgest_ts_id=ts.movgest_ts_id
						and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
						-- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  		--and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
					    and   tsdet.movgest_ts_id=ts.movgest_ts_id
						and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
						and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
						and   tipom.mod_tipo_id=mod.mod_tipo_id
						and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
						-- date
						and rbil.data_cancellazione is null
						and rbil.validita_fine is null
						and mov.data_cancellazione is null
						and mov.validita_fine is null
						and ts.data_cancellazione is null
						and ts.validita_fine is null
						and rstato.data_cancellazione is null
						and rstato.validita_fine is null
						and tsdet.data_cancellazione is null
						and tsdet.validita_fine is null
						and moddet.data_cancellazione is null
						and moddet.validita_fine is null
						and mod.data_cancellazione is null
						and mod.validita_fine is null
						and rmodstato.data_cancellazione is null
						and rmodstato.validita_fine is null
						and attostato.data_cancellazione is null
						and attostato.validita_fine is null
						and atto.data_cancellazione is null
						and atto.validita_fine is null
						group by ts.movgest_ts_tipo_id
					  ) tb, siac_d_movgest_ts_tipo tipo
					  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
					  order by tipo.movgest_ts_tipo_code desc
					  limit 1;		
					  
 				if importoModifDelta is null then importoModifDelta:=0; end if;
				  /*Aggiunta delle modifiche ECONB*/
				 -- anna_economie inizio
   				select tb.importo into importoModifINS
 				from
 				(
 					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
 			   	 	siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
				    siac_t_movgest_ts_det_mod moddet,
 			   	 	siac_t_modifica mod, siac_r_modifica_stato rmodstato,
				    siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
 			        siac_d_modifica_tipo tipom
				where rbil.elem_id=elemIdGestEq
				and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
				and	  mov.movgest_id=rbil.movgest_id
				and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
 			   	and   mov.movgest_anno=annoMovimento::integer
 			   	and   mov.bil_id=bilancioId
				and   ts.movgest_id=mov.movgest_id
				and   rstato.movgest_ts_id=ts.movgest_ts_id
				and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- impegno non annullato
				and   tsdet.movgest_ts_id=ts.movgest_ts_id
				and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
				and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
				and   moddet.movgest_ts_det_importo<0 -- importo negativo
				and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
				and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
				and   mod.mod_id=rmodstato.mod_id
				and   atto.attoamm_id=mod.attoamm_id
				and   attostato.attoamm_id=atto.attoamm_id
				and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
 			   and   tipom.mod_tipo_id=mod.mod_tipo_id
 			   and   tipom.mod_tipo_code = 'ECONB'
				-- date
				and rbil.data_cancellazione is null
				and rbil.validita_fine is null
				and mov.data_cancellazione is null
				and mov.validita_fine is null
				and ts.data_cancellazione is null
				and ts.validita_fine is null
				and rstato.data_cancellazione is null
				and rstato.validita_fine is null
				and tsdet.data_cancellazione is null
				and tsdet.validita_fine is null
				and moddet.data_cancellazione is null
				and moddet.validita_fine is null
				and mod.data_cancellazione is null
				and mod.validita_fine is null
				and rmodstato.data_cancellazione is null
				and rmodstato.validita_fine is null
				and attostato.data_cancellazione is null
				and attostato.validita_fine is null
				and atto.data_cancellazione is null
				and atto.validita_fine is null
 			   group by ts.movgest_ts_tipo_id
 			 ) tb, siac_d_movgest_ts_tipo tipo
 			 where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
 			 order by tipo.movgest_ts_tipo_code desc
 			 limit 1;
			 
			 if importoModifINS is null then 
			 	importoModifINS = 0;
			 end if;

		
			end if;		
		end if;
	end if;

	indiceAnnualita:=loop_counter;
	elemDetCompId:=idcomp_in;
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente per l'anno N-1
	--FIX adeguamento SIAC-7349 SPRINT 5
	-- Non restituiamo piu' le modifiche provvisorie e le ECONB al impegnato
    	importoModifINS:=0;
    	importoModifDelta:=0;
    	--
    	impegnatoDefinitivo:=impegnatoDefinitivo+importoCurAttuale-(importoModifDelta);
	--aggiunta per ECONB
	impegnatoDefinitivo:=impegnatoDefinitivo+abs(importoModifINS);
	return next;

 WHEN 5 THEN
	-- Calcolo Residuo Iniziale: 
	-- - Se presenti i movimenti gestione provenienti dal ribaltamento 
	--	 - Sommatoria dell importo iniziale di tutti gli Impegni assunti sul capitolo in questione su idcomp_in
	--		con anno movimento < N e anno esercizio N.
	-- - Se non presenti i movimenti gestione provenienti dal ribaltamento 
	-- 	- Sommatoria di tutti gli Impegni (valore effettivo aka finale) assunti sul capitolo in questione su incomp_in
	--		con anno movimento < N e anno esercizio N-1 diminuiti dalla sommatoria del pagato sui medesimi impegni nell esercizio N-1.

	impegniDaRibaltamento:=0;
	pluriennaliDaRibaltamento:=0;
	importoImpegnato:=0;	
	importoPagatoDelta:=0;
	
	select  count(*) into impegniDaRibaltamento 
	from fase_bil_t_gest_apertura_liq_imp fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;

	select  count(*) into  pluriennaliDaRibaltamento
	from fase_bil_t_gest_apertura_pluri fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;
				
	if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then

		-- - Se presenti i movimenti gestione provenienti dal ribaltamento 
		--	Residuo Iniziale = 
		--	 Sommatoria dell'importo iniziale di tutti gli Impegni assunti sul capitolo in questione su idcomp_in
		--	con anno movimento < N e anno esercizio N.

		annoEsercizio:=annoBilancio;
		annoMovimento:=annoBilancio;
 		flagDeltaPagamenti:=0; -- non e' necessario scomputare il pagato
		
 	else

		-- - Se non presenti i movimenti gestione provenienti dal ribaltamento 
		-- 	Residuo Iniziale =	
		--	 Sommatoria di tutti gli Impegni (valore effettivo aka finale) assunti sul capitolo in questione su incomp_in
		--	con anno movimento < N e anno esercizio N-1  
		--	diminuiti dalla sommatoria del pagato sui medesimi impegni nell'esercizio N-1.

		annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
		annoMovimento:=annoBilancio;
		flagDeltaPagamenti:=1; -- bisogna sottrarre la sommatoria del pagato sui medesimi impegni nell'esercizio N-1

	end if;

	strMessaggio:='Calcolo residuo iniziale elem_id='||id_in||'idcomp_in='||idcomp_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    -- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo residuo iniziale.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else

		strMessaggio:='Calcolo residuo iniziale elem_id='||id_in||'idcomp_in='||idcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento||'.'; 

		impegnatoDefinitivo:=0;
		strMessaggio:='Calcolo residuo iniziale elem_id='||id_in||'idcomp_in='||idcomp_in||
			'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
			'. Inizio calcolo totale importo  impegni per annoMovimento='||annoMovimento||'.';

		if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then
			--  Sommatoria dell'importo iniziale di tutti gli Impegni assunti sul capitolo in questione 
			--	su Componente X con anno movimento < N e anno esercizio N

		importoImpegnato:=0;			
		select tb.importo into importoImpegnato
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
				  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  -- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  --and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno < annoMovimento::integer -- anno dell impegno < annoMovimento 
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoIdIniziale -- considerare l'importo iniziale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;		
			-- 02.02.2016 Sofia JIRA 2947
			if importoImpegnato is null then importoImpegnato:=0; end if;

		else
			-- Sommatoria di tutti gli Impegni assunti (valore effettivo aka finale) sul capitolo in questione su Componente X 
			-- con anno movimento < N e anno esercizio N-1
			-- diminuiti dalla sommatoria del pagato sui medesimi impegni nell'esercizio N-1.
			importoImpegnato:=0;			
			select tb.importo into importoImpegnato
				from (
				  select
					  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
				  from
					  siac_r_movgest_bil_elem a,
					  siac_t_movgest b,
					  siac_t_movgest_ts c,
					  siac_r_movgest_ts_stato d,
					  siac_t_movgest_ts_det e,
					  siac_d_movgest_ts_det_tipo f
				  where
					  b.movgest_id=a.movgest_id and
					  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
					  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
					  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
					  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
					  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
					  -- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				      --and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
					  and b.movgest_anno < annoMovimento::integer -- anno dell impegno < annoMovimento 
					  and c.movgest_id=b.movgest_id
					  and d.movgest_ts_id=c.movgest_ts_id
					  and d.validita_fine is null
					  and e.movgest_ts_id=c.movgest_ts_id
					  and a.data_cancellazione is null
					  and b.data_cancellazione is null
					  and c.data_cancellazione is null
					  and e.data_cancellazione is null
					  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
					  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
					  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
				where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
				order by t.movgest_ts_tipo_code desc
				limit 1;	

			-- 16.03.2017 Sofia JIRA-SIAC-4614
			-- if importoImpegnato>0 then
			if importoImpegnato>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

				strMessaggio:='Calcolo residuo iniziale elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Calcolo sommatoria del pagato sui medesimi impegni nell''esercizio N-1.';

			   strMessaggio:='Lettura identificativo ord_stato_code='||STATO_ORD_A||'.';
			   select ordstato.ord_stato_id into ordStatoAId
			   from siac_d_ordinativo_stato ordstato
			   where ordstato.ente_proprietario_id=enteProprietarioId
			   and   ordstato.ord_stato_code=STATO_ORD_A;

			   select tipo.ord_ts_det_tipo_id into ordTsDetTipoAId
			   from siac_d_ordinativo_ts_det_tipo tipo
			   where tipo.ente_proprietario_id=enteProprietarioId
			   and   tipo.ord_ts_det_tipo_code=ORD_TS_DET_TIPO_A;

				select coalesce(sum(e.ord_ts_det_importo),0) into importoPagatoDelta
				from  
					 siac_r_movgest_bil_elem a,  --rmov,
					 siac_t_movgest b, -- mov, 
					 siac_t_movgest_ts c, --ts,
					 siac_r_liquidazione_movgest rliq,
					 siac_r_liquidazione_ord rord, 
					 siac_t_ordinativo_ts ordts, 
					 siac_t_ordinativo ord,
					 siac_r_ordinativo_stato rordstato,
					 siac_t_ordinativo_ts_det e, --tsdet,
					 siac_r_movgest_ts_stato d
				where
					b.movgest_id=a.movgest_id and
					a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
					a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
					and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
					and ord.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
					and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
					and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
					-- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  	--and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
					and b.movgest_anno < annoMovimento::integer -- anno dell impegno < annoMovimento 
					and c.movgest_id=b.movgest_id
					and d.movgest_ts_id=c.movgest_ts_id	
					and   rliq.movgest_ts_id=c.movgest_ts_id
					and   rord.liq_id=rliq.liq_id
					and   ordts.ord_ts_id=rord.sord_id
					and   ord.ord_id=ordts.ord_id
					and   rordstato.ord_id=ord.ord_id
					and   rordstato.ord_stato_id!=ordStatoAId -- non deve essere Annullato
					and   e.ord_ts_id=ordts.ord_ts_id
					and   e.ord_ts_det_tipo_id=ordTsDetTipoAId -- importo attuale
					and   e.data_cancellazione is null
					and   e.validita_fine is null
					and   b.data_cancellazione is null
					and   b.validita_fine is null
					and   c.data_cancellazione is null
					and   c.validita_fine is null
					and   a.data_cancellazione is null
					and   a.validita_fine is null
					and   rord.data_cancellazione is null
					and   rord.validita_fine is null
					and   rliq.data_cancellazione is null
					and   rliq.validita_fine is null
					and   ordts.data_cancellazione is null
					and   ordts.validita_fine is null
					and   ord.data_cancellazione is null
					and   ord.validita_fine is null
					and   rordstato.data_cancellazione is null
					and   rordstato.validita_fine is null
					and   d.data_cancellazione is null
					and   d.validita_fine is null;

				if importoPagatoDelta is null then importoPagatoDelta:=0; end if;

			end if;		
		end if;
	end if;

	indiceAnnualita:=loop_counter;
	elemDetCompId:=idcomp_in;
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente per l'anno N-1
	if flagDeltaPagamenti != 0 then
		impegnatoDefinitivo:=impegnatoDefinitivo+importoImpegnato-(importoPagatoDelta);
	else 
		impegnatoDefinitivo:=impegnatoDefinitivo+importoImpegnato;
	end if;
	return next;

	

 WHEN 6 THEN
	-- Calcolo Residuo Finale (In presenza della colonna finale e in assenza di qualsiasi colonna):
	-- - Se presenti i movimenti gestione provenienti dal ribaltamento 
	--      Sommatoria dell importo attuale di tutti gli Impegni assunti sul capitolo in questione su idcomp_in 
	--      con anno movimento < N e anno esercizio N.
	-- - Se non presenti i movimenti gestione provenienti dal ribaltamento 
	-- - Sommatoria di tutti gli Impegni (valore effettivo aka finale aka attuale) assunti sul capitolo in questione su incomp_in 
	--	con anno movimento < N e anno esercizio N-1 diminuiti dalla sommatoria del pagato sui medesimi impegni nell'esercizio N-1.

	impegniDaRibaltamento:=0;
	pluriennaliDaRibaltamento:=0;
	importoImpegnato:=0;	
	importoPagatoDelta:=0;
	
	select  count(*) into impegniDaRibaltamento 
	from fase_bil_t_gest_apertura_liq_imp fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;

	select  count(*) into  pluriennaliDaRibaltamento
	from fase_bil_t_gest_apertura_pluri fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;
				
	if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then

		-- - Se presenti i movimenti gestione provenienti dal ribaltamento 
		--		Residuo Finale = 
		--	 		Sommatoria dell importo attuale di tutti gli Impegni assunti sul capitolo in questione su idcomp_in
		--			con anno movimento < N e anno esercizio N.

		annoEsercizio:=annoBilancio;
		annoMovimento:=annoBilancio;
 		flagDeltaPagamenti:=0; -- non e' necessario scomputare il pagato
		
 	else

		-- - Se non presenti i movimenti gestione provenienti dal ribaltamento 
		-- 		Residuo Finale =	
		--			Sommatoria di tutti gli Impegni (valore effettivo aka finale) assunti sul capitolo in questione su incomp_in
		--			con anno movimento < N e anno esercizio N-1  
		--			diminuiti dalla sommatoria del pagato sui medesimi impegni nell esercizio N-1.
		annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
	        annoMovimento:=annoBilancio;
		flagDeltaPagamenti:=1; -- bisogna sottrarre la sommatoria del pagato sui medesimi impegni nell'esercizio N-1

	end if;

	strMessaggio:='Calcolo residuo finale elem_id='||id_in||'idcomp_in='||idcomp_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    	-- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo residuo finale.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else

		strMessaggio:='Calcolo residuo finale elem_id='||id_in||'idcomp_in='||idcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento||'.'; 

		impegnatoDefinitivo:=0;
		strMessaggio:='Calcolo residuo finale elem_id='||id_in||'idcomp_in='||idcomp_in||
			'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
			'. Inizio calcolo totale importo  impegni per annoMovimento='||annoMovimento||'.';

		if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then
			--  Sommatoria dell'importo attuale di tutti gli Impegni assunti sul capitolo in questione 
			--	su Componente X con anno movimento < N e anno esercizio N

		importoImpegnato:=0;			
		select tb.importo into importoImpegnato
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
				  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  -- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  --and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno < annoMovimento::integer -- anno dell impegno < annoMovimento 
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;		
			-- 02.02.2016 Sofia JIRA 2947
			if importoImpegnato is null then importoImpegnato:=0; end if;

		else
			-- Sommatoria di tutti gli Impegni assunti (valore effettivo aka finale) sul capitolo in questione su Componente X 
			-- con anno movimento < N e anno esercizio N-1
			-- diminuiti dalla sommatoria del pagato sui medesimi impegni nell'esercizio N-1.
			importoImpegnato:=0;			
			select tb.importo into importoImpegnato
				from (
				  select
					  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
				  from
					  siac_r_movgest_bil_elem a,
					  siac_t_movgest b,
					  siac_t_movgest_ts c,
					  siac_r_movgest_ts_stato d,
					  siac_t_movgest_ts_det e,
					  siac_d_movgest_ts_det_tipo f
				  where
					  b.movgest_id=a.movgest_id and
					  a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
					  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
					  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
					  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
					  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
					  -- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				  	  --and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
					  and b.movgest_anno < annoMovimento::integer -- anno dell impegno < annoMovimento 
					  and c.movgest_id=b.movgest_id
					  and d.movgest_ts_id=c.movgest_ts_id
					  and d.validita_fine is null
					  and e.movgest_ts_id=c.movgest_ts_id
					  and a.data_cancellazione is null
					  and b.data_cancellazione is null
					  and c.data_cancellazione is null
					  and e.data_cancellazione is null
					  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
					  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
					  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
				where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
				order by t.movgest_ts_tipo_code desc
				limit 1;	

			-- 16.03.2017 Sofia JIRA-SIAC-4614
			-- if importoImpegnato>0 then
			if importoImpegnato>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

				strMessaggio:='Calcolo residuo finale elem_id='||id_in||'idcomp_in='||idcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Calcolo sommatoria del pagato sui medesimi impegni nell''esercizio N-1.';

			   strMessaggio:='Lettura identificativo ord_stato_code='||STATO_ORD_A||'.';
			   select ordstato.ord_stato_id into ordStatoAId
			   from siac_d_ordinativo_stato ordstato
			   where ordstato.ente_proprietario_id=enteProprietarioId
			   and   ordstato.ord_stato_code=STATO_ORD_A;

			   select tipo.ord_ts_det_tipo_id into ordTsDetTipoAId
			   from siac_d_ordinativo_ts_det_tipo tipo
			   where tipo.ente_proprietario_id=enteProprietarioId
			   and   tipo.ord_ts_det_tipo_code=ORD_TS_DET_TIPO_A;

				select coalesce(sum(e.ord_ts_det_importo),0) into importoPagatoDelta
				from  
					 siac_r_movgest_bil_elem a,  --rmov,
					 siac_t_movgest b, -- mov, 
					 siac_t_movgest_ts c, --ts,
					 siac_r_liquidazione_movgest rliq,
					 siac_r_liquidazione_ord rord, 
					 siac_t_ordinativo_ts ordts, 
					 siac_t_ordinativo ord,
					 siac_r_ordinativo_stato rordstato,
					 siac_t_ordinativo_ts_det e, --tsdet,
					 siac_r_movgest_ts_stato d
				where
					b.movgest_id=a.movgest_id and
					a.elem_id=elemIdGestEq and -- UID del capitolo di gestione equivalente
					a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
					and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
					and ord.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
					and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
					and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
					-- SIAC-7737 GS 25/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				    --and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
					and b.movgest_anno < annoMovimento::integer -- anno dell impegno < annoMovimento 
					and c.movgest_id=b.movgest_id
					and d.movgest_ts_id=c.movgest_ts_id	
					and   rliq.movgest_ts_id=c.movgest_ts_id
					and   rord.liq_id=rliq.liq_id
					and   ordts.ord_ts_id=rord.sord_id
					and   ord.ord_id=ordts.ord_id
					and   rordstato.ord_id=ord.ord_id
					and   rordstato.ord_stato_id!=ordStatoAId -- non deve essere Annullato
					and   e.ord_ts_id=ordts.ord_ts_id
					and   e.ord_ts_det_tipo_id=ordTsDetTipoAId -- importo attuale
					and   e.data_cancellazione is null
					and   e.validita_fine is null
					and   b.data_cancellazione is null
					and   b.validita_fine is null
					and   c.data_cancellazione is null
					and   c.validita_fine is null
					and   a.data_cancellazione is null
					and   a.validita_fine is null
					and   rord.data_cancellazione is null
					and   rord.validita_fine is null
					and   rliq.data_cancellazione is null
					and   rliq.validita_fine is null
					and   ordts.data_cancellazione is null
					and   ordts.validita_fine is null
					and   ord.data_cancellazione is null
					and   ord.validita_fine is null
					and   rordstato.data_cancellazione is null
					and   rordstato.validita_fine is null
					and   d.data_cancellazione is null
					and   d.validita_fine is null;

				if importoPagatoDelta is null then importoPagatoDelta:=0; end if;

			end if;		
		end if;
	end if;

	indiceAnnualita:=loop_counter;
	elemDetCompId:=idcomp_in;
	impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente per l'anno N-1
	if flagDeltaPagamenti != 0 then
		impegnatoDefinitivo:=impegnatoDefinitivo+importoImpegnato-(importoPagatoDelta);
	else 
		impegnatoDefinitivo:=impegnatoDefinitivo+importoImpegnato;
	end if;
	return next;

END CASE;
END LOOP;

return;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
		return;
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
PARALLEL UNSAFE
COST 100 ROWS 1000;


ALTER FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp (id_in integer, idcomp_in integer)
  OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp (id_in integer, idcomp_in integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp (id_in integer, idcomp_in integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp (id_in integer, idcomp_in integer) TO siac;

--end fnc_siac_impegnatodefinitivoup_comp

--Start fnc_siac_impegnatoeffettivoug_comp_anno
CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatoeffettivoug_comp_anno (
  id_in integer,
  anno_in varchar
)
RETURNS TABLE (
  annocompetenza varchar,
  dicuiimpegnato numeric
) AS
$body$
DECLARE

-- constant
TIPO_CAP_UG constant varchar:='CAP-UG';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';

TIPO_IMP    constant varchar:='I';
TIPO_IMP_T  constant varchar:='T';

STATO_DEF   constant varchar:='D';
STATO_N     constant varchar:='N';
STATO_P     constant varchar:='P';
STATO_A     constant varchar:='A';
IMPORTO_ATT constant varchar:='A';

strMessaggio varchar(1500):=NVL_STR;


bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;

movGestTipoId integer:=0;
movGestTsTipoId integer:=0;
movGestStatoId integer:=0;
movGestTsDetTipoId integer:=0;

movGestTsId integer:=0;

importoAttuale numeric:=0;
importoCurAttuale numeric:=0;
movGestIdRec record;

esisteRmovgestidelemid INTEGER:=0;

BEGIN

select el.elem_id into esisteRmovgestidelemid from siac_r_movgest_bil_elem el, siac_t_movgest mv
where
mv.movgest_id=el.movgest_id
and el.elem_id=id_in
and mv.movgest_anno=anno_in::integer
;

 -- 02.02.2016 Sofia JIRA 2947
if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;

if esisteRmovgestidelemid <>0 then


 annoCompetenza:=null;
 diCuiImpegnato:=0;

 strMessaggio:='Calcolo impegnato effettivo competenza elem_id='||id_in||'.Controllo parametri.';

 if anno_in is null or anno_in=NVL_STR then
	 RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
	 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
 end if;


 strMessaggio:='Calcolo impegnato effettivo competenza elem_id='||id_in
			   ||'.Calcolo bilancioId enteProprietarioId  annoBilancio.';

 select bil.bil_id,  bil.ente_proprietario_id,  per.anno
        into strict bilancioId, enteProprietarioId, annoBilancio
 from siac_t_bil bil,siac_t_bil_elem bilElem, siac_t_periodo per
 where bilElem.elem_id=id_in
 and   bilElem.data_cancellazione is null
 and   bil.bil_id=bilElem.bil_id
 and   per.periodo_id=bil.periodo_id;





 strMessaggio:='Calcolo impegnato effettivo competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTipoId.';
 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
 from  siac_d_movgest_tipo tipoMovGest
 where tipoMovGest.ente_proprietario_id=enteProprietarioId
 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

 strMessaggio:='Calcolo impegnato effettivo competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsTipoId.';

 strMessaggio:='Calcolo impegnato effettivo competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsStatoId.';

 select movGestStato.movgest_stato_id into strict movGestStatoId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_A;

 strMessaggio:='Calcolo impegnato effettivo competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsDetTipoId.';

 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;



 strMessaggio:='Calcolo impegnato effettivo competenza elem_id='||id_in||'. Inizio calcolo totale importo attuale impegni per anno_in='||anno_in||'.';


 --nuovo G
   	importoCurAttuale:=0;

    select tb.importo into importoCurAttuale
	from (
		select
			coalesce(sum(e.movgest_ts_det_importo),0)  importo
			, c.movgest_ts_tipo_id
		from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id=a.movgest_id and
      a.elem_id=id_in
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
      and c.movgest_id=b.movgest_id
      and d.movgest_ts_id=c.movgest_ts_id
      and d.validita_fine is null
      and e.movgest_ts_id=c.movgest_ts_id
	and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
     and e.data_cancellazione is null
     and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
    and e.movgest_ts_det_tipo_id=movGestTsDetTipoId
    group by
   c.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;



 if importoCurAttuale is null then importoCurAttuale:=0; end if;

 

 end if;

 --nuovo G
 importoAttuale:=importoAttuale+importoCurAttuale; -- 16.03.2017 Sofia JIRA-SIAC-4614
 --fine nuovoG


 annoCompetenza:=anno_in;
 diCuiImpegnato:=importoAttuale;

 return next;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
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
PARALLEL UNSAFE
COST 100 ROWS 1000;


ALTER FUNCTION siac.fnc_siac_impegnatoeffettivoug_comp_anno (id_in integer, anno_in varchar)
  OWNER TO siac;
--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoug_comp_anno (id_in integer, anno_in varchar) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoug_comp_anno (id_in integer, anno_in varchar) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoug_comp_anno (id_in integer, anno_in varchar) TO siac;
--end fnc_siac_impegnatoeffettivoug_comp_anno

--Start fnc_siac_impegnatoeffettivoup_comp_anno
CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatoeffettivoup_comp_anno (
  id_in integer,
  anno_in varchar
)
RETURNS TABLE (
  annocompetenza varchar,
  impegnatoEffettivo numeric
) AS
$body$

DECLARE
annoBilancio varchar:=null;
annoEsercizio varchar:=null;
annoMovimento varchar:=null;
importoAttuale numeric:=0;
elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;
NVL_STR     constant varchar:='';
faseOpCode varchar(20):=NVL_STR;
bilancioId integer:=0;
elemTipoCode VARCHAR(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;
enteProprietarioId INTEGER:=0;
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
FASE_OP_BIL_PREV constant VARCHAR:='P';
STATO_A     constant varchar:='A';
STATO_P     constant varchar:='P';
TIPO_IMP    constant varchar:='I';
movGestStatoIdAnnullato integer:=0;
movGestStatoIdProvvisorio integer:=0;
movGestTipoId integer:=0;
IMPORTO_ATT constant varchar:='A';
movGestTsDetTipoId integer:=0;
IMPORTO_INIZIALE constant varchar:='I';
movGestTsDetTipoIdIniziale integer:=0;
STATO_MOD_V  constant varchar:='V';

STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';
importoCurAttuale numeric:=0;
esisteRmovgestidelemid INTEGER:=0;
impegniDaRibaltamento integer:=0;
pluriennaliDaRibaltamento integer:=0;
flagNMaggioreNPiu2 integer:=0;
importoImpegnato integer:=0;

strMessaggio varchar(1500):=null;
BEGIN


    strMessaggio:='Calcolo totale impegnato effettivo per elem_id='||id_in||'.';

	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;

	strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||'. Lettura anno di bilancio del capitolo UP.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;


	strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||'. Determina capitolo di gestione equivalente in anno esercizio di calcolato. Calcolo bilancioId e elem_tipo_code.';
	 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
	 into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
	 from 	siac_t_bil_elem bilElem,
	 		siac_d_bil_elem_tipo tipoBilElem,
		  	siac_t_bil bil, siac_t_periodo per
	 where bilElem.elem_id=id_in
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
	   and bil.bil_id=bilElem.bil_id
	   and per.periodo_id=bil.periodo_id;

	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UP then
			RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
	 end if;

	 strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||'. Determina capitolo di gestione equivalente in anno esercizio calcolato. Calcolo fase operativa per bilancioId='||bilancioId||' , per ente='||enteProprietarioId||' e per elem_id='||id_in||'.';

	 select  faseOp.fase_operativa_code into  faseOpCode
	 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
	 where bilFase.bil_id =bilancioId
	   and bilfase.data_cancellazione is null
	   and bilFase.validita_fine is null
	   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
	   and faseOp.data_cancellazione is null
	 order by bilFase.bil_fase_operativa_id desc;

	 if NOT FOUND THEN
	   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
	 end if;

	 strMessaggio:='Calcolo impegnato effettivo elem_id='||id_in||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

	 strMessaggio:='Calcolo impegnato effettivo  competenza elem_id='||id_in||
				  '. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO'
				  '. Calcolo movGestTsStatoIdProvvisorio per movgest_stato_code=PROVVISORIO';

	 select movGestStato.movgest_stato_id into strict movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;

	 select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_P;

	 strMessaggio:='Calcolo impegnato effettivo competenza elem_id='||id_in||
				  '. Calcolo movGestTsDetTipoId per movgest_ts_det_tipo_code=IMPORTO ATTUALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT; --'A'

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||
				  '. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE; --'I'


	importoCurAttuale:=0;
	annoMovimento=anno_in;
	annoEsercizio=annoBilancio;

	strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||'. Determina capitolo di gestione equivalente in anno esercizio calcolato.';

	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';

	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo impegnato effettivo competenza UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;
	   


	if NOT FOUND THEN
		impegnatoEffettivo:=0;
	else

		strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq||
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento||
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno=annoMovimento::integer;

		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;

		if esisteRmovgestidelemid <>0 then
 			impegnatoEffettivo:=0;
			strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq||
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

			importoCurAttuale:=0;
			select tb.importo into importoCurAttuale
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq  -- UID del capitolo di gestione equivalente
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno = annoMovimento::integer -- anno dell impegno = annoMovimento
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;

			-- 02.02.2016 Sofia JIRA 2947
			 if importoCurAttuale is null then importoCurAttuale:=0; end if;

		end if;
	end if;

 importoAttuale:=importoAttuale+importoCurAttuale; -- 16.03.2017 Sofia JIRA-SIAC-4614

 annoCompetenza:=anno_in;
 impegnatoEffettivo:=importoAttuale;

 return next;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
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
PARALLEL UNSAFE
COST 100 ROWS 1000;


ALTER FUNCTION siac.fnc_siac_impegnatoeffettivoup_comp_anno (id_in integer, anno_in varchar)
  OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoup_comp_anno (id_in integer, anno_in varchar) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoup_comp_anno (id_in integer, anno_in varchar) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoup_comp_anno (id_in integer, anno_in varchar) TO siac;
--end fnc_siac_impegnatoeffettivoup_comp_anno

--Start fnc_siac_impegnatoeffettivoug_anno1
CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatoeffettivoug_anno1 (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE

diCuiImpegnato numeric:=0;

annoBilancio varchar:=null;

diCuiImpegnatoRec record;

strMessaggio varchar(1500):=null;
BEGIN

    strMessaggio:='Calcolo totale impegnato elem_id='||id_in||'.';

	strMessaggio:='Calcolo totale impegnato elem_id='||id_in||
    			  '.Lettura anno di bilancio.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;



     strMessaggio:='Calcolo totale impegnato elem_id='||id_in||'.';
     select * into diCuiImpegnatoRec
     from  fnc_siac_impegnatoeffettivoug_comp_anno (id_in,annoBilancio);

     
     diCuiImpegnato:=diCuiImpegnatoRec.diCuiImpegnato;
	
	
     return diCuiImpegnato;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        diCuiImpegnato:=0;
        return diCuiImpegnato;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        diCuiImpegnato:=0;
        return diCuiImpegnato;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        diCuiImpegnato:=0;
        return diCuiImpegnato;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100;


ALTER FUNCTION siac.fnc_siac_impegnatoeffettivoug_anno1 (id_in integer)
  OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoug_anno1 (id_in integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoug_anno1 (id_in integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoug_anno1 (id_in integer) TO siac;
--end fnc_siac_impegnatoeffettivoug_anno1

--Start fnc_siac_impegnatoeffettivoug_anno2
CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatoeffettivoug_anno2 (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE

diCuiImpegnato numeric:=0;

annoBilancio varchar:=null;

diCuiImpegnatoRec record;

strMessaggio varchar(1500):=null;
BEGIN

    strMessaggio:='Calcolo totale impegnato elem_id='||id_in||'.';

	strMessaggio:='Calcolo totale impegnato elem_id='||id_in||
    			  '.Lettura anno di bilancio.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;



     strMessaggio:='Calcolo totale impegnato elem_id='||id_in||'.';
     select * into diCuiImpegnatoRec
     from  fnc_siac_impegnatoeffettivoug_comp_anno (id_in,((annoBilancio::integer)+1)::varchar);

     
     diCuiImpegnato:=diCuiImpegnatoRec.diCuiImpegnato;
	
	
     return diCuiImpegnato;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        diCuiImpegnato:=0;
        return diCuiImpegnato;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        diCuiImpegnato:=0;
        return diCuiImpegnato;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        diCuiImpegnato:=0;
        return diCuiImpegnato;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100;


ALTER FUNCTION siac.fnc_siac_impegnatoeffettivoug_anno2 (id_in integer)
  OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoug_anno2 (id_in integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoug_anno2 (id_in integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoug_anno2 (id_in integer) TO siac;
--end fnc_siac_impegnatoeffettivoug_anno2


--Start fnc_siac_impegnatoeffettivoug_anno3
CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatoeffettivoug_anno3 (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE

diCuiImpegnato numeric:=0;

annoBilancio varchar:=null;

diCuiImpegnatoRec record;

strMessaggio varchar(1500):=null;
BEGIN

    strMessaggio:='Calcolo totale impegnato elem_id='||id_in||'.';

	strMessaggio:='Calcolo totale impegnato elem_id='||id_in||
    			  '.Lettura anno di bilancio.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;



     strMessaggio:='Calcolo totale impegnato elem_id='||id_in||'.';
     select * into diCuiImpegnatoRec
     from  fnc_siac_impegnatoeffettivoug_comp_anno (id_in,((annoBilancio::integer)+2)::varchar);

     
     diCuiImpegnato:=diCuiImpegnatoRec.diCuiImpegnato;
	
	
     return diCuiImpegnato;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        diCuiImpegnato:=0;
        return diCuiImpegnato;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        diCuiImpegnato:=0;
        return diCuiImpegnato;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        diCuiImpegnato:=0;
        return diCuiImpegnato;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100;


ALTER FUNCTION siac.fnc_siac_impegnatoeffettivoug_anno3 (id_in integer)
  OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoug_anno3 (id_in integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoug_anno3 (id_in integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoug_anno3 (id_in integer) TO siac;
--end fnc_siac_impegnatoeffettivoug_anno3

--Start fnc_siac_impegnatoeffettivoup_anno1
CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatoeffettivoup_anno1 (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE

impegnatoEffettivo numeric:=0;

annoBilancio varchar:=null;

impegnatoEffettivoRec record;

strMessaggio varchar(1500):=null;
BEGIN

    strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||'.';

	strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||
    			  '.Lettura anno di bilancio.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;



     strMessaggio:='Calcolo totale impegnato elem_id='||id_in||'.';
     select * into impegnatoEffettivoRec
     from  fnc_siac_impegnatoeffettivoup_comp_anno (id_in,annoBilancio);

     
     impegnatoEffettivo:=impegnatoEffettivoRec.impegnatoEffettivo;
	
	
     return impegnatoEffettivo;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        impegnatoEffettivo:=0;
        return impegnatoEffettivo;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        impegnatoEffettivo:=0;
        return impegnatoEffettivo;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        impegnatoEffettivo:=0;
        return impegnatoEffettivo;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100;


ALTER FUNCTION siac.fnc_siac_impegnatoeffettivoup_anno1 (id_in integer)
  OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoup_anno1 (id_in integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoup_anno1 (id_in integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoup_anno1 (id_in integer) TO siac;
--end fnc_siac_impegnatoeffettivoup_anno1

--Start fnc_siac_impegnatoeffettivoup_anno2
CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatoeffettivoup_anno2 (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE

impegnatoEffettivo numeric:=0;

annoBilancio varchar:=null;

impegnatoEffettivoRec record;

strMessaggio varchar(1500):=null;
BEGIN

    strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||'.';

	strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||
    			  '.Lettura anno di bilancio.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;



     strMessaggio:='Calcolo totale impegnato elem_id='||id_in||'.';
     select * into impegnatoEffettivoRec
     from  fnc_siac_impegnatoeffettivoup_comp_anno (id_in,((annoBilancio::integer)+1)::varchar);

     
     impegnatoEffettivo:=impegnatoEffettivoRec.impegnatoEffettivo;
	
	
     return impegnatoEffettivo;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        impegnatoEffettivo:=0;
        return impegnatoEffettivo;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        impegnatoEffettivo:=0;
        return impegnatoEffettivo;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        impegnatoEffettivo:=0;
        return impegnatoEffettivo;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100;


ALTER FUNCTION siac.fnc_siac_impegnatoeffettivoup_anno2 (id_in integer)
  OWNER TO siac;
 
--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoup_anno2 (id_in integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoup_anno2 (id_in integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoup_anno2 (id_in integer) TO siac;
--end fnc_siac_impegnatoeffettivoup_anno2


--Start fnc_siac_impegnatoeffettivoup_anno3
CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatoeffettivoup_anno3 (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE

impegnatoEffettivo numeric:=0;

annoBilancio varchar:=null;

impegnatoEffettivoRec record;

strMessaggio varchar(1500):=null;
BEGIN

    strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||'.';

	strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||
    			  '.Lettura anno di bilancio.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;



     strMessaggio:='Calcolo totale impegnato elem_id='||id_in||'.';
     select * into impegnatoEffettivoRec
     from  fnc_siac_impegnatoeffettivoup_comp_anno (id_in,((annoBilancio::integer)+2)::varchar);

     
     impegnatoEffettivo:=impegnatoEffettivoRec.impegnatoEffettivo;
	
	
     return impegnatoEffettivo;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        impegnatoEffettivo:=0;
        return impegnatoEffettivo;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        impegnatoEffettivo:=0;
        return impegnatoEffettivo;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        impegnatoEffettivo:=0;
        return impegnatoEffettivo;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100;


ALTER FUNCTION siac.fnc_siac_impegnatoeffettivoup_anno3 (id_in integer)
  OWNER TO siac;
  
--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoup_anno3 (id_in integer) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoup_anno3 (id_in integer) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoup_anno3 (id_in integer) TO siac;
--end fnc_siac_impegnatoeffettivoup_anno3


--start fnc_siac_riaccertamento

 DROP FUNCTION if exists siac.fnc_siac_riaccertamento(integer, character varying, character varying);

CREATE OR REPLACE FUNCTION siac.fnc_siac_riaccertamento(
	mod_id_in integer,
	login_operazione_in character varying,
	tipo_operazione_in character varying)
    RETURNS TABLE(esito character varying) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE SECURITY DEFINER 
    ROWS 1000
AS $BODY$
DECLARE
importo_mod_da_scalare numeric;
ente_proprietario_id_in integer;
rec record;
recannullamento record;
--25.05.2020 FL SIAC-7349 Inizio SR.SR165.SR167.SR169
importo_sum_det_mod_da_scalare numeric;
recListaCollegata record;
--Il cursore 'cur' che estrae solo le modifiche di impegno  e' stato modificato escludendo le modifiche di reimputazione con questa modifica 
--e' stato creato un altro cursore 'curListaCollegata' che estrai le modifiche di accertamento di reimputazione  che sono state collegate all impegno strettamente legato 
-- ed a questo vincolo viene decurtato all'importo del vincolo  la somma degli importi collegamenti solo se  naturalmente le modifiche di accertamento   e sono di tipo reimputazione.
--25.05.2020 FL SIAC-7349 Fine SR.SR165.SR167.SR169

cur CURSOR(par_in integer) FOR
--avav
SELECT 'avav' tipomod,
a.mod_id,
i.movgest_ts_r_id,
i.movgest_ts_importo,
case when n.avav_tipo_code='FPVSC' then 1
	 when n.avav_tipo_code='FPVCC' then 1 when n.avav_tipo_code='AAM' then 2 else 3 end
		as tipoordinamento
FROM siac_t_modifica a,
siac_r_modifica_stato b,
siac_t_movgest_ts_det_mod c,
siac_d_modifica_stato d,
siac_d_movgest_ts_det_tipo e, siac_t_movgest_ts f, siac_t_movgest g,siac_d_movgest_tipo h,
siac_r_movgest_ts i,
siac_t_avanzovincolo l, siac_d_movgest_ts_tipo m,siac_d_avanzovincolo_tipo n
WHERE
a.mod_id=par_in--mod_id_in
 and
a.mod_id = b.mod_id AND
c.mod_stato_r_id = b.mod_stato_r_id AND
d.mod_stato_id = b.mod_stato_id and
e.movgest_ts_det_tipo_id=c.movgest_ts_det_tipo_id and
f.movgest_ts_id=c.movgest_ts_id and
g.movgest_id=f.movgest_id and
d.mod_stato_code='V' and
h.movgest_tipo_id=g.movgest_tipo_id and
h.movgest_tipo_code='I' and --movgest_ts_b_id e' impegno
i.movgest_ts_b_id=f.movgest_ts_id and
n.avav_tipo_id=l.avav_tipo_id and
now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now()) and
now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now()) and
m.movgest_ts_tipo_id=f.movgest_ts_tipo_id and
l.avav_id=i.avav_id and
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL and
e.data_cancellazione is null and
f.data_cancellazione is null and
g.data_cancellazione is null and
h.data_cancellazione is null and
i.data_cancellazione is null and
l.data_cancellazione is null and
m.data_cancellazione is null and
n.data_cancellazione is null
--order by 1 asc,3 desc
union
-- imp acc
SELECT
'impacc',
a.mod_id,
i.movgest_ts_r_id,
i.movgest_ts_importo,
4 tipoordinamento
FROM siac_t_modifica a,
siac_r_modifica_stato b,
siac_t_movgest_ts_det_mod c,
siac_d_modifica_stato d,
siac_d_movgest_ts_det_tipo e, siac_t_movgest_ts f, siac_t_movgest g,siac_d_movgest_tipo h,
siac_r_movgest_ts i,--, siac_t_movgest l,siac_d_movgest_tipo m
siac_t_movgest_ts l, siac_d_movgest_ts_tipo m
WHERE
a.mod_id=par_in--mod_id_in
and
a.mod_id = b.mod_id AND
c.mod_stato_r_id = b.mod_stato_r_id AND
d.mod_stato_id = b.mod_stato_id and
e.movgest_ts_det_tipo_id=c.movgest_ts_det_tipo_id and
f.movgest_ts_id=c.movgest_ts_id and
g.movgest_id=f.movgest_id and
d.mod_stato_code='V' and
h.movgest_tipo_id=g.movgest_tipo_id and
h.movgest_tipo_code='I' and
--h.movgest_tipo_code='A' and
--25.05.2020 FL SIAC-7349 Inizio SR.SR165.SR167.SR169
c.mtdm_reimputazione_flag=false and  --esclude le modifche di tipo reimputazione
--25.05.2020 FL SIAC-7349 Fine SR.SR165.SR167.SR169
i.movgest_ts_b_id=f.movgest_ts_id and --movgest_ts_b_id e' impegno
now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now()) and
now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now()) and
m.movgest_ts_tipo_id=f.movgest_ts_tipo_id and
l.movgest_ts_id=i.movgest_ts_a_id and
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL and
e.data_cancellazione is null and
f.data_cancellazione is null and
g.data_cancellazione is null and
h.data_cancellazione is null and
i.data_cancellazione is null and
l.data_cancellazione is null and
m.data_cancellazione is null
order
by 5 desc,2 asc,4 desc;   -- 27.02.2019 SIAC-6713
--by 5 asc,2 asc,4 desc;  -- 27.02.2019 SIAC-6713

--25.05.2020 FL SIAC-7349 Inizio SR.SR165.SR167.SR169

curListaCollegata CURSOR(par_in integer) FOR
-- imp acc
SELECT
'impacc',
a.mod_id,
i.movgest_ts_r_id,
i.movgest_ts_importo,
4 tipoordinamento,
l.movgest_ts_code 
FROM siac_t_modifica a,
siac_r_modifica_stato b,
siac_t_movgest_ts_det_mod c,
siac_d_modifica_stato d,
siac_d_movgest_ts_det_tipo e, siac_t_movgest_ts f, siac_t_movgest g,siac_d_movgest_tipo h,
siac_r_movgest_ts i,--, siac_t_movgest l,siac_d_movgest_tipo m
siac_t_movgest_ts l, siac_d_movgest_ts_tipo m
WHERE
a.mod_id=par_in--mod_id_in
and
a.mod_id = b.mod_id AND
c.mod_stato_r_id = b.mod_stato_r_id AND
d.mod_stato_id = b.mod_stato_id and
e.movgest_ts_det_tipo_id=c.movgest_ts_det_tipo_id and
f.movgest_ts_id=c.movgest_ts_id and
g.movgest_id=f.movgest_id and
d.mod_stato_code='V' and
h.movgest_tipo_id=g.movgest_tipo_id and
h.movgest_tipo_code='A' and
c.mtdm_reimputazione_flag=true and
i.movgest_ts_a_id=f.movgest_ts_id and --movgest_ts_a_id e' A = ACCERTAMENTI
now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now()) and
now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now()) and
m.movgest_ts_tipo_id=f.movgest_ts_tipo_id and
l.movgest_ts_id=i.movgest_ts_b_id and
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL and
e.data_cancellazione is null and
f.data_cancellazione is null and
g.data_cancellazione is null and
h.data_cancellazione is null and
i.data_cancellazione is null and
l.data_cancellazione is null and
m.data_cancellazione is null
order
by 5 desc,2 asc,4 desc;    
--25.05.2020 FL SIAC-7349 Fine SR.SR165.SR167.SR169

begin
esito:='oknodata'::varchar;

if tipo_operazione_in = 'INSERIMENTO' then

      --data la modifica trovo il suo importo da sottrarre ai vincoli
      --modifiche di impegno
      SELECT c.movgest_ts_det_importo,
      c.ente_proprietario_id
      into importo_mod_da_scalare,
      ente_proprietario_id_in
      FROM siac_t_modifica a,
      siac_r_modifica_stato b,
      siac_t_movgest_ts_det_mod c,
      siac_d_modifica_stato d,
      siac_d_movgest_ts_det_tipo e,
      siac_t_movgest_ts f,
      siac_t_movgest g,
      siac_d_movgest_tipo h
      WHERE a.mod_id = mod_id_in and
      a.mod_id = b.mod_id AND
      c.mod_stato_r_id = b.mod_stato_r_id AND
      d.mod_stato_id = b.mod_stato_id and
      e.movgest_ts_det_tipo_id = c.movgest_ts_det_tipo_id and
      f.movgest_ts_id = c.movgest_ts_id and
      g.movgest_id = f.movgest_id and
      d.mod_stato_code = 'V' and
      h.movgest_tipo_id = g.movgest_tipo_id and
      h.movgest_tipo_code = 'I' and	  
      now() BETWEEN b.validita_inizio and
      COALESCE(b.validita_fine, now()) and
      a.data_cancellazione IS NULL AND
      b.data_cancellazione IS NULL AND
      c.data_cancellazione IS NULL AND
      d.data_cancellazione IS NULL and
      e.data_cancellazione is null and
      f.data_cancellazione is null and
      g.data_cancellazione is null and
      h.data_cancellazione is null;

      if importo_mod_da_scalare<0 then

      ----------nuova sez inizio -------------
      for rec in cur(mod_id_in) loop
          if rec.movgest_ts_importo is not null and importo_mod_da_scalare<0 then
              if rec.movgest_ts_importo + importo_mod_da_scalare < 0 then
                esito:='ok';
                update siac_r_movgest_ts
                  set movgest_ts_importo = movgest_ts_importo - movgest_ts_importo --per farlo diventare zero
                  ,login_operazione = login_operazione_in,data_modifica = clock_timestamp()
                  where movgest_ts_r_id = rec.movgest_ts_r_id;

                insert into siac_r_modifica_vincolo(mod_id, movgest_ts_r_id,
                  modvinc_tipo_operazione, importo_delta, validita_inizio, ente_proprietario_id,
                  login_operazione)
                values (mod_id_in, rec.movgest_ts_r_id, 'INSERIMENTO', - rec.movgest_ts_importo,
                  clock_timestamp(), ente_proprietario_id_in, login_operazione_in || ' - ' ||
                  'fnc_siac_riccertamento');

                /*INSERT INTO siac.tmp_riaccertamento_debug(tmp_mod_id_in,
                  tmp_login_operazione_in, tmp_tipo_operazione_in, tmp_movgest_ts_r_id,
                  tmp_movgest_ts_importo, tmp_importo_mod_da_scalare, esito)
                VALUES (mod_id_in, login_operazione_in, tipo_operazione_in, rec.movgest_ts_r_id,
                  rec.movgest_ts_importo, importo_mod_da_scalare, esito);*/

                importo_mod_da_scalare:= importo_mod_da_scalare + rec.movgest_ts_importo;

              elsif rec.movgest_ts_importo + importo_mod_da_scalare >= 0 then
                esito:='ok';
                update siac_r_movgest_ts set
                movgest_ts_importo = movgest_ts_importo + importo_mod_da_scalare
                , login_operazione=login_operazione_in, data_modifica=clock_timestamp()
                where movgest_ts_r_id=rec.movgest_ts_r_id;

                insert into siac_r_modifica_vincolo (mod_id,movgest_ts_r_id,modvinc_tipo_operazione,
                importo_delta,validita_inizio,ente_proprietario_id
                ,login_operazione )
                values
                (mod_id_in, rec.movgest_ts_r_id, 'INSERIMENTO',importo_mod_da_scalare,clock_timestamp(), ente_proprietario_id_in,
                login_operazione_in||' - '||'fnc_siac_riccertamento' );

                /*INSERT INTO siac.tmp_riaccertamento_debug(tmp_mod_id_in,
                tmp_login_operazione_in, tmp_tipo_operazione_in, tmp_movgest_ts_r_id,
                tmp_movgest_ts_importo, tmp_importo_mod_da_scalare, esito)
                VALUES (mod_id_in, login_operazione_in, tipo_operazione_in,
                rec.movgest_ts_r_id, rec.movgest_ts_importo, importo_mod_da_scalare,
                'ok=');*/

                importo_mod_da_scalare:= importo_mod_da_scalare - importo_mod_da_scalare;

              end if;
          end if;
       --  esito:='ok';
      end loop;
      ----------nuova sez fine -------------
      return next;
	  
	  end if;
	  

	--25.05.2020 FL SIAC-7349 Inizio SR.SR165.SR167.SR169
	if importo_mod_da_scalare IS  NULL then
     
	  
	  
	-- if importo_sum_det_mod_da_scalare>0 then --nel caso in cui esitono la somma importo collegamento maggiore di 0

      ----------nuova sez inizio -------------
      for recListaCollegata in curListaCollegata(mod_id_in) loop
	  
					--data la modifica trovo la somma dell'importo collegamento da sottrarre ai vincoli
			  --modifiche di impegno
		  SELECT sum(r.movgest_ts_det_mod_importo), -- importo collegamento
			   c.ente_proprietario_id
			   into importo_sum_det_mod_da_scalare,
				   ente_proprietario_id_in
			  FROM siac_t_modifica a,
				   siac_r_modifica_stato b,
				   siac_t_movgest_ts_det_mod c,
				   siac_r_movgest_ts_det_mod r, --tabella di relazione
				   siac_d_modifica_stato d,
				   siac_d_movgest_ts_det_tipo e,
				   siac_t_movgest_ts f,
				   siac_t_movgest g,
				   siac_d_movgest_tipo h
			 WHERE a.mod_id = mod_id_in and  
			  r.movgest_ts_det_mod_entrata_id = c.movgest_ts_det_mod_id and --metto in join 
			  a.mod_id = b.mod_id AND
			  c.mod_stato_r_id = b.mod_stato_r_id AND
			  d.mod_stato_id = b.mod_stato_id and
			  e.movgest_ts_det_tipo_id = c.movgest_ts_det_tipo_id and
			  f.movgest_ts_id = c.movgest_ts_id and
			  g.movgest_id = f.movgest_id and
			  d.mod_stato_code = 'V' and
			  h.movgest_tipo_id = g.movgest_tipo_id and
			  h.movgest_tipo_code = 'A' and
			  c.mtdm_reimputazione_flag=true and 
			  now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine, now()) and
			  a.data_cancellazione IS NULL AND
			  b.data_cancellazione IS NULL AND
			  c.data_cancellazione IS NULL AND
			  d.data_cancellazione IS NULL and
			  e.data_cancellazione is null and
			  f.data_cancellazione is null and
			  g.data_cancellazione is null and
			  h.data_cancellazione is null and 
			  r.data_cancellazione is null   and
			  EXISTS  
			  (select movgest_ts_det_mod_id
				 from siac_t_movgest_ts_det_mod ci,
					  siac_t_movgest_ts fi,
					  siac_t_movgest gi,
					  siac_r_movgest_ts i, 
					  siac_t_movgest_ts l, 
					  siac_d_movgest_ts_tipo m
				  where  r.movgest_ts_det_mod_spesa_id=ci.movgest_ts_det_mod_id and  
				         i.movgest_ts_r_id = recListaCollegata.movgest_ts_r_id and  -- aggiunta condizione per l'impegno
						 fi.movgest_ts_id = ci.movgest_ts_id and
						 gi.movgest_id = fi.movgest_id and
						 i.movgest_ts_b_id=fi.movgest_ts_id and --movgest_ts_a_id e' I = IMPEGNI
						 now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now()) and
						 m.movgest_ts_tipo_id=fi.movgest_ts_tipo_id and
						 l.movgest_ts_id=i.movgest_ts_a_id and
						 ci.data_cancellazione is null and
						 fi.data_cancellazione is null and
						 i.data_cancellazione is null and
						 l.data_cancellazione is null and
						 m.data_cancellazione is null
			  )
			  group by c.ente_proprietario_id;
	  
	  
          if recListaCollegata.movgest_ts_importo is not null and importo_sum_det_mod_da_scalare>0 then
              if recListaCollegata.movgest_ts_importo - importo_sum_det_mod_da_scalare < 0 then
			    --CONTABILIA-258 Verifico  limite importo vincolo quando si collegano modifiche 
				--               di differimento di entrata a piu' modifiche di spesa sullo stesso impegno
				--esito:='ko';

			    esito:='koVincolo -  la somma dei collegamenti impostati supera l''importo del vincolo (' ||   trim(TO_CHAR(recListaCollegata.movgest_ts_importo,'99999999999999999D99')) || ') per l''impegno '||recListaCollegata.movgest_ts_code   ;
				return next;
				return;
/*
                esito:='ok';
                update siac_r_movgest_ts
                  set movgest_ts_importo = movgest_ts_importo - movgest_ts_importo --per farlo diventare zero
                  ,login_operazione = login_operazione_in,data_modifica = clock_timestamp()
                  where movgest_ts_r_id = recListaCollegata.movgest_ts_r_id;

                insert into siac_r_modifica_vincolo(mod_id, movgest_ts_r_id,
                  modvinc_tipo_operazione, importo_delta, validita_inizio, ente_proprietario_id,
                  login_operazione)
                values (mod_id_in, recListaCollegata.movgest_ts_r_id, 'INSERIMENTO', - recListaCollegata.movgest_ts_importo,
                  clock_timestamp(), ente_proprietario_id_in, login_operazione_in || ' - ' ||
                  'fnc_siac_riccertamento');

                /*INSERT INTO siac.tmp_riaccertamento_debug(tmp_mod_id_in,
                  tmp_login_operazione_in, tmp_tipo_operazione_in, tmp_movgest_ts_r_id,
                  tmp_movgest_ts_importo, tmp_importo_mod_da_scalare, esito)
                VALUES (mod_id_in, login_operazione_in, tipo_operazione_in, recListaCollegata.movgest_ts_r_id,
                  recListaCollegata.movgest_ts_importo,- importo_sum_det_mod_da_scalare, esito);*/

                importo_sum_det_mod_da_scalare:= importo_sum_det_mod_da_scalare - recListaCollegata.movgest_ts_importo;
*/
              elsif importo_sum_det_mod_da_scalare>0 and recListaCollegata.movgest_ts_importo - importo_sum_det_mod_da_scalare >= 0 then
                esito:='ok';
                update siac_r_movgest_ts set
                movgest_ts_importo = movgest_ts_importo - importo_sum_det_mod_da_scalare
                , login_operazione=login_operazione_in, data_modifica=clock_timestamp()
                where movgest_ts_r_id=recListaCollegata.movgest_ts_r_id;

                insert into siac_r_modifica_vincolo (mod_id,movgest_ts_r_id,modvinc_tipo_operazione,
                importo_delta,validita_inizio,ente_proprietario_id
                ,login_operazione )
                values
                (mod_id_in, recListaCollegata.movgest_ts_r_id, 'INSERIMENTO',-importo_sum_det_mod_da_scalare,clock_timestamp(), ente_proprietario_id_in,
                login_operazione_in||' - '||'fnc_siac_riccertamento' );

                /*INSERT INTO siac.tmp_riaccertamento_debug(tmp_mod_id_in,
                tmp_login_operazione_in, tmp_tipo_operazione_in, tmp_movgest_ts_r_id,
                tmp_movgest_ts_importo, tmp_importo_mod_da_scalare, esito)
                VALUES (mod_id_in, login_operazione_in, tipo_operazione_in,
                recListaCollegata.movgest_ts_r_id, recListaCollegata.movgest_ts_importo,- importo_sum_det_mod_da_scalare,
                'ok=');*/

                importo_sum_det_mod_da_scalare:= importo_sum_det_mod_da_scalare - importo_sum_det_mod_da_scalare;

              end if;
          end if;
       --  esito:='ok';
      end loop;
      ----------nuova sez fine -------------
      return next;
	  
	-- end if;

	end if;
	--25.05.2020 FL SIAC-7349 Fine SR.SR165.SR167.SR169

     

elsif tipo_operazione_in = 'ANNULLA' then

    for recannullamento in
    select a.* from siac_r_modifica_vincolo a where a.modvinc_tipo_operazione='INSERIMENTO'
    and a.mod_id=mod_id_in
    and a.data_cancellazione is null
    and now() between a.validita_inizio and coalesce(a.validita_fine,now())

    loop

    --aggiorna importo riportandolo a situazione pre riaccertamento
    update siac_r_movgest_ts set movgest_ts_importo=movgest_ts_importo-recannullamento.importo_delta
    where movgest_ts_r_id=recannullamento.movgest_ts_r_id;

    --inserisce record di ANNULLAMENTO con importo_delta=-importo_delta
    INSERT INTO
      siac.siac_r_modifica_vincolo
    (
      mod_id,
      movgest_ts_r_id,
      modvinc_tipo_operazione,
      importo_delta,
      validita_inizio,
      ente_proprietario_id,
      login_operazione
    )
    values (recannullamento.mod_id,
    recannullamento.movgest_ts_r_id,
    'ANNULLAMENTO',--tipo_operazione_in,
    -recannullamento.importo_delta,
    clock_timestamp(),
    recannullamento.ente_proprietario_id,
    login_operazione_in||' - '||'fnc_siac_riccertamento'
    );

    --annulla precedente modifica in INSERIMENTO
    update siac_r_modifica_vincolo set validita_fine=clock_timestamp()
    where modvinc_id=recannullamento.modvinc_id
    ;
    esito:='ok';

    --insert tabella debug
    /*  INSERT INTO
      siac.tmp_riaccertamento_debug
    (
      tmp_mod_id_in,
      tmp_login_operazione_in,
      tmp_tipo_operazione_in,
      tmp_movgest_ts_r_id,
      tmp_movgest_ts_importo,
      tmp_importo_mod_da_scalare,
      esito
    )
    VALUES (
      mod_id_in,
      login_operazione_in,
      tipo_operazione_in,
      recannullamento.movgest_ts_r_id,
      null,
      -recannullamento.importo_delta,
      esito
    );
*/

    end loop;
    return next;

end if;----tipo_operazione_in = 'INSERIMENTO'

/*if esito='oknodata' then
INSERT INTO
  siac.tmp_riaccertamento_debug
(
  tmp_mod_id_in,
  tmp_login_operazione_in,
  tmp_tipo_operazione_in,
esito
) VALUES(
 mod_id_in,
  login_operazione_in,
  tipo_operazione_in,
  esito);

end if;
*/

EXCEPTION
WHEN others THEN
  esito:='ko';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_riaccertamento(integer, character varying, character varying)
    OWNER TO siac; 
--end fnc_siac_riaccertamento

--start fnc_siac_dicuiimpegnatoug_comp_anno
CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno(
	id_in integer,
	anno_in character varying,
	verifica_mod_prov boolean DEFAULT true)
    RETURNS TABLE(annocompetenza character varying, dicuiimpegnato numeric) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
AS $BODY$
DECLARE

-- constant
TIPO_CAP_UG constant varchar:='CAP-UG';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';

TIPO_IMP    constant varchar:='I';
TIPO_IMP_T  constant varchar:='T';

STATO_DEF   constant varchar:='D';
STATO_N     constant varchar:='N';
STATO_P     constant varchar:='P';
STATO_A     constant varchar:='A';
IMPORTO_ATT constant varchar:='A';

STATO_MOD_V  constant varchar:='V';
STATO_ATTO_P constant varchar:='PROVVISORIO';

-- anna_economie inizio
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoModifINS  numeric:=0;
-- anna_economie fine

strMessaggio varchar(1500):=NVL_STR;

bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;

movGestTipoId integer:=0;
movGestTsTipoId integer:=0;
movGestStatoId integer:=0;
movGestTsDetTipoId integer:=0;

movGestTsId integer:=0;

importoAttuale numeric:=0;
importoCurAttuale numeric:=0;
importoModifNeg  numeric:=0;

modStatoVId integer:=0;
attoAmmStatoPId integer:=0;

movGestIdRec record;

esisteRmovgestidelemid INTEGER:=0;

BEGIN

select el.elem_id into esisteRmovgestidelemid from siac_r_movgest_bil_elem el, siac_t_movgest mv
where
mv.movgest_id=el.movgest_id
and el.elem_id=id_in
and mv.movgest_anno=anno_in::integer
;

 -- 02.02.2016 Sofia JIRA 2947
if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;

if esisteRmovgestidelemid <>0 then

 annoCompetenza:=null;
 diCuiImpegnato:=0;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.Controllo parametri.';

 if anno_in is null or anno_in=NVL_STR then
	 RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
	 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
 end if;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
			   ||'.Calcolo bilancioId enteProprietarioId  annoBilancio.';

 select bil.bil_id,  bil.ente_proprietario_id,  per.anno
        into strict bilancioId, enteProprietarioId, annoBilancio
 from siac_t_bil bil,siac_t_bil_elem bilElem, siac_t_periodo per
 where bilElem.elem_id=id_in
 and   bilElem.data_cancellazione is null
 and   bil.bil_id=bilElem.bil_id
 and   per.periodo_id=bil.periodo_id;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTipoId.';
 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
 from  siac_d_movgest_tipo tipoMovGest
 where tipoMovGest.ente_proprietario_id=enteProprietarioId
 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsTipoId.';
/* select movGestTsTipo.movgest_ts_tipo_id into strict movGestTsTipoId
 from siac_d_movgest_ts_tipo movGestTsTipo
 where movGestTsTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsTipo.movgest_ts_tipo_code=TIPO_IMP_T;
*/
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsStatoId.';

 select movGestStato.movgest_stato_id into strict movGestStatoId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_A;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsDetTipoId.';

 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

 -- 16.03.2017 Sofia JIRA-SIAC-4614
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo modStatoVId.';
 select d.mod_stato_id into strict modStatoVId
 from siac_d_modifica_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.mod_stato_code=STATO_MOD_V;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo attoAmmStatoPId.';
 select d.attoamm_stato_id into strict attoAmmStatoPId
 from siac_d_atto_amm_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.attoamm_stato_code=STATO_ATTO_P;
 -- 16.03.2017 Sofia JIRA-SIAC-4614

 -- anna_economie inizio
 select d.attoamm_stato_id into strict attoAmmStatoDId
 from siac_d_atto_amm_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.attoamm_stato_code=STATO_ATTO_D;
 -- anna_economie fine

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Inizio calcolo totale importo attuale impegni per anno_in='||anno_in||'.';

 --nuovo G
   	importoCurAttuale:=0;

    select tb.importo into importoCurAttuale
 from (
  select
      coalesce(sum(e.movgest_ts_det_importo),0)  importo
      , c.movgest_ts_tipo_id
    from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id=a.movgest_id and
      a.elem_id=id_in
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
      and c.movgest_id=b.movgest_id
      and d.movgest_ts_id=c.movgest_ts_id
      and d.validita_fine is null
      and e.movgest_ts_id=c.movgest_ts_id
	and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
     and e.data_cancellazione is null
     and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
    and e.movgest_ts_det_tipo_id=movGestTsDetTipoId
    group by
   c.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;

/*select tb.importo into importoCurAttuale from (
  select
      coalesce(sum(e.movgest_ts_det_importo),0)  importo
      , c.movgest_ts_tipo_id
      from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id= ANY (VALUES (a.movgest_id)) and
      a.elem_id=id_in
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
      and c.movgest_id=b.movgest_id
      and d.movgest_ts_id=c.movgest_ts_id
      and d.validita_fine is null
      and e.movgest_ts_id=c.movgest_ts_id
	and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
     and e.data_cancellazione is null
     and f.movgest_ts_det_tipo_id=ANY (VALUES (e.movgest_ts_det_tipo_id))
    and e.movgest_ts_det_tipo_id=ANY (VALUES (movGestTsDetTipoId))
    group by c.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    and t.movgest_ts_tipo_code=TIPO_IMP_T;--'T'; */

 /* select
      coalesce(sum(e.movgest_ts_det_importo),0) into importoCurAttuale
      from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id= ANY (VALUES (a.movgest_id)) and
      a.elem_id=id_in
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
      and c.movgest_id=b.movgest_id
      and d.movgest_ts_id=c.movgest_ts_id
      and e.movgest_ts_id=c.movgest_ts_id
	and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
     and e.data_cancellazione is null
     and f.movgest_ts_det_tipo_id=ANY (VALUES (e.movgest_ts_det_tipo_id))
    and e.movgest_ts_det_tipo_id=ANY (VALUES (movGestTsDetTipoId));*/

  --raise notice 'importoCurAttuale:%', importoCurAttuale;
 --fine nuovo G
 /*for movGestIdRec in
 (
     select movGestRel.movgest_id
     from siac_r_movgest_bil_elem movGestRel
     where movGestRel.elem_id=id_in
     and   movGestRel.data_cancellazione is null
     and   exists (select 1 from siac_t_movgest movGest
   				   where movGest.movgest_id=movGestRel.movgest_id
			       and	 movGest.bil_id = bilancioId
			       and   movGest.movgest_tipo_id=movGestTipoId
				   and   movGest.movgest_anno = anno_in::integer)
 )
 loop
   	importoCurAttuale:=0;

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
                      ||'.Calcolo impegnato anno_in='||anno_in
                      ||'.Lettura siac_t_movgest_ts movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';

    select movgestts.movgest_ts_id into  movGestTsId
    from siac_t_movgest_ts movGestTs
    where movGestTs.movgest_id = movGestIdRec.movgest_id
    and   movGestTs.data_cancellazione is null
    and   movGestTs.movgest_ts_tipo_id=movGestTsTipoId
    and   exists (select 1 from siac_r_movgest_ts_stato movGestTsRel
                  where movGestTsRel.movgest_ts_id=movGestTs.movgest_ts_id
                  and   movGestTsRel.movgest_stato_id!=movGestStatoId);

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
                      ||'.Calcolo accertato anno_in='||anno_in||'Somma siac_t_movgest_ts_det movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';
    if NOT FOUND then
    else
       select coalesce(sum(movGestTsDet.movgest_ts_det_importo),0) into importoCurAttuale
           from siac_t_movgest_ts_det movGestTsDet
           where movGestTsDet.movgest_ts_id=movGestTsId
           and   movGestTsDet.movgest_ts_det_tipo_id=movGestTsDetTipoId;
    end if;

    importoAttuale:=importoAttuale+importoCurAttuale;
 end loop;*/
 -- 02.02.2016 Sofia JIRA 2947
 if importoCurAttuale is null then importoCurAttuale:=0; end if;

 -- 16.03.2017 Sofia JIRA-SIAC-4614
-- if importoCurAttuale>0 then
 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

  strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Calcolo totale modifiche negative su atti provvisori per anno_in='||anno_in||'.';

 select tb.importo into importoModifNeg
 from
 (
 	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
    	 siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
	     siac_t_movgest_ts_det_mod moddet,
    	 siac_t_modifica mod, siac_r_modifica_stato rmodstato,
	     siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
         siac_d_modifica_tipo tipom
	where rbil.elem_id=id_in
	and	  mov.movgest_id=rbil.movgest_id
	and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
    and   mov.movgest_anno=anno_in::integer
    and   mov.bil_id=bilancioId
	and   ts.movgest_id=mov.movgest_id
	and   rstato.movgest_ts_id=ts.movgest_ts_id
	and   rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
	and   tsdet.movgest_ts_id=ts.movgest_ts_id
	and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	and   moddet.movgest_ts_det_importo<0 -- importo negativo
	and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
	and   mod.mod_id=rmodstato.mod_id
	and   atto.attoamm_id=mod.attoamm_id
	and   attostato.attoamm_id=atto.attoamm_id
	and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
    and   tipom.mod_tipo_id=mod.mod_tipo_id
    and   tipom.mod_tipo_code <> 'ECONB'
	-- date
	and rbil.data_cancellazione is null
	and rbil.validita_fine is null
	and mov.data_cancellazione is null
	and mov.validita_fine is null
	and ts.data_cancellazione is null
	and ts.validita_fine is null
	and rstato.data_cancellazione is null
	and rstato.validita_fine is null
	and tsdet.data_cancellazione is null
	and tsdet.validita_fine is null
	and moddet.data_cancellazione is null
	and moddet.validita_fine is null
	and mod.data_cancellazione is null
	and mod.validita_fine is null
	and rmodstato.data_cancellazione is null
	and rmodstato.validita_fine is null
	and attostato.data_cancellazione is null
	and attostato.validita_fine is null
	and atto.data_cancellazione is null
	and atto.validita_fine is null
    group by ts.movgest_ts_tipo_id
  ) tb, siac_d_movgest_ts_tipo tipo
  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
  order by tipo.movgest_ts_tipo_code desc
  limit 1;
  -- 21.06.2017 Sofia - aggiunto parametro verifica_mod_prov, ripreso da prod CmTo dove era stato implementato
  if importoModifNeg is null or verifica_mod_prov is false then importoModifNeg:=0; end if;

  -- anna_economie inizio
   select tb.importo into importoModifINS
 from
 (
 	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
    	 siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
	     siac_t_movgest_ts_det_mod moddet,
    	 siac_t_modifica mod, siac_r_modifica_stato rmodstato,
	     siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
         siac_d_modifica_tipo tipom
	where rbil.elem_id=id_in
	and	  mov.movgest_id=rbil.movgest_id
	and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
    and   mov.movgest_anno=anno_in::integer
    and   mov.bil_id=bilancioId
	and   ts.movgest_id=mov.movgest_id
	and   rstato.movgest_ts_id=ts.movgest_ts_id
	and   rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
	and   tsdet.movgest_ts_id=ts.movgest_ts_id
	and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	-- SIAC-7349
	-- abbiamo tolto il commento nella riga qui sotto perche' d'accordo con Pietro Gambino 
	-- e visto che possono anche esserci modifiche ECONB positive
	-- e' bene escluderle dal calcolo importoModifINS
	and   moddet.movgest_ts_det_importo<0 -- importo negativo
	and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
	and   mod.mod_id=rmodstato.mod_id
	and   atto.attoamm_id=mod.attoamm_id
	and   attostato.attoamm_id=atto.attoamm_id
	and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
    and   tipom.mod_tipo_id=mod.mod_tipo_id
    and   tipom.mod_tipo_code = 'ECONB'
	-- date
	and rbil.data_cancellazione is null
	and rbil.validita_fine is null
	and mov.data_cancellazione is null
	and mov.validita_fine is null
	and ts.data_cancellazione is null
	and ts.validita_fine is null
	and rstato.data_cancellazione is null
	and rstato.validita_fine is null
	and tsdet.data_cancellazione is null
	and tsdet.validita_fine is null
	and moddet.data_cancellazione is null
	and moddet.validita_fine is null
	and mod.data_cancellazione is null
	and mod.validita_fine is null
	and rmodstato.data_cancellazione is null
	and rmodstato.validita_fine is null
	and attostato.data_cancellazione is null
	and attostato.validita_fine is null
	and atto.data_cancellazione is null
	and atto.validita_fine is null
    group by ts.movgest_ts_tipo_id
  ) tb, siac_d_movgest_ts_tipo tipo
  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
  order by tipo.movgest_ts_tipo_code desc
  limit 1;
  
  if importoModifINS is null then importoModifINS:=0; end if;
  
  -- anna_economie fine

 end if;

 --nuovo G
 importoAttuale:=importoAttuale+importoCurAttuale+abs(importoModifNeg); -- 16.03.2017 Sofia JIRA-SIAC-4614
 --fine nuovoG

 -- anna_economie inizio
 importoAttuale:=importoAttuale+abs(importoModifINS);
 -- anna_economie fine 

 annoCompetenza:=anno_in;
 diCuiImpegnato:=importoAttuale;

 return next;

else

annoCompetenza:=anno_in;
diCuiImpegnato:=0;

return next;

end if;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
	when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno(integer, character varying, boolean)
    OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno(integer, character varying, boolean) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno(integer, character varying, boolean) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno(integer, character varying, boolean) TO siac;

--end fnc_siac_dicuiimpegnatoug_comp_anno

-- Aggiunte/modificate per versione 4.26
    
-- start fnc_siac_impegnatodefinitivoup_comp_triennio_nostanz

/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp_triennio_nostanz(
	id_in integer,
	idcomp_in integer[])
    RETURNS TABLE(elemdetcompid integer, elemdetcompdesc character varying, annoimpegnato integer, impegnatodefinitivo numeric, elemdetcompmacrotipodesc character varying) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
AS $BODY$
DECLARE

annoBilancio varchar:=null;
annoEsercizio varchar:=null;
annoMovimento varchar:=null;

elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;
NVL_STR     constant varchar:='';
faseOpCode varchar(20):=NVL_STR;
bilancioId integer:=0;
elemTipoCode VARCHAR(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;
enteProprietarioId INTEGER:=0;
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
FASE_OP_BIL_PREV constant VARCHAR:='P';
STATO_A     constant varchar:='A';
STATO_P     constant varchar:='P';
TIPO_IMP    constant varchar:='I';
movGestStatoIdAnnullato integer:=0;
movGestStatoIdProvvisorio integer:=0;
movGestTipoId integer:=0;
IMPORTO_ATT constant varchar:='A';
movGestTsDetTipoId integer:=0;
IMPORTO_INIZIALE constant varchar:='I';
movGestTsDetTipoIdIniziale integer:=0;
STATO_MOD_V  constant varchar:='V';
modStatoVId integer:=0;
attoAmmStatoPId integer:=0;
STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoCurAttuale numeric:=0;
esisteRmovgestidelemid INTEGER:=0;
importoModifDelta  numeric:=0;
importoModifINS numeric:=0; --aggiunta per ECONB
impegniDaRibaltamento integer:=0;
pluriennaliDaRibaltamento integer:=0;
flagNMaggioreNPiu2 integer:=0;
flagDeltaPagamenti integer:=0;
importoImpegnato numeric:=0;
importoPagatoDelta numeric:=0;
ordStatoAId          integer:=null;
ordTsDetTipoAId      integer:=null;
-- stati ordinativi
STATO_ORD_A    constant varchar:='A'; -- ANNULLATO
-- importoAttuale ordinativi
ORD_TS_DET_TIPO_A  constant varchar:='A';

sidcomp_in  varchar:=null;
strMessaggio varchar(1500):=null;

impComponenteRec record;

BEGIN

/* Calcola impegnato definitivo per quelle componenti per le quali pur non essendoci stanziamento
 * esistono quote di impegnato nel triennio
 * Le componenti per le quali esiste stanziamento (e quindi da non considerare) sono passate in input nell'array idcomp_in
 * NOTA: per problemi Java/Hibernate idcomp_in non puo essere un array vuoto, quindi 
 *		l'array in input conterra' sempre la componente fittizia idcomp = -1
 */
-- CALCOLO IMPEGNATO DEFINITIVO 
-- Stiamo sempre parlando di impegnato sul capitolo di gestione equivalente	

	sidcomp_in:=array_to_string(idcomp_in, ',');
    	strMessaggio:='Calcolo totale impegnato definitovo elem_id='||id_in|| ' escludo idcomp_in='||sidcomp_in|| '.';
	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;
 
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||
    			  '.Lettura anno di bilancio del capitolo UP.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;
	strMessaggio:=strMessaggio || 'annoBilancio='||annoBilancio|| '.';

		  

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||
    			  '. Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId e elem_tipo_code.';
	 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
	 into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
	 from 	siac_t_bil_elem bilElem, 
	 		siac_d_bil_elem_tipo tipoBilElem,
		  	siac_t_bil bil, siac_t_periodo per
	 where bilElem.elem_id=id_in
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
	   and bil.bil_id=bilElem.bil_id
	   and per.periodo_id=bil.periodo_id;

	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UP then
			RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
	 end if;

	 strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||
				   '. Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   'Calcolo fase operativa per bilancioId='||bilancioId
				   ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select  faseOp.fase_operativa_code into  faseOpCode
	 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
	 where bilFase.bil_id =bilancioId
	   and bilfase.data_cancellazione is null
	   and bilFase.validita_fine is null
	   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
	   and faseOp.data_cancellazione is null
	 order by bilFase.bil_fase_operativa_id desc;

	 if NOT FOUND THEN
	   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
	 end if;

	 strMessaggio:='Calcolo impegnato definitivo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO'
				  ||'. Calcolo movGestTsStatoIdProvvisorio per movgest_stato_code=PROVVISORIO';

	 select movGestStato.movgest_stato_id into strict movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;

	 select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_P; 
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTsDetTipoId per movgest_ts_det_tipo_code=IMPORTO ATTUALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE;
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
              ||'. Calcolo modStatoVId per mod_stato_code=VALIDO.';
	 select d.mod_stato_id into strict modStatoVId
	 from siac_d_modifica_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.mod_stato_code=STATO_MOD_V;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	 select d.attoamm_stato_id into strict attoAmmStatoPId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_P;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINITIVO';
	 select d.attoamm_stato_id into strict attoAmmStatoDId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_D;

 	-- Calcolo Impegnato definitivo - Anno N:
	-- Verifica se presenti i movimenti di gestione provenienti dal ribaltamento
	-- Per "ribaltamento" si intende  il batch di ribaltamento residui che gira prima del ROR 
	--	e che "copia" gli impegni dell'anno N-1 nel bilancio dell'anno N (di solito il 2 gennaio)
	-- Per verificare che il batch di ribaltamento sia stato eseguito controllo le seguenti tabelle
	-- 		fase_bil_t_gest_apertura_liq_imp per gli impegni residui
	--  	fase_bil_t_gest_apertura_pluri per i pluriennli (sia impegni che accertamenti)
	-- In entrambe c'e' sia il bil_id che il bil_id_orig ovvero l'anno nuovo su cui si stanno ribaltando i movimenti e l'anno prec
	-- c'e' anche un campo fl_elab che ti dice se i dati sono stati elaborati con scarto o con successo 

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
				 '.Verifica se presenti i movimenti di gestione provenienti dal ribaltamento per anno di esercizio N.';
	
	impegniDaRibaltamento:=0;
	pluriennaliDaRibaltamento:=0;
	importoCurAttuale:=0;	
	importoModifDelta:=0;
	importoModifINS := 0;
	
	select  count(*) into impegniDaRibaltamento 
	from fase_bil_t_gest_apertura_liq_imp fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;

	select  count(*) into  pluriennaliDaRibaltamento
	from fase_bil_t_gest_apertura_pluri fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;

	strMessaggio:=strMessaggio || 'impegniDaRibaltamento='||impegniDaRibaltamento|| '.';
	strMessaggio:=strMessaggio || 'pluriennaliDaRibaltamento='||pluriennaliDaRibaltamento|| '.';

	if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then

	-- - Se presenti i movimenti gestione provenienti dal ribaltamento 
		annoEsercizio:=annoBilancio;
		annoMovimento:=annoBilancio;
	else

		-- - Se non presenti i movimenti gestione provenienti dal ribaltamento 
		annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
		annoMovimento:=annoBilancio;
	end if;
	
	strMessaggio:=strMessaggio || 'annoEsercizio='||annoEsercizio|| '.';
	strMessaggio:=strMessaggio || 'annoMovimento='||annoMovimento|| '.';


	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    -- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';
	strMessaggio:=strMessaggio || 'bilIdElemGestEq='||bilIdElemGestEq|| '.';


	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo impegnato competenza UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;
	strMessaggio:=strMessaggio || 'elemIdGestEq='||elemIdGestEq|| '.';

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else
	
		strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento|| 
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid 
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno IN (annoMovimento::integer,  annoMovimento::integer+1, annoMovimento::integer+2)
			and NOT (el.elem_det_comp_tipo_id = ANY( idcomp_in)) --SIAC-7349
			;
		
		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;

		strMessaggio:=strMessaggio || 'esisteRmovgestidelemid='||esisteRmovgestidelemid|| '.';


		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

			/* Versione con group by per le componenti non da escludere e ciclo per ogni componente */
			for impComponenteRec in
			 (
				select tb.elem_det_comp_tipo_id as compId, 
				 g.elem_det_comp_tipo_desc as compDesc, 
				 tb.importo as importoCurAttuale,
				 h.elem_det_comp_macro_tipo_desc as compMacroTipoDesc,
				 tb.movgest_anno as annualita
				from (
				  select
					  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id, a.elem_det_comp_tipo_id, b.movgest_anno
				  from
					  siac_r_movgest_bil_elem a,
					  siac_t_movgest b,
					  siac_t_movgest_ts c,
					  siac_r_movgest_ts_stato d,
					  siac_t_movgest_ts_det e,
					  siac_d_movgest_ts_det_tipo f
				  where
					  b.movgest_id=a.movgest_id 
					  and a.elem_id=elemIdGestEq 
					  and NOT( a.elem_det_comp_tipo_id = ANY(idcomp_in)) --SIAC-7349 --id componente diversa da quella ricevuta in input
					  and b.bil_id = bilIdElemGestEq
					  and b.movgest_tipo_id=movGestTipoId
					  and d.movgest_stato_id<>movGestStatoIdAnnullato
					  -- SIAC-7737 GS 31/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				      -- and d.movgest_stato_id<>movGestStatoIdProvvisorio
					  and b.movgest_anno IN (annoMovimento::integer,  annoMovimento::integer+1, annoMovimento::integer+2)
					  and c.movgest_id=b.movgest_id
					  and d.movgest_ts_id=c.movgest_ts_id
					  and d.validita_fine is null
					  and e.movgest_ts_id=c.movgest_ts_id
					  and a.data_cancellazione is null
					  and b.data_cancellazione is null
					  and c.data_cancellazione is null
					  and e.data_cancellazione is null
					  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
					  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId
					  group by 	c.movgest_ts_tipo_id, 
								a.elem_det_comp_tipo_id, -- SIAC-7349
								b.movgest_anno
					) tb, 
					siac_d_movgest_ts_tipo t,
					siac_d_bil_elem_det_comp_tipo g,
				 	siac_d_bil_elem_det_comp_macro_tipo h
				where 
					tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
					and g.elem_det_comp_tipo_id = tb.elem_det_comp_tipo_id --SIAC-7349 recupera anche la descrizione della componente
					and g.elem_det_comp_macro_tipo_id = h.elem_det_comp_macro_tipo_id --SIAC-7349 recupera anche la descrizione del macrotipo della componente
				 order by t.movgest_ts_tipo_code desc
 			) 
			loop
			

					-- 02.02.2016 Sofia JIRA 2947
					 if impComponenteRec.importoCurAttuale is null then impComponenteRec.importoCurAttuale:=0; end if;

					 -- 16.03.2017 Sofia JIRA-SIAC-4614
					-- if importoCurAttuale>0 then
					 if impComponenteRec.importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

						strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'  impComponenteRec.compId='||impComponenteRec.compId||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Calcolo totale modifiche su atti provvisori per annoMovimento='||annoMovimento||'.';

						select tb.importo into importoModifDelta
						 from
						 (
							select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
							from siac_r_movgest_bil_elem rbil, 
								 siac_t_movgest mov,
								 siac_t_movgest_ts ts,
								 siac_r_movgest_ts_stato rstato,
								 siac_t_movgest_ts_det tsdet,
								 siac_t_movgest_ts_det_mod moddet,
								 siac_t_modifica mod, 
								 siac_r_modifica_stato rmodstato,
								 siac_r_atto_amm_stato attostato, 
								 siac_t_atto_amm atto,
								 siac_d_modifica_tipo tipom
							where 
								rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
								and rbil.elem_det_comp_tipo_id=impComponenteRec.compId --SIAC-7349 deve essere sulla compoenente del record 
								and	  mov.movgest_id=rbil.movgest_id
								and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
								and   mov.movgest_anno>annoMovimento::integer -- anno dell impegno = annoMovimento 
								and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
								and   ts.movgest_id=mov.movgest_id
								and   rstato.movgest_ts_id=ts.movgest_ts_id
								and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
							    -- SIAC-7737 GS 31/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
						        -- and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
								and   tsdet.movgest_ts_id=ts.movgest_ts_id
								and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
								and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
								-- SIAC-7349 Prendo tutti gli importi, sia con segno negativo che con segno positivo
								-- La loro somma produce il valore importoModifDelta che devo sottrarre all'impegnato calcolato
								-- ad esempio: modifiche su atto provv +100, -322 -> somma -222 si tratta di un delta che devo sottrarre
								-- all'impegnato calcolato = impegnato calcolato - (-222) = +222 (aggiungo quello che avevo tolto)
								-- and   moddet.movgest_ts_det_importo<0 -- importo negativo
								and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
								and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
								and   mod.mod_id=rmodstato.mod_id
								and   atto.attoamm_id=mod.attoamm_id
								and   attostato.attoamm_id=atto.attoamm_id
								and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
								and   tipom.mod_tipo_id=mod.mod_tipo_id
								and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
								-- date
								and rbil.data_cancellazione is null
								and rbil.validita_fine is null
								and mov.data_cancellazione is null
								and mov.validita_fine is null
								and ts.data_cancellazione is null
								and ts.validita_fine is null
								and rstato.data_cancellazione is null
								and rstato.validita_fine is null
								and tsdet.data_cancellazione is null
								and tsdet.validita_fine is null
								and moddet.data_cancellazione is null
								and moddet.validita_fine is null
								and mod.data_cancellazione is null
								and mod.validita_fine is null
								and rmodstato.data_cancellazione is null
								and rmodstato.validita_fine is null
								and attostato.data_cancellazione is null
								and attostato.validita_fine is null
								and atto.data_cancellazione is null
								and atto.validita_fine is null
								group by ts.movgest_ts_tipo_id
							  ) tb, siac_d_movgest_ts_tipo tipo
							  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
							  order by tipo.movgest_ts_tipo_code desc
							  limit 1;		

						if importoModifDelta is null then importoModifDelta:=0; end if;
						  /*Aggiunta delle modifiche ECONB*/
						 -- anna_economie inizio
						select tb.importo into importoModifINS
						from
						(
							select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
							from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
							siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
							siac_t_movgest_ts_det_mod moddet,
							siac_t_modifica mod, siac_r_modifica_stato rmodstato,
							siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
							siac_d_modifica_tipo tipom
						where rbil.elem_id=elemIdGestEq
						and rbil.elem_det_comp_tipo_id=impComponenteRec.compId --SIAC-7349
						and	  mov.movgest_id=rbil.movgest_id
						and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
						and   mov.movgest_anno=annoMovimento::integer
						and   mov.bil_id=bilancioId
						and   ts.movgest_id=mov.movgest_id
						and   rstato.movgest_ts_id=ts.movgest_ts_id
						and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- impegno non annullato
						and   tsdet.movgest_ts_id=ts.movgest_ts_id
						and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
						and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
					   and   tipom.mod_tipo_id=mod.mod_tipo_id
					   and   tipom.mod_tipo_code = 'ECONB'
						-- date
						and rbil.data_cancellazione is null
						and rbil.validita_fine is null
						and mov.data_cancellazione is null
						and mov.validita_fine is null
						and ts.data_cancellazione is null
						and ts.validita_fine is null
						and rstato.data_cancellazione is null
						and rstato.validita_fine is null
						and tsdet.data_cancellazione is null
						and tsdet.validita_fine is null
						and moddet.data_cancellazione is null
						and moddet.validita_fine is null
						and mod.data_cancellazione is null
						and mod.validita_fine is null
						and rmodstato.data_cancellazione is null
						and rmodstato.validita_fine is null
						and attostato.data_cancellazione is null
						and attostato.validita_fine is null
						and atto.data_cancellazione is null
						and atto.validita_fine is null
					   group by ts.movgest_ts_tipo_id
					 ) tb, siac_d_movgest_ts_tipo tipo
					 where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
					 order by tipo.movgest_ts_tipo_code desc
					 limit 1;

					 if importoModifINS is null then 
						importoModifINS = 0;
					 end if;

					end if;		
	
			--Fix MR adeguamento sprint 5
			-- Mon restituiamo piu' al valore impegnato le modifiche provvisorie e le ECONB
           		importoModifDelta:=0;
            		importoModifINS:=0;
            --
			
			annoimpegnato:=impComponenteRec.annualita;
			elemDetCompId:=impComponenteRec.compId;
			elemdetcompdesc:=impComponenteRec.compDesc;
			elemdetcompmacrotipodesc:=impComponenteRec.compMacroTipoDesc;
			impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente  
			impegnatoDefinitivo:=impegnatoDefinitivo+impComponenteRec.importoCurAttuale-(importoModifDelta);
			--aggiunta per ECONB
			impegnatoDefinitivo:=impegnatoDefinitivo+abs(importoModifINS);
			return next;	

	end loop;
	end if;
	end if;

	return;
 

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
		return;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
		return;
END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp_triennio_nostanz(integer, integer[])
    OWNER TO siac;

-- end fnc_siac_impegnatodefinitivoup_comp_triennio_nostanz

-- start fnc_siac_impegnatodefinitivoug_comp_triennio_nostanz
/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatodefinitivoug_comp_triennio_nostanz(
	id_in integer,
	idcomp_in integer[])
    RETURNS TABLE(elemdetcompid integer, elemdetcompdesc character varying, annoimpegnato integer, impegnatodefinitivo numeric, elemdetcompmacrotipodesc character varying) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
AS $BODY$
DECLARE

annoBilancio varchar:=null;
annoEsercizio varchar:=null;
annoMovimento varchar:=null;

elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;
NVL_STR     constant varchar:='';
faseOpCode varchar(20):=NVL_STR;
bilancioId integer:=0;
elemTipoCode VARCHAR(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;
enteProprietarioId INTEGER:=0;
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
FASE_OP_BIL_PREV constant VARCHAR:='P';
STATO_A     constant varchar:='A';
STATO_P     constant varchar:='P';
TIPO_IMP    constant varchar:='I';
movGestStatoIdAnnullato integer:=0;
movGestStatoIdProvvisorio integer:=0;
movGestTipoId integer:=0;
IMPORTO_ATT constant varchar:='A';
movGestTsDetTipoId integer:=0;
IMPORTO_INIZIALE constant varchar:='I';
movGestTsDetTipoIdIniziale integer:=0;
STATO_MOD_V  constant varchar:='V';
modStatoVId integer:=0;
attoAmmStatoPId integer:=0;
STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoCurAttuale numeric:=0;
esisteRmovgestidelemid INTEGER:=0;
importoModifDelta  numeric:=0;
importoModifINS numeric:=0; --aggiunta per ECONB
impegniDaRibaltamento integer:=0;
pluriennaliDaRibaltamento integer:=0;
flagNMaggioreNPiu2 integer:=0;
flagDeltaPagamenti integer:=0;
importoImpegnato numeric:=0;
importoPagatoDelta numeric:=0;
ordStatoAId          integer:=null;
ordTsDetTipoAId      integer:=null;
-- stati ordinativi
STATO_ORD_A    constant varchar:='A'; -- ANNULLATO
-- importoAttuale ordinativi
ORD_TS_DET_TIPO_A  constant varchar:='A';

sidcomp_in  varchar:=null;
strMessaggio varchar(1500):=null;

impComponenteRec record;

BEGIN

/* Calcola impegnato definitivo per quelle componenti per le quali pur non essendoci stanziamento
 * esistono quote di impegnato nel triennio
 * Le componenti per le quali esiste stanziamento (e quindi da non considerare) sono passate in input nell'array idcomp_in
 * NOTA: per problemi Java/Hibernate idcomp_in non puo essere un array vuoto, quindi 
 *		l'array in input conterra' sempre la componente fittizia idcomp = -1
 */
-- CALCOLO IMPEGNATO DEFINITIVO 
-- Stiamo sempre parlando di impegnato sul capitolo di gestione equivalente	

	sidcomp_in:=array_to_string(idcomp_in, ',');
    	strMessaggio:='Calcolo totale impegnato definitovo elem_id='||id_in|| ' escludo idcomp_in='||sidcomp_in|| '.';

	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;
 
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||
    			  '.Lettura anno di bilancio del capitolo UP.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;
	strMessaggio:=strMessaggio || 'annoBilancio='||annoBilancio|| '.';

		  

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||
 
 				   '. Calcolo bilancioId e elem_tipo_code.';
	 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
	 into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
	 from 	siac_t_bil_elem bilElem, 
	 		siac_d_bil_elem_tipo tipoBilElem,
		  	siac_t_bil bil, siac_t_periodo per
	 where bilElem.elem_id=id_in
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
	   and bil.bil_id=bilElem.bil_id
	   and per.periodo_id=bil.periodo_id;


	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UG then
			RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
	 end if;

	 strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||

				   'Calcolo fase operativa per bilancioId='||bilancioId
				   ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select  faseOp.fase_operativa_code into  faseOpCode
	 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
	 where bilFase.bil_id =bilancioId
	   and bilfase.data_cancellazione is null
	   and bilFase.validita_fine is null
	   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
	   and faseOp.data_cancellazione is null
	 order by bilFase.bil_fase_operativa_id desc;

	 if NOT FOUND THEN
	   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
	 end if;

	 strMessaggio:='Calcolo impegnato definitivo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO'
				  ||'. Calcolo movGestTsStatoIdProvvisorio per movgest_stato_code=PROVVISORIO';

	 select movGestStato.movgest_stato_id into strict movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;

	 select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_P; 
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTsDetTipoId per movgest_ts_det_tipo_code=IMPORTO ATTUALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE;
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
              ||'. Calcolo modStatoVId per mod_stato_code=VALIDO.';
	 select d.mod_stato_id into strict modStatoVId
	 from siac_d_modifica_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.mod_stato_code=STATO_MOD_V;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	 select d.attoamm_stato_id into strict attoAmmStatoPId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_P;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINITIVO';
	 select d.attoamm_stato_id into strict attoAmmStatoDId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_D;

 	-- Calcolo Impegnato definitivo 

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in;
	
	importoCurAttuale:=0;	
	importoModifDelta:=0;
	importoModifINS := 0;
	
	-- - Se presenti i movimenti gestione provenienti dal ribaltamento 
		annoEsercizio:=annoBilancio;
		annoMovimento:=annoBilancio;
	
	strMessaggio:=strMessaggio || 'annoEsercizio='||annoEsercizio|| '.';
	strMessaggio:=strMessaggio || 'annoMovimento='||annoMovimento|| '.';


	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
				   '. Calcolo bilancioId per annoEsercizio='||annoEsercizio
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    -- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';
	strMessaggio:=strMessaggio || 'bilIdElemGestEq='||bilIdElemGestEq|| '.';


	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo impegnato competenza UG.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;
	strMessaggio:=strMessaggio || 'elemIdGestEq='||elemIdGestEq|| '.';


	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else
	
		strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento|| 
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid 
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno IN (annoMovimento::integer,  annoMovimento::integer+1, annoMovimento::integer+2) 
			and NOT (el.elem_det_comp_tipo_id = ANY( idcomp_in)) --SIAC-7349
			;
		
		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;

		strMessaggio:=strMessaggio || 'esisteRmovgestidelemid='||esisteRmovgestidelemid|| '.';


		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

			/* Versione con group by per le componenti non da escludere e ciclo per ogni componente */
			for impComponenteRec in
			 (
				select tb.elem_det_comp_tipo_id as compId, 
				 g.elem_det_comp_tipo_desc as compDesc, 
				 tb.importo as importoCurAttuale,
				 h.elem_det_comp_macro_tipo_desc as compMacroTipoDesc,
				 tb.movgest_anno as annualita
				from (
				  select
					  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id, a.elem_det_comp_tipo_id, b.movgest_anno
				  from
					  siac_r_movgest_bil_elem a,
					  siac_t_movgest b,
					  siac_t_movgest_ts c,
					  siac_r_movgest_ts_stato d,
					  siac_t_movgest_ts_det e,
					  siac_d_movgest_ts_det_tipo f
				  where
					  b.movgest_id=a.movgest_id 
					  and a.elem_id=elemIdGestEq 
					  and NOT( a.elem_det_comp_tipo_id = ANY(idcomp_in)) --SIAC-7349 --id componente diversa da quella ricevuta in input
					  and b.bil_id = bilIdElemGestEq
					  and b.movgest_tipo_id=movGestTipoId
					  and d.movgest_stato_id<>movGestStatoIdAnnullato
					  -- SIAC-7737 GS 31/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
				      -- and d.movgest_stato_id<>movGestStatoIdProvvisorio
					  and b.movgest_anno IN (annoMovimento::integer,  annoMovimento::integer+1, annoMovimento::integer+2)
					  and c.movgest_id=b.movgest_id
					  and d.movgest_ts_id=c.movgest_ts_id
					  and d.validita_fine is null
					  and e.movgest_ts_id=c.movgest_ts_id
					  and a.data_cancellazione is null
					  and b.data_cancellazione is null
					  and c.data_cancellazione is null
					  and e.data_cancellazione is null
					  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
					  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId
					  group by 	c.movgest_ts_tipo_id, 
								a.elem_det_comp_tipo_id, -- SIAC-7349
								b.movgest_anno
					) tb, 
					siac_d_movgest_ts_tipo t,
					siac_d_bil_elem_det_comp_tipo g,
				 	siac_d_bil_elem_det_comp_macro_tipo h
				where 
					tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
					and g.elem_det_comp_tipo_id = tb.elem_det_comp_tipo_id --SIAC-7349 recupera anche la descrizione della componente
					and g.elem_det_comp_macro_tipo_id = h.elem_det_comp_macro_tipo_id --SIAC-7349 recupera anche la descrizione del macrotipo della componente
				 order by t.movgest_ts_tipo_code desc
 			) 
			loop
			

					-- 02.02.2016 Sofia JIRA 2947
					 if impComponenteRec.importoCurAttuale is null then impComponenteRec.importoCurAttuale:=0; end if;

					 -- 16.03.2017 Sofia JIRA-SIAC-4614
					-- if importoCurAttuale>0 then
					 if impComponenteRec.importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

						strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'  impComponenteRec.compId='||impComponenteRec.compId||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Calcolo totale modifiche su atti provvisori per annoMovimento='||annoMovimento||'.';

						select tb.importo into importoModifDelta
						 from
						 (
							select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
							from siac_r_movgest_bil_elem rbil, 
								 siac_t_movgest mov,
								 siac_t_movgest_ts ts,
								 siac_r_movgest_ts_stato rstato,
								 siac_t_movgest_ts_det tsdet,
								 siac_t_movgest_ts_det_mod moddet,
								 siac_t_modifica mod, 
								 siac_r_modifica_stato rmodstato,
								 siac_r_atto_amm_stato attostato, 
								 siac_t_atto_amm atto,
								 siac_d_modifica_tipo tipom
							where 
								rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
								and rbil.elem_det_comp_tipo_id=impComponenteRec.compId --SIAC-7349 deve essere sulla compoenente del record 
								and	  mov.movgest_id=rbil.movgest_id
								and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
								and   mov.movgest_anno>annoMovimento::integer -- anno dell impegno = annoMovimento 
								and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
								and   ts.movgest_id=mov.movgest_id
								and   rstato.movgest_ts_id=ts.movgest_ts_id
								and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
								-- SIAC-7737 GS 31/08/2020, necessario calcolare anche gli impegni provvisori: commentata quindi la riga seguente
							    -- and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
								and   tsdet.movgest_ts_id=ts.movgest_ts_id
								and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
								and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
								-- SIAC-7349 Prendo tutti gli importi, sia con segno negativo che con segno positivo
								-- La loro somma produce il valore importoModifDelta che devo sottrarre all'impegnato calcolato
								-- ad esempio: modifiche su atto provv +100, -322 -> somma -222 si tratta di un delta che devo sottrarre
								-- all'impegnato calcolato = impegnato calcolato - (-222) = +222 (aggiungo quello che avevo tolto)
								-- and   moddet.movgest_ts_det_importo<0 -- importo negativo
								and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
								and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
								and   mod.mod_id=rmodstato.mod_id
								and   atto.attoamm_id=mod.attoamm_id
								and   attostato.attoamm_id=atto.attoamm_id
								and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
								and   tipom.mod_tipo_id=mod.mod_tipo_id
								and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
								-- date
								and rbil.data_cancellazione is null
								and rbil.validita_fine is null
								and mov.data_cancellazione is null
								and mov.validita_fine is null
								and ts.data_cancellazione is null
								and ts.validita_fine is null
								and rstato.data_cancellazione is null
								and rstato.validita_fine is null
								and tsdet.data_cancellazione is null
								and tsdet.validita_fine is null
								and moddet.data_cancellazione is null
								and moddet.validita_fine is null
								and mod.data_cancellazione is null
								and mod.validita_fine is null
								and rmodstato.data_cancellazione is null
								and rmodstato.validita_fine is null
								and attostato.data_cancellazione is null
								and attostato.validita_fine is null
								and atto.data_cancellazione is null
								and atto.validita_fine is null
								group by ts.movgest_ts_tipo_id
							  ) tb, siac_d_movgest_ts_tipo tipo
							  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
							  order by tipo.movgest_ts_tipo_code desc
							  limit 1;		

						if importoModifDelta is null then importoModifDelta:=0; end if;
						  /*Aggiunta delle modifiche ECONB*/
						 -- anna_economie inizio
						select tb.importo into importoModifINS
						from
						(
							select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
							from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
							siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
							siac_t_movgest_ts_det_mod moddet,
							siac_t_modifica mod, siac_r_modifica_stato rmodstato,
							siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
							siac_d_modifica_tipo tipom
						where rbil.elem_id=elemIdGestEq
						and rbil.elem_det_comp_tipo_id=impComponenteRec.compId --SIAC-7349
						and	  mov.movgest_id=rbil.movgest_id
						and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
						and   mov.movgest_anno=annoMovimento::integer
						and   mov.bil_id=bilancioId
						and   ts.movgest_id=mov.movgest_id
						and   rstato.movgest_ts_id=ts.movgest_ts_id
						and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- impegno non annullato
						and   tsdet.movgest_ts_id=ts.movgest_ts_id
						and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
						and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
					   and   tipom.mod_tipo_id=mod.mod_tipo_id
					   and   tipom.mod_tipo_code = 'ECONB'
						-- date
						and rbil.data_cancellazione is null
						and rbil.validita_fine is null
						and mov.data_cancellazione is null
						and mov.validita_fine is null
						and ts.data_cancellazione is null
						and ts.validita_fine is null
						and rstato.data_cancellazione is null
						and rstato.validita_fine is null
						and tsdet.data_cancellazione is null
						and tsdet.validita_fine is null
						and moddet.data_cancellazione is null
						and moddet.validita_fine is null
						and mod.data_cancellazione is null
						and mod.validita_fine is null
						and rmodstato.data_cancellazione is null
						and rmodstato.validita_fine is null
						and attostato.data_cancellazione is null
						and attostato.validita_fine is null
						and atto.data_cancellazione is null
						and atto.validita_fine is null
					   group by ts.movgest_ts_tipo_id
					 ) tb, siac_d_movgest_ts_tipo tipo
					 where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
					 order by tipo.movgest_ts_tipo_code desc
					 limit 1;

					 if importoModifINS is null then 
						importoModifINS = 0;
					 end if;

					end if;		
	
			--Fix MR adeguamento sprint 5
			-- Mon restituiamo piu' al valore impegnato le modifiche provvisorie e le ECONB
           		importoModifDelta:=0;
            		importoModifINS:=0;
            --
			
			annoimpegnato:=impComponenteRec.annualita;
			elemDetCompId:=impComponenteRec.compId;
			elemdetcompdesc:=impComponenteRec.compDesc;
			elemdetcompmacrotipodesc:=impComponenteRec.compMacroTipoDesc;
			impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente  
			impegnatoDefinitivo:=impegnatoDefinitivo+impComponenteRec.importoCurAttuale-(importoModifDelta);
			--aggiunta per ECONB
			impegnatoDefinitivo:=impegnatoDefinitivo+abs(importoModifINS);
			return next;	

	end loop;
	end if;
	end if;

	return;
 

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
		return;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
		return;
END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_impegnatodefinitivoug_comp_triennio_nostanz(integer, integer[])
    OWNER TO siac;



-- end fnc_siac_impegnatodefinitivoug_comp_triennio_nostanz

  
  
