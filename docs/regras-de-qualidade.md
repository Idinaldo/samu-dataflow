# US03. Dicionário de dados e regras de qualidade

**Pulso 192 (antigo SAMU DataFlow)** · Responsável: Filipe · Sprint 1 · Versão 1, 19/10/2026

## 1. Para que serve

Define o que cada coluna dos dados de ocorrências significa e quais regras o motor de tratamento (o "T" do ETL) aplica antes de carregar no PostgreSQL. A US09 (transformação) implementa exatamente estas regras, e cada uma vira um teste unitário.

Base usada: arquivo de dados abertos do SAMU enviado pelo CIE. 113.016 registros, de 01/01/2026 a 31/07/2026, 12 colunas, separador `;`, UTF-8. Quando o Oracle do CIE ficar pronto, a mesma análise roda nele e este documento é atualizado.

## 2. Dicionário de dados

| Coluna | Tipo no banco final | O que é | Vazios | Observações |
|---|---|---|---|---|
| `data` + `hora_minuto` | `data_hora` (timestamp) | Data (AAAA-MM-DD) e hora (HH:MM:SS) do chamado | 0 | Viram um campo só, no fuso America/Recife. Nenhuma data ou hora inválida na base. |
| `municipio` | texto | Município da ocorrência | 1 | 72 municípios, sem acento, maiúsculo. Recife tem 39% dos registros. |
| `bairro` | texto | Bairro da ocorrência | 2 | 967 valores. Variações de escrita do mesmo bairro e rodovias no lugar do bairro. "CENTRO" aparece em 42 municípios: bairro só faz sentido junto com município. |
| `endereco` | texto | Logradouro | 6.121 (5,4%) | Às vezes só "PE", "BR" ou "AV". 7.759 registros têm número da casa (ver seção 4). |
| `origem_chamado` | texto (lista fechada) | Tipo de local do chamado | 7 | Válidos: RESIDENCIAL, VIA PÚBLICA, UNIDADE DE SAÚDE, ESTAB PR, ESTAB PU, ILPS, ANI/ALI. 2 valores digitados errado (ver seção 4). |
| `tipo` | texto (lista fechada) | Classificação clínica geral | 0 | 18 tipos válidos + 1 registro de teste. |
| `subtipo` | texto (lista fechada) | Classificação clínica detalhada | 26 | 113 valores. "OUTROS" é 39% dos registros. |
| `sexo` | texto (lista fechada) | Sexo do paciente | 2.112 (1,9%) | MASCULINO ou FEMININO. |
| `idade` | inteiro | Idade em anos | 14.532 (12,9%) | 15 idades impossíveis (112 a 754). 249 com idade 0 (menos de 1 ano, válido). |
| `motivo_finalizacao` | texto | Encerramento antes do atendimento | 112.947 (99,9%) | Quase vazia. Carrega, mas não serve pra análise. |
| `motivo_desfecho` | `codigo_desfecho` (inteiro) + `desfecho` (texto) | Como a ocorrência terminou | 0 | 14 desfechos numerados + "SEM DESFECHO" (115). Inclui trote e solicitação duplicada. |

## 3. Regras de validação

Ações:

- **Rejeitar:** não carrega, entra no relatório de qualidade.
- **Corrigir:** padroniza o valor e carrega.
- **Sinalizar:** carrega com flag; o analista decide se usa.

A ideia é rejeitar pouco: um registro com idade errada ainda tem data, local e tipo que valem pra análise.

