DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_CAD_ClienteFornecedor`$$

CREATE PROCEDURE `PROC_INTEGRA_CAD_ClienteFornecedor`(
	IN oCodUsuario				  VARCHAR(10),
	IN oCnpjCpf					    VARCHAR(14),
	IN oTipoPessoa				  VARCHAR(01),
	IN oTipoCliFor				  VARCHAR(01),
	IN oRazSocial				   VARCHAR(100),
	IN oNomeFantasia			 VARCHAR(100),
	IN oInscrEstadual			VARCHAR(20),
	IN oIndicadorIE			  VARCHAR(1),	
	IN oEndereco				    VARCHAR(50),
	IN oNumEnde					    VARCHAR(10),
	IN oComplEnde				   VARCHAR(20),
	IN oBairroEnde				  VARCHAR(50),
	IN oCidadeEnde				  VARCHAR(50),
	IN oUFEnde					     VARCHAR(02),
	IN oCepEnde					    VARCHAR(08),
	IN oContato01				   VARCHAR(20),
	IN oFone01 					    VARCHAR(20),
	IN oEmail01 				    VARCHAR(40),
	IN oContato02 				  VARCHAR(20),
	IN oFone02 					    VARCHAR(20),
	IN oEmail02 				    VARCHAR(40),
	IN oContato03 				  VARCHAR(20),
	IN oFone03 					    VARCHAR(20),
	IN oEmail03 				    VARCHAR(40),
	IN oEmail_fiscal 			VARCHAR(500),
	IN oStatusAtivo				 VARCHAR(01),
	
	# Parametros de Retorno
	OUT RESULTADO       VARCHAR(5),
	OUT MENSAGEM        VARCHAR(500)
)
BLOCO1:BEGIN
	DECLARE xIncAlt VARCHAR(01)	DEFAULT 'I';
	DECLARE excecao INT DEFAULT 0;
	-- DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
	
	IF EXISTS (SELECT cnpj_cpf FROM of_logistica.tbclientes
			   WHERE cnpj_cpf    = oCNPJCPF) THEN
		SET xIncAlt = 'A';
	END IF;
	
	#Tratar as variáveis
	
	/*******************************************************************
	#Tratar e Validar as variáveis
	*******************************************************************/
     SET MENSAGEM = '';
     SET oIndicadorIE = TRIM(IFNULL(oIndicadorIE, ''));
     IF TRIM(IFNULL(oCnpjCpf,'')) = '' THEN
        SET MENSAGEM = "CNPJ/CPF Inválido";
     ELSEIF TRIM(IFNULL(oTipoPessoa,'')) NOT IN ('F','J','O') THEN
        SET MENSAGEM = "Tipo Pessoa Inválido";
     ELSEIF TRIM(IFNULL(oRazSocial,'')) = '' THEN
        SET MENSAGEM = "Razão Social Inválida";
     ELSEIF oIndicadorIE = "" OR (oIndicadorIE NOT IN ('1','2','9')) THEN
        SET MENSAGEM = "Indicador de Inscrição Estadual inválido";
     ELSEIF oIndicadorIE <> '9' AND (TRIM(IFNULL(oInscrEstadual,'')) = '') THEN
           SET MENSAGEM = "Inscrição Estadual inválida";
     ELSEIF TRIM(IFNULL(oEndereco,'')) = '' THEN
        SET MENSAGEM = "Endereço Inválido";
     ELSEIF TRIM(IFNULL(oNumEnde,'')) = '' THEN
        SET MENSAGEM = "N° (Endereço) Inválido";
     ELSEIF TRIM(IFNULL(oBairroEnde,'')) = '' THEN
        SET MENSAGEM = "Bairro Inválido";
     ELSEIF TRIM(IFNULL(oCidadeEnde,'')) = '' THEN
        SET MENSAGEM = "Cidade Inválido";
     ELSEIF TRIM(IFNULL(oUFEnde,'')) = '' THEN
        SET MENSAGEM = "UF Inválido";
     ELSEIF (TRIM(IFNULL(oCepEnde,'')) = '') OR (fnSoNumeros(oCepEnde,"") <> oCepEnde) OR (NOT LENGTH(TRIM(oCepEnde)) = 8) THEN
        SET MENSAGEM = "CEP Inválido";
     END IF;    
     IF mensagem <> '' THEN
        SET RESULTADO = 'FALSE';
        LEAVE BLOCO1;
     END IF;
	IF xIncAlt = 'I' THEN
		#Insere tbClientes
		INSERT INTO of_logistica.tbclientes
			(cnpj_cpf, tipo_pessoa, tipo_cli_for, raz_social, nome_fantasia, inscr_estadual, idIEDest,
				endereco, num_ende, compl_ende, bairro, nome_cidade, sig_estado, num_cep,
				contato01, fone01, email01,
				contato02, fone02, email02, 
				contato03, fone03, email03, 
				email_fiscal, flg_ativo,
				dthr_inc, usu_inc) 
		VALUES (oCnpjCpf
				,oTipoPessoa
				,oTipoCliFor
				,SUBSTRING(oRazSocial,60)
				,SUBSTRING(oNomeFantasia,40)
				,oInscrEstadual
				,oIndicadorIE
				,oEndereco
				,oNumEnde
				,oComplEnde
				,oBairroEnde
				,oCidadeEnde
				,oUFEnde
				,oCepEnde
				,oContato01
				,oFone01 
				,oEmail01 
				,oContato02 
				,oFone02 
				,oEmail02 
				,oContato03 
				,oFone03 
				,oEmail03 
				,oEmail_fiscal 
				,oStatusAtivo
				,NOW()
				,oCodUsuario);		
			SET RESULTADO = 'TRUE';
			SET MENSAGEM = "Registro Inserido com sucesso";
	ELSE
		UPDATE of_logistica.tbclientes SET
			 tipo_pessoa	=	oTipoPessoa
			,tipo_cli_for	=	oTipoCliFor
			,raz_social		=	SUBSTRING(oRazSocial,60)
			,nome_fantasia	=	SUBSTRING(oNomeFantasia,40)
			,inscr_estadual	=	oInscrEstadual
			,idIEDest = oIndicadorIE
			,endereco		=	oEndereco
			,num_ende		=	oNumEnde
			,compl_ende		=	oComplEnde
			,bairro			=	oBairroEnde
			,nome_cidade	=	oCidadeEnde
			,sig_estado		=	oUFEnde
			,num_cep		=	oCepEnde
			,contato01		=	oContato01
			,fone01			=	oFone01 
			,email01		=	oEmail01 
			,contato02		=	oContato02 
			,fone02			=	oFone02 
			,email02		=	oEmail02 
			,contato03		=	oContato03 
			,fone03			=	oFone03 
			,email03		=	oEmail03 
			,email_fiscal	=	oEmail_fiscal 
			,flg_ativo		=	oStatusAtivo
			,dthr_alt 		= NOW()
			,usu_alt 		= oCodUsuario
			WHERE cnpj_cpf 	= oCnpjCpf;
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