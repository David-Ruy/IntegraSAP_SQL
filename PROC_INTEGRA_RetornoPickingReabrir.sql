DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_RetornoPickingReabrir`$$

CREATE PROCEDURE `PROC_INTEGRA_RetornoPickingReabrir`(
   IN oTipoOperacao           INT     #0 = Alterações Pendentes, 1 = Divergencia Conferencia
   # Parametros de Retorno
   #OUT RESULTADO      INT,
   #OUT MENSAGEM       VARCHAR(500)
)
BLOCO1:BEGIN
      #@Reviser David Ruy <2020/03/20> StatusSLIN = 1 => GSM em aberto ainda, Status SLIN = 2 (já gerou novo picking com alteração e GSM finalizada)
      #@Reviser David Ruy <2022/03/29> tbTopo.StatusDoc  <> 7 na condição para reabrir
      #@Reviser David Ruy <2022/04/29> oTipoOperacao = 0 (union StatusDoc=8 => Forçado Novo Picking Monitor) 
      #@Reviser David Ruy <2023/03/06> FatorAgrup e xflg_agrupa_transf para utilização Qtdes Agrupadas TD-S (Elinox)
      #@Reviser David Ruy <2023/04/25> Para TipoOper=1 => TD-S, não precisa ter checkout / AND tbTopo.StatusDoc > 3 / Listar QtdeEst e QtdeReal
      #@Reviser David Ruy <2023/04/26> Para TipoOper=1 => TD-S, AND TbSaidas.status_processo >= 8
      #@Reviser David Ruy <2023/07/12> Desconsiderar Registros com DocDate < 30 dias
      #@Reviser David Ruy <2024/11/04> Reabrir por Div Separação : Parametro xflg_obriga_checkout_retornoPV + Considerar DocTipo in ('TD-S','OP')
      #@Reviser David Ruy <2025/05/31> Quando oTipoOperacao=1 => TMP_AtualizarPedidos => AND IFNULL(tbTopo.idPicking,0) <> 0
      #@Reviser David Ruy <2026/06/26> Implementado LineNumPk para alteração de qtde variáveis direto no PV e PK.
      
   DECLARE xQtdeRegs      INT DEFAULT 0;
   DECLARE excecao 	      INT DEFAULT 0;
   DECLARE RESULTADO      INT DEFAULT 1;
   DECLARE MENSAGEM       VARCHAR(500) DEFAULT "";
   DECLARE xflg_permite_PVParcial INT;
   DECLARE xflg_agrupa_transf TINYINT;
   DECLARE xflg_obriga_checkout_retornoPV TINYINT;
   
   /*
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       ROLLBACK;
   END;
   */
   
   
   #@Reviser David Ruy <2022-11-01>
   SELECT flg_permite_PVParcial, flg_agrupa_transf, flg_obriga_checkout_retornoPV
   INTO xflg_permite_PVParcial, xflg_agrupa_transf, xflg_obriga_checkout_retornoPV
   FROM tbintegraSAP_parametros
   WHERE flg_ativo = 1
   LIMIT 1;
   
   IF oTipoOperacao = 0 THEN
   
      #Alterações Pendentes originadas no SAP-B1
      DROP TEMPORARY TABLE IF EXISTS TMP_ReabrirPicking;
      CREATE TEMPORARY TABLE TMP_ReabrirPicking 
            (SELECT DISTINCT tbTopo.idPicking, tbTopo.DocEntry, tbTopo.DocTipo, tbTopo.DocNum,
                   "Reabrir Picking - Alterações" Observ,
                   0 AS FlgProcessado,
                   0 QtdeEst, 0 QtdeReal,
                   tbUpdCancPV.LineNumber 'LineNum'
            FROM tbintegraSAP_UpdCancPV tbUpdCancPV 
            INNER JOIN tbintegraSAP_Doc tbTopo ON 
                       tbTopo.DocEntry = tbUpdCancPV.DocumentId
                   AND tbTopo.DocTipo  = tbUpdCancPV.DocumentType 
                   AND tbTopo.DocNum   = tbUpdCancPV.DocumentNumber 
            WHERE tbUpdCancPV.cod_emp IS NULL
              AND tbUpdCancPV.TipoUpdCanc = 'U'
              AND tbTopo.idPicking IS NOT NULL
              AND tbTopo.cod_emp IS NOT NULL
              AND tbUpdCancPV.STATUS = 1
              #@Reviser David Ruy <2020/04/27> Não reabrir picking de itens excluídos no SAP
              AND tbUpdCancPV.Quantity > 0)
        
        UNION
        
            (SELECT tbTopo.idPicking, tbTopo.DocEntry, tbTopo.DocTipo, tbTopo.DocNum,
                   "Reabrir Picking - Monitor" Observ,
                   0 AS FlgProcessado,
                   0 QtdeEst, 0 QtdeReal,
                   0 'LineNum'
            FROM tbintegraSAP_Doc tbTopo 
            WHERE tbTopo.StatusDoc = 8);
      
   ELSE
   
      #GSM com Divergencias de Conferencia que não retornaram ainda para o SAP
      DROP TEMPORARY TABLE IF EXISTS TMP_ReabrirPicking;
      CREATE TEMPORARY TABLE TMP_ReabrirPicking ( 
         SELECT DISTINCT tbTopo.idPicking, tbTopo.DocEntry, tbTopo.DocTipo, tbTopo.DocNum, 
                "Reabrir Picking - Ajuste divergencias GSM (Tolerancia)" Observ,
                0 AS FlgProcessado,
                IFNULL(tbItem.qtde_est,0) QtdeEst, IFNULL(tbItem.real_est2,0) QtdeReal, tbDocItem.LineNum
          FROM tbintegraSAP_Doc tbTopo
          INNER JOIN of_logistica.tbsolic_saidas TbSaidas ON
                     TbSaidas.cod_emp   = tbTopo.cod_emp
                 AND TbSaidas.cod_fil   = tbTopo.cod_fil
                 AND TbSaidas.ano_solic = tbTopo.ano_solic
                 AND TbSaidas.num_solic = tbTopo.num_solic
          INNER JOIN of_logistica.tbsolic_saidas_item tbItem ON 
                     tbItem.cod_emp   = TbSaidas.cod_emp
                 AND tbItem.cod_fil   = TbSaidas.cod_fil
                 AND tbItem.ano_solic = TbSaidas.ano_solic
                 AND tbItem.num_solic = TbSaidas.num_solic
          INNER JOIN tbintegraSAP_DocItem tbDocItem ON
                     tbDocItem.DocTipo  = tbTopo.DocTipo
                 AND tbDocItem.DocEntry = tbTopo.DocEntry
                 AND tbDocItem.DocNum   = tbTopo.DocNum
                 AND tbDocItem.num_item = tbItem.num_item
          WHERE tbTopo.TipoDocSLIN = "S"
            AND tbTopo.StatusSLIN = 1
            AND tbTopo.StatusDoc <> 7
            #AND TbSaidas.dthr_final_picking IS NOT NULL
            AND TbSaidas.status_processo >= 8
            AND IF(tbTopo.DocTipo IN ('TD-S','OP'),TRUE, 
                   IF(xflg_obriga_checkout_retornoPV = 1, TbSaidas.dthr_final_picking IS NOT NULL, TRUE))
            AND TbSaidas.dthr_retorno_integracao IS NULL
            AND IFNULL(tbItem.qtde_est,0) <> IFNULL(tbItem.real_est2,0)
            AND xflg_permite_PVParcial = 1
            AND tbTopo.DocDate >= DATE_ADD(CURRENT_DATE(), INTERVAL -30 DAY)
            AND IFNULL(tbTopo.idPicking,0) <> 0
          #HAVING SUM(IFNULL(tbItem.qtde_est,0)) <> SUM(IFNULL(tbItem.real_est2,0))
      );   
      
      
      DROP TEMPORARY TABLE IF EXISTS TMP_AtualizarPedidos;
      CREATE TEMPORARY TABLE TMP_AtualizarPedidos( 
          SELECT tbTopo.DocEntry, tbTopo.DocTipo, tbTopo.DocNum, tbDocItem.LineNum, tbDocItem.LineNumPk, 
                 tbDocItem.BaseQty, tbDocItem.OpenInvQty, 
                 tbItem.num_ped_aux, tbItem.cod_produto, tbItem.num_item, 
                 IFNULL(tbItem.qtde_est,0) QtdeEst, IFNULL(tbItem.real_est2,0) QtdeReal, 
                 tbItem.real_est2 real_est, tbItem.real_vol2 real_vol, tbItem.real_frac2 real_frac, tbItem.real_peso2 real_peso,
                 tbDocItem.ManBtchNum, tbDocItem.ManSerNum, 
                 IF(tbTopo.DocTipo='TD-S' AND xflg_agrupa_transf=1,1,0) xflg_agrupa_transf,
                 tbDocItem.BaseQty / (SELECT SUM(tbintegraSAP_DocItem.BaseQty) FROM tbintegraSAP_DocItem
                  WHERE tbintegraSAP_DocItem.DocTipo = tbDocItem.DocTipo
                    AND tbintegraSAP_DocItem.DocEntry = tbDocItem.DocEntry
                    AND tbintegraSAP_DocItem.ItemCode = tbDocItem.ItemCode
                  ) AS FatorAgrup,
                 "Atualizar Pedido SAP - Ajuste divergencias GSM (Tolerancia)" Observ
          FROM tbintegraSAP_Doc tbTopo
          INNER JOIN of_logistica.tbsolic_saidas TbSaidas ON
                     TbSaidas.cod_emp   = tbTopo.cod_emp
                 AND TbSaidas.cod_fil   = tbTopo.cod_fil
                 AND TbSaidas.ano_solic = tbTopo.ano_solic
                 AND TbSaidas.num_solic = tbTopo.num_solic
          INNER JOIN tbintegraSAP_DocItem tbDocItem ON
                     tbDocItem.DocEntry = tbTopo.DocEntry
                 AND tbDocItem.DocTipo  = tbTopo.DocTipo 
                 AND tbDocItem.DocNum   = tbTopo.DocNum 
          INNER JOIN of_logistica.tbsolic_saidas_item tbItem ON 
                     tbItem.cod_emp   = tbDocItem.cod_emp
                 AND tbItem.cod_fil   = tbDocItem.cod_fil
                 AND tbItem.ano_solic = tbDocItem.ano_solic
                 AND tbItem.num_solic = tbDocItem.num_solic
                 AND tbItem.num_item  = tbDocItem.num_item
          WHERE tbTopo.TipoDocSLIN = "S"
            AND tbTopo.StatusSLIN = 1
            #AND TbSaidas.dthr_final_picking IS NOT NULL
            AND tbTopo.StatusDoc <> 7
            AND TbSaidas.status_processo >= 8
            AND IF(tbTopo.DocTipo IN ('TD-S','OP'),TRUE, 
                   IF(xflg_obriga_checkout_retornoPV = 1, TbSaidas.dthr_final_picking IS NOT NULL, TRUE))
            AND TbSaidas.dthr_retorno_integracao IS NULL
            AND IFNULL(tbItem.qtde_est,0) <> IFNULL(tbItem.real_est2,0)
            AND xflg_permite_PVParcial = 1
            AND tbTopo.DocDate >= DATE_ADD(CURRENT_DATE(), INTERVAL -30 DAY)
            AND IFNULL(tbTopo.idPicking,0) <> 0
      );   
            
   END IF;
      
      
   SELECT COUNT(*) INTO xQtdeRegs FROM TMP_ReabrirPicking;
   
   SELECT idPicking, DocEntry, DocTipo, DocNum, Observ, QtdeEst, QtdeReal, LineNum
   FROM TMP_ReabrirPicking;
   IF oTipoOperacao = 1 THEN
      SELECT * FROM TMP_AtualizarPedidos;
   END IF;
   
   DROP TEMPORARY TABLE IF EXISTS TMP_ReabrirPicking;  
   DROP TEMPORARY TABLE IF EXISTS TMP_AtualizarPedidos;
   
   
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- Erro PROC_INTEGRA_RetornoPickingReabrir");
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- PROC_INTEGRA_RetornoPickingReabrir [",xQtdeRegs,"]");
   END IF;
END$$

DELIMITER ;