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