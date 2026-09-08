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
- Envio batch Horus → ML da **NF-e de venda** e da **fila de anúncios** (`VIEW_MLAPI_ANUNCIO`)
- Processo de longa duração com `node-cron`
- Ponte entre axios (API REST) e oracledb (procedures PL/SQL)

**Não é:**
- API REST própria (sem Express/Fastify)
- Frontend
- Exportação completa Horus → ML (anúncios: publicar/atualizar/pausar/ativar/encerrar/excluir já no worker; atributos extras da ficha técnica por categoria ainda não)
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
| `PUBLICACAO-ANUNCIOS.md` | Campos e fluxo para **enviar** anúncios Horus → ML |
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
| `dotenv` | `.env` (DB + unidade + Oracle Client + `ORDEM_DIAS` + `PERGUNTAS_DIAS`) |
| `qs` | Body OAuth (`application/x-www-form-urlencoded`) |
| `winston` | Declarado no `package.json`; **logging efetivo** via `utils/logger.js`, `execLogger.js` e `jsonLogger.js` |
| `form-data` | Upload multipart das fotos (`POST /pictures/items/upload`) |

---

## Variáveis de ambiente (`.env`)

Arquivo **não versionado** (`.gitignore`). Nunca commitar.

```env
DB_USER=
DB_PASSWORD=
DB_CONNECT=host:1521/servico
UNIDADE_EMPRESARIAL_ID=
ORDEM_DIAS=90
PERGUNTAS_DIAS=30
ORACLE_CLIENT_LIB_DIR=C:\caminho\para\oracle\instant\client
```

| Variável | Uso |
|----------|-----|
| `DB_*` | Conexão Oracle |
| `UNIDADE_EMPRESARIAL_ID` | Unidade/loja no Horus (uma por instância) |
| `ORDEM_DIAS` | Dias retroativos na busca de pedidos (`getOrdensAll.js`) — obrigatório, inteiro positivo (ex.: `90`) |
| `PERGUNTAS_DIAS` | Dias retroativos na busca de perguntas (`getPerguntasAll.js`) — obrigatório, inteiro positivo (ex.: `30`) |
| `ORACLE_CLIENT_LIB_DIR` | Caminho do Oracle Instant Client (modo Thick) |

`ORDEM_DIAS` alimenta `order.date_created.from` / `order.date_created.to` em `GET /orders/search`. A API ML só mantém pedidos por ~12 meses; valores maiores que isso não recuperam histórico além desse limite.

`PERGUNTAS_DIAS` filtra perguntas por `date_created` (a API `/my/received_questions/search` **não** aceita filtro de data na query — ordena `date_created DESC` e corta localmente pela janela).

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

**Limpeza manual (Windows):** `limparlog.bat` na raiz do repositório apaga todos os arquivos em `logs/` e subpastas (`error`, `exec`, `json/...`), mantendo a estrutura de pastas. Usa `%~dp0` para apontar sempre à pasta do projeto.

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
| `ordemNfeSave` | (não definido) | **sem cron** | `services/ordem/ordemNfe.js` |
| `perguntasSave` | `*/5 * * * *` | **comentado** | `services/pergunta/perguntas.js` |
| `anunciosSave` | `*/5 * * * *` | **comentado** | `services/anuncio/anuncios.js` |

**Estado atual:** na subida, `Iniciar()` executa **todos** os jobs **uma vez** em sequência (`token → tpAnuncio → categoria → anuncio → produto → ordem → ordemPagto → ordemNfe → pergunta`). Os `cron.schedule` estão **todos comentados** — o processo fica ocioso após a primeira rodada até ser reiniciado ou até alguém descomentar os crons.

Para novo job: criar função async + `cron.schedule` + exportar lógica no service correspondente + incluir chamada em `Iniciar()`.

### Inventário atual (`src/`)

