/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 04.11.2022 eseguito in prod 
-- DLL svecchiamento 
alter table siac_t_bck_file_pagopa  add	CONSTRAINT siac_d_file_pagopa_stato_siac_t_bck_file_pagopa FOREIGN KEY (file_pagopa_stato_id) REFERENCES siac.siac_d_file_pagopa_stato(file_pagopa_stato_id);
alter table siac_t_bck_file_pagopa  add	CONSTRAINT siac_t_ente_proprietario_siac_t_bck_file_pagopa FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id);

CREATE INDEX siac_t_bck_file_pagopa_fk_ente_proprietario_id_idx  ON siac.siac_t_bck_file_pagopa USING btree (ente_proprietario_id);
CREATE INDEX siac_t_bck_file_pagopa_fk_file_pagopa_stato_id_idx ON siac.siac_t_bck_file_pagopa USING btree (file_pagopa_stato_id);
CREATE INDEX siac_t_bck_file_pagopa_svecchia_id_idx                       ON siac.siac_t_bck_file_pagopa USING btree (pagopa_elab_svecchia_id);
CREATE INDEX siac_t_bck_file_pagopa_file_id_idx                                ON siac.siac_t_bck_file_pagopa USING btree (file_pagopa_id);


CREATE INDEX pagopa_t_bck_elaborazione_svecchia_id_idx ON siac.pagopa_t_bck_elaborazione USING btree (pagopa_elab_svecchia_id);
CREATE INDEX pagopa_t_bck_elaborazione_flusso_svecchia_id_idx ON siac.pagopa_t_bck_elaborazione_flusso USING btree (pagopa_elab_svecchia_id);
CREATE INDEX pagopa_t_bck_riconc_doc_svecchia_id_idx ON siac.pagopa_t_bck_riconciliazione_doc USING btree (pagopa_elab_svecchia_id);
CREATE INDEX pagopa_r_bck_elab_file_svecchia_id_idx ON siac.pagopa_r_bck_elaborazione_file USING btree (pagopa_elab_svecchia_id);
CREATE INDEX pagopa_t_bck_riconciliazione_svecchia_id_idx ON siac.pagopa_t_bck_riconciliazione USING btree (pagopa_elab_svecchia_id);
CREATE INDEX pagopa_t_bck_riconc_det_svecchia_id_idx ON siac.pagopa_t_bck_riconciliazione_det USING btree (pagopa_elab_svecchia_id);
CREATE INDEX pagopa_t_bck_elab_log_svecchia_id_idx ON siac.pagopa_t_bck_elaborazione_log USING btree (pagopa_elab_svecchia_id);
CREATE INDEX pagopa_t_bck_elab_log_file_id_idx ON siac.pagopa_t_bck_elaborazione_log USING btree (pagopa_elab_file_id);
CREATE INDEX pagopa_t_bck_t_doc_ente_id_idx ON siac.pagopa_bck_t_doc USING btree (ente_proprietario_id);
CREATE INDEX pagopa_t_bck_t_doc_attr_ente_id_idx ON siac.pagopa_bck_t_doc_attr USING btree (ente_proprietario_id);
CREATE INDEX pagopa_t_bck_t_doc_class_ente_id_idx ON siac.pagopa_bck_t_doc_class USING btree (ente_proprietario_id);
CREATE INDEX pagopa_t_bck_t_doc_sog_ente_id_idx ON siac.pagopa_bck_t_doc_sog USING btree (ente_proprietario_id);
CREATE INDEX pagopa_t_bck_t_doc_stato_ente_id_idx ON siac.pagopa_bck_t_doc_stato USING btree (ente_proprietario_id);
CREATE INDEX pagopa_t_bck_t_reg_unico_ente_id_idx ON siac.pagopa_bck_t_registrounico_doc USING btree (ente_proprietario_id);
CREATE INDEX pagopa_t_bck_t_subdoc_ente_id_idx ON siac.pagopa_bck_t_subdoc USING btree (ente_proprietario_id);
CREATE INDEX pagopa_t_bck_t_subdoc_am_ente_id_idx ON siac.pagopa_bck_t_subdoc_atto_amm USING btree (ente_proprietario_id);
CREATE INDEX pagopa_t_bck_t_subdoc_attr_ente_id_idx ON siac.pagopa_bck_t_subdoc_attr USING btree (ente_proprietario_id);
CREATE INDEX pagopa_t_bck_t_subdoc_mov_ente_id_idx ON siac.pagopa_bck_t_subdoc_movgest_ts USING btree (ente_proprietario_id);
CREATE INDEX pagopa_t_bck_t_subdoc_num_ente_id_idx ON siac.pagopa_bck_t_subdoc_num USING btree (ente_proprietario_id);
CREATE INDEX pagopa_t_bck_t_subdoc_pcassa_ente_id_idx ON siac.pagopa_bck_t_subdoc_prov_cassa USING btree (ente_proprietario_id);
CREATE INDEX pagopa_t_bck_elaborazione_ente_id_idx ON siac.pagopa_t_bck_elaborazione USING btree (ente_proprietario_id);
CREATE INDEX pagopa_t_bck_elaborazione_file_id_idx ON siac.pagopa_t_bck_elaborazione USING btree (file_pagopa_id);
CREATE INDEX pagopa_t_bck_elabo_flusso_ente_id_idx ON siac.pagopa_t_bck_elaborazione_flusso USING btree (ente_proprietario_id);
CREATE INDEX pagopa_t_bck_elab_flusso_elab_fl_id_idx ON siac.pagopa_t_bck_elaborazione_flusso USING btree (pagopa_elab_flusso_id);
CREATE INDEX pagopa_t_bck_elab_flusso_elab_id_idx ON siac.pagopa_t_bck_elaborazione_flusso USING btree (pagopa_elab_id);
CREATE INDEX pagopa_t_bck_elab_log_ente_id_idx ON siac.pagopa_t_bck_elaborazione_log USING btree (ente_proprietario_id);

