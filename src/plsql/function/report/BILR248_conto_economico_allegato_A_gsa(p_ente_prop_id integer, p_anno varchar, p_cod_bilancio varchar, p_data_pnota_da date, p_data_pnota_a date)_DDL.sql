/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR248_conto_economico_allegato_A_gsa" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_cod_bilancio varchar,
  p_data_pnota_da date,
  p_data_pnota_a date
)
RETURNS TABLE (
  classif_id integer,
  codice_voce varchar,
  descrizione_voce varchar,
  livello_codifica integer,
  padre varchar,
  foglia varchar,
  pdce_conto_code varchar,
  pdce_conto_descr varchar,
  pdce_conto_numerico varchar,
  pdce_fam_code varchar,
  importo_dare numeric,
  importo_avere numeric,
  importo_saldo numeric,
  segno integer,
  titolo varchar,
  display_error varchar
) AS
$body$
DECLARE

classifGestione record;
pdce            record;

v_imp_dare           NUMERIC :=0;
v_imp_avere          NUMERIC :=0;
v_imp_saldo		 	 NUMERIC :=0;
v_imp_dare_meno 	 NUMERIC :=0;
v_imp_avere_meno	 NUMERIC :=0;
v_imp_saldo_meno	 NUMERIC :=0;

v_importo 			 NUMERIC :=0;
v_pdce_fam_code      VARCHAR;
v_classificatori     VARCHAR;
v_classificatori1    VARCHAR;
v_codice_subraggruppamento VARCHAR;
v_anno_int integer;

DEF_NULL	constant VARCHAR:='';
RTN_MESSAGGIO 		 VARCHAR(1000):=DEF_NULL;
user_table			 VARCHAR;
conta_livelli integer;
maxLivello integer;
id_bil integer;
conta integer;

BEGIN


RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into   user_table;

v_anno_int := p_anno::integer;

classif_id:=0;
codice_voce := '';
descrizione_voce := '';
livello_codifica := 0;
padre := '';
foglia := '';
pdce_conto_code := '';
pdce_conto_descr := '';
importo_dare :=0;
importo_avere :=0;
display_error:='';

RTN_MESSAGGIO:='Inserimento nella tabella di appoggio.';
raise notice '1 - %' , clock_timestamp()::text;

v_classificatori  := '';
v_classificatori1 := '';
v_codice_subraggruppamento := '';
    
if (p_data_pnota_da IS NOT NULL and p_data_pnota_a IS NULL) OR
	(p_data_pnota_da IS NULL and p_data_pnota_a IS NOT NULL) then
    display_error:='Specificare entrambe le date della prima nota.';
    return next;
    return;
end if;
    
if p_data_pnota_da > p_data_pnota_a THEN
	display_error:='La data Da della prima nota non puo'' essere successiva alla data A.';
    return next;
    return;
end if;

