DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_LiberarStatusUAs`$$

CREATE PROCEDURE `PROC_INTEGRA_LiberarStatusUAs`(
   oCodUsuario    VARCHAR(30),
   oDocTipo            VARCHAR(30),
   oDocEntry           VARCHAR(30),
   oDocNum             VARCHAR(30),
   # Parametros de Retorno
   OUT RESULTADO              INT,
   OUT MENSAGEM               VARCHAR(500)
)
BLOCO1:BEGIN
  /************************************************************************/
  # @Created David Ruy <2026/03/26>
  # Esta procedure atualiza as UA´s de uma GEM (Ordem de Produção) com status para Liberar conforme necessário
  # @Reviser David Ruy <2026-04-17> Desabilitado PROC_WMS_SAIDA_GERAR_ACONSELHAMENTO_TOTAL, foi alterado 
  #                                 para chamar de outra procedure
  /************************************************************************/
   DECLARE excecao 	INT(6) DEFAULT 0;
   DECLARE _RESULTADO INT DEFAULT 0;
   DECLARE _MENSAGEM  VARCHAR(500);
   DECLARE xCodEmp        VARCHAR(03);
   DECLARE xCodFil        VARCHAR(03);
   DECLARE xAnoSolic      VARCHAR(04);
   DECLARE xNumSolic      VARCHAR(10);
   DECLARE xNumItem       VARCHAR(06);
   DECLARE xItemCode      VARCHAR(30);
   
   DECLARE xDocTipo         VARCHAR(10);
   DECLARE xDocEntry        VARCHAR(30);
   DECLARE xDocNum          VARCHAR(30);
   DECLARE xChaveIntegracao VARCHAR(100);
   DECLARE xdthr_confirm    VARCHAR(20);
   DECLARE xCodigoStatus    VARCHAR(10);
   
   DECLARE xnum_lote        VARCHAR(10);
   DECLARE xsequencia_lote  TINYINT(03);
   DECLARE xCodEmpWMS       VARCHAR(03);
   DECLARE xCodFilWMS       VARCHAR(03);
   DECLARE xAnoSolicWMS     VARCHAR(04);
   DECLARE xNumSolicWMS     VARCHAR(10);   
   DECLARE xNumOrdemProducao  VARCHAR(10);   
   DECLARE xAny_OrdemProducao BOOLEAN  DEFAULT FALSE;
   
   #Verificar se tem transação nas procedures
   #Se tiver, lascou
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       IF xCodEmp IS NOT NULL THEN
          SET MENSAGEM  = of_logistica.fnMensagemExcecao(
             CONCAT('ERRO Atualização UA´s - GEM : ',CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',
             CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao," ",MENSAGEM) );
       ELSE
          SET MENSAGEM  = of_logistica.fnMensagemExcecao(
             CONCAT('ERRO Atualização UA´s : ',MENSAGEM) );
       END IF;
       SELECT MENSAGEM;
       ROLLBACK;
   END;  
   
   
   #Busca o Status "Próprio para Nomrla"
   #Isso serve para deixar "bloqueadas" as UA´s, até que o pedido com os lotes vinculados seja integrado
   SELECT cod_status INTO xCodigoStatus 
   FROM tbintegraSAP_DeParaStatus_Armazem
   WHERE descr_armazem = 'Normal';
   
   DROP TEMPORARY TABLE IF EXISTS tbTMPItems_OrdemProducao;
   #Se o oDocTipo = 'PV', buscar o documento de "PA000" com DocEntry_OrdemProducao
   IF oDocTipo = 'PV' THEN
   
      #Seleciona a CodEmp, CodFil, Anosolic, NumSolic da GSM do PV
      SELECT cod_emp, cod_fil, ano_solic, num_solic
      INTO xCodEmpWMS, xCodFilWMS, xAnoSolicWMS, xNumSolicWMS
      FROM tbintegraSAP_Doc
      WHERE DocTipo  = oDocTipo
        AND DocEntry = oDocEntry
        AND DocNum   = oDocNum;
   
      
      #Seleciona as linhas do PV que tenham Ordem de Produção Vinculadas   
      DROP TEMPORARY TABLE IF EXISTS tbTMPAux_OP;
      CREATE TEMPORARY TABLE tbTMPAux_OP 
         SELECT DocEntryOrdemProducao, DocNumOrdemProducao, SerialOrdemProducao
         FROM tbintegraSAP_DocItem
         WHERE DocTipo  = oDocTipo
           AND DocEntry = oDocEntry
           AND DocNum   = oDocNum
           AND DocEntryOrdemProducao IS NOT NULL;
           
      #Se tiver alguma linha, busca os documentos (cod_emp, cod_fil, ano_solic, num_solic) da entrada de PA
      #IF EXISTS (SELECT 1 FROM tbTMPAux_OP) THEN
         CREATE TEMPORARY TABLE tbTMPItems_OrdemProducao
            SELECT cod_emp, cod_fil, ano_solic, num_solic, DocEntryOrdemProducao, DocNumOrdemProducao, SerialOrdemProducao
            FROM tbintegraSAP_Doc
            INNER JOIN tbTMPAux_OP ON 
                       tbintegraSAP_Doc.DocTipo = 'PA000'
                   AND tbTMPAux_OP.DocEntryOrdemProducao = tbintegraSAP_Doc.DocEntry
                   AND tbTMPAux_OP.DocNumOrdemProducao   = tbintegraSAP_Doc.DocNum
            ;
      #END IF;
      DROP TEMPORARY TABLE IF EXISTS tbTMPAux_OP;
   END IF;
   
   
   IF oDocTipo = 'PA000' THEN
   
      #Buscar direto o documento da entrada (OP)
      CREATE TEMPORARY TABLE tbTMPItems_OrdemProducao
         SELECT tbintegraSAP_DocItem.cod_emp, tbintegraSAP_DocItem.cod_fil, tbintegraSAP_DocItem.ano_solic, tbintegraSAP_DocItem.num_solic, 
                tbintegraSAP_DocItem.DocEntryOrdemProducao, tbintegraSAP_DocItem.DocNumOrdemProducao, tbintegraSAP_DocItem.SerialOrdemProducao
         INTO xCodEmp, xCodFil, xAnoSolic, xNumSolic
         FROM tbintegraSAP_Doc
         INNER JOIN tbintegraSAP_DocItem ON 
                    tbintegraSAP_DocItem.DocTipo  = tbintegraSAP_Doc.DocTipo 
                AND tbintegraSAP_DocItem.DocEntry = tbintegraSAP_Doc.DocEntry
                AND tbintegraSAP_DocItem.DocNum   = tbintegraSAP_Doc.DocNum
         WHERE tbintegraSAP_DocItem.DocTipo  = oDocTipo
           AND tbintegraSAP_DocItem.DocEntry = oDocEntry
           AND tbintegraSAP_DocItem.DocNum   = oDocNum;
   
   END IF;
   
   #Debug
   #select * from tbTMPItems_OrdemProducao;
   #leave bloco1;
   
   #Leitura da Lista de PA´s para atualização dos status
   #Pode ter mais de uma OP ou seja, pode ter uma OP para cada linha do PV
   WHILE EXISTS (SELECT 1 FROM tbTMPItems_OrdemProducao) DO
   
      SELECT cod_emp, cod_fil, ano_solic, num_solic, DocNumOrdemProducao
      INTO xCodEmp, xCodFil, xAnoSolic, xNumSolic, xNumOrdemProducao
      FROM tbTMPItems_OrdemProducao
      LIMIT 1;
      
      #3) Lista UA´s referente OP vinculada ao PV
      #não pega UA empenhada, nem UA com o mesmo status_lote
      DROP TEMPORARY TABLE IF EXISTS tbTMP_UpdateStatusLotes;
      CREATE TEMPORARY TABLE tbTMP_UpdateStatusLotes
         SELECT cod_emp, cod_fil, num_lote, sequencia_lote, 0 AS Flag, status_lote
         FROM of_logistica.tbwms_estoque
         WHERE cod_emp    = xCodEmp
           AND cod_fil    = xCodFil
           AND ano_solic  = xAnoSolic
           AND num_solic  = xNumSolic
           AND sld_fisico_est > 0
           AND IFNULL(qtd_emp_est,0) = 0
           AND status_lote <> xCodigoStatus;
       
      #Debug    
      #select xCodigoStatus;
      #select * from tbTMP_UpdateStatusLotes;
      #leave bloco1;           
           
      WHILE EXISTS (SELECT 1 FROM tbTMP_UpdateStatusLotes WHERE Flag = 0 LIMIT 1) DO
         SELECT num_lote, sequencia_lote INTO xnum_lote, xsequencia_lote
         FROM tbTMP_UpdateStatusLotes WHERE Flag = 0 LIMIT 1;
         
         #Debug
         #select "Debug", xCodEmp, xCodFil, xnum_lote, xsequencia_lote, xCodigoStatus;
         #leave bloco1;
         
         
         
         #Executa alteração Status da UA
         CALL of_logistica.PROC_WMS_ARMAZEM_ALTERAR_STATUS_UA(xCodEmp, xCodFil, xnum_lote, xsequencia_lote,
              xCodigoStatus, CONCAT('Integração - Desbloqueio UA Reservada OP ',xNumOrdemProducao), '999999', NULL);
              
         UPDATE tbTMP_UpdateStatusLotes 
         SET Flag = 1
         WHERE num_lote = xnum_lote AND sequencia_lote = xsequencia_lote;
         
      END WHILE;
      
      DROP TEMPORARY TABLE IF EXISTS tbTMP_UpdateStatusLotes;
     
      DELETE FROM tbTMPItems_OrdemProducao
      WHERE cod_emp    = xCodEmp
        AND cod_fil    = xCodFil
        AND ano_solic  = xAnoSolic
        AND num_solic  = xNumSolic;
        
        
      SET xAny_OrdemProducao = TRUE;
            
   END WHILE;
   
   #Debug
   #select xAny_OrdemProducao, oDocTipo, xCodEmpWMS, xCodFilWMS, xAnoSolicWMS, xNumSolicWMS;
   #leave bloco1;
   
   IF excecao = 0 THEN
      COMMIT;
      SET RESULTADO = 1;
      IF MENSAGEM = "" THEN
         SET MENSAGEM = CONCAT('Atualização Status de UA´s Concluída com sucesso - GEM : ',CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao);
      ELSE
         SET MENSAGEM = CONCAT(MENSAGEM," | ",CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao);
      END IF;
   ELSE
      ROLLBACK;
      
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT('ERRO Atualização Status de UA´s - GEM : ',CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao);
      
      #Verificar Log
      #CALL PROC_INTEGRA_EnviarLog('999999',
      #       IF(oChavePedido IN ("PV","OP","TD-S","NS"), 'PROC_INTEGRA_GerarGSMItem', 'PROC_INTEGRA_GerarGEMItem'),
      #         CONCAT('NÃO Inserido/Atualizado ',oChavePedido,oDocEntry,'-',oNumPedido,' | ', xRefGuia, '| Prd:', xItemCode), "200", @M, @R, @M);      
   END IF;
   
      
      
   
END$$

DELIMITER ;