```
services/
  token/       getToken.js, findToken.js, refreshToken.js
  tpAnuncio/   tpAnuncios.js, getTpAnuncios.js
  categoria/   categorias.js, getCategorias.js
  produto/     produtos.js, getProdutosAll.js, getProduto.js
  ordem/       ordens.js, ordemPagto.js, ordemNfe.js, getOrdensAll.js, getOrdem.js,
               getDadosFaturamento.js, getEndereco.js, getOrdemPagto.js, postNfeXml.js
  pergunta/    perguntas.js, getPerguntasAll.js, getPergunta.js
  anuncio/     anuncios.js, montarPayload.js, getVendedor.js, postAnuncio.js,
               putAnuncio.js, postDescricao.js, postImagem.js

repositories/
  configRepository.js, produtoRepository.js, ordemRepository.js,
  ordemItemRepository.js, ordemEndRepository.js, ordemPagtoRepository.js,
  ordemNfeRepository.js, perguntaRepository.js, categoriaRepository.js,
  tpAnuncioRepository.js, anuncioRepository.js

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
| Filtro / janela de pedidos importados | `src/services/ordem/getOrdensAll.js` + `.env` `ORDEM_DIAS` (`paid` + payment `approved` + data + paginação) |
| Limpar arquivos de log | `limparlog.bat` (raiz) → apaga conteúdo de `logs/` e subpastas |
| Dados fiscais do comprador | `src/services/ordem/getDadosFaturamento.js` |
| Endereço de entrega | `src/services/ordem/getEndereco.js` (API `/shipments/{id}`) |
| SKU/GTIN de produtos | `src/services/produto/produtos.js` (`SELLER_SKU`, `GTIN` nos attributes) |
| Paginação de anúncios importados | `src/services/produto/getProdutosAll.js` (`limit`/`offset`; `search_type=scan` se `paging.total` > 1000) |
| Sync perguntas ML | `src/services/pergunta/perguntas.js` — requer permissão DevCenter *Comunicação pré e pós-venda* |
| Listagem paginada de perguntas | `src/services/pergunta/getPerguntasAll.js` + `.env` `PERGUNTAS_DIAS` (janela + `date_created DESC`) |
| Detalhe da pergunta + comprador | `src/services/pergunta/getPergunta.js` |
| DDL/pergunta no Oracle | `src/oracle/merc_livre_pergunta.tab` + `prc_mlapi_pergunta_update.prc` |
| Sync pagamento/repasse ML | `src/services/ordem/ordemPagto.js` — ordens com repasse em aberto |
| API de repasse por pedido | `src/services/ordem/getOrdemPagto.js` (`GET .../order/details`, até 60 `order_ids`/request) |
| Ordens elegíveis para repasse | `src/repositories/ordemRepository.js` → `getOrdensPagtoAberto()` (SELECT direto) |
| Persistência repasse ML | `src/repositories/ordemPagtoRepository.js` → `PRC_MLAPI_ML_PAGTO` |
| DDL/procedure repasse | `src/oracle/merc_livre_ordem.tab` (colunas `MLOR_PAGTO_ML_*`) + `prc_mlapi_ml_pagto.prc` |
| Envio NF-e ML (Horus → ML) | `src/services/ordem/ordemNfe.js` — pedidos faturados com XML pendente |
| POST XML NF-e na API ML | `src/services/ordem/postNfeXml.js` (`POST /shipments/{id}/invoice_data?siteId=MLB`) |
| Ordens elegíveis para envio NF-e | `src/repositories/ordemNfeRepository.js` → `getOrdensNfePendente()` (`VIEW_MLOR_NFE`) |
| Registro data envio NF-e | `src/repositories/ordemNfeRepository.js` → `PRC_MLAPI_NFE_XML_ENVIO` |
| DDL/procedure NF-e | `src/oracle/merc_livre_ordem.tab` (coluna `MLOR_XML_DT_ENVIO`) + `prc_mlapi_nfe_xml_envio.prc` + `view_mlor_nfe.sql` |
| Fila de publicação de anúncios | `MERC_LIVRE_ANUNCIO` (`src/oracle/merc_livre_anuncio.tab`) — o anúncio |
| Embalagens no anúncio | `MERC_LIVRE_ANUNCIO_EV` (`src/oracle/MERC_LIVRE_ANUNCIO_EV.tab`) — amarração `EMBALAGEM_VENDA` |
| Fotos do anúncio (via produto) | `VIEW_MLAPI_ANUNCIO_IMAGEM` (`src/oracle/view_mlapi_anuncio_imagem.sql`) |
| Payload de publicação (view) | `VIEW_MLAPI_ANUNCIO` (`src/oracle/view_mlapi_anuncio.sql`) |
| Guia API de publicação | `.cursor/docs/PUBLICACAO-ANUNCIOS.md` |
| Envio de anúncios Horus → ML | `src/services/anuncio/anuncios.js` — job `anunciosSave` |
| Payload do anúncio | `src/services/anuncio/montarPayload.js` |
| Upload de fotos (LONG RAW) | `src/services/anuncio/postImagem.js` + `getAnuncioImagens()` |
| Gravação retorno ML | `anuncioRepository.anuncioEnvioUpdate()` → `PRC_MLAPI_AUNCIOS_ENV` |

---

## Domínio: Pedidos / ordens (jul/2026)

Importação **ML → Horus** de vendas pagas. Orquestrador: `ordens.js` → `getOrdensAll` → detalhe/faturamento/endereço → procedures `PRC_MLAPI_ORDEM_*`.

### Filtros e paginação (`getOrdensAll.js`)

| Critério | Onde | Detalhe |
|----------|------|---------|
| Status pedido | Query API | `order.status=paid` |
| Pagamento aprovado | Filtro local | algum `payments[].status === 'approved'` |
| Janela de datas | Query API + `.env` | `order.date_created.from/to` com base em `ORDEM_DIAS` |
| Paginação | Query API | `limit=50` + `offset` até `paging.total` |
| Ordenação | Query API | `sort=date_desc` |

### Limitações da API ML (doc oficial)

- `/orders/search` **exige filtro** além de `seller` (sem filtro não retorna pedidos).
- Pedidos disponíveis por **até ~12 meses**.
- Na busca como vendedor, pedidos **cancelados** são filtrados pela API.
- Canceladas / outros status (`confirmed`, `payment_in_process`, etc.) **não** entram no sync atual do Horus.

### Fluxo (`ordens.js`)

1. `getOrdensAll()` — IDs elegíveis na janela `ORDEM_DIAS` (paginado).
2. Para cada ID → `getOrdem` + `getDadosFaturamento` + `getEndereco`.
3. Persistência: `ordemUpdate` / `ordemEndUpdate` / `ordemItemUpdate`.

Erro em uma ordem não interrompe o lote (`try/catch` + `logger.logError`).

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
| `getPerguntasAll.js` | `GET /my/received_questions/search?api_version=4` (paginação `limit`/`offset`; `sort_fields=date_created` + `sort_types=DESC`; janela `PERGUNTAS_DIAS` filtrada localmente) |
| `getPergunta.js` | `GET /questions/{id}?api_version=4` (e-mail, telefone e nome do comprador) |

Sempre usar `api_version=4`. Status ML: `UNANSWERED`, `ANSWERED`, `BANNED`, `CLOSED_UNANSWERED`, `DELETED`, `DISABLED`, `UNDER_REVIEW`.

### Janela de datas (`PERGUNTAS_DIAS`)

A API de perguntas recebidas **não** expõe filtro `date_from`/`date_to` (filtros: `item`, `from`, `status`, etc.). O Horus:

1. Lê `PERGUNTAS_DIAS` do `.env` (obrigatório, inteiro positivo).
2. Ordena por `date_created DESC`.
3. Inclui só perguntas com `date_created` dentro da janela.
4. Interrompe a paginação ao encontrar a primeira pergunta mais antiga que o limite (demais páginas estariam fora da janela).

### Fluxo (`perguntas.js`)

1. `getPerguntasAll()` — lista perguntas recebidas na janela `PERGUNTAS_DIAS` (paginado, 50 por página).
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
| `getOrdemPagto.js` | `GET /billing/integration/group/ML/order/details?order_ids={id1,id2,...}` (até **60** IDs/request) |

### Fluxo (`ordemPagto.js`)

1. `getOrdensPagtoAberto()` — SELECT em `MERC_LIVRE_ORDEM` com `STATUS = 'Ativo'` e `MLOR_PAGTO_ML_STATUS` nulo ou `'Aberto'`.
2. Agrupa IDs em lotes de até **60** → `getOrdensPagto(lote)` — uma chamada API por lote.
3. Para cada ordem do lote → `mapearPagtoMl()` + `ordemPagtoUpdate()` → `PRC_MLAPI_ML_PAGTO`.

Erro em uma ordem (gravação) não interrompe o lote. Falha na API ML do lote deixa as ordens como `Aberto` / valor `0`.

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

## Domínio: Envio NF-e ML (jun/2026)

Envio do **XML autorizado da NF-e** (modelo 55) emitida no Horus para o Mercado Livre, destravando o substatus `invoice_pending` e permitindo geração da etiqueta de envio. Fluxo **Horus → ML** (direção oposta à importação de pedidos).

### Pré-requisitos

1. Pedido faturado no Horus vinculado a `MERC_LIVRE_ORDEM` (`PEDIDO_SAIDA_ID` preenchido via fluxo PDSD).
2. NF-e com status SEFAZ `Aceito` disponível em `NFE_ENVIO` / view `VIEW_MLOR_NFE`.
3. Coluna `MLOR_XML_DT_ENVIO` em `MERC_LIVRE_ORDEM` — ver `src/oracle/merc_livre_ordem.tab`.
4. Scripts Oracle aplicados:
   ```sql
   ALTER TABLE MERC_LIVRE_ORDEM ADD MLOR_XML_DT_ENVIO DATE;  -- se ainda não existir
   @src/oracle/prc_mlapi_nfe_xml_envio.prc
   @src/oracle/view_mlor_nfe.sql
   ```
5. Seller **PJ contribuinte** — fluxo de importação de NF-e via API (não DC-e).

### View `VIEW_MLOR_NFE`

Relaciona pedido ML faturado (`PEDIDO_SAIDA` → `PEDIDO_FATURADO` → `MOVIMENTO_ESTOQUE` → `NFE_ENVIO`) com `MERC_LIVRE_ORDEM`.

| Coluna view | Origem | Uso |
|-------------|--------|-----|
| `MLOR_ORDER_ID` | `MERC_LIVRE_ORDEM` | ID do pedido ML |
| `NFE_CHAVE` | `NFE_ENVIO.NFEE_CHAVE` | Chave de acesso (44 dígitos) |
| `NFE` | `MOVIMENTO_ESTOQUE.MOVI_NR_NOTA_FISCAL` | Número da NF-e |
| `SR` | `MOVIMENTO_ESTOQUE.MOVI_SR_NOTA_FISCAL` | Série |
| `NFE_XML` | `NFE_ENVIO.NFEE_3_JSON_PROCESSADO` | XML completo enviado à API ML |
| `MLOR_XML_DT_ENVIO` | `MERC_LIVRE_ORDEM` | `null` = pendente de envio |

Script: `src/oracle/view_mlor_nfe.sql`.

### Endpoints ML consumidos

| Arquivo | Endpoint |
|---------|----------|
| `getOrdem.js` | `GET /orders/{id}` — obtém `shipping.id` (shipment) |
| `postNfeXml.js` | `POST /shipments/{shipment_id}/invoice_data/?siteId=MLB` — body: XML (`Content-Type: application/xml`) |

Doc ML: [Importar Nota Fiscal](https://developers.mercadolivre.com.br/pt_br/importar-nota-fiscal).

**Importante:** a API ML **não aceita** apenas número/chave da NF-e — exige o **XML completo** (`nfeProc`). Notas de homologação SEFAZ são rejeitadas.

### Fluxo (`ordemNfe.js`)

1. `getOrdensNfePendente()` — SELECT em `VIEW_MLOR_NFE` com `MLOR_XML_DT_ENVIO is null` e `UNIDADE_EMPRESARIAL_ID` do `.env`.
2. Para cada ordem → `getOrdem(MLOR_ORDER_ID)` — obtém `shipping.id`.
3. `postNfeXml(shipmentId, nfe_xml)` — envia XML à API ML.
4. `ordemNfeXmlEnvioUpdate()` → `PRC_MLAPI_NFE_XML_ENVIO` — grava `MLOR_XML_DT_ENVIO = SYSDATE`.

Erro em uma ordem não interrompe o lote (`try/catch` + `logger.logError`). Em falha, **não** atualiza `MLOR_XML_DT_ENVIO` (permite reprocessamento).

### Campos Oracle (`MERC_LIVRE_ORDEM`)

| Coluna Oracle | Origem |
|---------------|--------|
| `MLOR_XML_DT_ENVIO` | `SYSDATE` na procedure após envio bem-sucedido à API ML |

### Leitura direta no Oracle (exceção)

`getOrdensNfePendente()` em `ordemNfeRepository.js` faz **SELECT direto** na view (CLOB `NFE_XML` lido como string via `fetchInfo`). Gravação continua via `PRC_MLAPI_NFE_XML_ENVIO`.

---

## Domínio: Publicação de anúncios (modelo de dados Horus)

Cadastro no ERP para **enviar** anúncios ao ML (Horus → ML). Job `anunciosSave` → `anuncios.anunciosEnviar()`. API e payload: [PUBLICACAO-ANUNCIOS.md](PUBLICACAO-ANUNCIOS.md).

Não confundir com `MERC_LIVRE_PRODUTO`, que é o **espelho do GET /items** (pull). A fila de envio é `MERC_LIVRE_ANUNCIO` + `MERC_LIVRE_ANUNCIO_EV`.

### Relacionamento

O anúncio nasce em `MERC_LIVRE_ANUNCIO`. As **embalagens de venda** que entram nesse anúncio são amarradas em `MERC_LIVRE_ANUNCIO_EV`. A embalagem de venda já está ligada ao **produto** no Horus (`EMBALAGEM_VENDA.PRODUTO_ID` → `PRODUTO`).

```
PRODUTO (1) ──< (N) EMBALAGEM_VENDA
                         ▲
                         │ EMBALAGEM_VENDA_ID
