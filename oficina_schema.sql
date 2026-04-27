-- ============================================================
-- PROJETO LÓGICO DE BANCO DE DADOS — OFICINA MECÂNICA
-- Mapeamento: Esquema ER → Relacional
-- Contexto: Sistema de controle e gerenciamento de execução
--           de ordens de serviço em uma oficina mecânica
-- ============================================================

DROP DATABASE IF EXISTS oficina;
CREATE DATABASE oficina;
USE oficina;

-- ============================================================
-- BLOCO 1 — ENTIDADES PRINCIPAIS
-- ============================================================

-- Cliente (PF ou PJ)
CREATE TABLE cliente (
    idCliente   INT          AUTO_INCREMENT PRIMARY KEY,
    tipoCliente ENUM('PF','PJ') NOT NULL,
    telefone    VARCHAR(15)  NOT NULL,
    email       VARCHAR(100),
    endereco    VARCHAR(255)
);

CREATE TABLE cliente_pf (
    idCliente   INT         PRIMARY KEY,
    nome        VARCHAR(100) NOT NULL,
    cpf         CHAR(11)     NOT NULL,
    dataNasc    DATE,
    CONSTRAINT uq_cpf_pf   UNIQUE (cpf),
    CONSTRAINT fk_cpf_cli  FOREIGN KEY (idCliente) REFERENCES cliente(idCliente)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE cliente_pj (
    idCliente   INT          PRIMARY KEY,
    razaoSocial VARCHAR(150) NOT NULL,
    cnpj        CHAR(14)     NOT NULL,
    nomeFantasia VARCHAR(150),
    CONSTRAINT uq_cnpj_pj  UNIQUE (cnpj),
    CONSTRAINT fk_cnpj_cli FOREIGN KEY (idCliente) REFERENCES cliente(idCliente)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- Veículo (pertence a um cliente)
CREATE TABLE veiculo (
    idVeiculo   INT          AUTO_INCREMENT PRIMARY KEY,
    idCliente   INT          NOT NULL,
    placa       VARCHAR(10)  NOT NULL,
    marca       VARCHAR(50)  NOT NULL,
    modelo      VARCHAR(80)  NOT NULL,
    ano         YEAR         NOT NULL,
    cor         VARCHAR(30),
    quilometragem INT        DEFAULT 0,
    CONSTRAINT uq_placa     UNIQUE (placa),
    CONSTRAINT fk_vei_cli   FOREIGN KEY (idCliente) REFERENCES cliente(idCliente)
        ON UPDATE CASCADE
);

-- Equipe de mecânicos
CREATE TABLE equipe (
    idEquipe    INT         AUTO_INCREMENT PRIMARY KEY,
    nomeEquipe  VARCHAR(80) NOT NULL,
    especialidade VARCHAR(100)
);

-- Mecânico
CREATE TABLE mecanico (
    idMecanico  INT         AUTO_INCREMENT PRIMARY KEY,
    idEquipe    INT,
    nome        VARCHAR(100) NOT NULL,
    cpf         CHAR(11)     NOT NULL,
    endereco    VARCHAR(255),
    especialidade VARCHAR(100),
    CONSTRAINT uq_cpf_mec  UNIQUE (cpf),
    CONSTRAINT fk_mec_eqp  FOREIGN KEY (idEquipe) REFERENCES equipe(idEquipe)
        ON UPDATE CASCADE ON DELETE SET NULL
);

-- Serviço (catálogo de serviços disponíveis)
CREATE TABLE servico (
    idServico   INT           AUTO_INCREMENT PRIMARY KEY,
    descricao   VARCHAR(255)  NOT NULL,
    categoria   ENUM('Revisão','Elétrica','Funilaria','Suspensão',
                     'Motor','Freios','Ar Condicionado','Diagnóstico','Outros') NOT NULL,
    valorMaoObra DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    tempoPrevisto INT          COMMENT 'Tempo previsto em minutos'
);

-- Peça (catálogo de peças)
CREATE TABLE peca (
    idPeca      INT           AUTO_INCREMENT PRIMARY KEY,
    nome        VARCHAR(150)  NOT NULL,
    descricao   VARCHAR(255),
    valorUnitario DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    quantEstoque  INT          DEFAULT 0,
    fabricante  VARCHAR(100)
);

-- ============================================================
-- BLOCO 2 — ORDEM DE SERVIÇO (entidade central)
-- ============================================================

CREATE TABLE ordemServico (
    idOS            INT           AUTO_INCREMENT PRIMARY KEY,
    idVeiculo       INT           NOT NULL,
    idEquipe        INT,
    numeroOS        VARCHAR(20)   NOT NULL,
    dataEmissao     DATETIME      DEFAULT CURRENT_TIMESTAMP,
    dataConclusao   DATETIME,
    dataPrevista    DATE,
    status          ENUM('Aguardando avaliação','Em andamento',
                         'Aguardando peças','Concluída','Cancelada',
                         'Entregue') DEFAULT 'Aguardando avaliação',
    autorizado      BOOLEAN       DEFAULT FALSE,
    observacoes     VARCHAR(500),
    CONSTRAINT uq_os_numero     UNIQUE (numeroOS),
    CONSTRAINT fk_os_vei        FOREIGN KEY (idVeiculo) REFERENCES veiculo(idVeiculo)
        ON UPDATE CASCADE,
    CONSTRAINT fk_os_eqp        FOREIGN KEY (idEquipe)  REFERENCES equipe(idEquipe)
        ON UPDATE CASCADE ON DELETE SET NULL
);

-- ============================================================
-- BLOCO 3 — RELACIONAMENTOS M:N
-- ============================================================

-- OS × Serviço (uma OS pode ter vários serviços)
CREATE TABLE os_servico (
    idOS            INT           NOT NULL,
    idServico       INT           NOT NULL,
    quantidade      INT           DEFAULT 1,
    valorCobrado    DECIMAL(10,2) NOT NULL COMMENT 'Valor efetivo cobrado (pode diferir do catálogo)',
    statusServico   ENUM('Pendente','Em execução','Concluído','Cancelado') DEFAULT 'Pendente',
    PRIMARY KEY (idOS, idServico),
    CONSTRAINT fk_oss_os  FOREIGN KEY (idOS)      REFERENCES ordemServico(idOS) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_oss_srv FOREIGN KEY (idServico) REFERENCES servico(idServico) ON UPDATE CASCADE
);

-- OS × Peça (uma OS pode usar várias peças)
CREATE TABLE os_peca (
    idOS            INT           NOT NULL,
    idPeca          INT           NOT NULL,
    quantidade      INT           NOT NULL DEFAULT 1,
    valorUnitario   DECIMAL(10,2) NOT NULL COMMENT 'Valor no momento da OS',
    PRIMARY KEY (idOS, idPeca),
    CONSTRAINT fk_osp_os   FOREIGN KEY (idOS)   REFERENCES ordemServico(idOS) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_osp_peca FOREIGN KEY (idPeca) REFERENCES peca(idPeca) ON UPDATE CASCADE
);

-- Mecânico × OS (mecânicos alocados em uma OS)
CREATE TABLE mecanico_os (
    idMecanico  INT NOT NULL,
    idOS        INT NOT NULL,
    funcao      VARCHAR(80) COMMENT 'Função exercida nesta OS',
    horasTrab   DECIMAL(5,2) DEFAULT 0,
    PRIMARY KEY (idMecanico, idOS),
    CONSTRAINT fk_mos_mec FOREIGN KEY (idMecanico) REFERENCES mecanico(idMecanico) ON UPDATE CASCADE,
    CONSTRAINT fk_mos_os  FOREIGN KEY (idOS)       REFERENCES ordemServico(idOS)   ON UPDATE CASCADE ON DELETE CASCADE
);

-- ============================================================
-- BLOCO 4 — INSERÇÃO DE DADOS (persistência para testes)
-- ============================================================

-- Clientes PF
INSERT INTO cliente (tipoCliente, telefone, email, endereco) VALUES
    ('PF','11987654321','ana.silva@email.com',     'Rua das Acácias 10, São Paulo - SP'),
    ('PF','11976543210','carlos.souza@email.com',  'Av. Brasil 500, São Paulo - SP'),
    ('PF','21965432109','fernanda.lima@email.com', 'Rua do Ouro 22, Rio de Janeiro - RJ'),
    ('PF','21954321098','roberto.melo@email.com',  'Rua das Palmeiras 77, Rio de Janeiro - RJ'),
    ('PF','31943210987','patricia.gomes@email.com','Av. Contorno 300, Belo Horizonte - MG');

INSERT INTO cliente_pf (idCliente, nome, cpf, dataNasc) VALUES
    (1,'Ana Clara Silva',   '12345678901','1990-03-15'),
    (2,'Carlos Eduardo Souza','98765432100','1985-07-22'),
    (3,'Fernanda Lima',     '45678912300','1992-11-08'),
    (4,'Roberto Melo',      '78912345600','1978-01-30'),
    (5,'Patrícia Gomes',    '32165498700','1995-06-19');

-- Clientes PJ
INSERT INTO cliente (tipoCliente, telefone, email, endereco) VALUES
    ('PJ','11933221100','contato@frotaexpress.com.br','Rodovia Anhanguera km 25, Campinas - SP'),
    ('PJ','11922110099','frota@logisticasp.com.br',   'Av. Industrial 800, São Paulo - SP');

INSERT INTO cliente_pj (idCliente, razaoSocial, cnpj, nomeFantasia) VALUES
    (6,'Frota Express Transportes LTDA','12345678000195','Frota Express'),
    (7,'Logística SP Comércio SA',      '98765432000188','LogSP');

-- Veículos
INSERT INTO veiculo (idCliente, placa, marca, modelo, ano, cor, quilometragem) VALUES
    (1,'ABC1D23','Volkswagen','Gol',          2018,'Branco',  82000),
    (1,'DEF2E45','Honda',     'HR-V',         2021,'Prata',   31000),
    (2,'GHI3F67','Toyota',    'Corolla',      2019,'Preto',  110000),
    (3,'JKL4G89','Chevrolet', 'Onix',         2020,'Vermelho',57000),
    (4,'MNO5H01','Ford',      'EcoSport',     2017,'Cinza',  143000),
    (5,'PQR6I23','Hyundai',   'HB20',         2022,'Azul',    18000),
    (6,'STU7J45','Mercedes',  'Sprinter',     2019,'Branco',  98000),
    (6,'VWX8K67','Volkswagen','Delivery 9.170',2020,'Branco', 75000),
    (7,'YZA9L89','Fiat',      'Ducato',       2018,'Branco', 120000);

-- Equipes
INSERT INTO equipe (nomeEquipe, especialidade) VALUES
    ('Equipe Alpha','Motor e Transmissão'),
    ('Equipe Beta', 'Elétrica e Eletrônica'),
    ('Equipe Gamma','Funilaria e Pintura'),
    ('Equipe Delta','Revisão Geral e Preventiva');

-- Mecânicos
INSERT INTO mecanico (idEquipe, nome, cpf, endereco, especialidade) VALUES
    (1,'João Pedro Alves',   '11122233344','Rua A 10, SP','Motor'),
    (1,'Lucas Fernandes',    '22233344455','Rua B 20, SP','Transmissão'),
    (2,'Marcos Oliveira',    '33344455566','Rua C 30, SP','Elétrica'),
    (2,'Rafael Costa',       '44455566677','Rua D 40, SP','Injeção Eletrônica'),
    (3,'Bruno Mendes',       '55566677788','Rua E 50, SP','Funilaria'),
    (3,'Diego Santos',       '66677788899','Rua F 60, RJ','Pintura'),
    (4,'André Martins',      '77788899900','Rua G 70, MG','Revisão Geral'),
    (4,'Felipe Rocha',       '88899900011','Rua H 80, SP','Freios e Suspensão'),
    (NULL,'Thiago Carvalho', '99900011122','Rua I 90, SP','Ar Condicionado');

-- Catálogo de serviços
INSERT INTO servico (descricao, categoria, valorMaoObra, tempoPrevisto) VALUES
    ('Troca de óleo e filtro',                'Revisão',       80.00,  60),
    ('Alinhamento e balanceamento',           'Revisão',      120.00,  90),
    ('Revisão completa 40.000 km',            'Revisão',      350.00, 240),
    ('Diagnóstico eletrônico',                'Diagnóstico',   90.00,  60),
    ('Reparo no sistema elétrico',            'Elétrica',     200.00, 180),
    ('Troca de pastilhas de freio',           'Freios',       150.00, 120),
    ('Revisão do sistema de suspensão',       'Suspensão',    180.00, 150),
    ('Reparo de motor',                       'Motor',        800.00, 480),
    ('Pintura parcial (painel)',              'Funilaria',    500.00, 360),
    ('Serviço de ar condicionado',            'Ar Condicionado',250.00,150),
    ('Troca de correia dentada',              'Motor',        220.00, 180),
    ('Substituição de amortecedor (par)',     'Suspensão',    280.00, 210),
    ('Higienização de ar condicionado',       'Ar Condicionado',120.00, 90),
    ('Reparo de funilaria (amassado)',        'Funilaria',    350.00, 300),
    ('Troca de bateria',                      'Elétrica',      80.00,  30);

-- Catálogo de peças
INSERT INTO peca (nome, descricao, valorUnitario, quantEstoque, fabricante) VALUES
    ('Filtro de óleo',          'Filtro motor 1.0/1.4',         25.00, 150,'Bosch'),
    ('Óleo motor 5W30 1L',      'Óleo sintético 1 litro',       32.00, 200,'Mobil'),
    ('Pastilha de freio diant.','Kit 4 pastilhas dianteiras',   120.00,  80,'Fras-Le'),
    ('Correia dentada',         'Kit correia + tensor',         180.00,  40,'Gates'),
    ('Amortecedor dianteiro',   'Amortecedor a gás (unid.)',    220.00,  30,'Monroe'),
    ('Bateria 60Ah',            'Bateria selada 12V 60Ah',      380.00,  25,'Moura'),
    ('Vela de ignição',         'Vela iridium (unid.)',          45.00, 100,'NGK'),
    ('Filtro de ar',            'Filtro de ar motor',            35.00, 120,'Tecfil'),
    ('Filtro de combustível',   'Filtro combustível',            40.00,  90,'Bosch'),
    ('Fluido de freio DOT4',    'Fluido freio 500ml',            28.00,  60,'Texaco'),
    ('Fluido de arrefecimento', 'Aditivo radiador 1L',           22.00,  80,'Prestone'),
    ('Correia alternador',      'Correia poly-v',                55.00,  50,'Gates'),
    ('Rolamento roda diant.',   'Rolamento cubo dianteiro',     145.00,  35,'FAG'),
    ('Cabo de vela (jogo)',     'Jogo 4 cabos vela',             95.00,  45,'Bosch'),
    ('Gás refrigerante R134a',  'Gás ar condicionado 250g',      85.00,  40,'Chemours');

-- Ordens de Serviço
INSERT INTO ordemServico (idVeiculo, idEquipe, numeroOS, dataConclusao, dataPrevista, status, autorizado, observacoes) VALUES
    (1, 4,'OS-2024-0001','2024-01-12 17:00:00','2024-01-12','Entregue',    TRUE, 'Revisão de rotina'),
    (3, 1,'OS-2024-0002','2024-01-18 16:30:00','2024-01-18','Entregue',    TRUE, 'Ruído no motor reportado pelo cliente'),
    (5, 2,'OS-2024-0003', NULL,                '2024-02-01','Em andamento',TRUE, 'Falha elétrica intermitente'),
    (4, 4,'OS-2024-0004','2024-01-25 15:00:00','2024-01-25','Entregue',    TRUE, 'Revisão dos 60k km'),
    (7, 1,'OS-2024-0005', NULL,                '2024-02-10','Aguardando peças',TRUE,'Aguardando correia Gates'),
    (2, 4,'OS-2024-0006','2024-02-05 11:00:00','2024-02-05','Entregue',    TRUE, 'Barulho na suspensão traseira'),
    (6, 3,'OS-2024-0007', NULL,                '2024-02-20','Em andamento',TRUE, 'Amassado lateral direita'),
    (8, 2,'OS-2024-0008','2024-02-08 14:00:00','2024-02-08','Entregue',    TRUE, 'Revisão elétrica + diagnóstico'),
    (9, 4,'OS-2024-0009', NULL,                '2024-03-01','Aguardando avaliação',FALSE,'Aguardando autorização do cliente'),
    (5, 2,'OS-2024-0010','2024-02-15 16:00:00','2024-02-15','Entregue',    TRUE, 'Complemento da OS-2024-0003');

-- Serviços por OS
INSERT INTO os_servico (idOS, idServico, quantidade, valorCobrado, statusServico) VALUES
    -- OS 1: Revisão Gol (troca óleo + alinhamento)
    (1, 1, 1,  80.00,'Concluído'),
    (1, 2, 1, 120.00,'Concluído'),
    -- OS 2: Corolla (reparo motor + diagnóstico)
    (2, 4, 1,  90.00,'Concluído'),
    (2, 8, 1, 800.00,'Concluído'),
    -- OS 3: EcoSport elétrica (em andamento)
    (3, 4, 1,  90.00,'Em execução'),
    (3, 5, 1, 200.00,'Pendente'),
    -- OS 4: Onix revisão
    (4, 3, 1, 350.00,'Concluído'),
    (4, 6, 1, 150.00,'Concluído'),
    -- OS 5: Sprinter correia
    (5,11, 1, 220.00,'Pendente'),
    -- OS 6: HR-V suspensão
    (6, 7, 1, 180.00,'Concluído'),
    (6,12, 1, 280.00,'Concluído'),
    -- OS 7: Ducato funilaria
    (7,14, 1, 350.00,'Em execução'),
    (7, 9, 1, 500.00,'Pendente'),
    -- OS 8: VW Delivery elétrica
    (8, 4, 1,  90.00,'Concluído'),
    (8, 5, 1, 200.00,'Concluído'),
    (8,15, 1,  80.00,'Concluído'),
    -- OS 9: Ducato (aguardando autorização)
    (9, 3, 1, 350.00,'Pendente'),
    -- OS 10: EcoSport complemento
    (10, 5, 1, 200.00,'Concluído'),
    (10,15, 1,  80.00,'Concluído');

-- Peças por OS
INSERT INTO os_peca (idOS, idPeca, quantidade, valorUnitario) VALUES
    -- OS 1
    (1,  1, 1,  25.00),
    (1,  2, 4,  32.00),
    -- OS 2
    (2,  7, 4,  45.00),
    (2,  4, 1, 180.00),
    -- OS 4
    (4,  1, 1,  25.00),
    (4,  2, 4,  32.00),
    (4,  8, 1,  35.00),
    (4,  9, 1,  40.00),
    (4,  3, 1, 120.00),
    -- OS 5
    (5,  4, 1, 180.00),
    -- OS 6
    (6,  5, 2, 220.00),
    (6, 13, 1, 145.00),
    -- OS 7
    (7, 10, 1,  28.00),
    -- OS 8
    (8,  6, 1, 380.00),
    (8, 14, 1,  95.00),
    -- OS 10
    (10,11, 1,  22.00);

-- Mecânicos por OS
INSERT INTO mecanico_os (idMecanico, idOS, funcao, horasTrab) VALUES
    (7, 1,'Revisão geral',        1.5),
    (8, 1,'Alinhamento',          1.0),
    (1, 2,'Reparo motor',         8.0),
    (2, 2,'Apoio transmissão',    4.0),
    (3, 3,'Diagnóstico elétrico', 2.0),
    (4, 3,'Reparo elétrico',      3.0),
    (7, 4,'Revisão completa',     4.0),
    (8, 4,'Freios',               2.0),
    (1, 5,'Troca correia',        3.0),
    (7, 6,'Suspensão',            3.5),
    (8, 6,'Amortecedor',          3.5),
    (5, 7,'Funilaria',            6.0),
    (6, 7,'Pintura',              6.0),
    (3, 8,'Diagnóstico',          1.5),
    (4, 8,'Elétrica',             3.0),
    (3,10,'Reparo elétrico',      3.5),
    (9,10,'Ar condicionado',      2.0);

-- ============================================================
-- BLOCO 5 — QUERIES ANALÍTICAS
-- ============================================================

-- -----------------------------------------------------------
-- Q1 — Recuperação simples: listagem completa de veículos com dados do dono
-- Pergunta: Quais veículos estão cadastrados e quem são seus proprietários?
-- -----------------------------------------------------------
SELECT
    v.placa,
    v.marca,
    v.modelo,
    v.ano,
    v.cor,
    v.quilometragem,
    CASE
        WHEN c.tipoCliente = 'PF' THEN pf.nome
        ELSE pj.razaoSocial
    END AS Proprietario,
    c.tipoCliente AS Tipo,
    c.telefone
FROM veiculo v
INNER JOIN cliente    c  ON v.idCliente = c.idCliente
LEFT  JOIN cliente_pf pf ON c.idCliente = pf.idCliente
LEFT  JOIN cliente_pj pj ON c.idCliente = pj.idCliente
ORDER BY v.marca, v.modelo;

-- -----------------------------------------------------------
-- Q2 — Filtro WHERE: OS abertas (não concluídas nem canceladas)
-- Pergunta: Quais ordens de serviço estão ainda em aberto?
-- -----------------------------------------------------------
SELECT
    os.numeroOS,
    os.dataEmissao,
    os.dataPrevista,
    os.status,
    v.placa,
    CONCAT(v.marca,' ',v.modelo,' (',v.ano,')') AS Veiculo,
    e.nomeEquipe                                AS Equipe,
    os.observacoes
FROM ordemServico os
INNER JOIN veiculo v ON os.idVeiculo = v.idVeiculo
LEFT  JOIN equipe  e ON os.idEquipe  = e.idEquipe
WHERE os.status NOT IN ('Entregue','Cancelada')
ORDER BY os.dataPrevista;

-- -----------------------------------------------------------
-- Q3 — Atributos derivados: valor total de cada OS (mão de obra + peças)
-- Pergunta: Qual o valor total de cada ordem de serviço?
-- -----------------------------------------------------------
SELECT
    os.numeroOS,
    os.status,
    CONCAT(v.marca,' ',v.modelo)                        AS Veiculo,
    v.placa,
    COALESCE(SUM(DISTINCT oss.valorCobrado * oss.quantidade), 0) AS TotalMaoObra,
    COALESCE(SUM(DISTINCT osp.valorUnitario * osp.quantidade), 0) AS TotalPecas,
    COALESCE(SUM(DISTINCT oss.valorCobrado * oss.quantidade), 0)
        + COALESCE(SUM(DISTINCT osp.valorUnitario * osp.quantidade), 0) AS ValorTotalOS,
    DATEDIFF(COALESCE(os.dataConclusao, NOW()), os.dataEmissao) AS DiasAberto
FROM ordemServico os
INNER JOIN veiculo     v   ON os.idVeiculo = v.idVeiculo
LEFT  JOIN os_servico  oss ON os.idOS = oss.idOS
LEFT  JOIN os_peca     osp ON os.idOS = osp.idOS
GROUP BY os.idOS
ORDER BY ValorTotalOS DESC;

-- -----------------------------------------------------------
-- Q4 — ORDER BY: mecânicos ordenados por horas trabalhadas (produtividade)
-- Pergunta: Quais mecânicos trabalharam mais horas no período?
-- -----------------------------------------------------------
SELECT
    m.nome                    AS Mecanico,
    m.especialidade,
    e.nomeEquipe              AS Equipe,
    COUNT(DISTINCT mo.idOS)   AS TotalOS,
    SUM(mo.horasTrab)         AS TotalHoras,
    ROUND(SUM(mo.horasTrab) / COUNT(DISTINCT mo.idOS), 2) AS MediaHorasPorOS
FROM mecanico m
LEFT JOIN equipe     e  ON m.idEquipe  = e.idEquipe
LEFT JOIN mecanico_os mo ON m.idMecanico = mo.idMecanico
GROUP BY m.idMecanico
ORDER BY TotalHoras DESC, TotalOS DESC;

-- -----------------------------------------------------------
-- Q5 — HAVING: clientes com mais de 1 OS registrada
-- Pergunta: Quais clientes são recorrentes (mais de uma OS)?
-- -----------------------------------------------------------
SELECT
    CASE
        WHEN c.tipoCliente = 'PF' THEN pf.nome
        ELSE pj.razaoSocial
    END               AS Cliente,
    c.tipoCliente     AS Tipo,
    c.telefone,
    COUNT(os.idOS)    AS TotalOS,
    MIN(os.dataEmissao) AS PrimeiraOS,
    MAX(os.dataEmissao) AS UltimaOS,
    DATEDIFF(MAX(os.dataEmissao), MIN(os.dataEmissao)) AS DiasComoCliente
FROM cliente c
LEFT  JOIN cliente_pf pf ON c.idCliente = pf.idCliente
LEFT  JOIN cliente_pj pj ON c.idCliente = pj.idCliente
INNER JOIN veiculo    v  ON c.idCliente = v.idCliente
INNER JOIN ordemServico os ON v.idVeiculo = os.idVeiculo
GROUP BY c.idCliente
HAVING TotalOS > 1
ORDER BY TotalOS DESC;

-- -----------------------------------------------------------
-- Q6 — JOIN complexo: visão completa da OS com serviços, peças e equipe
-- Pergunta: Qual o detalhamento completo de cada OS?
-- -----------------------------------------------------------
SELECT
    os.numeroOS,
    os.status,
    os.dataEmissao,
    os.dataPrevista,
    CONCAT(v.marca,' ',v.modelo,' – ',v.placa)  AS Veiculo,
    CASE
        WHEN c.tipoCliente = 'PF' THEN pf.nome
        ELSE pj.razaoSocial
    END                                          AS Cliente,
    e.nomeEquipe                                 AS Equipe,
    GROUP_CONCAT(DISTINCT s.descricao SEPARATOR ' | ') AS Servicos,
    GROUP_CONCAT(DISTINCT p.nome      SEPARATOR ' | ') AS Pecas,
    COUNT(DISTINCT oss.idServico)                AS QtdServicos,
    COUNT(DISTINCT osp.idPeca)                   AS QtdPecas,
    COUNT(DISTINCT mo.idMecanico)                AS QtdMecanicos
FROM ordemServico os
INNER JOIN veiculo     v   ON os.idVeiculo = v.idVeiculo
INNER JOIN cliente     c   ON v.idCliente  = c.idCliente
LEFT  JOIN cliente_pf  pf  ON c.idCliente  = pf.idCliente
LEFT  JOIN cliente_pj  pj  ON c.idCliente  = pj.idCliente
LEFT  JOIN equipe      e   ON os.idEquipe  = e.idEquipe
LEFT  JOIN os_servico  oss ON os.idOS      = oss.idOS
LEFT  JOIN servico     s   ON oss.idServico = s.idServico
LEFT  JOIN os_peca     osp ON os.idOS      = osp.idOS
LEFT  JOIN peca        p   ON osp.idPeca   = p.idPeca
LEFT  JOIN mecanico_os mo  ON os.idOS      = mo.idOS
GROUP BY os.idOS
ORDER BY os.dataEmissao DESC;

-- -----------------------------------------------------------
-- Q7 — Receita por equipe com HAVING: equipes acima de R$500 em OS entregues
-- Pergunta: Quais equipes geraram mais receita em serviços entregues?
-- -----------------------------------------------------------
SELECT
    e.nomeEquipe,
    e.especialidade,
    COUNT(DISTINCT os.idOS)                       AS TotalOS,
    SUM(oss.valorCobrado * oss.quantidade)        AS ReceitaMaoObra,
    SUM(osp.valorUnitario * osp.quantidade)       AS ReceitaPecas,
    SUM(oss.valorCobrado * oss.quantidade)
        + SUM(osp.valorUnitario * osp.quantidade) AS ReceitaTotal
FROM equipe e
INNER JOIN ordemServico os  ON e.idEquipe   = os.idEquipe
INNER JOIN os_servico   oss ON os.idOS      = oss.idOS
LEFT  JOIN os_peca      osp ON os.idOS      = osp.idOS
WHERE os.status IN ('Entregue','Concluída')
GROUP BY e.idEquipe
HAVING ReceitaTotal > 500
ORDER BY ReceitaTotal DESC;

-- -----------------------------------------------------------
-- Q8 — Filtro + derivado: veículos com alta quilometragem e suas OS
-- Pergunta: Veículos com mais de 80.000 km já passaram por quantas OS?
-- -----------------------------------------------------------
SELECT
    v.placa,
    CONCAT(v.marca,' ',v.modelo,' ',v.ano)   AS Veiculo,
    v.quilometragem,
    CASE
        WHEN v.quilometragem < 50000  THEN 'Baixo uso'
        WHEN v.quilometragem < 100000 THEN 'Uso moderado'
        WHEN v.quilometragem < 150000 THEN 'Alto uso'
        ELSE 'Uso intenso'
    END                                      AS ClassificacaoUso,
    COUNT(os.idOS)                           AS TotalOS,
    MAX(os.dataEmissao)                      AS UltimaVisita,
    DATEDIFF(CURDATE(), MAX(os.dataEmissao)) AS DiasDesdeUltimaVisita
FROM veiculo v
LEFT JOIN ordemServico os ON v.idVeiculo = os.idVeiculo
WHERE v.quilometragem > 80000
GROUP BY v.idVeiculo
ORDER BY v.quilometragem DESC;

-- -----------------------------------------------------------
-- Q9 — Peças mais utilizadas nas OS
-- Pergunta: Quais peças são mais consumidas e geram mais receita?
-- -----------------------------------------------------------
SELECT
    p.nome                                    AS Peca,
    p.fabricante,
    p.quantEstoque                            AS EstoqueAtual,
    COUNT(osp.idOS)                           AS VezesUsada,
    SUM(osp.quantidade)                       AS TotalUnidsUsadas,
    SUM(osp.quantidade * osp.valorUnitario)   AS ReceitaGerada,
    AVG(osp.valorUnitario)                    AS PrecoMedioVendido,
    CASE
        WHEN p.quantEstoque < 10 THEN 'REPOR URGENTE'
        WHEN p.quantEstoque < 30 THEN 'Estoque baixo'
        ELSE 'Estoque OK'
    END                                       AS AlertaEstoque
FROM peca p
LEFT JOIN os_peca osp ON p.idPeca = osp.idPeca
GROUP BY p.idPeca
ORDER BY TotalUnidsUsadas DESC, ReceitaGerada DESC;

-- -----------------------------------------------------------
-- Q10 — Serviços mais solicitados por categoria
-- Pergunta: Quais as categorias de serviço mais demandadas na oficina?
-- -----------------------------------------------------------
SELECT
    s.categoria,
    COUNT(oss.idOS)                            AS VezesSolicitado,
    SUM(oss.valorCobrado * oss.quantidade)     AS ReceitaTotal,
    AVG(oss.valorCobrado)                      AS TicketMedio,
    MAX(oss.valorCobrado)                      AS MaiorValor,
    MIN(oss.valorCobrado)                      AS MenorValor,
    ROUND(COUNT(oss.idOS) * 100.0 /
        (SELECT COUNT(*) FROM os_servico), 2)  AS PercentualDemanda
FROM servico s
INNER JOIN os_servico oss ON s.idServico = oss.idServico
GROUP BY s.categoria
ORDER BY VezesSolicitado DESC;

-- -----------------------------------------------------------
-- Q11 — OS aguardando autorização ou peças (gargalos operacionais)
-- Pergunta: Quais OS estão paradas e por quê?
-- -----------------------------------------------------------
SELECT
    os.numeroOS,
    os.status                                     AS Situacao,
    CONCAT(v.marca,' ',v.modelo,' – ',v.placa)    AS Veiculo,
    CASE
        WHEN c.tipoCliente = 'PF' THEN pf.nome
        ELSE pj.razaoSocial
    END                                           AS Cliente,
    c.telefone,
    os.dataEmissao,
    DATEDIFF(CURDATE(), os.dataEmissao)           AS DiasParada,
    os.observacoes
FROM ordemServico os
INNER JOIN veiculo    v  ON os.idVeiculo = v.idVeiculo
INNER JOIN cliente    c  ON v.idCliente  = c.idCliente
LEFT  JOIN cliente_pf pf ON c.idCliente  = pf.idCliente
LEFT  JOIN cliente_pj pj ON c.idCliente  = pj.idCliente
WHERE os.status IN ('Aguardando avaliação','Aguardando peças')
   OR os.autorizado = FALSE
ORDER BY DiasParada DESC;

-- -----------------------------------------------------------
-- Q12 — Ranking de clientes por valor total gasto
-- Pergunta: Quais clientes geraram mais receita para a oficina?
-- -----------------------------------------------------------
SELECT
    CASE
        WHEN c.tipoCliente = 'PF' THEN pf.nome
        ELSE pj.razaoSocial
    END                                             AS Cliente,
    c.tipoCliente,
    COUNT(DISTINCT os.idOS)                         AS TotalOS,
    COUNT(DISTINCT v.idVeiculo)                     AS TotalVeiculos,
    SUM(oss.valorCobrado * oss.quantidade)          AS GastoMaoObra,
    SUM(osp.valorUnitario * osp.quantidade)         AS GastoPecas,
    SUM(oss.valorCobrado * oss.quantidade)
        + SUM(osp.valorUnitario * osp.quantidade)   AS GastoTotal,
    RANK() OVER (ORDER BY
        SUM(oss.valorCobrado * oss.quantidade)
        + SUM(osp.valorUnitario * osp.quantidade) DESC) AS Ranking
FROM cliente c
LEFT  JOIN cliente_pf  pf  ON c.idCliente  = pf.idCliente
LEFT  JOIN cliente_pj  pj  ON c.idCliente  = pj.idCliente
INNER JOIN veiculo     v   ON c.idCliente  = v.idCliente
INNER JOIN ordemServico os  ON v.idVeiculo = os.idVeiculo
INNER JOIN os_servico  oss ON os.idOS      = oss.idOS
LEFT  JOIN os_peca     osp ON os.idOS      = osp.idOS
GROUP BY c.idCliente
ORDER BY GastoTotal DESC;
