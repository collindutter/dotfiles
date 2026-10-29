# Dokploy API recipes

Resolve placeholders from live discovery. Examples are request shapes, not a script to run against copied IDs. Fetch `GET /api/settings.getOpenApiDocument` with `x-api-key` and check the installed schema first.

REST calls use `/api/<router>.<method>` and plain JSON bodies. tRPC uses `/api/trpc/<router>.<method>` with `{ "json": { ... } }`; GET input is URL-encoded JSON. Reject HTTP failures and tRPC `error` envelopes.

Read credentials inside a process. Never print complete `application.one`, `destination.one`, or PostgreSQL responses: they can contain passwords and environment secrets. Filter output to names, IDs, status, and other nonsecret fields.

## Create the project and application

`POST /api/project.create`

```json
{"name":"<App>","description":"<purpose>"}
```

Record the returned project and production environment IDs. Reconcile existing resources by name before retrying a timed-out create.

`POST /api/application.create`

```json
{
  "name":"Web",
  "appName":"<app>-web",
  "environmentId":"<environment-id>",
  "serverId":"<verified-side-projects-id>",
  "sourceType":"docker"
}
```

Record the returned application ID and generated service name. A shared PostgreSQL database is created inside the existing database service, not by creating another Dokploy PostgreSQL service.

## Docker provider, environment, and runtime

`application.saveDockerProvider` accepts `applicationId`, `dockerImage`, `username`, `password`, and `registryUrl`. Set the registry to `ghcr.io`; supply private-package pull credentials without logging the payload. This selects the provider; it does not prove an image is running.

`application.saveEnvironment` accepts:

```json
{
  "applicationId":"<app-id>",
  "env":"<dotenv-formatted runtime configuration>",
  "buildArgs":"",
  "buildSecrets":"",
  "createEnvFile":false
}
```

For updates, read and preserve existing values instead of replacing the environment with an incomplete template. Serialize multiline PEM values correctly. Preserve existing build settings unless changing them deliberately. Never rotate signing secrets incidentally.

Use `application.update` for runtime settings. Check the schema's units. A 384 MiB memory limit is `"402653184"`, not `"384"`; 0.5 CPU is `"500000000"` NanoCPUs. Choose limits from actual host headroom.

Use one replica, a suitable health check/start period, serialized updates, and `endpointSpecSwarm: {"Mode":"dnsrr"}` when relying on the direct Traefik peer IP. Publish no application host ports.

## Hostname and release

`POST /api/domain.create`

```json
{
  "host":"<app>.coolin.me",
  "path":"/",
  "port":8000,
  "https":true,
  "certificateType":"letsencrypt",
  "applicationId":"<app-id>",
  "domainType":"application"
}
```

Use the actual application port. To switch images without replacing registry credentials:

`POST /api/application.update`

```json
{"applicationId":"<app-id>","dockerImage":"ghcr.io/<owner>/<repo>@sha256:<digest>"}
```

Then call `application.deploy` with `applicationId`, `title`, and `description`. Inspect `deployment.all?applicationId=<id>`, Docker service tasks/image/health, and the public endpoint. Keep the prior image reference for recovery; rolling back code cannot undo destructive migrations or restore remote-only content to an old inline-only build.

For an existing temporary hostname, the reference instance supports tRPC `redirects.create` with `applicationId`, `regex`, `replacement`, and `permanent`. Anchor the regex to the exact old hostname and preserve the path/query. Verify the installed route/schema. Prefer stored Dokploy routing configuration to hand-edited Traefik files that regeneration could overwrite.

## Database backups

Create/test a destination with `destination.testConnection` and `destination.create`:

```json
{
  "name":"<App>",
  "provider":"Cloudflare",
  "accessKey":"<secret>",
  "secretAccessKey":"<secret>",
  "bucket":"<private-app-bucket>",
  "region":"auto",
  "endpoint":"https://<account-id>.r2.cloudflarestorage.com",
  "additionalFlags":[],
  "serverId":"<verified-side-projects-id>"
}
```

Inspect `postgres.one` to verify the shared service and detect an existing app backup. Create only the app's schedule:

`POST /api/backup.create`

```json
{
  "schedule":"0 3 * * *",
  "enabled":true,
  "prefix":"backups/<app>/",
  "destinationId":"<app-destination-id>",
  "keepLatestCount":14,
  "database":"<app-database>",
  "databaseType":"postgres",
  "postgresId":"<verified-shared-postgres-id>",
  "backupType":"database"
}
```

Some create/mutation endpoints return no resource body. Read the resulting configuration before retrying. `backup.manualBackupPostgres` takes `backupId`. Inspect `deployment.allByType?id=<backup-id>&type=backup` and the uploaded object, not just the request's success.

The reference implementation stores PostgreSQL backups as gzipped custom-format dumps despite the `.sql.gz` suffix. Check the actual format. After decompression, use the matching PostgreSQL version's `pg_restore --no-owner --no-acl --exit-on-error` into a temporary database owned by the app role. A listing of dump contents is not a restore test.

Inspect the running version's retention implementation before enabling it. The expected object prefix is `<managed-postgres-service>/<configured-prefix>/`; deletion must stay there and leave artifact `versions/` keys untouched.
