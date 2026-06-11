# Horus — Integração Mercado Livre

Serviço Node.js que sincroniza dados entre a **API do Mercado Livre** e o banco de dados Oracle do **ERP Horus**. O aplicativo roda de forma contínua, consultando a API do marketplace e gravando as informações nas tabelas do Horus por meio de procedures PL/SQL.

## O que faz

A integração cobre os fluxos principais de operação no Mercado Livre:

| Módulo | Descrição |
|--------|-----------|
| **Autenticação OAuth** | Obtém e renova tokens de acesso (`access_token` / `refresh_token`) com base nas credenciais cadastradas no Horus |
| **Tipos de anúncio** | Importa os tipos de listagem disponíveis no site MLB (`listing_types`) |
| **Categorias** | Importa a árvore de categorias do Mercado Livre Brasil (`sites/MLB/categories`) |
| **Produtos** | Sincroniza anúncios do vendedor (título, preço, estoque, SKU, GTIN, categoria, etc.) |
| **Pedidos** | Importa pedidos pagos e aprovados, incluindo dados de faturamento, endereço de entrega e itens |

Os dados ficam disponíveis no Horus para processos internos como faturamento, expedição e controle de estoque.

## Arquitetura

```
Mercado Livre API  ──►  Node.js (axios)  ──►  Oracle (Horus)
                              │
                         node-cron
                    (jobs agendados)
```

- **Entrada:** credenciais e parâmetros OAuth na tabela `MERC_LIVRE_CONFIG`, identificados pela unidade empresarial.
- **Processamento:** serviços em JavaScript consomem a API REST do Mercado Livre e chamam repositories que executam procedures Oracle (`PRC_MLAPI_*`).
- **Persistência:** tabelas `MERC_LIVRE_*` no schema `HORUS`.

## Estrutura do projeto

```
src/
├── app.js                    # Ponto de entrada — carrega os jobs
├── config/
│   └── database.js           # Conexão Oracle (oracledb)
├── jobs/
│   └── execJobs.js           # Agendamento e execução dos jobs
├── services/                 # Integração com a API do Mercado Livre
│   ├── token/                # OAuth: obtenção e refresh de token
│   ├── tpAnuncio/            # Tipos de anúncio
│   ├── categoria/            # Categorias MLB
│   ├── produto/              # Produtos/anúncios
│   ├── ordem/                # Pedidos, endereço e faturamento
│   └── pergunta/             # Perguntas nos anúncios
├── repositories/             # Acesso ao banco via procedures Oracle
├── utils/
│   ├── logger.js             # Log de erros em error.log
│   └── oracleErrorHandler.js
└── oracle/                   # Scripts DDL (tabelas, views, procedures)
```

## Pré-requisitos

- **Node.js** 18+ (recomendado)
- **Oracle Instant Client** instalado localmente (modo Thick do `oracledb`)
- **Banco Oracle** com o schema Horus e os objetos em `src/oracle/` já aplicados
- **Aplicação cadastrada** no [Mercado Livre Developers](https://developers.mercadolivre.com.br/) com `client_id`, `client_secret`, `redirect_uri` e código de autorização (`code`)

> O caminho do Oracle Client está configurado em `src/config/database.js`. Ajuste a propriedade `libDir` conforme a instalação da máquina.

## Configuração

Crie um arquivo `.env` na raiz do projeto:

```env
DB_USER=usuario_oracle
DB_PASSWORD=senha
DB_CONNECT=host:1521/servico

UNIDADE_EMPRESARIAL_ID=1
```

As credenciais OAuth (`MLCN_CLIENT_ID`, `MLCN_CLIENT_SECRET`, `MLCN_CODE`, `MLCN_REDIRECT_URI`) são mantidas na tabela `MERC_LIVRE_CONFIG` do Horus, não no `.env`.

### Configuração no Horus

Cadastre os parâmetros da integração na tabela `MERC_LIVRE_CONFIG` para a unidade empresarial desejada. A view `VIEW_MERC_LIVRE_CONFIG` expõe os campos necessários e indica se o token está expirado (`EXPIRES = 'S'`).

## Instalação e execução

```bash
npm install
node src/app.js
```

No Windows, também é possível usar o script `Iniciar.bat`.

Ao iniciar, o serviço executa **todos os jobs imediatamente** e depois mantém a sincronização via cron.

## Jobs agendados

| Job | Intervalo | Função |
|-----|-----------|--------|
| Token | A cada 30 minutos | Renova o `access_token` quando necessário |
| Tipos de anúncio | A cada 12 horas | Atualiza `MERC_LIVRE_TP_ANUNCIO` |
| Categorias | A cada 12 horas | Atualiza `MERC_LIVRE_CATEGORIA` |
| Produtos | A cada 5 minutos | Sincroniza anúncios do vendedor |
| Pedidos | A cada 5 minutos | Importa pedidos pagos e aprovados |
| Perguntas | A cada 5 minutos | Sincroniza perguntas recebidas nos anúncios |

## Objetos Oracle

Scripts DDL e procedures ficam em `src/oracle/`:

| Objeto | Finalidade |
|--------|------------|
| `MERC_LIVRE_CONFIG` | Credenciais OAuth e tokens |
| `MERC_LIVRE_PRODUTO` | Anúncios sincronizados |
| `MERC_LIVRE_ORDEM` | Cabeçalho dos pedidos |
| `MERC_LIVRE_ORDEM_ITEM` | Itens dos pedidos |
| `MERC_LIVRE_ORDEM_END` | Endereço de entrega |
| `MERC_LIVRE_CATEGORIA` | Categorias MLB |
| `MERC_LIVRE_TP_ANUNCIO` | Tipos de listagem |
| `MERC_LIVRE_PERGUNTA` | Perguntas recebidas nos anúncios |
| `PRC_MLAPI_*` | Procedures de insert/update chamadas pelos repositories |

## Endpoints da API utilizados

- `POST /oauth/token` — autenticação OAuth
- `GET /users/{user_id}/items/search` — lista de produtos do vendedor
- `GET /items/{id}` — detalhes do produto
- `GET /orders/search?seller={user_id}` — pedidos do vendedor
- `GET /orders/{id}` — detalhes do pedido
- `GET /orders/{id}/billing_info` — dados de faturamento (CPF/CNPJ, endereço)
- `GET /sites/MLB/categories` — categorias
- `GET /sites/MLB/listing_types` — tipos de anúncio
- `GET /my/received_questions/search?api_version=4` — perguntas recebidas pelo vendedor
- `GET /questions/{id}?api_version=4` — detalhe da pergunta (inclui dados do comprador)

## Docker (Oracle local para desenvolvimento)

Há um `docker-compose.yml` com Oracle XE 21 para ambiente de testes:

```bash
docker compose up -d
```

A porta `1521` fica exposta. Após subir o container, aplique os scripts de `src/oracle/` no banco.

## Logs e erros

Erros são registrados em `src/error.log` pelo utilitário `logger.js`. Mensagens também aparecem no console durante a execução dos jobs.

## Dependências principais

- [axios](https://axios-http.com/) — chamadas HTTP à API do Mercado Livre
- [oracledb](https://oracle.github.io/node-oracledb/) — conexão com Oracle
- [node-cron](https://github.com/node-cron/node-cron) — agendamento dos jobs
- [dotenv](https://github.com/motdotla/dotenv) — variáveis de ambiente
- [winston](https://github.com/winstonjs/winston) — logging (declarado; uso principal via `logger.js`)

## Licença

ISC
