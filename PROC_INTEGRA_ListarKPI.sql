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