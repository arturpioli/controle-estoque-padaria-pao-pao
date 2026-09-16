-- Estrutura do banco usado no projeto 

CREATE DATABASE IF NOT EXISTS padaria_estoque;
USE padaria_estoque;

-- Tabela final, com os dados  tratados
CREATE TABLE folhas_estoque (
    id_folha INT AUTO_INCREMENT PRIMARY KEY,
    data_folha DATE NOT NULL,
    status VARCHAR(20) NOT NULL,
    data_lancamento DATE
);

-- Tabela de staging, pega os dados brutos exportados da planilha em CSV
CREATE TABLE staging_estoque (
    col1 VARCHAR(50),
    col2 VARCHAR(50),
    col3 VARCHAR(50),
    col4 VARCHAR(50)
);

-- Carga dos dados brutos na staging (colocar o caminho do arquivo CSV exportado da planilha)
LOAD DATA LOCAL INFILE 'caminho/para/o/arquivo.csv'
INTO TABLE staging_estoque
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(col1, col2, col3, col4);

-- Procedure pra converter os dados da staging e inserir na tabela 
DELIMITER $$

CREATE PROCEDURE sp_importar_staging()
BEGIN
    INSERT INTO folhas_estoque (data_folha, status, data_lancamento)
    SELECT
        STR_TO_DATE(col2, '%d/%m/%Y'),
        col3,
        STR_TO_DATE(NULLIF(col4, ''), '%d/%m/%Y')
    FROM staging_estoque;

    TRUNCATE TABLE staging_estoque;
END$$

DELIMITER //

-- Para importar um novo mês: carregar o CSV na staging (LOAD DATA acima) e depois rodar:
CALL sp_importar_staging();

-- Consultas úteis

-- Total de folhas e quantas estão pendentes
SELECT
    COUNT(*) AS total_folhas,
    SUM(CASE WHEN status = 'NAO LANÇADA' THEN 1 ELSE 0 END) AS pendentes,
    SUM(CASE WHEN status <> 'NAO LANÇADA' THEN 1 ELSE 0 END) AS lancadas
FROM folhas_estoque;

-- Lista das folhas ainda pendentes
SELECT id_folha, data_folha, status
FROM folhas_estoque
WHERE status = 'NAO LANÇADA'
ORDER BY data_folha;
