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
| Entry point | `src/app.js` → `src/jobs/execJobs.js` |
| Linguagem | JavaScript CommonJS (`require` / `module.exports`) |
| Idioma do usuário | **Português** (sempre responder em PT-BR) |

---

## O que este projeto **é** e **não é**

**É:**
- Integração batch pull (polling) ML → Horus
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
| `axios` | Todas as chamadas à API ML |
| `oracledb` | Conexão e execução de procedures |
| `node-cron` | Agendamento em `execJobs.js` |
| `dotenv` | `.env` (DB + unidade empresarial) |
| `qs` | Body OAuth (`application/x-www-form-urlencoded`) |
| `winston` | Declarado no `package.json`; **logging efetivo** via `src/utils/logger.js` |

---

## Variáveis de ambiente (`.env`)

Arquivo **não versionado** (`.gitignore`). Nunca commitar.

```env
DB_USER=
DB_PASSWORD=
DB_CONNECT=host:1521/servico
UNIDADE_EMPRESARIAL_ID=
```

**OAuth fica no banco**, tabela `MERC_LIVRE_CONFIG`:
`MLCN_CLIENT_ID`, `MLCN_CLIENT_SECRET`, `MLCN_CODE`, `MLCN_REDIRECT_URI`, `MLCN_TOKEN`, `MLCN_ACCESS_TOKEN`, `MLCN_USER_ID`.

View de leitura: `VIEW_MERC_LIVRE_CONFIG` (campo `EXPIRES`: `S` = precisa renovar token).

---

## Configuração crítica — Oracle Client

Em `src/config/database.js`:

```javascript
oracledb.initOracleClient({ libDir: 'C:\\app\\client\\product\\21.0.0\\client_1\\bin' });
```

- Caminho **hardcoded** para Windows.
- Se falhar na inicialização, o processo encerra com `process.exit(1)`.
- Ao portar para Linux/Docker/outra máquina, **ajustar `libDir`** ou usar variável de ambiente.

---

## Padrão de código (seguir ao adicionar features)

### Estrutura por domínio

Cada entidade segue o mesmo desenho:

```
services/{dominio}/
  getXxx.js          → chama API ML (axios + Bearer token via getToken)
  xxxs.js            → orquestra: busca API → transforma → chama repository

repositories/
  xxxRepository.js → connection.execute('BEGIN PRC_MLAPI_... END;')

src/oracle/
  prc_mlapi_xxx_update.prc → insert/update + regras Horus
```

### Fluxo de token (obrigatório em todo service de API)

Todo `get*.js` que chama a API ML deve:

1. `await getToken.getToken()`
2. Usar `resToken[0].MLCN_ACCESS_TOKEN` e, se necessário, `MLCN_USER_ID`

### Repositories

- Sempre: `getConnection()` → `execute` → `connection.close()` no `finally`
- Erros Oracle `errorNum === 20000` → `tratarErroOracle()` em `utils/oracleErrorHandler.js`
- Parâmetro `P_TRANSACTION: 0` em todas as procedures (commit controlado no PL/SQL)
- Procedures usam `GENERATE_NEXT_ID` para PKs novas (padrão Horus)

### Estilo

- CommonJS, sem TypeScript
- Funções `async/await`
- Nomes em português nos domínios de negócio (`ordens`, `produtos`, `categorias`)
- Campos API ML em inglês; campos mapeados para Oracle com prefixos `MLOR_`, `MLPD_`, `MLCN_`, etc.
- Evitar refatorações amplas não solicitadas; manter diff mínimo

---

## Jobs — ponto central de orquestração

Arquivo: `src/jobs/execJobs.js`

| Função | Cron | Service |
|--------|------|---------|
| `refreshToken` | `*/30 * * * *` | `services/token/getToken.js` |
| `tpAnuncioSave` | `0 */12 * * *` | `services/tpAnuncio/tpAnuncios.js` |
| `categoriasSave` | `0 */12 * * *` | `services/categoria/categorias.js` |
| `produtosSave` | `*/5 * * * *` | `services/produto/produtos.js` |
| `ordensSave` | `*/5 * * * *` | `services/ordem/ordens.js` |

Na subida: `Iniciar()` roda **todos** os jobs em sequência antes de registrar os crons.

Para novo job: criar função async + `cron.schedule` + exportar lógica no service correspondente.

---

## Mapeamento rápido: "preciso alterar X" → arquivo

| Necessidade | Onde alterar |
|-------------|--------------|
| Novo intervalo de sync | `src/jobs/execJobs.js` |
| Nova chamada API ML | `src/services/{dominio}/get*.js` |
| Regra de transformação dos dados | `src/services/{dominio}/*.js` (orquestrador) |
| Persistência / novo campo no banco | `src/repositories/*.js` + `src/oracle/prc_mlapi_*.prc` + `.tab` |
| Credenciais OAuth / token | Banco `MERC_LIVRE_CONFIG` + `services/token/*` |
| Conexão Oracle | `src/config/database.js` + `.env` |
| Log de erros | `src/utils/logger.js` → `src/error.log` |
| Filtro de pedidos importados | `src/services/ordem/getOrdensAll.js` (hoje: `paid` + payment `approved`) |
| Dados fiscais do comprador | `src/services/ordem/getDadosFaturamento.js` |
| Endereço de entrega | `src/services/ordem/getEndereco.js` (API `/shipments/{id}`) |
| SKU/GTIN de produtos | `src/services/produto/produtos.js` (`SELLER_SKU`, `GTIN` nos attributes) |

---

## Objetos Oracle — contrato Node ↔ Horus

### Tabelas principais (schema `HORUS`)

