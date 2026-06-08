# Autenticação OAuth — Mercado Livre × Horus

Guia de referência para **criação, renovação e uso de tokens** na integração Horus ↔ Mercado Livre, cruzando a documentação oficial com a implementação deste repositório.

**Documentação oficial:**
- [Recomendações de Autenticação e Token](https://developers.mercadolivre.com.br/pt_br/desenvolvimento-seguro)
- [Autenticação e Autorização](https://developers.mercadolivre.com.br/pt_br/autenticacao-e-autorizacao) *(atualizada em 29/12/2025)*

---

## Visão geral

O Mercado Livre usa **OAuth 2.0** com o fluxo **Authorization Code Grant Type (Server Side)** — indicado para aplicações que executam código no servidor (Java, Node.js, Go, etc.), conforme [Autenticação e Autorização](https://developers.mercadolivre.com.br/pt_br/autenticacao-e-autorizacao).

O projeto Horus armazena credenciais e tokens no Oracle (`MERC_LIVRE_CONFIG`) e o serviço Node.js renova o `access_token` automaticamente via job cron.

### Autenticação × Autorização

| Conceito | Significado no ML |
|----------|-------------------|
| **Autenticação** | Verificar a identidade do usuário (login/senha na plataforma ML) |
| **Autorização** | Permitir que o app acesse recursos privados do usuário (escopos de leitura/escrita) |

O OAuth 2.0 garante **confidencialidade** (senha nunca exposta ao app), **integridade** (só apps autorizados acessam dados privados) e **disponibilidade** (tokens quando necessários).

### Fluxo Server Side (resumo oficial)

Conforme a documentação ML, o processo completo é:

1. Redirecionar o usuário para o Mercado Livre
2. ML autentica o usuário (login na plataforma)
3. Usuário autoriza o app na tela de permissões
4. `POST /oauth/token` — trocar o `code` por tokens
5. ML devolve `access_token` e `refresh_token`
6. App usa o `access_token` para chamar a API e acessar dados privados

```mermaid
sequenceDiagram
    participant U as Usuário ML (admin)
    participant ML as Mercado Livre
    participant H as Horus (Oracle)
    participant N as Node.js (getToken)

    Note over U,ML: 1. Autorização manual (uma vez ou quando revogar)
    U->>ML: Acessa URL de autorização
    ML->>U: redirect_uri?code=...&state=...
    U->>H: Cadastra code em MERC_LIVRE_CONFIG

    Note over N,H: 2. Fluxo automático (serviço)
    N->>H: VIEW_MERC_LIVRE_CONFIG
    alt Token válido (EXPIRES = N)
        H-->>N: access_token
    else Token expirado (EXPIRES = S)
        N->>ML: POST /oauth/token (authorization_code ou refresh_token)
        ML-->>N: access_token + refresh_token + expires_in
        N->>H: PRC_MLAPI_TOKEN_UPDATE
        H-->>N: tokens atualizados
    end
    N->>ML: API calls com Authorization: Bearer
```

---

## Recomendações de segurança (documentação ML)

Conforme [Desenvolvimento seguro](https://developers.mercadolivre.com.br/pt_br/desenvolvimento-seguro):

| Recomendação ML | Descrição | Situação no projeto |
|-----------------|-----------|---------------------|
| **POST com parâmetros no body** | Ao chamar `POST /oauth/token`, enviar dados no **body** (`application/x-www-form-urlencoded`), não na query string | ✅ `findToken.js` e `refreshToken.js` usam `qs.stringify` no body via axios |
| **Access token em todas as chamadas** | Enviar `Authorization: Bearer {token}` em toda requisição à API | ✅ Todos os `get*.js` em `services/` seguem esse padrão |
| **Parâmetro `state`** | Valor aleatório seguro na URL de autorização; validar no retorno | ⚠️ Não implementado no projeto (recomendado adicionar em fluxo manual) |
| **Mesma `redirect_uri`** | Deve ser **idêntica** à cadastrada no app ML | ✅ Lida de `MLCN_REDIRECT_URI` no banco |
| **Validação de origem (webhooks)** | Validar URLs ao receber notificações | N/A — projeto ainda não usa webhooks |

---

## Pré-requisitos

1. **Aplicação criada** no [Mercado Livre Developers](https://developers.mercadolivre.com.br/) (obter `APP ID` / `client_id` e `Secret Key` / `client_secret`).
2. **`redirect_uri` estática** — URL fixa, sem parâmetros variáveis, igual à configurada no painel ML.
3. **Usuário administrador** da conta ML — colaboradores/operadores retornam `invalid_operator_user_id`.
4. **Registro no Horus** — linha em `MERC_LIVRE_CONFIG` para a `UNIDADE_EMPRESARIAL_ID` do `.env`.
5. **PKCE (opcional/obrigatório)** — se habilitado no app ML, é obrigatório enviar `code_challenge` na autorização e `code_verifier` no token exchange ([detalhes](https://developers.mercadolivre.com.br/pt_br/autenticacao-e-autorizacao)).

---

## Passo 1 — Obter o código de autorização (`code`)

### 1.1 — Conectar com usuário Mercado Livre

Requisitos e observações da [documentação oficial](https://developers.mercadolivre.com.br/pt_br/autenticacao-e-autorizacao):

- É possível usar **usuário de teste** para desenvolvimento.
- O usuário que faz login deve ser **administrador** da conta — colaboradores/operadores geram `invalid_operator_user_id`.
- Na tela de autorização, o ML exibe informações do **DPP (nível integrador)**, indicando se o app é certificado.
- A `redirect_uri` deve corresponder **exatamente** à registrada no app; **não pode conter parâmetros variáveis**. Caso contrário: *"your client callback has to match with the redirect_uri param"*.

### 1.2 — URL de autorização (Brasil)

Abra no navegador:

```
https://auth.mercadolivre.com.br/authorization?response_type=code&client_id={APP_ID}&redirect_uri={REDIRECT_URI}&state={VALOR_ALEATORIO}
```

Com **PKCE habilitado** no app (parâmetros passam a ser obrigatórios):

```
https://auth.mercadolivre.com.br/authorization?response_type=code&client_id={APP_ID}&redirect_uri={REDIRECT_URI}&state={VALOR_ALEATORIO}&code_challenge={CODE_CHALLENGE}&code_challenge_method=S256
```

> Para outros países, altere o domínio de auth (ex.: `mercadolibre.com.ar`, `mercadolibre.com.uy`). Este projeto usa **MLB** (Brasil).

### Parâmetros da URL de autorização

| Parâmetro | Obrigatório | Descrição |
|-----------|-------------|-----------|
| `response_type` | Sim | Valor fixo: `code` — obtém código para trocar por access token |
| `client_id` | Sim | APP ID da aplicação ML |
| `redirect_uri` | Sim | URL **estática**, idêntica à cadastrada no app |
| `state` | Recomendado | Valor aleatório único por tentativa; validar no retorno (ML **não valida** este campo — responsabilidade do app) |
| `code_challenge` | Se PKCE ativo | Hash do `code_verifier` cifrado conforme `code_challenge_method` |
| `code_challenge_method` | Se PKCE ativo | `S256` (SHA-256, **recomendado**) ou `plain` (não recomendado) |

#### Uso correto do parâmetro `state`

Como a `redirect_uri` deve ser estática, **não use parâmetros variáveis na URL de callback**. Se precisar transportar contexto (ex.: ID da unidade empresarial), envie via `state` e valide ao receber o retorno:

```
https://auth.mercadolivre.com.br/authorization?response_type=code&client_id=1620218256833906&redirect_uri=https://localhost.com/redirect&state=ABC123
```

### 1.3 — Tela de autorização e retorno

Após login e clique em autorizar, o ML redireciona para:

```
{REDIRECT_URI}?code=TG-61828b7fffcc9a001b4bc890-314029626&state=ABC1234
```

Exemplo real da documentação:

```
https://localhost.com/redirect?code=TG-61828b7fffcc9a001b4bc890-314029626&state=ABC1234
```

**Validações ao receber o retorno:**
- Conferir se o `state` retornado é o mesmo enviado na requisição
- Copiar o `code` imediatamente — é de uso único e expira rapidamente

### 1.4 — Erro: "Sorry, the application cannot connect to your account"

Se aparecer *Desculpe, o aplicativo não pode se conectar à sua conta*, verificar:

1. `redirect_uri` **exatamente** igual à do app ML (sem variáveis)
2. `client_id` e grant do app são válidos
3. Vendedor logado com **conta principal**, não colaborador
4. Vendedor ou owner do app com **dados pendentes de validação** ou conta inabilitada

### O que gravar no Horus

Cadastrar na tabela `MERC_LIVRE_CONFIG`:

| Campo Oracle | Conteúdo |
|--------------|----------|
| `MLCN_CLIENT_ID` | APP ID |
| `MLCN_CLIENT_SECRET` | Secret Key |
| `MLCN_REDIRECT_URI` | Mesma URL do app ML |
| `MLCN_CODE` | Valor do parâmetro `code` da URL de retorno |
| `UNIDADE_EMPRESARIAL_ID` | ID da unidade (mesmo valor do `.env`) |

> O `code` é de **uso único** e curta duração. Após a troca por token, o serviço passa a usar `refresh_token`.

---

## Passo 2 — Trocar `code` por tokens

### Documentação ML

```http
POST https://api.mercadolibre.com/oauth/token
Content-Type: application/x-www-form-urlencoded
Accept: application/json

grant_type=authorization_code
&client_id={APP_ID}
&client_secret={SECRET_KEY}
&code={AUTHORIZATION_CODE}
&redirect_uri={REDIRECT_URI}
&code_verifier={CODE_VERIFIER}   ← somente se PKCE estiver habilitado
```

### Parâmetros do POST (troca code → token)

| Parâmetro | Obrigatório | Descrição |
|-----------|-------------|-----------|
| `grant_type` | Sim | Valor fixo: `authorization_code` |
| `client_id` | Sim | APP ID |
| `client_secret` | Sim | Secret Key gerada ao criar o app |
| `code` | Sim | Código obtido no Passo 1 |
| `redirect_uri` | Sim | Mesma URL estática configurada no app |
| `code_verifier` | Se PKCE ativo | Sequência aleatória usada para gerar o `code_challenge` |

### Resposta esperada

```json
{
  "access_token": "APP_USR-123456-090515-8cc4448aac10d5105474e1351-1234567",
  "token_type": "bearer",
  "expires_in": 21600,
  "scope": "offline_access read write",
  "user_id": 1234567,
  "refresh_token": "TG-5b9032b4e23464aed1f959f-1234567"
}
```

| Campo | Descrição |
|-------|-----------|
| `access_token` | Token usado no header `Authorization: Bearer` |
| `token_type` | Sempre `bearer` |
| `expires_in` | **21600 segundos (6 horas)** desde a emissão |
| `scope` | Permissões concedidas: `offline_access`, `read`, `write` |
| `user_id` | ID numérico do vendedor no Mercado Livre |
| `refresh_token` | Token para renovação; **uso único** — cada refresh devolve um novo |

**Scopes permitidos** (referência de erros ML): `offline_access`, `read`, `write`.

### Implementação no projeto

Arquivo: `src/services/token/findToken.js`

```javascript
// POST https://api.mercadolibre.com/oauth/token
// grant_type=authorization_code
// Headers: accept + content-type: application/x-www-form-urlencoded
// Body via qs.stringify (não query string) ✅
```

Chamado por `src/services/token/getToken.js` quando `EXPIRES = 'S'` e ainda existe `MLCN_CODE`.

**Atenção — PKCE:** o projeto envia `code_verifier: '$CODE_VERIFIER'` como literal fixo. Isso **só funciona** se PKCE **não** estiver habilitado no app ML. Com PKCE ativo (obrigatório quando habilitado no painel), implementar:

1. Gerar `code_verifier` aleatório (43–128 caracteres)
2. Calcular `code_challenge = BASE64URL(SHA256(code_verifier))` com método `S256`
3. Enviar `code_challenge` + `code_challenge_method` na URL de autorização
4. Persistir o `code_verifier` (ex.: coluna extra em `MERC_LIVRE_CONFIG`) até o POST de troca do `code`
5. Enviar o mesmo `code_verifier` no body do `POST /oauth/token`

---

## Passo 3 — Renovar o access token (refresh)

Quando o token expira, usar o `refresh_token` (campo `MLCN_TOKEN` no banco):

### Documentação ML

```http
POST https://api.mercadolibre.com/oauth/token
Content-Type: application/x-www-form-urlencoded
Accept: application/json

grant_type=refresh_token
&client_id={APP_ID}
&client_secret={SECRET_KEY}
&refresh_token={REFRESH_TOKEN}
```

### Parâmetros do POST (refresh)

| Parâmetro | Obrigatório | Descrição |
|-----------|-------------|-----------|
| `grant_type` | Sim | Valor fixo: `refresh_token` |
| `refresh_token` | Sim | Último refresh token armazenado |
| `client_id` | Sim | APP ID |
| `client_secret` | Sim | Secret Key |

### Resposta do refresh

```json
{
  "access_token": "APP_USR-5387223166827464-090515-b0ad156bce700509ef81b273466faa15-8035443",
  "token_type": "bearer",
  "expires_in": 21600,
  "scope": "offline_access read write",
  "user_id": 8035443,
  "refresh_token": "TG-5b9032b4e4b0714aed1f959f-8035443"
}
```

A resposta inclui **novo** `access_token` (válido por mais 6 horas) e **novo** `refresh_token` — ambos devem substituir os anteriores no banco.

### Regras importantes (ML)

Conforme [Autenticação e Autorização](https://developers.mercadolivre.com.br/pt_br/autenticacao-e-autorizacao):

- Renovar **somente quando o access token expirar** (recomendação oficial de performance).
- Usar **apenas o último** `refresh_token` gerado para a troca.
- O `refresh_token` é de **utilização única** — após usado, invalida; cada refresh devolve um novo.
- Só pode ser usado pelo `client_id` ao qual está associado.
- Validade do refresh: **6 meses** sem uso; após isso, refazer fluxo de autorização completo.

### Implementação no projeto

| Arquivo | Função |
|---------|--------|
| `src/services/token/refreshToken.js` | POST refresh conforme documentação |
| `src/services/token/getToken.js` | Orquestra: tenta `findToken` → sempre `refreshToken` → grava no banco |
| `src/repositories/configRepository.js` | Chama `PRC_MLAPI_TOKEN_UPDATE` |
| `src/oracle/prc_mlapi_token_update.prc` | Atualiza tokens e calcula validade |

---

## Passo 4 — Usar o access token nas APIs

Por segurança, o ML exige o token **no header** em **toda** chamada — recursos públicos e privados — e o token deve corresponder ao usuário consultado ([Autenticação e Autorização](https://developers.mercadolivre.com.br/pt_br/autenticacao-e-autorizacao)):

```http
GET https://api.mercadolibre.com/users/me
Authorization: Bearer APP_USR-12345678-031820-X-12345678
```

Exemplo curl oficial:

```bash
curl -H 'Authorization: Bearer APP_USR-12345678-031820-X-12345678' \
  https://api.mercadolibre.com/users/me
```

No projeto, todo service segue o padrão:

```javascript
const resToken = await getToken.getToken();
const access_token = resToken[0].MLCN_ACCESS_TOKEN;

await axios.get(url, {
  headers: { Authorization: 'Bearer ' + access_token }
});
```

Arquivos que dependem do token: `getProdutosAll.js`, `getProduto.js`, `getOrdensAll.js`, `getOrdem.js`, `getCategorias.js`, `getTpAnuncios.js`, `getDadosFaturamento.js`, `getEndereco.js`.

---

## Fluxo implementado em `getToken.js`

```
1. Lê VIEW_MERC_LIVRE_CONFIG (UNIDADE_EMPRESARIAL_ID do .env)
2. Se EXPIRES = 'N' → retorna config (token ainda válido)
3. Se EXPIRES = 'S':
   a. Tenta findToken (authorization_code) se houver MLCN_CODE
   b. Executa refreshToken com MLCN_TOKEN (refresh_token)
   c. Grava via PRC_MLAPI_TOKEN_UPDATE
   d. Relê config e retorna
```

### Controle de expiração no Oracle

View `VIEW_MERC_LIVRE_CONFIG` calcula `EXPIRES`:

| Condição | EXPIRES |
|----------|---------|
| `MLCN_TOKEN` nulo | `S` (precisa renovar) |
| `MLCN_TOKEN_DT_VAL` nulo | `S` |
| `MLCN_TOKEN_DT_VAL < SYSDATE` | `S` |
| Caso contrário | `N` (válido) |

Procedure `PRC_MLAPI_TOKEN_UPDATE` define:

```sql
MLCN_TOKEN_DT_VAL = SYSDATE + NUMTODSINTERVAL(P_TIME_SEC, 'SECOND')
```

Onde `P_TIME_SEC` = `expires_in` retornado pela API (tipicamente 21600).

---

## Campos da tabela `MERC_LIVRE_CONFIG`

| Campo | Papel no fluxo OAuth |
|-------|----------------------|
| `MLCN_CLIENT_ID` | `client_id` / APP ID |
| `MLCN_CLIENT_SECRET` | `client_secret` |
| `MLCN_REDIRECT_URI` | `redirect_uri` (deve bater com o app ML) |
| `MLCN_CODE` | Código de autorização (primeira troca) |
| `MLCN_TOKEN` | `refresh_token` |
| `MLCN_ACCESS_TOKEN` | `access_token` usado nas APIs |
| `MLCN_USER_ID` | `user_id` do vendedor ML |
| `MLCN_TOKEN_DT_VAL` | Data/hora de expiração do access token |

---

## Job automático de renovação

Arquivo: `src/jobs/execJobs.js`

- Executa `getToken.getToken()` **na subida** e a cada **30 minutos** (`*/30 * * * *`).
- Garante que o `access_token` seja renovado antes ou quando `EXPIRES = 'S'`.

---

## Checklist — primeira configuração

- [ ] Criar app no Mercado Livre Developers
- [ ] Configurar `redirect_uri` estática no painel ML (sem parâmetros variáveis)
- [ ] Anotar `client_id` e `client_secret`
- [ ] (Opcional) Criar/usar **usuário de teste** ML para homologação
- [ ] Abrir URL de autorização no navegador (usuário **administrador**, não colaborador)
- [ ] Validar parâmetro `state` no retorno (se utilizado)
- [ ] Copiar `code` da URL de retorno
- [ ] Inserir/atualizar registro em `MERC_LIVRE_CONFIG` no Horus
- [ ] Configurar `.env` com `UNIDADE_EMPRESARIAL_ID`, `DB_*`
- [ ] Executar `node src/app.js` e verificar logs: `> Refresh Token` / `> Update Token`
- [ ] Confirmar `MLCN_ACCESS_TOKEN`, `MLCN_TOKEN` e `MLCN_TOKEN_DT_VAL` preenchidos
- [ ] Testar chamada API (ex.: sync de produtos)

---

## Referência de códigos de erro (documentação ML)

Tabela completa conforme [Autenticação e Autorização](https://developers.mercadolivre.com.br/pt_br/autenticacao-e-autorizacao):

| Código | HTTP | Significado | Ação sugerida no Horus |
|--------|------|-------------|------------------------|
| `invalid_client` | — | `client_id` e/ou `client_secret` inválidos | Revisar `MLCN_CLIENT_ID` e `MLCN_CLIENT_SECRET` |
| `invalid_grant` | 400 | `code` ou `refresh_token` inválido, expirado, já usado, revogado, fluxo incorreto, `redirect_uri` divergente, ou vendedor com pendências | Refazer autorização; ver seção [Erro invalid_grant](#erro-invalid_grant) |
| `invalid_scope` | — | Scope inválido ou mal formatado | Valores permitidos: `offline_access`, `write`, `read` |
| `invalid_request` | — | Parâmetro obrigatório ausente, duplicado ou malformado | Revisar body do POST `/oauth/token` |
| `unsupported_grant_type` | — | `grant_type` inválido | Usar apenas `authorization_code` ou `refresh_token` |
| `forbidden` | 403 | Token de outro usuário, IP bloqueado, scopes insuficientes, ou problema de acesso ao domínio ML do país | Verificar token, permissões e conectividade |
| `local_rate_limited` | 429 | Excesso de requisições | Aguardar alguns segundos e tentar novamente |
| `unauthorized_client` | — | App sem grant com o usuário ou scopes insuficientes | Refazer autorização; verificar permissões no painel ML |
| `unauthorized_application` | — | Aplicação bloqueada | Resolver pendências no painel Meus Aplicativos |
| `invalid_operator_user_id` | — | Login com operador/colaborador | Autorizar com conta **administrador** |

### Eventos que invalidam token antes do prazo (ML)

Podem invalidar `access_token` **antes** de `expires_in`:

- Alteração de senha pelo usuário
- Atualização do `client_secret` no aplicativo
- Revogação de permissões pelo vendedor
- App **sem nenhuma chamada** a `https://api.mercadolibre.com/` por **4 meses**

---

## Erro invalid_grant

Durante a troca de `code` ou `refresh_token`, a API pode retornar:

```json
{
  "error_description": "Error validating grant. Your authorization code or refresh token may be expired or it was already used",
  "error": "invalid_grant",
  "status": 400,
  "cause": []
}
```

Indica que o `authorization_code` ou `refresh_token` **não existe ou foi excluído**. Motivos documentados pelo ML:

| Motivo | Descrição | Solução |
|--------|-----------|---------|
| **Expiração (6 meses)** | `refresh_token` expira após ~6 meses sem renovação válida | Refazer fluxo completo de autorização no navegador |
| **Revogação pelo usuário/integrador** | Permissão revogada em "Administrar Permissões" | Nova autorização; atualizar `MLCN_CODE` e tokens |
| **Revogação interna ML** | Alteração de senha, desvinculação de dispositivos, fraude, etc. | Nova autorização completa |
| **Code já utilizado** | `authorization_code` é de uso único | Gerar novo `code` via URL de autorização |
| **Refresh já utilizado** | Cada `refresh_token` só vale uma troca | Garantir que `PRC_MLAPI_TOKEN_UPDATE` sempre salve o **novo** refresh retornado |
| **`redirect_uri` divergente** | URL do POST difere da usada na autorização | Igualar `MLCN_REDIRECT_URI` ao painel ML |
| **Pendências do vendedor** | Dados/documentos pendentes na conta | Regularizar conta ML antes de autorizar |

> **No projeto:** se `refreshToken` falhar com `invalid_grant`, o operador deve repetir o Passo 1 (autorização no navegador) e atualizar `MLCN_CODE` em `MERC_LIVRE_CONFIG`.

---

## Erros comuns — atalho operacional

| Sintoma | Causa provável | Ação |
|---------|----------------|------|
| `redirect_uri mismatch` | URL diferente da cadastrada no app | Igualar `MLCN_REDIRECT_URI` ao painel ML |
| `invalid_operator_user_id` | Login com colaborador | Autorizar com conta principal |
| `invalid_grant` (PKCE) | `code_verifier` incorreto ou placeholder | Implementar PKCE completo ou desabilitar PKCE no app |
| Token expira cedo | `MLCN_TOKEN_DT_VAL` desatualizado | Verificar execução de `PRC_MLAPI_TOKEN_UPDATE` |
| App para de sincronizar | Refresh expirado/revogado | Refazer autorização; consultar `src/error.log` |

---

## Divergências conhecidas (doc × código)

| Tópico | Documentação ML | Projeto atual |
|--------|-----------------|---------------|
| Parâmetro `state` | Recomendado na autorização | Não validado |
| PKCE | Obrigatório se habilitado no app | Placeholder `$CODE_VERIFIER` |
| Renovação | Somente quando expirar | Job a cada 30 min, mas `getToken` só renova se `EXPIRES = 'S'` ✅ |
| Credenciais | — | OAuth no Oracle; conexão DB no `.env` |
| Tratamento erro `findToken` | — | `catch` vazio em `getToken.js` (falha silenciosa) |

---

## Referência rápida de arquivos

| Arquivo | Responsabilidade |
|---------|------------------|
| `src/services/token/getToken.js` | Orquestrador principal |
| `src/services/token/findToken.js` | Troca `authorization_code` → tokens |
| `src/services/token/refreshToken.js` | Renovação via `refresh_token` |
| `src/repositories/configRepository.js` | Leitura view + gravação procedure |
| `src/oracle/view_merc_livre_config.vw` | Flag `EXPIRES` |
| `src/oracle/prc_mlapi_token_update.prc` | Persistência e validade |
| `src/oracle/merc_livre_config.tab` | Estrutura da configuração |
| `src/jobs/execJobs.js` | Cron de renovação (30 min) |

---

## Documentação relacionada no repositório

- [README.md](README.md) — instalação e visão geral
- [ARQUITETURA.md](ARQUITETURA.md) — fluxo OAuth na arquitetura
- [CONTEXTO-IA.md](CONTEXTO-IA.md) — continuidade e débitos técnicos
