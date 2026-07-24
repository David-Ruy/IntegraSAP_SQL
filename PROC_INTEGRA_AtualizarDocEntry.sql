DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_AtualizarDocEntry`$$

CREATE PROCEDURE `PROC_INTEGRA_AtualizarDocEntry`(
	IN oCodUsuario				    VARCHAR(10),
	IN oDocEntry          INT,
	IN oDocTipo           VARCHAR(10),
	IN oNomeCampo         VARCHAR(20),
	IN oValorCampo        VARCHAR(200),
	
	# Parametros de Retorno
	OUT RESULTADO         VARCHAR(5),
	OUT MENSAGEM          VARCHAR(500)
)
BLOCO1:BEGIN
   /****************************************************************
   #Create David Ruy 
   #Reviser David Ruy <2022-01-14 Update tbintegraSAP_Doc->U_RSD_RplOrder
   #Reviser David Ruy <2023-04-28> Atualizar StatusSlin   
   #Reviser David Ruy <2024-09-11 Update tbintegraSAP_Doc->Vlr_FreteCliente
   #Reviser David Ruy <2024-12-26 idPicking : Alteração chave do join tbSaidas.chave_integracao
   #Reviser David Ruy <2025-06-12 idPicking : Gerar Log
   #Reviser David Ruy <2026-05-07 xCampoAux1 e xCampoAux2, para quando precisar enviar 2 campos simultaneamente
   #Reviser David Ruy <2026-05-07 Implementado oNomeCampo = 'DocEntryRef'
   *****************************************************************/
   DECLARE xIncAlt      VARCHAR(01)	DEFAULT 'I';
   DECLARE excecao      INT DEFAULT 0;
   DECLARE xChaveAux    VARCHAR(50);
   DECLARE xDocNum      VARCHAR(50);
   DECLARE xCampoAux1   VARCHAR(100) DEFAULT NULL;
   DECLARE xCampoAux2   VARCHAR(100) DEFAULT NULL;
  
  
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION 
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
      GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
      ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM  = fnMensagemExcecao(MENSAGEM);
      SET excecao = 1;
   END;
   
   START TRANSACTION;	
   
   SET RESULTADO = "1";
   SET MENSAGEM = "Atualização realizada com sucesso";
   
   #Verifica se tem mais de um campo para atualizar
   IF LOCATE("|", oValorCampo) > 0 THEN
      SET xCampoAux1 = SUBSTRING(oValorCampo,1,LOCATE("|", oValorCampo)-1);
      SET xCampoAux2 = SUBSTRING(oValorCampo,LOCATE("|", oValorCampo)+1,200);
   END IF;
   
   IF NOT EXISTS (SELECT 1 FROM tbintegraSAP_Doc
                  WHERE DocEntry = oDocEntry
                    AND DocTipo  = oDocTipo) THEN
      SET xIncAlt = 'X';
   ELSE
      SET xIncAlt = 'A';
   END IF;
	
	  IF xIncAlt = 'X' THEN	
      SET RESULTADO = "0";
      SET MENSAGEM  = "DocEntry / DocTipo não localizado - Atualização Impossível";
      
   ELSEIF oNomeCampo = 'StatusSlin' THEN
         UPDATE tbintegraSAP_Doc
         SET  tbintegraSAP_Doc.StatusSLIN = oValorCampo
         WHERE DocEntry = oDocEntry
           AND DocTipo  = oDocTipo;
   ELSEIF LOWER(oNomeCampo) = 'idpicking' THEN
         UPDATE tbintegraSAP_Doc
         LEFT JOIN of_logistica.tbsolic_saidas tbSaidas ON
                  tbSaidas.chave_integracao = tbintegraSAP_Doc.chave_integracao
              #    tbSaidas.cod_emp   = tbintegraSAP_Doc.cod_emp 
              #AND tbSaidas.cod_fil   = tbintegraSAP_Doc.cod_fil
              #AND tbSaidas.ano_solic = tbintegraSAP_Doc.ano_solic 
              #AND tbSaidas.num_solic = tbintegraSAP_Doc.num_solic
         SET  tbintegraSAP_Doc.idPickingAnt = IF(IFNULL(tbintegraSAP_Doc.idPicking,'')='',tbintegraSAP_Doc.idPickingAnt,
                             CONCAT(IFNULL(tbintegraSAP_Doc.idPickingAnt,''),tbintegraSAP_Doc.idPicking,'/'))
             ,tbintegraSAP_Doc.idPicking = oValorCampo
             ,tbintegraSAP_Doc.StatusAnt = IF(StatusDoc=7,StatusDoc, StatusAnt)
             ,tbintegraSAP_Doc.StatusDoc = IF(StatusDoc=7,3, StatusDoc) 
             ,tbintegraSAP_Doc.dthr_alt  = NOW()
             ,tbintegraSAP_Doc.usu_alt   = oCodUsuario
             ,tbintegraSAP_Doc.StatusSLIN = IF(tbSaidas.dthr_final_picking IS NULL, tbintegraSAP_Doc.StatusSLIN, 2)
         WHERE DocEntry = oDocEntry
           AND DocTipo  = oDocTipo;
         
         
         SET @LineNum = -1;
         UPDATE tbintegraSAP_DocItem
         SET LineNumPk = @LineNum := @LineNum + 1
         WHERE DocEntry = oDocEntry
           AND DocTipo  = oDocTipo
           #@Reviser David Ruy <2021/01/05> Considerar apenas itens não cancelados=>(status=9)
           AND IFNULL(tbintegraSAP_DocItem.StatusItem,0) = 0
         ORDER BY DocEntry, Doctipo, DocNum, tbintegraSAP_DocItem.LineNum;
         
         #insert into tbintegraSAP_DocPicking
         SET @PKLineNum = -1;
         INSERT IGNORE INTO tbintegraSAP_DocPicking (DocEntry, DocNum, DocTipo, IdPicking, DocLineNum, PkLineNum, dthr_inc)
            SELECT DocEntry, DocNum, DocTipo, oValorCampo, LineNum, @PKLineNum := @PKLineNum + 1, NOW()
            FROM tbintegraSAP_DocItem
         WHERE DocEntry = oDocEntry
           AND DocTipo  = oDocTipo
           AND StatusItem = 0;
           
         
         #2025-06-12 Buscar DocNum para gerar log
         SELECT DocNum INTO xDocNum FROM tbintegraSAP_Doc
         WHERE DocEntry = oDocEntry AND DocTipo  = oDocTipo;
         
         CALL PROC_INTEGRA_EnviarLog(oCodUsuario, 
                                     CONCAT('PROC_INTEGRA_AtualizarDocEntry(idpicking)=>',oDocTipo,xDocNum,'-',oDocEntry),
                                     CONCAT('Log de chamada PROC_INTEGRA_AtualizarDocEntry=>',oDocTipo,xDocNum,'-',oDocEntry),
                                     'OK', 
                                     CONCAT('Atualização Pick com sucesso ',oValorCampo), 
                                     @R, 
                                     @M);
                                              
         
   ELSEIF LOWER(oNomeCampo) = 'U_RSD_RplOrder' THEN
         UPDATE tbintegraSAP_Doc
         SET  tbintegraSAP_Doc.U_RSD_RplOrder = oValorCampo
         WHERE DocEntry = oDocEntry
           AND DocTipo  = oDocTipo;
   ELSEIF LOWER(oNomeCampo) = 'DocEntryRef' THEN
         
         IF xCampoAux1 IS NOT NULL THEN
         
            UPDATE tbintegraSAP_Doc
            SET  tbintegraSAP_Doc.DocEntryRef = xCampoAux1,
                 tbintegraSAP_Doc.DocNumRef   = xCampoAux2
            WHERE DocEntry = oDocEntry
              AND DocTipo  = oDocTipo;
         ELSE
            
            UPDATE tbintegraSAP_Doc
            SET  tbintegraSAP_Doc.DocEntry = oValorCampo
            WHERE DocEntry = oDocEntry
              AND DocTipo  = oDocTipo;
         END IF;
   ELSEIF oNomeCampo = 'Vlr_FreteCliente' THEN
           
         UPDATE of_logistica.tbprog_entregas
         INNER JOIN tbintegraSAP_Doc ON 
               tbintegraSAP_Doc.chave_integracao  = tbprog_entregas.chave_integracao
         SET  tbintegraSAP_Doc.Vlr_FreteCliente = oValorCampo
             #,tbprog_entregas.vlr_frete_cliente = oValorCampo
              WHERE tbintegraSAP_Doc.DocEntry = oDocEntry
                AND tbintegraSAP_Doc.DocTipo  = oDocTipo;
           
   ELSE
      SET RESULTADO = "0";
      SET MENSAGEM = CONCAT("Atualização NÃO realizada - Campo não identificado (",oNomeCampo,")");    
      ROLLBACK;
    END IF;
    
   COMMIT;
       
   IF excecao = 1 THEN
      SET RESULTADO = "0";
      SET MENSAGEM = "Erro SQL - Verifique com o Administrador";
   END IF;
END$$

DELIMITER ;