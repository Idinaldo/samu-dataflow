-- ==========================================================================
-- Mock SAMU Recife 2026 -- schema catalogado (oracle)
-- Gerado por gerar_schema.py. Metadados medidos sobre 61.846 ocorrencias
-- reais de 2026 (jan-out), nao estimados.
--
-- Os dados de exemplo sao FICTICIOS. Estrutura, vocabularios e taxas de
-- preenchimento reproduzem a view CIEVS.HXGN_VW_DETALHE_OCO_SEC_SAUDE;
-- nenhum nome, telefone, endereco ou texto clinico real foi copiado.
-- ==========================================================================

WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION SET CONTAINER=FREEPDB1;
ALTER SESSION SET CURRENT_SCHEMA=SYSTEM;

-- --------------------------------------------------------------------------
-- CAMADA BRONZE: fiel a fonte. Onde a origem entrega texto, aqui e texto,
-- inclusive IDADE ('26 Anos'), PRESSÃO ('120X80') e FINALIZAÇÃO empacotada.
-- Nomes de coluna preservados como na view, por isso vem entre aspas.
-- --------------------------------------------------------------------------

DROP VIEW  IF EXISTS samu_ocorrencia_silver;
DROP TABLE IF EXISTS samu_ocorrencia_bronze CASCADE CONSTRAINTS;
DROP TABLE IF EXISTS samu_catalogo_colunas CASCADE CONSTRAINTS;

create table samu_ocorrencia_bronze (
  "OCORRÊNCIA"                   varchar2(20 char)      not null,
  "DATA/HORA CRIAÇÃO"            date                   not null,
  "PACIENTE"                     varchar2(120 char)    ,
  "IDADE"                        varchar2(40 char)     ,
  "SEXO"                         varchar2(20 char)     ,
  "SOLICITANTE"                  varchar2(120 char)    ,
  "TELEFONE"                     varchar2(40 char)     ,
  "ENDEREÇO"                     varchar2(250 char)    ,
  "ORIGEM DA CHAMADA"            varchar2(40 char)     ,
  "BAIRRO"                       varchar2(80 char)     ,
  "MUNICÍPIO"                    varchar2(80 char)     ,
  "PONTO DE REFERÊNCIA"          varchar2(250 char)    ,
  "DATA/HORA REGULAÇÃO"          date                  ,
  "CÓD./DESCRIÇÃO TIPO"          varchar2(80 char)     ,
  "CÓD./DESCRIÇÃO SUBTIPO"       varchar2(120 char)    ,
  "CLASSIFICAÇÃO DE RISCO"       varchar2(20 char)     ,
  "QUEIXA"                       varchar2(1000 char)   ,
  "RECOMENDAÇÕES"                varchar2(1000 char)   ,
  "DESPACHO"                     date                  ,
  "FINALIZAÇÃO"                  varchar2(200 char)    ,
  "DATA/HORA QUADRO CLÍNICO"     date                  ,
  "PRESSÃO"                      varchar2(20 char)     ,
  "PULSO"                        varchar2(20 char)     ,
  "TEMPERATURA"                  varchar2(20 char)     ,
  "F.RESP."                      varchar2(20 char)     ,
  "HGT"                          varchar2(20 char)     ,
  "SPO"                          varchar2(20 char)     ,
  "GLASGOW"                      varchar2(20 char)     ,
  "OBSERVAÇÕES"                  varchar2(2000 char)   ,
  "DATA/HORA AÇÃO MÉDICA"        date                  ,
  "AÇÃO"                         varchar2(200 char)    ,
  "DATA/HORA HOSPITAL DESTINO"   date                  ,
  "MÉDICO"                       varchar2(120 char)    ,
  "HOSPITAL"                     varchar2(150 char)    ,
  "MOTIVO DE RECUSA"             varchar2(200 char)    ,
  "REGIÃO"                       varchar2(80 char)     ,
  constraint pk_samu_ocorrencia_bronze primary key ("OCORRÊNCIA"),
  constraint ck_hospital_regiao check (("HOSPITAL" is null) = ("REGIÃO" is null)),
  constraint ck_acao_par check (("AÇÃO" is null) = ("DATA/HORA AÇÃO MÉDICA" is null)),
  constraint ck_obs_exige_quadro check ("OBSERVAÇÕES" is null or "DATA/HORA QUADRO CLÍNICO" is not null),
  constraint ck_recusa_exige_hosp check ("MOTIVO DE RECUSA" is null or "HOSPITAL" is not null),
  constraint ck_marcos_ordem check ("DATA/HORA REGULAÇÃO" is null or "DATA/HORA REGULAÇÃO" >= "DATA/HORA CRIAÇÃO")
);

-- faixas fisiologicas: o real guarda texto, logo estas checagens valem
-- para a camada silver; aqui ficam como documentacao do dominio esperado.
--   pressao sistolica 50-300 mmHg   diastolica 20-200 mmHg
--   pulso 20-250 bpm   temperatura 30-43 C   f.resp. 4-80 irpm
--   glicemia 10-600 mg/dL   saturacao 40-100 %   glasgow 3-15

