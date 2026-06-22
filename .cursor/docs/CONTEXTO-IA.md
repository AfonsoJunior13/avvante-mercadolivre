# Contexto do Projeto — Guia para IA

> **Instrução para agentes de IA:** leia este arquivo **antes** de alterar código, responder dúvidas ou continuar o desenvolvimento. Complemente com `README.md` (uso/instalação) e `ARQUITETURA.md` (diagramas e fluxos detalhados).

---

## Resumo em uma linha

Serviço **Node.js worker** (sem API HTTP) que sincroniza periodicamente dados da **API Mercado Livre** para o **Oracle do ERP Horus**, via jobs cron e procedures `PRC_MLAPI_*`.

---

## Identidade do projeto

| Item | Valor |
|------|-------|
| Nome npm | `horus-mercado-livre` |
| Repositório | `avvante-mercado-livre` |
| Cliente/ERP | Horus (schema Oracle `HORUS`) |
| Marketplace | Mercado Livre Brasil (`sites/MLB`) |
| Entry point | `src/app.js` (execLogger → dotenv → jobs) → `src/jobs/execJobs.js` |
| Linguagem | JavaScript CommonJS (`require` / `module.exports`) |
| Idioma do usuário | **Português** (sempre responder em PT-BR) |

---

## O que este projeto **é** e **não é**

**É:**
- Integração batch pull (polling) ML → Horus (produtos, pedidos, categorias, tipos de anúncio, **perguntas**, **pagamento/repasse ML**)
- Processo de longa duração com `node-cron`
- Ponte entre axios (API REST) e oracledb (procedures PL/SQL)

**Não é:**
- API REST própria (sem Express/Fastify)
- Frontend
- Envio de dados Horus → Mercado Livre (somente importação ML → Oracle hoje)
- Multi-tenant na mesma instância (uma `UNIDADE_EMPRESARIAL_ID` por `.env`)
- Projeto com testes automatizados (não há suite de testes)

---

## Documentação relacionada

| Arquivo | Quando usar |
|---------|-------------|
| `README.md` | Instalação, `.env`, jobs, endpoints ML |
| `ARQUITETURA.md` | Diagramas, camadas, fluxos por módulo |
| `OAUTH-TOKEN.md` | OAuth passo a passo e troubleshooting |
| `MercadoLivre-API.md` | **Índice da API ML** — endpoints, permissões, notificações, boas práticas |
| `CONTEXTO-IA.md` | **Este arquivo** — convenções, armadilhas, onde mexer |
| `src/oracle/*.tab`, `*.prc`, `*.vw` | DDL e regras de negócio no banco |

---

## Stack e dependências

```
Node.js 18+
Oracle Instant Client (modo Thick — obrigatório)
Oracle Database (Horus)
Mercado Livre OAuth 2.0
```

| Pacote | Uso real no código |
|--------|---------------------|
| `axios` | HTTP interno em `utils/mlApi.js` (não usar direto nos services) |
| `oracledb` | Conexão e execução de procedures |
| `node-cron` | Agendamento em `execJobs.js` |
| `dotenv` | `.env` (DB + unidade empresarial + Oracle Client) |
| `qs` | Body OAuth (`application/x-www-form-urlencoded`) |
| `winston` | Declarado no `package.json`; **logging efetivo** via `utils/logger.js`, `execLogger.js` e `jsonLogger.js` |

---

## Variáveis de ambiente (`.env`)

Arquivo **não versionado** (`.gitignore`). Nunca commitar.

```env
DB_USER=
DB_PASSWORD=
DB_CONNECT=host:1521/servico
UNIDADE_EMPRESARIAL_ID=
ORACLE_CLIENT_LIB_DIR=C:\caminho\para\oracle\instant\client
```

**OAuth fica no banco**, tabela `MERC_LIVRE_CONFIG`:
`MLCN_CLIENT_ID`, `MLCN_CLIENT_SECRET`, `MLCN_CODE`, `MLCN_REDIRECT_URI`, `MLCN_TOKEN`, `MLCN_ACCESS_TOKEN`, `MLCN_USER_ID`.

View de leitura: `VIEW_MERC_LIVRE_CONFIG` (campo `EXPIRES`: `S` = precisa renovar token).