MERC_LIVRE_ANUNCIO (1) ──< (N) MERC_LIVRE_ANUNCIO_EV
```

| Fato | Detalhe |
|------|---------|
| Cabeçalho do anúncio | Uma linha em `MERC_LIVRE_ANUNCIO` (título, preço, categoria ML, tipo, SKU/GTIN do anúncio, dimensões do pacote, ação) |
| Composição | 1 anúncio → **N** linhas em `MERC_LIVRE_ANUNCIO_EV` (kit / várias embalagens no mesmo item ML) |
| Ligação com o cadastro | `MERC_LIVRE_ANUNCIO_EV.EMBALAGEM_VENDA_ID` → `EMBALAGEM_VENDA` → `PRODUTO` |
| Quantidade e valor por embalagem | `MLAE_QTDE`, `MLAE_VALOR` na EV (não na capa) |
| Fotos | Vêm do **produto** das embalagens amarradas, não de tabela própria de imagem do anúncio |

A embalagem **não** fica na capa (`MERC_LIVRE_ANUNCIO` não tem `EMBALAGEM_VENDA_ID`). O vínculo é só em `MERC_LIVRE_ANUNCIO_EV`.

### Tabela `MERC_LIVRE_ANUNCIO` (prefixo `MLAN_`)

Script: `src/oracle/merc_livre_anuncio.tab`.

| Coluna | Uso |
|--------|-----|
| `MERC_LIVRE_ANUNCIO_ID` | PK Horus |
| `UNIDADE_EMPRESARIAL_ID` | Unidade/loja |
| `MLAN_ID` | `item_id` retornado pelo ML (ex. `MLB1234567890`); nulo = ainda não publicado |
| `MLAN_USER_PRODUCT_ID` | `user_product_id` (modelo User Products) |
| `MERC_LIVRE_CATEGORIA_ID` | FK categoria MLB (folha) |
| `MERC_LIVRE_TP_ANUNCIO_ID` | FK tipo de listagem (`gold_special`, `gold_pro`, …) |
| `MLAN_ACAO` | `PUBLICAR`, `ATUALIZAR`, `PAUSAR`, `ATIVAR`, `ENCERRAR`, `EXCLUIR` (view filtra também com inicial maiúscula) |
| `MLAN_TITULO` / `MLAN_DESCRICAO` | Título (clássico) ou `family_name` (UP); descrição `plain_text` |
| `MLAN_PRECO` / `MLAN_QTDE` | Preço e estoque do anúncio |
| `MLAN_CONDICAO` | `new`, `used` ou recondicionado |
| `MARCAS_ID` / `MLAN_MODELO` | Marca Horus + modelo |
| `MLAN_GTIN` / `MLAN_SKU` | EAN/UPC do anúncio e `SELLER_SKU` |
| `MLAN_GARANTIA_TIPO` / `MLAN_GARANTIA_TEMPO` | `WARRANTY_TYPE` / `WARRANTY_TIME` |
| `MLAN_ALTURA_CM` / `MLAN_COMPRIMENTO_CM` / `MLAN_LARGURA_CM` / `MLAN_PESO` | Pacote ME2 (cm / gramas) |
| `MLAN_MODO_ENVIO` | `shipping.mode` (padrão `me2`) |
| `MLAN_STATUS` | Status no ML (`active`, `paused`, `closed`) — distinto de `STATUS` do registro Horus |
| `MLAN_PERMALINK` / `MLAN_ERRO` | URL do anúncio e último erro da API |
| `MLAN_DATA_ENVIO` / `MLAN_DATA_ATUALIZACAO` / `MLAN_DATA_AGENDAMENTO` | Controle da fila |

### Tabela `MERC_LIVRE_ANUNCIO_EV` (prefixo `MLAE_`)

Script: `src/oracle/MERC_LIVRE_ANUNCIO_EV.tab`.

| Coluna | Uso |
|--------|-----|
| `MERC_LIVRE_ANUNCIO_EV_ID` | PK Horus |
| `MERC_LIVRE_ANUNCIO_ID` | FK do anúncio (obrigatório) |
| `EMBALAGEM_VENDA_ID` | FK da embalagem de venda do Horus (obrigatório). A embalagem já tem `PRODUTO_ID` |
| `MLAE_QTDE` | Quantidade dessa embalagem no anúncio |
| `MLAE_VALOR` | Valor dessa embalagem no anúncio |
| `STATUS` | Registro Horus (`Ativo`, etc.) |

Cadastro Horus de origem (fora deste repositório, schema ERP):

| Tabela | Papel |
|--------|-------|
| `EMBALAGEM_VENDA` | Unidade de venda do produto (código de barras, SKU da embalagem, dimensões). Tem `PRODUTO_ID` |
| `PRODUTO` | Cadastro do item; fotos em `FOTOGRAFIA_ID`, `FOTOGRAFIA1_ID`, `FOTOGRAFIA2_ID` → `FOTO_PRODUTO` |

### Views de leitura para envio ao ML

Contrato de **SELECT** do worker. O cadastro fica nas tabelas; o envio lê destas duas views (`anuncioRepository.js`).

| View | Script | Papel no envio |
|------|--------|----------------|
| `VIEW_MLAPI_ANUNCIO` | `src/oracle/view_mlapi_anuncio.sql` | Dados do anúncio (título, preço, categoria ML, tipo, atributos, ação) |
| `VIEW_MLAPI_ANUNCIO_IMAGEM` | `src/oracle/view_mlapi_anuncio_imagem.sql` | Imagens do anúncio (`FOPR_FOTO`) para `pictures` / upload multipart |

Padrão: **leitura** SELECT direto na view (como `VIEW_MLOR_NFE`); **gravação** do retorno ML (`MLAN_ID`, datas, erro) via procedure `PRC_MLAPI_*`.

#### `VIEW_MLAPI_ANUNCIO`

Monta o payload a partir de `MERC_LIVRE_ANUNCIO`, resolvendo IDs do ML (categoria e tipo de anúncio) e a descrição da marca. Só retorna linhas com ação pendente.

**Joins**

| Origem | Join | Tipo |
|--------|------|------|
| `MERC_LIVRE_ANUNCIO` | base | — |
| `MERC_LIVRE_CATEGORIA` | `MERC_LIVRE_CATEGORIA_ID` | interno (anúncio sem categoria **não** aparece) |
| `MERC_LIVRE_TP_ANUNCIO` | `MERC_LIVRE_TP_ANUNCIO_ID` | interno (anúncio sem tipo **não** aparece) |
| `MARCAS` | `MARCAS_ID` = `MARCA_ID` | externo (`(+)`) — marca pode ser nula |

**Filtro:** `MLAN_ACAO in ('Publicar','Atualizar','Pausar','Ativar','Encerrar','Excluir')`. A coluna de saída `MLAN_ACAO` vem com `upper(...)`.

**Não inclui** embalagens (`MERC_LIVRE_ANUNCIO_EV`). Composição do kit: ler a tabela EV à parte, pela PK do anúncio.

| Coluna da view | Origem | Uso no POST/PUT `/items` |
|----------------|--------|--------------------------|
| `UNIDADE_EMPRESARIAL_ID` | `MERC_LIVRE_ANUNCIO` | Filtrar pela unidade do `.env` |
| `MERC_LIVRE_ANUNCIO_ID` | `MERC_LIVRE_ANUNCIO` | PK Horus; chave para imagens e EV |
| `MLAN_ID` | `MERC_LIVRE_ANUNCIO` | `item_id` ML; nulo = ainda não publicado (`PUBLICAR`) |
| `MLAN_USER_PRODUCT_ID` | `MERC_LIVRE_ANUNCIO` | `user_product_id` (User Products) |
| `MLTA_TP_ANUNCIO_ID` | `MERC_LIVRE_TP_ANUNCIO.MLTA_ID` | `listing_type_id` (ex. `gold_special`) |
| `MLTA_CATEGORIA_ID` | `MERC_LIVRE_CATEGORIA.MLCA_ID` | `category_id` MLB (ex. `MLB269615`). Nome da coluna é `MLTA_*` por alias da view; o valor é o ID de **categoria** |
| `MLAN_TITULO` | `MERC_LIVRE_ANUNCIO` | `title` (clássico) ou `family_name` (UP) |
| `MLAN_DESCRICAO` | `MERC_LIVRE_ANUNCIO` | `POST /items/{id}/description` (`plain_text`) — **não** entra no POST do item |
| `MLAN_PRECO` | `MERC_LIVRE_ANUNCIO` | `price` |
| `MLAN_QTDE` | `MERC_LIVRE_ANUNCIO` | `available_quantity` |
| `MLAN_CONDICAO` | `MERC_LIVRE_ANUNCIO` | `ITEM_CONDITION` / `condition` |
| `MLTA_MARCA_DESCRICAO` | `MARCAS.MARC_DESCRICAO` | atributo `BRAND` |
| `MLAN_MODELO` | `MERC_LIVRE_ANUNCIO` | atributo `MODEL` |
| `MLAN_GTIN` | `MERC_LIVRE_ANUNCIO` | atributo `GTIN` |
| `MLAN_SKU` | `MERC_LIVRE_ANUNCIO` | atributo `SELLER_SKU` |
| `MLAN_GARANTIA_TIPO` | `MERC_LIVRE_ANUNCIO` | `sale_terms` `WARRANTY_TYPE` |
| `MLAN_GARANTIA_TEMPO` | `MERC_LIVRE_ANUNCIO` | `sale_terms` `WARRANTY_TIME` |
| `MLAN_ALTURA_CM` | `MERC_LIVRE_ANUNCIO` | `SELLER_PACKAGE_HEIGHT` |
| `MLAN_COMPRIMENTO_CM` | `MERC_LIVRE_ANUNCIO` | `SELLER_PACKAGE_LENGTH` |
| `MLAN_LARGURA_CM` | `MERC_LIVRE_ANUNCIO` | `SELLER_PACKAGE_WIDTH` |
| `MLAN_PESO` | `MERC_LIVRE_ANUNCIO` | `SELLER_PACKAGE_WEIGHT` (gramas) |
| `MLAN_MODO_ENVIO` | `MERC_LIVRE_ANUNCIO` | `shipping.mode` (padrão `me2`) |
| `MLAN_ACAO` | `upper(MLAN_ACAO)` | Roteia o endpoint: `PUBLICAR`, `ATUALIZAR`, `PAUSAR`, `ATIVAR`, `ENCERRAR`, `EXCLUIR` |

#### `VIEW_MLAPI_ANUNCIO_IMAGEM`

Lista as fotos a enviar junto com o anúncio. Não há tabela de imagem do anúncio: as fotos vêm do **produto** das embalagens amarradas.

**Caminho:** `MERC_LIVRE_ANUNCIO` → `MERC_LIVRE_ANUNCIO_EV` → `EMBALAGEM_VENDA` → `PRODUTO` → `FOTO_PRODUTO`.

Até **3** fotos por produto, via `UNION ALL`:

| Slot no produto | Coluna |
|-----------------|--------|
| 1ª | `PRODUTO.FOTOGRAFIA_ID` |
| 2ª | `PRODUTO.FOTOGRAFIA1_ID` |
| 3ª | `PRODUTO.FOTOGRAFIA2_ID` |

Slot vazio (FK nula) não gera linha. Várias embalagens do mesmo produto podem repetir a mesma foto (`UNION ALL`, sem `DISTINCT`).

**Não filtra** `MLAN_ACAO`. No job, cruzar com `VIEW_MLAPI_ANUNCIO` por `MERC_LIVRE_ANUNCIO_ID`.

| Coluna da view | Origem | Uso |
|----------------|--------|-----|
| `MERC_LIVRE_ANUNCIO_ID` | `MERC_LIVRE_ANUNCIO` | Ligar à linha da `VIEW_MLAPI_ANUNCIO` |
| `MLAN_ID` | `MERC_LIVRE_ANUNCIO` | `item_id` ML (anúncio já publicado: `POST /items/{id}/pictures`) |
| `FOTO_PRODUTO_ID` | `FOTO_PRODUTO` | PK da foto no Horus |
| `FOPR_FOTO` | `FOTO_PRODUTO` | **LONG RAW** com os bytes da imagem. Upload `POST /pictures/items/upload` (multipart); o `id` entra em `pictures[]` |
| `PRINCIPAL` | view (`Sim` / `Nao`) | `Sim` = foto de capa (primeira no array enviado ao ML) |

Capa: ordenar `PRINCIPAL = Sim` primeiro. Não usar a ordem do `UNION` como regra — o campo `PRINCIPAL` manda.

### Fluxo do worker (`anuncios.js`)

1. `getAnunciosPendentes()` — `VIEW_MLAPI_ANUNCIO` filtrada por `UNIDADE_EMPRESARIAL_ID`.
2. `GET /users/{id}` — tag `user_product_seller` (título vs `family_name`).
3. Por anúncio, conforme `MLAN_ACAO`:
   - `PUBLICAR` — upload das fotos → `POST /items/validate` → `POST /items` → descrição → `PRC_MLAPI_AUNCIOS_ENV`
   - `ATUALIZAR` — fotos + `PUT /items/{id}` + descrição
   - `PAUSAR` / `ATIVAR` / `ENCERRAR` — `PUT` com `status`
   - `EXCLUIR` — `closed` e depois `deleted: true`
4. Procedure `PRC_MLAPI_AUNCIOS_ENV` (`P_MERC_LIVRE_ANUNCIO_ID`, `P_MLAN_ID`): grava `MLAN_ID`, `MLAN_DATA_ENVIO = SYSDATE`, zera `MLAN_ACAO`.

Erro em um anúncio não interrompe o lote. Falha na descrição após o POST do item **não** impede gravar o `MLAN_ID` (evita republicar duplicado).

---

## Objetos Oracle — contrato Node ↔ Horus

### Tabelas principais (schema `HORUS`)

- `MERC_LIVRE_CONFIG` — OAuth
- `MERC_LIVRE_PRODUTO` — anúncios
- `MERC_LIVRE_ORDEM` — cabeçalho pedido (repasse `MLOR_PAGTO_ML_*`, envio NF-e `MLOR_XML_DT_ENVIO`)
- `MERC_LIVRE_ORDEM_ITEM` — itens
- `MERC_LIVRE_ORDEM_END` — endereço entrega
- `MERC_LIVRE_CATEGORIA` — categorias MLB
- `MERC_LIVRE_TP_ANUNCIO` — tipos de listagem
- `MERC_LIVRE_PERGUNTA` — perguntas recebidas nos anúncios (prefixo colunas `MLQT_`)
- `MERC_LIVRE_ANUNCIO` — fila de publicação Horus → ML (prefixo `MLAN_`); o anúncio em si
- `MERC_LIVRE_ANUNCIO_EV` — embalagens de venda amarradas ao anúncio (prefixo `MLAE_`); a embalagem aponta para o produto

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
| `PRC_MLAPI_NFE_XML_ENVIO` | `ordemNfeRepository.js` |
| `PRC_MLAPI_PERGUNTA_UPDATE` | `perguntaRepository.js` |
| `PRC_MLAPI_CATEGORIA_UPDATE` | `categoriaRepository.js` |
| `PRC_MLAPI_TP_ANUNCIO_UPDATE` | `tpAnuncioRepository.js` |
| `PRC_MLAPI_AUNCIOS_ENV` | `anuncioRepository.js` |

### Consultas diretas no Node (somente leitura)

| Função | Arquivo | Objeto |
|--------|---------|--------|
| `configFind` | `configRepository.js` | `VIEW_MERC_LIVRE_CONFIG` |
| `getOrdensPagtoAberto` | `ordemRepository.js` | `MERC_LIVRE_ORDEM` |
| `getOrdensNfePendente` | `ordemNfeRepository.js` | `VIEW_MLOR_NFE` |
| `getAnunciosPendentes` | `anuncioRepository.js` | `VIEW_MLAPI_ANUNCIO` |
| `getAnuncioImagens` | `anuncioRepository.js` | `VIEW_MLAPI_ANUNCIO_IMAGEM` (`FOPR_FOTO` LONG RAW → Buffer) |

### Views Oracle (somente leitura via Node)

| View | Uso |
|------|-----|
| `VIEW_MERC_LIVRE_CONFIG` | Config OAuth (`configFind`) |
| `VIEW_MLOR_NFE` | NF-e pendente de envio ao ML (`getOrdensNfePendente`) |
| `VIEW_MLAPI_ANUNCIO` | Envio de anúncios ao ML (`getAnunciosPendentes`) |
| `VIEW_MLAPI_ANUNCIO_IMAGEM` | Imagens do anúncio — LONG RAW `FOPR_FOTO` + `PRINCIPAL` (`getAnuncioImagens`) |

### Procedures Oracle **não** integradas ao Node

Scripts em `src/oracle/` sem chamada nos repositories atuais:

| Script | Observação |
|--------|------------|
| `prc_mlapi_config.prc` | Configuração — não usado pelo worker |
| `prc_mlapi_produto.prc` | Variante legada de produto |
| `prc_mlapi_cliente.prc`, `prc_mlapi_cliente_insert.prc` | Cliente Horus |
| `prc_mlapi_endereco_insert.prc` | Endereço |
| `prc_mlapi_pdsd_insert.prc`, `prc_mlapi_pdsd_exec.prc` | Pedido de saída (PDSD) |

**Regra:** regras de negócio pesadas (gerar ID, validar duplicidade, commit) ficam nas **procedures**, não no Node.

---

## API Mercado Livre — base URL e auth

- Base: `https://api.mercadolibre.com`
- Auth: `Authorization: Bearer {MLCN_ACCESS_TOKEN}`
- OAuth: `POST https://api.mercadolibre.com/oauth/token`
- Site fixo: **MLB** (Brasil) em categorias e listing_types

