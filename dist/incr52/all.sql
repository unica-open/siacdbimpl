/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--SIAC-6429 - Maurizio - INIZIO

DROP FUNCTION if exists siac.fnc_bilr_stampa_mastrino(p_ente_prop_id integer, p_anno varchar, p_data_reg_da date, p_data_reg_a date, p_pdce_v_livello varchar, p_ambito varchar);

CREATE OR REPLACE FUNCTION siac.fnc_bilr_stampa_mastrino (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_reg_da date,
  p_data_reg_a date,
  p_pdce_v_livello varchar,
  p_ambito varchar
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

--SIAC-6429 11/09/2018.
-- veniva aggiunto un giorno per far estrarre anche le date che avevano ora e minuti settati,
-- pero' questo causava l'estrazione anche delle prime note del giorno successivo.
-- Pertanto il parametro e' lasciato cosi' come arriva, mentre la data  pnota_dataregistrazionegiornale
-- viene troncata al giorno (senza ora e minuti) nelle varie query dove e'
-- confrontata.
   -- p_data_reg_a:=date_trunc('day', to_timestamp(to_char(p_data_reg_a,'dd/mm/yyyy'),'dd/mm/yyyy')) + interval '1 day';

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
    --SIAC-6429 aggiunto il date_trunc('day'
    and   date_trunc('day',pn.pnota_dataregistrazionegiornale) between p_data_reg_da
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
--SIAC-6279: 26/06/2018.
-- La data di registrazione e' la pnota_dataregistrazionegiornale
-- che e' sempre valorizzata perche' sono estratte solo le prime note
-- in stato definitivio.
--m.data_creazione::date  data_registrazione,
m.pnota_dataregistrazionegiornale::date  data_registrazione,
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
        --SIAC-6429 aggiunto il date_trunc('day'
        date_trunc('day',m.pnota_dataregistrazionegiornale) between
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
--SIAC-6279: 26/06/2018.
-- nel caso di impegni e accertamenti la data di riferimento e' quella di 
-- creazione del movimento
--null::date data_det_rif,
q.data_creazione::date data_det_rif,
--SIAC-6279: 26/06/2018.
-- La data di registrazione e' la pnota_dataregistrazionegiornale
-- che e' sempre valorizzata perche' sono estratte solo le prime note
-- in stato definitivio.
--m.data_creazione::date  data_registrazione,
m.pnota_dataregistrazionegiornale::date  data_registrazione,
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
        --SIAC-6429 aggiunto il date_trunc('day'
        date_trunc('day',m.pnota_dataregistrazionegiornale) between
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
--SIAC-6279: 26/06/2018.
-- nel caso di sub-impegni e sub-accertamenti la data di riferimento e' 
-- quella di creazione del movimento
--null::date data_det_rif,
q.data_creazione::date data_det_rif,
--SIAC-6279: 26/06/2018.
-- La data di registrazione e' la pnota_dataregistrazionegiornale
-- che e' sempre valorizzata perche' sono estratte solo le prime note
-- in stato definitivio.
--m.data_creazione::date  data_registrazione,
m.pnota_dataregistrazionegiornale::date  data_registrazione,
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
        --SIAC-6429 aggiunto il date_trunc('day'
        date_trunc('day',m.pnota_dataregistrazionegiornale) between
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
--SIAC-6279: 26/06/2018.
-- La data di registrazione e' la pnota_dataregistrazionegiornale
-- che e' sempre valorizzata perche' sono estratte solo le prime note
-- in stato definitivio.
--a.data_creazione::date  data_registrazione,
a.pnota_dataregistrazionegiornale::date  data_registrazione,
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
--SIAC-6429 aggiunto il date_trunc('day'
and   date_trunc('day',a.pnota_dataregistrazionegiornale) between  p_data_reg_da and
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
--SIAC-6279: 26/06/2018.
-- La data di registrazione e' la pnota_dataregistrazionegiornale
-- che e' sempre valorizzata perche' sono estratte solo le prime note
-- in stato definitivio.
--m.data_creazione::date  data_registrazione,
m.pnota_dataregistrazionegiornale::date  data_registrazione,
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
        --SIAC-6429 aggiunto il date_trunc('day'
        date_trunc('day',m.pnota_dataregistrazionegiornale) between
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
--SIAC-6279: 26/06/2018.
-- La data di registrazione e' la pnota_dataregistrazionegiornale
-- che e' sempre valorizzata perche' sono estratte solo le prime note
-- in stato definitivio.
--m.data_creazione::date  data_registrazione,
m.pnota_dataregistrazionegiornale::date  data_registrazione,
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
        --SIAC-6429 aggiunto il date_trunc('day'
        date_trunc('day',m.pnota_dataregistrazionegiornale) between
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
--SIAC-6279: 26/06/2018.
-- La data di registrazione e' la pnota_dataregistrazionegiornale
-- che e' sempre valorizzata perche' sono estratte solo le prime note
-- in stato definitivio.
--m.data_creazione::date  data_registrazione,
m.pnota_dataregistrazionegiornale::date  data_registrazione,
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
--SIAC-6429 aggiunto il date_trunc('day'
 date_trunc('day',m.pnota_dataregistrazionegiornale) between
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

--SIAC-6429 - Maurizio - FINE

--SIAC-6193
DROP FUNCTION if exists fnc_siac_cons_entita_reversale_from_capitoloentrata (integer,  integer, integer);

DROP FUNCTION if exists fnc_siac_cons_entita_reversale_from_capitoloentrata (integer,  varchar,integer, integer);


CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_reversale_from_capitoloentrata (
  _uid_capitoloentrata integer,
  _filtro_crp varchar, -- 12.07.2018 Sofia jira SIAC-6193 C,R
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
  ueb_numero varchar,
  capitolo_desc varchar,
  capitolo_anno varchar,
  provc_anno integer,
  provc_numero numeric,
  provc_data_convalida timestamp,
  ord_quietanza_data timestamp,
  -- 12.07.2018 Sofia jira siac-6193
  conto_tesoreria varchar,
  distinta_code varchar,
  distinta_desc varchar,
  ord_split     varchar,
  ord_ritenute  varchar
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
	_test VARCHAR := 'test';
rec record;
v_ord_id integer;
v_ord_ts_id integer;
v_attoamm_id integer;
BEGIN

	for rec in
     -- 12.07.2018 Sofia jira SIAC-6193 C,R
     WITH
      movimenti as
      (
      select rmov.ord_ts_id, mov.movgest_anno
      from   siac_r_movgest_bil_elem re,siac_t_movgest mov,
             siac_t_movgest_ts ts, siac_r_ordinativo_ts_movgest_ts rmov
      where  re.elem_id=_uid_capitoloentrata
      and    mov.movgest_id=re.movgest_id
      and    ts.movgest_id=mov.movgest_id
      and    rmov.movgest_ts_id=ts.movgest_ts_id
      and    re.data_cancellazione is null
      and    now() BETWEEN re.validita_inizio and COALESCE(re.validita_fine,now())
      and    mov.data_cancellazione is null
      and    now() BETWEEN mov.validita_inizio and COALESCE(mov.validita_fine,now())
      and    ts.data_cancellazione is null
      and    now() BETWEEN ts.validita_inizio and COALESCE(ts.validita_fine,now())
      and    rmov.data_cancellazione is null
      and    now() BETWEEN rmov.validita_inizio and COALESCE(rmov.validita_fine,now())
      ),
      ordinativi as
      (
		select
			a.elem_id,
			c2.anno,
			a.elem_code,
			a.elem_code2,
			a.elem_code3,
			d.ord_id,
			d.ord_anno,
			d.ord_numero,
			d.ord_desc,
			d.ord_emissione_data,
			g.ord_stato_desc,
			h.ord_ts_id,
			h.ord_ts_code,
            -- 12.07.2018 Sofia jira siac-6193
            d.contotes_id,
            d.dist_id
		from
			siac_t_bil_elem a,
			siac_t_bil b2,
			siac_t_periodo c2,
			siac_r_ordinativo_bil_elem b,
			siac_t_ordinativo d,
			siac_d_ordinativo_tipo e,
			siac_r_ordinativo_stato f,
			siac_d_ordinativo_stato g,
			siac_t_ordinativo_ts h
		where a.bil_id=b2.bil_id
		and c2.periodo_id=b2.periodo_id
		and a.elem_id=_uid_capitoloentrata
		and b.elem_id=a.elem_id
		and d.ord_id=b.ord_id
		and e.ord_tipo_id=d.ord_tipo_id
		and e.ord_tipo_code='I'
		and f.ord_id=d.ord_id
		and g.ord_stato_id=f.ord_stato_id
		and h.ord_id = d.ord_id
		and now() BETWEEN f.validita_inizio and COALESCE(f.validita_fine,now())
		and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
		and b.data_cancellazione is null
		and d.data_cancellazione is null
		and b2.data_cancellazione is null
		and c2.data_cancellazione is null
		and e.data_cancellazione is null
		and h.data_cancellazione is null
       )
       -- 12.07.2018 Sofia jira SIAC-6193 C,R
       select ordinativi.*
       from ordinativi, movimenti
       where ordinativi.ord_ts_id=movimenti.ord_ts_id
       and   ( case when coalesce(_filtro_crp,'')='C' then ordinativi.ord_anno=movimenti.movgest_anno
      			    when coalesce(_filtro_crp,'')='R' then movimenti.movgest_anno<ordinativi.ord_anno
                    else true end )
	   LIMIT _limit
	   OFFSET _offset

		loop
			uid:=rec.ord_id;
			capitolo_anno:=rec.anno;
			capitolo_numero:=rec.elem_code;
			capitolo_articolo:=rec.elem_code2;
			ueb_numero:=rec.elem_code3;
			ord_numero:=rec.ord_numero;
			ord_desc:=rec.ord_desc;
			ord_emissione_data:=rec.ord_emissione_data;
            
			v_ord_id:=rec.ord_id;
			ord_stato_desc:=rec.ord_stato_desc;
			v_ord_ts_id:=rec.ord_ts_id;
			ord_ts_code:=rec.ord_ts_code;

			select
				f.ord_ts_det_importo
			into
				importo
			from
				siac_t_ordinativo_ts e,
				siac_t_ordinativo_ts_det f,
				siac_d_ordinativo_ts_det_tipo g
			where e.ord_ts_id=v_ord_ts_id
			and f.ord_ts_id=e.ord_ts_id
			and g.ord_ts_det_tipo_id=f.ord_ts_det_tipo_id
			and g.ord_ts_det_tipo_code='A'
			and e.data_cancellazione is null
			and f.data_cancellazione is null
			and g.data_cancellazione is null;

			select
				y.soggetto_code,
				y.soggetto_desc
			into
				soggetto_code,
				soggetto_desc
			from
				siac_r_ordinativo_soggetto z,
				siac_t_soggetto y
			where z.soggetto_id=y.soggetto_id
			and now() BETWEEN z.validita_inizio
			and COALESCE(z.validita_fine,now())
			and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
			and z.data_cancellazione is null
			and y.data_cancellazione is null
			and z.ord_id=v_ord_id;

			select
				q.attoamm_id,
				q.attoamm_numero,
				q.attoamm_anno,
				t.attoamm_stato_desc,
				r.attoamm_tipo_code,
				r.attoamm_tipo_desc
			into
				v_attoamm_id,
				attoamm_numero,
				attoamm_anno,
				attoamm_stato_desc,
				attoamm_tipo_code,
				attoamm_tipo_desc
			from
				siac_r_ordinativo_atto_amm p,
				siac_t_atto_amm q,
				siac_d_atto_amm_tipo r,
				siac_r_atto_amm_stato s,
				siac_d_atto_amm_stato t
			where p.attoamm_id=q.attoamm_id
			and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
			and r.attoamm_tipo_id=q.attoamm_tipo_id
			and s.attoamm_id=q.attoamm_id
			and t.attoamm_stato_id=s.attoamm_stato_id
			and now() BETWEEN s.validita_inizio and COALESCE(s.validita_fine,now())
			and p.ord_id=v_ord_id
			and p.data_cancellazione is null
			and q.data_cancellazione is null
			and r.data_cancellazione is null
			and s.data_cancellazione is null
			and t.data_cancellazione is null;

			--sac
			select
				y.classif_code,
				y.classif_desc
			into
				attoamm_sac_code,
				attoamm_sac_desc
			from
				siac_r_atto_amm_class z,
				siac_t_class y,
				siac_d_class_tipo x
			where z.classif_id=y.classif_id
			and x.classif_tipo_id=y.classif_tipo_id
			and x.classif_tipo_code IN ('CDC', 'CDR')
			and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
			and z.attoamm_id=v_attoamm_id;

            --SIAC-5899
            SELECT
                siac_r_ordinativo_quietanza.ord_quietanza_data
            INTO
                ord_quietanza_data
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
                AND siac_T_Ordinativo.ord_Id = v_ord_id
                AND siac_t_oil_ricevuta.data_cancellazione is null
                AND siac_T_Ordinativo.data_cancellazione is null
                AND siac_d_oil_ricevuta_tipo.data_cancellazione is null
                AND siac_r_ordinativo_quietanza.data_cancellazione is null;

            -- 12.07.2018 Sofia jira siac-6193
            conto_tesoreria:=null;
            select conto.contotes_code into conto_tesoreria
            from siac_d_contotesoreria conto
            where conto.contotes_id=rec.contotes_id;

            distinta_code:=null;
            distinta_desc:=null;
            select d.dist_code, d.dist_desc
                   into distinta_code, distinta_desc
            from siac_d_distinta d
            where d.dist_id=rec.dist_id;

            -- 12.07.2018 Sofia jira siac-6193
            ord_split:=null;
           	select tipo.relaz_tipo_code into ord_split
            from siac_r_ordinativo rOrd, siac_d_relaz_tipo tipo,
                 siac_r_ordinativo_stato rstato,siac_d_ordinativo_stato stato
  		    where rord.ord_id_a=rec.ord_id
            and   tipo.relaz_tipo_id=rord.relaz_tipo_id
            and   tipo.relaz_tipo_code='SPR'
			and   rstato.ord_id=rOrd.ord_id_da
            and   stato.ord_stato_id=rstato.ord_stato_id
			and   stato.ord_stato_code!='A'
            and   rord.data_cancellazione is null
	        and   now() between rord.validita_inizio and coalesce(rord.validita_fine, now())
   		    and   rstato.data_cancellazione is null
			and   now() between rstato.validita_inizio and coalesce(rstato.validita_fine, now())
            limit 1;
			if ord_split is not null then
                 ord_split:='S';
            else ord_split:='N';
            end if;

            -- 12.07.2018 Sofia jira siac-6193
            ord_ritenute:=null;
            select tipo.relaz_tipo_code into ord_ritenute
            from siac_r_ordinativo rOrd, siac_d_relaz_tipo tipo,
                 siac_r_ordinativo_stato rstato,siac_d_ordinativo_stato stato
  		    where rord.ord_id_a=rec.ord_id
            and   tipo.relaz_tipo_id=rord.relaz_tipo_id
            and   tipo.relaz_tipo_code='RIT_ORD'
			and   rstato.ord_id=rOrd.ord_id_da
            and   stato.ord_stato_id=rstato.ord_stato_id
			and   stato.ord_stato_code!='A'
            and   rord.data_cancellazione is null
	        and   now() between rord.validita_inizio and coalesce(rord.validita_fine, now())
   		    and   rstato.data_cancellazione is null
			and   now() between rstato.validita_inizio and coalesce(rstato.validita_fine, now())
            limit 1;
            if ord_ritenute is not null then
                 ord_ritenute:='S';
            else ord_ritenute:='N';
            end if;

			return next;
		end loop;
	return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata (integer, integer, integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata (integer, varchar, integer, integer);

DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata (integer, varchar, varchar, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata (
  _uid_capitoloentrata integer,
  _anno varchar,
  _filtro_crp varchar, -- 12.07.2018 Sofia jira SIAC-6193 C,R,P, altro per tutto
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  accertamento_anno integer,
  accertamento_numero numeric,
  accertamento_desc varchar,
  soggetto_code varchar,
  soggetto_desc varchar,
  accertamento_stato_desc varchar,
  importo numeric,
  
  capitolo_anno integer,
  capitolo_numero integer,
  capitolo_articolo integer,
  
  
  ueb_numero varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  pdc_code varchar,
  pdc_desc varchar,
  -- 12.07.2018 Sofia jira siac-6193
  attoamm_oggetto varchar
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
	rec record;
	v_movgest_ts_id integer;
	v_attoamm_id integer;
BEGIN

	for rec in
		select
			a.elem_id,
			c2.anno,
			a.elem_code,
			a.elem_code2,
			a.elem_code3,
			e.movgest_ts_id,
			c.movgest_anno,
			c.movgest_numero,
			c.movgest_desc,
			f.movgest_ts_det_importo,
			l.movgest_stato_desc,
			c.movgest_id,
			n.classif_code pdc_code,
			n.classif_desc pdc_desc
		from
			siac_t_bil_elem a,
			siac_t_bil b2,
			siac_t_periodo c2,
			siac_r_movgest_bil_elem b,
			siac_t_movgest c,
			siac_d_movgest_tipo d,
			siac_t_movgest_ts e,
			siac_t_movgest_ts_det f,
			siac_d_movgest_ts_tipo g,
			siac_d_movgest_ts_det_tipo h,
			siac_r_movgest_ts_stato i,
			siac_d_movgest_stato l,
			siac_r_movgest_class m,
			siac_t_class n,
			siac_d_class_tipo o,
			siac_t_bil p,
			siac_t_periodo q
		where a.bil_id=b2.bil_id
		and c2.periodo_id=b2.periodo_id
		and c.movgest_id=b.movgest_id
		and b.elem_id=a.elem_id
		and d.movgest_tipo_id=c.movgest_tipo_id
		and e.movgest_id=c.movgest_id
		and f.movgest_ts_id=e.movgest_ts_id
		and g.movgest_ts_tipo_id=e.movgest_ts_tipo_id
		and h.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
		and l.movgest_stato_id=i.movgest_stato_id
		and i.movgest_ts_id=e.movgest_ts_id
		and m.movgest_ts_id = e.movgest_ts_id
		and n.classif_id = m.classif_id
		and o.classif_tipo_id = n.classif_tipo_id
		and p.bil_id = c.bil_id
		and q.periodo_id = p.periodo_id
		and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
		and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
		and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
		and b.data_cancellazione is null
		and c.data_cancellazione is null
		and d.data_cancellazione is null
		and e.data_cancellazione is null
		and f.data_cancellazione is null
		and g.data_cancellazione is null
		and h.data_cancellazione is null
		and i.data_cancellazione is null
		and l.data_cancellazione is null
		and m.data_cancellazione is null
		and n.data_cancellazione is null
		and o.data_cancellazione is null
		and d.movgest_tipo_code='A'
		and g.movgest_ts_tipo_code='T'
		and h.movgest_ts_det_tipo_code='A'
		and o.classif_tipo_code IN ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
		and a.elem_id=_uid_capitoloentrata
		and q.anno = _anno
        -- 12.07.2018 Sofia jira siac-6193
        and (case when coalesce(_filtro_crp,'X')='R' then c.movgest_anno<_anno::integer
                  when coalesce(_filtro_crp,'X')='C' then c.movgest_anno=_anno::integer
                  when coalesce(_filtro_crp,'X')='P' then c.movgest_anno>_anno::integer
                  else true end )
		order by
			c.movgest_anno,
			c.movgest_numero
		LIMIT _limit
		OFFSET _offset

		loop

			uid:=rec.movgest_id;
			capitolo_anno:=rec.anno::integer;
			capitolo_numero:=rec.elem_code::integer;
			capitolo_articolo:=rec.elem_code2::integer;
			ueb_numero:=rec.elem_code3;
			v_movgest_ts_id:=rec.movgest_ts_id;
			accertamento_anno:=rec.movgest_anno;
			accertamento_numero:=rec.movgest_numero;
			accertamento_desc:=rec.movgest_desc;
			importo:=rec.movgest_ts_det_importo;
			accertamento_stato_desc:=rec.movgest_stato_desc;
			pdc_code:=rec.pdc_code;
			pdc_desc:=rec.pdc_desc;

			select
				y.soggetto_code,
				y.soggetto_desc
			into
				soggetto_code,
				soggetto_desc
			from
				siac_r_movgest_ts_sog z,
				siac_t_soggetto y
			where z.soggetto_id=y.soggetto_id
			and now() BETWEEN z.validita_inizio
			and COALESCE(z.validita_fine,now())
			and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
			and z.data_cancellazione is null
			and y.data_cancellazione is null
			and z.movgest_ts_id=v_movgest_ts_id;

			--classe di soggetti
			if soggetto_code is null then

				select
					l.soggetto_classe_code,
					l.soggetto_classe_desc
				into
					soggetto_code,
					soggetto_desc
				from
					siac_t_soggetto g,
					siac_r_movgest_ts_sogclasse h,
					siac_r_soggetto_classe i,
					siac_d_soggetto_classe l
				where g.soggetto_id=i.soggetto_id
				and h.soggetto_classe_id=l.soggetto_classe_id
				and i.soggetto_classe_id=l.soggetto_classe_id
				and now() between h.validita_inizio and coalesce(h.validita_fine, now())
				and g.data_cancellazione is null
				and h.data_cancellazione is null
				and now() between i.validita_inizio and coalesce(i.validita_fine, now())
				and h.movgest_ts_id=v_movgest_ts_id;
			end if;

			select
				q.attoamm_id,
				q.attoamm_numero,
				q.attoamm_anno,
				t.attoamm_stato_desc,
				r.attoamm_tipo_code,
				r.attoamm_tipo_desc,
                -- 12.07.2018 Sofia jira siac-6193
                q.attoamm_oggetto
			into
				v_attoamm_id,
				attoamm_numero,
				attoamm_anno,
				attoamm_stato_desc,
				attoamm_tipo_code,
				attoamm_tipo_desc,
                attoamm_oggetto
			from
				siac_r_movgest_ts_atto_amm p,
				siac_t_atto_amm q,
				siac_d_atto_amm_tipo r,
				siac_r_atto_amm_stato s,
				siac_d_atto_amm_stato t
			where p.attoamm_id=q.attoamm_id
			and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
			and r.attoamm_tipo_id=q.attoamm_tipo_id
			and s.attoamm_id=q.attoamm_id
			and t.attoamm_stato_id=s.attoamm_stato_id
			and now() BETWEEN s.validita_inizio and COALESCE(s.validita_fine,now())
			and p.movgest_ts_id=rec.movgest_ts_id
			and p.data_cancellazione is null
			and q.data_cancellazione is null
			and r.data_cancellazione is null
			and s.data_cancellazione is null
			and t.data_cancellazione is null;

			--sac
			select
				y.classif_code,
				y.classif_desc
			into
				attoamm_sac_code,
				attoamm_sac_desc
			from
				siac_r_atto_amm_class z,
				siac_t_class y,
				siac_d_class_tipo x
			where z.classif_id=y.classif_id
			and x.classif_tipo_id=y.classif_tipo_id
			and x.classif_tipo_code  IN ('CDC', 'CDR')
			and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
			and z.attoamm_id=v_attoamm_id;

			return next;

		end loop;

	return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_provvedimento (integer, integer, integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_provvedimento (integer, varchar, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_impegno_from_provvedimento (
  _uid_provvedimento integer,
  _anno varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  impegno_anno integer,
  impegno_numero numeric,
  impegno_desc varchar,
  impegno_stato varchar,
  impegno_importo numeric,
  soggetto_code varchar,
  soggetto_desc varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  --attoamm_oggetto varchar,
  attoamm_desc varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  pdc_code varchar,
  pdc_desc varchar,
  -- 26.06.2018 Sofia siac-6193
  impegno_anno_capitolo integer,
  impegno_nro_capitolo  integer,
  impegno_nro_articolo  integer,
  impegno_flag_prenotazione varchar,
  impegno_cup varchar,
  impegno_cig varchar,
  impegno_tipo_debito varchar,
  impegno_motivo_assenza_cig varchar
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
		with attoammsac as (
			with attoamm as (
				select
					g.movgest_id uid,
					g.movgest_anno  impegno_anno,
					g.movgest_numero impegno_numero,
					g.movgest_desc impegno_desc,
					m.movgest_stato_desc impegno_stato,
					n.movgest_ts_det_importo impegno_importo,
					a.attoamm_numero,
					a.attoamm_anno,
                    a.attoamm_oggetto ,
					b.attoamm_tipo_code,
					b.attoamm_tipo_desc,
					d.attoamm_stato_desc,
					f.movgest_ts_id,
					a.attoamm_id,
					q.classif_code pdc_code,
					q.classif_desc pdc_desc,
                    f.siope_tipo_debito_id, -- 26.06.2018 Sofia siac-6193
                    f.siope_assenza_motivazione_id -- 26.06.2018 Sofia siac-6193
				from

					siac_t_atto_amm a,
					siac_d_atto_amm_tipo b,
					siac_r_atto_amm_stato c,
					siac_d_atto_amm_stato d,
					siac_r_movgest_ts_atto_amm e,
                    siac_t_bil_elem bilelem,
                    siac_r_movgest_bil_elem rmovgestbilelem,
					siac_t_movgest g,
					siac_d_movgest_tipo h,
					siac_d_movgest_ts_tipo i,
					siac_r_movgest_ts_stato l,
					siac_d_movgest_stato m,
					siac_t_movgest_ts_det n,
					siac_d_movgest_ts_det_tipo o,
					siac_r_movgest_class p,
					siac_t_class q,
					siac_d_class_tipo r,
					siac_t_bil s,
					siac_t_periodo t,
                    siac_t_movgest_ts f
				where b.attoamm_tipo_id=a.attoamm_tipo_id
				and c.attoamm_id=a.attoamm_id
				and d.attoamm_stato_id=c.attoamm_stato_id
				and e.attoamm_id=a.attoamm_id
				and f.movgest_ts_id=e.movgest_ts_id
				and g.movgest_id=f.movgest_id

                and bilelem.elem_id = rmovgestbilelem.elem_id
                and rmovgestbilelem.movgest_id = g.movgest_id
				and rmovgestbilelem.data_cancellazione is null
                and bilelem.data_cancellazione is null

				and h.movgest_tipo_id=g.movgest_tipo_id
				and i.movgest_ts_tipo_id=f.movgest_ts_tipo_id
				and l.movgest_ts_id=f.movgest_ts_id
				and l.movgest_stato_id=m.movgest_stato_id
				and n.movgest_ts_id=f.movgest_ts_id
				and o.movgest_ts_det_tipo_id=n.movgest_ts_det_tipo_id
				and p.movgest_ts_id = f.movgest_ts_id
				and q.classif_id = p.classif_id
				and r.classif_tipo_id = q.classif_tipo_id
				and s.bil_id = g.bil_id
				and t.periodo_id = s.periodo_id

				and now() BETWEEN c.validita_inizio and COALESCE(c.validita_fine,now())
				and now() BETWEEN e.validita_inizio and COALESCE(e.validita_fine,now())
				and now() BETWEEN l.validita_inizio and COALESCE(l.validita_fine,now())
				and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
				and a.data_cancellazione is null
				and b.data_cancellazione is null
				and c.data_cancellazione is null
				and d.data_cancellazione is null
				and e.data_cancellazione is null
				and f.data_cancellazione is null
				and g.data_cancellazione is null
				and h.data_cancellazione is null
				and i.data_cancellazione is null
				and l.data_cancellazione is null
				and m.data_cancellazione is null
				and n.data_cancellazione is null
				and o.data_cancellazione is null
				and p.data_cancellazione is null
				and q.data_cancellazione is null
				and r.data_cancellazione is null
				and s.data_cancellazione is null
				and t.data_cancellazione is null
				and a.attoamm_id=_uid_provvedimento
				and h.movgest_tipo_code='I'
				and i.movgest_ts_tipo_code='T'
				and o.movgest_ts_det_tipo_code='A'
				and r.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
				and t.anno = _anno
			),
			sac as (
				select
					f.attoamm_id,
					g.classif_code,
					g.classif_desc
				from
					siac_r_atto_amm_class f,
					siac_t_class g,
					siac_d_class_tipo h
				where f.classif_id=g.classif_id
				and h.classif_tipo_id=g.classif_tipo_id
				and h.classif_tipo_code in ('CDR','CDC')
				and now() BETWEEN f.validita_inizio and COALESCE(f.validita_fine,now())
				and f.data_cancellazione is null
				and g.data_cancellazione is null
				and h.data_cancellazione is null
			)
			select
				attoamm.uid,
				attoamm.impegno_anno,
				attoamm.impegno_numero,
				attoamm.impegno_desc,
				attoamm.impegno_stato,
				attoamm.impegno_importo,
				attoamm.attoamm_numero,
				attoamm.attoamm_anno,
				attoamm.attoamm_oggetto,
				attoamm.attoamm_tipo_code,
				attoamm.attoamm_tipo_desc,
				attoamm.attoamm_stato_desc,
				attoamm.movgest_ts_id,
				sac.classif_code attoamm_sac_code,
				sac.classif_desc attoamm_sac_desc,
				attoamm.pdc_code pdc_code,
				attoamm.pdc_desc pdc_desc,
                attoamm.siope_tipo_debito_id, -- 26.06.2018 Sofia siac-6193
                attoamm.siope_assenza_motivazione_id -- 26.06.2018 Sofia siac-6193
			from attoamm
			left outer join sac on attoamm.attoamm_id=sac.attoamm_id
		),
		sogg as (
			select
				z.movgest_ts_id,
				y.soggetto_code,
				y.soggetto_desc
			from
				siac_r_movgest_ts_sog z,
				siac_t_soggetto y
			where z.soggetto_id=y.soggetto_id
			and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
			and z.data_cancellazione is null
			and y.data_cancellazione is null
		),
    -- 26.06.2018 Sofia siac-6193
    capitolo as
    (
    select r.movgest_id,
           e.elem_code::integer nro_capitolo,
           e.elem_code2::integer nro_articolo,
           per.anno::integer anno_capitolo
    from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,siac_r_movgest_bil_elem r,
         siac_t_bil bil, siac_t_periodo per
    where tipo.elem_tipo_code='CAP-UG'
    and   e.elem_tipo_id=tipo.elem_tipo_id
    and   r.elem_id=e.elem_id
    and   bil.bil_id=e.bil_id
    and   per.periodo_id=bil.periodo_id
    and   e.data_cancellazione is null
    and   now() BETWEEN e.validita_inizio and COALESCE(e.validita_fine,now())
    and   r.data_cancellazione is null
    and   now() BETWEEN r.validita_inizio and COALESCE(r.validita_fine,now())
    ),
    -- 26.06.2018 Sofia siac-6193
    flagPrenotazione as
    (
    select rattr.movgest_ts_id,
           rattr.boolean
    from siac_r_movgest_ts_attr rattr, siac_t_attr attr
    where attr.attr_code='flagPrenotazione'
    and   rattr.attr_id=attr.attr_id
    and   rattr.data_cancellazione is null
    and   now() BETWEEN rattr.validita_inizio and COALESCE(rattr.validita_fine,now())
    ),
    cup as
    (
    select rattr.movgest_ts_id,
           rattr.testo
    from siac_r_movgest_ts_attr rattr, siac_t_attr attr
    where attr.attr_code='cup'
    and   rattr.attr_id=attr.attr_id
    and   rattr.data_cancellazione is null
    and   now() BETWEEN rattr.validita_inizio and COALESCE(rattr.validita_fine,now())
    ),
    cig as
    (
    select rattr.movgest_ts_id,
           rattr.testo
    from siac_r_movgest_ts_attr rattr, siac_t_attr attr
    where attr.attr_code='cig'
    and   rattr.attr_id=attr.attr_id
    and   rattr.data_cancellazione is null
    and   now() BETWEEN rattr.validita_inizio and COALESCE(rattr.validita_fine,now())
    )
	select
			attoammsac.uid,
			attoammsac.impegno_anno,
			attoammsac.impegno_numero,
			attoammsac.impegno_desc,
			attoammsac.impegno_stato,
			attoammsac.impegno_importo,
			sogg.soggetto_code,
			sogg.soggetto_desc,
			attoammsac.attoamm_numero,
			attoammsac.attoamm_anno,
			attoammsac.attoamm_oggetto attoamm_desc,
			attoammsac.attoamm_tipo_code,
			attoammsac.attoamm_tipo_desc,
			attoammsac.attoamm_stato_desc,
			attoammsac.attoamm_sac_code,
			attoammsac.attoamm_sac_desc,
			attoammsac.pdc_code pdc_code,
			attoammsac.pdc_desc pdc_desc,
            -- 26.06.2018 Sofia siac-6193
		    capitolo.anno_capitolo impegno_anno_capitolo,
            capitolo.nro_capitolo  impegno_nro_capitolo,
            capitolo.nro_articolo  impegno_nro_articolo,
            coalesce(flagPrenotazione.boolean,'N')::varchar impegno_flag_prenotazione,
            coalesce(cup.testo,' ') impegno_cup,
            coalesce(cig.testo,' ') impegno_cig,
            coalesce(deb.siope_tipo_debito_desc,' ') impegno_tipo_debito,
            coalesce(ass.siope_assenza_motivazione_desc,' ') impegno_motivo_assenza_cig

		from attoammsac
		left outer join sogg on attoammsac.movgest_ts_id=sogg.movgest_ts_id
        -- 26.06.2018 Sofia siac-6193
        left outer join capitolo on attoammsac.uid=capitolo.movgest_id
        left outer join flagPrenotazione on attoammsac.movgest_ts_id = flagPrenotazione.movgest_ts_id
        left outer join cup  on attoammsac.movgest_ts_id = cup.movgest_ts_id
        left outer join cig  on attoammsac.movgest_ts_id = cig.movgest_ts_id
        left outer join siac_d_siope_assenza_motivazione ass on attoammsac.siope_assenza_motivazione_id=ass.siope_assenza_motivazione_id
        left outer join siac_d_siope_tipo_debito deb on attoammsac.siope_tipo_debito_id=deb.siope_tipo_debito_id

		order by
			attoammsac.impegno_anno,
			attoammsac.impegno_numero
		LIMIT _limit
		OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

DROP FUNCTION if EXISTS fnc_siac_cons_entita_impegno_from_capitolospesa (integer, integer,integer);
DROP FUNCTION if EXISTS fnc_siac_cons_entita_impegno_from_capitolospesa (integer, varchar, integer,integer);
DROP FUNCTION if EXISTS fnc_siac_cons_entita_impegno_from_capitolospesa (integer, varchar, varchar, integer,integer);

-- _filtro_crp da rinominare: e' il filtro che discrimina COMPETENZA, RESIDUO, PLURIENNALE
CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_impegno_from_capitolospesa (
  _uid_capitolospesa integer,
  _anno varchar,
  _filtro_crp varchar, -- 11.07.2018 Sofia jira SIAC-6193 C,R,P, altro per tutto
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  impegno_anno integer,
  impegno_numero numeric,
  impegno_desc varchar,
  impegno_stato varchar,
  impegno_importo numeric,
  soggetto_code varchar,
  soggetto_desc varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  --attoamm_oggetto varchar,
  attoamm_desc varchar,

  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  pdc_code varchar,
  pdc_desc varchar,
  -- 29.06.2018 Sofia siac-6193
  impegno_anno_capitolo integer,
  impegno_nro_capitolo  integer,
  impegno_nro_articolo  integer,
  impegno_flag_prenotazione varchar,
  impegno_cup varchar,
  impegno_cig varchar,
  impegno_tipo_debito varchar,
  impegno_motivo_assenza_cig varchar
) AS
$body$
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
            		soggall.impegno_tipo_debito
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
            				zzz.impegno_tipo_debito
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
                                    c.siope_tipo_debito_id
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
                                impegno_cup.testo  impegno_cup
							from impegno
                              left outer join soggetto on impegno.movgest_ts_id=soggetto.movgest_ts_id
                              left outer join impegno_flag_prenotazione on impegno.movgest_ts_id=impegno_flag_prenotazione.movgest_ts_id
                              left outer join impegno_cig on impegno.movgest_ts_id=impegno_cig.movgest_ts_id
                              left outer join impegno_cup on impegno.movgest_ts_id=impegno_cup.movgest_ts_id
                              left outer join siope_assenza_motivazione on impegno.siope_assenza_motivazione_id=siope_assenza_motivazione.siope_assenza_motivazione_id
                              left outer join siope_tipo_debito on impegno.siope_tipo_debito_id=siope_tipo_debito.siope_tipo_debito_id
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
                imp_sogg.impegno_tipo_debito
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
            imp_sogg_attoamm.impegno_motivo_assenza_cig
		from imp_sogg_attoamm
		left outer join sac_attoamm on imp_sogg_attoamm.attoamm_id=sac_attoamm.attoamm_id
		order by
			imp_sogg_attoamm.movgest_anno,
			imp_sogg_attoamm.movgest_numero
		LIMIT _limit
		OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;



-- SIAC-5152: DROP FUNZIONE CON TRE (vecchia versione) E QUATTRO (nuova versione) PARAMETRI
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_soggetto (integer, integer, integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_soggetto (integer, varchar, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_accertamento_from_soggetto (
  _uid_soggetto integer,
  _anno varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  accertamento_anno integer,
  accertamento_numero numeric,
  accertamento_desc varchar,
  soggetto_code varchar,
  soggetto_desc varchar,
  accertamento_stato_desc varchar,
  importo numeric,
  capitolo_anno integer,
  capitolo_numero integer,
  capitolo_articolo integer,
  ueb_numero varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  pdc_code varchar,
  pdc_desc varchar,
  -- 12.07.2018 Sofia jira siac-6193
  attoamm_oggetto varchar

) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
	rec record;
	v_movgest_ts_id integer;
	v_attoamm_id integer;
BEGIN

	for rec in
		select
			a.elem_id,
			c2.anno,
			a.elem_code,
			a.elem_code2,
			a.elem_code3,
			e.movgest_ts_id,
			c.movgest_anno,
			c.movgest_numero  ,
			c.movgest_desc ,
			f.movgest_ts_det_importo ,
			l.movgest_stato_desc,
			c.movgest_id,
			n.soggetto_code,
			n.soggetto_desc,
			p.classif_code pdc_code,
			p.classif_desc pdc_desc
		from
			siac_t_bil_elem a,
			siac_t_bil b2,
			siac_t_periodo c2,
			siac_r_movgest_bil_elem b,
			siac_t_movgest c,
			siac_d_movgest_tipo d,
			siac_t_movgest_ts e,
			siac_t_movgest_ts_det f,
			siac_d_movgest_ts_tipo g,
			siac_d_movgest_ts_det_tipo h,
			siac_r_movgest_ts_stato i,
			siac_d_movgest_stato l,
			siac_r_movgest_ts_sog m,
			siac_t_soggetto n,
			siac_r_movgest_class o,
			siac_t_class p,
			siac_d_class_tipo q,
			siac_t_bil r,
			siac_t_periodo s
		where a.bil_id=b2.bil_id
		and c2.periodo_id=b2.periodo_id
		and c.movgest_id=b.movgest_id
		and b.elem_id=a.elem_id
		and d.movgest_tipo_id=c.movgest_tipo_id
		and e.movgest_id=c.movgest_id
		and f.movgest_ts_id=e.movgest_ts_id
		and g.movgest_ts_tipo_id=e.movgest_ts_tipo_id
		and h.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
		and i.movgest_ts_id=e.movgest_ts_id
		and l.movgest_stato_id=i.movgest_stato_id
		and m.movgest_ts_id=e.movgest_ts_id
		and n.soggetto_id=m.soggetto_id
		and o.movgest_ts_id=e.movgest_ts_id
		and p.classif_id=o.classif_id
		and q.classif_tipo_id=p.classif_tipo_id
		and r.bil_id = c.bil_id
		and s.periodo_id = r.periodo_id
		and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
		and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
		and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
		and now() BETWEEN o.validita_inizio and COALESCE(o.validita_fine,now())
		and m.data_cancellazione is null
		and b.data_cancellazione is null
		and c.data_cancellazione is null
		and d.data_cancellazione is null
		and e.data_cancellazione is null
		and f.data_cancellazione is null
		and g.data_cancellazione is null
		and h.data_cancellazione is null
		and i.data_cancellazione is null
		and l.data_cancellazione is null
		and m.data_cancellazione is null
		and n.data_cancellazione is null
		and o.data_cancellazione is null
		and p.data_cancellazione is null
		and q.data_cancellazione is null
		and r.data_cancellazione is null
		and s.data_cancellazione is null
		and d.movgest_tipo_code='A'
		and g.movgest_ts_tipo_code='T'
		and h.movgest_ts_det_tipo_code='A'
		and q.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
		and n.soggetto_id=_uid_soggetto
		and s.anno = _anno
		order by
			c.movgest_anno,
			c.movgest_numero
		LIMIT _limit
		OFFSET _offset

		loop

			uid:=rec.movgest_id;
            
			capitolo_anno:=rec.anno::integer;
			capitolo_numero:=rec.elem_code::integer;
			capitolo_articolo:=rec.elem_code2::integer;
            
			ueb_numero:=rec.elem_code3;
			v_movgest_ts_id:=rec.movgest_ts_id;
			accertamento_anno:=rec.movgest_anno;
			accertamento_numero:=rec.movgest_numero;
			accertamento_desc:=rec.movgest_desc;
			importo:=rec.movgest_ts_det_importo;
			accertamento_stato_desc:=rec.movgest_stato_desc;
			soggetto_code:=rec.soggetto_code;
			soggetto_desc:=rec.soggetto_desc;
			pdc_code:=rec.pdc_code;
			pdc_desc:=rec.pdc_desc;

			select
				y.soggetto_code,
				y.soggetto_desc
			into
				soggetto_code,
				soggetto_desc
			from
				siac_r_movgest_ts_sog z,
				siac_t_soggetto y
			where z.soggetto_id=y.soggetto_id
			and now() BETWEEN z.validita_inizio
			and COALESCE(z.validita_fine,now())
			and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
			and z.data_cancellazione is null
			and y.data_cancellazione is null
			and z.movgest_ts_id=v_movgest_ts_id;

			--classe di soggetti
			if soggetto_code is null then

				select
					l.soggetto_classe_code,
					l.soggetto_classe_desc
				into
					soggetto_code,
					soggetto_desc
				from
					siac_t_soggetto g,
					siac_r_movgest_ts_sogclasse h,
					siac_r_soggetto_classe i,
					siac_d_soggetto_classe l
				where g.soggetto_id=i.soggetto_id
				and h.soggetto_classe_id=l.soggetto_classe_id
				and i.soggetto_classe_id=l.soggetto_classe_id
				and now() between h.validita_inizio and coalesce(h.validita_fine, now())
				and g.data_cancellazione is null
				and h.data_cancellazione is null
				and now() between i.validita_inizio and coalesce(i.validita_fine, now())
				and h.movgest_ts_id=v_movgest_ts_id;
			end if;

			select
				q.attoamm_id,
				q.attoamm_numero,
				q.attoamm_anno,
				t.attoamm_stato_desc,
				r.attoamm_tipo_code,
				r.attoamm_tipo_desc,
                -- 12.07.2018 Sofia jira siac-6193
                q.attoamm_oggetto

			into
				v_attoamm_id,
				attoamm_numero,
				attoamm_anno,
				attoamm_stato_desc,
				attoamm_tipo_code,
				attoamm_tipo_desc,
                -- 12.07.2018 Sofia jira siac-6193
                attoamm_oggetto
			from
				siac_r_movgest_ts_atto_amm p,
				siac_t_atto_amm q,
				siac_d_atto_amm_tipo r,
				siac_r_atto_amm_stato s,
				siac_d_atto_amm_stato t
			where p.attoamm_id=q.attoamm_id
			and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
			and r.attoamm_tipo_id=q.attoamm_tipo_id
			and s.attoamm_id=q.attoamm_id
			and t.attoamm_stato_id=s.attoamm_stato_id
			and now() BETWEEN s.validita_inizio and COALESCE(s.validita_fine,now())
			and p.movgest_ts_id=rec.movgest_ts_id
			and p.data_cancellazione is null
			and q.data_cancellazione is null
			and r.data_cancellazione is null
			and s.data_cancellazione is null
			and t.data_cancellazione is null;

			--sac
			select
				y.classif_code,
				y.classif_desc
			into
				attoamm_sac_code,
				attoamm_sac_desc
			from
				siac_r_atto_amm_class z,
				siac_t_class y,
				siac_d_class_tipo x
			where z.classif_id=y.classif_id
			and x.classif_tipo_id=y.classif_tipo_id
			and x.classif_tipo_code  IN ('CDC', 'CDR')
			and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
			and z.attoamm_id=v_attoamm_id;

			return next;
		end loop;

	return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-5152: DROP FUNZIONE CON TRE (vecchia versione) E QUATTRO (nuova versione) PARAMETRI
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_provvedimento (integer, integer, integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_provvedimento (integer, varchar, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_accertamento_from_provvedimento (
  _uid_provvedimento integer,
  _anno varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  accertamento_anno integer,
  accertamento_numero numeric,
  accertamento_desc varchar,
  accertamento_stato_desc varchar,
  importo numeric,
  soggetto_code varchar,
  soggetto_desc varchar,
  
  capitolo_anno integer,
  capitolo_numero integer,
  capitolo_articolo integer,
  
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  pdc_code varchar,
  pdc_desc varchar,
  -- 12.07.2018 Sofia jira siac-6193
  attoamm_oggetto varchar

) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
	stringaTest character varying := 'stringa di test';
BEGIN

	RETURN QUERY
		with attoammsac as (
			with attoamm as (
				select g.movgest_id uid,
					g.movgest_anno accertamento_anno,
					g.movgest_numero accertamento_numero,
					g.movgest_desc accertamento_desc,
					m.movgest_stato_desc accertamento_stato_desc,
					n.movgest_ts_det_importo accertamento_importo,
					a.attoamm_numero,
					a.attoamm_anno,
					b.attoamm_tipo_code,
					b.attoamm_tipo_desc,
					d.attoamm_stato_desc,
					f.movgest_ts_id,
					a.attoamm_id,
					q.classif_code pdc_code,
					q.classif_desc pdc_desc,
                    -- 12.07.2018 Sofia jira siac-6193
                    a.attoamm_oggetto

				from siac_t_atto_amm a
				join siac_d_atto_amm_tipo b ON (b.attoamm_tipo_id=a.attoamm_tipo_id and b.data_cancellazione is null and a.data_cancellazione is null)
				join siac_r_atto_amm_stato c ON (c.attoamm_id=a.attoamm_id and c.data_cancellazione IS NULL and now() BETWEEN c.validita_inizio and COALESCE(c.validita_fine,now()))
				join siac_d_atto_amm_stato d on (d.attoamm_stato_id=c.attoamm_stato_id and d.data_cancellazione is null)
				join siac_r_movgest_ts_atto_amm e on (e.attoamm_id=a.attoamm_id and e.data_cancellazione is null and now() BETWEEN e.validita_inizio and COALESCE(e.validita_fine,now()))
				join siac_t_movgest_ts f ON (f.movgest_ts_id=e.movgest_ts_id and f.data_cancellazione is null)
				join siac_t_movgest g on (g.movgest_id=f.movgest_id and g.data_cancellazione is null)
				join siac_d_movgest_tipo h on (h.movgest_tipo_id=g.movgest_tipo_id and h.data_cancellazione is null)
				join siac_d_movgest_ts_tipo i on (i.movgest_ts_tipo_id=f.movgest_ts_tipo_id and i.data_cancellazione is null)
				join siac_r_movgest_ts_stato l on (l.movgest_ts_id=f.movgest_ts_id and l.data_cancellazione is null and now() BETWEEN l.validita_inizio and COALESCE(l.validita_fine,now()))
				join siac_d_movgest_stato m on (l.movgest_stato_id=m.movgest_stato_id and m.data_cancellazione is null)
				join siac_t_movgest_ts_det n on (n.movgest_ts_id=f.movgest_ts_id and n.data_cancellazione is null)
				join siac_d_movgest_ts_det_tipo o on (o.movgest_ts_det_tipo_id=n.movgest_ts_det_tipo_id and o.data_cancellazione is null)
				join siac_r_movgest_class p on (p.movgest_ts_id = f.movgest_ts_id and p.data_cancellazione is null and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine, now()))
				join siac_t_class q on (q.classif_id = p.classif_id and q.data_cancellazione is null)
				join siac_d_class_tipo r on (r.classif_tipo_id = q.classif_tipo_id and r.data_cancellazione is null)
				join siac_t_bil s on (s.bil_id = g.bil_id and s.data_cancellazione is null)
				join siac_t_periodo t on (t.periodo_id = s.periodo_id and t.data_cancellazione is null)
				where a.attoamm_id=_uid_provvedimento
				and h.movgest_tipo_code='A'
				and i.movgest_ts_tipo_code='T'
				and o.movgest_ts_det_tipo_code='A'
				and r.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
				and t.anno = _anno
			),
			sac as (
				select f.attoamm_id,
					g.classif_code,
					g.classif_desc
				from siac_r_atto_amm_class f
				join siac_t_class g on (f.classif_id=g.classif_id and g.data_cancellazione is null and f.data_cancellazione is null and now() BETWEEN f.validita_inizio and COALESCE(f.validita_fine,now()))
				join siac_d_class_tipo h on (h.classif_tipo_id=g.classif_tipo_id and h.data_cancellazione is null)
				where h.classif_tipo_code in ('CDR','CDC')
				and f.attoamm_id = _uid_provvedimento
			)
			select attoamm.uid,
				attoamm.accertamento_anno,
				attoamm.accertamento_numero,
				attoamm.accertamento_desc,
				attoamm.accertamento_stato_desc,
				attoamm.accertamento_importo,
				attoamm.attoamm_numero,
				attoamm.attoamm_anno,
				attoamm.attoamm_tipo_code,
				attoamm.attoamm_tipo_desc,
				attoamm.attoamm_stato_desc,
				attoamm.movgest_ts_id,
				sac.classif_code attoamm_sac_code,
				sac.classif_desc attoamm_sac_desc,
				attoamm.pdc_code,
				attoamm.pdc_desc,
                -- 12.07.2018 Sofia jira siac-6193
                attoamm.attoamm_oggetto
			from attoamm
			left outer join sac on attoamm.attoamm_id=sac.attoamm_id
		),
		sogg as (
			select z.movgest_ts_id,
				y.soggetto_code,
				y.soggetto_desc
			from siac_r_movgest_ts_sog z
			join siac_t_soggetto y on (z.soggetto_id=y.soggetto_id and y.data_cancellazione is null and z.data_cancellazione is null and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now()))
		),
		cap as (
			select
				a1.movgest_id,
				b1.elem_code as capitolo_numero,
				b1.elem_code2 as capitolo_articolo,
				d1.anno as capitolo_anno
			from siac_r_movgest_bil_elem a1
			join siac_t_bil_elem b1 on (a1.elem_id = b1.elem_id and a1.data_cancellazione IS NULL AND b1.data_cancellazione IS NULL)
			join siac_t_bil c1 on (c1.bil_id = b1.bil_id and c1.data_cancellazione is null)
			join siac_t_periodo d1 on (d1.periodo_id = c1.periodo_id and d1.data_cancellazione is null)
			WHERE now() BETWEEN a1.validita_inizio AND COALESCE(a1.validita_fine, now())
		)
		select attoammsac.uid,
			attoammsac.accertamento_anno,
			attoammsac.accertamento_numero,
			attoammsac.accertamento_desc,
			attoammsac.accertamento_stato_desc,
			attoammsac.accertamento_importo,
			sogg.soggetto_code,
			sogg.soggetto_desc,
			cap.capitolo_anno::integer,
			cap.capitolo_numero::integer,
			cap.capitolo_articolo::integer,
			attoammsac.attoamm_numero,
			attoammsac.attoamm_anno,
			attoammsac.attoamm_tipo_code,
			attoammsac.attoamm_tipo_desc,
			attoammsac.attoamm_stato_desc,
			attoammsac.attoamm_sac_code,
			attoammsac.attoamm_sac_desc,
			attoammsac.pdc_code,
			attoammsac.pdc_desc,
            -- 12.07.2018 Sofia jira siac-6193
            attoammsac.attoamm_oggetto
		from attoammsac
		left outer join sogg on attoammsac.movgest_ts_id=sogg.movgest_ts_id
		left outer join cap on attoammsac.uid = cap.movgest_id
		order by attoammsac.accertamento_anno,
			attoammsac.accertamento_numero
		LIMIT _limit
		OFFSET _offset;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

--fine siac-6193