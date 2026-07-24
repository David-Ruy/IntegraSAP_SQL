DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_AtualizarCTE`$$

CREATE PROCEDURE `PROC_INTEGRA_AtualizarCTE`(
	IN oCodUsuario				    VARCHAR(10),
   IN oId INT, 
   IN oDocTypeId        VARCHAR(10), 
   IN oDocEntry         VARCHAR(20),
   IN oDocNum           VARCHAR(20),
   IN oSerial           VARCHAR(20),
   IN oKeyNfe           VARCHAR(44),
   IN oNumNFE           VARCHAR(20),
   IN oSerieNFE         VARCHAR(20),
   IN oDateReceived     VARCHAR(20),
   IN oCardCode         VARCHAR(20),
   IN oCardName         VARCHAR(100),
   IN oCNPJEmi          VARCHAR(14),
   IN oIbgeCodeMuniIni  VARCHAR(20), 
   IN oIbgeCodeMuniFim  VARCHAR(20), 
   IN oDocTotal         VARCHAR(20), 
   IN oComments         TEXT, 

	# Parametros de Retorno
	OUT RESULTADO         VARCHAR(5),
	OUT MENSAGEM          VARCHAR(500)
)
BLOCO1:BEGIN
   /*
   @Reviser : David Ruy <2022/10/22> Cancelamento
   */

	DECLARE excecao      INT DEFAULT 0;
	#DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;

   SET RESULTADO = "1";
   SET MENSAGEM = "Inclusão realizada com sucesso";

   IF (oDocTotal="-1.0") THEN
      SET MENSAGEM = "Cancelamento realizado com sucesso";
      UPDATE tbintegraSAP_CTe
      SET dthr_cancel = IFNULL(dthr_cancel,NOW())
      WHERE num_chave = oKeyNfe;
   ELSE
      IF NOT EXISTS (SELECT 1 FROM tbintegraSAP_CTe
                     WHERE num_chave = oKeyNfe) THEN   
         INSERT INTO tbintegraSAP_CTe (idAddOn, DocTypeId, DocEntry, DocNum, SERIAL,
            num_chave, num_documento, serie_documento, data_documento, CardCode, CardName, emi_id, emi_cnpj, 
            #emi_raz_social, emi_endereco, emi_cidade, emi_bairro, emi_CEP, emi_UF, 
            #orig_id, orig_cnpj, ,orig_raz_social, orig_endereco, orig_cidade, orig_bairro, orig_CEP, orig_UF, 
            IbgeCodeMuniIni,
            #dest_id, dest_cnpj, dest_raz_social, dest_endereco, dest_cidade, dest_bairro, dest_CEP, dest_UF, 
            IbgeCodeMuniFim,
            valor_total, Comments, dthr_inc, usu_inc) VALUES (
               oId, oDocTypeId, oDocEntry, oDocNum, oSerial,
               oKeyNfe, oNumNFE, oSerieNFE, oDateReceived, oCardCode, oCardName, 0, oCNPJEmi,
               oIbgeCodeMuniIni, 
               oIbgeCodeMuniFim,
               oDocTotal, oComments, NOW(), oCodUsuario);
            SELECT CONCAT("OK",LAST_INSERT_ID()) INTO MENSAGEM;
      ELSE
      BEGIN
         SET MENSAGEM = "Atualização realizada com sucesso";
         UPDATE tbintegraSAP_CTe 
         SET idAddOn          = oId, 
             DocTypeId        = oDocTypeId, 
             DocEntry         = oDocEntry, 
             DocNum           = oDocNum, 
             SERIAL           = oSerial,  
             num_chave        = oKeyNfe, 
             num_documento    = oNumNFE, 
             serie_documento  = oSerieNFE,
             data_documento   = oDateReceived,
             CardCode         = oCardCode,
             CardName         = oCardName,
             emi_id           = 0, 
             emi_cnpj         = oCNPJEmi,
             IbgeCodeMuniIni  = oIbgeCodeMuniIni, 
             IbgeCodeMuniFim  = oIbgeCodeMuniFim,
             valor_total      = oDocTotal, 
             Comments         = oComments,  
             dthr_alt         = NOW(),
             usu_alt          = oCodUsuario
         WHERE num_chave = oKeyNfe;
         
         SELECT CONCAT("OK",id_documento) INTO MENSAGEM 
         FROM tbintegraSAP_CTe 
         WHERE num_chave = oKeyNfe;
         
      END;
      END IF;
   END IF;
   
   IF excecao = 1 THEN
      SET RESULTADO = "0";
      SET MENSAGEM = "Erro SQL - Verifique com o Administrador";
   END IF;
   
END$$

DELIMITER ;