---

## Configuração crítica — Oracle Client

Em `src/config/database.js`:

```javascript
oracledb.initOracleClient({ libDir: process.env.ORACLE_CLIENT_LIB_DIR });
```

- Caminho via **`ORACLE_CLIENT_LIB_DIR`** no `.env` (obrigatório).
- Se ausente ou inválido, o processo encerra com `process.exit(1)`.
- Ajustar o caminho por ambiente (Windows/Linux/Docker).

---

## Sistema de logs

Carregado na subida via `src/app.js` → `require('./utils/execLogger')` **antes** dos demais módulos.

| Tipo | Utilitário | Pasta | Nome do arquivo | Formato da linha/conteúdo |
|------|------------|-------|-----------------|---------------------------|
| Execução (console) | `utils/execLogger.js` | `logs/exec/` | `yyyymmdd.log` | `HH:mm:ss mensagem` |
| Erros | `utils/logger.js` + hook em `execLogger` | `logs/error/` | `yyyymmdd.logError` | `HH:mm:ss mensagem` |
| JSON enviado | `utils/jsonLogger.js` | `logs/json/env/` | `yyyymmddhhmmss_rotina.json` | payload mascarado (tokens/secrets) |
| JSON recebido | `utils/jsonLogger.js` | `logs/json/rec/` | `yyyymmddhhmmss_rotina.json` | resposta da API ou retorno Oracle |

- **`console.log` / `warn` / `info`** → espelhados em `logs/exec/`.
- **`console.error`** → espelhado em `logs/exec/` **e** `logs/error/`.
- **`logger.logError()`** → `logs/error/` (erros tratados em jobs, ordens, produtos, perguntas).
- **Chamadas API ML** → via `utils/mlApi.js` (`get`, `request`); grava env/rec automaticamente.
- **Repositories** → gravam binds (env) e confirmação/leitura (rec) via `jsonLogger`.

A pasta `logs/` está no `.gitignore`. Colisão de arquivos no mesmo segundo recebe sufixo `_1`, `_2`, etc.

---

## Padrão de código (seguir ao adicionar features)

### Estrutura por domínio

Cada entidade segue o mesmo desenho:

```
services/{dominio}/
  getXxx.js          → chama API ML via mlApi + Bearer token via getTokenConfig
  xxxs.js            → orquestra: busca API → transforma → chama repository

repositories/
  xxxRepository.js → connection.execute('BEGIN PRC_MLAPI_... END;') + log JSON env/rec

src/utils/
  mlApi.js           → wrapper axios com log JSON automático
  jsonLogger.js      → gravação logs/json/env e logs/json/rec
  execLogger.js      → intercepta console → logs/exec e logs/error
  logger.js          → logError → logs/error

src/oracle/
  prc_mlapi_xxx_update.prc → insert/update + regras Horus
```

### Fluxo de token (obrigatório em todo service de API)

Todo `get*.js` que chama a API ML deve:

1. `const tokenConfig = await getTokenConfig()` (de `services/token/getToken.js`)
2. Usar `tokenConfig.MLCN_ACCESS_TOKEN` e, se necessário, `tokenConfig.MLCN_USER_ID`

`getToken()` orquestra renovação OAuth; **`getTokenConfig()`** valida config + access token e lança erro claro se indisponível. Em falha OAuth, `getToken()` **relança** o erro (não retorna `undefined`).

Chamadas HTTP à API ML: usar **`mlApi.get(rotina, url, config)`** ou **`mlApi.request(rotina, config)`** — não axios direto.

### Repositories

- Sempre: `getConnection()` → `execute` → `connection.close()` no `finally`
- Erros Oracle `errorNum === 20000` → `tratarErroOracle()` em `utils/oracleErrorHandler.js`
- Parâmetro `P_TRANSACTION: 0` em todas as procedures (commit controlado no PL/SQL)
- Procedures usam `GENERATE_NEXT_ID` para PKs novas (padrão Horus)
- **Gravação** sempre via procedure; **leitura** pode usar SELECT direto (ex.: `configFind`, `getOrdensPagtoAberto`)

### Estilo

