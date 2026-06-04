# Dicionário de Dados — Modelo Dimensional de Saúde

Este dicionário descreve as tabelas e campos do modelo dimensional construído a partir do dataset sintético de saúde disponibilizado no [Kaggle](https://www.kaggle.com/datasets/prasad22/healthcare-dataset).

---

## Visão Geral do Modelo

O modelo segue o padrão **Star Schema**, composto por uma tabela fato central e quatro tabelas dimensão:

| Tabela | Tipo | Descrição |
|---|---|---|
| `fato_atendimento` | Fato | Eventos de atendimento hospitalar |
| `dim_paciente` | Dimensão | Dados dos pacientes |
| `dim_medico` | Dimensão | Dados dos médicos |
| `dim_hospital` | Dimensão | Dados dos hospitais |
| `dim_seguradora` | Dimensão | Dados das seguradoras |

---

## dim_paciente

Armazena os dados dos pacientes identificados no dataset.

> ⚠️ **Limitação conhecida:** O dataset original não possui identificador único de paciente (CPF, prontuário etc.). A unicidade foi definida pela combinação de `nome_paciente + idade + genero + tipo_sanguineo`. Registros com atributos idênticos são tratados como o mesmo paciente; registros com qualquer diferença nessa combinação são tratados como pacientes distintos — mesmo que na realidade possam ser a mesma pessoa.

| Campo | Tipo | Descrição |
|---|---|---|
| `id_paciente` | SERIAL (PK) | Identificador único gerado automaticamente (chave surrogada) |
| `nome_paciente` | VARCHAR(50) | Nome completo do paciente |
| `idade` | SMALLINT | Idade do paciente no momento da admissão, em anos |
| `genero` | VARCHAR(8) | Gênero do paciente: `Male` ou `Female` |
| `tipo_sanguineo` | VARCHAR(3) | Tipo sanguíneo do paciente (ex: `A+`, `O-`, `B-`) |

---

## dim_medico

Armazena os médicos identificados no dataset.

> ⚠️ **Limitação conhecida:** Foram identificados aproximadamente 40.341 médicos distintos em uma base de 55.500 atendimentos. Esse volume é incompatível com um cenário real, sendo uma característica da geração sintética dos dados. Nenhum tratamento adicional foi realizado.

| Campo | Tipo | Descrição |
|---|---|---|
| `id_medico` | SERIAL (PK) | Identificador único gerado automaticamente (chave surrogada) |
| `nome_medico` | VARCHAR(50) | Nome completo do médico responsável pelo atendimento |

---

## dim_hospital

Armazena os hospitais identificados no dataset.

> ⚠️ **Limitação conhecida:** Foram identificados aproximadamente 39.876 hospitais distintos em uma base de 55.500 atendimentos. Assim como na dimensão de médicos, esse volume reflete a geração artificial dos dados e não representa um cenário realista.

| Campo | Tipo | Descrição |
|---|---|---|
| `id_hospital` | SERIAL (PK) | Identificador único gerado automaticamente (chave surrogada) |
| `nome_hospital` | VARCHAR(40) | Nome da unidade hospitalar |

---

## dim_seguradora

Armazena as operadoras de seguro de saúde.

| Campo | Tipo | Descrição |
|---|---|---|
| `id_seguradora` | SERIAL (PK) | Identificador único gerado automaticamente (chave surrogada) |
| `nome_seguradora` | VARCHAR(40) | Nome da operadora de seguro. Valores presentes: `Aetna`, `Blue Cross`, `Cigna`, `UnitedHealthcare`, `Medicare` |

---

## fato_atendimento

Tabela central do modelo. Cada registro representa um evento de internação hospitalar.

> 📝 **Decisão de modelagem:** Os campos `condicao_clinica`, `medicamento` e `resultado_do_teste` foram mantidos na tabela fato — e não em dimensões separadas — por apresentarem baixa complexidade e escopo simplificado no contexto deste projeto. Em um modelo de produção, poderiam ser candidatos a dimensões próprias dependendo das necessidades analíticas do negócio.

| Campo | Tipo | Descrição |
|---|---|---|
| `id_atendimento` | SERIAL (PK) | Identificador único do atendimento (chave surrogada) |
| `id_paciente` | INT (FK) | Referência à `dim_paciente` |
| `condicao_clinica` | VARCHAR(25) | Condição médica ou diagnóstico principal do atendimento (ex: `Diabetes`, `Cancer`, `Asthma`) |
| `data_admissao` | DATE | Data de admissão do paciente na unidade de saúde |
| `id_medico` | INT (FK) | Referência à `dim_medico` |
| `id_hospital` | INT (FK) | Referência à `dim_hospital` |
| `id_seguradora` | INT (FK) | Referência à `dim_seguradora` |
| `valor_fatura` | NUMERIC(15,2) | Valor cobrado pelos serviços prestados durante a internação |
| `numero_quarto` | SMALLINT | Número do quarto onde o paciente ficou internado |
| `tipo_admissao` | VARCHAR(25) | Circunstância da admissão: `Emergency`, `Elective` ou `Urgent` |
| `data_alta` | DATE | Data de alta do paciente |
| `medicamento` | VARCHAR(30) | Medicamento prescrito ou administrado durante a internação (ex: `Aspirin`, `Paracetamol`, `Lipitor`) |
| `resultado_do_teste` | VARCHAR(50) | Resultado do exame realizado durante a internação: `Normal`, `Abnormal` ou `Inconclusive` |

---

## Relacionamentos

| Tabela Origem | Campo | Tabela Destino | Campo |
|---|---|---|---|
| `fato_atendimento` | `id_paciente` | `dim_paciente` | `id_paciente` |
| `fato_atendimento` | `id_medico` | `dim_medico` | `id_medico` |
| `fato_atendimento` | `id_hospital` | `dim_hospital` | `id_hospital` |
| `fato_atendimento` | `id_seguradora` | `dim_seguradora` | `id_seguradora` |

---

*Documentação elaborada por Rister Silva.*
