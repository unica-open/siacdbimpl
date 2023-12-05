/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
insert into siac_d_class_tipo (
			classif_tipo_code, 
            classif_tipo_desc,
            validita_inizio,
			ente_proprietario_id, 
            login_operazione)
SELECT tmp.code, tmp.descr, to_timestamp('2020-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'         
FROM siac_t_ente_proprietario tep
CROSS JOIN(VALUES ('RISACC','RISORSA ACCANTONATA')) as tmp(code, descr)
WHERE not exists (
 SELECT 1 FROM siac_d_class_tipo et
 WHERE et.classif_tipo_code=tmp.code
 and et.ente_proprietario_id=tep.ente_proprietario_id
 and et.data_cancellazione is null);
 
 insert into siac_r_bil_elem_tipo_class_tip (
			elem_tipo_id, 
            classif_tipo_id, 
            validita_inizio, 
            ente_proprietario_id, 
            login_operazione)
SELECT dbedt.elem_tipo_id, dct.classif_tipo_id, to_timestamp('2020-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
join siac_d_bil_elem_tipo dbedt on dbedt.ente_proprietario_id = tep.ente_proprietario_id
join siac_d_class_tipo dct on dct.ente_proprietario_id = tep.ente_proprietario_id
where dbedt.elem_tipo_code in ('CAP-UP', 'CAP-UG')
and dct.classif_tipo_code = 'RISACC'
and not exists (
	select 1 from siac_r_bil_elem_tipo_class_tip cc 
	where cc.ente_proprietario_id  = tep.ente_proprietario_id 
	and cc.elem_tipo_id  = dbedt.elem_tipo_id
	and cc.classif_tipo_id  = dct.classif_tipo_id
	and cc.data_cancellazione  is null
);
 
insert into siac_t_class (
			classif_code, 
            classif_desc,
            classif_tipo_id, 
            validita_inizio, 
            ente_proprietario_id, 
            login_operazione)
SELECT tmp.code, tmp.descr, dgt.classif_tipo_id, to_timestamp('2016-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'         
FROM siac_t_ente_proprietario tep
JOIN siac_d_class_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id           
CROSS JOIN(VALUES 
	('1','Fondo anticipazioni liquidità'), 
	('2','Fondo perdite società partecipate'), 
	('3','Fondo contezioso'), 
	('4','Fondo crediti di dubbia esigibilità'), 
	('5','Accantonamento residui perenti (solo per le regioni)'), 
	('6','Altri accantonamenti ')
	) as tmp(code, descr)
WHERE dgt.classif_tipo_code = 'RISACC'
and not exists (
 SELECT 1 FROM siac_t_class et
 WHERE et.classif_code=tmp.code
 and et.ente_proprietario_id=tep.ente_proprietario_id
 and et.classif_tipo_id=dgt.classif_tipo_id
 and et.data_cancellazione is null); 
 
CREATE TABLE IF NOT EXISTS siac.siac_d_vincolo_risorse_vincolate (
    vincolo_risorse_vincolate_id   SERIAL NOT null PRIMARY KEY,
    vincolo_risorse_vincolate_code CHARACTER VARYING(200) NOT NULL,
    vincolo_risorse_vincolate_desc CHARACTER VARYING(500) NOT NULL,
    validita_inizio        TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    validita_fine          TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id   INTEGER NOT NULL,
    data_creazione         TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica          TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione     TIMESTAMP WITHOUT TIME ZONE,
    login_operazione       CHARACTER VARYING(200) NOT NULL 
);

SELECT * FROM fnc_dba_create_index('siac_d_vincolo_risorse_vincolate', 'idx_siac_d_vincolo_risorse_vincolate','vincolo_risorse_vincolate_code,validita_inizio, ente_proprietario_id', 'data_cancellazione is null', false);

SELECT * FROM fnc_dba_add_column('siac_t_vincolo', 'vincolo_risorse_vincolate_id', 'integer');
SELECT * FROM fnc_dba_add_fk_constraint('siac_t_vincolo', 'siac_t_vincolo_siac_d_vincolo_risorse_vincolate', 'vincolo_risorse_vincolate_id', 'siac_d_vincolo' 'integer');


insert into siac_d_vincolo_risorse_vincolate (
			vincolo_risorse_vincolate_code, 
            vincolo_risorse_vincolate_desc, 
            validita_inizio, 
            ente_proprietario_id, 
            login_operazione)
SELECT tmp.vincolo_risorse_vincolate_code, tmp.descr, to_timestamp('2016-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'         
FROM siac_t_ente_proprietario tep           
CROSS JOIN(VALUES 
	('1','Vincoli derivanti dalla legge'), 
	('2','Vincoli derivanti da Trasferimenti'), 
	('3','Vincoli derivanti da finanziamenti'), 
	('4','Vincoli formalmente attribuiti dall''ente'), 
	('5','Altri vincoli'), 
	('6','Quote destinate agli Investimenti'),
	('7','In via di definizione')
	) as tmp(vincolo_risorse_vincolate_code, descr)
WHERE not exists (
    SELECT 1 FROM siac_d_vincolo_risorse_vincolate et
    WHERE et.vincolo_risorse_vincolate_code = tmp.vincolo_risorse_vincolate_code
    and et.ente_proprietario_id = tep.ente_proprietario_id
    and et.data_cancellazione is null
);

CREATE TABLE IF NOT EXISTS siac.siac_r_vincolo_risorse_vincolate (
    vincolo_risorse_vincolate_r_id   SERIAL NOT NULL PRIMARY KEY,
    vincolo_risorse_vincolate_id INTEGER NOT NULL,
    vincolo_id INTEGER NOT NULL,
    validita_inizio        TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    validita_fine          TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id   INTEGER NOT NULL,
    data_creazione         TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica          TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione     TIMESTAMP WITHOUT TIME ZONE,
    login_operazione       CHARACTER VARYING(200) NOT NULL 
);


SELECT * FROM fnc_dba_add_fk_constraint('siac_t_vincolo'::text, 'siac_t_vincolo_siac_r_vincolo_risorse_vincolate'::text, 'vincolo_id'::text, 'siac_r_vincolo_risorse_vincolate'::text, 'vincolo_id'::text);
SELECT * FROM fnc_dba_add_fk_constraint('siac_r_vincolo_risorse_vincolate'::text, 'siac_r_vincolo_risorse_vincolate_siac_t_vincolo'::text, 'vincolo_id'::text, 'siac_t_vincolo'::text, 'vincolo_id'::text);