comment on table samu_ocorrencia_bronze is 'Ocorrencias do SAMU Recife, camada bronze fiel a view de origem. Dados de exemplo ficticios.';
comment on column samu_ocorrencia_bronze."OCORRÊNCIA" is '[LGPD: operacional] Identificador da ocorrencia no CAD (ex. S2042832). NAO e unico na view de origem: os left joins produzem fan-out de ~1,14 linha por ocorrencia. [preenchimento real 100.0%; 61.846 valores distintos]';
comment on column samu_ocorrencia_bronze."DATA/HORA CRIAÇÃO" is '[LGPD: operacional] Abertura do chamado pelo TARM. Marco 1 da cascata, preenchido em 100% dos casos. [preenchimento real 100.0%; 61.760 valores distintos]';
comment on column samu_ocorrencia_bronze."PACIENTE" is '[LGPD: identificador_direto] Nome do paciente. Identificador direto; removido da exportacao 2026 por LGPD.';
comment on column samu_ocorrencia_bronze."IDADE" is '[LGPD: identificador_indireto] TEXTO LIVRE, nao numero: ''26 Anos'', ''Nao Informado'', ''1 Ano 3 Meses''. Parseado para numerico na camada silver. [preenchimento real 100.0%; 189 valores distintos]';
comment on column samu_ocorrencia_bronze."SEXO" is '[LGPD: identificador_indireto] MASCULINO, FEMININO ou NAOINFORMADO. [preenchimento real 100.0%; 3 valores distintos]';
comment on column samu_ocorrencia_bronze."SOLICITANTE" is '[LGPD: identificador_direto] Nome de quem acionou o servico, em geral terceiro. Identificador direto. [preenchimento real 100.0%; 15.201 valores distintos]';
comment on column samu_ocorrencia_bronze."TELEFONE" is '[LGPD: identificador_direto] Telefone de contato. Identificador direto; removido da exportacao 2026 por LGPD.';
comment on column samu_ocorrencia_bronze."ENDEREÇO" is '[LGPD: identificador_direto] Endereco da ocorrencia. Identificador direto; mantido na exportacao 2026 por decisao do responsavel pelos dados. [preenchimento real 99.8%; 49.640 valores distintos]';
comment on column samu_ocorrencia_bronze."ORIGEM DA CHAMADA" is '[LGPD: operacional] Tipo de local: RESIDENCIAL, VIA PUBLICA, ESTAB PR, UNIDADE DE SAUDE, ESTAB PU, ILPs. Contem ruido de digitacao (ex. ''EDILEUZA'', 1 caso). [preenchimento real 100.0%; 8 valores distintos]';
comment on column samu_ocorrencia_bronze."BAIRRO" is '[LGPD: identificador_indireto] Bairro da ocorrencia, 103 valores distintos. Quase-identificador quando cruzado com data e idade. [preenchimento real 100.0%; 103 valores distintos]';
comment on column samu_ocorrencia_bronze."MUNICÍPIO" is '[LGPD: operacional] Municipio da ocorrencia. Sempre RECIFE: a view tem filtro fixo b.municipio=''RECIFE''. [preenchimento real 100.0%; 1 valores distintos]';
comment on column samu_ocorrencia_bronze."PONTO DE REFERÊNCIA" is '[LGPD: identificador_indireto] Referencia textual de localizacao. Quase-identificador. [preenchimento real 99.9%; 57.330 valores distintos]';
comment on column samu_ocorrencia_bronze."DATA/HORA REGULAÇÃO" is '[LGPD: operacional] Momento em que o medico regulador assume o caso. Marco 2; mediana de 0,6 min apos a criacao. [preenchimento real 99.0%; 61.193 valores distintos]';
comment on column samu_ocorrencia_bronze."CÓD./DESCRIÇÃO TIPO" is '[LGPD: sensivel_saude] Codigo e descricao do agravo, colados por barra: ''EXTERNA/causas externas''. 20 valores, incluindo lixo operacional (''TESTE'', ''REG''). [preenchimento real 100.0%; 20 valores distintos]';
comment on column samu_ocorrencia_bronze."CÓD./DESCRIÇÃO SUBTIPO" is '[LGPD: sensivel_saude] Subtipo do agravo, 115 valores distintos, mesmo formato colado. [preenchimento real 100.0%; 115 valores distintos]';
comment on column samu_ocorrencia_bronze."CLASSIFICAÇÃO DE RISCO" is '[LGPD: sensivel_saude] Vermelho, Amarelo, Verde ou Azul. Segundo preditor mais forte da cascata de atendimento. [preenchimento real 98.1%; 4 valores distintos]';
comment on column samu_ocorrencia_bronze."QUEIXA" is '[LGPD: sensivel_saude] TEXTO LIVRE do TARM, telegrafico e com abreviacoes. Dado sensivel de saude: no mock e sintetico, nunca copiado do real. [preenchimento real 96.9%; 52.709 valores distintos]';
comment on column samu_ocorrencia_bronze."RECOMENDAÇÕES" is '[LGPD: sensivel_saude] Conduta do regulador. Dominante ''USB'', mas com 6.265 variantes de texto livre e caixa inconsistente (''USB''/''usb''). [preenchimento real 91.8%; 6.264 valores distintos]';
comment on column samu_ocorrencia_bronze."DESPACHO" is '[LGPD: operacional] Envio da viatura. Marco 3, preenchido em 62% das ocorrencias; vazio quando nenhuma unidade foi enviada. [preenchimento real 62.0%; 38.342 valores distintos]';
comment on column samu_ocorrencia_bronze."FINALIZAÇÃO" is '[LGPD: operacional] EMPACOTADO: ''dd/mm/yyyy hh:mi:ss / N. motivo'' em um unico campo. Desempacotado na camada silver. Preditor dominante de toda a cascata. [preenchimento real 100.0%; 61.800 valores distintos]';
comment on column samu_ocorrencia_bronze."DATA/HORA QUADRO CLÍNICO" is '[LGPD: operacional] Avaliacao clinica no local. Marco 4, 47% das ocorrencias. Porta de entrada dos sinais vitais. [preenchimento real 47.1%; 29.139 valores distintos]';
comment on column samu_ocorrencia_bronze."PRESSÃO" is '[LGPD: sensivel_saude] Pressao arterial como texto, ''sistolicaXdiastolica''. ATENCAO: 18,3% dos registros estao em cmHg (''12/8''), nao mmHg; separador varia entre X e barra. Normalizado na silver. [preenchimento real 27.3%; 1.208 valores distintos]';
comment on column samu_ocorrencia_bronze."PULSO" is '[LGPD: sensivel_saude] Frequencia cardiaca em bpm, como texto. [preenchimento real 24.6%; 224 valores distintos]';
comment on column samu_ocorrencia_bronze."TEMPERATURA" is '[LGPD: sensivel_saude] Temperatura em graus Celsius, com virgula decimal (''36,2''). Preenchida em apenas 6,3%. [preenchimento real 6.3%; 189 valores distintos]';
comment on column samu_ocorrencia_bronze."F.RESP." is '[LGPD: sensivel_saude] Frequencia respiratoria em irpm. Preenchida em apenas 8,9%. [preenchimento real 8.9%; 79 valores distintos]';
comment on column samu_ocorrencia_bronze."HGT" is '[LGPD: sensivel_saude] Glicemia capilar em mg/dL. [preenchimento real 24.0%; 581 valores distintos]';
comment on column samu_ocorrencia_bronze."SPO" is '[LGPD: sensivel_saude] Saturacao periferica de oxigenio em %. [preenchimento real 26.9%; 225 valores distintos]';
comment on column samu_ocorrencia_bronze."GLASGOW" is '[LGPD: sensivel_saude] Escala de coma de Glasgow, 3 a 15. Preenchida em 9,4% e com 90% dos valores iguais a 15. [preenchimento real 9.4%; 49 valores distintos]';
comment on column samu_ocorrencia_bronze."OBSERVAÇÕES" is '[LGPD: sensivel_saude] TEXTO LIVRE da equipe. Existe somente quando houve quadro clinico (100% na base real). Sintetico no mock. [preenchimento real 44.1%; 23.972 valores distintos]';
comment on column samu_ocorrencia_bronze."DATA/HORA AÇÃO MÉDICA" is '[LGPD: operacional] Procedimento executado. Preenchido em apenas 1,2%: na pratica inutilizavel para analise, possivel falha no join sgph_patient_action_taken. [preenchimento real 1.2%; 760 valores distintos]';
comment on column samu_ocorrencia_bronze."AÇÃO" is '[LGPD: sensivel_saude] Procedimento, vocabulario controlado (''Infusao venosa de SF 0,9%''). Par atomico com dt_acao_medica: 760 de 760 coincidem. [preenchimento real 1.2%; 18 valores distintos]';
comment on column samu_ocorrencia_bronze."DATA/HORA HOSPITAL DESTINO" is '[LGPD: operacional] Chegada ao destino. Marco 5, 35,5% das ocorrencias. [preenchimento real 36.1%; 22.331 valores distintos]';
comment on column samu_ocorrencia_bronze."MÉDICO" is '[LGPD: identificador_direto] Medico responsavel. Identificador direto. Vem como ''-'' quando ambas as partes do nome sao nulas. Existe quase so com hospital (98,3%). [preenchimento real 36.1%; 91 valores distintos]';
comment on column samu_ocorrencia_bronze."HOSPITAL" is '[LGPD: operacional] Unidade de destino, 133 valores distintos. Determina a coluna regiao. [preenchimento real 35.5%; 133 valores distintos]';
comment on column samu_ocorrencia_bronze."MOTIVO DE RECUSA" is '[LGPD: operacional] Motivo de recusa pela unidade receptora, vocabulario controlado. Existe somente com hospital (100%) e em apenas 0,52% das ocorrencias. [preenchimento real 0.5%; 5 valores distintos]';
comment on column samu_ocorrencia_bronze."REGIÃO" is '[LGPD: operacional] DERIVADA do hospital: e o municipio da unidade de destino, nao o da ocorrencia. Hospital e regiao divergem em apenas 0,6% dos casos, que sao erro de dado. [preenchimento real 36.1%; 36 valores distintos]';

