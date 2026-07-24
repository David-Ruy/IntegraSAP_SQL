DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_UpdCancPV_Liberar`$$

CREATE PROCEDURE `PROC_INTEGRA_UpdCancPV_Liberar`(
  	 IN oCodUsuario	            VARCHAR(10)
   ,IN oTipoUpdCanc          VARCHAR(01)
   ,IN oDocumentType	        VARCHAR(10)
   ,IN oDocumentId	          INT
   ,IN oDocumentNumber	      VARCHAR(50)
   ,IN oUpdateDate           VARCHAR(30)
   ,IN oQtdeRegistros        INT
	   
   # Parametros de Retorno
   ,OUT RESULTADO            INT
   ,OUT MENSAGEM             VARCHAR(500)
)
BLOCO1:BEGIN
   /******************************************************************************
   @Author <David Ruy (OVERFLASH)>
   @Creation <2025-01-21>
   @Description <Esta rotina atualiza o STATUS da tabela tbintegraSAP_UpdCancPV para "0" a fim de que 
   #      o registro possa ser processado normalmente. Alteração feita para evitar o processamento de pedidos
   #      alterados ocm registros incompletos
   #@Reviser David Ruy <2025-02-17> Recebe os parametros oUpdateDate e oQtdeRegistros para checar e então
   #                                liberar o documento para atualização
   *******************************************************************************/
   
   DECLARE xQtdeAux INT DEFAULT 0;
   DECLARE excecao  INT DEFAULT 0;
   
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       SELECT MENSAGEM;
       ROLLBACK;
   END; 
   


   --    IF EXISTS (SELECT 1 
   --               FROM tbintegraSAP_UpdCancPV
   --               WHERE DocumentType = oDocumentType
   --                 AND DocumentId = oDocumentId
   --                 AND DocumentNumber = oDocumentNumber
   --                 AND TipoUpdCanc = oTipoUpdCanc
   --                 AND STATUS = -1) 
   --    THEN
   
   #Conta a Qtde de Registros inseridas X Qtde Documento (UPDPV)
   SELECT COUNT(*) INTO xQtdeAux 
   FROM tbintegraSAP_UpdCancPV
   WHERE DocumentType = oDocumentType
     AND DocumentId = oDocumentId
     AND DocumentNumber = oDocumentNumber
     AND TipoUpdCanc = oTipoUpdCanc
     AND UpdateDate = oUpdateDate
     AND STATUS = -1;


   #Confirma a Qtde de Registros para liberar a alteração do documento
   IF oQtdeRegistros = xQtdeAux THEN 
         
      UPDATE tbintegraSAP_UpdCancPV
      SET STATUS = 0
      WHERE DocumentType = oDocumentType
        AND DocumentId = oDocumentId
        AND DocumentNumber = oDocumentNumber
        AND TipoUpdCanc = oTipoUpdCanc
        AND UpdateDate = oUpdateDate
        AND STATUS = -1;
                          
     SET MENSAGEM = CONCAT(ROW_COUNT()," Registro(s) Atualizado(s) com sucesso ");
     SET RESULTADO = 1;

   ELSE
        SET RESULTADO = 0;
        SET MENSAGEM = CONCAT("NÃO Existem Registros a serem atualizados, Qtde Esperada = ",oQtdeRegistros,' Quantidade Identificada = ',xQtdeAux);
   END IF;
    
   COMMIT;

   
END$$

DELIMITER ;