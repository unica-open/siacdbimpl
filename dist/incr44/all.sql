/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- siac-6200 Sofia - Inizio

CREATE OR REPLACE FUNCTION fnc_bilr_stampa_mastrino
 (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_reg_da date,
  p_data_reg_a date,
  p_pdce_v_livello varchar,
  p_ambito   varchar
 )
 RETURNS TABLE (
  nome_ente varchar,
  id_pdce0 integer,
  codice_pdce0 varchar,
  descr_pdce0 varchar,
  id_pdce1 integer,
  codice_pdce1 varchar,
  descr_pdce1 varchar,
  id_pdce2 integer,
  codice_pdce2 varchar,
  descr_pdce2 varchar,
  id_pdce3 integer,
  codice_pdce3 varchar,
  descr_pdce3 varchar,
  id_pdce4 integer,
  codice_pdce4 varchar,
  descr_pdce4 varchar,
  id_pdce5 integer,
  codice_pdce5 varchar,
  descr_pdce5 varchar,
  id_pdce6 integer,
  codice_pdce6 varchar,
  descr_pdce6 varchar,
  id_pdce7 integer,
  codice_pdce7 varchar,
  descr_pdce7 varchar,
  id_pdce8 integer,
  codice_pdce8 varchar,
  descr_pdce8 varchar,
  data_registrazione date,
  num_prima_nota integer,
  tipo_pnota varchar,
  prov_pnota varchar,
  cod_soggetto varchar,
  descr_soggetto varchar,
  tipo_documento varchar,
  data_registrazione_mov date,
  numero_documento varchar,
  num_det_rif varchar,
  data_det_rif date,
  importo_dare numeric,
  importo_avere numeric,
  livello integer,
  tipo_movimento varchar,
  saldo_prec_dare numeric,
  saldo_prec_avere numeric,
  saldo_ini_dare numeric,
  saldo_ini_avere numeric,
  code_pdce_livello varchar,
  display_error varchar
) AS
$body$
DECLARE
elenco_prime_note record;
elencoPdce record;
dati_movimento record;
dati_eventi record;
--dati_pdce record;
pdce_conto_id_in integer;


-- 07.06.2018 Sofia SIAC-6200
pdce_conto_ambito_id integer;
pdce_conto_ambito_code varchar;
pdce_conto_esiste_pnota integer:=null;

DEF_NULL	constant varchar:='';
RTN_MESSAGGIO 		varchar(1000):=DEF_NULL;
user_table			varchar;
nome_ente_in varchar;
bil_id_in integer;




BEGIN

    p_data_reg_a:=date_trunc('day', to_timestamp(to_char(p_data_reg_a,'dd/mm/yyyy'),'dd/mm/yyyy')) + interval '1 day';

	raise notice 'p_data_reg_da=%',p_data_reg_da;
	raise notice 'p_data_reg_a=%',p_data_reg_a;

	select ente_denominazione,b.bil_id into nome_ente_in,bil_id_in
	from siac_t_ente_proprietario a,siac_t_bil b,siac_t_periodo c
    where a.ente_proprietario_id=p_ente_prop_id
    and  a.ente_proprietario_id=b.ente_proprietario_id and b.periodo_id=c.periodo_id
	and c.anno=p_anno;

    select fnc_siac_random_user()
	into	user_table;

    raise notice '1 - % ',clock_timestamp()::varchar;

	-- 07.06.2018 Sofia siac-6200
	select a.pdce_conto_id , ambito.ambito_id, ambito.ambito_code
    into   pdce_conto_id_in, pdce_conto_ambito_id, pdce_conto_ambito_code
    from siac_t_pdce_conto a,siac_d_ambito ambito
    where a.ente_proprietario_id=p_ente_prop_id
  	and   a.pdce_conto_code=p_pdce_v_livello
    and   ambito.ambito_id=a.ambito_id
    and   p_anno::integer BETWEEN date_part('year',a.validita_inizio)::integer
    and   coalesce (date_part('year',a.validita_fine)::integer ,p_anno::integer  );

    IF NOT FOUND THEN
    	display_error='Il codice PDCE indicato ('||p_pdce_v_livello||') e'' inesistente';
        return next;
    	return;
    END IF;

    if coalesce(p_ambito,'')!='' and -- 08.06.2018 Sofia siac-6200
       pdce_conto_ambito_code!=p_ambito then
  		display_error='Il codice PDCE indicato ('||p_pdce_v_livello||') non appartiene all''ambito '||p_ambito||' richiesto.';
        return next;
    	return;
    end if;

    -- 08.06.2018 Sofia siac-6200
    select 1 into pdce_conto_esiste_pnota
    from siac_t_prima_nota pn,siac_r_prima_nota_stato rs,siac_d_prima_nota_stato stato,
         siac_t_mov_ep ep, siac_t_mov_ep_det det
    where det.pdce_conto_id=pdce_conto_id_in
    and   ep.movep_id=det.movep_id
    and   pn.pnota_id=ep.regep_id
    and   pn.bil_id=bil_id_in
    and   rs.pnota_id=pn.pnota_id
    and   stato.pnota_stato_id=rs.pnota_stato_id
    and   stato.pnota_stato_code='D'
    and   pn.pnota_dataregistrazionegiornale between p_data_reg_da
    and   p_data_reg_a
    and   ( case when coalesce(p_ambito,'')!='' then pn.ambito_id=pdce_conto_ambito_id
                 else pn.ambito_id=pn.ambito_id  end )
    and   pn.data_cancellazione is null
    and   pn.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   ep.data_cancellazione is null
    and   ep.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null
    limit 1;

    -- 08.06.2018 Sofia siac-6200
    if pdce_conto_esiste_pnota is null then
    	display_error='Per il codice PDCE indicato ('||p_pdce_v_livello||') non esistono prime note nel periodo richiesto.';
        return next;
    	return;
    end if;

--raise notice 'PDCE livello = %, conto = %, ID = %',  dati_pdce.livello, dati_pdce.pdce_conto_code, dati_pdce.pdce_conto_id;
raise notice 'pdce_conto_id_in=%',pdce_conto_id_in;
--     carico l'intera struttura PDCE
RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL PDCE ''.';
raise notice 'inserimento tabella di comodo STRUTTURA DEL PDCE';

raise notice '2 - % ',clock_timestamp()::varchar;
INSERT INTO
  siac.siac_rep_struttura_pdce
(
  pdce_liv0_id,
  pdce_liv0_id_padre,
  pdce_liv0_code,
  pdce_liv0_desc,
  pdce_liv1_id,
  pdce_liv1_id_padre,
  pdce_liv1_code,
  pdce_liv1_desc,
  pdce_liv2_id,
  pdce_liv2_id_padre,
  pdce_liv2_code,
  pdce_liv2_desc,
  pdce_liv3_id,
  pdce_liv3_id_padre,
  pdce_liv3_code,
  pdce_liv3_desc,
  pdce_liv4_id,
  pdce_liv4_id_padre,
  pdce_liv4_code,
  pdce_liv4_desc,
  pdce_liv5_id,
  pdce_liv5_id_padre,
  pdce_liv5_code,
  pdce_liv5_desc,
  pdce_liv6_id,
  pdce_liv6_id_padre,
  pdce_liv6_code,
  pdce_liv6_desc,
  pdce_liv7_id,
  pdce_liv7_id_padre,
  pdce_liv7_code,
  pdce_liv7_desc,
  utente
)
select zzz.*, user_table from(
with t_pdce_conto0 as (
WITH RECURSIVE my_tree AS
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree where pdce_conto_id=pdce_conto_id_in
),
t_pdce_conto1 as (
WITH RECURSIVE my_tree AS
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree
),
t_pdce_conto2 as (
WITH RECURSIVE my_tree AS
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree
)
,
t_pdce_conto3 as (
WITH RECURSIVE my_tree AS
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree
)
,
t_pdce_conto4 as (
WITH RECURSIVE my_tree AS
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree
)
,
t_pdce_conto5 as (
WITH RECURSIVE my_tree AS
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree
)
,
t_pdce_conto6 as (
WITH RECURSIVE my_tree AS
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree
)
,
t_pdce_conto7 as (
WITH RECURSIVE my_tree AS
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree
)
select
t_pdce_conto7.pdce_conto_id pdce_liv0_id,
t_pdce_conto7.pdce_conto_id_padre pdce_liv0_id_padre,
t_pdce_conto7.pdce_conto_code pdce_liv0_code,
t_pdce_conto7.pdce_conto_desc pdce_liv0_desc,
t_pdce_conto6.pdce_conto_id pdce_liv1_id,
t_pdce_conto6.pdce_conto_id_padre pdce_liv1_id_padre,
t_pdce_conto6.pdce_conto_code pdce_liv1_code,
t_pdce_conto6.pdce_conto_desc pdce_liv1_desc,
t_pdce_conto5.pdce_conto_id pdce_liv2_id,
t_pdce_conto5.pdce_conto_id_padre pdce_liv2_id_padre,
t_pdce_conto5.pdce_conto_code pdce_liv2_code,
t_pdce_conto5.pdce_conto_desc pdce_liv2_desc,
t_pdce_conto4.pdce_conto_id pdce_liv3_id,
t_pdce_conto4.pdce_conto_id_padre pdce_liv3_id_padre,
t_pdce_conto4.pdce_conto_code pdce_liv3_code,
t_pdce_conto4.pdce_conto_desc pdce_liv3_desc,
t_pdce_conto3.pdce_conto_id pdce_liv4_id,
t_pdce_conto3.pdce_conto_id_padre pdce_liv4_id_padre,
t_pdce_conto3.pdce_conto_code pdce_liv4_code,
t_pdce_conto3.pdce_conto_desc pdce_liv4_desc,
t_pdce_conto2.pdce_conto_id pdce_liv5_id,
t_pdce_conto2.pdce_conto_id_padre pdce_liv5_id_padre,
t_pdce_conto2.pdce_conto_code pdce_liv5_code,
t_pdce_conto2.pdce_conto_desc pdce_liv5_desc,
t_pdce_conto1.pdce_conto_id pdce_liv6_id,
t_pdce_conto1.pdce_conto_id_padre pdce_liv6_id_padre,
t_pdce_conto1.pdce_conto_code pdce_liv6_code,
t_pdce_conto1.pdce_conto_desc pdce_liv6_desc,
t_pdce_conto0.pdce_conto_id pdce_liv7_id,
t_pdce_conto0.pdce_conto_id_padre pdce_liv7_id_padre,
t_pdce_conto0.pdce_conto_code pdce_liv7_code,
t_pdce_conto0.pdce_conto_desc pdce_liv7_desc
 from t_pdce_conto0 left join t_pdce_conto1
on t_pdce_conto0.livello-1=t_pdce_conto1.livello
left join t_pdce_conto2
on t_pdce_conto1.livello-1=t_pdce_conto2.livello
left join t_pdce_conto3
on t_pdce_conto2.livello-1=t_pdce_conto3.livello
left join t_pdce_conto4
on t_pdce_conto3.livello-1=t_pdce_conto4.livello
left join t_pdce_conto5
on t_pdce_conto4.livello-1=t_pdce_conto5.livello
left join t_pdce_conto6
on t_pdce_conto5.livello-1=t_pdce_conto6.livello
left join t_pdce_conto7
on t_pdce_conto6.livello-1=t_pdce_conto7.livello
) as zzz;

raise notice '3 - % ',clock_timestamp()::varchar;
RTN_MESSAGGIO:='Estrazione dei dati delle prime note''.';
raise notice 'Estrazione dei dati delle prime note';

return query
select outp.* from (
with ord as (--ORD
SELECT
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
'ORD'::varchar tipo_pnota,
c.evento_code::varchar prov_pnota,
s.soggetto_code::varchar cod_soggetto,
s.soggetto_desc::varchar       descr_soggetto,
'ORD'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
q.ord_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,
g.evento_tipo_code::varchar  tipo_movimento,
q.ord_emissione_data::date data_det_rif,
m.data_creazione::date  data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
m.ambito_id ambito_prima_nota_id,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_ordinativo q,
       siac_r_ordinativo_soggetto  r,
       siac_t_soggetto  s
WHERE d.collegamento_tipo_code in ('OI','OP') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and
        m.bil_id=bil_id_in
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and
        o.pnota_stato_code='D' and
        m.pnota_dataregistrazionegiornale between
        p_data_reg_da and
p_data_reg_a  and
        q.ord_id=b.campo_pk_id and
        r.ord_id=q.ord_id and
        s.soggetto_id=r.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL
     --   limit 1
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union
union all
select impacc.* from (
--A,I
with movgest as (
SELECT
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
case when d.collegamento_tipo_code = 'I' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 c.evento_code::varchar prov_pnota,
case when d.collegamento_tipo_code = 'I' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
q.movgest_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
m.data_creazione::date  data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
m.ambito_id ambito_prima_nota_id,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere
, q.movgest_id
 FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_movgest q
WHERE d.collegamento_tipo_code in ('I','A') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and
        m.bil_id=bil_id_in
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and
        o.pnota_stato_code='D' and
        m.pnota_dataregistrazionegiornale between
        p_data_reg_da and
p_data_reg_a
and q.movgest_id=b.campo_pk_id and
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL AND
g.data_cancellazione IS NULL AND
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
q.data_cancellazione IS NULL
),
sogcla as (
select distinct c.movgest_id,b.soggetto_classe_code,b.soggetto_classe_desc
From  siac_r_movgest_ts_sogclasse a,siac_d_soggetto_classe b,siac_t_movgest c,siac_t_movgest_ts d where a.ente_proprietario_id=p_ente_prop_id
and b.soggetto_classe_id=a.soggetto_classe_id
and c.movgest_id=d.movgest_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
),
sog as (
select c.movgest_id, b.soggetto_id,
b.soggetto_code,b.soggetto_desc from siac_r_movgest_ts_sog a,
siac_t_soggetto b,siac_t_movgest c,siac_t_movgest_ts d
where a.ente_proprietario_id=p_ente_prop_id and b.soggetto_id=a.soggetto_id
and c.movgest_id=d.movgest_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
)
select
movgest.pnota_dataregistrazionegiornale,
movgest.num_prima_nota,
movgest.tipo_pnota,
movgest.prov_pnota,
case when sog.soggetto_id is null then sogcla.soggetto_classe_code else sog.soggetto_code end  cod_soggetto,
case when sog.soggetto_id is null then sogcla.soggetto_classe_desc else sog.soggetto_desc end descr_soggetto,
movgest.tipo_documento,
movgest.data_registrazione_movimento,
movgest.numero_documento,
movgest.num_det_rif,
movgest.ente_proprietario_id,
movgest.pdce_conto_id,
movgest.tipo_movimento,
movgest.data_det_rif,
movgest.data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
movgest.ambito_prima_nota_id,
movgest.importo_dare,
movgest.importo_avere
 from movgest left join sogcla on
movgest.movgest_id=sogcla.movgest_id
left join sog on
movgest.movgest_id=sog.movgest_id
) as impacc
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union
union all
select impsubacc.* from (
--SA,SI
with movgest as (
SELECT
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
case when d.collegamento_tipo_code = 'SI' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 c.evento_code::varchar prov_pnota,
case when d.collegamento_tipo_code = 'SI' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.movgest_numero||'-'||q.movgest_ts_code::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
m.data_creazione::date  data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
m.ambito_id ambito_prima_nota_id,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere
, q.movgest_ts_id
 FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_movgest_ts q,siac_t_movgest r
WHERE d.collegamento_tipo_code in ('SI','SA') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and
        m.bil_id=bil_id_in
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and
        o.pnota_stato_code='D' and
        m.pnota_dataregistrazionegiornale between
        p_data_reg_da and
p_data_reg_a
and q.movgest_ts_id =b.campo_pk_id and
r.movgest_id=q.movgest_id and
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL AND
g.data_cancellazione IS NULL AND
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
q.data_cancellazione IS NULL and
r.data_cancellazione IS NULL
),
sogcla as (
select distinct d.movgest_ts_id ,b.soggetto_classe_code,b.soggetto_classe_desc
From  siac_r_movgest_ts_sogclasse a,siac_d_soggetto_classe b,siac_t_movgest_ts d where a.ente_proprietario_id=p_ente_prop_id
and b.soggetto_classe_id=a.soggetto_classe_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
),
sog as (
select d.movgest_ts_id, b.soggetto_id,
b.soggetto_code,b.soggetto_desc from siac_r_movgest_ts_sog a,
siac_t_soggetto b,siac_t_movgest_ts d
where a.ente_proprietario_id=p_ente_prop_id and b.soggetto_id=a.soggetto_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
)
select
movgest.pnota_dataregistrazionegiornale,
movgest.num_prima_nota,
movgest.tipo_pnota,
movgest.prov_pnota,
case when sog.soggetto_id is null then sogcla.soggetto_classe_code else sog.soggetto_code end  cod_soggetto,
case when sog.soggetto_id is null then sogcla.soggetto_classe_desc else sog.soggetto_desc end descr_soggetto,
movgest.tipo_documento,
movgest.data_registrazione_movimento,
movgest.numero_documento,
movgest.num_det_rif,
movgest.ente_proprietario_id,
movgest.pdce_conto_id,
movgest.tipo_movimento,
movgest.data_det_rif,
movgest.data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
movgest.ambito_prima_nota_id,
movgest.importo_dare,
movgest.importo_avere
 from movgest left join sogcla on
movgest.movgest_ts_id=sogcla.movgest_ts_id
left join sog on
movgest.movgest_ts_id=sog.movgest_ts_id
) as impsubacc
--'MMGE','MMGS'
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union
union all
select impsubaccmod.* from (
with movgest as (
with modge as (select tbz.* from (
with modprnoteint as (
select
g.campo_pk_id,
a.pnota_dataregistrazionegiornale,
a.pnota_progressivogiornale::integer num_prima_nota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 h.evento_code::varchar prov_pnota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_documento ,
e.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
a.ente_proprietario_id,
e.pdce_conto_id,
l.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
a.data_creazione::date  data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
a.ambito_id ambito_prima_nota_id,
case when  e.movep_det_segno='Dare' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,
case when  e.movep_det_segno='Avere' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere
from
siac_t_prima_nota a
,siac_r_prima_nota_stato b,
siac_d_prima_nota_stato c,
siac_t_mov_ep d,
siac_t_mov_ep_det e,
siac_t_reg_movfin f,
siac_r_evento_reg_movfin g,
siac_d_evento h,
siac_d_collegamento_tipo i,
siac_d_evento_tipo l
where a.ente_proprietario_id=p_ente_prop_id
and a.bil_id=bil_id_in
and b.pnota_id=a.pnota_id
and i.collegamento_tipo_code in ('MMGS','MMGE')
and c.pnota_stato_id=b.pnota_stato_id
and   a.pnota_dataregistrazionegiornale between  p_data_reg_da and
p_data_reg_a
and b.validita_fine is null
and d.regep_id=a.pnota_id
and e.movep_id=d.movep_id
and f.regmovfin_id=d.regmovfin_id
and g.regmovfin_id=f.regmovfin_id
and g.validita_fine is null
and h.evento_id=g.evento_id
and i.collegamento_tipo_id=h.collegamento_tipo_id
and l.evento_tipo_id=h.evento_tipo_id
and c.pnota_stato_code='D'
and  a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
and l.data_cancellazione is null
)
,
moddd as (
select m.mod_id,n.mod_stato_r_id
 from siac_t_modifica m,
siac_r_modifica_stato n,
siac_d_modifica_stato o
where m.ente_proprietario_id=p_ente_prop_id
and n.mod_id=m.mod_id
and n.validita_fine is null
and o.mod_stato_id=n.mod_stato_id
and m.data_cancellazione is null
and n.data_cancellazione is null
and o.data_cancellazione is null
)
select
moddd.mod_stato_r_id,
modprnoteint.pnota_dataregistrazionegiornale,
modprnoteint.num_prima_nota,
modprnoteint.tipo_pnota,
modprnoteint.prov_pnota,
modprnoteint.tipo_documento,
modprnoteint.data_registrazione_movimento,
modprnoteint.numero_documento,
modprnoteint.ente_proprietario_id,
modprnoteint.pdce_conto_id,
modprnoteint.tipo_movimento,
modprnoteint.data_det_rif,
modprnoteint.data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
modprnoteint.ambito_prima_nota_id,
modprnoteint.importo_dare,
modprnoteint.importo_avere
 from modprnoteint join moddd
on  moddd.mod_id=modprnoteint.campo_pk_id)
as tbz
) ,
modsog as (
select p.mod_stato_r_id,q.movgest_ts_id,r.movgest_numero||'-'||q.movgest_ts_code num_det_rif
 from
siac_r_movgest_ts_sog_mod p,siac_t_movgest_ts q,siac_t_movgest r
where
p.ente_proprietario_id=p_ente_prop_id and
 q.movgest_ts_id=p.movgest_ts_id
and r.movgest_id=q.movgest_id
and p.data_cancellazione is null
and q.data_cancellazione is null
and r.data_cancellazione is null)
,
modimp as (
select p.mod_stato_r_id,q.movgest_ts_id
,r.movgest_numero||'-'||q.movgest_ts_code num_det_rif
from
siac_t_movgest_ts_det_mod p,siac_t_movgest_ts q,siac_t_movgest r
where
p.ente_proprietario_id=p_ente_prop_id and
 q.movgest_ts_id=p.movgest_ts_id
and r.movgest_id=q.movgest_id
and p.data_cancellazione is null
and q.data_cancellazione is null
and r.data_cancellazione is null)
select
modge.pnota_dataregistrazionegiornale,
modge.num_prima_nota,
modge.tipo_pnota,
modge.prov_pnota,
modge.tipo_documento ,--uguale a tipo_pnota,
modge.data_registrazione_movimento,
modge.numero_documento,
case when modsog.movgest_ts_id is null then modimp.num_det_rif else modsog.num_det_rif end num_det_rif,
modge.ente_proprietario_id,
modge.pdce_conto_id,
modge.tipo_movimento,
modge.data_det_rif,
modge.data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
modge.ambito_prima_nota_id,
modge.importo_dare,
modge.importo_avere
, case when modsog.movgest_ts_id is null then modimp.movgest_ts_id else modsog.movgest_ts_id end movgest_ts_id
from modge left join
modsog on modge.mod_stato_r_id=modsog.mod_stato_r_id
left join
modimp on modge.mod_stato_r_id=modimp.mod_stato_r_id
),
sogcla as (
select distinct d.movgest_ts_id ,b.soggetto_classe_code,b.soggetto_classe_desc
From  siac_r_movgest_ts_sogclasse a,siac_d_soggetto_classe b,siac_t_movgest_ts d where a.ente_proprietario_id=p_ente_prop_id
and b.soggetto_classe_id=a.soggetto_classe_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
),
sog as (
select d.movgest_ts_id, b.soggetto_id,
b.soggetto_code,b.soggetto_desc from siac_r_movgest_ts_sog a,
siac_t_soggetto b,siac_t_movgest_ts d
where a.ente_proprietario_id=p_ente_prop_id and b.soggetto_id=a.soggetto_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
)
select
movgest.pnota_dataregistrazionegiornale,
movgest.num_prima_nota,
movgest.tipo_pnota,
movgest.prov_pnota,
case when sog.soggetto_id is null then sogcla.soggetto_classe_code else sog.soggetto_code end  cod_soggetto,
case when sog.soggetto_id is null then sogcla.soggetto_classe_desc else sog.soggetto_desc end descr_soggetto,
movgest.tipo_documento,
movgest.data_registrazione_movimento,
movgest.numero_documento,
movgest.num_det_rif,
movgest.ente_proprietario_id,
movgest.pdce_conto_id,
movgest.tipo_movimento,
movgest.data_det_rif,
movgest.data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
movgest.ambito_prima_nota_id,
movgest.importo_dare,
movgest.importo_avere
 from movgest left join sogcla on
movgest.movgest_ts_id=sogcla.movgest_ts_id
left join sog on
movgest.movgest_ts_id=sog.movgest_ts_id
) as impsubaccmod
--LIQ
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union
union all
SELECT
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
'LIQ'::varchar tipo_pnota,
 c.evento_code::varchar prov_pnota,
s.soggetto_code::varchar cod_soggetto,
 s.soggetto_desc::varchar       descr_soggetto,
'LIQ'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
q.liq_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,
g.evento_tipo_code::varchar  tipo_movimento,
q.liq_emissione_data::date data_det_rif,
m.data_creazione::date  data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
m.ambito_id ambito_prima_nota_id,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_liquidazione q,
       siac_r_liquidazione_soggetto  r,
       siac_t_soggetto  s
WHERE d.collegamento_tipo_code in ('L') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and
        m.bil_id=bil_id_in
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and
        o.pnota_stato_code='D' and
        m.pnota_dataregistrazionegiornale between
        p_data_reg_da and p_data_reg_a  and
        q.liq_id=b.campo_pk_id and
        r.liq_id=q.liq_id and
        s.soggetto_id=r.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union
union all
--DOC
SELECT
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
'FAT'::varchar tipo_pnota,
 c.evento_code::varchar prov_pnota,
t.soggetto_code::varchar cod_soggetto,
 t.soggetto_desc::varchar       descr_soggetto,
'FAT'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.doc_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,
g.evento_tipo_code::varchar  tipo_movimento,
r.doc_data_emissione::date data_det_rif,
m.data_creazione::date  data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
m.ambito_id ambito_prima_nota_id,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_subdoc q,
       siac_t_doc  r,
       siac_r_doc_sog s,
       siac_t_soggetto t
WHERE d.collegamento_tipo_code in ('SS','SE') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and
        m.bil_id=bil_id_in
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and
        o.pnota_stato_code='D' and
        m.pnota_dataregistrazionegiornale between
        p_data_reg_da and p_data_reg_a  and
        q.subdoc_id=b.campo_pk_id and
        r.doc_id=q.doc_id and
        s.doc_id=r.doc_id and
        s.soggetto_id=t.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union
union all
--lib
SELECT
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
case when dd.evento_code='AAP' then 'AAP'::varchar when dd.evento_code='APP' then 'APP'::varchar
else 'LIB'::varchar end tipo_pnota,
 dd.evento_code::varchar prov_pnota,
m.pnota_desc::varchar cod_soggetto,
 ''::varchar       descr_soggetto,
'LIB'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
''::varchar num_det_rif,
m.ente_proprietario_id,
p.pdce_conto_id,
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
m.data_creazione::date  data_registrazione,
-- 08.06/2018 Sofia SIAC-6200
m.ambito_id ambito_prima_nota_id,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere
  FROM siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
siac_t_causale_ep	aa,
siac_d_causale_ep_tipo bb,
siac_r_evento_causale cc,
siac_d_evento dd,
siac_d_evento_tipo g
where
l.ente_proprietario_id=p_ente_prop_id
and l.regep_id=m.pnota_id
and n.pnota_id=m.pnota_id
and o.pnota_stato_id=n.pnota_stato_id
and p.movep_id=l.movep_id
and aa.causale_ep_id=l.causale_ep_id
and bb.causale_ep_tipo_id=aa.causale_ep_tipo_id
and bb.causale_ep_tipo_code='LIB'
and cc.causale_ep_id=aa.causale_ep_id
and dd.evento_id=cc.evento_id
and g.evento_tipo_id=dd.evento_tipo_id and
 m.pnota_dataregistrazionegiornale between
        p_data_reg_da and p_data_reg_a  and
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
aa.data_cancellazione IS NULL AND
bb.data_cancellazione IS NULL AND
cc.data_cancellazione IS NULL AND
dd.data_cancellazione IS NULL AND
g.data_cancellazione IS NULL
AND  n.validita_fine IS NULL
AND  cc.validita_fine IS NULL
AND  m.bil_id = bil_id_in
AND  o.pnota_stato_code = 'D' -- SIAC-5893
        )
        ,cc as
        ( WITH RECURSIVE my_tree AS
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_code, my_tree.livello
from my_tree
),
bb as (select * from siac_rep_struttura_pdce bb where bb.utente=user_table)
         select
nome_ente_in,
bb.pdce_liv0_id::integer  id_pdce0 ,
bb.pdce_liv0_code::varchar codice_pdce0 ,
bb.pdce_liv0_desc  descr_pdce0 ,
bb.pdce_liv1_id id_pdce1,
bb.pdce_liv1_code::varchar  codice_pdce1 ,
bb.pdce_liv1_desc::varchar  descr_pdce1 ,
bb.pdce_liv2_id  id_pdce2 ,
bb.pdce_liv2_code::varchar codice_pdce2 ,
bb.pdce_liv2_desc::varchar  descr_pdce2 ,
bb.pdce_liv3_id  id_pdce3 ,
bb.pdce_liv3_code::varchar  codice_pdce3 ,
bb.pdce_liv3_desc::varchar  descr_pdce3 ,
bb.pdce_liv4_id   id_pdce4 ,
bb.pdce_liv4_code::varchar  codice_pdce4 ,
bb.pdce_liv4_desc::varchar  descr_pdce4 ,
bb.pdce_liv5_id   id_pdce5 ,
bb.pdce_liv5_code::varchar  codice_pdce5 ,
bb.pdce_liv5_desc::varchar  descr_pdce5 ,
bb.pdce_liv6_id   id_pdce6 ,
bb.pdce_liv6_code::varchar  codice_pdce6 ,
bb.pdce_liv6_desc::varchar  descr_pdce6 ,
bb.pdce_liv7_id   id_pdce7 ,
bb.pdce_liv7_code::varchar  codice_pdce7 ,
bb.pdce_liv7_desc::varchar  descr_pdce7 ,
coalesce(bb.pdce_liv8_id,0)::integer   id_pdce8 ,
coalesce(bb.pdce_liv8_code,'')::varchar  codice_pdce8 ,
coalesce(bb.pdce_liv8_desc,'')::varchar  descr_pdce8,
ord.data_registrazione,
ord.num_prima_nota,
ord.tipo_pnota tipo_pnota,
ord.prov_pnota,
ord.cod_soggetto,
ord.descr_soggetto,
ord.tipo_documento tipo_documento,--uguale a tipo_pnota,
ord.data_registrazione_movimento,
''::varchar numero_documento,
ord.num_det_rif,
ord.data_det_rif,
ord.importo_dare,
ord.importo_avere,
--bb.livello::integer,
cc.livello::integer,
ord.tipo_movimento,
0::numeric  saldo_prec_dare,
0::numeric  saldo_prec_avere ,
0::numeric saldo_ini_dare ,
0::numeric saldo_ini_avere ,
--bb.codice_conto::varchar   code_pdce_livello ,
cc.pdce_conto_code::varchar   code_pdce_livello ,
''::varchar  display_error
from ord
     join cc on ord.pdce_conto_id=cc.pdce_conto_id
     cross join bb
where -- 08.06/2018 Sofia SIAC-6200
     ( case when coalesce(p_ambito,'')!='' then ord.ambito_prima_nota_id=pdce_conto_ambito_id
            else ord.ambito_prima_nota_id=ord.ambito_prima_nota_id end )
) as outp;

delete from siac_rep_struttura_pdce 	where utente=user_table;

exception
	when no_data_found THEN
		raise notice 'Prime note non trovate' ;
		--return next;
	when others  THEN
		--raise notice 'errore nella lettura delle prime note ';
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'MASTRINO',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

drop function if exists  siac."BILR205_stampa_mastrino_gsa" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_reg_da date,
  p_data_reg_a date,
  p_pdce_v_livello varchar
);

drop function if exists siac."BILR092_stampa_mastrino" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_reg_da date,
  p_data_reg_a date,
  p_pdce_v_livello varchar
);

CREATE OR REPLACE FUNCTION siac."BILR205_stampa_mastrino_gsa" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_reg_da date,
  p_data_reg_a date,
  p_pdce_v_livello varchar
)
RETURNS TABLE (
  nome_ente varchar,
  id_pdce0 integer,
  codice_pdce0 varchar,
  descr_pdce0 varchar,
  id_pdce1 integer,
  codice_pdce1 varchar,
  descr_pdce1 varchar,
  id_pdce2 integer,
  codice_pdce2 varchar,
  descr_pdce2 varchar,
  id_pdce3 integer,
  codice_pdce3 varchar,
  descr_pdce3 varchar,
  id_pdce4 integer,
  codice_pdce4 varchar,
  descr_pdce4 varchar,
  id_pdce5 integer,
  codice_pdce5 varchar,
  descr_pdce5 varchar,
  id_pdce6 integer,
  codice_pdce6 varchar,
  descr_pdce6 varchar,
  id_pdce7 integer,
  codice_pdce7 varchar,
  descr_pdce7 varchar,
  id_pdce8 integer,
  codice_pdce8 varchar,
  descr_pdce8 varchar,
  data_registrazione date,
  num_prima_nota integer,
  tipo_pnota varchar,
  prov_pnota varchar,
  cod_soggetto varchar,
  descr_soggetto varchar,
  tipo_documento varchar,
  data_registrazione_mov date,
  numero_documento varchar,
  num_det_rif varchar,
  data_det_rif date,
  importo_dare numeric,
  importo_avere numeric,
  livello integer,
  tipo_movimento varchar,
  saldo_prec_dare numeric,
  saldo_prec_avere numeric,
  saldo_ini_dare numeric,
  saldo_ini_avere numeric,
  code_pdce_livello varchar,
  display_error varchar
) AS
$body$
DECLARE
elenco_prime_note record;
elencoPdce record;
dati_movimento record;
dati_eventi record;
--dati_pdce record;
pdce_conto_id_in integer;

DEF_NULL	constant varchar:='';
RTN_MESSAGGIO 		varchar(1000):=DEF_NULL;
user_table			varchar;
nome_ente_in varchar;
bil_id_in integer;



BEGIN


return query
select outpt.*
from
(
 select *
 from fnc_bilr_stampa_mastrino
  (
  p_ente_prop_id,
  p_anno,
  p_data_reg_da,
  p_data_reg_a,
  p_pdce_v_livello,
  'AMBITO_GSA'
  )
) outpt;

exception
	when no_data_found THEN
		raise notice 'Prime note non trovate' ;
		--return next;
	when others  THEN
		--raise notice 'errore nella lettura delle prime note ';
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'MASTRINO',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;


CREATE OR REPLACE FUNCTION siac."BILR092_stampa_mastrino" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_reg_da date,
  p_data_reg_a date,
  p_pdce_v_livello varchar
)
RETURNS TABLE (
  nome_ente varchar,
  id_pdce0 integer,
  codice_pdce0 varchar,
  descr_pdce0 varchar,
  id_pdce1 integer,
  codice_pdce1 varchar,
  descr_pdce1 varchar,
  id_pdce2 integer,
  codice_pdce2 varchar,
  descr_pdce2 varchar,
  id_pdce3 integer,
  codice_pdce3 varchar,
  descr_pdce3 varchar,
  id_pdce4 integer,
  codice_pdce4 varchar,
  descr_pdce4 varchar,
  id_pdce5 integer,
  codice_pdce5 varchar,
  descr_pdce5 varchar,
  id_pdce6 integer,
  codice_pdce6 varchar,
  descr_pdce6 varchar,
  id_pdce7 integer,
  codice_pdce7 varchar,
  descr_pdce7 varchar,
  id_pdce8 integer,
  codice_pdce8 varchar,
  descr_pdce8 varchar,
  data_registrazione date,
  num_prima_nota integer,
  tipo_pnota varchar,
  prov_pnota varchar,
  cod_soggetto varchar,
  descr_soggetto varchar,
  tipo_documento varchar,
  data_registrazione_mov date,
  numero_documento varchar,
  num_det_rif varchar,
  data_det_rif date,
  importo_dare numeric,
  importo_avere numeric,
  livello integer,
  tipo_movimento varchar,
  saldo_prec_dare numeric,
  saldo_prec_avere numeric,
  saldo_ini_dare numeric,
  saldo_ini_avere numeric,
  code_pdce_livello varchar,
  display_error varchar
) AS
$body$
DECLARE
elenco_prime_note record;
elencoPdce record;
dati_movimento record;
dati_eventi record;
--dati_pdce record;
pdce_conto_id_in integer;

DEF_NULL	constant varchar:='';
RTN_MESSAGGIO 		varchar(1000):=DEF_NULL;
user_table			varchar;
nome_ente_in varchar;
bil_id_in integer;



BEGIN

return query
select outpt.*
from
(
 select *
 from fnc_bilr_stampa_mastrino
  (
  p_ente_prop_id,
  p_anno,
  p_data_reg_da,
  p_data_reg_a,
  p_pdce_v_livello,
  null
  )
) outpt;

exception
	when no_data_found THEN
		raise notice 'Prime note non trovate' ;
		--return next;
	when others  THEN
		--raise notice 'errore nella lettura delle prime note ';
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'MASTRINO',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- siac-6200 Sofia - Fine

-- siac-6233 - Sofia Inizio
drop view if exists siac_v_dwh_oneri_doc;

CREATE OR REPLACE VIEW siac_v_dwh_oneri_doc (
    ente_proprietario_id,
    doc_tipo_code,
    doc_anno,
    doc_numero,
    data_emissione,
    soggetto_id,
    soggetto_code,
    onere_tipo_code,
    onere_tipo_desc,
    onere_code,
    onere_desc,
    importo_imponibile,
    importo_carico_ente,
    importo_carico_soggetto,
    somma_non_soggetta,
    perc_carico_ente,
    perc_carico_sogg,
    doc_stato_code,
    doc_stato_desc,
    doc_id,
    attivita_code,
    attivita_desc,
    attivita_inizio,
    attivita_fine,
    quadro_770,
    causale_code,
    causale_desc,
    somma_non_soggetta_tipo_code,
    somma_non_soggetta_tipo_desc)
AS
SELECT --DISTINCT  11.06.2018 Sofia SIAC-6233
    tb.ente_proprietario_id, tb.doc_tipo_code, tb.doc_anno,
    tb.doc_numero, tb.doc_data_emissione AS data_emissione, tb.soggetto_id,
    tb.soggetto_code, tb.onere_code AS onere_tipo_code,
    tb.onere_desc AS onere_tipo_desc, tb.onere_tipo_code AS onere_code,
    tb.onere_tipo_desc AS onere_desc, tb.importo_imponibile,
    tb.importo_carico_ente, tb.importo_carico_soggetto, tb.somma_non_soggetta,
    tb.perc_carico_ente, tb.perc_carico_sogg, tb.doc_stato_code,
    tb.doc_stato_desc, tb.doc_id, tb.onere_att_code AS attivita_code,
    tb.onere_att_desc AS attivita_desc, tb.attivita_inizio, tb.attivita_fine,
    tb.quadro_770, tb.caus_code AS causale_code, tb.caus_desc AS causale_desc,
    tb.somma_non_soggetta_tipo_code, tb.somma_non_soggetta_tipo_desc
