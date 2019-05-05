"""Cornice Swagger 2.0 documentor helpers"""

from pyramid.threadlocal import get_current_registry
from cornice_apispec.utils import get_schema_name, get_schema_cls


def get_parameter_from_path(path):
    path_components = path.split('/')
    param_names = [comp[1:-1] for comp in path_components
                   if comp.startswith('{') and comp.endswith('}')]

    params = []
    for name in param_names:

        params.append(name)

    return params


class Helper(object):
    def __init__(self, service, args):
        self.service = service
        self.args = args


class PathHelper(Helper):

    def __init__(self, service, args, pyramid_registry=None):
        self.service = service
        self.args = args
        self.pyramid_registry = pyramid_registry

    def _extract_path_from_service(self):
        """
        Extract path object and its parameters from service definitions.
        :param service:
            Cornice service to extract information from.
        :rtype: dict
        :returns: Path definition.
        """

        path_obj = {}
        path = self.service.path
        route_name = getattr(self.service, 'pyramid_route', None)
        # handle services that don't create fresh routes,
        # we still need the paths so we need to grab pyramid introspector to
        # extract that information
        if route_name:
            # avoid failure if someone forgets to pass registry
            registry = self.pyramid_registry or get_current_registry()
            route_intr = registry.introspector.get('routes', route_name)
            if route_intr:
                path = route_intr['pattern']
            else:
                msg = 'Route `{}` is not found by ' \
                      'pyramid introspector'.format(route_name)
                raise ValueError(msg)

        # handle traverse and subpath as regular parameters
        # docs.pylonsproject.org/projects/pyramid/en/latest/narr/hybrid.html
        for subpath_marker in ('*subpath', '*traverse'):
            path = path.replace(subpath_marker, '{subpath}')

        return path

    @property
    def path(self):
        return self._extract_path_from_service()




class SchemasHelper(Helper):
    """
    Extract defined schema at service
    """

    def _has_cornice_base_validator(self, validators):
        """
        Cornice has a special validator that expect a especial schema with subsructure
        """
        # TODO: Add colander validator
        for validator in validators:
            if validator.__module__ in ['cornice.validators._marshmallow'] and validator.__name__ == 'validator':
                return True

        return False

    @property
    def body(self):
        if self._has_cornice_base_validator(self.args.get('validators', [])):

            schema_instance = get_schema_cls(self.args.get('schema'))()

            if 'body' in schema_instance.fields:
                return schema_instance.fields['body'].schema.__class__

        return self.args.get('schema', None)

    @property
    def querystring(self):
        return []

    @property
    def path(self):
        if self._has_cornice_base_validator(self.args.get('validators', [])):

            schema_instance = get_schema_cls(self.args.get('schema'))()

            if 'path' in schema_instance.fields:
                return schema_instance.fields['path'].schema.__class__

        return self.args.get('schema', None)

    def headers(self):
        return []


class ResponseHelper(Helper):

    """
    Extract response from service
    """

    @property
    def responses(self):
        ret = []
        for status_code, schema in self.args.get('response_schemas', {}).items():
            component_id = '{}_{}'.format(status_code, get_schema_name(schema))
            ret.append((component_id, status_code, schema,))
        else:
            ret.append(('default', 200, None,))

        return ret
