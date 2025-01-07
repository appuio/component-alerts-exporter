local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.alerts_exporter;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('alerts-exporter', params.namespace);

local appPath =
  local project = std.get(app, 'spec', { project: 'syn' }).project;
  if project == 'syn' then 'apps' else 'apps-%s' % project;

{
  ['%s/alerts-exporter' % appPath]: app,
}
