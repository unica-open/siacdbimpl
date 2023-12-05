/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR158_strutura_dca_stato_patrimonio" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  nome_ente varchar,
  fam_code varchar,
  fam_desc varchar,
  segno_importo varchar,
  pdce_conto_code varchar,
  pdce_conto_desc varchar,
  importo numeric,
  livello integer
) AS
$body$
DECLARE

elenco_prime_note record;
v_pdce_conto_code varchar;
v_pdce_conto_desc varchar;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO 		 varchar(1000):=DEF_NULL;

BEGIN

nome_ente := '';
fam_code := '';
fam_desc := '';
segno_importo := '';
pdce_conto_code := '';
pdce_conto_desc := ''; 
importo := 0; 
livello := 0;

SELECT a.ente_denominazione
INTO  nome_ente
FROM  siac_t_ente_proprietario a
WHERE a.ente_proprietario_id = p_ente_prop_id;

FOR elenco_prime_note IN 
SELECT d.pdce_fam_code, d.pdce_fam_desc,
e.movep_det_segno, 
SUM(COALESCE(e.movep_det_importo,0)) AS importo,
b.pdce_conto_code, b.pdce_conto_desc, b.livello,
b.pdce_conto_id_padre
FROM  siac_t_pdce_conto b
INNER JOIN siac_t_pdce_fam_tree c ON b.pdce_fam_tree_id = c.pdce_fam_tree_id
INNER JOIN siac_d_pdce_fam d ON c.pdce_fam_id = d.pdce_fam_id    
INNER JOIN siac_t_mov_ep_det e ON e.pdce_conto_id = b.pdce_conto_id
INNER JOIN siac_t_mov_ep f ON e.movep_id = f.movep_id
INNER JOIN siac_t_prima_nota g ON f.regep_id = g.pnota_id
INNER JOIN siac_t_bil h ON g.bil_id = h.bil_id
INNER JOIN siac_t_periodo i ON h.periodo_id = i.periodo_id
INNER JOIN siac_r_prima_nota_stato l ON g.pnota_id = l.pnota_id
INNER JOIN siac_d_prima_nota_stato m ON l.pnota_stato_id = m.pnota_stato_id  
--29/12/2020 SIAC-7894: occorre filtrare per ambito = FIN.
INNER JOIN siac_d_ambito ambito ON ambito.ambito_id= b.ambito_id   
WHERE b.ente_proprietario_id = p_ente_prop_id
AND   m.pnota_stato_code = 'D'
AND   i.anno = p_anno
AND   d.pdce_fam_code in ('PP','AP','OP','OA')
--29/12/2020 SIAC-7894: occorre filtrare per ambito = FIN.
AND   ambito.ambito_code ='AMBITO_FIN'
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
GROUP BY d.pdce_fam_code, d.pdce_fam_desc, e.movep_det_segno, 
b.pdce_conto_code, b.pdce_conto_desc, b.livello,
b.pdce_conto_id_padre
ORDER BY d.pdce_fam_code, b.pdce_conto_code
  
LOOP

  IF elenco_prime_note.livello = 8 THEN
    
    v_pdce_conto_code := null;
    v_pdce_conto_desc := null;
  
    SELECT b.pdce_conto_code, b.pdce_conto_desc
    INTO  v_pdce_conto_code, v_pdce_conto_desc
    FROM  siac_t_pdce_conto b
    WHERE b.pdce_conto_id = elenco_prime_note.pdce_conto_id_padre
    AND   b.data_cancellazione IS NULL;
  
    pdce_conto_code := v_pdce_conto_code;
    pdce_conto_desc := v_pdce_conto_desc;
  
  ELSE
  
    pdce_conto_code := elenco_prime_note.pdce_conto_code;
    pdce_conto_desc := elenco_prime_note.pdce_conto_desc;
    
  END IF;

  fam_code := elenco_prime_note.pdce_fam_code;
  fam_desc := elenco_prime_note.pdce_fam_desc;
  segno_importo := elenco_prime_note.movep_det_segno;
  importo := elenco_prime_note.importo;
  livello := elenco_prime_note.livello;


/* 22/06/2021 SIAC-8246.
   Non restituisco gli importi a 0 in quanto per il formato Xbrl se un conto ha
   entrambi gli importi a 0 non deve essere presente nel file.
   Il report se il conto e' presente con un importo a 0 e l'altro non 0
   visualizza comunque il dato correttamente.
   Questa modifica vale anche per il formato excel.
	return next;
*/

  --return next;
  if importo <> 0 then
  	return next;
  end if;

  fam_code := '';
  fam_desc := '';
  segno_importo := '';
  pdce_conto_code := '';
  pdce_conto_desc := ''; 
  importo := 0; 
  livello := 0;

END LOOP;

EXCEPTION
	when no_data_found THEN
		 raise notice 'Dati non trovati' ;
	when others  THEN
         RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'DCA Patrimonio',substring(SQLERRM from 1 for 500);
         return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;