| ID | Regra | Coluna | Ação | Casos na base |
|---|---|---|---|---|
| R01 | Registro de teste: `tipo` ou `subtipo` contém "TESTE" | tipo, subtipo | Rejeitar | 1 |
| R02 | Duplicata exata: as 12 colunas iguais a outro registro | todas | Rejeitar a cópia | 1 |
| R03 | Juntar `data` + `hora_minuto` em `data_hora`; se inválido, rejeitar | data, hora_minuto | Corrigir / Rejeitar | 0 inválidos |
| R04 | Idade fora de 0 a 110 vira nula, flag `idade_invalida` | idade | Corrigir + Sinalizar | 15 |
| R05 | Sexo vazio vira "NAO INFORMADO" | sexo | Corrigir | 2.112 |
| R06 | `origem_chamado` fora da lista vira "NAO INFORMADO", flag. Valor original **não** vai pro log | origem_chamado | Corrigir + Sinalizar | 9 |
| R07 | Município vazio ou fora da lista conhecida: flag `local_invalido` | municipio | Sinalizar | 1 |
| R08 | Padronizar bairro (sem acento, espaços em parênteses e hífen). Ex.: "BOA VISTA(CENTRO)" = "BOA VISTA (CENTRO)", "BR - 408" = "BR 408". Vazio: flag | bairro | Corrigir + Sinalizar | 6 variações + 2 vazios |
| R09 | Endereço genérico ("PE", "BR", "AV" sozinhos) vira nulo | endereco | Corrigir | 2.862 |
| R10 | Subtipo vazio vira "NAO INFORMADO" | subtipo | Corrigir | 26 |
| R11 | Desfecho "2. TROTE": flag `trote`, fora das contagens epidemiológicas | motivo_desfecho | Sinalizar | 136 |
| R12 | Desfecho "3. SOLICITAÇÃO DUPLICADA": flag `duplicata_operacional` | motivo_desfecho | Sinalizar | 3.324 |
| R13 | Separar número e texto do desfecho ("1. OCORRÊNCIA..." vira código 1 + texto) | motivo_desfecho | Corrigir | todos |
| R14 | Possível duplicata: mesma data, hora e endereço | data, hora, endereco | Sinalizar | 8 |
| R15 | Incoerência: tipo OBSTETRICA com sexo MASCULINO | tipo, sexo | Sinalizar | 24 |
| R16 | Incoerência: finalização "CANCELADA" com desfecho "CONCLUÍDA COM ÊXITO" | motivo_finalizacao, motivo_desfecho | Sinalizar | 4 |

**Resultado esperado na base atual:** 2 rejeitados (R01 e R02), 113.014 carregados, parte com flag.

## 4. Privacidade (LGPD)

- **Número da casa no endereço:** 7.759 registros. Junto com hora exata, idade, sexo e tipo clínico, identifica o paciente.
- **Regra geral do sistema:** logs e relatórios de qualidade não copiam valores das colunas, só contagens, número da linha e ID da regra.
- **Proposta pro CIE:** guardar o endereço sem número da casa no banco final, ou o endereço completo numa tabela com acesso restrito.

## 5. Adaptação do mock Oracle de 36 colunas

O mock Oracle reproduz a camada bronze com 36 colunas; ele não tem o mesmo formato do CSV de 12 colunas usado na especificação original. O pipeline adapta os campos necessários ao modelo final:

| Campo do mock Oracle | Campo tratado |
|---|---|
| `DATA/HORA CRIAÇÃO` | `data_hora` |
| `MUNICÍPIO`, `BAIRRO` | `municipio`, `bairro` |
| `ORIGEM DA CHAMADA` | `origem_chamado` |
| `CÓD./DESCRIÇÃO TIPO`, `CÓD./DESCRIÇÃO SUBTIPO` | `tipo`, `subtipo` (código antes da barra) |
| `SEXO`, `IDADE` | `sexo`, `idade` |
| `FINALIZAÇÃO` | `codigo_desfecho`, `desfecho` |

O endereço completo é usado apenas durante a transformação para detectar possíveis duplicatas e não é enviado à API nem armazenado no PostgreSQL; assim, R09 é atendida por omissão do campo. O hash da linha bruta é usado para deduplicação, não aparece na API ou no relatório.

Limitações da adaptação: a camada bronze já tipa `DATA/HORA CRIAÇÃO` como data, então R03 não consegue observar texto de data inválido; a fonte Oracle mock sempre informa `RECIFE`, portanto R07 valida o escopo do mock; e a coluna bronze `FINALIZAÇÃO` não contém um campo independente `motivo_finalizacao`, então R16 só poderá ser avaliada quando a origem fornecer esse dado separadamente.