FROM ( WITH aa AS (
    SELECT a.ente_proprietario_id, dt.doc_tipo_code, d.doc_anno,
                    d.doc_numero, d.doc_data_emissione, e.soggetto_id,
                    e.soggetto_code, a.onere_code, a.onere_desc,
                    b.onere_tipo_code, b.onere_tipo_desc, c.importo_imponibile,
                    c.importo_carico_ente, c.importo_carico_soggetto,
                    COALESCE(c.somma_non_soggetta, 0::numeric) AS somma_non_soggetta,
                    a.onere_id, g.doc_stato_code, g.doc_stato_desc, d.doc_id,
                    c.onere_att_id, c.caus_id, c.somma_non_soggetta_tipo_id,
                    c.attivita_inizio, c.attivita_fine
    FROM siac_d_onere a, siac_d_onere_tipo b, siac_r_doc_onere c,
                    siac_t_doc d, siac_d_doc_tipo dt, siac_r_doc_sog er,
                    siac_t_soggetto e, siac_r_doc_stato f, siac_d_doc_stato g
    WHERE a.onere_tipo_id = b.onere_tipo_id AND a.onere_id = c.onere_id AND
        c.doc_id = d.doc_id AND dt.doc_tipo_id = d.doc_tipo_id AND er.doc_id = d.doc_id AND er.soggetto_id = e.soggetto_id AND f.doc_id = d.doc_id AND f.doc_stato_id = g.doc_stato_id AND a.data_cancellazione IS NULL AND b.data_cancellazione IS NULL AND c.data_cancellazione IS NULL AND d.data_cancellazione IS NULL AND dt.data_cancellazione IS NULL AND er.data_cancellazione IS NULL AND e.data_cancellazione IS NULL AND f.data_cancellazione IS NULL AND g.data_cancellazione IS NULL AND now() >= c.validita_inizio AND now() <= COALESCE(c.validita_fine::timestamp with time zone, now()) AND now() >= er.validita_inizio AND now() <= COALESCE(er.validita_fine::timestamp with time zone, now()) AND now() >= f.validita_inizio AND now() <= COALESCE(f.validita_fine::timestamp with time zone, now())
    ), bb AS (
    SELECT rattr1.onere_id,
                    COALESCE(rattr1.percentuale, 0::numeric) AS perc_carico_ente
    FROM siac_r_onere_attr rattr1, siac_t_attr attr1
    WHERE rattr1.attr_id = attr1.attr_id AND attr1.attr_code::text =
        'ALIQUOTA_ENTE'::text AND rattr1.data_cancellazione IS NULL AND attr1.data_cancellazione IS NULL AND now() >= rattr1.validita_inizio AND now() <= COALESCE(rattr1.validita_fine::timestamp with time zone, now())
    ), cc AS (
    SELECT rattr2.onere_id,
                    COALESCE(rattr2.percentuale, 0::numeric) AS perc_carico_sogg
    FROM siac_r_onere_attr rattr2, siac_t_attr attr2
    WHERE rattr2.attr_id = attr2.attr_id AND attr2.attr_code::text =
        'ALIQUOTA_SOGG'::text AND rattr2.data_cancellazione IS NULL AND attr2.data_cancellazione IS NULL AND now() >= rattr2.validita_inizio AND now() <= COALESCE(rattr2.validita_fine::timestamp with time zone, now())
    ), dd AS (
    SELECT roa.onere_id, doa.onere_att_code, doa.onere_att_desc,
                    roa.onere_att_id
    FROM siac_r_onere_attivita roa, siac_d_onere_attivita doa
    WHERE roa.onere_att_id = doa.onere_att_id AND roa.data_cancellazione IS
        NULL AND doa.data_cancellazione IS NULL AND now() >= roa.validita_inizio AND now() <= COALESCE(roa.validita_fine::timestamp with time zone, now())
    ), ee AS (
    SELECT rattr3.onere_id, rattr3.testo AS quadro_770
    FROM siac_r_onere_attr rattr3, siac_t_attr attr3
    WHERE rattr3.attr_id = attr3.attr_id AND attr3.attr_code::text =
        'QUADRO_770'::text AND rattr3.data_cancellazione IS NULL AND attr3.data_cancellazione IS NULL AND now() >= rattr3.validita_inizio AND now() <= COALESCE(rattr3.validita_fine::timestamp with time zone, now())
    ), ff AS (
    SELECT dc.caus_id, dc.caus_code, dc.caus_desc
    FROM siac_d_causale dc
    WHERE dc.data_cancellazione IS NULL
    ), gg AS (
    SELECT dsnst.somma_non_soggetta_tipo_id,
                    dsnst.somma_non_soggetta_tipo_code,
                    dsnst.somma_non_soggetta_tipo_desc
    FROM siac_d_somma_non_soggetta_tipo dsnst
    WHERE dsnst.data_cancellazione IS NULL
    )
    SELECT aa.ente_proprietario_id, aa.doc_tipo_code, aa.doc_anno,
            aa.doc_numero, aa.doc_data_emissione, aa.soggetto_id,
            aa.soggetto_code, aa.onere_code, aa.onere_desc, aa.onere_tipo_code,
            aa.onere_tipo_desc, aa.importo_imponibile, aa.importo_carico_ente,
            aa.importo_carico_soggetto, aa.somma_non_soggetta,
            bb.perc_carico_ente, cc.perc_carico_sogg, aa.doc_stato_code,
            aa.doc_stato_desc, aa.doc_id, dd.onere_att_code, dd.onere_att_desc,
            aa.attivita_inizio, aa.attivita_fine, ee.quadro_770, ff.caus_code,
            ff.caus_desc, gg.somma_non_soggetta_tipo_code,
            gg.somma_non_soggetta_tipo_desc
    FROM aa
      LEFT JOIN bb ON aa.onere_id = bb.onere_id
   LEFT JOIN cc ON aa.onere_id = cc.onere_id
   LEFT JOIN dd ON aa.onere_id = dd.onere_id AND aa.onere_att_id = dd.onere_att_id
   LEFT JOIN ee ON aa.onere_id = ee.onere_id
   LEFT JOIN ff ON aa.caus_id = ff.caus_id
   LEFT JOIN gg ON aa.somma_non_soggetta_tipo_id = gg.somma_non_soggetta_tipo_id
    ) tb; 
	
-- siac-6233 - Sofia Fine

-- siac-6201 - Sofia Inizio

drop function if exists siac."BILR206_rendiconto_gestione_gsa" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_classificatori varchar
);

CREATE OR REPLACE FUNCTION siac."BILR206_rendiconto_gestione_gsa" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_classificatori varchar
)
RETURNS TABLE (
  tipo_codifica varchar,
  codice_codifica varchar,
  descrizione_codifica varchar,
  livello_codifica integer,
  importo_codice_bilancio numeric,
  codice_raggruppamento varchar,
  descr_raggruppamento varchar,
  codice_codifica_albero varchar,
  valore_importo integer,
  codice_subraggruppamento varchar,
--  importo_dati_passivo numeric, -- 11.06.2018 Sofia siac-6201 - non serve
  classif_id_liv1 integer,
  classif_id_liv2 integer,
  classif_id_liv3 integer,
  classif_id_liv4 integer,
  classif_id_liv5 integer,
  classif_id_liv6 integer,
  pdce_conto_code varchar,
  pdce_conto_descr varchar,
  importo_dare numeric,
  importo_avere numeric
) AS
$body$
DECLARE

classifGestione record;
pdce            record;

v_imp_dare           NUMERIC :=0;
v_imp_avere          NUMERIC :=0;

v_importo 			 NUMERIC :=0;
v_pdce_fam_code      VARCHAR;
v_classificatori     VARCHAR;
v_classificatori1    VARCHAR;
v_codice_subraggruppamento VARCHAR;
v_anno_int integer;

DEF_NULL	constant VARCHAR:='';
RTN_MESSAGGIO 		 VARCHAR(1000):=DEF_NULL;
user_table			 VARCHAR;

BEGIN


RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into   user_table;

v_anno_int := p_anno::integer;

tipo_codifica := '';
codice_codifica := '';
descrizione_codifica := '';
livello_codifica := 0;
importo_codice_bilancio := 0;
codice_raggruppamento := '';
descr_raggruppamento := '';
codice_codifica_albero := '';
valore_importo := 0;
codice_subraggruppamento := '';
classif_id_liv1 := 0;
classif_id_liv2 := 0;
classif_id_liv3 := 0;
classif_id_liv4 := 0;
classif_id_liv5 := 0;
classif_id_liv6 := 0;
pdce_conto_code := '';
pdce_conto_descr := '';
importo_dare :=0;
importo_avere :=0;

RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';
raise notice '1 - %' , clock_timestamp()::text;

v_classificatori  := '';
v_classificatori1 := '';
v_codice_subraggruppamento := '';



IF p_classificatori = '1' THEN
   v_classificatori := '00024'; -- conto economico (codice di bilancio) gsa
ELSIF p_classificatori = '2' THEN
   v_classificatori := '00026'; -- stato patrimoniale attivo (codice di bilancio) gsa
ELSIF p_classificatori = '3' THEN
   v_classificatori  := '00025';  -- stato patrimoniale passivo (codice di bilancio) gsa
END IF;


raise notice '1 - %' , v_classificatori;


-- attivita - passivita con segno negativo -- 11.06.Sofia siac-6201 - non serve
/*IF p_classificatori = '2' THEN

WITH Importipn AS
(
 SELECT
        Importipn.pdce_conto_id,
        Importipn.anno,
        CASE
            WHEN Importipn.movep_det_segno = 'Dare' THEN
                 Importipn.movep_det_importo
            ELSE
                 0
        END  importo_dare,
        CASE
            WHEN Importipn.movep_det_segno = 'Avere' THEN
                 Importipn.movep_det_importo
            ELSE
                 0
        END  importo_avere
  FROM (
   SELECT  anno_eserc.anno,
            CASE
              WHEN pdce_conto.livello = 8 THEN
                   (select a.pdce_conto_id_padre
                   from   siac_t_pdce_conto a
                   where  a.pdce_conto_id = pdce_conto.pdce_conto_id
                   and    a.data_cancellazione is null)
              ELSE
               pdce_conto.pdce_conto_id
            END pdce_conto_id,
            mov_ep_det.movep_det_segno,
            mov_ep_det.movep_det_importo
    FROM   siac_t_periodo	 		anno_eserc,
           siac_t_bil	 			bilancio,
           siac_t_prima_nota        prima_nota,
           siac_t_mov_ep_det	    mov_ep_det,
           siac_r_prima_nota_stato  r_pnota_stato,
           siac_d_prima_nota_stato  pnota_stato,
           siac_t_pdce_conto	    pdce_conto,
           siac_t_pdce_fam_tree     pdce_fam_tree,
           siac_d_pdce_fam          pdce_fam,
           siac_t_causale_ep	    causale_ep,
           siac_t_mov_ep		    mov_ep
    WHERE  bilancio.periodo_id=anno_eserc.periodo_id
    AND    prima_nota.bil_id=bilancio.bil_id
    AND    prima_nota.ente_proprietario_id=anno_eserc.ente_proprietario_id
    AND    prima_nota.pnota_id=mov_ep.regep_id
    AND    mov_ep.movep_id=mov_ep_det.movep_id
    AND    r_pnota_stato.pnota_id=prima_nota.pnota_id
    AND    pnota_stato.pnota_stato_id=r_pnota_stato.pnota_stato_id
    AND    pdce_conto.pdce_conto_id=mov_ep_det.pdce_conto_id
    AND    pdce_conto.pdce_fam_tree_id=pdce_fam_tree.pdce_fam_tree_id
    AND    pdce_fam_tree.pdce_fam_id=pdce_fam.pdce_fam_id
    AND    causale_ep.causale_ep_id=mov_ep.causale_ep_id
    AND prima_nota.ente_proprietario_id=p_ente_prop_id
    AND anno_eserc.anno IN (p_anno)
    AND pdce_conto.pdce_conto_id IN (select a.pdce_conto_id
                                     from  siac_r_pdce_conto_attr a, siac_t_attr c
                                     where a.attr_id = c.attr_id
                                     and   c.attr_code = 'pdce_conto_segno_negativo'
                                     and   a."boolean" = 'S'
                                     and   a.ente_proprietario_id = p_ente_prop_id)
    AND pnota_stato.pnota_stato_code='D'
    AND pdce_fam.pdce_fam_code IN ('PP','OP')
    AND bilancio.data_cancellazione is NULL
    AND anno_eserc.data_cancellazione is NULL
    AND prima_nota.data_cancellazione is NULL
    AND mov_ep.data_cancellazione is NULL
    AND mov_ep_det.data_cancellazione is NULL
    AND r_pnota_stato.data_cancellazione is NULL
    AND pnota_stato.data_cancellazione is NULL
    AND pdce_conto.data_cancellazione is NULL
    AND pdce_fam_tree.data_cancellazione is NULL
    AND pdce_fam.data_cancellazione is NULL
    AND causale_ep.data_cancellazione is NULL
    ) Importipn
    ),
    codifica_bilancio as (
    SELECT a.pdce_conto_id, tb.ordine
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
        classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, level, arrhierarchy) AS (
        SELECT rt1.classif_classif_fam_tree_id,
                                rt1.classif_fam_tree_id, rt1.classif_id,
                                rt1.classif_id_padre, rt1.ente_proprietario_id,
                                rt1.ordine, rt1.livello, 1,
                                ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
        FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1,  siac_d_class_fam cf
        WHERE cf.classif_fam_id = tt1.classif_fam_id
        AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id
        AND   rt1.classif_id_padre IS NULL
        AND   cf.classif_fam_code::text = '00026'::text
        AND   tt1.ente_proprietario_id = rt1.ente_proprietario_id
        AND   rt1.data_cancellazione is null
        AND   tt1.data_cancellazione is null
        AND   cf.data_cancellazione is null
        --AND   date_trunc('day'::text, now()) > rt1.validita_inizio
        --AND  (date_trunc('day'::text, now()) < rt1.validita_fine OR tt1.validita_fine IS NULL)
        AND   cf.ente_proprietario_id = p_ente_prop_id
        UNION ALL
        SELECT tn.classif_classif_fam_tree_id,
                                tn.classif_fam_tree_id, tn.classif_id,
                                tn.classif_id_padre, tn.ente_proprietario_id,
                                tn.ordine, tn.livello, tp.level + 1,
                                tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn
        WHERE tp.classif_id = tn.classif_id_padre
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        AND tn.ente_proprietario_id = p_ente_prop_id
        AND  tn.data_cancellazione is null
        )
        SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
                rqname.classif_id, rqname.classif_id_padre,
                rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
                rqname.level
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb, siac_t_class t1,
        siac_d_class_tipo ti1,
        siac_r_pdce_conto_class a
    WHERE t1.classif_id = tb.classif_id
    AND   ti1.classif_tipo_id = t1.classif_tipo_id
    AND   t1.ente_proprietario_id = tb.ente_proprietario_id
    AND   ti1.ente_proprietario_id = t1.ente_proprietario_id
    AND   a.classif_id = t1.classif_id
    AND   a.ente_proprietario_id = t1.ente_proprietario_id
    AND   t1.data_cancellazione is null
    AND   ti1.data_cancellazione is null
    AND   a.data_cancellazione is null
    AND   v_anno_int BETWEEN date_part('year',t1.validita_inizio) AND date_part('year',COALESCE(t1.validita_fine,now())) --SIAC-5487
    AND   v_anno_int BETWEEN date_part('year',a.validita_inizio) AND date_part('year',COALESCE(a.validita_fine,now())) -- SIAC-6156
    )
    INSERT INTO rep_bilr125_dati_stato_passivo
    SELECT
    Importipn.anno,
    codifica_bilancio.ordine,
    SUM(Importipn.importo_dare) importo_dare,
    SUM(Importipn.importo_avere) importo_avere,
    SUM(Importipn.importo_avere - Importipn.importo_dare) importo_passivo,
    user_table
    FROM Importipn
    INNER JOIN codifica_bilancio ON Importipn.pdce_conto_id = codifica_bilancio.pdce_conto_id
    GROUP BY Importipn.anno, codifica_bilancio.ordine ;

END IF;*/

-- loop per codifica di bilancio
-- CODBIL_GSA
-- CE_CODBIL_GSA  1 - costi,ricavi
-- SPA_CODBIL_GSA 2 - attivita bilancio
-- SPP_CODBIL_GSA 3 - passivita bilancio
FOR classifGestione IN
SELECT zz.ente_proprietario_id,
       zz.classif_tipo_code AS tipo_codifica,
       zz.classif_code AS codice_codifica,
       zz.classif_desc AS descrizione_codifica,
       zz.ordine AS codice_codifica_albero,
       case when zz.ordine='E.26' then 3 else zz.level end livello_codifica,
       zz.classif_id,
       zz.classif_id_padre,
       zz.arrhierarchy,
       COALESCE(zz.arrhierarchy[1],0) classif_id_liv1,
       COALESCE(zz.arrhierarchy[2],0) classif_id_liv2,
       COALESCE(zz.arrhierarchy[3],0) classif_id_liv3,
       COALESCE(zz.arrhierarchy[4],0) classif_id_liv4,
       COALESCE(zz.arrhierarchy[5],0) classif_id_liv5,
       COALESCE(zz.arrhierarchy[6],0) classif_id_liv6
FROM
(
    SELECT tb.classif_classif_fam_tree_id,
           tb.classif_fam_tree_id, t1.classif_code,
           t1.classif_desc, ti1.classif_tipo_code,
           tb.classif_id, tb.classif_id_padre,
           tb.ente_proprietario_id,
           CASE WHEN tb.ordine = 'B.9' THEN 'B.09'
           ELSE tb.ordine
           END  ordine,
           tb.level,
           tb.arrhierarchy
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id,
                                 classif_fam_tree_id,
                                 classif_id,
                                 classif_id_padre,
                                 ente_proprietario_id,
                                 ordine,
                                 livello,
                                 level, arrhierarchy) AS (
           SELECT rt1.classif_classif_fam_tree_id,
                  rt1.classif_fam_tree_id,
                  rt1.classif_id,
                  rt1.classif_id_padre,
                  rt1.ente_proprietario_id,
                  rt1.ordine,
                  rt1.livello, 1,
                  ARRAY[COALESCE(rt1.classif_id,0)] AS "array"
           FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1, siac_d_class_fam cf, siac_t_class c
           WHERE cf.classif_fam_id = tt1.classif_fam_id
           and c.classif_id=rt1.classif_id
           AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id
           AND rt1.classif_id_padre IS NULL
           AND   (cf.classif_fam_code = v_classificatori OR cf.classif_fam_code = v_classificatori1)
           AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
           AND v_anno_int BETWEEN date_part('year',tt1.validita_inizio) AND
           date_part('year',COALESCE(tt1.validita_fine,now()))
           AND v_anno_int BETWEEN date_part('year',rt1.validita_inizio) AND
           date_part('year',COALESCE(rt1.validita_fine,now()))
           AND v_anno_int BETWEEN date_part('year',c.validita_inizio) AND
           date_part('year',COALESCE(c.validita_fine,now()))
           AND tt1.ente_proprietario_id = p_ente_prop_id
           UNION ALL
           SELECT tn.classif_classif_fam_tree_id,
                  tn.classif_fam_tree_id,
                  tn.classif_id,
                  tn.classif_id_padre,
                  tn.ente_proprietario_id,
                  tn.ordine,
                  tn.livello,
                  tp.level + 1,
                  tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn,siac_t_class c2
        WHERE tp.classif_id = tn.classif_id_padre
        and c2.classif_id=tn.classif_id
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        AND v_anno_int BETWEEN date_part('year',tn.validita_inizio) AND
           date_part('year',COALESCE(tn.validita_fine,now()))
        AND v_anno_int BETWEEN date_part('year',c2.validita_inizio) AND
           date_part('year',COALESCE(c2.validita_fine,now()))
        )
        SELECT rqname.classif_classif_fam_tree_id,
               rqname.classif_fam_tree_id,
               rqname.classif_id,
               rqname.classif_id_padre,
               rqname.ente_proprietario_id,
               rqname.ordine, rqname.livello,
               rqname.level,
               rqname.arrhierarchy
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb,
        siac_t_class t1, siac_d_class_tipo ti1
    WHERE t1.classif_id = tb.classif_id
    AND ti1.classif_tipo_id = t1.classif_tipo_id
    AND t1.ente_proprietario_id = tb.ente_proprietario_id
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id
    AND v_anno_int BETWEEN date_part('year',t1.validita_inizio) AND date_part('year',COALESCE(t1.validita_fine,now())) --SIAC-5487
) zz
ORDER BY zz.classif_tipo_code desc,
         zz.ordine
LOOP

    valore_importo := 0;

    SELECT COUNT(*)
    INTO   valore_importo
    FROM   siac_r_class_fam_tree a
    WHERE  a.classif_id_padre = classifGestione.classif_id
    AND    a.data_cancellazione IS NULL;

    IF classifGestione.livello_codifica = 3 THEN
       v_codice_subraggruppamento := classifGestione.codice_codifica;
       codice_subraggruppamento := v_codice_subraggruppamento;
    ELSIF classifGestione.livello_codifica < 3 THEN
       codice_subraggruppamento := '';
    ELSIF classifGestione.livello_codifica > 3 THEN
       codice_subraggruppamento := v_codice_subraggruppamento;
    END IF;

    IF classifGestione.livello_codifica = 2 THEN
       codice_raggruppamento := SUBSTRING(classifGestione.descrizione_codifica FROM 1 FOR 1);
       descr_raggruppamento := classifGestione.descrizione_codifica;
    ELSIF classifGestione.livello_codifica = 1 THEN
       codice_raggruppamento := '';
       descr_raggruppamento := '';
    END IF;

  /* 11.06.2018 Sofia siac-6201 - non esiste per GSA
    IF classifGestione.tipo_codifica = 'CO_CODBIL' AND classifGestione.livello_codifica <> 1 THEN
       codice_raggruppamento := 'Z';
       descr_raggruppamento := 'CONTI D''ORDINE';
    END IF; */


/*  -- 11.06.2018 Sofia siac-6201 - non serve
    importo_dati_passivo :=0;

    IF p_classificatori = '2' THEN
      SELECT importo_passivo
      INTO   importo_dati_passivo
      FROM   rep_bilr125_dati_stato_passivo
      WHERE  anno = p_anno
      AND    codice_codifica_albero_passivo = classifGestione.codice_codifica_albero
      AND    utente = user_table;

    END IF;*/

    v_imp_dare := 0;
    v_imp_avere := 0;
    v_importo := 0;
    v_pdce_fam_code := '';
    raise notice 'classif_id = %', classifGestione.classif_id;

-- inizio loop per conto
FOR pdce IN
   WITH
   conti AS
   (
    SELECT fam.pdce_fam_code,
           conto.pdce_conto_code, conto.pdce_conto_desc,
           conto.pdce_conto_id
    from siac_r_pdce_conto_class r,  siac_t_pdce_conto conto,
         siac_t_pdce_fam_tree famtree, siac_d_pdce_fam fam,siac_d_ambito ambito
    where r.classif_id=classifGestione.classif_id
    and   conto.pdce_conto_id=r.pdce_conto_id
    and   famtree.pdce_fam_tree_id=conto.pdce_fam_tree_id
    and   fam.pdce_fam_id=famtree.pdce_fam_id
    and   ambito.ambito_id=conto.ambito_id
    and   ambito.ambito_code='AMBITO_GSA'
    and   r.data_cancellazione is null
    and   conto.data_cancellazione is null
    and   v_anno_int BETWEEN date_part('year',r.validita_inizio)::integer and  coalesce (date_part('year',r.validita_fine)::integer ,v_anno_int)
	and   v_anno_int BETWEEN date_part('year',conto.validita_inizio) AND date_part('year',COALESCE(conto.validita_fine,now()))
   ),
   movimenti as
   (
    select det.pdce_conto_id,
           sum( case  when det.movep_det_segno='Dare' then COALESCE(det.movep_det_importo,0) else 0 end ) as importo_dare,
           sum( case  when det.movep_det_segno='Avere' then COALESCE(det.movep_det_importo,0) else 0 end ) as importo_avere
    from  siac_t_periodo per,   siac_t_bil bil,
          siac_t_prima_nota pn, siac_r_prima_nota_stato rs, siac_d_prima_nota_stato stato,
          siac_t_mov_ep ep, siac_t_mov_ep_det det,siac_d_ambito ambito
    where bil.ente_proprietario_id=p_ente_prop_id
    and   per.periodo_id=bil.periodo_id
    and   per.anno::integer=v_anno_int
    and   pn.bil_id=bil.bil_id
    and   rs.pnota_id=pn.pnota_id
    and   stato.pnota_stato_id=rs.pnota_stato_id
    and   stato.pnota_stato_code='D'
    and   ep.regep_id=pn.pnota_id
    and   det.movep_id=ep.movep_id
    and   ambito.ambito_id=pn.ambito_id
    and   ambito.ambito_code='AMBITO_GSA'
    and   pn.data_cancellazione is null
    and   pn.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   ep.data_cancellazione is null
    and   ep.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null
    group by det.pdce_conto_id
   )
   select  conti.pdce_fam_code,
           conti.pdce_conto_code, conti.pdce_conto_desc,
           coalesce(movimenti.importo_dare,0) importo_dare, coalesce(movimenti.importo_avere,0) importo_avere
   from conti left join   movimenti on ( conti.pdce_conto_id=movimenti.pdce_conto_id )
LOOP
    raise notice 'Importo Dare = %', pdce.importo_dare;
    raise notice 'Importo Avere = %', pdce.importo_avere;

    v_imp_dare:=pdce.importo_dare;
    v_imp_avere := pdce.importo_avere;
    v_pdce_fam_code := pdce.pdce_fam_code;

    importo_avere:= v_imp_avere;
    importo_dare:=v_imp_dare;
    pdce_conto_code:=pdce.pdce_conto_code;
    pdce_conto_descr:= pdce.pdce_conto_desc;


    IF p_classificatori IN ('1','3') THEN

      IF v_pdce_fam_code IN ('PP','OP','OA','RE') THEN
         v_importo := v_imp_avere - v_imp_dare;
      ELSIF v_pdce_fam_code IN ('AP','CE') THEN
         v_importo := v_imp_dare - v_imp_avere;
      END IF;



    ELSIF p_classificatori = '2' THEN

      IF v_pdce_fam_code = 'AP' THEN
         v_importo := v_imp_dare - v_imp_avere;
      END IF;


    -- raise notice 'Famiglia %, Classe %, Importo %, Dare %, Avere %',v_pdce_fam_code,classifGestione.classif_id,COALESCE(v_importo,0),COALESCE(v_imp_dare,0),COALESCE(v_imp_avere,0);

    END IF;

    tipo_codifica := classifGestione.tipo_codifica;
    codice_codifica := classifGestione.codice_codifica;
    descrizione_codifica := classifGestione.descrizione_codifica;
    livello_codifica := classifGestione.livello_codifica;

    IF p_classificatori != '1' THEN

      IF valore_importo = 0 or classifGestione.codice_codifica_albero = 'B.III.2.1' or classifGestione.codice_codifica_albero = 'B.III.2.2'  or classifGestione.codice_codifica_albero = 'B.III.2.3' THEN
         importo_codice_bilancio := v_importo;
      ELSE
         importo_codice_bilancio := 0;
      END IF;

    ELSE
      importo_codice_bilancio := v_importo;
    END IF;

    codice_codifica_albero := classifGestione.codice_codifica_albero;

    classif_id_liv1 := classifGestione.classif_id_liv1;
    classif_id_liv2 := classifGestione.classif_id_liv2;
    classif_id_liv3 := classifGestione.classif_id_liv3;
    classif_id_liv4 := classifGestione.classif_id_liv4;
    classif_id_liv5 := classifGestione.classif_id_liv5;
    classif_id_liv6 := classifGestione.classif_id_liv6;

    return next;

    tipo_codifica := '';
    codice_codifica := '';
    descrizione_codifica := '';
    livello_codifica := 0;
    importo_codice_bilancio := 0;
    codice_codifica_albero := '';
    classif_id_liv1 := 0;
    classif_id_liv2 := 0;
    classif_id_liv3 := 0;
    classif_id_liv4 := 0;
    classif_id_liv5 := 0;
    classif_id_liv6 := 0;
    pdce_conto_code := '';
    pdce_conto_descr := '';
    importo_dare :=0;
    importo_avere :=0;
  end loop;  -- loop per conto

  valore_importo := 0;
  codice_subraggruppamento := '';
--  importo_dati_passivo :=0; -- 11.06.2018 Sofia siac-6201 - non serve


END LOOP; -- loop per codifica di bilancio

--delete from rep_bilr125_dati_stato_passivo where utente=user_table; -- 11.06.2018 Sofia siac-6201 - non serve

raise notice '2 - %' , clock_timestamp()::text;
raise notice 'fine OK';

  EXCEPTION
  WHEN no_data_found THEN
  raise notice 'nessun dato trovato per rendiconto gestione GSA';
  return;
  WHEN others  THEN
  RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
  return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- siac-6201 - Sofia Fine

-- SIAC-6215 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR029_soggetti_persona_fisica"(p_ente_prop_id integer, p_codice_soggetto varchar, p_denominazione varchar, p_stato_soggetto varchar, p_classe_soggetto varchar, p_tipo_estrazione varchar);
DROP FUNCTION if exists siac."BILR029_soggetti_persona_fisica_e_giuridica"(p_ente_prop_id integer, p_denominazione varchar, p_stato_soggetto varchar, p_classe_soggetto varchar, p_tipo_estrazione varchar);
DROP FUNCTION if exists siac."BILR029_soggetti_persona_giuridica"(p_ente_prop_id integer, p_codice_soggetto varchar, p_denominazione varchar, p_stato_soggetto varchar, p_classe_soggetto varchar, p_tipo_estrazione varchar);

CREATE OR REPLACE FUNCTION siac."BILR029_soggetti_persona_giuridica" (
  p_ente_prop_id integer,
  p_codice_soggetto varchar = NULL::character varying,
  p_denominazione varchar = NULL::character varying,
  p_stato_soggetto varchar = NULL::character varying,
  p_classe_soggetto varchar = NULL::character varying,
  p_tipo_estrazione varchar = NULL::character varying
)
RETURNS TABLE (
  ambito_id integer,
  soggetto_code varchar,
  codice_fiscale varchar,
  codice_fiscale_estero varchar,
  partita_iva varchar,
  soggetto_desc varchar,
  soggetto_tipo_code varchar,
  soggetto_tipo_desc varchar,
  forma_giuridica_cat_id varchar,
  forma_giuridica_desc varchar,
  forma_giuridica_istat_codice varchar,
  soggetto_id integer,
  stato varchar,
  classe_soggetto varchar,
  desc_tipo_indirizzo varchar,
  tipo_indirizzo varchar,
  via_indirizzo varchar,
  toponimo_indirizzo varchar,
  numero_civico_indirizzo varchar,
  interno_indirizzo varchar,
  frazione_indirizzo varchar,
  comune_indirizzo varchar,
  provincia_indirizzo varchar,
  provincia_sigla_indirizzo varchar,
  stato_indirizzo varchar,
  indirizzo_id integer,
  avviso varchar,
  sede_indirizzo_id integer,
  sede_via_indirizzo varchar,
  sede_toponimo_indirizzo varchar,
  sede_numero_civico_indirizzo varchar,
  sede_interno_indirizzo varchar,
  sede_frazione_indirizzo varchar,
  sede_comune_indirizzo varchar,
  sede_provincia_indirizzo varchar,
  sede_provincia_sigla_indirizzo varchar,
  sede_stato_indirizzo varchar,
  mp_soggetto_id integer,
  mp_soggetto_desc varchar,
  mp_accredito_tipo_code varchar,
  mp_accredito_tipo_desc varchar,
  mp_modpag_stato_desc varchar,
  ricevente varchar,
  accredito_tipo_code varchar,
  accredito_tipo_desc varchar,
  note varchar,
  ricevente_cod_fis varchar,
  ricevente_piva varchar,
  quietanzante varchar,
  quietanzante_cod_fis varchar,
  bic varchar,
  conto_corrente varchar,
  iban varchar,
  mp_data_scadenza date,
  data_scadenza_cessione date
) AS
$body$
DECLARE
	dati_soggetto record;
    DEF_NULL	constant varchar:=''; 
    DEF_SPACES	constant varchar:=' '; 
    RTN_MESSAGGIO varchar(1000):=DEF_NULL;
    user_table	varchar;
  
  BEGIN
  
select fnc_siac_random_user()
into	user_table;


if coalesce(p_stato_soggetto ,DEF_NULL)=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)=DEF_NULL then
      raise notice '1';
    insert into siac_rep_persona_giuridica
	select 	a.ambito_id,
            a.soggetto_code,
            a.codice_fiscale,
            a.codice_fiscale_estero,
            a.partita_iva,
            b.ragione_sociale,
            d.soggetto_tipo_code,
            d.soggetto_tipo_desc,
            m.forma_giuridica_cat_id,
            m.forma_giuridica_desc,
            m.forma_giuridica_istat_codice,
            a.soggetto_id,
            f.soggetto_stato_desc,
            h.soggetto_classe_desc,
            b.ente_proprietario_id,
            user_table utente                 
    from 	
            siac_r_soggetto_tipo 	c, 
            siac_d_soggetto_tipo 	d,
            siac_r_soggetto_stato	e,
            siac_d_soggetto_stato	f,
            siac_t_soggetto 		a,
            siac_t_persona_giuridica 	b
            FULL  join siac_r_soggetto_classe	g
            on    	(b.soggetto_id		=	g.soggetto_id
                        and	g.ente_proprietario_id	=	b.ente_proprietario_id
                        and	g.validita_fine	is null)
            FULL  join  siac_d_soggetto_classe	h	
            on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                        and	h.ente_proprietario_id	=	g.ente_proprietario_id
                        and	h.validita_fine	is null)
            FULL  join  siac_r_forma_giuridica	p	
            on    	(b.soggetto_id			=	p.soggetto_id
                        and	p.ente_proprietario_id	=	b.ente_proprietario_id)
            FULL  join  siac_t_forma_giuridica	m	
            on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                        and	p.ente_proprietario_id	=	m.ente_proprietario_id
                        and	p.validita_fine	is null)      
            WHERE	a.ente_proprietario_id	=	p_ente_prop_id
            and		b.ente_proprietario_id	=	a.ente_proprietario_id
            and		c.ente_proprietario_id	=	a.ente_proprietario_id
            and		d.ente_proprietario_id	=	a.ente_proprietario_id
            and		e.ente_proprietario_id	=	a.ente_proprietario_id
            and		f.ente_proprietario_id	=	a.ente_proprietario_id
            and		a.soggetto_id			=	b.soggetto_id
            and		c.soggetto_id			=	b.soggetto_id
            and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
            and		e.soggetto_id			=	b.soggetto_id
            and		e.soggetto_stato_id		=	f.soggetto_stato_id
            and		a.validita_fine			is null
            and		b.validita_fine			is null
            and		e.validita_fine			is null
            and		c.validita_fine			is null
            and		d.validita_fine			is null
            and		e.validita_fine			is null
            and		f.validita_fine			is null;		
ELSE
	if coalesce(p_stato_soggetto ,DEF_NULL)!=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)=DEF_NULL then
              raise notice '2';
        insert into siac_rep_persona_giuridica
        select 	a.ambito_id,
                a.soggetto_code,
                a.codice_fiscale,
                a.codice_fiscale_estero,
                a.partita_iva,
                b.ragione_sociale,
                d.soggetto_tipo_code,
                d.soggetto_tipo_desc,
                m.forma_giuridica_cat_id,
                m.forma_giuridica_desc,
                m.forma_giuridica_istat_codice,
                a.soggetto_id,
                f.soggetto_stato_desc,
                h.soggetto_classe_desc,
                b.ente_proprietario_id,
                user_table utente                 
    from 	
            siac_r_soggetto_tipo 	c, 
            siac_d_soggetto_tipo 	d,
            siac_r_soggetto_stato	e,
            siac_d_soggetto_stato	f,
            siac_t_soggetto 		a,
            siac_t_persona_giuridica 	b
            FULL  join siac_r_soggetto_classe	g
            on    	(b.soggetto_id		=	g.soggetto_id
                        and	g.ente_proprietario_id	=	b.ente_proprietario_id
                        and	g.validita_fine	is null)
            FULL  join  siac_d_soggetto_classe	h	
            on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                        and	h.ente_proprietario_id	=	g.ente_proprietario_id
                        and	h.validita_fine	is null)
            FULL  join  siac_r_forma_giuridica	p	
            on    	(b.soggetto_id			=	p.soggetto_id
                        and	p.ente_proprietario_id	=	b.ente_proprietario_id)
            FULL  join  siac_t_forma_giuridica	m	
            on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                        and	p.ente_proprietario_id	=	m.ente_proprietario_id
                        and	p.validita_fine	is null)      
                WHERE	a.ente_proprietario_id	=	p_ente_prop_id
                and		b.ente_proprietario_id	=	a.ente_proprietario_id
                and		c.ente_proprietario_id	=	a.ente_proprietario_id
                and		d.ente_proprietario_id	=	a.ente_proprietario_id
                and		e.ente_proprietario_id	=	a.ente_proprietario_id
                and		f.ente_proprietario_id	=	a.ente_proprietario_id
                and		a.soggetto_id			=	b.soggetto_id
                and		c.soggetto_id			=	b.soggetto_id
                and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
                and		e.soggetto_id			=	b.soggetto_id
                and		e.soggetto_stato_id		=	f.soggetto_stato_id
               	and		f.soggetto_stato_desc	=	p_stato_soggetto
                and		a.validita_fine			is null
                and		b.validita_fine			is null
                and		e.validita_fine			is null
                and		c.validita_fine			is null
                and		d.validita_fine			is null
                and		e.validita_fine			is null
                and		f.validita_fine			is null;		
     ELSE
     	if coalesce(p_stato_soggetto ,DEF_NULL)=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)!=DEF_NULL then
             raise notice 'classe diversa da null';
            insert into siac_rep_persona_giuridica
	select 		a.ambito_id,
                a.soggetto_code,
                a.codice_fiscale,
                a.codice_fiscale_estero,
                a.partita_iva,
                b.ragione_sociale,
                d.soggetto_tipo_code,
                d.soggetto_tipo_desc,
                m.forma_giuridica_cat_id,
                m.forma_giuridica_desc,
                m.forma_giuridica_istat_codice,
                a.soggetto_id,
                f.soggetto_stato_desc,
                h.soggetto_classe_desc,
                b.ente_proprietario_id,
                user_table utente                
    from 	
            siac_r_soggetto_tipo 	c, 
            siac_d_soggetto_tipo 	d,
            siac_r_soggetto_stato	e,
            siac_d_soggetto_stato	f,
            siac_t_soggetto 		a,
            siac_t_persona_fisica 	b
            FULL  join siac_r_soggetto_classe	g
            on    	(b.soggetto_id		=	g.soggetto_id
                        and	g.ente_proprietario_id	=	b.ente_proprietario_id
                        and	g.validita_fine	is null)
            RIGHT  join  siac_d_soggetto_classe	h	
            on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
            			AND	H.soggetto_classe_desc	=	p_classe_soggetto
                        and	h.ente_proprietario_id	=	g.ente_proprietario_id
                        and	h.validita_fine	is null)
            FULL  join  siac_r_forma_giuridica	p	
            on    	(b.soggetto_id			=	p.soggetto_id
                        and	p.ente_proprietario_id	=	b.ente_proprietario_id)
            FULL  join  siac_t_forma_giuridica	m	
            on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                        and	p.ente_proprietario_id	=	m.ente_proprietario_id
                        and	p.validita_fine	is null)          
            WHERE	a.ente_proprietario_id	=	p_ente_prop_id
            and		b.ente_proprietario_id	=	a.ente_proprietario_id
            and		c.ente_proprietario_id	=	a.ente_proprietario_id
            and		d.ente_proprietario_id	=	a.ente_proprietario_id
            and		e.ente_proprietario_id	=	a.ente_proprietario_id
            and		f.ente_proprietario_id	=	a.ente_proprietario_id
            and		a.soggetto_id			=	b.soggetto_id
            and		c.soggetto_id			=	b.soggetto_id
            and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
            and		e.soggetto_id			=	b.soggetto_id
            and		e.soggetto_stato_id		=	f.soggetto_stato_id
            and		a.validita_fine			is null
            and		b.validita_fine			is null
            and		e.validita_fine			is null
            and		c.validita_fine			is null
            and		d.validita_fine			is null
            and		e.validita_fine			is null
            and		f.validita_fine			is null;		
            		
      else  
      		      raise notice '3';
            insert into siac_rep_persona_giuridica
            select 	a.ambito_id,
                    a.soggetto_code,
                    a.codice_fiscale,
                    a.codice_fiscale_estero,
                    a.partita_iva,
                    b.ragione_sociale,
                    d.soggetto_tipo_code,
                    d.soggetto_tipo_desc,
                    m.forma_giuridica_cat_id,
                    m.forma_giuridica_desc,
                    m.forma_giuridica_istat_codice,
                    a.soggetto_id,
                    f.soggetto_stato_desc,
                    h.soggetto_classe_desc,
                    b.ente_proprietario_id,
                    user_table utente           
            from 	
                    siac_r_soggetto_tipo 	c, 
                    siac_d_soggetto_tipo 	d,
                    siac_r_soggetto_stato	e,
                    siac_d_soggetto_stato	f,
                    siac_t_soggetto 		a,
                    siac_t_persona_fisica 	b
                    FULL  join siac_r_soggetto_classe	g
                    on    	(b.soggetto_id		=	g.soggetto_id
                                and	g.ente_proprietario_id	=	b.ente_proprietario_id
                                and	g.validita_fine	is null)
                    RIGHT  join  siac_d_soggetto_classe	h	
                    on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                    			and	h.soggetto_classe_desc	=	p_classe_soggetto
                                and	h.ente_proprietario_id	=	g.ente_proprietario_id
                                and	h.validita_fine	is null)
                    FULL  join  siac_r_forma_giuridica	p	
                    on    	(b.soggetto_id			=	p.soggetto_id
                                and	p.ente_proprietario_id	=	b.ente_proprietario_id)
                    FULL  join  siac_t_forma_giuridica	m	
                    on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                                and	p.ente_proprietario_id	=	m.ente_proprietario_id
                                and	p.validita_fine	is null)
                    WHERE	a.ente_proprietario_id	=	p_ente_prop_id
                    and		b.ente_proprietario_id	=	a.ente_proprietario_id
                    and		c.ente_proprietario_id	=	a.ente_proprietario_id
                    and		d.ente_proprietario_id	=	a.ente_proprietario_id
                    and		e.ente_proprietario_id	=	a.ente_proprietario_id
                    and		f.ente_proprietario_id	=	a.ente_proprietario_id
                    and		a.soggetto_id			=	b.soggetto_id
                    and		c.soggetto_id			=	b.soggetto_id
                    and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
                    and		e.soggetto_id			=	b.soggetto_id
                    and		e.soggetto_stato_id		=	f.soggetto_stato_id
                    and		f.soggetto_stato_desc	=	p_stato_soggetto
                    and		a.validita_fine			is null
                    and		b.validita_fine			is null
                    and		e.validita_fine			is null
                    and		c.validita_fine			is null
                    and		d.validita_fine			is null
                    and		e.validita_fine			is null
                    and		f.validita_fine			is null;	      
      end if;    
	end if;
