/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 05.12.2017 Sofia SIAC-5630


ALTER TABLE fase_bil_t_gest_apertura_vincoli
  ALTER COLUMN movgest_orig_ts_a_id DROP NOT NULL,
  ALTER COLUMN movgest_orig_ts_b_id DROP NOT NULL;

-- ALTER TABLE fase_bil_t_gest_apertura_vincoli ADD COLUMN avav_id integer;'
-- alter table fase_bil_t_gest_apertura_vincoli
--add CONSTRAINT  siac_r_movgest_ts_siac_t_avanzovincolo FOREIGN KEY (avav_id)
--REFERENCES siac_t_avanzovincolo(avav_id)
--  ON DELETE NO ACTION
--  ON UPDATE NO ACTION
--  NOT DEFERRABLE;
CREATE OR REPLACE FUNCTION fnc_siac_add_column()
returns void
AS 
$body$
declare
 stm varchar;
begin
 
 select  'ALTER TABLE fase_bil_t_gest_apertura_vincoli ADD COLUMN avav_id integer;' into stm
 where 
 not exists 
 (
 SELECT 1 
 FROM information_schema.columns
 WHERE table_name = 'fase_bil_t_gest_apertura_vincoli'
 AND column_name = 'avav_id'
 );
 if stm is not null then
 	execute stm;
 end if;
 
 stm:=null;
 select 'alter table fase_bil_t_gest_apertura_vincoli
add CONSTRAINT  siac_r_movgest_ts_siac_t_avanzovincolo FOREIGN KEY (avav_id)
    REFERENCES siac_t_avanzovincolo(avav_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE;' into stm
 where 
 not exists
 (select 1 
  from pg_constraint
  where conname='siac_r_movgest_ts_siac_t_avanzovincolo'
 );
 if stm is not null then
 	execute stm;
 end if;
end;
$body$ LANGUAGE 'plpgsql' volatile called ON NULL input security invoker cost 100;

select * from fnc_siac_add_column();
 