v_anno_int:=p_anno::integer;    
conta:=0;
if p_cod_bilancio is not null and p_cod_bilancio <> '' then
	select count(*)
    	into conta
    from siac_t_class class,
        siac_d_class_tipo tipo_class
	where class.classif_tipo_id=tipo_class.classif_tipo_id
    	and class.ente_proprietario_id=p_ente_prop_id
        and upper(right(class.classif_code,length(class.classif_code)-1))=
        	upper(p_cod_bilancio)
        and class.data_cancellazione IS NULL;       
    if conta = 0 then 
    	display_error:='Il codice bilancio '''||p_cod_bilancio|| ''' non esiste';
    	return next;
    	return;
    end if;
end if;

select a.bil_id
into id_bil
from siac_t_bil a,
	siac_t_periodo b
where a.periodo_id=b.periodo_id
and a.data_cancellazione IS NULL
and a.ente_proprietario_id=p_ente_prop_id
and b.anno =p_anno;

--cerco le voci di conto economico e gli importi registrati sui conti
--solo per le voci "foglia".  
--I dati sono salvati sulla tabella di appoggio "siac_rep_ce_sp_gsa".
with voci as(select class.classif_id, 
 right(class.classif_code,length(class.classif_code)-1) classif_code,
class.classif_desc, r_class_fam.livello,
 	COALESCE(padre.classif_code,'') padre, 
 	case when figlio.classif_id_padre is null then 'S' else 'N' end foglia,
    case when figlio.classif_id_padre is null then class.classif_id 
    	else 0 end classif_id_foglia
    from siac_t_class class,
        siac_d_class_tipo tipo_class,
        siac_r_class_fam_tree r_class_fam
            left join (select r_fam1.classif_id, 
            	right(class1.classif_code,length(class1.classif_code)-1) classif_code
                        from siac_r_class_fam_tree r_fam1,
                            siac_t_class class1
                        where  r_fam1.classif_id=class1.classif_id
                            and r_fam1.ente_proprietario_id=p_ente_prop_id
                            and r_fam1.data_cancellazione IS NULL) padre
              on padre.classif_id=r_class_fam.classif_id_padre
             left join (select distinct r_tree2.classif_id_padre
                        from siac_r_class_fam_tree r_tree2
                        where r_tree2.ente_proprietario_id=p_ente_prop_id
                            and r_tree2.data_cancellazione IS NULL) figlio
                on r_class_fam.classif_id=figlio.classif_id_padre,
        siac_t_class_fam_tree t_class_fam        
    where class.classif_tipo_id=tipo_class.classif_tipo_id
    and class.classif_id=r_class_fam.classif_id
    and r_class_fam.classif_fam_tree_id=t_class_fam.classif_fam_tree_id
    and class.ente_proprietario_id=p_ente_prop_id
    and tipo_class.classif_tipo_code='CE_CODBIL_GSA'
    and class.data_cancellazione IS NULL
    AND v_anno_int BETWEEN date_part('year',class.validita_inizio) AND
           date_part('year',COALESCE(class.validita_fine,now())) 
    and r_class_fam.data_cancellazione IS NULL
    and r_class_fam.validita_fine IS NULL
    AND v_anno_int BETWEEN date_part('year',r_class_fam.validita_inizio) AND
           date_part('year',COALESCE(r_class_fam.validita_fine,now())) ),
conti AS( SELECT fam.pdce_fam_code,fam.pdce_fam_segno, r.classif_id,
                   conto.pdce_conto_code, conto.pdce_conto_desc,
                   conto.pdce_conto_id
            from siac_r_pdce_conto_class r,  siac_t_pdce_conto conto,
                 siac_t_pdce_fam_tree famtree, siac_d_pdce_fam fam,siac_d_ambito ambito
            where conto.pdce_conto_id=r.pdce_conto_id
            and   famtree.pdce_fam_tree_id=conto.pdce_fam_tree_id
            and   fam.pdce_fam_id=famtree.pdce_fam_id
            and   ambito.ambito_id=conto.ambito_id
            and   r.ente_proprietario_id=p_ente_prop_id
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
            where per.periodo_id=bil.periodo_id            
            and   pn.bil_id=bil.bil_id
            and   rs.pnota_id=pn.pnota_id
            and   stato.pnota_stato_id=rs.pnota_stato_id
            and   ep.regep_id=pn.pnota_id
            and   det.movep_id=ep.movep_id           
            and   ambito.ambito_id=pn.ambito_id 
            and   bil.ente_proprietario_id=p_ente_prop_id
            and   per.anno::integer=v_anno_int
            and   stato.pnota_stato_code='D'            
            and   ambito.ambito_code='AMBITO_GSA'    
            and   ((p_data_pnota_da is NOT NULL and 
    				trunc(pn.pnota_dataregistrazionegiornale) between 
    					  p_data_pnota_da and p_data_pnota_a) OR
            p_data_pnota_da IS NULL)                  
            and   pn.data_cancellazione is null
            and   pn.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   ep.data_cancellazione is null
            and   ep.validita_fine is null
            and   det.data_cancellazione is null
            and   det.validita_fine is null
            group by det.pdce_conto_id)      
insert into siac_rep_ce_sp_gsa                  
select voci.classif_id::integer, 
		voci.classif_code::varchar,
        voci.classif_desc::varchar,
        voci.livello::integer,
        voci.padre::varchar,
        voci.foglia::varchar,
        'CE_CODBIL_GSA'::varchar,
        COALESCE(conti.pdce_conto_code,'')::varchar,
        COALESCE(conti.pdce_conto_desc,'')::varchar,
        COALESCE(replace(conti.pdce_conto_code,'.',''),'')::varchar,
        COALESCE(conti.pdce_fam_code,'')::varchar,
        COALESCE(movimenti.importo_dare,0)::numeric,
        COALESCE(movimenti.importo_avere,0)::numeric,
        --PP OP RE = Avere
        	--'PP','OP','OA','RE' = Ricavi
        case when UPPER(conti.pdce_fam_segno) ='AVERE' then 
        	COALESCE(movimenti.importo_avere,0) - COALESCE(movimenti.importo_dare,0)
        	--AP OA CE = Dare
            --'AP','CE' = Costi 
        else COALESCE(movimenti.importo_dare,0) - COALESCE(movimenti.importo_avere,0)
        end ::numeric,
        p_ente_prop_id::integer,
        user_table::varchar
from voci 
	left join conti 
    	on voci.classif_id_foglia = conti.classif_id              
	left join movimenti
    	on conti.pdce_conto_id=movimenti.pdce_conto_id
order by voci.classif_code;

  
--inserisco il record per il totale finale
insert into siac_rep_ce_sp_gsa
values (0,'ZZ9999','RISULTATO DI ESERCIZIO',1,'CE_CODBIL_GSA','','S','','','','',
	0,0,0,p_ente_prop_id,user_table);
    
RTN_MESSAGGIO:='Lettura livello massimo.';
--leggo qual e' il massimo livello per le voci di conto NON "foglia".
maxLivello:=0;
SELECT max(a.livello_codifica) 
	into maxLivello
from siac_rep_ce_sp_gsa a
where a.foglia='N'
	and a.utente = user_table
	and a.ente_proprietario_id = p_ente_prop_id;
    
raise notice 'maxLivello = %', maxLivello;

RTN_MESSAGGIO:='Ciclo sui livelli';
--ciclo sui livelli partendo dal massimo in quanto devo ricostruire
--al contrario gli importi per i conti che non sono "foglia".
for conta_livelli in reverse maxLivello..1
loop     
	RTN_MESSAGGIO:='Ciclo sui conti non foglia.';
	raise notice 'conta_livelli = %', conta_livelli;
    	--ciclo su tutti i conti non "foglia" del livello che sto gestendo.
    for classifGestione IN
    	select a.cod_voce, a.classif_id
        from siac_rep_ce_sp_gsa a
        where a.foglia='N'
          and a.livello_codifica=conta_livelli
          and a.utente = user_table
          and a.ente_proprietario_id = p_ente_prop_id
     	order by a.cod_voce
     loop
        v_imp_dare:=0;
        v_imp_avere:=0;
        RTN_MESSAGGIO:='Calcolo importi.';
        
        	--calcolo gli importi come somma dei suoi figli.
        select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
        	into v_imp_dare, v_imp_avere, v_imp_saldo
        from siac_rep_ce_sp_gsa a
        where a.padre=classifGestione.cod_voce
         	and a.utente = user_table
          	and a.ente_proprietario_id = p_ente_prop_id;
        
        raise notice 'codice_voce = % - importo_dare= %, importo_avere = %', 
        	classifGestione.cod_voce, v_imp_dare,v_imp_avere;
        RTN_MESSAGGIO:='Update importi.';
        
            --aggiorno gli importi 
        update siac_rep_ce_sp_gsa a
        	set imp_dare=v_imp_dare,
            	imp_avere=v_imp_avere,
                imp_saldo=v_imp_saldo
        where cod_voce=classifGestione.cod_voce
        	and utente = user_table
          	and ente_proprietario_id = p_ente_prop_id;
            
     end loop; --loop voci NON "foglie" del livello gestito.     
end loop; --loop livelli

--devo aggiornare alcuni importi totali secondo le seguenti formule.

--AZ9999= AA0010+AA0240+AA0270+AA0320+AA0750+AA0940+AA0980+AA1050+AA1060
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('AA0010','AA0240','AA0270','AA0320','AA0750','AA0940','AA0980',
	'AA1050','AA1060')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare,
          imp_avere=v_imp_avere,
          imp_saldo=v_imp_saldo
where a.cod_voce= 'AZ9999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;
                   
--BZ9999= BA0010+BA0390+BA1910+BA1990+BA2080+BA2500+BA2560+BA2630+BA2660+BA2690
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('BA0010','BA0390','BA1910','BA1990','BA2080','BA2500','BA2560',
	'BA2630','BA2660','BA2690')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare,
          imp_avere=v_imp_avere,
          imp_saldo=v_imp_saldo
where a.cod_voce= 'BZ9999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;
    
--CZ9999= CA0010+CA0050-CA0110-CA0150    
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
v_imp_dare_meno:=0;
v_imp_avere_meno:=0;
v_imp_saldo_meno:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('CA0010','CA0050')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;    
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare_meno, v_imp_avere_meno, v_imp_saldo_meno
from siac_rep_ce_sp_gsa a
where a.cod_voce in('CA0110','CA0150')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;     
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare-v_imp_dare_meno,
          imp_avere=v_imp_avere-v_imp_avere_meno,
          imp_saldo=v_imp_saldo-v_imp_saldo_meno
where a.cod_voce= 'CZ9999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;  
    
--DZ9999= DA0010-DA0020
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
v_imp_dare_meno:=0;
v_imp_avere_meno:=0;
v_imp_saldo_meno:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('DA0010')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;    
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare_meno, v_imp_avere_meno, v_imp_saldo_meno
from siac_rep_ce_sp_gsa a
where a.cod_voce in('DA00200')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;     
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare-v_imp_dare_meno,
          imp_avere=v_imp_avere-v_imp_avere_meno,
          imp_saldo=v_imp_saldo-v_imp_saldo_meno
where a.cod_voce= 'DZ9999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;      
      
/* SIAC-8642 28/03/2022  
	Il campo EZ9999 deve essere calcolato con la stessa logica del campo:
    "EA0000 - E) Proventi e oneri straordinari".
    Pertanto prendo quanto gia' calcolato per  EA0000 e imposto gli stessi
    valori per EZ9999.
    Prima era calcolato come:
 		EZ9999= EA0010-EA0260
    L'importo del saldo che serve per il report BILR248 rimane calcolato come 
    saldo di EA0010 - saldo di EA0260.
*/
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
v_imp_dare_meno:=0;
v_imp_avere_meno:=0;
v_imp_saldo_meno:=0;
select --sum(a.imp_dare), sum(a.imp_avere), 
		sum(a.imp_saldo)
    into --v_imp_dare, v_imp_avere, 
    	v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('EA0010')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;    
select --sum(a.imp_dare), sum(a.imp_avere), 
		sum(a.imp_saldo)
    into --v_imp_dare_meno, v_imp_avere_meno, 
    	v_imp_saldo_meno
from siac_rep_ce_sp_gsa a
where a.cod_voce in('EA0260')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id; 
select sum(a.imp_dare), sum(a.imp_avere)
    into v_imp_dare, v_imp_avere
from siac_rep_ce_sp_gsa a
where a.cod_voce in('EA0000')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;        

update siac_rep_ce_sp_gsa a
      set --imp_dare=v_imp_dare-v_imp_dare_meno,
          --imp_avere=v_imp_avere-v_imp_avere_meno,
          --imp_saldo=v_imp_saldo-v_imp_saldo_meno
          imp_dare=v_imp_dare,
          imp_avere=v_imp_avere,
          imp_saldo=v_imp_saldo-v_imp_saldo_meno
where a.cod_voce= 'EZ9999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;      
    
--XA0000= AZ9999-BZ9999+CZ9999+DZ9999+EZ9999
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
v_imp_dare_meno:=0;
v_imp_avere_meno:=0;
v_imp_saldo_meno:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('AZ9999','CZ9999','DZ9999','EZ9999')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;    
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare_meno, v_imp_avere_meno, v_imp_saldo_meno
from siac_rep_ce_sp_gsa a
where a.cod_voce in('BZ9999')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;     
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare-v_imp_dare_meno,
          imp_avere=v_imp_avere-v_imp_avere_meno,
          imp_saldo=v_imp_saldo-v_imp_saldo_meno
where a.cod_voce= 'XA0000'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;  
    
--YZ9999= YA0010+YA0060+YA0090
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('YA0010','YA0060','YA0090')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;    
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare,
          imp_avere=v_imp_avere,
          imp_saldo=v_imp_saldo
where a.cod_voce= 'YZ9999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id; 
        
--ZZ9999= XA0000-YZ9999
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
v_imp_dare_meno:=0;
v_imp_avere_meno:=0;
v_imp_saldo_meno:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('XA0000')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;    
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare_meno, v_imp_avere_meno, v_imp_saldo_meno
from siac_rep_ce_sp_gsa a
where a.cod_voce in('YZ9999')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;     
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare-v_imp_dare_meno,
          imp_avere=v_imp_avere-v_imp_avere_meno,
          imp_saldo=v_imp_saldo-v_imp_saldo_meno
where a.cod_voce= 'ZZ9999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;  
        
--restituisco i dati presenti sulla tabella di appoggio.
return query
select tutto.*, 
	COALESCE(config.segno,1)::integer segno, 
    COALESCE(config.titolo,'') titolo,
    ''::varchar
from (select a.classif_id::integer, 
  a.cod_voce::varchar cod_voce,
  a.descrizione_voce::varchar,
  a.livello_codifica::integer,
  a.padre::varchar,
  a.foglia::varchar,
  COALESCE(a.pdce_conto_code,'')::varchar,
  COALESCE(a.pdce_conto_descr,'')::varchar,
  COALESCE(a.pdce_conto_numerico,'')::varchar,
  COALESCE(a.pdce_fam_code,'')::varchar,
  COALESCE(a.imp_dare,0)::numeric,
  COALESCE(a.imp_avere,0)::numeric,
  COALESCE(a.imp_saldo,0)::numeric--,
  --case when a.pdce_fam_code in ('PP','OP','OA','RE') then 1
  --	else -1 end::integer,
--  ''::varchar
from siac_rep_ce_sp_gsa a
where a.utente = user_table
	and a.ente_proprietario_id = p_ente_prop_id
    and ((p_cod_bilancio is null OR p_cod_bilancio = '') OR
    	 (p_cod_bilancio is not null and p_cod_bilancio <> '' and
          (upper(a.cod_voce) = upper(p_cod_bilancio) OR 
          	upper(a.padre) = upper(p_cod_bilancio))))    
UNION
select b.classif_id::integer, 
  b.cod_voce::varchar cod_voce,
  b.descrizione_voce::varchar,
  b.livello_codifica::integer,
  b.padre::varchar,
  b.foglia::varchar,
  ''::varchar,
  ''::varchar,
  ''::varchar,
  ''::varchar,
  COALESCE(sum(b.imp_dare),0)::numeric,
  COALESCE(sum(b.imp_avere),0)::numeric,
  COALESCE(sum(b.imp_saldo),0)::numeric--,
 -- 0::integer,
 -- ''::varchar
from siac_rep_ce_sp_gsa b
where b.utente = user_table
	and b.ente_proprietario_id = p_ente_prop_id
    and b.foglia='S'
    and ((p_cod_bilancio is null OR p_cod_bilancio = '') OR
    	 (p_cod_bilancio is not null and p_cod_bilancio <> '' and
          (b.cod_voce = p_cod_bilancio OR b.padre = p_cod_bilancio)))
    and b.classif_id not in (select c.classif_id
    		from siac_rep_ce_sp_gsa c
            where c.utente = user_table
				and c.ente_proprietario_id = p_ente_prop_id
                and c.pdce_conto_code ='')
group by b.classif_id, b.cod_voce, b.descrizione_voce, b.livello_codifica,
  b.padre, b.foglia) tutto 
  left join (select conf.cod_voce, conf.titolo, conf.segno
  			 from siac_t_config_rep_ce_sp_gsa conf
             where conf.bil_id=id_bil
             and conf.tipo_report='CE'
             and conf.data_cancellazione IS NULL) config
  	on tutto.cod_voce=config.cod_voce   
order by 2,6;
    
delete from siac_rep_ce_sp_gsa where utente = user_table;

raise notice '2 - %' , clock_timestamp()::text;
raise notice 'fine OK';

  EXCEPTION
  WHEN no_data_found THEN
  raise notice 'Nessun dato trovato per rendiconto gestione GSA';
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
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR248_conto_economico_allegato_A_gsa" (p_ente_prop_id integer, p_anno varchar, p_cod_bilancio varchar, p_data_pnota_da date, p_data_pnota_a date)
  OWNER TO siac;