end if;



if  p_tipo_estrazione = '1' or p_tipo_estrazione = '3'	THEN
      		      raise notice '4';
      insert into siac_rep_persona_giuridica_recapiti
     select	d.soggetto_id,				
   				c.principale,			
                b1.via_tipo_desc,			
                c.toponimo,					
                c.numero_civico,			
                c.interno,				
                c.frazione,				
                n.comune_desc,				
                q.provincia_desc,			
                q.sigla_automobilistica,		
                r.nazione_desc,		
                c.avviso,			
                d.ente_proprietario_id,
                user_table utente,
                e.indirizzo_tipo_desc,
                c.indirizzo_id	
 from	  siac_t_persona_giuridica d
              full join	siac_t_indirizzo_soggetto c   
                  on (d.soggetto_id	=	c.soggetto_id
                      and	d.validita_fine	is null) 
              full join siac_r_indirizzo_soggetto_tipo	a
              		on (c.indirizzo_id	=	a.indirizzo_id
                    	and	c.ente_proprietario_id	=	a.ente_proprietario_id
                        and	a.validita_fine	is NULL)
              full join siac_d_indirizzo_tipo	e
              		on (e.indirizzo_tipo_id	=	a.indirizzo_tipo_id
                    	and	e.ente_proprietario_id	=	a.ente_proprietario_id
                        and	e.validita_fine	is null)              
              FULL  join siac_d_via_tipo b1
                      on (b1.via_tipo_id	=	c.via_tipo_id
                          and	b1.ente_proprietario_id	=	c.ente_proprietario_id
                          and	b1.validita_fine is null)  
              FULL  join  siac_t_comune	n	
                  on    	(n.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id
                              and	n.validita_fine	is null)
              FULL  join  siac_r_comune_provincia	o	
                  on    	(o.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id
                              and	o.validita_fine	is null)
              FULL  join  siac_t_provincia	q	
                  on    	(q.provincia_id	=	o.provincia_id
                              and	q.ente_proprietario_id	=	o.ente_proprietario_id
                              and	q.validita_fine	is null)
              FULL  join  siac_t_nazione	r	
                  on    	(n.nazione_id	=	r.nazione_id
                              and	r.ente_proprietario_id	=	n.ente_proprietario_id
                              and	r.validita_fine	is null)  
              where 
                      d.ente_proprietario_id 	= p_ente_prop_id
              and		c.ente_proprietario_id 	= 	d.ente_proprietario_id;
end if;  


if  p_tipo_estrazione = '1' or p_tipo_estrazione = '3'	THEN
      		      raise notice '5';
      insert into siac_rep_persona_giuridica_sedi
      select		d.soggetto_id,	
                  ----c.								denominazione,	
                  b1.via_tipo_desc,
                  c.toponimo,
                  c.numero_civico,
                  c.interno,
                  c.frazione,
                  n.comune_desc,
                  q.provincia_desc,
                  q.sigla_automobilistica,
                  r.nazione_desc,
                  '',
                  c.indirizzo_id,
                  d.ente_proprietario_id,
                  user_table utente             
      from 	siac_d_relaz_tipo b, 
              siac_r_soggetto_relaz a  
              RIGHT join	siac_t_persona_fisica d
                  on (		d.soggetto_id	=	a.soggetto_id_da
                      and	d.validita_fine	is null)
              full join siac_t_indirizzo_soggetto c
                  on (a.soggetto_id_a	=	c.soggetto_id	
                      and	c.validita_fine is null) 
              FULL  join siac_d_via_tipo b1
                      on (b1.via_tipo_id	=	c.via_tipo_id
                          and	b1.ente_proprietario_id	=	c.ente_proprietario_id)  
              FULL  join  siac_t_comune	n	
                  on    	(n.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id)
              FULL  join  siac_r_comune_provincia	o	
                  on    	(o.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id)
              FULL  join  siac_t_provincia	q	
                  on    	(q.provincia_id	=	o.provincia_id
                              and	q.ente_proprietario_id	=	o.ente_proprietario_id)
              FULL  join  siac_t_nazione	r	
                  on    	(n.nazione_id	=	r.nazione_id
                              and	r.ente_proprietario_id	=	n.ente_proprietario_id)  
              where a.relaz_tipo_id = b.relaz_tipo_id
              and 	b.relaz_tipo_code ='SEDE_SECONDARIA'
              and 	a.ente_proprietario_id 	= p_ente_prop_id
              and 	b.ente_proprietario_id 	= 	a.ente_proprietario_id
              and	c.ente_proprietario_id 	= 	a.ente_proprietario_id
              and	d.ente_proprietario_id	=	a.ente_proprietario_id;



end if;  
if  p_tipo_estrazione = '1' or p_tipo_estrazione = '4'	THEN
	insert into siac_rep_persona_giuridica_modpag
       select
        	a.soggetto_id,	
    		a.soggetto_desc,
            0,
            ' ',
            ' ',
            ' ',   
            b.modpag_id, 
            b.accredito_tipo_id, 
			c.accredito_tipo_code, 
            c.accredito_tipo_desc, 
            d.modpag_stato_code, 
            d.modpag_stato_desc,
            ' ',
            ' ',
            ' ',
            a.ente_proprietario_id,
            user_table utente,
            a.soggetto_code,
            b.quietanziante,
            b.quietanziante_codice_fiscale,
            b.iban,
            b.bic,
            b.contocorrente,
            b.data_scadenza,
            NULL  
        from 	siac_t_soggetto a,
    			siac_t_modpag b ,
            	siac_d_accredito_tipo c, 
            	siac_d_modpag_stato d, 
				siac_r_modpag_stato e
        where a.ente_proprietario_id = p_ente_prop_id
        and	a.ente_proprietario_id=b.ente_proprietario_id
        and	c.ente_proprietario_id=a.ente_proprietario_id
        and	d.ente_proprietario_id=a.ente_proprietario_id
        and	e.ente_proprietario_id=a.ente_proprietario_id
        and a.soggetto_id = b.soggetto_id
        and b.accredito_tipo_id = c.accredito_tipo_id
        and e.modpag_id = b.modpag_id
        and	e.modpag_stato_id	=	d.modpag_stato_id      
   union  
    select 
           	a.soggetto_id_da,
            d.soggetto_desc,
            a.soggetto_id_a,
            x.soggetto_desc,
            x.codice_fiscale,
            x.partita_iva,
            0,
            a.relaz_tipo_id,
 			c.relaz_tipo_code,
        	c.relaz_tipo_desc,
 			g.relaz_stato_code,
        	g.relaz_stato_desc,
        	b.note,
        	f.accredito_tipo_code,
        	f.accredito_tipo_desc,
        	a.ente_proprietario_id,
            user_table utente,
        	d.soggetto_code,
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            NULL,
            e.data_scadenza
    from 		siac_r_soggetto_relaz a, 
    			siac_r_soggrel_modpag b, 
                siac_d_relaz_tipo c,
  				siac_t_soggetto d, 
                siac_t_modpag e, 
                siac_d_accredito_tipo f,
 				siac_d_relaz_stato g, 
				siac_r_soggetto_relaz_stato h, 
                siac_t_soggetto x
	where 	b.soggetto_relaz_id		= 	a.soggetto_relaz_id
		and a.relaz_tipo_id			= 	c.relaz_tipo_id
		and a.soggetto_id_da 		=	d.soggetto_id
        and	b.modpag_id				=	e.modpag_id
        and	e.accredito_tipo_id		=	f.accredito_tipo_id
        and h.soggetto_relaz_id		=	b.soggetto_relaz_id
        and	h.relaz_stato_id		=	g.relaz_stato_id
        and a.soggetto_id_a			=	x.soggetto_id
        and d.ente_proprietario_id	=	p_ente_prop_id
        and	a.ente_proprietario_id	=	d.ente_proprietario_id
        and b.ente_proprietario_id	=	d.ente_proprietario_id
        and c.ente_proprietario_id	=	d.ente_proprietario_id
        and e.ente_proprietario_id	=	d.ente_proprietario_id
        and f.ente_proprietario_id	=	d.ente_proprietario_id
        and g.ente_proprietario_id	=	d.ente_proprietario_id
        and h.ente_proprietario_id	=	d.ente_proprietario_id;
end if;
if coalesce(p_codice_soggetto ,DEF_NULL)=DEF_NULL	then
for dati_soggetto in 
	select 	a.ambito_id					ambito_id,
    		a.soggetto_code				soggetto_code,
            a.codice_fiscale			codice_fiscale,
            a.codice_fiscale_estero		codice_fiscale_estero, 
            a.partita_iva				partita_iva, 
            a.soggetto_desc				soggetto_desc, 
            a.soggetto_tipo_code		soggetto_tipo_code, 
            a.soggetto_tipo_desc		soggetto_tipo_desc,
            a.forma_giuridica_cat_id	forma_giuridica_cat_id,
            a.forma_giuridica_desc		forma_giuridica_desc,
            a.forma_giuridica_istat_codice	forma_giuridica_istat_codice,
            a.soggetto_id				soggetto_id,
            a.stato						stato,
            a.classe_soggetto			classe_soggetto,
            b.tipo_indirizzo			tipo_indirizzo,		
            coalesce (b.via,DEF_SPACES)						via_indirizzo,
            coalesce (b.toponimo,DEF_SPACES)					toponimo_indirizzo, 
            coalesce (b.numero_civico,DEF_SPACES)				numero_civico_indirizzo,
            coalesce (b.interno,DEF_SPACES)						interno_indirizzo,
            coalesce (b.frazione,DEF_SPACES)					frazione_indirizzo,
            coalesce (b.comune,DEF_SPACES)						comune_indirizzo,
            coalesce (b.provincia_desc_sede,DEF_SPACES)			provincia_indirizzo,
            coalesce (b.provincia_sigla,DEF_SPACES)				provincia_sigla_indirizzo,
            coalesce (b.stato_sede,DEF_SPACES)					stato_indirizzo,
            b.avviso					avviso,
            b.desc_tipo_indirizzo		desc_tipo_indirizzo,
            b.indirizzo_id				indirizzo_id,
            c.indirizzo_id_sede			sede_indirizzo_id,
            coalesce (c.via_sede,DEF_SPACES)					sede_via_indirizzo,
        	coalesce (c.toponimo_sede,DEF_SPACES)				sede_toponimo_indirizzo,					
            coalesce (c.numero_civico_sede,DEF_SPACES)			sede_numero_civico_indirizzo,
            coalesce (c.interno_sede,DEF_SPACES)				sede_interno_indirizzo,
            coalesce (c.frazione_sede,DEF_SPACES)				sede_frazione_indirizzo,
            coalesce (c.comune_sede,DEF_SPACES)					sede_comune_indirizzo,
            coalesce (c.provincia_desc_sede,DEF_SPACES)			sede_provincia_indirizzo,
            coalesce (c.provincia_sigla_sede,DEF_SPACES)		sede_provincia_sigla_indirizzo,
            coalesce (c.stato_sede,DEF_SPACES)					sede_stato_indirizzo,
           	d.soggetto_id				mp_soggetto_id,
            d.soggetto_desc				mp_soggetto_desc,
            d.accredito_tipo_code		mp_accredito_tipo_code,
            d.accredito_tipo_desc		mp_accredito_tipo_desc,
            d.modpag_stato_desc			mp_modpag_stato_desc,
            coalesce (d.soggetto_ricevente_desc,DEF_SPACES)			ricevente,
            coalesce (d.soggetto_ricevente_cod_fis,DEF_SPACES)		ricevente_cod_fis,
            coalesce (d.soggetto_ricevente_piva ,DEF_SPACES)		ricevente_piva,		
            coalesce (d.accredito_ricevente_tipo_code,DEF_SPACES)	accredito_tipo_code,
            coalesce (d.accredito_ricevente_tipo_desc,DEF_SPACES)	accredito_tipo_desc,
          	coalesce (d.note,DEF_SPACES)							note,
            coalesce (d.quietanzante,DEF_SPACES)					quietanzante,
            coalesce (d.quietanzante_codice_fiscale,DEF_SPACES)		quietanzante_cod_fis,
            coalesce (d.bic,DEF_SPACES)								bic,
            coalesce (d.conto_corrente,DEF_SPACES)					conto_corrente,
            coalesce (d.iban,DEF_SPACES)							iban,
            d.mp_data_scadenza										mp_data_scadenza,
            d.data_scadenza_cessione								data_scadenza_cessione				      
    from siac_rep_persona_giuridica	a
    LEFT join	siac_rep_persona_giuridica_recapiti b   
                  on (a.soggetto_id	=	b.soggetto_id
                  and 	a.utente	=	user_table
       				and	b.utente	=	user_table)
    LEFT join	siac_rep_persona_giuridica_sedi c   
    on (a.soggetto_id	=	c.soggetto_id
    and 	a.utente	=	user_table
       and	c.utente	=	user_table)
    LEFT join	siac_rep_persona_giuridica_modpag d   
    on (a.soggetto_code	=	d.soggetto_code
    and 	a.utente	=	user_table
       and	d.utente	=	user_table)
       --SIAC-6215: 12/06/2018: nel caso la denominazione sia NULL
    --	viene trasformata in ''.
        --where a.soggetto_desc	like '%'|| p_denominazione ||'%'
     where a.soggetto_desc	like '%'|| COALESCE(p_denominazione, DEF_NULL) ||'%'        
    loop
        ambito_id:=dati_soggetto.ambito_id;
        soggetto_code:=dati_soggetto.soggetto_code;
        codice_fiscale:=dati_soggetto.codice_fiscale;
        codice_fiscale_estero:=dati_soggetto.codice_fiscale_estero;
        partita_iva:=dati_soggetto.partita_iva;
        soggetto_desc:=dati_soggetto.soggetto_desc;
        soggetto_tipo_code:=dati_soggetto.soggetto_tipo_code;
        soggetto_tipo_desc:=dati_soggetto.soggetto_tipo_desc;
        soggetto_id:=dati_soggetto.soggetto_id;
        stato:=dati_soggetto.stato;
        forma_giuridica_cat_id:=dati_soggetto.forma_giuridica_cat_id;
        forma_giuridica_desc:=dati_soggetto.forma_giuridica_desc;
        forma_giuridica_istat_codice:=dati_soggetto.forma_giuridica_istat_codice;
        classe_soggetto:=dati_soggetto.classe_soggetto;   
        tipo_indirizzo:=dati_soggetto.tipo_indirizzo;
  		via_indirizzo:=dati_soggetto.via_indirizzo;
  		toponimo_indirizzo:=dati_soggetto.toponimo_indirizzo;
  		numero_civico_indirizzo:=dati_soggetto.numero_civico_indirizzo;
  		interno_indirizzo:=dati_soggetto.interno_indirizzo;
  		frazione_indirizzo:=dati_soggetto.frazione_indirizzo;
  		comune_indirizzo:=dati_soggetto.comune_indirizzo;
  		provincia_indirizzo:=dati_soggetto.provincia_indirizzo;
  		provincia_sigla_indirizzo:=dati_soggetto.provincia_sigla_indirizzo;
  		stato_indirizzo:=dati_soggetto.stato_indirizzo;
        avviso:=dati_soggetto.avviso;
        indirizzo_id:=dati_soggetto.indirizzo_id;
        desc_tipo_indirizzo:=dati_soggetto.desc_tipo_indirizzo;
        sede_indirizzo_id:=dati_soggetto.sede_indirizzo_id;
        sede_via_indirizzo:=dati_soggetto.sede_via_indirizzo;
       	sede_toponimo_indirizzo:=dati_soggetto.sede_toponimo_indirizzo;					
        sede_numero_civico_indirizzo:=dati_soggetto.sede_numero_civico_indirizzo;
        sede_interno_indirizzo:=dati_soggetto.sede_interno_indirizzo;
        sede_frazione_indirizzo:=dati_soggetto.sede_frazione_indirizzo;
       	sede_comune_indirizzo:=dati_soggetto.sede_comune_indirizzo;
       	sede_provincia_indirizzo:=dati_soggetto.sede_provincia_indirizzo;
        sede_provincia_sigla_indirizzo:=dati_soggetto.sede_provincia_sigla_indirizzo;
        sede_stato_indirizzo:=dati_soggetto.sede_stato_indirizzo;
         mp_soggetto_id:=dati_soggetto.mp_soggetto_id;
        mp_soggetto_desc:=dati_soggetto.mp_soggetto_desc;
        mp_accredito_tipo_code:=dati_soggetto.mp_accredito_tipo_code;
        mp_accredito_tipo_desc:=dati_soggetto.mp_accredito_tipo_desc;
        mp_modpag_stato_desc:=dati_soggetto.mp_modpag_stato_desc;
        ricevente:=dati_soggetto.ricevente;		
        accredito_tipo_code:=dati_soggetto.accredito_tipo_code;
        accredito_tipo_desc:=dati_soggetto.accredito_tipo_desc;
        note:=dati_soggetto.note;
        ricevente_cod_fis:=dati_soggetto.ricevente_cod_fis;
        ricevente_piva:=dati_soggetto.ricevente_piva;
        quietanzante:=dati_soggetto.quietanzante;
        quietanzante_cod_fis:=dati_soggetto.quietanzante_cod_fis;
        bic:=dati_soggetto.bic;
        conto_corrente:=dati_soggetto.conto_corrente;
        iban:=dati_soggetto.iban;
        mp_data_scadenza:=dati_soggetto.mp_data_scadenza;
        data_scadenza_cessione:=dati_soggetto.data_scadenza_cessione;
        return next;
     end loop;


  raise notice 'fine OK';
else
for dati_soggetto in 
	select 	a.ambito_id					ambito_id,
    		a.soggetto_code				soggetto_code,
            a.codice_fiscale			codice_fiscale,
            a.codice_fiscale_estero		codice_fiscale_estero, 
            a.partita_iva				partita_iva, 
            a.soggetto_desc				soggetto_desc, 
            a.soggetto_tipo_code		soggetto_tipo_code, 
            a.soggetto_tipo_desc		soggetto_tipo_desc,
            a.forma_giuridica_cat_id	forma_giuridica_cat_id,
            a.forma_giuridica_desc		forma_giuridica_desc,
            a.forma_giuridica_istat_codice	forma_giuridica_istat_codice,
            a.soggetto_id				soggetto_id,
            a.stato						stato,
            a.classe_soggetto			classe_soggetto,
            b.tipo_indirizzo			tipo_indirizzo,		
            coalesce (b.via,DEF_SPACES)						via_indirizzo,
            coalesce (b.toponimo,DEF_SPACES)					toponimo_indirizzo, 
            coalesce (b.numero_civico,DEF_SPACES)				numero_civico_indirizzo,
            coalesce (b.interno,DEF_SPACES)						interno_indirizzo,
            coalesce (b.frazione,DEF_SPACES)					frazione_indirizzo,
            coalesce (b.comune,DEF_SPACES)						comune_indirizzo,
            coalesce (b.provincia_desc_sede,DEF_SPACES)			provincia_indirizzo,
            coalesce (b.provincia_sigla,DEF_SPACES)				provincia_sigla_indirizzo,
            coalesce (b.stato_sede,DEF_SPACES)					stato_indirizzo,
            b.avviso					avviso,
            b.desc_tipo_indirizzo		desc_tipo_indirizzo,
            b.indirizzo_id				indirizzo_id,
            c.indirizzo_id_sede			sede_indirizzo_id,
            coalesce (c.via_sede,DEF_SPACES)					sede_via_indirizzo,
        	coalesce (c.toponimo_sede,DEF_SPACES)				sede_toponimo_indirizzo,					
            coalesce (c.numero_civico_sede,DEF_SPACES)			sede_numero_civico_indirizzo,
            coalesce (c.interno_sede,DEF_SPACES)				sede_interno_indirizzo,
            coalesce (c.frazione_sede,DEF_SPACES)				sede_frazione_indirizzo,
            coalesce (c.comune_sede,DEF_SPACES)					sede_comune_indirizzo,
            coalesce (c.provincia_desc_sede,DEF_SPACES)			sede_provincia_indirizzo,
            coalesce (c.provincia_sigla_sede,DEF_SPACES)		sede_provincia_sigla_indirizzo,
            coalesce (c.stato_sede,DEF_SPACES)					sede_stato_indirizzo,
           	d.soggetto_id				mp_soggetto_id,
            d.soggetto_desc				mp_soggetto_desc,
            d.accredito_tipo_code		mp_accredito_tipo_code,
            d.accredito_tipo_desc		mp_accredito_tipo_desc,
            d.modpag_stato_desc			mp_modpag_stato_desc,
            coalesce (d.soggetto_ricevente_desc,DEF_SPACES)			ricevente,
            coalesce (d.soggetto_ricevente_cod_fis,DEF_SPACES)		ricevente_cod_fis,
            coalesce (d.soggetto_ricevente_piva ,DEF_SPACES)		ricevente_piva,		
            coalesce (d.accredito_ricevente_tipo_code,DEF_SPACES)	accredito_tipo_code,
            coalesce (d.accredito_ricevente_tipo_desc,DEF_SPACES)	accredito_tipo_desc,
          	coalesce (d.note,DEF_SPACES)							note,
            coalesce (d.quietanzante,DEF_SPACES)					quietanzante,
            coalesce (d.quietanzante_codice_fiscale,DEF_SPACES)		quietanzante_cod_fis,
            coalesce (d.bic,DEF_SPACES)								bic,
            coalesce (d.conto_corrente,DEF_SPACES)					conto_corrente,
            coalesce (d.iban,DEF_SPACES)							iban,
            d.mp_data_scadenza										mp_data_scadenza,
            d.data_scadenza_cessione								data_scadenza_cessione				      
    from siac_rep_persona_giuridica	a
    LEFT join	siac_rep_persona_giuridica_recapiti b   
                  on (a.soggetto_id	=	b.soggetto_id
                  and 	a.utente	=	user_table
       				and	b.utente	=	user_table)
    LEFT join	siac_rep_persona_giuridica_sedi c   
    on (a.soggetto_id	=	c.soggetto_id
    and 	a.utente	=	user_table
       and	c.utente	=	user_table)
    LEFT join	siac_rep_persona_giuridica_modpag d   
    on (a.soggetto_code	=	d.soggetto_code
    and 	a.utente	=	user_table
       and	d.utente	=	user_table)
        where a.soggetto_code	=	p_codice_soggetto
    loop
        ambito_id:=dati_soggetto.ambito_id;
        soggetto_code:=dati_soggetto.soggetto_code;
        codice_fiscale:=dati_soggetto.codice_fiscale;
        codice_fiscale_estero:=dati_soggetto.codice_fiscale_estero;
        partita_iva:=dati_soggetto.partita_iva;
        soggetto_desc:=dati_soggetto.soggetto_desc;
        soggetto_tipo_code:=dati_soggetto.soggetto_tipo_code;
        soggetto_tipo_desc:=dati_soggetto.soggetto_tipo_desc;
        soggetto_id:=dati_soggetto.soggetto_id;
        stato:=dati_soggetto.stato;
        forma_giuridica_cat_id:=dati_soggetto.forma_giuridica_cat_id;
        forma_giuridica_desc:=dati_soggetto.forma_giuridica_desc;
        forma_giuridica_istat_codice:=dati_soggetto.forma_giuridica_istat_codice;
        classe_soggetto:=dati_soggetto.classe_soggetto;   
        tipo_indirizzo:=dati_soggetto.tipo_indirizzo;
  		via_indirizzo:=dati_soggetto.via_indirizzo;
  		toponimo_indirizzo:=dati_soggetto.toponimo_indirizzo;
  		numero_civico_indirizzo:=dati_soggetto.numero_civico_indirizzo;
  		interno_indirizzo:=dati_soggetto.interno_indirizzo;
  		frazione_indirizzo:=dati_soggetto.frazione_indirizzo;
  		comune_indirizzo:=dati_soggetto.comune_indirizzo;
  		provincia_indirizzo:=dati_soggetto.provincia_indirizzo;
  		provincia_sigla_indirizzo:=dati_soggetto.provincia_sigla_indirizzo;
  		stato_indirizzo:=dati_soggetto.stato_indirizzo;
        avviso:=dati_soggetto.avviso;
        indirizzo_id:=dati_soggetto.indirizzo_id;
        desc_tipo_indirizzo:=dati_soggetto.desc_tipo_indirizzo;
        sede_indirizzo_id:=dati_soggetto.sede_indirizzo_id;
        sede_via_indirizzo:=dati_soggetto.sede_via_indirizzo;
       	sede_toponimo_indirizzo:=dati_soggetto.sede_toponimo_indirizzo;					
        sede_numero_civico_indirizzo:=dati_soggetto.sede_numero_civico_indirizzo;
        sede_interno_indirizzo:=dati_soggetto.sede_interno_indirizzo;
        sede_frazione_indirizzo:=dati_soggetto.sede_frazione_indirizzo;
       	sede_comune_indirizzo:=dati_soggetto.sede_comune_indirizzo;
       	sede_provincia_indirizzo:=dati_soggetto.sede_provincia_indirizzo;
        sede_provincia_sigla_indirizzo:=dati_soggetto.sede_provincia_sigla_indirizzo;
        sede_stato_indirizzo:=dati_soggetto.sede_stato_indirizzo;
         mp_soggetto_id:=dati_soggetto.mp_soggetto_id;
        mp_soggetto_desc:=dati_soggetto.mp_soggetto_desc;
        mp_accredito_tipo_code:=dati_soggetto.mp_accredito_tipo_code;
        mp_accredito_tipo_desc:=dati_soggetto.mp_accredito_tipo_desc;
        mp_modpag_stato_desc:=dati_soggetto.mp_modpag_stato_desc;
        ricevente:=dati_soggetto.ricevente;		
        accredito_tipo_code:=dati_soggetto.accredito_tipo_code;
        accredito_tipo_desc:=dati_soggetto.accredito_tipo_desc;
        note:=dati_soggetto.note;
        ricevente_cod_fis:=dati_soggetto.ricevente_cod_fis;
        ricevente_piva:=dati_soggetto.ricevente_piva;
        quietanzante:=dati_soggetto.quietanzante;
        quietanzante_cod_fis:=dati_soggetto.quietanzante_cod_fis;
        bic:=dati_soggetto.bic;
        conto_corrente:=dati_soggetto.conto_corrente;
        iban:=dati_soggetto.iban;
        mp_data_scadenza:=dati_soggetto.mp_data_scadenza;
        data_scadenza_cessione:=dati_soggetto.data_scadenza_cessione;
        return next;
        ambito_id=0;
        soggetto_code='';
        codice_fiscale='';
     	codice_fiscale_estero='';
        partita_iva='';
        soggetto_desc='';
        soggetto_tipo_code='';
        soggetto_tipo_desc='';
        soggetto_id=0;
        stato='';
        forma_giuridica_cat_id=0;
        forma_giuridica_desc='';
        forma_giuridica_istat_codice='';
        classe_soggetto='';
        tipo_indirizzo='';
  		via_indirizzo='';
  		toponimo_indirizzo='';
  		numero_civico_indirizzo='';
  		interno_indirizzo='';
  		frazione_indirizzo='';
  		comune_indirizzo='';
  		provincia_indirizzo='';
  		provincia_sigla_indirizzo='';
  		stato_indirizzo='';
        avviso='';
       indirizzo_id=0;
        desc_tipo_indirizzo='';
        sede_indirizzo_id=0;
        sede_via_indirizzo='';
       	sede_toponimo_indirizzo='';
        sede_numero_civico_indirizzo='';
        sede_interno_indirizzo='';
        sede_frazione_indirizzo='';
       	sede_comune_indirizzo='';
       	sede_provincia_indirizzo='';
        sede_provincia_sigla_indirizzo='';
        sede_stato_indirizzo='';
        mp_soggetto_id=0;
        mp_soggetto_desc='';
        mp_accredito_tipo_code='';
        mp_accredito_tipo_desc='';
        mp_modpag_stato_desc='';
        ricevente='';
        accredito_tipo_code='';
        accredito_tipo_desc='';
       	note='';
        ricevente_cod_fis='';
        ricevente_piva='';
        quietanzante='';
        quietanzante_cod_fis='';
        bic='';
        conto_corrente='';
        iban='';
        mp_data_scadenza=NULL;
        data_scadenza_cessione=NULL;
     end loop;


  raise notice 'fine OK';
end if;    
delete from siac_rep_persona_giuridica where utente=user_table;
delete from siac_rep_persona_giuridica_recapiti where utente=user_table;
delete from siac_rep_persona_giuridica_sedi where utente=user_table;	
delete from siac_rep_persona_giuridica_modpag where utente=user_table;	

EXCEPTION
when no_data_found THEN
	raise notice 'nessun soggetto  trovato';
	return;
when others  THEN
 RTN_MESSAGGIO:='Ricerca dati soggetto';
 RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR029_soggetti_persona_fisica" (
  p_ente_prop_id integer,
  p_codice_soggetto varchar = NULL::character varying,
  p_denominazione varchar = NULL::character varying,
  p_stato_soggetto varchar = NULL::character varying,
  p_classe_soggetto varchar = NULL::character varying,
  p_tipo_estrazione varchar = NULL::character varying
)
RETURNS TABLE (
  ambito_id integer,
  soggetto_code varchar,
  codice_fiscale varchar,
  codice_fiscale_estero varchar,
  partita_iva varchar,
  soggetto_desc varchar,
  soggetto_tipo_code varchar,
  soggetto_tipo_desc varchar,
  forma_giuridica_cat_id varchar,
  forma_giuridica_desc varchar,
  forma_giuridica_istat_codice varchar,
  cognome varchar,
  nome varchar,
  comune_id_nascita integer,
  nascita_data date,
  sesso varchar,
  comune_desc varchar,
  comune_istat_code varchar,
  provincia_desc varchar,
  sigla_automobilistica varchar,
  nazione_desc varchar,
  soggetto_id integer,
  stato varchar,
  classe_soggetto varchar,
  desc_tipo_indirizzo varchar,
  tipo_indirizzo varchar,
  via_indirizzo varchar,
  toponimo_indirizzo varchar,
  numero_civico_indirizzo varchar,
  interno_indirizzo varchar,
  frazione_indirizzo varchar,
  comune_indirizzo varchar,
  provincia_indirizzo varchar,
  provincia_sigla_indirizzo varchar,
  stato_indirizzo varchar,
  indirizzo_id integer,
  avviso varchar,
  sede_indirizzo_id integer,
  sede_via_indirizzo varchar,
  sede_toponimo_indirizzo varchar,
  sede_numero_civico_indirizzo varchar,
  sede_interno_indirizzo varchar,
  sede_frazione_indirizzo varchar,
  sede_comune_indirizzo varchar,
  sede_provincia_indirizzo varchar,
  sede_provincia_sigla_indirizzo varchar,
  sede_stato_indirizzo varchar,
  mp_soggetto_id integer,
  mp_soggetto_desc varchar,
  mp_accredito_tipo_code varchar,
  mp_accredito_tipo_desc varchar,
  mp_modpag_stato_desc varchar,
  ricevente varchar,
  accredito_tipo_code varchar,
  accredito_tipo_desc varchar,
  note varchar,
  ricevente_cod_fis varchar,
  ricevente_piva varchar,
  quietanzante varchar,
  quietanzante_cod_fis varchar,
  bic varchar,
  conto_corrente varchar,
  iban varchar,
  mp_data_scadenza date,
  data_scadenza_cessione date
) AS
$body$
DECLARE
	dati_soggetto record;
    DEF_NULL	constant varchar:=''; 
    DEF_SPACES	constant varchar:=' '; 
    RTN_MESSAGGIO varchar(1000):=DEF_NULL;
    user_table	varchar;

    
  
  BEGIN
  

  
select fnc_siac_random_user()
into	user_table;


if coalesce(p_stato_soggetto ,DEF_NULL)=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)=DEF_NULL then
      raise notice '1';
    insert into siac_rep_persona_fisica
	select 	a.ambito_id,
            a.soggetto_code,
            a.codice_fiscale,
            a.codice_fiscale_estero,
            a.partita_iva,
            a.soggetto_desc,
            d.soggetto_tipo_code,
            d.soggetto_tipo_desc,
            m.forma_giuridica_cat_id,
            m.forma_giuridica_desc,
            m.forma_giuridica_istat_codice,
            b.cognome,
            b.nome,
            b.comune_id_nascita,
            b.nascita_data,
            b.sesso,
            n.comune_desc,
            n.comune_istat_code,
            q.provincia_desc,
            q.sigla_automobilistica,
            r.nazione_desc,
            a.soggetto_id,
            f.soggetto_stato_desc,
            h.soggetto_classe_desc,
            b.ente_proprietario_id,
            user_table utente                 
    from 	
            siac_r_soggetto_tipo 	c, 
            siac_d_soggetto_tipo 	d,
            siac_r_soggetto_stato	e,
            siac_d_soggetto_stato	f,
            siac_t_soggetto 		a,
            siac_t_persona_fisica 	b
            FULL  join siac_r_soggetto_classe	g
            on    	(b.soggetto_id		=	g.soggetto_id
                        and	g.ente_proprietario_id	=	b.ente_proprietario_id
                        and	g.validita_fine	is null)
            FULL  join  siac_d_soggetto_classe	h	
            on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                        and	h.ente_proprietario_id	=	g.ente_proprietario_id
                        and	h.validita_fine	is null)
            FULL  join  siac_r_forma_giuridica	p	
            on    	(b.soggetto_id			=	p.soggetto_id
                        and	p.ente_proprietario_id	=	b.ente_proprietario_id)
            FULL  join  siac_t_forma_giuridica	m	
            on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                        and	p.ente_proprietario_id	=	m.ente_proprietario_id
                        and	p.validita_fine	is null)
            FULL  join  siac_t_comune	n	
            on    	(n.comune_id	=	b.comune_id_nascita
                        and	n.ente_proprietario_id	=	b.ente_proprietario_id
                        and	n.validita_fine	is null)
            FULL  join  siac_r_comune_provincia	o	
            on    	(o.comune_id	=	b.comune_id_nascita
                        and	n.ente_proprietario_id	=	b.ente_proprietario_id
                        and	o.validita_fine	is null)
            FULL  join  siac_t_provincia	q	
            on    	(q.provincia_id	=	o.provincia_id
                        and	q.ente_proprietario_id	=	o.ente_proprietario_id
                        and	q.validita_fine	is null)
            FULL  join  siac_t_nazione	r	
            on    	(n.nazione_id	=	r.nazione_id
                        and	r.ente_proprietario_id	=	n.ente_proprietario_id
                        and	r.validita_fine	is null)           
            WHERE	a.ente_proprietario_id	=	p_ente_prop_id
            and		b.ente_proprietario_id	=	a.ente_proprietario_id
            and		c.ente_proprietario_id	=	a.ente_proprietario_id
            and		d.ente_proprietario_id	=	a.ente_proprietario_id
            and		e.ente_proprietario_id	=	a.ente_proprietario_id
            and		f.ente_proprietario_id	=	a.ente_proprietario_id
            and		a.soggetto_id			=	b.soggetto_id
            and		c.soggetto_id			=	b.soggetto_id
            and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
            and		e.soggetto_id			=	b.soggetto_id
            and		e.soggetto_stato_id		=	f.soggetto_stato_id
            and		a.validita_fine			is null
            and		b.validita_fine			is null
            and		e.validita_fine			is null
            and		c.validita_fine			is null
            and		d.validita_fine			is null
            and		e.validita_fine			is null
            and		f.validita_fine			is null;		
