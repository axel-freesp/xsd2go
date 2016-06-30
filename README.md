# xsd2go
Convert XML schema files to validating parser (Go source files)

## Introduction
XML schema validation is a useful thing. A schema description (xsd)
defines a XML dialect, and a validating parser only accepts XML files
that match the schema. Applications using XML content can rely on the
constraints defined in the schema, saving a lot of error handling code
without risk.

Go's XML parser (encoding/xml) is lazy in checking, but very performant.
To complement this parser by schema validation, we could wrap existing
validating parsers (e.g. Apache XERCES-C http://xerces.apache.org/),
but would then face a huge interface at the risk of performance loss.

In this project a different approach is taken: a schema is parsed
offline, and validating code is generated out of it. That way we
- keep the XML parser small and fast and
- keep the user interface small.

Instead of presenting a generic DOM (document object model) to the user,
the XML data are presented in auto-generated Go types matching the data
structure, just like you would do it manually if you want to input the
XML data to Go's parser. In order to perform schema validation,
additional constraint checks ensure that values are in the predefined
range or strings match regular expressions. The technique used is XSLT
(XML stylesheet processing) using Apache's Xalan stylesheet processor.

## Installation
Xsd2go needs
- GNU make 3.81b or higher
- Apache Xalan 1.10
- Go (1.3.3 or newer)

On some systems (e.g. Ubuntu 15.04) the stylesheet processor is broken
or comes with the wrong version. (I will provide detailed installation
notes how to compile and install Xalan correctly on Ubuntu 15.04.)

After cloning the project, cd into it. The following make commands are
available:

`$ make` - build all examples and run the tests on them.

`$ make clean` - delete all generated files.

`$ make check` - perform explicit schema validation of the test XML
files.

## Getting started
The examples folder contains example schema files (*.xsd) which are the
source for further processing. Each schema is complemented by a test
definition (*-test.xml) that lists test files together with their
expected parse result. You can simply add your schema file to the
examples folder, add a respective -test.xml (which may have an empty
list) and execute `make`. The results go to a newly created folder
`test` and get compiled against two generated test programs.

## Features
### Some Limitations
Compared to a full-blown validating XML parser, there are some drawbacks
resulting from the taken approach, that limit
the amount of checks that can actually be performed. For example, the
following input files cannot be distinguished, althought a schema could
tell we should accept one, but reject the other:

Example 1:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<toplevel>
    <element1>Content 1</element1>
    <element2>Content 2</element2>
</toplevel>
```

Example 2:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<toplevel>
    <element2>Content 2</element2>
    <element1>Content 1</element1>
</toplevel>
```

In general, the sequence order of elements cannot be checked, althought
it can be expressed in an XML schema. As of now, there is no strategy to
overcome this drawback. If the sequence order really matters, a
full-blown validating parser is needed.

Another drawback can be encountered: It is invalid XML to write an
attribute twice, like in the following example.

Example 3 - invalid XML (duplicated attribute):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<toplevel>
    <element1 attr="foo" attr="bar"/>
</toplevel>
```

Such malformed XML files are accepted by the generated parsers, and all
but one duplicate values are silently discarded. In contrast to the
sequence order weakness, this issue could be fixed in the native Go XML
parser, because it simply is invalid XML.

### Available Features
#### We can parse
- document structure (with the limitation of the sequence order)
  - sequence
  - choice
  - group
  - attributeGroup
  - attribute
- inheritance
  - simpleType - restriction
  - complexType - extension
- element cardinality (minOccurs, maxOccurs)
- attribute presence (use="optional", use="required")
- attribute default values
- attribute fixed values
- numeric values (in elements and attributes):
  - number format range (e.g. -128 <= signed char <= 127)
  - explicit range (m[ax|in][In|Ex]clusive)
- enumeration (only as a restriction of xsd:string)

#### We can create a parser from the AUTOSAR XML schema files!
The official schema files can be downloaded from the AUTOSAR server,
for example, I was playing with these files:
- [AUTOSAR-3.1 schema] (http://www.autosar.org/fileadmin/files/releases/3-1/methodology-templates/templates/standard/AUTOSAR_Schema.zip)
- [AUTOSAR-4.2 schema] (http://www.autosar.org/fileadmin/files/releases/4-2/methodology-and-templates/templates/standard/AUTOSAR_MMOD_XMLSchema.zip)

These schema files are really *big*. Here are some numbers about lines
of code of the schema files and the lines of code of the generated Go
parser:
- AUTOSAR.xsd - 20633 loc, AUTOSAR.go - 67584 loc
- AUTOSAR_4-2-2.xsd - 77357 loc, AUTOSAR_4-2-2.go - 191620 loc

We can generate Go structure files without any validation code by calling

```
$ make no-verify
```

This is useful, if you want to have a quick parser for a given schema, without any verification.

#### Next to Do
Some things have been left to do (and I will take care when time permits):
- missing features
  - regex parsing and validating
  - validation of floating point numbers
  - validation of special types (dateTime and friends)
  - namespace (until now, we are namespace agnostic)
  - references
  - handling of complex scenarios
- re-structuring of the XSLT stylesheets, to make them better readable ;)

If you want to contribute, please create a JIRA issue.

## Toolchain
TODO: detailed description of the processing steps: which stylesheet
produces what and why? Test execution.

Have fun!

