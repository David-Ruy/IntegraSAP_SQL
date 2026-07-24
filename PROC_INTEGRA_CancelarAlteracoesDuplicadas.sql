DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_CancelarAlteracoesDuplicadas`$$

CREATE PROCEDURE `PROC_INTEGRA_CancelarAlteracoesDuplicadas`(
	# Parametros de Retorno
	OUT RESULTADO       VARCHAR(5),
	OUT MENSAGEM        VARCHAR(500)
)
BLOCO1:BEGIN
   /*******************************************************************************************/
   #Author David Ruy <2021-01-10>
   #Reviser David Ruy <2022-02-01> Campos : UgpEntry, UomCode, unitMsr, OpenInvQty
   #Reviser David Ruy <2022-02-01> Considerar tbintegraSAP_UpdCanc.Status = 1 se U_RSD_RplOrder não for Nulo
   #                               para forçar o processamento de alteração
   #Reviser David Ruy <2022-03-24> xOpenInvQtyOriginal, xBaseQtyOriginal para atualizar tbintegraSAP_DocItem->OpenInvQty
   #Reviser David Ruy <2022-04-29> Correção where tbUpdCancPV.TipoUpdCanc = 'U' no update (0) Exclusão de PV´ nao alterados 
   #Reviser David Ruy <2022-12-20> Desconsiderar PV´s já faturados => Quando xflg_permite_PVParcial = 0   
   #Reviser David Ruy <2022-12-22> Ajuste inclusão de itens : PROC_INTEGRA_EnviarDocEntry_Item => IFNULL(xOpenInvQty,xBaseQty)
   #                               Ajuste tbTMPAtulizaQtde -> Left join em vez de inner (casos de inclusão de itens)
   #Reviser David Ruy <2023-04-03> Alteração se tbTMPAtuTMS.cnpjTransp = "", enviar NULL
   #Reviser David Ruy <2024-12-27> melhora na condição : TipoUpdCanc = 'U' AND STATUS = 0
   #Reviser David Ruy <2025-01-16> Ajuste para não gravar OpenInvQty = null : 
   #                               tbItens.OpenInvQty    = IFNULL(tbUpdCancPV.QtdeEstoque, IFNULL(tbItens.OpenInvQty/tbItens.BaseQty*tbUpdCancPV.Quantity, tbUpdCancPV.Quantity))
   #@Reviser David Ruy <2025-02-25> #Teoricamente não tem necessidade, visto que no EnviarUpdCancPV, já envio OpenInvQty (QtdeEstoque)
   #@Reviser David Ruy <2025-07-02> Criação com índices tabela temporária tbTMPAtulizaQtde, Start Transaction no final da rotina apenas
   #                                Ajuste tamanho variáveis _UniqueKey, xUniqueKey de varchar(20) para varchar(30)
   /*******************************************************************************************/
   
   DECLARE _UniqueKey         VARCHAR(30);
   DECLARE _UpdateDate        VARCHAR(20);
   DECLARE _ItemCode          VARCHAR(50);
   DECLARE _Quantity          DECIMAL(18,6);
   DECLARE _CNPJCPFDEP        VARCHAR(14);
   DECLARE _SalUnitMsr        VARCHAR(10);
   DECLARE _InvntryUom        VARCHAR(10);
   DECLARE _NumInSale         DECIMAL(18,6);
   DECLARE _emb_estoque       VARCHAR(10);
   DECLARE _fator_conversao   DECIMAL(18,6);
   DECLARE _QtdeEstoqueCli    DECIMAL(18,6);
    
   DECLARE xQtdeRegs          INT DEFAULT 0;
   DECLARE excecao            INT DEFAULT 0;
 
   DECLARE xCodEmpWMS         VARCHAR(03);
   DECLARE xCodFilWMS         VARCHAR(03);
   DECLARE xAnoSolic          VARCHAR(04);
   DECLARE xNumSolic          VARCHAR(10);
   DECLARE xTipoFrete         VARCHAR(05);
   DECLARE xNomeTransp        VARCHAR(100);
   DECLARE xCnpjTransp        VARCHAR(20);
   DECLARE xchave_integracao  VARCHAR(20);
   DECLARE xCNPJCPFCLI        VARCHAR(20);
   
   DECLARE xflgAtuTransp      INT DEFAULT 0;
   DECLARE xflgAtuEndereco    INT DEFAULT 0;
   
   DECLARE xCardCode          VARCHAR(15);
   DECLARE xCardName          VARCHAR(100);
   DECLARE xEndereco          VARCHAR(100);
   DECLARE xNumEnde           VARCHAR(30);
   DECLARE xComplEnde         VARCHAR(200);
   DECLARE xBairroEnde        VARCHAR(50);
   DECLARE xCidadeEnde        VARCHAR(50);
   DECLARE xCepEnde           VARCHAR(10);
   DECLARE xUFEnde            VARCHAR(02);
   DECLARE xPaisEnde          VARCHAR(50);
   DECLARE xhora1_entrega     VARCHAR(20);
   DECLARE xhora2_entrega     VARCHAR(20);
   DECLARE xhora3_entrega     VARCHAR(20);
   DECLARE xhora4_entrega     VARCHAR(20);
   DECLARE xEnd_Entrega       VARCHAR(200);
   
   DECLARE xTipoPessoa        VARCHAR(01);
   DECLARE xNumCPF            VARCHAR(20);
   DECLARE xNumCNPJ           VARCHAR(20);
   DECLARE xNumCPFouCNPJ      VARCHAR(20);
   
   #Variáveis para inclusão na tbintegraSAP_DocItem
   DECLARE xUniqueKey         VARCHAR(30);
   DECLARE xCodUsuario        VARCHAR(20);
   DECLARE xDocEntry          INT;
   DECLARE xDocTipo           VARCHAR(20);
   DECLARE xDocNum            INT;
   DECLARE xLineNum           INT;
   DECLARE xItemCode          VARCHAR(20);
   DECLARE xBaseQty           DOUBLE(20,6);
   DECLARE xPlannedQty        DOUBLE(20,6);
   DECLARE xIssuedQty         DOUBLE(20,6);
   DECLARE xWhareHouse        VARCHAR(30);
   DECLARE xPrice             DOUBLE(20,6);
   DECLARE xDollarQuote       DOUBLE(20,6);
   DECLARE xIssueType         VARCHAR(1);
   DECLARE xStatusItem        VARCHAR(10);
   DECLARE xObservacoes       VARCHAR(500);
   DECLARE xDescrProduto      VARCHAR(200);
   DECLARE xEmbCompras        VARCHAR(30);
   DECLARE xEmbVendas         VARCHAR(30);
   DECLARE xEmbEstoque        VARCHAR(30);
   DECLARE xManBtchNum        INT;
   DECLARE xManSerNum         INT;
   DECLARE xNumInSale         DOUBLE(20,6);
   DECLARE xBatchNumbersCode  VARCHAR(30);
   DECLARE xUgpEntry          INT;
   DECLARE xUomCode           VARCHAR(30);
   DECLARE xunitMsr           VARCHAR(30);
   DECLARE xOpenInvQty        DECIMAL(20,6); 
   DECLARE xOpenInvQtyOriginal DECIMAL(20,6); 
   DECLARE xBaseQtyOriginal    DECIMAL(20,6); 
   DECLARE xflg_PROMO          VARCHAR(01);
   DECLARE xflg_USO_CONS     VARCHAR(01);  
   
   DECLARE xflg_permite_PVParcial INT;
   DECLARE xflg_alterar_apos_retorno INT;
   DECLARE xUsage      VARCHAR(20);
   DECLARE xCFOPCode   VARCHAR(25);
   DECLARE xTaxCode    VARCHAR(15);   
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = CONCAT(xNumSolic," ",of_logistica.fnMensagemExcecao(MENSAGEM));
       ROLLBACK;
   END;
   
   #Iniciar transação apenas no final da rotina
   #START TRANSACTION;
   
   
   SET RESULTADO = "1";
   SET MENSAGEM = "Atualização realizada com sucesso (1)";
   
   
   /**********************************************************************************************/
   #Busca Parametros
   /*********************************************************************************************/
   SELECT cnpj_cpf_dep, flg_permite_PVParcial, flg_alterar_apos_retorno 
   INTO _CNPJCPFDEP, xflg_permite_PVParcial, xflg_alterar_apos_retorno
   FROM tbintegraSAP_parametros
   #WHERE flg_ativo = 1 
   LIMIT 1;   
   
   
   /**********************************************************************************************/
   #@Reviser David Ruy <2022-12-20> Desconsiderar PV´s já faturados => Quando xflg_permite_PVParcial = 0
   /**********************************************************************************************/
   IF IFNULL(xflg_alterar_apos_retorno,0) = 0 THEN
      UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV 
      INNER JOIN tbintegraSAP_Doc TbDoc ON 
                 TbDoc.DocTipo  = tbUpdCancPV.DocumentType
             AND TbDoc.DocEntry = tbUpdCancPV.DocumentId
             AND TbDoc.Docnum   = tbUpdCancPV.DocumentNumber
      SET tbUpdCancPV.Status = 3
         ,tbUpdCancPV.FreeText = SUBSTRING(CONCAT(TRIM(BOTH FROM IFNULL(tbUpdCancPV.FreeText,'')),IF(tbUpdCancPV.FreeText IS NULL,'','|'),"(-1)Exclusão PV já Retornado"),1,300)
      WHERE tbUpdCancPV.TipoUpdCanc = 'U'
        AND tbUpdCancPV.Status = 0
        AND TbDoc.StatusDoc = 6;
   END IF;
   
   
         
   /**********************************************************************************************/
   #@Reviser David Ruy <2022-04-03> Limpar Duplicidades 
   #Reviser David Ruy <2024-12-27> melhora na condição : TipoUpdCanc = 'U' AND STATUS = 0
   /**********************************************************************************************/
   UPDATE tbintegraSAP_Doc
   INNER JOIN tbintegraSAP_UpdCancPV tbUpdCancPV ON
              tbUpdCancPV.DocumentId     = tbintegraSAP_Doc.DocEntry
          AND tbUpdCancPV.DocumentType   = tbintegraSAP_Doc.DocTipo
          AND tbUpdCancPV.DocumentNumber = tbintegraSAP_Doc.DocNum
   SET tbintegraSAP_Doc.UpdateDate = tbintegraSAP_Doc.dthr_inc
   WHERE TipoUpdCanc = 'U' AND STATUS = 0
   AND tbintegraSAP_Doc.UpdateDate IS NULL;
   #SELECT "AQUI1";
   
   /**********************************************************************************************/
   #Atualiza PV´s não alterados ou alteração anterior à tbintegraSAP_Doc.UpdateDate
   /*********************************************************************************************/
   UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV
   INNER JOIN tbintegraSAP_DocItem tbItem ON 
              tbItem.DocEntry = tbUpdCancPV.DocumentId
          AND tbItem.DocTipo  = tbUpdCancPV.DocumentType
          AND tbItem.DocNum   = tbUpdCancPV.DocumentNumber
          AND tbItem.LineNum  = tbUpdCancPV.LineNumber
   SET tbUpdCancPV.Status = 3
      ,tbUpdCancPV.FreeText = SUBSTRING(CONCAT(TRIM(BOTH FROM IFNULL(tbUpdCancPV.FreeText,'')),IF(tbUpdCancPV.FreeText IS NULL,'','|'),"(0)Exclusão PV´s não alterados"),1,300)
      ,tbItem.StatusAnt  = IF(tbItem.StatusItem = 9, tbItem.StatusAnt, tbItem.StatusItem)
      ,tbItem.StatusItem = IF(tbItem.StatusItem = 9, tbItem.StatusItem, 0)
      ,tbUpdCancPV.cod_emp   = tbItem.cod_emp 
      ,tbUpdCancPV.cod_fil   = tbItem.cod_fil
      ,tbUpdCancPV.ano_solic = tbItem.ano_solic
      ,tbUpdCancPV.num_solic = tbItem.num_solic
      ,tbUpdCancPV.num_item  = tbItem.num_item
   WHERE tbUpdCancPV.TipoUpdCanc = 'U'
     AND tbUpdCancPV.Status = 0
     AND EXISTS (SELECT 1 FROM tbintegraSAP_Doc
                       WHERE tbintegraSAP_Doc.DocTipo  = tbUpdCancPV.DocumentType
                         AND tbintegraSAP_Doc.DocEntry = tbUpdCancPV.DocumentId
                         AND tbintegraSAP_Doc.DocNum   = tbUpdCancPV.DocumentNumber
                         AND IFNULL(tbintegraSAP_Doc.UpdateDate,tbintegraSAP_Doc.dthr_inc) >= tbUpdCancPV.UpdateDate);
   #SELECT "AQUI2";
                           
   
   /**********************************************************************************************/
   #Atualiza Quantidade Base equivalente QtdeEstoque = Quantity (convertida)
   /*********************************************************************************************/
   SELECT cnpj_cpf_dep, flg_permite_PVParcial INTO _CNPJCPFDEP, xflg_permite_PVParcial
   FROM tbintegraSAP_parametros
   #WHERE flg_ativo = 1 
   LIMIT 1;
   
         
   DROP TEMPORARY TABLE IF EXISTS tbTMPAtulizaQtde;
   CREATE TEMPORARY TABLE tbTMPAtulizaQtde (
         UniqueKey  VARCHAR(50), 
         UpdateDate VARCHAR(30), 
         ItemCode   VARCHAR(50), 
         Quantity   DECIMAL(18,6),
	 SalUnitMsr VARCHAR(20), 
	 NumInSale  DECIMAL(18,6), 
	 InvntryUom VARCHAR(20),
	 BaseQty    DECIMAL(18,6), 
	 OpenInvQty DECIMAL(18,6) ,
	 emb_estoque VARCHAR(10), 
	 fator_conversao DECIMAL(18,6),
	 flgProcessado INT DEFAULT 0,
	 PRIMARY KEY (UniqueKey, UpdateDate)
   );
   
   INSERT INTO tbTMPAtulizaQtde (
          SELECT tbUpdCancPV.UniqueKey, tbUpdCancPV.UpdateDate, tbUpdCancPV.ItemCode, tbUpdCancPV.Quantity, 
                 tbUpdCancPV.SalUnitMsr, tbUpdCancPV.NumInSale, tbUpdCancPV.InvntryUom,
                 tbItens.BaseQty, tbItens.OpenInvQty,
                 emb_estoque, fator_conversao,
                 0 AS flgProcessado
          FROM tbintegraSAP_UpdCancPV tbUpdCancPV
          #INNER JOIN tbintegraSAP_DocItem tbItens ON 
          LEFT JOIN tbintegraSAP_DocItem tbItens ON 
                     tbItens.DocEntry = tbUpdCancPV.DocumentId
                 AND tbItens.DocTipo  = tbUpdCancPV.DocumentType
                 AND tbItens.DocNum   = tbUpdCancPV.DocumentNumber
                 AND tbItens.LineNum  = tbUpdCancPV.LineNumber
          INNER JOIN of_logistica.tbprodutos ON
                     tbprodutos.cnpj_cpf    =  _CNPJCPFDEP
                 AND tbprodutos.cod_produto = tbUpdCancPV.ItemCode
          WHERE tbUpdCancPV.TipoUpdCanc = 'U'
            AND tbUpdCancPV.STATUS      = 0
          ORDER BY UpdateDate, UniqueKey
   );
   SET xQtdeRegs = xQtdeRegs + (SELECT COUNT(1) FROM tbTMPAtulizaQtde);
   
   #select "AQUI3", count(*) from tbTMPAtulizaQtde; leave BLOCO1;
   #select "AQUI3", tbTMPAtulizaQtde.* from tbTMPAtulizaQtde; leave BLOCO1;
   WHILE EXISTS (SELECT 1 FROM tbTMPAtulizaQtde WHERE flgProcessado = 0) DO
   
      SELECT UniqueKey, UpdateDate, ItemCode, Quantity, 
             SalUnitMsr, NumInSale, InvntryUom,
             emb_estoque, fator_conversao, 
             BaseQty, OpenInvQty
      INTO _UniqueKey, _UpdateDate, _ItemCode, _Quantity,
           _SalUnitMsr, _NumInSale, _InvntryUom,
           _emb_estoque, _fator_conversao,
           xBaseQtyOriginal, xOpenInvQtyOriginal
      FROM tbTMPAtulizaQtde
      WHERE flgProcessado = 0 LIMIT 1;
      SET MENSAGEM = CONCAT("Atualização realizada com sucesso (2) ",_UniqueKey,'=>',_UpdateDate);
      
      #@Reviser David Ruy <2023-07-03>
      #select _SalUnitMsr, _emb_estoque, _Quantity, _NumInSale;
      SET _QtdeEstoqueCli = _Quantity;
      #IF _SalUnitMsr <> _InvntryUom THEN
      IF _SalUnitMsr <> _emb_estoque THEN
         IF _NumInSale > 1 THEN
            SET _QtdeEstoqueCli = _Quantity * _NumInSale;
         ELSE 
            SET _QtdeEstoqueCli = _Quantity / _NumInSale;
         END IF;
      END IF;      
      
      
      #@Reviser David Ruy <2022-03-24>
      IF IFNULL(xOpenInvQtyOriginal,0) > 0 THEN
         SET _QtdeEstoqueCli = xOpenInvQtyOriginal / xBaseQtyOriginal * _Quantity;
      END IF;
      
      #@Reviser David Ruy <2025-02-25>
      #Teoricamente não tem necessidade, visto que no EnviarUpdCancPV, já envio OpenInvQty (QtdeEstoque)
      #UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV
      #SET QtdeEstoque = _QtdeEstoqueCli
      #WHERE UniqueKey  = _UniqueKey
      #  AND UpdateDate = _UpdateDate;
      
      
      UPDATE tbTMPAtulizaQtde
      SET flgProcessado = 1
      WHERE UniqueKey  = _UniqueKey
        AND UpdateDate = _UpdateDate;
      
   END WHILE;
   DROP TEMPORARY TABLE IF EXISTS tbTMPAtulizaQtde;
   SET MENSAGEM = "Atualização realizada com sucesso (3)";
   #select "AQUI4", count(*) from tbTMPAtulizaQtde; leave BLOCO1;
          
          
          
   /************************************************************************************/   
   #@Reviser David Ruy <2021/01/30>
   #Selecionar Registros para atualizar TMS (Transportadora) / Cadastrar Terceiros
   DROP TEMPORARY TABLE IF EXISTS tbTMPAtuTMS;
   CREATE TEMPORARY TABLE tbTMPAtuTMS
          SELECT DISTINCT 
                  tbUpdCancPV.DocumentId, tbUpdCancPV.DocumentType, tbUpdCancPV.DocumentNumber
                 ,tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic
                 ,tbSaidas.cnpj_cpf_cli, tbSaidas.chave_integracao
                 ,tbUpdCancPV.Incoterms, fnTirarCaracteresEspeciais(tbUpdCancPV.TrnspTaxIdNum) cnpjTransp
                 ,tbUpdCancPV.TrnspName nomeTransp
                 ,tbUpdCancPV.Route, tbUpdCancPV.StartTime1, tbUpdCancPV.EndTime1
                 ,tbUpdCancPV.StartTime2, tbUpdCancPV.EndTime2
                 ,tbUpdCancPV.End_Entrega
                 ,tbUpdCancPV.CardCode, tbUpdCancPV.CardName                 
                 ,CONCAT(IFNULL(tbUpdCancPV.AddrTypeS,''), ' ', tbUpdCancPV.StreetS) AS Endereco
                 ,tbUpdCancPV.StreetNoS AS num_ende
                 ,tbUpdCancPV.BuildingS compl_ende
                 ,tbUpdCancPV.BlockS AS bairro_ende
                 ,fnSoNumeros(tbUpdCancPV.ZipCodeS,'') CEP_Ende
                 ,tbUpdCancPV.CityS cidade_ende
                 ,tbUpdCancPV.StateS estado_ende
                 ,tbUpdCancPV.CountryS pais_ende
                 ,tbTopo.NumCPF, tbTopo.NumCNPJ
                 ,0 AS flgProcessado
          FROM of_logistica.tbprog_entregas tbEntregas
          LEFT JOIN of_logistica.tbviagens tbViagens ON 
                    tbViagens.cod_emp    = tbEntregas.cod_emp 
                AND tbViagens.cod_fil    = tbEntregas.cod_fil
                AND tbViagens.ano_viagem = tbEntregas.ano_viagem
                AND tbViagens.num_viagem = tbEntregas.num_viagem
          INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
                     tbSaidas.chave_integracao = tbEntregas.chave_integracao
          INNER JOIN tbintegraSAP_Doc tbTopo ON 
                     tbTopo.cod_emp   = tbSaidas.cod_emp
                 AND tbTopo.cod_fil   = tbSaidas.cod_fil
                 AND tbTopo.ano_solic = tbSaidas.ano_solic
                 AND tbTopo.num_solic = tbSaidas.num_solic
          INNER JOIN tbintegraSAP_UpdCancPV tbUpdCancPV ON
                     tbTopo.DocEntry = tbUpdCancPV.DocumentId
                 AND tbTopo.DocTipo  = tbUpdCancPV.DocumentType 
                 AND tbTopo.DocNum   = tbUpdCancPV.DocumentNumber 
          WHERE tbUpdCancPV.TipoUpdCanc = 'U'
            AND tbUpdCancPV.STATUS      = 0
            /*#AND tbUpdCancPV.TrnspTaxIdNum IS NOT NULL;
            AND (IFNULL(fnTirarCaracteresEspeciais(tbUpdCancPV.TrnspTaxIdNum),'') <> IFNULL(tbTopo.CnpjTransp,'')
             OR IFNULL(tbUpdCancPV.End_Entrega,'') <> IFNULL(tbTopo.End_Entrega,'')
             OR (tbTopo.DueDate <> tbUpdCancPV.DocumentDueDate)
             OR  CONCAT(IFNULL(tbUpdCancPV.AddrTypeS,''),IFNULL(tbUpdCancPV.StreetS,'')
                       ,IFNULL(tbUpdCancPV.StreetNoS,''),IFNULL(tbUpdCancPV.BuildingS,'')
                       ,IFNULL(tbUpdCancPV.BlockS,''),IFNULL(tbUpdCancPV.ZipCodeS,'')
                       ,IFNULL(tbUpdCancPV.CityS,''),IFNULL(tbUpdCancPV.StateS,''),IFNULL(tbUpdCancPV.CountryS,'')) <>
                 CONCAT(IFNULL(tbTopo.AddrTypeS,''),IFNULL(tbTopo.StreetS,'')
                       ,IFNULL(tbTopo.StreetNoS,''),IFNULL(tbTopo.BuildingS,'')
                       ,IFNULL(tbTopo.BlockS,''),IFNULL(tbTopo.ZipCodeS,'')
                       ,IFNULL(tbTopo.CityS,''),IFNULL(tbTopo.StateS,''),IFNULL(tbTopo.CountryS,''))
              OR CONCAT(IFNULL(tbUpdCancPV.StartTime1,''), IFNULL(tbUpdCancPV.EndTime1,''), 
                        IFNULL(tbUpdCancPV.StartTime2,''), IFNULL(tbUpdCancPV.EndTime2,'')) <>
                 CONCAT(IFNULL(tbTopo.StartTime1,''), IFNULL(tbTopo.EndTime1,''), 
                        IFNULL(tbTopo.StartTime2,''), IFNULL(tbTopo.EndTime2,''))
                 )*/;
   SET xQtdeRegs = xQtdeRegs + (SELECT COUNT(1) FROM tbTMPAtuTMS);                 
   SET MENSAGEM = "Atualização realizada com sucesso (4)";
            
            
            
   #@Reviser David Ruy <2020/01/17> 
   #Atualizar Topo de TODOS os Documentos 
   #STATUS = 3 (Processado)
   UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV
   INNER JOIN tbintegraSAP_Doc tbTopo ON 
              tbTopo.DocEntry = tbUpdCancPV.DocumentId
          AND tbTopo.DocTipo  = tbUpdCancPV.DocumentType 
          AND tbTopo.DocNum   = tbUpdCancPV.DocumentNumber 
   SET  tbTopo.DueDate       = tbUpdCancPV.DocumentDueDate
       ,tbTopo.NomeVendedor  = tbUpdCancPV.SlpName
       ,tbTopo.AddrTypeS     = tbUpdCancPV.AddrTypeS
       #,tbTopo.Address2      = tbUpdCancPV.Address2
       ,tbTopo.StreetS       = tbUpdCancPV.StreetS
       ,tbTopo.StreetNoS     = tbUpdCancPV.StreetNoS       
       ,tbTopo.BlockS        = tbUpdCancPV.BlockS
       ,tbTopo.BuildingS     = tbUpdCancPV.BuildingS
       ,tbTopo.CityS         = tbUpdCancPV.CityS
       ,tbTopo.StateS        = tbUpdCancPV.StateS
       ,tbTopo.CountryS      = tbUpdCancPV.CountryS
       ,tbTopo.StateS        = tbUpdCancPV.StateS
       ,tbTopo.ZipCodeS      = tbUpdCancPV.ZipCodeS
       ,tbTopo.TipoFrete     = tbUpdCancPV.Incoterms
       ,tbTopo.CnpjTransp    = fnTirarCaracteresEspeciais(tbUpdCancPV.TrnspTaxIdNum)
       ,tbTopo.NomeTransp    = SUBSTRING(tbUpdCancPV.TrnspName,1,50)
       ,tbTopo.Route      = tbUpdCancPV.Route
       ,tbTopo.StartTime1 = tbUpdCancPV.StartTime1
       ,tbTopo.EndTime1   = tbUpdCancPV.EndTime1
       ,tbTopo.StartTime2 = tbUpdCancPV.StartTime2
       ,tbTopo.EndTime2   = tbUpdCancPV.EndTime2
       ,tbTopo.End_Entrega= tbUpdCancPV.End_Entrega
       ,tbTopo.Observacoes= tbUpdCancPV.Comments
       #Verificar Status Topo para atualizar SLIN (tbdestinatários)
      #Nomes das Variáveis de Endereço SLIN
       #StatusDoc=3 , quanto atualizar coloca 4
       #,tbUpdCancPV.FreeText = CONCAT(TRIM(BOTH FROM tbUpdCancPV.FreeText),IF(tbUpdCancPV.FreeText IS NULL,'','|'),"(0)Atualização automatica Topo")
       ,tbUpdCancPV.FreeText = "(0)Atualização automatica Topo"
   WHERE tbUpdCancPV.TipoUpdCanc = 'U'
     AND tbUpdCancPV.STATUS      = 0;
     #AND tbTopo.cod_emp IS NULL;
   #(Verificar) Alterações que vieram após a criação do registro tbintegraSAP_Doc serão mantidas
   #and tbTopo.dthr_inc <= tbUpdCancPV.UpdateDate;
   SET MENSAGEM = "Atualização realizada com sucesso (5)";
   
   
   
   #@Reviser David Ruy <2021/01/17>
   #Identificar item excluído no SAP 
   #Insere registro tbintegraSAP_UpdCancPV => Quantity=0, Status = 1 (a processar)
   #Update tbIntegraSAP_DocItem->StatusItem = 9
   CALL PROC_INTEGRA_CancelarItemUPD(RESULTADO, MENSAGEM);
   SET MENSAGEM = "Atualização realizada com sucesso (6)";
   
   
   
   
   /****************************************************************************/
   #Atualiza Status dos Registros que sao INCLUSAO (QtdeUpd = 1)
   /****************************************************************************/
   DROP TEMPORARY TABLE IF EXISTS tbTMPUpd;
   CREATE TEMPORARY TABLE tbTMPUpd
          SELECT DocumentNumber, DocumentType, DocumentId, UpdateDate,
                 (SELECT COUNT(DISTINCT UpdateDate) 
                  FROM tbintegraSAP_UpdCancPV tbAux
                  WHERE tbAux.DocumentNumber = tbUpdCancPV.DocumentNumber 
                    AND tbAux.DocumentType   = tbUpdCancPV.DocumentType
                    AND tbAux.DocumentId     = tbUpdCancPV.DocumentId) QtdeUpd
          FROM tbintegraSAP_UpdCancPV tbUpdCancPV
          WHERE tbUpdCancPV.TipoUpdCanc = 'U'
            AND tbUpdCancPV.STATUS      = 0
            AND tbUpdCancPV.cod_emp IS NULL
          GROUP BY DocumentNumber, DocumentType, DocumentId, UpdateDate
          HAVING QtdeUpd = 1;
   SET xQtdeRegs = xQtdeRegs + (SELECT COUNT(1) FROM tbTMPUpd);                 
             
                    
                    
   UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV
   INNER JOIN tbintegraSAP_Doc tbTopo ON 
              tbTopo.DocEntry = tbUpdCancPV.DocumentId
          AND tbTopo.DocTipo  = tbUpdCancPV.DocumentType 
          AND tbTopo.DocNum   = tbUpdCancPV.DocumentNumber 
   INNER JOIN tbintegraSAP_DocItem tbItens ON 
              tbItens.DocEntry = tbTopo.DocEntry
          AND tbItens.DocTipo  = tbTopo.DocTipo 
          AND tbItens.DocNum   = tbTopo.DocNum 
          AND tbItens.LineNum  = tbUpdCancPV.LineNumber   
   INNER JOIN tbTMPUpd ON 
              tbTMPUpd.DocumentNumber = tbUpdCancPV.DocumentNumber 
          AND tbTMPUpd.DocumentType   = tbUpdCancPV.DocumentType   
          AND tbTMPUpd.DocumentId     = tbUpdCancPV.DocumentId
          AND tbTMPUpd.UpdateDate     = tbUpdCancPV.UpdateDate
   SET  tbItens.ItemCode      = tbUpdCancPV.ItemCode
       ,tbItens.BaseQty       = tbUpdCancPV.Quantity
       #,tbItens.OpenInvQty    = IF(tbItens.OpenInvQty IS NULL, NULL, tbUpdCancPV.QtdeEstoque)
       ,tbItens.OpenInvQty    = IFNULL(tbUpdCancPV.QtdeEstoque, IFNULL(tbItens.OpenInvQty/tbItens.BaseQty*tbUpdCancPV.Quantity, tbUpdCancPV.Quantity))
       ,tbItens.salUnitMsr    = tbUpdCancPV.SalUnitMsr
       ,tbItens.NumInSale     = tbUpdCancPV.NumInSale
       ,tbItens.invntryUom    = tbUpdCancPV.InvntryUom
       ,tbItens.Price         = tbUpdCancPV.Price
       ,tbItens.DollarQuote   = tbUpdCancPV.DollarQuote
       ,tbUpdCancPV.cod_emp   = tbTopo.cod_emp
       ,tbUpdCancPV.cod_fil   = tbTopo.cod_fil
       ,tbUpdCancPV.ano_solic = tbTopo.ano_solic
       ,tbUpdCancPV.num_solic = tbTopo.num_solic    
       #,tbUpdCancPV.FreeText  = CONCAT(TRIM(BOTH FROM tbUpdCancPV.FreeText),IF(tbUpdCancPV.FreeText IS NULL,'','|'),"(0)Atu Item")
       ,tbUpdCancPV.FreeText  = IF(tbItens.ItemCode = tbUpdCancPV.ItemCode,"(A)Atu Item","(X)Atu Item")
       #@Reviser David Ruy <2022-03-28>
       #,tbUpdCancPV.STATUS    = IF(tbTopo.U_RSD_RplOrder IS NULL, 3, 1)
   WHERE tbUpdCancPV.TipoUpdCanc = 'U'
     AND tbUpdCancPV.STATUS      = 0
     AND tbUpdCancPV.cod_emp IS NULL;
   DROP TEMPORARY TABLE IF EXISTS tbTMPUpd;
   SET MENSAGEM = "Atualização realizada com sucesso (7)";
     
 
     
     
   #@Reviser David Ruy <2021-04-29>
   #Verifica Itens NOVOS para inserir na tbintegraSAP_DocItem
   DROP TEMPORARY TABLE IF EXISTS tbTMPIncluir;
   CREATE TEMPORARY TABLE tbTMPIncluir
   SELECT tbUpdCancPV.*, tbItem.DocEntry, 0 FlgProcessado, 
          tbItem.OpenInvQty OpenInvQtyOriginal, tbItem.BaseQty BaseQtyOriginal,
          tbItem.OONE_PROMO, tbItem.OONE_USO_CONS
   FROM tbintegraSAP_UpdCancPV tbUpdCancPV
   INNER JOIN tbintegraSAP_Doc tbTopo ON
             tbTopo.DocEntry = tbUpdCancPV.DocumentId
         AND tbTopo.DocTipo  = tbUpdCancPV.DocumentType
         AND tbTopo.DocNum   = tbUpdCancPV.DocumentNumber
   LEFT JOIN tbintegraSAP_DocItem tbItem ON
             tbItem.DocEntry = tbUpdCancPV.DocumentId
         AND tbItem.DocTipo  = tbUpdCancPV.DocumentType
         AND tbItem.DocNum   = tbUpdCancPV.DocumentNumber
         AND tbItem.LineNum  = tbUpdCancPV.LineNumber
   WHERE tbUpdCancPV.TipoUpdCanc = 'U'
     AND tbUpdCancPV.STATUS = 0
     AND tbItem.DocEntry IS NULL;
     

   START TRANSACTION;  
   WHILE EXISTS (SELECT 1 FROM tbTMPIncluir WHERE FlgProcessado = 0) DO
   
      SET xOpenInvQtyOriginal = NULL;
      SET xBaseQtyOriginal = NULL;
      
      SELECT UniqueKey, '999999', DocumentId, DocumentType, DocumentNumber, LineNumber, ItemCode,
             Quantity, NULL, NULL,  NULL, Price, DollarQuote, NULL, NULL, Comments, 
             Description, BuyUnitMsr, SalUnitMsr, InvntryUom, ManBtchNum, ManSerNum,
             UgpEntry, UomCode, unitMsr, OpenInvQty, OpenInvQtyOriginal, BaseQtyOriginal, 
             OONE_PROMO, OONE_USO_CONS,
             NumInSale, BatchNumber_Code
      INTO xUniqueKey, xCodUsuario, xDocEntry, xDocTipo, xDocNum, xLineNum, xItemCode, 
           xBaseQty, xPlannedQty, xIssuedQty, xWhareHouse, xPrice, xDollarQuote, xIssueType, xStatusItem, xObservacoes,
           xDescrProduto, xEmbCompras, xEmbVendas, xEmbEstoque, xManBtchNum, xManSerNum, 
           xUgpEntry, xUomCode, xunitMsr, xOpenInvQty, xOpenInvQtyOriginal, xBaseQtyOriginal, 
           xflg_PROMO, xflg_USO_CONS,
           xNumInSale, xBatchNumbersCode
      FROM tbTMPIncluir 
      WHERE FlgProcessado = 0 LIMIT 1;
      
      #@Reviser David Ruy <2022-03-24>
      IF IFNULL(xOpenInvQtyOriginal,0) > 0 THEN
         SET xOpenInvQty = xOpenInvQtyOriginal / xBaseQtyOriginal * xBaseQty;
      END IF;
      
      CALL PROC_INTEGRA_EnviarDocEntry_Item(xCodUsuario, xDocEntry, xDocTipo, xDocNum, xLineNum, xItemCode, 
                    xBaseQty, xPlannedQty, xIssuedQty, xWhareHouse, xPrice, xDollarQuote, 
                    #
                    xUsage, xCFOPCode, xTaxCode,
                    #
                    xUgpEntry, xUomCode, xunitMsr, IFNULL(xOpenInvQty, xBaseQty),
                    xflg_PROMO, xflg_USO_CONS,
                    #
                    xIssueType, xStatusItem, xObservacoes,
                    xDescrProduto, xEmbCompras, xEmbVendas, xEmbEstoque, xManBtchNum, xManSerNum, 
                    xNumInSale, xBatchNumbersCode, @R, @M);
                    
      UPDATE tbTMPIncluir
      SET FlgProcessado = 1
      WHERE UniqueKey = xUniqueKey;
      
      #@Reviser David Ruy <2022-03-24> StatusItem = 2 = Item Novo
      UPDATE tbintegraSAP_DocItem
      SET StatusAnt  = StatusItem
         ,StatusItem = 2
      WHERE DocEntry = xDocEntry
        AND DocTipo  = xDocTipo
        AND DocNum   = xDocNum
        AND LineNum  = xLineNum;
      
      #Força Reprocessar a GSM para inserir o ITEM
      UPDATE tbintegraSAP_Doc
      SET StatusAnt = StatusDoc
         ,StatusDoc = 1
      WHERE DocEntry = xDocEntry
        AND DocTipo  = xDocTipo
        AND DocNum   = xDocNum; 
      
      #Força Reabrir Picking
      UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV
      SET tbUpdCancPV.FreeText  = "(7.5)Inc Item"
         ,tbUpdCancPV.STATUS    = 1
      WHERE tbUpdCancPV.TipoUpdCanc = 'U'
        AND tbUpdCancPV.STATUS      = 0
        AND tbUpdCancPV.UniqueKey   = xUniqueKey;
           
   END WHILE;
   
   DROP TEMPORARY TABLE tbTMPIncluir;
   SET MENSAGEM = CONCAT("Atualização realizada com sucesso (7.5) ");
   
   
   
   
   /****************************************************************************/
   #Atualiza Status dos Registros que ainda não foram para o WMS
   #@Reviser David Ruy <2022-04-03> Atualização StatusItem = 2 (Insert)
   /****************************************************************************/
   UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV
   INNER JOIN tbintegraSAP_Doc tbTopo ON 
              tbTopo.DocEntry = tbUpdCancPV.DocumentId
          AND tbTopo.DocTipo  = tbUpdCancPV.DocumentType 
          AND tbTopo.DocNum   = tbUpdCancPV.DocumentNumber 
   INNER JOIN tbintegraSAP_DocItem tbItens ON 
              tbItens.DocEntry = tbTopo.DocEntry
          AND tbItens.DocTipo  = tbTopo.DocTipo 
          AND tbItens.DocNum   = tbTopo.DocNum 
          AND tbItens.LineNum  = tbUpdCancPV.LineNumber   
   SET  tbItens.ItemCode      = tbUpdCancPV.ItemCode
       ,tbItens.BaseQty       = tbUpdCancPV.Quantity
       #,tbItens.OpenInvQty    = IF(tbItens.OpenInvQty IS NULL, NULL, tbUpdCancPV.QtdeEstoque)
       ,tbItens.OpenInvQty    = IFNULL(tbUpdCancPV.QtdeEstoque, IFNULL(tbItens.OpenInvQty/tbItens.BaseQty*tbUpdCancPV.Quantity, tbUpdCancPV.Quantity))
       ,tbItens.salUnitMsr    = tbUpdCancPV.SalUnitMsr
       ,tbItens.NumInSale     = tbUpdCancPV.NumInSale
       ,tbItens.invntryUom    = tbUpdCancPV.InvntryUom
       ,tbItens.Price         = tbUpdCancPV.Price
       ,tbItens.DollarQuote   = tbUpdCancPV.DollarQuote
       ,tbItens.StatusAnt     = tbItens.StatusItem
       ,tbItens.StatusItem    = 2 #(Inclusão de Item)
       #,tbUpdCancPV.FreeText  = CONCAT(TRIM(BOTH FROM tbUpdCancPV.FreeText),IF(tbUpdCancPV.FreeText IS NULL,'','|'),"(0)Atu Item")
       ,tbUpdCancPV.FreeText  = IF(tbItens.ItemCode = tbUpdCancPV.ItemCode,"(1)Atu Item","(0)Atu Item")
       #@Reviser David Ruy <2022-03-28>
       #,tbUpdCancPV.STATUS    = 3
   WHERE tbUpdCancPV.TipoUpdCanc = 'U'
     AND tbUpdCancPV.STATUS      = 0
     AND tbTopo.cod_emp IS NULL;
   SET MENSAGEM = "Atualização realizada com sucesso (8)";
     
     
     
     
   /************************************************************************************/   
   #@Reviser David Ruy <2021/01/30>
   #Atualizar TMS (Transportadora) / Cadastrar Terceiros           
   WHILE EXISTS (SELECT 1 FROM tbTMPAtuTMS WHERE flgProcessado = 0) DO
      SELECT  cod_emp, cod_fil, ano_solic, num_solic
             ,cnpj_cpf_cli, chave_integracao
             ,Incoterms, cnpjTransp, nomeTransp
             ,CardCode, CardName, NumCNPJ, NumCPF
             ,Endereco, num_ende, compl_ende, bairro_ende, CEP_Ende, cidade_ende, estado_ende, pais_ende
             ,StartTime1, EndTime1, StartTime2, EndTime2, End_Entrega
      INTO  xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic
           ,xCNPJCPFCLI, xchave_integracao
           ,xTipoFrete, xCnpjTransp, xNomeTransp
           ,xCardCode, xCardName, xNumCNPJ, xNumCPF
           ,xEndereco, xNumEnde, xComplEnde, xBairroEnde, xCepEnde, xCidadeEnde, xUFEnde, xPaisEnde
           ,xhora1_entrega, xhora2_entrega, xhora3_entrega, xhora4_entrega, xEnd_Entrega
      FROM tbTMPAtuTMS
      WHERE flgProcessado = 0 LIMIT 1;
      SET MENSAGEM = CONCAT("Atualização realizada com sucesso (9) ",xCodEmpWMS, '/',xCodFilWMS, '-',xAnoSolic, '.',xNumSolic);
      SET xNomeTransp = SUBSTRING(xNomeTransp,1,50);
      SET xCepEnde = SUBSTRING(fnTirarCaracteresEspeciais(xCepEnde),1,8);
      
      #Atualizar cadastro de Transportadores
      #@David Ruy 2023/03/03
      IF IFNULL(xCnpjTransp,'') <> '' THEN
         CALL PROC_INTEGRA_CAD_Terceiro('999999', xCNPJCPFCLI, xCnpjTransp, '1', xNomeTransp, xNomeTransp, 1, @R, @M);
         SET MENSAGEM = CONCAT("Atualização realizada com sucesso (10) ",xCNPJCPFCLI,'/',xCnpjTransp," :",@R, @M);
      ELSE
         SET xNomeTransp = NULL;
      END IF;
      
      #Endereço de Remessa
      #IF IFNULL(xEnd_Entrega,'') <> '' THEN
      #   CALL PROC_INTEGRA_MontaEndereco(xEnd_Entrega, @xLog, xEndereco, xNumEnde, xComplEnde, xBairroEnde, xCepEnde, xCidadeEnde, xUFEnde, @xPaisEnde);
      #   SET xEndereco   = CONCAT(@xLog,' ',xEndereco);
         SET xEndereco   = IFNULL(xEndereco,'');
         SET xNumEnde    = IFNULL(xNumEnde, '');
         SET xComplEnde  = IFNULL(xComplEnde, '');
         SET xBairroEnde = IFNULL(xBairroEnde, '');
         SET xCidadeEnde = IFNULL(xCidadeEnde, '');
         SET xCepEnde    = IFNULL(xCepEnde, '');
         SET xUFEnde     = IFNULL(xUFEnde, '');
         SET xPaisEnde   = IFNULL(xPaisEnde, '');
         SET xCepEnde    = fnSoNumeros(xCepEnde,'');
      #END IF;
      
            
      SET xNumCPF  = of_logistica.fnTirarCaracteresEspeciais(xNumCPF);
      SET xNumCNPJ = of_logistica.fnTirarCaracteresEspeciais(xNumCNPJ);
      SET xNumCPFouCNPJ = IFNULL(IFNULL(xNumCPF,xNumCNPJ),'');
      #SET xTipoPessoa = IF(LENGTH(xNumCPFouCNPJ)=0,'',IF(LENGTH(xNumCPFouCNPJ)=14,'J','F'));
      SET xTipoPessoa = IF(LENGTH(IFNULL(xNumCPF,''))>0,'F', IF(LENGTH(IFNULL(xNumCNPJ,''))>0,'J', ''));      
      
      # Atualizar cadastro de destinatarios
      CALL PROC_INTEGRA_CAD_Destinatario('999999', xCNPJCPFCLI, xCardCode, xTipoPessoa, 
                         SUBSTRING(xCardName,1,60), SUBSTRING(xCardName,1,50),
                         IFNULL(@oInscrEstadual,'123'), IFNULL(@oIndicadorIE,9),
                         xEndereco, xNumEnde, xComplEnde, xBairroEnde,
                         xCidadeEnde, xUFEnde, xCepEnde, @oContato01,
                         @oFone01, @oEmail01, @oStatusAtivo, 
                         xhora1_entrega, xhora2_entrega, xhora3_entrega, xhora4_entrega,
                         # Parametros de Retorno
                         @RESULTADO, @MENSAGEM);
      SET MENSAGEM = CONCAT("Atualização realizada com sucesso (11) ",xCNPJCPFCLI,'/',xCardCode," :",@RESULTADO, @MENSAGEM);
                         
      # Alimentar TMS com o pedido
      # não foi habilitado para ter performance, caso seja necessário atualizar mais campos
      # então habilitar essa rotina e desabilizar o update que está fora do While logo abaixo
      #CALL PROC_INTEGRA_TMS_GERAR_ENTREGAS(xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xTipoFrete, xCnpjTransp, xNomeTransp, @RESULTADO, @MENSAGEM);
      #SET MENSAGEM = CONCAT("Atualização realizada com sucesso (12) ",xCodEmpWMS, '/',xCodFilWMS, '-',xAnoSolic, '.',xNumSolic,' :',@RESULTADO, @MENSAGEM);
      
      
      #@Reviser David Ruy <2022/03/08> Este bloco estava abaixo do While
      /*******************************************************************************/
      #@Reviser David Ruy <2021/01/30>
      #Atualizar Transportadora / Endereço no TMS
      UPDATE of_logistica.tbprog_entregas tbEntregas
      LEFT JOIN of_logistica.tbviagens tbViagens ON 
                tbViagens.cod_emp    = tbEntregas.cod_emp 
            AND tbViagens.cod_fil    = tbEntregas.cod_fil
            AND tbViagens.ano_viagem = tbEntregas.ano_viagem
            AND tbViagens.num_viagem = tbEntregas.num_viagem
      INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
                 tbSaidas.chave_integracao = tbEntregas.chave_integracao
      INNER JOIN tbintegraSAP_Doc tbTopo ON 
                 tbTopo.cod_emp   = tbSaidas.cod_emp
             AND tbTopo.cod_fil   = tbSaidas.cod_fil
             AND tbTopo.ano_solic = tbSaidas.ano_solic
             AND tbTopo.num_solic = tbSaidas.num_solic
      #INNER JOIN tbintegraSAP_UpdCancPV tbUpdCancPV ON
      #           tbTopo.DocEntry = tbUpdCancPV.DocumentId
      #       AND tbTopo.DocTipo  = tbUpdCancPV.DocumentType 
      #       AND tbTopo.DocNum   = tbUpdCancPV.DocumentNumber 
      INNER JOIN tbTMPAtuTMS ON
                 tbTopo.DocEntry = tbTMPAtuTMS.DocumentId
             AND tbTopo.DocTipo  = tbTMPAtuTMS.DocumentType 
             AND tbTopo.DocNum   = tbTMPAtuTMS.DocumentNumber 
      SET tbEntregas.cnpj_cpf_terceiro = IF(tbTMPAtuTMS.cnpjTransp='',NULL,tbTMPAtuTMS.cnpjTransp)
         ,tbViagens.cnpj_cpf_terceiro  = IF(tbTMPAtuTMS.cnpjTransp='',NULL,tbTMPAtuTMS.cnpjTransp)
         ,tbEntregas.ende_destino      = SUBSTRING(CONCAT(xEndereco,' ',xNumEnde),1,50)
         ,tbEntregas.compl_ende        = SUBSTRING(xComplEnde,1,20)
         ,tbEntregas.bairro_destino    = xBairroEnde
         ,tbEntregas.cidade_destino    = xCidadeEnde
         ,tbEntregas.cep_ende          = xCepEnde
         ,tbEntregas.estado_destino    = xUFEnde
         ,tbEntregas.dthr_alt          = NOW()
         ,tbEntregas.usu_alt           = '999999'
      WHERE tbEntregas.chave_integracao = xchave_integracao;
      SET MENSAGEM = CONCAT("Atualização realizada com sucesso (13) ");
      /*******************************************************************************/
      
      
      UPDATE tbTMPAtuTMS
      SET flgProcessado = 1
         ,Endereco    = xEndereco 
         ,num_ende    = xNumEnde
         ,compl_ende  = xComplEnde
         ,bairro_ende = xBairroEnde
         ,CEP_Ende    = xCepEnde
         ,cidade_ende = xCidadeEnde
         ,estado_ende = xUFEnde
         ,pais_ende   = xPaisEnde          
      WHERE chave_integracao = xchave_integracao;
      
   END WHILE;
      
   
   #drop table if exists xtbTMPAtuTMS;
   #CREATE TABLE xtbTMPAtuTMS SELECT * FROM tbTMPAtuTMS;
   DROP TEMPORARY TABLE IF EXISTS tbTMPAtuTMS;
   /**************************************************************************************/
   
   
   
   
   /****************************************************************************/
   #Atualiza Status dos Registros que já foram para o WMS mas ainda não tem aconselhamento
   /****************************************************************************/
   UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV
   INNER JOIN tbintegraSAP_Doc tbTopo ON 
              tbTopo.DocEntry = tbUpdCancPV.DocumentId
          AND tbTopo.DocTipo  = tbUpdCancPV.DocumentType 
          AND tbTopo.DocNum   = tbUpdCancPV.DocumentNumber 
   INNER JOIN tbintegraSAP_DocItem tbItens ON 
              tbItens.DocEntry = tbTopo.DocEntry
          AND tbItens.DocTipo  = tbTopo.DocTipo 
          AND tbItens.DocNum   = tbTopo.DocNum 
          AND tbItens.LineNum  = tbUpdCancPV.LineNumber   
   INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
            tbSaidas.cod_emp   = tbTopo.cod_emp 
        AND tbSaidas.cod_fil   = tbTopo.cod_fil
        AND tbSaidas.ano_solic = tbTopo.ano_solic 
        AND tbSaidas.num_solic = tbTopo.num_solic
   INNER JOIN of_logistica.tbsolic_saidas_item tbSaidasItem ON
            tbSaidasItem.cod_emp   = tbItens.cod_emp 
        AND tbSaidasItem.cod_fil   = tbItens.cod_fil
        AND tbSaidasItem.ano_solic = tbItens.ano_solic 
        AND tbSaidasItem.num_solic = tbItens.num_solic
        AND tbSaidasItem.num_item  = tbItens.num_item          
   SET  tbItens.ItemCode      = tbUpdCancPV.ItemCode
       ,tbItens.BaseQty       = tbUpdCancPV.Quantity
       #,tbItens.OpenInvQty    = IF(tbItens.OpenInvQty IS NULL, NULL, tbUpdCancPV.QtdeEstoque)
       ,tbItens.OpenInvQty    = IFNULL(tbUpdCancPV.QtdeEstoque, IFNULL(tbItens.OpenInvQty/tbItens.BaseQty*tbUpdCancPV.Quantity, tbUpdCancPV.Quantity))
       ,tbItens.salUnitMsr    = tbUpdCancPV.SalUnitMsr
       ,tbItens.NumInSale     = tbUpdCancPV.NumInSale
       ,tbItens.invntryUom    = tbUpdCancPV.InvntryUom
       ,tbItens.Price         = tbUpdCancPV.Price
       ,tbItens.DollarQuote   = tbUpdCancPV.DollarQuote
       ,tbItens.StatusAnt     = tbItens.StatusItem
       ,tbItens.StatusItem    = IF(tbUpdCancPV.QtdeEstoque = tbSaidasItem.qtde_est AND 
                                   tbUpdCancPV.ItemCode    = tbSaidasItem.cod_produto,0,1)
       #,tbUpdCancPV.FreeText  = CONCAT(TRIM(BOTH FROM tbUpdCancPV.FreeText),IF(tbUpdCancPV.FreeText IS NULL,'','|'),"(1)Atu Item")
       ,tbUpdCancPV.FreeText  = IF(tbUpdCancPV.QtdeEstoque = tbSaidasItem.qtde_est AND
                                   tbUpdCancPV.ItemCode    = tbSaidasItem.cod_produto,"(1.3)Atu Item","(1.1)Atu Item")
       ,tbUpdCancPV.STATUS    = IF(tbUpdCancPV.QtdeEstoque = tbSaidasItem.qtde_est AND 
                                   tbUpdCancPV.ItemCode    = tbSaidasItem.cod_produto,3,1)
       #Reviser David Ruy <2022-04-06>
       ,tbUpdCancPV.cod_emp   = tbTopo.cod_emp
       ,tbUpdCancPV.cod_fil   = tbTopo.cod_fil
       ,tbUpdCancPV.ano_solic = tbTopo.ano_solic
       ,tbUpdCancPV.num_solic = tbTopo.num_solic    
   WHERE tbUpdCancPV.TipoUpdCanc = 'U'
     AND tbUpdCancPV.STATUS      = 0
     AND tbSaidasItem.dthr_aconselhamento IS NULL;
   SET MENSAGEM = CONCAT("Atualização realizada com sucesso (14) ");
     
     
     
   /****************************************************************************/
   #Atualiza Status dos Registros que já foram para o WMS mas ainda não iniciaram a separação
   /****************************************************************************/
   UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV
   INNER JOIN tbintegraSAP_Doc tbTopo ON 
              tbTopo.DocEntry = tbUpdCancPV.DocumentId
          AND tbTopo.DocTipo  = tbUpdCancPV.DocumentType 
          AND tbTopo.DocNum   = tbUpdCancPV.DocumentNumber 
   INNER JOIN tbintegraSAP_DocItem tbItens ON 
              tbItens.DocEntry = tbTopo.DocEntry
          AND tbItens.DocTipo  = tbTopo.DocTipo 
          AND tbItens.DocNum   = tbTopo.DocNum 
          AND tbItens.LineNum  = tbUpdCancPV.LineNumber   
   INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
            tbSaidas.cod_emp   = tbTopo.cod_emp 
        AND tbSaidas.cod_fil   = tbTopo.cod_fil
        AND tbSaidas.ano_solic = tbTopo.ano_solic 
        AND tbSaidas.num_solic = tbTopo.num_solic
   INNER JOIN of_logistica.tbsolic_saidas_item tbSaidasItem ON
            tbSaidasItem.cod_emp   = tbItens.cod_emp 
        AND tbSaidasItem.cod_fil   = tbItens.cod_fil
        AND tbSaidasItem.ano_solic = tbItens.ano_solic 
        AND tbSaidasItem.num_solic = tbItens.num_solic
        AND tbSaidasItem.num_item  = tbItens.num_item          
   SET  tbItens.BaseQty       = tbUpdCancPV.Quantity
       #,tbItens.OpenInvQty    = IF(tbItens.OpenInvQty IS NULL, NULL, tbUpdCancPV.QtdeEstoque)    
       ,tbItens.OpenInvQty    = IFNULL(tbUpdCancPV.QtdeEstoque, IFNULL(tbItens.OpenInvQty/tbItens.BaseQty*tbUpdCancPV.Quantity, tbUpdCancPV.Quantity))
       ,tbItens.salUnitMsr    = tbUpdCancPV.SalUnitMsr
       ,tbItens.NumInSale     = tbUpdCancPV.NumInSale
       ,tbItens.invntryUom    = tbUpdCancPV.InvntryUom
       ,tbItens.Price         = tbUpdCancPV.Price
       ,tbItens.DollarQuote   = tbUpdCancPV.DollarQuote
       ,tbItens.StatusAnt     = tbItens.StatusItem
       ,tbItens.StatusItem    = IF(tbUpdCancPV.QtdeEstoque = tbSaidasItem.qtde_est,0,1)
       #,tbUpdCancPV.FreeText  = CONCAT(TRIM(BOTH FROM tbUpdCancPV.FreeText),IF(tbUpdCancPV.FreeText IS NULL,'','|'),"(2)Atu Item")
       ,tbUpdCancPV.FreeText  = IF(tbUpdCancPV.QtdeEstoque = tbSaidasItem.qtde_est,"(2.3)Atu Item","(2.1)Atu Item")
       ,tbUpdCancPV.STATUS    = IF(tbUpdCancPV.QtdeEstoque = tbSaidasItem.qtde_est,3,1)
       #Reviser David Ruy <2022-04-06>
       ,tbUpdCancPV.cod_emp   = tbTopo.cod_emp
       ,tbUpdCancPV.cod_fil   = tbTopo.cod_fil
       ,tbUpdCancPV.ano_solic = tbTopo.ano_solic
       ,tbUpdCancPV.num_solic = tbTopo.num_solic    
   WHERE tbUpdCancPV.TipoUpdCanc = 'U'
     AND tbUpdCancPV.STATUS      = 0
     AND tbSaidasItem.dthr_aconselhamento IS NOT NULL
     #Reviser <2022-04-06> David Ruy - Não importa se já iniciou a baixa
     #AND tbSaidasItem.dthr_inicio_baixa_geral IS NULL
     AND NOT EXISTS (SELECT 1 FROM of_logistica.tbsolic_saidas_item_integra_alteracao tbAlt 
                     WHERE tbAlt.UniqueKey = tbUpdCancPV.UniqueKey 
                       AND tbAlt.dthr_realizado IS NULL);
   SET MENSAGEM = CONCAT("Atualização realizada com sucesso (15) ");
     
     
   
   #@Reviser David Ruy <2020-12-18>
   #Quando separa com divergencia, a integração atualiza o pedido no SAP, com essa atualização, 
   #um registro de alteração é gerado, essa rotina despresa os logs de alteração gerados pela atualização 
   #automatica do pedido pela integração.
   UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV
   INNER JOIN tbintegraSAP_Doc ON 
               tbintegraSAP_Doc.DocEntry = tbUpdCancPV.DocumentId
           AND tbintegraSAP_Doc.DocNum   = tbUpdCancPV.DocumentNumber
           AND tbintegraSAP_Doc.DocTipo  = tbUpdCancPV.DocumentType
   INNER JOIN tbintegraSAP_DocItem ON 
               tbintegraSAP_DocItem.DocEntry = tbUpdCancPV.DocumentId
           AND tbintegraSAP_DocItem.DocNum   = tbUpdCancPV.DocumentNumber
           AND tbintegraSAP_DocItem.DocTipo  = tbUpdCancPV.DocumentType
           AND tbintegraSAP_DocItem.LineNum  = tbUpdCancPV.LineNumber
   LEFT JOIN of_logistica.tbsolic_saidas_item_integra_alteracao tbAlt ON
            tbAlt.UniqueKey = tbUpdCancPV.UniqueKey
   INNER JOIN of_logistica.tbsolic_saidas_item tbSaidasItem ON
            tbSaidasItem.cod_emp   = tbintegraSAP_DocItem.cod_emp 
        AND tbSaidasItem.cod_fil   = tbintegraSAP_DocItem.cod_fil
        AND tbSaidasItem.ano_solic = tbintegraSAP_DocItem.ano_solic 
        AND tbSaidasItem.num_solic = tbintegraSAP_DocItem.num_solic
        AND tbSaidasItem.num_item  = tbintegraSAP_DocItem.num_item
   INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
            tbSaidas.cod_emp   = tbSaidasItem.cod_emp 
        AND tbSaidas.cod_fil   = tbSaidasItem.cod_fil
        AND tbSaidas.ano_solic = tbSaidasItem.ano_solic 
        AND tbSaidas.num_solic = tbSaidasItem.num_solic
   SET tbUpdCancPV.cod_emp   = tbintegraSAP_DocItem.cod_emp
      ,tbUpdCancPV.cod_fil   = tbintegraSAP_DocItem.cod_fil
      ,tbUpdCancPV.ano_solic = tbintegraSAP_DocItem.ano_solic
      ,tbUpdCancPV.num_solic = tbintegraSAP_DocItem.num_solic
      ,tbUpdCancPV.num_item  = tbintegraSAP_DocItem.num_item
      ,tbUpdCancPV.FreeText  = "Exclusão automatica(1) - Solicitação de alteração Duplicada"
      ,tbUpdCancPV.STATUS    = 3 
       #Reviser David Ruy <2022-04-06>
       ,tbUpdCancPV.cod_emp   = tbintegraSAP_Doc.cod_emp
       ,tbUpdCancPV.cod_fil   = tbintegraSAP_Doc.cod_fil
       ,tbUpdCancPV.ano_solic = tbintegraSAP_Doc.ano_solic
       ,tbUpdCancPV.num_solic = tbintegraSAP_Doc.num_solic    
   WHERE tbUpdCancPV.TipoUpdCanc = 'U'
     AND tbUpdCancPV.STATUS      = 0
     #AND tbintegraSAP_UpdCancPV.flg_deleted = 0 
     #Quantidade Alteração = Qtde Pedido
     AND tbUpdCancPV.QtdeEstoque = tbSaidasItem.real_est2
     AND tbintegraSAP_Doc.StatusDoc = 6
     AND tbSaidas.status_processo >= 8;
   SET MENSAGEM = CONCAT("Atualização realizada com sucesso (16) ");
     
     
     
     
   #@Reviser David Ruy <2021-06-21>
   #GSM´s encerradas com alteração posterior ao Retorno SAP para Faturamento
   UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV
   INNER JOIN tbintegraSAP_Doc tbTopo ON 
              tbTopo.DocEntry = tbUpdCancPV.DocumentId
          AND tbTopo.DocTipo  = tbUpdCancPV.DocumentType 
          AND tbTopo.DocNum   = tbUpdCancPV.DocumentNumber 
   INNER JOIN tbintegraSAP_DocItem tbItens ON 
              tbItens.DocEntry = tbTopo.DocEntry
          AND tbItens.DocTipo  = tbTopo.DocTipo 
          AND tbItens.DocNum   = tbTopo.DocNum 
          AND tbItens.LineNum  = tbUpdCancPV.LineNumber   
   INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
            tbSaidas.cod_emp   = tbTopo.cod_emp 
        AND tbSaidas.cod_fil   = tbTopo.cod_fil
        AND tbSaidas.ano_solic = tbTopo.ano_solic 
        AND tbSaidas.num_solic = tbTopo.num_solic
   INNER JOIN of_logistica.tbsolic_saidas_item tbSaidasItem ON
            tbSaidasItem.cod_emp   = tbItens.cod_emp 
        AND tbSaidasItem.cod_fil   = tbItens.cod_fil
        AND tbSaidasItem.ano_solic = tbItens.ano_solic 
        AND tbSaidasItem.num_solic = tbItens.num_solic
        AND tbSaidasItem.num_item  = tbItens.num_item          
   SET  tbItens.BaseQty       = tbUpdCancPV.Quantity
       #,tbItens.OpenInvQty    = IF(tbItens.OpenInvQty IS NULL, NULL, tbUpdCancPV.QtdeEstoque)
       ,tbItens.OpenInvQty    = IFNULL(tbUpdCancPV.QtdeEstoque, IFNULL(tbItens.OpenInvQty/tbItens.BaseQty*tbUpdCancPV.Quantity, tbUpdCancPV.Quantity))
       ,tbItens.salUnitMsr    = tbUpdCancPV.SalUnitMsr
       ,tbItens.NumInSale     = tbUpdCancPV.NumInSale
       ,tbItens.invntryUom    = tbUpdCancPV.InvntryUom
       ,tbItens.Price         = tbUpdCancPV.Price
       ,tbItens.DollarQuote   = tbUpdCancPV.DollarQuote
       ,tbUpdCancPV.FreeText  = "(2.4)Atu Item"
       ,tbUpdCancPV.STATUS    = 1
       #Reviser David Ruy <2022-04-06>
       ,tbUpdCancPV.cod_emp   = tbTopo.cod_emp
       ,tbUpdCancPV.cod_fil   = tbTopo.cod_fil
       ,tbUpdCancPV.ano_solic = tbTopo.ano_solic
       ,tbUpdCancPV.num_solic = tbTopo.num_solic    
   WHERE tbUpdCancPV.TipoUpdCanc = 'U'
     AND tbUpdCancPV.STATUS      = 0
     AND tbUpdCancPV.QtdeEstoque <> tbSaidasItem.real_est2
     AND tbTopo.StatusDoc = 6
     AND tbSaidas.status_processo >= 8;
   SET MENSAGEM = CONCAT("Atualização realizada com sucesso (16.6) ");     
     
     
     
     
     
   #Despresa LOG de alterações no SLIN que estão em aberto
   #Rotina que trata alterações irá gerar um novo log
   UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV
   INNER JOIN tbintegraSAP_DocItem ON 
               tbintegraSAP_DocItem.DocEntry = tbUpdCancPV.DocumentId
           AND tbintegraSAP_DocItem.DocNum   = tbUpdCancPV.DocumentNumber
           AND tbintegraSAP_DocItem.DocTipo  = tbUpdCancPV.DocumentType
           AND tbintegraSAP_DocItem.LineNum  = tbUpdCancPV.LineNumber
   INNER JOIN of_logistica.tbsolic_saidas_item_integra_alteracao tbAlt ON
              tbAlt.UniqueKey = tbUpdCancPV.UniqueKey
   SET  tbAlt.dthr_realizado = NOW(), tbAlt.flg_realizado = 1, tbAlt.usu_realizado = '999999'
       ,tbUpdCancPV.STATUS   = 1
       #,tbUpdCancPV.FreeText  = CONCAT(TRIM(BOTH FROM tbUpdCancPV.FreeText),IF(tbUpdCancPV.FreeText IS NULL,'','|'),"(3)Atu Item")
       ,tbUpdCancPV.FreeText = "(3)Atu Item"
       #Reviser David Ruy <2022-04-06>
       ,tbUpdCancPV.cod_emp   = tbintegraSAP_DocItem.cod_emp
       ,tbUpdCancPV.cod_fil   = tbintegraSAP_DocItem.cod_fil
       ,tbUpdCancPV.ano_solic = tbintegraSAP_DocItem.ano_solic
       ,tbUpdCancPV.num_solic = tbintegraSAP_DocItem.num_solic    
   WHERE tbUpdCancPV.TipoUpdCanc = 'U'
     AND tbUpdCancPV.STATUS = 0
     AND tbAlt.dthr_realizado IS NULL;
   SET MENSAGEM = CONCAT("Atualização realizada com sucesso (17) ");
   
   
   /*
   UPDATE tbintegraSAP_UpdCancPV
   INNER JOIN tbintegraSAP_DocItem ON 
               tbintegraSAP_DocItem.DocEntry = tbintegraSAP_UpdCancPV.DocumentId
           AND tbintegraSAP_DocItem.DocNum   = tbintegraSAP_UpdCancPV.DocumentNumber
           AND tbintegraSAP_DocItem.DocTipo  = tbintegraSAP_UpdCancPV.DocumentType
           AND tbintegraSAP_DocItem.LineNum  = tbintegraSAP_UpdCancPV.LineNumber
   LEFT JOIN of_logistica.tbsolic_saidas_item_integra_alteracao tbAlt ON
            tbAlt.UniqueKey = tbintegraSAP_UpdCancPV.UniqueKey
   INNER JOIN of_logistica.tbsolic_saidas_item tbSaidasItem ON
            tbSaidasItem.cod_emp   = tbintegraSAP_DocItem.cod_emp 
        AND tbSaidasItem.cod_fil   = tbintegraSAP_DocItem.cod_fil
        AND tbSaidasItem.ano_solic = tbintegraSAP_DocItem.ano_solic 
        AND tbSaidasItem.num_solic = tbintegraSAP_DocItem.num_solic
        AND tbSaidasItem.num_item  = tbintegraSAP_DocItem.num_item
   SET tbintegraSAP_UpdCancPV.cod_emp   = IF(tbintegraSAP_UpdCancPV.Quantity = tbSaidasItem.qtde_nf,tbintegraSAP_DocItem.cod_emp, NULL)
      ,tbintegraSAP_UpdCancPV.cod_fil   = IF(tbintegraSAP_UpdCancPV.Quantity = tbSaidasItem.qtde_nf,tbintegraSAP_DocItem.cod_fil, NULL)
      ,tbintegraSAP_UpdCancPV.ano_solic = IF(tbintegraSAP_UpdCancPV.Quantity = tbSaidasItem.qtde_nf,tbintegraSAP_DocItem.ano_solic, NULL)
      ,tbintegraSAP_UpdCancPV.num_solic = IF(tbintegraSAP_UpdCancPV.Quantity = tbSaidasItem.qtde_nf,tbintegraSAP_DocItem.num_solic, NULL)
      ,tbintegraSAP_UpdCancPV.num_item  = IF(tbintegraSAP_UpdCancPV.Quantity = tbSaidasItem.qtde_nf,tbintegraSAP_DocItem.num_item, NULL)
      ,tbintegraSAP_UpdCancPV.FreeText  = IF(tbintegraSAP_UpdCancPV.Quantity = tbSaidasItem.qtde_nf,"Exclusão automatica(2) - Solicitação de alteração Duplicada", tbintegraSAP_UpdCancPV.FreeText)
      ,tbintegraSAP_UpdCancPV.STATUS    = IF(tbintegraSAP_UpdCancPV.Quantity = tbSaidasItem.qtde_nf,3,1)
   WHERE tbintegraSAP_UpdCancPV.STATUS       = 0
     #AND tbintegraSAP_UpdCancPV.flg_deleted = 0 
     #Quantidade Alteração = Qtde Pedido
     #AND tbintegraSAP_UpdCancPV.Quantity = tbSaidasItem.qtde_nf
     #SE NÃO existe alteração em curso
     AND NOT EXISTS (SELECT 1 FROM of_logistica.tbsolic_saidas_item_integra_alteracao tbAlt 
                     WHERE tbAlt.UniqueKey = tbintegraSAP_UpdCancPV.UniqueKey
                       AND tbAlt.dthr_realizado IS NULL);
   */
   
   
   #Seta STATUS = 3 (processado) para registros que não foram tratados acima
   #Seta StatusItem = 0 novamente
   UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV
   LEFT JOIN tbintegraSAP_DocItem tbItem ON
             tbItem.DocEntry = tbUpdCancPV.DocumentId
         AND tbItem.DocTipo  = tbUpdCancPV.DocumentType
         AND tbItem.DocNum   = tbUpdCancPV.DocumentNumber
         AND tbItem.LineNum  = tbUpdCancPV.LineNumber
   SET tbUpdCancPV.STATUS = 3
       ,tbUpdCancPV.cod_emp   = tbItem.cod_emp 
       ,tbUpdCancPV.cod_fil   = tbItem.cod_fil
       ,tbUpdCancPV.ano_solic = tbItem.ano_solic 
       ,tbUpdCancPV.num_solic = tbItem.num_solic
       ,tbUpdCancPV.num_item  = tbItem.num_item
       #,tbUpdCancPV.FreeText  = CONCAT(TRIM(BOTH FROM tbUpdCancPV.FreeText),IF(tbUpdCancPV.FreeText IS NULL,'','|'),"(4)Atu Item")
       ,tbUpdCancPV.FreeText  = SUBSTRING(CONCAT(IFNULL(tbUpdCancPV.FreeText ,""),"(4)Atu Item"),1,300)
       ,tbItem.StatusAnt = tbItem.StatusItem
       ,tbItem.StatusItem = 0
   WHERE tbUpdCancPV.TipoUpdCanc = 'U'
     AND tbUpdCancPV.STATUS      = 0;
   
   
   
   IF excecao = 1 THEN
      ROLLBACK;
      SET RESULTADO = "0";
      SET MENSAGEM = "Erro SQL - Verifique com o Administrador";
   ELSE
      COMMIT;
      SET MENSAGEM = CONCAT(MENSAGEM, " - [", xQtdeRegs, "]");
   END IF;
   
   
END$$

DELIMITER ;