ELSE
	if coalesce(p_stato_soggetto ,DEF_NULL)!=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)=DEF_NULL then
              raise notice '2';
        insert into siac_rep_persona_fisica
        select 	a.ambito_id					ambito_id,
                a.soggetto_code				soggetto_code,
                a.codice_fiscale			codice_fiscale,
                a.codice_fiscale_estero		codice_fiscale_estero, 
                a.partita_iva				partita_iva, 
                a.soggetto_desc				soggetto_desc, 
                d.soggetto_tipo_code		soggetto_tipo_code, 
                d.soggetto_tipo_desc		soggetto_tipo_desc,
                m.forma_giuridica_cat_id	forma_giuridica_cat_id,
                m.forma_giuridica_desc		forma_giuridica_desc,
                m.forma_giuridica_istat_codice	forma_giuridica_istat_codice,
                b.cognome					cognome,
                b.nome						nome,  
                b.comune_id_nascita			comune_id_nascita, 
                b.nascita_data				nascita_data,
                b.sesso						sesso,
                n.comune_desc 				comune_desc,
                n.comune_istat_code 		comune_istat_code,
                q.provincia_desc			provincia_desc,
                q.sigla_automobilistica		sigla_automobilistica,
                r.nazione_desc				nazione_desc, 
                a.soggetto_id				soggetto_id,
                f.soggetto_stato_desc		stato,
                h.soggetto_classe_desc		classe_soggetto,
                b.ente_proprietario_id,
                user_table utente             
        from 	
                siac_r_soggetto_tipo 	c, 
                siac_d_soggetto_tipo 	d,
                siac_r_soggetto_stato	e,
                siac_d_soggetto_stato	f,
                siac_t_soggetto 		a,
                siac_t_persona_fisica 	b
                FULL  join siac_r_soggetto_classe	g
                on    	(b.soggetto_id		=	g.soggetto_id
                            and	g.ente_proprietario_id	=	b.ente_proprietario_id
                            and	g.validita_fine	is null)
                FULL  join  siac_d_soggetto_classe	h	
                on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                            and	h.ente_proprietario_id	=	g.ente_proprietario_id
                            and	h.validita_fine	is null)
                FULL  join  siac_r_forma_giuridica	p	
                on    	(b.soggetto_id			=	p.soggetto_id
                            and	p.ente_proprietario_id	=	b.ente_proprietario_id)
                FULL  join  siac_t_forma_giuridica	m	
                on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                            and	p.ente_proprietario_id	=	m.ente_proprietario_id
                            and	p.validita_fine	is null)
                FULL  join  siac_t_comune	n	
                on    	(n.comune_id	=	b.comune_id_nascita
                            and	n.ente_proprietario_id	=	b.ente_proprietario_id
                            and	n.validita_fine	is null)
                FULL  join  siac_r_comune_provincia	o	
                on    	(o.comune_id	=	b.comune_id_nascita
                            and	n.ente_proprietario_id	=	b.ente_proprietario_id
                            and	o.validita_fine	is null)
                FULL  join  siac_t_provincia	q	
                on    	(q.provincia_id	=	o.provincia_id
                            and	q.ente_proprietario_id	=	o.ente_proprietario_id
                            and	q.validita_fine	is null)
                FULL  join  siac_t_nazione	r	
                on    	(n.nazione_id	=	r.nazione_id
                            and	r.ente_proprietario_id	=	n.ente_proprietario_id
                            and	r.validita_fine	is null)           
                WHERE	a.ente_proprietario_id	=	p_ente_prop_id
                and		b.ente_proprietario_id	=	a.ente_proprietario_id
                and		c.ente_proprietario_id	=	a.ente_proprietario_id
                and		d.ente_proprietario_id	=	a.ente_proprietario_id
                and		e.ente_proprietario_id	=	a.ente_proprietario_id
                and		f.ente_proprietario_id	=	a.ente_proprietario_id
                and		a.soggetto_id			=	b.soggetto_id
                and		c.soggetto_id			=	b.soggetto_id
                and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
                and		e.soggetto_id			=	b.soggetto_id
                and		e.soggetto_stato_id		=	f.soggetto_stato_id
               	and		f.soggetto_stato_desc	=	p_stato_soggetto
                and		a.validita_fine			is null
                and		b.validita_fine			is null
                and		e.validita_fine			is null
                and		c.validita_fine			is null
                and		d.validita_fine			is null
                and		e.validita_fine			is null
                and		f.validita_fine			is null;		
     ELSE
     	if coalesce(p_stato_soggetto ,DEF_NULL)=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)!=DEF_NULL then
             raise notice 'classe diversa da null';
            insert into siac_rep_persona_fisica
select 	a.ambito_id,
            a.soggetto_code,
            a.codice_fiscale,
            a.codice_fiscale_estero,
            a.partita_iva,
            a.soggetto_desc,
            d.soggetto_tipo_code,
            d.soggetto_tipo_desc,
            m.forma_giuridica_cat_id,
            m.forma_giuridica_desc,
            m.forma_giuridica_istat_codice,
            b.cognome,
            b.nome,
            b.comune_id_nascita,
            b.nascita_data,
            b.sesso,
            n.comune_desc,
            n.comune_istat_code,
            q.provincia_desc,
            q.sigla_automobilistica,
            r.nazione_desc,
            a.soggetto_id,
            f.soggetto_stato_desc,
            h.soggetto_classe_desc,
            b.ente_proprietario_id,
            user_table utente                 
    from 	
            siac_r_soggetto_tipo 	c, 
            siac_d_soggetto_tipo 	d,
            siac_r_soggetto_stato	e,
            siac_d_soggetto_stato	f,
            siac_t_soggetto 		a,
            siac_t_persona_fisica 	b
            FULL  join siac_r_soggetto_classe	g
            on    	(b.soggetto_id		=	g.soggetto_id
                        and	g.ente_proprietario_id	=	b.ente_proprietario_id
                        and	g.validita_fine	is null)
            RIGHT  join  siac_d_soggetto_classe	h	
            on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
            			AND	H.soggetto_classe_desc	=	p_classe_soggetto
                        and	h.ente_proprietario_id	=	g.ente_proprietario_id
                        and	h.validita_fine	is null)
            FULL  join  siac_r_forma_giuridica	p	
            on    	(b.soggetto_id			=	p.soggetto_id
                        and	p.ente_proprietario_id	=	b.ente_proprietario_id)
            FULL  join  siac_t_forma_giuridica	m	
            on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                        and	p.ente_proprietario_id	=	m.ente_proprietario_id
                        and	p.validita_fine	is null)
            FULL  join  siac_t_comune	n	
            on    	(n.comune_id	=	b.comune_id_nascita
                        and	n.ente_proprietario_id	=	b.ente_proprietario_id
                        and	n.validita_fine	is null)
            FULL  join  siac_r_comune_provincia	o	
            on    	(o.comune_id	=	b.comune_id_nascita
                        and	n.ente_proprietario_id	=	b.ente_proprietario_id
                        and	o.validita_fine	is null)
            FULL  join  siac_t_provincia	q	
            on    	(q.provincia_id	=	o.provincia_id
                        and	q.ente_proprietario_id	=	o.ente_proprietario_id
                        and	q.validita_fine	is null)
            FULL  join  siac_t_nazione	r	
            on    	(n.nazione_id	=	r.nazione_id
                        and	r.ente_proprietario_id	=	n.ente_proprietario_id
                        and	r.validita_fine	is null)           
            WHERE	a.ente_proprietario_id	=	p_ente_prop_id
            and		b.ente_proprietario_id	=	a.ente_proprietario_id
            and		c.ente_proprietario_id	=	a.ente_proprietario_id
            and		d.ente_proprietario_id	=	a.ente_proprietario_id
            and		e.ente_proprietario_id	=	a.ente_proprietario_id
            and		f.ente_proprietario_id	=	a.ente_proprietario_id
            and		a.soggetto_id			=	b.soggetto_id
            and		c.soggetto_id			=	b.soggetto_id
            and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
            and		e.soggetto_id			=	b.soggetto_id
            and		e.soggetto_stato_id		=	f.soggetto_stato_id
            and		a.validita_fine			is null
            and		b.validita_fine			is null
            and		e.validita_fine			is null
            and		c.validita_fine			is null
            and		d.validita_fine			is null
            and		e.validita_fine			is null
            and		f.validita_fine			is null;		
            		
      else  
      		      raise notice '3';
            insert into siac_rep_persona_fisica
            select 	a.ambito_id					ambito_id,
                    a.soggetto_code				soggetto_code,
                    a.codice_fiscale			codice_fiscale,
                    a.codice_fiscale_estero		codice_fiscale_estero, 
                    a.partita_iva				partita_iva, 
                    a.soggetto_desc				soggetto_desc, 
                    d.soggetto_tipo_code		soggetto_tipo_code, 
                    d.soggetto_tipo_desc		soggetto_tipo_desc,
                    m.forma_giuridica_cat_id	forma_giuridica_cat_id,
                    m.forma_giuridica_desc		forma_giuridica_desc,
                    m.forma_giuridica_istat_codice	forma_giuridica_istat_codice,
                    b.cognome					cognome,
                    b.nome						nome,  
                    b.comune_id_nascita			comune_id_nascita, 
                    b.nascita_data				nascita_data,
                    b.sesso						sesso,
                    n.comune_desc 				comune_desc,
                    n.comune_istat_code 		comune_istat_code,
                    q.provincia_desc			provincia_desc,
                    q.sigla_automobilistica		sigla_automobilistica,
                    r.nazione_desc				nazione_desc, 
                    a.soggetto_id				soggetto_id,
                    f.soggetto_stato_desc		stato,
                    h.soggetto_classe_desc		classe_soggetto,
                    b.ente_proprietario_id,
                    user_table utente             
            from 	
                    siac_r_soggetto_tipo 	c, 
                    siac_d_soggetto_tipo 	d,
                    siac_r_soggetto_stato	e,
                    siac_d_soggetto_stato	f,
                    siac_t_soggetto 		a,
                    siac_t_persona_fisica 	b
                    FULL  join siac_r_soggetto_classe	g
                    on    	(b.soggetto_id		=	g.soggetto_id
                                and	g.ente_proprietario_id	=	b.ente_proprietario_id
                                and	g.validita_fine	is null)
                    RIGHT  join  siac_d_soggetto_classe	h	
                    on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                    			and	h.soggetto_classe_desc	=	p_classe_soggetto
                                and	h.ente_proprietario_id	=	g.ente_proprietario_id
                                and	h.validita_fine	is null)
                    FULL  join  siac_r_forma_giuridica	p	
                    on    	(b.soggetto_id			=	p.soggetto_id
                                and	p.ente_proprietario_id	=	b.ente_proprietario_id)
                    FULL  join  siac_t_forma_giuridica	m	
                    on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                                and	p.ente_proprietario_id	=	m.ente_proprietario_id
                                and	p.validita_fine	is null)
                    FULL  join  siac_t_comune	n	
                    on    	(n.comune_id	=	b.comune_id_nascita
                                and	n.ente_proprietario_id	=	b.ente_proprietario_id
                                and	n.validita_fine	is null)
                    FULL  join  siac_r_comune_provincia	o	
                    on    	(o.comune_id	=	b.comune_id_nascita
                                and	n.ente_proprietario_id	=	b.ente_proprietario_id
                                and	o.validita_fine	is null)
                    FULL  join  siac_t_provincia	q	
                    on    	(q.provincia_id	=	o.provincia_id
                                and	q.ente_proprietario_id	=	o.ente_proprietario_id
                                and	q.validita_fine	is null)
                    FULL  join  siac_t_nazione	r	
                    on    	(n.nazione_id	=	r.nazione_id
                                and	r.ente_proprietario_id	=	n.ente_proprietario_id
                                and	r.validita_fine	is null)           
                    WHERE	a.ente_proprietario_id	=	p_ente_prop_id
                    and		b.ente_proprietario_id	=	a.ente_proprietario_id
                    and		c.ente_proprietario_id	=	a.ente_proprietario_id
                    and		d.ente_proprietario_id	=	a.ente_proprietario_id
                    and		e.ente_proprietario_id	=	a.ente_proprietario_id
                    and		f.ente_proprietario_id	=	a.ente_proprietario_id
                    and		a.soggetto_id			=	b.soggetto_id
                    and		c.soggetto_id			=	b.soggetto_id
                    and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
                    and		e.soggetto_id			=	b.soggetto_id
                    and		e.soggetto_stato_id		=	f.soggetto_stato_id
                    and		f.soggetto_stato_desc	=	p_stato_soggetto
                    and		a.validita_fine			is null
                    and		b.validita_fine			is null
                    and		e.validita_fine			is null
                    and		c.validita_fine			is null
                    and		d.validita_fine			is null
                    and		e.validita_fine			is null
                    and		f.validita_fine			is null;	      
      end if;    
	end if;
end if;



if  p_tipo_estrazione = '1' or p_tipo_estrazione = '3'	THEN
      		      raise notice '4';
      insert into siac_rep_persona_fisica_recapiti
     select	d.soggetto_id,				
   				c.principale,			
                b1.via_tipo_desc,			
                c.toponimo,					
                c.numero_civico,			
                c.interno,				
                c.frazione,				
                n.comune_desc,				
                q.provincia_desc,			
                q.sigla_automobilistica,		
                r.nazione_desc,		
                c.avviso,			
                d.ente_proprietario_id,
                user_table utente,
                e.indirizzo_tipo_desc,
                c.indirizzo_id	
 from	  siac_t_persona_fisica d
              full join	siac_t_indirizzo_soggetto c   
                  on (d.soggetto_id	=	c.soggetto_id
                      and	d.validita_fine	is null) 
              full join siac_r_indirizzo_soggetto_tipo	a
              		on (c.indirizzo_id	=	a.indirizzo_id
                    	and	c.ente_proprietario_id	=	a.ente_proprietario_id
                        and	a.validita_fine	is NULL)
              full join siac_d_indirizzo_tipo	e
              		on (e.indirizzo_tipo_id	=	a.indirizzo_tipo_id
                    	and	e.ente_proprietario_id	=	a.ente_proprietario_id
                        and	e.validita_fine	is null)              
              FULL  join siac_d_via_tipo b1
                      on (b1.via_tipo_id	=	c.via_tipo_id
                          and	b1.ente_proprietario_id	=	c.ente_proprietario_id
                          and	b1.validita_fine is null)  
              FULL  join  siac_t_comune	n	
                  on    	(n.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id
                              and	n.validita_fine	is null)
              FULL  join  siac_r_comune_provincia	o	
                  on    	(o.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id
                              and	o.validita_fine	is null)
              FULL  join  siac_t_provincia	q	
                  on    	(q.provincia_id	=	o.provincia_id
                              and	q.ente_proprietario_id	=	o.ente_proprietario_id
                              and	q.validita_fine	is null)
              FULL  join  siac_t_nazione	r	
                  on    	(n.nazione_id	=	r.nazione_id
                              and	r.ente_proprietario_id	=	n.ente_proprietario_id
                              and	r.validita_fine	is null)  
              where 
                      d.ente_proprietario_id 	= p_ente_prop_id
              and		c.ente_proprietario_id 	= 	d.ente_proprietario_id;
end if;  


if  p_tipo_estrazione = '1' or p_tipo_estrazione = '3'	THEN
      		      raise notice '5';
      insert into siac_rep_persona_fisica_sedi
      select		d.soggetto_id,	
                  ----c.								denominazione,	
                  b1.via_tipo_desc,
                  c.toponimo,
                  c.numero_civico,
                  c.interno,
                  c.frazione,
                  n.comune_desc,
                  q.provincia_desc,
                  q.sigla_automobilistica,
                  r.nazione_desc,
                  '',
                  c.indirizzo_id,
                  d.ente_proprietario_id,
                  user_table utente             
      from 	siac_d_relaz_tipo b, 
              siac_r_soggetto_relaz a  
              RIGHT join	siac_t_persona_fisica d
                  on (		d.soggetto_id	=	a.soggetto_id_da
                      and	d.validita_fine	is null)
              full join siac_t_indirizzo_soggetto c
                  on (a.soggetto_id_a	=	c.soggetto_id	
                      and	c.validita_fine is null) 
              FULL  join siac_d_via_tipo b1
                      on (b1.via_tipo_id	=	c.via_tipo_id
                          and	b1.ente_proprietario_id	=	c.ente_proprietario_id)  
              FULL  join  siac_t_comune	n	
                  on    	(n.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id)
              FULL  join  siac_r_comune_provincia	o	
                  on    	(o.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id)
              FULL  join  siac_t_provincia	q	
                  on    	(q.provincia_id	=	o.provincia_id
                              and	q.ente_proprietario_id	=	o.ente_proprietario_id)
              FULL  join  siac_t_nazione	r	
                  on    	(n.nazione_id	=	r.nazione_id
                              and	r.ente_proprietario_id	=	n.ente_proprietario_id)  
              where a.relaz_tipo_id = b.relaz_tipo_id
              and 	b.relaz_tipo_code ='SEDE_SECONDARIA'
              and 	a.ente_proprietario_id 	= p_ente_prop_id
              and 	b.ente_proprietario_id 	= 	a.ente_proprietario_id
              and	c.ente_proprietario_id 	= 	a.ente_proprietario_id
              and	d.ente_proprietario_id	=	a.ente_proprietario_id;



end if;  
if  p_tipo_estrazione = '1' or p_tipo_estrazione = '4'	THEN
  raise notice 'siac_rep_persona_fisica_modpag';
	insert into siac_rep_persona_fisica_modpag
    select
        	a.soggetto_id,	
    		a.soggetto_desc,
            0,
            ' ',
            ' ',
            ' ',   
            b.modpag_id, 
            b.accredito_tipo_id, 
			c.accredito_tipo_code, 
            c.accredito_tipo_desc, 
            d.modpag_stato_code, 
            d.modpag_stato_desc,
            ' ',
            ' ',
            ' ',
            a.ente_proprietario_id,
            user_table utente,
            a.soggetto_code,
            b.quietanziante,
            b.quietanziante_codice_fiscale,
            b.iban,
            b.bic,
            b.contocorrente,
            b.data_scadenza,
            NULL 
        from 	siac_t_soggetto a,
    			siac_t_modpag b ,
            	siac_d_accredito_tipo c, 
            	siac_d_modpag_stato d, 
				siac_r_modpag_stato e
        where a.ente_proprietario_id = p_ente_prop_id
        and	a.ente_proprietario_id=b.ente_proprietario_id
        and	c.ente_proprietario_id=a.ente_proprietario_id
        and	d.ente_proprietario_id=a.ente_proprietario_id
        and	e.ente_proprietario_id=a.ente_proprietario_id
        and a.soggetto_id = b.soggetto_id
        and b.accredito_tipo_id = c.accredito_tipo_id
        and e.modpag_id = b.modpag_id
        and	e.modpag_stato_id	=	d.modpag_stato_id      
   union  
    select 
           	a.soggetto_id_da,
            d.soggetto_desc,
            a.soggetto_id_a,
            x.soggetto_desc,
            x.codice_fiscale,
            x.partita_iva,
            0,
            a.relaz_tipo_id,
 			c.relaz_tipo_code,
        	c.relaz_tipo_desc,
 			g.relaz_stato_code,
        	g.relaz_stato_desc,
        	b.note,
        	f.accredito_tipo_code,
        	f.accredito_tipo_desc,
        	a.ente_proprietario_id,
            user_table utente,
        	d.soggetto_code,
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            NULL,
            e.data_scadenza
    from 		siac_r_soggetto_relaz a, 
    			siac_r_soggrel_modpag b, 
                siac_d_relaz_tipo c,
  				siac_t_soggetto d, 
                siac_t_modpag e, 
                siac_d_accredito_tipo f,
 				siac_d_relaz_stato g, 
				siac_r_soggetto_relaz_stato h, 
                siac_t_soggetto x
	where 	b.soggetto_relaz_id		= 	a.soggetto_relaz_id
		and a.relaz_tipo_id			= 	c.relaz_tipo_id
		and a.soggetto_id_da 		=	d.soggetto_id
        and	b.modpag_id				=	e.modpag_id
        and	e.accredito_tipo_id		=	f.accredito_tipo_id
        and h.soggetto_relaz_id		=	b.soggetto_relaz_id
        and	h.relaz_stato_id		=	g.relaz_stato_id
        and a.soggetto_id_a			=	x.soggetto_id
        and d.ente_proprietario_id	=	p_ente_prop_id
        and	a.ente_proprietario_id	=	d.ente_proprietario_id
        and b.ente_proprietario_id	=	d.ente_proprietario_id
        and c.ente_proprietario_id	=	d.ente_proprietario_id
        and e.ente_proprietario_id	=	d.ente_proprietario_id
        and f.ente_proprietario_id	=	d.ente_proprietario_id
        and g.ente_proprietario_id	=	d.ente_proprietario_id
        and h.ente_proprietario_id	=	d.ente_proprietario_id;
end if;
  raise notice 'dati_soggetto';
if coalesce(p_codice_soggetto ,DEF_NULL)=DEF_NULL	then
for dati_soggetto in 
	select 	a.ambito_id					ambito_id,
    		a.soggetto_code				soggetto_code,
            a.codice_fiscale			codice_fiscale,
            a.codice_fiscale_estero		codice_fiscale_estero, 
            a.partita_iva				partita_iva, 
            a.soggetto_desc				soggetto_desc, 
            a.soggetto_tipo_code		soggetto_tipo_code, 
            a.soggetto_tipo_desc		soggetto_tipo_desc,
            a.forma_giuridica_cat_id	forma_giuridica_cat_id,
            a.forma_giuridica_desc		forma_giuridica_desc,
            a.forma_giuridica_istat_codice	forma_giuridica_istat_codice,
            a.cognome					cognome,
            a.nome						nome,  
            a.comune_id_nascita			comune_id_nascita, 
            a.nascita_data				nascita_data,
            a.sesso						sesso,
            a.comune_desc 				comune_desc,
            a.comune_istat_code 		comune_istat_code,
            coalesce (a.provincia_desc,DEF_SPACES)				provincia_desc,
            coalesce (a.sigla_automobilistica,DEF_SPACES)		sigla_automobilistica,
            coalesce (a.nazione_desc,DEF_SPACES)				nazione_desc, 
            a.soggetto_id				soggetto_id,
            a.stato						stato,
            a.classe_soggetto			classe_soggetto,
            b.tipo_indirizzo			tipo_indirizzo,		
            coalesce (b.via,DEF_SPACES)						via_indirizzo,
            coalesce (b.toponimo,DEF_SPACES)					toponimo_indirizzo, 
            coalesce (b.numero_civico,DEF_SPACES)				numero_civico_indirizzo,
            coalesce (b.interno,DEF_SPACES)						interno_indirizzo,
            coalesce (b.frazione,DEF_SPACES)					frazione_indirizzo,
            coalesce (b.comune,DEF_SPACES)						comune_indirizzo,
            coalesce (b.provincia_desc_sede,DEF_SPACES)			provincia_indirizzo,
            coalesce (b.provincia_sigla,DEF_SPACES)				provincia_sigla_indirizzo,
            coalesce (b.stato_sede,DEF_SPACES)					stato_indirizzo,
            b.avviso					avviso,
            b.desc_tipo_indirizzo		desc_tipo_indirizzo,
            b.indirizzo_id				indirizzo_id,
            c.indirizzo_id_sede			sede_indirizzo_id,
            coalesce (c.via_sede,DEF_SPACES)					sede_via_indirizzo,
        	coalesce (c.toponimo_sede,DEF_SPACES)				sede_toponimo_indirizzo,					
            coalesce (c.numero_civico_sede,DEF_SPACES)			sede_numero_civico_indirizzo,
            coalesce (c.interno_sede,DEF_SPACES)				sede_interno_indirizzo,
            coalesce (c.frazione_sede,DEF_SPACES)				sede_frazione_indirizzo,
            coalesce (c.comune_sede,DEF_SPACES)					sede_comune_indirizzo,
            coalesce (c.provincia_desc_sede,DEF_SPACES)			sede_provincia_indirizzo,
            coalesce (c.provincia_sigla_sede,DEF_SPACES)		sede_provincia_sigla_indirizzo,
            coalesce (c.stato_sede,DEF_SPACES)					sede_stato_indirizzo,
            d.soggetto_id				mp_soggetto_id,
            d.soggetto_desc				mp_soggetto_desc,
            d.accredito_tipo_code		mp_accredito_tipo_code,
            d.accredito_tipo_desc		mp_accredito_tipo_desc,
            d.modpag_stato_desc			mp_modpag_stato_desc,
            coalesce (d.soggetto_ricevente_desc,DEF_SPACES)			ricevente,
            coalesce (d.soggetto_ricevente_cod_fis,DEF_SPACES)		ricevente_cod_fis,
            coalesce (d.soggetto_ricevente_piva ,DEF_SPACES)		ricevente_piva,		
            coalesce (d.accredito_ricevente_tipo_code,DEF_SPACES)	accredito_tipo_code,
            coalesce (d.accredito_ricevente_tipo_desc,DEF_SPACES)	accredito_tipo_desc,
          	coalesce (d.note,DEF_SPACES)							note,
            coalesce (d.quietanzante,DEF_SPACES)					quietanzante,
            coalesce (d.quietanzante_codice_fiscale,DEF_SPACES)		quietanzante_cod_fis,
            coalesce (d.bic,DEF_SPACES)								bic,
            coalesce (d.conto_corrente,DEF_SPACES)					conto_corrente,
            coalesce (d.iban,DEF_SPACES)							iban,
            d.mp_data_scadenza										mp_data_scadenza,
            d.data_scadenza_cessione								data_scadenza_cessione											        
    from siac_rep_persona_fisica	a
    LEFT join	siac_rep_persona_fisica_recapiti b   
                  on (a.soggetto_id	=	b.soggetto_id
                  and a.utente	= user_table
                  and b.utente	= user_table)
    LEFT join	siac_rep_persona_fisica_sedi c   
    on (a.soggetto_id	=	c.soggetto_id
    	and a.utente	=	user_table
        and	c.utente	=	user_table)
    LEFT join	siac_rep_persona_fisica_modpag d   
    on (a.soggetto_code	=	d.soggetto_code
    	and	a.utente	=	user_table
        and	d.utente	=	user_table)
    --SIAC-6215: 12/06/2018: nel caso la denominazione sia NULL
    --	viene trasformata in ''.
   --where a.soggetto_desc	like '%'|| p_denominazione ||'%'
   where a.soggetto_desc	like '%'|| COALESCE(p_denominazione, DEF_NULL) ||'%'
   
   loop
        ambito_id:=dati_soggetto.ambito_id;
        soggetto_code:=dati_soggetto.soggetto_code;
        codice_fiscale:=dati_soggetto.codice_fiscale;
        codice_fiscale_estero:=dati_soggetto.codice_fiscale_estero;
        partita_iva:=dati_soggetto.partita_iva;
        soggetto_desc:=dati_soggetto.soggetto_desc;
        soggetto_tipo_code:=dati_soggetto.soggetto_tipo_code;
        soggetto_tipo_desc:=dati_soggetto.soggetto_tipo_desc;
        cognome:=dati_soggetto.cognome;
        nome:=dati_soggetto.nome;
        comune_id_nascita:=dati_soggetto.comune_id_nascita;
        nascita_data:=dati_soggetto.nascita_data;
        sesso:=dati_soggetto.sesso;
        soggetto_id:=dati_soggetto.soggetto_id;
        comune_desc:=dati_soggetto.comune_desc;
        comune_istat_code:=dati_soggetto.comune_istat_code;
        provincia_desc:=dati_soggetto.provincia_desc;
        sigla_automobilistica:=dati_soggetto.sigla_automobilistica;
        nazione_desc:=dati_soggetto.nazione_desc;
        stato:=dati_soggetto.stato;
        forma_giuridica_cat_id:=dati_soggetto.forma_giuridica_cat_id;
        forma_giuridica_desc:=dati_soggetto.forma_giuridica_desc;
        forma_giuridica_istat_codice:=dati_soggetto.forma_giuridica_istat_codice;
        classe_soggetto:=dati_soggetto.classe_soggetto;   
        tipo_indirizzo:=dati_soggetto.tipo_indirizzo;
  		via_indirizzo:=dati_soggetto.via_indirizzo;
  		toponimo_indirizzo:=dati_soggetto.toponimo_indirizzo;
  		numero_civico_indirizzo:=dati_soggetto.numero_civico_indirizzo;
  		interno_indirizzo:=dati_soggetto.interno_indirizzo;
  		frazione_indirizzo:=dati_soggetto.frazione_indirizzo;
  		comune_indirizzo:=dati_soggetto.comune_indirizzo;
  		provincia_indirizzo:=dati_soggetto.provincia_indirizzo;
  		provincia_sigla_indirizzo:=dati_soggetto.provincia_sigla_indirizzo;
  		stato_indirizzo:=dati_soggetto.stato_indirizzo;
        avviso:=dati_soggetto.avviso;
        indirizzo_id:=dati_soggetto.indirizzo_id;
        desc_tipo_indirizzo:=dati_soggetto.desc_tipo_indirizzo;
        sede_indirizzo_id:=dati_soggetto.sede_indirizzo_id;
        sede_via_indirizzo:=dati_soggetto.sede_via_indirizzo;
       	sede_toponimo_indirizzo:=dati_soggetto.sede_toponimo_indirizzo;					
        sede_numero_civico_indirizzo:=dati_soggetto.sede_numero_civico_indirizzo;
        sede_interno_indirizzo:=dati_soggetto.sede_interno_indirizzo;
        sede_frazione_indirizzo:=dati_soggetto.sede_frazione_indirizzo;
       	sede_comune_indirizzo:=dati_soggetto.sede_comune_indirizzo;
       	sede_provincia_indirizzo:=dati_soggetto.sede_provincia_indirizzo;
        sede_provincia_sigla_indirizzo:=dati_soggetto.sede_provincia_sigla_indirizzo;
        sede_stato_indirizzo:=dati_soggetto.sede_stato_indirizzo;
        mp_soggetto_id:=dati_soggetto.mp_soggetto_id;
        mp_soggetto_desc:=dati_soggetto.mp_soggetto_desc;
        mp_accredito_tipo_code:=dati_soggetto.mp_accredito_tipo_code;
        mp_accredito_tipo_desc:=dati_soggetto.mp_accredito_tipo_desc;
        mp_modpag_stato_desc:=dati_soggetto.mp_modpag_stato_desc;
        ricevente:=dati_soggetto.ricevente;		
        accredito_tipo_code:=dati_soggetto.accredito_tipo_code;
        accredito_tipo_desc:=dati_soggetto.accredito_tipo_desc;
        note:=dati_soggetto.note;
        ricevente_cod_fis:=dati_soggetto.ricevente_cod_fis;
        ricevente_piva:=dati_soggetto.ricevente_piva;
        quietanzante:=dati_soggetto.quietanzante;
        quietanzante_cod_fis:=dati_soggetto.quietanzante_cod_fis;
        bic:=dati_soggetto.bic;
        conto_corrente:=dati_soggetto.conto_corrente;
        iban:=dati_soggetto.iban;
        mp_data_scadenza:=dati_soggetto.mp_data_scadenza;
        data_scadenza_cessione:=dati_soggetto.data_scadenza_cessione;
        return next;
     end loop;


  raise notice 'fine OK';
  else
  for dati_soggetto in 
   select 	a.ambito_id					ambito_id,
    		a.soggetto_code				soggetto_code,
            a.codice_fiscale			codice_fiscale,
            a.codice_fiscale_estero		codice_fiscale_estero, 
            a.partita_iva				partita_iva, 
            a.soggetto_desc				soggetto_desc, 
            a.soggetto_tipo_code		soggetto_tipo_code, 
            a.soggetto_tipo_desc		soggetto_tipo_desc,
            a.forma_giuridica_cat_id	forma_giuridica_cat_id,
            a.forma_giuridica_desc		forma_giuridica_desc,
            a.forma_giuridica_istat_codice	forma_giuridica_istat_codice,
            a.cognome					cognome,
            a.nome						nome,  
            a.comune_id_nascita			comune_id_nascita, 
            a.nascita_data				nascita_data,
            a.sesso						sesso,
            a.comune_desc 				comune_desc,
            a.comune_istat_code 		comune_istat_code,
            coalesce (a.provincia_desc,DEF_SPACES)				provincia_desc,
            coalesce (a.sigla_automobilistica,DEF_SPACES)		sigla_automobilistica,
            coalesce (a.nazione_desc,DEF_SPACES)				nazione_desc, 
            a.soggetto_id				soggetto_id,
            a.stato						stato,
            a.classe_soggetto			classe_soggetto,
            b.tipo_indirizzo			tipo_indirizzo,		
            coalesce (b.via,DEF_SPACES)						via_indirizzo,
            coalesce (b.toponimo,DEF_SPACES)					toponimo_indirizzo, 
            coalesce (b.numero_civico,DEF_SPACES)				numero_civico_indirizzo,
            coalesce (b.interno,DEF_SPACES)						interno_indirizzo,
            coalesce (b.frazione,DEF_SPACES)					frazione_indirizzo,
            coalesce (b.comune,DEF_SPACES)						comune_indirizzo,
            coalesce (b.provincia_desc_sede,DEF_SPACES)			provincia_indirizzo,
            coalesce (b.provincia_sigla,DEF_SPACES)				provincia_sigla_indirizzo,
            coalesce (b.stato_sede,DEF_SPACES)					stato_indirizzo,
            b.avviso					avviso,
            b.desc_tipo_indirizzo		desc_tipo_indirizzo,
            b.indirizzo_id				indirizzo_id,
            c.indirizzo_id_sede			sede_indirizzo_id,
            coalesce (c.via_sede,DEF_SPACES)					sede_via_indirizzo,
        	coalesce (c.toponimo_sede,DEF_SPACES)				sede_toponimo_indirizzo,					
            coalesce (c.numero_civico_sede,DEF_SPACES)			sede_numero_civico_indirizzo,
            coalesce (c.interno_sede,DEF_SPACES)				sede_interno_indirizzo,
            coalesce (c.frazione_sede,DEF_SPACES)				sede_frazione_indirizzo,
            coalesce (c.comune_sede,DEF_SPACES)					sede_comune_indirizzo,
            coalesce (c.provincia_desc_sede,DEF_SPACES)			sede_provincia_indirizzo,
            coalesce (c.provincia_sigla_sede,DEF_SPACES)		sede_provincia_sigla_indirizzo,
            coalesce (c.stato_sede,DEF_SPACES)					sede_stato_indirizzo,
            d.soggetto_id				mp_soggetto_id,
            d.soggetto_desc				mp_soggetto_desc,
            d.accredito_tipo_code		mp_accredito_tipo_code,
            d.accredito_tipo_desc		mp_accredito_tipo_desc,
            d.modpag_stato_desc			mp_modpag_stato_desc,
            coalesce (d.soggetto_ricevente_desc,DEF_SPACES)			ricevente,
            coalesce (d.soggetto_ricevente_cod_fis,DEF_SPACES)		ricevente_cod_fis,
            coalesce (d.soggetto_ricevente_piva ,DEF_SPACES)		ricevente_piva,		
            coalesce (d.accredito_ricevente_tipo_code,DEF_SPACES)	accredito_tipo_code,
            coalesce (d.accredito_ricevente_tipo_desc,DEF_SPACES)	accredito_tipo_desc,
          	coalesce (d.note,DEF_SPACES)							note,
            coalesce (d.quietanzante,DEF_SPACES)					quietanzante,
            coalesce (d.quietanzante_codice_fiscale,DEF_SPACES)		quietanzante_cod_fis,
            coalesce (d.bic,DEF_SPACES)								bic,
            coalesce (d.conto_corrente,DEF_SPACES)					conto_corrente,
            coalesce (d.iban,DEF_SPACES)							iban,
            d.mp_data_scadenza										mp_data_scadenza,
            d.data_scadenza_cessione								data_scadenza_cessione											     
    from siac_rep_persona_fisica	a
    LEFT join	siac_rep_persona_fisica_recapiti b   
                  on (a.soggetto_id	=	b.soggetto_id
                  and a.utente	= user_table
                  and b.utente	= user_table)
    LEFT join	siac_rep_persona_fisica_sedi c   
    on (a.soggetto_id	=	c.soggetto_id
    	and a.utente	=	user_table
        and	c.utente	=	user_table)
    LEFT join	siac_rep_persona_fisica_modpag d   
    on (a.soggetto_code	=	d.soggetto_code
    	and	a.utente	=	user_table
        and	d.utente	=	user_table)
   where	a.soggetto_code	=	p_codice_soggetto

    loop
        ambito_id:=dati_soggetto.ambito_id;
        soggetto_code:=dati_soggetto.soggetto_code;
        codice_fiscale:=dati_soggetto.codice_fiscale;
        codice_fiscale_estero:=dati_soggetto.codice_fiscale_estero;
        partita_iva:=dati_soggetto.partita_iva;
        soggetto_desc:=dati_soggetto.soggetto_desc;
        soggetto_tipo_code:=dati_soggetto.soggetto_tipo_code;
        soggetto_tipo_desc:=dati_soggetto.soggetto_tipo_desc;
        cognome:=dati_soggetto.cognome;
        nome:=dati_soggetto.nome;
        comune_id_nascita:=dati_soggetto.comune_id_nascita;
        nascita_data:=dati_soggetto.nascita_data;
        sesso:=dati_soggetto.sesso;
        soggetto_id:=dati_soggetto.soggetto_id;
        comune_desc:=dati_soggetto.comune_desc;
        comune_istat_code:=dati_soggetto.comune_istat_code;
        provincia_desc:=dati_soggetto.provincia_desc;
        sigla_automobilistica:=dati_soggetto.sigla_automobilistica;
        nazione_desc:=dati_soggetto.nazione_desc;
        stato:=dati_soggetto.stato;
        forma_giuridica_cat_id:=dati_soggetto.forma_giuridica_cat_id;
        forma_giuridica_desc:=dati_soggetto.forma_giuridica_desc;
        forma_giuridica_istat_codice:=dati_soggetto.forma_giuridica_istat_codice;
        classe_soggetto:=dati_soggetto.classe_soggetto;   
        tipo_indirizzo:=dati_soggetto.tipo_indirizzo;
  		via_indirizzo:=dati_soggetto.via_indirizzo;
  		toponimo_indirizzo:=dati_soggetto.toponimo_indirizzo;
  		numero_civico_indirizzo:=dati_soggetto.numero_civico_indirizzo;
  		interno_indirizzo:=dati_soggetto.interno_indirizzo;
  		frazione_indirizzo:=dati_soggetto.frazione_indirizzo;
  		comune_indirizzo:=dati_soggetto.comune_indirizzo;
  		provincia_indirizzo:=dati_soggetto.provincia_indirizzo;
  		provincia_sigla_indirizzo:=dati_soggetto.provincia_sigla_indirizzo;
  		stato_indirizzo:=dati_soggetto.stato_indirizzo;
        avviso:=dati_soggetto.avviso;
        indirizzo_id:=dati_soggetto.indirizzo_id;
        desc_tipo_indirizzo:=dati_soggetto.desc_tipo_indirizzo;
        sede_indirizzo_id:=dati_soggetto.sede_indirizzo_id;
        sede_via_indirizzo:=dati_soggetto.sede_via_indirizzo;
       	sede_toponimo_indirizzo:=dati_soggetto.sede_toponimo_indirizzo;					
        sede_numero_civico_indirizzo:=dati_soggetto.sede_numero_civico_indirizzo;
        sede_interno_indirizzo:=dati_soggetto.sede_interno_indirizzo;
        sede_frazione_indirizzo:=dati_soggetto.sede_frazione_indirizzo;
       	sede_comune_indirizzo:=dati_soggetto.sede_comune_indirizzo;
       	sede_provincia_indirizzo:=dati_soggetto.sede_provincia_indirizzo;
        sede_provincia_sigla_indirizzo:=dati_soggetto.sede_provincia_sigla_indirizzo;
        sede_stato_indirizzo:=dati_soggetto.sede_stato_indirizzo;
        mp_soggetto_id:=dati_soggetto.mp_soggetto_id;
        mp_soggetto_desc:=dati_soggetto.mp_soggetto_desc;
        mp_accredito_tipo_code:=dati_soggetto.mp_accredito_tipo_code;
        mp_accredito_tipo_desc:=dati_soggetto.mp_accredito_tipo_desc;
        mp_modpag_stato_desc:=dati_soggetto.mp_modpag_stato_desc;
        ricevente:=dati_soggetto.ricevente;		
        accredito_tipo_code:=dati_soggetto.accredito_tipo_code;
        accredito_tipo_desc:=dati_soggetto.accredito_tipo_desc;
        note:=dati_soggetto.note;
        ricevente_cod_fis:=dati_soggetto.ricevente_cod_fis;
        ricevente_piva:=dati_soggetto.ricevente_piva;
        quietanzante:=dati_soggetto.quietanzante;
        quietanzante_cod_fis:=dati_soggetto.quietanzante_cod_fis;
        bic:=dati_soggetto.bic;
        conto_corrente:=dati_soggetto.conto_corrente;
        iban:=dati_soggetto.iban;
        mp_data_scadenza:=dati_soggetto.mp_data_scadenza;
        data_scadenza_cessione:=dati_soggetto.data_scadenza_cessione;
        return next;
        ambito_id=0;
        soggetto_code='';
        codice_fiscale='';
        codice_fiscale_estero='';
        partita_iva='';
        soggetto_desc='';
        soggetto_tipo_code='';
        soggetto_tipo_desc='';
        cognome='';
       nome='';
        comune_id_nascita=0;
        nascita_data=NULL;
        sesso='';
        soggetto_id=0;
        comune_desc='';
        comune_istat_code='';
        provincia_desc='';
        sigla_automobilistica='';
        nazione_desc='';
        stato='';
        forma_giuridica_cat_id=0;
        forma_giuridica_desc='';
        forma_giuridica_istat_codice='';
        classe_soggetto='';
        tipo_indirizzo='';
  		via_indirizzo='';
  		toponimo_indirizzo='';
  		numero_civico_indirizzo='';
  		interno_indirizzo='';
  		frazione_indirizzo='';
  		comune_indirizzo='';
  		provincia_indirizzo='';
  		provincia_sigla_indirizzo='';
  		stato_indirizzo='';
        avviso='';
        indirizzo_id=0;
        desc_tipo_indirizzo='';
        sede_indirizzo_id=0;
        sede_via_indirizzo='';
       	sede_toponimo_indirizzo='';				
        sede_numero_civico_indirizzo='';
        sede_interno_indirizzo='';
        sede_frazione_indirizzo='';
       	sede_comune_indirizzo='';
       	sede_provincia_indirizzo='';
        sede_provincia_sigla_indirizzo='';
        sede_stato_indirizzo='';
        mp_soggetto_id=0;
        mp_soggetto_desc='';
        mp_accredito_tipo_code='';
        mp_accredito_tipo_desc='';
        mp_modpag_stato_desc='';
        ricevente='';
        accredito_tipo_code='';
        accredito_tipo_desc='';
        note='';
        ricevente_cod_fis='';
        ricevente_piva='';
        quietanzante='';
        quietanzante_cod_fis='';
        bic='';
        conto_corrente='';
        iban='';
        mp_data_scadenza=NULL;
        data_scadenza_cessione=NULL;   
     end loop;


  raise notice 'fine OK';
  end if;  
