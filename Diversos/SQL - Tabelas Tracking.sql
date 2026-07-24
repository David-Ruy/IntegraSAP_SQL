DROP TABLE tbintegraSAP_Tracking;
CREATE TABLE tbintegraSAP_Tracking (
	chave_integracao VARCHAR(50) NOT NULL,
	StatusAtual VARCHAR(200),
	StatusAnt VARCHAR(200),
	NumNotaFiscal VARCHAR(20),
	DataEmissao DATETIME,
	dthr_inc DATETIME,
	dthr_alt DATETIME,
	dthr_integra DATETIME,
	PRIMARY KEY (chave_integracao),
	FOREIGN KEY fk_tbintegraSAP_Tracking (chave_integracao) REFERENCES tbintegraSAP_Doc (chave_integracao))

#About 20 sec (10 dias)
CALL PROC_INTEGRA_RetornoTracking()

SELECT * FROM of_logistica.tbprog_entregas WHERE chave_integracao LIKE 'PV455258%'

SELECT * FROM tbintegraSAP_Tracking

SHOW PROCESSLIST
