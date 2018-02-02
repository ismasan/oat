# Change Log

## [Unreleased](https://github.com/ismasan/oat/tree/HEAD)

[Full Changelog](https://github.com/ismasan/oat/compare/v0.5.1...HEAD)

**Merged pull requests:**

- Remove dependency on ActiveSupport. [\#76](https://github.com/ismasan/oat/pull/76) ([ismasan](https://github.com/ismasan))

## [v0.5.1](https://github.com/ismasan/oat/tree/v0.5.1) (2017-06-06)
[Full Changelog](https://github.com/ismasan/oat/compare/v0.5.0...v0.5.1)

**Merged pull requests:**

- Improve serialization performance by avoiding instance\_eval and method\_missing [\#73](https://github.com/ismasan/oat/pull/73) ([ivoanjo](https://github.com/ivoanjo))
- Remove duplicated license file [\#70](https://github.com/ismasan/oat/pull/70) ([tjmw](https://github.com/tjmw))

## [v0.5.0](https://github.com/ismasan/oat/tree/v0.5.0) (2016-08-24)
[Full Changelog](https://github.com/ismasan/oat/compare/v0.4.7...v0.5.0)

**Closed issues:**

- :only option for filtering [\#67](https://github.com/ismasan/oat/issues/67)

**Merged pull requests:**

- Add support for multiple schema blocks [\#69](https://github.com/ismasan/oat/pull/69) ([tjmw](https://github.com/tjmw))

## [v0.4.7](https://github.com/ismasan/oat/tree/v0.4.7) (2016-02-29)
[Full Changelog](https://github.com/ismasan/oat/compare/v0.4.6...v0.4.7)

**Implemented enhancements:**

- Override context on embedded serializers [\#13](https://github.com/ismasan/oat/issues/13)

**Closed issues:**

- The Siren adapter renders multiple rels per link as an array of an array instead of a flat array [\#64](https://github.com/ismasan/oat/issues/64)
- JsonApi adapter generates anything but JSON API conformant document [\#62](https://github.com/ismasan/oat/issues/62)
- Cross-cutting concerns [\#61](https://github.com/ismasan/oat/issues/61)

**Merged pull requests:**

- Support for multiple rels specified as an array for a single link. fixes \#64. [\#65](https://github.com/ismasan/oat/pull/65) ([landlessness](https://github.com/landlessness))

## [v0.4.6](https://github.com/ismasan/oat/tree/v0.4.6) (2015-02-07)
[Full Changelog](https://github.com/ismasan/oat/compare/v0.4.5...v0.4.6)

**Closed issues:**

- Serialize to vanilla JSON using the same serializer class [\#59](https://github.com/ismasan/oat/issues/59)
- HAL support for multiple link objects per relationship? [\#58](https://github.com/ismasan/oat/issues/58)
- Nested serializers: undefined method [\#56](https://github.com/ismasan/oat/issues/56)
- Array serialization [\#54](https://github.com/ismasan/oat/issues/54)
- Oat, Rails Responders and hypermedia mime types [\#50](https://github.com/ismasan/oat/issues/50)
- is lib/support/class\_attribute necessary? [\#44](https://github.com/ismasan/oat/issues/44)

**Merged pull requests:**

- HAL support for an array of linked objects [\#60](https://github.com/ismasan/oat/pull/60) ([abargnesi](https://github.com/abargnesi))
- Fixing Nested Serializers example [\#57](https://github.com/ismasan/oat/pull/57) ([coderdave](https://github.com/coderdave))
- Fix spelling in README.md [\#53](https://github.com/ismasan/oat/pull/53) ([killpack](https://github.com/killpack))
- provide an example of using Rails responders to support requests using a Hypermedia mime type [\#52](https://github.com/ismasan/oat/pull/52) ([apsoto](https://github.com/apsoto))
- Stop entities/entity from duplicating entries in linked hash. [\#49](https://github.com/ismasan/oat/pull/49) ([dpdawson](https://github.com/dpdawson))
- Better documentation for Oat::Adapters::JsonAPI\#collection [\#46](https://github.com/ismasan/oat/pull/46) ([emilesilvis](https://github.com/emilesilvis))
- add the required rel attribute for Siren sub-entities [\#45](https://github.com/ismasan/oat/pull/45) ([apsoto](https://github.com/apsoto))

## [v0.4.5](https://github.com/ismasan/oat/tree/v0.4.5) (2014-07-09)
[Full Changelog](https://github.com/ismasan/oat/compare/v0.4.4...v0.4.5)

**Closed issues:**

- Thread Safety [\#39](https://github.com/ismasan/oat/issues/39)

**Merged pull requests:**

- Fix serializer ampersand warning [\#43](https://github.com/ismasan/oat/pull/43) ([iainbeeston](https://github.com/iainbeeston))
- Update build matrix [\#42](https://github.com/ismasan/oat/pull/42) ([iainbeeston](https://github.com/iainbeeston))
- Update to rspec3 [\#41](https://github.com/ismasan/oat/pull/41) ([iainbeeston](https://github.com/iainbeeston))

## [v0.4.4](https://github.com/ismasan/oat/tree/v0.4.4) (2014-05-26)
[Full Changelog](https://github.com/ismasan/oat/compare/v0.4.3...v0.4.4)

**Closed issues:**

- Top level json api meta [\#28](https://github.com/ismasan/oat/issues/28)

**Merged pull requests:**

- Add title addribute to siren action's fields [\#38](https://github.com/ismasan/oat/pull/38) ([erezesk](https://github.com/erezesk))

## [v0.4.3](https://github.com/ismasan/oat/tree/v0.4.3) (2014-05-01)
[Full Changelog](https://github.com/ismasan/oat/compare/v0.4.2...v0.4.3)

**Merged pull requests:**

- json-api: Don't add templated links to the resource [\#37](https://github.com/ismasan/oat/pull/37) ([kjg](https://github.com/kjg))

## [v0.4.2](https://github.com/ismasan/oat/tree/v0.4.2) (2014-04-29)
[Full Changelog](https://github.com/ismasan/oat/compare/v0.4.1...v0.4.2)

**Closed issues:**

- Errors management [\#35](https://github.com/ismasan/oat/issues/35)

**Merged pull requests:**

- Add type attribute for siren actions [\#36](https://github.com/ismasan/oat/pull/36) ([erezesk](https://github.com/erezesk))

## [v0.4.1](https://github.com/ismasan/oat/tree/v0.4.1) (2014-04-25)
[Full Changelog](https://github.com/ismasan/oat/compare/v0.4.0...v0.4.1)

**Merged pull requests:**

- Add meta property [\#32](https://github.com/ismasan/oat/pull/32) ([ahx](https://github.com/ahx))

## [v0.4.0](https://github.com/ismasan/oat/tree/v0.4.0) (2014-04-07)
[Full Changelog](https://github.com/ismasan/oat/compare/v0.3.0...v0.4.0)

**Closed issues:**

- Does this support any type of caching? [\#30](https://github.com/ismasan/oat/issues/30)

**Merged pull requests:**

- Don't block NoMethodErrors from raising [\#31](https://github.com/ismasan/oat/pull/31) ([shekibobo](https://github.com/shekibobo))

## [v0.3.0](https://github.com/ismasan/oat/tree/v0.3.0) (2014-03-25)
[Full Changelog](https://github.com/ismasan/oat/compare/v0.2.5...v0.3.0)

**Closed issues:**

- How to serialize many records? [\#24](https://github.com/ismasan/oat/issues/24)

**Merged pull requests:**

- Don't allow rake 10.2 on ruby 1.8.7 [\#29](https://github.com/ismasan/oat/pull/29) ([kjg](https://github.com/kjg))
- Json api link templates [\#27](https://github.com/ismasan/oat/pull/27) ([kjg](https://github.com/kjg))
- Json api attribute links [\#26](https://github.com/ismasan/oat/pull/26) ([kjg](https://github.com/kjg))

## [v0.2.5](https://github.com/ismasan/oat/tree/v0.2.5) (2014-03-20)
[Full Changelog](https://github.com/ismasan/oat/compare/v0.2.4...v0.2.5)

**Merged pull requests:**

- Json api nil entities [\#25](https://github.com/ismasan/oat/pull/25) ([kjg](https://github.com/kjg))

## [v0.2.4](https://github.com/ismasan/oat/tree/v0.2.4) (2014-02-24)
[Full Changelog](https://github.com/ismasan/oat/compare/v0.2.3...v0.2.4)

**Merged pull requests:**

- Allow for serializing json api resource collections into root key [\#23](https://github.com/ismasan/oat/pull/23) ([kjg](https://github.com/kjg))
- Json api subent top linked [\#22](https://github.com/ismasan/oat/pull/22) ([kjg](https://github.com/kjg))

## [v0.2.3](https://github.com/ismasan/oat/tree/v0.2.3) (2014-02-17)
[Full Changelog](https://github.com/ismasan/oat/compare/v0.2.2...v0.2.3)

**Merged pull requests:**

- Json api sub behaviour [\#20](https://github.com/ismasan/oat/pull/20) ([kjg](https://github.com/kjg))
- Add version badge to README [\#18](https://github.com/ismasan/oat/pull/18) ([shekibobo](https://github.com/shekibobo))

## [v0.2.2](https://github.com/ismasan/oat/tree/v0.2.2) (2014-02-17)
[Full Changelog](https://github.com/ismasan/oat/compare/v0.1.2...v0.2.2)

**Closed issues:**

- Remove activesupport dependency [\#10](https://github.com/ismasan/oat/issues/10)

**Merged pull requests:**

- Test more combinations in travis [\#17](https://github.com/ismasan/oat/pull/17) ([kjg](https://github.com/kjg))
- Serializer from block or class update [\#16](https://github.com/ismasan/oat/pull/16) ([kjg](https://github.com/kjg))
- Make specs more accurate and using updated syntax [\#15](https://github.com/ismasan/oat/pull/15) ([shekibobo](https://github.com/shekibobo))
- Better Context [\#14](https://github.com/ismasan/oat/pull/14) ([shekibobo](https://github.com/shekibobo))
- Less active support [\#11](https://github.com/ismasan/oat/pull/11) ([kjg](https://github.com/kjg))

## [v0.1.2](https://github.com/ismasan/oat/tree/v0.1.2) (2014-02-13)
[Full Changelog](https://github.com/ismasan/oat/compare/v0.1.1...v0.1.2)

**Closed issues:**

- Serializing collections [\#9](https://github.com/ismasan/oat/issues/9)

**Merged pull requests:**

- Support ruby 1.8.7 [\#12](https://github.com/ismasan/oat/pull/12) ([kjg](https://github.com/kjg))

## [v0.1.1](https://github.com/ismasan/oat/tree/v0.1.1) (2014-01-26)
[Full Changelog](https://github.com/ismasan/oat/compare/v0.1.0...v0.1.1)

**Merged pull requests:**

- Don't add invalid link relations to HAL output [\#8](https://github.com/ismasan/oat/pull/8) ([shekibobo](https://github.com/shekibobo))

## [v0.1.0](https://github.com/ismasan/oat/tree/v0.1.0) (2014-01-14)
[Full Changelog](https://github.com/ismasan/oat/compare/v0.0.1...v0.1.0)

**Closed issues:**

- DRY property declaration [\#5](https://github.com/ismasan/oat/issues/5)

**Merged pull requests:**

- Add Serializer\#map\_properties to DRY property definitions [\#6](https://github.com/ismasan/oat/pull/6) ([shekibobo](https://github.com/shekibobo))
- Add action support for Siren. [\#4](https://github.com/ismasan/oat/pull/4) ([SebastianEdwards](https://github.com/SebastianEdwards))
- Don't try to serialize nil with an entity serializer [\#3](https://github.com/ismasan/oat/pull/3) ([shekibobo](https://github.com/shekibobo))
- Fix a small typo in the README [\#2](https://github.com/ismasan/oat/pull/2) ([stevenharman](https://github.com/stevenharman))

## [v0.0.1](https://github.com/ismasan/oat/tree/v0.0.1) (2013-11-18)
**Merged pull requests:**

- Fix a few spelling and grammar errors [\#1](https://github.com/ismasan/oat/pull/1) ([leemachin](https://github.com/leemachin))



\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*