Endpoints de anúncios (importação ML → Horus, `MERC_LIVRE_PRODUTO`):

- `GET /users/{user_id}/items/search?limit=50&offset=...` — listagem paginada (`getProdutosAll.js`); se `paging.total` > 1000 usa `search_type=scan` + `scroll_id`
- `GET /items/{id}` — detalhe (`getProduto.js`)

Endpoints de pedidos (importação):

- `GET /orders/search?seller={id}&order.status=paid&order.date_created.from=...&order.date_created.to=...&limit=50&offset=...` — listagem (`getOrdensAll.js`, janela `ORDEM_DIAS`)
- `GET /orders/{id}` — detalhe (`getOrdem.js`)
- `GET /orders/{id}/billing_info` — dados fiscais (`getDadosFaturamento.js`)
- `GET /shipments/{id}` — endereço de entrega (`getEndereco.js`)

Endpoints adicionais (perguntas):

- `GET /my/received_questions/search?api_version=4` — listagem paginada + ordenação `date_created DESC`; janela via `PERGUNTAS_DIAS` (filtro local)
- `GET /questions/{id}?api_version=4` — detalhe + dados do comprador

Endpoints adicionais (repasse ML):

- `GET /billing/integration/group/ML/order/details?order_ids={id1,id2,...}` — liberação de valores (até 60 IDs por request)

