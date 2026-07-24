DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_AtualizarStatusDocEntry`$$

CREATE PROCEDURE `PROC_INTEGRA_AtualizarStatusDocEntry`(
	IN oCodUsuario				VARCHAR(10),
	IN oDocEntry      INT,
	IN oDocTipo       VARCHAR(10),
	IN oDocNum        INT,
	IN oNewStatus     INT,
	
	# Parametros de Retorno
	OUT RESULTADO     VARCHAR(5),
	OUT MENSAGEM      VARCHAR(500)
)
BLOCO1:BEGIN
	/*****************************************************************************************/
	#@Author : David Ruy
    #@Reviser <20230324> David Ruy : Ajuste para não retroceder status de 3 para 1 => IF(StatusDoc=3 AND oNewStatus = 1, 3, oNewStatus)
    #@Reviser <20230325> David Ruy : TD-S Grava StatusEnum = 0 (para gerar o Recebimento)
	#@Reviser David Ruy <2024-05-15> : Checar Status ANTES de atualizar para não chamar 
	#    PROC_INTEGRA_AtualizarStatusSLIN quando o documento não tiver sido integrado no WMS, 
	/*****************************************************************************************/

   
   DECLARE xIncAlt   VARCHAR(01)	DEFAULT 'I';
   DECLARE excecao   INT DEFAULT 0;
   DECLARE xStatusDoc VARCHAR(10);	
   
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   START TRANSACTION;
   
   SET RESULTADO = "1";
   SET MENSAGEM = "Atualização realizada com sucesso";
   IF NOT EXISTS (SELECT 1 FROM tbintegraSAP_Doc
			   WHERE DocEntry = oDocEntry
			     AND DocTipo  = oDocTipo
			     AND DocNum   = oDocNum) THEN
        SET xIncAlt = 'X';
   ELSE
        SET xIncAlt = 'A';
   END IF;
	
   IF xIncAlt = 'X' THEN	
      SET RESULTADO = "0";
      SET MENSAGEM  = "DocEntry / DocTipo não localizado - Atualização Impossível";
   ELSE
   
      SELECT StatusDoc INTO xStatusDoc FROM tbintegraSAP_Doc
      WHERE DocEntry = oDocEntry
        AND DocTipo  = oDocTipo
        AND DocNum   = oDocNum;
       
   
      UPDATE tbintegraSAP_Doc
      SET  StatusAnt = StatusDoc
          ,StatusDoc = IF(StatusDoc=3 AND oNewStatus = 1, 3, oNewStatus)
          ,usu_alt   = oCodUsuario
          ,dthr_alt  = NOW()
      WHERE DocEntry = oDocEntry
        AND DocTipo  = oDocTipo
        AND DocNum   = oDocNum;
        
      IF oDocTipo = 'TD-S' AND oNewStatus = 6 THEN
         # No primeiro envio Seta "0" para gerar a Devolução, no segundo Seta "1" = Gerado
         UPDATE tbintegraSAP_Doc
         SET  StatusEnum = IF(StatusEnum IS NULL, 0, 1)
         WHERE DocEntry = oDocEntry
           AND DocTipo  = oDocTipo
           AND DocNum   = oDocNum;
       END IF;
      
      IF ROW_COUNT() > 0 AND (xStatusDoc > 1) THEN  
         CALL PROC_INTEGRA_AtualizarStatusSLIN(oCodUsuario, oDocEntry, oDocTipo, oDocNum, oNewStatus, RESULTADO, MENSAGEM);
         
         IF RESULTADO = 0 THEN 
            IF EXISTS (SELECT 1 FROM tbintegraSAP_Doc
                       WHERE DocEntry = oDocEntry
                         AND DocTipo  = oDocTipo
                         AND DocNum   = oDocNum
                         AND num_solic IS NOT NULL) THEN       
               SET excecao = 1;
            ELSE
               SET excecao = 0;
               SET MENSAGEM = "Atualização realizada com sucesso";
            END IF;            
         END IF;
      END IF;
   END IF;
    
   IF excecao = 1 THEN
      ROLLBACK;
      IF RESULTADO = 1 THEN
         -- Ero da propria rotina, caso contrário, retorna erro da rotina PROC_INTEGRA_AtualizarStatusSLIN
         SET MENSAGEM = "Erro SQL (PROC_INTEGRA_AtualizarStatusDocEntry) - Verifique com o Administrador";
      END IF;
      SET RESULTADO = "0";
   ELSE
      COMMIT;
   END IF;
END$$

DELIMITER ;