DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_RetornoContagem`$$

CREATE PROCEDURE `PROC_INTEGRA_RetornoContagem`(
   IN oCodUsuario				      VARCHAR(10),
   IN oTipoSelecao         INT     #0 = Contagens a Criar, 1 = Contagens a Confirmar
   # Parametros de Retorno
   #OUT RESULTADO          INT,
   #OUT MENSAGEM           VARCHAR(500)
)
BLOCO1:BEGIN
   /***************************************************************************
   #@Autho David Ruy <2019/12/11>
   # Lista recebimentos a maior para envio ao SAP como complemento de entradas
   ****************************************************************************/
   DECLARE excecao         INT DEFAULT 0;
   DECLARE RESULTADO       INT DEFAULT 1;
   DECLARE MENSAGEM        VARCHAR(500);
   DECLARE xChave          VARCHAR(20);
   DECLARE xQtdeNF         DECIMAL(18,5);
   DECLARE xQtdeRecebido   DECIMAL(18,5);   
   DECLARE xSaldoaMaior    DECIMAL(18,5);
   DECLARE xqtde_est2      DECIMAL(18,5);
   DECLARE xnum_lote       VARCHAR(10);
   DECLARE xsequencia_lote INT;
   
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
    
   IF (oTipoSelecao = 0) THEN
      DROP TEMPORARY TABLE IF EXISTS tbTMPItemContagem;
      CREATE TEMPORARY TABLE tbTMPItemContagem
         SELECT tbwmsEstoque.cod_emp, tbwmsEstoque.cod_fil, tbwmsEstoque.ano_solic, tbwmsEstoque.num_solic, tbwmsEstoque.num_item, 
                tbItem.qtde_est, tbItem.real_est,
               (tbItem.real_est - tbItem.qtde_est) xSaldoaMaior,
                tbAcons.num_lote, tbAcons.sequencia_lote, tbAcons.qtde_est2,
                tbEntradas.num_nf AS NumDoc,
                tbwmsEstoque.cod_produto, tbwmsEstoque.num_lote_cli,
                tbIntegraArmazem.cod_armazem CodArmazemSAP, 
                of_logistica.fnLocalizCompleta2(tbwmsEstoque.cod_und, tbwmsEstoque.cod_armazem, tbwmsEstoque.camara, tbwmsEstoque.rua, 
                                 tbwmsEstoque.posicao, tbwmsEstoque.altura, tbwmsEstoque.profund, NULL, "Sem endereço") binCode
         FROM of_logistica.tbsolic_entradas_acons tbAcons
         INNER JOIN of_logistica.tbwms_estoque tbwmsEstoque ON
                tbwmsEstoque.cod_emp        = tbAcons.cod_emp 
            AND tbwmsEstoque.cod_fil        = tbAcons.cod_fil
            AND tbwmsEstoque.num_lote       = tbAcons.num_lote
            AND tbwmsEstoque.sequencia_lote = tbAcons.sequencia_lote
         LEFT JOIN tbintegraSAP_DeParaStatus_Armazem tbIntegraArmazem ON 
                     tbIntegraArmazem.cod_status = tbwmsEstoque.status_lote
         INNER JOIN of_logistica.tbsolic_entradas_item tbItem ON
                tbItem.cod_emp   = tbAcons.cod_emp 
            AND tbItem.cod_fil   = tbAcons.cod_fil
            AND tbItem.ano_solic = tbAcons.ano_solic
            AND tbItem.num_solic = tbAcons.num_solic
            AND tbItem.num_item  = tbAcons.num_item
         INNER JOIN of_logistica.tbsolic_entradas tbEntradas ON
                tbEntradas.cod_emp   = tbItem.cod_emp 
            AND tbEntradas.cod_fil   = tbItem.cod_fil
            AND tbEntradas.ano_solic = tbItem.ano_solic
            AND tbEntradas.num_solic = tbItem.num_solic
         LEFT JOIN tbintegraSAP_Contagem tbIntegraContagem ON
                  tbIntegraContagem.cod_emp   = tbAcons.cod_emp 
              AND tbIntegraContagem.cod_fil   = tbAcons.cod_fil
              AND tbIntegraContagem.ano_solic = tbAcons.ano_solic 
              AND tbIntegraContagem.num_solic = tbAcons.num_solic
              AND tbIntegraContagem.num_item  = tbAcons.num_item
              #AND tbIntegraContagem.num_lote = tbAcons.num_lote
              #AND tbIntegraContagem.sequencia_lote = tbAcons.sequencia_lote
         WHERE IFNULL(tbAcons.qtde_est2,0) > 0 
           AND tbIntegraContagem.cod_emp IS NULL
           AND tbItem.real_est > tbItem.qtde_est
         ORDER BY num_solic, num_item, num_lote, sequencia_lote;
      WHILE EXISTS (SELECT 1 FROM tbTMPItemContagem) DO
         SELECT CONCAT(num_solic, num_item), qtde_est, xSaldoaMaior
         INTO xChave, xQtdeNF, xSaldoaMaior
         FROM tbTMPItemContagem LIMIT 1;
         SET xQtdeRecebido = 0;
         
         WHILE EXISTS (SELECT 1 FROM tbTMPItemContagem WHERE CONCAT(num_solic, num_item) = xChave) DO
         
            SELECT qtde_est2, num_lote, sequencia_lote 
            INTO xqtde_est2, xnum_lote, xsequencia_lote 
            FROM tbTMPItemContagem WHERE xChave = CONCAT(num_solic, num_item) LIMIT 1;
            
            SET xQtdeRecebido = xQtdeRecebido + xqtde_est2;
            
            IF xQtdeRecebido > xQtdeNF  THEN
            
               SET xqtde_est2 = xQtdeRecebido - xQtdeNF;
            
               INSERT INTO tbintegraSAP_Contagem (
                    Id,
                    Reference,
                    CountingDate,
                    ItemCode, 
                    WarehouseCode, 
                    BinCode, 
                    BatchNumber_Code, 
                    BatchNumber_Quantity, 
                    SerialNumber_ManufactureCode, 
                    ContedQuantity,
                    TipoDocSLIN,
                    cod_emp,
                    cod_fil,	
                    ano_solic,
                    num_solic,
                    num_item,
                    num_lote,
                    sequencia_lote,
                    observacoes,   
                    dthr_inc) 
              (SELECT 0, CONCAT("Ajuste Entrada a maior SLIN - Doc ",NumDoc), NOW(), 
                  tbTMPItemContagem.cod_produto, tbTMPItemContagem.CodArmazemSAP, tbTMPItemContagem.binCode,
                  tbTMPItemContagem.num_lote_cli, xqtde_est2, NULL, 
                  xqtde_est2, 'E',
                  cod_emp, cod_fil, ano_solic, num_solic, num_item, num_lote, sequencia_lote, 'observ lote', NOW()
               FROM tbTMPItemContagem
               WHERE CONCAT(num_solic, num_item) = xChave
                 AND num_lote = xnum_lote
                 AND sequencia_lote = xsequencia_lote);
            END IF;
            
            DELETE FROM tbTMPItemContagem 
            WHERE xChave = CONCAT(num_solic, num_item) 
              AND num_lote = xnum_lote
              AND sequencia_lote = xsequencia_lote;
              
         END WHILE;
                 
      END WHILE;
      DROP TEMPORARY TABLE IF EXISTS tbTMPItemContagem;
      
      /*****************************************************************************************
      #Retorno Dataset 1 (Topo) / DataSet 2 (Itens) / DataSet 3 (Lotes)
      #Registros a para gerar contagem no SAP
      *****************************************************************************************/
      SELECT id, Reference, CountingDate, CONCAT(cod_emp,cod_fil, ano_solic, num_solic) AS NumDocSLIN, RESULTADO 
      FROM tbintegraSAP_Contagem
      WHERE id = 0
      GROUP BY NumDocSlin;
      SELECT CONCAT(cod_emp,cod_fil, ano_solic, num_solic) AS NumDocSLIN, num_item, ItemCode, WarehouseCode, BinCode, SUM(ContedQuantity) AS ContedQuantity
      FROM tbintegraSAP_Contagem
      WHERE id = 0
      GROUP BY NumDocSlin, num_item;
      SELECT CONCAT(cod_emp,cod_fil, ano_solic, num_solic) AS NumDocSLIN, num_item,  
            BatchNumber_Code, BatchNumber_Quantity, CONCAT('UA',TRIM(LEADING '0' FROM cod_emp),'/',TRIM(LEADING '0' FROM cod_fil),'-',
                                                    TRIM(LEADING '0' FROM num_lote),'.', sequencia_lote) NumLoteSlin
      FROM tbintegraSAP_Contagem
      WHERE id = 0;
      
   ELSEIF (oTipoSelecao = 1) THEN
      /*****************************************************************************************
      #Retorno Dataset 1 (Topo) / DataSet 2 (Itens) / DataSet 3 (Lotes)
      #Registros a para confirmar contagem no SAP
      *****************************************************************************************/
      SELECT id, Reference, CountingDate, CONCAT(cod_emp,cod_fil, ano_solic, num_solic) AS NumDocSLIN, RESULTADO
      FROM tbintegraSAP_Contagem
      WHERE id > 0 AND dthr_retorno_integracao IS NULL
      GROUP BY NumDocSlin;
      SELECT CONCAT(cod_emp,cod_fil, ano_solic, num_solic) AS NumDocSLIN, num_item, ItemCode, WarehouseCode, BinCode, SUM(ContedQuantity) AS ContedQuantity
      FROM tbintegraSAP_Contagem
      WHERE id > 0 AND dthr_retorno_integracao IS NULL
      GROUP BY NumDocSlin, num_item;
      SELECT CONCAT(cod_emp,cod_fil, ano_solic, num_solic) AS NumDocSLIN, num_item,  
            BatchNumber_Code, BatchNumber_Quantity, CONCAT('UA',TRIM(LEADING '0' FROM cod_emp),'/',TRIM(LEADING '0' FROM cod_fil),'-',
                                                    TRIM(LEADING '0' FROM num_lote),'.', sequencia_lote) NumLoteSlin
      FROM tbintegraSAP_Contagem
      WHERE id > 0 AND dthr_retorno_integracao IS NULL;
   END IF;
    
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      SELECT RESULTADO, MENSAGEM;
   ELSE    
      SET RESULTADO = 1;
      #SET MENSAGEM  = 'Processo Realizado com sucesso!';
   END IF;
   
END$$

DELIMITER ;