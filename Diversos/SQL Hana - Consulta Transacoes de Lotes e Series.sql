
CREATE TABLE tbintegraSAP_Lotes (
num_lote_serie  VARCHAR(30),
DocRemessaArmaz INT,
DocRecebArmaz   IN,
DocRemessaArmaz_Dev INT,
DocRecebArmaz_Dev   IN);

INSERT INTO tbintegraSAP_Lotes
VALUES ();



#N° Serie : DeliveryNotes
SELECT top 20000 T0."ApplyEntry",T0."AppDocNum",T0."DocDate",T0."CardCode",
T0."CardName",T1."ItemCode",Ti."ItemName",
T1."Quantity", T2."DistNumber"
FROM OITL T0
INNER JOIN OITM Ti ON Ti."ItemCode" = T0."ItemCode"
INNER JOIN OSRN T2 ON T2."ItemCode" = t0."ItemCode" 
INNER JOIN ITL1 T1 ON T0."LogEntry" = T1."LogEntry" AND T1."SysNumber" = T2."SysNumber"
WHERE T0."ManagedBy" = 10000045
AND T0."DocType" = 15 / 20
AND T0."DocEntry" = 177 / 1157

UNION

#N° Lotes : DeliveryNotes
SELECT top 20000 T0."ApplyEntry",T0."AppDocNum",T0."DocDate",T0."CardCode",
T0."CardName",T1."ItemCode",Ti."ItemName",
T1."Quantity", T2."DistNumber"
FROM OITL T0
INNER JOIN OITM Ti ON Ti."ItemCode" = T0."ItemCode"
INNER JOIN OBTN T2 ON T2."ItemCode" = t0."ItemCode" 
INNER JOIN ITL1 T1 ON T0."LogEntry" = T1."LogEntry" AND T1."SysNumber" = T2."SysNumber"
WHERE T0."ManagedBy" = 10000044
AND T0."DocType" = 15 / 20
AND T0."ApplyEntry" = 157 / 1144




#Rodado em 20200522
SELECT top 20000 T0."ApplyEntry",T0."AppDocNum",T0."DocDate",T0."CardCode",
T0."CardName",T1."ItemCode",Ti."ItemName",
T1."Quantity", T2."DistNumber"
FROM OITL T0
INNER JOIN OITM Ti ON Ti."ItemCode" = T0."ItemCode"
INNER JOIN OSRN T2 ON T2."ItemCode" = t0."ItemCode" 
INNER JOIN ITL1 T1 ON T0."LogEntry" = T1."LogEntry" AND T1."SysNumber" = T2."SysNumber"
WHERE T0."ManagedBy" = 10000045
AND T0."DocType" = 15
AND T0."AppDocNum" IN (10,11,12,18,22,23,24,25,26,27,28,29,30)
#
#AND T0."DocType" = 20
#AND T0."AppDocNum" IN (899,900,902,903,904,905,907,908,909,910,911,912,915)

UNION

SELECT top 20000 T0."ApplyEntry",T0."AppDocNum",T0."DocDate",T0."CardCode",
T0."CardName",T1."ItemCode",Ti."ItemName",
T1."Quantity", T2."DistNumber"
FROM OITL T0
INNER JOIN OITM Ti ON Ti."ItemCode" = T0."ItemCode"
INNER JOIN OBTN T2 ON T2."ItemCode" = t0."ItemCode" 
INNER JOIN ITL1 T1 ON T0."LogEntry" = T1."LogEntry" AND T1."SysNumber" = T2."SysNumber"
WHERE T0."ManagedBy" = 10000044
AND T0."DocType" = 15
AND T0."AppDocNum" IN (10,11,12,18,22,23,24,25,26,27,28,29,30)
#
#AND T0."DocType" = 20
#AND T0."AppDocNum" IN (899,900,902,903,904,905,907,908,909,910,911,912,915)







#Rodado em 20230529
SELECT top 20000 T0."ApplyEntry",T0."AppDocNum",T0."DocDate",T0."CardCode",
T0."CardName",T1."ItemCode",Ti."ItemName",
T1."Quantity", T2."DistNumber"
FROM OITL T0
INNER JOIN OITM Ti ON Ti."ItemCode" = T0."ItemCode"
INNER JOIN OSRN T2 ON T2."ItemCode" = t0."ItemCode" 
INNER JOIN ITL1 T1 ON T0."LogEntry" = T1."LogEntry" AND T1."SysNumber" = T2."SysNumber"
WHERE T0."ManagedBy" = 10000045
AND T0."DocType" = 15
AND T0."AppDocNum" IN (50,58,62,63,65)
--AND T0."DocType" = 20
--AND T0."AppDocNum" IN (1011,1009,1008,1010,1007)