-- --------------------------------------------------------------------------
-- CAMADA SILVER: o que a bronze guarda como texto, aqui vira tipo util.
-- Resolve os quatro problemas estruturais da fonte:
--   1. IDADE texto livre          -> idade_anos numerico
--   2. PRESSÃO em cmHg (18,3%)    -> pa_sistolica/pa_diastolica em mmHg
--   3. FINALIZAÇÃO empacotada     -> finalizacao_cod + dt_finalizacao
--   4. ausencia informativa       -> flags explicitas da cascata
-- --------------------------------------------------------------------------
create or replace view samu_ocorrencia_silver as
with base as (
  select b.*,
         to_number(regexp_substr("PRESSÃO", '[0-9]+')) as v_pa_s,
         to_number(regexp_substr("PRESSÃO", '[0-9]+$')) as v_pa_d
    from samu_ocorrencia_bronze b
)
select
  "OCORRÊNCIA"                       as ocorrencia,
  "DATA/HORA CRIAÇÃO"                as dt_criacao,
  "DATA/HORA REGULAÇÃO"              as dt_regulacao,
  "DESPACHO"                         as dt_despacho,
  "DATA/HORA QUADRO CLÍNICO"         as dt_quadro_clinico,
  "DATA/HORA AÇÃO MÉDICA"            as dt_acao_medica,
  "DATA/HORA HOSPITAL DESTINO"       as dt_hospital_destino,
  -- 1. idade: de texto livre para numero
  case when regexp_like("IDADE", '[0-9]+\s*(Ano|M[eê]s|Dia)') then round(coalesce(to_number(regexp_substr("IDADE", '([0-9]+)\s*Ano', 1, 1, null, 1)), 0) + coalesce(to_number(regexp_substr("IDADE", '([0-9]+)\s*M[eê]s', 1, 1, null, 1)), 0) / 12 + coalesce(to_number(regexp_substr("IDADE", '([0-9]+)\s*Dia', 1, 1, null, 1)), 0) / 365, 2) end as idade_anos,
  "IDADE"                            as idade_texto,
  -- 2. pressao: 18,3%% do real vem em cmHg ('12/8'); abaixo de 30 multiplica por 10
  case when v_pa_s < 30 then v_pa_s * 10 else v_pa_s end as pa_sistolica,
  case when v_pa_s < 30 then v_pa_d * 10 else v_pa_d end as pa_diastolica,
  to_number(regexp_substr("PULSO", '[0-9]+')) as pulso,
  to_number(regexp_substr("HGT", '[0-9]+')) as glicemia,
  to_number(regexp_substr("SPO", '[0-9]+')) as saturacao,
  to_number(regexp_substr("F.RESP.", '[0-9]+')) as freq_respiratoria,
  to_number(regexp_substr("GLASGOW", '[0-9]+')) as glasgow,
  to_number(replace("TEMPERATURA", ',', '.'), '9999D999', 'nls_numeric_characters=''.,''') as temperatura,
  -- 3. finalizacao: desempacota codigo e timestamp
  to_number(regexp_substr("FINALIZAÇÃO", '/\s*([0-9]+)\.', 1, 1, null, 1)) as finalizacao_cod,
  to_date(substr("FINALIZAÇÃO", 1, 19), 'dd/mm/yyyy hh24:mi:ss') as dt_finalizacao,
  -- 4. ausencia informativa: a cascata explicitada
  case when "DESPACHO" is not null then 1 else 0 end as fl_despachou,
  case when "DATA/HORA QUADRO CLÍNICO" is not null then 1 else 0 end as fl_avaliou,
  case when "HOSPITAL" is not null then 1 else 0 end as fl_transportou,
  -- intervalos de resposta, em minutos
  round(("DATA/HORA REGULAÇÃO" - "DATA/HORA CRIAÇÃO") * 24 * 60, 1) as min_ate_regulacao,
  round(("DESPACHO" - "DATA/HORA CRIAÇÃO") * 24 * 60, 1) as min_ate_despacho,
  round(("DATA/HORA QUADRO CLÍNICO" - "DESPACHO") * 24 * 60, 1) as min_ate_quadro,
  round(("DATA/HORA HOSPITAL DESTINO" - "DATA/HORA QUADRO CLÍNICO") * 24 * 60, 1) as min_ate_hospital,
  "SEXO"                             as sexo,
  "BAIRRO"                           as bairro,
  "ORIGEM DA CHAMADA"                as origem_chamada,
  "CLASSIFICAÇÃO DE RISCO"           as risco,
  "HOSPITAL"                         as hospital,
  "REGIÃO"                           as regiao_hospital,
  "AÇÃO"                             as acao,
  "MOTIVO DE RECUSA"                 as motivo_recusa,
  -- tipo e subtipo vem colados 'COD/descricao'; separa os dois
  substr("CÓD./DESCRIÇÃO TIPO", 1, instr("CÓD./DESCRIÇÃO TIPO", '/') - 1) as tipo_cod,
  substr("CÓD./DESCRIÇÃO SUBTIPO", 1, instr("CÓD./DESCRIÇÃO SUBTIPO", '/') - 1) as subtipo_cod
  from base;

