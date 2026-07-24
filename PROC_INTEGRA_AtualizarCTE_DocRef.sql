DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_AtualizarCTE_DocRef`$$

CREATE PROCEDURE `PROC_INTEGRA_AtualizarCTE_DocRef`(
	IN oCodUsuario		VARCHAR(10),
   IN oidAddOn       INT,
   #IN oId            INT,
   IN oKeyNfeRef     VARCHAR(44),
   IN oCoduF         VARCHAR(02),
   IN oAnoMes        VARCHAR(04),
   IN oCNPJEmi       VARCHAR(14),
   IN oTipoDoc       VARCHAR(02),
   IN oSerieNFE      VARCHAR(04),
   IN oNumNFE        VARCHAR(09),
   IN oCodNFE        VARCHAR(09),
   IN oDV            VARCHAR(01),

	# Parametros de Retorno
	OUT RESULTADO         VARCHAR(5),
	OUT MENSAGEM          VARCHAR(500)
)
BLOCO1:BEGIN

   DECLARE oid_documento   INT DEFAULT 0;
	DECLARE excecao         INT DEFAULT 0;
	#DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;

   SET RESULTADO = "1";
   SET MENSAGEM = "Inclusão realizada com sucesso";
   
   SELECT id_documento INTO oid_documento FROM tbintegraSAP_CTe
   WHERE idAddOn = oidAddOn;


   IF NOT EXISTS (SELECT 1 FROM tbintegraSAP_CTeDocRef
                  WHERE id_documento = oid_documento
                  AND chave_doc_ref = oKeyNfeRef) THEN
      INSERT INTO tbintegraSAP_CTeDocRef (
         id_documento, chave_doc_ref, tipo_doc_ref, num_doc_ref, serie_doc_ref,
         valor_doc_ref, peso_doc_ref, data_doc_ref) VALUES (
         oid_documento, oKeyNfeRef, oTipoDoc, oNumNFE, oSerieNFE,
         NULL, NULL, NULL);
   ELSE
   BEGIN
      SET MENSAGEM = "Atualização realizada com sucesso";
      UPDATE tbintegraSAP_CTeDocRef
      SET  chave_doc_ref = oKeyNfeRef
          ,tipo_doc_ref  = tipo_doc_ref
          ,num_doc_ref   = num_doc_ref
          ,serie_doc_ref = serie_doc_ref
      WHERE id_documento = oid_documento AND chave_doc_ref = oKeyNfeRef;
   END;
   END IF;
   
   IF excecao = 1 THEN
      SET RESULTADO = "0";
      SET MENSAGEM = "Erro SQL - Verifique com o Administrador";
   END IF;
   
END$$

DELIMITER ;