- CommonJS, sem TypeScript
- Funções `async/await`
- Nomes em português nos domínios de negócio (`ordens`, `produtos`, `categorias`, `perguntas`)
- Campos API ML em inglês; campos mapeados para Oracle com prefixos `MLOR_`, `MLPD_`, `MLCN_`, `MLQT_`, etc.
- Evitar refatorações amplas não solicitadas; manter diff mínimo

---

## Jobs — ponto central de orquestração

Arquivo: `src/jobs/execJobs.js`

| Função | Cron (planejado) | Cron ativo hoje | Service |
|--------|------------------|-----------------|---------|
| `refreshToken` | `*/30 * * * *` | **comentado** | `services/token/getToken.js` |
| `tpAnuncioSave` | `0 */12 * * *` | **comentado** | `services/tpAnuncio/tpAnuncios.js` |
| `categoriasSave` | `0 */12 * * *` | **comentado** | `services/categoria/categorias.js` |
| `produtosSave` | `*/5 * * * *` | **comentado** | `services/produto/produtos.js` |
| `ordensSave` | `*/5 * * * *` | **comentado** | `services/ordem/ordens.js` |
| `ordemPagtoSave` | (não definido) | **sem cron** | `services/ordem/ordemPagto.js` |
| `perguntasSave` | `*/5 * * * *` | **comentado** | `services/pergunta/perguntas.js` |

**Estado atual:** na subida, `Iniciar()` executa **todos** os jobs **uma vez** em sequência (`token → tpAnuncio → categoria → produto → ordem → ordemPagto → pergunta`). Os `cron.schedule` estão **todos comentados** — o processo fica ocioso após a primeira rodada até ser reiniciado ou até alguém descomentar os crons.

Para novo job: criar função async + `cron.schedule` + exportar lógica no service correspondente + incluir chamada em `Iniciar()`.

### Inventário atual (`src/`)

```
services/
  token/       getToken.js, findToken.js, refreshToken.js
  tpAnuncio/   tpAnuncios.js, getTpAnuncios.js
  categoria/   categorias.js, getCategorias.js
  produto/     produtos.js, getProdutosAll.js, getProduto.js
  ordem/       ordens.js, ordemPagto.js, getOrdensAll.js, getOrdem.js,
               getDadosFaturamento.js, getEndereco.js, getOrdemPagto.js
  pergunta/    perguntas.js, getPerguntasAll.js, getPergunta.js

repositories/
  configRepository.js, produtoRepository.js, ordemRepository.js,
  ordemItemRepository.js, ordemEndRepository.js, ordemPagtoRepository.js,
  perguntaRepository.js, categoriaRepository.js, tpAnuncioRepository.js

utils/
  mlApi.js, jsonLogger.js, execLogger.js, logger.js, oracleErrorHandler.js
```

---

## Mapeamento rápido: "preciso alterar X" → arquivo

| Necessidade | Onde alterar |
|-------------|--------------|
| Novo intervalo de sync | `src/jobs/execJobs.js` |
| Nova chamada API ML | `src/services/{dominio}/get*.js` |
| Regra de transformação dos dados | `src/services/{dominio}/*.js` (orquestrador) |
| Persistência / novo campo no banco | `src/repositories/*.js` + `src/oracle/prc_mlapi_*.prc` + `.tab` |
| Credenciais OAuth / token | Banco `MERC_LIVRE_CONFIG` + `services/token/*` |
| Conexão Oracle | `src/config/database.js` + `.env` (`ORACLE_CLIENT_LIB_DIR`) |
| Log de execução (console) | `src/utils/execLogger.js` → `logs/exec/yyyymmdd.log` |
| Log de erros | `src/utils/logger.js` → `logs/error/yyyymmdd.logError` |
| Log JSON API/Oracle | `src/utils/jsonLogger.js` + `src/utils/mlApi.js` → `logs/json/env/` e `logs/json/rec/` |
| Filtro de pedidos importados | `src/services/ordem/getOrdensAll.js` (hoje: `paid` + payment `approved`) |
| Dados fiscais do comprador | `src/services/ordem/getDadosFaturamento.js` |
| Endereço de entrega | `src/services/ordem/getEndereco.js` (API `/shipments/{id}`) |
| SKU/GTIN de produtos | `src/services/produto/produtos.js` (`SELLER_SKU`, `GTIN` nos attributes) |
| Sync perguntas ML | `src/services/pergunta/perguntas.js` — requer permissão DevCenter *Comunicação pré e pós-venda* |
| Listagem paginada de perguntas | `src/services/pergunta/getPerguntasAll.js` |
| Detalhe da pergunta + comprador | `src/services/pergunta/getPergunta.js` |
| DDL/pergunta no Oracle | `src/oracle/merc_livre_pergunta.tab` + `prc_mlapi_pergunta_update.prc` |
| Sync pagamento/repasse ML | `src/services/ordem/ordemPagto.js` — ordens com repasse em aberto |
| API de repasse por pedido | `src/services/ordem/getOrdemPagto.js` (`GET /billing/integration/group/ML/order/details`) |
| Ordens elegíveis para repasse | `src/repositories/ordemRepository.js` → `getOrdensPagtoAberto()` (SELECT direto) |
| Persistência repasse ML | `src/repositories/ordemPagtoRepository.js` → `PRC_MLAPI_ML_PAGTO` |
| DDL/procedure repasse | `src/oracle/merc_livre_ordem.tab` (colunas `MLOR_PAGTO_ML_*`) + `prc_mlapi_ml_pagto.prc` |

