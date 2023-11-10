// main template for openshift4-slos
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

local slo = import 'slos.libsonnet';

local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.alerts_exporter;

local upstreamNamespace = 'alerts-exporter';

local removeUpstreamNamespace = kube.Namespace(upstreamNamespace) {
  metadata: {
    name: upstreamNamespace,
  } + com.makeMergeable(params.namespaceMetadata),
};

local patch = function(p) {
  patch: std.manifestJsonMinified(p),
};

local deploymentPatch = {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    name: 'alerts-exporter',
  },
} + com.makeMergeable(params.exporter.deploymentPatch);

local extraArgsPatch = [
  {
    op: 'test',
    path: '/spec/template/spec/containers/0/name',
    value: 'exporter',
  },
] + std.map(function(arg) {
  op: 'add',
  path: '/spec/template/spec/containers/0/args/-',
  value: arg,
}, params.exporter.extraArgs);

com.Kustomization(
  '%(repository)s//%(subdir)s' % params.manifests,
  params.manifests.version,
  {
    'ghcr.io/appuio/alerts-exporter': {
      local image = params.images.alerts_exporter,
      newTag: image.tag,
      newName: '%(registry)s/%(image)s' % image,
    },
    'gcr.io/kubebuilder/kube-rbac-proxy': {
      local image = params.images.kube_rbac_proxy,
      newTag: image.tag,
      newName: '%(registry)s/%(image)s' % image,
    },
  },
  params.kustomize_input {
    patches+: [
      patch(removeUpstreamNamespace),
      patch(deploymentPatch),
      patch(extraArgsPatch) {
        target: {
          kind: 'Deployment',
          name: 'alerts-exporter',
        },
      },
    ],
    labels+: [
      {
        pairs: {
          'app.kubernetes.io/managed-by': 'commodore',
        },
      },
    ],
  },
)