CREATE INDEX pagopa_t_bck_riconc_ente_id_idx ON siac.pagopa_t_bck_riconciliazione USING btree (ente_proprietario_id);
CREATE INDEX pagopa_t_bck_riconc_ric_id_idx ON siac.pagopa_t_bck_riconciliazione USING btree (pagopa_ric_id);
CREATE INDEX pagopa_t_bck_riconc_det_ric_id_idx ON siac.pagopa_t_bck_riconciliazione_det USING btree (pagopa_ric_id);
CREATE INDEX pagopa_t_bck_riconc_det_ente_id_idx ON siac.pagopa_t_bck_riconciliazione_det USING btree (ente_proprietario_id);

CREATE INDEX pagopa_t_bck_riconc_doc_ric_id_idx ON siac.pagopa_t_bck_riconciliazione_doc USING btree (pagopa_ric_id);
CREATE INDEX pagopa_t_bck_riconc_doc_ente_id_idx ON siac.pagopa_t_bck_riconciliazione_doc USING btree (ente_proprietario_id);




create index pagopa_t_elab_log_ente_id_idx on siac.pagopa_t_elaborazione_log USING btree (ente_proprietario_id);
create index pagopa_t_elab_log_elab_file_id_idx on siac.pagopa_t_elaborazione_log USING btree (pagopa_elab_file_id);
create index pagopa_t_elab_log_elab_id_idx on siac.pagopa_t_elaborazione_log USING btree (pagopa_elab_id);

create index pagopa_t_riconc_det_ente_id_idx on siac.pagopa_t_riconciliazione_det USING btree (ente_proprietario_id);
create index pagopa_t_riconc_det_ric_id_idx on siac.pagopa_t_riconciliazione_det USING btree (pagopa_ric_id);