---

## Domínio: Perguntas ao vendedor (jun/2026)

Sincronização **pré-venda** — perguntas públicas feitas nos anúncios. **Não** confundir com mensagens pós-venda (`/messages/*`), que ainda não estão implementadas.

### Pré-requisitos

1. **DevCenter:** permissão funcional *Comunicação pré e pós-venda* (libera `questions`, `messages`, `claims`, `returns`). Sem ela → HTTP 403 `PA_UNAUTHORIZED_RESULT_FROM_POLICIES`.
2. **OAuth:** vendedor deve reautorizar o app após habilitar a permissão.
3. **Oracle:** executar scripts antes do primeiro job:
   ```sql
   @src/oracle/merc_livre_pergunta.tab
   @src/oracle/prc_mlapi_pergunta_update.prc
   ```
   Ajustar schema `DESENV` se o ambiente usar outro.

### Endpoints ML consumidos

| Arquivo | Endpoint |
|---------|----------|
| `getPerguntasAll.js` | `GET /my/received_questions/search?api_version=4` (paginação `limit`/`offset`) |
| `getPergunta.js` | `GET /questions/{id}?api_version=4` (e-mail, telefone e nome do comprador) |

Sempre usar `api_version=4`. Status ML: `UNANSWERED`, `ANSWERED`, `BANNED`, `CLOSED_UNANSWERED`, `DELETED`, `DISABLED`, `UNDER_REVIEW`.

### Fluxo (`perguntas.js`)

1. `getPerguntasAll()` — lista todas as perguntas recebidas (paginado, 50 por página).
2. Para cada pergunta → `getPergunta(id)` — detalhe com dados do comprador.
3. `extrairDadosComprador(from)` — mapeia `first_name`/`last_name`/`nickname`, `email`, `phone`.
4. `perguntaRepository.perguntaUpdate()` → `PRC_MLAPI_PERGUNTA_UPDATE`.

Erro em uma pergunta não interrompe o lote (`try/catch` + `logger.logError`).

### Notificações (webhooks) vs polling

O Horus **não expõe HTTP** — webhooks do ML (tópicos `questions` / `messages`) **não estão implementados**. Perguntas usam **polling** periódico, alinhado aos demais domínios. Detalhes em `MercadoLivre-API.md` seções 5 e 10.

---

## Domínio: Pagamento / repasse ML (jun/2026)

Sincronização do **repasse ao vendedor** (liberação de valores) para pedidos já importados no Horus. Complementa o módulo de pedidos — não substitui a importação de ordens em `ordens.js`.

### Pré-requisitos

1. Pedido já gravado em `MERC_LIVRE_ORDEM` via `ordensSave`.
2. Colunas de repasse existentes na tabela (`MLOR_PAGTO_ML_DATA`, `MLOR_PAGTO_ML_STATUS`, `MLOR_PAGTO_ML_VLR`, `MLOR_PAGTO_ML_DT_PROC`) — ver `src/oracle/merc_livre_ordem.tab`.
3. Procedure `PRC_MLAPI_ML_PAGTO` aplicada no banco (`src/oracle/prc_mlapi_ml_pagto.prc`).

