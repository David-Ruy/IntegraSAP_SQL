DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_CAD_Produto_Paridade_Emb`$$

CREATE PROCEDURE `PROC_INTEGRA_CAD_Produto_Paridade_Emb`(
	IN oCodUsuario				   VARCHAR(10),
	IN ocnpj_cpf_cli 			 VARCHAR(14),
	IN ocod_produto 			  VARCHAR(20),
	IN ocnpj_cpf_for 			 VARCHAR(14),
	IN ocod_produto_for		VARCHAR(20),
	IN oEmbEstoque       VARCHAR(10),	
	IN oEmbCompras       VARCHAR(10),
	IN oFatConvCompras   DECIMAL(18,6),
	# Parametros de Retorno
	OUT RESULTADO        VARCHAR(5),
	OUT MENSAGEM         VARCHAR(500)
)
BLOCO1:BEGIN
   DECLARE excecao             INT DEFAULT 0;
   DECLARE xIdParidade         INT;
   DECLARE Xsigla              VARCHAR(10); 
   DECLARE Xflg_tipo_embalagem INT; 
   DECLARE Xemb_conv_volume    VARCHAR(03); 
   DECLARE Xfator_conv_volume  DECIMAL(18,6);
   -- DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
	
   SELECT id_paridade INTO xIdParidade 
   FROM of_logistica.tbprodutos_paridade
   WHERE cnpj_cpf_for = ocnpj_cpf_for
     AND cod_prod_for = ocod_produto_for
     AND cnpj_cpf_cli = ocnpj_cpf_cli
     AND cod_produto  = ocod_produto;
     
   #Buscar Embalagem e Fator de Conversão Equivalentes   
   SET Xsigla = NULL; SET Xflg_tipo_embalagem = NULL; SET Xemb_conv_volume = NULL; SET Xfator_conv_volume = NULL;
   SELECT sigla, flg_tipo_embalagem, emb_conv_volume, fator_conv_volume
   INTO Xsigla, Xflg_tipo_embalagem, Xemb_conv_volume, Xfator_conv_volume
   FROM of_logistica.tbwms_unidade
   LEFT JOIN of_logistica.tbprodutos_paridade_volume ON 
             tbprodutos_paridade_volume.id_paridade = xIdParidade
         AND tbprodutos_paridade_volume.emb_volume = tbwms_unidade.sigla             
   WHERE tbwms_unidade.sigla = oEmbCompras
   LIMIT 1;
   
   #SELECT * FROM of_logistica.tbprodutos_paridade WHERE id_paridade = xIdParidade;
   #SELECT * FROM of_logistica.tbwms_unidade WHERE tbwms_unidade.sigla = oEmbCompras;
   #SELECT * FROM of_logistica.tbprodutos_paridade_volume WHERE id_paridade = xIdParidade;
   #select Xsigla, Xflg_tipo_embalagem, Xemb_conv_volume, Xfator_conv_volume;
   
   IF Xsigla IS NULL THEN
      INSERT INTO of_logistica.tbwms_unidade (sigla, descricao, flg_tipo_embalagem, dthr_inc, usu_inc, flg_ativo)
      VALUES (oEmbCompras, oEmbCompras, 2, NOW(), oCodUsuario, 1);
   END IF;
   
   
   IF Xemb_conv_volume IS NULL THEN
      INSERT INTO of_logistica.tbprodutos_paridade_volume (
          id_paridade       
         ,emb_volume        
         ,prod_barcode_volume
         ,emb_conv_volume   
         ,fator_conv_volume 
         ,usu_inc           
         ,dthr_inc) VALUES (
         xIdParidade, oEmbCompras, NULL, oEmbEstoque, IFNULL(oFatConvCompras,1), oCodUsuario, NOW());
      SET RESULTADO = 'TRUE';
      SET MENSAGEM = "Registro Inserido com sucesso";
   ELSE
       UPDATE of_logistica.tbprodutos_paridade_volume 
       SET emb_conv_volume    = oEmbEstoque 
          ,fator_conv_volume  = oFatConvCompras
       WHERE id_paridade_volume = xIdParidade
         AND emb_volume = oEmbCompras;
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