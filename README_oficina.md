# 🔧 Projeto Lógico de Banco de Dados — Oficina Mecânica

## 📋 Descrição do Projeto

Este projeto implementa o **esquema lógico relacional** para um sistema de controle e gerenciamento de uma oficina mecânica, desenvolvido como desafio da formação **SQL Database Specialist** da DIO.

O modelo cobre todo o ciclo de atendimento de uma oficina: do cadastro do cliente e veículo, passando pela abertura e execução de ordens de serviço, alocação de mecânicos por equipe, consumo de peças e serviços, até a entrega final do veículo.

---

## 🗂 Arquivos

```
├── oficina_schema.sql    # Script completo: DDL + DML + Queries
└── README.md
```

---

## 🏗 Mapeamento ER → Relacional

### Entidades e Tabelas

| Entidade Conceitual | Tabela(s) Relacional(is) | Observação |
|---|---|---|
| Cliente | `cliente`, `cliente_pf`, `cliente_pj` | Especialização PF/PJ |
| Veículo | `veiculo` | FK para `cliente` |
| Equipe | `equipe` | Agrupa mecânicos |
| Mecânico | `mecanico` | FK para `equipe` |
| Ordem de Serviço | `ordemServico` | Entidade central |
| Serviço | `servico` | Catálogo de serviços |
| Peça | `peca` | Catálogo com estoque |

### Relacionamentos M:N mapeados

| Relacionamento | Tabela associativa | Atributos extras |
|---|---|---|
| OS ↔ Serviço | `os_servico` | quantidade, valorCobrado, statusServico |
| OS ↔ Peça | `os_peca` | quantidade, valorUnitario (snapshot) |
| Mecânico ↔ OS | `mecanico_os` | funcao, horasTrab |

### Especialização de Cliente

A entidade **Cliente** foi especializada em PF e PJ usando o padrão de **herança com tabelas separadas**:

```
cliente (base)
    ├── cliente_pf  → CPF, nome, dataNasc
    └── cliente_pj  → CNPJ, razaoSocial, nomeFantasia
```

A coluna `tipoCliente ENUM('PF','PJ')` na tabela base garante exclusividade mútua.

---

## 📐 Diagrama de Relacionamentos

```
cliente ──┬── cliente_pf
          └── cliente_pj
               │
veiculo ───────┘ (FK: idCliente)
    │
ordemServico ──────────────────── equipe ──── mecanico
    │                                              │
    ├── os_servico ── servico            mecanico_os
    └── os_peca    ── peca
```

---

## 🔍 Queries Implementadas

| # | Pergunta respondida | Recursos SQL |
|---|---|---|
| Q1 | Quais veículos estão cadastrados e quem são seus donos? | `SELECT`, `JOIN`, `CASE WHEN`, `ORDER BY` |
| Q2 | Quais OS estão em aberto? | `WHERE NOT IN`, `JOIN` |
| Q3 | Qual o valor total de cada OS (mão de obra + peças)? | Atributo derivado, `SUM`, `GROUP BY` |
| Q4 | Quais mecânicos trabalharam mais horas? | `ORDER BY`, `SUM`, `AVG` |
| Q5 | Quais clientes são recorrentes (mais de 1 OS)? | `HAVING`, `DATEDIFF` |
| Q6 | Qual o detalhamento completo de cada OS? | Multi-`JOIN`, `GROUP_CONCAT` |
| Q7 | Quais equipes geraram mais receita em OS entregues? | `HAVING > 500`, `SUM` |
| Q8 | Veículos com alta km: quantas OS fizeram? | `WHERE`, `CASE WHEN`, atributo derivado |
| Q9 | Quais peças são mais consumidas? | `ORDER BY`, alerta de estoque derivado |
| Q10 | Quais categorias de serviço são mais demandadas? | `GROUP BY`, `ROUND`, subquery |
| Q11 | Quais OS estão paradas (gargalos)? | `WHERE` composto, `DATEDIFF` |
| Q12 | Ranking de clientes por valor total gasto | `RANK() OVER`, `SUM` duplo |

---

## 🚀 Como Executar

**Pré-requisitos:** MySQL 8.0+

```bash
# Conectar ao MySQL
mysql -u root -p

# Executar o script
source oficina_schema.sql;

# Verificar estrutura
USE oficina;
SHOW TABLES;
```

---

## 🧩 Tecnologias

- **MySQL 8.0** — SGBD relacional
- **SQL** — DDL, DML, DQL (SELECT, JOIN, GROUP BY, HAVING, ORDER BY, Window Functions)

---

## 👤 Autor

Desafio de Projeto — Formação SQL Database Specialist | DIO