Endpoints adicionais (envio NF-e):

- `POST /shipments/{shipment_id}/invoice_data/?siteId=MLB` — importar XML da NF-e (libera etiqueta)
- `GET /shipments/{shipment_id}/invoice_data?siteId=MLB` — consultar NF-e já enviada

Endpoints adicionais (publicação de anúncios):

- `GET /users/{id}` — tag `user_product_seller`
- `POST /pictures/items/upload` — upload multipart da foto (`FOPR_FOTO`)
- `POST /items/validate` — validar payload (HTTP 204)
- `POST /items` — criar anúncio
- `PUT /items/{id}` — atualizar / pausar / ativar / encerrar / excluir
- `POST /items/{id}/description` — descrição após criar
- `PUT /items/{id}/description?api_version=2` — atualizar descrição

Documentação oficial: https://developers.mercadolivre.com.br/  
NF-e: https://developers.mercadolivre.com.br/pt_br/importar-nota-fiscal  
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
6. **`ordemNfeSave`** — sem cron definido; roda apenas na subida via `Iniciar()`.
7. **Sem testes** — validar manualmente contra API ML e banco Horus.
8. **Conexão por operação** — cada repository abre/fecha conexão; não há pool compartilhado.
9. **OAuth `MLCN_CODE`** — após primeira troca, o code expira; tentativa de `findToken` gera `invalid_grant` (ruído no log) se o code antigo permanecer no banco; o refresh costuma resolver.
10. **Arquivos locais não versionados** — `.env`, `logs/`, `node_modules/`.
11. **`README.md`** — parcialmente desatualizado em relação ao código (falta `ordemPagto`, `ordemNfe`, `ORACLE_CLIENT_LIB_DIR`, estado dos crons).
12. **NT 2025.001** — XML da NF-e para pagamentos cartão/PIX deve incluir dados do intermediador ML (`CNPJ 03.007.331/0001-41`, grupo `<card>`, etc.); ver doc ML.
13. **`ORDEM_DIAS`** — obrigatório no `.env`; se ausente ou inválido, `getOrdensAll` lança erro. Não recupera pedidos além da retenção da API (~12 meses) nem cancelados.
14. **`PERGUNTAS_DIAS`** — obrigatório no `.env`; se ausente ou inválido, `getPerguntasAll` lança erro. A API de perguntas não filtra por data na query — o corte é local após ordenação DESC.

