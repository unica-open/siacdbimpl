-- siac-task-251 Sofia - 19.10.2023

DROP INDEX IF EXISTS idx_siac_t_avanzovincolo_anno;
CREATE UNIQUE index if not exists idx_siac_t_avanzovincolo_anno ON siac.siac_t_avanzovincolo 
USING btree (avav_tipo_id,extract(year from  validita_inizio));