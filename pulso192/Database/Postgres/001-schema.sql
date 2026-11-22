CREATE TABLE IF NOT EXISTS ocorrencias (
    id UUID PRIMARY KEY,
    data_hora TIMESTAMPTZ NOT NULL,
    municipio TEXT NOT NULL,
    bairro TEXT NOT NULL,
    origem_chamado TEXT NOT NULL,
    tipo TEXT NOT NULL,
    subtipo TEXT NOT NULL,
    sexo TEXT NOT NULL CHECK (sexo IN ('NAO_INFORMADO', 'MASCULINO', 'FEMININO')),
    idade INTEGER NULL CHECK (idade IS NULL OR idade BETWEEN 0 AND 110),
    motivo_finalizacao TEXT NULL,
    codigo_desfecho INTEGER NULL,
    desfecho TEXT NOT NULL,
    sinalizacoes TEXT[] NOT NULL DEFAULT '{}',
    hash VARCHAR(64) NOT NULL UNIQUE
);

CREATE INDEX IF NOT EXISTS ix_ocorrencias_data_hora ON ocorrencias (data_hora DESC);
CREATE INDEX IF NOT EXISTS ix_ocorrencias_local ON ocorrencias (municipio, bairro);