-- --------------------------------------------------------------------------
-- CATALOGO: metadados consultaveis por SQL, como um data catalog.
-- taxa_preenchimento e cardinalidade vem da base real de 2026, nao do mock.
-- --------------------------------------------------------------------------
create table samu_catalogo_colunas (
  ordem                int          not null,
  coluna_bronze        varchar2(40 char) not null,
  coluna_silver        varchar2(40 char),
  tipo_logico          varchar2(20 char),
  obrigatorio          char(1),
  classificacao_lgpd   varchar2(30 char),
  taxa_preenchimento   numeric(5,2),
  valores_distintos    integer,
  tamanho_max          integer,
  descricao            varchar2(2000 char),
  constraint pk_samu_catalogo_colunas primary key (coluna_bronze)
);
comment on table samu_catalogo_colunas is 'Dicionario de dados. Taxas medidas sobre 61846 ocorrencias reais de 2026.';

insert into samu_catalogo_colunas values (1, 'OCORRÊNCIA', 'ocorrencia', 'codigo', 'S', 'operacional', 100.00, 61846, 8, 'Identificador da ocorrencia no CAD (ex. S2042832). NAO e unico na view de origem: os left joins produzem fan-out de ~1,14 linha por ocorrencia.');
insert into samu_catalogo_colunas values (2, 'DATA/HORA CRIAÇÃO', 'dt_criacao', 'timestamp', 'S', 'operacional', 100.00, 61760, 19, 'Abertura do chamado pelo TARM. Marco 1 da cascata, preenchido em 100% dos casos.');
insert into samu_catalogo_colunas values (3, 'PACIENTE', 'paciente', 'texto', 'N', 'identificador_direto', null, null, null, 'Nome do paciente. Identificador direto; removido da exportacao 2026 por LGPD.');
insert into samu_catalogo_colunas values (4, 'IDADE', 'idade', 'texto', 'N', 'identificador_indireto', 100.00, 189, 16, 'TEXTO LIVRE, nao numero: ''26 Anos'', ''Nao Informado'', ''1 Ano 3 Meses''. Parseado para numerico na camada silver.');
insert into samu_catalogo_colunas values (5, 'SEXO', 'sexo', 'codigo', 'N', 'identificador_indireto', 100.00, 3, 12, 'MASCULINO, FEMININO ou NAOINFORMADO.');
insert into samu_catalogo_colunas values (6, 'SOLICITANTE', 'solicitante', 'texto', 'N', 'identificador_direto', 100.00, 15201, 46, 'Nome de quem acionou o servico, em geral terceiro. Identificador direto.');
insert into samu_catalogo_colunas values (7, 'TELEFONE', 'telefone', 'texto', 'N', 'identificador_direto', null, null, null, 'Telefone de contato. Identificador direto; removido da exportacao 2026 por LGPD.');
insert into samu_catalogo_colunas values (8, 'ENDEREÇO', 'endereco', 'texto', 'N', 'identificador_direto', 99.77, 49640, 70, 'Endereco da ocorrencia. Identificador direto; mantido na exportacao 2026 por decisao do responsavel pelos dados.');
insert into samu_catalogo_colunas values (9, 'ORIGEM DA CHAMADA', 'origem_chamada', 'codigo', 'N', 'operacional', 99.99, 8, 16, 'Tipo de local: RESIDENCIAL, VIA PUBLICA, ESTAB PR, UNIDADE DE SAUDE, ESTAB PU, ILPs. Contem ruido de digitacao (ex. ''EDILEUZA'', 1 caso).');
insert into samu_catalogo_colunas values (10, 'BAIRRO', 'bairro', 'codigo', 'N', 'identificador_indireto', 100.00, 103, 20, 'Bairro da ocorrencia, 103 valores distintos. Quase-identificador quando cruzado com data e idade.');
insert into samu_catalogo_colunas values (11, 'MUNICÍPIO', 'municipio', 'codigo', 'N', 'operacional', 100.00, 1, 6, 'Municipio da ocorrencia. Sempre RECIFE: a view tem filtro fixo b.municipio=''RECIFE''.');
insert into samu_catalogo_colunas values (12, 'PONTO DE REFERÊNCIA', 'ponto_referencia', 'texto', 'N', 'identificador_indireto', 99.93, 57330, 294, 'Referencia textual de localizacao. Quase-identificador.');
insert into samu_catalogo_colunas values (13, 'DATA/HORA REGULAÇÃO', 'dt_regulacao', 'timestamp', 'N', 'operacional', 99.03, 61193, 19, 'Momento em que o medico regulador assume o caso. Marco 2; mediana de 0,6 min apos a criacao.');
insert into samu_catalogo_colunas values (14, 'CÓD./DESCRIÇÃO TIPO', 'tipo', 'codigo', 'N', 'sensivel_saude', 100.00, 20, 33, 'Codigo e descricao do agravo, colados por barra: ''EXTERNA/causas externas''. 20 valores, incluindo lixo operacional (''TESTE'', ''REG'').');
insert into samu_catalogo_colunas values (15, 'CÓD./DESCRIÇÃO SUBTIPO', 'subtipo', 'codigo', 'N', 'sensivel_saude', 100.00, 115, 64, 'Subtipo do agravo, 115 valores distintos, mesmo formato colado.');
insert into samu_catalogo_colunas values (16, 'CLASSIFICAÇÃO DE RISCO', 'risco', 'codigo', 'N', 'sensivel_saude', 98.09, 4, 8, 'Vermelho, Amarelo, Verde ou Azul. Segundo preditor mais forte da cascata de atendimento.');
insert into samu_catalogo_colunas values (17, 'QUEIXA', 'queixa', 'texto', 'N', 'sensivel_saude', 96.88, 52709, 953, 'TEXTO LIVRE do TARM, telegrafico e com abreviacoes. Dado sensivel de saude: no mock e sintetico, nunca copiado do real.');
insert into samu_catalogo_colunas values (18, 'RECOMENDAÇÕES', 'recomendacoes', 'texto', 'N', 'sensivel_saude', 91.79, 6264, 445, 'Conduta do regulador. Dominante ''USB'', mas com 6.265 variantes de texto livre e caixa inconsistente (''USB''/''usb'').');
insert into samu_catalogo_colunas values (19, 'DESPACHO', 'dt_despacho', 'timestamp', 'N', 'operacional', 62.01, 38342, 19, 'Envio da viatura. Marco 3, preenchido em 62% das ocorrencias; vazio quando nenhuma unidade foi enviada.');
insert into samu_catalogo_colunas values (20, 'FINALIZAÇÃO', 'finalizacao', 'texto', 'N', 'operacional', 99.95, 61800, 82, 'EMPACOTADO: ''dd/mm/yyyy hh:mi:ss / N. motivo'' em um unico campo. Desempacotado na camada silver. Preditor dominante de toda a cascata.');
insert into samu_catalogo_colunas values (21, 'DATA/HORA QUADRO CLÍNICO', 'dt_quadro_clinico', 'timestamp', 'N', 'operacional', 47.13, 29139, 19, 'Avaliacao clinica no local. Marco 4, 47% das ocorrencias. Porta de entrada dos sinais vitais.');
insert into samu_catalogo_colunas values (22, 'PRESSÃO', 'pressao', 'texto', 'N', 'sensivel_saude', 27.28, 1208, 32, 'Pressao arterial como texto, ''sistolicaXdiastolica''. ATENCAO: 18,3% dos registros estao em cmHg (''12/8''), nao mmHg; separador varia entre X e barra. Normalizado na silver.');
insert into samu_catalogo_colunas values (23, 'PULSO', 'pulso', 'texto', 'N', 'sensivel_saude', 24.56, 224, 34, 'Frequencia cardiaca em bpm, como texto.');
insert into samu_catalogo_colunas values (24, 'TEMPERATURA', 'temperatura', 'texto', 'N', 'sensivel_saude', 6.26, 189, 7, 'Temperatura em graus Celsius, com virgula decimal (''36,2''). Preenchida em apenas 6,3%.');
insert into samu_catalogo_colunas values (25, 'F.RESP.', 'freq_respiratoria', 'texto', 'N', 'sensivel_saude', 8.95, 79, 6, 'Frequencia respiratoria em irpm. Preenchida em apenas 8,9%.');
insert into samu_catalogo_colunas values (26, 'HGT', 'glicemia', 'texto', 'N', 'sensivel_saude', 23.99, 581, 37, 'Glicemia capilar em mg/dL.');
insert into samu_catalogo_colunas values (27, 'SPO', 'saturacao', 'texto', 'N', 'sensivel_saude', 26.92, 225, 27, 'Saturacao periferica de oxigenio em %.');
insert into samu_catalogo_colunas values (28, 'GLASGOW', 'glasgow', 'texto', 'N', 'sensivel_saude', 9.45, 49, 31, 'Escala de coma de Glasgow, 3 a 15. Preenchida em 9,4% e com 90% dos valores iguais a 15.');
insert into samu_catalogo_colunas values (29, 'OBSERVAÇÕES', 'observacoes', 'texto', 'N', 'sensivel_saude', 44.10, 23972, 497, 'TEXTO LIVRE da equipe. Existe somente quando houve quadro clinico (100% na base real). Sintetico no mock.');
insert into samu_catalogo_colunas values (30, 'DATA/HORA AÇÃO MÉDICA', 'dt_acao_medica', 'timestamp', 'N', 'operacional', 1.23, 760, 19, 'Procedimento executado. Preenchido em apenas 1,2%: na pratica inutilizavel para analise, possivel falha no join sgph_patient_action_taken.');
insert into samu_catalogo_colunas values (31, 'AÇÃO', 'acao', 'codigo', 'N', 'sensivel_saude', 1.23, 18, 41, 'Procedimento, vocabulario controlado (''Infusao venosa de SF 0,9%''). Par atomico com dt_acao_medica: 760 de 760 coincidem.');
insert into samu_catalogo_colunas values (32, 'DATA/HORA HOSPITAL DESTINO', 'dt_hospital_destino', 'timestamp', 'N', 'operacional', 36.12, 22331, 19, 'Chegada ao destino. Marco 5, 35,5% das ocorrencias.');
insert into samu_catalogo_colunas values (33, 'MÉDICO', 'medico', 'texto', 'N', 'identificador_direto', 36.12, 91, 54, 'Medico responsavel. Identificador direto. Vem como ''-'' quando ambas as partes do nome sao nulas. Existe quase so com hospital (98,3%).');
insert into samu_catalogo_colunas values (34, 'HOSPITAL', 'hospital', 'codigo', 'N', 'operacional', 35.52, 133, 56, 'Unidade de destino, 133 valores distintos. Determina a coluna regiao.');
insert into samu_catalogo_colunas values (35, 'MOTIVO DE RECUSA', 'motivo_recusa', 'codigo', 'N', 'operacional', 0.52, 5, 59, 'Motivo de recusa pela unidade receptora, vocabulario controlado. Existe somente com hospital (100%) e em apenas 0,52% das ocorrencias.');
insert into samu_catalogo_colunas values (36, 'REGIÃO', 'regiao', 'codigo', 'N', 'operacional', 36.10, 36, 24, 'DERIVADA do hospital: e o municipio da unidade de destino, nao o da ocorrencia. Hospital e regiao divergem em apenas 0,6% dos casos, que sao erro de dado.');