delete from siac_rep_persona_fisica where utente=user_table;
delete from siac_rep_persona_fisica_recapiti where utente=user_table;
delete from siac_rep_persona_fisica_sedi where utente=user_table;	
delete from siac_rep_persona_fisica_modpag where utente=user_table;	
  
EXCEPTION
when no_data_found THEN
	raise notice 'nessun soggetto  trovato';
	return;
when others  THEN
 RTN_MESSAGGIO:='Ricerca dati soggetto';
 RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR029_soggetti_persona_fisica_e_giuridica" (
  p_ente_prop_id integer,
  p_denominazione varchar = NULL::character varying,
  p_stato_soggetto varchar = NULL::character varying,
  p_classe_soggetto varchar = NULL::character varying,
  p_tipo_estrazione varchar = NULL::character varying
)
RETURNS TABLE (
  ambito_id integer,
  soggetto_code varchar,
  codice_fiscale varchar,
  codice_fiscale_estero varchar,
  partita_iva varchar,
  soggetto_desc varchar,
  soggetto_tipo_code varchar,
  soggetto_tipo_desc varchar,
  forma_giuridica_cat_id varchar,
  forma_giuridica_desc varchar,
  forma_giuridica_istat_codice varchar,
  cognome varchar,
  nome varchar,
  comune_id_nascita integer,
  nascita_data date,
  sesso varchar,
  comune_desc varchar,
  comune_istat_code varchar,
  provincia_desc varchar,
  sigla_automobilistica varchar,
  nazione_desc varchar,
  soggetto_id integer,
  stato varchar,
  classe_soggetto varchar,
  desc_tipo_indirizzo varchar,
  tipo_indirizzo varchar,
  via_indirizzo varchar,
  toponimo_indirizzo varchar,
  numero_civico_indirizzo varchar,
  interno_indirizzo varchar,
  frazione_indirizzo varchar,
  comune_indirizzo varchar,
  provincia_indirizzo varchar,
  provincia_sigla_indirizzo varchar,
  stato_indirizzo varchar,
  indirizzo_id integer,
  avviso varchar,
  sede_indirizzo_id integer,
  sede_via_indirizzo varchar,
  sede_toponimo_indirizzo varchar,
  sede_numero_civico_indirizzo varchar,
  sede_interno_indirizzo varchar,
  sede_frazione_indirizzo varchar,
  sede_comune_indirizzo varchar,
  sede_provincia_indirizzo varchar,
  sede_provincia_sigla_indirizzo varchar,
  sede_stato_indirizzo varchar,
  mp_soggetto_id integer,
  mp_soggetto_desc varchar,
  mp_accredito_tipo_code varchar,
  mp_accredito_tipo_desc varchar,
  mp_modpag_stato_desc varchar,
  ricevente varchar,
  accredito_tipo_code varchar,
  accredito_tipo_desc varchar,
  note varchar,
  ricevente_cod_fis varchar,
  ricevente_piva varchar,
  quietanzante varchar,
  quietanzante_cod_fis varchar,
  bic varchar,
  conto_corrente varchar,
  iban varchar,
  tipologia_soggetto varchar,
  mp_data_scadenza date,
  data_scadenza_cessione date
) AS
$body$
DECLARE
	dati_soggetto record;
    DEF_NULL	constant varchar:=''; 
    DEF_SPACES	constant varchar:=' '; 
    RTN_MESSAGGIO varchar(1000):=DEF_NULL;
    user_table	varchar;
  
  BEGIN
  
select fnc_siac_random_user()
into	user_table;
  
  tipologia_soggetto:='PF'; 

if coalesce(p_stato_soggetto ,DEF_NULL)=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)=DEF_NULL then
      raise notice '1';
    insert into siac_rep_persona_fisica
	select 	a.ambito_id,
            a.soggetto_code,
            a.codice_fiscale,
            a.codice_fiscale_estero,
            a.partita_iva,
            a.soggetto_desc,
            d.soggetto_tipo_code,
            d.soggetto_tipo_desc,
            m.forma_giuridica_cat_id,
            m.forma_giuridica_desc,
            m.forma_giuridica_istat_codice,
            b.cognome,
            b.nome,
            b.comune_id_nascita,
            b.nascita_data,
            b.sesso,
            n.comune_desc,
            n.comune_istat_code,
            q.provincia_desc,
            q.sigla_automobilistica,
            r.nazione_desc,
            a.soggetto_id,
            f.soggetto_stato_desc,
            h.soggetto_classe_desc,
            b.ente_proprietario_id,
            user_table utente                 
    from 	
            siac_r_soggetto_tipo 	c, 
            siac_d_soggetto_tipo 	d,
            siac_r_soggetto_stato	e,
            siac_d_soggetto_stato	f,
            siac_t_soggetto 		a,
            siac_t_persona_fisica 	b
            FULL  join siac_r_soggetto_classe	g
            on    	(b.soggetto_id		=	g.soggetto_id
                        and	g.ente_proprietario_id	=	b.ente_proprietario_id
                        and	g.validita_fine	is null)
            FULL  join  siac_d_soggetto_classe	h	
            on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                        and	h.ente_proprietario_id	=	g.ente_proprietario_id
                        and	h.validita_fine	is null)
            FULL  join  siac_r_forma_giuridica	p	
            on    	(b.soggetto_id			=	p.soggetto_id
                        and	p.ente_proprietario_id	=	b.ente_proprietario_id)
            FULL  join  siac_t_forma_giuridica	m	
            on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                        and	p.ente_proprietario_id	=	m.ente_proprietario_id
                        and	p.validita_fine	is null)
            FULL  join  siac_t_comune	n	
            on    	(n.comune_id	=	b.comune_id_nascita
                        and	n.ente_proprietario_id	=	b.ente_proprietario_id
                        and	n.validita_fine	is null)
            FULL  join  siac_r_comune_provincia	o	
            on    	(o.comune_id	=	b.comune_id_nascita
                        and	n.ente_proprietario_id	=	b.ente_proprietario_id
                        and	o.validita_fine	is null)
            FULL  join  siac_t_provincia	q	
            on    	(q.provincia_id	=	o.provincia_id
                        and	q.ente_proprietario_id	=	o.ente_proprietario_id
                        and	q.validita_fine	is null)
            FULL  join  siac_t_nazione	r	
            on    	(n.nazione_id	=	r.nazione_id
                        and	r.ente_proprietario_id	=	n.ente_proprietario_id
                        and	r.validita_fine	is null)           
            WHERE	a.ente_proprietario_id	=	p_ente_prop_id
            and		b.ente_proprietario_id	=	a.ente_proprietario_id
            and		c.ente_proprietario_id	=	a.ente_proprietario_id
            and		d.ente_proprietario_id	=	a.ente_proprietario_id
            and		e.ente_proprietario_id	=	a.ente_proprietario_id
            and		f.ente_proprietario_id	=	a.ente_proprietario_id
            and		a.soggetto_id			=	b.soggetto_id
            and		c.soggetto_id			=	b.soggetto_id
            and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
            and		e.soggetto_id			=	b.soggetto_id
            and		e.soggetto_stato_id		=	f.soggetto_stato_id
            and		a.validita_fine			is null
            and		b.validita_fine			is null
            and		e.validita_fine			is null
            and		c.validita_fine			is null
            and		d.validita_fine			is null
            and		e.validita_fine			is null
            and		f.validita_fine			is null;		
ELSE
	if coalesce(p_stato_soggetto ,DEF_NULL)!=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)=DEF_NULL then
              raise notice '2';
        insert into siac_rep_persona_fisica
        select 	a.ambito_id					ambito_id,
                a.soggetto_code				soggetto_code,
                a.codice_fiscale			codice_fiscale,
                a.codice_fiscale_estero		codice_fiscale_estero, 
                a.partita_iva				partita_iva, 
                a.soggetto_desc				soggetto_desc, 
                d.soggetto_tipo_code		soggetto_tipo_code, 
                d.soggetto_tipo_desc		soggetto_tipo_desc,
                m.forma_giuridica_cat_id	forma_giuridica_cat_id,
                m.forma_giuridica_desc		forma_giuridica_desc,
                m.forma_giuridica_istat_codice	forma_giuridica_istat_codice,
                b.cognome					cognome,
                b.nome						nome,  
                b.comune_id_nascita			comune_id_nascita, 
                b.nascita_data				nascita_data,
                b.sesso						sesso,
                n.comune_desc 				comune_desc,
                n.comune_istat_code 		comune_istat_code,
                q.provincia_desc			provincia_desc,
                q.sigla_automobilistica		sigla_automobilistica,
                r.nazione_desc				nazione_desc, 
                a.soggetto_id				soggetto_id,
                f.soggetto_stato_desc		stato,
                h.soggetto_classe_desc		classe_soggetto,
                b.ente_proprietario_id,
                user_table utente             
        from 	
                siac_r_soggetto_tipo 	c, 
                siac_d_soggetto_tipo 	d,
                siac_r_soggetto_stato	e,
                siac_d_soggetto_stato	f,
                siac_t_soggetto 		a,
                siac_t_persona_fisica 	b
                FULL  join siac_r_soggetto_classe	g
                on    	(b.soggetto_id		=	g.soggetto_id
                            and	g.ente_proprietario_id	=	b.ente_proprietario_id
                            and	g.validita_fine	is null)
                FULL  join  siac_d_soggetto_classe	h	
                on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                            and	h.ente_proprietario_id	=	g.ente_proprietario_id
                            and	h.validita_fine	is null)
                FULL  join  siac_r_forma_giuridica	p	
                on    	(b.soggetto_id			=	p.soggetto_id
                            and	p.ente_proprietario_id	=	b.ente_proprietario_id)
                FULL  join  siac_t_forma_giuridica	m	
                on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                            and	p.ente_proprietario_id	=	m.ente_proprietario_id
                            and	p.validita_fine	is null)
                FULL  join  siac_t_comune	n	
                on    	(n.comune_id	=	b.comune_id_nascita
                            and	n.ente_proprietario_id	=	b.ente_proprietario_id
                            and	n.validita_fine	is null)
                FULL  join  siac_r_comune_provincia	o	
                on    	(o.comune_id	=	b.comune_id_nascita
                            and	n.ente_proprietario_id	=	b.ente_proprietario_id
                            and	o.validita_fine	is null)
                FULL  join  siac_t_provincia	q	
                on    	(q.provincia_id	=	o.provincia_id
                            and	q.ente_proprietario_id	=	o.ente_proprietario_id
                            and	q.validita_fine	is null)
                FULL  join  siac_t_nazione	r	
                on    	(n.nazione_id	=	r.nazione_id
                            and	r.ente_proprietario_id	=	n.ente_proprietario_id
                            and	r.validita_fine	is null)           
                WHERE	a.ente_proprietario_id	=	p_ente_prop_id
                and		b.ente_proprietario_id	=	a.ente_proprietario_id
                and		c.ente_proprietario_id	=	a.ente_proprietario_id
                and		d.ente_proprietario_id	=	a.ente_proprietario_id
                and		e.ente_proprietario_id	=	a.ente_proprietario_id
                and		f.ente_proprietario_id	=	a.ente_proprietario_id
                and		a.soggetto_id			=	b.soggetto_id
                and		c.soggetto_id			=	b.soggetto_id
                and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
                and		e.soggetto_id			=	b.soggetto_id
                and		e.soggetto_stato_id		=	f.soggetto_stato_id
               	and		f.soggetto_stato_desc	=	p_stato_soggetto
                and		a.validita_fine			is null
                and		b.validita_fine			is null
                and		e.validita_fine			is null
                and		c.validita_fine			is null
                and		d.validita_fine			is null
                and		e.validita_fine			is null
                and		f.validita_fine			is null;		
     ELSE
     	if coalesce(p_stato_soggetto ,DEF_NULL)=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)!=DEF_NULL then
             raise notice 'classe diversa da null';
            insert into siac_rep_persona_fisica
select 	a.ambito_id,
            a.soggetto_code,
            a.codice_fiscale,
            a.codice_fiscale_estero,
            a.partita_iva,
            a.soggetto_desc,
            d.soggetto_tipo_code,
            d.soggetto_tipo_desc,
            m.forma_giuridica_cat_id,
            m.forma_giuridica_desc,
            m.forma_giuridica_istat_codice,
            b.cognome,
            b.nome,
            b.comune_id_nascita,
            b.nascita_data,
            b.sesso,
            n.comune_desc,
            n.comune_istat_code,
            q.provincia_desc,
            q.sigla_automobilistica,
            r.nazione_desc,
            a.soggetto_id,
            f.soggetto_stato_desc,
            h.soggetto_classe_desc,
            b.ente_proprietario_id,
            user_table utente                 
    from 	
            siac_r_soggetto_tipo 	c, 
            siac_d_soggetto_tipo 	d,
            siac_r_soggetto_stato	e,
            siac_d_soggetto_stato	f,
            siac_t_soggetto 		a,
            siac_t_persona_fisica 	b
            FULL  join siac_r_soggetto_classe	g
            on    	(b.soggetto_id		=	g.soggetto_id
                        and	g.ente_proprietario_id	=	b.ente_proprietario_id
                        and	g.validita_fine	is null)
            RIGHT  join  siac_d_soggetto_classe	h	
            on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
            			AND	H.soggetto_classe_desc	=	p_classe_soggetto
                        and	h.ente_proprietario_id	=	g.ente_proprietario_id
                        and	h.validita_fine	is null)
            FULL  join  siac_r_forma_giuridica	p	
            on    	(b.soggetto_id			=	p.soggetto_id
                        and	p.ente_proprietario_id	=	b.ente_proprietario_id)
            FULL  join  siac_t_forma_giuridica	m	
            on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                        and	p.ente_proprietario_id	=	m.ente_proprietario_id
                        and	p.validita_fine	is null)
            FULL  join  siac_t_comune	n	
            on    	(n.comune_id	=	b.comune_id_nascita
                        and	n.ente_proprietario_id	=	b.ente_proprietario_id
                        and	n.validita_fine	is null)
            FULL  join  siac_r_comune_provincia	o	
            on    	(o.comune_id	=	b.comune_id_nascita
                        and	n.ente_proprietario_id	=	b.ente_proprietario_id
                        and	o.validita_fine	is null)
            FULL  join  siac_t_provincia	q	
            on    	(q.provincia_id	=	o.provincia_id
                        and	q.ente_proprietario_id	=	o.ente_proprietario_id
                        and	q.validita_fine	is null)
            FULL  join  siac_t_nazione	r	
            on    	(n.nazione_id	=	r.nazione_id
                        and	r.ente_proprietario_id	=	n.ente_proprietario_id
                        and	r.validita_fine	is null)           
            WHERE	a.ente_proprietario_id	=	p_ente_prop_id
            and		b.ente_proprietario_id	=	a.ente_proprietario_id
            and		c.ente_proprietario_id	=	a.ente_proprietario_id
            and		d.ente_proprietario_id	=	a.ente_proprietario_id
            and		e.ente_proprietario_id	=	a.ente_proprietario_id
            and		f.ente_proprietario_id	=	a.ente_proprietario_id
            and		a.soggetto_id			=	b.soggetto_id
            and		c.soggetto_id			=	b.soggetto_id
            and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
            and		e.soggetto_id			=	b.soggetto_id
            and		e.soggetto_stato_id		=	f.soggetto_stato_id
            and		a.validita_fine			is null
            and		b.validita_fine			is null
            and		e.validita_fine			is null
            and		c.validita_fine			is null
            and		d.validita_fine			is null
            and		e.validita_fine			is null
            and		f.validita_fine			is null;		
            		
      else  
      		      raise notice '3';
            insert into siac_rep_persona_fisica
            select 	a.ambito_id					ambito_id,
                    a.soggetto_code				soggetto_code,
                    a.codice_fiscale			codice_fiscale,
                    a.codice_fiscale_estero		codice_fiscale_estero, 
                    a.partita_iva				partita_iva, 
                    a.soggetto_desc				soggetto_desc, 
                    d.soggetto_tipo_code		soggetto_tipo_code, 
                    d.soggetto_tipo_desc		soggetto_tipo_desc,
                    m.forma_giuridica_cat_id	forma_giuridica_cat_id,
                    m.forma_giuridica_desc		forma_giuridica_desc,
                    m.forma_giuridica_istat_codice	forma_giuridica_istat_codice,
                    b.cognome					cognome,
                    b.nome						nome,  
                    b.comune_id_nascita			comune_id_nascita, 
                    b.nascita_data				nascita_data,
                    b.sesso						sesso,
                    n.comune_desc 				comune_desc,
                    n.comune_istat_code 		comune_istat_code,
                    q.provincia_desc			provincia_desc,
                    q.sigla_automobilistica		sigla_automobilistica,
                    r.nazione_desc				nazione_desc, 
                    a.soggetto_id				soggetto_id,
                    f.soggetto_stato_desc		stato,
                    h.soggetto_classe_desc		classe_soggetto,
                    b.ente_proprietario_id,
                    user_table utente             
            from 	
                    siac_r_soggetto_tipo 	c, 
                    siac_d_soggetto_tipo 	d,
                    siac_r_soggetto_stato	e,
                    siac_d_soggetto_stato	f,
                    siac_t_soggetto 		a,
                    siac_t_persona_fisica 	b
                    FULL  join siac_r_soggetto_classe	g
                    on    	(b.soggetto_id		=	g.soggetto_id
                                and	g.ente_proprietario_id	=	b.ente_proprietario_id
                                and	g.validita_fine	is null)
                    RIGHT  join  siac_d_soggetto_classe	h	
                    on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                    			and	h.soggetto_classe_desc	=	p_classe_soggetto
                                and	h.ente_proprietario_id	=	g.ente_proprietario_id
                                and	h.validita_fine	is null)
                    FULL  join  siac_r_forma_giuridica	p	
                    on    	(b.soggetto_id			=	p.soggetto_id
                                and	p.ente_proprietario_id	=	b.ente_proprietario_id)
                    FULL  join  siac_t_forma_giuridica	m	
                    on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                                and	p.ente_proprietario_id	=	m.ente_proprietario_id
                                and	p.validita_fine	is null)
                    FULL  join  siac_t_comune	n	
                    on    	(n.comune_id	=	b.comune_id_nascita
                                and	n.ente_proprietario_id	=	b.ente_proprietario_id
                                and	n.validita_fine	is null)
                    FULL  join  siac_r_comune_provincia	o	
                    on    	(o.comune_id	=	b.comune_id_nascita
                                and	n.ente_proprietario_id	=	b.ente_proprietario_id
                                and	o.validita_fine	is null)
                    FULL  join  siac_t_provincia	q	
                    on    	(q.provincia_id	=	o.provincia_id
                                and	q.ente_proprietario_id	=	o.ente_proprietario_id
                                and	q.validita_fine	is null)
                    FULL  join  siac_t_nazione	r	
                    on    	(n.nazione_id	=	r.nazione_id
                                and	r.ente_proprietario_id	=	n.ente_proprietario_id
                                and	r.validita_fine	is null)           
                    WHERE	a.ente_proprietario_id	=	p_ente_prop_id
                    and		b.ente_proprietario_id	=	a.ente_proprietario_id
                    and		c.ente_proprietario_id	=	a.ente_proprietario_id
                    and		d.ente_proprietario_id	=	a.ente_proprietario_id
                    and		e.ente_proprietario_id	=	a.ente_proprietario_id
                    and		f.ente_proprietario_id	=	a.ente_proprietario_id
                    and		a.soggetto_id			=	b.soggetto_id
                    and		c.soggetto_id			=	b.soggetto_id
                    and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
                    and		e.soggetto_id			=	b.soggetto_id
                    and		e.soggetto_stato_id		=	f.soggetto_stato_id
                    and		f.soggetto_stato_desc	=	p_stato_soggetto
                    and		a.validita_fine			is null
                    and		b.validita_fine			is null
                    and		e.validita_fine			is null
                    and		c.validita_fine			is null
                    and		d.validita_fine			is null
                    and		e.validita_fine			is null
                    and		f.validita_fine			is null;	      
      end if;    
	end if;
end if;



if  p_tipo_estrazione = '1' or p_tipo_estrazione = '3'	THEN
      		      raise notice '4';
      insert into siac_rep_persona_fisica_recapiti
     select	d.soggetto_id,				
   				c.principale,			
                b1.via_tipo_desc,			
                c.toponimo,					
                c.numero_civico,			
                c.interno,				
                c.frazione,				
                n.comune_desc,				
                q.provincia_desc,			
                q.sigla_automobilistica,		
                r.nazione_desc,		
                c.avviso,			
                d.ente_proprietario_id,
                user_table utente,
                e.indirizzo_tipo_desc,
                c.indirizzo_id	
 from	  siac_t_persona_fisica d
              full join	siac_t_indirizzo_soggetto c   
                  on (d.soggetto_id	=	c.soggetto_id
                      and	d.validita_fine	is null) 
              full join siac_r_indirizzo_soggetto_tipo	a
              		on (c.indirizzo_id	=	a.indirizzo_id
                    	and	c.ente_proprietario_id	=	a.ente_proprietario_id
                        and	a.validita_fine	is NULL)
              full join siac_d_indirizzo_tipo	e
              		on (e.indirizzo_tipo_id	=	a.indirizzo_tipo_id
                    	and	e.ente_proprietario_id	=	a.ente_proprietario_id
                        and	e.validita_fine	is null)              
              FULL  join siac_d_via_tipo b1
                      on (b1.via_tipo_id	=	c.via_tipo_id
                          and	b1.ente_proprietario_id	=	c.ente_proprietario_id
                          and	b1.validita_fine is null)  
              FULL  join  siac_t_comune	n	
                  on    	(n.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id
                              and	n.validita_fine	is null)
              FULL  join  siac_r_comune_provincia	o	
                  on    	(o.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id
                              and	o.validita_fine	is null)
              FULL  join  siac_t_provincia	q	
                  on    	(q.provincia_id	=	o.provincia_id
                              and	q.ente_proprietario_id	=	o.ente_proprietario_id
                              and	q.validita_fine	is null)
              FULL  join  siac_t_nazione	r	
                  on    	(n.nazione_id	=	r.nazione_id
                              and	r.ente_proprietario_id	=	n.ente_proprietario_id
                              and	r.validita_fine	is null)  
              where 
                      d.ente_proprietario_id 	= p_ente_prop_id
              and		c.ente_proprietario_id 	= 	d.ente_proprietario_id;
end if;  


if  p_tipo_estrazione = '1' or p_tipo_estrazione = '3'	THEN
      		      raise notice '5';
      insert into siac_rep_persona_fisica_sedi
      select		d.soggetto_id,	
                  ----c.								denominazione,	
                  b1.via_tipo_desc,
                  c.toponimo,
                  c.numero_civico,
                  c.interno,
                  c.frazione,
                  n.comune_desc,
                  q.provincia_desc,
                  q.sigla_automobilistica,
                  r.nazione_desc,
                  '',
                  c.indirizzo_id,
                  d.ente_proprietario_id,
                  user_table utente             
      from 	siac_d_relaz_tipo b, 
              siac_r_soggetto_relaz a  
              RIGHT join	siac_t_persona_fisica d
                  on (		d.soggetto_id	=	a.soggetto_id_da
                      and	d.validita_fine	is null)
              full join siac_t_indirizzo_soggetto c
                  on (a.soggetto_id_a	=	c.soggetto_id	
                      and	c.validita_fine is null) 
              FULL  join siac_d_via_tipo b1
                      on (b1.via_tipo_id	=	c.via_tipo_id
                          and	b1.ente_proprietario_id	=	c.ente_proprietario_id)  
              FULL  join  siac_t_comune	n	
                  on    	(n.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id)
              FULL  join  siac_r_comune_provincia	o	
                  on    	(o.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id)
              FULL  join  siac_t_provincia	q	
                  on    	(q.provincia_id	=	o.provincia_id
                              and	q.ente_proprietario_id	=	o.ente_proprietario_id)
              FULL  join  siac_t_nazione	r	
                  on    	(n.nazione_id	=	r.nazione_id
                              and	r.ente_proprietario_id	=	n.ente_proprietario_id)  
              where a.relaz_tipo_id = b.relaz_tipo_id
              and 	b.relaz_tipo_code ='SEDE_SECONDARIA'
              and 	a.ente_proprietario_id 	= p_ente_prop_id
              and 	b.ente_proprietario_id 	= 	a.ente_proprietario_id
              and	c.ente_proprietario_id 	= 	a.ente_proprietario_id
              and	d.ente_proprietario_id	=	a.ente_proprietario_id;



end if;  
if  p_tipo_estrazione = '1' or p_tipo_estrazione = '4'	THEN
	insert into siac_rep_persona_fisica_modpag
    select
        	a.soggetto_id,	
    		a.soggetto_desc,
            0,
            ' ',
            ' ',
            ' ',   
            b.modpag_id, 
            b.accredito_tipo_id, 
			c.accredito_tipo_code, 
            c.accredito_tipo_desc, 
            d.modpag_stato_code, 
            d.modpag_stato_desc,
            ' ',
            ' ',
            ' ',
            a.ente_proprietario_id,
            user_table utente,
            a.soggetto_code,
            b.quietanziante,
            b.quietanziante_codice_fiscale,
            b.iban,
            b.bic,
            b.contocorrente,
            b.data_scadenza,
            NULL  
        from 	siac_t_soggetto a,
    			siac_t_modpag b ,
            	siac_d_accredito_tipo c, 
            	siac_d_modpag_stato d, 
				siac_r_modpag_stato e
        where a.ente_proprietario_id = p_ente_prop_id
        and	a.ente_proprietario_id=b.ente_proprietario_id
        and	c.ente_proprietario_id=a.ente_proprietario_id
        and	d.ente_proprietario_id=a.ente_proprietario_id
        and	e.ente_proprietario_id=a.ente_proprietario_id
        and a.soggetto_id = b.soggetto_id
        and b.accredito_tipo_id = c.accredito_tipo_id
        and e.modpag_id = b.modpag_id
        and	e.modpag_stato_id	=	d.modpag_stato_id      
   union  
    select 
           	a.soggetto_id_da,
            d.soggetto_desc,
            a.soggetto_id_a,
            x.soggetto_desc,
            x.codice_fiscale,
            x.partita_iva,
            0,
            a.relaz_tipo_id,
 			c.relaz_tipo_code,
        	c.relaz_tipo_desc,
 			g.relaz_stato_code,
        	g.relaz_stato_desc,
        	b.note,
        	f.accredito_tipo_code,
        	f.accredito_tipo_desc,
        	a.ente_proprietario_id,
            user_table utente,
        	d.soggetto_code,
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            NULL,
            e.data_scadenza
    from 		siac_r_soggetto_relaz a, 
    			siac_r_soggrel_modpag b, 
                siac_d_relaz_tipo c,
  				siac_t_soggetto d, 
                siac_t_modpag e, 
                siac_d_accredito_tipo f,
 				siac_d_relaz_stato g, 
				siac_r_soggetto_relaz_stato h, 
                siac_t_soggetto x
	where 	b.soggetto_relaz_id		= 	a.soggetto_relaz_id
		and a.relaz_tipo_id			= 	c.relaz_tipo_id
		and a.soggetto_id_da 		=	d.soggetto_id
        and	b.modpag_id				=	e.modpag_id
        and	e.accredito_tipo_id		=	f.accredito_tipo_id
        and h.soggetto_relaz_id		=	b.soggetto_relaz_id
        and	h.relaz_stato_id		=	g.relaz_stato_id
        and a.soggetto_id_a			=	x.soggetto_id
        and d.ente_proprietario_id	=	p_ente_prop_id
        and	a.ente_proprietario_id	=	d.ente_proprietario_id
        and b.ente_proprietario_id	=	d.ente_proprietario_id
        and c.ente_proprietario_id	=	d.ente_proprietario_id
        and e.ente_proprietario_id	=	d.ente_proprietario_id
        and f.ente_proprietario_id	=	d.ente_proprietario_id
        and g.ente_proprietario_id	=	d.ente_proprietario_id
        and h.ente_proprietario_id	=	d.ente_proprietario_id;
end if;

for dati_soggetto in 
	select 	a.ambito_id					ambito_id,
    		a.soggetto_code				soggetto_code,
            a.codice_fiscale			codice_fiscale,
            a.codice_fiscale_estero		codice_fiscale_estero, 
            a.partita_iva				partita_iva, 
            a.soggetto_desc				soggetto_desc, 
            a.soggetto_tipo_code		soggetto_tipo_code, 
            a.soggetto_tipo_desc		soggetto_tipo_desc,
            a.forma_giuridica_cat_id	forma_giuridica_cat_id,
            a.forma_giuridica_desc		forma_giuridica_desc,
            a.forma_giuridica_istat_codice	forma_giuridica_istat_codice,
            a.cognome					cognome,
            a.nome						nome,  
            a.comune_id_nascita			comune_id_nascita, 
            a.nascita_data				nascita_data,
            a.sesso						sesso,
            a.comune_desc 				comune_desc,
            a.comune_istat_code 		comune_istat_code,
            coalesce (a.provincia_desc,DEF_SPACES)				provincia_desc,
            coalesce (a.sigla_automobilistica,DEF_SPACES)		sigla_automobilistica,
            coalesce (a.nazione_desc,DEF_SPACES)				nazione_desc, 
            a.soggetto_id				soggetto_id,
            a.stato						stato,
            a.classe_soggetto			classe_soggetto,
            b.tipo_indirizzo			tipo_indirizzo,		
            coalesce (b.via,DEF_SPACES)						via_indirizzo,
            coalesce (b.toponimo,DEF_SPACES)					toponimo_indirizzo, 
            coalesce (b.numero_civico,DEF_SPACES)				numero_civico_indirizzo,
            coalesce (b.interno,DEF_SPACES)						interno_indirizzo,
            coalesce (b.frazione,DEF_SPACES)					frazione_indirizzo,
            coalesce (b.comune,DEF_SPACES)						comune_indirizzo,
            coalesce (b.provincia_desc_sede,DEF_SPACES)			provincia_indirizzo,
            coalesce (b.provincia_sigla,DEF_SPACES)				provincia_sigla_indirizzo,
            coalesce (b.stato_sede,DEF_SPACES)					stato_indirizzo,
            b.avviso					avviso,
            b.desc_tipo_indirizzo		desc_tipo_indirizzo,
            b.indirizzo_id				indirizzo_id,
            c.indirizzo_id_sede			sede_indirizzo_id,
            coalesce (c.via_sede,DEF_SPACES)					sede_via_indirizzo,
        	coalesce (c.toponimo_sede,DEF_SPACES)				sede_toponimo_indirizzo,					
            coalesce (c.numero_civico_sede,DEF_SPACES)			sede_numero_civico_indirizzo,
            coalesce (c.interno_sede,DEF_SPACES)				sede_interno_indirizzo,
            coalesce (c.frazione_sede,DEF_SPACES)				sede_frazione_indirizzo,
            coalesce (c.comune_sede,DEF_SPACES)					sede_comune_indirizzo,
            coalesce (c.provincia_desc_sede,DEF_SPACES)			sede_provincia_indirizzo,
            coalesce (c.provincia_sigla_sede,DEF_SPACES)		sede_provincia_sigla_indirizzo,
            coalesce (c.stato_sede,DEF_SPACES)					sede_stato_indirizzo,
            d.soggetto_id				mp_soggetto_id,
            d.soggetto_desc				mp_soggetto_desc,
            d.accredito_tipo_code		mp_accredito_tipo_code,
            d.accredito_tipo_desc		mp_accredito_tipo_desc,
            d.modpag_stato_desc			mp_modpag_stato_desc,
            coalesce (d.soggetto_ricevente_desc,DEF_SPACES)			ricevente,
            coalesce (d.soggetto_ricevente_cod_fis,DEF_SPACES)		ricevente_cod_fis,
            coalesce (d.soggetto_ricevente_piva ,DEF_SPACES)		ricevente_piva,		
            coalesce (d.accredito_ricevente_tipo_code,DEF_SPACES)	accredito_tipo_code,
            coalesce (d.accredito_ricevente_tipo_desc,DEF_SPACES)	accredito_tipo_desc,
          	coalesce (d.note,DEF_SPACES)							note,
            coalesce (d.quietanzante,DEF_SPACES)					quietanzante,
            coalesce (d.quietanzante_codice_fiscale,DEF_SPACES)		quietanzante_cod_fis,
            coalesce (d.bic,DEF_SPACES)								bic,
            coalesce (d.conto_corrente,DEF_SPACES)					conto_corrente,
            coalesce (d.iban,DEF_SPACES)							iban,
            d.mp_data_scadenza										mp_data_scadenza,
            d.data_scadenza_cessione								data_scadenza_cessione	
            
    from siac_rep_persona_fisica	a
    LEFT join	siac_rep_persona_fisica_recapiti b   
                  on (a.soggetto_id	=	b.soggetto_id
                  	and a.utente	=	user_table
                    and	b.utente	=	user_table)
    LEFT join	siac_rep_persona_fisica_sedi c   
    on (a.soggetto_id	=	c.soggetto_id
    	and a.utente	=	user_table
        and	c.utente	=	user_table)
    LEFT join	siac_rep_persona_fisica_modpag d   
    on (a.soggetto_code	=	d.soggetto_code
    	and a.utente	=	user_table
        and	d.utente	=	user_table)
    --SIAC-6215: 12/06/2018: nel caso la denominazione sia NULL
    --	viene trasformata in ''.
    --where a.soggetto_desc	like '%'|| p_denominazione ||'%'
    where a.soggetto_desc	like '%'|| COALESCE(p_denominazione, DEF_NULL) ||'%'
    order by a.soggetto_desc
    loop
        ambito_id:=dati_soggetto.ambito_id;
        soggetto_code:=dati_soggetto.soggetto_code;
        codice_fiscale:=dati_soggetto.codice_fiscale;
        codice_fiscale_estero:=dati_soggetto.codice_fiscale_estero;
        partita_iva:=dati_soggetto.partita_iva;
        soggetto_desc:=dati_soggetto.soggetto_desc;
        soggetto_tipo_code:=dati_soggetto.soggetto_tipo_code;
        soggetto_tipo_desc:=dati_soggetto.soggetto_tipo_desc;
        cognome:=dati_soggetto.cognome;
        nome:=dati_soggetto.nome;
        comune_id_nascita:=dati_soggetto.comune_id_nascita;
        nascita_data:=dati_soggetto.nascita_data;
        sesso:=dati_soggetto.sesso;
        soggetto_id:=dati_soggetto.soggetto_id;
        comune_desc:=dati_soggetto.comune_desc;
        comune_istat_code:=dati_soggetto.comune_istat_code;
        provincia_desc:=dati_soggetto.provincia_desc;
        sigla_automobilistica:=dati_soggetto.sigla_automobilistica;
        nazione_desc:=dati_soggetto.nazione_desc;
        stato:=dati_soggetto.stato;
        forma_giuridica_cat_id:=dati_soggetto.forma_giuridica_cat_id;
        forma_giuridica_desc:=dati_soggetto.forma_giuridica_desc;
        forma_giuridica_istat_codice:=dati_soggetto.forma_giuridica_istat_codice;
        classe_soggetto:=dati_soggetto.classe_soggetto;   
        tipo_indirizzo:=dati_soggetto.tipo_indirizzo;
  		via_indirizzo:=dati_soggetto.via_indirizzo;
  		toponimo_indirizzo:=dati_soggetto.toponimo_indirizzo;
  		numero_civico_indirizzo:=dati_soggetto.numero_civico_indirizzo;
  		interno_indirizzo:=dati_soggetto.interno_indirizzo;
  		frazione_indirizzo:=dati_soggetto.frazione_indirizzo;
  		comune_indirizzo:=dati_soggetto.comune_indirizzo;
  		provincia_indirizzo:=dati_soggetto.provincia_indirizzo;
  		provincia_sigla_indirizzo:=dati_soggetto.provincia_sigla_indirizzo;
  		stato_indirizzo:=dati_soggetto.stato_indirizzo;
        avviso:=dati_soggetto.avviso;
        indirizzo_id:=dati_soggetto.indirizzo_id;
        desc_tipo_indirizzo:=dati_soggetto.desc_tipo_indirizzo;
        sede_indirizzo_id:=dati_soggetto.sede_indirizzo_id;
        sede_via_indirizzo:=dati_soggetto.sede_via_indirizzo;
       	sede_toponimo_indirizzo:=dati_soggetto.sede_toponimo_indirizzo;					
        sede_numero_civico_indirizzo:=dati_soggetto.sede_numero_civico_indirizzo;
        sede_interno_indirizzo:=dati_soggetto.sede_interno_indirizzo;
        sede_frazione_indirizzo:=dati_soggetto.sede_frazione_indirizzo;
       	sede_comune_indirizzo:=dati_soggetto.sede_comune_indirizzo;
       	sede_provincia_indirizzo:=dati_soggetto.sede_provincia_indirizzo;
        sede_provincia_sigla_indirizzo:=dati_soggetto.sede_provincia_sigla_indirizzo;
        sede_stato_indirizzo:=dati_soggetto.sede_stato_indirizzo;
        mp_soggetto_id:=dati_soggetto.mp_soggetto_id;
        mp_soggetto_desc:=dati_soggetto.mp_soggetto_desc;
        mp_accredito_tipo_code:=dati_soggetto.mp_accredito_tipo_code;
        mp_accredito_tipo_desc:=dati_soggetto.mp_accredito_tipo_desc;
        mp_modpag_stato_desc:=dati_soggetto.mp_modpag_stato_desc;
        ricevente:=dati_soggetto.ricevente;		
        accredito_tipo_code:=dati_soggetto.accredito_tipo_code;
        accredito_tipo_desc:=dati_soggetto.accredito_tipo_desc;
        note:=dati_soggetto.note;
        ricevente_cod_fis:=dati_soggetto.ricevente_cod_fis;
        ricevente_piva:=dati_soggetto.ricevente_piva;
        quietanzante:=dati_soggetto.quietanzante;
        quietanzante_cod_fis:=dati_soggetto.quietanzante_cod_fis;
        bic:=dati_soggetto.bic;
        conto_corrente:=dati_soggetto.conto_corrente;
        iban:=dati_soggetto.iban;
        mp_data_scadenza:=dati_soggetto.mp_data_scadenza;
        data_scadenza_cessione:=dati_soggetto.data_scadenza_cessione;
        ------tipologia_soggetto:=dati_soggetto.tipologia_soggetto;
        return next;
        ambito_id=0;
        soggetto_code='';
        codice_fiscale='';
        codice_fiscale_estero='';
        partita_iva='';
        soggetto_desc='';
        soggetto_tipo_code='';
        soggetto_tipo_desc='';
        cognome='';
       nome='';
        comune_id_nascita=0;
        nascita_data=NULL;
        sesso='';
        soggetto_id=0;
        comune_desc='';
        comune_istat_code='';
        provincia_desc='';
        sigla_automobilistica='';
        nazione_desc='';
        stato='';
        forma_giuridica_cat_id=0;
        forma_giuridica_desc='';
        forma_giuridica_istat_codice='';
        classe_soggetto='';
        tipo_indirizzo='';
  		via_indirizzo='';
  		toponimo_indirizzo='';
  		numero_civico_indirizzo='';
  		interno_indirizzo='';
  		frazione_indirizzo='';
  		comune_indirizzo='';
  		provincia_indirizzo='';
  		provincia_sigla_indirizzo='';
  		stato_indirizzo='';
        avviso='';
        indirizzo_id=0;
        desc_tipo_indirizzo='';
        sede_indirizzo_id=0;
        sede_via_indirizzo='';
       	sede_toponimo_indirizzo='';				
        sede_numero_civico_indirizzo='';
        sede_interno_indirizzo='';
        sede_frazione_indirizzo='';
       	sede_comune_indirizzo='';
       	sede_provincia_indirizzo='';
        sede_provincia_sigla_indirizzo='';
        sede_stato_indirizzo='';
        mp_soggetto_id=0;
        mp_soggetto_desc='';
        mp_accredito_tipo_code='';
        mp_accredito_tipo_desc='';
        mp_modpag_stato_desc='';
        ricevente='';
        accredito_tipo_code='';
        accredito_tipo_desc='';
        note='';
        ricevente_cod_fis='';
        ricevente_piva='';
        quietanzante='';
        quietanzante_cod_fis='';
        bic='';
        conto_corrente='';
        iban='';
        mp_data_scadenza=NULL;
        data_scadenza_cessione=NULL;   
     end loop;
     
 tipologia_soggetto:='PG';      