UNION

SELECT top 20000 T0."ApplyEntry",T0."AppDocNum",T0."DocDate",T0."CardCode",
T0."CardName",T1."ItemCode",Ti."ItemName",
T1."Quantity", T2."DistNumber"
FROM OITL T0
INNER JOIN OITM Ti ON Ti."ItemCode" = T0."ItemCode"
INNER JOIN OBTN T2 ON T2."ItemCode" = t0."ItemCode" 
INNER JOIN ITL1 T1 ON T0."LogEntry" = T1."LogEntry" AND T1."SysNumber" = T2."SysNumber"
WHERE T0."ManagedBy" = 10000044
AND T0."DocType" = 15
AND T0."AppDocNum" IN (50,58,62,63,65)
--AND T0."DocType" = 20
--AND T0."AppDocNum" IN (1011,1009,1008,1010,1007)





/*******************************************************************************/
#Listar Lotes com Saldo de um Produto
SELECT TQ."ItemCode", TQ."WhsCode", TQ."Quantity",TQ."CommitQty", TN."SysNumber", TN."DistNumber", TN."Status"
FROM "OBTQ" TQ
INNER JOIN "OBTN" TN ON
           TQ."ItemCode" = TN."ItemCode"
   AND TQ."SysNumber" = TN."SysNumber"
WHERE TQ."ItemCode" = '1835' 
 AND TQ."WhsCode" = 'RV01' 
AND TN."Status" = '0'
AND (TQ."Quantity" -  IFNULL(TQ."CommitQty",0)) > 0
ORDER BY (TQ."Quantity" -  IFNULL(TQ."CommitQty",0)) DESC 
/*******************************************************************************/












SELECT top 5000 
T0."ApplyEntry",T0."AppDocNum",T0."DocDate",T0."CardCode",
T0."CardName",T1."ItemCode",Ti."ItemName",
T1."Quantity" AS "QtdeSerie", T10."Quantity" AS "QtdeLote" ,T2."DistNumber"
FROM OITL T0
INNER JOIN OITM Ti ON Ti."ItemCode" = T0."ItemCode"
INNER JOIN ODLN Tx ON Tx."DocEntry" = T0."ApplyEntry"
LEFT JOIN OSRN T2 ON T2."ItemCode" = T0."ItemCode" 
LEFT JOIN ITL1 T1 ON T0."LogEntry" = T1."LogEntry" AND T1."SysNumber" = T2."SysNumber"

LEFT JOIN OBTN T20 ON T20."ItemCode" = T0."ItemCode" 
LEFT JOIN ITL1 T10 ON T0."LogEntry" = T10."LogEntry" AND T10."SysNumber" = T20."SysNumber"

WHERE (T1."Quantity" > 0 OR T10."Quantity" > 0)
AND T0."DocType" = 15
AND T0."ApplyEntry" = 177









SELECT T0."DocEntry",T0."DocNum",T0."DocDate",T0."CardCode",
T0."CardName",T1."ItemCode",T1."Dscription",
T1."Quantity",T2."DistNumber"
FROM ODLN T0
INNER JOIN DLN1 T1 ON T0."DocEntry" = T1."DocEntry"
INNER JOIN OITM T3 ON T3."ItemCode" = T1."ItemCode"
INNER JOIN OSRN T2 ON T2."ItemCode" = t1."ItemCode"
INNER JOIN ITL1 T4 ON T4."ItemCode" = T2."ItemCode" AND T4."SysNumber" = T2."SysNumber"
INNER JOIN OITL T5 ON T5."LogEntry" = T4."LogEntry" AND T5."DocType" = '15' --Entrega
WHERE T5."DocEntry" = T0."DocEntry"
AND T0."DocEntry" = 157

SELECT
T0.TaxDate,
T0.CardCode,
T0.CardName,
T0.DocEntry AS "DocEntry",
T0.DocNum AS "Nº Do Doc.",
T0.Serial AS "Nº NF",
T1.ItemCode,
T1.Dscription,
T1.Quantity,
T2.DistNumber
FROM OPDN T0
INNER JOIN DLN1 T1 ON T0.DocEntry = T1.DocEntry
INNER JOIN OSRN T2 ON T2.ItemCode = t1.ItemCode
INNER JOIN OITM T3 ON T3.ItemCode = T2.ItemCode
INNER JOIN ITL1 T4 ON T4.ItemCode = T2.ItemCode AND T4.[SysNumber] = T2.[SysNumber]
INNER JOIN OITL T5 ON T5.LogEntry = T4.LogEntry AND T5.DocType = '20' --Recebimento para Armazenagem
WHERE T5.DocEntry = T0.DocEntry
AND T0.DocEntry = 1