-- --------------------------------------------------------------------------
-- SEED: as 10 linhas ficticias.
-- --------------------------------------------------------------------------
insert into samu_ocorrencia_bronze ("OCORRÊNCIA", "DATA/HORA CRIAÇÃO", "PACIENTE", "IDADE", "SEXO", "SOLICITANTE", "TELEFONE", "ENDEREÇO", "ORIGEM DA CHAMADA", "BAIRRO", "MUNICÍPIO", "PONTO DE REFERÊNCIA", "DATA/HORA REGULAÇÃO", "CÓD./DESCRIÇÃO TIPO", "CÓD./DESCRIÇÃO SUBTIPO", "CLASSIFICAÇÃO DE RISCO", "QUEIXA", "RECOMENDAÇÕES", "DESPACHO", "FINALIZAÇÃO", "DATA/HORA QUADRO CLÍNICO", "PRESSÃO", "PULSO", "TEMPERATURA", "F.RESP.", "HGT", "SPO", "GLASGOW", "OBSERVAÇÕES", "DATA/HORA AÇÃO MÉDICA", "AÇÃO", "DATA/HORA HOSPITAL DESTINO", "MÉDICO", "HOSPITAL", "MOTIVO DE RECUSA", "REGIÃO")
  values ('S2100007', to_date('2026-11-11 22:03:19', 'yyyy-mm-dd hh24:mi:ss'), 'MARIA JOSE NASCIMENTO', '18 Anos', 'FEMININO', 'ANA DOS SANTOS', '81997792542', 'TRAVESSA EXEMPLO 597, N 119', 'ESTAB PU', 'CASA AMARELA', 'RECIFE', 'EM FRENTE A ESCOLA', to_date('2026-11-11 22:04:28', 'yyyy-mm-dd hh24:mi:ss'), 'NEUROLOGICA/neurologica', 'CONVULSAO/convulsao', 'Vermelho', 'EPISODIO CONVULSIVO, JA CESSADO, SONOLENTO', 'USB', to_date('2026-11-11 22:11:27', 'yyyy-mm-dd hh24:mi:ss'), '12/11/2026 00:26:07 / 1. Ocorrência concluída com êxito', to_date('2026-11-11 23:01:44', 'yyyy-mm-dd hh24:mi:ss'), '130X80', null, null, null, '92', '100', null, 'CONSCIENTE, ORIENTADO, SINAIS VITAIS ESTAVEIS', null, null, to_date('2026-11-12 00:26:07', 'yyyy-mm-dd hh24:mi:ss'), 'DR CARLOS NASCIMENTO', 'UPA OLINDA', null, 'OLINDA');
