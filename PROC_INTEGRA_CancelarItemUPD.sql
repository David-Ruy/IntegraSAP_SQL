DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_CancelarItemUPD`$$

CREATE PROCEDURE `PROC_INTEGRA_CancelarItemUPD`(
	# Parametros de Retorno
	OUT RESULTADO       VARCHAR(5),
	OUT MENSAGEM        VARCHAR(500)
)
	   #@Author David Ruy <2020/04/27>
	   #Esta procedure identifica se houveram itens que não vieram na integração do SAP para alteração
	   #Isso significa que o item foi excluído no SAP, então a procedure atualiza Status na tbIntegraSAP_DocItem 
	   #Insere na tbintegraSAP_UpdCanc (com status 9=Cancelado) para registrar a operação
	   
BLOCO1:BEGIN
	DECLARE xQtdeRegs   INT DEFAULT 0;
	DECLARE excecao     INT DEFAULT 0;
	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   SET RESULTADO = "1";
   SET MENSAGEM = "Atualização realizada com sucesso";
   
   /*******************************************************************
   #Seleciona as GSM´ (Topo) que deverão ser alteradas para verificar se houveram exclusões de Itens
   ********************************************************************/
   DROP TEMPORARY TABLE IF EXISTS tbTMPDocs;
   CREATE TEMPORARY TABLE tbTMPDocs 
     SELECT DISTINCT tbTopo.DocEntry, tbTopo.DocTipo, tbTopo.DocNum, tbUpdCancPV.UpdateDate
     FROM tbintegraSAP_Doc tbTopo
     INNER JOIN tbintegraSAP_UpdCancPV tbUpdCancPV ON
               tbTopo.DocTipo  = tbUpdCancPV.DocumentType 
           AND tbTopo.DocEntry = tbUpdCancPV.DocumentId
           AND tbTopo.DocNum   = tbUpdCancPV.DocumentNumber 
     INNER JOIN tbintegraSAP_DocItem tbItens ON 
               tbItens.DocTipo  = tbTopo.DocTipo  
           AND tbItens.DocEntry = tbTopo.DocEntry 
           AND tbItens.DocNum   = tbTopo.DocNum   
     WHERE TRUE 
       AND tbUpdCancPV.STATUS = 0
       AND tbUpdCancPV.TipoUpdCanc = 'U';
   #SELECT * FROM tbTMPDocs;   
   
   
   /*******************************************************************
   #Seleciona TODOS os Itens da tbintegraSAP_UpdaCanc
   ********************************************************************/
   DROP TEMPORARY TABLE IF EXISTS tbTMPItensUPD;
   CREATE TEMPORARY TABLE tbTMPItensUPD 
     SELECT DISTINCT tbTMPDocs.DocEntry, tbTMPDocs.DocTipo, tbTMPDocs.DocNum, 
            tbUpdCancPV.LineNumber LineNum, tbUpdCancPV.ItemCode,
            tbUpdCancPV.UniqueKey, tbUpdCancPV.UpdateDate
     FROM tbTMPDocs 
     INNER JOIN tbintegraSAP_UpdCancPV tbUpdCancPV ON
               tbUpdCancPV.DocumentId     = tbTMPDocs.DocEntry
           AND tbUpdCancPV.DocumentType   = tbTMPDocs.DocTipo
           AND tbUpdCancPV.DocumentNumber = tbTMPDocs.DocNum     
     WHERE tbUpdCancPV.STATUS = 0
       AND tbUpdCancPV.TipoUpdCanc = 'U';
   #SELECT * FROM tbTMPItensUPD;
   
   
   /*******************************************************************
   #Seleciona TODOS os Itens da tbintegraSAP_DocItem
   ********************************************************************/   
   DROP TEMPORARY TABLE IF EXISTS tbTMPExclusao;
   CREATE TEMPORARY TABLE tbTMPExclusao
      SELECT DISTINCT tbItens.DocEntry, tbItens.DocTipo, tbItens.DocNum, 
                      tbItens.LineNum, tbItens.ItemCode, tbTMPDocs.UpdateDate,
                      0 AS FlgDelete
      FROM tbTMPDocs
      INNER JOIN tbintegraSAP_DocItem tbItens ON
                 tbTMPDocs.DocEntry = tbItens.DocEntry
             AND tbTMPDocs.DocTipo  = tbItens.DocTipo
             AND tbTMPDocs.DocNum   = tbItens.DocNum;
   #SELECT * FROM tbTMPExclusao;
   
   
   
   /*******************************************************************
   #Marca item a "Excluir"
   ********************************************************************/   
   UPDATE tbTMPExclusao
   LEFT JOIN tbTMPItensUPD ON
   #INNER JOIN tbTMPItensUPD ON
             tbTMPItensUPD.DocEntry = tbTMPExclusao.DocEntry
         AND tbTMPItensUPD.DocTipo  = tbTMPExclusao.DocTipo
         AND tbTMPItensUPD.DocNum   = tbTMPExclusao.DocNum
         AND tbTMPItensUPD.LineNum  = tbTMPExclusao.LineNum
   SET FlgDelete = 1
   WHERE tbTMPItensUPD.LineNum IS NULL;
   #SELECT * FROM tbTMPExclusao;
   
   /*******************************************************************
   #Insere registro de LOG tbintegraSAP_UpdCancPV do Item "Excluído"
   ********************************************************************/   
   INSERT IGNORE INTO tbintegraSAP_UpdCancPV
      (TipoUpdCanc, UniqueKey, DocumentId, DocumentType, DocumentNumber, LineNumber, 
       UpdateDate, Quantity, QtdeEstoque, Price, STATUS, flg_deleted, FreeText)
         #SELECT tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocNum, tbintegraSAP_DocItem.LineNum,
      #       tbintegraSAP_DocItem.cod_emp, tbintegraSAP_DocItem.cod_fil, tbintegraSAP_DocItem.ano_solic, 
      #       tbintegraSAP_DocItem.num_solic, tbintegraSAP_DocItem.num_item
      SELECT 'U', CONCAT(tbItem.DocTipo,'-',tbItem.DocEntry,'-',tbItem.DocNum, '-', tbItem.LineNum),
           tbItem.DocEntry, tbItem.DocTipo, tbItem.DocNum, tbItem.LineNum, 
           tbTMPExclusao.UpdateDate, 0, 0, 0,
           #Se não tem GSM ainda ou se já tem GSM mas já tem cancelamento anterior, => Status=3 (processado), senão Status=1 (tratar)
           IF(tbintegraSAP_Doc.cod_emp IS NULL, 3, 1),# IF(tbItem.statusItem=9,3,1)), 
           1, "Exclusão de Item"
      FROM tbintegraSAP_DocItem tbItem
      INNER JOIN tbintegraSAP_Doc ON
             tbintegraSAP_Doc.DocEntry = tbItem.DocEntry
         AND tbintegraSAP_Doc.DocNum   = tbItem.DocNum   
         AND tbintegraSAP_Doc.DocTipo  = tbItem.DocTipo  
      INNER JOIN tbTMPExclusao ON
                 tbTMPExclusao.DocEntry = tbItem.DocEntry
             AND tbTMPExclusao.DocTipo  = tbItem.DocTipo
             AND tbTMPExclusao.DocNum   = tbItem.DocNum
             AND tbTMPExclusao.LineNum  = tbItem.LineNum
      WHERE tbTMPExclusao.flgDelete = 1;
      
      
      
      
   /*******************************************************************
   #"Exclui o item na tbintegraSAP_DocItem
   ********************************************************************/   
   UPDATE tbintegraSAP_DocItem tbItem
   INNER JOIN tbTMPExclusao ON
              tbTMPExclusao.DocEntry = tbItem.DocEntry
          AND tbTMPExclusao.DocTipo  = tbItem.DocTipo
          AND tbTMPExclusao.DocNum   = tbItem.DocNum
          AND tbTMPExclusao.LineNum  = tbItem.LineNum
   SET tbItem.statusItem = 9
   WHERE tbTMPExclusao.flgDelete = 1;
   
   
   
   
   #Apaga as tabelas temporárias
   DROP TEMPORARY TABLE IF EXISTS tbTMPDocs;
   DROP TEMPORARY TABLE IF EXISTS tbTMPItensUPD;
   DROP TEMPORARY TABLE IF EXISTS tbTMPExclusao;   
   IF excecao = 1 THEN
      SET RESULTADO = "0";
      SET MENSAGEM = "Erro SQL - Verifique com o Administrador";
   ELSE
      SET MENSAGEM = CONCAT(MENSAGEM, " - [", xQtdeRegs, "]");
   END IF;
   
END$$

DELIMITER ;