DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_LISTAR_ATUALIZAR_STATUS_FRETE`$$

CREATE PROCEDURE `PROC_INTEGRA_LISTAR_ATUALIZAR_STATUS_FRETE`(
   IN xTipoMovto   INT,
   IN DanfeCTE     VARCHAR(100)
   #OUT RESULTADO   INT,
   #OUT MENSAGEM    VARCHAR(500)
)
BEGIN
   # PROCEDURE PARA CONSULTAR PRODUTOS DE PICKING
   # @author Érico Forcinetti <2018/05/27>
   # @company Overflash
   # Parametros : xtipomovto = 0 => Listar / xtipomovto = 1 => Update tbintegraSAP_CTe.dthr_integracao 
   DECLARE xQtdeLinhas INT DEFAULT 0;
   DECLARE RESULTADO   INT;
   DECLARE MENSAGEM    VARCHAR(500);
   SET RESULTADO = 0;
     
   IF xTipoMovto = 0 THEN
      SELECT CardCode, CardName, DocTypeId, DocEntry, DocNum, SERIAL, data_documento, num_chave DanfeCTE,
             TRUNCATE(valor_total,4) FreteFornecedor, TRUNCATE(tbprog_entregas.valor_entrega,4) FreteCalculado, 
             tbtms_ctrc_terc2.dthr_analise, tbtms_ctrc_terc2.status_analise, IFNULL(tbtms_ctrc_terc2.flg_analise,9) flg_analise
      FROM tbintegraSAP_CTe
      INNER JOIN of_logistica.tbtms_ctrc_terc ON 
                 tbintegraSAP_CTe.num_chave = tbtms_ctrc_terc.id_remessa
      INNER JOIN of_logistica.tbtms_ctrc_terc2 ON 
                 tbtms_ctrc_terc2.cod_emp      = tbtms_ctrc_terc.cod_emp
             AND tbtms_ctrc_terc2.cod_fil      = tbtms_ctrc_terc.cod_fil
             AND tbtms_ctrc_terc2.cnpj_cpf_emi = tbtms_ctrc_terc.cnpj_cpf_emi
             AND tbtms_ctrc_terc2.num_ctrc     = tbtms_ctrc_terc.num_ctrc
             AND tbtms_ctrc_terc2.serie_ctrc   = tbtms_ctrc_terc.serie_ctrc 
      INNER JOIN of_logistica.tbprog_entregas ON 
                              tbprog_entregas.cod_emp     = tbtms_ctrc_terc2.cod_emp_entrega
                          AND tbprog_entregas.cod_fil     = tbtms_ctrc_terc2.cod_fil_entrega
                          AND tbprog_entregas.ano_entrega = tbtms_ctrc_terc2.ano_entrega
                          AND tbprog_entregas.num_entrega = tbtms_ctrc_terc2.num_entrega
      WHERE tbintegraSAP_CTe.dthr_cancel IS NULL
        AND tbintegraSAP_CTe.DocEntry <> 'N/A'
        AND tbintegraSAP_CTe.DocEntry <> '0'
        AND tbtms_ctrc_terc2.dthr_analise IS NOT NULL
        AND tbintegraSAP_CTe.dthr_integracao IS NULL
        #AND tbintegraSAP_CTe.status_analise <> IFNULL(tbtms_ctrc_terc2.flg_analise,'9')
        AND tbtms_ctrc_terc2.dthr_analise BETWEEN DATE_ADD(NOW(), INTERVAL -30 DAY) AND DATE_ADD(NOW(), INTERVAL -10 DAY)
        ;
        
      SELECT ROW_COUNT() INTO xQtdeLinhas;
      SET MENSAGEM = CONCAT("Total de registros selecionados : ",xQtdeLinhas);
      
   END IF;
   
   
   IF xTipoMovto = 1 THEN
      UPDATE tbintegraSAP_CTe 
      INNER JOIN of_logistica.tbtms_ctrc_terc ON 
                 tbintegraSAP_CTe.num_chave = tbtms_ctrc_terc.id_remessa
      INNER JOIN of_logistica.tbtms_ctrc_terc2 ON 
                 tbtms_ctrc_terc2.cod_emp      = tbtms_ctrc_terc.cod_emp
             AND tbtms_ctrc_terc2.cod_fil      = tbtms_ctrc_terc.cod_fil
             AND tbtms_ctrc_terc2.cnpj_cpf_emi = tbtms_ctrc_terc.cnpj_cpf_emi
             AND tbtms_ctrc_terc2.num_ctrc     = tbtms_ctrc_terc.num_ctrc
             AND tbtms_ctrc_terc2.serie_ctrc   = tbtms_ctrc_terc.serie_ctrc 
      INNER JOIN of_logistica.tbprog_entregas ON 
                              tbprog_entregas.cod_emp     = tbtms_ctrc_terc2.cod_emp_entrega
                          AND tbprog_entregas.cod_fil     = tbtms_ctrc_terc2.cod_fil_entrega
                          AND tbprog_entregas.ano_entrega = tbtms_ctrc_terc2.ano_entrega
                          AND tbprog_entregas.num_entrega = tbtms_ctrc_terc2.num_entrega
      SET tbintegraSAP_CTe.dthr_integracao = NOW(),
          tbintegraSAP_CTe.status_analise  = tbtms_ctrc_terc2.flg_analise,
          tbintegraSAP_CTe.vlr_calculado   = tbprog_entregas.valor_entrega,
          tbintegraSAP_CTe.observ_analise  = tbtms_ctrc_terc2.observ_analise
      WHERE tbintegraSAP_CTe.num_chave = DanfeCTE;
      #WHERE true #tbtms_ctrc_terc2.dthr_analise BETWEEN DATE_ADD(NOW(), INTERVAL -30 DAY) AND DATE_ADD(NOW(), INTERVAL -10 DAY)
      #  AND ifnull(tbintegraSAP_CTe.status_analise,'X') <> ifNull(tbtms_ctrc_terc2.flg_analise,'X')
      #  and tbtms_ctrc_terc2.flg_analise is not null;
      
      IF ROW_COUNT() = 0 THEN
         SET RESULTADO = -1;
         SET MENSAGEM = "ERRO - Nenhum Registro foi atualizado ! ";
      ELSE
         SET MENSAGEM = "OK - Registro atualizado com sucesso ! ";
      END IF;
      SELECT RESULTADO, MENSAGEM;
      
   END IF;
   
END$$

DELIMITER ;