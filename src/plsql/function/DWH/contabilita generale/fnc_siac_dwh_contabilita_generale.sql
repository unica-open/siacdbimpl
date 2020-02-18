/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_contabilita_generale (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE
/*
pdc        record;

impegni record;
documenti record;
liquidazioni_doc record;
liquidazioni_imp record;
ordinativi record;
ordinativi_imp record;

prima_nota record;
movimenti  record;
causale    record;
class      record;*/

v_user_table varchar;
params varchar;

BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_anno_bilancio IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Anno di bilancio nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   --IF p_anno_bilancio::integer < to_char(now(),'YYYY')::integer THEN
      --p_data = to_timestamp('31/12/'||p_anno_bilancio, 'dd/mm/yyyy');
   --ELSE
      p_data := now();
   --END IF;
END IF;

select fnc_siac_random_user()
into	v_user_table;

params := p_anno_bilancio||' - '||p_ente_proprietario_id::varchar||' - '||p_data::varchar;


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
'fnc_siac_dwh_contabilita_generale',
params,
clock_timestamp(),
v_user_table
);

esito:= 'Inizio funzione carico dati contabilita_generale (FNC_SIAC_DWH_CONTABILITA_GENERALE) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;
DELETE FROM siac.siac_dwh_contabilita_generale
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;

insert into siac_dwh_contabilita_generale

