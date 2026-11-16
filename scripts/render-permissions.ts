import { readFileSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { parseArgs } from 'node:util'
import { match } from 'ts-pattern'
import { z } from 'zod'

const POLICIES_DIR = 'policies'
const MANIFEST_FILE = 'manifest.json'
const AWS_MANAGED_POLICY_DOCS = 'https://docs.aws.amazon.com/aws-managed-policy/latest/reference'
const PLACEHOLDERS = ['account_id', 'partition', 'role_name', 'cloudtrail_bucket_name'] as const

const ManifestSchema = z.strictObject({
  deployment_version: z.string().min(1),
  managed_policies: z.array(z.strictObject({ arn: z.string().startsWith('arn:aws:iam::aws:policy/'), reason: z.string().min(1) })).min(1),
  custom_policies: z
    .array(z.strictObject({ name: z.string().min(1), file: z.string().endsWith('.json'), capability: z.string().min(1).nullable() }))
    .min(1),
})

const StatementSchema = z.looseObject({ Action: z.union([z.string(), z.array(z.string()).min(1)]) })
const PolicyDocumentSchema = z.looseObject({ Version: z.literal('2012-10-17'), Statement: z.array(StatementSchema).min(1) })

const CliSchema = z.union([
  z.strictObject({ mode: z.literal('write'), target: z.string().min(1) }),
  z.strictObject({ mode: z.literal('check'), target: z.string().min(1) }),
])

type Manifest = z.infer<typeof ManifestSchema>
type CustomPolicy = Manifest['custom_policies'][number]
type PolicyDocument = z.infer<typeof PolicyDocumentSchema>

main()

function main(): void {
  const cli = parseCliOrExit()
  const manifest = loadManifest()
  const markdown = renderPermissionsDoc({ manifest })
  match(cli)
    .with({ mode: 'write' }, ({ target }) => writeFileSync(target, markdown))
    .with({ mode: 'check' }, ({ target }) => failWhenStale({ target, markdown }))
    .exhaustive()
}

function parseCliOrExit(): z.infer<typeof CliSchema> {
  const { values } = parseArgs({ options: { write: { type: 'string' }, check: { type: 'string' } }, strict: true })
  const candidate = values.write === undefined ? { mode: 'check', target: values.check } : { mode: 'write', target: values.write }
  const parsed = CliSchema.safeParse(candidate)
  if (!parsed.success) {
    console.error('usage: render-permissions.ts --write <file> | --check <file>')
    process.exit(2)
  }
  return parsed.data
}

function loadManifest(): Manifest {
  const parsed = ManifestSchema.safeParse(JSON.parse(readFileSync(join(POLICIES_DIR, MANIFEST_FILE), 'utf8')))
  if (!parsed.success) {
    throw new Error(`${MANIFEST_FILE} is invalid: ${z.prettifyError(parsed.error)}`)
  }
  return parsed.data
}

function renderPermissionsDoc({ manifest }: { manifest: Manifest }): string {
  return [
    '## Permissions',
    '',
    `The role gets these permissions and nothing else: exactly what Act requests when you connect AWS from the Act console. The files in [\`${POLICIES_DIR}/\`](${POLICIES_DIR}) are the only source; the module and this section are built from them, and CI fails when this section drifts from them. Member roles in an organization get the same set. The role carries the tag \`DeploymentVersion = ${manifest.deployment_version}\`.`,
    '',
    '### AWS managed policies',
    '',
    '| Policy | Why |',
    '| ------ | --- |',
    ...manifest.managed_policies.map(renderManagedPolicyRow),
    '',
    '### Act policies',
    '',
    `Each file is an IAM policy document. \`\${account_id}\`, \`\${partition}\`, \`\${role_name}\` and \`\${cloudtrail_bucket_name}\` are filled in for the account the role is in.`,
    '',
    '| Policy | File | Attached | Statements | Services |',
    '| ------ | ---- | -------- | ---------- | -------- |',
    ...manifest.custom_policies.map(renderCustomPolicyRow),
    '',
  ].join('\n')
}

function renderManagedPolicyRow({ arn, reason }: Manifest['managed_policies'][number]): string {
  const name = arn.split('/').at(-1) ?? arn
  return `| [\`${name}\`](${AWS_MANAGED_POLICY_DOCS}/${name}.html) \`${arn}\` | ${reason} |`
}

function renderCustomPolicyRow(policy: CustomPolicy): string {
  const document = loadPolicyDocument({ file: policy.file })
  const attached = policy.capability === null ? 'Always' : `When \`${policy.capability}\` is true (the default)`
  const services = servicesOf({ document }).join(', ')
  return `| \`${policy.name}\` | [\`${POLICIES_DIR}/${policy.file}\`](${POLICIES_DIR}/${policy.file}) | ${attached} | ${document.Statement.length} | ${services} |`
}

function loadPolicyDocument({ file }: { file: string }): PolicyDocument {
  const text = readFileSync(join(POLICIES_DIR, file), 'utf8')
  const parsed = PolicyDocumentSchema.safeParse(JSON.parse(text))
  if (!parsed.success) {
    throw new Error(`${file} is not an IAM policy document: ${z.prettifyError(parsed.error)}`)
  }
  assertKnownPlaceholders({ file, text })
  return parsed.data
}

function assertKnownPlaceholders({ file, text }: { file: string; text: string }): void {
  const unknown = [...text.matchAll(/\$\{([^}]*)\}/g)]
    .map(([, name]) => name ?? '')
    .filter((name) => !PLACEHOLDERS.some((known) => known === name))
  if (unknown.length > 0) {
    throw new Error(`${file} uses unknown placeholders: ${[...new Set(unknown)].join(', ')}`)
  }
}

function servicesOf({ document }: { document: PolicyDocument }): string[] {
  const actions = document.Statement.flatMap(({ Action }) => (typeof Action === 'string' ? [Action] : Action))
  return [...new Set(actions.map((action) => action.split(':')[0] ?? action))].sort().map((service) => `\`${service}\``)
}

function failWhenStale({ target, markdown }: { target: string; markdown: string }): void {
  if (readFileSync(target, 'utf8') !== markdown) {
    console.error(`${target} is stale. Run make docs.`)
    process.exit(1)
  }
}
