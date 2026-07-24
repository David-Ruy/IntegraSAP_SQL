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