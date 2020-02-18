/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_siac_riaccertamento (
  mod_id_in integer,
  login_operazione_in varchar,
  tipo_operazione_in varchar
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE
importo_mod_da_scalare numeric;
ente_proprietario_id_in integer;
rec record;
recannullamento record;

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
h.movgest_tipo_code='I' and --movgest_ts_b_id Ã¨ impegno
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
i.movgest_ts_b_id=f.movgest_ts_id and --movgest_ts_b_id Ã¨ impegno
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
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;