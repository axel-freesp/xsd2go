# xsd2go
Convert XML schema files to validating parser (Go source files)

## Introduction
XML schema validation is a useful thing. A schema description (xsd) defines a XML dialect, and a validating parser only accepts XML files that match the schema. Applications using XML content can rely on the constraints defined in the schema, saving a lot of error handling code without risk.

Go's XML parser (encoding/xml) is lazy in checking, but very performant. To complement this parser by schema validation, we could wrap existing validating parsers (e.g. Apache XERCES-C http://xerces.apache.org/), but would then face a huge interface at the risk of performance loss.

In this project a different approach is taken: a schema is parsed offline, and validating code is generated out of it. That way we
- keep the XML parser small and fast and
- keep the user interface small.

Instead of presenting a generic DOM (document object model) to the user, the XML data are presented in auto-generated Go types matching the data structure, just like you would do it manually if you want to input the XML data to Go's parser. In order to perform schema validation, additional constraint checks ensure that values are in the predefined range or strings match regular expressions. The technique used is XSLT (XML stylesheet processing) using Apache's Xalan stylesheet processor.

## Installation
Xsd2go needs
- GNU make 3.81b or higher
- Apache Xalan 1.10
- Go (1.3.3 or newer)

On some systems (e.g. Ubuntu 15.04) the stylesheet processor is broken or comes with the wrong version. (I will provide detailed installation notes how to compile and install Xalan correctly on Ubuntu 15.04.)

After cloning the project, cd into it. The following make commands are available:
`$ make` - build all examples and run the tests on them.
`$ make clean` - delete all generated files
`$ make check` - perform explicit schema validation of the test XML files

## Getting started
The examples folder contains example schema files (*.xsd) which are the source for further processing. Each schema is complemented by a test definition (*-test.xml) that lists test files together with their expected parse result. You can simply add your schema file to the examples folder, add a respective -test.xml (which may have an empty list) and execute `make`. The results go to a newly created folder `test` and get compiled against two generated test programs.

## Toolchain
TODO: detailed description of the processing steps: which stylesheet produces what and why? Test execution.

## Features
TODO: describe the already existing features and what needs to be done.

Have fun!

