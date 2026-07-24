DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_CAD_Fornecedor`$$

CREATE PROCEDURE `PROC_INTEGRA_CAD_Fornecedor`(
   IN oCodUsuario				   VARCHAR(10),
   IN oCnpjCpfTerc			   VARCHAR(14),
   IN oRazSocial				    VARCHAR(100),
   IN oNomeFantasia			  VARCHAR(100),
   # Parametros de Retorno
   OUT RESULTADO        INT,
   OUT MENSAGEM         VARCHAR(500)
)
BLOCO1:BEGIN
   DECLARE xIncAlt      VARCHAR(01)	DEFAULT 'I';
   DECLARE excecao      INT DEFAULT 0;
   -- DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   IF EXISTS (SELECT cnpj_cpf FROM of_logistica.tbclientes
              WHERE cnpj_cpf = oCnpjCpfTerc) THEN
      SET xIncAlt = 'A';
   END IF;
   #Tratar as variáveis
   /*******************************************************************
   #Tratar e Validar as variáveis
   *******************************************************************/
   SET MENSAGEM = '';
   IF TRIM(IFNULL(oCnpjCpfTerc,'')) = '' THEN
      SET MENSAGEM = "CNPJ/CPF TERCEIRO Inválido";
   ELSEIF TRIM(IFNULL(oRazSocial,'')) = '' THEN
      SET MENSAGEM = "Razão Social Inválida";
   END IF;    
   IF mensagem <> '' THEN
      SET RESULTADO = 0;
      LEAVE BLOCO1;
   END IF;
   IF xIncAlt = 'I' THEN
      #Insere tbClientes
      INSERT INTO of_logistica.tbclientes (cnpj_cpf, raz_social, nome_fantasia, tipo_pessoa, tipo_cli_for, flg_ativo, dthr_inc, usu_inc)
      VALUES (oCnpjCpfTerc, SUBSTRING(oRazSocial,1,60), SUBSTRING(oNomeFantasia,1,60), 'J', 'F', 'S', NOW(), '999999');
      SET RESULTADO = 1;
      SET MENSAGEM = "Registro Inserido com sucesso";
   ELSE
      UPDATE of_logistica.tbclientes  SET
              cnpj_cpf       = oCnpjCpfTerc
             ,raz_social     = SUBSTRING(oRazSocial,1,60)
             ,nome_fantasia  = SUBSTRING(oRazSocial,1,60)
             ,tipo_pessoa    = 'J'
             ,tipo_cli_for   = 'F'
             ,flg_ativo      = 'S'
             ,dthr_alt       = NOW()
             ,usu_alt        = '999999'
      WHERE cnpj_cpf = oCnpjCpfTerc;
          
     SET RESULTADO = 1;
     SET MENSAGEM = "Registro Atualizado com sucesso";
     
   END IF;
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = "Erro SQL - Verifique com o Administrador";
      #SELECT RESULTADO, MENSAGEM;
   END IF;
END$$

DELIMITER ;