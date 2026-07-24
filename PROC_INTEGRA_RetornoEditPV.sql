DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_RetornoEditPV`$$

CREATE PROCEDURE `PROC_INTEGRA_RetornoEditPV`(
   # Parametros de Retorno
   #OUT RESULTADO             	INT,
   #OUT MENSAGEM              	VARCHAR(500)
)
BLOCO1:BEGIN
   /***************************************************************************
   #@Reviser David Ruy <2021/07/11>
   #Busca informações de GSM´ que liberou alteração de PV no SAP
   #EditPV => 1:Não / 2:SIM
   ****************************************************************************/
   DECLARE RESULTADO          INT;
   DECLARE MENSAGEM           VARCHAR(500);
   DECLARE excecao 	          INT DEFAULT 0;
      
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    
    GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
  
    ROLLBACK;
    SET RESULTADO = 0;
    SET MENSAGEM  = MENSAGEM;
  END;
   
   
   SELECT tbintegraSAP_Doc.DocTipo, tbintegraSAP_Doc.DocEntry, tbintegraSAP_Doc.DocNum, 
          "2" EditPV, 1 AS resultado, tbSaidas.chave_integracao AS mensagem
   FROM tbintegraSAP_Doc
   INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
         tbSaidas.cod_emp   = tbintegraSAP_Doc.cod_emp
     AND tbSaidas.cod_fil   = tbintegraSAP_Doc.cod_fil
     AND tbSaidas.ano_solic = tbintegraSAP_Doc.ano_solic
     AND tbSaidas.num_solic = tbintegraSAP_Doc.num_solic
     AND tbSaidas.status_processo >= 4
     AND tbintegraSAP_Doc.StatusDoc = 3
   INNER JOIN of_logistica.tbwms_tipo_oper tbOperacoesWMS ON 
         tbOperacoesWMS.cod_oper_wms = tbSaidas.flg_tipo_oper
   WHERE tbintegraSAP_Doc.TipoDocSLIN = 'S'
     AND tbintegraSAP_Doc.DocTipo     = 'PV'
     AND tbSaidas.dthr_bloqueio_ini IS NOT NULL
     AND tbSaidas.dthr_bloqueio_fin IS NULL
     AND tbSaidas.dthr_retorno_integracao IS NULL;
   
    
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