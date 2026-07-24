DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_AtualizarCTE_SLIN`$$

CREATE PROCEDURE `PROC_INTEGRA_AtualizarCTE_SLIN`(
	IN oCodUsuario				    VARCHAR(10),
	# Parametros de Retorno
	OUT RESULTADO         VARCHAR(5),
	OUT MENSAGEM          VARCHAR(500)
)
BLOCO1:BEGIN
   /*
   #Author David Ruy <20221226>
   #Reviser David Ruy <20230124> Ajuste, não excluir mais tbtms_ctrc -> atualizar data_cancel
   */

   DECLARE xNumCTE         VARCHAR(20);
   DECLARE xSerieCTE       VARCHAR(10);
   DECLARE xNumChave       VARCHAR(50);
   DECLARE xDescrDespesa   VARCHAR(100);
   DECLARE xValorDespesa   DOUBLE(18,6);
   DECLARE xNumDocRef      VARCHAR(20);
   DECLARE xSerieDocRef    VARCHAR(10);
   DECLARE xChaveDocRef    VARCHAR(50);
   DECLARE xQtdeAux        INT DEFAULT 0;

	DECLARE excecao         INT DEFAULT 0;
	#DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;

   SET RESULTADO = "1";
   SET MENSAGEM = "Inclusão realizada com sucesso";
   
   DROP TEMPORARY TABLE IF EXISTS tbTMPCTE;
   CREATE TEMPORARY TABLE tbTMPCTE
      SELECT tbCTeInvent.*, #SUM(tbVLR.valor_despesa) SomaDesp,
             GROUP_CONCAT(DISTINCT tbDocRef.num_doc_ref) AS NFs
      FROM tbintegraSAP_CTe tbCTeInvent
      LEFT JOIN tbintegraSAP_CTeVlr tbVLR ON 
         tbVLR.id_documento = tbCTeInvent.id_documento
      LEFT JOIN tbintegraSAP_CTeDocRef tbDocRef ON 
         tbDocRef.id_documento = tbCTeInvent.id_documento
      LEFT JOIN of_logistica.tbtms_ctrc_terc TbCTeTerc ON
                TbCTeTerc.id_remessa = tbCTeInvent.num_chave
      WHERE TbCTeTerc.id_remessa IS NULL
      AND tbCTeInvent.dthr_cancel IS NULL
      GROUP BY num_chave;

   INSERT INTO of_logistica.tbtms_ctrc_terc (
          cod_emp, cod_fil, cnpj_cpf_emi, raz_soc_emi, cod_ibge_emi, 
          num_ctrc, serie_ctrc, data_viagem, dthr_emiss, id_remessa,
          cnpj_cpf_rem, raz_soc_rem, cidade_rem, estado_rem, cep_rem, cod_ibge_origem, 
          cnpj_cpf_dest, raz_soc_dest, cidade_dest, estado_dest, cep_dest, cod_mun_dest, 
          vlr_tot_ctrc, num_nfs)
      (SELECT '001', '001', emi_cnpj, SUBSTRING(CardName,1,50), NULL,
              SERIAL AS NumCTE, serie_documento AS SerieCTE,data_documento, data_documento, num_chave,
              orig_cnpj, orig_raz_social, orig_cidade, orig_cep, orig_uf, IbgeCodeMuniIni, 
              dest_cnpj, dest_raz_social, dest_cidade, dest_cep, dest_uf, IbgeCodeMuniFim,
              valor_total, SUBSTRING(NFs,01,200)
       FROM tbTMPCTE);
       
       
       
   /******************************************************/
   #Atualiza valores do CTe (composição tbintegraSAP_CTeVlr)    
   DROP TEMPORARY TABLE IF EXISTS tbTMPCTEVlr;
   CREATE TEMPORARY TABLE tbTMPCTEVlr 
      SELECT tbTMPCTE.num_chave, tbTMPCTE.id_documento, tbVlr.descr_despesa, SUM(tbVlr.valor_despesa) valor_despesa
      FROM tbintegraSAP_CTeVlr tbVlr
      INNER JOIN tbTMPCTE ON
            tbTMPCTE.id_documento = tbVlr.id_documento
      WHERE IFNULL(tbVlr.valor_despesa ,0) > 0
      GROUP BY num_chave, descr_despesa;
      
   WHILE EXISTS (SELECT 1 FROM tbTMPCTEVlr) DO
   
      SELECT num_chave, descr_despesa, valor_despesa 
      INTO xNumChave, xDescrDespesa, xValorDespesa
      FROM tbTMPCTEVlr 
      LIMIT 1;
      
      IF xDescrDespesa IN ('FRETE') OR 
             xDescrDespesa LIKE '%FRETE%' THEN
         UPDATE of_logistica.tbtms_ctrc_terc
         SET vlr_frete_apag = IFNULL(vlr_frete_apag,0)     + xValorDespesa
         WHERE id_remessa = xNumChave;        
      ELSEIF xDescrDespesa IN ('GRIS','SEGURO','Advalorem') OR 
         xDescrDespesa LIKE ('%SEGURO%') OR 
         xDescrDespesa LIKE ('%Advalorem%') THEN
         UPDATE of_logistica.tbtms_ctrc_terc
         SET vlr_seguro   = IFNULL(vlr_seguro,0)   + xValorDespesa
         WHERE id_remessa = xNumChave;         
      ELSEIF xDescrDespesa IN ('ICMS') OR 
             xDescrDespesa LIKE '%ICMS%' THEN
         UPDATE of_logistica.tbtms_ctrc_terc
         SET vlr_icms     = IFNULL(vlr_icms,0)     + xValorDespesa
         WHERE id_remessa = xNumChave;         
      ELSEIF xDescrDespesa IN ('IOF') OR 
             xDescrDespesa LIKE '%IOF%' THEN
         UPDATE of_logistica.tbtms_ctrc_terc
         SET vlr_iof      = IFNULL(vlr_iof,0)      + xValorDespesa
         WHERE id_remessa = xNumChave;         
      ELSEIF xDescrDespesa IN ('TAXA') OR 
             xDescrDespesa LIKE '%TAXA%' THEN
         UPDATE of_logistica.tbtms_ctrc_terc
         SET vlr_tx_ctrc  = IFNULL(vlr_tx_ctrc,0)  + xValorDespesa
         WHERE id_remessa = xNumChave;         
      ELSEIF xDescrDespesa IN ('PEDAGIO') OR 
             xDescrDespesa LIKE '%PEDAGIO%' THEN
         UPDATE of_logistica.tbtms_ctrc_terc
         SET vlr_pedagio  = IFNULL(vlr_pedagio,0)  + xValorDespesa
         WHERE id_remessa = xNumChave;         
      ELSE 
         UPDATE of_logistica.tbtms_ctrc_terc
         SET vlr_desp_div = IFNULL(vlr_desp_div,0) + xValorDespesa
         WHERE id_remessa = xNumChave;
      END IF;       
      
      DELETE FROM tbTMPCTEVlr 
      WHERE num_chave = xNumChave
        AND descr_despesa = xDescrDespesa;
   
   END WHILE;
   SELECT COUNT(*) INTO xQtdeAux FROM tbTMPCTEVlr;   
   DROP TEMPORARY TABLE IF EXISTS tbTMPCTEVlr;
            

   /******************************************************/
   #Insere os Documentos (NF´s) Referenciadas (tbintegraSAP_CTeDocRef)  
   INSERT IGNORE INTO of_logistica.tbtms_ctrc_terc2 (
         cod_emp, cod_fil, num_ctrc, serie_ctrc, cnpj_cpf_emi, num_nf, serie_nf, chave_nfe)
         (SELECT '001', '001', SERIAL AS NumCTE, serie_documento AS SerieCTE,
             tbTMPCTE.emi_cnpj, TRIM(LEADING '0' FROM num_doc_ref) AS num_doc_ref, 
             TRIM(LEADING '0' FROM serie_doc_ref) AS serie_doc_ref, chave_doc_ref
         FROM tbintegraSAP_CTeDocRef
         INNER JOIN tbTMPCTE ON
               tbTMPCTE.id_documento = tbintegraSAP_CTeDocRef.id_documento);
   
   DROP TEMPORARY TABLE IF EXISTS tbTMPCTE;   
   
   CALL PROC_INTEGRA_EnviarLog('999999',"PROC_INTEGRA_AtualizarCTE_SLIN",xQtdeAux,"OK","Automatico OK",@R,@M);   
   
   
   
   
   
   
   
   /*******************************************************************************************/   
   #Cancelamentos
   DROP TEMPORARY TABLE IF EXISTS tbTMPCTE;
   CREATE TEMPORARY TABLE tbTMPCTE
      SELECT tbCTeInvent.*, #SUM(tbVLR.valor_despesa) SomaDesp,
             GROUP_CONCAT(DISTINCT tbDocRef.num_doc_ref) AS NFs
      FROM tbintegraSAP_CTe tbCTeInvent
      LEFT JOIN tbintegraSAP_CTeVlr tbVLR ON 
         tbVLR.id_documento = tbCTeInvent.id_documento
      LEFT JOIN tbintegraSAP_CTeDocRef tbDocRef ON 
         tbDocRef.id_documento = tbCTeInvent.id_documento
      LEFT JOIN of_logistica.tbtms_ctrc_terc TbCTeTerc ON
                TbCTeTerc.id_remessa = tbCTeInvent.num_chave
      WHERE TbCTeTerc.id_remessa IS NOT NULL
        AND tbCTeInvent.dthr_cancel IS NOT NULL
        AND TbCTeTerc.data_cancel IS NULL
      GROUP BY num_chave;
    
    SELECT COUNT(*) INTO xQtdeAux FROM tbTMPCTE;    
    
    /*DELETE FROM of_logistica.tbtms_ctrc_terc 
    WHERE EXISTS (SELECT 1 FROM tbTMPCTE 
                  WHERE tbtms_ctrc_terc.id_remessa = tbTMPCTE.num_chave);
    */

   UPDATE of_logistica.tbtms_ctrc_terc
   INNER JOIN tbTMPCTE ON 
              tbTMPCTE.num_chave = tbtms_ctrc_terc.id_remessa
   INNER JOIN of_logistica.tbtms_ctrc_terc2 ON 
              tbtms_ctrc_terc.cod_emp = tbtms_ctrc_terc2.cod_emp
          AND tbtms_ctrc_terc.cod_fil = tbtms_ctrc_terc2.cod_fil
          AND tbtms_ctrc_terc.cnpj_cpf_emi = tbtms_ctrc_terc2.cnpj_cpf_emi
          AND tbtms_ctrc_terc.num_ctrc = tbtms_ctrc_terc2.num_ctrc
          AND tbtms_ctrc_terc.serie_ctrc = tbtms_ctrc_terc2.serie_ctrc
   SET tbtms_ctrc_terc2.cod_emp_entrega = NULL,   
       tbtms_ctrc_terc2.cod_fil_entrega = NULL, 
       tbtms_ctrc_terc2.ano_entrega = NULL, 
       tbtms_ctrc_terc2.num_entrega = NULL, 
       tbtms_ctrc_terc.data_cancel = CURRENT_DATE(),
       tbtms_ctrc_terc.data_cancel_ = NOW();
     

   DROP TEMPORARY TABLE IF EXISTS tbTMPCTE;   
   
   CALL PROC_INTEGRA_EnviarLog('999999',"PROC_INTEGRA_AtualizarCTE_SLIN Cancel",xQtdeAux,"OK","Cancelamento OK",@R,@M);   
   
   
   IF excecao = 1 THEN
      SET RESULTADO = "0";
      SET MENSAGEM = "Erro SQL - Verifique com o Administrador";
   END IF;
   
END$$

DELIMITER ;