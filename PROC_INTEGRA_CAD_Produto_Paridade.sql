DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_CAD_Produto_Paridade`$$

CREATE PROCEDURE `PROC_INTEGRA_CAD_Produto_Paridade`(
	IN oCodUsuario				   VARCHAR(10),
	IN ocnpj_cpf_cli 			 VARCHAR(14),
	IN ocod_produto 			  VARCHAR(20),
	IN ocnpj_cpf_for 			 VARCHAR(14),
	IN ocod_produto_for		VARCHAR(20),
	IN odescr_produto 		 VARCHAR(50),
	# Parametros de Retorno
	OUT RESULTADO        VARCHAR(5),
	OUT MENSAGEM         VARCHAR(500)
)
BLOCO1:BEGIN
	DECLARE xIncAlt      VARCHAR(01)	DEFAULT 'I';
	DECLARE excecao      INT DEFAULT 0;
	-- DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
	
	IF EXISTS (SELECT 1 FROM of_logistica.tbprodutos_paridade
			   WHERE cnpj_cpf_for = ocnpj_cpf_for
			     AND cod_prod_for = ocod_produto_for
			     AND cnpj_cpf_cli = ocnpj_cpf_cli
			     AND cod_produto  = ocod_produto) THEN
		SET xIncAlt = 'A';
	END IF;
	
	#Tratar as variáveis
	
	/*******************************************************************
	#Tratar e Validar as variáveis
	*******************************************************************/
	IF xIncAlt = 'I' THEN
		#Insere tbprodutos
		INSERT INTO of_logistica.tbprodutos_paridade (
         cnpj_cpf_for   
			,cod_prod_for   
			,cnpj_cpf_cli
			,cod_produto    
			,descr_prod_for
			#,flg_barcode
		) VALUES (
          ocnpj_cpf_for
         ,ocod_produto_for
         ,ocnpj_cpf_cli
         ,ocod_produto
         ,odescr_produto
         #,'EAN'
		);
			SET RESULTADO = 'TRUE';
			SET MENSAGEM = "Registro Inserido com sucesso";
	ELSE
			SET RESULTADO = 'TRUE';
			SET MENSAGEM = "Registro Atualizado com sucesso";
	END IF;
	
	IF excecao = 1 THEN
		SET RESULTADO = 'FALSE';
		SET MENSAGEM = "Erro SQL - Verifique com o Administrador";
		#SELECT RESULTADO, MENSAGEM;
	END IF;
	
END$$

DELIMITER ;