if coalesce(p_stato_soggetto ,DEF_NULL)=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)=DEF_NULL then
      raise notice '1';
    insert into siac_rep_persona_giuridica
	select 	a.ambito_id,
            a.soggetto_code,
            a.codice_fiscale,
            a.codice_fiscale_estero,
            a.partita_iva,
            b.ragione_sociale,
            d.soggetto_tipo_code,
            d.soggetto_tipo_desc,
            m.forma_giuridica_cat_id,
            m.forma_giuridica_desc,
            m.forma_giuridica_istat_codice,
            a.soggetto_id,
            f.soggetto_stato_desc,
            h.soggetto_classe_desc,
            b.ente_proprietario_id,
            user_table utente                 
    from 	
            siac_r_soggetto_tipo 	c, 
            siac_d_soggetto_tipo 	d,
            siac_r_soggetto_stato	e,
            siac_d_soggetto_stato	f,
            siac_t_soggetto 		a,
            siac_t_persona_giuridica 	b
            FULL  join siac_r_soggetto_classe	g
            on    	(b.soggetto_id		=	g.soggetto_id
                        and	g.ente_proprietario_id	=	b.ente_proprietario_id
                        and	g.validita_fine	is null)
            FULL  join  siac_d_soggetto_classe	h	
            on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                        and	h.ente_proprietario_id	=	g.ente_proprietario_id
                        and	h.validita_fine	is null)
            FULL  join  siac_r_forma_giuridica	p	
            on    	(b.soggetto_id			=	p.soggetto_id
                        and	p.ente_proprietario_id	=	b.ente_proprietario_id)
            FULL  join  siac_t_forma_giuridica	m	
            on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                        and	p.ente_proprietario_id	=	m.ente_proprietario_id
                        and	p.validita_fine	is null)      
            WHERE	a.ente_proprietario_id	=	p_ente_prop_id
            and		b.ente_proprietario_id	=	a.ente_proprietario_id
            and		c.ente_proprietario_id	=	a.ente_proprietario_id
            and		d.ente_proprietario_id	=	a.ente_proprietario_id
            and		e.ente_proprietario_id	=	a.ente_proprietario_id
            and		f.ente_proprietario_id	=	a.ente_proprietario_id
            and		a.soggetto_id			=	b.soggetto_id
            and		c.soggetto_id			=	b.soggetto_id
            and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
            and		e.soggetto_id			=	b.soggetto_id
            and		e.soggetto_stato_id		=	f.soggetto_stato_id
            and		a.validita_fine			is null
            and		b.validita_fine			is null
            and		e.validita_fine			is null
            and		c.validita_fine			is null
            and		d.validita_fine			is null
            and		e.validita_fine			is null
            and		f.validita_fine			is null;		
ELSE
	if coalesce(p_stato_soggetto ,DEF_NULL)!=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)=DEF_NULL then
              raise notice '2';
        insert into siac_rep_persona_giuridica
        select 	a.ambito_id,
                a.soggetto_code,
                a.codice_fiscale,
                a.codice_fiscale_estero,
                a.partita_iva,
                b.ragione_sociale,
                d.soggetto_tipo_code,
                d.soggetto_tipo_desc,
                m.forma_giuridica_cat_id,
                m.forma_giuridica_desc,
                m.forma_giuridica_istat_codice,
                a.soggetto_id,
                f.soggetto_stato_desc,
                h.soggetto_classe_desc,
                b.ente_proprietario_id,
                user_table utente                 
    from 	
            siac_r_soggetto_tipo 	c, 
            siac_d_soggetto_tipo 	d,
            siac_r_soggetto_stato	e,
            siac_d_soggetto_stato	f,
            siac_t_soggetto 		a,
            siac_t_persona_giuridica 	b
            FULL  join siac_r_soggetto_classe	g
            on    	(b.soggetto_id		=	g.soggetto_id
                        and	g.ente_proprietario_id	=	b.ente_proprietario_id
                        and	g.validita_fine	is null)
            FULL  join  siac_d_soggetto_classe	h	
            on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                        and	h.ente_proprietario_id	=	g.ente_proprietario_id
                        and	h.validita_fine	is null)
            FULL  join  siac_r_forma_giuridica	p	
            on    	(b.soggetto_id			=	p.soggetto_id
                        and	p.ente_proprietario_id	=	b.ente_proprietario_id)
            FULL  join  siac_t_forma_giuridica	m	
            on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                        and	p.ente_proprietario_id	=	m.ente_proprietario_id
                        and	p.validita_fine	is null)      
                WHERE	a.ente_proprietario_id	=	p_ente_prop_id
                and		b.ente_proprietario_id	=	a.ente_proprietario_id
                and		c.ente_proprietario_id	=	a.ente_proprietario_id
                and		d.ente_proprietario_id	=	a.ente_proprietario_id
                and		e.ente_proprietario_id	=	a.ente_proprietario_id
                and		f.ente_proprietario_id	=	a.ente_proprietario_id
                and		a.soggetto_id			=	b.soggetto_id
                and		c.soggetto_id			=	b.soggetto_id
                and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
                and		e.soggetto_id			=	b.soggetto_id
                and		e.soggetto_stato_id		=	f.soggetto_stato_id
               	and		f.soggetto_stato_desc	=	p_stato_soggetto
                and		a.validita_fine			is null
                and		b.validita_fine			is null
                and		e.validita_fine			is null
                and		c.validita_fine			is null
                and		d.validita_fine			is null
                and		e.validita_fine			is null
                and		f.validita_fine			is null;		
     ELSE
     	if coalesce(p_stato_soggetto ,DEF_NULL)=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)!=DEF_NULL then
             raise notice 'classe diversa da null';
            insert into siac_rep_persona_giuridica
	select 		a.ambito_id,
                a.soggetto_code,
                a.codice_fiscale,
                a.codice_fiscale_estero,
                a.partita_iva,
                b.ragione_sociale,
                d.soggetto_tipo_code,
                d.soggetto_tipo_desc,
                m.forma_giuridica_cat_id,
                m.forma_giuridica_desc,
                m.forma_giuridica_istat_codice,
                a.soggetto_id,
                f.soggetto_stato_desc,
                h.soggetto_classe_desc,
                b.ente_proprietario_id,
                user_table utente                
    from 	
            siac_r_soggetto_tipo 	c, 
            siac_d_soggetto_tipo 	d,
            siac_r_soggetto_stato	e,
            siac_d_soggetto_stato	f,
            siac_t_soggetto 		a,
            siac_t_persona_fisica 	b
            FULL  join siac_r_soggetto_classe	g
            on    	(b.soggetto_id		=	g.soggetto_id
                        and	g.ente_proprietario_id	=	b.ente_proprietario_id
                        and	g.validita_fine	is null)
            RIGHT  join  siac_d_soggetto_classe	h	
            on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
            			AND	H.soggetto_classe_desc	=	p_classe_soggetto
                        and	h.ente_proprietario_id	=	g.ente_proprietario_id
                        and	h.validita_fine	is null)
            FULL  join  siac_r_forma_giuridica	p	
            on    	(b.soggetto_id			=	p.soggetto_id
                        and	p.ente_proprietario_id	=	b.ente_proprietario_id)
            FULL  join  siac_t_forma_giuridica	m	
            on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                        and	p.ente_proprietario_id	=	m.ente_proprietario_id
                        and	p.validita_fine	is null)          
            WHERE	a.ente_proprietario_id	=	p_ente_prop_id
            and		b.ente_proprietario_id	=	a.ente_proprietario_id
            and		c.ente_proprietario_id	=	a.ente_proprietario_id
            and		d.ente_proprietario_id	=	a.ente_proprietario_id
            and		e.ente_proprietario_id	=	a.ente_proprietario_id
            and		f.ente_proprietario_id	=	a.ente_proprietario_id
            and		a.soggetto_id			=	b.soggetto_id
            and		c.soggetto_id			=	b.soggetto_id
            and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
            and		e.soggetto_id			=	b.soggetto_id
            and		e.soggetto_stato_id		=	f.soggetto_stato_id
            and		a.validita_fine			is null
            and		b.validita_fine			is null
            and		e.validita_fine			is null
            and		c.validita_fine			is null
            and		d.validita_fine			is null
            and		e.validita_fine			is null
            and		f.validita_fine			is null;		
            		
      else  
      		      raise notice '3';
            insert into siac_rep_persona_giuridica
            select 	a.ambito_id,
                    a.soggetto_code,
                    a.codice_fiscale,
                    a.codice_fiscale_estero,
                    a.partita_iva,
                    b.ragione_sociale,
                    d.soggetto_tipo_code,
                    d.soggetto_tipo_desc,
                    m.forma_giuridica_cat_id,
                    m.forma_giuridica_desc,
                    m.forma_giuridica_istat_codice,
                    a.soggetto_id,
                    f.soggetto_stato_desc,
                    h.soggetto_classe_desc,
                    b.ente_proprietario_id,
                    user_table utente           
            from 	
                    siac_r_soggetto_tipo 	c, 
                    siac_d_soggetto_tipo 	d,
                    siac_r_soggetto_stato	e,
                    siac_d_soggetto_stato	f,
                    siac_t_soggetto 		a,
                    siac_t_persona_fisica 	b
                    FULL  join siac_r_soggetto_classe	g
                    on    	(b.soggetto_id		=	g.soggetto_id
                                and	g.ente_proprietario_id	=	b.ente_proprietario_id
                                and	g.validita_fine	is null)
                    RIGHT  join  siac_d_soggetto_classe	h	
                    on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                    			and	h.soggetto_classe_desc	=	p_classe_soggetto
                                and	h.ente_proprietario_id	=	g.ente_proprietario_id
                                and	h.validita_fine	is null)
                    FULL  join  siac_r_forma_giuridica	p	
                    on    	(b.soggetto_id			=	p.soggetto_id
                                and	p.ente_proprietario_id	=	b.ente_proprietario_id)
                    FULL  join  siac_t_forma_giuridica	m	
                    on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                                and	p.ente_proprietario_id	=	m.ente_proprietario_id
                                and	p.validita_fine	is null)
                    WHERE	a.ente_proprietario_id	=	p_ente_prop_id
                    and		b.ente_proprietario_id	=	a.ente_proprietario_id
                    and		c.ente_proprietario_id	=	a.ente_proprietario_id
                    and		d.ente_proprietario_id	=	a.ente_proprietario_id
                    and		e.ente_proprietario_id	=	a.ente_proprietario_id
                    and		f.ente_proprietario_id	=	a.ente_proprietario_id
                    and		a.soggetto_id			=	b.soggetto_id
                    and		c.soggetto_id			=	b.soggetto_id
                    and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
                    and		e.soggetto_id			=	b.soggetto_id
                    and		e.soggetto_stato_id		=	f.soggetto_stato_id
                    and		f.soggetto_stato_desc	=	p_stato_soggetto
                    and		a.validita_fine			is null
                    and		b.validita_fine			is null
                    and		e.validita_fine			is null
                    and		c.validita_fine			is null
                    and		d.validita_fine			is null
                    and		e.validita_fine			is null
                    and		f.validita_fine			is null;	      
      end if;    
	end if;
end if;



if  p_tipo_estrazione = '1' or p_tipo_estrazione = '3'	THEN
      		      raise notice '4';
      insert into siac_rep_persona_giuridica_recapiti
     select	d.soggetto_id,				
   				c.principale,			
                b1.via_tipo_desc,			
                c.toponimo,					
                c.numero_civico,			
                c.interno,				
                c.frazione,				
                n.comune_desc,				
                q.provincia_desc,			
                q.sigla_automobilistica,		
                r.nazione_desc,		
                c.avviso,			
                d.ente_proprietario_id,
                user_table utente,
                e.indirizzo_tipo_desc,
                c.indirizzo_id	
 from	  siac_t_persona_giuridica d
              full join	siac_t_indirizzo_soggetto c   
                  on (d.soggetto_id	=	c.soggetto_id
                      and	d.validita_fine	is null) 
              full join siac_r_indirizzo_soggetto_tipo	a
              		on (c.indirizzo_id	=	a.indirizzo_id
                    	and	c.ente_proprietario_id	=	a.ente_proprietario_id
                        and	a.validita_fine	is NULL)
              full join siac_d_indirizzo_tipo	e
              		on (e.indirizzo_tipo_id	=	a.indirizzo_tipo_id
                    	and	e.ente_proprietario_id	=	a.ente_proprietario_id
                        and	e.validita_fine	is null)              
              FULL  join siac_d_via_tipo b1
                      on (b1.via_tipo_id	=	c.via_tipo_id
                          and	b1.ente_proprietario_id	=	c.ente_proprietario_id
                          and	b1.validita_fine is null)  
              FULL  join  siac_t_comune	n	
                  on    	(n.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id
                              and	n.validita_fine	is null)
              FULL  join  siac_r_comune_provincia	o	
                  on    	(o.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id
                              and	o.validita_fine	is null)
              FULL  join  siac_t_provincia	q	
                  on    	(q.provincia_id	=	o.provincia_id
                              and	q.ente_proprietario_id	=	o.ente_proprietario_id
                              and	q.validita_fine	is null)
              FULL  join  siac_t_nazione	r	
                  on    	(n.nazione_id	=	r.nazione_id
                              and	r.ente_proprietario_id	=	n.ente_proprietario_id
                              and	r.validita_fine	is null)  
              where 
                      d.ente_proprietario_id 	= p_ente_prop_id
              and		c.ente_proprietario_id 	= 	d.ente_proprietario_id;
end if;  


if  p_tipo_estrazione = '1' or p_tipo_estrazione = '3'	THEN
      		      raise notice '5';
      insert into siac_rep_persona_giuridica_sedi
      select		d.soggetto_id,	
                  ----c.								denominazione,	
                  b1.via_tipo_desc,
                  c.toponimo,
                  c.numero_civico,
                  c.interno,
                  c.frazione,
                  n.comune_desc,
                  q.provincia_desc,
                  q.sigla_automobilistica,
                  r.nazione_desc,
                  '',
                  c.indirizzo_id,
                  d.ente_proprietario_id,
                  user_table utente             
      from 	siac_d_relaz_tipo b, 
              siac_r_soggetto_relaz a  
              RIGHT join	siac_t_persona_fisica d
                  on (		d.soggetto_id	=	a.soggetto_id_da
                      and	d.validita_fine	is null)
              full join siac_t_indirizzo_soggetto c
                  on (a.soggetto_id_a	=	c.soggetto_id	
                      and	c.validita_fine is null) 
              FULL  join siac_d_via_tipo b1
                      on (b1.via_tipo_id	=	c.via_tipo_id
                          and	b1.ente_proprietario_id	=	c.ente_proprietario_id)  
              FULL  join  siac_t_comune	n	
                  on    	(n.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id)
              FULL  join  siac_r_comune_provincia	o	
                  on    	(o.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id)
              FULL  join  siac_t_provincia	q	
                  on    	(q.provincia_id	=	o.provincia_id
                              and	q.ente_proprietario_id	=	o.ente_proprietario_id)
              FULL  join  siac_t_nazione	r	
                  on    	(n.nazione_id	=	r.nazione_id
                              and	r.ente_proprietario_id	=	n.ente_proprietario_id)  
              where a.relaz_tipo_id = b.relaz_tipo_id
              and 	b.relaz_tipo_code ='SEDE_SECONDARIA'
              and 	a.ente_proprietario_id 	= p_ente_prop_id
              and 	b.ente_proprietario_id 	= 	a.ente_proprietario_id
              and	c.ente_proprietario_id 	= 	a.ente_proprietario_id
              and	d.ente_proprietario_id	=	a.ente_proprietario_id;



end if;  
if  p_tipo_estrazione = '1' or p_tipo_estrazione = '4'	THEN
	insert into siac_rep_persona_giuridica_modpag
       select
        	a.soggetto_id,	
    		a.soggetto_desc,
            0,
            ' ',
            ' ',
            ' ',   
            b.modpag_id, 
            b.accredito_tipo_id, 
			c.accredito_tipo_code, 
            c.accredito_tipo_desc, 
            d.modpag_stato_code, 
            d.modpag_stato_desc,
            ' ',
            ' ',
            ' ',
            a.ente_proprietario_id,
            user_table utente,
            a.soggetto_code,
            b.quietanziante,
            b.quietanziante_codice_fiscale,
            b.iban,
            b.bic,
            b.contocorrente,
            b.data_scadenza,
            NULL 
        from 	siac_t_soggetto a,
    			siac_t_modpag b ,
            	siac_d_accredito_tipo c, 
            	siac_d_modpag_stato d, 
				siac_r_modpag_stato e
        where a.ente_proprietario_id = p_ente_prop_id
        and	a.ente_proprietario_id=b.ente_proprietario_id
        and	c.ente_proprietario_id=a.ente_proprietario_id
        and	d.ente_proprietario_id=a.ente_proprietario_id
        and	e.ente_proprietario_id=a.ente_proprietario_id
        and a.soggetto_id = b.soggetto_id
        and b.accredito_tipo_id = c.accredito_tipo_id
        and e.modpag_id = b.modpag_id
        and	e.modpag_stato_id	=	d.modpag_stato_id      
   union  
    select 
           	a.soggetto_id_da,
            d.soggetto_desc,
            a.soggetto_id_a,
            x.soggetto_desc,
            x.codice_fiscale,
            x.partita_iva,
            0,
            a.relaz_tipo_id,
 			c.relaz_tipo_code,
        	c.relaz_tipo_desc,
 			g.relaz_stato_code,
        	g.relaz_stato_desc,
        	b.note,
        	f.accredito_tipo_code,
        	f.accredito_tipo_desc,
        	a.ente_proprietario_id,
            user_table utente,
        	d.soggetto_code,
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            NULL,
            e.data_scadenza 
    from 		siac_r_soggetto_relaz a, 
    			siac_r_soggrel_modpag b, 
                siac_d_relaz_tipo c,
  				siac_t_soggetto d, 
                siac_t_modpag e, 
                siac_d_accredito_tipo f,
 				siac_d_relaz_stato g, 
				siac_r_soggetto_relaz_stato h, 
                siac_t_soggetto x
	where 	b.soggetto_relaz_id		= 	a.soggetto_relaz_id
		and a.relaz_tipo_id			= 	c.relaz_tipo_id
		and a.soggetto_id_da 		=	d.soggetto_id
        and	b.modpag_id				=	e.modpag_id
        and	e.accredito_tipo_id		=	f.accredito_tipo_id
        and h.soggetto_relaz_id		=	b.soggetto_relaz_id
        and	h.relaz_stato_id		=	g.relaz_stato_id
        and a.soggetto_id_a			=	x.soggetto_id
        and d.ente_proprietario_id	=	p_ente_prop_id
        and	a.ente_proprietario_id	=	d.ente_proprietario_id
        and b.ente_proprietario_id	=	d.ente_proprietario_id
        and c.ente_proprietario_id	=	d.ente_proprietario_id
        and e.ente_proprietario_id	=	d.ente_proprietario_id
        and f.ente_proprietario_id	=	d.ente_proprietario_id
        and g.ente_proprietario_id	=	d.ente_proprietario_id
        and h.ente_proprietario_id	=	d.ente_proprietario_id;
end if;

for dati_soggetto in 
	select 	a.ambito_id					ambito_id,
    		a.soggetto_code				soggetto_code,
            a.codice_fiscale			codice_fiscale,
            a.codice_fiscale_estero		codice_fiscale_estero, 
            a.partita_iva				partita_iva, 
            a.soggetto_desc				soggetto_desc, 
            a.soggetto_tipo_code		soggetto_tipo_code, 
            a.soggetto_tipo_desc		soggetto_tipo_desc,
            a.forma_giuridica_cat_id	forma_giuridica_cat_id,
            a.forma_giuridica_desc		forma_giuridica_desc,
            a.forma_giuridica_istat_codice	forma_giuridica_istat_codice,
            a.soggetto_id				soggetto_id,
            a.stato						stato,
            a.classe_soggetto			classe_soggetto,
            b.tipo_indirizzo			tipo_indirizzo,		
            coalesce (b.via,DEF_SPACES)						via_indirizzo,
            coalesce (b.toponimo,DEF_SPACES)					toponimo_indirizzo, 
            coalesce (b.numero_civico,DEF_SPACES)				numero_civico_indirizzo,
            coalesce (b.interno,DEF_SPACES)						interno_indirizzo,
            coalesce (b.frazione,DEF_SPACES)					frazione_indirizzo,
            coalesce (b.comune,DEF_SPACES)						comune_indirizzo,
            coalesce (b.provincia_desc_sede,DEF_SPACES)			provincia_indirizzo,
            coalesce (b.provincia_sigla,DEF_SPACES)				provincia_sigla_indirizzo,
            coalesce (b.stato_sede,DEF_SPACES)					stato_indirizzo,
            b.avviso					avviso,
            b.desc_tipo_indirizzo		desc_tipo_indirizzo,
            b.indirizzo_id				indirizzo_id,
            c.indirizzo_id_sede			sede_indirizzo_id,
            coalesce (c.via_sede,DEF_SPACES)					sede_via_indirizzo,
        	coalesce (c.toponimo_sede,DEF_SPACES)				sede_toponimo_indirizzo,					
            coalesce (c.numero_civico_sede,DEF_SPACES)			sede_numero_civico_indirizzo,
            coalesce (c.interno_sede,DEF_SPACES)				sede_interno_indirizzo,
            coalesce (c.frazione_sede,DEF_SPACES)				sede_frazione_indirizzo,
            coalesce (c.comune_sede,DEF_SPACES)					sede_comune_indirizzo,
            coalesce (c.provincia_desc_sede,DEF_SPACES)			sede_provincia_indirizzo,
            coalesce (c.provincia_sigla_sede,DEF_SPACES)		sede_provincia_sigla_indirizzo,
            coalesce (c.stato_sede,DEF_SPACES)					sede_stato_indirizzo,
           	d.soggetto_id				mp_soggetto_id,
            d.soggetto_desc				mp_soggetto_desc,
            d.accredito_tipo_code		mp_accredito_tipo_code,
            d.accredito_tipo_desc		mp_accredito_tipo_desc,
            d.modpag_stato_desc			mp_modpag_stato_desc,
            coalesce (d.soggetto_ricevente_desc,DEF_SPACES)			ricevente,
            coalesce (d.soggetto_ricevente_cod_fis,DEF_SPACES)		ricevente_cod_fis,
            coalesce (d.soggetto_ricevente_piva ,DEF_SPACES)		ricevente_piva,		
            coalesce (d.accredito_ricevente_tipo_code,DEF_SPACES)	accredito_tipo_code,
            coalesce (d.accredito_ricevente_tipo_desc,DEF_SPACES)	accredito_tipo_desc,
          	coalesce (d.note,DEF_SPACES)							note,
            coalesce (d.quietanzante,DEF_SPACES)					quietanzante,
            coalesce (d.quietanzante_codice_fiscale,DEF_SPACES)		quietanzante_cod_fis,
            coalesce (d.bic,DEF_SPACES)								bic,
            coalesce (d.conto_corrente,DEF_SPACES)					conto_corrente,
            coalesce (d.iban,DEF_SPACES)							iban,
            d.mp_data_scadenza										mp_data_scadenza,
            d.data_scadenza_cessione								data_scadenza_cessione      
    from siac_rep_persona_giuridica	a
    LEFT join	siac_rep_persona_giuridica_recapiti b   
    on (a.soggetto_id	=	b.soggetto_id
       and 	a.utente	=	user_table
       and	b.utente	=	user_table)
    LEFT join	siac_rep_persona_giuridica_sedi c   
    on (a.soggetto_id	=	c.soggetto_id
    	and a.utente	=	user_table
        and	c.utente	=	user_table)
    LEFT join	siac_rep_persona_giuridica_modpag d   
    on (a.soggetto_code	=	d.soggetto_code
    	and a.utente	=	user_table
        and	d.utente	=	user_table)
    --SIAC-6215: 12/06/2018: nel caso la denominazione sia NULL
    --	viene trasformata in ''.
    --where a.soggetto_desc	like '%'|| p_denominazione ||'%'
    where a.soggetto_desc	like '%'|| COALESCE(p_denominazione, DEF_NULL) ||'%'
    
    order by a.soggetto_desc	
    loop
        ambito_id:=dati_soggetto.ambito_id;
        soggetto_code:=dati_soggetto.soggetto_code;
        codice_fiscale:=dati_soggetto.codice_fiscale;
        codice_fiscale_estero:=dati_soggetto.codice_fiscale_estero;
        partita_iva:=dati_soggetto.partita_iva;
        soggetto_desc:=dati_soggetto.soggetto_desc;
        soggetto_tipo_code:=dati_soggetto.soggetto_tipo_code;
        soggetto_tipo_desc:=dati_soggetto.soggetto_tipo_desc;
        soggetto_id:=dati_soggetto.soggetto_id;
        stato:=dati_soggetto.stato;
        forma_giuridica_cat_id:=dati_soggetto.forma_giuridica_cat_id;
        forma_giuridica_desc:=dati_soggetto.forma_giuridica_desc;
        forma_giuridica_istat_codice:=dati_soggetto.forma_giuridica_istat_codice;
        classe_soggetto:=dati_soggetto.classe_soggetto;   
        tipo_indirizzo:=dati_soggetto.tipo_indirizzo;
  		via_indirizzo:=dati_soggetto.via_indirizzo;
  		toponimo_indirizzo:=dati_soggetto.toponimo_indirizzo;
  		numero_civico_indirizzo:=dati_soggetto.numero_civico_indirizzo;
  		interno_indirizzo:=dati_soggetto.interno_indirizzo;
  		frazione_indirizzo:=dati_soggetto.frazione_indirizzo;
  		comune_indirizzo:=dati_soggetto.comune_indirizzo;
  		provincia_indirizzo:=dati_soggetto.provincia_indirizzo;
  		provincia_sigla_indirizzo:=dati_soggetto.provincia_sigla_indirizzo;
  		stato_indirizzo:=dati_soggetto.stato_indirizzo;
        avviso:=dati_soggetto.avviso;
        indirizzo_id:=dati_soggetto.indirizzo_id;
        desc_tipo_indirizzo:=dati_soggetto.desc_tipo_indirizzo;
        sede_indirizzo_id:=dati_soggetto.sede_indirizzo_id;
        sede_via_indirizzo:=dati_soggetto.sede_via_indirizzo;
       	sede_toponimo_indirizzo:=dati_soggetto.sede_toponimo_indirizzo;					
        sede_numero_civico_indirizzo:=dati_soggetto.sede_numero_civico_indirizzo;
        sede_interno_indirizzo:=dati_soggetto.sede_interno_indirizzo;
        sede_frazione_indirizzo:=dati_soggetto.sede_frazione_indirizzo;
       	sede_comune_indirizzo:=dati_soggetto.sede_comune_indirizzo;
       	sede_provincia_indirizzo:=dati_soggetto.sede_provincia_indirizzo;
        sede_provincia_sigla_indirizzo:=dati_soggetto.sede_provincia_sigla_indirizzo;
        sede_stato_indirizzo:=dati_soggetto.sede_stato_indirizzo;
         mp_soggetto_id:=dati_soggetto.mp_soggetto_id;
        mp_soggetto_desc:=dati_soggetto.mp_soggetto_desc;
        mp_accredito_tipo_code:=dati_soggetto.mp_accredito_tipo_code;
        mp_accredito_tipo_desc:=dati_soggetto.mp_accredito_tipo_desc;
        mp_modpag_stato_desc:=dati_soggetto.mp_modpag_stato_desc;
        ricevente:=dati_soggetto.ricevente;		
        accredito_tipo_code:=dati_soggetto.accredito_tipo_code;
        accredito_tipo_desc:=dati_soggetto.accredito_tipo_desc;
        note:=dati_soggetto.note;
        ricevente_cod_fis:=dati_soggetto.ricevente_cod_fis;
        ricevente_piva:=dati_soggetto.ricevente_piva;
        quietanzante:=dati_soggetto.quietanzante;
        quietanzante_cod_fis:=dati_soggetto.quietanzante_cod_fis;
        bic:=dati_soggetto.bic;
        conto_corrente:=dati_soggetto.conto_corrente;
        iban:=dati_soggetto.iban;
        mp_data_scadenza:=dati_soggetto.mp_data_scadenza;
        data_scadenza_cessione:=dati_soggetto.data_scadenza_cessione;
        -------tipologia_soggetto:=dati_soggetto.tipologia_soggetto;
        return next;
        ambito_id=0;
        soggetto_code='';
        codice_fiscale='';
     	codice_fiscale_estero='';
        partita_iva='';
        soggetto_desc='';
        soggetto_tipo_code='';
        soggetto_tipo_desc='';
        soggetto_id=0;
        stato='';
        forma_giuridica_cat_id=0;
        forma_giuridica_desc='';
        forma_giuridica_istat_codice='';
        classe_soggetto='';
        tipo_indirizzo='';
  		via_indirizzo='';
  		toponimo_indirizzo='';
  		numero_civico_indirizzo='';
  		interno_indirizzo='';
  		frazione_indirizzo='';
  		comune_indirizzo='';
  		provincia_indirizzo='';
  		provincia_sigla_indirizzo='';
  		stato_indirizzo='';
        avviso='';
       indirizzo_id=0;
        desc_tipo_indirizzo='';
        sede_indirizzo_id=0;
        sede_via_indirizzo='';
       	sede_toponimo_indirizzo='';
        sede_numero_civico_indirizzo='';
        sede_interno_indirizzo='';
        sede_frazione_indirizzo='';
       	sede_comune_indirizzo='';
       	sede_provincia_indirizzo='';
        sede_provincia_sigla_indirizzo='';
        sede_stato_indirizzo='';
        mp_soggetto_id=0;
        mp_soggetto_desc='';
        mp_accredito_tipo_code='';
        mp_accredito_tipo_desc='';
        mp_modpag_stato_desc='';
        ricevente='';
        accredito_tipo_code='';
        accredito_tipo_desc='';
       	note='';
        ricevente_cod_fis='';
        ricevente_piva='';
        quietanzante='';
        quietanzante_cod_fis='';
        bic='';
        conto_corrente='';
        iban='';
        mp_data_scadenza=NULL;
        data_scadenza_cessione=NULL;
     end loop;


  raise notice 'fine OK';
  
delete from siac_rep_persona_fisica where utente=user_table;
delete from siac_rep_persona_fisica_recapiti where utente=user_table;
delete from siac_rep_persona_fisica_sedi where utente=user_table;	
delete from siac_rep_persona_fisica_modpag where utente=user_table;
delete from siac_rep_persona_giuridica where utente=user_table;
delete from siac_rep_persona_giuridica_recapiti where utente=user_table;
delete from siac_rep_persona_giuridica_sedi where utente=user_table;	
delete from siac_rep_persona_giuridica_modpag where utente=user_table;	
  
EXCEPTION
when no_data_found THEN
	raise notice 'nessun soggetto  trovato';
	return;
when others  THEN
 RTN_MESSAGGIO:='Ricerca dati soggetto';
 RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-6215 - Maurizio - FINE