- `MERC_LIVRE_CONFIG` — OAuth
- `MERC_LIVRE_PRODUTO` — anúncios
- `MERC_LIVRE_ORDEM` — cabeçalho pedido
- `MERC_LIVRE_ORDEM_ITEM` — itens
- `MERC_LIVRE_ORDEM_END` — endereço entrega
- `MERC_LIVRE_CATEGORIA` — categorias MLB
- `MERC_LIVRE_TP_ANUNCIO` — tipos de listagem

### Procedures chamadas pelo Node

| Procedure | Repository |
|-----------|------------|
| `PRC_MLAPI_TOKEN_UPDATE` | `configRepository.js` |
| `PRC_MLAPI_PRODUTO_UPDATE` | `produtoRepository.js` |
| `PRC_MLAPI_ORDEM_UPDATE` | `ordemRepository.js` |
| `PRC_MLAPI_ORDEM_ITEM_UPDATE` | `ordemItemRepository.js` |
| `PRC_MLAPI_ORDEM_END_UPDATE` | `ordemEndRepository.js` |
| `PRC_MLAPI_CATEGORIA_UPDATE` | `categoriaRepository.js` |
| `PRC_MLAPI_TP_ANUNCIO_UPDATE` | `tpAnuncioRepository.js` |

Existe também `PRC_MLAPI_PRODUTO_UPDATE_X` (variante; verificar uso antes de alterar).

Scripts adicionais em `src/oracle/` referem schema `DESENV` (`MERC_LIVRE_PRDT`, `MERC_LIVRE_PRDT_IMAGEM`) — possível evolução futura, **não integrados** ao fluxo Node atual.

**Regra:** regras de negócio pesadas (gerar ID, validar duplicidade, commit) ficam nas **procedures**, não no Node.

---

## API Mercado Livre — base URL e auth

- Base: `https://api.mercadolibre.com`
- Auth: `Authorization: Bearer {MLCN_ACCESS_TOKEN}`
- OAuth: `POST https://api.mercadolibre.com/oauth/token`
- Site fixo: **MLB** (Brasil) em categorias e listing_types

Documentação oficial: https://developers.mercadolivre.com.br/

---

## Como executar localmente

```bash
npm install
node src/app.js
```

Windows: `Iniciar.bat` (atenção: script aponta para `C:\Fontes\avvante-mercado-livre` — pode divergir do path real `C:\Projetos\avvante-mercado-livre`).

Oracle local opcional: `docker compose up -d` (Oracle XE 21, porta 1521).

---

## Pontos de atenção / débitos técnicos conhecidos

1. **`findToken.js`** — `code_verifier` está como literal `'$CODE_VERIFIER'` (placeholder); fluxo OAuth inicial pode precisar de ajuste para PKCE real.
2. **`ordens.js`** — itens do pedido gravam `sku: '0'` e `gtin: '0'` fixos (não extrai do produto).
3. **`configRepository.js`** — no `catch` de `configUpdate`, referência a `logError(errorMsg)` parece incorreta (variável indefinida).
4. **`database.js`** — caminho Oracle Client fixo por máquina Windows.
5. **`Iniciar.bat`** — path desatualizado em relação ao workspace atual.
6. **Sem testes** — validar manualmente contra API ML e banco Horus.
7. **Conexão por operação** — cada repository abre/fecha conexão; não há pool compartilhado.
8. **Pedidos** — erro em uma ordem é logado e o loop continua; demais jobs abortam no primeiro throw do orquestrador.
9. **Arquivos locais não versionados** — `.env`, `src/error.log`, `node_modules/`, `logs/`.

---

## Checklist para adicionar nova entidade sincronizada

1. Criar/alterar tabela em `src/oracle/*.tab`
2. Criar procedure `PRC_MLAPI_{ENTIDADE}_UPDATE` em `src/oracle/`
3. Criar `repositories/{entidade}Repository.js` seguindo padrão existente
4. Criar `services/{entidade}/get{Entidade}.js` (API) e `{entidade}s.js` (orquestrador)
5. Registrar job em `execJobs.js` (função + cron + chamada em `Iniciar()`)
6. Atualizar `README.md`, `ARQUITETURA.md` e este `CONTEXTO-IA.md`

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
- `src/error.log`
- Credenciais Oracle/ML

**Arquivos auxiliares no repo:**
- `bkp.js` — backup/utilitário na raiz (verificar antes de usar)
- `docker-compose.yml` — Oracle XE dev (senha exemplo no compose)
- `vssver.scc` — legado SourceSafe

Commits e PRs: só quando o usuário pedir explicitamente.

---

## Evoluções prováveis (contexto para planejamento)

Áreas comuns de continuidade que **ainda não existem** no código:

- Webhooks/notifications ML (substituir ou complementar polling)
- Exportação Horus → ML (publicar/atualizar anúncios)
- Suporte a múltiplas unidades empresariais
- Integração `MERC_LIVRE_PRDT` / imagens (`DESENV`)
- Pool de conexões Oracle
- Testes de integração mockados
- Parametrizar `libDir` e site MLB via `.env`
- Corrigir SKU/GTIN nos itens de pedido

---

## Histórico de contexto da sessão

Documentação criada para o projeto Avvante/Horus:
- `README.md` — guia geral
- `ARQUITETURA.md` — diagramas e camadas
- `CONTEXTO-IA.md` — este guia de continuidade

Última atualização deste arquivo: junho/2026.

---

## Prompt sugerido para retomar trabalho

Ao iniciar nova sessão, o usuário (ou o agente) pode usar:

> Leia `CONTEXTO-IA.md`, `README.md` e `ARQUITETURA.md` deste repositório e continue o desenvolvimento da integração Horus ↔ Mercado Livre.
