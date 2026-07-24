DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_CancelarGSM`$$

CREATE PROCEDURE `PROC_INTEGRA_CancelarGSM`(
   IN oCodEmpWMS	    VARCHAR(03),
   IN oCodFilWMS		   VARCHAR(03),
   IN oAnoSolic 		   VARCHAR(04),
   IN oNumSolic 		   VARCHAR(30)
   # Parametros de Retorno
   #OUT RESULTADO    INT,
   #OUT MENSAGEM     VARCHAR(500)
)
BLOCO1:BEGIN
   #@Reviser David Ruy <2021/01/05>
   #Quando enviar oCodEmpWMS = 'X', então considerar DocumentType/DocumentNumber/DocumentId (EX:PV/160/433)
   #@Reviser David Ruy <2022-01-31> Listar o campo DocEntry_Substituto (U_RSD_RplOrder)
   #@Reviser David Ruy <2023-03-10> No select TMP_CancelarGSM, não trazer registros com item sem num_solic
   #@Reviser David Ruy <2023-07-14> Melhora no select e busca cancelamentos até 30 dias para trás
   #@Reviser David Ruy <2023-08-03> Desabilitando, permite cancelar PV´ ainda não integrados
   #@Reviser David Ruy <2024-07-16> Campo IdPicking para permitir atualizar PK de Pedidos Parciais (Leinertex)
   DECLARE RESULTADO        INT;
   DECLARE MENSAGEM         VARCHAR(500);
   DECLARE xDocumentId      INT;
   DECLARE xDocumentType    VARCHAR(10);
   DECLARE xDocumentNumber  INT;
   
   DECLARE xQtdeRegs        INT DEFAULT 0;
   DECLARE excecao 	        INT DEFAULT 0;
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       ROLLBACK;
   END;
   
   START TRANSACTION;
   
  IF IFNULL(oCodEmpWMS,'') = '' THEN
     #Cancelamentos Pendentes originadas no SAP-B1
      DROP TEMPORARY TABLE IF EXISTS TMP_CancelarGSM;
      CREATE TEMPORARY TABLE TMP_CancelarGSM ( 
         SELECT tbUpdCancPV.DocumentId, tbUpdCancPV.DocumentType, tbUpdCancPV.DocumentNumber,
                tbItem.cod_emp, tbItem.cod_fil, tbItem.ano_solic, tbItem.num_solic,
                COUNT(tbUpdCancPV.LineNumber) QtdeLinhasCancel,
                COUNT(tbItem.LineNum) QtdeItensPedido,
                tbPvSubstituto.DocEntry DocEntry_Substituto,
                tbPvSubstituto.DocNum   DocNum_Substituto,
                "Cancelar GSM" Observ,  tbTopo.idPicking,
                0 AS FlgProcessado
         FROM tbintegraSAP_UpdCancPV tbUpdCancPV
         INNER JOIN tbintegraSAP_DocItem tbItem ON 
                    tbItem.DocEntry = tbUpdCancPV.DocumentId
                AND tbItem.DocTipo  = tbUpdCancPV.DocumentType 
                AND tbItem.DocNum   = tbUpdCancPV.DocumentNumber 
         INNER JOIN tbintegraSAP_Doc tbTopo ON 
                    tbTopo.DocEntry = tbUpdCancPV.DocumentId
                AND tbTopo.DocTipo  = tbUpdCancPV.DocumentType 
                AND tbTopo.DocNum   = tbUpdCancPV.DocumentNumber 
         LEFT JOIN tbintegraSAP_Doc tbPvSubstituto ON 
                    tbPvSubstituto.DocTipo = 'PV'
                AND tbPvSubstituto.U_RSD_RplOrder = tbUpdCancPV.DocumentId
                AND tbPvSubstituto.DocTipo        = tbUpdCancPV.DocumentType 
                AND tbPvSubstituto.dthr_inc >= DATE_ADD(CURRENT_DATE(), INTERVAL -30 DAY)
         WHERE tbUpdCancPV.dthr_inc >= DATE_ADD(CURRENT_DATE(), INTERVAL -30 DAY)
           AND tbUpdCancPV.cod_emp IS NULL
           AND tbUpdCancPV.TipoUpdCanc = 'C'
           AND tbUpdCancPV.STATUS = 0
           #Alterado em 20230803 : Desabilitando, permite cancelar PV´ ainda não integrados
           #AND tbItem.cod_emp IS NOT NULL
         GROUP BY tbUpdCancPV.DocumentId, tbUpdCancPV.DocumentType, tbUpdCancPV.DocumentNumber
         #Já vem do SAP TODOS os itens do pedido cancelado
         #having QtdeLinhasCancel = QtdeItensPedido
      );  
      
      SELECT * FROM TMP_CancelarGSM;
      
  ELSE
  
      #Prepara as variáveis para busca pelo Documento da Integracao
      IF oCodEmpWMS = 'X' THEN
      
         SET xDocumentType   = SUBSTRING(oNumSolic, 01, LOCATE('/',oNumSolic)-1);
         SET oNumSolic       = REPLACE(oNumSolic, CONCAT(xDocumentType,'/'), '');
         SET xDocumentNumber = SUBSTRING(oNumSolic, 01, LOCATE('/',oNumSolic)-1);
         SET oNumSolic       = REPLACE(oNumSolic, CONCAT(xDocumentNumber,'/'), '');
         SET xDocumentId     = oNumSolic;
         
         SET oCodEmpWMS = "000";
         SET oCodFilWMS = "000";
         SET oAnoSolic  = "0000";
         SET oNumSolic  = "0000000000";
         
      ELSE
      
         #Prepara as variáveis para busca pelo Documento do SLIN
         SELECT tbUpdCancPV.DocumentId, tbUpdCancPV.DocumentType, tbUpdCancPV.DocumentNumber
         INTO xDocumentId, xDocumentType, xDocumentNumber
         FROM tbintegraSAP_UpdCancPV tbUpdCancPV
         INNER JOIN tbintegraSAP_DocItem tbItem ON 
                    tbItem.DocEntry = tbUpdCancPV.DocumentId
                AND tbItem.DocTipo  = tbUpdCancPV.DocumentType 
                AND tbItem.DocNum   = tbUpdCancPV.DocumentNumber 
         WHERE tbItem.cod_emp   = oCodEmpWMS
           AND tbItem.cod_fil   = oCodFilWMS
           AND tbItem.ano_solic = oAnoSolic
           AND tbItem.num_solic = oNumSolic
           AND tbUpdCancPV.TipoUpdCanc = 'C'
         LIMIT 1;
      END IF;
  
  
      #Atualiza Integração de que a GSM foi cancelada
      UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV
      SET tbUpdCancPV.cod_emp   = oCodEmpWMS,
          tbUpdCancPV.cod_fil   = oCodFilWMS,
          tbUpdCancPV.ano_solic = oAnoSolic,
          tbUpdCancPV.num_solic = oNumSolic
      WHERE tbUpdCancPV.DocumentId     = xDocumentId
        AND tbUpdCancPV.DocumentType   = xDocumentType
        AND tbUpdCancPV.DocumentNumber = xDocumentNumber;
        
      UPDATE tbintegraSAP_Doc
      SET StatusAnt = StatusDoc,
          StatusDoc = 9
      WHERE tbintegraSAP_Doc.DocEntry = xDocumentId
        AND tbintegraSAP_Doc.DocTipo  = xDocumentType
        AND tbintegraSAP_Doc.DocNum   = xDocumentNumber;
      
   END IF;
   
   DROP TEMPORARY TABLE IF EXISTS TMP_CancelarGSM;    
   
   IF excecao = 1 THEN
      ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,"ERRO "),"- PROC_INTEGRA_CancelarGSM");
   ELSE
      COMMIT;
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,"OK "),"- PROC_INTEGRA_CancelarGSM");
   END IF;
   SELECT RESULTADO, MENSAGEM;
   
   
END$$

DELIMITER ;