-- siac-6240 Antonino - Inizio
DROP FUNCTION if exists fnc_siac_cons_entita_mandato_from_soggetto (integer,  varchar, integer, integer);
DROP FUNCTION if exists fnc_siac_cons_entita_mandato_from_soggetto (integer, integer, integer);
DROP FUNCTION if exists fnc_siac_cons_entita_reversale_from_soggetto (integer,  integer, integer);
DROP FUNCTION if exists fnc_siac_cons_entita_reversale_from_soggetto (integer, varchar,  integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_mandato_from_soggetto (
  _uid_soggetto integer,
  _annoesercizio varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  ord_numero numeric,
  ord_desc varchar,
  ord_emissione_data timestamp,
  soggetto_code varchar,
  soggetto_desc varchar,
  accredito_tipo_code varchar,
  accredito_tipo_desc varchar,
  ord_stato_desc varchar,
  importo numeric,
  ord_ts_code varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  uid_capitolo integer,
  num_capitolo varchar,
  num_articolo varchar,
  num_ueb varchar,
  capitolo_desc varchar,
  provc_anno integer,
  provc_numero numeric,
  provc_data_convalida timestamp,
  ord_quietanza_data timestamp
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
	with ord_join_outer as (
		with ord_join as (
			with ordinativo as (
				select
					a.ord_id as uid,
					a.ord_numero,
					a.ord_desc,
					a.ord_emissione_data,
					e.ord_stato_desc,
					g.ord_ts_det_importo as importo,
					f.ord_ts_code
				from
					 siac_t_ordinativo a
					,siac_r_ordinativo_stato d
					,siac_d_ordinativo_stato e
					,siac_t_ordinativo_ts f
					,siac_t_ordinativo_ts_det g
					,siac_d_ordinativo_ts_det_tipo h
					,siac_d_ordinativo_tipo i
                    ,siac_t_bil tbil
					,siac_t_periodo tper 

				where d.ord_id=a.ord_id
				and d.ord_stato_id=e.ord_stato_id
				and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
				and f.ord_id=a.ord_id
				and g.ord_ts_id=f.ord_ts_id
				and h.ord_ts_det_tipo_id=g.ord_ts_det_tipo_id
                and a.bil_id = tbil.bil_id
				and tbil.periodo_id	= tper.periodo_id
                and tper.anno = _annoEsercizio
				and h.ord_ts_det_tipo_code = 'A'
				and i.ord_tipo_id=a.ord_tipo_id
				and i.ord_tipo_code='P'
				and a.data_cancellazione is null
				and d.data_cancellazione is null
				and e.data_cancellazione is null
				and f.data_cancellazione is null
				and g.data_cancellazione is null
				and i.data_cancellazione is null
                and tbil.data_cancellazione is null
				and tper.data_cancellazione is null 

			),
			soggetto as (
				select
					b.ord_id,
					c.soggetto_code,
					c.soggetto_desc
				from
					siac_r_ordinativo_soggetto b,
					siac_t_soggetto c
				where b.soggetto_id=c.soggetto_id
				and c.soggetto_id=_uid_soggetto
				and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
				and b.data_cancellazione is null
				and c.data_cancellazione is null
			),
			attoamm as (
				select
					m.ord_id,
					n.attoamm_id,
					n.attoamm_numero,
					n.attoamm_anno,
					q.attoamm_stato_desc,
					o.attoamm_tipo_code,
					o.attoamm_tipo_desc
				from
					siac_r_ordinativo_atto_amm m,
					siac_t_atto_amm n,
					siac_d_atto_amm_tipo o,
					siac_r_atto_amm_stato p,
					siac_d_atto_amm_stato q
				where n.attoamm_id=m.attoamm_id
				and o.attoamm_tipo_id=n.attoamm_tipo_id
				and p.attoamm_id=n.attoamm_id
				and p.attoamm_stato_id=q.attoamm_stato_id
				and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
				and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
				and q.attoamm_stato_code<>'ANNULLATO'
				and m.data_cancellazione is null
				and n.data_cancellazione is null
				and o.data_cancellazione is null
				and p.data_cancellazione is null
				and q.data_cancellazione is null
			),
			capitolo as (
				select
					r.ord_id,
					s.elem_id,
					s.elem_code,
					s.elem_code2,
					s.elem_code3,
					s.elem_desc
				from
					siac_r_ordinativo_bil_elem r,
					siac_t_bil_elem s
				where s.elem_id=r.elem_id
				and r.data_cancellazione is null
				and s.data_cancellazione is null
				and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
			),
			modpag as (
				with modpag_noncessione as (
					select
						c2.ord_id,
						e2.accredito_tipo_code,
						e2.accredito_tipo_desc
					FROM
						siac_r_ordinativo_modpag c2,
						siac_t_modpag d2,
						siac_d_accredito_tipo e2
					where c2.modpag_id=d2.modpag_id
					and e2.accredito_tipo_id=d2.accredito_tipo_id
					and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
					and c2.data_cancellazione is null
					and d2.data_cancellazione is null--??forse da commentare siac-5670
					and e2.data_cancellazione is null
				),
				modpag_cessione as (
					select
						c2.ord_id,
						e2.relaz_tipo_code accredito_tipo_code,
						e2.relaz_tipo_desc accredito_tipo_desc
					from
						siac_r_ordinativo_modpag c2,
						siac_r_soggetto_relaz d2,
						siac_d_relaz_tipo e2
					where d2.soggetto_relaz_id = c2.soggetto_relaz_id
					and e2.relaz_tipo_id = d2.relaz_tipo_id
					and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
					and c2.data_cancellazione is null
					and d2.data_cancellazione is null
					and e2.data_cancellazione is null
				)
				select *
				from modpag_noncessione
				UNION ALL
				select *
				from modpag_cessione
			)
			select *
			from
				           ordinativo
				CROSS JOIN soggetto
				CROSS JOIN attoamm
				CROSS JOIN capitolo
				LEFT OUTER JOIN modpag on  (ordinativo.uid=modpag.ord_id)
			where ordinativo.uid=soggetto.ord_id
			and ordinativo.uid=attoamm.ord_id
			and ordinativo.uid=capitolo.ord_id
			--and ordinativo.uid=modpag.ord_id
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
			and x.classif_tipo_code IN ('CDC', 'CDR')
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
		)
		select *
		from ord_join
		left outer join sac_attoamm on ord_join.attoamm_id=sac_attoamm.attoamm_id
	),
	provv_cassa as (
		select
			a2.ord_id,
			b2.provc_anno,
			b2.provc_numero,
			b2.provc_data_convalida
		from
			siac_r_ordinativo_prov_cassa a2,
			siac_t_prov_cassa b2
		where b2.provc_id=a2.provc_id
		and now() BETWEEN a2.validita_inizio and coalesce (a2.validita_fine,now())
		and a2.data_cancellazione is NULL
		and b2.data_cancellazione is NULL
	),quietanza AS(
     --SIAC-5899
      SELECT 
          siac_T_Ordinativo.ord_id,	
          siac_r_ordinativo_quietanza.ord_quietanza_data
      FROM 
          siac_t_oil_ricevuta  
          ,siac_T_Ordinativo
          ,siac_d_oil_ricevuta_tipo
          ,siac_r_ordinativo_quietanza
      WHERE 
              siac_t_oil_ricevuta.oil_ricevuta_tipo_id =  siac_d_oil_ricevuta_tipo.oil_ricevuta_tipo_id
          AND siac_t_oil_ricevuta.oil_ord_id  = siac_T_Ordinativo.ord_id        
          AND siac_T_Ordinativo.ord_id = siac_r_ordinativo_quietanza.ord_id
          AND siac_d_oil_ricevuta_tipo.oil_ricevuta_tipo_code = 'Q'
          AND siac_t_oil_ricevuta.data_cancellazione is null  
          AND siac_T_Ordinativo.data_cancellazione is null
          AND siac_d_oil_ricevuta_tipo.data_cancellazione is null
          AND siac_r_ordinativo_quietanza.data_cancellazione is null
    )
	select
		ord_join_outer.uid,
		ord_join_outer.ord_numero,
		ord_join_outer.ord_desc,
		ord_join_outer.ord_emissione_data,
		ord_join_outer.soggetto_code,
		ord_join_outer.soggetto_desc,
		ord_join_outer.accredito_tipo_code,
		ord_join_outer.accredito_tipo_desc,
		ord_join_outer.ord_stato_desc,
		ord_join_outer.importo,
		ord_join_outer.ord_ts_code,
		ord_join_outer.attoamm_numero,
		ord_join_outer.attoamm_anno,
		ord_join_outer.attoamm_stato_desc,
		ord_join_outer.classif_code as attoamm_sac_code,
		ord_join_outer.classif_desc as attoamm_sac_desc,
		ord_join_outer.attoamm_tipo_code,
		ord_join_outer.attoamm_tipo_desc,
		ord_join_outer.elem_id as uid_capitolo,
		ord_join_outer.elem_code as num_capitolo,
		ord_join_outer.elem_code2 as num_articolo,
		ord_join_outer.elem_code3 as num_ueb,
		ord_join_outer.elem_desc as capitolo_desc,
		provv_cassa.provc_anno,
		provv_cassa.provc_numero,
		provv_cassa.provc_data_convalida,
		quietanza.ord_quietanza_data
	from ord_join_outer
		left outer join provv_cassa on ord_join_outer.uid=provv_cassa.ord_id
    	left outer join quietanza on ord_join_outer.uid=quietanza.ord_id    
	order by 2,4,12,11
	LIMIT _limit
	OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_reversale_from_soggetto (
  _uid_soggetto integer,
  _annoesercizio varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  ord_numero numeric,
  ord_desc varchar,
  ord_emissione_data timestamp,
  soggetto_code varchar,
  soggetto_desc varchar,
  accredito_tipo_code varchar,
  accredito_tipo_desc varchar,
  ord_stato_desc varchar,
  importo numeric,
  ord_ts_code varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  uid_capitolo integer,
  capitolo_numero varchar,
  capitolo_articolo varchar,
  num_ueb varchar,
  capitolo_desc varchar,
  capitolo_anno varchar,
  provc_anno integer,
  provc_numero numeric,
  provc_data_convalida timestamp,
  ord_quietanza_data timestamp
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
	with ord_join_outer as (
		with ord_join as (
			with ordinativo as (
				select
					a.ord_id as uid,
					a.ord_numero,
					a.ord_desc,
					a.ord_emissione_data,
					e.ord_stato_desc,
					g.ord_ts_det_importo as importo,
					f.ord_ts_code
				from
					 siac_t_ordinativo a
					,siac_r_ordinativo_stato d
					,siac_d_ordinativo_stato e
					,siac_t_ordinativo_ts f
					,siac_t_ordinativo_ts_det g
					,siac_d_ordinativo_ts_det_tipo h
					,siac_d_ordinativo_tipo i
                    ,siac_t_bil tbil
					,siac_t_periodo tper 

				where d.ord_id=a.ord_id
				and d.ord_stato_id=e.ord_stato_id
				and f.ord_id=a.ord_id
				and g.ord_ts_id=f.ord_ts_id
				and h.ord_ts_det_tipo_id=g.ord_ts_det_tipo_id

                and a.bil_id = tbil.bil_id
                and tbil.periodo_id	= tper.periodo_id
                and tper.anno = _annoEsercizio
                
				and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
				and h.ord_ts_det_tipo_code = 'A'
				and i.ord_tipo_id=a.ord_tipo_id
				and i.ord_tipo_code='I'
				and a.data_cancellazione is null
				and d.data_cancellazione is null
				and e.data_cancellazione is null
				and f.data_cancellazione is null
				and g.data_cancellazione is null
                and tbil.data_cancellazione is null
				and tper.data_cancellazione is null 
                
			),
			soggetto as (
				select
					b.ord_id,
					c.soggetto_code,
					c.soggetto_desc
				from
					siac_r_ordinativo_soggetto b,
					siac_t_soggetto c
				where b.soggetto_id=c.soggetto_id
				and c.soggetto_id=_uid_soggetto
				and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
				and b.data_cancellazione is null
				and c.data_cancellazione is null
			),
			attoamm as (
				select
					m.ord_id,
					n.attoamm_id,
					n.attoamm_numero,
					n.attoamm_anno,
					q.attoamm_stato_desc,
					o.attoamm_tipo_code,
					o.attoamm_tipo_desc
				from
					siac_r_ordinativo_atto_amm m,
					siac_t_atto_amm n,
					siac_d_atto_amm_tipo o,
					siac_r_atto_amm_stato p,
					siac_d_atto_amm_stato q
				where n.attoamm_id=m.attoamm_id
				and o.attoamm_tipo_id=n.attoamm_tipo_id
				and p.attoamm_id=n.attoamm_id
				and p.attoamm_stato_id=q.attoamm_stato_id
				and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
				and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
				and q.attoamm_stato_code<>'ANNULLATO'
				and m.data_cancellazione is null
				and n.data_cancellazione is null
				and o.data_cancellazione is null
				and p.data_cancellazione is null
				and q.data_cancellazione is null
			),
			capitolo as (
				select
					r.ord_id,
					s.elem_id,
					s.elem_code,
					s.elem_code2,
					s.elem_code3,
					s.elem_desc,
					y.anno capitolo_anno
				from
					siac_r_ordinativo_bil_elem r,
					siac_t_bil_elem s,
					siac_t_bil x,
					siac_t_periodo y
				where s.elem_id=r.elem_id
				and r.data_cancellazione is null
				and s.data_cancellazione is null
				and x.bil_id=s.bil_id
				and y.periodo_id=x.periodo_id
				and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
			),
			modpag as (
				select c2.ord_id,
					e2.accredito_tipo_code,
					e2.accredito_tipo_desc
				FROM
					siac_r_ordinativo_modpag c2,
					siac_t_modpag d2,
					siac_d_accredito_tipo e2
				where c2.modpag_id=d2.modpag_id
				and e2.accredito_tipo_id=d2.accredito_tipo_id
				and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
				and c2.data_cancellazione is null
				and d2.data_cancellazione is null
				and e2.data_cancellazione is null
			)
			select *
			from ordinativo
			join soggetto on ordinativo.uid=soggetto.ord_id
			join attoamm on ordinativo.uid=attoamm.ord_id
			join capitolo on ordinativo.uid=capitolo.ord_id
			left outer join modpag on ordinativo.uid=modpag.ord_id
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
			and x.classif_tipo_code IN ('CDC', 'CDR')
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
		)
		select *
		from ord_join
		left outer join sac_attoamm on ord_join.attoamm_id=sac_attoamm.attoamm_id
	),
	provv_cassa as(
		select
			a2.ord_id,
			b2.provc_anno,
			b2.provc_numero,
			b2.provc_data_convalida
		from
			siac_r_ordinativo_prov_cassa a2,
			siac_t_prov_cassa b2
		where b2.provc_id=a2.provc_id
		and now() BETWEEN a2.validita_inizio and coalesce (a2.validita_fine,now())
		and a2.data_cancellazione is NULL
		and b2.data_cancellazione is NULL
	),
    quietanza AS(
     --SIAC-5899
        SELECT 
            siac_T_Ordinativo.ord_id,	
            siac_r_ordinativo_quietanza.ord_quietanza_data
        --INTO
            --ord_quietanza_data
        FROM 
            siac_t_oil_ricevuta  
            ,siac_T_Ordinativo
            ,siac_d_oil_ricevuta_tipo
            ,siac_r_ordinativo_quietanza
        WHERE 
                siac_t_oil_ricevuta.oil_ricevuta_tipo_id =  siac_d_oil_ricevuta_tipo.oil_ricevuta_tipo_id
            AND siac_t_oil_ricevuta.oil_ord_id  = siac_T_Ordinativo.ord_id        
            AND siac_T_Ordinativo.ord_id = siac_r_ordinativo_quietanza.ord_id
            AND siac_d_oil_ricevuta_tipo.oil_ricevuta_tipo_code = 'Q'
            --AND siac_T_Ordinativo.ord_Id = uid 
            AND siac_t_oil_ricevuta.data_cancellazione is null  
            AND siac_T_Ordinativo.data_cancellazione is null
            AND siac_d_oil_ricevuta_tipo.data_cancellazione is null
            AND siac_r_ordinativo_quietanza.data_cancellazione is null
            )
	select
		ord_join_outer.uid,
		ord_join_outer.ord_numero,
		ord_join_outer.ord_desc,
		ord_join_outer.ord_emissione_data,
		ord_join_outer.soggetto_code,
		ord_join_outer.soggetto_desc,
		ord_join_outer.accredito_tipo_code,
		ord_join_outer.accredito_tipo_desc,
		ord_join_outer.ord_stato_desc,
		ord_join_outer.importo,
		ord_join_outer.ord_ts_code,
		ord_join_outer.attoamm_numero,
		ord_join_outer.attoamm_anno,
		ord_join_outer.attoamm_stato_desc,
		ord_join_outer.classif_code as attoamm_sac_code,
		ord_join_outer.classif_desc as attoamm_sac_desc,
		ord_join_outer.attoamm_tipo_code,
		ord_join_outer.attoamm_tipo_desc,
		ord_join_outer.elem_id as uid_capitolo,
		ord_join_outer.elem_code as capitolo_numero,
		ord_join_outer.elem_code2 as capitolo_articolo,
		ord_join_outer.elem_code3 as numero_ueb,
		ord_join_outer.elem_desc as capitolo_desc,
		ord_join_outer.capitolo_anno as capitolo_anno,
		provv_cassa.provc_anno,
		provv_cassa.provc_numero,
		provv_cassa.provc_data_convalida,
		quietanza.ord_quietanza_data
	from ord_join_outer
		left outer join provv_cassa on ord_join_outer.uid=provv_cassa.ord_id
    	left outer join quietanza on ord_join_outer.uid=quietanza.ord_id
	order by 2,4,12,11
	LIMIT _limit
	OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;


-- siac-6240 Antonino - Fine





-- SIAC-6184 - INIZIO


INSERT INTO siac_d_accredito_tipo (
  accredito_tipo_code, 
  accredito_tipo_desc, 
  accredito_priorita,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  accredito_gruppo_id
) 
SELECT  
  x.c, 
  x.d, 
  at.accredito_priorita,
  now(),
  ente_proprietario_id,
  login_operazione,
  accredito_gruppo_id
FROM siac_d_accredito_tipo at, 
  (SELECT 'CPT' c, 'Cessione presso terzi' d UNION 
   SELECT 'CSIG' c, 'Cessione incasso generica' d) x
WHERE at.accredito_tipo_code='PI';

 

 
INSERT INTO siac_d_relaz_tipo (
  relaz_tipo_code,
  relaz_tipo_desc,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
) 
SELECT 
  x.c, 
  x.d,
  now(),
  ente_proprietario_id,
  login_operazione
FROM siac_d_relaz_tipo rt,
  (SELECT 'CPT' c, 'Cessione presso terzi' d UNION 
   SELECT 'CSIG' c, 'Cessione incasso generica' d) x
WHERE rt.relaz_tipo_code='PI';



-- SIAC-6184 - FINE


-- SIAC-6246 - INIZIO

drop function if exists siac.fnc_siac_dwh_documento_spesa (
  p_ente_proprietario_id integer,
  p_data timestamp
);


CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_documento_spesa (
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

v_user_table varchar;
params varchar;
fnc_eseguita integer;

BEGIN

select count(*) into fnc_eseguita
from siac_dwh_log_elaborazioni
a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.fnc_elaborazione_inizio >= (now() - interval '13 hours')::timestamp -- non deve esistere  una elaborazione uguale nelle 13 ore che precedono la chimata
and a.fnc_name='fnc_siac_dwh_documento_spesa' ;

if fnc_eseguita> 0 then

return;

else

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

select fnc_siac_random_user()
into	v_user_table;

params := p_ente_proprietario_id::varchar||' - '||p_data::varchar;


insert into
siac_dwh_log_elaborazioni (
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values (
p_ente_proprietario_id,
'fnc_siac_dwh_documento_spesa',
params,
clock_timestamp(),
v_user_table
);


esito:= 'Inizio funzione carico documenti spesa (FNC_SIAC_DWH_DOCUMENTO_SPESA) - '||clock_timestamp();
RETURN NEXT;

DELETE FROM siac.siac_dwh_documento_spesa
WHERE ente_proprietario_id = p_ente_proprietario_id;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;

INSERT INTO
  siac.siac_dwh_documento_spesa
(
  ente_proprietario_id,
  ente_denominazione,
  anno_atto_amministrativo,
  num_atto_amministrativo,
  oggetto_atto_amministrativo,
  cod_tipo_atto_amministrativo,
  desc_tipo_atto_amministrativo,
  cod_cdr_atto_amministrativo,
  desc_cdr_atto_amministrativo,
  cod_cdc_atto_amministrativo,
  desc_cdc_atto_amministrativo,
  note_atto_amministrativo,
  cod_stato_atto_amministrativo,
  desc_stato_atto_amministrativo,
  causale_atto_allegato,
  altri_allegati_atto_allegato,
  dati_sensibili_atto_allegato,
  data_scadenza_atto_allegato,
  note_atto_allegato,
  annotazioni_atto_allegato,
  pratica_atto_allegato,
  resp_amm_atto_allegato,
  resp_contabile_atto_allegato,
  anno_titolario_atto_allegato,
  num_titolario_atto_allegato,
  vers_invio_firma_atto_allegato,
  cod_stato_atto_allegato,
  desc_stato_atto_allegato,
  sogg_id_atto_allegato,
  cod_sogg_atto_allegato,
  tipo_sogg_atto_allegato,
  stato_sogg_atto_allegato,
  rag_sociale_sogg_atto_allegato,
  p_iva_sogg_atto_allegato,
  cf_sogg_atto_allegato,
  cf_estero_sogg_atto_allegato,
  nome_sogg_atto_allegato,
  cognome_sogg_atto_allegato,
  anno_doc,
  num_doc,
  desc_doc,
  importo_doc,
  beneficiario_multiplo_doc,
  data_emissione_doc,
  data_scadenza_doc,
  codice_bollo_doc,
  desc_codice_bollo_doc,
  collegato_cec_doc,
  cod_pcc_doc,
  desc_pcc_doc,
  cod_ufficio_doc,
  desc_ufficio_doc,
  cod_stato_doc,
  desc_stato_doc,
  anno_elenco_doc,
  num_elenco_doc,
  data_trasmissione_elenco_doc,
  tot_quote_entrate_elenco_doc,
  tot_quote_spese_elenco_doc,
  tot_da_pagare_elenco_doc,
  tot_da_incassare_elenco_doc,
  cod_stato_elenco_doc,
  desc_stato_elenco_doc,
  cod_gruppo_doc,
  desc_famiglia_doc,
  cod_famiglia_doc,
  desc_gruppo_doc,
  cod_tipo_doc,
  desc_tipo_doc,
  sogg_id_doc,
  cod_sogg_doc,
  tipo_sogg_doc,
  stato_sogg_doc,
  rag_sociale_sogg_doc,
  p_iva_sogg_doc,
  cf_sogg_doc,
  cf_estero_sogg_doc,
  nome_sogg_doc,
  cognome_sogg_doc,
  num_subdoc,
  desc_subdoc,
  importo_subdoc,
  num_reg_iva_subdoc,
  data_scadenza_subdoc,
  convalida_manuale_subdoc,
  importo_da_dedurre_subdoc,
  splitreverse_importo_subdoc,
  pagato_cec_subdoc,
  data_pagamento_cec_subdoc,
  note_tesoriere_subdoc,
  cod_distinta_subdoc,
  desc_distinta_subdoc,
  tipo_commissione_subdoc,
  conto_tesoreria_subdoc,
  rilevante_iva,
  ordinativo_singolo,
  ordinativo_manuale,
  esproprio,
  note,
  cig,
  cup,
  causale_sospensione,
  data_sospensione,
  data_riattivazione,
  causale_ordinativo,
  num_mutuo,
  annotazione,
  certificazione,
  data_certificazione,
  note_certificazione,
  num_certificazione,
  data_scadenza_dopo_sospensione,
  data_esecuzione_pagamento,
  avviso,
  cod_tipo_avviso,
  desc_tipo_avviso,
  sogg_id_subdoc,
  cod_sogg_subdoc,
  tipo_sogg_subdoc,
  stato_sogg_subdoc,
  rag_sociale_sogg_subdoc,
  p_iva_sogg_subdoc,
  cf_sogg_subdoc,
  cf_estero_sogg_subdoc,
  nome_sogg_subdoc,
  cognome_sogg_subdoc,
  sede_secondaria_subdoc,
  bil_anno,
  anno_impegno,
  num_impegno,
  cod_impegno,
  desc_impegno,
  cod_subimpegno,
  desc_subimpegno,
  num_liquidazione,
  cod_tipo_accredito,
  desc_tipo_accredito,
  mod_pag_id,
  quietanziante,
  data_nascita_quietanziante,
  luogo_nascita_quietanziante,
  stato_nascita_quietanziante,
  bic,
  contocorrente,
  intestazione_contocorrente,
  iban,
  note_mod_pag,
  data_scadenza_mod_pag,
  sogg_id_mod_pag,
  cod_sogg_mod_pag,
  tipo_sogg_mod_pag,
  stato_sogg_mod_pag,
  rag_sociale_sogg_mod_pag,
  p_iva_sogg_mod_pag,
  cf_sogg_mod_pag,
  cf_estero_sogg_mod_pag,
  nome_sogg_mod_pag,
  cognome_sogg_mod_pag,
  anno_liquidazione,
  bil_anno_ord,
  anno_ord,
  num_ord,
  num_subord,
  registro_repertorio,
  anno_repertorio,
  num_repertorio,
  data_repertorio,
  data_ricezione_portale,
  doc_contabilizza_genpcc,
  rudoc_registrazione_anno,
  rudoc_registrazione_numero,
  rudoc_registrazione_data,
  cod_cdc_doc,
  desc_cdc_doc,
  cod_cdr_doc,
  desc_cdr_doc,
  data_operazione_pagamentoincasso,
  pagataincassata,
  note_pagamentoincasso,
  -- 	SIAC-5229
  arrotondamento,
  cod_tipo_splitrev,
  desc_tipo_splitrev,
  stato_liquidazione,
  sdi_lotto_siope_doc,
  cod_siope_tipo_doc,
  desc_siope_tipo_doc,
  desc_siope_tipo_bnkit_doc,
  cod_siope_tipo_analogico_doc,
  desc_siope_tipo_analogico_doc,
  desc_siope_tipo_ana_bnkit_doc,
  cod_siope_tipo_debito_subdoc,
  desc_siope_tipo_debito_subdoc,
  desc_siope_tipo_deb_bnkit_sub,
  cod_siope_ass_motiv_subdoc,
  desc_siope_ass_motiv_subdoc,
  desc_siope_ass_motiv_bnkit_sub,
  cod_siope_scad_motiv_subdoc,
  desc_siope_scad_motiv_subdoc,
  desc_siope_scad_moti_bnkit_sub,
  doc_id, -- SIAC-5573,
  --- 15.05.2018 Sofia SIAC-6124
  data_ins_atto_allegato,
  data_sosp_atto_allegato,
  causale_sosp_atto_allegato,
  data_riattiva_atto_allegato,
  data_completa_atto_allegato,
  data_convalida_atto_allegato
  )
select
tb.v_ente_proprietario_id::INTEGER,
trim(tb.v_ente_denominazione::VARCHAR)::VARCHAR,
trim(tb.v_anno_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_num_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_oggetto_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_tipo_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_cdr_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_cdr_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_cdc_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_cdc_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_note_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_stato_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_causale_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_altri_allegati_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_dati_sensibili_atto_allegato::VARCHAR)::VARCHAR,
tb.v_data_scadenza_atto_allegato::timestamp,
trim(tb.v_note_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_annotazioni_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_pratica_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_resp_amm_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_resp_contabile_atto_allegato::VARCHAR)::VARCHAR,
tb.v_anno_titolario_atto_allegato::INTEGER,
trim(tb.v_num_titolario_atto_allegato::VARCHAR)::VARCHAR,
tb.v_vers_invio_firma_atto_allegato::INTEGER,
trim(tb.v_cod_stato_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_atto_allegato::VARCHAR)::VARCHAR,
tb.v_sogg_id_atto_allegato::INTEGER,
trim(tb.v_cod_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_atto_allegato::VARCHAR)::VARCHAR,
tb.v_anno_doc::INTEGER,
trim(tb.v_num_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_doc::VARCHAR)::VARCHAR,
tb.v_importo_doc::NUMERIC,
trim(tb.v_beneficiario_multiplo_doc::VARCHAR)::VARCHAR,
tb.v_data_emissione_doc::TIMESTAMP,
tb.v_data_scadenza_doc::TIMESTAMP,
trim(tb.v_codice_bollo_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_codice_bollo_doc::VARCHAR)::VARCHAR,
tb.v_collegato_cec_doc,
trim(tb.v_cod_pcc_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_pcc_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_ufficio_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_ufficio_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_stato_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_doc::VARCHAR)::VARCHAR,
tb.v_anno_elenco_doc::INTEGER,
tb.v_num_elenco_doc::INTEGER,
tb.v_data_trasmissione_elenco_doc::TIMESTAMP,
tb.v_tot_quote_entrate_elenco_doc::NUMERIC,
tb.v_tot_quote_spese_elenco_doc::NUMERIC,
tb.v_tot_da_pagare_elenco_doc::NUMERIC,
tb.v_tot_da_incassare_elenco_doc::NUMERIC,
trim(tb.v_cod_stato_elenco_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_elenco_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_gruppo_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_famiglia_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_famiglia_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_gruppo_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_tipo_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_doc::VARCHAR)::VARCHAR,
tb.v_sogg_id_doc::INTEGER,
trim(tb.v_cod_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_doc::VARCHAR)::VARCHAR,
tb.v_num_subdoc::INTEGER,
trim(tb.v_desc_subdoc::VARCHAR)::VARCHAR,
tb.v_importo_subdoc::NUMERIC,
trim(tb.v_num_reg_iva_subdoc::VARCHAR)::VARCHAR,
tb.v_data_scadenza_subdoc::TIMESTAMP,
trim(tb.v_convalida_manuale_subdoc::VARCHAR)::VARCHAR,
tb.v_importo_da_dedurre_subdoc::NUMERIC,
tb.v_splitreverse_importo_subdoc::NUMERIC,
tb.v_pagato_cec_subdoc,
tb.v_data_pagamento_cec_subdoc::TIMESTAMP,
trim(tb.v_note_tesoriere_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cod_distinta_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_desc_distinta_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_tipo_commissione_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_conto_tesoreria_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_rilevante_iva::VARCHAR)::VARCHAR,
trim(tb.v_ordinativo_singolo::VARCHAR)::VARCHAR,
trim(tb.v_ordinativo_manuale::VARCHAR)::VARCHAR,
trim(tb.v_esproprio::VARCHAR)::VARCHAR,
trim(tb.v_note::VARCHAR)::VARCHAR,
trim(tb.v_cig::VARCHAR)::VARCHAR,
trim(tb.v_cup::VARCHAR)::VARCHAR,
trim(tb.v_causale_sospensione::VARCHAR)::VARCHAR,
trim(tb.v_data_sospensione::VARCHAR)::VARCHAR,
trim(tb.v_data_riattivazione::VARCHAR)::VARCHAR,
trim(tb.v_causale_ordinativo::VARCHAR)::VARCHAR,
tb.v_num_mutuo::INTEGER,
trim(tb.v_annotazione::VARCHAR)::VARCHAR,
trim(tb.v_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_data_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_note_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_num_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_data_scadenza_dopo_sospensione::VARCHAR)::VARCHAR,
trim(tb.v_data_esecuzione_pagamento::VARCHAR)::VARCHAR,
trim(tb.v_avviso::VARCHAR)::VARCHAR,
trim(tb.v_cod_tipo_avviso::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_avviso::VARCHAR)::VARCHAR,
tb.v_soggetto_id::INTEGER,
trim(tb.v_cod_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_sede_secondaria_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_bil_anno::VARCHAR)::VARCHAR,
tb.v_anno_impegno::INTEGER,
tb.v_num_impegno::NUMERIC,
trim(tb.v_cod_impegno::VARCHAR)::VARCHAR,
trim(tb.v_desc_impegno::VARCHAR)::VARCHAR,
trim(tb.v_cod_subimpegno::VARCHAR)::VARCHAR,
trim(tb.v_desc_subimpegno::VARCHAR)::VARCHAR,
tb.v_num_liquidazione::NUMERIC,
trim(tb.v_cod_tipo_accredito::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_accredito::VARCHAR)::VARCHAR,
tb.v_mod_pag_id::INTEGER,
trim(tb.v_quietanziante::VARCHAR)::VARCHAR,
tb.v_data_nasciata_quietanziante::TIMESTAMP,
trim(tb.v_luogo_nascita_quietanziante::VARCHAR)::VARCHAR,
trim(tb.v_stato_nascita_quietanziante::VARCHAR)::VARCHAR,
trim(tb.v_bic::VARCHAR)::VARCHAR,
trim(tb.v_contocorrente::VARCHAR)::VARCHAR,
trim(tb.v_intestazione_contocorrente::VARCHAR)::VARCHAR,
trim(tb.v_iban::VARCHAR)::VARCHAR,
trim(tb.v_note_mod_pag::VARCHAR)::VARCHAR,
tb.v_data_scadenza_mod_pag::TIMESTAMP,
tb.v_soggetto_id_modpag::INTEGER,
trim(tb.v_cod_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_mod_pag::VARCHAR)::VARCHAR,
tb.v_anno_liquidazione::INTEGER,
trim(tb.v_bil_anno_ord::VARCHAR)::VARCHAR,
tb.v_anno_ord::INTEGER,
tb.v_num_ord::NUMERIC,
trim(tb.v_num_subord::VARCHAR)::VARCHAR,
--nuova sezione coge 26-09-2016
trim(tb.v_registro_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_anno_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_num_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_data_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_data_ricezione_portale::VARCHAR)::VARCHAR,
trim(tb.v_doc_contabilizza_genpcc::VARCHAR)::VARCHAR,
-- CR 854
tb.rudoc_registrazione_anno::INTEGER,
tb.rudoc_registrazione_numero::INTEGER,
tb.rudoc_registrazione_data::TIMESTAMP,
trim(tb.cdc_code::VARCHAR)::VARCHAR,
trim(tb.cdc_desc::VARCHAR)::VARCHAR,
trim(tb.cdr_code::VARCHAR)::VARCHAR,
trim(tb.cdr_desc::VARCHAR)::VARCHAR,
trim(tb.v_dataOperazionePagamentoIncasso::VARCHAR)::VARCHAR,
trim(tb.v_flagPagataIncassata::VARCHAR)::VARCHAR,
trim(tb.v_notePagamentoIncasso::VARCHAR)::VARCHAR,
---- SIAC-5229
tb.v_arrotondamento,
-------------
trim(tb.v_cod_tipo_splitrev::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_splitrev::VARCHAR)::VARCHAR,
trim(tb.v_liq_stato_desc::VARCHAR)::VARCHAR,
tb.doc_sdi_lotto_siope,
tb.siope_documento_tipo_code,
tb.siope_documento_tipo_desc,
tb.siope_documento_tipo_desc_bnkit,
tb.siope_documento_tipo_analogico_code,
tb.siope_documento_tipo_analogico_desc,
tb.siope_documento_tipo_analogico_desc_bnkit,
tb.siope_tipo_debito_code,
tb.siope_tipo_debito_desc,
tb.siope_tipo_debito_desc_bnkit,
tb.siope_assenza_motivazione_code,
tb.siope_assenza_motivazione_desc,
tb.siope_assenza_motivazione_desc_bnkit,
tb.siope_scadenza_motivo_code,
tb.siope_scadenza_motivo_desc,
tb.siope_scadenza_motivo_desc_bnkit ,
tb.doc_id, -- SIAC-5573,
--- 15.05.2018 Sofia SIAC-6124
tb.data_ins_atto_allegato::timestamp,
tb.data_sosp_atto_allegato::timestamp,
tb.causale_sosp_atto_allegato,
tb.data_riattiva_atto_allegato::timestamp,
tb.data_completa_atto_allegato::timestamp,
tb.data_convalida_atto_allegato::timestamp
from (
with doc as (
  with doc1 as (
select distinct
  --h.subdoc_id,a.doc_id,b.doc_tipo_id,c.doc_fam_tipo_id,d.doc_gruppo_tipo_id,e.doc_stato_r_id,f.doc_stato_id,
  b.doc_gruppo_tipo_id,
  g.ente_proprietario_id, g.ente_denominazione,
  a.doc_anno, a.doc_numero, a.doc_desc, a.doc_importo,
  case when a.doc_beneficiariomult= false then 'F' else 'T' end doc_beneficiariomult,
  a.doc_data_emissione, a.doc_data_scadenza,
  case when a.doc_collegato_cec = false then 'F' else 'T' end doc_collegato_cec,
  f.doc_stato_code, f.doc_stato_desc,
  c.doc_fam_tipo_code, c.doc_fam_tipo_desc, b.doc_tipo_code, b.doc_tipo_desc,
  a.doc_id, a.pcccod_id, a.pccuff_id,
  case when a.doc_contabilizza_genpcc= false then 'F' else 'T' end doc_contabilizza_genpcc,
  h.subdoc_numero, h.subdoc_desc, h.subdoc_importo, h.subdoc_nreg_iva, h.subdoc_data_scadenza,
  h.subdoc_convalida_manuale, h.subdoc_importo_da_dedurre, h.subdoc_splitreverse_importo,
  case when h.subdoc_pagato_cec = false then 'F' else 'T' end subdoc_pagato_cec,
  h.subdoc_data_pagamento_cec,
  a.codbollo_id, h.subdoc_id,h.comm_tipo_id,
  h.notetes_id,h.dist_id,h.contotes_id,
  a.doc_sdi_lotto_siope,
  n.siope_documento_tipo_code, n.siope_documento_tipo_desc, n.siope_documento_tipo_desc_bnkit,
  o.siope_documento_tipo_analogico_code, o.siope_documento_tipo_analogico_desc, o.siope_documento_tipo_analogico_desc_bnkit,
  i.siope_tipo_debito_code, i.siope_tipo_debito_desc, i.siope_tipo_debito_desc_bnkit,
  l.siope_assenza_motivazione_code, l.siope_assenza_motivazione_desc, l.siope_assenza_motivazione_desc_bnkit,
  m.siope_scadenza_motivo_code, m.siope_scadenza_motivo_desc, m.siope_scadenza_motivo_desc_bnkit
  from siac_t_doc a
  left join siac_d_siope_documento_tipo n on n.siope_documento_tipo_id = a.siope_documento_tipo_id
                                     and n.data_cancellazione is null
                                     and n.validita_fine is null
  left join siac_d_siope_documento_tipo_analogico o on o.siope_documento_tipo_analogico_id = a.siope_documento_tipo_analogico_id
                                             and o.data_cancellazione is null
                                             and o.validita_fine is null
  ,siac_d_doc_tipo b,siac_d_doc_fam_tipo c,
  --siac_d_doc_gruppo d,
  siac_r_doc_stato e,
  siac_d_doc_stato f,
  siac_t_ente_proprietario g,
  siac_t_subdoc h
  left join siac_d_siope_tipo_debito i on i.siope_tipo_debito_id = h.siope_tipo_debito_id
                                     and i.data_cancellazione is null
                                     and i.validita_fine is null
  left join siac_d_siope_assenza_motivazione l on l.siope_assenza_motivazione_id = h.siope_assenza_motivazione_id
                                             and l.data_cancellazione is null
                                             and l.validita_fine is null
  left join siac_d_siope_scadenza_motivo m on m.siope_scadenza_motivo_id = h.siope_scadenza_motivo_id
                                             and m.data_cancellazione is null
                                             and m.validita_fine is null
  where b.doc_tipo_id=a.doc_tipo_id
  and c.doc_fam_tipo_id=b.doc_fam_tipo_id
  --and b.doc_gruppo_tipo_id=d.doc_gruppo_tipo_id
  and e.doc_id=a.doc_id
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  and f.doc_stato_id=e.doc_stato_id
  and g.ente_proprietario_id=a.ente_proprietario_id
  and g.ente_proprietario_id=p_ente_proprietario_id--p_ente_proprietario_id
  AND c.doc_fam_tipo_code in ('S','IS')
  and h.doc_id=a.doc_id
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  AND g.data_cancellazione IS NULL
  AND h.data_cancellazione IS NULL
)
, docgru as  (
select a.doc_gruppo_tipo_id, a.doc_gruppo_tipo_code, a.doc_gruppo_tipo_desc
 from siac_d_doc_gruppo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null)
select doc1.*, docgru.* from doc1 left join docgru on
docgru.doc_gruppo_tipo_id = doc1.doc_gruppo_tipo_id
  )
  ,bollo as (
  select a.codbollo_id,a.codbollo_code, a.codbollo_desc from siac_d_codicebollo a
  where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null)
  ,sogg as (
  with sogg1 as (
  select distinct a.doc_id,b.soggetto_code,
  --d.soggetto_tipo_desc,
  f.soggetto_stato_desc,
  b.partita_iva, b.codice_fiscale, b.codice_fiscale_estero,
   b.soggetto_id
   from
  siac_r_doc_sog a, siac_t_soggetto b ,/*siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d,*/siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.soggetto_id=b.soggetto_id
 /* and c.soggetto_id=b.soggetto_id
  and d.soggetto_tipo_id=c.soggetto_tipo_id*/
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  /*and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)*/
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
/*  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL*/
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  --and b.soggetto_id=1862
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  ),
  sogg5 as (select
c.soggetto_id,d.soggetto_tipo_desc
 from siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d where c.ente_proprietario_id=p_ente_proprietario_id and
  d.soggetto_tipo_id=c.soggetto_tipo_id
  and c.data_cancellazione is null
  and d.data_cancellazione is NULL
  AND p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  )
  select sogg1.*, sogg2.ragione_sociale,sogg3.nome, sogg3.cognome, sogg5.soggetto_tipo_desc
  from sogg1 left join sogg2 on sogg1.soggetto_id=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id=sogg3.soggetto_id
  left join sogg5 on sogg1.soggetto_id=sogg5.soggetto_id
  )
  , reguni as (select a.doc_id,a.rudoc_registrazione_anno,
  a.rudoc_registrazione_numero,a.rudoc_registrazione_data
  from siac_t_registrounico_doc a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , cdr as (
  select a.doc_id, b.classif_code doc_cdr_cdr_code, b.classif_desc doc_cdr_cdr_desc ,
  null   doc_cdr_cdc_code, null  doc_cdr_cdc_desc
  from siac_r_doc_class a, siac_t_class b, siac_d_class_tipo c
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDR'
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  ),
  cdc as (
  select a.doc_id, b.classif_code doc_cdc_cdc_code, b.classif_desc doc_cdc_cdc_desc,
  d.classif_code doc_cdc_cdr_code, d.classif_desc doc_cdc_cdr_desc
  from siac_r_doc_class a, siac_t_class b, siac_d_class_tipo c, siac_t_class d,siac_r_class_fam_tree e
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDC'
  and b.classif_id=e.classif_id
  and d.classif_id=e.classif_id_padre
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL)
  ,pcccod as (select a.pcccod_id,a.pcccod_code,a.pcccod_desc from
  siac_d_pcc_codice  a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , pccuff as (
  select a.pccuff_id,a.pccuff_code,a.pccuff_desc from
  siac_d_pcc_ufficio  a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , attoamm as (
  with attoamm1 as (
  select
  b.attoamm_id,
  a.subdoc_id,  b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
  d.attoamm_stato_code, d.attoamm_stato_desc,
  e.attoamm_tipo_code, e.attoamm_tipo_desc
  from
  siac_r_subdoc_atto_amm a ,siac_t_atto_amm b ,siac_r_atto_amm_stato c ,siac_d_atto_amm_stato d,
  siac_d_atto_amm_tipo e
  where
  a.ente_proprietario_id=p_ente_proprietario_id and
  a.attoamm_id=b.attoamm_id and c.attoamm_id=b.attoamm_id
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and d.attoamm_stato_id=c.attoamm_stato_id
  and e.attoamm_tipo_id=b.attoamm_tipo_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.data_cancellazione is null
  ),
cdr as (
  select a.attoamm_id, b.classif_code attoamm_cdr_cdr_code, b.classif_desc attoamm_cdr_cdr_desc ,
  null::varchar  attoamm_cdr_cdc_code, null::varchar attoamm_cdr_cdc_desc
  from siac_r_atto_amm_class a, siac_t_class b, siac_d_class_tipo c
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDR'
  -- and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) -- SIAC-5494
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  ),
  cdc as (
  select a.attoamm_id, b.classif_code attoamm_cdc_cdc_code, b.classif_desc attoamm_cdc_cdc_desc,
  d.classif_code attoamm_cdc_cdr_code, d.classif_desc attoamm_cdc_cdr_desc
  from siac_r_atto_amm_class a, siac_t_class b, siac_d_class_tipo c, siac_t_class d,siac_r_class_fam_tree e
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDC'
  and b.classif_id=e.classif_id
  and d.classif_id=e.classif_id_padre
  -- and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data) -- SIAC-5494
  -- and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) -- SIAC-5494
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  )
  select   attoamm1.*,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdc_code::varchar else null::varchar end attoamm_cdc_code,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdc_desc::varchar else null::varchar end attoamm_cdc_desc,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdr_code::varchar else cdr.attoamm_cdr_cdr_code::varchar end attoamm_cdr_code,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdr_desc::varchar else cdr.attoamm_cdr_cdr_desc::varchar end attoamm_cdr_desc
  from attoamm1
  left join cdc on attoamm1.attoamm_id=cdc.attoamm_id
  left join cdr on attoamm1.attoamm_id=cdr.attoamm_id
  ),
  commt as (select a.comm_tipo_id,a.comm_tipo_code,a.comm_tipo_desc
   from siac_d_commissione_tipo a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  ,
  eldocattall as (
  with eldoc as (
  select a.subdoc_id,a.eldoc_id,
  b.eldoc_anno, b.eldoc_numero, b.eldoc_data_trasmissione, b.eldoc_tot_quoteentrate,
  b.eldoc_tot_quotespese, b.eldoc_tot_dapagare, b.eldoc_tot_daincassare,
  d.eldoc_stato_code, d.eldoc_stato_desc
   from
  siac_r_elenco_doc_subdoc a,siac_t_elenco_doc b, siac_r_elenco_doc_stato c,
  siac_d_elenco_doc_stato d
  where
  a.ente_proprietario_id=p_ente_proprietario_id and
  b.eldoc_id=a.eldoc_id
  and c.eldoc_id=b.eldoc_id
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and d.eldoc_stato_id=c.eldoc_stato_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  ),
  attoal as (with attoall as (
select distinct
  a.eldoc_id,b.attoal_id,
  b.attoal_causale, b.attoal_altriallegati, b.attoal_dati_sensibili,
         b.attoal_data_scadenza, b.attoal_note, b.attoal_annotazioni, b.attoal_pratica,
         b.attoal_responsabile_amm, b.attoal_responsabile_con, b.attoal_titolario_anno,
         b.attoal_titolario_numero, b.attoal_versione_invio_firma,
         d.attoal_stato_code, d.attoal_stato_desc,
         b.data_creazione data_ins_atto_allegato,   -- 15.05.2018 Sofia siac-6124
	     fnc_siac_attoal_getDataStato(b.attoal_id,'C') data_completa_atto_allegato, -- 22.05.2018 Sofia siac-6124
         fnc_siac_attoal_getDataStato(b.attoal_id,'CV') data_convalida_atto_allegato  -- 22.05.2018 Sofia siac-6124
   from
  siac_r_atto_allegato_elenco_doc a, siac_t_atto_allegato b,
  siac_r_atto_allegato_stato c ,siac_d_atto_allegato_stato d
  where a.ente_proprietario_id=p_ente_proprietario_id and
  a.attoal_id=b.attoal_id
  and c.attoal_id=b.attoal_id
  and d.attoal_stato_id=c.attoal_stato_id
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  ),
  soggattoall as (
  with sogg1 as (
  select distinct a.attoal_id,b.soggetto_code soggetto_code_atto_allegato,
  /*d.soggetto_tipo_desc soggetto_tipo_desc_atto_allegato, */
  f.soggetto_stato_desc soggetto_stato_desc_atto_allegato,
  b.partita_iva partita_iva_atto_allegato, b.codice_fiscale codice_fiscale_atto_allegato,
  b.codice_fiscale_estero codice_fiscale_estero_atto_allegato,
  b.soggetto_id soggetto_id_atto_allegato,
  -- 16.05.2018 Sofia siac-6124
  a.attoal_sog_data_sosp data_sosp_atto_allegato,
  a.attoal_sog_causale_sosp causale_sosp_atto_allegato,
  a.attoal_sog_data_riatt data_riattiva_atto_allegato
   from
  siac_r_atto_allegato_sog a, siac_t_soggetto b ,/*siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d,*/siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.soggetto_id=b.soggetto_id
  /*and c.soggetto_id=b.soggetto_id
  and d.soggetto_tipo_id=c.soggetto_tipo_id*/
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  /*and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)*/
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
/*  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL*/
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  --and b.soggetto_id=1862
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale  from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  ),
  sogg5 as (select
	c.soggetto_id,d.soggetto_tipo_desc
 from siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d where c.ente_proprietario_id=p_ente_proprietario_id and
  d.soggetto_tipo_id=c.soggetto_tipo_id
  and c.data_cancellazione is null
  and d.data_cancellazione is NULL
  AND p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  )
  select sogg1.*, sogg2.ragione_sociale ragione_sociale_atto_allegato,sogg3.nome nome_atto_allegato,
  sogg3.cognome cognome_atto_allegato, sogg5.soggetto_tipo_desc soggetto_tipo_desc_atto_allegato
  from sogg1 left join sogg2 on sogg1.soggetto_id_atto_allegato=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id_atto_allegato=sogg3.soggetto_id
  left join sogg5 on sogg1.soggetto_id_atto_allegato=sogg5.soggetto_id
  )
  select attoall.*,soggattoall.ragione_sociale_atto_allegato,soggattoall.nome_atto_allegato,
  soggattoall.cognome_atto_allegato,   soggattoall.soggetto_code_atto_allegato,
  soggattoall.soggetto_tipo_desc_atto_allegato,
  soggattoall.soggetto_stato_desc_atto_allegato,
  soggattoall.partita_iva_atto_allegato, soggattoall.codice_fiscale_atto_allegato,
  soggattoall.codice_fiscale_estero_atto_allegato,
  soggattoall.soggetto_id_atto_allegato ,
  -- 16.05.2018 Sofia siac-6124
  soggattoall.data_sosp_atto_allegato,
  soggattoall.causale_sosp_atto_allegato,
  soggattoall.data_riattiva_atto_allegato
  from attoall left join soggattoall
  on attoall.attoal_id=soggattoall.attoal_id
  )
  select distinct eldoc.*,
  attoal.attoal_id,
  attoal.attoal_causale, attoal.attoal_altriallegati, attoal.attoal_dati_sensibili,
         attoal.attoal_data_scadenza, attoal.attoal_note, attoal.attoal_annotazioni, attoal.attoal_pratica,
         attoal.attoal_responsabile_amm, attoal.attoal_responsabile_con, attoal.attoal_titolario_anno,
         attoal.attoal_titolario_numero, attoal.attoal_versione_invio_firma,
         attoal.attoal_stato_code, attoal.attoal_stato_desc,
   attoal.ragione_sociale_atto_allegato,attoal.nome_atto_allegato,attoal.cognome_atto_allegato,
   attoal.soggetto_code_atto_allegato,
  attoal.soggetto_tipo_desc_atto_allegato,
  attoal.soggetto_stato_desc_atto_allegato,
  attoal.partita_iva_atto_allegato, attoal.codice_fiscale_atto_allegato,
  attoal.codice_fiscale_estero_atto_allegato,
  attoal.soggetto_id_atto_allegato,
  -- 15.05.2018 Sofia siac-6124
  attoal.data_ins_atto_allegato,
  attoal.data_sosp_atto_allegato,
  attoal.causale_sosp_atto_allegato,
  attoal.data_riattiva_atto_allegato,
  attoal.data_completa_atto_allegato,
  attoal.data_convalida_atto_allegato
  from eldoc left join attoal
  on eldoc.eldoc_id=attoal.eldoc_id
  ),
  notes as (
  select a.notetes_id,a.notetes_desc from
  siac.siac_d_note_tesoriere a
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , dist as (
  select a.dist_id,a.dist_code, a.dist_desc from siac_d_distinta a
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , contes as (
  select a.contotes_id,a.contotes_desc from siac_d_contotesoreria  a
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null),
  split as (select
  a.subdoc_id,b.sriva_tipo_code , b.sriva_tipo_desc from  siac_r_subdoc_splitreverse_iva_tipo a,
  siac_d_splitreverse_iva_tipo b
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null
  and b.sriva_tipo_id=a.sriva_tipo_id
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  )
  , liq as (  select  a.subdoc_id,b.liq_anno,b.liq_numero ,d.liq_stato_desc
  from siac.siac_r_subdoc_liquidazione a ,siac_t_liquidazione b,siac_r_liquidazione_stato c ,
  siac_d_liquidazione_stato d
  where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and b.liq_id=a.liq_id
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and c.liq_id=b.liq_id
  and d.liq_stato_id=c.liq_stato_id
  --and d.liq_stato_code<>'A'
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
),
subcltipoavviso as (select a.subdoc_id,b.classif_code cod_tipo_avviso,b.classif_desc desc_tipo_avviso
 from siac_r_subdoc_class a, siac_t_class b,siac_d_class_tipo c
where a.ente_proprietario_id=p_ente_proprietario_id and b.classif_id=a.classif_id
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and c.classif_tipo_id=b.classif_tipo_id
and c.classif_tipo_code='TIPO_AVVISO'
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
),
docattr1 as (
SELECT distinct a.doc_id,
a.testo v_registro_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'registro_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr2 as (
SELECT distinct a.doc_id,
a.numerico v_anno_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'anno_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr3 as (
SELECT distinct a.doc_id,
a.testo v_num_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'num_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr4 as (
SELECT distinct a.doc_id,
a.testo v_data_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'data_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr5 as (
SELECT distinct a.doc_id,
a.testo v_data_ricezione_portale
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataRicezionePortale' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr6 as (
SELECT distinct a.doc_id,
a.testo v_dataOperazionePagamentoIncasso
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataOperazionePagamentoIncasso' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr7 as (
SELECT distinct a.doc_id,
a."boolean" v_flagPagataIncassata
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagPagataIncassata' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr8 as (
SELECT distinct a.doc_id,
a.testo v_notePagamentoIncasso
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'notePagamentoIncasso' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr9 as (
SELECT distinct a.doc_id,
a.numerico v_arrotondamento
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'arrotondamento' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)

,subdocattr1 as (
SELECT distinct a.subdoc_id,
a."boolean" v_rilevante_iva
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagRilevanteIVA' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr2 as (
SELECT a.subdoc_id, a.subdoc_attr_id,
a."boolean" v_ordinativo_singolo
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagOrdinativoSingolo' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)

,subdocattr3 as (
SELECT distinct a.subdoc_id,
a."boolean" v_esproprio
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagEsproprio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr4 as (
SELECT distinct a.subdoc_id,
a."boolean" v_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr5 as (
SELECT distinct a.subdoc_id,
a."boolean" v_ordinativo_manuale
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagOrdinativoManuale' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr6 as (
SELECT distinct a.subdoc_id,
a."boolean" v_avviso
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagAvviso' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr7 as (
SELECT distinct a.subdoc_id,
a.numerico v_num_mutuo
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'numeroMutuo' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr8 as (
SELECT distinct a.subdoc_id,
a.testo v_cup
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'cup' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr9 as (
SELECT distinct a.subdoc_id,
a.testo v_cig
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'cig' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr10 as (
SELECT distinct a.subdoc_id,
a.testo v_note_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'noteCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
/* JIRA 5764
,subdocattr11 as (
*/
/*SELECT distinct a.subdoc_id,
a.testo v_data_sospensione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'data_sospensione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)*/
/* JIRA 5764
select a.subdoc_id,to_char(a.subdoc_sosp_data,'dd/mm/yyyy') v_data_sospensione from
siac_t_subdoc_sospensione a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)*/
,subdocattr12 as (
SELECT distinct a.subdoc_id,
a.testo v_data_esecuzione_pagamento
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataEsecuzionePagamento' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr13 as (
SELECT distinct a.subdoc_id,
a.testo v_annotazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'annotazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr14 as (
SELECT distinct a.subdoc_id,
a.testo v_num_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'numeroCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr15 as (
SELECT distinct a.subdoc_id,
a.testo v_data_scadenza_dopo_sospensione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataScadenzaDopoSospensione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
/* JIRA 5764
,subdocattr16 as (
*/
/*SELECT distinct a.subdoc_id,
a.testo v_data_riattivazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'data_riattivazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)*/
/* JIRA 5764
select a.subdoc_id,to_char(a.subdoc_sosp_data_riattivazione,'dd/mm/yyyy')  v_data_riattivazione
from
siac_t_subdoc_sospensione a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
*/
,subdocattr17 as (
SELECT distinct a.subdoc_id,
a.testo v_causale_ordinativo
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'causaleOrdinativo' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr18 as (
SELECT distinct a.subdoc_id,
a.testo v_note
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'Note' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr19 as (
SELECT distinct a.subdoc_id,
a.testo v_data_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
/* JIRA 5764
,subdocattr20 as (*/
/*SELECT distinct a.subdoc_id,
a.testo v_causale_sospensione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'causale_sospensione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)*/
/* JIRA 5764
select
	    a.subdoc_id
		,to_char(a.subdoc_sosp_data,'dd/mm/yyyy') v_data_sospensione
		,to_char(a.subdoc_sosp_data_riattivazione,'dd/mm/yyyy')  v_data_riattivazione
        ,a.subdoc_sosp_causale v_causale_sospensione from
siac_t_subdoc_sospensione a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)*/
,soggsub as (
  with sogg1 as (
  select distinct a.subdoc_id,b.soggetto_code soggetto_code_subdoc,
  f.soggetto_stato_desc soggetto_stato_desc_subdoc,
  b.partita_iva partita_iva_subdoc, b.codice_fiscale codice_fiscale_subdoc,
  b.codice_fiscale_estero codice_fiscale_estero_subdoc,
   b.soggetto_id soggetto_id_subdoc
   from
  siac_r_subdoc_sog a, siac_t_soggetto b ,siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.soggetto_id=b.soggetto_id
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
    AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  --and b.soggetto_id=1862
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale ragione_sociale_subdoc  from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome nome_subdoc, h.cognome cognome_subdoc from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  ),
  sogg4 as (
  SELECT a.soggetto_id_da, a.soggetto_id_a
    FROM siac.siac_r_soggetto_relaz a, siac.siac_d_relaz_tipo b
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and
    a.relaz_tipo_id = b.relaz_tipo_id
    AND   b.relaz_tipo_code  = 'SEDE_SECONDARIA'
    AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
    AND   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
    AND   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL)
    ,
sogg5 as (select
c.soggetto_id,d.soggetto_tipo_desc soggetto_tipo_desc_subdoc
 from siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d where c.ente_proprietario_id=p_ente_proprietario_id and
  d.soggetto_tipo_id=c.soggetto_tipo_id
  and c.data_cancellazione is null
  and d.data_cancellazione is NULL
  AND p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  )
  select sogg1.*, sogg2.ragione_sociale_subdoc,sogg3.nome_subdoc, sogg3.cognome_subdoc,
  case when sogg4.soggetto_id_da is not null then 'S' else NULL::varchar end v_sede_secondaria_subdoc
  , sogg5.soggetto_tipo_desc_subdoc
  from sogg1 left join sogg2 on sogg1.soggetto_id_subdoc=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id_subdoc=sogg3.soggetto_id
  left join sogg4 on sogg1.soggetto_id_subdoc=sogg4.soggetto_id_a
  left join sogg5 on sogg1.soggetto_id_subdoc=sogg5.soggetto_id
  ),
  imp as (select distinct
  c.movgest_id,b.movgest_ts_id,
a.subdoc_id,
case when g.movgest_ts_tipo_code ='T' then b.movgest_ts_code else NULL::varchar end v_cod_impegno,
case when g.movgest_ts_tipo_code ='T' then c.movgest_desc else NULL::varchar end v_desc_impegno,
case when g.movgest_ts_tipo_code ='S' then b.movgest_ts_code else NULL::varchar end v_cod_subimpegno,
case when g.movgest_ts_tipo_code ='S' then b.movgest_ts_desc else NULL::varchar end v_desc_subimpegno,
e.anno v_bil_anno,
c.movgest_anno v_anno_impegno,
c.movgest_numero v_num_impegno,
g.movgest_ts_tipo_code
from
siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, siac_t_movgest c, siac_t_bil d,
siac_t_periodo e, siac_d_movgest_tipo f, siac_d_movgest_ts_tipo g
where b.movgest_ts_id=A.movgest_ts_id
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and c.movgest_id=b.movgest_id
and d.bil_id=c.bil_id
and e.periodo_id=d.periodo_id
and f.movgest_tipo_id=c.movgest_tipo_id
and g.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and f.movgest_tipo_code = 'I'
and a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null),
modpag as (
with modpag0 as (
with modpag1 as (
SELECT
a.subdoc_id,b.quietanziante, b.quietanzante_nascita_data, b.quietanziante_nascita_luogo, b.quietanziante_nascita_stato,
b.bic, b.contocorrente ,b.contocorrente_intestazione,b.iban , b.note , b.data_scadenza,b.accredito_tipo_id,
 b.soggetto_id,a.soggrelmpag_id, b.modpag_id
FROM siac.siac_r_subdoc_modpag a, siac.siac_t_modpag b where
a.ente_proprietario_id=p_ente_proprietario_id and
b.modpag_id = a.modpag_id
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is NULL
and b.data_cancellazione is NULL
)
,actipo as (
select a.accredito_tipo_id,
a.accredito_tipo_code ,
a.accredito_tipo_desc
 from siac.siac_d_accredito_tipo a where a.ente_proprietario_id=p_ente_proprietario_id and
a.data_cancellazione is NULL),
relmodpag as ( SELECT
 a.soggrelmpag_id,
b.soggetto_id_a v_soggetto_id_modpag_cess
 FROM  siac.siac_r_soggrel_modpag a, siac.siac_r_soggetto_relaz b
 WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.soggetto_relaz_id = b.soggetto_relaz_id
 AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
 AND   a.data_cancellazione IS NULL
 AND   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
 AND   b.data_cancellazione IS NULL
 )
 select
modpag1.subdoc_id,
modpag1.quietanziante v_quietanziante,
modpag1.quietanzante_nascita_data v_data_nasciata_quietanziante,
modpag1.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
modpag1.quietanziante_nascita_stato v_stato_nascita_quietanziante,
modpag1.bic v_bic, modpag1.contocorrente v_contocorrente,
modpag1.contocorrente_intestazione v_intestazione_contocorrente,
modpag1.iban v_iban, modpag1.note v_note_mod_pag, modpag1.data_scadenza v_data_scadenza_mod_pag,
modpag1.accredito_tipo_id,
 modpag1.soggetto_id v_soggetto_id_modpag_nocess,
modpag1.soggrelmpag_id v_soggrelmpag_id, modpag1.modpag_id v_mod_pag_id,
actipo.accredito_tipo_code v_cod_tipo_accredito,
actipo.accredito_tipo_desc v_desc_tipo_accredito,
case when modpag1.soggrelmpag_id IS NULL THEN modpag1.soggetto_id else relmodpag.v_soggetto_id_modpag_cess
 end v_soggetto_id_modpag
 from modpag1 left join actipo
on modpag1.accredito_tipo_id=actipo.accredito_tipo_id
left join relmodpag on relmodpag.soggrelmpag_id=modpag1.soggrelmpag_id
)
,
 soggmodpag as (
  with sogg1 as (
  select distinct b.soggetto_code, d.soggetto_tipo_desc, f.soggetto_stato_desc,
  b.partita_iva, b.codice_fiscale, b.codice_fiscale_estero,
   b.soggetto_id
   from
  siac_t_soggetto b ,siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d,siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  b.ente_proprietario_id=p_ente_proprietario_id
  and c.soggetto_id=b.soggetto_id
  and d.soggetto_tipo_id=c.soggetto_tipo_id
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  --and b.soggetto_id=1862
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  )
  select sogg1.*, sogg2.ragione_sociale,sogg3.nome, sogg3.cognome
  from sogg1 left join sogg2 on sogg1.soggetto_id=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id=sogg3.soggetto_id
  )
select modpag0.*,soggmodpag.soggetto_code v_cod_sogg_mod_pag, soggmodpag.soggetto_tipo_desc v_tipo_sogg_mod_pag,
soggmodpag.soggetto_stato_desc v_stato_sogg_mod_pag, soggmodpag.ragione_sociale v_rag_sociale_sogg_mod_pag,
soggmodpag.partita_iva v_p_iva_sogg_mod_pag, soggmodpag.codice_fiscale v_cf_sogg_mod_pag,
soggmodpag.codice_fiscale_estero v_cf_estero_sogg_mod_pag,
soggmodpag.nome v_nome_sogg_mod_pag, soggmodpag.cognome v_cognome_sogg_mod_pag
 from modpag0
left join soggmodpag on soggmodpag.soggetto_id=modpag0.v_soggetto_id_modpag
),
ord as (
SELECT
a.subdoc_id,
c.ord_anno, c.ord_numero, b.ord_ts_code, g.anno
    FROM  siac_r_subdoc_ordinativo_ts a, siac_t_ordinativo_ts b, siac_t_ordinativo c,
          siac_r_ordinativo_stato d, siac_d_ordinativo_stato e,
          siac.siac_t_bil f, siac.siac_t_periodo g
    WHERE b.ord_ts_id = a.ord_ts_id
    AND   c.ord_id = b.ord_id
    AND   d.ord_id = c.ord_id
    AND   d.ord_stato_id = e.ord_stato_id
    AND   c.bil_id = f.bil_id
    AND   g.periodo_id = f.periodo_id
    AND   e.ord_stato_code <> 'A'
    AND   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL
    AND   c.data_cancellazione IS NULL
    AND   d.data_cancellazione IS NULL
    AND   e.data_cancellazione IS NULL
    AND   f.data_cancellazione IS NULL
    AND   g.data_cancellazione IS NULL
    AND   p_data between a.validita_inizio and COALESCE(a.validita_fine,p_data)
    AND   p_data between d.validita_inizio and COALESCE(d.validita_fine,p_data)
    )
  select doc.ente_proprietario_id v_ente_proprietario_id,
  doc.ente_denominazione v_ente_denominazione,
  doc.subdoc_id,
  doc.doc_anno v_anno_doc, doc.doc_numero v_num_doc,
  doc.doc_desc v_desc_doc,
  doc.doc_importo v_importo_doc,
  doc.doc_beneficiariomult v_beneficiario_multiplo_doc,
  doc.doc_data_emissione v_data_emissione_doc,
  doc.doc_data_scadenza v_data_scadenza_doc,
  bollo.codbollo_code v_codice_bollo_doc, bollo.codbollo_desc v_desc_codice_bollo_doc,
 doc.doc_collegato_cec v_collegato_cec_doc,
  pcccod.pcccod_code v_cod_pcc_doc,pcccod.pcccod_desc v_desc_pcc_doc
  ,pccuff.pccuff_code v_cod_ufficio_doc,pccuff.pccuff_desc v_desc_ufficio_doc,
  doc.doc_stato_code v_cod_stato_doc, doc.doc_stato_desc v_desc_stato_doc,
   doc.doc_fam_tipo_code v_cod_famiglia_doc, doc.doc_fam_tipo_desc v_desc_famiglia_doc,
doc.doc_tipo_code v_cod_tipo_doc, doc.doc_tipo_desc v_desc_tipo_doc,
doc.subdoc_numero v_num_subdoc, doc.subdoc_desc v_desc_subdoc,doc.subdoc_importo v_importo_subdoc,
doc.subdoc_nreg_iva v_num_reg_iva_subdoc, doc.subdoc_data_scadenza v_data_scadenza_subdoc,
doc.subdoc_convalida_manuale v_convalida_manuale_subdoc, doc.subdoc_importo_da_dedurre v_importo_da_dedurre_subdoc,
doc.subdoc_splitreverse_importo v_splitreverse_importo_subdoc,
doc.subdoc_pagato_cec v_pagato_cec_subdoc,
doc.subdoc_data_pagamento_cec v_data_pagamento_cec_subdoc,
doc.doc_contabilizza_genpcc v_doc_contabilizza_genpcc,
sogg.soggetto_id v_sogg_id_doc,sogg.soggetto_code v_cod_sogg_doc, sogg.soggetto_tipo_desc v_tipo_sogg_doc,
sogg.soggetto_stato_desc v_stato_sogg_doc,sogg.ragione_sociale v_rag_sociale_sogg_doc,
sogg.partita_iva v_p_iva_sogg_doc,
sogg.codice_fiscale v_cf_sogg_doc,
sogg.codice_fiscale_estero v_cf_estero_sogg_doc,
sogg.nome v_nome_sogg_doc, sogg.cognome v_cognome_sogg_doc,
reguni.rudoc_registrazione_anno,reguni.rudoc_registrazione_numero,reguni.rudoc_registrazione_data,
case when cdr.doc_cdr_cdr_code is not null then null::varchar else cdc.doc_cdc_cdc_code::varchar end cdc_code,
case when cdr.doc_cdr_cdr_code is not null then null::varchar else cdc.doc_cdc_cdc_desc::varchar end cdc_desc,
case when cdr.doc_cdr_cdr_code is not null then cdr.doc_cdr_cdr_code::varchar else cdc.doc_cdc_cdr_code::varchar end cdr_code,
-- 13.06.2018 SIAC-6246
-- case when cdr.doc_cdr_cdr_code is not null then cdc.doc_cdc_cdr_code::varchar else cdc.doc_cdc_cdr_desc::varchar end cdr_desc,
-- 13.06.2018 SIAC-6246
case when cdr.doc_cdr_cdr_code is not null then cdr.doc_cdr_cdr_desc::varchar else cdc.doc_cdc_cdr_desc::varchar end cdr_desc,
attoamm.attoamm_anno v_anno_atto_amministrativo, attoamm.attoamm_numero v_num_atto_amministrativo,
attoamm.attoamm_oggetto v_oggetto_atto_amministrativo, attoamm.attoamm_note v_note_atto_amministrativo,
attoamm.attoamm_stato_code v_cod_stato_atto_amministrativo, attoamm.attoamm_stato_desc v_desc_stato_atto_amministrativo,
attoamm.attoamm_tipo_code v_cod_tipo_atto_amministrativo, attoamm.attoamm_tipo_desc v_desc_tipo_atto_amministrativo,
attoamm.attoamm_cdc_code v_cod_cdc_atto_amministrativo,attoamm.attoamm_cdc_desc v_desc_cdc_atto_amministrativo,
attoamm.attoamm_cdr_code v_cod_cdr_atto_amministrativo,attoamm.attoamm_cdr_desc v_desc_cdr_atto_amministrativo,
commt.comm_tipo_code,commt.comm_tipo_desc v_tipo_commissione_subdoc,
eldocattall.subdoc_id,eldocattall.eldoc_id,
eldocattall.eldoc_anno v_anno_elenco_doc,
eldocattall.eldoc_numero v_num_elenco_doc,
eldocattall.eldoc_data_trasmissione v_data_trasmissione_elenco_doc,
eldocattall.eldoc_tot_quoteentrate v_tot_quote_entrate_elenco_doc,
eldocattall.eldoc_tot_quotespese v_tot_quote_spese_elenco_doc,
eldocattall.eldoc_tot_dapagare v_tot_da_pagare_elenco_doc,
eldocattall.eldoc_tot_daincassare v_tot_da_incassare_elenco_doc,
eldocattall.eldoc_stato_code v_cod_stato_elenco_doc,
eldocattall.eldoc_stato_desc v_desc_stato_elenco_doc,
eldocattall.attoal_id,
eldocattall.attoal_causale v_causale_atto_allegato,
eldocattall.attoal_altriallegati v_altri_allegati_atto_allegato, eldocattall.attoal_dati_sensibili v_dati_sensibili_atto_allegato,
eldocattall.attoal_data_scadenza v_data_scadenza_atto_allegato, eldocattall.attoal_note v_note_atto_allegato,
eldocattall.attoal_annotazioni v_annotazioni_atto_allegato, eldocattall.attoal_pratica v_pratica_atto_allegato,
eldocattall.attoal_responsabile_amm v_resp_amm_atto_allegato, eldocattall.attoal_responsabile_con v_resp_contabile_atto_allegato,
eldocattall.attoal_titolario_anno v_anno_titolario_atto_allegato,
eldocattall.attoal_titolario_numero v_num_titolario_atto_allegato, eldocattall.attoal_versione_invio_firma v_vers_invio_firma_atto_allegato,
eldocattall.attoal_stato_code v_cod_stato_atto_allegato, eldocattall.attoal_stato_desc v_desc_stato_atto_allegato,
eldocattall.ragione_sociale_atto_allegato v_rag_sociale_sogg_atto_allegato,
eldocattall.nome_atto_allegato v_nome_sogg_atto_allegato,
eldocattall.cognome_atto_allegato v_cognome_sogg_atto_allegato,
eldocattall.soggetto_code_atto_allegato v_cod_sogg_atto_allegato,
eldocattall.soggetto_tipo_desc_atto_allegato v_tipo_sogg_atto_allegato,
eldocattall.soggetto_stato_desc_atto_allegato v_stato_sogg_atto_allegato,
eldocattall.partita_iva_atto_allegato v_p_iva_sogg_atto_allegato,
eldocattall.codice_fiscale_atto_allegato v_cf_sogg_atto_allegato,
eldocattall.codice_fiscale_estero_atto_allegato v_cf_estero_sogg_atto_allegato,
eldocattall.soggetto_id_atto_allegato v_sogg_id_atto_allegato,
doc.doc_gruppo_tipo_code v_cod_gruppo_doc, doc.doc_gruppo_tipo_desc v_desc_gruppo_doc,
notes.notetes_desc v_note_tesoriere_subdoc,
dist.dist_code v_cod_distinta_subdoc, dist.dist_desc v_desc_distinta_subdoc,
contes.contotes_desc v_conto_tesoreria_subdoc,
split.sriva_tipo_code v_cod_tipo_splitrev , split.sriva_tipo_desc v_desc_tipo_splitrev,
liq.liq_anno v_anno_liquidazione,liq.liq_numero v_num_liquidazione,liq.liq_stato_desc v_liq_stato_desc,
subcltipoavviso.cod_tipo_avviso v_cod_tipo_avviso,subcltipoavviso.desc_tipo_avviso v_desc_tipo_avviso,
docattr1.v_registro_repertorio,
docattr2.v_anno_repertorio,
docattr3.v_num_repertorio,
docattr4.v_data_repertorio,
docattr5.v_data_ricezione_portale,
docattr6.v_dataOperazionePagamentoIncasso,
docattr7.v_flagPagataIncassata,
docattr8.v_notePagamentoIncasso,
-- 	SIAC-5229
docattr9.v_arrotondamento,
--
subdocattr1.v_rilevante_iva,
subdocattr2.v_ordinativo_singolo,
subdocattr3.v_esproprio,
subdocattr4.v_certificazione,
subdocattr5.v_ordinativo_manuale,
subdocattr6.v_avviso,
subdocattr7.v_num_mutuo,
subdocattr8.v_cup,
subdocattr9.v_cig,
subdocattr10.v_note_certificazione,
null::varchar v_data_sospensione, --subdocattr20.v_data_sospensione,--subdocattr11.v_data_sospensione, JIRA 5764
subdocattr12.v_data_esecuzione_pagamento,
subdocattr13.v_annotazione,
subdocattr14.v_num_certificazione,
subdocattr15.v_data_scadenza_dopo_sospensione,
null::varchar v_data_riattivazione,--subdocattr20.v_data_riattivazione,--subdocattr16.v_data_riattivazione, JIRA 5764
subdocattr17.v_causale_ordinativo,
subdocattr18.v_note,
subdocattr19.v_data_certificazione,
null::varchar v_causale_sospensione, --subdocattr20.v_causale_sospensione,JIRA 5764
soggsub.soggetto_code_subdoc v_cod_sogg_subdoc,
soggsub.soggetto_tipo_desc_subdoc v_tipo_sogg_subdoc,
soggsub.soggetto_stato_desc_subdoc v_stato_sogg_subdoc,
soggsub.partita_iva_subdoc v_p_iva_sogg_subdoc,
soggsub.codice_fiscale_subdoc v_cf_sogg_subdoc,
soggsub.codice_fiscale_estero_subdoc v_cf_estero_sogg_subdoc,
soggsub.soggetto_id_subdoc v_soggetto_id,
soggsub.nome_subdoc v_nome_sogg_subdoc,
soggsub.cognome_subdoc v_cognome_sogg_subdoc, soggsub.ragione_sociale_subdoc v_rag_sociale_sogg_subdoc,
soggsub.v_sede_secondaria_subdoc v_sede_secondaria_subdoc,
imp.v_cod_impegno v_cod_impegno,
imp.v_desc_impegno v_desc_impegno,
imp.v_cod_subimpegno v_cod_subimpegno,
imp.v_desc_subimpegno v_desc_subimpegno,
imp.v_bil_anno v_bil_anno,
imp.v_anno_impegno v_anno_impegno,
imp.v_num_impegno v_num_impegno,
imp.movgest_ts_tipo_code,
modpag.v_quietanziante v_quietanziante,
modpag.v_data_nasciata_quietanziante,
modpag.v_luogo_nascita_quietanziante,
modpag.v_stato_nascita_quietanziante,
modpag.v_bic, modpag.v_contocorrente,
modpag.v_intestazione_contocorrente,
modpag.v_iban, modpag.v_note_mod_pag, modpag.v_data_scadenza_mod_pag,
modpag.accredito_tipo_id,
modpag.v_soggetto_id_modpag_nocess,
modpag.v_soggrelmpag_id, modpag.v_mod_pag_id,
modpag.v_cod_tipo_accredito v_cod_tipo_accredito,
modpag.v_desc_tipo_accredito v_desc_tipo_accredito,
modpag.v_soggetto_id_modpag,
modpag.v_cod_sogg_mod_pag, modpag.v_tipo_sogg_mod_pag,
modpag.v_stato_sogg_mod_pag, modpag.v_rag_sociale_sogg_mod_pag,
modpag.v_p_iva_sogg_mod_pag, modpag.v_cf_sogg_mod_pag,
modpag.v_cf_estero_sogg_mod_pag,
modpag.v_nome_sogg_mod_pag, modpag.v_cognome_sogg_mod_pag,
ord.subdoc_id,
ord.ord_anno v_anno_ord, ord.ord_numero v_num_ord, ord.ord_ts_code v_num_subord, ord.anno v_bil_anno_ord,
doc.doc_sdi_lotto_siope,
doc.siope_documento_tipo_code, doc.siope_documento_tipo_desc, doc.siope_documento_tipo_desc_bnkit,
doc.siope_documento_tipo_analogico_code, doc.siope_documento_tipo_analogico_desc, doc.siope_documento_tipo_analogico_desc_bnkit,
doc.siope_tipo_debito_code, doc.siope_tipo_debito_desc, doc.siope_tipo_debito_desc_bnkit,
doc.siope_assenza_motivazione_code, doc.siope_assenza_motivazione_desc, doc.siope_assenza_motivazione_desc_bnkit,
doc.siope_scadenza_motivo_code, doc.siope_scadenza_motivo_desc, doc.siope_scadenza_motivo_desc_bnkit,
doc.doc_id, -- SIAC-5573,
-- 15.05.2018 Sofia siac-6124
eldocattall.data_ins_atto_allegato,
eldocattall.data_sosp_atto_allegato,
eldocattall.causale_sosp_atto_allegato,
eldocattall.data_riattiva_atto_allegato,
eldocattall.data_completa_atto_allegato,
eldocattall.data_convalida_atto_allegato
from doc
left join bollo on doc.codbollo_id=bollo.codbollo_id
left join sogg on doc.doc_id=sogg.doc_id
left join reguni on doc.doc_id=reguni.doc_id
left join cdc on doc.doc_id=cdc.doc_id
left join cdr on doc.doc_id=cdr.doc_id
left join pcccod on doc.pcccod_id=pcccod.pcccod_id
left join pccuff on doc.pccuff_id=pccuff.pccuff_id
left join attoamm on doc.subdoc_id=attoamm.subdoc_id
left join commt on doc.comm_tipo_id=commt.comm_tipo_id
left join eldocattall on doc.subdoc_id=eldocattall.subdoc_id
left join notes on doc.notetes_id=notes.notetes_id
left join dist  on doc.dist_id=dist.dist_id
left join contes on doc.contotes_id=contes.contotes_id
left join split on doc.subdoc_id=split.subdoc_id
left join liq on doc.subdoc_id=liq.subdoc_id --origina multipli
left join  subcltipoavviso on doc.subdoc_id=subcltipoavviso.subdoc_id
left join docattr1 on doc.doc_id=docattr1.doc_id
left join docattr2 on doc.doc_id=docattr2.doc_id
left join docattr3 on doc.doc_id=docattr3.doc_id
left join docattr4 on doc.doc_id=docattr4.doc_id
left join docattr5 on doc.doc_id=docattr5.doc_id
left join docattr6 on doc.doc_id=docattr6.doc_id
left join docattr7 on doc.doc_id=docattr7.doc_id
left join docattr8 on doc.doc_id=docattr8.doc_id
left join docattr9 on doc.doc_id=docattr9.doc_id
left join subdocattr1 on doc.subdoc_id=subdocattr1.subdoc_id
left join subdocattr2 on doc.subdoc_id=subdocattr2.subdoc_id
left join subdocattr3 on doc.subdoc_id=subdocattr3.subdoc_id
left join subdocattr4 on doc.subdoc_id=subdocattr4.subdoc_id
left join subdocattr5 on doc.subdoc_id=subdocattr5.subdoc_id
left join subdocattr6 on doc.subdoc_id=subdocattr6.subdoc_id
left join subdocattr7 on doc.subdoc_id=subdocattr7.subdoc_id
left join subdocattr8 on doc.subdoc_id=subdocattr8.subdoc_id
left join subdocattr9 on doc.subdoc_id=subdocattr9.subdoc_id
left join subdocattr10 on doc.subdoc_id=subdocattr10.subdoc_id
--left join subdocattr11 on doc.subdoc_id=subdocattr11.subdoc_id
left join subdocattr12 on doc.subdoc_id=subdocattr12.subdoc_id
left join subdocattr13 on doc.subdoc_id=subdocattr13.subdoc_id
left join subdocattr14 on doc.subdoc_id=subdocattr14.subdoc_id
left join subdocattr15 on doc.subdoc_id=subdocattr15.subdoc_id
--left join subdocattr16 on doc.subdoc_id=subdocattr16.subdoc_id
left join subdocattr17 on doc.subdoc_id=subdocattr17.subdoc_id
left join subdocattr18 on doc.subdoc_id=subdocattr18.subdoc_id
left join subdocattr19 on doc.subdoc_id=subdocattr19.subdoc_id
--left join subdocattr20 on doc.subdoc_id=subdocattr20.subdoc_id jira 5764
left join soggsub on soggsub.subdoc_id = doc.subdoc_id
left join imp on imp.subdoc_id=doc.subdoc_id
left join modpag on modpag.subdoc_id=doc.subdoc_id
left join ord on ord.subdoc_id = doc.subdoc_id
) as tb;


esito:= 'Fine funzione carico documenti spesa (FNC_SIAC_DWH_DOCUMENTO_SPESA) - '||clock_timestamp();
RETURN NEXT;

update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;

end if;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico documenti spesa (FNC_SIAC_DWH_DOCUMENTO_SPESA) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

-- SIAC-6246 - FINE