DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_ListarAlteracoes`$$

CREATE PROCEDURE `PROC_INTEGRA_ListarAlteracoes`(
   IN  oTipoLista        INT    #0=Alterações Solicitadas SAP / 1=Alterações Divergencia dentro da tolerancia
   # Parametros de Retorno
   #OUT RESULTADO        INT,
   #OUT MENSAGEM         VARCHAR(500)
)
BLOCO1:BEGIN
   /*************************************************************************************************/
   #@Reviser David Ruy <2022-04-14> Gera registros apenas se permite parcial
   #@Reviser David Ruy <2023/03/06> FatorAgrup e xflg_agrupa_transf para utilização Qtdes Agrupadas TD-S (Elinox)
   #@Reviser David Ruy <20230426> Ajuste TD-S não tem picking : IF(tbTopo.DocTipo='TD-S',TRUE,TbSaidas.dthr_final_picking IS NOT NULL)
   /*************************************************************************************************/
   
   DECLARE excecao 	     INT DEFAULT 0;
   DECLARE RESULTADO     INT DEFAULT 1;
   DECLARE MENSAGEM      VARCHAR(500) DEFAULT "Selecao realizada com sucesso";
   DECLARE xflg_permite_PVParcial INT;
   DECLARE xflg_agrupa_transf TINYINT;
   
   
   /*DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       ROLLBACK;
   END;*/
   
   SELECT flg_permite_PVParcial, flg_agrupa_transf 
   INTO xflg_permite_PVParcial, xflg_agrupa_transf
   FROM tbintegraSAP_parametros
   WHERE flg_ativo = 1
   LIMIT 1;
   
   
   IF oTipoLista = 0 THEN
      SELECT Topo.DocEntry, Topo.DocNum, Topo.DocTipo, DocItem.LineNum, 
             IFNULL(tbAlteracao.qtde_est_atu,0) qtde_est_atu, 
             IF(Topo.DocTipo='TD-S' AND xflg_agrupa_transf=1,1,0) xflg_agrupa_transf,
             DocItem.BaseQty / (SELECT SUM(tbintegraSAP_DocItem.BaseQty) FROM tbintegraSAP_DocItem
              WHERE tbintegraSAP_DocItem.DocTipo = DocItem.DocTipo
                AND tbintegraSAP_DocItem.DocEntry = DocItem.DocEntry
                AND tbintegraSAP_DocItem.ItemCode = DocItem.ItemCode
              ) AS FatorAgrup,             
             RESULTADO, MENSAGEM
      FROM of_logistica.tbsolic_saidas_item_integra_alteracao tbAlteracao
      INNER JOIN of_logistica.tbsolic_saidas_item tbItem ON
                 tbItem.cod_emp   = tbAlteracao.cod_emp 
             AND tbItem.cod_fil   = tbAlteracao.cod_fil 
             AND tbItem.ano_solic = tbAlteracao.ano_solic 
             AND tbItem.num_solic = tbAlteracao.num_solic 
             AND tbItem.num_item  = tbAlteracao.num_item
      INNER JOIN tbintegraSAP_Doc Topo ON
                 Topo.cod_emp   = tbAlteracao.cod_emp 
             AND Topo.cod_fil   = tbAlteracao.cod_fil 
             AND Topo.ano_solic = tbAlteracao.ano_solic 
             AND Topo.num_solic = tbAlteracao.num_solic 
      INNER JOIN tbintegraSAP_DocItem DocItem ON
                 DocItem.cod_emp   = tbAlteracao.cod_emp 
             AND DocItem.cod_fil   = tbAlteracao.cod_fil 
             AND DocItem.ano_solic = tbAlteracao.ano_solic 
             AND DocItem.num_solic = tbAlteracao.num_solic 
             AND DocItem.num_item  = tbAlteracao.num_item
      WHERE Topo.idPicking IS NULL
        AND tbAlteracao.dthr_realizado IS NULL
        AND xflg_permite_PVParcial = 1;
        #AND tbAlteracao.dthr_atu_integra IS NULL;
   ELSE
      SELECT tbTopo.DocEntry, tbTopo.DocNum, tbTopo.DocTipo, DocItem.LineNum, 
             IFNULL(tbItem.real_est2,0) AS qtde_est_atu, 
             IF(tbTopo.DocTipo='TD-S' AND xflg_agrupa_transf=1,1,0) xflg_agrupa_transf,
             DocItem.BaseQty / (SELECT SUM(tbintegraSAP_DocItem.BaseQty) FROM tbintegraSAP_DocItem
              WHERE tbintegraSAP_DocItem.DocTipo = DocItem.DocTipo
                AND tbintegraSAP_DocItem.DocEntry = DocItem.DocEntry
                AND tbintegraSAP_DocItem.ItemCode = DocItem.ItemCode
              ) AS FatorAgrup,
             RESULTADO, MENSAGEM
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
      INNER JOIN tbintegraSAP_DocItem DocItem ON
                 DocItem.cod_emp   = tbItem.cod_emp 
             AND DocItem.cod_fil   = tbItem.cod_fil 
             AND DocItem.ano_solic = tbItem.ano_solic 
             AND DocItem.num_solic = tbItem.num_solic 
             AND DocItem.num_item  = tbItem.num_item
      WHERE tbTopo.TipoDocSLIN = "S"
      AND IF(tbTopo.DocTipo='TD-S',TRUE,TbSaidas.dthr_final_picking IS NOT NULL)
      AND TbSaidas.dthr_retorno_integracao IS NULL
      AND tbTopo.idPicking IS NULL
      AND tbTopo.idPickingAnt IS NOT NULL
      AND tbTopo.StatusDoc = 7
      AND IFNULL(tbItem.qtde_est,0) <> IFNULL(tbItem.real_est2,0)
      AND xflg_permite_PVParcial = 1;      
      #HAVING SUM(IFNULL(tbItem.qtde_est,0)) <> SUM(IFNULL(tbItem.real_est2,0));   
   END IF;
   
   IF excecao = 1 THEN
      #ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- Erro PROC_INTEGRA_ListarAlteracoes");
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      #COMMIT;
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- (PROC_INTEGRA_ListarAlteracoes) Alterações Llistadas com sucesso");
   END IF;
END$$

DELIMITER ;