### Tratamento de erros (comportamento atual)

| Camada | Comportamento |
|--------|---------------|
| `execJobs.js` | `try/catch` por job; falha de um job não interrompe os demais na mesma execução |
| `ordens.js` | `try/catch` por ordem (API + Oracle); log + continua próxima ordem |
| `produtos.js` | `try/catch` por produto; log + continua próximo item |
| `perguntas.js` | `try/catch` por pergunta; log + continua próxima pergunta |
| `ordemPagto.js` | `try/catch` por ordem; log + continua próxima ordem |
| `ordemNfe.js` | `try/catch` por ordem; log + continua próxima ordem; não grava data em falha |
| `anuncios.js` | `try/catch` por anúncio; log + continua próximo; descrição falha não impede gravar `MLAN_ID` |
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
- `limparlog.bat` — apaga arquivos em `logs/` e subpastas (Windows)

Commits e PRs: só quando o usuário pedir explicitamente.

---

## Evoluções prováveis (contexto para planejamento)

Áreas comuns de continuidade que **ainda não existem** ou estão **incompletas** no código:

- Webhooks/notifications ML — **perguntas via polling**; mensagens pós-venda ainda não implementadas (ver `MercadoLivre-API.md` seções 5 e 10)
- Exportação Horus → ML de anúncios implementada (`anunciosSave`). Atributos extras da ficha técnica (por categoria) ainda não. Guia: [PUBLICACAO-ANUNCIOS.md](PUBLICACAO-ANUNCIOS.md)
- Suporte a múltiplas unidades empresariais
- Integração `MERC_LIVRE_ANUNCIO` + `MERC_LIVRE_ANUNCIO_EV` — worker publica via `VIEW_MLAPI_ANUNCIO` / `VIEW_MLAPI_ANUNCIO_IMAGEM` e `PRC_MLAPI_AUNCIOS_ENV`
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