POSTMAN => SQLQueries

GET https://biomedical.ramo.com.br:50000/b1s/v1/SQLQueries('OOne_QRY_GET_ItemSerial')/LIST?xItemCode='PRODN00002'&xNumSerie='00312-0530219'&xWhsCode='CGOKBIO'

POST https://biomedical.ramo.com.br:50000/b1s/v1/SQLQueries
{
    "SqlCode": "OOne_QRY_GET_ItemSerial",
    "SqlName": "OOne_QRY_GET_ItemSerial",
    "SqlText": "SELECT TN.ItemCode, TN.SysNumber, TN.DistNumber, TN.MnfSerial, TN.LotNumber, TN.ExpDate, TN.MnfDate, TN.InDate, TN.GrntStart, TN.GrntExp, TN.CreateDate, TN.Location, TN.Status, TN.Notes, TN.DataSource, TN.UserSign, TN.Transfered, TN.Instance, TN.AbsEntry, TN.ObjType, TN.itemName, TN.LogInstanc, TN.UserSign2, TN.UpdateDate, TN.CostTotal, TN.Quantity, TN.QuantOut, TN.PriceDiff, TN.Balance, TN.TrackingNt, TN.TrackiNtLn, TN.SumDec , TQ.WhsCode, TQ.Quantity 'Q1', TQ.CommitQty 'Q2', TQ.CountQty 'Q3' 
    from OSRN TN  
    inner join OSRQ TQ on TQ.SysNumber = TN.SysNumber
       WHERE TN.ItemCode = :xItemCode       AND TN.DistNumber = :xNumSerie  and TQ.WhsCode = :xWhsCode 
       and TQ.Quantity > 0   
    order by TN.SysNumber DESC"

}



GET https://biomedical.ramo.com.br:50000/b1s/v1/SQLQueries('OOne_QRY_GET_ItemSerial3')/LIST?xItemCode='PRODN00001'&xWhsCode='CGHMD52'&DistNumber1='GJ10532987'&DistNumber2='GJ10532988'&DistNumber3='GJ10532989'&&DistNumber4='GJ10532990'&&DistNumber5='GJ10532991'&&DistNumber6='GJ10532992'&&DistNumber7='GJ10532993'&&DistNumber8='GJ10532994'&&DistNumber9='GJ10532995'&&DistNumber10='GJ10532996'&&DistNumber11='GJ10532997'&&DistNumber12='GJ10532998'&&DistNumber13='GJ10532999'&&DistNumber14='GJ10533000'&&DistNumber15='GJ10533001'&&DistNumber16='GJ10533002'&&DistNumber17='GJ10533003'&&DistNumber18='GJ10533004'&&DistNumber19='GJ10533005'&&DistNumber20='GJ10533006'

POST https://biomedical.ramo.com.br:50000/b1s/v1/SQLQueries
{
    "SqlCode": "OOne_QRY_GET_ItemSerial3",
    "SqlName": "OOne_QRY_GET_ItemSerial3",
    "SqlText": "SELECT TN.ItemCode, TN.SysNumber, TN.DistNumber
    from OSRN TN  
    inner join OSRQ TQ on TQ.SysNumber = TN.SysNumber
       WHERE TN.ItemCode = :xItemCode AND  TQ.WhsCode = :xWhsCode 
       AND TQ.Quantity > 0   
       AND (TN.DistNumber = :DistNumber1 or TN.DistNumber = :DistNumber2 or TN.DistNumber = :DistNumber3 or 
       TN.DistNumber = :DistNumber4 or TN.DistNumber = :DistNumber5 or TN.DistNumber = :DistNumber6 or 
       TN.DistNumber = :DistNumber7 or TN.DistNumber = :DistNumber8 or TN.DistNumber = :DistNumber9 or 
       TN.DistNumber = :DistNumber10 or TN.DistNumber = :DistNumber11 or TN.DistNumber = :DistNumber12 or 
       TN.DistNumber = :DistNumber13 or TN.DistNumber = :DistNumber14 or TN.DistNumber = :DistNumber15 or 
       TN.DistNumber = :DistNumber16 or TN.DistNumber = :DistNumber17 or TN.DistNumber = :DistNumber18 or 
       TN.DistNumber = :DistNumber19 or TN.DistNumber = :DistNumber20)
    order by TN.SysNumber DESC"
}



