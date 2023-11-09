local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.alerts_exporter;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('alerts-exporter', params.namespace);

{
  'alerts-exporter': app,
}