insert into samu_ocorrencia_bronze ("OCORRÊNCIA", "DATA/HORA CRIAÇÃO", "PACIENTE", "IDADE", "SEXO", "SOLICITANTE", "TELEFONE", "ENDEREÇO", "ORIGEM DA CHAMADA", "BAIRRO", "MUNICÍPIO", "PONTO DE REFERÊNCIA", "DATA/HORA REGULAÇÃO", "CÓD./DESCRIÇÃO TIPO", "CÓD./DESCRIÇÃO SUBTIPO", "CLASSIFICAÇÃO DE RISCO", "QUEIXA", "RECOMENDAÇÕES", "DESPACHO", "FINALIZAÇÃO", "DATA/HORA QUADRO CLÍNICO", "PRESSÃO", "PULSO", "TEMPERATURA", "F.RESP.", "HGT", "SPO", "GLASGOW", "OBSERVAÇÕES", "DATA/HORA AÇÃO MÉDICA", "AÇÃO", "DATA/HORA HOSPITAL DESTINO", "MÉDICO", "HOSPITAL", "MOTIVO DE RECUSA", "REGIÃO")
  values ('S2100024', to_date('2026-11-14 14:09:23', 'yyyy-mm-dd hh24:mi:ss'), 'CARLOS EDUARDO FERREIRA', '49 Anos', 'MASCULINO', 'CARLOS ARAUJO', '81979551968', 'RUA EXEMPLO 971, N 458', 'VIA PÚBLICA', 'GRACAS', 'RECIFE', 'PROXIMO A PRACA', to_date('2026-11-14 14:10:17', 'yyyy-mm-dd hh24:mi:ss'), 'EXTERNA/causas externas', 'ACIDENTMOTO/acidente de transito envolvendo moto', 'Amarelo', 'ACIDENTE DE TRANSITO, VITIMA CONSCIENTE, SEM SANGRAMENTO ATIVO', 'USB', to_date('2026-11-14 14:19:52', 'yyyy-mm-dd hh24:mi:ss'), '14/11/2026 16:46:51 / 1. Ocorrência concluída com êxito', to_date('2026-11-14 15:19:05', 'yyyy-mm-dd hh24:mi:ss'), '80X50', '96', null, null, null, '99', '15', 'ACOMPANHANTE PRESENTE, PACIENTE ESTAVEL', null, null, to_date('2026-11-14 16:46:51', 'yyyy-mm-dd hh24:mi:ss'), 'DR RICARDO NASCIMENTO', 'UPA TORROES', null, 'RECIFE');
insert into samu_ocorrencia_bronze ("OCORRÊNCIA", "DATA/HORA CRIAÇÃO", "PACIENTE", "IDADE", "SEXO", "SOLICITANTE", "TELEFONE", "ENDEREÇO", "ORIGEM DA CHAMADA", "BAIRRO", "MUNICÍPIO", "PONTO DE REFERÊNCIA", "DATA/HORA REGULAÇÃO", "CÓD./DESCRIÇÃO TIPO", "CÓD./DESCRIÇÃO SUBTIPO", "CLASSIFICAÇÃO DE RISCO", "QUEIXA", "RECOMENDAÇÕES", "DESPACHO", "FINALIZAÇÃO", "DATA/HORA QUADRO CLÍNICO", "PRESSÃO", "PULSO", "TEMPERATURA", "F.RESP.", "HGT", "SPO", "GLASGOW", "OBSERVAÇÕES", "DATA/HORA AÇÃO MÉDICA", "AÇÃO", "DATA/HORA HOSPITAL DESTINO", "MÉDICO", "HOSPITAL", "MOTIVO DE RECUSA", "REGIÃO")
  values ('S2100057', to_date('2026-11-11 05:09:29', 'yyyy-mm-dd hh24:mi:ss'), 'JOAO PEDRO DA SILVA', '91 Anos', 'FEMININO', 'JOSEFA OLIVEIRA LIMA', '81957447867', 'AVENIDA EXEMPLO 554, N 242', 'RESIDENCIAL', 'CORDEIRO', 'RECIFE', 'PROXIMO AO MERCADO', to_date('2026-11-11 05:10:13', 'yyyy-mm-dd hh24:mi:ss'), 'EXTERNA/causas externas', 'QUEDALTURA/queda da propria altura', 'Amarelo', 'VITIMA DE QUEDA, CONSCIENTE, REFERE DOR LOCAL', 'ORIENTO REMOÇÃO À UNIDADE DE SAUDE PARA AVALIAÇÃO MÉDICA /// ENVIAR USB SE COBRANÇA', to_date('2026-11-11 05:30:37', 'yyyy-mm-dd hh24:mi:ss'), '11/11/2026 08:11:30 / 1. Ocorrência concluída com êxito', to_date('2026-11-11 06:20:33', 'yyyy-mm-dd hh24:mi:ss'), '110X70', null, null, null, null, null, null, 'ACOMPANHANTE PRESENTE, PACIENTE ESTAVEL', null, null, to_date('2026-11-11 08:11:30', 'yyyy-mm-dd hh24:mi:ss'), 'DR MARIA DOS SANTOS', 'HGV - HOSPITAL GETULIO VARGAS', null, 'RECIFE');
insert into samu_ocorrencia_bronze ("OCORRÊNCIA", "DATA/HORA CRIAÇÃO", "PACIENTE", "IDADE", "SEXO", "SOLICITANTE", "TELEFONE", "ENDEREÇO", "ORIGEM DA CHAMADA", "BAIRRO", "MUNICÍPIO", "PONTO DE REFERÊNCIA", "DATA/HORA REGULAÇÃO", "CÓD./DESCRIÇÃO TIPO", "CÓD./DESCRIÇÃO SUBTIPO", "CLASSIFICAÇÃO DE RISCO", "QUEIXA", "RECOMENDAÇÕES", "DESPACHO", "FINALIZAÇÃO", "DATA/HORA QUADRO CLÍNICO", "PRESSÃO", "PULSO", "TEMPERATURA", "F.RESP.", "HGT", "SPO", "GLASGOW", "OBSERVAÇÕES", "DATA/HORA AÇÃO MÉDICA", "AÇÃO", "DATA/HORA HOSPITAL DESTINO", "MÉDICO", "HOSPITAL", "MOTIVO DE RECUSA", "REGIÃO")
  values ('S2100073', to_date('2026-11-12 07:03:29', 'yyyy-mm-dd hh24:mi:ss'), 'RICARDO ALVES FERREIRA', '1 Anos', 'FEMININO', 'ANTONIO DOS SANTOS', '81999742028', 'RUA EXEMPLO 634, N 422', 'UNIDADE DE SAÚDE', 'NOVA DESCOBERTA', 'RECIFE', 'AO LADO DA IGREJA', to_date('2026-11-12 07:04:02', 'yyyy-mm-dd hh24:mi:ss'), 'EXTERNA/causas externas', 'OUTROS/outros', 'Verde', 'QUEDA DA PROPRIA ALTURA, DOR EM MEMBRO, NEGA DESMAIO', 'ENVIO USB', to_date('2026-11-12 07:19:47', 'yyyy-mm-dd hh24:mi:ss'), '12/11/2026 07:19:47 / 1. Ocorrência concluída com êxito', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null);
