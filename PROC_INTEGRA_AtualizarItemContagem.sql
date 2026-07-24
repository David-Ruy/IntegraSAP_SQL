DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_AtualizarItemContagem`$$

CREATE PROCEDURE `PROC_INTEGRA_AtualizarItemContagem`(
	IN oCodUsuario				   VARCHAR(10),
	IN oDocEntry         INT,
	IN oCodProduto       VARCHAR(30),
	IN oLineNum          INT,
	
	# Parametros de Retorno
	OUT RESULTADO        VARCHAR(5),
	OUT MENSAGEM         VARCHAR(500)
)
BLOCO1:BEGIN
   DECLARE xIncAlt    VARCHAR(01)	DEFAULT 'I';
   DECLARE xCodEmp    VARCHAR(03);
   DECLARE xCodFil    VARCHAR(03);
   DECLARE xAnoSolic  VARCHAR(04);
   DECLARE xNumSolic  VARCHAR(10);
      
   DECLARE excecao    INT DEFAULT 0;
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   #Atualizar LineNum Contagem (Base ID + ItemCode
   UPDATE tbintegraSAP_Contagem tbCont
   SET tbCont.LineNum = oLineNum
   WHERE tbCont.Id       = oDocEntry
     AND tbCont.ItemCode = oCodProduto;
  
   IF excecao = 1 THEN
      SET RESULTADO = "0";
      SET MENSAGEM = "Erro SQL (PROC_INTEGRA_AtualizarItemContagem) - Verifique com o Administrador";
      #rollback;
   ELSE
      SET RESULTADO = "1";
      SET MENSAGEM = "Atualização realizada - Status não relevante";   
      #commit;
   END IF;
END$$

DELIMITER ;