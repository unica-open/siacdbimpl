/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop table siac.siac_s_prov_cassa;
CREATE TABLE siac.siac_s_prov_cassa 
(
	provc_st_id serial ,
	provc_id integer NOT NULL,
	sac_id integer null,
	sac_code varchar(200) null,
	sac_desc varchar(500) null,
	sac_tipo_code varchar(200) null,
	sac_tipo_desc varchar(500) null,
	provc_data_invio_servizio timestamp null,
    validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	ente_proprietario_id int4 NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT null,
	CONSTRAINT pk_siac_s_prov_cassa PRIMARY KEY (provc_st_id),
	CONSTRAINT siac_t_prov_cassa_siac_s_prov_cassa FOREIGN KEY (provc_id) REFERENCES siac.siac_t_prov_cassa(provc_id),
    CONSTRAINT siac_t_class_siac_s_prov_cassa FOREIGN KEY (sac_id) REFERENCES siac.siac_t_class(classif_id),
	CONSTRAINT siac_t_ente_proprietario_siac_s_prov_cassa FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);
CREATE INDEX siac_s_prov_cassa_fk_provc_id_idx ON siac_s_prov_cassa USING btree (provc_id);
CREATE INDEX siac_s_prov_cassa_fk_ente_proprietario_id_idx ON siac_s_prov_cassa USING btree (ente_proprietario_id);
CREATE INDEX siac_s_prov_cassa_fk_sac_id_idx ON siac_s_prov_cassa USING btree (sac_id);
CREATE INDEX siac_s_prov_cassa_fk_sac_code_idx ON siac_s_prov_cassa USING btree (sac_code,sac_tipo_code);

alter table siac.siac_s_prov_cassa OWNER to siac;



drop VIEW if exists siac.siac_v_dwh_storico_prov_cassa;
CREATE OR REPLACE VIEW siac.siac_v_dwh_storico_prov_cassa
(
    ente_proprietario_id,
    ente_denominazione,
    provc_tipo_code,
    provc_tipo_desc,
    provc_anno,
    provc_numero,
    sac_code,
	sac_desc,
	sac_tipo_code,
	sac_tipo_desc,
	provc_data_invio_servizio,
	validita_inizio_storico,
	validita_fine_storico
)
as
select ente.ente_proprietario_id,
       ente.ente_denominazione, 
       tipo.provc_tipo_code,
       tipo.provc_tipo_desc,
       p.provc_anno,
       p.provc_numero,
       s.sac_code,
       s.sac_desc,
       s.sac_tipo_code,
       s.sac_tipo_desc,
       s.provc_data_invio_servizio,
       s.validita_inizio,
       s.validita_fine
from siac_s_prov_cassa  s ,siac_t_prov_cassa p,siac_d_prov_cassa_tipo tipo,
     siac_t_ente_proprietario ente
where  tipo.ente_proprietario_id=ente.ente_proprietario_id 
and    p.provc_tipo_id=tipo.provc_tipo_id
and    s.provc_id=p.provc_id
and    p.data_cancellazione is null
and    s.data_cancellazione is null;


alter view siac.siac_v_dwh_storico_prov_cassa OWNER to siac;

