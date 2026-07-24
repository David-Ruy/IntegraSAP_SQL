DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_GerarGEMItem`$$

CREATE PROCEDURE `PROC_INTEGRA_GerarGEMItem`(
   IN oCodUsuario				   VARCHAR(10),
   IN oNumGEMRef        VARCHAR(20),
   IN oNumPedido				    VARCHAR(20),
   IN oLineNum          INT,
   IN oItemCode         VARCHAR(30),
   IN oBaseQty          DOUBLE(20,6),
   IN oOpenInvQty       DOUBLE(20,6),
   IN oVlrUnitario      DOUBLE(20,6),
   IN oStatusItem       VARCHAR(10),
   IN oObservItem			    VARCHAR(500),
   IN oDescrProduto     VARCHAR(100),
   IN oEmbCompras       VARCHAR(30),
   IN oEmbEstoque       VARCHAR(30),
   IN oFatorConvCompras DECIMAL(18,6),   
   IN oCodDeposito      VARCHAR(10),
   # Parametros de Retorno
   OUT RESULTADO      INT,
   OUT MENSAGEM       VARCHAR(500)
)
BLOCO1:BEGIN
   /**********************************************************************************************/
   #@Reviser David Ruy <2019/09/11> Ajuste calculo peso liquido para assumir peso da integração
   # quando for peso variável
   #@Reviser David Ruy <2021/03/11> Ajuste atualizar tbprodutos campos Embalagem Compras SAP
   # caso estiverem nulos
   #@Reviser David Ruy <2021/06/04> Considerar Sigla ou Descrição das Embalagens   
   #@Reviser David Ruy <2021/08/19> Considerar embalagem de vendas para Devoluções (xDocTipo='DV')
   #@Reviser David Ruy <2021/08/26> Campos habilitados novamente (perc_ipi, perc_icms, vlr_ipi_item, vlr_icms_item)
   #@Reviser David Ruy <2021/11/16> Cadastro de produtos co flg_tipo_embalagem = 1 (condição para cadastro da embalagem)
   #@Reviser David Ruy <2022/05/11> Atualizar tbsolic_entradas_item2->deposito_integracao = oCodDeposito
   #@Reviser David Ruy <2022/07/01> Quando DV, pegar embalagem de compras quando embalagens de vendas = nulo
   #@Reviser David Ruy <2023/01/11> Ajuste graver emb_nf -> oEmbCompras em vez de xEmbCompras
   #@Reviser David Ruy <2023/02/08> Ajuste parametro OpenInvQty e calculo xFatConvCompras
   #@Reviser David Ruy <2023/04/12> Gerar Itens com Qtde_NF = QtdeEstoqueCli e EmbNF = Emb_Estoque
   #@Reviser David Ruy <2023-07-11> Ajuste OP : Recalcula xQtdeEstoqueCli
   #@Reviser David Ruy <2024-06-18> Corrige o oFatorConvCompras, caso não exista cadastrado
   #@Reviser David Ruy <2024-11-27> Desabilitado PROC_INTEGRA_CAD_Produto_Paridade_Emb   
   #@Reviser David Ruy <2025-01-07> UpperCase Cadastro de Produtos
   #@Reviser David Ruy <2025-01-07> xQtdeVolPallet
   #@Reviser David Ruy <2025-02-24/25/26> Ajustes calculo Qtdes (Panizzon)
   #                                      Não atualiza tbprodutos->FatorCompras se for PA
   #@Reviser David Ruy <2025-10-29> Ajuste condição : if xDocTipo LIKE 'PA%' AND (oOpenInvQty = oBaseQty) AND (oEmbCompras <> xemb_estoque) THEN #and IFNULL(oFatorConvCompras,0) > 0  THEN
   /**********************************************************************************************/
   DECLARE xCodEmpWMS			VARCHAR(03);
   DECLARE xCodFilWMS			VARCHAR(03);
   DECLARE xCNPJCPFCLI        VARCHAR(14);
   DECLARE xCNPJCPFDEP        VARCHAR(14);
   DECLARE xCnpjCpfFor        VARCHAR(14);
   DECLARE xNumPedido			      VARCHAR(20);
   DECLARE xAnoSolic 			      VARCHAR(04);
   DECLARE xNumSolic 			      VARCHAR(10);
   DECLARE xStatusProcesso		  VARCHAR(02);
   DECLARE xDthrInicio			     VARCHAR(30);
   DECLARE xNumItem			        VARCHAR(06);
   DECLARE xIdFiscal          INT;
   DECLARE xQtdeSep			        DECIMAL(12,2);
   DECLARE xQtdeVolumes       INT;
   DECLARE xemb_estoque       VARCHAR(10);
   DECLARE xemb_frac          VARCHAR(10);
   DECLARE xemb_vol           VARCHAR(10);
   DECLARE xfator_conversao   DECIMAL(20,6);
   DECLARE xpeso_liq_vol      DECIMAL(20,6);
   DECLARE xpeso_brt_vol      DECIMAL(20,6);
   DECLARE xpeso_liq_item     DECIMAL(20,6);
   DECLARE xpeso_brt_item     DECIMAL(20,6);
   DECLARE xChaveIntegracao   VARCHAR(50);
   DECLARE xEmbCompras        VARCHAR(10);
   DECLARE xFatConvCompras    DECIMAL(20,6);
   DECLARE xEmbEstoqueCli     VARCHAR(10);
   DECLARE xQtdeEstoqueCli    DECIMAL(20,6);
   DECLARE xDocTipo           VARCHAR(10);
   DECLARE xQtdeVolPallet     INT;
   
   DECLARE xIncAlt 	VARCHAR(01)	DEFAULT 'I';
   DECLARE xCodErro	INT DEFAULT 0;
   DECLARE excecao 	INT DEFAULT 0;
   /*DECLARE EXIT HANDLER FOR SQLEXCEPTION 
   BEGIN
      SET excecao = 1;
      ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
   END;*/
   SET xCodEmpWMS	= SUBSTRING(oNumGEMRef,01,03);
   SET xCodFilWMS	= SUBSTRING(oNumGEMRef,04,03);
   SET xAnoSolic 	= SUBSTRING(oNumGEMRef,07,04);
   SET xNumSolic 	= SUBSTRING(oNumGEMRef,11,10);
   #Corrige o oFatorConvCompras , caso não exista cadastrado
   SET oFatorConvCompras = IF(IFNULL(oFatorConvCompras,1)=0,1,IFNULL(oFatorConvCompras,1));
   
   #Trata a embalagem de compras caso seja necessário cadastrar produto
   SELECT sigla INTO xEmbCompras FROM of_logistica.tbwms_unidade WHERE flg_tipo_embalagem = 1 AND (sigla = oEmbCompras OR descricao = oEmbCompras) LIMIT 1;
   IF xEmbCompras IS NULL THEN
      #SELECT sigla INTO xEmbCompras FROM of_logistica.tbwms_unidade WHERE flg_tipo_embalagem = 1 AND (LOCATE(sigla,oEmbCompras) OR LOCATE(descricao,oEmbCompras)) LIMIT 1;
      SELECT sigla INTO xEmbCompras FROM of_logistica.tbwms_unidade WHERE flg_tipo_embalagem = 1 AND (LOCATE(sigla,oEmbCompras) OR descricao LIKE CONCAT("%",oEmbCompras,"%")) LIMIT 1;
   END IF;      
   SET xEmbCompras = IFNULL(xEmbCompras, oEmbCompras);
   SET xEmbCompras = SUBSTR(xEmbCompras,1,3);
   
   #Trata a embalagem de estoque caso seja necessário cadastrar produto
   SELECT sigla INTO xemb_estoque FROM of_logistica.tbwms_unidade WHERE flg_tipo_embalagem = 1 AND (sigla = oEmbEstoque OR descricao = oEmbEstoque) LIMIT 1;
   IF xemb_estoque IS NULL THEN
      #SELECT sigla INTO xemb_estoque FROM of_logistica.tbwms_unidade WHERE flg_tipo_embalagem = 1 AND (LOCATE(sigla,oEmbEstoque) OR LOCATE(descricao,oEmbEstoque)) LIMIT 1;
      SELECT sigla INTO xemb_estoque FROM of_logistica.tbwms_unidade WHERE flg_tipo_embalagem = 1 AND (LOCATE(sigla,oEmbEstoque) OR descricao LIKE CONCAT("%",oEmbEstoque,"%")) LIMIT 1;
   END IF;      
   
   SET xemb_estoque = IFNULL(xemb_estoque, oEmbEstoque);
   SET xemb_estoque = SUBSTR(xemb_estoque,1,3);
   
   /*******************************************************************
   #Tratar e Validar as variáveis Destinatário
   *******************************************************************/
   #Tansação tratada pela procedure "Pai"
   #START TRANSACTION;
   SET xCodErro = 1;
   #Verifica se a GEM existe
   SELECT tbsolic_entradas.cnpj_cpf_cli, tbsolic_entradas.cnpj_cpf_dep, 
          tbsolic_entradas.status_processo, tbsolic_entradas.num_nf, 
          tbsolic_entradas_fiscal.id_solic_entradas_fiscal,
          tbsolic_entradas.cnpj_cpf_for,
          tbsolic_entradas.flg_tipo_doc
   INTO xCnpjCpfCli, xCnpjCpfDep, xStatusProcesso, xNumPedido, xIdFiscal, xCnpjCpfFor, xDocTipo
   FROM of_logistica.tbsolic_entradas
   LEFT JOIN of_logistica.tbsolic_entradas_fiscal ON
            tbsolic_entradas_fiscal.cod_emp = tbsolic_entradas.cod_emp
        AND tbsolic_entradas_fiscal.cod_fil = tbsolic_entradas.cod_fil
        AND tbsolic_entradas_fiscal.ano_solic = tbsolic_entradas.ano_solic
        AND tbsolic_entradas_fiscal.num_solic = tbsolic_entradas.num_solic
   WHERE tbsolic_entradas.cod_emp   = xCodEmpWMS
     AND tbsolic_entradas.cod_fil   = xCodFilWMS
     AND tbsolic_entradas.ano_solic = xAnoSolic
     AND tbsolic_entradas.num_solic = xNumSolic;
     
   IF xCnpjCpfCli IS NULL THEN
      SET RESULTADO = 0;
      SET MENSAGEM = 'GEM não localizada';
      SET xIncAlt = 'X';
   ELSE
      SET xCodErro = 2;
      /*
      #Verifica já existe o produto na GEM
      SELECT num_item, dthr_conf_ini, real_vol2
      INTO xNumItem, xDthrInicio, xQtdeSep
      FROM of_logistica.tbsolic_entradas_item
      WHERE of_logistica.tbsolic_entradas_item.cod_emp     = xCodEmpWMS
        AND of_logistica.tbsolic_entradas_item.cod_fil     = xCodFilWMS
        AND of_logistica.tbsolic_entradas_item.ano_solic   = xAnoSolic
        AND of_logistica.tbsolic_entradas_item.num_solic   = xNumSolic
        AND of_logistica.tbsolic_entradas_item.cod_produto = oItemCode;
      */
      SELECT ite.num_item, ite.dthr_conf_ini, ite.real_vol2
      INTO xNumItem, xDthrInicio, xQtdeSep
      FROM of_logistica.tbsolic_entradas_item ite
      INNER JOIN of_logistica.tbsolic_entradas_item2 ite2 ON
               ite2.cod_emp   = ite.cod_emp 
           AND ite2.cod_fil   = ite.cod_fil
           AND ite2.ano_solic = ite.ano_solic
           AND ite2.num_solic = ite.num_solic
           AND ite2.num_item  = ite.num_item 
      WHERE ite2.cod_emp      = xCodEmpWMS
        AND ite2.cod_fil      = xCodFilWMS
        AND ite2.ano_solic    = xAnoSolic
        AND ite2.num_solic    = xNumSolic
        AND ite2.num_item_cli = oLineNum;
      
      IF xNumItem IS NULL THEN
         SET xIncAlt = 'I';
         #Numeração do Proximo Item
         SELECT LPAD(IFNULL(CAST(MAX(num_item) AS UNSIGNED),0)+1,6,'0') INTO xNumItem
         FROM of_logistica.tbsolic_entradas_item
         WHERE of_logistica.tbsolic_entradas_item.cod_emp     = xCodEmpWMS
           AND of_logistica.tbsolic_entradas_item.cod_fil     = xCodFilWMS
           AND of_logistica.tbsolic_entradas_item.ano_solic   = xAnoSolic
           AND of_logistica.tbsolic_entradas_item.num_solic   = xNumSolic;
      ELSEIF xDthrInicio IS NULL THEN
         SET xIncAlt = 'A';
      ELSE
         SET xIncAlt = 'X';
         SET RESULTADO = 0;
         SET MENSAGEM = 'Item já está em andamento na GEM - Alteração não permitida';
      END IF; 
   END IF;
   
   
    #@Reviser David Ruy <2025-01-07> UpperCase Cadastro de Produtos
    SET oDescrProduto = IF(oDescrProduto IS NOT NULL, UPPER(oDescrProduto), oDescrProduto );
    SET xemb_estoque = IF(xemb_estoque IS NOT NULL, UPPER(xemb_estoque), xemb_estoque );
    SET xEmbCompras = IF(xEmbCompras IS NOT NULL, UPPER(xEmbCompras), xEmbCompras );
    SET oEmbCompras = IF(oEmbCompras IS NOT NULL, UPPER(oEmbCompras), oEmbCompras );
    SET oEmbEstoque = IF(oEmbEstoque IS NOT NULL, UPPER(oEmbEstoque), oEmbEstoque );
    
       
   IF NOT EXISTS (SELECT 1 FROM of_logistica.tbprodutos
      WHERE cnpj_cpf    = xCnpjCpfDep
        AND cod_produto = oItemCode) THEN
      #SELECT "Antes de Inserir",
      #xCnpjCpfDep, oItemCode, SUBSTRING(oDescrProduto,01,60), xemb_estoque, 
      #         xemb_estoque, xEmbCompras, xEmbCompras, IF(xEmbCompras=xemb_estoque,1,oFatorConvCompras), 200,
      #         1, 1, 1, 1,
      #         oEmbCompras, oFatorConvCompras, oEmbEstoque,
      #         NOW(), oCodUsuario;
      INSERT INTO of_logistica.tbprodutos (cnpj_cpf, cod_produto, descr_produto, emb_estoque, 
               emb_frac, emb_vol, emb_pallet, fator_conversao, qtde_vol_pallet, 
               peso_liq_vol, peso_bruto_vol, peso_liq_frac, peso_bruto_frac,
               emb_compras, fator_conv_compras, emb_estoque_cli,
               dthr_inc, usu_inc)
      VALUES (xCnpjCpfDep, oItemCode, SUBSTRING(oDescrProduto,01,60), xemb_estoque, 
               xemb_estoque, xEmbCompras, xEmbCompras, IF(xEmbCompras=xemb_estoque,1,oFatorConvCompras), 200,
               1, 1, 1, 1,
               oEmbCompras, oFatorConvCompras, oEmbEstoque,
               NOW(), oCodUsuario);
       #Sincronizar cadastro de produtos
       #
               
   ELSEIF xDocTipo NOT LIKE 'PA%' THEN
      #Reviser 2020-02-27 - Não deixa atualizar informação em branco
      #Reviser 2021-07-15 - Atualiza sempre Dados de Compras SAP
      UPDATE of_logistica.tbprodutos SET
            descr_produto = IF(oDescrProduto='',descr_produto, SUBSTRING(oDescrProduto,01,60)), 
            #emb_estoque       = xemb_estoque, 
            #emb_frac          = SUBSTRING(oEmbEstoque,01,03),
            #emb_vol           = SUBSTRING(oEmbEstoque,01,03),
            #emb_pallet        = SUBSTRING(oEmbEstoque,01,03), 
            #fator_conversao   = 1,
            emb_compras        = oEmbCompras,       #IFNULL(emb_compras, oEmbCompras),
            fator_conv_compras = oFatorConvCompras, #IFNULL(fator_conv_compras, oFatorConvCompras),
            emb_estoque_cli    = oEmbEstoque,       #IFNULL(emb_estoque_cli, oEmbEstoque),
            dthr_alt = NOW(),
            usu_alt = oCodUsuario
      WHERE cnpj_cpf = xCnpjCpfDep
        AND cod_produto = oItemCode;
        
       #Sincronizar cadastro de produtos
       #
        
   END IF;
   
   #Pega as informações do cadastro de produtos
   SELECT emb_estoque, emb_frac, emb_vol, fator_conversao, peso_liq_vol, peso_bruto_vol,
          emb_estoque_cli, IF(xDocTipo='DV',emb_vendas,emb_compras) emb_compras, 
          IF(xDocTipo='DV',fator_conv_vendas,fator_conv_compras) fator_conv_compras, IFNULL(qtde_vol_pallet,1)
   INTO xemb_estoque, xemb_frac, xemb_vol, xfator_conversao, xpeso_liq_vol, xpeso_brt_vol,
        xEmbEstoqueCli, xEmbCompras, xFatConvCompras, xQtdeVolPallet
   FROM of_logistica.tbprodutos
   WHERE cnpj_cpf = xCnpjCpfDep
     AND cod_produto = oItemCode;
     
   SET xQtdeVolPallet = IF(xQtdeVolPallet = 0, 1, xQtdeVolPallet);
     
   #Às vezes não tem a embalagem de vendas, então considera a embalagem de compras mesmo.
   IF IFNULL(xEmbCompras,'') = '' OR IFNULL(xFatConvCompras,0) = 0 THEN
      SELECT emb_estoque, emb_frac, emb_vol, fator_conversao, peso_liq_vol, peso_bruto_vol,
          emb_estoque_cli, 
          emb_compras emb_compras, 
          fator_conv_compras fator_conv_compras
      INTO xemb_estoque, xemb_frac, xemb_vol, xfator_conversao, xpeso_liq_vol, xpeso_brt_vol,
           xEmbEstoqueCli, xEmbCompras, xFatConvCompras
      FROM of_logistica.tbprodutos
      WHERE cnpj_cpf = xCnpjCpfDep
        AND cod_produto = oItemCode;
   END IF;
   
   
   #@Reviser David Ruy <2023/07/03>
   #Se embalagem de estoque = embalagem da venda, não faz a conversão
   IF (oEmbCompras = xemb_estoque) THEN
      SET oOpenInvQty = oBaseQty;
   END IF;
   #SELECT oEmbCompras,xEmbCompras,xemb_estoque,xEmbEstoqueCli;
   
   #@Reviser David Ruy <2023/02/08>
   #Calculo xFatConvVendas com base OpenInvQty
   SET xFatConvCompras =  oOpenInvQty / oBaseQty;
   SET xQtdeEstoqueCli = oOpenInvQty;
   
   
   #Insere a paridade do produtos para o fornecedor do processo
   CALL PROC_INTEGRA_CAD_Produto_Paridade(oCodUsuario, xCnpjCpfDep
         ,oItemCode ,xCnpjCpfFor, oItemCode, SUBSTRING(oDescrProduto,01,50), @R, @M);        
   #SELECT oCodUsuario, xCnpjCpfDep
   #      ,oItemCode ,xCnpjCpfFor, oItemCode, SUBSTRING(oDescrProduto,01,50), @R, @M;
/*
   #Insere a paridade do produtos X Embalagem
   CALL PROC_INTEGRA_CAD_Produto_Paridade_Emb(oCodUsuario, xCnpjCpfDep
         ,oItemCode ,xCnpjCpfFor, oItemCode, xemb_estoque, xEmbCompras, xFatConvCompras, @R, @M);
   #SELECT oCodUsuario, xCnpjCpfDep
   #      ,oItemCode ,xCnpjCpfFor, oItemCode, xemb_estoque, xEmbCompras, xFatConvCompras, @R, @M;
*/
         
   #Calcula quantidade Estoque Cliente (Embalagem de Estoque)
   #Que deve ser a mesma que no SLIN
   SET xQtdeEstoqueCli = oBaseQty;
   IF xEmbCompras <> xEmbEstoqueCli THEN #AND xDocTipo <> 'DV' THEN   
      IF xFatConvCompras > 1 THEN
         SET xQtdeEstoqueCli = oBaseQty * xFatConvCompras;
      ELSE 
         SET xQtdeEstoqueCli = oBaseQty / xFatConvCompras;
      END IF;
   END IF;
   #SELECT oEmbCompras, xemb_estoque, xEmbCompras, xemb_estoque, xEmbEstoqueCli, xFatConvCompras, oFatorConvCompras, xQtdeEstoqueCli, oOpenInvQty;
   
   #@Reviser David Ruy <2023-07-11> Ajuste OP : Recalcula xQtdeEstoqueCli
   #@Reviser David Ruy <2025-02-26> Ajuste OP : Recalcula xQtdeEstoqueCli com base em 
   #IF xDocTipo LIKE 'PA%' AND oEmbCompras <> xemb_estoque AND IFNULL(oFatorConvCompras,0) > 0  THEN
   #IF xDocTipo LIKE 'PA%' AND (oOpenInvQty = oBaseQty) AND (oEmbEstoque = xemb_estoque) THEN #and IFNULL(oFatorConvCompras,0) > 0  THEN
   IF xDocTipo LIKE 'PA%' AND (oOpenInvQty = oBaseQty) AND (oEmbCompras <> xemb_estoque) THEN #and IFNULL(oFatorConvCompras,0) > 0  THEN
      SET xFatConvCompras = xfator_conversao; #oFatorConvCompras;
      #SET xQtdeEstoqueCli = oOpenInvQty / xFatConvCompras;
   ELSEIF (oEmbCompras = xemb_estoque) THEN
      #@Reviser David Ruy <2025-02-25>, #Entradas que não sejam PA : Se embalagem de estoque = embalagem da venda, não faz a conversão
      SET oOpenInvQty = oBaseQty;
   ELSE
      #Reviser David Ruy <2025-02-24> Esse bloco estava fora do ELSE
      #@Reviser David Ruy <2023-02-07>
      #Calculo xFatConvVendas com base OpenInvQty
      SET xFatConvCompras =  oOpenInvQty / oBaseQty;
      SET xQtdeEstoqueCli = oOpenInvQty;
   END IF;
   #SELECT oEmbCompras,xEmbCompras,xemb_estoque,xEmbEstoqueCli, xFatConvCompras, xQtdeEstoqueCli;
   
   #SELECT oEmbEstoque, oEmbCompras, xemb_estoque, xEmbCompras, xemb_estoque, xEmbEstoqueCli, xFatConvCompras, oFatorConvCompras, xQtdeEstoqueCli, oOpenInvQty, oBaseQty;
   #rollback;
   #leave BLOCO1;
   
   
   
   
   
#Força Erro para testes
/*   set MENSAGEM = concat("oEmbCompras=>",oEmbCompras," xEmbCompras=>",xEmbCompras," xemb_estoque=>",xemb_estoque," xEmbEstoqueCli=>", xEmbEstoqueCli, 
   " oBaseQty=>",oBaseQty,
   " xFatConvCompras=>", xFatConvCompras , " xQtdeEstoqueCli=>",xQtdeEstoqueCli);
   select MENSAGEM ;
   SELECT emb_estoquex FROM of_logistica.tbprodutos
   WHERE cnpj_cpf = xCnpjCpfDep AND cod_produto = oItemCode;
*/
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   #Calcula quantidade de volumes
   IF LOCATE('KG',xemb_estoque)  THEN
      SET xQtdevolumes = ROUND(xQtdeEstoqueCli / xpeso_liq_vol);
   ELSEIF xemb_estoque = xemb_vol THEN
      SET xQtdevolumes = xQtdeEstoqueCli;
   ELSEIF xemb_estoque = xemb_frac THEN
      SET xQtdevolumes = xQtdeEstoqueCli / xfator_conversao;
   ELSE
      SET xQtdevolumes = xQtdeEstoqueCli / xfator_conversao;
   END IF;
   IF xQtdevolumes < 1 THEN
      SET xQtdevolumes = 1;
   END IF;
   #SELECT xemb_estoque, xemb_vol, xemb_frac, xQtdeEstoqueCli, xfator_conversao;
   #leave BLOCO1;
   
   #Calcula Peso Liquido / Bruto
   IF LOCATE('KG',xemb_estoque) THEN
      SET xpeso_liq_item = xQtdeEstoqueCli;
   ELSEIF xemb_estoque = xemb_vol THEN
      SET xpeso_liq_item = xQtdeEstoqueCli * xpeso_liq_vol;
   ELSEIF xemb_estoque = xemb_frac THEN
      SET xpeso_liq_item = xQtdevolumes * xpeso_liq_vol;
   ELSE
      SET xpeso_liq_item = xQtdevolumes * xpeso_liq_vol;
   END IF;
   SET xpeso_brt_item = xpeso_liq_item + (xQtdevolumes * (xpeso_brt_vol-xpeso_liq_vol));
      
   
   IF xIncAlt = 'I' THEN  
      #Insere Item
      INSERT INTO of_logistica.tbsolic_entradas_item
         (cod_emp, cod_fil, ano_solic, num_solic, num_item, num_nf_vda,
          cnpj_cpf_cli, cnpj_cpf_dep, cod_produto, emb_nf, qtde_nf, 
          vlr_unitario, flg_tipo_vlr, vlr_item, 
          #@Reviser David Ruy <2020/03/02> Campos excluídos da tabela
          #@Reviser David Ruy <2021/08/26> Campos habilitados novamente
          perc_ipi, perc_icms, vlr_ipi_item, vlr_icms_item,
          emb_vol, fator_conv, 
          emb_frac, emb_est, emb_pallet, qtde_vol_pallet, qtde_pallets,
          qtde_vol, qtde_est, qtde_frac, pliq_item, pbrt_item, id_solic_entradas_fiscal)          
      (SELECT xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xNumItem, xNumPedido,
          #xCnpjCpfCli, xCnpjCpfDep, oItemCode, tbprodutos.emb_vol, oBaseQty, 
          #xCnpjCpfCli, xCnpjCpfDep, oItemCode, SUBSTR(oEmbCompras,1,3), oBaseQty, 
          xCnpjCpfCli, xCnpjCpfDep, oItemCode, tbprodutos.emb_estoque, xQtdeEstoqueCli,
          oVlrUnitario, IF(tbprodutos.tipo_peso_produto='P','V','P'), oVlrUnitario * oBaseQty, 
          0, 0, 0, 0, 
          tbprodutos.emb_vol, tbprodutos.fator_conversao, 
          tbprodutos.emb_frac, tbprodutos.emb_estoque, tbprodutos.emb_pallet, 
          xQtdeVolPallet, #tbprodutos.qtde_vol_pallet, 
          #Quantidade Volumes por pallet
          #xQtdevolumes / IF(IFNULL(tbprodutos.emb_pallet, 1)=0,1, IFNULL(tbprodutos.qtde_vol_pallet, 1)),
          #@Reviser David Ruy <2025-01-07>
          #IF((xQtdevolumes / IFNULL(tbprodutos.qtde_vol_pallet, 1)) > ROUND(xQtdevolumes / IFNULL(tbprodutos.qtde_vol_pallet, 1)),
          #     ROUND(xQtdevolumes / IFNULL(tbprodutos.qtde_vol_pallet, 1))+1,
          #     ROUND(xQtdevolumes / IFNULL(tbprodutos.qtde_vol_pallet, 1))
          IF(xQtdevolumes / xQtdeVolPallet > ROUND(xQtdevolumes / xQtdeVolPallet),
               ROUND(xQtdevolumes / xQtdeVolPallet)+1,
               ROUND(xQtdevolumes / xQtdeVolPallet)
          ),
          #Qtde Volumes
          xQtdeVolumes,
          #Qtde Estoque
          xQtdeEstoqueCli,
          #IF(LOCATE('KG',xEmbCompras) AND LOCATE('KG',xemb_estoque), 
          #  oBaseQty, 
          #  of_logistica.fnCalcQtdeEst(tbprodutos.emb_estoque, tbprodutos.emb_frac, tbprodutos.emb_vol, tbprodutos.fator_conversao, tbprodutos.peso_liq_vol*xQtdeVolumes, xQtdeVolumes)),
          #Qtde Fracao
          IF(LOCATE('KG',xemb_frac), 
            xQtdeEstoqueCli, 
            of_logistica.fnCalcQtdeFrac(tbprodutos.emb_frac, tbprodutos.fator_conversao, tbprodutos.peso_liq_vol*xQtdeVolumes, xQtdeVolumes)),
          #Peso Liquido
          #IF(LOCATE('KG',oEmbCompras),oBaseQty,tbprodutos.peso_liq_vol*xQtdeVolumes),
          xpeso_liq_item,
          #Peso Bruto
          #of_logistica.fnCalcPesoBrt(tbprodutos.peso_liq_vol*xQtdeVolumes, tbprodutos.peso_bruto_vol-tbprodutos.peso_liq_vol, xQtdeVolumes),
          #of_logistica.fnCalcPesoBrt(IF(tbprodutos.peso_liq_vol*xQtdeVolumes < IF(LOCATE('KG',oEmbCompras),oBaseQty,tbprodutos.peso_liq_vol*xQtdeVolumes),
          #                           IF(LOCATE('KG',oEmbCompras),oBaseQty,tbprodutos.peso_liq_vol*xQtdeVolumes),
          #                           tbprodutos.peso_liq_vol*xQtdeVolumes),
          #                           tbprodutos.peso_bruto_vol-tbprodutos.peso_liq_vol, xQtdeVolumes),
          xpeso_brt_item,
          xIdFiscal
      FROM of_logistica.tbprodutos
      WHERE tbprodutos.cnpj_cpf    = xCnpjCpfDep
        AND tbprodutos.cod_produto = oItemCode);
      
      IF ROW_COUNT() > 0 THEN
         SET RESULTADO = 1;
         SET MENSAGEM = "Item Inserido com sucesso";
      ELSE
         SET RESULTADO = 0;
         SET MENSAGEM = "Item Não Inserido";
      END IF;
      
   ELSEIF xIncAlt = 'A' THEN
   
      #Atualiza Item
      UPDATE of_logistica.tbsolic_entradas_item
      LEFT JOIN of_logistica.tbprodutos ON of_logistica.tbprodutos.cnpj_cpf = of_logistica.tbsolic_entradas_item.cnpj_cpf_cli
              AND of_logistica.tbprodutos.cod_produto = of_logistica.tbsolic_entradas_item.cod_produto
      #SET of_logistica.tbsolic_entradas_item.qtde_nf   = oBaseQty, 
      SET of_logistica.tbsolic_entradas_item.qtde_nf   = xQtdeEstoqueCli, 
          of_logistica.tbsolic_entradas_item.qtde_vol  = xQtdeVolumes, 
          of_logistica.tbsolic_entradas_item.qtde_est  = IF(LOCATE('KG',xemb_estoque), 
                                                         xQtdeEstoqueCli, 
                                                         of_logistica.fnCalcQtdeEst(tbprodutos.emb_estoque, tbprodutos.emb_frac, tbprodutos.emb_vol, tbprodutos.fator_conversao, tbprodutos.peso_liq_vol*xQtdeVolumes, xQtdeVolumes)),
          of_logistica.tbsolic_entradas_item.qtde_frac = IF(LOCATE('KG',xemb_frac), 
                                                         xQtdeEstoqueCli, 
                                                         of_logistica.fnCalcQtdeFrac(tbprodutos.emb_frac, tbprodutos.fator_conversao, tbprodutos.peso_liq_vol*xQtdeVolumes, xQtdeVolumes)),
          of_logistica.tbsolic_entradas_item.pliq_item = xpeso_liq_item, #IF(LOCATE('KG',oEmbCompras),oBaseQty,tbprodutos.peso_liq_vol*xQtdeVolumes),
          of_logistica.tbsolic_entradas_item.pbrt_item = xpeso_brt_item, #of_logistica.fnCalcPesoBrt(tbprodutos.peso_liq_vol*xQtdeVolumes, tbprodutos.peso_bruto_vol-tbprodutos.peso_liq_vol, xQtdeVolumes),
          #Reviser David Ruy <2020-11-25> Ajusta Peso Bruto
          #of_logistica.tbsolic_entradas_item.pbrt_item = IF(tbsolic_entradas_item.pbrt_item < tbsolic_entradas_item.pliq_item, tbsolic_entradas_item.pliq_item, tbsolic_entradas_item.pbrt_item),
          of_logistica.tbsolic_entradas_item.qtde_vol_pallet = xQtdeVolPallet, #of_logistica.tbprodutos.qtde_vol_pallet, 
          #of_logistica.tbsolic_entradas_item.qtde_pallets    = IF((xQtdevolumes / IFNULL(tbprodutos.qtde_vol_pallet, 1)) > ROUND(xQtdevolumes / IFNULL(tbprodutos.qtde_vol_pallet, 1)),
          #                                                        ROUND(xQtdevolumes / IFNULL(tbprodutos.qtde_vol_pallet, 1))+1,
          #                                                        ROUND(xQtdevolumes / IFNULL(tbprodutos.qtde_vol_pallet, 1))
          #                                                   ),
          of_logistica.tbsolic_entradas_item.qtde_pallets    = IF(xQtdevolumes / xQtdeVolPallet > ROUND(xQtdevolumes / xQtdeVolPallet),
                                                                  ROUND(xQtdevolumes / xQtdeVolPallet)+1,
                                                                  ROUND(xQtdevolumes / xQtdeVolPallet)
                                                             ),
          of_logistica.tbsolic_entradas_item.vlr_unitario    = oVlrUnitario, 
          of_logistica.tbsolic_entradas_item.flg_tipo_vlr    = IF(tbprodutos.tipo_peso_produto='P','V','P'), 
          of_logistica.tbsolic_entradas_item.vlr_item        = oVlrUnitario * oBaseQty                   
      WHERE cod_emp   = xCodEmpWMS
        AND cod_fil   = xCodFilWMS
        AND ano_solic = xAnoSolic
        AND num_solic = xNumSolic
        AND num_item  = xNumItem;
        
      
      SET RESULTADO = 1;
      SET MENSAGEM = "Item Alterado com sucesso";
   END IF;
   
   
   #Tabela Auxiliar de Itens
   INSERT INTO of_logistica.tbsolic_entradas_item2 (
      cod_emp, cod_fil, ano_solic, num_solic, num_item, num_item_cli, observacoes, deposito_integracao)
   VALUES (xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xNumItem, oLineNum, oObservItem, oCodDeposito)
   ON DUPLICATE KEY UPDATE num_item_cli = oLineNum, observacoes = oObservItem, deposito_integracao = oCodDeposito;
   
   
   IF (xIncAlt = 'I') OR (xIncAlt = 'A') THEN
      UPDATE of_logistica.tbsolic_entradas
      SET tbsolic_entradas.tot_pliq_nf   = (SELECT SUM(pliq_item) FROM of_logistica.tbsolic_entradas_item
              WHERE tbsolic_entradas_item.cod_emp = tbsolic_entradas.cod_emp
                AND tbsolic_entradas_item.cod_fil = tbsolic_entradas.cod_fil
                AND tbsolic_entradas_item.ano_solic = tbsolic_entradas.ano_solic
                AND tbsolic_entradas_item.num_solic = tbsolic_entradas.num_solic),
       tbsolic_entradas.tot_pbrt_nf   = 
            (SELECT SUM(tbsolic_entradas_item.pbrt_item) FROM of_logistica.tbsolic_entradas_item
              WHERE tbsolic_entradas_item.cod_emp = tbsolic_entradas.cod_emp
                AND tbsolic_entradas_item.cod_fil = tbsolic_entradas.cod_fil
                AND tbsolic_entradas_item.ano_solic = tbsolic_entradas.ano_solic
                AND tbsolic_entradas_item.num_solic = tbsolic_entradas.num_solic),
       tbsolic_entradas.total_volumes = 
            (SELECT SUM(tbsolic_entradas_item.qtde_vol) FROM of_logistica.tbsolic_entradas_item
              WHERE tbsolic_entradas_item.cod_emp = tbsolic_entradas.cod_emp
                AND tbsolic_entradas_item.cod_fil = tbsolic_entradas.cod_fil
                AND tbsolic_entradas_item.ano_solic = tbsolic_entradas.ano_solic
                AND tbsolic_entradas_item.num_solic = tbsolic_entradas.num_solic),
       /*
       tbsolic_entradas.vlr_tot_ipi = 
             (SELECT SUM(tbsolic_entradas_item.vlr_ipi_item) FROM of_logistica.tbsolic_entradas_item
              WHERE tbsolic_entradas_item.cod_emp = tbsolic_entradas.cod_emp
                AND tbsolic_entradas_item.cod_fil = tbsolic_entradas.cod_fil
                AND tbsolic_entradas_item.ano_solic = tbsolic_entradas.ano_solic
                AND tbsolic_entradas_item.num_solic = tbsolic_entradas.num_solic),
       tbsolic_entradas.vlr_tot_icms = 
             (SELECT SUM(tbsolic_entradas_item.vlr_icms_item) FROM of_logistica.tbsolic_entradas_item
              WHERE tbsolic_entradas_item.cod_emp = tbsolic_entradas.cod_emp
                AND tbsolic_entradas_item.cod_fil = tbsolic_entradas.cod_fil
                AND tbsolic_entradas_item.ano_solic = tbsolic_entradas.ano_solic
                AND tbsolic_entradas_item.num_solic = tbsolic_entradas.num_solic),
       */
       tbsolic_entradas.vlr_tot_merc = 
             (SELECT SUM(tbsolic_entradas_item.vlr_item) FROM of_logistica.tbsolic_entradas_item
              WHERE tbsolic_entradas_item.cod_emp = tbsolic_entradas.cod_emp
                AND tbsolic_entradas_item.cod_fil = tbsolic_entradas.cod_fil
                AND tbsolic_entradas_item.ano_solic = tbsolic_entradas.ano_solic
                AND tbsolic_entradas_item.num_solic = tbsolic_entradas.num_solic),
       tbsolic_entradas.vlr_tot_nf = 
             (SELECT SUM(tbsolic_entradas_item.vlr_item
             #+IFNULL(tbsolic_entradas_item.vlr_ipi_item,0)
             ) 
              FROM of_logistica.tbsolic_entradas_item
              WHERE tbsolic_entradas_item.cod_emp = tbsolic_entradas.cod_emp
                AND tbsolic_entradas_item.cod_fil = tbsolic_entradas.cod_fil
                AND tbsolic_entradas_item.ano_solic = tbsolic_entradas.ano_solic
                AND tbsolic_entradas_item.num_solic = tbsolic_entradas.num_solic)
      WHERE tbsolic_entradas.cod_emp = xCodEmpWMS
        AND tbsolic_entradas.cod_fil = xCodFilWMS
        AND tbsolic_entradas.ano_solic = xAnoSolic
        AND tbsolic_entradas.num_solic = xNumSolic;
      UPDATE of_logistica.tbsolic_entradas_fiscal
      SET tot_pliq_nf   = (SELECT SUM(tbsolic_entradas_item.pliq_item) FROM of_logistica.tbsolic_entradas_item
              WHERE tbsolic_entradas_item.cod_emp = tbsolic_entradas_fiscal.cod_emp
                AND tbsolic_entradas_item.cod_fil = tbsolic_entradas_fiscal.cod_fil
                AND tbsolic_entradas_item.ano_solic = tbsolic_entradas_fiscal.ano_solic
                AND tbsolic_entradas_item.num_solic = tbsolic_entradas_fiscal.num_solic),
       tot_pbrt_nf   = (SELECT SUM(tbsolic_entradas_item.pbrt_item) FROM of_logistica.tbsolic_entradas_item
              WHERE tbsolic_entradas_item.cod_emp = tbsolic_entradas_fiscal.cod_emp
                AND tbsolic_entradas_item.cod_fil = tbsolic_entradas_fiscal.cod_fil
                AND tbsolic_entradas_item.ano_solic = tbsolic_entradas_fiscal.ano_solic
                AND tbsolic_entradas_item.num_solic = tbsolic_entradas_fiscal.num_solic),
       #@Reviser David Ruy <2020/03/02> Campos excluídos da tabela                                
       /*
       vlr_tot_ipi = 
             (SELECT SUM(tbsolic_entradas_item.vlr_ipi_item) FROM of_logistica.tbsolic_entradas_item
              WHERE tbsolic_entradas_item.cod_emp = tbsolic_entradas_fiscal.cod_emp
                AND tbsolic_entradas_item.cod_fil = tbsolic_entradas_fiscal.cod_fil
                AND tbsolic_entradas_item.ano_solic = tbsolic_entradas_fiscal.ano_solic
                AND tbsolic_entradas_item.num_solic = tbsolic_entradas_fiscal.num_solic),
       vlr_tot_icms = 
             (SELECT SUM(tbsolic_entradas_item.vlr_icms_item) FROM of_logistica.tbsolic_entradas_item
              WHERE tbsolic_entradas_item.cod_emp = tbsolic_entradas_fiscal.cod_emp
                AND tbsolic_entradas_item.cod_fil = tbsolic_entradas_fiscal.cod_fil
                AND tbsolic_entradas_item.ano_solic = tbsolic_entradas_fiscal.ano_solic
                AND tbsolic_entradas_item.num_solic = tbsolic_entradas_fiscal.num_solic),
       */
       vlr_tot_merc = 
             (SELECT SUM(tbsolic_entradas_item.vlr_item) FROM of_logistica.tbsolic_entradas_item
              WHERE tbsolic_entradas_item.cod_emp = tbsolic_entradas_fiscal.cod_emp
                AND tbsolic_entradas_item.cod_fil = tbsolic_entradas_fiscal.cod_fil
                AND tbsolic_entradas_item.ano_solic = tbsolic_entradas_fiscal.ano_solic
                AND tbsolic_entradas_item.num_solic = tbsolic_entradas_fiscal.num_solic),
       vlr_tot_nf = 
             (SELECT SUM(tbsolic_entradas_item.vlr_item
             #+IFNULL(of_logistica.tbsolic_entradas_item.vlr_ipi_item,0)
             ) 
              FROM of_logistica.tbsolic_entradas_item
              WHERE tbsolic_entradas_item.cod_emp = tbsolic_entradas_fiscal.cod_emp
                AND tbsolic_entradas_item.cod_fil = tbsolic_entradas_fiscal.cod_fil
                AND tbsolic_entradas_item.ano_solic = tbsolic_entradas_fiscal.ano_solic
                AND tbsolic_entradas_item.num_solic = tbsolic_entradas_fiscal.num_solic)
      WHERE tbsolic_entradas_fiscal.cod_emp = xCodEmpWMS
        AND tbsolic_entradas_fiscal.cod_fil = xCodFilWMS
        AND tbsolic_entradas_fiscal.ano_solic = xAnoSolic
        AND tbsolic_entradas_fiscal.num_solic = xNumSolic;
        
      #Gerar aconselhamento do Item se for inclusao
      #@Reviser David Ruy <2020-11-25> Rotina desativada,
      #o aconselhamento será gerado na procedure PROC_INTEGRA_GerarGEM
      #IF xIncAlt = 'I' THEN
      #   CALL of_logistica.PROC_WMS_DESCARGA_GERAR_ACONSELHAMENTO(
      #      1, oCodUsuario, xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xNumItem, @R, @M);
      #END IF;
      
   END IF;
   
   
   IF excecao = 1 THEN
      #ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro Proc_Integra_GerrGEMItem ",oNumPedido," ",oItemCode);
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      #COMMIT;
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT(LPAD(xNumItem,6,'0'),"|",xIncAlt, "|Item processado com sucesso");
   END IF;
   
END$$

DELIMITER ;