### Endpoints ML consumidos

| Arquivo | Endpoint |
|---------|----------|
| `getOrdemPagto.js` | `GET /billing/integration/group/ML/order/details?order_ids={id}` |

### Fluxo (`ordemPagto.js`)

1. `getOrdensPagtoAberto()` — SELECT em `MERC_LIVRE_ORDEM` com `STATUS = 'Ativo'` e `MLOR_PAGTO_ML_STATUS` nulo ou `'Aberto'`.
2. Para cada `MLOR_ORDER_ID` → `getOrdemPagto(id)` — consulta API de faturamento/repasse.
3. `mapearPagtoMl()` — deriva `pagto_ml_data`, `pagto_ml_status` (`Quitado` / `Aberto`) e `pagto_ml_vlr`.
4. `ordemPagtoRepository.ordemPagtoUpdate()` → `PRC_MLAPI_ML_PAGTO`.

Erro em uma ordem não interrompe o lote (`try/catch` + `logger.logError`). Falha na API ML retorna objeto vazio (status `Aberto`, valor `0`) e o loop continua.

### Cálculo do valor repassado (`getOrdemPagto.js`)

Quando `payment_info[0].money_release_status === 'released'`:

- Base: maior `transaction_amount` em `details[].sales_info`.
- Desconta cobranças com `charge_info.debited_from_operation === 'YES'`.
- Desconta retenções em `tax_details` (`original_amount - refunded_amount`).
- Resultado arredondado em 2 casas, mínimo `0`.

### Campos Oracle (`MERC_LIVRE_ORDEM`)

| Coluna Oracle | Origem |
|---------------|--------|
| `MLOR_PAGTO_ML_DATA` | `payment_info[0].money_release_date` (quando quitado) |
| `MLOR_PAGTO_ML_STATUS` | `Quitado` ou `Aberto` |
| `MLOR_PAGTO_ML_VLR` | Valor líquido calculado |
| `MLOR_PAGTO_ML_DT_PROC` | `SYSDATE` na procedure |

### Leitura direta no Oracle (exceção)

`getOrdensPagtoAberto()` em `ordemRepository.js` faz **SELECT direto** (não usa procedure). Padrão aceito para **consultas**; gravação continua via `PRC_MLAPI_ML_PAGTO`.

---

## Objetos Oracle — contrato Node ↔ Horus

### Tabelas principais (schema `HORUS`)

- `MERC_LIVRE_CONFIG` — OAuth
- `MERC_LIVRE_PRODUTO` — anúncios
- `MERC_LIVRE_ORDEM` — cabeçalho pedido (inclui colunas de repasse `MLOR_PAGTO_ML_*`)
- `MERC_LIVRE_ORDEM_ITEM` — itens
- `MERC_LIVRE_ORDEM_END` — endereço entrega
- `MERC_LIVRE_CATEGORIA` — categorias MLB
- `MERC_LIVRE_TP_ANUNCIO` — tipos de listagem
- `MERC_LIVRE_PERGUNTA` — perguntas recebidas nos anúncios (prefixo colunas `MLQT_`)

### Tabela `MERC_LIVRE_PERGUNTA` — campos principais

| Coluna Oracle | Origem API ML |
|---------------|---------------|
| `MLQT_QUESTION_ID` | `id` (UK) |
| `MLQT_ITEM_ID` | `item_id` |
| `MLQT_SELLER_ID` | `seller_id` |
| `MLQT_STATUS` | `status` |
| `MLQT_TEXT` | `text` |
| `MLQT_DATE_CREATED` | `date_created` |
| `MLQT_FROM_USER_ID` | `from.id` |
| `MLQT_ANSWER_TEXT` | `answer.text` |
| `MLQT_ANSWER_STATUS` | `answer.status` |
| `MLQT_ANSWER_DATE` | `answer.date_created` |
| `MLQT_BUYER_NOME` | `from.first_name` / `last_name` / `nickname` |
| `MLQT_BUYER_EMAIL` | `from.email` |
| `MLQT_BUYER_PHONE` | `from.phone` |
| `MLQT_HOLD` | `hold` (`S`/`N`) |
| `MLQT_DELETED_LISTING` | `deleted_from_listing` (`S`/`N`) |
| `UNIDADE_EMPRESARIAL_ID` | `.env` → `UNIDADE_EMPRESARIAL_ID` |

