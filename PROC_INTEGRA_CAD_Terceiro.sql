DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_CAD_Terceiro`$$

CREATE PROCEDURE `PROC_INTEGRA_CAD_Terceiro`(
   IN oCodUsuario				   VARCHAR(10),
   IN oCnpjCpfCli				   VARCHAR(14),
   IN oCnpjCpfTerc			   VARCHAR(14),
   IN oTipoTerceiro			  INT, #0=Fornecedor / 1=Transportador
   IN oRazSocial				    VARCHAR(100),
   IN oNomeFantasia			  VARCHAR(100),
   IN oStatusAtivo			   INT,
   # Parametros de Retorno
   OUT RESULTADO        INT,
   OUT MENSAGEM         VARCHAR(500)
)
BLOCO1:BEGIN
   DECLARE xIncAlt      VARCHAR(01)	DEFAULT 'I';
   DECLARE excecao      INT DEFAULT 0;
   -- DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   IF EXISTS (SELECT cnpj_cpf_cliente FROM of_logistica.tbwms_terceiro
              WHERE cnpj_cpf_cliente  = oCnpjCpfCli
                AND cnpj_cpf_terceiro = oCnpjCpfTerc) THEN
      SET xIncAlt = 'A';
   END IF;
   #Tratar as variáveis
   /*******************************************************************
   #Tratar e Validar as variáveis
   *******************************************************************/
   SET MENSAGEM = '';
   IF TRIM(IFNULL(oCnpjCpfCli,'')) = '' THEN
      SET MENSAGEM = "CNPJ/CPF Cliente Inválido";
   ELSEIF TRIM(IFNULL(oCnpjCpfTerc,'')) = '' THEN
      SET MENSAGEM = "CNPJ/CPF TERCEIRO Inválido";
   ELSEIF TRIM(IFNULL(oTipoTerceiro,'')) NOT IN (0,1) THEN
      SET MENSAGEM = "Tipo Terceiro Inválido";
   ELSEIF TRIM(IFNULL(oRazSocial,'')) = '' THEN
      SET MENSAGEM = "Razão Social Inválida";
   END IF;    
   IF mensagem <> '' THEN
      SET RESULTADO = 0;
      LEAVE BLOCO1;
   END IF;
   IF xIncAlt = 'I' THEN
      #Insere tbClientes
      INSERT INTO of_logistica.tbwms_terceiro (cnpj_cpf_cliente, cnpj_cpf_terceiro, raz_social, nome_fantasia, tipo, flg_ativo, senha, dthr_inc, usu_inc)
      VALUES (oCnpjCpfCli, oCnpjCpfTerc, SUBSTRING(oRazSocial,1,50), SUBSTRING(oNomeFantasia,1,50), oTipoTerceiro, oStatusAtivo, '123', NOW(), '999999');
      SET RESULTADO = 1;
      SET MENSAGEM = "Registro Inserido com sucesso";
   ELSE
      UPDATE of_logistica.tbwms_terceiro SET
             cnpj_cpf_cliente    = oCnpjCpfCli
             ,cnpj_cpf_terceiro  = oCnpjCpfTerc
             ,raz_social         = SUBSTRING(oRazSocial,1,50)
             ,nome_fantasia      = SUBSTRING(oNomeFantasia,1,50)
             ,tipo               = oTipoTerceiro
             ,flg_ativo          = oStatusAtivo
             ,senha              = '123'
             ,dthr_inc           = NOW()
             ,usu_inc            = '999999'
      WHERE cnpj_cpf_cliente  = oCnpjCpfCli
        AND cnpj_cpf_terceiro = oCnpjCpfTerc;
          
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