### Alterações jun/2026 — envio NF-e ML (Horus → ML)

**Código Node:**

| Arquivo | Função |
|---------|--------|
| `src/services/ordem/postNfeXml.js` | POST XML na API ML (`/shipments/{id}/invoice_data`) |
| `src/services/ordem/ordemNfe.js` | Orquestrador batch |
| `src/repositories/ordemNfeRepository.js` | `getOrdensNfePendente()` + `PRC_MLAPI_NFE_XML_ENVIO` |
| `src/jobs/execJobs.js` | Job `ordemNfeSave` em `Iniciar()`; **sem cron** |

**Oracle (aplicar manualmente no banco):**

| Script | Objeto |
|--------|--------|
| `src/oracle/merc_livre_ordem.tab` | Coluna `MLOR_XML_DT_ENVIO` |
| `src/oracle/view_mlor_nfe.sql` | View `VIEW_MLOR_NFE` |
| `src/oracle/prc_mlapi_nfe_xml_envio.prc` | Procedure update data envio |

**Fora de escopo desta entrega:** anexar NF-e ao pack (`/packs/{id}/fiscal_documents`), DC-e (PF/PJ não-contribuinte), webhooks `shipments`.

### Alterações jul/2026 — busca de pedidos (`ORDEM_DIAS` + paginação)