Scripts: `src/oracle/merc_livre_pergunta.tab`, `src/oracle/prc_mlapi_pergunta_update.prc`.

### Procedures chamadas pelo Node

| Procedure | Repository |
|-----------|------------|
| `PRC_MLAPI_TOKEN_UPDATE` | `configRepository.js` |
| `PRC_MLAPI_PRODUTO_UPDATE` | `produtoRepository.js` |
| `PRC_MLAPI_ORDEM_UPDATE` | `ordemRepository.js` |
| `PRC_MLAPI_ORDEM_ITEM_UPDATE` | `ordemItemRepository.js` |
| `PRC_MLAPI_ORDEM_END_UPDATE` | `ordemEndRepository.js` |
| `PRC_MLAPI_ML_PAGTO` | `ordemPagtoRepository.js` |
| `PRC_MLAPI_PERGUNTA_UPDATE` | `perguntaRepository.js` |
| `PRC_MLAPI_CATEGORIA_UPDATE` | `categoriaRepository.js` |
| `PRC_MLAPI_TP_ANUNCIO_UPDATE` | `tpAnuncioRepository.js` |

### Consultas diretas no Node (somente leitura)

| Função | Arquivo | Objeto |
|--------|---------|--------|
| `configFind` | `configRepository.js` | `VIEW_MERC_LIVRE_CONFIG` |
| `getOrdensPagtoAberto` | `ordemRepository.js` | `MERC_LIVRE_ORDEM` |

### Procedures Oracle **não** integradas ao Node

Scripts em `src/oracle/` sem chamada nos repositories atuais:

| Script | Observação |
|--------|------------|
| `prc_mlapi_config.prc` | Configuração — não usado pelo worker |
| `prc_mlapi_produto.prc` | Variante legada de produto |
| `prc_mlapi_cliente.prc`, `prc_mlapi_cliente_insert.prc` | Cliente Horus |
| `prc_mlapi_endereco_insert.prc` | Endereço |
| `prc_mlapi_pdsd_insert.prc`, `prc_mlapi_pdsd_exec.prc` | Pedido de saída (PDSD) |

Scripts adicionais referem schema `DESENV` (`MERC_LIVRE_PRDT`, `MERC_LIVRE_PRDT_IMAGEM`) — possível evolução futura, **não integrados** ao fluxo Node atual.

**Regra:** regras de negócio pesadas (gerar ID, validar duplicidade, commit) ficam nas **procedures**, não no Node.

---

## API Mercado Livre — base URL e auth

- Base: `https://api.mercadolibre.com`
- Auth: `Authorization: Bearer {MLCN_ACCESS_TOKEN}`
- OAuth: `POST https://api.mercadolibre.com/oauth/token`
- Site fixo: **MLB** (Brasil) em categorias e listing_types

Endpoints adicionais (perguntas):

- `GET /my/received_questions/search?api_version=4` — listagem paginada
- `GET /questions/{id}?api_version=4` — detalhe + dados do comprador

Endpoints adicionais (repasse ML):

- `GET /billing/integration/group/ML/order/details?order_ids={id}` — detalhes de liberação de valores

Documentação oficial: https://developers.mercadolivre.com.br/  
Perguntas: https://developers.mercadolivre.com.br/pt_br/variacoes/perguntas-e-respostas

---

## Como executar localmente

```bash
npm install
npm start
# ou: node src/app.js
```

Oracle local opcional: `docker compose up -d` (Oracle XE 21, porta 1521).

---

## Pontos de atenção / débitos técnicos conhecidos

