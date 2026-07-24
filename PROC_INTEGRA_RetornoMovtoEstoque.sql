DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_RetornoMovtoEstoque`$$

CREATE PROCEDURE `PROC_INTEGRA_RetornoMovtoEstoque`(
)
BLOCO1:BEGIN
   /***************************************************************************
   #@Autho David Ruy <2019/12/11>
   # Movimentação de Estoque (bloqueio/desbloquio de UA´s, alteração de status)
   #2024-11-21 Desconsiderar movimentações com data superior a 30 dias da data atual   
   #2025-07-21 Inclusão campo tbfiliais.chave_integracao BPLId
   #2025-10-23 Desabilita movimentações onde o Depósito Origem = Depósito Destino   
   ****************************************************************************/
   
   
   DECLARE xCodEmpWMS			     VARCHAR(03)	DEFAULT '001';
   DECLARE xCodFilWMS			     VARCHAR(03) DEFAULT '001';
   DECLARE xNumSolic 			     VARCHAR(10);
   DECLARE xAnoSolic 			     VARCHAR(04)	DEFAULT YEAR(CURRENT_DATE());
   DECLARE xDocEntry         INT;
   DECLARE xDocTipo          VARCHAR(10);
   DECLARE xTipoOperSaida 		 VARCHAR(03) DEFAULT '001';
   DECLARE xCodUnidade			    VARCHAR(03) DEFAULT '001';
   DECLARE xCodArmazem			    VARCHAR(02) DEFAULT '01';
   DECLARE xStatusProcesso		 VARCHAR(02) DEFAULT '01';
   DECLARE xCodErro	         INT DEFAULT 0;
   DECLARE excecao 	         INT DEFAULT 0;
   DECLARE RESULTADO         INT DEFAULT 1;
   DECLARE MENSAGEM          VARCHAR(500);
   DECLARE xSTRGEM           TEXT;
   DECLARE xNumProcesso      VARCHAR(20);  
   DECLARE xQtdeDias         INT DEFAULT 30;
   
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
    
   #Cria tabela temporária com as GEM que estão liberadas para retorno à integração
   DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_MOVTOESTOQUE;
   
   CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_MOVTOESTOQUE AS 
      SELECT CONCAT("Movimentação SLIN - UA:",tbwmsManut.num_lote,tbwmsManut.sequencia_lote," ",IFNULL(tbwmsManut.observ,'')) AS Comments,       
             CURRENT_TIMESTAMP() AS TaxDate, 
             CONCAT(TRIM(LEADING '0' FROM tbwmsEstoque.cod_emp),'/',TRIM(LEADING '0' FROM tbwmsEstoque.cod_fil),'-',
                    TRIM(LEADING '0' FROM tbwmsEstoque.num_lote),'.',tbwmsEstoque.sequencia_lote) AS NumLoteSlin,
             tbwmsEstoque.num_lote_cli NumLoteFabr,
             tbwmsManut.dthr_inc DataMovimento,
             tbwmsManut.id_manutencao idMovimento,
             tbwmsManut.observacao Observacoes,
             tbwmsEstoque.cod_produto AS ItemCode,
             tbwmsManut.cod_status_ant StatusAnt,
             tbwmsManut.cod_status StatusAtu,
             IFNULL(tbIntegraOri.deposito_integracao, tbIntegraOri2.deposito_integracao) FromWareHouseCode,
             IFNULL(tbIntegraDest.deposito_integracao,tbIntegraDest2.deposito_integracao) ToWareHouseCode,
             tbwmsEstoque.sld_fisico_est Quantity,
             of_logistica.fnLocalizCompleta2(tbwmsEstoque.cod_und, tbwmsEstoque.cod_armazem, tbwmsEstoque.camara, tbwmsEstoque.rua, 
                              tbwmsEstoque.posicao, tbwmsEstoque.altura, tbwmsEstoque.profund, NULL, "SEM LOCAL") binCode,
             tbProd.flg_obriga_lote_fornecedor,
             NULL AS CardCode,
             NULL AS CardName,
             NULL AS Address,
             tbwmsEstoque.emb_est,
             1 AS QtdeEmbalagem,
             tbfiliais.chave_integracao BPLId
      FROM of_logistica.tbwms_manut_lote tbwmsManut
      INNER JOIN of_logistica.tbfiliais ON 
                 tbfiliais.cod_empresa = tbwmsManut.cod_emp
             AND tbfiliais.cod_filial  = tbwmsManut.cod_fil
      INNER JOIN of_logistica.tbwms_estoque tbwmsEstoque ON
                  tbwmsEstoque.cod_emp = tbwmsManut.cod_emp
              AND tbwmsEstoque.cod_fil = tbwmsManut.cod_fil
              AND tbwmsEstoque.num_lote = tbwmsManut.num_lote
              AND tbwmsEstoque.sequencia_lote = tbwmsManut.sequencia_lote
      LEFT JOIN of_logistica.tbprodutos tbProd ON
                  tbProd.cnpj_cpf    = tbwmsEstoque.cnpj_cpf_dep
              AND tbProd.cod_produto = tbwmsEstoque.cod_produto
      #LEFT JOIN tbintegraSAP_DeParaStatus_Armazem tbIntegraOri ON 
      #            tbIntegraOri.cod_status = tbwmsManut.cod_status_ant
      #LEFT JOIN tbintegraSAP_DeParaStatus_Armazem tbIntegraDest ON 
      #            tbIntegraDest.cod_status = tbwmsManut.cod_status
      LEFT JOIN of_logistica.tbstatus_lotes_integracao tbIntegraOri ON 
                tbIntegraOri.cod_emp    = tbwmsManut.cod_emp 
            AND tbIntegraOri.cod_fil    = tbwmsManut.cod_fil
            AND tbIntegraOri.codigo_status = tbwmsManut.cod_status_ant
      LEFT JOIN of_logistica.tbstatus_lotes tbIntegraOri2 ON 
                tbIntegraOri2.codigo = tbwmsManut.cod_status_ant
      LEFT JOIN of_logistica.tbstatus_lotes_integracao tbIntegraDest ON 
                tbIntegraDest.cod_emp    = tbwmsManut.cod_emp 
            AND tbIntegraDest.cod_fil    = tbwmsManut.cod_fil
            AND tbIntegraDest.codigo_status = tbwmsManut.cod_status
      LEFT JOIN of_logistica.tbstatus_lotes tbIntegraDest2 ON 
                tbIntegraDest2.codigo = tbwmsManut.cod_status
      WHERE tbwmsManut.cod_status_ant <> tbwmsManut.cod_status
        AND tbwmsManut.dthr_retorno_integracao IS NULL
        AND tbwmsManut.dthr_inc >= DATE_SUB(CURRENT_DATE, INTERVAL xQtdeDias DAY)
        ;
   
   #Desabilita movimentações onde o Depósito Origem = Depósito Destino
   UPDATE of_logistica.tbwms_manut_lote tbwmsManut
   INNER JOIN tbTMP_INTEGRA_RETORNO_MOVTOESTOQUE ON
              tbTMP_INTEGRA_RETORNO_MOVTOESTOQUE.idMovimento = tbwmsManut.id_manutencao              
   SET tbwmsManut.dthr_retorno_integracao = NOW(), 
       tbwmsManut.observ = CONCAT("IntegraSAP|Ori=",FromWareHouseCode,"/Dest=",ToWareHouseCode," Transf Não realizada")
   WHERE FromWareHouseCode = ToWareHouseCode;
       
   DELETE FROM tbTMP_INTEGRA_RETORNO_MOVTOESTOQUE
   WHERE FromWareHouseCode = ToWareHouseCode;
   
   SELECT * FROM tbTMP_INTEGRA_RETORNO_MOVTOESTOQUE;
   
   DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_MOVTOESTOQUE;
    
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