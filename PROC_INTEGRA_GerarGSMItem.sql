DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_GerarGSMItem`$$

CREATE PROCEDURE `PROC_INTEGRA_GerarGSMItem`(
   IN oCodUsuario			    VARCHAR(10),
   IN oNumGSMRef        VARCHAR(20),
   IN oNumPedido			     VARCHAR(20),
   IN oLineNum          INT,
   IN oItemCode         VARCHAR(30),
   IN oDescrProduto     VARCHAR(100),
   IN oBaseQty          DOUBLE(20,6),
   IN oOpenInvQty       DOUBLE(20,6),
   IN oVlrUnitario      DOUBLE(20,6),
   IN oEmbVendas        VARCHAR(30),
   IN oEmbEstoque       VARCHAR(30),
   IN oFatorConvVendas  DECIMAL(18,6),
   IN oStatusItem       VARCHAR(10),
   IN oObservItem			    VARCHAR(500),
   IN oCodCliente       VARCHAR(14),
   IN oNomeCliente      VARCHAR(100),
   IN oBatchCode        VARCHAR(30),
   IN oCodDeposito      VARCHAR(10),
   # Parametros de Retorno
   OUT RESULTADO        INT,
   OUT MENSAGEM         VARCHAR(500)
)
BLOCO1:BEGIN
   /**********************************************************************************************/
   #@Reviser David Ruy <2021/03/11> Ajuste atualizar tbprodutos campos Embalagem Vendas SAP
   # caso estiverem nulos
   #@Reviser David Ruy <2021/06/04> Considerar Sigla ou Descrição das Embalagens
   #@Reviser David Ruy <2022/01/12> Ajuste para atualizar peso bruto   
   #@Reviser David Ruy <2022/03/17> Ajuste para atualizar tbsolic_saidas_item2->deposito_integracao    
   #@Reviser David Ruy <2022/03/18> Ajuste tbsolic_saidas_item.tipo_pedido = tbprodutos.tipo_armazenagem 
   #@Reviser David Ruy <2023/02/07> Ajuste parametro OpenInvQty e calculo xFatConvVendas
   #@Reviser David Ruy <2023/04/12> Gerar Itens com Qtde_NF = QtdeEstoqueCli e EmbNF = Emb_Estoque      
   #@Reviser David Ruy <2023/04/22> Ajuste emb_nf e Qtde_NF
   #@Reviser David Ruy <2023/07/03> Se embalagem de estoque = embalagem da venda (SAP), não faz a conversão pelo multiplo de venda   
   #@Reviser David Ruy <2023/07/05> Ajuste variável : xpeso_brt_vol = peso_bruto_vol
   #@Reviser David Ruy <2023-07-07> Reforça a confirmação da existencia da linha para não incluir novamente   
   #@Reviser David Ruy <2023-10-11> Reforça a confirmação da existencia da linha para não incluir novamente (Check via LineNum)   
   #@Reviser David Ruy <2024-03-25> Transaction e chamada da inserção de itens        
   #@Reviser David Ruy <2025-01-07> UpperCase Cadastro de Produtos
   #@Reviser David Ruy <2025-02-24> FatorConvVendas e QtdeEstoqueCli
   #@Reviser David Ruy <2025-03-24> Alterada variável xEmbVendas => oEmbVendas
   #                                Else : calcula xFatConvVendas / xQtdeEstoqueCli
   #Reviser David Ruy <2026-07-14> Considerar OpenInvQty como QtdeEstoque quando embalagem = 'KG'
   /***************************  *******************************************************************/
   DECLARE xCodEmpWMS			VARCHAR(03);
   DECLARE xCodFilWMS			VARCHAR(03);
   DECLARE xCNPJCPFCLI  VARCHAR(14);
   DECLARE xCNPJCPFDEP  VARCHAR(14);
   DECLARE xNumPedido			VARCHAR(20);
   DECLARE xAnoSolic 			VARCHAR(04);
   DECLARE xNumSolic 			VARCHAR(10);
   DECLARE xStatusProcesso		  VARCHAR(02);
   DECLARE xDthrInicio			     VARCHAR(30);
   DECLARE xNumItem			        VARCHAR(06);
   DECLARE xNumItemAux        VARCHAR(06);
   DECLARE xQtdeSep			        DECIMAL(12,2);
   DECLARE xCodEmpTMS			      VARCHAR(03);
   DECLARE xCodFilTMS			      VARCHAR(03);
   DECLARE xQtdeVolumes       INT;
   DECLARE xEmbVendas         VARCHAR(30);
   DECLARE xFatConvVendas     DECIMAL(20,6);
   DECLARE xEmbEstoqueCli     VARCHAR(30);
   DECLARE xQtdeEstoqueCli    DECIMAL(20,6);
   DECLARE xemb_estoque       VARCHAR(10);
   DECLARE xemb_frac          VARCHAR(10);
   DECLARE xemb_vol           VARCHAR(10);
   DECLARE xfator_conversao   DECIMAL(20,6);
   DECLARE xpeso_liq_vol      DECIMAL(20,6);
   DECLARE xpeso_liq_frac     DECIMAL(20,6);
   DECLARE xpesoLiqItem       DECIMAL(20,6);
   DECLARE xpeso_brt_vol      DECIMAL(20,6);
   DECLARE xpeso_liq_item     DECIMAL(20,6);
   DECLARE xpeso_brt_item     DECIMAL(20,6);
   DECLARE xStatusIntegracao  VARCHAR(05);
 
   DECLARE xIncAlt 	VARCHAR(01)	DEFAULT 'I';
   DECLARE xCodErro	INT DEFAULT 0;
   DECLARE excecao 	INT DEFAULT 0;
   
#   declare xDocTipo varchar(10);
#   declare xDocEntry int;
#   DECLARE xflg_agrupa_transf TINYINT;  
   
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       SELECT MENSAGEM;
   END;  
   
   
   SET xCodEmpWMS	= SUBSTRING(oNumGSMRef,01,03);
   SET xCodFilWMS	= SUBSTRING(oNumGSMRef,04,03);
   SET xAnoSolic 	= SUBSTRING(oNumGSMRef,07,04);
   SET xNumSolic 	= SUBSTRING(oNumGSMRef,11,10);
   
   SET xCodEmpTMS	= xCodEmpWMS;
   SET xCodFilTMS	= xCodFilWMS;
   
   
   SET oObservItem  = SUBSTRING(oObservItem,1,300);
   /***************************************************************************
   #@Parametros
   ****************************************************************************/
   #SELECT flg_agrupa_transf INTO xflg_agrupa_transf 
   #FROM tbintegraSAP_parametros LIMIT 1;  
   
   
   
   /**************************************************************************************/
   #Buscar Documento Referenciado na integração
   /**************************************************************************************/    
   #SELECT DocTipo, DocEntry INTO xDocTipo, xDocEntry 
   #FROM tbintegraSAP_Doc
   #WHERE TipoDocSLIN = 'S' 
   #  AND cod_emp = xCodEmpWMS
   #  AND cod_fil = xCodFilWMS
   #  AND ano_solic = xAnoSolic
   #  AND num_solic = xNumSolic;
   
   
   
   #Trata a embalagem de vendas caso seja necessário cadastrar produto
   SELECT sigla INTO xEmbVendas FROM of_logistica.tbwms_unidade WHERE sigla = oEmbVendas OR descricao = oEmbVendas LIMIT 1;
   IF xEmbVendas IS NULL THEN
      SELECT sigla INTO xEmbVendas FROM of_logistica.tbwms_unidade WHERE LOCATE(sigla,oEmbVendas) OR LOCATE(descricao,oEmbVendas) LIMIT 1;
   END IF;      
   SET xEmbVendas = IFNULL(xEmbVendas, SUBSTR(oEmbVendas,1,3));
   #Trata a embalagem de estoque caso seja necessário cadastrar produto
   SELECT sigla INTO xemb_estoque FROM of_logistica.tbwms_unidade WHERE sigla = oEmbEstoque OR descricao = oEmbEstoque LIMIT 1;
   IF xemb_estoque IS NULL THEN
      SELECT sigla INTO xemb_estoque FROM of_logistica.tbwms_unidade WHERE LOCATE(sigla,oEmbEstoque) OR LOCATE(descricao,oEmbEstoque) LIMIT 1;
   END IF;      
   SET xemb_estoque = IFNULL(xemb_estoque, SUBSTR(oEmbEstoque,1,3));
   
   /************************************r*******************************
   #Tratar e Validar as variáveis Destinatário
   *******************************************************************/
   #Tansação tratada pela procedure "Pai"   
   #START TRANSACTION;
   SET xCodErro = 1;
   #Verifica se a GSM existe
   SELECT of_logistica.tbsolic_saidas.cnpj_cpf_cli, of_logistica.tbsolic_saidas.cnpj_cpf_dep, 
          of_logistica.tbsolic_saidas.status_processo, of_logistica.tbsolic_saidas.num_nf
   INTO xCnpjCpfCli, xCnpjCpfDep, xStatusProcesso, xNumPedido
   FROM of_logistica.tbsolic_saidas
   WHERE of_logistica.tbsolic_saidas.cod_emp   = xCodEmpWMS
     AND of_logistica.tbsolic_saidas.cod_fil   = xCodFilWMS
     AND of_logistica.tbsolic_saidas.ano_solic = xAnoSolic
     AND of_logistica.tbsolic_saidas.num_solic = xNumSolic;
   IF xCnpjCpfCli IS NULL THEN
      SET RESULTADO = 0;
      SET MENSAGEM = 'GSM não localizada';
      SET xIncAlt = 'X';
   ELSE
      SET xCodErro = 2;
      #Verifica já existe o produto na GSM
      /*
      SELECT num_item, dthr_aconselhamento, real_vol2
      INTO xNumItem, xDthrInicio, xQtdeSep
      FROM of_logistica.tbsolic_saidas_item 
      WHERE of_logistica.tbsolic_saidas_item.cod_emp     = xCodEmpWMS
        AND of_logistica.tbsolic_saidas_item.cod_fil     = xCodFilWMS
        AND of_logistica.tbsolic_saidas_item.ano_solic   = xAnoSolic
        AND of_logistica.tbsolic_saidas_item.num_solic   = xNumSolic
        AND of_logistica.tbsolic_saidas_item.cod_produto = oItemCode;
      */
      
      SET xNumItem = NULL;
      SELECT ite.num_item, ite.dthr_aconselhamento, ite.real_vol2
      INTO xNumItem, xDthrInicio, xQtdeSep
      FROM of_logistica.tbsolic_saidas_item ite
      INNER JOIN of_logistica.tbsolic_saidas_item2 ite2 ON
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
         FROM of_logistica.tbsolic_saidas_item
         WHERE of_logistica.tbsolic_saidas_item.cod_emp     = xCodEmpWMS
           AND of_logistica.tbsolic_saidas_item.cod_fil     = xCodFilWMS
           AND of_logistica.tbsolic_saidas_item.ano_solic   = xAnoSolic
           AND of_logistica.tbsolic_saidas_item.num_solic   = xNumSolic;
      ELSEIF xDthrInicio IS NULL THEN
         SET xIncAlt = 'A';
      ELSE
         SET xIncAlt = 'X';
         SET RESULTADO = 0;
         SET MENSAGEM = 'Item já está em andamento na GSM - Alteração não permitida';
      END IF; 
   END IF;
   
   
    #@Reviser David Ruy <2025-01-07> UpperCase Cadastro de Produtos
    SET oDescrProduto = IF(oDescrProduto IS NOT NULL, UPPER(oDescrProduto), oDescrProduto );
    SET xemb_estoque = IF(xemb_estoque IS NOT NULL, UPPER(xemb_estoque), xemb_estoque );
    SET xEmbVendas = IF(xEmbVendas IS NOT NULL, UPPER(xEmbVendas), xEmbVendas );
    SET oEmbVendas = IF(oEmbVendas IS NOT NULL, UPPER(oEmbVendas), oEmbVendas );
    SET oEmbEstoque = IF(oEmbEstoque IS NOT NULL, UPPER(oEmbEstoque), oEmbEstoque );
   
   
   /*************************************************************************/
   #@Reviser David Ruy <2020/01/07>
   #Por solicitação do Cesar (Elinox), atualizar a descrição
   /*************************************************************************/
   IF NOT EXISTS (SELECT 1 FROM of_logistica.tbprodutos
      WHERE cnpj_cpf    = xCnpjCpfDep
        AND cod_produto = oItemCode) THEN
      INSERT INTO of_logistica.tbprodutos (cnpj_cpf, cod_produto, descr_produto, emb_estoque, 
               emb_frac, emb_vol, emb_pallet, fator_conversao, qtde_vol_pallet, 
               peso_liq_vol, peso_bruto_vol, peso_liq_frac, peso_bruto_frac,
               emb_vendas, fator_conv_vendas, emb_estoque_cli,
               dthr_inc, usu_inc)
      VALUES (xCnpjCpfDep, oItemCode, SUBSTRING(oDescrProduto,01,60), xemb_estoque, 
               xemb_estoque, xEmbVendas, xEmbVendas, oFatorConvVendas, 200,
               1, 1, 1, 1,
               oEmbVendas, oFatorConvVendas, oEmbEstoque,
               NOW(), oCodUsuario);
   ELSE
   
   
	IF EXISTS( SELECT 1 
             FROM of_logistica.tbprodutos
            WHERE tbprodutos.cnpj_cpf    = xCnpjCpfDep
              AND tbprodutos.cod_produto = oItemCode
              AND (    IFNULL(tbprodutos.descr_produto, '')    <> oDescrProduto 
                    OR IFNULL(tbprodutos.emb_vendas, '')       <> IFNULL(emb_vendas, oEmbVendas)
                    OR IFNULL(tbprodutos.fator_conv_vendas, '') <> IFNULL(fator_conv_vendas, oFatorConvVendas)
                    OR IFNULL(tbprodutos.emb_estoque_cli, '')  <> IFNULL(emb_estoque_cli, oEmbEstoque) )
            ) THEN
            #Reviser 2020-02-27 - Não deixa atualizar informação em branco
	      UPDATE of_logistica.tbprodutos SET
		    descr_produto = IF(oDescrProduto='',descr_produto, SUBSTRING(oDescrProduto,01,60)),
		    #emb_estoque       = xemb_estoque, 
		    #emb_frac          = SUBSTRING(oEmbEstoque,01,03),
		    #emb_vol           = SUBSTRING(oEmbEstoque,01,03),
		    #emb_pallet        = SUBSTRING(oEmbEstoque,01,03), 
		    #fator_conversao   = 1,
		    emb_vendas         = IFNULL(emb_vendas, oEmbVendas),
		    fator_conv_vendas  = IFNULL(fator_conv_vendas, oFatorConvVendas),
		    emb_estoque_cli    = IFNULL(emb_estoque_cli, oEmbEstoque),
		    dthr_alt = NOW(),
		    usu_alt = oCodUsuario
	      WHERE cnpj_cpf = xCnpjCpfDep
		AND cod_produto = oItemCode;
	END IF;
   END IF;     
   
   #Pega as informações do cadastro de produtos
   SELECT emb_estoque, emb_frac, emb_vol, fator_conversao, peso_liq_vol, peso_bruto_vol, peso_liq_frac,
          emb_estoque_cli, emb_vendas, fator_conv_vendas
   INTO xemb_estoque, xemb_frac, xemb_vol, xfator_conversao, xpeso_liq_vol, xpeso_brt_vol, xpeso_liq_frac,
        xEmbEstoqueCli, xEmbVendas, xFatConvVendas
   FROM of_logistica.tbprodutos
   WHERE cnpj_cpf = xCnpjCpfDep
     AND cod_produto = oItemCode;
     
     
   IF IFNULL(oEmbVendas,'') = '' THEN
      SET oEmbVendas = xemb_estoque;
   END IF;     
     
      # xemb_estoque = Embalagem Estoque do cadastro do SLIN
      # desconsiderar | xEmbEstoqueCli = Embalagem Estoque do cadastro do SAP
      # xEmbVendas = Embalagem Estoque do cadastro do SAP
      # oEmbVendas = Embalagem Estoque do Documento no SAP
      # xFatConvVendas = Fator Conversão Cadastro SAP
      
     
   #Calcula quantidade Estoque Cliente (Embalagem de Estoque), #Que deve ser a mesma que no SLIN
   #@Reviser David Ruy <2025-02-24> Inserida condição : AND oEmbVendas <> xemb_estoque
   SET xQtdeEstoqueCli = oBaseQty;
   #@Reviser David Ruy <2025-03-24> Alterada variável xEmbVendas => oEmbVendas
   #IF xEmbVendas <> xEmbEstoqueCli THEN   
   IF (oEmbVendas <> xemb_estoque) THEN
      IF xFatConvVendas > 1 THEN
         SET xQtdeEstoqueCli = oBaseQty * xFatConvVendas;
      ELSE 
         SET xQtdeEstoqueCli = oBaseQty / xFatConvVendas;
      END IF;
   END IF;
   
   
   #@Reviser David Ruy <2023/07/03>
   #Se embalagem de estoque = embalagem da venda, não faz a conversão
   #@Reviser David Ruy <2025-03-24>
   #Else : calcula xFatConvVendas / xQtdeEstoqueCli
   IF (oEmbVendas = xemb_estoque) THEN
      #SET oOpenInvQty = oBaseQty;
      SET xQtdeEstoqueCli = oBaseQty;
   ELSE
      #@Reviser David Ruy <2023/02/07>
      SET xFatConvVendas =  oOpenInvQty / oBaseQty;
      SET xQtdeEstoqueCli = oOpenInvQty;
   END IF;
   #SELECT oEmbVendas,xEmbVendas,xemb_estoque,xEmbEstoqueCli, xFatConvVendas , xQtdeEstoqueCli, oBaseQty, oOpenInvQty;
   
   
#Força Erro para testes
/*   set MENSAGEM = concat("oEmbVendas=>",oEmbVendas," xEmbVendas=>",xEmbVendas," xemb_estoque=>",xemb_estoque," xEmbEstoqueCli=>", xEmbEstoqueCli, 
   " oBaseQty=>",oBaseQty," oOpenInvQty=>",oOpenInvQty,
   " xFatConvVendas=>", xFatConvVendas , " xQtdeEstoqueCli=>",xQtdeEstoqueCli);
   select MENSAGEM ;
   SELECT emb_estoquex FROM of_logistica.tbprodutos
   WHERE cnpj_cpf = xCnpjCpfDep AND cod_produto = oItemCode;
*/   

   #2026-07-14 : Considerar OpenInvQty como QtdeEstoque quando embalagem = 'KG'
   IF LOCATE('KG', IFNULL(oEmbEstoque, oEmbVendas)) THEN
      SET xQtdeEstoqueCli = oOpenInvQty;
   END IF;
   
   
   #Calcula quantidade de volumes
   IF IFNULL(oEmbVendas,'') = '' THEN
      SET oEmbVendas = xemb_estoque;
   END IF;
      
   IF LOCATE('KG',xemb_estoque)  THEN
      SET xQtdevolumes = ROUND(xQtdeEstoqueCli / xpeso_liq_vol);
   ELSEIF xemb_estoque = xemb_vol THEN
      SET xQtdevolumes = xQtdeEstoqueCli;
   ELSEIF xemb_estoque = xemb_frac THEN
      SET xQtdevolumes = xQtdeEstoqueCli / xfator_conversao;
   ELSE
      SET xQtdevolumes = oBaseQty;
   END IF;
   IF IFNULL(xQtdevolumes,1) < 1 THEN
      SET xQtdevolumes = 1;
   END IF;
   #select "Aqui", xpeso_liq_vol, xpeso_brt_vol, xQtdevolumes;
   #leave bloco1;
   
   #Calcula Peso Liquido / Bruto
   IF LOCATE('KG',xemb_estoque) THEN
      SET xpeso_liq_item = xQtdeEstoqueCli;
   ELSEIF xemb_estoque = xemb_vol THEN
      SET xpeso_liq_item = xQtdeEstoqueCli * xpeso_liq_vol;
   ELSEIF xemb_estoque = xemb_frac THEN
      SET xpeso_liq_item = xQtdeVolumes * xpeso_liq_vol;
   ELSE
      SET xpeso_liq_item = xQtdevolumes * xpeso_liq_vol;
   END IF;
   SET xpeso_brt_item = xpeso_liq_item + (xQtdevolumes * (xpeso_brt_vol-xpeso_liq_vol));
   SET xpeso_brt_item = IFNULL(xpeso_brt_item, xpeso_liq_item);
   
   
   #@Reviser David Ruy <2023-07-07> Reforça a confirmação da existencia da linha para não incluir novamente
   #Ajuste para evitar inconsistencia nos itens
   IF EXISTS (SELECT 1 FROM of_logistica.tbsolic_saidas_item2 ite2
              WHERE ite2.cod_emp      = xCodEmpWMS
                AND ite2.cod_fil      = xCodFilWMS
                AND ite2.ano_solic    = xAnoSolic
                AND ite2.num_solic    = xNumSolic
                AND ite2.num_item_cli = oLineNum) THEN
      SET xIncAlt = 'A';
      
      SELECT num_item INTO xNumItem
      FROM of_logistica.tbsolic_saidas_item2 ite2
      WHERE ite2.cod_emp      = xCodEmpWMS
        AND ite2.cod_fil      = xCodFilWMS
        AND ite2.ano_solic    = xAnoSolic
        AND ite2.num_solic    = xNumSolic
        AND ite2.num_item_cli = oLineNum;
   END IF;
   
   #@Reviser David Ruy <2023-10-11> Reforça a confirmação da existencia da linha para não incluir novamente (Check via LineNum)      
   #@Reviser David Ruy <2023-10-25> Double check da existencia da linha para não incluir novamente (Check via LineNum)      
   IF xIncAlt = 'I' THEN
   
      SET xNumItemAux = NULL;
      SELECT num_item INTO xNumItemAux 
      FROM tbintegraSAP_DocItem Item 
      INNER JOIN tbintegraSAP_Doc Topo ON
                   Topo.DocTipo  = Item.DocTipo 
               AND Topo.DocEntry = Item.DocEntry
               AND Topo.DocNum   = Item.DocNum
               AND Item.LineNum  = oLineNum
               AND Item.num_item IS NOT NULL
      WHERE Item.cod_emp      = xCodEmpWMS
        AND Item.cod_fil      = xCodFilWMS
        AND Item.ano_solic    = xAnoSolic
        AND Item.num_solic    = xNumSolic
        AND Topo.TipoDocSLIN  = 'S';
                
      IF xNumItemAux IS NULL THEN
         SET xNumItemAux = NULL;
         SELECT num_item INTO xNumItemAux 
         FROM tbintegraSAP_Doc Topo
         INNER JOIN tbintegraSAP_DocItem Item ON
                      Item.DocTipo  = Topo.DocTipo 
                  AND Item.DocEntry = Topo.DocEntry
                  AND Item.DocNum   = Topo.DocNum
                  AND Item.LineNum  = oLineNum
                  AND Item.num_item IS NOT NULL
         WHERE Topo.cod_emp      = xCodEmpWMS
           AND Topo.cod_fil      = xCodFilWMS
           AND Topo.ano_solic    = xAnoSolic
           AND Topo.num_solic    = xNumSolic
           AND TipoDocSLIN       = 'S';       
      END IF;
        
     IF xNumItemAux IS NOT NULL THEN
         SET xIncAlt = 'A';  
         SET xNumItem = xNumItemAux;
     END IF;
     
   END IF;
   
   
   
   
   
   
   IF xIncAlt = 'I' THEN
      #Insere Item
      INSERT INTO of_logistica.tbsolic_saidas_item( cod_emp
                              , cod_fil
                              , ano_solic
                              , num_solic
                              , num_item
                              , cnpj_cpf_cli
                              , cnpj_cpf_dep
                              , cod_produto
                              , num_ped_aux
                              , num_ped_cli
                              , cod_emp_pedido
                              , cod_fil_pedido
                              , cnpj_cod_destino
                              , emb_nf
                              , qtde_nf
                              , pliq_item
                              , pbrt_item
                              , vlr_unitario
                              , flg_tipo_vlr
                              , vlr_item    
                              #@Reviser David Ruy <2020/03/02> Campos excluídos da tabela
                              #, perc_ipi
                              #, perc_icms
                              #, vlr_ipi_item
                              #, vlr_icms_item
                              , emb_vol
                              , qtde_vol
                              , fator_conv
                              , emb_frac
                              , qtde_frac
                              , emb_est
                              , qtde_est
                              , emb_pallet
                              , qtde_vol_pallet
                              , qtde_pallets
                              , num_lote
                              , sequencia_lote
                              , num_lote_cliente
                              , tipo_pedido
                              , data_valid
                              #@Reviser David Ruy <2020/03/02> Campos excluídos da tabela
                              #, dthr_aconselhamento
                              #, usu_aconselhamento
                              , peso_volume_liq
                              , peso_volume_brt
                              , peso_tipo
                              , real_tara
                              )
         (SELECT xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xNumItem
                ,xCnpjCpfCli, xCnpjCpfDep, oItemCode
                ,xNumPedido, xNumPedido
                ,xCodEmpTMS, xCodFilTMS, oCodCliente
                #,SUBSTRING(xEmbVendas,1,3), oBaseQty
                ,tbprodutos.emb_estoque, xQtdeEstoqueCli
                ,xpeso_liq_item
                ,xpeso_brt_item
                ,oVlrUnitario
                ,IF(tbprodutos.tipo_peso_produto='P','V','P')
                ,oVlrUnitario * oBaseQty
                #,0, 0, 0, 0
                ,tbprodutos.emb_vol
                ,xQtdeVolumes
                ,tbprodutos.fator_conversao
                ,tbprodutos.emb_frac
                ,IF(LOCATE('KG',xemb_frac), 
                  xQtdeEstoqueCli,
                  of_logistica.fnCalcQtdeFrac(tbprodutos.emb_frac, tbprodutos.fator_conversao, tbprodutos.peso_liq_vol*xQtdevolumes, xQtdeVolumes))
                ,tbprodutos.emb_estoque
                ,IF(LOCATE('KG',xemb_estoque), 
                  xQtdeEstoqueCli,
                  of_logistica.fnCalcQtdeEst(tbprodutos.emb_estoque, tbprodutos.emb_frac, tbprodutos.emb_vol, tbprodutos.fator_conversao, tbprodutos.peso_liq_vol*xQtdevolumes, xQtdeVolumes))
                ,tbprodutos.emb_pallet
                ,tbprodutos.qtde_vol_pallet
                ,0 #qtde_pallets
                ,NULL  #num_lote          
                ,NULL  #sequencia_lote
                ,IF(oBatchCode='',NULL, oBatchCode) #num_lote_cliente 
                ,tbprodutos.tipo_armazenagem  #  2     #tipo_pedido 
                ,NULL  #data_valid        
                ,tbprodutos.peso_liq_vol
                ,tbprodutos.peso_bruto_vol
                ,tbprodutos.tipo_peso_produto
                ,tbprodutos.peso_bruto_vol - tbprodutos.peso_liq_vol
         FROM of_logistica.tbprodutos
         WHERE tbprodutos.cnpj_cpf    = xCnpjCpfDep
           AND tbprodutos.cod_produto = oItemCode);
      
      IF ROW_COUNT() > 0 THEN
         SET RESULTADO = 1;
         SET MENSAGEM = "Item Inserido com sucesso";
      ELSE
         SET RESULTADO = 0;
         SET MENSAGEM = "Item Não Inserido";
         LEAVE BLOCO1;
      END IF;
      
      IF (IFNULL(oObservItem,'') <> '' OR IFNULL(oCodDeposito,'') <> '') THEN
         INSERT INTO of_logistica.tbsolic_saidas_item2( cod_emp, cod_fil, ano_solic, num_solic, num_item, observacoes, deposito_integracao) 
             VALUES (xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xNumItem, oObservItem, oCodDeposito);
      END IF;
            
      
   ELSEIF xIncAlt = 'A' THEN
      #Atualiza Item
      UPDATE of_logistica.tbsolic_saidas_item
      LEFT JOIN of_logistica.tbprodutos ON of_logistica.tbprodutos.cnpj_cpf = of_logistica.tbsolic_saidas_item.cnpj_cpf_cli
              AND of_logistica.tbprodutos.cod_produto = of_logistica.tbsolic_saidas_item.cod_produto
      #SET of_logistica.tbsolic_saidas_item.qtde_nf = oBaseQty, 
      SET of_logistica.tbsolic_saidas_item.qtde_nf = xQtdeEstoqueCli,
         of_logistica.tbsolic_saidas_item.qtde_vol = xQtdevolumes, 
         of_logistica.tbsolic_saidas_item.qtde_est = IF(LOCATE('KG',xemb_estoque), 
                                                      xQtdeEstoqueCli,
                                                      of_logistica.fnCalcQtdeEst(tbprodutos.emb_estoque, tbprodutos.emb_frac, tbprodutos.emb_vol, tbprodutos.fator_conversao, tbprodutos.peso_liq_vol*xQtdevolumes, xQtdeVolumes)),
         of_logistica.tbsolic_saidas_item.qtde_frac = IF(LOCATE('KG',xemb_frac), 
                                                      xQtdeEstoqueCli,
                                                      of_logistica.fnCalcQtdeFrac(tbprodutos.emb_frac, tbprodutos.fator_conversao, tbprodutos.peso_liq_vol*xQtdevolumes, xQtdeVolumes)),
         of_logistica.tbsolic_saidas_item.pliq_item = xpeso_liq_item,
         of_logistica.tbsolic_saidas_item.pbrt_item = xpeso_brt_item,
         of_logistica.tbsolic_saidas_item.qtde_vol_pallet = of_logistica.tbprodutos.qtde_vol_pallet, 
         of_logistica.tbsolic_saidas_item.qtde_pallets    = 0, #qtde_pallets
         of_logistica.tbsolic_saidas_item.vlr_unitario    = oVlrUnitario, 
         of_logistica.tbsolic_saidas_item.flg_tipo_vlr    = IF(tbprodutos.tipo_peso_produto='P','V','P'), 
         of_logistica.tbsolic_saidas_item.vlr_item        = oVlrUnitario * oBaseQty, 
         of_logistica.tbsolic_saidas_item.real_tara       = tbprodutos.peso_bruto_vol - tbprodutos.peso_liq_vol
      WHERE cod_emp = xCodEmpWMS
        AND cod_fil = xCodFilWMS
        AND ano_solic = xAnoSolic
        AND num_solic = xNumSolic
        AND num_item = xNumItem;
        
      UPDATE of_logistica.tbsolic_saidas_item2
      SET observacoes         = oObservItem,
          deposito_integracao = oCodDeposito
      WHERE cod_emp = xCodEmpWMS
        AND cod_fil = xCodFilWMS
        AND ano_solic = xAnoSolic
        AND num_solic = xNumSolic
        AND num_item = xNumItem;
      
        
      SET RESULTADO = 1;
      SET MENSAGEM = "Item Alterado com sucesso";
   END IF;
   
   #Tabela Auxiliar de Itens
   INSERT INTO of_logistica.tbsolic_saidas_item2 (
      cod_emp, cod_fil, ano_solic, num_solic, num_item, num_item_cli, observacoes)
   VALUES (xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xNumItem, oLineNum, oObservItem)
   ON DUPLICATE KEY UPDATE num_item_cli = oLineNum, observacoes = oObservItem;
   
   IF (xIncAlt = 'I') OR (xIncAlt = 'A') THEN
      UPDATE of_logistica.tbsolic_saidas
      SET of_logistica.tbsolic_saidas.tot_pliq_nf   = (SELECT SUM(pliq_item) FROM of_logistica.tbsolic_saidas_item
              WHERE of_logistica.tbsolic_saidas_item.cod_emp = of_logistica.tbsolic_saidas.cod_emp
                AND of_logistica.tbsolic_saidas_item.cod_fil = of_logistica.tbsolic_saidas.cod_fil
                AND of_logistica.tbsolic_saidas_item.ano_solic = of_logistica.tbsolic_saidas.ano_solic
                AND of_logistica.tbsolic_saidas_item.num_solic = of_logistica.tbsolic_saidas.num_solic),
       of_logistica.tbsolic_saidas.tot_pbrt_nf   = (SELECT SUM(of_logistica.tbsolic_saidas_item.pbrt_item) FROM of_logistica.tbsolic_saidas_item
              WHERE of_logistica.tbsolic_saidas_item.cod_emp = of_logistica.tbsolic_saidas.cod_emp
                AND of_logistica.tbsolic_saidas_item.cod_fil = of_logistica.tbsolic_saidas.cod_fil
                AND of_logistica.tbsolic_saidas_item.ano_solic = of_logistica.tbsolic_saidas.ano_solic
                AND of_logistica.tbsolic_saidas_item.num_solic = of_logistica.tbsolic_saidas.num_solic),
       of_logistica.tbsolic_saidas.total_volumes = (SELECT SUM(of_logistica.tbsolic_saidas_item.qtde_vol) FROM of_logistica.tbsolic_saidas_item
              WHERE of_logistica.tbsolic_saidas_item.cod_emp = of_logistica.tbsolic_saidas.cod_emp
                AND of_logistica.tbsolic_saidas_item.cod_fil = of_logistica.tbsolic_saidas.cod_fil
                AND of_logistica.tbsolic_saidas_item.ano_solic = of_logistica.tbsolic_saidas.ano_solic
                AND of_logistica.tbsolic_saidas_item.num_solic = of_logistica.tbsolic_saidas.num_solic),	
       #@Reviser David Ruy <2020/03/02> Campos excluídos da tabela                
       /*
       of_logistica.tbsolic_saidas.vlr_tot_ipi = 
             (SELECT SUM(of_logistica.tbsolic_saidas_item.vlr_ipi_item) FROM of_logistica.tbsolic_saidas_item
              WHERE of_logistica.tbsolic_saidas_item.cod_emp = of_logistica.tbsolic_saidas.cod_emp
                AND of_logistica.tbsolic_saidas_item.cod_fil = of_logistica.tbsolic_saidas.cod_fil
                AND of_logistica.tbsolic_saidas_item.ano_solic = of_logistica.tbsolic_saidas.ano_solic
                AND of_logistica.tbsolic_saidas_item.num_solic = of_logistica.tbsolic_saidas.num_solic),	
       of_logistica.tbsolic_saidas.vlr_tot_icms = 
             (SELECT SUM(of_logistica.tbsolic_saidas_item.vlr_icms_item) FROM of_logistica.tbsolic_saidas_item
              WHERE of_logistica.tbsolic_saidas_item.cod_emp = of_logistica.tbsolic_saidas.cod_emp
                AND of_logistica.tbsolic_saidas_item.cod_fil = of_logistica.tbsolic_saidas.cod_fil
                AND of_logistica.tbsolic_saidas_item.ano_solic = of_logistica.tbsolic_saidas.ano_solic
                AND of_logistica.tbsolic_saidas_item.num_solic = of_logistica.tbsolic_saidas.num_solic),	
       */
       of_logistica.tbsolic_saidas.vlr_tot_merc = 
             (SELECT SUM(of_logistica.tbsolic_saidas_item.vlr_item) FROM of_logistica.tbsolic_saidas_item
              WHERE of_logistica.tbsolic_saidas_item.cod_emp = of_logistica.tbsolic_saidas.cod_emp
                AND of_logistica.tbsolic_saidas_item.cod_fil = of_logistica.tbsolic_saidas.cod_fil
                AND of_logistica.tbsolic_saidas_item.ano_solic = of_logistica.tbsolic_saidas.ano_solic
                AND of_logistica.tbsolic_saidas_item.num_solic = of_logistica.tbsolic_saidas.num_solic),	
       of_logistica.tbsolic_saidas.vlr_tot_nf = 
             (SELECT SUM(of_logistica.tbsolic_saidas_item.vlr_item
             #+IFNULL(of_logistica.tbsolic_saidas_item.vlr_ipi_item,0)
             ) 
              FROM of_logistica.tbsolic_saidas_item
              WHERE of_logistica.tbsolic_saidas_item.cod_emp = of_logistica.tbsolic_saidas.cod_emp
                AND of_logistica.tbsolic_saidas_item.cod_fil = of_logistica.tbsolic_saidas.cod_fil
                AND of_logistica.tbsolic_saidas_item.ano_solic = of_logistica.tbsolic_saidas.ano_solic
                AND of_logistica.tbsolic_saidas_item.num_solic = of_logistica.tbsolic_saidas.num_solic)	
      WHERE of_logistica.tbsolic_saidas.cod_emp = xCodEmpWMS
        AND of_logistica.tbsolic_saidas.cod_fil = xCodFilWMS
        AND of_logistica.tbsolic_saidas.ano_solic = xAnoSolic
        AND of_logistica.tbsolic_saidas.num_solic = xNumSolic;
   END IF;
   
   IF excecao = 1 THEN
      #ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro Proc_Integra_GerrGSMItem ",oNumPedido," ",oItemCode);
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      #COMMIT;
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT(LPAD(xNumItem,6,'0')," Item processado com sucesso");
   END IF;
END$$

DELIMITER ;