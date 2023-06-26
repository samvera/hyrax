# Maintenance Policy for Hyrax
January 25, 2023

[Hyrax Maintenance Working Group](https://samvera.atlassian.net/wiki/spaces/samvera/pages/496632295/Hyrax+Maintenance+Working+Group)

## Why do we need a policy? 
A written policy prevents word-of-mouth policies which create confusion in the community. 
A written policy also provides a transparent way to communicate our values to people who may 
not work on the maintenance team consistently. It gives a basis to justify spending time on 
something that isn’t in the product backlog.

Updated versions of JavaScript libraries, Ruby, and Ruby gems are released all the time. 
If we don’t keep our applications up-to-date with the latest released versions of their 
dependencies, we may end up with applications that rely on dependencies with known 
vulnerabilities, bugs, or deprecated features.

Hyrax releases are managed in two groupings: 
- Breaking changes which include new features with incompatible changes such as requiring 
  data migration, bug fixes or security fixes with incompatible changes. 
- Non-breaking changes which have new features that can be introduced with feature flipper, 
  backwards compatibility, or that do not require data migration, bug fixes or security fixes
  that do not require data migration. 

## Semantic Versioning

Hyrax follows [semver](https://semver.org/) for release versioning. All releases are handled in X.Y.Z format.

Current releases are at https://github.com/samvera/hyrax/releases 

### Major X
New features with incompatible changes such as requiring data migration, bug fixes or security 
fixes with incompatible changes. Breaking changes are paired with deprecation notices in the 
previous minor or major release.

### Minor Y
New features that can be introduced with feature flipper, backwards compatibility, or that do not 
require data migration. May also contain bug fixes or security fixes that do not require data migration.

### Patch Z
Bug fixes or security fixes that do not require data migration. No new features.

## Supported Versions
Supported versions are the highest currently released X version and then backwards to X-1. So when 
Hyrax 4.0 is released, the latest Hyrax 3.y is supported but Hyrax 2.y is not. Extended support for 
an otherwise unsupported version may be offered at the Product Owner or Technical Lead’s discretion. 
See End-of-Life Versions below.

## New features
New features that are added to the current release may be backported to supported past versions on 
a case-by-case basis. New features that are not relevant to the current release can be added to a 
supported past version.

## Bug fixes
Bug fixes that are added to the current release may be backported to supported past versions on a 
case-by-case basis. 

## Security fixes
The current major release will receive patches and new versions in case of a security fix. The last
release in the previous major version will also receive security updates. So when Hyrax 4.y has a 
security fix applied, this security fix would also be applied to the latest Hyrax 3.y, but not to 
Hyrax 2.y.

## Dependency Management
Deprecated or end-of-life versions of dependencies used as part of building a Hyrax-based application 
will be removed from the test suite to manage maintenance. If an outdated version of a dependency is 
still supported that does not pose security issues, it may remain supported in the test suite.

## End-of-Life  Versions
End-of-life versions are X-1 versions behind the highest currently released X version. So when Hyrax 4.0 
is released, Hyrax 2.y is end-of-life and no longer supported, but Hyrax 3.y is still supported and is 
not end-of-life. Extended support for an otherwise unsupported version may be offered at the Product 
Owner or Technical Lead’s discretion (e.g. many major releases in a short period of time). 
See Supported Versions above.

End-of-Life versions of Hyrax will not be supported. Applying fixes (security or otherwise) will be 
up to the implementing entity. We encourage updating to supported versions of Hyrax to receive updates 
and security fixes.