select
tb.ente_proprietario_id,
tb.ente_denominazione,
tb.bil_anno,
tb.desc_prima_nota,
tb.num_provvisorio_prima_nota,
tb.num_definitivo_prima_nota,
tb.data_registrazione_prima_nota,
tb.cod_stato_prima_nota,
tb.desc_stato_prima_nota,
tb.cod_mov_ep,
tb.desc_mov_ep,
tb.cod_mov_ep_dettaglio,
tb.desc_mov_ep_dettaglio,
tb.importo_mov_ep,
tb.segno_mov_ep,
tb.cod_piano_dei_conti,
tb.desc_piano_dei_conti,
tb.livello_piano_dei_conti,
tb.ordine_piano_dei_conti,
tb.cod_pdce_fam,
tb.desc_pdce_fam,
tb.cod_ambito,
tb.desc_ambito,
tb.cod_causale,
tb.desc_causale,
tb.cod_tipo_causale,
tb.desc_tipo_causale,
tb.cod_stato_causale,
tb.desc_stato_causale,
tb.cod_evento,
tb.desc_evento,
tb.cod_tipo_mov_finanziario,
tb.desc_tipo_mov_finanziario,
tb.cod_piano_finanziario,
tb.desc_piano_finanziario,
tb.anno_movimento,
tb.numero_movimento,
tb.cod_submovimento,
anno_ordinativo,
num_ordinativo,
num_subordinativo,
anno_liquidazione,
num_liquidazione,
anno_doc,
num_doc,
cod_tipo_doc,
data_emissione_doc,
cod_sogg_doc,
num_subdoc,
modifica_impegno,
entrate_uscite,
tb.cod_bilancio,
p_data data_elaborazione,
numero_ricecon,
tipo_evento -- SIAC-5641
,doc_id -- SIAC-5573
from
(
-- documenti
select tbdoc.*
from
(
  with
  movep as
  (
   select distinct
  	  a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno,
      m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,
      m.pnota_progressivogiornale num_definitivo_prima_nota,
	  m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
	  o.pnota_stato_code cod_stato_prima_nota,
	  o.pnota_stato_desc desc_stato_prima_nota,
	  l.movep_id, --da non visualizzare
	  l.movep_code cod_mov_ep,
	  l.movep_desc desc_mov_ep,
	  q.causale_ep_code cod_causale,
	  q.causale_ep_desc desc_causale,
	  r.causale_ep_tipo_code cod_tipo_causale,
	  r.causale_ep_tipo_desc desc_tipo_causale,
	  t.causale_ep_stato_code cod_stato_causale,
	  t.causale_ep_stato_desc desc_stato_causale,
      c.evento_code cod_evento,
      c.evento_desc desc_evento,
      d.collegamento_tipo_code cod_tipo_mov_finanziario,
      d.collegamento_tipo_desc desc_tipo_mov_finanziario,
      b.campo_pk_id ,
      q.causale_ep_id,
      g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
/*         left join siac_r_causale_ep_stato s on s.causale_ep_id=q.causale_ep_id  -- SIAC-5696 INIZIO
                                             and s.data_cancellazione is null
                                             and s.validita_fine is null
         left join siac_d_causale_ep_stato t on s.causale_ep_stato_id=t.causale_ep_stato_id
                                             and t.data_cancellazione is null,   -- SIAC-5696 FINE  */
         siac_r_causale_ep_stato s, -- SIAC-5941
         siac_d_causale_ep_stato t, -- SIAC-5941
         siac_d_causale_ep_tipo r
    WHERE
 		  a.ente_proprietario_id=p_ente_proprietario_id and
		  i.anno=p_anno_bilancio and
		  a.regmovfin_id = b.regmovfin_id and
          c.evento_id = b.evento_id AND
          d.collegamento_tipo_id = c.collegamento_tipo_id AND
          g.evento_tipo_id = c.evento_tipo_id AND
          e.regmovfin_id = a.regmovfin_id AND
          f.regmovfin_stato_id = e.regmovfin_stato_id AND
          p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data) and
          --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
          p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data) and
          --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
          h.bil_id = a.bil_id AND
          i.periodo_id = h.periodo_id AND
          l.regmovfin_id = a.regmovfin_id AND
          l.regep_id = m.pnota_id AND
          m.pnota_id = n.pnota_id AND
          o.pnota_stato_id = n.pnota_stato_id AND
          p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data) and
          --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
          p.ente_proprietario_id=a.ente_proprietario_id and
          q.causale_ep_id=l.causale_ep_id AND
          r.causale_ep_tipo_id=q.causale_ep_tipo_id and
          s.causale_ep_id=q.causale_ep_id AND -- SIAC-5941 -- SIAC-5696
          s.causale_ep_stato_id=t.causale_ep_stato_id and -- SIAC-5941 -- SIAC-5696
          --s.validita_fine is NULL and -- SIAC-5696
          o.pnota_stato_code <> 'A' and
          a.data_cancellazione IS NULL AND
          b.data_cancellazione IS NULL AND
          c.data_cancellazione IS NULL AND
          d.data_cancellazione IS NULL AND
          e.data_cancellazione IS NULL AND
          f.data_cancellazione IS NULL AND
          g.data_cancellazione IS NULL AND
          h.data_cancellazione IS NULL AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          m.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL AND
          o.data_cancellazione IS NULL AND
          p.data_cancellazione IS NULL AND
          --q.data_cancellazione IS NULL AND -- SIAC-5696
          r.data_cancellazione IS NULL AND
          --s.data_cancellazione IS NULL AND -- SIAC-5696
          --t.data_cancellazione IS NULL -- SIAC-5696
          (q.data_cancellazione IS NULL -- SIAC-5696 INIZIO
               OR
               q.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
               ) -- SIAC-5696 FINE
          and d.collegamento_tipo_code in ('SE','SS')
          and ((s.data_cancellazione is null and s.validita_fine is null) -- SIAC-5941 Integrazione INIZIO
                or s.causale_ep_stato_id =
               (select d_caus_stato.causale_ep_stato_id
                from   siac_d_causale_ep_stato d_caus_stato
                where  d_caus_stato.causale_ep_stato_id = s.causale_ep_stato_id
                and    d_caus_stato.causale_ep_stato_code = 'V'
                )
               )  -- SIAC-5941 Integrazione FINE
  ),
  movepdet as
  (
	with
    aa as
    (
	  select a.movep_id,
             b.pdce_conto_id,
	         a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
		     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
			 b.pdce_conto_code cod_piano_dei_conti,
		     b.pdce_conto_desc desc_piano_dei_conti,
	         b.livello livello_piano_dei_conti,
		     b.ordine ordine_piano_dei_conti,
		     d.pdce_fam_code cod_pdce_fam,
			 d.pdce_fam_desc desc_pdce_fam,
 		     e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c,siac_d_pdce_fam d,siac_d_ambito e
      where a.ente_proprietario_id= p_ente_proprietario_id
      and   b.pdce_conto_id=a.pdce_conto_id
      and   c.pdce_fam_tree_id=b.pdce_fam_tree_id
      and   d.pdce_fam_id=c.pdce_fam_id
      and   c.validita_fine is null
      and   e.ambito_id=a.ambito_id
	  and   a.data_cancellazione is null
--	  and   b.data_cancellazione is null -- 27.06.2018 Sofia jira siac-6282
	  and   c.data_cancellazione is null
	  and   d.data_cancellazione is null
	  and   e.data_cancellazione is null
   ),
   bb as
   (
   SELECT c.pdce_conto_id,
         case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
              when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
		      when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
		      when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
		      when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
		      when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
			  when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
			  else ''::varchar end as tipo_codifica,
		      a.codice_codifica_albero
   FROM siac_v_dwh_codifiche_econpatr a,
        siac_r_pdce_conto_class b,
        siac_t_pdce_conto c
   WHERE b.classif_id = a.classif_id
   AND   c.pdce_conto_id = b.pdce_conto_id
   and   c.ente_proprietario_id= p_ente_proprietario_id
--   and   c.data_cancellazione is null -- 27.06.2018 Sofia jira siac-6282
   and   b.data_cancellazione is NULL
   and   b.validita_fine is null
  )
  select aa.*,
         bb.tipo_codifica||'.'||  bb.codice_codifica_albero cod_bilancio
  from aa
       left join bb on aa.pdce_conto_id=bb.pdce_conto_id
  ),
  doc as
  (with
   aa as
   (
	select a.doc_id,
		   b.subdoc_id, b.subdoc_numero  num_subdoc,
		   a.doc_anno anno_doc,
		   a.doc_numero num_doc,
	       a.doc_data_emissione data_emissione_doc ,
		   c.doc_tipo_code cod_tipo_doc
	 from siac_t_doc a,siac_t_subdoc b,siac_d_doc_tipo c
	 where b.doc_id=a.doc_id
     and   a.ente_proprietario_id=p_ente_proprietario_id
     and   c.doc_tipo_id=a.doc_tipo_id
     and   a.data_cancellazione is null
     and   b.data_cancellazione is null
     and   c.data_cancellazione is NULL
   ),
   bb as
  (SELECT  a.doc_id,
           b.soggetto_code v_soggetto_code
   FROM   siac_r_doc_sog a, siac_t_soggetto b
   WHERE a.soggetto_id = b.soggetto_id
     and a.ente_proprietario_id=p_ente_proprietario_id
     and a.data_cancellazione is null
     and b.data_cancellazione is null
     and a.validita_fine is null
  )
  select -- SIAC-5573
         -- *
         aa.*,
         bb.v_soggetto_code
  From aa left join bb ON aa.doc_id=bb.doc_id
 ),
 pdc as
 (select distinct
         a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
         b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
  from siac_t_class a,siac_r_causale_ep_class b
  where a.ente_proprietario_id=p_ente_proprietario_id
  and   b.classif_id=a.classif_id
  -- and b.validita_fine is null
  and a.data_cancellazione is null
  -- and b.data_cancellazione is null
  and (b.data_cancellazione IS NULL -- SIAC-5941 Integrazione
       or
       b.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
      )
  )
  select movep.*,
         movepdet.* ,
         pdc.cod_piano_finanziario,pdc.desc_piano_finanziario,
        null::integer anno_movimento,
        null::numeric numero_movimento,
        null::varchar cod_submovimento,
        null::integer anno_ordinativo,
        null::numeric num_ordinativo,
        null::varchar num_subordinativo,
        null::integer anno_liquidazione,
        null::numeric num_liquidazione,
        -- SIAC-5573
        doc.doc_id,
        doc.anno_doc,
        doc.num_doc,
	    doc.cod_tipo_doc,
	    doc.data_emissione_doc,
	    doc.v_soggetto_code cod_sogg_doc,
	    doc.num_subdoc,
	    null::varchar modifica_impegno,
	    case -- SIAC-5601
	      when movepdet.cod_ambito = 'AMBITO_GSA' then
          case when movep.cod_tipo_mov_finanziario = 'SE' then 'E' else 'U' end
		  else  pdc.entrate_uscite
		end entrate_uscite,
       -- pdc.entrate_uscite,
       p_data data_elaborazione,
       null::integer numero_ricecon
    from movep
         left join movepdet on movep.movep_id=movepdet.movep_id
         left join doc      on movep.campo_pk_id=doc.subdoc_id
         left join pdc      on movep.causale_ep_id=pdc.causale_ep_id
) as tbdoc
-- impegni
UNION
select tbimp.*
from
(
-- imp
with
movep as
(
  select distinct
		 a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno,
	     m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,
	     m.pnota_progressivogiornale num_definitivo_prima_nota,
		 m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
		 o.pnota_stato_code cod_stato_prima_nota,
	     o.pnota_stato_desc desc_stato_prima_nota,
	     l.movep_id, --da non visualizzare
		 l.movep_code cod_mov_ep,
		 l.movep_desc desc_mov_ep,
	     q.causale_ep_code cod_causale,
	     q.causale_ep_desc desc_causale,
	     r.causale_ep_tipo_code cod_tipo_causale,
	     r.causale_ep_tipo_desc desc_tipo_causale,
	     t.causale_ep_stato_code cod_stato_causale,
	     t.causale_ep_stato_desc desc_stato_causale,
	     c.evento_code cod_evento,
         c.evento_desc desc_evento,
         d.collegamento_tipo_code cod_tipo_mov_finanziario,
         d.collegamento_tipo_desc desc_tipo_mov_finanziario,
         b.campo_pk_id ,
         q.causale_ep_id,
         g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
/*         left join siac_r_causale_ep_stato s on s.causale_ep_id=q.causale_ep_id -- SIAC-5696 INIZIO
                                             and s.data_cancellazione is null
                                             and s.validita_fine is null
         left join siac_d_causale_ep_stato t on s.causale_ep_stato_id=t.causale_ep_stato_id
                                             and t.data_cancellazione is null, -- SIAC-5696 FINE   */
         siac_r_causale_ep_stato s, -- SIAC-5941
         siac_d_causale_ep_stato t, -- SIAC-5941
         siac_d_causale_ep_tipo r
    WHERE  a.ente_proprietario_id=p_ente_proprietario_id
    and    i.anno=p_anno_bilancio
    and    a.regmovfin_id = b.regmovfin_id
    and    c.evento_id = b.evento_id
    AND    d.collegamento_tipo_id = c.collegamento_tipo_id
    AND    g.evento_tipo_id = c.evento_tipo_id
    AND    e.regmovfin_id = a.regmovfin_id
    AND    f.regmovfin_stato_id = e.regmovfin_stato_id
    AND    p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data)
    and    p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data)
          --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
          --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
    and   h.bil_id = a.bil_id
    AND   i.periodo_id = h.periodo_id
    AND   l.regmovfin_id = a.regmovfin_id
    AND   l.regep_id = m.pnota_id
    AND   m.pnota_id = n.pnota_id
    AND   o.pnota_stato_id = n.pnota_stato_id
    AND   p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data)
          --p_data >= n.validita_inizio AND  p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
    and   p.ente_proprietario_id=a.ente_proprietario_id
    and   q.causale_ep_id=l.causale_ep_id
    AND   r.causale_ep_tipo_id=q.causale_ep_tipo_id
    and   s.causale_ep_id=q.causale_ep_id  -- SIAC-5941 -- SIAC-5696
    and   s.causale_ep_stato_id=t.causale_ep_stato_id  -- SIAC-5941 -- SIAC-5696
          --s.validita_fine is NULL and -- SIAC-5696
    and   o.pnota_stato_code <> 'A'
    and   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL
    AND   c.data_cancellazione IS NULL
    AND   d.data_cancellazione IS NULL
    AND   e.data_cancellazione IS NULL
    AND   f.data_cancellazione IS NULL
    AND   g.data_cancellazione IS NULL
    AND   h.data_cancellazione IS NULL
    AND   i.data_cancellazione IS NULL
    AND   l.data_cancellazione IS NULL
    AND   m.data_cancellazione IS NULL
    AND   n.data_cancellazione IS NULL
    AND   o.data_cancellazione IS NULL
    AND   p.data_cancellazione IS NULL
    --q.data_cancellazione IS NULL AND -- SIAC-5696
    and   r.data_cancellazione IS NULL
    --s.data_cancellazione IS NULL AND -- SIAC-5696
    --t.data_cancellazione IS NULL -- SIAC-5696
    and (q.data_cancellazione is NULL -- SIAC-5696 INIZIO
               OR
               q.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
         ) -- SIAC-5696 FINE
    and d.collegamento_tipo_code in ('A','I')
    and ((s.data_cancellazione is null and s.validita_fine is null) -- SIAC-5941 Integrazione INIZIO
                or s.causale_ep_stato_id =
               (select d_caus_stato.causale_ep_stato_id
                from   siac_d_causale_ep_stato d_caus_stato
                where  d_caus_stato.causale_ep_stato_id = s.causale_ep_stato_id
                and    d_caus_stato.causale_ep_stato_code = 'V'
                )
               )  -- SIAC-5941 Integrazione FINE
  ),
  movepdet as
  (
	with aa as
    (
	  select a.movep_id, b.pdce_conto_id,
    		 a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
		     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
			 b.pdce_conto_code cod_piano_dei_conti,
		     b.pdce_conto_desc desc_piano_dei_conti,
	         b.livello livello_piano_dei_conti,
		     b.ordine ordine_piano_dei_conti,
	         d.pdce_fam_code cod_pdce_fam,
	         d.pdce_fam_desc desc_pdce_fam,
	         e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c,siac_d_pdce_fam d,siac_d_ambito e
      where a.ente_proprietario_id=p_ente_proprietario_id
        and b.pdce_conto_id=a.pdce_conto_id
        and c.pdce_fam_tree_id=b.pdce_fam_tree_id
        and d.pdce_fam_id=c.pdce_fam_id
        and c.validita_fine is null
        and e.ambito_id=a.ambito_id
        and a.data_cancellazione is null
--        and b.data_cancellazione is null 27.06.2018 Sofia Jira siac-6282
        and c.data_cancellazione is null
        and d.data_cancellazione is null
        and e.data_cancellazione is null
   ),
   bb as
   ( /*SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
	SELECT c.pdce_conto_id,
           case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
				when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
				when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
				when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
				when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
				when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
				when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
				else ''::varchar end as tipo_codifica,
				a.codice_codifica_albero
	FROM siac_v_dwh_codifiche_econpatr a,
	     siac_r_pdce_conto_class b,
	     siac_t_pdce_conto c
    WHERE b.classif_id = a.classif_id
    AND   c.pdce_conto_id = b.pdce_conto_id
    and   c.ente_proprietario_id=p_ente_proprietario_id
--	and   c.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
	and   b.data_cancellazione is NULL
	and   b.validita_fine is null
   )
   select aa.*,
          bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio
   from aa left join bb on aa.pdce_conto_id=bb.pdce_conto_id
  ),
  imp as
  (
  select a.movgest_id,a.movgest_anno anno_movimento,a.movgest_numero numero_movimento
  from siac_t_movgest a
  where a.ente_proprietario_id=p_ente_proprietario_id
  and   a.data_cancellazione is null
  ),
  pdc as
  (select distinct a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
		  b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
   from siac_t_class a,siac_r_causale_ep_class b
   where a.ente_proprietario_id=p_ente_proprietario_id
   and   b.classif_id=a.classif_id
  -- and b.validita_fine is null
   and   a.data_cancellazione is null
  -- and b.data_cancellazione is null
  and (b.data_cancellazione IS NULL -- SIAC-5941 Integrazione
       or
       b.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
      )
  )
  select movep.*,
         movepdet.*,
         pdc.cod_piano_finanziario,pdc.desc_piano_finanziario,
         imp.anno_movimento,imp.numero_movimento,
         null::varchar cod_submovimento,
         null::integer anno_ordinativo,
         null::numeric num_ordinativo,
		 null::varchar num_subordinativo,
	     null::integer anno_liquidazione,
	     null::numeric num_liquidazione,
	     -- SIAC-5573
	     null::integer doc_id,
	     null::integer anno_doc,
	     null::varchar num_doc,
	     null::varchar cod_tipo_doc,
 		 null::timestamp data_emissione_doc,
	     null::varchar cod_sogg_doc,
	     null::integer num_subdoc,
	     null::varchar modifica_impegno,
	     case -- SIAC-5601
		 when movepdet.cod_ambito = 'AMBITO_GSA' then
		      case when movep.cod_tipo_mov_finanziario = 'A' then 'E' else 'U' end
			  else pdc.entrate_uscite
			  end entrate_uscite,
			-- pdc.entrate_uscite,
		p_data data_elaborazione,
		null::integer numero_ricecon
 from movep
      left join movepdet on movep.movep_id=movepdet.movep_id
      left join imp on movep.campo_pk_id=imp.movgest_id
      left join pdc on movep.causale_ep_id=pdc.causale_ep_id
) as tbimp

UNION
--subimp subacc
select tbimp.*
from
(
-- imp
with
movep as
(
  select distinct
		 a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno,
	     m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,
	     m.pnota_progressivogiornale num_definitivo_prima_nota,
		 m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
		 o.pnota_stato_code cod_stato_prima_nota,
		 o.pnota_stato_desc desc_stato_prima_nota,
		 l.movep_id, --da non visualizzare
		 l.movep_code cod_mov_ep,
	     l.movep_desc desc_mov_ep,
	     q.causale_ep_code cod_causale,
	     q.causale_ep_desc desc_causale,
	     r.causale_ep_tipo_code cod_tipo_causale,
	     r.causale_ep_tipo_desc desc_tipo_causale,
	     t.causale_ep_stato_code cod_stato_causale,
	     t.causale_ep_stato_desc desc_stato_causale,
         c.evento_code cod_evento,
         c.evento_desc desc_evento,
         d.collegamento_tipo_code cod_tipo_mov_finanziario,
         d.collegamento_tipo_desc desc_tipo_mov_finanziario,
         b.campo_pk_id ,
         q.causale_ep_id,
         g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
/*         left join siac_r_causale_ep_stato s on s.causale_ep_id=q.causale_ep_id -- SIAC-5696 INIZIO
                                             and s.data_cancellazione is null
                                             and s.validita_fine is null
         left join siac_d_causale_ep_stato t on s.causale_ep_stato_id=t.causale_ep_stato_id
                                             and t.data_cancellazione is null, -- SIAC-5696 FINE  */
         siac_r_causale_ep_stato s, -- SIAC-5941
         siac_d_causale_ep_stato t, -- SIAC-5941
         siac_d_causale_ep_tipo r
    WHERE a.ente_proprietario_id=p_ente_proprietario_id
    and   i.anno=p_anno_bilancio
    and   a.regmovfin_id = b.regmovfin_id
    and   c.evento_id = b.evento_id
    AND   d.collegamento_tipo_id = c.collegamento_tipo_id
    AND   g.evento_tipo_id = c.evento_tipo_id
    AND   e.regmovfin_id = a.regmovfin_id
    AND   f.regmovfin_stato_id = e.regmovfin_stato_id
    AND   p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data)
    and   p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data)
    --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
     --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
    and   h.bil_id = a.bil_id
    AND   i.periodo_id = h.periodo_id
    AND   l.regmovfin_id = a.regmovfin_id
    AND   l.regep_id = m.pnota_id
    AND   m.pnota_id = n.pnota_id
    AND   o.pnota_stato_id = n.pnota_stato_id
    AND   p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data)
     --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
    and   p.ente_proprietario_id=a.ente_proprietario_id
    and   q.causale_ep_id=l.causale_ep_id
    AND   r.causale_ep_tipo_id=q.causale_ep_tipo_id
    and   s.causale_ep_id=q.causale_ep_id
     -- SIAC-5941 -- SIAC-5696
    and   s.causale_ep_stato_id=t.causale_ep_stato_id -- SIAC-5941 -- SIAC-5696
          --s.validita_fine is NULL and -- SIAC-5696
    and   o.pnota_stato_code <> 'A'
    and   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL
    AND   c.data_cancellazione IS NULL AND
          d.data_cancellazione IS NULL AND
          e.data_cancellazione IS NULL AND
          f.data_cancellazione IS NULL AND
          g.data_cancellazione IS NULL AND
          h.data_cancellazione IS NULL AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          m.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL AND
          o.data_cancellazione IS NULL AND
          p.data_cancellazione IS NULL AND
          --q.data_cancellazione IS NULL AND -- SIAC-5696
          r.data_cancellazione IS NULL AND
          --s.data_cancellazione IS NULL AND -- SIAC-5696
          --t.data_cancellazione IS NULL -- SIAC-5696
          (q.data_cancellazione is NULL -- SIAC-5696 INIZIO
               OR
               q.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
               )-- SIAC-5696 FINE
          and d.collegamento_tipo_code in ('SA','SI')
          and ((s.data_cancellazione is null and s.validita_fine is null) -- SIAC-5941 Integrazione INIZIO
                or s.causale_ep_stato_id =
               (select d_caus_stato.causale_ep_stato_id
                from   siac_d_causale_ep_stato d_caus_stato
                where  d_caus_stato.causale_ep_stato_id = s.causale_ep_stato_id
                and    d_caus_stato.causale_ep_stato_code = 'V'
                )
               )  -- SIAC-5941 Integrazione FINE
  ),
  movepdet as
  (
	with aa as
    (
     select a.movep_id, b.pdce_conto_id,
    		a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
		    a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
		    b.pdce_conto_code cod_piano_dei_conti,
		    b.pdce_conto_desc desc_piano_dei_conti,
	        b.livello livello_piano_dei_conti,
	        b.ordine ordine_piano_dei_conti,
			d.pdce_fam_code cod_pdce_fam,
			d.pdce_fam_desc desc_pdce_fam,
			e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c,siac_d_pdce_fam d,siac_d_ambito e
      where a.ente_proprietario_id=p_ente_proprietario_id
	    and b.pdce_conto_id=a.pdce_conto_id
        and c.pdce_fam_tree_id=b.pdce_fam_tree_id
        and d.pdce_fam_id=c.pdce_fam_id
        and c.validita_fine is null
        and e.ambito_id=a.ambito_id
        and a.data_cancellazione is null
    --    and b.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
        and c.data_cancellazione is null
        and d.data_cancellazione is null
        and e.data_cancellazione is null
    ),
    bb as
    ( /*SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
	SELECT c.pdce_conto_id,
           case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
				when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
				when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
				when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
				when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
				when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
				when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
				else ''::varchar end as tipo_codifica,
				a.codice_codifica_albero
	FROM siac_v_dwh_codifiche_econpatr a,
	     siac_r_pdce_conto_class b,
		 siac_t_pdce_conto c
	WHERE b.classif_id = a.classif_id
    AND   c.pdce_conto_id = b.pdce_conto_id
	and   c.ente_proprietario_id=p_ente_proprietario_id
--	and   c.data_cancellazione is null 28.06.2018 Sofia jira siac-6282
	and   b.data_cancellazione is NULL
	and   b.validita_fine is null
  )
  select aa.*,
         bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio
  from aa left join bb on aa.pdce_conto_id=bb.pdce_conto_id
  ),
  subimp as
  (
  select a.movgest_id,a.movgest_anno anno_movimento,a.movgest_numero numero_movimento,
  		 b.movgest_ts_id,b.movgest_ts_code cod_submovimento
  from siac_t_movgest a,siac_T_movgest_ts b
  where a.ente_proprietario_id=p_ente_proprietario_id
  and   a.data_cancellazione is null
  and   b.data_cancellazione is null
  and   b.movgest_id=a.movgest_id
  ),
  pdc as
  (select distinct
          a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
		  b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
   from siac_t_class a,siac_r_causale_ep_class b
   where a.ente_proprietario_id=p_ente_proprietario_id
   and   b.classif_id=a.classif_id
  -- and b.validita_fine is null
   and a.data_cancellazione is null
  -- and b.data_cancellazione is null
   and (b.data_cancellazione IS NULL -- SIAC-5941 Integrazione
       or
       b.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
       )
  )
  select movep.*,
         movepdet.* ,
         pdc.cod_piano_finanziario,pdc.desc_piano_finanziario, subimp.anno_movimento,
		 subimp.numero_movimento,
		 subimp.cod_submovimento,
         null::integer anno_ordinativo,
		 null::numeric num_ordinativo,
		 null::varchar num_subordinativo,
	     null::integer anno_liquidazione,
		 null::numeric num_liquidazione,
	     -- SIAC-5573
		 null::integer doc_id,
		 null::integer anno_doc,
		 null::varchar num_doc,
		 null::varchar cod_tipo_doc,
		 null::timestamp data_emissione_doc,
		 null::varchar cod_sogg_doc,
		 null::integer num_subdoc,
		 null::varchar modifica_impegno,
		 case -- SIAC-5601
          when movepdet.cod_ambito = 'AMBITO_GSA' then
		       case when movep.cod_tipo_mov_finanziario = 'SA' then 'E' else 'U' end
		  else pdc.entrate_uscite
		  end entrate_uscite,
		  -- pdc.entrate_uscite,
		  p_data data_elaborazione,
		  null::integer numero_ricecon
   from movep
        left join movepdet on movep.movep_id=movepdet.movep_id
		left join subimp   on movep.campo_pk_id=subimp.movgest_ts_id
        left join pdc      on movep.causale_ep_id=pdc.causale_ep_id
) as tbimp

-- ordinativi
union
select tbord.*
from
(
-- ord
with movep as
(
  select distinct
		 a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno,
		 m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,
		 m.pnota_progressivogiornale num_definitivo_prima_nota,
		 m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
		 o.pnota_stato_code cod_stato_prima_nota,
		 o.pnota_stato_desc desc_stato_prima_nota,
		 l.movep_id, --da non visualizzare
		 l.movep_code cod_mov_ep,
		 l.movep_desc desc_mov_ep,
		 q.causale_ep_code cod_causale,
		 q.causale_ep_desc desc_causale,
	 	 r.causale_ep_tipo_code cod_tipo_causale,
		 r.causale_ep_tipo_desc desc_tipo_causale,
		 t.causale_ep_stato_code cod_stato_causale,
		 t.causale_ep_stato_desc desc_stato_causale,
         c.evento_code cod_evento,
         c.evento_desc desc_evento,
         d.collegamento_tipo_code cod_tipo_mov_finanziario,
         d.collegamento_tipo_desc desc_tipo_mov_finanziario,
         b.campo_pk_id ,
         q.causale_ep_id,
         g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
/*         left join siac_r_causale_ep_stato s on s.causale_ep_id=q.causale_ep_id -- SIAC-5696 INIZIO
                                             and s.data_cancellazione is null
                                             and s.validita_fine is null
         left join siac_d_causale_ep_stato t on s.causale_ep_stato_id=t.causale_ep_stato_id
                                             and t.data_cancellazione is null, -- SIAC-5696 FINE    */
         siac_r_causale_ep_stato s, -- SIAC-5941
         siac_d_causale_ep_stato t, -- SIAC-5941
         siac_d_causale_ep_tipo r
    WHERE a.ente_proprietario_id=p_ente_proprietario_id
    and   i.anno=p_anno_bilancio
    and   a.regmovfin_id = b.regmovfin_id
    and   c.evento_id = b.evento_id
    AND   d.collegamento_tipo_id = c.collegamento_tipo_id
    AND   g.evento_tipo_id = c.evento_tipo_id
    AND   e.regmovfin_id = a.regmovfin_id
    AND   f.regmovfin_stato_id = e.regmovfin_stato_id
    AND   p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data)
    and   p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data)
    --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
    --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
    and   h.bil_id = a.bil_id
    AND   i.periodo_id = h.periodo_id
    AND   l.regmovfin_id = a.regmovfin_id
    AND   l.regep_id = m.pnota_id
    AND   m.pnota_id = n.pnota_id
    AND   o.pnota_stato_id = n.pnota_stato_id
    AND   p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data)
    --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
    and   p.ente_proprietario_id=a.ente_proprietario_id
    and   q.causale_ep_id=l.causale_ep_id
    AND   r.causale_ep_tipo_id=q.causale_ep_tipo_id
    and   s.causale_ep_id=q.causale_ep_id
    -- SIAC-5941 -- SIAC-5696          s.causale_ep_stato_id=t.causale_ep_stato_id and -- SIAC-5941 -- SIAC-5696
     --s.validita_fine is NULL and -- SIAC-5696
    and   o.pnota_stato_code <> 'A'
    and   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL
    AND   c.data_cancellazione IS NULL
    AND   d.data_cancellazione IS NULL
    AND   e.data_cancellazione IS NULL
    AND   f.data_cancellazione IS NULL
    AND   g.data_cancellazione IS NULL
    AND   h.data_cancellazione IS NULL
    AND   i.data_cancellazione IS NULL
    AND   l.data_cancellazione IS NULL
    AND   m.data_cancellazione IS NULL
    AND   n.data_cancellazione IS NULL
    AND   o.data_cancellazione IS NULL
    AND   p.data_cancellazione IS NULL
    --q.data_cancellazione IS NULL AND -- SIAC-5696
    and r.data_cancellazione IS NULL
    --s.data_cancellazione IS NULL AND -- SIAC-5696
    --t.data_cancellazione IS NULL -- SIAC-5696
   and (q.data_cancellazione is NULL -- SIAC-5696 INIZIO
               OR
               q.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
        )
  -- SIAC-5696 FINE
  and d.collegamento_tipo_code in ('OI', 'OP')
  and ((s.data_cancellazione is null and s.validita_fine is null) -- SIAC-5941 Integrazione INIZIO
                or s.causale_ep_stato_id =
               (select d_caus_stato.causale_ep_stato_id
                from   siac_d_causale_ep_stato d_caus_stato
                where  d_caus_stato.causale_ep_stato_id = s.causale_ep_stato_id
                and    d_caus_stato.causale_ep_stato_code = 'V'
                )
       )  -- SIAC-5941 Integrazione FINE
 ),
 movepdet as
 (
  with aa as
  (
  select a.movep_id, b.pdce_conto_id,
  	     a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
	     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
		 b.pdce_conto_code cod_piano_dei_conti,
		 b.pdce_conto_desc desc_piano_dei_conti,
		 b.livello livello_piano_dei_conti,
		 b.ordine ordine_piano_dei_conti,
		 d.pdce_fam_code cod_pdce_fam,
		 d.pdce_fam_desc desc_pdce_fam,
		 e.ambito_code cod_ambito, e.ambito_desc desc_ambito
  From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c,siac_d_pdce_fam d,siac_d_ambito e
  where a.ente_proprietario_id=p_ente_proprietario_id
    and b.pdce_conto_id=a.pdce_conto_id
    and c.pdce_fam_tree_id=b.pdce_fam_tree_id
    and d.pdce_fam_id=c.pdce_fam_id
    and c.validita_fine is null
    and e.ambito_id=a.ambito_id
    and a.data_cancellazione is null
 --   and b.data_cancellazione is null 27.06.2018 Sofia Jira siac-6282
    and c.data_cancellazione is null
    and d.data_cancellazione is null
    and e.data_cancellazione is null
 ),
 bb as
 (/* SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
  SELECT c.pdce_conto_id,
  	  	 case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
			  when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
			  when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
			  when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
			  when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
			  when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
			  when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
			  else ''::varchar end as tipo_codifica,
			  a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
	   siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id
  AND   c.pdce_conto_id = b.pdce_conto_id
  and   c.ente_proprietario_id=p_ente_proprietario_id
  --and   c.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
  and   b.data_cancellazione is NULL
  and   b.validita_fine is null
 )
 select aa.*,
       bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio
 from aa left join  bb on aa.pdce_conto_id=bb.pdce_conto_id
 ),
 ord as
 (select a.ord_id,a.ord_anno anno_ordinativo,a.ord_numero num_ordinativo
  from siac_t_ordinativo a
  where a.ente_proprietario_id=p_ente_proprietario_id
  and   a.data_cancellazione is null
 ),
 pdc as
 (select distinct
         a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
		 b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
  from siac_t_class a,siac_r_causale_ep_class b
  where a.ente_proprietario_id=p_ente_proprietario_id
  and   b.classif_id=a.classif_id
  -- and b.validita_fine is null
  and a.data_cancellazione is null
  -- and b.data_cancellazione is null
  and (b.data_cancellazione IS NULL -- SIAC-5941 Integrazione
       or
       b.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
      )
  )
/*  ,liq as (select a.liq_id,a.liq_anno anno_liquidazione,a.liq_numero num_liquidazione from siac_t_liquidazione a where a.ente_proprietario_id=3
and a.data_cancellazione is null)  */
   select movep.*,
          movepdet.* ,
          pdc.cod_piano_finanziario,pdc.desc_piano_finanziario,
		  null::integer anno_movimento,null::numeric numero_movimento,
          null::varchar cod_submovimento,
          ord.anno_ordinativo,
		  ord.num_ordinativo,
		  null::varchar num_subordinativo,
		  null::integer anno_liquidazione,
		  null::numeric num_liquidazione,
 		  -- SIAC-5573
		  null::integer doc_id,
		  null::integer anno_doc,
		  null::varchar num_doc,
		  null::varchar cod_tipo_doc,
		  null::timestamp data_emissione_doc,
		  null::varchar cod_sogg_doc,
		  null::integer num_subdoc,
		  null::varchar modifica_impegno,
		  case -- SIAC-5601
			  when movepdet.cod_ambito = 'AMBITO_GSA' then
                   case when movep.cod_tipo_mov_finanziario = 'OI' then 'E' else 'U' end
				   else pdc.entrate_uscite
				   end entrate_uscite,
				   -- pdc.entrate_uscite,
			 p_data data_elaborazione,
		     null::integer numero_ricecon
	   from movep
            left join movepdet on movep.movep_id=movepdet.movep_id
            left join ord on movep.campo_pk_id=ord.ord_id
            left join pdc on movep.causale_ep_id=pdc.causale_ep_id
) as tbord

-- liquidazioni
UNION
-- liq
select tbliq.*
from
(
with movep as
(
  select distinct
		 a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno,
	     m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,
    	 m.pnota_progressivogiornale num_definitivo_prima_nota,
		 m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
		 o.pnota_stato_code cod_stato_prima_nota,
		 o.pnota_stato_desc desc_stato_prima_nota,
		 l.movep_id, --da non visualizzare
		 l.movep_code cod_mov_ep,
		 l.movep_desc desc_mov_ep,
		 q.causale_ep_code cod_causale,
		 q.causale_ep_desc desc_causale,
		 r.causale_ep_tipo_code cod_tipo_causale,
		 r.causale_ep_tipo_desc desc_tipo_causale,
		 t.causale_ep_stato_code cod_stato_causale,
		 t.causale_ep_stato_desc desc_stato_causale,
         c.evento_code cod_evento,
         c.evento_desc desc_evento,
         d.collegamento_tipo_code cod_tipo_mov_finanziario,
         d.collegamento_tipo_desc desc_tipo_mov_finanziario,
         b.campo_pk_id ,
         q.causale_ep_id,
         g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
/*         left join siac_r_causale_ep_stato s on s.causale_ep_id=q.causale_ep_id -- SIAC-5696 INIZIO
                                             and s.data_cancellazione is null
                                             and s.validita_fine is null
         left join siac_d_causale_ep_stato t on s.causale_ep_stato_id=t.causale_ep_stato_id
                                             and t.data_cancellazione is null, -- SIAC-5696 FINE   */
         siac_r_causale_ep_stato s, -- SIAC-5941
         siac_d_causale_ep_stato t, -- SIAC-5941
         siac_d_causale_ep_tipo r
    WHERE a.ente_proprietario_id=p_ente_proprietario_id
    and   i.anno=p_anno_bilancio
    and   a.regmovfin_id = b.regmovfin_id
    and   c.evento_id = b.evento_id
    AND   d.collegamento_tipo_id = c.collegamento_tipo_id
    AND   g.evento_tipo_id = c.evento_tipo_id
    AND   e.regmovfin_id = a.regmovfin_id
    AND   f.regmovfin_stato_id = e.regmovfin_stato_id
    AND   p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data)
    and   p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data)
    --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
    --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
    and   h.bil_id = a.bil_id
    AND   i.periodo_id = h.periodo_id
    AND   l.regmovfin_id = a.regmovfin_id
    AND   l.regep_id = m.pnota_id
    AND   m.pnota_id = n.pnota_id
    AND   o.pnota_stato_id = n.pnota_stato_id
    AND   p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data)
    --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
    and   p.ente_proprietario_id=a.ente_proprietario_id
    and   q.causale_ep_id=l.causale_ep_id
    AND   r.causale_ep_tipo_id=q.causale_ep_tipo_id
    and   s.causale_ep_id=q.causale_ep_id -- SIAC-5941 -- SIAC-5696
    and   s.causale_ep_stato_id=t.causale_ep_stato_id  -- SIAC-5941 -- SIAC-5696
    --s.validita_fine is NULL and -- SIAC-5696
    and   o.pnota_stato_code <> 'A'
    and   a.data_cancellazione IS NULL AND
          b.data_cancellazione IS NULL AND
          c.data_cancellazione IS NULL AND
          d.data_cancellazione IS NULL AND
          e.data_cancellazione IS NULL AND
          f.data_cancellazione IS NULL AND
          g.data_cancellazione IS NULL AND
          h.data_cancellazione IS NULL AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          m.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL AND
          o.data_cancellazione IS NULL AND
          p.data_cancellazione IS NULL AND
          --q.data_cancellazione IS NULL AND -- SIAC-5696
          r.data_cancellazione IS NULL
          --s.data_cancellazione IS NULL AND -- SIAC-5696
          --t.data_cancellazione IS NULL -- SIAC-5696
    and   (q.data_cancellazione is NULL -- SIAC-5696 INIZIO
               OR
               q.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
          )-- SIAC-5696 FINE
    and d.collegamento_tipo_code ='L'
    and ((s.data_cancellazione is null and s.validita_fine is null) -- SIAC-5941 Integrazione INIZIO
                or s.causale_ep_stato_id =
               (select d_caus_stato.causale_ep_stato_id
                from   siac_d_causale_ep_stato d_caus_stato
                where  d_caus_stato.causale_ep_stato_id = s.causale_ep_stato_id
                and    d_caus_stato.causale_ep_stato_code = 'V'
                )
         )  -- SIAC-5941 Integrazione FINE
 ),
 movepdet as
 (
	with aa as
    (
	  select a.movep_id, b.pdce_conto_id,
    		 a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
		     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
			 b.pdce_conto_code cod_piano_dei_conti,
		     b.pdce_conto_desc desc_piano_dei_conti,
		     b.livello livello_piano_dei_conti,
			 b.ordine ordine_piano_dei_conti,
			 d.pdce_fam_code cod_pdce_fam,
			 d.pdce_fam_desc desc_pdce_fam,
			 e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c,siac_d_pdce_fam d,siac_d_ambito e
      where a.ente_proprietario_id=p_ente_proprietario_id
      and   b.pdce_conto_id=a.pdce_conto_id
      and   c.pdce_fam_tree_id=b.pdce_fam_tree_id
      and   d.pdce_fam_id=c.pdce_fam_id
      and   c.validita_fine is null
      and   e.ambito_id=a.ambito_id
      and   a.data_cancellazione is null
--      and   b.data_cancellazione is null 28.06.2018 Sofia jira siac-6282
	  and   c.data_cancellazione is null
	  and   d.data_cancellazione is null
	  and   e.data_cancellazione is null
     ),
     bb as
     ( /*SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
	SELECT c.pdce_conto_id,
           case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
				when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
				when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
				when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
				when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
				when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
				when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
				else ''::varchar end as tipo_codifica,
				a.codice_codifica_albero
	FROM siac_v_dwh_codifiche_econpatr a,
		 siac_r_pdce_conto_class b,
		 siac_t_pdce_conto c
	WHERE b.classif_id = a.classif_id
    AND   c.pdce_conto_id = b.pdce_conto_id
	and   c.ente_proprietario_id=p_ente_proprietario_id
--	and   c.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
    and   b.data_cancellazione is NULL
    and   b.validita_fine is null
  )
  select aa.*,
         bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio
  from aa
       left join  bb on aa.pdce_conto_id=bb.pdce_conto_id
 ),
 liq as
 (
   select a.liq_id,a.liq_anno anno_liquidazione,a.liq_numero num_liquidazione
   from siac_t_liquidazione a
   where a.ente_proprietario_id=p_ente_proprietario_id
   and   a.data_cancellazione is null
 ),
 pdc as
 (select distinct
         a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
         b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
  from siac_t_class a,siac_r_causale_ep_class b
  where a.ente_proprietario_id=p_ente_proprietario_id
  and   b.classif_id=a.classif_id
  -- and b.validita_fine is null
  and a.data_cancellazione is null
  -- and b.data_cancellazione is null
  and (b.data_cancellazione IS NULL -- SIAC-5941 Integrazione
       or
       b.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
      )
 )
 select movep.*,
        movepdet.* ,
        pdc.cod_piano_finanziario,pdc.desc_piano_finanziario,
        null::integer anno_movimento,
        null::numeric numero_movimento,
        null::varchar cod_submovimento,
        null::integer anno_ordinativo,
        null::numeric num_ordinativo,
        null::varchar num_subordinativo,
        liq.anno_liquidazione,
        liq.num_liquidazione,
        -- SIAC-5573
        null::integer doc_id,
        null::integer anno_doc,
        null::varchar num_doc,
        null::varchar cod_tipo_doc,
        null::timestamp data_emissione_doc,
        null::varchar cod_sogg_doc,
        null::integer num_subdoc,
        null::varchar modifica_impegno,
        case -- SIAC-5601
            when movepdet.cod_ambito = 'AMBITO_GSA' then
                 case when movep.cod_tipo_mov_finanziario = 'L' then 'U'  else  'E' end
        else pdc.entrate_uscite
        end entrate_uscite,
        -- pdc.entrate_uscite,
	    p_data data_elaborazione,
		null::integer numero_ricecon
  from movep
       left join  movepdet on movep.movep_id=movepdet.movep_id
       left join liq  on movep.campo_pk_id=liq.liq_id
       left join pdc  on movep.causale_ep_id=pdc.causale_ep_id
) as tbliq


union
--richiesta econ
select tbricecon.*
from
(
 with
 movep as
 (
  select distinct
		 a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno,
	     m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,
    	 m.pnota_progressivogiornale num_definitivo_prima_nota,
		 m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
		 o.pnota_stato_code cod_stato_prima_nota,
		 o.pnota_stato_desc desc_stato_prima_nota,
		 l.movep_id, --da non visualizzare
		 l.movep_code cod_mov_ep,
		 l.movep_desc desc_mov_ep,
		 q.causale_ep_code cod_causale,
		 q.causale_ep_desc desc_causale,
		 r.causale_ep_tipo_code cod_tipo_causale,
		 r.causale_ep_tipo_desc desc_tipo_causale,
		 t.causale_ep_stato_code cod_stato_causale,
		 t.causale_ep_stato_desc desc_stato_causale,
		 c.evento_code cod_evento,
         c.evento_desc desc_evento,
         d.collegamento_tipo_code cod_tipo_mov_finanziario,
         d.collegamento_tipo_desc desc_tipo_mov_finanziario,
         b.campo_pk_id ,
         q.causale_ep_id,
         g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
/*         left join siac_r_causale_ep_stato s on s.causale_ep_id=q.causale_ep_id -- SIAC-5696 INIZIO
                                             and s.data_cancellazione is null
                                             and s.validita_fine is null
         left join siac_d_causale_ep_stato t on s.causale_ep_stato_id=t.causale_ep_stato_id
                                             and t.data_cancellazione is null, -- SIAC-5696 FINE    */
         siac_r_causale_ep_stato s, -- SIAC-5941
         siac_d_causale_ep_stato t, -- SIAC-5941
         siac_d_causale_ep_tipo r
    WHERE a.ente_proprietario_id=p_ente_proprietario_id
    and   i.anno=p_anno_bilancio
    and   a.regmovfin_id = b.regmovfin_id
    and   c.evento_id = b.evento_id
    AND   d.collegamento_tipo_id = c.collegamento_tipo_id
    AND   g.evento_tipo_id = c.evento_tipo_id
    AND   e.regmovfin_id = a.regmovfin_id
    AND   f.regmovfin_stato_id = e.regmovfin_stato_id
    AND   p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data)
    and   p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data)
   --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
  --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
    and   h.bil_id = a.bil_id
    AND   i.periodo_id = h.periodo_id
    AND   l.regmovfin_id = a.regmovfin_id
    AND   l.regep_id = m.pnota_id
    AND   m.pnota_id = n.pnota_id
    AND   o.pnota_stato_id = n.pnota_stato_id
    AND   p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data)
   --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
    and   p.ente_proprietario_id=a.ente_proprietario_id
    and   q.causale_ep_id=l.causale_ep_id
    AND   r.causale_ep_tipo_id=q.causale_ep_tipo_id
    and   s.causale_ep_id=q.causale_ep_id
    -- SIAC-5941 -- SIAC-5696
    and  s.causale_ep_stato_id=t.causale_ep_stato_id  -- SIAC-5941 -- SIAC-5696
    --s.validita_fine is NULL and -- SIAC-5696
    and  o.pnota_stato_code <> 'A'
    and  a.data_cancellazione IS NULL AND
         b.data_cancellazione IS NULL AND
         c.data_cancellazione IS NULL AND
         d.data_cancellazione IS NULL AND
         e.data_cancellazione IS NULL AND
         f.data_cancellazione IS NULL AND
         g.data_cancellazione IS NULL AND
         h.data_cancellazione IS NULL AND
         i.data_cancellazione IS NULL AND
         l.data_cancellazione IS NULL AND
         m.data_cancellazione IS NULL AND
         n.data_cancellazione IS NULL AND
         o.data_cancellazione IS NULL AND
         p.data_cancellazione IS NULL AND
         --q.data_cancellazione IS NULL AND -- SIAC-5696
         r.data_cancellazione IS NULL
          --s.data_cancellazione IS NULL AND -- SIAC-5696
          --t.data_cancellazione IS NULL -- SIAC-5696
     and  (q.data_cancellazione is NULL -- SIAC-5696 INIZIO
               OR
               q.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
          )-- SIAC-5696 FINE
     and d.collegamento_tipo_code ='RE'
     and ((s.data_cancellazione is null and s.validita_fine is null) -- SIAC-5941 Integrazione INIZIO
                or s.causale_ep_stato_id =
               (select d_caus_stato.causale_ep_stato_id
                from   siac_d_causale_ep_stato d_caus_stato
                where  d_caus_stato.causale_ep_stato_id = s.causale_ep_stato_id
                and    d_caus_stato.causale_ep_stato_code = 'V'
                )
          )   -- SIAC-5941 Integrazione FINE
  ),
  movepdet as
  (
	with
    aa as
    (
      select a.movep_id, b.pdce_conto_id,
     		 a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
		     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
		     b.pdce_conto_code cod_piano_dei_conti,
			 b.pdce_conto_desc desc_piano_dei_conti,
			 b.livello livello_piano_dei_conti,
			 b.ordine ordine_piano_dei_conti,
			 d.pdce_fam_code cod_pdce_fam,
			 d.pdce_fam_desc desc_pdce_fam,
			 e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c,siac_d_pdce_fam d,siac_d_ambito e
      where a.ente_proprietario_id=p_ente_proprietario_id
      and   b.pdce_conto_id=a.pdce_conto_id
      and   c.pdce_fam_tree_id=b.pdce_fam_tree_id
      and   d.pdce_fam_id=c.pdce_fam_id
      and   c.validita_fine is null
      and   e.ambito_id=a.ambito_id
      and a.data_cancellazione is null
   --   and b.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
      and c.data_cancellazione is null
      and d.data_cancellazione is null
      and e.data_cancellazione is null
    ),
    bb as
    ( /*SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
    SELECT c.pdce_conto_id,
           case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
		  	    when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
		        when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
				when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
				when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
				when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
				when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
				else ''::varchar end as tipo_codifica,
		  a.codice_codifica_albero
	FROM siac_v_dwh_codifiche_econpatr a,
		 siac_r_pdce_conto_class b,
		 siac_t_pdce_conto c
	WHERE b.classif_id = a.classif_id
    AND   c.pdce_conto_id = b.pdce_conto_id
	and   c.ente_proprietario_id=p_ente_proprietario_id
--	and   c.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
    and   b.data_cancellazione is NULL
    and   b.validita_fine is null
  )
  select aa.*,
         bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio
   from aa left join bb on aa.pdce_conto_id=bb.pdce_conto_id
  ),
  ricecon as
  (select a.ricecon_id,
          a.ricecon_numero numero_ricecon
   from siac_t_richiesta_econ a
   where a.ente_proprietario_id=p_ente_proprietario_id
    and  a.data_cancellazione is null
  ),
  pdc as
  (
   select distinct
          a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
		  b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
   from siac_t_class a,siac_r_causale_ep_class b
   where a.ente_proprietario_id=p_ente_proprietario_id
   and   b.classif_id=a.classif_id
  -- and b.validita_fine is null
   and   a.data_cancellazione is null
  -- and b.data_cancellazione is null
   and (b.data_cancellazione IS NULL -- SIAC-5941 Integrazione
       or
       b.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
      )
  )
  select movep.*,
         movepdet.* ,
         pdc.cod_piano_finanziario,pdc.desc_piano_finanziario,
         null::integer anno_movimento,
         null::numeric numero_movimento,
         null::varchar cod_submovimento,
         null::integer anno_ordinativo,
		 null::numeric num_ordinativo,
		 null::varchar num_subordinativo,
		 null::integer anno_liquidazione,
		 null::numeric num_liquidazione,
		 -- SIAC-5573
		 null::integer doc_id,
		 null::integer anno_doc,
		 null::varchar num_doc,
		 null::varchar cod_tipo_doc,
		 null::timestamp data_emissione_doc,
		 null::varchar cod_sogg_doc,
		 null::integer num_subdoc,
		 null::varchar modifica_impegno,
		 case -- SIAC-5601
		  when movepdet.cod_ambito = 'AMBITO_GSA' then
	       case when movep.cod_tipo_mov_finanziario = 'RE' then 'U' else 'E' end
		  else pdc.entrate_uscite
		  end entrate_uscite,
		  -- pdc.entrate_uscite,
		 p_data data_elaborazione,
	     ricecon.numero_ricecon
   from movep
        left join movepdet on movep.movep_id=movepdet.movep_id
        left join ricecon  on movep.campo_pk_id=ricecon.ricecon_id
        left join pdc      on movep.causale_ep_id=pdc.causale_ep_id
) as tbricecon

union
-- mod
select tbmod.*
from
(
 with
 movep as
 (
  select distinct
		 a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno,
	     m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,
    	 m.pnota_progressivogiornale num_definitivo_prima_nota,
		 m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
		 o.pnota_stato_code cod_stato_prima_nota,
		 o.pnota_stato_desc desc_stato_prima_nota,
		 l.movep_id, --da non visualizzare
		 l.movep_code cod_mov_ep,
		 l.movep_desc desc_mov_ep,
		 q.causale_ep_code cod_causale,
		 q.causale_ep_desc desc_causale,
	  	 r.causale_ep_tipo_code cod_tipo_causale,
		 r.causale_ep_tipo_desc desc_tipo_causale,
	     t.causale_ep_stato_code cod_stato_causale,
	     t.causale_ep_stato_desc desc_stato_causale,
	     c.evento_code cod_evento,
         c.evento_desc desc_evento,
         d.collegamento_tipo_code cod_tipo_mov_finanziario,
         d.collegamento_tipo_desc desc_tipo_mov_finanziario,
         b.campo_pk_id ,
         q.causale_ep_id,
         g.evento_tipo_code as tipo_evento -- SIAC-5641
   FROM siac_t_reg_movfin a,
        siac_r_evento_reg_movfin b,
        siac_d_evento c,
        siac_d_collegamento_tipo d,
        siac_r_reg_movfin_stato e,
        siac_d_reg_movfin_stato f,
        siac_d_evento_tipo g,
        siac_t_bil h,
        siac_t_periodo i,
        siac_t_mov_ep l,
        siac_t_prima_nota m,
        siac_r_prima_nota_stato n,
        siac_d_prima_nota_stato o,
        siac_t_ente_proprietario p,
        siac_t_causale_ep q,
/*        left join siac_r_causale_ep_stato s on s.causale_ep_id=q.causale_ep_id -- SIAC-5696 INIZIO
                                             and s.data_cancellazione is null
                                             and s.validita_fine is null
         left join siac_d_causale_ep_stato t on s.causale_ep_stato_id=t.causale_ep_stato_id
                                             and t.data_cancellazione is null, -- SIAC-5696 FINE  */
        siac_r_causale_ep_stato s, -- SIAC-5941
        siac_d_causale_ep_stato t, -- SIAC-5941
        siac_d_causale_ep_tipo r
   WHERE a.ente_proprietario_id=p_ente_proprietario_id
   and   i.anno=p_anno_bilancio
   and   a.regmovfin_id = b.regmovfin_id
   and   c.evento_id = b.evento_id
   AND   d.collegamento_tipo_id = c.collegamento_tipo_id
   AND   g.evento_tipo_id = c.evento_tipo_id
   AND   e.regmovfin_id = a.regmovfin_id
   AND   f.regmovfin_stato_id = e.regmovfin_stato_id
   AND   p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data)
   and   p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data)
 --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
 --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
   and   h.bil_id = a.bil_id
   AND   i.periodo_id = h.periodo_id
   AND   l.regmovfin_id = a.regmovfin_id
   AND   l.regep_id = m.pnota_id
   AND   m.pnota_id = n.pnota_id
   AND   o.pnota_stato_id = n.pnota_stato_id
   AND   p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data)
 --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
   and   p.ente_proprietario_id=a.ente_proprietario_id
   and   q.causale_ep_id=l.causale_ep_id
   AND   r.causale_ep_tipo_id=q.causale_ep_tipo_id
   and   s.causale_ep_id=q.causale_ep_id -- SIAC-5941 -- SIAC-5696
   and   s.causale_ep_stato_id=t.causale_ep_stato_id  -- SIAC-5941 -- SIAC-5696
 --s.validita_fine is NULL and -- SIAC-5696
   and   o.pnota_stato_code <> 'A'
   and   a.data_cancellazione IS NULL AND
         b.data_cancellazione IS NULL AND
         c.data_cancellazione IS NULL AND
         d.data_cancellazione IS NULL AND
         e.data_cancellazione IS NULL AND
         f.data_cancellazione IS NULL AND
         g.data_cancellazione IS NULL AND
         h.data_cancellazione IS NULL AND
         i.data_cancellazione IS NULL AND
         l.data_cancellazione IS NULL AND
         m.data_cancellazione IS NULL AND
         n.data_cancellazione IS NULL AND
         o.data_cancellazione IS NULL AND
         p.data_cancellazione IS NULL AND
        --q.data_cancellazione IS NULL AND -- SIAC-5696
         r.data_cancellazione IS NULL
          --s.data_cancellazione IS NULL AND -- SIAC-5696
          --t.data_cancellazione IS NULL -- SIAC-5696
  and (q.data_cancellazione is NULL -- SIAC-5696 INIZIO
               OR
               q.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
       )-- SIAC-5696 FINE
  and d.collegamento_tipo_code in ('MMGE','MMGS')
  and ((s.data_cancellazione is null and s.validita_fine is null) -- SIAC-5941 Integrazione INIZIO
                or s.causale_ep_stato_id =
               (select d_caus_stato.causale_ep_stato_id
                from   siac_d_causale_ep_stato d_caus_stato
                where  d_caus_stato.causale_ep_stato_id = s.causale_ep_stato_id
                and    d_caus_stato.causale_ep_stato_code = 'V'
                )
       )  -- SIAC-5941 Integrazione FINE
),
movepdet as
(
 with
 aa as
 (
  select a.movep_id, b.pdce_conto_id,
  	     a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
	     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
	     b.pdce_conto_code cod_piano_dei_conti,
	     b.pdce_conto_desc desc_piano_dei_conti,
	     b.livello livello_piano_dei_conti,
	     b.ordine ordine_piano_dei_conti,
	     d.pdce_fam_code cod_pdce_fam,
	     d.pdce_fam_desc desc_pdce_fam,
		 e.ambito_code cod_ambito, e.ambito_desc desc_ambito
  From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c,siac_d_pdce_fam d,siac_d_ambito e
  where a.ente_proprietario_id=p_ente_proprietario_id
    and b.pdce_conto_id=a.pdce_conto_id
    and c.pdce_fam_tree_id=b.pdce_fam_tree_id
    and d.pdce_fam_id=c.pdce_fam_id
    and c.validita_fine is null
    and e.ambito_id=a.ambito_id
    and a.data_cancellazione is null
 --   and b.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
    and c.data_cancellazione is null
    and d.data_cancellazione is null
    and e.data_cancellazione is null
 ),
 bb as
 (
/*
SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
 SELECT c.pdce_conto_id,
        case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
			 when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
			 when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
		     when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
			 when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
	         when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
			 when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
			 else ''::varchar end as tipo_codifica,
		     a.codice_codifica_albero
 FROM siac_v_dwh_codifiche_econpatr a,
      siac_r_pdce_conto_class b,
	  siac_t_pdce_conto c
 WHERE b.classif_id = a.classif_id
 AND   c.pdce_conto_id = b.pdce_conto_id
 and   c.ente_proprietario_id=p_ente_proprietario_id
-- and   c.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
 and   b.data_cancellazione is NULL
 and   b.validita_fine is null
)
select aa.*,
       bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio
from aa left join  bb on aa.pdce_conto_id=bb.pdce_conto_id
) ,
mod as
(
 select d.mod_id,
 	    c.movgest_anno v_movgest_anno, c.movgest_numero v_movgest_numero,
		b.movgest_ts_code cod_submovimento,
        tsTipo.movgest_ts_tipo_code
 FROM   siac_t_movgest_ts_det_mod a,siac_T_movgest_ts b,
        siac_t_movgest c,siac_t_modifica d, siac_r_modifica_stato e, siac_d_modifica_stato f,siac_d_movgest_ts_tipo tsTipo
 WHERE a.ente_proprietario_id = p_ente_proprietario_id
   and a.mod_stato_r_id=e.mod_stato_r_id
   and e.mod_id=d.mod_id
   and f.mod_stato_id=e.mod_stato_id
   and a.movgest_ts_id=b.movgest_ts_id
   and b.movgest_id=c.movgest_id
   AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
   AND    p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
   AND    a.data_cancellazione IS NULL
   AND    b.data_cancellazione IS NULL
   AND    c.data_cancellazione IS NULL
   AND    d.data_cancellazione IS NULL
   AND    e.data_cancellazione IS NULL
   AND    f.data_cancellazione IS NULL
   AND tsTipo.movgest_ts_tipo_id = b.movgest_ts_tipo_id
 UNION
  select d.mod_id,
  		 c.movgest_anno v_movgest_anno, c.movgest_numero v_movgest_numero,
		 b.movgest_ts_code cod_submovimento,
         tsTipo.movgest_ts_tipo_code
  FROM   siac_r_movgest_ts_sog_mod a,siac_T_movgest_ts b, siac_t_movgest c,
         siac_t_modifica d, siac_r_modifica_stato e, siac_d_modifica_stato f,siac_d_movgest_ts_tipo tsTipo
  WHERE  a.ente_proprietario_id = p_ente_proprietario_id
	and  a.mod_stato_r_id=e.mod_stato_r_id
	and  e.mod_id=d.mod_id
	and  f.mod_stato_id=e.mod_stato_id
	and  a.movgest_ts_id=b.movgest_ts_id
	and  b.movgest_id=c.movgest_id
	AND  p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
    AND  p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
    AND  a.data_cancellazione IS NULL
    AND  b.data_cancellazione IS NULL
    AND  c.data_cancellazione IS NULL
    AND  d.data_cancellazione IS NULL
    AND  e.data_cancellazione IS NULL
    AND  f.data_cancellazione IS NULL
    AND  tsTipo.movgest_ts_tipo_id = b.movgest_ts_tipo_id
),
pdc as
(
 select distinct a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
	    b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
 from siac_t_class a,siac_r_causale_ep_class b
 where a.ente_proprietario_id=p_ente_proprietario_id
  and  b.classif_id=a.classif_id
  -- and b.validita_fine is null
  and  a.data_cancellazione is null
  -- and b.data_cancellazione is null
  and (b.data_cancellazione IS NULL -- SIAC-5941 Integrazione
       or
       b.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
      )
)
select movep.*,
       movepdet.*,--, case when mod.mod_id is not null then 'S' else 'N' end modifica_impegno
       pdc.cod_piano_finanziario,pdc.desc_piano_finanziario,
       mod.v_movgest_anno anno_movimento,mod.v_movgest_numero numero_movimento,
   -- SIAC-5685
   -- mod.cod_submovimento
      case when mod.movgest_ts_tipo_code='T' then null::varchar else mod.cod_submovimento end cod_submovimento,
      null::integer anno_ordinativo,
      null::numeric num_ordinativo,
	  null::varchar num_subordinativo,
	  null::integer anno_liquidazione,
	  null::numeric num_liquidazione,
	  -- SIAC-5573
	  null::integer doc_id,
	  null::integer anno_doc,
	  null::varchar num_doc,
	  null::varchar cod_tipo_doc,
	  null::timestamp data_emissione_doc,
	  null::varchar cod_sogg_doc,
	  null::integer num_subdoc,
	  case when mod.mod_id is not null then 'S' else 'N' end modifica_impegno,
	  case -- SIAC-5601
	   when movepdet.cod_ambito = 'AMBITO_GSA' then
        case
         when movep.cod_tipo_mov_finanziario = 'MMGE' then 'E' else 'U' end
      else  pdc.entrate_uscite
	  end entrate_uscite,
	  -- pdc.entrate_uscite,
	  p_data data_elaborazione,
	  null::integer numero_ricecon
   from movep
        left join  movepdet on movep.movep_id=movepdet.movep_id
	    left join mod on  movep.campo_pk_id=  mod.mod_id
        left join pdc on movep.causale_ep_id=pdc.causale_ep_id
) as tbmod

--lib
union
select lib.*
from
(
with
movep as
(
select distinct
m.ente_proprietario_id,
p.ente_denominazione,
i.anno AS bil_anno,
m.pnota_desc desc_prima_nota,
m.pnota_numero num_provvisorio_prima_nota,
m.pnota_progressivogiornale num_definitivo_prima_nota,
m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
o.pnota_stato_code cod_stato_prima_nota,
o.pnota_stato_desc desc_stato_prima_nota,
l.movep_id,
l.movep_code cod_mov_ep,
l.movep_desc desc_mov_ep,
q.causale_ep_code cod_causale,
q.causale_ep_desc desc_causale,
r.causale_ep_tipo_code cod_tipo_causale,
r.causale_ep_tipo_desc desc_tipo_causale,
t.causale_ep_stato_code cod_stato_causale,
t.causale_ep_stato_desc desc_stato_causale,
NULL::varchar cod_evento,
NULL::varchar desc_evento,
NULL::varchar cod_tipo_mov_finanziario,
NULL::varchar desc_tipo_mov_finanziario,
NULL::integer campo_pk_id ,
q.causale_ep_id,
NULL::varchar evento_tipo_code
FROM
siac_t_prima_nota m,siac_d_causale_ep_tipo r,
siac_t_bil h,
siac_t_periodo i,
siac_t_mov_ep l,
siac_r_prima_nota_stato n,
siac_d_prima_nota_stato o,
siac_t_ente_proprietario p,
siac_t_causale_ep q,
siac_r_causale_ep_stato s,
siac_d_causale_ep_stato t
WHERE m.ente_proprietario_id=p_ente_proprietario_id
and r.causale_ep_tipo_code='LIB'
and i.anno=p_anno_bilancio
and h.bil_id = m.bil_id
AND i.periodo_id = h.periodo_id
AND l.regep_id = m.pnota_id
AND m.pnota_id = n.pnota_id
AND o.pnota_stato_id = n.pnota_stato_id
--p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
and p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data)
and p.ente_proprietario_id=m.ente_proprietario_id
and q.causale_ep_id=l.causale_ep_id
AND r.causale_ep_tipo_id=q.causale_ep_tipo_id
and s.causale_ep_id=q.causale_ep_id
AND s.causale_ep_stato_id=t.causale_ep_stato_id
and s.validita_fine is NULL
and o.pnota_stato_code <> 'A'
and
h.data_cancellazione IS NULL AND
i.data_cancellazione IS NULL AND
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
q.data_cancellazione IS NULL AND
r.data_cancellazione IS NULL AND
s.data_cancellazione IS NULL AND
t.data_cancellazione IS NULL
),
movepdet as
(
with aa as
(
select a.movep_id, b.pdce_conto_id,
a.movep_det_code cod_mov_ep_dettaglio,
a.movep_det_desc desc_mov_ep_dettaglio,
a.movep_det_importo importo_mov_ep,
a.movep_det_segno segno_mov_ep,
b.pdce_conto_code cod_piano_dei_conti,
b.pdce_conto_desc desc_piano_dei_conti,
b.livello livello_piano_dei_conti,
b.ordine ordine_piano_dei_conti,
d.pdce_fam_code cod_pdce_fam,
d.pdce_fam_desc desc_pdce_fam,
e.ambito_code cod_ambito,
e.ambito_desc desc_ambito
From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c ,siac_d_pdce_fam d,siac_d_ambito e
where a.ente_proprietario_id= p_ente_proprietario_id
and b.pdce_conto_id=a.pdce_conto_id
and c.pdce_fam_tree_id=b.pdce_fam_tree_id
and d.pdce_fam_id=c.pdce_fam_id
and c.validita_fine is null
and e.ambito_id=a.ambito_id
and a.data_cancellazione is null
--and b.data_cancellazione is null 28.06.2018 Sofia jira siac-6282
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
),
bb as
(
SELECT c.pdce_conto_id,
	   case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
			when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
			when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
			when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
			when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
			when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
			when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
			else ''::varchar end as tipo_codifica,
	a.codice_codifica_albero
FROM siac_v_dwh_codifiche_econpatr a,siac_r_pdce_conto_class b,siac_t_pdce_conto c
WHERE b.classif_id = a.classif_id
AND c.pdce_conto_id = b.pdce_conto_id
and c.ente_proprietario_id=p_ente_proprietario_id
--and c.data_cancellazione is null 28.06.2018 Sofia jira siac-6282
and b.data_cancellazione is NULL
and b.validita_fine is null
)
select aa.*,
	   bb.tipo_codifica||'.'||  bb.codice_codifica_albero cod_bilancio
from aa left join bb on aa.pdce_conto_id=bb.pdce_conto_id
)
select movep.*,
       movepdet.*,
	   null::varchar cod_piano_finanziario,
	   null::varchar desc_piano_finanziario,
	   null::integer anno_movimento,
	   null::numeric numero_movimento,
	   null::varchar cod_submovimento,
	   null::integer anno_ordinativo,
	   null::numeric num_ordinativo,
	   null::varchar num_subordinativo,
	   null::integer anno_liquidazione,
	   null::numeric num_liquidazione,
	   -- SIAC-5573
	   null::integer doc_id,
	   null::integer anno_doc,
	   null::varchar num_doc,
	   null::varchar cod_tipo_doc,
	   null::timestamp data_emissione_doc,
	   null::varchar cod_sogg_doc,
	   null::integer num_subdoc,
	   null::varchar modifica_impegno,
	   null::varchar entrate_uscite,
	   p_data data_elaborazione,
	   null::integer numero_ricecon
from movep left join movepdet on movep.movep_id=movepdet.movep_id
) as lib

) as tb;

esito:= 'Fine funzione carico contabilita_generale (FNC_SIAC_DWH_CONTABILITA_GENERALE) - '||clock_timestamp();
RETURN NEXT;

update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;


EXCEPTION
WHEN others THEN
  esito:='Funzione carico contabilita_generale (FNC_SIAC_DWH_CONTABILITA_GENERALE) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;