1. **`findToken.js`** — `code_verifier` está como literal `'$CODE_VERIFIER'` (placeholder); fluxo OAuth inicial pode precisar de ajuste para PKCE real.
2. **`ordens.js`** — itens do pedido gravam `sku: '0'` e `gtin: '0'` fixos (não extrai do produto; SKU/GTIN **são** extraídos em `produtos.js`).
3. **Crons desabilitados** — todos os `cron.schedule` em `execJobs.js` estão comentados; sincronização periódica só ocorre se o processo for reiniciado ou os crons forem reativados.
4. **`PRC_MLAPI_ML_PAGTO`** — lógica invertida no script `prc_mlapi_ml_pagto.prc`: quando a ordem **é** encontrada, dispara `ORA-20000` com mensagem "Ordem não encontrada"; quando **não** encontra, tenta `UPDATE` com ID nulo. **Corrigir no Oracle** antes de usar repasse em produção.
5. **`ordemPagtoSave`** — sem cron definido (nem comentado); roda apenas na subida via `Iniciar()`.
6. **Sem testes** — validar manualmente contra API ML e banco Horus.
7. **Conexão por operação** — cada repository abre/fecha conexão; não há pool compartilhado.
8. **OAuth `MLCN_CODE`** — após primeira troca, o code expira; tentativa de `findToken` gera `invalid_grant` (ruído no log) se o code antigo permanecer no banco; o refresh costuma resolver.
9. **Arquivos locais não versionados** — `.env`, `logs/`, `node_modules/`.
10. **`README.md`** — parcialmente desatualizado em relação ao código (falta `ordemPagto`, `ORACLE_CLIENT_LIB_DIR`, estado dos crons).

### Tratamento de erros (comportamento atual)

| Camada | Comportamento |
|--------|---------------|
| `execJobs.js` | `try/catch` por job; falha de um job não interrompe os demais na mesma execução |
| `ordens.js` | `try/catch` por ordem (API + Oracle); log + continua próxima ordem |
| `produtos.js` | `try/catch` por produto; log + continua próximo item |
| `perguntas.js` | `try/catch` por pergunta; log + continua próxima pergunta |
| `ordemPagto.js` | `try/catch` por ordem; log + continua próxima ordem |
| `getOrdemPagto.js` | Falha API → retorna status `Aberto` e valor `0` |
| `getDadosFaturamento.js` | Falha API → retorna `{}` e continua |
| `getEndereco.js` | Falha API → retorna `{}` e continua |
| `getToken.js` | Falha OAuth → relança erro; `getTokenConfig()` valida antes do uso |

---

## Checklist para adicionar nova entidade sincronizada

1. Criar/alterar tabela em `src/oracle/*.tab`
2. Criar procedure `PRC_MLAPI_{ENTIDADE}_UPDATE` em `src/oracle/`
3. Criar `repositories/{entidade}Repository.js` seguindo padrão existente
4. Criar `services/{entidade}/get{Entidade}.js` (API via `mlApi`) e `{entidade}s.js` (orquestrador)
5. Registrar job em `execJobs.js` (função + cron + chamada em `Iniciar()`)
6. Adicionar logs JSON no repository (`logJsonEnv` / `logJsonRec`) se persistir dados
7. Atualizar `README.md`, `ARQUITETURA.md` e este `CONTEXTO-IA.md`

---

## Checklist para alterar campo existente

1. Coluna na tabela Oracle (`.tab` ou migration manual no Horus)
2. Parâmetro na procedure `PRC_MLAPI_*`
3. Bind no `repository` correspondente
4. Mapeamento no service (transformação API → objeto)
5. Origem do dado na API ML (verificar endpoint/resposta)

---

## Git e arquivos sensíveis

**Não commitar:**
- `.env`
- `logs/` (exec, error, json)
- Credenciais Oracle/ML

**Arquivos auxiliares no repo:**
- `docker-compose.yml` — Oracle XE dev (senha exemplo no compose)
- `info.md` — notas auxiliares
- `bkp.js` — backup/utilitário na raiz (verificar antes de usar)

Commits e PRs: só quando o usuário pedir explicitamente.

---

## Evoluções prováveis (contexto para planejamento)

Áreas comuns de continuidade que **ainda não existem** ou estão **incompletas** no código:

- Webhooks/notifications ML — **perguntas via polling**; mensagens pós-venda ainda não implementadas (ver `MercadoLivre-API.md` seções 5 e 10)
- Exportação Horus → ML (publicar/atualizar anúncios)
- Suporte a múltiplas unidades empresariais
- Integração `MERC_LIVRE_PRDT` / imagens (`DESENV`)
- Integração PDSD (`prc_mlapi_pdsd_*`) — procedures existem, Node não chama
- Pool de conexões Oracle
- Testes de integração mockados
- Parametrizar site MLB via `.env` (hoje fixo em código)
- Corrigir SKU/GTIN nos itens de pedido (`ordens.js`)
- Corrigir lógica de `PRC_MLAPI_ML_PAGTO` no Oracle
- Reativar crons em `execJobs.js` para sync periódica contínua
- Limpar `MLCN_CODE` após troca OAuth bem-sucedida (evitar ruído `invalid_grant`)

---

## Histórico de contexto da sessão

Documentação criada/atualizada para o projeto Avvante/Horus:
- `README.md` — guia geral
- `ARQUITETURA.md` — diagramas e camadas
- `CONTEXTO-IA.md` — este guia de continuidade
- `OAUTH-TOKEN.md`, `MercadoLivre-API.md` — referência API ML

### Alterações jun/2026 — infraestrutura

- Logs estruturados (`logs/exec`, `logs/error`, `logs/json`)
- `mlApi` / `getTokenConfig` — cliente HTTP centralizado
- Tratamento de erros por ordem/produto (`try/catch` isolado)
- `ORACLE_CLIENT_LIB_DIR` no `.env`

### Alterações jun/2026 — sync de perguntas ao vendedor

**Código Node:**

| Arquivo | Função |
|---------|--------|
| `src/services/pergunta/getPerguntasAll.js` | Listagem paginada via API ML |
| `src/services/pergunta/getPergunta.js` | Detalhe com `api_version=4` |
| `src/services/pergunta/perguntas.js` | Orquestrador batch |
| `src/repositories/perguntaRepository.js` | Chama `PRC_MLAPI_PERGUNTA_UPDATE` |
| `src/jobs/execJobs.js` | Job `perguntasSave` em `Iniciar()`; cron planejado `*/5 * * * *` (comentado) |

**Oracle (aplicar manualmente no banco):**

| Script | Objeto |
|--------|--------|
| `src/oracle/merc_livre_pergunta.tab` | Tabela `MERC_LIVRE_PERGUNTA` |
| `src/oracle/prc_mlapi_pergunta_update.prc` | Procedure insert/update |

**Fora de escopo desta entrega:** mensagens pós-venda (`/messages/*`), webhooks HTTP, view `VIEW_MERC_LIVRE_PERGUNTA`.

### Alterações jun/2026 — sync de pagamento/repasse ML

**Código Node:**

| Arquivo | Função |
|---------|--------|
| `src/services/ordem/getOrdemPagto.js` | API billing + cálculo valor repassado |
| `src/services/ordem/ordemPagto.js` | Orquestrador batch |
| `src/repositories/ordemPagtoRepository.js` | Chama `PRC_MLAPI_ML_PAGTO` |
| `src/repositories/ordemRepository.js` | `getOrdensPagtoAberto()` — SELECT de ordens elegíveis |
| `src/jobs/execJobs.js` | Job `ordemPagtoSave` em `Iniciar()`; **sem cron** |

**Oracle (aplicar manualmente no banco):**

| Script | Objeto |
|--------|--------|
| `src/oracle/merc_livre_ordem.tab` | Colunas `MLOR_PAGTO_ML_*` |
| `src/oracle/prc_mlapi_ml_pagto.prc` | Procedure update repasse (**revisar lógica antes de produção**) |

**Documentação atualizada:** `MercadoLivre-API.md` (seções 2, 4, 5, 8, 10), `ARQUITETURA.md`, `README.md` (parcialmente pendente).

Última atualização deste arquivo: 22/jun/2026.

---

## Prompt sugerido para retomar trabalho

Ao iniciar nova sessão, o usuário (ou o agente) pode usar:

> Leia `CONTEXTO-IA.md`, `README.md` e `ARQUITETURA.md` deste repositório e continue o desenvolvimento da integração Horus ↔ Mercado Livre.
