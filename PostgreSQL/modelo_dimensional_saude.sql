-- Script de criação da tabela STAGING utilizada no processo ETL do Pentaho

CREATE TABLE stg_atendimentos
(
Nome VARCHAR(50)
, Idade SMALLINT
, Genero VARCHAR(8)
, Tipo_sanguineo VARCHAR(4)
, Condicao_medica VARCHAR(25)
, Data_admissao TIMESTAMP
, Medico VARCHAR(40)
, Hospital VARCHAR(40)
, Seguradora VARCHAR(40)
, Valor_fatura NUMERIC(17, 2)
, Numero_quarto SMALLINT
, Tipo_admissao VARCHAR(25)
, Data_alta TIMESTAMP
, Medicamento VARCHAR(30)
, Resultado_do_teste VARCHAR(40)
);

-- Inserção dos dados também pelo Pentaho.


/*

Adequação dos tipos de dados após a carga na STAGING.

Os campos de data são convertidos para DATE por não
haver necessidade de armazenar horário.

O campo de faturamento é ajustado para NUMERIC(15,2),
adequado para valores monetários.

*/

ALTER TABLE stg_atendimentos
ALTER COLUMN data_admissao TYPE DATE;

ALTER TABLE stg_atendimentos
ALTER COLUMN data_alta TYPE DATE;

ALTER TABLE stg_atendimentos
ALTER COLUMN valor_fatura TYPE NUMERIC(15,2);

-- Consulta padrão limitada a 100 registros
select count(*)
from stg_atendimentos
limit 100;

-- Criação das tabelas de dimensões
-- 1) Tabela de pacientes

CREATE TABLE  IF NOT EXISTS dim_paciente (
  id_paciente SERIAL PRIMARY KEY,
  nome_paciente VARCHAR(50),
  idade SMALLINT,
  genero VARCHAR(8),
  tipo_sanguineo VARCHAR(3)
);

-- 2) Tabela de medicos

CREATE TABLE  IF NOT EXISTS dim_medico (
  id_medico SERIAL PRIMARY KEY,
  nome_medico VARCHAR(50)
);

-- 3) tabela de hospitais

CREATE TABLE  IF NOT EXISTS dim_hospital (
  id_hospital SERIAL PRIMARY KEY,
  nome_hospital VARCHAR(40)
);


-- 4) Tabela de seguradoras

CREATE TABLE  IF NOT EXISTS dim_seguradora (
  id_seguradora SERIAL PRIMARY KEY,
  nome_seguradora VARCHAR(40)
);

-- Criação da tabela fato

/*
Tabela fato responsável por armazenar os eventos
de atendimento, referenciando as dimensões de
paciente, médico, hospital e seguradora.
*/

/*
Condição clínica, medicamento e resultado do teste
foram mantidos na tabela fato devido à baixa
cardinalidade e ao escopo simplificado do projeto.
*/

CREATE TABLE IF NOT EXISTS fato_atendimento (
	id_atendimento SERIAL PRIMARY KEY,
	id_paciente INT REFERENCES dim_paciente(id_paciente),
	condicao_clinica VARCHAR(25),
	data_admissao DATE,
	id_medico INT REFERENCES dim_medico(id_medico),
	id_hospital INT REFERENCES dim_hospital(id_hospital),
	id_seguradora INT REFERENCES dim_seguradora(id_seguradora),
	valor_fatura NUMERIC(15,2),
	numero_quarto SMALLINT,
	tipo_admissao VARCHAR (25),
	data_alta DATE,
	medicamento VARCHAR(30),
	resultado_do_teste VARCHAR(50)
);


-- Carga das dimensões

/*

Não existe um identificador único de paciente no dataset
(CPF, prontuário, ID etc.).

Dessa forma, a unicidade do paciente foi definida pela
combinação de Nome, Idade, Gênero e Tipo Sanguíneo.

Essa abordagem pode gerar pacientes distintos sendo
tratados como o mesmo indivíduo caso possuam exatamente
os mesmos atributos.

*/

-- 1) Pacientes
INSERT INTO dim_paciente (nome_paciente, idade, genero, tipo_sanguineo)
SELECT 
DISTINCT 
	nome, 
	idade, 
	genero, 
	tipo_sanguineo
FROM stg_atendimentos;


-- 2) médicos

INSERT INTO dim_medico (nome_medico)
SELECT 
	DISTINCT medico
FROM stg_atendimentos;

/*
Observação:

Foram identificados aproximadamente 40.341 médicos distintos
no dataset. Considerando o volume total de registros, essa
quantidade sugere baixa recorrência dos profissionais e não
representa um cenário realista para dados hospitalares.

Por se tratar de um dataset sintético, assumiu-se que essa
característica é decorrente da geração artificial dos dados.
*/

-- 3) hospitais

INSERT INTO dim_hospital (nome_hospital)
SELECT 
	DISTINCT hospital
FROM stg_atendimentos;

/*
Observação:

Foram identificados aproximadamente 39.876 hospitais distintos
no dataset. Esse volume é incompatível com um cenário real
para a quantidade de registros analisada, indicando uma alta
cardinalidade gerada artificialmente.

Nenhum tratamento adicional foi realizado, uma vez que o
objetivo do projeto é demonstrar o processo de ETL e
modelagem dimensional utilizando dados sintéticos.
*/

-- 4) seguradoras

INSERT INTO dim_seguradora (nome_seguradora)
SELECT 
	DISTINCT seguradora
FROM stg_atendimentos;

-- Carga da tabela fato

/*
Aliases utilizados:
stg = tabela staging
dp  = dimensão paciente
dm  = dimensão médico
dh  = dimensão hospital
ds  = dimensão seguradora
*/

INSERT INTO fato_atendimento (
	id_paciente,
	condicao_clinica,
	data_admissao,
	id_medico,
	id_hospital,
	id_seguradora,
	valor_fatura,
	numero_quarto,
	tipo_admissao,
	data_alta,
	medicamento,
	resultado_do_teste
	)
SELECT
	dp.id_paciente,
	stg.condicao_medica,
	stg.data_admissao,
	dm.id_medico,
	dh.id_hospital,
	ds.id_seguradora,
	stg.valor_fatura,
	stg.numero_quarto,
	stg.tipo_admissao,
	stg.data_alta, 
	stg.medicamento, 
	stg.resultado_do_teste
FROM stg_atendimentos AS stg
JOIN dim_paciente AS dp
ON dp.nome_paciente = stg.nome
AND dp.idade = stg.idade
AND dp.genero = stg.genero
AND dp.tipo_sanguineo = stg.tipo_sanguineo
JOIN dim_medico AS dm
ON dm.nome_medico = stg.medico
JOIN dim_hospital AS dh
ON dh.nome_hospital = stg.hospital
JOIN dim_seguradora AS ds
On ds.nome_seguradora = stg.seguradora;