**Código Node:**

| Arquivo | Função |
|---------|--------|
| `src/services/ordem/getOrdensAll.js` | Janela `ORDEM_DIAS` (`order.date_created.from/to`), filtro `paid` + pagamento `approved`, paginação `limit`/`offset` |
| `src/services/ordem/ordens.js` | Log da quantidade de ordens elegíveis antes do loop |

**Configuração:**

| Item | Detalhe |
|------|---------|
| `.env` → `ORDEM_DIAS` | Inteiro positivo (ex.: `90` = últimos 90 dias); obrigatório |

**Utilitário:**

| Arquivo | Função |
|---------|--------|
| `limparlog.bat` (raiz) | Apaga todos os arquivos em `logs/` e subpastas |

**Documentação atualizada:** `CONTEXTO-IA.md`, `ARQUITETURA.md`, `MercadoLivre-API.md`, `README.md`, regra `.cursor/rules/desenvolvimento.mdc`.

### Alterações jul/2026 — janela de perguntas (`PERGUNTAS_DIAS`)

**Código Node:**

| Arquivo | Função |
|---------|--------|
| `src/services/pergunta/getPerguntasAll.js` | Janela `PERGUNTAS_DIAS` (filtro local por `date_created`); ordenação `date_created DESC`; para paginação ao sair da janela |
| `src/services/pergunta/perguntas.js` | Log da quantidade de perguntas elegíveis antes do loop |

**Configuração:**

| Item | Detalhe |
|------|---------|
| `.env` → `PERGUNTAS_DIAS` | Inteiro positivo (ex.: `30` = últimos 30 dias); obrigatório |

**Nota API:** `/my/received_questions/search` não aceita `date_from`/`date_to` — apenas `item`, `from`, `status`, etc.

### Alterações set/2026 — modelo de dados da publicação (anúncio + embalagens)

DDL e views no Oracle para a fila Horus → ML.

| Script | Objeto |
|--------|--------|
| `src/oracle/merc_livre_anuncio.tab` | `MERC_LIVRE_ANUNCIO` — cabeçalho do anúncio |
| `src/oracle/MERC_LIVRE_ANUNCIO_EV.tab` | `MERC_LIVRE_ANUNCIO_EV` — embalagens de venda no anúncio (`EMBALAGEM_VENDA_ID` → produto) |
| `src/oracle/view_mlapi_anuncio.sql` | `VIEW_MLAPI_ANUNCIO` — SELECT do worker para dados do anúncio (categoria/tipo ML, marca, ação) |
| `src/oracle/view_mlapi_anuncio_imagem.sql` | `VIEW_MLAPI_ANUNCIO_IMAGEM` — SELECT do worker para imagens (`FOPR_FOTO` LONG RAW + `PRINCIPAL`) |

### Alterações set/2026 — envio de anúncios Horus → ML

**Código Node:**

| Arquivo | Função |
|---------|--------|
| `src/services/anuncio/anuncios.js` | Orquestrador batch (`MLAN_ACAO`) |
| `src/services/anuncio/montarPayload.js` | JSON `POST/PUT /items` (clássico vs User Products) |
| `src/services/anuncio/getVendedor.js` | Tag `user_product_seller` |
| `src/services/anuncio/postImagem.js` | Multipart `POST /pictures/items/upload` |
| `src/services/anuncio/postAnuncio.js` | Validate + `POST /items` |
| `src/services/anuncio/putAnuncio.js` | `PUT /items/{id}` |
| `src/services/anuncio/postDescricao.js` | Descrição após criar/atualizar |
| `src/repositories/anuncioRepository.js` | Views + `PRC_MLAPI_AUNCIOS_ENV` |
| `src/jobs/execJobs.js` | Job `anunciosSave` em `Iniciar()`; cron planejado `*/5 * * * *` (comentado) |

**Oracle:** `PRC_MLAPI_AUNCIOS_ENV` (`P_MERC_LIVRE_ANUNCIO_ID`, `P_MLAN_ID`).

### Alterações set/2026 — paginação do pull de anúncios (`getProdutosAll`)

`GET /users/{user_id}/items/search` passou a percorrer todas as páginas (`limit=50` + `offset`). Se `paging.total` > 1000, usa `search_type=scan` + `scroll_id` (limite da API com offset).

Última atualização deste arquivo: 08/set/2026.

---

## Prompt sugerido para retomar trabalho

Ao iniciar nova sessão, o usuário (ou o agente) pode usar:

> Leia `CONTEXTO-IA.md`, `README.md` e `ARQUITETURA.md` deste repositório e continue o desenvolvimento da integração Horus ↔ Mercado Livre.
