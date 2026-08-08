/*
Overflash Informática
Automação de Scripts
Atualização: Integração SAP 2018
Data/ Hora: 08/08/2026 17:05:30
A leitura, exame, retransmissão, divulgação, distribuição, cópia ou outro uso deste arquivo por pessoas ou entidades
que não sejam funcionário da Overflash, constitui obtenção de informação por meio ilícito e configura crime previsto na legislação brasileira. 
Caso este arquivo tenha sido recebido por engano, por favor, apague-a imediatamente de seu sistema e, se possível, avise suporte@overflash.com.br
*/

/********************************************************/
/**** BEGIN - PROCEDURE */
/********************************************************/


/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_AtualizarCTE.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_AtualizarCTE`$$

CREATE PROCEDURE `PROC_INTEGRA_AtualizarCTE`(
	IN oCodUsuario				    VARCHAR(10),
   IN oId INT, 
   IN oDocTypeId        VARCHAR(10), 
   IN oDocEntry         VARCHAR(20),
   IN oDocNum           VARCHAR(20),
   IN oSerial           VARCHAR(20),
   IN oKeyNfe           VARCHAR(44),
   IN oNumNFE           VARCHAR(20),
   IN oSerieNFE         VARCHAR(20),
   IN oDateReceived     VARCHAR(20),
   IN oCardCode         VARCHAR(20),
   IN oCardName         VARCHAR(100),
   IN oCNPJEmi          VARCHAR(14),
   IN oIbgeCodeMuniIni  VARCHAR(20), 
   IN oIbgeCodeMuniFim  VARCHAR(20), 
   IN oDocTotal         VARCHAR(20), 
   IN oComments         TEXT, 

	# Parametros de Retorno
	OUT RESULTADO         VARCHAR(5),
	OUT MENSAGEM          VARCHAR(500)
)
BLOCO1:BEGIN
   /*
   @Reviser : David Ruy <2022/10/22> Cancelamento
   */

	DECLARE excecao      INT DEFAULT 0;
	#DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;

   SET RESULTADO = "1";
   SET MENSAGEM = "Inclusão realizada com sucesso";

   IF (oDocTotal="-1.0") THEN
      SET MENSAGEM = "Cancelamento realizado com sucesso";
      UPDATE tbintegraSAP_CTe
      SET dthr_cancel = IFNULL(dthr_cancel,NOW())
      WHERE num_chave = oKeyNfe;
   ELSE
      IF NOT EXISTS (SELECT 1 FROM tbintegraSAP_CTe
                     WHERE num_chave = oKeyNfe) THEN   
         INSERT INTO tbintegraSAP_CTe (idAddOn, DocTypeId, DocEntry, DocNum, SERIAL,
            num_chave, num_documento, serie_documento, data_documento, CardCode, CardName, emi_id, emi_cnpj, 
            #emi_raz_social, emi_endereco, emi_cidade, emi_bairro, emi_CEP, emi_UF, 
            #orig_id, orig_cnpj, ,orig_raz_social, orig_endereco, orig_cidade, orig_bairro, orig_CEP, orig_UF, 
            IbgeCodeMuniIni,
            #dest_id, dest_cnpj, dest_raz_social, dest_endereco, dest_cidade, dest_bairro, dest_CEP, dest_UF, 
            IbgeCodeMuniFim,
            valor_total, Comments, dthr_inc, usu_inc) VALUES (
               oId, oDocTypeId, oDocEntry, oDocNum, oSerial,
               oKeyNfe, oNumNFE, oSerieNFE, oDateReceived, oCardCode, oCardName, 0, oCNPJEmi,
               oIbgeCodeMuniIni, 
               oIbgeCodeMuniFim,
               oDocTotal, oComments, NOW(), oCodUsuario);
            SELECT CONCAT("OK",LAST_INSERT_ID()) INTO MENSAGEM;
      ELSE
      BEGIN
         SET MENSAGEM = "Atualização realizada com sucesso";
         UPDATE tbintegraSAP_CTe 
         SET idAddOn          = oId, 
             DocTypeId        = oDocTypeId, 
             DocEntry         = oDocEntry, 
             DocNum           = oDocNum, 
             SERIAL           = oSerial,  
             num_chave        = oKeyNfe, 
             num_documento    = oNumNFE, 
             serie_documento  = oSerieNFE,
             data_documento   = oDateReceived,
             CardCode         = oCardCode,
             CardName         = oCardName,
             emi_id           = 0, 
             emi_cnpj         = oCNPJEmi,
             IbgeCodeMuniIni  = oIbgeCodeMuniIni, 
             IbgeCodeMuniFim  = oIbgeCodeMuniFim,
             valor_total      = oDocTotal, 
             Comments         = oComments,  
             dthr_alt         = NOW(),
             usu_alt          = oCodUsuario
         WHERE num_chave = oKeyNfe;
         
         SELECT CONCAT("OK",id_documento) INTO MENSAGEM 
         FROM tbintegraSAP_CTe 
         WHERE num_chave = oKeyNfe;
         
      END;
      END IF;
   END IF;
   
   IF excecao = 1 THEN
      SET RESULTADO = "0";
      SET MENSAGEM = "Erro SQL - Verifique com o Administrador";
   END IF;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_AtualizarCTE_DocRef.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_AtualizarCTE_DocRef`$$

CREATE PROCEDURE `PROC_INTEGRA_AtualizarCTE_DocRef`(
	IN oCodUsuario		VARCHAR(10),
   IN oidAddOn       INT,
   #IN oId            INT,
   IN oKeyNfeRef     VARCHAR(44),
   IN oCoduF         VARCHAR(02),
   IN oAnoMes        VARCHAR(04),
   IN oCNPJEmi       VARCHAR(14),
   IN oTipoDoc       VARCHAR(02),
   IN oSerieNFE      VARCHAR(04),
   IN oNumNFE        VARCHAR(09),
   IN oCodNFE        VARCHAR(09),
   IN oDV            VARCHAR(01),

	# Parametros de Retorno
	OUT RESULTADO         VARCHAR(5),
	OUT MENSAGEM          VARCHAR(500)
)
BLOCO1:BEGIN

   DECLARE oid_documento   INT DEFAULT 0;
	DECLARE excecao         INT DEFAULT 0;
	#DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;

   SET RESULTADO = "1";
   SET MENSAGEM = "Inclusão realizada com sucesso";
   
   SELECT id_documento INTO oid_documento FROM tbintegraSAP_CTe
   WHERE idAddOn = oidAddOn;


   IF NOT EXISTS (SELECT 1 FROM tbintegraSAP_CTeDocRef
                  WHERE id_documento = oid_documento
                  AND chave_doc_ref = oKeyNfeRef) THEN
      INSERT INTO tbintegraSAP_CTeDocRef (
         id_documento, chave_doc_ref, tipo_doc_ref, num_doc_ref, serie_doc_ref,
         valor_doc_ref, peso_doc_ref, data_doc_ref) VALUES (
         oid_documento, oKeyNfeRef, oTipoDoc, oNumNFE, oSerieNFE,
         NULL, NULL, NULL);
   ELSE
   BEGIN
      SET MENSAGEM = "Atualização realizada com sucesso";
      UPDATE tbintegraSAP_CTeDocRef
      SET  chave_doc_ref = oKeyNfeRef
          ,tipo_doc_ref  = tipo_doc_ref
          ,num_doc_ref   = num_doc_ref
          ,serie_doc_ref = serie_doc_ref
      WHERE id_documento = oid_documento AND chave_doc_ref = oKeyNfeRef;
   END;
   END IF;
   
   IF excecao = 1 THEN
      SET RESULTADO = "0";
      SET MENSAGEM = "Erro SQL - Verifique com o Administrador";
   END IF;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_AtualizarCTE_SLIN.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_AtualizarCTE_SLIN`$$

CREATE PROCEDURE `PROC_INTEGRA_AtualizarCTE_SLIN`(
	IN oCodUsuario				    VARCHAR(10),
	# Parametros de Retorno
	OUT RESULTADO         VARCHAR(5),
	OUT MENSAGEM          VARCHAR(500)
)
BLOCO1:BEGIN
   /*
   #Author David Ruy <20221226>
   #Reviser David Ruy <20230124> Ajuste, não excluir mais tbtms_ctrc -> atualizar data_cancel
   */

   DECLARE xNumCTE         VARCHAR(20);
   DECLARE xSerieCTE       VARCHAR(10);
   DECLARE xNumChave       VARCHAR(50);
   DECLARE xDescrDespesa   VARCHAR(100);
   DECLARE xValorDespesa   DOUBLE(18,6);
   DECLARE xNumDocRef      VARCHAR(20);
   DECLARE xSerieDocRef    VARCHAR(10);
   DECLARE xChaveDocRef    VARCHAR(50);
   DECLARE xQtdeAux        INT DEFAULT 0;

	DECLARE excecao         INT DEFAULT 0;
	#DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;

   SET RESULTADO = "1";
   SET MENSAGEM = "Inclusão realizada com sucesso";
   
   DROP TEMPORARY TABLE IF EXISTS tbTMPCTE;
   CREATE TEMPORARY TABLE tbTMPCTE
      SELECT tbCTeInvent.*, #SUM(tbVLR.valor_despesa) SomaDesp,
             GROUP_CONCAT(DISTINCT tbDocRef.num_doc_ref) AS NFs
      FROM tbintegraSAP_CTe tbCTeInvent
      LEFT JOIN tbintegraSAP_CTeVlr tbVLR ON 
         tbVLR.id_documento = tbCTeInvent.id_documento
      LEFT JOIN tbintegraSAP_CTeDocRef tbDocRef ON 
         tbDocRef.id_documento = tbCTeInvent.id_documento
      LEFT JOIN of_logistica.tbtms_ctrc_terc TbCTeTerc ON
                TbCTeTerc.id_remessa = tbCTeInvent.num_chave
      WHERE TbCTeTerc.id_remessa IS NULL
      AND tbCTeInvent.dthr_cancel IS NULL
      GROUP BY num_chave;

   INSERT INTO of_logistica.tbtms_ctrc_terc (
          cod_emp, cod_fil, cnpj_cpf_emi, raz_soc_emi, cod_ibge_emi, 
          num_ctrc, serie_ctrc, data_viagem, dthr_emiss, id_remessa,
          cnpj_cpf_rem, raz_soc_rem, cidade_rem, estado_rem, cep_rem, cod_ibge_origem, 
          cnpj_cpf_dest, raz_soc_dest, cidade_dest, estado_dest, cep_dest, cod_mun_dest, 
          vlr_tot_ctrc, num_nfs)
      (SELECT '001', '001', emi_cnpj, SUBSTRING(CardName,1,50), NULL,
              SERIAL AS NumCTE, serie_documento AS SerieCTE,data_documento, data_documento, num_chave,
              orig_cnpj, orig_raz_social, orig_cidade, orig_cep, orig_uf, IbgeCodeMuniIni, 
              dest_cnpj, dest_raz_social, dest_cidade, dest_cep, dest_uf, IbgeCodeMuniFim,
              valor_total, SUBSTRING(NFs,01,200)
       FROM tbTMPCTE);
       
       
       
   /******************************************************/
   #Atualiza valores do CTe (composição tbintegraSAP_CTeVlr)    
   DROP TEMPORARY TABLE IF EXISTS tbTMPCTEVlr;
   CREATE TEMPORARY TABLE tbTMPCTEVlr 
      SELECT tbTMPCTE.num_chave, tbTMPCTE.id_documento, tbVlr.descr_despesa, SUM(tbVlr.valor_despesa) valor_despesa
      FROM tbintegraSAP_CTeVlr tbVlr
      INNER JOIN tbTMPCTE ON
            tbTMPCTE.id_documento = tbVlr.id_documento
      WHERE IFNULL(tbVlr.valor_despesa ,0) > 0
      GROUP BY num_chave, descr_despesa;
      
   WHILE EXISTS (SELECT 1 FROM tbTMPCTEVlr) DO
   
      SELECT num_chave, descr_despesa, valor_despesa 
      INTO xNumChave, xDescrDespesa, xValorDespesa
      FROM tbTMPCTEVlr 
      LIMIT 1;
      
      IF xDescrDespesa IN ('FRETE') OR 
             xDescrDespesa LIKE '%FRETE%' THEN
         UPDATE of_logistica.tbtms_ctrc_terc
         SET vlr_frete_apag = IFNULL(vlr_frete_apag,0)     + xValorDespesa
         WHERE id_remessa = xNumChave;        
      ELSEIF xDescrDespesa IN ('GRIS','SEGURO','Advalorem') OR 
         xDescrDespesa LIKE ('%SEGURO%') OR 
         xDescrDespesa LIKE ('%Advalorem%') THEN
         UPDATE of_logistica.tbtms_ctrc_terc
         SET vlr_seguro   = IFNULL(vlr_seguro,0)   + xValorDespesa
         WHERE id_remessa = xNumChave;         
      ELSEIF xDescrDespesa IN ('ICMS') OR 
             xDescrDespesa LIKE '%ICMS%' THEN
         UPDATE of_logistica.tbtms_ctrc_terc
         SET vlr_icms     = IFNULL(vlr_icms,0)     + xValorDespesa
         WHERE id_remessa = xNumChave;         
      ELSEIF xDescrDespesa IN ('IOF') OR 
             xDescrDespesa LIKE '%IOF%' THEN
         UPDATE of_logistica.tbtms_ctrc_terc
         SET vlr_iof      = IFNULL(vlr_iof,0)      + xValorDespesa
         WHERE id_remessa = xNumChave;         
      ELSEIF xDescrDespesa IN ('TAXA') OR 
             xDescrDespesa LIKE '%TAXA%' THEN
         UPDATE of_logistica.tbtms_ctrc_terc
         SET vlr_tx_ctrc  = IFNULL(vlr_tx_ctrc,0)  + xValorDespesa
         WHERE id_remessa = xNumChave;         
      ELSEIF xDescrDespesa IN ('PEDAGIO') OR 
             xDescrDespesa LIKE '%PEDAGIO%' THEN
         UPDATE of_logistica.tbtms_ctrc_terc
         SET vlr_pedagio  = IFNULL(vlr_pedagio,0)  + xValorDespesa
         WHERE id_remessa = xNumChave;         
      ELSE 
         UPDATE of_logistica.tbtms_ctrc_terc
         SET vlr_desp_div = IFNULL(vlr_desp_div,0) + xValorDespesa
         WHERE id_remessa = xNumChave;
      END IF;       
      
      DELETE FROM tbTMPCTEVlr 
      WHERE num_chave = xNumChave
        AND descr_despesa = xDescrDespesa;
   
   END WHILE;
   SELECT COUNT(*) INTO xQtdeAux FROM tbTMPCTEVlr;   
   DROP TEMPORARY TABLE IF EXISTS tbTMPCTEVlr;
            

   /******************************************************/
   #Insere os Documentos (NF´s) Referenciadas (tbintegraSAP_CTeDocRef)  
   INSERT IGNORE INTO of_logistica.tbtms_ctrc_terc2 (
         cod_emp, cod_fil, num_ctrc, serie_ctrc, cnpj_cpf_emi, num_nf, serie_nf, chave_nfe)
         (SELECT '001', '001', SERIAL AS NumCTE, serie_documento AS SerieCTE,
             tbTMPCTE.emi_cnpj, TRIM(LEADING '0' FROM num_doc_ref) AS num_doc_ref, 
             TRIM(LEADING '0' FROM serie_doc_ref) AS serie_doc_ref, chave_doc_ref
         FROM tbintegraSAP_CTeDocRef
         INNER JOIN tbTMPCTE ON
               tbTMPCTE.id_documento = tbintegraSAP_CTeDocRef.id_documento);
   
   DROP TEMPORARY TABLE IF EXISTS tbTMPCTE;   
   
   CALL PROC_INTEGRA_EnviarLog('999999',"PROC_INTEGRA_AtualizarCTE_SLIN",xQtdeAux,"OK","Automatico OK",@R,@M);   
   
   
   
   
   
   
   
   /*******************************************************************************************/   
   #Cancelamentos
   DROP TEMPORARY TABLE IF EXISTS tbTMPCTE;
   CREATE TEMPORARY TABLE tbTMPCTE
      SELECT tbCTeInvent.*, #SUM(tbVLR.valor_despesa) SomaDesp,
             GROUP_CONCAT(DISTINCT tbDocRef.num_doc_ref) AS NFs
      FROM tbintegraSAP_CTe tbCTeInvent
      LEFT JOIN tbintegraSAP_CTeVlr tbVLR ON 
         tbVLR.id_documento = tbCTeInvent.id_documento
      LEFT JOIN tbintegraSAP_CTeDocRef tbDocRef ON 
         tbDocRef.id_documento = tbCTeInvent.id_documento
      LEFT JOIN of_logistica.tbtms_ctrc_terc TbCTeTerc ON
                TbCTeTerc.id_remessa = tbCTeInvent.num_chave
      WHERE TbCTeTerc.id_remessa IS NOT NULL
        AND tbCTeInvent.dthr_cancel IS NOT NULL
        AND TbCTeTerc.data_cancel IS NULL
      GROUP BY num_chave;
    
    SELECT COUNT(*) INTO xQtdeAux FROM tbTMPCTE;    
    
    /*DELETE FROM of_logistica.tbtms_ctrc_terc 
    WHERE EXISTS (SELECT 1 FROM tbTMPCTE 
                  WHERE tbtms_ctrc_terc.id_remessa = tbTMPCTE.num_chave);
    */

   UPDATE of_logistica.tbtms_ctrc_terc
   INNER JOIN tbTMPCTE ON 
              tbTMPCTE.num_chave = tbtms_ctrc_terc.id_remessa
   INNER JOIN of_logistica.tbtms_ctrc_terc2 ON 
              tbtms_ctrc_terc.cod_emp = tbtms_ctrc_terc2.cod_emp
          AND tbtms_ctrc_terc.cod_fil = tbtms_ctrc_terc2.cod_fil
          AND tbtms_ctrc_terc.cnpj_cpf_emi = tbtms_ctrc_terc2.cnpj_cpf_emi
          AND tbtms_ctrc_terc.num_ctrc = tbtms_ctrc_terc2.num_ctrc
          AND tbtms_ctrc_terc.serie_ctrc = tbtms_ctrc_terc2.serie_ctrc
   SET tbtms_ctrc_terc2.cod_emp_entrega = NULL,   
       tbtms_ctrc_terc2.cod_fil_entrega = NULL, 
       tbtms_ctrc_terc2.ano_entrega = NULL, 
       tbtms_ctrc_terc2.num_entrega = NULL, 
       tbtms_ctrc_terc.data_cancel = CURRENT_DATE(),
       tbtms_ctrc_terc.data_cancel_ = NOW();
     

   DROP TEMPORARY TABLE IF EXISTS tbTMPCTE;   
   
   CALL PROC_INTEGRA_EnviarLog('999999',"PROC_INTEGRA_AtualizarCTE_SLIN Cancel",xQtdeAux,"OK","Cancelamento OK",@R,@M);   
   
   
   IF excecao = 1 THEN
      SET RESULTADO = "0";
      SET MENSAGEM = "Erro SQL - Verifique com o Administrador";
   END IF;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_AtualizarCTE_Valor.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_AtualizarCTE_Valor`$$

CREATE PROCEDURE `PROC_INTEGRA_AtualizarCTE_Valor`(
	IN oCodUsuario		VARCHAR(10),
	
   IN oidAddOn       INT,
   #IN oId            INT,
   IN oDescription   VARCHAR(100),
   IN oValor         DECIMAL(18,6),

	# Parametros de Retorno
	OUT RESULTADO         VARCHAR(5),
	OUT MENSAGEM          VARCHAR(500)
)
BLOCO1:BEGIN

   DECLARE oid_documento   INT DEFAULT 0;
	DECLARE excecao         INT DEFAULT 0;
	#DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;

   SET RESULTADO = "1";
   SET MENSAGEM = "Inclusão realizada com sucesso";
   
   SELECT id_documento INTO oid_documento FROM tbintegraSAP_CTe
   WHERE idAddOn = oidAddOn;


   IF NOT EXISTS (SELECT 1 FROM tbintegraSAP_CTeVlr
                  WHERE id_documento = oid_documento
                  AND descr_despesa = oDescription) THEN
      INSERT INTO tbintegraSAP_CTeVlr (
         id_documento, tipo_despesa, descr_despesa, valor_despesa) VALUES (
         oid_documento, 1, oDescription, oValor);
   ELSE
   BEGIN
      SET MENSAGEM = "Atualização realizada com sucesso";
      UPDATE tbintegraSAP_CTeVlr
      SET  id_documento   = oid_documento
          ,tipo_despesa   = 1
          ,descr_despesa  = oDescription
          ,valor_despesa  = oValor
      WHERE id_documento = oid_documento AND descr_despesa = oDescription;
   END;
   END IF;
   
   IF excecao = 1 THEN
      SET RESULTADO = "0";
      SET MENSAGEM = "Erro SQL - Verifique com o Administrador";
   END IF;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_AtualizarDocEntry.sql*/

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
   #Reviser David Ruy <2026-07-29> Desabilitado | PROC_INTEGRA_GravarPicking fará essa funcionalidade
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
      #SET MENSAGEM  = fnMensagemExcecao(MENSAGEM);
      SET MENSAGEM  = fnMensagemExcecao(
         CONCAT('ERRO Gerar DocEntry ',oDocTipo,"",oDocNum,"|",oDocEntry," ",MENSAGEM) );
      
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
         
         #2026-07-29 Desabilitado
         #PROC_INTEGRA_GravarPicking fará essa funcionalidade
         /*
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
         */
         
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

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_AtualizarItemContagem.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_AtualizarItemContagem`$$

CREATE PROCEDURE `PROC_INTEGRA_AtualizarItemContagem`(
	IN oCodUsuario				   VARCHAR(10),
	IN oDocEntry         INT,
	IN oCodProduto       VARCHAR(30),
	IN oLineNum          INT,
	
	# Parametros de Retorno
	OUT RESULTADO        VARCHAR(5),
	OUT MENSAGEM         VARCHAR(500)
)
BLOCO1:BEGIN
   DECLARE xIncAlt    VARCHAR(01)	DEFAULT 'I';
   DECLARE xCodEmp    VARCHAR(03);
   DECLARE xCodFil    VARCHAR(03);
   DECLARE xAnoSolic  VARCHAR(04);
   DECLARE xNumSolic  VARCHAR(10);
      
   DECLARE excecao    INT DEFAULT 0;
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   #Atualizar LineNum Contagem (Base ID + ItemCode
   UPDATE tbintegraSAP_Contagem tbCont
   SET tbCont.LineNum = oLineNum
   WHERE tbCont.Id       = oDocEntry
     AND tbCont.ItemCode = oCodProduto;
  
   IF excecao = 1 THEN
      SET RESULTADO = "0";
      SET MENSAGEM = "Erro SQL (PROC_INTEGRA_AtualizarItemContagem) - Verifique com o Administrador";
      #rollback;
   ELSE
      SET RESULTADO = "1";
      SET MENSAGEM = "Atualização realizada - Status não relevante";   
      #commit;
   END IF;
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_AtualizarSLIN.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_AtualizarSLIN Verificar_20240813`$$

CREATE PROCEDURE `PROC_INTEGRA_AtualizarSLIN Verificar_20240813`(
	IN oCodUsuario				  VARCHAR(10),
	IN oDocTipo         VARCHAR(50),
	# Parametros de Retorno
	OUT RESULTADO       INT,
	OUT MENSAGEM        VARCHAR(500)
)
BLOCO1:BEGIN
  /************************************************************************
  * @Created David Ruy <2019/04/11>
  * Esta procedure realiza a atualização do SLIN de registros pendentes na base de dados intermediária da integração
  *
  *@Reviser David Ruy <2021/03/24> Cadastrar transportadora na tbclientes (PROC_INTEGRA_CAD_Fornecedor)
  *@Reviser David Ruy <2021/04/14> Gravar o campo SERIAL (xSerialNum -> NumNF Fornecedor) na GEM
  *@Reviser David Ruy <2021/08/24> Tratativa para DocTipo = "TD-<E>/<S>" Transferencia entre Depósitos
  *@Reviser David Ruy <2022/02/10> Agrupamento de SKU para TD-S quando flg_agrupa_transf=1 (Produção)
  #@Reviser David Ruy <2022/03/17> Ajuste para atualizar tbsolic_saidas_item2->deposito_integracao    (PROC_INTEGRA_GerarGSMItem)
  #@Reviser David Ruy <2022/05/11> Ajuste para atualizar tbsolic_entradas_item2->deposito_integracao  (PROC_INTEGRA_GerarGEMItem) 
  #@Reviser David Ruy <2022-08-08> Atualizar Valor (PRICE) do Item quando foi em caixas  
  #@Reviser David Ruy <2023-01-11> Alteração ifNull(UomCode,buyUnitMsr) e ifNull(UomCode,salUnitMsr)
                                   Alteração envio gerarGEM/gerarGSM xBaseQty em vez de xOpenInvQty
  #@Reviser David Ruy <2023-02-07> Alteração PROC_INTEGRA_GerarGSMItem (Parametros xBaseQty, e xOpenInvQty)
  #@Reviser David Ruy <2023-02-08> Alteração PROC_INTEGRA_GerarGEMItem (Parametros xBaseQty, e xOpenInvQty)
  #@Reviser David Ruy <2023-03-01> Alteração agrupamento linhas TD-S conforme flg_agrupa_transf
  #@Reviser David Ruy <2023-04-22> Alteração agrupamento linhas TD-S group by
  #@Reviser David Ruy <2023-07-07> Não grava numero de GEM/GSM que não tenha sido inserida corretamente  
  #@Reviser David Ruy <2023-07-14> Devolução de Vendas pegar Embalagem de Vendas
  #@Reviser David Ruy <2024-02-19> Parametro oDocTipo para isolar criação de Documentos para cada serviço
  #@Reviser David Ruy <2024-03-25> Transaction e chamada da inserção de itens  
  #@Reviser David Ruy <2024-06-19> Alteração variável xObservacoes -> SUBSTRING(tbintegraSAP_DocItem.Observacoes,1,300) 
  #@Reviser David Ruy <2024-08-29> Correção join tTabelaComTexto => tbTMPTipoDoc, tbTMPTipoDoc2
  #@Reviser David Ruy <2024-10-17> Variaveis xDepositoOrigem/xDepositoDestino (se precisar para alguma regra)
  #@Reviser David Ruy <2024-10-17> xCNPJEmpresa <> xNumCPFouCNPJ para não gerar Entregas
  #@Reviser David Ruy <2025-01-15> DocTipo = 'DC'  Devolução de Compras
  #@Reviser David Ruy <2025-01-27> xDocNumRef e xBDO_NKIT + Call Proc_IntegraSAP_GerarGEM (Versão_20240813)
  #@Reviser David Ruy <2025-07-21> #xDocNumRef, xBDO_NKIT,  Já tratados direto no GerarGEM
  #@Reviser David Ruy <2025-10-03> Não gerar TMS para TD-S
  #@Reviser David Ruy <2025-10-29> Considerar PA000 até PA099
  *************************************************************************/
   DECLARE excecao         INT DEFAULT 0;
   DECLARE xVarAux         INT DEFAULT 0;
   DECLARE xGerouGuia      BOOLEAN;
   DECLARE xDocTipo        VARCHAR(10);
   DECLARE xDocEntry       INT;
   DECLARE xDocNum         VARCHAR(20);
   DECLARE xSerialNum      INT;
   DECLARE xDocDate        DATETIME;
   DECLARE xDueDate        DATETIME;
   DECLARE xStatusDoc      VARCHAR(10);
   DECLARE xStatusEnum     INT;
   DECLARE xWhareHouse     VARCHAR(30);
   DECLARE xCardCode       VARCHAR(15);
   DECLARE xCardName       VARCHAR(100);
   DECLARE xAddrTypeS      VARCHAR(20);
   DECLARE xStreetS        VARCHAR(200);
   DECLARE xStreetNoS      VARCHAR(30);
   DECLARE xBuildingS      VARCHAR(100);
   DECLARE xBlockS         VARCHAR(100);
   DECLARE xCityS          VARCHAR(100);
   DECLARE xZipCodeS       VARCHAR(10);
   DECLARE xStateS         VARCHAR(02);
   DECLARE xCountryS       VARCHAR(50);
   DECLARE xTipoFrete      VARCHAR(05);
   DECLARE xNomeTransp     VARCHAR(50);
   DECLARE xCnpjTransp     VARCHAR(20);
   DECLARE xCFOP           VARCHAR(10);
   DECLARE xObservacoes    TEXT;
   DECLARE xNomeVendedor   VARCHAR(200)   DEFAULT "Nome Vendedor";
   DECLARE xValorPedido    DOUBLE   DEFAULT 0;
   DECLARE xFlgInclusao    BOOLEAN;
   
   DECLARE xLineNum           INT;
   DECLARE xItemCode          VARCHAR(30);
   DECLARE xBaseQty           DOUBLE;
   DECLARE xOpenInvQty        DOUBLE;
   DECLARE xVlrUnitario       DOUBLE;
   DECLARE xCambio            DOUBLE;
   DECLARE xWhareHouseIte     VARCHAR(10); 
   DECLARE xStatusItem        VARCHAR(10);
   DECLARE xObservacoesIte    VARCHAR(300); 
   DECLARE xdescription       VARCHAR(100); 
   DECLARE xbuyUnitMsr        VARCHAR(30); 
   DECLARE xsalUnitMsr        VARCHAR(30); 
   DECLARE xinvntryUom        VARCHAR(30); 
   DECLARE xNumInSale         DECIMAL(18,6);
   DECLARE xNumInBuy          DECIMAL(18,6);
   DECLARE xBatchCode         VARCHAR(30); 
   DECLARE xCodEmpWMS			      VARCHAR(03);
   DECLARE xCodFilWMS			      VARCHAR(03);
   DECLARE xAnoSolic 			      VARCHAR(04);
   DECLARE xNumSolic 			      VARCHAR(10);
   DECLARE xRefGuia           VARCHAR(30);
   DECLARE xCodErro           INT;
   DECLARE _VlrUnitario       DOUBLE   DEFAULT 1;
   DECLARE xNumItem           VARCHAR(06);
   DECLARE xStatusSlin        INT;
   DECLARE xMensagemSlin      VARCHAR(500);
   
   DECLARE xStrAux            VARCHAR(200);
   DECLARE xLog               VARCHAR(30);
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
   DECLARE xTipoProducao      VARCHAR(10);
   DECLARE xflg_agrupa_transf TINYINT;
   
   DECLARE xTipoPessoa        VARCHAR(01);
   DECLARE xNumCPF            VARCHAR(20);
   DECLARE xNumCNPJ           VARCHAR(20);
   DECLARE xNumCPFouCNPJ      VARCHAR(20);
   DECLARE xCNPJCPFCLI        VARCHAR(20);
   DECLARE xCodEmpSLIN        VARCHAR(03);
   DECLARE xCodFilSLIN        VARCHAR(03);
   DECLARE xCNPJEmpresa       VARCHAR(20);
   DECLARE xDepositoOrigem    VARCHAR(20);
   DECLARE xDepositoDestino   VARCHAR(20);
   
   DECLARE xDocTipoAux        VARCHAR(50);
   DECLARE xDocNumRef         VARCHAR(50);
   DECLARE xBDO_NKIT          VARCHAR(50);
   
   SELECT flg_agrupa_transf INTO xflg_agrupa_transf 
   FROM tbintegraSAP_parametros LIMIT 1;
   
   
   IF oDocTipo = "" THEN
      CREATE TEMPORARY TABLE tTabelaComTexto (Coluna01 VARCHAR(100));
      INSERT INTO tTabelaComTexto SELECT DocTipo FROM tbintegraSAP_TipoDoc;

      DROP TEMPORARY TABLE IF EXISTS tbTMPTipoDoc;
      CREATE TEMPORARY TABLE tbTMPTipoDoc (SELECT * FROM tTabelaComTexto);

      DROP TEMPORARY TABLE IF EXISTS tbTMPTipoDoc2;
      CREATE TEMPORARY TABLE tbTMPTipoDoc2 (SELECT * FROM tTabelaComTexto);

   ELSE
      CALL PROC_SYS_GerarTabelaComTexto(oDocTipo,'|',1);
      
      DROP TEMPORARY TABLE IF EXISTS tbTMPTipoDoc;
      CREATE TEMPORARY TABLE tbTMPTipoDoc (SELECT * FROM tTabelaComTexto);
      
      #Insere PA000 até PA099
      IF EXISTS (SELECT 1 FROM tbTMPTipoDoc WHERE Coluna01 = 'PA') THEN
         SET xVarAux = 0;
         WHILE xVarAux <= 99 DO
            INSERT INTO tbTMPTipoDoc (Coluna01) VALUES (CONCAT('PA',LPAD(xVarAux,3,'0')));
            SET xVarAux = xVarAux + 1;
         END WHILE;
      END IF;
      #select * from tbTMPTipoDoc; leave BLOCO1;
      
      DROP TEMPORARY TABLE IF EXISTS tbTMPTipoDoc2;
      CREATE TEMPORARY TABLE tbTMPTipoDoc2 (SELECT * FROM tbTMPTipoDoc);

   END IF;
   
 
   #1a fase - Inserir documentos sem id-SLIN
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraDocTopo;
   CREATE TEMPORARY TABLE tbtmp_IntegraDocTopo 
      SELECT tbintegraSAP_Doc.*,
             tbintegraSAP_empresas.cod_emp_slin AS CodEmpSLIN,
             tbintegraSAP_empresas.cod_fil_slin AS CodFilSLIN,
             tbintegraSAP_empresas.cnpj_empresa AS CNPJEmpresa,
             tbDepOri.cod_deposito DepositoOrigem, tbDepDest.cod_deposito DepositoDestino
      FROM tbintegraSAP_Doc
      INNER JOIN tbTMPTipoDoc ON
                 tbTMPTipoDoc.Coluna01 = tbintegraSAP_Doc.DocTipo
      INNER JOIN tbintegraSAP_empresas ON 
                 tbintegraSAP_empresas.id_integracao = tbintegraSAP_Doc.BPLId
      LEFT JOIN tbintegraSAP_Depositos tbDepOri ON
                tbintegraSAP_Doc.WhareHouse = tbDepOri.cod_deposito
      LEFT JOIN tbintegraSAP_Depositos tbDepDest ON
                tbintegraSAP_Doc.WhareHouseTransf = tbDepDest.cod_deposito
      #WHERE cod_emp IS NULL
      #WHERE StatusDoc <= "3"
      WHERE StatusDoc < "3"      
      # Se PV ou OP precisa ter criado o picking (validação de saldo no SAP) para poder gerar no SLIN
      AND IF(Doctipo IN ('PV','OP','TD-S','NS'), idPicking IS NOT NULL, TRUE)
      ORDER BY DocTipo, DocEntry, DocNum;
      
   #Tabela Gemea para Union
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraDocTopo2;
   CREATE TEMPORARY TABLE tbtmp_IntegraDocTopo2 
      SELECT tbintegraSAP_Doc.*,
             tbintegraSAP_empresas.cod_emp_slin AS CodEmpSLIN,
             tbintegraSAP_empresas.cod_fil_slin AS CodFilSLIN,
             tbintegraSAP_empresas.cnpj_empresa AS CNPJEmpresa,
             tbDepOri.cod_deposito DepositoOrigem, tbDepDest.cod_deposito DepositoDestino
      FROM tbintegraSAP_Doc
      INNER JOIN tbTMPTipoDoc ON
                 tbTMPTipoDoc.Coluna01 = tbintegraSAP_Doc.DocTipo
      INNER JOIN tbintegraSAP_empresas ON 
                 tbintegraSAP_empresas.id_integracao = tbintegraSAP_Doc.BPLId
      LEFT JOIN tbintegraSAP_Depositos tbDepOri ON
                tbintegraSAP_Doc.WhareHouse = tbDepOri.cod_deposito
      LEFT JOIN tbintegraSAP_Depositos tbDepDest ON
                tbintegraSAP_Doc.WhareHouseTransf = tbDepDest.cod_deposito
      #WHERE cod_emp IS NULL
      #WHERE StatusDoc <= "3"
      WHERE StatusDoc < "3"      
      # Se PV ou OP precisa ter criado o picking (validação de saldo no SAP) para poder gerar no SLIN
      AND IF(Doctipo IN ('PV','OP','TD-S','NS'), idPicking IS NOT NULL, TRUE)
      ORDER BY DocTipo, DocEntry, DocNum;
      
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraDocItem;
   IF xflg_agrupa_transf = 0 THEN   
      CREATE TEMPORARY TABLE tbtmp_IntegraDocItem
         SELECT tbintegraSAP_DocItem.* FROM tbintegraSAP_DocItem
         INNER JOIN tbtmp_IntegraDocTopo Topo ON
                    Topo.DocEntry = tbintegraSAP_DocItem.DocEntry
                AND Topo.DocTipo  = tbintegraSAP_DocItem.DocTipo                 
                AND Topo.DocNum   = tbintegraSAP_DocItem.DocNum
         INNER JOIN tbintegraSAP_Doc ON
             tbintegraSAP_Doc.DocEntry = tbintegraSAP_DocItem.DocEntry
         AND tbintegraSAP_Doc.DocTipo  = tbintegraSAP_DocItem.DocTipo
         AND tbintegraSAP_Doc.DocNum   = tbintegraSAP_DocItem.DocNum
         INNER JOIN tbTMPTipoDoc ON
                    tbTMPTipoDoc.Coluna01 = tbintegraSAP_Doc.DocTipo
         #WHERE tbintegraSAP_Doc.cod_emp IS NULL
         WHERE TRUE #StatusDoc <= "3"
         # Se PV ou OP precisa ter criado o picking (validação de saldo no SAP) para poder gerar no SLIN
         AND IF(tbintegraSAP_DocItem.Doctipo IN ('PV','OP','TD-S','NS'), tbintegraSAP_Doc.idPicking IS NOT NULL, TRUE)
         AND IFNULL(tbintegraSAP_DocItem.StatusItem,'0') <= '2'  #Traz os itens com status nulo (a inserir) e 1 = A atualizar
         ORDER BY tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.LineNum;
   ELSE
      CREATE TEMPORARY TABLE tbtmp_IntegraDocItem
         (
            #SELECT tbintegraSAP_DocItem.* 
            SELECT tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocNum, 
                   tbintegraSAP_DocItem.LineNum, 
                   tbintegraSAP_DocItem.ItemCode, tbintegraSAP_DocItem.BaseQty, tbintegraSAP_DocItem.OpenInvQty,
                   (tbintegraSAP_DocItem.Price*IF(IFNULL(tbintegraSAP_DocItem.DollarQuote,0)=0,1,tbintegraSAP_DocItem.DollarQuote)) Price,              
                   tbintegraSAP_DocItem.DollarQuote,
                   tbintegraSAP_DocItem.WhareHouse, 
                   tbintegraSAP_DocItem.StatusItem, 
                   tbintegraSAP_DocItem.UomCode,
                   #SUBSTRING(tbintegraSAP_DocItem.Observacoes,1,300) AS Observacoes, 
                   tbintegraSAP_DocItem.Observacoes,
                   tbintegraSAP_DocItem.description, tbintegraSAP_DocItem.buyUnitMsr, tbintegraSAP_DocItem.salUnitMsr, 
                   tbintegraSAP_DocItem.invntryUom, 
                   tbintegraSAP_DocItem.NumInSale, tbintegraSAP_DocItem.NumInBuy, tbintegraSAP_DocItem.BatchNumbersCode  
            FROM tbintegraSAP_DocItem
            INNER JOIN tbtmp_IntegraDocTopo Topo ON
                       Topo.DocEntry = tbintegraSAP_DocItem.DocEntry
                   AND Topo.DocTipo  = tbintegraSAP_DocItem.DocTipo                 
                   AND Topo.DocNum   = tbintegraSAP_DocItem.DocNum
            INNER JOIN tbintegraSAP_Doc ON
                tbintegraSAP_Doc.DocEntry = tbintegraSAP_DocItem.DocEntry
            AND tbintegraSAP_Doc.DocTipo  = tbintegraSAP_DocItem.DocTipo
            AND tbintegraSAP_Doc.DocNum   = tbintegraSAP_DocItem.DocNum
            INNER JOIN tbTMPTipoDoc2 ON
                       tbTMPTipoDoc2.Coluna01 = tbintegraSAP_Doc.DocTipo
            #WHERE tbintegraSAP_Doc.cod_emp IS NULL
            WHERE NOT (tbintegraSAP_DocItem.Doctipo = 'TD-S')
            # Se PV ou OP precisa ter criado o picking (validação de saldo no SAP) para poder gerar no SLIN
            AND IF(tbintegraSAP_DocItem.Doctipo IN ('PV','OP','TD-S','NS'), tbintegraSAP_Doc.idPicking IS NOT NULL, TRUE)
            #Verificar : estava antes IFNULL(tbintegraSAP_DocItem.StatusItem,'2') 
            AND IFNULL(tbintegraSAP_DocItem.StatusItem,'0') <= '1'  #Traz os itens com status nulo (a inserir) e 1 = A atualizar
            ORDER BY tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.LineNum
         )
         UNION
         (
            #SELECT tbintegraSAP_DocItem.* FROM tbintegraSAP_DocItem
            SELECT tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocNum, 
                   tbintegraSAP_DocItem.LineNum, 
                   tbintegraSAP_DocItem.ItemCode, SUM(tbintegraSAP_DocItem.BaseQty) BaseQty, SUM(tbintegraSAP_DocItem.OpenInvQty) OpenInvQty,
                   (tbintegraSAP_DocItem.Price*IF(IFNULL(tbintegraSAP_DocItem.DollarQuote,0)=0,1,tbintegraSAP_DocItem.DollarQuote)) Price, 
                   tbintegraSAP_DocItem.DollarQuote,
                   tbintegraSAP_DocItem.WhareHouse, 
                   tbintegraSAP_DocItem.StatusItem, 
                   tbintegraSAP_DocItem.UomCode,
                   #SUBSTRING(tbintegraSAP_DocItem.Observacoes,1,300) AS Observacoes, 
                   tbintegraSAP_DocItem.Observacoes,
                   tbintegraSAP_DocItem.description, tbintegraSAP_DocItem.buyUnitMsr, tbintegraSAP_DocItem.salUnitMsr, 
                   tbintegraSAP_DocItem.invntryUom, 
                   tbintegraSAP_DocItem.NumInSale, tbintegraSAP_DocItem.NumInBuy, tbintegraSAP_DocItem.BatchNumbersCode
            FROM tbintegraSAP_DocItem
            INNER JOIN tbtmp_IntegraDocTopo2 Topo ON
                       Topo.DocEntry = tbintegraSAP_DocItem.DocEntry
                   AND Topo.DocTipo  = tbintegraSAP_DocItem.DocTipo                 
                   AND Topo.DocNum   = tbintegraSAP_DocItem.DocNum
            INNER JOIN tbintegraSAP_Doc ON
                tbintegraSAP_Doc.DocEntry = tbintegraSAP_DocItem.DocEntry
            AND tbintegraSAP_Doc.DocTipo  = tbintegraSAP_DocItem.DocTipo
            AND tbintegraSAP_Doc.DocNum   = tbintegraSAP_DocItem.DocNum
            INNER JOIN tTabelaComTexto ON
                       tTabelaComTexto.Coluna01 = tbintegraSAP_Doc.DocTipo
            #WHERE tbintegraSAP_Doc.cod_emp IS NULL
            WHERE (tbintegraSAP_DocItem.Doctipo = 'TD-S')
            # Se PV ou OP precisa ter criado o picking (validação de saldo no SAP) para poder gerar no SLIN
            AND IF(tbintegraSAP_DocItem.Doctipo IN ('PV','OP','TD-S','NS'), tbintegraSAP_Doc.idPicking IS NOT NULL, TRUE)
            #Verificar : estava antes IFNULL(tbintegraSAP_DocItem.StatusItem,'2') 
            AND IFNULL(tbintegraSAP_DocItem.StatusItem,'2') <= '1'  #Traz os itens com status nulo (a inserir) e 1 = A atualizar
            GROUP BY tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.DocNum, tbintegraSAP_DocItem.ItemCode
            ORDER BY tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.DocNum, tbintegraSAP_DocItem.LineNum
         );
         
         #select * from tbtmp_IntegraDocTopo ;
         #SELECT * from tbtmp_IntegraDocTopo2;
         DELETE FROM tbtmp_IntegraDocTopo 
         WHERE Doctipo IN ('TD-S');
         
         INSERT INTO tbtmp_IntegraDocTopo 
            SELECT * FROM tbtmp_IntegraDocTopo2
            WHERE Doctipo IN ('TD-S')
            GROUP BY Doctipo, DocEntry;
         
   END IF;
   #select * from tbtmp_IntegraDocTopo;
   #select * from tbtmp_IntegraDocItem;
   #leave BLOCO1;

   
   
   DROP TEMPORARY TABLE IF EXISTS tTabelaComTexto;
   DROP TEMPORARY TABLE IF EXISTS tbTMPTipoDoc;
   DROP TEMPORARY TABLE IF EXISTS tbTMPTipoDoc2;
   
   
   #Atualizar Valor do Item quando for em caixas
   UPDATE tbtmp_IntegraDocItem
   SET Price = Price * IFNULL(BaseQty,1) / IFNULL(OpenInvQty,BaseQty)
   WHERE IFNULL(OpenInvQty,0) > 0 AND IFNULL(BaseQty,0) > 0;
   
   
   #Varre a lista de Documentos para inserir no SLIN   
   SET xEnd_Entrega = NULL;
   WHILE EXISTS (SELECT 1 FROM tbtmp_IntegraDocTopo) DO
      SELECT DocTipo, DocEntry, DocNum, DocDate, DueDate, StatusDoc, StatusEnum, WhareHouse, 
             CardCode, CardName, NumCPF, NumCNPJ, SERIAL,
             AddrTypeS, SUBSTRING(StreetS,1,50), StreetNoS, SUBSTRING(BuildingS,1,50), SUBSTRING(BlockS,1,50), SUBSTRING(CityS,1,50), ZipCodeS, StateS, CountryS, 
             NomeVendedor, TipoFrete, NomeTransp, SUBSTRING(CnpjTransp,1,14), CFOP,
             StartTime1, EndTime1, StartTime2, EndTime2, End_Entrega,
             Observacoes, IFNULL(TipoProducao,"PEX"),
             CodEmpSLIN, CodFilSLIN, CNPJEmpresa, DepositoOrigem, DepositoDestino,             
             DocNumRef, U_BDO_NKIT,
             CodEmpSLIN, CodFilSLIN
      INTO xDocTipo, xDocEntry, xDocNum, xDocDate, xDueDate, xStatusDoc, xStatusEnum, xWhareHouse, 
             xCardCode, xCardName, xNumCPF, xNumCNPJ, xSerialNum,
             xAddrTypeS, xStreetS, xStreetNoS, xBuildingS, xBlockS, xCityS, xZipCodeS, xStateS, xCountryS,
             xNomeVendedor, xTipoFrete, xNomeTransp, xCnpjTransp, xCFOP,
             xhora1_entrega, xhora2_entrega, xhora3_entrega, xhora4_entrega, xEnd_Entrega,
             xObservacoes, xTipoProducao,
             xCodEmpSLIN, xCodFilSLIN, xCNPJEmpresa, xDepositoOrigem, xDepositoDestino,             
             xDocNumRef, xBDO_NKIT,
             xCodEmpSLIN, xCodFilSLIN
      FROM tbtmp_IntegraDocTopo 
      LIMIT 1;
      
      #Valores dos campos em letra maiúscula
      SET xCardName = UPPER(xCardName);
      SET xAddrTypeS = UPPER(xAddrTypeS);
      SET xStreetS = UPPER(xStreetS);
      SET xBuildingS = UPPER(xBuildingS);
      SET xStreetNoS = UPPER(xStreetNoS);
      SET xBlockS = UPPER(xBlockS);
      SET xCityS = UPPER(xCityS);
      SET xStateS = UPPER(xStateS);
      SET xCountryS = UPPER(xCountryS);
      SET xNumCPF  = of_logistica.fnTirarCaracteresEspeciais(xNumCPF);
      SET xNumCNPJ = of_logistica.fnTirarCaracteresEspeciais(xNumCNPJ);
      SET xNumCPFouCNPJ = IFNULL(IFNULL(xNumCPF,xNumCNPJ),'');
      #SET xTipoPessoa = IF(LENGTH(xNumCPFouCNPJ)=0,'',IF(LENGTH(xNumCPFouCNPJ)=14,'J','F'));
      SET xTipoPessoa = IF(LENGTH(IFNULL(xNumCPF,''))>0,'F', IF(LENGTH(IFNULL(xNumCNPJ,''))>0,'J', ''));
            
      
      #Nomes das Variáveis de Endereço SLIN
      #IF xEnd_Entrega IS NULL THEN
         SET xEndereco   = CONCAT(IFNULL(xAddrTypeS,''), IF(IFNULL(xStreetS,'')='','',' '), IFNULL(xStreetS,''));
         SET xNumEnde    = xStreetNoS;
         SET xComplEnde  = xBuildingS;
         SET xBairroEnde = xBlockS;
         SET xCidadeEnde = xCityS;
         SET xCepEnde    = fnSoNumeros(xZipCodeS,'');
         SET xUFEnde     = xStateS;
         SET xPaisEnde   = xCountryS;
      /*ELSE
         #logradouro,numero <newline> complemento <newline> Bairro <newline> cep - Cidade - Estado <newline> pais         
         CALL PROC_INTEGRA_MontaEndereco(xEnd_Entrega, xLog, xEndereco, xNumEnde, xComplEnde, xBairroEnde, xCepEnde, xCidadeEnde, xUFEnde, xPaisEnde);
         SET xEndereco   = IFNULL(CONCAT(xLog,' ',xEndereco), CONCAT('*',IFNULL(xAddrTypeS,''), IF(IFNULL(xStreetS,'')='','',' '), IFNULL(xStreetS,'')));
         SET xNumEnde    = IFNULL(xNumEnde, CONCAT('*',xStreetNoS));
         SET xComplEnde  = IFNULL(xComplEnde, CONCAT('*',xBuildingS));
         SET xBairroEnde = IFNULL(xBairroEnde, CONCAT('*',xBlockS));
         SET xCidadeEnde = IFNULL(xCidadeEnde, CONCAT('*',xCityS));
         SET xCepEnde    = IFNULL(xCepEnde, xZipCodeS);
         SET xUFEnde     = IFNULL(xUFEnde, CONCAT('*',xStateS));
         SET xPaisEnde   = IFNULL(xPaisEnde, CONCAT('*',xCountryS));
         
         SET xCepEnde    = fnSoNumeros(xCepEnde,'');
      END IF;*/
      SET xCnpjTransp = fnTirarCaracteresEspeciais(xCnpjTransp);
      
      
      #IF xDocTipo IN ("PV","NFD","DEV","OP") THEN
      SET xFlgInclusao = FALSE;
      IF xDocTipo IN ('PV','OP','TD-S','NS','DC') THEN
         CALL PROC_INTEGRA_GerarGSM(oCodUsuario, xCodEmpSLIN, xCodFilSLIN, xDocTipo, xDocEntry, xDocNum, xDocDate, xDueDate, 
                                    xCardCode, xCardName, xObservacoes, xNomeVendedor, xValorPedido, 
                                    xTipoFrete, xNomeTransp, xCnpjTransp, @R, @M);
      #ELSEIF xDocTipo IN ("REC","NFE","PC","NE") THEN
      ELSEIF xDocTipo IN ('NE','E-RM','E-NE','DV','TD-E') OR (xDocTipo LIKE "PA%") THEN
         CALL PROC_INTEGRA_GerarGEM(oCodUsuario, xCodEmpSLIN, xCodFilSLIN, xDocTipo, xDocEntry, xDocNum, xSerialNum, xDocDate, 
                                    xCardCode, xCardName, xCFOP, xObservacoes, 
                                    #Reviser David Ruy <2025-01-27> 
                                    #Reviser David Ruy <2025-07-21> Já tratados direto no GerarGEM
                                    #xDocNumRef, xBDO_NKIT, 
                                    @R, @M);
         SET xFlgInclusao = IF(@R=0,FALSE,TRUE);                                                                        
         #select oCodUsuario, xCodEmpSLIN, xCodFilSLIN, xDocTipo, xDocEntry, xDocNum, xSerialNum, xDocDate, 
         #                           xCardCode, xCardName, xCFOP, xObservacoes, @R, @M;
      END IF;   
      SET xStatusSlin = @R;
      SET xMensagemSlin = @M;
      
      CALL PROC_INTEGRA_EnviarLog('999999', 
           #20230526 -> Ajuste Log para apresentar xMensagemSlin
           IF(xDocTipo IN ('PV','OP','TD-S','NS','DC'), 'PROC_INTEGRA_GerarGSM', 'PROC_INTEGRA_GerarGEM'),
           CONCAT(CONCAT(xDocTipo,xDocEntry," ",xMensagemSlin), @R, @M ), "0", @M, xStatusSlin, @M);
      SET xGerouGuia = FALSE;
      
      IF xStatusSlin <> 0 THEN
         SET xGerouGuia = TRUE;
         SET xRefGuia   = SUBSTRING(xMensagemSlin,01,20);
         SET xCodEmpWMS	= SUBSTRING(xRefGuia,01,03);
         SET xCodFilWMS	= SUBSTRING(xRefGuia,04,03);
         SET xAnoSolic 	= SUBSTRING(xRefGuia,07,04);
         SET xNumSolic 	= SUBSTRING(xRefGuia,11,10);
         #Variavel atualizada pela rotina que insere o topo
         #SET xFlgInclusao = FALSE;
         
         #@Reviser David Ruy <2023-07-07> Não grava numero de GEM/GSM que não tenha sido inserida corretamente
         #Evita de gravar a mensagem de retorno nos campos cod_emp/cod_fil/ano_solic/num_solic
         IF (xNumSolic = fnSonumeros(xNumSolic,'')) THEN
            UPDATE tbintegraSAP_Doc
            SET cod_emp   = xCodEmpWMS
               ,cod_fil   = xCodFilWMS
               ,ano_solic = xAnoSolic
               ,num_solic = xNumSolic
               ,TipoDocSLIN = IF(xDocTipo IN ('PV','OP','TD-S','NS','DC'),"S","E")
               ,StatusAnt  = StatusDoc
               ,StatusDoc  = IF(StatusDoc <= '2', '3', StatusDoc)
               ,StatusSlin = xStatusSlin
            WHERE DocTipo  = xDocTipo
              AND DocEntry = xDocEntry
              AND DocNum   = xDocNum;
         END IF;
           
           
/*************************************************************************************************/
#
/*************************************************************************************************/
           
         #Insere / Atualiza Itens  
         WHILE FALSE DO
         #WHILE EXISTS (SELECT 1 FROM tbtmp_IntegraDocItem
         #              WHERE DocTipo  = xDocTipo
         #                AND DocEntry = xDocEntry
         #              ORDER BY LineNum) DO
                       
            #SELECT LineNum, ItemCode, BaseQty, (Price*IF(IFNULL(DollarQuote,0)=0,1,DollarQuote)), WhareHouse, StatusItem, Observacoes, 
            #@Reviser David Ruy <2023-01-11> considerar BaseQty, nova variável  "xOpenInvQty"
            #SELECT LineNum, ItemCode, IF(IFNULL(OpenInvQty,0)=0,BaseQty,OpenInvQty), 
            SELECT LineNum, ItemCode, BaseQty, IFNULL(OpenInvQty, BaseQty),
                   (Price*IF(IFNULL(DollarQuote,0)=0,1,DollarQuote)), WhareHouse, StatusItem, Observacoes, 
                   #description, buyUnitMsr, salUnitMsr, invntryUom, 
                   #description, IFNULL(UomCode,buyUnitMsr), IFNULL(UomCode,salUnitMsr), invntryUom, 
                   description, IFNULL(buyUnitMsr,UomCode), IFNULL(salUnitMsr,UomCode), invntryUom, 
                   NumInSale, NumInBuy, BatchNumbersCode
            INTO xLineNum, xItemCode, xBaseQty, xOpenInvQty, xVlrUnitario, xWhareHouseIte, xStatusItem, xObservacoesIte,
                 xdescription, xbuyUnitMsr, xsalUnitMsr, xinvntryUom, 
                 xNumInSale, xNumInBuy, xBatchCode
            FROM tbtmp_IntegraDocItem
            WHERE DocTipo  = xDocTipo
              AND DocEntry = xDocEntry
              AND DocNum   = xDocNum
            ORDER BY LineNum LIMIT 1;
            
            SET xVlrUnitario = IF(IFNULL(xVlrUnitario,1)=0,1,IFNULL(xVlrUnitario,1));
            SET xdescription = IFNULL(xdescription,'');
            SET xbuyUnitMsr = IFNULL(xbuyUnitMsr,'');
            SET xsalUnitMsr = IFNULL(xsalUnitMsr,'');
            SET xinvntryUom = IFNULL(xinvntryUom,'');
            SET xObservacoesIte = SUBSTRING(xObservacoesIte,1,300);
           
            #@Reviser David Ruy <2023-07-14> Devolução de Vendas pegar Embalagem de Vendas
            #SELECT "===>",xItemCode, xSalUnitMsr, xbuyUnitMsr, xinvntryUom, xNumInSale, xNumInBuy, xBaseQty, xOpenInvQty;
            IF xDocTipo = 'DV' THEN
		SET xbuyUnitMsr = xSalUnitMsr;
	    END IF;
            
            IF xDocTipo IN ('PV','OP','TD-S','NS','DC') THEN
               -- CALL PROC_INTEGRA_GerarGSMItem(oCodUsuario, xRefGuia, CONCAT(xDocNum,'(',xDocEntry,')'), xLineNum, xItemCode, xdescription, xBaseQty, xOpenInvQty, xVlrUnitario, 
               --             xsalUnitMsr, xinvntryUom, xNumInsale, xStatusItem, xObservacoesIte, xCardCode, xCardName, xBatchCode, xWhareHouseIte, @R, @M);
               SET @R = 1;
               SET @M = CONCAT("Item Inserido pela nova rotina L=",xLineNum," It=", xItemCode, " Desc=", xdescription);
            ELSEIF xDocTipo IN ('NE','E-RM','E-NE','DV','TD-E') OR (xDocTipo LIKE "PA%") THEN
               -- CALL PROC_INTEGRA_GerarGEMItem(oCodUsuario, xRefGuia, CONCAT(xDocNum,'(',xDocEntry,')'), xLineNum, xItemCode, xBaseQty, xOpenInvQty, xVlrUnitario, 
               --             xStatusItem, xObservacoesIte, xdescription, xbuyUnitMsr, xinvntryUom, xNumInBuy, xWhareHouseIte, @R, @M);            
               SET @R = 1;
               SET @M = CONCAT("Item Inserido pela nova rotina L=",xLineNum," It=", xItemCode, " Desc=", xdescription);
               
               #Se teve inclusão de Itens para gerar aconselhamento               
               #IF NOT xFlgInclusao  THEN
               #   SET xFlgInclusao = IF(@R=0,FALSE,SUBSTRING(@M,08,01)="I");                                    
               #END IF;
               
            END IF;
            
            #select oCodUsuario, xRefGuia, CONCAT(xDocNum,'(',xDocEntry,')'), xLineNum, xItemCode, xdescription, xBaseQty, xOpenInvQty, xVlrUnitario, 
            #               xsalUnitMsr, xinvntryUom, xNumInsale, xStatusItem, xObservacoesIte, xCardCode, xCardName, xBatchCode, xWhareHouseIte, @R, @M;
                        
            SET xStatusItem = @R;
            SET xNumItem    = SUBSTRING(@M,01,06);  #Numero do item no retorno da proc
            CALL PROC_INTEGRA_EnviarLog('999999',
                   IF(xDocTipo IN ('PV','OP','TD-S','NS','DC'), 'PROC_INTEGRA_GerarGSMItem', 'PROC_INTEGRA_GerarGEMItem'),
                     CONCAT('Inserido/Atualizado ',xDocTipo,xDocEntry,'-',xDocNum,' | ', xRefGuia, '| Prd:', xItemCode), "200", @M, @R, @M);
            
            IF (xStatusItem <> 0) AND (@R = 1) THEN
               UPDATE tbintegraSAP_DocItem
               SET cod_emp     = xCodEmpWMS
                  ,cod_fil     = xCodFilWMS
                  ,ano_solic   = xAnoSolic
                  ,num_solic   = xNumSolic
                  ,num_item    = xNumItem
                  ,StatusItem  = '0'    #Volta para Zero para identificar que já atualizou no SLIN
               WHERE DocTipo  = xDocTipo
                 AND DocEntry = xDocEntry
                 AND DocNum   = xDocNum
                 AND IF(xflg_agrupa_transf=0 OR xDocTipo <> "TD-S", LineNum  = xLineNum, ItemCode = xItemCode);            
            ELSE
                CALL PROC_INTEGRA_EnviarLog('999999',
                      IF(xDocTipo IN ('PV','OP','TD-S','DC'),'PROC_INTEGRA_GerarGSMItem','PROC_INTEGRA_GerarGEMItem'), 
                        CONCAT('NÃO Inserido/Atualizado ',xDocTipo,xDocEntry,'-',xDocNum,' | ', xRefGuia, '| Prd:', xItemCode), "0", @M, @R, @M);
            END IF;
            
-- Aqui Novo IF   (desabilitado)         
--            END IF;
            
            DELETE FROM tbtmp_IntegraDocItem
            WHERE DocTipo  = xDocTipo
              AND DocEntry = xDocEntry
              AND LineNum  = xLineNum;
                            
         END WHILE;
/*************************************************************************************************/
#
/*************************************************************************************************/
         
         #@Reviser David Ruy <2020-11-25>
         #Aconselhamento de Entradas com endereçamento
         IF xFlgInclusao THEN
            CALL of_logistica.PROC_WMS_DESCARGA_GERAR_ACONSELHAMENTO_TOTAL(1, xCodEmpWMS	, xCodFilWMS	, xAnoSolic, xNumSolic, 1, '999999', @R, @M);
            CALL PROC_INTEGRA_EnviarLog('999999',
                  'PROC_WMS_DESCARGA_GERAR_ACONSELHAMENTO_TOTAL', 
                    CONCAT('Aconselhamento Endereço =>',xCodEmpWMS	, xCodFilWMS	, xAnoSolic, xNumSolic), "1", @M, @R, @M);            
         END IF;
         
      ELSE
          CALL PROC_INTEGRA_EnviarLog('999999',
                IF(xDocTipo IN ('PV','OP','TD-S','NS','DC'),'PROC_INTEGRA_GerarGSM','PROC_INTEGRA_GerarGEM'), 
                  CONCAT('Não Inserido ', xDocTipo, CAST(xDocEntry AS CHAR), '-', xDocNum,'|', xCardName), "0", @M, @R, @M);
      END IF;
      
      SELECT cnpj_cpf_cli INTO xCNPJCPFCLI FROM of_logistica.tbsolic_saidas
      WHERE cod_emp   = xCodEmpWMS 
        AND cod_fil   = xCodFilWMS
        AND ano_solic = xAnoSolic
        AND num_solic = xNumSolic;
        
      IF xGerouGuia AND (IFNULL(xCnpjTransp,'') <> '') AND (xDocTipo IN ('PV','NS') ) THEN
         #Atualizar cadastro de Transportadores (tbwms_terceiros)
         CALL PROC_INTEGRA_CAD_Terceiro('999999', xCNPJCPFCLI, xCnpjTransp, '1', xNomeTransp, xNomeTransp, 1, @R, @M);
         #Atualizar cadastro de Transportadores (tbclientes)
         CALL PROC_INTEGRA_CAD_Fornecedor('999999', xCnpjTransp, xNomeTransp, xNomeTransp, @R, @M);
         
         
         /*#Cadastro de Fornecedores (Transportadora para o TMS)
         CALL PROC_INTEGRA_CAD_ClienteFornecedor('999999',
                                                   xCnpjTransp, "J", "F", 
                                                   xNomeTransp, xNomeTransp, 
                                                   'x', #oInscrEstadual			VARCHAR(20),
                                                   '9', #oIndicadorIE			  VARCHAR(1),	
                                                   'x', #oEndereco				VARCHAR(50),
                                                   'x', #oNumEnde					VARCHAR(10),
                                                   NULL,#oComplEnde				VARCHAR(20),
                                                   'x', #oBairroEnde				VARCHAR(50),
                                                   'x', #oCidadeEnde				VARCHAR(50),
                                                   'x', #oUFEnde					VARCHAR(02),
                                                   '00000000', #oCepEnde		VARCHAR(08),
                                                   NULL,#oContato01				VARCHAR(20),
                                                   NULL,#oFone01 					VARCHAR(20),
                                                   NULL,#oEmail01 				VARCHAR(40),
                                                   NULL,#oContato02 				VARCHAR(20),
                                                   NULL,#oFone02 					VARCHAR(20),
                                                   NULL,#oEmail02 				VARCHAR(40),
                                                   NULL,#oContato03 				VARCHAR(20),
                                                   NULL,#oFone03 					VARCHAR(20),
                                                   NULL,#oEmail03 				VARCHAR(40),
                                                   NULL,#oEmail_fiscal 			VARCHAR(500),
                                                   'S',#oStatusAtivo				VARCHAR(01),
                                                   @R, @M);
         */
         
            # Desabilitado em 14/12/2020
            # Atualizar cadastro de destinatarios (Transportadora)
            /*CALL PROC_INTEGRA_CAD_Destinatario(oCodUsuario, xCNPJCPFCLI, xCnpjTransp, "J", 
                               SUBSTRING(xNomeTransp,1,60), SUBSTRING(xNomeTransp,1,40),
                               NULL, 9,
                               'x', 'x', xComplEnde, 'x',
                               'x', 'x', '00000000', NULL,
                               NULL, NULL, 'S',
                               # Parametros de Retorno
                               @RESULTADO, @MENSAGEM);
            */
      END IF;    
      
      IF xGerouGuia THEN
         #IF xDocTipo IN ("PV","TD-S","NS") AND (xTipoProducao IN ("PEX","PEC") AND (xCNPJEmpresa <> xNumCPFouCNPJ)) THEN
         #2025-10-03 Não gerar Transporte para TD-S
         IF xDocTipo IN ("PV","NS") AND (xTipoProducao IN ("PEX","PEC") AND (xCNPJEmpresa <> xNumCPFouCNPJ)) THEN
            # Atualizar cadastro de destinatarios
            CALL PROC_INTEGRA_CAD_Destinatario(oCodUsuario, xCNPJCPFCLI, xCardCode, xTipoPessoa, 
                               SUBSTRING(xCardName,1,60), SUBSTRING(xCardName,1,50),
                               IFNULL(@oInscrEstadual,'123'), IFNULL(@oIndicadorIE,9),
                               xEndereco, xNumEnde, xComplEnde, xBairroEnde,
                               xCidadeEnde, xUFEnde, xCepEnde, @oContato01,
                               @oFone01, @oEmail01, @oStatusAtivo, 
                               xhora1_entrega, xhora2_entrega, xhora3_entrega, xhora4_entrega,
                               # Parametros de Retorno
                               @RESULTADO, @MENSAGEM);
                               
            # Alimentar TMS com o pedido
            CALL PROC_INTEGRA_TMS_GERAR_ENTREGAS(xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xTipoFrete, xCnpjTransp, xNomeTransp, @RESULTADO, @MENSAGEM);
         END IF;
      END IF;
      
      DELETE FROM tbtmp_IntegraDocTopo
      WHERE DocTipo  = xDocTipo
        AND DocEntry = xDocEntry
        AND DocNum   = xDocNum;
        
   END WHILE;
   
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraDocItem;
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraDocTopo;
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraDocTopo2;
   
   IF excecao = 1 THEN
      ROLLBACK;
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      COMMIT;
      SET RESULTADO = 0;
      SET MENSAGEM = "Atualização realizada com sucesso";
   END IF;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_AtualizarStatusDocEntry.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_AtualizarStatusDocEntry`$$

CREATE PROCEDURE `PROC_INTEGRA_AtualizarStatusDocEntry`(
	IN oCodUsuario				VARCHAR(10),
	IN oDocEntry      INT,
	IN oDocTipo       VARCHAR(10),
	IN oDocNum        INT,
	IN oNewStatus     INT,
	
	# Parametros de Retorno
	OUT RESULTADO     VARCHAR(5),
	OUT MENSAGEM      VARCHAR(500)
)
BLOCO1:BEGIN
	/*****************************************************************************************/
	#@Author : David Ruy
    #@Reviser <20230324> David Ruy : Ajuste para não retroceder status de 3 para 1 => IF(StatusDoc=3 AND oNewStatus = 1, 3, oNewStatus)
    #@Reviser <20230325> David Ruy : TD-S Grava StatusEnum = 0 (para gerar o Recebimento)
	#@Reviser David Ruy <2024-05-15> : Checar Status ANTES de atualizar para não chamar 
	#    PROC_INTEGRA_AtualizarStatusSLIN quando o documento não tiver sido integrado no WMS, 
	/*****************************************************************************************/

   
   DECLARE xIncAlt   VARCHAR(01)	DEFAULT 'I';
   DECLARE excecao   INT DEFAULT 0;
   DECLARE xStatusDoc VARCHAR(10);	
   
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   START TRANSACTION;
   
   SET RESULTADO = "1";
   SET MENSAGEM = "Atualização realizada com sucesso";
   IF NOT EXISTS (SELECT 1 FROM tbintegraSAP_Doc
			   WHERE DocEntry = oDocEntry
			     AND DocTipo  = oDocTipo
			     AND DocNum   = oDocNum) THEN
        SET xIncAlt = 'X';
   ELSE
        SET xIncAlt = 'A';
   END IF;
	
   IF xIncAlt = 'X' THEN	
      SET RESULTADO = "0";
      SET MENSAGEM  = "DocEntry / DocTipo não localizado - Atualização Impossível";
   ELSE
   
      SELECT StatusDoc INTO xStatusDoc FROM tbintegraSAP_Doc
      WHERE DocEntry = oDocEntry
        AND DocTipo  = oDocTipo
        AND DocNum   = oDocNum;
       
   
      UPDATE tbintegraSAP_Doc
      SET  StatusAnt = StatusDoc
          ,StatusDoc = IF(StatusDoc=3 AND oNewStatus = 1, 3, oNewStatus)
          ,usu_alt   = oCodUsuario
          ,dthr_alt  = NOW()
      WHERE DocEntry = oDocEntry
        AND DocTipo  = oDocTipo
        AND DocNum   = oDocNum;
        
      IF oDocTipo = 'TD-S' AND oNewStatus = 6 THEN
         # No primeiro envio Seta "0" para gerar a Devolução, no segundo Seta "1" = Gerado
         UPDATE tbintegraSAP_Doc
         SET  StatusEnum = IF(StatusEnum IS NULL, 0, 1)
         WHERE DocEntry = oDocEntry
           AND DocTipo  = oDocTipo
           AND DocNum   = oDocNum;
       END IF;
      
      IF ROW_COUNT() > 0 AND (xStatusDoc > 1) THEN  
         CALL PROC_INTEGRA_AtualizarStatusSLIN(oCodUsuario, oDocEntry, oDocTipo, oDocNum, oNewStatus, RESULTADO, MENSAGEM);
         
         IF RESULTADO = 0 THEN 
            IF EXISTS (SELECT 1 FROM tbintegraSAP_Doc
                       WHERE DocEntry = oDocEntry
                         AND DocTipo  = oDocTipo
                         AND DocNum   = oDocNum
                         AND num_solic IS NOT NULL) THEN       
               SET excecao = 1;
            ELSE
               SET excecao = 0;
               SET MENSAGEM = "Atualização realizada com sucesso";
            END IF;            
         END IF;
      END IF;
   END IF;
    
   IF excecao = 1 THEN
      ROLLBACK;
      IF RESULTADO = 1 THEN
         -- Ero da propria rotina, caso contrário, retorna erro da rotina PROC_INTEGRA_AtualizarStatusSLIN
         SET MENSAGEM = "Erro SQL (PROC_INTEGRA_AtualizarStatusDocEntry) - Verifique com o Administrador";
      END IF;
      SET RESULTADO = "0";
   ELSE
      COMMIT;
   END IF;
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_AtualizarStatusSLIN.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_AtualizarStatusSLIN`$$

CREATE PROCEDURE `PROC_INTEGRA_AtualizarStatusSLIN`(
	IN oCodUsuario				      VARCHAR(10),
	IN oDocEntry            INT,
	IN oDocTipo             VARCHAR(100),
	IN oDocNum              VARCHAR(30),
	IN oNewStatus           INT,
	
	# Parametros de Retorno
	OUT RESULTADO           VARCHAR(5),
	OUT MENSAGEM            VARCHAR(500)
)
BLOCO1:BEGIN
   DECLARE xIncAlt    VARCHAR(01)	DEFAULT 'I';
   DECLARE xCodEmp    VARCHAR(03);
   DECLARE xCodFil    VARCHAR(03);
   DECLARE xAnoSolic  VARCHAR(04);
   DECLARE xNumSolic  VARCHAR(10);
   DECLARE XNumAgrup  VARCHAR(10);
   DECLARE xStatusDoc VARCHAR(10);
   DECLARE xflg_obriga_checkout_retornoPV TINYINT;
   DECLARE xcampo_qtde_volumes TINYINT;
   
				
   DECLARE excecao INT DEFAULT 0;
   #Nesta procedure não tem transaction porque é chamada da PROC_INTEGRA_AtualizarStatusDocEntry
   #que controla a transação
   
   #@Reviser David Ruy <2021-07-12>
   #Utilização do agrupamento para atualizar dthr_retorno_integracao (PV)
   #Ajuste quando oNewStatus = 0, limpa o campo de dthr_retorno_integração (PV)
   #@Reviser David Ruy <2021-08-30> Ajuste TD-<E>/<S> para atualizar
   #@Reviser David Ruy <2023-04-24> PA000
   #@Reviser David Ruy <2023-05-02> Atualização tbintegraSAP_ContagemTopo
   #@Reviser David Ruy <2023-06-13> Atualização SAIDA_AVULSA
   #@Reviser David Ruy <2023-07-19> Desconsidera GSM´s que flg_conferencia_volume_check_tp = 1 e que não concluiu o checkout
   #@Reviser David Ruy <2024-07-16> Alteração variável oDocNum Varchar(30)   
   #@Reviser David Ruy <2025/05/21> Ajuste xcampo_qtde_volumes (tbintegraSAP_Parametros.flg_campo_volumes => 0=CHECKOUT / 1=EMB_VOL / 2=STRING_CHECKOUT)
   #@Reviser David Ruy <2025/11/25> Ajuste condição oDocTipo like 'PA%'
   
   SELECT flg_obriga_checkout_retornoPV, flg_campo_volumes
   INTO xflg_obriga_checkout_retornoPV, xcampo_qtde_volumes
   FROM tbintegraSAP_parametros
   LIMIT 1;
   
   
   
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   SET RESULTADO = "1";
   SET MENSAGEM = "Atualização realizada - Status não relevante";
   
   IF oDocTipo = 'MOVTO' THEN
      SET MENSAGEM = "Atualização realizada com sucesso";
      UPDATE of_logistica.tbwms_manut_lote tbwmsManut
      SET tbwmsManut.dthr_retorno_integracao = NOW()
      WHERE tbwmsManut.id_manutencao = oDocEntry;
      
   ELSEIF SUBSTRING(oDocTipo,1,12) = 'SAIDA_AVULSA' THEN
  
      SET MENSAGEM = "Atualização realizada com sucesso";
      SET xCodEmp = SUBSTRING(oDocTipo, 13,03);
      SET xCodFil = SUBSTRING(oDocTipo, 16,03);
      SET xAnoSolic = SUBSTRING(oDocTipo, 19,04);
      SET xNumSolic = SUBSTRING(oDocTipo, 23,10);
      
      UPDATE of_logistica.tbsolic_saidas tbSaidas
      SET tbSaidas.dthr_retorno_integracao = NOW()
      WHERE tbSaidas.cod_emp   = xCodEmp
        AND tbSaidas.cod_fil   = xCodFil
        AND tbSaidas.ano_solic = xAnoSolic
        AND tbSaidas.num_solic =xNumSolic;
      
   ELSEIF SUBSTRING(oDocTipo,01,08) = 'CONTAGEM' THEN
   
      SET MENSAGEM = "Atualização realizada com sucesso";
      
      IF oNewStatus = 0 THEN
         #oDocTipo = CONTAGEM + E/S + cod_emp + cod_fil + ano_solic + num_solic
         
         SET xCodEmp = SUBSTRING(oDocTipo, 10,03);
         SET xCodFil = SUBSTRING(oDocTipo, 13,03);
         SET xAnoSolic = SUBSTRING(oDocTipo, 16,04);
         SET xNumSolic = SUBSTRING(oDocTipo, 20,10);
         
         #Criar Contagem
         UPDATE tbintegraSAP_ContagemTopo tbCont
         SET tbCont.Id = oDocEntry
         WHERE tbCont.cod_emp   = xCodEmp
           AND tbCont.cod_fil   = xCodFil
           AND tbCont.ano_solic = xAnoSolic
           AND tbCont.num_solic = xnumSolic;
      ELSE 
         #Confirmar Contagem
         UPDATE tbintegraSAP_ContagemTopo tbCont
         SET tbCont.dthr_retorno_integracao = NOW()
         WHERE tbCont.Id = oDocEntry;
           
      END IF;
      
      
      /*SET xCodEmp = SUBSTRING(oDocTipo, 10,03);
      SET xCodFil = SUBSTRING(oDocTipo, 13,03);
      SET xAnoSolic = SUBSTRING(oDocTipo, 16,04);
      SET xNumSolic = SUBSTRING(oDocTipo, 20,10);
      #Criar e Confirmar Contagem
      UPDATE tbintegraSAP_ContagemTopo tbCont
      SET tbCont.Id = oDocEntry,
          tbCont.dthr_retorno_integracao = NOW()
      WHERE tbCont.cod_emp   = xCodEmp
        AND tbCont.cod_fil   = xCodFil
        AND tbCont.ano_solic = xAnoSolic
        AND tbCont.num_solic = xnumSolic;          
      */
      
        
   #ELSEIF oDocTipo IN ('PV', 'OP') AND oNewStatus = 6 THEN
   ELSEIF oDocTipo IN ('PV', 'OP', 'TD-S') THEN 
   
      SELECT tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic, tbSaidas.num_agrup_geral, 
             tbintegraSAP_Doc.StatusDoc
      INTO xCodEmp, xCodFil, xAnoSolic, xNumSolic, XNumAgrup, xStatusDoc
      FROM of_logistica.tbsolic_saidas tbSaidas
      INNER JOIN tbintegraSAP_Doc ON 
            tbintegraSAP_Doc.cod_emp     = tbSaidas.cod_emp
        AND tbintegraSAP_Doc.cod_fil     = tbSaidas.cod_fil
        AND tbintegraSAP_Doc.ano_solic   = tbSaidas.ano_solic
        AND tbintegraSAP_Doc.num_solic   = tbSaidas.num_solic
        AND tbintegraSAP_Doc.TipoDocSLIN = "S"
      WHERE DocEntry = oDocEntry
        AND DocTipo  = oDocTipo
        AND DocNum   = oDocNum;
        

      IF XNumAgrup IS NOT NULL THEN

         UPDATE of_logistica.tbsolic_saidas tbSaidas
         SET tbSaidas.dthr_retorno_integracao = IF(xStatusDoc >= 6, NOW(),NULL)  #IF(oNewStatus=0,NULL,NOW())
         WHERE tbSaidas.num_agrup_geral = XNumAgrup
           AND tbSaidas.status_processo >= 8
           AND tbSaidas.dthr_cancelamento IS NULL
           AND (tbSaidas.dthr_bloqueio_ini IS NULL OR (tbSaidas.dthr_bloqueio_ini IS NOT NULL AND tbSaidas.dthr_bloqueio_fin IS NOT NULL))
           #AND IF(xflg_obriga_checkout_retornoPV = 1, dthr_final_picking IS NOT NULL, TRUE);
           AND IF(xflg_obriga_checkout_retornoPV = 1, dthr_final_picking IS NOT NULL, 
                                                      IF(xcampo_qtde_volumes IN (2,3), IFNULL(tbSaidas.qtde_volume_checkout,0) > 0, TRUE));

      ELSE

         UPDATE of_logistica.tbsolic_saidas tbSaidas
         SET tbSaidas.dthr_retorno_integracao = IF(xStatusDoc >= 6, NOW(),NULL) #IF(oNewStatus=0,NULL,NOW())
         WHERE cod_emp   = xCodEmp
           AND cod_fil   = xCodFil
           AND ano_solic = xAnoSolic
           AND num_solic = xNumSolic;

      END IF;
      
      #@Reviser David Ruy <2020-08-28>
      #Atualiza as quantidades da GSM finalizada no TMS, envia FRETE = Null para não atualizar as informações
      IF oDocTipo IN ('PV','TD-S') AND xStatusDoc = 6 THEN
         CALL PROC_INTEGRA_TMS_GERAR_ENTREGAS(xCodEmp, xCodFil, xAnoSolic, xnumSolic, NULL, NULL, NULL, @R, @M);
      END IF;
      
      SET MENSAGEM = "Atualização (Saída) realizada com sucesso";
  
   ELSEIF (oDocTipo IN ('NE', 'E-RM', 'E-NE', 'DV', 'TD-E') OR oDocTipo LIKE 'PA%') AND oNewStatus = 6 THEN
      SELECT tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic,
             tbintegraSAP_Doc.StatusDoc
      INTO xCodEmp, xCodFil, xAnoSolic, xNumSolic, xStatusDoc
      FROM of_logistica.tbsolic_entradas tbEntradas
      INNER JOIN tbintegraSAP_Doc ON 
            tbintegraSAP_Doc.cod_emp     = tbEntradas.cod_emp
        AND tbintegraSAP_Doc.cod_fil     = tbEntradas.cod_fil
        AND tbintegraSAP_Doc.ano_solic   = tbEntradas.ano_solic
        AND tbintegraSAP_Doc.num_solic   = tbEntradas.num_solic
        AND tbintegraSAP_Doc.TipoDocSLIN = "E"
      WHERE DocEntry = oDocEntry
        AND DocTipo  = oDocTipo
        AND DocNum   = oDocNum;
        
      UPDATE of_logistica.tbsolic_entradas tbEntradas
      SET tbEntradas.dthr_retorno_integracao = IF(xStatusDoc >= 6, NOW(),NULL) #NOW()
      WHERE cod_emp   = xCodEmp
        AND cod_fil   = xCodFil
        AND ano_solic = xAnoSolic
        AND num_solic = xNumSolic;
        
      SET MENSAGEM = "Atualização (Entrada) realizada com sucesso";
      
   END IF;
   
   IF excecao = 1 THEN
      SET RESULTADO = "0";
      SET MENSAGEM = "Erro SQL (PROC_INTEGRA_AtualizarStatusSLIN) - Verifique com o Administrador";
   END IF;
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_AtualizarStatusTMS.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_AtualizarStatusTMS`$$
                  
CREATE PROCEDURE `PROC_INTEGRA_AtualizarStatusTMS`(
   IN oDocEntry      INT
  ,IN oDocTipo       VARCHAR(10)
  ,IN oDocNum        VARCHAR(10)
  ,IN oRefViagem     VARCHAR(100)
  ,IN oStatusEntrega VARCHAR(200)
  ,IN oStatusArmazem VARCHAR(200)
  ,IN oStatusCliente VARCHAR(200)
)
BLOCO1:BEGIN
   /*******************************************************************************************
   #@Author David Ruy <2021-12-06>
   #@Reviser David Ruy <2025-07-21> Parametro oStatusCliente
   ********************************************************************************************/
   
   DECLARE excecao 	          INT DEFAULT 0;
   DECLARE RESULTADO          INT DEFAULT 1;
   DECLARE MENSAGEM           VARCHAR(500);
   DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   
   UPDATE tbintegraSAP_Doc
   SET RefViagem     = oRefViagem,
       StatusEntrega = oStatusEntrega,
       StatusArmazem = oStatusArmazem,
       StatusAux_Cliente = oStatusCliente
   WHERE DocEntry = oDocEntry
     AND DocTipo  = oDocTipo
     AND DocNum   = oDocNum;   
    
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
   ELSE    
      SET RESULTADO = 1;
      SET MENSAGEM  = 'Processo Realizado com sucesso!';
   END IF;
   SELECT RESULTADO, MENSAGEM;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_AtualizarTMS_NFeVendas.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_AtualizarTMS_NFeVendas`$$

CREATE PROCEDURE `PROC_INTEGRA_AtualizarTMS_NFeVendas`(
   IN oDocEntry      INT
  ,IN oDocTipo       VARCHAR(10)
  ,IN oDocNum        VARCHAR(10)
  ,IN oChaveIntegra  VARCHAR(50)
  ,IN oChaveNFE      VARCHAR(50)
  ,IN oValorNFE      VARCHAR(50)
  ,OUT RESULTADO     INT
  ,OUT MENSAGEM      VARCHAR(100)
)
BLOCO1:BEGIN
   /*******************************************************************************************
   #@Author David Ruy <2021-12-06>
   #@Reviser David Ruy <2024-12-26> #Pega Id_NF para poder atualizar tbprog_entregas
   #@Reviser David Ruy <2026-05-21> #Implementada rotina de Transação e controle de exceção
   ********************************************************************************************/
   DECLARE xIdNF              INT;
   DECLARE excecao 	          INT DEFAULT 0;
   DECLARE xNumNFE             VARCHAR(10);
   DECLARE xSerieNFE           VARCHAR(03);
   DECLARE xValorNFE           DECIMAL(18,6) DEFAULT 0;
   #DECLARE RESULTADO          INT DEFAULT 1;
   #DECLARE MENSAGEM           VARCHAR(500);
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
      GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
      ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM  = fnMensagemExcecao(MENSAGEM);
   END;

   START TRANSACTION;   
   
   
   
   IF IFNULL(oValorNFE,'') <> '' THEN
      SET xValorNFE = CAST(oValorNFE AS DECIMAL(18,6));
   END IF;
   
   IF oChaveNFE = 'IntegraSAP - Chave não localizada' THEN
      SET oChaveNFE = NULL;
      SET xNumNFE = NULL;
   ELSE
      #SET xSerieNFE = SUBSTRING(oChaveNFE, 22, 03); SET xSerieNFE = TRIM(LEADING '0' FROM xSerieNFE);
      SET xNumNFE = SUBSTRING(oChaveNFE, 26, 09); SET xNumNFE = TRIM(LEADING '0' FROM xNumNFE);
   END IF;
   
   IF (oChaveIntegra = "") THEN
      #Pega Id_NF para poder atualizar tbprog_entregas
      SELECT id_nf INTO xIdNF 
      FROM of_logistica.tbnf_clientes
      WHERE chave_nfe = oChaveNFE;  
   
      #Limpa NF´ canceladas
      UPDATE of_logistica.tbnf_clientes
      SET chave_nfe = NULL
      WHERE chave_nfe = oChaveNFE;
      
      UPDATE of_logistica.tbprog_entregas
      SET num_nf_aux = NULL
      #WHERE num_nf_aux = xNumNFE;
      WHERE id_nf = xIdNF;
   ELSE   
      #Atualiza NF / DANFE
      UPDATE of_logistica.tbnf_clientes
      SET chave_nfe = oChaveNFE,
          #vlr_tot_nf = IF(xValorNFE < vlr_tot_nf , vlr_tot_nf, xValorNFE)
          vlr_tot_nf = IFNULL(xValorNFE, vlr_tot_nf)
      WHERE chave_integracao = oChaveIntegra;
      
      UPDATE of_logistica.tbprog_entregas
      SET num_nf_aux = xNumNFE
      WHERE chave_integracao = oChaveIntegra;
   END IF;
   
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      SELECT RESULTADO, MENSAGEM;
      ROLLBACK;
   ELSE    
      SET RESULTADO = 1;
      SET MENSAGEM  = 'Processo Realizado com sucesso!';
       COMMIT;
   END IF;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_Atualizar_SubstituirPV.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_Atualizar_SubstituirPV`$$
                  
CREATE PROCEDURE `PROC_INTEGRA_Atualizar_SubstituirPV`(
   IN oCodUsuario				VARCHAR(10),
   IN oDocEntry_Antigo		VARCHAR(20),
   IN oDocEntry_Novo			VARCHAR(20),
   OUT RESULTADO           INT,
   OUT MENSAGEM            VARCHAR(200)
)
BLOCO1:BEGIN
   /*******************************************************************************************
   #@Author David Ruy <2022-01-31>
   #@Tratar a substituição de PV vindo do commerce (U_RSD_RplOrder)
   ********************************************************************************************/
   
   DECLARE xCodEmpWMS			   VARCHAR(03)	DEFAULT '001';
   DECLARE xCodFilWMS			   VARCHAR(03) DEFAULT '001';
   DECLARE xNumSolic 			   VARCHAR(10);
   DECLARE xAnoSolic 			   VARCHAR(04);
   DECLARE xStatusAnt            INT;
   DECLARE xStatusDoc            INT;
   DECLARE xStatusSLIN           INT;
   DECLARE xTipoDocSLIN          VARCHAR(10);
   DECLARE xcod_emp              VARCHAR(03);
   DECLARE xcod_fil              VARCHAR(03);
   DECLARE xano_solic            VARCHAR(04);
   DECLARE xnum_solic            VARCHAR(10);
   DECLARE xChaveNovo            VARCHAR(30);
   DECLARE xDocNumNovo           VARCHAR(30);
   DECLARE xChaveAntigo          VARCHAR(30);
   DECLARE xDocNumAntigo         VARCHAR(30);
   DECLARE xid_nf                INT;
   DECLARE xano_entrega          VARCHAR(04);
   DECLARE xnum_entrega          VARCHAR(10);
   DECLARE excecao               INT DEFAULT 0;
   
   
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       ROLLBACK;
   END;
      
   START TRANSACTION;
   
   SET RESULTADO = 1;
   SET MENSAGEM  = "Substituição realizada com sucesso";
   
   #Busca Chave PV Substituto (Novo)
   SELECT chave_integracao, DocNum INTO xChaveNovo, xDocNumNovo
   FROM tbintegraSAP_Doc
   WHERE tbintegraSAP_Doc.DocEntry = oDocEntry_Novo
     AND tbintegraSAP_Doc.DocTipo  = 'PV';
   
   
   #Busca Dados PV Substituído (Antigo)
   SELECT chave_integracao, DocNum, StatusAnt, StatusDoc, StatusSLIN, TipoDocSLIN, cod_emp, cod_fil, ano_solic, num_solic
     INTO xChaveAntigo, xDocNumAntigo, xStatusAnt, xStatusDoc, xStatusSLIN, xTipoDocSLIN, xcod_emp, xcod_fil, xano_solic, xnum_solic
   FROM tbintegraSAP_Doc 
   WHERE tbintegraSAP_Doc.DocEntry = oDocEntry_Antigo
     AND tbintegraSAP_Doc.DocTipo  = 'PV';
     
     
   #Busca Dados TMS : tbprog_entregas / tbnf_clientes
   SELECT id_nf, cod_emp, cod_fil, ano_entrega, num_entrega 
   INTO xid_nf, xcod_emp, xcod_fil, xano_entrega, xnum_entrega 
   FROM of_logistica.tbprog_entregas
   WHERE chave_integracao = xchaveAntigo;
   
   
   
   #Atualiza dados PV Substituído (Antigo)
   UPDATE tbintegraSAP_Doc 
   SET StatusAnt     = xStatusDoc
      ,StatusDoc     = 9
      ,TipoDocSLIN   = NULL
      ,cod_emp       = NULL
      ,cod_fil       = NULL
      ,ano_solic     = NULL
      ,num_solic     = NULL
      ,dthr_cancel   = NOW()
      ,observacoes   = CONCAT("Susbstituição por ",xChaveNovo," => ",observacoes)
   WHERE tbintegraSAP_Doc.DocEntry  = oDocEntry_Antigo
     AND tbintegraSAP_Doc.DocTipo   = 'PV'
     AND tbintegraSAP_Doc.DocNum    = xDocNumAntigo;

   
   
   #Atualiza Itens PV Substituído (Antigo)
   UPDATE tbintegraSAP_DocItem
   SET Observacoes = CONCAT("Susbstituição por ",xChaveNovo," => ",Observacoes)
       ,StatusAnt = StatusItem
       ,StatusItem = 9
       #,cod_emp = null
       #,cod_fil = null
       #,ano_solic = null
       #,num_solic = null
       #,num_item = null
   WHERE tbintegraSAP_DocItem.DocEntry  = oDocEntry_Antigo
     AND tbintegraSAP_DocItem.DocTipo   = 'PV'
     AND tbintegraSAP_DocItem.DocNum    = xDocNumAntigo;
    
    
   #Atualiza dados PV Substituto (Novo)
   UPDATE tbintegraSAP_Doc
   SET StatusAnt     = xStatusAnt
      #,StatusDoc     = 20           #Status 20 indica que precisará passar por processo de alteração
      ,StatusDoc     = xStatusDoc
      ,StatusSLIN    = xStatusSLIN
      ,TipoDocSLIN   = xTipoDocSLIN
      ,cod_emp       = xcod_emp
      ,cod_fil       = xcod_fil
      ,ano_solic     = xano_solic
      ,num_solic     = xnum_solic
   WHERE tbintegraSAP_Doc.DocEntry  = oDocEntry_Novo
     AND tbintegraSAP_Doc.DocTipo   = 'PV'
     AND tbintegraSAP_Doc.DocNum    = xDocNumNovo;
   

   #Atualiza Itens PV Substituto (Novo)
   UPDATE tbintegraSAP_DocItem tbItemNovo
   INNER JOIN tbintegraSAP_DocItem tbItemAntigo ON
           tbItemAntigo.DocTipo  = tbItemNovo.DocTipo
       AND tbItemAntigo.DocNum   = tbItemNovo.DocNum
       AND tbItemAntigo.DocEntry = tbItemNovo.DocEntry
       AND tbItemAntigo.LineNum  = tbItemNovo.LineNum
   SET  tbItemNovo.cod_emp   = tbItemAntigo.cod_emp   
       ,tbItemNovo.cod_fil   = tbItemAntigo.cod_fil   
       ,tbItemNovo.ano_solic = tbItemAntigo.ano_solic 
       ,tbItemNovo.num_solic = tbItemAntigo.num_solic 
       ,tbItemNovo.num_item  = tbItemAntigo.num_item  
   WHERE tbItemNovo.DocEntry  = oDocEntry_Novo
     AND tbItemNovo.DocTipo   = 'PV'
     AND tbItemNovo.DocNum    = xDocNumNovo;
    
    
   #Atualiza tbsolic_saidas (GSM)
   UPDATE of_logistica.tbsolic_saidas
   SET num_nf = CONCAT('PV',xDocNumNovo)
      ,chave_integracao = xChaveNovo
      ,observ_solic = CONCAT("Susbstituição de ",xChaveAntigo," => ",observ_solic)
   WHERE cod_emp   = xcod_emp
     AND cod_fil   = xcod_fil
     AND ano_solic = xano_solic
     AND num_solic = xnum_solic;
     
     
   #Atualiza tbsolic_saidas_item (Itens da GSM)
   UPDATE of_logistica.tbsolic_saidas_item
   SET num_ped_aux = CONCAT('PV',xDocNumNovo)
      ,num_ped_cli = CONCAT('PV',xDocNumNovo)
   WHERE cod_emp   = xcod_emp
     AND cod_fil   = xcod_fil
     AND ano_solic = xano_solic
     AND num_solic = xnum_solic;
     
     
   #Atualiza TMS : tbprog_entregas
   UPDATE of_logistica.tbprog_entregas
   SET num_ped_aux = CONCAT('PV',xDocNumNovo)
      ,num_nf_cli  = CONCAT('PV',xDocNumNovo)
      ,chave_integracao = xchaveNovo
      ,observ_entre = CONCAT("Susbstituição de ",xChaveAntigo," => ",observ_entre)
   WHERE chave_integracao = xchaveAntigo;
   
   
   #Atualiza TMS : tbnf_clientes (Topo da NF)
   UPDATE of_logistica.tbnf_clientes
   SET num_nf = CONCAT('PV',xDocNumNovo)
      ,chave_integracao = xChaveNovo
   WHERE chave_integracao = xchaveAntigo;
   
   
   #Atualiza TMS : tbnf_ite_clientes (Itens da NF)
   UPDATE of_logistica.tbnf_ite_clientes
   SET num_nf   = CONCAT('PV',xDocNumNovo)
   WHERE id_nf  = xid_nf;
   
   
   #Atualiza Integração de que o Documento foi cancelado
   UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV
   SET tbUpdCancPV.STATUS = 9
   WHERE tbUpdCancPV.DocumentId     = oDocEntry_Antigo
     AND tbUpdCancPV.DocumentType   = 'PV'
     AND tbUpdCancPV.DocumentNumber = xDocNumAntigo
     AND tbUpdCancPV.STATUS = 0
     AND tbUpdCancPV.TipoUpdCanc = 'C';
   
   
   IF excecao = 0 THEN
      COMMIT;
   ELSE
      SET RESULTADO = 0;
      SET MENSAGEM  = "Erro Substituição NÃO realizada";
      ROLLBACK;
   END IF;
    
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_BloquearStatusUAs.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_BloquearStatusUAs`$$

CREATE PROCEDURE `PROC_INTEGRA_BloquearStatusUAs`(
   oCodUsuario    VARCHAR(30),
   oDocTipo            VARCHAR(30),
   oDocEntry           VARCHAR(30),
   oDocNum             VARCHAR(30),
   # Parametros de Retorno
   OUT RESULTADO              INT,
   OUT MENSAGEM               VARCHAR(500)
)
BLOCO1:BEGIN
  /************************************************************************/
  # @Created David Ruy <2026/03/26>
  # Esta procedure atualiza as UA´s de uma GEM (Ordem de Produção) com status para bloquear conforme necessário
  # @Reviser David Ruy <2026-04-17> Atualização de PROC_WMS_ARMAZEM_ALTERAR_STATUS_UA para gerar log da alteração do Status
  /************************************************************************/
   DECLARE excecao 	       INT(6) DEFAULT 0;
   DECLARE _RESULTADO      INT DEFAULT 0;
   DECLARE _MENSAGEM       VARCHAR(500);
   DECLARE xCodEmp         VARCHAR(03);
   DECLARE xCodFil         VARCHAR(03);
   DECLARE xAnoSolic       VARCHAR(04);
   DECLARE xNumSolic       VARCHAR(10);
   DECLARE xNumItem        VARCHAR(06);
   DECLARE xItemCode       VARCHAR(30);
   DECLARE xnum_lote       VARCHAR(30);
   DECLARE xsequencia_lote INT;
   
   DECLARE xDocTipo         VARCHAR(10);
   DECLARE xDocEntry        VARCHAR(30);
   DECLARE xDocNum          VARCHAR(30);
   DECLARE xChaveIntegracao VARCHAR(100);
   DECLARE xdthr_confirm    VARCHAR(20);
   DECLARE xCodigoStatus    VARCHAR(10);
   
   #Verificar se tem transação nas procedures
   #Se tiver, lascou
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       IF xCodEmp IS NOT NULL THEN
          SET MENSAGEM  = of_logistica.fnMensagemExcecao(
             CONCAT('ERRO Atualização UA´s - GEM : ',CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',
             CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao," ",MENSAGEM) );
       ELSE
          SET MENSAGEM  = of_logistica.fnMensagemExcecao(
             CONCAT('ERRO Atualização UA´s : ',MENSAGEM) );
       END IF;
       SELECT MENSAGEM;
       ROLLBACK;
   END;  
   
   
   #Busca o Status "Próprio para Produção Automática"
   #Isso serve para deixar "bloqueadas" as UA´s, até que o pedido com os lotes vinculados seja integrado
   SELECT cod_status INTO xCodigoStatus 
   FROM tbintegraSAP_DeParaStatus_Armazem
   WHERE descr_armazem = 'Produção automatica';
   
   
   #Pega os dados da GEM / GSM com base no documento referenciado nos parametros
   SELECT cod_emp, cod_fil, ano_solic, num_solic, chave_integracao
   INTO xCodEmp, xCodFil, xAnoSolic, xNumSolic, xChaveIntegracao
   FROM tbintegraSAP_Doc
   WHERE DocTipo = oDocTipo
     AND DocEntry = oDocEntry
     AND DocNum   = oDocNum;
     
     
   IF xCodEmp IS NULL THEN 
      SET RESULTADO = 0;
      SET MENSAGEM  = "Não existem documentos no SLIN vinculados a esse processo - operação não realizada";
      LEAVE BLOCO1;
   END IF;
   

   SELECT dthr_confirm INTO xdthr_confirm
   FROM of_logistica.tbsolic_entradas
   WHERE chave_integracao = xChaveIntegracao;
   
   
   IF xdthr_confirm IS NULL THEN
      SET RESULTADO = 0;
      SET MENSAGEM  = "GEM não confirmada, operação não pode ser realizada";
      LEAVE BLOCO1;   
   END IF;
   
   #Gera tabela com as UA´s a bloquear
   DROP TEMPORARY TABLE IF EXISTS tbTMP_AtuStatus;
   CREATE TEMPORARY TABLE tbTMP_AtuStatus
      SELECT num_lote, sequencia_lote, 0 AS flag FROM of_logistica.tbwms_estoque
      WHERE cod_emp   = xCodEmp
        AND cod_fil   = xCodFil 
        AND ano_solic = xAnoSolic
        AND num_solic = xNumSolic;
        
   #Bloqueia as UA´s (Status "Produção Automática")
   WHILE EXISTS (SELECT 1 FROM tbTMP_AtuStatus WHERE flag = 0) DO
      SELECT num_lote, sequencia_lote INTO xnum_lote, xsequencia_lote
      FROM tbTMP_AtuStatus WHERE flag = 0 LIMIT 1;
      
      CALL of_logistica.PROC_WMS_ARMAZEM_ALTERAR_STATUS_UA(xCodEmp, xCodFil, xnum_lote, xsequencia_lote,
                 xCodigoStatus, CONCAT('Integração - Bloqueio UA Reservada OP',oDocNum), '999999', NULL);     
      
      UPDATE tbTMP_AtuStatus 
      SET flag = 1
      WHERE num_lote = xnum_lote AND sequencia_lote = xsequencia_lote;
   
   END WHILE;
   DROP TEMPORARY TABLE IF EXISTS tbTMP_AtuStatus;
   
   
   IF excecao = 0 THEN
      #COMMIT;
      SET RESULTADO = 1;
      IF MENSAGEM = "" THEN
         SET MENSAGEM = CONCAT('Atualização Status de UA´s Concluída com sucesso - GEM : ',CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao);
      ELSE
         SET MENSAGEM = CONCAT(MENSAGEM," | ",CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao);
      END IF;
   ELSE
      #ROLLBACK;
      
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT('ERRO Atualização Status de UA´s - GEM : ',CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao);
      
      #Verificar Log
      #CALL PROC_INTEGRA_EnviarLog('999999',
      #       IF(oChavePedido IN ("PV","OP","TD-S","NS"), 'PROC_INTEGRA_BloquearStatusUAs', 'PROC_INTEGRA_GerarGEMItem'),
      #         CONCAT('NÃO Inserido/Atualizado ',oChavePedido,oDocEntry,'-',oNumPedido,' | ', xRefGuia, '| Prd:', xItemCode), "200", @M, @R, @M);      
   END IF;
   
      
      
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_CAD_ClienteFornecedor.sql*/

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

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_CAD_Destinatario.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_CAD_Destinatario`$$

CREATE PROCEDURE `PROC_INTEGRA_CAD_Destinatario`( IN oCodUsuario				     VARCHAR(10)
, IN oCNPJCliente        VARCHAR(14)
,	IN oCNPJCPF					       VARCHAR(14)
,	IN oTipoPessoa				     VARCHAR(01)
,	IN oRazSocial				      VARCHAR(100)
,	IN oNomeFantasia		     VARCHAR(100)
,	IN oInscrEstadual	     VARCHAR(20)
,	IN oIndicadorIE			     VARCHAR(1)
,	IN oEndereco				       VARCHAR(100)
,	IN oNumEnde					       VARCHAR(30)
,	IN oComplEnde			       VARCHAR(200)
,	IN oBairroEnde		       VARCHAR(50)
,	IN oCidadeEnde		       VARCHAR(50)
,	IN oUFEnde					        VARCHAR(02)
,	IN oCepEnde					       VARCHAR(10)
,	IN oContato01			       VARCHAR(20)
,	IN oFone01 					       VARCHAR(20)
,	IN oEmail01 				       VARCHAR(40)
,	IN oStatusAtivo	       VARCHAR(01)
, IN ohora1_entrega      VARCHAR(20)
, IN ohora2_entrega      VARCHAR(20)
, IN ohora3_entrega      VARCHAR(20)
, IN ohora4_entrega      VARCHAR(20)
,	OUT RESULTADO     VARCHAR(5)
,	OUT MENSAGEM      VARCHAR(500)
)
BLOCO1:BEGIN
  # PROCEDURE INTEGRAÇÃO PARA CADASTRO DE DESTINATÁRIO
  # @author David Ruy
  # @company Overflash
  
  /**
   * ------------------------ INFORMAÇÕES ADICIONAIS -----------------------
   *
   *
   * ---------------------- FIM INFORMAÇÕES ADICIONAIS ---------------------
   */
  
  /****************************************************************/
  /****************DECLARAR VARIÁVEIS AUXILIARES
  /****************************************************************/
  
  DECLARE xIncAlt   VARCHAR(01)	DEFAULT 'I';
  DECLARE xemp_rota VARCHAR(03);
  DECLARE xfil_rota VARCHAR(03);
  DECLARE xcod_rota VARCHAR(10);
  
  /****************************************************************/
  /****************CONTROLE DE EXCEÇÃO DE SQL
  /****************************************************************/
  
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    
    GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
  
    ROLLBACK;
    SET RESULTADO = 'FALSE';
    SET MENSAGEM  = MENSAGEM;
  END;
   SET oCepEnde = fnSoNumeros(oCepEnde,"");
   SET ohora1_entrega = SUBSTRING(ohora1_entrega,1,5);
   SET ohora2_entrega = SUBSTRING(ohora2_entrega,1,5);
   SET ohora3_entrega = SUBSTRING(ohora3_entrega,1,5);
   SET ohora4_entrega = SUBSTRING(ohora4_entrega,1,5);
   
  /****************************************************************/
  /****************VERIFICAR ALTERAÇÃO
  /****************************************************************/
  
  IF EXISTS( SELECT 1 
               FROM of_logistica.tbdestinatarios
              WHERE of_logistica.tbdestinatarios.cnpj_cpf_cliente = oCNPJCliente
                AND of_logistica.tbdestinatarios.cod_integracao   = oCNPJCPF
           ) 
  THEN
   
    SET xIncAlt = 'A';
  
  END IF;
  
  /*******************************************************************
  #Tratar e Validar as variáveis Destinatário
  # Se enviar oStatusAtivo em branco, não realiza validações de todos os campos
  *******************************************************************/
  
  IF IFNULL(oStatusAtivo,'') = '' THEN
     IF TRIM(IFNULL(oCNPJCPF,'')) = '' THEN
         SET MENSAGEM = "CNPJ/CPF Inválido";
     ELSEIF TRIM(IFNULL(oRazSocial,'')) = '' THEN
         SET MENSAGEM = "Razão Social Inválida";
     END IF;
  ELSE
     SET MENSAGEM = '';
     SET oIndicadorIE = TRIM(IFNULL(oIndicadorIE, ''));
     IF TRIM(IFNULL(oCNPJCPF,'')) = '' THEN
         SET MENSAGEM = "CNPJ/CPF Inválido";
     ELSEIF TRIM(IFNULL(oTipoPessoa,'')) NOT IN ('F','J','O') THEN
         SET MENSAGEM = "Tipo Pessoa Inválido";
     ELSEIF TRIM(IFNULL(oRazSocial,'')) = '' THEN
         SET MENSAGEM = "Razão Social Inválida";
     ELSEIF TRIM(IFNULL(oNomeFantasia,'')) = '' THEN
         SET MENSAGEM = "Nome Fantasia Inválida";
     #ELSEIF (oIndicadorIE = "") OR (oIndicadorIE NOT IN ('1','2','9')) THEN
     #    SET MENSAGEM = "Indicador de Inscrição Estadual inválido";
     #ELSEIF oIndicadorIE <> '9' AND (TRIM(IFNULL(oInscrEstadual,'')) = '') THEN
     #    SET MENSAGEM = "Inscrição Estadual Destinatário inválida";
     #ELSEIF TRIM(IFNULL(oEndereco,'')) = '' THEN
     #    SET MENSAGEM = "Endereço Inválido";
     #ELSEIF TRIM(IFNULL(oNumEnde,'')) = '' THEN
     #    SET MENSAGEM = "N° (Endereço) Inválido";
     #ELSEIF TRIM(IFNULL(oBairroEnde,'')) = '' THEN
     #    SET MENSAGEM = "Bairro Inválido";
     #ELSEIF TRIM(IFNULL(oCidadeEnde,'')) = '' THEN
     #    SET MENSAGEM = "Cidade Inválido";
     #ELSEIF TRIM(IFNULL(oUFEnde,'')) = '' THEN
     #    SET MENSAGEM = "UF Inválido";
     #ELSEIF (TRIM(IFNULL(oCepEnde,'')) = '') OR (fnSoNumeros(oCepEnde,"") <> oCepEnde) OR (NOT LENGTH(TRIM(oCepEnde)) = 8) THEN
     #    SET MENSAGEM = "CEP Inválido";
     END IF;
   END IF;
   IF MENSAGEM <> '' THEN
      SET RESULTADO = 'FALSE';
      LEAVE BLOCO1;
   END IF;
   
   
   #Buscar ROTA através do CEP
   SELECT #@oCidadeEnde, @oUFEnde, @oCepEnde, 
          tbrotas.cod_emp, tbrotas.cod_fil, tbrotas.cod_rota 
          #,tbrotas.descr_rota, tbrotas_cep.cep_ini, tbrotas_cep.cep_fin
   INTO xemp_rota, xfil_rota, xcod_rota
   FROM of_logistica.tbrotas
   LEFT JOIN of_logistica.tbrotas_cep ON 
              tbrotas_cep.cod_emp = tbrotas.cod_emp
          AND tbrotas_cep.cod_fil = tbrotas.cod_fil
          AND tbrotas_cep.cod_rota = tbrotas.cod_rota
   WHERE oCepEnde BETWEEN tbrotas_cep.cep_ini AND tbrotas_cep.cep_fin
   LIMIT 1;
   
   #Se não localizou pelo CEP, Buscar ROTA através da cidade
   IF xemp_rota IS NULL THEN
      SELECT #@oCidadeEnde, @oUFEnde, @oCepEnde, 
             tbrotas.cod_emp, tbrotas.cod_fil, tbrotas.cod_rota
             #tbrotas.descr_rota, tbcidades.nome_cidade
      INTO xemp_rota, xfil_rota, xcod_rota          
      FROM of_logistica.tbrotas 
      LEFT JOIN of_logistica.tbrotas_cidade ON
                tbrotas_cidade.cod_emp  = tbrotas.cod_emp
            AND tbrotas_cidade.cod_fil  = tbrotas.cod_fil
            AND tbrotas_cidade.cod_rota = tbrotas.cod_rota
      LEFT JOIN of_logistica.tbcidades ON
                tbcidades.cod_cidade = tbrotas_cidade.cod_cidade
      WHERE tbcidades.nome_cidade = oCidadeEnde
        AND tbcidades.sig_estado  = oUFEnde
      LIMIT 1;
     END IF;
     
     
     #@Reviser David Ruy <2022-03-15>
     SET oTipoPessoa = UPPER(oTipoPessoa);
     SET oRazSocial = UPPER(oRazSocial);
     SET oNomeFantasia = UPPER(oNomeFantasia);
     SET oEndereco = UPPER(oEndereco);
     SET oNumEnde = UPPER(oNumEnde);
     SET oComplEnde = UPPER(oComplEnde);
     SET oBairroEnde = UPPER(oBairroEnde);
     SET oCidadeEnde = UPPER(oCidadeEnde);
     SET oUFEnde = UPPER(oUFEnde);
     SET oCepEnde = UPPER(oCepEnde);
     SET oContato01 = UPPER(oContato01);
     SET oFone01 = UPPER(oFone01);
     SET oEmail01 = UPPER(oEmail01);
     SET oCNPJCPF = UPPER(oCNPJCPF);
     SET oCNPJCliente = UPPER(oCNPJCliente);
     
 
   
  IF xIncAlt = 'I' THEN
  BEGIN 
  
    INSERT INTO of_logistica.tbdestinatarios( cnpj_cpf
                                         , tipo_pessoa
                                         , raz_social
                                         , nome_fantasia
                                         , inscr_estadual
                                         , idIEDest
                                         , endereco
                                         , num_ende
                                         , compl_ende
                                         , bairro
                                         , nome_cidade
                                         , sig_estado
                                         , cep_ende
                                         , contato
                                         , telefone
                                         , email
                                         , cnpj_aux
                                         , cnpj_cpf_cliente
                                         , hora1_entrega
                                         , hora2_entrega
                                         , hora3_entrega
                                         , hora4_entrega
                                         , emp_rota
                                         , fil_rota
                                         , cod_rota
                                         , cod_integracao
                                         , dthr_inc
                                         , usu_inc
                                         )
                                  VALUES ( oCNPJCPF
                                         #, IF(IFNULL(oTipoPessoa,"O")="", "O", IFNULL(oTipoPessoa,"O"))
                                         , IF(IFNULL(oTipoPessoa,"J")="", "J", IFNULL(oTipoPessoa,"J"))
                                         , SUBSTRING(oRazSocial,1, 60)
                                         , SUBSTRING(oNomeFantasia,1, 50)
                                         , oInscrEstadual
                                         , oIndicadorIE
                                         , SUBSTRING(oEndereco,1,50)
                                         , SUBSTRING(oNumEnde,1,10)
                                         , SUBSTRING(oComplEnde,1,30)
                                         , SUBSTRING(oBairroEnde,1,50)
                                         , SUBSTRING(oCidadeEnde,1,50)
                                         , SUBSTRING(oUFEnde,1,2)
                                         , SUBSTRING(oCepEnde,1,8)
                                         , oContato01
                                         , oFone01
                                         , oEmail01
                                         , oCNPJCPF
                                         , oCNPJCliente
                                         , ohora1_entrega
                                         , ohora2_entrega
                                         , ohora3_entrega
                                         , ohora4_entrega
                                         , xemp_rota
                                         , xfil_rota
                                         , xcod_rota                                      
                                         , oCNPJCPF
                                         , NOW()
                                         , oCodUsuario
                                         );
     SET RESULTADO = 'TRUE';
     SET MENSAGEM = "Registro Inserido com sucesso";
  
  END; 
  ELSE
  BEGIN 
  
    UPDATE of_logistica.tbdestinatarios 
       SET tbdestinatarios.tipo_pessoa	     =	oTipoPessoa
         , tbdestinatarios.raz_social		     =	SUBSTRING(oRazSocial,01,60)
         , tbdestinatarios.nome_fantasia	   =	SUBSTRING(oNomeFantasia,01,50)
         , tbdestinatarios.inscr_estadual	  =	oInscrEstadual
         , tbdestinatarios.idIEDest         = oIndicadorIE
         , tbdestinatarios.endereco		       =	SUBSTRING(oEndereco,1,50)
         , tbdestinatarios.num_ende		       =	SUBSTRING(oNumEnde,1,10)
         , tbdestinatarios.compl_ende		     =	SUBSTRING(oComplEnde,1,30)
         , tbdestinatarios.bairro			        =	SUBSTRING(oBairroEnde,1,50)
         , tbdestinatarios.nome_cidade	     =	SUBSTRING(oCidadeEnde,1,50)
         , tbdestinatarios.sig_estado		     =	SUBSTRING(oUFEnde,1,2)
         , tbdestinatarios.cep_ende		       =	SUBSTRING(oCepEnde,1,8)
         , tbdestinatarios.contato		        =	oContato01
         , tbdestinatarios.telefone		       =	oFone01
         , tbdestinatarios.email			         =	oEmail01
         , tbdestinatarios.hora1_entrega    = IFNULL(ohora1_entrega,tbdestinatarios.hora1_entrega)
         , tbdestinatarios.hora2_entrega    = IFNULL(ohora2_entrega,tbdestinatarios.hora2_entrega)
         , tbdestinatarios.hora3_entrega    = IFNULL(ohora3_entrega,tbdestinatarios.hora3_entrega)
         , tbdestinatarios.hora4_entrega    = IFNULL(ohora4_entrega,tbdestinatarios.hora4_entrega)
         , tbdestinatarios.emp_rota         = IFNULL(tbdestinatarios.emp_rota, xemp_rota)
         , tbdestinatarios.fil_rota         = IFNULL(tbdestinatarios.fil_rota, xfil_rota)
         , tbdestinatarios.cod_rota         = IFNULL(tbdestinatarios.cod_rota, xcod_rota)
         , tbdestinatarios.flg_ativo        = 1
         , tbdestinatarios.dthr_alt 	       = NOW()
         , tbdestinatarios.usu_alt 		       = oCodUsuario
     WHERE tbdestinatarios.cnpj_cpf_cliente = oCNPJCliente
       AND tbdestinatarios.cod_integracao   = oCNPJCPF;
     SET RESULTADO = 'TRUE';
     SET MENSAGEM  = "Registro Atualizado com sucesso";
  
  END; 
  END IF;
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_CAD_Fornecedor.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_CAD_Fornecedor`$$

CREATE PROCEDURE `PROC_INTEGRA_CAD_Fornecedor`(
   IN oCodUsuario				   VARCHAR(10),
   IN oCnpjCpfTerc			   VARCHAR(14),
   IN oRazSocial				    VARCHAR(100),
   IN oNomeFantasia			  VARCHAR(100),
   # Parametros de Retorno
   OUT RESULTADO        INT,
   OUT MENSAGEM         VARCHAR(500)
)
BLOCO1:BEGIN
   DECLARE xIncAlt      VARCHAR(01)	DEFAULT 'I';
   DECLARE excecao      INT DEFAULT 0;
   -- DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   IF EXISTS (SELECT cnpj_cpf FROM of_logistica.tbclientes
              WHERE cnpj_cpf = oCnpjCpfTerc) THEN
      SET xIncAlt = 'A';
   END IF;
   #Tratar as variáveis
   /*******************************************************************
   #Tratar e Validar as variáveis
   *******************************************************************/
   SET MENSAGEM = '';
   IF TRIM(IFNULL(oCnpjCpfTerc,'')) = '' THEN
      SET MENSAGEM = "CNPJ/CPF TERCEIRO Inválido";
   ELSEIF TRIM(IFNULL(oRazSocial,'')) = '' THEN
      SET MENSAGEM = "Razão Social Inválida";
   END IF;    
   IF mensagem <> '' THEN
      SET RESULTADO = 0;
      LEAVE BLOCO1;
   END IF;
   IF xIncAlt = 'I' THEN
      #Insere tbClientes
      INSERT INTO of_logistica.tbclientes (cnpj_cpf, raz_social, nome_fantasia, tipo_pessoa, tipo_cli_for, flg_ativo, dthr_inc, usu_inc)
      VALUES (oCnpjCpfTerc, SUBSTRING(oRazSocial,1,60), SUBSTRING(oNomeFantasia,1,60), 'J', 'F', 'S', NOW(), '999999');
      SET RESULTADO = 1;
      SET MENSAGEM = "Registro Inserido com sucesso";
   ELSE
      UPDATE of_logistica.tbclientes  SET
              cnpj_cpf       = oCnpjCpfTerc
             ,raz_social     = SUBSTRING(oRazSocial,1,60)
             ,nome_fantasia  = SUBSTRING(oRazSocial,1,60)
             ,tipo_pessoa    = 'J'
             ,tipo_cli_for   = 'F'
             ,flg_ativo      = 'S'
             ,dthr_alt       = NOW()
             ,usu_alt        = '999999'
      WHERE cnpj_cpf = oCnpjCpfTerc;
          
     SET RESULTADO = 1;
     SET MENSAGEM = "Registro Atualizado com sucesso";
     
   END IF;
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = "Erro SQL - Verifique com o Administrador";
      #SELECT RESULTADO, MENSAGEM;
   END IF;
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_CAD_Produtos.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_CAD_Produtos`$$

CREATE PROCEDURE `PROC_INTEGRA_CAD_Produtos`(
	IN oCodUsuario				           VARCHAR(10),
	IN cnpj_cpf 				             VARCHAR(14),
	IN ocod_produto 			          VARCHAR (20),
	IN oprd_ativo 				           VARCHAR(1),
	IN odescr_produto 			        VARCHAR (50),
	IN odescr_abrev 			          VARCHAR (50),
	IN odescr_estrangeiro 		     VARCHAR (50),
	IN ocod_barras 				          VARCHAR (30),
	IN onum_nbm 				             VARCHAR (10),
	IN osit_tribut 				          VARCHAR(3),
	IN operc_ipi 				            DOUBLE (9, 3),
	IN operc_icms 				           DOUBLE (9, 3),
	IN oredu_icms_est 			        DOUBLE (13, 5),
	IN oredu_icms_fora 			       DOUBLE (13, 5),
	IN otipo_produto 			         VARCHAR (3),
	IN otipo_peso_produto 		     VARCHAR(1),
	IN oemb_frac 				            VARCHAR(3),
	IN opeso_liq_frac 			        DOUBLE (9, 3),
	IN opeso_bruto_frac 		       DOUBLE (9, 3),
	IN oemb_estoque 			          VARCHAR(3),
	IN oemb_vol 				             VARCHAR(3),
	IN opeso_liq_vol 			         DOUBLE (9, 3),
	IN opeso_bruto_vol 			       DOUBLE (9, 3),
	IN omaior_embalagem 		       VARCHAR(3),
	IN ofator_conversao 		       DOUBLE (9, 3),
	IN oqtde_unidades_por_volume DOUBLE (9, 2),
	IN ofator_cubagem 			        DOUBLE (9, 3),
	IN otipo_armazenagem 		      VARCHAR(1),
	IN ocontrole_valid 			       VARCHAR(1),
	IN odias_dt_critica 		       INT (11),
	IN odias_dt_restrita 		      INT (11),
	IN oprazo_valid 			          INT (11),
	IN oemb_pallet 				          VARCHAR(3),
	IN oqtde_vol_pallet 		       DOUBLE (13, 5),
	IN ocontrole_temp 			        VARCHAR(1),
	IN ovalor_unitario 			       DOUBLE (9, 3),
	IN odata_preco_unit 		       DATETIME,
	IN odthr_inc 				            DATETIME,
	IN ousu_inc 				             VARCHAR(6),
	IN odthr_alt 				            DATETIME,
	IN ousu_alt 				             VARCHAR(6),
	IN oqtde_min_especifica 	    INT (11),
	IN oqtde_min_picking 		      DOUBLE (13, 5),
	IN oflg_etiq_vol_saida 		    INT (1),
	IN oqtde_min_picking_retorno DOUBLE (13, 5),
	# Parametros de Retorno
	OUT RESULTADO             	  VARCHAR(5),
	OUT MENSAGEM              	  VARCHAR(500)
)
BLOCO1:BEGIN
   DECLARE xIncAlt VARCHAR(01)	DEFAULT 'I';
   DECLARE excecao INT DEFAULT 0;
   DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   IF EXISTS (SELECT cnpj_cpf FROM of_logistica.tbprodutos
        WHERE cnpj_cpf    = ocnpj_cpf
        AND cod_produto = ocod_produto) THEN
    SET xIncAlt = 'A';
   END IF;
   #Tratar as variáveis
   /*******************************************************************
   #Tratar e Validar as variáveis
   *******************************************************************/
   IF xIncAlt = 'I' THEN
      #Insere tbprodutos
      INSERT INTO of_logistica.tbprodutos (
             cnpj_cpf
            ,cod_produto
            ,prd_ativo
            ,descr_produto
            ,descr_abrev
            ,descr_estrangeiro
            ,cod_barras
            ,num_nbm
            ,sit_tribut
            ,perc_ipi
            ,perc_icms
            ,redu_icms_est
            ,redu_icms_fora
            ,tipo_produto
            ,tipo_peso_produto
            ,emb_frac
            ,peso_liq_frac
            ,peso_bruto_frac
            ,emb_estoque
            ,emb_vol
            ,peso_liq_vol
            ,peso_bruto_vol
            ,maior_embalagem
            ,fator_conversao
            ,qtde_unidades_por_volume
            ,fator_cubagem
            ,tipo_armazenagem
            ,controle_valid
            ,dias_dt_critica
            ,dias_dt_restrita
            ,prazo_valid
            ,emb_pallet
            ,qtde_vol_pallet
            ,controle_temp
            ,valor_unitario
            ,data_preco_unit
            ,dthr_inc
            ,usu_inc
            ,dthr_alt
            ,usu_alt
            ,qtde_min_especifica
            ,qtde_min_picking
            ,flg_etiq_vol_saida
            ,qtde_min_picking_retorno
      ) VALUES (
           ocnpj_cpf
          ,ocod_produto
          ,oprd_ativo
          ,odescr_produto
          ,odescr_abrev
          ,odescr_estrangeiro
          ,ocod_barras
          ,onum_nbm
          ,osit_tribut
          ,operc_ipi
          ,operc_icms
          ,oredu_icms_est
          ,oredu_icms_fora
          ,otipo_produto
          ,otipo_peso_produto
          ,oemb_frac
          ,opeso_liq_frac
          ,opeso_bruto_frac
          ,oemb_estoque
          ,oemb_vol
          ,opeso_liq_vol
          ,opeso_bruto_vol
          ,omaior_embalagem
          ,ofator_conversao
          ,oqtde_unidades_por_volume
          ,ofator_cubagem
          ,otipo_armazenagem
          ,ocontrole_valid
          ,odias_dt_critica
          ,odias_dt_restrita
          ,oprazo_valid
          ,oemb_pallet
          ,oqtde_vol_pallet
          ,ocontrole_temp
          ,ovalor_unitario
          ,odata_preco_unit
          ,NOW()
          ,oCodUsuario
          ,NULL
          ,NULL
          ,oqtde_min_especifica
          ,oqtde_min_picking
          ,oflg_etiq_vol_saida
          ,oqtde_min_picking_retorno
      );
     SET RESULTADO = 'TRUE';
     SET MENSAGEM = "Registro Inserido com sucesso";
     
   ELSE
   
     UPDATE of_logistica.tbprodutos SET
            #cnpj_cpf            = IFNULL(ocnpj_cpf,cnpj_cpf,ocnpj_cpf),
            #cod_produto         = IFNULL(ocod_produto,cod_produto,ocod_produto),
            prd_ativo            = IFNULL(oprd_ativo,prd_ativo),
            descr_produto        = IFNULL(odescr_produto,descr_produto),
            descr_abrev          = IFNULL(odescr_abrev,descr_abrev),
            descr_estrangeiro    = IFNULL(odescr_estrangeiro,descr_estrangeiro),
            cod_barras           = IFNULL(ocod_barras,cod_barras),
            num_nbm              = IFNULL(onum_nbm,num_nbm),
            sit_tribut           = IFNULL(osit_tribut,sit_tribut),
            perc_ipi             = IFNULL(operc_ipi,perc_ipi),
            perc_icms            = IFNULL(operc_icms,perc_icms),
            redu_icms_est        = IFNULL(oredu_icms_est,redu_icms_est),
            redu_icms_fora       = IFNULL(oredu_icms_fora,redu_icms_fora),
            tipo_produto         = IFNULL(otipo_produto,tipo_produto),
            tipo_peso_produto    = IFNULL(otipo_peso_produto,tipo_peso_produto),
            emb_frac             = IFNULL(oemb_frac,emb_frac),
            peso_liq_frac        = IFNULL(opeso_liq_frac,peso_liq_frac),
            peso_bruto_frac      = IFNULL(opeso_bruto_frac,peso_bruto_frac),
            emb_estoque          = IFNULL(oemb_estoque,emb_estoque),
            emb_vol              = IFNULL(oemb_vol,emb_vol),
            peso_liq_vol         = IFNULL(opeso_liq_vol,peso_liq_vol),
            peso_bruto_vol       = IFNULL(opeso_bruto_vol,peso_bruto_vol),
            maior_embalagem      = IFNULL(omaior_embalagem,maior_embalagem),
            fator_conversao      = IFNULL(ofator_conversao,fator_conversao),
            qtde_unidades_por_volume = IFNULL(oqtde_unidades_por_volume,qtde_unidades_por_volume),
            fator_cubagem        = IFNULL(ofator_cubagem,fator_cubagem),
            tipo_armazenagem     = IFNULL(otipo_armazenagem,tipo_armazenagem),
            controle_valid       = IFNULL(ocontrole_valid,controle_valid),
            dias_dt_critica      = IFNULL(odias_dt_critica,dias_dt_critica),
            dias_dt_restrita     = IFNULL(odias_dt_restrita,dias_dt_restrita),
            prazo_valid          = IFNULL(oprazo_valid,prazo_valid),
            emb_pallet           = IFNULL(oemb_pallet,emb_pallet),
            qtde_vol_pallet      = IFNULL(oqtde_vol_pallet,qtde_vol_pallet),
            controle_temp        = IFNULL(ocontrole_temp,controle_temp),
            valor_unitario       = IFNULL(ovalor_unitario,valor_unitario),
            data_preco_unit      = IFNULL(odata_preco_unit,data_preco_unit),
            #dthr_inc            = IFNULL(odthr_inc,dthr_inc,odthr_inc),
            #usu_inc             = IFNULL(ousu_inc,usu_inc,ousu_inc),
            dthr_alt             = NOW(),
            usu_alt              = oCodUsuario,
            qtde_min_especifica  = IFNULL(oqtde_min_especifica,qtde_min_especifica),
            qtde_min_picking     = IFNULL(oqtde_min_picking,qtde_min_picking),
            flg_etiq_vol_saida   = IFNULL(oflg_etiq_vol_saida,flg_etiq_vol_saida),
            qtde_min_picking_retorno = IFNULL(oqtde_min_picking_retorno,qtde_min_picking_retorno)
      WHERE cnpj_cpf 	= oCnpjCpf AND cod_produto = ocod_produto;
      
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

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_CAD_Produto_Paridade.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_CAD_Produto_Paridade`$$

CREATE PROCEDURE `PROC_INTEGRA_CAD_Produto_Paridade`(
	IN oCodUsuario				   VARCHAR(10),
	IN ocnpj_cpf_cli 			 VARCHAR(14),
	IN ocod_produto 			  VARCHAR(20),
	IN ocnpj_cpf_for 			 VARCHAR(14),
	IN ocod_produto_for		VARCHAR(20),
	IN odescr_produto 		 VARCHAR(50),
	# Parametros de Retorno
	OUT RESULTADO        VARCHAR(5),
	OUT MENSAGEM         VARCHAR(500)
)
BLOCO1:BEGIN
	DECLARE xIncAlt      VARCHAR(01)	DEFAULT 'I';
	DECLARE excecao      INT DEFAULT 0;
	-- DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
	
	IF EXISTS (SELECT 1 FROM of_logistica.tbprodutos_paridade
			   WHERE cnpj_cpf_for = ocnpj_cpf_for
			     AND cod_prod_for = ocod_produto_for
			     AND cnpj_cpf_cli = ocnpj_cpf_cli
			     AND cod_produto  = ocod_produto) THEN
		SET xIncAlt = 'A';
	END IF;
	
	#Tratar as variáveis
	
	/*******************************************************************
	#Tratar e Validar as variáveis
	*******************************************************************/
	IF xIncAlt = 'I' THEN
		#Insere tbprodutos
		INSERT INTO of_logistica.tbprodutos_paridade (
         cnpj_cpf_for   
			,cod_prod_for   
			,cnpj_cpf_cli
			,cod_produto    
			,descr_prod_for
			#,flg_barcode
		) VALUES (
          ocnpj_cpf_for
         ,ocod_produto_for
         ,ocnpj_cpf_cli
         ,ocod_produto
         ,odescr_produto
         #,'EAN'
		);
			SET RESULTADO = 'TRUE';
			SET MENSAGEM = "Registro Inserido com sucesso";
	ELSE
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

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_CAD_Produto_Paridade_Emb.sql*/

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

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_CAD_Terceiro.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_CAD_Terceiro`$$

CREATE PROCEDURE `PROC_INTEGRA_CAD_Terceiro`(
   IN oCodUsuario				   VARCHAR(10),
   IN oCnpjCpfCli				   VARCHAR(14),
   IN oCnpjCpfTerc			   VARCHAR(14),
   IN oTipoTerceiro			  INT, #0=Fornecedor / 1=Transportador
   IN oRazSocial				    VARCHAR(100),
   IN oNomeFantasia			  VARCHAR(100),
   IN oStatusAtivo			   INT,
   # Parametros de Retorno
   OUT RESULTADO        INT,
   OUT MENSAGEM         VARCHAR(500)
)
BLOCO1:BEGIN
   DECLARE xIncAlt      VARCHAR(01)	DEFAULT 'I';
   DECLARE excecao      INT DEFAULT 0;
   -- DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   IF EXISTS (SELECT cnpj_cpf_cliente FROM of_logistica.tbwms_terceiro
              WHERE cnpj_cpf_cliente  = oCnpjCpfCli
                AND cnpj_cpf_terceiro = oCnpjCpfTerc) THEN
      SET xIncAlt = 'A';
   END IF;
   #Tratar as variáveis
   /*******************************************************************
   #Tratar e Validar as variáveis
   *******************************************************************/
   SET MENSAGEM = '';
   IF TRIM(IFNULL(oCnpjCpfCli,'')) = '' THEN
      SET MENSAGEM = "CNPJ/CPF Cliente Inválido";
   ELSEIF TRIM(IFNULL(oCnpjCpfTerc,'')) = '' THEN
      SET MENSAGEM = "CNPJ/CPF TERCEIRO Inválido";
   ELSEIF TRIM(IFNULL(oTipoTerceiro,'')) NOT IN (0,1) THEN
      SET MENSAGEM = "Tipo Terceiro Inválido";
   ELSEIF TRIM(IFNULL(oRazSocial,'')) = '' THEN
      SET MENSAGEM = "Razão Social Inválida";
   END IF;    
   IF mensagem <> '' THEN
      SET RESULTADO = 0;
      LEAVE BLOCO1;
   END IF;
   IF xIncAlt = 'I' THEN
      #Insere tbClientes
      INSERT INTO of_logistica.tbwms_terceiro (cnpj_cpf_cliente, cnpj_cpf_terceiro, raz_social, nome_fantasia, tipo, flg_ativo, senha, dthr_inc, usu_inc)
      VALUES (oCnpjCpfCli, oCnpjCpfTerc, SUBSTRING(oRazSocial,1,50), SUBSTRING(oNomeFantasia,1,50), oTipoTerceiro, oStatusAtivo, '123', NOW(), '999999');
      SET RESULTADO = 1;
      SET MENSAGEM = "Registro Inserido com sucesso";
   ELSE
      UPDATE of_logistica.tbwms_terceiro SET
             cnpj_cpf_cliente    = oCnpjCpfCli
             ,cnpj_cpf_terceiro  = oCnpjCpfTerc
             ,raz_social         = SUBSTRING(oRazSocial,1,50)
             ,nome_fantasia      = SUBSTRING(oNomeFantasia,1,50)
             ,tipo               = oTipoTerceiro
             ,flg_ativo          = oStatusAtivo
             ,senha              = '123'
             ,dthr_inc           = NOW()
             ,usu_inc            = '999999'
      WHERE cnpj_cpf_cliente  = oCnpjCpfCli
        AND cnpj_cpf_terceiro = oCnpjCpfTerc;
          
     SET RESULTADO = 1;
     SET MENSAGEM = "Registro Atualizado com sucesso";
     
   END IF;
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = "Erro SQL - Verifique com o Administrador";
      #SELECT RESULTADO, MENSAGEM;
   END IF;
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_CancelarAlteracoesDuplicadas.sql*/

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

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_CancelarEntrada.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_CancelarEntrada`$$

CREATE PROCEDURE `PROC_INTEGRA_CancelarEntrada`(
   IN  oIdEntrada            INT,
   IN  oDocTipo              VARCHAR(10),
   IN  oTipoRetorno          INT,   #0=Retorna Chave (emp/fil/ano/num) | 1=Update dthr_cancel
   # Parametros de Retorno
   OUT RESULTADO             INT,
   OUT MENSAGEM              VARCHAR(500)
)
BLOCO1:BEGIN
   DECLARE xCodEmpWMS			     VARCHAR(03);
   DECLARE xCodFilWMS			     VARCHAR(03);
   DECLARE xAnoSolic 			     VARCHAR(04);
   DECLARE xNumSolic 			     VARCHAR(10);
   DECLARE xstatus_processo  INT;
   
   DECLARE excecao 	         INT DEFAULT 0;
   
   /*DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       ROLLBACK;
   END;*/
   
   #Transação tratada pela procedure "Pai"   
   START TRANSACTION;
   IF oTipoRetorno = 0 THEN
      SELECT TopoWMS.cod_emp, TopoWMS.cod_fil, TopoWMS.ano_solic, TopoWMS.num_solic, TopoWMS.status_processo
      INTO xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xstatus_processo
      FROM tbintegraSAP_Doc TopoDoc
      INNER JOIN of_logistica.tbsolic_entradas TopoWMS ON 
                 TopoWMS.cod_emp   = TopoDoc.cod_emp
             AND TopoWMS.cod_fil   = TopoDoc.cod_fil
             AND TopoWMS.ano_solic = TopoDoc.ano_solic
             AND TopoWMS.num_solic = TopoDoc.num_solic
      WHERE TopoDoc.DocEntry = oIdEntrada
        AND TopoDoc.DocTipo  = oDocTipo
        AND TopoDoc.TipoDocSLIN = "E";
      SET RESULTADO = 1;
      #SET MENSAGEM  = CONCAT("Cancelamento Realizado com sucesso [",xCodEmpWMS, '/', xCodFilWMS, '-', xAnoSolic, '.', xNumSolic,"]");
      IF xstatus_processo = 11  THEN #Cancelado
         SET RESULTADO = 0;
         SET MENSAGEM  = CONCAT("GEM já está Cancelada [",xCodEmpWMS, '/', xCodFilWMS, '-', xAnoSolic, '.', xNumSolic,"] - Cancelamento impossível");
      ELSEIF xstatus_processo >= 6  THEN #Conferencia
         SET RESULTADO = 0;
         SET MENSAGEM  = CONCAT("GEM em Conferencia [",xCodEmpWMS, '/', xCodFilWMS, '-', xAnoSolic, '.', xNumSolic,"] - Cancelamento impossível");
      ELSE   
         SET MENSAGEM = CONCAT(xCodEmpWMS, '|', xCodFilWMS, '|', xAnoSolic, '|', xNumSolic);    
      END IF;
   ELSE
   
      #set RESULTADO = 0;
      #set MENSAGEM = "";
      #CALL of_logistica.PROC_WMS_DESCARGA_CANCELAR_GEM_INTEGRACAO(xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, RESULTADO, MENSAGEM);
      
      #if RESULTADO = 1 then
         UPDATE tbintegraSAP_Doc
         SET dthr_cancel = NOW(),
             StatusDoc   = 9
         WHERE DocEntry = oIdEntrada
           AND DocTipo  = oDocTipo;      
       #end if;
   END IF;
   
   IF excecao = 1 THEN
      ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- Erro PROC_INTEGRA_CancelarEntrada [",xQtdeRegs,"]");
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      COMMIT;
      SET RESULTADO = 1;
      #SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- (PROC_INTEGRA_CancelarEntrada) processamento com sucesso [",xQtdeRegs,"]");
   END IF;
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_CancelarGSM.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_CancelarGSM`$$

CREATE PROCEDURE `PROC_INTEGRA_CancelarGSM`(
   IN oCodEmpWMS	    VARCHAR(03),
   IN oCodFilWMS		   VARCHAR(03),
   IN oAnoSolic 		   VARCHAR(04),
   IN oNumSolic 		   VARCHAR(30)
   # Parametros de Retorno
   #OUT RESULTADO    INT,
   #OUT MENSAGEM     VARCHAR(500)
)
BLOCO1:BEGIN
   #@Reviser David Ruy <2021/01/05>
   #Quando enviar oCodEmpWMS = 'X', então considerar DocumentType/DocumentNumber/DocumentId (EX:PV/160/433)
   #@Reviser David Ruy <2022-01-31> Listar o campo DocEntry_Substituto (U_RSD_RplOrder)
   #@Reviser David Ruy <2023-03-10> No select TMP_CancelarGSM, não trazer registros com item sem num_solic
   #@Reviser David Ruy <2023-07-14> Melhora no select e busca cancelamentos até 30 dias para trás
   #@Reviser David Ruy <2023-08-03> Desabilitando, permite cancelar PV´ ainda não integrados
   #@Reviser David Ruy <2024-07-16> Campo IdPicking para permitir atualizar PK de Pedidos Parciais (Leinertex)
   DECLARE RESULTADO        INT;
   DECLARE MENSAGEM         VARCHAR(500);
   DECLARE xDocumentId      INT;
   DECLARE xDocumentType    VARCHAR(10);
   DECLARE xDocumentNumber  INT;
   
   DECLARE xQtdeRegs        INT DEFAULT 0;
   DECLARE excecao 	        INT DEFAULT 0;
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       ROLLBACK;
   END;
   
   START TRANSACTION;
   
  IF IFNULL(oCodEmpWMS,'') = '' THEN
     #Cancelamentos Pendentes originadas no SAP-B1
      DROP TEMPORARY TABLE IF EXISTS TMP_CancelarGSM;
      CREATE TEMPORARY TABLE TMP_CancelarGSM ( 
         SELECT tbUpdCancPV.DocumentId, tbUpdCancPV.DocumentType, tbUpdCancPV.DocumentNumber,
                tbItem.cod_emp, tbItem.cod_fil, tbItem.ano_solic, tbItem.num_solic,
                COUNT(tbUpdCancPV.LineNumber) QtdeLinhasCancel,
                COUNT(tbItem.LineNum) QtdeItensPedido,
                tbPvSubstituto.DocEntry DocEntry_Substituto,
                tbPvSubstituto.DocNum   DocNum_Substituto,
                "Cancelar GSM" Observ,  tbTopo.idPicking,
                0 AS FlgProcessado
         FROM tbintegraSAP_UpdCancPV tbUpdCancPV
         INNER JOIN tbintegraSAP_DocItem tbItem ON 
                    tbItem.DocEntry = tbUpdCancPV.DocumentId
                AND tbItem.DocTipo  = tbUpdCancPV.DocumentType 
                AND tbItem.DocNum   = tbUpdCancPV.DocumentNumber 
         INNER JOIN tbintegraSAP_Doc tbTopo ON 
                    tbTopo.DocEntry = tbUpdCancPV.DocumentId
                AND tbTopo.DocTipo  = tbUpdCancPV.DocumentType 
                AND tbTopo.DocNum   = tbUpdCancPV.DocumentNumber 
         LEFT JOIN tbintegraSAP_Doc tbPvSubstituto ON 
                    tbPvSubstituto.DocTipo = 'PV'
                AND tbPvSubstituto.U_RSD_RplOrder = tbUpdCancPV.DocumentId
                AND tbPvSubstituto.DocTipo        = tbUpdCancPV.DocumentType 
                AND tbPvSubstituto.dthr_inc >= DATE_ADD(CURRENT_DATE(), INTERVAL -30 DAY)
         WHERE tbUpdCancPV.dthr_inc >= DATE_ADD(CURRENT_DATE(), INTERVAL -30 DAY)
           AND tbUpdCancPV.cod_emp IS NULL
           AND tbUpdCancPV.TipoUpdCanc = 'C'
           AND tbUpdCancPV.STATUS = 0
           #Alterado em 20230803 : Desabilitando, permite cancelar PV´ ainda não integrados
           #AND tbItem.cod_emp IS NOT NULL
         GROUP BY tbUpdCancPV.DocumentId, tbUpdCancPV.DocumentType, tbUpdCancPV.DocumentNumber
         #Já vem do SAP TODOS os itens do pedido cancelado
         #having QtdeLinhasCancel = QtdeItensPedido
      );  
      
      SELECT * FROM TMP_CancelarGSM;
      
  ELSE
  
      #Prepara as variáveis para busca pelo Documento da Integracao
      IF oCodEmpWMS = 'X' THEN
      
         SET xDocumentType   = SUBSTRING(oNumSolic, 01, LOCATE('/',oNumSolic)-1);
         SET oNumSolic       = REPLACE(oNumSolic, CONCAT(xDocumentType,'/'), '');
         SET xDocumentNumber = SUBSTRING(oNumSolic, 01, LOCATE('/',oNumSolic)-1);
         SET oNumSolic       = REPLACE(oNumSolic, CONCAT(xDocumentNumber,'/'), '');
         SET xDocumentId     = oNumSolic;
         
         SET oCodEmpWMS = "000";
         SET oCodFilWMS = "000";
         SET oAnoSolic  = "0000";
         SET oNumSolic  = "0000000000";
         
      ELSE
      
         #Prepara as variáveis para busca pelo Documento do SLIN
         SELECT tbUpdCancPV.DocumentId, tbUpdCancPV.DocumentType, tbUpdCancPV.DocumentNumber
         INTO xDocumentId, xDocumentType, xDocumentNumber
         FROM tbintegraSAP_UpdCancPV tbUpdCancPV
         INNER JOIN tbintegraSAP_DocItem tbItem ON 
                    tbItem.DocEntry = tbUpdCancPV.DocumentId
                AND tbItem.DocTipo  = tbUpdCancPV.DocumentType 
                AND tbItem.DocNum   = tbUpdCancPV.DocumentNumber 
         WHERE tbItem.cod_emp   = oCodEmpWMS
           AND tbItem.cod_fil   = oCodFilWMS
           AND tbItem.ano_solic = oAnoSolic
           AND tbItem.num_solic = oNumSolic
           AND tbUpdCancPV.TipoUpdCanc = 'C'
         LIMIT 1;
      END IF;
  
  
      #Atualiza Integração de que a GSM foi cancelada
      UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV
      SET tbUpdCancPV.cod_emp   = oCodEmpWMS,
          tbUpdCancPV.cod_fil   = oCodFilWMS,
          tbUpdCancPV.ano_solic = oAnoSolic,
          tbUpdCancPV.num_solic = oNumSolic
      WHERE tbUpdCancPV.DocumentId     = xDocumentId
        AND tbUpdCancPV.DocumentType   = xDocumentType
        AND tbUpdCancPV.DocumentNumber = xDocumentNumber;
        
      UPDATE tbintegraSAP_Doc
      SET StatusAnt = StatusDoc,
          StatusDoc = 9
      WHERE tbintegraSAP_Doc.DocEntry = xDocumentId
        AND tbintegraSAP_Doc.DocTipo  = xDocumentType
        AND tbintegraSAP_Doc.DocNum   = xDocumentNumber;
      
   END IF;
   
   DROP TEMPORARY TABLE IF EXISTS TMP_CancelarGSM;    
   
   IF excecao = 1 THEN
      ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,"ERRO "),"- PROC_INTEGRA_CancelarGSM");
   ELSE
      COMMIT;
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,"OK "),"- PROC_INTEGRA_CancelarGSM");
   END IF;
   SELECT RESULTADO, MENSAGEM;
   
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_CancelarItemUPD.sql*/

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

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_ConfirmarAlteracaoPedido.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_ConfirmarAlteracaoPedido`$$

CREATE PROCEDURE `PROC_INTEGRA_ConfirmarAlteracaoPedido`(
   IN oDocEntry      INT,
   IN oDocNum        INT,
   IN oDocTipo       VARCHAR(10),
   IN oLineNum       INT,
   # Parametros de Retorno
   OUT RESULTADO     INT,
   OUT MENSAGEM      VARCHAR(500)
)
BLOCO1:BEGIN
   DECLARE excecao 	 INT DEFAULT 0;
   
   /*DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       ROLLBACK;
   END;*/
   
   START TRANSACTION;
   
   UPDATE of_logistica.tbsolic_saidas_item_integra_alteracao tbAlteracao
   INNER JOIN tbintegraSAP_DocItem DocItem ON
              DocItem.cod_emp   = tbAlteracao.cod_emp 
          AND DocItem.cod_fil   = tbAlteracao.cod_fil 
          AND DocItem.ano_solic = tbAlteracao.ano_solic 
          AND DocItem.num_solic = tbAlteracao.num_solic 
          AND DocItem.num_item  = tbAlteracao.num_item
   SET tbAlteracao.dthr_atu_integra = NOW()
   WHERE DocItem.DocEntry = oDocEntry
     AND DocItem.DocTipo  = oDocTipo
     AND DocItem.DocNum   = oDocNum
     AND DocItem.LineNum  = oLineNum;
   UPDATE tbintegraSAP_Doc
   SET  StatusAnt = IF(StatusDoc=7,StatusDoc, StatusAnt)
       ,StatusDoc = IF(StatusDoc=7,3, StatusDoc) 
       ,dthr_alt  = NOW()
       ,usu_alt   = "999999"
   WHERE DocEntry = oDocEntry
     AND DocTipo  = oDocTipo
     AND DocNum   = oDocNum;
     
   
   IF excecao = 1 THEN
      ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- Erro PROC_INTEGRA_ConfirmarAtuAlteracao [",CONCAT(oDocEntry,'-',oDocTipo,oDocNum,'-',oLineNum),"]");
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      COMMIT;
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- Alterações processadas com sucesso (PROC_INTEGRA_ConfirmarAtuAlteracao) [",CONCAT(oDocEntry,'-',oDocTipo,oDocNum,'-',oLineNum),"]");
   END IF;
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_ConfirmarGEM.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_ConfirmarGEM`$$

CREATE PROCEDURE `PROC_INTEGRA_ConfirmarGEM`(
#   oChaveIntegracao    varchar(30),
#   oDocTipo            VARCHAR(30),
#   oDocEntry           VARCHAR(30),
   # Parametros de Retorno
   OUT RESULTADO              INT,
   OUT MENSAGEM               VARCHAR(500)
)
BLOCO1:BEGIN
  /************************************************************************/
  # @Created David Ruy <2024/06/16>
  # Esta procedure atualiza uma GEM com informações de recebimento de produção do SAP
  # Gera a conferencia e confirmação no SLIN-WMS
  # @Reviser David Ruy <2025-10-29> Ajuste parametro PROC_WMS_DESCARGA_ATUALIZAR_CONFERENCIA_ITEM_DESCARGA
  # @Reviser David Ruy <2025-11-28> Ajuste para pegar a primeira sequencia de etiqueta por PA/ItemCode
  /************************************************************************/
   DECLARE excecao 	INT(6) DEFAULT 0;
   DECLARE _RESULTADO INT DEFAULT 0;
   DECLARE _MENSAGEM  VARCHAR(500);
   DECLARE xCodEmp        VARCHAR(03);
   DECLARE xCodFil        VARCHAR(03);
   DECLARE xAnoSolic      VARCHAR(04);
   DECLARE xNumSolic      VARCHAR(10);
   DECLARE xNumItem       VARCHAR(06);
   DECLARE xItemCode      VARCHAR(30);
   
   DECLARE xDocTipo       VARCHAR(10);
   DECLARE xDocEntry      VARCHAR(30);
   DECLARE xDocNum        VARCHAR(30);
   DECLARE xChaveIntegracao VARCHAR(100);
   
   DECLARE xLoteFabricacao VARCHAR(30);
   DECLARE xDataFabricacao VARCHAR(30);
   DECLARE xDataValidade   VARCHAR(30);
   
   DECLARE xQtdeEstItem   DECIMAL(18,6);
   DECLARE xQtdeVolItem   DECIMAL(18,6);
   DECLARE xQtdeFracItem  DECIMAL(18,6);
   DECLARE xQtdePesoItem  DECIMAL(18,6);
   DECLARE xFatorConv     DECIMAL(18,6);
   DECLARE xNumeroUA      VARCHAR(10);
   DECLARE xSequenciaUA   INT(3);
   DECLARE xQtdeEstUA     DECIMAL(18,6);
   DECLARE xQtdeVolUA     DECIMAL(18,6);
   DECLARE xQtdeFracUA    DECIMAL(18,6);
   DECLARE xQtdePesoUA    DECIMAL(18,6);
   
   DECLARE xInicioSequencia INT(6);
   DECLARE xDocTipoAux      VARCHAR(30);
   DECLARE xVersaoPA        INT(6);
   DECLARE xStringEtqAux    VARCHAR(100);
   DECLARE xStringEtq       VARCHAR(100);
   DECLARE xCampoQtdeStr    VARCHAR(10);

   #Verificar se tem transação nas procedures
   #Se tiver, lascou
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       IF xCodEmp IS NOT NULL THEN
          SET MENSAGEM  = of_logistica.fnMensagemExcecao(
             CONCAT('ERRO Conferencia - GEM : ',CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',
             CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao," ",MENSAGEM) );
       ELSE
          SET MENSAGEM  = of_logistica.fnMensagemExcecao(
             CONCAT('ERRO Conferencia : ',MENSAGEM) );
       END IF;
       SELECT MENSAGEM;
       ROLLBACK;
   END;  
   
  
   DROP TEMPORARY TABLE IF EXISTS tbTMPGEM_ACONFIRMAR;
   CREATE TEMPORARY TABLE tbTMPGEM_ACONFIRMAR
      SELECT tbintegraSAP_Doc.DocEntry, tbintegraSAP_Doc.DocTipo, tbintegraSAP_Doc.DocNum, tbintegraSAP_Doc.chave_integracao, 
             tbintegraSAP_Doc.ItemCode, tbintegraSAP_Doc.cod_emp, tbintegraSAP_Doc.cod_fil, tbintegraSAP_Doc.ano_solic, 
             tbintegraSAP_Doc.num_solic, 
             CAST(0 AS SIGNED) flgProcessado
      FROM tbintegraSAP_Doc
      INNER JOIN of_logistica.tbsolic_entradas ON
                 tbintegraSAP_Doc.chave_integracao = tbsolic_entradas.chave_integracao
      WHERE tbintegraSAP_Doc.DocTipo LIKE 'PA%'
        #Habilitar esta linha apenas para testes
        #and tbintegraSAP_Doc.DocEntry = 8 and tbintegraSAP_Doc.DocTipo = 'PA012'
        AND tbintegraSAP_Doc.StatusDoc = 3
        AND tbsolic_entradas.dthr_confirm IS NULL
      ORDER BY cod_emp, cod_fil, ano_solic, num_solic; #      limit 1;
      
      #select * from tbTMPGEM_ACONFIRMAR;
      #leave bloco1;
        
   SET MENSAGEM = "";
   SET RESULTADO = 1;
   IF NOT EXISTS (SELECT 1 FROM tbTMPGEM_ACONFIRMAR) THEN 
      SET MENSAGEM = "NÃO EXISTEM REGISTROS PARA PROCESSAR";
   END IF;
   
   
   WHILE EXISTS (SELECT 1 FROM tbTMPGEM_ACONFIRMAR WHERE flgProcessado = 0) DO
      START TRANSACTION;
   
     
      SELECT DocEntry, DocTipo, DocNum, chave_integracao, cod_emp, cod_fil, ano_solic, num_solic
      INTO xDocEntry, xDocTipo, xDocNum, xChaveIntegracao, xCodEmp, xCodFil, xAnoSolic, xNumSolic
      FROM tbTMPGEM_ACONFIRMAR WHERE flgProcessado = 0
      LIMIT 1;
   
      /***********************************************************************/
      #Buscar Informações da Ordem de Produção
      /***********************************************************************/
      SELECT ItemCode, BatchNumbersCode, DATE_FORMAT(DataFabricacao,'%Y-%m-%d'), DATE_FORMAT(DataValidade,'%Y-%m-%d')
      INTO xItemCode, xLoteFabricacao, xDataFabricacao, xDataValidade
      FROM tbintegraSAP_DocItem
      WHERE tbintegraSAP_DocItem.DocTipo  = xDocTipo
        AND tbintegraSAP_DocItem.DocEntry = xDocEntry
      LIMIT 1;
      
      
      /***********************************************************************/
      #Buscar Numero do início da Sequencia dos pallets por PA/ItemCode
      /***********************************************************************/
      SET xStringEtq = NULL;
      SELECT tbsolic_entradas_acons.num_caixa_barcode AS xStringEtq, DocTipo DocTipoAnt
      INTO xStringEtq, xDocTipoAux
      FROM tbintegraSAP_Doc
      INNER JOIN of_logistica.tbsolic_entradas_acons ON 
                    tbintegraSAP_Doc.cod_emp   = tbsolic_entradas_acons.cod_emp
                AND tbintegraSAP_Doc.cod_fil   = tbsolic_entradas_acons.cod_fil
                AND tbintegraSAP_Doc.ano_solic = tbsolic_entradas_acons.ano_solic
                AND tbintegraSAP_Doc.num_solic = tbsolic_entradas_acons.num_solic
      WHERE tbintegraSAP_Doc.DocTipo LIKE 'PA%'   #= xDocTipo
        AND tbintegraSAP_Doc.DocEntry = xDocEntry
        AND tbintegraSAP_Doc.ItemCode = xItemCode
        AND tbsolic_entradas_acons.num_caixa_barcode IS NOT NULL
      ORDER BY num_lote DESC LIMIT 1;
           
      IF xStringEtq IS NULL THEN
         SET xInicioSequencia = 0;
      ELSE
      
         #OrdemProducao.CodigoProduto.NumeroLote.DataFabricacao.DataValidade.Quantidade.NumeroSequencia
         #Exemplo: 494.1325001.494.0424.0824.40.1
         #Alteração no padrão da Etiqueta em 2024-06-20 (Sequencia Reinicia a cada Item)
         #OrdemProducao.DataFabricacao.DataValidade.Quantidade.CodigoProduto_NumeroLote_NumeroSequencia
         #Exemplo: 494.0424.0824.40.1325001_494_1
         SET xInicioSequencia = CAST(SUBSTRING_INDEX(xStringEtq, '-', -1) AS UNSIGNED);
      END IF;
      
      #Habilitar somente para testes
      #SELECT xDocTipo, xDocTipoAux, xInicioSequencia, xStringEtq, xItemCode;
      #LEAVE bloco1;
      
      /***********************************************************************/
      #Tabela Temporária de Itens da GEM
      /***********************************************************************/
      DROP TEMPORARY TABLE IF EXISTS tbTMPItens;
      CREATE TEMPORARY TABLE tbTMPItens
         SELECT tbsolic_entradas_item.cod_emp, tbsolic_entradas_item.cod_fil, tbsolic_entradas_item.ano_solic, 
                tbsolic_entradas_item.num_solic, tbsolic_entradas_item.num_item, tbsolic_entradas_item.cod_produto,
                tbsolic_entradas_item.qtde_est QtdeEst, tbsolic_entradas_item.qtde_vol QtdeVol, 
                tbsolic_entradas_item.qtde_frac QtdeFrac, tbsolic_entradas_item.pliq_item QtdePeso, 
                tbsolic_entradas_item.fator_conv FatorConv, 
                CAST(0 AS UNSIGNED) flgProcessado
         FROM of_logistica.tbsolic_entradas_item
         INNER JOIN tbintegraSAP_Doc ON
                    tbintegraSAP_Doc.cod_emp   = tbsolic_entradas_item.cod_emp
                AND tbintegraSAP_Doc.cod_fil   = tbsolic_entradas_item.cod_fil
                AND tbintegraSAP_Doc.ano_solic = tbsolic_entradas_item.ano_solic
                AND tbintegraSAP_Doc.num_solic= tbsolic_entradas_item.num_solic
         WHERE chave_integracao = xChaveIntegracao;
         
         
      /***********************************************************************/
      #Tabela Temporária de Aconselhamenro da GEM
      /***********************************************************************/
      DROP TEMPORARY TABLE IF EXISTS tbTMPAcons;
      CREATE TEMPORARY TABLE tbTMPAcons
         SELECT tbsolic_entradas_acons.cod_emp, tbsolic_entradas_acons.cod_fil, tbsolic_entradas_acons.ano_solic, 
                tbsolic_entradas_acons.num_solic, tbsolic_entradas_acons.num_item, 
                tbsolic_entradas_acons.num_lote, tbsolic_entradas_acons.sequencia_lote,
                tbsolic_entradas_acons.qtde_est QtdeEst, tbsolic_entradas_acons.qtde_vol QtdeVol, 
                tbsolic_entradas_acons.qtde_frac QtdeFrac, tbsolic_entradas_acons.qtde_peso QtdePeso,
                CAST(0 AS UNSIGNED) flgProcessado
         FROM of_logistica.tbsolic_entradas_acons
         INNER JOIN tbintegraSAP_Doc ON
                    tbintegraSAP_Doc.cod_emp   = tbsolic_entradas_acons.cod_emp
                AND tbintegraSAP_Doc.cod_fil   = tbsolic_entradas_acons.cod_fil
                AND tbintegraSAP_Doc.ano_solic = tbsolic_entradas_acons.ano_solic
                AND tbintegraSAP_Doc.num_solic = tbsolic_entradas_acons.num_solic
         WHERE chave_integracao = xChaveIntegracao;
         
      #select xInicioSequencia;
      #select * from tbTMPItens;
      #SELECT * FROM tbTMPAcons;
      #leave bloco1;
      #Loop dos Itens
      
      WHILE EXISTS (SELECT 1 FROM tbTMPItens WHERE flgProcessado = 0) DO
         SELECT cod_emp, cod_fil, ano_solic, num_solic, num_item, cod_produto, 
                QtdeEst, QtdeVol, QtdeFrac, QtdePeso, FatorConv
         INTO xCodEmp, xCodFil, xAnoSolic, xNumSolic, xNumItem, xItemCode, 
              xQtdeEstItem, xQtdeVolItem, xQtdeFracItem, xQtdePesoItem, xFatorConv
         FROM tbTMPItens
         WHERE flgProcessado = 0
         LIMIT 1;
         
         #Loop das UA´s
         WHILE EXISTS (SELECT 1 FROM tbTMPAcons WHERE num_item = xNumItem AND flgProcessado = 0) DO
            SELECT num_lote, sequencia_lote, QtdeEst, QtdeVol, QtdeFrac, QtdePeso
            INTO xNumeroUA, xSequenciaUA, xQtdeEstUA, xQtdeVolUA, xQtdeFracUA, xQtdePesoUA
            FROM tbTMPAcons
            WHERE flgProcessado = 0
            LIMIT 1;
            
            #Monta String ETIQUETA PALLET
            SET xInicioSequencia = xInicioSequencia + 1;
            #OrdemProducao.DataFabricacao.DataValidade.Quantidade.CodigoProduto-NumeroLote-NumeroSequencia
            #Exemplo: 494.0424.0824.40.1325001-494-1
            SET xStringEtq =  CONCAT(xDocNum, '.', DATE_FORMAT(xDataFabricacao,'%m%y'), '.', 
                                     DATE_FORMAT(xDataValidade,'%m%y'), '.', CAST(xQtdeEstUA AS UNSIGNED), '.', 
                                     xItemCode, '-', xLoteFabricacao, '-', xInicioSequencia );
            #Habilitar esta linha apenas para testes, checar string etiqueta
            #select xStringEtq ;
            #leave bloco1;
            
            /****************************************************************/
            #CONFERÊNCIA DA UA
            /****************************************************************/		
            CALL of_logistica.PROC_WMS_DESCARGA_ATUALIZAR_CONFERENCIA_ITEM_DESCARGA(	0
                                                                        , CAST(xCodEmp   AS SIGNED)
                                                                        , CAST(xCodFil   AS SIGNED)
                                                                        , CAST(xAnoSolic AS SIGNED)
                                                                        , CAST(xNumSolic AS SIGNED)
                                                                        , 1
                                                                        , CAST(xNumItem  AS SIGNED)
                                                                        , CAST(xNumeroUA AS SIGNED)
                                                                        , NULL
                                                                        , 1
                                                                        , xDataFabricacao
                                                                        , xDataValidade
                                                                        , xLoteFabricacao  #MÁXIMO DE 30! 
                                                                        , xQtdeVolUA
                                                                        , xQtdePesoUA
                                                                        , 0
                                                                        , 0
                                                                        , 999999
                                                                        , 0
                                                                        , NULL
                                                                        , 0
                                                                        , 0
                                                                        , 0
                                                                        , 0
                                                                        , 0
                                                                        , 0
                                                                        , 0
                                                                        , 0
                                                                        , NULL
                                                                        , xStringEtq #MÁXIMO DE 50
                                                                        , _RESULTADO #OUT
                                                                        , _MENSAGEM  #OUT 
                                                                        );
                                                                        
            #select "PROC_WMS_DESCARGA_ATUALIZAR_CONFERENCIA_ITEM_DESCARGA", _RESULTADO, _MENSAGEM;
            #leave BLOCO1;
            IF _RESULTADO = 0 THEN
               #Erro Provocar exceção e parar processamento
               SET RESULTADO = _RESULTADO;
               SET MENSAGEM  = _MENSAGEM;
            END IF;
            
            UPDATE tbTMPAcons
            SET flgProcessado = 1
            WHERE cod_emp   = xCodEmp
              AND cod_fil   = xCodFil
              AND ano_solic = xAnoSolic
              AND num_solic = xNumSolic
              AND num_lote  = xNumeroUA
              AND sequencia_lote = xSequenciaUA;
         END WHILE; 
         
         
         /****************************************************************/
         #FINALIZAR CONFERENCIA ITEM
         /****************************************************************/		
         CALL of_logistica.PROC_WMS_DESCARGA_ATUALIZAR_CONFERENCIA_ITEM_FINAL( 1
                                                               , NULL
                                                               , '999999'
                                                               , xCodEmp
                                                               , xCodFil
                                                               , xAnoSolic
                                                               , xNumSolic
                                                               , xNumItem
                                                               , 1
                                                               , NULL
                                                               , _RESULTADO #OUT
                                                               , _MENSAGEM  #OUT
                                                               ); 
      
         #select "PROC_WMS_DESCARGA_ATUALIZAR_CONFERENCIA_ITEM_FINAL", _RESULTADO, _MENSAGEM;
         #leave BLOCO1;        
         IF _RESULTADO = 0 THEN
            #Erro Provocar exceção e parar processamento
            SET RESULTADO = _RESULTADO;
            SET MENSAGEM  = _MENSAGEM;
         END IF;
         
         
         
         
         /****************************************************************/
         /****************ACONSELHAMENTO DE ENDEREÇO CONFORME PARAMETRIZACAO
         /****************************************************************/		
         IF EXISTS( SELECT 1 
                      FROM of_logistica.tbsolic_entradas
                           INNER JOIN of_logistica.tbwms_estoque_cli  ON tbwms_estoque_cli.cod_emp      = tbsolic_entradas.cod_emp
                                                        AND tbwms_estoque_cli.cod_fil      = tbsolic_entradas.cod_fil
                                                        AND tbwms_estoque_cli.cnpj_cpf_cli = tbsolic_entradas.cnpj_cpf_cli
                                                        AND tbwms_estoque_cli.cod_estoque  = tbsolic_entradas.cod_estoque
                           INNER JOIN of_logistica.tbwms_tipo_oper    ON tbwms_tipo_oper.cod_oper_wms   = tbsolic_entradas.flg_tipo_oper
                     WHERE tbsolic_entradas.cod_emp                      = xCodEmp
                       AND tbsolic_entradas.cod_fil                      = xCodFil
                       AND tbsolic_entradas.ano_solic                    = xAnoSolic
                       AND tbsolic_entradas.num_solic                    = xNumSolic
                       AND tbwms_estoque_cli.flg_aconselhamento_endereco = 1
                       AND tbwms_tipo_oper.flg_aconselhamento_endereco   = 1 
                  ) THEN 
         BEGIN 
              
            #looping por tbsolic_entradas_item
            CALL of_logistica.PROC_WMS_DESCARGA_GERAR_ACONSELHAMENTO_ENDERECO( '999999'
                                                                , CAST(xCodEmp  AS SIGNED)
                                                                , CAST(xCodFil   AS SIGNED)
                                                                , CAST(xAnoSolic    AS SIGNED)
                                                                , CAST(xNumSolic AS SIGNED)
                                                                , CAST(xNumItem     AS SIGNED)
                                                                , _RESULTADO #OUT
                                                                , _MENSAGEM  #OUT 
                                                                );
            #select "PROC_WMS_DESCARGA_GERAR_ACONSELHAMENTO_ENDERECO", _RESULTADO, _MENSAGEM;
            #leave BLOCO1;        
            IF _RESULTADO = 0 THEN
               #Erro Provocar exceção e parar processamento
               SET RESULTADO = _RESULTADO;
               SET MENSAGEM  = _MENSAGEM;
            END IF;
         END; 
         END IF;
         
         
         UPDATE tbTMPItens
         SET flgProcessado = 1
         WHERE cod_emp   = xCodEmp
           AND cod_fil   = xCodFil
           AND ano_solic = xAnoSolic
           AND num_solic = xNumSolic
           AND num_item  = xNumItem;
         
      END WHILE;
      /****************************************************************/
      /****************ATUALIZAR TOPO DA GUIA 
      /****************************************************************/		
      UPDATE of_logistica.tbsolic_entradas 
         SET tbsolic_entradas.final_descarga  = NOW()
           , tbsolic_entradas.status_processo = IF(tbsolic_entradas.status_processo > 7, tbsolic_entradas.status_processo, 7) 
      WHERE tbsolic_entradas.cod_emp   = xCodEmp
        AND tbsolic_entradas.cod_fil   = xCodFil
        AND tbsolic_entradas.ano_solic = xAnoSolic
        AND tbsolic_entradas.num_solic = xNumSolic;
          
          
      /****************************************************************/
      /**************** CONFIRMAÇÃO AUTOMATICA
      /****************************************************************/	   
      CALL of_logistica.PROC_WMS_DESCARGA_ATUALIZAR_CONFIRMACAO_AUTOMATICA( 1
                                                             , xCodEmp
                                                             , xCodFil
                                                             , xAnoSolic
                                                             , xNumSolic
                                                             , '999999'
                                                             ); 
      /****************************************************************/
      /**************** Atualiza STATUS DOCUMENTO NA INTEGRAÇÃO
      /****************************************************************/	   
      CALL PROC_INTEGRA_AtualizarStatusDocEntry('999999', xDocEntry, xDocTipo, xDocNum, 6, _RESULTADO, _MENSAGEM);
      
      
      DROP TEMPORARY TABLE IF EXISTS tbTMPItens;
      DROP TEMPORARY TABLE IF EXISTS tbTMPAcons;
      
      UPDATE tbTMPGEM_ACONFIRMAR
      SET flgProcessado = 1
      WHERE chave_integracao = xChaveIntegracao;
      
      
      IF excecao = 0 THEN
         COMMIT;
         SET RESULTADO = 1;
         IF MENSAGEM = "" THEN
            SET MENSAGEM = CONCAT('Conferencia Concluída com sucesso - GEM : ',CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao);
         ELSE
            SET MENSAGEM = CONCAT(MENSAGEM," | ",CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao);
         END IF;
      ELSE
         ROLLBACK;
         
         SET RESULTADO = 0;
         SET MENSAGEM = CONCAT('ERRO Conferencia - GEM : ',CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao);
         
         #Verificar Log
         #CALL PROC_INTEGRA_EnviarLog('999999',
         #       IF(oChavePedido IN ("PV","OP","TD-S","NS"), 'PROC_INTEGRA_GerarGSMItem', 'PROC_INTEGRA_GerarGEMItem'),
         #         CONCAT('NÃO Inserido/Atualizado ',oChavePedido,oDocEntry,'-',oNumPedido,' | ', xRefGuia, '| Prd:', xItemCode), "200", @M, @R, @M);      
      END IF;
      
      
      
   END WHILE;
   
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_DOCSLIN_CANCELAR.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_DOCSLIN_CANCELAR`$$

CREATE PROCEDURE `PROC_INTEGRA_DOCSLIN_CANCELAR`(
	IN oTipoOper				     VARCHAR(10),
	IN oChaveIntegracao  VARCHAR(100),
	# Parametros de Retorno
	OUT RESULTADO           VARCHAR(5),
	OUT MENSAGEM            VARCHAR(500)
)
BLOCO1:BEGIN
   #@Author David Ruy <2023-07-02>
   #Cancelar Documentos de Entradas e Saídas no SLIN
   #Documento não pode estar em conferencia
   DECLARE xDthrAux   DATETIME DEFAULT NOW();
			DECLARE excecao INT DEFAULT 0;
			DECLARE xCodEmp VARCHAR(03);
			DECLARE xCodFil VARCHAR(03);
			DECLARE xAnoSolic VARCHAR(04);
			DECLARE xNumSolic VARCHAR(10);
			
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       ROLLBACK;
   END;
   START TRANSACTION;
   
   
   IF (oTipoOper = 'E') THEN
      IF EXISTS (SELECT 1 FROM of_logistica.tbsolic_entradas
                 WHERE chave_integracao = oChaveIntegracao AND status_processo <= 5) 
         OR EXISTS (SELECT 1 FROM tbintegraSAP_Doc WHERE chave_integracao = oChaveIntegracao AND StatusDoc <= 1) THEN
          
          UPDATE of_logistica.tbsolic_entradas
          SET status_processo = 11, status_solic = 9,
              dthr_cancelamento = xDthrAux, 
              usu_cancelamento = "999999",
              observ_conf01 = "Cancelamento via Monitor de Integração (1)"
          WHERE chave_integracao = oChaveIntegracao;
          
          DELETE FROM of_logistica.tbsolic_entradas_acons
          WHERE EXISTS (SELECT 1 FROM of_logistica.tbsolic_entradas 
                        WHERE tbsolic_entradas.cod_emp   = tbsolic_entradas_acons.cod_emp
                          AND tbsolic_entradas.cod_fil   = tbsolic_entradas_acons.cod_fil
                          AND tbsolic_entradas.ano_solic = tbsolic_entradas_acons.ano_solic
                          AND tbsolic_entradas.num_solic = tbsolic_entradas_acons.num_solic
                          AND chave_integracao = oChaveIntegracao);
          
          UPDATE tbintegraSAP_Doc
          SET StatusDoc = 9, 
              StatusSLIN = 9,
              dthr_cancel = xDthrAux,
              Observacoes = CONCAT(IFNULL(Observacoes,''),' Cancelamento via monitor de integração(1)')
          WHERE chave_integracao = oChaveIntegracao;
          
          SET RESULTADO = 1;
          SET MENSAGEM = "CANCELAMENTO REALIZADO COM SUCESSO";
      ELSE
          SET RESULTADO = 0;
          SET MENSAGEM = "GEM NÃO LOCALIZADA OU STATUS NÃO PERMITIDO PARA ESSA OPERAÇÃO - Não pode estar em conferencia";
      END IF;
   END IF;
   
   IF (oTipoOper = 'S') THEN
      IF EXISTS (SELECT 1 FROM of_logistica.tbsolic_saidas
                 WHERE chave_integracao = oChaveIntegracao AND status_processo <= 1) 
         OR EXISTS (SELECT 1 FROM tbintegraSAP_Doc WHERE chave_integracao = oChaveIntegracao AND StatusDoc <= 1) THEN
                
         SET xCodEmp = NULL;
         SET xCodFil = NULL;
         SET xAnoSolic = NULL;
         SET xNumSolic = NULL;
         #
         SELECT cod_emp, cod_fil, ano_solic, num_solic 
         INTO xCodEmp, xCodFil, xAnoSolic, xNumSolic
         FROM of_logistica.tbsolic_saidas
         WHERE chave_integracao = oChaveIntegracao;
         
         CALL of_logistica.PROC_WMS_SAIDA_CANCELAR_GSM_INTEGRACAO(xCodEmp, xCodFil, xAnoSolic, xNumSolic, @R, @M);
          
          #Bloco Subistituido pelo chamada da procedure acima
          /*
          UPDATE of_logistica.tbsolic_saidas
          SET status_processo = 11, status_solic = 9,
              dthr_cancelamento = xDthrAux, 
              usu_cancelamento = "999999",
              observ_conf01 = "Cancelamento via Monitor de Integração (1)"
          WHERE chave_integracao = oChaveIntegracao;
          
          DELETE FROM of_logistica.tbsolic_saidas_acons
          WHERE EXISTS (SELECT 1 FROM of_logistica.tbsolic_saidas 
                        WHERE tbsolic_saidas.cod_emp   = tbsolic_saidas_acons.cod_emp
                          AND tbsolic_saidas.cod_fil   = tbsolic_saidas_acons.cod_fil
                          AND tbsolic_saidas.ano_solic = tbsolic_saidas_acons.ano_solic
                          AND tbsolic_saidas.num_solic = tbsolic_saidas_acons.num_solic
                          AND chave_integracao = oChaveIntegracao);

          UPDATE of_logistica.tbprog_entregas
          SET tbprog_entregas.status_entre = 9,
              tbprog_entregas.status_baixa = 4,
              tbprog_entregas.ano_viagem = NULL,
              tbprog_entregas.num_viagem = NULL,
              tbprog_entregas.usu_alt = '999999',
              tbprog_entregas.dthr_alt = xDthrAux,
              tbprog_entregas.observ_baixa = "Cancelamento via Monitor de Integração (1)"
          WHERE chave_integracao = oChaveIntegracao;

          */
          
         IF (@M = "OK" OR xCodEmp IS NULL) THEN
            UPDATE tbintegraSAP_Doc
            SET StatusDoc = 9, 
                StatusSLIN = 9,
                dthr_cancel = xDthrAux,
                Observacoes = CONCAT(IFNULL(Observacoes,''),' Cancelamento via monitor de integração(1)')
            WHERE chave_integracao = oChaveIntegracao;
            
            
            SET RESULTADO = 1;
            SET MENSAGEM = "CANCELAMENTO REALIZADO COM SUCESSO";
         ELSE
            SET RESULTADO = 0;
            SET MENSAGEM = @M;
         END IF;
       
      ELSE
          SET RESULTADO = 0;
          SET MENSAGEM = "GSM NÃO LOCALIZADA OU STATUS NÃO PERMITIDO PARA ESSA OPERAÇÃO - Não pode estar aconselhada";
      END IF;
   END IF;
   IF (excecao = 0) THEN
      SET RESULTADO = "1";
      COMMIT;
   END IF;
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_DOC_EXCLUIR_GERAL.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_DOC_EXCLUIR_GERAL`$$

CREATE PROCEDURE `PROC_INTEGRA_DOC_EXCLUIR_GERAL`(
	IN oTipoOper				     VARCHAR(10),
	IN oChaveIntegracao  VARCHAR(100),
	# Parametros de Retorno
	OUT RESULTADO           VARCHAR(5),
	OUT MENSAGEM            VARCHAR(500)
)
BLOCO1:BEGIN
   #@Author David Ruy <2023-07-02>
   #Cancelar Documentos de Entradas e Saídas no SLIN
   #Documento não pode estar em conferencia
   DECLARE xDthrAux   DATETIME DEFAULT NOW();
			DECLARE excecao INT DEFAULT 0;
			DECLARE xCodEmp VARCHAR(03);
			DECLARE xCodFil VARCHAR(03);
			DECLARE xAnoSolic VARCHAR(04);
			DECLARE xNumSolic VARCHAR(10);
			DECLARE xStatusProcesso VARCHAR(10);
			DECLARE xProcessar INT DEFAULT 0;
			
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       ROLLBACK;
   END;
   
   
   START TRANSACTION;
   
   
   IF (oTipoOper = 'E') THEN
      SET xCodEmp = NULL;
      SET xCodFil = NULL;
      SET xAnoSolic = NULL;
      SET xNumSolic = NULL;
      SET xStatusProcesso = NULL;
      #
      SELECT cod_emp, cod_fil, ano_solic, num_solic, status_processo
      INTO xCodEmp, xCodFil, xAnoSolic, xNumSolic, xStatusProcesso
      FROM of_logistica.tbsolic_entradas
      WHERE chave_integracao = oChaveIntegracao;
      
      IF xCodEmp IS NOT NULL THEN
      
         IF IFNULL(xStatusProcesso,0) <= 5 THEN #OR IFNULL(xStatusProcesso,0) = 11 THEN
         
            DELETE FROM of_logistica.tbsolic_entradas
            WHERE chave_integracao = oChaveIntegracao;
            
            DELETE FROM tbintegraSAP_Doc
            WHERE chave_integracao = oChaveIntegracao;                 
            SET RESULTADO = 1;
            SET MENSAGEM = "EXCLUSÃO REALIZADA COM SUCESSO";
             
            #Gravar LOG
            CALL PROC_INTEGRA_EnviarLog('999999', CONCAT('Monitor_EXCLUSÃO ',oChaveIntegracao), CONCAT(@R, " ", @M),  @R, 
                      CONCAT(@M, IFNULL(CONCAT("GEM=>",xCodEmp,'/',xCodFil,'-',xAnoSolic,'.',xNumSolic),"")), @R, @M);         
         ELSE
           SET RESULTADO = 0;
           SET MENSAGEM = "STATUS NÃO PERMITIDO PARA ESSA OPERAÇÃO - Não pode estar em conferencia";
         END IF;
                 
      ELSE
         DELETE FROM tbintegraSAP_Doc
         WHERE chave_integracao = oChaveIntegracao;                 
          
         SET RESULTADO = 1;
         SET MENSAGEM = "GEM NÃO LOCALIZADA - Documento excluído apenas da integração";
         #Gravar LOG
         CALL PROC_INTEGRA_EnviarLog('999999', CONCAT('Monitor_EXCLUSÃO ',oChaveIntegracao), CONCAT(@R, " ", @M),  @R, 
                   CONCAT(@M, IFNULL(CONCAT("GEM=>",xCodEmp,'/',xCodFil,'-',xAnoSolic,'.',xNumSolic),"")), @R, @M);         
     
      END IF;
   END IF;
   
   IF (oTipoOper = 'S') THEN
   
   
      SET xCodEmp = NULL;
      SET xCodFil = NULL;
      SET xAnoSolic = NULL;
      SET xNumSolic = NULL;
      SET xStatusProcesso = NULL;
      #
      SELECT cod_emp, cod_fil, ano_solic, num_solic, status_processo
      INTO xCodEmp, xCodFil, xAnoSolic, xNumSolic, xStatusProcesso
      FROM of_logistica.tbsolic_saidas
      WHERE chave_integracao = oChaveIntegracao;
      
      IF xCodEmp IS NOT NULL THEN
      
         IF IFNULL(xStatusProcesso,0) <= 1 THEN #or IFNULL(xStatusProcesso,0) = 11 THEN   
         
            DELETE FROM of_logistica.tbsolic_saidas
            WHERE chave_integracao = oChaveIntegracao;
            
            DELETE FROM of_logistica.tbprog_entregas
            WHERE chave_integracao = oChaveIntegracao;
            
            DELETE FROM of_logistica.tbnf_clientes
            WHERE chave_integracao = oChaveIntegracao;
            
            DELETE FROM tbintegraSAP_DocPicking
            WHERE EXISTS (SELECT 1 FROM tbintegraSAP_Doc
                          WHERE tbintegraSAP_DocPicking.DocTipo = tbintegraSAP_Doc.DocTipo
                           AND tbintegraSAP_DocPicking.DocEntry = tbintegraSAP_Doc.DocEntry
                           AND chave_integracao = oChaveIntegracao);   
                                         
            DELETE FROM tbintegraSAP_Doc
            WHERE chave_integracao = oChaveIntegracao;                 
            
            SET RESULTADO = 1;
            SET MENSAGEM = "EXCLUSÃO REALIZADA COM SUCESSO";
            #Gravar LOG
            CALL PROC_INTEGRA_EnviarLog('999999', CONCAT('Monitor_EXCLUSÃO ',oChaveIntegracao), CONCAT(RESULTADO, " ", MENSAGEM),  "OK", 
                      CONCAT(MENSAGEM, IFNULL(CONCAT(" GSM=>",xCodEmp,'/',xCodFil,'-',xAnoSolic,'.',xNumSolic),"")), RESULTADO, MENSAGEM);         
         ELSE
            SET RESULTADO = 0;
            SET MENSAGEM = "STATUS NÃO PERMITIDO PARA ESSA OPERAÇÃO - Não pode estar aconselhada";
         END IF;
         
      ELSE
         DELETE FROM tbintegraSAP_Doc
         WHERE chave_integracao = oChaveIntegracao;                 
          
         SET RESULTADO = 1;
         SET MENSAGEM = "GSM NÃO LOCALIZADA - Documento excluído apenas da integração";

         #Gravar LOG
         CALL PROC_INTEGRA_EnviarLog('999999', CONCAT('Monitor_EXCLUSÃO ',oChaveIntegracao), CONCAT(RESULTADO, " ", MENSAGEM),  "OK", 
                   CONCAT(MENSAGEM, IFNULL(CONCAT(" GEM=>",xCodEmp,'/',xCodFil,'-',xAnoSolic,'.',xNumSolic),"")), RESULTADO, MENSAGEM);         
      
      END IF;
      
   END IF;
   
   IF (excecao = 0) THEN
      SET RESULTADO = "1";
      COMMIT;
   END IF;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_EnviarDocEntry.sql*/

DELIMITER $$

#Para BRW e Gemmini _20240813 para as demais, tirar oU_BDO_NKIT e oDocEntryRef, oDocNumRef, oDocTotal
DROP PROCEDURE IF EXISTS `PROC_INTEGRA_EnviarDocEntry`$$

CREATE PROCEDURE `PROC_INTEGRA_EnviarDocEntry`(
	IN oCodUsuario	      VARCHAR(10),
	IN oDocEntry	      INT,
	IN oDocTipo	         VARCHAR(10), #'PV / NF / OP / NE Nota Fiscal entrada / DV Devolução de Vendas / TD-<E>/<S> (Transferencia Entre Depósitos)
	IN oDocNum	         VARCHAR(30),
	IN oBPLId           VARCHAR(30),
	IN oIdSales         VARCHAR(30),
	IN oIdCommerce      VARCHAR(30),
	IN oIdRplOrder      VARCHAR(30),
	IN oU_BDO_NKIT      VARCHAR(50),
	
	IN oTipoProducao     VARCHAR(20),
	IN oItemCode	      VARCHAR(30),
	IN oCardCode	      VARCHAR(15),
	IN oCardName	      VARCHAR(100),
	IN oNumCNPJ          VARCHAR(20), 
	IN oNumCPF           VARCHAR(20), 
	IN oSerial           INT,
	IN oAddrTypeS        VARCHAR(20),
	IN oStreetS          VARCHAR(200),
	IN oStreetNoS        VARCHAR(30),
	IN oBuildingS        VARCHAR(100),
	IN oBlockS           VARCHAR(100),
	IN oCityS            VARCHAR(100),
	IN oZipCodeS         VARCHAR(10),
	IN oStateS           VARCHAR(02),
	IN oCountryS         VARCHAR(50),
	
	IN oNomeVendedor     VARCHAR(60),
	IN oCFOP             VARCHAR(10),
	#IN oMainUsage        VARCHAR(30),
	IN oTipoFrete        VARCHAR(5),
	IN oNomeTransp       VARCHAR(150),
	IN oCnpjTransp       VARCHAR(50),
	IN oTransportationCode VARCHAR(10),
	
	IN oRoute             VARCHAR(50),
	IN oStartTime1        VARCHAR(20),
	IN oEndTime1          VARCHAR(20),
	IN oStartTime2        VARCHAR(20),
	IN oEndTime2          VARCHAR(20),
	IN oEnd_Entrega	      VARCHAR(200),
			
	IN oDocDate	         DATETIME,	
	IN oDueDate	         DATETIME,
	IN oStatusDoc	       VARCHAR(10),	# Verificar STATUS EXCLUSÃO
	IN oPlannedQty	      DOUBLE(20,6),
	IN oWhareHouse	      VARCHAR(30),
	IN oWhareHouseTransf VARCHAR(30),
	IN oStatusEnum	      INT,
	IN oid_request       INT,           #Receber idPicking quando DocObjVendas = 'P'
	IN oObservacoes      VARCHAR(2000),
	IN oDocEntryRef      VARCHAR(30),
	IN oDocNumRef        VARCHAR(30),
	IN oDocTotal         DECIMAL(20,6),
	IN oQtdeOriItens     INT,  
	
	# Parametros de Retorno
	OUT RESULTADO         INT,
	OUT MENSAGEM          VARCHAR(500)
)
BLOCO1:BEGIN
   /******************************************************************************
   @Author <David Ruy (OVERFLASH)>
   @Creation <2019-07-11>
   @Description <Esta rotina insere e atualiza a tabela tbintegraSAP_Doc que faz o controle
   da integração SAP / SLIN. Considera os status abaixo :
      StatusDoc 
         1 = Importado SAP
         2 = Integrado SLIN
         3 = Integrado SLIN (alteração)
         4 = Iniciado SLIN
         5 = Finalizado SLIN
         6 = Retornado SAP
         7 = Processo de Atualização SAP (Divergencias dentro da tolerancia)
         9 = Cancelado SAP
         10 = OP Externa, processar (Pedido de Transferencia irá gerar o processo de Saída)
   >
   @Reviser David Ruy <2019-11-20> Ajuste xStatusAnt para atualização do registro | SET xStatusAux = IF(xStatusAnt="1","2",xStatusAnt);
   @Reviser David Ruy <2021-08-24> Ajustes oDocTipo = 'TF" : Tranferencia entre filiais
   @Reviser David Ruy <2021-08-30> Ajustes oTipoProducao => PEX/PEC não gerar picking (STATUS=10)
   @Reviser David Ruy <2021-09-22> Ajustes Elinox : Nunca realizar leitura de OP´ pois TODAS serão integradas via transferencia de estoque
   @Reviser David Ruy <2021-09-22> Ajustes Entrada Produção Parcelada PA000, PA001, PA002,....
   @Reviser David Ruy <2022-01-04> Ajustes TD-S/TD-E CardCode e CardName, enviar null quando vier vazio
   @Reviser David Ruy <2022-03-18> Ajustes NumCPF e NumCNPJ
   @Reviser David Ruy <2022-09-24> Novos campos : oBPLId, oIdSales, oIdCommerce, oIdRplOrder
   @Reviser David Ruy <2022-12-01> Status = 0 na inclusão para evitar processamento parcial de itens na PROC_INTEGRA_AtualizarSLIN
   @Reviser David Ruy <2023-06-29> Busca o ultimo registro "PA" em aberto
   @Reviser David Ruy <2023-06-29> No retorno MENSAGEM = xchave_integracao
   @Reviser David Ruy <2023-10-26> Aumento campo oNomeVendedor
   @Reviser David Ruy <2024-06-18> Quando for PA, analisa Serial = DocNum => checa status, caso contrário, checa Serial
   @Reviser David Ruy <2024-06-24> Gravar Registro vindo da leitura de PickList DocNum = concat(DocNum,'-',Sequencia)   
   @Reviser David Ruy <2024-08-13> Novos campos (BRW) oDocEntryRef, oDocNumRef, oDocTotal
   @Reviser David Ruy <2024-08-19> Alteração Parametro oObservacoes varchar(500) -> varchar(2000) 
   @Reviser David Ruy <2025-01-27> oU_BDO_NKIT
   @Reviser David Ruy <2025-11-27> Ajuste para considerar (tbintegraSAP_empresas.CardCode_For, tbintegraSAP_empresas.CardCode_Cli) quando parametro CardCode estiver vazio 
   @Reviser David Ruy <2026-07-24> Novo campo oQtdeOriItens para não liberar o processo com qtde de itens quebrada
   *******************************************************************************/
   DECLARE xIncAlt 	      VARCHAR(01)	DEFAULT 'I';
   DECLARE xStatusAnt      VARCHAR(02);
   DECLARE xStatusAux      VARCHAR(02);
   DECLARE xCodErro	      INT DEFAULT 0;
   DECLARE excecao 	      INT DEFAULT 0;
   DECLARE xflgGeraMovtoTr INT DEFAULT 1;
   DECLARE xcnpj_cpf_cli   VARCHAR(20);
   DECLARE xraz_social     VARCHAR(100);
   DECLARE xOrigem         VARCHAR(30);
   DECLARE xDestino        VARCHAR(20);
   DECLARE xCondicao       VARCHAR(100) DEFAULT ""; 
   DECLARE xTipoDocSLIN    VARCHAR(01);
   DECLARE xStrAux         VARCHAR(10) DEFAULT NULL;
   DECLARE xIntAux         INT DEFAULT 0;
   DECLARE xchave_integracao VARCHAR(50);
   DECLARE xDocNum         VARCHAR(30);
   DECLARE xidPicking      INT(11);
   DECLARE xObjDocVendas   VARCHAR(01);
   DECLARE xSequenciaPV    INT(11);
   
   
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(
          CONCAT('ERRO Gerar DocEntry ',oDocTipo,"",oDocNum,"|",oDocEntry," =>",xDocNum," ",MENSAGEM) );
       SELECT MENSAGEM;
       ROLLBACK;
   END;  
   
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   SET xStatusAnt = NULL;
   SET oCnpjTransp = of_logistica.fnTirarCaracteresEspeciais(oCnpjTransp);
   SET oNomeTransp = SUBSTRING(oNomeTransp,1,50);
   
   
   
   
   -- Buscar Parametros
   SELECT cnpj_cpf_cli, raz_social #, ObjDocVendas
   INTO xcnpj_cpf_cli, xraz_social #, xObjDocVendas
   FROM tbintegraSAP_parametros
   INNER JOIN of_logistica.tbfiliais ON
              tbfiliais.num_cnpj = tbintegraSAP_parametros.cnpj_cpf_cli
   LIMIT 1;
   
   
   
   -- Verificar Status Inicial do Documento
   SELECT StatusDoc INTO xStatusAnt
   FROM tbintegraSAP_Doc
   WHERE DocEntry = oDocEntry 
     AND DocTipo = oDocTipo
     #AND IF(xObjDocVendas='P', idPicking = oid_request, TRUE);
     AND IF(oid_request IS NULL, TRUE, idPicking = oid_request);
     
   SET xIncAlt = 'A';
   #Se oStatusDoc (Status Parametro) = 1 => Cancelado
   #Senão mantem o Status do Documento
   IF oStatusDoc = '1' THEN
      SET xStatusAux = '9';
   ELSE 
      IF xStatusAnt IS NULL THEN
         #SET xStatusAux = '1';
         SET xStatusAux = NULL;
      ELSE
         SET xStatusAux = IF(xStatusAnt="1","2",xStatusAnt);
      END IF;
   END IF;
   
   
   SELECT cnpj_cpf_cli, raz_social 
   INTO xcnpj_cpf_cli, xraz_social
   FROM tbintegraSAP_parametros
   INNER JOIN of_logistica.tbfiliais ON
              tbfiliais.num_cnpj = tbintegraSAP_parametros.cnpj_cpf_cli
   LIMIT 1;
   
   
   SET @cod_deposito = NULL; SET @id_empresa = NULL; SET @cod_emp_slin = NULL; SET @cod_fil_slin = NULL;
   IF oDocTipo = "TD-E" THEN #AND IFNULL(oCardCode,"") = "" THEN
      SET xOrigem  = oWhareHouseTransf;
      SET xDestino = oWhareHouse;
      SELECT TB0.cod_deposito, TB0.id_empresa, TB1.cod_emp_slin, TB1.cod_fil_slin, 
         #IFNULL(oCardCode,IFNULL(TB1.cnpj_empresa,xcnpj_cpf_cli)),
         #IFNULL(oCardName,IFNULL(TB2.raz_social,xraz_social))
         IFNULL(IF(oCardCode='',NULL,oCardCode),TB1.CardCode_For),   #IF(oCardCode='',NULL,oCardCode),
         IFNULL(IF(oCardCode='',NULL,oCardName),TB1.raz_social)      #IF(oCardName='',NULL,oCardName)         
      INTO @cod_deposito, @id_empresa, @cod_emp_slin, @cod_fil_slin, oCardCode, oCardName
      FROM tbintegraSAP_Depositos TB0
      LEFT JOIN tbintegraSAP_empresas TB1 ON 
                TB1.id_integracao = TB0.id_empresa
      LEFT JOIN of_logistica.tbfiliais TB2 ON 
                TB2.cod_empresa = TB1.cod_emp_slin
            AND TB2.cod_filial  = TB1.cod_fil_slin
      WHERE TB0.cod_deposito = oWhareHouse;
      
      SET xflgGeraMovtoTr = @cod_emp_slin IS NOT NULL;
   END IF;
   IF oDocTipo = "TD-S" THEN #AND IFNULL(oCardCode,"") = "" THEN
      SET xOrigem  = oWhareHouse;
      SET xDestino = oWhareHouseTransf;
      SELECT TB0.cod_deposito, TB0.id_empresa, TB1.cod_emp_slin, TB1.cod_fil_slin, 
         #IFNULL(oCardCode,IFNULL(TB1.cnpj_empresa,xcnpj_cpf_cli)),
         #IFNULL(oCardName,IFNULL(TB2.raz_social,xraz_social))
         IFNULL(IF(oCardCode='',NULL,oCardCode),TB1.CardCode_Cli),   #IF(oCardCode='',NULL,oCardCode),
         IFNULL(IF(oCardCode='',NULL,oCardName),TB1.raz_social)      #IF(oCardName='',NULL,oCardName)         
      INTO @cod_deposito, @id_empresa, @cod_emp_slin, @cod_fil_slin, oCardCode, oCardName
      FROM tbintegraSAP_Depositos TB0
      LEFT JOIN tbintegraSAP_empresas TB1 ON 
                TB1.id_integracao = TB0.id_empresa
      LEFT JOIN of_logistica.tbfiliais TB2 ON 
                TB2.cod_empresa = TB1.cod_emp_slin
            AND TB2.cod_filial  = TB1.cod_fil_slin
      WHERE TB0.cod_deposito = oWhareHouse;
      SET xflgGeraMovtoTr = @cod_emp_slin IS NOT NULL;
   END IF;
   
   IF oDocTipo = "PA" THEN
      #Tratativa para Ordem de Produção : Recebimento Parcelado
      #Gerar PA000, PA001, PA002, .....
      SET xStrAux = NULL;
      
      
      #Busca o ultimo registro "PA" em aberto
      SELECT MAX(DocTipo) INTO xStrAux 
      FROM tbintegraSAP_Doc
      WHERE SUBSTRING(DocTipo,1,2)  = "PA"
        AND DocEntry = oDocEntry
        #AND PlannedQty = oPlannedQty;
        #AND StatusDoc < 6;
        #Se Serial = DocNum (Leitura da OP), se não, Leitura da Entrada de Produção
        AND IF(oSerial = oDocNum, StatusDoc < 6, SERIAL = oSerial);
        
        
      #Inclusão
      IF IFNULL(xStrAux,'') = '' THEN 
--          NOT EXISTS (SELECT DocTipo
--                      FROM tbintegraSAP_Doc
--                      WHERE SUBSTRING(DocTipo,1,2)  = "PA"
--                        AND DocEntry = oDocEntry
--                        AND PlannedQty = oPlannedQty) THEN
                       
         SELECT MAX(DocTipo) INTO xStrAux
         FROM tbintegraSAP_Doc
         WHERE SUBSTRING(DocTipo,1,2)  = "PA"
           AND DocEntry = oDocEntry;
           
         IF IFNULL(xStrAux,'') = '' THEN 
            SET xStrAux = 'PA000';
         ELSE 
            SET xStrAux = CONCAT("PA", LPAD(CONVERT(CONVERT(SUBSTR(xStrAux,3,3),SIGNED)+1,CHAR),3,'0'));
         END IF;
         
      ELSE
         #Alteração
         SET xStatusAux = '0'; #NULL;
      END IF;
      SET oDocTipo = xStrAux;
                    
   END IF;
   
   
   
   
   
   #@Reviser David Ruy <2024-06-24> Pedido de Venda Parcial via leitura PickList (DocNum-Sequencia)
   IF oDocTipo = 'PV' AND oid_request IS NOT NULL THEN # and xObjDocVendas = 'P' THEN
      SET xidPicking = oid_request;
      SET xDocNum = NULL;
      IF EXISTS (SELECT 1 FROM tbintegraSAP_Doc 
                 WHERE DocEntry = oDocEntry AND DocTipo = oDocTipo AND idPicking = xidPicking) THEN
         SELECT DocNum FROM xDocNum tbintegraSAP_Doc 
         WHERE DocEntry = oDocEntry AND DocTipo = oDocTipo AND idPicking = xidPicking;
      
        
      ELSEIF EXISTS (SELECT 1 FROM tbintegraSAP_Doc 
                     WHERE DocEntry = oDocEntry AND DocTipo = oDocTipo AND StatusDoc = 3) THEN
                     
         SELECT MAX(DocNum) DocNum INTO xDocNum
         FROM tbintegraSAP_Doc 
         WHERE DocEntry = oDocEntry AND DocTipo = oDocTipo
           AND StatusDoc = 3;
         
         -- Cancelar o PV e gerar um novo registro : PROC_Integra_AtuStatusDocEntry
         -- Cancelar GSM (gerar logs de alteração) : PROC_Integra_CancelarGSM
         IF xDocNum IS NULL THEN
            SET xSequenciaPV = 1;
         ELSE
            IF POSITION('.' IN xDocNum) > 0 THEN
               SET xSequenciaPV = CAST(SUBSTRING_INDEX(xDocNum,'.',-1) AS UNSIGNED)+1;
            ELSE
               SET xSequenciaPV = 1;
            END IF;
         END IF;
         
      ELSE
         SELECT MAX(DocNum) DocNum INTO xDocNum
         FROM tbintegraSAP_Doc 
         WHERE DocEntry = oDocEntry AND DocTipo = oDocTipo;
				  
         IF xDocNum IS NULL THEN
            SET xSequenciaPV = 1;
         ELSE
            IF POSITION('.' IN xDocNum) > 0 THEN
               SET xSequenciaPV = CAST(SUBSTRING_INDEX(xDocNum,'.',-1) AS UNSIGNED)+1;
            ELSE
               SET xSequenciaPV = 1;
            END IF;
         END IF;
         
				  END IF;
				  
				  SET xDocNum = CONCAT(oDocNum,'.',xSequenciaPV);        
				  SET oDocNum = xDocNum;  
   END IF;
      
   SET xchave_integracao = CONCAT(oDocTipo, oDocNum,'-',oDocEntry);
   IF IFNULL(xStatusAux,'1') = '1' AND xflgGeraMovtoTr = 1 THEN
      #Inclusão
      INSERT INTO tbintegraSAP_Doc
         (DocEntry, DocTipo, DocNum, TipoProducao, ItemCode, DocDate, DueDate, 
          CardCode, CardName, NumCNPJ, NumCPF, SERIAL,
          BPLId, IdSales, IdCommerce, U_RSD_RplOrder, U_BDO_NKIT,
          AddrTypeS, StreetS, StreetNoS, BuildingS, BlockS, CityS, ZipCodeS, StateS, CountryS, 
          NomeVendedor, CFOP, TipoFrete, NomeTransp, CnpjTransp,	TransportationCode,
          Route, StartTime1, EndTime1, StartTime2, EndTime2, End_Entrega,
          StatusDoc, PlannedQty,
          DocEntryRef, DocNumRef, DocTotal, QtdeOriItens,
          WhareHouse, WhareHouseTransf, StatusEnum, id_request, Observacoes, 
          dthr_inc, usu_inc, idPicking,chave_integracao)
      VALUES (oDocEntry, oDocTipo, oDocNum, oTipoProducao, oItemCode, oDocDate, oDueDate, 
          oCardCode, oCardName, oNumCNPJ, oNumCPF, oSerial,
          oBPLId, oIdSales, oIdCommerce, oIdRplOrder, oU_BDO_NKIT,
          oAddrTypeS, oStreetS, oStreetNoS, oBuildingS, oBlockS, oCityS, oZipCodeS, oStateS, oCountryS, 
          oNomeVendedor, oCFOP, oTipoFrete, oNomeTransp, oCnpjTransp, oTransportationCode,
          oRoute, oStartTime1, oEndTime1, oStartTime2, oEndTime2, oEnd_Entrega,          
          xStatusAux, oPlannedQty, 
          oDocEntryRef, oDocNumRef, oDocTotal, oQtdeOriItens, 
          oWhareHouse, oWhareHouseTransf, oStatusEnum, oid_request, oObservacoes, NOW(), oCodUsuario,
          #Temporariamente, até que XNET resolva a criação de picking para TD-S
          #IF(oDocTipo='TD-S',0,NULL),
          #Alterado pois o picking é gerado pelo serviço OVERFLASH
          xidPicking,
          xchave_integracao ); 
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT("Registro inserido com sucesso - chave_integracao:",xchave_integracao);
      
   ELSEIF xStatusAux = '9' AND (xStatusAux <> xStatusAnt) THEN
      #Cancelamento / Preserva a hora do cancelamento
      CALL PROC_INTEGRA_AtualizarStatusDocEntry('999999', oDocEntry, oDocTipo, oDocNum, oStatusDoc, @R, @M);
      SET RESULTADO = 9;
      SET MENSAGEM = CONCAT("Registro CANCELADO com sucesso - chave_integracao:",xchave_integracao);
      
   #ELSEIF xStatusAnt < "4" THEN
   ELSEIF xStatusAnt IS NULL THEN
      #Se Status Anterior : Não iniciado SLIN, então atualiza
      #@Reviser David Ruy <2020/02/28> Nunca atualizar a integração pois já 
      #                                existem endpoints de atualização / cancelamento
      UPDATE tbintegraSAP_Doc SET 
         DocNum     = oDocNum 
         ,TipoProducao = oTipoProducao
         ,ItemCode  = oItemCode 
         ,DocDate   = oDocDate
         ,DueDate   = oDueDate 
         ,CardCode  = oCardCode 
         ,CardName  = oCardName 
         ,NumCNPJ   = oNumCNPJ
         ,NumCPF    = oNumCPF
         ,SERIAL    	= oSerial
         
         ,BPLId = oBPLId
         ,IdSales = oIdSales
         ,IdCommerce = oIdCommerce
         ,U_RSD_RplOrder = oIdRplOrder         
         ,U_BDO_NKIT = oU_BDO_NKIT
         
         ,AddrTypeS 	= oAddrTypeS
         ,StreetS   	= oStreetS
         ,StreetNoS 	= oStreetNoS
         ,BuildingS 	= oBuildingS
         ,BlockS    	= oBlockS
         ,CityS     	= oCityS
         ,ZipCodeS  	= oZipCodeS 
         ,StateS    	= oStateS 
         ,CountryS  	= oCountryS 
         ,NomeVendedor  = oNomeVendedor
         ,CFOP          = oCFOP
         ,TipoFrete     = oTipoFrete
         ,NomeTransp    = oNomeTransp
         ,CnpjTransp    = oCnpjTransp    
         ,TransportationCode = oTransportationCode
              
         ,Route       	= oRoute 
         ,StartTime1  	= oStartTime1
         ,EndTime1    	= oEndTime1
         ,StartTime2  	= oStartTime2
         ,EndTime2    	= oEndTime2
         ,End_Entrega 	= oEnd_Entrega
         
         #,StatusDoc = oStatusDoc 
         ,PlannedQty 	= oPlannedQty
         
         ,DocEntryRef = oDocEntryRef
         ,DocNumRef   = oDocNumRef
         ,DocTotal    = oDocTotal
         
         ,WhareHouse 	= oWhareHouse
         ,WhareHouseTransf = oWhareHouseTransf
         ,StatusEnum 	= oStatusEnum
         ,id_request 	= oid_request
         ,Observacoes   = IF(LENGTH(IFNULL(oObservacoes,''))=0,NULL, oObservacoes)
         ,dthr_alt      = NOW()
         ,usu_alt       = oCodUsuario

      WHERE DocEntry = oDocEntry 
        AND DocTipo = oDocTipo
        AND IF(xidPicking IS NULL, TRUE, idPicking = xidPicking);
        
      SET RESULTADO = xStatusAux;
      SET MENSAGEM = CONCAT("Registro atualizado com sucesso  - chave_integracao:",xchave_integracao);
      
   ELSE
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT("Registro não atualizado - Status Pedido => Ant=",xStatusAnt," <> Novo=",xStatusAux," chave_integracao:",xchave_integracao);		
   END IF;
   
   
   #Excluir do processamento as OP´s com TipoProducao Externa
   #Elinox : Nunca realizar leitura de OP´ pois TODAS serão integradas via transferencia de estoque
   #Demais clientes : Se o flag na tbintegraSAP_TipoDoc = E/S, gera SE OP Externa (PEX,PEC)
   SELECT Condicao, TipoDocSLIN INTO xCondicao, xTipoDocSLIN 
   FROM tbintegraSAP_TipoDoc
   WHERE DocTipo = oDocTipo LIMIT 1;
   
   
   #Monta script UPDATE
   SET @SQL = CONCAT("UPDATE tbintegraSAP_Doc ",
                     "SET tbintegraSAP_Doc.StatusAnt = tbintegraSAP_Doc.StatusDoc, ",
                     "    tbintegraSAP_Doc.StatusDoc = 10 ",
                     "WHERE tbintegraSAP_Doc.DocEntry = ",oDocEntry," ",
                     "  AND tbintegraSAP_Doc.DocTipo  = '",oDocTipo,"' ",
                     IF(xidPicking IS NULL, "",CONCAT(" AND  tbintegraSAP_Doc.idPicking = ",xidPicking)),
                     "  AND tbintegraSAP_Doc.StatusDoc = '1' ",
                     IF(xTipoDocSLIN NOT IN ('E','S'), 
                        #Se XtipoDocSLin != E/S, então dá update para ignorar o processamento
                        "",
                        IF(xCondicao = '',
                           #Se nao tem condição, não dá update, ou seja, processa
                           "and false", 
                           #se tem condição, dá update no inverso da condição
                           CONCAT(" and not ",xCondicao)
                           )
                        ));
   #select xCondicao, xTipoDocSLIN ;
   #select @SQL;
   
   
   #Executa o UpDATE
   PREPARE stmt1 FROM @SQL;
   EXECUTE stmt1;
   DEALLOCATE PREPARE stmt1;   
   
   
   IF xflgGeraMovtoTr <> 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - ERRO Transferencia não inserida =>",oDocTipo, oDocNum,'-',oDocEntry,"(",xOrigem,'/',xDestino,")"); 
   END IF;
   
   IF excecao = 1 THEN
      ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - ERRO SQL - Verifique com o Administrador");
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      COMMIT;
   END IF;
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_EnviarDocEntry_Item.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_EnviarDocEntry_Item`$$

CREATE PROCEDURE `PROC_INTEGRA_EnviarDocEntry_Item`(
   IN oCodUsuario				   VARCHAR(10),
   IN oDocEntry	        INT,
   IN oDocTipo		        VARCHAR(10), #'PedidoVenda-ConfPV / NotaFiscalRecebimento-ConfNF / OrdemProducao-ConfOP / '
   IN oDocNum		         VARCHAR(30),
   IN oLineNum		        INT,
   IN oItemCode	        VARCHAR(30),
   IN oBaseQty		        DOUBLE(20,6),
   IN oPlannedQty	      DOUBLE(20,6),
   IN oIssuedQty	       DOUBLE(20,6),
   IN oWhareHouse	      VARCHAR(30),
   IN oPrice            DOUBLE(20,6),
   IN oDollarQuote      DOUBLE(20,6),
   IN oUsage            VARCHAR(20),
   IN oCFOPCode         VARCHAR(15),
   IN oTaxCode          VARCHAR(15),
   #Grupo Unidade de Medida
   IN oUgpEntry         INT,
   IN oUomCode          VARCHAR(30),
   IN ounitMsr          VARCHAR(30),
   IN oOpenInvQty       DOUBLE(20,6),
   #
   IN oflg_PROMO        VARCHAR(01),
   IN oflg_USO_CONS     VARCHAR(01),
   #
   IN oIssueType	       VARCHAR(1),
   IN oStatusItem	      VARCHAR(10),	# Verificar STATUS EXCLUSÃO
   IN oObservacoes      VARCHAR(500),
	
   IN oDescrProduto     VARCHAR(200),
   IN oEmbCompras       VARCHAR(30),
   IN oEmbVendas        VARCHAR(30),
   IN oEmbEstoque       VARCHAR(30),
   IN oManBtchNum       INT,
   IN oManSerNum        INT,
   IN oNumInSale        DECIMAL(18,5),
   IN oBatchNumbersCode VARCHAR(30),
	
	# Parametros de Retorno
	OUT RESULTADO          BOOLEAN,
	OUT MENSAGEM           VARCHAR(500)
)
BLOCO1:BEGIN
   /******************************************************************************
   @Author <David Ruy (OVERFLASH)>
   @Creation <2019-07-11>
   @Description <Esta rotina insere e atualiza a tabela tbintegraSAP_DocItem que faz o controle
   da integração SAP / SLIN. 
   >
   @Reviser David Ruy <2021-09-25> Ajustes Entrada Produção Parcelada PA000, PA001, PA002,....
   @Reviser David Ruy <2021-11-04> Ajustes Grupos de UM
   @Reviser David Ruy <2023-05-22> Controle Material Uso-Consumo/Promocional: oflg_PROMO / oflg_USO_CONS
   #@Reviser David Ruy <2023-10-07> Merge Uso-Consumo/Promocional   
   #@Reviser <20240627> David Ruy : Campo/Variável DocNum->Varchar(30)   
   #@Reviser David Ruy <2024-12-26> Checa topo tbintegraSAP_Doc
   #@Reviser David Ruy <2025-01-07> Upper Campos Item
   #@Reviser David Ruy <2025-02-05> Convencionado campo NumInSale para "PA"
   #@Reviser David Ruy <2026-07-24> Atualizar status do topo quando inserir o ultimo item para evitar Qtde Quebrada de itens
   *******************************************************************************/

   DECLARE xTipoDocSLIN VARCHAR(10);
   DECLARE xIncAlt 	VARCHAR(01)	DEFAULT 'I';
   DECLARE xLineNum INT;
   DECLARE xQtdeOriItens INT;
   DECLARE xStatusItem INT DEFAULT 1;
   DECLARE xCodErro	INT DEFAULT 0;
   DECLARE excecao 	INT DEFAULT 0;
   DECLARE xStrAux         VARCHAR(10) DEFAULT NULL;   
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   
   SET oDescrProduto = SUBSTRING(oDescrProduto,1,100);   
   
   IF oDocTipo = "PA" THEN
      #Tratativa para Ordem de Produção : Recebimento Parcelado
      #Gerar PA000, PA001, PA002, .....
      SELECT MAX(DocTipo) INTO xStrAux
      FROM tbintegraSAP_Doc
      WHERE SUBSTRING(DocTipo,1,2)  = "PA"
        AND DocEntry = oDocEntry;
           
      SET oDocTipo = xStrAux;
   END IF;   



   #Checa topo tbintegraSAP_Doc
   IF NOT EXISTS (SELECT 1 FROM tbintegraSAP_Doc WHERE DocEntry = oDocEntry AND DocTipo = oDocTipo AND DocNum = oDocNum) THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT("ERRO - Não localizado TOPO tbintegraSAP_Doc => ",oDocTipo,oDocNum,'(',oDocEntry,')');
      LEAVE BLOCO1;
   END IF;


   
   
   SET xLineNum = NULL;
   SELECT LineNum INTO xLineNum
   #@Reviser @David Ruy <2019/11/28> Chave primária é oDocEntry+oDocTipo+oLineNum
   FROM tbintegraSAP_DocItem
   WHERE DocEntry = oDocEntry
     AND DocTipo  = oDocTipo
     AND Docnum   = oDocNum
     #AND ItemCode = oItemCode;
     AND LineNum  = oLineNum;
     
   IF xLineNum IS NULL THEN
      SET xIncAlt = "I";
      SET xLineNum = oLineNum;
   ELSE
      SET xIncAlt = "A";
   END IF;
   
   /*IF xIncAlt = "I" THEN
      #SELECT IFNULL(MAX(LineNum)+1,0) INTO xLineNum 
      #FROM tbintegraSAP_DocItem
      #WHERE DocEntry = oDocEntry
      #  AND DocTipo  = oDocTipo;
      SET xLineNum = oLineNum;
      SET xIncAlt = "I";
   END IF;
   */
   
   SELECT tbTipoOper.tipo_movto INTO xTipoDocSLIN
   FROM of_logistica.tbsys_integracao_estoque tbSys
   INNER JOIN of_logistica.tbwms_tipo_oper tbTipoOper ON
              tbSys.cod_oper_wms = tbTipoOper.cod_oper_wms
    WHERE chave_integracao = oDocTipo LIMIT 1;
    
    
    IF (oWhareHouse IS NULL) THEN
      SELECT WhareHouse INTO oWhareHouse 
      FROM tbintegraSAP_Doc
      WHERE DocEntry = oDocEntry
        AND DocTipo = oDocTipo
        AND Docnum = oDocNum
      LIMIT 1;
    END IF;
   
   
    #@Reviser David Ruy <2025-01-07> Upper Campos Item
				SET oDescrProduto = IF(oDescrProduto IS NOT NULL, UPPER(oDescrProduto), oDescrProduto );
				SET oUgpEntry = IF(oUgpEntry  IS NOT NULL, UPPER(oUgpEntry), oUgpEntry );
				SET oUomCode = IF(oUomCode IS NOT NULL, UPPER(oUomCode), oUomCode);
				SET ounitMsr = IF(ounitMsr IS NOT NULL, UPPER(ounitMsr), ounitMsr);
				SET oDescrProduto = IF(oDescrProduto IS NOT NULL, UPPER(oDescrProduto), oDescrProduto);
				SET oEmbCompras = IF(oEmbCompras IS NOT NULL, UPPER(oEmbCompras), oEmbCompras);
				SET oEmbVendas = IF(oEmbVendas IS NOT NULL, UPPER(oEmbVendas), oEmbVendas);
				SET oEmbEstoque = IF(oEmbEstoque IS NOT NULL, UPPER(oEmbEstoque), oEmbEstoque);

   
   IF xIncAlt = "I" THEN
      INSERT INTO tbintegraSAP_DocItem
         (DocEntry, DocTipo, DocNum, LineNum, ItemCode, BaseQty, PlannedQty, IssuedQty,
          WhareHouse, Price, DollarQuote, Usage_, CFOPCode, TaxCode,
          UgpEntry, UomCode, unitMsr, OpenInvQty,
          IssueType, StatusItem, Observacoes,
          OONE_PROMO, OONE_USO_CONS, 
          description, buyUnitMsr, salUnitMsr, invntryUom, ManBtchNum, ManSerNum, 
          NumInSale, NumInBuy, BatchNumbersCode,
          dthr_inc, usu_inc)
      VALUES 
         (oDocEntry, oDocTipo, oDocNum, xLineNum, oItemCode, oBaseQty, oPlannedQty, oIssuedQty,
          oWhareHouse, oPrice, oDollarQuote, oUsage, oCFOPCode, oTaxCode,
          oUgpEntry, oUomCode, ounitMsr, oOpenInvQty,
          oIssueType, NULL, oObservacoes, 
          oflg_PROMO, oflg_USO_CONS,
          oDescrProduto, oEmbCompras, oEmbVendas, oEmbEstoque, oManBtchNum, oManSerNum, 
          IF(DocTipo LIKE 'PA%', oNumInSale, IF(xTipoDocSLIN='S',oNumInSale,NumInSale)), 
          IF(DocTipo LIKE 'PA%', NumInBuy, IF(xTipoDocSLIN='E',oNumInSale,NumInBuy)), 
          oBatchNumbersCode,
          NOW(), oCodUsuario);
      SET MENSAGEM = "Registro inserido com sucesso";
      
   ELSEIF EXISTS (SELECT 1 FROM tbintegraSAP_DocItem
                  WHERE DocEntry = oDocEntry
                    AND DocTipo = DocTipo
                    AND ItemCode = oItemCode
                    AND (BaseQty <> oBaseQty
                    #@Reviser David Ruy <2020/02/28> Força condição para Nunca atualizar a integração pois já 
                    #                                existem endpoints de atualização / cancelamento
                    AND FALSE
                    #
                       OR IFNULL(PlannedQty,0) <> oPlannedQty
                       #OR IssuedQty <> oIssuedQty
                       OR IFNULL(WhareHouse,'') <> oWhareHouse
                       OR IFNULL(Price,0) <> oPrice
                       OR IFNULL(DollarQuote,0) <> oDollarQuote
                       #OR IssueType <> oIssueType
                       OR IFNULL(description,'') <> oDescrProduto
                       OR IFNULL(UgpEntry,'')   <> oUgpEntry
                       OR IFNULL(unitMsr,'')    <> ounitMsr
                       OR IFNULL(OpenInvQty,'') <> oOpenInvQty
                       #OR IFNULL(buyUnitMsr,'') <> oEmbCompras
                       #OR IFNULL(salUnitMsr,'') <> oEmbVendas
                       #OR IFNULL(invntryUom,'') <> oEmbEstoque
                       OR IF(xTipoDocSLIN='S' OR DocTipo LIKE 'PA%', 
                             IFNULL(NumInSale,0) <> oNumInSale, 
                             IFNULL(NumInBuy,0)  <> oNumInSale))) THEN
      UPDATE tbintegraSAP_DocItem SET
         #DocEntry = oDocEntry
         #,DocTipo = oDocTipo
         #,DocNum = oDocNum
         #,LineNum = oLineNum
          ItemCode = oItemCode
         ,BaseQty = oBaseQty
         ,PlannedQty  = oPlannedQty
         ,IssuedQty   = oIssuedQty
         ,WhareHouse  = oWhareHouse
         ,Price       = oPrice
         ,DollarQuote = oDollarQuote
         ,Usage_      = oUsage
         ,CFOPCode    = oCFOPCode
         ,TaxCode     = oTaxCode 
         ,UgpEntry    = oUgpEntry
         ,UomCode     = oUomCode
         ,unitMsr     = ounitMsr
         ,OpenInvQty  = oOpenInvQty
         ,IssueType   = oIssueType
         ,StatusItem  = 1
         ,Observacoes = IF(LENGTH(IFNULL(oObservacoes,''))=0,NULL, oObservacoes)
         ,description = oDescrProduto
         ,buyUnitMsr  = oEmbCompras
         ,salUnitMsr  = oEmbVendas
         ,invntryUom  = oEmbEstoque 
         ,ManBtchNum = oManBtchNum
         ,ManSerNum  = oManSerNum
         ,NumInSale  = IF(DocTipo LIKE 'PA%', oNumInSale, IF(xTipoDocSLIN='S',oNumInSale,NumInSale))
         ,NumInBuy   = IF(DocTipo LIKE 'PA%', NumInBuy, IF(xTipoDocSLIN='E',oNumInSale,NumInBuy))
         ,BatchNumbersCode = oBatchNumbersCode
         ,dthr_alt    = NOW()
         ,usu_alt     = oCodUsuario
      WHERE DocEntry = oDocEntry
        AND DocTipo  = oDocTipo
        AND DocNum   = oDocNum
        #AND ItemCode = oItemCode;
        AND LineNum  = oLineNum;
        
      IF ROW_COUNT() > 0 THEN
         SET MENSAGEM = "Registro atualizado com sucesso";
         SET xStatusItem = 1;
      ELSE
         SET MENSAGEM = CONCAT("Registro não atualizado - Sem alterações identificadas");
         SET xStatusItem = 0;
      END IF;
   ELSE
         SET MENSAGEM = CONCAT("Registro não atualizado - Sem alterações identificadas");
         SET xStatusItem = 0;
   END IF;
   
   
   
   #Checa Qtde de Itens para Liberar Status "1" Processar
   SELECT QtdeOriItens, COUNT(LineNum) QtdeLinhas 
   INTO xQtdeOriItens, xLineNum
   FROM tbintegraSAP_Doc tbTopo
   INNER JOIN tbintegraSAP_DocItem tbItem ON
              tbItem.DocTipo  = tbTopo.DocTipo 
          AND tbItem.DocEntry = tbTopo.DocEntry
          AND tbItem.DocNum   = tbTopo.DocNum
   WHERE tbTopo.DocTipo  = oDocTipo
     AND tbTopo.DocEntry = oDocEntry
     AND tbTopo.DocNum   = oDocNum;
   
   IF xQtdeOriItens = xLineNum THEN
      CALL PROC_INTEGRA_AtualizarStatusDocEntry('999999', oDocEntry, oDocTipo, oDocNum, 1, @R, @M);
   END IF;
   
   
   
   IF excecao = 1 THEN
      #ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      #COMMIT;
      SET RESULTADO = xStatusItem;
      #SELECT RESULTADO, MENSAGEM;
   END IF;
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_EnviarDocEntry_ItemOP.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_EnviarDocEntry_ItemOP`$$

CREATE PROCEDURE `PROC_INTEGRA_EnviarDocEntry_ItemOP`(
   IN oCodUsuario				   VARCHAR(10),
   IN oDocEntry	        INT,
   IN oDocTipo		        VARCHAR(10), #'PedidoVenda-ConfPV / NotaFiscalRecebimento-ConfNF / OrdemProducao-ConfOP / '
   IN oDocNum		         INT,
   IN oLineNum		        INT,
   IN oItemCode	        VARCHAR(30),
   IN oBaseQty		        DOUBLE(20,6),
   IN oPlannedQty	      DOUBLE(20,6),
   IN oIssuedQty	       DOUBLE(20,6),
   IN oWhareHouse	      VARCHAR(30),
   IN oPrice            DOUBLE(20,6),
   IN oDollarQuote      DOUBLE(20,6),
   IN oUsage            VARCHAR(20),
   IN oCFOPCode         VARCHAR(15),
   IN oTaxCode          VARCHAR(15),
   #Grupo Unidade de Medida
   IN oUgpEntry         INT,
   IN oUomCode          VARCHAR(30),
   IN ounitMsr          VARCHAR(30),
   IN oOpenInvQty       DOUBLE(20,6),
   #
   IN oIssueType	       VARCHAR(1),
   IN oStatusItem	      VARCHAR(10),	# Verificar STATUS EXCLUSÃO
   IN oObservacoes      VARCHAR(500),
	
   IN oDescrProduto     VARCHAR(200),
   IN oEmbCompras       VARCHAR(30),
   IN oEmbVendas        VARCHAR(30),
   IN oEmbEstoque       VARCHAR(30),
   IN oManBtchNum       INT,
   IN oManSerNum        INT,
   IN oNumInSale        DECIMAL(18,5),
   IN oBatchNumbersCode VARCHAR(30),
   IN oDataFabricacao   VARCHAR(30),
   IN oDataValidade     VARCHAR(30),
	
	# Parametros de Retorno
	OUT RESULTADO          BOOLEAN,
	OUT MENSAGEM           VARCHAR(500)
)
BLOCO1:BEGIN
   /******************************************************************************
   @Author <David Ruy (OVERFLASH)>
   @Creation <2019-07-11>
   @Description <Esta rotina insere e atualiza a tabela tbintegraSAP_DocItem que faz o controle
   da integração SAP / SLIN. 
   >
   @Reviser David Ruy <2021-09-25> Ajustes Entrada Produção Parcelada PA000, PA001, PA002,....
   @Reviser David Ruy <2021-11-04> Ajustes Grupos de UM
   @Reviser David Ruy <2025-07-11> Correção update, ajuste variável oDoctipo
   *******************************************************************************/
   DECLARE xTipoDocSLIN VARCHAR(10);
   DECLARE xIncAlt 	VARCHAR(01)	DEFAULT 'I';
   DECLARE xLineNum INT;
   DECLARE xStatusItem INT DEFAULT 1;
   DECLARE xCodErro	INT DEFAULT 0;
   DECLARE excecao 	INT DEFAULT 0;
   DECLARE xStrAux         VARCHAR(10) DEFAULT NULL;   
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   
   SET oDescrProduto = SUBSTRING(oDescrProduto,1,100);   
   
   IF oDocTipo = "PA" THEN
      #Tratativa para Ordem de Produção : Recebimento Parcelado
      #Gerar PA000, PA001, PA002, .....
      SELECT MAX(DocTipo) INTO xStrAux
      FROM tbintegraSAP_Doc
      WHERE SUBSTRING(DocTipo,1,2)  = "PA"
        AND DocEntry = oDocEntry;
           
      SET oDocTipo = xStrAux;
   END IF;   
   
   
   SET xLineNum = NULL;
   SELECT LineNum INTO xLineNum
   #@Reviser @David Ruy <2019/11/28> Chave primária é oDocEntry+oDocTipo+oLineNum
   FROM tbintegraSAP_DocItem
   WHERE DocEntry = oDocEntry
     AND DocTipo  = oDocTipo
     #AND ItemCode = oItemCode;
     AND LineNum  = oLineNum;
     
   IF xLineNum IS NULL THEN
      SET xIncAlt = "I";
      SET xLineNum = oLineNum;
   ELSE
      SET xIncAlt = "A";
   END IF;
   
   /*IF xIncAlt = "I" THEN
      #SELECT IFNULL(MAX(LineNum)+1,0) INTO xLineNum 
      #FROM tbintegraSAP_DocItem
      #WHERE DocEntry = oDocEntry
      #  AND DocTipo  = oDocTipo;
      SET xLineNum = oLineNum;
      SET xIncAlt = "I";
   END IF;
   */
   
   SELECT tbTipoOper.tipo_movto INTO xTipoDocSLIN
   FROM of_logistica.tbsys_integracao_estoque tbSys
   INNER JOIN of_logistica.tbwms_tipo_oper tbTipoOper ON
              tbSys.cod_oper_wms = tbTipoOper.cod_oper_wms
    WHERE chave_integracao = oDocTipo LIMIT 1;
    
    
    IF (oWhareHouse IS NULL) THEN
      SELECT WhareHouse INTO oWhareHouse 
      FROM tbintegraSAP_Doc
      WHERE DocEntry = oDocEntry
        AND DocTipo = oDocTipo
        AND Docnum = oDocNum
      LIMIT 1;
    END IF;
   
   
   IF xIncAlt = "I" THEN
      INSERT INTO tbintegraSAP_DocItem
         (DocEntry, DocTipo, DocNum, LineNum, ItemCode, BaseQty, PlannedQty, IssuedQty,
          WhareHouse, Price, DollarQuote, Usage_, CFOPCode, TaxCode,
          UgpEntry, UomCode, unitMsr, OpenInvQty,
          IssueType, StatusItem, Observacoes,
          description, buyUnitMsr, salUnitMsr, invntryUom, ManBtchNum, ManSerNum, 
          NumInSale, NumInBuy, BatchNumbersCode, DataFabricacao, DataValidade,
          dthr_inc, usu_inc)
      VALUES 
         (oDocEntry, oDocTipo, oDocNum, xLineNum, oItemCode, oBaseQty, oPlannedQty, oIssuedQty,
          oWhareHouse, oPrice, oDollarQuote, oUsage, oCFOPCode, oTaxCode,
          oUgpEntry, oUomCode, ounitMsr, oOpenInvQty,
          oIssueType, NULL, oObservacoes, 
          oDescrProduto, oEmbCompras, oEmbVendas, oEmbEstoque, oManBtchNum, oManSerNum, 
          IF(xTipoDocSLIN='S',oNumInSale,NumInSale), IF(xTipoDocSLIN='E',oNumInSale,NumInBuy), 
          oBatchNumbersCode, oDataFabricacao, oDataValidade,
          NOW(), oCodUsuario);
      SET MENSAGEM = "Registro inserido com sucesso";
      
   ELSEIF EXISTS (SELECT 1 FROM tbintegraSAP_DocItem
                  WHERE DocEntry = oDocEntry
                    AND DocTipo  = oDocTipo
                    AND ItemCode = oItemCode
                    AND (BaseQty <> oBaseQty
                    #@Reviser David Ruy <2020/02/28> Força condição para Nunca atualizar a integração pois já 
                    #                                existem endpoints de atualização / cancelamento
                    AND FALSE
                    #
                       OR IFNULL(PlannedQty,0) <> oPlannedQty
                       #OR IssuedQty <> oIssuedQty
                       OR IFNULL(WhareHouse,'') <> oWhareHouse
                       OR IFNULL(Price,0) <> oPrice
                       OR IFNULL(DollarQuote,0) <> oDollarQuote
                       #OR IssueType <> oIssueType
                       OR IFNULL(description,'') <> oDescrProduto
                       OR IFNULL(UgpEntry,'')   <> oUgpEntry
                       OR IFNULL(unitMsr,'')    <> ounitMsr
                       OR IFNULL(OpenInvQty,'') <> oOpenInvQty
                       #OR IFNULL(buyUnitMsr,'') <> oEmbCompras
                       #OR IFNULL(salUnitMsr,'') <> oEmbVendas
                       #OR IFNULL(invntryUom,'') <> oEmbEstoque
                       OR IF(xTipoDocSLIN='S', 
                             IFNULL(NumInSale,0) <> oNumInSale, 
                             IFNULL(NumInBuy,0)  <> oNumInSale))) THEN
      UPDATE tbintegraSAP_DocItem SET
         #DocEntry = oDocEntry
         #,DocTipo = oDocTipo
         #,DocNum = oDocNum
         #,LineNum = oLineNum
          ItemCode = oItemCode
         ,BaseQty = oBaseQty
         ,PlannedQty  = oPlannedQty
         ,IssuedQty   = oIssuedQty
         ,WhareHouse  = oWhareHouse
         ,Price       = oPrice
         ,DollarQuote = oDollarQuote
         ,Usage_      = oUsage
         ,CFOPCode    = oCFOPCode
         ,TaxCode     = oTaxCode 
         ,UgpEntry    = oUgpEntry
         ,UomCode     = oUomCode
         ,unitMsr     = ounitMsr
         ,OpenInvQty  = oOpenInvQty
         ,IssueType   = oIssueType
         ,StatusItem  = 1
         ,Observacoes = IF(LENGTH(IFNULL(oObservacoes,''))=0,NULL, oObservacoes)
         ,description = oDescrProduto
         ,buyUnitMsr  = oEmbCompras
         ,salUnitMsr  = oEmbVendas
         ,invntryUom  = oEmbEstoque 
         ,ManBtchNum = oManBtchNum
         ,ManSerNum  = oManSerNum
         ,NumInSale  = IF(xTipoDocSLIN='S',oNumInSale, NumInSale)
         ,NumInBuy   = IF(xTipoDocSLIN='S',NumInBuy, oNumInSale)
         ,BatchNumbersCode = oBatchNumbersCode
         ,DataFabricacao   = oDataFabricacao
         ,DataValidade     = oDataValidade
         ,dthr_alt    = NOW()
         ,usu_alt     = oCodUsuario
      WHERE DocEntry  = oDocEntry
        AND DocTipo   = oDocTipo
        #AND ItemCode = oItemCode;
        AND LineNum   = oLineNum;
        
      IF ROW_COUNT() > 0 THEN
         SET MENSAGEM = "Registro atualizado com sucesso";
         SET xStatusItem = 1;
      ELSE
         SET MENSAGEM = CONCAT("Registro não atualizado - Sem alterações identificadas");
         SET xStatusItem = 0;
      END IF;
   ELSE
         SET MENSAGEM = CONCAT("Registro não atualizado - Sem alterações identificadas");
         SET xStatusItem = 0;
   END IF;
   
   IF excecao = 1 THEN
      #ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      #COMMIT;
      SET RESULTADO = xStatusItem;
      #SELECT RESULTADO, MENSAGEM;
   END IF;
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_EnviarDocEntry_Item_Producao.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_EnviarDocEntry_Item_Producao`$$

CREATE PROCEDURE `PROC_INTEGRA_EnviarDocEntry_Item_Producao`(
   IN oCodUsuario				   VARCHAR(10),
   IN oDocEntry	        INT,
   IN oDocTipo		        VARCHAR(10), 
   IN oDocNum		         VARCHAR(30),
   IN oLineNum		        INT,
   
   IN oDocEntryOrdemProducao  VARCHAR(30),
   IN oDocNumOrdemProducao    VARCHAR(30),
   IN oSerialOrdemProducao    VARCHAR(30),
   
	# Parametros de Retorno
	OUT RESULTADO          BOOLEAN,
	OUT MENSAGEM           VARCHAR(500)
)
BLOCO1:BEGIN
   /******************************************************************************
   @Author <David Ruy (OVERFLASH)>
   @Creation <2026-04-06>
   @Description <Esta rotina insere e atualiza a tabela tbintegraSAP_DocItem com informação de Ordem de Produção Vinculada ao item
   #@Reviser David Ruy <2026-07-24> Atualizar status do topo quando inserir o ultimo item para evitar Qtde Quebrada de itens
   *******************************************************************************/

   DECLARE xTipoDocSLIN VARCHAR(10);
   DECLARE xIncAlt 	VARCHAR(01)	DEFAULT 'I';
   DECLARE xLineNum INT;
   DECLARE xQtdeOriItens INT;   
   DECLARE xStatusItem INT DEFAULT 1;
   DECLARE xCodErro	INT DEFAULT 0;
   DECLARE excecao 	INT DEFAULT 0;
   DECLARE xStrAux         VARCHAR(10) DEFAULT NULL;   
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   

   #Checa topo tbintegraSAP_Doc
   IF NOT EXISTS (SELECT 1 FROM tbintegraSAP_DocItem 
                  WHERE DocEntry = oDocEntry AND DocTipo = oDocTipo AND DocNum = oDocNum AND LineNum = oLineNum) THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT("ERRO - Não localizado ITEM tbintegraSAP_Doc_Item => ",oDocTipo,oDocNum,'(',oDocEntry,') LineNum=',oLineNum);
      LEAVE BLOCO1;
   END IF;
   
   
   UPDATE tbintegraSAP_DocItem 
   SET DocEntryOrdemProducao  = oDocEntryOrdemProducao,
       DocNumOrdemProducao    = oDocNumOrdemProducao,
       SerialOrdemProducao    = oSerialOrdemProducao, 
       dthr_alt    = NOW(),
       usu_alt     = oCodUsuario
   WHERE DocEntry = oDocEntry
     AND DocTipo  = oDocTipo
     AND DocNum   = oDocNum
     AND LineNum  = oLineNum;
        
   IF ROW_COUNT() > 0 THEN
      SET MENSAGEM = "Registro atualizado com sucesso";
      SET xStatusItem = 1;
   ELSE
      SET MENSAGEM = CONCAT("Registro não atualizado - Sem alterações identificadas");
      SET xStatusItem = 0;
   END IF;




   #Checa Qtde de Itens para Liberar Status "1" Processar
   SELECT QtdeOriItens, COUNT(LineNum) QtdeLinhas 
   INTO xQtdeOriItens, xLineNum
   FROM tbintegraSAP_Doc tbTopo
   INNER JOIN tbintegraSAP_DocItem tbItem ON
              tbItem.DocTipo  = tbTopo.DocTipo 
          AND tbItem.DocEntry = tbTopo.DocEntry
          AND tbItem.DocNum   = tbTopo.DocNum
   WHERE tbTopo.DocTipo  = oDocTipo
     AND tbTopo.DocEntry = oDocEntry
     AND tbTopo.DocNum   = oDocNum;
   
   IF xQtdeOriItens = xLineNum THEN
      CALL PROC_INTEGRA_AtualizarStatusDocEntry('999999', oDocEntry, oDocTipo, oDocNum, 1);
   END IF;






   
   IF excecao = 1 THEN
      #ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      #COMMIT;
      SET RESULTADO = xStatusItem;
      #SELECT RESULTADO, MENSAGEM;
   END IF;
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_EnviarLog.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_EnviarLog`$$

CREATE PROCEDURE `PROC_INTEGRA_EnviarLog`(
    IN oCodUsuario				       VARCHAR(10),
    IN oJsonRequest				      MEDIUMTEXT,
    IN oJsonResponse			      MEDIUMTEXT,
    IN oResponseStatus			    VARCHAR(10),
    IN oResponseStatusDescr		VARCHAR(300),
    # Parametros de Retorno
    OUT RESULTADO            INT,
    OUT MENSAGEM             VARCHAR(500)
)
BLOCO1:BEGIN
   DECLARE xIncAlt 	     VARCHAR(01)	DEFAULT 'I';
   DECLARE xCodErro	     INT DEFAULT 0;
   DECLARE excecao 	     INT DEFAULT 0;
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   #START TRANSACTION;
   
   INSERT INTO tbintegraSAP_log_request (
    jsonRequest,jsonResponse, ResponseStatus, ResponseStatusDescr, usu_inc, dthr_inc)
   VALUES (oJsonRequest, oJsonResponse, oResponseStatus, oResponseStatusDescr, 
     oCodUsuario, NOW()
    );
   IF excecao = 1 THEN
      #ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
   ELSE
      #COMMIT;
      SET RESULTADO = 1;
      SET MENSAGEM = "LOG gerado com sucesso";
   END IF;
   #SELECT RESULTADO, MENSAGEM;
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_EnviarUpdCancPV.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_EnviarUpdCancPV`$$

CREATE PROCEDURE `PROC_INTEGRA_EnviarUpdCancPV`(
	 IN oCodUsuario	            VARCHAR(10)
   ,IN oUniqueKey	           VARCHAR(30)	
   ,IN oTipoUpdCanc          VARCHAR(01)
   ,IN oDocumentType	        VARCHAR(10)
   ,IN oDocumentId	          INT(11)	
   ,IN oDocumentNumber	      INT(11)	
   ,IN oDocumentDate	        DATETIME	
   ,IN oDocumentDueDate	     DATETIME	
   ,IN oUpdateDate	          DATETIME	
   ,IN oCardCode	            VARCHAR(15)	
   ,IN oCardName	            VARCHAR(100)	
   ,IN oLineNumber	          INT(11)	
   ,IN oItemCode	            VARCHAR(30)	
   ,IN oFreeText	            VARCHAR(2000)
   ,IN oQuantity	            DECIMAL(18,5)	
   ,IN oInvQuantity	            DECIMAL(18,5)	   
   ,IN oSERIAL	              INT(11)	
   ,IN oAddress2	            VARCHAR(200)	
   ,IN oComments	            VARCHAR(2000)
   ,IN oAddrTypeS	           VARCHAR(20)	
   ,IN oStreetS	             VARCHAR(100)	
   ,IN oStreetNoS	           VARCHAR(30)	
   ,IN oBlockS	              VARCHAR(50)	
   ,IN oBuildingS	           VARCHAR(100)	
   ,IN oCityS	               VARCHAR(100)	
   ,IN oZipCodeS	            VARCHAR(10)	
   ,IN oStateS	              VARCHAR(2)	
   ,IN oCountryS	            VARCHAR(50)	
   ,IN oBatchNumber_Code	    VARCHAR(30)	
   ,IN oBatchNumber_Quantity	DECIMAL(18,5)	
   ,IN oSerialNumber_ManufactureCode	VARCHAR(30)	
   ,IN oManBtchNum	          TINYINT(1)	
   ,IN oManSerNum	           TINYINT(1)	
   ,IN oDescription	         VARCHAR(200)	
   ,IN oPrice	               DECIMAL(18,5)	
   ,IN oDollarQuote          DECIMAL(18,5)
   ,IN oBuyUnitMsr	          VARCHAR(10)	
   ,IN oSalUnitMsr	          VARCHAR(10)	
   ,IN oInvntryUom	          VARCHAR(10)	
   ,IN oNumInSale	           DECIMAL(18,5)	
   ,IN oSlpName              VARCHAR(100)	
   ,IN oIncoterms            VARCHAR(10)	
   ,IN oTransportationCode   VARCHAR(10)	
   ,IN oTrnspName            VARCHAR(100)	
   ,IN oTrnspTaxIdNum        VARCHAR(20)	
   ,IN oRoute                VARCHAR(50)
   ,IN oStartTime1           VARCHAR(20)
   ,IN oEndTime1             VARCHAR(20)
   ,IN oStartTime2           VARCHAR(20)
   ,IN oEndTime2             VARCHAR(20)
	,IN oEndEntrega	        VARCHAR(200)
	   
   # Parametros de Retorno
   ,OUT RESULTADO            INT
   ,OUT MENSAGEM             VARCHAR(500)
)
BLOCO1:BEGIN
   /******************************************************************************
   @Author <David Ruy (OVERFLASH)>
   @Creation <2019-12-20>
   @Description <Esta rotina insere e atualiza a tabela tbintegraSAP_UpdCancPV que faz o controle
   da integração SAP / SLIN dos pedidos Alterados e Cancelados no SAP  
   @#@Reviser David Ruy <2024-06-19> Alteração variável oComments -> VARCHAR(500) -> TEXT
   @Reviser David Ruy <2025-01-16> Novo Parametro oInvQuantity para atualizar QtdeEstoque
   @Reviser David Ruy <2025-01-21> Gravar STATUS = -1 (para não processar inicialmente até que seja feita uma checagem dos itens)
   *******************************************************************************/
   
   DECLARE xIncAlt 	     VARCHAR(01)	DEFAULT 'I';
   DECLARE xStatusAnt    VARCHAR(01);
   DECLARE xStatusAux    VARCHAR(01);
   DECLARE xCodErro	     INT DEFAULT 0;
   DECLARE excecao 	     INT DEFAULT 0;
   
   DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   IF NOT EXISTS (
         SELECT 1 
         FROM tbintegraSAP_UpdCancPV
         WHERE UniqueKey = oUniqueKey
           AND TipoUpdCanc = oTipoUpdCanc
           AND IF(oTipoUpdCanc = 'C', TRUE, UpdateDate = oUpdateDate)) THEN
         
         INSERT INTO tbintegraSAP_UpdCancPV (
            UniqueKey
            ,TipoUpdCanc
            ,DocumentType 
            ,DocumentId 
            ,DocumentNumber 
            ,DocumentDate 
            ,DocumentDueDate
            ,UpdateDate
            ,CardCode 
            ,CardName 
            ,LineNumber 
            ,ItemCode 
            ,FreeText 
            ,Quantity 
            ,QtdeEstoque
            ,SERIAL 
            ,Address2 
            ,Comments 
            ,AddrTypeS 
            ,StreetS 
            ,StreetNoS 
            ,BlockS 
            ,BuildingS 
            ,CityS 
            ,ZipCodeS 
            ,StateS 
            ,CountryS 
            ,BatchNumber_Code 
            ,BatchNumber_Quantity 
            ,SerialNumber_ManufactureCode 
            ,ManBtchNum 
            ,ManSerNum 
            ,Description 
            ,Price 
            ,DollarQuote 
            ,BuyUnitMsr 
            ,SalUnitMsr 
            ,InvntryUom 
            ,NumInSale
            ,SlpName         
            ,Incoterms   
            ,TransportationCode    
            ,TrnspName       
            ,TrnspTaxIdNum
            ,Route
            ,StartTime1
            ,EndTime1
            ,StartTime2
            ,EndTime2
            ,End_Entrega
            ,STATUS) VALUES (
                oUniqueKey
               ,oTipoUpdCanc
               ,oDocumentType 
               ,oDocumentId 
               ,oDocumentNumber 
               ,oDocumentDate
               ,oDocumentDueDate
               ,oUpdateDate
               ,oCardCode 
               ,oCardName 
               ,oLineNumber 
               ,oItemCode 
               ,oFreeText 
               ,oQuantity 
               ,oInvQuantity 
               ,oSERIAL 
               ,oAddress2 
               ,oComments 
               ,oAddrTypeS 
               ,oStreetS 
               ,oStreetNoS 
               ,oBlockS 
               ,oBuildingS 
               ,oCityS 
               ,oZipCodeS 
               ,oStateS 
               ,oCountryS 
               ,oBatchNumber_Code 
               ,oBatchNumber_Quantity 
               ,oSerialNumber_ManufactureCode 
               ,oManBtchNum 
               ,oManSerNum 
               ,oDescription 
               ,oPrice 
               ,oDollarQuote 
               ,oBuyUnitMsr 
               ,oSalUnitMsr 
               ,oInvntryUom 
               ,oNumInSale
               ,oSlpName         
               ,oIncoterms       
               ,oTransportationCode
               ,oTrnspName       
               ,oTrnspTaxIdNum
               ,oRoute
               ,oStartTime1
               ,oEndTime1
               ,oStartTime2
               ,oEndTime2
               ,oEndEntrega
               ,-1);
        SET RESULTADO = 1;
        SET MENSAGEM = "Registro inserido com sucesso";
            
/*            
     #@Reviser David Ruy <2020-08-11> Não há mais necessidade 
     # só insere se não existe e pronto
     ELSEIF EXISTS (SELECT 1 
                    FROM tbintegraSAP_UpdCancPV
                    WHERE UniqueKey = oUniqueKey
                      AND TipoUpdCanc = oTipoUpdCanc
                      AND UpdateDate = oUpdateDate
                      AND STATUS > 0) THEN
                      
        SET RESULTADO = 0;
        SET MENSAGEM = CONCAT("Registro em processo, não foi atualizado");		
   ELSE
      UPDATE tbintegraSAP_UpdCancPV
      SET Quantity   = oQuantity
          ,cod_emp   = NULL
          ,cod_fil   = NULL
          ,ano_solic = NULL
          ,num_solic = NULL
          ,num_item  = NULL          
          ,STATUS    = 1
      WHERE UniqueKey = oUniqueKey
        AND TipoUpdCanc = oTipoUpdCanc
        AND UpdateDate  = oUpdateDate; 
        
      SET RESULTADO = 1;
      SET MENSAGEM = "Registro atualizado com sucesso";   
*/
   ELSE
        SET RESULTADO = 2;
        SET MENSAGEM = "Registro já existe - Atualização não realizada";
   END IF;
    
   /*
   IF RESULTADO = 1 AND oTipoUpdCanc = "U" THEN
      UPDATE tbintegraSAP_UpdCancPV
      SET  cod_emp   = NULL
          ,cod_fil   = NULL
          ,ano_solic = NULL
          ,num_solic = NULL
          ,num_item  = NULL          
      WHERE DocumentId     = oDocumentId
        AND DocumentNumber = oDocumentNumber
        AND DocumentType   = oDocumentType
        AND TipoUpdCanc    = oTipoUpdCanc;   
   END IF;*/
    
    
   IF excecao = 1 THEN
      ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      COMMIT;
   END IF;
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_FINALIZAR_ITEM_GSM.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_FINALIZAR_ITEM_GSM`$$

CREATE PROCEDURE `PROC_INTEGRA_FINALIZAR_ITEM_GSM`( 
  IN oCodigoEmpresa    VARCHAR(3)
, IN oCodigoFilial     VARCHAR(3)
, IN oAnoProcesso      VARCHAR(4)
, IN oNumeroProcesso   VARCHAR(10)
, IN oNumeroItem       VARCHAR(6)
, OUT RESULTADO		      INT(1)
, OUT MENSAGEM         VARCHAR(255)
)
BLOCO2:BEGIN
  # PROCEDURE PARA CANCELAR GSM 
  # @author Érico Forcinetti <2019/07/15>
  # @company Overflash Informática
  
  /** 
   * ------------------------ INFORMAÇÕES ADICIONAIS -----------------------
   *
   *
   * ---------------------- FIM INFORMAÇÕES ADICIONAIS ---------------------
   */
  
  /****************************************************************/
  /**************** DECLARAR VARIÁVEIS AUXILIARES 
  /****************************************************************/
  DECLARE xCodUsuario      VARCHAR(06) DEFAULT "999999";  
  DECLARE _DthrAtual       DATETIME DEFAULT NOW();
  
  /****************************************************************/
  /****************DECLARAR CONTROLE DE EXCEÇÃO DE SQL 
  /****************************************************************/
    
	 DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    
    GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
  
    ROLLBACK;
    SET RESULTADO = 0;
    SET MENSAGEM  = fnMensagemExcecao(MENSAGEM);
		END;
	 
  /****************************************************************/
  /**************** INICIAR TRANSAÇÃO 
  /****************************************************************/
	 
  START TRANSACTION; 
	 
  /****************************************************************/
  /**************** ATUALIZAR TOPO DO ITEM
  /****************************************************************/
  
  UPDATE of_logistica.tbsolic_saidas_item tbItem
     SET tbItem.real_vol    = 0           
       , tbItem.real_frac   = 0          
       , tbItem.real_est    = 0       
       , tbItem.real_peso   = 0          
       , tbItem.real_pbrt   = 0          
       , tbItem.real_vol2   = 0          
       , tbItem.real_frac2  = 0          
       , tbItem.real_est2   = 0          
       , tbItem.real_peso2  = 0    
       , tbItem.dthr_aconselhamento = _DthrAtual
       , tbItem.usu_aconselhamento = xCodUsuario
   WHERE tbItem.cod_emp   = oCodigoEmpresa
     AND tbItem.cod_fil   = oCodigoFilial
     AND tbItem.ano_solic = oAnoProcesso
     AND tbItem.num_solic = oNumeroProcesso
     AND tbItem.num_item  = oNumeroItem;
  
  /****************************************************************/
  /**************** ATUALIZAR LOG
  /****************************************************************/
  # Rotina já realizada na PROC_INTEGRA_TratarAlteraoesSLIN
  # Mas por precaução, segue :
  UPDATE of_logistica.tbsolic_saidas_item_integra_alteracao tbItemAlteracao
     SET tbItemAlteracao.dthr_realizado = _DthrAtual
       , tbItemAlteracao.usu_realizado  = xCodUsuario
   WHERE tbItemAlteracao.cod_emp        = oCodigoEmpresa
     AND tbItemAlteracao.cod_fil        = oCodigoFilial
     AND tbItemAlteracao.ano_solic      = oAnoProcesso
     AND tbItemAlteracao.num_solic      = oNumeroProcesso
     AND tbItemAlteracao.num_item       = oNumeroItem
     AND tbItemAlteracao.qtde_est_atu   = 0;
     #AND tbItemAlteracao.dthr_realizado IS NULL; 
     
  /****************************************************************/
  /**************** DESVINCULAR ITEMS DOS CHECKOUTS
  /****************************************************************/
  
  DELETE 
    FROM of_logistica.tbsolic_saidas_volume_item
   WHERE cod_emp   = oCodigoEmpresa
     AND cod_fil   = oCodigoFilial
     AND ano_solic = oAnoProcesso
     AND num_solic = oNumeroProcesso
     AND num_item  = oNumeroItem;
  
  #*******************************************************************************************
  #**
  #** Se por ventura houver algum erro em alguma etapa do processamento, cancela o processo
  #** inteiro e sinalizado ao usuario. Caso contrario efetiva informações no banco e sinaliza
  #** usuario.
  #**
  #********************************************************************************************
  
  SET MENSAGEM  = 'OK';
  SET RESULTADO = 1;
  COMMIT; 
  
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_GerarGEM.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_GerarGEM`$$

CREATE PROCEDURE `PROC_INTEGRA_GerarGEM`(
   IN oCodUsuario			          VARCHAR(10),
   IN oCodEmpSLIN             VARCHAR(03),
   IN oCodFilSLIN             VARCHAR(03),
   IN oChavePedido			         VARCHAR(10),
   IN oDocEntry			            VARCHAR(10),
   IN oNumPedido		            VARCHAR(20),
   IN oSerialNum              INT,
   IN oDataPedido             DATETIME,
   IN oCodCliente             VARCHAR(14),
   IN oNomeCliente            VARCHAR(100),
   IN oCFOP                   VARCHAR(10),
   IN oObservPedido			        VARCHAR(500),
   
   # Parametros de Retorno
   OUT RESULTADO              INT,
   OUT MENSAGEM               VARCHAR(500)
)
BLOCO1:BEGIN
  /************************************************************************
  * @Created David Ruy <2019/04/11>
  * Esta procedure realiza a Inclusão/Atualização da GEM com base nas informações da tbIntegraSAP_Doc (Documentos de Entradas)
  *
  *@Reviser David Ruy <2021/04/14> Gravar o campo SERIAL (oSerialNum -> NumNF Fornecedor) na GEM
  *@Reviser David Ruy <2022-09-24> Parametros : oCodEmpSLIN / oCodFilSLIN
  *@Reviser David Ruy <2023-06-29> Gravar NumNF => Concat('OP',oSerialNum) para produção
  *@Reviser David Ruy <2024-06-12> Gravar tbsolic_entradas.num_pedido = xDocEntryRef (BRW)
  *@Reviser David Ruy <2024-06-24> xDocNum -> Update num_nf->concat('PA',xDocNum)
  *@Reviser David Ruy <2025-01-27> xBDO_NKIT (Gemmini)
  *@Reviser David Ruy <2025-02-24> Tratativa xChavePedido 'PA%' (Panizzon)
  *                                Condição IFNULL(buyUnitMsr,IF(UomCode='MANUAL',buyUnitMsr,UomCode))
  *@Reviser David Ruy <2025-07-22> Update num_pedido => IFNULL(xDocEntryRef,xDocNum)
  *************************************************************************/
   DECLARE excecao 	INT DEFAULT 0;
   DECLARE xCodEmpWMS			      VARCHAR(03)	;#DEFAULT '001';
   DECLARE xCodFilWMS			      VARCHAR(03) ;#DEFAULT '001';
   DECLARE xCNPJCPFCLI        VARCHAR(14) ;#DEFAULT '04330905000180';
   DECLARE xRAZSOCCLI         VARCHAR(100) ;#DEFAULT '04330905000180';
   DECLARE xCodEstoque        VARCHAR(03) ;#DEFAULT '001';
   DECLARE xAnoSolic 			      VARCHAR(04)	DEFAULT YEAR(CURRENT_DATE());
   DECLARE xNumSolic 			      VARCHAR(10);
   DECLARE xDataAtual         DATETIME;
   DECLARE xChaveIntegracao   VARCHAR(50);
   DECLARE xNumPedido         VARCHAR(20);
   DECLARE xDocEntryRef       VARCHAR(30);
   DECLARE xBDO_NKIT          VARCHAR(50);
   DECLARE xDocNum            VARCHAR(30);
   
   DECLARE xTipoOperacao 		      VARCHAR(03) ;#DEFAULT '001';
   DECLARE xFlgGeraPendFiscal    VARCHAR(01) ;#DEFAULT 'N';
   DECLARE xCodUnidade			        VARCHAR(03) ;#DEFAULT '001';
   DECLARE xCodArmazem			        VARCHAR(02) ;#DEFAULT '01';
   DECLARE xCFOP                 VARCHAR(04) ;#DEFAULT '9999';
   DECLARE xFlgDevol             VARCHAR(01) ;#DEFAULT 'N';
   DECLARE xFlgProducao          VARCHAR(01) ;#DEFAULT 'N';
   DECLARE xIncAlt 	VARCHAR(01)	DEFAULT 'I';
   DECLARE xCodErro	INT DEFAULT 0;
   DECLARE xflg_agrupa_transf TINYINT;  
   
   DECLARE xRefGuia           VARCHAR(30);
   DECLARE xNumItem           VARCHAR(06);
   DECLARE xLineNum           INT;
   DECLARE xItemCode          VARCHAR(30);
   DECLARE xBaseQty           DOUBLE(20,6);
   DECLARE xOpenInvQty        DOUBLE(20,6);
   DECLARE xVlrUnitario       DOUBLE(20,6);
   DECLARE xWhareHouseIte     VARCHAR(10); 
   DECLARE xStatusItem        VARCHAR(10);
   DECLARE xObservacoesIte    VARCHAR(300); 
   DECLARE xdescription       VARCHAR(100); 
   DECLARE xbuyUnitMsr        VARCHAR(30); 
   DECLARE xsalUnitMsr        VARCHAR(30); 
   DECLARE xinvntryUom        VARCHAR(30); 
   DECLARE xNumInSale         DECIMAL(18,6);
   DECLARE xNumInBuy          DECIMAL(18,6);
   DECLARE xBatchCode         VARCHAR(30); 
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       SELECT MENSAGEM;
       ROLLBACK;
   END;  
   
   START TRANSACTION;
   
   
   /*******************************************************************
   #Tratar e Validar as variáveis GEM
   *******************************************************************/
   SET xDataAtual = NOW(); 
   SET xCodErro   = 2;
   SET xIncAlt    = 'I';
   
   
   /***************************************************************************
   #@Parametros
   ****************************************************************************/
   SELECT flg_agrupa_transf INTO xflg_agrupa_transf 
   FROM tbintegraSAP_parametros LIMIT 1;  
   
   
   /***************************************************************************
   #@Reviser David Ruy <2019/12/11>
   # Busca informações dos parametros para gerar o documento
   ****************************************************************************/
   SET xNumPedido       = CONCAT(oChavePedido, oNumPedido);
   SET xChaveIntegracao = CONCAT(xNumPedido,'-',oDocEntry);
   SET xCNPJCPFCLI = NULL;
   #
   SELECT tbSysEstoque.cod_emp, tbSysEstoque.cod_fil, tbSysEstoque.cnpj_cpf_cli, tbSysEstoque.cod_estoque,
          tbWMSEstoqueCli.cod_und, tbWMSEstoqueCli.cod_armazem,
          IF(IFNULL(tbWMSEstoqueCli.flg_troca_nf_wms,"N")="N","N", IF(tbOperacoesWMS.flg_gera_fiscal="S","N","S")) AS xFlgGeraPendFiscal,      
          tbSysEstoque.cod_oper_wms, tbOperacoesWMS.cod_cfop_padrao AS cod_cfop_padrao, tbOperacoesWMS.flg_devol AS xFlgDevol,
          tbOperacoesWMS.flg_producao AS xFlgProducao
   INTO xCodEmpWMS, xCodFilWMS, xCNPJCPFCLI, xCodEstoque, 
        xCodUnidade, xCodArmazem,
        xFlgGeraPendFiscal, xTipoOperacao, xCFOP, xFlgDevol, xFlgProducao
   FROM of_logistica.tbsys_integracao tbSys
   INNER JOIN of_logistica.tbsys_integracao_estoque tbSysEstoque ON 
             tbSysEstoque.id_integracao = tbSys.id_integracao
         #AND tbSysEstoque.chave_integracao = oChavePedido
         AND tbSysEstoque.chave_integracao = IF(oChavePedido LIKE 'PA%','PA', oChavePedido)
   INNER JOIN of_logistica.tbwms_tipo_oper tbOperacoesWMS ON 
         tbOperacoesWMS.cod_oper_wms = tbSysEstoque.cod_oper_wms
   INNER JOIN of_logistica.tbwms_estoque_cli tbWMSEstoqueCli ON 
             tbWMSEstoqueCli.cod_emp = tbSysEstoque.cod_emp
         AND tbWMSEstoqueCli.cod_fil = tbSysEstoque.cod_fil
         AND tbWMSEstoqueCli.cod_estoque = tbSysEstoque.cod_estoque
   WHERE tbSys.nome_integracao_wms = 'SAP B1'
     AND tbSysEstoque.cod_emp = oCodEmpSLIN
     AND tbSysEstoque.cod_fil = oCodFilSLIN
   LIMIT 1;
   
   
   #@Reviser David Ruy <2022-09-24> 
   SET xCodEmpWMS = oCodEmpSLIN;
   SET xCodFilWMS = oCodFilSLIN;
   
   
   
   IF xCNPJCPFCLI IS NULL THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT("Parametrização não localizada - tbsys_integracao_estoque");
      LEAVE BLOCO1;
   END IF;
   
   #Considera CFOP da Integração se não for vazio
   IF IFNULL(oCFOP,'') <> '' THEN
      SET xCFOP = SUBSTRING(oCFOP,1,4);
      #Cadastrar CFOP se não existir
      IF NOT EXISTS (SELECT 1 FROM of_logistica.tbwms_oper_fiscal_ent
                     WHERE cod_oper = xCFOP) THEN
         INSERT INTO of_logistica.tbwms_oper_fiscal_ent
         VALUES (xCFOP, "CFOP INTEGRACAO - FAVOR CADASTRAR DESCRICAO");
      END IF;
   END IF;
     
   IF IFNULL(xCodEmpWMS,'') = '' OR 
      IFNULL(xCodFilWMS,'') = '' OR
      IFNULL(xCodEstoque,'') = '' OR
      IFNULL(xCodUnidade,'') = '' OR 
      IFNULL(xCodArmazem,'') = '' OR
      IFNULL(xFlgGeraPendFiscal,'') = '' OR
      IFNULL(xTipoOperacao,'') = '' OR
      IFNULL(xCFOP,'') = '' THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT("Parametrização incompleta - tbsys_integracao_estoque");
      LEAVE BLOCO1;
   END IF;
   
   
   IF (xFlgProducao = 'S') OR (xFlgDevol = 'S') THEN
      # Se for Entrada de Produção, fornecedor = CNPJ / NOME (Integração)
      SELECT raz_social INTO xRAZSOCCLI 
      FROM of_logistica.tbwms_terceiro 
      WHERE cnpj_cpf_cliente = xCNPJCPFCLI
        AND cnpj_cpf_terceiro = xCNPJCPFCLI;
      SET oCodCliente  = xCNPJCPFCLI;  #IF(IFNULL(oCodCliente,'')='',xCNPJCPFCLI,oCodCliente);
      SET oNomeCliente = xRAZSOCCLI;   #IF(IFNULL(oNomeCliente,'')='',xRAZSOCCLI,oNomeCliente);
   END IF;
   
   
   
   /***************************************************************************
   #@Reviser David Ruy <2024/06/12>
   #Busca informações do Topo da Entrada
   ****************************************************************************/
   SELECT DocEntryRef, DocNum, U_BDO_NKIT INTO xDocEntryRef, xDocNum, xBDO_NKIT
   FROM tbintegraSAP_Doc
   WHERE chave_integracao = xChaveIntegracao;
   
   
   
   
   /***************************************************************************
   ****************************************************************************/   
   SELECT tbsolic_entradas.cod_emp, tbsolic_entradas.cod_fil, tbsolic_entradas.ano_solic, tbsolic_entradas.num_solic
   INTO xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic
   FROM of_logistica.tbsolic_entradas 
   LEFT JOIN of_logistica.tbsolic_entradas_item ON
        tbsolic_entradas_item.cod_emp   = tbsolic_entradas.cod_emp
    AND tbsolic_entradas_item.cod_fil   = tbsolic_entradas.cod_fil
    AND tbsolic_entradas_item.ano_solic = tbsolic_entradas.ano_solic
    AND tbsolic_entradas_item.num_solic = tbsolic_entradas.num_solic
   WHERE tbsolic_entradas.cnpj_cpf_cli  = xCNPJCPFCLI
     AND (tbsolic_entradas.chave_integracao = xChaveIntegracao)
       #OR num_nf_vda = oChavePedido);
   LIMIT 1;
   IF xNumSolic IS NOT NULL THEN
      SET xIncAlt = 'A';		
   END IF;
   IF (NOT xFlgProducao = 'S') AND (NOT xFlgDevol = 'S') THEN
      CALL PROC_INTEGRA_CAD_Terceiro(oCodUsuario, xCNPJCPFCLI, oCodCliente, 0, oNomeCliente, oNomeCliente, 1, @R, @M);
      IF @R = 0 THEN
         SET RESULTADO = 0;
         SET MENSAGEM = CONCAT('PROC_INTEGRA_CAD_Terceiro ',@M, oCodCliente, oNomeCliente);
         LEAVE BLOCO1;
      END IF;
   END IF;
   IF xIncAlt = 'I' THEN
      
      SELECT LPAD(MAX(IFNULL(CAST(num_solic AS UNSIGNED),0))+1,10,'0')
      INTO xNumSolic 
      FROM of_logistica.tbsolic_entradas
      WHERE cod_emp   = xCodEmpWMS
        AND cod_fil   = xCodFilWMS
        AND ano_solic = xAnoSolic;
      SET xNumSolic = IFNULL(xNumSolic,'0000000001');
      /****************************************************************/
      /****************GRAVAR TOPO 
      /****************************************************************/
      INSERT INTO of_logistica.tbsolic_entradas( cod_emp
                           , cod_fil
                           , ano_solic
                           , num_solic
                           , data_solic
                           , flg_tipo_oper
                           , flg_utensilio
                           , flg_devol
                           , flg_gera_cobr
                           , flg_cobra_min
                           , flg_interface
                           , flg_pend_fiscal
                           , cod_oper
                           , cnpj_cpf_cli
                           , cnpj_cpf_dep
                           , cnpj_cpf_for
                           , cod_estoque
                           , flg_tipo_doc
                           , num_nf
                           , serie_nf
                           , data_nf
                           , observ_solic
                           , status_solic
                           , dthr_inc
                           , usu_inc
                           , cod_und
                           , cod_armazem
                           , flg_importacao_xml
                           , status_processo
                           , flg_producao
                           , chave_integracao
                           , num_pedido
                           #, inicio_descarga
                           #, final_descarga
                           #, dthr_acons
                           #, usu_acons
                           #, dthr_confer
                           #, usu_confer
                           #, dthr_confirm
                           #, usu_confirm
                           )
                      VALUES ( xCodEmpWMS
                           ,xCodFilWMS
                           ,xAnoSolic
                           ,xNumSolic
                           , CAST(xDataAtual AS DATE)
                           , xTipoOperacao
                           , 0         # flg_utensilio
                           , xFlgDevol # flg_devol
                           , 'N'       # flg_gera_cobr
                           , 'N'       # flg_cobra_min
                           , 'N'       # flg_interface (iNtegração)
                           , xFlgGeraPendFiscal 
                           ,xCFOP
                           ,xCNPJCPFCLI
                           ,xCNPJCPFCLI
                           ,oCodCliente
                           ,xCodEstoque
                           ,IF(SUBSTRING(oChavePedido,1,2)='PA', 'PA', oChavePedido) 
                           #,IF(xFlgProducao='N',oSerialNum,xNumPedido)
                           #,IF(xFlgProducao='N',oSerialNum,CONCAT("OP",IFNULL(oSerialNum, xNumPedido)))
                           ,IF(xFlgProducao='N',oSerialNum,CONCAT("PA",xDocNum))
                           , ''
                           , CAST(XDataAtual AS DATE)
                           , CONCAT('Integração SAP (Fornecedor:',oNomeCliente,') - ',xChaveIntegracao," ",IFNULL(oObservPedido,""),
                                    IF(xBDO_NKIT IS NULL,'', CONCAT(' NKIT:',xBDO_NKIT)))
                           , '1' 
                           , xDataAtual
                           
                           ,oCodUsuario
                           ,xCodUnidade
                           ,xCodArmazem
                           ,'N' 
                           , 3
                           , xFlgProducao
                           #,xDataAtual
                           #,xDataAtual
                           #,xDataAtual
                           #,oCodUsuario
                           #,xDataAtual
                           #,oCodUsuario
                           #,xDataAtual
                           #,oCodUsuario
                           , xChaveIntegracao
                           , IFNULL(xDocEntryRef,xDocNum)
                           );
      INSERT INTO of_logistica.tbsolic_entradas_fiscal (
            cod_emp, cod_fil, ano_solic, num_solic, cnpj_cpf_emi, flg_tipo_doc, num_nf, serie_nf, data_nf, cod_tipo_oper, cod_oper)
      VALUES (xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, oCodCliente, oChavePedido, 
               IF(xFlgProducao='N',oSerialNum,xNumPedido),
               '', xDataAtual, xTipoOperacao, '9999');
      SET RESULTADO = 3;
      SET MENSAGEM = CONCAT(xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic);		
   ELSE
      SELECT status_processo INTO RESULTADO
      FROM of_logistica.tbsolic_entradas
      WHERE cod_emp = xCodEmpWMS
        AND cod_fil = xCodFilWMS
        AND ano_solic = xAnoSolic
        AND num_solic = xNumSolic;
      SET MENSAGEM = CONCAT(xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, ' - GEM já cadastrada');
   END IF;
   
   
   
   
   
   /************************************************************************************************/
   #Fase 2 - Inclusão dos Itens
   /************************************************************************************************/
   SET xRefGuia = CONCAT(xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic);
   
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraDocItem;
   CREATE TEMPORARY TABLE tbtmp_IntegraDocItem
      SELECT tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocNum, 
             tbintegraSAP_DocItem.LineNum, 
             tbintegraSAP_DocItem.ItemCode, tbintegraSAP_DocItem.BaseQty, tbintegraSAP_DocItem.OpenInvQty,
             (tbintegraSAP_DocItem.Price*IF(IFNULL(tbintegraSAP_DocItem.DollarQuote,0)=0,1,tbintegraSAP_DocItem.DollarQuote)) Price, 
             tbintegraSAP_DocItem.UomCode,
             tbintegraSAP_DocItem.DollarQuote,
             tbintegraSAP_DocItem.WhareHouse, 
             tbintegraSAP_DocItem.StatusItem, 
             SUBSTRING(tbintegraSAP_DocItem.Observacoes,1,300) AS Observacoes, 
             tbintegraSAP_DocItem.description, tbintegraSAP_DocItem.buyUnitMsr, tbintegraSAP_DocItem.salUnitMsr, 
             tbintegraSAP_DocItem.invntryUom, 
             tbintegraSAP_DocItem.NumInSale, tbintegraSAP_DocItem.NumInBuy, tbintegraSAP_DocItem.BatchNumbersCode
      FROM tbintegraSAP_DocItem
      INNER JOIN tbintegraSAP_Doc ON
                 tbintegraSAP_Doc.DocTipo  = tbintegraSAP_DocItem.DocTipo    
             AND tbintegraSAP_Doc.DocEntry = tbintegraSAP_DocItem.DocEntry
      WHERE tbintegraSAP_DocItem.DocTipo  = oChavePedido
        AND tbintegraSAP_DocItem.DocEntry = oDocEntry
        AND tbintegraSAP_DocItem.DocNum   = oNumPedido
        AND tbintegraSAP_DocItem.num_solic IS NULL
        AND IFNULL(tbintegraSAP_DocItem.StatusItem,'0') <= '2'  #Traz os itens com status nulo (a inserir) e 1 = A atualizar
      ORDER BY tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.LineNum;
   
   
   #SELECT oChavePedido, oDocEntry, oNumPedido, tbtmp_IntegraDocItem.* FROM tbtmp_IntegraDocItem;
   #rollback; Leave BLOCO1;
   
   
   
   #Insere / Atualiza Itens  
   WHILE EXISTS (SELECT 1 FROM tbtmp_IntegraDocItem
                 WHERE DocTipo  = oChavePedido
                   AND DocEntry = oDocEntry
                 ORDER BY LineNum) DO
                 
      SELECT LineNum, ItemCode, BaseQty, IFNULL(OpenInvQty, BaseQty),
             (Price*IF(IFNULL(DollarQuote,0)=0,1,DollarQuote)), WhareHouse, StatusItem, Observacoes, 
             #description, buyUnitMsr, salUnitMsr, invntryUom, 
             description, 
             #@Reviser David Ruy <2025-02-24> Alterado, estava IFNULL(UomCode,buyUnitMsr), 
             IFNULL(buyUnitMsr,IF(UomCode='MANUAL',buyUnitMsr,UomCode)), 
             IFNULL(salUnitMsr,IF(UomCode='MANUAL',salUnitMsr,UomCode)), 
             invntryUom, NumInSale, NumInBuy, BatchNumbersCode
      INTO xLineNum, xItemCode, xBaseQty, xOpenInvQty, xVlrUnitario, xWhareHouseIte, xStatusItem, xObservacoesIte,
           xdescription, xbuyUnitMsr, xsalUnitMsr, xinvntryUom, 
           xNumInSale, xNumInBuy, xBatchCode
      FROM tbtmp_IntegraDocItem
      WHERE DocTipo  = oChavePedido
        AND DocEntry = oDocEntry
      ORDER BY LineNum LIMIT 1;
      
      SET xVlrUnitario = IF(IFNULL(xVlrUnitario,1)=0,1,IFNULL(xVlrUnitario,1));
      SET xdescription = IFNULL(xdescription,'');
      SET xbuyUnitMsr = IFNULL(xbuyUnitMsr,'');
      SET xsalUnitMsr = IFNULL(xsalUnitMsr,'');
      SET xinvntryUom = IFNULL(xinvntryUom,'');
      SET xObservacoesIte = SUBSTRING(xObservacoesIte,1,100);
      
      
      CALL PROC_INTEGRA_GerarGEMItem(oCodUsuario, xRefGuia, CONCAT(oNumPedido,'(',oDocEntry,')'), xLineNum, xItemCode, xBaseQty, xOpenInvQty, xVlrUnitario, 
                  xStatusItem, xObservacoesIte, xdescription, IF(oChavePedido = 'DV' OR oChavePedido LIKE 'PA%',xsalUnitMsr,xbuyUnitMsr), xinvntryUom, 
                  IF(oChavePedido = 'DV' OR oChavePedido LIKE 'PA%',xNumInSale,xNumInBuy), xWhareHouseIte, @R, @M);            
      IF @R = 1 THEN      
         SET xStatusItem = @R;
         SET xNumItem    = SUBSTRING(@M,01,06);  #Numero do item no retorno da proc
         #Atualiza referencia GSM na tbintegraSAP_DocItem
         UPDATE tbintegraSAP_DocItem
         SET cod_emp     = xCodEmpWMS
            ,cod_fil     = xCodFilWMS
            ,ano_solic   = xAnoSolic
            ,num_solic   = xNumSolic
            ,num_item    = xNumItem
            ,StatusItem  = '0'    #Volta para Zero para identificar que já atualizou no SLIN
         WHERE DocTipo  = oChavePedido
           AND DocEntry = oDocEntry
           AND IF(xflg_agrupa_transf=1 AND oChavePedido = "TD-E", ItemCode = xItemCode, LineNum  = xLineNum);            
              
         CALL PROC_INTEGRA_EnviarLog('999999', 'PROC_INTEGRA_GerarGEMItem',
                  CONCAT('Inserido/Atualizado ',oChavePedido,oDocEntry,'-',oNumPedido,' | ', xRefGuia, '| Prd:', xItemCode), "200", @M, @R, @M);
      ELSE
         SET excecao   = 1;
         DELETE FROM tbtmp_IntegraDocItem
         WHERE DocTipo  = oChavePedido
           AND DocEntry = oDocEntry;
      END IF;
            
      DELETE FROM tbtmp_IntegraDocItem
      WHERE DocTipo  = oChavePedido
        AND DocEntry = oDocEntry
        AND LineNum  = xLineNum;
                      
   END WHILE;       
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraDocItem;
   IF excecao = 0 THEN
      COMMIT;
   ELSE
      ROLLBACK;
      
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT('ERRO Inclusão de Item ',oChavePedido,oDocEntry,'-',oNumPedido,' | ', xRefGuia, '| Prd:', xItemCode);
      
      CALL PROC_INTEGRA_EnviarLog('999999',
             IF(oChavePedido IN ("PV","OP","TD-S","NS"), 'PROC_INTEGRA_GerarGSMItem', 'PROC_INTEGRA_GerarGEMItem'),
               CONCAT('NÃO Inserido/Atualizado ',oChavePedido,oDocEntry,'-',oNumPedido,' | ', xRefGuia, '| Prd:', xItemCode), "200", @M, @R, @M);      
   END IF;
   
   
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_GerarGEMItem.sql*/

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

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_GerarGSM.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_GerarGSM`$$

CREATE PROCEDURE `PROC_INTEGRA_GerarGSM`(
   IN oCodUsuario				          VARCHAR(10),
   IN oCodEmpSLIN             VARCHAR(03),
   IN oCodFilSLIN             VARCHAR(03),
   IN oChavePedido			         VARCHAR(10),
   IN oDocEntry			            VARCHAR(10),
   IN oNumPedido		            VARCHAR(20),
   IN oDataPedido             DATETIME,
   IN oDataEntrega            DATETIME,
   IN oCodCliente             VARCHAR(14),
   IN oNomeCliente            VARCHAR(100),
   IN oObservPedido	          VARCHAR(2000),
   IN oNomeVendedor           VARCHAR(200),
   IN oValorPedido            DECIMAL(18,5),
   IN oTipoFrete              VARCHAR(05),
   IN oNomeTransp             VARCHAR(50),
   IN oCnpjTransp             VARCHAR(20),
   
   OUT RESULTADO              INT,
   OUT MENSAGEM               VARCHAR(500)
)
BLOCO1:BEGIN
  # PROCEDURE INTEGRAÇÃO PARA GERAR GSM
  # @author David Ruy
  # @company Overflash
  
  /**
   * ------------------------ INFORMAÇÕES ADICIONAIS -----------------------
   *
   *@Reviser David Ruy <2022-09-24> Parametros : oCodEmpSLIN / oCodFilSLIN
   *@Reviser David Ruy <2024-03-25> Transaction e chamada da inserção de itens
   *@Reviser David Ruy <2024-06-19> Alteração variável oObservPedido -> VARCHAR(500) -> VARCHAR(2000)
   *@Reviser David Ruy <2024-06-28> Inclusão da condição DocNum   = oNumPedido nas instruções SQL
   *@Reviser David Ruy <2024-09-23> CNPJ Centralizador       
   #@Reviser David Ruy <2025-01-10> DocTipo = 'DC'  Devolução de Compras
   *@Reviser David Ruy <2026-04-06> Implementação PROC_INTEGRA_LiberarStatusUAs (xDocEntryOrdemProducao)
   *@Reviser David Ruy <2026-04-17> Implementação PROC_WMS_SAIDA_GERAR_ACONSELHAMENTO_TOTAL após commit
   * ---------------------- FIM INFORMAÇÕES ADICIONAIS ---------------------
   */
  
  /****************************************************************/
  /****************DECLARAR VARIÁVEIS AUXILIARES
  /****************************************************************/
   DECLARE excecao              TINYINT DEFAULT 0;
   DECLARE _IDDestinatario      INT(11); 
   DECLARE xCodEmpWMS			        VARCHAR(03);  #DEFAULT '001';
   DECLARE xCodFilWMS			        VARCHAR(03);  #DEFAULT '001';
   DECLARE xCNPJCPFCLI          VARCHAR(14);  #DEFAULT '04330905000180';
   DECLARE xRAZSOCCLI           VARCHAR(100); #DEFAULT '04330905000180';
   DECLARE xCodEstoque          VARCHAR(03);  #DEFAULT '001';
   DECLARE xAnoSolic 			        VARCHAR(04)	DEFAULT YEAR(CURRENT_DATE());
   DECLARE xNumSolic 			        VARCHAR(10);
   DECLARE xDataAtual           DATETIME;
   DECLARE xGSMDataSaida        DATETIME DEFAULT oDataEntrega; #DATE_ADD(CURRENT_DATE(), INTERVAL 1 DAY);
   DECLARE xChaveIntegracao     VARCHAR(50);
   DECLARE xNumPedido           VARCHAR(20);
   DECLARE xTipoOperacao 		     VARCHAR(03); #DEFAULT '002';
   DECLARE xFlgEmiteNF          VARCHAR(01)  DEFAULT 'N';
   DECLARE xFLGDataCritica      VARCHAR(01)  DEFAULT 'S';
   DECLARE xFLGDataRestrita     VARCHAR(01)  DEFAULT 'S';
   DECLARE xFLGVencidos         VARCHAR(01)  DEFAULT 'S';
   DECLARE xFLGDataFutura       VARCHAR(01)  DEFAULT 'S';
   DECLARE xPercentualVidaUtil  DECIMAL(5,2) DEFAULT 0;
   DECLARE xCodUnidade			       VARCHAR(03); #DEFAULT '001';
   DECLARE xCodArmazem			       VARCHAR(02); #DEFAULT '01';
   DECLARE xCFOP                VARCHAR(04); #DEFAULT '9999';
   DECLARE xFlgProducao         VARCHAR(01); #DEFAULT 'N';
   DECLARE xIncAlt 	            VARCHAR(01)	DEFAULT 'I';
   DECLARE xCodErro	            INT         DEFAULT 0;
   DECLARE xflg_agrupa_transf TINYINT;  
   DECLARE xRefGuia           VARCHAR(30);
   DECLARE xNumItem           VARCHAR(06);
   DECLARE xLineNum           INT;
   DECLARE xItemCode          VARCHAR(30);
   DECLARE xBaseQty           DOUBLE(20,6);
   DECLARE xOpenInvQty        DOUBLE(20,6);
   DECLARE xVlrUnitario       DOUBLE(20,6);
   DECLARE xWhareHouseIte     VARCHAR(10); 
   DECLARE xStatusItem        VARCHAR(10);
   DECLARE xObservacoesIte    VARCHAR(300); 
   DECLARE xdescription       VARCHAR(100); 
   DECLARE xbuyUnitMsr        VARCHAR(30); 
   DECLARE xsalUnitMsr        VARCHAR(30); 
   DECLARE xinvntryUom        VARCHAR(30); 
   DECLARE xNumInSale         DECIMAL(18,6);
   DECLARE xNumInBuy          DECIMAL(18,6);
   DECLARE xBatchCode         VARCHAR(30); 
   #
   DECLARE xDocEntryOrdemProducao VARCHAR(30);
   DECLARE xAny_OrdemProducao     BOOLEAN  DEFAULT FALSE;
   
  
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       SELECT MENSAGEM;
       ROLLBACK;
   END;  
   START TRANSACTION;
  
   /*******************************************************************
   #Tratar e Validar as variáveis GSM
   *******************************************************************/
   
   SET xDataAtual = NOW();
   SET xCodErro = 2;
   SET xIncAlt = 'I';
   SET oCnpjTransp = fnTirarCaracteresEspeciais(oCnpjTransp);
   SET oTipoFrete = IFNULL(oTipoFrete,"N/A");
  
  
  
   /***************************************************************************
   #@Parametros
   ****************************************************************************/
   SELECT flg_agrupa_transf INTO xflg_agrupa_transf 
   FROM tbintegraSAP_parametros LIMIT 1;  
  
  
  
   /***************************************************************************
   #@Reviser David Ruy <2019/12/11>
   # Busca informações dos parametros para gerar o documento
   ****************************************************************************/
   SET xNumPedido       = CONCAT(oChavePedido, oNumPedido);
   SET xChaveIntegracao = CONCAT(xNumPedido,'-',oDocEntry);
   SET xCNPJCPFCLI = NULL;
   #
   
   SELECT tbSysEstoque.cod_emp, tbSysEstoque.cod_fil, tbSysEstoque.cnpj_cpf_cli, tbSysEstoque.cod_estoque,
          tbWMSEstoqueCli.cod_und, tbWMSEstoqueCli.cod_armazem,
          IF(IFNULL(tbWMSEstoqueCli.flg_troca_nf_wms,"N")="N","N", IF(tbOperacoesWMS.flg_gera_fiscal="S","N","S")) AS xFlgEmiteNF,
          tbSysEstoque.cod_oper_wms, tbOperacoesWMS.cod_cfop_padrao AS cod_cfop_padrao,
          tbOperacoesWMS.flg_producao AS xFlgProducao
   INTO xCodEmpWMS, xCodFilWMS, xCNPJCPFCLI, xCodEstoque,
        xCodUnidade, xCodArmazem,
        xFlgEmiteNF, xTipoOperacao, xCFOP, xFlgProducao
   FROM of_logistica.tbsys_integracao tbSys
   INNER JOIN of_logistica.tbsys_integracao_estoque tbSysEstoque ON
             tbSysEstoque.id_integracao = tbSys.id_integracao
         #AND tbSysEstoque.chave_integracao = oChavePedido
         AND tbSysEstoque.chave_integracao = IF(oChavePedido LIKE 'PA%','PA', oChavePedido)
   INNER JOIN of_logistica.tbwms_tipo_oper tbOperacoesWMS ON
         tbOperacoesWMS.cod_oper_wms = tbSysEstoque.cod_oper_wms
   INNER JOIN of_logistica.tbwms_estoque_cli tbWMSEstoqueCli ON
             tbWMSEstoqueCli.cod_emp = tbSysEstoque.cod_emp
         AND tbWMSEstoqueCli.cod_fil = tbSysEstoque.cod_fil
         AND tbWMSEstoqueCli.cod_estoque = tbSysEstoque.cod_estoque
   WHERE tbSys.nome_integracao_wms = 'SAP B1'
     AND tbSysEstoque.cod_emp = oCodEmpSLIN
     AND tbSysEstoque.cod_fil = oCodFilSLIN
   LIMIT 1;
   
   #@Reviser David Ruy <2022-09-24> 
   SET xCodEmpWMS = oCodEmpSLIN;
   SET xCodFilWMS = oCodFilSLIN;
   
   
   IF xCNPJCPFCLI IS NULL THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT("Parametrização incompleta - tbsys_integrcao_estoque");
      LEAVE BLOCO1;
   END IF;
   IF IFNULL(xCodEmpWMS,'') = '' OR
      IFNULL(xCodFilWMS,'') = '' OR
      IFNULL(xCodEstoque,'') = '' OR
      IFNULL(xCodUnidade,'') = '' OR
      IFNULL(xCodArmazem,'') = '' OR
      IFNULL(xFlgEmiteNF,'') = '' OR
      IFNULL(xTipoOperacao,'') = '' OR
      IFNULL(xCFOP,'') = ''    
   THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT("Parametrização incompleta - tbsys_integrcao_estoque");
      LEAVE BLOCO1;
   END IF;
   
   IF xFlgProducao = 'S' THEN
      # Se for Saída para Produção, fornecedor = CNPJ / NOME (Integração)
      SELECT raz_social INTO xRAZSOCCLI
      FROM of_logistica.tbwms_terceiro
      WHERE cnpj_cpf_cliente = xCNPJCPFCLI
        AND cnpj_cpf_terceiro = xCNPJCPFCLI;
      SET oCodCliente  = IF(IFNULL(oCodCliente,'')='',xCNPJCPFCLI,oCodCliente);
      SET oNomeCliente = IF(IFNULL(oNomeCliente,'')='',xRAZSOCCLI,oNomeCliente);
   END IF;
   SELECT tbsolic_saidas.cod_emp, tbsolic_saidas.cod_fil, tbsolic_saidas.ano_solic, tbsolic_saidas.num_solic
     INTO xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic
   FROM of_logistica.tbsolic_saidas
   LEFT JOIN of_logistica.tbsolic_saidas_item ON
        tbsolic_saidas_item.cod_emp   = tbsolic_saidas.cod_emp
    AND tbsolic_saidas_item.cod_fil   = tbsolic_saidas.cod_fil
    AND tbsolic_saidas_item.ano_solic = tbsolic_saidas.ano_solic
    AND tbsolic_saidas_item.num_solic = tbsolic_saidas.num_solic
   WHERE tbsolic_saidas.cnpj_cpf_cli     = xCNPJCPFCLI
     AND tbsolic_saidas.chave_integracao = xChaveIntegracao
   LIMIT 1;
   
   IF xNumSolic IS NOT NULL THEN
    SET xIncAlt = 'A';
   END IF;
   
   IF (xIncAlt = 'I') THEN
   
      SELECT of_logistica.tbdestinatarios.id_destinatario
        INTO _IDDestinatario
        FROM of_logistica.tbclientes 
       INNER JOIN of_logistica.tbdestinatarios ON 
                  tbdestinatarios.cnpj_cpf_cliente = tbclientes.cnpj_cpf_centralizador
              AND tbdestinatarios.cod_integracao   = oCodCliente
       WHERE of_logistica.tbclientes.cnpj_cpf = xCNPJCPFCLI
       LIMIT 1; 
             
      SELECT LPAD(MAX(IFNULL(CAST(num_solic AS UNSIGNED),0))+1,10,'0')
        INTO xNumSolic
        FROM of_logistica.tbsolic_saidas
       WHERE of_logistica.tbsolic_saidas.cod_emp   = xCodEmpWMS
         AND of_logistica.tbsolic_saidas.cod_fil   = xCodFilWMS
         AND of_logistica.tbsolic_saidas.ano_solic = xAnoSolic;
      SET xNumSolic = IFNULL(xNumSolic,'0000000001');
      
      INSERT INTO of_logistica.tbsolic_saidas ( cod_emp
                                           , cod_fil
                                           , ano_solic
                                           , num_solic
                                           , data_solic
                                           , num_nf
                                           , data_nf
                                           , flg_tipo_oper
                                           , flg_gera_cobr
                                           , flg_cobra_min
                                           , perc_vutil
                                           , flg_interface
                                           , flg_emite_nf
                                           , cnpj_cpf_cli
                                           , cnpj_cpf_dep
                                           , cod_estoque
                                           , flg_dt_critica
                                           , flg_dt_restrita
                                           , flg_vencidos
                                           , flg_dt_futura
                                           , flg_tipo_quebra
                                           , data_saida
                                           , observ_solic
                                           , cnpj_cpf_for 
                                           , descr_pedido
                                           , cnpj_cpf_transp
                                           , vlr_tot_nf
                                           , dthr_inc
                                           , usu_inc
                                           , cod_und
                                           , cod_armazem
                                           , tipo_conferencia
                                           , status_processo
                                           , flg_producao
                                           , id_destinatario
                                           , chave_integracao
                                           )
                                    VALUES ( xCodEmpWMS
                                           , xCodFilWMS
                                           , xAnoSolic
                                           , xNumSolic
                                           , CAST(xDataAtual AS DATE)
                                           , xNumPedido
                                           , oDataPedido
                                           , xTipoOperacao
                                           , 'N'
                                           , 'N'
                                           , xPercentualVidaUtil
                                           , 'N' 
                                           , xFlgEmiteNF
                                           , xCNPJCPFCLI
                                           , xCNPJCPFCLI
                                           , xCodEstoque
                                           , xFLGDataCritica
                                           , xFLGDataRestrita
                                           , xFLGVencidos
                                           , xFLGDataFutura
                                           , 'N' #flg_tipo_quebra (N-Apenas 1)
                                           , xGSMDataSaida
                                           , CONCAT('Integração (Destinatário:',oNomeCliente,') - ',oDocEntry," ",IFNULL(oObservPedido,""), " Frete:",oTipoFrete)
                                           , IF(IFNULL(oCodCliente,'') = '', NULL, oCodCliente)
                                           , oNomeVendedor
                                           , oCnpjTransp
                                           , oValorPedido
                                           , xDataAtual
                                           , oCodUsuario
                                           , xCodUnidade
                                           , xCodArmazem
                                           , '1' #1-Baixa Geral, 2-Picking Estoque
                                           , '1' #1-GSM Aberta
                                           , xFlgProducao
                                           , IF( IFNULL(_IDDestinatario, 0) = 0 
                                               , NULL 
                                               , _IDDestinatario
                                               )
                                           , xChaveIntegracao
                                           );
     SET RESULTADO = 1;
     SET MENSAGEM = CONCAT(xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic);
   ELSE
      SELECT status_processo 
        INTO RESULTADO
        FROM of_logistica.tbsolic_saidas
       WHERE cod_emp = xCodEmpWMS
         AND cod_fil = xCodFilWMS
         AND ano_solic = xAnoSolic
         AND num_solic = xNumSolic;
      SET MENSAGEM = CONCAT(xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, ' - GSM já cadastrada');
   END IF;
   
   
   
   
   /************************************************************************************************/
   #Fase 2 - Inclusão dos Itens
   /************************************************************************************************/
   SET xRefGuia = CONCAT(xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic);
   
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraDocItem;
   IF oChavePedido = 'TD-S' AND xflg_agrupa_transf = 1 THEN   
      CREATE TEMPORARY TABLE tbtmp_IntegraDocItem
         SELECT tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocNum, 
                tbintegraSAP_DocItem.LineNum, 
                tbintegraSAP_DocItem.ItemCode, SUM(tbintegraSAP_DocItem.BaseQty) BaseQty, SUM(tbintegraSAP_DocItem.OpenInvQty) OpenInvQty,
                (tbintegraSAP_DocItem.Price*IF(IFNULL(tbintegraSAP_DocItem.DollarQuote,0)=0,1,tbintegraSAP_DocItem.DollarQuote)) Price, 
                tbintegraSAP_DocItem.UomCode,
                tbintegraSAP_DocItem.DollarQuote,
                tbintegraSAP_DocItem.WhareHouse, 
                tbintegraSAP_DocItem.StatusItem, 
                SUBSTRING(tbintegraSAP_DocItem.Observacoes,1,300) AS Observacoes, 
                tbintegraSAP_DocItem.description, tbintegraSAP_DocItem.buyUnitMsr, tbintegraSAP_DocItem.salUnitMsr, 
                tbintegraSAP_DocItem.invntryUom, 
                tbintegraSAP_DocItem.NumInSale, tbintegraSAP_DocItem.NumInBuy, tbintegraSAP_DocItem.BatchNumbersCode,
                tbintegraSAP_DocItem.DocEntryOrdemProducao, tbintegraSAP_DocItem.DocNumOrdemProducao, tbintegraSAP_DocItem.SerialOrdemProducao
         FROM tbintegraSAP_DocItem
         INNER JOIN tbintegraSAP_Doc ON
                    tbintegraSAP_Doc.DocEntry = tbintegraSAP_DocItem.DocEntry
                AND tbintegraSAP_Doc.DocTipo  = tbintegraSAP_DocItem.DocTipo
         WHERE tbintegraSAP_DocItem.DocTipo  = oChavePedido
           AND tbintegraSAP_DocItem.DocEntry = oDocEntry
           AND tbintegraSAP_DocItem.DocNum   = oNumPedido
           AND tbintegraSAP_DocItem.num_solic IS NULL
           AND IFNULL(tbintegraSAP_DocItem.StatusItem,'0') <= '2'  #Traz os itens com status nulo (a inserir) e 1 = A atualizar
         GROUP BY tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocNum, tbintegraSAP_DocItem.ItemCode
         ORDER BY tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.LineNum;
   ELSE
      CREATE TEMPORARY TABLE tbtmp_IntegraDocItem
         SELECT tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocNum, 
                tbintegraSAP_DocItem.LineNum, 
                tbintegraSAP_DocItem.ItemCode, tbintegraSAP_DocItem.BaseQty, tbintegraSAP_DocItem.OpenInvQty,
                (tbintegraSAP_DocItem.Price*IF(IFNULL(tbintegraSAP_DocItem.DollarQuote,0)=0,1,tbintegraSAP_DocItem.DollarQuote)) Price, 
                tbintegraSAP_DocItem.UomCode,
                tbintegraSAP_DocItem.DollarQuote,
                tbintegraSAP_DocItem.WhareHouse, 
                tbintegraSAP_DocItem.StatusItem, 
                SUBSTRING(tbintegraSAP_DocItem.Observacoes,1,300) AS Observacoes, 
                tbintegraSAP_DocItem.description, tbintegraSAP_DocItem.buyUnitMsr, tbintegraSAP_DocItem.salUnitMsr, 
                tbintegraSAP_DocItem.invntryUom, 
                tbintegraSAP_DocItem.NumInSale, tbintegraSAP_DocItem.NumInBuy, tbintegraSAP_DocItem.BatchNumbersCode,
                tbintegraSAP_DocItem.DocEntryOrdemProducao, tbintegraSAP_DocItem.DocNumOrdemProducao, tbintegraSAP_DocItem.SerialOrdemProducao
         FROM tbintegraSAP_DocItem
         INNER JOIN tbintegraSAP_Doc ON
                    tbintegraSAP_Doc.DocTipo  = tbintegraSAP_DocItem.DocTipo    
                AND tbintegraSAP_Doc.DocEntry = tbintegraSAP_DocItem.DocEntry
         WHERE tbintegraSAP_DocItem.DocTipo  = oChavePedido
           AND tbintegraSAP_DocItem.DocEntry = oDocEntry
           AND tbintegraSAP_DocItem.DocNum   = oNumPedido
           AND tbintegraSAP_DocItem.num_solic IS NULL
           AND IFNULL(tbintegraSAP_DocItem.StatusItem,'0') <= '2'  #Traz os itens com status nulo (a inserir) e 1 = A atualizar
         ORDER BY tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.LineNum;
   END IF;
   
   
   #SELECT oChavePedido, oDocEntry, oNumPedido, tbtmp_IntegraDocItem.* FROM tbtmp_IntegraDocItem;
   #rollback; Leave BLOCO1;
   
   
   
   #Insere / Atualiza Itens  
   WHILE EXISTS (SELECT 1 FROM tbtmp_IntegraDocItem
                 WHERE DocTipo  = oChavePedido
                   AND DocEntry = oDocEntry
                 ORDER BY LineNum) DO
                 
      SELECT LineNum, ItemCode, BaseQty, IFNULL(OpenInvQty, BaseQty),
             (Price*IF(IFNULL(DollarQuote,0)=0,1,DollarQuote)), WhareHouse, StatusItem, Observacoes, 
             #description, buyUnitMsr, salUnitMsr, invntryUom, 
             description, 
             #@Reviser David Ruy <2025-02-24> Alterado, estava IFNULL(UomCode,IF(UomCode='MANUAL',buyUnitMsr,UomCode)), 
             IFNULL(buyUnitMsr,IF(UomCode='MANUAL',buyUnitMsr,UomCode)), 
             IFNULL(salUnitMsr,IF(UomCode='MANUAL',salUnitMsr,UomCode)), 
             invntryUom, NumInSale, NumInBuy, BatchNumbersCode, DocEntryOrdemProducao
      INTO xLineNum, xItemCode, xBaseQty, xOpenInvQty, xVlrUnitario, xWhareHouseIte, xStatusItem, xObservacoesIte,
           xdescription, xbuyUnitMsr, xsalUnitMsr, xinvntryUom, 
           xNumInSale, xNumInBuy, xBatchCode, xDocEntryOrdemProducao
      FROM tbtmp_IntegraDocItem
      WHERE DocTipo  = oChavePedido
        AND DocEntry = oDocEntry
        AND DocNum   = oNumPedido
      ORDER BY LineNum LIMIT 1;
      
      IF xDocEntryOrdemProducao IS NOT NULL THEN 
         SET xAny_OrdemProducao = TRUE;
      END IF;
      
      SET xVlrUnitario = IF(IFNULL(xVlrUnitario,1)=0,1,IFNULL(xVlrUnitario,1));
      SET xdescription = IFNULL(xdescription,'');
      SET xbuyUnitMsr = IFNULL(xbuyUnitMsr,'');
      SET xsalUnitMsr = IFNULL(xsalUnitMsr,'');
      SET xinvntryUom = IFNULL(xinvntryUom,'');
      SET xObservacoesIte = SUBSTRING(xObservacoesIte,1,300);
      
      #Debug
      #select 'PROC_INTEGRA_GerarGSMItem',oCodUsuario, xRefGuia, CONCAT(oNumPedido,'(',oDocEntry,')'), xLineNum, xItemCode, xdescription, xBaseQty, xOpenInvQty, xVlrUnitario, 
      #            xsalUnitMsr, xinvntryUom, xNumInsale, xStatusItem, xObservacoesIte, oCodCliente, oNomeCliente, xBatchCode, xWhareHouseIte, @R, @M;
      #
      CALL PROC_INTEGRA_GerarGSMItem(oCodUsuario, xRefGuia, CONCAT(oNumPedido,'(',oDocEntry,')'), xLineNum, xItemCode, xdescription, xBaseQty, xOpenInvQty, xVlrUnitario, 
                  xsalUnitMsr, xinvntryUom, xNumInsale, xStatusItem, xObservacoesIte, oCodCliente, oNomeCliente, xBatchCode, xWhareHouseIte, @R, @M);
      IF @R = 1 THEN      
         SET xStatusItem = @R;
         SET xNumItem    = SUBSTRING(@M,01,06);  #Numero do item no retorno da proc
         #Atualiza referencia GSM na tbintegraSAP_DocItem
         UPDATE tbintegraSAP_DocItem
         SET cod_emp     = xCodEmpWMS
            ,cod_fil     = xCodFilWMS
            ,ano_solic   = xAnoSolic
            ,num_solic   = xNumSolic
            ,num_item    = xNumItem
            ,StatusItem  = '0'    #Volta para Zero para identificar que já atualizou no SLIN
         WHERE DocTipo  = oChavePedido
           AND DocEntry = oDocEntry
           AND DocNum   = oNumPedido
           AND IF(xflg_agrupa_transf=1 AND oChavePedido = "TD-S", ItemCode = xItemCode, LineNum  = xLineNum);            
              
         CALL PROC_INTEGRA_EnviarLog(oCodUsuario, 'PROC_INTEGRA_GerarGSMItem',
                  CONCAT('Inserido/Atualizado ',oChavePedido,oDocEntry,'-',oNumPedido,' | ', xRefGuia, '| Prd:', xItemCode), "200", @M, @R, @M);
      ELSE
         SET excecao   = 1;
         DELETE FROM tbtmp_IntegraDocItem
         WHERE DocTipo  = oChavePedido
           AND DocEntry = oDocEntry
           AND DocNum   = oNumPedido;
         CALL PROC_INTEGRA_EnviarLog(oCodUsuario, 'PROC_INTEGRA_GerarGSMItem',
                  CONCAT('ERRO GERANDO ITEM GSM ',oChavePedido,oDocEntry,'-',oNumPedido,' | ', xRefGuia, '| Prd:', xItemCode), "ERRO", @M, @R, @M);
      END IF;
            
      DELETE FROM tbtmp_IntegraDocItem
      WHERE DocTipo  = oChavePedido
        AND DocEntry = oDocEntry
        AND DocNum   = oNumPedido
        AND LineNum  = xLineNum;
                
   END WHILE;       
   
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraDocItem;
   
   IF excecao = 0 THEN
      COMMIT;
      
      
      IF xAny_OrdemProducao THEN
         CALL PROC_INTEGRA_LiberarStatusUAs(oCodUsuario, oChavePedido, oDocEntry, oNumPedido, @R, @M);
         CALL PROC_INTEGRA_EnviarLog(oCodUsuario, 'PROC_INTEGRA_LiberarStatusUAs',
                  CONCAT('Liberando UA´s ',oChavePedido,oDocEntry,'-',oNumPedido,' | ', xRefGuia), IF(@R=1,"200","ERRO"), @M, @R, @M);

         CALL of_logistica.PROC_WMS_SAIDA_GERAR_ACONSELHAMENTO_TOTAL(8,
              xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, '999999', @R, @M);

         CALL PROC_INTEGRA_EnviarLog('999999',
                'PROC_INTEGRA_LiberarStatusUAs - Aconselhamento',
                  CONCAT(oChavePedido,oNumPedido,'(',oDocEntry,')',' |GEM=', xCodEmpWMS,'/',xCodFilWMS,'-',xAnoSolic,'.',xNumSolic), IF(@R=1,"200","ERRO"), @M, @R, @M);       
      END IF;
      
      
   ELSE
      ROLLBACK;
      
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT('ERRO Inclusão de Item ',oChavePedido,oDocEntry,'-',oNumPedido,' | ', xRefGuia, '| Prd:', xItemCode);
      
      CALL PROC_INTEGRA_EnviarLog(oCodUsuario,
             IF(oChavePedido IN ('PV','OP','TD-S','NS','DC'), 'PROC_INTEGRA_GerarGSMItem', 'PROC_INTEGRA_GerarGEMItem'),
               CONCAT('NÃO Inserido/Atualizado ',oChavePedido,oDocEntry,'-',oNumPedido,' | ', xRefGuia, '| Prd:', xItemCode), "200", @M, @R, @M);      
   END IF;
   
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_GerarGSMItem.sql*/

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

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_GERAR_TRANSF_ECOM.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_GERAR_TRANSF_ECOM`$$

CREATE PROCEDURE `PROC_INTEGRA_GERAR_TRANSF_ECOM`( 
  IN oItemCode     VARCHAR(20)
, IN oDepOrigem    VARCHAR(20)
, IN oDepDestino   VARCHAR(20)
, IN oQuantidade   DECIMAL(18,6)
, OUT RESULTADO    VARCHAR(40)
, OUT MENSAGEM     VARCHAR(500)
)
BLOCO1:BEGIN
   /************************************************************************
   * @Created David Ruy <2023/01/14>
   * Esta procedure realiza a inserção de registros na base de dados SLIN
   * para o módulo WM (tbwms_manut_lote) 
   * SAP : transferencia entre depósitos 
   * SLIN : Alteração de Status
   /************************************************************************/
   /****************************************************************/
   /****************DECLARAR VARIÁVEIS AUXILIARES
   /****************************************************************/
   DECLARE xDepositoAux        VARCHAR(10);
   DECLARE xCodEmp             VARCHAR(03);
   DECLARE xCodFil             VARCHAR(03);
   DECLARE xNumLote            VARCHAR(10); 
   DECLARE xSequenciaLote      INT;
   DECLARE xStatusOrigem       VARCHAR(03); 
   DECLARE xStatusDestino      VARCHAR(03); 
   DECLARE xQtdeATransf        DECIMAL(18,6);
   DECLARE xSaldoQtde          DECIMAL(18,6);
   DECLARE xSaldoPLiq          DECIMAL(18,6);
   DECLARE xSaldoEst           DECIMAL(18,6);
   DECLARE xSaldoVol           DECIMAL(18,6);
   DECLARE xSaldoFrac          DECIMAL(18,6);
   DECLARE xSaldoPeso          DECIMAL(18,6);
   DECLARE xNumLoteAux         VARCHAR(10); 
   DECLARE xSequenciaAux       INT;
   DECLARE xFragmentou         BOOLEAN;
   /****************************************************************/
   /****************CONTROLE DE EXCEÇÃO DE SQL
   /****************************************************************/
  
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
    
     GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
  
     ROLLBACK;
     SET RESULTADO = '0';
     SET MENSAGEM  = MENSAGEM;
   END;
   
   
  
   START TRANSACTION;
   
   
   #Quantidade Negativa, inverte depósitos Origem <-> Destino
   IF (oQuantidade < 0) THEN
      SET oQuantidade = oQuantidade * -1;
      SET xDepositoAux = oDepOrigem;
      SET oDepOrigem = oDepDestino;
      SET oDepDestino = xDepositoAux;
   END IF;
   
   
   
   
  
   SELECT IFNULL(cod_emp,'001'), IFNULL(cod_fil,'001'), IFNULL(tbstatus_lotes.codigo, tbstatus_lotes_integracao.codigo_status) cod_status
   INTO xCodEmp, xCodFil, xStatusOrigem
   FROM of_logistica.tbstatus_lotes
   LEFT JOIN of_logistica.tbstatus_lotes_integracao ON
             tbstatus_lotes_integracao.codigo_status = tbstatus_lotes.codigo
   WHERE of_logistica.tbstatus_lotes.deposito_integracao = oDepOrigem
      OR tbstatus_lotes_integracao.deposito_integracao = oDepOrigem;
   
   SELECT IFNULL(tbstatus_lotes.codigo, tbstatus_lotes_integracao.codigo_status) cod_status
   INTO xStatusDestino
   FROM of_logistica.tbstatus_lotes
   LEFT JOIN of_logistica.tbstatus_lotes_integracao ON
             tbstatus_lotes_integracao.codigo_status = tbstatus_lotes.codigo
   WHERE of_logistica.tbstatus_lotes.deposito_integracao = oDepDestino
      OR tbstatus_lotes_integracao.deposito_integracao = oDepDestino;
      
      
   DROP TEMPORARY TABLE IF EXISTS tbTMPTransferencia;
   CREATE TEMPORARY TABLE tbTMPTransferencia
       SELECT cod_emp, cod_fil, num_lote, sequencia_lote, 
              fator_conv, emb_vol, emb_frac, emb_nf, vlr_unitario, vlr_unitario_nf, 
              flg_tipo_vlr, data_fabr, data_valid, status_lote,
              sld_fisico_est - IFNULL(qtd_emp_est,0) saldo_est, 
              sld_fisico_vol - IFNULL(qtd_emp_vol,0) saldo_vol, 
              sld_fisico_frac- IFNULL(qtd_emp_frac,0) saldo_frac, 
              sld_fisico_peso- IFNULL(qtd_emp_peso,0) saldo_peso,
              0 AS Processado
       FROM of_logistica.tbwms_estoque
       WHERE cod_emp = xCodEmp
         AND cod_fil = xCodFil
         AND cod_produto = oItemCode
         AND sld_fisico_est - IFNULL(qtd_emp_est,0) > 0
         AND status_lote = xStatusOrigem
       ORDER BY sld_fisico_est - IFNULL(qtd_emp_est,0);
              
   IF NOT EXISTS (SELECT 1 FROM tbTMPTransferencia) THEN
      SET RESULTADO = 0;
      SET mensagem = CONCAT("Não existe saldo no WMS para essa transferencia ",
         xCodEmp,'/',xCodFil,' Item:',oItemCode,' de ',xStatusOrigem,' para ',xStatusDestino,
         ' Qtde = ',oQuantidade);
      ROLLBACK;
      LEAVE bloco1;
   END IF;
    
       
   SET xSaldoQtde = oQuantidade;
   WHILE EXISTS (SELECT 1 FROM tbTMPTransferencia WHERE Processado = 0) DO
          
      SET xNumLote = NULL;
      #Busca UA com qtde Exata
      IF EXISTS (SELECT 1 FROM tbTMPTransferencia 
                 WHERE Processado = 0 AND saldo_est = xSaldoQtde) THEN
         SELECT num_lote, sequencia_lote, saldo_est, saldo_vol, saldo_frac, saldo_peso 
         INTO xNumLote, xSequenciaLote, xSaldoEst, xSaldoVol, xSaldoFrac, xSaldoPeso
         FROM tbTMPTransferencia 
         WHERE Processado = 0 AND saldo_est = xSaldoQtde
         LIMIT 1;
         SET xQtdeATransf = xSaldoQtde;
      #Se não tem Qtde exata, Busca UA com qtde menor que o saldo a transferir
      ELSEIF EXISTS (SELECT 1 FROM tbTMPTransferencia 
                     WHERE Processado = 0 AND saldo_est < xSaldoQtde) THEN
         SELECT num_lote, sequencia_lote, saldo_est, saldo_vol, saldo_frac, saldo_peso 
         INTO xNumLote, xSequenciaLote, xSaldoEst, xSaldoVol, xSaldoFrac, xSaldoPeso
         FROM tbTMPTransferencia 
         WHERE Processado = 0 AND saldo_est < xSaldoQtde
         LIMIT 1;
         SET xQtdeATransf = xSaldoEst;
      #Se não tem Qtde exata nem Qtde menor, pega a de menor qtde (Order By da tabela temporária)
      ELSE
         SELECT num_lote, sequencia_lote, saldo_est, saldo_vol, saldo_frac, saldo_peso 
         INTO xNumLote, xSequenciaLote, xSaldoEst, xSaldoVol, xSaldoFrac, xSaldoPeso
         FROM tbTMPTransferencia 
         WHERE Processado = 0
         LIMIT 1;       
      END IF;
      
      
      IF xNumLote IS NULL THEN
         SET RESULTADO = 0;
         SET mensagem = CONCAT("Saldo Insuficiente(0) no WMS para essa transferencia ",
            xCodEmp,'/',xCodFil,' Item:',oItemCode,' de ',xStatusOrigem,' para ',xStatusDestino,
            ' Qtde = ',oQuantidade);
         ROLLBACK;
         LEAVE bloco1;      
      END IF;
       
      SET xFragmentou = FALSE;
      IF xSaldoEst >= xSaldoQtde THEN
         #PesoLiquido Proporcional (Ref : xSaldoQtde)
         SET xSaldoPLiq = xSaldoPeso / xSaldoEst * xSaldoQtde;
      
         # Fragmentar (Gera nova UA com a Quantidade = xSaldoQtde e Peso = xSaldoPLiq )
         # Essa UA será utilizada para a transferencia
         CALL of_logistica.PROC_WMS_ARMAZEM_GERAR_FRAGMENTACAO(
              xCodEmp, xCodFil, xNumLote, xSequenciaLote, xSaldoQtde, xSaldoPLiq, xStatusOrigem, 
              '999999', 'Fragmentação Automática - Transf EComm', @Resultado, @Mensagem, xNumLoteAux, xSequenciaAux);
              
         IF (@Resultado <> 1) THEN
            #Forçar erro; Abortar rotina
            SET @Teste = 1/0;
         ELSE
         
            SET xFragmentou = TRUE;         
            
            #Atualiza flag Processado tabela temporária (Lote Original "Processado")
            UPDATE tbTMPTransferencia 
            #SET Processado = 0
            SET saldo_est  = saldo_est  - xSaldoQtde,
                saldo_peso = saldo_peso - xSaldoPLiq
            WHERE cod_emp  = xCodEmp
              AND cod_fil  = xCodFil
              AND num_lote = xNumLote
              AND sequencia_lote = xSequenciaLote;
                
            #Insere novo lote Fragmentado na tabela temporária, é o registro 
            #que será processado para atender a movimentação
            INSERT INTO tbTMPTransferencia (cod_emp, cod_fil, num_lote, sequencia_lote, 
                      fator_conv, emb_vol, emb_frac, emb_nf, vlr_unitario, vlr_unitario_nf,  
                      flg_tipo_vlr, data_fabr, data_valid, status_lote,
                      saldo_est, saldo_vol, saldo_frac, saldo_peso,
                      Processado)
               (SELECT xCodEmp, xCodFil, xNumLoteAux, xSequenciaAux, 
                       fator_conv, emb_vol, emb_frac, emb_nf, vlr_unitario, vlr_unitario_nf, 
                       flg_tipo_vlr, data_fabr, data_valid, status_lote,
                       sld_fisico_est - IFNULL(qtd_emp_est,0) saldo_est, 
                       sld_fisico_vol - IFNULL(qtd_emp_vol,0) saldo_vol, 
                       sld_fisico_frac- IFNULL(qtd_emp_frac,0) saldo_frac, 
                       sld_fisico_peso- IFNULL(qtd_emp_peso,0) saldo_peso, 
                       0
                FROM tbwms_estoque
                WHERE cod_emp  = xCodEmp
                  AND cod_emp  = xCodFil
                  AND num_lote = xNumLoteAux
                  AND sequencia_lote = xSequenciaAux); 
            
         END IF;         
         
         SET xNumLote       = xNumLoteAux;
         SET xSequenciaLote = xSequenciaAux;
         SET xQtdeATransf   = xSaldoQtde;
         
      END IF;
            
      
      #Insere movimento de alteração de Status
      INSERT INTO of_logistica.tbwms_manut_lote
         (cod_emp, cod_fil, num_lote, sequencia_lote, dthr_inc, usu_inc, 
          fator_conv_ant, emb_vol_ant, emb_frac_ant, emb_nf_ant, 
          vlr_unitario_ant, flg_tipo_vlr_ant, data_fabricacao_ant, data_validade_ant, cod_status_ant, 
          fator_conv, emb_vol, emb_frac, emb_nf, vlr_unitario, vlr_unitario_nf, flg_tipo_vlr, observacao,  
          data_fabricacao, data_validade, cod_status, 
          observ) 
          (SELECT cod_emp, cod_fil, num_lote, sequencia_lote, NOW(), '999999', 
                  fator_conv, emb_vol, emb_frac, emb_nf, vlr_unitario, flg_tipo_vlr, data_fabr, data_valid, status_lote, 
                  fator_conv, emb_vol, emb_frac, emb_nf, vlr_unitario, vlr_unitario_nf, flg_tipo_vlr, 
                  "Movimentação automática - Serviço OOne_IntegraSAP_Transf_Ecom",
                  data_fabr, data_valid, xStatusDestino, 
                  CONCAT("Transf Aut E-Comm. Saldo=",xSaldoQtde)
           FROM of_logistica.tbwms_estoque
           WHERE cod_emp = xCodEmp
           AND cod_fil   = xCodFil
           AND num_lote  = xNumLote
           AND sequencia_lote = xSequenciaLote);
           
           
      #Atualiza Status na tabela de estoque
      UPDATE of_logistica.tbwms_estoque
      SET status_lote = xStatusDestino
      WHERE cod_emp   = xCodEmp
        AND cod_fil   = xCodFil
        AND num_lote  = xNumLote
        AND sequencia_lote = xSequenciaLote;
        
        
      #Atualiza flag Processado tabela temporária
      UPDATE tbTMPTransferencia 
      SET Processado = 1
      WHERE cod_emp  = xCodEmp
        AND cod_fil  = xCodFil
        AND num_lote = xNumLote
        AND sequencia_lote = xSequenciaLote;
        
      #Atualiza Variável de controle de Saldo  
      SET xSaldoQtde = xSaldoQtde - xQtdeATransf;
            
      #Força Finalização do Loop (Processado = 2 => Finalização forçada)
      IF (xSaldoQtde = 0) THEN
         UPDATE tbTMPTransferencia 
         SET Processado = 2
         WHERE cod_emp  = xCodEmp
           AND cod_fil  = xCodFil
           AND Processado = 0;
         #  AND num_lote = xNumLote
         #  AND sequencia_lote = xSequenciaLote;
      END IF;
                   
   END WHILE;
   
   
   /****************************************************************/
   /******** FINALIZA PROCEDURE E ENVIA RETORNO
   /****************************************************************/
   SET RESULTADO = 1;
   SET mensagem = "Transferencia realizada com sucesso";
   COMMIT;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_GravarPicking.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_GravarPicking`$$

CREATE PROCEDURE `PROC_INTEGRA_GravarPicking`(
	IN oDocEntry          VARCHAR(10),
	IN oDocTipo           VARCHAR(10),
	IN oIdPicking         VARCHAR(10),
	IN oPkLineNum         VARCHAR(10),
	IN oDocLineNum        VARCHAR(10),
	
	# Parametros de Retorno
	OUT RESULTADO         VARCHAR(5),
	OUT MENSAGEM          VARCHAR(500)
)
BLOCO1:BEGIN
   /****************************************************************
   #Create David Ruy 
   #Reviser David Ruy <2022-01-14 Update tbintegraSAP_Doc->U_RSD_RplOrder
   #Reviser David Ruy <2026-07-29 Update tbintegraSAP_DocItem->LineNumPk = oPkLineNum
   *****************************************************************/
	DECLARE xIncAlt      VARCHAR(01)	DEFAULT 'I';
	DECLARE excecao      INT DEFAULT 0;
	DECLARE xDocNum      INT;
	#DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   SET RESULTADO = "1";
   SET MENSAGEM = "Atualização realizada com sucesso";
   
   SELECT DocNum INTO xDocNum FROM tbintegraSAP_Doc
   WHERE DocEntry = oDocEntry
     AND DocTipo  = oDocTipo;
     
   
   INSERT INTO tbintegraSAP_DocPicking (
         DocEntry, Doctipo, DocNum, IdPicking, PkLineNum, DocLineNum, dthr_inc)
   VALUES (oDocEntry, oDocTipo, xDocNum, oIdPicking, oPkLineNum, oDocLineNum, NOW());
   
   #2026-07-29
   UPDATE tbintegraSAP_DocItem
   SET LineNumPk = oPkLineNum
   WHERE DocEntry = oDocEntry
     AND DocTipo  = oDocTipo
     AND LineNum  = oDocLineNum;
     
   
   
   
   IF excecao = 1 THEN
      SET RESULTADO = "0";
      SET MENSAGEM = "Erro SQL - Verifique com o Administrador";
   END IF;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_INVENTARIO_TERCEIRO_ATUALIZAR_ITEM.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_INVENTARIO_TERCEIRO_ATUALIZAR_ITEM`$$

CREATE PROCEDURE `PROC_INTEGRA_INVENTARIO_TERCEIRO_ATUALIZAR_ITEM`(
   IN oCodUsuario				   VARCHAR(10),
   IN oIdInventario     VARCHAR(10),
   IN oItemCode         VARCHAR(30),
   IN oItemName         VARCHAR(100),
   IN oflg_series       TINYINT,
   IN oflg_lotes        TINYINT,
   IN oEmbVendas        VARCHAR(10),
   IN oFatorConvVendas  DECIMAL(18,6),
   IN oUnidadeCompras   VARCHAR(10),
   IN oFatorConvCompras DECIMAL(18,6),
   IN oEmbEstoque       VARCHAR(10),
   IN oBarCode          VARCHAR(200),
   IN oQtdeEstoque      DECIMAL(18,6),
   IN oValorUnitario    DECIMAL(18,6),
   IN oSerieFabr        VARCHAR(50),
   IN oNumLoteFabr      VARCHAR(50),
   IN oDataFabr         VARCHAR(20),
   IN oDataValid        VARCHAR(20),
   
   IN oQtdeItens        INT,
   IN oCountItens       INT,
	
	# Parametros de Retorno
	OUT RESULTADO          BOOLEAN,
	OUT MENSAGEM           VARCHAR(500)
)
BLOCO1:BEGIN
   /******************************************************************************
   @Author <David Ruy (OVERFLASH)>
   @Creation <2026-04-23>
   @Description Esta rotina insere itens e atualiza as tabelas tbwms_inventario_terceiro_produto e 
                tbwms_inventario_terceiro_produto_serie_lote para o controle de inventário em terceiros
   @Reviser <David Ruy (OVERFLASH)>
   @Description Ajuste no retorno da mensagem IFNULL
   *******************************************************************************/
  /****************************************************************/
  /****************DECLARAR VARIÁVEIS AUXILIARES
  /****************************************************************/
   DECLARE excecao                TINYINT DEFAULT 0;
   DECLARE xid_inventario_produto INT     DEFAULT 0;
   DECLARE xdthr_leitura_terceiro DATETIME;
   DECLARE xdthr_retorno_terceiro DATETIME;
   DECLARE xdthr_liberacao_contagem2 DATETIME;
   DECLARE xdata_final               DATETIME;
   DECLARE xVarLotesSeries           INT DEFAULT 0;
   DECLARE xQtdeItens                INT DEFAULT 0;
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       ROLLBACK;
   END;
   
   
   
   START TRANSACTION;
   
   SET RESULTADO = 1;
   SET MENSAGEM = "Inclusão do item realizado com sucesso !";
   
   
   
   #Busca dados do topo do inventário para validações
   SELECT dthr_leitura_terceiro, dthr_retorno_terceiro, data_final
   INTO xdthr_leitura_terceiro, xdthr_retorno_terceiro, xdata_final
   FROM of_logistica.tbwms_inventario_terceiro
   WHERE id_inventario = oIdInventario;
   
   
   #Validação de conclusão do inventário, não permite inserir mais itens
   IF (xdthr_retorno_terceiro IS NOT NULL) OR (xdata_final IS NOT NULL) THEN
      SET RESULTADO = 0;
      SET MENSAGEM  = CONCAT('Inventário já foi finalizado ! Data Finalização : ', IFNULL(xdata_final,'n/a'), ', Data Retorno : ', IFNULL(xdthr_retorno_terceiro,'n/a'));
      ROLLBACK;
      LEAVE bloco1;
   END IF;
   
   
   #Se 1o item, então limpa a base de produtos do inventário
   #pois pode ser importação de atualização de estoque contábil
   IF oQtdeItens = 1 THEN
      DELETE FROM of_logistica.tbwms_inventario_terceiro_produto_serie_lote tbLotes
      WHERE EXISTS (SELECT 1 FROM of_logistica.tbwms_inventario_terceiro_produto tbProd
                    WHERE tbLotes.id_inventario_produto = tbProd.id_inventario_produto
                      AND tbProd.id_inventario = oIdInventario);
      DELETE FROM of_logistica.tbwms_inventario_terceiro_produto
      WHERE id_inventario = oIdInventario;
   END IF;
   
   
   #Busca dados do Item do Inventário para validações
   SELECT id_inventario_produto, dthr_liberacao_contagem2 
   INTO xid_inventario_produto, xdthr_liberacao_contagem2
   FROM of_logistica.tbwms_inventario_terceiro_produto 
   WHERE id_inventario = oIdInventario
     AND cod_produto   = oItemCode;
     
     
     
   #Ajusta variáveis
   SET xVarLotesSeries = IF(oflg_lotes = 1, 2, IF(oflg_series = 1, 3, 1));
   SET oDataFabr  = IF(oDataFabr = '', NULL, oDataFabr);
   SET oDataValid = IF(oDataValid= '', NULL, oDataValid);
   
   
   
   #Insere/Atualiza ITEM     
   IF IFNULL(xid_inventario_produto,0) = 0 THEN
                  
      INSERT INTO of_logistica.tbwms_inventario_terceiro_produto (
                  id_inventario, cod_produto, descr_produto, 
                  barcode01, barcode02, barcode03, 
                  flg_controle_validade, flg_controle_estoque, 
                  flg_tipo_embalagem_valor, fator_conversao, vlr_unitario)
      VALUES (oIdInventario, oItemCode, oItemName, 
              oBarCode, NULL, NULL, 
              IF(oDataFabr IS NULL, 0, 1), /*Controle Validade */
              xVarLotesSeries, /*Controle Lote/Serie,Nenhum*/
              1, /*Valorização pela embalagem de estoque*/
              oFatorConvVendas, oValorUnitario);
              
   ELSEIF xdthr_liberacao_contagem2 IS NULL THEN
   
      SET RESULTADO = 1;
      SET MENSAGEM = "Alteração do item realizado com sucesso !";
      
      UPDATE of_logistica.tbwms_inventario_terceiro_produto 
      SET id_inventario              = oIdInventario, 
          cod_produto                = oItemCode, 
          descr_produto              = oItemName, 
          barcode01                  = oBarCode, 
          barcode02                  = NULL, 
          barcode03                  = NULL, 
          flg_controle_validade      = IF(oDataFabr IS NULL, 0, 1), /*Controle Validade */
          flg_controle_estoque       = xVarLotesSeries, /*Controle Lote/Serie,Nenhum*/
          flg_tipo_embalagem_valor   = 1, /*Valorização pela embalagem de estoque*/
          fator_conversao            = oFatorConvVendas, 
          vlr_unitario               = oValorUnitario
      WHERE id_inventario = oIdInventario
        AND cod_produto   = oItemCode;
       
   ELSE
   
      SET RESULTADO = 0;
      SET MENSAGEM  = CONCAT('2a contagem deste item já foi liberada - Atualização não realizada - Produto : ', oItemCode, ' - ', oItemName);
      ROLLBACK;
      LEAVE bloco1;   
      
   END IF;
   
   #Insere/Atualiza Lote/Série
   IF IFNULL(oSerieFabr,'') <> '' OR IFNULL(oNumLoteFabr,'') <> '' THEN
   
      SELECT id_inventario_produto INTO xid_inventario_produto
      FROM of_logistica.tbwms_inventario_terceiro_produto
      WHERE id_inventario = oIdInventario
       AND cod_produto    = oItemCode;
   
      IF NOT EXISTS (SELECT 1 FROM of_logistica.tbwms_inventario_terceiro_produto_serie_lote
                     WHERE id_inventario_produto = xid_inventario_produto
                       AND numero_serie          = oSerieFabr
                       AND numero_lote_fabr      = oNumLoteFabr) THEN
                     
         SET RESULTADO = 1;
         SET MENSAGEM = CONCAT(MENSAGEM, " Inclusão do lote/série realizado com sucesso !");
         INSERT INTO of_logistica.tbwms_inventario_terceiro_produto_serie_lote (
                id_inventario_produto, data_fabr, data_valid, 
                numero_lote_fabr, numero_serie, 
                embalagem_estoque, qtde_emb_estoque, 
                embalagem_secundaria, qtde_emb_secundaria)
         VALUES (xid_inventario_produto, oDataFabr, oDataValid, 
                 oNumLoteFabr, oSerieFabr,
                 oEmbEstoque, oQtdeEstoque,
                 oEmbVendas, NULL);
      ELSE
      
         SET RESULTADO = 1;
         SET MENSAGEM = CONCAT(MENSAGEM, " Alteração do lote/série realizado com sucesso !");
         UPDATE of_logistica.tbwms_inventario_terceiro_produto_serie_lote 
         SET data_fabr            = oDataFabr,  
             data_valid           = oDataValid, 
             numero_lote_fabr     = oNumLoteFabr, 
             numero_serie         = oSerieFabr,
             embalagem_estoque    = oEmbEstoque, 
             qtde_emb_estoque     = oQtdeEstoque,
             embalagem_secundaria = oEmbVendas, 
             qtde_emb_secundaria  = NULL
         WHERE id_inventario_produto = xid_inventario_produto
           AND numero_serie          = oSerieFabr
           AND numero_lote_fabr      = oNumLoteFabr;
      END IF;
   
   END IF;
   COMMIT;
   
   SELECT COUNT(*) INTO xQtdeItens 
   FROM of_logistica.tbwms_inventario_terceiro_produto_serie_lote tbLotes
   INNER JOIN of_logistica.tbwms_inventario_terceiro_produto tbProd ON
              tbProd.id_inventario_produto = tbLotes.id_inventario_produto
   WHERE tbProd.id_inventario = oIdInventario;
   
   #Checa QtdeTotal do parametro X Qtde efetivamente Inserida
   #Atualiza Status do Inventário (Leitura de Saldo Contábil concluída - Liberado para contagem)
   IF oCountItens = xQtdeItens  THEN
      UPDATE of_logistica.tbwms_inventario_terceiro
      SET dthr_leitura_terceiro = NOW()
      WHERE id_inventario = oIdInventario;
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT(MENSAGEM, " - Leitura Contábil concluída.");
   END IF;
   
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_INVENTARIO_TERCEIRO_LISTAR.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_INVENTARIO_TERCEIRO_LISTAR`$$

CREATE PROCEDURE `PROC_INTEGRA_INVENTARIO_TERCEIRO_LISTAR`(
   IN oTipoRetorno				   INT
)
BLOCO1:BEGIN
   /******************************************************************************
   @Author <David Ruy (OVERFLASH)>
   @Creation <2026-04-23>
   @Description Esta rotina Lista os inventários conforme o status de acordo com o parametro oTipoRetorno :
                0 - Aguardando Leitura do estoque Contábil
                1 - Em andamento 1a Contagem
                2 - Em andamento 2a Contagem
                3 - Em andamento 3a Contagem
                4 - Finalizado Não Retornado para SAP
                5 - Finalizado Retornado para SAP
   *******************************************************************************/
  /****************************************************************/
  /****************DECLARAR VARIÁVEIS AUXILIARES
  /****************************************************************/
   DECLARE excecao                TINYINT DEFAULT 0;
   
   IF oTipoRetorno = 0 THEN
      
      SELECT id_inventario, chave_terceiro, nome_terceiro, cnpj_cpf_cli, 
      data_inicio, data_final, dthr_leitura_terceiro, dthr_retorno_terceiro,
      flg_atualizar_terceiro, tipo_doc_terceiro_entrada, tipo_doc_terceiro_saida,
      chave_doc_terceiro_entrada, chave_doc_terceiro_saida
      FROM of_logistica.tbwms_inventario_terceiro
      WHERE dthr_leitura_terceiro IS NULL
      AND dthr_cancel IS NULL;
   
   ELSEIF oTipoRetorno = 1 THEN
   
      SELECT id_inventario, chave_terceiro, nome_terceiro, cnpj_cpf_cli, 
             data_inicio, data_final, dthr_leitura_terceiro, dthr_retorno_terceiro,
             flg_atualizar_terceiro, tipo_doc_terceiro_entrada, tipo_doc_terceiro_saida,
             chave_doc_terceiro_entrada, chave_doc_terceiro_saida,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario) QtdeItens,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario
                AND tbwms_inventario_terceiro_produto.dthr_liberacao_contagem2 IS NOT NULL) Qtde_1a_Contagem
      FROM of_logistica.tbwms_inventario_terceiro
      WHERE dthr_leitura_terceiro IS NOT NULL
        AND dthr_retorno_terceiro IS NULL
        AND data_final IS NULL
        AND dthr_cancel IS NULL
      HAVING Qtde_1a_Contagem < QtdeItens;
        
   ELSEIF oTipoRetorno = 2 THEN
   
      SELECT id_inventario, chave_terceiro, nome_terceiro, cnpj_cpf_cli, 
             data_inicio, data_final, dthr_leitura_terceiro, dthr_retorno_terceiro,
             flg_atualizar_terceiro, tipo_doc_terceiro_entrada, tipo_doc_terceiro_saida,
             chave_doc_terceiro_entrada, chave_doc_terceiro_saida,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario) QtdeItens,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario
                AND tbwms_inventario_terceiro_produto.dthr_liberacao_contagem2 IS NOT NULL) Qtde_1a_Contagem,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario
                AND tbwms_inventario_terceiro_produto.dthr_liberacao_contagem3 IS NULL) Qtde_2a_Contagem
      FROM of_logistica.tbwms_inventario_terceiro
      WHERE dthr_leitura_terceiro IS NOT NULL
        AND dthr_retorno_terceiro IS NULL
        AND data_final IS NULL
        AND dthr_cancel IS NULL
      HAVING Qtde_1a_Contagem = QtdeItens 
         AND Qtde_2a_Contagem < Qtde_1a_Contagem;
   ELSEIF oTipoRetorno = 3 THEN
   
      SELECT id_inventario, chave_terceiro, nome_terceiro, cnpj_cpf_cli, 
             data_inicio, data_final, dthr_leitura_terceiro, dthr_retorno_terceiro,
             flg_atualizar_terceiro, tipo_doc_terceiro_entrada, tipo_doc_terceiro_saida,
             chave_doc_terceiro_entrada, chave_doc_terceiro_saida,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario) QtdeItens,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario
                AND tbwms_inventario_terceiro_produto.dthr_liberacao_contagem2 IS NOT NULL) Qtde_1a_Contagem,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario
                AND tbwms_inventario_terceiro_produto.dthr_liberacao_contagem3 IS NOT NULL) Qtde_2a_Contagem
      FROM of_logistica.tbwms_inventario_terceiro
      WHERE dthr_leitura_terceiro IS NOT NULL
        AND dthr_retorno_terceiro IS NULL
        AND data_final IS NULL
        AND dthr_cancel IS NULL
      HAVING Qtde_1a_Contagem = QtdeItens 
         AND Qtde_2a_Contagem = Qtde_1a_Contagem;
   ELSEIF oTipoRetorno = 4 THEN
   
      SELECT id_inventario, chave_terceiro, nome_terceiro, cnpj_cpf_cli, 
             data_inicio, data_final, dthr_leitura_terceiro, dthr_retorno_terceiro,
             flg_atualizar_terceiro, tipo_doc_terceiro_entrada, tipo_doc_terceiro_saida,
             chave_doc_terceiro_entrada, chave_doc_terceiro_saida,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario) QtdeItens,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario
                AND tbwms_inventario_terceiro_produto.dthr_liberacao_contagem2 IS NOT NULL) Qtde_1a_Contagem,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario
                AND tbwms_inventario_terceiro_produto.dthr_liberacao_contagem3 IS NOT NULL) Qtde_2a_Contagem
      FROM of_logistica.tbwms_inventario_terceiro
      WHERE dthr_leitura_terceiro IS NOT NULL
        AND dthr_retorno_terceiro IS NULL
        AND data_final IS NOT NULL
        AND dthr_cancel IS NULL;
   
   
   ELSEIF oTipoRetorno = 5 THEN
      SELECT id_inventario, chave_terceiro, nome_terceiro, cnpj_cpf_cli, 
             data_inicio, data_final, dthr_leitura_terceiro, dthr_retorno_terceiro,
             flg_atualizar_terceiro, tipo_doc_terceiro_entrada, tipo_doc_terceiro_saida,
             chave_doc_terceiro_entrada, chave_doc_terceiro_saida,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario) QtdeItens,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario
                AND tbwms_inventario_terceiro_produto.dthr_liberacao_contagem2 IS NOT NULL) Qtde_1a_Contagem,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario
                AND tbwms_inventario_terceiro_produto.dthr_liberacao_contagem3 IS NOT NULL) Qtde_2a_Contagem
      FROM of_logistica.tbwms_inventario_terceiro
      WHERE dthr_leitura_terceiro IS NOT NULL
        AND dthr_retorno_terceiro IS NOT NULL
        AND data_final IS NOT NULL
        AND dthr_cancel IS NULL;
   ELSE
      SELECT 0 AS RESULTADO, "Opção incorreta - Selecione parametro de 0 à 5" AS MENSAGEM;
   
   END IF;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_INVENTARIO_TERCEIRO_LISTAR_AJUSTES.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_INVENTARIO_TERCEIRO_LISTAR_AJUSTES`$$

CREATE PROCEDURE `PROC_INTEGRA_INVENTARIO_TERCEIRO_LISTAR_AJUSTES`(
   IN oIdInventario    INT,
   IN oTipoAjuste      VARCHAR(10)    #Entrada/Saída
)
BLOCO1:BEGIN
   /******************************************************************************
   @Author <David Ruy (OVERFLASH)>
   @Creation <2026-04-23>
   @Description : Esta rotina Lista os itens com divergencia a maior no inventário
                  para que seja gerada a entrada de ajustes no ERP desejado
   *******************************************************************************/

  /****************************************************************/
  /****************DECLARAR VARIÁVEIS AUXILIARES
  /****************************************************************/
   DECLARE excecao                TINYINT DEFAULT 0;
   DECLARE xdthr_leitura_terceiro  DATETIME;
   DECLARE xdthr_retorno_terceiro  DATETIME;
   DECLARE xdata_final             DATETIME;
   DECLARE xtipo_doc_terceiro_entrada  VARCHAR(50);
   DECLARE xchave_doc_terceiro_entrada VARCHAR(50);
   DECLARE xtipo_doc_terceiro_saida    VARCHAR(50);
   DECLARE xchave_doc_terceiro_saida   VARCHAR(50);
   

   
   #Busca dados do topo do inventário para validações
   SELECT dthr_leitura_terceiro, dthr_retorno_terceiro, data_final, 
          tipo_doc_terceiro_entrada, chave_doc_terceiro_entrada,
          tipo_doc_terceiro_saida, chave_doc_terceiro_saida
   INTO xdthr_leitura_terceiro, xdthr_retorno_terceiro, xdata_final, 
        xtipo_doc_terceiro_entrada, xchave_doc_terceiro_entrada,
        xtipo_doc_terceiro_saida, xchave_doc_terceiro_saida
   FROM of_logistica.tbwms_inventario_terceiro
   WHERE id_inventario = oIdInventario;
   
   IF oTipoAjuste = 'Entrada' AND xchave_doc_terceiro_entrada IS NOT NULL THEN
      SELECT 0 AS RESULTADO, 
             CONCAT("Documento de Ajustes de Entrada do Inventário já foi gerado - ",
             xtipo_doc_terceiro_entrada,xchave_doc_terceiro_entrada) AS MENSAGEM;
      LEAVE bloco1;
   END IF;

   IF oTipoAjuste = 'Saída' AND xchave_doc_terceiro_saida IS NOT NULL THEN
      SELECT 0 AS RESULTADO, 
             CONCAT("Documento de Ajustes de Saída do Inventário já foi gerado - ",
             xtipo_doc_terceiro_saida,xchave_doc_terceiro_saida) AS MENSAGEM;
      LEAVE bloco1;
   END IF;

   
   IF oTipoAjuste = 'Entrada' THEN
      DROP TEMPORARY TABLE IF EXISTS tbTMP_Fech;
      CREATE TEMPORARY TABLE tbTMP_Fech
         SELECT chave_terceiro, nome_terceiro,
                tbProd.id_inventario, tbProd.cod_produto, tbProd.descr_produto, 
                tbAux.embalagem_estoque,
                tbFech.qtde_ajuste_entrada AS qtde_ajuste, tbProd.vlr_unitario,
                tbFech.id_inventario_fechamento
         FROM of_logistica.tbwms_inventario_terceiro_fechamento tbFech
         INNER JOIN of_logistica.tbwms_inventario_terceiro_produto_serie_lote tbAux ON 
                    tbAux.id_inventario_produto = tbFech.id_inventario_produto
         INNER JOIN of_logistica.tbwms_inventario_terceiro tbInventario ON
                    tbInventario.id_inventario = tbFech.id_inventario
         INNER JOIN of_logistica.tbwms_inventario_terceiro_produto tbProd ON
                    tbProd.id_inventario_produto = tbFech.id_inventario_produto
         WHERE tbFech.id_inventario = oIdInventario AND qtde_ajuste_entrada > 0;
         
         
      DROP TEMPORARY TABLE IF EXISTS tbTMP_FechLotes;
      CREATE TEMPORARY TABLE tbTMP_FechLotes
         SELECT tbFech.cod_produto, tbFech_SL.numero_lote_fabr, tbFech_SL.numero_serie, 
                tbFech_SL.data_fabr, tbFech_SL.data_valid, tbFech_SL.qtde_ajuste_entrada  AS qtde_ajuste
         FROM of_logistica.tbwms_inventario_terceiro_fechamento_serie_lote tbFech_SL
         INNER JOIN tbTMP_Fech tbFech ON
                    tbFech.id_inventario_fechamento = tbFech_SL.id_inventario_fechamento
         WHERE tbFech.id_inventario = oIdInventario
           AND tbFech_SL.qtde_ajuste_entrada > 0;
   END IF;
   

   IF oTipoAjuste = 'Saida' THEN
      DROP TEMPORARY TABLE IF EXISTS tbTMP_Fech;
      CREATE TEMPORARY TABLE tbTMP_Fech
         SELECT chave_terceiro, nome_terceiro,
                tbProd.id_inventario, tbProd.cod_produto, tbProd.descr_produto, 
                tbAux.embalagem_estoque,
                tbFech.qtde_ajuste_saida AS qtde_ajuste, tbProd.vlr_unitario,
                tbFech.id_inventario_fechamento
         FROM of_logistica.tbwms_inventario_terceiro_fechamento tbFech
         INNER JOIN of_logistica.tbwms_inventario_terceiro_produto_serie_lote tbAux ON 
                    tbAux.id_inventario_produto = tbFech.id_inventario_produto
         INNER JOIN of_logistica.tbwms_inventario_terceiro tbInventario ON
                    tbInventario.id_inventario = tbFech.id_inventario
         INNER JOIN of_logistica.tbwms_inventario_terceiro_produto tbProd ON
                    tbProd.id_inventario_produto = tbFech.id_inventario_produto
         WHERE tbFech.id_inventario = oIdInventario AND qtde_ajuste_saida > 0;
         
         
      DROP TEMPORARY TABLE IF EXISTS tbTMP_FechLotes;
      CREATE TEMPORARY TABLE tbTMP_FechLotes
         SELECT tbFech.cod_produto, tbFech_SL.numero_lote_fabr, tbFech_SL.numero_serie, 
                tbFech_SL.data_fabr, tbFech_SL.data_valid, tbFech_SL.qtde_ajuste_saida  AS qtde_ajuste
         FROM of_logistica.tbwms_inventario_terceiro_fechamento_serie_lote tbFech_SL
         INNER JOIN tbTMP_Fech tbFech ON
                    tbFech.id_inventario_fechamento = tbFech_SL.id_inventario_fechamento
         WHERE tbFech.id_inventario = oIdInventario
           AND tbFech_SL.qtde_ajuste_saida > 0;
   END IF;
   

   SELECT oTipoAjuste 'TipoAjuste', tbTMP_Fech.* FROM tbTMP_Fech;
   SELECT oTipoAjuste 'TipoAjuste', tbTMP_FechLotes.* FROM tbTMP_FechLotes;


   DROP TEMPORARY TABLE IF EXISTS tbTMP_Fech;
   DROP TEMPORARY TABLE IF EXISTS tbTMP_FechLotes;

   

END$$

DELIMITER ;



/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_LiberarStatusUAs.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_LiberarStatusUAs`$$

CREATE PROCEDURE `PROC_INTEGRA_LiberarStatusUAs`(
   oCodUsuario    VARCHAR(30),
   oDocTipo            VARCHAR(30),
   oDocEntry           VARCHAR(30),
   oDocNum             VARCHAR(30),
   # Parametros de Retorno
   OUT RESULTADO              INT,
   OUT MENSAGEM               VARCHAR(500)
)
BLOCO1:BEGIN
  /************************************************************************/
  # @Created David Ruy <2026/03/26>
  # Esta procedure atualiza as UA´s de uma GEM (Ordem de Produção) com status para Liberar conforme necessário
  # @Reviser David Ruy <2026-04-17> Desabilitado PROC_WMS_SAIDA_GERAR_ACONSELHAMENTO_TOTAL, foi alterado 
  #                                 para chamar de outra procedure
  /************************************************************************/
   DECLARE excecao 	INT(6) DEFAULT 0;
   DECLARE _RESULTADO INT DEFAULT 0;
   DECLARE _MENSAGEM  VARCHAR(500);
   DECLARE xCodEmp        VARCHAR(03);
   DECLARE xCodFil        VARCHAR(03);
   DECLARE xAnoSolic      VARCHAR(04);
   DECLARE xNumSolic      VARCHAR(10);
   DECLARE xNumItem       VARCHAR(06);
   DECLARE xItemCode      VARCHAR(30);
   
   DECLARE xDocTipo         VARCHAR(10);
   DECLARE xDocEntry        VARCHAR(30);
   DECLARE xDocNum          VARCHAR(30);
   DECLARE xChaveIntegracao VARCHAR(100);
   DECLARE xdthr_confirm    VARCHAR(20);
   DECLARE xCodigoStatus    VARCHAR(10);
   
   DECLARE xnum_lote        VARCHAR(10);
   DECLARE xsequencia_lote  TINYINT(03);
   DECLARE xCodEmpWMS       VARCHAR(03);
   DECLARE xCodFilWMS       VARCHAR(03);
   DECLARE xAnoSolicWMS     VARCHAR(04);
   DECLARE xNumSolicWMS     VARCHAR(10);   
   DECLARE xNumOrdemProducao  VARCHAR(10);   
   DECLARE xAny_OrdemProducao BOOLEAN  DEFAULT FALSE;
   
   #Verificar se tem transação nas procedures
   #Se tiver, lascou
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       IF xCodEmp IS NOT NULL THEN
          SET MENSAGEM  = of_logistica.fnMensagemExcecao(
             CONCAT('ERRO Atualização UA´s - GEM : ',CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',
             CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao," ",MENSAGEM) );
       ELSE
          SET MENSAGEM  = of_logistica.fnMensagemExcecao(
             CONCAT('ERRO Atualização UA´s : ',MENSAGEM) );
       END IF;
       SELECT MENSAGEM;
       ROLLBACK;
   END;  
   
   
   #Busca o Status "Próprio para Nomrla"
   #Isso serve para deixar "bloqueadas" as UA´s, até que o pedido com os lotes vinculados seja integrado
   SELECT cod_status INTO xCodigoStatus 
   FROM tbintegraSAP_DeParaStatus_Armazem
   WHERE descr_armazem = 'Normal';
   
   DROP TEMPORARY TABLE IF EXISTS tbTMPItems_OrdemProducao;
   #Se o oDocTipo = 'PV', buscar o documento de "PA000" com DocEntry_OrdemProducao
   IF oDocTipo = 'PV' THEN
   
      #Seleciona a CodEmp, CodFil, Anosolic, NumSolic da GSM do PV
      SELECT cod_emp, cod_fil, ano_solic, num_solic
      INTO xCodEmpWMS, xCodFilWMS, xAnoSolicWMS, xNumSolicWMS
      FROM tbintegraSAP_Doc
      WHERE DocTipo  = oDocTipo
        AND DocEntry = oDocEntry
        AND DocNum   = oDocNum;
   
      
      #Seleciona as linhas do PV que tenham Ordem de Produção Vinculadas   
      DROP TEMPORARY TABLE IF EXISTS tbTMPAux_OP;
      CREATE TEMPORARY TABLE tbTMPAux_OP 
         SELECT DocEntryOrdemProducao, DocNumOrdemProducao, SerialOrdemProducao
         FROM tbintegraSAP_DocItem
         WHERE DocTipo  = oDocTipo
           AND DocEntry = oDocEntry
           AND DocNum   = oDocNum
           AND DocEntryOrdemProducao IS NOT NULL;
           
      #Se tiver alguma linha, busca os documentos (cod_emp, cod_fil, ano_solic, num_solic) da entrada de PA
      #IF EXISTS (SELECT 1 FROM tbTMPAux_OP) THEN
         CREATE TEMPORARY TABLE tbTMPItems_OrdemProducao
            SELECT cod_emp, cod_fil, ano_solic, num_solic, DocEntryOrdemProducao, DocNumOrdemProducao, SerialOrdemProducao
            FROM tbintegraSAP_Doc
            INNER JOIN tbTMPAux_OP ON 
                       tbintegraSAP_Doc.DocTipo = 'PA000'
                   AND tbTMPAux_OP.DocEntryOrdemProducao = tbintegraSAP_Doc.DocEntry
                   AND tbTMPAux_OP.DocNumOrdemProducao   = tbintegraSAP_Doc.DocNum
            ;
      #END IF;
      DROP TEMPORARY TABLE IF EXISTS tbTMPAux_OP;
   END IF;
   
   
   IF oDocTipo = 'PA000' THEN
   
      #Buscar direto o documento da entrada (OP)
      CREATE TEMPORARY TABLE tbTMPItems_OrdemProducao
         SELECT tbintegraSAP_DocItem.cod_emp, tbintegraSAP_DocItem.cod_fil, tbintegraSAP_DocItem.ano_solic, tbintegraSAP_DocItem.num_solic, 
                tbintegraSAP_DocItem.DocEntryOrdemProducao, tbintegraSAP_DocItem.DocNumOrdemProducao, tbintegraSAP_DocItem.SerialOrdemProducao
         INTO xCodEmp, xCodFil, xAnoSolic, xNumSolic
         FROM tbintegraSAP_Doc
         INNER JOIN tbintegraSAP_DocItem ON 
                    tbintegraSAP_DocItem.DocTipo  = tbintegraSAP_Doc.DocTipo 
                AND tbintegraSAP_DocItem.DocEntry = tbintegraSAP_Doc.DocEntry
                AND tbintegraSAP_DocItem.DocNum   = tbintegraSAP_Doc.DocNum
         WHERE tbintegraSAP_DocItem.DocTipo  = oDocTipo
           AND tbintegraSAP_DocItem.DocEntry = oDocEntry
           AND tbintegraSAP_DocItem.DocNum   = oDocNum;
   
   END IF;
   
   #Debug
   #select * from tbTMPItems_OrdemProducao;
   #leave bloco1;
   
   #Leitura da Lista de PA´s para atualização dos status
   #Pode ter mais de uma OP ou seja, pode ter uma OP para cada linha do PV
   WHILE EXISTS (SELECT 1 FROM tbTMPItems_OrdemProducao) DO
   
      SELECT cod_emp, cod_fil, ano_solic, num_solic, DocNumOrdemProducao
      INTO xCodEmp, xCodFil, xAnoSolic, xNumSolic, xNumOrdemProducao
      FROM tbTMPItems_OrdemProducao
      LIMIT 1;
      
      #3) Lista UA´s referente OP vinculada ao PV
      #não pega UA empenhada, nem UA com o mesmo status_lote
      DROP TEMPORARY TABLE IF EXISTS tbTMP_UpdateStatusLotes;
      CREATE TEMPORARY TABLE tbTMP_UpdateStatusLotes
         SELECT cod_emp, cod_fil, num_lote, sequencia_lote, 0 AS Flag, status_lote
         FROM of_logistica.tbwms_estoque
         WHERE cod_emp    = xCodEmp
           AND cod_fil    = xCodFil
           AND ano_solic  = xAnoSolic
           AND num_solic  = xNumSolic
           AND sld_fisico_est > 0
           AND IFNULL(qtd_emp_est,0) = 0
           AND status_lote <> xCodigoStatus;
       
      #Debug    
      #select xCodigoStatus;
      #select * from tbTMP_UpdateStatusLotes;
      #leave bloco1;           
           
      WHILE EXISTS (SELECT 1 FROM tbTMP_UpdateStatusLotes WHERE Flag = 0 LIMIT 1) DO
         SELECT num_lote, sequencia_lote INTO xnum_lote, xsequencia_lote
         FROM tbTMP_UpdateStatusLotes WHERE Flag = 0 LIMIT 1;
         
         #Debug
         #select "Debug", xCodEmp, xCodFil, xnum_lote, xsequencia_lote, xCodigoStatus;
         #leave bloco1;
         
         
         
         #Executa alteração Status da UA
         CALL of_logistica.PROC_WMS_ARMAZEM_ALTERAR_STATUS_UA(xCodEmp, xCodFil, xnum_lote, xsequencia_lote,
              xCodigoStatus, CONCAT('Integração - Desbloqueio UA Reservada OP ',xNumOrdemProducao), '999999', NULL);
              
         UPDATE tbTMP_UpdateStatusLotes 
         SET Flag = 1
         WHERE num_lote = xnum_lote AND sequencia_lote = xsequencia_lote;
         
      END WHILE;
      
      DROP TEMPORARY TABLE IF EXISTS tbTMP_UpdateStatusLotes;
     
      DELETE FROM tbTMPItems_OrdemProducao
      WHERE cod_emp    = xCodEmp
        AND cod_fil    = xCodFil
        AND ano_solic  = xAnoSolic
        AND num_solic  = xNumSolic;
        
        
      SET xAny_OrdemProducao = TRUE;
            
   END WHILE;
   
   #Debug
   #select xAny_OrdemProducao, oDocTipo, xCodEmpWMS, xCodFilWMS, xAnoSolicWMS, xNumSolicWMS;
   #leave bloco1;
   
   IF excecao = 0 THEN
      COMMIT;
      SET RESULTADO = 1;
      IF MENSAGEM = "" THEN
         SET MENSAGEM = CONCAT('Atualização Status de UA´s Concluída com sucesso - GEM : ',CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao);
      ELSE
         SET MENSAGEM = CONCAT(MENSAGEM," | ",CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao);
      END IF;
   ELSE
      ROLLBACK;
      
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT('ERRO Atualização Status de UA´s - GEM : ',CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao);
      
      #Verificar Log
      #CALL PROC_INTEGRA_EnviarLog('999999',
      #       IF(oChavePedido IN ("PV","OP","TD-S","NS"), 'PROC_INTEGRA_GerarGSMItem', 'PROC_INTEGRA_GerarGEMItem'),
      #         CONCAT('NÃO Inserido/Atualizado ',oChavePedido,oDocEntry,'-',oNumPedido,' | ', xRefGuia, '| Prd:', xItemCode), "200", @M, @R, @M);      
   END IF;
   
      
      
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_LimparPicking.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_LimparPicking`$$

CREATE PROCEDURE `PROC_INTEGRA_LimparPicking`(
   IN oIdPicking       INT,
   # Parametros de Retorno
   OUT RESULTADO       INT,
   OUT MENSAGEM        VARCHAR(500)
)
BLOCO1:BEGIN
   /*
   #@Reviser David Ruy <2022/04/29> Concatenar IdPickingAnt para armazenar histórico de Pickings
   */
   
   
   DECLARE xQtdeRegs   INT DEFAULT 0;
   DECLARE excecao 	   INT DEFAULT 0;
   
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
   
   START TRANSACTION;
   
   
   UPDATE tbintegraSAP_Doc
   SET idPickingAnt = CONCAT(IFNULL(idPickingAnt,''),IF(idPickingAnt IS NULL, '','/'),idPicking),
       idPicking = NULL,
       StatusAnt = StatusDoc,
       StatusDoc = 7      #Processo de Atualização SAP (Divergencias dentro da tolerancia)
   WHERE idPicking = oIdPicking; 
 
    IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- Erro PROC_INTEGRA_LimparPicking");
      #SELECT RESULTADO, MENSAGEM;
      ROLLBACK;
   ELSE
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- PROC_INTEGRA_LimparPicking [",xQtdeRegs,"]");
      COMMIT;
   END IF;
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_ListarAlteracoes.sql*/

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

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_ListarContagem_GEM_GSM.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_ListarContagem_GEM_GSM`$$

CREATE PROCEDURE `PROC_INTEGRA_ListarContagem_GEM_GSM`(
   IN oFlgGerarListar    INT  #0=Gerar Contagens Integração/Criação, 1=Lista para Confirmação
)
BLOCO1:BEGIN
   #@Reviser David Ruy <2020/03/12> Arredondamento 3 casas decimais pois o SAP não suporta mais que 3 casas
   DECLARE xQtdeRegs     INT DEFAULT 0;
   DECLARE excecao 	     INT DEFAULT 0;
   DECLARE xDataHora     DATETIME DEFAULT NOW();
   DECLARE RESULTADO     INT;
   DECLARE MENSAGEM      VARCHAR(500) DEFAULT '';
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       ROLLBACK;
   END;
   
   
   START TRANSACTION;
   
   
   IF oFlgGerarListar = 0 THEN
   
      #Tabela temporária para atualizar retorno à integração
      DROP TEMPORARY TABLE IF EXISTS tbTMPGEM;
      CREATE TEMPORARY TABLE tbTMPGEM AS
         (SELECT "Entrada" AS TipoMovto, TopoEntrada.cod_emp, TopoEntrada.cod_fil, TopoEntrada.ano_solic, TopoEntrada.num_solic,
                 tbOperWMS.descr_oper_wms          
         FROM of_logistica.tbsolic_entradas TopoEntrada 
         INNER JOIN of_logistica.tbsys_integracao_operacao tbOper ON 
                     tbOper.cod_oper_wms = TopoEntrada.flg_tipo_oper
         INNER JOIN of_logistica.tbwms_tipo_oper tbOperWMS ON 
                     tbOperWMS.cod_oper_wms = TopoEntrada.flg_tipo_oper
         WHERE TopoEntrada.dthr_retorno_integracao IS NULL
           AND TopoEntrada.dthr_confirm IS NOT NULL
           AND TopoEntrada.chave_integracao IS NULL
         GROUP BY cod_emp, cod_fil, ano_solic, num_solic);
         
      DROP TEMPORARY TABLE IF EXISTS tbTMPGSM;
      CREATE TEMPORARY TABLE tbTMPGSM AS
         (SELECT "Saida" AS TipoMovto, TopoSaida.cod_emp, TopoSaida.cod_fil, TopoSaida.ano_solic, TopoSaida.num_solic,
                 tbOperWMS.descr_oper_wms 
         FROM of_logistica.tbsolic_saidas TopoSaida 
         INNER JOIN of_logistica.tbsys_integracao_operacao tbOper ON 
                     tbOper.cod_oper_wms = TopoSaida.flg_tipo_oper
         INNER JOIN of_logistica.tbwms_tipo_oper tbOperWMS ON 
                     tbOperWMS.cod_oper_wms = TopoSaida.flg_tipo_oper
         WHERE TopoSaida.dthr_retorno_integracao IS NULL
           AND TopoSaida.dthr_confirm IS NOT NULL
           AND TopoSaida.chave_integracao IS NULL
         GROUP BY cod_emp, cod_fil, ano_solic, num_solic);
         
      
      
      DROP TEMPORARY TABLE IF EXISTS tbTMPItemContagem;
      CREATE TEMPORARY TABLE tbTMPItemContagem AS
         (
         SELECT TipoMovto, Item.cod_emp, Item.cod_fil, Item.ano_solic, Item.num_solic, Item.num_item,
                        Item.cod_produto, IFNULL(tbEstoque.num_lote_cli,"") num_lote_cli,
                        tbEstoque.num_lote, tbEstoque.sequencia_lote,
                        SUM(tbEstoque.sld_fisico_est) QtdeEstoque,
                        tbArmazem.cod_armazem CodArmazemSAP, tbOperWMS.descr_oper_wms
         FROM of_logistica.tbsolic_entradas_item Item
         INNER JOIN of_logistica.tbsolic_entradas tbTopo ON
                     Item.cod_emp   = tbTopo.cod_emp
                 AND Item.cod_fil   = tbTopo.cod_fil
                 AND Item.ano_solic = tbTopo.ano_solic
                 AND Item.num_solic = tbTopo.num_solic
         INNER JOIN tbTMPGEM ON 
                     tbTMPGEM.cod_emp   = Item.cod_emp
                 AND tbTMPGEM.cod_fil   = Item.cod_fil
                 AND tbTMPGEM.ano_solic = Item.ano_solic
                 AND tbTMPGEM.num_solic = Item.num_solic
         INNER JOIN of_logistica.tbwms_estoque tbEstoque ON 
                     tbTopo.cod_emp       = tbEstoque.cod_emp
                 AND tbTopo.cod_fil       = tbEstoque.cod_fil
                 AND tbTopo.cnpj_cpf_cli  = tbEstoque.cnpj_cpf_cli
                 AND tbTopo.cod_estoque   = tbEstoque.cod_estoque
                 AND Item.cod_produto  = tbEstoque.cod_produto 
         INNER JOIN of_logistica.tbsys_integracao_operacao tbOper ON 
                     tbOper.cod_oper_wms = tbTopo.flg_tipo_oper
         INNER JOIN of_logistica.tbwms_tipo_oper tbOperWMS ON 
                     tbOperWMS.cod_oper_wms = tbTopo.flg_tipo_oper
         INNER JOIN tbintegraSAP_DeParaStatus_Armazem tbArmazem ON
                     tbArmazem.cod_status = tbEstoque.status_lote
         GROUP BY CodArmazemSAP, tbEstoque.cod_produto, IFNULL(tbEstoque.num_lote_cli,tbEstoque.data_valid))
         UNION
         (SELECT TipoMovto, Item.cod_emp, Item.cod_fil, Item.ano_solic, Item.num_solic, Item.num_item,
                        Item.cod_produto, IFNULL(tbEstoque.num_lote_cli,"") num_lote_cli,
                        tbEstoque.num_lote, tbEstoque.sequencia_lote,
                        SUM(tbEstoque.sld_fisico_est) QtdeEstoque,
                        tbArmazem.cod_armazem CodArmazemSAP, tbOperWMS.descr_oper_wms
         FROM of_logistica.tbsolic_saidas_item Item
         INNER JOIN of_logistica.tbsolic_saidas tbTopo ON
                     Item.cod_emp   = tbTopo.cod_emp
                 AND Item.cod_fil   = tbTopo.cod_fil
                 AND Item.ano_solic = tbTopo.ano_solic
                 AND Item.num_solic = tbTopo.num_solic
         INNER JOIN tbTMPGSM ON 
                     tbTMPGSM.cod_emp   = Item.cod_emp
                 AND tbTMPGSM.cod_fil   = Item.cod_fil
                 AND tbTMPGSM.ano_solic = Item.ano_solic
                 AND tbTMPGSM.num_solic = Item.num_solic
         INNER JOIN of_logistica.tbwms_estoque tbEstoque ON 
                     tbTopo.cod_emp       = tbEstoque.cod_emp
                 AND tbTopo.cod_fil       = tbEstoque.cod_fil
                 AND tbTopo.cnpj_cpf_cli  = tbEstoque.cnpj_cpf_cli
                 AND tbTopo.cod_estoque   = tbEstoque.cod_estoque
                 AND Item.cod_produto  = tbEstoque.cod_produto 
         INNER JOIN of_logistica.tbsys_integracao_operacao tbOper ON 
                     tbOper.cod_oper_wms = tbTopo.flg_tipo_oper
         INNER JOIN of_logistica.tbwms_tipo_oper tbOperWMS ON 
                     tbOperWMS.cod_oper_wms = tbTopo.flg_tipo_oper
         INNER JOIN tbintegraSAP_DeParaStatus_Armazem tbArmazem ON
                     tbArmazem.cod_status = tbEstoque.status_lote
         GROUP BY CodArmazemSAP, tbEstoque.cod_produto, IFNULL(tbEstoque.num_lote_cli,tbEstoque.data_valid));
         
         
      INSERT INTO tbintegraSAP_ContagemTopo (
              Id, 
              Reference,
              CountingDate,
              TipoDocSLIN,
              cod_emp,
              cod_fil,	
              ano_solic,
              num_solic,
              observacoes,   
              dthr_inc) 
          (SELECT 0, CONCAT(descr_oper_wms," ",
               CAST(cod_emp AS UNSIGNED),"/",CAST(cod_fil AS UNSIGNED),"|",ano_solic,"-",CAST(num_solic AS UNSIGNED)),
               xDataHora, 
               SUBSTRING(TipoMovto,1,1),
               cod_emp, cod_fil, ano_solic, num_solic, 
               TipoMovto, xDataHora
           FROM tbTMPGEM)
           UNION 
          (SELECT 0, CONCAT(descr_oper_wms," ",
               CAST(cod_emp AS UNSIGNED),"/",CAST(cod_fil AS UNSIGNED),"|",ano_solic,"-",CAST(num_solic AS UNSIGNED)),
               xDataHora, 
               SUBSTRING(TipoMovto,1,1),
               cod_emp, cod_fil, ano_solic, num_solic, 
               TipoMovto, xDataHora
           FROM tbTMPGSM);
           
      
      INSERT INTO tbintegraSAP_ContagemItens (
              TipoDocSLIN,
              cod_emp,
              cod_fil,	
              ano_solic,
              num_solic,
              num_item, 
              ItemCode,
              WarehouseCode,
              BinCode,
              BatchNumber_Code,
              BatchNumber_Quantity,
              SerialNumber_ManufactureCode,
              ContedQuantity)
       (SELECT SUBSTRING(TipoMovto,1,1), 
         tbTMPItemContagem.cod_emp, tbTMPItemContagem.cod_fil, tbTMPItemContagem.ano_solic, tbTMPItemContagem.num_solic, 
         tbTMPItemContagem.num_item, tbTMPItemContagem.cod_produto, tbTMPItemContagem.CodArmazemSAP, "BinCode", 
         tbTMPItemContagem.num_lote_cli, CAST(tbTMPItemContagem.QtdeEstoque AS DECIMAL(18,3)), NULL,
         CAST(tbTMPItemContagem.QtdeEstoque AS DECIMAL(18,3))
      FROM tbTMPItemContagem
      WHERE tbTMPItemContagem.QtdeEstoque IS NOT NULL
      #GROUP BY TipoMovto, cod_emp, cod_fil, ano_solic, num_solic, num_item, cod_produto, num_lote_cli
      #ORDER BY TipoMovto, cod_emp, cod_fil, ano_solic, num_solic, num_item, cod_produto, num_lote_cli);
      GROUP BY TipoMovto, cod_emp, cod_fil, ano_solic, num_solic, num_item, cod_produto, CodArmazemSAP, num_lote_cli 
      ORDER BY TipoMovto, cod_emp, cod_fil, ano_solic, num_solic, num_item, cod_produto, CodArmazemSAP, num_lote_cli);
      
      SET xQtdeRegs = ROW_COUNT();
         
      #Atualiza TBSOLIC_ENTRADAS
      UPDATE of_logistica.tbsolic_entradas tbEntradas
      INNER JOIN tbTMPGEM ON 
            tbTMPGEM.cod_emp   = tbEntradas.cod_emp
        AND tbTMPGEM.cod_fil   = tbEntradas.cod_fil
        AND tbTMPGEM.ano_solic = tbEntradas.ano_solic
        AND tbTMPGEM.num_solic = tbEntradas.num_solic
      SET tbEntradas.dthr_retorno_integracao = xDataHora
      WHERE tbTMPGEM.TipoMovto = "Entrada";
      
      #Atualiza TBSOLIC_SAIDAS
      UPDATE of_logistica.tbsolic_saidas tbSaidas
      INNER JOIN tbTMPGSM ON 
            tbTMPGSM.cod_emp   = tbSaidas.cod_emp
        AND tbTMPGSM.cod_fil   = tbSaidas.cod_fil
        AND tbTMPGSM.ano_solic = tbSaidas.ano_solic
        AND tbTMPGSM.num_solic = tbSaidas.num_solic
      SET tbSaidas.dthr_retorno_integracao = xDataHora
      WHERE tbTMPGSM.TipoMovto = "Saida";
      
      #SELECT * FROM tbTMPItemContagem
      #ORDER BY TipoMovto, cod_emp, cod_fil, ano_solic, num_solic, cod_produto, num_lote_cli;
      DROP TEMPORARY TABLE IF EXISTS tbTMPGEM;
      DROP TEMPORARY TABLE IF EXISTS tbTMPGSM;
      DROP TEMPORARY TABLE IF EXISTS tbTMPItemContagem;
      
   END IF;
   
   
   #Topos da Contagem         
   SELECT  id IdContagem, Reference, CountingDate, CONCAT(TipoDocSLIN, cod_emp, cod_fil, ano_solic, num_solic) AS NumDocSLIN
          ,RESULTADO AS resultado, CONCAT(TipoDocSLIN, cod_emp, cod_fil, ano_solic, num_solic) AS mensagem
   FROM tbintegraSAP_ContagemTopo Topo
   WHERE IF(oFlgGerarListar = 0, id = 0, id > 0 AND Topo.dthr_retorno_integracao IS NULL)
   GROUP BY NumDocSlin;
   
   #Itens (Entradas) das Contagens
   SELECT CONCAT(Topo.TipoDocSLIN, Itens.cod_emp, Itens.cod_fil, Itens.ano_solic, Itens.num_solic) AS NumDocSLIN, 
          Itens.num_item, ItemCode, WarehouseCode, BinCode, SUM(ContedQuantity) AS ContedQuantity,
          tbProd.flg_obriga_lote_fornecedor
   FROM tbintegraSAP_ContagemItens Itens
   INNER JOIN tbintegraSAP_ContagemTopo Topo ON
        Topo.TipoDocSLIN = Itens.TipoDocSLIN
    AND Topo.cod_emp     = Itens.cod_emp
    AND Topo.cod_fil     = Itens.cod_fil
    AND Topo.ano_solic   = Itens.ano_solic
    AND Topo.num_solic   = Itens.num_solic
   LEFT JOIN of_logistica.tbsolic_entradas_item tbItens ON 
             tbItens.cod_emp   = Itens.cod_emp
         AND tbItens.cod_fil   = Itens.cod_fil
         AND tbItens.ano_solic = Itens.ano_solic
         AND tbItens.num_solic = Itens.num_solic
         AND tbItens.num_item  = Itens.num_item
   LEFT JOIN of_logistica.tbprodutos tbProd ON 
           tbProd.cnpj_cpf    = tbItens.cnpj_cpf_dep
       AND tbProd.cod_produto = tbItens.cod_produto
   WHERE Itens.TipoDocSLIN = "E" 
     AND IF(oFlgGerarListar = 0, id = 0, id > 0 AND Topo.dthr_retorno_integracao IS NULL)
   GROUP BY NumDocSlin, ItemCode, WarehouseCode
      
   UNION
   
   #Itens (Saídas) das Contagens
   SELECT CONCAT(Topo.TipoDocSLIN, Itens.cod_emp, Itens.cod_fil, Itens.ano_solic, Itens.num_solic) AS NumDocSLIN, 
          Itens.num_item, ItemCode, WarehouseCode, BinCode, SUM(ContedQuantity) AS ContedQuantity,
          tbProd.flg_obriga_lote_fornecedor
   FROM tbintegraSAP_ContagemItens Itens
   INNER JOIN tbintegraSAP_ContagemTopo Topo ON
        Topo.TipoDocSLIN = Itens.TipoDocSLIN
    AND Topo.cod_emp     = Itens.cod_emp
    AND Topo.cod_fil     = Itens.cod_fil
    AND Topo.ano_solic   = Itens.ano_solic
    AND Topo.num_solic   = Itens.num_solic
   LEFT JOIN of_logistica.tbsolic_saidas_item tbItens ON 
             tbItens.cod_emp   = Itens.cod_emp
         AND tbItens.cod_fil   = Itens.cod_fil
         AND tbItens.ano_solic = Itens.ano_solic
         AND tbItens.num_solic = Itens.num_solic
         AND tbItens.num_item  = Itens.num_item
   LEFT JOIN of_logistica.tbprodutos tbProd ON 
           tbProd.cnpj_cpf    = tbItens.cnpj_cpf_dep
       AND tbProd.cod_produto = tbItens.cod_produto
   WHERE Itens.TipoDocSLIN = "S" AND id = 0
   GROUP BY NumDocSlin, ItemCode, WarehouseCode;
   
   
   
   
   IF oFlgGerarListar = 0 THEN
      SELECT COUNT(1) INTO xQtdeRegs
      FROM tbintegraSAP_ContagemItens Itens
      INNER JOIN tbintegraSAP_ContagemTopo Topo ON
           Topo.TipoDocSLIN = Itens.TipoDocSLIN
       AND Topo.cod_emp     = Itens.cod_emp
       AND Topo.cod_fil     = Itens.cod_fil
       AND Topo.ano_solic   = Itens.ano_solic
       AND Topo.num_solic   = Itens.num_solic
      WHERE id = 0;
   END IF;
   
   #Lotes das Contagens
   SELECT CONCAT(Topo.TipoDocSLIN, Itens.cod_emp, Itens.cod_fil, Itens.ano_solic, Itens.num_solic) AS NumDocSLIN, 
         Itens.num_item, ItemCode, WarehouseCode,   
         BatchNumber_Code, SUM(BatchNumber_Quantity) AS BatchNumber_Quantity            
   FROM tbintegraSAP_ContagemItens Itens
   INNER JOIN tbintegraSAP_ContagemTopo Topo ON
        Topo.TipoDocSLIN = Itens.TipoDocSLIN
    AND Topo.cod_emp     = Itens.cod_emp
    AND Topo.cod_fil     = Itens.cod_fil
    AND Topo.ano_solic   = Itens.ano_solic
    AND Topo.num_solic   = Itens.num_solic      
   WHERE IF(oFlgGerarListar=0,id = 0, id > 0 AND Topo.dthr_retorno_integracao IS NULL)
   #WHERE id = 0
   GROUP BY NumDocSlin, ItemCode, WarehouseCode, BatchNumber_Code;           
   
            
   SET RESULTADO = 0;
   #SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- (PROC_INTEGRA_ListarContagem_GEM_GSM) Contagens Listadas com sucesso");
   IF excecao = 1 THEN
      ROLLBACK;
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- Erro PROC_INTEGRA_ListarContagem_GEM_GSM");
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      COMMIT;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,"")," (PROC_INTEGRA_ListarContagem_GEM_GSM) Contagens Geradas com sucesso [",xQtdeRegs,']');
   END IF;
   
   SELECT RESULTADO, MENSAGEM;
   
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_ListarDepositos.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_ListarDepositos`$$

CREATE PROCEDURE PROC_INTEGRA_ListarDepositos(
   IN xDeposito VARCHAR(30)
)   
BLOCO1:BEGIN
   /*******************************************************************************************
   #@Author David Ruy <2023-01-07>
   ********************************************************************************************/
   
   SELECT * FROM of_logistica.tbstatus_lotes
   LEFT JOIN of_logistica.tbstatus_lotes_integracao ON
             tbstatus_lotes_integracao.codigo_status = tbstatus_lotes.codigo
   WHERE tbstatus_lotes.flg_ativo = 1 
     AND (tbstatus_lotes_integracao.deposito_integracao = xDeposito
      OR  tbstatus_lotes.deposito_integracao = xDeposito);
      
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_ListarDocumento.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_ListarDocumento`$$

CREATE PROCEDURE `PROC_INTEGRA_ListarDocumento`(
   IN oDocTipo  				VARCHAR(10),
   IN oDocNum       INT,
   IN oDocEntry     INT,
   IN oIdPicking    INT
)
BLOCO1:BEGIN
   /*******************************************************************************************
   #@Author David Ruy <2021-01-15>
   #@Reviser David Ruy <2023-07-25> Ajuste condição oDocTipo like "PA%"
   #@Reviser David Ruy <2023-10-11> Ajuste condição AND (tbEntradasAcons.qtde_est > 0 OR tbEntradasAcons.qtde_est2 > 0);
   #@Reviser David Ruy <2023-10-11> Ajuste condição AND (tbSaidasAcons.qtde_est > 0 OR tbSaidasAcons.qtde_est2 > 0);
   #@Reviser David Ruy <2024-06-24> Melhora na condição if(parametro is null, true, campo = parametro
   #@Reviser David Ruy <2025-01-10> DocTipo = 'DC'  Devolução de Compras
   #@Reviser David Ruy <2025-04-04> join tbprodutos para campos de embalagens : tbEntradasItem.emb_est, emb_estoque_cli, fator_conv_vendas (Entradas)
   #@Reviser David Ruy <2026-04-07> join tbprodutos para campos de embalagens : tbEntradasItem.emb_est, emb_estoque_cli, fator_conv_vendas (Saídas)
   ********************************************************************************************/
   
   DECLARE xcnpj_cpf_cli   VARCHAR(20);
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   
   
   SELECT cnpj_cpf_cli INTO xcnpj_cpf_cli 
   FROM tbintegraSAP_parametros;
   
    
      
    IF oDocTipo IN ('PV','TD-S','OP','DC') THEN
      
       SELECT DocNum, DocEntry, IdPicking
       INTO oDocNum, oDocEntry, oIdPicking
       FROM tbintegraSAP_Doc
       LEFT JOIN of_logistica.tbsolic_saidas tbSaidas ON
             tbSaidas.cod_emp   = tbintegraSAP_Doc.cod_emp
         AND tbSaidas.cod_fil   = tbintegraSAP_Doc.cod_fil
         AND tbSaidas.ano_solic = tbintegraSAP_Doc.ano_solic
         AND tbSaidas.num_solic = tbintegraSAP_Doc.num_solic
       WHERE DocTipo = oDocTipo
         AND (DocEntry = oDocEntry); # OR DocNum = oDocNum OR idPicking=oIdPicking);
       SELECT tbintegraSAP_Doc.*, IFNULL(tbSaidas.cnpj_cpf_cli,xcnpj_cpf_cli) cnpj_cpf_cli
             ,tbSaidas.num_nf, tbSaidas.data_nf, tbSaidas.data_solic
             #,tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic
             ,tbSaidas.status_processo StatusDocWMS
             ,of_logistica.fnStatusProcessoWms(tbSaidas.status_processo) StatusDescrWMS
             ,tbSaidas.observ_solic
       FROM tbintegraSAP_Doc
       LEFT JOIN of_logistica.tbsolic_saidas tbSaidas ON
             tbSaidas.cod_emp   = tbintegraSAP_Doc.cod_emp
         AND tbSaidas.cod_fil   = tbintegraSAP_Doc.cod_fil
         AND tbSaidas.ano_solic = tbintegraSAP_Doc.ano_solic
         AND tbSaidas.num_solic = tbintegraSAP_Doc.num_solic
       WHERE DocTipo = oDocTipo
         AND IF(oDocNum IS NULL, TRUE, DocNum = oDocNum)
         AND IF(oDocEntry IS NULL, TRUE, DocEntry = oDocEntry)
         AND IF(oIdPicking IS NULL, TRUE, idPicking = oIdPicking);
         
         
       SELECT tbintegraSAP_DocItem.*, tbSaidasItem.real_est3, tbSaidasItem.emb_est, emb_estoque_cli, fator_conv_vendas
       FROM tbintegraSAP_DocItem
       LEFT JOIN of_logistica.tbsolic_saidas_item tbSaidasItem ON
             tbSaidasItem.cod_emp   = tbintegraSAP_DocItem.cod_emp
         AND tbSaidasItem.cod_fil   = tbintegraSAP_DocItem.cod_fil
         AND tbSaidasItem.ano_solic = tbintegraSAP_DocItem.ano_solic
         AND tbSaidasItem.num_solic = tbintegraSAP_DocItem.num_solic
         AND tbSaidasItem.num_item  = tbintegraSAP_DocItem.num_item
       INNER JOIN of_logistica.tbprodutos ON 
                  tbprodutos.cnpj_cpf = tbSaidasItem.cnpj_cpf_dep
              AND tbprodutos.cod_produto = tbSaidasItem.cod_produto
       WHERE tbintegraSAP_DocItem.DocTipo = oDocTipo
         AND tbintegraSAP_DocItem.DocNum = oDocNum 
         AND tbintegraSAP_DocItem.DocEntry = oDocEntry;
         
       SELECT tbSaidasAcons.*, tbintegraSAP_DocItem.LineNum,
              tbEstoque.num_lote_cli NumLoteCli
       FROM tbintegraSAP_DocItem
       LEFT JOIN of_logistica.tbsolic_saidas_item tbSaidasItem ON
             tbSaidasItem.cod_emp   = tbintegraSAP_DocItem.cod_emp
         AND tbSaidasItem.cod_fil   = tbintegraSAP_DocItem.cod_fil
         AND tbSaidasItem.ano_solic = tbintegraSAP_DocItem.ano_solic
         AND tbSaidasItem.num_solic = tbintegraSAP_DocItem.num_solic
         AND tbSaidasItem.num_item  = tbintegraSAP_DocItem.num_item
       INNER JOIN of_logistica.tbsolic_saidas_acons tbSaidasAcons ON
                 tbSaidasAcons.cod_emp   = tbSaidasItem.cod_emp
             AND tbSaidasAcons.cod_fil   = tbSaidasItem.cod_fil
             AND tbSaidasAcons.ano_solic = tbSaidasItem.ano_solic
             AND tbSaidasAcons.num_solic = tbSaidasItem.num_solic
             AND tbSaidasAcons.num_item  = tbSaidasItem.num_item
       INNER JOIN of_logistica.tbwms_estoque tbEstoque ON 
                  tbEstoque.cod_emp = tbSaidasAcons.cod_emp
              AND tbEstoque.cod_fil = tbSaidasAcons.cod_fil
              AND tbEstoque.num_lote = tbSaidasAcons.num_lote
              AND tbEstoque.sequencia_lote = tbSaidasAcons.sequencia_lote
       WHERE tbintegraSAP_DocItem.DocTipo = oDocTipo
         AND tbintegraSAP_DocItem.DocNum = oDocNum 
         AND tbintegraSAP_DocItem.DocEntry = oDocEntry
         AND (tbSaidasAcons.qtde_est > 0 OR tbSaidasAcons.qtde_est2 > 0);
         
         
   ELSEIF oDocTipo IN ('DV','NE','E-NE','E-RM','TD-E','PA') OR (oDocTipo LIKE  'PA%')THEN
       SELECT DocNum, DocEntry, IdPicking
       INTO oDocNum, oDocEntry, oIdPicking
       FROM tbintegraSAP_Doc
       LEFT JOIN of_logistica.tbsolic_entradas tbEntradas ON
             tbEntradas.cod_emp   = tbintegraSAP_Doc.cod_emp
         AND tbEntradas.cod_fil   = tbintegraSAP_Doc.cod_fil
         AND tbEntradas.ano_solic = tbintegraSAP_Doc.ano_solic
         AND tbEntradas.num_solic = tbintegraSAP_Doc.num_solic
       WHERE DocTipo = oDocTipo
         AND (DocEntry = oDocEntry); # OR DocNum = oDocNum OR idPicking=oIdPicking);
       SELECT tbintegraSAP_Doc.*, IFNULL(tbEntradas.cnpj_cpf_cli,xcnpj_cpf_cli) cnpj_cpf_cli
             ,tbEntradas.num_nf, tbEntradas.data_nf, tbEntradas.data_solic
             #,tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic
             ,tbEntradas.status_processo StatusDocWMS
             ,of_logistica.fnStatusProcessoWms(tbEntradas.status_processo) StatusDescrWMS
             ,tbEntradas.observ_solic
       FROM tbintegraSAP_Doc
       LEFT JOIN of_logistica.tbsolic_entradas tbEntradas ON
             tbEntradas.cod_emp   = tbintegraSAP_Doc.cod_emp
         AND tbEntradas.cod_fil   = tbintegraSAP_Doc.cod_fil
         AND tbEntradas.ano_solic = tbintegraSAP_Doc.ano_solic
         AND tbEntradas.num_solic = tbintegraSAP_Doc.num_solic
       WHERE DocTipo = oDocTipo
         AND DocNum = oDocNum
         AND DocEntry = oDocEntry;
         
         
       SELECT tbintegraSAP_DocItem.*, tbEntradasItem.real_est3, tbEntradasItem.emb_est, emb_estoque_cli, fator_conv_vendas
       FROM tbintegraSAP_DocItem
       LEFT JOIN of_logistica.tbsolic_entradas_item tbEntradasItem ON
             tbEntradasItem.cod_emp   = tbintegraSAP_DocItem.cod_emp
         AND tbEntradasItem.cod_fil   = tbintegraSAP_DocItem.cod_fil
         AND tbEntradasItem.ano_solic = tbintegraSAP_DocItem.ano_solic
         AND tbEntradasItem.num_solic = tbintegraSAP_DocItem.num_solic
         AND tbEntradasItem.num_item  = tbintegraSAP_DocItem.num_item
       INNER JOIN of_logistica.tbprodutos ON 
                  tbprodutos.cnpj_cpf = tbEntradasItem.cnpj_cpf_dep
              AND tbprodutos.cod_produto = tbEntradasItem.cod_produto
       WHERE tbintegraSAP_DocItem.DocTipo = oDocTipo
         AND tbintegraSAP_DocItem.DocNum = oDocNum 
         AND tbintegraSAP_DocItem.DocEntry = oDocEntry;
         
       SELECT tbEntradasAcons.*, tbintegraSAP_DocItem.LineNum,
              tbEstoque.num_lote_cli NumLoteCli
       FROM tbintegraSAP_DocItem
       LEFT JOIN of_logistica.tbsolic_entradas_item tbEntradasItem ON
             tbEntradasItem.cod_emp   = tbintegraSAP_DocItem.cod_emp
         AND tbEntradasItem.cod_fil   = tbintegraSAP_DocItem.cod_fil
         AND tbEntradasItem.ano_solic = tbintegraSAP_DocItem.ano_solic
         AND tbEntradasItem.num_solic = tbintegraSAP_DocItem.num_solic
         AND tbEntradasItem.num_item  = tbintegraSAP_DocItem.num_item
       INNER JOIN of_logistica.tbsolic_entradas_acons tbEntradasAcons ON
                 tbEntradasAcons.cod_emp   = tbEntradasItem.cod_emp
             AND tbEntradasAcons.cod_fil   = tbEntradasItem.cod_fil
             AND tbEntradasAcons.ano_solic = tbEntradasItem.ano_solic
             AND tbEntradasAcons.num_solic = tbEntradasItem.num_solic
             AND tbEntradasAcons.num_item  = tbEntradasItem.num_item
       INNER JOIN of_logistica.tbwms_estoque tbEstoque ON 
                  tbEstoque.cod_emp = tbEntradasAcons.cod_emp
              AND tbEstoque.cod_fil = tbEntradasAcons.cod_fil
              AND tbEstoque.num_lote = tbEntradasAcons.num_lote
              AND tbEstoque.sequencia_lote = tbEntradasAcons.sequencia_lote
       WHERE tbintegraSAP_DocItem.DocTipo = oDocTipo
         AND tbintegraSAP_DocItem.DocNum = oDocNum 
         AND tbintegraSAP_DocItem.DocEntry = oDocEntry
         AND (tbEntradasAcons.qtde_est > 0 OR tbEntradasAcons.qtde_est2 > 0);
   
   END IF;
    
      
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_ListarFiliais.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_ListarFiliais`$$

CREATE PROCEDURE `PROC_INTEGRA_ListarFiliais`()
BLOCO1:BEGIN
   /*
   #@Author David Ruy <2023/03/20>
   #@Reviser David Ruy <2023/04/05> Join tbintegrasap_depositos
   */
   
   
   DECLARE xIdEmpresa TINYINT DEFAULT 0;
   DECLARE xidBase    TINYINT DEFAULT 1;
   
   DROP TEMPORARY TABLE IF EXISTS tbTMPFiliais ;
   CREATE TEMPORARY TABLE tbTMPFiliais 
      SELECT id_integracao chave_integracao, cnpj_empresa CnpjCpfCli, 
             idBase, SeqCode_NF, 
             cod_emp_slin CodEmpSlin, cod_fil_slin CodFilSlin, 
             raz_social nome_fantasia, raz_social, CardCode_For, CardCode_Cli, estado UF,
             flgMatriz
      FROM tbintegraSAP_empresas
      WHERE flg_ativo = 1;
      #SELECT chave_integracao, num_cnpj CnpjCpfCli, cod_empresa CodEmpSlin, cod_filial CodFilSlin, 
      #       cod_nome nome_fantasia, raz_social
      #FROM of_logistica.tbfiliais
      #WHERE flg_ativo = 'S';
      
   #SELECT * FROM tbTMPFiliais ;   
   
   SELECT chave_integracao, nome_fantasia, raz_social, CnpjCpfCli, tbTMPFiliais.UF,
          CodEmpSlin, CodFilSlin, CardCode_For, CardCode_Cli,
          chave_integracao IdEmpresa, tbintegraSAP_Depositos.cod_deposito,
          tbTMPFiliais.SeqCode_NF, tbTMPFiliais.flgMatriz, 
          tbintegraSAP_bases.*
   FROM tbTMPFiliais 
   LEFT JOIN tbintegraSAP_bases ON
              tbTMPFiliais.idBase = tbintegraSAP_bases.idBase
   LEFT JOIN tbintegraSAP_Depositos ON 
             TRUE #tbintegraSAP_Depositos.idBase = tbTMPFiliais.idBase
         AND tbintegraSAP_Depositos.id_empresa = tbTMPFiliais.chave_integracao
   WHERE IF(xIdEmpresa = 0, TRUE, xIdEmpresa = tbTMPFiliais.chave_integracao AND xidBase = tbTMPFiliais.idBase)
     AND flgAtivo = 1
   GROUP BY chave_integracao;
   #SELECT chave_integracao FROM of_logistica.tbfiliais 
   #WHERE IFNULL(chave_integracao,'') <> '' AND flg_ativo = 'S';
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_ListarKPI.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_ListarKPI`$$

CREATE PROCEDURE `PROC_INTEGRA_ListarKPI`(
   IN oDataInicio				   VARCHAR(20),
   IN oDataFinal				    VARCHAR(20)
   # Parametros de Retorno
   #OUT RESULTADO        INT,
   #OUT MENSAGEM         VARCHAR(500)
)
BLOCO1:BEGIN
   DECLARE xDataInicio   DATE;
   DECLARE xDataFinal    DATE;
   DECLARE xQtdeSep      INT; 
   DECLARE xQtdeSepItem  INT; 
   DECLARE xQtdeFat      INT; 
   DECLARE xQtdeFatItem  INT; 
   DECLARE xQtdePed      INT; 
   DECLARE xQtdePedItem  INT; 
   DECLARE xQtdeCanc     INT; 
   DECLARE xQtdeCancItem INT; 
   DECLARE xQtdeBack     INT; 
   DECLARE xQtdeBackItem INT;
   
   DROP TEMPORARY TABLE IF EXISTS tbTMP_KPI;
   CREATE TEMPORARY TABLE tbTMP_KPI (
            DATA           VARCHAR(20),
            QtdeSep        INT,
            QtdeSepItem    INT,
            QtdeFat        INT,
            QtdeFatItem    INT,
            QtdePed        INT,
            QtdePedItem    INT,
            QtdeCanc       INT,
            QtdeCancItem   INT,
            QtdeBack       INT,
            QtdeBackItem   INT);
            
   SET xDataInicio = oDataInicio;
   SET xDataFinal  = oDataFinal;
   
   #SELECT xDataInicio, xDataFinal;
   #leave BLOCO1;
   
   WHILE xDataInicio <= xDataFinal DO
      
      #Separação
      INSERT INTO tbTMP_KPI (DATA, QtdeSep, QtdeSepItem)
        SELECT xDataInicio,
               COUNT(DISTINCT tbSaidas.num_solic) QtdePedidos,
               COUNT(DISTINCT Item.num_solic, Item.num_item) QtdeItens
        FROM of_logistica.tbsolic_saidas tbSaidas
        LEFT JOIN of_logistica.tbsolic_saidas_item Item ON 
                  Item.cod_emp = tbSaidas.cod_emp
              AND Item.cod_fil = tbSaidas.cod_fil
              AND Item.ano_solic = tbSaidas.ano_solic
              AND Item.num_solic = tbSaidas.num_solic
        WHERE DATE(dthr_confirm) = xDataInicio;
        
        
      #Faturamento
      UPDATE tbTMP_KPI 
      SET QtdeFat     = (SELECT COUNT(DISTINCT tbSaidas.num_solic)
                         FROM of_logistica.tbsolic_saidas tbSaidas 
                         WHERE DATE(tbSaidas.dthr_retorno_integracao) = tbTMP_KPI.data),
          QtdeFatItem = (SELECT COUNT(DISTINCT Item.num_solic, Item.num_item)
                         FROM of_logistica.tbsolic_saidas tbSaidas 
                         LEFT JOIN of_logistica.tbsolic_saidas_item Item ON 
                                   Item.cod_emp = tbSaidas.cod_emp
                               AND Item.cod_fil = tbSaidas.cod_fil
                               AND Item.ano_solic = tbSaidas.ano_solic
                               AND Item.num_solic = tbSaidas.num_solic                 
                         WHERE DATE(tbSaidas.dthr_retorno_integracao) = tbTMP_KPI.data)
      WHERE tbTMP_KPI.data = xDataInicio;
      
      
      #Pedidos
      UPDATE tbTMP_KPI 
      SET QtdePed     = (SELECT COUNT(DISTINCT tbSaidas.num_solic)
                         FROM of_logistica.tbsolic_saidas tbSaidas 
                         WHERE tbSaidas.data_solic = tbTMP_KPI.data
                           AND dthr_cancelamento IS NULL),
          QtdePedItem = (SELECT COUNT(DISTINCT Item.num_solic, Item.num_item)
                         FROM of_logistica.tbsolic_saidas tbSaidas 
                         LEFT JOIN of_logistica.tbsolic_saidas_item Item ON 
                                   Item.cod_emp = tbSaidas.cod_emp
                               AND Item.cod_fil = tbSaidas.cod_fil
                               AND Item.ano_solic = tbSaidas.ano_solic
                               AND Item.num_solic = tbSaidas.num_solic           
                         WHERE tbSaidas.data_solic = tbTMP_KPI.data
                           AND dthr_cancelamento IS NULL)
      WHERE DATA = xDataInicio;
      
      
      #Cancelamentos
      UPDATE tbTMP_KPI 
      SET QtdeCanc     = (SELECT COUNT(DISTINCT tbSaidas.num_solic)
                          FROM of_logistica.tbsolic_saidas tbSaidas 
                          WHERE tbSaidas.data_solic = tbTMP_KPI.data
                            AND dthr_cancelamento IS NOT NULL),
          QtdeCancItem = (SELECT COUNT(DISTINCT Item.num_solic, Item.num_item)
                          FROM of_logistica.tbsolic_saidas tbSaidas 
                          LEFT JOIN of_logistica.tbsolic_saidas_item Item ON 
                                    Item.cod_emp = tbSaidas.cod_emp
                                AND Item.cod_fil = tbSaidas.cod_fil
                                AND Item.ano_solic = tbSaidas.ano_solic
                                AND Item.num_solic = tbSaidas.num_solic           
                          WHERE tbSaidas.data_solic = tbTMP_KPI.data
                            AND dthr_cancelamento IS NOT NULL)
      WHERE DATA = xDataInicio;
      
      
      #BackLog
      UPDATE tbTMP_KPI 
      SET QtdeBack     = (SELECT COUNT(DISTINCT tbSaidas.num_solic)
                          FROM of_logistica.tbsolic_saidas tbSaidas 
                          WHERE tbSaidas.data_solic = tbTMP_KPI.data
                            AND dthr_cancelamento IS NULL
                            AND dthr_confirm IS NULL),
          QtdeBackItem = (SELECT COUNT(DISTINCT Item.num_solic, Item.num_item)
                          FROM of_logistica.tbsolic_saidas tbSaidas 
                          LEFT JOIN of_logistica.tbsolic_saidas_item Item ON 
                                    Item.cod_emp = tbSaidas.cod_emp
                                AND Item.cod_fil = tbSaidas.cod_fil
                                AND Item.ano_solic = tbSaidas.ano_solic
                                AND Item.num_solic = tbSaidas.num_solic           
                          WHERE tbSaidas.data_solic = tbTMP_KPI.data
                            AND dthr_cancelamento IS NULL
                            AND dthr_confirm IS NULL)
      WHERE DATA = xDataInicio;
      SET xDataInicio = DATE_ADD(xDataInicio, INTERVAL 1 DAY);   
        
   END WHILE;
   SELECT SUM(QtdeSep) QtdeSep,
          SUM(QtdeSepItem) QtdeSepItem,
          SUM(QtdeFat) QtdeFat,
          SUM(QtdeFatItem) QtdeFatItem,
          SUM(QtdePed) QtdePed,
          SUM(QtdePedItem) QtdePedItem,
          SUM(QtdeCanc) QtdeCanc,
          SUM(QtdeCancItem) QtdeCancItem,
          SUM(QtdeBack) QtdeBack,
          SUM(QtdeBackItem) QtdeBackItem
   INTO XQtdeSep, XQtdeSepItem, XQtdeFat, XQtdeFatItem, XQtdePed, XQtdePedItem, XQtdeCanc, XQtdeCancItem, XQtdeBack, XQtdeBackItem
   FROM tbTMP_KPI;
    
   INSERT INTO tbTMP_KPI VALUES ('Totais', XQtdeSep, XQtdeSepItem, XQtdeFat, XQtdeFatItem, XQtdePed, XQtdePedItem, XQtdeCanc, XQtdeCancItem, XQtdeBack, XQtdeBackItem);
            
   SELECT * FROM tbTMP_KPI;
   DROP TEMPORARY TABLE IF EXISTS tbTMP_KPI;
      
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_ListarLog.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_ListarLog`$$

CREATE PROCEDURE `PROC_INTEGRA_ListarLog`( IN oDataInicio				   VARCHAR(20)
, IN oDataFinal				    VARCHAR(20)
, IN oMetodo           VARCHAR(50)
, IN oTipoOper				     VARCHAR(50)
, IN oTipoOper2        VARCHAR(50)
, IN oStatusSLIN       VARCHAR(50)
, IN oSucesso          VARCHAR(1)
)
BEGIN
   /*************************************************************************************************
   #@Reviser David Ruy <2022/04/29> Novo Status = 8-> Forçar Picking
   #@Reviser David Ruy <2022/04/29> Buscar por PK / ID
   #@Reviser David Ruy <2023/03/01> Campo BPLId
   #@Reviser David Ruy <2023/07/25> Filtro oTipoOper like PA%
   #@Reviser Erico Forcinetti <2024/04/20> Melhorias nos Selects
   #@Reviser David Ruy <2024-09-04> Condição TOPO : IF(tbTopo.DocTipo IN ('PV','DC','TD-S','OP'),'S','' )) = 'S'
   #@Reviser David Ruy <2024-09-04> Condição TOPO : IF(tbTopo.DocTipo IN ('E-RM','E-NE','NE','DV','TD-E','PA000'),'S','' )) = 'E'
   #
   #
   #
   #
   #PV - Liberados para Picking
   1 'GET', 'inventory/Picking', '', null);
   #PV - Reabertura de Picking
   2 'DELETE', 'inventory/Picking', 'PV571', 0);
   #Criação de Picking
   3 'POST', 'inventory/Picking/Create','PV571', 0);
   #Confirmação de Picking
   4 'POST', 'inventory/Picking', 'Confirm', 0);
   #Vendas - Alteração de Pedido de Vendas
   5 'GET', 'inventory/Updated', '', 0);
     'PROC', 'tbintegraSAP_UpdCancPV', '', 0);
   #Vendas - Atualização de Pedido de Vendas
   7 'POST', 'inventory/Order', 'ChangeQuantity', 0);
   #Vendas - Cancelamento Pedido de Vendas
   8 'ObterDocumento', 'inventory/Canceled', '', 0);
   #Vendas - NF retorno - Devolução de Vendas
   9 'GET', 'inventory/CreditNote', '', 0);
   9 'POST', 'inventory/CreditNote', '', 0);
   #Compras - NF Entrega Futura
   10 'GET', 'purchase', '', 0);
   10 'POST', 'purchase', '', 0);
   #Compras - Cancelamento Entrega Futura
   11 'ObterListaRecebimentoCancelado', 'ReverseInvoice', '', 0);
   #Contagem
   12 'POST','inventory/Counting/Confirm', xcod_produto   
   *************************************************************************************************/
   
   DECLARE xTipoDoc    VARCHAR(20) DEFAULT '';
   DECLARE _DataInicio DATETIME; 
   DECLARE _DataFinal  DATETIME; 
   
   SET _DataInicio = oDataInicio; 
   SET _DataFinal  = oDataFinal; 
   
   IF LOCATE('PK',oTipoOper2)>0 THEN
      SET xTipoDoc = 'PK';
      SET oTipoOper2 = REPLACE(oTipoOper2, "PK","");
   END IF;
   IF LOCATE('ID',oTipoOper2)>0 THEN
      SET xTipoDoc = 'ID';
      SET oTipoOper2 = REPLACE(oTipoOper2, "ID","");
   END IF;
   
   #Cria tabela Temporária com Status das operações
   SET @String = 'Confirmed|OK|Created|200|1|2|3';
   CALL PROC_SYS_GerarTabelaComTexto(@String,"|",1);
   
   
  IF oTipoOper = "/api/inventory/Picking/Create" THEN
     SET oTipoOper = "Pick_Create";
  END IF;
  IF oTipoOper = "/api/inventory/Picking/Confirm" THEN
     SET oTipoOper = "Pick_Confirm";
  END IF;
  IF oTipoOper = "/api/inventory/Canceled" THEN
     SET oTipoOper = "Pick_Delete";
  END IF;
  #IF oTipoOper = "/api/Stock/Transfers/Confirm" THEN
  IF oTipoOper LIKE "%Transfer%" THEN
     SET oTipoOper = "Transfer";
  END IF;
  IF oTipoOper LIKE "/api/purchase%" THEN
     SET oTipoOper = "Purchase";
  END IF;
   
   
  IF UPPER(oMetodo) = 'TOPO' THEN
  BEGIN 
  
    SELECT tbTopo.DocTipo                   AS DocTipo
         , tbTopo.DocEntry                  AS DocEntry
         , CONCAT( tbTopo.DocTipo
                 , tbTopo.DocNum
                 , '(',tbTopo.DocEntry,')'
                 )                          AS DocSAP
         , tbTopo.IdPicking                 AS IdPicking 
         , tbTopo.IdPickingAnt              AS IdPickingAnt
         , tbTopo.DocDate                   AS DocDate   
         , tbTopo.DueDate                   AS DueDate
         , tbTopo.StatusAnt                 AS StatusAnt
         , tbTopo.StatusDoc                 AS StatusDoc 
         , tbTopo.StatusSLIN                AS StatusSLIN
         , tbTopo.DocNum                    AS DocNum
         , CASE tbTopo.StatusAnt
                WHEN "1" THEN "Importado SAP"
                WHEN "2" THEN "Integrado SLIN"
                WHEN "3" THEN "Integrado SLIN (alteração)"
                WHEN "4" THEN "Iniciado SLIN"
                WHEN "5" THEN "Finalizado SLIN"
                WHEN "6" THEN "Retornado SAP"
                WHEN "7" THEN "Em Alteração WMS"
                WHEN "8" THEN "Forçar Novo Picking"
                WHEN "9" THEN "Cancelado SAP"
           END                              AS DescStatusAnt
         , CASE tbTopo.StatusDoc
                WHEN "1" THEN "Importado SAP"
                WHEN "2" THEN "Integrado SLIN"
                WHEN "3" THEN "Integrado SLIN (alteração)"
                WHEN "4" THEN "Iniciado SLIN"
                WHEN "5" THEN "Finalizado SLIN"
                WHEN "6" THEN "Retornado SAP"
                WHEN "7" THEN "Em Alteração WMS"
                WHEN "8" THEN "Forçar Novo Picking"
                WHEN "9" THEN "Cancelado SAP"
           END                              AS DescStatus
         , of_logistica.fnStatusSaidaWms(IFNULL(tbSaidas.status_processo,99)) StatusSlin
         , tbTopo.CardCode                  AS CardCode
         , tbTopo.CardName                  AS CardName
         , CONCAT( 'GSM:'
                 , TRIM(LEADING '0' FROM tbTopo.cod_emp)
                 , "/"
                 , TRIM(LEADING '0' FROM tbTopo.cod_fil)
                 , '-'
                 , TRIM(LEADING '0' FROM tbTopo.num_solic)
                 , "|"
                 , tbTopo.ano_solic
                 )                          AS DocSLIN
         , tbTopo.dthr_cancel_slin          AS dthr_cancel_slin
         , tbTopo.Observacoes               AS Observacoes
         , tbTopo.dthr_inc                  AS dthr_inc
         , tbTopo.dthr_alt                  AS dthr_alt  
         , tbSaidas.dthr_inc                AS dthr_inc_slin
         , tbSaidas.dthr_retorno_integracao AS dthr_retorno
         , IF(     ( SELECT SUM(IFNULL(Item.real_est2, 0)) 
                       FROM of_logistica.tbsolic_saidas_item Item
                      WHERE Item.cod_emp   = tbSaidas.cod_emp   
                        AND Item.cod_fil   = tbSaidas.cod_fil
                        AND Item.ano_solic = tbSaidas.ano_solic
                        AND Item.num_solic = tbSaidas.num_solic
                   )  
                 - ( SELECT SUM(IFNULL(Item.qtde_sep_est, 0)) 
                       FROM of_logistica.tbsolic_saidas_volume_item Item
                      WHERE Item.cod_emp   = tbSaidas.cod_emp   
                        AND Item.cod_fil   = tbSaidas.cod_fil
                        AND Item.ano_solic = tbSaidas.ano_solic
                        AND Item.num_solic = tbSaidas.num_solic
                   ) = 0 
               AND IFNULL( ( SELECT SUM(IFNULL(Item.qtde_sep_est, 0)) 
                               FROM of_logistica.tbsolic_saidas_volume_item Item
                              WHERE Item.cod_emp   = tbSaidas.cod_emp   
                                AND Item.cod_fil   = tbSaidas.cod_fil
                                AND Item.ano_solic = tbSaidas.ano_solic
                                AND Item.num_solic = tbSaidas.num_solic
                           ) 
                         , 0
                         ) > 0 
               AND ( tbSaidas.status_processo >= 8
                   )
             , TRUE
             , FALSE
             )                              AS FlgCheckout
         , IF( EXISTS( SELECT tbViagens.num_viagem
                         FROM of_logistica.tbprog_entregas tbEntregas 
                              INNER JOIN of_logistica.tbviagens tbViagens  ON tbViagens.cod_emp    = tbEntregas.cod_emp 
                                                                          AND tbViagens.cod_fil    = tbEntregas.cod_fil
                                                                          AND tbViagens.ano_viagem = tbEntregas.ano_viagem 
                                                                          AND tbViagens.num_viagem = tbEntregas.num_viagem
                        WHERE tbEntregas.chave_integracao = tbSaidas.chave_integracao
                          AND tbViagens.data_conf IS NOT NULL
                     )
             , TRUE
             , FALSE
             )                             AS FlgRotaConf
         , ( SELECT CONCAT(tbEntregas.num_viagem , '/', tbEntregas.ano_viagem) 
               FROM of_logistica.tbprog_entregas tbEntregas
              WHERE tbEntregas.chave_integracao = tbSaidas.chave_integracao
           )                               AS NumViagem
         , tbTopo.chave_integracao         AS chave_integracao
         , tbnfCli.chave_nfe               AS chave_nfe 
         , tbTopo.BPLId                    AS BPLId
         , ( SELECT SUM(Item.qtde_sep_est) 
               FROM of_logistica.tbsolic_saidas_volume_item Item
              WHERE Item.cod_emp   = tbSaidas.cod_emp
                AND Item.cod_fil   = tbSaidas.cod_fil
                AND Item.ano_solic = tbSaidas.ano_solic
                AND Item.num_solic = tbSaidas.num_solic
           )                               AS QtdeCheckout 
         , ( SELECT SUM(Item.real_est2) 
               FROM of_logistica.tbsolic_saidas_item Item
              WHERE Item.cod_emp   = tbSaidas.cod_emp
                AND Item.cod_fil   = tbSaidas.cod_fil
                AND Item.ano_solic = tbSaidas.ano_solic
                AND Item.num_solic = tbSaidas.num_solic
           )                               AS QtdeSep
         , tbSaidas.qtde_volume_checkout  AS QtdeVolumesApontamento
      FROM tbintegraSAP_Doc tbTopo
           LEFT JOIN of_logistica.tbsolic_saidas tbSaidas  ON tbSaidas.cod_emp         = tbTopo.cod_emp 
                                                          AND tbSaidas.cod_fil         = tbTopo.cod_fil
                                                          AND tbSaidas.ano_solic       = tbTopo.ano_solic
                                                          AND tbSaidas.num_solic       = tbTopo.num_solic
           LEFT JOIN of_logistica.tbnf_clientes tbnfCli    ON tbnfCli.chave_integracao = tbTopo.chave_integracao
     WHERE tbTopo.DocDate     BETWEEN _DataInicio AND _DataFinal
       AND IFNULL(tbTopo.TipoDocSLIN, IF(tbTopo.DocTipo IN ('PV','DC','TD-S','OP'),'S','' )) = 'S'
       AND IF( IFNULL(oTipoOper,'') = ''
             , TRUE
             , DocTipo LIKE CONCAT(oTipoOper,'%')
             )
       AND IF( IFNULL(oTipoOper2,'') = ''
             , TRUE
             , IF( xTipoDoc='PK'
                 , IdPicking = oTipoOper2
                 , IF( xTipoDoc='ID'
                     , DocEntry = oTipoOper2
                     , CAST(DocNum AS CHAR) = oTipoOper2
                     )
                 )
             )
       AND IF( IFNULL(oSucesso,'T') = 'T'
             , TRUE
             , oSucesso = StatusDoc
             )
       AND IF( oStatusSLIN='T'
             , TRUE
             , IF( oStatusSLIN = '1'
                 , tbSaidas.status_processo <= 1 
                 , IF( oStatusSLIN = '2'
                     , tbSaidas.status_processo BETWEEN 2 AND 5
                     , IF( oStatusSLIN = '3'
                         , tbSaidas.status_processo >= 6
                         , FALSE
                         )
                 )
              )
           )
        
     UNION ALL 
      
     SELECT tbTopo.DocTipo                     AS DocTipo
          , tbTopo.DocEntry                    AS DocEntry
          , CONCAT( tbTopo.DocTipo
                  , tbTopo.DocNum
                  , '(',tbTopo.DocEntry,')'
                  )                            AS DocSAP
          , tbTopo.IdPicking                   AS IdPicking 
          , tbTopo.IdPickingAnt                AS IdPickingAnt
          , tbTopo.DocDate                     AS DocDate   
          , tbTopo.DueDate                     AS DueDate
          , tbTopo.StatusAnt                   AS StatusAnt
          , tbTopo.StatusDoc                   AS StatusDoc 
          , tbTopo.StatusSLIN                  AS StatusSLIN
          , tbTopo.DocNum                      AS DocNum
          , CASE tbTopo.StatusAnt
                 WHEN "1" THEN "Importado SAP"
                 WHEN "2" THEN "Integrado SLIN"
                 WHEN "3" THEN "Integrado SLIN (alteração)"
                 WHEN "4" THEN "Iniciado SLIN"
                 WHEN "5" THEN "Finalizado SLIN"
                 WHEN "6" THEN "Retornado SAP"
                 WHEN "7" THEN "Em Alteração WMS"
                 WHEN "8" THEN "Forçar Novo Picking"
                 WHEN "9" THEN "Cancelado SAP"
            END                                AS DescStatusAnt
          , CASE tbTopo.StatusDoc
                 WHEN "1" THEN "Importado SAP"
                 WHEN "2" THEN "Integrado SLIN"
                 WHEN "3" THEN "Integrado SLIN (alteração)"
                 WHEN "4" THEN "Iniciado SLIN"
                 WHEN "5" THEN "Finalizado SLIN"
                 WHEN "6" THEN "Retornado SAP"
                 WHEN "7" THEN "Em Alteração WMS"
                 WHEN "8" THEN "Forçar Novo Picking"
                 WHEN "9" THEN "Cancelado SAP"
            END                                AS DescStatus
          , of_logistica.fnStatusProcessoWms(IFNULL(tbEntradas.status_processo,99)) StatusSlin
          , tbTopo.CardCode                    AS CardCode
          , tbTopo.CardName                    AS CardName
          , CONCAT( 'GEM:'
                  , TRIM(LEADING '0' FROM tbTopo.cod_emp)
                  , "/"
                  , TRIM(LEADING '0' FROM tbTopo.cod_fil)
                  , '-'
                  , TRIM(LEADING '0' FROM tbTopo.num_solic)
                  , "|"
                  , tbTopo.ano_solic
                  )                            AS DocSLIN
          , tbTopo.dthr_cancel_slin            AS dthr_cancel_slin
          , tbTopo.Observacoes                 AS Observacoes
          , tbTopo.dthr_inc                    AS dthr_inc
          , tbTopo.dthr_alt                    AS dthr_alt  
          , tbEntradas.dthr_inc                AS dthr_inc_slin
          , tbEntradas.dthr_retorno_integracao AS dthr_retorno
          , FALSE                              AS FlgCheckout
          , FALSE                              AS FlgRotaConf
          , NULL                               AS NumViagem
          , tbTopo.chave_integracao            AS chave_integracao
          , NULL                               AS chave_nfe 
          , tbTopo.BPLId                       AS BPLId
          , NULL                               AS QtdeCheckout 
          , NULL                               AS QtdeSep
          , NULL                               AS QtdeVolumesApontamento
       FROM tbintegraSAP_Doc tbTopo  
       LEFT JOIN of_logistica.tbsolic_entradas tbEntradas  ON tbEntradas.cod_emp   = tbTopo.cod_emp 
                                                          AND tbEntradas.cod_fil   = tbTopo.cod_fil
                                                          AND tbEntradas.ano_solic = tbTopo.ano_solic
                                                          AND tbEntradas.num_solic = tbTopo.num_solic
      WHERE tbTopo.DocDate     BETWEEN _DataInicio AND _DataFinal
        AND IFNULL(tbTopo.TipoDocSLIN, IF(tbTopo.DocTipo IN ('E-RM','E-NE','NE','DV','TD-E','PA000'),'S','' )) = 'E'
        AND IF( IFNULL(oTipoOper,'') = ''
              , TRUE
              , DocTipo LIKE CONCAT(oTipoOper,'%')
              )
        AND IF( IFNULL(oTipoOper2,'') = ''
              , TRUE
              , IF( xTipoDoc='PK'
                  , IdPicking = oTipoOper2
                  , IF( xTipoDoc='ID'
                      , DocEntry = oTipoOper2
                      , CAST(DocNum AS CHAR) = oTipoOper2
                      )
                  )
              )
        AND IF( IFNULL(oSucesso,'T') = 'T'
              , TRUE
              , oSucesso = StatusDoc
              )
        AND IF( oStatusSLIN='T'
              , TRUE
              , IF( oStatusSLIN = '1'
                  , tbEntradas.status_processo <= 3
                  , IF( oStatusSLIN = '2'
                      , tbEntradas.status_processo BETWEEN 4 AND 7
                      , IF( oStatusSLIN = '3'
                          , tbEntradas.status_processo >= 8
                          , FALSE
                          )
                  )
               )
            ); 
  
  END; 
  ELSEIF UPPER(oMetodo) IN ('PATCH', 'GET','POST','PROC','DELETE') THEN
  BEGIN  
  
     IF oTipoOper = 'Last' THEN
     BEGIN 
     
        SELECT * FROM tbintegraSAP_log_request
        LEFT JOIN tTabelaComTexto ON
                 tTabelaComTexto.coluna01 = ResponseStatus
        WHERE dthr_inc > CURRENT_DATE()
        AND IF(oMetodo='PROC', SUBSTRING(jsonrequest,01,04) = oMetodo,
               IF(oMetodo='GET',(SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = 'ObterDocumento' OR 
                                 SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = oMetodo OR
                                 SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = 'GET1') ,
                     
                     IF(oMetodo='PATCH',
                                 SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = oMetodo OR
                                 SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = 'PATCH1',
                                 
                                 SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = oMetodo)
                                 
              ))
        AND IF(oSucesso='T', TRUE, IF(oSucesso=1, tTabelaComTexto.coluna01 IS NOT NULL, tTabelaComTexto.coluna01 IS NULL))
        ORDER BY dthr_inc DESC 
        LIMIT 50;
       
     END; 
     ELSE
     BEGIN 
     
        SELECT tbintegraSAP_log_request.* 
          FROM tbintegraSAP_log_request
               LEFT JOIN tTabelaComTexto ON tTabelaComTexto.coluna01 = tbintegraSAP_log_request.ResponseStatus
         WHERE tbintegraSAP_log_request.dthr_inc BETWEEN _DataInicio AND _DataFinal
           AND IF( oMetodo='PROC'
                 , SUBSTRING(jsonrequest, 01, 04) = oMetodo
                 , IF( ( oMetodo = 'GET'
                       )  
                     , (    SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = 'ObterDocumento' 
                         OR SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = oMetodo 
                         OR SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = 'GET1'
                       ) 
                     , IF( oMetodo = 'PATCH'
                         ,    SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = oMetodo 
                           OR SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = 'PATCH1'
                         , SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = oMetodo
                         )
                     )
                 )
           AND tbintegraSAP_log_request.jsonrequest LIKE CONCAT('%',oTipoOper,'%')
           AND IF( oMetodo='POST'
                 , tbintegraSAP_log_request.jsonrequest  LIKE CONCAT('%',oTipoOper2,'%')
                 , tbintegraSAP_log_request.jsonResponse LIKE CONCAT('%',oTipoOper2,'%')
                 )
           AND IF( oSucesso='T'
                 , TRUE
                 , IF( oSucesso=1
                     , tTabelaComTexto.coluna01 IS NOT NULL, tTabelaComTexto.coluna01 IS NULL
                     )
                 );      
        
        SELECT oTipoOper, oTipoOper2, oMetodo;
     
     END; 
     END IF;
  
  END; 
  ELSEIF UPPER(oMetodo) = 'LAST' THEN 
  BEGIN 
  
     #Ultimo registro de log
     SELECT tbintegraSAP_log_request.*,
            CASE 
               WHEN LOCATE('purchase',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Compras"
               WHEN LOCATE('transfer',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Transferencias"
               WHEN LOCATE('ReverseInvoice',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Cancelamento de Compras"
               WHEN LOCATE('CreditNote',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Devoluções Pedido de Vendas"
               WHEN LOCATE('picking',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Criação e Confirmaçao de Picking"
               WHEN LOCATE('Production',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Ordem de Produção"
               WHEN LOCATE('Update',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Alterações de Pedidos de Vendas"
               WHEN LOCATE('PROC_INTEGRA_EnviarUpdCancPV',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Alterações de Pedidos de Vendas"
               WHEN LOCATE('PROC_INTEGRA_AtualizarSLIN',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Atualizar SLIN (GEM e GSM)"
               WHEN LOCATE('PATCHTMS',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Atualizar Status Entregas -> SAP"
               WHEN LOCATE('GetDiAPI_InventChaveDanfe',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Buscar N° NF Vendas (AddOn Invent)"
               #WHEN LOCATE('',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Buscar CT-e´s (AddOn Invent)"
             ELSE "N/A"
             END AS ProcessoAtual
     FROM tbintegraSAP_log_request
     ORDER BY dthr_inc DESC LIMIT 1;
  
  END; 
  END IF;
  
  
  DROP TEMPORARY TABLE IF EXISTS tTabelaComTexto;
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_ListarParametros.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_ListarParametros`$$

CREATE PROCEDURE `PROC_INTEGRA_ListarParametros`(
)
BLOCO1:BEGIN
/**************************************************************************************/
#@Reviser David Ruy <2025-07-21> Buscar DataUpdCanc da tabela de parametros
#                                Listar tbintegraSAP_utilizacao
#
/**************************************************************************************/
   DECLARE xIncAlt VARCHAR(01)	DEFAULT 'I';
   DECLARE excecao INT DEFAULT 0;
   DECLARE DataUpdCanc DATETIME;
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;

   #Data e Hora da ultima alteração recuperada do SAP
   #SELECT MAX(updatedate) INTO DataUpdCanc 
   #FROM tbintegraSAP_UpdCancPV
   #WHERE DATE(dthr_inc) = CURRENT_DATE()
   #AND TipoUpdCanc = 'U';
   #
   #SET DataUpdCanc = IFNULL(DATE_ADD(DataUpdCanc, INTERVAL -30 MINUTE),
   #                         DATE_ADD(NOW(), INTERVAL -2 HOUR));
                            
                            
   SELECT tbintegraSAP_parametros .*
         ,IFNULL(TIMESTAMPDIFF(MINUTE, ultima_atu, NOW()),0) AS ElapsedAtu
         ,NOW() AS dthr_now, 
         IFNULL(DATE_ADD(dthr_updcanc, INTERVAL -30 MINUTE),
                         DATE_ADD(NOW(), INTERVAL -2 HOUR)) DataUpdCanc
         ,tbfiliais.raz_social
         #,DATE_SUB(ultima_atu, INTERVAL 30 MINUTE) DataUpdCanc2
         ,dthr_updcanc DataUpdCanc2
   FROM tbintegraSAP_parametros
   LEFT JOIN of_logistica.tbfiliais ON 
             tbfiliais.num_cnpj = cnpj_cpf_cli;
             
             
   SELECT * FROM tbintegraSAP_utilizacao;
             
   #IF excecao = 1 THEN
      #SET RESULTADO = "0";
      #SET MENSAGEM = "Erro SQL - Verifique com o Administrador";
   #END IF;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_LISTAR_ATUALIZAR_STATUS_FRETE.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_LISTAR_ATUALIZAR_STATUS_FRETE`$$

CREATE PROCEDURE `PROC_INTEGRA_LISTAR_ATUALIZAR_STATUS_FRETE`(
   IN xTipoMovto   INT,
   IN DanfeCTE     VARCHAR(100)
   #OUT RESULTADO   INT,
   #OUT MENSAGEM    VARCHAR(500)
)
BEGIN
   # PROCEDURE PARA CONSULTAR PRODUTOS DE PICKING
   # @author Érico Forcinetti <2018/05/27>
   # @company Overflash
   # Parametros : xtipomovto = 0 => Listar / xtipomovto = 1 => Update tbintegraSAP_CTe.dthr_integracao 
   DECLARE xQtdeLinhas INT DEFAULT 0;
   DECLARE RESULTADO   INT;
   DECLARE MENSAGEM    VARCHAR(500);
   SET RESULTADO = 0;
     
   IF xTipoMovto = 0 THEN
      SELECT CardCode, CardName, DocTypeId, DocEntry, DocNum, SERIAL, data_documento, num_chave DanfeCTE,
             TRUNCATE(valor_total,4) FreteFornecedor, TRUNCATE(tbprog_entregas.valor_entrega,4) FreteCalculado, 
             tbtms_ctrc_terc2.dthr_analise, tbtms_ctrc_terc2.status_analise, IFNULL(tbtms_ctrc_terc2.flg_analise,9) flg_analise
      FROM tbintegraSAP_CTe
      INNER JOIN of_logistica.tbtms_ctrc_terc ON 
                 tbintegraSAP_CTe.num_chave = tbtms_ctrc_terc.id_remessa
      INNER JOIN of_logistica.tbtms_ctrc_terc2 ON 
                 tbtms_ctrc_terc2.cod_emp      = tbtms_ctrc_terc.cod_emp
             AND tbtms_ctrc_terc2.cod_fil      = tbtms_ctrc_terc.cod_fil
             AND tbtms_ctrc_terc2.cnpj_cpf_emi = tbtms_ctrc_terc.cnpj_cpf_emi
             AND tbtms_ctrc_terc2.num_ctrc     = tbtms_ctrc_terc.num_ctrc
             AND tbtms_ctrc_terc2.serie_ctrc   = tbtms_ctrc_terc.serie_ctrc 
      INNER JOIN of_logistica.tbprog_entregas ON 
                              tbprog_entregas.cod_emp     = tbtms_ctrc_terc2.cod_emp_entrega
                          AND tbprog_entregas.cod_fil     = tbtms_ctrc_terc2.cod_fil_entrega
                          AND tbprog_entregas.ano_entrega = tbtms_ctrc_terc2.ano_entrega
                          AND tbprog_entregas.num_entrega = tbtms_ctrc_terc2.num_entrega
      WHERE tbintegraSAP_CTe.dthr_cancel IS NULL
        AND tbintegraSAP_CTe.DocEntry <> 'N/A'
        AND tbintegraSAP_CTe.DocEntry <> '0'
        AND tbtms_ctrc_terc2.dthr_analise IS NOT NULL
        AND tbintegraSAP_CTe.dthr_integracao IS NULL
        #AND tbintegraSAP_CTe.status_analise <> IFNULL(tbtms_ctrc_terc2.flg_analise,'9')
        AND tbtms_ctrc_terc2.dthr_analise BETWEEN DATE_ADD(NOW(), INTERVAL -30 DAY) AND DATE_ADD(NOW(), INTERVAL -10 DAY)
        ;
        
      SELECT ROW_COUNT() INTO xQtdeLinhas;
      SET MENSAGEM = CONCAT("Total de registros selecionados : ",xQtdeLinhas);
      
   END IF;
   
   
   IF xTipoMovto = 1 THEN
      UPDATE tbintegraSAP_CTe 
      INNER JOIN of_logistica.tbtms_ctrc_terc ON 
                 tbintegraSAP_CTe.num_chave = tbtms_ctrc_terc.id_remessa
      INNER JOIN of_logistica.tbtms_ctrc_terc2 ON 
                 tbtms_ctrc_terc2.cod_emp      = tbtms_ctrc_terc.cod_emp
             AND tbtms_ctrc_terc2.cod_fil      = tbtms_ctrc_terc.cod_fil
             AND tbtms_ctrc_terc2.cnpj_cpf_emi = tbtms_ctrc_terc.cnpj_cpf_emi
             AND tbtms_ctrc_terc2.num_ctrc     = tbtms_ctrc_terc.num_ctrc
             AND tbtms_ctrc_terc2.serie_ctrc   = tbtms_ctrc_terc.serie_ctrc 
      INNER JOIN of_logistica.tbprog_entregas ON 
                              tbprog_entregas.cod_emp     = tbtms_ctrc_terc2.cod_emp_entrega
                          AND tbprog_entregas.cod_fil     = tbtms_ctrc_terc2.cod_fil_entrega
                          AND tbprog_entregas.ano_entrega = tbtms_ctrc_terc2.ano_entrega
                          AND tbprog_entregas.num_entrega = tbtms_ctrc_terc2.num_entrega
      SET tbintegraSAP_CTe.dthr_integracao = NOW(),
          tbintegraSAP_CTe.status_analise  = tbtms_ctrc_terc2.flg_analise,
          tbintegraSAP_CTe.vlr_calculado   = tbprog_entregas.valor_entrega,
          tbintegraSAP_CTe.observ_analise  = tbtms_ctrc_terc2.observ_analise
      WHERE tbintegraSAP_CTe.num_chave = DanfeCTE;
      #WHERE true #tbtms_ctrc_terc2.dthr_analise BETWEEN DATE_ADD(NOW(), INTERVAL -30 DAY) AND DATE_ADD(NOW(), INTERVAL -10 DAY)
      #  AND ifnull(tbintegraSAP_CTe.status_analise,'X') <> ifNull(tbtms_ctrc_terc2.flg_analise,'X')
      #  and tbtms_ctrc_terc2.flg_analise is not null;
      
      IF ROW_COUNT() = 0 THEN
         SET RESULTADO = -1;
         SET MENSAGEM = "ERRO - Nenhum Registro foi atualizado ! ";
      ELSE
         SET MENSAGEM = "OK - Registro atualizado com sucesso ! ";
      END IF;
      SELECT RESULTADO, MENSAGEM;
      
   END IF;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_MontaEndereco.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_MontaEndereco`$$

CREATE PROCEDURE `PROC_INTEGRA_MontaEndereco`(
	   IN  xEnd_Entrega     VARCHAR(500),
      OUT xLogradouro      VARCHAR(10),
      OUT xEndereco        VARCHAR(100),
      OUT xNumEnde         VARCHAR(30),
      OUT xComplEnde       VARCHAR(200),
      OUT xBairroEnde      VARCHAR(50),
      OUT xCepEnde         VARCHAR(10),
      OUT xCidadeEnde      VARCHAR(50),
      OUT xUFEnde          VARCHAR(10),
      OUT xPaisEnde        VARCHAR(50)
    )
BLOCO1:BEGIN
	/* PROCEDURE PARA DESMONTAR STRING COM ENDERECO EM VARIÁVEIS
	 * @author David Ruy <2021/08/20>
	 */
	 DECLARE _Logradouro    VARCHAR(30);
	 DECLARE _Endereco      VARCHAR(100);
	 DECLARE xStrAux   VARCHAR(100);
	
   #logradouro,endereço,numero <newline> complemento <newline> Bairro <newline> cep - Cidade - Estado <newline> pais
   SET xEnd_Entrega = REPLACE(xEnd_Entrega,'\n','|');
   SET xEnd_Entrega = REPLACE(xEnd_Entrega,'||','|#|');
   
   #Logradouro
   SET _Logradouro = SUBSTRING(xEnd_Entrega,1,LOCATE('|',xEnd_Entrega)); 
   SET xEnd_Entrega = REPLACE(xEnd_Entrega,_Logradouro,'');
   #Endereço
   SET _Endereco = SUBSTRING(xEnd_Entrega,1,LOCATE('|',xEnd_Entrega)); 
   SET xEnd_Entrega = REPLACE(xEnd_Entrega,_Endereco,'');
   
   #Numero
   SET xNumEnde = SUBSTRING(xEnd_Entrega,1,LOCATE('|',xEnd_Entrega)); 
   SET xEnd_Entrega = REPLACE(xEnd_Entrega,xNumEnde,'');
   
   #Complemento
   SET xComplEnde   = SUBSTRING(xEnd_Entrega,1,LOCATE('|',xEnd_Entrega));  
   SET xEnd_Entrega = REPLACE(xEnd_Entrega,xComplEnde,'');
   #Bairro
   SET xBairroEnde  = SUBSTRING(xEnd_Entrega,1,LOCATE('|',xEnd_Entrega));  
   SET xEnd_Entrega = REPLACE(xEnd_Entrega,xBairroEnde,'');
   #CEP
   SET xCepEnde  = SUBSTRING(xEnd_Entrega,1,LOCATE('|',xEnd_Entrega));  
   SET xEnd_Entrega = REPLACE(xEnd_Entrega,xCepEnde,'');
   #Cidade
   SET xCidadeEnde  = SUBSTRING(xEnd_Entrega,1,LOCATE('|',xEnd_Entrega));  
   SET xEnd_Entrega = REPLACE(xEnd_Entrega,xCidadeEnde,'');
   #UF
   SET xUFEnde = SUBSTRING(xEnd_Entrega,1,LOCATE('|',xEnd_Entrega));  
   SET xEnd_Entrega = REPLACE(xEnd_Entrega,xUFEnde,'');
   #País
   SET xPaisEnde = xEnd_Entrega;
         
   #Ajuste fino das variáveis
   SET xLogradouro = _Logradouro;
   SET xEndereco   = _Endereco;
   SET xLogradouro = REPLACE(xLogradouro,'|','');     SET xLogradouro = REPLACE(xLogradouro,'#','');   
   SET xEndereco   = REPLACE(xEndereco,'|','');       SET xEndereco   = REPLACE(xEndereco,'#','');   
   SET xNumEnde    = REPLACE(xNumEnde,'|','');        SET xNumEnde    = REPLACE(xNumEnde,'#','');
   SET xComplEnde  = REPLACE(xComplEnde,'|','');      SET xComplEnde  = REPLACE(xComplEnde,'#','');
   SET xBairroEnde = REPLACE(xBairroEnde,'|','');     SET xBairroEnde = REPLACE(xBairroEnde,'#','');
   SET xCepEnde    = REPLACE(xCepEnde,'|','');        SET xCepEnde    = REPLACE(xCepEnde,'#','');
   SET xCidadeEnde = REPLACE(xCidadeEnde,'|','');     SET xCidadeEnde = REPLACE(xCidadeEnde,'#','');
   SET xUFEnde     = REPLACE(xUFEnde,'|','');         SET xUFEnde     = REPLACE(xUFEnde,'#','');
				   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_MovtoEtiquetaProducao.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_MovtoEtiquetaProducao`$$

CREATE PROCEDURE `PROC_INTEGRA_MovtoEtiquetaProducao`(
   IN xTipoParam TINYINT,
   IN xCodEmp VARCHAR(03),
   IN xCodFil VARCHAR(03),
   IN xNumLote VARCHAR(20),
   IN xSeqLote INT,
   IN xBarCode VARCHAR(80)
)
BLOCO1:BEGIN
   /***************************************************************************
   #@Author David Ruy <2023/11/29>
   # Listar ou Atualizar Tabela de controle de Etiquetas de Produção SAP "lidas" no SLIN
   #               xTipoParam = 1 => Listagem dos registros | 2 => Insere/Atualiza tbintegraSAP_EtiquetaUA
   #@Reviser David Ruy <2023-12-01> Não retornar se a GEM ainda estiver aberta (dthr_confirm is not null) (DESABILITADO - SOLICITAÇÃO FELIPE PANIZZON)
   ****************************************************************************/
   DECLARE RESULTADO INT DEFAULT 1;
   DECLARE MENSAGEM VARCHAR(500);
   DECLARE excecao INT DEFAULT 0;
   DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   
   
   IF xTipoParam = 1 THEN
      SELECT tbEst.cod_emp, tbEst.cod_fil, tbEst.num_lote, tbEst.sequencia_lote, tbEst.num_caixa_barcode,
             tbsolic_entradas_acons.dthr_conf, tbEst.data_fabr, tbEst.data_valid, tbEst.posicao_ant,
             CONCAT(tbEst.cod_und, "/", tbEst.cod_armazem, "-", 
                    tbEst.camara, ".", tbEst.rua, ".", tbEst.posicao, ".", tbEst.altura, ".", tbEst.profund) Endereco
      FROM of_logistica.tbwms_estoque tbEst
      INNER JOIN of_logistica.tbsolic_entradas_acons ON
                 tbsolic_entradas_acons.cod_emp  = tbEst.cod_emp 
             AND tbsolic_entradas_acons.cod_fil  = tbEst.cod_fil 
             AND tbsolic_entradas_acons.num_lote = tbEst.num_lote
             AND tbsolic_entradas_acons.sequencia_lote= tbEst.sequencia_lote
      /*INNER JOIN of_logistica.tbsolic_entradas ON
                 tbsolic_entradas.cod_emp   = tbEst.cod_emp 
             AND tbsolic_entradas.cod_fil   = tbEst.cod_fil 
             AND tbsolic_entradas.ano_solic = tbEst.ano_solic
             AND tbsolic_entradas.num_solic = tbEst.num_solic*/
      WHERE tbEst.num_caixa_barcode IS NOT NULL
      #AND tbsolic_entradas.dthr_confirm is not null
      AND tbsolic_entradas_acons.dthr_conf >= '2023-12-01'
      AND NOT EXISTS (SELECT 1 FROM tbintegraSAP_EtiquetaUA tbEtiq
                      WHERE tbEtiq.cod_emp  = tbEst.cod_emp
                        AND tbEtiq.cod_fil  = tbEst.cod_fil
                        AND tbEtiq.num_lote = tbEst.num_lote
                        AND tbEtiq.sequencia_lote = tbEst.sequencia_lote)
      #and tbEst.num_lote= '0000019611'
      #Limit 0
      ;
   
   ELSEIF xTipoParam = 2 THEN
   
      IF NOT EXISTS (SELECT 1 FROM tbintegraSAP_EtiquetaUA 
                     WHERE cod_emp   = xCodEmp
                       AND cod_fil   = xCodFil
                       AND num_lote  = xNumLote
                       AND sequencia_lote = xSeqLote) THEN
         INSERT INTO tbintegraSAP_EtiquetaUA (
            cod_emp, cod_fil, num_lote, sequencia_lote, barcode_etiqueta, dthr_inc)
         VALUES (xCodEmp, xCodFil, xNumLote, xSeqLote, xBarCode, NOW());
      END IF;
   END IF;
      
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      SELECT RESULTADO, MENSAGEM;
   ELSE    
      SET RESULTADO = 1;
      SET MENSAGEM  = 'Processo Realizado com sucesso!';
   END IF;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_ProcessarAlteracoes.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_ProcessarAlteracoes` $$

CREATE PROCEDURE `PROC_INTEGRA_ProcessarAlteracoes`(
   # Parametros de Retorno
   OUT RESULTADO      INT,
   OUT MENSAGEM       VARCHAR(500)
)
BLOCO1:BEGIN
   /********************************************************************************/
   #@Reviser David Ruy <2021-12-12> Ajuste WHERE tbUpdCancPV.TipoUpdCanc IN ('U','C')
   #                                estava WHERE true
   #@Reviser David Ruy <2023-02-07> Alteração PROC_INTEGRA_GerarGSM (Parametros xBaseQty, e xOpenInvQty) : xQuantity, xQtdeEstoque
   #@Reviser David Ruy <2025-02-25> Considerar Quantity (BaseQty) ou QtdeEstoque (OpenInvQty) conforme xemb_estoque = xsalUnitMsr
   /********************************************************************************/
   DECLARE xCodEmpWMS			      VARCHAR(03);
   DECLARE xCodFilWMS			      VARCHAR(03);
   DECLARE xAnoSolic 			      VARCHAR(04);
   DECLARE xNumSolic 			      VARCHAR(10);
   DECLARE xNumItem           VARCHAR(06);
   DECLARE xCodEmpTMS         VARCHAR(03);
   DECLARE xCodFilTMS         VARCHAR(03);
   DECLARE xCnpjCpfCli        VARCHAR(14);
   DECLARE xNumPedido         VARCHAR(20);
   DECLARE xCnpjCpfDep        VARCHAR(14);
   DECLARE xCodProduto        VARCHAR(30);
   DECLARE xemb_estoque       VARCHAR(10);
   DECLARE xemb_frac          VARCHAR(10);
   DECLARE xemb_vol           VARCHAR(10);
   DECLARE xfator_conversao   DECIMAL(18,6);
   DECLARE xpeso_liq_vol      DECIMAL(18,6);
   DECLARE xpeso_brt_vol      DECIMAL(18,6);
   
   DECLARE xpeso_liq_frac     DECIMAL(18,5);
   DECLARE xpesoLiqItem       DECIMAL(18,5);
   DECLARE xQtdeFrac          DECIMAL(18,5);
   DECLARE xQtdeEst           DECIMAL(18,5);
   DECLARE xQtdeRegs          INT DEFAULT 0;
 
   DECLARE xItemCode          VARCHAR(20);
   DECLARE xQuantity          DECIMAL(18,6);
   DECLARE xQtdeEstoque       DECIMAL(18,6);
   DECLARE xQtdeVolumes       DECIMAL(18,6);
   DECLARE xUniqueKey         VARCHAR(30);
   DECLARE xUpdateDate        DATETIME;
   DECLARE xTipoUpdCanc       VARCHAR(01);
   
   DECLARE xDocEntry          INT;
   DECLARE xDocTipo           VARCHAR(10);
   DECLARE xDocNum            INT;
   DECLARE xStatusItem        VARCHAR(20);
   DECLARE xLineNum           INT;
   
   DECLARE xEmbVendas         VARCHAR(10);
   DECLARE excecao 	         INT DEFAULT 0;
   
   #Informações do item para inserir na tbsolic_saidas_item
   DECLARE xdescription       VARCHAR(100);
   DECLARE xBaseQty           DECIMAL(18,6);
   DECLARE xVlrUnitario       DECIMAL(18,6);
   DECLARE xsalUnitMsr        VARCHAR(30);
   DECLARE xinvntryUom        VARCHAR(30);
   DECLARE xNumInsale         DECIMAL(18,5);
   DECLARE xObservacoesIte    TEXT;
   DECLARE xCardCode          VARCHAR(15);
   DECLARE xCardName          VARCHAR(100);
   DECLARE xBatchCode         VARCHAR(30);
   DECLARE xWhareHouseIte     VARCHAR(30);
   DECLARE xRefGuia           VARCHAR(30);
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       ROLLBACK;
   END;
   
   START TRANSACTION;
   
   
   #@Reviser David Ruy <2022-04-12>
   #Seleciona os itens a inserir na tbsolic_saidas_item
   DROP TEMPORARY TABLE IF EXISTS TMP_IncluirItem;
   CREATE TEMPORARY TABLE TMP_IncluirItem ( 
      SELECT tbUpdCancPV.TipoUpdCanc,tbUpdCancPV.UniqueKey, tbUpdCancPV.DocumentType, 
             tbUpdCancPV.DocumentId, tbUpdCancPV.DocumentNumber,
             tbUpdCancPV.DocumentDate, tbUpdCancPV.LineNumber, tbUpdCancPV.UpdateDate, 
             tbUpdCancPV.Quantity, 
             #IFNULL(tbUpdCancPV.QtdeEstoque,tbUpdCancPV.Quantity*IFNULL(tbItem.NumInsale,1))  QtdeEstoque, 
             IF(tbUpdCancPV.SalUnitMsr = tbprodutos.emb_estoque,
                tbUpdCancPV.Quantity,
                IFNULL(tbUpdCancPV.QtdeEstoque,tbUpdCancPV.Quantity*IFNULL(tbItem.NumInsale,1)))  QtdeEstoque, 
             tbUpdCancPV.SalUnitMsr,
             IFNULL(tbUpdCancPV.ItemCode,tbItem.ItemCode) ItemCode, tbItem.StatusItem,
             tbSolic.cod_emp, tbSolic.cod_fil, tbSolic.ano_solic, tbSolic.num_solic,
             tbSolic.cnpj_cpf_dep, tbTopo.idPicking,
             #
             tbItem.description, tbItem.Price, tbItem.invntryUom,
             tbItem.NumInsale, tbItem.Observacoes, tbTopo.CardCode, tbTopo.CardName, BatchNumbersCode, tbItem.WhareHouse,
             #
             0 AS FlgProcessado
      FROM tbintegraSAP_UpdCancPV tbUpdCancPV 
      INNER JOIN tbintegraSAP_Doc tbTopo ON 
                 tbTopo.DocEntry = tbUpdCancPV.DocumentId
             AND tbTopo.DocTipo  = tbUpdCancPV.DocumentType 
             AND tbTopo.DocNum   = tbUpdCancPV.DocumentNumber 
      INNER JOIN tbintegraSAP_DocItem tbItem ON 
                 tbItem.DocEntry = tbUpdCancPV.DocumentId
             AND tbItem.DocTipo  = tbUpdCancPV.DocumentType 
             AND tbItem.DocNum   = tbUpdCancPV.DocumentNumber 
             AND tbItem.LineNum  = tbUpdCancPV.LineNumber 
      LEFT JOIN of_logistica.tbsolic_saidas tbSolic ON 
                 tbSolic.cod_emp   = tbTopo.cod_emp
             AND tbSolic.cod_fil   = tbTopo.cod_fil
             AND tbSolic.ano_solic = tbTopo.ano_solic
             AND tbSolic.num_solic = tbTopo.num_solic
      LEFT JOIN of_logistica.tbprodutos ON 
                 tbprodutos.cnpj_cpf = tbSolic.cnpj_cpf_dep
             AND tbprodutos.cod_produto = tbUpdCancPV.ItemCode
      WHERE tbUpdCancPV.TipoUpdCanc IN ('U','C')
        AND tbUpdCancPV.STATUS = 1
        AND tbItem.StatusItem = 2);
        
   #Insere os itens na tbsolic_saidas_item
   SET xQtdeRegs = 0;
   WHILE EXISTS (SELECT 1 FROM TMP_IncluirItem WHERE TMP_IncluirItem.FlgProcessado = 0) DO
   
      SELECT cod_emp, cod_fil, ano_solic, num_solic, 
             TipoUpdCanc, UniqueKey, UpdateDate, Quantity, QtdeEstoque, 
             SalUnitMsr, cnpj_cpf_dep, 
             ItemCode, StatusItem,
             DocumentId, DocumentType, DocumentNumber, LineNumber,
             description, price, salUnitMsr, invntryUom,
             NumInsale, Observacoes, CardCode, CardName, BatchNumbersCode, WhareHouse
      INTO xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, 
           xTipoUpdCanc, xUniqueKey, xUpdateDate, xQuantity, xQtdeEstoque, xEmbVendas, xCnpjCpfDep, 
           xItemCode, xStatusItem,
           xDocEntry, xDocTipo, xDocNum, xLineNum,
           xdescription, xVlrUnitario, xsalUnitMsr, xinvntryUom,
           xNumInsale, xObservacoesIte, xCardCode, xCardName, xBatchCode, xWhareHouseIte
      FROM TMP_IncluirItem
      WHERE TMP_IncluirItem.FlgProcessado = 0
      LIMIT 1;
      
      SET xRefGuia     = CONCAT(xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic);
      SET xVlrUnitario = IF(IFNULL(xVlrUnitario,1)=0,1,IFNULL(xVlrUnitario,1));
      SET xdescription = IFNULL(xdescription,'');
      SET xsalUnitMsr = IFNULL(xsalUnitMsr,'');
      SET xinvntryUom = IFNULL(xinvntryUom,'');      
      
      SET xQtdeRegs = xQtdeRegs + 1;
      CALL PROC_INTEGRA_GerarGSMItem('999999', xRefGuia, 
                                     CONCAT(xDocNum,'(',xDocEntry,')'), xLineNum, xItemCode, xdescription, xQuantity, xQtdeEstoque, xVlrUnitario, 
                                     xsalUnitMsr, xinvntryUom, xNumInsale, xStatusItem, xObservacoesIte, xCardCode, xCardName, xBatchCode, 
                                     xWhareHouseIte, @R, @M);
      SET xNumItem    = SUBSTRING(@M,01,06);  #Numero do item no retorno da proc
      IF (xStatusItem <> 0) AND (@R = 1) THEN
         UPDATE tbintegraSAP_DocItem
         SET cod_emp     = xCodEmpWMS
            ,cod_fil     = xCodFilWMS
            ,ano_solic   = xAnoSolic
            ,num_solic   = xNumSolic
            ,num_item    = xNumItem
            ,StatusAnt   = StatusItem
            ,StatusItem  = '0'    #Volta para Zero para identificar que já atualizou no SLIN
         WHERE DocTipo  = xDocTipo
           AND DocEntry = xDocEntry
           AND LineNum  = xLineNum;
           
           
      INSERT INTO of_logistica.tbsolic_saidas_item_integra_alteracao (
                  cod_emp, cod_fil, ano_solic, num_solic, num_item, UniqueKey, dthr_inc, 
                  qtde_est_ant, qtde_vol_ant, qtde_frac_ant, qtde_peso_ant, 
                  qtde_est_atu , qtde_vol_atu, qtde_frac_atu, qtde_peso_atu)
         SELECT tbItem.cod_emp, tbItem.cod_fil, tbItem.ano_solic, tbItem.num_solic, tbItem.num_item,
                TMP_IncluirItem.UniqueKey, TMP_IncluirItem.UpdateDate, 
                0,0,0,0,
                tbItem.qtde_est, tbItem.qtde_vol, tbItem.qtde_frac, tbItem.pliq_item
         FROM TMP_IncluirItem
         INNER JOIN of_logistica.tbsolic_saidas_item tbItem ON
               tbItem.cod_emp   = TMP_IncluirItem.cod_emp 
           AND tbItem.cod_fil   = TMP_IncluirItem.cod_fil
           AND tbItem.ano_solic = TMP_IncluirItem.ano_solic 
           AND tbItem.num_solic = TMP_IncluirItem.num_solic
           AND tbItem.num_item  = xNumItem
         WHERE DocumentType   = xDocTipo
           AND DocumentId     = xDocEntry
           AND DocumentNumber = xDocNum
           AND Linenumber     = xLineNum;
           
      ELSE
          CALL PROC_INTEGRA_EnviarLog('999999',
                IF(xDocTipo IN ("PV","OP","TD-S"),'PROC_INTEGRA_GerarGSMItem','PROC_INTEGRA_GerarGEMItem'), 
                  CONCAT('NÃO Inserido/Atualizado ',xDocTipo,xDocEntry,'-',xDocNum,' | ', xRefGuia, '| Prd:', xItemCode), "0", @M, @R, @M);
      END IF;
      
      UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV 
      INNER JOIN tbintegraSAP_DocItem tbItem ON 
                 tbItem.DocEntry = tbUpdCancPV.DocumentId
             AND tbItem.DocTipo  = tbUpdCancPV.DocumentType 
             AND tbItem.DocNum   = tbUpdCancPV.DocumentNumber 
             AND tbItem.LineNum  = tbUpdCancPV.LineNumber 
      SET tbUpdCancPV.cod_emp = tbItem.cod_emp, 
          tbUpdCancPV.cod_fil = tbItem.cod_fil,
          tbUpdCancPV.ano_solic = tbItem.ano_solic,
          tbUpdCancPV.num_solic = tbItem.num_solic, 
          tbUpdCancPV.num_item  = tbItem.num_item,
          tbUpdCancPV.status    = 2,
          tbUpdCancPV.FreeText  = CONCAT(IFNULL(tbUpdCancPV.FreeText,""),"|(4.9)Inc Item =>",xDocTipo,xDocNum),
          tbItem.StatusAnt  = IF(tbItem.StatusItem = 9, tbItem.StatusAnt, tbItem.StatusItem),
          tbItem.StatusItem = IF(tbItem.StatusItem = 9, tbItem.StatusItem, 0)
      WHERE tbUpdCancPV.UniqueKey  = xUniqueKey
        AND tbUpdCancPV.UpdateDate = xUpdateDate;
           
                 
      DELETE FROM TMP_IncluirItem
      WHERE UniqueKey = xUniqueKey;
      
   END WHILE;
   DROP TEMPORARY TABLE IF EXISTS TMP_IncluirItem;
   
   
   DROP TEMPORARY TABLE IF EXISTS TMP_UpdCancPV;
   CREATE TEMPORARY TABLE TMP_UpdCancPV ( 
      SELECT tbUpdCancPV.TipoUpdCanc,tbUpdCancPV.UniqueKey, tbUpdCancPV.DocumentType, 
             tbUpdCancPV.DocumentId, tbUpdCancPV.DocumentNumber,
             tbUpdCancPV.DocumentDate, tbUpdCancPV.LineNumber, tbUpdCancPV.UpdateDate, 
             tbUpdCancPV.Quantity, 
             #tbUpdCancPV.QtdeEstoque, 
             IF(tbUpdCancPV.SalUnitMsr = tbprodutos.emb_estoque,
                tbUpdCancPV.Quantity,
                IFNULL(tbUpdCancPV.QtdeEstoque,tbUpdCancPV.Quantity*IFNULL(tbItem.NumInsale,1)))  QtdeEstoque, 
             tbUpdCancPV.SalUnitMsr,
             IFNULL(tbUpdCancPV.ItemCode,tbItem.ItemCode) ItemCode, tbItem.StatusItem,
             tbItem.cod_emp, tbItem.cod_fil, tbItem.ano_solic, tbItem.num_solic, tbItem.num_item,
             tbIte.cnpj_cpf_dep, tbIte.cod_produto, tbTopo.idPicking,
             0 AS FlgProcessado
      FROM tbintegraSAP_UpdCancPV tbUpdCancPV 
      INNER JOIN tbintegraSAP_Doc tbTopo ON 
                 tbTopo.DocEntry = tbUpdCancPV.DocumentId
             AND tbTopo.DocTipo  = tbUpdCancPV.DocumentType 
             AND tbTopo.DocNum   = tbUpdCancPV.DocumentNumber 
      INNER JOIN tbintegraSAP_DocItem tbItem ON 
                 tbItem.DocEntry = tbUpdCancPV.DocumentId
             AND tbItem.DocTipo  = tbUpdCancPV.DocumentType 
             AND tbItem.DocNum   = tbUpdCancPV.DocumentNumber 
             AND tbItem.LineNum  = tbUpdCancPV.LineNumber 
      INNER JOIN of_logistica.tbsolic_saidas_item tbIte ON 
                 tbIte.cod_emp   = tbItem.cod_emp
             AND tbIte.cod_fil   = tbItem.cod_fil
             AND tbIte.ano_solic = tbItem.ano_solic
             AND tbIte.num_solic = tbItem.num_solic
             AND tbIte.num_item  = tbItem.num_item
      LEFT JOIN of_logistica.tbprodutos ON 
                 tbprodutos.cnpj_cpf = tbIte.cnpj_cpf_dep
             AND tbprodutos.cod_produto = tbIte.cod_produto
      WHERE tbUpdCancPV.TipoUpdCanc IN ('U','C')
        AND tbUpdCancPV.STATUS = 1
        #AND tbUpdCancPV.flg_deleted = 0
   );
   #select "aqui",TMP_UpdCancPV.* from TMP_UpdCancPV;
   
   WHILE EXISTS (SELECT 1 FROM TMP_UpdCancPV WHERE TMP_UpdCancPV.FlgProcessado = 0) DO
   
      SET xQtdeRegs = xQtdeRegs + 1;
      
      SELECT cod_emp, cod_fil, ano_solic, num_solic, num_item,
             TipoUpdCanc, UniqueKey, UpdateDate, Quantity, QtdeEstoque, SalUnitMsr, cnpj_cpf_dep, 
             ItemCode, cod_produto, StatusItem,
             DocumentId, DocumentType, DocumentNumber
      INTO xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xNumItem,
           xTipoUpdCanc, xUniqueKey, xUpdateDate, xQuantity, xQtdeEstoque, xEmbVendas, xCnpjCpfDep, 
           xItemCode, xCodProduto, xStatusItem,
           xDocEntry, xDocTipo, xDocNum
      FROM TMP_UpdCancPV
      WHERE TMP_UpdCancPV.FlgProcessado = 0
      LIMIT 1;
      
      #Quando for item deletado, xItemCode vem nulo
      SET xItemCode = IFNULL(xItemCode, xCodProduto);
      
      #Pega as informações do cadastro de produtos
      SELECT emb_estoque, emb_frac, emb_vol, fator_conversao, peso_liq_vol, peso_bruto_vol, peso_liq_frac
      INTO xemb_estoque, xemb_frac, xemb_vol, xfator_conversao, xpeso_liq_vol, xpeso_brt_vol, xpeso_liq_frac
      FROM of_logistica.tbprodutos
      WHERE cnpj_cpf = xCnpjCpfDep
        AND cod_produto = xItemCode;
     
      #select "aqui", xItemCode, xCodProduto;     
     
      IF xTipoUpdCanc = 'U' THEN
         #Calcula quantidade de volumes
         IF LOCATE('KG',xemb_estoque)  THEN
            SET xQtdevolumes = xQtdeEstoque / xpeso_liq_vol;
            SET xpesoLiqItem = xQtdeEstoque;
         ELSEIF xemb_estoque = xemb_vol THEN
            SET xQtdevolumes = xQtdeEstoque;
            SET xpesoLiqItem = xQtdevolumes * xpeso_liq_vol;
         ELSEIF xemb_estoque = xemb_frac THEN
            SET xQtdevolumes = xQtdeEstoque / xfator_conversao;
            SET xpesoLiqItem = xQtdevolumes * xpeso_liq_vol;  
         ELSE
            SET xQtdevolumes = xQuantity;
         END IF;
         
         SET xQtdeFrac = of_logistica.fnCalcQtdeFrac(xemb_frac, xfator_conversao, xpeso_liq_vol * xQtdevolumes, xQtdeVolumes);
      ELSE
         SET xQtdevolumes = 0;
         SET xpesoLiqItem = 0;
         SET xQtdeFrac = 0;
      END IF;

      #SELECT "aqui", xItemCode, xCodProduto;     
      
      INSERT INTO of_logistica.tbsolic_saidas_item_integra_alteracao (
                  cod_emp, cod_fil, ano_solic, num_solic, num_item, UniqueKey, dthr_inc, 
                  qtde_est_ant, qtde_vol_ant, qtde_frac_ant, qtde_peso_ant, 
                  qtde_est_atu , qtde_vol_atu, qtde_frac_atu, qtde_peso_atu)
         SELECT tbItem.cod_emp, tbItem.cod_fil, tbItem.ano_solic, tbItem.num_solic, tbItem.num_item,
                #TMP_UpdCancPV.UniqueKey, NOW() /*TMP_UpdCancPV.DocumentDate*/ , 
                TMP_UpdCancPV.UniqueKey, TMP_UpdCancPV.UpdateDate, 
                #Reviser David Ruy <2021/01/19> Campos conforme andamento do processo
                #tbItem.qtde_est, tbItem.qtde_vol, tbItem.qtde_frac, tbItem.pliq_item
                IF(dthr_final_baixa_geral IS NOT NULL,
                   tbItem.real_est2, IF(dthr_aconselhamento IS NOT NULL, tbItem.real_est, tbItem.qtde_est)),
                IF(dthr_final_baixa_geral IS NOT NULL,
                   tbItem.real_vol2, IF(dthr_aconselhamento IS NOT NULL, tbItem.real_vol, tbItem.qtde_vol)),
                IF(dthr_final_baixa_geral IS NOT NULL,
                   tbItem.real_frac2, IF(dthr_aconselhamento IS NOT NULL, tbItem.real_frac, tbItem.qtde_frac)),
                IF(dthr_final_baixa_geral IS NOT NULL,
                   tbItem.real_peso2, IF(dthr_aconselhamento IS NOT NULL, tbItem.real_peso, tbItem.pliq_item)),
                TMP_UpdCancPV.QtdeEstoque, xQtdevolumes, xQtdeFrac, xpesoLiqItem
         FROM TMP_UpdCancPV
         INNER JOIN of_logistica.tbsolic_saidas_item tbItem ON
               tbItem.cod_emp   = TMP_UpdCancPV.cod_emp 
           AND tbItem.cod_fil   = TMP_UpdCancPV.cod_fil
           AND tbItem.ano_solic = TMP_UpdCancPV.ano_solic 
           AND tbItem.num_solic = TMP_UpdCancPV.num_solic
           AND tbItem.num_item  = TMP_UpdCancPV.num_item
         WHERE TMP_UpdCancPV.UniqueKey  = xUniqueKey
           AND TMP_UpdCancPV.UpdateDate = xUpdateDate
         #@Reviser David Ruy <2021/01/19> Verifica diferença de quantidades
         AND (tbItem.cod_produto <> IFNULL(TMP_UpdCancPV.ItemCode,TMP_UpdCancPV.cod_produto)
           OR IF(dthr_final_baixa_geral IS NOT NULL,
                 ABS(tbItem.real_est2 - IFNULL(TMP_UpdCancPV.QtdeEstoque,0)) >= 0.001,
                 IF(dthr_aconselhamento IS NOT NULL,
                    ABS(tbItem.real_est - IFNULL(TMP_UpdCancPV.QtdeEstoque,0)) >= 0.001,
                    ABS(tbItem.qtde_est - IFNULL(TMP_UpdCancPV.QtdeEstoque,0)) >= 0.001
                    )
                 )
              );
         #@Reviser David Ruy <2020/05/14> Verifica diferença de quantidades
         #AND IF(tbItem.real_est IS NULL,
         #       ABS(tbItem.qtde_est - IFNULL(TMP_UpdCancPV.QtdeEstoque,0)) >= 0.001,
         #       ABS(tbItem.real_est - IFNULL(TMP_UpdCancPV.QtdeEstoque,0)) >= 0.001);
         
      #SELECT "aqui", xItemCode, xCodProduto;     
         
      #@Reviser David Ruy <2020/05/14> Só gera registro se quantidade for diferente
      IF ROW_COUNT() > 0 THEN
         #Atualizar Qtde Pedido (WMS)
         UPDATE of_logistica.tbsolic_saidas_item tbItem
         INNER JOIN of_logistica.tbsolic_saidas tbTopo ON
                    tbTopo.cod_emp   = tbItem.cod_emp 
                AND tbTopo.cod_fil   = tbItem.cod_fil
                AND tbTopo.ano_solic = tbItem.ano_solic
                AND tbTopo.num_solic = tbItem.num_solic
         SET tbItem.cod_produto = xItemCode,
             tbItem.qtde_nf     = xQuantity,
             tbItem.qtde_est    = xQtdeEstoque,
             tbItem.qtde_vol    = xQtdevolumes,
             tbItem.qtde_frac   = xQtdeFrac,
             tbItem.pliq_item   = xpesoLiqItem,
             tbItem.pbrt_item   = xpesoLiqItem + ((xpeso_brt_vol-xpeso_liq_vol) * xQtdevolumes),
             tbTopo.dthr_bloqueio_fin = IF(tbTopo.dthr_bloqueio_ini IS NULL, NULL, NOW()),
             tbTopo.usu_bloqueio_fin  = IF(tbTopo.usu_bloqueio_ini IS NULL, NULL, '999999')
         WHERE tbItem.cod_emp   = xCodEmpWMS
           AND tbItem.cod_fil   = xCodFilWMS
           AND tbItem.ano_solic = xAnoSolic
           AND tbItem.num_solic = xNumSolic
           AND tbItem.num_item  = xNumItem;
           
           
         SELECT cod_emp_pedido, cod_fil_pedido, cnpj_cpf_cli, num_ped_aux
         INTO xCodEmpTMS, xCodFilTMS, xCnpjCpfCli, xNumPedido
         FROM of_logistica.tbsolic_saidas_item
         WHERE cod_emp   = xCodEmpWMS
           AND cod_fil   = xCodFilWMS
           AND ano_solic = xAnoSolic
           AND num_solic = xNumSolic
           AND num_item  = xNumItem;
         
           
         #Atualizar Qtde Pedido (TMS)
         UPDATE of_logistica.tbprog_entregas Topo
         INNER JOIN of_logistica.tbprog_ite_entregas Item ON
                     Topo.cod_emp     = Item.cod_emp
                 AND Topo.cod_fil     = Item.cod_fil
                 AND Topo.ano_entrega = Item.ano_entrega
                 AND Topo.num_entrega = Item.num_entrega
         INNER JOIN of_logistica.tbnf_ite_clientes ItemNF ON
                    ItemNF.id_nf    = Topo.id_nf
                AND ItemNF.num_item = Item.num_item
         SET Item.cod_produto     = xItemCode,
             Item.qtde_ori        = xQtdeEstoque,
             Item.qtde_vol        = xQtdevolumes,
             Item.qtde_frac       = xQtdeFrac,
             Item.peso_liq_item   = xpesoLiqItem,
             Item.peso_brt_item   = xpesoLiqItem + ((xpeso_brt_vol-xpeso_liq_vol) * xQtdevolumes),
             ItemNF.cod_produto   = xItemCode,
             ItemNF.qtde_ori      = xQtdeEstoque,
             ItemNF.qtde_vol      = xQtdevolumes,
             ItemNF.qtde_frac     = xQtdeFrac,
             ItemNF.peso_liq_item = xpesoLiqItem,
             ItemNF.peso_brt_item = xpesoLiqItem + ((xpeso_brt_vol-xpeso_liq_vol) * xQtdevolumes)          
         WHERE Topo.cod_emp      = xCodEmpTMS
           AND Topo.cod_fil      = xCodFilTMS
           AND Topo.cnpj_cpf_cli = xCnpjCpfCli
           AND Topo.num_ped_aux  = xNumPedido
           AND Item.num_item     = xNumItem;
           
           
         #Atualiza Status da Integração para casos de alteração após a finalização do processo
         CALL PROC_INTEGRA_ReabrirIntegracao(xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, "S", RESULTADO, MENSAGEM);
         #*********************** Verificar : Atualizar Topo Pedido / NF (TMS)
         
         
         UPDATE TMP_UpdCancPV
         SET TMP_UpdCancPV.FlgProcessado = 1
         WHERE TMP_UpdCancPV.UniqueKey  = xUniqueKey
           AND TMP_UpdCancPV.UpdateDate = xUpdateDate;
         
         UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV 
         INNER JOIN tbintegraSAP_DocItem tbItem ON 
                    tbItem.DocEntry = tbUpdCancPV.DocumentId
                AND tbItem.DocTipo  = tbUpdCancPV.DocumentType 
                AND tbItem.DocNum   = tbUpdCancPV.DocumentNumber 
                AND tbItem.LineNum  = tbUpdCancPV.LineNumber 
         SET tbUpdCancPV.cod_emp = tbItem.cod_emp, 
             tbUpdCancPV.cod_fil = tbItem.cod_fil,
             tbUpdCancPV.ano_solic = tbItem.ano_solic,
             tbUpdCancPV.num_solic = tbItem.num_solic, 
             tbUpdCancPV.num_item  = tbItem.num_item,
             tbUpdCancPV.status    = 2,
             tbUpdCancPV.FreeText  = CONCAT(IFNULL(tbUpdCancPV.FreeText,""),"|(5)Atu Item =>",xDocTipo,xDocNum),
             tbItem.StatusAnt  = IF(tbItem.StatusItem = 9, tbItem.StatusAnt, tbItem.StatusItem),
             tbItem.StatusItem = IF(tbItem.StatusItem = 9, tbItem.StatusItem, 0)
         WHERE tbUpdCancPV.UniqueKey  = xUniqueKey
           AND tbUpdCancPV.UpdateDate = xUpdateDate;
         
      ELSE
      
         UPDATE TMP_UpdCancPV
         SET TMP_UpdCancPV.FlgProcessado = 1
         WHERE TMP_UpdCancPV.UniqueKey = xUniqueKey;
         
         #Libera o registro da atualilazação
         UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV 
         INNER JOIN tbintegraSAP_DocItem tbItem ON 
                    tbItem.DocEntry = tbUpdCancPV.DocumentId
                AND tbItem.DocTipo  = tbUpdCancPV.DocumentType 
                AND tbItem.DocNum   = tbUpdCancPV.DocumentNumber 
                AND tbItem.LineNum  = tbUpdCancPV.LineNumber 
         SET tbUpdCancPV.cod_emp = tbItem.cod_emp, 
             tbUpdCancPV.cod_fil = tbItem.cod_fil,
             tbUpdCancPV.ano_solic = tbItem.ano_solic,
             tbUpdCancPV.num_solic = tbItem.num_solic, 
             tbUpdCancPV.num_item  = tbItem.num_item,
             tbUpdCancPV.STATUS    = 3,
             tbItem.StatusAnt  = IF(tbItem.StatusItem = 9, tbItem.StatusAnt, tbItem.StatusItem),
             tbItem.StatusItem = IF(tbItem.StatusItem = 9, tbItem.StatusItem, 0),
             tbUpdCancPV.FreeText  = CONCAT(IFNULL(tbUpdCancPV.FreeText,""),"|(6)Atu Item =>",xDocTipo,xDocNum)
         WHERE tbUpdCancPV.UniqueKey  = xUniqueKey
           AND tbUpdCancPV.UpdateDate = xUpdateDate;
      
      
      END IF;
      
      UPDATE tbintegraSAP_Doc
      LEFT JOIN tbintegraSAP_DocItem tbItem ON
                tbItem.DocEntry = tbintegraSAP_Doc.DocEntry
            AND tbItem.DocTipo  = tbintegraSAP_Doc.DocTipo
            AND tbItem.DocNum   = tbintegraSAP_Doc.DocNum
      SET UpdateDate = xUpdateDate,
          tbItem.StatusAnt  = IF(tbItem.StatusItem = 9, tbItem.StatusAnt, tbItem.StatusItem),
          tbItem.StatusItem = IF(tbItem.StatusItem = 9, tbItem.StatusItem, 0)
      WHERE tbintegraSAP_Doc.DocEntry = xDocEntry
        AND tbintegraSAP_Doc.DocTipo  = xDocTipo
        AND tbintegraSAP_Doc.DocNum   = xDocNum;      
      
   END WHILE;
   
   DROP TEMPORARY TABLE IF EXISTS TMP_UpdCancPV;  
   
   IF excecao = 1 THEN
      ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- Erro PROC_INTEGRA_ProcessarAlteraoes [",xQtdeRegs,"]");
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      COMMIT;
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- Alterações processadas com sucesso [",xQtdeRegs,"]");
   END IF;
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_ReabrirIntegracao.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_ReabrirIntegracao`$$

CREATE PROCEDURE `PROC_INTEGRA_ReabrirIntegracao`(
   IN xCodEmpWMS			   VARCHAR(03),
   IN xCodFilWMS			   VARCHAR(03),
   IN xAnoSolic 			   VARCHAR(04),
   IN xNumSolic 			   VARCHAR(10),
   IN xTipoDoc        VARCHAR(01),    #E=Entrada / S=Saída
   # Parametros de Retorno
   OUT RESULTADO      INT,
   OUT MENSAGEM       VARCHAR(500)
)
BLOCO1:BEGIN
   /*
   #@Reviser David Ruy <2022/04/29> Ajuste LPAD para variaveis xCodEmpWMS/xCodFilWMS/xNumSolic
   #Reviser David Ruy <2022/04/29> Ajuste Retorno SET MENSAGEM = CONCAT(xCodEmpWMS,'/',xCodFilWMS,'-',xNumSolic,'.',xAnoSolic);   
   #Reviser David Ruy <20230606> Ajuste condição update status tbsolic_saidas
   */

   DECLARE xVarOK        INT DEFAULT 0;
   DECLARE excecao 	    INT DEFAULT 0;   
   DECLARE xCodUsuario   VARCHAR(06) DEFAULT "999999";


   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       #ROLLBACK;
   END;
   
   #Transação tratada pela procedure "Pai"   
   #START TRANSACTION;
   
   SET xCodEmpWMS	= LPAD(xCodEmpWMS, 3, '0');
   SET xCodFilWMS = LPAD(xCodFilWMS, 3, '0');
   SET xNumSolic  = LPAD(xNumSolic, 10, '0');
   
   IF xTipoDoc = 'E' THEN  
      UPDATE of_logistica.tbsolic_entradas tbTopo 
      SET tbTopo.dthr_retorno_integracao = NULL
      WHERE tbTopo.cod_emp   = xCodEmpWMS
        AND tbTopo.cod_fil   = xCodFilWMS
        AND tbTopo.ano_solic = xAnoSolic
        AND tbTopo.num_solic = xNumSolic;
        
      IF ROW_COUNT() > 0 THEN        
         #Atualizar Status na tbIntegra_DOC apenas se dthr_retorno_integracao não estiver Nulo
         UPDATE tbintegraSAP_Doc tbTopo
         SET StatusAnt  = StatusDoc,
             StatusDoc  = IF(StatusDoc = 6, 3, StatusDoc),
             StatusSLIN = 1
         WHERE tbTopo.cod_emp   = xCodEmpWMS
           AND tbTopo.cod_fil   = xCodFilWMS
           AND tbTopo.ano_solic = xAnoSolic
           AND tbTopo.num_solic = xNumSolic
           AND tbTopo.TipoDocSLIN = xTipoDoc;
      END IF;
        
   ELSE
      
      SET xVarOK = EXISTS (SELECT 1 FROM of_logistica.tbsolic_saidas tbTopo 
                          WHERE tbTopo.cod_emp   = xCodEmpWMS
                            AND tbTopo.cod_fil   = xCodFilWMS
                            AND tbTopo.ano_solic = xAnoSolic
                            AND tbTopo.num_solic = xNumSolic
                            AND tbTopo.dthr_retorno_integracao IS NOT NULL);
   
      IF xVarOK THEN
      
         UPDATE of_logistica.tbsolic_saidas tbTopo 
         SET tbTopo.dthr_retorno_integracao = NULL,
             tbTopo.dthr_confirm    = NULL,
             tbTopo.usu_confirm     = NULL,
             tbTopo.dthr_alt        = NOW(),
             tbTopo.usu_alt         = '999999',
             tbTopo.status_solic    = IF(tbTopo.status_solic<2,tbTopo.status_solic,2),
             tbTopo.status_processo = IF(tbTopo.status_processo<6,tbTopo.status_processo,6)
         WHERE tbTopo.cod_emp   = xCodEmpWMS
           AND tbTopo.cod_fil   = xCodFilWMS
           AND tbTopo.ano_solic = xAnoSolic
           AND tbTopo.num_solic = xNumSolic;
        
         #Atualizar Status na tbIntegra_DOC apenas se dthr_retorno_integracao não estiver Nulo
         UPDATE tbintegraSAP_Doc tbTopo
         SET StatusAnt  = StatusAnt,
             StatusDoc  = IF(StatusDoc = 6, 3, StatusDoc),
             StatusSLIN = 1
         WHERE tbTopo.cod_emp     = xCodEmpWMS
           AND tbTopo.cod_fil     = xCodFilWMS
           AND tbTopo.ano_solic   = xAnoSolic
           AND tbTopo.num_solic   = xNumSolic
           AND tbTopo.TipoDocSLIN = xTipoDoc;
           
         INSERT INTO of_logistica.tbsolic_saidas_log_reabertura( cod_emp
                                                      , cod_fil
                                                      , ano_solic
                                                      , num_solic
                                                      , dthr_confirm
                                                      , usu_confirm
                                                      , dthr_log
                                                      , usu_log
                                                      , usu_log_lider
                                                      , form_log
                                                      , flg_reabertura_tipo
                                                      )
               SELECT tbsolic_saidas.cod_emp                          AS cod_emp
                    , tbsolic_saidas.cod_fil                          AS cod_fil
                    , tbsolic_saidas.ano_solic                        AS ano_solic
                    , tbsolic_saidas.num_solic                        AS num_solic
                    , tbsolic_saidas.dthr_confirm                     AS dthr_confirm
                    , tbsolic_saidas.usu_confirm                      AS usu_confirm
                    , NOW()                                           AS dthr_log
                    , XCodUsuario                                     AS usu_log
                    , NULL                                            AS usu_log_lider
                    , 'PROC_INTEGRA_REABRIRINTEGRACAO'                AS form_log
                    , 3                                               AS flg_reabertura_tipo 
                 FROM of_logistica.tbsolic_saidas
                WHERE tbsolic_saidas.cod_emp      = xCodEmpWMS
                  AND tbsolic_saidas.cod_fil      = xCodFilWMS
                  AND tbsolic_saidas.ano_solic    = xAnoSolic
                  AND tbsolic_saidas.num_solic    = xNumSolic
                  AND tbsolic_saidas.dthr_confirm IS NOT NULL;                       
      END IF;
   END IF;
   
   
   IF excecao = 1 THEN
      #ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- Erro PROC_INTEGRA_ReabrirIntegracao");
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      #COMMIT;
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT(xCodEmpWMS,'/',xCodFilWMS,'-',xNumSolic,'.',xAnoSolic);
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- PROC_INTEGRA_ReabrirIntegracao processada com sucesso");
   END IF;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_RetornoContagem.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_RetornoContagem`$$

CREATE PROCEDURE `PROC_INTEGRA_RetornoContagem`(
   IN oCodUsuario				      VARCHAR(10),
   IN oTipoSelecao         INT     #0 = Contagens a Criar, 1 = Contagens a Confirmar
   # Parametros de Retorno
   #OUT RESULTADO          INT,
   #OUT MENSAGEM           VARCHAR(500)
)
BLOCO1:BEGIN
   /***************************************************************************
   #@Autho David Ruy <2019/12/11>
   # Lista recebimentos a maior para envio ao SAP como complemento de entradas
   ****************************************************************************/
   DECLARE excecao         INT DEFAULT 0;
   DECLARE RESULTADO       INT DEFAULT 1;
   DECLARE MENSAGEM        VARCHAR(500);
   DECLARE xChave          VARCHAR(20);
   DECLARE xQtdeNF         DECIMAL(18,5);
   DECLARE xQtdeRecebido   DECIMAL(18,5);   
   DECLARE xSaldoaMaior    DECIMAL(18,5);
   DECLARE xqtde_est2      DECIMAL(18,5);
   DECLARE xnum_lote       VARCHAR(10);
   DECLARE xsequencia_lote INT;
   
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
    
   IF (oTipoSelecao = 0) THEN
      DROP TEMPORARY TABLE IF EXISTS tbTMPItemContagem;
      CREATE TEMPORARY TABLE tbTMPItemContagem
         SELECT tbwmsEstoque.cod_emp, tbwmsEstoque.cod_fil, tbwmsEstoque.ano_solic, tbwmsEstoque.num_solic, tbwmsEstoque.num_item, 
                tbItem.qtde_est, tbItem.real_est,
               (tbItem.real_est - tbItem.qtde_est) xSaldoaMaior,
                tbAcons.num_lote, tbAcons.sequencia_lote, tbAcons.qtde_est2,
                tbEntradas.num_nf AS NumDoc,
                tbwmsEstoque.cod_produto, tbwmsEstoque.num_lote_cli,
                tbIntegraArmazem.cod_armazem CodArmazemSAP, 
                of_logistica.fnLocalizCompleta2(tbwmsEstoque.cod_und, tbwmsEstoque.cod_armazem, tbwmsEstoque.camara, tbwmsEstoque.rua, 
                                 tbwmsEstoque.posicao, tbwmsEstoque.altura, tbwmsEstoque.profund, NULL, "Sem endereço") binCode
         FROM of_logistica.tbsolic_entradas_acons tbAcons
         INNER JOIN of_logistica.tbwms_estoque tbwmsEstoque ON
                tbwmsEstoque.cod_emp        = tbAcons.cod_emp 
            AND tbwmsEstoque.cod_fil        = tbAcons.cod_fil
            AND tbwmsEstoque.num_lote       = tbAcons.num_lote
            AND tbwmsEstoque.sequencia_lote = tbAcons.sequencia_lote
         LEFT JOIN tbintegraSAP_DeParaStatus_Armazem tbIntegraArmazem ON 
                     tbIntegraArmazem.cod_status = tbwmsEstoque.status_lote
         INNER JOIN of_logistica.tbsolic_entradas_item tbItem ON
                tbItem.cod_emp   = tbAcons.cod_emp 
            AND tbItem.cod_fil   = tbAcons.cod_fil
            AND tbItem.ano_solic = tbAcons.ano_solic
            AND tbItem.num_solic = tbAcons.num_solic
            AND tbItem.num_item  = tbAcons.num_item
         INNER JOIN of_logistica.tbsolic_entradas tbEntradas ON
                tbEntradas.cod_emp   = tbItem.cod_emp 
            AND tbEntradas.cod_fil   = tbItem.cod_fil
            AND tbEntradas.ano_solic = tbItem.ano_solic
            AND tbEntradas.num_solic = tbItem.num_solic
         LEFT JOIN tbintegraSAP_Contagem tbIntegraContagem ON
                  tbIntegraContagem.cod_emp   = tbAcons.cod_emp 
              AND tbIntegraContagem.cod_fil   = tbAcons.cod_fil
              AND tbIntegraContagem.ano_solic = tbAcons.ano_solic 
              AND tbIntegraContagem.num_solic = tbAcons.num_solic
              AND tbIntegraContagem.num_item  = tbAcons.num_item
              #AND tbIntegraContagem.num_lote = tbAcons.num_lote
              #AND tbIntegraContagem.sequencia_lote = tbAcons.sequencia_lote
         WHERE IFNULL(tbAcons.qtde_est2,0) > 0 
           AND tbIntegraContagem.cod_emp IS NULL
           AND tbItem.real_est > tbItem.qtde_est
         ORDER BY num_solic, num_item, num_lote, sequencia_lote;
      WHILE EXISTS (SELECT 1 FROM tbTMPItemContagem) DO
         SELECT CONCAT(num_solic, num_item), qtde_est, xSaldoaMaior
         INTO xChave, xQtdeNF, xSaldoaMaior
         FROM tbTMPItemContagem LIMIT 1;
         SET xQtdeRecebido = 0;
         
         WHILE EXISTS (SELECT 1 FROM tbTMPItemContagem WHERE CONCAT(num_solic, num_item) = xChave) DO
         
            SELECT qtde_est2, num_lote, sequencia_lote 
            INTO xqtde_est2, xnum_lote, xsequencia_lote 
            FROM tbTMPItemContagem WHERE xChave = CONCAT(num_solic, num_item) LIMIT 1;
            
            SET xQtdeRecebido = xQtdeRecebido + xqtde_est2;
            
            IF xQtdeRecebido > xQtdeNF  THEN
            
               SET xqtde_est2 = xQtdeRecebido - xQtdeNF;
            
               INSERT INTO tbintegraSAP_Contagem (
                    Id,
                    Reference,
                    CountingDate,
                    ItemCode, 
                    WarehouseCode, 
                    BinCode, 
                    BatchNumber_Code, 
                    BatchNumber_Quantity, 
                    SerialNumber_ManufactureCode, 
                    ContedQuantity,
                    TipoDocSLIN,
                    cod_emp,
                    cod_fil,	
                    ano_solic,
                    num_solic,
                    num_item,
                    num_lote,
                    sequencia_lote,
                    observacoes,   
                    dthr_inc) 
              (SELECT 0, CONCAT("Ajuste Entrada a maior SLIN - Doc ",NumDoc), NOW(), 
                  tbTMPItemContagem.cod_produto, tbTMPItemContagem.CodArmazemSAP, tbTMPItemContagem.binCode,
                  tbTMPItemContagem.num_lote_cli, xqtde_est2, NULL, 
                  xqtde_est2, 'E',
                  cod_emp, cod_fil, ano_solic, num_solic, num_item, num_lote, sequencia_lote, 'observ lote', NOW()
               FROM tbTMPItemContagem
               WHERE CONCAT(num_solic, num_item) = xChave
                 AND num_lote = xnum_lote
                 AND sequencia_lote = xsequencia_lote);
            END IF;
            
            DELETE FROM tbTMPItemContagem 
            WHERE xChave = CONCAT(num_solic, num_item) 
              AND num_lote = xnum_lote
              AND sequencia_lote = xsequencia_lote;
              
         END WHILE;
                 
      END WHILE;
      DROP TEMPORARY TABLE IF EXISTS tbTMPItemContagem;
      
      /*****************************************************************************************
      #Retorno Dataset 1 (Topo) / DataSet 2 (Itens) / DataSet 3 (Lotes)
      #Registros a para gerar contagem no SAP
      *****************************************************************************************/
      SELECT id, Reference, CountingDate, CONCAT(cod_emp,cod_fil, ano_solic, num_solic) AS NumDocSLIN, RESULTADO 
      FROM tbintegraSAP_Contagem
      WHERE id = 0
      GROUP BY NumDocSlin;
      SELECT CONCAT(cod_emp,cod_fil, ano_solic, num_solic) AS NumDocSLIN, num_item, ItemCode, WarehouseCode, BinCode, SUM(ContedQuantity) AS ContedQuantity
      FROM tbintegraSAP_Contagem
      WHERE id = 0
      GROUP BY NumDocSlin, num_item;
      SELECT CONCAT(cod_emp,cod_fil, ano_solic, num_solic) AS NumDocSLIN, num_item,  
            BatchNumber_Code, BatchNumber_Quantity, CONCAT('UA',TRIM(LEADING '0' FROM cod_emp),'/',TRIM(LEADING '0' FROM cod_fil),'-',
                                                    TRIM(LEADING '0' FROM num_lote),'.', sequencia_lote) NumLoteSlin
      FROM tbintegraSAP_Contagem
      WHERE id = 0;
      
   ELSEIF (oTipoSelecao = 1) THEN
      /*****************************************************************************************
      #Retorno Dataset 1 (Topo) / DataSet 2 (Itens) / DataSet 3 (Lotes)
      #Registros a para confirmar contagem no SAP
      *****************************************************************************************/
      SELECT id, Reference, CountingDate, CONCAT(cod_emp,cod_fil, ano_solic, num_solic) AS NumDocSLIN, RESULTADO
      FROM tbintegraSAP_Contagem
      WHERE id > 0 AND dthr_retorno_integracao IS NULL
      GROUP BY NumDocSlin;
      SELECT CONCAT(cod_emp,cod_fil, ano_solic, num_solic) AS NumDocSLIN, num_item, ItemCode, WarehouseCode, BinCode, SUM(ContedQuantity) AS ContedQuantity
      FROM tbintegraSAP_Contagem
      WHERE id > 0 AND dthr_retorno_integracao IS NULL
      GROUP BY NumDocSlin, num_item;
      SELECT CONCAT(cod_emp,cod_fil, ano_solic, num_solic) AS NumDocSLIN, num_item,  
            BatchNumber_Code, BatchNumber_Quantity, CONCAT('UA',TRIM(LEADING '0' FROM cod_emp),'/',TRIM(LEADING '0' FROM cod_fil),'-',
                                                    TRIM(LEADING '0' FROM num_lote),'.', sequencia_lote) NumLoteSlin
      FROM tbintegraSAP_Contagem
      WHERE id > 0 AND dthr_retorno_integracao IS NULL;
   END IF;
    
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      SELECT RESULTADO, MENSAGEM;
   ELSE    
      SET RESULTADO = 1;
      #SET MENSAGEM  = 'Processo Realizado com sucesso!';
   END IF;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_RetornoDevCompras.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_RetornoDevCompras`$$

CREATE PROCEDURE `PROC_INTEGRA_RetornoDevCompras`()
BLOCO1:BEGIN
   /*******************************************************************************************
   #@Author David Ruy <2025-12-17> Listar as Devoluções de Compras : GSM concluídas para integração de retorno ao SAP
   ********************************************************************************************/

   DECLARE xCodEmpWMS			      VARCHAR(03)	DEFAULT '001';
   DECLARE xCodFilWMS			      VARCHAR(03) DEFAULT '001';
   DECLARE xNumSolic 			      VARCHAR(10);
   DECLARE xAnoSolic 			      VARCHAR(04)	DEFAULT YEAR(CURRENT_DATE());
   DECLARE xDocEntry          INT;
   DECLARE xDocTipo           VARCHAR(10);   
   DECLARE xTipoOperSaida 		  VARCHAR(03) DEFAULT '002';
   DECLARE xCodUnidade			     VARCHAR(03) DEFAULT '001';
   DECLARE xCodArmazem			     VARCHAR(02) DEFAULT '01';
   DECLARE xStatusProcesso		  VARCHAR(02) DEFAULT '01';
   DECLARE xCodErro	          INT DEFAULT 0;
   DECLARE excecao 	          INT DEFAULT 0;
   DECLARE RESULTADO          INT DEFAULT 1;
   DECLARE MENSAGEM           VARCHAR(500);
   DECLARE xSTRGEM            TEXT;
   DECLARE xNumProcesso       VARCHAR(20);  
   DECLARE xflg_obriga_checkout_retornoPV TINYINT;
   DECLARE xflg_obriga_roteiriz_retornoPV TINYINT;
   DECLARE xOrdemLista        INT DEFAULT 0;  #0=Crescente / 1 = Decrescente
   DECLARE xQtdeRegistros     INT DEFAULT 0;
   DECLARE xflg_permite_PVParcial INT DEFAULT 0;
   DECLARE xutilizacao_saidas_retorno VARCHAR(200) DEFAULT NULL;
   DECLARE xflg_agrupa_transf TINYINT;
   DECLARE xemb_faturamento   VARCHAR(50);
   DECLARE xcampo_qtde_volumes TINYINT;
   DECLARE xParamDiasEntrega  TINYINT DEFAULT 90;

   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;


   #@Reviser David Ruy <2022-11-01>
   SELECT flg_permite_PVParcial, flg_obriga_checkout_retornoPV, flg_obriga_roteiriz_retornoPV, utilizacao_saidas_retorno,
          flg_agrupa_transf, IFNULL(emb_faturamento,"Volumes"), flg_campo_volumes
   INTO xflg_permite_PVParcial, xflg_obriga_checkout_retornoPV, xflg_obriga_roteiriz_retornoPV, xutilizacao_saidas_retorno,
        xflg_agrupa_transf, xemb_faturamento, xcampo_qtde_volumes
   FROM tbintegraSAP_parametros
   LIMIT 1;


   #Cria tabela temporária com as GSM recebidas que serão separadas
   DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_SAIDAS;

      
   DROP TEMPORARY TABLE IF EXISTS tbSaidas;
   CREATE TEMPORARY TABLE tbSaidas
     SELECT tbSaidas.* FROM of_logistica.tbsolic_saidas tbSaidas
     INNER JOIN tbintegraSAP_Doc ON 
                tbintegraSAP_Doc.chave_integracao = tbSaidas.chave_integracao
     WHERE tbSaidas.status_processo >= 8
       AND tbSaidas.dthr_cancelamento IS NULL
       AND tbSaidas.dthr_retorno_integracao IS NULL
       AND tbSaidas.dthr_confirm >= DATE_ADD(CURRENT_DATE(), INTERVAL -30 DAY)
       AND IF(xflg_obriga_checkout_retornoPV = 1, dthr_final_picking IS NOT NULL, TRUE)
       AND tbSaidas.chave_integracao IS NOT NULL
       AND tbintegraSAP_Doc.DocTipo IN ('DC')
     ORDER BY tbSaidas.dthr_confirm DESC
     LIMIT 100
     ;
   ALTER TABLE tbSaidas ADD PRIMARY KEY (chave_integracao);
   #select * from tbSaidas; leave Bloco1; 

   DROP TEMPORARY TABLE IF EXISTS tbSaidasVolItem;
   CREATE TEMPORARY TABLE tbSaidasVolItem
     SELECT tbSaidasVolItem.* FROM of_logistica.tbsolic_saidas_volume_item tbSaidasVolItem
     INNER JOIN tbSaidas ON 
                       tbSaidasVolItem.cod_emp   = tbSaidas.cod_emp 
                   AND tbSaidasVolItem.cod_fil   = tbSaidas.cod_fil
                   AND tbSaidasVolItem.ano_solic = tbSaidas.ano_solic
                   AND tbSaidasVolItem.num_solic = tbSaidas.num_solic;
                
   DROP TEMPORARY TABLE IF EXISTS tbSaidasItem;
   CREATE TEMPORARY TABLE tbSaidasItem
     SELECT tbSaidasItem.* FROM of_logistica.tbsolic_saidas_item tbSaidasItem
     INNER JOIN tbSaidas ON 
                       tbSaidasItem.cod_emp   = tbSaidas.cod_emp 
                   AND tbSaidasItem.cod_fil   = tbSaidas.cod_fil
                   AND tbSaidasItem.ano_solic = tbSaidas.ano_solic
                   AND tbSaidasItem.num_solic = tbSaidas.num_solic;
         
   CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_SAIDAS AS 
     SELECT DocEntry, DocTipo, DocNum, tbSaidas.num_nf, tbSaidas.data_nf, tbSaidas.data_solic, BPLId
           ,CONCAT(tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic) NumProcesso
           ,tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic
           ,tbSaidas.status_processo, tbSaidas.observ_solic 
           ,tbSaidas.flg_producao
           ,tbSaidas.dthr_final_picking 
           ,tbSaidas.dthr_confirm
           ,tbEstCli.flg_conferencia_volume_check_tp
           #
           
           #,(SELECT SUM(qtde_sep_est) FROM of_logistica.tbsolic_saidas_volume_item Item
           ,(SELECT SUM(qtde_sep_est) FROM tbSaidasVolItem Item
             WHERE Item.cod_emp   = tbSaidas.cod_emp
               AND Item.cod_fil   = tbSaidas.cod_fil
               AND Item.ano_solic = tbSaidas.ano_solic
               AND Item.num_solic = tbSaidas.num_solic) AS QtdeCheckout 
           #,(SELECT SUM(real_est2) FROM of_logistica.tbsolic_saidas_item Item
           ,(SELECT SUM(real_est2) FROM tbSaidasItem Item
             WHERE Item.cod_emp = tbSaidas.cod_emp
               AND Item.cod_fil = tbSaidas.cod_fil
               AND Item.ano_solic = tbSaidas.ano_solic
               AND Item.num_solic = tbSaidas.num_solic) AS QtdeSep
           #
     FROM tbintegraSAP_Doc
     #INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
     INNER JOIN tbSaidas ON
           tbSaidas.chave_integracao = tbintegraSAP_Doc.chave_integracao 
       #    tbSaidas.cod_emp   = tbintegraSAP_Doc.cod_emp
       #AND tbSaidas.cod_fil   = tbintegraSAP_Doc.cod_fil
       #AND tbSaidas.ano_solic = tbintegraSAP_Doc.ano_solic
       #AND tbSaidas.num_solic = tbintegraSAP_Doc.num_solic
       AND tbSaidas.status_processo >= 8
       AND tbSaidas.dthr_cancelamento IS NULL
       AND (tbSaidas.dthr_bloqueio_ini IS NULL OR (tbSaidas.dthr_bloqueio_ini IS NOT NULL AND tbSaidas.dthr_bloqueio_fin IS NOT NULL))              
     INNER JOIN of_logistica.tbwms_estoque_cli tbEstCli ON 
                tbEstCli.cod_emp      = tbSaidas.cod_emp
            AND tbEstCli.cod_fil      = tbSaidas.cod_fil
            AND tbEstCli.cnpj_cpf_cli = tbSaidas.cnpj_cpf_cli
            AND tbEstCli.cod_estoque  = tbSaidas.cod_estoque
     WHERE tbintegraSAP_Doc.TipoDocSLIN = 'S'
       AND tbintegraSAP_Doc.StatusDoc = 3
       # Só retorna depois de checkout (exceto para Ordem Produção)
       #AND IF(tbSaidas.flg_producao='S', TRUE, 
       #       tbSaidas.dthr_final_picking IS NOT NULL)
#       AND tbintegraSAP_Doc.IdPicking IS NOT NULL
       AND tbintegraSAP_Doc.DocTipo IN ('DC')
       AND tbintegraSAP_Doc.DocDate >= DATE_ADD(CURRENT_DATE(), INTERVAL -90 DAY)
       AND tbSaidas.dthr_confirm >= DATE_ADD(CURRENT_DATE(), INTERVAL -30 DAY)
       #@Reviser David Ruy <2023-09-15> Regra Cromo, Não retornar se não tiver preenchido Qtde e Peso Checkout manual
       AND IF(xcampo_qtde_volumes IN (2,3), IFNULL(tbSaidas.qtde_volume_checkout,0) > 0, TRUE)
       AND IF(xcampo_qtde_volumes IN (2), IFNULL(tbSaidas.peso_liq_checkout,0) > 0, TRUE)  
       AND IF(xcampo_qtde_volumes IN (2), IFNULL(tbSaidas.peso_brt_checkout,0) > 0, TRUE)
               #AND tbintegraSAP_Doc.DocNum = 159381
       #ORDER BY tbSaidas.dthr_confirm DESC
       LIMIT 100    #(utilizar LIMIT quando consulta estourar o tempo DO processamento)
       ; 
               
   DROP TEMPORARY TABLE IF EXISTS tbSaidas;
   DROP TEMPORARY TABLE IF EXISTS tbSaidasVolItem;
   DROP TEMPORARY TABLE IF EXISTS tbSaidasItem;
	  #select * from tbTMP_INTEGRA_RETORNO_SAIDAS;
	      


   #Update (como retornado) para PV´ com utilização diferente da parametrizada
   IF IFNULL(xutilizacao_saidas_retorno,'') <> '' THEN
      UPDATE tbintegraSAP_Doc
      INNER JOIN tbTMP_INTEGRA_RETORNO_SAIDAS ON
                 tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo  = tbintegraSAP_Doc.DocTipo
             AND tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry = tbintegraSAP_Doc.DocEntry
             AND tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum   = tbintegraSAP_Doc.DocNum
      SET StatusAnt = StatusDoc,
          StatusDoc = 6
      #where LOCATE(tbintegraSAP_Doc.MainUsage,xutilizacao_saidas_retorno) = 0);
      WHERE EXISTS (SELECT 1 FROM tbintegraSAP_DocItem
                    WHERE tbintegraSAP_DocItem.DocTipo  = tbintegraSAP_Doc.DocTipo
                      AND tbintegraSAP_DocItem.DocEntry = tbintegraSAP_Doc.DocEntry
                      AND tbintegraSAP_DocItem.DocNum   = tbintegraSAP_Doc.DocNum
                      AND LOCATE(IFNULL(tbintegraSAP_DocItem.Usage_,'XXX'),xutilizacao_saidas_retorno) = 0);
      DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS 
      WHERE EXISTS (SELECT 1 FROM tbintegraSAP_Doc
                    WHERE tbintegraSAP_Doc.DocTipo = tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo
                      AND tbintegraSAP_Doc.DocEntry  = tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry
                      AND tbintegraSAP_Doc.DocNum = tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum
                      AND StatusDoc = 6);
   END IF;
         

      























   
   
   #SELECT flg_obriga_checkout_retornoPV, flg_obriga_roteiriz_retornoPV
   #INTO xflg_obriga_checkout_retornoPV, xflg_obriga_roteiriz_retornoPV
   #FROM tbintegraSAP_parametros LIMIT 1;

        
   #Desconsidera GSM´s que não são de produção e que flg_conferencia_volume_check_tp = 1
   #e que não concluiu o checkout
   IF xflg_obriga_checkout_retornoPV = 1 THEN
      DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS
      #WHERE flg_producao = 'N'
      WHERE flg_producao = 'N' AND DocTipo NOT IN ('OP','TD-S','DC') 
        AND flg_conferencia_volume_check_tp = 1
        AND dthr_final_picking IS NULL;
      #select "Aqui", row_count();  LEAVE BLOCO1;
   END IF;
   #select * from tbTMP_INTEGRA_RETORNO_SAIDAS;
          
   #Ordem de Produção não depende de checkout
   UPDATE tbTMP_INTEGRA_RETORNO_SAIDAS
   SET QtdeCheckout = QtdeSep
   WHERE QtdeCheckout IS NULL
     AND DocTipo IN ('OP','TD-S','DC');
        
        
        
        
   #Desconsidera GSM´s com Checkout não Realizado quando flg_conferencia_volume_check_tp = 2
   IF xflg_obriga_checkout_retornoPV = 1 THEN
      DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS
      WHERE flg_producao = 'N'
        AND flg_conferencia_volume_check_tp = 2
        AND (IFNULL(QtdeSep,0) = 0 
        OR IFNULL(QtdeCheckout,0) < IFNULL(QtdeSep,0));
      #SELECT "Aqui2", ROW_COUNT();  LEAVE BLOCO1;
   END IF;


   #Não considerar retorno se o checkout não estiver concluido
   IF xcampo_qtde_volumes IN (2,3) THEN
      DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS
      WHERE flg_producao = 'N'
        AND (IFNULL(QtdeSep,0) = 0 
        OR IFNULL(QtdeCheckout,0) < IFNULL(QtdeSep,0));
      #SELECT "Aqui2", ROW_COUNT();  LEAVE BLOCO1;
   END IF;



   #SELECT xflg_permite_PVParcial, xflg_obriga_checkout_retornoPV, xflg_obriga_roteiriz_retornoPV, xutilizacao_saidas_retorno,
   #xflg_agrupa_transf, xemb_faturamento, xcampo_qtde_volumes;
   #SELECT * FROM tbTMP_INTEGRA_RETORNO_SAIDAS;
   #LEAVE BLOCO1;
           
                    
   #Desconsidera GSM´s Pedido em viagem Não Confirmada
   IF xflg_obriga_roteiriz_retornoPV = 1 THEN
      DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS
      WHERE flg_producao = 'N'
        AND flg_conferencia_volume_check_tp = 2
        AND EXISTS (SELECT NumProcesso, tbViagens.num_viagem
                    FROM of_logistica.tbsolic_saidas_item tbItem 
                    LEFT JOIN of_logistica.tbprog_entregas tbEntregas ON 
                              tbEntregas.cod_emp      = tbItem.cod_emp_pedido
                          AND tbEntregas.cod_fil      = tbItem.cod_fil_pedido
                          AND tbEntregas.cnpj_cpf_cli = tbItem.cnpj_cpf_cli
                          AND tbEntregas.num_nf_cli   = tbItem.num_ped_cli
                    LEFT JOIN of_logistica.tbviagens tbViagens ON 
                              tbViagens.cod_emp    = tbEntregas.cod_emp 
                          AND tbViagens.cod_fil    = tbEntregas.cod_fil
                          AND tbViagens.ano_viagem = tbEntregas.ano_viagem 
                          AND tbViagens.num_viagem = tbEntregas.num_viagem
                    WHERE tbItem.cod_emp   = tbTMP_INTEGRA_RETORNO_SAIDAS.cod_emp 
                      AND tbItem.cod_fil   = tbTMP_INTEGRA_RETORNO_SAIDAS.cod_fil
                      AND tbItem.ano_solic = tbTMP_INTEGRA_RETORNO_SAIDAS.ano_solic 
                      AND tbItem.num_solic = tbTMP_INTEGRA_RETORNO_SAIDAS.num_solic
                      AND tbViagens.data_conf IS NULL
                    GROUP BY NumProcesso);
      #SELECT "Aqui3", ROW_COUNT();  LEAVE BLOCO1;
   END IF;
         
   #@Reviser David Ruy <2022-04-06>
   #Não retornar Quando houver divergencia entre itens ou quantidades do SLIN X Integração
   IF xflg_permite_PVParcial = 0 THEN
      DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS
      WHERE EXISTS
            (SELECT SUM(tbItemSLIN.real_est2) TotalSlin, COUNT(tbItemSLIN.num_item) QtdeSlin, 
                    SUM(IFNULL(tbItem.OpenInvQty,tbItem.BaseQty)) TotalDoc, COUNT(tbItem.LineNum) QtdeDoc
             FROM tbintegraSAP_DocItem tbItem 
             LEFT JOIN of_logistica.tbsolic_saidas_item tbItemSLIN ON
                       tbItemSLIN.cod_emp   = tbItem.cod_emp 
                   AND tbItemSLIN.cod_fil   = tbItem.cod_fil
                   AND tbItemSLIN.ano_solic = tbItem.ano_solic
                   AND tbItemSLIN.num_solic = tbItem.num_solic
                   AND tbItemSLIN.num_item  = tbItem.num_item
             WHERE tbItem.cod_emp   = tbTMP_INTEGRA_RETORNO_SAIDAS.cod_emp 
               AND tbItem.cod_fil   = tbTMP_INTEGRA_RETORNO_SAIDAS.cod_fil
               AND tbItem.ano_solic = tbTMP_INTEGRA_RETORNO_SAIDAS.ano_solic 
               AND tbItem.num_solic = tbTMP_INTEGRA_RETORNO_SAIDAS.num_solic
               AND tbItem.StatusItem <> 9
             HAVING TotalSlin <> TotalDoc OR QtdeSlin <> QtdeDoc);
   END IF;
         
         
      
      
   #Ordena Ascendente ou Descendente
   DROP TEMPORARY TABLE IF EXISTS tbTMPX;
   IF xOrdemLista = 0 THEN
      CREATE TEMPORARY TABLE tbTMPX AS
         SELECT * FROM tbTMP_INTEGRA_RETORNO_SAIDAS ORDER BY dthr_confirm;
   ELSE
      CREATE TEMPORARY TABLE tbTMPX AS
         SELECT * FROM tbTMP_INTEGRA_RETORNO_SAIDAS ORDER BY dthr_confirm DESC;
   END IF;
                 
   #Força ficar apenas 10 Registros;
   DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS;
   IF xQtdeRegistros = 0 THEN
      INSERT INTO tbTMP_INTEGRA_RETORNO_SAIDAS SELECT * FROM tbTMPX;
   ELSE
      INSERT INTO tbTMP_INTEGRA_RETORNO_SAIDAS SELECT * FROM tbTMPX LIMIT xQtdeRegistros;
   END IF;
   DROP TEMPORARY TABLE IF EXISTS tbTMPX;
      
   

   
   #Não Gerar retorno de Materiais de Uso/consumo
   DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS
   WHERE (SELECT COUNT(*) FROM tbintegraSAP_DocItem
                 WHERE tbintegraSAP_DocItem.DocTipo = tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo
                   AND tbintegraSAP_DocItem.DocEntry = tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry
                   AND tbintegraSAP_DocItem.OONE_USO_CONS = 1);

   
   
   
   


   
   #Alimenta variavel xSTRGEM com a lista das GSM´s selecionadas
   SET xSTRGEM = '';  
   WHILE EXISTS (SELECT 1 FROM tbTMP_INTEGRA_RETORNO_SAIDAS) DO
      SELECT NumProcesso, cod_emp, cod_fil, ano_solic, num_solic, DocEntry, Doctipo
      INTO xNumProcesso, xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xDocEntry, xDoctipo
      FROM tbTMP_INTEGRA_RETORNO_SAIDAS LIMIT 1;         
      
      SET xSTRGEM = CONCAT(xSTRGEM, CONCAT(xCodEmpWMS, "|", xCodFilWMS, "|", xAnoSolic, "|", xNumSolic, "|", xDocEntry, "|"), xDocTipo, "|");
      DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS WHERE NumProcesso = xNumProcesso;
   END WHILE;

   #Cria tabela temporária auxiliar para inner join com a tbsolic_entradas para gerar seleção das informações
   #da GEM informada no parametro
   CALL PROC_SYS_GerarTabelaComTexto(xSTRGEM,'|',6);        
   
   
   #select * from tTabelaComTexto; #2024-11-14
   #       LEAVE bloco1;   
   /*****************************************************************************/
   #Tabelas Temporarias para Volumes
   /*****************************************************************************/
   SELECT NOW() INTO @Time0;
    
   #Nova tabela Temporária Volumes
   DROP TEMPORARY TABLE IF EXISTS tbTMPVolumes;
   CREATE TEMPORARY TABLE tbTMPVolumes (
       cod_emp VARCHAR(03), cod_fil VARCHAR(03), ano_solic VARCHAR(04), 
       num_solic VARCHAR(10), num_item VARCHAR(06), id_volume_saida INT,
       qtde_sep_est DECIMAL(18,6),
       INDEX (id_volume_saida)
   );
   #Tabela Gêmea para utilização em 2 campos distintos
   DROP TEMPORARY TABLE IF EXISTS tbTMPVolumes2;
   CREATE TEMPORARY TABLE tbTMPVolumes2 (
       cod_emp VARCHAR(03), cod_fil VARCHAR(03), ano_solic VARCHAR(04), 
       num_solic VARCHAR(10), num_item VARCHAR(06), id_volume_saida INT,
       qtde_sep_est DECIMAL(18,6),
       INDEX (id_volume_saida)
   );


   INSERT INTO tbTMPVolumes       
    (   
       SELECT tbsolic_saidas_volume_item.cod_emp, tbsolic_saidas_volume_item.cod_fil, 
              tbsolic_saidas_volume_item.ano_solic, tbsolic_saidas_volume_item.num_solic, 
              tbsolic_saidas_volume_item.num_item, tbsolic_saidas_volume_item.id_volume_saida,
              tbsolic_saidas_volume_item.qtde_sep_est
       FROM of_logistica.tbsolic_saidas_volume_item
       INNER JOIN tTabelaComTexto ON
             tTabelaComTexto.Coluna01 = tbsolic_saidas_volume_item.cod_emp
             AND tTabelaComTexto.Coluna02 = tbsolic_saidas_volume_item.cod_fil
             AND tTabelaComTexto.Coluna03 = tbsolic_saidas_volume_item.ano_solic
             AND tTabelaComTexto.Coluna04 = tbsolic_saidas_volume_item.num_solic
       #WHERE tbsolic_saidas_volume.id_volume_saida = tbsolic_saidas_volume_item.id_volume_saida;
    );
   INSERT INTO tbTMPVolumes2 (SELECT * FROM tbTMPVolumes);
   DROP TEMPORARY TABLE IF EXISTS tbTMPPesosInsumos;
   CREATE TEMPORARY TABLE tbTMPPesosInsumos (
      SELECT tbTMPVolumes.cod_emp, tbTMPVolumes.cod_fil, 
             tbTMPVolumes.ano_solic, tbTMPVolumes.num_solic, 
             SUM(IFNULL(peso_bruto_insumo,0)) PesoInsumos
      FROM of_logistica.tbsolic_saidas_volume
      INNER JOIN tbTMPVolumes ON tbsolic_saidas_volume.id_volume_saida = tbTMPVolumes.id_volume_saida 
      GROUP BY tbTMPVolumes.cod_emp, tbTMPVolumes.cod_fil, 
               tbTMPVolumes.ano_solic, tbTMPVolumes.num_solic
   );

   SELECT NOW() INTO @Time1;
   /*******************************************************************
   # Selecionar as informações da GSM
   *******************************************************************/
   # INFORMAÇÕES DO TOPO DA GSM
   SELECT tTabelaComTexto.Coluna05 AS DocEntry, tTabelaComTexto.Coluna06 AS Doctipo
         ,tbintegraSAP_Doc.IdPicking, tbintegraSAP_Doc.IdPickingAnt
         ,tbintegraSAP_Doc.DocNum, tbintegraSAP_Doc.BPLId
         ,topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic
         ,topo.data_solic, topo.data_saida, topo.dthr_acons, topo.num_nf AS num_pedido
         ,CONCAT(tbViagens.cod_emp,'/',tbViagens.cod_fil,'-',tbViagens.ano_viagem,'.',tbViagens.num_viagem) AS NumViagem
         ,tbRotas.descr_rota RotaCliente
         ,tbDest.hora1_entrega Janela01
         ,tbDest.hora2_entrega Janela02
         ,tbDest.hora3_entrega Janela03
         ,tbDest.hora4_entrega Janela04
         ,CONCAT(tbViagens.cod_emp,'/',tbViagens.cod_fil,'-',tbViagens.ano_viagem,'.',tbViagens.num_viagem,'=>',tbRotas.descr_rota) RefViagem
         ,IF(of_logistica.fnStatusBaixaEntrega(tbEntregas.status_baixa)='Em Aberto',
                  IF(topo.status_processo>=9,of_logistica.fnStatusBaixaEntrega(tbEntregas.status_baixa),
                                             of_logistica.fnStatusSaidaWms(topo.status_processo)),
                  of_logistica.fnStatusBaixaEntrega(tbEntregas.status_baixa)) StatusEntrega
         ,IFNULL(tbViagens.cnpj_transportador,topo.cnpj_cpf_transp) CodTranspTMS
         ,tbintegraSAP_Doc.CnpjTransp CodTranspOriginal
         ,topo.observ_solic, topo.observ_conf01, topo.status_processo
         ,of_logistica.fnStatusSaidaWms(topo.status_processo) status_processoAux
         #Liberação Inicio Processo de Separação, Picking
         ,topo.dthr_armazem, topo.dthr_armazem_picking, topo.dthr_confer, topo.dthr_confirm
         #Inicio Processo de Separação, Picking
         ,topo.dthr_inicio_geral, topo.dthr_inicio_picking, topo.dthr_inicio_carregamento
         ,xcampo_qtde_volumes
   #Totais 1 (OK)
   ###
         ,(SELECT SUM(tbItem.real_vol) FROM of_logistica.tbsolic_saidas_item tbItem
           WHERE tbItem.cod_emp  = topo.cod_emp
             AND tbItem.cod_fil   = topo.cod_fil
             AND tbItem.ano_solic = topo.ano_solic
             AND tbItem.num_solic = topo.num_solic) QtdeVolumes
         ,(SELECT COUNT(DISTINCT tbVolumesTopo.id_volume_saida) 
            FROM of_logistica.tbsolic_saidas_volume tbVolumesTopo
            INNER JOIN of_logistica.tbsolic_saidas_volume_item tbVolumes ON
                   tbVolumesTopo.id_volume_saida = tbVolumes.id_volume_saida
            WHERE tbVolumes.cod_emp  = topo.cod_emp
             AND tbVolumes.cod_fil   = topo.cod_fil
             AND tbVolumes.ano_solic = topo.ano_solic
             AND tbVolumes.num_solic = topo.num_solic
             #AND tbVolumes.num_item  = ite.num_item
           ) QtdeVolumesPedido
   ###
         ,topo.qtde_volume_checkout QtdeVolManual
         ,topo.peso_liq_checkout PesoLiqManual
         ,topo.peso_brt_checkout PesoBrtManual
         ,topo.chave_integracao
   #Totais 2 (OK)
   ###
         ,(SELECT SUM(IFNULL(tbAcons.qtde_peso2,0)) FROM of_logistica.tbsolic_saidas_acons tbAcons
           WHERE tbAcons.cod_emp   = topo.cod_emp
             AND tbAcons.cod_fil   = topo.cod_fil
             AND tbAcons.ano_solic = topo.ano_solic
             AND tbAcons.num_solic = topo.num_solic
          ) TotalPesoLiq
         ,(SELECT SUM(IFNULL(tbAcons.qtde_pbrt2,0)) FROM of_logistica.tbsolic_saidas_acons tbAcons
           WHERE tbAcons.cod_emp   = topo.cod_emp
             AND tbAcons.cod_fil   = topo.cod_fil
             AND tbAcons.ano_solic = topo.ano_solic
             AND tbAcons.num_solic = topo.num_solic
          ) TotalPesoBruto
   ###
          ,tbintegraSAP_Doc.WhareHouse
          ,tbintegraSAP_Doc.WhareHouseTransf
          ,tbintegraSAP_Doc.CardCode
          ,tbintegraSAP_Doc.CardName
          ,CONCAT(tbintegraSAP_Doc.StreetS," - ",tbintegraSAP_Doc.CityS,"-",tbintegraSAP_Doc.StateS,"-",tbintegraSAP_Doc.CountryS,
                  " CEP:",tbintegraSAP_Doc.ZipCodeS) AS Address 
   #Totais 3 (OK)
   ###
          ,IF(xemb_faturamento <> "", xemb_faturamento,
              fnContarEmbalagens(
                 (SELECT GROUP_CONCAT(tbsolic_saidas_volume.id_volume_saida,IFNULL(sigla_insumo,"vol")) Embalagens
                  FROM of_logistica.tbsolic_saidas_volume_item 
                  INNER JOIN of_logistica.tbsolic_saidas_volume ON 
                      tbsolic_saidas_volume.id_volume_saida = tbsolic_saidas_volume_item.id_volume_saida
                  LEFT JOIN of_logistica.tbwms_insumo ON 
                       tbwms_insumo.id_insumo = tbsolic_saidas_volume.id_insumo
                  WHERE topo.cod_emp = tbsolic_saidas_volume_item.cod_emp
                    AND topo.cod_fil = tbsolic_saidas_volume_item.cod_fil
                    AND topo.ano_solic = tbsolic_saidas_volume_item.ano_solic
                    AND topo.num_solic = tbsolic_saidas_volume_item.num_solic) ) 
            ) Embalagens
   ###
   #Totais 4 (Tabela temporária OK)
   ###
          ,(SELECT PesoInsumos
            FROM tbTMPPesosInsumos
            WHERE tbTMPPesosInsumos.cod_emp = topo.cod_emp 
              AND tbTMPPesosInsumos.cod_fil = topo.cod_fil
              AND tbTMPPesosInsumos.ano_solic = topo.ano_solic
              AND tbTMPPesosInsumos.num_solic = topo.num_solic
            ) PesoInsumos
   ###
         ,RESULTADO, MENSAGEM
   FROM of_logistica.tbsolic_saidas topo
   LEFT JOIN of_logistica.tbprog_entregas tbEntregas ON
             tbEntregas.chave_integracao = topo.chave_integracao
   LEFT JOIN of_logistica.tbviagens tbViagens ON 
             tbViagens.cod_emp    = tbEntregas.cod_emp 
         AND tbViagens.cod_fil    = tbEntregas.cod_fil
         AND tbViagens.ano_viagem = tbEntregas.ano_viagem
         AND tbViagens.num_viagem = tbEntregas.num_viagem
   LEFT JOIN of_logistica.tbdestinatarios tbDest ON 
             tbDest.id_destinatario = tbEntregas.id_destinatario
   LEFT JOIN of_logistica.tbrotas tbRotas ON
             tbRotas.cod_emp  = tbDest.emp_rota
         AND tbRotas.cod_fil  = tbDest.fil_rota
         AND tbRotas.cod_rota = tbDest.cod_rota                
   INNER JOIN tTabelaComTexto ON
         tTabelaComTexto.Coluna01 = topo.cod_emp
         AND tTabelaComTexto.Coluna02 = topo.cod_fil
         AND tTabelaComTexto.Coluna03 = topo.ano_solic
         AND tTabelaComTexto.Coluna04 = topo.num_solic
   INNER JOIN tbintegraSAP_Doc ON 
             tbintegraSAP_Doc.cod_emp = topo.cod_emp
         AND tbintegraSAP_Doc.cod_fil = topo.cod_fil
         AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
         AND tbintegraSAP_Doc.num_solic = topo.num_solic
         AND tbintegraSAP_Doc.TipoDocSLIN = 'S';
      
   #select "Teste1"; leave bloco1;
   SELECT NOW() INTO @Time2;
         
   # INFORMAÇÕES DOS ITENS DA GSM
   SET @LinePk = -1;
   SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, tbintegraSAP_DocItem.LineNum, 
          tbintegraSAP_DocItem.LineNumPk,
          xflg_permite_PVParcial, tbintegraSAP_DocItem.Usage_,
          tbintegraSAP_DocItem.BaseQty, tbintegraSAP_DocItem.Price, 
          tbintegraSAP_DocItem.unitMsr,
          tbintegraSAP_DocItem.OpenInvQty,
          tbintegraSAP_DocItem.OpenInvQty/tbintegraSAP_DocItem.BaseQty AS B1_FatorEmbalagem,
          tbintegraSAP_DocItem.ManBtchNum, tbintegraSAP_DocItem.ManSerNum,
          #IF(IFNULL(tbintegraSAP_DocItem.NumInSale,1)=0,1,tbintegraSAP_DocItem.NumInSale) AS FatorConvSAP,
          #tbintegraSAP_DocItem.buyUnitMsr, tbintegraSAP_DocItem.salUnitMsr, tbintegraSAP_DocItem.invntryUom,
          #IF(IFNULL(prod.fator_conv_vendas,0)=0,1,prod.fator_conv_vendas) AS FatorConvSAP,
          IF(IFNULL(tbintegraSAP_DocItem.OpenInvQty,0) > 0, 
            tbintegraSAP_DocItem.OpenInvQty / tbintegraSAP_DocItem.BaseQty,
               IF(IFNULL(tbintegraSAP_DocItem.NumInSale,1)=0,1,tbintegraSAP_DocItem.NumInSale))  AS FatorConvSAP,
          #prod.emb_compras buyUnitMsr, prod.emb_vendas salUnitMsr, prod.emb_estoque_cli invntryUom,
          tbintegraSAP_DocItem.buyUnitMsr, tbintegraSAP_DocItem.salUnitMsr, tbintegraSAP_DocItem.invntryUom,
          ite.num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
          ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
          #
          ite.local_geral, ite.local_picking,
          IFNULL(ite.qtde_est,0) qtde_est, ite.qtde_vol, ite.qtde_frac, ite.pliq_item,		#Qtde Pedido
          ite.real_est, ite.real_vol, ite.real_frac, ite.real_peso,		#Qtde Aconselhada
          ite.real_est2, ite.real_vol2, ite.real_frac2, ite.real_peso2,	#Qtde Separação
          ite.real_est3, ite.real_vol3, ite.real_frac3, ite.real_peso3,	#Qtde Conferencia / Picking
          ite.real_est4, ite.real_vol4, ite.real_frac4, ite.real_peso4,	#Qtde Carregamento
          ite.real_est5, ite.real_vol5, ite.real_frac5, ite.real_peso5,	#Qtde check-carregamento
          # Alterado (2024-11-18) subSelect, agora utilizando tbTMPVolumes
          (SELECT GROUP_CONCAT(tbTMPVolumes.id_volume_saida)
           FROM tbTMPVolumes 
           WHERE tbTMPVolumes.cod_emp   = ite.cod_emp
             AND tbTMPVolumes.cod_fil   = ite.cod_fil
             AND tbTMPVolumes.ano_solic = ite.ano_solic
             AND tbTMPVolumes.num_solic = ite.num_solic
             AND tbTMPVolumes.num_item  = ite.num_item) IdVolumesCheckout,
          # Alterado (2024-11-18)subSelect, agora utilizando tbTMPVolumes2
          (SELECT SUM(tbTMPVolumes2.qtde_sep_est)
           FROM tbTMPVolumes2 
           WHERE tbTMPVolumes2.cod_emp   = ite.cod_emp
             AND tbTMPVolumes2.cod_fil   = ite.cod_fil
             AND tbTMPVolumes2.ano_solic = ite.ano_solic
             AND tbTMPVolumes2.num_solic = ite.num_solic
             AND tbTMPVolumes2.num_item  = ite.num_item) QtdeVolCheckout,
          #			
          ite.dthr_aconselhamento, ite.dthr_retorno_wms,
          ite.dthr_inicio_baixa_geral, ite.dthr_inicio_picking_carga, ite.dthr_inicio_carregamento,
          ite.dthr_final_baixa_geral, ite.dthr_final_picking_carga, ite.dthr_final_carregamento				
          ,topo.chave_integracao
          ,prod.flg_obriga_lote_fornecedor
          ,IF(tbintegraSAP_Doc.DocTipo='TD-S' AND xflg_agrupa_transf=1,1,0) xflg_agrupa_transf
          ,tbintegraSAP_DocItem.BaseQty / (SELECT SUM(tbDocItem.BaseQty) FROM tbintegraSAP_DocItem tbDocItem
                WHERE tbintegraSAP_DocItem.DocTipo = tbDocItem.DocTipo
                  AND tbintegraSAP_DocItem.DocEntry = tbDocItem.DocEntry
                  AND tbintegraSAP_DocItem.ItemCode = tbDocItem.ItemCode
                ) AS FatorAgrup
          ,RESULTADO, MENSAGEM
   FROM of_logistica.tbsolic_saidas topo
   INNER JOIN tbintegraSAP_Doc ON 
             tbintegraSAP_Doc.cod_emp = topo.cod_emp
         AND tbintegraSAP_Doc.cod_fil = topo.cod_fil
         AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
         AND tbintegraSAP_Doc.num_solic = topo.num_solic
         AND tbintegraSAP_Doc.TipoDocSLIN = "S"
   INNER JOIN of_logistica.tbsolic_saidas_item ite ON
         ite.cod_emp = topo.cod_emp
         AND ite.cod_fil = topo.cod_fil
         AND ite.ano_solic = topo.ano_solic
         AND ite.num_solic = topo.num_solic
   INNER JOIN of_logistica.tbprodutos prod ON
         prod.cnpj_cpf = ite.cnpj_cpf_dep
         AND prod.cod_produto = ite.cod_produto
   INNER JOIN tbintegraSAP_DocItem ON 
             tbintegraSAP_DocItem.cod_emp = ite.cod_emp
         AND tbintegraSAP_DocItem.cod_fil = ite.cod_fil
         AND tbintegraSAP_DocItem.ano_solic = ite.ano_solic
         AND tbintegraSAP_DocItem.num_solic = ite.num_solic
         AND tbintegraSAP_DocItem.num_item = ite.num_item
         AND tbintegraSAP_DocItem.DocTipo  = tbintegraSAP_Doc.DocTipo
   INNER JOIN tTabelaComTexto ON
         tTabelaComTexto.Coluna01 = topo.cod_emp
         AND tTabelaComTexto.Coluna02 = topo.cod_fil
         AND tTabelaComTexto.Coluna03 = topo.ano_solic
         AND tTabelaComTexto.Coluna04 = topo.num_solic
   #WHERE TRUE; #ite.qtde_nf > 0;
   WHERE IFNULL(tbintegraSAP_DocItem.StatusItem,0) <= 2;
   #select "Teste2"; leave bloco1;
   SELECT NOW() INTO @Time3;
   DROP TEMPORARY TABLE IF EXISTS tbTMPVolumes;
   DROP TEMPORARY TABLE IF EXISTS tbTMPVolumes2;
   DROP TEMPORARY TABLE IF EXISTS tbTMPPesosInsumos;
   



   #Seleção das UA´/Lotes
   SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, tbintegraSAP_DocItem.LineNum, tbintegraSAP_DocItem.LineNumPk,
      ite.num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
      ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
      #
      CONCAT(acons.num_lote,acons.sequencia_lote) AS NumUA,
      tbwms_estoque.num_lote_cli,
      SUM(acons.qtde_est) qtde_est, SUM(acons.qtde_vol) qtde_vol, SUM(acons.qtde_frac) qtde_frac, SUM(acons.qtde_peso) qtde_peso,		#Qtde Aconselhada
      SUM(acons.qtde_est2) qtde_est2, SUM(acons.qtde_vol2) qtde_vol2, SUM(acons.qtde_frac2) qtde_frac2, SUM(acons.qtde_peso2) qtde_peso2,	#Qtde Separada
      SUM(acons.qtde_est3) qtde_est3, SUM(acons.qtde_vol3) qtde_vol3, SUM(acons.qtde_frac3) qtde_frac3, SUM(acons.qtde_peso3) qtde_frac3,	#(*) Qtde Conferencia/Picking Carga
      #		
      acons.dthr_conf, acons.dthr_conf_picking, acons.dthr_carregamento
      ,topo.chave_integracao
      ,"NÃO" LoteForcado
      ,RESULTADO, MENSAGEM
   FROM of_logistica.tbsolic_saidas topo
   LEFT JOIN of_logistica.tbsolic_saidas_item ite ON
         ite.cod_emp = topo.cod_emp
         AND ite.cod_fil = topo.cod_fil
         AND ite.ano_solic = topo.ano_solic
         AND ite.num_solic = topo.num_solic	
   INNER JOIN tbintegraSAP_Doc ON 
             tbintegraSAP_Doc.cod_emp = topo.cod_emp
         AND tbintegraSAP_Doc.cod_fil = topo.cod_fil
         AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
         AND tbintegraSAP_Doc.num_solic = topo.num_solic
         AND tbintegraSAP_Doc.TipoDocSLIN = 'S'      
   INNER JOIN tbintegraSAP_DocItem ON 
             tbintegraSAP_DocItem.cod_emp = ite.cod_emp
         AND tbintegraSAP_DocItem.cod_fil = ite.cod_fil
         AND tbintegraSAP_DocItem.ano_solic = ite.ano_solic
         AND tbintegraSAP_DocItem.num_solic = ite.num_solic
         AND tbintegraSAP_DocItem.num_item = ite.num_item
         AND tbintegraSAP_DocItem.DocTipo  = tbintegraSAP_Doc.DocTipo
   LEFT JOIN of_logistica.tbprodutos prod ON
         prod.cnpj_cpf = ite.cnpj_cpf_dep
         AND prod.cod_produto = ite.cod_produto
   LEFT JOIN of_logistica.tbsolic_saidas_acons acons ON
         acons.cod_emp = ite.cod_emp
         AND acons.cod_fil = ite.cod_fil
         AND acons.ano_solic = ite.ano_solic
         AND acons.num_solic = ite.num_solic			
         AND acons.num_item  = ite.num_item
   LEFT JOIN of_logistica.tbwms_estoque ON  
         tbwms_estoque.cod_emp = acons.cod_emp
         AND tbwms_estoque.cod_fil = acons.cod_fil
         AND tbwms_estoque.num_lote = acons.num_lote
         AND tbwms_estoque.sequencia_lote = acons.sequencia_lote
   INNER JOIN tTabelaComTexto ON
         tTabelaComTexto.Coluna01 = topo.cod_emp
         AND tTabelaComTexto.Coluna02 = topo.cod_fil
         AND tTabelaComTexto.Coluna03 = topo.ano_solic
         AND tTabelaComTexto.Coluna04 = topo.num_solic
   WHERE acons.qtde_est2 > 0
     AND IFNULL(tbintegraSAP_DocItem.StatusItem,0) <= 2
   GROUP BY ite.cod_emp, ite.cod_fil, ite.ano_solic, ite.num_solic, 
            IF(tbintegraSAP_Doc.DocTipo='TD-S' AND xflg_agrupa_transf=1,
               tbintegraSAP_DocItem.LineNum,tbintegraSAP_DocItem.num_item), num_lote_cli;
   #select "Teste3"; leave bloco1;
   SELECT NOW() INTO @Time4;




   
   SELECT @Time0, @Time1, @Time2, @Time3, @Time4,
          TIMEDIFF(@Time1,@Time0) "CriarTMP",
          TIMEDIFF(@Time2,@Time1) "Topo",
          TIMEDIFF(@Time3,@Time2) "Item",
          TIMEDIFF(@Time4,@Time3) "Acons";
       
   DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_SAIDAS;
   DROP TEMPORARY TABLE IF EXISTS tTabelaComTexto;
    
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      SELECT RESULTADO, MENSAGEM;
   ELSE    
      SET RESULTADO = 1;
      #SET MENSAGEM  = 'Processo Realizado com sucesso!';
   END IF;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_RetornoEditPV.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_RetornoEditPV`$$

CREATE PROCEDURE `PROC_INTEGRA_RetornoEditPV`(
   # Parametros de Retorno
   #OUT RESULTADO             	INT,
   #OUT MENSAGEM              	VARCHAR(500)
)
BLOCO1:BEGIN
   /***************************************************************************
   #@Reviser David Ruy <2021/07/11>
   #Busca informações de GSM´ que liberou alteração de PV no SAP
   #EditPV => 1:Não / 2:SIM
   ****************************************************************************/
   DECLARE RESULTADO          INT;
   DECLARE MENSAGEM           VARCHAR(500);
   DECLARE excecao 	          INT DEFAULT 0;
      
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    
    GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
  
    ROLLBACK;
    SET RESULTADO = 0;
    SET MENSAGEM  = MENSAGEM;
  END;
   
   
   SELECT tbintegraSAP_Doc.DocTipo, tbintegraSAP_Doc.DocEntry, tbintegraSAP_Doc.DocNum, 
          "2" EditPV, 1 AS resultado, tbSaidas.chave_integracao AS mensagem
   FROM tbintegraSAP_Doc
   INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
         tbSaidas.cod_emp   = tbintegraSAP_Doc.cod_emp
     AND tbSaidas.cod_fil   = tbintegraSAP_Doc.cod_fil
     AND tbSaidas.ano_solic = tbintegraSAP_Doc.ano_solic
     AND tbSaidas.num_solic = tbintegraSAP_Doc.num_solic
     AND tbSaidas.status_processo >= 4
     AND tbintegraSAP_Doc.StatusDoc = 3
   INNER JOIN of_logistica.tbwms_tipo_oper tbOperacoesWMS ON 
         tbOperacoesWMS.cod_oper_wms = tbSaidas.flg_tipo_oper
   WHERE tbintegraSAP_Doc.TipoDocSLIN = 'S'
     AND tbintegraSAP_Doc.DocTipo     = 'PV'
     AND tbSaidas.dthr_bloqueio_ini IS NOT NULL
     AND tbSaidas.dthr_bloqueio_fin IS NULL
     AND tbSaidas.dthr_retorno_integracao IS NULL;
   
    
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      SELECT RESULTADO, MENSAGEM;
   ELSE    
      SET RESULTADO = 1;
      #SET MENSAGEM  = 'Processo Realizado com sucesso!';
   END IF;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_RetornoEncerrarOP.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_RetornoEncerrarOP`$$

CREATE PROCEDURE `PROC_INTEGRA_RetornoEncerrarOP`(
   IN oCodUsuario				VARCHAR(10),
   IN oNumero_OP     VARCHAR(10)
   # Parametros de Retorno
#   OUT RESULTADO             	INT,
#   OUT MENSAGEM              	VARCHAR(500)
)
BLOCO1:BEGIN
   /***************************************************************************
   #@Author David Ruy <2026/03/09>
   # Gera lista de Documentos para Retorno (Avalia se não existe MP E PA em aberto)
   #@Reviser David Ruy <2026/06/18>
   # Avalia se gerou Documentos de Saída MP e Entrada PA (DocEntryRef IS NOT NULL)
   ****************************************************************************/
   DECLARE xDtHrFech        VARCHAR(20);
   DECLARE xCodErro	        INT DEFAULT 0;
   DECLARE excecao 	        INT DEFAULT 0;
   DECLARE RESULTADO        INT DEFAULT 1;
   DECLARE MENSAGEM         VARCHAR(500);
   
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       SELECT RESULTADO, MENSAGEM;
       ROLLBACK;
   END;
   
   
   IF (oNumero_OP IS NULL OR oNumero_OP = 0) THEN
      #Cria tabela temporária com as GEM/GSM´s de OP´s que estão liberadas para encerramento de OP
      DROP TEMPORARY TABLE IF EXISTS tbTMP_OPs;
         
      CREATE TEMPORARY TABLE tbTMP_OPs
      SELECT DocEntry, DocNum FROM 
      (
          (SELECT DocEntry, DocNum FROM  tbintegraSAP_Doc tbIntegra_PA
          INNER JOIN of_logistica.tbsolic_entradas tbEntradas ON 
                     tbEntradas.chave_integracao = tbIntegra_PA.chave_integracao
          WHERE tbIntegra_PA.DocTipo LIKE ('PA%')
            AND tbEntradas.status_processo >= 8
            AND tbIntegra_PA.StatusDoc = 6
            AND tbEntradas.dthr_retorno_integracao IS NOT NULL 
            AND tbIntegra_PA.DocEntryRef IS NOT NULL     
            AND tbIntegra_PA.StatusAux_Cliente IS NULL)
      UNION
         (SELECT DocEntry, DocNum FROM tbintegraSAP_Doc tbIntegra_OP
          INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
                     tbSaidas.chave_integracao = tbIntegra_OP.chave_integracao
          WHERE tbIntegra_OP.DocTipo = 'OP'
            AND tbSaidas.status_processo >= 8
            AND tbIntegra_OP.StatusDoc = 6
            AND tbSaidas.dthr_retorno_integracao IS NOT NULL   
            AND tbIntegra_OP.DocEntryRef IS NOT NULL     
            AND tbIntegra_OP.StatusAux_Cliente IS NULL)
         ) Tabelas;
      
      
      #Apaga os Documentos que ainda tem GEM em andamento
      DELETE FROM tbTMP_OPs
      WHERE EXISTS (
            SELECT 1 FROM tbintegraSAP_Doc 
            WHERE tbintegraSAP_Doc.DocTipo LIKE 'PA%'
             AND tbintegraSAP_Doc.DocEntry = tbTMP_OPs.DocEntry       
             AND tbintegraSAP_Doc.StatusDoc <= 3);
      #Apaga os Documentos que ainda tem GSM em andamento
      DELETE FROM tbTMP_OPs
      WHERE EXISTS (
            SELECT 1 FROM tbintegraSAP_Doc 
            WHERE tbintegraSAP_Doc.DocTipo = 'OP'
             AND tbintegraSAP_Doc.DocEntry = tbTMP_OPs.DocEntry       
             AND tbintegraSAP_Doc.StatusDoc <= 3);
      
      SET RESULTADO = 1;
      SET MENSAGEM  = 'Listagem realizada com sucesso!';
      
      
      SELECT tbTMP_OPs.*, RESULTADO, MENSAGEM FROM tbTMP_OPs;
      DROP TEMPORARY TABLE IF EXISTS tbTMP_OPs;
 
   ELSE
   
      SET xDtHrFech = NOW();
   
      UPDATE tbintegraSAP_Doc
      SET StatusAux_Cliente = CONCAT("Fech OP =>",xDtHrFech)
      WHERE DocTipo LIKE 'PA%' AND DocEntry = oNumero_OP;
      UPDATE tbintegraSAP_Doc
      SET StatusAux_Cliente = CONCAT("Fech OP =>",xDtHrFech)
      WHERE DocTipo = 'OP' AND DocEntry = oNumero_OP;
      
      IF ROW_COUNT() > 0 THEN
         SET RESULTADO = 1;
         SET MENSAGEM  = 'Atualização Realizada com sucesso!';
      ELSE
         SET RESULTADO = 0;
         SET MENSAGEM  = 'Documento NÃO Localizado !';
      END IF;
      SELECT RESULTADO, MENSAGEM;
   
   END IF;
   
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

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_RetornoEntrada.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_RetornoEntrada`$$

CREATE PROCEDURE `PROC_INTEGRA_RetornoEntrada`(
   IN oCodUsuario				VARCHAR(10),
   IN oIdRetorno				 VARCHAR(20),
   IN oTipoDoc       VARCHAR(10)  #NE = Compras NE / Compras E-RM / Compras E-NE
                                  #DV = Devoluções de Compras
   # Parametros de Retorno
   #OUT RESULTADO             	INT,
   #OUT MENSAGEM              	VARCHAR(500)
)
BLOCO1:BEGIN
   /***************************************************************************
   #@Reviser David Ruy <2019/12/11>
   # Busca informações do tipo de operação para não retornar GEM de Produção 
   #@Reviser David Ruy <2020/02/27>
   # oTipoRetorno = 1 (Entradas Quaisquer), oTipoRetorno = 2 (Entradas Devoluções)
   #@Reviser David Ruy <2021/08/24>
   # oTipoDoc "TD-E" Transferencia entre depósitos <Entrada>
   #@Reviser David Ruy <2021/12/24> Campos ManBtchNum, ManSerNum
   #@Reviser David Ruy <2022-11-04> #confirmação de PV => Considerar apenas com Uitilização parametrizada   
   #@Reviser David Ruy <2023-03-10> #Confirmação de Entradas : Unificação retorno DV => XDV, NE => XNE
   #                                 Isso por conta de utilização do serviço OOne e não mais XNET
   #@Reviser David Ruy <2024-12-11> Se OpenInvQty > 0 então, 
                FatorConvSap = OpenInvQty / BaseQty 
                Caso contrário para Devolução = NumInSales, senão = NumInBuy 2024-12-11
   #@Reviser David Ruy <2024-12-12> Inclusão campos : acons.data_fabr, acons.data_valid (retorno nos lotes/series)   
   #@Reviser David Ruy <2025-01-27> U_BDO_NKIT (Gemmini)
   #@Reviser David Ruy <2025-04-04> IF(tbintegraSAP_Doc.DocTipo IN ('DV','PA','PA000','PA001','PA002'),
   ****************************************************************************/
   DECLARE xCodEmpWMS			      VARCHAR(03)	DEFAULT '001';
   DECLARE xCodFilWMS			      VARCHAR(03) DEFAULT '001';
   DECLARE xNumSolic 			      VARCHAR(10);
   DECLARE xAnoSolic 			      VARCHAR(04)	DEFAULT YEAR(CURRENT_DATE());
   DECLARE xDocEntry          INT;
   DECLARE xDocTipo           VARCHAR(10);
   DECLARE xTipoOperSaida 		  VARCHAR(03) DEFAULT '001';
   DECLARE xCodUnidade			     VARCHAR(03) DEFAULT '001';
   DECLARE xCodArmazem			     VARCHAR(02) DEFAULT '01';
   DECLARE xStatusProcesso		  VARCHAR(02) DEFAULT '01';
   DECLARE xCodErro	          INT DEFAULT 0;
   DECLARE excecao 	          INT DEFAULT 0;
   DECLARE RESULTADO          INT DEFAULT 1;
   DECLARE MENSAGEM           VARCHAR(500);
   DECLARE xSTRGEM            TEXT;
   DECLARE xNumProcesso       VARCHAR(20); 
   DECLARE xutilizacao_entradas_retorno VARCHAR(200) DEFAULT NULL;
   
   DECLARE xFlg_RetornoEntradas VARCHAR(20); 
   
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   
   
   #@Reviser David Ruy <2021-01-27> Força para não retornar nenhum registro para SAP   
   SELECT CONCAT(IF(flg_retorno_entrada_ENE=1,'E-NE','X'), '|', 
                 IF(flg_retorno_entrada_ERM=1,'E-RM','X'), '|', 
                 IF(flg_retorno_entrada_NE=1 ,'NE','X'), '|', 
                 IF(flg_retorno_entrada_PD=1 ,'DV','X'), '|', 
                 IF(flg_retorno_entrada_TD=1 ,'TD-E','X')) 
           ,utilizacao_entradas_retorno
   INTO xFlg_RetornoEntradas, xutilizacao_entradas_retorno
   FROM tbintegraSAP_parametros LIMIT 1;
   
   CALL PROC_SYS_GerarTabelaComTexto(xFlg_RetornoEntradas,"|",1);
   DROP TEMPORARY TABLE IF EXISTS tbTMPTipoDoc;
   CREATE TEMPORARY TABLE tbTMPTipoDoc 
          SELECT * FROM tTabelaComTexto WHERE Coluna01 <> 'X';
   DROP TEMPORARY TABLE IF EXISTS tTabelaComTexto;
   
   
   
   #Cria tabela temporária com as GEM que estão liberadas para retorno à integração
   DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_ENTRADAS;
   IF IFNULL(oIdRetorno,'') = '' THEN
   
      CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_ENTRADAS AS 
         SELECT DocEntry, DocTipo, DocNum, tbEntradas.num_nf, tbEntradas.data_nf, tbEntradas.data_solic
               ,CONCAT(tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic) NumProcesso
               ,tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic
               ,tbEntradas.status_processo, tbEntradas.observ_solic, U_BDO_NKIT 
               #,CONCAT('CALL PROC_INTEGRA_RetornoEntrada("999999","',CONCAT(tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic),'");') _call
         FROM tbintegraSAP_Doc
         INNER JOIN of_logistica.tbsolic_entradas tbEntradas ON
               tbEntradas.cod_emp   = tbintegraSAP_Doc.cod_emp
           AND tbEntradas.cod_fil   = tbintegraSAP_Doc.cod_fil
           AND tbEntradas.ano_solic = tbintegraSAP_Doc.ano_solic
           AND tbEntradas.num_solic = tbintegraSAP_Doc.num_solic
           AND tbEntradas.status_processo >= 8
           AND tbintegraSAP_Doc.StatusDoc = 3
         INNER JOIN of_logistica.tbwms_tipo_oper tbOperacoesWMS ON 
               tbOperacoesWMS.cod_oper_wms = tbEntradas.flg_tipo_oper
         INNER JOIN tbTMPTipoDoc ON
                    tbTMPTipoDoc.Coluna01 = tbintegraSAP_Doc.DocTipo
         WHERE tbintegraSAP_Doc.TipoDocSLIN = 'E'
           AND tbintegraSAP_Doc.DocTipo     = oTipoDoc
           #AND tbOperacoesWMS.flg_producao = 'N';
           AND tbEntradas.flg_producao      = 'N'
           AND tbEntradas.flg_devol         = IF(oTipoDoc='DV','S','N')
           #and tbintegraSAP_Doc.DocEntry in (863, 950,951)
           ;
                      
   ELSE
   
      SET xCodEmpWMS	= SUBSTRING(oIdRetorno,01,03);
      SET xCodFilWMS	= SUBSTRING(oIdRetorno,04,03);
      SET xAnoSolic 	= SUBSTRING(oIdRetorno,07,04);
      SET xNumSolic 	= SUBSTRING(oIdRetorno,11,10);    
      #select xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic;
      /*******************************************************************
      # Validar a existencia da GEM
      *******************************************************************/
      IF NOT EXISTS (SELECT 1 FROM of_logistica.tbsolic_entradas 
                     WHERE cod_emp = xCodEmpWMS
                     AND cod_fil = xCodFilWMS
                     AND ano_solic = xAnoSolic
                     AND num_solic = xNumSolic) THEN
         SET xCodErro = 1;
         SET RESULTADO = 0;
         SET MENSAGEM  = 'GEM não localizada';
         SELECT RESULTADO, MENSAGEM;
         LEAVE BLOCO1;         
      END IF;
      CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_ENTRADAS AS 
         SELECT DocEntry, DocTipo, DocNum, tbEntradas.num_nf, tbEntradas.data_nf, tbEntradas.data_solic
               ,CONCAT(tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic) NumProcesso
               ,tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic
               ,tbEntradas.status_processo, tbEntradas.observ_solic, U_BDO_NKIT
               #,CONCAT('CALL PROC_INTEGRA_RetornoEntrada("999999","',CONCAT(tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic),'");') _call
         FROM tbintegraSAP_Doc
         INNER JOIN of_logistica.tbsolic_entradas tbEntradas ON
               tbEntradas.cod_emp   = tbintegraSAP_Doc.cod_emp
           AND tbEntradas.cod_fil   = tbintegraSAP_Doc.cod_fil
           AND tbEntradas.ano_solic = tbintegraSAP_Doc.ano_solic
           AND tbEntradas.num_solic = tbintegraSAP_Doc.num_solic
           AND tbEntradas.status_processo >= 8
           AND tbintegraSAP_Doc.StatusDoc = 3
         WHERE tbintegraSAP_Doc.cod_emp   = xCodEmpWMS 
           AND tbintegraSAP_Doc.cod_fil   = xCodFilWMS
           AND tbintegraSAP_Doc.ano_solic = xAnoSolic
           AND tbintegraSAP_Doc.num_solic = xNumSolic
           AND tbintegraSAP_Doc.TipoDocSLIN = 'E';
   
   END IF;
    
    
   #select * from tbTMP_INTEGRA_RETORNO_ENTRADAS;
      
   DROP TEMPORARY TABLE IF EXISTS tbTMPTipoDoc;
   
   
   #select IFNULL(xutilizacao_entradas_retorno,'Vazio');
   
   #select * from tbTMP_INTEGRA_RETORNO_ENTRADAS;
    
   #Update (como retornado) para Documentos com utilização diferente da parametrizada
   IF IFNULL(xutilizacao_entradas_retorno,'') <> '' THEN
      UPDATE tbintegraSAP_Doc
      INNER JOIN tbTMP_INTEGRA_RETORNO_ENTRADAS ON
                 tbTMP_INTEGRA_RETORNO_ENTRADAS.DocTipo  = tbintegraSAP_Doc.DocTipo
             AND tbTMP_INTEGRA_RETORNO_ENTRADAS.DocEntry = tbintegraSAP_Doc.DocEntry
             AND tbTMP_INTEGRA_RETORNO_ENTRADAS.DocNum   = tbintegraSAP_Doc.DocNum
      SET StatusAnt = StatusDoc,
          StatusDoc = 6
      #where LOCATE(tbintegraSAP_Doc.MainUsage,xutilizacao_entradas_retorno) = 0);
      WHERE EXISTS (SELECT 1 FROM tbintegraSAP_DocItem
                    WHERE tbintegraSAP_DocItem.DocTipo  = tbintegraSAP_Doc.DocTipo
                      AND tbintegraSAP_DocItem.DocEntry = tbintegraSAP_Doc.DocEntry
                      AND tbintegraSAP_DocItem.DocNum   = tbintegraSAP_Doc.DocNum
                      AND LOCATE(IFNULL(tbintegraSAP_DocItem.Usage_,'XXX'),xutilizacao_entradas_retorno) = 0);
                      
                      
      DELETE FROM tbTMP_INTEGRA_RETORNO_ENTRADAS 
      WHERE EXISTS (SELECT 1 FROM tbintegraSAP_Doc
                    WHERE tbintegraSAP_Doc.DocTipo = tbTMP_INTEGRA_RETORNO_ENTRADAS.DocTipo
                      AND tbintegraSAP_Doc.DocEntry  = tbTMP_INTEGRA_RETORNO_ENTRADAS.DocEntry
                      AND tbintegraSAP_Doc.DocNum = tbTMP_INTEGRA_RETORNO_ENTRADAS.DocNum
                      AND StatusDoc = 6);
   END IF;
   
   
   #Alimenta variavel xSTRGEM com a lista das GEM´s selecionadas
   SET xSTRGEM = '';  
   WHILE EXISTS (SELECT 1 FROM tbTMP_INTEGRA_RETORNO_ENTRADAS) DO
      SELECT NumProcesso, cod_emp, cod_fil, ano_solic, num_solic, DocEntry, Doctipo
      INTO xNumProcesso, xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xDocEntry, xDoctipo
      FROM tbTMP_INTEGRA_RETORNO_ENTRADAS LIMIT 1;         
      
      SET xSTRGEM = CONCAT(xSTRGEM, CONCAT(xCodEmpWMS, "|", xCodFilWMS, "|", xAnoSolic, "|", xNumSolic, "|", xDocEntry, "|"), xDocTipo, "|");
      DELETE FROM tbTMP_INTEGRA_RETORNO_ENTRADAS WHERE NumProcesso = xNumProcesso;
   END WHILE;
   DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_ENTRADAS;
   #Cria tabela temporária auxiliar para inner join com a tbsolic_entradas para gerar seleção das informações
   #da GEM informada no parametro
   CALL PROC_SYS_GerarTabelaComTexto(xSTRGEM,'|',6);
    
    
   /*******************************************************************
   # Selecionar as informações da GEM
   *******************************************************************/
   IF oTipoDoc IN ('DV','NE','E-RM','E-NE','TD-E') THEN
   
      # INFORMAÇÕES DO TOPO DA GEM
      #IF oTipoDoc IN ('NE','DV') THEN
      IF oTipoDoc IN ('XNE','xDV') THEN
         SELECT tTabelaComTexto.Coluna05 AS DocEntry, tTabelaComTexto.Coluna06 AS Doctipo, 
               topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
               topo.data_solic, topo.dthr_acons, topo.num_nf AS num_pedido,
               topo.observ_solic, topo.observ_conf01, topo.status_processo, 
               of_logistica.fnStatusSaidaWms(topo.status_processo) status_processoAux,
               #Liberação Inicio Processo de Separação, Picking
               topo.dthr_endereco, topo.dthr_confer, topo.dthr_confirm,
               #Inicio Processo de Separação, Picking
               topo.dthr_chegada, topo.final_descarga,
         # INFORMAÇÕES INTEGRAÇÃO
               tbintegraSAP_Doc.DocNum,
               tbintegraSAP_Doc.DocDate,
               tbintegraSAP_Doc.CardCode, tbintegraSAP_Doc.CardName, 
               CONCAT(tbintegraSAP_Doc.StreetS," - ",tbintegraSAP_Doc.CityS,"-",tbintegraSAP_Doc.StateS,"-",tbintegraSAP_Doc.CountryS,
                      " CEP:",tbintegraSAP_Doc.ZipCodeS) AS Address,
               tbintegraSAP_DocItem.LineNum,
               tbintegraSAP_Doc.ItemCode, 
               tbintegraSAP_Doc.Observacoes,
               tbintegraSAP_Doc.SERIAL,
               tbintegraSAP_Doc.StreetS,
               tbintegraSAP_Doc.AddrTypeS,
               tbintegraSAP_Doc.StreetNoS,
               tbintegraSAP_Doc.BlockS,
               tbintegraSAP_Doc.BuildingS,
               tbintegraSAP_Doc.CityS,
               tbintegraSAP_Doc.ZipCodeS,
               tbintegraSAP_Doc.StateS,
               tbintegraSAP_Doc.CountryS,
               "Employee" Employee,
               tbintegraSAP_Doc.U_BDO_NKIT,
         # INFORMAÇÕES DOS ITENS DA GEM
               #FatorConvSap para Devolução = NumInSales, senão = NumInBuy 2024-12-11
               IF(IFNULL(tbintegraSAP_DocItem.OpenInvQty,0) > 0, 
                 tbintegraSAP_DocItem.OpenInvQty / tbintegraSAP_DocItem.BaseQty,
                 #IF(tbintegraSAP_Doc.DocTipo IN ('DV'),
                 IF(tbintegraSAP_Doc.DocTipo IN ('DV','PA','PA000','PA001','PA002'),
                    IF(IFNULL(tbintegraSAP_DocItem.NumInSale,1)=0,1,tbintegraSAP_DocItem.NumInSale),
                    IF(IFNULL(tbintegraSAP_DocItem.NumInBuy,1)=0,1,tbintegraSAP_DocItem.NumInBuy)))  AS FatorConvSAP,
               #tbintegraSAP_DocItem.buyUnitMsr, tbintegraSAP_DocItem.salUnitMsr, tbintegraSAP_DocItem.invntryUom,
               #Desabilitado em 2024-12-11
               #IF(IFNULL(prod.fator_conv_compras,1)=0,1,prod.fator_conv_compras) AS FatorConvSAP,
               prod.emb_compras buyUnitMsr, prod.emb_vendas salUnitMsr, prod.emb_estoque_cli invntryUom,  
               tbintegraSAP_DocItem.ManBtchNum, tbintegraSAP_DocItem.ManSerNum,            
               ite.num_nf_vda AS num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
               ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
               #
               ite.qtde_est, ite.qtde_vol, ite.qtde_frac, ite.pliq_item,		#Qtde Pedido
               ite.real_est, ite.real_vol, ite.real_frac, ite.real_peso,		#Qtde Aconselhada
               ite.real_est2, ite.real_vol2, ite.real_frac2, ite.real_peso2,	#Qtde Conferencia
               ite.real_est3, ite.real_vol3, ite.real_frac3, ite.real_peso3,	#Qtde Conferencia / ???
               #			
               ite.dthr_conf_ini, ite.dthr_conf_fin,
               tbintegraSAP_DocItem.Usage_,
               topo.chave_integracao,
               prod.flg_obriga_lote_fornecedor,
               tbintegraSAP_Doc.BPLId, tbintegraSAP_Doc.CFOP,
               RESULTADO, MENSAGEM
         FROM of_logistica.tbsolic_entradas topo
         INNER JOIN tTabelaComTexto ON
                   tTabelaComTexto.Coluna01 = topo.cod_emp
               AND tTabelaComTexto.Coluna02 = topo.cod_fil
               AND tTabelaComTexto.Coluna03 = topo.ano_solic
               AND tTabelaComTexto.Coluna04 = topo.num_solic
         LEFT JOIN tbintegraSAP_Doc ON 
                  tbintegraSAP_Doc.cod_emp = topo.cod_emp
              AND tbintegraSAP_Doc.cod_fil = topo.cod_fil
              AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
              AND tbintegraSAP_Doc.num_solic = topo.num_solic
              AND tbintegraSAP_Doc.TipoDocSLIN = 'E'
         LEFT JOIN of_logistica.tbsolic_entradas_item ite ON
                   ite.cod_emp = topo.cod_emp
               AND ite.cod_fil = topo.cod_fil
               AND ite.ano_solic = topo.ano_solic
               AND ite.num_solic = topo.num_solic
         INNER JOIN tbintegraSAP_DocItem ON 
                   tbintegraSAP_DocItem.cod_emp = ite.cod_emp
               AND tbintegraSAP_DocItem.cod_fil = ite.cod_fil
               AND tbintegraSAP_DocItem.ano_solic = ite.ano_solic
               AND tbintegraSAP_DocItem.num_solic = ite.num_solic
               AND tbintegraSAP_DocItem.num_item = ite.num_item
               AND tbintegraSAP_DocItem.DocTipo  = tbintegraSAP_Doc.DocTipo
         LEFT JOIN of_logistica.tbprodutos prod ON
                   prod.cnpj_cpf = ite.cnpj_cpf_dep
               AND prod.cod_produto = ite.cod_produto
         WHERE ite.real_est > 0;
      ELSE
      
         #Topo
         SELECT DISTINCT tTabelaComTexto.Coluna05 AS DocEntry, tTabelaComTexto.Coluna06 AS Doctipo, 
               topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
               topo.data_solic, topo.dthr_acons, topo.num_nf AS num_pedido,
               topo.observ_solic, topo.observ_conf01, topo.status_processo, 
               of_logistica.fnStatusSaidaWms(topo.status_processo) status_processoAux,
               #Liberação Inicio Processo de Separação, Picking
               topo.dthr_endereco, topo.dthr_confer, topo.dthr_confirm,
               #Inicio Processo de Separação, Picking
               topo.dthr_chegada, topo.final_descarga,
         # INFORMAÇÕES INTEGRAÇÃO
               tbintegraSAP_Doc.DocNum,
               tbintegraSAP_Doc.DocDate,
               tbintegraSAP_Doc.CardCode, tbintegraSAP_Doc.CardName, 
               CONCAT(tbintegraSAP_Doc.StreetS," - ",tbintegraSAP_Doc.CityS,"-",tbintegraSAP_Doc.StateS,"-",tbintegraSAP_Doc.CountryS,
               " CEP:",tbintegraSAP_Doc.ZipCodeS) AS Address, 
               tbintegraSAP_Doc.Observacoes,
               tbintegraSAP_Doc.SERIAL,
               tbintegraSAP_Doc.StreetS,
               tbintegraSAP_Doc.AddrTypeS,
               tbintegraSAP_Doc.StreetNoS,
               tbintegraSAP_Doc.BlockS,
               tbintegraSAP_Doc.BuildingS,
               tbintegraSAP_Doc.CityS,
               tbintegraSAP_Doc.ZipCodeS,
               tbintegraSAP_Doc.StateS,
               tbintegraSAP_Doc.CountryS,
               tbintegraSAP_Doc.WhareHouse,
               tbintegraSAP_Doc.WhareHouseTransf,
               "Employee" Employee,
               topo.chave_integracao,
               tbintegraSAP_Doc.BPLId, tbintegraSAP_Doc.CFOP,
               tbintegraSAP_Doc.U_BDO_NKIT,
               RESULTADO, MENSAGEM
         FROM of_logistica.tbsolic_entradas topo
         INNER JOIN tTabelaComTexto ON
                   tTabelaComTexto.Coluna01 = topo.cod_emp
               AND tTabelaComTexto.Coluna02 = topo.cod_fil
               AND tTabelaComTexto.Coluna03 = topo.ano_solic
               AND tTabelaComTexto.Coluna04 = topo.num_solic
         LEFT JOIN tbintegraSAP_Doc ON 
                  tbintegraSAP_Doc.cod_emp = topo.cod_emp
              AND tbintegraSAP_Doc.cod_fil = topo.cod_fil
              AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
              AND tbintegraSAP_Doc.num_solic = topo.num_solic
              AND tbintegraSAP_Doc.TipoDocSLIN = 'E'
         LEFT JOIN of_logistica.tbsolic_entradas_item ite ON
                   ite.cod_emp = topo.cod_emp
               AND ite.cod_fil = topo.cod_fil
               AND ite.ano_solic = topo.ano_solic
               AND ite.num_solic = topo.num_solic
         WHERE ite.real_est > 0;
         
         #Itens
         SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
               topo.data_solic, topo.dthr_acons, topo.num_nf AS num_pedido,               
         # INFORMAÇÕES DA INTEGRACAO
               tbintegraSAP_DocItem.LineNum, tbintegraSAP_DocItem.WhareHouse,
               tbintegraSAP_DocItem.Observacoes, tbintegraSAP_DocItem.Price,
               #IF(IFNULL(tbintegraSAP_DocItem.NumInSale,1)=0,1,tbintegraSAP_DocItem.NumInSale) AS FatorConvSAP,
               #tbintegraSAP_DocItem.buyUnitMsr, tbintegraSAP_DocItem.salUnitMsr, tbintegraSAP_DocItem.invntryUom,
               #Desabilitado em 2024-12-11
               #IF(IFNULL(prod.fator_conv_compras,1)=0,1,prod.fator_conv_compras) AS FatorConvSAP,
               IF(IFNULL(tbintegraSAP_DocItem.OpenInvQty,0) > 0, 
                 tbintegraSAP_DocItem.OpenInvQty / tbintegraSAP_DocItem.BaseQty,
                 #IF(tbintegraSAP_Doc.DocTipo IN ('DV'),
                 IF(tbintegraSAP_Doc.DocTipo IN ('DV','PA','PA000','PA001','PA002'),
                    IF(IFNULL(tbintegraSAP_DocItem.NumInSale,1)=0,1,tbintegraSAP_DocItem.NumInSale),
                    IF(IFNULL(tbintegraSAP_DocItem.NumInBuy,1)=0,1,tbintegraSAP_DocItem.NumInBuy)))  AS FatorConvSAP,
               prod.emb_compras buyUnitMsr, prod.emb_vendas salUnitMsr, prod.emb_estoque_cli invntryUom,  
               tbintegraSAP_DocItem.ManBtchNum, tbintegraSAP_DocItem.ManSerNum,
         # INFORMAÇÕES DOS ITENS DA GEM
               ite.num_nf_vda AS num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
               ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
               #
               ite.qtde_est, ite.qtde_vol, ite.qtde_frac, ite.pliq_item,		#Qtde Pedido
               ite.real_est, ite.real_vol, ite.real_frac, ite.real_peso,		#Qtde Aconselhada
               ite.real_est2, ite.real_vol2, ite.real_frac2, ite.real_peso2,	#Qtde Conferencia
               ite.real_est3, ite.real_vol3, ite.real_frac3, ite.real_peso3,	#Qtde Conferencia / ???
               #			
               ite.dthr_conf_ini, ite.dthr_conf_fin,
               tbintegraSAP_DocItem.Usage_, tbintegraSAP_DocItem.TaxCode, tbintegraSAP_DocItem.CFOPCode, 
               topo.chave_integracao,
               prod.flg_obriga_lote_fornecedor,
               
               RESULTADO, MENSAGEM
         FROM of_logistica.tbsolic_entradas topo
         INNER JOIN tTabelaComTexto ON
                   tTabelaComTexto.Coluna01 = topo.cod_emp
               AND tTabelaComTexto.Coluna02 = topo.cod_fil
               AND tTabelaComTexto.Coluna03 = topo.ano_solic
               AND tTabelaComTexto.Coluna04 = topo.num_solic
         LEFT JOIN tbintegraSAP_Doc ON 
                  tbintegraSAP_Doc.cod_emp = topo.cod_emp
              AND tbintegraSAP_Doc.cod_fil = topo.cod_fil
              AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
              AND tbintegraSAP_Doc.num_solic = topo.num_solic
              AND tbintegraSAP_Doc.TipoDocSLIN = 'E'
         LEFT JOIN of_logistica.tbsolic_entradas_item ite ON
                   ite.cod_emp = topo.cod_emp
               AND ite.cod_fil = topo.cod_fil
               AND ite.ano_solic = topo.ano_solic
               AND ite.num_solic = topo.num_solic
         INNER JOIN tbintegraSAP_DocItem ON 
                   tbintegraSAP_DocItem.cod_emp = ite.cod_emp
               AND tbintegraSAP_DocItem.cod_fil = ite.cod_fil
               AND tbintegraSAP_DocItem.ano_solic = ite.ano_solic
               AND tbintegraSAP_DocItem.num_solic = ite.num_solic
               AND tbintegraSAP_DocItem.num_item = ite.num_item
               AND tbintegraSAP_DocItem.DocTipo  = tbintegraSAP_Doc.DocTipo
         LEFT JOIN of_logistica.tbprodutos prod ON
                   prod.cnpj_cpf = ite.cnpj_cpf_dep
               AND prod.cod_produto = ite.cod_produto
         WHERE ite.real_est > 0;         
      END IF;
      
            
      # INFORMAÇÕES DAS UA´S DA GEM
      SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
            ite.num_nf_vda AS num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
            ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
            #
            CONCAT(acons.num_lote,acons.sequencia_lote) AS NumUA,
            acons.data_fabr, acons.data_valid,
            tbwms_estoque.num_lote_cli,
            SUM(acons.qtde_est) qtde_est, 
            SUM(acons.qtde_vol) qtde_vol, 
            SUM(acons.qtde_frac) qtde_frac, 
            SUM(acons.qtde_peso) qtde_peso,		#Qtde Aconselhada
            #Qtde Conferencia (SAP não recebe Qtde Entrada a maior, PROC_INTEGRA_RetornoContagem gera registro de complementos)
            #if(acons.qtde_est2 > acons.qtde_est, acons.qtde_est, acons.qtde_est2) as qtde_est2, 
            #if(acons.qtde_vol2 > acons.qtde_vol, acons.qtde_vol, acons.qtde_vol2) as qtde_vol2, 
            #if(acons.qtde_frac2 > acons.qtde_frac, acons.qtde_frac, acons.qtde_frac2) as qtde_frac2, 
            #if(acons.qtde_peso2 > acons.qtde_peso, acons.qtde_peso, acons.qtde_peso2) as qtde_peso2,
            #@Reviser David Ruy <2019/12/30> Alterado para enviar a quantidade Real Conferida
            #Qtde Conferencia (SAP não recebe Qtde Entrada a maior, PROC_INTEGRA_RetornoContagem gera registro de complementos)
            SUM(acons.qtde_est2) AS qtde_est2, 
            SUM(acons.qtde_vol2) AS qtde_vol2, 
            SUM(acons.qtde_frac2) AS qtde_frac2, 
            SUM(acons.qtde_peso2) AS qtde_peso2,
            SUM(acons.qtde_est3) AS qtde_est3, 
            SUM(acons.qtde_vol3) AS qtde_vol3, 
            SUM(acons.qtde_frac3) AS qtde_frac3, 
            SUM(acons.qtde_peso3) AS qtde_peso3,	#(*) Qtde Conferencia/???
            #		
            acons.dthr_conf, acons.dthr_armaz
            #,tbIntegraDeposito.cod_armazem WarehouseCode,
            ,tbstatus_lotes_integracao.deposito_integracao WarehouseCode,
            topo.chave_integracao,
            RESULTADO, MENSAGEM
      FROM of_logistica.tbsolic_entradas topo
      LEFT JOIN of_logistica.tbsolic_entradas_item ite ON
            ite.cod_emp = topo.cod_emp
            AND ite.cod_fil = topo.cod_fil
            AND ite.ano_solic = topo.ano_solic
            AND ite.num_solic = topo.num_solic			
      LEFT JOIN of_logistica.tbprodutos prod ON
            prod.cnpj_cpf = ite.cnpj_cpf_dep
            AND prod.cod_produto = ite.cod_produto
      LEFT JOIN of_logistica.tbsolic_entradas_acons acons ON
            acons.cod_emp = ite.cod_emp
            AND acons.cod_fil = ite.cod_fil
            AND acons.ano_solic = ite.ano_solic
            AND acons.num_solic = ite.num_solic			
            AND acons.num_item  = ite.num_item
      LEFT JOIN of_logistica.tbwms_estoque ON  
            tbwms_estoque.cod_emp = acons.cod_emp
            AND tbwms_estoque.cod_fil = acons.cod_fil
            AND tbwms_estoque.num_lote = acons.num_lote
            AND tbwms_estoque.sequencia_lote = acons.sequencia_lote
      #LEFT JOIN tbintegraSAP_DeParaStatus_Armazem tbIntegraDeposito ON 
      #      tbIntegraDeposito.cod_status =  tbwms_estoque.status_lote
      LEFT JOIN of_logistica.tbstatus_lotes_integracao ON
                tbstatus_lotes_integracao.cod_emp = topo.cod_emp
            AND tbstatus_lotes_integracao.cod_fil = topo.cod_fil
            AND tbstatus_lotes_integracao.codigo_status = tbwms_estoque.status_lote
      INNER JOIN tTabelaComTexto ON
            tTabelaComTexto.Coluna01 = topo.cod_emp
            AND tTabelaComTexto.Coluna02 = topo.cod_fil
            AND tTabelaComTexto.Coluna03 = topo.ano_solic
            AND tTabelaComTexto.Coluna04 = topo.num_solic
      WHERE acons.qtde_est2  > 0
      GROUP BY chave_integracao, num_item, num_lote_cli;
            
   END IF; 
   
   DROP TEMPORARY TABLE IF EXISTS tTabelaComTexto;
    
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      SELECT RESULTADO, MENSAGEM;
   ELSE    
      SET RESULTADO = 1;
      #SET MENSAGEM  = 'Processo Realizado com sucesso!';
   END IF;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_RetornoMateriaPrima.sql*/

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

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_RetornoMovtoEstoque.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_RetornoMovtoEstoque`$$

CREATE PROCEDURE `PROC_INTEGRA_RetornoMovtoEstoque`(
)
BLOCO1:BEGIN
   /***************************************************************************
   #@Autho David Ruy <2019/12/11>
   # Movimentação de Estoque (bloqueio/desbloquio de UA´s, alteração de status)
   #2024-11-21 Desconsiderar movimentações com data superior a 30 dias da data atual   
   #2025-07-21 Inclusão campo tbfiliais.chave_integracao BPLId
   #2025-10-23 Desabilita movimentações onde o Depósito Origem = Depósito Destino   
   ****************************************************************************/
   
   
   DECLARE xCodEmpWMS			     VARCHAR(03)	DEFAULT '001';
   DECLARE xCodFilWMS			     VARCHAR(03) DEFAULT '001';
   DECLARE xNumSolic 			     VARCHAR(10);
   DECLARE xAnoSolic 			     VARCHAR(04)	DEFAULT YEAR(CURRENT_DATE());
   DECLARE xDocEntry         INT;
   DECLARE xDocTipo          VARCHAR(10);
   DECLARE xTipoOperSaida 		 VARCHAR(03) DEFAULT '001';
   DECLARE xCodUnidade			    VARCHAR(03) DEFAULT '001';
   DECLARE xCodArmazem			    VARCHAR(02) DEFAULT '01';
   DECLARE xStatusProcesso		 VARCHAR(02) DEFAULT '01';
   DECLARE xCodErro	         INT DEFAULT 0;
   DECLARE excecao 	         INT DEFAULT 0;
   DECLARE RESULTADO         INT DEFAULT 1;
   DECLARE MENSAGEM          VARCHAR(500);
   DECLARE xSTRGEM           TEXT;
   DECLARE xNumProcesso      VARCHAR(20);  
   DECLARE xQtdeDias         INT DEFAULT 30;
   
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
    
   #Cria tabela temporária com as GEM que estão liberadas para retorno à integração
   DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_MOVTOESTOQUE;
   
   CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_MOVTOESTOQUE AS 
      SELECT CONCAT("Movimentação SLIN - UA:",tbwmsManut.num_lote,tbwmsManut.sequencia_lote," ",IFNULL(tbwmsManut.observ,'')) AS Comments,       
             CURRENT_TIMESTAMP() AS TaxDate, 
             CONCAT(TRIM(LEADING '0' FROM tbwmsEstoque.cod_emp),'/',TRIM(LEADING '0' FROM tbwmsEstoque.cod_fil),'-',
                    TRIM(LEADING '0' FROM tbwmsEstoque.num_lote),'.',tbwmsEstoque.sequencia_lote) AS NumLoteSlin,
             tbwmsEstoque.num_lote_cli NumLoteFabr,
             tbwmsManut.dthr_inc DataMovimento,
             tbwmsManut.id_manutencao idMovimento,
             tbwmsManut.observacao Observacoes,
             tbwmsEstoque.cod_produto AS ItemCode,
             tbwmsManut.cod_status_ant StatusAnt,
             tbwmsManut.cod_status StatusAtu,
             IFNULL(tbIntegraOri.deposito_integracao, tbIntegraOri2.deposito_integracao) FromWareHouseCode,
             IFNULL(tbIntegraDest.deposito_integracao,tbIntegraDest2.deposito_integracao) ToWareHouseCode,
             tbwmsEstoque.sld_fisico_est Quantity,
             of_logistica.fnLocalizCompleta2(tbwmsEstoque.cod_und, tbwmsEstoque.cod_armazem, tbwmsEstoque.camara, tbwmsEstoque.rua, 
                              tbwmsEstoque.posicao, tbwmsEstoque.altura, tbwmsEstoque.profund, NULL, "SEM LOCAL") binCode,
             tbProd.flg_obriga_lote_fornecedor,
             NULL AS CardCode,
             NULL AS CardName,
             NULL AS Address,
             tbwmsEstoque.emb_est,
             1 AS QtdeEmbalagem,
             tbfiliais.chave_integracao BPLId
      FROM of_logistica.tbwms_manut_lote tbwmsManut
      INNER JOIN of_logistica.tbfiliais ON 
                 tbfiliais.cod_empresa = tbwmsManut.cod_emp
             AND tbfiliais.cod_filial  = tbwmsManut.cod_fil
      INNER JOIN of_logistica.tbwms_estoque tbwmsEstoque ON
                  tbwmsEstoque.cod_emp = tbwmsManut.cod_emp
              AND tbwmsEstoque.cod_fil = tbwmsManut.cod_fil
              AND tbwmsEstoque.num_lote = tbwmsManut.num_lote
              AND tbwmsEstoque.sequencia_lote = tbwmsManut.sequencia_lote
      LEFT JOIN of_logistica.tbprodutos tbProd ON
                  tbProd.cnpj_cpf    = tbwmsEstoque.cnpj_cpf_dep
              AND tbProd.cod_produto = tbwmsEstoque.cod_produto
      #LEFT JOIN tbintegraSAP_DeParaStatus_Armazem tbIntegraOri ON 
      #            tbIntegraOri.cod_status = tbwmsManut.cod_status_ant
      #LEFT JOIN tbintegraSAP_DeParaStatus_Armazem tbIntegraDest ON 
      #            tbIntegraDest.cod_status = tbwmsManut.cod_status
      LEFT JOIN of_logistica.tbstatus_lotes_integracao tbIntegraOri ON 
                tbIntegraOri.cod_emp    = tbwmsManut.cod_emp 
            AND tbIntegraOri.cod_fil    = tbwmsManut.cod_fil
            AND tbIntegraOri.codigo_status = tbwmsManut.cod_status_ant
      LEFT JOIN of_logistica.tbstatus_lotes tbIntegraOri2 ON 
                tbIntegraOri2.codigo = tbwmsManut.cod_status_ant
      LEFT JOIN of_logistica.tbstatus_lotes_integracao tbIntegraDest ON 
                tbIntegraDest.cod_emp    = tbwmsManut.cod_emp 
            AND tbIntegraDest.cod_fil    = tbwmsManut.cod_fil
            AND tbIntegraDest.codigo_status = tbwmsManut.cod_status
      LEFT JOIN of_logistica.tbstatus_lotes tbIntegraDest2 ON 
                tbIntegraDest2.codigo = tbwmsManut.cod_status
      WHERE tbwmsManut.cod_status_ant <> tbwmsManut.cod_status
        AND tbwmsManut.dthr_retorno_integracao IS NULL
        AND tbwmsManut.dthr_inc >= DATE_SUB(CURRENT_DATE, INTERVAL xQtdeDias DAY)
        ;
   
   #Desabilita movimentações onde o Depósito Origem = Depósito Destino
   UPDATE of_logistica.tbwms_manut_lote tbwmsManut
   INNER JOIN tbTMP_INTEGRA_RETORNO_MOVTOESTOQUE ON
              tbTMP_INTEGRA_RETORNO_MOVTOESTOQUE.idMovimento = tbwmsManut.id_manutencao              
   SET tbwmsManut.dthr_retorno_integracao = NOW(), 
       tbwmsManut.observ = CONCAT("IntegraSAP|Ori=",FromWareHouseCode,"/Dest=",ToWareHouseCode," Transf Não realizada")
   WHERE FromWareHouseCode = ToWareHouseCode;
       
   DELETE FROM tbTMP_INTEGRA_RETORNO_MOVTOESTOQUE
   WHERE FromWareHouseCode = ToWareHouseCode;
   
   SELECT * FROM tbTMP_INTEGRA_RETORNO_MOVTOESTOQUE;
   
   DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_MOVTOESTOQUE;
    
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      SELECT RESULTADO, MENSAGEM;
   ELSE    
      SET RESULTADO = 1;
      #SET MENSAGEM  = 'Processo Realizado com sucesso!';
   END IF;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_RetornoPickingReabrir.sql*/

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

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_RetornoProducao.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_RetornoProducao`$$

CREATE PROCEDURE `PROC_INTEGRA_RetornoProducao`(
   IN oCodUsuario				VARCHAR(10),
   IN oIdRetorno				 MEDIUMTEXT,
   IN oTiporetorno   INT     #0 = 3 RecordSets (Topo - Item - UA), 1 = 2 RecordSets (Topo/Item - UA)
                             #10 = Listar Documentos a gerar ENTRADA COMPLETA
                             #11 = Gerar ENTRADA COMPLETA
   #IN oTipoConsulta			INT     #0 = Apenas o Topo, 1 = Detalhe por ITEM, 2 = Detalhe por UA
   # Parametros de Retorno
   #OUT RESULTADO             	INT,
   #OUT MENSAGEM              	VARCHAR(500)
)
BLOCO1:BEGIN
   /***************************************************************************
   #@Reviser David Ruy <2019/12/11> 
   # Busca informações do tipo de operação para retornar apenas GEM de Produção 
   #@Reviser David Ruy <2026/04/04> 
   # Implementado retorno campo tbintegraSAP_Doc.TipoProducao
   ****************************************************************************/
   DECLARE xCodEmpWMS			    VARCHAR(03)	DEFAULT '001';
   DECLARE xCodFilWMS			    VARCHAR(03) DEFAULT '001';
   DECLARE xNumSolic 			    VARCHAR(10);
   DECLARE xAnoSolic 			    VARCHAR(04)	DEFAULT YEAR(CURRENT_DATE());
   DECLARE xDocEntry        INT;
   DECLARE xDocTipo         VARCHAR(10);
   DECLARE xTipoOperSaida 		VARCHAR(03) DEFAULT '001';
   DECLARE xCodUnidade			   VARCHAR(03) DEFAULT '001';
   DECLARE xCodArmazem			   VARCHAR(02) DEFAULT '01';
   DECLARE xStatusProcesso		VARCHAR(02) DEFAULT '01';
   DECLARE xCodErro	        INT DEFAULT 0;
   DECLARE excecao 	        INT DEFAULT 0;
   DECLARE RESULTADO        INT DEFAULT 1;
   DECLARE MENSAGEM         VARCHAR(500);
   DECLARE xSTRGEM          TEXT;
   DECLARE xNumProcesso     VARCHAR(20);  
   
   DECLARE xNumUA           INT;
   DECLARE xIdPallet        VARCHAR(50);
   DECLARE xQtde            DECIMAL(18,6);
   DECLARE xNumLote         VARCHAR(50);
   DECLARE xDataFabr        VARCHAR(20);
   DECLARE xDataValid       VARCHAR(20);
   DECLARE xFatorConv       DECIMAL(18,6);
   DECLARE xCodProduto      VARCHAR(50);
   DECLARE xNumCaixaBarcode VARCHAR(100);
   
   
   
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
   DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_PRODUCAO;
   
   IF oTiporetorno IN (0,1,10) THEN
  
      IF IFNULL(oIdRetorno,'') = '' THEN
      
         CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_PRODUCAO AS 
            SELECT DocEntry, DocTipo, DocNum, tbEntradas.num_nf, tbEntradas.data_nf, tbEntradas.data_solic
                  ,CONCAT(tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic) NumProcesso
                  ,tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic
                  ,tbEntradas.status_processo, tbEntradas.observ_solic 
                  #,CONCAT('CALL PROC_INTEGRA_RetornoEntrada("999999","',CONCAT(tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic,   tbEntradas.num_solic),'");') _call
            FROM tbintegraSAP_Doc
            INNER JOIN of_logistica.tbsolic_entradas tbEntradas ON
                  tbEntradas.cod_emp   = tbintegraSAP_Doc.cod_emp
              AND tbEntradas.cod_fil   = tbintegraSAP_Doc.cod_fil
              AND tbEntradas.ano_solic = tbintegraSAP_Doc.ano_solic
              AND tbEntradas.num_solic = tbintegraSAP_Doc.num_solic
              AND IF(oTiporetorno = 10, tbEntradas.status_processo = 3, tbEntradas.status_processo >= 8)
              AND tbintegraSAP_Doc.StatusDoc = 3
            INNER JOIN of_logistica.tbwms_tipo_oper tbOperacoesWMS ON 
                  tbOperacoesWMS.cod_oper_wms = tbEntradas.flg_tipo_oper
            WHERE tbintegraSAP_Doc.TipoDocSLIN = 'E'
              #AND tbOperacoesWMS.flg_producao = 'S';
              AND tbEntradas.flg_producao = 'S';
      ELSE
      
         SET xCodEmpWMS	= SUBSTRING(oIdRetorno,01,03);
         SET xCodFilWMS	= SUBSTRING(oIdRetorno,04,03);
         SET xAnoSolic 	= SUBSTRING(oIdRetorno,07,04);
         SET xNumSolic 	= SUBSTRING(oIdRetorno,11,10);    
         #select xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic;
         /*******************************************************************
         # Validar a existencia da GEM
         *******************************************************************/
         IF NOT EXISTS (SELECT 1 FROM of_logistica.tbsolic_entradas 
                        WHERE cod_emp = xCodEmpWMS
                        AND cod_fil = xCodFilWMS
                        AND ano_solic = xAnoSolic
                        AND num_solic = xNumSolic) THEN
            SET xCodErro = 1;
            SET RESULTADO = 0;
            SET MENSAGEM  = 'GEM não localizada';
            SELECT RESULTADO, MENSAGEM;
            LEAVE BLOCO1;         
         END IF;
         CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_PRODUCAO AS 
            SELECT DocEntry, DocTipo, DocNum, tbEntradas.num_nf, tbEntradas.data_nf, tbEntradas.data_solic
                  ,CONCAT(tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic) NumProcesso
                  ,tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic
                  ,tbEntradas.status_processo, tbEntradas.observ_solic 
                  #,CONCAT('CALL PROC_INTEGRA_RetornoEntrada("999999","',CONCAT(tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic),'");') _call
            FROM tbintegraSAP_Doc
            INNER JOIN of_logistica.tbsolic_entradas tbEntradas ON
                  tbEntradas.cod_emp   = tbintegraSAP_Doc.cod_emp
              AND tbEntradas.cod_fil   = tbintegraSAP_Doc.cod_fil
              AND tbEntradas.ano_solic = tbintegraSAP_Doc.ano_solic
              AND tbEntradas.num_solic = tbintegraSAP_Doc.num_solic
              AND tbEntradas.status_processo >= 8
              AND tbintegraSAP_Doc.StatusDoc = 3
            WHERE tbintegraSAP_Doc.cod_emp   = xCodEmpWMS 
              AND tbintegraSAP_Doc.cod_fil   = xCodFilWMS
              AND tbintegraSAP_Doc.ano_solic = xAnoSolic
              AND tbintegraSAP_Doc.num_solic = xNumSolic
              AND tbintegraSAP_Doc.TipoDocSLIN = 'E';
      
      END IF;
      
      #Alimenta variavel xSTRGEM com a lista das GEM´s selecionadas
      SET xSTRGEM = '';  
      WHILE EXISTS (SELECT 1 FROM tbTMP_INTEGRA_RETORNO_PRODUCAO) DO
         SELECT NumProcesso, cod_emp, cod_fil, ano_solic, num_solic, DocEntry, Doctipo
         INTO xNumProcesso, xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xDocEntry, xDoctipo
         FROM tbTMP_INTEGRA_RETORNO_PRODUCAO LIMIT 1;         
         
         SET xSTRGEM = CONCAT(xSTRGEM, CONCAT(xCodEmpWMS, "|", xCodFilWMS, "|", xAnoSolic, "|", xNumSolic, "|", xDocEntry, "|"), xDocTipo, "|");
         DELETE FROM tbTMP_INTEGRA_RETORNO_PRODUCAO WHERE NumProcesso = xNumProcesso;
      END WHILE;
      DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_PRODUCAO;
      #Cria tabela temporária auxiliar para inner join com a tbsolic_entradas para gerar seleção das informações
      #da GSM informada no parametro
      CALL PROC_SYS_GerarTabelaComTexto(xSTRGEM,'|',6);
      
   ELSEIF oTiporetorno = 11 THEN
   
      #Complementar a GEM com as informações das etiquetas dos pallets lidos


      #Cria tabela temporária auxiliar com informações dos lotes e quantidade de cada pallet     
      CALL PROC_SYS_GerarTabelaComTexto(oIdRetorno,'|',6);
      #select * from tTabelaComTexto;
      
      START TRANSACTION;
      
      WHILE EXISTS (SELECT 1 FROM tTabelaComTexto WHERE Coluna01 IS NOT NULL) DO
      
         #00100120240000000001|12315|40|L1654XR12|2024-04-10|2028-04-10
         SELECT Coluna01, Coluna02, Coluna03, Coluna04, Coluna05, Coluna06
         INTO xSTRGEM, xIdPallet, xQtde, xNumLote, xDataFabr, xDataValid
         FROM tTabelaComTexto WHERE Coluna01 IS NOT NULL
         LIMIT 1;
                 
         SET xCodEmpWMS	= SUBSTRING(xSTRGEM,01,03);
         SET xCodFilWMS	= SUBSTRING(xSTRGEM,04,03);
         SET xAnoSolic 	= SUBSTRING(xSTRGEM,07,04);
         SET xNumSolic 	= SUBSTRING(xSTRGEM,11,10);             
         
         SET xNumUA = NULL;

         SELECT tbsolic_entradas_acons.num_lote, tbsolic_entradas_item.cod_produto, tbsolic_entradas_item.fator_conv
         INTO xNumUA, xCodProduto, xFatorConv
         FROM of_logistica.tbsolic_entradas_acons
         INNER JOIN of_logistica.tbsolic_entradas_item ON 
                    tbsolic_entradas_item.cod_emp   = tbsolic_entradas_acons.cod_emp
                AND tbsolic_entradas_item.cod_fil   = tbsolic_entradas_acons.cod_fil
                AND tbsolic_entradas_item.ano_solic = tbsolic_entradas_acons.ano_solic
                AND tbsolic_entradas_item.num_solic = tbsolic_entradas_acons.num_solic
                AND tbsolic_entradas_item.num_item  = tbsolic_entradas_acons.num_item
         WHERE tbsolic_entradas_acons.cod_emp   = xCodEmpWMS
           AND tbsolic_entradas_acons.cod_fil   = xCodFilWMS
           AND tbsolic_entradas_acons.ano_solic = xAnoSolic
           AND tbsolic_entradas_acons.num_solic = xNumSolic
           AND tbsolic_entradas_acons.qtde_est3 IS NULL
         LIMIT 1;         
         SET xNumCaixaBarcode = CONCAT(xCodProduto,'.',xIdPallet);
         
         IF xNumUA IS NULL THEN
            
            SELECT tbsolic_entradas_item.cod_produto, tbsolic_entradas_item.fator_conv
            INTO xCodProduto, xFatorConv
            FROM of_logistica.tbsolic_entradas_acons
            INNER JOIN of_logistica.tbsolic_entradas_item ON 
                       tbsolic_entradas_item.cod_emp   = tbsolic_entradas_acons.cod_emp
                   AND tbsolic_entradas_item.cod_fil   = tbsolic_entradas_acons.cod_fil
                   AND tbsolic_entradas_item.ano_solic = tbsolic_entradas_acons.ano_solic
                   AND tbsolic_entradas_item.num_solic = tbsolic_entradas_acons.num_solic
                   AND tbsolic_entradas_item.num_item  = tbsolic_entradas_acons.num_item
            WHERE tbsolic_entradas_acons.cod_emp   = xCodEmpWMS
              AND tbsolic_entradas_acons.cod_fil   = xCodFilWMS
              AND tbsolic_entradas_acons.ano_solic = xAnoSolic
              AND tbsolic_entradas_acons.num_solic = xNumSolic
            LIMIT 1;
            SET xNumCaixaBarcode = CONCAT(xCodProduto,'.',xIdPallet);
            

            SELECT IFNULL(MAX(num_lote)+1,0) INTO xNumUA FROM of_logistica.tbwms_estoque
            WHERE tbwms_estoque.cod_emp   = xCodEmpWMS
              AND tbwms_estoque.cod_fil   = xCodFilWMS;
                 
            INSERT INTO of_logistica.tbsolic_entradas_acons (
               cod_emp, cod_fil, ano_solic, num_solic, num_item, num_lote, sequencia_lote, 
               num_lote_cli, num_caixa, num_caixa_barcode, data_fabr, data_valid, dthr_conf,
               qtde_est, qtde_vol, qtde_frac, qtde_est2, qtde_vol2, qtde_frac2, qtde_est3, qtde_vol3, qtde_frac3
            ) VALUES (
               xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, '000001', LPAD(xNumUA,10,'0') , 1, 
               xNumLote,xIdPallet, xNumCaixaBarcode, xDataFabr, xDataValid, NOW(), 
               xQtde, xQtde/xFatorConv, xQtde, 
               xQtde, xQtde/xFatorConv, xQtde, 
               xQtde, xQtde/xFatorConv, xQtde);
               

            INSERT INTO of_logistica.tbwms_estoque (
               cod_emp, cod_fil, ano_solic, num_solic, num_item, num_lote, sequencia_lote, 
               num_lote_cli, num_caixa, num_caixa_barcode, data_fabr, data_valid, 
               qtde_est, qtde_vol, qtde_frac, qtde_est2, qtde_vol2, qtde_frac2, qtde_est3, qtde_vol3, qtde_frac3
            ) VALUES (
               xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, '000001', LPAD(xNumUA,10,'0') , 1, 
               xNumLote,xIdPallet, xNumCaixaBarcode, xDataFabr, xDataValid,  
               xQtde, xQtde/xFatorConv, xQtde, 
               xQtde, xQtde/xFatorConv, xQtde, 
               xQtde, xQtde/xFatorConv, xQtde);
                              
         ELSE
         
            UPDATE of_logistica.tbsolic_entradas_acons
            SET num_lote_cli = xNumLote,
                num_caixa = xIdPallet,
                num_caixa_barcode = xNumCaixaBarcode,
                data_fabr = xDataFabr,
                data_valid = xDataValid,
                dthr_conf = NOW(),
                qtde_est = xQtde, qtde_vol = xQtde/xFatorConv, qtde_frac = xQtde,
                qtde_est2 = xQtde, qtde_vol2 = xQtde/xFatorConv, qtde_frac2 = xQtde,
                qtde_est3 = xQtde, qtde_vol3 = xQtde/xFatorConv, qtde_frac3 = xQtde
            WHERE tbsolic_entradas_acons.cod_emp   = xCodEmpWMS
              AND tbsolic_entradas_acons.cod_fil   = xCodFilWMS
              AND tbsolic_entradas_acons.num_lote  = xNumUA
              AND tbsolic_entradas_acons.sequencia_lote = 1;
              
            UPDATE of_logistica.tbwms_estoque
            SET num_lote_cli = xNumLote,
                num_caixa = xIdPallet,
                num_caixa_barcode = xNumCaixaBarcode,
                data_fabr = xDataFabr,
                data_valid = xDataValid,
                dthr_conf = NOW(),
                qtde_est = xQtde, qtde_vol = xQtde/xFatorConv, qtde_frac = xQtde,
                qtde_est2 = xQtde, qtde_vol2 = xQtde/xFatorConv, qtde_frac2 = xQtde,
                qtde_est3 = xQtde, qtde_vol3 = xQtde/xFatorConv, qtde_frac3 = xQtde
            WHERE tbwms_estoque.cod_emp   = xCodEmpWMS
              AND tbwms_estoque.cod_fil   = xCodFilWMS
              AND tbwms_estoque.num_lote  = xNumUA
              AND tbwms_estoque.sequencia_lote = 1;
              
         END IF;
         #select xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xNumLote, xIdPallet, xQtde, xDataFabr, xDataValid, NOW();
         
         UPDATE tTabelaComTexto
         SET Coluna01 = NULL
         WHERE Coluna02 = xIdPallet;
      
      END WHILE; 
      COMMIT;    
   
   END IF;
    
    
   /*******************************************************************
   # Selecionar as informações da GSM
   *******************************************************************/
   # Retorno com 3 RecordSets
   IF oTiporetorno IN (0,10) THEN
      # INFORMAÇÕES DO TOPO DA GSM
      SELECT tTabelaComTexto.Coluna05 AS DocEntry, tTabelaComTexto.Coluna06 AS Doctipo, tbintegraSAP_Doc.DocNum,
             tbintegraSAP_Doc.TipoProducao, 
             #tbintegraSAP_Doc.DocEntry, tbintegraSAP_Doc.DocTipo,
            topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
            topo.data_solic, topo.dthr_acons, topo.num_nf AS num_pedido,
            topo.observ_solic, topo.observ_conf01, topo.status_processo, 
            of_logistica.fnStatusSaidaWms(topo.status_processo) status_processoAux,
            #Liberação Inicio Processo de Separação, Picking
            topo.dthr_endereco, topo.dthr_confer, topo.dthr_confirm,
            #Inicio Processo de Separação, Picking
            topo.dthr_chegada, topo.final_descarga,
            IFNULL(tbintegraSAP_Doc.TaxDate, tbintegraSAP_Doc.DocDate) TaxDate, tbintegraSAP_Doc.Observacoes Comments
            ,topo.chave_integracao
            ,RESULTADO, MENSAGEM
      FROM of_logistica.tbsolic_entradas topo
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
            ite.num_nf_vda AS num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
            ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
            #
            ite.qtde_est, ite.qtde_vol, ite.qtde_frac, ite.pliq_item,		#Qtde Pedido
            ite.real_est, ite.real_vol, ite.real_frac, ite.real_peso,		#Qtde Aconselhada
            ite.real_est2, ite.real_vol2, ite.real_frac2, ite.real_peso2,	#Qtde Conferencia
            ite.real_est3, ite.real_vol3, ite.real_frac3, ite.real_peso3,	#Qtde Conferencia / ???
            #			
            ite.dthr_conf_ini, ite.dthr_conf_fin,
            tbintegraSAP_DocItem.LineNum, tbintegraSAP_DocItem.WhareHouse, tbintegraSAP_DocItem.NumInBuy
            ,tbintegraSAP_DocItem.ManBtchNum
            ,topo.chave_integracao
            ,prod.flg_obriga_lote_fornecedor
            ,RESULTADO, MENSAGEM
      FROM of_logistica.tbsolic_entradas topo
      INNER JOIN tTabelaComTexto ON
                tTabelaComTexto.Coluna01 = topo.cod_emp
            AND tTabelaComTexto.Coluna02 = topo.cod_fil
            AND tTabelaComTexto.Coluna03 = topo.ano_solic
            AND tTabelaComTexto.Coluna04 = topo.num_solic
      LEFT JOIN of_logistica.tbsolic_entradas_item ite ON
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
            ite.num_nf_vda AS num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
            ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
            #
            CONCAT(acons.num_lote,acons.sequencia_lote) AS NumUA,
            tbwms_estoque.num_lote_cli,
            acons.qtde_est, acons.qtde_vol, acons.qtde_frac, acons.qtde_peso,		#Qtde Aconselhada
            acons.qtde_est2, acons.qtde_vol2, acons.qtde_frac2, acons.qtde_peso2,	#Qtde Separada
            acons.qtde_est3, acons.qtde_vol3, acons.qtde_frac3, acons.qtde_peso3,	#(*) Qtde Conferencia/???
            #		
            acons.dthr_conf, acons.dthr_armaz,
            of_logistica.fnLocalizCompleta2(acons.cod_und, acons.cod_armazem, acons.camara, acons.rua, 
                                         acons.posicao, acons.altura, acons.profund, NULL, "Sem endereco") AS BinCode
            ,topo.chave_integracao
            ,RESULTADO, MENSAGEM
      FROM of_logistica.tbsolic_entradas topo
      LEFT JOIN of_logistica.tbsolic_entradas_item ite ON
                ite.cod_emp   = topo.cod_emp
            AND ite.cod_fil   = topo.cod_fil
            AND ite.ano_solic = topo.ano_solic
            AND ite.num_solic = topo.num_solic			
      LEFT JOIN of_logistica.tbprodutos prod ON
                prod.cnpj_cpf    = ite.cnpj_cpf_dep
            AND prod.cod_produto = ite.cod_produto
      LEFT JOIN of_logistica.tbsolic_entradas_acons acons ON
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
   ELSEIF oTiporetorno = 1 THEN
   
      # Retorno com 2 RecordSets
      # INFORMAÇÕES DO TOPO DA GSM
      SELECT tTabelaComTexto.Coluna05 AS DocEntry, tTabelaComTexto.Coluna06 AS Doctipo, 
            tbintegraSAP_Doc.TipoProducao, 
            topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
            topo.data_solic, topo.dthr_acons, topo.num_nf AS num_pedido,
            topo.observ_solic, topo.observ_conf01, topo.status_processo, 
            of_logistica.fnStatusSaidaWms(topo.status_processo) status_processoAux,
            #Liberação Inicio Processo de Separação, Picking
            topo.dthr_endereco, topo.dthr_confer, topo.dthr_confirm,
            #Inicio Processo de Separação, Picking
            topo.dthr_chegada, topo.final_descarga,
      # INFORMAÇÕES INTEGRAÇÃO
            tbintegraSAP_Doc.DocNum,
            tbintegraSAP_Doc.DocDate,
            tbintegraSAP_Doc.CardCode, tbintegraSAP_Doc.CardName, tbintegraSAP_DocItem.LineNum,
            #tbintegraSAP_Doc.ItemCode, 
            tbintegraSAP_DocItem.ItemCode, 
            tbintegraSAP_DocItem.WhareHouse,
            tbintegraSAP_Doc.Observacoes,
            "0" SERIAL,
            tbintegraSAP_Doc.StreetS,
            tbintegraSAP_Doc.AddrTypeS,
            tbintegraSAP_Doc.StreetNoS,
            tbintegraSAP_Doc.BlockS,
            tbintegraSAP_Doc.BuildingS,
            tbintegraSAP_Doc.CityS,
            tbintegraSAP_Doc.ZipCodeS,
            tbintegraSAP_Doc.StateS,
            tbintegraSAP_Doc.CountryS,
            "Employee" Employee,
      # INFORMAÇÕES DOS ITENS DA GSM
            ite.num_nf_vda AS num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
            ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
            #
            ite.qtde_est, ite.qtde_vol, ite.qtde_frac, ite.pliq_item,		#Qtde Pedido
            ite.real_est, ite.real_vol, ite.real_frac, ite.real_peso,		#Qtde Aconselhada
            ite.real_est2, ite.real_vol2, ite.real_frac2, ite.real_peso2,	#Qtde Conferencia
            ite.real_est3, ite.real_vol3, ite.real_frac3, ite.real_peso3,	#Qtde Conferencia / ???
            #			
            ite.dthr_conf_ini, ite.dthr_conf_fin
            ,topo.chave_integracao
            ,prod.flg_obriga_lote_fornecedor
            ,RESULTADO, MENSAGEM
      FROM of_logistica.tbsolic_entradas topo
      INNER JOIN tTabelaComTexto ON
                tTabelaComTexto.Coluna01 = topo.cod_emp
            AND tTabelaComTexto.Coluna02 = topo.cod_fil
            AND tTabelaComTexto.Coluna03 = topo.ano_solic
            AND tTabelaComTexto.Coluna04 = topo.num_solic
      LEFT JOIN tbintegraSAP_Doc ON 
               tbintegraSAP_Doc.cod_emp   = topo.cod_emp
           AND tbintegraSAP_Doc.cod_fil   = topo.cod_fil
           AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
           AND tbintegraSAP_Doc.num_solic = topo.num_solic
           AND tbintegraSAP_Doc.TipoDocSLIN = 'E'
      LEFT JOIN of_logistica.tbsolic_entradas_item ite ON
                ite.cod_emp = topo.cod_emp
            AND ite.cod_fil = topo.cod_fil
            AND ite.ano_solic = topo.ano_solic
            AND ite.num_solic = topo.num_solic
      INNER JOIN tbintegraSAP_DocItem ON 
                tbintegraSAP_DocItem.cod_emp   = ite.cod_emp
            AND tbintegraSAP_DocItem.cod_fil   = ite.cod_fil
            AND tbintegraSAP_DocItem.ano_solic = ite.ano_solic
            AND tbintegraSAP_DocItem.num_solic = ite.num_solic
            AND tbintegraSAP_DocItem.num_item  = ite.num_item
            AND tbintegraSAP_DocItem.DocTipo   =  tbintegraSAP_Doc.DocTipo
      LEFT JOIN of_logistica.tbprodutos prod ON
                prod.cnpj_cpf = ite.cnpj_cpf_dep
            AND prod.cod_produto = ite.cod_produto;
            
      # INFORMAÇÕES DAS UA´S DA GSM
      SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
            ite.num_nf_vda AS num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
            ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
            #
            CONCAT(acons.num_lote,acons.sequencia_lote) AS NumUA,
            tbwms_estoque.num_lote_cli,
            acons.qtde_est, acons.qtde_vol, acons.qtde_frac, acons.qtde_peso,		#Qtde Aconselhada
            acons.qtde_est2, acons.qtde_vol2, acons.qtde_frac2, acons.qtde_peso2,	#Qtde Separada
            acons.qtde_est3, acons.qtde_vol3, acons.qtde_frac3, acons.qtde_peso3,	#(*) Qtde Conferencia/???
            #		
            acons.dthr_conf, acons.dthr_armaz,
            of_logistica.fnLocalizCompleta2(acons.cod_und, acons.cod_armazem, acons.camara, acons.rua, 
                                         acons.posicao, acons.altura, acons.profund, NULL, "Sem endereco") AS BinCode
            ,topo.chave_integracao
            ,RESULTADO, MENSAGEM
      FROM of_logistica.tbsolic_entradas topo
      LEFT JOIN of_logistica.tbsolic_entradas_item ite ON
                ite.cod_emp   = topo.cod_emp
            AND ite.cod_fil   = topo.cod_fil
            AND ite.ano_solic = topo.ano_solic
            AND ite.num_solic = topo.num_solic			
      LEFT JOIN of_logistica.tbprodutos prod ON
                prod.cnpj_cpf    = ite.cnpj_cpf_dep
            AND prod.cod_produto = ite.cod_produto
      LEFT JOIN of_logistica.tbsolic_entradas_acons acons ON
                acons.cod_emp   = ite.cod_emp
            AND acons.cod_fil   = ite.cod_fil
            AND acons.ano_solic = ite.ano_solic
            AND acons.num_solic = ite.num_solic			
            AND acons.num_item  = ite.num_item
      LEFT JOIN of_logistica.tbwms_estoque ON  
                tbwms_estoque.cod_emp        = acons.cod_emp
            AND tbwms_estoque.cod_fil        = acons.cod_fil
            AND tbwms_estoque.num_lote       = acons.num_lote
            AND tbwms_estoque.sequencia_lote = acons.sequencia_lote
      INNER JOIN tTabelaComTexto ON
            tTabelaComTexto.Coluna01 = topo.cod_emp
            AND tTabelaComTexto.Coluna02 = topo.cod_fil
            AND tTabelaComTexto.Coluna03 = topo.ano_solic
            AND tTabelaComTexto.Coluna04 = topo.num_solic;            
            
   END IF; 
   
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

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_RetornoSaida.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_RetornoSaida`$$

CREATE PROCEDURE `PROC_INTEGRA_RetornoSaida`(
   IN oCodUsuario				VARCHAR(10),
   IN oIdRetorno				 VARCHAR(20)
   #IN oTipoConsulta			INT     #0 = Apenas o Topo, 1 = Detalhe por ITEM, 2 = Detalhe por UA
   # Parametros de Retorno
   #OUT RESULTADO             	INT,
   #OUT MENSAGEM              	VARCHAR(500)
)
BLOCO1:BEGIN
   DECLARE xCodEmpWMS			     VARCHAR(03)	DEFAULT '001';
   DECLARE xCodFilWMS			     VARCHAR(03) DEFAULT '001';
   DECLARE xNumSolic 			     VARCHAR(10);
   DECLARE xAnoSolic 			     VARCHAR(04)	DEFAULT YEAR(CURRENT_DATE());
   DECLARE xDocEntry         INT;
   DECLARE xDocTipo          VARCHAR(10);   
   DECLARE xTipoOperSaida 		 VARCHAR(03) DEFAULT '002';
   DECLARE xCodUnidade			    VARCHAR(03) DEFAULT '001';
   DECLARE xCodArmazem			    VARCHAR(02) DEFAULT '01';
   DECLARE xStatusProcesso		 VARCHAR(02) DEFAULT '01';
   DECLARE xCodErro	         INT DEFAULT 0;
   DECLARE excecao 	         INT DEFAULT 0;
   DECLARE RESULTADO         INT DEFAULT 1;
   DECLARE MENSAGEM          VARCHAR(500);
   DECLARE xSTRGEM           TEXT;
   DECLARE xNumProcesso      VARCHAR(20);  
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
    
   #Cria tabela temporária com as GSM que estão liberadas para retorno à integração
   DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_SAIDAS;
   IF IFNULL(oIdRetorno,'') = '' THEN
   
      CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_SAIDAS AS 
         SELECT DocEntry, DocTipo, DocNum, tbSaidas.num_nf, tbSaidas.data_nf, tbSaidas.data_solic
               ,CONCAT(tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic) NumProcesso
               ,tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic
               ,tbSaidas.status_processo, tbSaidas.observ_solic 
               #,CONCAT('CALL PROC_INTEGRA_RetornoSaida("999999","',CONCAT(tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic),'");') _call
         FROM tbintegraSAP_Doc
         INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
               tbSaidas.cod_emp   = tbintegraSAP_Doc.cod_emp
           AND tbSaidas.cod_fil   = tbintegraSAP_Doc.cod_fil
           AND tbSaidas.ano_solic = tbintegraSAP_Doc.ano_solic
           AND tbSaidas.num_solic = tbintegraSAP_Doc.num_solic
           AND tbSaidas.status_processo >= 8
           AND tbintegraSAP_Doc.StatusDoc = 3
         WHERE tbintegraSAP_Doc.TipoDocSLIN = 'S';
   ELSE
   
      SET xCodEmpWMS	= SUBSTRING(oIdRetorno,01,03);
      SET xCodFilWMS	= SUBSTRING(oIdRetorno,04,03);
      SET xAnoSolic 	= SUBSTRING(oIdRetorno,07,04);
      SET xNumSolic 	= SUBSTRING(oIdRetorno,11,10);    
      SET xSTRGEM = CONCAT(xCodEmpWMS, "|", xCodFilWMS, "|", xAnoSolic, "|", xNumSolic, "|");
      #select xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic;
      /*******************************************************************
      # Validar a existencia da GSM
      *******************************************************************/
      IF NOT EXISTS (SELECT 1 FROM of_logistica.tbsolic_saidas 
                     WHERE cod_emp = xCodEmpWMS
                     AND cod_fil = xCodFilWMS
                     AND ano_solic = xAnoSolic
                     AND num_solic = xNumSolic) THEN
         SET xCodErro = 1;
         SET RESULTADO = 0;
         SET MENSAGEM  = 'GSM não localizada';
         SELECT RESULTADO, MENSAGEM;
         LEAVE BLOCO1;
      END IF;
      CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_SAIDAS AS 
         SELECT DocEntry, DocTipo, DocNum, tbSaidas.num_nf, tbSaidas.data_nf, tbSaidas.data_solic
               ,CONCAT(tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic) NumProcesso
               ,tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic
               ,tbSaidas.status_processo, tbSaidas.observ_solic 
               #,CONCAT('CALL PROC_INTEGRA_RetornoSaida("999999","',CONCAT(tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic),'");') _call
         FROM tbintegraSAP_Doc
         INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
               tbSaidas.cod_emp   = tbintegraSAP_Doc.cod_emp
           AND tbSaidas.cod_fil   = tbintegraSAP_Doc.cod_fil
           AND tbSaidas.ano_solic = tbintegraSAP_Doc.ano_solic
           AND tbSaidas.num_solic = tbintegraSAP_Doc.num_solic
           AND tbSaidas.status_processo >= 8
           AND tbintegraSAP_Doc.StatusDoc = 3
         WHERE tbintegraSAP_Doc.cod_emp   = xCodEmpWMS 
           AND tbintegraSAP_Doc.cod_fil   = xCodFilWMS
           AND tbintegraSAP_Doc.ano_solic = xAnoSolic
           AND tbintegraSAP_Doc.num_solic = xNumSolic
           AND tbintegraSAP_Doc.TipoDocSLIN = 'S';
   END IF;
   #Alimenta variavel xSTRGEM com a lista das GSM´s selecionadas
   SET xSTRGEM = '';  
   WHILE EXISTS (SELECT 1 FROM tbTMP_INTEGRA_RETORNO_SAIDAS) DO
      SELECT NumProcesso, cod_emp, cod_fil, ano_solic, num_solic, DocEntry, Doctipo
      INTO xNumProcesso, xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xDocEntry, xDoctipo
      FROM tbTMP_INTEGRA_RETORNO_SAIDAS LIMIT 1;         
      
      SET xSTRGEM = CONCAT(xSTRGEM, CONCAT(xCodEmpWMS, "|", xCodFilWMS, "|", xAnoSolic, "|", xNumSolic, "|", xDocEntry, "|"), xDocTipo, "|");
      DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS WHERE NumProcesso = xNumProcesso;
   END WHILE;
   DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_SAIDAS;
   #Cria tabela temporária auxiliar para inner join com a tbsolic_entradas para gerar seleção das informações
   #da GEM informada no parametro
   CALL PROC_SYS_GerarTabelaComTexto(xSTRGEM,'|',6);        
   
    
   /*******************************************************************
   # Selecionar as informações da GSM
   *******************************************************************/
   # INFORMAÇÕES DO TOPO DA GSM
   SELECT tTabelaComTexto.Coluna05 AS DocEntry, tTabelaComTexto.Coluna06 AS Doctipo, 
         topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
         topo.data_solic, topo.data_saida, topo.dthr_acons, topo.num_nf AS num_pedido,
         topo.observ_solic, topo.observ_conf01, topo.status_processo, 
         of_logistica.fnStatusSaidaWms(topo.status_processo) status_processoAux,
         #Liberação Inicio Processo de Separação, Picking
         topo.dthr_armazem, topo.dthr_armazem_picking, topo.dthr_confer, topo.dthr_confirm,
         #Inicio Processo de Separação, Picking
         topo.dthr_inicio_geral, topo.dthr_inicio_picking, topo.dthr_inicio_carregamento
         ,topo.chave_integracao
         ,RESULTADO, MENSAGEM
   FROM of_logistica.tbsolic_saidas topo
   INNER JOIN tTabelaComTexto ON
         tTabelaComTexto.Coluna01 = topo.cod_emp
         AND tTabelaComTexto.Coluna02 = topo.cod_fil
         AND tTabelaComTexto.Coluna03 = topo.ano_solic
         AND tTabelaComTexto.Coluna04 = topo.num_solic;
         
   # INFORMAÇÕES DOS ITENS DA GSM
   SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
         ite.num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
         ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
         #
         ite.local_geral, ite.local_picking,
         ite.qtde_est, ite.qtde_vol, ite.qtde_frac, ite.pliq_item,		#Qtde Pedido
         ite.real_est, ite.real_vol, ite.real_frac, ite.real_peso,		#Qtde Aconselhada
         ite.real_est2, ite.real_vol2, ite.real_frac2, ite.real_peso2,	#Qtde Separação
         ite.real_est3, ite.real_vol3, ite.real_frac3, ite.real_peso3,	#Qtde Conferencia / Picking
         ite.real_est4, ite.real_vol4, ite.real_frac4, ite.real_peso4,	#Qtde Carregamento
         ite.real_est5, ite.real_vol5, ite.real_frac5, ite.real_peso5,	#Qtde check-carregamento
         #			
         ite.dthr_aconselhamento, ite.dthr_retorno_wms,
         ite.dthr_inicio_baixa_geral, ite.dthr_inicio_picking_carga, ite.dthr_inicio_carregamento,
         ite.dthr_final_baixa_geral, ite.dthr_final_picking_carga, ite.dthr_final_carregamento				
         ,topo.chave_integracao
         ,RESULTADO, MENSAGEM
   FROM of_logistica.tbsolic_saidas topo
   LEFT JOIN of_logistica.tbsolic_saidas_item ite ON
         ite.cod_emp = topo.cod_emp
         AND ite.cod_fil = topo.cod_fil
         AND ite.ano_solic = topo.ano_solic
         AND ite.num_solic = topo.num_solic
   LEFT JOIN of_logistica.tbprodutos prod ON
         prod.cnpj_cpf = ite.cnpj_cpf_dep
         AND prod.cod_produto = ite.cod_produto
   INNER JOIN tTabelaComTexto ON
             tTabelaComTexto.Coluna01 = topo.cod_emp
         AND tTabelaComTexto.Coluna02 = topo.cod_fil
         AND tTabelaComTexto.Coluna03 = topo.ano_solic
         AND tTabelaComTexto.Coluna04 = topo.num_solic;
    
   # INFORMAÇÕES DAS UA´S DA GSM
   # Checa se envia Lotes da UA ou da tbsolic_saidas_item_loteAux
   # @Reviser David Ruy <2020-11-18>
   IF TRUE THEN
      SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
         ite.num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
         ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
         #
         CONCAT(acons.num_lote,acons.sequencia_lote) AS NumUA,
         IFNULL(tbLoteAux.num_lote, tbwms_estoque.num_lote_cli) num_lote_cli,
         SUM(acons.qtde_est) qtde_est, SUM(acons.qtde_vol) qtde_vol, SUM(acons.qtde_frac) qtde_frac, SUM(acons.qtde_peso) qtde_peso,		#Qtde Aconselhada
         IF(tbLoteAux.num_lote IS NULL, SUM(acons.qtde_est2), tbLoteAux.qtde_est) qtde_est2, 
         IF(tbLoteAux.num_lote IS NULL, SUM(acons.qtde_vol2), tbLoteAux.qtde_vol) qtde_vol2, 
         IF(tbLoteAux.num_lote IS NULL, SUM(acons.qtde_frac2), tbLoteAux.qtde_frac) qtde_frac2, 
         IF(tbLoteAux.num_lote IS NULL, SUM(acons.qtde_peso2), tbLoteAux.qtde_peso) qtde_peso2,	#Qtde Separada
         SUM(acons.qtde_est3) qtde_est3, SUM(acons.qtde_vol3) qtde_vol3, SUM(acons.qtde_frac3) qtde_frac3, SUM(acons.qtde_peso3) qtde_peso3,	#(*) Qtde Conferencia/Picking Carga
         #		
         acons.dthr_conf, acons.dthr_conf_picking, acons.dthr_carregamento
         ,topo.chave_integracao
         ,RESULTADO, MENSAGEM
      FROM of_logistica.tbsolic_saidas topo
      LEFT JOIN of_logistica.tbsolic_saidas_item ite ON
            ite.cod_emp = topo.cod_emp
            AND ite.cod_fil = topo.cod_fil
            AND ite.ano_solic = topo.ano_solic
            AND ite.num_solic = topo.num_solic			
      LEFT JOIN of_logistica.tbprodutos prod ON
            prod.cnpj_cpf = ite.cnpj_cpf_dep
            AND prod.cod_produto = ite.cod_produto
      LEFT JOIN of_logistica.tbsolic_saidas_acons acons ON
            acons.cod_emp = ite.cod_emp
            AND acons.cod_fil = ite.cod_fil
            AND acons.ano_solic = ite.ano_solic
            AND acons.num_solic = ite.num_solic			
            AND acons.num_item  = ite.num_item
      LEFT JOIN of_logistica.tbwms_estoque ON  
            tbwms_estoque.cod_emp = acons.cod_emp
            AND tbwms_estoque.cod_fil = acons.cod_fil
            AND tbwms_estoque.num_lote = acons.num_lote
            AND tbwms_estoque.sequencia_lote = acons.sequencia_lote
      LEFT JOIN of_logistica.tbsolic_saidas_item_loteAux tbLoteAux ON
                 tbLoteAux.cod_emp   = acons.cod_emp
             AND tbLoteAux.cod_fil   = acons.cod_fil
             AND tbLoteAux.ano_solic = acons.ano_solic
             AND tbLoteAux.num_solic = acons.num_solic
             AND tbLoteAux.num_item  = acons.num_item
      INNER JOIN tTabelaComTexto ON
            tTabelaComTexto.Coluna01 = topo.cod_emp
            AND tTabelaComTexto.Coluna02 = topo.cod_fil
            AND tTabelaComTexto.Coluna03 = topo.ano_solic
            AND tTabelaComTexto.Coluna04 = topo.num_solic
      GROUP BY cod_emp, cod_fil, ano_solic, num_solic, num_ped_cli, num_item, num_lote_cli;
   ELSE   
      #Rotina desativada em 18/11/2020
      SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
         ite.num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
         ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
         #
         CONCAT(acons.num_lote,acons.sequencia_lote) AS NumUA,
         tbwms_estoque.num_lote_cli,
         acons.qtde_est, acons.qtde_vol, acons.qtde_frac, acons.qtde_peso,		#Qtde Aconselhada
         acons.qtde_est2, acons.qtde_vol2, acons.qtde_frac2, acons.qtde_peso2,	#Qtde Separada
         acons.qtde_est3, acons.qtde_vol3, acons.qtde_frac3, acons.qtde_peso3,	#(*) Qtde Conferencia/Picking Carga
         #		
         acons.dthr_conf, acons.dthr_conf_picking, acons.dthr_carregamento
         ,topo.chave_integracao
         ,RESULTADO, MENSAGEM
      FROM of_logistica.tbsolic_saidas topo
      LEFT JOIN of_logistica.tbsolic_saidas_item ite ON
            ite.cod_emp = topo.cod_emp
            AND ite.cod_fil = topo.cod_fil
            AND ite.ano_solic = topo.ano_solic
            AND ite.num_solic = topo.num_solic			
      LEFT JOIN of_logistica.tbprodutos prod ON
            prod.cnpj_cpf = ite.cnpj_cpf_dep
            AND prod.cod_produto = ite.cod_produto
      LEFT JOIN of_logistica.tbsolic_saidas_acons acons ON
            acons.cod_emp = ite.cod_emp
            AND acons.cod_fil = ite.cod_fil
            AND acons.ano_solic = ite.ano_solic
            AND acons.num_solic = ite.num_solic			
            AND acons.num_item  = ite.num_item
      LEFT JOIN of_logistica.tbwms_estoque ON  
            tbwms_estoque.cod_emp = acons.cod_emp
            AND tbwms_estoque.cod_fil = acons.cod_fil
            AND tbwms_estoque.num_lote = acons.num_lote
            AND tbwms_estoque.sequencia_lote = acons.sequencia_lote
      INNER JOIN tTabelaComTexto ON
            tTabelaComTexto.Coluna01 = topo.cod_emp
            AND tTabelaComTexto.Coluna02 = topo.cod_fil
            AND tTabelaComTexto.Coluna03 = topo.ano_solic
            AND tTabelaComTexto.Coluna04 = topo.num_solic;
   END IF;
    
   DROP TEMPORARY TABLE IF EXISTS tTabelaComTexto;
    
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      SELECT RESULTADO, MENSAGEM;
   ELSE    
      SET RESULTADO = 1;
      #SET MENSAGEM  = 'Processo Realizado com sucesso!';
   END IF;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_RetornoSaidaPicking.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_RetornoSaidaPicking`$$

CREATE PROCEDURE `PROC_INTEGRA_RetornoSaidaPicking`(
   IN oCodUsuario				VARCHAR(10),
   IN oIdRetorno				 VARCHAR(20),
   IN oTipoRetorno   INT     #0 = Criação de Picking no SAP (Criar Lista de Separação) 
   #                          2 = Criação de Picking no SAP (Criar Lista de Separação)  - Alterações  [desabilitado]
   #                          1 = Confirmação de Picking (Separação Confirmada)
   #                          3 = Confirmação de Picking (Transferencia)
   #                          4 = Confirmação Transferencia
   #                          5 = Confirmação Devolução Compras
)
BLOCO1:BEGIN
   /*******************************************************************************************
   #@Author David Ruy 
   #
   #@Reviser David Ruy <2019/12/11> Considerar apenas GMS´ com dthr_final_picking (Checkout concluído) Quando flg_conferencia_volume_check_tp=1
   #@Reviser David Ruy <2020/02/11> Regra para não considerar pedido com data de entrega no passado              
   #@Reviser David Ruy <2021/01/04> Regra para considerar flag flg_conferencia_volume_check_tp (checkout automático)
   #@Reviser David Ruy <2021/01/27> Flags para regras de retorno Checkout e Roteirização / Variáveis Limit e Ordem da Lista
   #@Reviser David Ruy <2021/01/28> Inclusão campos Transportadora / Rota / Janelas de Entrega
   #@Reviser David Ruy <2021/08/05> condição para não listar GSM´ canceladas / Incluído campo idPickingAnt
   #@Reviser David Ruy <2021/08/30> Campos WhareHouse e WhareHouseTransf (TD-S)
   #@Reviser David Ruy <2021/12/24> Campos ManBtchNum, ManSerNum
   #@Reviser David Ruy <2022/01/28> Tratativa campo U_RSD_RplOrder (não gera picking para PV com o campo preenchido)   
   #@Reviser David Ruy <2022-03-21> Retornar apenas as linhas que foram geradas no picking (tbintegraSAP_DocPicking)   
   #@Reviser David Ruy <2022-03-29> AND (tbintegraSAP_Doc.StatusDoc <= 3 OR tbintegraSAP_Doc.StatusDoc = 7) na condição para gerar picking
   #@Reviser David Ruy <2022-04-06> #Não retornar Quando houver divergencia entre itens ou quantidades do SLIN X Integração
   #@Reviser David Ruy <2022-04-20> #Ajuste para não gerar NADA se tiver bloqueado no SLIN
   #@Reviser David Ruy <2022-11-01> #confirmação de PV => Considerar apenas com Uitilização parametrizada
   #@Reviser David Ruy <2023-03-01> Alteração agrupamento linhas TD-S conforme flg_agrupa_transf
   #@Reviser David Ruy <2023/03/06> FatorAgrup e xflg_agrupa_transf para utilização Qtdes Agrupadas TD-S (Elinox)
   #@Reviser David Ruy <2023/04/24> Ajuste OP/TD-S X Não precisa Efetuar Checkout
   #@Reviser David Ruy <2023/04/25> Ajuste oTipoRetorno = 4 (Criar Documento Recebimento)
   #@Reviser David Ruy <2023/05/22> Ajuste Não Gerar retorno de Materiais de Uso/consumo (OONE_USO_CONS)
   #@Reviser David Ruy <2023/07/11> Ajuste xParamDiasEntrega : Só seleciona PV´ com data de entrega até X dias
                                    Ajusta para confirmação de PK até 30 dias passados da data PV
   #@Reviser David Ruy <2023/08/02> Ajuste xcampo_qtde_volumes (tbintegraSAP_Parametros.flg_campo_volumes => 0=CHECKOUT / 1=EMB_VOL / 2=STRING_CHECKOUT)
   #@Reviser David Ruy <2023/09/15> Novos campos qtde_volume_checkout -> QtdeVolManual, 
                                                 peso_liq_checkout -> PesoLiqManual,
                                                 peso_brt_checkout -> PesoBrtManual 
   #@Reviser David Ruy <2023-09-15> Regra Cromo, Não retornar se não tiver preenchido Qtde e Peso Checkout manual
   #@Reviser David Ruy <2023-10-11> <2025-12-23> tbintegraSAP_Doc.StatusEnum = 0 (em aberto para gerar Transferencia) / 1=Processado (Transferencia já gerada)
   #@Reviser David Ruy <2024-01-24> Regra BRW, [xcampo_qtde_volumes=3] Não retornar se não tiver preenchido Qtde e Peso Checkout manual e se checkout não concluído 
   #                                      conforme condição tbsolic_saidas_item.real_est2 = sum(ifnull(tbsolic_saidas_volume_item.qtde_sep_est, 0))
   #@Reviser David Ruy <2024-10-01> Ajuste, Condição para TD-S ao criar tbSaidas quando oTipoRetorno in (1,2,3,4)
   #@Reviser David Ruy <2024-11-18> Só processa o tbsolic_saidas_item_loteAux se qtde registros  > 0
   #@Reviser David Ruy <2024-12-16> Se OpenInvQty > 0 então, FatorConvSap = OpenInvQty / BaseQty, Caso contrário NumInSales
   #@Reviser David Ruy <2025-01-15> Não Gerar PK para DocTipo = 'DC'  Devolução de Compras / oTipoRetorno = 5 'DC'
   #@Reviser David Ruy <2025-12-17> Quando oTipoRetorno : considerar documentos com até 60 dias da data de inclusão   
   #@Reviser David Ruy <2025-07-21> Não utiliza mais Não utiliza mais tbsolic_saidas_item_loteAux
   #@Reviser David Ruy <2025-09-18> Desconsidera DocDate < 90 dias para retorno, retorna qualquer Doc com dthr_confirm até 30 dias
   #@Reviser David Ruy <2026-04-17> Add campos Ordem Produção : DocEntryOrdemProducao, DocNumOrdemProducao
   ********************************************************************************************/
   
   DECLARE xCodEmpWMS			      VARCHAR(03)	DEFAULT '001';
   DECLARE xCodFilWMS			      VARCHAR(03) DEFAULT '001';
   DECLARE xNumSolic 			      VARCHAR(10);
   DECLARE xAnoSolic 			      VARCHAR(04)	DEFAULT YEAR(CURRENT_DATE());
   DECLARE xDocEntry          INT;
   DECLARE xDocTipo           VARCHAR(10);   
   DECLARE xTipoOperSaida 		  VARCHAR(03) DEFAULT '002';
   DECLARE xCodUnidade			     VARCHAR(03) DEFAULT '001';
   DECLARE xCodArmazem			     VARCHAR(02) DEFAULT '01';
   DECLARE xStatusProcesso		  VARCHAR(02) DEFAULT '01';
   DECLARE xCodErro	          INT DEFAULT 0;
   DECLARE excecao 	          INT DEFAULT 0;
   DECLARE RESULTADO          INT DEFAULT 1;
   DECLARE MENSAGEM           VARCHAR(500);
   DECLARE xSTRGEM            TEXT;
   DECLARE xNumProcesso       VARCHAR(20);  
   DECLARE xflg_obriga_checkout_retornoPV TINYINT;
   DECLARE xflg_obriga_roteiriz_retornoPV TINYINT;
   DECLARE xOrdemLista        INT DEFAULT 0;  #0=Crescente / 1 = Decrescente
   DECLARE xQtdeRegistros     INT DEFAULT 0;
   DECLARE xflg_permite_PVParcial INT DEFAULT 0;
   DECLARE xutilizacao_saidas_retorno VARCHAR(200) DEFAULT NULL;
   DECLARE xflg_agrupa_transf TINYINT;
   DECLARE xemb_faturamento   VARCHAR(50);
   DECLARE xcampo_qtde_volumes TINYINT;
   DECLARE xParamDiasEntrega   INT DEFAULT 180;
   
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   
   
   #@Reviser David Ruy <2022-11-01>
   SELECT flg_permite_PVParcial, flg_obriga_checkout_retornoPV, flg_obriga_roteiriz_retornoPV, utilizacao_saidas_retorno,
          flg_agrupa_transf, IFNULL(emb_faturamento,"Volumes"), flg_campo_volumes
   INTO xflg_permite_PVParcial, xflg_obriga_checkout_retornoPV, xflg_obriga_roteiriz_retornoPV, xutilizacao_saidas_retorno,
        xflg_agrupa_transf, xemb_faturamento, xcampo_qtde_volumes
   FROM tbintegraSAP_parametros
   LIMIT 1;
   
   
   #Cria tabela temporária com as GSM recebidas que serão separadas
   DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_SAIDAS;
   IF IFNULL(oIdRetorno,'') = '' THEN
   
      IF oTipoRetorno = 0 THEN
         CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_SAIDAS AS 
            SELECT DocEntry, DocTipo, DocNum, tbSaidas.num_nf, tbSaidas.data_nf, tbSaidas.data_solic, tbintegraSAP_Doc.BPLId
                  ,CONCAT(tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic) NumProcesso
                  ,tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic
                  ,tbSaidas.status_processo, tbSaidas.observ_solic 
                  ,tbwmsTipoOper.tipo_movto, tbwmsTipoOper.cod_oper_wms
            FROM tbintegraSAP_Doc
            INNER JOIN tbintegraSAP_empresas ON 
                       tbintegraSAP_empresas.id_integracao = IFNULL(tbintegraSAP_Doc.BPLId,1)
            LEFT JOIN of_logistica.tbsolic_saidas tbSaidas ON
                  tbSaidas.cod_emp   = tbintegraSAP_Doc.cod_emp
              AND tbSaidas.cod_fil   = tbintegraSAP_Doc.cod_fil
              AND tbSaidas.ano_solic = tbintegraSAP_Doc.ano_solic
              AND tbSaidas.num_solic = tbintegraSAP_Doc.num_solic
            LEFT JOIN of_logistica.tbsys_integracao_estoque tbwmsIntegraEstoque ON 
                     tbwmsIntegraEstoque.chave_integracao = tbintegraSAP_Doc.DocTipo
                 AND tbwmsIntegraEstoque.cod_emp = tbintegraSAP_empresas.cod_emp_slin
                 AND tbwmsIntegraEstoque.cod_fil = tbintegraSAP_empresas.cod_fil_slin
            LEFT JOIN of_logistica.tbwms_tipo_oper tbwmsTipoOper ON 
                     tbwmsTipoOper.cod_oper_wms = tbwmsIntegraEstoque.cod_oper_wms
            WHERE tbwmsTipoOper.tipo_movto = 'S'
              AND tbintegraSAP_Doc.IdPicking IS NULL
              AND tbSaidas.dthr_cancelamento IS NULL
              AND (tbintegraSAP_Doc.StatusDoc <= 3 OR tbintegraSAP_Doc.StatusDoc = 7)
              AND (tbSaidas.dthr_bloqueio_ini IS NULL OR (tbSaidas.dthr_bloqueio_ini IS NOT NULL AND tbSaidas.dthr_bloqueio_fin IS NOT NULL))
              AND tbintegraSAP_Doc.dthr_inc >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY)
              AND tbintegraSAP_Doc.DueDate <= DATE_ADD(CURRENT_DATE(), INTERVAL xParamDiasEntrega DAY)
              #@Reviser David Ruy <2025-01-15> Não gerar PK para DC
              AND tbintegraSAP_Doc.DocTipo NOT IN ('DC') 
              #AND IF(oTipoRetorno=0, tbSaidas.cod_emp IS NULL, tbSaidas.cod_emp IS NOT NULL)
              #@Reviser David Ruy <2020/02/11> Regra para não considerar pedido com data de entrega no passado              
              #@Reviser David Ruy <2020/03/26> pedido com entrega no passado mas que já foi separado pode retornar
          #AND IF(tbintegraSAP_Doc.idPickingAnt IS NULL, DATE(tbintegraSAP_Doc.DueDate) >= CURRENT_DATE(), TRUE)
              ;#AND (tbintegraSAP_Doc.U_RSD_RplOrder IS NULL OR
               #   (tbintegraSAP_Doc.U_RSD_RplOrder IS NOT NULL AND tbintegraSAP_Doc.cod_emp IS NOT NULL));
               
         #Ordena Ascendente ou Descendente
         DROP TEMPORARY TABLE IF EXISTS tbTMPX;
         IF xOrdemLista = 0 THEN
            CREATE TEMPORARY TABLE tbTMPX AS
               SELECT * FROM tbTMP_INTEGRA_RETORNO_SAIDAS ORDER BY data_solic;
         ELSE
            CREATE TEMPORARY TABLE tbTMPX AS
               SELECT * FROM tbTMP_INTEGRA_RETORNO_SAIDAS ORDER BY data_solic DESC;
         END IF;
                       
         #Força ficar apenas 10 Registros;
         DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS;
         IF xQtdeRegistros = 0 THEN
            INSERT INTO tbTMP_INTEGRA_RETORNO_SAIDAS SELECT * FROM tbTMPX;
         ELSE
            INSERT INTO tbTMP_INTEGRA_RETORNO_SAIDAS SELECT * FROM tbTMPX LIMIT xQtdeRegistros;
         END IF;
         DROP TEMPORARY TABLE IF EXISTS tbTMPX;      
         
         #select * from tbTMP_INTEGRA_RETORNO_SAIDAS ;         
         #Leave Bloco1;
               
              
      ELSE
      
         DROP TEMPORARY TABLE IF EXISTS tbSaidas;
         CREATE TEMPORARY TABLE tbSaidas
            SELECT tbSaidas.* FROM of_logistica.tbsolic_saidas tbSaidas
            INNER JOIN tbintegraSAP_Doc ON 
                       tbintegraSAP_Doc.chave_integracao = tbSaidas.chave_integracao
            WHERE tbSaidas.status_processo >= 8
              AND tbSaidas.dthr_cancelamento IS NULL
              AND tbSaidas.dthr_retorno_integracao IS NULL
              AND tbSaidas.dthr_confirm >= DATE_ADD(CURRENT_DATE(), INTERVAL -30 DAY)
              AND IF(xflg_obriga_checkout_retornoPV = 1, dthr_final_picking IS NOT NULL, TRUE)
              AND tbSaidas.chave_integracao IS NOT NULL
              AND IF(oTipoRetorno=4, tbintegraSAP_Doc.StatusDoc = 6 AND tbintegraSAP_Doc.StatusEnum = 0, tbintegraSAP_Doc.StatusDoc = 3)              
            ORDER BY tbSaidas.dthr_confirm DESC
            LIMIT 100
            ;
         ALTER TABLE tbSaidas ADD PRIMARY KEY (chave_integracao);
         #select * from tbSaidas; leave Bloco1; 
          
         DROP TEMPORARY TABLE IF EXISTS tbSaidasVolItem;
         CREATE TEMPORARY TABLE tbSaidasVolItem
            SELECT tbSaidasVolItem.* FROM of_logistica.tbsolic_saidas_volume_item tbSaidasVolItem
            INNER JOIN tbSaidas ON 
                              tbSaidasVolItem.cod_emp   = tbSaidas.cod_emp 
                          AND tbSaidasVolItem.cod_fil   = tbSaidas.cod_fil
                          AND tbSaidasVolItem.ano_solic = tbSaidas.ano_solic
                          AND tbSaidasVolItem.num_solic = tbSaidas.num_solic;
                          
         DROP TEMPORARY TABLE IF EXISTS tbSaidasItem;
         CREATE TEMPORARY TABLE tbSaidasItem
            SELECT tbSaidasItem.* FROM of_logistica.tbsolic_saidas_item tbSaidasItem
            INNER JOIN tbSaidas ON 
                              tbSaidasItem.cod_emp   = tbSaidas.cod_emp 
                          AND tbSaidasItem.cod_fil   = tbSaidas.cod_fil
                          AND tbSaidasItem.ano_solic = tbSaidas.ano_solic
                          AND tbSaidasItem.num_solic = tbSaidas.num_solic;
                   
         CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_SAIDAS AS 
            SELECT DocEntry, DocTipo, DocNum, tbSaidas.num_nf, tbSaidas.data_nf, tbSaidas.data_solic, tbintegraSAP_Doc.BPLId
                  ,CONCAT(tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic) NumProcesso
                  ,tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic
                  ,tbSaidas.status_processo, tbSaidas.observ_solic 
                  ,tbSaidas.flg_producao
                  ,tbSaidas.dthr_final_picking 
                  ,tbSaidas.dthr_confirm
                  ,tbEstCli.flg_conferencia_volume_check_tp
                  #
                  
                  #,(SELECT SUM(qtde_sep_est) FROM of_logistica.tbsolic_saidas_volume_item Item
                  ,(SELECT SUM(qtde_sep_est) FROM tbSaidasVolItem Item
                    WHERE Item.cod_emp   = tbSaidas.cod_emp
                      AND Item.cod_fil   = tbSaidas.cod_fil
                      AND Item.ano_solic = tbSaidas.ano_solic
                      AND Item.num_solic = tbSaidas.num_solic) AS QtdeCheckout 
                  #,(SELECT SUM(real_est2) FROM of_logistica.tbsolic_saidas_item Item
                  ,(SELECT SUM(real_est2) FROM tbSaidasItem Item
                    WHERE Item.cod_emp = tbSaidas.cod_emp
                      AND Item.cod_fil = tbSaidas.cod_fil
                      AND Item.ano_solic = tbSaidas.ano_solic
                      AND Item.num_solic = tbSaidas.num_solic) AS QtdeSep
                  #
            FROM tbintegraSAP_Doc
            #INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
            INNER JOIN tbSaidas ON
                  tbSaidas.chave_integracao = tbintegraSAP_Doc.chave_integracao 
              #    tbSaidas.cod_emp   = tbintegraSAP_Doc.cod_emp
              #AND tbSaidas.cod_fil   = tbintegraSAP_Doc.cod_fil
              #AND tbSaidas.ano_solic = tbintegraSAP_Doc.ano_solic
              #AND tbSaidas.num_solic = tbintegraSAP_Doc.num_solic
              AND tbSaidas.status_processo >= 8
              AND tbSaidas.dthr_cancelamento IS NULL
              AND (tbSaidas.dthr_bloqueio_ini IS NULL OR (tbSaidas.dthr_bloqueio_ini IS NOT NULL AND tbSaidas.dthr_bloqueio_fin IS NOT NULL))              
            INNER JOIN of_logistica.tbwms_estoque_cli tbEstCli ON 
                       tbEstCli.cod_emp      = tbSaidas.cod_emp
                   AND tbEstCli.cod_fil      = tbSaidas.cod_fil
                   AND tbEstCli.cnpj_cpf_cli = tbSaidas.cnpj_cpf_cli
                   AND tbEstCli.cod_estoque  = tbSaidas.cod_estoque
            WHERE tbintegraSAP_Doc.TipoDocSLIN = 'S'
              AND IF(oTipoRetorno=4, tbintegraSAP_Doc.StatusDoc = 6 AND tbintegraSAP_Doc.StatusEnum = 0, tbintegraSAP_Doc.StatusDoc = 3)
              # Só retorna depois de checkout (exceto para Ordem Produção)
              #AND IF(tbSaidas.flg_producao='S', TRUE, 
              #       tbSaidas.dthr_final_picking IS NOT NULL)
              AND tbintegraSAP_Doc.IdPicking IS NOT NULL
              AND IF(oTipoRetorno=1,tbintegraSAP_Doc.DocTipo IN ('PV','OP','NS'), 
                     IF(oTipoRetorno=4,tbintegraSAP_Doc.DocTipo IN ('TD-S'), 
                        IF(oTipoRetorno=5,tbintegraSAP_Doc.DocTipo IN ('DC'), 
                           FALSE
                        )
                     )
                  )
              #AND tbintegraSAP_Doc.DocDate >= DATE_ADD(CURRENT_DATE(), INTERVAL -90 DAY)
              AND tbSaidas.dthr_confirm >= DATE_ADD(CURRENT_DATE(), INTERVAL -30 DAY)
              #@Reviser David Ruy <2023-09-15> Regra Cromo, Não retornar se não tiver preenchido Qtde e Peso Checkout manual
              AND IF(xcampo_qtde_volumes IN (2,3), IFNULL(tbSaidas.qtde_volume_checkout,0) > 0, TRUE)
              AND IF(xcampo_qtde_volumes IN (2), IFNULL(tbSaidas.peso_liq_checkout,0) > 0, TRUE)  
              AND IF(xcampo_qtde_volumes IN (2), IFNULL(tbSaidas.peso_brt_checkout,0) > 0, TRUE)
                      #AND tbintegraSAP_Doc.DocNum = 159381
              #ORDER BY tbSaidas.dthr_confirm DESC
              LIMIT 100    #(utilizar LIMIT quando consulta estourar o tempo DO processamento)
              ; 
                      
	      DROP TEMPORARY TABLE IF EXISTS tbSaidas;
	      DROP TEMPORARY TABLE IF EXISTS tbSaidasVolItem;
	      DROP TEMPORARY TABLE IF EXISTS tbSaidasItem;
	      
	      
         #Update (como retornado) para PV´ com utilização diferente da parametrizada
         IF IFNULL(xutilizacao_saidas_retorno,'') <> '' THEN
            UPDATE tbintegraSAP_Doc
            INNER JOIN tbTMP_INTEGRA_RETORNO_SAIDAS ON
                       tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo  = tbintegraSAP_Doc.DocTipo
                   AND tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry = tbintegraSAP_Doc.DocEntry
                   AND tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum   = tbintegraSAP_Doc.DocNum
            SET StatusAnt = StatusDoc,
                StatusDoc = 6
            #where LOCATE(tbintegraSAP_Doc.MainUsage,xutilizacao_saidas_retorno) = 0);
            WHERE EXISTS (SELECT 1 FROM tbintegraSAP_DocItem
                          WHERE tbintegraSAP_DocItem.DocTipo  = tbintegraSAP_Doc.DocTipo
                            AND tbintegraSAP_DocItem.DocEntry = tbintegraSAP_Doc.DocEntry
                            AND tbintegraSAP_DocItem.DocNum   = tbintegraSAP_Doc.DocNum
                            AND LOCATE(IFNULL(tbintegraSAP_DocItem.Usage_,'XXX'),xutilizacao_saidas_retorno) = 0);
            DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS 
            WHERE EXISTS (SELECT 1 FROM tbintegraSAP_Doc
                          WHERE tbintegraSAP_Doc.DocTipo = tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo
                            AND tbintegraSAP_Doc.DocEntry  = tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry
                            AND tbintegraSAP_Doc.DocNum = tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum
                            AND StatusDoc = 6);
         END IF;
               
      END IF;
      
   ELSE
   
      SET xCodEmpWMS	= SUBSTRING(oIdRetorno,01,03);
      SET xCodFilWMS	= SUBSTRING(oIdRetorno,04,03);
      SET xAnoSolic 	= SUBSTRING(oIdRetorno,07,04);
      SET xNumSolic 	= SUBSTRING(oIdRetorno,11,10);    
      SET xSTRGEM = CONCAT(xCodEmpWMS, "|", xCodFilWMS, "|", xAnoSolic, "|", xNumSolic, "|");
      #select xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic;
      /*******************************************************************
      # Validar a existencia da GSM
      *******************************************************************/
      IF NOT EXISTS (SELECT 1 FROM of_logistica.tbsolic_saidas 
                     WHERE cod_emp = xCodEmpWMS
                     AND cod_fil = xCodFilWMS
                     AND ano_solic = xAnoSolic
                     AND num_solic = xNumSolic) THEN
         SET xCodErro = 1;
         SET RESULTADO = 0;
         SET MENSAGEM  = 'GSM não localizada';
         SELECT RESULTADO, MENSAGEM;
         LEAVE BLOCO1;
      END IF;
      CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_SAIDAS AS 
         SELECT DocEntry, DocTipo, DocNum, tbSaidas.num_nf, tbSaidas.data_nf, tbSaidas.data_solic
               ,CONCAT(tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic) NumProcesso
               ,tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic
               ,tbSaidas.status_processo, tbSaidas.observ_solic 
         FROM tbintegraSAP_Doc
         INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
               tbSaidas.cod_emp   = tbintegraSAP_Doc.cod_emp
           AND tbSaidas.cod_fil   = tbintegraSAP_Doc.cod_fil
           AND tbSaidas.ano_solic = tbintegraSAP_Doc.ano_solic
           AND tbSaidas.num_solic = tbintegraSAP_Doc.num_solic
           AND IF(oTipoRetorno = 0, tbSaidas.status_processo = 1, tbSaidas.status_processo >= 8)
           AND IF(oTipoRetorno = 0, tbintegraSAP_Doc.StatusDoc BETWEEN 2 AND 3, tbintegraSAP_Doc.StatusDoc = 5)
         WHERE tbintegraSAP_Doc.cod_emp   = xCodEmpWMS 
           AND tbintegraSAP_Doc.cod_fil   = xCodFilWMS
           AND tbintegraSAP_Doc.ano_solic = xAnoSolic
           AND tbintegraSAP_Doc.num_solic = xNumSolic
           AND tbintegraSAP_Doc.TipoDocSLIN = 'S'
           AND IF(tbSaidas.flg_producao='S', TRUE, tbSaidas.dthr_final_picking IS NOT NULL)
           AND IF(oTipoRetorno = 0, tbintegraSAP_Doc.IdPicking IS NULL, tbintegraSAP_Doc.IdPicking IS NOT NULL)
           #@Reviser David Ruy <2020/02/11> Regra para não considerar pedido com data de entrega no passado
           AND IF(oTipoRetorno = 0, DATE(tbintegraSAP_Doc.DueDate) >= CURRENT_DATE(), TRUE)
           #@Reviser David Ruy <2023-09-15> Regra Cromo, Não retornar se não tiver preenchido Qtde e Peso Checkout manual
           AND IF(xcampo_qtde_volumes IN (2,3), IFNULL(tbSaidas.qtde_volume_checkout,0) > 0, TRUE)
           AND IF(xcampo_qtde_volumes IN (2), IFNULL(tbSaidas.peso_liq_checkout,0) > 0, TRUE)  
           AND IF(xcampo_qtde_volumes IN (2), IFNULL(tbSaidas.peso_brt_checkout,0) > 0, TRUE);           
   END IF;
   
   
   
   IF (oTipoRetorno IN (1,3,5)) THEN
      #SELECT flg_obriga_checkout_retornoPV, flg_obriga_roteiriz_retornoPV
      #INTO xflg_obriga_checkout_retornoPV, xflg_obriga_roteiriz_retornoPV
      #FROM tbintegraSAP_parametros LIMIT 1;
      
           
      #Desconsidera GSM´s que não são de produção e que flg_conferencia_volume_check_tp = 1
      #e que não concluiu o checkout
      IF xflg_obriga_checkout_retornoPV = 1 THEN
         DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS
         #WHERE flg_producao = 'N'
         WHERE flg_producao = 'N' AND DocTipo NOT IN ('OP','TD-S') 
           AND flg_conferencia_volume_check_tp = 1
           AND dthr_final_picking IS NULL;
         #select "Aqui", row_count();  LEAVE BLOCO1;
      END IF;
      #select * from tbTMP_INTEGRA_RETORNO_SAIDAS;
             
      #Ordem de Produção não depende de checkout
      UPDATE tbTMP_INTEGRA_RETORNO_SAIDAS
      SET QtdeCheckout = QtdeSep
      WHERE QtdeCheckout IS NULL
        AND DocTipo IN ('OP','TD-S');
        
        
      #Desconsidera GSM´s com Checkout não Realizado quando flg_conferencia_volume_check_tp = 2
      IF xflg_obriga_checkout_retornoPV = 1 THEN
         DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS
         WHERE flg_producao = 'N'
           AND flg_conferencia_volume_check_tp = 2
           AND (IFNULL(QtdeSep,0) = 0 
           OR IFNULL(QtdeCheckout,0) < IFNULL(QtdeSep,0));
         #SELECT "Aqui2", ROW_COUNT();  LEAVE BLOCO1;
      END IF;
      
      
      #Não considerar retorno se o checkout não estiver concluido
      IF xcampo_qtde_volumes IN (2,3) THEN
         DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS
         WHERE flg_producao = 'N'
           AND (IFNULL(QtdeSep,0) = 0 
           OR IFNULL(QtdeCheckout,0) < IFNULL(QtdeSep,0));
         #SELECT "Aqui2", ROW_COUNT();  LEAVE BLOCO1;
      END IF;
	#SELECT xflg_permite_PVParcial, xflg_obriga_checkout_retornoPV, xflg_obriga_roteiriz_retornoPV, xutilizacao_saidas_retorno,
	#xflg_agrupa_transf, xemb_faturamento, xcampo_qtde_volumes;
	#SELECT * FROM tbTMP_INTEGRA_RETORNO_SAIDAS;
	#LEAVE BLOCO1;
           
                    
      #Desconsidera GSM´s Pedido em viagem Não Confirmada
      IF xflg_obriga_roteiriz_retornoPV = 1 THEN
         DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS
         WHERE flg_producao = 'N'
           AND flg_conferencia_volume_check_tp = 2
           AND EXISTS (SELECT NumProcesso, tbViagens.num_viagem
                       FROM of_logistica.tbsolic_saidas_item tbItem 
                       LEFT JOIN of_logistica.tbprog_entregas tbEntregas ON 
                                 tbEntregas.cod_emp      = tbItem.cod_emp_pedido
                             AND tbEntregas.cod_fil      = tbItem.cod_fil_pedido
                             AND tbEntregas.cnpj_cpf_cli = tbItem.cnpj_cpf_cli
                             AND tbEntregas.num_nf_cli   = tbItem.num_ped_cli
                       LEFT JOIN of_logistica.tbviagens tbViagens ON 
                                 tbViagens.cod_emp    = tbEntregas.cod_emp 
                             AND tbViagens.cod_fil    = tbEntregas.cod_fil
                             AND tbViagens.ano_viagem = tbEntregas.ano_viagem 
                             AND tbViagens.num_viagem = tbEntregas.num_viagem
                       WHERE tbItem.cod_emp   = tbTMP_INTEGRA_RETORNO_SAIDAS.cod_emp 
                         AND tbItem.cod_fil   = tbTMP_INTEGRA_RETORNO_SAIDAS.cod_fil
                         AND tbItem.ano_solic = tbTMP_INTEGRA_RETORNO_SAIDAS.ano_solic 
                         AND tbItem.num_solic = tbTMP_INTEGRA_RETORNO_SAIDAS.num_solic
                         AND tbViagens.data_conf IS NULL
                       GROUP BY NumProcesso);
         #SELECT "Aqui3", ROW_COUNT();  LEAVE BLOCO1;
         
         #@Reviser David Ruy <2022-04-06>
         #Não retornar Quando houver divergencia entre itens ou quantidades do SLIN X Integração
         IF xflg_permite_PVParcial = 0 THEN
            DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS
            WHERE EXISTS
                  (SELECT SUM(tbItemSLIN.real_est2) TotalSlin, COUNT(tbItemSLIN.num_item) QtdeSlin, 
                          SUM(IFNULL(tbItem.OpenInvQty,tbItem.BaseQty)) TotalDoc, COUNT(tbItem.LineNum) QtdeDoc
                   FROM tbintegraSAP_DocItem tbItem 
                   LEFT JOIN of_logistica.tbsolic_saidas_item tbItemSLIN ON
                             tbItemSLIN.cod_emp   = tbItem.cod_emp 
                         AND tbItemSLIN.cod_fil   = tbItem.cod_fil
                         AND tbItemSLIN.ano_solic = tbItem.ano_solic
                         AND tbItemSLIN.num_solic = tbItem.num_solic
                         AND tbItemSLIN.num_item  = tbItem.num_item
                   WHERE tbItem.cod_emp   = tbTMP_INTEGRA_RETORNO_SAIDAS.cod_emp 
                     AND tbItem.cod_fil   = tbTMP_INTEGRA_RETORNO_SAIDAS.cod_fil
                     AND tbItem.ano_solic = tbTMP_INTEGRA_RETORNO_SAIDAS.ano_solic 
                     AND tbItem.num_solic = tbTMP_INTEGRA_RETORNO_SAIDAS.num_solic
                     AND tbItem.StatusItem <> 9
                   HAVING TotalSlin <> TotalDoc OR QtdeSlin <> QtdeDoc);
         END IF;
         
         
         
      END IF;
      
      
      #Ordena Ascendente ou Descendente
      DROP TEMPORARY TABLE IF EXISTS tbTMPX;
      IF xOrdemLista = 0 THEN
         CREATE TEMPORARY TABLE tbTMPX AS
            SELECT * FROM tbTMP_INTEGRA_RETORNO_SAIDAS ORDER BY dthr_confirm;
      ELSE
         CREATE TEMPORARY TABLE tbTMPX AS
            SELECT * FROM tbTMP_INTEGRA_RETORNO_SAIDAS ORDER BY dthr_confirm DESC;
      END IF;
                    
      #Força ficar apenas 10 Registros;
      DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS;
      IF xQtdeRegistros = 0 THEN
         INSERT INTO tbTMP_INTEGRA_RETORNO_SAIDAS SELECT * FROM tbTMPX;
      ELSE
         INSERT INTO tbTMP_INTEGRA_RETORNO_SAIDAS SELECT * FROM tbTMPX LIMIT xQtdeRegistros;
      END IF;
      DROP TEMPORARY TABLE IF EXISTS tbTMPX;
      
   END IF;
   
   
   IF oTipoRetorno = 1 THEN  
      #Não Gerar retorno de Materiais de Uso/consumo
      DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS
      WHERE (SELECT COUNT(*) FROM tbintegraSAP_DocItem
                    WHERE tbintegraSAP_DocItem.DocTipo = tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo
                      AND tbintegraSAP_DocItem.DocEntry = tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry
                      AND tbintegraSAP_DocItem.OONE_USO_CONS = 1);
  END IF;
   
   
   
   IF oTipoRetorno = 0 THEN
   /*******************************************************************
      # Selecionar as informações da GSM
      *******************************************************************/
      # INFORMAÇÕES DO TOPO DA GSM
      SELECT tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry, tbTMP_INTEGRA_RETORNO_SAIDAS.Doctipo, tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum, 
             tbTMP_INTEGRA_RETORNO_SAIDAS.BPLId, 
             tbintegraSAP_Doc.IdPicking, tbintegraSAP_Doc.idPickingAnt,
             topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
             
             #Soma das Qtdes por Item
            (SELECT COUNT(tbItem.LineNum) QtdeSAP
             FROM tbintegraSAP_DocItem tbItem 
             WHERE tbItem.DocEntry = tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry
               AND tbItem.DocTipo  = tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo
               AND tbItem.DocNum   = tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum
               AND IFNULL(tbItem.StatusItem,0) <> 9) QtdeSAP,
            (SELECT COUNT(tbItemSLIN.num_item) TotalSlin
             FROM tbintegraSAP_DocItem tbItem 
             LEFT JOIN of_logistica.tbsolic_saidas_item tbItemSLIN ON
                       tbItemSLIN.cod_emp   = tbItem.cod_emp 
                   AND tbItemSLIN.cod_fil   = tbItem.cod_fil
                   AND tbItemSLIN.ano_solic = tbItem.ano_solic
                   AND tbItemSLIN.num_solic = tbItem.num_solic
                   AND tbItemSLIN.num_item  = tbItem.num_item
             WHERE tbItem.DocEntry = tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry
               AND tbItem.DocTipo = tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo
               AND tbItem.DocNum = tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum
               AND IFNULL(tbItem.StatusItem,0) <> 9) QtdeSlin,
               
             #Contabiliza Qtde de Itens
            (SELECT SUM(IFNULL(tbItem.OpenInvQty,tbItem.BaseQty)) TotalSAP
             FROM tbintegraSAP_DocItem tbItem 
             WHERE tbItem.DocEntry = tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry
               AND tbItem.DocTipo  = tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo
               AND tbItem.DocNum   = tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum
               AND IFNULL(tbItem.StatusItem,0) <> 9) TotalSAP,
            (SELECT SUM(tbItemSLIN.real_est) TotalSlin
             FROM tbintegraSAP_DocItem tbItem 
             LEFT JOIN of_logistica.tbsolic_saidas_item tbItemSLIN ON
                       tbItemSLIN.cod_emp   = tbItem.cod_emp 
                   AND tbItemSLIN.cod_fil   = tbItem.cod_fil
                   AND tbItemSLIN.ano_solic = tbItem.ano_solic
                   AND tbItemSLIN.num_solic = tbItem.num_solic
                   AND tbItemSLIN.num_item  = tbItem.num_item
             WHERE tbItem.DocEntry = tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry
               AND tbItem.DocTipo  = tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo
               AND tbItem.DocNum   = tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum
               AND IFNULL(tbItem.StatusItem,0) <> 9) TotalSlin,
             
             topo.data_solic, IFNULL(topo.data_saida,tbintegraSAP_Doc.DueDate) data_saida, topo.dthr_acons, 
             IFNULL(topo.num_nf, CONCAT(tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo,tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum)) AS num_pedido,
             topo.observ_solic, topo.observ_conf01, topo.status_processo, 
             of_logistica.fnStatusSaidaWms(topo.status_processo) status_processoAux,
             #Liberação Inicio Processo de Separação, Picking
             topo.dthr_armazem, topo.dthr_armazem_picking, topo.dthr_confer, topo.dthr_confirm,
             #Inicio Processo de Separação, Picking
             topo.dthr_inicio_geral, topo.dthr_inicio_picking, topo.dthr_inicio_carregamento
            ,IFNULL(topo.chave_integracao, CONCAT(tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo,tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum,'-',tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry)) chave_integracao
            ,RESULTADO, MENSAGEM
      FROM tbTMP_INTEGRA_RETORNO_SAIDAS
      INNER JOIN tbintegraSAP_Doc ON 
                tbintegraSAP_Doc.DocEntry = tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry
            AND tbintegraSAP_Doc.DocTipo  = tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo
            AND tbintegraSAP_Doc.DocNum   = tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum
      LEFT JOIN of_logistica.tbsolic_saidas topo ON
            tbTMP_INTEGRA_RETORNO_SAIDAS.cod_emp = topo.cod_emp
            AND tbTMP_INTEGRA_RETORNO_SAIDAS.cod_fil = topo.cod_fil
            AND tbTMP_INTEGRA_RETORNO_SAIDAS.ano_solic = topo.ano_solic
            AND tbTMP_INTEGRA_RETORNO_SAIDAS.num_solic = topo.num_solic;
   
      # INFORMAÇÕES DOS ITENS DA GSM
         SELECT tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry, tbTMP_INTEGRA_RETORNO_SAIDAS.Doctipo, tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum, 
               tbintegraSAP_DocItem.LineNum, tbintegraSAP_DocItem.DocEntryOrdemProducao, tbintegraSAP_DocItem.DocNumOrdemProducao,
               xflg_permite_PVParcial,  #@Reviser David Ruy <2022-04-04>
               #IF(IFNULL(tbintegraSAP_DocItem.NumInSale,1)=0,1,tbintegraSAP_DocItem.NumInSale) AS FatorConvSAP,
               #tbintegraSAP_DocItem.buyUnitMsr, tbintegraSAP_DocItem.salUnitMsr, tbintegraSAP_DocItem.invntryUom,
               #IF(IFNULL(prod.fator_conv_vendas,0)=0,1,prod.fator_conv_vendas) AS FatorConvSAP,
               IF(IFNULL(tbintegraSAP_DocItem.OpenInvQty,0) > 0, 
                 tbintegraSAP_DocItem.OpenInvQty / tbintegraSAP_DocItem.BaseQty,
                 IF(IFNULL(tbintegraSAP_DocItem.NumInSale,1)=0,1,tbintegraSAP_DocItem.NumInSale))  AS FatorConvSAP,               
               #prod.emb_compras buyUnitMsr, prod.emb_vendas salUnitMsr, prod.emb_estoque_cli invntryUom,
               tbintegraSAP_DocItem.buyUnitMsr, tbintegraSAP_DocItem.salUnitMsr, tbintegraSAP_DocItem.invntryUom,
               topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
               IFNULL(ite.num_ped_cli, CONCAT(tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocNum)) num_ped_cli, ite.num_item, 
               IFNULL(ite.cod_produto, tbintegraSAP_DocItem.ItemCode) cod_produto, 
               IFNULL(descr_produto, tbintegraSAP_DocItem.description) AS descr_prod,
               IFNULL(ite.emb_est, tbintegraSAP_DocItem.invntryUom) AS emb_est, 
               ite.emb_frac, ite.emb_vol,ite.fator_conv AS fator_conv,
               #
               ite.local_geral, ite.local_picking,
               IFNULL(ite.qtde_est, tbintegraSAP_DocItem.BaseQty) qtde_est , ite.qtde_vol, ite.qtde_frac, ite.pliq_item,		#Qtde Pedido
               ite.real_est, ite.real_vol, ite.real_frac, ite.real_peso,		#Qtde Aconselhada
               #@Reviser David Ruy <2020/04/29>
               #Se tiver alteração em andamento, envia a nova quantidade
               IF(tbAlt.cod_emp IS NOT NULL, tbAlt.qtde_est_atu ,ite.real_est2) real_est2,
               IF(tbAlt.cod_emp IS NOT NULL, tbAlt.qtde_vol_atu ,ite.real_vol2) real_vol2,
               IF(tbAlt.cod_emp IS NOT NULL, tbAlt.qtde_frac_atu ,ite.real_frac2) real_frac2,
               IF(tbAlt.cod_emp IS NOT NULL, tbAlt.qtde_peso_atu ,ite.real_peso2) real_peso2,
               #ite.real_est2, ite.real_vol2, ite.real_frac2, ite.real_peso2,	#Qtde Separação
               #
               ite.real_est3, ite.real_vol3, ite.real_frac3, ite.real_peso3,	#Qtde Conferencia / Picking
               #
               ite.real_est4, ite.real_vol4, ite.real_frac4, ite.real_peso4,	#Qtde Carregamento
               ite.real_est5, ite.real_vol5, ite.real_frac5, ite.real_peso5,	#Qtde check-carregamento
               #			
               ite.dthr_aconselhamento, ite.dthr_retorno_wms,
               ite.dthr_inicio_baixa_geral, ite.dthr_inicio_picking_carga, ite.dthr_inicio_carregamento,
               ite.dthr_final_baixa_geral, ite.dthr_final_picking_carga, ite.dthr_final_carregamento		
               ,IFNULL(topo.chave_integracao, CONCAT(tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo,tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum,'-',tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry)) chave_integracao
               ,prod.flg_obriga_lote_fornecedor
               ,IF(tbintegraSAP_Doc.DocTipo='TD-S' AND xflg_agrupa_transf=1,1,0) xflg_agrupa_transf
               ,tbintegraSAP_DocItem.BaseQty / (SELECT SUM(tbDocItem.BaseQty) FROM tbintegraSAP_DocItem tbDocItem
                     WHERE tbintegraSAP_DocItem.DocTipo = tbDocItem.DocTipo
                       AND tbintegraSAP_DocItem.DocEntry = tbDocItem.DocEntry
                       AND tbintegraSAP_DocItem.ItemCode = tbDocItem.ItemCode
                     ) AS FatorAgrup
               ,RESULTADO, MENSAGEM
         FROM tbTMP_INTEGRA_RETORNO_SAIDAS
         INNER JOIN tbintegraSAP_Doc ON 
                   tbintegraSAP_Doc.DocEntry = tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry
               AND tbintegraSAP_Doc.DocTipo  = tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo
               AND tbintegraSAP_Doc.DocNum   = tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum
         INNER JOIN tbintegraSAP_empresas ON 
                    tbintegraSAP_empresas.id_integracao = IFNULL(tbintegraSAP_Doc.BPLId,1)
         LEFT JOIN tbintegraSAP_DocItem ON 
                   tbintegraSAP_DocItem.DocEntry = tbintegraSAP_Doc.DocEntry
               AND tbintegraSAP_DocItem.DocTipo  = tbintegraSAP_Doc.DocTipo
               AND tbintegraSAP_DocItem.DocNum   = tbintegraSAP_Doc.DocNum
         INNER JOIN of_logistica.tbsys_integracao_estoque tbwmsIntegracaoEstoque ON 
                     tbwmsIntegracaoEstoque.chave_integracao = tbintegraSAP_Doc.DocTipo
                 AND tbwmsIntegracaoEstoque.cod_emp  = tbintegraSAP_empresas.cod_emp_slin
                 AND tbwmsIntegracaoEstoque.cod_fil  = tbintegraSAP_empresas.cod_fil_slin
         #INNER JOIN of_logistica.tbwms_tipo_oper tbwmsTipoOper ON 
         #            tbwmsTipoOper.cod_oper_wms = tbwmsIntegracaoEstoque.cod_oper_wms
         #        AND tbwmsTipoOper.tipo_movto = 'S'
         LEFT JOIN of_logistica.tbsolic_saidas topo ON 
                   tbintegraSAP_Doc.cod_emp = topo.cod_emp
               AND tbintegraSAP_Doc.cod_fil = topo.cod_fil
               AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
               AND tbintegraSAP_Doc.num_solic = topo.num_solic
         LEFT JOIN of_logistica.tbsolic_saidas_item ite ON
                   ite.cod_emp = tbintegraSAP_DocItem.cod_emp
               AND ite.cod_fil = tbintegraSAP_DocItem.cod_fil
               AND ite.ano_solic = tbintegraSAP_DocItem.ano_solic
               AND ite.num_solic = tbintegraSAP_DocItem.num_solic
               AND ite.num_item  = tbintegraSAP_DocItem.num_item
         LEFT JOIN of_logistica.tbsolic_saidas_item_integra_alteracao tbAlt ON
                   ite.cod_emp   = tbAlt.cod_emp
               AND ite.cod_fil   = tbAlt.cod_fil
               AND ite.ano_solic = tbAlt.ano_solic
               AND ite.num_solic = tbAlt.num_solic
               AND ite.num_item  = tbAlt.num_item
               AND tbAlt.dthr_realizado IS NULL
         LEFT JOIN of_logistica.tbprodutos prod ON
                   prod.cnpj_cpf = tbwmsIntegracaoEstoque.cnpj_cpf_cli
               AND prod.cod_produto = tbintegraSAP_DocItem.ItemCode
         WHERE IF(ite.cod_emp IS NOT NULL, ite.qtde_nf > 0,  TRUE)
         #@Reviser David Ruy <2021/01/05> Considerar apenas itens não cancelados=>(status=9)
           AND (IFNULL(tbintegraSAP_DocItem.StatusItem,0) <= 2)
         ORDER BY DocEntry, Doctipo, DocNum, tbintegraSAP_DocItem.LineNum;
   
   ELSEIF oTipoRetorno IN (1,3,4,5) THEN
   
      #Alimenta variavel xSTRGEM com a lista das GSM´s selecionadas
      SET xSTRGEM = '';  
      WHILE EXISTS (SELECT 1 FROM tbTMP_INTEGRA_RETORNO_SAIDAS) DO
         SELECT NumProcesso, cod_emp, cod_fil, ano_solic, num_solic, DocEntry, Doctipo
         INTO xNumProcesso, xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xDocEntry, xDoctipo
         FROM tbTMP_INTEGRA_RETORNO_SAIDAS LIMIT 1;         
         
         SET xSTRGEM = CONCAT(xSTRGEM, CONCAT(xCodEmpWMS, "|", xCodFilWMS, "|", xAnoSolic, "|", xNumSolic, "|", xDocEntry, "|"), xDocTipo, "|");
         DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS WHERE NumProcesso = xNumProcesso;
      END WHILE;
      
      #Cria tabela temporária auxiliar para inner join com a tbsolic_entradas para gerar seleção das informações
      #da GEM informada no parametro
      CALL PROC_SYS_GerarTabelaComTexto(xSTRGEM,'|',6);        
   
   
   #select * from tTabelaComTexto; #2024-11-14
   #       LEAVE bloco1;   
      /*****************************************************************************/
      #Tabelas Temporarias para Volumes
      /*****************************************************************************/
      SELECT NOW() INTO @Time0;
       
      #Nova tabela Temporária Volumes
      DROP TEMPORARY TABLE IF EXISTS tbTMPVolumes;
      CREATE TEMPORARY TABLE tbTMPVolumes (
          cod_emp VARCHAR(03), cod_fil VARCHAR(03), ano_solic VARCHAR(04), 
          num_solic VARCHAR(10), num_item VARCHAR(06), id_volume_saida INT,
          qtde_sep_est DECIMAL(18,6),
          INDEX (id_volume_saida)
      );
      #Tabela Gêmea para utilização em 2 campos distintos
      DROP TEMPORARY TABLE IF EXISTS tbTMPVolumes2;
      CREATE TEMPORARY TABLE tbTMPVolumes2 (
          cod_emp VARCHAR(03), cod_fil VARCHAR(03), ano_solic VARCHAR(04), 
          num_solic VARCHAR(10), num_item VARCHAR(06), id_volume_saida INT,
          qtde_sep_est DECIMAL(18,6),
          INDEX (id_volume_saida)
      );
      
      
       INSERT INTO tbTMPVolumes       
       (   
          SELECT tbsolic_saidas_volume_item.cod_emp, tbsolic_saidas_volume_item.cod_fil, 
                 tbsolic_saidas_volume_item.ano_solic, tbsolic_saidas_volume_item.num_solic, 
                 tbsolic_saidas_volume_item.num_item, tbsolic_saidas_volume_item.id_volume_saida,
                 tbsolic_saidas_volume_item.qtde_sep_est
          FROM of_logistica.tbsolic_saidas_volume_item
          INNER JOIN tTabelaComTexto ON
                tTabelaComTexto.Coluna01 = tbsolic_saidas_volume_item.cod_emp
                AND tTabelaComTexto.Coluna02 = tbsolic_saidas_volume_item.cod_fil
                AND tTabelaComTexto.Coluna03 = tbsolic_saidas_volume_item.ano_solic
                AND tTabelaComTexto.Coluna04 = tbsolic_saidas_volume_item.num_solic
          #WHERE tbsolic_saidas_volume.id_volume_saida = tbsolic_saidas_volume_item.id_volume_saida;
       );
       INSERT INTO tbTMPVolumes2 (SELECT * FROM tbTMPVolumes);
      DROP TEMPORARY TABLE IF EXISTS tbTMPPesosInsumos;
      CREATE TEMPORARY TABLE tbTMPPesosInsumos (
         SELECT tbTMPVolumes.cod_emp, tbTMPVolumes.cod_fil, 
                tbTMPVolumes.ano_solic, tbTMPVolumes.num_solic, 
                SUM(IFNULL(peso_bruto_insumo,0)) PesoInsumos
         FROM of_logistica.tbsolic_saidas_volume
         INNER JOIN tbTMPVolumes ON tbsolic_saidas_volume.id_volume_saida = tbTMPVolumes.id_volume_saida 
         GROUP BY tbTMPVolumes.cod_emp, tbTMPVolumes.cod_fil, 
                  tbTMPVolumes.ano_solic, tbTMPVolumes.num_solic
      );
    
      SELECT NOW() INTO @Time1;
      /*******************************************************************
      # Selecionar as informações da GSM
      *******************************************************************/
      # INFORMAÇÕES DO TOPO DA GSM
      SELECT tTabelaComTexto.Coluna05 AS DocEntry, tTabelaComTexto.Coluna06 AS Doctipo
            ,tbintegraSAP_Doc.IdPicking, tbintegraSAP_Doc.IdPickingAnt
            ,tbintegraSAP_Doc.DocNum, tbintegraSAP_Doc.BPLId
            ,topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic
            ,topo.data_solic, topo.data_saida, topo.dthr_acons, topo.num_nf AS num_pedido
            ,CONCAT(tbViagens.cod_emp,'/',tbViagens.cod_fil,'-',tbViagens.ano_viagem,'.',tbViagens.num_viagem) AS NumViagem
            ,tbRotas.descr_rota RotaCliente
            ,tbDest.hora1_entrega Janela01
            ,tbDest.hora2_entrega Janela02
            ,tbDest.hora3_entrega Janela03
            ,tbDest.hora4_entrega Janela04
            ,CONCAT(tbViagens.cod_emp,'/',tbViagens.cod_fil,'-',tbViagens.ano_viagem,'.',tbViagens.num_viagem,'=>',tbRotas.descr_rota) RefViagem
            ,IF(of_logistica.fnStatusBaixaEntrega(tbEntregas.status_baixa)='Em Aberto',
                     IF(topo.status_processo>=9,of_logistica.fnStatusBaixaEntrega(tbEntregas.status_baixa),
                                                of_logistica.fnStatusSaidaWms(topo.status_processo)),
                     of_logistica.fnStatusBaixaEntrega(tbEntregas.status_baixa)) StatusEntrega
            ,IFNULL(tbViagens.cnpj_transportador,topo.cnpj_cpf_transp) CodTranspTMS
            ,tbintegraSAP_Doc.CnpjTransp CodTranspOriginal
            ,topo.observ_solic, topo.observ_conf01, topo.status_processo
            ,of_logistica.fnStatusSaidaWms(topo.status_processo) status_processoAux
            #Liberação Inicio Processo de Separação, Picking
            ,topo.dthr_armazem, topo.dthr_armazem_picking, topo.dthr_confer, topo.dthr_confirm
            #Inicio Processo de Separação, Picking
            ,topo.dthr_inicio_geral, topo.dthr_inicio_picking, topo.dthr_inicio_carregamento
            ,xcampo_qtde_volumes
#Totais 1 (OK)
###
            ,(SELECT SUM(tbItem.real_vol) FROM of_logistica.tbsolic_saidas_item tbItem
              WHERE tbItem.cod_emp  = topo.cod_emp
                AND tbItem.cod_fil   = topo.cod_fil
                AND tbItem.ano_solic = topo.ano_solic
                AND tbItem.num_solic = topo.num_solic) QtdeVolumes
            ,(SELECT COUNT(DISTINCT tbVolumesTopo.id_volume_saida) 
               FROM of_logistica.tbsolic_saidas_volume tbVolumesTopo
               INNER JOIN of_logistica.tbsolic_saidas_volume_item tbVolumes ON
                      tbVolumesTopo.id_volume_saida = tbVolumes.id_volume_saida
               WHERE tbVolumes.cod_emp  = topo.cod_emp
                AND tbVolumes.cod_fil   = topo.cod_fil
                AND tbVolumes.ano_solic = topo.ano_solic
                AND tbVolumes.num_solic = topo.num_solic
                #AND tbVolumes.num_item  = ite.num_item
              ) QtdeVolumesPedido
###
            ,topo.qtde_volume_checkout QtdeVolManual
            ,topo.peso_liq_checkout PesoLiqManual
            ,topo.peso_brt_checkout PesoBrtManual
            ,topo.chave_integracao
#Totais 2 (OK)
###
            ,(SELECT SUM(IFNULL(tbAcons.qtde_peso2,0)) FROM of_logistica.tbsolic_saidas_acons tbAcons
              WHERE tbAcons.cod_emp   = topo.cod_emp
                AND tbAcons.cod_fil   = topo.cod_fil
                AND tbAcons.ano_solic = topo.ano_solic
                AND tbAcons.num_solic = topo.num_solic
             ) TotalPesoLiq
            ,(SELECT SUM(IFNULL(tbAcons.qtde_pbrt2,0)) FROM of_logistica.tbsolic_saidas_acons tbAcons
              WHERE tbAcons.cod_emp   = topo.cod_emp
                AND tbAcons.cod_fil   = topo.cod_fil
                AND tbAcons.ano_solic = topo.ano_solic
                AND tbAcons.num_solic = topo.num_solic
             ) TotalPesoBruto
###
             ,tbintegraSAP_Doc.WhareHouse
             ,tbintegraSAP_Doc.WhareHouseTransf
             ,tbintegraSAP_Doc.CardCode
             ,tbintegraSAP_Doc.CardName
             ,CONCAT(tbintegraSAP_Doc.StreetS," - ",tbintegraSAP_Doc.CityS,"-",tbintegraSAP_Doc.StateS,"-",tbintegraSAP_Doc.CountryS,
                     " CEP:",tbintegraSAP_Doc.ZipCodeS) AS Address 
#Totais 3 (OK)
###
             ,IF(xemb_faturamento <> "", xemb_faturamento,
                 fnContarEmbalagens(
                    (SELECT GROUP_CONCAT(tbsolic_saidas_volume.id_volume_saida,IFNULL(sigla_insumo,"vol")) Embalagens
                     FROM of_logistica.tbsolic_saidas_volume_item 
                     INNER JOIN of_logistica.tbsolic_saidas_volume ON 
                         tbsolic_saidas_volume.id_volume_saida = tbsolic_saidas_volume_item.id_volume_saida
                     LEFT JOIN of_logistica.tbwms_insumo ON 
                          tbwms_insumo.id_insumo = tbsolic_saidas_volume.id_insumo
                     WHERE topo.cod_emp = tbsolic_saidas_volume_item.cod_emp
                       AND topo.cod_fil = tbsolic_saidas_volume_item.cod_fil
                       AND topo.ano_solic = tbsolic_saidas_volume_item.ano_solic
                       AND topo.num_solic = tbsolic_saidas_volume_item.num_solic) ) 
               ) Embalagens
###
#Totais 4 (Tabela temporária OK)
###
             ,(SELECT PesoInsumos
               FROM tbTMPPesosInsumos
               WHERE tbTMPPesosInsumos.cod_emp = topo.cod_emp 
                 AND tbTMPPesosInsumos.cod_fil = topo.cod_fil
                 AND tbTMPPesosInsumos.ano_solic = topo.ano_solic
                 AND tbTMPPesosInsumos.num_solic = topo.num_solic
               ) PesoInsumos
###
            ,RESULTADO, MENSAGEM
      FROM of_logistica.tbsolic_saidas topo
      LEFT JOIN of_logistica.tbprog_entregas tbEntregas ON
                tbEntregas.chave_integracao = topo.chave_integracao
      LEFT JOIN of_logistica.tbviagens tbViagens ON 
                tbViagens.cod_emp    = tbEntregas.cod_emp 
            AND tbViagens.cod_fil    = tbEntregas.cod_fil
            AND tbViagens.ano_viagem = tbEntregas.ano_viagem
            AND tbViagens.num_viagem = tbEntregas.num_viagem
      LEFT JOIN of_logistica.tbdestinatarios tbDest ON 
                tbDest.id_destinatario = tbEntregas.id_destinatario
      LEFT JOIN of_logistica.tbrotas tbRotas ON
                tbRotas.cod_emp  = tbDest.emp_rota
            AND tbRotas.cod_fil  = tbDest.fil_rota
            AND tbRotas.cod_rota = tbDest.cod_rota                
      INNER JOIN tTabelaComTexto ON
            tTabelaComTexto.Coluna01 = topo.cod_emp
            AND tTabelaComTexto.Coluna02 = topo.cod_fil
            AND tTabelaComTexto.Coluna03 = topo.ano_solic
            AND tTabelaComTexto.Coluna04 = topo.num_solic
      INNER JOIN tbintegraSAP_Doc ON 
                tbintegraSAP_Doc.cod_emp = topo.cod_emp
            AND tbintegraSAP_Doc.cod_fil = topo.cod_fil
            AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
            AND tbintegraSAP_Doc.num_solic = topo.num_solic
            AND tbintegraSAP_Doc.TipoDocSLIN = 'S';
         
      #select "Teste1"; leave bloco1;
      SELECT NOW() INTO @Time2;
         
      # INFORMAÇÕES DOS ITENS DA GSM
      SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, tbintegraSAP_DocItem.LineNum, 
             tbintegraSAP_DocPicking.PkLineNum LineNumPk, #tbintegraSAP_DocItem.LineNumPk,
             xflg_permite_PVParcial, tbintegraSAP_DocItem.Usage_,
            tbintegraSAP_DocItem.BaseQty, tbintegraSAP_DocItem.Price, 
            tbintegraSAP_DocItem.unitMsr,
            tbintegraSAP_DocItem.OpenInvQty,
            tbintegraSAP_DocItem.OpenInvQty/tbintegraSAP_DocItem.BaseQty AS B1_FatorEmbalagem,
            tbintegraSAP_DocItem.ManBtchNum, tbintegraSAP_DocItem.ManSerNum,
            tbintegraSAP_DocItem.DocEntryOrdemProducao, tbintegraSAP_DocItem.DocNumOrdemProducao,
            #IF(IFNULL(tbintegraSAP_DocItem.NumInSale,1)=0,1,tbintegraSAP_DocItem.NumInSale) AS FatorConvSAP,
            #tbintegraSAP_DocItem.buyUnitMsr, tbintegraSAP_DocItem.salUnitMsr, tbintegraSAP_DocItem.invntryUom,
            #IF(IFNULL(prod.fator_conv_vendas,0)=0,1,prod.fator_conv_vendas) AS FatorConvSAP,
            IF(IFNULL(tbintegraSAP_DocItem.OpenInvQty,0) > 0, 
              tbintegraSAP_DocItem.OpenInvQty / tbintegraSAP_DocItem.BaseQty,
                 IF(IFNULL(tbintegraSAP_DocItem.NumInSale,1)=0,1,tbintegraSAP_DocItem.NumInSale))  AS FatorConvSAP,
            #prod.emb_compras buyUnitMsr, prod.emb_vendas salUnitMsr, prod.emb_estoque_cli invntryUom,
            tbintegraSAP_DocItem.buyUnitMsr, tbintegraSAP_DocItem.salUnitMsr, tbintegraSAP_DocItem.invntryUom,
            ite.num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
            ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
            #
            ite.local_geral, ite.local_picking,
            IFNULL(ite.qtde_est,0) qtde_est, ite.qtde_vol, ite.qtde_frac, ite.pliq_item,		#Qtde Pedido
            ite.real_est, ite.real_vol, ite.real_frac, ite.real_peso,		#Qtde Aconselhada
            ite.real_est2, ite.real_vol2, ite.real_frac2, ite.real_peso2,	#Qtde Separação
            ite.real_est3, ite.real_vol3, ite.real_frac3, ite.real_peso3,	#Qtde Conferencia / Picking
            ite.real_est4, ite.real_vol4, ite.real_frac4, ite.real_peso4,	#Qtde Carregamento
            ite.real_est5, ite.real_vol5, ite.real_frac5, ite.real_peso5,	#Qtde check-carregamento
            # Alterado (2024-11-18) subSelect, agora utilizando tbTMPVolumes
            (SELECT GROUP_CONCAT(tbTMPVolumes.id_volume_saida)
             FROM tbTMPVolumes 
             WHERE tbTMPVolumes.cod_emp   = ite.cod_emp
               AND tbTMPVolumes.cod_fil   = ite.cod_fil
               AND tbTMPVolumes.ano_solic = ite.ano_solic
               AND tbTMPVolumes.num_solic = ite.num_solic
               AND tbTMPVolumes.num_item  = ite.num_item) IdVolumesCheckout,
            # Alterado (2024-11-18)subSelect, agora utilizando tbTMPVolumes2
            (SELECT SUM(tbTMPVolumes2.qtde_sep_est)
             FROM tbTMPVolumes2 
             WHERE tbTMPVolumes2.cod_emp   = ite.cod_emp
               AND tbTMPVolumes2.cod_fil   = ite.cod_fil
               AND tbTMPVolumes2.ano_solic = ite.ano_solic
               AND tbTMPVolumes2.num_solic = ite.num_solic
               AND tbTMPVolumes2.num_item  = ite.num_item) QtdeVolCheckout,
            #			
            ite.dthr_aconselhamento, ite.dthr_retorno_wms,
            ite.dthr_inicio_baixa_geral, ite.dthr_inicio_picking_carga, ite.dthr_inicio_carregamento,
            ite.dthr_final_baixa_geral, ite.dthr_final_picking_carga, ite.dthr_final_carregamento				
            ,topo.chave_integracao
            ,prod.flg_obriga_lote_fornecedor
            ,IF(tbintegraSAP_Doc.DocTipo='TD-S' AND xflg_agrupa_transf=1,1,0) xflg_agrupa_transf
            ,tbintegraSAP_DocItem.BaseQty / (SELECT SUM(tbDocItem.BaseQty) FROM tbintegraSAP_DocItem tbDocItem
                  WHERE tbintegraSAP_DocItem.DocTipo = tbDocItem.DocTipo
                    AND tbintegraSAP_DocItem.DocEntry = tbDocItem.DocEntry
                    AND tbintegraSAP_DocItem.ItemCode = tbDocItem.ItemCode
                  ) AS FatorAgrup
            ,RESULTADO, MENSAGEM
      FROM of_logistica.tbsolic_saidas topo
      INNER JOIN tbintegraSAP_Doc ON 
                tbintegraSAP_Doc.cod_emp = topo.cod_emp
            AND tbintegraSAP_Doc.cod_fil = topo.cod_fil
            AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
            AND tbintegraSAP_Doc.num_solic = topo.num_solic
            AND tbintegraSAP_Doc.TipoDocSLIN = "S"
      INNER JOIN of_logistica.tbsolic_saidas_item ite ON
            ite.cod_emp = topo.cod_emp
            AND ite.cod_fil = topo.cod_fil
            AND ite.ano_solic = topo.ano_solic
            AND ite.num_solic = topo.num_solic
      INNER JOIN of_logistica.tbprodutos prod ON
            prod.cnpj_cpf = ite.cnpj_cpf_dep
            AND prod.cod_produto = ite.cod_produto
      INNER JOIN tbintegraSAP_DocItem ON 
                tbintegraSAP_DocItem.cod_emp = ite.cod_emp
            AND tbintegraSAP_DocItem.cod_fil = ite.cod_fil
            AND tbintegraSAP_DocItem.ano_solic = ite.ano_solic
            AND tbintegraSAP_DocItem.num_solic = ite.num_solic
            AND tbintegraSAP_DocItem.num_item = ite.num_item
            AND tbintegraSAP_DocItem.DocTipo  = tbintegraSAP_Doc.DocTipo
      #@Reviser David Ruy < 2022-03-21>
      #Retornar apenas as linhas que foram geradas no picking (tbintegraSAP_DocPicking)
      INNER JOIN tbintegraSAP_DocPicking ON 
                 tbintegraSAP_DocPicking.IdPicking  = tbintegraSAP_Doc.idPicking
             AND tbintegraSAP_DocPicking.DocLineNum = tbintegraSAP_DocItem.LineNum
      INNER JOIN tTabelaComTexto ON
            tTabelaComTexto.Coluna01 = topo.cod_emp
            AND tTabelaComTexto.Coluna02 = topo.cod_fil
            AND tTabelaComTexto.Coluna03 = topo.ano_solic
            AND tTabelaComTexto.Coluna04 = topo.num_solic
      #WHERE TRUE; #ite.qtde_nf > 0;
      WHERE IFNULL(tbintegraSAP_DocItem.StatusItem,0) <= 2;
      #select "Teste2"; leave bloco1;
      SELECT NOW() INTO @Time3;
      DROP TEMPORARY TABLE IF EXISTS tbTMPVolumes;
      DROP TEMPORARY TABLE IF EXISTS tbTMPVolumes2;
      DROP TEMPORARY TABLE IF EXISTS tbTMPPesosInsumos;
   
      # INFORMAÇÕES DAS UA´S DA GSM
      # @Reviser David Ruy <2020-11-18>
      # Checa se existe a tabela tbsolic_saidas_item_loteAux (Lotes selecionados pelo separador)
      # @Reviser David Ruy <2024-11-18>
      # Só processa o tbsolic_saidas_item_loteAux se qtde registros  > 0
      # @Reviser David Ruy <2025-07-21>
      # Não utiliza mais tbsolic_saidas_item_loteAux
      IF FALSE THEN
      #IF EXISTS (SELECT 1 
      #           FROM INFORMATION_SCHEMA.TABLES
      #           WHERE TABLE_SCHEMA = 'of_logistica'
      #             AND table_name   = 'tbsolic_saidas_item_loteAux') 
      #   AND EXISTS (SELECT 1 FROM of_logistica.tbsolic_saidas_item_loteAux LIMIT 1) THEN
         SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, tbintegraSAP_DocItem.LineNum, tbintegraSAP_DocItem.LineNumPk,
            ite.num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
            ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
            #
            CONCAT(acons.num_lote,acons.sequencia_lote) AS NumUA,
            IFNULL(tbLoteAux.num_lote, tbwms_estoque.num_lote_cli) num_lote_cli,
            SUM(acons.qtde_est) qtde_est, SUM(acons.qtde_vol) qtde_vol, SUM(acons.qtde_frac) qtde_frac, SUM(acons.qtde_peso) qtde_peso,		#Qtde Aconselhada
            IF(tbLoteAux.num_lote IS NULL, SUM(acons.qtde_est2), tbLoteAux.qtde_est) qtde_est2, 
            IF(tbLoteAux.num_lote IS NULL, SUM(acons.qtde_vol2), tbLoteAux.qtde_vol) qtde_vol2, 
            IF(tbLoteAux.num_lote IS NULL, SUM(acons.qtde_frac2), tbLoteAux.qtde_frac) qtde_frac2, 
            IF(tbLoteAux.num_lote IS NULL, SUM(acons.qtde_peso2), tbLoteAux.qtde_peso) qtde_peso2,	#Qtde Separada
            SUM(acons.qtde_est3) qtde_est3, SUM(acons.qtde_vol3) qtde_vol3, SUM(acons.qtde_frac3) qtde_frac3, SUM(acons.qtde_peso3) qtde_frac3,	#(*) Qtde Conferencia/Picking Carga
            #		
            acons.dthr_conf, acons.dthr_conf_picking, acons.dthr_carregamento
            ,topo.chave_integracao
            ,"SIM" LoteForcado
            ,RESULTADO, MENSAGEM
         FROM of_logistica.tbsolic_saidas topo
         LEFT JOIN of_logistica.tbsolic_saidas_item ite ON
               ite.cod_emp = topo.cod_emp
               AND ite.cod_fil = topo.cod_fil
               AND ite.ano_solic = topo.ano_solic
               AND ite.num_solic = topo.num_solic	
         INNER JOIN tbintegraSAP_Doc ON 
                   tbintegraSAP_Doc.cod_emp = topo.cod_emp
               AND tbintegraSAP_Doc.cod_fil = topo.cod_fil
               AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
               AND tbintegraSAP_Doc.num_solic = topo.num_solic
               AND tbintegraSAP_Doc.TipoDocSLIN = 'S'      
         INNER JOIN tbintegraSAP_DocItem ON 
                   tbintegraSAP_DocItem.cod_emp = ite.cod_emp
               AND tbintegraSAP_DocItem.cod_fil = ite.cod_fil
               AND tbintegraSAP_DocItem.ano_solic = ite.ano_solic
               AND tbintegraSAP_DocItem.num_solic = ite.num_solic
               AND tbintegraSAP_DocItem.num_item = ite.num_item
               AND tbintegraSAP_DocItem.DocTipo  = tbintegraSAP_Doc.DocTipo
         LEFT JOIN of_logistica.tbprodutos prod ON
               prod.cnpj_cpf = ite.cnpj_cpf_dep
               AND prod.cod_produto = ite.cod_produto
         LEFT JOIN of_logistica.tbsolic_saidas_acons acons ON
               acons.cod_emp = ite.cod_emp
               AND acons.cod_fil = ite.cod_fil
               AND acons.ano_solic = ite.ano_solic
               AND acons.num_solic = ite.num_solic			
               AND acons.num_item  = ite.num_item
         LEFT JOIN of_logistica.tbsolic_saidas_item_loteAux tbLoteAux ON
                    tbLoteAux.cod_emp   = acons.cod_emp
                AND tbLoteAux.cod_fil   = acons.cod_fil
                AND tbLoteAux.ano_solic = acons.ano_solic
                AND tbLoteAux.num_solic = acons.num_solic
                AND tbLoteAux.num_item  = acons.num_item
         LEFT JOIN of_logistica.tbwms_estoque ON  
               tbwms_estoque.cod_emp = acons.cod_emp
               AND tbwms_estoque.cod_fil = acons.cod_fil
               AND tbwms_estoque.num_lote = acons.num_lote
               AND tbwms_estoque.sequencia_lote = acons.sequencia_lote
         INNER JOIN tTabelaComTexto ON
               tTabelaComTexto.Coluna01 = topo.cod_emp
               AND tTabelaComTexto.Coluna02 = topo.cod_fil
               AND tTabelaComTexto.Coluna03 = topo.ano_solic
               AND tTabelaComTexto.Coluna04 = topo.num_solic
         #WHERE TRUE #acons.qtde_est2 > 0
         WHERE acons.qtde_est2 > 0
           AND IFNULL(tbintegraSAP_DocItem.StatusItem,0) <= 2
         GROUP BY cod_emp, cod_fil, ano_solic, num_solic, 
                  IF(tbintegraSAP_Doc.DocTipo='TD-S' AND xflg_agrupa_transf=1,
                     tbintegraSAP_DocItem.LineNum,tbintegraSAP_DocItem.num_item), num_lote_cli;
                     
      ELSE
         #Seleção das UA´/Lotes
         SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, tbintegraSAP_DocItem.LineNum, tbintegraSAP_DocItem.LineNumPk,
            ite.num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
            ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
            #
            CONCAT(acons.num_lote,acons.sequencia_lote) AS NumUA,
            tbwms_estoque.num_lote_cli,
            SUM(acons.qtde_est) qtde_est, SUM(acons.qtde_vol) qtde_vol, SUM(acons.qtde_frac) qtde_frac, SUM(acons.qtde_peso) qtde_peso,		#Qtde Aconselhada
            SUM(acons.qtde_est2) qtde_est2, SUM(acons.qtde_vol2) qtde_vol2, SUM(acons.qtde_frac2) qtde_frac2, SUM(acons.qtde_peso2) qtde_peso2,	#Qtde Separada
            SUM(acons.qtde_est3) qtde_est3, SUM(acons.qtde_vol3) qtde_vol3, SUM(acons.qtde_frac3) qtde_frac3, SUM(acons.qtde_peso3) qtde_frac3,	#(*) Qtde Conferencia/Picking Carga
            #		
            acons.dthr_conf, acons.dthr_conf_picking, acons.dthr_carregamento
            ,topo.chave_integracao
            ,"NÃO" LoteForcado
            ,RESULTADO, MENSAGEM
         FROM of_logistica.tbsolic_saidas topo
         LEFT JOIN of_logistica.tbsolic_saidas_item ite ON
               ite.cod_emp = topo.cod_emp
               AND ite.cod_fil = topo.cod_fil
               AND ite.ano_solic = topo.ano_solic
               AND ite.num_solic = topo.num_solic	
         INNER JOIN tbintegraSAP_Doc ON 
                   tbintegraSAP_Doc.cod_emp = topo.cod_emp
               AND tbintegraSAP_Doc.cod_fil = topo.cod_fil
               AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
               AND tbintegraSAP_Doc.num_solic = topo.num_solic
               AND tbintegraSAP_Doc.TipoDocSLIN = 'S'      
         INNER JOIN tbintegraSAP_DocItem ON 
                   tbintegraSAP_DocItem.cod_emp = ite.cod_emp
               AND tbintegraSAP_DocItem.cod_fil = ite.cod_fil
               AND tbintegraSAP_DocItem.ano_solic = ite.ano_solic
               AND tbintegraSAP_DocItem.num_solic = ite.num_solic
               AND tbintegraSAP_DocItem.num_item = ite.num_item
               AND tbintegraSAP_DocItem.DocTipo  = tbintegraSAP_Doc.DocTipo
         LEFT JOIN of_logistica.tbprodutos prod ON
               prod.cnpj_cpf = ite.cnpj_cpf_dep
               AND prod.cod_produto = ite.cod_produto
         LEFT JOIN of_logistica.tbsolic_saidas_acons acons ON
               acons.cod_emp = ite.cod_emp
               AND acons.cod_fil = ite.cod_fil
               AND acons.ano_solic = ite.ano_solic
               AND acons.num_solic = ite.num_solic			
               AND acons.num_item  = ite.num_item
         LEFT JOIN of_logistica.tbwms_estoque ON  
               tbwms_estoque.cod_emp = acons.cod_emp
               AND tbwms_estoque.cod_fil = acons.cod_fil
               AND tbwms_estoque.num_lote = acons.num_lote
               AND tbwms_estoque.sequencia_lote = acons.sequencia_lote
         INNER JOIN tTabelaComTexto ON
               tTabelaComTexto.Coluna01 = topo.cod_emp
               AND tTabelaComTexto.Coluna02 = topo.cod_fil
               AND tTabelaComTexto.Coluna03 = topo.ano_solic
               AND tTabelaComTexto.Coluna04 = topo.num_solic
         WHERE acons.qtde_est2 > 0
           AND IFNULL(tbintegraSAP_DocItem.StatusItem,0) <= 2
         GROUP BY ite.cod_emp, ite.cod_fil, ite.ano_solic, ite.num_solic, 
                  IF(tbintegraSAP_Doc.DocTipo='TD-S' AND xflg_agrupa_transf=1,
                     tbintegraSAP_DocItem.LineNum,tbintegraSAP_DocItem.num_item), num_lote_cli;
      END IF;
      #select "Teste3"; leave bloco1;
      SELECT NOW() INTO @Time4;
   END IF;
   
   SELECT @Time0, @Time1, @Time2, @Time3, @Time4,
    TIMEDIFF(@Time1,@Time0) "CriarTMP",
    TIMEDIFF(@Time2,@Time1) "Topo",
    TIMEDIFF(@Time3,@Time2) "Item",
    TIMEDIFF(@Time4,@Time3) "Acons";
       
   DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_SAIDAS;
   DROP TEMPORARY TABLE IF EXISTS tTabelaComTexto;
    
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      SELECT RESULTADO, MENSAGEM;
   ELSE    
      SET RESULTADO = 1;
      #SET MENSAGEM  = 'Processo Realizado com sucesso!';
   END IF;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_RetornoTMS.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_RetornoTMS`$$

CREATE PROCEDURE `PROC_INTEGRA_RetornoTMS`(
   IN oCodUsuario				VARCHAR(10),
   IN oTipoRetorno   INT                                  
)
BLOCO1:BEGIN
   /*******************************************************************************************
   #@Author David Ruy <2021-11-29>
    * PARÂMETRO oTipoRetorno DETERMINA 
    *   0 = Retorna os Status de Pedidos TMS
    *   1 = Retorna os Pedidos no TMS sem chave_nfe
    *   2 = Retorna os Status de Pedidos Campo StatusAux_Cliente  
   #@Reviser David Ruy <2023-05-02> Status Picking para status_processo in (6,7,8,9)
   #@Reviser David Ruy <2024-11-21> Atualizar Novo_StatusCliente (fnStatusCliente)
   #@Reviser David Ruy <2025-10-24> Selecionar PlacaVeiculo (Atualizar orders->VehiclePlate)
   ********************************************************************************************/
   
   DECLARE excecao 	          INT DEFAULT 0;
   DECLARE RESULTADO          INT DEFAULT 1;
   DECLARE MENSAGEM           VARCHAR(500);
   DECLARE xDias              INT DEFAULT 90;   #Qtde de Dias Status TMS
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   DECLARE xDocEntry           INT;
   DECLARE xDocTipo            VARCHAR(10); 
   DECLARE xstatus_processo    VARCHAR(10);
   DECLARE xstatus_picking     VARCHAR(10);
   DECLARE xstatus_entre       VARCHAR(10);
   DECLARE xstatus_baixa       VARCHAR(10);
   DECLARE xStatusEntrega      VARCHAR(100);
   DECLARE xStatusArmazem      VARCHAR(100);
   DECLARE xStatusCliente      VARCHAR(2000);
   
   
   
   IF oTipoRetorno = 0 THEN 
      #Cria tabela temporária com as GSM recebidas que serão separadas
      DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_B1;
      CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_B1 AS 
         SELECT DISTINCT DocEntry, DocTipo, DocNum, DocDate,
                tbintegraSAP_Doc.StatusDoc AS StatusDoc,
                tbRotas.descr_rota RotaCliente,
                tbSaidas.status_processo, tbSaidas.status_picking,
                tbEntregas.status_entre,  tbEntregas.status_baixa, 
                IF(tbSaidas.status_processo <= 5, tbSaidas.status_processo, 
                      CONCAT(tbSaidas.status_picking)) AS StatusProcessoAux,
                CASE IFNULL(tbEntregas.status_entre,-1)
                   WHEN -1 THEN "A roteirizar"
                   WHEN 0 THEN "Em Roteirizacao"
                   WHEN 1 AND tbEntregas.status_baixa IS NULL THEN
                              IF(tbViagens.dthr_liberacao IS NULL, "Roteirizado - Entrega em aberto",
                                                                   "Em Rota para entrega") 
                ELSE of_logistica.fnStatusBaixaEntrega(tbEntregas.status_baixa)
                END AS StatusEntrega,
                IF(tbSaidas.status_processo < 5, "Em Preparacao", 
                      CONCAT('',of_logistica.fnStatusPickingWms(tbSaidas.status_picking))) AS StatusArmazem,
#                   IF(tbSaidas.status_processo IN (6,7,8,9), 
#                      CONCAT('pk=>',of_logistica.fnStatusPickingWms(tbSaidas.status_picking)),
#                      CONCAT('sep=>',of_logistica.fnStatusSaidaWms(tbSaidas.status_processo)))) AS StatusArmazem,
                SPACE(200) AS StatusIntegracao, SPACE(200) AS StatusIntegracaoAux,
                tbintegraSAP_Doc.StatusAux_Cliente  AS StatusAux,
                tbintegraSAP_Doc.StatusAux_Cliente  AS StatusAux_Cliente,
                SPACE(200) AS Novo_StatusCliente,
                IF(tbViagens.data_conf IS NULL, "",
                   CONCAT(tbViagens.cod_emp,'/',tbViagens.cod_fil,'-',tbViagens.ano_viagem,'.',tbViagens.num_viagem,'=>',
                   IFNULL(tbRotas.descr_rota,IFNULL(tbRotas2.descr_rota,"")))) RefViagem,
                IFNULL(tbViagens.cnpj_transportador,tbSaidas.cnpj_cpf_transp) CodTranspTMS,
                tbViagens.data_conf, tbViagens.dthr_liberacao,
                tbViagens.placa_veiculo PlacaVeiculo,
                tbintegraSAP_Doc.RefViagem RefViagemANT,
                tbintegraSAP_Doc.StatusEntrega StatusEntregaANT,
                tbintegraSAP_Doc.StatusArmazem StatusArmazemANT,
                tbNFClientes.chave_nfe ChaveNFe
/**********************************/
                , CONCAT(tbSaidas.status_processo,'.',status_entre,tbEntregas.status_baixa,'.',of_logistica.fnStatusBaixaEntrega(tbEntregas.status_baixa)) AS StatusClienteAux                
                , CAST( ( SELECT SUM(IFNULL(tbSaidasItem.real_est2, 0))
                            FROM of_logistica.tbsolic_saidas_item tbSaidasItem           
                           WHERE tbSaidasItem.cod_emp        = tbSaidas.cod_emp
                             AND tbSaidasItem.cod_fil        = tbSaidas.cod_fil
                             AND tbSaidasItem.ano_solic      = tbSaidas.ano_solic
                             AND tbSaidasItem.num_solic      = tbSaidas.num_solic
                         )
                        AS DECIMAL(18,6)
                      )                                AS QtdeSep
                , CAST( ( SELECT SUM(IFNULL(tbSaidasVolItem.qtde_sep_est, 0))
                            FROM of_logistica.tbsolic_saidas_volume_item tbSaidasVolItem
                           WHERE tbSaidasVolItem.cod_emp     = tbSaidas.cod_emp
                             AND tbSaidasVolItem.cod_fil     = tbSaidas.cod_fil
                             AND tbSaidasVolItem.ano_solic   = tbSaidas.ano_solic
                             AND tbSaidasVolItem.num_solic   = tbSaidas.num_solic
                        )
                        AS DECIMAL(18,6)
                      )                                AS  QtdeMontagemCheckout
                , CAST( ( SELECT SUM(IFNULL(tbSaidasVolItem.qtde_conf_est2, 0))
                            FROM of_logistica.tbsolic_saidas_volume_item tbSaidasVolItem
                           WHERE tbSaidasVolItem.cod_emp     = tbSaidas.cod_emp
                             AND tbSaidasVolItem.cod_fil     = tbSaidas.cod_fil
                             AND tbSaidasVolItem.ano_solic   = tbSaidas.ano_solic
                             AND tbSaidasVolItem.num_solic   = tbSaidas.num_solic
                        )
                        AS DECIMAL(18,6)
                      )                                AS  QtdeConferenciaCheckout
                , CAST( ( SELECT SUM(IFNULL(tbSaidasVolItem.qtde_conf_est3, 0))
                            FROM of_logistica.tbsolic_saidas_volume_item tbSaidasVolItem
                           WHERE tbSaidasVolItem.cod_emp     = tbSaidas.cod_emp
                             AND tbSaidasVolItem.cod_fil     = tbSaidas.cod_fil
                             AND tbSaidasVolItem.ano_solic   = tbSaidas.ano_solic
                             AND tbSaidasVolItem.num_solic   = tbSaidas.num_solic
                        )
                        AS DECIMAL(18,6)
                      )                                AS  QtdeCarregamento
/**********************************/
         FROM tbintegraSAP_Doc
         INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
               tbSaidas.cod_emp   = tbintegraSAP_Doc.cod_emp
           AND tbSaidas.cod_fil   = tbintegraSAP_Doc.cod_fil
           AND tbSaidas.ano_solic = tbintegraSAP_Doc.ano_solic
           AND tbSaidas.num_solic = tbintegraSAP_Doc.num_solic
         INNER JOIN of_logistica.tbprog_entregas tbEntregas ON
                   tbEntregas.chave_integracao = tbSaidas.chave_integracao
         INNER JOIN of_logistica.tbnf_clientes tbNFClientes ON
                   tbNFClientes.id_nf = tbEntregas.id_nf
         LEFT JOIN of_logistica.tbdestinatarios tbDest ON 
                   tbDest.id_destinatario = tbEntregas.id_destinatario
         LEFT JOIN of_logistica.tbrotas tbRotas ON
                   tbRotas.cod_emp  = tbDest.emp_rota
               AND tbRotas.cod_fil  = tbDest.fil_rota
               AND tbRotas.cod_rota = tbDest.cod_rota                
         LEFT JOIN of_logistica.tbviagens tbViagens ON 
                   tbViagens.cod_emp    = tbEntregas.cod_emp 
               AND tbViagens.cod_fil    = tbEntregas.cod_fil
               AND tbViagens.ano_viagem = tbEntregas.ano_viagem
               AND tbViagens.num_viagem = tbEntregas.num_viagem
         LEFT JOIN of_logistica.tbrotas tbRotas2 ON
                   tbRotas2.cod_emp  = tbViagens.emp_rota
               AND tbRotas2.cod_fil  = tbViagens.fil_rota
               AND tbRotas2.cod_rota = tbViagens.cod_rota                
         WHERE tbintegraSAP_Doc.DocDate > DATE_SUB(CURRENT_DATE(), INTERVAL xDias DAY)
           AND IF(tbSaidas.dthr_acons  IS NULL, TRUE,  tbSaidas.dthr_acons >= DATE_SUB(CURRENT_DATE(), INTERVAL 20 DAY))
           #and tbintegraSAP_Doc.DocNum = 199948
           AND tbintegraSAP_Doc.DocTipo IN ("PV","TD-S","NS")
           #and tbintegraSAP_Doc.DocNum in ()
           AND tbSaidas.dthr_cancelamento IS NULL
           AND (tbEntregas.status_baixa IS NULL OR 
                #DATE(tbEntregas.dthr_baixa) = CURRENT_DATE())
                DATE(tbEntregas.dthr_baixa) >= DATE_SUB(CURRENT_DATE(), INTERVAL xDias DAY) )
           #and substring(tbintegraSAP_Doc.StatusEntrega,1,1) = '_'
           AND tbSaidas.dthr_cancelamento IS NULL;
           
      #Não lista registros sem alteração de Status     
      DELETE FROM tbTMP_INTEGRA_RETORNO_B1 
      #where DocDate < '2025-02-01' -- date_sub(current_date(), interval 10 day)
      WHERE StatusEntregaANT = StatusEntrega
        AND StatusArmazemANT = StatusArmazem
        AND RefViagemANT = RefViagem
      ;
     
     #Desabilitado : Antiga rotina Mistral   
     #UPDATE tbTMP_INTEGRA_RETORNO_B1 
     #SET StatusIntegracao    = CONCAT("WMS->",StatusArmazem," / ","TMS->",StatusEntrega),
     #    StatusIntegracaoAux = IF(IF(status_processo <= 5,status_processo,status_picking) <= 5, '1 - Em Separação',
     #                            IF(status_processo = 11, '3 - Cancelado',
     #                               IF(status_entre IS NULL,
     #                                  '2 - Separação Concluída', 
     #                                  IF(status_entre = 0, '4 - Em Roteirização',
     #                                       IF(status_baixa IS NULL, '5 - Em Rota para Entrega',
     #                                          CONCAT(status_baixa+6,' - ',StatusEntrega))))));
     UPDATE tbTMP_INTEGRA_RETORNO_B1 
     SET StatusIntegracao    = CONCAT("WMS->",StatusArmazem," / ","TMS->",StatusEntrega);
         
         
     #@Reviser David Ruy <2024-03-04> Solicitação Mistral
     #Colocar a regra em tabela
     #UPDATE tbTMP_INTEGRA_RETORNO_B1 
     #SET StatusIntegracao = StatusIntegracaoAux;         
                                           
     /*************************************************************************/
     UPDATE tbTMP_INTEGRA_RETORNO_B1 SET Novo_StatusCliente = "";
     WHILE EXISTS (SELECT 1 FROM tbTMP_INTEGRA_RETORNO_B1 WHERE Novo_StatusCliente = "") DO
        
        SELECT DocEntry, DocTipo, status_processo, status_picking, status_entre, status_baixa, StatusEntrega, StatusArmazem
        INTO xDocEntry, xDocTipo, xstatus_processo, xstatus_picking, xstatus_entre, xstatus_baixa, xStatusEntrega, xStatusArmazem
        FROM tbTMP_INTEGRA_RETORNO_B1 
        WHERE Novo_StatusCliente = "" LIMIT 1;
     
        #select xstatus_processo,xstatus_entre,xstatus_baixa,xStatusEntrega;
        SET @xStrCase = fnStatusCliente(xstatus_processo,xstatus_entre,xstatus_baixa);
        SET @xStrCase = REPLACE(@xStrCase, 'oStatusProcesso', 'status_processo');
        SET @xStrCase = REPLACE(@xStrCase, 'oStatusEntrega', 'status_entre');
        SET @xStrCase = REPLACE(@xStrCase, 'oStatusBaixa', 'status_baixa');
        
        SET @xStrCase = CONCAT(@xStrCase, ' from tbTMP_INTEGRA_RETORNO_B1 ',
                 ' where DocTipo = "',xDocTipo,'" AND DocEntry = ',xDocEntry);
        #SELECT @xStrCase;
        #leave bloco1;
               
        PREPARE SQL_StatusCliente FROM @xStrCase;
        EXECUTE SQL_StatusCliente; #USING @a, @b;
        DEALLOCATE PREPARE SQL_StatusCliente;
               
        #@Reviser David Ruy <2024-03-04> Solicitação Mistral
        #Colocar a regra em tabela
        UPDATE tbTMP_INTEGRA_RETORNO_B1 
        SET Novo_StatusCliente = @xStatusCliente
        WHERE DocTipo  = xDocTipo
          AND DocEntry = xDocEntry;
     END WHILE;
     /*************************************************************************/
      
      SELECT * FROM tbTMP_INTEGRA_RETORNO_B1;
      
      DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_B1;
      #DROP TEMPORARY TABLE IF EXISTS tTabelaComTexto;
      
   ELSEIF oTipoRetorno = 1 THEN
   
      #Lista os registros tbnf_clientes.chave_nfe Nulos ou Não Localizados
      SELECT tbintegraSAP_Doc.chave_integracao, DocTipo, DocNum, DocEntry, data_solic, dthr_retorno_integracao, chave_nfe
      FROM tbintegraSAP_Doc
      INNER JOIN of_logistica.tbnf_clientes ON
               tbnf_clientes.chave_integracao = tbintegraSAP_Doc.chave_integracao
      INNER JOIN of_logistica.tbsolic_saidas ON
               tbsolic_saidas.chave_integracao = tbintegraSAP_Doc.chave_integracao
      WHERE tbsolic_saidas.dthr_retorno_integracao IS NOT NULL
        #AND IFNULL(tbnf_clientes.chave_nfe,"IntegraSAP - Chave não localizada") = "IntegraSAP - Chave não localizada";
        AND IFNULL(tbnf_clientes.chave_nfe,"") = ""
        AND tbsolic_saidas.dthr_cancelamento IS NULL
        AND tbsolic_saidas.dthr_confirm IS NOT NULL
      ORDER BY dthr_retorno_integracao DESC
      #limit 200
      ;
      
   END IF;
    
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      SELECT RESULTADO, MENSAGEM;
   ELSE    
      SET RESULTADO = 1;
      #SET MENSAGEM  = 'Processo Realizado com sucesso!';
   END IF;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_RetornoTracking.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_RetornoTracking`$$

CREATE PROCEDURE `PROC_INTEGRA_RetornoTracking`()
BLOCO1:BEGIN
   /*******************************************************************************************
   #@Author David Ruy <2021-11-29>
    * PARÂMETRO oTipoRetorno DETERMINA 
    *   0 = Retorna os Status de Pedidos TMS
    *   1 = Retorna os Pedidos no TMS sem chave_nfe
    *   2 = Retorna os Status de Pedidos Campo StatusAux_Cliente  
   #@Reviser David Ruy <2023-05-02> Status Picking para status_processo in (6,7,8,9)
   #@Reviser David Ruy <2024-11-21> Atualizar Novo_StatusCliente (fnStatusCliente)
   ********************************************************************************************/
   
   DECLARE excecao 	          INT DEFAULT 0;
   DECLARE RESULTADO          INT DEFAULT 1;
   DECLARE MENSAGEM           VARCHAR(500);
   DECLARE xDias              INT DEFAULT 10;   #Qtde de Dias Status TMS
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   DECLARE xDocEntry           INT;
   DECLARE xDocTipo            VARCHAR(10); 
   DECLARE xstatus_processo    VARCHAR(10);
   DECLARE xstatus_picking     VARCHAR(10);
   DECLARE xstatus_entre       VARCHAR(10);
   DECLARE xstatus_baixa       VARCHAR(10);
   DECLARE xStatusEntrega      VARCHAR(100);
   DECLARE xStatusArmazem      VARCHAR(100);
   DECLARE xStatusCliente      VARCHAR(2000);
   
   
   
      #Cria tabela temporária com as GSM recebidas que serão separadas
      DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_B1;
      CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_B1 AS 
         SELECT DISTINCT DocEntry, DocTipo, DocNum, tbintegraSAP_Doc.chave_integracao,
                tbintegraSAP_Doc.StatusDoc AS StatusDoc,
                tbRotas.descr_rota RotaCliente,
                tbSaidas.status_processo, tbSaidas.status_picking,
                tbEntregas.status_entre,  tbEntregas.status_baixa, 
                IF(tbSaidas.status_processo <= 5, tbSaidas.status_processo, 
                      CONCAT(tbSaidas.status_picking)) AS StatusProcessAux,
                CASE IFNULL(tbEntregas.status_entre,-1)
                   WHEN -1 THEN "A roteirizar"
                   WHEN 0 THEN "Em Roteirizacao"
                   WHEN 1 AND tbEntregas.status_baixa IS NULL THEN
                              IF(tbViagens.dthr_liberacao IS NULL, "Roteirizado - Entrega em aberto",
                                                                   "Em Rota para entrega") 
                ELSE of_logistica.fnStatusBaixaEntrega(tbEntregas.status_baixa)
                END AS StatusEntrega,
                IF(tbSaidas.status_processo < 5, "Em Preparacao", 
                      CONCAT('',of_logistica.fnStatusPickingWms(tbSaidas.status_picking))) AS StatusArmazem,
#                   IF(tbSaidas.status_processo IN (6,7,8,9), 
#                      CONCAT('pk=>',of_logistica.fnStatusPickingWms(tbSaidas.status_picking)),
#                      CONCAT('sep=>',of_logistica.fnStatusSaidaWms(tbSaidas.status_processo)))) AS StatusArmazem,
                SPACE(200) AS StatusIntegracao, SPACE(200) AS StatusIntegracaoAux,
                tbintegraSAP_Doc.StatusAux_Cliente  AS StatusAux,
                tbintegraSAP_Doc.StatusAux_Cliente  AS StatusAux_Cliente,
                SPACE(200) AS Novo_StatusCliente,
                IF(tbViagens.data_conf IS NULL, "",
                   CONCAT(tbViagens.cod_emp,'/',tbViagens.cod_fil,'-',tbViagens.ano_viagem,'.',tbViagens.num_viagem,'=>',
                   IFNULL(tbRotas.descr_rota,IFNULL(tbRotas2.descr_rota,"")))) RefViagem,
                IFNULL(tbViagens.cnpj_transportador,tbSaidas.cnpj_cpf_transp) CodTranspTMS,
                tbViagens.data_conf, tbViagens.dthr_liberacao,
                tbintegraSAP_Doc.RefViagem RefViagemAux,
                tbintegraSAP_Doc.StatusEntrega StatusEntregaAux,
                tbintegraSAP_Doc.StatusArmazem StatusArmazemAux
/**********************************/
                , CONCAT(tbSaidas.status_processo,'.',status_entre,tbEntregas.status_baixa,'.',of_logistica.fnStatusBaixaEntrega(tbEntregas.status_baixa)) AS StatusClienteAux                
                , CAST( ( SELECT SUM(IFNULL(tbSaidasItem.real_est2, 0))
                            FROM of_logistica.tbsolic_saidas_item tbSaidasItem           
                           WHERE tbSaidasItem.cod_emp        = tbSaidas.cod_emp
                             AND tbSaidasItem.cod_fil        = tbSaidas.cod_fil
                             AND tbSaidasItem.ano_solic      = tbSaidas.ano_solic
                             AND tbSaidasItem.num_solic      = tbSaidas.num_solic
                         )
                        AS DECIMAL(18,6)
                      )                                AS QtdeSep
                , CAST( ( SELECT SUM(IFNULL(tbSaidasVolItem.qtde_sep_est, 0))
                            FROM of_logistica.tbsolic_saidas_volume_item tbSaidasVolItem
                           WHERE tbSaidasVolItem.cod_emp     = tbSaidas.cod_emp
                             AND tbSaidasVolItem.cod_fil     = tbSaidas.cod_fil
                             AND tbSaidasVolItem.ano_solic   = tbSaidas.ano_solic
                             AND tbSaidasVolItem.num_solic   = tbSaidas.num_solic
                        )
                        AS DECIMAL(18,6)
                      )                                AS  QtdeMontagemCheckout
                , CAST( ( SELECT SUM(IFNULL(tbSaidasVolItem.qtde_conf_est2, 0))
                            FROM of_logistica.tbsolic_saidas_volume_item tbSaidasVolItem
                           WHERE tbSaidasVolItem.cod_emp     = tbSaidas.cod_emp
                             AND tbSaidasVolItem.cod_fil     = tbSaidas.cod_fil
                             AND tbSaidasVolItem.ano_solic   = tbSaidas.ano_solic
                             AND tbSaidasVolItem.num_solic   = tbSaidas.num_solic
                        )
                        AS DECIMAL(18,6)
                      )                                AS  QtdeConferenciaCheckout
                , CAST( ( SELECT SUM(IFNULL(tbSaidasVolItem.qtde_conf_est3, 0))
                            FROM of_logistica.tbsolic_saidas_volume_item tbSaidasVolItem
                           WHERE tbSaidasVolItem.cod_emp     = tbSaidas.cod_emp
                             AND tbSaidasVolItem.cod_fil     = tbSaidas.cod_fil
                             AND tbSaidasVolItem.ano_solic   = tbSaidas.ano_solic
                             AND tbSaidasVolItem.num_solic   = tbSaidas.num_solic
                        )
                        AS DECIMAL(18,6)
                      )                                AS  QtdeCarregamento
                , tbintegraSAP_Tracking.StatusAtual StatusTrackingAtual
                , tbintegraSAP_Tracking.StatusAnt StatusTrackingAnt
                , 0 AS Processado
/**********************************/
         FROM tbintegraSAP_Doc
         INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
               tbSaidas.cod_emp   = tbintegraSAP_Doc.cod_emp
           AND tbSaidas.cod_fil   = tbintegraSAP_Doc.cod_fil
           AND tbSaidas.ano_solic = tbintegraSAP_Doc.ano_solic
           AND tbSaidas.num_solic = tbintegraSAP_Doc.num_solic
         INNER JOIN of_logistica.tbprog_entregas tbEntregas ON
                   tbEntregas.chave_integracao = tbSaidas.chave_integracao
         LEFT JOIN of_logistica.tbdestinatarios tbDest ON 
                   tbDest.id_destinatario = tbEntregas.id_destinatario
         LEFT JOIN of_logistica.tbrotas tbRotas ON
                   tbRotas.cod_emp  = tbDest.emp_rota
               AND tbRotas.cod_fil  = tbDest.fil_rota
               AND tbRotas.cod_rota = tbDest.cod_rota                
         LEFT JOIN of_logistica.tbviagens tbViagens ON 
                   tbViagens.cod_emp    = tbEntregas.cod_emp 
               AND tbViagens.cod_fil    = tbEntregas.cod_fil
               AND tbViagens.ano_viagem = tbEntregas.ano_viagem
               AND tbViagens.num_viagem = tbEntregas.num_viagem
         LEFT JOIN of_logistica.tbrotas tbRotas2 ON
                   tbRotas2.cod_emp  = tbViagens.emp_rota
               AND tbRotas2.cod_fil  = tbViagens.fil_rota
               AND tbRotas2.cod_rota = tbViagens.cod_rota    
         LEFT JOIN tbintegraSAP_Tracking ON 
                   tbintegraSAP_Tracking.chave_integracao = tbintegraSAP_Doc.chave_integracao
         WHERE tbintegraSAP_Doc.DocDate > DATE_SUB(CURRENT_DATE(), INTERVAL xDias DAY)
           AND tbintegraSAP_Doc.DocTipo IN ("PV","TD-S","NS")
           #and tbintegraSAP_Doc.DocNum in ()
           AND tbSaidas.dthr_cancelamento IS NULL
           AND (tbEntregas.status_baixa IS NULL OR 
                #DATE(tbEntregas.dthr_baixa) = CURRENT_DATE())
                DATE(tbEntregas.dthr_baixa) >= DATE_SUB(CURRENT_DATE(), INTERVAL xDias DAY) )
           #and substring(tbintegraSAP_Doc.StatusEntrega,1,1) = '_'
           AND tbSaidas.dthr_cancelamento IS NULL;
           
      #Não lista registros sem alteração de Status     
      DELETE FROM tbTMP_INTEGRA_RETORNO_B1 
      WHERE StatusTrackingAtual = StatusAux_Cliente
        AND RefViagemAux = RefViagem;
     
     #Desabilitado : Antiga rotina Mistral   
     #UPDATE tbTMP_INTEGRA_RETORNO_B1 
     #SET StatusIntegracao    = CONCAT("WMS->",StatusArmazem," / ","TMS->",StatusEntrega),
     #    StatusIntegracaoAux = IF(IF(status_processo <= 5,status_processo,status_picking) <= 5, '1 - Em Separação',
     #                            IF(status_processo = 11, '3 - Cancelado',
     #                               IF(status_entre IS NULL,
     #                                  '2 - Separação Concluída', 
     #                                  IF(status_entre = 0, '4 - Em Roteirização',
     #                                       IF(status_baixa IS NULL, '5 - Em Rota para Entrega',
     #                                          CONCAT(status_baixa+6,' - ',StatusEntrega))))));
         
         
     #@Reviser David Ruy <2024-03-04> Solicitação Mistral
     #Colocar a regra em tabela
     #UPDATE tbTMP_INTEGRA_RETORNO_B1 
     #SET StatusIntegracao = StatusIntegracaoAux;         
     
     
     #select * from tbTMP_INTEGRA_RETORNO_B1;                                      
     /*************************************************************************/
     UPDATE tbTMP_INTEGRA_RETORNO_B1 SET Processado = 0;
     WHILE EXISTS (SELECT 1 FROM tbTMP_INTEGRA_RETORNO_B1 WHERE Processado = 0) DO
        
        SELECT DocEntry, DocTipo, status_processo, status_picking, status_entre, status_baixa, StatusEntrega, StatusArmazem
        INTO xDocEntry, xDocTipo, xstatus_processo, xstatus_picking, xstatus_entre, xstatus_baixa, xStatusEntrega, xStatusArmazem
        FROM tbTMP_INTEGRA_RETORNO_B1 
        WHERE Processado = 0 LIMIT 1;
     
        #select xstatus_processo,xstatus_entre,xstatus_baixa,xStatusEntrega;
        SET @xStrCase = fnStatusCliente(xstatus_processo,xstatus_entre,xstatus_baixa);
        SET @xStrCase = REPLACE(@xStrCase, 'oStatusProcesso', 'status_processo');
        SET @xStrCase = REPLACE(@xStrCase, 'oStatusEntrega', 'status_entre');
        SET @xStrCase = REPLACE(@xStrCase, 'oStatusBaixa', 'status_baixa');
        
        SET @xStrCase = CONCAT(@xStrCase, ' from tbTMP_INTEGRA_RETORNO_B1 ',
                 ' where DocTipo = "',xDocTipo,'" AND DocEntry = ',xDocEntry);
        #SELECT @xStrCase;
        #leave bloco1;
               
        PREPARE SQL_StatusCliente FROM @xStrCase;
        EXECUTE SQL_StatusCliente; #USING @a, @b;
        DEALLOCATE PREPARE SQL_StatusCliente;
               
        #@Reviser David Ruy <2024-03-04> Solicitação Mistral
        #Colocar a regra em tabela
        UPDATE tbTMP_INTEGRA_RETORNO_B1 
        SET StatusTrackingAnt = StatusTrackingAtual, 
            StatusTrackingAtual = @xStatusCliente, 
            Processado = 1
        WHERE DocTipo  = xDocTipo
          AND DocEntry = xDocEntry;
          
          
          #SELECT chave_integracao, StatusAtualTracking, StatusAntTracking, NOW(), NULL 
#		 FROM tbTMP_INTEGRA_RETORNO_B1 WHERE DocTipo  = xDocTipo AND DocEntry = xDocEntry;
#          INSERT INTO tbintegraSAP_Tracking (chave_integracao, StatusAtual, StatusAnt, dthr_inc, dthr_alt)
#		(SELECT chave_integracao, StatusAtualTracking, StatusAntTracking, NOW(), NULL 
#		 FROM tbTMP_INTEGRA_RETORNO_B1 WHERE DocTipo  = xDocTipo AND DocEntry = xDocEntry)
#	  ON DUPLICATE KEY UPDATE StatusAtual = StatusTrackingAtual, StatusAnt = StatusTrackingAnt, dthr_alt = NOW();
         
     END WHILE;
     /*************************************************************************/
     
     #Não lista registros sem alteração de Status     
	DELETE FROM tbTMP_INTEGRA_RETORNO_B1 
	WHERE StatusTrackingAnt = StatusTrackingAtual;
      
	INSERT IGNORE INTO tbintegraSAP_Tracking (chave_integracao, StatusAtual, StatusAnt, dthr_inc, dthr_alt)
	(SELECT chave_integracao, StatusTrackingAtual, StatusTrackingAnt, NOW(), NULL 
	 FROM tbTMP_INTEGRA_RETORNO_B1);
	
	UPDATE tbintegraSAP_Tracking 
	INNER JOIN tbTMP_INTEGRA_RETORNO_B1 ON tbTMP_INTEGRA_RETORNO_B1.chave_integracao = tbintegraSAP_Tracking.chave_integracao
	SET StatusAtual = StatusTrackingAtual 
	   ,StatusAnt = StatusTrackingAnt 
	   ,dthr_alt = NOW();
      
      SELECT * FROM tbTMP_INTEGRA_RETORNO_B1;
      
      DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_B1;
      #DROP TEMPORARY TABLE IF EXISTS tTabelaComTexto;
      
    
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      SELECT RESULTADO, MENSAGEM;
   ELSE    
      SET RESULTADO = 1;
      #SET MENSAGEM  = 'Processo Realizado com sucesso!';
   END IF;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_SetarStatusProcesso.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_SetarStatusProcesso`$$

CREATE PROCEDURE `PROC_INTEGRA_SetarStatusProcesso`(
	IN oCodUsuario				VARCHAR(10),
	IN oNewStatus           INT,
	IN oStatusAtivo         INT,
	
	# Parametros de Retorno
	OUT RESULTADO             	VARCHAR(5),
	OUT MENSAGEM              	VARCHAR(500)
)
BLOCO1:BEGIN
	DECLARE xIncAlt VARCHAR(01)	DEFAULT 'I';
	DECLARE excecao INT DEFAULT 0;
	#DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   SET RESULTADO = "1";
   SET MENSAGEM = "Atualização realizada com sucesso";
   UPDATE tbintegraSAP_parametros
   SET  flg_status = oNewStatus
        ,ultima_atu = IF(oNewStatus=1,NOW(), ultima_atu)
        ,flg_ativo  = IFNULL(oStatusAtivo,1);
   IF excecao = 1 THEN
      SET RESULTADO = "0";
      SET MENSAGEM = "Erro SQL - Verifique com o Administrador";
   END IF;
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_TMS_GERAR_ENTREGAS.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_TMS_GERAR_ENTREGAS`$$

CREATE PROCEDURE `PROC_INTEGRA_TMS_GERAR_ENTREGAS`( IN oCodEmpWMS   VARCHAR(03)
, IN oCodFilWMS   VARCHAR(03)
, IN oAnoSolic    VARCHAR(04)
, IN oNumSolic    VARCHAR(10)
, IN oTipoFrete   VARCHAR(05)
, IN oCnpjTransp  VARCHAR(20)
, IN oNomeTransp  VARCHAR(50)
, OUT RESULTADO   VARCHAR(40)
, OUT MENSAGEM    VARCHAR(500)
)
BLOCO1:BEGIN
  /************************************************************************
  * @Created David Ruy <2018/04/11>
  * Esta procedure realiza a inserção de registros na base de dados SLIN
  * para o módulo TMS (analisa tbprog_entregas, tbnf_clientes)
  *
  *@Reviser David Ruy <2020/01/26> Considerar TipoFrete (SAP) e Transportadora Coleta
  *@Reviser David Ruy <2020/02/11> Considerar DEPARA para tipo Operação de Transporte/Incoterms
  *@Reviser David Ruy <2020/08/28> Atualizar quantidades no TMS com base no FECHAMENTO da GSM, 
  *                                além de considerar oTipoFrete = null para não atualizar essas informações
  *@Reviser David Ruy <2020/12/14> Não considerar mais Coletas
  *@Reviser David Ruy <2021/03/24> Atualizar a transportadora na tbprog_entregas->cnpj_cpf_terceiro not null
  *                                Rotina de roteirização : tbviagens->cnpj_transportador quando não for retirada
  *
  *@Reviser David Ruy <2022/01/12> Ajuste para atualizar peso bruto
  *@Reviser David Ruy <2023/01/05> Ajuste correção Year(now()) para oAnoSolic (evita Duplicar a entrega e fica no mesmo ano da GSM)
  *@Reviser David Ruy <2023/01/30> Ajuste Calculo Peso Bruto Variavel xtot_pesobrt : pesoLiq+(Vol*(tara))
                                   Alterado tbsolic_saidas_item.dthr_final_baixa_geral por tbsolic_saidas.dthr_final_geral 
  *@Reviser David Ruy <2023/01/31> Ajuste Calculo Peso Bruto Variavel xtot_pesobrt : com base na UA
  *@Reviser David Ruy <2023/10/23> Parametrização tabela novo formato tbintegraSAP_TipoFrete.TransportationCode
  *@Reviser David Ruy <2023/12/27> Atualização campo num_nf_aux com xNumPedido
  *@Reviser David Ruy <2024/08/07> Correção calculo Valor NF pela soma dos itens (Sub Select inserido)
  *************************************************************************/
  
  /**
   * ------------------------ INFORMAÇÕES ADICIONAIS -----------------------
   *
   *
   * ---------------------- FIM INFORMAÇÕES ADICIONAIS ---------------------
   */
  
  /****************************************************************/
  /****************DECLARAR VARIÁVEIS AUXILIARES
  /****************************************************************/
  
  DECLARE xRetornoTMS         VARCHAR(500);
  DECLARE xId_nf				          INT;
  DECLARE xCnpjCliWMS         VARCHAR(14);
  DECLARE xNumPedido          VARCHAR(20);
  DECLARE xChaveIntegracao    VARCHAR(50);
  DECLARE xSerPedido          VARCHAR(03) DEFAULT '1';
  DECLARE xDataSolic          DATE;
  DECLARE xDataSaida          DATE;
  DECLARE xCodUsuario         VARCHAR(06);
  DECLARE xTipoFrete          VARCHAR(01) DEFAULT 'C';
  DECLARE xCodTipoOper        VARCHAR(03) DEFAULT '001';
  DECLARE xFlgCross           VARCHAR(01) DEFAULT 'N';
  DECLARE xvlr_tot_nf         DECIMAL(20,6);
  DECLARE xtot_pesoliq        DECIMAL(20,6);
  DECLARE xtot_pesobrt        DECIMAL(20,6);
  DECLARE xPLiqItem           DECIMAL(20,6);
  DECLARE xPBrtItem           DECIMAL(20,6); 
  #Destinatário (Local Entrega)
  DECLARE _IDDestinatario     INT(11); 
  DECLARE _dest_CNPJ          VARCHAR(14);
  DECLARE _dest_CPF      	    VARCHAR(14);
  DECLARE _dest_RazSocial     VARCHAR(200);
  DECLARE _dest_NomeFant      VARCHAR(200);
  DECLARE _dest_InscrEst      VARCHAR(20);
  DECLARE _dest_Endereco      VARCHAR(60);
  DECLARE _dest_Nro           VARCHAR(10);
  DECLARE _dest_Compl         VARCHAR(200);
  DECLARE _dest_Bairro        VARCHAR(100);
  DECLARE _dest_Cidade        VARCHAR(50);
  DECLARE _dest_UF            VARCHAR(20);
  DECLARE _dest_CEP           VARCHAR(10);
  DECLARE _dest_CidadeCod     VARCHAR(10);
  #Variaveis para tbprog_entregas
  DECLARE xCodEmp             VARCHAR(03);
  DECLARE xCodFil             VARCHAR(03);
  DECLARE xAno_entrega        VARCHAR(04);
  DECLARE xNum_entrega        VARCHAR(10);
  DECLARE xTemtbprog_entregas INT DEFAULT 0;
  DECLARE xCNPJ_Dest_Aux      VARCHAR(14);
  DECLARE xHora1_entrega      VARCHAR(05);
  DECLARE xHora2_entrega      VARCHAR(05);
  DECLARE xHora3_entrega      VARCHAR(05);
  DECLARE xHora4_entrega      VARCHAR(05);
  DECLARE xtempo_entrega      DECIMAL(6,2);
  DECLARE xCodUnidade			VARCHAR(03);
  DECLARE xCodArmazem 		   VARCHAR(02);
  DECLARE xObservacoes        VARCHAR(200);
  DECLARE xinstr_entrega      VARCHAR(200);
  DECLARE xCNPJColeta         VARCHAR(20);
  DECLARE xidDestinoColeta    INT;
  DECLARE xNomeColeta         VARCHAR(50);
  
  DECLARE xOperadorLogistico  BOOLEAN;
  DECLARE xTabelaFrete        INT DEFAULT 0;   #0 = tbintegraSAP_DeParaOperTMS; 1 = tbintegraSAP_TipoFrete
  
  /****************************************************************/
  /****************CONTROLE DE EXCEÇÃO DE SQL
  /****************************************************************/
  
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    
    GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
  
    ROLLBACK;
    SET RESULTADO = '0';
    SET MENSAGEM  = MENSAGEM;
  END;
  
  #****************************************************************
  #*******************INICIAR VARIÁVEIS
  #****************************************************************
  
  SET xCodUsuario = '999999';
  
  
  /*
  #Incoterms - SAP => 0,1,2,9 Coleta/Retirada | => 3,4 (Nosso Carro/Distribuição/CIF)
  #SET xTipoFrete = IF(oTipoFrete IN (0,1,2,9), "E", "C");
  #Incoterms - SAP => 0,1,2 Coleta | 9 => Retirada | => 3,4 (Nosso Carro/Distribuição/CIF)
  SET xidDestinoColeta = NULL;
  #SET xTipoFrete = IF(oTipoFrete IN (0,1,2),"O", IF(oTipoFrete=9, "E", "C"));
  SET xTipoFrete = IF(oTipoFrete IN (0,1,2,9),"E", "C");
  IF xTipoFrete = "E" THEN
     SET xCodTipoOper = "999";
  END IF;
  */
  
  
   IF EXISTS (SELECT 1 FROM tbintegraSAP_TipoFrete LIMIT 1) THEN
      SET xTabelaFrete = 1;
   END IF;
  
  
  #*******************Seleciona o Destinatário do pedido da GSM
  SELECT of_logistica.tbsolic_saidas.cnpj_cpf_cli
       , of_logistica.tbsolic_saidas.cnpj_cpf_for
       , IFNULL(of_logistica.tbsolic_saidas_item.num_ped_cli, of_logistica.tbsolic_saidas.num_nf)
       , of_logistica.tbsolic_saidas.data_solic
       , of_logistica.tbsolic_saidas.data_saida
       #Peso_Item : 2023-01-30
       , SUM(tbsolic_saidas_item.pliq_item)
       , SUM(tbsolic_saidas_item.pbrt_item)
       #Peso_Aconselhamento 2023-01-31
       , IF(tbsolic_saidas.dthr_final_geral IS NULL, SUM(of_logistica.tbsolic_saidas_acons.qtde_peso), SUM(of_logistica.tbsolic_saidas_acons.qtde_peso2))
       , IF(tbsolic_saidas.dthr_final_geral IS NULL, SUM(of_logistica.tbsolic_saidas_acons.qtde_pbrt), SUM(of_logistica.tbsolic_saidas_acons.qtde_pbrt2))
       #
       , IF(xTabelaFrete = 0, 
            IFNULL(tbintegraSAP_DeParaOperTMS.cod_oper_tms, '001'),
            IFNULL(tbintegraSAP_TipoFrete.CodTipoOper, '001')) CodTipoOper
       , IF(xTabelaFrete = 0, 
            IFNULL(tbintegraSAP_DeParaOperTMS.TipoFrete, 'C'),
            IFNULL(tbintegraSAP_TipoFrete.TipoFrete, 'C'))  TipoFrete
       , of_logistica.tbsolic_saidas.id_destinatario
       
       #@Reviser David Ruy <2024/08/07> 
       #, IF(tbsolic_saidas.dthr_final_geral IS NULL, SUM(of_logistica.tbsolic_saidas_item.vlr_item), SUM(of_logistica.tbsolic_saidas_item.vlr_item / tbsolic_saidas_item.qtde_est * real_est2))
       , IF(tbsolic_saidas.dthr_final_geral IS NULL, 
             (SELECT SUM(tbItemAux.vlr_item) 
                      FROM of_logistica.tbsolic_saidas_item tbItemAux
                      WHERE tbItemAux.cod_emp   = tbsolic_saidas_item.cod_emp 
                        AND tbItemAux.cod_fil   = tbsolic_saidas_item.cod_fil 
                        AND tbItemAux.ano_solic = tbsolic_saidas_item.ano_solic
                        AND tbItemAux.num_solic = tbsolic_saidas_item.num_solic)  ,
             (SELECT SUM(tbItemAux.vlr_item) 
                      FROM of_logistica.tbsolic_saidas_item tbItemAux
                      WHERE tbItemAux.cod_emp   = tbsolic_saidas_item.cod_emp 
                        AND tbItemAux.cod_fil   = tbsolic_saidas_item.cod_fil 
                        AND tbItemAux.ano_solic = tbsolic_saidas_item.ano_solic
                        AND tbItemAux.num_solic = tbsolic_saidas_item.num_solic) / tbsolic_saidas_item.qtde_est * real_est2) VlrNF
       , tbsolic_saidas.chave_integracao
       , SUBSTRING(tbintegraSAP_Doc.Observacoes,1,200)
    INTO xCnpjCliWMS
       , _dest_CNPJ
       , xNumPedido
       , xDataSolic
       , xDataSaida
       , xPLiqItem
       , xPBrtItem
       , xtot_pesoliq
       , xtot_pesobrt
       , xCodTipoOper
       , xTipoFrete
       , _IDDestinatario
       , xvlr_tot_nf
       , xChaveIntegracao
       , xObservacoes
    FROM of_logistica.tbsolic_saidas
    LEFT JOIN tbintegraSAP_Doc              ON tbintegraSAP_Doc.cod_emp             = tbsolic_saidas.cod_emp
                                           AND tbintegraSAP_Doc.cod_fil             = tbsolic_saidas.cod_fil
                                           AND tbintegraSAP_Doc.ano_solic           = tbsolic_saidas.ano_solic
                                           AND tbintegraSAP_Doc.num_solic           = tbsolic_saidas.num_solic
                                           AND tbintegraSAP_Doc.TipoDocSLIN         = 'S'
    LEFT JOIN tbintegraSAP_DeParaOperTMS    ON tbintegraSAP_DeParaOperTMS.Incoterms = tbintegraSAP_Doc.TipoFrete
    LEFT JOIN tbintegraSAP_TipoFrete        ON tbintegraSAP_TipoFrete.TransportationCode = tbintegraSAP_Doc.TransportationCode
    LEFT JOIN of_logistica.tbsolic_saidas_item ON tbsolic_saidas_item.cod_emp          = tbsolic_saidas.cod_emp
                                           AND tbsolic_saidas_item.cod_fil          = tbsolic_saidas.cod_fil
                                           AND tbsolic_saidas_item.ano_solic        = tbsolic_saidas.ano_solic
                                           AND tbsolic_saidas_item.num_solic        = tbsolic_saidas.num_solic
    LEFT JOIN of_logistica.tbsolic_saidas_acons ON tbsolic_saidas_acons.cod_emp      = tbsolic_saidas_item.cod_emp
                                           AND tbsolic_saidas_acons.cod_fil          = tbsolic_saidas_item.cod_fil
                                           AND tbsolic_saidas_acons.ano_solic        = tbsolic_saidas_item.ano_solic
                                           AND tbsolic_saidas_acons.num_solic        = tbsolic_saidas_item.num_solic
                                           AND tbsolic_saidas_acons.num_item         = tbsolic_saidas_item.num_item
   WHERE tbsolic_saidas.cod_emp   = oCodEmpWMS
     AND tbsolic_saidas.cod_fil   = oCodFilWMS
     AND tbsolic_saidas.ano_solic = oAnoSolic
     AND tbsolic_saidas.num_solic = oNumSolic
   LIMIT 1;
   
   #Se ainda não tem aconselhamento, pega o peso do item
   IF xtot_pesoliq IS NULL THEN
      SET xtot_pesoliq = xPLiqItem;
      SET xtot_pesobrt = xPBrtItem;
   END IF;
   
   
   #Desabilitado em 14/12/2020
   #Se for Coleta, Buscar na tabela de Destinatarios a Transportadora
   #Se for retira também
   /*IF xTipoFrete IN ("O","E") THEN
      SET xCNPJColeta  = oCnpjTransp;
      SET xNomeColeta  = oNomeTransp;
      SELECT id_destinatario INTO xidDestinoColeta
      FROM of_logistica.tbdestinatarios
      WHERE of_logistica.tbdestinatarios.cnpj_cpf_cliente = xCnpjCliWMS
        AND of_logistica.tbdestinatarios.cod_integracao   = xCNPJColeta;
   END IF;   
   */
   
   
   #Se não gravou o ID Destinatário na tbSolicSaidas
   #Busca o destinatário pelo Codigo de Integração
   IF IFNULL(_IDDestinatario,'') = '' THEN
      SELECT id_destinatario INTO _IDDestinatario
      FROM of_logistica.tbdestinatarios
      WHERE of_logistica.tbdestinatarios.cnpj_cpf_cliente = xCnpjCliWMS
        AND of_logistica.tbdestinatarios.cod_integracao   = _dest_CNPJ;
        
      # Atualiza a GSM com o ID do Destinatário identificado pelo codigo de integração
      UPDATE of_logistica.tbsolic_saidas tbSaidas
      SET tbSaidas.id_destinatario = _IDDestinatario
      WHERE tbSaidas.cod_emp   = oCodEmpWMS
        AND tbSaidas.cod_fil   = oCodFilWMS
        AND tbSaidas.ano_solic = oAnoSolic
        AND tbSaidas.num_solic = oNumSolic;
   END IF;
   
   
   #*******************Informações do Destinatário
   SELECT of_logistica.tbdestinatarios.cnpj_cpf
       , of_logistica.tbdestinatarios.raz_social
       , of_logistica.tbdestinatarios.nome_fantasia
       , of_logistica.tbdestinatarios.inscr_estadual
       , of_logistica.tbdestinatarios.endereco
       , of_logistica.tbdestinatarios.num_ende
       , of_logistica.tbdestinatarios.compl_ende
       , of_logistica.tbdestinatarios.bairro
       , of_logistica.tbdestinatarios.nome_cidade
       , of_logistica.tbdestinatarios.sig_estado
       , of_logistica.tbdestinatarios.cep_ende
   INTO _dest_CNPJ
       , _dest_RazSocial
       , _dest_NomeFant
       , _dest_InscrEst
       , _dest_Endereco
       , _dest_Nro
       , _dest_Compl
       , _dest_Bairro
       , _dest_Cidade
       , _dest_UF
       , _dest_CEP
   FROM of_logistica.tbdestinatarios
   WHERE id_destinatario = _IDDestinatario; 
   
   #@Reviser David Ruy <2022-03-15>
   SET _dest_Endereco = SUBSTRING(CONCAT(_dest_Endereco, IF(IFNULL(_dest_Nro,'')='','', CONCAT(' ',_dest_Nro))),1,50);   
   SET _dest_Endereco = UPPER(_dest_Endereco);
   SET _dest_RazSocial = UPPER(_dest_RazSocial);
   SET _dest_NomeFant = UPPER(_dest_NomeFant);
   SET _dest_InscrEst = UPPER(_dest_InscrEst);
   SET _dest_Nro = UPPER(_dest_Nro);
   SET _dest_Compl = UPPER(_dest_Compl);
   SET _dest_Bairro = UPPER(_dest_Bairro);
   SET _dest_Cidade = UPPER(_dest_Cidade);
   SET _dest_UF = UPPER(_dest_UF);
   
   
   
  #***************************************************************************
  #***************Verica se já existe um numero e ano de entrega se não cria
  #***************************************************************************
  SELECT num_entrega, ano_entrega
    INTO xNum_entrega, xAno_entrega
    FROM of_logistica.tbprog_entregas
   WHERE cod_emp          = oCodEmpWMS
     AND cod_fil          = oCodFilWMS
     AND cnpj_cpf_cli     = xCnpjCliWMS   #_emi_CNPJ
     #AND num_nf_cli      = xNumPedido
     #AND serie_nf_cli    = xSerPedido
     AND chave_integracao = xChaveIntegracao     
     #Temporariamente desabilitado o Ano nessa Busca
     #AND ano_entrega      = oAnoSolic     #YEAR(NOW())
     AND num_entre_ant IS NULL;
     
  SET xTemtbprog_entregas = (IFNULL(xNum_entrega,'') <> '');
  
  IF NOT xTemtbprog_entregas THEN
     SELECT LPAD((CAST(MAX(num_entrega) AS UNSIGNED)+1),'10','0') AS num_entrega
          #, YEAR(NOW())                                           AS ano_entrega
          ,oAnoSolic                                              AS ano_entrega  
     INTO xNum_entrega, xAno_entrega
     FROM of_logistica.tbprog_entregas
     WHERE cod_emp     = oCodEmpWMS
       AND cod_fil     = oCodFilWMS
       AND ano_entrega = oAnoSolic;  #YEAR(NOW());
     IF (xNum_entrega IS NULL) THEN
        SET xNum_entrega = '0000000001';
     END IF;
     SET xRetornoTMS = CONCAT('Entrega N° ',xNum_entrega, ' gerada com sucesso ! (',xNumPedido,')');
  END IF;
  
  
  #****************************************************************
  #***************Insere / atualiza tbnf_clientes
  #****************************************************************
  
  IF NOT EXISTS( SELECT 1
                   FROM of_logistica.tbnf_clientes
                  WHERE cod_emp          = oCodEmpWMS
                    AND cod_fil          = oCodFilWMS
                    AND cnpj_cpf         = xCnpjCliWMS    #_emi_CNPJ
                    AND chave_integracao = xChaveIntegracao
                    #AND num_nf          = xNumPedido
                    #AND serie_nf        = xSerPedido
                    AND ano_entrega      = xAno_entrega
               )
  THEN
  BEGIN 
     
     INSERT INTO of_logistica.tbnf_clientes( cod_emp
                                        , cod_fil
                                        , cnpj_cpf
                                        , num_nf
                                        , serie_nf
                                        , ano_entrega
                                        , cnpj_cpf_rem
                                        , data_nf
                                        , cnpj_cpf_destino
                                        , loc_destino
                                        , id_destinatario
                                        , valor_nf
                                        , vlr_tot_nf
                                        , peso_liq_nf
                                        , peso_brt_nf
                                        , dthr_inc
                                        , usu_inc
                                        , chave_integracao
                                        )
                                 VALUES ( oCodEmpWMS
                                        , oCodFilWMS
                                        , xCnpjCliWMS
                                        , xNumPedido
                                        , xSerPedido
                                        , xAno_entrega
                                        , xCnpjCliWMS
                                        , CAST(SUBSTRING(xDataSolic, 1, 10) AS DATE)
                                        , _dest_CNPJ
                                        , _IDDestinatario
                                        , _IDDestinatario
                                        , xvlr_tot_nf
                                        , xvlr_tot_nf
                                        , xtot_pesoliq
                                        , xtot_pesobrt
                                        , NOW()
                                        , xCodUsuario
                                        , xChaveIntegracao
                                        );
     SET xid_nf = LAST_INSERT_ID();
  
  END; 
  ELSE
  BEGIN 
  
    SELECT of_logistica.tbnf_clientes.id_nf
      INTO xid_nf
      FROM of_logistica.tbnf_clientes
     WHERE of_logistica.tbnf_clientes.cod_emp          = oCodEmpWMS
       AND of_logistica.tbnf_clientes.cod_fil          = oCodFilWMS
       AND of_logistica.tbnf_clientes.cnpj_cpf         = xCnpjCliWMS
       #AND of_logistica.tbnf_clientes.num_nf          = xNumPedido
       #AND of_logistica.tbnf_clientes.serie_nf        = xSerPedido
       AND of_logistica.tbnf_clientes.chave_integracao = xChaveIntegracao
       AND of_logistica.tbnf_clientes.ano_entrega      = xAno_entrega
     LIMIT 1;
    UPDATE of_logistica.tbnf_clientes
       SET of_logistica.tbnf_clientes.cnpj_cpf_rem     = xCnpjCliWMS
         , of_logistica.tbnf_clientes.data_nf          = CAST(SUBSTRING(xDataSolic, 1, 10) AS DATE)
         , of_logistica.tbnf_clientes.cnpj_cpf_destino = _dest_CNPJ
         , of_logistica.tbnf_clientes.id_destinatario  = _IDDestinatario
         , of_logistica.tbnf_clientes.loc_destino      = _IDDestinatario
         , of_logistica.tbnf_clientes.valor_nf         = xvlr_tot_nf
         , of_logistica.tbnf_clientes.vlr_tot_nf       = xvlr_tot_nf
         , of_logistica.tbnf_clientes.peso_liq_nf      = xtot_pesoliq
         , of_logistica.tbnf_clientes.peso_brt_nf      = xtot_pesobrt
         , of_logistica.tbnf_clientes.dthr_alt         = NOW()
         , of_logistica.tbnf_clientes.usu_alt          = xCodUsuario
     WHERE of_logistica.tbnf_clientes.id_nf            = xid_nf;
  
  END; 
  END IF; 
     
  #****************************************************************
  #***********************Insere tbprog_entregas
  #****************************************************************
  #Verifica se a nota já esta cadastrada na tbprog_entregas, caso não cadastrada inclui
  SELECT hora1_entrega
       , hora2_entrega
       , hora3_entrega
       , hora4_entrega
       , tempo_entrega
       , instr_entrega
  INTO xHora1_entrega
     , xHora2_entrega
     , xHora3_entrega
     , xHora4_entrega
     , xtempo_entrega
     , xinstr_entrega
   FROM of_logistica.tbdestinatarios
   WHERE id_destinatario = _IDDestinatario; 
  IF (NOT xTemtbprog_entregas) THEN
  BEGIN 
  
        INSERT INTO of_logistica.tbprog_entregas(id_nf,
                                     cod_emp,
                                     cod_fil,
                                     ano_entrega,
                                     num_entrega,
                                     flg_roteiriza,
                                     cnpj_cpf_cli,
                                     cnpj_cpf_centralizador,
                                     num_ped_aux,
                                     num_nf_cli,
                                     serie_nf_cli,
                                     num_nf_aux,
                                     id_destinatario, 
                                     cnpj_cpf_destino,
                                     ie_destino,
                                     nome_destino,
                                     ende_destino,
                                     bairro_destino,
                                     cidade_destino,
                                     estado_destino,
                                     local_entrega,
                                     cnpj_cpf_coleta,
                                     id_destinatario_coleta,
                                     cnpj_cpf_terceiro,
                                     cnpj_cpf_redesp,
                                     ie_redesp,
                                     nome_redesp,
                                     ende_redesp,
                                     cep_redesp,
                                     bairro_redesp,
                                     cidade_redesp,
                                     estado_redesp,
                                     data_redesp,
                                     tipo_frete,
                                     num_ctrc_redesp,
                                     valor_redesp,
                                     peso_liq_entre,
                                     peso_brt_entre,
                                     peso_liq_ori,
                                     peso_brt_ori,
                                     cubagem_entre,
                                     data_progr,
                                     data_separa,
                                     cep_ende,
                                     flg_zmrc,
                                     num_ende,
                                     flg_cobra_entrega,
                                     cod_serv,
                                     cod_tipo_oper,
                                     compl_ende,
                                     hora1_entre,
                                     hora2_entre,
                                     hora3_entre,
                                     hora4_entre,
                                     tempo_entre,
                                     observ_entre,
                                     flg_cobra_var,
                                     flg_cdock,
                                     usu_inc,
                                     dthr_inc,
                                     chave_integracao)
        VALUES (xid_nf,
                oCodEmpWMS,
                oCodFilWMS,
                xAno_entrega,
                xNum_entrega,
                "S",
                xCnpjCliWMS,
                xCnpjCliWMS, 
                xNumPedido,
                xNumPedido,
                xSerPedido,
                xNumPedido,  #@NumNF,
                _IDDestinatario, 
                _dest_CNPJ,
                _dest_InscrEst,
                SUBSTRING(_dest_RazSocial,1,50),
                _dest_Endereco,
                SUBSTRING(_dest_Bairro,1,50),
                _dest_Cidade,
                _dest_UF,
                _IDDestinatario, # cod_loja
                xCNPJColeta,
                xidDestinoColeta,
                oCnpjTransp,
                NULL, # cnpj_redesp
                NULL, # ie_redesp
                NULL, # raz_soc_redesp
                NULL, # ende_redesp
                NULL, # cep_redesp
                NULL, # bairro_redesp
                NULL, # cidade_redesp
                NULL, # estado_redesp
                NULL, # data_redesp
                xTipoFrete, # Parametro
                NULL, # num_ctrc_redesp,
                NULL, # valor_redesp
                xtot_pesoliq,
                xtot_pesobrt,
                xtot_pesoliq,
                xtot_pesobrt,
                NULL,       # cubagem
                xDataSaida, # Parametro
                xDataSaida, # Parametro
                _dest_CEP,
                '', # xflgZMRC,
                _dest_Nro,
                'S', # flg_cobra_entrega
                NULL,     # cod_serv
                xCodTipoOper,  # Parametro
                SUBSTRING(_dest_Compl, 1, 20),
                xHora1_entrega,
                xHora2_entrega,
                xHora3_entrega,
                xHora4_entrega,
                xtempo_entrega,
                xObservacoes,
                NULL, # xflg_cobra_var,  (Verificar Tabela de Preços)
                xFlgCross, # Parametro
                xCodUsuario,
                NOW(),
                xChaveIntegracao);
  
  END; 
  ELSE
  BEGIN 
  
        UPDATE of_logistica.tbprog_entregas
        SET cod_emp           = oCodEmpWMS,
            cod_fil           = oCodFilWMS,
            ano_entrega       = xAno_entrega,
            num_entrega       = xNum_entrega,
            flg_roteiriza     = "S",
            cnpj_cpf_cli      = xCnpjCliWMS,  #_emi_CNPJ,
            num_ped_aux       = xNumPedido,
            num_nf_cli        = xNumPedido,
            serie_nf_cli      = xSerPedido,
            id_destinatario   = _IDDestinatario, 
            cnpj_cpf_destino  = _dest_CNPJ,
            ie_destino        = _dest_InscrEst,
            nome_destino      = SUBSTRING(_dest_RazSocial,1,50),
            ende_destino      = _dest_Endereco,
            bairro_destino    = SUBSTRING(_dest_Bairro,1,50),
            cidade_destino    = _dest_Cidade,
            estado_destino    = _dest_UF,
            local_entrega     = _IDDestinatario,
            cnpj_cpf_coleta   = IF(oTipoFrete IS NULL, cnpj_cpf_coleta, xCNPJColeta),
            id_destinatario_coleta = IF(oTipoFrete IS NULL, id_destinatario_coleta, xidDestinoColeta),
            cnpj_cpf_terceiro = oCnpjTransp,
            cnpj_cpf_redesp   = NULL,
            ie_redesp         = NULL,
            nome_redesp       = NULL,
            ende_redesp       = NULL,
            cep_redesp        = NULL,
            bairro_redesp     = NULL,
            cidade_redesp     = NULL,
            estado_redesp     = NULL,
            data_redesp       = NULL,
            tipo_frete        = IF(oTipoFrete IS NULL, tipo_frete, xTipoFrete),   #<@Reviser David - 2020-07-23> tipo_frete,  # Não Atualiza, utiliza o conteúdo do campo
            num_ctrc_redesp   = NULL,
            valor_redesp      = NULL,
            peso_liq_entre    = xtot_pesoliq,
            peso_brt_entre    = xtot_pesobrt,
            peso_liq_ori      = xtot_pesoliq,
            peso_brt_ori      = xtot_pesobrt,
            cubagem_entre     = cubagem_entre,                              # Não Atualiza, utiliza o conteúdo do campo
            cep_ende          = _dest_CEP,
            flg_zmrc          = flg_zmrc,                                        # Não Atualiza, utiliza o conteúdo do campo
            num_ende          = _dest_Nro,
            flg_cobra_entrega = flg_cobra_entrega,         # Não Atualiza, utiliza o conteúdo do campo
            cod_serv          = cod_serv,                                      # Não Atualiza, utiliza o conteúdo do campo
            cod_tipo_oper     = IF(oTipoFrete IS NULL, cod_tipo_oper, xCodTipoOper), #<@Reviser David - 2020-07-23>  cod_tipo_oper,                   # Não Atualiza, utiliza o conteúdo do campo
            compl_ende        = SUBSTRING(_dest_Compl, 1, 20),
            hora1_entre       = xHora1_entrega,
            hora2_entre       = xHora2_entrega,
            hora3_entre       = xHora3_entrega,
            hora4_entre       = xHora4_entrega,
            tempo_entre       = xtempo_entrega,
            observ_entre      = xObservacoes,
            flg_cobra_var     = flg_cobra_var,                        # Não Atualiza, utiliza o conteúdo do campo
            flg_cdock         = flg_cdock,                                     # Não Atualiza, utiliza o conteúdo do campo
            dthr_alt          = NOW(),
            usu_alt           = xCodUsuario
        WHERE id_nf = xid_nf
          AND num_entre_ant IS NULL;
    
     SET xRetornoTMS = CONCAT('Entrega N° ',xNum_entrega, ' atualizada com sucesso ! (',xNumPedido,'-',xSerPedido,')');
  
  END; 
  END IF;
  #****************************************************************
  #********Insere tbnf_ite_clientes (Itens da NF)
  #****************************************************************
  DELETE
    FROM of_logistica.tbnf_ite_clientes
   WHERE of_logistica.tbnf_ite_clientes.id_nf = xid_nf; 
  INSERT INTO of_logistica.tbnf_ite_clientes (id_nf, cod_emp,
                                 cod_fil,
                                 cnpj_cpf,
                                 num_nf,
                                 serie_nf,
                                 num_item,
                                 ano_entrega,
                                 cod_produto,
                                 qtde_ori,
                                 emb_ori,
                                 peso_liq_item,
                                 peso_brt_item,
                                 vlr_unitario,
                                 vlr_item,
                                 #vlr_ipi_item,
                                 #vlr_icms_item,
                                 qtde_vol,
                                 emb_vol,
                                 qtde_frac,
                                 emb_frac,
                                 emb_maior,
                                 fator_conv,
                                 #num_lote_cli,
                                 #data_fabr,
                                 dthr_inc,
                                 usu_inc)
             (SELECT xid_nf, oCodEmpWMS,
                     oCodFilWMS,
                     xCnpjCliWMS,  #_emi_CNPJ,
                     xNumPedido,
                     xSerPedido,
                     LPAD(num_item,6,'0'),
                     xAno_Entrega,
                     cod_produto,
                     IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, qtde_est, real_est2),
                     emb_est,
                     IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, pliq_item, real_peso2),
                     #IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, pbrt_item, real_vol2 * tbsolic_saidas_item.peso_volume_brt),
                     IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, 
                         of_logistica.fnCalcPesoBrt( tbsolic_saidas_item.pliq_item, tbsolic_saidas_item.real_tara, tbsolic_saidas_item.qtde_vol),
                         of_logistica.fnCalcPesoBrt( tbsolic_saidas_item.real_peso2, tbsolic_saidas_item.real_tara, tbsolic_saidas_item.real_vol2)
                         ),
                     vlr_unitario,
                     IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, vlr_item, vlr_item / qtde_est * real_est2),
                     #vlr_ipi_item,
                     #vlr_icms_item,
                     IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, qtde_vol, real_vol2),
                     emb_vol,
                     IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, qtde_frac, real_frac2),
                     emb_frac,
                     emb_vol,
                     fator_conv,
                     #NULL, #num_lote_cli
                     #NULL, #data_fabr
                     NOW(),
                     xCodUsuario
              FROM of_logistica.tbsolic_saidas_item
              WHERE cod_emp = oCodEmpWMS
                AND cod_fil = oCodEmpWMS
                AND ano_solic = oAnoSolic
                AND num_solic = oNumSolic
                AND IFNULL(tbsolic_saidas_item.qtde_est,0) > 0);
  
  #****************************************************************
  #***********Insere tbprog_ite_entregas (Itens da Entrega)
  #****************************************************************
  DELETE
    FROM of_logistica.tbprog_ite_entregas
   WHERE of_logistica.tbprog_ite_entregas.cod_emp     = oCodEmpWMS
     AND of_logistica.tbprog_ite_entregas.cod_fil     = oCodFilWMS
     AND of_logistica.tbprog_ite_entregas.ano_entrega = xAno_entrega
     AND of_logistica.tbprog_ite_entregas.num_entrega = xnum_entrega;
  INSERT INTO of_logistica.tbprog_ite_entregas( cod_emp
                                           , cod_fil
                                           , ano_entrega
                                           , num_entrega
                                           , num_item
                                           , cod_produto
                                           , qtde_ori
                                           , emb_ori
                                           , qtde_vol
                                           , emb_vol
                                           , peso_liq_item
                                           , peso_brt_item
                                           , qtde_frac
                                           , emb_frac
                                           , cubagem
                                           , dthr_inc
                                           , usu_inc
                                           )
    SELECT oCodEmpWMS
         , oCodFilWMS
         , xAno_entrega
         , xNum_entrega
         , LPAD(num_item,6,'0')
         , cod_produto
         , IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, qtde_est, real_est2)
         , emb_est
         , IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, qtde_vol, real_vol2)
         , emb_vol
         , IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, pliq_item, real_peso2)
         #, IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, pbrt_item, real_vol2 * tbsolic_saidas_item.peso_volume_brt)
         ,IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, 
              of_logistica.fnCalcPesoBrt( tbsolic_saidas_item.pliq_item, tbsolic_saidas_item.real_tara, tbsolic_saidas_item.qtde_vol),
              of_logistica.fnCalcPesoBrt( tbsolic_saidas_item.real_peso2, tbsolic_saidas_item.real_tara, tbsolic_saidas_item.real_vol2)
              )
         , IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, qtde_frac, real_frac2)
         , emb_frac
         , NULL
         , NOW()
         , xCodUsuario
      FROM of_logistica.tbsolic_saidas_item
     WHERE cod_emp = oCodEmpWMS
       AND cod_fil = oCodEmpWMS
       AND ano_solic = oAnoSolic
       AND num_solic = oNumSolic
       AND IFNULL(tbsolic_saidas_item.qtde_est,0) > 0;
  /***********************************************************************
  # Integração TMS X WMS
  ***********************************************************************/
  IF (xDataSaida IS NOT NULL) THEN
     CALL of_logistica.PROC_TMS_SAIDA_ATUALIZAR_ENTREGA_UNIDADE_ARMAZEM(oCodEmpWMS, oCodFilWMS, IFNULL(xCnpjCliWMS, xCnpjCliWMS), xDataSolic, xDataSaida, @R, @M);
  END IF;
  /****************************************************************/
  /******** FINALIZA PROCEDURE E ENVIA RETORNO
  /****************************************************************/
  SET RESULTADO = 1;
  SET mensagem = CONCAT(xRetornoTMS);
  COMMIT;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_TratarAlteraoesSLIN.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_TratarAlteraoesSLIN`$$

CREATE PROCEDURE `PROC_INTEGRA_TratarAlteraoesSLIN`(
   # Parametros de Retorno
   #OUT RESULTADO      INT,
   #OUT MENSAGEM       VARCHAR(500)
)
BLOCO1:BEGIN
   DECLARE RESULTADO                INT;
   DECLARE MENSAGEM                 VARCHAR(500);
   DECLARE xCodUsuario              VARCHAR(06) DEFAULT "999999";
   DECLARE xDocEntry                INT;
   DECLARE xDocNum                  INT;
   DECLARE xDocTipo                 VARCHAR(10);
   DECLARE xUniqueKey               VARCHAR(30);
   DECLARE xUpdateDate              VARCHAR(30);
   DECLARE xDthrInc                 VARCHAR(20);
   DECLARE xDocumentDate            VARCHAR(20);
   DECLARE xCodEmpWMS			            VARCHAR(03);
   DECLARE xCodFilWMS			            VARCHAR(03);
   DECLARE xAnoSolic 			            VARCHAR(04);
   DECLARE xNumSolic 			            VARCHAR(10);
   DECLARE xNumItem                 VARCHAR(06);
   DECLARE xNumPedido               VARCHAR(20);
   DECLARE xQtdeVol                 DECIMAL(18,6);
   DECLARE xQtdeFrac                DECIMAL(18,6);
   DECLARE xQtdeEst                 DECIMAL(18,6);
   DECLARE xQtdePeso                DECIMAL(18,6);
   DECLARE xdthr_aconselhamento     VARCHAR(20);
   DECLARE xdthr_inicio_separacao   VARCHAR(20);
   DECLARE xdthr_final_separacao    VARCHAR(20);
   DECLARE xQtdeRegs                INT DEFAULT 0;
   DECLARE xTipoUpdCanc             VARCHAR(01);
   
   DECLARE xEmbVendas         VARCHAR(10);
   DECLARE excecao 	INT DEFAULT 0;
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       ROLLBACK;
   END;
   
   START TRANSACTION;
   
   
   DROP TEMPORARY TABLE IF EXISTS TMP_AlteracoesSLIN;
   CREATE TEMPORARY TABLE TMP_AlteracoesSLIN ( 
      SELECT tbUpdCancPV.TipoUpdCanc,tbUpdCancPV.UniqueKey, tbUpdCancPV.DocumentType, 
             tbUpdCancPV.DocumentId, tbUpdCancPV.DocumentNumber,
             tbUpdCancPV.DocumentDate, tbUpdCancPV.LineNumber, tbUpdCancPV.UpdateDate,
             tbUpdCancPV.QtdeEstoque Quantity, tbUpdCancPV.SalUnitMsr,
             tbAlteracao.cod_emp, tbAlteracao.cod_fil, tbAlteracao.ano_solic, tbAlteracao.num_solic, tbAlteracao.num_item,
             tbAlteracao.dthr_inc,
             tbAlteracao.qtde_est_ant, tbAlteracao.qtde_frac_ant, tbAlteracao.qtde_vol_ant, tbAlteracao.qtde_peso_ant,
             tbAlteracao.qtde_est_atu, tbAlteracao.qtde_frac_atu, tbAlteracao.qtde_vol_atu, tbAlteracao.qtde_peso_atu,
             item.dthr_aconselhamento AS dthr_aconselhamento, 
             item.dthr_inicio_baixa_geral AS dthr_inicio_separacao, 
             item.dthr_final_baixa_geral AS dthr_final_separacao,
             0 AS FlgProcessado,
             0 AS FlgAconselhar
      FROM tbintegraSAP_UpdCancPV tbUpdCancPV 
      INNER JOIN of_logistica.tbsolic_saidas_item_integra_alteracao tbAlteracao ON 
                 tbAlteracao.cod_emp = tbUpdCancPV.cod_emp
             AND tbAlteracao.cod_fil = tbUpdCancPV.cod_fil
             AND tbAlteracao.ano_solic = tbUpdCancPV.ano_solic
             AND tbAlteracao.num_solic = tbUpdCancPV.num_solic
             AND tbAlteracao.num_item  = tbUpdCancPV.num_item
             AND tbAlteracao.dthr_inc  = tbUpdCancPV.UpdateDate
      INNER JOIN of_logistica.tbsolic_saidas_item item ON
                 item.cod_emp   = tbAlteracao.cod_emp
             AND item.cod_fil   = tbAlteracao.cod_fil
             AND item.ano_solic = tbAlteracao.ano_solic
             AND item.num_solic = tbAlteracao.num_solic
             AND item.num_item  = tbAlteracao.num_item               
      WHERE tbUpdCancPV.STATUS = 2
        AND tbAlteracao.dthr_realizado IS NULL
   );
   
   
   #@Reviser David Ruy <2022-04-14 13:00> Desabilitado
   /*
   WHILE EXISTS (SELECT 1 FROM TMP_AlteracoesSLIN WHERE TMP_AlteracoesSLIN.FlgProcessado = 0) DO
   
      SET xQtdeRegs = xQtdeRegs + 1;
      
      SELECT DocumentType, DocumentId, DocumentNumber, DocumentDate, UniqueKey, dthr_inc,
             cod_emp, cod_fil, ano_solic, num_solic, num_item, 
             qtde_est_atu, qtde_vol_atu, qtde_frac_atu, qtde_peso_atu,
             dthr_aconselhamento, dthr_inicio_separacao, dthr_final_separacao
      INTO xDocTipo, xDocEntry, xDocNum, xDocumentDate, xUniqueKey, xDthrInc,
           xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xNumItem, 
           xQtdeEst, xQtdeVol, xQtdeFrac, xQtdePeso,
           xdthr_aconselhamento, xdthr_inicio_separacao, xdthr_final_separacao
      FROM TMP_AlteracoesSLIN
      WHERE TMP_AlteracoesSLIN.FlgProcessado = 0
      LIMIT 1;
      
--       if xdthr_aconselhamento is null then
--          # Faz nada
--          set @R = null;
--              
--       elseif xdthr_inicio_separacao is null then
--             #não chamar estas procedures elas são de outro banco de dados, por isso não funcionam se chamadas desta procedure
--             #para isso foi criado o FlgAconselhar na tabela temporária para que as rotinas abaixo sejam chamadas pelo programa 
--             #de integração quando for setado em "1"
--       
--             #Cancelar Aconselhamento
--             #call of_logistica.PROC_WMS_SAIDA_CANCELAR_ACONSELHAMENTO(xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xNumItem, xCodUsuario, @R, @M);
--             #Refazer aconselhamento
--             #CALL of_logistica.PROC_WMS_SAIDA_GERAR_ACONSELHAMENTO(8, 1, xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xNumItem, xQtdeVol, xQtdeFrac, @R, @M);            
--       end if;

      #Se ainda nao rodou aconselhamento ou se ainda não iniciou a separação
      IF (xdthr_aconselhamento IS NULL) OR (xdthr_inicio_separacao IS NULL) THEN
         #Atualiza Status do Documento de 7 (em alteração) para 3 (Atualizado SLIN)
         UPDATE tbintegraSAP_Doc
         SET tbintegraSAP_Doc.StatusAnt = StatusDoc,
             #tbintegraSAP_Doc.StatusDoc = 3
             tbintegraSAP_Doc.StatusDoc = 1  #<2022-03-22> Força PROC_INTEGRA_AtualizarSLIN (Criar itens, atualizar Qtde)
         WHERE DocEntry = xDocEntry
           AND DocNum   = xDocNum   
           AND DocTipo  = xDocTipo;
           
        #Atualiza REALIZADO da tabela de controle de alterações de interface
        UPDATE of_logistica.tbsolic_saidas_item_integra_alteracao
        SET tbsolic_saidas_item_integra_alteracao.dthr_realizado = NOW(),
            tbsolic_saidas_item_integra_alteracao.usu_realizado = xCodUsuario,
            tbsolic_saidas_item_integra_alteracao.flg_realizado = 1
        WHERE UniqueKey = xUniqueKey
          AND dthr_inc  = xDthrInc;
          
      END IF;
      
      UPDATE TMP_AlteracoesSLIN
      SET FlgProcessado = 1,
          FlgAconselhar = IF((xdthr_aconselhamento IS NOT NULL) AND (xdthr_inicio_separacao IS NULL),1,0) 
      WHERE UniqueKey = xUniqueKey 
        AND dthr_inc  = xDthrInc;
      
   END WHILE;
   */   
   
   #Atualiza/Libera Status do controle de alterações
   UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV
   INNER JOIN TMP_AlteracoesSLIN ON
              TMP_AlteracoesSLIN.UniqueKey  = tbUpdCancPV.UniqueKey 
          AND TMP_AlteracoesSLIN.UpdateDate = tbUpdCancPV.UpdateDate
   SET tbUpdCancPV.FreeText = CONCAT(tbUpdCancPV.FreeText,'|PROC_INTEGRA_TratarAlteraoesSLIN(0)')
      ,tbUpdCancPV.STATUS = 3;
   
   /*
   INNER JOIN of_logistica.tbsolic_saidas_item_integra_alteracao tbAlteracao ON 
              tbAlteracao.cod_emp   = tbUpdCancPV.cod_emp
          AND tbAlteracao.cod_fil   = tbUpdCancPV.cod_fil
          AND tbAlteracao.ano_solic = tbUpdCancPV.ano_solic
          AND tbAlteracao.num_solic = tbUpdCancPV.num_solic
          AND tbAlteracao.num_item  = tbUpdCancPV.num_item
          AND tbAlteracao.dthr_inc  = tbUpdCancPV.UpdateDate
   SET tbUpdCancPV.STATUS = 3
   WHERE tbUpdCancPV.STATUS = 2
     AND tbAlteracao.dthr_realizado IS NULL;
  */
  
  
  
   #@David Ruy <2021/04/30>
   #Atualizar Alterações em aberto (Inclusão STATUS=1)
   #Isso também evita que 
   UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV
   SET tbUpdCancPV.FreeText = CONCAT(tbUpdCancPV.FreeText,'|PROC_INTEGRA_TratarAlteraoesSLIN')
      ,tbUpdCancPV.STATUS   = 3
   WHERE tbUpdCancPV.STATUS = 1;
   
   
   
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- Erro PROC_INTEGRA_TratarAlteraoesSLIN [",xQtdeRegs,"]");
   ELSE
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- PROC_INTEGRA_TratarAlteraoesSLIN - sucesso [",xQtdeRegs,"]");
   END IF;
   SELECT TMP_AlteracoesSLIN.*, RESULTADO, MENSAGEM FROM TMP_AlteracoesSLIN;
   DROP TEMPORARY TABLE IF EXISTS TMP_AlteracoesSLIN;    
  
   IF excecao = 1 THEN
      ROLLBACK;
   ELSE
      COMMIT;
   END IF;
   
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_UpdCancPV_Liberar.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_UpdCancPV_Liberar`$$

CREATE PROCEDURE `PROC_INTEGRA_UpdCancPV_Liberar`(
  	 IN oCodUsuario	            VARCHAR(10)
   ,IN oTipoUpdCanc          VARCHAR(01)
   ,IN oDocumentType	        VARCHAR(10)
   ,IN oDocumentId	          INT
   ,IN oDocumentNumber	      VARCHAR(50)
   ,IN oUpdateDate           VARCHAR(30)
   ,IN oQtdeRegistros        INT
	   
   # Parametros de Retorno
   ,OUT RESULTADO            INT
   ,OUT MENSAGEM             VARCHAR(500)
)
BLOCO1:BEGIN
   /******************************************************************************
   @Author <David Ruy (OVERFLASH)>
   @Creation <2025-01-21>
   @Description <Esta rotina atualiza o STATUS da tabela tbintegraSAP_UpdCancPV para "0" a fim de que 
   #      o registro possa ser processado normalmente. Alteração feita para evitar o processamento de pedidos
   #      alterados ocm registros incompletos
   #@Reviser David Ruy <2025-02-17> Recebe os parametros oUpdateDate e oQtdeRegistros para checar e então
   #                                liberar o documento para atualização
   *******************************************************************************/
   
   DECLARE xQtdeAux INT DEFAULT 0;
   DECLARE excecao  INT DEFAULT 0;
   
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       SELECT MENSAGEM;
       ROLLBACK;
   END; 
   


   --    IF EXISTS (SELECT 1 
   --               FROM tbintegraSAP_UpdCancPV
   --               WHERE DocumentType = oDocumentType
   --                 AND DocumentId = oDocumentId
   --                 AND DocumentNumber = oDocumentNumber
   --                 AND TipoUpdCanc = oTipoUpdCanc
   --                 AND STATUS = -1) 
   --    THEN
   
   #Conta a Qtde de Registros inseridas X Qtde Documento (UPDPV)
   SELECT COUNT(*) INTO xQtdeAux 
   FROM tbintegraSAP_UpdCancPV
   WHERE DocumentType = oDocumentType
     AND DocumentId = oDocumentId
     AND DocumentNumber = oDocumentNumber
     AND TipoUpdCanc = oTipoUpdCanc
     AND UpdateDate = oUpdateDate
     AND STATUS = -1;


   #Confirma a Qtde de Registros para liberar a alteração do documento
   IF oQtdeRegistros = xQtdeAux THEN 
         
      UPDATE tbintegraSAP_UpdCancPV
      SET STATUS = 0
      WHERE DocumentType = oDocumentType
        AND DocumentId = oDocumentId
        AND DocumentNumber = oDocumentNumber
        AND TipoUpdCanc = oTipoUpdCanc
        AND UpdateDate = oUpdateDate
        AND STATUS = -1;
                          
     SET MENSAGEM = CONCAT(ROW_COUNT()," Registro(s) Atualizado(s) com sucesso ");
     SET RESULTADO = 1;

   ELSE
        SET RESULTADO = 0;
        SET MENSAGEM = CONCAT("NÃO Existem Registros a serem atualizados, Qtde Esperada = ",oQtdeRegistros,' Quantidade Identificada = ',xQtdeAux);
   END IF;
    
   COMMIT;

   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_INTEGRA_UpdCancSLIN.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_UpdCancSLIN`$$

CREATE PROCEDURE `PROC_INTEGRA_UpdCancSLIN`(
	IN oCodUsuario				  VARCHAR(10),
	# Parametros de Retorno
	OUT RESULTADO       INT,
	OUT MENSAGEM        VARCHAR(500)
)
BLOCO1:BEGIN
   DECLARE excecao         INT DEFAULT 0;
   DECLARE xUniqueKey	VARCHAR(30);
   DECLARE xTipoUpdCanc VARCHAR(01);
   DECLARE xDocumentType	VARCHAR(10);
   DECLARE xDocumentId	INT(11);
   DECLARE xDocumentNumber	INT(11);
   DECLARE xDocumentDate	DATETIME;
   DECLARE xCardCode	VARCHAR(15);
   DECLARE xCardName	VARCHAR(100);
   DECLARE xLineNumber	INT(11);
   DECLARE xItemCode	VARCHAR(30);
   DECLARE xFreeText	VARCHAR(300);
   DECLARE xOpenQuantity	DECIMAL(18,5);
   DECLARE xSERIAL	INT(11);
   DECLARE xAddress2	VARCHAR(200);
   DECLARE xComments	VARCHAR(300);
   DECLARE xAddrTypeS	VARCHAR(20);
   DECLARE xStreetS	VARCHAR(100);
   DECLARE xStreetNoS	VARCHAR(30);
   DECLARE xBlockS	VARCHAR(50);
   DECLARE xBuildingS	VARCHAR(50);
   DECLARE xCityS	VARCHAR(50);
   DECLARE xZipCodeS	VARCHAR(10);
   DECLARE xStateS	VARCHAR(2);
   DECLARE xCountryS	VARCHAR(50);
   DECLARE xBatchNumber_Code	VARCHAR(30);
   DECLARE xBatchNumber_Quantity	DECIMAL(18,5);
   DECLARE xSerialNumber_ManufactureCode	VARCHAR(30);
   DECLARE xManBtchNum	TINYINT(1);
   DECLARE xManSerNum	TINYINT(1);
   DECLARE xDescription	VARCHAR(100);
   DECLARE xPrice	DECIMAL(18,5);
   DECLARE xBuyUnitMsr	VARCHAR(10);
   DECLARE xSalUnitMsr	VARCHAR(10);
   DECLARE xInvntryUom	VARCHAR(10);
   DECLARE xNumInSale	DECIMAL(18,5);
   
   DECLARE xcod_emp        VARCHAR(03);
   DECLARE xcod_fil        VARCHAR(03);
   DECLARE xano_solic      VARCHAR(03);
   DECLARE xnum_solic      VARCHAR(03);
   DECLARE xflgInicioSep   VARCHAR(03);
   DECLARE flgInicioCarga  VARCHAR(03);
   
   DECLARE xGerouGuia      BOOLEAN;
   DECLARE xRefGuia        VARCHAR(20);
   DECLARE xCodEmpWMS	     VARCHAR(03);
   DECLARE xCodFilWMS	     VARCHAR(03); 
   DECLARE xAnoSolic 	     VARCHAR(04);
   DECLARE xNumSolic 	     VARCHAR(10);
   
   #1a fase - Inserir documentos sem id-SLIN
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraUpdCanc;
   CREATE TEMPORARY TABLE tbtmp_IntegraUpdCanc 
      SELECT * FROM tbintegraSAP_UpdCancPV
      WHERE cod_emp IS NULL;
            
   #Varre a lista de Documentos para inserir no SLIN   
   WHILE EXISTS (SELECT 1 FROM tbtmp_IntegraUpdCanc) DO
      SELECT tbUpdCanc.UniqueKey
            ,tbUpdCanc.TipoUpdCanc
            ,tbUpdCanc.DocumentType 
            ,tbUpdCanc.DocumentId 
            ,tbUpdCanc.DocumentNumber 
            ,tbUpdCanc.LineNumber 
            ,tbUpdCanc.ItemCode 
            ,tbUpdCanc.OpenQuantity 
            ,tbUpdCanc.SERIAL 
            ,tbUpdCanc.BatchNumber_Code 
            ,tbUpdCanc.BatchNumber_Quantity 
            ,tbUpdCanc.SerialNumber_ManufactureCode 
            ,tbUpdCanc.Price 
            ,tbUpdCanc.NumInSale       
            ,tbItem.cod_emp
            ,tbItem.cod_fil
            ,tbItem.ano_solic
            ,tbItem.num_solic
            ,IF(tbItemSlin.dthr_inicio_baixa_geral IS NULL,0,1) AS flgInicioSep
            ,IF(tbItemSlin.dthr_inicio_carregamento IS NULL,0,1) AS flgInicioCarga
      INTO  xUniqueKey	
            ,xTipoUpdCanc 
            ,xDocumentType
            ,xDocumentId
            ,xDocumentNumber
            ,xLineNumber
            ,xItemCode 
            ,xOpenQuantity
            ,xBatchNumber_Code
            ,xBatchNumber_Quantity
            ,xSerialNumber_ManufactureCode
            ,xPrice
            ,xNumInSale     
            ,xcod_emp        
            ,xcod_fil        
            ,xano_solic      
            ,xnum_solic      
            ,xflgInicioSep   
            ,flgInicioCarga  
      FROM tbtmp_IntegraUpdCanc tbUpdCanc
      INNER JOIN tbintegraSAP_DocItem tbItem ON
            tbItem.DocumentType = tbUpdCanc.DocumentType
        AND tbItem.DocumentId	= tbUpdCanc.DocumentId	
        AND tbItem.DocumentNumber = tbUpdCanc.DocumentNumber	
        AND tbItem.LineNumber = tbUpdCanc.LineNumber
      INNER JOIN of_logistica.tbsolic_saidas_item tbItemSlin ON
               tbItemSlin.cod_emp   = tbItem.cod_emp
           AND tbItemSlin.cod_fil   = tbItem.cod_fil
           AND tbItemSlin.ano_solic = tbItem.ano_solic
           AND tbItemSlin.num_solic = tbItem.num_solic
           AND tbItemSlin.num_item  = tbItem.num_item
      LIMIT 1;
      
      #IF xflgInicioSep = 0 THEN
         
      #END IF;
      CALL PROC_INTEGRA_EnviarLog('999999', 
           CONCAT('PROC_INTEGRA_UpdCancSLIN=>',xTipoUpdCanc),
           CONCAT(xDocumentType,xDocumentNumber,'(',CAST(xDocumentId AS CHAR),') =>',xItemCode, '|', @R, @M), "0", @M, CONCAT('flgInicioSep=>',xflgInicioSep), @M);
      
      IF xStatusSlin <> 0 THEN
         SET xGerouGuia = TRUE;
         SET xRefGuia   = SUBSTRING(xMensagemSlin,01,20);
         SET xCodEmpWMS	= SUBSTRING(xRefGuia,01,03);
         SET xCodFilWMS	= SUBSTRING(xRefGuia,04,03);
         SET xAnoSolic 	= SUBSTRING(xRefGuia,07,04);
         SET xNumSolic 	= SUBSTRING(xRefGuia,11,10);
         
         UPDATE tbintegraSAP_Doc
         SET cod_emp   = xCodEmpWMS
            ,cod_fil   = xCodFilWMS
            ,ano_solic = xAnoSolic
            ,num_solic = xNumSolic
            ,TipoDocSLIN = IF(xDocumentType IN ("PV","OP"),"S","E")
            ,StatusAnt  = StatusDoc
            ,StatusDoc  = IF(StatusDoc <= '2', '3', StatusDoc)
            ,StatusSlin = xStatusSlin
         WHERE DocTipo  = xDocumentType
           AND DocEntry = xDocEntry;
           
      ELSE
          CALL PROC_INTEGRA_EnviarLog('999999',
                CONCAT('PROC_INTEGRA_UpdCancSLIN=>',xTipoUpdCanc),
                  CONCAT('Não Atualizado ', xDocumentType,xDocumentNumber,'(',CAST(xDocumentId AS CHAR),') =>',xItemCode,'|', @R, @M), "0", @M, @R, @M);
      END IF;
      
   END WHILE;
   
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraUpdCanc;
   
   IF excecao = 1 THEN
      ROLLBACK;
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      COMMIT;
      SET RESULTADO = 0;
      SET MENSAGEM = "Atualização realizada com sucesso";
   END IF;
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_SYS_GerarTabelaComTexto.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_SYS_GerarTabelaComTexto`$$

CREATE PROCEDURE `PROC_SYS_GerarTabelaComTexto`( IN oTexto			    TEXT 
	,IN oSeparador		 CHAR(1)  	
	,IN oQtdeColunas	INT
)
BEGIN
  # PROCEDURE PARA GERAR TABELA TEMPORÁRIA A PARTIR DE UM TEXTO 
  # @author Érico Forcinetti <2017/05/11>
  # @company Overflash Informática Ltda
  
  /** 
   * ------------------------ INFORMAÇÕES ADICIONAIS -----------------------
   *
   * CRIAR A TABELA TEMPORÁRIA ABAIXO NA APLICAÇÃO QUER IRÁ CONSUMIR ESSA ROTINA:
   * 
   * DROP TEMPORARY TABLE IF EXISTS tTabelaComTexto;
   *
   * CREATE TEMPORARY TABLE tTabelaComTexto ( Coluna01 VARCHAR(100)
   *                                        , Coluna02 VARCHAR(100) 
   *                                        , Coluna03 VARCHAR(100)
   *                                        , Coluna04 VARCHAR(100)
   *                                        , Coluna05 VARCHAR(100)
   *                                        , Coluna06 VARCHAR(100)
   *                                        ); 
   *
   * ---------------------- FIM INFORMAÇÕES ADICIONAIS ---------------------
   */
  /****************************************************************/
  /****************DECLARAR VARIÁVEIS AUXLIARES 
  /****************************************************************/
  
  DECLARE _Valor    VARCHAR(100) DEFAULT '';
  DECLARE _Valor1   VARCHAR(100) DEFAULT '';
  DECLARE _Valor2   VARCHAR(100) DEFAULT '';
  DECLARE _Valor3   VARCHAR(100) DEFAULT '';
  DECLARE _Valor4   VARCHAR(100) DEFAULT '';
  DECLARE _Valor5   VARCHAR(100) DEFAULT '';
  DECLARE _Valor6   VARCHAR(100) DEFAULT '';
  DECLARE _iPos     INT          DEFAULT 0;
  DECLARE _iColuna  INT          DEFAULT 1; 
  DECLARE _iInsere  INT          DEFAULT 0;
 
  /****************************************************************/
  /****************CERTIFICAR QUE TODOS OS DADOS FORAM EXCLUÍDOS 
  /****************************************************************/
  
  DROP TEMPORARY TABLE IF EXISTS tTabelaComTexto;
  
  CREATE TEMPORARY TABLE tTabelaComTexto ( Coluna01 VARCHAR(100)
                                         , Coluna02 VARCHAR(100) 
                                         , Coluna03 VARCHAR(100)
                                         , Coluna04 VARCHAR(100)
                                         , Coluna05 VARCHAR(100)
                                         , Coluna06 VARCHAR(100)
                                         ); 
  
  /****************************************************************/
  /****************CERTIFICAR QUE TODOS OS DADOS FORAM EXCLUÍDOS 
  /****************************************************************/
  DELETE FROM tTabelaComTexto; 
  /****************************************************************/
  /****************INTEGRIDADE DE SOMENTE 6 COLUNAS DE RETORNO 
  /****************************************************************/
  
  IF (oQtdeColunas > 6) THEN 
  BEGIN 
    SET oTexto = ''; 
  END;  
  END IF; 
  
  /****************************************************************/
  /****************PROCESSAR 
  /****************************************************************/
  
  WHILE (_iPos < LENGTH(oTexto)) DO 
  BEGIN
    SET _iPos = _iPos + 1; 
    IF (SUBSTRING(oTexto, _iPos, 1) = oSeparador) THEN 
    BEGIN
      
     
       IF (_iColuna = 1) THEN SET _Valor1 = _Valor;    
      ELSEIF (_iColuna = 2) THEN SET _Valor2 = _Valor;
      ELSEIF (_iColuna = 3) THEN SET _Valor3 = _Valor;
      ELSEIF (_iColuna = 4) THEN SET _Valor4 = _Valor;
      ELSEIF (_iColuna = 5) THEN SET _Valor5 = _Valor;
      ELSEIF (_iColuna = 6) THEN SET _Valor6 = _Valor;
      END IF; 
      
      SET _iColuna = _iColuna + 1; 
      IF (_iColuna > oQtdeColunas) THEN 
      BEGIN
     INSERT INTO tTabelaComTexto 
           VALUES ( _Valor1
                  , _Valor2
                  , _Valor3
                  , _Valor4
                  , _Valor5
                  , _Valor6
                  ); 
     SET _iColuna = 1;			
     SET _Valor1  = '';
     SET _Valor2  = '';
     SET _Valor3  = '';
     SET _Valor4  = '';
     SET _Valor5  = '';
     SET _Valor6  = '';
     SET _iInsere = 0;
      
      END; 
      END IF; 
       
      SET _Valor = ''; 
   END; 
   ELSE
   BEGIN
     
      SET _Valor   = CONCAT(_Valor, SUBSTRING(oTexto, _iPos, 1)); 
      SET _iInsere = 1; 
   END;
   END IF; 
  
  END;
  END WHILE; 
  IF (_iInsere = 1) THEN 
  BEGIN
   
         IF (_iColuna = 1) THEN SET _Valor1 = _Valor;    
     ELSEIF (_iColuna = 2) THEN SET _Valor2 = _Valor;
     ELSEIF (_iColuna = 3) THEN SET _Valor3 = _Valor;
     ELSEIF (_iColuna = 4) THEN SET _Valor4 = _Valor;
     ELSEIF (_iColuna = 5) THEN SET _Valor5 = _Valor;
     ELSEIF (_iColuna = 6) THEN SET _Valor6 = _Valor;
     END IF;
      
     INSERT INTO tTabelaComTexto 
          VALUES ( _Valor1
                 , _Valor2
                 , _Valor3
                 , _Valor4
                 , _Valor5
                 , _Valor6
                 ); 
  END;
  END IF; 
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_TMS_CTE_TERCEIROS_CONCILIAR.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_TMS_CTE_TERCEIROS_CONCILIAR`$$

CREATE PROCEDURE `PROC_TMS_CTE_TERCEIROS_CONCILIAR`(
    IN oTipoOperacao        VARCHAR (1)
   ,IN oCodEmp              VARCHAR (3)
   ,IN oCodFil              VARCHAR (3)
   ,IN oDataInicio          DATETIME
   ,IN oDataFim             DATETIME
   ,IN oTransportador       VARCHAR(14)
   ,IN oNumCte              VARCHAR(9)
   ,IN oNumNfe              VARCHAR(9)
   ,IN oStatusConciliacao   VARCHAR(1)
   ,IN oCodUsuario          VARCHAR(6)
   ,IN oFlgAnalise          VARCHAR(1)
   ,IN oObservAnalise       VARCHAR(300)
   ,IN oStatusAnalise       VARCHAR(30)
   ,IN oIdCtrcTercNf        INT
   ,OUT RESULTADO           VARCHAR (5)
   ,OUT MENSAGEM            VARCHAR (500)
)
BLOCO1 :
BEGIN
  #******************************************************************************************
  # oTipoOpercao = 1 ==> consulta
  #                2 ==> Atualiza conciliacao
  #******************************************************************************************
  
  DECLARE xQtdeAtualizada INT DEFAULT 0 ;
  DECLARE excecao INT DEFAULT 0 ;
  SET RESULTADO = "1" ;
  SET MENSAGEM = "Conciliação realizada com sucesso" ;
  
  IF (oTipoOperacao = 1) THEN
  BEGIN
     SELECT  
         tbCTE.cod_emp
       , tbCTE.cod_fil
       , tbCTE.cnpj_cpf_emi AS cnpj_transportadora
       , tbCTE.raz_soc_emi AS raz_transportadora
       , tbCTE.num_ctrc
       , tbCTE.serie_ctrc
       , tbCTE.dthr_emiss
       , tbCTE.vlr_tot_ctrc AS vlr_frete
       , tbCTE_NF.num_nf
       , tbCTE_NF.serie_nf
       , tbCTE_NF.data_nf
       , tbCTE_NF.peso_brt
       , tbCTE_NF.chave_nfe
       , tbCTE_NF.id_ctrc_terc_nf
       , tbprog_entregas.num_entrega
       , tbprog_entregas.ano_entrega
       , tbprog_entregas.ano_viagem
       , tbprog_entregas.num_viagem
       , tbprog_entregas.valor_entrega
       , tbprog_entregas.peso_brt_entre
       , tbviagens.carro_dia
       , tbviagens.data_viagem
       , tbusuarios.nome_usuario
       , CASE tbCTE_NF.flg_analise   #Nulo=Em Aberto, 0=Reprovado, 1=Aprovado
           WHEN 0 THEN "REPROVADO"
           WHEN 1 THEN "APROVADO"
         ELSE 
           "EM ABERTO"
         END AS flg_analise_aux
       , tbCTE_NF.flg_analise
       , tbCTE_NF.status_analise
       , tbCTE_NF.usu_analise
       , tbCTE_NF.observ_analise
       , tbCTE_NF.dthr_analise       
       , tbusuarios.nome_usuario
       , "N" AS selecionar
       , tbCTE_NF.id_ctrc_terc_nf
       , tbCTE_NF.valor_nf
            FROM tbtms_ctrc_terc2 tbCTE_NF 
      INNER JOIN tbtms_ctrc_terc tbCTE 
              ON tbCTE_NF.cod_emp = tbCTE.cod_emp 
             AND tbCTE_NF.cod_fil = tbCTE.cod_fil 
             AND tbCTE_NF.cnpj_cpf_emi = tbCTE.cnpj_cpf_emi 
             AND tbCTE_NF.num_ctrc = tbCTE.num_ctrc 
             AND tbCTE_NF.serie_ctrc = tbCTE.serie_ctrc 
       LEFT JOIN tbprog_entregas 
              ON tbCTE_NF.cod_emp_entrega = tbprog_entregas.cod_emp
             AND tbCTE_NF.cod_fil_entrega = tbprog_entregas.cod_fil
             AND tbCTE_NF.ano_entrega     = tbprog_entregas.ano_entrega
             AND tbCTE_NF.num_entrega     = tbprog_entregas.num_entrega
       LEFT JOIN tbviagens
              ON tbprog_entregas.cod_emp  = tbviagens.cod_emp
             AND tbprog_entregas.cod_fil  = tbviagens.cod_fil
             AND tbprog_entregas.ano_viagem = tbviagens.ano_viagem
             AND tbprog_entregas.num_viagem = tbviagens.num_viagem
       LEFT JOIN tbusuarios 
              ON tbCTE_NF.usu_analise = tbusuarios.cod_usu
              
     WHERE tbCTE.cod_emp = oCodEmp
       AND tbCTE.cod_fil = oCodFil
       AND tbCTE.dthr_emiss >= oDataInicio
       AND tbCTE.dthr_emiss <= oDataFim 
       AND IF(oTransportador IS NULL, 1 = 1, tbCTE.cnpj_cpf_emi = oTransportador)
       AND IF(oNumCte IS NULL, 1=1, tbCTE.num_ctrc = oNumCte)
       AND IF(oNumNfe IS NULL, 1=1, tbCTE_NF.num_nf = oNumNfe)
       AND IF(oStatusConciliacao > 1, IF(oStatusConciliacao = 2, 1=1, tbCTE_NF.flg_analise IS NULL ),
                tbCTE_NF.flg_analise = oStatusConciliacao);
  END;
  ELSEIF (oTipoOperacao = '2') THEN   
  BEGIN  
     UPDATE tbtms_ctrc_terc2 tbCTE_NF 
        SET tbCTE_NF.status_analise = oStatusAnalise,
            tbCTE_NF.observ_analise = oObservAnalise,
            tbCTE_NF.flg_analise = oflgAnalise,
            tbCTE_NF.usu_analise = oCodUsuario,
            tbCTE_NF.dthr_analise = NOW()
      WHERE tbCTE_NF.id_ctrc_terc_nf = oIdCtrcTercNf;
      
     SET MENSAGEM = 'Entrega Conciliada com Sucesso!!!';
     SET RESULTADO = '1';
  END;
  END IF;
  
  
  IF excecao = 1 THEN 
    SET RESULTADO = "0" ;
    SET MENSAGEM = "Erro SQL - Verifique com o Administrador" ;
  END IF ;
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_TMS_CTE_TERCEIROS_VINCULAR_ENTREGA.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_TMS_CTE_TERCEIROS_VINCULAR_ENTREGA`$$

CREATE PROCEDURE `PROC_TMS_CTE_TERCEIROS_VINCULAR_ENTREGA`(
	IN oCodUsuario				    VARCHAR(10),
	# Parametros de Retorno
	OUT RESULTADO         VARCHAR(5),
	OUT MENSAGEM          VARCHAR(500)
)
BLOCO1:BEGIN
   /***********************************************************************************************************************************************/
   #@Reviser David Ruy <2023-11-17> Ajuste para atualizar o valor_frete (rateio pelo peso) tbtms_ctrc_terc2
   #@Reviser David Ruy <2025-11-14> Ajuste para considerar o processamento apenas dos ultimos 6 meses (180 dias)
   /***********************************************************************************************************************************************/
   DECLARE xQtdeAtualizada INT DEFAULT 0;
   DECLARE excecao         INT DEFAULT 0;
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   DECLARE xdata_viagem      VARCHAR(30);
   DECLARE xcod_emp          VARCHAR(03);
   DECLARE xcod_fil          VARCHAR(03);
   DECLARE xchave_integracao VARCHAR(30);
   SET RESULTADO = "1";
   SET MENSAGEM = "Conciliação realizada com sucesso";
   
   DROP TEMPORARY TABLE IF EXISTS tbTMPCTE_Terc;
   CREATE TEMPORARY TABLE tbTMPCTE_Terc
      SELECT tbCTE.id_remessa AS chave_CTE,
             tbCTE.cod_emp, tbCTE.cod_fil, tbCTE.cnpj_cpf_emi, tbCTE.num_ctrc, tbCTE.serie_ctrc,
             tbCTE_NF.id_ctrc_terc_nf,
             tbCTE_NF.chave_nfe, tbCTE_NF.num_nf, tbCTE_NF.serie_nf,
             tbCTE.vlr_tot_ctrc, 0 flg_processado
      FROM tbtms_ctrc_terc2 tbCTE_NF
      INNER JOIN tbtms_ctrc_terc tbCTE ON 
            tbCTE_NF.cod_emp      = tbCTE.cod_emp
        AND tbCTE_NF.cod_fil      = tbCTE.cod_fil
        AND tbCTE_NF.cnpj_cpf_emi = tbCTE.cnpj_cpf_emi
        AND tbCTE_NF.num_ctrc     = tbCTE.num_ctrc
        AND tbCTE_NF.serie_ctrc   = tbCTE.serie_ctrc
      WHERE tbCTE.dthr_emiss >= DATE_SUB(CURRENT_DATE(), INTERVAL 180 DAY)
        AND tbCTE_NF.cod_emp_entrega IS NULL
        AND tbCTE.data_cancel IS NULL;
      
   UPDATE tbtms_ctrc_terc2 tbCTE_NF
   INNER JOIN tbTMPCTE_Terc ON
         tbCTE_NF.id_ctrc_terc_nf = tbTMPCTE_Terc.id_ctrc_terc_nf 
   INNER JOIN tbnf_clientes ON 
              tbnf_clientes.chave_nfe = tbTMPCTE_Terc.chave_nfe
   INNER JOIN tbprog_entregas ON 
              tbprog_entregas.id_nf = tbnf_clientes.id_nf
   SET  tbCTE_NF.cod_emp_entrega = tbprog_entregas.cod_emp
       ,tbCTE_NF.cod_fil_entrega = tbprog_entregas.cod_fil
       ,tbCTE_NF.ano_entrega     = tbprog_entregas.ano_entrega
       ,tbCTE_NF.num_entrega     = tbprog_entregas.num_entrega;
       #,tbprog_entregas.valor_entrega = tbTMPCTE_Terc.vlr_tot_ctrc;
       
   SELECT ROW_COUNT() INTO xQtdeAtualizada;
   SET MENSAGEM = CONCAT("Conciliação realizada com sucesso - Registros Atualizados : ",xQtdeAtualizada);
   
   
   
   
   #Calcular o Rateio do FRETE das entregas vinculadas
   DROP TEMPORARY TABLE IF EXISTS tbTMSCTE_Calcular;
   CREATE TEMPORARY TABLE tbTMSCTE_Calcular
   SELECT tbCTE.cod_emp, tbCTE.cod_fil, tbCTE.cnpj_cpf_emi, tbCTE.num_ctrc, tbCTE.serie_ctrc, tbCTE.vlr_tot_ctrc,
          (SELECT SUM(tbprog_entregas.peso_brt_entre)
           FROM tbprog_entregas
           INNER JOIN tbtms_ctrc_terc2 ON 
                      tbtms_ctrc_terc2.cod_emp     = tbprog_entregas.cod_emp
                  AND tbtms_ctrc_terc2.cod_fil     = tbprog_entregas.cod_fil
                  AND tbtms_ctrc_terc2.ano_entrega = tbprog_entregas.ano_entrega 
                  AND tbtms_ctrc_terc2.num_entrega = tbprog_entregas.num_entrega
           WHERE tbCTE_NF.cod_emp       = tbtms_ctrc_terc2.cod_emp
             AND tbCTE_NF.cod_fil       = tbtms_ctrc_terc2.cod_fil
             AND tbCTE_NF.cnpj_cpf_emi  = tbtms_ctrc_terc2.cnpj_cpf_emi
             AND tbCTE_NF.num_ctrc      =  tbtms_ctrc_terc2.num_ctrc
             AND tbCTE_NF.serie_ctrc    = tbtms_ctrc_terc2.serie_ctrc
          ) PesoTotNFs,
          (SELECT SUM(tbnf_clientes.vlr_tot_nf)
           FROM tbprog_entregas
           INNER JOIN tbtms_ctrc_terc2 ON 
                      tbtms_ctrc_terc2.cod_emp     = tbprog_entregas.cod_emp
                  AND tbtms_ctrc_terc2.cod_fil     = tbprog_entregas.cod_fil
                  AND tbtms_ctrc_terc2.ano_entrega = tbprog_entregas.ano_entrega 
                  AND tbtms_ctrc_terc2.num_entrega = tbprog_entregas.num_entrega
           INNER JOIN tbnf_clientes ON tbnf_clientes.id_nf = tbprog_entregas.id_nf
           WHERE tbCTE_NF.cod_emp       = tbtms_ctrc_terc2.cod_emp
             AND tbCTE_NF.cod_fil       = tbtms_ctrc_terc2.cod_fil
             AND tbCTE_NF.cnpj_cpf_emi  = tbtms_ctrc_terc2.cnpj_cpf_emi
             AND tbCTE_NF.num_ctrc      =  tbtms_ctrc_terc2.num_ctrc
             AND tbCTE_NF.serie_ctrc    = tbtms_ctrc_terc2.serie_ctrc
          ) ValorTotNFs
   FROM tbTMPCTE_Terc tbCTE
   INNER JOIN tbtms_ctrc_terc2 tbCTE_NF ON 
         tbCTE_NF.cod_emp      = tbCTE.cod_emp
     AND tbCTE_NF.cod_fil      = tbCTE.cod_fil
     AND tbCTE_NF.cnpj_cpf_emi = tbCTE.cnpj_cpf_emi
     AND tbCTE_NF.num_ctrc     = tbCTE.num_ctrc
     AND tbCTE_NF.serie_ctrc   = tbCTE.serie_ctrc
   WHERE tbCTE_NF.cod_emp IS NOT NULL 
   AND tbCTE_NF.valor_frete IS NULL
   GROUP BY cod_emp, cod_fil, cnpj_cpf_emi, num_ctrc, serie_ctrc
   ; 
   
   #select * from tbTMSCTE_Calcular;   
   
   UPDATE tbtms_ctrc_terc2
   INNER JOIN tbprog_entregas ON 
              tbtms_ctrc_terc2.cod_emp     = tbprog_entregas.cod_emp 
          AND tbtms_ctrc_terc2.cod_fil     = tbprog_entregas.cod_fil
          AND tbtms_ctrc_terc2.ano_entrega = tbprog_entregas.ano_entrega 
          AND tbtms_ctrc_terc2.num_entrega = tbprog_entregas.num_entrega
   INNER JOIN tbTMSCTE_Calcular ON
         tbtms_ctrc_terc2.cod_emp      = tbTMSCTE_Calcular.cod_emp
     AND tbtms_ctrc_terc2.cod_fil      = tbTMSCTE_Calcular.cod_fil
     AND tbtms_ctrc_terc2.cnpj_cpf_emi = tbTMSCTE_Calcular.cnpj_cpf_emi
     AND tbtms_ctrc_terc2.num_ctrc     = tbTMSCTE_Calcular.num_ctrc
     AND tbtms_ctrc_terc2.serie_ctrc   = tbTMSCTE_Calcular.serie_ctrc
   SET tbtms_ctrc_terc2.valor_frete = ROUND(tbTMSCTE_Calcular.vlr_tot_ctrc / PesoTotNFs * tbprog_entregas.peso_brt_entre,2);
   
   SET xQtdeAtualizada = ROW_COUNT();
   SET MENSAGEM = CONCAT(MENSAGEM," / Fretes Rateio : ",xQtdeAtualizada);
  
   #Calcular o frete das entregas vinculadas
   DROP TEMPORARY TABLE IF EXISTS tbTMSCTE_Calcular;
   CREATE TEMPORARY TABLE tbTMSCTE_Calcular
      SELECT IFNULL(data_viagem, data_progr) data_viagem, tbprog_entregas.cod_emp, tbprog_entregas.cod_fil, tbprog_entregas.chave_integracao
      FROM tbTMPCTE_Terc
      INNER JOIN tbnf_clientes ON 
                 tbnf_clientes.chave_nfe = tbTMPCTE_Terc.chave_nfe
      INNER JOIN tbprog_entregas ON 
                 tbprog_entregas.id_nf = tbnf_clientes.id_nf
      LEFT JOIN tbviagens ON 
                 tbprog_entregas.cod_emp    = tbviagens.cod_emp 
             AND tbprog_entregas.cod_fil    = tbviagens.cod_fil
             AND tbprog_entregas.ano_viagem = tbviagens.ano_viagem 
             AND tbprog_entregas.num_viagem = tbviagens.num_viagem
      WHERE tbprog_entregas.valor_entrega IS NULL; 
   
   SET xQtdeAtualizada = 0;
   WHILE EXISTS (SELECT 1 FROM tbTMSCTE_Calcular) DO
   
      SELECT data_viagem, cod_emp, cod_fil, chave_integracao 
      INTO xdata_viagem, xcod_emp, xcod_fil, xchave_integracao 
      FROM tbTMSCTE_Calcular LIMIT 1;
   
      CALL PROC_TMS_FRETE_TERCEIROS_BUSCAR(xdata_viagem, xcod_emp, xcod_fil, xchave_integracao, 3);
       
      DELETE FROM tbTMSCTE_Calcular
      WHERE chave_integracao = xchave_integracao;
      SET xQtdeAtualizada= xQtdeAtualizada + 1;
   END WHILE;
   SET MENSAGEM = CONCAT(MENSAGEM," / Fretes Calculados : ",xQtdeAtualizada);
   
   DROP TEMPORARY TABLE IF EXISTS tbTMSCTE_Calcular;
   DROP TEMPORARY TABLE IF EXISTS tbTMPCTE_Terc;
   
   IF excecao = 1 THEN
      SET RESULTADO = "0";
      SET MENSAGEM = "Erro SQL - Verifique com o Administrador";
   END IF;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_WMS_INVENTARIO_TERCEIRO_FINALIZAR.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_WMS_INVENTARIO_TERCEIRO_FINALIZAR`$$

CREATE PROCEDURE `PROC_WMS_INVENTARIO_TERCEIRO_FINALIZAR`(
   IN oIdInventario    INT,
   IN oCodUsuario      VARCHAR(06),
   IN oGerarFechamento INT,
   OUT RESULTADO       INT,
   OUT MENSAGEM        VARCHAR(500)
)
BLOCO1:BEGIN
   /******************************************************************************
   @Author <David Ruy (OVERFLASH)>
   @Creation <2026-04-23>
   @Description : Esta rotina gera o fechamento do inventário atualizando as tabelas 
                  tbwms_inventario_terceiro_fechamento e tbwms_inventario_terceiro_fechamento_serie_lote
   Range oGerarFechamento : 0 - Lista Relatório de Divergencias
                            1 - Listar Relatório de Inventário
                            5 - Fechamento
   *******************************************************************************/

  /****************************************************************/
  /****************DECLARAR VARIÁVEIS AUXILIARES
  /****************************************************************/
   DECLARE excecao                TINYINT DEFAULT 0;
   DECLARE xdthr_leitura_terceiro  DATETIME;
   DECLARE xdthr_retorno_terceiro  DATETIME;
   DECLARE xdata_final             DATETIME;
   DECLARE xtipo_doc_terceiro_entrada  VARCHAR(50);
   DECLARE xchave_doc_terceiro_entrada VARCHAR(50);
   DECLARE xtipo_doc_terceiro_saida    VARCHAR(50);
   DECLARE xchave_doc_terceiro_saida   VARCHAR(50);
   DECLARE xNumContagem INT;
   DECLARE xDtHrFechamento             DATETIME;





   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = fnMensagemExcecao(MENSAGEM);
       ROLLBACK;
   END;
   

  
   #Busca dados do topo do inventário para validações
   SELECT dthr_leitura_terceiro, dthr_retorno_terceiro, data_final, 
          tipo_doc_terceiro_entrada, chave_doc_terceiro_entrada,
          tipo_doc_terceiro_saida, chave_doc_terceiro_saida
   INTO xdthr_leitura_terceiro, xdthr_retorno_terceiro, xdata_final, 
        xtipo_doc_terceiro_entrada, xchave_doc_terceiro_entrada,
        xtipo_doc_terceiro_saida, xchave_doc_terceiro_saida
   FROM tbwms_inventario_terceiro
   WHERE id_inventario = oIdInventario;
   

   IF oGerarFechamento = 5 AND xdata_final IS NOT NULL THEN

      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT("Inventário já foi finalizado - Processo não será realizado, verifique listagem do fechamento !");
      LEAVE bloco1;

   END IF;
   
   
   #Topo : Dados do Inventário
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Ajustes;
   CREATE TEMPORARY TABLE tbTMP_Ajustes
      SELECT tbwms_inventario_terceiro.id_inventario, 
           tbwms_inventario_terceiro.chave_terceiro, tbwms_inventario_terceiro.nome_terceiro,
           tbwms_inventario_terceiro.chave_doc_terceiro_entrada, tbwms_inventario_terceiro.tipo_doc_terceiro_entrada,
           tbwms_inventario_terceiro.chave_doc_terceiro_saida, tbwms_inventario_terceiro.tipo_doc_terceiro_saida
      FROM tbwms_inventario_terceiro
      WHERE tbwms_inventario_terceiro.id_inventario = oIdInventario;

   
   #Itens : Produtos e Quantidades Contábeis
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Ajustes_Item;
   CREATE TEMPORARY TABLE tbTMP_Ajustes_Item
      SELECT tbwms_inventario_terceiro_produto.id_inventario_produto, tbwms_inventario_terceiro_produto.cod_produto,              
             tbwms_inventario_terceiro_produto.fator_conversao,
             (SELECT embalagem_estoque 
              FROM tbwms_inventario_terceiro_produto_serie_lote
              WHERE tbwms_inventario_terceiro_produto_serie_lote.id_inventario_produto = tbwms_inventario_terceiro_produto.id_inventario_produto) AS EmbEstoque,
             (SELECT embalagem_secundaria
              FROM tbwms_inventario_terceiro_produto_serie_lote
              WHERE tbwms_inventario_terceiro_produto_serie_lote.id_inventario_produto = tbwms_inventario_terceiro_produto.id_inventario_produto) AS EmbSecundaria,
           (SELECT SUM(qtde_emb_estoque) 
            FROM tbwms_inventario_terceiro_produto_serie_lote
            WHERE tbwms_inventario_terceiro_produto_serie_lote.id_inventario_produto = tbwms_inventario_terceiro_produto.id_inventario_produto)
            AS QtdeContabil
      FROM tbwms_inventario_terceiro_produto
      INNER JOIN tbTMP_Ajustes ON
                 tbTMP_Ajustes.id_inventario = tbwms_inventario_terceiro_produto.id_inventario;
   
   
   #Series_Lotes : Series/Lotes, Fabr, Validade, Quantidade
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Ajustes_Serie_Lote;
   CREATE TEMPORARY TABLE tbTMP_Ajustes_Serie_Lote
      SELECT tbwms_inventario_terceiro_produto_serie_lote.id_inventario_produto, tbTMP_Ajustes_Item.cod_produto, 
             tbTMP_Ajustes_Item.fator_conversao, tbTMP_Ajustes_Item.EmbEstoque, 
             numero_lote_fabr, numero_serie, data_fabr, data_valid, embalagem_estoque, qtde_emb_estoque
      FROM tbwms_inventario_terceiro_produto_serie_lote
      INNER JOIN tbTMP_Ajustes_Item ON
                 tbTMP_Ajustes_Item.id_inventario_produto = tbwms_inventario_terceiro_produto_serie_lote.id_inventario_produto;
                 
   
   
   #Tabelas Saldo Contábil (DEBUG)
   #SELECT * FROM tbTMP_Ajustes;
   #SELECT * FROM tbTMP_Ajustes_Item;
   #SELECT * FROM tbTMP_Ajustes_Serie_Lote;
   
   
   
/**********************************************************************************/   
   
   
   
   #Tabelas de Inventariados por contagem
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Contagem1;
   CREATE TEMPORARY TABLE tbTMP_Contagem1
   SELECT tbConf.num_contagem,
          tbTMP_Ajustes_Item.id_inventario_produto, tbTMP_Ajustes_Item.cod_produto, tbConf.numero_lote_fabr, tbConf.numero_serie, 
          tbConf.data_valid, tbConf.data_fabr, tbTMP_Ajustes_Item.fator_conversao,
          tbConf.embalagem, tbConf.quantidade QtdeContada, 
          tbTMP_Ajustes_Item.EmbEstoque,
          SUM( 
          IF(tbConf.embalagem = tbTMP_Ajustes_Item.EmbEstoque, tbConf.quantidade, tbConf.quantidade * tbTMP_Ajustes_Item.fator_conversao) 
          ) 
          QtdeInventario
   FROM tbwms_inventario_terceiro_conferencia tbConf
   INNER JOIN tbTMP_Ajustes_Item ON
              tbTMP_Ajustes_Item.id_inventario_produto = tbConf.id_inventario_produto
   WHERE num_contagem = 1
   GROUP BY num_contagem, id_inventario_produto, IFNULL(numero_lote_fabr, numero_serie), IFNULL(data_fabr, ''), IFNULL(data_valid, '');
   
   
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Contagem2;
   CREATE TEMPORARY TABLE tbTMP_Contagem2
   SELECT tbConf.num_contagem,
          tbTMP_Ajustes_Item.id_inventario_produto, tbTMP_Ajustes_Item.cod_produto, tbConf.numero_lote_fabr, tbConf.numero_serie, 
          tbConf.data_valid, tbConf.data_fabr, tbTMP_Ajustes_Item.fator_conversao,
          tbConf.embalagem, tbConf.quantidade QtdeContada, 
          tbTMP_Ajustes_Item.EmbEstoque,
          SUM( 
          IF(tbConf.embalagem = tbTMP_Ajustes_Item.EmbEstoque, tbConf.quantidade, tbConf.quantidade * tbTMP_Ajustes_Item.fator_conversao) 
          ) 
          QtdeInventario
   FROM tbwms_inventario_terceiro_conferencia tbConf
   INNER JOIN tbTMP_Ajustes_Item ON
              tbTMP_Ajustes_Item.id_inventario_produto = tbConf.id_inventario_produto
   WHERE num_contagem = 2
   GROUP BY num_contagem, id_inventario_produto, IFNULL(numero_lote_fabr, numero_serie), IFNULL(data_fabr, ''), IFNULL(data_valid, '');
   
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Contagem3;
   CREATE TEMPORARY TABLE tbTMP_Contagem3
   SELECT tbConf.num_contagem,
          tbTMP_Ajustes_Item.id_inventario_produto, tbTMP_Ajustes_Item.cod_produto, tbConf.numero_lote_fabr, tbConf.numero_serie, 
          tbConf.data_valid, tbConf.data_fabr, tbTMP_Ajustes_Item.fator_conversao,
          tbConf.embalagem, tbConf.quantidade QtdeContada, 
          tbTMP_Ajustes_Item.EmbEstoque,
          SUM( 
          IF(tbConf.embalagem = tbTMP_Ajustes_Item.EmbEstoque, tbConf.quantidade, tbConf.quantidade * tbTMP_Ajustes_Item.fator_conversao) 
          ) 
          QtdeInventario
   FROM tbwms_inventario_terceiro_conferencia tbConf
   INNER JOIN tbTMP_Ajustes_Item ON
              tbTMP_Ajustes_Item.id_inventario_produto = tbConf.id_inventario_produto
   WHERE num_contagem = 3
   GROUP BY num_contagem, id_inventario_produto, IFNULL(numero_lote_fabr, numero_serie), IFNULL(data_fabr, ''), IFNULL(data_valid, '');
   
   
    #SELECT * FROM tbTMP_Contagem1 UNION ALL
    #SELECT * FROM tbTMP_Contagem2 UNION ALL
    #SELECT * FROM tbTMP_Contagem3;
    


/**********************************************************************************/   
    

   #Tabela de Consolidação do Inventário
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Inventario;
   CREATE TEMPORARY TABLE tbTMP_Inventario (
      id_inventario_produto INT,
      cod_produto           VARCHAR(50), 
      numero_lote_fabr      VARCHAR(30), 
      numero_serie          VARCHAR(30),
      data_valid            DATE, 
      data_fabr             DATE, 
      fator_conversao       DECIMAL(18,6),
      EmbEstoque            VARCHAR(10),
      Contagem01            DECIMAL(18,6),
      Contagem02            DECIMAL(18,6),
      Contagem03            DECIMAL(18,6),
      Contabil              DECIMAL(18,6),
      GerarEntrada          DECIMAL(18,6),
      GerarSaida            DECIMAL(18,6),
      PRIMARY KEY (cod_produto, numero_lote_fabr, numero_serie, data_valid, data_fabr)
   );

    #Insere Dados da 1a contagem
    INSERT INTO tbTMP_Inventario (
           id_inventario_produto, cod_produto, numero_lote_fabr, 
           numero_serie, data_valid, data_fabr, 
           fator_conversao, EmbEstoque, 
           Contagem01, Contagem02, Contagem03)
       SELECT id_inventario_produto, cod_produto, IFNULL(numero_lote_fabr,''), 
            IFNULL(numero_serie,''), data_valid, data_fabr, 
            fator_conversao, EmbEstoque, QtdeInventario, 0, 0
       FROM tbTMP_Contagem1;
       
    #Insere Dados da 2a contagem
    INSERT INTO tbTMP_Inventario (
           id_inventario_produto, cod_produto, numero_lote_fabr, 
           numero_serie, data_valid, data_fabr, 
           fator_conversao, EmbEstoque, 
           Contagem01, Contagem02, Contagem03)
       SELECT id_inventario_produto, cod_produto, IFNULL(numero_lote_fabr,''), 
            IFNULL(numero_serie,''), data_valid, data_fabr, 
            fator_conversao, EmbEstoque, QtdeInventario, 0, 0
       FROM tbTMP_Contagem2
    ON DUPLICATE KEY UPDATE  
       Contagem02 = QtdeInventario;
       
    #Insere Dados da 3a contagem
    INSERT INTO tbTMP_Inventario (
           id_inventario_produto, cod_produto, numero_lote_fabr, 
           numero_serie, data_valid, data_fabr, 
           fator_conversao, EmbEstoque, 
           Contagem01, Contagem02, Contagem03)
       SELECT id_inventario_produto, cod_produto, IFNULL(numero_lote_fabr,''), 
            IFNULL(numero_serie,''), data_valid, data_fabr, 
            fator_conversao, EmbEstoque, QtdeInventario, 0, 0
       FROM tbTMP_Contagem3
    ON DUPLICATE KEY UPDATE  
       Contagem03 = QtdeInventario;
       
           
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Contagem1;
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Contagem2;
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Contagem3;
   

   
/******************************************************************************************/   



   #Listar Divergencias de Contagens
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Divergencias;
   CREATE TEMPORARY TABLE tbTMP_Divergencias (
      Mensagem              VARCHAR(200),
      cod_produto           VARCHAR(50), 
      numero_lote_fabr      VARCHAR(30), 
      numero_serie          VARCHAR(30),
      data_valid            DATE, 
      data_fabr             DATE, 
      fator_conversao       DECIMAL(18,6),
      EmbEstoque            VARCHAR(10),
      Contagem01            DECIMAL(18,6),
      Contagem02            DECIMAL(18,6),
      Contagem03            DECIMAL(18,6),
      Contabil              DECIMAL(18,6)
   );

   
   INSERT INTO tbTMP_Divergencias
      SELECT "Divergencias 1a X 2a contagem" AS Mensagem,  
         cod_produto, numero_lote_fabr, numero_serie, 
         data_valid, data_fabr, fator_conversao, EmbEstoque, 
         Contagem01, Contagem02, Contagem03, Contabil              
      FROM tbTMP_Inventario
      WHERE Contagem01 <> Contagem02 AND IFNULL(Contagem03,0) = 0;
    

   INSERT INTO tbTMP_Divergencias
      SELECT "Divergencias 1a ou 2a X 3contagem" AS Mensagem, 
         cod_produto, numero_lote_fabr, numero_serie, 
         data_valid, data_fabr, fator_conversao, EmbEstoque, 
         Contagem01, Contagem02, Contagem03, Contabil                    
      FROM tbTMP_Inventario
      WHERE Contagem03 <> 0 AND Contagem01 <> Contagem03 AND Contagem02 <> Contagem03;

   IF oGerarFechamento = 0 THEN
      SELECT * FROM tbTMP_Divergencias;
   END IF;
   

   IF oGerarFechamento = 5 AND EXISTS (SELECT 1 FROM tbTMP_Divergencias LIMIT 1) THEN
      SET RESULTADO = 0;
      SET MENSAGEM  = "Identificadas Divergencias - Fechamento não pode ser realizado";
   END IF;
   


/******************************************************************************************/   

   
    #Insere Dados das Quantidades Contábeis
   INSERT INTO tbTMP_Inventario (
           id_inventario_produto, cod_produto, numero_lote_fabr, 
           numero_serie, data_valid, data_fabr, 
           fator_conversao, EmbEstoque, Contabil)
       SELECT id_inventario_produto, cod_produto, IFNULL(numero_lote_fabr,''), 
           IFNULL(numero_serie,''), data_valid, data_fabr, 
           fator_conversao, EmbEstoque, qtde_emb_estoque
       FROM tbTMP_Ajustes_Serie_Lote tbContabil 
   ON DUPLICATE KEY UPDATE
      Contabil = tbContabil.qtde_emb_estoque;
   
   
   
   UPDATE tbTMP_Inventario
   SET Contagem01 = IF(IFNULL(Contagem01,0)=0,NULL,Contagem01),
       Contagem02 = IF(IFNULL(Contagem02,0)=0,NULL,Contagem02),
       Contagem03 = IF(IFNULL(Contagem03,0)=0,NULL,Contagem03),
       Contabil   = IF(IFNULL(Contabil,0)=0,NULL,Contabil),
       GerarEntrada = IF( IFNULL(Contagem03, IFNULL(Contagem01,0) ) - IFNULL(Contabil,0) < 0, 0, IFNULL(Contagem03, IFNULL(Contagem01,0)) - IFNULL(Contabil,0) ),
       GerarSaida   = IF( IFNULL(Contabil,0) - IFNULL(Contagem03, IFNULL(Contagem01,0) ) < 0, 0, IFNULL(Contabil,0) - IFNULL(Contagem03, IFNULL(Contagem01,0)) )
       ;
   
   
   IF oGerarFechamento = 1 THEN
      SELECT * FROM tbTMP_Inventario;
   END IF;

      
/******************************************************************************************/   


   #Gera Registros do Fechamento

   IF oGerarFechamento = 5 AND RESULTADO = 1 THEN

      START TRANSACTION;

      SET xDtHrFechamento = NOW();
      INSERT INTO tbwms_inventario_terceiro_fechamento (
            id_inventario, id_inventario_produto, qtde_conferencia_inventario,
            qtde_ajuste_entrada, qtde_ajuste_saida, dthr_inc, usu_inc)
           SELECT oIdInventario, id_inventario_produto, 
                  IFNULL(SUM(IFNULL(Contagem03, Contagem01)), 0), 
                  IFNULL(SUM(GerarEntrada), 0), 
                  IFNULL(SUM(GerarSaida), 0), xDtHrFechamento , oCodUsuario
           FROM tbTMP_Inventario
           GROUP BY id_inventario_produto;
           
      INSERT INTO tbwms_inventario_terceiro_fechamento_serie_lote (
                  id_inventario_fechamento, numero_lote_fabr, numero_serie, 
                  data_fabr, data_valid, qtde_conferencia_inventario, 
                  qtde_ajuste_entrada, qtde_ajuste_saida)
         SELECT tbFech.id_inventario_fechamento, tbTMP_Inventario.numero_lote_fabr, tbTMP_Inventario.numero_serie, 
                  tbTMP_Inventario.data_fabr, tbTMP_Inventario.data_valid,  
                  IFNULL(IFNULL(Contagem03, Contagem01), 0), 
                  IFNULL(GerarEntrada, 0), 
                  IFNULL(GerarSaida, 0)
           FROM tbTMP_Inventario
           INNER JOIN tbwms_inventario_terceiro_fechamento tbFech ON
                      tbFech.id_inventario_produto = tbTMP_Inventario.id_inventario_produto;


       UPDATE tbwms_inventario_terceiro 
       SET data_final = CURRENT_DATE, dthr_alt = NOW(), usu_alt = oCodUsuario
       WHERE id_inventario = oIdInventario;
       
       SET RESULTADO = 1;
       SET MENSAGEM  = "FECHAMENTO REALIZADO COM SUCESSO ! ";

       COMMIT;

   ELSE

      IF oGerarFechamento IN (0,1) THEN
         SET RESULTADO = 1;
         SET MENSAGEM  = "LISTAGEM GERADA COM SUCESSO ! ";
      END IF;
   
   END IF;


/******************************************************************************************/   

   #Excluir tabelas Temporárias
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Ajustes;
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Ajustes_Item;
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Ajustes_Serie_Lote;
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Inventario;
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Divergencias;

   

END$$

DELIMITER ;



/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\PROC_WMS_SAIDA_CANCELAR_GSM_INTEGRACAO.sql*/

DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_WMS_SAIDA_CANCELAR_GSM_INTEGRACAO`$$

CREATE PROCEDURE `PROC_WMS_SAIDA_CANCELAR_GSM_INTEGRACAO`( IN oCodigoEmpresa    VARCHAR(3)
, IN oCodigoFilial     VARCHAR(3)
, IN oAnoProcesso      VARCHAR(4)
, IN oNumeroProcesso   VARCHAR(10)
, OUT RESULTADO		      INT(1)
, OUT MENSAGEM         VARCHAR(255)
)
BLOCO1:BEGIN
  # PROCEDURE PARA CANCELAR GSM VIA INTEGRAÇÃO
  # @author Érico Forcinetti <2019/07/15>
  # @Reviser David ruy <2021/12/06> Cancelamento da entrega no TMS (status_entre)  
  # @company Overflash Informática
  
  /** 
   * ------------------------ INFORMAÇÕES ADICIONAIS -----------------------
   *
   *
   * ---------------------- FIM INFORMAÇÕES ADICIONAIS ---------------------
   */
  
  /****************************************************************/
  /**************** DECLARAR VARIÁVEIS AUXILIARES 
  /****************************************************************/
  
  DECLARE _DthrAtual DATETIME DEFAULT NOW();
  
  /****************************************************************/
  /****************DECLARAR CONTROLE DE EXCEÇÃO DE SQL 
  /****************************************************************/
    
	 DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
   
    ROLLBACK; 
    SET RESULTADO = 0;
    SET MENSAGEM  = fnMensagemExcecao(MENSAGEM);
  END;
	 
  /****************************************************************/
  /**************** INICIAR TRANSAÇÃO 
  /****************************************************************/
	 
  START TRANSACTION; 
	 
	 
  SET RESULTADO	= 1;
	 
	 
  /****************************************************************/
  /**************** SEPARAÇÃO INICIADA 
  /****************************************************************/
  
  IF EXISTS( SELECT 1 
               FROM tbsolic_saidas 
              WHERE tbsolic_saidas.cod_emp           = oCodigoEmpresa
                AND tbsolic_saidas.cod_fil           = oCodigoFilial
                AND tbsolic_saidas.ano_solic         = oAnoProcesso
                AND tbsolic_saidas.num_solic         = oNumeroProcesso
                AND tbsolic_saidas.dthr_inicio_geral IS NOT NULL 
           )
  THEN 
  BEGIN
    
    /****************************************************************/
    /**************** GRAVAR LOG DE REABERTURA DA CONFIRMAÇÃO 
    /****************************************************************/
 
    INSERT INTO tbsolic_saidas_log_reabertura( cod_emp
                                             , cod_fil
                                             , ano_solic
                                             , num_solic
                                             , dthr_confirm
                                             , usu_confirm
                                             , dthr_log
                                             , usu_log
                                             , usu_log_lider
                                             , form_log
                                             , flg_reabertura_tipo
                                             )
      SELECT tbsolic_saidas.cod_emp                   AS cod_emp
           , tbsolic_saidas.cod_fil                   AS cod_fil
           , tbsolic_saidas.ano_solic                 AS ano_solic
           , tbsolic_saidas.num_solic                 AS num_solic
           , tbsolic_saidas.dthr_confirm              AS dthr_confirm
           , tbsolic_saidas.usu_confirm               AS usu_confirm
           , _DthrAtual                               AS dthr_log
           , '999999'                                 AS usu_log
           , NULL                                     AS usu_log_lider
           , 'PROC_WMS_SAIDA_CANCELAR_GSM_INTEGRACAO' AS form_log
           , 2                                        AS flg_reabertura_tipo 
        FROM tbsolic_saidas
       WHERE tbsolic_saidas.cod_emp      = oCodigoEmpresa
         AND tbsolic_saidas.cod_fil      = oCodigoFilial
         AND tbsolic_saidas.ano_solic    = oAnoProcesso
         AND tbsolic_saidas.num_solic    = oNumeroProcesso
         AND tbsolic_saidas.dthr_confirm IS NOT NULL; 
 
    /****************************************************************/
    /**************** ATUALIZAR TOPO 
    /****************************************************************/
  
    /**
     * CANCELAMENTO DEVERÁ SER GERADO VIA TELA DE SUPERVISÃO DE SEPARAÇÃO
     */ 
     
    UPDATE tbsolic_saidas
       SET tbsolic_saidas.dthr_confirm    = NULL 
         , tbsolic_saidas.usu_confirm     = NULL 
         , tbsolic_saidas.status_processo = 11
         , tbsolic_saidas.num_agrup_geral = NULL
         , tbsolic_saidas.dthr_bloqueio_fin = IF(     tbsolic_saidas.dthr_bloqueio_ini IS NOT NULL 
                                                  AND tbsolic_saidas.dthr_bloqueio_fin IS     NULL 
                                                , _DthrAtual
                                                , tbsolic_saidas.dthr_bloqueio_fin
                                                )
         , tbsolic_saidas.usu_bloqueio_fin  = IF(     tbsolic_saidas.usu_bloqueio_ini IS NOT NULL 
                                                  AND tbsolic_saidas.usu_bloqueio_fin IS     NULL 
                                                , '999999'
                                                , tbsolic_saidas.usu_bloqueio_fin
                                                )
     WHERE tbsolic_saidas.cod_emp         = oCodigoEmpresa
       AND tbsolic_saidas.cod_fil         = oCodigoFilial
       AND tbsolic_saidas.ano_solic       = oAnoProcesso
       AND tbsolic_saidas.num_solic       = oNumeroProcesso
       AND tbsolic_saidas.status_processo <> 11;
    
    /****************************************************************/
    /**************** FINALIZAR RECURSOS
    /****************************************************************/
  
    UPDATE tbrf_recurso
       SET tbrf_recurso.dthr_fin        = _DthrAtual
         , tbrf_recurso.flg_concluido   = 1 
         , tbrf_recurso.usu_desktop_fin = '999999'
     WHERE tbrf_recurso.cod_emp_saida   = oCodigoEmpresa
       AND tbrf_recurso.cod_fil_saida   = oCodigoFilial
       AND tbrf_recurso.ano_solic_saida = oAnoProcesso
       AND tbrf_recurso.num_solic_saida = oNumeroProcesso
       AND tbrf_recurso.cod_funcao      IN (2, 4)
       AND tbrf_recurso.dthr_fin        IS NULL;
   
  END; 
  
  /****************************************************************/
  /**************** SEPARAÇÃO NÃO INICIADA 
  /****************************************************************/
  
  ELSE 
  BEGIN
    
    /**
     * CANCELAMENTO REALIZADO VIA SISTEMA
     */ 
    
    CALL PROC_WMS_SAIDA_CANCELAR_GSM( oCodigoEmpresa  
                                    , oCodigoFilial   
                                    , oAnoProcesso    
                                    , oNumeroProcesso
                                    , '999999'
                                    , RESULTADO		      
                                    , MENSAGEM         
                                    ); 
  
    IF (RESULTADO = 0) THEN 
    BEGIN
    
      ROLLBACK; 
      LEAVE BLOCO1; 
    
    END; 
    END IF; 
    
  END;
  END IF;
  
  
  IF RESULTADO = 1 THEN
     #Cancela a Entrega no TMS
     UPDATE tbprog_entregas
     INNER JOIN tbsolic_saidas ON 
           tbsolic_saidas.chave_integracao = tbprog_entregas.chave_integracao
     #inner join tbnf_clientes on 
     #           tbnf_clientes.id_nf = tbprog_entregas.id_nf
     SET tbprog_entregas.status_entre = 9,
         tbprog_entregas.status_baixa = 4,
         tbprog_entregas.ano_viagem = NULL,
         tbprog_entregas.num_viagem = NULL,
         tbprog_entregas.usu_alt = '999999',
         tbprog_entregas.dthr_alt = NOW(),
         tbprog_entregas.observ_baixa = "Cancelamento via integração"
     WHERE tbsolic_saidas.cod_emp   = oCodigoEmpresa
       AND tbsolic_saidas.cod_fil   = oCodigoFilial
       AND tbsolic_saidas.ano_solic = oAnoProcesso
       AND tbsolic_saidas.num_solic = oNumeroProcesso;
  END IF;
 
  
  #*******************************************************************************************
  #**
  #** Se por ventura houver algum erro em alguma etapa do processamento, cancela o processo
  #** inteiro e sinalizado ao usuario. Caso contrario efetiva informações no banco e sinaliza
  #** usuario.
  #**
  #********************************************************************************************
  SET MENSAGEM  = 'OK';
  SET RESULTADO = 1;
  COMMIT; 
  
END$$

DELIMITER ;

/********************************************************/
/**** END - PROCEDURE */
/********************************************************/


/********************************************************/
/**** BEGIN - FUNCTION */
/********************************************************/


/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\fnContarEmbalagens.sql*/

DELIMITER $$

DROP FUNCTION IF EXISTS `fnContarEmbalagens`$$

CREATE FUNCTION `fnContarEmbalagens`( 
   oString VARCHAR(500)
) RETURNS VARCHAR(500) CHARSET latin1
    NO SQL
BEGIN
   DECLARE xvar_str VARCHAR(500) DEFAULT oString;
   DECLARE xstr VARCHAR(500);
   DECLARE xvar_retorno VARCHAR(100);
   
   DROP TEMPORARY TABLE IF EXISTS tbTMPAux;
   CREATE TEMPORARY TABLE tbTMPAux (Coluna01 VARCHAR(30));
   
   SET @x1 = 0;
   WHILE LENGTH(xvar_str) > 0 DO
      IF LOCATE(',',xvar_str) > 0 THEN
         SET xstr = SUBSTR(xvar_str,01,LOCATE(',',xvar_str)-1);
      ELSE
         SET xstr = SUBSTR(xvar_str,01,LENGTH(xvar_str));
      END IF;
      
      SET xvar_str = SUBSTRING(REPLACE(xvar_str, xstr, ''),2,100);
      
      IF LENGTH(xstr) > 0 THEN
         INSERT INTO tbTMPAux VALUES (xstr);
      END IF;
      
      #if @X1 = 3 then
      #   return concat('aqui',xstr,"|",xvar_str);
      #end if;
      #set @X1 =@X1 + 1;
      
   END WHILE;
   
   
   #select group_concat(Coluna01) into xvar_str from tbTMPAux;
   #return xvar_str;
   
   SELECT GROUP_CONCAT(EmbAux) INTO xvar_str
   FROM (
         (SELECT CONCAT(COUNT(Emb),SUBSTRING(Emb,1,1)) EmbAux FROM
            (SELECT DISTINCT coluna01, REPLACE(coluna01, fnSoNumeros(coluna01,''),"") Emb
             FROM tbTMPAux) tbAux
         GROUP BY Emb) 
         ) Tb2;
   
   DROP TEMPORARY TABLE IF EXISTS tbTMPAux;
   
   RETURN TRIM(REPLACE(xvar_str,',',''));
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\fnSoNumeros.sql*/

DELIMITER $$

DROP FUNCTION IF EXISTS `fnSoNumeros`$$

CREATE FUNCTION `fnSoNumeros`( oString VARCHAR(100)
, oExcecao VARCHAR(10)
) RETURNS VARCHAR(100) CHARSET latin1
    NO SQL
BEGIN
	DECLARE xstrPadrao VARCHAR(50);
	DECLARE xvar_str   VARCHAR(100);
	DECLARE xcont	     INT;
	DECLARE xtamanho   INT;
	DECLARE xnew_str   VARCHAR(100);
	
  #String Padrão
  SET xstrPadrao = '0123456789';
  #String Padrão + Exceções de Parametro
  SET xstrPadrao = CONCAT(xstrPadrao,oExcecao);
  #Substitui os caracteres que não estão na Exceção por "»" a string principal
  SET xvar_str := TRIM(oString);
	SET xcont = 1;
	SET xnew_str = '';
  
  SET xtamanho = LENGTH(xvar_str);
  WHILE xcont <= xtamanho DO
		IF LOCATE(SUBSTRING(xvar_str, xcont,1),xstrPadrao) = 0 THEN
		  SET xnew_str = CONCAT(xnew_str, '»');
		ELSE 
		  SET xnew_str = CONCAT(xnew_str,SUBSTRING(xvar_str, xcont,1));
		END IF;
    SET xcont = xcont + 1;
  END WHILE;
  #Limpa os [»]
  SET xvar_str = REPLACE(SUBSTRING(xnew_str, 1,LENGTH(xnew_str)), '»', '');
  #Retorno da Função
  RETURN TRIM(xvar_str);
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\fnStatusCliente.sql*/

DELIMITER $$

DROP FUNCTION IF EXISTS `fnStatusCliente`$$

CREATE FUNCTION `fnStatusCliente`(
   oStatusProcesso    VARCHAR(20),
   oStatusEntrega     VARCHAR(20),
   oStatusBaixa       VARCHAR(20)
   #oDescrStatusBaixa  VARCHAR(50)
) RETURNS TEXT CHARSET latin1
    NO SQL
BEGIN
   /************************************************************************************/
   # Author David Ruy <2024-11-22> Função que monta instrução CASE para condições de Status do Cliente
   /************************************************************************************/
   DECLARE xidStatusSAP INT;
   DECLARE xCodStatusSAP VARCHAR(20);
   DECLARE xDescrStatusSAP VARCHAR(100);
   DECLARE xFormatoRetorno INT;
   DECLARE xStatusProcessoSLIN VARCHAR(50);
   DECLARE xStatusEntregaSLIN VARCHAR(50);
   DECLARE xStatusBaixaSLIN VARCHAR(50);
   DECLARE xCondStatusSAP VARCHAR(200);
   DECLARE xStrCase TEXT;
   DECLARE xStatusCliente TEXT;
   DECLARE xCaseLinha TEXT;
   
   
   DROP TEMPORARY TABLE IF EXISTS tbTMPAux;
   CREATE TEMPORARY TABLE tbTMPAux (SELECT * FROM tbintegraSAP_StatusWMS ORDER BY IdStatusSAP);
   
   SET xStrCase = " Case True ";
   WHILE EXISTS (SELECT 1 FROM tbTMPAux) DO
   
      SELECT idStatusSAP, CodStatusSAP, DescrStatusSAP, FormatoRetorno, StatusProcessoSLIN, StatusEntregaSLIN, StatusBaixaSLIN, CondStatusSAP
      INTO xidStatusSAP, xCodStatusSAP, xDescrStatusSAP, xFormatoRetorno, xStatusProcessoSLIN, xStatusEntregaSLIN, xStatusBaixaSLIN, xCondStatusSAP
      FROM tbTMPAux
      LIMIT 1;
      
      SET xCaseLinha = '';
      
      SET xDescrStatusSAP = REPLACE(xDescrStatusSAP,"DescrStatusBaixa",of_logistica.fnStatusBaixaEntrega(oStatusBaixa));
      
      IF xStatusProcessoSLIN IS NOT NULL THEN
         #SET xStrCase = CONCAT(xStrCase, CONCAT(' when oStatusProcesso ',xStatusProcessoSLIN,' then "',CONCAT(xCodStatusSAP,' - ',xDescrStatusSAP),'"'));
         SET xCaseLinha = CONCAT(xCaseLinha, CONCAT(' when oStatusProcesso ',xStatusProcessoSLIN));
      END IF;
      
      IF xStatusEntregaSLIN IS NOT NULL THEN
         #SET xStrCase = CONCAT(xStrCase, CONCAT(' when oStatusEntrega ',xStatusEntregaSLIN,' then "',CONCAT(xCodStatusSAP,' - ',xDescrStatusSAP),'"'));
         IF xCaseLinha = '' THEN
            SET xCaseLinha = CONCAT(xCaseLinha, CONCAT(' when oStatusEntrega ',xStatusEntregaSLIN));
         ELSE
            SET xCaseLinha = CONCAT(xCaseLinha, CONCAT(' and oStatusEntrega ',xStatusEntregaSLIN));
         END IF;
      END IF;
      IF xStatusBaixaSLIN IS NOT NULL THEN 
         #SET xStrCase = CONCAT(xStrCase, CONCAT(' when oStatusBaixa ',xStatusBaixaSLIN,' then "',CONCAT(xCodStatusSAP,' - ',xDescrStatusSAP),'"'));
         IF xCaseLinha = '' THEN
            SET xCaseLinha = CONCAT(xCaseLinha, CONCAT(' when oStatusBaixa ',xStatusBaixaSLIN));
         ELSE
            SET xCaseLinha = CONCAT(xCaseLinha, CONCAT(' and oStatusBaixa ',xStatusBaixaSLIN));
         END IF;
      END IF;
      
      IF xCondStatusSAP IS NOT NULL THEN
         IF xCaseLinha = '' THEN
            SET xCaseLinha = CONCAT(xCaseLinha, CONCAT(' when ', xCondStatusSAP));
         ELSE
            SET xCaseLinha = CONCAT(xCaseLinha, ' and ', xCondStatusSAP);
         END IF;
      END IF;
      
      IF xFormatoRetorno = 1 THEN
         SET xStrCase = CONCAT(xStrCase, xCaseLinha, ' then "',xCodStatusSAP,'"');
      ELSEIF xFormatoRetorno = 2 THEN
         SET xStrCase = CONCAT(xStrCase, xCaseLinha, ' then "',xDescrStatusSAP,'"');
      ELSEIF xFormatoRetorno = 3 THEN
         SET xStrCase = CONCAT(xStrCase, xCaseLinha, ' then "',CONCAT(xCodStatusSAP,' - ',xDescrStatusSAP),'"');
      END IF;
      
      DELETE FROM tbTMPAux WHERE idStatusSAP = xidStatusSAP;
      
   END WHILE;
   
   SET xStrCase = CONCAT(xStrCase, ' ELSE "N/A"');
   SET xStrCase = CONCAT(xStrCase,' end into @xStatusCliente');
     
   DROP TEMPORARY TABLE IF EXISTS tbTMPAux;
   
   SET xStatusCliente = CONCAT('SELECT ',xStrCase);
   #PREPARE SQL_StatusCliente FROM @xStatusCliente;
   #EXECUTE SQL_StatusCliente; #USING @a, @b;
   #DEALLOCATE PREPARE SQL_StatusCliente;
   RETURN xStatusCliente;
   
END$$

DELIMITER ;

/*C:\Users\druyo\OneDrive - OVERFLASH Informatica Ltda\Scripts\Integração SAP 2018\Processar\fnTirarCaracteresEspeciais.sql*/

DELIMITER $$

DROP FUNCTION IF EXISTS `fnTirarCaracteresEspeciais`$$

CREATE FUNCTION `fnTirarCaracteresEspeciais`( oString	VARCHAR(50)
) RETURNS VARCHAR(50) CHARSET latin1
    NO SQL
BEGIN
	
	IF IFNULL(oString, '') <> '' THEN 
	BEGIN 
	
   SET oString = REPLACE(oString,'.','');
   SET oString = REPLACE(oString,'-','');
   SET oString = REPLACE(oString,'/','');
   SET oString = REPLACE(oString,',','');
   SET oString = REPLACE(oString,'ƒ','');
#TIL
   SET oString = REPLACE(oString,'Ã','A');
   SET oString = REPLACE(oString,'ã','a');
   SET oString = REPLACE(oString,'õ','o');
   SET oString = REPLACE(oString,'Õ','O');
#CIRCUNFLEXO
   SET oString = REPLACE(oString,'â','a');
   SET oString = REPLACE(oString,'Â','A');
   SET oString = REPLACE(oString,'Ê','E');
   SET oString = REPLACE(oString,'ê','e');
   SET oString = REPLACE(oString,'ô','o');
   SET oString = REPLACE(oString,'Ô','O');
#AGUDO
   SET oString = REPLACE(oString,'Á','A');
   SET oString = REPLACE(oString,'á','a');
   SET oString = REPLACE(oString,'É','E');
   SET oString = REPLACE(oString,'é','e');
   SET oString = REPLACE(oString,'Í','I');
   SET oString = REPLACE(oString,'í','i');
   SET oString = REPLACE(oString,'Ó','O');
   SET oString = REPLACE(oString,'ó','o');
   SET oString = REPLACE(oString,'Ú','U');
   SET oString = REPLACE(oString,'ú','u');
#CRASE
   SET oString = REPLACE(oString,'À','A');
   SET oString = REPLACE(oString,'à','a');
   SET oString = REPLACE(oString,'È','E');
   SET oString = REPLACE(oString,'è','e');
   SET oString = REPLACE(oString,'Ì','I');
   SET oString = REPLACE(oString,'ì','i');
   SET oString = REPLACE(oString,'Ò','O');
   SET oString = REPLACE(oString,'ò','o');
   SET oString = REPLACE(oString,'Ù','U');
   SET oString = REPLACE(oString,'ù','u');
#CEDILHA 
   SET oString = REPLACE(oString,'ç','c');
   SET oString = REPLACE(oString,'Ç','c');
#ORDINAIS
   SET oString = REPLACE(oString,'º','');
   SET oString = REPLACE(oString,'ª','');
   SET oString = REPLACE(oString,'€','');
   SET oString = REPLACE(oString,'¡','');
   SET oString = REPLACE(oString,'£','');
   SET oString = REPLACE(oString,'&','');
   SET oString = REPLACE(oString,'*','');
   
   RETURN oString;
	
	END; 
	ELSE 
 BEGIN 
   
   RETURN oString;	
   
 END; 
	END IF;
	
END$$

DELIMITER ;

/********************************************************/
/**** END - FUNCTION */
/********************************************************/

