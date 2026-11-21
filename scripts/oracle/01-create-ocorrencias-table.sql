CREATE TABLE ocorrencias(
    data VARCHAR(20),
    hora_minuto VARCHAR(10),
    municipio VARCHAR(255),
    bairro VARCHAR(255),
    endereco VARCHAR(255),
    origem_chamado VARCHAR(255),
    tipo VARCHAR(255),
    subtipo VARCHAR(255),   
    sexo VARCHAR(255) CHECK (sexo IN ('FEMININO', 'MASCULINO')),
    idade INTEGER,
    motivo_finalizacao VARCHAR(255),
    motivo_desfecho VARCHAR(255)    
);