insert into samu_ocorrencia_bronze ("OCORRÊNCIA", "DATA/HORA CRIAÇÃO", "PACIENTE", "IDADE", "SEXO", "SOLICITANTE", "TELEFONE", "ENDEREÇO", "ORIGEM DA CHAMADA", "BAIRRO", "MUNICÍPIO", "PONTO DE REFERÊNCIA", "DATA/HORA REGULAÇÃO", "CÓD./DESCRIÇÃO TIPO", "CÓD./DESCRIÇÃO SUBTIPO", "CLASSIFICAÇÃO DE RISCO", "QUEIXA", "RECOMENDAÇÕES", "DESPACHO", "FINALIZAÇÃO", "DATA/HORA QUADRO CLÍNICO", "PRESSÃO", "PULSO", "TEMPERATURA", "F.RESP.", "HGT", "SPO", "GLASGOW", "OBSERVAÇÕES", "DATA/HORA AÇÃO MÉDICA", "AÇÃO", "DATA/HORA HOSPITAL DESTINO", "MÉDICO", "HOSPITAL", "MOTIVO DE RECUSA", "REGIÃO")
  values ('S2100103', to_date('2026-11-11 10:47:05', 'yyyy-mm-dd hh24:mi:ss'), 'JOSEFA MARIA NASCIMENTO', '20 Anos', 'FEMININO', 'ANTONIO PEREIRA', '81984246924', 'TRAVESSA EXEMPLO 255, N 369', 'RESIDENCIAL', 'IBURA', 'RECIFE', 'EM FRENTE A ESCOLA', to_date('2026-11-11 10:48:19', 'yyyy-mm-dd hh24:mi:ss'), 'GERAIS/gerais/outros', 'OUTROS/outros', 'Amarelo', 'QUADRO DE DOR ABDOMINAL HA ALGUMAS HORAS', 'IRA LEVAR A URG POR CONTA PROPRIA', null, '11/11/2026 10:48:19 / 4. Desistência da solicitação/ Sem contato com o solicitante', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null);
insert into samu_ocorrencia_bronze ("OCORRÊNCIA", "DATA/HORA CRIAÇÃO", "PACIENTE", "IDADE", "SEXO", "SOLICITANTE", "TELEFONE", "ENDEREÇO", "ORIGEM DA CHAMADA", "BAIRRO", "MUNICÍPIO", "PONTO DE REFERÊNCIA", "DATA/HORA REGULAÇÃO", "CÓD./DESCRIÇÃO TIPO", "CÓD./DESCRIÇÃO SUBTIPO", "CLASSIFICAÇÃO DE RISCO", "QUEIXA", "RECOMENDAÇÕES", "DESPACHO", "FINALIZAÇÃO", "DATA/HORA QUADRO CLÍNICO", "PRESSÃO", "PULSO", "TEMPERATURA", "F.RESP.", "HGT", "SPO", "GLASGOW", "OBSERVAÇÕES", "DATA/HORA AÇÃO MÉDICA", "AÇÃO", "DATA/HORA HOSPITAL DESTINO", "MÉDICO", "HOSPITAL", "MOTIVO DE RECUSA", "REGIÃO")
  values ('S2100128', to_date('2026-11-12 12:06:40', 'yyyy-mm-dd hh24:mi:ss'), 'RICARDO ALVES BARBOSA', '50 Anos', 'MASCULINO', 'JOSEFA PEREIRA', '81966278353', 'TRAVESSA EXEMPLO 624, N 150', 'VIA PÚBLICA', 'MUSTARDINHA', 'RECIFE', 'PROXIMO A PRACA', to_date('2026-11-12 12:07:55', 'yyyy-mm-dd hh24:mi:ss'), 'NEUROLOGICA/neurologica', 'CONVULSAO/convulsao', 'Amarelo', 'CEFALEIA INTENSA COM TONTURA, CONSCIENTE', 'USB', null, '12/11/2026 12:07:55 / 4. Desistência da solicitação/ Sem contato com o solicitante', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null);
insert into samu_ocorrencia_bronze ("OCORRÊNCIA", "DATA/HORA CRIAÇÃO", "PACIENTE", "IDADE", "SEXO", "SOLICITANTE", "TELEFONE", "ENDEREÇO", "ORIGEM DA CHAMADA", "BAIRRO", "MUNICÍPIO", "PONTO DE REFERÊNCIA", "DATA/HORA REGULAÇÃO", "CÓD./DESCRIÇÃO TIPO", "CÓD./DESCRIÇÃO SUBTIPO", "CLASSIFICAÇÃO DE RISCO", "QUEIXA", "RECOMENDAÇÕES", "DESPACHO", "FINALIZAÇÃO", "DATA/HORA QUADRO CLÍNICO", "PRESSÃO", "PULSO", "TEMPERATURA", "F.RESP.", "HGT", "SPO", "GLASGOW", "OBSERVAÇÕES", "DATA/HORA AÇÃO MÉDICA", "AÇÃO", "DATA/HORA HOSPITAL DESTINO", "MÉDICO", "HOSPITAL", "MOTIVO DE RECUSA", "REGIÃO")
  values ('S2100148', to_date('2026-11-11 22:12:41', 'yyyy-mm-dd hh24:mi:ss'), 'FRANCISCA OLIVEIRA LIMA', '85 Anos', 'FEMININO', 'ANTONIO OLIVEIRA LIMA', '81990117909', 'RUA EXEMPLO 986, N 159', 'RESIDENCIAL', 'TEJIPIO', 'RECIFE', 'PROXIMO AO MERCADO', to_date('2026-11-11 22:13:19', 'yyyy-mm-dd hh24:mi:ss'), 'GERAIS/gerais/outros', 'OUTROS/outros', 'Amarelo', 'QUADRO DE DOR ABDOMINAL HA ALGUMAS HORAS', 'USB', to_date('2026-11-11 22:38:06', 'yyyy-mm-dd hh24:mi:ss'), '11/11/2026 22:38:06 / 5. Removido antes do atendimento por particulares', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null);
