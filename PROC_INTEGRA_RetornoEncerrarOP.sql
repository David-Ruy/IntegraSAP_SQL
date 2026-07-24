DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_RetornoEncerrarOP`$$

CREATE PROCEDURE `PROC_INTEGRA_RetornoEncerrarOP`(
   IN oCodUsuario				VARCHAR(10),
   IN oNumero_OP     VARCHAR(10)
   # Parametros de Retorno
#   OUT RESULTADO             	INT,
#   OUT MENSAGEM              	VARCHAR(500)
)
BLOCO1:BEGIN
   /***************************************************************************
   #@Author David Ruy <2026/03/09>
   # Gera lista de Documentos para Retorno (Avalia se não existe MP E PA em aberto)
   #@Reviser David Ruy <2026/06/18>
   # Avalia se gerou Documentos de Saída MP e Entrada PA (DocEntryRef IS NOT NULL)
   ****************************************************************************/
   DECLARE xDtHrFech        VARCHAR(20);
   DECLARE xCodErro	        INT DEFAULT 0;
   DECLARE excecao 	        INT DEFAULT 0;
   DECLARE RESULTADO        INT DEFAULT 1;
   DECLARE MENSAGEM         VARCHAR(500);
   
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       SELECT RESULTADO, MENSAGEM;
       ROLLBACK;
   END;
   
   
   IF (oNumero_OP IS NULL OR oNumero_OP = 0) THEN
      #Cria tabela temporária com as GEM/GSM´s de OP´s que estão liberadas para encerramento de OP
      DROP TEMPORARY TABLE IF EXISTS tbTMP_OPs;
         
      CREATE TEMPORARY TABLE tbTMP_OPs
      SELECT DocEntry, DocNum FROM 
      (
          (SELECT DocEntry, DocNum FROM  tbintegraSAP_Doc tbIntegra_PA
          INNER JOIN of_logistica.tbsolic_entradas tbEntradas ON 
                     tbEntradas.chave_integracao = tbIntegra_PA.chave_integracao
          WHERE tbIntegra_PA.DocTipo LIKE ('PA%')
            AND tbEntradas.status_processo >= 8
            AND tbIntegra_PA.StatusDoc = 6
            AND tbEntradas.dthr_retorno_integracao IS NOT NULL 
            AND tbIntegra_PA.DocEntryRef IS NOT NULL     
            AND tbIntegra_PA.StatusAux_Cliente IS NULL)
      UNION
         (SELECT DocEntry, DocNum FROM tbintegraSAP_Doc tbIntegra_OP
          INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
                     tbSaidas.chave_integracao = tbIntegra_OP.chave_integracao
          WHERE tbIntegra_OP.DocTipo = 'OP'
            AND tbSaidas.status_processo >= 8
            AND tbIntegra_OP.StatusDoc = 6
            AND tbSaidas.dthr_retorno_integracao IS NOT NULL   
            AND tbIntegra_OP.DocEntryRef IS NOT NULL     
            AND tbIntegra_OP.StatusAux_Cliente IS NULL)
         ) Tabelas;
      
      
      #Apaga os Documentos que ainda tem GEM em andamento
      DELETE FROM tbTMP_OPs
      WHERE EXISTS (
            SELECT 1 FROM tbintegraSAP_Doc 
            WHERE tbintegraSAP_Doc.DocTipo LIKE 'PA%'
             AND tbintegraSAP_Doc.DocEntry = tbTMP_OPs.DocEntry       
             AND tbintegraSAP_Doc.StatusDoc <= 3);
      #Apaga os Documentos que ainda tem GSM em andamento
      DELETE FROM tbTMP_OPs
      WHERE EXISTS (
            SELECT 1 FROM tbintegraSAP_Doc 
            WHERE tbintegraSAP_Doc.DocTipo = 'OP'
             AND tbintegraSAP_Doc.DocEntry = tbTMP_OPs.DocEntry       
             AND tbintegraSAP_Doc.StatusDoc <= 3);
      
      SET RESULTADO = 1;
      SET MENSAGEM  = 'Listagem realizada com sucesso!';
      
      
      SELECT tbTMP_OPs.*, RESULTADO, MENSAGEM FROM tbTMP_OPs;
      DROP TEMPORARY TABLE IF EXISTS tbTMP_OPs;
 
   ELSE
   
      SET xDtHrFech = NOW();
   
      UPDATE tbintegraSAP_Doc
      SET StatusAux_Cliente = CONCAT("Fech OP =>",xDtHrFech)
      WHERE DocTipo LIKE 'PA%' AND DocEntry = oNumero_OP;
      UPDATE tbintegraSAP_Doc
      SET StatusAux_Cliente = CONCAT("Fech OP =>",xDtHrFech)
      WHERE DocTipo = 'OP' AND DocEntry = oNumero_OP;
      
      IF ROW_COUNT() > 0 THEN
         SET RESULTADO = 1;
         SET MENSAGEM  = 'Atualização Realizada com sucesso!';
      ELSE
         SET RESULTADO = 0;
         SET MENSAGEM  = 'Documento NÃO Localizado !';
      END IF;
      SELECT RESULTADO, MENSAGEM;
   
   END IF;
   
   IF excecao = 1 THEN
      ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      SELECT RESULTADO, MENSAGEM;
   ELSE    
      SET RESULTADO = 1;
      #SET MENSAGEM  = 'Processo Realizado com sucesso!';
   END IF;
   
END$$

DELIMITER ;