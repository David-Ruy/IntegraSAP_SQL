DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_RetornoMateriaPrima`$$

CREATE PROCEDURE `PROC_INTEGRA_RetornoMateriaPrima`(
   IN oCodUsuario				VARCHAR(10)
   # Parametros de Retorno
   #OUT RESULTADO             	INT,
   #OUT MENSAGEM              	VARCHAR(500)
)
BLOCO1:BEGIN
   /***************************************************************************
   #@Author David Ruy <2026/03/09>
   # Gera lista de Documentos para Retorno
   #@Reviser David Ruy <2026-05-07> Ajuste Condição de listar (apenas finalizados com DocEntryRef is null)
   ****************************************************************************/
   DECLARE xCodEmpWMS			    VARCHAR(03)	DEFAULT '001';
   DECLARE xCodFilWMS			    VARCHAR(03) DEFAULT '001';
   DECLARE xNumSolic 			    VARCHAR(10);
   DECLARE xAnoSolic 			    VARCHAR(04)	DEFAULT YEAR(CURRENT_DATE());
   DECLARE xDocEntry        INT;
   DECLARE xDocTipo         VARCHAR(10);
   DECLARE xCodErro	        INT DEFAULT 0;
   DECLARE excecao 	        INT DEFAULT 0;
   DECLARE RESULTADO        INT DEFAULT 1;
   DECLARE MENSAGEM         VARCHAR(500);
   DECLARE xSTRGEM          TEXT;
   DECLARE xNumProcesso     VARCHAR(20);  
   
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       SELECT RESULTADO, MENSAGEM;
       ROLLBACK;
   END;
   
   
       
   #Cria tabela temporária com as GEM que estão liberadas para retorno à integração
   DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_MP;
   
  
   CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_MP AS 
      SELECT DocEntry, DocTipo, DocNum, tbSaidas.num_nf, tbSaidas.data_nf, tbSaidas.data_solic
            ,CONCAT(tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic) NumProcesso
            ,tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic
            ,tbSaidas.status_processo, tbSaidas.observ_solic 
            #,CONCAT('CALL PROC_INTEGRA_RetornoEntrada("999999","',CONCAT(tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic,   tbSaidas.num_solic),'");') _call
      FROM tbintegraSAP_Doc
      INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
            tbSaidas.chave_integracao = tbintegraSAP_Doc.chave_integracao
      INNER JOIN of_logistica.tbwms_tipo_oper tbOperacoesWMS ON 
            tbOperacoesWMS.cod_oper_wms = tbSaidas.flg_tipo_oper
      WHERE tbintegraSAP_Doc.DocTipo IN ('OP')
        AND tbSaidas.status_processo >= 8
        AND tbintegraSAP_Doc.StatusDoc = 6
        AND tbSaidas.dthr_retorno_integracao IS NOT NULL
        AND tbintegraSAP_Doc.DocEntryRef IS NULL;  
        
        
   
   #Alimenta variavel xSTRGEM com a lista das GEM´s selecionadas
   SET xSTRGEM = '';  
   WHILE EXISTS (SELECT 1 FROM tbTMP_INTEGRA_RETORNO_MP) DO
      SELECT NumProcesso, cod_emp, cod_fil, ano_solic, num_solic, DocEntry, Doctipo
      INTO xNumProcesso, xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xDocEntry, xDoctipo
      FROM tbTMP_INTEGRA_RETORNO_MP LIMIT 1;         
      
      SET xSTRGEM = CONCAT(xSTRGEM, CONCAT(xCodEmpWMS, "|", xCodFilWMS, "|", xAnoSolic, "|", xNumSolic, "|", xDocEntry, "|"), xDocTipo, "|");
      DELETE FROM tbTMP_INTEGRA_RETORNO_MP WHERE NumProcesso = xNumProcesso;
   END WHILE;
   DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_MP;
   #Cria tabela temporária auxiliar para inner join com a tbsolic_saidas para gerar seleção das informações
   #da GSM informada no parametro
   CALL PROC_SYS_GerarTabelaComTexto(xSTRGEM,'|',6);
   
     
    
   /*******************************************************************
   # Selecionar as informações da GSM
   *******************************************************************/
   # INFORMAÇÕES DO TOPO DA GSM
   SELECT tTabelaComTexto.Coluna05 AS DocEntry, tTabelaComTexto.Coluna06 AS Doctipo, tbintegraSAP_Doc.DocNum,
          #tbintegraSAP_Doc.DocEntry, tbintegraSAP_Doc.DocTipo,
         topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
         topo.data_solic, topo.dthr_acons, topo.num_nf AS num_pedido,
         topo.observ_solic, topo.observ_conf01, topo.status_processo, 
         of_logistica.fnStatusSaidaWms(topo.status_processo) status_processoAux,
         #Liberação Inicio Processo de Separação, Picking
         topo.dthr_confer, topo.dthr_confirm,
         #Inicio Processo de Separação, Picking
         topo.dthr_final_geral, topo.dthr_final_picking,
         IFNULL(tbintegraSAP_Doc.TaxDate, tbintegraSAP_Doc.DocDate) TaxDate, tbintegraSAP_Doc.Observacoes Comments
         ,topo.chave_integracao
         ,RESULTADO, MENSAGEM
   FROM of_logistica.tbsolic_saidas topo
   INNER JOIN tTabelaComTexto ON
             tTabelaComTexto.Coluna01 = topo.cod_emp
         AND tTabelaComTexto.Coluna02 = topo.cod_fil
         AND tTabelaComTexto.Coluna03 = topo.ano_solic
         AND tTabelaComTexto.Coluna04 = topo.num_solic
   INNER JOIN tbintegraSAP_Doc ON 
            tbintegraSAP_Doc.cod_emp   = topo.cod_emp
        AND tbintegraSAP_Doc.cod_fil   = topo.cod_fil
        AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
        AND tbintegraSAP_Doc.num_solic = topo.num_solic
        AND tbintegraSAP_Doc.DocEntry  = tTabelaComTexto.coluna05
        AND tbintegraSAP_Doc.DocTipo   = tTabelaComTexto.coluna06;
   
   
   
   # INFORMAÇÕES DOS ITENS DA GSM
   SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
         ite.num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
         ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
         #
         ite.qtde_est, ite.qtde_vol, ite.qtde_frac, ite.pliq_item,		#Qtde Pedido
         ite.real_est, ite.real_vol, ite.real_frac, ite.real_peso,		#Qtde Aconselhada
         ite.real_est2, ite.real_vol2, ite.real_frac2, ite.real_peso2,	#Qtde Separada
         #ite.real_est3, ite.real_vol3, ite.real_frac3, ite.real_peso3,	#Qtde Conferencia / ???
         #			
         ite.dthr_inicio_baixa_geral, ite.dthr_final_baixa_geral,
         ite.dthr_inicio_picking_carga, ite.dthr_final_picking_carga,
         tbintegraSAP_DocItem.LineNum, tbintegraSAP_DocItem.WhareHouse, tbintegraSAP_DocItem.NumInBuy
         ,tbintegraSAP_DocItem.ManBtchNum
         ,topo.chave_integracao
         ,prod.flg_obriga_lote_fornecedor
         ,RESULTADO, MENSAGEM
   FROM of_logistica.tbsolic_saidas topo
   INNER JOIN tTabelaComTexto ON
             tTabelaComTexto.Coluna01 = topo.cod_emp
         AND tTabelaComTexto.Coluna02 = topo.cod_fil
         AND tTabelaComTexto.Coluna03 = topo.ano_solic
         AND tTabelaComTexto.Coluna04 = topo.num_solic
   LEFT JOIN of_logistica.tbsolic_saidas_item ite ON
         ite.cod_emp = topo.cod_emp
         AND ite.cod_fil = topo.cod_fil
         AND ite.ano_solic = topo.ano_solic
         AND ite.num_solic = topo.num_solic
   LEFT JOIN of_logistica.tbprodutos prod ON
             prod.cnpj_cpf    = ite.cnpj_cpf_dep
         AND prod.cod_produto = ite.cod_produto
   LEFT JOIN tbintegraSAP_Doc ON 
            tbintegraSAP_Doc.cod_emp   = topo.cod_emp
        AND tbintegraSAP_Doc.cod_fil   = topo.cod_fil
        AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
        AND tbintegraSAP_Doc.num_solic = topo.num_solic
        AND tbintegraSAP_Doc.TipoDocSLIN = 'E'
   INNER JOIN tbintegraSAP_DocItem ON 
             tbintegraSAP_DocItem.cod_emp   = ite.cod_emp
         AND tbintegraSAP_DocItem.cod_fil   = ite.cod_fil
         AND tbintegraSAP_DocItem.ano_solic = ite.ano_solic
         AND tbintegraSAP_DocItem.num_solic = ite.num_solic
         AND tbintegraSAP_DocItem.num_item  = ite.num_item
         AND tbintegraSAP_DocItem.DocTipo   = tbintegraSAP_Doc.DocTipo;
 
   # INFORMAÇÕES DAS UA´S DA GSM
   SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
         ite.num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
         ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
         #
         CONCAT(acons.num_lote,acons.sequencia_lote) AS NumUA,
         tbwms_estoque.num_lote_cli,
         acons.qtde_est, acons.qtde_vol, acons.qtde_frac, acons.qtde_peso,		#Qtde Aconselhada
         acons.qtde_est2, acons.qtde_vol2, acons.qtde_frac2, acons.qtde_peso2,	#Qtde Separada
         #acons.qtde_est3, acons.qtde_vol3, acons.qtde_frac3, acons.qtde_peso3,	#(*) Qtde Conferencia/???
         #		
         acons.dthr_baixa_ini, acons.dthr_baixa,
         acons.dthr_conf_picking, acons.dthr_conf,
         of_logistica.fnLocalizCompleta2(acons.cod_und, acons.cod_armazem, acons.camara, acons.rua, 
                                      acons.posicao, acons.altura, acons.profund, NULL, "Sem endereco") AS BinCode
         ,topo.chave_integracao
         ,RESULTADO, MENSAGEM
   FROM of_logistica.tbsolic_saidas topo
   LEFT JOIN of_logistica.tbsolic_saidas_item ite ON
             ite.cod_emp   = topo.cod_emp
         AND ite.cod_fil   = topo.cod_fil
         AND ite.ano_solic = topo.ano_solic
         AND ite.num_solic = topo.num_solic			
   LEFT JOIN of_logistica.tbprodutos prod ON
             prod.cnpj_cpf    = ite.cnpj_cpf_dep
         AND prod.cod_produto = ite.cod_produto
   LEFT JOIN of_logistica.tbsolic_saidas_acons acons ON
             acons.cod_emp   = ite.cod_emp
         AND acons.cod_fil   = ite.cod_fil
         AND acons.ano_solic = ite.ano_solic
         AND acons.num_solic = ite.num_solic			
         AND acons.num_item  = ite.num_item
   LEFT JOIN of_logistica.tbwms_estoque ON  
         tbwms_estoque.cod_emp = acons.cod_emp
         AND tbwms_estoque.cod_fil  = acons.cod_fil
         AND tbwms_estoque.num_lote = acons.num_lote
         AND tbwms_estoque.sequencia_lote = acons.sequencia_lote
   INNER JOIN tTabelaComTexto ON
         tTabelaComTexto.Coluna01     = topo.cod_emp
         AND tTabelaComTexto.Coluna02 = topo.cod_fil
         AND tTabelaComTexto.Coluna03 = topo.ano_solic
         AND tTabelaComTexto.Coluna04 = topo.num_solic;
            
   
   DROP TEMPORARY TABLE IF EXISTS tTabelaComTexto;
    
   IF excecao = 1 THEN
      ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      SELECT RESULTADO, MENSAGEM;
   ELSE    
      SET RESULTADO = 1;
      #SET MENSAGEM  = 'Processo Realizado com sucesso!';
   END IF;
   
END$$

DELIMITER ;