insert into samu_ocorrencia_bronze ("OCORRÊNCIA", "DATA/HORA CRIAÇÃO", "PACIENTE", "IDADE", "SEXO", "SOLICITANTE", "TELEFONE", "ENDEREÇO", "ORIGEM DA CHAMADA", "BAIRRO", "MUNICÍPIO", "PONTO DE REFERÊNCIA", "DATA/HORA REGULAÇÃO", "CÓD./DESCRIÇÃO TIPO", "CÓD./DESCRIÇÃO SUBTIPO", "CLASSIFICAÇÃO DE RISCO", "QUEIXA", "RECOMENDAÇÕES", "DESPACHO", "FINALIZAÇÃO", "DATA/HORA QUADRO CLÍNICO", "PRESSÃO", "PULSO", "TEMPERATURA", "F.RESP.", "HGT", "SPO", "GLASGOW", "OBSERVAÇÕES", "DATA/HORA AÇÃO MÉDICA", "AÇÃO", "DATA/HORA HOSPITAL DESTINO", "MÉDICO", "HOSPITAL", "MOTIVO DE RECUSA", "REGIÃO")
  values ('S2100162', to_date('2026-11-10 01:21:21', 'yyyy-mm-dd hh24:mi:ss'), 'ANTONIO MARCOS MONTEIRO', '78 Anos', 'FEMININO', 'SEVERINO MONTEIRO', '81984742126', 'RUA EXEMPLO 968, N 553', 'RESIDENCIAL', 'TORROES', 'RECIFE', 'AO LADO DA IGREJA', to_date('2026-11-10 01:22:55', 'yyyy-mm-dd hh24:mi:ss'), 'GERAIS/gerais/outros', 'OUTROS/outros', 'Verde', 'PACIENTE COM INDISPOSICAO E TONTURA, CONSCIENTE', 'USB', to_date('2026-11-10 01:39:22', 'yyyy-mm-dd hh24:mi:ss'), '10/11/2026 02:26:26 / 7. Paciente recusa ser removido', to_date('2026-11-10 02:26:26', 'yyyy-mm-dd hh24:mi:ss'), '110X70', null, null, null, '136', '99', '15', 'CONSCIENTE, ORIENTADO, SINAIS VITAIS ESTAVEIS', null, null, null, null, null, null, null);
insert into samu_ocorrencia_bronze ("OCORRÊNCIA", "DATA/HORA CRIAÇÃO", "PACIENTE", "IDADE", "SEXO", "SOLICITANTE", "TELEFONE", "ENDEREÇO", "ORIGEM DA CHAMADA", "BAIRRO", "MUNICÍPIO", "PONTO DE REFERÊNCIA", "DATA/HORA REGULAÇÃO", "CÓD./DESCRIÇÃO TIPO", "CÓD./DESCRIÇÃO SUBTIPO", "CLASSIFICAÇÃO DE RISCO", "QUEIXA", "RECOMENDAÇÕES", "DESPACHO", "FINALIZAÇÃO", "DATA/HORA QUADRO CLÍNICO", "PRESSÃO", "PULSO", "TEMPERATURA", "F.RESP.", "HGT", "SPO", "GLASGOW", "OBSERVAÇÕES", "DATA/HORA AÇÃO MÉDICA", "AÇÃO", "DATA/HORA HOSPITAL DESTINO", "MÉDICO", "HOSPITAL", "MOTIVO DE RECUSA", "REGIÃO")
  values ('S2100192', to_date('2026-11-11 10:32:34', 'yyyy-mm-dd hh24:mi:ss'), 'LUCIA HELENA MONTEIRO', '9 Meses', 'MASCULINO', 'SEVERINO BARBOSA', '81973206685', 'RUA EXEMPLO 964, N 946', 'RESIDENCIAL', 'BOMBA DO HEMETERIO', 'RECIFE', 'PROXIMO AO MERCADO', to_date('2026-11-11 10:33:26', 'yyyy-mm-dd hh24:mi:ss'), 'RESPIRATORIA/respiratoria', 'OUTROS/outros', 'Verde', 'DISPNEIA PROGRESSIVA, USO DE MUSCULATURA ACESSORIA', 'ORIENTADA', null, '11/11/2026 10:33:26 / 11. Paciente não necessita de remoção', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null);
insert into samu_ocorrencia_bronze ("OCORRÊNCIA", "DATA/HORA CRIAÇÃO", "PACIENTE", "IDADE", "SEXO", "SOLICITANTE", "TELEFONE", "ENDEREÇO", "ORIGEM DA CHAMADA", "BAIRRO", "MUNICÍPIO", "PONTO DE REFERÊNCIA", "DATA/HORA REGULAÇÃO", "CÓD./DESCRIÇÃO TIPO", "CÓD./DESCRIÇÃO SUBTIPO", "CLASSIFICAÇÃO DE RISCO", "QUEIXA", "RECOMENDAÇÕES", "DESPACHO", "FINALIZAÇÃO", "DATA/HORA QUADRO CLÍNICO", "PRESSÃO", "PULSO", "TEMPERATURA", "F.RESP.", "HGT", "SPO", "GLASGOW", "OBSERVAÇÕES", "DATA/HORA AÇÃO MÉDICA", "AÇÃO", "DATA/HORA HOSPITAL DESTINO", "MÉDICO", "HOSPITAL", "MOTIVO DE RECUSA", "REGIÃO")
  values ('S2100196', to_date('2026-11-10 16:25:49', 'yyyy-mm-dd hh24:mi:ss'), 'RICARDO ALVES DOS SANTOS', '57 Anos', 'FEMININO', 'SEVERINO DA SILVA', '81945755709', 'AVENIDA EXEMPLO 757, N 508', 'VIA PÚBLICA', 'PARNAMIRIM', 'RECIFE', 'AO LADO DA IGREJA', to_date('2026-11-10 16:26:25', 'yyyy-mm-dd hh24:mi:ss'), 'EXTERNA/causas externas', 'ACIDENTMOTO/acidente de transito envolvendo moto', 'Amarelo', 'VITIMA DE QUEDA, CONSCIENTE, REFERE DOR LOCAL', 'USB', to_date('2026-11-10 16:41:06', 'yyyy-mm-dd hh24:mi:ss'), '10/11/2026 19:30:43 / 1. Ocorrência concluída com êxito', to_date('2026-11-10 17:51:53', 'yyyy-mm-dd hh24:mi:ss'), '100X80', '69', '35,3', '18', '114', '98', '15', 'ORIENTADO, AFEBRIL, MANTIDO EM OBSERVACAO', to_date('2026-11-10 17:56:51', 'yyyy-mm-dd hh24:mi:ss'), 'Instalação de catéter de oxigênio', to_date('2026-11-10 19:30:43', 'yyyy-mm-dd hh24:mi:ss'), 'DR SEVERINO DOS SANTOS', 'HPS - Hospital Metropolitano Oeste Pelópidas Silveira', 'Indisponibilidade de vagas na unidade receptora', 'RECIFE');

-- conferencia rapida
select fl_despachou, fl_avaliou, fl_transportou, count(*)
  from samu_ocorrencia_silver group by fl_despachou, fl_avaliou, fl_transportou
  order by 1, 2, 3;
